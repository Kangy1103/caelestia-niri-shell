# caelestia-niri-shell — Cleanup Plan

Created by Kangy w/ OpenCode AI Assistance
Version: 1.0.0-20260607

Last updated: 2026-06-07

---

## Phase 1: Audit & Quick Wins [COMPLETE]

- Performed comprehensive file-by-file audit of all 371 source files (excluding `.git/` and build artifacts)
- Categorised every file as: Dead, WIP/abandoned, Leftover, Duplicate, Setup/tooling, or Fully implemented
- **NiriThing.qml** — WIP workspace control panel (274 lines). Decided not to pursue. Deleted.
- Verified all active imports resolve to existing files
- Identified broken reference: `lock/Media.qml:34` → missing shader `assets/shaders/opacitymask.frag.qsb` (resolved in Phase 2 by switching to upstream's dim-overlay approach, shader not restored)

### Phase 1 summary

| Category | Dead | WIP/abandoned | Leftover | Duplicate | Keep |
|----------|------|---------------|----------|-----------|------|
| QML components | 8 | — | — | — | — |
| Config | 1 | — | — | — | — |
| Bar/workspaces | 9 | — | — | — | — |
| Dashboard | — | — (NiriThing deleted) | — | 1 (ActiveWindow) | — |
| CC panes | 3 | — | — | — | — |
| Services | 2 | — | — | — | — |
| Runtime scripts | 5 | — | — | — | — |
| Keybinds scripts | — | — | 4 | — | — |
| Setup scripts | — | — | — | — | 12 |
| Build script | — | — | — | — | 1 |
| Assets | 2 + 1 missing | — | — | — | 6 (active) |
| Screenshots | — | — | — | — | 6 (doc) |

---

## Phase 2: Group-by-Group Purge [IN PROGRESS]

**Strategy:** Walk through each group and decide: **delete** or **keep**. Each group is independent — decisions don't cascade.

---

### Group 1: Dead Behaviours + Effects [DONE]

**Deleted (5):**

| File | Reason |
|------|--------|
| `components/behaviors/OpacityBehavior.qml` | Leftover from behaviours cleanup. Added by community contributor, never in upstream. |
| `components/behaviors/PositionBehavior.qml` | Same. |
| `components/behaviors/SizeBehavior.qml` | Same. |
| `components/effects/CalloutLine.qml` | Decorative connector-line, part of old workspace refactor, never wired up. |
| `components/effects/OpacityMask.qml` | Broken shader ref to deleted `.qsb` file. Upstream uses `MultiEffect` instead — no shader needed. |

**Kept (1):**

| File | Reason |
|------|--------|
| `components/effects/ElevationGlow.qml` | Even-halo glow effect for focused element highlighting (vs directional `Elevation.qml` shadow). Worth keeping — potential to wire into active workspace pill for a soft glow indicator. |

---

### Group 2: Dead Standalone Components [DONE]

**Deleted (2):**

| File | Reason |
|------|--------|
| `components/controls/SpinBoxRow.qml` | Generic label+spinbox row. Settings pattern handled differently. Not in upstream. |
| `components/SystemLogo.qml` | Fully superseded by inline logo code in `SysInfo.qml`. Not in upstream. |

**Kept (1):**

| File | Reason |
|------|--------|
| `components/Chip.qml` | 69-line M3-styled tag/chip with icon, text, selected state, and close button. Not currently used but well-implemented building block for future tag/filter UI (launcher categories, notification filters, etc.). |

---

### Group 3: Config Orphan [DONE]

**Deleted (1):**

| File | Reason |
|------|--------|
| `config/SidebarConfig.qml` | Stub for upstream's notification sidebar (`modules/sidebar/` — 9 files). The upstream sidebar is a notification centre side-panel with group/dock/action support. Not ported to CNS. |

**Note:** Upstream source saved to `~/.config/opencode/plans/cns-sidebar/` (9 files: `Content.qml`, `Wrapper.qml`, `Notif.qml`, `NotifGroup.qml`, `NotifGroupList.qml`, `NotifDock.qml`, `NotifDockList.qml`, `NotifActionList.qml`, `Props.qml`). Available to port when desired.

---

### Group 4: Old Workspace Pill System [DONE]

All 9 files deleted — fully replaced by Noctalia-style workspace pill implementation.

| File | Reason |
|------|--------|
| `modules/bar/components/IdleInhibitor.qml` | Idle management moved to Stasis |
| `modules/bar/components/workspaces/ActiveIndicator.qml` | Old pill visuals, replaced by Noctalia-style |
| `modules/bar/components/workspaces/OccupiedBg.qml` | Same |
| `modules/bar/components/workspaces/Pager.qml` | Same |
| `modules/bar/components/workspaces/WorkspaceIcon.qml` | Same |
| `modules/bar/components/workspaces/DraggableWindowColumn.qml` | Same |
| `modules/bar/components/workspaces/context/ContextBg.qml` | Same |
| `modules/bar/components/workspaces/context/ContextIndicator.qml` | Same |
| `modules/bar/popouts/WorkspacesPopout.qml` | Old workspace popout, replaced by new pill popout |

---

### Group 5: Old Control Center Panes [DONE]

All 3 files deleted — `ReadonlySlider` was a component without a consumer, `EthernetPane` and `WirelessPane` superseded by unified `NetworkingPane.qml`.

| File | Reason |
|------|--------|
| `modules/controlcenter/components/ReadonlySlider.qml` | Display-only slider, no consumer. All values in CNS are read+write. |
| `modules/controlcenter/network/EthernetPane.qml` | Replaced by unified `NetworkingPane.qml` |
| `modules/controlcenter/network/WirelessPane.qml` | Replaced by unified `NetworkingPane.qml` |

---

### Group 6: Dashboard Duplicates [DONE]

**Deleted (1):**

| File | Reason |
|------|--------|
| `modules/dashboard/ActiveWindow.qml` | Duplicate of `bar/components/ActiveWindow.qml`. Dashboard version never imported. |

**Kept (1):**

| File | Reason |
|------|--------|
| `modules/dashboard/WeatherPanel.qml` | Actively wired in `Content.qml:146` as the full weather tab. Coexists with compact `dash/Weather.qml`. |

**Reference saved:** Upstream `WeatherTab.qml` → `~/.config/opencode/plans/weather-widget-update/` for migrating our `WeatherPanel.qml` to the new `Tokens.*` API when desired.

---

### Group 7: Dead Services [DONE]

Both deleted — C++ equivalents (`BeatTracker`, `SysMonitor` from `Caelestia.Services`) handle their functionality.

| File | Reason |
|------|--------|
| `services/BeatDetector.qml` | 10-line stub with static `bpm: 150`. Not imported. Bongo cat uses C++ `BeatTracker` instead. |
| `services/SysMonitorService.qml` | Full impl but never imported outside self-refs. C++ `SysMonitor` used directly. |

---

### Group 8: Leftover Keybinds Scripts [DONE]

**Kept (4 scripts):** Backend pipeline is functional for Niri (`expand.py` already targets `~/.config/niri/config.kdl`).

**QML UI saved to `~/.config/opencode/plans/keybind-ui/`** (5 files restored from git commit `f9cd31f^`):

| File | Purpose |
|------|---------|
| `Content.qml` | Main keybinds viewer UI (426 lines) |
| `Wrapper.qml` | Drawer wrapper integration |
| `KeybindsPanel.qml` | Panel layout |
| `KeybindsBackground.qml` | Background styling |
| `Keybinds.qml` (service) | IPC / data service |

---

### Group 9: Dead Runtime Scripts [DONE]

All 5 deleted.

| File | Reason |
|------|--------|
| `scripts/colors/applycolor.sh` | Empty stub |
| `scripts/colors/scheme_for_image.py` | Replaced by `generate_colors_material.py` |
| `scripts/colors/generate_nvchad_theme.py` | NvChad-specific, user doesn't use NvChad |
| `scripts/audio-port.sh` | Superseded by inline pactl in `AudioPortSwitch.qml` |
| `scripts/start-swayidle.sh` | Stasis handles idle management |

---

### Group 10: Assets [DONE]

**Kept (2):**
- `images/Wallpapers/eyes.png` — not referenced, keep as-is
- `images/Wallpapers/MXBpbZp.png` — same

**Deleted/replaced (1):**
- `assets/shaders/opacitymask.frag.qsb` — **Not restored.** Upstream moved to simpler `FadeImage` + dim overlay approach. Updated `lock/Media.qml` to match: removed custom shader + gradient mask, added `StyledRect` overlay at 70% opacity. Same moody backdrop, no GLSL to maintain.

---

### Group 11: Unused Imports [DONE]

**Cleaned (3):**

| File | Removed |
|------|---------|
| `services/Brightness.qml` | `import qs.components.misc` |
| `modules/Shortcuts.qml` | `import qs.components.misc` |
| `modules/controlcenter/network/VpnSettings.qml` | `import QtQuick.Controls` |

---

### Group 12: Screenshots (6 PNGs)

In `images/screenshorts/`. Documentation only — not runtime assets.

| File | Size |
|------|------|
| `images/screenshorts/weather.png` | ~2 MB |
| `images/screenshorts/quicktoggles.png` | ~2.5 MB |
| `images/screenshorts/niriThings.png` | ~2.3 MB |
| `images/screenshorts/dashboard.png` | ~2.2 MB |
| `images/screenshorts/clipboard.png` | ~2.5 MB |
| `images/screenshorts/app_launcher.png` | ~2.3 MB |

**Verdict:** _Decide — remove from repo or leave as documentation_

---

## Reference: Full Audit (Phase 1 output)

### Category definitions

- **Dead** — Superseded, replaced, or explicitly removed. No intent to revive.
- **WIP / abandoned** — Started but never finished or wired in. May want to finish or delete.
- **Leftover** — Orphaned remnants after another component was removed.
- **Duplicate** — Redundant copy of an active component.
- **Setup/tooling** — Install-time or dev-time only. Keep as-is.

### QML files — audit

#### Components — 9 files

| File | Status | Reason |
|------|--------|--------|
| ~~`components/behaviors/OpacityBehavior.qml`~~ | ~~Dead~~ **Deleted** | Unreferenced. Behaviors were cleaned up, these weren't removed. Deleted in Phase 2. |
| ~~`components/behaviors/PositionBehavior.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`components/behaviors/SizeBehavior.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| `components/Chip.qml` | **Kept** | Unreferenced chip/tag component. M3-styled building block, kept for potential tag/filter UI. |
| ~~`components/controls/SpinBoxRow.qml`~~ | ~~Dead~~ **Deleted** | Unreferenced spin box control. Deleted in Phase 2. |
| ~~`components/effects/CalloutLine.qml`~~ | ~~Dead~~ **Deleted** | Decorative effect, never used in any module. Deleted in Phase 2. |
| `components/effects/ElevationGlow.qml` | **Kept** | Even-halo glow for focused element highlighting. Not currently wired but worth keeping for active pill integration. |
| ~~`components/effects/OpacityMask.qml`~~ | ~~Dead~~ **Deleted** | Opacity mask shader effect. Broken ref to missing `.qsb`. Upstream uses `MultiEffect` instead. Deleted in Phase 2. |
| ~~`components/SystemLogo.qml`~~ | ~~Dead~~ **Deleted** | OS logo component. Never used — `SysInfo.qml` does this inline. Deleted in Phase 2. |

#### Config — 1 file

| File | Status | Reason |
|------|--------|--------|
| ~~`config/SidebarConfig.qml`~~ | ~~Dead~~ **Deleted** | Only config file not referenced anywhere. Upstream has a `modules/sidebar/` notification centre — not ported to CNS. Reference copies saved to `~/.config/opencode/plans/cns-sidebar/` (9 files) for future implementation. Deleted in Phase 2. |

#### Bar / Workspaces — 9 files (old workspace pill)

| File | Status | Reason |
|------|--------|--------|
| ~~`modules/bar/components/IdleInhibitor.qml`~~ | ~~Dead~~ **Deleted** | Was a bar button for toggling idle inhibit. Idle management moved to Stasis. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/ActiveIndicator.qml`~~ | ~~Dead~~ **Deleted** | Old workspace pill visuals. Replaced by Noctalia-style. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/context/ContextBg.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/context/ContextIndicator.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/DraggableWindowColumn.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/OccupiedBg.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/Pager.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`modules/bar/components/workspaces/WorkspaceIcon.qml`~~ | ~~Dead~~ **Deleted** | Same. Deleted in Phase 2. |
| ~~`modules/bar/popouts/WorkspacesPopout.qml`~~ | ~~Dead~~ **Deleted** | Old workspace popout. Replaced by new workspace pill popout. Deleted in Phase 2. |

#### Dashboard — 3 files

| File | Status | Reason |
|------|--------|--------|
| `modules/dashboard/NiriThing.qml` | ~~WIP/abandoned~~ **Deleted** | Workspace overview/control panel. 274 lines of functional code — never wired into the dashboard pane system. Removed in Phase 1. |
| ~~`modules/dashboard/ActiveWindow.qml`~~ | ~~Duplicate~~ **Deleted** | Shows focused window icon + title. Same concept as `modules/bar/components/ActiveWindow.qml` which IS used. This dashboard version was never wired in. Deleted in Phase 2. |
| `modules/dashboard/WeatherPanel.qml` | **Active** (corrected) | Full weather tab wired into `Content.qml:146`. Coexists with compact `dash/Weather.qml`. |

#### Control Center — 3 files

| File | Status | Reason |
|------|--------|--------|
| ~~`modules/controlcenter/components/ReadonlySlider.qml`~~ | ~~Dead~~ **Deleted** | Unreferenced slider variant, no consumer. Deleted in Phase 2. |
| ~~`modules/controlcenter/network/EthernetPane.qml`~~ | ~~Dead~~ **Deleted** | Old standalone ethernet pane. Superseded by `NetworkingPane.qml`. Deleted in Phase 2. |
| ~~`modules/controlcenter/network/WirelessPane.qml`~~ | ~~Dead~~ **Deleted** | Old standalone wireless pane. Same. Deleted in Phase 2. |

#### Services — 2 files

| File | Status | Reason |
|------|--------|--------|
| ~~`services/BeatDetector.qml`~~ | ~~Dead~~ **Deleted** | Exposed via `qs.services` but no QML file ever imports it. The C++ BeatTracker (from Caelestia.Services) handles beat detection inline. Deleted in Phase 2. |
| ~~`services/SysMonitorService.qml`~~ | ~~Dead~~ **Deleted** | Exposed via `qs.services` but no QML file ever imports it. The C++ SysMonitor (from Caelestia.Services) handles monitoring inline. Deleted in Phase 2. |

### Scripts — audit

#### Runtime scripts — 5 files

| File | Status | Reason |
|------|--------|--------|
| ~~`scripts/colors/applycolor.sh`~~ | ~~Dead~~ **Deleted** | Empty stub. "Terminal theming (disabled)". Abandoned. Deleted in Phase 2. |
| ~~`scripts/colors/scheme_for_image.py`~~ | ~~Dead~~ **Deleted** | Orphaned Python. Replaced by `generate_colors_material.py` which `switchwall.sh` calls. Deleted in Phase 2. |
| ~~`scripts/colors/generate_nvchad_theme.py`~~ | ~~Dead~~ **Deleted** | Neovim theme generator. Never wired into the color pipeline. Deleted in Phase 2. |
| ~~`scripts/audio-port.sh`~~ | ~~Dead~~ **Deleted** | Audio port switching via pactl. Superseded by inline `pactl set-sink-port` in `AudioPortSwitch.qml`. Deleted in Phase 2. |
| ~~`scripts/start-swayidle.sh`~~ | ~~Dead~~ **Deleted** | Idle management via swayidle. You stated Stasis handles this now. Deleted in Phase 2. |

#### Keybinds scripts — 4 files

| File | Status | Reason |
|------|--------|--------|
| `modules/keybinds/scripts/expand.py` | **Kept** | Niri config include expander. Part of keybinds viewer pipeline — kept for future UI rebuild. |
| `modules/keybinds/scripts/extract_binds.py` | **Kept** | Same — kept for future UI rebuild. |
| `modules/keybinds/scripts/dedupe_binds.py` | **Kept** | Same — kept for future UI rebuild. |
| `modules/keybinds/scripts/pretty_print_binds.py` | **Kept** | Same — kept for future UI rebuild. |

#### Setup scripts — 12 files (KEEP)

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

#### Build — 1 file (KEEP)

| File | Purpose |
|------|---------|
| `plugin/build.sh` | Build helper for C++ plugin |

### Assets — audit

| Asset | Status | Reason |
|-------|--------|--------|
| ~~`assets/shaders/opacitymask.frag.qsb`~~ | ~~Restored~~ **Not restored** | Decompiled from git history but decided against. Upstream uses simpler `FadeImage` + dim overlay approach. `lock/Media.qml` updated to match. |
| `images/Wallpapers/eyes.png` | Keep | Sample wallpaper, not referenced. Kept as-is. |
| `images/Wallpapers/MXBpbZp.png` | Keep | Same. |
| `images/screenshorts/*.png` (6 files) | Doc | Screenshots for documentation. Not runtime. |

### Unused imports (minor, 3 files)

| File | Import removed |
|------|----------------|
| `services/Brightness.qml` | `import qs.components.misc` — cleaned |
| `modules/Shortcuts.qml` | `import qs.components.misc` — cleaned |
| `modules/controlcenter/network/VpnSettings.qml` | `import QtQuick.Controls` — cleaned |
