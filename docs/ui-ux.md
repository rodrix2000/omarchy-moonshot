# UI / UX Specification

## Visual Hierarchy

1. **Lunar Hero Disk:** Large texture-backed Canvas rendering with a computed north-up illumination terminator and restrained earthshine.
2. **Key Metrics:** Phase name, illumination percentage, waxing/waning status, moon age in days.
3. **Horizon & Ephemeris:** Rise and set times with status indicators (above/below horizon).
4. **Upcoming Phases:** Timeline of the next major lunar quarters.
5. **Date Navigation:** Quick controls to browse past/future dates and jump back to Today or exact Full/New phases.
6. **Location Configuration:** Integrated editor for manual coordinates, IANA time zone, search, and one-click switching among up to six saved places.

## Interaction and Accessibility

- The popup targets 420 logical pixels, caps at 440, and becomes vertically scrollable when content exceeds the available panel height.
- All custom commands participate in tab focus, expose accessible names/roles, and use visible Omarchy focus and hover tokens.
- Arrow keys and Vim-style lowercase `h`/`l` browse dates; `T`, `F`, `N`, `Shift+L`, and `R` provide direct actions; `Escape` backs out of location editing before closing the panel.
- Location values are validated through the astronomy helper before they are committed. Search disclosure, loading, timeout, empty, invalid, and offline-manual states are explicit.
- Saved places are de-duplicated and most-recent-first. `Clear active` preserves the travel list; `Reset all` requires a second confirming click before clearing it.
- Controls use vector Canvas icons rather than emoji, so glyph availability and color behavior are consistent across fonts and themes.

## Theme Contract

Production QML does not assume a dark background. Panel surfaces, borders, labels, muted text, accents, urgent states, focus fills, control geometry, and typography come from `qs.Commons.Color`, `Style`, and `Border`. The generated lunar albedo stays neutral; only its contextual rim and glow inherit theme colors.

The visual direction is recorded in [`design/moonshot-ui-concept-v2.png`](design/moonshot-ui-concept-v2.png). The implementation intentionally uses Omarchy’s installed typography and control tokens instead of baking the concept’s dark palette or serif treatment into the plugin.
