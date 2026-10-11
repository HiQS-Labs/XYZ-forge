# RELAY · GH1022 staged intake plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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


### Attestation · relay-drive — 2026-10-11T16:10:46Z
task: GH1022-PLAN-QA
reviewer: codex
status: Approved
reviewed-head: 22806e5f212bf64459ed60e8a790133aeccdca52
added-range: 6381+4245
added-sha256: c2cb14fa71fec5321c95275109de9f3d8b8fca992ae43582f2a0436574c57299
### Producer · Round 2

Plan nits implemented with source/phase goals and historical registration distinctions.
Fresh ownership review required: the existing inventory ratchet rejects utils/py/issue_intake.py.
The shared import-only library now lives beside the existing intake owner at
skills/3-weekly/weekly-planner/scripts/issue_intake.py and has no standalone CLI.
The existing entry points and core mode call it via the selected harness. Read the updated
plan's ownership correction and code; decide explicitly whether this follows the existing
skill-subsystem/entry-point policy or evades it. No gate/baseline/test changed. Current inventory
check passes without modifications. If this is a bypass, return FAIL and hold instead of
recommending policy weakening. Staged/held scope and all remaining umbrella limits unchanged.

### Reviewer · Round 2

VERDICT: PASS
Basis: The ownership correction follows existing skill-subsystem ownership and existing-entry-point routing; it is not a loose-script policy bypass. Approval covers the staged plan and this ownership decision. Final implementation QA and disposable-clone verification remain owed.
swept file: yes

- [Pass] GH-777's policy is explicit: "new CLI verbs must route through existing entry points or subcommands" (`utils/pdda/check_inventory_ratchet.py:9`), and its script inventory deliberately scans `utils`, `scripts`, and `bin` (`:50–62`). This is not permission to relocate an arbitrary CLI outside the scanner. Here the substance matches the policy: `issue_intake.py:1–262` is a function library beside the existing intake owner, the weekly preview is an existing-core mode (`planner_core.py:814–831`), and scan/find continue through their original shell entry points and the bundled adapter (`intake_adapter.py:33–42`). Plan `:189–202` explains the rejected location and explicitly forbids relaxing the ratchet. Keep this ownership and the unchanged gate/baseline; no policy exception is needed for this design.
- [Pass] The import-only characterization has direct source support (`issue_intake.py:7–21`, function definitions through `:262`). Narrow static probe command: `PYTHONDONTWRITEBYTECODE=1 python3 -c 'import ast,pathlib; t=ast.parse(pathlib.Path("skills/3-weekly/weekly-planner/scripts/issue_intake.py").read_text()); print("top_level_if",sum(isinstance(n,ast.If) for n in t.body)); print("top_level_calls",sum(isinstance(n,ast.Call) for s in t.body if not isinstance(s,(ast.FunctionDef,ast.ClassDef)) for n in ast.walk(s)))'`; exit 0; decisive output: `top_level_if 0`, `top_level_calls 0`. This measures the absence of a top-level main guard/call in the library, not runtime no-write behavior or dependency imports.
- [Pass] Harness ownership remains distinct from swept-root ownership. Adapter `intake_adapter.py:29–42` selects the module from the locator-returned harness, fails clearly when missing, and supplies caller CWD to the legacy functions. Core `planner_core.py:25–47` selects the same harness-relative library. Plan `:70–74`, `:183–186` and `:194–199` explicitly retain installed-copy support and the current-harness prerequisite. Moving the library does not create an independently deployed sibling-skill requirement.
- [Pass] Full-plan scope remains held and preserves executable-plan ownership (`plan:30–48`, `:139–163`; `utils/py/marathon_plan.py:23–24`). Preview routing precedes scratch creation (`planner_core.py:814–832`), reports advisory helpers separately, and leaves `dispatch_allowed` false (`issue_intake.py:258–262`). Legacy CI NONE/dependency/closure weaknesses remain visible in the full source (`planner_core.py:194–241`, `:495–509`) and segregated in plan `:76–82`, `:145–159`. No additional pre-existing plan defect blocking this milestone found during the sweep; this does not attest legacy readiness or approve any execution.
- [Pass] Proof remains a required next phase: plan `:123–137`, `:161–176` requires legacy parity, pagination/malformed/offline/conflict controls, import/preview no-write evidence, existing gh369, exact final revision, independent final QA and a disposable-clone gate. The ownership change does not satisfy or waive those checks. Preserve the remaining checkbox and staged draft disclosure.

Evidence limits: Verify tier attempted with `list_projects`, `index_status`, targeted `search_graph` (zero results, no further page) and one coverage query for all material paths and the library scope. The nearest canonical `XYZ-forge` graph is at a different root and generation `2026-09-01T15:54:30Z`; coverage reports missing/not-tracked/changed metadata. Findings therefore use current direct source reads, not graph completeness. Read the complete 202-line plan, library, adapter, planner core, Setup-named sources and existing gh369 suite. [Unverified — needs clone run] Runtime parity, installed-copy execution, complete metadata/error controls, no-write behavior and final gate. No tests, executable fixtures, Git commands, dispatch or source/artifact edits ran this turn. The explicit user reviewer assignment and latest Producer request resolve the stale `NEXT: Producer` header for this turn.

Relay closed (Approved), no further plan-review turn needed. Producer author receives the result and must complete separate final implementation QA and verification before publication.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
