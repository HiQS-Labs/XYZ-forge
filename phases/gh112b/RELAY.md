# Marathon Phase gh112b
STATUS: Open
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH112B-TURN builder=codex reviewer=agy round-cap=4 -->

## Phase Brief

---
gh_issue: 112
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112
title: "GH-112 follow-up: close the #134 drift in the opt-in Python layer (utils/py) so it stays a faithful mirror of Bash"
status: captured 2026-07-05, rated — independent (utils/py) lane, marathon-ready
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: bugfix
goal: >
  The opt-in Python layer (XYZ_PYTHON=1) was extracted from a PRE-#134 snapshot of the shell
  scripts, so it is missing three of #134's reliability fixes. Port those three into the Python
  twins so the layer is a coherent, current mirror of Bash — closing the known drift while it is
  still small (before a future default-flip inherits the debt). Containment stays out of scope by
  construction: GH-107's fix lives in relay-turn-lib.sh, which the Python path already inherits via
  rtl.py, so this lane touches only non-containment orchestration logic.
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - NOT flipping the default to Python — this only keeps the opt-in layer honest; the default stays Bash (decisions/2026-07-04-python-port-boundary.md)
  - NOT re-implementing containment in Python — GH-107's tool-cache exemption is in relay-turn-lib.sh (the permanent Bash boundary) and is inherited via rtl.py; a test asserts inheritance rather than porting it
  - NOT porting marathon.sh's GH-116 --retry — marathon.sh has no Python twin (was never in the ported set), so it stays Bash and is unaffected by XYZ_PYTHON=1
  - NOT changing any default-mode (Bash) behavior — validate.sh must stay byte-for-byte green in default mode
related:
  - utils/py/codex-turn.py
  - utils/py/marathon_drive.py
  - utils/py/swarm_preflight.py
  - test/test_python_layer.py
  - validate.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Sized the #134 drift against the Python twins (2026-07-05): GH-107 containment is inherited free via rtl.py→relay-turn-lib.sh; only GH-106 / GH-117 / GH-108 (~80 lines, non-containment) need porting; GH-116 is N/A (no twin). Light-medium, so queued rather than deferred. | Build the three ports + Python-mode parity tests, and wire `pytest` into `validate.sh` so the Python layer is actually gated by the canonical suite. |

## Problem (grounded in the current code)

The Python layer under `utils/py/` was extracted file-level from `origin/GH-112-python-port`, whose
shell scripts predate PR #134. Three of #134's fixes therefore exist in Bash but not in the Python
twins that `XYZ_PYTHON=1` routes to:

1. **GH-106** (`742c230`, `relay-automation/codex-turn.sh`) — non-interactive-safe default
   `CODEX_FLAGS` (adds `-c approval_policy=never` so a headless codex turn does not hang on
   approvals). `utils/py/codex-turn.py` still defaults to the old `-s workspace-write` only.
2. **GH-117** (`b4e73df`, `relay-automation/marathon-drive.sh`) — probe the builder/reviewer
   binaries **before** any `tick` state mutation, so a `--dry-run` (or a missing binary) can't
   half-seed the token. Absent from `utils/py/marathon_drive.py`.
3. **GH-108 bundle** (`691848c`, `utils/swarm-preflight.sh`) — gate-scoping caveat + GH-126
   genuine-ref check + GH-127 bare-`>` redirect detection. Absent from `utils/py/swarm_preflight.py`.

**Inherited, NOT in scope:** GH-107 (`524d345`) adds the `CONTAINMENT_IGNORE` tool-cache exemption
to `rtl_worktree_end` in `relay-automation/relay-turn-lib.sh`. Python never reimplements that
function — it shells into it through `rtl.py` — so the exemption is already live in Python mode. The
DoD asserts this by test rather than porting it.

## Acceptance criteria — the build is DONE when these hold

