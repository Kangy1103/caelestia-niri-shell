Created by Kangy w/ OpenCode AI Assistance
Version: 0.7.0-20260610

# Upstream Merge Plan — caelestia-niri-shell ← caelestia-dots/shell

Merge upstream changes from `caelestia-dots/shell` (main@3c7df45) into our
Niri fork **without** undoing custom Niri work or quality-of-life improvements.

---

## Reference

| Item | Value |
|------|-------|
| Upstream repo | `https://github.com/caelestia-dots/shell` |
| Upstream ref | `main` (HEAD `3c7df45505f8364f1a397468bf1e3db018260ba0`) |
| Upstream clone | `/mnt/Gogeta/Personal Projects/caelestia-shell-reference` |
| Our fork | `~/.config/quickshell/caelestia-niri-shell` |
| Our remote | `origin` → `git@github.com:Kangy1103/caelestia-niri-shell.git` |
| Total upstream files | 446 |
| Total our fork files | 465 |
| Shared files | 205 (need per-file merge) |
| Upstream-only | 241 (new to integrate) |
| Ours-only | 260 (protect) |

---

## Strategy

1. **Adopt C++ config** (`Caelestia.Config`) for persistence + Nexus
   compatibility. Keep our `config/*.qml` files as read-through wrappers so
   existing `import "config"` paths still work.
2. **Phase by module**, ordered by dependency (plugin → config → components
   → services → modules), so each phase is independently testable.
3. **Three-way merge** shared files using `git merge-file` with our version,
   upstream version, and the merge base. Ask on ambiguous conflicts.
4. **Keep all Niri-specific code** (niriipc, nirisocket, WorkspacePill,
   workspace context menus, StasisStatus, etc.) — never replace with
   Hyprland equivalents.

---

## Phase 0 — Prep

Tag current state so we can roll back if needed:

```fish
git tag pre-merge/v0.4
git checkout -b merge-upstream
git remote add upstream /mnt/Gogeta/Personal\ Projects/caelestia-shell-reference
git fetch upstream
```

---

## Phase 1 — Plugin C++ modules ⚡

**Depends on:** nothing
**Goal:** All new upstream C++ modules compile alongside our Niri IPC.

### Copy new upstream sources (no conflict)

```
plugin/src/Caelestia/Blobs/            # blobgroup, blobshape, blobrect, blobinvertedrect, blobmaterial + shaders
plugin/src/Caelestia/Components/       # lazylistview, wavyline, buttonrow
plugin/src/Caelestia/Images/           # cachingimageprovider, imagecacher, iutils
plugin/src/Caelestia/Config/           # ~30 files — full C++ config system
plugin/src/Caelestia/Internal/         # circularbuffer, linearindicatormanager, logindmanager, sparklineitem, visualiserbars
plugin/src/Caelestia/Services/         # cpu, diskinfo, gpu, lyriccandidate, lyrics, memory, sensorslib, storage, tickingservice, usagefmt
plugin/cmake/                          # pch.cmake, qml-module.cmake, sensorslib.cmake
extras/                                # CMakeLists.txt, version.cpp
```

### Files to merge

| File | Approach |
|------|----------|
| `plugin/CMakeLists.txt` | Adopt upstream version (finds more deps, uses cmake helpers) |
| `plugin/src/Caelestia/CMakeLists.txt` | Upstream + our Niri modules |
| `plugin/src/Caelestia/Internal/CMakeLists.txt` | Upstream + niriipc/nirisocket |
| `plugin/src/Caelestia/Services/CMakeLists.txt` | Upstream + sysmonitor |

### Do NOT copy

```
plugin/src/Caelestia/Internal/hyprdevices.*      # Hyprland-specific
plugin/src/Caelestia/Internal/hyprextras.*        # Hyprland-specific
```

We keep `niriipc.*` and `nirisocket.*` instead.

### Verify

```fish
cmake -B build -G Ninja
cmake --build build
# Should succeed. New modules: Caelestia.Config, Caelestia.Images,
# Caelestia.Blobs, Caelestia.Components all present in build output.
```

---

## Phase 2 — Config system

**Depends on:** Phase 1 (C++ Config must compile)
**Goal:** `import Caelestia.Config` works. Our `import "config"` still works.
Nexus settings pages can read/write config.

### New upstream QML modules

```
modules/ConfigToasts.qml        # Toast notifications on config load/save
modules/GSFLoader.qml           # Google Sans Flex font loader
modules/IdleMonitors.qml        # Idle monitor (DPMS, lock, suspend)
```

### Our QML config files → read-through wrappers

Convert each of the 18 `config/*.qml` files to delegate to C++ Config objects:

```qml
// config/Appearance.qml — becomes:
import Caelestia.Config
pragma Singleton
QtObject {
    readonly property QtObject rounding: Config.appearance.rounding
    readonly property QtObject spacing: Config.appearance.spacing
    readonly property QtObject padding: Config.appearance.padding
    readonly property QtObject font: Config.appearance.font
    readonly property QtObject anim: Config.appearance.anim
    readonly property QtObject transparency: Config.appearance.transparency
    readonly property real deformScale: Config.appearance.deformScale
}
```

### Add Niri-specific config keys

Add to C++ Config structs:
- `GeneralConfig`: `stasisEnabled`, `workspaceScrollWraps`, etc.
- `BarConfig`: `workspacePillStyle`, `stasisIcon`, etc.
- `ServiceConfig`: `niriSocketPath`

### Verify

- Old code with `import "config"` and `Config.appearance.rounding` works.
- New code with `import Caelestia.Config` and `Config.appearance.rounding` works.
- Config persists to `~/.config/caelestia/shell.json`.

---

## Phase 3 — Shared components

**Depends on:** nothing (pure QML)
**Goal:** All upstream components available. Ours preserved.

### New upstream files to copy

```
components/AnchorAnim.qml
components/AnimLoader.qml
components/DashboardState.qml
components/DrawerVisibilities.qml
components/controls/ButtonBase.qml
components/controls/CollapsibleSection.qml      # (upstream moved from root)
components/controls/LoadingIndicator.qml
components/controls/SpinBoxRow.qml
components/controls/StyledProgressBar.qml
components/effects/Mask.qml
components/images/FadeImage.qml
components/misc/CustomShortcut.qml
components/widgets/CoverArt.qml
components/widgets/WavyTopRect.qml
components/containers/VerticalFadeFlickable.qml
```

### Shared files — merge by diff size

**<25 lines diff (~30 files):** Fast-path — accept upstream, re-apply our
improvements if any (use `git merge-file`).

```
components/controls/MenuItem.qml       # 0 diff — no action
components/misc/Ref.qml                # 0 diff — no action
components/StyledRect.qml              # 0 diff — no action
components/effects/Colouriser.qml      # 4 lines
components/filedialog/Sizes.qml        # 4 lines
components/StyledClippingRect.qml      # 4 lines
components/Logo.qml                    # 5 lines
... (~25 more)
```

**25-100 lines diff (~30 files):** Three-way merge each. Evaluate conflicts
case-by-case.

```
components/Anim.qml
components/MaterialIcon.qml
components/StateLayer.qml
components/StyledText.qml
components/containers/StyledWindow.qml
components/SectionHeader.qml
...
```

**>100 lines diff:** Manual review needed.

```
components/controls/Menu.qml             (271 lines diff)
components/StateLayer.qml                (264 lines diff)
components/filedialog/FolderContents.qml (258 lines diff)
```

### Our files to preserve (do not touch)

```
components/Card.qml
components/Chip.qml
components/FocusRing.qml
components/ReloadPopup.qml
components/controls/StyledBusyIndicator.qml
components/controls/StyledRadialButton.qml
components/controls/Toggle.qml
components/effects/CornerPiece.qml
components/effects/ElevationGlow.qml
components/effects/OpacityMask.qml
components/widgets/NotificationList.qml
components/widgets/WindowDecorations.qml
components/containers/WrappedLoader.qml
```

