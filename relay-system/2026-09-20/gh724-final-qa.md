# RELAY · GH-724 marathon-triage rewrite final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-20.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh724-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/marathon-triage/SKILL.md` @ `a9a41baa` (the rewritten skill, 340 lines). Read with: `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md` (approved plan + QA checklist), `CHANGELOG.md` (top entry), `relay-system/2026-09-20/gh724-plan-qa.md` (plan QA R1/R2), `skills/merge-cleanup/SKILL.md` (shape reference), `relay-automation/hooks/relay-xyz-guard.sh`, `utils/py/marathon_plan.py`, `utils/py/swarm_preflight.py`, `utils/py/_marathon_plan.py` (deep delegation at 1022-1049), `utils/hq/hq-lib.sh` (`hq_render_capture`, `hq_roadmap_line`, `hq_slug`), `PROJECT/PDDA.md` → GitHub issue intake.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-20
- Definition of Done: the Phase 1 QA checklist in the plan doc — every item satisfied by the rewritten skill text; the four-scenario walkthrough reaches the right terminal shape (complete or blocked report) without asking the operator; the recipes are executable as written against the cited CLIs; no new writer, tool, or runtime change; #443 scope untouched.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — final QA packet

VERDICT: PARKED
Basis: implementation committed at `a9a41baa`; requesting independent final QA against the approved plan.

**Operational envelope.** Doc-only rewrite of one skill file instructing a coding agent; local single-repo developer tooling. No runtime code, no tests, no new writer. Grade against the plan's QA checklist and commensurate complexity; do not request a triage runtime, state machine, CLI verb, or enterprise fail-safes.

**Evidence already recorded (Producer):**
- Acceptance greps on the artifact: shape headings = 3 (`^## Recite this|^## Drive loop|^\*\*Done rule`), `ROADMAP.md` = 0, stop-sentences (`request confirmation before generating|before any triage work|not ready to triage`) = 0, `proof-of-load` mentions = 3.
- Red controls observed failing: (i) deleting the `## Drive loop` heading → headings 2; (ii) mutant with all three headings + the old sentence "Running the planner writes a file, so request confirmation before generating or refreshing one" appended → stop-sentences 1 (rejected).
- PDDA gates (frontmatter, status-table, roadmap-coverage, changelog, hardcoded-paths): 0 errors. `test/xyz-harness-hooks.sh` in a separate disposable clone at `a9a41baa`: 62 pass, 0 fail; clone identity unchanged.
- Codex plan QA R2 Approved; the two R2 nits (terminology; qualified exit-2 sentence) are applied — check them.

**Walkthrough — for each scenario, read the skill as an agent would and say which step you would be on, what you would run, and what terminal shape you reach; state where (line) the text tells you so. Grade whether any step would make you ask the operator instead:**
1. No umbrella issue exists; two unrelated candidate issues are open, one with a capture doc and a valid contract, one with a capture doc and no contract.
2. An open issue in scope has no `GH-<n>-*.md` in `1-INBOX` or `2-WORKING`; `releases roadmap add` succeeds. Variant: `roadmap add` fails.
3. A promoted candidate's preflight exits 3 (invalid contract); another exits 4.
4. `gh` is unavailable (planner exit 6 on `--require-gh`, or `gh issue list` fails).
5. (Failing control) Read the previous skill at `origin/development:skills/marathon-triage/SKILL.md` for scenario 1 and confirm it stops at 0b ("before any triage work") — that is the behaviour this rewrite must not reproduce.

**Questions (grade each, cite `file:line`):**
1. Recite block: does it name the five phases, the Done rule and the Overall Goal, and is the Step-0 sentence correctly qualified (guard enabled, no prior proof-of-load)?
2. Guardrails: is the default/confirmation boundary exactly as approved — readiness computation with stated side effects + reversible intake inside; promote/close/fire/branch/write-plan-file behind confirmation; the strict-read-only override covering metadata effects and reporting readiness as unavailable rather than skipping silently?
3. Drive loop table + Done rule: does every planner code (0/2/3/4/5/6/other) and preflight code (0/2/3/4/5/6/7) map to an action/classification and a terminal shape? Is "direct calls even for `--deep`-covered items" stated and justified?
4. Step 3 recipe: executable as written? Check `hq_render_capture` argument order (`hq-lib.sh:401-416`), `hq_slug` output vs the PDDA filename convention (SCREAMING-KEBAB, 2–4 words), the `roadmap add` flags vs `releases_app.py roadmap add --help` if you can read it, `hq_roadmap_line` argument order (`:548-550`), half-complete handling. Anything the recipe would produce that a PDDA gate flags?
5. Step 7 (before firing): is anything from the old 0b/0c lost or weakened, and does no triage step reference it as a prerequisite?
6. Report section: are complete and blocked shapes both fully specified; does the decisions list cover commit-captures and open-umbrella?
7. Residual: any sentence left that would make an agent stop and ask before Step 6? Any `ROADMAP.md` or retired-tool reference? Any claim about the CLIs that the sources contradict?
8. Scope: anything beyond a doc rewrite; anything that belongs in #443?

Output: graded findings with citations, `swept file: yes|no`, VERDICT with Basis. Do not edit any artifact — findings only.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
