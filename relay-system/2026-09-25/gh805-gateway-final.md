# RELAY · GH805 gateway final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh805-gateway-final-qa): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: Review the Gateway continuation implementation versus its approved plan, not the untouched broader value census. Read coverage_admission.py, gate_inventory.py, githooks/pre-push, ci-route.sh, new admission/publish workflows, CODEOWNERS, protected publisher/catch-up, runbook, and changed existing tests. Operational envelope: one public repo, operator native review, no service, no new standalone suite, activation explicitly PENDING. Check complete manifest/stale refusal, cheap metadata-only follow-up, no candidate execution with privileged token, exact-head checks, bot event delivery, native reviewer identity, protected reconciliation/pending/self-recursion, and false completion claims. Focused provenance is under TESTS-RESULTS/2026-09-25+GH-805/gateway-focused. Historical full 422/422 predates gateway; a fresh final gate follows QA, so do not read it as gateway proof. Source code is implementation; live activation requires operator bootstrap and credential separation. Distinguish build blockers from explicit rollout prerequisites. Do not run tests in worktree; only thread writable, harness owns commit. Original template criteria: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Two bounded implementation gaps remain: executable-mode changes can evade the decision packet, and automated bot publication selects a full hosted canary even for metadata-only updates. Neither finding treats pending operator activation as a build failure.
swept file: yes

Read the entire seeded artifact, including its historical completion claims and explicit superseding caveat. Reviewed admission/inventory, hook/routing, workflows/CODEOWNERS, publisher/catch-up, runbook, gh419/gh740 and relevant gh421 assertions. No additional pre-existing defect established by this review; broader value-census work remains outside this turn's scope.

- [Should] **F1 — Make the documentation exemption respect executable modes.** `utils/py/coverage_admission.py:136` tests only the path, although the manifest already contains old/new modes. An executable with a documentation suffix returns before checking for a packet. Require a decision when either relevant side has executable mode; retain the ordinary non-executable documentation exemption. Extend gh419's existing controls, including a regular-document negative control.
  Observed input: Synthetic manifest row `dict(path='docs/runner.md', status='A', old_mode='000000', new_mode='100755', old_blob='0'*40, new_blob='1'*40)` passed to the real `inspect` classifier. This is a classifier probe, not a claim that this file exists in the branch.
  Affected scope: Documentation-suffix changes with old or new Git mode `100755`, including additions, removals and permission transitions; no request for a general content interpreter.
  Falsifier: A disposable-clone commit adding executable `docs/runner.md` without a packet must refuse; an ordinary `100644` documentation-only change must retain the exemption. A current-code refusal of the former would disprove the finding.
  Probe command (exit 0; no Git commands or candidate fixtures executed):
  ```python
  # PYTHONDONTWRITEBYTECODE=1; TMPDIR="$PWD/.relay-scratch/tmp"; python3 -
  import sys
  from unittest.mock import patch
  sys.path.insert(0, 'utils/py')
  import coverage_admission as a
  row=dict(path='docs/runner.md',status='A',old_mode='000000',new_mode='100755',old_blob='0'*40,new_blob='1'*40)
  with patch.object(a,'manifest',return_value=('b'*40,'c'*40,[row])), patch.object(a,'summary',return_value={}), patch.object(a,'git',side_effect=AssertionError('packet read')):
      print(a.inspect('.', 'base', 'head'))
  print(a.documentation('docs/guide.md'))
  ```
  Decisive output: `{'state': 'documentation-only; operator PR review still required'}` and `True`. Git/data acquisition and summary are stubbed; the real exemption branch is exercised. Native operator review is still required, so this is a coverage-decision omission, not an approval bypass.

