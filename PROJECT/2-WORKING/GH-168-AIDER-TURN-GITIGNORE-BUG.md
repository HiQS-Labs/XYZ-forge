---
gh_issue: 168
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/168
title: "aider-turn.sh: --no-gitignore doesn't enable reading gitignored files — missing --add-gitignore-files silently skips relay threads in gitignored dirs"
status: Queued (1-INBOX) — queued for today's marathon
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not a broader aider-flag audit — scoped to this one missing flag
related:
  - relay-automation/aider-turn.sh
roadmap_exempt: false
---

## Key concepts

- `--no-gitignore` (aider) only controls whether aider *writes* paths into `.gitignore` — it does
  not control whether aider can *read* files that are already gitignored. Reading gitignored files
  needs the separate flag `--add-gitignore-files`.
- `relay-automation/aider-turn.sh:170` passes `--no-gitignore` but never `--add-gitignore-files`.
- This repo's own `relay-system/` convention deliberately gitignores relay threads in some repos —
  any repo following that same pattern hits this wall: aider can't read the target relay file, and
  the model just asks for its content instead of failing loudly.
- Surfaced live via a relay run in a `.xyz`-vendored install (pdda repo); workaround for that run
  was `AIDER_FLAGS="--add-gitignore-files"`, which confirms the fix.

# GH-168 · aider-turn.sh missing --add-gitignore-files

## Status

| What was just completed | What's next |
|---|---|
| Queued into today's marathon build cluster (Marathon Plan E) as a small, single-file fix lane. | **Done.** Implemented fix in `aider-turn.sh`, added regression test, and verified with `validate.sh`. |

## The bug

`relay-automation/aider-turn.sh:170`:

```bash
aider_args=(--model "$AIDER_MODEL" --yes-always --no-auto-commits --no-gitignore
            --no-check-update --no-analytics --no-show-model-warnings --no-stream --map-tokens 0
            ...)
```

`--no-gitignore` alone does not let aider read gitignored files in this aider version — that
needs `--add-gitignore-files`, which is missing from the default flag set. Any repo that
gitignores its relay thread directory (this repo's own documented `relay-system/` pattern is one
such case) will have the turn's target file silently unreadable: no error, no non-zero exit — the
model just asks for the file's content, and the turn produces nothing useful.

## Fix direction

Add `--add-gitignore-files` alongside the existing `--no-gitignore` in the default `aider_args`
(`aider-turn.sh:170`), so this works out of the box for any repo that gitignores its relay
threads, without every caller needing to discover and set `AIDER_FLAGS` themselves.

## Phase 0 — Fix and regression-test

### Checklist

- [x] Add `--add-gitignore-files` to the default `aider_args` in `aider-turn.sh:170`.
- [x] Add/extend a test that stages a gitignored target file and confirms aider can read it with
      the default flags (no `AIDER_FLAGS` override needed).
- [x] Confirm no behavior change for repos that don't gitignore their relay threads (flag is inert
      when nothing is gitignored).

### QA checklist — Phase 0

- [x] The fix is the minimal one-line flag addition, not a broader aider-flag refactor.
- [x] The regression test reproduces the original failure mode (gitignored target file silently
      unreadable) before the fix, and passes after.
- [x] `test/*.sh` covering `aider-turn.sh` stays green.


## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"README.md","pattern":"THIS_WILL_NEVER_MATCH"}],"artifacts":["relay-automation/aider-turn.sh","test/aider-turn.sh"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
