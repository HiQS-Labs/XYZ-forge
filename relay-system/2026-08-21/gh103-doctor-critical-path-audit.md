# Relay: Audit of Rebalance OS Doctor Critical Path Coverage (GH-103)
STATUS: Approved
NEXT: done (verdict: Approved — advisories A1–D3 recorded below, non-blocking, for implementer reference)

<!-- relay-drive: task=RELAY-GH103-DOCTOR-AUDIT producer=claude reviewer=aider round-cap=4 -->

## Phase Brief

Audit the diagnosis and remediation specification filed in [HiQS-Suite/rebalanceOS#103](https://github.com/HiQS-Suite/rebalanceOS/issues/103) regarding critical path gaps in `src/rebalance/doctor.py`.

### Context & Diagnosis Under Review

`rebalance doctor` contains 27 check categories, but an architectural review identified 4 critical runtime blind spots:

1. **Exit Code `0` vs. Delivery Verification (Silent Skips):**
   - Doctor checks process exit codes (`launchctl list` returncode `0`), but not whether target artifacts were created/updated.
   - *Incident:* `daily-synthesis` and `obsidian-rollover` aborted on missing vault env vars, logged skips, and exited `0`. Doctor reported `OK`, masking zero notes written.

2. **Static Token Presence vs. Live API Quota & Rate Limit Exhaustion:**
   - Doctor checks token existence in keyring/secret store and reports `auth log: OK (0 active auth failures)`. It does not monitor external API quota burn (`x-ratelimit-remaining == 0` on GitHub API, HTTP 429 on Gemini/Anthropic).
   - Rate limit depletion causes job exit 1 while auth logs report zero failures without quota context.

3. **Pipeline Lock Contention & Stale Locks:**
   - Background jobs share lock files under `~/.cache/rebalance-os/locks/` (e.g. `rebalance-embed.lock`). Collisions cause subordinate syncs (`vault-sync`) to fail lock acquisition and exit `1`.
   - Doctor does not proactively audit lock files for dead PID holders or stale durations.

4. **Read-Side Query Engine & MCP Tool Responsiveness:**
   - Ingestion and database integrity are validated, but no smoke test audits the read-side synthesis and vector retrieval pipeline (`querier.py`, `semantic_query()`, MCP stdio server).

### Objective for Reviewer (Aider -> OpenRouter -> stealth/ox-alpha)

1. Verify whether this 4-part diagnosis is technically accurate against the Rebalance OS architecture (`src/rebalance/doctor.py`, `src/rebalance/ingest/index_ops.py`, `SCHEDULER.md`).
2. Identify any missing critical paths, potential regression risks with active quota probing, or edge cases in lock auditing.
3. Provide a clear verdict (`Approved` / `Changes Requested`) and structured findings.

---

▶ TAKE YOUR TURN:
Review the diagnosis above. Append your structured review block below, and update `STATUS:` and `NEXT:`.

---

## Review — aider (Reviewer, Round 1)

**Verdict: Approved.** The 4-part diagnosis is technically sound; each gap maps to a concrete, well-known failure mechanism, and no claim in the brief is incorrect. Advisories below are non-blocking but should shape implementation.

**Verification-scope caveat:** `src/rebalance/doctor.py`, `src/rebalance/ingest/index_ops.py`, and `SCHEDULER.md` were not attached to this relay turn. This review verifies the diagnosis against the architecture as described in the Phase Brief and the cited incident record; line-level source confirmation is deferred to the implementer. Nothing in the brief is internally inconsistent or architecturally implausible.

### Finding-by-finding assessment

**F1 — Exit 0 vs. delivery verification: ACCURATE, HIGH VALUE.**
- The skip-and-exit-0 pattern (missing env var → logged skip → exit 0 → doctor `OK`) is a real blind spot: exit codes capture crash-class failures only, not no-op-class failures.
- **A1:** Delivery verification needs a ground-truth signal that distinguishes "legitimately nothing to do" (quiet day → zero notes written is correct) from "silently skipped." Inferring from filesystem mtimes alone will false-positive on low-activity days. Prefer structured job manifests/heartbeats: each job reports `{expected_work, completed, skipped[], skip_reasons}` to a known location; doctor audits the manifest, not the filesystem.
- **A2:** Treat the root cause directly as well — the incident trigger was missing vault env vars. Doctor should validate required env vars in the launchd job's actual environment (as launchd resolves it), not only detect downstream symptoms. This catches the failure before the job runs.
- **A3:** Also audit "did the job run at all" (last-successful-run timestamp per job vs. expected schedule). Silent skips (F1) and jobs-never-fired (launchd label unloaded, calendar mismatch) are distinct blind spots; the brief covers only the former.

**F2 — Static token presence vs. live quota: ACCURATE.**
- Auth-failure logs and quota exhaustion are disjoint failure classes; a fully authenticated job can die on 429 with zero auth failures logged. Correct.
- **B1 (regression risk, explicitly requested):** Active quota probing consumes quota and adds a network dependency to doctor itself. Prefer passive-first: have jobs record `x-ratelimit-remaining` / `Retry-After` / 429 events into job telemetry; doctor reads telemetry. If active probing is retained: (a) GitHub — use `GET /rate_limit`, which does not count against the core limit; (b) Gemini/Anthropic — no guaranteed zero-cost quota endpoint, so probe at low frequency with caching, and treat probe-transport-failure as "unknown," never as "quota exhausted" (otherwise doctor goes red whenever the machine is offline — a new false-positive class).
- **B2:** Static presence checks also miss expired-but-present tokens. Only an active probe or cheap authenticated no-op call catches expiry — fold this into the F2 spec explicitly.

**F3 — Lock contention & stale locks: ACCURATE, with edge cases.**
- Shared-lockfile collisions causing subordinate exit-1 is a standard contention pattern; proactive audit is justified.
- **C1 (PID reuse):** Liveness-by-PID alone false-positives "alive" after PID recycling. Store holder PID **plus process start time** (e.g., `/proc/<pid>/stat` field 22, or `ps -o lstart`) in the lockfile; a lock is stale only if the PID is dead **or** the start time mismatches.
- **C2 (acquisition race):** A just-created lockfile may be empty (PID not yet written). Treat empty/short lockfiles as "acquiring in progress," never stale.
- **C3 (stale threshold):** Fixed duration thresholds false-positive on legitimately long jobs (full re-embed). Prefer holder heartbeats (lockfile mtime touched every N seconds) or per-lock expected max durations.
- **C4 (remediation risk — highest in this finding):** Doctor must be **read-only on locks by default**. Auto-deleting a misjudged live lock enables concurrent writers and index corruption — strictly worse than the contention being diagnosed. If remediation is added, gate behind an explicit flag with a re-verify-before-delete step.
- **C5:** Contention is transient; a point-in-time snapshot can flag a lock that frees itself seconds later. Prefer contention history from job logs (acquisition-failure counts over a window) over snapshot-only.

**F4 — Read-side smoke test: ACCURATE.**
- Write-side integrity does not exercise `querier.py` / `semantic_query()` / the MCP stdio server. Correct gap.
- **D1:** The highest-value read-side failure is silent, not crashing — embedding model/version drift between indexed vectors and the current query encoder returns zero-results or garbage without errors. Add an index-metadata ↔ config model-stamp consistency check alongside the smoke query.
- **D2:** MCP smoke = spawn server, initialize handshake, one tool call, assert response, **and reliably reap the child** (repeated doctor runs must not orphan servers).
- **D3:** Use generous latency SLO bounds; report latency as a metric, hard-fail only above a wide bound — otherwise doctor becomes flaky on loaded machines.

### Missing critical paths (beyond the 4)
- **Jobs-never-fired audit** (see A3) — distinct from silent skips.
- **Disk-space headroom** for index/vault volumes — ENOSPC often surfaces as partial writes that pass mtime-based checks.
- **Config drift** — env vars / paths referenced by job plists that no longer exist (the root-cause class of the F1 incident).

### Regression-risk summary (ranked)
1. Lock auto-remediation → concurrent-writer corruption (C4).
2. Active quota probing → doctor's own network dependency + quota burn (B1).
3. Delivery verification via mtimes → false positives on quiet days (A1).
4. Tight latency SLOs → flaky doctor (D3).

**Final verdict: Approved.** Implementer should incorporate advisories A1–D3; B1 and C4 are the two highest regression risks and must be addressed in the remediation design even though they do not block this diagnosis.
