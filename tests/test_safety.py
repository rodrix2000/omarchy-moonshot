"""Static security-policy regression tests for shipped runtime source."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNTIME_SUFFIXES = {".js", ".py", ".qml", ".sh"}
FORBIDDEN = re.compile(
    r"(?:sudo |pkexec |systemctl |google-analytics|telemetry_client)"
)


class TestSafetyPolicy(unittest.TestCase):
    def test_runtime_source_has_no_privilege_service_or_tracking_paths(self):
        violations = []
        for path in ROOT.rglob("*"):
            if not path.is_file() or path.suffix not in RUNTIME_SUFFIXES:
                continue
            relative = path.relative_to(ROOT)
            if relative.parts[0] in {".git", "tests", "vendor"}:
                continue
            for line_number, line in enumerate(
                path.read_text(encoding="utf-8").splitlines(), start=1
            ):
                if FORBIDDEN.search(line):
                    violations.append(f"{relative}:{line_number}")

        self.assertEqual([], violations, f"forbidden runtime patterns: {violations}")


if __name__ == "__main__":
    unittest.main()
