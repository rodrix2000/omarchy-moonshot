#!/usr/bin/env python3
"""Tests for time zone handling, DST boundaries, and fractional UTC offsets."""

import datetime
import unittest
import zoneinfo

from scripts.moonshot_ephemeris import compute_snapshot


class TestTimezones(unittest.TestCase):
    def test_dst_spring_forward(self):
        # US Central time springs forward on 2026-03-08
        snap = compute_snapshot(
            request_id="dst-spring",
            instant_utc="2026-03-08T07:30:00Z",
            selected_date="2026-03-08",
            timezone_name="America/Chicago",
            latitude=33.0,
            longitude=-96.0,
        )
        self.assertEqual(snap["status"], "ok")
        self.assertEqual(snap["data"]["observation"]["selectedLocalDate"], "2026-03-08")

    def test_fractional_offset_kolkata(self):
        # India Standard Time (UTC+5:30)
        snap = compute_snapshot(
            request_id="kolkata-test",
            instant_utc="2026-08-22T12:00:00Z",
            selected_date="2026-08-22",
            timezone_name="Asia/Kolkata",
            latitude=22.57,
            longitude=88.36,
        )
        self.assertEqual(snap["status"], "ok")
        self.assertEqual(snap["data"]["observation"]["utcOffsetSeconds"], 19800)

    def test_fractional_offset_chatham(self):
        # Chatham Islands (UTC+12:45 standard / UTC+13:45 DST)
        snap = compute_snapshot(
            request_id="chatham-test",
            instant_utc="2026-08-22T12:00:00Z",
            selected_date="2026-08-22",
            timezone_name="Pacific/Chatham",
            latitude=-43.95,
            longitude=-176.56,
        )
        self.assertEqual(snap["status"], "ok")
        self.assertEqual(snap["data"]["observation"]["utcOffsetSeconds"], 45900)


if __name__ == "__main__":
    unittest.main()
