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

### 7. Monthly Lunar Calendar
- Each calendar disk is computed for 21:00 in the selected IANA time zone, matching date-browse semantics.
- Major-phase markers use exact `SearchMoonQuarter` instants converted to the observation location’s local date.

### 8. Lunar Cycle Timeline
- Cycle boundaries and all major events come from exact `SearchMoonQuarter` / `NextMoonQuarter` results.
- Position is elapsed UT days divided by the exact duration between the bounding New Moons; no fixed 29.5-day shortcut is used.

### 9. Eclipse Tracking
- Lunar and global solar events come from Astronomy Engine’s `SearchLunarEclipse` and `SearchGlobalSolarEclipse` calculations.
- Lunar visibility uses exact contact times plus apparent local Moon altitude and rise checks.
- Solar visibility is conservatively prefiltered with topocentric Sun/Moon geometry and confirmed with `SearchLocalSolarEclipse`; visible events use local contact and maximum times.
- If a global solar event is not locally visible, Moonshot labels its displayed time as the global maximum rather than presenting it as a local circumstance.
- Regression fixtures are sourced from [NASA GSFC’s 2026 eclipse catalog](https://eclipse.gsfc.nasa.gov/OH/OH2026.html) and [2027 annular-eclipse elements](https://eclipse.gsfc.nasa.gov/SEsearch/SEdata.php?Ecl=+20270206).
