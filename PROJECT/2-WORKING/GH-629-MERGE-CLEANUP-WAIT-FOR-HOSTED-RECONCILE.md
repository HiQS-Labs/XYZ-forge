---
gh_issue: 629
source: https://github.com/HiQS-Labs/XYZ-forge/issues/629
title: "GH-629: merge-cleanup Phase 5 — wait for the hosted wave-reconcile run before reconciling locally; local fallback only when hosted failed or is absent"
status: active
created: 2026-09-15
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
goal: a merge-cleanup --execute run on a repo with the hosted reconciler enabled does not stop at run_post_merge_reconcile because the hosted run it just triggered is in flight
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/624 — emit-after-fast-forward + commit/push, landed on this branch first (lane gh-624)"
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/625 — hosted reconciler red until it lands"
---

# GH-629 — merge-cleanup: local reconcile runs while the hosted run it triggered is in flight

## Status

| What was just completed | What's next |
|---|---|
| lane gh-624 landed the durability order (ff → reconcile → emit → commit → push) but left `run_post_merge_reconcile` with no hosted-run awareness | this lane: hosted wait + local fallback inside the same Phase 5 sequence |

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.

## Bug

`run_post_merge_reconcile()` (skills/merge-cleanup/scripts/merge_cleanup.py) runs
`utils/py/wave_reconcile.py --pr N` immediately after the fast-forward. The `gh pr merge` that
Phase 5 just executed pushed to the integration branch, which triggers the hosted
`wave-reconcile.yml`; `wave_reconcile.py` refuses while that run is queued or in progress
(`check_hosted_reconciler_in_flight`, utils/py/wave_reconcile.py:75). So with the hosted
reconciler enabled the local reconcile is refused on every landing, `run_post_merge_reconcile`
returns False, and the run stops after one PR. `rg -n 'wave-reconcile|run list' skills/merge-cleanup/scripts/merge_cleanup.py`
→ 0 matches on this branch (after lane gh-624).

Documented order (skills/merge-cleanup/SKILL.md Phase 5): wait for the hosted run, fast-forward
onto its commit, local reconcile only when the hosted run failed or is absent.

## Fix (smallest mechanism)

Inside `run_post_merge_reconcile` (or a small helper it calls) before the local
`wave_reconcile.py` step: if `gh` is present, `gh run list --workflow wave-reconcile.yml
--branch <integration> --commit <merged head sha> --json databaseId,status,conclusion` and poll
until the run for that head is `completed` (bounded timeout, env-overridable, e.g.
`MERGE_CLEANUP_HOSTED_WAIT_S`, default 1800; poll interval ~30 s). On `success`: fetch +
`--ff-only` the primary onto the reconcile commit and skip the local `wave_reconcile.py`. On
`failure` / `cancelled` / timeout / no run found within a short grace window / no `gh` / no
workflow: run the existing local `wave_reconcile.py --pr N` exactly as today (no
`--force-local-reconcile` while a run is still queued or in progress). `releases_app.py check`
and `pdda.sh issue-doc-sync` stay as they are; emit → commit → push from lane gh-624 stay after
this step unchanged. The fake `gh` in `test/gh534_phase_c_tests.py` answers `run list` with `[]`
so the existing two-PR test takes the local path; one new test asserts the local
`wave_reconcile.py` is not invoked while the fake `gh` reports a run `in_progress` for the head
until it flips to `completed/success`, and that the primary then fast-forwards onto the fake
hosted commit. No new module, no second writer, no change to `wave_reconcile.py`.

Test scope: `test/gh534_phase_c_tests.py` (fake-`gh` `run list` answer; one new hosted-wait
test), `bash test/gh436-merge-cleanup.sh`, `bash test/gh549-work-events.sh`. Test non-scope:
no real GitHub calls, no workflow YAML changes.

## Acceptance

- [ ] After a PR is merged and the primary fast-forwarded, Phase 5 waits for the hosted `wave-reconcile.yml` run for that head to complete (bounded, env-overridable timeout) and fast-forwards onto its reconcile commit; local `wave_reconcile.py --pr N` runs only when the hosted run failed, timed out, or does not exist (no `gh`, no workflow), never while it is queued or in progress.
- [ ] The `pr_merged` work event(s) for the PR are emitted after that reconcile fast-forward, committed on the integration branch, and pushed to `origin/<integration>`; before the next PR is attempted `git status --porcelain` is empty and `HEAD == origin/<integration>`.
- [ ] The fake-`gh` fixture in `test/gh534_phase_c_tests.py` answers `gh run list` (no runs → local path) and a two-PR `--execute` run lands both PRs.


## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash test/gh436-merge-cleanup.sh && bash test/gh549-work-events.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "skills/merge-cleanup/scripts/merge_cleanup.py", "pattern": "wave-reconcile\\.yml" } ],
  "artifacts":   [ "skills/merge-cleanup/scripts/merge_cleanup.py", "skills/merge-cleanup/SKILL.md", "test/gh534_phase_c_tests.py" ],
  "remediation": { "source": "issue#629", "criteria": "Phase 5 waits for the hosted wave-reconcile run for the merged head; local wave_reconcile only when hosted failed/absent; never while queued or in progress" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ ".tick/", "CHANGELOG.md", "releases.db", "releases.sql", "LEADERBOARD.md", "PROJECT/" ] }
}
```

## Lessons Learned (For Future Agents)

- (filled at closeout by the orchestrator)