- [ ] `utils/py/codex-turn.py` default `CODEX_FLAGS` matches the post-#134 Bash default (includes `approval_policy=never`), with a `GH-106` marker comment at the change site.
- [ ] `utils/py/marathon_drive.py` probes builder/reviewer binaries before mutating tick state (matching `marathon-drive.sh`'s GH-117 behavior), with a `GH-117` marker comment.
- [ ] `utils/py/swarm_preflight.py` carries the GH-108/126/127 gate-scoping + genuine-ref + bare-`>` logic (matching `swarm-preflight.sh`), with a `GH-108` marker comment.
- [ ] `test/test_python_layer.py` gains a behavioral parity test for **each** ported fix (GH-106/117/108), run against the Python module.
- [ ] `test/test_python_layer.py` also asserts GH-107's containment exemption is honored in Python mode (proving inheritance via `rtl.py` — do NOT reimplement GH-107).
- [ ] `validate.sh` runs `python3 -m pytest test/test_python_layer.py` as part of the suite, so the Python layer is gated going forward (today it is exercised by neither `validate.sh` nor CI).
- [ ] `python3 -m pytest test/test_python_layer.py` is green AND `validate.sh` is green in default mode (no Bash-path regression); `relay-turn-lib.sh` is untouched and `XYZ_PYTHON` is NOT flipped to default.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "python3 -m pytest test/test_python_layer.py -q",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/codex-turn.py", "pattern": "GH-106" },
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "GH-117" },
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "GH-108" }
  ],
  "artifacts": [
    "utils/py/codex-turn.py",
    "utils/py/marathon_drive.py",
    "utils/py/swarm_preflight.py",
    "test/test_python_layer.py",
    "validate.sh"
  ],
  "remediation": "Port three PRE-#134 gaps into the opt-in Python twins so utils/py mirrors Bash. (1) GH-106: in utils/py/codex-turn.py, change the default CODEX_FLAGS to match relay-automation/codex-turn.sh's post-#134 default (include `-c approval_policy=never`); add a `GH-106` marker comment. (2) GH-117: in utils/py/marathon_drive.py, probe the builder AND reviewer binaries (shutil.which / equivalent) BEFORE any tick-state mutation, mirroring relay-automation/marathon-drive.sh; fail early if missing; add a `GH-117` marker comment. (3) GH-108: in utils/py/swarm_preflight.py, add the gate-scoping caveat + GH-126 genuine-ref check + GH-127 bare-`>` redirect detection from utils/swarm-preflight.sh; add a `GH-108` marker comment. Then add one behavioral parity test per fix to test/test_python_layer.py (assert the Python module reproduces the Bash behavior), plus one test asserting GH-107's containment exemption is honored in Python mode via rtl.py (do NOT reimplement GH-107). Finally, wire `python3 -m pytest test/test_python_layer.py` into validate.sh so the Python layer is gated. Do NOT change any default-mode Bash behavior; validate.sh must stay green in default mode. Do NOT flip XYZ_PYTHON to default. Do NOT touch relay-turn-lib.sh.",
  "lanes": {
    "python_safe": ["utils/py/codex-turn.py", "utils/py/marathon_drive.py", "utils/py/swarm_preflight.py", "test/test_python_layer.py", "validate.sh"],
    "orchestrator_only": [],
    "note": "Single independent lane. Write-set is the three Python twins + their test + the validate.sh pytest hook — disjoint from any Bash entry script and from relay-turn-lib.sh (untouched)."
  }
}
```

## How to fire

```
utils/swarm-preflight.sh --project-doc PROJECT/2-WORKING/GH-112-PYTHON-134-PARITY.md
relay-automation/marathon-drive.sh ...   # build→gate→review, contained, ALLOW_PATHS = the artifacts above
```

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/codex-turn.py,utils/py/marathon_drive.py,utils/py/swarm_preflight.py,test/test_python_layer.py,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH112B-TURN --agent codex --paths "phases/gh112b/RELAY.md,utils/py/codex-turn.py,utils/py/marathon_drive.py,utils/py/swarm_preflight.py,test/test_python_layer.py,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH112B-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH112B-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh112b/RELAY.md and utils/py/codex-turn.py,utils/py/marathon_drive.py,utils/py/swarm_preflight.py,test/test_python_layer.py,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/codex-turn.py,utils/py/marathon_drive.py,utils/py/swarm_preflight.py,test/test_python_layer.py,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH112B-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH112B-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh112b/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex
Files touched: `utils/py/marathon_drive.py`, `utils/py/swarm_preflight.py`, `test/test_python_layer.py`, `validate.sh`, `phases/gh112b/RELAY.md`

- `utils/py/codex-turn.py` already carried the GH-106 default `CODEX_FLAGS` + marker comment, so I left the code path intact and added an explicit parity test instead of rewriting it.
- Added the GH-117 preflight binary probes to `utils/py/marathon_drive.py` so missing builder/reviewer CLIs fail before any clean-workspace scan or tick mutation.
- Added GH-108/126/127 helper logic to `utils/py/swarm_preflight.py`: genuine artifact-reference detection, bare-`>` fs-touch detection, and the emitted gate-scoping caveat / packet scope text that depends on those helpers.
- Extended `test/test_python_layer.py` with focused parity coverage for GH-106, GH-117, GH-108, plus a GH-107 inheritance assertion through `rtl.py`.
- Wired `python3 -m pytest test/test_python_layer.py` into `validate.sh`; I did not run full `validate.sh` because this phase explicitly forbids the full gate.

Verification:
- `python3 -m pytest test/test_python_layer.py` (`13 passed`)
