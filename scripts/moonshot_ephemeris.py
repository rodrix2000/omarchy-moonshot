#!/usr/bin/env python3
"""Moonshot Ephemeris Engine.

Computes astronomical lunar phase, illumination, moon age, monthly planning data,
cycle and eclipse events, observer rise/set, and horizon altitude using vendored
Astronomy Engine.
"""

from __future__ import annotations

import argparse
import datetime
import json
import math
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
import zoneinfo

# Runtime calculations must never modify the installed plugin checkout, even
# when an older shell component launches the helper without Python's -B flag.
sys.dont_write_bytecode = True

# Ensure vendored astronomy library is in sys.path
_REPO_ROOT = Path(__file__).resolve().parent.parent
_VENDOR_PATH = _REPO_ROOT / "vendor"
if str(_VENDOR_PATH) not in sys.path:
    sys.path.insert(0, str(_VENDOR_PATH))

try:
    import astronomy
except ImportError:
    try:
        from vendor import astronomy
    except ImportError as exc:
        print(
            json.dumps(
                {
                    "protocolVersion": 1,
                    "requestId": "",
                    "status": "error",
                    "error": {
                        "code": "HELPER_NOT_FOUND",
                        "message": f"Failed to import Astronomy Engine: {exc}",
                    },
                }
            ),
            file=sys.stderr,
        )
        sys.exit(1)

PROTOCOL_VERSION = 1
ENGINE_VERSION = "2.1.19"
ENGINE_COMMIT = "865d3da7d8112bbc7911238052c6af4aaf877181"

PHASE_NAMES = [
    "New Moon",
    "Waxing Crescent",
    "First Quarter",
    "Waxing Gibbous",
    "Full Moon",
    "Waning Gibbous",
    "Last Quarter",
    "Waning Crescent",
]

QUARTER_NAMES = {
    0: "New Moon",
    1: "First Quarter",
    2: "Full Moon",
    3: "Last Quarter",
}

ECLIPSE_KIND_LABELS = {
    astronomy.EclipseKind.Penumbral: "Penumbral",
    astronomy.EclipseKind.Partial: "Partial",
    astronomy.EclipseKind.Annular: "Annular",
    astronomy.EclipseKind.Total: "Total",
}


def normalize_degrees(deg: float) -> float:
    """Normalize degrees to [0.0, 360.0)."""
    res = deg % 360.0
    if res < 0.0:
        res += 360.0
    return 0.0 if math.isclose(res, 360.0, abs_tol=1e-9) else res


def classify_phase(phase_angle_deg: float) -> Tuple[str, str]:
    """Classify phase angle into 8 named phases and direction (waxing/waning/neutral).

    Boundaries:
      [337.5, 360) or [0, 22.5) -> New Moon
      [22.5, 67.5)              -> Waxing Crescent
      [67.5, 112.5)             -> First Quarter
      [112.5, 157.5)            -> Waxing Gibbous
      [157.5, 202.5)            -> Full Moon
      [202.5, 247.5)            -> Waning Gibbous
      [247.5, 292.5)            -> Last Quarter
      [292.5, 337.5)            -> Waning Crescent
    """
    angle = normalize_degrees(phase_angle_deg)

    # Direction
    if math.isclose(angle, 0.0, abs_tol=1e-5) or math.isclose(angle, 180.0, abs_tol=1e-5):
        direction = "neutral"
    elif 0.0 < angle < 180.0:
        direction = "waxing"
    else:
        direction = "waning"

    # Octant classification
    if angle >= 337.5 or angle < 22.5:
        name = "New Moon"
    elif angle < 67.5:
        name = "Waxing Crescent"
    elif angle < 112.5:
        name = "First Quarter"
    elif angle < 157.5:
        name = "Waxing Gibbous"
    elif angle < 202.5:
        name = "Full Moon"
    elif angle < 247.5:
        name = "Waning Gibbous"
    elif angle < 292.5:
        name = "Last Quarter"
    else:
        name = "Waning Crescent"

    return name, direction


def dt_to_astro_time(dt_utc: datetime.datetime) -> astronomy.Time:
    """Convert an aware UTC datetime to astronomy.Time."""
    if dt_utc.tzinfo is None:
        dt_utc = dt_utc.replace(tzinfo=datetime.timezone.utc)
    else:
        dt_utc = dt_utc.astimezone(datetime.timezone.utc)
    return astronomy.Time.Make(
        dt_utc.year,
        dt_utc.month,
        dt_utc.day,
        dt_utc.hour,
        dt_utc.minute,
        dt_utc.second + (dt_utc.microsecond / 1_000_000.0),
    )


