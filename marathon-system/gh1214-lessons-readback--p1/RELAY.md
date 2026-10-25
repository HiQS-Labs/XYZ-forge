# Marathon Phase p1
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

---
gh_issue: 1222
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1222
title: "releases: _live_manifest_count double-counts a shipped+redialed issue (#1214 P5)"
status: Active (2-WORKING — marathon GH-1214 phase p1)
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: two COUNT queries, confirmed reachable by Kimi K3.1 QA on #1214
non_goals:
  - Changing redial semantics (a redial still inserts a second row — GH-111/GH-351 append-only trail)
  - Rewriting already-captured baseline_count values in existing databases
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 5)
  - GH-111, GH-351 (row-per-dial design)
goal: >
  A release's live manifest count and the migration-004 backfill count each issue once, even when
  that issue has both a shipped row and a redialed dialed_in row in the same release.
---

# GH-1222 — `_live_manifest_count` double-counts a shipped+redialed issue

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p1 of marathon #1214; contract added; reachability confirmed by Kimi K3.1 QA (`releases_app.py:114-123,2618-2677`) | Marathon phase p1 (agy builder, codex reviewer): switch both queries to `COUNT(DISTINCT issue_ref_id)`, record the manual check, gate green |

Umbrella: #1214 · Phase p1 · first in the chain (no `depends_on`).

## Ground truth (`origin/development` 395e9d64)

- `utils/py/releases_app.py:114-123` — re-dialing a shipped item inserts a **second** row (`dialed_in`) beside the `shipped` row.
- `utils/py/releases_app.py:2517-2522` — `_live_manifest_count` runs `SELECT COUNT(*) FROM manifest_items WHERE release_id = ? AND state IN ('dialed_in','shipped')`, which counts that issue twice. It feeds the write-once `baseline_count` (`:2533`).
- `utils/py/releases_app.py:824-833` — migration 004's backfill uses the same shape.

## Plan (one phase)

1. Change `_live_manifest_count` to `COUNT(DISTINCT issue_ref_id)` and add a `GH-1222` comment explaining why: one issue can hold a shipped row and a redialed row at once.
2. Make the same change in migration 004's backfill query, with the same comment tag.
3. Record a manual check under `TESTS-RESULTS/2026-10-25+GH-1222/` using a throwaway database under `$TMPDIR`, never the repo's `releases.db`. Dial an issue, ship it, redial it; show the count is 1, not 2, before the fix (red control) and after; show that a second distinct issue raises the count to 2. Write `manual-check.md` with the commands and output, plus `provenance.jsonl`.

Rules: Python only; shortest diff (`/ponytail`); no new suite or registry entry (GH-831 D7). Edit an existing suite only if a pinned assertion becomes untrue. Do not touch `releases.db` / `releases.sql` / `CHANGELOG.md` (orchestrator reconciles at landing).

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/releases_app.py",
      "pattern": "GH-1222"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/releases_app.py",
    "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1222",
    "criteria": "_live_manifest_count and the migration-004 backfill in utils/py/releases_app.py count DISTINCT issue_ref_id over dialed_in+shipped rows, so a shipped-then-redialed issue counts once while distinct issues still add; a GH-1222 comment explains why; a manual red/green check on a throwaway DB is recorded under TESTS-RESULTS/2026-10-25+GH-1222/ with provenance.jsonl; existing releases suites stay green."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/releases_app.py",
      "TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- After a ship and a redial of one issue in a throwaway DB, `_live_manifest_count` returns 1 for it, and the migration-004 backfill expression counts it once.
- Two distinct live issues count 2.
- `test/gh32-releases-app.sh` and the full `bash validate.sh` are green.
- Manual check + `provenance.jsonl` present under `TESTS-RESULTS/2026-10-25+GH-1222/`.

## Lessons Learned (For Future Agents)

- (filled at closeout)


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/releases_app.py, TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick claim MARATHON-P1-TURN --agent agy --paths "marathon-system/gh1214-lessons-readback--p1/RELAY.md,utils/py/releases_app.py, TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick ping MARATHON-P1-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P1-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1214-lessons-readback--p1/RELAY.md and utils/py/releases_app.py, TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py, TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P1-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick done MARATHON-P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   Edit ONLY marathon-system/gh1214-lessons-readback--p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

---

### Round 1 · Builder · agy

- **Files touched:**
  - `utils/py/releases_app.py`
  - `TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md`
  - `TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl`
  - `marathon-system/gh1214-lessons-readback--p1/RELAY.md`
- **Summary of changes:**
  1. Updated `_live_manifest_count` (`utils/py/releases_app.py:2519-2526`) from `SELECT COUNT(*)` to `SELECT COUNT(DISTINCT issue_ref_id)` with a `# GH-1222:` comment explaining that one issue can hold both a `shipped` row and a redialed `dialed_in` row at once.
  2. Updated migration 004's active-release baseline backfill query (`utils/py/releases_app.py:826-832`) to `SELECT COUNT(DISTINCT issue_ref_id)` with the same `# GH-1222:` comment.
  3. Executed a throwaway SQLite ledger verification under `$TMPDIR` (never touching the repository's `releases.db`) demonstrating:
     - Red control: `COUNT(*)` returns `2` when one issue is dialed in, shipped, and redialed.
     - Green control: `_live_manifest_count` and the migration-004 backfill query return `1` for that shipped+redialed issue, and `2` once a second distinct issue is dialed in (and `baseline_count=2` on `draft -> active`).
  4. Recorded the commands, output, and provenance under `TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md` and `TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl`.
  5. Verified existing releases test suites pass: `bash test/gh32-releases-app.sh` (145/145) and `bash test/gh351-manifest-unship.sh` (13/13).

