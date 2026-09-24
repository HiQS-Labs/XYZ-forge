---
gh_issue: 651
source: https://github.com/HiQS-Labs/XYZ-forge/issues/651
title: "test(gh610): mock CLI shebang breaks with a spaced Python path"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-21
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/60 · calc 270"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  test/gh610-claude-subscription.sh's mock CLI fixture launches the selected interpreter safely
  when its path contains spaces.
---

# GH-651 — test(gh610): mock CLI shebang breaks with a spaced Python path

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`test/gh610-claude-subscription.sh:91` and `:148` write executable fixtures whose first line is
`'#!'+sys.executable`; a direct-interpreter shebang cannot carry a path with spaces, so
`test_real_probe_and_consult_dispatch` fails at the mock auth preflight with `subscription auth
status not verified` — not evidence of a real login problem. Reproduces by construction at HEAD
(`python3 -m venv "$fixture_root/with spaces"`); no commit or PR references #651.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] The fixture launcher in `test/gh610-claude-subscription.sh` invokes the exact selected
      interpreter safely when its path contains spaces (e.g. a correctly quoted shell launcher
      that execs `"$PYTHON" "$0.py" "$@"`); the auth validator is not relaxed and no different
      Python is substituted silently.
- [ ] A non-empty path-with-spaces regression is added and the current direct-path red control is
      retained; both spaced and ordinary interpreter paths pass the existing suite with no live
      account/API calls.
- [ ] The change is confined to the gh610 fixture (the GH-646 status feature and the sibling suites
      with the same pattern are out of scope).
- [ ] `bash validate.sh` exits 0.

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
      "path": "test/gh610-claude-subscription.sh",
      "pattern": "'#!'\\+sys\\.executable"
    }
  ],
  "artifacts": [
    "test/gh610-claude-subscription.sh"
  ],
  "remediation": {
    "source": "issue#651",
    "criteria": "Quote the mock-CLI fixture's interpreter launcher so a spaced Python path works; add the spaced-path regression"
  },
  "lanes": {
    "agy_safe": [
      "test/gh610-claude-subscription.sh"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
