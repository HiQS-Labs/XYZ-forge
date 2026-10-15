# RELAY · GH-1064 final QA — script-owned merge-batch record, sweep inputs, --record-sweep, exit 4
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
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
6. **Commit only the relay file** (`relay(gh1064-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/merge-cleanup/scripts/batch_record.py` and the rest of the
  committed implementation on this branch (the diff against origin/development). Code files:
  - `skills/2-daily/merge-cleanup/scripts/batch_record.py` (new)
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`land_prs` wrapper, `_record_batch_outcomes`, `_land_prs_loop` hooks, `select_batch`, `record_sweep`, exit 4)
  - `skills/2-daily/merge-cleanup/scripts/toposort_prs.py` (`_soft_reasons`)
  - `skills/2-daily/merge-cleanup/SKILL.md` (recite item 6, Phase 5 exits, Drive loop step 6, Done rule, protocol section, capability table, options line)
  - `test/gh534_phase_b_tests.py` (stub verbs, `batch_of`, `TestBatchIssue`, updated exit expectations)
  - `test/gh534_phase_c_tests.py` (import, `REQUIRED_CAPABILITIES`, AST pins, controls, updated exit expectations)
- The approved plan and its acceptance map: `PROJECT/2-WORKING/GH-1064-MERGE-BATCH-ISSUE-QA.md`
  (plan QA thread: `relay-system/2026-10-14/gh1064-plan-qa.md`, Approved round 3, including its nits).
- Evidence:
  - `bash test/gh436-merge-cleanup.sh` → `Ran 185 tests … OK`, run from this task clone on commit `bd0229e9`.
  - Three red controls in `TESTS-RESULTS/2026-10-14+GH-1064/provenance.jsonl` and the `red-*.log` files.
  - The full gate (`route=full`, tier 3) runs once after this review approves, in a disposable clone.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-14
- **Operational envelope:** a local operator CLI landing a handful of PRs per run in one repo. Grade
  against the approved plan and the operator scope (the script records and the agent runs the
  suite; exit 4; threshold 2). Do not ask for new suites, guards, runners (GH-831) or enterprise
  fail-safes.
- **Definition of Done — answer each with file:line evidence:**
  1. Does the code match each approved plan item (steps 1–5, R1–R7, and the round-3 nits: landing order, the :935 attribution, a post-merge stop keeping the oid)?
  2. Hard-stop recording: does the wrapper/`_ERR_SINK` design attribute **every** in-loop `return 2` (all 22 sites) to the PR in hand with its diagnostic, and leave later PRs `unattempted`? Is there any path where a stale `current`/`errs` mis-attributes a stop, or where `_ERR_SINK` leaks across calls?
  3. Exit precedence: 2 (including a Phase 6 failure) > 3 > 4 > 0, with Phase 6 running before 4; the QA-only empty-queue resume; and `--record-sweep` doing no discovery, merge or teardown.
  4. Issue ownership: can `update` ever overwrite text outside the markers? Is non-blocking failure honored everywhere (create, view, edit), with the landing unaffected?
  5. `find_unfinished` / `qa_pending` / `continuable`: correct on the resume scenarios, and no accidental match of another repo's or branch's batch?
  6. Is there a duplicate subsystem or writer (a second gh wrapper, lock or persistence path)? Is the test footprint commensurate and inside GH-831 (no new file or registry entry)?
  7. Do the tests and red controls actually substantiate the claims, or could any pass vacuously?
  8. Pre-existing defects in the touched code that this change makes worse.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
