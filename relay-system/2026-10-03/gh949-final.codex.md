# RELAY · GH-949 final runtime QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
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
6. **Commit only the relay file** (`relay(gh-949-final-runtime-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-949-ATE-REMEDIATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-949-ATE-REMEDIATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-03
- Definition of Done: All F1–F9/K1 acceptance criteria in canonical plan Phase 2, source contracts and retained before/after proof; no new suite or registry entries. Final full gate is deliberately after independent runtime approval.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet

Review the complete changed runtime files against base3fbed72f781d1ad060e298b798a44c32edef393d, canonical plan/recon and TESTS-RESULTS/2026-10-03+GH-949/SUMMARY.md. Runtime candidate76ad7e4e; later commits are evidence/ledger/docs. Scope: utils/py/proc_group.py, domain_oracles.py, metamorphic_oracle.py, utils/ate/scripts/run_variations.py, skills/1-hourly/relay-xyz/find-harness.sh, test/lib/runner-envelope.sh. Inspect entire files and existing callers, especially cancellation cleanup/ACK, timeout versus genuine124, threaded repeats, Git common/worktree metadata, ATE records/consumer contracts, HOME and selector precedence. Manual base/repaired controls and nine existing focused suites passed on candidate; raw provenance committed. Review the ratings90/85/50/55 and82/80/50/85 against the stated evidence, neutral appeal/no overrides. Scope is a local developer tool; apply commensurate complexity, no unrequested framework or enterprise threat model. Zero-budget returns nonzero/no-new-row but retains baseline initialization; only empty-grid admission has a no-write promise. Normal successful background policy and SIGKILL/session escape are outside the repair contract.

Review-only: edit this transcript only, no production edits, no live model tests, no mutation-heavy suites or gates in this task clone or linked review worktree. The final full local gate will run once after approval in a separate full verification clone through the required push hook. Flag concrete failures with input/scope/falsifier; no speculative new machinery. Evidence wrapper caveats are explicitly retained in SUMMARY. Produce PASS/FAIL and grounded whole-file sweep. Signature requested by operator for this review: GPT 6 Astra Light. Three rounds maximum. Marker remains last.

## Log


### Reviewer · Round 1

VERDICT: FAIL
Basis: One observed false-pass in the touched domain idempotence oracle prevents runtime approval. The retained F1–F9/K1 repair evidence otherwise supports the bounded changes; the final full gate remains pending.
swept file: yes

Reviewer: codex. Operator-requested signature label: GPT 6 Astra Light (runtime model identity not independently attested).

- [Blocker] **R1 — compare the first observation with subsequent observations.** At `utils/py/domain_oracles.py:383`, the first-run comparison iterates `inner.get("results", [])`; `utils/py/metamorphic_oracle.py:210` actually returns `exit_codes` and `stdout_hashes`, never `results`. Consequently first-run rc/output divergence is ignored. The documented contract at `domain_oracles.py:363` includes rc/output idempotence, not merely stabilization after the first run. This is an existing defect exposed by the required whole-file sweep, not a claim that GH-949 introduced it.
  Observed input: three completed BoundedResult observations with unchanged tree/receipts: `[(7,"same"),(0,"same"),(0,"same")]`, and separately `[(0,"first"),(0,"later"),(0,"later")]`. Both produce `passed=true, reasons=[]`.
  Affected scope: domain `check_idempotence_oracle` calls where the first completed command's exit code or stdout differs from otherwise identical later repetitions.
  Falsifier: `[(0,"same")]*3` must remain passing; `[(0,"same"),(7,"same"),(0,"same")]` must remain failing; first-only rc/output differences must fail. Preserve permitted first-run tree/receipt initialization and genuine nonzero-but-identical diagnostic results.
  Root cause: consumer reads a nonexistent producer result key and never compares first stdout; Fix site: the existing domain oracle's first-versus-inner comparison; Why not upstream/downstream: the shared metamorphic result already supplies the required exit codes and stdout hashes.
  Concrete fix: compare `first["rc"]` and the SHA-256 of `first["stdout"]` with the existing `inner["exit_codes"]` / `inner["stdout_hashes"]`, retaining incomplete-observation rejection. Record red/green manual evidence or use the existing suite; do not add a suite or framework.

  Review probe command (in-memory boundary substitution, no child processes, Git commands, fixture execution, or source edits):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 - <<'PROBE'
  import sys,json
  from unittest.mock import patch
  sys.path.insert(0, 'utils/py')
  import domain_oracles as d
  import metamorphic_oracle as m
  from proc_group import BoundedResult
  for label, observations in [
   ('stable',[(0,'same')]*3),
   ('first_rc_differs',[(7,'same'),(0,'same'),(0,'same')]),
   ('first_output_differs',[(0,'first'),(0,'later'),(0,'later')]),
   ('later_rc_differs',[(0,'same'),(7,'same'),(0,'same')]),
  ]:
   rows=iter(BoundedResult(rc,out,'',False,1,0) for rc,out in observations)
   def bounded(*a,**k): return next(rows)
   with patch.object(d,'run_bounded',bounded),patch.object(m,'run_bounded',bounded),patch.object(d,'tree_digest',return_value=('unchanged',1)):
    r=d.check_idempotence_oracle(['observed-command'],'.',repetitions=3)
   print(json.dumps({'case':label,'input':observations,'passed':r['passed'],'first_rc':r['run']['rc'],'inner_exit_codes':r['inner']['exit_codes'],'reasons':r['reasons']}))
  PROBE
  ```
  Exit status: **0** (probe completed; this is not a passing product assertion). Decisive output: stable → `passed:true`; first_rc_differs → `passed:true, first_rc:7, inner_exit_codes:[0,0], reasons:[]`; first_output_differs → `passed:true, reasons:[]`; later_rc_differs → `passed:false, reasons:["exit code / output digest diverged across repetitions"]`. This isolates the missing first comparison; actual process/fixture replay belongs in the verification clone.

- [Pass] **Cancellation/timeout implementation and retained controls:** `proc_group.py:136` cleans the group on BaseException and re-raises; CLI cancellation handlers are outside the threaded library. `proc_group.py:178` admits timeout before spawn. `TESTS-RESULTS/2026-10-03+GH-949/manual-process/after/summary.json` and `manual-process/compat-after/summary.json` retain child-reaped, prior-row, ACK repeated-signal, SystemExit77 and true-exit124 controls. These are reviewed retained results, not suites rerun in this worktree.
- [Pass] **State, ATE and environment repair evidence:** `domain_oracles.py:94` hashes directory symlinks; `domain_oracles.py:246` resolves common/worktree config; `run_variations.py:435` refuses empty grids before control/baseline writes, and `run_variations.py:487` funnels interruption/launch failure into the existing row path. `manual-state/base/results.json` contains 4/14 correct properties versus 14/14 in `manual-state/after/results.json`; `manual-contracts/results.json` retains failure-row consumer and threaded timeout controls. `find-harness.sh:131` guards HOME fallbacks; `test/lib/runner-envelope.sh:62` scrubs only the two inherited selectors. The environment provenance records both focused commands at rc0, while SUMMARY explicitly preserves the separate stale-SHA wrapper failure.
- [Pass] **Ratings are proportionate judgments, not measured probabilities:** the canonical plan's “Ratings dated2026-10-03” paragraph supports 90/85/50/55 and 82/80/50/85 with potential continuing writes, one documented3373s false-red gate, neutral appeal, no override and unknown trend. No inflation from claimed production loss or an invented second incident is needed.

Sweep covered all six complete runtime files, the canonical plan/recon, retained result/provenance records, and caller seams in fuzz_engine, claude_cli, wave_reconcile, runaway-guard, checkin, compile_issue and the two gate runners. No other concrete blocker was identified in that bounded sweep. Graph limitation: no project indexes this review worktree; nearest XYZ-forge graph is generation2026-09-01T15:54:30Z in another checkout. Search had no remaining page; coverage reports four paths not_tracked and the ATE subtree excluded. Even the metamorphic metadata match belongs to that other checkout, so all six files were read directly. No Git command or prohibited suite was run; base-to-candidate diff/commit membership was not independently established under the no-Git restriction. Full qualifying gate: [Unverified — needs clone run], deliberately scheduled after approval.

Handing off to Producer (codex-producer): disposition R1, make the focused correction and retain its red/green evidence, then request round 2. No approval or merge-readiness attestation yet.

### Producer · Round 2

Disposition R1: Implemented in984b7f64. Compare first rc and SHA-256(stdout) with the existing inner exit_codes and stdout_hashes; incomplete observations still fail. Actual-process witness under TESTS-RESULTS/2026-10-03+GH-949/manual-idempotence shows both first-only differences falsely pass before and fail after; stable remains passing. No new API, test suite or gate. The two affected existing oracle suites were rerun; see provenance in that directory. Earlier manual controls and focused results remain applicable to unchanged runtime files.

Request independent round2 review of the correction and whole-file contracts. Full local gate is still pending approval. Handing off to Reviewer.

### Reviewer · Round 2

VERDICT: PASS
Basis: R1 is resolved using the existing result fields, supported by actual-process red/green evidence and an independent in-memory compatibility probe. No additional concrete blocker found in the bounded whole-file sweep. Runtime review is approved; the full qualifying gate remains pending.
swept file: yes

Reviewer: codex. Operator-requested signature label: GPT 6 Astra Light (runtime model identity not independently attested).

- [Pass] **R1 closed.** `utils/py/domain_oracles.py:383` compares the first rc against `inner["exit_codes"]`; the following stdout comparison uses the same SHA-256 encoding as `utils/py/metamorphic_oracle.py:184`. First/inner incomplete-observation checks remain. `TESTS-RESULTS/2026-10-03+GH-949/manual-idempotence/before/results.json` records both first-only divergences falsely passing; `after/results.json` records both rejected and stable passing. The retained replay script uses real commands with counters outside the digested directory. `manual-idempotence/provenance.jsonl` records both affected existing suites at rc0 on984b7f64.
- [Pass] **Compatibility probe:** stable exit0, stable exit7 and genuine exit124 pass; first-only rc, first-only stdout, later rc, all-timeout and later-timeout fail. Source: `domain_oracles.py:367` through its return block and `metamorphic_oracle.py:180` through its return block. Command below exited **0**. Decisive output: `stable=true, stable_nonzero=true, genuine124=true, first_rc=false, first_stdout=false, later_rc=false, timeout=false, later_timeout=false`. First divergence reasons respectively: `exit code differs from first run` and `output digest differs from first run`. No child processes, executable fixtures or Git commands ran.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PROBE'
import sys,json
from unittest.mock import patch
sys.path.insert(0,'utils/py')
import domain_oracles as d
import metamorphic_oracle as m
from proc_group import BoundedResult
cases=[
('stable',[(0,'same',False)]*3,True),
('stable_nonzero',[(7,'same',False)]*3,True),
('genuine124',[(124,'same',False)]*3,True),
('first_rc',[(7,'same',False),(0,'same',False),(0,'same',False)],False),
('first_stdout',[(0,'first',False),(0,'later',False),(0,'later',False)],False),
('later_rc',[(0,'same',False),(7,'same',False),(0,'same',False)],False),
('timeout',[(None,'same',True)]*3,False),
('later_timeout',[(0,'same',False),(None,'same',True),(0,'same',False)],False)]
for label,observations,expected in cases:
 rows=iter(BoundedResult(rc,out,'',timeout,1,0) for rc,out,timeout in observations)
 def bounded(*a,**k): return next(rows)
 with patch.object(d,'run_bounded',bounded),patch.object(m,'run_bounded',bounded),patch.object(d,'tree_digest',return_value=('unchanged',1)):
  r=d.check_idempotence_oracle(['observed-command'],'.',repetitions=3)
 print(json.dumps({'case':label,'passed':r['passed'],'reasons':r['reasons']}))
 assert r['passed'] is expected
PROBE
```

- [Pass] **Remaining bounded contracts retained:** `proc_group.py:136` cleans/reaps on BaseException; CLI timeout admission precedes Popen and ACK/publication are enclosed by cleanup. `domain_oracles.py:94` includes directory links; `host_identity` resolves common/worktree config with explicit errors. `run_variations.py:435` rejects empty grids before writes; its existing append path records launch/cancellation failures and UTC timestamps. `find-harness.sh:131` guards optional HOME; `runner-envelope.sh:62` scrubs only inherited locator selectors, with runner callers at `validate.sh:1238` and `ci-local.sh:399`. Canonical Phase2 and SUMMARY retain earlier controls and the wrapper-failure caveat. Zero-budget baseline initialization and normal-success background policy remain expressly accepted boundaries.
- [Pass] **Ratings:** the plan's “Ratings dated2026-10-03” paragraph grounds90/85/50/55 and82/80/50/85 in potential continuing writes and the documented3373s false-red gate, with neutral appeal, no override and unknown trend. These are judgments supported by the stated bounded evidence.

Sweep: read all six complete runtime files, plan/recon, SUMMARY and R1 replay/results/provenance; inspected shared process callers in fuzz_engine, claude_cli and wave_reconcile plus both envelope invocation sites. No further concrete pre-existing defect requiring a change was identified in this bounded review. Graph limitation persists: all77 projects enumerated; none indexes this worktree. Nearest XYZ-forge index is another checkout, generation2026-09-01T15:54:30Z; six-path coverage cannot attest this candidate, so direct source was used. Base/candidate commit membership was not independently established under the no-Git restriction.

[Unverified — needs clone run] Final full qualifying gate and final-state clone identity remain the Producer/harness next step. No suite, executable fixture, live model or Git command was executed here. This approval does not attest merge readiness.

Relay closed (Approved), no further review turn needed. Handing completion to codex-producer for the required separate-full-clone gate and subsequent handoff.


### Attestation · relay-drive — 2026-10-03T07:36:18Z
task: RELAY-GH949-FINAL
reviewer: codex
status: Approved
reviewed-head: 59d666cdcf0ce839a4050447c048c50117aea8cc
added-range: 14718+5197
added-sha256: 7dfa96894388f7ed80e52d721fa18f96a54410796b919515672b8b3d6adaea88
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
