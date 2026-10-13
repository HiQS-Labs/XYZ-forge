# RELAY · GH922 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
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
6. **Commit only the relay file** (`relay(gh922-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **plan-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-02

### Artifact — plan-qa.md
```
Review PROJECT/2-WORKING/GH-922-CODEX-SCOPE.md in full against skills/3-weekly/task-sync/scripts/adapters/codex.py, scripts/task_sync.py, scripts/core.py and SKILL.md Native sweep procedure. Local desktop read-only planner, native app tools own writes; no new suites or machinery. User authorized stacked workflow on #902. Questions: 1 Does adding projectId non-null exclusion at sweep candidate selection fix pinned project chats without weakening eligible activity validation? 2 Are recorded root-cause differential, rating 80/80/50/95, dependencies and rollback grounded? 3 Does manual red/green matrix falsify requirements including eligible failure, idempotence, exclusions and invalid snapshots? Read whole affected source; cite file:line. Reviewer writes only relay receipt. Do not run test/*.sh, validate.sh or pytest in worktree. Return Approved if no concrete blockers; include swept file: yes. No speculative contract expansion.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

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
Basis: Approved for implementation. No concrete blockers in the bounded candidate-selection plan; runtime acceptance and PR readiness remain later gates.
swept file: yes

Read the entire GH-922 plan, `skills/3-weekly/task-sync/scripts/adapters/codex.py`, `scripts/task_sync.py`, `scripts/core.py`, and task-sync `SKILL.md`. No additional pre-existing defect found in these files against the stated native planner contract. Graph Verify used primary project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-09-30T07:57:23Z`; task-sync lookup returned no symbols and exact-path coverage reported missing freshness. Used full branch-source reads instead; no graph completeness claim.

- [Pass] Root-cause placement: `skills/3-weekly/task-sync/scripts/adapters/codex.py:90` selects pinned/chats rows without checking project ownership; activity rejection follows at line 96. Native policy explicitly says “Preserve project-grouped chats” (`skills/3-weekly/task-sync/SKILL.md:106`). Adding `row.get("projectId") is not None` to this skip predicate excludes pinned project rows before activity lookup and leaves null/missing IDs on the existing eligible path. Retain this placement and the activity guard. Static probe command: `PYTHONDONTWRITEBYTECODE=1 python3 -` using `ast.parse(Path("skills/3-weekly/task-sync/scripts/adapters/codex.py").read_text())`, selecting sweep If nodes at lines 90/96 and counting projectId string constants. Exit 0; decisive output: `projectId references: 0`; line 96: `not self._seconds(at) or at > captured + 60`. This measures current source, not fixed runtime behavior.
- [Pass] Blast radius and rollback are bounded: plan lines 31 and 48 restrict work to the existing predicate, preserve manual pins, add no writer/schema/helper, and specify commit revert. Snapshot shape/inventory checks remain before selection (`skills/3-weekly/task-sync/scripts/adapters/codex.py:19`); CLI refuses Codex writes before dispatch (`skills/3-weekly/task-sync/scripts/task_sync.py:210`). Keep these boundaries.
- [Pass] Planned proof is falsifiable: plan lines 41-43 require the base mixed-inventory assertion to fail, fixed planner to succeed, missing eligible activity to retain CLI exit 3, and checks for exclusions, actual-old turns, invalid snapshots, full descriptions, manual pins and idempotence. These correspond to adapter lines 95-110, CLI lines 129-132/229, and `skills/3-weekly/task-sync/scripts/core.py:72`. Execute and commit the named manual receipts/provenance before final QA; do not count this plan review as their execution.
- [Pass] Rating and dependency treatment are proportionate to the stated incident: plan lines 22/32/36 distinguish one incident repeated across ticks from independent incidents, leave prior rate unknown, justify 80/80/50/95, and require #900 then #902 before landing. Keep the dependency disclosure and retained-clone state in the eventual PR.
- [Unverified — needs clone run] The private 06:38/06:53 snapshot replay (plan line 29), incident frequency, remote prerequisite state and runtime red/green results were not independently measured here. The manual matrix is a future acceptance requirement, not an existing passing receipt. No validate.sh, test/*.sh, pytest, executable fixtures, Git commands, deployment or source edits were performed.

Relay closed (Approved), no further review turn needed. Handing the completed token to Producer (`codex-producer`) to implement the approved plan and obtain final QA.


### Attestation · relay-drive — 2026-10-02T07:05:04Z
task: RELAY-gh922-plan
reviewer: codex
status: Approved
reviewed-head: 23b3239de9bb795344fb0e63f54e92d748439a80
added-range: 6173+3532
added-sha256: 90d8fa8e8718f1f1199a986f6e1c2a77c41474f5b3594663dd0d6bebf0ade9e6
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
