#!/usr/bin/env python3
"""Moonshot Ephemeris Engine.

Computes astronomical lunar phase, illumination, moon age, upcoming quarter events,
observer rise/set, and horizon altitude using vendored Astronomy Engine.
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


def compute_moon_age(obs_time: astronomy.Time) -> Tuple[float, str]:
    """Find exact previous New Moon and return (age_in_days, previous_new_moon_utc_iso)."""
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
) -> Dict[str, Any]:
    """Compute full ephemeris snapshot."""
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
                    "message": f"Unknown or invalid IANA time zone: {timezone_name}",
                },
            }
    else:
        tz = get_system_timezone()
        timezone_name = tz.key if hasattr(tz, "key") else str(tz)

    has_coords = latitude is not None and longitude is not None
    if has_coords:
        if not (-90.0 <= latitude <= 90.0):
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_COORDINATES",
                    "message": f"Latitude out of bounds [-90, 90]: {latitude}",
                },
            }
        if not (-180.0 <= longitude <= 180.0):
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_COORDINATES",
                    "message": f"Longitude out of bounds [-180, 180]: {longitude}",
                },
            }

    now_utc = datetime.datetime.now(datetime.timezone.utc)
    if instant_utc:
        try:
            dt_utc = datetime.datetime.fromisoformat(
                instant_utc.replace("Z", "+00:00")
            ).astimezone(datetime.timezone.utc)
        except Exception as exc:
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_INSTANT",
                    "message": f"Invalid ISO 8601 instant string '{instant_utc}': {exc}",
                },
            }
    else:
        dt_utc = now_utc

    dt_local = dt_utc.astimezone(tz)
    local_today = dt_local.date()

    if selected_date:
        try:
            target_date = datetime.date.fromisoformat(selected_date)
        except Exception as exc:
            return {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": request_id,
                "status": "error",
                "error": {
                    "code": "INVALID_DATE",
                    "message": f"Invalid selected date '{selected_date}': {exc}",
                },
            }
    else:
        target_date = local_today

    if target_date == local_today and (instant_utc is None or abs((dt_utc - now_utc).total_seconds()) < 300):
        mode = "now"
        effective_dt_utc = dt_utc
        effective_dt_local = dt_local
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

    age_days, prev_new_utc = compute_moon_age(astro_time)
    upcoming_phases = compute_upcoming_phases(astro_time, tz)

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
            )
            if res.get("status") == "error":
                print(json.dumps(res, indent=2), file=sys.stderr)
                sys.exit(1)
            print(json.dumps(res, indent=2))
            sys.exit(0)
        except Exception as exc:
            err_doc = {
                "protocolVersion": PROTOCOL_VERSION,
                "requestId": args.request_id,
                "status": "error",
                "error": {
                    "code": "ASTRONOMY_CALCULATION",
                    "message": f"Ephemeris calculation failed: {exc}",
                },
            }
            print(json.dumps(err_doc, indent=2), file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
