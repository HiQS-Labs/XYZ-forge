# RELAY · GH1066 plan QA: bounded CI groups and adversarial batch review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: —
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
6. **Commit only the relay file** (`relay(gh1066-plan-qa-bounded-ci-groups-and-adversarial-batch-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1066-MERGE-CLEANUP-CI-GROUPS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-14
- Definition of Done: approve the bounded GH1066 plan and its acceptance checks; do not implement.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Bounded plan QA packet

Read PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md in full, skills/2-daily/merge-cleanup/SKILL.md (whole file), docs/CI-CHURN-RECOVERY-SOP.md and the current start-task scope in that plan. The operator requests start-task from development for batch optimization and asks whether adversarial different-model relay review for3+PRs is worthwhile. Proposed policy adds one bounded batch-level review through existing relay-xyz, not a new CI gate/runner.

Operational envelope: local orchestration guidance only. No runtime/CI/settings/new tests; no broad harness or enterprise threat model. Existing Phase5 serial reconciliation and mandatory checks remain binding. Prototype text predates this invocation; new implementation and final publication wait for this plan QA. Reuse existing draft/clone, do not create duplicate intake.

1. Does the plan actually reduce avoidable preparation/qualification churn without claiming unsupported batching or overriding required per-PR checks?
2. Is one different-actual-model adversarial review for3+PRs scoped to groups, ordering, conflicts, qualification and rollback, with material-change invalidation and cap3, commensurate and complete? Challenge redundant reviews.
3. Are policy fallback, neutral missing-review notes, exact revision evidence, and failure handling coherent with the whole skill and existing recovery SOP?
4. Are manual scenarios/red controls sufficient for this prose-only change without new persistent tests? Is the recorded rating65/25/50/85 grounded and modest? Any real requirement missing?

Only this relay thread writable. No git commands, validate/test/pytest/executable fixtures in the reviewer worktree. Grade with file:line citations, swept file: yes/no, and literal VERDICT: PASS|FAIL|PARKED plus Basis. Approve by STATUS: Approved and NEXT: — only if supported; do not self-commit (the harness records the turn). Scope proposed fixes to concrete observed contradictions; no new machinery. No previous plan turn exists; this is round1/3.

### Reviewer · Round 1

Ship the bounded plan; approval covers planning only.

swept file: yes

Reviewed all 100 lines of `PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md`, all 558 lines of `skills/2-daily/merge-cleanup/SKILL.md`, and all 385 lines of `docs/CI-CHURN-RECOVERY-SOP.md`. No additional pre-existing substantive defects found in that prose scope. No graph tools were exposed; this was direct document inspection, not a code/runtime audit.

- [Pass] Preparation is separated from qualification without promising fewer mandatory runs. Plan lines 23–27 and 93 preserve policy; skill lines 238–265 require final-head checks, candidate invalidation, supported landing, and sequential fallback. Phase5's per-merge durability sequence remains explicit at skill lines 280–286. This fits recovery SOP lines 25–27 and 183–202; historical exceptions are not renewed.
- [Pass] One additional batch-level strategy review is proportionate: plan lines 53–62 and 68–77 specify actual model-family difference, identities, exact revisions, grouping/order, conflicts, qualification, rollback, cap3, material-change invalidation, and no claim of approval when review is unavailable. Read “no per-PR duplicate reviews” as avoiding another copy of this strategy review, while preserving existing required per-PR QA receipts (recovery SOP lines 201–202 and 220–221). Final implementation QA must check that distinction in the resulting prose.
- [Pass] The verification plan is falsifiable without adding persistent tests: plan lines 78–85 distinguish three PRs from two, reject one model behind different CLIs, invalidate changed plans, retain sequential fallback, and require threshold/model-condition mutations to be detected. These are planned controls, not witnessed results. The full gate is reserved for the final revision in a separate full clone; no suite or executable fixture was run here.
- [Pass] Rating rationale is modest and explicitly disclaims incident growth and measured CI savings (plan lines 90–93). Read-only probe: `python3 -c 'import sqlite3; c=sqlite3.connect("file:releases.db?mode=ro",uri=True); print(c.execute("select rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr from roadmap_items where gh_number=1066").fetchall())'`; exit 0; decisive output `[(65, 25, 50, 85, None)]`. This verifies persistence only, not a performance result or live remote state.
- [Nit] Correct the artifact reference on the next invocation. `nl -ba .relay-artifacts/GH-1066-MERGE-CLEANUP-CI-GROUPS.md` exited 1: `No such file or directory`; the available seed instead identifies GH182 at `.relay-artifacts/gh182-claim-guards.md:1`. The bounded packet explicitly directs reading the canonical PROJECT plan, so that supplied file was reviewed in full. Revision binding: `shasum -a 256 PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md` exited 0 and returned `a7cbea28d0ea049d048d46f8ec49203f99bdd5d126467ce422dd1548a68984db`. Approval is for those bytes, not the unrelated seed.
- [Nit] When implementing plan lines 78–85, explicitly place the retained manual scenarios and witnessed red controls under `TESTS-RESULTS/<date>+GH-1066/` with committed `provenance.jsonl`, including reviewed revision and outcomes. This makes the existing retention requirement concrete; it does not require a new test or runner (recovery SOP line 202; `TESTS-RESULTS/README.md:7`).

VERDICT: PASS
Basis: The bounded plan reuses existing caller/relay/batch records, preserves mandatory landing checks and review authority, and defines observable manual acceptance. The two notes are non-blocking documentation clarifications. No implementation, CI reduction, current remote state, or successful gate is attested by this approval.

Relay closed (Approved), no further turn needed. Producer may proceed with the approved scope and must obtain final implementation QA and applicable gate evidence before publication.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
