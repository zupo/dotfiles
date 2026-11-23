import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "rex_usage", Path(__file__).resolve().parents[1] / "common/rex-usage.py"
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

    def test_old_or_expired_figures_are_not_presented_as_current(self):
        data = {"used": 40, "updated": 1000, "reset": 1000 + 3 * 86400}
        self.assertEqual(usage.label("Codex", data, 1000), "Codex\u2004 ▰▰▱▱▱ · 3d")
        self.assertEqual(usage.label("Codex", data, 1700), "Codex · stale")
        self.assertEqual(usage.label("Codex", {**data, "reset": 999}, 1000), "Codex · stale")
        self.assertEqual(usage.label("Codex", {**data, "error": "HTTP 401"}, 1000), "Codex · stale")
        self.assertEqual(usage.label("Codex", {}, 1000), "Codex · unavailable")

    def test_existing_tabs_are_reordered_without_creating_or_focusing(self):
        windows = [
            {"window_id": "main", "label": "dotfiles"},
            {"window_id": "work", "label": "Codex integration task"},
            {"window_id": "claude", "label": "Claude · unavailable"},
            {"window_id": "codex", "label": "Codex · unavailable"},
        ]
        def rex(*args):
            if args[:2] == ("session", "ls"):
                return {"sessions": [{"session_id": "session", "label": "dotfiles"}]}
            if args[:2] == ("session", "inspect"):
                return {"windows": windows}
        with patch.object(usage, "rex", side_effect=rex) as calls, patch.object(usage, "read_cache", return_value={}):
            usage.sync_tabs()
        self.assertEqual([w["window_id"] for w in windows], ["main", "codex", "claude", "work"])
        self.assertEqual([c.args[:3] for c in calls.call_args_list[2:]], [
            ("api", "call", "session.move_window"), ("api", "call", "session.move_window"),
        ])


if __name__ == "__main__":
    unittest.main()
