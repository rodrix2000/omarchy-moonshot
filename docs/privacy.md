# Privacy & Security

## Principles

1. **Zero Tracking:** No telemetry, metrics, user identifiers, or advertising.
2. **Offline-First:** All astronomical calculations occur locally using the bundled Python ephemeris engine.
3. **Explicit Network Use Only:** Network requests occur solely when the user interacts with the location search field in the Location Editor.
4. **Strict Provider Boundaries:** Location search queries Open-Meteo Geocoding API via HTTPS with bounded timeouts and sanitization.
5. **No Privileged Execution:** No `sudo`, `pkexec`, or system-level service daemon requirements.
