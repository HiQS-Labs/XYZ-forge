# RELAY · GH1022 staged intake plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1022-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-11
- Artifact: PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md, read it in full.
- Operational envelope: local single-repo discovery CLI, staged foundation for #1022, no dispatch/branch ledger orchestration in this PR. Grade this stated milestone, not completion of the umbrella. No new tests/cases/gates permitted; no enterprise machinery.
- Read current skills/3-weekly/10days/{scan-issues.sh,find-doc.sh,SKILL.md}, skills/3-weekly/weekly-planner/scripts/planner_core.py, utils/py/harness_paths.py, utils/py/marathon_plan.py and existing gh369 suite. Repository instructions apply.
- Questions: (1) Is extraction grounded in actual interfaces/defaults/root and installed-copy behavior? (2) Does complete read preview belong in existing core without a second orchestrator? (3) Are incomplete/foreign/conflicting inputs held and import/planning effects explicit? (4) Are safety-policy changes and unfinished issue criteria honestly segregated with no execution authority? (5) Are rating/rollback/verification and negative controls adequate for this stage? Cite concrete source/plan lines. Do not request new tests or live dispatch.
- Review only: append findings and verdict to this relay; no artifact edits. All requirement details and acceptance map are in the plan.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: The staged, held discovery milestone is buildable without a second orchestrator or execution authority. Approval covers this plan, not runtime correctness, umbrella completion, dispatch, or landing.
swept file: yes

- [Pass] Legacy extraction is grounded: plan lines 59–66 preserve defaults, window query, projection, failure status, root precedence, bucket order and contract heuristics. Sources: `skills/3-weekly/10days/scan-issues.sh:26–54`, `skills/3-weekly/10days/find-doc.sh:19–94`. Installed-copy lookup is explicitly harness-owned (plan lines 68–72, 103–104); the existing locator supports copied/symlinked skills and foreign CWD (`skills/1-hourly/relay-xyz/find-harness.sh:103–110`, `177–254`). Keep harness lookup separate from the swept doc root as specified.
- [Pass] Preview belongs in the existing core and must bypass its effectful path: `planner_core.py:786–789` creates scratch and performs capped PR discovery before routing; `:498–561` writes fallback outlines. Plan lines 74–80, 100–110, 119–121 explicitly require pure helper reuse, no import/write effects and complete independent reads. `utils/py/marathon_plan.py:23–24`, `:135–175`, `:195–201` retains executable-plan ownership. Implement the new mode before legacy scratch/fetch calls; preserve existing default modes.
- [Pass] Held input boundaries are explicit: plan lines 105–114 require paginated issues/PR metadata, qualified deduplication, UNKNOWN/nonzero on failures/conflicts/malformed snapshots, re-fetch of carried IDs and rejection of foreign snapshots. Closed state remains observation. Completeness must include every metadata collection actually consumed by the advisory helpers, including PR files (`planner_core.py:259–275`), rather than merely the outer PR page list.
- [Pass] Existing policy defects are acknowledged rather than laundered into readiness: missing draft discovery (`planner_core.py:108`), CI NONE readiness (`:171–172`), unmet dependencies as annotations (`:204–207`), closure-number union (`:468–481`). Plan lines 74–80 and 139–153 segregate these and the unfinished shared protocol; lines 115–117 prohibit a new fire entry point. No additional pre-existing defect blocking this held milestone found in the full plan/source sweep.
- [Pass] Rating, rollback and proof are proportionate: plan lines 45–48 name adapter/module rollback and affected consumers; lines 85–91 separate recurrence evidence from incident assumptions; lines 98–99, 119–131, 155–157 require provenance, manual negative controls, existing gh369, exact final revision, independent QA and disposable-clone gates without new tests/cases. Preserve those evidence requirements during implementation.
- [Nit] Timestamp the historical discovery claims at plan lines 55–57 and 91. The seeded `releases.sql:843` already contains the #1022 active pointer and 70/65/50/25 ratings; `:3323–3325` records registration/rating/transition at 16:06:48Z. Cheapest fix: distinguish the earlier reconnaissance from the current registered state; no ledger rewrite needed.
- [Nit] Add source citations to the reconnaissance paragraphs, explicit phase goals, trackable QA checkboxes and the execution-time debug-mantra reference. These improve the SWE proof/diagnosis surface without adding runtime machinery or tests.

Evidence limits: Verify-tier graph attempted against nearest indexed canonical project `XYZ-forge`; generation 2026-09-01T15:54:30Z is foreign/stale for this seeded worktree, structural search returned no matches and coverage reported untracked/changed metadata. All material claims above therefore use direct current source reads, not graph completeness. Full artifact read (157 lines), plus all Setup-named sources and the existing gh369 resolver suite read. [Unverified — needs clone run] Legacy byte parity, pagination/error negative controls, import/preview no-write behavior and final gate remain prospective; no tests, executable fixtures, Git commands or live dispatch ran here.

Relay closed (Approved), no further turn needed. Producer author may implement the staged plan and address the documentation nits; final implementation QA remains required.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
