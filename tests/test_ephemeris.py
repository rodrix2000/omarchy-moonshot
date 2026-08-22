#!/usr/bin/env python3
"""Tests for astronomical calculations against golden fixtures and physical laws."""

import datetime
import json
import unittest
from pathlib import Path
import zoneinfo

from scripts.moonshot_ephemeris import (
    compute_moon_age,
    compute_upcoming_phases,
    compute_snapshot,
    dt_to_astro_time,
)


class TestEphemeris(unittest.TestCase):
    def setUp(self):
        self.fixtures_dir = Path(__file__).parent / "fixtures"
        self.major_phases_fixture = json.loads(
            (self.fixtures_dir / "major-phases.json").read_text(encoding="utf-8")
        )

    def test_major_phases_against_usno_goldens(self):
        tol_sec = self.major_phases_fixture.get("toleranceSeconds", 120)
        events = self.major_phases_fixture["events"]

        for expected_event in events:
            dt_expected = datetime.datetime.fromisoformat(
                expected_event["instantUtc"].replace("Z", "+00:00")
            )
            # Query the upcoming quarter search starting slightly before expected
            search_start_dt = dt_expected - datetime.timedelta(hours=2)
            search_astro = dt_to_astro_time(search_start_dt)
            upcoming = compute_upcoming_phases(search_astro, zoneinfo.ZoneInfo("UTC"))

            # Find matching quarter
            matched = [u for u in upcoming if u["quarter"] == expected_event["quarter"]]
            self.assertTrue(matched, f"Quarter {expected_event['quarter']} not found near {dt_expected}")

            found_dt = datetime.datetime.fromisoformat(
                matched[0]["instantUtc"].replace("Z", "+00:00")
            )
            diff_seconds = abs((found_dt - dt_expected).total_seconds())
            self.assertLessEqual(
                diff_seconds,
                tol_sec,
                f"Phase {expected_event['name']} at {dt_expected} exceeded tolerance: {diff_seconds}s > {tol_sec}s",
            )

    def test_moon_age_accuracy(self):
        # On 2026-08-22 19:30:00 UTC, the previous New Moon was on 2026-08-12 17:37:00 UTC (~10.08 days ago)
        obs_dt = datetime.datetime(2026, 8, 22, 19, 30, 0, tzinfo=datetime.timezone.utc)
        obs_time = dt_to_astro_time(obs_dt)
        age_days, prev_new_utc = compute_moon_age(obs_time)

        self.assertGreater(age_days, 10.0)
        self.assertLess(age_days, 10.5)
        self.assertTrue(prev_new_utc.startswith("2026-08-12"))

    def test_no_location_snapshot(self):
        snap = compute_snapshot(
            request_id="test-no-loc",
            instant_utc="2026-08-22T19:30:00Z",
            selected_date="2026-08-22",
            timezone_name="UTC",
            latitude=None,
            longitude=None,
        )
        self.assertEqual(snap["status"], "ok")
        self.assertFalse(snap["data"]["location"]["configured"])
        self.assertFalse(snap["data"]["horizon"]["configured"])
        self.assertEqual(snap["data"]["events"]["rise"]["status"], "not-configured")
        self.assertEqual(snap["data"]["events"]["set"]["status"], "not-configured")
        self.assertGreater(snap["data"]["moon"]["illuminationPercent"], 0.0)


if __name__ == "__main__":
    unittest.main()
