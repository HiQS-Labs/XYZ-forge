# RELAY · GH-1139 Plan QA — todo-list daily skill delegating 10x10m wake loop to handsfree
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: —
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh-1139-plan-qa-todo-list-daily-skill-delegating-10x10m-wake-loop-to-handsfree): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md** in the committed checkout; also inspect `skills/1-hourly/handsfree/SKILL.md` and `ARCHITECTURE.md` (`### 2-daily`).
- Reviewer: codex   ·   Producer: agy-producer
- Started: 2026-10-18
- Definition of Done: Surgical, DRY plan for the Markdown-only `todo-list` daily skill (`skills/2-daily/todo-list/SKILL.md`) that extracts the preceding assistant list into an ordered checklist and delegates the 10x10m watchdog wake loop to `handsfree` via a small subroutine-override clause, with grounded ratings (`65/20/50/85`), bounded docs-tier verification (`pdda.sh run` + `gh778`/`gh798` index checks), and no new CI tests (`AGENTS.md` GH-831).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer (agy-producer) · Plan QA Request

Review `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md` alongside `skills/1-hourly/handsfree/SKILL.md` and `ARCHITECTURE.md:72-98`.

**Operational Envelope (Commensurate Complexity):**
This is a lightweight, Markdown-only daily skill (`skills/2-daily/todo-list/SKILL.md`) plus a 1-paragraph caller-override clause in `skills/1-hourly/handsfree/SKILL.md` and a 1-row index addition in `ARCHITECTURE.md`. Grade strictly against the stated operator requirements and commensurate complexity — do not demand scripts, daemons, new CI test files (forbidden by `AGENTS.md` GH-831), or enterprise multi-tenant machinery.

Please evaluate:
1. Are the recon claims grounded in the actual repo paths (`skills/1-hourly/handsfree/SKILL.md`, `ARCHITECTURE.md`, `utils/ci-route.sh`, `test/gh778-review-code-skill.sh`)?
2. Are all operator requirements covered (numbered todo list from the list above, remembered in chat/native task tool + gitignored `temp/todo-list-YYYY-MM-DD-<session-token>.md`, executed in recommended order immediately, `10 x 10 minutes` = 100-minute / 10-iteration watchdog timer delegated to `handsfree` with early cancel on completion/blocker, PR-only without local deployment)?
3. Does the plan cleanly extend the existing `handsfree` skill rather than duplicating per-harness scheduler instructions?
4. Are blast radius, rollback, falsifiable verification checks (including a witnessed red control on `test/gh778-review-code-skill.sh` and the `pdda.sh run` docs gate), and the `65/20/50/85` RELEASES rating + recurrence check sufficient?

Do not run `validate.sh`, `pytest`, or mutating git commands. Append one reviewer block with `swept file: yes`, cited findings, `VERDICT: PASS|FAIL|PARKED`, and `Basis:`. If approved, set header `STATUS: Approved` and `NEXT: —`.

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL

Basis: The Markdown-only design and reuse boundary are sound; revise the verification plan in two small places before implementation. Reviewed the entire capture, entire handsfree skill, and architecture document, with direct source inspection of both named index suites and routing rules. No additional pre-existing defect found in the reviewed artifact/supporting Markdown beyond the verification gaps below. This is plan QA, not implementation approval.

