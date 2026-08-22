# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-22

### Added
- Initial release of Moonshot for the Omarchy shell.
- Living bar indicator with configurable display modes (`disk`, `illumination`, `phase`, `next-full`, `moonrise`).
- Rich lunar panel with procedural Canvas rendering, illumination metrics, and moon age.
- Accurate upcoming major phase quarter events (New, First Quarter, Full, Last Quarter).
- Observer-based local rise and set times with horizon altitude checks.
- Date navigation supporting day stepping, jumps to Today, and jumps to next Full/New Moon.
- Offline-first architecture powered by pinned vendored Astronomy Engine (v2.1.19).
- Location editor supporting manual coordinates, IANA time zones, and explicit city search.
- Full keyboard navigation, shortcuts, visible focus, and reduced-motion support.
