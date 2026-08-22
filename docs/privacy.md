# Privacy & Security

## Principles

1. **Zero Tracking:** No telemetry, metrics, user identifiers, or advertising.
2. **Offline-First:** All astronomical calculations occur locally using the bundled Python ephemeris engine.
3. **Explicit Network Use Only:** Network requests occur solely when the user interacts with the location search field in the Location Editor.
4. **Strict Provider Boundaries:** Location search queries Open-Meteo Geocoding API via HTTPS only after the user types in the disclosed city-search field. Requests have a five-second timeout and responses are capped at 64 KiB and normalized to five results.
5. **No Privileged Execution:** No `sudo`, `pkexec`, or system-level service daemon requirements.

## Local Data

- Moonshot stores only the configured label, latitude, longitude, IANA time zone, and elevation.
- State lives at `${XDG_STATE_HOME:-$HOME/.local/state}/moonshot/settings-v1.json`, is written atomically, and is restricted to the user (`0700` directory, `0600` file).
- Helper stderr and malformed provider responses are never shown verbatim, preventing accidental disclosure of private values or tracebacks.
- Clearing the location rewrites the state as unconfigured. Removing the state directory removes Moonshot’s saved location.
