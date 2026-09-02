---
Goal: QA Cross-Device AgentChorus Bridge over Cloudflare Tunnel (GH-384)
Date: 2026-09-02
NEXT: Producer
STATUS: Open
---

# Context

Adjudicate the implementation of Cross-Device AgentChorus Bridge over Cloudflare Tunnel (GH-384) against its requirements and invariants specified in `PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md`.

Read the project doc in full, plus the implementation and test files:
- `PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md`
- `skills/agent-chorus/scripts/agent_chorus_bridge.py`
- `skills/agent-chorus/scripts/agent_chorus_client.py`
- `skills/agent-chorus/scripts/agent_chorus.py`
- `skills/agent-chorus/SKILL.md`
- `test/agent-chorus-bridge.sh`

Questions:

1. **Locking & Single-Writer Invariant**: Does `agent_chorus_bridge.py` route all mutation operations through `agent_chorus.py` / `DiscussionLock` (`flock`) and `atomic_write`, guaranteeing zero concurrency race conditions?
2. **Dual Authentication & Capability Scoping**: Are Cloudflare Access headers (`CF-Access-Client-Id` / `CF-Access-Client-Secret`) and seat capability tokens (`secrets.token_urlsafe(32)`) properly scoped and validated for each seat?
3. **Lease Lifecycle & Expiry**: Does the 10-minute idle lease expire inactive sessions cleanly without corrupting the local canonical `conversation.md` file?
4. **Zero-Leak Redaction**: Do access logs and error handlers strictly omit authorization tokens and message bodies?
5. **AST Compatibility & Test Coverage**: Are `agent_chorus_bridge.py` and `agent_chorus_client.py` compatible with Python 3.8 AST, and does `test/agent-chorus-bridge.sh` cover all required failure modes and happy paths?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line where you disagree with a specific claim.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Round 1 · Reviewer · deepseek

**Review:** Cross-Device AgentChorus Bridge over Cloudflare Tunnel (GH-384)

**Preliminary finding — the referenced implementation does not exist in this working tree.** 
Every file this QA task asks me to review is absent:

| Referenced path | Status |
|---|---|
| `PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md` | **NOT FOUND** — no file matching this pattern under `PROJECT/2-WORKING/` |
| `skills/agent-chorus/scripts/agent_chorus_bridge.py` | **NOT FOUND** — only `agent_chorus.py` and the legacy `agent2agent.py` shim exist in that directory |
| `skills/agent-chorus/scripts/agent_chorus_client.py` | **NOT FOUND** — same as above |
| `test/agent-chorus-bridge.sh` | **NOT FOUND** — only `test/agent-chorus.sh` exists (GH-497/GH-510/GH-144, the existing AgentChorus discussion test, which covers local file-based protocol only) |

The only GH-384 content in this repository is entirely unrelated: `GH-384` in this repo refers to the **marathon crash recovery** feature (see `test/baselines/GH-384-negative-control.md`, `marathon-system/nightwatch-wave-3-2026-08-11--gh384-crash-recovery/RELAY.md`, and `CHANGELOG.md` line 613). There is no GH-384 issue, branch, project doc, or implementation about an AgentChorus Cloudflare Tunnel Bridge.

**Existing `agent_chorus.py` lacks any networking or cross-device transport.**

Reviewing the code that DOES exist:

1. **Locking & Single-Writer Invariant (Q1):** The existing `agent_chorus.py` correctly implements the invariant. `DiscussionLock` (`agent_chorus.py:1045-1099`) uses `flock` with `LOCK_EX | LOCK_NB` on a lock file in `runtime/discussion.lock`, and `append_turn` at line 1762 acquires it before every write. `atomic_write` (`agent_chorus.py:842-857`) uses `tempfile.mkstemp` + `os.replace` + `_fsync_dir` for crash-safe atomic replacement. This is sound for the local-only protocol. There is, however, **no bridge code** that could route these operations over a network, so the question "does the bridge route through DiscussionLock" is unanswerable — the bridge does not exist.

2. **Dual Authentication & Capability Scoping (Q2):** Zero references to `CF-Access-Client-Id`, `CF-Access-Client-Secret`, `secrets.token_urlsafe`, capability tokens, or any authentication/authorization mechanism exist in `agent_chorus.py`. A search across the entire source tree confirms no file contains these strings. The existing protocol has no authentication layer because it operates on local files — access is governed by filesystem permissions.

3. **Lease Lifecycle & Expiry (Q3):** No 10-minute idle lease exists in the codebase. The existing `wait_for_turn` (line 1209) uses a configurable `timeout` parameter (defaulting to 0 = indefinite), and `stale_after` defaults to 1800 seconds (30 minutes, line 29). There is no lease/expiry mechanism and no network-session concept.

4. **Zero-Leak Redaction (Q4):** The existing telemetry framework (`emit_telemetry`, `TELEMETRY_EVENT_FIELDS`, `telemetry_audit`) is well-designed with a strict field allowlist and a comparator audit that proves no transcript content leaks into telemetry (validated by `test/agent-chorus.sh:748-749`). However, this covers telemetry only — there are no access logs or error handlers relating to a network bridge to audit.

5. **AST Compatibility (Q5):** The existing `agent_chorus.py` uses only Python 3.8-compatible syntax (confirmed by the AST check at `test/agent-chorus.sh:61-63` which passes). Since `agent_chorus_bridge.py` and `agent_chorus_client.py` do not exist, their AST compatibility cannot be assessed. The test `test/agent-chorus-bridge.sh` does not exist either; the existing `test/agent-chorus.sh` covers the local protocol well (822+ lines, thorough coverage of locking, drive, watch, telemetry, supersession, etc.) but has nothing related to bridging, Cloudflare, or cross-device transport.

**Verdict:** The implementation this QA task purports to review does not exist in the working tree. The QA task references a `GH-384` that in this repo means something else entirely (marathon crash recovery). No Cloudflare Tunnel bridge, no cross-device transport, no bridge client/server code, and no bridge test file exists. The QA task cannot proceed as written.

**Recommended action:** Either (a) this QA task was filed against the wrong repo (the Cloudflare bridge may live in a separate repository that shares the GH-384 issue number), or (b) the referenced files need to be created before a review can take place. Set NEXT to the appropriate producer for follow-up.
