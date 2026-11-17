# RELAY · GH-1498 pr-minder final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
- Reviewer: codex   ·   Producer: claude-a
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

### Reviewer · Round 1 (codex)

VERDICT: FAIL
Basis: Block. Observed no-write violations and narrower delivery/evidence gaps prevent approval.
swept file: yes

Evidence boundary: read the whole seeded issue, approved plan/plan-QA history, pr_minder.py, SKILL.md, manual driver/results, smoke and gate receipts. Reviewed changed planner clock/collector/production wiring and merge-cleanup refresh/hold/import seams. The two large existing modules were not exhaustively audited; no additional pre-existing defect was established in those bounded seams. Verify-tier graph discovery returned no matching symbols and no project for this worktree. Primary-checkout XYZ-forge generation is 2026-09-01T15:54:30Z; coverage reports new paths missing and existing Python paths not tracked. Material evidence therefore uses direct worktree source.

Probe ledger: two narrow commands invoked as "export PYTHONDONTWRITEBYTECODE=1 TMPDIR=.../.relay-scratch/tmp; python3 -" both exited 0. Inline Python imported pr_minder, replaced gh/refresh/owned_comment/receipts with in-memory functions and called plan_bundle/apply_row. No real writer was reachable. A TemporaryDirectory under that TMPDIR contained the bundle-layout probe. Decisive outputs appear below. No Git command, gate, executable fixture, network call or source/artifact edit was run.

- [Blocker] **F1 — report-only plans remove labels.** pr_minder.py:214–220 returns label=None for unknown/inherited-held rows; :283–288 interprets it as removal. Refresh checks only the current PR and cannot rescue unknown history or an inherited hold. Probe outputs for both cases were "calls= [['pr', 'edit', '1', '--remove-label', 'pr-minder:stale']]". Honor the row-level no-write decision before constructing operations, separately from fresh cleanup. A3/A11 currently omit existing owned labels (manual_check.py.txt:239–244,463–466).
  Observed input: open PR #1, head old, base development, label pr-minder:stale; separately unknown=True and inherited_hold="stacked on held #2", without a hold on #1 itself.
  Affected scope: every write to unknown PRs or descendants of held PRs (issue :49,53,99).
  Falsifier: both labelled inputs produce zero writes; a complete, unheld fresh PR with a proven owned label still clears it.

- [Should] **F2 — label namespace replaces ownership.** pr_minder.py:280–288 removes matching names without evidence the tool added them. Empty receipt history plus a pre-existing pr-minder:stale label produced the same remove-label call. Issue :78 promises removal only of labels pr-minder added; SKILL.md:60 silently substitutes a namespace. Establish ownership from the existing successful add/remove receipts and preserve unproven ownership.
  Observed input: fresh open PR #1 already carries pr-minder:stale; receipt history is empty.
  Affected scope: removing the two named labels from PRs on which another actor added them.
  Falsifier: that input retains the label; a successful owned-add receipt permits cleanup, while foreign stale remains untouched.

- [Should] **F3 — failed sync drops the fallback comment and rung-2 label.** pr_minder.py:259–260 plans no comment, then :344–345 breaks on sync failure before later operations. For rung 2, no labels and update return code 1, probe result was "['update-branch:failed']"; only update-branch/head-read calls occurred. Issue :77 requires a failure comment. Render that diagnosis and complete the appropriate non-branch bundle when safe, without retrying the mutation. Also check the head-read return code before treating its stdout as successful evidence (:326–329).
  Observed input: open clean-behind PR #1 at rung 2, no labels, no skip condition; update returns 1 with "forced failure".
  Affected scope: failed/uncertain sync outcomes at rungs 1–2 and subsequent label/comment operations.
  Falsifier: failed sync yields the failure comment and appropriate rung-2 label with accurate receipts, never a second branch mutation; successful sync remains idempotent.

- [Should] **F4 — label creation is an unaccounted write.** pr_minder.py:321–342 wraps label create --force and pr edit in one add-label receipt pair and ignores creation failure. Probe output: "successful rung2 write verbs: [['label','create'], ['pr','edit'], ['api','-X']]"; receipts had only intent/result add-label and intent/result comment. Record creation and its outcome separately. A10 compares receipts only to themselves (manual_check.py.txt:433–443); compare actual shim write calls to receipts.
  Observed input: rung-2 conflicting PR #1, no labels, differing owned comment #42, all fake calls successful.
  Affected scope: every actual GitHub write, including repository-label creation/update (issue :58,105).
  Falsifier: three writes have three attributable intent/result pairs; forced label-creation failure is recorded truthfully.

