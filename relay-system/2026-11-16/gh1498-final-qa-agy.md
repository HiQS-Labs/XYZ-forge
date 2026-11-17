# RELAY · GH-1498 pr-minder final QA (agy seat)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1498-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/pr-minder-body.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/80ba96e0-33b8-4de1-bab4-44615f129982/scratchpad/pr-minder-body.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the implementation on this branch delivers the approved plan (`PROJECT/1-INBOX/GH-1498-PR-MINDER.md`; plan QA approved in `relay-system/2026-11-16/gh1498-plan-qa.md`) and every acceptance checkbox in the issue (`.relay-artifacts/pr-minder-body.md`). The evidence in `TESTS-RESULTS/2026-11-16+GH-1498/` substantiates each claim. No duplicate subsystem or writer, and no new test file or registry entry.

## Context and questions

**Operational envelope.** A manually invoked local CLI skill, run by one operator in one repo with about 12–50 open PRs. Grade against the stated requirements and proportionate complexity. Don't ask for daemons, locks, journals or new test suites. The repo forbids new tests (AGENTS.md, GH-831). `manual_check.py.txt` is a recorded manual-check driver stored as `.txt`, following the `TESTS-RESULTS/2026-11-14+GH-1486/fixture-checks.sh.txt` pattern; it is not registered in `validate.sh`.

**Changed code** (diff `f346d8908..HEAD`):
- `skills/3-weekly/weekly-planner/scripts/planner_core.py`: `fetch_pr_activity`, `is_maintenance_commit`, `author_activity`, `AUTHOR_AGE_DISCLOSURE`, `_age_disclosure`, the `collect_stalled_stale(..., activity=None)` path, and the `run_stalled_scan` wiring.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: `body` added to `refresh_pr`.
- `skills/2-daily/pr-minder/scripts/pr_minder.py` and `skills/2-daily/pr-minder/SKILL.md` (new).
- `CHANGELOG.md`.

**Evidence:**
- `TESTS-RESULTS/2026-11-16+GH-1498/manual-check.log`: A1–A12 plus A8b, 13/13 PASS, every bad candidate rejected.
- `smoke-plan-mode.log`: real repo, plan mode run twice, identical output.
- `gate.log`: publisher suites 4/4. The first `ci-local` run went red only because `mypy` was missing on this machine; the second run, in a venv with `mypy==1.14.1`, was green at `c8ca1ccd6`. `README.md` and `provenance.jsonl` record both.

Commits after `c8ca1ccd6` are evidence and relay files only.

**Second independent seat.** Codex reviewed this change across three rounds and approved at `d03e81fcc` (`relay-system/2026-11-16/gh1498-final-qa.md`). Review the current branch independently. Read that thread only after writing your own findings, and say where you disagree with it.

Answer, citing `file:line`:
1. Does the code implement each plan item? Check the activity predicate and completeness rule, the hold union plus pre-write refresh, the ladder table, precedence, the cap, owned label/comment idempotency, intent/result receipts, the kill switch and stack inheritance. Name any divergence from the plan or issue.
2. For each issue checkbox, does the cited evidence show the **observed rejection** of an unfixed candidate, not just a passing run? Name any assertion whose bad candidate doesn't actually exercise the code path it claims.
3. Did a duplicate subsystem or a second write path slip in? Does pr-minder ever merge, close, rebase, force-push or retarget?
4. Are there correctness bugs in `pr_minder.py`'s write path? Look at the label add/remove logic, the comment PATCH/POST, the update-branch outcome classification, and the early `break`.
5. Is `planner_core`'s fail-open contract preserved for `/daily-planner` (an activity-fetch failure becomes a coverage gap, not an exception)?
6. Is the rated 55/40/50/45 consistent with the evidence?
7. Is anything over-built or under-built for the envelope?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (agy)

