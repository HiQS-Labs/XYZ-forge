"""Explicit, optional loopback preview over the existing Flightdeck read boundary."""

from __future__ import annotations

import argparse
import logging
import sys
from http import HTTPStatus
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from src.flightdeck.aggregate import FlightdeckAggregator
from src.flightdeck.contract import ConnectorConfig
from src.flightdeck.server import FlightdeckHandler

HERE = Path(__file__).resolve().parent
ASSETS = {
    "/": (HERE / "index.html", "text/html; charset=utf-8"),
    "/index.html": (HERE / "index.html", "text/html; charset=utf-8"),
    "/app.css": (HERE / "app.css", "text/css; charset=utf-8"),
    "/app.js": (HERE / "app.js", "text/javascript; charset=utf-8"),
    "/demo.mjs": (HERE / "demo.mjs", "text/javascript; charset=utf-8"),
    "/shared/presentation.mjs": (ROOT / "web/flightdeck/presentation.mjs", "text/javascript; charset=utf-8"),
    "/shared/issue-context.mjs": (ROOT / "web/flightdeck/issue-context.mjs", "text/javascript; charset=utf-8"),
}


class PreviewHandler(FlightdeckHandler):
    def do_GET(self) -> None:
        if self.headers.get("Host", "").split(":", 1)[0] not in {"127.0.0.1", "localhost"}:
            self._send_json({"error": "loopback host required"}, HTTPStatus.FORBIDDEN)
            return
        path = urlsplit(self.path).path
        if path == "/flightdeck.json":
            if not self.server.live_reads:
                self._send_json({"error": "Live reads are disabled. Restart with --live."}, HTTPStatus.FORBIDDEN)
                return
            super().do_GET()
            return
        asset = ASSETS.get(path)
        if asset is None:
            self._send_json({"error": "not found"}, HTTPStatus.NOT_FOUND)
            return
        body = asset[0].read_bytes()
        if asset[0].name == "index.html":
            body = body.replace(b"__MODE__", b"live" if self.server.live_reads else b"demo")
        self._headers(HTTPStatus.OK, asset[1], len(body))
        self.wfile.write(body)


def main() -> int:
    parser = argparse.ArgumentParser(description="Optional Paperclip-inspired dashboard preview")
    parser.add_argument("--live", action="store_true", help="opt in to existing local Flightdeck readers")
    parser.add_argument("--port", type=int, default=8769)
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(levelname)s %(message)s")
    try:
        server = ThreadingHTTPServer(("127.0.0.1", args.port), PreviewHandler)
        server.daemon_threads = True
        server.live_reads = args.live
        if args.live:
            server.aggregator = FlightdeckAggregator(ConnectorConfig.from_environment())
    except (OSError, ValueError) as exc:
        parser.exit(1, f"Preview unavailable: {exc}\n")
    print(f"http://127.0.0.1:{server.server_port}/ — {'local live reads' if args.live else 'synthetic demo; no live reads'}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
