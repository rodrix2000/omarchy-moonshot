#!/usr/bin/env python3
"""Protocol v1 and CLI error handling tests."""

import subprocess
import sys
import unittest
from pathlib import Path


class TestProtocol(unittest.TestCase):
    def setUp(self):
        self.script = Path(__file__).parent.parent / "scripts" / "moonshot_ephemeris.py"

    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(self.script), *args],
            capture_output=True,
            text=True,
        )

    def test_version_subcommand(self):
        res = self.run_cli("version")
        self.assertEqual(res.returncode, 0)
        self.assertIn("Astronomy Engine", res.stdout)
        self.assertIn("2.1.19", res.stdout)

    def test_self_test_subcommand(self):
        res = self.run_cli("self-test")
        self.assertEqual(res.returncode, 0)
        self.assertIn('"status": "ok"', res.stdout)

    def test_invalid_timezone_error(self):
        res = self.run_cli("snapshot", "--timezone", "Invalid/Fake_Zone")
        self.assertEqual(res.returncode, 1)
        self.assertIn("INVALID_TIME_ZONE", res.stderr)

    def test_invalid_coordinates_error(self):
        res = self.run_cli("snapshot", "--latitude", "120.0", "--longitude", "0.0")
        self.assertEqual(res.returncode, 1)
        self.assertIn("INVALID_COORDINATES", res.stderr)


if __name__ == "__main__":
    unittest.main()
