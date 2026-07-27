---
title: aider-turn per-turn timeout drift (py 300s / sh 600s / docs 900s) commits 0-byte artifacts
status: "Active (2-WORKING) — promoted 2026-07-26 after re-confirming all three values still disagree at development. Preflight contract below is LIVE and safe to fire."
created: 2026-07-26
updated: 2026-07-26
owner: noel
gh_issue: 278
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/278
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Per-turn artifact-count guidance / auto-fan for multi-file lanes (issue finding 1).
    Real, but a separate design change — not this lane.
  - Choosing a different builder or edit format. The drift is the defect; builder
    selection is not.
related:
  - "#294, #274, #292 — co-scheduled lanes in the same marathon."
  - "#268 — the lane whose Phase 1 surfaced this (nine 0-byte install.sh artifacts)."
goal: >
  One documented per-turn timeout value, identical in the Bash shim, the Python twin,
  and the skill doc, with a parity test that fails if they ever diverge again — and a
  killed turn that produced only empty artifacts is classified as no-progress rather
  than "artifacts appeared".
---

# GH-278 — `aider-turn` per-turn timeout drift

## Status
| What was just completed | What's next |
|---|---|
| **2026-07-26: re-confirmed unfixed at `development` @ `8d89616` and promoted with a live contract.** All three values still disagree — `utils/py/aider-turn.py` `int(os.environ.get("RELAY_TURN_TIMEOUT_S", 300))`, `relay-automation/aider-turn.sh` `turn_timeout="${RELAY_TURN_TIMEOUT_S:-600}"`, and `skills/relay-xyz/SKILL.md` documenting "default 900s". Python is the default runner (GH-264), so the **effective** cap is the shortest and the only undocumented one. Also confirmed there is no py/sh parity test in `test/` by name — which is why the drift was invisible. | Fire the contract below. Pick ONE value, apply to both twins and the doc, and add the parity assertion so this class cannot recur silently. |

## Symptom

A thinking-heavy aider builder was killed mid-generation at 300s. aider had pre-created its nine
`--file` targets as empty stubs at startup; the kill left them empty and **the harness committed
them** (`git show --stat` → nine `install.sh | 0`). The driver then reported *"declared artifact(s)
appeared — probing the pre-advance gate"*, and a gate that only runs `bash -n` passes 0-byte files
silently. The reviewer caught it — *"All nine artifacts exist only as zero-byte, non-executable
files… not reviewable"* — but the harness had already treated a killed turn as a productive one.

## Root cause — three-way drift

| Source | Default `RELAY_TURN_TIMEOUT_S` | Verified 2026-07-26 |
|---|---|---|
| `utils/py/aider-turn.py` (**runs** — Python default per GH-264) | **300s** | ✓ still 300 |
| `relay-automation/aider-turn.sh` | 600s | ✓ still 600 |
| `skills/relay-xyz/SKILL.md` | 900s | ✓ still documents 900 |

The value that applied is the shortest, is a third of what the docs promise, and is the one nobody
opted into.

## Second defect in scope: the empty-artifact escape

A turn killed by the timeout commits its empty stubs and is reported as having produced artifacts.
A declared artifact that is zero-byte or unchanged after a **killed** turn should be classified as
no-progress. Without this, the timeout fix alone still leaves a silent-corruption path whenever any
builder is killed for any reason.

## Reproduction

```bash
rg -n 'RELAY_TURN_TIMEOUT_S' utils/py/aider-turn.py relay-automation/aider-turn.sh
rg -n 'turn ceiling' skills/relay-xyz/SKILL.md
# three different defaults
```

**Frequency:** deterministic — it is a constant mismatch, not a race.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_present", "path": "utils/py/aider-turn.py", "pattern": "RELAY_TURN_TIMEOUT_S., 300" },
    { "type": "grep_present", "path": "relay-automation/aider-turn.sh", "pattern": "RELAY_TURN_TIMEOUT_S:-600" },
    { "type": "path_absent",  "path": "test/gh278-turn-timeout-parity.sh" }
  ],
  "artifacts":   [
    "utils/py/aider-turn.py",
    "relay-automation/aider-turn.sh",
    "skills/relay-xyz/SKILL.md",
    "test/gh278-turn-timeout-parity.sh",
    "validate.sh"
  ],
  "artifacts_new": [ "test/gh278-turn-timeout-parity.sh" ],
  "remediation": {
    "source":   "self#suggested-fixes",
    "criteria": "One documented default for RELAY_TURN_TIMEOUT_S, identical in utils/py/aider-turn.py, relay-automation/aider-turn.sh and skills/relay-xyz/SKILL.md. test/gh278-turn-timeout-parity.sh asserts the two shim defaults match each other and match the documented value, and is registered in validate.sh's TESTS array. Additionally: a declared artifact that is zero-byte or unchanged after a timeout-killed turn is classified as no-progress rather than 'artifacts appeared'."
  },
  "lanes":       {
    "agy_safe":          [ "test/gh278-turn-timeout-parity.sh", "skills/relay-xyz/SKILL.md" ],
    "orchestrator_only": [ "bin/", ".tick/" ]
  }
}
```

## Phase 0 — Reconcile & lock it in

### Checklist
- [ ] Pick ONE default (the documented 900s is the least surprising; state the choice explicitly)
- [ ] Apply it to both shims and the skill doc in the same change
- [ ] Add `test/gh278-turn-timeout-parity.sh` asserting shim↔shim↔doc agreement
- [ ] Register the test in `validate.sh`'s `TESTS=()` array — it will not run otherwise
- [ ] Classify zero-byte / unchanged declared artifacts after a killed turn as no-progress

### QA checklist — Phase 0
- [ ] The parity test fails before the fix and passes after (verify with `git stash`)
- [ ] A simulated killed turn leaving 0-byte artifacts is reported as no-progress, not "appeared"
- [ ] Raising the cap does not weaken the hung-CLI kill path (exit 7 still fires)
- [ ] `bash validate.sh` green, with the new test actually executing
