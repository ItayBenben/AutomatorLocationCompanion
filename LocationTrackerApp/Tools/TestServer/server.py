#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("content-length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        auth = self.headers.get("authorization", "")

        print("\n--- POST", self.path, "---")
        print("Authorization:", auth[:120] + ("..." if len(auth) > 120 else ""))
        print("Body:", body)

        # Try parse JSON for nicer logs
        try:
            obj = json.loads(body) if body else None
        except Exception:
            obj = None

        resp = {
            "ok": True,
            "path": self.path,
            "received": obj,
        }
        data = json.dumps(resp).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main():
    host = "0.0.0.0"
    port = 8787
    server = HTTPServer((host, port), Handler)
    print(f"Listening on http://{host}:{port}")
    print("POST endpoint: /location")
    server.serve_forever()


if __name__ == "__main__":
    main()

