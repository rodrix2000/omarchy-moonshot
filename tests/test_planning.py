#!/usr/bin/env python3
"""Planning-view tests for calendar, cycle, and eclipse calculations."""

import datetime
import json
import unittest
from pathlib import Path
import zoneinfo

from scripts.moonshot_ephemeris import (
    astronomy,
    compute_lunar_calendar,
    compute_lunar_cycle,
    compute_upcoming_eclipses,
    dt_to_astro_time,
    local_solar_eclipse_possible,
)


class TestPlanning(unittest.TestCase):
    def setUp(self):
        self.obs_time = dt_to_astro_time(
            datetime.datetime(
                2026, 8, 22, 19, 30, 0, tzinfo=datetime.timezone.utc
            )
        )

    @staticmethod
    def parse_iso(value):
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))

    def test_august_calendar_uses_local_evenings_and_exact_major_events(self):
        calendar = compute_lunar_calendar(
            datetime.date(2026, 8, 22), zoneinfo.ZoneInfo("America/Chicago")
        )

        self.assertEqual(calendar["year"], 2026)
        self.assertEqual(calendar["month"], 8)
        self.assertEqual(calendar["firstWeekday"], 5)
        self.assertEqual(calendar["dayCount"], 31)
        self.assertEqual(len(calendar["days"]), 31)
        self.assertEqual(
            [
                (day["date"], day["majorPhase"]["name"])
                for day in calendar["days"]
                if day["majorPhase"] is not None
            ],
            [
                ("2026-08-05", "Last Quarter"),
                ("2026-08-12", "New Moon"),
                ("2026-08-19", "First Quarter"),
                ("2026-08-27", "Full Moon"),
            ],
        )
        self.assertTrue(
            all(0.0 <= day["illuminationFraction"] <= 1.0 for day in calendar["days"])
        )

    def test_cycle_contains_five_ordered_exact_quarters(self):
        cycle = compute_lunar_cycle(
            self.obs_time, zoneinfo.ZoneInfo("America/Chicago")
        )

        self.assertEqual([event["quarter"] for event in cycle["events"]], [0, 1, 2, 3, 0])
        self.assertAlmostEqual(cycle["durationDays"], 29.41, places=2)
        self.assertGreater(cycle["position"], 0.0)
        self.assertLess(cycle["position"], 1.0)
        self.assertEqual(cycle["events"][0]["position"], 0.0)
        self.assertEqual(cycle["events"][-1]["position"], 1.0)

    def test_eclipse_events_match_nasa_reference_times(self):
        fixture = json.loads(
            (Path(__file__).parent / "fixtures" / "eclipses.json").read_text(
                encoding="utf-8"
            )
        )
        calculated = compute_upcoming_eclipses(
            self.obs_time, zoneinfo.ZoneInfo("UTC"), None, None
        )

        self.assertEqual(len(calculated), 2)
        by_type = {event["type"]: event for event in calculated}
        for expected in fixture["events"]:
            actual = by_type[expected["type"]]
            self.assertEqual(actual["kind"], expected["kind"])
            difference = abs(
                (self.parse_iso(actual["peakUtc"]) - self.parse_iso(expected["peakUtc"])).total_seconds()
            )
            self.assertLessEqual(difference, expected["toleranceSeconds"])

            if expected.get("startUtc"):
                start_difference = abs(
                    (
                        self.parse_iso(actual["startLocalDateTime"])
                        - self.parse_iso(expected["startUtc"])
                    ).total_seconds()
                )
                end_difference = abs(
                    (
                        self.parse_iso(actual["endLocalDateTime"])
                        - self.parse_iso(expected["endUtc"])
                    ).total_seconds()
                )
                self.assertLessEqual(start_difference, expected["toleranceSeconds"])
                self.assertLessEqual(end_difference, expected["toleranceSeconds"])

    def test_eclipse_visibility_is_location_aware(self):
        events = compute_upcoming_eclipses(
            self.obs_time,
            zoneinfo.ZoneInfo("America/Chicago"),
            33.0,
            -96.0,
        )
        by_type = {event["type"]: event for event in events}

        self.assertEqual(by_type["lunar"]["visibility"], "visible")
        self.assertEqual(by_type["solar"]["visibility"], "not-visible")
        self.assertIsNone(by_type["solar"]["startLocalDateTime"])

        central_path_events = compute_upcoming_eclipses(
            self.obs_time,
            zoneinfo.ZoneInfo("UTC"),
            -31.3,
            -48.5,
        )
        central_solar = next(
            event for event in central_path_events if event["type"] == "solar"
        )
        self.assertEqual(central_solar["visibility"], "visible")
        self.assertIsNotNone(central_solar["startLocalDateTime"])
        self.assertIsNotNone(central_solar["endLocalDateTime"])

    def test_solar_prefilter_rejects_a_clear_local_miss(self):
        solar_peak = astronomy.SearchGlobalSolarEclipse(self.obs_time).peak
        self.assertFalse(
            local_solar_eclipse_possible(
                solar_peak, astronomy.Observer(33.0, -96.0, 0.0)
            )
        )
        self.assertTrue(
            local_solar_eclipse_possible(
                solar_peak, astronomy.Observer(-31.3, -48.5, 0.0)
            )
        )


if __name__ == "__main__":
    unittest.main()
