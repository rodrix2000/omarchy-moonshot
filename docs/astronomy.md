# Astronomy Engine & Ephemeris Calculation

## Engine Details

- **Vendor:** Astronomy Engine by Don Cross (`cosinekitty/astronomy`)
- **Version:** 2.1.19
- **Source Commit:** `865d3da7d8112bbc7911238052c6af4aaf877181`
- **License:** MIT

## Calculations & Conventions

### 1. Phase Angle & Direction
- Geocentric apparent phase angle `[0, 360)`.
- Direction: `0° < phase < 180°` is **Waxing**; `180° < phase < 360°` is **Waning**.

### 2. Eight Named Phases
- New Moon: `[337.5°, 360°) ∪ [0°, 22.5°)`
- Waxing Crescent: `[22.5°, 67.5°)`
- First Quarter: `[67.5°, 112.5°)`
- Waxing Gibbous: `[112.5°, 157.5°)`
- Full Moon: `[157.5°, 202.5°)`
- Waning Gibbous: `[202.5°, 247.5°)`
- Last Quarter: `[247.5°, 292.5°)`
- Waning Crescent: `[292.5°, 337.5°)`

### 3. Illumination Fraction
- Computed via `Illumination(Body.Moon, time).phase_fraction`.
- Output as fraction `[0.0, 1.0]` and percentage `[0.0, 100.0]`.

### 4. Moon Age
- Measured as elapsed days from the exact instant of the preceding New Moon quarter.

### 5. Rise and Set Times
- Searches for Moon rise and set within the local calendar day `[00:00, 24:00)` in the specified IANA time zone.
- Standard atmospheric refraction and upper-limb disc model applied.

### 6. North-Up Rendering Convention
- Light on right when waxing, light on left when waning.
