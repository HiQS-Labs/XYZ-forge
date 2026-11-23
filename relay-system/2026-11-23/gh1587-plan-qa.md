# RELAY · GH-1587 Plan QA: Close 6 High-Severity Review Blind Spots
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1587-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: The surgical plan in `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` faithfully covers all 6 recurring High-severity review blind spots and the GH-681/GH-564 Catch-22 from HiQS-Labs/XYZ-forge#1587, pins accurate source seams at `14cb8a60d`, obeys GH-831 (no new tests), GH-308 (frozen Bash twins), GH-836 (live self-sufficiency + scaffold review), and single-source-of-truth skill boundaries (`review-code-xyz` vs `review-pr-xyz`), and specifies falsifiable rejection criteria and rollback without over-engineering.
- Operational Envelope: Local XYZ-forge skill docs, relay turn prompts, marathon reviewer brief, packaged tarball (`relay-pkg.tar.gz`), and in-place pin test (`test/gh681-reviewer-probe-rules.sh`). Grade against stated requirements, commensurate complexity, and XYZ-forge rails (`AGENTS.md`, GH-681, GH-831, GH-308, GH-564).
- Paraphrase-First Step (GH-1414): Before reading repo source files, read ONLY `.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md` and write 2–5 sentences each under `**What this proposes**`, `**How the existing system works, per this document**`, and `**What it's not**` (marking input boundary = plan artifact only). Then read the target repo files below and label the remaining findings as `**Source-backed technical validation**`.
- Source paths to validate after paraphrase: `skills/2-daily/review-code-xyz/SKILL.md`, `skills/2-daily/review-pr-xyz/SKILL.md`, `relay-automation/relay-turn-lib.sh`, `relay-automation/new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `relay-automation/README.md`, `test/gh681-reviewer-probe-rules.sh`, `utils/py/review_xyz.py`.
- Plan QA Questions:
  1. Are all target file paths, line references, and confirmed non-edits (`utils/py/rtl.py`, `relay-automation/marathon-drive.sh`, `utils/py/review_xyz.py`) grounded in the repo at `14cb8a60d`?
  2. Is any requirement from GH-1587 (6 blind spots + 2-form `Observed input:` / `Clone probe:` + `make-pkg.sh` + GH-836 live check) missing, contradictory, or unsynchronized across the 10 target files?
  3. What prevents an unchanged, unfixed candidate from being reported as delivered — and where is the observed rejection? Do the acceptance checks distinguish admission/pin checks from actual defect detection?
  4. Does the plan keep `review-code-xyz` as single source of truth (no duplication into `review-pr-xyz`), keep canonical `[Blocker]`/`[Should]` tags intact, obey GH-831 (no new test files), and obey GH-308 (no frozen twin edits)?
  5. Are the persisted roadmap rating (`85/80/50/70`, appeal neutral=50), rollback boundary, and Phase 1/2 QA gates sufficient and commensurate?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