def astro_time_to_dt(astro_time: astronomy.Time) -> datetime.datetime:
    """Convert an astronomy.Time to aware UTC datetime."""
    dt = astro_time.Utc()
    sec_int = int(dt.second)
    microsec = int(round((dt.second - sec_int) * 1_000_000))
    if microsec >= 1_000_000:
        sec_int += 1
        microsec = 0
    return datetime.datetime(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        sec_int,
        microsec,
        tzinfo=datetime.timezone.utc,
    )


def format_iso_utc(dt_utc: datetime.datetime) -> str:
    """Format aware datetime as ISO 8601 UTC string (e.g. 2026-08-22T19:30:00Z)."""
    utc = dt_utc.astimezone(datetime.timezone.utc)
    return utc.strftime("%Y-%m-%dT%H:%M:%SZ")


def format_iso_local(dt_local: datetime.datetime) -> str:
    """Format aware local datetime with UTC offset (e.g. 2026-08-22T14:30:00-05:00)."""
    return dt_local.isoformat(timespec="seconds")


def get_system_timezone() -> zoneinfo.ZoneInfo:
    """Resolve system IANA timezone with safe fallback."""
    tz_env = os.environ.get("TZ")
    if tz_env:
        try:
            return zoneinfo.ZoneInfo(tz_env)
        except Exception:
            pass

    try:
        tz_path = Path("/etc/timezone")
        if tz_path.exists():
            name = tz_path.read_text(encoding="utf-8").strip()
            if name:
                return zoneinfo.ZoneInfo(name)
    except Exception:
        pass

    try:
        localtime_path = Path("/etc/localtime")
        if localtime_path.is_symlink():
            target = os.readlink("/etc/localtime")
            if "zoneinfo/" in target:
                zone_name = target.split("zoneinfo/", 1)[1]
                return zoneinfo.ZoneInfo(zone_name)
    except Exception:
        pass

    return zoneinfo.ZoneInfo("UTC")


def find_previous_new_moon(obs_time: astronomy.Time) -> astronomy.Time:
    """Find the exact New Moon quarter immediately preceding an instant."""
    search_start = obs_time.AddDays(-40.0)
    quarter = astronomy.SearchMoonQuarter(search_start)
    latest_new_moon: Optional[astronomy.Time] = None

    for _ in range(20):
        if quarter.time.ut > obs_time.ut:
            break
        if quarter.quarter == 0:  # New Moon
            latest_new_moon = quarter.time
        quarter = astronomy.NextMoonQuarter(quarter)

    if latest_new_moon is None:
        quarter = astronomy.SearchMoonQuarter(obs_time.AddDays(-32.0))
        while quarter.time.ut <= obs_time.ut:
            if quarter.quarter == 0:
                latest_new_moon = quarter.time
            quarter = astronomy.NextMoonQuarter(quarter)

    if latest_new_moon is None:
        raise ValueError("Could not determine preceding New Moon quarter.")

    return latest_new_moon


def compute_moon_age(
    obs_time: astronomy.Time,
    previous_new_moon: Optional[astronomy.Time] = None,
) -> Tuple[float, str]:
    """Return elapsed days and the exact preceding New Moon UTC instant."""
    latest_new_moon = previous_new_moon or find_previous_new_moon(obs_time)

    age_days = obs_time.ut - latest_new_moon.ut
    prev_new_iso = format_iso_utc(astro_time_to_dt(latest_new_moon))
    return max(0.0, age_days), prev_new_iso


def compute_upcoming_phases(
    obs_time: astronomy.Time, tz: zoneinfo.ZoneInfo, max_events: int = 4
) -> List[Dict[str, Any]]:
    """Compute the next occurrence of each major quarter phase."""
    events: List[Dict[str, Any]] = []
    quarter = astronomy.SearchMoonQuarter(obs_time)

    while quarter.time.ut < obs_time.ut:
        quarter = astronomy.NextMoonQuarter(quarter)

    seen_quarters = set()
    while len(events) < max_events and len(seen_quarters) < 4:
        q_num = quarter.quarter
        if q_num not in seen_quarters:
            seen_quarters.add(q_num)
            dt_utc = astro_time_to_dt(quarter.time)
            dt_local = dt_utc.astimezone(tz)
            events.append(
                {
                    "quarter": q_num,
                    "name": QUARTER_NAMES[q_num],
                    "instantUtc": format_iso_utc(dt_utc),
                    "localDateTime": format_iso_local(dt_local),
                }
            )
        quarter = astronomy.NextMoonQuarter(quarter)

    events.sort(key=lambda x: x["instantUtc"])
    return events


