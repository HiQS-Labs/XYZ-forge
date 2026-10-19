# RELAY · GH-1088 plan QA — start-task orchestrator smoke check before final relay QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
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
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1088-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1088-START-TASK-SMOKE-CHECK.md`, the **plan** (no edit written yet).
- Requirements: GitHub issue #1088 body (an orchestrator smoke check on the main path plus one adjacent path, before final relay QA; recorded as a manual check; GH-831 compliant).
- Read the source the plan cites, not just the plan:
  - `skills/1-hourly/start-task/SKILL.md` (steps 6, 7, 8, 9 and the recited summary block)
  - `AGENTS.md` "No new tests (GH-831)" and "Verified beats plausible"
  - `test/gh609-sdlc-agent-gaps.sh` (`check_start_task_contract`)
  - `utils/ci-route.sh` (how the changed paths route)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-15
- **Operational envelope:** an instruction-only edit to one skill file used by a single operator's agents. Grade against the stated requirements and commensurate complexity. Do **not** ask for new suites, guards, runners or scripts (GH-831 forbids them), or for enterprise process machinery.
- **Definition of Done — answer each with file:line evidence:**
  1. Are the plan's claims about start-task's current steps 6–9 accurate (no orchestrator smoke step exists; step 6's self-review rule; step 9's diff inspection)?
  2. Does the planned placement (end of step 7, evidence line in step 8, a few words in recite item 4) put the smoke step where it runs before final QA without blurring author and reviewer roles, or conflicting with step 6's "do not substitute a self-review"?
  3. Is the requirement set complete for #1088 (main path plus one adjacent path, a manual-check receipt, handed to the reviewer, scaled for docs-only, failure means fix before QA)? Is anything missing or overbuilt?
  4. Does the plan stay inside GH-831, and does it leave the gh609 start-task contract text intact?
  5. Is the verification plan (docs route gate, gh609, a self-applied docs-only smoke) sufficient and falsifiable for an instruction-only change?
  6. Are the rating (55/45/50/85) and its rationale grounded?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the plan for the bounded instruction-only change. Its requirements match the live issue and its placement preserves independent review. This approves implementation, not unexecuted gate results.
swept file: yes

- [Pass] **DoD 1 — current behavior.** Read the entire plan (lines 1–113) and entire start-task skill (lines 1–395), including pre-existing instructions. No additional in-scope pre-existing defect found. `skills/1-hourly/start-task/SKILL.md:212–214` prohibits substituting self-review; `:216–251` contains implementation and verification without an orchestrator smoke step; `:253–272` covers independent final QA; `:274–283` covers diff inspection and emitted-PR checks. The plan's current-state account at `PROJECT/1-INBOX/GH-1088-START-TASK-SMOKE-CHECK.md:19–27` is accurate.
- [Pass] **DoD 2 — placement and roles.** Plan `:54–58` places the paragraph at the end of step 7, evidence in step 8, and visibility in recitation item 4 (`skills/1-hourly/start-task/SKILL.md:52`). Plan `:46–47,63` explicitly says the receipt never substitutes for review. This complements the independent-review boundary at skill `:262–269`; no role conflict.
- [Pass] **DoD 3 — complete and proportionate.** Plan `:40–50` covers main path, one adjacent operator path, commands/output/verdict with provenance, reviewer handoff, docs-only read/justified skip, and fixing or recording a blocker before QA. Source query `gh issue view 1088 --repo HiQS-Labs/XYZ-forge --json body,title,url` exited 0; its Ask explicitly requires “main path” and “one adjacent real-world path”, and permits documentation smoke-reading or a reasoned skip. The plan adds no unnecessary machinery. Its mutation-heavy isolation provision (`:85–86`) reuses skill `:247–250`.
- [Pass] **DoD 4 — GH-831 and gh609 preservation.** Plan `:62–64,82–86` excludes new tests, runners, gates and unrelated skills, consistent with `AGENTS.md:154–162`. `test/gh609-sdlc-agent-gaps.sh:94–106` pins resume/remote-PR/live-HEAD and transport reconciliation strings, located at skill `:124–128,228–229,277–279`; none is a planned edit. The existing suite also has a remote-PR mutation at `:304–310`. This is source inspection, not a claim the suite ran.
- [Pass] **DoD 5 — verification design.** Plan `:90–95` uses the existing docs gate, existing gh609 suite and a self-applied consumer read, sufficient for this instruction-only scope. Narrow classifier probe: `printf '%s\n' skills/1-hourly/start-task/SKILL.md PROJECT/1-INBOX/GH-1088-START-TASK-SMOKE-CHECK.md relay-system/2026-10-15/gh1088-plan-qa.md TESTS-RESULTS/2026-10-15+GH-1088/provenance.jsonl | bash utils/ci-route.sh pull_request` exited 0, output `docs_only=true`, `pdda_needed=true`, `full_required=false`, `route=docs`, `tier=1`. This agrees with `utils/ci-route.sh:63–70,459–477`.
  Manual baseline red control for the proposed evidence check: `python3 -` read the skill with `Path.read_text()`, extracted between `'8. **Run final Codex relay QA'` and `'9. **Open or update'`, asserted a nonempty extraction, printed whether `'smoke' in packet.lower()`, and exited `0 if present else 1`. Exit 1; decisive output: `Step 8 nonempty; smoke receipt in final-review packet: False`. Thus the current artifact fails the proposed smoke-evidence criterion; the implementation receipt must show the changed consumer path satisfies the full requirements, not just keyword presence. Commit its `provenance.jsonl` with the PR (`AGENTS.md:112–119`).
- [Pass] **DoD 6 — rating.** Plan `:99–107` explains 55/45/50/85, labels one episode rather than asserting a trend, and uses neutral appeal and high cheapness consistently with skill `:330–344`. Read-only issue queries for #1074 and #1084 both exited 0 and describe lost merge history/false QA completion and the non-resume rerun bypass, supporting the stated medium process consequence. Exact scores remain a reasoned assessment, not a measured probability.
- [Unverified — needs clone run] Planned gh609 and documentation gates have not run in this reviewer turn; no implementation exists yet. Execute and retain their results against the final revision in the authorized later verification phase. No executable fixtures, tests, git commands, source edits or artifact edits were performed here.

Evidence scope: Verify-tier direct source review. `list_projects` returned no index for this temporary checkout. The nearest XYZ-forge index is generation `2026-09-01T15:54:30Z`; coverage for the five evidence paths reported missing/not-tracked/metadata-changed freshness. Used current local source throughout; no graph completeness claim.

relay closed (Approved), no further turn needed. Producer may proceed with the approved plan; implementation still requires final QA.


### Attestation · relay-drive — 2026-10-15T22:37:49Z
task: RELAY-gh1088-plan-qa
reviewer: codex
status: Approved
reviewed-head: f9363cf289a45d5d26d3608805c755817ccf3095
added-range: 7030+4856
added-sha256: 8529a42142ef3b8f5370eb6ef0f56c15da98d8c2db2e720c475a1fa988a78bd7
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
