# Testing & Validation Strategy

## Test Suites

1. `tests/test_classification.py`: Unit tests for phase angle normalisation, 8-phase boundaries, and direction classification.
2. `tests/test_ephemeris.py`: Verification of core astronomy calculations, moon age, and upcoming quarter events.
3. `tests/test_rise_set.py`: Validation of observer rise/set algorithms across time zones and polar regions.
4. `tests/test_timezones.py`: DST transitions, fractional offsets, and local calendar boundary handling.
5. `tests/test_protocol.py`: Protocol v1 input validation, CLI serialization, error envelopes, and resilience.
6. `tests/qml/`: QML syntax, render smoke, and lifecycle tests.
