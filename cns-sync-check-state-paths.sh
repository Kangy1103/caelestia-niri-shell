#!/usr/bin/env bash
# CNS state-path guard.
#
# Why: CNS renamed its state directory caelestia -> caelestia-niri-shell
# (commit 8d113c2d). That constant lived in plugin/src/Caelestia/Config/config.cpp,
# a file UPSTREAM DELETED. Upstream's replacement, Config/common.cpp:12, hardcodes
# u"/caelestia"_s again.
#
# If a sync takes upstream's Config/ tree wholesale, CNS silently reads and writes
# ~/.config/quickshell/caelestia/ instead of .../caelestia-niri-shell/. There is no
# error and no warning — you just lose your wallpaper, colours, launcher favourites
# and monitor layout, and the shell boots to defaults.
#
# Run from the repo root:  ./cns-sync-check-state-paths.sh
# Exit 0 = safe, 1 = path regression.

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 2

WANT="caelestia-niri-shell"
fail=0
warn=0

echo "== CNS state-path guard =="

# --- 1. Source: the config directory constant ---------------------------------
# Classify every GenericConfigLocation site by what it actually builds:
#   CNS-NAMESPACED : appends caelestia-niri-shell   -> must keep doing so
#   BARE BASE      : returns the XDG root alone     -> correct as-is (walk sentinel)
#   UPSTREAM       : appends bare /caelestia        -> REGRESSION
#
# Note: plugin/src/Caelestia/Config/rootconfig.cpp:watchRoot() is a deliberate BARE
# BASE - it is the filesystem-walk sentinel, and must never gain the app subdir.
mapfile -t SITES < <(git grep -l 'GenericConfigLocation' -- 'plugin/src/**' 2>/dev/null | sort -u)

if (( ${#SITES[@]} == 0 )); then
  echo "FAIL: found no GenericConfigLocation site — tree layout changed?"
  exit 1
fi

for f in "${SITES[@]}"; do
  if grep -q "$WANT" "$f"; then
    echo "  ok    $f — CNS-namespaced"
  elif grep -q '/caelestia' "$f"; then
    echo "  FAIL  $f — builds upstream's /caelestia path"
    fail=1
  else
    echo "  ok    $f — bare XDG base (walk sentinel, correct)"
  fi
done

# --- 2. Source: other CNS-namespaced paths ------------------------------------
# imagecache / lyrics / generated frames. Same trap, separate sites.
mapfile -t OTHERS < <(git grep -ln '/caelestia' -- 'plugin/src/**' 2>/dev/null | sort -u)

for f in "${OTHERS[@]}"; do
  grep -q 'GenericConfigLocation' "$f" && continue   # already classified above
  if grep -q "$WANT" "$f"; then
    echo "  ok    $f — CNS-namespaced"
  else
    echo "  FAIL  $f — path is not CNS-namespaced"
    fail=1
  fi
done

# --- 3. Banned literals anywhere in the source -------------------------------
echo "-- scanning for upstream '/caelestia' literals --"
while read -r hit; do
  [[ -z "$hit" ]] && continue
  echo "  FAIL  $hit — reintroduces upstream's /caelestia path"
  fail=1
done < <(git grep -n '/caelestia\(["/]\|$\)' -- 'plugin/src/**' 2>/dev/null | grep -v "$WANT")

# --- 4. Built artifact: what is actually installed ----------------------------
# Source can be correct while a stale installed plugin still carries the old path.
INSTALLED=$(ls -d /usr/lib/qt6/qml/CNS ~/.local/lib/qt6/qml/CNS 2>/dev/null | head -1)
if [[ -n "$INSTALLED" ]]; then
  echo "-- installed plugin: $INSTALLED --"
  found=$(grep -rl "$WANT" "$INSTALLED" 2>/dev/null | head -1)
  if [[ -n "$found" ]]; then
    echo "  ok    installed binary carries '$WANT'"
  else
    echo "  WARN  installed plugin has no '$WANT' string — shell is running stale build"
    warn=1
  fi
else
  echo "  WARN  no installed CNS qml module found (nothing to verify)"
  warn=1
fi

# --- 5. Runtime state dir ----------------------------------------------------
REAL="$HOME/.config/quickshell/$WANT"
if [[ -d "$REAL" ]]; then
  echo "  ok    $REAL exists"
else
  echo "  WARN  $REAL missing — is the shell using a different dir?"
  warn=1
fi
# If upstream's dir exists too, something wrote there.
if [[ -d "$HOME/.config/quickshell/caelestia" ]]; then
  echo "  WARN  ~/.config/quickshell/caelestia also exists — cross-contamination?"
  warn=1
fi

echo "==============================="
if (( fail )); then
  echo "RESULT: FAIL — state paths will regress. Fix before shipping this sync."
  exit 1
fi
(( warn )) && echo "RESULT: PASS (with warnings)"
(( warn )) || echo "RESULT: PASS"
exit 0