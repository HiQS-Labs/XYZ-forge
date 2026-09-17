# RELAY · GH613 archive stderr correction
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(gh613-archive-stderr-correction): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/claude-turn.py`, `test/claude-turn.sh`, `relay-automation/README.md`
- Reviewer: codex   ·   Producer: operator
- Started: 2026-09-13
- Definition of Done: Reuse approved full review relay-system/gh613-final.md and correction review gh613-correction.md. Review final bounded correction at 4358f276: claude-turn.py now puts stderr beside selected JSON path as .stderr, avoiding archive target-tree leakage. Inspect complete changed function and docs; test/archive-commit.sh and relay-target-root.sh are regression witnesses. Evidence archive-fixed.log (16 pass), ledger-fixed.log (10 pass), focused-sidecar.log (12 Python and 4 Bash). Ledger pair regenerated with official check --rebuild after 371/376 superseded gate (four ledger failures, one archive failure); corrected full gate running separately, do not claim passed. Review only, no execution or git operations in linked worktree; only append this relay. Cite findings, literal VERDICT: PASS/FAIL, Basis:, swept file: yes.

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
Basis: The bounded sidecar correction satisfies the stated review scope. Reused the approved full sweep in relay-system/gh613-final.md and correction review in relay-system/gh613-correction.md; read the complete current claude-turn.py and relevant documentation and regression witnesses. No additional blocking pre-existing defect identified in that scope. Source and recorded-evidence review only: no git commands or tests executed, and no passing corrected full gate claimed.
swept file: yes

- [Pass] The selected JSON path is computed once, then diagnostics use `claude_stderr = claude_log + ".stderr"` (`utils/py/claude-turn.py:93-95`). Both streams are opened by the parent before subprocess dispatch, so the child's isolated CWD does not relocate the sidecar (`utils/py/claude-turn.py:194-195`). This removes the independent default-log call that created target-tree directories despite a custom transcript path. Fix: none required.
- [Pass] Strict JSON validation, failed-turn cleanup and RTL enforcement remain connected (`utils/py/claude-turn.py:196`, `utils/py/claude-turn.py:212`, `utils/py/claude-turn.py:242`). The diagnostic path is printed before dispatch (`utils/py/claude-turn.py:191`). Public documentation accurately states `<CLAUDE_LOG>.stderr` and that the custom path controls both files (`relay-automation/README.md:103-106`). Fix: none required.
- [Pass] The archive witness supplies an external custom JSON path and explicitly rejects target `relay-system/` creation (`test/archive-commit.sh:68`, `test/archive-commit.sh:84`); recorded corrected output reports “archive-commit: 16 pass, 0 fail” (`TESTS-RESULTS/2026-09-14+GH-613/archive-fixed.log`). The vendored-root witness also supplies an external custom path (`test/relay-target-root.sh:162`). Its earlier “12 pass, 0 fail” record is prior correction evidence, not a newly executed sidecar run (`TESTS-RESULTS/2026-09-14+GH-613/targetroot-fixed.log`). Fix: none required for this bounded correction.
- [Pass] Recorded focused evidence reports “Ran 12 tests in 32.668s”, “OK”, and four successful handoff cases (`TESTS-RESULTS/2026-09-14+GH-613/focused-sidecar.log`). Ledger evidence reports “10 pass, 0 fail”, including a divergent-dump negative control (`TESTS-RESULTS/2026-09-14+GH-613/ledger-fixed.log`). The final provenance row explicitly labels the superseded gate “371/376; four ledger-derived failures and archive directory leak” and records the official rebuild and sidecar correction (`TESTS-RESULTS/2026-09-14+GH-613/provenance.jsonl`, event `gate-corrections`). Fix: none required; these records do not qualify the independent full gate.
- [Nit] The plan's older lesson “Diagnostic logs must use the resolved coordination root” is superseded by its final correction paragraph (`PROJECT/2-WORKING/GH-613-CLAUDE-REVIEW-FIXES.md`, Lessons Learned). At final bookkeeping, rewrite that lesson to say diagnostics follow the selected transcript path, and update CHANGELOG.md's full-gate evidence statement with the actual final result. The final paragraph already explicitly supersedes the earlier tick-root review, so this does not block implementation approval.

Coverage limitation: Verify-tier graph metadata for XYZ-forge refers to another checkout, generation 2026-09-01T15:54:30Z, and reports changed claude-turn.py metadata. Current source reads and the explicitly reusable prior full sweep supply the review evidence; no graph completeness or independent commit-identity claim is made.

relay closed (Approved), no further turn needed. Producer/operator owns corrected full-gate qualification and final publication bookkeeping.



### System · relay-drive — 2026-09-14T02:03:56Z
terminal STATUS Approved written by builder-role turn (codex) — reverted

## Producer — operator — follow-up
The previous reviewer PASS was not attested because the driver omitted --reviewer; this rerun supplies the correct role configuration. A full-gate compatibility case subsequently found custom in-tree stderr treated as an off-lane agent edit. The parent now creates its diagnostic sidecar before rtl.before(), retaining setup errors for normal failure/enforcement instead of leaking claims. Review the complete changed function and new test assertions requiring stderr content retained and no artifact commit. Existing isolated claude suite now passes 37 and archive 16. Reuse prior full reviews; no code/test execution in review worktree. Do not assert the full gate is green until separately completed. Append literal VERDICT, Basis, swept file.

## Reviewer — codex — Round 1 follow-up

VERDICT: PASS
Basis: The bounded in-tree sidecar correction is sound. Reused the approved full reviews in gh613-final.md and gh613-correction.md, read the complete current claude-turn.py and test/claude-turn.sh, and inspected the relevant public documentation and containment snapshot implementation. No additional blocking pre-existing defect identified within this scope. Source review only: no git commands, artifact execution, or tests run; the corrected full gate is not established as passing.
swept file: yes

- [Pass] Parent-side preparation uses `with open(claude_stderr, "a")` before `rtl.before()` (`utils/py/claude-turn.py:118`, `utils/py/claude-turn.py:122`). The shared snapshot records pre-turn porcelain entries and compares their exact status/path (`relay-automation/relay-turn-lib.sh:1044`, `relay-automation/relay-turn-lib.sh:1062`), so a newly created untracked diagnostic remains pre-existing when dispatch writes its contents. This reuses the existing containment mechanism. Fix: none required.
- [Pass] Preparation errors are saved as `stderr_setup_error`, converted to exit-5 state, and reported (`utils/py/claude-turn.py:120`, `utils/py/claude-turn.py:144`). Dispatch is guarded by `if bounded_rc == 0`; cleanup and `rtl.enforce(t, me, claude_log, "claude")` still follow. This avoids an early exception exit specifically for sidecar preparation. Fix: none required.
- [Pass] The regression supplies `CLAUDE_LOG="$A/claude.log"`, requires a successful turn, requires JSON cleanup, searches retained stderr for `fixture CLI diagnostic`, and fails if `git ... ls-files --error-unmatch claude.log.stderr` succeeds (`test/claude-turn.sh`, section 2b). These assertions cover both retained content and exclusion from the artifact commit. Fix: none required for the stated correction.
- [Pass] The path remains `claude_stderr = claude_log + ".stderr"` (`utils/py/claude-turn.py:95`), matching the documented `<CLAUDE_LOG>.stderr` contract (`relay-automation/README.md:104`). The archive witness supplies an external JSON path and rejects target-tree relay-system creation (`test/archive-commit.sh:68`, `test/archive-commit.sh:84`). Fix: none required.
- [Nit] The producer reports a new 37-pass Claude run, but the inspected committed provenance ends at the earlier `gate-corrections` row (`TESTS-RESULTS/2026-09-14+GH-613/provenance.jsonl:13`); that row records archive 16, ledger 10, and subscription 12 plus 4, not this latest compatibility run. Preserve the latest run and its provenance with final publication evidence, including a pre-fix red witness for the new sidecar assertions. This review approves the source correction, not an independently verified 37-pass run or full gate.

Coverage limitation: graph project XYZ-forge points to another checkout, generation 2026-09-01T15:54:30Z, and reports changed metadata for the Python and documentation paths. Current source reads and the expressly reusable prior full reviews supply the evidence; no graph completeness claim is made.

relay closed (Approved), no further turn needed. Producer/operator owns the corrected full gate and final evidence bookkeeping.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