- [Should] **F5 — author reset leaves the old comment.** pr_minder.py:226–228 returns before rendering a reset; :290 never looks up the existing comment without a planned body. Fresh input with owned comment #42 containing the marker and "old rung 3 diagnosis" produced "calls=[] comment=None". Update that existing diagnosis as issue :79 requires; avoid creating comments on never-managed fresh PRs.
  Observed input: complete fresh open PR #1, no labels, existing owned comment #42 with an old rung-3 diagnosis.
  Affected scope: reset of an already managed PR's owned comment.
  Falsifier: PATCH the existing comment to fresh/reset once; immediate rerun writes nothing; never-managed fresh PR gets no comment.

- [Should] **F6 — flat installed bundle resolution fails.** Both roots at pr_minder.py:29 are equal: HERE.parents[2] and HERE.parents[1].parent. For skills/pr-minder/scripts the fallback looks outside skills. Scratch probe created sibling skills/weekly-planner/scripts, but _bundle exited "cannot find weekly-planner/scripts"; "expected flat bundle exists: True". Correct the sibling root for both dependencies.
  Observed input: the documented flat sibling layout (SKILL.md:23–27), directories present, no env override.
  Affected scope: flat-install startup of weekly-planner and merge-cleanup dependencies.
  Falsifier: both siblings resolve; repository layout and explicit absolute overrides still work.

- [Should] **F7 — conflict diagnostics omit promised data.** pr_minder.py:233 lists files without measured base-commit drift; :238–239 always emits a generic re-cut suggestion without the actual cherry-pick list/diff sizing required by issue :67,69. This is separate from the accepted first-error-line deviation. Render measured drift and PR-specific re-cut information, or record an explicit scoped specification disposition.
  Observed input: conflicting rung-3 PR #1, drift 803, conflict_files=['a.py']; the literal :238–239 template contains no drift count, concrete commits or diff size.
  Affected scope: conflicting rung-1 diagnostics and rung-3 re-cut descriptions.
  Falsifier: comments show the actual drift and concrete commit/diff information sufficient to size that PR's re-cut, with unavailable reads disclosed.

- [Should] **F8 — two rejection claims miss their named scenario.** A8b good uses rename-head (manual_check.py.txt:402), but bad hardcodes fix/new and runs maint (:392–397), whose headline uses fix/x. It rejects a mismatch even without a rename. A5/A6 merely seed sync/marker history (:278–284) and read it; they never apply the label/comment/sync bundle then re-read its effects, as issue :101 requests. Correct both in the existing manual driver; retain accurate logs/provenance, without a new suite.
  Observed input: bad A8b calls plans(a8_env("maint")); A5 calls only plans(a5_env()) at :292.
  Affected scope: rename red control and shared-age-after-own-writes evidence.
  Falsifier: the bad predicate handles the original name but fails the renamed same-OID case; a stateful shim apply followed by both production readers retains the original author date.

- [Pass] **Shared clock and fail-open planner wiring.** Name-independent maintenance/receipt predicates are at planner_core.py:1283–1290; completeness/latest activity is at :1293–1329. Production catches fetch failures into coverage and passes an empty activity mapping for numbered updatedAt fallback (:1811–1818,1845–1846; collector/disclosure :1614–1619,1685–1690). A6 reaches the production entry (manual_check.py.txt:305–334). The accepted human-sync heuristic and check-name/link deviations remain disclosed (SKILL.md:34–39,64–65). Refresh includes body (merge_cleanup.py:505–506); pre-bundle state/head/base/full-own-hold checks exist (pr_minder.py:299–317). Plan :83 says before each write, whereas code/SKILL.md:69 refresh once per bundle: disposition this additional timing divergence explicitly.

- [Pass] **Reuse, bounded actions and non-goals.** In the entire pr_minder.py, apply_row (:278–346) is the new remediation writer; existing owners are imported/reused (:36–37,100–121). No landing/close/rebase/force-push/retarget/ledger invocation appears in that file. Stack inheritance/cycle guard is at :191–205, cap at :251–254, kill switch at :415–417, plan-only return at :413–414. POST/PATCH selection and same-body suppression exist (:272–275,290–293,337–340), subject to F5. No duplicate landing subsystem or new test/registry entry was identified in the stated changed-file surface. The envelope warrants no daemon, lock or journal framework.

- [Unverified — needs clone run] **Acceptance and gates.** The recorded 13/13 is narrower than all issue checkboxes: A2 measures plans (:204–220), A3/A11 lack already-managed labels, A8 omits reset comments, A10 omits actual write-count matching. A4/A7/A9/A12 have meaningful bounded recorded inputs (manual_check.py.txt:262–274,338–358,407–429,487–494). gate.log:4–7,12–20 summarizes publisher 4/4 and ci-local rc=0 at c8ca1ccd6; it is not a retained full validate transcript, and no gate was rerun here. Final changed code needs the disposable-clone harness gate and current provenance. Rating 55/40/50/45 remains a defensible planning judgment (plan :123–129), not a measured result; historical 9/12 and effort were not independently remeasured.

