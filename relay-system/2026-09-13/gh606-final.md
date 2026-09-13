# RELAY · GH-606 End of Week final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-606-end-of-week-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/end-of-week/SKILL.md`, `ARCHITECTURE.md` skills-index addition, GH-606 plan/recon, and `TESTS-RESULTS/2026-09-13+GH-606/`
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-13
- Definition of Done: The approved plan is PROJECT/2-WORKING/GH-606-END-OF-WEEK-SKILL.md. Review the entire skill, matching each acceptance scenario to actual instructions. Answer:
  1. Does it meet the operator's six tasks/two goals, seven-day window, GitHub-configured default branch, write scope, up-to-ten umbrella gaps, justified Critical/High priority title, and script-recommendation-only boundary?
  2. Does configuration remain portable and user-owned, including consumer/harness roots, repo .xyz vs device .xyz, effective work connector settings and repos[0] scope?
  3. Are HiQS freshness/coverage, fail-soft board outcomes, lifecycle writer choice, bounded resume/completion and public-private evidence handling correct?
  4. Can the workflow reach a verified board result without publishing unmerged task-clone metadata or bypassing canonical writers? Flag command/semantic errors against current code.  [Unverified — no citation]
  5. Do evidence and claims distinguish docs checks/scenario reasoning from live execution? The broad harness prerequisite rerun is still pending and is NOT claimed green; do not require live board mutations for an instructions-only artifact.
Cite exact file:line. Read only; only update this review file. Do not run suites or change production artifacts. Give concrete bounded fixes; do not expand scope into repairing existing runtime gaps.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

VERDICT: FAIL
Basis: The core instructions satisfy most acceptance scenarios, but connector containment must apply before the first metadata writer, and the touched architecture file contains a contradictory authority statement. Both fixes are documentation-only; no runtime repair is requested.
swept file: yes

- [Should] **F1 — Establish connector containment before any metadata write.** `skills/end-of-week/SKILL.md:156` requires umbrella intake/rating through RELEASES before the task-clone suppression instruction at `:169` and effective board/repo validation at `:187`. Every `perform_write` invokes connector dispatch (`utils/py/releases_app.py:1656`–`:1660`), and the explicit suppression is `XYZ_WORK_CONNECTORS=0` (`:1548`). Thus step 4 registration (and a local writer in step 2) can project unmerged clone events or write to a device-configured foreign board before step 6 checks `repos[0]`. **Fix:** establish a workflow-wide pre-write rule before step 2: suppress post-write connectors for all unmerged/task-clone writes, including umbrella intake/rating; permit dispatch only after authoritative-state and effective board/repo/kill-switch checks. Keep the existing six-task order; cross-reference the configuration preflight rather than duplicate it. Add a scenario explicitly covering step-4 intake with an enabled foreign board.
- [Should] **F2 — Correct pre-existing roadmap authority drift in the swept architecture file.** `ARCHITECTURE.md:366`–`:367` says markdown remains the source of truth and describes sync without its legacy-mode restriction, contradicting `ARCHITECTURE.md:371` and the current releases-mode refusal in `utils/py/releases_app.py:3954`–`:3956`. **Fix:** qualify the shadow/sync description as legacy-mode only and point current XYZ users to the RELEASES ledger. No runtime changes.
- [Pass] Six tasks/two goals, fixed seven-day window, GitHub default-branch discovery, justified Critical/High titles, up-to-ten gaps and recommendation-only script scope are explicit (`skills/end-of-week/SKILL.md:29`–`:37`, `:49`–`:63`, `:74`–`:100`, `:137`–`:155`). No fix needed.
- [Pass] Consumer/harness roots and user-owned configuration are distinguished; effective fallback settings and `repos[0]` are required (`skills/end-of-week/SKILL.md:68`–`:72`, `:181`–`:193`; `utils/py/device_config.py:29`–`:31`; `utils/py/work_connectors/github_board.py:102`–`:107`). F1 addresses when those safeguards take effect.
- [Pass] HiQS cache freshness/coverage, private-evidence filtering, bounded retry/resume, lifecycle-vs-work-start semantics and fail-soft read-back requirements are explicit (`skills/end-of-week/SKILL.md:39`–`:45`, `:102`–`:130`, `:157`–`:160`, `:203`–`:223`). Current source supports the lifecycle command and 500-event batching (`utils/py/releases_app.py:5021`–`:5062`; `utils/py/work_connectors/__init__.py:127`–`:131`). No additional defect found in the skill sweep beyond F1.
- [Pass] Evidence distinguishes authored-doc checks and recorded negative controls from live execution; the invalidated broad prerequisite and pending rerun remain explicit (`TESTS-RESULTS/2026-09-13+GH-606/SUMMARY.md:5`–`:6`, `:16`–`:19`, `:25`–`:28`; corresponding entries in `provenance.jsonl`). No live board mutation or green full-suite claim is required for this review. No fix needed.

Review method: Read-only source/scenario review of the entire skill, plan/recon, architecture and three evidence files. No artifact, test, suite or git command was run. Graph inventory had no matching task worktree; nearest XYZ generation 2026-09-01T15:54:30Z reported changed/untracked material paths, so current source reads superseded it. This is not a runtime conformance certification or an exhaustive audit of adjacent runtime files.

Handing off to Producer — address F1/F2, record dispositions, and return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