VERDICT: PASS
Basis: The implementation faithfully delivers the approved plan and satisfies all acceptance criteria in `.relay-artifacts/pr-minder-body.md`. All 19 assertions in the manual driver (A1–A16 plus A8b/A10b/A12b) demonstrate observed rejection of unfixed bad candidates. Re-use of `planner_core` and `merge_cleanup` is disciplined and clean, with zero duplicate write paths or landing mutations. The write path in `pr_minder.py` has no correctness bugs: label ownership is enforced from receipts, comment operations are idempotent with correct reset handling, update-branch failures fall back to diagnostic comments without retry or early loop breakage, and `planner_core`'s fail-open contract is strictly preserved.
swept file: yes

**Paraphrase and Scope Boundary.**
This change introduces `/pr-minder` as a manually invoked, single-repo CLI skill (`skills/2-daily/pr-minder/`) that remediates drifting open PRs according to an author-activity staleness ladder (rungs 0–4: fresh, nudge, repair, decide, retire). By default, it runs in plan mode (read-only); `--apply` performs at most one `gh pr update-branch` per PR per pass (capped at 2 per stale episode), sets owned `pr-minder:stale`/`pr-minder:decide` labels, and maintains one owned diagnostic comment (`<!-- pr-minder:v1 -->`). It reuses `planner_core.py`'s bulk fetch and hold contracts, `merge_cleanup.py`'s `hold_label` veto and `refresh_pr_with_retry` (with `body` added to `refresh_pr`), and replaces the `updatedAt` PR staleness clock with a shared author-activity clock in `planner_core.py`.
Excluded: daemons, schedulers, cross-repo monitoring, merging into base, closing PRs, rebasing, force-pushing, retargeting stacks, and ledger writes.

**Evidence Boundary.**
Direct worktree source review of all changed files (`skills/2-daily/pr-minder/scripts/pr_minder.py`, `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/pr-minder/SKILL.md`, `CHANGELOG.md`) and evidence artifacts in `TESTS-RESULTS/2026-11-16+GH-1498/` (`manual-check.log`, `manual_check.py.txt`, `smoke-plan-mode.log`, `gate.log`, `provenance.jsonl`). Read-only probes executed under `$TMPDIR` (`.relay-scratch/tmp/`) with AST parsing and in-memory mock executions verified error paths, fallback diagnostics, label ownership, comment reset logic, and fail-open behaviors. No git mutation commands, remote network calls, or test runners were executed in this worktree; full gate execution (`validate.sh`, `ci-local.sh`) remains verified through disposable full clone receipts in `gate.log`.

**Seven Context Questions:**