def compute_lunar_calendar(
    selected_date: datetime.date, tz: zoneinfo.ZoneInfo
) -> Dict[str, Any]:
    """Compute a local-time monthly lunar calendar at 21:00 each day."""
    month_start = selected_date.replace(day=1)
    if month_start.month == 12:
        next_month = datetime.date(month_start.year + 1, 1, 1)
    else:
        next_month = datetime.date(month_start.year, month_start.month + 1, 1)
    day_count = (next_month - month_start).days

    local_start = datetime.datetime.combine(
        month_start, datetime.time(0, 0, 0), tzinfo=tz
    )
    local_end = datetime.datetime.combine(
        next_month, datetime.time(0, 0, 0), tzinfo=tz
    )
    quarter = astronomy.SearchMoonQuarter(
        dt_to_astro_time(local_start.astimezone(datetime.timezone.utc)).AddDays(-2.0)
    )
    end_ut = dt_to_astro_time(local_end.astimezone(datetime.timezone.utc)).ut
    major_by_date: Dict[str, Dict[str, Any]] = {}
    for _ in range(8):
        if quarter.time.ut >= end_ut:
            break
        event_utc = astro_time_to_dt(quarter.time)
        event_local = event_utc.astimezone(tz)
        if event_local.date() >= month_start:
            major_by_date[event_local.date().isoformat()] = {
                "quarter": quarter.quarter,
                "name": QUARTER_NAMES[quarter.quarter],
                "instantUtc": format_iso_utc(event_utc),
                "localDateTime": format_iso_local(event_local),
            }
        quarter = astronomy.NextMoonQuarter(quarter)

    days: List[Dict[str, Any]] = []
    for offset in range(day_count):
        local_date = month_start + datetime.timedelta(days=offset)
        local_evening = datetime.datetime.combine(
            local_date, datetime.time(21, 0, 0), tzinfo=tz
        )
        astro_time = dt_to_astro_time(
            local_evening.astimezone(datetime.timezone.utc)
        )
        phase_deg = normalize_degrees(astronomy.MoonPhase(astro_time))
        phase_name, direction = classify_phase(phase_deg)
        illum_fraction = float(
            astronomy.Illumination(astronomy.Body.Moon, astro_time).phase_fraction
        )
        days.append(
            {
                "date": local_date.isoformat(),
                "day": local_date.day,
                "phaseAngleDeg": round(phase_deg, 2),
                "phaseName": phase_name,
                "direction": direction,
                "illuminationFraction": round(illum_fraction, 4),
                "illuminationPercent": round(illum_fraction * 100.0, 1),
                "majorPhase": major_by_date.get(local_date.isoformat()),
            }
        )

    return {
        "year": month_start.year,
        "month": month_start.month,
        "firstWeekday": month_start.weekday(),
        "dayCount": day_count,
        "days": days,
    }


def compute_lunar_cycle(
    obs_time: astronomy.Time,
    tz: zoneinfo.ZoneInfo,
    previous_new_moon: Optional[astronomy.Time] = None,
) -> Dict[str, Any]:
    """Compute the exact major events and selected position in one lunar cycle."""
    previous_new = previous_new_moon or find_previous_new_moon(obs_time)
    events: List[Dict[str, Any]] = []

    previous_utc = astro_time_to_dt(previous_new)
    previous_local = previous_utc.astimezone(tz)
    events.append(
        {
            "quarter": 0,
            "name": QUARTER_NAMES[0],
            "instantUtc": format_iso_utc(previous_utc),
            "localDateTime": format_iso_local(previous_local),
            "offsetDays": 0.0,
            "position": 0.0,
        }
    )

    quarter = astronomy.SearchMoonQuarter(previous_new.AddDays(0.5))
    while len(events) < 5:
        event_utc = astro_time_to_dt(quarter.time)
        event_local = event_utc.astimezone(tz)
        events.append(
            {
                "quarter": quarter.quarter,
                "name": QUARTER_NAMES[quarter.quarter],
                "instantUtc": format_iso_utc(event_utc),
                "localDateTime": format_iso_local(event_local),
                "offsetDays": round(quarter.time.ut - previous_new.ut, 4),
                "position": 0.0,
            }
        )
        if quarter.quarter == 0:
            break
        quarter = astronomy.NextMoonQuarter(quarter)

    if len(events) != 5 or events[-1]["quarter"] != 0:
        raise ValueError("Could not determine a complete lunar cycle.")

    duration_days = float(events[-1]["offsetDays"])
    for event in events:
        event["position"] = round(event["offsetDays"] / duration_days, 5)

    position = max(0.0, min(1.0, (obs_time.ut - previous_new.ut) / duration_days))
    return {
        "startInstantUtc": events[0]["instantUtc"],
        "endInstantUtc": events[-1]["instantUtc"],
        "durationDays": round(duration_days, 3),
        "ageDays": round(max(0.0, obs_time.ut - previous_new.ut), 3),
        "position": round(position, 5),
        "events": events,
    }


