# RELAY · GH805 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
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
6. **Commit only the relay file** (`relay(gh805-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-805-TEST-VALUE-ADMISSION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-805-TEST-VALUE-ADMISSION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: astra
- Started: 2026-09-24
- Definition of Done: Review final implementation against the seven-step plan and TESTS-RESULTS/2026-09-25+GH-805/REPORT.md. Compare source against base 0ae3452a5774c6e72b633dd61648137e80516e6b (no git writes). Operational envelope: local developer toolkit, bounded observe-only pilot, no mandatory approval/auth service or general test scanner. Commensurate complexity is required.

Read utils/py/gate_inventory.py, utils/ci-route.sh, changed portions and consumers of validate.sh/ci-local.sh, test/gh165-governance-canonical-paths-guard.sh, test/gh177-sandbox-test-guard.sh, test/gh269-roadmap-retired.sh, test/gh567-roadmap-dashboard-retired.sh, test/gh419-gate-inventory.sh, test/gh35-test-tiers.sh, test/gh365-runner-envelope.sh and decisions.json.

Questions: (1) Are coverage additions, error propagation and red controls correct with preserved existing policies? (2) Does the catalog remain advisory and honest about source-reference/digest/authentication limits? (3) Independently adjudicate four proposed cohort decisions (reuse retirement suites, extend planner guard, add hook suite, reject duplicate GH534 registration). (4) Do evidence and report substantiate steps1–6 and separate coverage GO from enforcement NO-GO? (5) Any scoped correctness defect or unnecessary parallel mechanism? Plan ratings remain 85/75/50/35 and GH774 partial repair 85/80/50/65; no overrides.

Full gate is intentionally pending until final code approval per start-task. Do not demand its premature rerun or mark merge ready; grade implementation readiness for that gate. Do not run tests in linked reviewer worktree; source probes only, writes only this thread, no commits yourself. Missing full-gate/hosted evidence is disclosed and remains required for the final PR claim.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The bounded advisory design and four cohort choices are reasonable, but the new Node verdict is absent from validate.sh's completeness denominator. Implementation is not ready for the final gate until that accounting defect is fixed. The Flightdeck addition also widens tier-2 selection contrary to the stated full-runner scope.
swept file: yes

- [Blocker] **F1 — full-gate denominator omits Node.** `validate.sh:1467` appends `node:test:unit` to PASSED/FAILED; `validate.sh:1527` counts only shell suites, identity, Python and gamma. `validate.sh:1540` therefore refuses even an otherwise green tier-3 run. Add the Node contribution under its execution condition and extend the existing runner-envelope control through the real summary accounting (its current extraction stops before the identity/summary block). Do not weaken the completeness check.
  Observed input: current 418-entry TESTS registry, TIER=3, pytest available, no skips, all children successful: **422 classified versus TOTAL=421**.
  Affected scope: every tier-3 validate.sh run reaching the completeness check, with or without a successful Node child; tier-2 must retain its own denominator.
  Falsifier: in a disposable clone, an all-green controlled runner including the actual summary must exit 0 with equal classified/expected counts; removing the Node TOTAL contribution must make that control red. A child rc7 must still fail for its child verdict. Full execution remains [Unverified — needs clone run].
  Read-only source probe (exit **1**, no runner or fixture executed):
  ```python
  # Command: PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY' ... PY
  from pathlib import Path
  import re, shlex
  s=Path('validate.sh').read_text()
  n=len(shlex.split(re.search(r'^TESTS=\((.*?)^\)',s,re.M|re.S)[1],comments=True))
  b=s[s.index('TOTAL=$(( ${#RUN_TESTS[@]} + 1 ))'):s.index('# GH-15: the verdict')]
  print(b)
  labels=re.findall(r'PASSED\+=\("([^"]+)"\)',s[s.index('# The Python layer follows'):s.index('TOTAL=$(( ${#RUN_TESTS[@]} + 1 ))')])
  print('full-gate non-shell verdicts:',labels)
  print(f'all-green tier3: registered={n}, classified={n+len(labels)}, TOTAL={n+3}')
  assert n+len(labels)==n+3, 'Node verdict is missing from TOTAL'
  ```
  Decisive output: `full-gate non-shell verdicts: ['python:test_python_layer.py', 'node:test:unit', 'clone-identity-invariant', 'gamma-poison-staleness-probe']`; `all-green tier3: registered=418, classified=422, TOTAL=421`; `AssertionError: Node verdict is missing from TOTAL`. The +3 is the displayed source's tier-3 arithmetic, not an observed full-gate run.

- [Should] **F2 — preserve focused Python selection.** `validate.sh:1442` enters the Python lane for T2_PYTEST as well as tier 3, but `validate.sh:1454` unconditionally adds Flightdeck. Keep Flightdeck restricted to full runs unless a separately justified focused mapping is explicitly adopted; extend the existing controlled runner checks to include tier 2.
  Observed input: `--subsystem releases` (also pdda) sets T2_PYTEST=1 at `validate.sh:938`; the shared pytest invocation then includes `"$HERE/test/flightdeck/"`. Plan step 2 explicitly says “both full-runner” additions while “preserving ... tier behavior.”
  Affected scope: tier-2 selections that enable T2_PYTEST, not the intended tier-3 coverage addition.
  Falsifier: controlled tier-2 releases invocation selects the existing Python layer without Flightdeck, while tier 3 selects both exactly once; demonstrate child-failure propagation for both. No execution attempted here. Source query `rg -n 'T2_PYTEST=1' validate.sh` exited 0 and included `938:  case "$SUBSYSTEM" in releases|pdda) T2_PYTEST=1 ;; esac`.

- [Pass] **Independent cohort adjudication: agree with all four outcomes (0/4 disagreement).** Reuse gh269/567/568: gh269's “Fixture test: releases roadmap move and update CLI verbs”, gh567's `check_writer_audit`, and gh568's `check_runtime_untouched`/Python AST write checks protect distinct policies. Extend gh269 for planner status: `planner_status_allowed() { [ "$1" -eq 0 ] || [ "$1" -eq 4 ]; }` belongs in that owner. Add GH177: its new suite supplies JSON to the live hook and never executes the dangerous payload strings (`test/gh177-sandbox-test-guard.sh`, `subprocess.run(['bash', hook], input=json.dumps(payload)...)`). Reject duplicate GH534 scheduling: registered `test/gh436-merge-cleanup.sh` execs its Python collector, which imports all three phase modules at `test/gh436-merge-cleanup.py:863` before `unittest.main()` at line 869. Retain these choices; they do not depend on fixing F1/F2.

- [Pass] **Advisory limits are honest and proportionate.** `utils/py/gate_inventory.py:257` overwrites claimed authority with `approval_trusted: False` and `would_refuse_mandatory: True`; audit limitations explicitly say literal references “are not execution proof.” REPORT's “Coverage: GO” and “Mandatory admission: NO-GO” are distinct, and it declines global invariant counts, matched runtime savings, and real-world error-rate estimates. Preserve observe mode; no approval service or general scanner is warranted here.

- [Pass] **Retained focused evidence supports the narrow repairs, not summary correctness.** `provenance.jsonl` records eight focused rc0 suites and five candidate mutation rc1 results; the matching logs exist and are nonempty. The before/after planner-exit5 and quoted-move logs support the stated regressions. `focused/gh365-runner-envelope.log` says `PASS: validate both lanes once; child rc 7 propagated`, but that snippet never reaches TOTAL, explaining why it missed F1. Read-only JSON/hash probe (Python pathlib/json/hashlib, exit 0) compared both identity pairs, required every referenced log to have nonzero size, and recomputed each decisions.json content hash: `baseline identity_equal= True`, `focused identity_equal= True`, `provenance rows= 23 empty logs= []`, and all four cohort records reported `stale bindings= []`. Preserve the evidence and add the missing summary witness after repair.

- [Unverified — needs clone run] **Scope of this verdict.** Read the complete seeded plan/report and the requested implementation/test sources, including the surrounding runner consumers. No additional scoped pre-existing correctness defect was identified in that sweep. No git commands, gates, pytest, or executable fixtures were run. An independent source diff against base `0ae3452a5774c6e72b633dd61648137e80516e6b` was not obtained under the explicit no-git constraint (the base is not a loose object); baseline comparisons above rely on the retained evidence. Steps 1–6 have useful evidence but step 2's preservation/completeness claim needs F1/F2 resolved. Full-gate and exact-head hosted evidence remain pending as planned; this is not merge readiness. Ratings remain 85/75/50/35 and GH774 85/80/50/65, without overrides.

Handing off to Producer (astra) — fix F1/F2, retain the bounded cohort decisions, and return for review; do not treat this as approval to claim a green final gate.

### Producer · Round 2 · astra

F1 — Implemented: Node now contributes to tier-3 TOTAL alongside gamma. The existing runner-envelope fixture executes the actual summary completeness block, so a denominator regression becomes red instead of escaping the snippet.
F2 — Implemented: Flightdeck is appended to pytest targets only at tier3. The controlled runner covers tier2/tier3 and child rc0/7, checking target selection, once-only execution, child failure and total accounting.

The scope remains unchanged; these are corrections to step2. Supplemental focused evidence and the external denominator mutation are retained in the GH805 evidence folder. Existing provenance rows now also carry the repository's canonical `commit` field; log trailing whitespace was normalized only. Please re-review the repairs and full implementation for approval before the final full gate.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: F1/F2 are resolved in source and the retained controlled-runner evidence exercises the repaired boundary. The bounded implementation is ready for the planned final full gate; this is not merge readiness or an authenticated admission approval.
swept file: yes

- [Pass] **F1 resolved — complete denominator retained.** `validate.sh:1528–1534` counts shell suites, identity, selected/non-skipped Python, tier-3 gamma plus Node, and the existing tier-2 probes. The new `TOTAL=$((TOTAL + 2))` at line 1532 matches the two unconditional tier-3 non-Python lanes. `test/gh365-runner-envelope.sh:253` now extracts the actual completeness block, not a copied equation. Retained `focused/final-review-green.log` includes “PASS: validate tier 3 lane count and actual summary; child rc 0 propagated”; `focused/final-review-missing-node-total.log` contains “INTERNAL ERROR — classified 4 passed + 0 failed, expected 3”. Root provenance records the respective rc0/rc1 at `52ab4cd7`. Keep this repair and control.

- [Pass] **F2 resolved — focused selection preserved.** `validate.sh:1443–1444` starts with the existing Python-layer target and appends Flightdeck only for tier 3; Node remains tier-3-only at line 1467. `test/gh365-runner-envelope.sh:267–284` checks tier 2/3, exactly one/two child calls, Flightdeck membership and rc0/7 failure classification. The retained green log includes both tier-2 cases and both ci-local cases. `ci-local.sh:323–344` retains full Python/Flightdeck and Node execution, captures child status before other commands, and sets the enclosing suite's rc on failure. Keep the existing two-runner architecture.

- [Pass] **Whole-artifact/cohort review still supports all four choices (0/4 disagreement).** Read the complete seeded plan, report, requested inventory/routing/test sources and surrounding runner consumers, beyond the two repairs. GH269's “Fixture test: releases roadmap move and update CLI verbs”, GH567's `check_writer_audit`, and GH568's `check_runtime_untouched` plus Python AST checks protect distinct policies: reuse all three. GH269's `planner_status_allowed` accepts exactly 0/4: extend its existing owner. GH177's `subprocess.run(['bash', hook], input=json.dumps(payload)...)` tests the real hook without executing the payload strings: add that suite. `test/gh436-merge-cleanup.py:863–869` imports all three GH534 modules before unittest discovery: reject duplicate registration. No additional scoped pre-existing correctness defect or unnecessary parallel mechanism was identified in this sweep.

- [Pass] **Observe mode and evidence limits remain explicit.** `utils/py/gate_inventory.py` derives the audit from TESTS/routes and labels literal references “not execution proof”; `decision_view` forces `approval_trusted: False` and `would_refuse_mandatory: True`. REPORT separates “Coverage: GO” from “Mandatory admission: NO-GO”, declines global invariant counts and matched runtime savings, and leaves full-gate/hosted results pending. Steps 1–6 have source and retained focused evidence sufficient for implementation review, not a completed step 7. No authority service, broad scanner, bulk deletion or ratings override is justified. Ratings remain GH805 85/75/50/35 and GH774 85/80/50/65.

- [Pass] **Read-only evidence integrity probe.** Command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` using `pathlib/json/hashlib/re/shlex` to load every root provenance row, require every referenced log to exist and be nonempty, compare the two retained identity pairs, recompute every `decisions.json` content digest, and parse TESTS with `shlex.split(..., comments=True)`; exit **0**. Decisive output: `provenance rows= 31 nonempty logs= 30`; `baseline identity_equal= True`; `focused identity_equal= True`; each of the four decisions printed `stale bindings= []`; `registered= 418`. These are file-integrity/source observations, not newly executed tests.

- [Unverified — needs clone run] **Remaining evidence boundary.** The retained identity pairs identify baseline `7813ab52` and focused `e5f7659d`; they do not establish pre/post parent-clone identity for supplemental `52ab4cd7` runs. Their logs show the intended controlled outcomes, but do not upgrade them to fully attributable gate evidence. Carry final-revision pre/post identity snapshots with the upcoming disposable-clone gate. No tests, executable fixtures, pytest, or git commands were run here. Independent source comparison to base `0ae3452a5774c6e72b633dd61648137e80516e6b` remains unavailable under the no-git constraint; historical before/after conclusions rely on retained evidence. Final full-gate and applicable exact-head hosted evidence remain required before the final PR readiness claim.

Relay closed (Approved), no further review turn needed. Astra resumes the already-planned final gate and evidence/PR handoff; the harness owns the relay-file commit.


### Attestation · relay-drive — 2026-09-25T03:20:15Z
task: RELAY-gh805-final
reviewer: codex
status: Approved
reviewed-head: 4ac68632469ee510563b46dcbf022db5eb7201e0
added-range: 15040+4970
added-sha256: cd39393b8e5f0a7d89ea1fb419836efec98dee397c8ef3c7757f72fc2cabc84a
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