### Verify

Shell loads without "Type X unavailable" errors. All controls render correctly.

---

## Phase 4 — Services

**Depends on:** Phase 2 (C++ Config)
**Goal:** Upstream services available. Our custom services preserved.

### New upstream files to copy

```
services/Hypr.qml              # → rename/merge into our Niri.qml
services/NotifData.qml         # Notification data model
services/Recorder.qml          # Screen recording
services/Screens.qml           # Multi-monitor screen info
```

### Shared files — merge priorities

**High priority (high diff, complex):**

| File | Diff | Approach |
|------|------|----------|
| `Notifs.qml` | 603 | Our enhanced version (persistence, grouping, unread) is better. Keep ours, cherry-pick upstream features. |
| `Colours.qml` | 585 | Completely rewritten upstream. Likely replaced by C++ config. Evaluate. |
| `VPN.qml` | 386 | Both evolved independently. Merge carefully. |
| `Weather.qml` | 334 | Upstream has richer API. Merge into ours. |
| `Wallpapers.qml` | 285 | Upstream uses `Screens.qml`. Rework to support both. |
| `Brightness.qml` | 215 | Upstream changed significantly. Merge. |

**Medium priority:**

`Network.qml`, `Audio.qml`, `GameMode.qml`, `NetworkUsage.qml`,
`Time.qml`, `Visibilities.qml`, `Nmcli.qml`, `Players.qml`,
`IdleInhibitor.qml`

### Our custom services to preserve

```
services/AudioPortSwitch.qml       # Audio device switcher
services/BatteryMonitor.qml        # Battery monitoring
services/CalEvents.qml             # Calendar events
services/Cava.qml                  # Audio visualiser
services/Fonts.qml                 # Font management
services/M3Variants.qml            # Material You variants
services/scheme.json               # Colour scheme data
services/Schemes.qml               # Scheme management
services/PolkitService.qml         # Polkit authentication
services/SystemUsage.qml           # System monitoring
services/Niri.qml                  # Niri IPC service
```

### Verify

`qs.services` imports work. Our custom services still respond. No duplicates.

---

## Phase 5 — Bar module

**Depends on:** Phase 2, 3 (config, components)
**Goal:** Upstream bar layout improvements. Our Niri workspace widgets intact.

### New upstream files

```
modules/bar/components/workspaces/ActiveIndicator.qml
modules/bar/components/workspaces/OccupiedBg.qml
modules/bar/components/workspaces/SpecialWorkspaces.qml
modules/bar/components/workspaces/Workspace.qml
modules/bar/popouts/ActiveWindow.qml
modules/bar/popouts/ClipWrapper.qml
modules/bar/popouts/PopoutState.qml
modules/bar/popouts/kblayout/KbLayout.qml
modules/bar/popouts/kblayout/KbLayoutModel.qml
```

### `Bar.qml` — 256 lines diff

Adopt upstream's:
- Popout state management (`PopoutState`)
- Entry model iteration (`Config.bar.entries`)
- Scroll action handling

Keep ours:
- Workspace import (`import "components/workspaces"` → our WorkspacePill etc.)
- Niri-specific workspace interaction model
- `import qs.config` wrapper pattern
- Stasis/context popout integration

### Our workspace files to preserve

```
modules/bar/components/workspaces/WorkspacePill.qml
modules/bar/components/workspaces/WindowIcon.qml
modules/bar/components/workspaces/context/ItemWorkspaceContext.qml
modules/bar/components/workspaces/context/MultiWindowContext.qml
modules/bar/components/workspaces/context/WindowIconContext.qml
modules/bar/components/StasisStatus.qml
modules/bar/popouts/Stasis.qml
modules/bar/popouts/WsContextPopout.qml
modules/bar/popouts/Background.qml
modules/bar/popouts/KbLayout.qml
```

### Verify

Bar renders. Workspace pills show correct Niri workspaces. Popouts open.
Tray works. Clock renders.

---

## Phase 6 — Dashboard

**Depends on:** Phase 2, 3, 4 (config, components, services)
**Goal:** Rich media view + performance cards. Custom panels preserved.

### New upstream files

```
modules/dashboard/dash/Calendar.qml
modules/dashboard/dash/SmallWeather.qml
modules/dashboard/media/BackgroundShapes.qml
modules/dashboard/media/CoverVisualiser.qml
modules/dashboard/media/Details.qml
modules/dashboard/media/LyricList.qml
modules/dashboard/media/LyricsAndSelector.qml
modules/dashboard/media/LyricsInfo.qml
modules/dashboard/performance/BatteryTank.qml
modules/dashboard/performance/HeroCard.qml
modules/dashboard/performance/MemoryCard.qml
modules/dashboard/performance/NetworkCard.qml
modules/dashboard/performance/StorageCard.qml
modules/dashboard/WeatherTab.qml
```

### Shared files — merge approach

| File | Diff | Approach |
|------|------|----------|
| `Performance.qml` | 1037 | Adopt upstream modular cards. Keep our custom performance data sources. |
| `Media.qml` | 751 | Adopt upstream structure (lyrics, cover visualiser). Keep our player picker. |
| `dash/Media.qml` | 286 | Merge upstream improvements into our version. |
| `Content.qml` | 312 | Merge layout changes. Keep our QuickToggles integration. |
| `Tabs.qml` | 251 | Keep our tab order, add upstream tabs. |
| `dash/User.qml` | 437 | Upstream has richer profile display. Merge in. |
| `Dash.qml` | — | Keep our wrapper structure. |

### Our files to preserve

```
modules/dashboard/Background.qml       # Custom backdrop
modules/dashboard/WindowTools.qml      # Window tools tab
modules/dashboard/WeatherPanel.qml     # Weather detail panel
modules/dashboard/dash/QuickToggles.qml    # Quick toggles
modules/dashboard/dash/UpcomingEvents.qml  # Events widget
modules/dashboard/dash/Weather.qml         # Weather widget
```

### Verify

Dashboard opens. Media shows album art + lyrics. Performance shows
CPU/GPU/RAM/disk/network. Our custom panels still accessible.

---

## Phase 7 — Nexus (settings app)

**Depends on:** Phase 1, 2 (C++ Config)
**Goal:** Nexus settings app available alongside our ControlCenter.

### New upstream files (~55 total)

```
modules/nexus/Nexus.qml
modules/nexus/NexusState.qml
modules/nexus/NavPane.qml
modules/nexus/WindowFactory.qml
modules/nexus/Pages.qml
modules/nexus/PageRegistry.qml
modules/nexus/PageCompRegistry.qml
modules/nexus/navpane/NavLocations.qml
modules/nexus/navpane/SearchBar.qml
modules/nexus/common/*                    # ~15 reusable components
modules/nexus/pages/*                      # ~25 settings pages
```

### Integration

- Nexus launched via `caelestia shell nexus open` or launcher
- Our ControlCenter remains accessible for panes Nexus doesn't have yet
- Phase out overlapping CC panes over time (Audio, Bluetooth, Network,
  Appearance, Launcher, Lock, Notifs, OSD, Session)
- Keep our unique CC panes: Dashboard, Taskbar, Extra

### Verify

Nexus opens. Settings pages render with live config values. Changes persist
to `~/.config/caelestia/shell.json`. Our ControlCenter still works.

---

## Phase 8 — Lock screen

**Depends on:** Phase 2, 3 (config, components)
**Goal:** Upstream lock screen refactoring merged in.

### New upstream files

```
modules/lock/center/Clock.qml
modules/lock/center/InputField.qml
modules/lock/center/PasswordInput.qml
modules/lock/center/ProfilePic.qml
modules/lock/center/StateMessage.qml
modules/lock/weather/BriefInfo.qml
modules/lock/weather/Forecast.qml
```

