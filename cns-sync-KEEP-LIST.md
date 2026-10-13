# CNS Upstream Sync — Keep List

**Watermark:** `688142ea` (2026-08-04) → `upstream/main` `a3a8fe59` (2026-10-12)
**Delta:** 138 commits, 355 files (164 C++ / 149 QML / 42 other)

CNS deleted 28 files that exist at the watermark. Only **21** are still present
upstream at HEAD — those are the ones a wholesale take would resurrect. The other
7 upstream removed itself and need no guard.

---

## Section 1 — AT RISK, must stay deleted (15)

These exist at `upstream/main` HEAD **and** are absent from CNS. Taking upstream's
tree wholesale puts every one of them back.

### Nix — CNS builds with plain CMake + Ninja

| File | Why |
|---|---|
| `flake.nix` | No Nix in CNS build chain |
| `flake.lock` | No Nix in CNS build chain |
| `nix/default.nix` | No Nix in CNS build chain |

### GitHub CI — CNS runs no upstream CI

| File | Why |
|---|---|
| `.github/CONTRIBUTING.md` | No upstream contribution flow |
| `.github/ISSUE_TEMPLATE/crash.yml` | Not applicable |
| `.github/ISSUE_TEMPLATE/feature.yml` | Not applicable |
| `.github/ISSUE_TEMPLATE/issue.yml` | Not applicable |
| `.github/workflows/check-format.yml` | Depends on `.clang-format` CNS dropped |
| `.github/workflows/lint.yml` | Runs `scripts/trs.fish` — not adopted |
| `.github/workflows/release.yml` | Not used |
| `.github/workflows/update-flake-inputs.yml` | Nix only |
| `.github/workflows/update-image.yml` | Upstream image publishing |

### Tooling

| File | Why |
|---|---|
| `.vscode/settings.json` | Not used |
| `scripts/qml-lint-conventions.py` | Superseded by the `trs` lineage; not adopted |

### Compositor — the important one

| File | Why |
|---|---|
| `services/Hypr.qml` | **CNS uses `services/Niri.qml`.** Restoring this reintroduces Hyprland IPC into a Niri shell. Highest-risk item in this list. |

---

## Section 2 — At risk, but ADOPT rather than keep deleted (6)

Absent from CNS by neglect, not decision. Upstream's versions are worth taking in
Phase 4 — they carry the `favouriteApps` UI and AppDb usage-sorting, which CNS
currently holds as **compiled-but-dead** C++ (`plugin/src/Caelestia/appdb.cpp` is
in the CMake SOURCES but no `Apps.qml` ever instantiates `AppDb`).

| File | Note |
|---|---|
| `modules/nexus/pages/AppsPage.qml` | Adopt — brings favourites UI |
| `modules/nexus/pages/apps/AllApps.qml` | Adopt |
| `modules/nexus/pages/apps/AppInfo.qml` | Adopt |
| `modules/nexus/common/DialogRowButton.qml` | Adopt if referenced |
| `modules/nexus/pages/services/NotificationsPage.qml` | Evaluate vs CNS `NotificationsPopupsPage.qml` |
| `modules/bar/popouts/AudioPopout.qml` | Evaluate vs CNS audio popout |

---

## Section 3 — No guard needed (7)

Upstream removed these itself. They will not come back, so listing them as risks
was wrong.

| File | Removed upstream by |
|---|---|
| `.github/FUNDING.yml` | `fix: remove FUNDING.yml (#2037)` |
| `.github/workflows/build-nix.yml` | Nix removal upstream |
| `plugin/src/Caelestia/Internal/hyprdevices.cpp` | moved to `Services/hyprdevices.cpp` |
| `plugin/src/Caelestia/Config/configlist.cpp` | `Settings/configlist` subsystem |
| `plugin/src/Caelestia/Config/configlist.hpp` | ditto |
| `plugin/src/Caelestia/Config/confignode.cpp` | `Settings/node.cpp`, `Settings/objectnode.cpp` |
| `plugin/src/Caelestia/Config/confignode.hpp` | ditto |

---

## Verification

```bash
# Section 1 only — all must stay absent
for f in flake.nix flake.lock nix/default.nix .vscode/settings.json \
         scripts/qml-lint-conventions.py services/Hypr.qml \
         .github/CONTRIBUTING.md \
         .github/ISSUE_TEMPLATE/crash.yml \
         .github/ISSUE_TEMPLATE/feature.yml \
         .github/ISSUE_TEMPLATE/issue.yml \
         .github/workflows/check-format.yml \
         .github/workflows/lint.yml \
         .github/workflows/release.yml \
         .github/workflows/update-flake-inputs.yml \
         .github/workflows/update-image.yml; do
  test -e "$f" && echo "RESURRECTED: $f"
done
```