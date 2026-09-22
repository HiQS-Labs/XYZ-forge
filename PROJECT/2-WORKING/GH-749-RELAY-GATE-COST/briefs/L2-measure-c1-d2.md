---
title: "L2 brief — #732 C.1 + D.2: measure the conflict magnets and the hosted-lane green rate (umbrella #749)"
status: "Brief (input to the GH-749 marathon — not a tracked plan)"
created: 2026-09-22
updated: 2026-09-22
owner: Noel Saw
goal: >
  Two reproducible measurements, written as counted lists with the commands that produce them, so #732's
  C.1 (which committed files absorb merge work) and D.2 (how often the hosted reconcile lane is green)
  are numbers with provenance instead of observations.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/749
  - https://github.com/HiQS-Labs/XYZ-forge/issues/732
  - https://github.com/HiQS-Labs/XYZ-forge/issues/591
---

# L2 — #732 C.1 + D.2: measurements only

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-22); raw inputs captured under `TESTS-RESULTS/2026-09-22+GH-732/{c1,d2}/` | Phase p2 fires after p1 is approved |

Umbrella: #749 · Issue: #732 lanes C.1 and D.2 · Phase p2 · `depends_on: p1`

## Inputs already in the tree (read-only — do not regenerate, do not delete)

- `TESTS-RESULTS/2026-09-22+GH-732/d2/runs-40.json` — the last 40 `wave-reconcile.yml` runs, captured 2026-09-22 with the command recorded in `runs-40.CAPTURE.txt` (`gh` may be unreachable from the builder's sandbox; the file is the signal).
- `TESTS-RESULTS/2026-09-22+GH-732/c1/merge-commits-touching-magnets.txt` — `git log --merges --since=2026-08-31 --until=2026-09-22` over `validate.sh`, `releases.db`, `skills/relay-automation/relay-pkg.tar.gz`.
- `TESTS-RESULTS/2026-09-22+GH-732/c1/resolver-commits.txt` — non-merge commits in the same window whose subject mentions resolve/B1/conflict and touch the same three paths.
- `TESTS-RESULTS/2026-09-22+GH-732/c1/attempt-records/*.json` — the merge-cleanup B1 attempt records from the primary's `.tick/merge-cleanup/HiQS-Labs-XYZ-forge/` (each names a PR, its repair rungs and outcome).
- `git log` in this clone is also available for any further count you need; name the exact command in the output.

## Deliverables (the lane's write-set — nothing else)

1. **`TESTS-RESULTS/2026-09-22+GH-732/c1/conflict-magnets.md`** — for each of the three files: the count of PRs in the window that needed a manual/B1 resolution on it, the PR numbers (or commit SHAs when the PR is not derivable), the command(s) the count comes from, and **one decision line per file** using the issue's three options verbatim — *registry* (derive the `TESTS` list from `test/*.sh` + an explicit exclusions list; the frozen-twin and registration guards must still fire), *tarball* (generate on demand / in CI instead of committing; first check who consumes the committed bytes), *ledger* (the #496 Phase 3 spike, held). A decision line is a recommendation with its evidence, not an implementation.
2. **`TESTS-RESULTS/2026-09-22+GH-732/d2/hosted-lane-rate.md`** — from `runs-40.json`: green / failed / cancelled counts, the run ids per bucket, the date range covered, the count of consecutive green runs at the head of the list (the issue's exit condition is 10), and the two prior baselines for comparison (7/40 at #732 v6 on 2026-09-21; 14/40 at triage on 2026-09-22 — this run recomputes from the file, it does not copy those numbers).
3. **`provenance.jsonl`** in each of `c1/` and `d2/` — one JSON object per command run (command, cwd, exit code, output file, sha256 of the output), the same shape other `TESTS-RESULTS/` folders in this repo use.

## Rules

Measurement only: **no source, docs, registry or ledger edits** in this lane. Counts must be reproducible from the named commands over the committed inputs — a reviewer who re-runs them must get the same numbers. Where the inputs cannot answer a question (e.g. a PR number for a resolver commit), say `not derivable from inputs` rather than guessing. `bash validate.sh` green is the phase gate (the lane adds no code, so this is the unchanged trunk gate).

## Acceptance / Guard

- Both markdown files exist, are non-empty, and every number in them is followed by the command that produces it.
- `provenance.jsonl` present in both folders with at least one record each; sha256 values match the files they name.
- No file outside `TESTS-RESULTS/2026-09-22+GH-732/{c1,d2}/` is modified by this phase (`git status` after the turn shows only those paths).
