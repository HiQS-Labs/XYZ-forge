# RELAY · GH-1475 Phase 2A final QA (Codex)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
6. **Commit only the relay file** (`relay(gh1475-p2a-final-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md` plus the committed Phase 2A
  implementation it describes. Review the diff with `git diff a9ece7fcf HEAD -- skills test CHANGELOG.md PROJECT TESTS-RESULTS`
  (the merge of `origin/development` brought only unrelated files).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: each of P2.1, P2.2, P2.3, P2.8 (issue #1475) is delivered as the approved plan says
  (`relay-system/2026-11-14/gh1475-p2a-plan-codex.md`, Approved r2), the code paths match the plan, no
  duplicate subsystem or writer slipped in, no new test file or registry entry, and the receipts
  substantiate each claim with an observed red control.

## Review packet (Producer: claude-a, 2026-11-14)

**Operational envelope.** Local operator CLI, one person or agent on one laptop. Grade against the stated
requirements and commensurate complexity; do not ask for distributed locks, daemons or enterprise
fail-safes. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new suite, `validate.sh` entry
or gate machinery would be a finding; editing existing tests to keep them truthful is allowed.
Review-only turn: write only this relay file. Do not run suites or fixtures in the relay worktree
(read-only probes only; mark anything else `[Unverified — needs clone run]`).

Read:
- Plan: `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md` `## Phase 2A` (including the new
  "Phase 2A implementation notes").
- Code: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`checks_state`, `resolve_merge_policy`,
  `_other_merge_cleanup_running`, `prune_retained_scratch`, `_remove_own_scratch`, `_land_prs_loop`: the B1
  branch, the pin check, the checks wait, the re-pin block, `landed_scratch`, the `finally`),
  `scan_clones.py` (`inspect_open_handles`), `ledger_merge.py` (forecast assumption text),
  `skills/2-daily/merge-cleanup/SKILL.md`, `CHANGELOG.md`.
- Tests changed: `test/gh534_phase_b_tests.py` (`assert_repinned`, replaces `land_repaired`),
  `test/gh534_phase_c_tests.py` (four call sites).
- Evidence: `TESTS-RESULTS/2026-11-14+GH-1475-phase2a/` (`README.md` acceptance map, `manual-p2a.py.txt`
  driver, `manual-check-run.log` base vs new, `existing-suite-summary.txt`, `smoke.log`, `provenance.jsonl`).

Acceptance map (claim → evidence):
- P2.8 → manual P2.8 row (base: `B1 stopped`, #2 unpreviewed; new: both previewed, rc 0) + smoke (#1467, #1471 both previewed after a #1413 handoff).
- P2.2 → policy rows, wait/timeout/absent rows, no-key control row.
- P2.1 → rows (a)–(f); existing suites now land the repaired PR in the first run, and `assert_repinned` checks MERGED, no deferral, and that the published selection pins the merged head.
- P2.3 → handles row (red control for the `scan_clones` fix), prune row, four negative controls + positive, exit-3 release row; smoke prune through the real CLI.

Questions:
1. Does each item satisfy the issue and the approved plan? Cite any deviation (file:line).
2. P2.1: can any path re-pin or merge a head that this run did not push, or one whose checks were not read
   as passing on it? Is the plan-QA nit honoured (the `had_required` rule applied to the required part
   before combining with declared checks; pins staged in a copy until `pin_selection` succeeds)?
3. P2.2: is `checks_state` correct for gh's outputs (operator precedence, "no checks reported", repeated
   names, unknown buckets) and does the F6 dry-run warning stay correct with declared checks?
4. P2.3: is pruning safe under the guards (prefix, direct temp-root child, uid, newest N, one-hour floor,
   verified-idle lsof, tri-state pgrep)? Is the exit-3 release limited to landed PRs' own clones? The
   `scan_clones.inspect_open_handles` change goes beyond the plan's surface: is it correct, minimal, and
   acceptable here (it also changes teardown to preserve a checkout whose root is some process's cwd)?
5. Are the test edits truthful updates of pinned behaviour rather than new tests? Is any assertion weakened?
6. Do the receipts actually show each red control failing on base `a9ece7fcf`, or are any only admission
   probes? Is the PRS rating (retained 60/65/50/75) still grounded?
7. Anything duplicated, over-built, or missing (docs, CHANGELOG)?

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, then VERDICT.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
