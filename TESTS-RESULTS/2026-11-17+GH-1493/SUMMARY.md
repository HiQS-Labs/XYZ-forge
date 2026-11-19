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
and after. Receipt: `gate/ci-local-0d1ccf8fa.txt`.

## Smoke (GH-1088)

Real PR #1516 (non-draft, live head `4355071e83c7e24a1c9e8639c3965e8010f96d27`), driver from the
task clone at that head, preview only (no `--execute`), run from the primary as working directory:

```
merge_cleanup.py --primary <GH Repos>/XYZ-forge --retire-published-pr 1516 \
  --checkout <task clone> --checkout <task>-gate --checkout <task>-localorigin --checkout <task>-verify
```

| Checkout | Setup | Run 1 (`smoke/run1-preview-pr1516.txt`) | Run 2, same call (`smoke/run2-…`) |
|---|---|---|---|
| task clone | HEAD `4355071e8` = PR head, clean | `SAFE_REMOVE_CLONE`, would remove | same |
| `-gate` | cloned from task clone, origin set to canonical, HEAD `0d1ccf8fa` (on the PR branch) | `ACTIVE_PROCESS` (open handles from two leftover `sleep` processes of the stopped first push attempt), skipped | `SAFE_REMOVE_CLONE` (those processes had exited) |
| `-localorigin` | `git clone <task clone>`, origin left as the local path | `PRESERVED …: checkout origin (<task clone>) differs from the protected primary (https://github.com/HiQS-Labs/XYZ-forge.git); a -gate/-verify helper must keep the canonical origin — clone the task clone, then: git -C <helper> remote set-url origin https://github.com/HiQS-Labs/XYZ-forge.git` | same |
| `-verify` | canonical origin, clean, one empty local commit `3c660c33172ec9077083549557a22f8b9e69a27a` beyond the PR head | `PRESERVE_UNPUSHED` (unlanded local ref `refs/heads/fix/…` @ `3c660c3317`), skipped | same |

Exit 1 both runs. Verdict: **pass.** The batch continued past a refused path and a preserved
classification; the local-origin refusal names the helper recipe; the unpublished-commit control
reached classification and was preserved for its unpushed ref, not an origin, dirt or session reason.
The `-gate` change between runs is live session evidence working as designed, not a defect.

## CodeRabbit follow-up: refused checkout nested in an admitted one (2026-11-17)

CodeRabbit found that a refused checkout nested inside an admitted one would be moved to Trash with
its parent. `retire_published_checkouts` now records each refused path and preserves any admitted
checkout that contains one (`PRESERVED <path>: contains refused checkout <inner>`), before it is
inspected or torn down.

Manual check, preview only (no `--execute`), receipt `manual-nested-refused.txt`. A parent clone with
the canonical origin holds an ignored nested `git init` repo (`inner/`, origin none). The run passes
`--checkout <parent>/inner --checkout <parent>`.
- Old code (`0e470b330`): `inner` is preserved, but the parent is admitted and goes on to inspection
  and teardown. It survived this run only because of unrelated local tags (`PRESERVE_UNPUSHED`).
- New code: both are preserved, and the parent is never inspected. Exit 1 for both.

## CodeRabbit follow-up 2: duplicate path (2026-11-17)

The guard now also matches a refused path equal to the admitted one. Passing the same checkout twice
used to refuse the second occurrence but leave the first eligible. Preview check, receipt
`manual-duplicate-path.txt`: both occurrences are `PRESERVED`, exit 1. The GH-1493 roadmap row's
stored text now carries 🚧, matching its status marker (`roadmap update --raw-text`).