### Shared files — merge

| File | Diff | Approach |
|------|------|----------|
| `Center.qml` | 535 | Adopt upstream center sub-modules. Keep our layout. |
| `LockSurface.qml` | 354 | Merge background + overlay logic. |
| `Resources.qml` | 261 | Adopt upstream resource display. |
| `Fetch.qml` | 248 | Merge data fetching changes. |
| `NotifGroup.qml` | 247 | Merge notification display. |
| `Media.qml` | 226 | Merge media controls. |
| `WeatherInfo.qml` | 192 | Adopt upstream weather info. |

### Our files to preserve

```
modules/lock/InputField.qml    # Our custom input field
PAM integration               # Keep our PAM auth backend
```

### Verify

Lock screen renders. PAM auth works. Fingerprint works. Weather/notifs/media
display correctly.

---

## Phase 9 — Remaining modules

**Depends on:** Phase 2, 3, 4, 5, 6, 8 (various)
**Goal:** All upstream modules present. All our custom modules still work.

### New upstream modules

```
modules/windowinfo/*              # Window info overlay (4 files)
modules/BatteryMonitor.qml        # Battery monitoring module
modules/ConfigToasts.qml          # Already done in Phase 2
modules/GSFLoader.qml             # Already done in Phase 2
modules/IdleMonitors.qml          # Already done in Phase 2
modules/utilities/cards/*         # Utility overlay cards
modules/utilities/RecordingDeleteModal.qml
```

### Our custom modules (preserve all)

```
modules/calendar/*                # Full calendar app + panel
modules/keybinds/*                # Keybinds viewer
modules/polkit/PolkitDialog.qml  # Polkit auth agent
modules/sidebar/*                 # Notification sidebar
modules/notifications/Background.qml
modules/osd/Background.qml
modules/osd/Interactions.qml
modules/session/Background.qml
modules/drawers/Backgrounds.qml
modules/drawers/Border.qml
modules/launcher/Background.qml
modules/launcher/EmojiList.qml
modules/launcher/items/ClipItem.qml
modules/launcher/items/ClipPreview.qml
modules/launcher/items/WebItem.qml
```

### Verify

All modules load. No import errors. All features accessible.

---

## Phase 10 — Entry point, build & cleanup

**Depends on:** All previous phases
**Goal:** Everything wired. Build system polished. Dead files removed.

### Update `shell.qml`

Current our shell.qml (51 lines) → add upstream's entry-point modules:

```
GSFLoader {}              # Google Sans Flex loader
ConfigToasts {}           # Config change toasts
BatteryMonitor {}         # Battery monitoring
IdleMonitors { lock: lock }  # Idle/DPMS/auto-lock
```

Keep our custom entries:

```
Backdrop {}
KeybindsPanel {}
CalendarPanel {}
CalendarAppPanel {}
PolkitDialog {}
ReloadPopup {}
```

### Build system

- Adopt upstream root `CMakeLists.txt` with our custom `INSTALL_*` paths
- Keep our `plugin/build.sh` updated (or replace with cmake wrapper)
- Update `plugin/src/Caelestia/CMakeLists.txt` with final module list

### Cleanup

- Remove dead/duplicate files after each phase
- Remove old QML config files once wrappers confirmed working
- Remove any files superseded by C++ equivalents

### Final verification

```fish
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
pkill quickshell; qs -c caelestia-niri-shell
```

Shell launches without errors. All features functional.

---

## Special attention files

These have heavy divergence and need case-by-case decisions during merge:

| File | Diff | Phase | Key Question |
|------|------|-------|-------------|
| `modules/dashboard/Performance.qml` | 1037 | 6 | Keep our monolithic or adopt modular cards? |
| `modules/dashboard/Media.qml` | 751 | 6 | Keep simple or adopt full lyrics view? |
| `services/Notifs.qml` | 603 | 4 | Our enhanced persistence vs upstream simplicity? |
| `services/Colours.qml` | 585 | 4 | Upstream refactor vs our scheme management? |
| `modules/bar/components/workspaces/Workspaces.qml` | 573 | 5 | Niri workspace model completely different from Hyprland. Keep ours entirely. |
| `modules/lock/Center.qml` | 535 | 8 | Adopt upstream sub-modules or keep our layout? |
| `modules/lock/LockSurface.qml` | 354 | 8 | Merge carefully — our PAM integration. |
| `modules/dashboard/dash/User.qml` | 437 | 6 | Upstream richer profile vs our simpler version. |
| `modules/bar/Bar.qml` | 256 | 5 | Multiple import/entry model differences. |

---

## File status legend

After the merge, each file should be categorised:

| Status | Meaning |
|--------|---------|
| `upstream` | Direct copy from upstream, no changes |
| `merged` | Three-way merge result, both sides contributed |
| `ours` | Custom file, not in upstream |
| `kept` | Our version kept over upstream (e.g. Notifs.qml) |
| `wrapper` | Thin wrapper delegating to upstream C++ code |
| `removed` | Old file removed (superseded by upstream equivalent) |

---

## Rollback

If a phase breaks the shell:

```fish
git checkout merge-upstream
git reset --hard <pre-phase-tag>
```

Or for individual file reverts during development:

```fish
git checkout main -- path/to/file.qml
```

---

## Completed Phases

### Phase 0 — Prep ✅ (2026-06-09)

**What was done:**

Tagged current state and set up upstream remote for reference during merge:

```
git tag pre-merge/v0.4
git remote add upstream /mnt/Gogeta/Personal Projects/caelestia-shell-reference
git fetch upstream
```

Note: `merge-upstream` branch was not created — all work committed directly to `main`.

---

### Phase 1 — Plugin C++ modules ✅ (2026-06-09)

**What was done:**

Copied new upstream C++ modules and merged CMake build system.

**Files added:**
```
plugin/src/Caelestia/Blobs/               # blobgroup, blobshape, blobrect, blobinvertedrect, blobmaterial + shaders
plugin/src/Caelestia/Components/          # lazylistview, wavyline, buttonrow
plugin/src/Caelestia/Images/              # cachingimageprovider, imagecacher, iutils
plugin/src/Caelestia/Config/              # ~30 files — full C++ config system
plugin/src/Caelestia/Internal/            # circularbuffer, linearindicatormanager, logindmanager, sparklineitem, visualiserbars
plugin/src/Caelestia/Services/            # cpu, diskinfo, gpu, lyriccandidate, lyrics, memory, sensorslib, storage, tickingservice, usagefmt
plugin/cmake/                             # pch.cmake, qml-module.cmake, sensorslib.cmake
extras/                                   # CMakeLists.txt, version.cpp
```

**Files modified:**
```
plugin/CMakeLists.txt                     # Adopted upstream dep layout + cmake helpers
plugin/src/Caelestia/CMakeLists.txt       # Added subdirs: Components, Config, Blobs, Images
plugin/src/Caelestia/Internal/CMakeLists.txt   # Merged upstream sources, kept niriipc/nirisocket
plugin/src/Caelestia/Services/CMakeLists.txt   # Merged upstream sources, kept sysmonitor
```

**Excluded (Hyprland-specific):**
- `plugin/src/Caelestia/Internal/hyprdevices.*`
- `plugin/src/Caelestia/Internal/hyprextras.*`

**Installed modules (8 total):**
`Caelestia`, `Caelestia.Components`, `Caelestia.Config`, `Caelestia.Internal`,
`Caelestia.Models`, `Caelestia.Services`, `Caelestia.Blobs`, `Caelestia.Images`

**Infrastructure — passwordless sudo for cmake --install:**

Added sudoers rule so OpenCode can run `sudo cmake --install` without a password prompt.

File: `/etc/sudoers.d/opencode-cmake`
Rule: `kangy ALL=(ALL) NOPASSWD: /usr/bin/cmake --install *`

