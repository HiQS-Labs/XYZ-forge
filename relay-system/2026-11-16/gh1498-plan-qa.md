# RELAY · GH-1498 pr-minder plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1498-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: the plan in `PROJECT/1-INBOX/GH-1498-PR-MINDER.md` is safe to implement. It is grounded in the cited code, covers every acceptance checkbox in the issue body (`.relay-artifacts/pr-minder-body.md`), extends the existing writers rather than adding parallel ones, and its verification plan can actually reject an unfixed candidate.

## Context and questions

**Operational envelope.** A manually invoked local CLI skill, run by one operator in one repo with about 12–50 open PRs. Machinery and verification must stay proportionate. Don't ask for daemons, distributed locks, journaled recovery or new test suites. This repo forbids new tests (AGENTS.md *No new tests*, GH-831): verification uses existing suites plus a manual check recorded under `TESTS-RESULTS/`.

**Step A — paraphrase first (GH-1414).** Before opening the issue artifact or any source file, read ONLY `PROJECT/1-INBOX/GH-1498-PR-MINDER.md` and write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; separate excluded, deferred, and later-authorization items; label any inference)

State the input boundary you used for this step (plan doc only).

**Step B — source-backed validation.** Now read the issue (`.relay-artifacts/pr-minder-body.md`) and the cited code:
- `skills/3-weekly/weekly-planner/scripts/planner_core.py` (`get_open_prs` :326, `detect_merge_sequence` :346, `HOLD_LABELS` :1203, `AGE_DISCLOSURE` :1214, `_age_days` :1229, `collect_stalled_stale` :1500, the stalled wiring :1726 and :1869)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (imports :27–54, `refresh_pr` :501, `refresh_pr_with_retry` :516, `_protect_stacked_dependents` :553, `hold_label` :574)
- `skills/2-daily/daily-planner/SKILL.md:14`

Answer:
1. Are the plan's five recon findings true against the source? Pay particular attention to #2: identifying update-branch commits by the headline `Merge branch '<base>' into <head>` instead of by receipts. Is that sound, and what would it misclassify?
2. Does each issue acceptance checkbox map to a plan step with a check that would **reject an unchanged or unfixed candidate**? Name any checkbox with no observable rejection.
3. Does the plan extend the existing writers (planner_core's fetch and stalled path, merge_cleanup's hold and read helpers) without a duplicate subsystem or a second write path?
4. Is the "first error line → failing check name plus URL" ponytail disposition acceptable against the issue?
5. Is the planner adoption safe for `/daily-planner`'s existing fail-open contract (:1871–1876)? Is there any risk to the existing suites that cover planner_core?
6. Is anything over-built or under-built for the envelope above?

Cite `file:line` for every claim.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: the reuse direction is sound, but the clock and pre-write hold contracts are incomplete, and the acceptance map does not yet specify discriminating checks for every checkbox. These are plan corrections, not a request for more machinery.
swept file: yes

**Step A — plan-only paraphrase (recorded before opening issue/source).** Input boundary: only `PROJECT/1-INBOX/GH-1498-PR-MINDER.md`. This proposes a manually invoked, report-by-default PR remediation skill, with explicit apply managing branch sync, owned labels and an owned comment. A shared activity clock drives its stale ladder and the planner report. Per the document, planner_core already fetches PRs and reports stalled work; merge_cleanup supplies hold and refresh helpers. The document adds a separate history reader because enlarging the bulk query exceeded GitHub's node limit. Excluded: merging, closing, conflict resolution, daemons and queue dispatch. The plan explicitly names no additional deferred work beyond its exclusions; real-PR apply needs later authorization. The issue subsequently supplies the more detailed deferred and unauthorized lists at `.relay-artifacts/pr-minder-body.md:108–111`.

**Evidence boundary.** Verify-tier review of the entire plan and issue plus the cited source seams. Graph project `XYZ-forge` is ready but rooted in the primary checkout, generation `2026-09-01T15:54:30Z`; both list_projects pages were read, and this relay worktree has no indexed project. Exact symbol search returned zero (has_more=false). Coverage for both Python paths and daily-planner SKILL.md was freshness `not_tracked`, and the plan was `missing`. Therefore all material claims below use direct worktree source, not stale graph evidence. No gates, fixtures, Git commands or remote writes were run. Existing-suite compatibility remains [Unverified — needs clone run].

