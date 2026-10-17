"""Sinash oson bo‘lgan domen qoidalari. Tashqi paket talab etilmaydi."""

from __future__ import annotations

import json
import unicodedata
from pathlib import Path

DATA_PATH = Path(__file__).resolve().parent / "data" / "articles.json"
MAX_FEEDBACK_LENGTH = 500


def normalize(value: str) -> str:
    """Qidiruvda katta-kichik harf va o‘zbek apostroflarini birxillashtirish."""
    folded = unicodedata.normalize("NFKC", value).casefold()
    for apostrophe in ("‘", "’", "ʻ", "ʼ", "`"):
        folded = folded.replace(apostrophe, "'")
    return " ".join(folded.split())


def load_articles(path: Path | str = DATA_PATH) -> list[dict]:
    """O‘quv kontentini o‘qish va aniq xabar bilan tekshirish."""
    with Path(path).open(encoding="utf-8") as stream:
        articles = json.load(stream)
    if not isinstance(articles, list):
        raise ValueError("Maqolalar JSON ro‘yxat bo‘lishi kerak.")
    seen = set()
    for article in articles:
        if not isinstance(article, dict):
            raise ValueError("Har bir maqola JSON obyekt bo‘lishi kerak.")
        for key in ("id", "title", "category", "summary", "body"):
            if not isinstance(article.get(key), str) or not article[key].strip():
                raise ValueError(f"Maqolada {key} bo‘sh yoki noto‘g‘ri.")
        if article["id"] in seen:
            raise ValueError("Maqola identifikatorlari takrorlanmasligi kerak.")
        seen.add(article["id"])
        checklist = article.get("checklist", [])
        if not isinstance(checklist, list) or any(not isinstance(x, str) for x in checklist):
            raise ValueError("checklist matnlar ro‘yxati bo‘lishi kerak.")
    return articles


def search_articles(articles: list[dict], query: str = "", category: str = "") -> list[dict]:
    """So‘rovdagi barcha so‘zlar va ixtiyoriy aniq turkum orqali filtrlash."""
    terms = normalize(query).split()
    chosen_category = normalize(category)
    results = []
    for article in articles:
        if chosen_category and normalize(article["category"]) != chosen_category:
            continue
        haystack = normalize(" ".join(article[key] for key in ("title", "summary", "body")))
        if all(term in haystack for term in terms):
            results.append(article)
    return results


def categories(articles: list[dict]) -> list[str]:
    return sorted({article["category"] for article in articles})


def validate_feedback(value: object) -> str:
    """Faqat matn qabul qilinadi; bo‘shliqlar olib tashlangach 1..500 belgi."""
    if not isinstance(value, str):
        raise ValueError("Fikr matn ko‘rinishida bo‘lishi kerak.")
    cleaned = value.strip()
    if not 1 <= len(cleaned) <= MAX_FEEDBACK_LENGTH:
        raise ValueError(f"Fikr 1–{MAX_FEEDBACK_LENGTH} belgidan iborat bo‘lishi kerak.")
    return cleaned