def body_altitude(
    body: astronomy.Body,
    astro_time: astronomy.Time,
    observer: astronomy.Observer,
) -> float:
    """Return apparent body altitude for a local visibility decision."""
    equator = astronomy.Equator(body, astro_time, observer, True, True)
    horizon = astronomy.Horizon(
        astro_time,
        observer,
        equator.ra,
        equator.dec,
        astronomy.Refraction.Normal,
    )
    return float(horizon.altitude)


def lunar_eclipse_visible(
    eclipse: astronomy.LunarEclipseInfo, observer: astronomy.Observer
) -> bool:
    """Determine whether any part of a lunar eclipse is above the local horizon."""
    begin = eclipse.peak.AddDays(-eclipse.sd_penum / 1440.0)
    end = eclipse.peak.AddDays(eclipse.sd_penum / 1440.0)
    if any(
        body_altitude(astronomy.Body.Moon, instant, observer) > 0.0
        for instant in (begin, eclipse.peak, end)
    ):
        return True

    rise = astronomy.SearchRiseSet(
        astronomy.Body.Moon,
        observer,
        astronomy.Direction.Rise,
        begin,
        max(0.1, end.ut - begin.ut),
    )
    return rise is not None and rise.ut <= end.ut


def local_solar_eclipse_possible(
    global_peak: astronomy.Time, observer: astronomy.Observer
) -> bool:
    """Cheaply reject locations far outside a global solar eclipse footprint.

    The topocentric Sun/Moon separation is sampled with a generous angular and
    horizon margin. A possible match is always confirmed by Astronomy Engine's
    exact local eclipse search; this prefilter only avoids searching through
    later years when the next global event clearly misses the observer.
    """
    for minute_offset in range(-420, 421, 60):
        sample = global_peak.AddDays(minute_offset / 1440.0)
        sun = astronomy.Equator(
            astronomy.Body.Sun, sample, observer, True, True
        )
        moon = astronomy.Equator(
            astronomy.Body.Moon, sample, observer, True, True
        )
        sun_dec = math.radians(sun.dec)
        moon_dec = math.radians(moon.dec)
        delta_ra = math.radians((sun.ra - moon.ra) * 15.0)
        cos_separation = (
            math.sin(sun_dec) * math.sin(moon_dec)
            + math.cos(sun_dec) * math.cos(moon_dec) * math.cos(delta_ra)
        )
        separation = math.degrees(
            math.acos(max(-1.0, min(1.0, cos_separation)))
        )
        # Solar and lunar apparent radii sum to roughly 0.6 degrees. With
        # one-hour samples, the nearest sample is at most about 0.3 degrees
        # from a local contact, so 1 degree retains a safety margin without
        # sending clearly missed eclipses through the expensive exact search.
        if separation > 1.0:
            continue
        sun_horizon = astronomy.Horizon(
            sample,
            observer,
            sun.ra,
            sun.dec,
            astronomy.Refraction.Normal,
        )
        if sun_horizon.altitude > -10.0:
            return True
    return False


