# RELAY · GH1493 plan QA (published retirement per-path preservation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Reviewer
STATUS: Open
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

### Reviewer · Round 1

Input boundary for Step A: plan doc only (before source or issue).

**What this proposes:** Move checkout validation into a per-path exception boundary so an invalid helper is reported as preserved while eligible siblings proceed. Keep origin and deletion safeguards, clarify canonical-origin helper creation, and verify the batch change with a base/candidate manual control plus closeout smoke.

**How the existing system works, per this document:** A single validation exception currently prevents the entire batch from reaching inspection. Published-head classification requires a canonical GitHub origin; eligible checkouts then use the existing inspection, refresh, and teardown pipeline. The documented partial-retirement exit status is 1, while the current validation refusal returns 2.

**What it's not:** No acceptance of local-origin helpers, classification redesign, teardown redesign, or new test suite. Inference: preservation is a partial-failure result and does not authorize deleting an otherwise unsafe checkout.

swept file: yes

**VERDICT: FAIL**

**Basis:** The implementation approach is surgical and matches the retrieved scoping comment; tighten the planned evidence before implementation. These are verification-plan findings, not observed runtime failures or requests for a new suite. I swept the entire plan; no other pre-existing defect in that artifact was found. Reversibility: Easy for the code change (single-commit revert); actual retirement still requires the existing fresh safety checks.

- [Should] **F1 — Put an eligible candidate after a refusal and observe the complete delegation.** The manual input at `PROJECT/2-WORKING/GH-1493-RETIRE-PUBLISHED-BATCH.md:82-87` lists eligible (a) first and asserts only that it reaches inspection. That can miss a candidate which handles earlier eligible paths, prints all validation refusals, but stops inspecting candidates after the first refusal. Reorder the same four paths to put (a) after at least one invalid path; assert that (a) alone reaches inspection, refresh and teardown with the expected PR/execute arguments, alongside the three preservation reasons and exit 1. Keep the base red control (no inspection/delegation, exit 2). Stubbing these downstream functions is appropriate for measuring this batch boundary; record their calls rather than equating an inspection call with retirement.
  Observed input: plan lines 82-87: `(a) an eligible path, (b) ... local path, (c) ... different repository, (d) a non-Git directory`; expected green only says `(a) reaches inspection`.
  Affected scope: the one proposed manual batch check and its claimed evidence of continuing after an ineligible path.
  Falsifier: a candidate deliberately stopping candidate processing at the first invalid input must fail this manual check; the intended per-path implementation must pass with an eligible path after that input. This is a proposed sensitivity check, not a probe run during this review.

- [Should] **F2 — Make the unpublished-commit smoke input explicit and distinguish its reason.** Lines 88-90 promise a local-commit control, but the enumerated smoke at lines 91-93 names only task + canonical-origin gate + local-origin helper. Add the promised canonical-origin helper with a clean, unpublished local commit explicitly to the smoke scope, or explicitly assign that state to a named helper. Require preservation for its unlanded ref, not an earlier origin/dirty/session refusal; retain its path/ref/SHA and live PR head in the receipt. No classifier change or extra test file is needed.
  Observed input: plan lines 91-93 enumerate no helper explicitly holding an unpublished commit; a local-origin helper is rejected before classification at `merge_cleanup.py:2412-2414`.
  Affected scope: evidence for requirement 3's unpublished-local-commit control.
  Falsifier: a clean canonical-origin helper with one commit beyond the published PR head must reach ref classification and be preserved for the unpublished ref; preservation solely for an origin mismatch or active session does not witness that control.

- [Pass] **Grounding and scope:** `merge_cleanup.py:2396-2418` has the single exception boundary and exit 2; `:2420-2429` owns the unchanged inspection/refresh/teardown delegation. `scan_clones.py:532-538,562-565` requires a canonical GitHub origin and fetches the exact PR head from origin. The retrieved #1493 scoping comment says “the exit code is 1 when anything was preserved.” Keeping that classifier and improving helper instructions is the smallest sound change. The small merge-cleanup contract clause is useful at its public CLI contract (`SKILL.md:646-666`), alongside start-task's helper naming instructions (`start-task/SKILL.md:117-119`).

- [Pass] **Callers and exit-code compatibility:** bounded source search of `skills/`, `utils/` and `test/` found the CLI dispatch at `merge_cleanup.py:2505-2506`; it returns the retirement result directly, with no branch distinguishing 1 from 2. The documented workflow caller is `start-task/SKILL.md:359-375`; it reports preserved paths and has no numeric retry loop. The public exit table already defines 1 as “could not retire a checkout” (`merge-cleanup/SKILL.md:478`). Invalid PR/mode/primary arguments remain whole-call parser/startup failures (`merge_cleanup.py:2494-2504`); the plan should not be read as removing those.

- [Pass] **Path-local versus call-level refusal:** executing-directory protection identifies that path and its ancestors (`merge_cleanup.py:2402-2404`); independent siblings can still run. Primary-origin failure has no per-path recovery (`:2390-2393`). The proposed overlap rule retains comparison against accepted candidates (`plan:65-66`, source `:2410-2411`); it is order-dependent admission, so a skipped overlapping path is not proof that its contents are outside an accepted ancestor's Trash move. Do not claim stronger subtree isolation from this unchanged comparison. Existing fresh refusal and recoverable removal stay material (`merge_cleanup.py:1596-1606,1653-1667`).

- [Pass] **Unchanged classification safeguards and no suite proliferation:** origin mismatch is rejected at `merge_cleanup.py:2412-2414`; unpublished refs are checked against integration and published heads (`scan_clones.py:646-671`) and yield `PRESERVE_UNPUSHED` at `:1188-1191`. Plan lines 80-96 and 100-102 select retained manual evidence and existing suites, with no new registry or suite. These are source-backed expectations, not executed control results.

**Evidence limits:** Verify-tier review with local source fallback. Graph project `XYZ-forge`, generation `2026-09-01T15:54:30Z`, returned no retirement symbol; coverage reports both Python paths `freshness: not_tracked`, so no graph completeness claim is made. Direct reads and bounded source searches support the citations above. `gh issue view 1493 --comments` succeeded and supplied the scoping comment; subsequent issue-body requests failed with “error connecting to api.github.com”, and the web fallback also failed. The original issue body is therefore unverified beyond the plan's summary. No runtime probes, fixtures, gates or Git commands were run; base/candidate and real-PR controls remain [Unverified — needs clone run].

Handing off to Producer (claude-a) — revise the evidence plan for F1/F2, disposition both findings, then open the next review round.

### Producer · Round 2

- F1 — **Implemented.** Plan "Verification inline" now orders the manual check (b) local-origin, (c) other repo, (d) non-Git, then (a) eligible; the three downstream functions are patched to record calls; green requires (a) alone delegated to inspect (`published_pr=N`), refresh and teardown (`dry_run=not execute`), three `PRESERVED` lines, exit 1; red on base `9331cec67` requires exit 2 and zero recorded calls.
- F2 — **Implemented.** Smoke now names a canonical-origin `-verify` helper, clean, holding one local commit beyond the live PR head; it must reach classification and be preserved as `PRESERVE_UNPUSHED`, not for origin/dirty/session. Receipt keeps path, ref, SHA and live PR head.
- Overlap note — **Accepted.** Plan states the overlap comparison is unchanged and order-dependent; no stronger isolation claimed.

Handing off to Reviewer (codex) — re-review the revised Verification section.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
