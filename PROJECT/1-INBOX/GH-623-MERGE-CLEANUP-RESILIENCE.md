---
gh_issue: 623
source: https://github.com/HiQS-Labs/XYZ-forge/issues/623
title: "merge-cleanup: operator had to re-drive the run 4x — collision edges cascade handoffs, no fetch retry, no resume loop (session ae137dca)"
status: "Proposed (1-INBOX — in execution on fix/gh-623-merge-cleanup-resilience)"
created: 2026-09-15
doc_type: bug
effort: 4
complexity: 3
risk: 2
reversibility: "Easy — code + docs + focused tests in one PR; rollback is a revert, no schema or data changes"
---

# GH-623: merge-cleanup Resilience — Soft Edges, Fetch Retry, Resume Loop

## Problem Statement

Session ae137dca ran `/merge-cleanup` and the operator had to re-prompt four times. Five stalls
(all structural, verified against the code on 2026-09-14):

1. **Collision edges cascade handoffs (S3).** `toposort_prs.py:104-121` puts file-collision
   ordering edges into the same `dep_graph` as explicit `depends on #N` annotations and publishes
   them all as `_deps`. `merge_cleanup.py:479-484` then treats **every** `_deps` entry as a hard
   dependency: one handoff marks the predecessor failed and every collision-adjacent PR is
   "NOT attempted". In the incident, PR #596 handed off (a CHANGELOG.md ledger-adjacent conflict)
   and #597, #598, #601 were refused as dependents — #601 was MERGEABLE; only a file-collision
   ordering edge linked it.
2. **No network retry (S4).** `prepare_landing_clone` (`merge_cleanup.py:127-154`) runs `git
   clone`, `git fetch pull/N/head` and the branch-name fallback fetch with zero retries; a single
   DNS failure ("Could not resolve host: github.com") returned 2 and aborted the rest of the
   queue — #604, #607 and #614 were never attempted.
3. **No resume loop (S5).** There is no `--resume`: after a repair, the only way to continue the
   queue is a full re-run, and the SKILL.md never tells the caller to do one.
4. **Classifier denial surrendered (S2).** One permission-classifier block of `--execute` ended
   the attempt; the identical command succeeded four minutes later. No "retry once before
   escalating" guidance exists.
5. **False Done (S1).** Phase 0 refused a dirty primary; the model silently degraded to
   teardown-only, retired 14 clones, and reported "Done" without running the PR sequence. SKILL.md
   has no drive loop and no Done rule.

## Rating (parked 2026-09-14; read back from the RELEASES DB)

`rated 82/80/50/65` (pri/sev/appeal/effort; sum 277).