def eclipse_event_payload(
    *,
    eclipse_type: str,
    kind: astronomy.EclipseKind,
    peak: astronomy.Time,
    begin: Optional[astronomy.Time],
    end: Optional[astronomy.Time],
    obscuration: Optional[float],
    visibility: str,
    tz: zoneinfo.ZoneInfo,
    obs_time: astronomy.Time,
) -> Dict[str, Any]:
    """Normalize an Astronomy Engine eclipse into the Moonshot protocol."""
    kind_label = ECLIPSE_KIND_LABELS.get(kind, "Unknown")
    peak_utc = astro_time_to_dt(peak)
    peak_local = peak_utc.astimezone(tz)

    def local_iso(value: Optional[astronomy.Time]) -> Optional[str]:
        if value is None:
            return None
        return format_iso_local(astro_time_to_dt(value).astimezone(tz))

    if visibility == "visible":
        visibility_label = "Visible from this location"
    elif visibility == "not-visible":
        visibility_label = "Not visible from this location"
    else:
        visibility_label = "Set a location to check visibility"

    return {
        "id": f"{eclipse_type}-{peak_local.date().isoformat()}",
        "type": eclipse_type,
        "kind": kind_label.lower(),
        "title": f"{kind_label} {eclipse_type.title()} Eclipse",
        "peakUtc": format_iso_utc(peak_utc),
        "peakLocalDateTime": format_iso_local(peak_local),
        "startLocalDateTime": local_iso(begin),
        "endLocalDateTime": local_iso(end),
        "daysUntil": round(max(0.0, peak.ut - obs_time.ut), 2),
        "obscurationPercent": (
            round(float(obscuration) * 100.0, 1)
            if obscuration is not None and math.isfinite(obscuration)
            else None
        ),
        "visibility": visibility,
        "visibilityLabel": visibility_label,
    }


def compute_upcoming_eclipses(
    obs_time: astronomy.Time,
    tz: zoneinfo.ZoneInfo,
    latitude: Optional[float],
    longitude: Optional[float],
    elevation_m: float = 0.0,
) -> List[Dict[str, Any]]:
    """Compute the next lunar and global solar eclipses with local visibility."""
    observer = (
        astronomy.Observer(latitude, longitude, elevation_m)
        if latitude is not None and longitude is not None
        else None
    )

    lunar = astronomy.SearchLunarEclipse(obs_time)
    lunar_begin = lunar.peak.AddDays(-lunar.sd_penum / 1440.0)
    lunar_end = lunar.peak.AddDays(lunar.sd_penum / 1440.0)
    lunar_visibility = "location-required"
    if observer is not None:
        lunar_visibility = (
            "visible" if lunar_eclipse_visible(lunar, observer) else "not-visible"
        )
    events = [
        eclipse_event_payload(
            eclipse_type="lunar",
            kind=lunar.kind,
            peak=lunar.peak,
            begin=lunar_begin,
            end=lunar_end,
            obscuration=lunar.obscuration,
            visibility=lunar_visibility,
            tz=tz,
            obs_time=obs_time,
        )
    ]

    solar = astronomy.SearchGlobalSolarEclipse(obs_time)
    solar_peak = solar.peak
    solar_begin: Optional[astronomy.Time] = None
    solar_end: Optional[astronomy.Time] = None
    solar_obscuration = solar.obscuration
    solar_visibility = "location-required"
    if observer is not None:
        solar_visibility = "not-visible"
        if local_solar_eclipse_possible(solar_peak, observer):
            local_solar = astronomy.SearchLocalSolarEclipse(
                solar_peak.AddDays(-1.0), observer
            )
            if abs(local_solar.peak.time.ut - solar_peak.ut) < 1.0:
                solar_visibility = "visible"
                solar_peak = local_solar.peak.time
                solar_begin = local_solar.partial_begin.time
                solar_end = local_solar.partial_end.time
                solar_obscuration = local_solar.obscuration

    events.append(
        eclipse_event_payload(
            eclipse_type="solar",
            kind=solar.kind,
            peak=solar_peak,
            begin=solar_begin,
            end=solar_end,
            obscuration=solar_obscuration,
            visibility=solar_visibility,
            tz=tz,
            obs_time=obs_time,
        )
    )
    events.sort(key=lambda event: event["peakUtc"])
    return events


