#!/usr/bin/env python3
"""Unit tests for phase classification, degree normalization, and directional labeling."""

import math
import unittest
from scripts.moonshot_ephemeris import classify_phase, normalize_degrees


class TestClassification(unittest.TestCase):
    def test_degree_normalization(self):
        self.assertAlmostEqual(normalize_degrees(0.0), 0.0)
        self.assertAlmostEqual(normalize_degrees(360.0), 0.0)
        self.assertAlmostEqual(normalize_degrees(720.0), 0.0)
        self.assertAlmostEqual(normalize_degrees(-90.0), 270.0)
        self.assertAlmostEqual(normalize_degrees(450.0), 90.0)

    def test_eight_named_phases_centers(self):
        cases = [
            (0.0, "New Moon", "neutral"),
            (45.0, "Waxing Crescent", "waxing"),
            (90.0, "First Quarter", "waxing"),
            (135.0, "Waxing Gibbous", "waxing"),
            (180.0, "Full Moon", "neutral"),
            (225.0, "Waning Gibbous", "waning"),
            (270.0, "Last Quarter", "waning"),
            (315.0, "Waning Crescent", "waning"),
        ]
        for angle, expected_name, expected_dir in cases:
            name, direction = classify_phase(angle)
            self.assertEqual(name, expected_name, f"Failed for angle {angle}")
            self.assertEqual(direction, expected_dir, f"Failed for angle {angle}")

    def test_octant_boundaries(self):
        boundary_cases = [
            (22.49, "New Moon"),
            (22.50, "Waxing Crescent"),
            (67.49, "Waxing Crescent"),
            (67.50, "First Quarter"),
            (112.49, "First Quarter"),
            (112.50, "Waxing Gibbous"),
            (157.49, "Waxing Gibbous"),
            (157.50, "Full Moon"),
            (202.49, "Full Moon"),
            (202.50, "Waning Gibbous"),
            (247.49, "Waning Gibbous"),
            (247.50, "Last Quarter"),
            (292.49, "Last Quarter"),
            (292.50, "Waning Crescent"),
            (337.49, "Waning Crescent"),
            (337.50, "New Moon"),
            (359.99, "New Moon"),
        ]
        for angle, expected_name in boundary_cases:
            name, _ = classify_phase(angle)
            self.assertEqual(name, expected_name, f"Boundary failure at angle {angle}")


if __name__ == "__main__":
    unittest.main()