- [Should] **F1 — a headline is not sufficient evidence of a maintenance-only commit.** Plan `PROJECT/1-INBOX/GH-1498-PR-MINDER.md:37` discards every matching headline, regardless of author or structure. This can discard a normal single-parent author commit with that message, or a human conflict-resolution merge containing real repair work. It also misses maintenance merges whose message differs or whose branch was subsequently renamed/retargeted. Cross-device availability is a valid objection to receipt-only identification, but it does not prove this replacement sound. Fetch parent/tree evidence and define a conservative, portable maintenance predicate; ambiguous history should be unknown for writes. State explicitly whether ignoring human base-sync commits is an intentional spec change from issue `:45–49`, and record the accepted boundary.
  Observed input: plan `:37` says “ignores every commit with that headline”; concrete counterexample input is `{baseRefName: "development", headRefName: "fix/x", messageHeadline: "Merge branch 'development' into fix/x", parents: [oldHead], committedDate: "2026-11-16T12:00:00Z"}`. The specified predicate drops this author commit. This is a design counterexample, not an executed implementation failure.
  Affected scope: commits excluded from the shared activity clock in both consumers.
  Falsifier: the recorded manual check must retain this single-parent commit as activity while excluding a proven maintenance-only two-parent sync; also cover a conflict-resolution merge. A predicate already doing that would resolve this finding.

- [Should] **F2 — fetch the required activity kinds and define completeness per PR.** Plan `:36,54–55` requests commits, issue comments and review submissions, but never review comments, which issue `.relay-artifacts/pr-minder-body.md:46` explicitly counts. The two all-filtered-tail conditions are not a complete pagination/error contract. Add the review-comment read and either obtain enough history to establish the maximum qualifying activity or return unknown; keep PR-page pagination distinct from nested-history completeness. A small bounded fetch with a truthful unknown result is sufficient for this workload.
  Observed input: the exact connection list at plan `:36` is `commits(last:10), comments(last:20), reviews(last:5)`; an inline review comment today on a review submitted 20 days ago has no corresponding current event in those specified inputs.
  Affected scope: PR age, label reset and eligibility to write when activity is absent, truncated or partially failed.
  Falsifier: a manual case containing an old review submission and a new inline comment must reset age; missing pages/API data must produce unknown and zero pr-minder writes, not a createdAt-based stale action.

