# RELAY · GH1092 final Codex QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: done
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1092-final-codex-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: relay-automation/relay-turn-lib.sh and skills/1-hourly/relay-xyz/SKILL.md, integration diff against ed0a386fac4caa170bd9d6b297da7154717288df
- Reviewer: codex   ·   Producer: implementation
- Started: 2026-11-12
- Definition of Done: Bounded #1092 shared-prompt plan, measured delivery acceptance and regression evidence; no closure of #1092 or LTVera GH981. Approval of implementation precedes the exact-commit full gate and publication.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## FINAL QA packet

Normal independent Codex FINAL QA, <=3 rounds. Operational envelope: local operator CLI;
no new controller, gate, suite, registry, global install, LTVera implementation or merge.
Read the plan PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md, PLAN relay,
TESTS-RESULTS/2026-11-12+GH-1092/SUMMARY.md and provenance, main and foreign smoke relays,
source diff and WHOLE touched source files. Existing issue acceptance remains in the plan;
unimplemented GH981/Radar requirements explicitly remain open. PR1432/1445 reused unchanged.

First resolve the main runtime-smoke prerequisite, then assess the implementation. Prior
main thread remains parked (three launches, one actual reviewer round); do not modify it or
re-fire its token. This FINAL turn must record its own independent measurement before approval.
The prior failure was mktemp using macOS Darwin user-temp outside its sandbox roots, not a
suite assertion failure. The orchestrator now supplies both exact clone and OS temp root as
sandbox writable roots; this is an execution context, not a policy waiver or suite edit.

Supplied separate disposable full clone:
/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12-verify
Expected HEAD equals THIS review worktree HEAD; full .git dir=true, bare=false, local user.name
and user.email unset, origin ends `/XYZ-forge-gh1092-reviewer-evidence-2026-11-12/.`.
Read root/HEAD/origin/bare/local identity before/after without mutating Git. No source edits.
Assigned command ONLY there: `PATH=/Users/noelsaw/.cache/xyz-forge-test-venv/bin:$PATH bash test/gh681-reviewer-probe-rules.sh`.
Record command, exit, decisive assertion output and identity bracket in this relay. This existing
focused suite exercises main scratch-only and adjacent forbidden residue paths; no full suite here.
If runtime remains unavailable, do not approve: name its exact predicate and retain Unverified.

Questions after that measurement:
1. Does actual prompt/transcript deliver the correct target test policy and pinned supplied-clone
   permission, preserve narrow GH1428 exception and producer behavior, and avoid blanket gates?
2. Does the baseline REJECT plus candidate render/live foreign/main evidence establish this
   limited delivery change? Do not mistake wording checks or attestation for browser safety.
3. Does the existing writer path remain single, and does whole-file inspection find regressions
   or pre-existing defects relevant to this change? Cite concrete input/scope/falsifier.
4. Are all original requirements retained, partial scope and owner recommendations honest,
   rating still 75/70/50/65 no override, no new test suites/registry, no stale evidence relabeled?
5. Is the implementation ready for the required route=full/tier=3 gate on the final approved
   commit? Full gate is deliberately pending until your approval (installed start-task Step 7:
   exactly once on final approved commit). A failed gate will block publication, not be waived.

Quote VERDICT/Basis, swept file yes/no and source/evidence citations. Only relay tracked writes;
no other delegates or Kimi. Parent will perform additional Kimi review after normal QA.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The bounded source change matches the approved plan, but the required independent main runtime measurement did not pass. The supplied clone now permits fixture creation; the assigned suite instead exits 1 at its Producer-role assertion under inherited driver state. Cases 7–8 were not reached, so approval and the final full gate must wait for a correctly assigned execution context.
swept file: yes

