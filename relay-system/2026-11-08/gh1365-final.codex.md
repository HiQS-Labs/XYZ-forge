# RELAY · GH-1365 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-07.
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
6. **Commit only the relay file** (`relay(gh-1365-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1365-JOG-MARKDOWN-TAIL-EXEMPTION.md; implementation.patch and evidence under TESTS-RESULTS/2026-11-08+GH-1365/
- Reviewer: codex   ·   Producer: task-parent
- Started: 2026-11-07
- Definition of Done: Operator-selected completion policy, honest version attribution and proportionality guidance implemented; focused verification and CLI smoke support claims.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review scope

Operator explicitly chose to stop exact approval ancestry requirements for QUEUE COMPLETION. Read the plan and full changed source files; implementation.patch supplies exact diff without needing Git. Read manual-results.json, runner and SUMMARY for limits. Existing gh280 suite passed 227/227; full classified gate will run after this QA, not yet claimed. Operational envelope is local operator-directed software factory. No supplemental-attestation mechanism, no new suite/gate, no unrelated containment bypass. Publication/retry checks remain unchanged. Grade against these requirements, not an unrequested hostile multi-tenant threat model.

1. Does jog_land complete delivered work with valid historical evidence without exact ancestry, including rebased history, while preserving PR/merge/receipt identity checks and queue idempotence?
2. Are reviewed/tested/landed identities truthfully distinguished and never falsely upgraded to final-head approval?
3. Do AGENTS and GUIDING-PRINCIPLES express the requested balance, with MACHINE-CONTRACTS and Jog instructions consistent? Any actual missing consumer?
4. Are focused suite and manual main/adjacent replay evidence adequate and falsifiable? Any accidental new machinery or scoped defect?

Write findings only in relay. Do not run mutation-heavy tests. Approve when requirements are met; full gate is next publication step.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: The implementation meets the operator-selected queue-completion policy without adding an approval mechanism or changing publication/retry admission. Approval is final QA of the seeded artifact; the classified full gate remains the next publication step, not a completed claim.
swept file: yes

- [Pass] Completion boundary: `utils/py/jog_run.py:1291`–`1449` retains committed bundle validation, PR branch/identity checks, merge reachability, releases check, reconciliation and canonical-row checks. The moved PR head is fetched and compared at `:1343`; historical approval ancestry is no longer required here. Publication still calls `_landing_tail_proof` at `:1129`, and retry admission still uses `_is_relay_receipt_tail`. No blocking pre-existing source defect was identified in the whole-file sweep of `jog_run.py` and the existing adapter suite.
- [Pass] Attribution is factual: `utils/py/jog_run.py:1434` records original approved/tested, reported review head/candidate, landed head and merge separately; missing review fields stay null. `TESTS-RESULTS/2026-11-08+GH-1365/manual-results.json:276` records distinct historical identities and `completion_policy: merged-pr`; it does not upgrade final-head review or test coverage.
- [Pass] Evidence is proportionate and falsifiable: `TESTS-RESULTS/2026-11-08+GH-1365/manual-results.json:7` records baseline exit 2 for the actual nonledger tail, `:187` candidate exit 0, `:217` stable replay, and `:247` successful explicitly constructed non-ancestor control. Five invalid-input cases also return 2 without queue/count changes. `focused.log:230` reports `227 pass, 0 fail`; the runner and SUMMARY explicitly describe local GitHub transport fixtures and the synthetic non-ancestor limit. These are inspected saved clone-run receipts, not suites rerun in this worktree.
- [Pass] Canonical proportionality guidance at `GUIDING-PRINCIPLES.md:29` and `AGENTS.md:149` weighs concrete risk against operational cost while retaining honest evidence and unrelated protections. `MACHINE-CONTRACTS.md:109` and `skills/2-daily/jog/SKILL.md:168` distinguish delivery from approval. No additional landing-metadata consumer requiring migration was found in the inspected runtime/skill references.
- [Nit] Pre-existing wording in `skills/2-daily/jog/SKILL.md:67`, `:118` and `:165` still says “after hosted reconciliation,” while the updated landing paragraph correctly permits local reconciliation. Optional cleanup: make these summaries say “hosted or local reconciliation” or point to the landing paragraph. This does not block the implemented policy or its evidence.

Read-only probe (exit 0), run with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`; no production function, fixture, suite or Git command was executed:

```python
import ast, hashlib, json
from pathlib import Path
p = Path('TESTS-RESULTS/2026-11-08+GH-1365')
r = json.loads((p/'manual-results.json').read_text())
assert len(r['cases']) == 9
assert [c['rc'] for c in r['cases']] == [2,2,2,2,2,2,0,0,0]
assert all(c['before'] == c['after'] for c in r['cases'] if c['rc'])
assert r['cases'][6]['after'] == r['cases'][7]['after']
prov = [json.loads(s) for s in (p/'provenance.jsonl').read_text().splitlines()]
h = hashlib.sha256((p/'manual-replay.py').read_bytes()).hexdigest()
assert h == prov[-1]['runner_sha256']
t = ast.parse(Path('utils/py/jog_run.py').read_text())
callers = [f.name for f in t.body if isinstance(f, ast.FunctionDef)
           and any(isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
                   and n.func.id == '_landing_tail_proof' for n in ast.walk(f))]
assert callers == ['publish_jog_receipt']
assert '227 pass, 0 fail' in (p/'focused.log').read_text()
```

Command: `python3 - <<'PY'` with the above body and closing `PY`. Decisive output from the same checks: `9 saved cases; 6 refusal controls unchanged; replay counts stable; runner SHA256 f57e70c3579ee9ce34f99182ecf1a7048729c608bc7014f730a4745c278b4b60 matches provenance; focused log: 227 pass, 0 fail; tail-proof callers: ['publish_jog_receipt']`.

Relay closed (Approved), no further turn needed. Producer/harness proceeds to the classified gate before publication.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