- [Should] **F3 — the reused refresh cannot recheck the complete hold contract.** Plan `:67` checks state, labels, head and base, but holds also depend on title/body (`planner_core.py:401–429,1205,1523`; `merge_cleanup.py:582–584`). `refresh_pr` fetches title but not body (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:504–505`). Extend the existing reader minimally to include body and re-evaluate the same full hold union before applying the bundle. Preserve the issue's requirement to abort on changed holds, not merely changed labels (`.relay-artifacts/pr-minder-body.md:57`).
  Observed input: a measured non-held PR followed by body `owner decision: hold`, with state/labels/head/base unchanged, passes the planned comparisons; the reused query cannot observe that line.
  Affected scope: pre-write authorization for held/evidence PRs, including title/body vetoes.
  Falsifier: the manual race case must change only that body line and observe zero writes plus an abort receipt; unchanged non-held input must still permit its eligible bundle.
  Probe (read-only, exit 0): `PYTHONDONTWRITEBYTECODE=1 python3 -` with `ast.parse(Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py").read_text())`, selecting the `refresh_pr` field-list constant and printing membership. Decisive output: `refresh_pr fields: number,state,isDraft,title,mergeable,headRefOid,headRefName,baseRefName,labels,mergeCommit,url`; `body fetched: False`. The same probe read the plan: `clock smoke accepts equality: True`; `review-comment connection specified: False`. No fixture or candidate code was executed.

- [Should] **F4 — replace the blanket acceptance map with observable rejection checks.** Plan `:57` accepts dates “at or before updatedAt”; the unchanged clock at `skills/3-weekly/weekly-planner/scripts/planner_core.py:1514–1516` produces equality and passes. The matrix at plan `:75–78` is useful but does not specify assertions for the central shared-clock, episode-cap, reset and per-write receipt acceptance items. Add these to the existing recorded manual check, with pinned expected outcomes and controlled bad inputs; do not create a test suite.
  Observed input: plan `:90` says every checkbox maps to steps 1–3, while `:57` accepts the existing updatedAt result and `:75–78` contains no post-maintenance dual-consumer age assertion, two-sync/14-day replay, author-reset replay or receipt-pair assertion.
  Affected scope: issue acceptance checkboxes `:97–106` and the plan's claim that an unfixed candidate is rejected.
  Falsifier: replay the cases below against a candidate deliberately using updatedAt, ignoring the cap, failing to reset labels, or omitting one result receipt; each respective assertion must fail.

  Acceptance audit (issue `.relay-artifacts/pr-minder-body.md`):
  | Checkbox | Plan mapping and rejection needed |
  |---|---|
  | :97 zero writes | Step 2 + manual shim; assert zero write verbs, then witness its write detector rejecting apply, not merely logging a positive write count. |
  | :98 rung matrix | Step 2/3 + matrix exists; assert exact actions, lower-bound/draft/drift behavior and report-only rung 4. |
  | :99 holds | Step 2 + held cases exist; enumerate all four hold sources and transitive held ancestor, assert zero writes. |
  | :100 idempotency | Step 3 + second run explicitly expects zero writes; shim must reflect first-run state. |
  | :101 shared age | Step 1; missing discriminating check. Make updatedAt recent through owned maintenance, keep qualifying activity old, assert exact original age/date in both consumers. |
  | :102 cap/escalation | Step 3; missing explicit replay. Two successful sync receipts, subsequent behind pass must not sync; advance to day 14 and assert rung 3. |
  | :103 author reset | Steps 1/3; missing explicit replay. New author commit resets rung/removes only owned labels; proven maintenance merge does neither. |
  | :104 race | Step 3 + SHA race assertion exists; explicitly assert abort receipt as well as zero writes. |
  | :105 receipts | Step 3 promises intent/result; missing log assertion for each actual write, including failed/uncertain outcomes. |
  | :106 gates | Disposable full-clone ci-local plus named publisher suites covers the requested gate intention; execution remains unverified here. |

- [Pass] **Recon #1/#3/#4/#5 and reuse direction, with limits.** `get_open_prs` really is the bulk metadata reader (`skills/3-weekly/weekly-planner/scripts/planner_core.py:326–343`); the reported GraphQL node-limit run itself is unverified because no retained receipt is cited in plan `:36`. A separate bounded history read, one clock beside `_age_days` (`:1229`) and one stalled-path adoption are coherent. Existing hold contracts are at `:401–429,1203–1205,1506–1524`; imports are at `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:27–62`; read retry is at `:516–531`. Read-only import probe, exit 0: `sys.path.insert(0, "skills/2-daily/merge-cleanup/scripts"); from merge_cleanup import hold_label, refresh_pr_with_retry; print("imports:", hold_label.__name__, refresh_pr_with_retry.__name__)` → `imports: hold_label refresh_pr_with_retry`. Stack predicate reuse at `:558–559` avoids calling the retarget writer at `:564`. No duplicate landing writer is proposed: the new action path syncs PR heads, while merge-cleanup continues owning landing (issue `:109`).

- [Pass] **Planner adoption is conceptually safe if fallback stays local to the stalled path.** Current fail-open handling is `skills/3-weekly/weekly-planner/scripts/planner_core.py:1865–1875`; both stalled and daily call `run_stalled_scan` (`:1892,1909`), which already accumulates coverage gaps (`:1690–1705`). Plan `:40` correctly preserves a report with disclosed updatedAt fallback and unchanged issue age (`:1555`). Do not let the new reader raise past that boundary or run it in unrelated modes. Preserve existing pure-collector callers with an optional activity input, and verify missing activity/fetch failure in the disposable clone. A shared-clock fallback disclosure must identify which PRs used updatedAt. Existing suite results are not claimed by this review.

- [Pass] **The failing-check URL disposition is proportionate, but is an explicit spec deviation.** Plan `:90` replaces issue `.relay-artifacts/pr-minder-body.md:67`'s first-error-line text with a check name and details URL. That is acceptable for this manually invoked 12–50 PR pass: it supplies an actionable diagnostic link without downloading job logs. Keep this disposition visible and verify the rendered name/link (with an explicit unavailable-link fallback), rather than claiming the original first-error-line requirement was implemented. The narrow script, owned comment and JSONL receipts fit the envelope (`plan :45,68–70`); no daemon, distributed lock or recovery journal is needed.

- [Nit] **Correct the claimed gate route.** Plan `:82` says the new skill script plus planner_core means full route. `utils/ci-route.sh:63–69` treats these unclaimed skill paths as docs, and `:382–383` excludes docs from tier escalation. Say that full ci-local is deliberately selected to meet issue acceptance, rather than claiming the router selects it. Its full registry intention is documented in `ci-local.sh:25–26,34–35`. Keep publisher suites explicit.

Pre-existing scope: the source's missing refresh body field is reported in F3 because the proposed caller relies on it. The existing updatedAt behavior is the known target of this work, not a new regression. No other pre-existing defect was established in the reviewed plan/issue or bounded source seams; this is not an exhaustive audit of the two large Python modules.

Handing off to Producer (claude-a) — address F1–F4, disposition the remaining notes, then return the revised plan for Round 2. Go to the Producer window and say 'take your turn'.

### Producer · Round 2 (claude-a)

Dispositions:

- **F1 — Implemented (modified).** Recon #2 now uses a conservative predicate. A commit counts as maintenance only if it has 2 parents, AND its headline is exactly `Merge branch '<base>' into <head>` for this PR, AND its committer email is `noreply@github.com`. Your single-parent counterexample now counts as activity (assertion A8 pins this). The human "Update branch" click is recorded as an **intentional spec change** with its boundary. A web-editor conflict resolution that keeps the default message is an **accepted** boundary. It errs toward escalating a rung early, the only writes are labels and a comment, and the PR comment discloses it. A conservative alternative was considered and not taken: re-merging to prove a clean merge would need local merge work on every commit, which is disproportionate here.
- **F2 — Implemented.** Added `reviewThreads(last:20){comments(last:1)}` and `reviews(last:10)`. Completeness is defined per connection: a connection is complete if it has at least one qualifying item OR `hasPreviousPage` is false. `reviewThreads` counts as complete only when `hasPreviousPage` is false. An incomplete connection or a GraphQL error gives `unknown`: no writes in pr-minder, and an `updatedAt` fallback in the planner with the PR numbers listed. The `createdAt` fallback applies only when every connection is complete and empty. Assertion A11 pins this.
- **F3 — Implemented.** `refresh_pr` gains `body` (`merge_cleanup.py:504–505`, one token). The pre-write check re-evaluates the full hold union on the refreshed title, body and labels, including `detect_merge_sequence([refreshed])`, and records an `aborted` receipt. A9 now includes your body-only race.
- **F4 — Implemented.** The acceptance map is replaced by the assertions A1–A12. Each has a pinned outcome and a controlled bad candidate that must fail it: an `updatedAt` clock, a removed cap, a headline-only predicate, a skipped result receipt, a pre-write check without `body`, and so on. The old "at or before updatedAt" smoke check is removed; A5/A6 need the strictly older age.
- **Pass notes adopted.** The planner reader runs only in `stalled`/`daily`, catches its own exceptions inside `run_stalled_scan`, and adds `collect_stalled_stale(..., activity=None)` so existing callers and fixtures keep today's behaviour. The failing-check deviation is labelled "Spec deviation (kept visible)" and gets a "link unavailable" fallback (A12). The node-limit observation will be retained in the receipt.
- **Nit — Implemented.** The Gates paragraph now says `ci-route.sh` classifies these paths as docs (`:63–69`), and that the full `ci-local.sh` run is deliberately chosen.

Revised plan: `PROJECT/1-INBOX/GH-1498-PR-MINDER.md` (recon #1–#2, plan steps 1 and 3, the assertions table, Gates, the acceptance map).

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2

VERDICT: FAIL
Basis: F2 and F3 are addressed in the plan, and most of F4 now has discriminating checks. Two narrow gaps remain: the planner wiring can escape A6, and the maintenance predicate can count a known owned sync as author activity after a branch rename. No new subsystem or suite is requested.
swept file: yes

**Step A — revised-plan paraphrase.** Plan-only content boundary: `PROJECT/1-INBOX/GH-1498-PR-MINDER.md`. This proposes one manually invoked PR pass, report by default, with explicit apply for branch sync, owned labels and an owned comment. A shared author-activity clock also feeds the planner. Per the plan, the existing bulk PR reader stays intact; a bounded GraphQL reader supplies history, and existing merge-cleanup readers and hold predicates are reused. Excluded: daemon, landing, closing, conflict repair and queue dispatch. Deferred: the SKILL.md will carry the issue's deferred list; the plan's “caps” exclusion means per-area PR caps (inference), since it explicitly implements a two-sync episode cap. Later authorization: apply against real PRs. Timing disclosure: this Round 2 paraphrase was written after the source read, rather than recorded before it as Step A requests; it is not claimed as a fresh blind-comprehension result.

**Evidence boundary.** Verify-tier, whole revised plan and issue, plus the cited source seams. `list_projects(limit=100)` returned all 86 projects (`has_more=false`); none is this relay worktree. `XYZ-forge` is ready at the primary checkout, generation `2026-09-01T15:54:30Z`. Exact symbol search returned 0 (`has_more=false`); coverage again reports the two Python paths and daily-planner skill as `not_tracked`, and the plan as `missing`. Direct worktree source therefore supplies material evidence. No Git command, gate, executable fixture, remote write or source edit was run. Implementation and existing-suite compatibility remain [Unverified — needs clone run].

- [Should] **F4 follow-up — A6 must reach the production planner wiring.** Plan `PROJECT/1-INBOX/GH-1498-PR-MINDER.md:99` injects activity directly into `collect_stalled_stale`. An implementation can add the helper and optional argument, leave `run_stalled_scan` unchanged, and pass A6 while `/daily-planner` continues using updatedAt. Replace or supplement A6 in the same manual check with the actual stalled/daily path under the fake gh; assert the old activity date in the generated report, and assert a disclosed fallback report on history failure. The red candidate should omit the fetch/pass-through at the production call, not only substitute the collector's clock.
  Observed input: A6 is literally “same input through `collect_stalled_stale(..., activity=...)`”; the current production call at `skills/3-weekly/weekly-planner/scripts/planner_core.py:1726–1727` supplies no activity. Both production modes enter this function (`:1892,1909`).
  Affected scope: acceptance checkbox `.relay-artifacts/pr-minder-body.md:101`, specifically planner adoption and its fail-open path.
  Falsifier: a candidate retaining the old production call must fail the report-date assertion; the wired candidate must show the 20-day-old date, and an activity-read error must still yield a report listing the fallback PR.

- [Should] **F1 follow-up — a current-name predicate loses owned maintenance history after rename/retarget.** The added two-parent and committer checks resolve the single-parent counterexample. The predicate still compares a historical message to today's branch names (`PROJECT/1-INBOX/GH-1498-PR-MINDER.md:42–47`). Thus an owned maintenance merge changes classification when only the branch name changes, even though metadata edits must not reset the clock (`.relay-artifacts/pr-minder-body.md:49`). Preserve classification for known owned syncs using the existing receipt/structure evidence where available, and define a truthful conservative outcome for ambiguous historical syncs across devices. Do not require a local re-merge. Add this input to the existing A5/A8 manual check; the accepted human web-editor boundary at plan `:49` does not cover this false reset.
  Observed input: applying the plan's exact predicate to `{parents: 2, messageHeadline: "Merge branch 'development' into fix/old", committer: {email: "noreply@github.com"}, committedDate: "2026-11-16T12:00:00Z"}` yields maintenance with `headRefName=fix/old` and author activity with `headRefName=fix/new`. This is a controlled design counterexample, not a claim that a live PR was renamed.
  Affected scope: shared activity age and episode-cap/reset behavior when a PR containing a prior owned sync is renamed or retargeted.
  Falsifier: hold commit OID/parents/dates and receipt identity fixed, change only headRefName (and separately baseRefName), and assert no fresh author-activity reset. A real single-parent author commit must still reset normally.

  Read-only probe for both findings (exit 0): `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` read plan A6 and source lines 1726–1727, then evaluated `parents == 2 and messageHeadline == f"Merge branch 'development' into {head}" and committer_email == 'noreply@github.com'` for the literal input above. Decisive output: `A6 injects activity directly: True`; `Current production collector call: section = collect_stalled_stale(prs, issues, sequence, operator, now, args.stale_days, args.draft_stale_days, device, local_rows, coverage, prior, date_local)`; `headRefName=fix/old: maintenance=True, counted_as_activity=False`; `headRefName=fix/new: maintenance=False, counted_as_activity=True`. No candidate implementation was executed.

- [Pass] **F2/F3 plan corrections and reuse.** The revised plan now explicitly reads review-thread comments, returns unknown on incomplete/error history, and discloses planner fallback (`PROJECT/1-INBOX/GH-1498-PR-MINDER.md:37–41,51,69–72`). The reader must actually validate returned data and maxima; these are plan promises, not verified API behavior. Adding body to the existing `refresh_pr` field list and re-evaluating the full hold union (`plan :83`) fixes the identified query gap (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:504–505`). Existing ownership remains coherent: planner bulk reader `planner_core.py:326–343`, holds `:401–429,1203–1205`, refresh/retry `merge_cleanup.py:501–531`, hold veto `:574–585`, stack predicate only `:558–559`. No parallel landing writer is proposed. Recon #1's node-limit observation remains unverified pending its promised receipt; recon #3–#5 match these seams and daily-planner's bundle contract (`skills/2-daily/daily-planner/SKILL.md:14`).

- [Pass] **Acceptance map, remaining scope and proportionality.** A1–A4 map issue checkboxes `:97–100`; A5/A6 map `:101` subject to the wiring gap above; A7–A10 map `:102–105`; the Gates paragraph maps `:106` (`PROJECT/1-INBOX/GH-1498-PR-MINDER.md:94–105,111`). The pinned 20d/0d and label/reset/receipt outcomes now reject the named bad candidates. A12 and the explicit failing-check name/URL deviation (`plan :105,119`) remain proportionate and actionable against issue `:67`; this is accepted as a disclosed deviation, not implementation of first-error-line extraction. Optional activity input and exception containment (`plan :70–72`) fit the current fail-open contract (`planner_core.py:1865–1875`). The current workload does not warrant locks, a daemon, journal recovery or more suites. No additional pre-existing defect was established in the whole plan/issue or bounded source seams; the large source modules were not exhaustively audited.

Handing off to Producer (claude-a) — address the two follow-ups in the plan and its existing manual verification procedure, then open Round 3. Go to the Producer window and say 'take your turn'.

### Producer · Round 3 (claude-a)

Dispositions:

- **F4 follow-up (A6 wiring) — Implemented.** A6 now drives the real `planner_core.py --mode stalled` entry point, with the fake `gh` serving both the bulk list and the history query. It asserts the 20-day-old date in the generated report. A history-query error must still produce a report whose disclosure lists that PR as an `updatedAt` fallback. The red candidate leaves the production call at `:1726` without the fetch/pass-through, so it shows today's date and fails.
- **F1 follow-up (rename) — Implemented.** The headline test no longer compares against current branch names. It now uses GitHub's server-merge pattern `^Merge branch '[^']+' into .+$`, together with the 2-parent and `noreply@github.com` committer checks. A commit whose OID is in a local `ok` update-branch receipt also counts as maintenance; that is a union, so a device without receipts still classifies correctly from structure alone. A8 adds the change-only-`headRefName` and change-only-`baseRefName` cases, which must not reset, plus the current-name predicate as a red candidate. The single-parent author commit still resets.

Plan diff: recon #2 (headline pattern, receipt union) and the A6/A8 rows. Nothing else changed.

Handing off to Reviewer (codex) for Round 3, the final round under the cap.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
