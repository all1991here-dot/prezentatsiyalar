"""Hisoblash semantikasi va buzilgan ma’lumotlarni tekshirish."""

import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from metrics import ROOT, calculate, read_items


class MetricsTests(unittest.TestCase):
    def setUp(self):
        self.items = read_items(ROOT / "data" / "flow_data.csv")

    def sample(self, content):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        path = Path(temporary.name) / "sample.csv"
        path.write_text("id,article_id,title,queued,started,done\n" + content, encoding="utf-8")
        return path

    def test_exact_sample_means_and_denominator(self):
        report = calculate(self.items, date(2026, 9, 1), date(2026, 9, 11), date(2026, 9, 10))
        self.assertEqual(report["completed_count"], 6)
        self.assertEqual(report["mean_lead_days"], 5)
        self.assertAlmostEqual(report["mean_cycle_days"], 16 / 6)
        self.assertAlmostEqual(report["throughput_per_day"], 6 / 10)

    def test_halfopen_boundary_and_historical_wip(self):
        report = calculate(self.items, date(2026, 9, 10), date(2026, 9, 11), date(2026, 9, 10))
        self.assertEqual([row["id"] for row in report["completed_items"]], ["C06"])
        self.assertEqual(report["active_item_ages"], [
            {"id": "C07", "age_days": 1}, {"id": "C08", "age_days": 0},
            {"id": "C10", "age_days": 0}])
        self.assertEqual(report["wip"], 3)
        # Completion on the cut-off date means no longer WIP at that date.
        next_report = calculate(self.items, date(2026, 9, 11), date(2026, 9, 12), date(2026, 9, 11))
        self.assertEqual(next_report["completed_count"], 1)
        self.assertEqual(next_report["wip"], 2)

    def test_empty_completion_window_is_not_zero_average(self):
        report = calculate(self.items, date(2026, 8, 1), date(2026, 8, 2), date(2026, 8, 1))
        self.assertIsNone(report["mean_lead_days"])
        self.assertIsNone(report["mean_cycle_days"])
        self.assertIsNone(report["mean_age_days"])
        self.assertEqual(report["throughput_per_day"], 0)

    def test_missing_queued_and_done_without_started_rejected(self):
        for row in ("X,kutubxona,Test,,2026-09-02,2026-09-03\n",
                    "X,kutubxona,Test,2026-09-01,,2026-09-03\n"):
            with self.subTest(row=row), self.assertRaises(ValueError):
                read_items(self.sample(row))

    def test_bad_date_chronology_and_duplicate_rejected(self):
        for row in ("X,lms,Test,2026-02-30,,\n", "X,lms,Test,20260901,,\n",
                    "X,lms,Test,2026-09-02,2026-09-01,\n",
                    "X,lms,Test,2026-09-01,2026-09-03,2026-09-02\n",
                    "X,lms,Test,2026-09-01,,\nX,lms,Test,2026-09-01,,\n"):
            with self.subTest(row=row), self.assertRaises(ValueError):
                read_items(self.sample(row))

    def test_equal_dates_are_elapsed_zero_and_window_must_be_positive(self):
        items = read_items(self.sample("X,lms,Test,2026-09-01,2026-09-01,2026-09-01\n"))
        report = calculate(items, date(2026, 9, 1), date(2026, 9, 2), date(2026, 9, 1))
        self.assertEqual(report["mean_cycle_days"], 0)
        self.assertEqual(report["wip"], 0)
        with self.assertRaises(ValueError):
            calculate(items, date(2026, 9, 1), date(2026, 9, 1), date(2026, 9, 1))


if __name__ == "__main__":
    unittest.main()
