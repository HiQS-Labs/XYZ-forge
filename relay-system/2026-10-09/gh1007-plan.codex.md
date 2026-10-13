# RELAY · GH-1007 SWE plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1007-swe-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md`, existing `skills/1-hourly/swe/SKILL.md`, and read-only proposed `.relay-artifacts/SKILL.md`
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-09
- Definition of Done: The user requests three-domain/four-axis surgical SWE governance, earned tests and separate CI admission, advisory performance baselines in existing task records, and independent plan/final QA. Grade the plan before implementation.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review questions and envelope

This is a local instruction-only skill revision. Commensurate complexity is required;
no new suite, runner, gate, dashboard, enterprise policy machinery, or runtime code.
Source files: read the plan, full current SWE, seeded proposal, architecture SWE row,
recon's SWE references, and start-task's relevant lifecycle/test restrictions.

1. Does the plan satisfy every user requirement and preserve source-first deployment,
   bounded review, permission, rating and dependency rules? Check persisted rating 75/55/50/85.
2. Is scope surgical and reuse-first? Flag accidental parallel governance or performance machinery.
3. Is verification meaningful without new tests? Does each manual scenario detect a real
   instruction failure, and does the validator red control avoid pretending format proves behavior?
4. Dedicated omission-diff pass: list current SWE claims with no equivalent in the proposal.
   Distinguish deliberate removal of arbitrary SOLID/FSM/scaffold/dual-sync prescriptions from
   an accidental loss of safety, migration, rollback, or consumer contracts. The plan explicitly
   retains Pillar 0 and Blast anchors at implementation, so their proposed headings are not final.
5. Are the performance statements honest about pipeline vs product, noise and baselines?

Use phase-qa's concrete acceptance and commensurate DRY/observability lens; this is a
single ordered unphased docs task, not a request to impose phase scaffolding or SOLID ceremony.
Grade only evidence-backed issues. Record file:line or quoted-span support. Reviewer writes
only this relay file. Do not run test suites, pytest, validate.sh, or executable fixtures.
No self-commit: the driven shim commits your permitted relay change. Set STATUS: Approved
only if genuinely approved; otherwise return specific findings for the author.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The plan is surgical and meets the requested governance direction, but the proposal drops one existing safety contract: the tripwire and last safe intervention point for irreversible changes. Restore that in prose before implementation; no new machinery is needed.
swept file: yes

- [Should] **S1 — Preserve the intervention deadline and one-way-door tripwire.** Current `skills/1-hourly/swe/SKILL.md:58` requires a tripwire for “anything costly or one-way,” including “by when (the point of no return).” Proposed `.relay-artifacts/SKILL.md:96` only requires a rollback signal for Costly changes and authorization for One-way doors. Authorization does not establish the condition for stopping before an irreversible action, and a rollback signal without its availability window can arrive too late. The generic migration rollback/window language at proposal line 100 does not restore this for other consequential changes. Cheapest fix: retain one sentence under the planned Blast anchor requiring Costly/One-way changes to name the stop/rollback signal and last safe intervention point; where rollback is impossible, identify the pre-action checkpoint and explicit authorization. Exercise that distinction within the existing rollback/migration manual scenario, not a new suite.
  Observed input: the exact replacement at `.relay-artifacts/SKILL.md:96`: “Costly changes need a rollback path and a signal for when to use it. One-way doors require explicit authorization.” Neither sentence retains the original deadline; the second omits the tripwire entirely.
  Affected scope: Costly or One-way changes governed by SWE, particularly actions whose rollback option expires; no added requirement for ordinary Easy edits.
  Falsifier: cite an equivalent proposed requirement covering both classes and their last safe intervention point. A manual review of an authorized irreversible action with no pre-action stop condition must still flag the missing condition; an Easy rename must not acquire a rollback ceremony.

- [Pass] **Requested scope and earned verification are present.** Proposal lines 12–20 establish planning/implementation/review and defer to project authority; lines 24–33 separate the four axes without averaging away safety/security. Lines 37–45 require owner/consumer evidence and allow justified separation. Lines 53–67 independently price test creation and CI admission, preserve necessary coverage, and reject silent test retirement. Plan lines 69–78 prohibit parallel runtime/performance machinery and deployment changes. No additional pre-existing defect requiring a separate fix was found beyond S1 and the deliberately replaced prescriptions listed below.

- [Pass] **Lifecycle, authority, and consumer preservation are planned.** Plan lines 30–32 keep GH-1008 blocked on the unlanded prerequisite; lines 49–51 preserve source-first Skills Army delivery; lines 82–102 require bounded independent plan/final QA, accepted-start, actual classification, isolated gates and a development PR. These agree with `skills/1-hourly/start-task/SKILL.md:25–30`, `:73–76`, `:175–198`, and `:237–271`. `ARCHITECTURE.md:63` needs the planned catalog update. `skills/1-hourly/recon/SKILL.md:122,128` consume Pillar 0/Blast; plan lines 46–48 and 82–84 explicitly preserve those anchors and the current-state/proposed-impact distinction. Their absence from the seeded headings is therefore not an additional finding at plan QA.

