# RELAY · GH-911 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
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
6. **Commit only the relay file** (`relay(gh911-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation on this branch versus `origin/development`:
  - `skills/2-daily/workhorse/SKILL.md` (whole file)
  - `skills/2-daily/workhorse/stop-hook.sh` (new)
  - the `CHANGELOG.md` top entry
  - evidence in `TESTS-RESULTS/2026-10-01+GH-911/` (`SUMMARY.md`, `provenance.jsonl`, `matrix.txt`)

  The approved plan is `PROJECT/2-WORKING/GH-911-WORKHORSE-DIRECT-REENTRY.md` (plan QA:
  `relay-system/2026-10-01/gh911-plan-qa.md`, r2 PASS). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/911
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- **Operational envelope:** a skill text edit plus one ~50-line local Claude Code Stop hook for a single operator.
  Grade against the approved plan and commensurate complexity. Explicit non-goals: no governor role, progress
  fingerprints, budget counters, run schema, or new tests (GH-831). A new `test/` suite or `validate.sh`
  entry in the diff would itself be a finding.
- **Definition of Done (final QA):**
  - every plan step (1–8) is implemented as approved, with no duplicate subsystem or writer;
  - the hook's behavior matches the plan;
  - the evidence substantiates the claims, including the red control;
  - the skill text is internally consistent.

**Questions:**
1. Is each plan step 1–8 implemented as written? Cite `file:line` for anything missing or divergent.
2. `stop-hook.sh`: is input handling correct (the hook's stdin is captured before the python heredoc)? Is
   fail-open total? Does the block JSON match the documented Stop contract? Can a session be trapped?
3. Frontmatter: is the `hooks:` block valid YAML in the settings format, and does the folded `command`
   resolve correctly? Does the YAML comment inside it parse cleanly?
4. Is SKILL.md now internally consistent (recital, ladder diagram, Rung 0, Rung 4, Rung 5, Rung 6 §4–5,
   Proportional Rigor, Operating Rules)? Is the #626 orchestrator `--resume` clause unchanged in substance?
   Is the emergency-rollback restriction intact?
5. Does `TESTS-RESULTS/2026-10-01+GH-911/` substantiate the claims (red control observed, sha matches, 15/15,
   gh609 33/0)? Is its "not covered" disclosure honest?
6. Anything over-engineered, or any accidental files in the diff (`git diff origin/development --stat`)?
   Note that `LEADERBOARD.md`/`releases.*` changes come from the canonical `releases_app.py` writer.

Cite `file:line` for every disagreement. Set STATUS: Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
