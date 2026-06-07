# caelestia-niri-shell — Cleanup Plan

Last updated: 2026-06-07
Status: Plan — NOT YET EXECUTED

---

## Category definitions

- **Dead** — Superseded, replaced, or explicitly removed. No intent to revive.
- **WIP / abandoned** — Started but never finished or wired in. May want to finish or delete.
- **Leftover** — Orphaned remnants after another component was removed.
- **Duplicate** — Redundant copy of an active component.
- **Setup/tooling** — Install-time or dev-time only. Keep as-is.

---

## QML files

### Components — 9 files

| File | Status | Reason |
|------|--------|--------|
| `components/behaviors/OpacityBehavior.qml` | Dead | Unreferenced. Behaviors were cleaned up, these weren't removed. |
| `components/behaviors/PositionBehavior.qml` | Dead | Same. |
| `components/behaviors/SizeBehavior.qml` | Dead | Same. |
| `components/Chip.qml` | Dead | Unreferenced chip/tag component. Maybe planned for a feature that didn't land. |
| `components/controls/SpinBoxRow.qml` | Dead | Unreferenced spin box control. Maybe planned. |
| `components/effects/CalloutLine.qml` | Dead | Decorative effect, never used in any module. |
| `components/effects/ElevationGlow.qml` | Dead | Glow effect, never used. |
| `components/effects/OpacityMask.qml` | Dead | Opacity mask shader effect. Requires `assets/shaders/opacitymask.frag.qsb` which does not exist — broken. Referenced from `modules/lock/Media.qml:34` which is a dead reference (loading from file://, not root:/). |
| `components/SystemLogo.qml` | Dead | OS logo component. Never used — `SysInfo.qml` does this inline. |

### Config — 1 file

| File | Status | Reason |
|------|--------|--------|
| `config/SidebarConfig.qml` | Dead | Only config file not referenced anywhere. Sidebar feature was likely removed or never finished. |

### Bar / Workspaces — 9 files (old workspace pill)

| File | Status | Reason |
|------|--------|--------|
| `modules/bar/components/IdleInhibitor.qml` | Dead | Was a bar button for toggling idle inhibit. Idle management moved to Stasis. |
| `modules/bar/components/workspaces/ActiveIndicator.qml` | Dead | Old workspace pill visuals. Replaced by Noctalia-style implementation per discussion. |
| `modules/bar/components/workspaces/context/ContextBg.qml` | Dead | Same. |
| `modules/bar/components/workspaces/context/ContextIndicator.qml` | Dead | Same. |
| `modules/bar/components/workspaces/DraggableWindowColumn.qml` | Dead | Same. |
| `modules/bar/components/workspaces/OccupiedBg.qml` | Dead | Same. |
| `modules/bar/components/workspaces/Pager.qml` | Dead | Same. |
| `modules/bar/components/workspaces/WorkspaceIcon.qml` | Dead | Same. |
| `modules/bar/popouts/WorkspacesPopout.qml` | Dead | Old workspace popout. Replaced by new workspace pill popout. |

### Dashboard — 3 files

| File | Status | Reason |
|------|--------|--------|
| `modules/dashboard/NiriThing.qml` | WIP/abandoned | Workspace overview/control panel (move windows, fullscreen, center, screenshot, inhibit). **274 lines of functional code** — never wired into the dashboard pane system. If you want a workspace controls pane in the dashboard, this could be finished and wired in. Otherwise it's dead. |
| `modules/dashboard/WeatherPanel.qml` | Dead | Superseded by `dash/Weather.qml` inside the Dash component. This was a standalone weather pane that was replaced when the dashboard was refactored into tabbed panes. |
| `modules/dashboard/ActiveWindow.qml` | Duplicate | Shows focused window icon + title. Same concept as `modules/bar/components/ActiveWindow.qml` which IS used. This dashboard version was never wired in. |

### Control Center — 3 files

| File | Status | Reason |
|------|--------|--------|
| `modules/controlcenter/components/ReadonlySlider.qml` | Dead | Unreferenced slider variant. Possibly planned but never used. |
| `modules/controlcenter/network/EthernetPane.qml` | Dead | Old standalone ethernet pane. Superseded by `NetworkingPane.qml` which handles ethernet + wireless + VPN in a unified split layout. |
| `modules/controlcenter/network/WirelessPane.qml` | Dead | Old standalone wireless pane. Same reason. |

### Services — 2 files

| File | Status | Reason |
|------|--------|--------|
| `services/BeatDetector.qml` | Dead | Exposed via `qs.services` but no QML file ever imports it. The C++ BeatTracker (from Caelestia.Services) handles beat detection inline. |
| `services/SysMonitorService.qml` | Dead | Exposed via `qs.services` but no QML file ever imports it. The C++ SysMonitor (from Caelestia.Services) handles monitoring inline. |

---

## Scripts

### Runtime scripts — 5 files

| File | Status | Reason |
|------|--------|--------|
| `scripts/colors/applycolor.sh` | Dead | Empty stub. "Terminal theming (disabled)". Abandoned. |
| `scripts/colors/scheme_for_image.py` | Dead | Orphaned Python. Replaced by `generate_colors_material.py` which `switchwall.sh` calls. |
| `scripts/colors/generate_nvchad_theme.py` | Dead | Neovim theme generator. Never wired into the color pipeline. |
| `scripts/audio-port.sh` | Dead | Audio port switching via pactl. Superseded by inline `pactl set-sink-port` in `AudioPortSwitch.qml`. |
| `scripts/start-swayidle.sh` | Dead | Idle management via swayidle. You stated Stasis handles this now. |

### Keybinds scripts — 4 files

| File | Status | Reason |
|------|--------|--------|
| `modules/keybinds/scripts/expand.py` | Leftover | Niri config include expander. Part of a keybinds viewer QML module that was **explicitly deleted** in commit `f9cd31f` ("refactor: remove keybinds module"). These scripts were left behind when the UI was removed. |
| `modules/keybinds/scripts/extract_binds.py` | Leftover | Same — leftover from deleted feature. |
| `modules/keybinds/scripts/dedupe_binds.py` | Leftover | Same — leftover from deleted feature. |
| `modules/keybinds/scripts/pretty_print_binds.py` | Leftover | Same — leftover from deleted feature. |

### Setup scripts — 12 files (KEEP)

| File | Purpose |
|------|---------|
| `scripts/setup/setup.sh` | Entry point — orchestrates full install |
| `scripts/setup/v2/sdata/subcmd-install/0.greeting.sh` | Welcome message |
| `scripts/setup/v2/sdata/subcmd-install/1.deps-router.sh` | Routes to correct distro installer |
| `scripts/setup/v2/sdata/subcmd-install/2.setups.sh` | Post-install setups (services, groups) |
| `scripts/setup/v2/sdata/subcmd-install/3.files.sh` | Copies dotfiles/configs to ~ |
| `scripts/setup/v2/sdata/subcmd-install/4.sddm.sh` | SDDM theme installation |
| `scripts/setup/v2/sdata/subcmd-install/options.sh` | Optional feature selection |
| `scripts/setup/v2/sdata/lib/functions.sh` | Shared logging/helper functions |
| `scripts/setup/v2/sdata/lib/environment-variables.sh` | Shared env vars |
| `scripts/setup/v2/sdata/lib/package-installers.sh` | Package manager abstraction |
| `scripts/setup/v2/sdata/lib/dist-determine.sh` | Distro detection |
| `scripts/setup/v2/sdata/dist-arch/install-deps.sh` | Arch package install list |

### Build — 1 file (KEEP)

| File | Purpose |
|------|---------|
| `plugin/build.sh` | Build helper for C++ plugin |

---

## Assets

| Asset | Status | Reason |
|-------|--------|--------|
| `assets/shaders/opacitymask.frag.qsb` | Missing | Referenced from `OpacityMask.qml` and `lock/Media.qml` but does not exist. OpacityMask.qml is dead anyway. `lock/Media.qml:34` has a stale file:// reference that silently fails. |
| `images/Wallpapers/eyes.png` | Dead | Sample wallpaper, not referenced. Copied during setup but never consumed by QML. |
| `images/Wallpapers/MXBpbZp.png` | Dead | Same. |
| `images/screenshorts/*.png` (6 files) | Doc | Screenshots for documentation. Not runtime. Move out of repo if not needed. |

---

## Unused imports (minor, 3 files)

| File | Import to remove |
|------|-------------------|
| `services/Brightness.qml` | `import qs.components.misc` |
| `modules/Shortcuts.qml` | `import qs.components.misc` |
| `modules/controlcenter/network/VpnSettings.qml` | `import QtQuick.Controls` (not using any QtQuick.Controls types) |

---

## Summary

| Category | Dead | WIP/abandoned | Leftover | Duplicate | Keep |
|----------|------|---------------|----------|-----------|------|
| QML components | 8 | — | — | — | — |
| Config | 1 | — | — | — | — |
| Bar/workspaces | 9 | — | — | — | — |
| Dashboard | — | 1 (NiriThing) | — | 1 (ActiveWindow) | — |
| CC panes | 3 | — | — | — | — |
| Services | 2 | — | — | — | — |
| Runtime scripts | 5 | — | — | — | — |
| Keybinds scripts | — | — | 4 | — | — |
| Setup scripts | — | — | — | — | 12 |
| Build script | — | — | — | — | 1 |
| Assets | 2 + 1 missing | — | — | — | 6 (active) |

**Items requiring your decision:**
1. `NiriThing.qml` — 274 lines of workspace control UI, never finished. Finish or delete?
2. `ActiveWindow.qml` — Delete (bar version handles this)?
3. Keybinds scripts — Delete (leftover from deleted feature)?
4. Setup scripts — Keep (as agreed)
5. Screenshots — Remove from repo or leave as doc?
