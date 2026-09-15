---
Goal: Plan QA — GH-623 merge-cleanup resilience (soft edges, fetch retry, resume loop)
Date: 2026-09-14
NEXT: Producer
STATUS: Open
---

# Context

You are the plan reviewer for GH-623. The canonical plan is
`PROJECT/1-INBOX/GH-623-MERGE-CLEANUP-RESILIENCE.md` (committed at HEAD of this worktree).
The issue it implements: HiQS-Labs/XYZ-forge#623 — a /merge-cleanup run where one PR handoff
cascaded "NOT attempted" through collision-adjacent PRs, one DNS failure aborted the rest of
the queue, and the operator had to re-drive the run 4x.

Read the plan doc in full, then verify its claims against the actual code:
- skills/merge-cleanup/scripts/toposort_prs.py  (collision edges -> dep_graph -> `_deps`)
- skills/merge-cleanup/scripts/merge_cleanup.py (`land_prs` blocking, `prepare_landing_clone`, main's pre-queue + post-merge fetches)
- skills/merge-cleanup/scripts/attempt_record.py (reserve/finish, MAX_REPAIRS ceiling)
- skills/merge-cleanup/SKILL.md (Phase 5 dependents bullet, capability table, option list)
- test/gh534_phase_b_tests.py + test/gh534_phase_c_tests.py (fixture + pinned dependents-blocked test + TestParityGuard)
- test/gh436-merge-cleanup.py (toposort ordering tests)

## Operational envelope

Grade against the plan's stated requirements and commensurate complexity. Do NOT demand
unrequested machinery (circuit breakers, speculative frameworks, enterprise fail-safes) — the
plan's non-goals section is deliberate scope, not omission.

## Questions to adjudicate (cite file:line)

1. Grounding: is every code claim in the plan's Problem Statement true of the actual sources?
   Name any wrong line reference or overstated claim.
2. Requirement coverage: does the design satisfy the issue's acceptance bullets
   (hard/soft split, 3x-backoff retry + defer-and-continue, --resume, SKILL.md drive loop +
   Done rule + classifier-retry)? Are the two deliberate non-deferral sites the right call —
   pre-queue fetch exhaustion still refuses (R2-1 stale-verdict guard) and post-merge fetch
   exhaustion still stops (reconciliation is gating)?
3. Pinned guarantees: does the hard/soft split keep
   `test_dependent_of_a_handed_off_pr_is_not_attempted_and_an_independent_pr_proceeds` green
   (it uses an explicit "Depends on #2" annotation)? Does defer-and-continue preserve the E
   guarantee (a PR whose state is unknown is never merged) and the exit-code shape (0/2/3)?
4. Resume safety: can `--resume` as designed ever bypass the two-repair ceiling, given reserve()
   re-checks budget under the lock? Is "unreadable record -> warn and proceed" acceptable when
   reserve() still gates?
5. Blast radius: name any consumer of toposort output or `_deps` the plan missed (note:
   `utils/py/_marathon_plan.py::_deps_of` is a different, unrelated function).
6. Red controls: would each new test in the plan's test scope actually fail on the current
   code? Is the test footprint commensurate with the change?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — changes requested

**Verdict: Block** — the hard/soft split and resume ceiling are sound, but the plan still leaves
two network-failure paths capable of recreating the incident class, and its proposed fixture changes
cannot express two of the promised red controls as written.

### Findings

1. **Block — initial PR discovery still converts a network failure into false success.**
   `toposort_prs.py:16-33` returns `[]` for both a genuine empty queue and any failed/unparseable
   `gh pr list`. `merge_cleanup.py:697-717` then prints "No open PRs", proceeds toward Phase 6, and
   can report completion. The retry-site list in the plan (`GH-623...md:112-117`) omits
   `fetch_open_prs`, so a transient DNS failure at Phase 4 still recreates S1/S4. Cheapest fix:
   preserve the empty-vs-error distinction, retry the Phase 4 list call three times, and make
   exhaustion exit 2 before teardown. Add a red control proving a DNS-flavoured `pr list` failure
   cannot become "No open PRs" or reach Phase 6.

2. **Block — a hung Git network operation never reaches `_transient()` or `_retry()`.**
   The shared `run_git` wrapper has no timeout and catches only `OSError`
   (`scan_clones.py:85-100`), while every planned clone/fetch retry is built on it
   (`merge_cleanup.py:127-147,602-605,729-739`). Matching the words `timed out` in stderr does not
   bound a subprocess that never returns. Cheapest fix: add a bounded timeout only for the network
   Git calls (or a small network-call wrapper), convert `TimeoutExpired` into the same diagnostic
   result shape, and pin retry/exhaustion with a focused mocked timeout test. No broader retry
   framework is warranted.

3. **Fix — the pre-queue refusal conflicts with the existing override and the stated non-goal.**
   The plan says exhaustion "still refuses" and also says `--allow-unready-primary` is unchanged
   (`GH-623...md:91-96`), but current code permits a failed pre-queue fetch when that flag is set
   (`merge_cleanup.py:729-739`). State explicitly whether retry exhaustion remains subject to the
   existing operator override or whether GH-623 intentionally removes that escape hatch; add the
   corresponding test. Default refusal and post-merge stop are otherwise the correct two
   non-deferral choices: the first protects the freshness verdict, and the second gates remote
   merge reconciliation.

4. **Fix — dropping `_deps` changes an observable standalone JSON contract.**
   The in-repo search confirms `land_prs` is the only runtime reader of `_deps`, but
   `toposort_prs.py:198-201` serializes the mutated PR dictionaries under `--json`. Replacing
   `_deps` with two fields therefore changes output consumed outside this repository even if no
   second in-repo reader exists. Cheapest compatible shape: keep `_deps` as the ordered union for
   JSON compatibility, add `_hard_deps`/`_soft_deps`, and make only `land_prs` consult hard edges;
   alternatively declare and test the breaking CLI change.

5. **Fix — the planned GH stub additions are insufficient for the named tests.**
   Today `pr view` failure is one global boolean and one fixed message
   (`gh534_phase_b_tests.py:97-100`), and `files` is hard-coded empty (`:77-82`). `files`
   passthrough plus a single `view_fail_msg` can make a DNS diagnostic, but cannot make only PR A
   fail while PR B lands, nor fail exactly twice and then succeed so the call count is three.
   Specify a per-PR remaining-failures map (with message) or equivalent minimal side effect. That
   one small fixture mechanism covers both network-defer and retry-then-success without a new
   framework.

6. **Fix — correct the grounding citations.** The explicit dependency insertion is
   `toposort_prs.py:75-84`, collision insertion/publication is `:89-121`, and the hard-blocking read
   is `merge_cleanup.py:475-480`, not `:479-484` as claimed in the Problem Statement.

### Answers to the remaining adjudication questions

- The explicit-dependency pin remains valid: the fixture sets `Depends on #2` at
  `gh534_phase_c_tests.py:257-269`, so publishing that edge as hard and reading only
  `_hard_deps` preserves the "NOT attempted" guarantee while soft predecessors proceed.
- Defer-and-continue is safe for E only if every deferred PR is recorded as a failed predecessor,
  is never passed to the ledger gate or `gh pr merge`, and leaves hard dependents blocked. Returning
  3 for any deferred/handoff/park outcome preserves the promised 0/2/3 shape.
- `--resume` cannot mint a third repair: `reserve()` re-reads and counts under `RecordLock`, then
  refuses at `MAX_REPAIRS` (`attempt_record.py:129-143`). Warning and proceeding on an unreadable
  resume pre-check is safe because a later repair still stops in `load()` (`:101-114`); a currently
  mergeable PR needs no repair slot.
- The soft-edge, network-defer, and resume controls would all fail current code for the reasons the
  plan states. Once findings 1, 2, and 5 are covered, the test footprint remains commensurate:
  existing fixture suites, no new runner or abstraction.

Graph evidence was used as a lead at generation `2026-09-15T04:47:51Z` and confirmed against the
worktree sources. The named code/test paths had no recorded coverage gaps; the plan itself was not
present in that graph generation and was read directly. Repository-wide literal search found no
additional `_deps` reader beyond `land_prs`; excluded caches and unrelated parse-partial tests were
not relied upon.

## Author response (round 1 adjudication) — all six findings accepted

1. ACCEPTED (Block): `fetch_open_prs` retry + empty-vs-error at the call site + exit 2 before
   Phase 6 on exhaustion, plus a red control (pr-list-discovery) proving the failure cannot
   print "No open PRs" or reach teardown. Plan §Design/§Tests updated.
2. ACCEPTED (Block): `run_git` gains an additive `timeout` param (default unbounded — no
   existing caller changes behavior); `_net_git()` bounds the clone/fetch/pre-queue/post-merge
   call sites and converts `TimeoutExpired` to the normal failure shape so it reaches the retry
   loop. Focused mocked-timeout test (hung-git-bounded). Plan §R2a/§Design/§Tests updated.
3. ACCEPTED (Fix): plan now states explicitly that `--allow-unready-primary` is preserved
   unchanged after retry exhaustion (no escape hatch added or removed) and an
   allow-unready-preserved test pins it.
4. ACCEPTED (Fix): `_deps` kept as the sorted union for the `--json` contract; `_hard_deps`/
   `_soft_deps` added; only `land_prs` changes what it consults. No breaking CLI change.
5. ACCEPTED (Fix): stub gets a per-PR remaining-failures map with message (bool form kept for
   the existing global-failure test) — one mechanism covers network-defer and retry-then-success.
6. ACCEPTED (Fix): citations corrected (explicit deps toposort_prs.py:75-84, collision
   :89-121, blocking read merge_cleanup.py:475-480).

Plan revised in PROJECT/1-INBOX/GH-623-MERGE-CLEANUP-RESILIENCE.md (see §Execution log round-1
record). Re-review requested on the revised plan.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex re-review — changes requested (round 2)

**Verdict: Block** — all six round-1 findings are substantively resolved, but the same
"a hung call never reaches retry" defect remains on Phase 4 discovery, and two smaller plan/proof
contracts need to be made internally consistent before implementation.

### Findings

1. **Block — Phase 4's `gh pr list` call is still unbounded, so its promised retry can hang
   forever.** The plan correctly bounds Git network calls and notes that `refresh_pr` is already
   bounded through `_gh` (`GH-623...md:126-137`), but `fetch_open_prs` does not use `_gh`:
   it calls `subprocess.run(...)` with no timeout and catches neither `OSError` nor
   `TimeoutExpired` (`toposort_prs.py:16-33`). A hung discovery call therefore never returns an
   error for `_retry()` to classify, recreating finding 2 one phase earlier. Cheapest fix: give
   `fetch_open_prs` a bounded subprocess timeout and convert `OSError`/`TimeoutExpired` into the
   same explicit error result used for non-zero/invalid output. Extend `pr-list-discovery` (or add
   one focused case) so a mocked `TimeoutExpired` proves Phase 4 exits 2 before Phase 6 rather than
   hanging or reporting an empty queue. The test must also assert the subprocess was invoked with
   a finite timeout; merely injecting the exception proves handling, not boundedness.

2. **Fix — the affected-file inventory omits the production file that R2a changes.** Scope says
   "Three files" and lists `toposort_prs.py`, `merge_cleanup.py`, and `SKILL.md`
   (`GH-623...md:59-70`), but the design adds `timeout` to `scan_clones.py::run_git`
   (`:130-135`; current definition `scan_clones.py:85-100`). The ordered implementation list then
   misleadingly places the `run_git` change under the `merge_cleanup.py` step (`:193-195`). Add
   `scan_clones.py` to the production scope and give its additive-default contract an explicit
   assertion: an existing non-network call remains unbounded by default, while `_net_git` forwards
   a finite timeout. This matters because `run_git` has many scan and ledger consumers; the default
   is the compatibility shield the plan relies on.

3. **Fix — the retry count and delay schedule contradict each other.** Requirements and the
   retry-success test specify **three total attempts** (fail twice, succeed on the third;
   `GH-623...md:76-80,165-166`), while Design says "up to 3 attempts with 2s/4s/8s backoff"
   (`:126-128`). Three total attempts have only two inter-attempt sleeps (2s, 4s); a third 8s sleep
   implies a fourth call or a pointless sleep after exhaustion. State one exact contract and pin
   call count plus sleep sequence. The existing proposed three-call test supports the lean reading:
   3 total calls, sleeps `[2, 4]`, then defer/stop.

### Re-adjudication of the requested questions

- **Round-1 closure:** hard/soft publication while retaining `_deps` as the JSON union closes the
  compatibility concern; the existing explicit `Depends on #2` pin at
  `gh534_phase_c_tests.py:257-273` remains hard-blocked. `land_prs` is the only in-repo runtime
  reader of `_deps`; `toposort_prs.py:198-201` remains the observable serializer.
- **Deferral and E:** deferring a transiently unreadable PR before the ledger gate/merge, recording
  it in the predecessor outcome map, continuing independent PRs, and returning 3 preserves the
  rule that unknown state is never merged. Default pre-queue refusal (subject to the existing
  `--allow-unready-primary` override) and post-merge stop are the correct two non-deferral sites.
- **Resume ceiling:** `reserve()` re-loads and counts under `RecordLock` before appending
  (`attempt_record.py:129-143`), so `--resume` cannot mint repair three. An unreadable resume
  pre-check may warn and proceed because any repair still reaches the fail-closed `load()` path
  (`:101-114`); a currently clean/mergeable PR consumes no repair slot.
- **Red controls:** soft-edge, network-defer, pr-list non-zero failure, and resume all fail current
  code as stated. The hung-Git control will fail current code with propagated `TimeoutExpired`, but
  must assert finite timeout forwarding to prove the actual bound. Add the equivalent Phase 4
  hung-discovery control from finding 1. With those assertions, the footprint remains commensurate
  and needs no broader framework.

Graph discovery used the `Users-noelsaw-Documents-GH-Repos-XYZ-forge` index at generation
`2026-09-15T04:47:51Z`; all eight named source/test paths reported metadata-matched coverage with
no recorded issue. `trace_path` was unavailable under the no-approval policy, so graph search was
confirmed with direct, bounded source reads and repository literal search. The only scope gap under
`skills/merge-cleanup` was excluded `__pycache__`; unrelated parse-partial test files were not used.

## Author response (round 2 adjudication) — all three findings accepted

1. ACCEPTED (Block): `fetch_open_prs` gains a finite subprocess timeout (180s, matching `_gh`)
   and `OSError`/`TimeoutExpired` convert to a raised `FetchError` — never a silent `[]`. The
   pr-list-discovery test gains a mocked-TimeoutExpired case whose mock asserts the subprocess
   was invoked with a finite timeout (boundedness, not just handling). Plan §Scope/§R2a/§Design.
2. ACCEPTED (Fix): `scan_clones.py` added to the production scope (4 production files); an
   explicit companion assertion pins that `run_git` without the timeout argument stays
   unbounded by default.
3. ACCEPTED (Fix): retry contract pinned to exactly 3 total calls with inter-attempt sleeps
   [2, 4]; retry-then-success asserts the call count and sleep sequence.

Plan revised (see §Execution log round-2 record). Final re-review requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex final re-review — changes requested (round 3)

**Verdict: Block** — the three round-2 findings are closed, and the hard/soft, retry, timeout,
and compatibility contracts are now coherent. One resume ordering bug would strand a successfully
repaired PR, however, and three smaller scope/proof gaps should be resolved with it.

### Findings

1. **Block — the pre-refresh `--resume` skip can discard the successful second repair.** The plan
   skips any record with two finished repairs *before* live refresh
   (`GH-623-MERGE-CLEANUP-RESILIENCE.md:152-155`) and directs the caller to re-run with
   `--resume --execute` after the repair ladder (`:156-160`). But attempts record outcomes such as
   `resolved`/`handoff`/`failed` (`attempt_record.py:140-149`), and the second allowed caller repair
   can legitimately finish `resolved` after pushing a now-mergeable head. That record has two
   finished attempts, so the prescribed resume run would label the PR “previously parked” without
   even calling the authoritative `refresh_pr` (`merge_cleanup.py:481-498`) and would never land
   it. This does not bypass the ceiling; it prevents completion after using it correctly. Cheapest
   fix: perform the live refresh first and let an OPEN/MERGEABLE PR proceed without reserving a
   repair; apply the exhausted-record skip only when another repair would actually be needed (and
   retain `reserve()` as the under-lock authority at `attempt_record.py:129-143`). Add the paired
   pin: two finished unsuccessful repairs + still conflicting skips, while two finished repairs
   with the last `resolved` + live MERGEABLE proceeds and lands. The current resume test
   (`GH-623...md:192-194`) covers only the first half.

2. **Fix — the promised Phase 4 red control still lacks a concrete failure fixture.** The only
   planned gh-stub additions are `files` passthrough and the per-PR `view_fail` map
   (`GH-623...md:166-171`), while the existing `pr list` branch always succeeds
   (`gh534_phase_b_tests.py:91-96`). Yet `pr-list-discovery` says the real `gh pr list` fails with
   a DNS diagnostic and, on current code, proves the false “No open PRs” path
   (`GH-623...md:181-186,201-205`). Specify a minimal `list_fail`/remaining-failures stub state (or
   an equivalently explicit direct test of `fetch_open_prs` plus the orchestration call site).
   Mocking only `merge_cleanup.fetch_open_prs` to raise would not prove the current
   `toposort_prs.py:24-33` empty-on-error defect. The standalone `toposort_prs.py` main is also a
   caller (`toposort_prs.py:185-201`); since `fetch_open_prs` will now raise `FetchError`, state that
   main catches it, prints the diagnostic, and exits non-zero rather than leaking a traceback.

3. **Fix — `test/gh436-merge-cleanup.py` is in the behavioral blast radius, not merely a gate.**
   Its Phase 5 harness patches `merge_cleanup.run_git` with a two-argument `fake_git(cwd, args)`
   (`test/gh436-merge-cleanup.py:409-418,428`). `_net_git` forwarding `timeout=` through that patch
   will raise `TypeError`, so the file needs the additive timeout-compatible fake signature (and
   should remain in the focused run). Add it to the affected-test inventory; the current scope
   lists only the two gh534 files (`GH-623...md:73-74`) even though the ordered gate names gh436
   later (`:217-219`).

4. **Fix — narrow or fulfill the “every network call is bounded” claim.** R2a says every network
   call is bounded (`GH-623...md:87-94`), but the enumerated `_net_git` sites stop at the initial
   landing clone/fetches and the pre/post-merge fetches (`:144-151`). Existing B1 paths still
   include an origin clone (`merge_cleanup.py:157-164`) and a remote push (`:182-191`) through
   unbounded `run_git`. The least-scope resolution is to say “every GH-623 retry-site network call”
   and explicitly leave the B1 validation/push behavior out of scope; alternatively route those
   calls through the finite-time wrapper and pin their stop semantics. Do not imply repository-wide
   boundedness while preserving `run_git`'s unbounded default for compatibility.

### Final adjudication

- The corrected explicit/collision citations are accurate. Publishing `_hard_deps` and
  `_soft_deps` while retaining `_deps` as their sorted JSON union preserves the standalone output
  shape and the explicit `Depends on #2` guarantee at `gh534_phase_c_tests.py:257-273`.
- Three total calls with sleeps `[2, 4]`, finite Phase 4 and Git retry-site timeouts, transient-only
  retry, per-PR defer-and-continue, default pre-queue refusal with the existing override, and
  post-merge stop satisfy the issue's network and E/exit-code requirements as revised.
- `--resume` still cannot mint repair three because `reserve()` re-loads and counts under
  `RecordLock` (`attempt_record.py:129-143`). Warning on an unreadable pre-check remains safe because
  any actual repair reaches that fail-closed load. Finding 1 is a liveness/correctness defect, not a
  ceiling bypass.
- The soft-edge, network-defer, retry-success, timeout, and existing resume red controls are
  commensurate and would fail current code. Add the successful-final-repair resume pin and make the
  Phase 4 fixture/proof explicit; no new framework is needed.

Graph discovery used `Users-noelsaw-Documents-GH-Repos-XYZ-forge` generation
`2026-09-15T04:47:51Z`. All named code/test paths were metadata-matched with no recorded coverage
gap; the revised plan was missing from that generation and was read directly. `trace_path` was
unavailable under the no-approval policy, so caller/blast-radius claims were confirmed with bounded
source reads and literal search. The only recorded gap under `skills/merge-cleanup` was excluded
`__pycache__`; unrelated parse-partial test files were not used.

## Log

### Codex round 3 handoff

VERDICT: FAIL

Basis: The revised plan would skip a successfully repaired, now-mergeable PR before live refresh;
the Phase 4 failure fixture, gh436 timeout-compatible mock, and bounded-network scope also need the
specific corrections recorded above.
