---
title: "GH-807: test/signal-triage.sh quiet-grep pipelines produce a false failure under load"
status: active
created: 2026-09-24
updated: 2026-09-24
owner: noel
gh_issue: 807
source: https://github.com/HiQS-Labs/XYZ-forge/issues/807
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
related:
  - GH-139
  - GH-460
  - GH-801
non_goals:
  - No new test framework; no change to GH-804's skill-test simplification
  - No change to utils/signal-triage.sh (the producer under test is correct; the harness is wrong)
  - No relaxation of the GH-139 ratchet — it moves forward (9 → 0), never back
goal: >
  Every assertion in test/signal-triage.sh matches on a captured string instead of piping a
  producer into grep, so grep's early exit can no longer SIGPIPE the echo under `set -o pipefail`
  and report a mismatch on correct JSON. The GH-139 baseline row for this file goes to zero.
---

# GH-807 — signal-triage quiet-grep false failure

## Status

| What was just completed | What's next |
|---|---|
| Ten `echo \| grep` sites rewritten to here-string matching; GH-139 baseline row removed (9 → 0). Red control reproduced the defect (2/8 parallel runs at `0ae3452a`); fixed suite 44/44 on 9/9 runs incl. 8-wide parallel; `gh139` green. Evidence in `TESTS-RESULTS/2026-09-24+GH-807/`. | Full `validate.sh` once on the final commit; Codex final relay QA; push through the pre-push gate; PR against `development`. |

## Observed

Under the 4-wide macOS full gate (candidate `df1353de`, 2026-09-24), `test/signal-triage.sh:70`
emitted `echo: write error: Broken pipe` and reported `FAIL: pdda-001: expected category=drift`
while printing JSON whose `category` was `drift`. The gate's serial retry passed (43/43 → 420/420).
Evidence: PR #799 at `52eb25cf`, `TESTS-RESULTS/2026-09-24+GH-796/resume-signal-triage.sh.log`.

## Root cause (traced, not inferred)

Ten sites pipe a shell variable into grep: nine `echo "$json" | grep -q …` (lines 70, 76, 102,
114, 154, 159, 182, 190, 254) and one `echo "$json_l" | grep '"category"'` (line 208). Under
`set -o pipefail` (line 26), `grep -q` exits on first match, `echo` gets SIGPIPE on a large
write, the pipeline's status is non-zero, and the `if` takes the fail branch. Same class as
GH-139 / GH-460; this file is a grandfathered row in `test/baselines/GH-139-pipe-grep-baseline.txt:32`
(`9 test/signal-triage.sh`).

## Fix — one shape, ten sites

`grep -q PAT <<<"$json"` (here-string; no producer process, nothing to SIGPIPE). Line 208 becomes
`grep '"category"' <<<"$json_l"`. Assertion text and pass/fail messages unchanged. Baseline row
for this file: `9` → removed (0), ratcheting GH-139 forward.

## Acceptance

- [x] `grep -cE '\| *grep' test/signal-triage.sh` → 0
- [x] `bash test/signal-triage.sh` → 44/44 serial, and 44/44 on each of 8 concurrent runs
      (`for i in $(seq 8); do bash test/signal-triage.sh & done; wait`) — the parallel case is
      the one that failed; one serial pass is not proof of absence
- [x] Red control (2/8 unfixed runs failed with Broken pipe; 0/9 fixed): the same 8-wide run against `origin/development`'s copy of the file reproduces
      at least one `Broken pipe` or FAIL, or the report records that it did not reproduce on this
      host and why the fix is still correct (pipefail semantics, not a load-only symptom)
- [x] `bash test/gh139-pipe-grep-guard.sh` green with the baseline row removed
- [ ] Full `validate.sh` green once on the final commit, in this clone

## Rating (RELEASES, 2026-09-24)

`rated 55/45/50/92`. sev 45: a false red on the full gate; no data loss, retry masks it, but a
masked flake trains operators to ignore the gate. pri 55: severity-led plus a same-class fix
(#801) landed this week — the class is active, this is its last grandfathered row in this file.
appeal 50 neutral (no user preference given). effort 92: ten one-line rewrites, established
pattern, existing guard. Recurrence window 2026-09-10 → 2026-09-24: #801 (same class, different
files), #807; prior 14 days: none found. Coverage limit: issue search only, no gate-log corpus.
