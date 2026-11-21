# GH-1465 CodeRabbit follow-up

The four new Major failure paths from PR #1467 reproduced on the development-merged
baseline `985b6da13fa778a40897e0569977d237be4ed19f`. `red.json` records four false
contract outcomes with a passing normal-command control. `green.json` records the
same controls passing after the repair, plus real `relay_attest.load()` round trips,
tamper rejection, legacy trailer compatibility, source-drift refusal and allowed
transcript-only commits. Commands and nonempty output digests are in `provenance.jsonl`.

Run the retained manual artifact with `python3 manual-review-controls.py <source-clone> green`.
For the red control, extract `utils/py/proc_group.py`, `gate_env.py` and `relay_attest.py`
from the pinned baseline into a scratch root preserving `utils/py/`, then pass that
root and `red`. These are manual controls, not a new registered suite.

The process-lifetime controls inject bounded process states and a controlled RSS
sample; they do not allocate excessive memory or claim an observed host OOM.
The legacy normal-command record remains readable. New records mark command text as
JSON so embedded newlines stay on one line and citation canonicalization preserves it.

## Recon and repair bet

Graph leads used generation 2026-11-18T19:39:07Z and were checked against current source.
The current branch is newer than that graph; the branch's RSS additions were read directly.

| Seam | Current owner and downstream contract |
|---|---|
| Driver approval | `relay_drive.py:judge_terminal` runs the configured gate; `gate-failed` refuses attestation and follows the existing terminal refusal path. |
| Process lifetime | `proc_group.py:run_bounded` owns optional RSS monitoring and `kill_existing` owns group TERM/grace/KILL. Communication completion, rather than launcher exit, ends monitoring. Joining the watcher completes an already-started termination. |
| Command identity | `relay_attest.py:trailer_text` serializes new command metadata with an optional JSON format marker; `load` still checks the exact canonical trailer and digest. Records without the marker retain the old representation. |
| Source identity | `candidate_ok` retains isolation/artifact eligibility checks and shares its existing ancestor/content comparison through `source_matches`; the driver checks this before and after its gate. Source commits refuse; transcript-only commits remain allowed. |
| Gate environment | `gate_env.HARNESS_ENV` and marathon's existing literal scrub list remove `MARATHON_REVIEWER_GATE_CMD` only from the gate's children, preserving how the outer driver reads it. |

Bounded caller inspection confirmed that ATE, fuzzing, adapters, oracle calls, Jog and
wave-reconcile call `run_bounded` without an RSS cap. Their existing no-RSS path is
unchanged. RSS-specific lifecycle behavior changes for the reviewer gate. The
same process-group sampler remains shared with marathon's pre-advance guard.

Root cause: direct-child lifetime was substituted for group/communication lifetime,
termination was joined for less than its grace period, command metadata was emitted
as claim-bearing text, and the nested-gate variable was absent from the existing
environment classification. Fix sites are those existing owners; no separate runner,
registry or test suite is introduced.

Reversibility: **Costly**, because process-group behavior is shared and attestation
metadata is persisted. Roll back the repair commit before landing if controls,
existing coverage or independent QA fail. Ordinary callers and legacy record reading
are explicit compatibility controls. No installed harness is updated by this repair.

Unknowns: real host OOM and an external concurrently mutating checkout are not
recreated. Bounded API controls cover the reported watcher states, and Git fixtures
cover the source-comparison contract. Full-gate and independent-QA outcomes are
recorded separately; these manual controls do not establish promotion qualification.
