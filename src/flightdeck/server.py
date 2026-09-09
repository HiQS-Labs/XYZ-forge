from __future__ import annotations

import argparse
import json
import logging
import mimetypes
import os
import sys
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

from .aggregate import FlightdeckAggregator
from .contract import ConnectorConfig

LOG = logging.getLogger("flightdeck")
ROOT = Path(__file__).resolve().parents[2]
WEB_ROOT = ROOT / "web" / "flightdeck"
CSP = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"


class FlightdeckHandler(BaseHTTPRequestHandler):
    server_version = "Flightdeck/1"

    def _headers(self, status: int, content_type: str, length: int) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(length))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Security-Policy", CSP)
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        started = time.monotonic()
        host = self.headers.get("Host", "").split(":", 1)[0]
        if host not in {"127.0.0.1", "localhost", "[::1]"}:
            self._send_json({"error": "loopback host required"}, HTTPStatus.FORBIDDEN)
            return
        path = urlsplit(self.path).path
        if path == "/flightdeck.json":
            try:
                body = self.server.aggregator.snapshot()  # type: ignore[attr-defined]
                self._send_json(body)
                LOG.info("snapshot id=%s repos=%s duration_ms=%d", body["snapshot_id"], len(body["repos"]), (time.monotonic() - started) * 1000)
            except Exception as exc:  # boundary: return a bounded failure, keep server alive
                LOG.exception("snapshot failed")
                self._send_json({"error": type(exc).__name__, "message": "snapshot unavailable"}, HTTPStatus.SERVICE_UNAVAILABLE)
            return
        if path in {"/", "/flightdeck", "/flightdeck/"}:
            path = "/index.html"
        elif path.startswith("/flightdeck/"):
            path = path.removeprefix("/flightdeck")
        candidate = (WEB_ROOT / path.lstrip("/")).resolve()
        if WEB_ROOT.resolve() not in candidate.parents or not candidate.is_file():
            self._send_json({"error": "not found"}, HTTPStatus.NOT_FOUND)
            return
        body = candidate.read_bytes()
        self._headers(HTTPStatus.OK, mimetypes.guess_type(candidate.name)[0] or "application/octet-stream", len(body))
        self.wfile.write(body)

    def _send_json(self, value: object, status: int = HTTPStatus.OK) -> None:
        body = json.dumps(value, separators=(",", ":")).encode()
        self._headers(status, "application/json; charset=utf-8", len(body))
        self.wfile.write(body)

    def log_message(self, fmt: str, *args: object) -> None:
        LOG.debug(fmt, *args)


class FlightdeckServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address: tuple[str, int], config: ConnectorConfig):
        super().__init__(address, FlightdeckHandler)
        self.aggregator = FlightdeckAggregator(config)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Serve the local Flightdeck dashboard")
    parser.add_argument("--host", default="127.0.0.1", choices=("127.0.0.1", "::1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("FLIGHTDECK_PORT", "8768")))
    args = parser.parse_args(argv)
    logging.basicConfig(level=os.environ.get("FLIGHTDECK_LOG_LEVEL", "INFO"), format="%(asctime)s %(levelname)s %(name)s %(message)s")
    server = FlightdeckServer((args.host, args.port), ConnectorConfig.from_environment())
    LOG.info("serving http://%s:%d/flightdeck/", args.host, server.server_port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
