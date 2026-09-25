---
gh_issue: 674
source: https://github.com/HiQS-Labs/XYZ-forge/issues/674
title: "merge-cleanup: hosted wave-reconcile lookup keys on the merge SHA, misses the PR-closed run, then forces past the writer's in-flight guard (races the hosted reconciler)"
status: Complete
created: 2026-09-21
updated: 2026-09-24
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
rating: "pri/sev/appeal/effort 90/90/90/60 · calc 330"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  merge-cleanup finds the hosted wave-reconcile run a PR merge actually triggers (PR-head keyed),
  waits on it, and never appends --force-local-reconcile in the automatic fallback.
---

# GH-674 — merge-cleanup: hosted wave-reconcile lookup keys on the merge SHA, misses the PR-closed run, then forces past the writer's in-flight guard (races the hosted reconciler)

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`skills/merge-cleanup/scripts/merge_cleanup.py:403-404` queries `gh run list --branch <integration>
--commit <merged_head>`, but `wave-reconcile.yml` triggers on `pull_request: closed` and GitHub keys
that run on the PR head — the lookup returns empty every time, the 60s grace expires, and
`run_local_reconcile()` (`:466-468`) appends `--force-local-reconcile`, overriding the writer's own
in-flight guard. Reproduced at HEAD e565c0fe by grep; no fix commit or PR references #674.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `wait_for_hosted_reconcile()` lists recent `wave-reconcile.yml` runs without the
      `--branch`/`--commit` filter (or with `--event pull_request`) and matches a run on
      `headSha == <PR headRefOid>` OR `headSha == <merge sha>`; any
      `queued|in_progress|waiting|requested` run inside the grace window counts as active
      regardless of key.
- [ ] The automatic `run_local_reconcile()` fallback never appends `--force-local-reconcile`; the flag
      is reserved for an explicit operator option on the skill.
- [ ] A registered test (new `test/gh674-merge-cleanup-hosted-lookup.sh`, added to `validate.sh`) uses
      a fake `gh run list` that returns a PR-keyed in-progress run and asserts Phase 5 waits,
      and asserts the fallback command does not contain `--force-local-reconcile`; red control:
      the pre-fix lookup against the same fake returns empty.
- [ ] `test/gh645-merge-cleanup-xyz-tools.sh`, which currently pins the forced-flag behaviour, is
      updated to the new contract and stays green.
- [ ] `skills/merge-cleanup/SKILL.md` Phase 5 text matches the shipped behaviour.
- [ ] `bash validate.sh` exits 0.
- [ ] `test/gh534_phase_c_tests.py::TestCScript::test_hosted_run_is_waited_for_and_fast_forwarded_before_emission` (GH-629) stays green: with that test's existing fake `gh run list` response shape, the new lookup still classifies the hosted run as active and `run_local_wave_reconcile` is NOT called (marathon attempt 1 on 2026-09-22 called it once and failed the gate). Read the test's fake before changing the query/match logic.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "\"--branch\", integration_branch, \"--commit\", merged_head"
    },
    {
      "type": "grep_present",
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "r_cmd\\.append\\(\"--force-local-reconcile\"\\)"
    },
    {
      "type": "path_absent",
      "path": "test/gh674-merge-cleanup-hosted-lookup.sh"
    }
  ],
  "artifacts": [
    "skills/merge-cleanup/scripts/merge_cleanup.py",
    "skills/merge-cleanup/SKILL.md",
    "test/gh645-merge-cleanup-xyz-tools.sh",
    "test/gh674-merge-cleanup-hosted-lookup.sh",
    "validate.sh"
  ],
  "artifacts_new": [
    "test/gh674-merge-cleanup-hosted-lookup.sh"
  ],
  "remediation": {
    "source": "issue#674",
    "criteria": "Key the hosted-run lookup on the PR head, drop --force-local-reconcile from the auto fallback, pin with a fake-gh test"
  },
  "lanes": {
    "agy_safe": [
      "skills/merge-cleanup/scripts/merge_cleanup.py",
      "skills/merge-cleanup/SKILL.md",
      "test/gh645-merge-cleanup-xyz-tools.sh",
      "test/gh674-merge-cleanup-hosted-lookup.sh"
    ],
    "orchestrator_only": [
      "validate.sh"
    ]
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
