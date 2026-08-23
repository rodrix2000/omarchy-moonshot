# Testing & Validation Strategy

## Test Suites

1. `tests/test_classification.py`: Unit tests for phase angle normalisation, 8-phase boundaries, and direction classification.
2. `tests/test_ephemeris.py`: Verification of core astronomy calculations, moon age, upcoming quarter events, exact event instants, and location bounds.
3. `tests/test_rise_set.py`: Validation of observer rise/set algorithms across time zones and polar regions.
4. `tests/test_timezones.py`: DST transitions, fractional offsets, and local calendar boundary handling.
5. `tests/test_protocol.py`: Protocol v1 input validation, CLI serialization, generic error envelopes, private-input redaction, and resilience.
6. `tests/qml/`: QML texture/phase render, model-to-helper lifecycle, native floating-window open/close and default no-scroll sizing, and validated atomic-state persistence tests—including save, reset, clear-active, reorder, and saved-place switching—in offscreen Quickshell.
7. `scripts/accessibility-check.sh`: Static naming, focus, Escape behavior, and non-emoji control checks.
8. `tests/test_safety.py`: Static regression preventing privilege, service-management, and tracking paths in shipped runtime source.
9. `scripts/package-check.sh`: Manifest, package hygiene, and bounded true-alpha lunar texture checks.

`scripts/qml-runtime-check.sh` is a hard gate: startup, compilation, render, lifecycle, sizing, or success-marker failures return nonzero. The release workflow also exercises `Super+W` against the installed floating window under live Hyprland; live theme switching, screen-reader output, and multi-monitor placement remain manual release checks.
