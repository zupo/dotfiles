import contextlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "swiftbar_usage", Path(__file__).resolve().parents[1] / "common/swiftbar-usage.py"
)
usage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(usage)


class UsageTests(unittest.TestCase):
    def test_weekly_window_can_be_primary_or_secondary(self):
        weekly = {"used_percent": 18, "reset_at": 2000000000, "limit_window_seconds": 604800}
        hourly = {"used_percent": 90, "reset_at": 1900000000, "limit_window_seconds": 18000}
        for primary, secondary in [(weekly, None), (hourly, weekly)]:
            with self.subTest(primary=primary):
                result = usage.weekly("Codex", {"rate_limit": {
                    "primary_window": primary, "secondary_window": secondary,
                }})
                self.assertEqual(result["used"], 18)
                self.assertEqual(result["reset"], 2000000000)

    def test_claude_weekly_usage(self):
        result = usage.weekly("Claude", {"seven_day": {
            "utilization": 18, "resets_at": "2026-11-29T22:59:59+00:00",
        }})
        self.assertEqual(result["used"], 18)
        self.assertEqual(result["reset"], 1795993199)

    def test_label_shows_remaining_and_local_weekday(self):
        import datetime as dt
        reset = dt.datetime(2026, 11, 29, 23).timestamp()
        self.assertEqual(usage.label({"used": 23, "reset": reset}), "77%\\nSun")

    def test_failed_or_expired_fetch_never_shows_a_percentage(self):
        cases = [
            {"side_effect": OSError("secret must not be printed")},
            {"return_value": {"used": 23, "reset": 0, "updated": 0}},
        ]
        for case in cases:
            output = io.StringIO()
            with self.subTest(case=case), patch.object(usage, "fetch", **case), patch.object(usage.sys, "argv", ["usage", "Claude"]), contextlib.redirect_stdout(output):
                usage.main()
            self.assertEqual(output.getvalue().splitlines()[0], "unavailable | sfimage=asterisk")
            self.assertNotIn("secret", output.getvalue())
            self.assertNotIn("%", output.getvalue())


if __name__ == "__main__":
    unittest.main()