- [Should] **Add a bounded manual acceptance walkthrough for the feature itself.** `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md:68-69` verifies index hygiene and PDDA, but neither named suite reads the new skill or handsfree; their relevant assertions only compare the daily count (`test/gh778-review-code-skill.sh:43-46`, `test/gh798-status-skill.sh:39-42`). The count red control is useful but cannot detect a missing checklist contract or a caller that accidentally retains the 3-hour default. Fix: extend the existing verification step with a short, recorded manual walkthrough using a preceding two-item assistant list (first item waits asynchronously), checking ordered numbered persistence, immediate first action, checklist advancement on wake, the shared note/job identity, the earlier of 100 minutes or ten wakes, and early completion/blocker cancellation. Inspect the unsupported-scheduler branch for honest unarmed reporting. Keep this a manual check in the already-planned evidence receipt; no new suite, scheduler implementation, or actual 100-minute soak is requested. Include a paper red control: substituting the inherited 3-hour deadline must fail this acceptance review.
  Observed input: The existing suites bind `SKILL_FILE` to `review-code-xyz` / `where-are-we-at`, not todo-list (`gh778:7-8`, `gh798:6-9`); the complete plan's steps 4–5 name only these suites, PDDA and releases checks.
  Affected scope: Verification of GH-1139's new prose contract and its two caller overrides only.
  Falsifier: Existing planned coverage that reads todo-list/handsfree and rejects a missing checklist or unchanged 3-hour caller deadline would make the extra manual walkthrough unnecessary; the inspected suites do neither.
  Probe (exit 0): `python3 - <<'PY'
from pathlib import Path
for f in ('test/gh778-review-code-skill.sh', 'test/gh798-status-skill.sh'):
 t=Path(f).read_text()
 print(f, 'todo-list='+str(t.count('todo-list')), 'handsfree='+str(t.count('handsfree')))
PY` → `test/gh778-review-code-skill.sh todo-list=0 handsfree=0`; `test/gh798-status-skill.sh todo-list=0 handsfree=0`. This literal probe supplements the source trace, rather than proving coverage absence by itself.

- [Should] **Specify the full-clone boundary for the planned suite runs and red mutation.** `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md:68-69` currently gives direct suite commands and an architecture mutation without naming their execution location. Fix: explicitly run both suites and their count-mismatch red/green control in a separate disposable full clone containing the candidate state, with restoration from a pre-mutation file copy. Retain the resulting provenance in the task PR. Do not use the working task clone or a linked worktree for these runs (AGENTS.md GH-564).
  Observed input: Step 4 says `bash test/gh778-review-code-skill.sh` / `bash test/gh798-status-skill.sh`; step 5 mutates the architecture count; neither step establishes isolation.
  Affected scope: These existing suite invocations and their red control, not ordinary read-only Markdown inspection.
  Falsifier: An explicit disposable-full-clone instruction covering steps 4–5 would resolve this finding; the current 70-line capture has none.

- [Pass] **Surgical reuse and scope:** capture lines 40–52 specify ordered extraction, dual persistence, immediate execution, 100-minute/ten-wake delegation, no scripts/new CI/deployment, and an Easy rollback. Handsfree already supplies scheduler receipt/readback, failed-creation cleanup and no duplicate-job handling (`skills/1-hourly/handsfree/SKILL.md:33-64,97-107`). Preserve those protections and the standalone default when adding the override.
- [Pass] **Index recon and ratings:** `ARCHITECTURE.md:72` declares 20 daily skills; a read-only `Path('skills/2-daily').glob('*/SKILL.md')` count returned `20` (exit 0), supporting the planned 21. The score `65/20/50/85` sums to 220 and each axis has a rationale (capture lines 56–60). The recurrence claim at line 61 lacks a query/receipt here and remains unverified, rather than independently confirmed.
- [Unverified — needs clone run] No suite, PDDA gate, red mutation, or live scheduling was executed during this reviewer turn. Their eventual green results and committed provenance remain implementation obligations. Graph inventory had no matching task/worktree project; nearest `XYZ-forge` index generation was `2026-09-01T15:54:30Z`, with missing/not-tracked/changed freshness for the six reviewed paths. Used current local source instead; no completeness claim rests on that stale graph.

Handing off to Producer (agy-producer) — disposition both findings, update the plan, and return for Round 2.

### Producer (agy-producer) · Round 2

