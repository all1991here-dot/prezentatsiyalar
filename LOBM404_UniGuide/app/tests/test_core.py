"""Domen qoidalari: mazmun, qidiruv va fikr chegaralari."""
import json
import tempfile
import unittest
from pathlib import Path

from app.core import MAX_FEEDBACK_LENGTH, categories, load_articles, normalize, search_articles, validate_feedback


class CoreTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.articles = load_articles()

    def test_seed_six_unique_articles(self):
        self.assertEqual(len(self.articles), 6)
        self.assertEqual(len({article["id"] for article in self.articles}), 6)

    def test_categories_are_unique_and_sorted(self):
        self.assertEqual(categories(self.articles), ["Kampus", "Ta’lim", "Xavfsizlik", "Xizmatlar"])

    def test_empty_query_returns_all_in_original_order(self):
        self.assertEqual(search_articles(self.articles), self.articles)

    def test_case_and_apostrophe_normalization(self):
        self.assertEqual(normalize("  O‘QUV   YOʻLI  "), "o'quv yo'li")
        self.assertEqual(normalize("O’quv"), normalize("o'quv"))

    def test_search_matches_body_and_case(self):
        self.assertEqual([item["id"] for item in search_articles(self.articles, "PASPORT")], ["dekanat"])

    def test_search_requires_all_query_words(self):
        self.assertEqual([item["id"] for item in search_articles(self.articles, "kutubxona katalog")], ["kutubxona"])
        self.assertEqual(search_articles(self.articles, "kutubxona pasport"), [])

    def test_category_exact_match_after_normalization(self):
        matches = search_articles(self.articles, category="TA'LIM")
        self.assertEqual({item["id"] for item in matches}, {"kutubxona", "lms", "dars-jadvali"})
        self.assertEqual(search_articles(self.articles, category="ta"), [])

    def test_query_and_category_are_combined(self):
        self.assertEqual(search_articles(self.articles, "kitob", "Kampus"), [])
        self.assertEqual([x["id"] for x in search_articles(self.articles, "kitob", "Ta’lim")], ["kutubxona"])

    def test_search_does_not_mutate_source(self):
        original = json.dumps(self.articles, ensure_ascii=False)
        search_articles(self.articles, "kitob")
        self.assertEqual(json.dumps(self.articles, ensure_ascii=False), original)

    def test_unknown_query_returns_empty_list(self):
        self.assertEqual(search_articles(self.articles, "bu-soz-mavjud-emas"), [])

    def test_feedback_trims_surrounding_whitespace(self):
        self.assertEqual(validate_feedback("  Yangi yo‘riqnoma kerak. \n"), "Yangi yo‘riqnoma kerak.")

    def test_feedback_empty_or_whitespace_rejected(self):
        for value in ("", "  \n\t"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate_feedback(value)

    def test_feedback_non_text_rejected(self):
        for value in (None, 42, [], {}, True):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate_feedback(value)

    def test_feedback_boundary_accepts_maximum(self):
        message = "a" * MAX_FEEDBACK_LENGTH
        self.assertEqual(validate_feedback(message), message)

    def test_feedback_boundary_rejects_maximum_plus_one(self):
        with self.assertRaises(ValueError):
            validate_feedback("a" * (MAX_FEEDBACK_LENGTH + 1))

    def test_feedback_unicode_count_uses_code_points(self):
        self.assertEqual(validate_feedback("📘" * MAX_FEEDBACK_LENGTH), "📘" * MAX_FEEDBACK_LENGTH)

    def test_invalid_content_shapes_rejected(self):
        valid = self.articles[0]
        cases = [None, {}, ["bad"], [{**valid, "title": " "}], [valid, valid], [{**valid, "checklist": "bad"}]]
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "articles.json"
            for payload in cases:
                path.write_text(json.dumps(payload), encoding="utf-8")
                with self.subTest(payload=payload), self.assertRaises(ValueError):
                    load_articles(path)


if __name__ == "__main__":
    unittest.main()