- [Should] **F2 — Separate automatic publication checks from deliberate full-canary dispatch.** `coverage_admission.py:192` dispatches `ci.yml` for creation AND reuse. `utils/ci-route.sh:77` treats that event as an unconditional full run; `.github/workflows/ci.yml:244` enables the canary for dispatch, and its `Run validate.sh suite` step consumes `route=full`. Merely adding the packet to docs routing does not make this hosted publication path cheap. Provide a bounded automatic-publication dispatch path that still supplies exact-head blocking smoke/admission checks without selecting the expensive advisory full canary for a metadata-only refresh. Preserve deliberate full-run dispatch semantics.
  Observed input: `.github/test-admission.json` sent to the classifier with the exact event name emitted by `dispatch_checks`; command `printf '%s\n' '.github/test-admission.json' | bash utils/ci-route.sh workflow_dispatch`, exit 0, returns `docs_only=false`, `full_required=true`, `route=full`, `tier=3`, `tier_reason=operator-initiated full run`.
  Affected scope: Bot publisher creation/reuse and protected reconciliation calls through `dispatch_checks`; particularly a packet/evidence-only follow-up. This is static workflow reachability plus a real classifier query, not a measured hosted runtime claim.
  Falsifier: A disposable/hosted automatic-publication metadata-only control supplies current-head admission and blocking smoke while skipping the full advisory canary; an explicit operator full dispatch still selects full. If current automatic publication already skips that canary, show its exact-head job evidence.

- [Pass] **Proposal binding and authority separation are explicit in source.** `coverage_admission.py:150` compares the packet to a recomputed complete manifest; its manifest records both blob IDs and modes and excludes only the packet. `catalog` requires the operator ID, latest effective APPROVED state, exact head and a different PR author. `.github/CODEOWNERS` contains `* @noelsaw1`. These are source findings, not live enforcement proof.
- [Pass] **Trusted admission and protected publication are structurally separated from candidate execution/direct integration push.** `test-admission.yml` checks out `ref: development` with `persist-credentials: false`; `hosted` fetches objects and checks the live head before completing its check. `hosted_lane_publish.py:263` returns through protected publication; `publication_landing` checks bot identity, branch namespace and landed allowlisted paths. Native protection and credential separation remain rollout prerequisites per the runbook's “not activated/verified” instruction.
- [Unverified — needs clone run] No test suite, pytest, executable fixture, Git command, or live activation was run in this reviewer worktree. Existing `gateway-focused/provenance.jsonl` records focused greens and red controls, including the initial gh421 failure and subsequent green; those receipts do not prove the final post-review revision. The historical 422/422 is explicitly pre-gateway. Run the corrected focused controls and final macOS gate in the harness's disposable full clone before claiming final verification.

Handing off to Producer astra — address F1/F2 with bounded existing coverage and return for round 2. No artifact/source edits or self-commit made by this reviewer.

### Producer · Round 2

F1 Implemented: documentation exemption now requires regular non-executable mode on both sides. Existing gh419 exercises real Git additions, executable-to-regular transitions and deletion; seeded removal of that condition returns rc1. Ordinary 100644 docs still pass without a packet.

F2 Implemented: bot dispatch passes `publication_only=true`; existing CI skips its advisory full canary for that input while retaining unconditional blocking smoke. Manual default remains false/full, and concurrency separates publication from deliberate full dispatch. Existing ci-workflow/gh379 controls pass; removing the cost guard returns rc1. Native hosted behavior still awaits publication/bootstrap and is not claimed from YAML. Explicit POST/PATCH methods now avoid relying on gh body-only method inference, with focused request controls.

Evidence retained in gateway-focused: corrected gh419, ci-workflow and gh379 green; red-executable-doc and red-publication-cost nonzero. Local admission check median was 0.088s over five observations, not approval latency. Review the complete implementation and these dispositions; no scope expansion to the broader value census. Handing off to codex for round 2.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: F1/F2 are resolved within the approved Gateway scope. No remaining build blocker established. Approval is source/retained-focused-evidence QA, not final-gate success, merge authorization, or live activation.
swept file: yes

Swept the entire seeded artifact, admission and inventory modules, push hook/routing, admission/publication/CI workflows and CODEOWNERS, protected publisher and catch-up seam, runbook, and relevant existing test controls. No additional pre-existing defect established in the reviewed Gateway scope. Broader value-census acceptance remains incomplete.

