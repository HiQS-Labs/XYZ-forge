---
gh_issue: 851
related_issues: [852]
source: https://github.com/HiQS-Labs/XYZ-forge/issues/851
title: "merge-cleanup landing resilience: stale re-gate after a B1 push (#851), unbounded network calls, merge-call recovery, --reconcile-pr SHA, hosted-wait default (#852, #854 D5)"
status: Working — admitted 2026-09-27 (accepted-start on both rows); implementing F1–F5
created: 2026-09-27
updated: 2026-09-27
owner: operator (via /start-task, #854 direct-path item 1)
branch: fix/gh851-852-merge-cleanup-network
doc_type: fix
non_goals:
  - New suites, registry entries or test files (AGENTS.md, No new tests). Existing suites are edited only if a behaviour they pin changes.
  - Any change to releases_app.py. Its `gh issue view` already has `timeout=30`; see R3.
  - Making Python timeouts count wall time across a machine sleep. That is the #854 Day 0 host rule (caffeinate or an always-on host), not code.
  - A retry or defer policy for a stalled call beyond the existing GH-623 transient machinery.
related:
  - "#849 — the merge batch where every finding was hit"
  - "#854 — stabilization window; this PR is its first direct-path item; D5 decided the 5400 s default"
  - "#623 — the existing network-resilience machinery (_net_git, _retry_call) this extends"
  - "#674 / #743 — hosted-run lookup and receipts; the --reconcile-pr fix completes #674 for that mode"
  - "#736 — the mergeable poll this reuses"
goal: >
  An unattended merge-cleanup run never hangs on a dead network call and never stops on a stale answer.
  It treats a PR that GitHub has merged as merged, and in --reconcile-pr mode it waits for the right hosted run.
---

# GH-851 / GH-852 — merge-cleanup landing resilience

## Status

| What was just completed | What's next |
|---|---|
| Admitted (`--accepted-start` on #851 and #852) and moved to `2-WORKING`. Plan QA had closed by operator-directed adjudication after round 2 (see *Plan QA record*). | Implement F1–F5, witnesses, focused suites, final Codex QA, then the full gate and a ready PR. |

## Issues

| Issue | Scope in this PR | Rating (pri/sev/appeal/effort) |
|---|---|---|
| [#851](https://github.com/HiQS-Labs/XYZ-forge/issues/851) | F4: the re-gate after a B1 push | `55/35/50/85` |
| [#852](https://github.com/HiQS-Labs/XYZ-forge/issues/852) | F1 bounded network calls, F2 merge-call recovery, F3 `--reconcile-pr` SHA | `60/45/50/65` |
| #854 D5 (operator decision, no issue of its own) | F5: the hosted-wait default goes from 1800 to 5400 | — |

**Ratings, 2026-09-27.**
- **#851, severity 35:** the run stops safely, with no data risk. Each B1-repaired PR costs one `--resume` cycle, and under ledger churn it helped park #803.
- **#851, priority 55:** it fired on every B1 repair in #849: #806 twice, #810, #827 and #846.
- **#852, severity 45:** a stall hangs an unattended run with no bound. A killed merge call skipped every post-merge step (#810). `--reconcile-pr` would have raced the hosted writer if `wave_reconcile.py`'s own in-flight guard had not refused (exit 8). There was no data loss.
- **#852, priority 60:** it is #854's first direct-path item and blocks unattended landings.
- **Appeal 50:** neutral.
- **Effort:** 85 for #851 (one poll); 65 for #852 (six call sites, two control-flow changes).
- **Recurrence (14 days):** it is the same class as #623 (network), #674 (hosted lookup) and #736 (mergeable poll), all fixed. These are new instances of one class, gate machinery that is brittle to its own environment, and all were found in the one #849 batch. The trend is unknown beyond that.

## Recon (base `030ab5ba`)

- **R1. Existing bounds.**
  - `_gh` (`merge_cleanup.py:70`) defaults to `timeout=180`; `gh pr merge` gets 600 (`:161`); `wait_for_hosted_reconcile` uses 60 (`:444`).
  - `_net_git` (`:106`, GH-623) bounds git at the retry sites at 180 s: the landing clone and fetches (`:289`, `:294`, `:298`) and the pre-merge refresh fetches (`:1006` post-merge, `:1200` Phase 5 entry).
- **R2. Unbounded network git calls.** These are plain `run_git` calls with no timeout:
  - `merge_cleanup.py:316`: `clone` in `validate_head_in_second_clone`. This is the #852 incident: `verify-760ba1ff` sat at 0% CPU for 36+ min on an ESTABLISHED socket.
  - `:343`: `push` in `push_resolved_head`.
  - `:550`: `fetch` in `run_post_merge_reconcile`.
  - `:601` and `:605`: `push` and `fetch` in `commit_and_push_phase5_writes`. The push runs the pre-push hook.
  - `scan_clones.py:437`: `fetch` in the Phase-3 provenance check.
  - `:320` fetches from a local path, not the network, so it is out of scope.
- **R3. Why the bounded calls also hung.**
  - On macOS, Python's `time.monotonic()` is `mach_absolute_time()`, which stops while the machine sleeps (checked with `time.get_clock_info('monotonic')`). `subprocess.run(timeout=…)` uses it.
  - Every #849 hang happened between 00:00 and 03:40 PT, while the machine was sleeping and waking 4–10 times an hour (`pmset -g log`). Those hangs were: the `gh issue view` inside the gate (78 min wall time against `timeout=30`), `gh issue view #216`, and the killed `gh pr merge`.
  - So a code bound limits awake time only. The wall-clock fix is #854's Day 0 host rule, and this PR does not try to replace it.
  - A second layer still helps: git's own `http.lowSpeedLimit` / `http.lowSpeedTime` makes libcurl abort a transfer that is stalled after a wake, instead of waiting on a dead socket. #849 used these as environment variables, and they turned the later stalls into fast, retryable failures (`curl 28 … Operation too slow`).
- **R4. Merge-call failure.** `execute_pr_merge` (`:161-164`) returns False on any non-zero `gh pr merge`, without re-querying. In #810, GitHub merged (`ad923412`) and deleted the branch, then `gh` hung and was killed. The run logged `Failed to merge` and stopped before the hosted wait, fast-forward, emit and commit. The zero-exit path already re-queries (#510, `:167-173`).
- **R5. `--reconcile-pr`.** `main` (`:1112-1115`) calls `run_post_merge_reconcile` with no `pr_head`, and that function uses the primary's `HEAD` as `merged_head` (`:541`). In the #810 recovery it looked for `85a60f2c`, not `4caf3e1d` / `ad923412`. It missed the in-progress run 36313206686, the lookup then hit a connection reset, and it fell back to the local writer. `wave_reconcile.py`'s in-flight guard refused (exit 8).
- **R6. #851.**
  - After `push_resolved_head` succeeds, `land_prs` (`:970-974`) re-reads once through `_await_mergeable`.
  - `_await_mergeable` polls only while `mergeable` is neither MERGEABLE nor CONFLICTING (`:797`). Straight after a push, GitHub still reports the old head's `CONFLICTING`, so the poll exits and the run stops (exit 2).
  - In #849 this happened every time (#806 ×2, #810, #827, #846). Each PR was MERGEABLE at the pushed head within a minute.
- **R7. The hosted-wait default** is 1800 (`merge_cleanup.py:431`; `SKILL.md:153` says "default 1800"). No suite pins it: `gh674` sets `HOSTED_WAIT_ENV` explicitly, to 10 and 0. PR-closed full-registry runs took 52.8–65.9 min (#854).
- **R8. Suites that read this code:**
  - `test/gh436-merge-cleanup.sh`, which runs `gh436-merge-cleanup.py` and `gh534_phase_{a,b,c}_tests.py`. Phase C has `TestGh623Resilience` and the `TestParityGuard` over `SKILL.md`.
  - `test/gh674-merge-cleanup-hosted-lookup.sh`.
  - `test/gh645-merge-cleanup-xyz-tools.sh`.
- **R9. Routing.** `merge_cleanup.py` is unmapped, and `skills/*/merge-cleanup/SKILL.md` is in `full_required` (GH-836 D1). So this PR is tier 3 both at push and at the hosted reconcile.

## Plan (extends GH-623's `_net_git` / `_retry_call` and GH-736's poll; no new module or helper family)

1. **F5, D5 default.**
   - Change: `wait_for_hosted_reconcile` defaults to 5400 (`:431`). `SKILL.md:153` says "default 5400", and the same sentence is corrected (plan QA nit): the lookup does not pass `--branch`/`--commit`; it lists runs and matches the PR head or merge commit (`:436-439`).
   - Check: the witness records the default `_seconds_from_env` receives, 1800 at base and 5400 at head. The `TestParityGuard` in gh436 stays green.
2. **F1, bounded network git.** This changes the environment, not the argv, so every existing `run_git` stub keeps matching.
   - **Transfer-stall abort.** Call `os.environ.setdefault("GIT_HTTP_LOW_SPEED_LIMIT", "1000")` and `os.environ.setdefault("GIT_HTTP_LOW_SPEED_TIME", "120")` at the top of `merge_cleanup.main()` and `scan_clones.main()`.
     - Every child `git` inherits them, including git run by the pre-push hook and by `releases_app.py`. These are the exact values #849 ran with.
     - `setdefault` keeps an operator's own values.
     - Passing `-c` arguments instead was rejected: it would change the argv that existing stubs match exactly (`test/gh534_phase_c_tests.py:756,816,839`; `test/gh436-merge-cleanup.py:413-421`, from plan QA C3).
   - **Time bound.** Route these through `_net_git`:
     - the clone at `:316`, the push at `:343`, the fetch at `:550` and the fetch at `:605`: default 180 s;
     - the push at `:601`: 3600 s, because it runs the pre-push hook, which can run a gate.

     Every `merge_cleanup.run_git` stub already accepts `timeout` (`**kw`, or `timeout=None`).
   - **`scan_clones.py:437`** is bounded too (plan QA D1). It passes `timeout=180` through `run_git`'s existing parameter, which already converts expiry to rc 124 (`scan_clones.py:86-110`). The failure goes to the existing failed-query/preserve result. The environment abort is a second layer only: it covers stalled HTTP transfers, not a subprocess deadline. **Existing stubs to keep truthful (a signature-only edit):** the three `flaky(cwd, args)` doubles at `test/gh534_phase_a_tests.py:505,632` and `test/gh436-merge-cleanup.py:308` accept `**kw` and forward it to the real `run_git`. Their fault predicates are unchanged.
   - **C1: classify the new failure as transient.** Add `operation too slow` (libcurl's low-speed abort) and `connection reset` to `TRANSIENT_RE` (`:94-97`). Both texts were observed in #849:
     - `error: RPC failed; curl 28 Operation too slow. Less than 1000 bytes/sec transferred the last 120 seconds`;
     - `error: RPC failed; curl 56 Recv failure: Connection reset by peer`.

     So GH-623's three attempts and defer apply to them. Nothing else is added.
   - A timeout keeps today's failure shape: rc 124, "timed out", which `TRANSIENT_RE` already matches.
   - **Witness (C2), manual, in `TESTS-RESULTS/`:**
     1. A stub `git` first on `PATH` sleeps forever for `clone` only; every other subcommand passes through to the real git. Call `validate_head_in_second_clone` with `merge_cleanup.run_git` wrapped as `def wrap(cwd, args, timeout=None, **kw): return real(cwd, args, timeout=None if timeout is None else min(timeout, 2), **kw)`. This keeps base's unbounded `None` (D2), and the shortened bound still reaches the real `run_git` call. The same recipe runs unchanged at base and at head.
        - Base: still blocked when a 10 s outer watchdog fires.
        - Head: returns `(False, "second clone failed: timed out …")` inside it.
     2. Record the `timeout` each of the six sites passes: the five in `merge_cleanup` and `scan_clones.py:437`. None at base; 180, 180, 180, 3600, 180 and 180 at head.
     2a. A stalled `fetch` at `scan_clones.py:437`, with the bound shortened through the same wrapper and **no** `GIT_HTTP_LOW_SPEED_*` in the environment, returns the existing failed-query result at head. At base it is still blocked at the outer watchdog.
     3. After `main()` has set up, the environment holds `GIT_HTTP_LOW_SPEED_LIMIT=1000` and `GIT_HTTP_LOW_SPEED_TIME=120`, and an operator's own value is kept.
     4. `_transient()` is True for both observed texts at head (False at base). It stays False for `remote: Repository not found.` and for `fatal: Authentication failed`.
     - Every witness log must be non-empty. The logs are committed with `provenance.jsonl`.
3. **F2, merge-call recovery.**
   - Change: in `execute_pr_merge`, on a non-zero exit, call `refresh_pr` once. If it reads `MERGED` with a non-empty `mergeCommit.oid` (the success branch's own test), log a warning (`gh pr merge exited N but the PR reads MERGED as <sha> — continuing`) and return True, so the existing post-merge sequence runs.
   - Otherwise keep today's `Failed to merge` return False.
   - Check (witness): stub `_gh` so `pr merge` returns rc 1, and `pr view` returns `MERGED` plus a merge commit. Base returns False; head returns True with the warning. Control: `pr view` returns `OPEN`, so head still returns False.
4. **F3, `--reconcile-pr` SHA.**
   - Change: in `main`, `refresh_pr_with_retry(args.reconcile_pr)` first.
     - A refresh error stops with exit 2, which fails closed.
     - A PR that is not `MERGED` also stops with exit 2: "not merged — nothing to reconcile".
   - Otherwise pass `pr_head=headRefOid`, and a new optional `merged_head=mergeCommit.oid` argument to `run_post_merge_reconcile`. That argument replaces the `HEAD` lookup (`:538-541`) when given; the Phase-5 caller is unchanged.
   - Check (witness): stub `gh`, where `pr view` gives head H and merge M, and `run list` has a run on H. Base logs `No hosted wave-reconcile run listed yet for <primary HEAD>`; head waits on the run for H.
   - **Safety witnesses (plan QA D2, carried from round 1):**
     - An `OPEN` PR returns 2 with **zero** `run_post_merge_reconcile` calls.
     - A `gh pr view` error returns 2 with zero calls.
     - With an active hosted run on H and the wait exhausted (shortened `MERGE_CLEANUP_HOSTED_WAIT_S`), the result is `active_timeout`, and `run_local_wave_reconcile` is never called.
     - Red control: a deliberate local-writer call while the run on H is active must turn that witness red.
   - **Existing tests to keep truthful (C3).** These edit what the tests inject; they add no test case.
     - `test/gh436-merge-cleanup.py:352-363` (`_run_main`): stub `refresh_pr_with_retry` to return a `MERGED` PR 42 with head H and merge M. The ready-primary test (`:374-379`) then also asserts that `run_post_merge_reconcile` got `pr_head=H` and `merged_head=M`.
     - `test/gh534_phase_b_tests.py:522-525` (`test_reconcile_pr_failure_propagates`): give PR 7 a `MERGED` state, so rc 2 still comes from the reconciliation failure and not from the new refusal. A red control checks this: making `main` ignore `run_post_merge_reconcile`'s result must turn it red.
5. **F4, #851.**
   - Change: after `push_resolved_head` succeeds, poll `refresh_pr_with_retry` until `headRefOid == b1["commit"]`. Use the same budget as `MERGEABLE_POLL_ATTEMPTS` × `MERGEABLE_POLL_S`, then go through `_await_mergeable` as today. It is a small loop in `land_prs`, beside `_await_mergeable`, not a new abstraction.
   - If the head never arrives within the budget, stop as today, and the message names the head GitHub still reports.
   - Check (witness): stub `refresh_pr_with_retry` to return the old head plus CONFLICTING once, then the new head plus UNKNOWN, then MERGEABLE. Base stops with `after resolution the PR reads CONFLICTING`; head proceeds to the landing clone.
6. **Evidence and diagnosis.** Any unexpected red during execution is diagnosed with `/debug-mantra`: ground truth first, and no fix before the root cause is stated.
   - The witness script goes in `TESTS-RESULTS/2026-09-27+GH-851/witness.py.txt`: one script run against a base checkout and a head checkout, with logs and `provenance.jsonl`.
   - Existing suites, run focused once: `gh436`, `gh674`, `gh645`.
   - The full gate runs once, through the pre-push hook on the final commit, from a disposable full clone, under `caffeinate -i`.
7. **Docs.**
   - Update the `emit_pr_merged` docstring (`merge_cleanup.py:365-371`, plan QA nit). Under F2 a merge is also witnessed by a `MERGED` re-query after a non-zero merge call. Under F3, `--reconcile-pr` now verifies merge state; it still does not emit.
   - `SKILL.md`: the F5 default, plus one sentence under Phase 5 on F2 and F4.
   - `CHANGELOG.md`: one entry.
   - Close #851/#852 at merge through `Closes` lines.

## Risks and rollback

- **The `GIT_HTTP_LOW_SPEED_*` settings can abort a live HTTP transfer.** A live transfer that stays below 1,000 bytes/s for 120 s is aborted along with a stalled one. The retry sites treat that as transient (C1) and retry it; #849 ran with these values, and the later runs were clean.
- **F2 hides a real merge failure.** It returns True only when GitHub itself reports `MERGED` with a merge commit, which is the same evidence the zero-exit path already requires.
- **F3 refuses a PR it used to "reconcile".** Before, `--reconcile-pr` on an unmerged PR ran the local writer against a merge that did not exist. Refusing is the fail-closed reading of #674.
- **Rollback:** revert the squash. There is no state or format change. Reverting the code cannot undo PRs that were already merged with it.

## Plan QA record

- Thread: `relay-system/2026-09-27/gh851-852-plan-review.md`. Reviewer Codex (`relay-xyz --review-once`, `ALLOW_PATHS=""`).
- **Round 1: FAIL.**
  - C1: the low-speed diagnostic was not classified as transient.
  - C2: the witness patched a default already captured at definition time.
  - C3: existing stubs and tests had to be named.
  - Recon R1–R9, F2–F5, the ratings and the rollback were Pass. All three findings were implemented; for C3, `-c` arguments were replaced by environment settings.
- **Round 2: FAIL.**
  - D1: keep a time bound on `scan_clones.py:437`.
  - D2: the witness wrapper's `None` handling, and the F3 safety witnesses.
  - Two nits: *Risks* wording, and a stale docstring.
  - C1, most of C3, F2, F4, F5 and the scope were Pass.
- **Final adjudication (2026-09-27, operator-directed, Producer):** D1, D2 and both nits are **accepted in full** and written above.
  - Each is a correction to the plan or its evidence that Codex backed with a probe. None expands production behaviour, adds a helper, or adds a test. D1 adds only a `timeout` that `run_git` already supports, plus signature-only stub edits.
  - The operator directed closing the loop without a round 3. So the thread is **Closed**, not Approved, and there is no Codex attestation for the plan.
  - Final Codex QA on the implementation, its evidence and the full gate still applies before the PR is ready (start-task Step 8).
