# RELAY · GH-724 marathon-triage drive-loop plan QA
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
6. **Commit only the relay file** (`relay(gh724-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-724-MARATHON-TRIAGE-DRIVE-LOOP.md` (the plan). Read alongside: `skills/marathon-triage/SKILL.md` (current, to be rewritten), `skills/merge-cleanup/SKILL.md` (the loop shape to mirror: `## Recite this`, `## Drive loop`, `**Done rule**`), `relay-automation/hooks/relay-xyz-guard.sh`, `utils/py/marathon_plan.py`, `utils/hq/hq-lib.sh` (`hq_render_capture`, `hq_roadmap_line`), `utils/hq/hq.sh` (`park`), `PROJECT/PDDA.md` → "GitHub issue intake".
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-20
- Definition of Done: the plan's recon claims are grounded in the cited file:line evidence; the ordered Phase 1 list is sufficient to make `/marathon-triage` run unattended (inventory → reconcile → capture missing intake → planner dry run + per-candidate preflight → report) without inventing new tooling; the read-only/confirmation boundary is drawn correctly (read-only tools inside the default, irreversible actions behind confirmation); the capture recipe reuses the existing writers only; acceptance checks are falsifiable with a red control; non-goals keep #443's code work out; ratings are grounded.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — plan QA packet

VERDICT: PARKED
Basis: awaiting independent plan review.

**Operational envelope.** A markdown skill document (`skills/marathon-triage/SKILL.md`) that instructs a coding agent; local single-repo developer tooling. No runtime code, no tests added, no new writer. Grade against the stated requirements and commensurate complexity: do not ask for a triage runtime, a state machine, a new CLI verb, or enterprise fail-safes. The measurable defect is behavioural: agents invoking the skill stop and ask the operator before writing capture docs, running `swarm-preflight.sh --dry-run`, and running the planner dry run.

**Read first, in full:** the plan doc named in Setup, then the files listed beside it. Measure, read-only: you may run `python3 utils/py/marathon_plan.py --help`, `grep -n` over the cited files, and `bash relay-automation/hooks/relay-xyz-guard.sh` reading (do not execute the harness entrypoints themselves).

**Questions — answer each with a grade and a file:line citation:**

1. Recon grounding: do `marathon_plan.py:49/:52/:58` say what the plan claims (`--dry-run` writes nothing; `--deep` delegates to `swarm-preflight.sh --dry-run`; the exit code set)? Does `relay-xyz-guard.sh:98-100` really treat any Bash command containing `find-harness.sh` as proof-of-load, and are `marathon-plan`/`swarm-preflight` (Bash and Python twins) on the derived block list?
2. Is the diagnosis complete? Beyond the five traced causes, is there anything else in the current `SKILL.md` that would make an agent stop or ask before the end-to-end computation? Quote the line.
3. Is the read-only/confirmation boundary right? The plan puts `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run` inside the read-only default and reserves confirmation for promote / close / fire / cut a branch / write the plan file. Is writing a `1-INBOX` capture doc + `releases roadmap add` row (a reversible, repo-local, ledger-through-the-writer action) correctly treated as *in* the default with commit left to the operator — or should it sit behind confirmation? Give the concrete consequence either way.
4. Capture recipe: does `hq_render_capture` (`hq-lib.sh:401-416`) + `hq_roadmap_line` (`:548`) + `releases_app.py roadmap add` produce the same artifacts `hq park --create` produces for a new issue (`hq.sh:254-345`)? Any field the recipe would miss (e.g. `owner`, `goal`) that a PDDA gate then flags?
5. Drive loop / exit ladder: are the per-code actions for the planner (0/2/3/4/5/6) and preflight (0/2/3/4/5/6/7) consistent with the classification table already in the skill? Is `6 → re-run without --require-gh and mark UNKNOWN` correct given `marathon_plan.py`'s documented degrade behaviour?
6. Done rule: is it falsifiable? Can you construct a report the rule would wrongly accept (an agent that "asked whether to preflight" and stopped)?
7. Acceptance: the grep-count check (`^## Recite this|^## Drive loop|^\*\*Done rule` = 3) and the red control — adequate for a doc-only change, or is something load-bearing unchecked (e.g. the Step 0 proof-of-load sentence, the `ROADMAP.md` = 0 count in the deployed copy)?
8. Scope: is anything in Phase 1 more than a doc rewrite plus a Pulse re-publish? Anything that should be pushed to #443 or a follow-up instead?
9. Ratings `65/45/50/85`: grounded in the recon and the recurrence evidence (#443 + this report)? Appeal is neutral by policy.

Output: graded findings (`[Blocker]/[Should]/[Nit]/[Pass]`), each with the fix and a citation; `swept file: yes|no`; a VERDICT with Basis. Do not edit the plan or any artifact — findings only, in this thread.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
