# RELAY · GH-773 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-23.
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
6. **Commit only the relay file** (`relay(gh-773-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/marathon_drive.py` and `test/gh390-gate-guard.sh` (the GH-773 change), graded against the approved plan `PROJECT/2-WORKING/GH-773-MARATHON-DRIVE-GATE-MEMORY.md`.
- Scope of the change: the diff from commit 7bc89410 to HEAD on this branch, limited to the two files above. Read the full `_gate_group_rss_mb`, `_gate_rss_summary`, and the guarded loop in `run_pre_advance_gate`, and section (8) of the test file.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-23
- Definition of Done: every plan step and acceptance line is implemented in the actual code paths; no duplicate subsystem or writer; tests substantiate the claims.
- Test evidence (run by the producer in a disposable full clone at bee21ee5; the diff after that is CHANGELOG/status only):
  - `bash test/gh390-gate-guard.sh` → `23 pass, 0 fail` (17 existing + 6 new GH-773 checks).
  - Mutation: pre-fix `utils/py/marathon_drive.py` (from 9a887cda) with `TEST_SOFT_FAIL=1` → `19 pass, 4 fail`; failing: GH-773 seam, warning-once (saw 0), unknown summary, numeric-peak absence. The fail-open check and the working-`ps` control pass on both, as intended.
  - `test/gh291-contract-goldens.sh` 20/0, `test/gh457-gate-tiers.sh` 10/0, `test/gh382-marathon-memory-telemetry.sh` pass.
  - Full gate not yet run; it runs once on the approved commit. Known baseline reds on untouched development: gh549-work-events, gh605-work-state (#764).
- Operational envelope: local developer CLI; one helper, one loop, one existing test file. Do not request fail-closed modes, fallback probes, receipt schema fields, or new test frameworks (explicit non-goals).
- Questions:
  1. Does the loop match the plan exactly: `group-missing` re-polls and leaves without counting when the gate exited; `ps-failed` always counts; unreadable skips only the RSS cap; warning logged once; readable samples still enforce the cap?
  2. Is the `rc` value set on the `group-missing` break handled identically to the normal top-of-loop break (CPU attribution, baseline allowance, summary)?
  3. Are all four summary forms correct, and is `peak group RSS` still present for `test/gh390-gate-guard.sh:173`?
  4. Is `(0, None)` for a matched group under 1 MB distinct from any unknown path?
  5. Do the new tests prove the acceptance lines, including the red control? Any assertion that could pass vacuously?
  6. Any regression to the unguarded path, wall/CPU caps, or the result receipt?
- Write findings only in this file (ALLOW_PATHS is empty). Set `STATUS: Approved` if ready to open the PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
