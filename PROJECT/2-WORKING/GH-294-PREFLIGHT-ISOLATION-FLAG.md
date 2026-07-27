---
title: swarm-preflight's suggested marathon-drive invocation omits RELAY_WORKTREE_ISOLATION=1
status: "Active (2-WORKING) — promoted 2026-07-26 after reproducing the gap in a freshly generated packet. Preflight contract below is LIVE and safe to fire."
created: 2026-07-26
updated: 2026-07-26
owner: noel
gh_issue: 294
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/294
doc_type: bugfix
complexity: 2
risk: 3
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - The orchestrator's own branch management for a marathon run. This covers the
    per-turn containment half only; the branch half is a separate follow-up.
  - Changing RELAY_WORKTREE_ISOLATION's own default in the shims. Fix what the
    packet EMITS, not the underlying default.
related:
  - "#292, #274, #278 — co-scheduled lanes in the same marathon."
goal: >
  Every packet swarm-preflight emits suggests an invocation that is contained by
  default, so an operator copying the suggested command verbatim gets per-turn
  worktree isolation instead of an unconstrained headless builder against ROOT.
---

# GH-294 — preflight's suggested invocation omits `RELAY_WORKTREE_ISOLATION=1`

## Status
| What was just completed | What's next |
|---|---|
| **2026-07-26: reproduced against a freshly generated packet and promoted with a live contract.** Generated `relay-system/preflight/2026-07-27/gh-292-worktree-vendored-discovery/` today; its `marathon-invocation.txt` contains no `RELAY_WORKTREE_ISOLATION` — the same gap the issue found across five packets from 2026-07-22/23, still present at `development` @ `8d89616`. Confirmed **both** twins are affected: `utils/swarm-preflight.sh` and `utils/py/swarm_preflight.py` each carry the `XYZ_HARNESS_CONTEXT=swarm` template and neither mentions the flag. Sequenced **first** in the marathon so later lanes inherit a contained invocation. | Fire the contract below. Fix both twins together — a one-sided fix reproduces the py/sh drift class that GH-278 exists to remove. |

## Symptom

The `INVOCATION` template (`utils/swarm-preflight.sh` ~819-825, mirrored in the Python twin) emits:

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=$SLUG $_DRIVE_CMD \
  --phase-brief <packet>/packet.md --reviewer agy --builder codex \
  --artifact $ART_CSV --pre-advance-cmd '$GATE_CMD' --require-clean
```

`RELAY_WORKTREE_ISOLATION` defaults **off**. `--require-clean` only checks the workspace is clean
*before* the run — it provides no isolation *during* it. An operator copying the packet's own
suggested command verbatim therefore runs every turn directly against ROOT with no per-turn
containment.

## Why it matters

`GUIDING-PRINCIPLES.md` §3 names worktree isolation as one of three non-negotiable containment
mechanisms, citing live incidents (GH-13, GH-14, GH-17). A preflight contract whose own suggested
invocation omits it is one careless copy-paste from an unconstrained headless builder in the real
repo. The operator has asked that all marathons run in their own worktrees; this is the
preflight half of that.

## Reproduction (today, not historical)

```bash
bash utils/swarm-preflight.sh --gh-issue 292
grep -c RELAY_WORKTREE_ISOLATION \
  relay-system/preflight/2026-07-27/gh-292-worktree-vendored-discovery/marathon-invocation.txt
# -> 0
```

**Frequency:** every packet, both twins.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "RELAY_WORKTREE_ISOLATION" },
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "RELAY_WORKTREE_ISOLATION" }
  ],
  "artifacts":   [
    "utils/swarm-preflight.sh",
    "utils/py/swarm_preflight.py",
    "test/swarm-preflight.sh"
  ],
  "artifacts_new": [],
  "remediation": {
    "source":   "self#fix-direction",
    "criteria": "Both swarm-preflight twins emit RELAY_WORKTREE_ISOLATION=1 in the suggested marathon-drive invocation (marathon-invocation.txt AND packet.md). test/swarm-preflight.sh asserts the flag is present in the emitted invocation for the happy path, and asserts py/sh emit byte-identical invocations. No change to the shims' own RELAY_WORKTREE_ISOLATION default."
  },
  "lanes":       {
    "agy_safe":          [ "test/swarm-preflight.sh" ],
    "orchestrator_only": [ "bin/", ".tick/" ]
  }
}
```

## Phase 0 — Fix & lock it in

### Checklist
- [ ] Add `RELAY_WORKTREE_ISOLATION=1` to the `INVOCATION` template in the Bash implementation
- [ ] Make the identical change in `utils/py/swarm_preflight.py` — do not leave the twins divergent
- [ ] Check any other suggested-invocation generator (e.g. `utils/marathon-plan.sh`) for the same gap
- [ ] Assert the flag in `test/swarm-preflight.sh`'s happy-path packet check

### QA checklist — Phase 0
- [ ] Regenerating the #292 packet now yields an invocation containing the flag
- [ ] Bash and Python twins emit byte-identical invocations (parity asserted, not assumed)
- [ ] `bash validate.sh` green
