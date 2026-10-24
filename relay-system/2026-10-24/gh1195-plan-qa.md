# RELAY · GH-1195 plan QA: marathon-plan root leak — one-line anchor fix
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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
6. **Commit only the relay file** (`relay(gh-1195-plan-qa-marathon-plan-root-leak-one-line-anchor-fix): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1195-PLANNER-ROOT-LEAK.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1195-PLANNER-ROOT-LEAK.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: the plan in the artifact is approved when a reviewer confirms, against the live
  source paths, that (1) the root-cause claim is grounded: `utils/py/marathon_plan.py:112-114` calls
  `repo_root()` with no anchor, and `utils/py/harness_paths.py:31-60` prefers `XYZ_HARNESS` before this
  file's location; (2) the one-line fix `repo_root(anchor_file=__file__)` yields the clone root in a
  canonical checkout and the consumer root in a vendored `.xyz` layout (trace `harness_home(anchor_file=…)`
  and `repo_root`'s vendored branch); (3) `QUEUE_PLAN_ROOT` still overrides; (4) the verification list
  (two manual checks with a red control, smoke main + adjacent path, the four named existing suites) can
  detect the actual failure and would go red if the fix were reverted; (5) the rating 72/70/50/92 is
  grounded in the stated consequence and recurrence; (6) nothing in the plan adds a test, suite, second
  resolver or parallel write path.
- Operational envelope: this is a one-line fix to a planner's default root in a single-operator harness.
  Grade against the stated requirements (issue #1195 acceptance, GH-831 no new tests, GH-1001 vendored
  precedence) and commensurate complexity; do not require multi-tenant threat models, new abstractions,
  or changes to `harness_home()` precedence. Evidence of the bug: `TESTS-RESULTS/2026-10-24+GH-1195/`
  in the same tree (red control: the engine ran with this clone's `releases.db` absent and wrote its
  plan file into the PRIMARY clone).
- Source paths to read: `utils/py/marathon_plan.py`, `utils/py/harness_paths.py`, `utils/marathon-plan.sh`
  (lines 20-32, 84-102), `utils/py/_marathon_plan.py:805-820`, `utils/py/wave_reconcile.py:1664-1750`,
  `test/marathon-plan.sh` (QUEUE_PLAN_ROOT pins), `test/gh358-wave-reconcile-vendored-paths.sh`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