- [Blocker] B1 — Resolve the supplied-command environment before claiming main acceptance. Executed only the assigned command in the supplied disposable full clone: `PATH=/Users/noelsaw/.cache/xyz-forge-test-venv/bin:$PATH bash test/gh681-reviewer-probe-rules.sh`, with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR=/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.w1Vz2t/.relay-scratch/tmp` exported. Exit **1**. Decisive output: `workdir: /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-gh681-reviewer-probe-rules.XXXXXX.HnipbT18Dg`; eight case-1 PASS lines and two case-2 PASS lines, then `FAIL: case 3: producer prompt lost its verification clause`. This supersedes neither the historical mktemp failure nor the producer's earlier green receipt. Source explains the context conflict: `relay-automation/relay-turn-lib.sh:90-93` gives inherited driver role priority; `test/gh681-reviewer-probe-rules.sh:65-70` changes NEXT to Producer without clearing that role; `test/_setup.sh:28-44` does not clear the driver marker/role or reviewed-head pin. Have the orchestrator explicitly assign the same suite with irrelevant inherited relay-driver state removed in the command's child environment (including the reviewed-head pin used by fixture worktrees); retain identity brackets and the complete result. Do not weaken production role precedence or add a suite/controller. I did not silently alter the assigned command or rerun it.
  Observed input: Actual environment `RELAY_DRIVER_LOCKED=1`, `RELAY_ROLE=reviewer`, `RELAY_REVIEWED_HEAD=f66f9692735bbad9be34d3dc00d6a4094ed40fc1`, plus the fixture's literal `NEXT: Producer` at case 3; observed exit 1 above.
  Affected scope: This orchestrator-supplied independent smoke execution and the existing suite's inherited-environment sensitivity; no demonstrated regression in the new reviewer-note wording.
  Falsifier: An explicitly assigned, child-environment-clean execution of the unchanged existing suite at the reviewed revision must reach and pass Producer classification, scratch-only acceptance, forbidden `.pytest_cache` rejection and reviewer-only env injection. If that still fails, investigate the actual remaining failure; an earlier producer receipt or wording pass cannot satisfy this predicate.

- Identity bracket (read-only Python pathlib/configparser, exit 0 before and after; no Git invocation): resolved root `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12-verify`; `.git` is a full directory; HEAD `f66f9692735bbad9be34d3dc00d6a4094ed40fc1`, equal to this protected review worktree HEAD; origin `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12/.`; bare `false`; local user.name and user.email both unset. All values identical after execution (`identity unchanged: True`). No repair or shared Git mutation performed by reviewer.
- [Pass] Target/rule delivery is present in the actual received prompt: “Read the target checkout startup instructions” and “XYZ-forge AGENTS.md GH-831 is Forge-only”; it also delivers the supplied revision-pinned clone restriction and identity brackets. Target root is `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12`, inspected through protected worktree `/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.w1Vz2t`, revision above. Rules read: `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `SOP.md`, `WORKTREE-SAFETY.md`, `PROJECT/PDDA.md`, `TESTS-RESULTS/README.md`, `HARNESS-MODELS-REGISTRY.md`; SWE and relay-xyz skills consulted. Forge's own AGENTS “No new tests (GH-831)” and “Run mutation-heavy suites only in a separate disposable FULL CLONE” apply here. This turn's explicit single-suite assignment governs execution; foreign targets retain their own policy.
- [Pass] Surgical implementation and single writer: read both touched files in full. Read-only `gh api repos/HiQS-Labs/XYZ-forge/contents/<path>?ref=ed0a386fac4caa170bd9d6b297da7154717288df`, followed by base64 decode and Python unified comparison (exit 0, nonempty source asserted), shows only `relay-turn-lib.sh:1067` and `skills/1-hourly/relay-xyz/SKILL.md:717` changed. The Producer verification clause at `relay-turn-lib.sh:1043` and existing GH1428 named phase exception are retained; containment/enforcement writers are unchanged. `utils/py/rtl.py:865-868` still delegates prompt construction to the shared owner. Read-only tarfile comparison (exit 0) reported `package member relay-automation/relay-turn-lib.sh equals source True`. No parallel controller, registry or test suite is introduced by these changes. The pre-existing environment interaction in B1 is the concrete relevant sweep finding; no additional pre-existing defects were identified in the whole-file sweep. Graph discovery was attempted first and returned “MCP tool call requires approval, but approval policy is never”; direct source inspection was the fallback.
- [Pass] Evidence boundaries remain honest: `TESTS-RESULTS/2026-11-12+GH-1092/delivery-control.json` records baseline “REJECT” with eight missing delivery clauses and candidate “PASS (render only; live transcript pending)”; paired nonempty prompt files contain those different role notes. `gh1092-smoke-main.codex.md` retains PARKED/exit 2, while `gh1092-smoke-foreign.codex.md` identifies LTVera's own justified-new-tests/disposable-Postgres policy and refuses the unsupplied browser-runtime claim. `SUMMARY.md` says “This PR must not close Forge #1092 or LTVera GH981” and “Full qualifying gate: pending”; it preserves the earlier failed launches and disclaims browser safety. Together these support limited instruction delivery, not completed main runtime acceptance. The current case-1 assertion output independently demonstrates live receipt; B1 prevents calling the combined acceptance complete.
- [Pass] Scope/rating continuity: `PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md` sections “Requirements continuity and remaining gaps” and “Rating and QA evidence” preserve all eight original requirements, six decisions' remaining predicates, no closure of either issue, and owner recommendations as proposals. `releases.sql:1001` retains 75/70/50/65 and NULL override. PLAN Round 1 FAIL and Round 2 Approved remain intact; provenance keeps original revisions/exits rather than relabeling failures. Reversibility remains Easy for this prompt/docs/package change. No fresh live issue-status or complete historical requirement audit is claimed in this turn.
- [Unverified — needs clone run] Main scratch-only/forbidden-residue behavior and full delivery acceptance remain pending because this independent run stopped before case 7. Producer regression receipts are supporting history, not independent runtime verification. The classified route=full/tier=3 exact-final-approved-commit gate deliberately remains pending; no full gate, pytest, other suite, new clone, or delegated review was run. Approval must precede that gate, and a failed gate must block publication.

