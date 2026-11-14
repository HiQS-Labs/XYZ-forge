# RELAY: GH-1459 — Daily Work Ledger GH Issue & Checkout Calibration Plan QA

ARTIFACT: PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md
PRODUCER: claude
REVIEWER: codex
ROUND_CAP: 3
STATUS: Approved
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


---

## Round 2 — Producer (claude)

### Summary of Revisions
Resolved all three Round 1 findings directly in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md`:

1. **[P1] Authenticate ledger claims on ingestion (first-line marker + comment author == marker operator) and on both POST and PATCH:**
   - **Ingestion contract (`collect_operator_continuation_and_queue`):** Only comments whose **first non-empty line** (`body.lstrip().splitlines()[0].strip()`) matches `^<!-- daily-ledger:([a-zA-Z0-9._-]+):([a-zA-Z0-9._-]+):(\d{4}-\d{2}-\d{2})(?:\s+started:(\S+))? -->$` AND whose marker date matches the target ledger date (`prev_date` or `date_local`) are parsed (`LESSONS-LEARNED.md:154`). Shared issue `body` text and line-2+ quoted markers are never parsed as claims. Before trusting any comment for prior-workday carryover or `verified-ledger-claim` checkout calibration, the reader verifies `comment["user"]["login"].lower() == marker_op.lower()` (or an explicit `--allow-delegate-comment` trusted bot allowlist `XYZ_DAILY_LEDGER_TRUSTED_BOTS` / `daily_ledger_trusted_bots`, default empty). Any comment where `comment.user.login != marker_op` is rejected as `unverified-forged-marker` and excluded from carryover and collision suppression.
   - **Publication contract (`sync_daily_ledger_comment`):** Enforces `operator.lower() == auth_login.lower()` before creating an issue, `POST`ing a new comment, or `PATCH`ing an existing comment, and unconditionally requires `comment["user"]["login"].lower() == auth_login.lower()` on `PATCH` even when delegation is enabled.
   - **Controls added to Acceptance:** Added explicit controls for (a) a forged first-line comment (`comment.user.login="mallory"`, marker `"alice"`), (b) a line-2 quoted marker, (c) mismatched `--operator != auth_login` on first-time `POST`, (d) forged comment on `PATCH`, and (e) legitimate cross-device (`laptop-a` -> `studio-b`) carryover by the same authenticated operator.

2. **[P2] Eliminated the 100-ledger historical cutoff in discovery (`find_or_create_daily_ledger_issue`):**
   - Split discovery into (1) an exact-date today query (`"Daily Work Ledger — <date_local>" in:title sort:created-asc --limit 100`) and (2) a descending recent-history query (`"Daily Work Ledger — " in:title sort:created-desc --limit 100`) so the 100 newest ledger issues are returned first regardless of how many historical daily ledgers exist, with paginated `gh api --paginate --slurp search/issues` fallback if all 100 descending results are on/after `date_local` or share the same prior date.
   - Added an explicit control in Acceptance with >100 historical ledger issues proving both today's canonical `min(number)` issue and the most recent prior workday (`date < today`) are resolved accurately while still refusing creation (exit 3) when discovery fails or remains incomplete.

3. **[P2] Extended `scan_local_checkout` for linked worktrees and read-only `.tick` claims + `open_prs` cap truncation:**
   - Specified that `scan_local_checkout(repo_root)` runs `git -C <repo_root> worktree list --porcelain` (read-only) to emit `kind: "worktree_branch"` rows with extracted issue numbers (`(?:#|GH-|gh)(\d+)`) even when clean/tracked/0-ahead, and reads active `.tick` claims read-only via `TICK_REPO_ROOT=<repo_root> <tick_bin> claims --json` (or pure-Python read-only replay of `<repo_root>/.tick/events/*.jsonl` without mutating state or invoking `claim`/`ping`), emitting `kind: "tick_claim"` rows for `local-device-only` checkout calibration and collision detection.
   - Explicitly marks `coverage["open_prs"]["status"] = "truncated"` when `len(prs) >= 100`.
   - Added explicit Acceptance controls for a clean tracked git worktree (0 dirty, 0 ahead) and a live `.tick` claim with 0 dirty/ahead git commits.

### Questions for Reviewer (codex)
Please verify that `[P1]` and both `[P2]` items in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` are now fully addressed and mark `STATUS: Approved` if ready for implementation.


## Round 2 — Reviewer (codex)

### Goal understanding
The plan extends the shared planner with a GitHub daily work ledger that carries unfinished work across devices. It combines assignments, PR follow-ups, and earlier operators' checkout claims before recommending work. Forge, vendored, and plain GitHub repositories must work without a weekly baseline. Publishing is explicit and attributed to an authenticated operator; Rebalance `/daily` stays separate. The goal remains clear.

### Verdict: Changes Requested
The Round 1 P1 ingestion/authorship finding is addressed in the plan: marker/date validation, author matching, explicit trusted delegation, and unconditional PATCH author ownership are specified. Clean tracked worktree enumeration and target-root-pinned `tick claims --json` also address the missing inventory direction. Two P2 corrections remain before implementation:

1. **[P2] Prior-ledger discovery still cannot establish completeness** — plan lines 84–87. The fallback runs only when none of the 100 results precedes today or all 100 share one prior date. With one issue for today and 100 duplicates for yesterday, the first page contains today plus 99 yesterday issues: neither fallback condition fires, and yesterday's oldest/canonical issue and its comments are omitted. More generally, sorting creation time does not prove the maximum title date: recently backfilled older ledgers can hide a newer title date beyond the first page. Paginate whenever the bounded history result may be incomplete, or specify another query strategy that proves both the latest prior title date and completeness of that date's duplicates. Preserve fail-closed handling if completeness cannot be established. Add a manual control for the mixed-page duplicate case (one today + 100 yesterday) and for backfilled dates; a simple >100 sequential-days control does not cover this failure.
   - Evidence: `nl -ba PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md | sed -n '76,96p'` exited 0. Line 84 specifies the two limited fallback conditions; line 87 promises title-date ordering and comments across all prior-date duplicates. The counterexample follows from these specified inputs; no GitHub request or fixture was executed.

2. **[P2] Remove the parallel Python coordination-state replay fallback** — plan line 78. `tick claims --json` already uses the canonical strict event reader and fold. Reimplementing that fold in the planner after the canonical command fails can turn a deliberate unreadable/corrupt-state refusal into misleading checkout claims, and requires duplicating epoch fencing, authorized terminals, and scope changes. Keep the pinned read-only claims command as the owner; if unavailable or failed, report local-claim coverage as unavailable/failed and continue with explicitly incomplete calibration. If needed, use an installed absolute tick binary with the target root pinned. Do not introduce a second event-state interpreter. Add a control that a failed claims command yields a visible coverage gap rather than an empty/verified claim set.
   - Evidence: `sed -n '403,461p' bin/tick; sed -n '74,105p' src/project.js; sed -n '145,180p' src/project.js` exited 0. `claims` calls `fold(readAllEvents(root, { strict: true }))`, returns 3 for unreadable events, and explicitly avoids STATE.md writes. The fold chooses the highest live epoch, fences releases by agent/epoch, and seals authorized terminal events. Line 78 instead proposes an independent Python replay of selected event types; `task.scope_changed` is absent from that list.

### Nonblocking accuracy notes and verification limits
`get_open_prs` currently defaults to **300**, not 100 (`sed -n '326,345p' skills/3-weekly/weekly-planner/scripts/planner_core.py`, exit 0: `limit: int = 300`; `rg -n 'get_open_prs\(' skills/3-weekly/weekly-planner/scripts/planner_core.py`, exit 0: main calls it without a limit). Marking >=100 truncated is conservative but needlessly degrades coverage at 100–299 PRs; use the actual requested cap or explicitly pass 100 for ledger mode. Also clarify the publication bullet's unconditional mismatch-refusal wording to accommodate its explicit trusted-bot POST exception consistently with Acceptance. These are implementation clarifications, not additional blockers.

Source inspection only. No git commands, gates, pytest, executable fixtures, or implementation writes were run. Runtime controls remain **[Unverified — needs clone run]**. Only this relay file was edited. Return to claude for the two bounded plan corrections; no P0/P1 finding remains from this round.


---

## Round 3 — Producer (claude)

### Summary of Revisions
Applied both remaining `[P2]` corrections and both nonblocking accuracy notes in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md`:

1. **[P2] Unconditional pagination on full 100-row discovery pages (`find_or_create_daily_ledger_issue`):**
   - Whenever the initial 100-row `gh issue list` page is full (`len == 100`), discovery now **unconditionally paginates to completeness** via `gh api --paginate --slurp 'repos/<slug>/issues?state=all&per_page=100'` (filtering exact regex `^Daily Work Ledger — (\d{4}-\d{2}-\d{2})$` across all pages). This guarantees both the true maximum `parsed_date < date_local` (even when older dates were backfilled more recently) and completeness of all duplicate issues for that prior date (including the `1 today + 100 yesterday` mixed-page case).
   - Added explicit Acceptance controls for the `1 today + 100 yesterday` mixed-page duplicate case and for backfilled dates.

2. **[P2] Removed the parallel Python `.tick/events` replay fallback (`scan_local_checkout`):**
   - Kept `TICK_REPO_ROOT=<repo_root> <tick_bin> claims --json` (resolving `<repo_root>/bin/tick`, `<repo_root>/.xyz/bin/tick`, or the harness's installed `bin/tick` relative to `planner_core.py`) as the sole canonical owner of `.tick` claims.
   - If `<repo_root>/.tick/events` exists and `<tick_bin>` is unavailable or `tick claims --json` exits non-zero (e.g. exit 3 on corrupt/unreadable JSONL), `coverage["tick_claims"]` records `"failed"` / `"unavailable"` with a visible warning rather than reimplementing `.tick` event folding in Python or reporting an `ok` empty claim set. Added the corresponding Acceptance negative control.

3. **Nonblocking accuracy notes:**
   - Updated `open_prs` truncation threshold to `len(prs) >= 300` (matching `get_open_prs` `limit: int = 300` at `planner_core.py:326-345`).
   - Clarified the publication `POST` trusted-bot exception wording to match Acceptance (`--allow-delegate-comment` + `auth_login` in `trusted_bots` for first-time `POST`/issue creation; `PATCH` unconditionally requires `comment.user.login == auth_login`).

### Questions for Reviewer (codex)
All P1 and P2 findings have been resolved in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md`. Please verify and set `STATUS: Approved` (`tick done gh1459-plan-qa --agent codex --relay-file relay-system/2026-11-13/gh1459-plan-qa.md`) if ready for implementation.


## Round 3 — Reviewer (codex)

### Goal understanding
The plan adds a shared daily GitHub ledger to the existing planner engine so operators can resume unfinished work across devices and coordinate task pickup. It combines prior-day carryover, assignments, PR follow-ups, and attributed checkout signals without requiring a weekly baseline. Forge, vendored, and plain GitHub repositories use the same engine. Publishing remains explicit, and Rebalance's `/daily` remains separate. The goal is clear.

### Verdict: Approved for implementation
Both remaining P2 findings are addressed. A full initial history page now triggers unconditional pagination of the repository issues endpoint, with exact title filtering and parsed-date ordering; this closes the mixed-page duplicate and backfilled-date counterexamples. The canonical pinned `tick claims --json` command is now the sole coordination-state reader, and unavailable/failed reads surface coverage gaps. The acceptance criteria explicitly include both discovery counterexamples and the failed-claims negative control. The PR cap now matches the existing 300 default, and the publication contract states the trusted-bot first-POST exception while retaining unconditional PATCH ownership.

Evidence: `sed -n '112,180p' PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md; sed -n '326,345p' skills/3-weekly/weekly-planner/scripts/planner_core.py; sed -n '403,461p' bin/tick; rg -n 'TAKE YOUR TURN|REVIEWER|phase gate' relay-system/2026-11-13/gh1459-plan-qa.md` exited 0. Decisive output: Acceptance names “1 today issue + 100 yesterday duplicate issues” and a backfilled older ledger; failed claims must record `coverage.tick_claims.status` as `failed`; source defines `get_open_prs(... limit: int = 300)` and claims uses `fold(readAllEvents(root, { strict: true }))` without snapshot writes. The Plan discovery bullets also explicitly require full-page pagination and failure refusal.

No P0/P1/P2 blocker remains. Implementation should normalize REST issue fields (`created_at`, `user`) to the planner's `gh issue list` field shape (`createdAt`, `author`) when combining paginated discovery results, and retain fail-closed treatment if today's exact-date lookup remains truncated. These are ordinary implementation details within the approved contract.

### Verification limits / handoff
This approves the plan, not runtime behavior. Runtime controls and gates remain **[Unverified — needs clone run]** and belong to the specified disposable full clone. No git commands, gates, pytest, executable fixtures, or implementation writes were run. Only this relay file was edited; temporary storage was initialized under `.relay-scratch/tmp`. Close the token with `done` and proceed to implementation under the approved plan.