- [Unverified — no citation] **Omission-diff disposition.** Current SWE lines 33–35, 78–84, 123–174 prescribe a sourcing order/use-count, raw-diff bias, FSM threshold, one writer, UTC-only handling, SOLID in agent instructions, fixed scaffold/checklist syntax and correlation IDs. The proposal deliberately replaces these with fit-based reuse, coherent mutation ownership, timezone semantics, repository formats and proportionate observability (proposal lines 39–45, 92–104); those removals are consistent with the task. Current lines 88–99 prescribe nullable expansion, automated parity, fallback and bidirectional sync; proposal line 100 preserves compatibility, bounded backfill, update ordering, convergence, cutover and retirement obligations while making mechanisms conditional. Current lines 18–20, 47, 60, 103–121 also lose exact unknown-resolution commands, categorical Recon exemptions and named sibling-workflow routing; proposal lines 18, 37, 94 and 104 delegate those details to project workflows while retaining evidence/unknowns and debugging discipline. Current exact verdict-table/quick-win formatting and repeated principles/example are replaced by proposal lines 104–110. The accidental safety loss is S1; preservation of the named consumer anchors remains an explicit implementation acceptance condition.

- [Pass] **Performance and verification claims stay bounded.** Proposal lines 71–86 require relevant baselines, honest initial measurements, comparable samples and noise reporting; distinguish pipeline timing from product performance; keep new measurements advisory and evidence in existing records. Plan lines 109–121 cover small edits, authorization coverage, reuse exceptions, cache/noise confounds, hot paths and migration contracts. Lines 90–93 and 123–125 correctly limit the invalid-frontmatter red control to format validation, not agent behavior. Applying phase-qa's concrete-acceptance and calibrated DRY/observability lens does not require adding phases or SOLID scaffolding to this task.

- [Pass] **Persisted rating matches.** Read-only probe (exit 0), after `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`: Python `sqlite3.connect(Path("releases.db").resolve().as_uri()+"?mode=ro", uri=True)`, then `SELECT gh_number,doc_path,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr FROM roadmap_items WHERE gh_number=1007`, asserting exactly one row. Decisive output: `{"gh_number":1007,"doc_path":"PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md","rating_pri":75,"rating_sev":55,"rating_appeal":50,"rating_effort":85,"rating_ovr":null}`. Sum 265 agrees with plan line 129. Initial schema probe exited 1 because it used nonexistent `issue_number`; PRAGMA identified `gh_number`, and the corrected query above succeeded without writes.

- [Unverified — needs clone run] No validators, suites, fixtures or runtime gates were executed in this turn. Final source digests, provenance, classifier results and implementation QA remain future work under plan lines 90–102. Graph Verify context: nearest canonical project `XYZ-forge`, generation `2026-09-01T15:54:30Z`; coverage reported skill freshness untracked, architecture metadata changed, and plan/proposal missing. Current source was read directly; no graph completeness claim.

Handing off to Producer (codex-author) — address S1, record its disposition, and return the revised proposal for Round 2. No implementation approval yet.

### Producer · Round 2

Disposition S1: Implemented. The proposed Blast paragraph now covers both Costly and
One-way classes, stop/rollback signals, the last safe intervention point, and explicit
pre-action checkpoint/authorization where rollback is impossible. The plan's existing
manual scenarios now include the irreversible-action versus Easy-rename distinction.
Also fulfilled the planned Pillar 0/Blast anchors and made clear an explicitly requested
measurement skill may reuse SWE governance (GH-1008), without authorizing new machinery.
Re-review the updated seeded proposal and plan. Production SWE remains unchanged.

### Reviewer · Round 2

VERDICT: PASS
Basis: S1 is repaired in the seeded proposal and its manual acceptance scenario. The full plan and current/proposed SWE comparison supports implementation of this bounded instruction change. No additional pre-existing defect requiring a separate fix was found in the reviewed files. This approves the plan, not implementation, deployment, or merge.
swept file: yes

- [Pass] **S1 closed.** `.relay-artifacts/SKILL.md:100` now says “For Costly and One-way changes, name the stop/rollback signal and the last safe intervention point” and requires a pre-action checkpoint and explicit authorization where rollback is impossible. `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md:119` tests an authorized irreversible action missing that checkpoint and exempts an Easy rename. This restores the deadline and both affected classes from `skills/1-hourly/swe/SKILL.md:58`; no added machinery is needed.

- [Pass] **Scope, reuse, and earned verification satisfy the requested direction.** `.relay-artifacts/SKILL.md:12` defines three modes; `:24` separates safety/security/maintainability/performance; `:31` prevents trading away safety or security. Its `:41` requires owner/consumer evidence, `:46` permits justified separation, and `:57` through `:71` separately price new tests and CI admission while preserving consequential coverage and governed retirement. `:18` leaves repository prohibitions and permissions authoritative. `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md:69` rejects parallel policy/runtime/performance machinery.

