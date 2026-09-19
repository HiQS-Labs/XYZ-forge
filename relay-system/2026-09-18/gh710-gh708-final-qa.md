# RELAY · GH-710/GH-708 final QA — reviewer agy
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
-->

NEXT: Producer
STATUS: Approved
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh710-gh708-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh710-gh708-final-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-09-18/gh710-gh708-final-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude
- Started: 2026-09-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


## TURN 1 — Reviewer (agy)

swept file: yes

*   `[Pass]` Q1 (GH-710 key order/resolution): The record build matches the approved key order (`utils/py/_marathon_plan.py:863-865`, using `doc_rel` first then other `.md` links). A true duplicate resolves to gids only, returning `("one of ...", None, None)` where `db_rank` is explicitly `None` (`utils/py/_marathon_plan.py:798-800`), thus never resolving to a rating.
*   `[Pass]` Q2 (GH-710 precedence): The "DB rating wins over legacy frontmatter" precedence is unchanged. If a `NULL-gh` row has legacy frontmatter but no DB rating, `hit` is not found, `db_rank` remains `None` (`utils/py/_marathon_plan.py:858`), bypassing the precedence branch (`:873`), leaving `rated = True` (`:872`) and scoring via legacy frontmatter in `score_of` (`:1095`).
*   `[Pass]` Q3 (GH-710 test): Pre-existing assertions are real and `GH-102` correctly reaches the unrated branch (`test/gh698-planner-db-ratings.sh:124`, `INFO [unrated]  GH-102`). The suite correctly reads lanes/ranks from the written plan doc (`plan_doc="$(cat "$FX"/PROJECT/2-WORKING/MARATHON-PLAN-*.md ...)"` at `:109`). The crash assertion explicitly expects 4 or 5 (`case "$planner_rc" in 4|5)` at `:141`), so a crash (like the pre-fix rc 1) hits the `*)` fallback (`:143`) and cannot pass.
*   `[Pass]` Q4 (GH-708 helper): The marker check `sed -n 's/^source_commit=//p'` (`test/lib/fixture-guard.sh:96`) ensures a safe exit 2 on a non-vendored tree. `BASH_SOURCE[1]` correctly points to the caller suite (`test/lib/fixture-guard.sh:89`) regardless of whether it is called at the top level or after `_setup.sh`, because sourcing `_setup.sh` does not shift the caller frame for subsequent calls in the suite.
*   `[Pass]` Q5 (GH-708 spot-checks): Spot-checked `test/gh267-express-skill.sh:41`, `test/gh544-pre-push-gate.sh:62`, `test/ci-workflow.sh:13`, `test/gh35-test-tiers.sh:43`, and `test/gh365-tier-fail-closed.sh:14`. All calls are correctly placed at the top level or right after `_setup.sh`, before first use. No double-sourcing of `fixture-guard.sh` was found in `_setup.sh` callers. The paths named are indeed read by the suites.
*   `[Pass]` Q6 (GH-708 acceptance): The 62 skips and 11 tracked leftovers completely answer the issue questions. The vendor decision to skip rather than vendor `githooks/` is correct, as vendoring `pre-push` without `validate.sh` would break the consumer pushes.
*   `[Pass]` Q7 (Ratings): Both sets of ratings are still grounded. GH-710 90/90/50/85 correctly reflects the crash blocking `LTVera#551` reconciles; GH-708 65/55/50/80 correctly sizes the false-red noise blocking acceptance.

VERDICT: PASS
STATUS: Approved
Basis: All acceptance criteria from the plan are met, both the test suite additions and code modifications implement the required fixes and safety guards accurately. Pre-existing code swept and no issues were found.  [Unverified — no citation]

handing off to Producer — relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
