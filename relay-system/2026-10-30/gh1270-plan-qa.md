# RELAY · GH-1270 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1270-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1270-LAUNCH-PACKET-READINESS.md`
- Also read (the code the plan cites): utils/py/harness.py (factory-primitive plan-draft section: _planner, _cited_paths, plan_draft, _build_proposal, _verify_plan_draft, init_from_prs, BRIEF_KEYS, factory_parser/factory_main); utils/py/_marathon_plan.py (_resolve_gh, _gh_state, _eval_probe, the state loop near the already-closed / already-landed checks); utils/py/marathon_yaml_emit.py (Lane, Packet, render, brief_value, safe_scalar); bin/marathon-yaml; relay-automation/marathon.sh (plan location and brief checks); relay-automation/MARATHON.example.yaml; utils/py/wave_reconcile.py (extract_linked_issues); TESTS-RESULTS/2026-10-25+GH-1175-phase0/D4-stale-contracts-intake.md; issues #1270 and #1075.
- Operational envelope: a local, single-operator, read-only experiment in development. Grade against the plan's stated requirements and commensurate complexity; do not demand multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): verification is existing suites plus manual controls under `TESTS-RESULTS/`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: the plan is grounded in the actual code paths; it reuses the planner's already-closed path, extract_linked_issues, _eval_probe and marathon_yaml_emit.render rather than adding parallel logic, and changes no planner, schema, validator or launcher; read-only and offline claims hold (new GitHub reads only at init; packet writes only under the run root; no command probes run); the packet format is what bin/marathon-yaml and marathon.sh accept; acceptance criteria are falsifiable with red controls; the rating 60/40/50/50 is reasonable.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 · claude-a

Plan ready: `PROJECT/2-WORKING/GH-1270-LAUNCH-PACKET-READINESS.md`. Specific questions:

1. Is freezing `gh issue list --state all` into the planner's stub state file the right way to exclude CLOSED rows, and are there side effects on other planner states (e.g. already-closed only fires for Queue / In progress sections)?
2. Is `extract_linked_issues` closers-only the right "delivered but open" signal, and is holding (not dropping) planner lanes in the provisional view correct?
3. Is a partial `fix_probes` landing via `_eval_probe` (working tree) a sound stale-contract hold, with `command` probes never executed?
4. One `MARATHON.yaml` per lane (because phases run serially) — correct reading of marathon.sh? Is reusing `render` with brief paths pointing at the post-copy `PROJECT/2-WORKING/GH-<n>-LAUNCH/brief.md` location sound?
5. Are acceptance checks and red controls sufficient?

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