Reversion:
```fish
sudo rm /etc/sudoers.d/opencode-cmake
```

**Reversion steps for Phase 1 files:**
git checkout main -- plugin/CMakeLists.txt
git checkout main -- plugin/src/Caelestia/CMakeLists.txt
git checkout main -- plugin/src/Caelestia/Internal/CMakeLists.txt
git checkout main -- plugin/src/Caelestia/Services/CMakeLists.txt

# Remove new module directories:
rm -rf plugin/src/Caelestia/Blobs
rm -rf plugin/src/Caelestia/Components
rm -rf plugin/src/Caelestia/Images
rm -rf plugin/src/Caelestia/Config
rm -rf plugin/cmake
rm -rf extras

# Remove individual new files from Internal/:
rm -f plugin/src/Caelestia/Internal/circularbuffer.*
rm -f plugin/src/Caelestia/Internal/linearindicatormanager.*
rm -f plugin/src/Caelestia/Internal/logindmanager.*
rm -f plugin/src/Caelestia/Internal/sparklineitem.*
rm -f plugin/src/Caelestia/Internal/visualiserbars.*

# Remove individual new files from Services/:
rm -f plugin/src/Caelestia/Services/cpu.*
rm -f plugin/src/Caelestia/Services/diskinfo.*
rm -f plugin/src/Caelestia/Services/gpu.*
rm -f plugin/src/Caelestia/Services/lyriccandidate.*
rm -f plugin/src/Caelestia/Services/lyrics.*
rm -f plugin/src/Caelestia/Services/memory.*
rm -f plugin/src/Caelestia/Services/sensorslib.*
rm -f plugin/src/Caelestia/Services/storage.*
rm -f plugin/src/Caelestia/Services/tickingservice.*
rm -f plugin/src/Caelestia/Services/usagefmt.*

