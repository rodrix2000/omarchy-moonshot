# Release Process & Gates

## Pre-Release Checklist

1. Verify all unit, golden astronomy, protocol, and integration tests pass: `make test`
2. Run QML linting and runtime smoke tests: `make test-qml`
3. Validate plugin manifest with Omarchy CLI: `omarchy plugin validate .`
4. Confirm package structure and lack of forbidden files/symlinks: `make package-check`
5. Verify Definition of Done criteria in `docs/implementation-status.md`.
6. Refresh the four live popup captures in `docs/screenshots/`, remove private location labels, regenerate `preview.png` with `./scripts/generate-preview.sh`, and inspect it at native resolution.
7. With `omarchy-shell` running, manually exercise light, dark, tinted, and high-contrast themes; keyboard traversal; screen-reader names; reduced motion; narrow/short monitor constraints; and popout switching.
