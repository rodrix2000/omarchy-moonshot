# Release Process & Gates

## Pre-Release Checklist

1. Verify all unit, golden astronomy, protocol, and integration tests pass: `make test`
2. Run QML linting and runtime smoke tests: `make test-qml`
3. Validate plugin manifest with Omarchy CLI: `omarchy plugin validate .`
4. Confirm package structure and lack of forbidden files/symlinks: `make package-check`
5. Verify Definition of Done criteria in `docs/implementation-status.md`.
