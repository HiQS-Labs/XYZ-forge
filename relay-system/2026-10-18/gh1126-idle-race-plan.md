# RELAY · GH-1126 plan QA: idle-kill label race between sampler and classify()
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1126-idle-race-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1126-IDLE-LABEL-PROBE-RACE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1126-IDLE-LABEL-PROBE-RACE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Plan QA request.** Read the canonical `PROJECT/2-WORKING/GH-1126-IDLE-LABEL-PROBE-RACE.md` (it is also seeded under `.relay-artifacts/`). Then read `utils/py/turn_diagnostics.py` (whole file), `utils/py/consult.py:270-330,780-810`, `test/gh610-claude-subscription.sh:119-149`, and issue #1126's acceptance criteria as summarized in the plan.

**Operational envelope:**
- Single-maintainer repo.
- #1126 constraints: do not weaken the classifier; do not delete, skip or quarantine the suite; no new test case without operator approval (GH-831).

**Questions (cite file:line):**
1. **Root cause.** Does the failing transcript (`samples=3, cpu=0.00s/s, worktree-progress=no`, network observation None) *require* that the sample-3 probe had not completed when `classify()` ran? Is there another path to that exact detail string, such as `_loop` swallowing an exception, or `cpu_ratio()` differing between the probe check and `classify()`? Separate confirmed from hypothesis.
2. **Lock design.** `_sample()` holds `_sample_lock` for its whole body, and `classify()` acquires it. Check three things:
   - Any deadlock: does `classify()` call anything that re-enters `_sample`?
   - Readers other than `classify()` that would need it: `idle_seconds()`, `cpu_ratio()`, `termination_record()`, or a direct `samples` read in consult or the shims.
   - Test seams that call `_sample()` directly from a test thread, e.g. `test/gh648-l1-turn-termination.sh:150-175`.
3. **Turn shims.** `stop()` joins with `timeout=2.0` (`:437-441`), but `lsof` can take up to 5 s. Can a shim's post-`stop()` `classify()` currently race a still-running probe too? Does the lock fix that as well?
4. **Verification.** Is the planned manual race control (a slow stubbed `_network_state`, `classify()` mid-sample; red on base, green on fix) sufficient and non-vacuous? Are the listed existing suites the right covering set?
5. Anything in the plan that is an unproven generalization or a missing requirement from #1126.

End with VERDICT and a `swept file: yes|no` line.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
