---
gh_issue: 1493
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1493
title: "merge-cleanup: --retire-published-pr aborts the whole call on a -gate helper cloned from the task clone"
status: Complete
created: 2026-11-17
updated: 2026-11-17
owner: start-task lane
goal: One ineligible --checkout path is preserved with its reason while the other paths are still retired, and the origin refusal names the supported way to make a helper.
doc_type: bug
effort: 1
complexity: 1
risk: 1
phases: 1
related:
  - GH-1059 (published-PR retirement mode)
  - GH-1193 (earlier sibling-clone refusal, closed)
  - GH-1359 (retirement gaps)
context_tags: [merge-cleanup, start-task, retirement, helpers]
---

# GH-1493 — Published retirement: per-path preservation and helper origin

## Status
| What was just completed | What's next |
|---|---|
| Plan QA Approved (r2); implemented in `0d1ccf8fa`; manual check, ci-local gate and PR #1516 smoke green (`TESTS-RESULTS/2026-11-17+GH-1493/`) | Final Codex relay QA, then PR ready; awaiting merge |

## Observed problem

`merge_cleanup.py --retire-published-pr N --checkout A --checkout B --checkout C` validates every
path inside one `try` block (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2396-2418`).
The first ineligible path raises, the whole call logs `Published retirement refused: …` and
returns 2, so eligible paths named in the same call are not retired. Observed on PR #1492
(issue body): a `-gate` helper made with `git clone <task clone>` has a local-path `origin`,
fails the origin check at `:2412-2414`, and blocks the task clone and `-verify` helper.

A local-origin helper cannot be classified anyway: `published_pr_head()`
(`skills/2-daily/merge-cleanup/scripts/scan_clones.py:529-570`) requires a canonical GitHub
origin and fetches the PR head from `origin`. Teaching classification to resolve through the
parent checkout is a larger, riskier change and is out of scope (scoping comment on #1493).

## Requirements (from the scoping comment)

1. **Batch abort.** Move per-path validation inside the loop. An ineligible path prints
   `PRESERVED <path>: <reason>` and is skipped; the remaining paths are still inspected and
   retired through the unchanged `inspect_checkout` → `refresh_for_teardown` →
   `teardown_checkout` path. Exit 1 if anything was preserved (the documented exit for
   "could not retire a checkout", `skills/2-daily/merge-cleanup/SKILL.md:478`). Same spirit as
   the existing per-checkout skip at `merge_cleanup.py:1601` (`Skipping …: disposition is …`).
2. **Helper origin.** Keep the origin check. Its message names the supported way to make a
   helper: keep the canonical origin, e.g. `git clone <task clone> <helper>` then
   `git -C <helper> remote set-url origin <origin URL>`. Add one sentence to
   `skills/1-hourly/start-task/SKILL.md` near `:117-119` saying `-gate`/`-verify` helpers must
   keep the canonical origin.
3. **Controls unchanged.** A checkout of a different repository and a helper holding a local
   commit not on the published head are still preserved.

## Plan (one ordered list)

1. `retire_published_checkouts` (`merge_cleanup.py:2387`): keep the primary-origin check
   (`:2390-2393`, still exit 2 — no per-path decision is possible without it). Replace the
   single `try` with a per-path `try` inside the loop; on `OSError/RuntimeError/ValueError`
   print `PRESERVED <raw path>: <reason>` and continue. Accumulate `preserved`; return
   `1 if (failed or preserved) else 0`. Overlap check still compares against already-accepted
   candidates. Existing teardown loop unchanged.
2. Origin message: `checkout origin differs from the protected primary (<origin or "none">):
   <path>; a -gate/-verify helper must keep the canonical origin — clone the task clone, then
   git -C <path> remote set-url origin <primary origin>`.
3. `skills/1-hourly/start-task/SKILL.md` after `:117-119`: one sentence — helpers keep the
   canonical origin (clone the task clone, then `git remote set-url origin <origin URL>`), or
   Step 9 retirement preserves them.
4. `skills/2-daily/merge-cleanup/SKILL.md` scoped-contract paragraph (`:651-656`): one clause —
   an ineligible path is preserved with `PRESERVED <path>: <reason>` and the other paths still run.
   (Full-gate file; keeps the contract truthful.)
5. `CHANGELOG.md` entry.

Verification inline:

- No existing suite exercises `retire_published_checkouts` (`git grep retire_published -- test`
  is empty). Manual check under `TESTS-RESULTS/2026-11-17+GH-1493/` with `provenance.jsonl`:
  a temp primary (canonical-style origin) plus, in one call and in this order,
  (b) a clone whose origin is a local path, (c) a clone of a different repository,
  (d) a non-Git directory, then (a) an eligible path — so the eligible path comes after refusals.
  `inspect_checkout`/`refresh_for_teardown`/`teardown_checkout` are patched to record their calls
  (so the check observes the batch decision, not GitHub; a recorded call is delegation, not
  retirement). Before (base `9331cec67`): exit 2, one `refused` line, zero recorded calls.
  After: (b)(c)(d) each print `PRESERVED <path>: <reason>`; (a) alone is passed to inspection
  (`published_pr=N`), refresh and teardown (`dry_run=not execute`); exit 1. A candidate that stops
  processing at the first refusal fails this check (plan QA F1).
- Smoke (GH-1088) on this task's own closeout, real PR, preview (no `--execute`) for the controls:
  main path = one call naming the task clone, a `-gate` helper with the canonical origin, a
  helper with a local-path origin, and a `-verify` helper with the canonical origin that is clean
  but holds one local commit beyond the published PR head. Expected: local-origin helper
  `PRESERVED` with the helper-creation hint; the unpublished-commit helper reaches classification
  and is preserved for its unpushed ref (`PRESERVE_UNPUSHED`, not an origin/dirty/session reason);
  task clone and `-gate` classify as retirable. Receipt keeps each path, ref, SHA and the live PR
  head (plan QA F2). Adjacent path = rerun of the same call (second invocation), same verdicts.
  Recorded in the same folder; then the real closeout retires only the eligible paths.
- Overlap: the overlap test still compares against already-accepted candidates only (order
  dependent, unchanged); no stronger subtree isolation is claimed.
- Gate: `utils/ci-route.sh` routes merge-cleanup code as full gate → `ci-local.sh` once on the
  final commit, in a disposable `-gate` clone. Express rule: also run `test/gh620-skills-army-mini-sync.sh`
  and `test/gh589-xyz-mini-sync.sh` (published skill folder). Focused: `test/gh436-merge-cleanup.sh`.

## Non-goals

- Accepting a helper whose origin is another `--checkout` path (classification change).
- Any change to classification, teardown, safe roots, or the primary-origin requirement.
- New test suites or registry entries (AGENTS.md *No new tests*).

## Preflight bet check

- Outcome: start-task closeout retires what it can in one call and tells the operator how to
  fix the rest.
- Smallest bet: per-path skip + clearer message + one doc sentence.
- Alternative rejected: accept local-origin helpers — needs classification to resolve PR heads
  through a parent checkout (scan_clones.py:529-570), larger and riskier.
- Rollback: revert the single commit; behaviour returns to all-or-nothing refusal.

## Risks

- A caller relying on exit 2 for a bad path now sees exit 1. Only start-task Step 9 calls this
  mode; SKILL.md's exit table already maps 1 to "could not retire a checkout; preserved".

## Rating (2026-11-17)

`rated 50/45/50/85`. Consequence: leftover task clones and a manual removal at every closeout
that uses a local-origin helper; no data loss (fails closed). Recurrence: 14-day window — one
incident (#1492 closeout, 2026-11-15); prior sibling refusal #1193 (closed, different cause).
Appeal neutral. Cheap: one function and two doc sentences.