- [Pass] **Consumer and workflow contracts remain intact.** The Pillar 0/Blast names and current-state/proposed-impact distinction at `.relay-artifacts/SKILL.md:35`, `:37`, and `:94` satisfy the references in `skills/1-hourly/recon/SKILL.md:122` and `:128`. The plan's `:45` updates `ARCHITECTURE.md:63`; its `:49` preserves source-first delivery without running the legacy installer. Plan `:30`, `:82`, `:86`, `:94`, and `:98` retain dependency ordering, bounded independent plan/final QA, accepted-start, actual classification, isolated gates and a development PR. These align with `skills/1-hourly/start-task/SKILL.md:73`, `:175`, `:200`, `:237`, and `:265`. GH-1008 remains dependent on landing, not merely this approval.

- [Pass] **Dedicated omission-diff pass: remaining removals are deliberate simplifications.** `skills/1-hourly/swe/SKILL.md:33`–`:35` impose a sourcing order, use-count and raw-diff bias; proposal `.relay-artifacts/SKILL.md:43`–`:49` substitute fit-based reuse and present responsibilities. Current `skills/1-hourly/swe/SKILL.md:78`–`:84` and `:123`–`:174` impose an FSM threshold, literal single writer, UTC-only convention, SOLID wording, fixed scaffold/checklist syntax and correlation IDs; proposal `.relay-artifacts/SKILL.md:96`, `:102`, and `:108` preserve proportionate observability, consistency, interruption/time semantics and repository-owned formats. Current `skills/1-hourly/swe/SKILL.md:88`–`:99` mandate six migration stages, automated parity, fallback and bidirectional sync; proposal `.relay-artifacts/SKILL.md:104` retains compatibility, bounded backfill, ordering, convergence, cutover, rollback and legacy-consumer retirement while making the mechanism conditional. Current `skills/1-hourly/swe/SKILL.md:18`, `:20`, `:47`, `:57`, `:60`, and `:103`–`:121` lose exact unknown-resolution commands, categorical recon exemptions, mandatory named sibling routing and an explicit shield-or-none field; proposal `.relay-artifacts/SKILL.md:18`, `:37`, `:41`, `:98`, and `:100` retain evidence, proportionality, debugging, risk and stop/rollback obligations. Current `skills/1-hourly/swe/SKILL.md:176` onward loses the exact review table, quick-win layout and repeated example; proposal `.relay-artifacts/SKILL.md:108`–`:114` retains observable completion, consumer delivery, independent review, honest evidence and actionable findings. No remaining accidental safety, migration, rollback or named-consumer loss found.

- [Pass] **Performance and planned manual review stay honest.** `.relay-artifacts/SKILL.md:75`–`:90` distinguish pipeline from product, require relevant baselines and comparable samples, label noisy evidence inconclusive, default new measurements to advisory and reuse existing records. The explicit measurement-skill allowance at `:90` adds no authority for new infrastructure. `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md:109`–`:123` exercise meaningful instruction decisions rather than keyword matches. Its `:92` and `:125` correctly limit the validator red control to format sensitivity; they do not claim agent behavior is proven. This applies phase-qa's calibrated acceptance/DRY/observability lens without imposing phases or SOLID ceremony.

- [Pass] **Persisted rating read back unchanged.** Read-only probe, exit 0: after `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` and `mkdir -p "$TMPDIR"`, ran `python3` with `sqlite3.connect(Path("releases.db").resolve().as_uri()+"?mode=ro", uri=True)` and `SELECT gh_number,doc_path,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr FROM roadmap_items WHERE gh_number=1007`, asserting exactly one row. Decisive output: `{"doc_path": "PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md", "gh_number": 1007, "rating_appeal": 50, "rating_effort": 85, "rating_ovr": null, "rating_pri": 75, "rating_sev": 55}`. The 75/55/50/85 rating sums to 265, matching plan `:131`.

- [Unverified — needs clone run] No validator, test suite, executable fixture or runtime gate ran in this turn. Implementation digests, committed provenance, classifier results, required gates and final independent QA remain due under `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md:90`–`:102`. Graph Verify context: both project-list pages examined; no index for this relay worktree. Nearest canonical project `XYZ-forge`, generation `2026-09-01T15:54:30Z`; coverage reports skill freshness untracked, architecture metadata changed, and plan/proposal missing. Direct current-source reads support this review; no graph completeness claim.

Relay closed (Approved), no further plan-review turn needed. Handing completion to Producer (codex-author) for the approved implementation sequence and subsequent final QA. The harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-09T15:39:35Z
task: RELAY-gh1007-plan
reviewer: codex
status: Approved
reviewed-head: 925248ecbba108e389516336db4853dcf159b60b
added-range: 14942+6338
added-sha256: b4b5ac2ef1463d7872de6ee9618e4be5ab7727d56fced3981b201d9c673db062
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
