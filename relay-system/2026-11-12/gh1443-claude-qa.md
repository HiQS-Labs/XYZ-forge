---
Goal: Independent Claude Opus QA of PR #1444 (GH-1443 Jog target-aware readiness)
Date: 2026-11-12
NEXT: orchestrator
STATUS: Approved
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
freshness or checkpoint recovery eligibility were verified, and you should not assume they were.  [Unverified — no citation]
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

## Claude Opus QA — round 1 — Approved

Reviewer: claude (Opus 5.5), read-only. No validate.sh, test/*.sh, pytest, jog CLI or network run.

### Baseline probes (quoted)
- `git diff 9fbdd6330 HEAD --stat` → exit 0; only `relay-system/2026-11-12/gh1443-claude-qa.md | 81 +++`.
  Every reviewed path is byte-identical to the PR head.
- `git log 630fff3ef..9fbdd6330 -- utils/py/jog_run.py skills/2-daily/jog/SKILL.md test/` → only
  `8744fcb2f test(GH-1443): keep existing bare-preview controls on bare invocation`. `jog_run.py` at
  the PR head is therefore the same code that produced `cli-fixed.json` (source `630fff3ef`).
  `git diff --stat ff4592c88 9fbdd6330` touches only docs and evidence, so the 408/408 full-push
  receipt applies to the reviewed runtime.
- Python `-I` read-only parse of the receipts → `cli-baseline.json 4049ed0b4 passed 3/16, neg 13,
  neg actual0 13, preserved True`; `cli-fixed.json 630fff3ef passed 16/16, neg 13, neg actual0 0,
  preserved True`; `helper-final.json passed 8/8`; `full-push.json rc 0, head before == after ==
  ff4592c88…, status clean`. The rubric claim "13 invalid CLI preparations formerly returned 0" is
  exact.
- sha256 check of all `provenance.jsonl` artifacts → 1 mismatch, explained in Nit 3; every other
  artifact matches.

### Answers
1. **Exit propagation: holds.** `_dry_run_preflight` (`utils/py/jog_run.py:2218-2245`) now returns
   `(status, summary)` on all four paths: missing helper → 2, identity mismatch → 2, no promotion
   probe → 2, otherwise `proc.returncode`. A returncode of 4, or a negative signal code, is `!= 0`. The loop
   (`:2340-2347`) folds `failed = failed or status != 0` without breaking. `sys.exit(2)` runs only
   after `conn.close()` (`:2350`), so every selected item prints before the nonzero exit. Preparation
   refusals (`:2318-2320`) exit before the item list. That is correct: no item is evaluated at that
   point. I found no remaining 0-on-failure path. An uncaught exception inside the helper would print a
   traceback and exit 1, which is still nonzero, and none of the callees can plausibly raise one:
   `extract_probes_from_doc`/`contract_probes_from_doc` catch broadly and the target is pre-validated.
   An empty queue and `--max-tasks 0`/negative values all give 0 with no preflight. That matches "Any
   **selected** nonzero preflight" and "Empty queues remain an empty preview". See Nit 4 for wording.
2. **Promotion parity: exact.** `promotion_probes` (`:1677-1680`) is the removed inline block
   rewritten as a comprehension: lint-valid legacy probes win, contract fallback runs only when the list is empty, and
   `(valid, None)` reproduces the old `contract_reason = None`. Nothing executes:
   `contract_probes_from_doc` checks shape only. Both call sites pass `target` as root (live
   `:2451-2452`, dry-run `:2238`), so `lint_probe` path resolution matches. In the unattended case
   (no tty) the live path returns `unreviewed-probe-contract` (`:1727-1730`), so the dry-run refusal
   is the correct verdict. The attended divergence is Nit 1.
3. **Checkpoint reuse: equivalent.** `validate_checkpoint_options` (`:2206-2215`) has the same
   conditions in the same order: `not max_tasks or <1 or simulate or executor != marathon`. It resolves
   the executor the same way as `jog_run_main:2273`, keeps the realpath-distinct check, and its messages
   print identically after the `jog: ` prefix. The live call still exits 2 before `JogSupervisorLock`
   (`:2361-2367`), and `target` is the realpath from `_validate_execution_target` in both modes.
   `check_publication` has the same two checks at the same point in `finish`: after
   `save()`, before fetch (`:2185`). In dry-run, `JogCheckpoint.__init__` only assigns
   `self.journal`, with no mkdir. `save`/`begin`/`finish` are never called. `primary_config_key` and
   `github_slug_from_origin` only read git config. `_git` raises `ContractError`, `check_output` raises
   `CalledProcessError`, and both are caught at `:2318`. No journal, `.tick` or ref write. One
   observation that needs no action: `git status` in `dirty()` may refresh the publication clone's
   index stat cache, the same as live `finish`. That is not Jog state and is not covered by the "no Jog state writes"
   claim.
4. **Gate widening: correctly bounded.** `target_readiness = dry_run and bool(getattr(args,
   "target_root", None))` (`:2279`). Bare preview (no target) and any `--simulate` remain exempt from
   both gates. `--executor relay` skips executor validation in dry-run and live alike. A namespace
   without `target_root` falls back to the old bare behavior. The rewritten I7 and jog-queue #12
   invocations exercise bare preview, which matches their test names. The old `jog_run_root` helper
   added `--target-root` (`test/gh280-jog-marathon-adapter.sh:597-601`), so those cases never tested
   bare preview.
5. **Complexity: nothing to cut.** Three small helpers, each with two call sites or one documented
   reuse. The duplication the PR claims to remove is gone: the inline probe selection and the two
   inline checkpoint checks are each defined once now. `validate_marathon_executor` also re-checks
   `auto_merge`, but that duplication predates this PR.
6. **Claims: accurate.** SKILL.md:81-90, SUMMARY, plan status and rubric match the code and the
   receipts above. The SKILL is candid about preflight fetches, transient worktrees and contract-probe
   execution. The unverified line printed at `:2321-2323` matches the documented gaps.

### Findings
- [Nit] `utils/py/jog_run.py:2238-2239`, `skills/2-daily/jog/SKILL.md:82`: dry-run refuses a 1-INBOX
  doc with no valid probe even when run from a tty. An attended live run would prompt with
  `Probes: (none declared)` and can continue (`:1732-1738`). The refusal is right for the unattended
  target. However, the operator-visible message includes "unattended mode" only when `reason` is
  None, and the SKILL does not mention the attended divergence. Optional: one clause in the SKILL.
- [Nit] `PROJECT/2-WORKING/GH-1443-JOG-READINESS.md` (Remaining prerequisite coverage): live `begin()`
  also refuses a primary with foreign changes, or with pre-existing ledger changes and no journal
  (`utils/py/jog_run.py:2146,2155-2156`). Dry-run does not check either condition. The "Fresh published
  primary and pending recovery" row arguably covers both, but an explicit "primary cleanliness" mention
  would close the gap.
- [Nit] `TESTS-RESULTS/2026-11-12+GH-1443/provenance.jsonl` stage `manual-cli-and-helper`: it records
  `helper-controls.py` as `44ae848c…`, but the retained file hashes to `53400ae4…`. That matches the
  later `focused-and-real-fallback` stage, so the script was overwritten. `helper-fixed.json` therefore
  cannot be reproduced from a retained script. SUMMARY already marks it superseded by
  `helper-final.json`, and the current entry verifies, so the claim does not depend on it.
- [Nit] `skills/2-daily/jog/SKILL.md:84`: "Empty queues remain an empty preview" could also name
  `--max-tasks 0` (without `--checkpoint-root`). That run prints "would process N pending item(s)
  (capped at 0)", evaluates nothing and exits 0. This is a wording request, not a behavior request.

No [Blocker] or [Should] survives. STATUS: Approved.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (claude)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
