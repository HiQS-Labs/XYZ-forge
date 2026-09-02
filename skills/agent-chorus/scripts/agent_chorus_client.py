#!/usr/bin/env python3
"""Remote client for AgentChorus Bridge over HTTP/HTTPS (GH-384).

Enables off-device agents to join, poll, send turns, and close AgentChorus
discussions across a Cloudflare Tunnel or localhost bridge.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional, Tuple


class BridgeClient:
    """HTTP client for AgentChorus Bridge."""

    def __init__(
        self,
        base_url: str,
        cf_client_id: Optional[str] = None,
        cf_client_secret: Optional[str] = None,
        timeout: float = 30.0,
    ):
        self.base_url = base_url.rstrip("/")
        self.cf_client_id = cf_client_id or os.environ.get("CF_ACCESS_CLIENT_ID")
        self.cf_client_secret = cf_client_secret or os.environ.get("CF_ACCESS_CLIENT_SECRET")
        self.timeout = timeout

    def _headers(self, token: Optional[str] = None) -> Dict[str, str]:
        headers = {
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json",
            "User-Agent": "AgentChorus-Client/1.0",
        }
        if token:
            headers["Authorization"] = f"Bearer {token}"
        if self.cf_client_id:
            headers["CF-Access-Client-Id"] = self.cf_client_id
        if self.cf_client_secret:
            headers["CF-Access-Client-Secret"] = self.cf_client_secret
        return headers

    def _request(
        self, method: str, path: str, data: Optional[Dict[str, Any]] = None, token: Optional[str] = None
    ) -> Dict[str, Any]:
        url = f"{self.base_url}{path}"
        headers = self._headers(token)
        body = json.dumps(data).encode("utf-8") if data is not None else None
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                resp_bytes = response.read()
                return json.loads(resp_bytes.decode("utf-8")) if resp_bytes else {}
        except urllib.error.HTTPError as exc:
            err_body = exc.read().decode("utf-8", errors="replace")
            try:
                err_json = json.loads(err_body)
                msg = err_json.get("error", err_body)
            except ValueError:
                msg = err_body
            raise RuntimeError(f"HTTP {exc.code} {exc.reason}: {msg}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f"Connection failed to {url}: {exc.reason}") from exc

    def create_session(
        self, subject: str, packet: str, agents: int = 2, timed_watch: bool = False
    ) -> Dict[str, Any]:
        return self._request(
            "POST",
            "/sessions",
            {"subject": subject, "packet": packet, "agents": agents, "timed_watch": timed_watch},
        )

    def attach_session(self, discussion_id: str) -> Dict[str, Any]:
        return self._request("POST", "/sessions", {"id": discussion_id})

    def join(
        self,
        discussion_id: str,
        agent_number: int,
        expect_subject: Optional[str] = None,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        return self._request(
            "POST",
            f"/sessions/{discussion_id}/join",
            {"agent": agent_number, "expect_subject": expect_subject, "model": model},
        )

    def status(self, discussion_id: str) -> Dict[str, Any]:
        return self._request("GET", f"/sessions/{discussion_id}/status")

    def turns(self, discussion_id: str, after: int = 0, limit: int = 100) -> Dict[str, Any]:
        return self._request("GET", f"/sessions/{discussion_id}/turns?after={after}&limit={limit}")

    def send(
        self,
        discussion_id: str,
        agent_number: int,
        next_agent_number: int,
        message: str,
        token: str,
        expected_turn: Optional[int] = None,
        idempotency_key: Optional[str] = None,
        check_clean: bool = False,
    ) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "agent": agent_number,
            "next_agent": next_agent_number,
            "message": message,
            "check_clean": check_clean,
        }
        if expected_turn is not None:
            payload["expected_turn"] = expected_turn
        if idempotency_key is not None:
            payload["idempotency_key"] = idempotency_key
        return self._request("POST", f"/sessions/{discussion_id}/send", payload, token=token)

    def close(
        self,
        discussion_id: str,
        agent_number: int,
        message: str,
        token: str,
        trivial: bool = False,
        check_clean: bool = False,
    ) -> Dict[str, Any]:
        return self._request(
            "POST",
            f"/sessions/{discussion_id}/close",
            {"agent": agent_number, "message": message, "trivial": trivial, "check_clean": check_clean},
            token=token,
        )

    def heartbeat(self, discussion_id: str, agent_number: int, token: str) -> Dict[str, Any]:
        return self._request(
            "POST", f"/sessions/{discussion_id}/heartbeat", {"agent": agent_number}, token=token
        )

    def poll_for_turn(
        self,
        discussion_id: str,
        agent_number: int,
        token: str,
        interval: float = 5.0,
        timeout: float = 300.0,
    ) -> Tuple[str, Dict[str, Any]]:
        """Poll until it is this participant's turn or discussion is closed."""
        member = f"agent{agent_number}"
        start = time.monotonic()
        while True:
            st = self.status(discussion_id)
            if st.get("status", "").lower() == "closed":
                return "closed", st
            if st.get("next") == member:
                return "take-turn", st
            if (time.monotonic() - start) >= timeout:
                return "timeout", st
            # Send periodic heartbeat during long poll
            try:
                self.heartbeat(discussion_id, agent_number, token)
            except Exception:
                pass
            time.sleep(interval)


