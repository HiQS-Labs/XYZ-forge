# RELAY · GH-813 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Producer
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

### Reviewer · Round 1

VERDICT: FAIL
Basis: The local retry is a reasonable design, but the plan needs a concrete injection seam and auditable evidence before its proof claims meet the Definition of Done. These are plan corrections, not a request for a broader runtime subsystem.
swept file: yes

Reviewed the entire plan and all of `harness_app.py`, `harness_turn_logger.py`, and `gh496-telemetry-isolation.sh`. No additional established pre-existing runtime defect was found in this sweep; this is not proof that every concurrency interleaving succeeds.

- [Should] **Specify how case 14 reaches the connection created inside `init_db`.** Plan `PROJECT/2-WORKING/GH-813-SQLITE-WAL-INIT-RACE.md:59` names a factory but does not say how it replaces the internal `sqlite3.connect(db_path)` at `utils/py/harness_app.py:168`. Creating a subclass connection separately does not affect that call. Cheapest fix: explicitly patch `harness_app.sqlite3.connect` within the inline test, saving the real connect before patching and forwarding it with `factory=Subclass`; assert the injected WAL-attempt count (4 for a, 1 for b, 50 for c), and put an outer timeout on c so an unbounded mutant fails rather than hangs. No production injection API is needed.
  Observed input: `init_db(db_path)` has no connection/factory argument and internally calls `sqlite3.connect(db_path)` with no keywords.
  Affected scope: the proposed case 14 only.
  Falsifier: in the disposable clone, demonstrate that the patch intercepts the real WAL call and case 14a fails on base after one injected lock, then succeeds after four WAL attempts with the fix; an unpatched base run must not accidentally satisfy the test.
  Probe: `python3` AST inspection of `init_db` printed `utils/py/harness_app.py:168: sqlite3.connect(db_path); factory keywords=[]` (Python exit 0). This is static seam evidence, not an executed red control.

- [Should] **Retain/cite the measurements and qualify the recurrence claim.** Plan lines 30–31 give exact 200-round results without a command, receipt path, or provenance; line 36 adds an unexplained 3% denominator; line 40 asserts a complete 3-versus-3 historical count without dated query results. `rg -n -F -e '30/200' -e '33 errors' -e 'GH-813' TESTS-RESULTS` exited 1 with no output. That does not establish that the producer never ran them; it establishes that this review cannot audit them from the named evidence store. Link retained commands/results/provenance (and name where implementation/red-control receipts will be committed), or label unavailable numbers provisional. Record issue creation timestamps and the date-window/query predicate for recurrence, or describe these as examples rather than an exhaustive flat trend. Local GH-558's capture says `created: 2026-09-21` (`PROJECT/3-COMPLETED/GH-558-GH32-SECTION-J-FLAKE.md:6`), so it cannot by itself substantiate placement in the earlier window; capture date need not equal issue date. Appeal 50 is explicitly neutral at plan line 38, and the recoverable-impact/cheap-fix rationale supports the qualitative rating, but not the uncited rates.

- [Should] **Correct the stated latency bound without widening the fix.** Plan lines 57 and 72 call about 2.5 seconds the worst case. Fifty attempts allow 49 sleeps, at most 2.45 seconds of deliberate sleep; that does not include time inside SQLite. A read-only configuration probe, `python3 -c 'import sqlite3; c=sqlite3.connect(":memory:"); print(c.execute("PRAGMA busy_timeout").fetchone()[0])'`, reports `5000` ms (same probe executed in the combined Python inspection, exit 0). `harness_app.py:168` keeps that default. State that 2.45 seconds is the added sleep budget for immediate-BUSY failures, not a universal wall-clock cap; 50 attempts remains the bounded policy. The reported 0.06–0.07-second sample supports bypass of the full timeout in those failures, not every possible lock condition. No timeout/helper redesign is requested.

- [Pass] **Recon and scope match source.** The sole `sqlite3.connect` in `harness_app.py` is at line 168; WAL is line 171; migration tolerance is lines 276–283; all CLI paths converge through `init_db` at lines 460, 539, 547, 553, 562, 602, and 622. The logger surfaces nonzero subprocess results without failing the turn at `harness_turn_logger.py:132–145`. No observed later CREATE/ALTER/seed/INSERT failure supports extending retries beyond the pragma. Plan lines 51–53 appropriately avoid a helper subsystem, preinitialization, soak tests in the gate, and a new mandatory WAL-mode assertion. Jitter is a small defensible contention choice, but its superiority to fixed sleep is not measured here.

- [Nit] **Correct two verification labels.** Plan line 57 expects 14/14 after adding case 14, but the existing suite already has 14 `pass` sites (case 10 reports twice, `test/gh496-telemetry-isolation.sh:234` and `:250`). Say zero failures/all expected cases, or use the implemented count. Plan line 66 calls `validate.sh` qualifying; `ROUTER.md:110–111` distinguishes that self-check from `ci-local.sh`'s qualifying evidence record. Use the intended gate's accurate label.

- [Unverified — needs clone run] The real race, prototype 0/200, base red control, eventual cases 14a–c, stderr mutation, and final gate were not executed in this reviewer worktree. Require their receipts during implementation; no runtime success is claimed by this plan review.

Handing off to Producer (claude-a) — address the findings and open round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
