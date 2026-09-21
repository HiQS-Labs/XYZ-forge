---
gh_issue: 740
source: https://github.com/HiQS-Labs/XYZ-forge/issues/740
title: "wave-reconcile.yml: the final fast-forward push is rejected whenever a merge lands during the ~70-min run — the whole green qualification is thrown away (#733 during #731's run)"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-21
owner: unassigned
doc_type: capture
complexity: 3
risk: 3
effort: 3
rating: "pri/sev/appeal/effort 75/75/70/45 · calc 265"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  wave-reconcile.yml's final fast-forward push survives a merge landing during the run: the push
  step is an extracted script with a bounded retry-with-rebuild, and a failure names the racing
  landing instead of a bare [rejected].
---

# GH-740 — wave-reconcile.yml: the final fast-forward push is rejected whenever a merge lands during the ~70-min run — the whole green qualification is thrown away (#733 during #731's run)

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`.github/workflows/wave-reconcile.yml:100-103` does a bare `git push origin HEAD:development` with
no fetch/retry; the workflow's concurrency group serialises runs, not merges, so any landing during
the ~70-minute run rejects the push and fails the job. Build Option 1 only (retry-with-rebuild):
extract the push step's Python into `utils/py/wave_reconcile_push.py` that the workflow calls; keep
the exact allowlist; on a rejected push, `git fetch origin development`, replay the doc moves +
receipts onto the new head, regenerate the ledger via `releases check --rebuild`, retry a bounded
number of times, and otherwise fail naming the racing landing. No fix commit or PR references #740.

## Acceptance
- [ ] Fixture replay in a disposable clone: run the extracted push-step script, land an unrelated commit on the target branch before the push, and the step **completes** (pushed on top of the new head; `releases check` clean, trio consistent) or **refuses with a message naming the racing landing** — never a bare `[rejected]`.
- [ ] Red control: the pre-fix step against the same fixture reproduces the rejection.
- [ ] No force-push, no rebase of `releases.db` bytes, artifact allowlist unchanged (a planted undeclared file is still refused).
- Exit condition for the class (shared with #732 D.2 / #293): **10 consecutive green scheduled + PR-closed runs**.

## Acceptance — deviations from the issue

The issue states its acceptance as plain bullets; each is carried below as a checkbox with the wording
unchanged so the preflight packet inlines it as the builder's definition of done.

- [added] Fixture replay in a disposable clone: run the extracted push-step script, land an unrelated commit on the target branch before the push, and the step **completes** (pushed on top of the new head; `releases check` clean, trio consistent) or **refuses with a message naming the racing landing** — never a bare `[rejected]`. — reason: issue states this criterion as a plain bullet; carried as a checkbox, wording unchanged, so the packet carries it as the builder's definition of done
- [added] Red control: the pre-fix step against the same fixture reproduces the rejection. — reason: issue states this criterion as a plain bullet; carried as a checkbox, wording unchanged, so the packet carries it as the builder's definition of done
- [added] No force-push, no rebase of `releases.db` bytes, artifact allowlist unchanged (a planted undeclared file is still refused). — reason: issue states this criterion as a plain bullet; carried as a checkbox, wording unchanged, so the packet carries it as the builder's definition of done

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
      "path": ".github/workflows/wave-reconcile.yml",
      "pattern": "git\\('push', 'origin', 'HEAD:development'\\)"
    },
    {
      "type": "path_absent",
      "path": "utils/py/wave_reconcile_push.py"
    },
    {
      "type": "path_absent",
      "path": "test/gh740-reconcile-push-race.sh"
    }
  ],
  "artifacts": [
    ".github/workflows/wave-reconcile.yml",
    "utils/py/wave_reconcile_push.py",
    "test/gh740-reconcile-push-race.sh",
    "validate.sh"
  ],
  "artifacts_new": [
    "utils/py/wave_reconcile_push.py",
    "test/gh740-reconcile-push-race.sh"
  ],
  "remediation": {
    "source": "issue#740",
    "criteria": "Extract the reconcile push step into a script with bounded retry-with-rebuild; fixture replay proves completion-or-named-refusal"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/wave_reconcile_push.py",
      "test/gh740-reconcile-push-race.sh"
    ],
    "orchestrator_only": [
      ".github/workflows/wave-reconcile.yml",
      "validate.sh"
    ]
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
