# RELAY · GH-813 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
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
6. **Commit only the relay file** (`relay(gh-813-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/harness_app.py`, together with `test/gh496-telemetry-isolation.sh`, as committed on branch fix/gh813-sqlite-wal-init-race. The full diff is `git diff 0ae3452a..HEAD -- utils/py/harness_app.py test/gh496-telemetry-isolation.sh CHANGELOG.md PROJECT/2-WORKING/GH-813-SQLITE-WAL-INIT-RACE.md TESTS-RESULTS/2026-09-25+GH-813/`
- Approved plan: `PROJECT/2-WORKING/GH-813-SQLITE-WAL-INIT-RACE.md` (plan QA thread `relay-system/2026-09-25/gh-813-plan-qa.md`, Approved round 3)
- Source to read in full, not just the diff: `utils/py/harness_app.py` (`init_db`) and `test/gh496-telemetry-isolation.sh`
- Evidence: `TESTS-RESULTS/2026-09-25+GH-813/` (`base-200.txt`, `red-control-base.txt`, `suite-fixed.txt`, `fixed-200.txt`, `provenance.jsonl` with 4 rows)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: R1–R4 in the plan are met by the code and the retained evidence; the implementation matches the approved plan with no scope creep; no duplicate subsystem or write path; ratings and ledger state are truthful.

**Operational envelope:** a local developer CLI and one gate suite. The fix is about 12 lines; judge it at that scale. Do not ask for helper modules, soak tests in the gate, or multi-tenant hardening. Reviewer is read-only: narrow `$TMPDIR` probes are fine; do not run `validate.sh` or `test/*.sh` here. Grade anything that needs a clone run `[Unverified — needs clone run]`.

**Questions:**
1. Does the retry in `init_db` match plan step 1 exactly? Check: only the WAL pragma is retried, only on `database is locked` (case-insensitive), at most 50 attempts, a re-raise on the last attempt and on any other error, and nothing swallowed. Cite `file:line`.
2. Case 14 (`test/gh496-telemetry-isolation.sh`): does the factory patch really reach `init_db`'s connect? Are the assertions `a|ok|4`, `b|disk I/O error|1` and `c|database is locked|50` exact (`grep -qxF`)? Does `signal.alarm(30)` bound an unbounded mutant? Could the case pass vacuously, for example on empty output or a Python crash with rc 0?
3. Case 9: is the new stderr capture safe under `set -euo pipefail` (the `concur_why` loop), and does it still keep ten workers on a fresh DB with no pre-initialization?
4. Evidence: do the receipts and provenance rows agree with each other and with the plan's Results section? Is the red-on-base claim (case 14 fails with `a|database is locked|1` and `c|database is locked|1`) supported by `red-control-base.txt`? Are local paths redacted?
5. Is anything outside the plan in the diff (beyond ledger/leaderboard regeneration from `releases_app.py` verbs)? Any pre-existing defect in the swept files that this change sits on?
6. Are the CHANGELOG entry and the plan's Results section accurate, and is the rating `60/45/50/90` still consistent with the evidence?

Output graded findings with `file:line` citations, a VERDICT and a Basis. Set `STATUS: Approved` only if no Blocker or Should remains.
## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
