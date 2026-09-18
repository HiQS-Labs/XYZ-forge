# RELAY · GH-694 final QA — express telemetry schema and Tick fold resilience
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh694-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-18
- Definition of Done: the implementation is sound if (1) utils/py/express.py write_tick() emits the canonical Tick 0.2.0 event envelope (schema_version, ts, type, task, agent) while preserving backward-compatible payload fields; (2) src/project.js foldWithMeta() defensively skips non-task.* and malformed events without string task ids, with the institutional rationale comment intact; (3) test/gh267-express-skill.sh pins tick project clean exit 0 across refusals, happy path landings, and resumes; (4) CHANGELOG.md and capture doc accurately describe the change; (5) npm test and test/gh267-express-skill.sh are green. Grade each; PASS only when no [Blocker] remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: Reviewer (agy)
swept file: yes
VERDICT: FAIL

- [Pass] (1) `utils/py/express.py` `write_tick()` correctly emits the canonical Tick 0.2.0 event envelope (`schema_version="0.2.0"`, `ts=now_iso()`, `type=ev_type`, `task=task_id`, `agent="express"`) while preserving backward-compatible payload fields via `rec.update({k: v for k, v in fields.items() if v is not None})` (`utils/py/express.py:104-114`). Tested with a local probe showing the correctly emitted JSON schema.
- [Pass] (2) `src/project.js` `foldWithMeta()` defensively skips non-task.* and malformed events without string task ids: `if (!ev || typeof ev.task !== 'string' || !ev.task) continue;` (`src/project.js:59`), and the institutional rationale comment is intact above it.
- [Pass] (3) `test/gh267-express-skill.sh` pins `tick project` clean exit 0 across refusals, happy path landings, and resumes. Assertions like `TICK_REPO_ROOT="$FX" "$HERE/../bin/tick" project >/dev/null 2>&1 && ok "tick project folded cleanly...` were found at lines 228, 360, and 594.
- [Blocker] (4) The capture doc accurately describes the change.
  Observed input: The capture doc is still located at `PROJECT/1-INBOX/GH-694-EXPRESS-TICK-TELEMETRY-SCHEMA.md`. Its "Status" section reads `What's next | Grounded recon, implementation plan & Codex relay QA`, failing to describe the completed change.
  Affected scope: Capture doc lifecycle and accuracy.
  Falsifier: Move the capture doc to `PROJECT/2-WORKING/` and update its "Status" and "Acceptance Criteria" to accurately reflect the completed implementation.
- [Pass] (4) `CHANGELOG.md` accurately describes the change under the `2026-09-18` section.
- [Unverified — needs clone run] (5) `npm test` and `test/gh267-express-skill.sh` are green. (Cannot run full test suite or fixtures in the relay).
- [Pass] Pre-existing defects: None found in the reviewed scope of `utils/py/express.py` and `src/project.js`.

Basis: The implementation is correct, but the capture doc was neither moved to `PROJECT/2-WORKING/` nor updated to accurately describe the completed change.

Handing off to Producer — go to the claude-a window and say 'take your turn'.

### Turn 2: Producer (claude-a)

- [Implemented] (4) The capture doc was moved from `PROJECT/1-INBOX/GH-694-EXPRESS-TICK-TELEMETRY-SCHEMA.md` to `PROJECT/2-WORKING/GH-694-EXPRESS-TICK-TELEMETRY-SCHEMA.md` via `git mv`. Its "Status" and "Acceptance Criteria" sections were updated to accurately reflect the completed dual-sided implementation and verification checks.
- Verification evidence: `npm test` passed 23/23 tests cleanly; `bash test/gh267-express-skill.sh` passed 98/98 assertions cleanly including all `tick project` coexistence assertions.

Handing off to Reviewer — go to the agy window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

