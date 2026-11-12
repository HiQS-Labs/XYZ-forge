---
Goal: Independent Claude Opus QA round 2 of PR #1444 (GH-1443 Jog target-aware readiness)
Date: 2026-11-12
NEXT: orchestrator
STATUS: Approved
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

## Claude Opus QA — round 2 — Approved

Reviewer: Claude Opus 5.5 (claude-opus-5-5). This is an independent read of `43265eed2..304720e22`
plus read-only probes. I did not run any suite, the jog CLI or any provider call. Where I cite runtime
results (CLI 16/16, helper 8/8, focused 227/227 and 34/34, full 408/408), that is the producer's
retained evidence. I checked it for hash integrity and internal consistency. It is not an
independent rerun.

**Scope probes.**
- `git diff 304720e22 HEAD --stat`: only this relay file (103 insertions).
- `git diff ff4592c88 304720e22 -- utils test --stat`: empty, exit 0.
- `git diff 630fff3ef 304720e22 --stat -- utils test`: only the two test invocation lines
  (`test/gh280-jog-marathon-adapter.sh`, `test/jog-queue.sh`, 1+/1− each). So `utils/py/jog_run.py`
  is byte-identical from the fix commit `630fff3ef` (the source of `cli-fixed.json`) through
  `8744fcb2f`, `ff4592c88` and `304720e22`.

**Q1 Fail behavior / exit propagation: holds.**
- `_dry_run_preflight` now returns `(status, summary)` on every path:
  - missing preflight → 2 (`utils/py/jog_run.py:2225`);
  - inbox identity mismatch → 2;
  - inbox with no valid promotion probes → 2;
  - otherwise `proc.returncode`, so already-landed exit 4 is nonzero.
- The loop (`utils/py/jog_run.py:2344-2347`) prints each summary, then sets
  `failed = failed or status != 0`. It never breaks early except at the `--max-tasks` cap.
- `sys.exit(2)` runs only after `conn.close()` and after the loop (`:2350-2351`).
- No path returns 0 after a selected item failed:
  - the empty-queue `return`s exit before any item is evaluated;
  - preparation refusals exit 2 before any item, which is correct because they are not per-item.
- Remaining exception exposure: the `find_issue_doc` / `doc_frontmatter_issue` import came with
  GH-1426 and was not changed here. Its failure mode is a nonzero traceback, not a false 0.

**Q2 Promotion parity: holds.**
- `promotion_probes` (`:1677-1680`) keeps the original's behavior exactly:
  - it lints every legacy probe with `lint_probe(root, p)[0]`;
  - it keeps the valid ones, in order;
  - it falls back to `contract_probes_from_doc` only when none is valid, and returns
    `(valid, None)` otherwise. That is the same as the removed `contract_reason = None` initialization.
- Nothing executes: `contract_probes_from_doc` checks shape only, and `lint_probe` only globs.
- The live call site (`:2451-2452`) and dry-run (`_dry_run_preflight`) both pass the execution
  `target` as root. The arguments are therefore at parity too.
- `helper-final.json` cases 1–3 (legacy wins, real contract fallback, neither source) are consistent
  with this reading.

**Q3 Checkpoint reuse: holds.**
- `validate_checkpoint_options` (`:2206-2215`) re-derives the removed checks:
  - same order: options first, then realpath equality;
  - same messages;
  - `simulate` and `executor` are computed with the same `getattr`/default expressions as
    `jog_run_main`;
  - only `ContractError` is raised, caught at `:2361-2365` and turned into `jog: <msg>` / exit 2,
    still before `JogSupervisorLock.acquire()`.
- `check_publication` uses `self.publication`, which is exactly the removed `pub`. It is called at
  the same point in `finish`, after `save()` and before fetch/merge.
- Dry-run writes no Jog state:
  - `JogCheckpoint.__init__` only computes paths and runs git reads;
  - `begin`, `finish` and `save` are never called;
  - the DB is opened `mode=ro`.
- Every exception from those dry-run calls (`ContractError`, git `CalledProcessError` such as a
  detached-HEAD `symbolic-ref`, `OSError`) is caught at `:2318`.

**Q4 Gate widening: holds.**
- `target_readiness = dry_run and bool(target_root)`. Bare `--dry-run` therefore evaluates
  `(not dry_run or False)` → False and stays exempt. `--simulate` short-circuits both gates.
- A programmatic `Namespace` with no `target_root` or no `dry_run` behaves as before.
- `--executor relay` still skips executor validation. Its only new behavior is under
  target-aware dry-run: `--auto-merge` is now refused, and an invalid `--checkpoint-root` combination
  is now refused. The live run already refuses both "regardless of executor" (`:2276-2282`,
  `:2361`), so the dry-run now predicts the live refusal. That is intended.
- The two test edits are needed: `jog_run_root` and `ra` add `--target-root`, so without them the
  "bare preview unchanged" assertions would have silently become target-readiness cases.

