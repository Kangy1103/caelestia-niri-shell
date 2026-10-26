# CNS optimisation implementation and validation

**Status, 26 October:** conservative optimisation pass completed; native wallpaper deployment is active. Final verification and residual diagnostics are in the completion section below.

25 October 2026 · Umbriel · work restricted to `optimisation`

## Decisions

| Area | Decision | Reason |
|---|---|---|
| Closed overlay surfaces | Keep the implemented on-demand mapping and picker lifecycle fixes | The earlier matched validation measured 559 MiB less CNS-attributed GPU allocation and 782 MiB more device-free VRAM. These are overlapping measurements, not additive savings. |
| Stasis polling | One shared status service | Retains complete status/tooltip data and controls; avoids querying independently from four bars and a popout. |
| Render loop | Keep `threaded` | `basic` saves substantial host memory, but had less consistent animation steps in the valid trial and has not received a human responsiveness comparison under load. |
| Feature caches | Retain useful image, font and application-list caches | Profiling did not establish a growing JavaScript leak or justify repeatedly paying construction/decoding costs. |
| Animation clock | Retain current production driver | Qt's multiple-window timer fallback explains the observed cadence. The earlier simple-driver experiment had a major idle CPU/GPU regression. |
| Wallpaper implementation | Port current upstream Visual/cache architecture, preserve CNS transitions and fit/preview behavior | Requested upstream integration, with explicit resource lifetimes, failures and playback handling. It is not presented as a major memory saving. |
| Wallpaper compression | Lossless PNG by default | Real BC3/KTX captures show small color/detail changes. Preserve fidelity; leave compression opt-in for deliberate comparisons. |
| Full-screen shell effects | Keep existing resolution, shadows and composition | Prior ablations saved memory by changing appearance. No demonstrated equivalent composition justifies a broader rewrite in this pass. |

## Changes committed

- `fc7e86e7`: shared Stasis polling across bars/popout.
- `0828b16a`: Umbriel workspace screenshots no longer invoke Niri's clipboard-history cleanup.
- `9be46140`: picker array return/property typing, validated resolution/aspect/purity values, fit persistence.
- `ef9488b3`: compositor-independent monitor power IPC and Niri-to-Umbriel power-action aliases.
- `8a57cde2`: failed VPN status-command startup becomes an error state; clears stale connection state and pending automatic connection.
- `7a4d6cdd`: upstream wallpaper backend, cache, shader transition, multimedia regression tests.

Earlier overlay/lifecycle commits remain part of this branch. `main` remains the saved pre-optimisation shell.

The live Stasis configuration at `~/.config/stasis/stasis.rune` was also updated to use CNS's compositor power IPC. Its original bytes are backed up locally. That external dotfile is not silently included in the shell repository; the IPC interface and example are documented in `docs/idle-compositor-routing.md`.

## Measurements

### Shared polling

Matched 45-second idle windows, CPU expressed as a percentage of **one logical core**:

| CPU owner | Before | Shared service |
|---|---:|---:|
| CNS process | 0.764% | 0.787% |
| Exited helper children | 0.742% | 0.202% |
| Combined | 1.505% | 0.989% |

This is a small absolute CPU saving of about 0.52 percentage points of one core. It does not imply a large whole-system CPU reduction. Controls were actually exercised and restored: inhibition, gaming profile, video profile and popout.

### Native and JavaScript memory

The QML trace recorded approximately 3.2 million events. Peak JavaScript heap-page allocation was about 15 MiB; the final live small-object count represented approximately 3.3 MiB. Inclusive function/binding durations overlap and must not be summed as CPU costs.

The debugger/trace buffer itself inflated native allocations. Therefore the same feature sequence was repeated with allocator profiling **without** the QML debugger:

| Actual allocator metric | Old wallpaper | New wallpaper |
|---|---:|---:|
| Allocated at initial idle | 431.77 MiB | 446.37 MiB |
| Allocated after feature exercise | 451.10 MiB | 465.23 MiB |
| Feature-use retained allocation | 19.33 MiB | 18.86 MiB |
| Allocator resident, initial → final | 519.45 → 517.30 MiB | 542.04 → 541.20 MiB |

