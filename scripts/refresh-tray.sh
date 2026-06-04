#!/usr/bin/env bash
# Created by Kangy w/ OpenCode AI Assistance
# Version: 0.3.0-20260604
#
# Refresh system tray: finds all StatusNotifierItem services on DBus and
# registers any that the current watcher is missing.
# Run after a QS reload to recover tray icons that didn't re-register.

WATCHER_SERVICE="org.kde.StatusNotifierWatcher"
WATCHER_PATH="/StatusNotifierWatcher"
WATCHER_IFACE="org.kde.StatusNotifierWatcher"

# Get currently registered items from the watcher
readarray -t REGISTERED < <(
  busctl --user get-property "$WATCHER_SERVICE" "$WATCHER_PATH" \
    "$WATCHER_IFACE" RegisteredStatusNotifierItems 2>/dev/null \
    | sed 's/^as //' | tr ' ' '\n' | sed 's/^"//;s/"$//' | sed '/^[[:space:]]*$/d'
)

# Scan all running user services for StatusNotifierItem objects
# Skip activatable (not yet running) services to avoid launching apps
COUNT=0
while IFS= read -r svc; do
  # Quick check: does this service have a StatusNotifierItem?
  ITEM_PATH=$(timeout 1 busctl --user tree "$svc" 2>/dev/null \
    | grep -o '/StatusNotifierItem$' | head -1)
  if [ -z "$ITEM_PATH" ]; then
    continue
  fi

  FULL="${svc}${ITEM_PATH}"

  # Skip if already registered
  FOUND=0
  for registered in "${REGISTERED[@]}"; do
    if [ "$registered" = "$FULL" ]; then
      FOUND=1
      break
    fi
  done

  if [ "$FOUND" -eq 1 ]; then
    continue
  fi

  busctl --user call "$WATCHER_SERVICE" "$WATCHER_PATH" \
    "$WATCHER_IFACE" RegisterStatusNotifierItem s "$svc" 2>/dev/null && \
    echo "Registered: $FULL" && COUNT=$((COUNT + 1)) || true
done < <(busctl --user list --no-legend 2>/dev/null | awk '$5 !~ /\(activatable\)/ && $2 != "-" && $1 !~ /^org\.kde\./ {print $1}')

if [ "$COUNT" -eq 0 ]; then
  echo "All tray items already registered."
else
  echo "Registered $COUNT missing tray item(s)."
fi
