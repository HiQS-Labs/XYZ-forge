# RELAY · GH1092 final Codex QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
