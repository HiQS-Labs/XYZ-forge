---
gh_issue: 703
source: https://github.com/HiQS-Labs/XYZ-forge/issues/703
title: "releases: `roadmap add` inline raw_text bypasses validate_raw_text — a title with a bare `*` produces a row the renderer drops and B1 replay refuses"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-22
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/80 · calc 290"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  `releases roadmap add` can no longer write a ledger row its own grammar rejects on replay: a
  title with a bare `*` is either refused at intake or rendered and replayed cleanly.
---

# GH-703 — releases: `roadmap add` inline raw_text bypasses validate_raw_text — a title with a bare `*` produces a row the renderer drops and B1 replay refuses

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`utils/py/releases_app.py:3568` builds the inline `- **GH-%d · %s** …` fallback straight from
`--title` without calling `validate_raw_text()` (only the `--raw-text` path at `:3565` validates),
while the bullet grammar at `:3516`/`:4232` forbids `*` inside the bold title. `roadmap render` then
drops the row and merge-cleanup B1 (`ledger_merge.py:300`) refuses the replay. Reproduced at HEAD by
inspection; no fix commit or PR references #703.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] One of the issue's two fix options is implemented and named in this doc: (1) the inline fallback
      in `roadmap add` runs `validate_raw_text()` and refuses with a clear message, or (2) the
      bullet grammar in `validate_raw_text()` and `roadmap_render()` both allow a lone `*` that
      is not part of `**`, with `_without_rating`/`parse_rating` unaffected.
- [ ] A registered test (new `test/gh703-raw-text-asterisk.sh`, added to `validate.sh`): `roadmap add
      --title 'a/*/b'` with no `--raw-text` either refuses (option 1) or produces a row that
      `roadmap render` keeps and `roadmap add --raw-text <stored>` re-accepts (option 2); red
      control demonstrates the pre-fix behaviour.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh703-raw-text-asterisk.sh` runs green both standalone and under `bash validate.sh`: the suite must source the shared helpers it calls (e.g. `test/_setup.sh`) or define its own `finish`/`pass`/`fail` (marathon attempt 1 on 2026-09-22 died with `line 69: finish: command not found`, rc 127). Run the new suite once before handing off.

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
      "type": "path_absent",
      "path": "test/gh703-raw-text-asterisk.sh"
    },
    {
      "type": "grep_absent",
      "path": "validate.sh",
      "pattern": "gh703"
    }
  ],
  "artifacts": [
    "utils/py/releases_app.py",
    "test/gh703-raw-text-asterisk.sh",
    "validate.sh"
  ],
  "artifacts_new": [
    "test/gh703-raw-text-asterisk.sh"
  ],
  "remediation": {
    "source": "issue#703",
    "criteria": "Make roadmap add's inline fallback consistent with validate_raw_text and pin it with a registered regression"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/releases_app.py",
      "test/gh703-raw-text-asterisk.sh"
    ],
    "orchestrator_only": [
      "validate.sh"
    ]
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
