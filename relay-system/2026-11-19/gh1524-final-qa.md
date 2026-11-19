# RELAY · GH-1524 Final QA: 10days HAS-PR routing and remediate / serial-JIT / marathon modes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
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
6. **Manual relay: commit only the relay file** (`relay(gh-1524-final-qa-10days-has-pr-routing-and-remediate-serial-jit-marathon-modes): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/3-weekly/10days/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-19
- Definition of Done:
  - Inspect the committed implementation (`57ec48c3dbdd56b3c134473e9c14bfd620cad30e`) against the approved plan (`PROJECT/2-WORKING/GH-1524-10DAYS-REMEDIATE-ROUTING.md`, Plan QA receipt `relay-system/2026-11-19/gh1524-plan-qa.md`), all edited files (`skills/3-weekly/10days/SKILL.md`, `skills/2-daily/flywheel/SKILL.md`, `ARCHITECTURE.md`, `CHANGELOG.md`), and retained evidence (`TESTS-RESULTS/2026-11-19+GH-1524/smoke-walkthrough.md`, `red-control-and-assertions.log`, `releases-check.log`, `pdda-run.log`, `ci-route.log`, `provenance.jsonl`).
  - Grade against GH-1524 acceptance criteria and commensurate docs-only (`tier=1`, GH-831 no new tests) operational envelope:
    1. `10days/SKILL.md` Step 3 defines `HAS-PR` (`open_prs`, routing to `pr-minder`/`merge-cleanup`, kept out of Step 4–7 build paths).
    2. `10days/SKILL.md` Step 3.5 defines `remediate`, `serial` (`conveyor→jog` + `start-task` with the narrow single-harness exception over `start-task:235` and verbatim `Independent review did not run.` disclosure), and `marathon` (default) with zero new queues/runners/schemas.
    3. `10days/SKILL.md` (`Optional Flywheel coordination`) and `flywheel/SKILL.md` (`Daily observation and 10days batches` + Operating Flow Step 3) agree on ownership and mode-qualified routing with no contradiction.
    4. `10days/SKILL.md` Step 8 Report includes `Mode selected` and `HAS-PR Ledger`.
    5. `ARCHITECTURE.md` indexes `pr-minder` (`skills/2-daily/pr-minder/SKILL.md`).
    6. Evidence receipts (`ci-route` = `docs_only=true / tier=1`, `pdda.sh run` 0 errors, `releases check` 0 failures, 6/6 red controls, smoke walkthroughs, `provenance.jsonl`) and PRS rating (`75/60/50/85`, admitted `--accepted-start`) match the committed diff with no new test file or duplicate subsystem.
  - End your review block with `swept file: yes`, `VERDICT: PASS` (or `FAIL`/`PARKED`) and a non-empty `Basis:` line. Set `STATUS: Approved` when passing.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