def load_text(file_path: Optional[str], inline_text: Optional[str]) -> str:
    if inline_text is not None:
        return inline_text.strip()
    if file_path == "-":
        return sys.stdin.read().strip()
    if file_path:
        return Path(file_path).read_text(encoding="utf-8").strip()
    raise ValueError("either inline text or file path is required")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AgentChorus Remote Bridge Client")
    parser.add_argument("--url", default="http://127.0.0.1:8080", help="Bridge server URL (default: http://127.0.0.1:8080)")
    parser.add_argument("--cf-client-id", help="Cloudflare Access Client ID")
    parser.add_argument("--cf-client-secret", help="Cloudflare Access Client Secret")

    sub = parser.add_subparsers(dest="command", required=True)

    # join
    p_join = sub.add_parser("join", help="Join discussion and acquire capability token")
    p_join.add_argument("--id", required=True, help="6-digit discussion ID")
    p_join.add_argument("--agent", type=int, required=True, help="Agent seat number (e.g. 2)")
    p_join.add_argument("--expect-subject", help="Expected subject")
    p_join.add_argument("--model", help="Participant model name")

    # status
    p_status = sub.add_parser("status", help="Inspect discussion status")
    p_status.add_argument("--id", required=True, help="6-digit discussion ID")

    # turns
    p_turns = sub.add_parser("turns", help="Fetch turns")
    p_turns.add_argument("--id", required=True, help="6-digit discussion ID")
    p_turns.add_argument("--after", type=int, default=0, help="Fetch turns after this turn number")

    # poll
    p_poll = sub.add_parser("poll", help="Poll for turn")
    p_poll.add_argument("--id", required=True, help="6-digit discussion ID")
    p_poll.add_argument("--agent", type=int, required=True, help="Agent seat number")
    p_poll.add_argument("--token", required=True, help="Seat capability token")
    p_poll.add_argument("--interval", type=float, default=5.0, help="Poll interval in seconds")
    p_poll.add_argument("--timeout", type=float, default=300.0, help="Max wait timeout in seconds")

    # send
    p_send = sub.add_parser("send", help="Send a turn")
    p_send.add_argument("--id", required=True, help="6-digit discussion ID")
    p_send.add_argument("--agent", type=int, required=True, help="Agent seat number")
    p_send.add_argument("--next-agent", type=int, required=True, help="Next agent seat number")
    p_send.add_argument("--token", required=True, help="Seat capability token")
    p_send.add_argument("--message", help="Inline message body")
    p_send.add_argument("--message-file", help="Path to message file (or - for stdin)")
    p_send.add_argument("--expected-turn", type=int, help="Expected current turn before write")
    p_send.add_argument("--idempotency-key", help="Optional idempotency key")

    # close
    p_close = sub.add_parser("close", help="Close discussion")
    p_close.add_argument("--id", required=True, help="6-digit discussion ID")
    p_close.add_argument("--agent", type=int, required=True, help="Agent seat number")
    p_close.add_argument("--token", required=True, help="Seat capability token")
    p_close.add_argument("--message", help="Inline close message")
    p_close.add_argument("--message-file", help="Path to close message file")
    p_close.add_argument("--trivial", action="store_true", help="Perform trivial administrative close")

    # heartbeat
    p_hb = sub.add_parser("heartbeat", help="Send heartbeat")
    p_hb.add_argument("--id", required=True, help="6-digit discussion ID")
    p_hb.add_argument("--agent", type=int, required=True, help="Agent seat number")
    p_hb.add_argument("--token", required=True, help="Seat capability token")

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    client = BridgeClient(
        base_url=args.url,
        cf_client_id=args.cf_client_id,
        cf_client_secret=args.cf_client_secret,
    )

    try:
        if args.command == "join":
            res = client.join(
                discussion_id=args.id,
                agent_number=args.agent,
                expect_subject=args.expect_subject,
                model=args.model,
            )
            print(json.dumps(res, indent=2))
        elif args.command == "status":
            res = client.status(discussion_id=args.id)
            print(json.dumps(res, indent=2))
        elif args.command == "turns":
            res = client.turns(discussion_id=args.id, after=args.after)
            print(json.dumps(res, indent=2))
        elif args.command == "poll":
            decision, st = client.poll_for_turn(
                discussion_id=args.id,
                agent_number=args.agent,
                token=args.token,
                interval=args.interval,
                timeout=args.timeout,
            )
            print(f"DECISION: {decision}")
            print(json.dumps(st, indent=2))
        elif args.command == "send":
            msg = load_text(args.message_file, args.message)
            res = client.send(
                discussion_id=args.id,
                agent_number=args.agent,
                next_agent_number=args.next_agent,
                message=msg,
                token=args.token,
                expected_turn=args.expected_turn,
                idempotency_key=args.idempotency_key,
            )
            print(json.dumps(res, indent=2))
        elif args.command == "close":
            msg = load_text(args.message_file, args.message) if not args.trivial else "Discussion closed."
            res = client.close(
                discussion_id=args.id,
                agent_number=args.agent,
                message=msg,
                token=args.token,
                trivial=args.trivial,
            )
            print(json.dumps(res, indent=2))
        elif args.command == "heartbeat":
            res = client.heartbeat(
                discussion_id=args.id,
                agent_number=args.agent,
                token=args.token,
            )
            print(json.dumps(res, indent=2))
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
