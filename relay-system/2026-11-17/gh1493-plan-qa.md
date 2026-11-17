# RELAY · GH1493 plan QA (published retirement per-path preservation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1493-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1493-RETIRE-PUBLISHED-BATCH.md` (the plan; no code changed yet).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Operational envelope: a local developer CLI (`merge_cleanup.py --retire-published-pr`) called by
  start-task closeout on one machine. Grade against the stated requirements and commensurate
  complexity; do not ask for enterprise fail-safes. XYZ-forge forbids new tests (AGENTS.md
  *No new tests*, GH-831): verification is existing suites plus a manual check under `TESTS-RESULTS/`.

### Step A — paraphrase first (GH-1414), before reading anything except the plan
Read only the plan doc. Then, before opening any source file or the issue, write in your block:
**What this proposes** (2–5 sentences), **How the existing system works, per this document**
(2–5 sentences), and a short **What it's not**. Label inference. Record the input boundary
("plan doc only").

### Step B — source-backed validation
Then read: issue https://github.com/HiQS-Labs/XYZ-forge/issues/1493 and its scoping comment (body is
summarised in the plan's "Observed problem" and "Requirements"), and the source:
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2387-2429` (`retire_published_checkouts`),
  `:1590-1605` (the existing `Skipping …: disposition is …` per-checkout skip), `:362-380` (log helpers)
- `skills/2-daily/merge-cleanup/scripts/scan_clones.py:529-570` (`published_pr_head`)
- `skills/2-daily/merge-cleanup/SKILL.md:121-127, 474-479, 634-666`
- `skills/1-hourly/start-task/SKILL.md:100-125, 340-375`

- Definition of Done (the Reviewer grades against these):
  1. One ineligible `--checkout` path no longer aborts the call: it prints `PRESERVED <path>: <reason>`,
     the other paths are still inspected/retired by the unchanged teardown path, exit 1 if anything
     was preserved.
  2. The origin check stays; its refusal names the supported way to make a helper (keep the
     canonical origin). start-task SKILL.md gains one sentence that helpers keep the canonical origin.
  3. Controls unchanged: a different repository and a helper with an unpublished local commit are
     still preserved.
  4. No new test files or registry entries; the manual check has a red control on base `9331cec67`.

Questions:
1. Are the plan's claims grounded in the cited lines (single `try`, exit 2, origin check, the
   classification constraint in `published_pr_head`)?
2. What prevents an unchanged, unfixed candidate from being reported as delivered? Does the planned
   manual check (four paths in one call, red on base, green after) actually observe the batch
   decision, and is stubbing inspection/teardown acceptable for that purpose?
3. Which per-path refusals should become `PRESERVED` versus stay a whole-call exit 2? The plan keeps
   only the primary-origin failure as exit 2. Is anything else genuinely call-level (e.g. the
   executing-directory or overlap checks)?
4. Is the exit-code change (2 → 1 for a bad path) safe for every caller? Cite callers.
5. Is the plan surgical and DRY: no new subsystem, no change to classification/teardown? Flag any
   over- or under-engineering, including whether the merge-cleanup SKILL.md clause is needed.
6. Is the control for "helper with an unpublished local commit" adequately witnessed by the planned
   real-PR smoke, given classification code is untouched?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