# Rebuild and reinstall old plugin:
cmake -B build -G Ninja
cmake --build build
sudo cmake --install build
```

---

### Phase 2 — Config System Migration ✅ (2026-06-09)

**What was done:**

Fully switched QML config to C++ `Caelestia.Config` module. All 242 QML files now import `Caelestia.Config` directly via the `Config` attached property. Deleted all 18 legacy QML config files (`config/*.qml`).

**Import migration:**
```
import qs.config → import Caelestia.Config  (242 files)
```

**Property name changes (QML → C++ upstream parity):**
| Old QML name | New C++/TokenConfig name | Files touched |
|---|---|---|
| `Config.appearance.font.family.sans` | `Config.appearance.font.body.family` | ~30 |
| `Config.appearance.font.family.mono` | `Config.appearance.font.mono.family` | ~20 |
| `Config.appearance.font.family.material` | `Config.appearance.font.icon.family` | ~30 |
| `Config.appearance.font.family.clock` | `Config.appearance.font.clock` | ~10 |
| `Config.appearance.font.size.bodySmall` | `Config.appearance.font.body.small.size` | ~50 |
| `Config.appearance.font.size.bodyMedium` | `Config.appearance.font.body.medium.size` | ~50 |
| `Config.appearance.font.size.bodyLarge` | `Config.appearance.font.body.large.size` | ~50 |
| `Config.appearance.font.size.labelSmall` | `Config.appearance.font.label.small.size` | ~30 |
| `Config.appearance.font.size.labelMedium` | `Config.appearance.font.label.medium.size` | ~30 |
| `Config.appearance.font.size.labelLarge` | `Config.appearance.font.label.large.size` | ~30 |
| `Config.appearance.font.size.headlineLarge` | `Config.appearance.font.headline.large.size` | ~5 |
| `Config.appearance.font.size.titleLarge` | `Config.appearance.font.title.large.size` | ~5 |
| `Config.appearance.font.size.titleMedium` | `Config.appearance.font.title.medium.size` | ~5 |
| `Config.appearance.font.size.smaller` | `Config.appearance.font.body.small.size` | ~10 |
| `Config.appearance.font.size.normal` | `Config.appearance.font.body.medium.size` | ~10 |
| `Config.appearance.font.size.large` | `Config.appearance.font.title.medium.size` | ~5 |
| `Config.appearance.font.size.small` | `Config.appearance.font.body.small.size` | ~5 |
| `Config.appearance.font.size.scale` | `Config.appearance.font.scale` | ~5 |
| `Config.appearance.spacing.sm` | `Config.appearance.spacing.small` | ~40 |
| `Config.appearance.spacing.md` | `Config.appearance.spacing.medium` | ~30 |
| `Config.appearance.spacing.lg` | `Config.appearance.spacing.large` | ~30 |
| `Config.appearance.spacing.xl` | `Config.appearance.spacing.largeIncreased` | ~10 |
| `Config.appearance.spacing.xs` | `Config.appearance.spacing.extraSmall` | ~20 |
| `Config.appearance.spacing.xxl` | `Config.appearance.spacing.extraExtraLarge` | ~5 |
| `Config.appearance.spacing.smaller` | `Config.appearance.spacing.small` | ~5 |
| `Config.appearance.spacing.normal` | `Config.appearance.spacing.large` | ~5 |
| `Config.appearance.padding.sm` | `Config.appearance.padding.small` | ~40 |
| `Config.appearance.padding.md` | `Config.appearance.padding.medium` | ~30 |
| `Config.appearance.padding.lg` | `Config.appearance.padding.large` | ~30 |
| `Config.appearance.padding.xl` | `Config.appearance.padding.largeIncreased` | ~20 |
| `Config.appearance.padding.xs` | `Config.appearance.padding.extraSmall` | ~20 |
| `Config.appearance.padding.smaller` | `Config.appearance.padding.small` | ~5 |
| `Config.appearance.padding.normal` | `Config.appearance.padding.medium` | ~5 |
| `Config.appearance.anim.curves.*` | `TokenConfig.appearance.curves.*` | ~30 |
| `Config.appearance.rounding.normal` | `Config.appearance.rounding.large` | ~10 |
| `Config.bar.sizes.*` | `TokenConfig.sizes.bar.*` | ~10 |
| `Config.dashboard.sizes.*` | `TokenConfig.sizes.dashboard.*` | ~10 |
| `Config.launcher.sizes.*` | `TokenConfig.sizes.launcher.*` | ~10 |
| `Config.lock.sizes.*` | `TokenConfig.sizes.lock.*` | ~5 |
| `Config.notifs.sizes.*` | `TokenConfig.sizes.notifs.*` | ~5 |
| `Config.utilities.sizes.*` | `TokenConfig.sizes.utilities.*` | ~5 |
| `Config.session.sizes.*` | `TokenConfig.sizes.session.*` | ~5 |
| `Config.osd.sizes.*` | `TokenConfig.sizes.osd.*` | ~5 |
| `Config.controlCenter.sizes.*` | `TokenConfig.sizes.nexus.*` | ~3 |
| `Tokens.sizes.*` | `TokenConfig.sizes.*` | ~3 |

**Other changes:**
- `Appearance.xxx` → `Config.appearance.xxx` (all files that used the old `Appearance` singleton shortcut)
- Removed `Config.markDirty()` calls throughout (C++ config auto-saves on property change)
- Fixed `Shortcuts.qml` — removed broken signal connections, ConfigToasts handles them
- Suppressed screen-context warnings in `configattached.cpp` (`qCWarning` → `qCDebug`)

**C++ additions:**
- `config.cpp` / `tokens.cpp` — path `caelestia` → `caelestia-niri-shell`
- `appearanceconfig.hpp` — added `reduceTransparency` to `AppearanceTransparency`
- `dashboardconfig.hpp` — added `CalendarColors` class with 9 colour properties
- `config.hpp` — added `controlCenter` Q_PROPERTY alias (maps to `nexus`)
- `configattached.cpp` — `qCWarning` → `qCDebug` for non-screen context

**Files deleted:**
```
config/Appearance.qml, AppearanceConfig.qml, BackgroundConfig.qml,
BarConfig.qml, BorderConfig.qml, Config.qml, ControlCenterConfig.qml,
DashboardConfig.qml, GeneralConfig.qml, LauncherConfig.qml, LockConfig.qml,
NotifsConfig.qml, OsdConfig.qml, ServiceConfig.qml, SessionConfig.qml,
Tokens.qml, UserPaths.qml, UtilitiesConfig.qml
```

**Upstream modules added:**
- `modules/ConfigToasts.qml` — toast notifications on config load/save/error
- `modules/GSFLoader.qml` — Google Sans Flex font loader
- `modules/IdleMonitors.qml` — idle monitor (wired but not activated — uses Hypr.dispatch)

**Reversion:**
```fish
git checkout phase-2 -- .
sudo cmake --install ~/.config/quickshell/caelestia-niri-shell/plugin/build
```
Reverts all QML files and C++ sources to pre-Phase-2 state (before import switch + naming migration). Plugin needs reinstall to pick up reverted C++.

---

### Phase 3 — Shared Components ✅ (2026-06-09)

**What was done:**

All upstream components merged in. 14 new files copied, 46 shared files accepted upstream, 1 relocated, 13 our-only files preserved untouched.

**New upstream files copied (15):**
```
components/AnchorAnim.qml                 components/AnimLoader.qml
components/DashboardState.qml             components/DrawerVisibilities.qml
components/controls/ButtonBase.qml        components/controls/LoadingIndicator.qml
components/controls/SpinBoxRow.qml        components/controls/StyledProgressBar.qml
components/effects/Mask.qml               components/images/FadeImage.qml
components/misc/CustomShortcut.qml        components/widgets/CoverArt.qml
components/widgets/WavyTopRect.qml        components/containers/VerticalFadeFlickable.qml
components/controls/CollapsibleSection.qml  (relocated from root)
```

**Shared files merged — by bucket:**

| Bucket | Count | Method |
|--------|-------|--------|
| 0 diff (identical) | 3 | Skipped (StyledRect, MenuItem, Ref) |
| <25 lines | 17 | Fast-path — accept upstream |
| 25–100 lines | 22 | Three-way — accept upstream |
| >100 lines | 4 | Manual review — accept upstream |
| Relocated | 1 | CollapsibleSection → controls/ |

**Key upstream changes accepted:**

| Component | Change |
|-----------|--------|
| `Anim.qml` | 14-type enum animation system (StandardSmall → SlowEffects) |
| `IconButton.qml` | Now extends `ButtonBase` instead of `StyledRect` |
| `TextButton.qml` | Now extends `ButtonBase`, `isToggle` replaces `toggle` |
| `IconTextButton.qml` | Now extends `ButtonBase`, `fontStyle` for icon sizing |
| `StyledText.qml` | Opacity-based animate, removed animateProp/From/To properties |
| `StateLayer.qml` | Shape-based ripple with RadialGradient, `shapeMorph` support |
| `Menu.qml` | `attachTo` positioning, Scale expand animation, m3tertiaryContainer |
| `CachingImage.qml` | `IUtils.urlForPath` pattern replaces `CachingImageManager` |
| `FolderContents.qml` | `FileEntry` component block, `Mask` effect for layer |
| `CollapsibleSection.qml` | Data-based content (was Loader), relocated to `controls/` |

**Consumer compatibility verified:**
- `animateProp`/`animateFrom`/`animateTo`: 1 usage (lock screen, matches new default)
- `showFocusRing`: 1 usage (harmless, silently ignored)
- `contentComponent` → `content`: 0 external references — all 21 consumers use default property syntax, backward-compatible
- `backgroundMargins`/`backgroundColor`/`collapsed`/`collapse()`: 0 external references

**Our-only files preserved (13 — untouched):**
```
Card.qml, Chip.qml, FocusRing.qml, ReloadPopup.qml
controls/StyledBusyIndicator.qml, controls/StyledRadialButton.qml, controls/Toggle.qml
effects/CornerPiece.qml, effects/ElevationGlow.qml, effects/OpacityMask.qml
widgets/NotificationList.qml, widgets/WindowDecorations.qml
containers/WrappedLoader.qml
```

**Post-merge fixes (2026-06-09):**

| Issue | Root cause | Fix |
|-------|-----------|-----|
| Bar/panels not loading | `StyledWindow` added `contentItem.Config.screen: screen.name` — broke PanelWindow creation in Niri | Removed both lines |
| 5 files still old versions | `CircularProgress`, `CustomSpinBox`, `StyledScrollBar`, `StyledSlider`, `Tooltip` missed in Bucket C copy | Copied from upstream |
| StyledScrollBar errors | Upstream changed `flickable` to `required` — 28 consumers use Qt auto-attachment without explicit `flickable` | Reverted to `property Flickable flickable: null` |
| Icons showing as text | `MaterialIcon` changed from single `font: ...build()` to individual sub-property bindings — broke when consumers set `font.pointSize` | Reverted to upstream atomic builder, migrated 58 consumers to `fontStyle` |
| `placeholderText` missing | Upstream removed the alias | Restored |
| `toggle` property broken | ButtonBase renamed `toggle` → `isToggle` | Updated Toggle.qml and 2 consumers |
| `showFocusRing`/`animateProp`/`backgroundMarginTop` | Removed from upstream components | Removed from our consumers |
| `Menu.attachTo` missing | Upstream Menu requires `attachTo` + positioning properties | Added to StasisStatus.qml |
| Config warning noise | `qCWarning` on global-only + screen-context config access, `Tokens` screen warnings | Downgraded to `qCDebug` (3 files) |
| Sidebar notif text too big | `Notif.qml` overrode `font.pointSize` on every text element | Aligned with upstream — removed overrides, use StyledText defaults |
| `CUtils.clamp` failing | `Q_INVOKABLE static` doesn't resolve in our Qt build | Replaced with pure-QML `Math.max/Min` in StateLayer.qml |
| `ContentWindow` undefined | Menu.qml cast `win as ContentWindow` — type not available | Duck-typed `win.interactionWrapper` check |
| `CollapsibleSection` import | Relocated to `controls/`, WindowTools.qml missing import | Added `import qs.components.controls` |

**Reversion:**
```fish
git checkout main -- $(git diff-tree --no-commit-id --name-only -r a7f846c febf9f3 -- components/)
# For the deleted CollapsibleSection.qml at root:
git checkout main -- components/CollapsibleSection.qml
rm components/controls/CollapsibleSection.qml
```
Restores all component files to pre-Phase-3 state.

---

### Phase 4 — Services ✅ (2026-06-09)

**What was done:**

Merged upstream service files, added new services, and verified at runtime. 3 new files copied, 2 replaced from upstream, 8 three-way merged, 5 kept as-is, 11 custom files preserved.

**New upstream files copied (4):**
```
services/NotifData.qml       # Notification data model
services/Recorder.qml        # gpu-screen-recorder integration
services/Screens.qml         # Multi-monitor screen info
services/Hypr.qml            # NOT copied — Hyprland-specific, we use Niri.qml
```

**Files accepted from upstream (full replace):**
```
services/VPN.qml             # Richer status model, auth, per-provider parsing
services/IdleInhibitor.qml   # Wayland-native IdleInhibitor replaces systemd-inhibit hack
```

**Files merged (kept our features, added upstream improvements):**

| File | Our features kept | Upstream additions |
|------|-------------------|--------------------|
| `Weather.qml` | Error handling, ipinfo caching, geocoding dedup | Hourly forecast, reverse geocoding, Config reactivity |
| `Wallpapers.qml` | Video wallpaper support, self-contained colour gen | Fallback, setRandom, getCategoryFor, smartArg, key prop |
| `Audio.qml` | Readonly computed sinks/sources/streams | CavaProvider/BeatTracker (disabled), cycleOutput, maxVolume, app.name |
| `Players.qml` | IpcHandler structure | PersistentProperties for manualActive, getArtUrl, null guard, PostTrack toast |
| `Network.qml` | Bar-compatible API, failure-state tracking | Qt.callLater delays (500/1000/100ms) to prevent NM races |
| `Nmcli.qml` | Cleaner retry logic | connecting property + isConnectingState + connectingSsid |
| `NetworkUsage.qml` | JS array backward compat via .values export | CircularBuffer for efficient history |
| `Visibilities.qml` | Niri.focusedMonitorName keying | Map() instead of plain object {} |

**Files kept as-is (our version superior or no meaningful diff):**
```
Notifs.qml      # Our enhanced version (persistence, grouping, unread, IPC)
Colours.qml     # reduceTransparency, saveSchemeState, extended colours
Brightness.qml  # Compositor-agnostic, better error handling
GameMode.qml    # Niri-specific compositor integration
Time.qml        # Identical functionality
```

**Our custom files preserved (11):**
```
AudioPortSwitch.qml, BatteryMonitor.qml, CalEvents.qml, Cava.qml, Fonts.qml,
M3Variants.qml, Niri.qml, PolkitService.qml, scheme.json, Schemes.qml, SystemUsage.qml
```

**C++ plugin additions (missed in Phase 1):**
```
plugin/src/Caelestia/Services/audiocollector.{hpp,cpp}
plugin/src/Caelestia/Services/audioprovider.{hpp,cpp}
plugin/src/Caelestia/Services/beattracker.{hpp,cpp}
plugin/src/Caelestia/Services/cavaprovider.{hpp,cpp}
```

**C++ fixes:**
- `audioprovider.cpp`: Fixed Qt 6.11 `QMetaObject::invokeMethod` — removed extra `this` arg from `AudioCollector::ref`/`unref` calls
- `service.hpp`: Added `QML_ELEMENT` (needed for cross-namespace prototype chain resolution)
- `audioprovider.hpp`: Added `QML_ELEMENT` (needed for BeatTracker/CavaProvider prototype chain)
- `beattracker.hpp`: Changed `smpl_t` → `float` in QML-visible properties (aubio typedef unresolvable by QML engine)
- `Internal/CMakeLists.txt`: Added missing `circularbuffer.hpp` (MOC never ran, type silently not registered)

**Runtime verification:**
- Shell launches clean: `Configuration Loaded`, Niri IPC connected, no errors
- **CircularBuffer**: Fixed and working (`circularbuffer.hpp` was missing from CMakeLists.txt)
- **CavaProvider**: Crashes in `libcava` → `fftw3` segfault — third-party library bug. Disabled with diagnostic comment.
- **BeatTracker**: `Element is not creatable` in Qt 6.11 — `smpl_t` typedef, `optional plugin` qmldir, abstract `Service` base all contribute. Works on upstream's older Qt. Disabled with diagnostic comment. All fixes applied: `QML_ELEMENT` on Service+AudioProvider, `smpl_t`→`float`, qmldir `plugin` (not optional), `prefer` removed.

**Reversion:**
```fish
git checkout main -- services/
# Remove new upstream files:
rm services/NotifData.qml services/Recorder.qml services/Screens.qml
# Remove new C++ service files:
rm plugin/src/Caelestia/Services/{audiocollector,audioprovider,beattracker,cavaprovider}.{hpp,cpp}
# Revert C++ modifications:
git checkout main -- plugin/src/Caelestia/Services/audioprovider.cpp
git checkout main -- plugin/src/Caelestia/Services/service.hpp
git checkout main -- plugin/src/Caelestia/Services/audioprovider.hpp
git checkout main -- plugin/src/Caelestia/Services/beattracker.hpp
git checkout main -- plugin/src/Caelestia/Internal/CMakeLists.txt
# Rebuild and reinstall:
cmake -B build -G Ninja && cmake --build build && sudo cmake --install build
```

---

## Phase 3 Regressions (discovered 2026-06-09 during Phase 4 testing)

### StateLayer onClicked — BROKEN across 44 files ✅ Fixed

**Root cause:** Phase 3 converted `StateLayer` from a custom click-handling component to a plain `MouseArea`. The old StateLayer internally called a user-defined `onClicked()` method when clicked. The new `MouseArea` has a `clicked` signal instead.

85 instances of `function onClicked(): void {}` inside `StateLayer { }` blocks across 44 files were silently broken — `function onClicked()` defines a JS method that shadows `MouseArea.onClicked`, so the method is never called.

**Fix:** `function onClicked(): void {` → `onClicked: {` (QML signal handler syntax with colon). Applied to all instances inside `StateLayer { }` blocks via Python script.

**Files fixed (44):**
```
components/Chip.qml, components/controls/StyledRadialButton.qml
components/widgets/NotificationList.qml
modules/background/Wallpaper.qml
modules/bar/components/Power.qml
modules/bar/popouts/{Audio,Battery,Bluetooth,Network,Stasis,TrayMenu}.qml
modules/calendar/Content.qml
modules/controlcenter/{NavRail,WindowTitle}.qml
modules/controlcenter/appearance/FontDropdown.qml
modules/controlcenter/appearance/sections/{ColorScheme,ColorVariant}Section.qml
modules/controlcenter/audio/AudioPane.qml
modules/controlcenter/bluetooth/{Details,DeviceList,Settings}.qml
modules/controlcenter/launcher/LauncherPane.qml
modules/controlcenter/network/{Ethernet,Vpn,Wireless}List.qml
modules/controlcenter/network/WirelessPasswordDialog.qml
modules/dashboard/{Media,WindowTools}.qml
modules/dashboard/dash/{Media,User}.qml
modules/keybinds/Content.qml
modules/launcher/items/{Action,App,Calc,Clip,Scheme,Variant,Wallpaper,Web}Item.qml
modules/lock/{Center,Media,NotifGroup}.qml
modules/notifications/Notification.qml
modules/polkit/PolkitDialog.qml
modules/session/Content.qml
```

**Intentionally excluded (correct as-is):**
- `Actions.qml`, `Schemes.qml`, `M3Variants.qml` — `function onClicked(list: ...)` with parameter, called explicitly by parent code
- Component-root-level `function onClicked()` — method definitions called by child StateLayer handlers via `root.onClicked()`

### Visibilities.screens Map() — BROKEN launcher + session + all drawers ✅ Fixed

**Root cause:** Phase 4 merged upstream's `Map()` for both `screens` and `bars`. `Drawers.qml:112` uses bracket notation: `Visibilities.screens[name] = this`. JavaScript `Map` objects don't support bracket assignment (entries must be set via `.set()`). All drawer visibility objects were silently not stored, so launcher, session, dashboard etc. could never open.

**Fix:** Reverted `screens` to `{}` (plain object, bracket notation compatible). Kept `bars` as `Map()` — consumers correctly use `.set()`/`.get()`.

### Remaining component-root-level onClicked (not yet broken — deferred)

~30 instances of `function onClicked()` at component-root level exist on button instances (`WorkspaceButton`, `IconTextButton`, etc.) that extend `ButtonBase`. These define a JS method that shadows the component's `onClicked` signal handler. Likely also broken but no reports yet. To fix: change to `onClicked: {` on each instance. Files affected:
```
modules/dashboard/WindowTools.qml:63,100,109,119,129,140,164,209
modules/dashboard/Media.qml (several)
modules/dashboard/dash/Media.qml (several)
modules/lock/Media.qml (several)
modules/controlcenter/components/WallpaperGrid.qml
modules/launcher/EmojiList.qml
components/widgets/WindowDecorations.qml
```

### Config key fallbacks — NaN layout crashes ✅ Fixed (2026-06-10)

Several config keys were deleted in Phase 2 (C++ Config migration) but consumers weren't updated with fallbacks. Undefined values propagated to `implicitWidth`/`implicitHeight`/anchors, producing `NaN` and collapsing layouts.

| Key | Used in | Fallback | Effect |
|-----|---------|----------|--------|
| `TokenConfig.sizes.dashboard.mediaVisualiserSize` | `Media.qml` root `implicitWidth`/`implicitHeight`, cover `anchors.leftMargin` | `|| 0` | NaN → RowLayout collapse, dashboard transparent |
| `TokenConfig.sizes.dashboard.mediaIconSize` | `Media.qml` `PlayerIcon` | `|| 48` | `undefined` assign to double warnings |
| `TokenConfig.sizes.dashboard.resourceProgessThickness` | `Resources.qml` progress bar | `?? 8` | `undefined` assign to double warnings |
| `Config.dashboard.toggles.*` (showWifi, showBluetooth, etc.) | `QuickToggles.qml` `visible` bindings | `?. ?? true` | `undefined` assigned to bool warnings |

### CUtils.clamp — stale installed plugin ✅ Fixed (2026-06-10)

`CUtils.clamp` worked in the built `.so` but the installed copy was stale. `cmake --install` compared timestamps and marked `libcaelestia.so` and `caelestia.qmltypes` as "Up-to-date" — never overwriting them. The QML engine reads `qmltypes` to resolve methods; without `clamp` listed, it threw `is not a function`.

**Fix:** Manually installed `libcaelestia.so` and `caelestia.qmltypes` from build directory. Same issue affected all Phase 1 C++ changes — any `touch`/rebuild must be followed by explicit install since cmake timestamp checks are unreliable.

### Dashboard Media tab — visualiser/BeatTracker/bongocat ✅ Fixed (2026-06-10)

When the Media pane Loader activated, multiple issues cascaded:
1. `CavaProvider` (`Cava.values`) not started — `ServiceRef` disabled, no `ref()` call. `Cava.values[modelData]` returned `undefined` → visualiser bars rendered NaN geometry
2. `BeatTracker.bpm` — ServiceRef disabled, type not creatable under Qt 6.11
3. `visualiser.width`/`visualiser.height`/`visualiser.right` — dead references after visualiser commented out (bongocat + details anchors)

**Fix:** Visualiser + ServiceRef instances commented out. `visualiserSize` property with `|| 0` fallback. Details anchor `visualiser.right` → `cover.right`. Bongocat dimensions → parent-relative. `bongoSpeed` hardcoded to 0.5.

### Album art quality — FadeImage sourceSize + YouTube resolution ✅ Fixed (2026-06-10)

**FadeImage sourceSize:** `sourceSize: Qt.size(width * dpr, height * dpr)` downscaled album art to component pixel dimensions before render. On high-DPI displays with DPR detection failure, this halved the effective resolution. Removed `sourceSize`; added `mipmap: true` + `smooth: true` for GPU-native scaling.

**YouTube thumbnails:** `hqdefault.jpg` (480×360) → `maxresdefault.jpg` (1280×720). YouTube URL now checked before `trackArtUrl` to prevent MPRIS metadata updates from overwriting with lower-res player thumbnail.

### Upstream issues matching our Qt 6.11 deferred items (2026-06-09)

| Issue | Status | Relevance |
|-------|--------|-----------|
| [#1483](https://github.com/caelestia-dots/shell/issues/1483) — PipeWireWorker deadlock on libpipewire 1.6.5 | Open | Same distro, same Qt. `CavaProvider`/`BeatTracker` destruction hangs. |
| [#1442](https://github.com/caelestia-dots/shell/issues/1442) — QQuickPropertyChanges SIGSEGV on Qt 6.11 | Open | Qt 6.11 QML engine crash. |
| [#1401](https://github.com/caelestia-dots/shell/issues/1401) — "Unavailable Types" after PR 1392 | Closed | Similar pattern to our BeatTracker "not creatable." |

## Phase 5 — Bar Module + Drawer Infrastructure ✅ (2026-06-09 / 2026-06-10)

**What was done:**

Full upstream adoption of the bar module AND the drawer orchestration layer (`Interactions.qml`, `Panels.qml`, `Backgrounds.qml`) that all modules plug into. This was a two-day effort — initial bar QML merge on 2026-06-09, then the drawer infrastructure cascade + module wrappers on 2026-06-10.

### Day 1 — Bar QML (2026-06-09)

**New upstream files copied (4):**
```
modules/bar/popouts/PopoutState.qml          # Popout state tracker (8 lines)
modules/bar/popouts/ClipWrapper.qml          # Popout positioning wrapper
modules/bar/popouts/kblayout/KbLayout.qml    # Rich keyboard layout popout UI
modules/bar/popouts/kblayout/KbLayoutModel.qml  # Niri-adapted layout data model
```

**Skipped Hyprland-specific (5):**
```
modules/bar/popouts/ActiveWindow.qml
modules/bar/components/workspaces/ActiveIndicator.qml
modules/bar/components/workspaces/OccupiedBg.qml
modules/bar/components/workspaces/SpecialWorkspaces.qml
modules/bar/components/workspaces/Workspace.qml
```

**Accepted upstream (11 shared files):**
```
modules/bar/components/Clock.qml, Power.qml, Tray.qml, TrayItem.qml (merged—kept iconSubs)
modules/bar/popouts/Audio.qml, Battery.qml, Bluetooth.qml, Network.qml, TrayMenu.qml, WirelessPassword.qml, LockStatus.qml (Niri-adapted capsLock/numLock)
```

**Adopted upstream structure (3):**
```
modules/bar/BarWrapper.qml   # fullscreen, disabled regex, exclusiveZone, Anim.Emphasized
modules/bar/popouts/Wrapper.qml   # Added PopoutState child + offsetScale property
modules/bar/popouts/Content.qml   # Upstream Popout pattern + wsWindow/stasis Niri popouts
```

**Type migration — PersistentProperties → DrawerVisibilities:**
```
modules/drawers/Drawers.qml → DrawerVisibilities
modules/bar/Bar.qml → DrawerVisibilities + fullscreen
modules/bar/components/Power.qml → DrawerVisibilities
```

**KbLayout Niri adaptation:**
- `KbLayoutModel.qml`: Removed all `hyprctl` Processes. `Niri.kbLayoutsArray` + `Niri.kbLayoutIndex` for state, `cycleLayout()` calls `Niri.action("switch-layout", [])`. Kept XKB XML display name parsing.
- `KbLayout.qml`: "Next Layout" cycle button, display-only layout list, active highlight with pop-in animation.
- Old `popouts/KbLayout.qml` deleted.

### Day 2 — Drawer Infrastructure Cascade + Module Wrappers (2026-06-10)

The initial bar merge kept our custom `Interactions.qml` and `Panels.qml`. This caused the dashboard hover to break (no `offsetScale`-aware `inTopPanel`). Full upstream adoption cascaded:

**Drawer orchestration (3 files adopted upstream):**
```
modules/drawers/Interactions.qml  # offsetScale-aware panel hover, fullscreen support, sidebar drag
modules/drawers/Panels.qml        # Upstream panel registry with wrapper aliases
modules/drawers/Drawers.qml       # borderThickness + fullscreen propagation
```

**Module wrappers adopted upstream (6):**
```
modules/osd/Wrapper.qml             # sidebarOrSessionVisible, hovered, brightness/volume props
modules/notifications/Wrapper.qml   # sidebarPanel, osdPanel/sessionPanel/utilitiesPanel aliases
modules/session/Wrapper.qml         # offsetScale, shouldBeActive
modules/launcher/Wrapper.qml        # offsetScale, shouldBeActive
modules/utilities/Wrapper.qml       # offsetScale, shouldBeActive
modules/sidebar/Wrapper.qml         # offsetScale, shouldBeActive, utilsRoundingX added
```

**Module backgrounds fixed (6 — upstream ShapePath always rendered, added Active-based visibility):**
```
modules/dashboard/Background.qml  # strokeWidth: 0 + fillColor: "transparent" when !shouldBeActive
modules/sidebar/Background.qml    # Same pattern
modules/osd/Background.qml        # Same pattern
modules/launcher/Background.qml   # Same pattern
modules/session/Background.qml    # Same pattern
modules/utilities/Background.qml  # Same pattern + sidebar + rounding required props
```

**Notifications upstream adopted (kept our Notifs service):**
```
modules/notifications/*          # Upstream QML files, restored custom Notifs.qml service
modules/notifications/Wrapper.qml # Upstream version
modules/notifications/Background.qml # Fixed: active when wrapper.height > 0
```

**Custom panels preserved (2):**
```
modules/drawers/Panels.qml → added Keybinds.Wrapper + Calendar.Wrapper entries (not in upstream)
modules/drawers/Backgrounds.qml → kept references to Keybinds.Background + Calendar.Background
```

### C++ additions (both days)

**Day 1:**
- `niriipc.cpp/.hpp`: Added `handleKeyboardLayoutSwitched` — listens for `KeyboardLayoutSwitched` event with `idx: u8`, updates `m_kbLayoutIndex` reactively (no polling).
- `tokens.hpp/.cpp`: Added `font` (FontTokens*) and `anim` (AnimTokens*) Q_PROPERTY to `TokenConfig` singleton. Bound in `TokenConfig::create()`.

**Day 2:**
- `cutils.hpp/.cpp`: Added `exists(const QString& path)` Q_INVOKABLE — file-existence check.
- `cpu.hpp/.cpp`, `memory.hpp/.cpp`, `storage.hpp/.cpp`: Added `static create(QQmlEngine*, QJSEngine*)` factory methods — required by Qt 6.11 for `QML_SINGLETON` types.
- `filesystemmodel.hpp/.cpp`: Replaced with upstream version — adds `sortReverse`, `Filter` enum (`NoFilter`, `Images`, `Files`, `Dirs`).
- `services/Weather.qml`: Added `formatTemp()` and `toFahrenheit()` to match upstream API.
- `services/Notifs.qml`: Added `hasFullscreen()` — returns false (Niri doesn't expose fullscreen state in IPC).
- `services/Wallpapers.qml`: Changed `FileSystemModel.ImagesAndVideos` → `FileSystemModel.Images` + `nameFilters` (upstream FileSystemModel changed Filter enum).

**Stale `.so` cleanup (3 files removed):**
```
/usr/lib/qt6/qml/Caelestia/Services/libcaelestia-services.so   # Jun 8, shadowing fresh .so in ../lib/
/usr/lib/qt6/qml/Caelestia/libcaelestia.so                     # Jun 8, shadowing fresh .so in lib/
/usr/lib/qt6/qml/Caelestia/Models/libcaelestia-models.so       # Jun 8, shadowing fresh .so in ../lib/
```
Root cause: old cmake installs put shared libs in module directories. RUNPATH `$ORIGIN` resolved to stale file first. Clean rebuild (`rm -rf build`) + fresh install fixed.

**Dash Media BeatTracker (Qt 6.11 workaround):**
- `modules/dashboard/dash/Media.qml`: Disabled `ServiceRef { service: Audio.beatTracker }`, hardcoded `speed: 0.5`.

### Post-merge fixes summary

| Issue | Root cause | Fix |
|-------|-----------|-----|
| Clock.qml font builder | `TokenConfig` lacked `font`/`anim` Q_PROPERTY | Added FontTokens/AnimTokens to singleton |
| Dashboard hover broken | `Interactions.qml` used old `inTopPanel` without `offsetScale` | Adopted upstream Interactions.qml |
| Dashboard background stuck | `visible: false` on Wrapper → height 0 → mask hole gone | Changed to `visible: true`, use `anchors.topMargin` for hiding |
| Sidebar/OSD/Launcher/Session/Utilities backgrounds stuck | ShapePath always renders | Added `strokeWidth: 0` + `fillColor: transparent` when !shouldBeActive |
| `Cpu`/`Memory`/`Storage` not found | Qt 6.11 requires `create()` for QML_SINGLETON; stale .so blocking | Added `create()` methods; removed stale .so |
| `CUtils.clamp` / `CUtils.exists` | Stale .so + missing method | Removed stale .so; added `exists()` to CUtils |
| `FileSystemModel.ImagesAndVideos` | Upstream changed Filter enum | Changed to `FileSystemModel.Images` + `nameFilters` |
| `FileSystemModel.sortReverse` | Old FileSystemModel lacked property | Adopted upstream FileSystemModel |
| `Weather.formatTemp` | Missing method on our Weather service | Added `formatTemp()` + `toFahrenheit()` |
| `Notifs.hasFullscreen` | Missing method on our Notifs service | Added `hasFullscreen()` stub |

---

## Phase 6 — Dashboard ✅ (2026-06-10)

**What was done:**

Full upstream dashboard replacement. Backed up 6 custom files to `.backup/`.

**New upstream files copied (14):**
```
modules/dashboard/dash/Calendar.qml
modules/dashboard/dash/SmallWeather.qml
modules/dashboard/media/BackgroundShapes.qml
modules/dashboard/media/CoverVisualiser.qml
modules/dashboard/media/Details.qml
modules/dashboard/media/LyricList.qml
modules/dashboard/media/LyricsAndSelector.qml
modules/dashboard/media/LyricsInfo.qml
modules/dashboard/performance/BatteryTank.qml
modules/dashboard/performance/HeroCard.qml
modules/dashboard/performance/MemoryCard.qml
modules/dashboard/performance/NetworkCard.qml
modules/dashboard/performance/StorageCard.qml
modules/dashboard/WeatherTab.qml
```

**Shared files replaced with upstream (7):**
```
modules/dashboard/Content.qml, Dash.qml, Media.qml, Performance.qml, Tabs.qml, Wrapper.qml
modules/dashboard/dash/DateTime.qml, Media.qml, Resources.qml, User.qml
```

**Custom files backed up (6 → .backup/):**
```
WeatherPanel.qml, WindowTools.qml, Background.qml (restored—needed by drawers)
QuickToggles.qml, UpcomingEvents.qml, Weather.qml
```

---

## Merge Rules for Remaining Phases (7-10)

Established after Phase 5 lessons learned:

1. **Copy-first, fix-forward** — upstream version goes in first. Any cascade gets chased to completion with MORE upstream files, never a revert to ours.

2. **Dependency tree first** — before touching any file, map the full import/reference graph. If adopting `File A` means also adopting `File B` through `File Z`, that's the plan — not a surprise.

3. **Services over hacks** — missing API on our services gets added to match upstream expectations. QML never gets rewritten to work around gaps.

4. **Shared = upstream** — any file present in both trees gets the upstream version. Our-only files stay; upstream-only files get copied; no "merge" that quietly keeps our old version.

5. **One module tree at a time** — each phase gets its own full dependency analysis up front, so the cascade is planned, not discovered.

6. **Three-way merge via `git merge-file`** — for any file present in both trees with custom Niri additions:
   - Get three versions: ours, upstream, merge base (from git common ancestor)
   - Run `git merge-file ours base upstream` — auto-resolves non-conflicting changes
   - Manual resolution only for conflicts — always keep our Niri-specific additions inside the upstream structure
   - Post-merge: diff against upstream to confirm only intentional differences remain

### Additional enforcement

7. **No `git checkout` to restore old files** — once upstream is in, fixes go forward, never back.

8. **Every phase ends with `rm -rf build && cmake -B build && cmake --build build && sudo cmake --install build`** — clean rebuild prevents stale `.so` issues.

9. **Post-install verification**: `qs -c caelestia-niri-shell` must load with zero scene warnings (cosmetic QML type warnings and other-agent-registration warnings are acceptable).