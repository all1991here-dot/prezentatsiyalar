"""UniGuide mahalliy HTTP serveri. Ishga tushirish: python app/server.py."""

from __future__ import annotations

import argparse
import json
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

try:
    from .core import MAX_FEEDBACK_LENGTH, categories, load_articles, search_articles, validate_feedback
except ImportError:  # To‘g‘ridan-to‘g‘ri python app/server.py uchun
    from core import MAX_FEEDBACK_LENGTH, categories, load_articles, search_articles, validate_feedback

STATIC_DIR = Path(__file__).resolve().parent / "static"
MAX_REQUEST_BYTES = 8192


class UniGuideHandler(SimpleHTTPRequestHandler):
    """Ilova resurslari va kichik, holatsiz JSON API."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(STATIC_DIR), **kwargs)

    def end_headers(self):
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def send_json(self, payload, status=HTTPStatus.OK):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urlsplit(self.path)
        if url.path == "/api/health":
            return self.send_json({"status": "ok", "app": "UniGuide", "mode": "teaching-demo", "feedback_max_length": MAX_FEEDBACK_LENGTH})
        if url.path == "/api/articles":
            params = parse_qs(url.query)
            try:
                articles = load_articles()
                result = search_articles(articles, params.get("q", [""])[0], params.get("category", [""])[0])
            except (OSError, ValueError):
                return self.send_json({"error": "Kontentni o‘qib bo‘lmadi. articles.json faylini tekshiring."}, HTTPStatus.INTERNAL_SERVER_ERROR)
            return self.send_json({"articles": result, "total": len(result), "categories": categories(articles)})
        if url.path.startswith("/api/"):
            return self.send_json({"error": "API manzili topilmadi."}, HTTPStatus.NOT_FOUND)
        if url.path in ("/lab", "/lab/"):
            self.path = "/lab.html"
        # Faqat statik katalog ichidagi oddiy fayllar beriladi; ro‘yxat chiqarmaymiz.
        requested = Path(self.translate_path(urlsplit(self.path).path))
        if requested.is_dir() and not (requested / "index.html").exists():
            return self.send_error(HTTPStatus.NOT_FOUND)
        return super().do_GET()

    def do_POST(self):
        if urlsplit(self.path).path != "/api/feedback":
            return self.send_json({"error": "API manzili topilmadi."}, HTTPStatus.NOT_FOUND)
        if self.headers.get("Content-Type", "").split(";")[0].strip().lower() != "application/json":
            return self.send_json({"error": "Content-Type: application/json kerak."}, HTTPStatus.UNSUPPORTED_MEDIA_TYPE)
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.send_json({"error": "Content-Length noto‘g‘ri."}, HTTPStatus.BAD_REQUEST)
        if length < 1:
            return self.send_json({"error": "JSON matni bo‘sh."}, HTTPStatus.BAD_REQUEST)
        if length > MAX_REQUEST_BYTES:
            return self.send_json({"error": "So‘rov juda katta."}, HTTPStatus.REQUEST_ENTITY_TOO_LARGE)
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
            if not isinstance(payload, dict):
                raise ValueError("JSON obyekt yuboring.")
            validate_feedback(payload.get("message"))
        except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as error:
            return self.send_json({"error": str(error)}, HTTPStatus.BAD_REQUEST)
        # O‘quv rejimi: matn diskka yoki tashqi xizmatga saqlanmaydi.
        return self.send_json({"accepted": True, "persisted": False, "message": "Namuna fikr tekshirildi. Ma’lumot saqlanmadi."})


def create_server(host="127.0.0.1", port=8765, handler=UniGuideHandler):
    return ThreadingHTTPServer((host, port), handler)


def main():
    parser = argparse.ArgumentParser(description="UniGuide mahalliy o‘quv ilovasi")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    load_articles()  # Xato kontent bo‘lsa, server ochilishidan oldin aniqlanadi.
    with create_server(args.host, args.port) as server:
        print(f"UniGuide: http://{args.host}:{args.port}", flush=True)
        print("O‘quv paneli: /lab | To‘xtatish: Ctrl+C", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServer to‘xtadi.")


if __name__ == "__main__":
    main()