- **Finding 1 (`[Should]` Add a bounded manual acceptance walkthrough for the feature itself):** `Disposition: Implemented`. Updated `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md:69-72` (Step 5) to include `TESTS-RESULTS/2026-10-18+GH-1139/session-example.md` with a two-item assistant list walkthrough (Item 1 waiting asynchronously), verifying ordered numbered extraction, dual persistence (`temp/todo-list-YYYY-MM-DD-<session-token>.md` + chat/native task tool), immediate Item 1 execution, shared note/job identity and checklist advancement on wake, the earlier of 100 minutes or 10 wakes (`10 x 10 minutes`), early completion/blocker cancellation, honest unarmed reporting when no same-conversation scheduler exists, and a paper red control rejecting an un-overridden 3-hour deadline or missing checklist. Also recorded the exact `gh issue list` recurrence query/receipt at line 61.
- **Finding 2 (`[Should]` Specify the full-clone boundary for the planned suite runs and red mutation):** `Disposition: Implemented`. Updated `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md:67-68` (Steps 4–5) so `test/gh778-review-code-skill.sh`, `test/gh798-status-skill.sh`, and the `cp ARCHITECTURE.md ARCHITECTURE.md.bak` count-mismatch red/green mutation explicitly run only in a separate disposable verification full clone (`../XYZ-forge-gh1139-todo-list-skill-2026-10-18-verify`), never in the working task clone (`AGENTS.md` GH-564).

Handing off to Reviewer (codex) — go to the codex window and say 'take your turn'.

### Reviewer · Round 2

swept file: yes

VERDICT: PASS

Basis: Approve this bounded Markdown-only plan for implementation. Re-read the entire 73-line capture, entire handsfree skill and architecture document, plus the relevant routing rules and both existing index suites. Both Round 1 findings are resolved; no additional actionable plan defect found in this sweep. This verdict approves the plan, not implemented behavior or merge readiness.

- [Pass] **Manual acceptance is now falsifiable.** `PROJECT/1-INBOX/GH-1139-TODO-LIST-SKILL.md:71-72` specifies the two-item async walkthrough, numbered extraction, dual persistence, immediate execution, shared note/job identity, advancement on wake, the earlier of 100 minutes or ten wakes, early cancellation, unsupported-scheduler reporting, and a paper red control rejecting the inherited 3-hour default or missing checklist. The session example and committed provenance have explicit destinations. This resolves Round 1 finding 1.
- [Pass] **Verification isolation is explicit.** Capture lines 69–70 place both index suites and their count-mismatch red/green control in a separate disposable full clone, with backup/restore from a file copy. Their source still compares the declared daily count to disk (`test/gh778-review-code-skill.sh:43-46`, `test/gh798-status-skill.sh:39-42`), so the planned 20-versus-21 mutation targets a real assertion. This resolves Round 1 finding 2.
- [Pass] **Scope and reuse remain surgical.** Capture lines 40–52 and 68 preserve ordered execution, the PR-only/no-deployment boundary, no new scripts/tests, the standalone handsfree default and its create/readback/cancel/no-duplicate protections (`skills/1-hourly/handsfree/SKILL.md:25-64,97-107`). The caller override owns the tighter cap and checklist behavior; handsfree retains scheduler ownership. The docs classification follows `utils/ci-route.sh:64-68,328-343,458-477`; no gate change is planned.
- [Pass] **Current count and arithmetic:** `ARCHITECTURE.md:72` declares 20 daily skills; capture lines 44 and 68 propose 21 after addition, and lines 56–60 explain `65/20/50/85`. Read-only probe (exit 0): `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
from pathlib import Path
p=Path("skills/2-daily")
print("daily_count=",len(list(p.glob("*/SKILL.md"))))
print("score_sum=",sum((65,20,50,85)))
print("todo_list_exists=",(p/"todo-list/SKILL.md").exists())
PY` → `daily_count= 20`; `score_sum= 220`; `todo_list_exists= False`. The absent skill is expected at plan QA.
- [Unverified — needs clone run] No suites, PDDA gate, red mutation, or live scheduler were run here. Execute and retain the planned evidence before final implementation approval. Capture line 61 now includes the recurrence query and reported result; its live GitHub result was not independently re-run this turn.
- Evidence boundary: Verify-tier intent, with direct current-source fallback. Project inventory (84 entries, no further page) contains no matching task/worktree index. Nearest `XYZ-forge` generation remains `2026-09-01T15:54:30Z`; coverage for all six evidence paths reports missing, not-tracked or metadata-changed freshness. No structural or completeness conclusion relies on that stale index.

Relay closed (Approved), no further review turn needed. Producer (agy-producer) may proceed with implementation and the planned verification, then request final QA.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
