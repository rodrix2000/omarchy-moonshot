#!/usr/bin/env python3
"""Performance and budget tests for ephemeris computation."""

import time
import unittest
from scripts.moonshot_ephemeris import compute_snapshot


class TestPerformance(unittest.TestCase):
    def test_snapshot_computation_time_budget(self):
        # Target: sub-150ms per snapshot calculation
        runs = 10
        start = time.perf_counter()
        for i in range(runs):
            compute_snapshot(
                request_id=f"perf-{i}",
                instant_utc="2026-08-22T19:30:00Z",
                selected_date="2026-08-22",
                timezone_name="America/Chicago",
                latitude=33.0,
                longitude=-96.0,
            )
        elapsed_total = time.perf_counter() - start
        avg_ms = (elapsed_total / runs) * 1000.0

        self.assertLess(avg_ms, 150.0, f"Average execution time {avg_ms:.2f}ms exceeded 150ms budget")


if __name__ == "__main__":
    unittest.main()
