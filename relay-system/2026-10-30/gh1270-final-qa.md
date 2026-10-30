# RELAY · GH-1270 final QA
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
6. **Commit only the relay file** (`relay(gh1270-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/harness.py`
- Also read: the diff `TESTS-RESULTS/2026-10-30+GH-1270/harness-2fa49d95..52406394.diff`; the approved plan `PROJECT/2-WORKING/GH-1270-LAUNCH-PACKET-READINESS.md` and its plan QA thread `relay-system/2026-10-30/gh1270-plan-qa.md`; evidence `TESTS-RESULTS/2026-10-30+GH-1270/` (SUMMARY.md, provenance.jsonl, controls.txt, smoke.txt, ledger-identity.txt, gh1270-controls.py, gh1270-controls.sh, pilot-2c/ including launch-packet/wave-1/); utils/py/marathon_yaml_emit.py; bin/marathon-yaml; utils/py/_marathon_plan.py (_gh_state, _eval_probe); utils/py/wave_reconcile.py (extract_linked_issues).
- Operational envelope: a local, single-operator, read-only experiment in development. Grade against the approved plan and commensurate complexity; no multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): a new test file or registry entry is a finding; verification is manual controls under `TESTS-RESULTS/`. The full gate is running in the verify clone; its result will be added in the next Producer block.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: each acceptance item in the plan is met by the code and shown by retained evidence (with provenance and ledger hashes); the code matches the approved plan (frozen full issue state before the planner runs; closers-only delivered map; stale check for briefed and unbriefed lanes; command probes never run; probe_results in BRIEF_KEYS; packet only from a proposal matching the latest completed plan-draft receipt; render anchored at the repo root; validator run per lane); no second planner, writer, schema or suite; read-only claims hold; the rating 60/40/50/50 still fits.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 · claude-a

Implementation `34edabb0` + README fix `52406394`; evidence `df28f1e4` (provenance, ledger hashes, controls, smoke and the base diff are retained). Pilot on 15 real issues; 11 controls pass including red controls for the seeded-only state file and admitted-only probe check; smoke found and fixed the builder == reviewer refusal in the printed dry-run command. Please check especially: init ordering (state frozen before the planner computes), the delivered exclusion for both seeded paths, `_probe_landing` on every provisional planner lane, the receipt-hash gate in `make_packet`, and the staging-then-replace write of the packet directory.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
