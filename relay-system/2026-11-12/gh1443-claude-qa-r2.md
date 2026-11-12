---
Goal: Independent Claude Opus QA round 2 of PR #1444 (GH-1443 Jog target-aware readiness)
Date: 2026-11-12
NEXT: claude
STATUS: Open
---

# GH1443 independent Claude QA — round 2 — PR #1444

This is a fresh, separately tokened review turn. Round 1 (`relay-system/2026-11-12/gh1443-claude-qa.md`,
packet `2e9281542`, review `3164c2cab`) reached no Blocker or Should, but the driver refused it with
exit 4 `review-body-rewritten`: the review was inserted ABOVE the automation block instead of
appended after it, so it is not a driver-attested approval. That thread is preserved history. Do not
edit it, and do not copy its text into this review. Write your own review from your own reading.

## What to review

Local branch head `304720e22cfcc559b8dcaf5c97f4271e8f9aff9e` against base
`43265eed2359f781f942543af74c6d12c990cf00` (`git diff 43265eed2..304720e22`). The commit that adds
this thread changes only this relay file. Check with `git diff 304720e22 HEAD --stat`.

- Runtime is unchanged since the published head `9fbdd6330` and the qualified head `ff4592c88`:
  check `git diff ff4592c88 304720e22 -- utils test --stat` is empty.
- `304720e22` changes three docs only: `skills/2-daily/jog/SKILL.md` (dry-run paragraph),
  `PROJECT/2-WORKING/GH-1443-JOG-READINESS.md` (one prerequisite row) and
  `TESTS-RESULTS/2026-11-12+GH-1443/SUMMARY.md` (new "Additional Claude review" section).

Operational envelope: a local developer CLI (`releases jog run --dry-run --target-root ...`) on one
machine. The runtime change is limited to `utils/py/jog_run.py` plus one invocation line in each of
`test/gh280-jog-marathon-adapter.sh` and `test/jog-queue.sh`. Grade against that scale. Do not ask
for distributed locking, journaled recovery, new suites, new `validate.sh` entries or gate
machinery (AGENTS.md / GH-831: a new suite is itself a finding). Target-aware readiness is
deliberately stricter than the live run; bare `--dry-run` preview must keep its old behavior. Live
provider capacity, credits, gate environments, remote freshness and checkpoint recovery eligibility
are explicitly out of scope and unclaimed. The PR is held: no merge, deployment or handoff is in scope.

Read:
- `utils/py/jog_run.py`: `promotion_probes`, `promote_contract_to_working`,
  `JogCheckpoint.__init__/check_publication/finish`, `validate_checkpoint_options`,
  `_dry_run_preflight`, `jog_run_main` (auto-merge gate, executor validation, dry-run branch, live
  checkpoint validation) and the existing helpers they call.
- `skills/2-daily/jog/SKILL.md`, the two changed test invocation lines,
  `PROJECT/2-WORKING/GH-1443-JOG-READINESS.md`, `TESTS-RESULTS/2026-11-12+GH-1443/SUMMARY.md`,
  `SPIKES.md`, `provenance.jsonl`, `cli-fixed.json`, `helper-final.json`, `full-push.json` and the
  prior Codex receipts `relay-system/2026-11-12/gh1443-plan.codex.md` and `gh1443-final.codex.md`.

## Questions

1. **Fail behavior / exit propagation.** Does every selected item that target-aware dry-run
   preflight refuses, cannot evaluate, or reports as already landed (exit 4) make the run exit
   nonzero after all selected items have printed? Find any path that still exits 0 while an item
   failed, or that exits early and hides later items.
2. **Promotion parity.** Is `promotion_probes` exactly equivalent to the removed inline selection
   (valid legacy `fix_probes` win; contract fallback only when none is valid; nothing executes)?
3. **Checkpoint reuse.** Is `validate_checkpoint_options` behaviorally identical to the removed live
   checks (order, messages, exit 2, before the supervisor lock), and is `check_publication`
   equivalent at its `finish` position? Can dry-run write Jog state or raise an uncaught exception?
4. **Gate widening.** Are bare preview and `--simulate` still exempt from the auto-merge refusal and
   executor validation, with no unintended change for programmatic callers or `--executor relay`?
5. **Complexity.** Is any added helper, branch or message unnecessary, or any claimed de-duplication
   incomplete?
6. **Docs at `304720e22`.** Are the new SKILL sentences (empty queue and `--max-tasks 0` without
   checkpoint mode are previews; inbox probe checks use unattended rules even in a terminal) true
   against the code? Is the widened prerequisite row accurate? Is the SUMMARY "Additional Claude
   review" section an accurate description of round 1 (exit 4 `review-body-rewritten`, commits
   `2e9281542`/`3164c2cab` preserved, not an attested approval)?
7. **Historical helper script claim.** SUMMARY says the `manual-cli-and-helper` provenance records an
   earlier `helper-controls.py` hash and that the earlier script should be retrieved "from its
   recorded source commit, not the current path". Check this read-only: take the `source` commit and
   the `helper-controls.py` hash recorded in that provenance line, then run
   `git show <source>:TESTS-RESULTS/2026-11-12+GH-1443/helper-controls.py | shasum -a 256` (and
   check the stage's recorded command path). If the script is absent at that commit, or the hash
   differs, the SUMMARY instruction is wrong: report it with the exact output, and say where (if
   anywhere) the earlier script can actually be found.
8. **Retained evidence.** Do `full-push.json` (full 408/408 at `ff4592c88`), the focused logs and the
   latest `provenance.jsonl` hashes support the SUMMARY and plan claims? You may hash and parse the
   retained files read-only. Producer evidence is not an independent rerun; say so where it matters.

Measurement rules: narrow read-only probes are allowed (`export PYTHONDONTWRITEBYTECODE=1
TMPDIR="$PWD/.relay-scratch/tmp"` first; quote the command, exit status and decisive output). Do NOT
run `validate.sh`, `test/*.sh`, pytest, the jog CLI against real roots, or any network/provider
call. A claim only measurable that way is graded `[Unverified — needs clone run]`.

## Output and placement (read carefully — round 1 failed on placement only)

Your review is ONE new block appended at the end of this file: below the closing
`△ RELAY AUTOMATION` line of the block that follows, and directly above the final
`NEXT TURN goes here` sentinel line, which must stay the last line of the file. Do not insert,
edit, reflow or delete any line above that sentinel, including this text and the automation
block. The only lines above your block you may change are the `NEXT:` and `STATUS:` header lines.

Start the block with `## Claude Opus QA — round 2 — <Approved|ChangesRequested>`. Tag each finding
`[Blocker]`, `[Should]` or `[Nit]` with `file:line`. Every `[Blocker]` or `[Should]` that asks for a
behavior change MUST carry `Observed input:`, `Affected scope:` and `Falsifier:` lines; a
`[Blocker]` must cite an observed failure. Reject speculative architecture. If nothing at
`[Blocker]` or `[Should]` survives, set `STATUS: Approved`; otherwise set `STATUS: ChangesRequested`.
Either way set `NEXT: orchestrator`. Edit only this file. Do not edit source, docs or evidence.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (claude) — append your review BELOW this block's closing line and ABOVE the final sentinel line.
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
