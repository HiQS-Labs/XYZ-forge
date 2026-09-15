---
gh_issue: 624
source: https://github.com/HiQS-Labs/XYZ-forge/issues/624
title: "GH-624: merge-cleanup Phase 5 — emit pr_merged after the fast-forward, commit and push the primary's ledger writes, wait for the hosted reconciler"
status: active
created: 2026-09-14
updated: 2026-09-15
owner: orchestrator (Claude Code) · builder codex · reviewer agy
doc_type: bugfix
effort: 2
complexity: 3
risk: 3
phases: 1
rating: "pri/sev/appeal/effort 90/90/90/70 · calc 340"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: a merge-cleanup --execute run lands every ready ledger-touching PR in one run instead of stopping at its own fast-forward after the first
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/629 — same seam: Phase 5 runs local wave_reconcile while the hosted run it triggered is in flight; closed by the same change"
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/625 — why the hosted reconciler is red today"
---

# GH-624 — merge-cleanup: pr_merged emit dirties the primary before the fast-forward

## Status

| What was just completed | What's next |
|---|---|
| lane gh-624 approved by agy (round 1) and gate green: emit moved after reconcile, `commit_and_push_phase5_writes` added, two-PR landing test + AST order pin; CHANGELOG entry written | PR from `marathon/10days-2026-09-15` into `development`; lands via /merge-cleanup, which is the first live exercise of the new Phase 5 order |

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.

## Bug

`skills/merge-cleanup/scripts/merge_cleanup.py` Phase 5 sequence is merge → `emit_pr_merged`
(writes a `pr_merged` work event into the primary's `releases.db`, regenerating `releases.sql`
and `LEADERBOARD.md`) → `git merge --ff-only origin/development` → `run_post_merge_reconcile`.
The squash merge on origin also touched the three ledger files, so the fast-forward refuses to
overwrite the uncommitted emit; the run exits 2 after the first ledger-touching PR and the
reconcile never runs. Observed 2026-09-14 on PR #596 from a clean landing clone (issue body has
the log). Second defect in the same 30 lines (#629): `run_post_merge_reconcile` runs
`wave_reconcile.py --pr N` immediately, which refuses while the hosted `wave-reconcile.yml` run
the merge just triggered is queued or in progress — so even with the emit moved, the run stops
at the reconcile. Documented order in `skills/merge-cleanup/SKILL.md` Phase 5 is: wait for the
hosted run, fast-forward, local reconcile only when hosted failed / is absent.

Ground truth (this clone, `ab7ab1d5`): `rg -n 'wave-reconcile|run list' skills/merge-cleanup/scripts/merge_cleanup.py` → 0 matches;
emit at line 600, fast-forward at line 606, reconcile at line 611.

## Fix (smallest mechanism)

In the Phase 5 landing loop: merge → fetch + `--ff-only` → reconcile (poll the hosted run for the
merged head with a bounded, env-overridable timeout; on success fetch + `--ff-only` again; on
failure / timeout / no `gh` / no workflow run the existing local `wave_reconcile.py --pr N`,
then `releases_app.py check` and `pdda.sh issue-doc-sync` as today) → `emit_pr_merged` → commit
the primary's ledger writes on the integration branch → push to `origin/<integration>` → next
PR. The test fixture's fake `gh` must answer `run list` (empty → local path). Keep the existing
functions; reorder the calls and add the wait + commit/push. No new module, no second writer:
the ledger is still written only through `releases_app.py`.

Test scope: `test/gh534_phase_c_tests.py` (new two-PR landing test with `Closes #N` bodies,
red-control noted in its docstring) plus the already-registered `test/gh436-merge-cleanup.sh`
and `test/gh549-work-events.sh`. Test non-scope: no new fixture framework, no hosted-runner
simulation beyond the fake `gh run list` answer.

## Acceptance

- [ ] In `skills/merge-cleanup/scripts/merge_cleanup.py` Phase 5, nothing writes into the primary between the remote merge and the fast-forward: `emit_pr_merged` runs only after `git merge --ff-only origin/<integration>` has succeeded (and, per #629, after the reconcile step's own fast-forward).
- [ ] Every ledger write Phase 5 makes in the primary (the `pr_merged` work event, any local reconcile output) is committed on the integration branch and pushed to `origin/<integration>` before the next PR is attempted; after each landed PR `git status --porcelain` is empty and `HEAD == origin/<integration>`.
- [ ] A test in `test/gh534_phase_c_tests.py` (existing fake-`gh` fixture) lands two ledger-touching PRs whose bodies say `Closes #<issue>` in one `--execute` run: both read MERGED, the primary is clean, and `HEAD == origin/<integration>`. Red control: the pre-fix ordering fails this test at the second PR's fast-forward.
- [ ] `bash test/gh436-merge-cleanup.sh` and `bash test/gh549-work-events.sh` are green, and the Phase 5 text in `skills/merge-cleanup/SKILL.md` describes the implemented order (merge → fast-forward → reconcile → emit → commit → push).

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash test/gh436-merge-cleanup.sh && bash test/gh549-work-events.sh",
  "fix_probes":  [ { "type": "grep_present", "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
                     "pattern": "emit_pr_merged\\(primary_repo, pr, dry_run=False\\)\\s*\\n(?:.*\\n){0,4}\\s*fetched = run_git\\(primary_repo, \\[\"fetch\"" } ],
  "artifacts":   [ "skills/merge-cleanup/scripts/merge_cleanup.py", "skills/merge-cleanup/SKILL.md", "test/gh534_phase_c_tests.py" ],
  "remediation": { "source": "issue#624", "criteria": "Phase 5 lands N ledger-touching PRs in one run: merge -> ff -> reconcile (hosted wait, local fallback) -> emit -> commit -> push; primary clean and at origin after each PR" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ ".tick/", "CHANGELOG.md", "releases.db", "releases.sql", "LEADERBOARD.md", "PROJECT/" ] }
}
```

## Lessons Learned (For Future Agents)

- The defect was invisible while the hosted reconciler committed on `development`; a local-only path exposed it. When a landing tool has two writers (hosted workflow, local script), test the local path with the hosted one absent — the fixture's fake `gh` returning `[]` for `run list` is that test.
- "Emit after the merge" and "emit after the fast-forward" differ by exactly the ledger files the squash merge also touched; the AST order pin in `test/gh549-work-events.sh` keeps the call order from drifting back without anyone noticing.
- Lane cost: first codex attempt died on provider capacity (no build); the re-fire built, reviewed and gated in 15 minutes.
