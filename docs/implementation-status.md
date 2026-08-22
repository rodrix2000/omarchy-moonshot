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
| Milestone 0 | Platform Verification | Verified | Platform version, tools, and constraints verified |
| Milestone 1 | Repository Foundation | Verified | Manifest, docs, Makefile, licenses, CI |
| Milestone 2 | Astronomy Core | In progress | Python helper, vendored engine, golden tests |
| Milestone 3 | Minimal Shell Integration | Not started | BarWidget, Panel, KeyboardPanel lifecycle |
| Milestone 4 | Protocol Integration | Not started | AstronomyClient, generations, last-good |
| Milestone 5 | Moon Rendering & Primary Panel | Not started | Canvas MoonDisk, hero metrics, themes |
| Milestone 6 | Date Browsing | Not started | Day nav, today, next full/new jumps |
| Milestone 7 | Location & Timezone | Not started | Manual coords, IANA zone, search, weather import |
| Milestone 8 | Accessibility & Resilience | Not started | Keyboard nav, focus, reduced motion, fault injection |
| Milestone 9 | Release Quality | Not started | Gates, DoD verification, preview, changelog |

## Traceability Matrix

| Requirement | Description | State | Code | Tests | Evidence / Notes |
|---|---|---|---|---|---|
| FR-001 | Persistent bar lunar indicator | In progress | `BarWidget.qml`, `MoonDisk.qml` | `tests/test_qml.py` | Validated manifest entry point |
| FR-002 | Lunar panel popup on activation | Not started | `Panel.qml`, `BarWidget.qml` | `tests/qml/LifecycleSmoke.qml` | Handoff & popout coordination |
| FR-003 | Offline ephemeris computation | In progress | `scripts/moonshot_ephemeris.py` | `tests/test_ephemeris.py` | Vendored Astronomy Engine |
| FR-004 | Exact phase classification & illumination | In progress | `scripts/moonshot_ephemeris.py` | `tests/test_classification.py` | 8 named phases + 4 major quarters |
| FR-005 | Moon age calculation | In progress | `scripts/moonshot_ephemeris.py` | `tests/test_ephemeris.py` | Measured from exact previous new moon |
| FR-006 | Next major phase events | In progress | `scripts/moonshot_ephemeris.py` | `tests/test_ephemeris.py` | Quarter search with local timestamps |
| FR-007 | Observer rise/set & horizon | In progress | `scripts/moonshot_ephemeris.py` | `tests/test_rise_set.py` | Upper limb refraction convention |
| FR-008 | Date browsing & jump to today/phase | Not started | `MoonshotModel.qml`, `Panel.qml` | `tests/qml/LifecycleSmoke.qml` | 21:00 local for non-current dates |
| FR-009 | Location configuration (manual & search) | Not started | `LocationEditor.qml` | `tests/test_protocol.py` | Optional manual coords + Open-Meteo search |
| FR-010 | Native Omarchy theming & responsive UI | Not started | `MoonDisk.qml`, `Panel.qml` | `tests/qml/RenderSmoke.qml` | Canvas procedural rendering |
| FR-011 | Full keyboard navigation & accessibility | Not started | `Panel.qml`, `KeyboardPanel` | `tests/qml/LifecycleSmoke.qml` | Shortcuts, visible focus, escape |
| NFR-001 | Strict privacy (no telemetry/tracking) | Verified | Repository-wide | `scripts/safety-check.sh` | No background calls or tracking |
| NFR-002 | Memory and CPU performance budgets | Not started | `scripts/moonshot_ephemeris.py` | `tests/test_performance.py` | Sub-150ms helper execution |
| NFR-003 | Bounded process & request generation | Not started | `AstronomyClient.qml` | `tests/test_protocol.py` | Monotonic request IDs |
