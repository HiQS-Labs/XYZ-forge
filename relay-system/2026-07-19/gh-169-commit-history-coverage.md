# RELAY · GH-169 commit history coverage — will this durably conclude the 155/157/169 chain?
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-19.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-169-commit-history-coverage): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **GH-169-COMMIT-HISTORY-COVERAGE.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-19

### Artifact — GH-169-COMMIT-HISTORY-COVERAGE.md
````
---
gh_issue: 169
source: https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/169
title: Commit history coverage — backfill direct + merge commits, and stop the collector evicting its own work
status: "Active (2-WORKING)"
owner: Noel
created: 2026-07-19
updated: 2026-07-19
doc_type: project
branch: worktree-temp-cognee-litmus-test
goal: >
  Make git commit history a complete, self-healing signal source. Close the measured 182-commit
  (19.4%) gap on `development` — including the CLIO import commit `cfeafe4` — by enumerating
  history from the local clone rather than the Events API, and repair the attempt-accounting
  defect that is currently evicting 20 push events that never actually failed. Completeness must
  become a property the system can prove and re-derive, not a side effect of a 300-event API window.
related:
  - PROJECT/1-INBOX/GH-155-DIRECT-COMMIT-SIGNALS.md
  - PROJECT/2-WORKING/GH-146-HEALTH-SIGNAL-ACCURACY.md
  - PROJECT/2-WORKING/SIGNAL-HEALTH-NUANCE.md
  - PROJECT/1-INBOX/GH-156-CRITICAL-CLIO-PROJECTION-RECONCILIATION.md