def compute_rise_set_for_day(
    selected_local_date: datetime.date,
    tz: zoneinfo.ZoneInfo,
    latitude: float,
    longitude: float,
    elevation_m: float = 0.0,
) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Compute Moonrise and Moonset for the specific local calendar date."""
    observer = astronomy.Observer(latitude, longitude, elevation_m)

    local_start = datetime.datetime.combine(
        selected_local_date, datetime.time(0, 0, 0), tzinfo=tz
    )
    local_end = local_start + datetime.timedelta(days=1)

    start_utc = local_start.astimezone(datetime.timezone.utc)
    end_utc = local_end.astimezone(datetime.timezone.utc)

    start_astro = dt_to_astro_time(start_utc)
    end_ut = dt_to_astro_time(end_utc).ut

    rise_res = astronomy.SearchRiseSet(
        astronomy.Body.Moon, observer, astronomy.Direction.Rise, start_astro, 1.5
    )
    rise_event: Dict[str, Any] = {"status": "none-in-day"}
    if rise_res is not None and start_astro.ut <= rise_res.ut < end_ut:
        dt_rise_utc = astro_time_to_dt(rise_res)
        dt_rise_local = dt_rise_utc.astimezone(tz)
        rise_event = {
            "status": "event",
            "instantUtc": format_iso_utc(dt_rise_utc),
            "localDateTime": format_iso_local(dt_rise_local),
        }

    set_res = astronomy.SearchRiseSet(
        astronomy.Body.Moon, observer, astronomy.Direction.Set, start_astro, 1.5
    )
    set_event: Dict[str, Any] = {"status": "none-in-day"}
    if set_res is not None and start_astro.ut <= set_res.ut < end_ut:
        dt_set_utc = astro_time_to_dt(set_res)
        dt_set_local = dt_set_utc.astimezone(tz)
        set_event = {
            "status": "event",
            "instantUtc": format_iso_utc(dt_set_utc),
            "localDateTime": format_iso_local(dt_set_local),
        }

    if rise_event["status"] != "event" or set_event["status"] != "event":
        sample_times = [
            start_astro.AddDays(i * (1.0 / 24.0)) for i in range(25)
        ]
        alts = []
        for st in sample_times:
            eq = astronomy.Equator(
                astronomy.Body.Moon,
                st,
                observer,
                True,
                True,
            )
            hor = astronomy.Horizon(
                st, observer, eq.ra, eq.dec, astronomy.Refraction.Normal
            )
            alts.append(hor.altitude)

        all_above = all(a > 0.0 for a in alts)
        all_below = all(a < 0.0 for a in alts)

        if all_above:
            if rise_event["status"] != "event":
                rise_event = {"status": "always-above"}
            if set_event["status"] != "event":
                set_event = {"status": "always-above"}
        elif all_below:
            if rise_event["status"] != "event":
                rise_event = {"status": "always-below"}
            if set_event["status"] != "event":
                set_event = {"status": "always-below"}

    return rise_event, set_event


def compute_horizon(
    obs_time: astronomy.Time,
    latitude: float,
    longitude: float,
    elevation_m: float = 0.0,
) -> Dict[str, Any]:
    """Compute horizon coordinates (altitude, azimuth) at observation instant."""
    observer = astronomy.Observer(latitude, longitude, elevation_m)
    equator = astronomy.Equator(
        astronomy.Body.Moon,
        obs_time,
        observer,
        True,
        True,
    )
    horizon = astronomy.Horizon(
        obs_time, observer, equator.ra, equator.dec, astronomy.Refraction.Normal
    )
    return {
        "configured": True,
        "altitudeDeg": round(horizon.altitude, 2),
        "azimuthDeg": round(horizon.azimuth, 2),
        "aboveHorizon": bool(horizon.altitude > 0.0),
        "convention": "astronomy-engine-apparent",
    }


def compute_snapshot(
    request_id: str,
    instant_utc: Optional[str],
    selected_date: Optional[str],
    timezone_name: Optional[str],
    latitude: Optional[float],
    longitude: Optional[float],
    elevation_m: float = 0.0,
    location_label: str = "",
    observation_mode: str = "auto",
) -> Dict[str, Any]:
    """Compute full ephemeris snapshot."""
    request_id = str(request_id or "")[:64]
    observation_mode = str(observation_mode or "auto").strip().lower()
    if observation_mode not in {"auto", "now", "browse", "event"}:
        return {
            "protocolVersion": PROTOCOL_VERSION,
            "requestId": request_id,
            "status": "error",
            "error": {
                "code": "INVALID_MODE",
                "message": "Observation mode must be auto, now, browse, or event.",
            },
        }

    location_label = str(location_label or "").strip()
    if len(location_label) > 128:
        return {
            "protocolVersion": PROTOCOL_VERSION,
            "requestId": request_id,
            "status": "error",
            "error": {
                "code": "INVALID_LOCATION",
                "message": "Location labels must be 128 characters or fewer.",
            },
        }

    if timezone_name:
        try:
            tz = zoneinfo.ZoneInfo(timezone_name)
        except Exception:
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_TIME_ZONE",
                    "message": "The requested IANA time zone is unavailable.",
                },
            }
    else:
        tz = get_system_timezone()
        timezone_name = tz.key if hasattr(tz, "key") else str(tz)

    if (latitude is None) != (longitude is None):
        return {
            "protocolVersion": PROTOCOL_VERSION,
            "requestId": request_id,
            "status": "error",
            "error": {
                "code": "INVALID_COORDINATES",
                "message": "Latitude and longitude must be provided together.",
            },
        }

    has_coords = latitude is not None and longitude is not None
    if has_coords:
        if not math.isfinite(latitude) or not (-90.0 <= latitude <= 90.0):
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_COORDINATES",
                    "message": "Latitude must be finite and within [-90, 90].",
                },
            }
        if not math.isfinite(longitude) or not (-180.0 <= longitude <= 180.0):
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_COORDINATES",
                    "message": "Longitude must be finite and within [-180, 180].",
                },
            }

    if not math.isfinite(elevation_m) or not (-500.0 <= elevation_m <= 9000.0):
        return {
            "protocolVersion": PROTOCOL_VERSION,
            "requestId": request_id,
            "status": "error",
            "error": {
                "code": "INVALID_ELEVATION",
                "message": "Elevation must be finite and within [-500, 9000] meters.",
            },
        }

    now_utc = datetime.datetime.now(datetime.timezone.utc)
    if instant_utc:
        try:
            dt_utc = datetime.datetime.fromisoformat(
                instant_utc.replace("Z", "+00:00")
            ).astimezone(datetime.timezone.utc)
        except Exception:
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_INSTANT",
                    "message": "The observation instant is not valid ISO 8601 UTC.",
                },
            }
    else:
        dt_utc = now_utc

    dt_local = dt_utc.astimezone(tz)
    local_today = dt_local.date()

    if selected_date:
        try:
            target_date = datetime.date.fromisoformat(selected_date)
        except Exception:
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_DATE",
                    "message": "The selected date is not a valid ISO calendar date.",
                },
            }
    else:
        target_date = local_today

    if observation_mode == "event":
        if instant_utc is None:
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_INSTANT",
                    "message": "Event mode requires an exact UTC instant.",
                },
            }
        mode = "event"
        effective_dt_utc = dt_utc
        effective_dt_local = dt_local
        target_date = effective_dt_local.date()
    elif observation_mode == "now" or (
        observation_mode == "auto"
        and target_date == local_today
        and (instant_utc is None or abs((dt_utc - now_utc).total_seconds()) < 300)
    ):
        mode = "now"
        effective_dt_utc = now_utc if instant_utc is None else dt_utc
        effective_dt_local = effective_dt_utc.astimezone(tz)
        target_date = effective_dt_local.date()
    else:
        mode = "browse"
        effective_dt_local = datetime.datetime.combine(
            target_date, datetime.time(21, 0, 0), tzinfo=tz
        )
        effective_dt_utc = effective_dt_local.astimezone(datetime.timezone.utc)

    astro_time = dt_to_astro_time(effective_dt_utc)

    phase_deg = normalize_degrees(astronomy.MoonPhase(astro_time))
    phase_name, direction = classify_phase(phase_deg)
    illum = astronomy.Illumination(astronomy.Body.Moon, astro_time)
    illum_fraction = round(float(illum.phase_fraction), 4)
    illum_percent = round(illum_fraction * 100.0, 1)

    previous_new_moon = find_previous_new_moon(astro_time)
    age_days, prev_new_utc = compute_moon_age(astro_time, previous_new_moon)
    upcoming_phases = compute_upcoming_phases(astro_time, tz)
    lunar_calendar = compute_lunar_calendar(target_date, tz)
    lunar_calendar["todayLocalDate"] = local_today.isoformat()
    lunar_cycle = compute_lunar_cycle(astro_time, tz, previous_new_moon)
    upcoming_eclipses = compute_upcoming_eclipses(
        astro_time,
        tz,
        latitude if has_coords else None,
        longitude if has_coords else None,
        elevation_m,
    )

    if has_coords:
        horizon_info = compute_horizon(
            astro_time, latitude, longitude, elevation_m  # type: ignore
        )
        rise_event, set_event = compute_rise_set_for_day(
            target_date, tz, latitude, longitude, elevation_m  # type: ignore
        )
    else:
        horizon_info = {
            "configured": False,
            "altitudeDeg": 0.0,
            "azimuthDeg": 0.0,
            "aboveHorizon": False,
            "convention": "unconfigured",
        }
        rise_event = {"status": "not-configured"}
        set_event = {"status": "not-configured"}

    tz_abbr = effective_dt_local.tzname() or ""
    utc_offset = int(effective_dt_local.utcoffset().total_seconds() if effective_dt_local.utcoffset() else 0)

    data = {
        "observation": {
            "instantUtc": format_iso_utc(effective_dt_utc),
            "instantEpochMs": int(effective_dt_utc.timestamp() * 1000),
            "selectedLocalDate": target_date.isoformat(),
            "localDateTime": format_iso_local(effective_dt_local),
            "timeZone": timezone_name,
            "timeZoneAbbreviation": tz_abbr,
            "utcOffsetSeconds": utc_offset,
            "mode": mode,
        },
        "location": {
            "configured": bool(has_coords),
            "label": location_label or ("Configured Location" if has_coords else "No Location Configured"),
            "latitude": float(latitude) if latitude is not None else None,
            "longitude": float(longitude) if longitude is not None else None,
            "elevationM": float(elevation_m),
        },
        "moon": {
            "phaseAngleDeg": round(phase_deg, 2),
            "phaseName": phase_name,
            "direction": direction,
            "illuminationFraction": illum_fraction,
            "illuminationPercent": illum_percent,
            "ageDays": round(age_days, 1),
            "previousNewMoonUtc": prev_new_utc,
            "renderConvention": "north-up",
        },
        "horizon": horizon_info,
        "events": {
            "rise": rise_event,
            "set": set_event,
            "nextMajorPhases": upcoming_phases,
        },
        "planning": {
            "calendar": lunar_calendar,
            "cycle": lunar_cycle,
            "upcomingEclipses": upcoming_eclipses,
        },
        "engine": {
            "name": "Astronomy Engine",
            "version": ENGINE_VERSION,
            "sourceCommit": ENGINE_COMMIT,
        },
    }

    return {
        "protocolVersion": PROTOCOL_VERSION,
        "requestId": request_id,
        "generatedAtUtc": format_iso_utc(now_utc),
        "status": "ok",
        "data": data,
        "warnings": [],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Moonshot astronomical ephemeris helper.")
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    snap_p = subparsers.add_parser("snapshot", help="Compute lunar ephemeris snapshot.")
    snap_p.add_argument("--request-id", default="", help="Monotonic request identifier.")
    snap_p.add_argument("--instant-utc", default=None, help="Observation UTC instant (ISO 8601).")
    snap_p.add_argument("--selected-date", default=None, help="Selected local date (YYYY-MM-DD).")
    snap_p.add_argument("--timezone", default=None, help="IANA time zone name.")
    snap_p.add_argument("--latitude", type=float, default=None, help="Observer latitude (-90 to 90).")
    snap_p.add_argument("--longitude", type=float, default=None, help="Observer longitude (-180 to 180).")
    snap_p.add_argument("--elevation-m", type=float, default=0.0, help="Observer elevation in meters.")
    snap_p.add_argument("--location-label", default="", help="User-facing location label.")
    snap_p.add_argument(
        "--mode",
        choices=("auto", "now", "browse", "event"),
        default="auto",
        help="Observation selection mode.",
    )

    subparsers.add_parser("version", help="Print version information.")
    subparsers.add_parser("self-test", help="Run self tests and verify engine.")

    args = parser.parse_args()

    if args.subcommand == "version":
        out = {
            "protocolVersion": PROTOCOL_VERSION,
            "engine": "Astronomy Engine",
            "engineVersion": ENGINE_VERSION,
            "engineCommit": ENGINE_COMMIT,
        }
        print(json.dumps(out, indent=2))
        sys.exit(0)

    elif args.subcommand == "self-test":
        t = astronomy.Time.Make(2026, 8, 22, 12, 0, 0.0)
        phase = astronomy.MoonPhase(t)
        assert 0.0 <= phase <= 360.0
        print(json.dumps({"status": "ok", "selfTest": "passed", "samplePhase": phase}))
        sys.exit(0)

    elif args.subcommand == "snapshot":
        try:
            res = compute_snapshot(
                request_id=args.request_id,
                instant_utc=args.instant_utc,
                selected_date=args.selected_date,
                timezone_name=args.timezone,
                latitude=args.latitude,
                longitude=args.longitude,
                elevation_m=args.elevation_m,
                location_label=args.location_label,
                observation_mode=args.mode,
            )
            if res.get("status") == "error":
                print(json.dumps(res, indent=2), file=sys.stderr)
                sys.exit(1)
            print(json.dumps(res, indent=2))
            sys.exit(0)
        except Exception:
            err_doc = {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": args.request_id,
                "status": "error",
                "error": {
                    "code": "ASTRONOMY_CALCULATION",
                    "message": "The lunar ephemeris could not be calculated.",
                },
            }
            print(json.dumps(err_doc, indent=2), file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
