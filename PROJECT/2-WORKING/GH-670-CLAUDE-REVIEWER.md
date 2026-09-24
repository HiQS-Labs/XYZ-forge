---
gh_issue: 670
source: https://github.com/HiQS-Labs/XYZ-forge/issues/670
title: "Marathon: support explicitly selected Claude CLI reviewers instead of Codex/Agy-only restriction"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-22
owner: unassigned
doc_type: capture
complexity: 3
risk: 2
effort: 3
rating: "pri/sev/appeal/effort 60/60/90/60 · calc 270"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  A marathon plan may name an explicitly selected Claude CLI reviewer; YAML validation and the
  driver accept it through the existing Claude adapter while keeping builder/reviewer identity,
  reviewer-only write scope, attestation and CLI availability checks.
---

# GH-670 — Marathon: support explicitly selected Claude CLI reviewers instead of Codex/Agy-only restriction

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

Three lockstep copies of the eligibility gate hard-reject anything that is not `codex*`/`agy*`:
`bin/marathon-yaml:100`, `src/marathon-yaml.js:117-118`, and `utils/py/marathon_drive.py:2022-2023`
— while `route_agent`/`_probe_agent_bin` and `relay-automation/marathon-agent.sh:79` already route a
`claude` adapter (`claude-turn.sh` / `claude-turn.py`). Tests pin the rejection at `test/marathon-
yaml.sh:88-91`, `test/marathon.sh:123`, `test/gh346-gateway-allowlists.sh:327-332`,
`test/gh373-reviewer-validation.sh:35`. No commit or PR references #670.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] Claude reviewer IDs (`claude`, `claude-*`) are accepted by both YAML validation (`bin/marathon-
      yaml`, `src/marathon-yaml.js`) and the marathon driver (`utils/py/marathon_drive.py`),
      dispatched through the existing Claude adapter; the builder/reviewer must still be
      distinct identities.
- [ ] Reviewer-only write scope, approval attestation, and the CLI availability check are preserved
      for a Claude reviewer (no bypass, no renaming Claude as Codex).
- [ ] A registered regression (new `test/gh670-claude-reviewer.sh`, added to `validate.sh`) covers
      plan parsing, `--dry-run`, and dispatch with an Agy builder + Claude reviewer, including
      model/effort propagation; the four tests that pin the old rejection are updated to the new
      contract and stay green.
- [ ] `HARNESS-MODELS-REGISTRY.md` records Claude as an eligible reviewer with its flags.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh346-gateway-allowlists.sh` stays green, in particular check #6: widening the reviewer gate to `claude*` in `bin/marathon-yaml` and `src/marathon-yaml.js` must still reject the phantom `gemini` reviewer, and the literal string `gemini` must not appear outside a comment in either file (marathon attempt 1 on 2026-09-22 failed `#6 ... still admits the phantom 'gemini' reviewer outside a comment` in both). Run the suite before handing off.

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
      "path": "bin/marathon-yaml",
      "pattern": "must start with codex or agy"
    },
    {
      "type": "grep_present",
      "path": "utils/py/marathon_drive.py",
      "pattern": "args\\.reviewer\\.startswith\\(\"codex\"\\) or args\\.reviewer\\.startswith\\(\"agy\"\\)"
    },
    {
      "type": "path_absent",
      "path": "test/gh670-claude-reviewer.sh"
    }
  ],
  "artifacts": [
    "bin/marathon-yaml",
    "src/marathon-yaml.js",
    "utils/py/marathon_drive.py",
    "test/marathon-yaml.sh",
    "test/marathon.sh",
    "test/gh346-gateway-allowlists.sh",
    "test/gh373-reviewer-validation.sh",
    "test/gh670-claude-reviewer.sh",
    "validate.sh",
    "HARNESS-MODELS-REGISTRY.md"
  ],
  "artifacts_new": [
    "test/gh670-claude-reviewer.sh"
  ],
  "remediation": {
    "source": "issue#670",
    "criteria": "Accept an explicitly selected Claude reviewer in marathon-yaml + the driver via the existing adapter; regression with agy builder + claude reviewer"
  },
  "lanes": {
    "agy_safe": [
      "src/marathon-yaml.js",
      "utils/py/marathon_drive.py",
      "test/marathon-yaml.sh",
      "test/marathon.sh",
      "test/gh346-gateway-allowlists.sh",
      "test/gh373-reviewer-validation.sh",
      "test/gh670-claude-reviewer.sh",
      "HARNESS-MODELS-REGISTRY.md"
    ],
    "orchestrator_only": [
      "validate.sh",
      "bin/marathon-yaml"
    ]
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.

## Merge evidence

- PR #753 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
