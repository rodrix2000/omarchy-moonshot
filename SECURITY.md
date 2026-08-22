# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Moonshot, please send an email to rudyrodrix@gmail.com. Please do not open public issues for security vulnerabilities until they have been addressed.

## Architecture and Capability Disclosure

- **Offline-First:** Moonshot runs astronomical computations locally via a Python helper and vendored Astronomy Engine. No network connection is used or required for ephemeris calculations, rise/set times, or phase tracking.
- **Network Boundaries:** Network access is isolated strictly to user-initiated city search (geocoding) via HTTPS to Open-Meteo. No background network requests, tracking, telemetry, or analytics exist.
- **Permissions:** Moonshot runs purely in user space under Quickshell. It requires no `sudo`, `pkexec`, systemd services, daemon processes, or system package modifications.
- **Process Boundaries:** The Python helper is executed with explicit argument vectors (`Process.command`). No shell string interpolation or shell expansion is performed.
