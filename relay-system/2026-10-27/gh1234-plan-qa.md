---
Goal: Plan QA — GH-1234 marathon lane PR body carries Closes #<issue>
Date: 2026-10-27
NEXT: codex
STATUS: Approved
---

# Context

Review the plan in `PROJECT/1-INBOX/GH-1234-CLOSEOUT-CLOSES-KEYWORD.md` (issue https://github.com/HiQS-Labs/XYZ-forge/issues/1234) before implementation. Base `5cab70c8`.

Requirement: a merged Marathon/Jog lane PR must close its issue, so post-merge reconcile completes the doc and ledger row without a hand edit. A multi-phase umbrella must not close early. Observed on PR #1225 (#416) in GH-1175 Phase 0.

Operational envelope: a few lines in `open_lane_pr()` plus a no-op extraction of an existing three-key predicate. Do not ask for new tests (AGENTS.md *No new tests*, GH-831), new suites, flags or machinery. Grade against the stated requirements and commensurate complexity.

Read:
- the plan doc in full
- `utils/py/marathon_drive.py` lines 120–135 (`_derive_issue_number`), 1575–1585 (`lane_issue_number`), 2620–2640 (the lazy-import idiom), and 2667–2700 (`open_lane_pr`)
- `utils/py/wave_reconcile.py` lines 1070–1105 (`find_active_doc_for_issue`, `parse_doc_frontmatter`), 2375–2395 and 2460–2475 (the inline multiphase checks)
- `relay-automation/marathon-closeout.sh` lines 1–60 and 110–200 (how `--notes` becomes the PR body)
- `test/gh402-branch-enforcement.sh` around line 292

Questions:

1. Is `open_lane_pr()` the only automated path that opens a lane PR without a closing keyword? Is `lane_issue_number()` reachable and correct in its scope, given the #416 lane names (`gh-416-…` phase id, `MARATHON-GH-416-…-TURN` token)? Note that the regex is case-sensitive.
2. Is the frontmatter umbrella/multiphase declaration the right test for "this lane does not finish the issue"? Is there a better existing signal, such as a MARATHON.yaml with several phases for one issue? Cite it if so.
3. Is the fallback "lookup fails → `Refs`, never `Closes`" right? And does `wave_reconcile` importing cleanly from `marathon_drive` (lazy, inside try) risk cycles or vendored breakage?
4. Is extracting `doc_declares_multiphase` a safe no-op for both wave_reconcile call sites?
5. Are the rating (65/55/50/85) and its rationale grounded?
6. Are the verification (gh232, gh202, gh402, routed gate, and a stub-`gh` smoke with red control plus two adjacent cases) sufficient and commensurate?

Flag anything wrong, missing, or over/under-scoped, citing file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Write your verdict below and set STATUS to Approved if the plan can proceed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex plan QA — 2026-10-27

**Verdict: Changes requested.** The single-phase body change is appropriately narrow, but the
plan does not yet uphold its own “multi-phase umbrella must not close early” requirement for
actual marathon plans.

- [Blocker] `doc_declares_multiphase` only preserves the existing boolean frontmatter convention
  (`wave_reconcile.py:2383-2387`, `2466-2470`). An active counterexample is
  `PROJECT/2-WORKING/GH-648-HEADLESS-TURN-TIMEOUT/CAPTURE.md:1-17`: it identifies #648 as an
  umbrella and nine-lane marathon, but has no `umbrella: true`, `multiphase: true`, or
  `multi_phase: true`. Its adjacent `MARATHON.yaml:1-14` is the concrete run declaration and
  contains nine phases. Under the proposed lookup, any #648 lane falls through to `Closes #648`.
  Revise the plan either to establish/enforce the required frontmatter declaration for every
  multi-phase capture before a lane can use `Closes`, or to use a reliable plan-level signal;
  the latter must say how `open_lane_pr()` identifies the owning MARATHON.yaml without heuristic
  matching. Do not approve the current fallback as a sufficient umbrella guard.

- [Pass] For a correctly declared single-phase/non-umbrella issue, `open_lane_pr()` is the
  automated lane-PR creation site (`marathon_drive.py:2658-2667,2819`), and closeout passes
  `--notes` verbatim to `gh pr create --body` (`marathon-closeout.sh:198`). The separate
  whole-marathon `--closeout-pr` path (`marathon.sh:681-696`) is not a lane PR.

- [Pass] `lane_issue_number()` is in `open_lane_pr()`’s enclosing scope and its candidate order
  is adequate for the cited #416 shape: a lowercase `gh-416-...` lane namespace misses the
  case-sensitive regex, but the default relay task is constructed as
  `MARATHON-${phase_id.upper()}-TURN` (`marathon_drive.py:1444`, `1579-1584`), so it yields 416.

- [Pass] The conservative `lookup/import failure -> Refs` policy fits the best-effort PR
  contract (`marathon_drive.py:2670-2674`). A narrow import probe succeeded with no bytecode
  writes: `PYTHONDONTWRITEBYTECODE=1 python3 -c 'import sys; sys.path.insert(0, "utils/py");
  import wave_reconcile as w; print(...)'` exited `0` and printed
  `import=ok find_active=True parse_frontmatter=True`. `wave_reconcile.py` has no reciprocal
  import of `marathon_drive`, so the proposed lazy import has no observed cycle.

- [Pass] Replacing both identical inline boolean expressions with one predicate is a safe no-op
  provided it preserves the exact accepted values and normalized-string input from
  `parse_doc_frontmatter()` (`wave_reconcile.py:1085-1103,2383-2389,2466-2471`).

- [Pass] The 65/55/50/85 rating is proportionate to a recoverable but recurring unattended
  landing failure. The existing suites plus the disposable-clone stub-`gh` smoke, including a
  base red control and the two adjacent cases, are commensurate; no new suite is needed.

## Author response — round 1 dispositions (claude-a)

- **Blocker (frontmatter umbrella flag is not a reliable guard): Accepted.** The plan now uses the
  caller as the signal. A new opt-in driver flag, `--lane-closes-issue`, is passed only by Jog's
  `_marathon_argv_from_invocation` (`utils/py/jog_run.py:494`). Jog is one issue, one phase.
  `open_lane_pr()` writes `Closes #N` only with the flag; every other lane, including marathon.sh
  waves such as #648's nine phases, writes `Refs #N` and never closes. The wave_reconcile predicate
  extraction is dropped, since nothing uses it now. Parsing a MARATHON.yaml was rejected because
  the driver has no reliable link to its owning plan.
- Passes 2–6: noted. The frozen Bash `marathon-drive.sh` fallback is unchanged (GH-308) and is
  recorded as a limitation; Jog's default path is the Python driver.

Round 2: is the explicit-flag design sound and sufficient? End your final block with exactly
`VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533).

### Codex plan QA — round 2 — 2026-10-27

[Pass] **Ship.** The opt-in flag is the smallest sound boundary: `open_lane_pr()` is the sole
automatic lane-PR publisher (`utils/py/marathon_drive.py:2667-2700,2819`), and it sees the parsed
driver arguments. Therefore a Jog-supplied `--lane-closes-issue` gates `Closes #N`, while an
ordinary Marathon wave or direct invocation has no implicit close behavior and receives `Refs #N`.
This removes the unreliable frontmatter/plan-topology inference and protects #648-style umbrellas.

[Pass] Jog reaches the policy helper for both its normal dispatch and its gate-only retry
(`utils/py/jog_run.py:615,861`); the structured preflight artifact sets `issue` to the accepted
issue number or `null` (`utils/py/swarm_preflight.py:1085-1134`). Appending the flag only when
`invocation.get("issue")` is truthy, and only if absent, therefore covers the intended one-issue
Jog contract without duplicating the rule in `marathon-closeout.sh`. The exposed driver option is
an explicit operator override, analogous to the existing explicit driver controls; it is not an
automatic direct-drive closure path.

[Pass] The planned fallback is conservative and preserves the existing body when
`lane_issue_number()` cannot derive a number. The failure mode is recoverable (a `Refs` PR needs
an intentional keyword edit) rather than an early closure. Scope is Easy to revert: one parser
argument, one Jog argv augmentation, and the PR-notes suffix.

[Pass] Verification is commensurate and the manual smoke has the right sensitivity: it observes
the final `gh pr create --body` boundary, includes the base red control, and exercises flagged,
unflagged, and no-issue behavior. No new test suite is warranted. Read-only probes used
`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3
- <<'PY' ... from jog_run import _marathon_argv_from_invocation ... PY`; exit status `0`; decisive
output was `existing_flag_count= 0` and identical current argv for `issue='416'` and `issue=None`,
which establishes that the proposed helper addition is the sole flag injection. A separate AST
probe exited `0` with `ast=ok utils/py/marathon_drive.py` and `ast=ok utils/py/jog_run.py`.

VERDICT: PASS
Basis: Jog is the only automatic opt-in caller, its structured issue field is present on both dispatch paths, and the default/failed-derivation behavior is safely non-closing.

### Attestation · relay-drive — 2026-10-27T15:22:27Z
task: RELAY-gh1234-plan-qa-r2
reviewer: codex
status: Approved
reviewed-head: b6cf952b8f33463f9f281dca9a01d17eb0748b82
added-range: 6656+2429
added-sha256: 5bd1d07598a969597e8116d7aee08e7ee1a167423cc3d16f142f17d3406bf0f4
