# RELAY · GH-693 implementation QA — Lessons Learned advisory (landed 989f5549)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh693-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh693-impl-review-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-09-18/gh693-impl-review-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude
- Started: 2026-09-18
- Definition of Done: the six numbered questions in the packet are each answered with a graded finding and a file:line citation; a `[Blocker]` exists only for an observed non-zero exit / die / SKIPPED / skipped lifecycle write still caused by a missing or placeholder Lessons Learned section, or for a flipped test that is weaker than what it replaced without a compensating pin; PASS when no `[Blocker]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: agy (Reviewer)

- **Q1:** `[Pass]` There is no remaining path where a missing/placeholder Lessons Learned causes a `die`, `SKIPPED` line, or skipped lifecycle write. The three call sites are: `utils/py/wave_reconcile.py:1041` (in `validate_and_update_doc`), `utils/py/wave_reconcile.py:1809` (in `run_pre_merge`), and the catch-up block which now cleanly loops without skipping (`~L2054` removes the old skip machinery). All sites now defer to `warn_lessons_learned()`.
- **Q2:** `[Nit]` Keeping the GH-684 skip-and-report shape is the right call under the /ponytail principle and the operational envelope. Removing `SKIP_MARKER` reporting would break `test/gh684-hosted-lane-report.sh` which explicitly checks for it, and require touching `utils/py/hosted_lane_report.py` which was stated as a Non-goal.
- **Q3:** `[Pass]` The consequence is correct. A lessons-less backlog doc is now reconciled completely (moves to `3-COMPLETED`, `ROADMAP.md` updated). This eliminates its planner drift on subsequent runs. If planner drift is still found for a successfully reconciled issue, it's a genuine failure of the ledger update (attributable and fatal, exit 6), which does not recreate the #691 shape (where skipped docs stayed in `2-WORKING` and red the lane every run).
- **Q4:** `[Pass]` `test/gh693-lessons-learned-advisory.sh` DOES fail on the parent commit. It fails at Case A's first assertion (`[ "$rc" = 0 ]`), immediately exiting the suite, which successfully proves the parent commit is red. The flipped Test 4 in `wave-reconcile.sh` is not weaker because the new suite performs the real promotion test (`test/gh693-lessons-learned-advisory.sh`). Case C (`--pre-merge`) is a real pin because it commits a new `HEAD` after generating the test receipt; if the doc-contract (exit 5) did not pass, it would exit 5 before reaching the receipt check. By asserting `[ "$rc" != 5 ]`, it correctly proves the doc-contract no longer fails.
- **Q5:** `[Nit]` `utils/py/wave_reconcile.py:1024` has a stale docstring `"""Assert ## Lessons Learned..."""` that should be updated to reflect it only warns now.
  `[Pass]` The wording in `PDDA.md`, `HOW-TO-USE.md`, `express SKILL.md`, and `pr-emit.sh` consistently labels the section "highly recommended". No other non-test document states it is required.
- **Q6:** `[Pass]` Commensurate complexity. The change is extremely minimal. It replaces `die()` with `log()`, removes the `catch_up` skipping logic cleanly, and correctly updates the tests. No speculative abstraction was added.

swept file: yes
VERDICT: PASS
Basis: The implementation cleanly downgrades the Lessons Learned section to an advisory warning across all paths without breaking downstream contracts. All questions addressed; only minor nits found (docstring update).

handing off to done — relay closed (Approved), no further turn needed

### Turn 2: claude (Producer) — dispositions, relay closed

- Q2 `[Nit]` keep the GH-684 skip-and-report shape — **Accepted** (matches the capture doc's Lessons Learned bullet 3; removal parked as a follow-up for the next real backlog-doc defect class, see GH-693 doc).
- Q5 `[Nit]` stale docstring on `validate_and_update_doc` — **Implemented**: `utils/py/wave_reconcile.py` docstring now reads "Warn on a missing/placeholder ## Lessons Learned (GH-693), update frontmatter, and compute destination path." (this commit).
- Header: the reviewer wrote `NEXT: done`; the driver refused the close as a close-mismatch because the tick token could not be marked done by agy. Restored to the harness attestation convention (`NEXT: Producer` + `STATUS: Approved`); the verdict above stands unchanged.
- Discovered while driving this turn: `/express` telemetry in `.tick/events/` breaks `tick`'s fold in the same clone — filed as #694; the two express events were moved out of this clone's `.tick/events/` (mirrored centrally) to run the review.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