- [Pass] **F1 closed.** `utils/py/coverage_admission.py:137` requires both modes to be absent or regular non-executable before applying the documentation exemption. Existing gh419 includes ordinary documentation, executable addition, permission transition and deletion controls. Narrow classifier probe below independently reproduces refusal for the three executable cases while retaining regular documentation exemption. Retained `gateway-focused/red-executable-doc.log` contains `AssertionError: bad proposal was accepted`; its provenance records rc 1, with corrected gh419 rc 0 at `8e3d2bd4`.
- [Pass] **F2 closed.** `coverage_admission.py:195` supplies `publication_only=true`; `.github/workflows/ci.yml:252` excludes that input from the canary, while `vendored-smoke` at line 518 has no job condition. The input defaults false and concurrency separates publication/default lanes. Retained `red-publication-cost.log` records `FAIL: publication dispatch unexpectedly runs full canary or omits smoke`; provenance records rc 1 and corrected ci-workflow/gh379 rc 0 at `8e3d2bd4`. This establishes source wiring and recorded controls, not hosted event delivery.
- [Pass] **Authority and containment remain explicit.** Admission checks the complete manifest and current head (`coverage_admission.py`, `inspect`/`hosted`); trusted admission checkout states `ref: development` and `persist-credentials: false`. `catalog` requires the operator's latest effective exact-head approval and different authorship. Protected publication returns through `publish_review` without direct-push fallback; `publication_landing` checks bot identity, namespace and actual allowlisted landed paths, and `wave_reconcile.py:1239` consumes it. The runbook explicitly requires credential separation and labels rollout “not activated/verified.”
- [Unverified — needs clone run] Final macOS gate and exact-head hosted checks remain outstanding. No Git command, test suite, pytest or executable fixture ran here. Historical 422/422 predates this gateway. Native stale-review dismissal, protected direct-push refusal, bot event delivery and protected reconciliation require the documented operator bootstrap/live rollout; this verdict does not close those checkboxes or #805.

Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` with the following stdin (exit 0; Git acquisition/API calls stubbed, no fixture execution):
```python
import sys
from unittest.mock import patch
sys.path.insert(0,'utils/py')
import coverage_admission as a
for old,new in [('000000','100644'),('000000','100755'),('100755','100644'),('100755','000000')]:
    row=dict(path='docs/runner.md',status='M',old_mode=old,new_mode=new,old_blob='0'*40,new_blob='1'*40)
    with patch.object(a,'manifest',return_value=('b'*40,'c'*40,[row])), patch.object(a,'summary',return_value={}), patch.object(a,'git',return_value=''):
        try: print(old,new,a.inspect('.','base')['state'])
        except ValueError as e: print(old,new,'REFUSED:',e)
calls=[]
with patch.object(a,'gh',side_effect=lambda *args: calls.append(args)):
    a.dispatch_checks('owner/repo',{'number':1,'head':{'ref':'feat/coverage'}})
print('dispatch:',calls)
```
Decisive output: `000000 100644 documentation-only; operator PR review still required`; each executable pair returned `REFUSED: missing regular admission packet; run gate_inventory.py admission prepare`. Dispatch calls targeted `test-admission.yml` on `development` with PR `1`, then `ci.yml` on `feat/coverage` with `{'publication_only': 'true'}`.

Relay closed (Approved), no further review turn needed. Producer astra/harness next runs the final disposable-clone gate and retains evidence before the separate operator rollout handoff. Only this relay file was edited; no self-commit.


### Attestation · relay-drive — 2026-09-25T05:05:21Z
task: GH805-GATEWAY-FINAL
reviewer: codex
status: Approved
reviewed-head: 164a2a0a3da65967bda8b49f52304831db9ec7d5
added-range: 13952+4441
added-sha256: 1786e7270ce9bb03d7d7626e44ee179aa86e4c4efa916c057a5085d9c43c67e6
### Producer · Round 3

Reopened for a concrete concurrency correction after round 2 approval: a shared admission filename makes independent PRs conflict. One UUID-named record per integration change now replaces that shared file. The same gateway/schema/authority remain; historical records cannot be modified, malformed/multiple records refuse, and the protected publisher and metadata router use the new path. No new suite registration.

Focused evidence at `gateway-record-focused/provenance.jsonl` records gh419, gh740, gh421 and ci-route passing on 3c9506c3, with unchanged clone identity. gh419 witnesses a real merge conflict for the former shared filename, a clean merge for independent UUID records, and extraction of only the incoming record after merging another branch. The full pre-push run on 2f75a185 is intermediate, not final proof of this change.

Review the complete relevant files, concentrating on this changed storage contract: (1) Are all manifest callers and publisher/catch-up consumers consistent? (2) Does the immutable one-new-record rule reject omission, stale metadata and historical mutation while allowing parallel PRs? (3) Do routing/docs preserve cheap metadata follow-ups and truthful pending activation? This is round 3 of the same capped review, not a fresh review budget. A fresh tick token only accommodates the previous token's terminal approval state. No suite execution in the reviewer worktree; thread writes only. Handing off to Reviewer codex.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
