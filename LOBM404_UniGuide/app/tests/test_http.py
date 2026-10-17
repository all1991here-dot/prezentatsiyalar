"""Mahalliy serverning haqiqiy HTTP so‘rovlari; bo‘sh port avtomatik tanlanadi."""
import http.client
import json
import threading
import unittest

from app.core import MAX_FEEDBACK_LENGTH
from app.server import MAX_REQUEST_BYTES, UniGuideHandler, create_server


class QuietHandler(UniGuideHandler):
    def log_message(self, *args):
        pass


class HTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = create_server(port=0, handler=QuietHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.port = cls.server.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=3)

    def request(self, method, path, body=None, headers=None):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=3)
        try:
            conn.request(method, path, body, headers or {})
            response = conn.getresponse()
            return response.status, dict(response.getheaders()), response.read()
        finally:
            conn.close()

    def post(self, payload):
        return self.request("POST", "/api/feedback", json.dumps(payload), {"Content-Type": "application/json"})

    def test_health_announces_demo_and_feedback_limit(self):
        status, headers, raw = self.request("GET", "/api/health")
        self.assertEqual(status, 200)
        data = json.loads(raw)
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["mode"], "teaching-demo")
        self.assertEqual(data["feedback_max_length"], MAX_FEEDBACK_LENGTH)
        self.assertIn("application/json", headers["Content-Type"])
        self.assertEqual(headers["X-Content-Type-Options"], "nosniff")

    def test_article_list_and_query(self):
        status, _, raw = self.request("GET", "/api/articles?q=kutubxona")
        data = json.loads(raw)
        self.assertEqual(status, 200)
        self.assertEqual(data["total"], 1)
        self.assertEqual(data["articles"][0]["id"], "kutubxona")
        self.assertEqual(len(data["categories"]), 4)

    def test_category_query_combination(self):
        status, _, raw = self.request("GET", "/api/articles?q=kitob&category=Kampus")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(raw)["articles"], [])

    def test_home_and_lab_assets_available(self):
        for path, marker in (("/", b"UniGuide"), ("/lab?view=metrics", b"NAMUNAVIY"), ("/lab.js", b"flow_data.csv"), ("/app.js", b"/api/feedback")):
            with self.subTest(path=path):
                status, _, raw = self.request("GET", path)
                self.assertEqual(status, 200)
                self.assertIn(marker, raw)

    def test_api_not_found_is_json(self):
        status, _, raw = self.request("GET", "/api/not-found")
        self.assertEqual(status, 404)
        self.assertIn("error", json.loads(raw))

    def test_directory_listing_is_not_exposed(self):
        self.assertEqual(self.request("GET", "/missing-directory/")[0], 404)
        self.assertEqual(self.request("GET", "/../data/articles.json")[0], 404)

    def test_feedback_accepts_text_without_persisting(self):
        status, _, raw = self.post({"message": "Yangi talaba uchun foydali."})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(raw)["accepted"], True)
        self.assertEqual(json.loads(raw)["persisted"], False)

    def test_feedback_accepts_current_boundary(self):
        self.assertEqual(self.post({"message": "a" * MAX_FEEDBACK_LENGTH})[0], 200)

    def test_feedback_rejects_current_boundary_plus_one(self):
        status, _, raw = self.post({"message": "a" * (MAX_FEEDBACK_LENGTH + 1)})
        self.assertEqual(status, 400)
        self.assertIn(str(MAX_FEEDBACK_LENGTH), json.loads(raw)["error"])

    def test_feedback_requires_json_object_and_text(self):
        for payload in (None, [], {}, {"message": 4}, {"message": " "}):
            with self.subTest(payload=payload):
                self.assertEqual(self.post(payload)[0], 400)

    def test_malformed_json_and_encoding_rejected(self):
        for raw in (b"{bad", b"\xff"):
            with self.subTest(raw=raw):
                self.assertEqual(self.request("POST", "/api/feedback", raw, {"Content-Type": "application/json"})[0], 400)

    def test_content_type_required(self):
        self.assertEqual(self.request("POST", "/api/feedback", b"hello", {"Content-Type": "text/plain"})[0], 415)

    def test_body_size_limit(self):
        self.assertEqual(self.request("POST", "/api/feedback", b"x" * (MAX_REQUEST_BYTES + 1), {"Content-Type": "application/json"})[0], 413)

    def test_empty_body_rejected(self):
        self.assertEqual(self.request("POST", "/api/feedback", b"", {"Content-Type": "application/json"})[0], 400)

    def test_unknown_post_is_not_accepted(self):
        self.assertEqual(self.request("POST", "/api/other", b"{}", {"Content-Type": "application/json"})[0], 404)


if __name__ == "__main__":
    unittest.main()