non_goals:
  - Ingesting archived third-party repos (deferred from the original #169 framing — the destination
    repo's own commit already carries the provenance).
  - Changing the embedding model or re-embedding the existing corpus.
  - Re-architecting the Events-API path from #157; it stays as an accelerator.
effort: 3
complexity: 3
risk: 2
phases: 4
---

# GH-169 — Commit history coverage

## Status

| What was just completed | What's next |
|---|---|
| RCA complete. Four compounding causes identified and each one confirmed against live data, not inferred: 300-event API ceiling, actor-scoped discovery, per-run caps starving the queue, and an attempt-accounting defect that has already permanently evicted 20 push events which never failed. Gap measured at **182 of 938 commits (19.4%)** on `development` since 2026-05-01. | Phase 1 — build the local-git backfill, verify `cfeafe4` becomes queryable and the gap goes to 0. Doc is out for an agy relay review before code is written. |

## Table of contents

- [Why this exists](#why-this-exists)
- [Root cause analysis](#root-cause-analysis)
- [Phase 1 — Local-git commit backfill](#phase-1--local-git-commit-backfill)
- [Phase 2 — Repair attempt accounting](#phase-2--repair-attempt-accounting)
- [Phase 3 — Completeness as a measurable property](#phase-3--completeness-as-a-measurable-property)
- [Phase 4 — Verification against the original symptom](#phase-4--verification-against-the-original-symptom)
- [Anti-goals](#anti-goals)

## Why this exists

The operator could not answer "where does CLIO live, and where did it come from?" from the HiQS
signal, and resorted to manual digging. The answer existed the whole time, in one commit:

```
cfeafe4f564cf8f8fa5b161bad80642ae8752d16   2026-07-17T20:06:18-07:00

feat: bring CLIO into rebalance-OS as its canonical home

Pull the latest CLIO skill (append+cursor exporter for cross-device
accumulation, atomic same-fs writes, shrink-cursor recovery) from
Claude-AI-Tools-Ventura-County/CLIO-Claude-Prompts@ef96a44, plus
README/LICENSE, into utils/CLIO/.
```

That single document names the origin repo, the exact upstream SHA, the destination path, and the
intent. It was never indexed. This is the third consecutive issue in this area (#155 → #157 → #169),
which is the "one more thing" pattern this doc is explicitly chartered to end — hence Phase 3, which
exists so the *next* gap is detected by the system rather than by an operator noticing a bad answer.

## Root cause analysis

Why a gap persists **after** #157 shipped. All four verified against the live DB on 2026-07-19.  [Unverified — no citation]

### RC1 — Discovery is capped at 300 events / ~90 days

`capture_direct_commits()` never enumerates git history. It only filters a list of `events` handed in
from `github_scan` (`src/rebalance/ingest/github_direct_commits.py:82`, `:99`). GitHub's user-events
endpoint returns at most 300 events and retains roughly 90 days. The 2026-07-19 refresh reported
`events: 300` — the ceiling, exactly. Anything older is undiscoverable by construction, and no amount
of re-running helps. `cfeafe4` is outside that window.

### RC2 — Discovery is actor-scoped

The scan reads the authenticated user's event feed (`login: noelsaw1`). Commits pushed under a
different account, a different device identity, or by CI never enter the candidate set at all.

### RC3 — Per-run caps starve the queue

`MAX_PUSH_COMPARES_PER_REFRESH = 5` and `MAX_COMMIT_DETAILS_PER_REFRESH = 20`
(`github_direct_commits.py:17-18`). The observed refresh enriched 5 events and deferred 20. There are
**137 push events still pending at attempt 0** with a drain rate of ~5 per run.

### RC4 — Cap-deferrals burn retry attempts (the actual data-loss defect)

`update_push_event()` in `src/rebalance/ingest/db/github.py` increments unconditionally:

```sql
SET state = ?, attempt_count = attempt_count + 1, ...
```

while `pending_push_events()` selects only `WHERE state IN ('pending','deferred') AND attempt_count < ?`
against `MAX_EVENT_ATTEMPTS = 3`.

A deferral for `"compare cap reached"` (`github_direct_commits.py:161`, and `:139`) is **not a
failure** — it means the run exhausted its own budget before reaching this event. It costs an attempt
anyway. Lose that lottery three times and the event is permanently excluded from the pending query.
It will never be fetched, and nothing reports it as lost.

Live state confirming this:

| state | attempt_count | n | dominant reason |
|---|---|---|---|
| deferred | 1 | 5 | compare cap reached |
| deferred | 2 | 5 | compare cap reached |
| **deferred** | **3** | **21** | **compare cap reached (20 of 21)** |
| enriched | 1–3 | 29 | — |
| pending | 0 | 137 | — |

**20 push events have been permanently dropped without a single real failure.**

The module docstring states: *"A transient failure remains a durable deferred receipt, so no work is
silently treated as absent."* The implementation does not honour that guarantee. Worse, the
`events_deferred` counter reports these as ordinary deferrals, so the refresh output looks healthy
while data is being discarded — the same class of defect as GH-146, where a working system reported
as broken; here a lossy system reports as working.

### Why the two fixes are different

RC1/RC2 are **coverage** problems — the collector cannot see far enough back, or wide enough.
RC3/RC4 are **durability** problems — of what it does see, it discards some. Backfill alone would
close today's gap and let it regrow. The attempt fix alone would not recover `cfeafe4`, which is
outside the event window entirely. Both are required, which is why this doc has both.

## Phase 1 — Local-git commit backfill

**Decision (operator, 2026-07-19):** read from the **local clone**, not the API. Every one of the 182
missing SHAs is already on disk. This costs zero API calls, is not rate-limited, and therefore does
not reproduce the pressure that motivated the caps in RC3 — which is precisely what makes a
full-history backfill affordable instead of a 90-day compromise.

- [ ] Add `backfill_commits(database_path, repo, *, since, cap)` in a new
      `src/rebalance/ingest/github_commit_backfill.py`.
- [ ] Enumerate via `git log` on the resolved default branch: SHA, author, author-email, authored
      date, full message, and changed paths (`--name-only`).
- [ ] Dedupe against **both** `github_commits` (PR commits) and `github_direct_commits` before
      insert; key on `(repo_full_name, sha)`.
- [ ] Capture **merge commits explicitly** — they are missed by both existing paths and are the
      "when did X land on development" record.
- [ ] Persist into `github_direct_commits` / `github_direct_commit_files` with a new
      `path_coverage` value distinguishing git-sourced rows from API-sourced ones.
- [ ] Project through the existing `sync_direct_commit_documents()` so no retrieval-side change is
      needed.
- [ ] Resolve the clone path from existing config rather than a new hardcoded constant; skip cleanly
      with a logged reason when no clone is present.

### QA gate — Phase 1

- [ ] Backfilling `development` since 2026-05-01 reduces the measured 182-commit gap to **0**.
- [ ] `cfeafe4` is present in `github_direct_commits` with its full message and all 3 `utils/CLIO/` paths.
- [ ] Merge commits are captured and do **not** duplicate their PR-commit counterparts.
- [ ] Re-running the backfill is a no-op (0 inserted, 0 updated) — idempotency proven, not assumed.
- [ ] Zero GitHub API calls made by this path, asserted in test.
- [ ] Runs cleanly against a repo with no local clone (skips, logs, does not raise).
- [ ] `rebalance doctor` clean.

## Phase 2 — Repair attempt accounting

- [ ] Separate **budget exhaustion** from **attempt failure**. A cap-deferral must not increment
      `attempt_count`; introduce a distinct state (e.g. `queued`) or an explicit
      `increment_attempt: bool` on `update_push_event()`.
- [ ] Recover the 21 currently-stuck events: reset those whose `failure_reason` indicates a cap
      deferral rather than a genuine fetch failure.
- [ ] Distinguish the two in `DirectCommitCaptureResult` — `events_deferred` must not conflate
      "over budget" with "failed", since that conflation is what made this invisible.
- [ ] Make the module docstring's durability claim true, or amend the docstring. It currently
      asserts a guarantee the code does not provide.

### QA gate — Phase 2

- [ ] A regression test proves an event deferred purely by cap is still eligible after 3+ runs.
- [ ] The 21 stuck events return to eligibility; the 20 cap-only ones enrich on subsequent runs.
- [ ] Genuine failures (non-retryable HTTP) still exhaust attempts and stop retrying — the fix must
      not turn real failures into an infinite retry loop.
- [ ] Refresh output reports over-budget and failed counts separately.

## Phase 3 — Completeness as a measurable property

This phase is why the doc exists in the form it does. #155 and #157 each fixed a real thing and each
left a gap that only surfaced when an operator asked a question and got a bad answer. Completeness
must be continuously derivable.

- [ ] Add a coverage check comparing local `git log` SHAs against captured SHAs, reporting the
      absolute gap per repo.
- [ ] Surface it in `index_status` freshness (alongside `github_documents_missing_from_semantic`)
      and in `rebalance doctor`.
- [ ] Degrade health status when the gap exceeds a defined threshold.

### QA gate — Phase 3

- [ ] With commits deliberately withheld, the check reports the correct non-zero gap.
- [ ] After backfill, it reports 0 and health is `ok`.
- [ ] The check is cheap enough to run on every `doctor` invocation (local git only, no API).
- [ ] Consistent with the #167 precedent for reporting corpus drift.

## Phase 4 — Verification against the original symptom

The plan is only done when the question that started it is answerable.

- [ ] Re-run `semantic_query("where does CLIO live and where did it come from")`.
- [ ] `cfeafe4` returns in the top results, carrying both the origin repo and `utils/CLIO/`.
- [ ] Spot-check 3 further missing commits from the measured 182 for correct message and paths.
- [ ] Record the before/after retrieval comparison in this doc (per PDDA: discovery findings are
      written back here before the gate passes).

### QA gate — Phase 4

- [ ] The originating operator question is answered from the signal alone, with no manual digging.
- [ ] Full suite: zero regressions against the `development` baseline.
- [ ] `rebalance doctor` and `pdda` both clean.
- [ ] Findings written back into this doc.

## Anti-goals

- **Not** ingesting archived third-party repos. Deferred from the original #169 framing after the
  RCA showed the destination repo's own commit already carries the provenance — the origin repo did
  not need ingesting at all.
- **Not** removing the Events-API path. It stays as a low-latency accelerator; git history becomes
  the correctness backstop.
- **Not** raising the per-run caps as the fix. Caps are a legitimate rate-limit defence; the defect
  is that hitting one is accounted as a failure.
- **Not** a full re-embed of the corpus.
````
### Definition of Done — what the Reviewer grades against

**Context the Reviewer needs.** This is the *third* consecutive issue in one area. #155 diagnosed that
direct commits were lost; #157 shipped a fix and was closed as COMPLETED; yet a 182-commit (19.4%)
gap remains on `development`, and the operator still could not answer "where does CLIO live and where
did it come from" from the signal. The operator's explicit charter for this plan: **it must
confidently conclude this issue rather than becoming another "one more thing."** Grade accordingly —
a plan that closes today's gap but leaves the chain open should not be Approved.

Grade these five questions. Each finding needs a quoted span or `file:line` citation.

1. **Is the RCA complete?** Four causes are claimed (RC1 300-event/90-day ceiling, RC2 actor-scoped
   discovery, RC3 per-run caps starving a 137-event backlog, RC4 cap-deferrals incrementing
   `attempt_count` so 20 events were evicted without a genuine failure). Is there a **fifth cause**
   the plan misses? Specifically consider: PR commits from repos never synced; force-pushes and
   rewritten history; commits on branches never merged to the default branch; squash-merges where the
   original SHAs vanish; and whether `sync_direct_commit_documents()`'s
   `DELETE FROM github_documents WHERE doc_type = 'direct_commit'` full-rebuild has its own failure mode.

2. **Does Phase 3 actually prevent recurrence?** It proposes comparing local `git log` SHAs against
   captured SHAs and surfacing the gap in `doctor` / `index_status`. Is that sufficient, or does it
   merely detect the *same* class of gap it was written for — leaving a new class (a source that isn't
   git, or a repo with no local clone) equally silent? If the check is itself the thing that could
   drift, say so and propose the stronger invariant.

3. **Does the local-git backfill decision have blind spots?** The operator chose local clone over the
   GitHub API: zero API cost, no rate limits, all 182 SHAs already on disk. Where does this fail?
   Consider: repos with no clone on this machine; a clone that is stale or behind origin; shallow
   clones; commits present on origin but never fetched; multi-device divergence (this repo is used
   from at least three machines); and whether "the local clone" is even well-defined for a watched
   repo the operator has never cloned.

4. **Is the Phase 2 fix correct and safe?** Separating budget-exhaustion from attempt-failure must not
   turn genuine non-retryable failures into an infinite retry loop, and the recovery step mutates
   existing rows in a live DB. Is the proposed reset keyed safely (it selects on `failure_reason` text)?
   Is there a migration/rollback story?

5. **Is the phase ordering right?** Phase 1 (backfill) ships before Phase 2 (durability). Does
   backfilling into a collector whose accounting is still broken create any interference — double
   counting, coverage-value confusion between git-sourced and API-sourced rows, or masking the very
   defect Phase 2 must then detect?

**Verdict rule.** Approve only if you believe this plan ends the #155→#157→#169 chain. If it closes
the gap but the chain can plausibly continue, that is `Changes requested` with the specific gap named.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: agy (Reviewer)

**Verdict:** Changes requested

**Findings:**
- `[Should]` RCA completeness: The RCA misses the failure mode of the indexer itself (`sync_direct_commit_documents()` doing a full delete and failing mid-insert, wiping the corpus) and orphaned SHAs from force-pushes. Fix: Add RC5 to account for downstream indexer failures and rewritten history (ref: `Root cause analysis` section).
- `[Blocker]` Phase 3 blind spot: Comparing local git to local DB (lines 229-231: "Add a coverage check comparing local `git log` SHAs against captured SHAs") only proves the backfill ran, not completeness against the remote repo. If the local clone is stale, the gap will falsely report 0. Fix: The coverage check must involve the remote (e.g., check against `git ls-remote` HEAD or ensure a successful fetch happened recently).
- `[Blocker]` Local-git backfill blind spots: The plan admits it will "skip cleanly with a logged reason when no clone is present" (line 190). For watched repos without a local clone, this leaves the coverage gap permanently open. Additionally, local clones can be stale. Fix: Phase 1 must include `git fetch` before enumeration, and define a fallback (e.g. API) or explicit warning for tracked repos with no local clone.
- `[Should]` Phase 2 safety: Resetting live DB rows based on text matching (`failure_reason` indicates a cap deferral, lines 208-209) is brittle and risky. Fix: Provide the exact `UPDATE` SQL with a `SELECT` dry-run step to preview affected rows before mutating production data, and a rollback plan.
- `[Should]` Phase ordering interference: If Phase 1 backfills commits first, and Phase 2 later unsticks 21 deferred events (line 218), those un-stuck events will re-process and may overwrite the `path_coverage` metadata Phase 1 just added (line 186). Fix: Either swap Phase 1 and 2 (fix the pipeline first, then backfill) or explicitly define an `ON CONFLICT DO UPDATE` policy that preserves the backfill metadata.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
