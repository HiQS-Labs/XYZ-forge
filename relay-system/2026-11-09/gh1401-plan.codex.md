# RELAY · GH-1401 conveyor plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh-1401-conveyor-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1401-CONVEYOR.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1401-CONVEYOR.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: author
- Started: 2026-11-09
- Definition of Done: Review the canonical plan acceptance and requirements, not implementation. Read PROJECT/1-INBOX/GH-1401-CONVEYOR.md and recon-conveyor.md plus referenced source. Operational envelope: skill-only local developer workflow; no runtime changes, new tests/gates or enterprise machinery. Check (1) complete #1401 scope including invocation modes, (2) existing writer/schema reuse, (3) actual Jog handoff and label publication semantics, (4) bug probe polarity and falsifiable manual checks, (5) rating provenance and rollback. Cite concrete file:line for findings. This is plan QA before implementation.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The bounded skill-only design fits the request; add one explicit bug-polarity verification before implementation. This is plan QA, not an implementation failure or execution attestation.
swept file: yes

- [Should] S1 — Make the promised bug-polarity check falsifiable in the verification sequence. `.relay-artifacts/GH-1401-CONVEYOR.md:46` specifies only a valid missing-artifact contract and malformed/empty contracts, while lines 34 and 52 require concrete bug-polarity probes. Those checks cannot distinguish an inverted bug probe from a correct one: both parse and lint. `utils/py/swarm_preflight.py:211-234` demonstrates why: `grep_present` means the bug pattern still exists, and command success means unfixed unless `expect_nonzero` reverses it. Cheapest fix: extend step 3 with a manual paired existing-file bug example in the already-planned disposable clone: bug-present input must yield unfixed, controlled fixed input must yield landed, and deliberately inverted polarity must expose the mismatch. Record commands, exit status, verdicts and provenance; no new suite or gate.
  Observed input: The complete verification step at artifact line 46 is “a valid missing-artifact contract at the pinned base and a malformed/empty contract using existing parser/linter”; it contains no bug-present/fixed pair or expected verdicts.
  Affected scope: Verification of synthesized existing-file bug contracts, not every backlog item and not new runtime behavior.
  Falsifier: An explicit existing planned manual check that runs the same bug probe against bug-present and fixed contents, expecting unfixed and landed respectively, with an inverted-polarity red control. If that check is named in the sequence, this finding is satisfied.
- [Pass] Writer and consumer reuse are appropriately bounded: artifact lines 30 and 36 keep PRS canonical and forbid `--accepted-start`; lines 54 and 59 defer admission and require integration-ref availability before readiness. This matches Jog's separate promotion/shape-check/preflight stages (`skills/2-daily/jog/SKILL.md:90-104`, `utils/py/jog_run.py:1577-1627`).
- [Pass] Invocation coverage and scope match the issue at plan level: artifact lines 34 and 55 cover issue IDs/PRS selection, scheduled batches, and intake/refine events without installing dispatch machinery; lines 40 and 53 state rating provenance/preservation, and line 59 supplies rollback. Source request read through GitHub `fetch_issue` for HiQS-Labs/XYZ-forge #1401 (Invocation Modes and Initial PRS Proposal). No additional pre-existing defects found in the swept 67-line artifact.
- [Unverified — needs clone run] No parser/linter execution, preflight or gates were run in this review worktree; those are future implementation evidence per artifact lines 46-47. Source inspection supports the design but does not establish runtime readiness.

Handing off to Producer — address S1 in the canonical plan, log its disposition, and request the next review turn.

### Producer · Round 2

Disposition: S1 Implemented. The existing manual-check step now names paired bug-present/fixed grep_present evaluation and deliberately inverted grep_absent red control, with explicit unfixed/landed expected values. No new suite or gate. Review the updated canonical plan and previous S1 only for resolution while retaining whole-artifact review.

Handing off to Reviewer for plan approval.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
