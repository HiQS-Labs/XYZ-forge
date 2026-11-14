# RELAY: GH-1459 — Daily Work Ledger GH Issue & Checkout Calibration Plan QA

ARTIFACT: PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md
PRODUCER: claude
REVIEWER: codex
ROUND_CAP: 3
STATUS: Changes Requested
NEXT: claude

---

## Round 1 — Producer (claude)

### Summary
Prepared the `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` implementation plan for issue #1459 (`daily-planner: shared Daily Work Ledger GH issue, carryover, checkout calibration, and vendored repo support`).

### Verification / Context
- Grounded `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/daily-planner/SKILL.md`, and `skills/3-weekly/weekly-planner/SKILL.md` at `Recon: 7acaa2450` (`origin/development` `6f4dbaf9c`).
- Incorporates cross-model `/consult` findings (`relay-system/2026-11-13/daily-work-ledger-idea-170103`, comment `https://github.com/HiQS-Labs/XYZ-forge/issues/1459#issuecomment-6869175826`).
- Respects repo guardrails:
  - Zero new files under `test/` (`GH-831`, `AGENTS.md:162`); all verification and red/green negative controls will be recorded in `TESTS-RESULTS/2026-11-13+GH-1459/` with `provenance.jsonl`.
  - Zero new `sqlite3.connect` calls (`GH-777`); `forge` mode reuses existing `get_release_milestones` and `ingest_weekly_intake`.
  - Rebalance's `/daily` skill remains untouched.

### Questions for Reviewer (codex)
First, in 3–5 sentences, paraphrase what you understand the goal of this plan to be and what problem it solves. If the goal is ambiguous or could be misread, flag that before reviewing the steps.

Then review `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` against the real codebase:
1. Are the target files, functions, and line references in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` accurate?
2. Does the plan reuse existing subsystems (`planner_core.py`, `daily-planner/SKILL.md`, `weekly-planner/SKILL.md`) cleanly without duplicating logic or violating `GH-777` / `GH-831`?
3. Are the failure modes, security/ownership checks (`auth_login`, `min(number)` tie-break, `limit=100` refusal on truncation, preserved `started:` timestamp), and verification steps complete?
4. Do you have any `[P0]` or `[P1]` blockers before implementation begins, or is this plan `STATUS: Approved`?


## Round 1 — Reviewer (codex)

### Goal understanding
The plan adds a GitHub-native daily coordination workflow to the existing shared planner engine. Operators should resume unfinished work across devices, discover assigned issues and PR follow-ups, and see earlier starters' checkout claims before choosing work. It must work in Forge, vendored, and plain GitHub repositories without a weekly baseline. Publishing remains explicit, and Rebalance's separate `/daily` workflow remains unchanged. That goal is clear.

### Verdict: Changes Requested
The current function locations and the missing-ledger diagnosis agree with the source. Extending the shared engine and reusing existing read-only release intake is appropriate; no new database connection or permanent test suite is necessary. Resolve the following before implementation:

1. **[P1] Authenticate ledger claims on ingestion, not only PATCH** — plan lines 83, 88–89 and Acceptance lines 119–120. The reader currently accepts every matching marker and labels it `verified-ledger-claim`; only the writer checks GitHub authorship. A comment by user B can name operator A, an earlier `started:` time, and arbitrary tasks, thereby injecting A's carryover or suppressing another operator's candidate through a false collision. Quoted marker examples can also become claims. Require a first-line marker, matching ledger date, and case-insensitive marker-operator versus actual GitHub comment author validation before granting verified provenance or using it as an attributed checkout. Define explicit trusted delegation semantics for bot-authored claims; handle issue-body attribution separately rather than treating every marker in a shared body as the issue author's claim. Apply operator/auth checks to POST as well as PATCH, so a missing existing comment does not bypass attribution. Add manual negative controls for a forged first-line claim, a quoted marker, and mismatched-operator first publication, plus a legitimate cross-device positive control. Preserve the unconditional comment-author/authenticated-writer equality on PATCH even with delegation.
   - Evidence: `nl -ba PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md | sed -n '80,123p'` exited 0: line 88 says “Parse all comments ... matching” and assigns `verified-ledger-claim`; line 89 scopes authentication to “Before PATCHing”. `rg -n -A 12 -B 3 "first line|marker lookup" LESSONS-LEARNED.md` exited 0: line 154 explicitly says “Match the marker with startswith, not contains.” This is a plan-contract gap, not a claim that the unimplemented reader has been executed.

2. **[P2] All-history discovery has a permanent 100-ledger cutoff** — plan Step 1 discovery query and Acceptance line 118. The query sorts all historical ledger issues ascending and takes 100, then refuses publishing whenever that cap is reached. At 100 accumulated ledger issues, every subsequent daily run refuses even when today's issue exists; after that, neither today nor the latest previous workday appears in the returned oldest 100. Fail-closed truncation handling is good, but cannot be the normal terminal state of a daily feature. Paginate discovery to completeness or use separate complete date-scoped today discovery and a bounded recent-history lookup with explicit completeness handling. Retain refusal on genuine incomplete discovery. Specify a control with over 100 historical issues proving today's canonical issue and the most recent prior ledger are still resolved.
   - Evidence: `cat PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` exited 0: the exact proposed query uses `sort:created-asc`, `--state all`, `--limit 100`; the following bullet refuses creation on the cap. This follows directly from the specified query, without executing GitHub requests.

3. **[P2] Existing local scanner does not supply the promised claims/worktree inventory** — plan Step 1 and Acceptance line 119. `scan_local_checkout` reads branch refs and dirty counts only; it neither enumerates linked worktrees nor reads `.tick` claims. Moreover, clean branches with an upstream and no ahead commits produce no local row, even when actively checked out. The plan mentions scanning claims and worktrees but names no concrete read contract or negative control for either. State how the existing scanner will be extended/reused to enumerate checked-out worktrees and active tick claims, including explicit target-root pinning for vendored/native tick or direct read-only state access. Define how active issue identifiers reach collision matching, and record controls with a clean tracked worktree and a live claim that have no dirty/ahead signal. Do not invoke claim/ping or any mutating tick verb during collection.
   - Evidence: `sed -n '1352,1406p' skills/3-weekly/weekly-planner/scripts/planner_core.py` exited 0: the scanner invokes `for-each-ref` and `status --porcelain`, emitting rows for closed-head matches, no upstream, ahead, or dirty state. `rg -n "worktree|tick|claims" skills/3-weekly/weekly-planner/scripts/planner_core.py` exited 0: only the dirty `kind: worktree` row and a rendering comment match; there is no tick claim reader.

### Verification limits / handoff
Source inspection only; no git commands, gates, pytest, executable fixtures, or implementation writes were run. Runtime red/green controls and the full gate remain **[Unverified — needs clone run]**, correctly assigned to the producer's disposable-clone verification step. The existing `get_open_prs` only warns at its cap (lines 340–342); ensure ledger coverage explicitly marks that cap truncated as promised, rather than interpreting a returned list as complete. Canonical `min(number)`, preserved starter time, pagination of comment reads, and the existing PATCH author guard are sound directions once the ingestion contract above is closed.
