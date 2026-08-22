# Omarchy Platform Compatibility

## Platform Contract

- **Shell Engine:** Quickshell (Qt 6.x Quick/QML)
- **Plugin Kind:** Single `bar-widget` entry point
- **Bar Integration:** Extends `qs.Ui.BarWidget` and uses `qs.Ui.WidgetButton`
- **Panel Popout:** Extends `qs.Ui.KeyboardPanel` for anchored popup lifecycle, focus trap avoidance, and sibling popout handoff.
- **Placement:** Supports top, bottom, left, and right bar orientations.
- **Settings:** Uses Omarchy per-widget settings schema with optional XDG fallback state in `~/.local/state/moonshot/settings-v1.json`.
