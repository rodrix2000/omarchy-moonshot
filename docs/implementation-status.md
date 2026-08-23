# Moonshot Implementation Status

## Audited Platform Snapshot

- **OS / distro:** Arch Linux with Omarchy package `4.0.0-1`
- **Installed Omarchy path:** `/usr/share/omarchy`
- **Omarchy source revision:** unavailable because the installed path is a package payload, not a Git checkout
- **Quickshell:** `0.3.0`, revision `28771c7c74b42e20afca0b1b63980cb46515537c`
- **Python:** `3.14.7`
- **Plugin ID:** `io.github.rodrix2000.moonshot`
- **Entry point:** one `bar-widget`, `BarWidget.qml`, with a nested `KeyboardPanel`
- **Native shell check:** Loaded in the installed `omarchy-shell` on the 1440×900, 1.25-scale `eDP-1` output; IPC open, anchored placement, full-height sizing, no-scroll layout, and shell-log health were verified on 2026-08-22

## Milestone Progress

| Milestone | Status | Evidence and remaining work |
|---|---|---|
| Platform and repository | Automated verified | Installed package/tool versions, manifest validation, package hygiene, licensing, and failing format/safety gates |
| Astronomy core | Automated verified | Pinned Astronomy Engine and 22 unit/golden/protocol tests |
| Shell integration | Native load/placement verified | QML lint plus Quickshell render/model smoke and an installed-shell IPC open on the audited top-bar output; pointer handoff and other bar orientations remain manual |
| Protocol and resilience | Automated verified | One-active/newest-pending scheduling, three-second timeout, 64 KiB ceilings, schema checks, redacted failures, and last-good state |
| Rendering and primary panel | Visual/native verified | Native-size 1280×800 preview plus installed-shell capture inspected; generated RGBA texture, computed north-up terminator, and a full-height panel without unnecessary scrolling |
| Date and event browsing | Automated verified | Calendar-safe day stepping and exact event-instant regression test |
| Location and time zones | Core verified | Helper validation, DST/fractional-zone tests, atomic XDG state, saved-place switching/reset smoke coverage, and bounded search source review; interactive provider search remains manual |
| Accessibility and themes | Partially verified | Semantic tokens, vector controls, tab focus, accessible names, reduced-motion path, static gate, and current-theme native render; screen reader and live theme matrix remain manual |
| Release quality | Candidate gates green | Automated gates and the audited-output native smoke pass are green; multi-monitor, full live-theme matrix, and assistive-technology checks remain before marketplace sign-off |

## Traceability Matrix

| Requirement | State | Code | Automated evidence | Notes |
|---|---|---|---|---|
| Persistent bar lunar indicator | Implemented | `BarWidget.qml`, `MoonDisk.qml` | QML lint/runtime render | Five configured display modes; right-click cycle is session-local |
| Lunar popup | Implemented | `Panel.qml`, `MoonshotContent.qml` | Quickshell render/lifecycle smoke plus installed-shell capture | Native open, placement, and no-scroll sizing confirmed on the audited top-bar output |
| Offline ephemeris | Verified | `scripts/moonshot_ephemeris.py` | Astronomy and protocol tests | Vendored Astronomy Engine `2.1.19` |
| Phase, illumination, age, quarters | Verified | Helper and `MoonDisk.qml` | Golden/classification/ephemeris tests | Surface texture is illustrative; phase geometry is computed |
| Observer rise/set and horizon | Verified | Helper | Rise/set and timezone tests | Apparent altitude and upper-limb/refraction conventions documented |
| Date browsing and exact phase jumps | Verified | `MoonshotModel.qml`, helper | Exact-event and lifecycle tests | Browse dates anchor at 21:00 local; events retain exact UTC instant |
| Location configuration | Implemented | `LocationEditor.qml`, `MoonshotModel.qml` | Bounds/redaction/protocol and saved-place state tests | Manual mode and six-place switching are offline; city search is explicit Open-Meteo HTTPS |
| Theme-responsive UI | Source/current-theme verified | Production QML, `qs.Commons` tokens | QML lint/runtime preview plus installed-shell capture | Live light/dark/tinted/high-contrast switching remains manual |
| Keyboard and accessibility | Partially verified | Panel, editor, custom controls | Static accessibility gate | Screen reader output and complete native tab order remain manual |
| Privacy and bounded execution | Verified | Client, helper, editor, state model | Safety/protocol/package/runtime gates | No telemetry; raw stderr is not exposed; state is atomic and user-only |
| Performance | Verified on audited machine | Helper | `tests/test_performance.py` | Test enforces the documented helper budget |

## Manual Release Checks Still Required

1. Verify pointer open/close and sibling-popout switching from the real bar, including bottom/left/right bar orientations.
2. Switch among representative light, dark, tinted, and high-contrast Omarchy themes while the panel is open.
3. Verify placement, clipping, scroll behavior, and keyboard focus on additional short and multi-monitor layouts.
4. Exercise location search against the live provider and verify timeout/offline fallback messaging.
5. Inspect accessible names and navigation with the target screen reader, plus reduced-motion behavior.
