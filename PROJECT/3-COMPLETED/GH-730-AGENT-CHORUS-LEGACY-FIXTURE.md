---
title: pre-push gate red on test/agent-chorus.sh in any clone with a leftover skills/agent2agent/__pycache__ — legacy-symlink assertion reads clone state, not a fixture
status: Complete
created: 2026-09-21
owner: agent-b
gh_issue: 730
source: https://github.com/HiQS-Labs/XYZ-forge/issues/730
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
reported_from: XYZ-forge primary clone (while landing GH-720 / PR #729)
harness_commit: bd8c6950   # origin/development at task start
non_goals:
  - Broadening skills/agent-chorus/install.sh to treat a tracked-file-less legacy dir as gone (the issue's item 2 — a test's problem must not widen the installer)
  - A gate-side "ghost directory" detector or auto-clean of ignored leftovers in operator clones
  - Setting PYTHONDONTWRITEBYTECODE in every script entry point (ordinary CLI runs may still write bytecode; .gitignore already covers it and no test depends on its absence any more)
related:
  - GH-193 (Phase 0 rename that left the ignored shell behind)
  - GH-458 / GH-463 (earlier false reds on the same assertion — path spelling, not clone state)
  - GH-682 (relay shims already set PYTHONDONTWRITEBYTECODE for reviewer turns)
  - GH-720 / PR #729 (the push the red gate blocked)
goal: >
  test/agent-chorus.sh passes on every clone regardless of what ignored leftovers the clone
  carries, and a gate run stops manufacturing the leftovers in the first place.
---

# GH-730 — agent-chorus legacy-symlink assertion coupled to clone state; gate runs write bytecode into the tree

> **1-INBOX capture** for a fix carried on its own branch. Simple change (two files, no design
> decision) — plan relay QA skipped per start-task Step 6; final Codex relay QA applies.

## Symptom
`git push` from the operator's primary clone was refused by the pre-push gate after 1099s with
exactly one red suite, `agent-chorus.sh`, and this assertion:

```text
FAIL: legacy symlink not repointed (now -> '<clone>/skills/agent2agent', which is not the same directory as '<clone>/skills/agent-chorus')
```

The same suite on a pristine `origin/development` checkout is 215/0.

## Root causes (two, both deterministic)

1. **The fixture was the clone.** `test/agent-chorus.sh:713` built the "dangling" legacy link as
   `ln -s "$REPO/skills/agent2agent"`. `skills/agent-chorus/install.sh:24-30`
   (`migrate_legacy_link`) repoints only when the target no longer exists. On any clone where
   `skills/agent2agent/` still exists — as an ignored, zero-tracked-file shell — the installer
   correctly declines to touch a live link and the assertion fails. The assertion's precondition
   lived in the clone's untracked state, not in a fixture the test controls.

2. **Gate runs create the ghosts.** Suites import repo modules directly (`importlib` at
   `test/agent-chorus.sh:437`, the `unittest` files under `test/`), and every such import wrote
   `__pycache__/` under `skills/*/scripts` and `utils/py`. Those caches are gitignored, so they
   outlive the rename or removal of the directory that held them. The primary clone carried two
   such ghosts: `skills/agent2agent/scripts/__pycache__/` (Aug 22) and
   `skills/skills-sync-trinity/scripts/__pycache__/`. The relay shims already set
   `PYTHONDONTWRITEBYTECODE=1` for reviewer turns (GH-682); the gate did not.

## Fix (surgical, extends what exists)

| Surface | Change |
|---|---|
| `test/agent-chorus.sh:713` | Fixture link targets `$WORK/pre-rename-clone/skills/agent2agent` — a path the suite never creates, so it is dangling by construction. Still ends in `/skills/agent2agent`, which is what the installer's `case` arm matches. |
| `relay-automation/gate-env.sh` | `export PYTHONDONTWRITEBYTECODE=1` — the shared gate prologue `validate.sh:12` already sources (the GH-441 single registry for gate environment), so every suite in every gate mode inherits it. Its scratch names are now all `_ge_`-prefixed and unset (it clobbered a caller's `_src`/`_hp_lib` — Codex round-1 finding). |
| `ci-local.sh` | Sources `gate-env.sh` after `HERE` (round-1 Blocker): the qualifying runner launches suites and pytest directly and never sourced the prologue — so it was also missing the GH-441 scrub. |
| `test/gh441-gate-env-contract.sh` | C7a: `ci-local.sh` sources the helper. C8a: sourcing sets `PYTHONDONTWRITEBYTECODE=1` and preserves a caller's `_src`/`_hp_lib`. Both red against the pre-fix files. |

Rejected (Out of Scope / Ponytail): setting the variable inside `marathon_drive._gate_env()` for an
explicit `--pre-advance-cmd`. The documented contract (`gate-env.sh:2-3`) already makes a custom gate
source the helper itself, and the default gate resolves to `validate.sh`; a second writer for gate
environment is the defect GH-441 replaced.

Issue item 3 (print the failing line in the refusal block) is already served:
`validate.sh:1345-1346` tails the last 40 lines of the failing suite's serial re-run before the
`failed:` summary. No change.

## Surveyed and clean
- Installers with legacy logic: `skills/agent-chorus/install.sh` (fixed fixture) and
  `skills/releases/install.sh` (removes legacy symlinks unconditionally — no dependence on a
  repo path existing).
- Tests linking a `$REPO` path expected to be absent: only the one at `test/agent-chorus.sh:713`.
  `test/test_deploy_skills.py:548` checks `skills/skills-sync-trinity/SKILL.md`, a tracked file,
  not the directory — unaffected by the ghost.

## Acceptance (all run on this branch, unsandboxed per GH-177)
- [x] Red control: clean clone + `mkdir -p skills/agent2agent/scripts/__pycache__` → `agent-chorus: 214 pass, 1 fail` (the reported assertion)
- [x] After fix, same clone state → `215 pass, 0 fail`; ghost removed → `215 pass, 0 fail`
- [x] Red control for the changed assertion: installer's `ln -sfn` repoint disabled → `214 pass, 1 fail` on the same assertion (it still detects a non-repointing installer); installer restored
- [x] `. relay-automation/gate-env.sh && bash test/agent-chorus.sh` → 215/0 and **zero** `__pycache__` directories under `skills/ test/ utils/` afterwards
- [x] `test/gh441-gate-env-contract.sh` → 18 pass, 0 fail (C7a/C8a red against the pre-fix `ci-local.sh` / `gate-env.sh`)
- [ ] Full `./validate.sh` green through the pre-push gate on the final commit
- [x] Final Codex relay QA: Approved, round 2 (`relay-system/2026-09-21/gh730-final-qa-codex.md`, reviewed-head 2ef7850a)

## Ratings (RELEASES, 2026-09-21)
`rated 70/70/50/95`. **sev 70:** deterministic gate red on every push from an affected clone;
recoverable (`rm -rf` the ghost) but it normalises `--no-verify`, which is the gate's own
failure mode. **pri 70:** severity-led; the operator's primary clone is affected and it blocked
a landing today. **appeal 50:** neutral, no operator preference given. **effort 95:** two-line
fix, focused suites already green. **Recurrence:** third false red on this one assertion
(GH-458, GH-463 on path spelling; this one on clone state) — 2026-09-07..21 window: 1 incident
(this); prior 14 days: 0 on this assertion. Same class (test keyed on clone state) — no other
instance found in the survey above.

## Operator follow-up (not in this PR)
The primary clone's `skills/agent2agent` ghost was moved to the session scratchpad on
2026-09-21; `skills/skills-sync-trinity/scripts/__pycache__/` is still there and is now
harmless — `rm -rf skills/skills-sync-trinity` when convenient (zero tracked files).