This is not evidence of continuous leakage: allocation retention was bounded over this short sequence and allocator-resident bytes declined slightly. Native graphics/font allocations dominate much more than JavaScript. Sampled names in proprietary or stripped driver libraries are approximate attribution, not proof about the named function's behavior.

The new backend adds some native infrastructure memory. Independent fresh-launch runs also showed roughly 15–22 MiB more warmed RSS in the new threaded condition, while GPU allocation differences overlapped run-to-run variation. **No meaningful wallpaper-port memory saving is claimed from these measurements.**

### Valid render-loop comparison

Same current QML, startup directive explicitly changed for the basic trial, loop verified in Qt's launch diagnostics. Eight launcher open/type/clear/close cycles, other drawers and wallpaper picker were exercised per run.

| Warm final idle | New threaded run A | New threaded run B | New basic |
|---|---:|---:|---:|
| CNS GPU allocation | 918.1 MiB | 936.1 MiB | 843.1 MiB |
| Host RSS | 1,257.1 MiB | 1,250.3 MiB | 868.3 MiB |
| Animation-step median | 16 ms | 16 ms | 17 ms |
| Animation-step p95 | 17 ms | 17 ms | 24 ms |

Basic therefore saved about 382–389 MiB RSS and 75–93 MiB CNS-attributed GPU memory in these comparisons. Scripted typed text arrived correctly in all eight launcher cycles in each condition. This is functional input verification, not a key-to-photon latency measurement or a human judgment of feel.

One earlier condition named "basic" was invalid: CNS's forced QML environment directive overrode the supplied process environment. Its log proved it was threaded. That run is retained under `render-loops/INVALID-basic-request-was-threaded` and excluded from the comparison above.

Given the user's existing smoothness concern, the narrower validation under load, and the poorer timing tail in this trial, production remains threaded.

## Wallpaper integration

