"""Materiallar butligi va o‘quv ma’lumotlarining izchilligini tekshirish.

Bu qabul, mualliflik, xizmat akkaunti yoki GitHub Actions isbotlovchisi emas.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from app.core import load_articles
from metrics import read_items

FILENAMES = (
    "L01_charter.md", "L02_backlog.md", "L03_workflow.md", "L04_wip.md",
    "L05_metrics.md", "L06_content_acceptance.md", "L07_wbs.md", "L08_sprint1.md",
    "L09_risks_budget.md", "L10_review1.md", "L11_quality.md", "L12_review2.md",
    "L13_monitoring.md", "L14_release.md", "L15_defense.md",
)
ARTICLE_IDS = {"kutubxona", "lms", "dars-jadvali", "dekanat", "xavfsizlik", "klublar"}
REQUIRED_APP_FILES = (
    "app/core.py", "app/server.py", "app/data/articles.json",
    "app/static/index.html", "app/static/app.js", "app/static/style.css",
    "app/tests/test_core.py", "app/tests/test_http.py",
    "scripts/metrics.py", "scripts/tests/test_metrics.py", "data/sprint_data.csv",
)


def check() -> list[str]:
    errors = []
    for relative in REQUIRED_APP_FILES:
        if not (ROOT / relative).is_file():
            errors.append(f"Kerakli fayl yo‘q: {relative}")
    for folder in ("templates", "examples"):
        for filename in FILENAMES:
            if not (ROOT / folder / filename).is_file():
                errors.append(f"Dars artefakti yo‘q: {folder}/{filename}")
    try:
        articles = load_articles(ROOT / "app/data/articles.json")
        if len(articles) != 6 or {item["id"] for item in articles} != ARTICLE_IDS:
            errors.append("Kontent aynan kelishilgan olti barqaror article IDdan iborat bo‘lsin.")
        for article in articles:
            if len(article.get("checklist", [])) < 3:
                errors.append(f"{article['id']}: kamida 3 yo‘l-yo‘riq qadami kerak.")
    except (OSError, ValueError, KeyError) as error:
        errors.append(f"Maqola ma’lumoti: {error}")
    try:
        for item in read_items(ROOT / "data/flow_data.csv"):
            if item["article_id"] not in ARTICLE_IDS:
                errors.append(f"{item['id']}: noma’lum article_id {item['article_id']}")
    except (OSError, ValueError) as error:
        errors.append(f"Oqim ma’lumoti: {error}")
    try:
        with (ROOT / "data/sprint_data.csv").open(encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream)
            expected = {"sprint", "story_id", "title", "planned_points", "status", "completed_points"}
            if not expected.issubset(reader.fieldnames or []):
                raise ValueError("Sprint CSV ustunlari noto‘g‘ri.")
            seen, done_stories = set(), set()
            row_count = 0
            for row in reader:
                row_count += 1
                key = row["sprint"], row["story_id"]
                if key in seen:
                    errors.append(f"{key}: bir sprintda story takrorlangan.")
                seen.add(key)
                points, completed = int(row["planned_points"]), int(row["completed_points"])
                if points <= 0 or completed not in (0, points):
                    errors.append(f"{key}: point musbat, completed esa0 yoki to‘liq point bo‘lsin.")
                if row["status"] not in {"done", "incomplete", "deferred"}:
                    errors.append(f"{key}: noma’lum status.")
                if (row["status"] == "done") != (completed == points):
                    errors.append(f"{key}: faqat done story to‘liq velocity beradi.")
                if row["status"] == "done":
                    if row["story_id"] in done_stories:
                        errors.append(f"{row['story_id']}: tugallangan point ikki marta hisoblangan.")
                    done_stories.add(row["story_id"])
            if not row_count:
                errors.append("Sprint CSV bo‘sh.")
    except (OSError, ValueError, KeyError, TypeError) as error:
        errors.append(f"Sprint ma’lumoti: {error}")
    return errors


def main() -> int:
    errors = check()
    if errors:
        for error in errors:
            print(f"XATO: {error}", file=sys.stderr)
        return 1
    print("OK: 15 shablon, 15 misol, 6 maqola IDsi, ilova fayllari va CSV izchil.")
    print("Bu tekshiruv haqiqiy jamoa ishini yoki Trello/Jira/Actions natijasini tasdiqlamaydi.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
