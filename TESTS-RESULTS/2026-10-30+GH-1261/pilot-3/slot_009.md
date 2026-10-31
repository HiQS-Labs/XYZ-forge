# Plan draft: #670 Marathon: support explicitly selected Claude CLI reviewers instead of Codex/Agy-only restriction

> draft; preflight and independent plan QA outstanding

- Request: `gh-670-406e69df557a` (tick `slot_009`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 60/60/90/60
- Capture doc: PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md (sha256 34c4f63515a53eabdfe4d684eea4074fae96ee215e799d51ba237b413476d2df)
- Issue sha256: 406e69df557afd8833ab4f090d335fa06092ad3fdc6883d50401d76ba9c5c9d8 (updated 2026-09-25T01:19:04Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:L17 (frontmatter goal)_

A marathon plan may name an explicitly selected Claude CLI reviewer; YAML validation and the driver accept it through the existing Claude adapter while keeping builder/reviewer identity, reviewer-only write scope, attestation and CLI availability checks.

## Acceptance criteria

_Source: PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:L40 (Acceptance)_

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
- [ ] `bash test/gh346-gateway-allowlists.sh` stays green, in particular check #6: widening the reviewer gate to `claude*` in `bin/marathon-yaml` and `src/marathon-yaml.js` must still reject the phantom `gemini` reviewer, and the literal string `gemini` must not appear outside a comment in either file (marathon attempt 1 on 2026-09-22 failed `#6 ... still admi

## Open questions

_missing_

## Write set

- `bin/marathon-yaml` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `src/marathon-yaml.js` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `utils/py/marathon_drive.py` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `test/marathon-yaml.sh` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `test/marathon.sh` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `test/gh346-gateway-allowlists.sh` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `test/gh373-reviewer-validation.sh` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `test/gh670-claude-reviewer.sh` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `validate.sh` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)
- `HARNESS-MODELS-REGISTRY.md` (PROJECT/2-WORKING/GH-670-CLAUDE-REVIEWER.md:preflight-contract)

## Unresolved file names

- none

## Existing preflight contract

```json
{
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
  "fix_probes": [
    {
      "path": "bin/marathon-yaml",
      "pattern": "must start with codex or agy",
      "type": "grep_present"
    },
    {
      "path": "utils/py/marathon_drive.py",
      "pattern": "args\\.reviewer\\.startswith\\(\"codex\"\\) or args\\.reviewer\\.startswith\\(\"agy\"\\)",
      "type": "grep_present"
    },
    {
      "path": "test/gh670-claude-reviewer.sh",
      "type": "path_absent"
    }
  ],
  "gate": "bash validate.sh",
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
  },
  "remediation": {
    "criteria": "Accept an explicitly selected Claude reviewer in marathon-yaml + the driver via the existing adapter; regression with agy builder + claude reviewer",
    "source": "issue#670"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