**Q5 Complexity: no unnecessary mechanism.** One cosmetic Nit below. The de-duplication is complete:
the live path has no remaining inline copy of the selector or the checkpoint option checks.

**Q6 Docs at `304720e22`.**
- SKILL claims checked against the code:
  - an empty queue (`:2329-2335`) and `--max-tasks 0` (loop breaks at idx 0, `failed` stays False)
    both exit 0;
  - with `--checkpoint-root`, `--max-tasks 0` is refused by `validate_checkpoint_options`, so
    "without checkpoint mode" is the correct qualifier;
  - "unattended rules even in a terminal" is true: dry-run returns 2 on no probes regardless of tty,
    while the live run passes `interactive=sys.stdin.isatty()` and, attended, reaches the
    `Probes: (none declared)` prompt.
- The SUMMARY round-1 section is accurate:
  - in `relay-system/2026-11-12/gh1443-claude-qa.md`, the round-1 review heading is at line 79 and
    the automation block at lines 168-170, so it was placed above the block;
  - `2e9281542` is the seed packet and `3164c2cab` is the claude turn, and both are present in
    history.
  - I cannot independently observe the driver's exit 4 from retained artifacts; it is consistent
    with this packet's own statement.
- The widened prerequisite row is accurate except for one word (Nit 1).

**Q7 Historical helper script: SUMMARY instruction is correct.** Provenance line 1
(`manual-cli-and-helper`) records `source 48a91063e…` and `helper-controls.py 44ae848c…`.
```
$ git show 48a91063e:TESTS-RESULTS/2026-11-12+GH-1443/helper-controls.py | shasum -a 256
44ae848c075013b142096b7ec00a028fe165413e279d5867fc43ed84cc8ab9ed  -     (pipestatus 0 0)
```
The hash matches.
- The stage's recorded command path is `python3 temp/helper-controls.py`. That path is absent at
  the commit: `git show 48a91063e:temp/helper-controls.py` gives rc=128.
- So the script ran from an untracked temp copy, and the committed TESTS-RESULTS copy at the source
  commit is the matching artifact.
- The current file hashes `53400ae4…`, which matches provenance line 2 (`focused-and-real-fallback`).
- Minor observation: at line 2's `source 8744fcb2f`, the committed copy is still `44ae848c…`. The
  revised script was first committed in `d1a5191e5`, so "source" there means the code under test,
  not the commit that holds the artifact. Harmless, because the SUMMARY points to the current path
  for current evidence.

**Q8 Retained evidence: consistent (producer evidence, not rerun).**
- `provenance.jsonl`, latest hash per artifact: 21/21 OK, exit 0. The script hashed each named file
  with sha256 and compared it to the last record naming it.
- `full-push.json`:
  - `rc 0`, `elapsed_seconds 550.312`;
  - before and after `head` both `ff4592c88b60…`;
  - `bare false`, same origin, `status` empty both times, `identity` rc 1 both times (no local
    identity, unchanged);
  - `cap_seconds 1800`.
- `full-push.log`: `passed: 408 / 408` (line 477) and `pre-push: full gate GREEN in 546s` (line 886).
  No bypass used; line 2 is only the standard bypass hint.
- Focused logs: `gh280-final.log` ends `227 pass, 0 fail`; `jog-queue-final.log` ends `34 passed, 0 failed`.
- Manual controls:
  - `cli-fixed.json`: source `630fff3ef`, 16/16, `all_preserved true`;
  - `helper-final.json`: 8/8, including "mixed queue visits all and refuses" with rc 2 and
    "DB bytes unchanged; no .tick".
- All runtime evidence is on runtime byte-identical to `304720e22` (see the scope probes).

### Findings

- [Nit] `PROJECT/2-WORKING/GH-1443-JOG-READINESS.md:61`: "static dry-run **explicitly** leaves
  primary cleanliness/freshness/recovery unknown". The `primary cleanliness` part is not explicit
  anywhere:
  - the CLI notice (`utils/py/jog_run.py:2322-2323`) names only provider capacity, gate
    environment/services, remote freshness and checkpoint recovery eligibility;
  - the SKILL limits sentence names the same set.

  It is true that dry-run never calls `check_owned`/`_require_jog_primary`, so primary cleanliness is
  in fact unverified. Either drop "explicitly" for that item, or add "primary cleanliness" to the
  SKILL limits sentence. Docs-only; no behavior change requested.
- [Nit] `utils/py/jog_run.py:2312,2321`: two consecutive `if dry_target:` blocks. The notice could
  sit at the end of the first block's `try`/after it, since every refusal there exits. This is
  cosmetic; leave it unless the code is touched again.

No [Blocker] or [Should] survives. STATUS: Approved; NEXT: orchestrator. The PR stays held: this
approval does not authorize merge, deployment or handoff.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