Handing off to Producer (implementation) — supply an explicitly environment-clean assigned command for B1 and reopen the next review round; go to the Producer window and say 'take your turn'.

### Producer · Round 2

B1 [Blocker], disposition: Modified execution context, not production behavior. The command
below supersedes the initial packet's assigned command for this and later review rounds.
Only its child process loses inherited relay state; the outer driver/token remains intact:
`PATH=/Users/noelsaw/.cache/xyz-forge-test-venv/bin:$PATH env -u RELAY_DRIVER_LOCKED -u RELAY_ROLE -u RELAY_REVIEWED_HEAD bash test/gh681-reviewer-probe-rules.sh`.
Run it ONLY in the same supplied disposable full clone after the same identity bracket;
its HEAD must equal this review worktree HEAD. Same sandbox roots as round1, no new permission
scope. No suite/source edits. Producer replay with deliberately contaminated outer role/lock/head
and this child command passed at f66f9692; receipt clean-env-control.log/provenance retained.
That is supporting evidence, not independent closure: reviewer must rerun before approving B1.
Original failed launches, parked smoke and FINAL round1 failure are retained unchanged.

Upstream development advanced to 712a73b4f3b01c8acc2c5115d11f855c62a2e537. New work adds a
final-acceptance question at another location in relay-xyz; no other implementation overlap.
Read upstream-nonoverlap.diff and mergeability.txt receipts. A non-mutating branch-state
merge-tree check returned a conflict-free prospective tree containing BOTH clauses. No branch
merge/rebase, no history rewrite (preserves review/input SHAs), no PR merge authorization used.
Recheck live upstream if needed using read-only GitHub source; do not demand duplicate wording.

After actual runtime succeeds, adjudicate B1 and finalize normal source QA using the retained
round1 whole-file source assessment plus these changed inputs. Full gate remains pending on
final approved commit. No Kimi or other delegate. Handing off to codex.

### Reviewer · Round 2

VERDICT: PASS
Basis: B1 is resolved by an independently executed, explicitly reassigned child-environment-clean run of the unchanged existing suite. All eight cases pass with unchanged clone identity. Approve the bounded instruction-delivery implementation for the required exact-final-commit full gate; this is not publication, merge readiness, issue closure or browser-safety certification.
swept file: yes

