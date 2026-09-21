---
gh_issue: 740
source: https://github.com/HiQS-Labs/XYZ-forge/issues/740
title: "GH-740 + GH-741: hosted reconcile lane — land receipts before the race, recompute transitions on rejection; report the failing step's real error"
status: In progress
created: 2026-09-21
updated: 2026-09-21
owner: Claude Code (start-task, one group: #740 + #741)
doc_type: bugfix
complexity: 3
risk: 2
effort: 3
phases: 1
rgt_note: "both issues are the same seam — the last two steps of .github/workflows/wave-reconcile.yml"
related:
  - GH-741-HOSTED-LANE-REPORT-ATTRIBUTION.md
  - "#591 umbrella (the post-merge reconciler actually lands) — this group closes two of its open classes"
  - "#674 — the operator-side half of the same race (merge-cleanup's local fallback); not changed here"
  - "#732 D.2 — the lane's success-rate measurement; exit condition 10 consecutive green runs"
non_goals:
  - GitHub merge queue / branch protection (#571 owns the research); the lane keeps `contents: write` on an unprotected branch
  - Splitting the workflow into two jobs (qualify / land) — same effect is reached inside the one step by pushing receipts first
  - The hosted qualification suite going red on the runner (8 of the 27 red runs since 09-17, `Full-suite qualification failed`) — a different class, tracked on #591/#293, untouched here
  - Any change to what the bot may commit (the declared-artifact allowlist moves verbatim; it is not widened)
  - Rebasing or force-pushing `releases.db` bytes
goal: >
  A merge landing during a hosted reconcile run costs at most one recompute of this run's ledger
  transitions, bounded to minutes because the retry can never qualify anything — never the
  ~70-minute qualification — and when a run is red, the one labelled attention issue names the
  step that failed and its real error, not a unit test's expected output.
---

# GH-740 + GH-741 — hosted reconcile lane: publish survives a concurrent landing; the lane report tells the truth

Issues: [#740](https://github.com/HiQS-Labs/XYZ-forge/issues/740) (push race),
[#741](https://github.com/HiQS-Labs/XYZ-forge/issues/741) (report attribution). Umbrella: #591.
Radar run 4 target `RADAR-class-hosted-reconcile-lane` (#293). Base: `origin/development @ b6bb8aab`.
Clone: `XYZ-forge-gh740-741-hosted-lane`, branch `fix/gh740-741-hosted-lane-push-and-report`.

## Status

| What was just completed | What's next |
|---|---|
| **Implemented** (`87d6051c` report attribution + gh684; `c31921c9` `--only-receipted` + gh421; `fa5facd0` publish script, gh740 fixture suite, workflow wiring, gh421 pin move). Plan QA: relay `gh740-741-plan-qa` R1–R3 (F1–F6, capped/Escalated), `-delta` R1–R2 (F6a; R2 graded an unrevised plan — Producer error, disclosed), `-delta2` **Approved**. Focused suites green: gh684 10/10, gh421 36/36, gh740 7/7, ci-workflow 0 failed. | Full qualifying gate once in a disposable clone (evidence → `TESTS-RESULTS/2026-09-21+GH-740/`); final Codex relay QA on the diff; PR against `development`. Hosted proof is post-merge: the first raced run exercises the recovery. |

## Observed problem (both issues, one seam)

The lane is one ~70-minute job. Its last two steps are `Commit declared artifacts and push` (inline
Python: allowlist → `git add` → commit → **one plain `git push origin HEAD:development`**,
`wave-reconcile.yml:68-103`) and `Report hosted lane` (`hosted_lane_report.py`, `if: always()`).

- **#740.** When any merge lands on `development` during the run, the push is rejected
  (`! [rejected] HEAD -> development (fetch first)`), the job is red, and *everything* the run
  produced is discarded — including the qualification receipts under
  `TESTS-RESULTS/<date>+GH-591/wave-<tested>/`. The next run cannot reuse them:
  `committed_qualifications()` reads `git ls-tree HEAD` (`wave_reconcile.py:511-528`) and
  `qualification_receipt_matches()` (`:475-508`) requires the receipt on HEAD with `tested` an
  ancestor of HEAD. So the ~70-minute `validate.sh --sequential` runs again, and races again.
  `concurrency: group: wave-reconcile` (`:12-17`) serialises runs, not merges. Observed 3× in five
  days (runs 35372725722, 35375197135 on 09-18; 35623940059 on 09-21 — #733 landing during #731's run).
- **#741.** `summarize()` returns `errors[-1]` over every line of the tee'd reconcile log
  (`hosted_lane_report.py:52-56`). On a `--qualify` run that log contains the full test suite's
  output, and `test/gh421-auto-wave-reconcile.sh`'s unit tests deliberately drive
  `wave_reconcile.py:1210/:1229` through their expected `wave-reconcile: ERROR — …` lines. For run
  35623940059 the reconcile step was **green**; the push step failed; #735 reported
  `Malformed merged-PR recovery response: invalid merged_at timestamp`. The step that failed is not
  tee'd at all, so its cause is invisible to the report.

## Requirements

| Issue | Requirement | Acceptance (falsifiable) |
|---|---|---|
| #740 | A landing that races the run never costs the qualification again | Fixture: remote advances after the reconcile output exists and before the push; the receipts-only commit lands on the racer's head (no rebase), transitions land after exactly one recompute; `git log origin/development` = racer → receipts → transitions; the racer's own ledger line is still in `releases.sql` on the remote; the real consumer `qualification_receipt_matches()` returns True for the run's landing against the published receipt (False for a corrupted copy — control) |
| #740 | The retry is bounded in wall time **and** keeps the original run's lifecycle semantics | The retry re-runs the reconcile step's **own argv** plus `--only-receipted --skip-pull` **plus `--pr <n…>` / `--commit <sha…>` for every landing named in the receipts this run just published** (F6: once `R` is on HEAD, `unreconciled_prs()` no longer lists those PRs — `wave_reconcile.py:1223-1224` — and `catch_up_prs()` skips OPEN issues — `:1254-1256` — so a recovered PR that only *references* an open issue would otherwise drop out and lose its `record_merge_evidence()` write, `:2133-2155`; naming them explicitly restores the original iteration list without replaying historical receipts). `--catch-up` still enumerates the rest and `issue_owners` is still built over every merged closer (`:2015-2023`), but landings without a committed, matching receipt are **deferred** (logged, left to their own queued run) instead of qualified — so the suite is unreachable in the retry. gh421 replay of the #90/#42 two-closer input under `--only-receipted` with #42 receipted and #90 not: `qualify_landings` never called, #90 deferred, #42 owns the doc (`updated: 2026-09-08`, never `-07`); variant with both receipted → same owner; an **explicit** `--pr` item without a receipt → die (fail closed, GH-684 semantics). gh421 replay of the recovery fixture's `References #421` shape (PR #5, #421 OPEN): scheduled `--catch-up --gate --qualify`, receipt for #5 committed, then the retry argv → `record_merge_evidence` runs for #5 (active doc carries its merge evidence), #421 stays OPEN, `qualify_landings` not called. F6a: the publisher's argv builder, fed original `--pr 42 --catch-up --gate --qualify` and receipts for #5/#6, produces one `--pr 42 5 6` group that the **production parser** parses to all three IDs (red control: the naive repeated-option form parses to `['5']`); an original already-receipted `--pr 42` referencing an OPEN issue therefore keeps its merge-evidence write too. `timeout-minutes: 120` unchanged |
| #740 | A second race on the same run, or a race on a run that produced no receipts, fails **loudly, once**, naming the racing head; receipts are never lost | Fixture: remote advances again between the receipts push and the transitions push → exit 1, stderr has `hosted-lane-publish: ERROR — …` naming `origin/development` and its SHA; receipts already on the remote; exactly one recompute happened. No-receipts race → exit 1, no retry, message says nothing expensive was lost. The receipts-only push has its own ≤3-attempt loop; that loop is never a recompute |
| #740 | The bot's commit surface is unchanged | The allowlist cases pinned in gh421 (`undeclared` refusals for `utils/py/unexpected.py`, `TESTS-RESULTS/arbitrary/…`, `PROJECT/1-INBOX/scratch-note.md`, malformed `wave-<sha>`) pass against the moved function, byte-identical regexes |
| #740 | No force-push; nothing is ever rebased; stale ledger bytes never reach the remote | The publish code contains no `--force`/`-f` and no `rebase` at all; on a race the full local commit is **discarded** and only receipt *files* are checked out of it onto the fresh head; the fixture asserts the racer's ledger line survives |
| #741 | A red run whose reconcile step is green never reports a reconcile-log error | Replay: gh421-style log (test-emitted `ERROR —` lines, last one `invalid merged_at timestamp`) + `--reconcile-outcome success` + `--publish-outcome failure` + publish log with `[rejected]` → body names the publish step and the rejection; does **not** contain `merged_at` |
| #741 | A red reconcile step still reports its real last error | Existing gh684 case (`Doc GH-505-X.md is missing …`) with `--reconcile-outcome failure` → unchanged body |
| #741 | Red control | The pre-fix `summarize()` on the replay log returns the `merged_at` line — the new attribution must differ from it on that input |
| both | Existing lane semantics | `job.status` still decides red/green; one labelled issue; self-close on green; skip lines unchanged |

## Smallest affected surface (existing subsystem + canonical writer, extended)

0. **`utils/py/wave_reconcile.py` — one narrow flag, `--only-receipted`** (valid only with
   `--catch-up --qualify`; argparse rejects it otherwise). Where `main` today calls
   `qualify_landings(repo_root, [metadata[item] …], journal)` (`:2007-2011`), the flag instead
   partitions `landing_items` with the **same** matcher the qualifier uses
   (`committed_qualifications()` + `qualification_receipt_matches()`): items with a committed matching
   receipt continue; recovered items without one are dropped from `landing_items` with a
   `wave-reconcile: deferred <landing> — no committed qualification receipt; its own run qualifies it`
   log line (not `SKIPPED` — a deferral is expected in a retry and must not open the attention
   issue); an **explicit** `--pr/--commit` item without a receipt dies (fail closed, the GH-684
   explicit-item contract). `issue_owners` (`:2015-2023`) is still built over the full `metadata`,
   deferred closers included, so an older receipted closer still yields to a newer unreceipted one.
   ~15 lines; no other path changes. gh421 gains the three cases in the Requirements row.

1. **`utils/py/hosted_lane_publish.py` (new file, same subsystem — it *is* the current inline step, moved).**
   The workflow's inline Python (`:71-103`) becomes a script so it can be unit-tested and retried;
   the allowlist (`exact`, `doc`, `plan`, `receipt` regexes), explicit `git add -A -- <paths>`, bot
   identity and commit message move **verbatim**. Added behaviour, in order:
   (F1: every push happens from a **clean tree on the current remote head**; no rebase anywhere; no
   parked files.)
   - `declared_paths()` → the sorted changed set, validated against the allowlist **once, before any
     push**; `receipt_paths(paths)` selects the receipt files with the existing `receipt` regex.
   - **Commit everything as today** into one local commit `T` (`chore: reconcile merged development
     work`; the tree is now clean) and `push origin HEAD:development`. **No race → exactly today's
     result**: one commit, one push.
   - **Race (push rejected) and `T` contains receipts →** `fetch origin development`;
     `reset --hard origin/development` (`T` stays reachable by SHA; the stale transitions are
     discarded, never rebased or restored); `git checkout <T> -- <receipt paths>` (new files under a
     `wave-<tested>` folder unique to this run — cannot collide with anything on the new head);
     commit `R` (`chore: retain qualification receipts for <tested>`); push. If *that* push is
     rejected, repeat fetch / reset / checkout / commit / push up to 3 times — receipts are the only
     content, so this loop needs no judgment.
   - **Recompute once, bounded, same semantics.** Re-run the reconcile step's own argv (passed in as
     `RECONCILE_ARGS`, exported by that step via `$GITHUB_ENV`) plus `--only-receipted --skip-pull`,
     with the landings this run qualified made explicit (F6) so publication of `R` cannot drop them
     from the catch-up enumeration. **Serialisation (F6a):** `wave_reconcile.py`'s `--pr`/`--commit`
     are `nargs="+"` store options (`:1870-1879`) — a repeated option *replaces* the earlier group — so
     the publisher parses `RECONCILE_ARGS`, takes the original `--pr` values (if any) **plus** every
     `pr` from `R`'s `provenance.jsonl` into **one** `--pr` group, and likewise every `landing_commit`
     (entries with `artifact_kind: commit`) plus any original `--commit` values into **one** `--commit`
     group; all other original flags are retained verbatim; an entry with neither identity refuses
     the retry loudly. Parser-level acceptance: the production parser fed the built argv for original
     `--pr 42` plus receipts #5/#6 yields `args.pr == ['42','5','6']` (and the `--commit` analogue);
     `['--pr','42','--pr','5']` is the red control (yields `['5']`). On the clean fresh head. `--catch-up` stays, so the retry enumerates the same lifecycle targets
     and computes the same newest-closer ownership as the original run (F4); `--only-receipted`
     (§0 below) makes it **defer** any landing without a committed matching receipt — the racer
     included; its own queued PR-closed run qualifies it — instead of running the suite. Because `R`
     is committed on HEAD and `tested` is now an ancestor, this run's landings match and are
     processed; the retry is `--gate` + transitions, minutes. `rm -f .tick/marathon-plan.fingerprint` first so
     the planner regenerates the plan file the reset reverted (fingerprint lives in untracked
     `.tick/`, `wave_reconcile.py:1617-1647`). Then `declared_paths()` again → allowlist → commit
     `T2` → push. Rejected again → exit 1: `hosted-lane-publish: ERROR — push rejected after
     recompute; origin/development moved to <sha>; receipts <R> are published, nothing expensive
     was lost`.
   - **Race and `T` contains no receipts** (nothing was qualified this run, so nothing expensive is
     at stake) → no retry: exit 1 with `hosted-lane-publish: ERROR — push rejected; origin/development
     moved to <sha>; no receipts this run — the next run recomputes cheaply`. Rare: a scheduled run
     with no pending qualification finishes in minutes, so its race window is small.
   - Every failure path prints one `hosted-lane-publish: ERROR — …` line to stderr; when the
     recompute's `wave_reconcile.py` dies, its last `wave-reconcile: ERROR — …` line is quoted inside
     that message (Codex Q4), and its `SKIPPED` lines stay in `publish.log` for the report.
   - Nothing to commit → `Nothing to commit`, exit 0 (unchanged).
2. **`.github/workflows/wave-reconcile.yml`** — publish step becomes `id: publish` /
   `run: python3 utils/py/hosted_lane_publish.py --reconcile-args "$RECONCILE_ARGS" 2>&1 | tee
   "$RUNNER_TEMP/publish.log"` under `set -euo pipefail`. The reconcile step builds its argv once as
   a bash array (`ARGS=(--pr "$PR_NUMBER" --catch-up --gate --qualify)` / `ARGS=(--catch-up --gate
   --qualify)`), runs `wave_reconcile.py "${ARGS[@]}"`, and exports `RECONCILE_ARGS="${ARGS[*]}"` to
   `$GITHUB_ENV` — one source for the argv, and the two literal command strings gh421 pins remain
   present. Report step gains
   `--reconcile-outcome "${{ steps.reconcile.outcome }}" --publish-outcome "${{ steps.publish.outcome }}"
   --publish-log "$RUNNER_TEMP/publish.log"`. Triggers, permissions, concurrency, the two reconcile
   command lines pinned by gh421 — unchanged.
3. **`utils/py/hosted_lane_report.py`** — `summarize()` keeps its signature; new
   `terminal_error(reconcile_outcome, reconcile_lines, publish_outcome, publish_lines)`:
   reconcile outcome ≠ `success` → last `wave-reconcile: ERROR — ` line (today's behaviour);
   else publish outcome ≠ `success` → last `hosted-lane-publish: ERROR — ` line, falling back to the
   last non-empty publish-log line (a raw `git` rejection); else `None`. Skip lines are collected
   from **both** logs (a recompute may skip a backlog item — Codex Q4), so a green retry cannot
   close the attention issue over a skip. `body_for()` prints
   `Terminal error (step: reconcile|publish): …` or `none captured (no step reported an error; see the
   run)`. Outcomes default to `None` → current behaviour, so the workflow and the script can land in
   one PR without an ordering hazard. `job.status`, skips, issue discovery/close: untouched.
4. **Tests** (footprint scaled to ~150 lines of production change):
   - `test/gh684-hosted-lane-report.sh`: +2 cases — attribution by outcome (replay above) and the red
     control (old `summarize()` on that log returns the `merged_at` line; new attribution does not).
   - `test/gh421-auto-wave-reconcile.sh`: the three publish tests (`:551-640`) import
     `hosted_lane_publish` instead of exec'ing YAML; allowlist cases unchanged; the "rejected push
     raises" pin becomes "rejected push → discard, receipts-only commit on the fresh head, one recompute" with `check_output`
     patched as today, keeping the combined explicit-staging assertion for the fast path and adding
     receipt-only and recomputed-staging assertions for the recovery path; `PUBLISH_HEAD`-based extraction and its bounded-extraction test go (no inline
     Python remains to extract); the ordering assertion becomes "publish step precedes report step"
     by step name; workflow markers updated (`id: publish`, `steps.reconcile.outcome`,
     `hosted_lane_publish.py`, `--publish-log`).
   - `test/gh740-hosted-lane-publish.sh` (new, registered in `validate.sh`'s `TESTS`): real git
     fixture — bare remote with a "merged PR" landing commit, a clone, and a stub reconcile command
     (`RECONCILE_CMD` override, test-only) that writes a **schema-valid** receipt pair
     (`validation.jsonl` satisfying `qualification_summary()`: one `run.start`/`run.summary`, the
     registered sequential suites incl. the two required probe names; `provenance.jsonl` entry with
     `tested_commit`/`landing_commit`/`telemetry_sha256`/`pr`), a `PROJECT/2-WORKING/GH-740-fixture.md`
     and a `releases.sql` line, and counts its invocations. Cases: (1) no race → one commit, one push,
     stub ×1; (2) race before the first push → remote = racer → receipts → transitions, stub ×2 (the
     second invocation receives the original args plus `--only-receipted --skip-pull` plus `--pr <n>`
     for the receipt the stub wrote — asserted from the stub's recorded argv), the racer's `releases.sql` line present on the remote, and **the
     real consumer** `wave_reconcile.qualification_receipt_matches(clone, entry, meta)` is True for the
     published receipt / False for a byte-corrupted `validation.jsonl` (control); (3) race before the
     first push **and** again between the receipts push and the transitions push → exit 1,
     `hosted-lane-publish: ERROR — ` names the remote SHA, receipts on the remote, stub ×2 (one
     recompute, no more); (4) race with no receipts → exit 1, no retry, stub ×1; (5) undeclared
     artifact → refused before any push; (6) **red control**, run on the stale clone *before* any
     recovery: a plain `git push origin HEAD:development` is rejected (`[rejected]`), proving the
     fixture races. (The former "B-only race succeeds" case is gone — F5: with a single combined
     first push, a rejection between `R` and `T2` *is* the second race.)

## Dependencies, risks, rollback

- No PR dependency. #674 (operator side) stays open and unchanged.
- Risk: `reset --hard` discards the local commit's transitions — intended: they were computed against
  a stale head and must never be pushed over the racer's ledger; the recompute regenerates them from
  committed state on the fresh head. Risk: untracked `.tick/marathon-plan.fingerprint` survives the
  reset — deleted before the recompute. Replay-target contract (one statement): retry argv = original
  `RECONCILE_ARGS` with its `--pr` / `--commit` groups **coalesced** with the identities from this
  run's published receipts (one `--pr` group, one `--commit` group — never a repeated option, which
  the parser would overwrite) + `--only-receipted --skip-pull`; an entry lacking both `pr` and a valid
  `landing_commit` refuses the retry loudly rather than guess. Wall time: the retry cannot qualify (pending set empty by construction), so it fits the
  unchanged 120-minute job budget.
- Rollback: revert the PR; the inline step returns. Receipts already pushed by the new code remain
  valid under the unchanged receipt schema.

## Ratings (RELEASES `rated pri/sev/appeal/effort`, written 2026-09-21)

- **#740 `85/75/50/55`** — sev 75: no data loss, but every collision discards ~70 min of runner time
  and blocks the lane from converging; recurrence 3 collisions in 5 days plus the operator rule that
  serialises merges. pri 85: severity-led; it taxes every landing. appeal 50 neutral. effort 55: one
  script + fixture suite + pin updates.
- **#741 `70/55/50/80`** — sev 55: a misleading alert sends operators after the wrong bug (it nearly
  became a radar failure class); not blocking. pri 70: prerequisite for measuring D.2 honestly.
  appeal 50. effort 80: ~25 lines + 2 test cases.

## Ordered implementation (verification inline)

1. `hosted_lane_report.py`: `terminal_error()` + `body_for()` step label + two CLI flags; gh684 +2
   cases → `bash test/gh684-hosted-lane-report.sh` green, including the red control.
1b. `wave_reconcile.py --only-receipted` (§0) + gh421 cases: two-closer (deferred #90 / receipted #42;
   both receipted; explicit unreceipted → die) and the F6 open-reference retention case (PR #5
   `References #421`, #421 OPEN, receipt committed, explicit `--pr 5` + `--catch-up --only-receipted` →
   merge evidence written, no qualification) → `bash test/gh421-auto-wave-reconcile.sh` green.
2. `hosted_lane_publish.py`: move the inline step; `declared_paths()`; commit-all → push → on race:
   discard, lift receipts, `R`, one recompute with `--only-receipted --skip-pull`, `T2`; error lines.
3. `test/gh740-hosted-lane-publish.sh` + `validate.sh` registration → green, red control witnessed.
4. `wave-reconcile.yml` wiring (`ARGS` array + `RECONCILE_ARGS` export, `id: publish`, tee, report
   flags); gh421 pin updates → `bash test/gh421-auto-wave-reconcile.sh` green.
5. Focused: gh684, gh421, gh740, `ci-workflow.sh`. Record the gh740 decisive output (remote log, consumer True/False, the rejected plain push) under `TESTS-RESULTS/2026-09-21+GH-740/`. Full gate once, in a disposable clone, on the final
   approved commit; receipts retained under `TESTS-RESULTS/2026-09-21+GH-740/`.
6. Final Codex relay QA → PR against `development`. Hosted proof is post-merge: the first PR-closed
   run exercises the fast path on the real lane; the first raced run exercises the recovery.

## Lessons Learned (For Future Agents)

- A qualification receipt is only worth anything once it is **committed on HEAD** — so on a race,
  the receipt *files* are lifted out of the discarded commit onto the fresh head; the stale
  transitions are never rebased or restored, they are recomputed.
- A retry that may re-enter a 70-minute step is not "bounded to one attempt" — make the expensive
  branch unreachable (defer what has no receipt) while keeping the *same* enumeration and ownership
  logic as the original run; narrowing the argv instead would silently change lifecycle semantics.
- `if: always()` reporters that scan a log for the last error line are only right when the step
  that wrote the log is the step that failed; pass step outcomes, don't infer.
- Classify red runs by *failing step* before by error text: 13 of 27 "reconciler failures" were one
  fixed guard, and the 3 real races were invisible behind test output.
