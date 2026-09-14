# RELAY · GH613 final implementation review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh613-final-implementation-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-613-CLAUDE-REVIEW-FIXES.md`, the full changed production files and regression evidence at `TESTS-RESULTS/2026-09-14+GH-613/`
- Reviewer: codex   ·   Producer: operator
- Started: 2026-09-13
- Definition of Done: Review the completed changes since ec0823abb084c62f494df4cd31432625f17a5c60 against the approved plan and five Opus findings. Full-source sweep the three Python modules; inspect the two narrow shell guards, tests and public docs. Verify actual shared helpers, auth/request restriction parity, strict success across auth modes, native effort and truthful telemetry, consult failure preservation, test falsifiability, and role/backward compatibility. Five mutants are rejected; native boundary control grants an extra fixture dir then denies it without that grant. Default CLI also denied outside reads: no prior data leak claimed. Existing consult process-group runner is unchanged; relay group/idle refactor is not claimed. The full pre-push gate is running independently; initial run exposed old metadata-only fake Claude results, now corrected in compatibility fixtures. Review code/evidence without claiming full-gate completion until the actual gate finishes. Only edit this relay; no test/*.sh, validate.sh or mutation scripts in the linked worktree. Return literal standalone VERDICT: PASS/FAIL and Basis: text, swept file: yes. Approve the implementation if sound; deployment/merge is not requested.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

VERDICT: PASS
Basis: The implementation is sound for the approved bounded Claude changes. Current SHA-256 values for all three production Python modules match provenance.jsonl. This is source/evidence review, not an independently executed gate or merge approval; the full gate remains outstanding. No git commands, artifact execution, or production edits were performed.
swept file: yes

- [Pass] Full-source sweep completed for `utils/py/claude_cli.py`, `utils/py/claude-turn.py`, and `utils/py/consult.py`, including their pre-existing paths. Shared `effort_flags`, `preflight`, and `read_result` remain the actual implementation seams (claude_cli.py:19, claude_cli.py:27, claude_cli.py:61); consult imports them at utils/py/consult.py:44. No additional blocking pre-existing defect identified in those modules within this review. Graph project XYZ-forge generation `2026-09-01T15:54:30Z` is a different checkout and reports missing/changed coverage for these paths; conclusions use the complete current source instead.
- [Pass] Both narrow shell guards refuse explicit subscription before legacy execution: relay-automation/claude-turn.sh:23 and relay-automation/consult.sh:23. Native consult passes the same `claude_settings` to auth and inference (utils/py/consult.py:568); relay unconditionally calls `read_result(claude_log)` after successful process exit (utils/py/claude-turn.py:196). Failed results still reach RTL enforcement. The inherit-result mutant records `inherit-error expected 5, got 0`, establishing a discriminating negative control.
- [Pass] Effort validation accepts only native values and is shared by both dispatches; relay telemetry uses `native_effort[1] if native_effort else "cli-default"`. The relay-effort mutant ends with `FAIL: relay omitted effort flag`. Durable stderr is opened separately and its path printed before relay dispatch; consult nonzero-result messages point to `.stderr` (utils/py/consult.py:727). Fix: none required.
- [Pass] Recorded native boundary evidence contains non-empty inside-marker success in both cases, outside-marker success with the explicit extra-directory grant, and denial without it (`TESTS-RESULTS/2026-09-14+GH-613/boundary-proof.jsonl:1`). The probe asserts those outcomes using random markers. Default denial is explicitly disclosed; this proves neither a prior leak nor an OS sandbox. Five recorded mutants are rejected (`mutant-results.jsonl:1`); descendant-kill output specifically reports `descendant survived kill` for both wall and idle controls. Fix: none required.
- [Pass] Consult cleanup uses Git removal only; a failed/timeout removal preserves the worktree, prints a recovery command and exits 5 (`utils/py/consult.py:842`). The forced-removal-failure fixture asserts retained registration and directory existence, then recovers through Git (`test/gh610-claude-subscription.sh:118`). Existing consult group termination is exercised, not newly implemented; no relay group/idle guarantee is approved.
- [Pass] Public setup distinguishes read-only consult from protocol-writing relay reviewers, preserves explicit Claude builder selection, and documents inherited settings changes and CLI-default effort (`relay-automation/README.md:67`, `relay-automation/README.md:80`, `relay-automation/README.md:90`). Compatibility evidence records containment, handoff, root routing, and successful real-shaped JSON fixtures (`TESTS-RESULTS/2026-09-14+GH-613/claude-compat.log:1`, `focused.log:1`). Fix: none required.
- [Nit] Programmatic consult still sends Claude the generic permission to execute `script_runner.py` (utils/py/consult.py:499), although its actual tools are only Read/Grep/Glob. The plan explicitly requested Claude-specific read-only instructions. Follow up by selecting a read-only preamble for the Claude seat; the current native tool restriction prevents this prompt mismatch from granting execution.
- [Nit] The wall/idle fixture tests runner helpers with a mocked idle sampler, then accepts absent or zombie child state (`test/gh610-claude-subscription.sh:155`). It does not drive the complete consult main path through timeout to assert failed-answer classification plus worktree removal. Add that integration case when extending timeout coverage; do not describe current evidence as complete end-to-end S4 proof. The source connects these paths, and the unchanged runner's five-mutant evidence supports this implementation approval.
- [Nit] Keep final bookkeeping accurate when the independent gate finishes: the active plan still has unchecked acceptance items and CHANGELOG.md:7 says full-gate evidence is recorded with the implementation PR. Update these with the actual final result before publication; no full-gate completion is established by this review. Omitted-effort telemetry is source-inspected, not independently checked against a persisted telemetry row here.

relay closed (Approved), no further turn needed. Operator owns remaining gate evidence and PR preparation.


### Attestation · relay-drive — 2026-09-14T01:41:19Z
task: RELAY-gh613-final
reviewer: codex
status: Approved
reviewed-head: 0c3da099a04d9ab5b941db89ccf8382186a4b143
added-range: 5072+5015
added-sha256: 250d8e3b9fad640cae1664f80892576c3a2a63f4c9ac382bb9aad9994c6956af
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
