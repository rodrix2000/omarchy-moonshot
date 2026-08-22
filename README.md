# Moonshot

**The moon, built into your Omarchy desktop.**

Moonshot places a living lunar indicator in the Omarchy bar and opens a calm, location-aware lunar panel with the current phase, illumination percentage, exact moon age, upcoming major quarter phases, and local moonrise/moonset timings.

![Moonshot Preview](preview.png)

## Features

- **Living Bar Indicator:** Optically centered lunar disk in the status bar with selectable modes (`disk`, `illumination`, `phase`, `next-full`, `moonrise`).
- **Detailed Lunar Panel:** Clean modal panel with procedural Canvas lunar rendering, illumination stats, waxing/waning direction, and moon age in days.
- **Accurate Astronomical Ephemeris:** Offline computation powered by Astronomy Engine with validated USNO/NASA golden data.
- **Local Rise, Set & Horizon:** Precise local-day rise and set calculations with upper-limb and refraction corrections.
- **Date Browsing:** Step through past or future dates with smooth transitions and quick jumps back to Today or the next Full/New Moon.
- **Location Flexibility:** Works fully offline with manual coordinates & IANA time zone, or via optional city search (Open-Meteo).
- **Omarchy Native:** Theme-adaptive palette, smooth popout lifecycle, keyboard accessibility, and reduced-motion support.
- **Zero Tracking:** No telemetry, analytics, tracking, or background daemons.

## Requirements

- **Omarchy:** 4.0.0 or higher
- **Shell:** Quickshell 0.3.0+
- **Python:** Python 3.10+ (standard library only; Astronomy Engine is vendored in-repo)

## Installation

Install directly into your Omarchy shell using the Omarchy plugin CLI:

```bash
omarchy plugin add https://github.com/rodrix2000/omarchy-moonshot.git --enable
```

To enable or reposition the widget manually in your status bar:

```bash
omarchy bar move io.github.rodrix2000.moonshot --section right
```

## Usage

- **Click Bar Icon:** Toggle the Moonshot panel.
- **Middle-Click Bar Icon:** Force recalculation and refresh.
- **Keyboard Shortcuts (inside panel):**
  - <kbd>Left</kbd> / <kbd>Right</kbd>: Previous / Next day
  - <kbd>T</kbd>: Jump to Today (current instant)
  - <kbd>F</kbd>: Jump to next Full Moon
  - <kbd>N</kbd>: Jump to next New Moon
  - <kbd>L</kbd>: Open Location Editor
  - <kbd>R</kbd>: Refresh calculations
  - <kbd>Escape</kbd>: Close Location Editor or dismiss Panel

## Location & Privacy

- **Offline-First:** All ephemeris calculations run locally on your system.
- **No Location Mode:** If unconfigured, global moon phase, illumination, and age are computed immediately without needing coordinates.
- **Manual Mode:** Provide your latitude, longitude, and IANA time zone directly for 100% offline rise/set computation.
- **City Search:** Optional geocoding queries Open-Meteo over HTTPS. No location data is sent in the background.

## Rendering Convention

> **Note:** Moonshot v1 renders the lunar disk using a standard north-up astronomical chart convention (waxing light on right, waning on left). It accurately depicts illumination and phase direction but does not simulate local horizon disc rotation.

## Updating

```bash
omarchy plugin update io.github.rodrix2000.moonshot
```

## Removal

```bash
omarchy plugin remove io.github.rodrix2000.moonshot
```

To clean up local state cache:

```bash
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/moonshot"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/moonshot"
```

## Third-Party Software

Moonshot vendors [Astronomy Engine](https://github.com/cosinekitty/astronomy) by Don Cross under the MIT License. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for details.

## License

MIT License — Copyright (c) 2026 Rudy Rodriguez. See [LICENSE](LICENSE) for details.