- **sev 80** — work-blocking for the governed-landing workflow: 3 of 7 PRs never attempted, the
  operator hand-drove 4 re-prompts. No data loss — every stall fails safe and stops; recovery is
  manual driving. Recurring same-class area: 5th merge-cleanup reliability issue in ~5 weeks
  (#523, #534, #555, #561, #623).
- **pri 82** — severity-led; the incident is from yesterday's landing session and blocked real
  PRs (#604/#607/#614 remain unlanded).
- **appeal 50** — neutral; no operator preference stated.
- **effort 65** — one consumer of `_deps`, a retry helper, one flag, a SKILL.md section, focused
  tests in the existing gh534 fixture suite.

Recurrence window checked: 2026-08-31 → 2026-09-14 issues/PRs mentioning merge-cleanup: #561
(clone retention), #623 (this). Prior window: #555, #534, #523. Same-class (skill reliability),
not same root cause — no numeric multiplier applied.

## Scope — smallest affected surface

Three files plus their pinned tests; no change to B1 resolution, the ledger gate, teardown, or
the two-repair ceiling.

1. `skills/merge-cleanup/scripts/toposort_prs.py` — split the published edge lists.
2. `skills/merge-cleanup/scripts/merge_cleanup.py` — block only on hard edges; retry +
   defer network failures; `--resume`.
3. `skills/merge-cleanup/SKILL.md` — drive loop, Done rule, classifier-retry guidance,
   capability-table rows.
4. `test/gh534_phase_c_tests.py` — new tests + parity rows; `test/gh534_phase_b_tests.py` —
   additive gh-stub support (custom failure message, `files` passthrough).

## Requirements (per issue acceptance criteria)

- R1: `_deps` split into hard (explicit annotations) and soft (collision) edges; **soft edges
  never produce "NOT attempted"** — the per-PR landing simulation remains the real gate.
- R2: transient network failures (DNS, connection, TLS, timeout) retried with backoff (3
  attempts); a PR whose pre-decision refresh or landing-clone prep still fails is **deferred**
  and the queue continues.
- R3: `--resume` re-reads attempt records and skips parked (budget-exhausted) PRs; landed PRs
  are already skipped by the live state re-fetch.
- R4: SKILL.md gains an explicit drive loop, the rule "Do not report Done unless Phase 5 ran —
  or the operator asked for `--teardown-only`/`--scan-only`", and "on a classifier block of
  `--execute`, retry once before escalating".

## Explicit non-goals

- **/unstuck self-trigger** ("consider" item): a different skill's interplay, speculative
  machinery — rejected, out of scope (Ponytail disposition below).
- No circuit breaker for a full network outage: each PR defers after its own retries; simple
  beats clever, and a fully-down network defers every PR honestly.
- The **pre-queue** fetch (`merge_cleanup.py` main, R2-1 refusal) gains a retry but exhaustion
  still refuses the run: merging on a stale Phase 0 verdict is the pinned hazard it guards.
- The **post-merge** fetch gains a retry but exhaustion still stops: reconciliation is gating
  (SKILL.md Safety Guarantee 5); PRs are already merged remotely at that point.
- No change to hold labels, exit-code shape (0 clean / 2 stop / 3 handoff-ish), B1, the ledger
  gate, or teardown.

## Design

- `toposort_prs.py`: publish `pr["_hard_deps"]` (explicit `depends on/blocked by/after/requires`)
  and `pr["_soft_deps"]` (file-collision ordering edges). Both still feed the same `dep_graph`
  for ordering — a collision still decides *sequence*; it no longer decides *eligibility*.
  `_deps` is dropped (its only consumer is `merge_cleanup.py:479`).
- `merge_cleanup.py land_prs()`:
  - `blocked_by` reads `_hard_deps` ∩ failed — unchanged semantics for explicit dependencies
    (the pinned `dependents-blocked` test uses an explicit annotation and stays green).
  - A failed/deferred **soft** predecessor logs
    `PR #N: soft predecessor #M handed off — attempting anyway; the landing simulation decides`
    and proceeds.
  - `deferred` outcomes share the existing outcome map (so hard dependents of a deferred PR are
    blocked) and are named in the end-of-run summary; any non-empty outcome map → exit 3.
  - `_transient()`: stderr matcher for `could not resolve host`, `connection refused`, `connection
    timed out`, `timed out`, `TLS`/`SSL`, `rate limit`. A `_retry()` helper runs a network call
    up to 3 attempts with 2s/4s/8s backoff, retrying only transient failures. Applied to:
    `refresh_pr`, the clone + both fetches in `prepare_landing_clone`, the pre-queue fetch, and
    the post-merge fetch. Post-retry exhaustion: defer-and-continue for the two pre-decision
    call sites; refuse/stop for the pre-queue and post-merge sites (see non-goals).
- `--resume`: before the live refresh, if a PR's attempt record exists and shows the repair
  budget exhausted with no in-progress attempt, skip it as `previously parked (resume)`.
  A missing record proceeds normally; an unreadable one warns and proceeds (reserve still gates
  under the lock — resume only avoids re-attempting a parked PR, it never bypasses the ceiling).
- SKILL.md: new "Drive loop" section (dry run → fix the primary, never degrade to
  `--teardown-only` because Phase 0 refused → `--execute` → on exit 3 run the caller ladder and
  RE-RUN with `--resume --execute` → on exit 2 diagnose before reporting), the Done rule, the
  classifier-retry rule, Phase 5 dependents bullet reworded to the hard/soft distinction, three
  new capability-table rows, `--resume` in the documented option list.

## Bounded test scope (and non-scope)

Extend the existing gh534 fixture suite; no new frameworks, no synthetic runners.

- `test/gh534_phase_b_tests.py` (additive stub support): `files` passthrough on `pr view/list`;
  a `view_fail_msg` so a test can inject a DNS-flavored error.
- `test/gh534_phase_c_tests.py`:
  - soft-edge: PR A hands off (same-key ledger conflict), PR B collides with A on files →
    B **is attempted** (lands if mergeable); an explicitly-annotated dependent C stays blocked;
    exit 3.
  - network-defer: `pr view` for PR A fails with "Could not resolve host: github.com" on every
    attempt (backoff patched to near-zero) → A deferred, named in the summary; independent PR B
    still lands; exit 3.
  - retry-then-success: failure twice then success → the call count shows 3 attempts and the PR
    lands.
  - resume: pre-seed PR A's record with 2 finished repairs → `--resume` skips A as previously
    parked, B lands, no B1 line for A; without `--resume`, A takes the park path (existing
    behavior preserved).
  - parity rows: `soft-edge-nonblocking`, `network-retry-defer`, `resume-skips-parked` (script
    rows naming the tests above) + `--resume` in the documented option list (the parity guard
    checks documented options against argparse).
- **Red controls:** the soft-edge, network-defer, and resume tests are written first and run
  against the unmodified code to watch them fail (soft-edge: today B is "NOT attempted";
  network-defer: today the run exits 2 and B never lands; resume: today there is no such flag).
  Evidence recorded in the execution log below.

## Ordered implementation list

1. Write the three red tests + stub support; run → expect exactly those failures.
2. `toposort_prs.py`: `_hard_deps`/`_soft_deps`; keep ordering identical; update
   `gh436` toposort tests still green -> expect `test/gh436-merge-cleanup.py` green.
3. `merge_cleanup.py`: hard/soft blocking, `_transient`/`_retry`, defer-and-continue,
   `--resume` -> expect the three tests green; `test/gh534_phase_c_tests.py` fully green.
4. SKILL.md drive loop + rows + option list -> expect `TestParityGuard` green.
5. Focused gate: `python3 -m unittest test.gh534_phase_c_tests -v` and `bash test/gh436-merge-cleanup.sh`
   -> expect green. Then `./validate.sh --tier 2 --subsystem hq` if registered, else the full
   `ci-local.sh` once on the final commit (mutation-heavy suites run only in this disposable
   clone, never the primary).
6. CHANGELOG entry per PDDA; PR to `development`.

## Execution log

- 2026-09-14: intake parked + rated (82/80/50/65); task clone
  `~/Documents/GH Repos/XYZ-forge-gh623` cut at origin/development `98cd6edf`; hooks verified.