Port pinned to [Caelestia 4b1dae84b1b3b28bf486776ba30c1c1ec74fb64d](https://github.com/caelestia-dots/shell/tree/4b1dae84b1b3b28bf486776ba30c1c1ec74fb64d), specifically its [Multimedia backend](https://github.com/caelestia-dots/shell/tree/4b1dae84b1b3b28bf486776ba30c1c1ec74fb64d/plugin/src/Caelestia/Multimedia) and [WallpaperImpl](https://github.com/caelestia-dots/shell/blob/4b1dae84b1b3b28bf486776ba30c1c1ec74fb64d/components/widgets/WallpaperImpl.qml).

Retained:

- Current CNS transition duration/easing and zoom behavior.
- Crop, whole-image fit and blurred-fill modes across all four output geometries/scales.
- Immediate live previews and the picker-covered screen's readiness handoff.
- Muted video wallpaper, infinite playback, game-mode pause/resume.
- Existing CNS.Images consumers; this does not replace unrelated image components wholesale.

Adaptations:

- CNS module/cache names, lossless default and millisecond modification times in cache keys.
- Dedicated low-priority cache thread, bounded disk cache and two BC3 encoder workers.
- Explicit callback shutdown before native destruction; guarded item/output pointers.
- New sources invalidate stale readiness; missing image paths and media failures reach the fallback UI.
- Transition capture completion checks identity/pending state; rapid requests coalesce while capture is pending.
- Snapshot objects and the shader/live-target graph are destroyed after transitions. Clearing `sourceItem` alone is insufficient for a frozen Qt layer: [Qt 6.12 layer source](https://github.com/qt/qtdeclarative/blob/v6.12.0/src/quick/scenegraph/qsgrhilayer.cpp) retains resources for non-live layers. Unloading the shader before its inputs also avoids invalid-provider warnings.

### Visual checks and corrections

The initial old/new comparison exposed a stale-image bug in the old implementation. The old state logs show HDMI retaining the ordinary wallpaper after a fit change and other outputs retaining the previous wide fixture during the portrait fit/blur cases. Those captures are **not valid visual parity references** for the requested new image.

Correction to the early diagnosis: the apparent "stretched portrait" was actually the previous wide image still displayed. It does not establish an aspect-ratio bug. The replacement was checked independently for the expected wide/portrait geometry and current-source readiness.

Twenty-four lossless captures cover two fixture aspect ratios × three fit modes × four outputs. Readiness is asserted before capture. Images were visually inspected, including portrait placement, blurred fill, rotated/fractional-scale outputs and gradient/grid detail.

Compression was tested separately with cold and warm caches. All 24 warm BC3 captures were verified to use `.ktx` paths. Differences were small but measurable and visible as subtle gradient/detail changes; the side-by-side 1:1 crop is `wallpaper-cache-comparison.png`. Default remains lossless. Compression savings are not claimed without a separate matched resource run.

## Correctness and stability checks

- Shared Stasis: all four bars agree, complete tooltip data remains, actual controls restore successfully.
- Workspace preview: screenshots correct; clipboard database hash unchanged byte-for-byte under Umbriel.
- Picker settings: isolated valid/malformed-input checks and persisted-fit check passed.
- VPN status process: missing command → success → missing command fixture passes, clearing stale connected state without attempting a VPN connection. No VPN software was installed or connection changed.
- Monitor power: actual off/on cycle verified in compositor state for all four outputs, with an independent timed wake fallback. Stasis profile preserved.
- Wallpaper: 13 live behavior checks pass, including interrupted transitions, resource-object cleanup, same-source handoff, empty/missing sources, missing video, playback progression, paused-frame identity, resume and video-to-image switching.
- Native regression suites: 10 repeats pass under AddressSanitizer/UndefinedBehaviorSanitizer. Multimedia includes 50 source/item teardown cycles per repeat, lossless cache reopen, fit behavior, missing-source propagation and 512 MiB budget enforcement using sparse temporary files. LeakSanitizer is disabled for Qt process-lifetime allocations; address/UB checks remain active.
- Full normal plugin build succeeds.
- 20 live hot reloads with picker/launcher interactions pass without a process restart. Temporary probes/comments restored afterward.
- Texture-provider warnings found during transition teardown were traced and removed by ordering shader destruction before texture destruction. Deliberately missing media still produces expected Qt/FFmpeg diagnostics in negative tests.

## Animation clock and effect decisions

The installed Qt is 6.12.0. Its [threaded render-loop source](https://github.com/qt/qtdeclarative/blob/v6.12.0/src/quick/scenegraph/qsgthreadedrenderloop.cpp#L1011-L1058) switches regular animations to a system timer when multiple windows are exposed, or when vsync assumptions fail. CNS has multiple exposed output/shell windows. This agrees with the measured ~16 ms position updates; more render callbacks alone do not imply more animation positions.

Qt's [animation-driver documentation](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html#driving-animations) describes the alternative driver and its tradeoffs. The prior local simple-driver trial raised CNS idle CPU to about 51% of a core and GPU utilization to about 73%; it remains rejected. No unsupported primary-screen environment variable or private Qt animation-driver replacement was introduced.

Full-screen effects remain unchanged. Cutting their resolution, shadow area or composition without demonstrated parity would conflict with preserving the shell's look. A region-based redesign can be a later measured project; it is not required to finish this conservative pass.

## Final soak and deployment at the requested stop

Stopped at the user's request during the wallpaper-picker settling phase. Completed portions include the initial 120-second idle window, three cycles of all ten drawers, three real Alt+Tab/release cycles and three wallpaper-picker cycles. The capture-picker, notification and final idle portions were **not completed**. Partial samples/checks were saved by the harness's cleanup handler. This is not reported as a completed soak.

The new native module is built/tested but not installed under `/usr/lib`; `sudo -n` requires a password. To leave normal startup working, the two background QML files are temporarily deployed from the previous working commit (`8a57cde2`). They intentionally differ from the committed `optimisation` versions. All other completed fixes remain active, and the new wallpaper implementation is committed/pushed and retained in the activation stage.

One ordinary CNS instance was restarted and verified without temporary QML import paths or profiling preload. UI/inhibitor state was restored. The prepared `install-cns-multimedia.sh` installs only the four new native-module files, verifies checksums, and runs `activate-cns-wallpaper.py` as the user to activate the tested QML. The activation helper refuses unknown user edits, requires matching installed native hashes, keeps backups and is tested for refusal, successful activation and idempotence.

### Remaining findings to investigate when resumed

The reload logs exposed null-object binding warnings in `modules/notifications/Notification.qml`, plus undefined fallback values during teardown in `services/Time.qml` and `services/Compositor.qml`. They were inspected but **not changed** before the user asked to stop. Reproduce/guard those lifetimes before claiming a clean reload log. Qt Wayland text-input focus warnings and an external tray item's D-Bus property error also remain; no input-loss cause was established.

No lock/authentication, logout, suspend or human smoothness comparison was performed during this unattended pass.

Raw local evidence is under this report's directory. The large profiler traces, test screenshots, desktop-state data and build artifacts remain local; they are not published as shell source.

## Installation verification after the user ran the installer

The system installation and activation are now complete. All four native module files and all three wallpaper QML files match the tested activation manifest. Both background files now match committed `optimisation`; the temporary previous-wallpaper deployment is resolved.

A clean start with the ordinary `cns-start` succeeded. `/proc` mappings confirm both multimedia libraries load from `/usr/lib/qt6/qml/CNS`, with no staged QML import path, profiler preload or allocator profiling flags. A temporary read-only probe verified the actual selected wallpaper is ready and settled on all four outputs; background captures were visually inspected. The probe was removed and ordinary startup verified again. No configuration errors were logged.

Evidence: `installed-verification/checks.json`, normal startup/runtime logs and four output captures. This verification did not resume the unfinished optimisation/soak work listed above.

## Completion pass — 26 October 2026

This closes the conservative optimisation pass. The rendering/default-quality decisions above remain in force: threaded rendering, unchanged effects and animation curves, useful caches retained, and lossless wallpaper caching by default.

### Final code changes

Commit `7669a37d`:

- Notification delegates tolerate their `NotifData` being destroyed first. Text/icon/action bindings have safe empty states; handlers do not call deleted objects. Cached notifications with no persisted hints also have a safe progress-value fallback. Live notification colours, sizing, actions and animations are retained.
- Workspace refreshes use a zero-interval, single-shot timer owned by the bar item. It still coalesces event bursts, but its callback is cancelled with the bar, preventing a delayed function from entering a destroyed QML context.
- Menus tolerate a missing window during teardown; tray entries stop dereferencing deleted menu objects. Disabled/deleted entries cannot be activated.
- Fullscreen toast policy reads `GlobalConfig`, matching its global schema instead of accessing it through a screen overlay.
- Shell-root teardown stops the old generation's SystemClock before its QML engine is interrupted. In the final repeated-reload suite, the earlier Time.qml assignment warnings did not recur.

### Targeted checks

The final suite completed ten hot reloads in one process with notifications and launcher/wallpaper overlays in use. It checked compositor availability and usable time fields after each reload, notification action-list preservation, eight exact launcher typing/clear cycles, and two open/close cycles for each of four application tray menus. The notification, menu, workspace-callback and Time.qml warnings reproduced earlier did not recur in that suite. This does not mean all reload diagnostics disappeared.

The first synthetic typing attempts were invalid as input-quality claims: immediate virtual-keyboard sequences lost input, including in a separate minimal Qt TextInput config without CNS. Allowing virtual-keyboard initialisation and using a 15 ms inter-key delay made all eight CNS typing/clear cycles pass. The minimal fixture still lost zero-delay strings; that is retained as a test limitation, not attributed to CNS. This does not measure physical keyboard latency or prove that every input-method issue is fixed.

### Residual diagnostics and limits

- Some hot reloads still emit undefined-assignment warnings from the retiring compositor facade. Each checked new generation recovered correct compositor availability and state. Adding nullish fallbacks did not resolve those warnings, so that trial was reverted. They are **not claimed fixed**. A windowless facade fixture, fed changing snapshots by a fake local IPC server, reproduced the same four typed-binding warnings on all twenty reloads, immediately after its `RETIRING ROOT` marker. Every replacement generation answered fresh state queries. The installed Quickshell generation teardown interrupts JavaScript after root destruction and before engine-owned singletons finish retiring; the reproduction isolates the warnings to that retirement path rather than the full CNS UI. A simpler clock-only fixture completed twenty reloads without warnings. This does not establish a safe patch for Quickshell or the native client, so no broad facade rewrite or warning suppression was shipped.
- Qt Wayland text-input focus warnings still occur during focus changes. Exact typed text passed with the settled virtual keyboard. The warnings alone do not establish physical input loss.
- Vesktop's StatusNotifierItem `IconName` getter returns `org.freedesktop.DBus.Error.Failed` when called directly with `gdbus`, without CNS in the call path. CNS's tray menu opens/closes; no unrelated application was restarted to hide that provider error.
- Early diagnostic attachment encountered unavailable compositor state in an already-reloaded process. A clean ordinary launch recovered it; the final controlled ten-reload suite retained availability. No source fix for that earlier state is claimed.

The installed Quickshell revision is `9b0f339b19057f4731bf3b48293307d7ef241671`. Its [generation teardown](https://github.com/quickshell-mirror/quickshell/blob/9b0f339b19057f4731bf3b48293307d7ef241671/src/core/generation.cpp) and [SystemClock implementation](https://github.com/quickshell-mirror/quickshell/blob/9b0f339b19057f4731bf3b48293307d7ef241671/src/core/clock.cpp) were read for the lifetime investigation.

### Whole-shell soak

Completed an 18.7-minute ordinary-launch run, including the 120-second initial idle baseline and a 600-second final idle observation. There were 4,456 resource samples and 39 recorded checks. The same CNS process survived throughout.

Exercised three cycles of each of ten drawers, three real Alt+Tab/Alt-release cycles, three wallpaper-picker cycles, three freeze-capture/cancel cycles across all four outputs, toasts and three silent notification/close cycles. Drawer and overlay close conditions passed, and no TypeError, undefined-assignment warning, invalid-context callback or configuration error appeared in the normal-use run. Qt text-input focus warnings and the externally reproduced Vesktop getter error remained.

The final values below use the last 120 seconds after settling. GPU allocation and host memory describe different accounting pools; these are not additive savings.

| Metric | Initial 120-second idle | Settled final 120 seconds |
|---|---:|---:|
| CNS GPU allocation, median | 910.0 MiB | 852.0 MiB |
| Host RSS, median | 1155.9 MiB | 1268.9 MiB |
| Host PSS, median | 927.2 MiB | 1014.9 MiB |
| CNS CPU, mean / one core | 0.78% | 0.73% |
| Exited-helper CPU, mean / one core | 0.22% | 0.22% |
| Threads | 47 | 47 |
| File descriptors | 349 | 350 |
| Swap | 0 MiB | 0 MiB |

Across the full final ten minutes, mean CNS plus exited-helper CPU was 1.00% of one logical core, compared with 0.99% in the initial baseline. RSS varied between 1224.9 and 1273.2 MiB; the apparent late increase in the spot checks was a bounded step, followed by a plateau. The final 120-second RSS range was only 0.21 MiB, while GPU allocation was constant at 852.0 MiB. This short run does not establish the absence of long-duration leaks.

Host RSS ended about 113 MiB above the fresh initial state after broad feature use. That retained memory is reported, not described as a saving. The earlier allocator profiling found bounded retained feature allocations; this run alone does not identify the owner of every RSS change or justify aggressive cache flushing. A brief windowless fixture also ran during the earlier part of final idle; settled final samples were collected after it exited. Device-wide GPU utilisation/free-memory samples include the rest of the desktop and are not attributed solely to CNS.

A launcher capture was visually spot-checked. This is not a pixel comparison of every panel or a human responsiveness verdict. The larger wallpaper visual/fitting/playback checks are described above. No wallpaper, theme, effect quality, refresh rate or user content was changed by this final soak.

UI overlays were closed and the original focus and idle-inhibitor state restored. Test notifications did not remain in notification history. Local evidence: `whole-shell-completed/summary.json`, `samples.csv`, `details.json`, `checks.json` and `final-completion/`.


### Delivery

The new multimedia module's installed hashes and committed wallpaper QML were rechecked. Runtime mappings point to the system module under `/usr/lib/qt6/qml/CNS`, with no staged import path or allocator preload. Temporary diagnostics are removed. Changes remain on `optimisation`; `main` is not merged.

Profiler output and runtime logs stay local; temporary full-desktop captures are removed after review. The public report contains measurements and methods, not desktop screenshots or notification content.
