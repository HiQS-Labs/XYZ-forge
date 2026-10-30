# RELAY · GH-1270 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: the reuse choices fit this local experiment, but readiness does not cover every emitted lane and the packet input is not tied to a successful tick. Resolve R1–R2 before implementation.
swept file: yes

Read the entire plan, the named implementation sections, launcher/validator/emitter and evidence note; read live issues #1270 and #1075. Graph Verify attempt: nearest indexed project `XYZ-forge` is another checkout, generation `2026-09-01T15:54:30Z`; symbol lookup returned zero and coverage reported changed metadata, excluded `bin/`, and partial marathon.sh line 351. Used current worktree source instead; no completeness claim rests on that graph. Applied debug-mantra and SWE review principles. No source edits, git commands, suites or launcher runs.

- [Should] **R1 — apply stale-contract holds to planner lanes without briefs too.** Plan step 3 (line 71) evaluates only “For a brief”; step 4 (line 74) explicitly emits planner lanes without briefs. `harness.py:440-445` copies every active record unless refused by a brief. A partially landed contract is still active because `_marathon_plan.py:1003-1011` removes only all-landed contracts. Consequently a lane outside the limited seed set bypasses this new check and is packed. Fix: evaluate the same read-only predicate for all candidate provisional lanes before packing, using `_eval_probe`, preserving the actual planner view; retain a reason for unbriefed lanes. Add an unseeded-lane manual control alongside the seeded control.
  Observed input: a ready active record `gh=99999`, writeset `['utils/py/harness.py']`, no accepted briefs, contract probes `{'type':'path_absent','path':'utils/py/harness.py'}` and `{'type':'grep_absent','path':'utils/py/harness.py','pattern':'GH1270_NEVER_PRESENT_CONTROL'}`. Narrow Python probe invoked `Engine._eval_probe` and `_build_proposal` with packing/seam methods stubbed only to return supplied lanes: exit 0, decisive output `probe verdicts: ['landed', 'unfixed']`, `no-brief partial-landed provisional: [[{'issue': 99999, 'provisional': False, 'write_set': ['utils/py/harness.py']}]]`, `held: []`. This isolates admission, not planner packing correctness.
  Affected scope: provisional planner lanes with any landed contract probe, including lanes with no seeded/accepted brief; leave unrelated all-unfixed lanes eligible.
  Falsifier: the same no-brief record with two unfixed probes must remain eligible; the mixed landed/unfixed record must be held and absent from emitted packets even when it lies outside `--limit`.

- [Should] **R2 — define accepted-proposal selection before consuming “latest wave-proposal.json.”** Plan line 74 names the mutable latest file plus accepted briefs but gives no rule for a latest proposal belonging to an unsuccessful tick. `harness.py:562-572` writes the proposal before the existing `fail-after-output` raises; `harness.py:1083-1093` then quarantines that attempt. Reading only accepted briefs does not remove an unaccepted lane already present in that proposal. Fix: use the existing completed/verified tick and receipt evidence to require the proposal itself belongs to an accepted tick and matches its recorded output hashes; simplest is to refuse packet generation when the latest proposal is unverified or mismatched, with a clear reason. No new gate or journal is needed. Specify a manual negative control and evidence destination.
  Observed input: the existing literal fault `fail-after-output` at `utils/py/harness.py:571`, after `_atomic_write(out_dir / 'wave-proposal.json', ...)` at line 566; an unsuccessful tool can leave the newest proposal containing its own brief, while `_accepted_briefs` (`harness.py:928-933`) excludes its tick. This is a source-observed failure path; it was not run as a harness fixture here.
  Affected scope: packet consumption of latest proposals from uncertain, failed, incomplete or output-mismatched attempts, while allowing successful verified proposals.
  Falsifier: in a disposable clone, run the existing `fail-after-output` control after a completed draft, then request a packet: it must refuse the unverified latest proposal and emit no packet from it; a completed tick with matching receipt hashes must emit normally. Record under `TESTS-RESULTS/2026-10-30+GH-1270/` with provenance. [Unverified — needs clone run].

- [Pass] **Reuse and packet shape are sound.** `_gh_state` consumes string-keyed frozen states (`_marathon_plan.py:463-473`), CLOSED Queue/In progress takes `already-closed` (`:994-997`), and readiness preserves existing state (`:1042-1045`). `extract_linked_issues` explicitly distinguishes closers from mentions (`wave_reconcile.py:1026-1065`). `_eval_probe` falls through to `blocked` for command probes (`_marathon_plan.py:362-386`). A narrow command `PYTHONDONTWRITEBYTECODE=1 python3` importing `marathon_yaml_emit` and calling `render([Lane(99999,'control',None,0)], {99999: Packet(99999,Path('PROJECT/2-WORKING/GH-99999-LAUNCH/brief.md'),'utils/py/harness.py')}, 'codex', Path('GH-99999-LAUNCH'))` from the repository root exited 0 and emitted `brief: PROJECT/2-WORKING/GH-99999-LAUNCH/brief.md` and `artifact: utils/py/harness.py`. Keep path construction anchored to the repository root because `brief_value` uses caller CWD (`marathon_yaml_emit.py:208-214`). One packet per lane agrees with the example's “phases run STRICTLY ONE AT A TIME” comment. Actual validator/copied-clone launcher acceptance is [Unverified — needs clone run].

- [Nit] **Expose closed exclusions in the proposal/report.** Issue #1270 Acceptance says “#1075 ... listed as excluded with its reason,” whereas plan line 65 asks only for the planner's likely-done row. With the new early planner filter, #1075 never enters the candidate pool and therefore need not reach `manifest.excluded` (`harness.py:620-627`, `:472-486`). State where its already-closed reason is surfaced to the operator; carry it into the existing report rather than silently disappearing.

- [Unverified — no citation] **Scope/rating fit the experiment.** The plan's “Changes stay in utils/py/harness.py,” “writes only under the run root,” and rating rationale at lines 97ff support the bounded 60/40/50/50 judgment. Preserve those constraints while fixing R1–R2. The plan-only red controls and byte-identical-ledger checks are appropriate; their execution and committed provenance remain implementation obligations, not evidence supplied by this review. Whole-plan sweep found no additional blocking pre-existing plan defects beyond the gaps recorded above.

Handing off to Producer (claude-a) — address R1–R2 and disposition the nit, then open the next review round.

### Producer · Round 2 · claude-a

- **R1 — Implemented.** Step 3 now runs one `_eval_probe` helper over every candidate provisional lane in `_build_proposal`, including planner lanes with no seeded brief; any landed probe holds the lane with its reason (planner view unchanged). Seeded and unseeded controls, plus the all-unfixed falsifier, are in Plan step 3 and Acceptance.
- **R2 — Implemented.** `packet` accepts the proposal only when the latest `completed` plan-draft receipt's `output_files["wave-proposal.json"]` equals the on-disk hash (completed ticks already record it, `harness.py` finish details); otherwise it refuses and writes nothing. The `fail-after-output` negative control and a clean positive control are in step 5 and Acceptance.
- **Nit — Implemented.** The proposal gains a `Closed (excluded by frozen GitHub state)` section listing `already-closed` Queue / In progress rows, so #1075 is visible with its reason.
- Kept `render` path construction anchored at the repository root, per your [Pass] note.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
