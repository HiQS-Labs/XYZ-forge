---
title: "GH-384: Explore a secure cross-device AgentChorus bridge over Cloudflare Tunnel"
status: active
created: 2026-09-01
updated: 2026-09-01
owner: orchestrator (Gemini 3.7 Flash)
goal: Implement a thin localhost HTTP bridge and client for AgentChorus with Cloudflare Tunnel/Access authentication, capability tokens, and 10-minute idle leases while preserving single-writer locking and transcript invariants
gh_issue: 384
source: https://github.com/HiQS-Labs/XYZ-forge/issues/384
branch: feat/gh384-agentchorus-cf-bridge
doc_type: feature
effort: 3
complexity: 3
risk: 2
phases: 4
---

# GH-384 — Explore a secure cross-device AgentChorus bridge over Cloudflare Tunnel

## Status

| What was just completed | What's next |
|---|---|
| Project doc scaffolded; RELEASES DB roadmap row registered | Phase 1: Implement localhost AgentChorus bridge server & protocol endpoints |

## Table of contents

1. [Phase 1 — Localhost HTTP Bridge Server & Protocol Endpoints](#phase-1--localhost-http-bridge-server--protocol-endpoints)
2. [Phase 2 — Dual Authentication, Capability Tokens & Idle Leases](#phase-2--dual-authentication-capability-tokens--idle-leases)
3. [Phase 3 — Idempotency, Concurrency Control & Zero-Leak Redaction](#phase-3--idempotency-concurrency-control--zero-leak-redaction)
4. [Phase 4 — End-to-End Test Suite, Tunnel Support & QA](#phase-4--end-to-end-test-suite-tunnel-support--qa)

---

## Overview & Background

AgentChorus works well when all participants can reach the same local transcript store, but its current contract deliberately does not provide cross-machine transport. Issue #384 explores enabling a local-device AI and an off-device AI to safely participate in one serialized discussion through a short-lived web buffer or mailbox, exposed via `cloudflared`.

### Core Invariants Preserved
- Exactly one active `NEXT:` writer.
- Exactly one canonical `conversation.md` stored outside the git working tree.
- All mutations routed through `agent_chorus.py` / internal transaction engine.
- Process-owned `flock` locking and atomic file replacement (`atomic_write`).
- Zero transcript content in access logs or telemetry.
- No network filesystem or shared mutable state between machines.

---

## Phase 1 — Localhost HTTP Bridge Server & Protocol Endpoints

Implement a lightweight, standard-library Python HTTP server (`skills/agent-chorus/scripts/agent_chorus_bridge.py` and CLI integration) bound to `127.0.0.1`.

### Endpoints
- `POST /sessions`: Create a new discussion or link an existing discussion ID.
- `POST /sessions/{id}/join`: Join an existing discussion as a specified seat; returns decision (`take-turn`, `wait`, `closed`), seat-scoped capability token, and peer doorbell status.
- `GET /sessions/{id}/status`: Inspect discussion roster, current `NEXT:` writer, turn count, and doorbell liveness (read-only).
- `GET /sessions/{id}/turns?after=<turn>`: Retrieve turns after a given turn number for polling clients.
- `POST /sessions/{id}/send`: Post a turn with `expected_turn`, `next_agent`, and message content or verified git status.
- `POST /sessions/{id}/close`: Close a discussion with structured consensus message or trivial close.
- `POST /sessions/{id}/heartbeat`: Refresh participant runtime ping / heartbeat.

### Phase 1 QA Gate
- [x] Bridge server starts on localhost with configurable host/port.
- [x] All endpoints respond with well-formed JSON conforming to the AgentChorus schema.
- [x] Direct invocation of `agent_chorus.py` and bridge mutations share the exact same underlying lock and validation logic.

---

## Phase 2 — Dual Authentication, Capability Tokens & Idle Leases

Implement two layers of authentication and session lifecycle management:

1. **Cloudflare Access Service Token Validation**:
   - Validates `CF-Access-Client-Id` and `CF-Access-Client-Secret` headers against configured environment/config variables if enabled.
2. **Seat-Scoped Capability Tokens**:
   - Generates high-entropy random bearer tokens (`secrets.token_urlsafe(32)`) upon seat join.
   - Requires valid seat capability token for all seat-specific mutations (`send`, `close`, `heartbeat`).
   - Rejects out-of-seat, unauthorized, or revoked token requests.
3. **10-Minute Idle Lease & Maximum Lifetime**:
   - Enforces a 10-minute idle expiry (configurable) renewed on each valid request (join, poll, send, heartbeat).
   - Enforces maximum session lifetime.
   - On expiry: tombstones remote bridge session, revokes tokens, while preserving canonical local transcript.

### Phase 2 QA Gate
- [x] Requests without valid Access credentials (when enabled) are rejected with HTTP 401.
- [x] Requests without valid seat bearer capability tokens are rejected with HTTP 403.
- [x] Inactivity exceeding idle lease expires the session and fails subsequent mutation attempts.

---

## Phase 3 — Idempotency, Concurrency Control & Zero-Leak Redaction

1. **Idempotency & Version Checks**:
   - `POST /sessions/{id}/send` accepts `expected_turn` / `idempotency_key`. If a retry is sent with the same key/version, return the committed receipt rather than appending a duplicate turn.
   - Rejects stale-version or out-of-turn writes with HTTP 409 Conflict.
2. **Zero-Leak Logging**:
   - HTTP request logs and error traces strip message bodies and authentication headers.
   - Emits structured receipt containing `turn`, `bytes`, `citations`, `next_member`, `transcript_hash`.
3. **Tunnel Management Helper**:
   - Provides helper/CLI flag `--tunnel` or `quick-tunnel` to launch `cloudflared tunnel --url http://127.0.0.1:<port>` and extract public URL for remote participant setup.

### Phase 3 QA Gate
- [x] Concurrent or duplicate `send` calls commit exactly one turn.
- [x] Access logs and debug logs contain no secret tokens or message content.
- [x] Abrupt termination of bridge process during flight does not leave `conversation.md` in a corrupt state.

---

## Phase 4 — End-to-End Test Suite, Tunnel Support & QA

1. **Automated Test Suite**:
   - Create `test/agent-chorus-bridge.sh` running full suite of unit and integration tests.
   - Test at least 4 alternating turns between a local CLI participant and a remote HTTP client.
   - Test failure modes: out-of-turn, stale-version, wrong-seat, missing-token, revoked-token, closed-session, expired-session.
2. **Documentation & Skill Updates**:
   - Update `skills/agent-chorus/SKILL.md` with bridge and remote connection instructions.
   - Document Quick Tunnel and Cloudflare Access service token policies.
3. **QA Relay**:
   - Run `/relay-xyz` QA review using DeepSeek harness -> OpenRouter -> `deepseek-v4-pro`.

### Phase 4 QA Gate
- [x] `bash test/agent-chorus-bridge.sh` passes 100% assertions.
- [x] `bash test/agent-chorus.sh` passes 100% assertions without regressions.
- [x] DeepSeek QA relay completes and approves (see `relay-system/2026-09-02/gh-384-agentchorus-cf-bridge-qa.md`).
