---
Goal: Independent Claude Opus QA of PR #1444 (GH-1443 Jog target-aware readiness)
Date: 2026-11-12
NEXT: claude
STATUS: Open
---

# GH1443 independent Claude QA — PR #1444

Review the published PR head `9fbdd6330dbd0828945fd909feff0e76f3455ea5` against base
`43265eed2359f781f942543af74c6d12c990cf00` (`git diff 43265eed2..9fbdd6330`). The commit that adds
this thread changes only this relay file, so the source you read at HEAD is byte-identical to
`9fbdd6330` for every reviewed path. Confirm that with `git diff 9fbdd6330 HEAD --stat`.

Operational envelope: a local developer CLI (`releases jog run --dry-run --target-root ...`) on one
machine. The runtime change is 55 added / 29 removed lines in `utils/py/jog_run.py` only. Grade
against that scale. Do not ask for distributed locking, journaled recovery, new suites, new
`validate.sh` entries or gate machinery (AGENTS.md / GH-831: a new suite is itself a finding).
Target-aware readiness is deliberately stricter than the live run; bare `--dry-run` preview must
keep its old behavior. Nobody claims that live provider capacity, credits, gate environments, remote
freshness or checkpoint recovery eligibility were verified, and you should not assume they were.
The PR is held: no merge, deployment or handoff is in scope.

Read:
- `utils/py/jog_run.py`: `promotion_probes`, `promote_contract_to_working`,
  `JogCheckpoint.__init__/check_publication/finish`, `validate_checkpoint_options`,
  `_dry_run_preflight`, `jog_run_main` (auto-merge gate, executor validation, dry-run branch,
  live checkpoint validation), plus the existing helpers they call (`lint_probe`,
  `extract_probes_from_doc`, `contract_probes_from_doc`, `validate_marathon_executor`,
  `_validate_execution_target`, `_preflight_summary`) and the live preflight handling near the
  `pf_res.returncode` checks.
- `skills/2-daily/jog/SKILL.md` (the changed dry-run paragraph), `test/gh280-jog-marathon-adapter.sh`
  and `test/jog-queue.sh` (one invocation line changed in each).
- `PROJECT/2-WORKING/GH-1443-JOG-READINESS.md`, `TESTS-RESULTS/2026-11-12+GH-1443/SUMMARY.md`,
  `SPIKES.md`, `provenance.jsonl`, `cli-fixed.json`, `helper-final.json`, `full-push.json`, and the
  prior Codex receipts `relay-system/2026-11-12/gh1443-plan.codex.md` and `gh1443-final.codex.md`.

Questions:

1. **Fail behavior / exit propagation.** Does every selected item that preflight refuses, cannot
   evaluate (missing helper, inbox identity mismatch, no valid promotion probe) or reports as
   already landed (exit 4) make target-aware dry-run exit nonzero, after all selected items have
   printed? Find any path that still reports 0 while an item failed or was skipped, or that exits
   early and hides later items. Treat empty-queue and `--max-tasks 0` behavior as questions about
   whether the docs are accurate, not as requests for new behavior.
2. **Promotion parity.** Is `promotion_probes` exactly equivalent to the removed inline selection
   (any valid legacy `fix_probes` wins; contract fallback only when none is valid; no probe is
   executed)? The live run promotes with `interactive=sys.stdin.isatty()`, while dry-run always
   refuses when there is no probe. Is that divergence stated where an operator would see it, and does
   it cause any wrong verdict in the unattended case this readiness targets?
3. **Checkpoint reuse.** Is `validate_checkpoint_options` behaviorally identical to the two removed
   live checks (conditions, executor-default resolution, `simulate`, messages, exit 2, still before
   the supervisor lock)? Is the `check_publication` extraction equivalent at its existing `finish`
   position? In dry-run, can constructing `JogCheckpoint` plus `check_publication` write anything
   (journal, `.tick`, refs) or raise an exception type the `except` clause does not catch?
4. **Gate widening.** The auto-merge refusal and `validate_marathon_executor` now also run for
   `dry_run and target_root`. Confirm that bare preview and `--simulate` are still exempt, and
   that no programmatic caller (a namespace without some attribute, `--executor relay`) changes
   behavior unintentionally.
5. **Complexity.** Is any added helper, branch or message unnecessary? Is any duplication left
   that the PR claims to have removed?
6. **Claims and prerequisites.** Do the SKILL text, plan status/rubric ("13 invalid CLI preparations
   formerly returned 0") and SUMMARY match the code and the retained receipts? Is a prerequisite
   claimed as checked but not checked, or a remaining gap missing from the prerequisite table?
   You may verify `provenance.jsonl` hashes and parse the JSON receipts read-only.

Measurement rules: narrow read-only probes are allowed (`export PYTHONDONTWRITEBYTECODE=1
TMPDIR="$PWD/.relay-scratch/tmp"` first; quote the command, exit status and decisive output). Do NOT
run `validate.sh`, `test/*.sh`, pytest, the jog CLI against real roots, or any network/provider
call. A claim only measurable that way is graded `[Unverified — needs clone run]`.

Output: append `## Claude Opus QA — round 1 — <Approved|ChangesRequested>` below. Tag each finding
`[Blocker]`, `[Should]` or `[Nit]` with `file:line`. Every `[Blocker]` or `[Should]` that asks for a
behavior change MUST carry `Observed input:`, `Affected scope:` and `Falsifier:` lines; a
`[Blocker]` must cite an observed failure. Reject speculative architecture. If nothing at
`[Blocker]` or `[Should]` survives, set `STATUS: Approved`; otherwise set `STATUS: ChangesRequested`
and hand back to `orchestrator`. Edit only this file. Do not edit source, docs or evidence.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (claude)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
