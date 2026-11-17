# GH-1493 — verification summary

Candidate code commit: `0d1ccf8fa36ca51d6facb00926491b3390f3703a` (base `9331cec67`).
Plan QA: `relay-system/2026-11-17/gh1493-plan-qa.md` — Codex, Approved round 2.

## Manual batch check (red/green)

One call, paths in this order: local-origin helper, other-repository clone, non-Git directory,
then one eligible checkout. Inspection, refresh and teardown are patched to record calls
(delegation, not retirement). Input: `manual-batch-input.md`.

| Run | Exit | Output | Recorded calls |
|---|---|---|---|
| Base `9331cec67` (`manual-batch-base-9331cec67.txt`) | 2 | one `Published retirement refused: checkout origin differs …` line | 0 |
| Candidate `0d1ccf8fa` (`manual-batch-candidate-0d1ccf8.txt`) | 1 | three `PRESERVED <path>: <reason>` lines; origin lines name the helper fix | eligible path only: inspect (`published_pr=9`), refresh, teardown (`dry_run=True`) |

The base run is the red control: an unfixed driver exits 2 with no delegation. A driver that
stopped at the first refusal would also show zero calls, because the eligible path comes last.

## Gate

`ci-local.sh` on `0d1ccf8fa` in disposable clone `<task folder>-gate` (made by cloning the task
clone, then `git remote set-url origin` to the canonical URL): **green**, 407 recorded, 406 pass,
1 skip (`acorn-extract.sh`, already run in the npm step). Includes `gh436-merge-cleanup.sh`,
`gh589-xyz-mini-sync.sh` and `gh620-skills-army-mini-sync.sh` (publisher suites: changed files sit
under published skill folders). Clone identity (HEAD, origin, `core.bare=false`) identical before
and after. Receipt: `gate/ci-local-0d1ccf8fa.txt`. The push of `0d1ccf8fa` from the same clone ran
the pre-push full gate: `pre-push: full gate GREEN in 799s`.

## Smoke (GH-1088)

PENDING — real PR preview, see plan "Verification inline".
