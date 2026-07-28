---
title: "Marathon pre-advance gate silently passes on any repo path containing a space"
status: "Active (2-WORKING) — found 2026-07-28 while verifying the 4-lane gate-and-fleet-integrity marathon. Fix + regression test landed on branch marathon/gate-and-fleet-integrity-2026-07-28 (PR #318); promote to 3-COMPLETED on merge."
created: 2026-07-28
updated: 2026-07-28
owner: unassigned
gh_issue: 319
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/319
doc_type: bugfix
complexity: 1
risk: 5
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Editing relay-automation/marathon-drive.sh — GH-308 froze it in this same PR; the Bash fallback's identical defect is documented, not silently patched.
  - Redesigning how the default gate is chosen or configured.
  - Auditing or re-running historical marathons whose "gate passed" is now suspect.
related:
  - utils/py/marathon_drive.py (default gate construction + runnability preflight)
  - relay-automation/marathon-drive.sh:493 (frozen Bash twin, same defect)
  - test/gh319-gate-path-with-space.sh
goal: >
  A marathon phase can never report "gate passed" without the configured gate having actually run,
  regardless of what characters appear in the repository's filesystem path.
---

# GH-319 — the marathon gate word-splits a spaced repo path and passes on the wrong file

## Status

| What was just completed | What's next |
|---|---|
| Found while verifying the 4-lane `MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY` run by direct inspection rather than trusting its exit code. Root cause reproduced in isolation; `shlex` fix + `test/gh319-gate-path-with-space.sh` landed and registered in `validate.sh`. Test demonstrated **failing** against pre-fix code (4 pass / 2 fail) and **passing** after (6 pass / 0 fail). | Merge PR #318, then promote this doc to `3-COMPLETED`. The frozen Bash twin's identical defect is tracked as a follow-on under GH-308 Phase 2. |

## Symptom

All four phases logged `STATUS: Approved, gate passed` while `bash validate.sh` on the identical
tree was **RED** (`relay-pkg-freshness`, `skill-extract` — both real, both caused by GH-308's
banners drifting `relay-pkg.tar.gz`).

The timing was the tell. `.tick/events/`:

| Phase | `agy-done` → `marathon.phase.approved` |
|---|---|
| `gh311-validate-pdda-contract` | 7.5 s |
| `gh308-freeze-bash-twins` | 6.6 s |

A real `validate.sh` on this machine takes **483 s** (`/usr/bin/time -p`). Seven seconds is the
transcript commit, not a test suite.

## Mechanism

`utils/py/marathon_drive.py` built the default gate as an unquoted string and handed it to a shell:

```python
pre_advance_cmd = args.pre_advance_cmd or f"bash {root}/validate.sh"   # pre-fix
...
subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash", ...)
```

At `.../Documents/GH Repos/xyz-3-agents-swarm` the shell word-splits on the space and runs
`bash $HOME/Documents/GH` with `Repos/.../validate.sh` as a positional argument.

**`$HOME/Documents/GH` exists as an unrelated 0-byte file.** Executing an empty script
exits 0 immediately, with no output to make the substitution visible.

## Why the guard that exists for exactly this did not fire

GH-238 added `_preflight_pre_advance_gate()` to prove the gate is *runnable* before spending a
builder and reviewer turn. It extracted the script argument with `^\s*(bash|/\S*/bash)\s+(\S+)`,
which captured the same wrong fragment — and `os.path.isfile("$HOME/Documents/GH")`
returned `True`. **The runnability check and the gate agreed on the wrong file.** The preflight even
carried quote-stripping logic for a quoted script argument the default never produced.

This is the third instance of one failure class in this program — after GH-315 (a stale relay token
made a build-nothing run report success) and the sandboxed-Monitor liveness gap folded into GH-284
Phase 2: **a broken observation layer where failure is invisible and every available signal agrees.**

## Fix

1. `shlex.quote` the default gate path.
2. Replace regex extraction in the preflight with `shlex.split`, so the runnability check inspects
   the file the shell would actually execute. Falls back to naive `.split()` only on unbalanced
   quotes, which the adjacent `bash -n` syntax check already rejects.
3. `test/gh319-gate-path-with-space.sh`, registered in `validate.sh`.

The test builds its fixture at a path with a space **and plants the same 0-byte decoy at the split
point**, so a regression cannot hide behind a split prefix that happens not to exist.

## Proof

Against pre-fix code, with a fixture `validate.sh` that exits 1:

```
marathon-drive: relay approved — running pre-advance gate: bash .../GH Repos/target/validate.sh
marathon-drive: phase p1 complete — STATUS: Approved, gate passed
  FAIL: gate never ran the real validate.sh — the path split again (rc=0)
  FAIL: expected exit 5 for a failing gate, got 0
  gh319-gate-path-with-space: 4 pass, 2 fail
```

Post-fix: **6 pass / 0 fail**, driver exits 5 (`pre-advance-failed`).

## Residual risk (stated, not fixed)

`relay-automation/marathon-drive.sh:493` has the identical construction. GH-308 froze that file in
this same PR and AGENTS.md now directs behavior fixes to the Python twin, so it is **left
unpatched deliberately**: an `XYZ_PYTHON=0` run at a spaced path still has a fake gate. Tracked as a
follow-on for GH-308 Phase 2 (twin retirement).

Historical marathon runs on this machine that reported "gate passed" are retroactively unverified.
No audit of them is planned.
