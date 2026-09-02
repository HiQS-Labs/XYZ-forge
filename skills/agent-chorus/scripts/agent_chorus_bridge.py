#!/usr/bin/env python3
"""Localhost HTTP bridge for AgentChorus over Cloudflare Tunnel (GH-384).

Provides a secure, localhost-only REST interface to AgentChorus discussions,
enabling cross-device participation while preserving single-writer locking,
canonical transcript storage, dual authentication, seat capability tokens,
and 10-minute idle leases.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import hmac
import http.server
import json
import os
from pathlib import Path
import re
import secrets
import signal
import socketserver
import subprocess
import sys
import threading
import time
import urllib.parse
from typing import Any, Dict, List, Optional, Tuple

# Ensure parent directory is in path so we can import agent_chorus
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import agent_chorus


DEFAULT_PORT = 8080
DEFAULT_IDLE_TIMEOUT = 600.0  # 10 minutes idle lease
DEFAULT_MAX_LIFETIME = 7200.0  # 2 hours maximum session duration
MAX_BODY_BYTES = 2 * 1024 * 1024  # 2 MB max payload size


class BridgeError(Exception):
    """Base error for bridge operations."""
    def __init__(self, message: str, status_code: int = 400, code: str = "bad_request"):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.code = code


class SessionExpiredError(BridgeError):
    def __init__(self, message: str = "discussion session has expired (idle lease or max lifetime exceeded)"):
        super().__init__(message, status_code=410, code="session_expired")


class UnauthorizedError(BridgeError):
    def __init__(self, message: str = "unauthorized"):
        super().__init__(message, status_code=401, code="unauthorized")


class ForbiddenError(BridgeError):
    def __init__(self, message: str = "forbidden"):
        super().__init__(message, status_code=403, code="forbidden")


class ConflictError(BridgeError):
    def __init__(self, message: str = "conflict"):
        super().__init__(message, status_code=409, code="conflict")


class NotFoundError(BridgeError):
    def __init__(self, message: str = "not found"):
        super().__init__(message, status_code=404, code="not_found")


def utc_now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def compute_transcript_hash(path: Path) -> str:
    try:
        content = path.read_bytes()
        return "sha256:" + hashlib.sha256(content).hexdigest()
    except OSError:
        return "sha256:unknown"


class BridgeSession:
    """Tracks remote session state, capability tokens, and idle lease for one discussion."""

    def __init__(
        self,
        discussion_id: str,
        root: Path,
        store: Optional[Path] = None,
        idle_timeout: float = DEFAULT_IDLE_TIMEOUT,
        max_lifetime: float = DEFAULT_MAX_LIFETIME,
    ):
        self.discussion_id = discussion_id
        self.root = root
        self.store = store
        self.idle_timeout = idle_timeout
        self.max_lifetime = max_lifetime
        self.created_mono = time.monotonic()
        self.last_activity_mono = time.monotonic()
        self.created_at = utc_now_iso()
        self.lock = threading.Lock()
        self.seat_tokens: Dict[str, str] = {}  # member (e.g. "agent2") -> token
        self.token_to_seat: Dict[str, str] = {}  # token -> member
        self.idempotency_cache: Dict[str, Dict[str, Any]] = {}
        self.is_closed = False

    @property
    def lease_expires_at(self) -> str:
        remaining_idle = max(0.0, self.idle_timeout - (time.monotonic() - self.last_activity_mono))
        remaining_max = max(0.0, self.max_lifetime - (time.monotonic() - self.created_mono))
        effective_remaining = min(remaining_idle, remaining_max)
        expiry_dt = dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=effective_remaining)
        return expiry_dt.replace(microsecond=0).isoformat()

    def touch(self) -> None:
        with self.lock:
            if self.is_expired_unlocked():
                raise SessionExpiredError()
            self.last_activity_mono = time.monotonic()

    def is_expired_unlocked(self) -> bool:
        if self.is_closed:
            return False
        now = time.monotonic()
        if (now - self.last_activity_mono) > self.idle_timeout:
            return True
        if (now - self.created_mono) > self.max_lifetime:
            return True
        return False

    def is_expired(self) -> bool:
        with self.lock:
            return self.is_expired_unlocked()

    def get_or_create_seat_token(self, member: str) -> str:
        with self.lock:
            if self.is_expired_unlocked():
                raise SessionExpiredError()
            token = self.seat_tokens.get(member)
            if not token:
                token = secrets.token_urlsafe(32)
                self.seat_tokens[member] = token
                self.token_to_seat[token] = member
            self.last_activity_mono = time.monotonic()
            return token

    def validate_seat_token(self, member: str, token: Optional[str]) -> None:
        with self.lock:
            if self.is_expired_unlocked():
                raise SessionExpiredError()
            if not token:
                raise UnauthorizedError("missing seat capability token in Authorization header")
            expected = self.seat_tokens.get(member)
            if not expected or not hmac.compare_digest(expected, token):
                raise ForbiddenError(f"invalid capability token for seat {member}")
            self.last_activity_mono = time.monotonic()

    def revoke_all(self) -> None:
        with self.lock:
            self.seat_tokens.clear()
            self.token_to_seat.clear()
            self.is_closed = True


class BridgeManager:
    """Manages active bridge sessions and authentication policies."""

    def __init__(
        self,
        root: Path,
        store: Optional[Path] = None,
        cf_client_id: Optional[str] = None,
        cf_client_secret: Optional[str] = None,
        idle_timeout: float = DEFAULT_IDLE_TIMEOUT,
        max_lifetime: float = DEFAULT_MAX_LIFETIME,
    ):
        self.root = root
        self.store = store
        if self.store:
            agent_chorus.ACTIVE_STORE = self.store
            os.environ["AGENT2AGENT_HOME"] = str(self.store)
        self.cf_client_id = cf_client_id or os.environ.get("CF_ACCESS_CLIENT_ID")
        self.cf_client_secret = cf_client_secret or os.environ.get("CF_ACCESS_CLIENT_SECRET")
        self.idle_timeout = idle_timeout
        self.max_lifetime = max_lifetime
        self.sessions: Dict[str, BridgeSession] = {}
        self.lock = threading.Lock()

    def validate_cf_access(self, headers: Dict[str, str]) -> None:
        if not self.cf_client_id and not self.cf_client_secret:
            return  # Cloudflare Access not configured/required
        client_id = headers.get("cf-access-client-id") or headers.get("CF-Access-Client-Id")
        client_secret = headers.get("cf-access-client-secret") or headers.get("CF-Access-Client-Secret")
        if not client_id or not client_secret:
            raise UnauthorizedError("missing Cloudflare Access service token headers")
        id_ok = hmac.compare_digest(self.cf_client_id or "", client_id)
        secret_ok = hmac.compare_digest(self.cf_client_secret or "", client_secret)
        if not (id_ok and secret_ok):
            raise UnauthorizedError("invalid Cloudflare Access service token")

    def get_or_create_session(self, discussion_id: str) -> BridgeSession:
        with self.lock:
            if self.store:
                agent_chorus.ACTIVE_STORE = self.store
            session = self.sessions.get(discussion_id)
            if session is None:
                # Validate discussion exists in storage
                agent_chorus.resolve_discussion(self.root, discussion_id, self.store)
                session = BridgeSession(
                    discussion_id=discussion_id,
                    root=self.root,
                    store=self.store,
                    idle_timeout=self.idle_timeout,
                    max_lifetime=self.max_lifetime,
                )
                self.sessions[discussion_id] = session
            elif session.is_expired():
                # Reopen session if active in transcript
                path = agent_chorus.resolve_discussion(self.root, discussion_id, self.store)
                content = agent_chorus.read_discussion(path)
                if agent_chorus.field(content, "STATUS").lower() != "closed":
                    session = BridgeSession(
                        discussion_id=discussion_id,
                        root=self.root,
                        store=self.store,
                        idle_timeout=self.idle_timeout,
                        max_lifetime=self.max_lifetime,
                    )
                    self.sessions[discussion_id] = session
                else:
                    raise SessionExpiredError()
            return session

    def get_session(self, discussion_id: str) -> BridgeSession:
        with self.lock:
            if self.store:
                agent_chorus.ACTIVE_STORE = self.store
            session = self.sessions.get(discussion_id)
            if session is None:
                try:
                    agent_chorus.resolve_discussion(self.root, discussion_id, self.store)
                    session = BridgeSession(
                        discussion_id=discussion_id,
                        root=self.root,
                        store=self.store,
                        idle_timeout=self.idle_timeout,
                        max_lifetime=self.max_lifetime,
                    )
                    self.sessions[discussion_id] = session
                except agent_chorus.Agent2AgentError as exc:
                    raise NotFoundError(f"discussion #{discussion_id} not found: {exc}")
            if session.is_expired():
                raise SessionExpiredError()
            return session


class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


class BridgeRequestHandler(http.server.BaseHTTPRequestHandler):
    """Processes AgentChorus Bridge HTTP REST requests."""

    server: ThreadingHTTPServer

    @property
    def manager(self) -> BridgeManager:
        return getattr(self.server, "bridge_manager")

    def log_message(self, format: str, *args: Any) -> None:
        """Sanitized logging: never log authorization tokens or request payloads."""
        ts = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
        sys.stderr.write(f"[{ts}] [agent-chorus-bridge] {self.address_string()} - {format % args}\n")

    def _send_json(self, status_code: int, data: Dict[str, Any]) -> None:
        body = json.dumps(data, indent=2, sort_keys=True).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.end_headers()
        self.wfile.write(body)

    def _send_error(self, exc: Exception) -> None:
        if isinstance(exc, BridgeError):
            self._send_json(exc.status_code, {"error": exc.message, "code": exc.code})
        elif isinstance(exc, agent_chorus.Agent2AgentError):
            msg = str(exc)
            if "out of turn" in msg or "locked by another writer" in msg:
                self._send_json(409, {"error": msg, "code": "conflict"})
            elif "closed" in msg:
                self._send_json(410, {"error": msg, "code": "closed"})
            else:
                self._send_json(400, {"error": msg, "code": "bad_request"})
        else:
            self.log_message("Internal server error: %s", exc)
            self._send_json(500, {"error": "internal server error", "code": "internal_error"})

    def _read_json_body(self) -> Dict[str, Any]:
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length > MAX_BODY_BYTES:
            raise BridgeError("request body exceeds maximum allowed size (2MB)", status_code=413, code="payload_too_large")
        if content_length == 0:
            return {}
        try:
            raw_body = self.rfile.read(content_length)
            return json.loads(raw_body.decode("utf-8"))
        except (ValueError, UnicodeDecodeError) as exc:
            raise BridgeError(f"malformed JSON body: {exc}", status_code=400, code="bad_json")

    def _get_bearer_token(self) -> Optional[str]:
        auth_header = self.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            return auth_header[7:].strip()
        seat_token = self.headers.get("X-Seat-Token")
        if seat_token:
            return seat_token.strip()
        return None

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Allow", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Seat-Token, CF-Access-Client-Id, CF-Access-Client-Secret")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self) -> None:
        try:
            self.manager.validate_cf_access(dict(self.headers))
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path.rstrip("/")
            query = urllib.parse.parse_qs(parsed.query)

            # Route: GET /
            if path == "" or path == "/":
                self._send_json(200, {
                    "service": "agent-chorus-bridge",
                    "status": "online",
                    "version": "1.0.0",
                    "time": utc_now_iso(),
                })
                return

            # Route: GET /sessions/<id>/status
            status_match = re.match(r"^/sessions/([0-9]{6})/status$", path)
            if status_match:
                discussion_id = status_match.group(1)
                session = self.manager.get_session(discussion_id)
                session.touch()
                disc_path = agent_chorus.resolve_discussion(session.root, discussion_id, session.store)
                content = agent_chorus.read_discussion(disc_path)
                status_text = agent_chorus.field(content, "STATUS")
                roster = agent_chorus.parse_roster(content)
                next_member = agent_chorus.field(content, "NEXT")
                turn_count = int(agent_chorus.field(content, "TURN"))
                subject = agent_chorus.field(content, "SUBJECT")
                updated = agent_chorus.field(content, "UPDATED")
                
                self._send_json(200, {
                    "id": discussion_id,
                    "subject": subject,
                    "status": status_text,
                    "agents": roster,
                    "current_turn": turn_count,
                    "next": next_member,
                    "updated": updated,
                    "active": status_text.lower() != "closed" and not session.is_expired(),
                    "lease_expires_at": session.lease_expires_at,
                    "transcript_hash": compute_transcript_hash(disc_path),
                })
                return

            # Route: GET /sessions/<id>/turns
            turns_match = re.match(r"^/sessions/([0-9]{6})/turns$", path)
            if turns_match:
                discussion_id = turns_match.group(1)
                session = self.manager.get_session(discussion_id)
                session.touch()
                disc_path = agent_chorus.resolve_discussion(session.root, discussion_id, session.store)
                content = agent_chorus.read_discussion(disc_path)
                
                after_turn = 0
                if "after" in query and query["after"][0].isdigit():
                    after_turn = int(query["after"][0])
                
                limit = 100
                if "limit" in query and query["limit"][0].isdigit():
                    limit = min(500, int(query["limit"][0]))
                
                raw_turns = agent_chorus.parse_turns(content)
                filtered = [
                    {"turn": t_num, "author": member, "timestamp": ts, "body": body}
                    for (t_num, member, ts, body) in raw_turns
                    if t_num > after_turn
                ][:limit]

                self._send_json(200, {
                    "id": discussion_id,
                    "current_turn": int(agent_chorus.field(content, "TURN")),
                    "status": agent_chorus.field(content, "STATUS"),
                    "next": agent_chorus.field(content, "NEXT"),
                    "turns": filtered,
                    "count": len(filtered),
                    "lease_expires_at": session.lease_expires_at,
                })
                return

            raise NotFoundError(f"endpoint not found: GET {path}")
        except Exception as exc:
            self._send_error(exc)

    def do_POST(self) -> None:
        try:
            self.manager.validate_cf_access(dict(self.headers))
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path.rstrip("/")
            body = self._read_json_body()

            # Route: POST /sessions
            if path == "/sessions":
                disc_id = body.get("id")
                if disc_id:
                    if not re.match(r"^[0-9]{6}$", str(disc_id)):
                        raise BridgeError("id must be a 6-digit number", code="invalid_id")
                    session = self.manager.get_or_create_session(str(disc_id))
                    disc_path = agent_chorus.resolve_discussion(session.root, str(disc_id), session.store)
                    content = agent_chorus.read_discussion(disc_path)
                else:
                    subject = body.get("subject")
                    if not subject:
                        raise BridgeError("subject is required to start a new discussion", code="missing_subject")
                    packet = body.get("packet")
                    if not packet:
                        raise BridgeError("packet is required to start a new discussion", code="missing_packet")
                    agent_count = int(body.get("agents", 2))
                    timed_watch = bool(body.get("timed_watch", False))
                    supersedes = body.get("supersedes")
                    explicit_id = body.get("explicit_id")

                    validated_packet = agent_chorus.validate_context_packet(packet)
                    disc_id, disc_path = agent_chorus.create_discussion(
                        root=self.manager.root,
                        subject=subject,
                        agents=agent_count,
                        explicit_id=explicit_id,
                        timed_watch=timed_watch,
                        context_packet=validated_packet,
                        store=self.manager.store,
                        supersedes=supersedes,
                    )
                    session = self.manager.get_or_create_session(disc_id)
                    content = agent_chorus.read_discussion(disc_path)

                norm_subject = agent_chorus.field(content, "SUBJECT")
                roster = agent_chorus.parse_roster(content)
                timed_w = agent_chorus.timed_watch_enabled(content)
                invitations = [
                    agent_chorus.invitation(disc_id, num, norm_subject, timed_w)
                    for num in range(2, len(roster) + 1)
                ]

                self._send_json(201, {
                    "id": disc_id,
                    "subject": norm_subject,
                    "agents": roster,
                    "status": agent_chorus.field(content, "STATUS"),
                    "turn": int(agent_chorus.field(content, "TURN")),
                    "next": agent_chorus.field(content, "NEXT"),
                    "relay_file": str(disc_path),
                    "invitations": invitations,
                    "session_created_at": session.created_at,
                    "lease_expires_at": session.lease_expires_at,
                })
                return

            # Route: POST /sessions/<id>/join
            join_match = re.match(r"^/sessions/([0-9]{6})/join$", path)
            if join_match:
                discussion_id = join_match.group(1)
                session = self.manager.get_session(discussion_id)
                agent_num = body.get("agent")
                if agent_num is None:
                    raise BridgeError("agent number is required", code="missing_agent")
                try:
                    agent_num_int = int(agent_num)
                except ValueError:
                    raise BridgeError("agent must be an integer", code="invalid_agent")

                expect_subject = body.get("expect_subject")
                model = body.get("model")

                disc_path, subject, next_member, decision = agent_chorus.join_discussion(
                    session.root, discussion_id, agent_num_int, expect_subject
                )
                member = agent_chorus.agent_id(agent_num_int)
                token = session.get_or_create_seat_token(member)
                content = agent_chorus.read_discussion(disc_path)

                if agent_chorus.telemetry_enabled():
                    agent_chorus.emit_telemetry(
                        disc_path, "seat_joined", agent=member, decision=decision, model=model
                    )

                self._send_json(200, {
                    "id": discussion_id,
                    "agent": member,
                    "agent_number": agent_num_int,
                    "subject": subject,
                    "decision": decision,
                    "next": next_member,
                    "turn": int(agent_chorus.field(content, "TURN")),
                    "peer_doorbells": agent_chorus.participation_lines(content, agent_num_int, closing=False),
                    "capability_token": token,
                    "lease_expires_at": session.lease_expires_at,
                })
                return

            # Route: POST /sessions/<id>/send
            send_match = re.match(r"^/sessions/([0-9]{6})/send$", path)
            if send_match:
                discussion_id = send_match.group(1)
                session = self.manager.get_session(discussion_id)
                agent_num = body.get("agent")
                if agent_num is None:
                    raise BridgeError("agent is required", code="missing_agent")
                agent_num_int = int(agent_num)
                member = agent_chorus.agent_id(agent_num_int)

                # Validate Seat Capability Token
                token = self._get_bearer_token()
                session.validate_seat_token(member, token)

                next_agent = body.get("next_agent")
                if next_agent is None:
                    raise BridgeError("next_agent is required", code="missing_next_agent")
                next_agent_int = int(next_agent)

                message = body.get("message")
                if not message or not str(message).strip():
                    raise BridgeError("message must not be empty", code="empty_message")
                norm_message = agent_chorus.normalize_message(str(message))

                # Idempotency / Expected version check
                idempotency_key = body.get("idempotency_key")
                expected_turn = body.get("expected_turn")

                disc_path = agent_chorus.resolve_discussion(session.root, discussion_id, session.store)
                current_content = agent_chorus.read_discussion(disc_path)
                current_turn = int(agent_chorus.field(current_content, "TURN"))

                if idempotency_key and idempotency_key in session.idempotency_cache:
                    cached = session.idempotency_cache[idempotency_key]
                    self._send_json(200, cached)
                    return

                if expected_turn is not None:
                    expected_turn_int = int(expected_turn)
                    if expected_turn_int != current_turn:
                        # Check if this was an immediate duplicate retry of the just-committed turn
                        authors = agent_chorus.turn_authors(current_content)
                        if authors.get(current_turn) == member and current_turn == expected_turn_int + 1:
                            cached_receipt = session.idempotency_cache.get(f"turn-{current_turn}")
                            if cached_receipt:
                                self._send_json(200, cached_receipt)
                                return
                        raise ConflictError(
                            f"stale turn version: discussion is at turn {current_turn}, expected {expected_turn_int}"
                        )

                # Verified git handoff check if requested
                check_clean = bool(body.get("check_clean", False))
                receipt_git = agent_chorus.verify_git_handoff(session.root) if check_clean else None

                disc_path, committed_turn, next_member, subject = agent_chorus.append_turn(
                    root=session.root,
                    discussion_id=discussion_id,
                    number=agent_num_int,
                    message=norm_message,
                    next_number=next_agent_int,
                    close=False,
                )

                cites, _ = agent_chorus._citation_counts(norm_message)
                after_content = agent_chorus.read_discussion(disc_path)
                tx_hash = compute_transcript_hash(disc_path)

                receipt = {
                    "id": discussion_id,
                    "turn": committed_turn,
                    "author": member,
                    "next": next_member,
                    "bytes": len(norm_message.encode("utf-8")),
                    "citations": cites,
                    "transcript_hash": tx_hash,
                    "timestamp": utc_now_iso(),
                }
                if receipt_git:
                    receipt["verified_git"] = receipt_git

                response_payload = {
                    "receipt": receipt,
                    "decision": "wait",
                    "next_invitation": agent_chorus.invitation(
                        discussion_id, next_agent_int, subject, agent_chorus.timed_watch_enabled(after_content)
                    ),
                    "lease_expires_at": session.lease_expires_at,
                }

                # Save to idempotency cache
                if idempotency_key:
                    session.idempotency_cache[idempotency_key] = response_payload
                session.idempotency_cache[f"turn-{committed_turn}"] = response_payload

                self._send_json(200, response_payload)
                return

            # Route: POST /sessions/<id>/close
            close_match = re.match(r"^/sessions/([0-9]{6})/close$", path)
            if close_match:
                discussion_id = close_match.group(1)
                session = self.manager.get_session(discussion_id)
                agent_num = body.get("agent")
                if agent_num is None:
                    raise BridgeError("agent is required", code="missing_agent")
                agent_num_int = int(agent_num)
                member = agent_chorus.agent_id(agent_num_int)

                # Validate Seat Capability Token
                token = self._get_bearer_token()
                session.validate_seat_token(member, token)

                message = body.get("message")
                if not message or not str(message).strip():
                    raise BridgeError("close message must not be empty", code="empty_message")
                norm_message = agent_chorus.normalize_message(str(message))

                trivial = bool(body.get("trivial", False))
                if not trivial:
                    agent_chorus.validate_structured_close(norm_message)

                check_clean = bool(body.get("check_clean", False))
                receipt_git = agent_chorus.verify_git_handoff(session.root) if check_clean else None

                disc_path, committed_turn, _, _ = agent_chorus.append_turn(
                    root=session.root,
                    discussion_id=discussion_id,
                    number=agent_num_int,
                    message=norm_message,
                    next_number=None,
                    close=True,
                )

                session.revoke_all()

                self._send_json(200, {
                    "receipt": {
                        "id": discussion_id,
                        "turn": committed_turn,
                        "author": member,
                        "status": "Closed",
                        "transcript_hash": compute_transcript_hash(disc_path),
                        "timestamp": utc_now_iso(),
                    },
                    "decision": "closed",
                    "status": "Closed",
                })
                return

            # Route: POST /sessions/<id>/heartbeat
            ping_match = re.match(r"^/sessions/([0-9]{6})/(?:heartbeat|ping)$", path)
            if ping_match:
                discussion_id = ping_match.group(1)
                session = self.manager.get_session(discussion_id)
                agent_num = body.get("agent")
                if agent_num is None:
                    raise BridgeError("agent is required", code="missing_agent")
                agent_num_int = int(agent_num)
                member = agent_chorus.agent_id(agent_num_int)

                token = self._get_bearer_token()
                session.validate_seat_token(member, token)

                agent_chorus.ping_discussion(session.root, discussion_id, agent_num_int)
                session.touch()

                self._send_json(200, {
                    "status": "ok",
                    "id": discussion_id,
                    "agent": member,
                    "lease_expires_at": session.lease_expires_at,
                })
                return

            raise NotFoundError(f"endpoint not found: POST {path}")
        except Exception as exc:
            self._send_error(exc)


def start_bridge_server(
    host: str = "127.0.0.1",
    port: int = DEFAULT_PORT,
    root: Optional[Path] = None,
    store: Optional[Path] = None,
    cf_client_id: Optional[str] = None,
    cf_client_secret: Optional[str] = None,
    idle_timeout: float = DEFAULT_IDLE_TIMEOUT,
    max_lifetime: float = DEFAULT_MAX_LIFETIME,
) -> Tuple[ThreadingHTTPServer, int]:
    """Start the bridge server in a background thread or return the server instance."""
    resolved_root = agent_chorus.normalize_root(str(root) if root else None)
    resolved_store = agent_chorus.normalize_store(resolved_root, str(store) if store else None)
    agent_chorus.ACTIVE_STORE = resolved_store
    os.environ["AGENT2AGENT_HOME"] = str(resolved_store)

    manager = BridgeManager(
        root=resolved_root,
        store=resolved_store,
        cf_client_id=cf_client_id,
        cf_client_secret=cf_client_secret,
        idle_timeout=idle_timeout,
        max_lifetime=max_lifetime,
    )
    server = ThreadingHTTPServer((host, port), BridgeRequestHandler)
    setattr(server, "bridge_manager", manager)
    actual_port = server.server_address[1]
    return server, actual_port


def launch_quick_tunnel(port: int) -> subprocess.Popen:
    """Launch cloudflared quick tunnel and wait for public trycloudflare.com URL."""
    try:
        proc = subprocess.Popen(
            ["cloudflared", "tunnel", "--url", f"http://127.0.0.1:{port}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
    except FileNotFoundError:
        raise BridgeError("cloudflared executable not found on PATH. Install cloudflared to use --tunnel.")

    # Read stderr to extract the quick tunnel URL
    public_url = None
    start = time.monotonic()
    while time.monotonic() - start < 15.0 and proc.poll() is None:
        line = proc.stderr.readline()
        if not line:
            time.sleep(0.1)
            continue
        match = re.search(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com", line)
        if match:
            public_url = match.group(0)
            break

    if not public_url:
        proc.kill()
        raise BridgeError("failed to obtain Quick Tunnel URL from cloudflared within 15 seconds")

    print(f"Cloudflare Quick Tunnel established: {public_url}")
    print(f"Forwarding to: http://127.0.0.1:{port}")
    return proc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AgentChorus Localhost HTTP Bridge")
    parser.add_argument("--host", default="127.0.0.1", help="Host address to bind to (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Port to bind to (default: 8080)")
    parser.add_argument("--root", help="Repository root path")
    parser.add_argument("--store", help="Session store directory path")
    parser.add_argument("--idle-timeout", type=float, default=DEFAULT_IDLE_TIMEOUT, help="Idle lease timeout in seconds (default: 600)")
    parser.add_argument("--max-lifetime", type=float, default=DEFAULT_MAX_LIFETIME, help="Max session lifetime in seconds (default: 7200)")
    parser.add_argument("--cf-client-id", help="Required Cloudflare Access Client ID")
    parser.add_argument("--cf-client-secret", help="Required Cloudflare Access Client Secret")
    parser.add_argument("--tunnel", action="store_true", help="Launch cloudflared Quick Tunnel")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server, actual_port = start_bridge_server(
        host=args.host,
        port=args.port,
        root=Path(args.root) if args.root else None,
        store=Path(args.store) if args.store else None,
        cf_client_id=args.cf_client_id,
        cf_client_secret=args.cf_client_secret,
        idle_timeout=args.idle_timeout,
        max_lifetime=args.max_lifetime,
    )

    tunnel_proc = None
    if args.tunnel:
        try:
            tunnel_proc = launch_quick_tunnel(actual_port)
        except BridgeError as exc:
            print(f"warning: could not launch quick tunnel ({exc}); continuing localhost only", file=sys.stderr)

    print(f"AgentChorus Bridge listening on http://{args.host}:{actual_port}")
    print(f"Idle lease: {args.idle_timeout}s | Max lifetime: {args.max_lifetime}s")
    if args.cf_client_id:
        print("Cloudflare Access authentication: ENABLED")

    def handle_sig(sig, frame):
        if tunnel_proc:
            try:
                tunnel_proc.terminate()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_sig)
    signal.signal(signal.SIGTERM, handle_sig)

    try:
        server.serve_forever()
    finally:
        server.server_close()
        if tunnel_proc:
            tunnel_proc.terminate()
    return 0


if __name__ == "__main__":
    sys.exit(main())
