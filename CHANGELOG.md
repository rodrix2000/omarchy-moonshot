# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-08-24

### Added
- Monthly lunar calendar with local-evening phase renders, exact major-phase markers, keyboard date selection, and month navigation.
- Exact new-to-new lunar cycle timeline with local quarter times and selectable event jumps.
- Offline lunar and solar eclipse tracking with classification, contact/maximum times, countdowns, obscuration, and observer-local visibility.
- NASA GSFC eclipse fixtures plus calendar, cycle, visibility, responsive layout, and performance regression coverage.

### Changed
- Add four compact, keyboard-addressable panel views: Tonight, Calendar, Cycle, and Eclipses.
- Restore Moonshot’s original anchored, notification-style Omarchy popup instead of opening a Hyprland-managed tiled window.
- Keep all four views within the compact 420 × 620 popup content target.
- Update the marketplace preview with live captures of all four anchored popup views.

### Fixed
- Prevent the astronomy helper from writing Python bytecode caches inside the installed plugin checkout.
- Skip exact local solar-eclipse searches when the topocentric geometry is a clear miss, keeping snapshot calculations within the performance budget.

## [0.1.2] - 2026-08-23

### Fixed
- Reset stale fullscreen and maximized state whenever Moonshot opens or closes so it tiles beside the active workspace window like PhotoDock and Omarchy Chess.
- Prevent a previous fullscreen session from hiding the existing workspace client on the next launch.
- Fit the default 480 × 660 window request within the laptop work area while keeping the complete primary view visible without scrolling.

## [0.1.1] - 2026-08-23

### Changed
- Open Moonshot as a native Omarchy floating panel while retaining the living bar indicator.
- Match PhotoDock and Omarchy Chess window behavior so Hyprland’s standard `Super+W` command closes Moonshot.
- Increase the default panel height so the primary lunar view fits without scrolling, while preserving overflow scrolling after a small manual resize.
- Add an explicit themed close control alongside the existing Escape and bar-toggle dismissal paths.

### Fixed
- Keep shell open-state bookkeeping synchronized when Hyprland closes the Moonshot window.
- Share one lunar model between the panel and bar widget so location, phase, refresh, and theme-aware display settings stay in sync.

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
- Prepared a privacy-safe marketplace preview and portable CI/package checks for the public release.

### Security
- Bounded and normalized Open-Meteo responses, added a five-second search timeout, and stopped raw helper stderr from reaching the UI.
- Added coordinate-pair, elevation, label, mode, and private-input redaction tests.
- Kept privilege, service-management, and tracking policy regression checks out of shipped runtime paths so marketplace scanning reports actual capabilities instead of audit literals.