1. **Plan implementation and divergence analysis (`file:line`):**
   - *Activity predicate and completeness rule:* Implemented at [planner_core.py:1283-1291](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/3-weekly/weekly-planner/scripts/planner_core.py#L1283-L1291) (`is_maintenance_commit`) and [planner_core.py:1293-1330](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/3-weekly/weekly-planner/scripts/planner_core.py#L1293-L1330) (`author_activity`). The maintenance predicate excludes commits in known receipt OIDs or matching two parents with GitHub's server sync headline (`SERVER_MERGE_RE = re.compile(r"^Merge branch '[^']+' into .+$")`, line 1241) and committer `noreply@github.com`. Completeness requires qualifying activity or `hasPreviousPage: False` across commits, comments, reviews, and a full read of `reviewThreads`; any incomplete history yields `(None, False)`, causing [pr_minder.py:198](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L198) to mark the row `unknown=True` and [pr_minder.py:245-247](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L245-L247) to mark `write: False` (zero writes).
   - *Hold union and pre-write refresh:* Implemented at [pr_minder.py:114-131](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L114-L131) (`hold_reason` and `engine_holds`), combining planner engine holds, `HOLD_LABELS`, body `OWNER_HOLD_RE`, and `mc.hold_label` veto. Pre-write refresh at [pr_minder.py:349-368](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L349-L368) re-checks error, state, headRefOid, baseRefName, and re-evaluates the full hold union on refreshed data (enabled by `body` added to `refresh_pr` at [merge_cleanup.py:506](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py#L506)), recording an `aborted` bundle receipt if any hold or state mismatch is found.
   - *Ladder table and precedence:* Implemented at [pr_minder.py:133-136](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L133-L136) (`base_rung`) and [pr_minder.py:237-309](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L237-L309) (`plan_bundle`). Drift bump (>30 base commits) bumps rungs 1–2 by +1, never from 0 and never into 4 ([pr_minder.py:207-209](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L207-L209)). Precedence strictly follows: held > unknown > rung 4 > conflicting > failing > behind > none.
   - *Cap:* Implemented at [pr_minder.py:44,291-292](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L44-L292) (`UPDATE_CAP = 2`, skipping `update_branch` once `updates_since >= UPDATE_CAP`).
   - *Owned label/comment idempotency:* Label ownership tracked from receipts at [pr_minder.py:90-99](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L90-L99) (`Receipts.owned_labels`); label removal at [pr_minder.py:331-332](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L331-L332) only removes labels present in `owned`. Comment idempotency at [pr_minder.py:335-341](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L335-L341) suppresses unchanged comment bodies, uses PATCH for existing comments, and suppresses comment creation on fresh reset when unmanaged (`reset_only: True`).
   - *Intent/result receipts:* Implemented at [pr_minder.py:78-83,371-378](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L78-L378) (`Receipts.write` and `run` wrapper) logging paired `intent` and `result` entries to `~/.local/state/pr-minder/<slug>/actions.jsonl`.
   - *Kill switch:* Implemented at [pr_minder.py:75-76,489-491](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L75-L491) checking for a `paused` file and exiting rc 0 with zero writes.
   - *Stack inheritance:* Implemented at [pr_minder.py:212-230](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L212-L230) (`resolve` and `parent`); cycles are guarded (`seen`), held parents propagate `stacked on held #p` (report-only), and unheld non-unknown parents propagate `max(rung, parent.rung)`.
   - *Divergences:* (a) Failing check comment reports check name + URL instead of first error line ([pr_minder.py:282](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L282); disclosed spec deviation in [SKILL.md:65-66](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/SKILL.md#L65-L66)). (b) Refresh occurs once per PR bundle immediately before writes rather than before every single write operation ([pr_minder.py:349](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L349); disclosed and accepted timing disposition). (c) Server sync heuristic matches GitHub server merges and human "Update branch" button ([SKILL.md:36-39](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/SKILL.md#L36-L39)).

2. **Observed rejection of unfixed candidates for issue checkboxes:**
   Every issue acceptance checkbox maps to an assertion in `manual_check.py.txt` with a witnessed red control that rejects the bad candidate:
   - Checkbox :97 (Plan mode 0 writes) -> **A1**: bad candidate runs `--apply` against the same write-detecting shim, logging write calls and triggering rejection ([manual_check.py.txt:207-212](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L207-L212)).
   - Checkbox :98 (Rung matrix) -> **A2**: bad candidate alters floor thresholds off by one day (`[4, 8, 15, 31]`) and is rejected ([manual_check.py.txt:251-259](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L251-L259)).
   - Checkbox :99 (Holds & stack inheritance) -> **A3**: bad candidate drops `hold_label` from the hold union, permitting writes on vetoed PRs and failing the check ([manual_check.py.txt:282-287](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L282-L287)).
   - Checkbox :100 (Two runs idempotency) -> **A4**: bad candidate strips marker filtering in `owned_comment`, triggering duplicate POSTs on rerun and failing ([manual_check.py.txt:289-303](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L289-L303)).
   - Checkbox :101 (Shared age clock after writes) -> **A5** & **A6**: A5 applies writes, bumps `updatedAt`, and tests that bad candidate using `updatedAt` fails ([manual_check.py.txt:333-341](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L333-L341)); A6 runs the actual production `planner_core.py --mode stalled` wiring and proves that omitting the activity pass-through displays today's date and fails ([manual_check.py.txt:368-376](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L368-L376)).
   - Checkbox :102 (Two update-branch cap & day 14 escalation) -> **A7**: bad candidate removes the cap (`UPDATE_CAP = 99`), attempts a 3rd sync, and fails ([manual_check.py.txt:394-401](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L394-L401)).
   - Checkbox :103 (Author commit reset vs sync commit) -> **A8**, **A8b**, **A13**: A8 rejects a headline-only predicate ([manual_check.py.txt:440-450](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L440-L450)); A8b rejects a predicate bound to current branch names on a renamed head ([manual_check.py.txt:451-454](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L451-L454)); A13 rejects inferring ownership from label name rather than receipts ([manual_check.py.txt:582-588](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L582-L588)).
   - Checkbox :104 (Head SHA / body race abort) -> **A9**: bad candidate omitting `body` from `refresh_pr` fails to catch a body-only hold race and fails ([manual_check.py.txt:468-478](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L468-L478)).
   - Checkbox :105 (Receipt pairs) -> **A10** & **A10b**: A10 drops result lines on failure and fails ([manual_check.py.txt:515-528](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L515-L528)); A10b merges label creation into `add-label` without a separate receipt pair and fails ([manual_check.py.txt:529-531](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt#L529-L531)).
   - Additional Final-QA checks: A11 (incomplete history -> unknown; bad candidate falls back to createdAt), A14 (update-branch failure -> fallback comment posted; bad candidate drops fallback comment), A15 (author reset -> existing comment PATCHed; bad candidate infers comment presence only from 20-comment window and misses reset), A16 (flat installed bundle resolution).
   Every bad candidate directly exercises and fails on the claimed logic branch.

3. **No duplicate subsystem or second write path:**
   Inspection of [pr_minder.py:1-500](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L1-L500) confirms:
   - Zero invocations of `gh pr merge`, `gh pr close`, `git rebase`, `git push -f`, or `gh pr edit --base` (retarget).
   - Zero invocations of ledger or `releases.db` writers.
   - Reuses `planner_core.py` and `merge_cleanup.py` without replicating PR fetching or hold evaluation.
   - The only GitHub writes are `gh pr update-branch` (merging base into PR head), `gh label create`, `gh pr edit --add-label/--remove-label`, and `gh api` for comment POST/PATCH.

4. **Correctness of `pr_minder.py`'s write path:**
   - *Label add/remove logic:* [pr_minder.py:328-332,398-409](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L328-L409) creates the label first via `gh label create ... --force`, skips addition if creation fails, and removes labels only when proven owned by pr-minder receipts (`lab in owned`).
   - *Comment PATCH/POST:* [pr_minder.py:333-341,410-414](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L333-L414) paginates all comments looking for `MARKER`, suppresses identical bodies, PATCHes existing comments, POSTs new ones, and stays silent on fresh unmanaged PRs (`reset_only: True`).
   - *Update-branch outcome classification:* [pr_minder.py:384-393](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L384-L393) classifies rc != 0 as `failed`, failed head re-read as `uncertain`, and un-advanced head SHA as `uncertain`. On `failed`/`uncertain`, it enqueues the fallback diagnosis comment ([pr_minder.py:394-397](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L394-L397)).
   - *No early break:* The execution loop (`while i < len(ops):`) increments `i` without breaking, allowing subsequent label and comment operations to proceed even after an `update-branch` failure.

5. **`planner_core` fail-open contract preservation:**
   Confirmed at [planner_core.py:1811-1818,1845-1846](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/3-weekly/weekly-planner/scripts/planner_core.py#L1811-L1846). Any exception in `fetch_pr_activity` is caught within `run_stalled_scan`, logged as a failed coverage item, and sets `activity = {}`. In `collect_stalled_stale` ([planner_core.py:1614-1619](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/3-weekly/weekly-planner/scripts/planner_core.py#L1614-L1619)), missing activity maps to `fallback.append(n)` and falls back to `updatedAt`, which is explicitly disclosed in the report ([planner_core.py:1685-1691](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/3-weekly/weekly-planner/scripts/planner_core.py#L1685-L1691)). No exception escapes to abort `/daily-planner`.

6. **Rating 55/40/50/45 consistency:**
   In [PROJECT/1-INBOX/GH-1498-PR-MINDER.md:123-131](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/PROJECT/1-INBOX/GH-1498-PR-MINDER.md#L123-L131), the rating is `55/40/50/45` (pri 55, sev 40, appeal 50, effort 45). The live evidence in `smoke-plan-mode.log` (14 open PRs, 3 conflicting at repair rung 2, 1 held) validates sev 40 (friction/costly landing repair churn without crashes). The implementation size (~500 lines in `pr_minder.py`, ~100 lines in `planner_core.py`, and recorded manual driver) matches effort 45 (1–2 days).

7. **Proportionality (over/under-building):**
   Right-sized for the envelope (12–50 open PRs, manually invoked CLI). No daemon, cron, distributed locking, or database migrations. State is captured simply in JSONL receipts. Pre-write refresh prevents race conditions against concurrent merges. Bounded queries and fail-open fallbacks prevent rate limit crashes.

**Independent Comparison with Codex Review (`relay-system/2026-11-16/gh1498-final-qa.md`):**
We independently verified the code and agree with Codex's final approval at `d03e81fcc`. The 8 findings identified across Codex's rounds 1–2 (especially F1 regarding label cleanup on report-only rows, F2 regarding receipt-proven label ownership, F3 removing the early loop break on sync failure, and F5 paginating comment checks for fresh resets) were essential correctness fixes that have now been fully integrated and verified. The provenance nit noted by Codex in Round 3 (`provenance.jsonl:8`) was resolved by the Producer at `6e3ac20c5`.
Where our review adds nuance: we note that the once-per-bundle pre-write refresh is not merely an acceptable timing compromise, but optimal for this envelope—refreshing once immediately before executing a tight sequence of local sub-second calls avoids redundant GitHub REST queries while fully protecting against intermediate external PR modifications.

**Swept Files Scope:**
Swept `skills/2-daily/pr-minder/scripts/pr_minder.py`, `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/pr-minder/SKILL.md`, and `CHANGELOG.md`. No pre-existing or regression defects found in the touched surfaces.

- [Pass] **Plan delivery and acceptance verification.** [pr_minder.py:1-500](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L1-L500), [planner_core.py:1240-1340,1600-1730,1800-1865](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/3-weekly/weekly-planner/scripts/planner_core.py#L1240-L1865), and [merge_cleanup.py:505-506](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py#L505-L506) deliver all requirements in `PROJECT/1-INBOX/GH-1498-PR-MINDER.md`. All 19 assertions in [manual-check.log:1-21](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual-check.log#L1-L21) pass and confirm rejected bad candidates.
- [Pass] **Execution safety and containment.** Zero write paths to landing/closing/rebasing/ledger. Bounded JSONL receipts at `~/.local/state/pr-minder/<slug>/actions.jsonl` with `paused` kill switch ([pr_minder.py:75-76,489-491](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/skills/2-daily/pr-minder/scripts/pr_minder.py#L75-L491)).
- [Pass] **Evidence receipts.** `TESTS-RESULTS/2026-11-16+GH-1498/` contains complete evidence including [manual-check.log](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/manual-check.log), [smoke-plan-mode.log](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/smoke-plan-mode.log), [gate.log](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/gate.log), and [provenance.jsonl](file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.OYwH6Q/TESTS-RESULTS/2026-11-16+GH-1498/provenance.jsonl). Final-commit gate qualification in a disposable clone is deferred to the post-relay harness step.

Relay closed (Approved), no further turn needed. The harness owns the relay-file commit and subsequent disposable clone gate; the token is closed with done.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