Root cause: no-action representation is reused as cleanup, ownership is inferred from names, and manual scenarios omit managed/failure/installed inputs; Fix site: existing plan/apply boundary, receipts, resolver and manual driver; Why not upstream/downstream: readers supply these inputs correctly; extra orchestration would not fix interpretation.

Handing off to Producer (claude-a) — disposition F1–F8, correct implementation/manual evidence, and open Round 2. Go to the Producer window and say 'take your turn'. The harness owns the relay-file commit.

### Producer · Round 2 (claude-a)

All eight findings are implemented. Code commit: `326b47088`.

- **F1 — Implemented.** `plan_bundle` now returns `write: False` for held, stacked-on-held, unknown and rung-4 rows. `apply_row` returns before building any operation, so there is no label cleanup either (`pr_minder.py` `apply_row` first lines). A3 now gives every held or stacked PR an **owned** `pr-minder:stale` label at a fresh age, so the label would be cleared if the guard were missing. A11 does the same for the unknown PR.
- **F2 — Implemented.** The new `Receipts.owned_labels(pr)` replays `ok` add-label/remove-label receipts, and a label is removed only if it is in that set. New A13: an unowned label is kept, and an owned one on a fresh PR is cleared. Its bad candidate infers ownership from the label name and fails. SKILL.md now states the rule: a label added by hand, or from another device, is kept.
- **F3 — Implemented.** At rungs 1–2, a behind PR's bundle carries a `fallback` diagnosis. If `update-branch` fails or comes back uncertain, label and comment operations still run, and the failure comment is posted. The mutation is never retried. The head re-read return code is checked: a failed re-read is `uncertain`, never `ok`. New A14: one sync attempt, label added, failure diagnosis commented. Its bad candidate removes the fallback and fails.
- **F4 — Implemented.** Label creation is its own operation with its own intent/result pair. If creation fails, the add is skipped and the failure is recorded. A10 now checks that the shim's write count equals the non-bundle result receipts, and adds a forced `label create` failure. New A10b: folding creation into add-label (the old shape) fails.
- **F5 — Implemented.** `assess` sets `has_owned_comment` from the marker comments in the activity history. At rung 0 a managed PR gets its owned comment PATCHed to "rung 0 (fresh)… No action needed". An unmanaged fresh PR gets no comment. New A15: one PATCH, the rerun makes no writes, and the unmanaged PR stays untouched. Its bad candidate ignores the existing comment and fails.
- **F6 — Implemented.** The flat candidate is now `HERE.parents[1] / rel_flat` (with a comment). New A16 copies the three skills into a temp flat `skills/<name>/scripts` layout and runs `--help` with no env override: rc 0. The pre-fix resolver fails.
- **F7 — Implemented.** Conflict comments now state the measured drift ("Base has moved N commits since this branch's merge base", or "Base drift unknown"). The rung-3 re-cut names the PR's own non-maintenance commits (oid + headline, newest 10, marked if truncated) and the diff size from `files`. New render check A12b.
- **F8 — Implemented.** A8b's bad predicate is now bound to the current head name. It handles the original name (`maint`, `fix/x`) and fails on the same-OID renamed case (`rename-head`, `fix/new`). A5/A6 now **apply** first: label and comment on #40, update-branch on #41. The fake `gh` appends the server sync commit and the marker comment to the history and bumps `updatedAt`. Then both readers re-read: pr-minder ages 20d/5d, and the real `planner_core.py --mode stalled` report shows the 20d/5d dates, with the fallback disclosure naming #40 and #41 on a history error.
- **Refresh timing — Disposition.** The plan said "before each write", but the code refreshes once per PR bundle and then runs its 1–4 writes back to back. That is accepted and recorded in the plan as "Timing disposition (final QA r1)". The window is seconds, and A9 covers a change between measure and bundle. SKILL.md says the same.

Evidence: `manual-check.log` is 19/19 PASS, with every bad candidate rejected. The A10 fixture also surfaced a driver bug: each fake env overwrote process-wide environment variables, so a second env redirected the first env's receipts. `Env.activate()` now re-points them per call. That was a manual-driver fix, not product code. The smoke and gate at `326b47088` are in progress. GitHub's GraphQL limit was briefly exhausted by other sessions, so the real-repo smoke re-runs after the reset. The gate is re-running in the disposable clone. Both are appended before handoff.

**Evidence update (before handoff):**
- Gate re-run at `326b47088`: publisher suites 4/4, `ci-local` rc=0 (`gate.log`, `.gate-evidence/326b4708.txt`).
- `07538331d`: on an open-PR read failure (for example a GitHub rate limit), pr-minder now exits rc 2 with a one-line message and no writes, instead of a traceback. This was observed live while GraphQL was refusing calls. Manual check still 19/19.
- Smoke re-recorded at `07538331d` (`smoke-plan-mode.log`): rc 0 twice, 14 open PRs.
- A final gate will run on the approved head.

Handing off to Reviewer (codex) for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
