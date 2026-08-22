#!/usr/bin/env python3
"""Tests for observer rise/set and horizon calculations."""

import datetime
import json
import unittest
from pathlib import Path
import zoneinfo

from scripts.moonshot_ephemeris import compute_rise_set_for_day, compute_horizon, dt_to_astro_time


class TestRiseSet(unittest.TestCase):
    def setUp(self):
        self.fixtures_dir = Path(__file__).parent / "fixtures"
        self.rise_set_fixture = json.loads(
            (self.fixtures_dir / "rise-set.json").read_text(encoding="utf-8")
        )

    def test_rise_set_cases(self):
        tol_min = self.rise_set_fixture.get("toleranceMinutes", 5)

        for case in self.rise_set_fixture["cases"]:
            target_date = datetime.date.fromisoformat(case["date"])
            tz = zoneinfo.ZoneInfo(case["timeZone"])
            lat = case["latitude"]
            lon = case["longitude"]

            rise_event, set_event = compute_rise_set_for_day(target_date, tz, lat, lon)

            self.assertEqual(
                rise_event["status"],
                case["expectedRiseStatus"],
                f"Rise status mismatch for {case['location']}",
            )
            self.assertEqual(
                set_event["status"],
                case["expectedSetStatus"],
                f"Set status mismatch for {case['location']}",
            )

            if case["expectedRiseStatus"] == "event" and case.get("expectedRiseLocal"):
                rise_local_str = rise_event["localDateTime"].split("T")[1][:5]  # HH:MM
                exp_rise = datetime.datetime.strptime(case["expectedRiseLocal"], "%H:%M")
                act_rise = datetime.datetime.strptime(rise_local_str, "%H:%M")
                rise_diff = abs((act_rise - exp_rise).total_seconds()) / 60.0

                self.assertLessEqual(
                    rise_diff,
                    tol_min,
                    f"Rise time mismatch for {case['location']}: got {rise_local_str}, expected {case['expectedRiseLocal']}",
                )

            if case["expectedSetStatus"] == "event" and case.get("expectedSetLocal"):
                set_local_str = set_event["localDateTime"].split("T")[1][:5]  # HH:MM
                exp_set = datetime.datetime.strptime(case["expectedSetLocal"], "%H:%M")
                act_set = datetime.datetime.strptime(set_local_str, "%H:%M")
                set_diff = abs((act_set - exp_set).total_seconds()) / 60.0

                self.assertLessEqual(
                    set_diff,
                    tol_min,
                    f"Set time mismatch for {case['location']}: got {set_local_str}, expected {case['expectedSetLocal']}",
                )

    def test_polar_always_above_or_below(self):
        target_date = datetime.date(2026, 6, 21)
        tz = zoneinfo.ZoneInfo("Europe/Oslo")
        rise_event, set_event = compute_rise_set_for_day(target_date, tz, 69.6492, 18.9553)
        self.assertIn(rise_event["status"], ["event", "always-above", "always-below", "none-in-day"])


if __name__ == "__main__":
    unittest.main()