- [Pass] B1 closed. Executed exactly the Producer Round 2 assignment, only in the supplied disposable full clone: `PATH=/Users/noelsaw/.cache/xyz-forge-test-venv/bin:$PATH env -u RELAY_DRIVER_LOCKED -u RELAY_ROLE -u RELAY_REVIEWED_HEAD bash test/gh681-reviewer-probe-rules.sh`. Suite exit **0**. Exported `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` from this protected worktree before launching. Decisive output: `PASS: case 3: producer prompt keeps its own verification clause`; `PASS: case 7: a probe that writes only under .relay-scratch/ is not off-lane`; `PASS: case 7: a probe that leaves .pytest_cache/ in the worktree is off-lane (residue still fails the turn)`; `PASS: case 8: apply_reviewer_turn_env injects PYTHONDONTWRITEBYTECODE and TMPDIR for reviewer turns only`; `gh681-reviewer-probe-rules: all cases passed`. This independently reaches the cases absent from Round 1. The negative residue case retains a witnessed rejection; no production-role precedence or suite changes were needed.
- Identity bracket: read-only Python pathlib/configparser before and after, wrapper exit **0**; resolved root `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12-verify`; full `.git` directory **true**; HEAD **c460929878066a3f09d20dfff0f9d35a70fc9f4a**, equal to this review worktree HEAD; origin `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12/.`; bare **false**; local user.name and user.email **unset**. After: identical values, `IDENTITY_UNCHANGED True`. No Git command was invoked by this reviewer; the expressly assigned existing suite ran its own fixtures.
- [Pass] Target/rules and delivered policy: target root `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12`, protected review worktree `/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.TN8Y82`, reviewed revision above. Startup/canonical paths consulted: `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `SOP.md`, `WORKTREE-SAFETY.md`, `PROJECT/PDDA.md`, `TESTS-RESULTS/README.md`, `HARNESS-MODELS-REGISTRY.md`; relay-xyz and SWE skills applied. Forge AGENTS says “No new tests (GH-831)” and “Run mutation-heavy suites only in a separate disposable FULL CLONE”; the narrow explicit assignment governs this turn. Actual received prompt and `relay-automation/relay-turn-lib.sh:1067` both deliver target-policy discovery, Forge-only scope, pinned supplied-clone commands and identity checks. Existing GH1428 named phase exception and Producer clause at `relay-turn-lib.sh:1043` remain. Foreign smoke explicitly cites LTVera `AGENTS.md:1341` (“New tests are allowed when they are justified”) and disposable Postgres policy; it does not import Forge's moratorium.
- [Pass] Source/ownership sweep: reviewed both complete touched source files using the retained Round 1 whole-file assessment plus current reads and comparison. Read-only `gh api repos/HiQS-Labs/XYZ-forge/contents/<path>?ref=ed0a386fac4caa170bd9d6b297da7154717288df`, base64 decode with nonempty assertions and Python unified comparison returned **0** for both files: only the reviewer role note at `relay-turn-lib.sh:1067` and permission mirror at `skills/1-hourly/relay-xyz/SKILL.md:717` differ. `utils/py/rtl.py:865-868` delegates to that shared prompt owner. Python tarfile read, exit **0**, reported `PACKAGE relay-automation/relay-turn-lib.sh True` against the current source. No extra writer, controller, registry or suite appears in these source changes. No additional relevant pre-existing defect found; the inherited-environment interaction from B1 remains documented, with its execution-context resolution. Graph search was attempted first and returned “MCP tool call requires approval, but approval policy is never”; source reads were the fallback.
- [Pass] Limited delivery acceptance is discriminating: `TESTS-RESULTS/2026-11-12+GH-1092/delivery-control.json` retains baseline `REJECT` with eight missing clauses versus candidate `PASS (render only; live transcript pending)`. That lexical control alone is insufficient; this turn supplies actual main-target receipt and independent assigned-check execution, while `gh1092-smoke-foreign.codex.md` supplies foreign-policy delivery and the explicit missing-runtime refusal. Historical main PARKED, FINAL Round 1 FAIL and setup failures remain intact in their relays, SUMMARY and provenance; none is relabeled. These observations establish this bounded prompt seam, not browser safety or general model compliance.
- [Pass] Scope continuity and integration: plan “Requirements continuity and remaining gaps” retains all original eight requirements and six decisions' unimplemented predicates; “Rating and QA evidence” keeps `75/70/50/65, no override`. SUMMARY states “This PR must not close Forge #1092 or LTVera GH981” and “Full qualifying gate: pending”. Owner recommendations remain proposed. `upstream-nonoverlap.diff` adds the separate final-acceptance question at the template section; `mergeability.txt` records prospective tree `5ffc9904bd0f63f9d36912d6513aadaadf299f55`. Those are retained producer integration receipts, not a reviewer-executed merge or guarantee about a later upstream tip. Easy reversibility for this prompt/docs/package change remains reasonable; no containment implementation changed.
- [Unverified — needs clone run] Full route=full/tier=3 qualifying gate on the final approved commit remains deliberately pending per plan steps 6–7. Parent must perform it before publication; failure blocks publication. The independent focused run above does not substitute for it. LTVera browser replay/GH981 and broader #1092 requirements remain open. No other suite, pytest, executable fixture, new clone, source edit, delegation or shared Git mutation was performed by this reviewer.

Relay closed (Approved), no further turn needed. Parent proceeds to the required final-commit gate and separately planned additional review; neither is claimed complete here.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
