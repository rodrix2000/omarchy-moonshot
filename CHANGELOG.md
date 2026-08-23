# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-22

### Added
- Initial release of Moonshot for the Omarchy shell.
- Living bar indicator with configurable display modes (`disk`, `illumination`, `phase`, `next-full`, `moonrise`).
- Rich lunar panel with a realistic generated lunar texture, computed Canvas phase mask, illumination metrics, and moon age.
- Accurate upcoming major phase quarter events (New, First Quarter, Full, Last Quarter).
- Observer-based local rise and set times with horizon altitude checks.
- Date navigation supporting day stepping, jumps to Today, and jumps to next Full/New Moon.
- Offline-first architecture powered by pinned vendored Astronomy Engine (v2.1.19).
- Location editor supporting manual coordinates, IANA time zones, and explicit city search.
- A six-place travel list with one-click switching, clear-active behavior, and confirmed reset-all handling.
- Full keyboard navigation, shortcuts, visible focus, and reduced-motion support.

### Changed
- Reworked the panel hierarchy, observer band, upcoming-event rail, controls, vector icons, and responsive sizing from a full-window visual concept.
- Made production surfaces and controls use Omarchy semantic theme tokens; kept lunar albedo neutral for theme independence.
- Preserved exact UTC instants when jumping to New or Full Moon and corrected remote-zone wall-time formatting.
- Resolved Omarchy’s Vim-style lowercase `l` navigation conflict by assigning the Location shortcut to `Shift+L`.
- Made Omarchy Weather import feedback appear only after an explicit import request instead of when the editor opens.
- Made helper requests one-active/newest-pending with a three-second timeout, bounded output, response validation, and last-good fallback.
- Made location saves validate before commit and persist atomically in XDG state with user-only permissions.
- Replaced permissive QML smoke gates and placeholder accessibility/format checks with failing automated checks.

### Security
- Bounded and normalized Open-Meteo responses, added a five-second search timeout, and stopped raw helper stderr from reaching the UI.
- Added coordinate-pair, elevation, label, mode, and private-input redaction tests.
