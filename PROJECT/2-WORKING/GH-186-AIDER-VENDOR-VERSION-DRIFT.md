---
gh_issue: 186
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/186
title: "aider-turn.sh: --add-gitignore-files removal (775380c) unverified against vendored installs on older aider — risk of silently reopening GH-168"
status: Active (2-WORKING) — promoted for firing via Marathon Plan E's follow-up lane
created: 2026-07-08
updated: 2026-07-08
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
  - PROJECT/2-WORKING/GH-168-AIDER-TURN-GITIGNORE-BUG.md
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
| Filed 2026-07-08 while reviewing `775380c`; queued into Marathon Plan E as a follow-up lane to GH-168 (same file). Not yet built. | Fire the lane: add runtime detection of `--add-gitignore-files` support (or a documented minimum-version guard) to `aider-turn.sh`, and extend the GH-168 regression test to cover both an old-aider and current-aider flag-support scenario. |

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

- [ ] Add runtime detection (or an explicit version guard) for `--add-gitignore-files` support in
      `aider-turn.sh`.
- [ ] Extend the GH-168 regression test (`test/aider-turn.sh` case 13) to assert correct behavior
      under both an old-aider (flag required) and current-aider (flag absent) scenario.
- [ ] Confirm `bash test/aider-turn.sh` stays green with no behavior change for the common case.

### QA checklist — Phase 0

- [ ] The fix makes the flag decision version-aware, not a re-hardcode in either direction.
- [ ] The regression test would have caught both GH-168 (flag missing, needed) and this issue
      (flag present, no longer valid) had it existed before either fix.
- [ ] No regression in `test/aider-turn.sh`'s existing cases.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"README.md","pattern":"THIS_WILL_NEVER_MATCH"}],"artifacts":["relay-automation/aider-turn.sh","test/aider-turn.sh"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
