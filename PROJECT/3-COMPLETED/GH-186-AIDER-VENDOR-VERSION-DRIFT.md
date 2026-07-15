---
gh_issue: 186
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/186
title: "aider-turn.sh: --add-gitignore-files removal (775380c) unverified against vendored installs on older aider — risk of silently reopening GH-168"
status: Shipped — merged to `main` via PR #188 (2026-07-09); #186 closed. validate.sh green
created: 2026-07-08
updated: 2026-07-10
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not a broader aider-flag audit — scoped to this one flag's version sensitivity
related:
  - relay-automation/aider-turn.sh
  - PROJECT/3-COMPLETED/GH-168-AIDER-TURN-GITIGNORE-BUG.md
  - PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-E-BUILD.md
goal: >
  Make relay-automation/aider-turn.sh's gitignored-relay-file handling resilient to aider CLI
  version drift across vendored .xyz installs, instead of hardcoding behavior observed on one
  local aider-chat version.
roadmap_exempt: false
---

## Key concepts

- GH-168's original fix added `--add-gitignore-files` to `aider-turn.sh` because a **vendored**
  install (pdda repo, running its own pinned `.xyz/relay-automation/aider-turn.sh` copy) needed it
  to read gitignored relay threads on the aider version in play there.
- Commit `775380c` (2026-07-08) dropped that same flag again, because it no longer exists in
  aider-chat 0.82.3 (the version installed locally in this repo) and hard-fails argparse before
  aider even starts. That fix was verified **only against local aider-chat 0.82.3**.
- Vendored `.xyz/` copies (tracked via `relay-automation/xyz-sync.sh list`) are pinned, not
  auto-updated — a vendored copy only picks up harness changes via an explicit `xyz-sync.sh
  update`. Any vendored consumer that re-syncs to `775380c`-or-later while still running an older
  aider where `--add-gitignore-files` is still required would silently reopen GH-168's exact
  failure mode: no error, no exit code signal, just a turn that quietly does nothing useful.
- `775380c`'s own justification rests on an empirically observed but undocumented aider behavior
  on 0.82.3 (`--no-gitignore` + explicit `--file <path>` warns but still adds the file) — not a
  documented CLI contract, so it isn't guaranteed stable across aider versions either.

# GH-186 · aider-turn.sh vendored-install version drift on the gitignore fix

## Status

| What was just completed | What's next |
|---|---|
| **Built and Approved 2026-07-09** via a codex-builder/agy-reviewer marathon relay (`MARATHON-GH186-TURN`, 2 rounds). Codex added runtime detection of `--add-gitignore-files` support (probes `aider --help`), extended `test/aider-turn.sh` case 13 to cover both old-aider and current-aider scenarios; agy's round 1 review found a real, separate pre-existing bug (`ALLOW_PATHS` env leakage breaking Case 12) which codex fixed in round 2 by expanding `test/_setup.sh`'s scrubber; agy Approved round 2 ("all 44 test cases passed, including the previously failing Case 12"). Both review rounds hit the same detector false positive (filed as [#187](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/187), a second instance of GH-183's pattern) and required manual commit recovery — verified against the raw transcripts before recovering, not just trusted. `bash test/aider-turn.sh` 44/0; `bash validate.sh` green except 2 confirmed pre-existing/unrelated failures (`acorn-extract.sh` — missing `node_modules`, this clone never ran `npm install`; `test_python_layer.py` — missing `pytest`). Sits on local branch `marathon/gh-186-aider-vendor-version-drift-2026-07-09`, not yet pushed/PR'd. | Operator call: push the branch and open a PR (or merge directly). |

## The bug

`relay-automation/aider-turn.sh` now hardcodes the *absence* of `--add-gitignore-files`, just as it
previously hardcoded the flag's *presence* — both times tuned to whatever aider version was
installed locally at the time, with no version check and no fallback for vendored installs running
a different aider. This is the second time this exact code path has broken from an unpinned
aider-version assumption.

## Fix direction

- Detect aider's actual flag support at runtime (e.g. grep `aider --help` for
  `--add-gitignore-files`) and conditionally include it, so the shim degrades gracefully across
  aider versions instead of assuming one.
- Or: document/enforce a minimum aider-chat version for this harness and have `aider-turn.sh` fail
  loudly (not silently) if the installed aider is below it.
- Extend `test/aider-turn.sh` case 13 (the GH-168 regression case) to cover both scenarios.

## Phase 0 — Version-safe flag handling and regression-test

### Checklist

- [x] Add runtime detection (or an explicit version guard) for `--add-gitignore-files` support in
      `aider-turn.sh`.
- [x] Extend the GH-168 regression test (`test/aider-turn.sh` case 13) to assert correct behavior
      under both an old-aider (flag required) and current-aider (flag absent) scenario.
- [x] Confirm `bash test/aider-turn.sh` stays green with no behavior change for the common case.

### QA checklist — Phase 0

- [x] The fix makes the flag decision version-aware, not a re-hardcode in either direction.
- [x] The regression test would have caught both GH-168 (flag missing, needed) and this issue
      (flag present, no longer valid) had it existed before either fix.
- [x] No regression in `test/aider-turn.sh`'s existing cases.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"README.md","pattern":"THIS_WILL_NEVER_MATCH"}],"artifacts":["relay-automation/aider-turn.sh","test/aider-turn.sh"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
