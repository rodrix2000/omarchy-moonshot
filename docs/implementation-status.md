# Moonshot Implementation Status

## Target Platform Snapshot

- **OS / Distro:** Arch Linux / Omarchy 4.0.0.alpha (omarchy 4.0.0-1)
- **Omarchy Path:** `/usr/share/omarchy`
- **Quickshell:** `Quickshell 0.3.0 (revision 28771c7c74b42e20afca0b1b63980cb46515537c, distributed by AUR (package: quickshell-git))`
- **Python:** `Python 3.14.7`
- **Plugin ID:** `io.github.rodrix2000.moonshot`
- **Entry Points:** `kinds: ["bar-widget"]`, `entryPoints: { "barWidget": "BarWidget.qml" }`

## Milestone Progress

| Milestone | Description | Status | Target / Notes |
|---|---|---|---|
| Milestone 0 | Platform Verification | Verified | Platform version, tools, and constraints verified on system |
| Milestone 1 | Repository Foundation | Verified | Manifest, docs, Makefile, licenses, CI, package checks |
| Milestone 2 | Astronomy Core | Verified | Python helper, vendored engine, 16 unit & golden tests |
| Milestone 3 | Minimal Shell Integration | Verified | BarWidget, Panel, KeyboardPanel lifecycle, popout handoff |
| Milestone 4 | Protocol Integration | Verified | AstronomyClient, request generations, last-good caching |
| Milestone 5 | Moon Rendering & Primary Panel | Verified | Canvas MoonDisk, hero metrics, north-up chart convention |
| Milestone 6 | Date Browsing | Verified | Day navigation, today jump, exact phase quarter jumps |
| Milestone 7 | Location & Timezone | Verified | Manual coordinates, IANA zones, city search, weather import |
| Milestone 8 | Accessibility & Resilience | Verified | Keyboard shortcuts, visible focus, reduced motion, fault recovery |
| Milestone 9 | Release Quality | Verified | All gates green, DoD verified, 1280x800 preview generated |

## Traceability Matrix

| Requirement | Description | State | Code | Tests | Evidence / Notes |
|---|---|---|---|---|---|
| FR-001 | Persistent bar lunar indicator | Verified | `BarWidget.qml`, `MoonDisk.qml` | `scripts/qml-check.sh` | 5 bar display modes supported |
| FR-002 | Lunar panel popup on activation | Verified | `Panel.qml`, `BarWidget.qml` | `tests/qml/LifecycleSmoke.qml` | Popout coordination & focus trap avoidance |
| FR-003 | Offline ephemeris computation | Verified | `scripts/moonshot_ephemeris.py` | `tests/test_ephemeris.py` | Vendored Astronomy Engine v2.1.19 |
| FR-004 | Exact phase classification & illumination | Verified | `scripts/moonshot_ephemeris.py` | `tests/test_classification.py` | 8 named octants + exact quarter instants |
| FR-005 | Moon age calculation | Verified | `scripts/moonshot_ephemeris.py` | `tests/test_ephemeris.py` | Measured from exact preceding new moon |
| FR-006 | Next major phase events | Verified | `scripts/moonshot_ephemeris.py` | `tests/test_ephemeris.py` | Quarter search with local timestamps |
| FR-007 | Observer rise/set & horizon | Verified | `scripts/moonshot_ephemeris.py` | `tests/test_rise_set.py` | Upper limb refraction convention tested |
| FR-008 | Date browsing & jump to today/phase | Verified | `MoonshotModel.qml`, `Panel.qml` | `tests/qml/LifecycleSmoke.qml` | 21:00 local anchor for browse dates |
| FR-009 | Location configuration (manual & search) | Verified | `LocationEditor.qml` | `tests/test_protocol.py` | Manual coords, IANA zones, Open-Meteo search |
| FR-010 | Native Omarchy theming & responsive UI | Verified | `MoonDisk.qml`, `Panel.qml` | `tests/qml/RenderSmoke.qml` | Canvas procedural rendering |
| FR-011 | Full keyboard navigation & accessibility | Verified | `Panel.qml`, `KeyboardPanel` | `tests/qml/LifecycleSmoke.qml` | Shortcuts (T, F, N, L, R, Esc), visible focus |
| NFR-001 | Strict privacy (no telemetry/tracking) | Verified | Repository-wide | `scripts/safety-check.sh` | Verified offline ephemeris, zero tracking |
| NFR-002 | Memory and CPU performance budgets | Verified | `scripts/moonshot_ephemeris.py` | `tests/test_performance.py` | Sub-150ms helper execution (<50ms measured) |
| NFR-003 | Bounded process & request generation | Verified | `AstronomyClient.qml` | `tests/test_protocol.py` | Monotonic request IDs |
