# RELAY · GH-813 plan QA
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
6. **Commit only the relay file** (`relay(gh-813-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-813-SQLITE-WAL-INIT-RACE.md` (the PLAN; no code has been written yet)
- Source paths the plan cites (read them, do not trust the summary): `utils/py/harness_app.py` (`init_db` :165-288, callers :440-470 and :530-622), `utils/py/harness_turn_logger.py:90-147`, `test/gh496-telemetry-isolation.sh` (case #9 at :175-208)
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/813 (live issue text is transcribed in the plan's Requirements; the reviewer sandbox may not reach GitHub)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: the plan fixes the observed race at its cause, extends the existing `init_db` writer rather than adding a subsystem, keeps every other error visible, has falsifiable checks including a red control that fails on base `0ae3452a`, and its rating/recurrence claims are grounded.

**Operational envelope:** a local developer CLI (`harness_app.py`) that writes one telemetry row per agent turn into a per-project SQLite file, plus one gate test. Machinery and tests must be commensurate with a ~10-line fix. Do not demand shared DB helper modules, distributed locking, soak tests in the gate, or multi-tenant hardening. Reviewer is read-only: narrow probes in `$TMPDIR` are fine, but do not run `validate.sh` or `test/*.sh` here.

**Questions:**
1. Grounding: do the recon claims match the code? Is `init_db` the sole connect path, is the WAL pragma at `harness_app.py:171`, and is the GH-450 `ALTER` tolerance at :276-283? Cite `file:line`.
2. Root cause: the plan says every failure was at the WAL pragma and came back in 0.06–0.07 s, so the default 5 s busy handler was never used and only a retry fixes it. Is retrying only that statement sufficient, or is there a concrete statement later in `init_db` (CREATE, ALTER, seed, the log INSERT) that the same concurrency can break? A finding must name the statement and the failing input.
3. Retry design: at most 50 attempts, retry only on `database is locked`, 20–50 ms jittered sleep, re-raise on the last attempt or any other error. Is this bounded and correct? Does it swallow anything it should not? Is `random`/`time` jitter justified, or would a fixed sleep do?
4. Red control (Phase 1 step 3): will a `sqlite3.Connection` subclass passed via `sqlite3.connect(factory=...)` really intercept `conn.execute("PRAGMA journal_mode = WAL;")` inside `init_db`? Will cases (a) three locks then success, (b) a non-lock error propagating after one attempt, and (c) persistent locks raising once the budget runs out actually fail on base code where they should? Specifically, (a) must be red on base.
5. Scope: is anything required by #813 missing, and is anything in the plan unnecessary? Is declining the "read back `wal`" check justified?
6. Rating `60/45/50/90` and the recurrence counts: are they grounded in the plan's evidence, with appeal neutral?

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
