---
gh_issue: 174
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/174
title: "GH-171 follow-up: utils/py/agy-turn.py never got a claim-before-launch guard (XYZ_PYTHON=1 agy turns still exposed)"
status: Fixed and verified 2026-07-17 via a marathon lane, merged to `development`.
created: 2026-07-07
updated: 2026-07-17
owner: noel
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not a broader Bash/Python parity audit — scoped to this one guard
related:
  - relay-automation/agy-turn.sh
  - utils/py/agy-turn.py
  - utils/py/codex-turn.py
  - PROJECT/3-COMPLETED/GH-165-CODEX-TOKEN-OWNERSHIP.md
goal: >
  Port the claim-before-launch ownership guard that relay-automation/agy-turn.sh gained in GH-171's
  fix (commit b00ee48, branch fix/gh-171-chain-root-cause) into utils/py/agy-turn.py, which never
  had one — leaving XYZ_PYTHON=1 agy (reviewer) turns exposed to the same no-progress symptom
  GH-165/GH-171 fixed for the Bash default and for Python's own codex-turn.py.
roadmap_exempt: false
---

## Key concepts

- Found live during code review of GH-171's fix: `relay-automation/agy-turn.sh` gained a new
  claim-before-launch block (claim the handed-off task, verify `claimer == agy`, exit 5 on
  mismatch) in the same commit that fixed GH-171's tick-bin resolution bug — a deliberate,
  reasoned scope expansion (the reviewer side has the identical exposure once you look at it).
- `utils/py/agy-turn.py` has zero matches for `claim`/`tick_bin` — it never had an equivalent
  guard, before or after that commit. It DID get the `TICK_REPO_ROOT`-preservation half of the fix
  (the worktree-isolation overwrite bug), just not the ownership guard.
- `utils/py/codex-turn.py` already has its own claim-before-launch logic (from GH-165) and was
  correctly parity-fixed for tick-bin resolution in the same GH-171 commit — this gap is specific
  to the Python agy port, not a general Python-mode problem.
- Lower severity than GH-171 itself: `XYZ_PYTHON` is opt-in, less used than the Bash default, and
  this only affects the reviewer role in Python mode.

# GH-174 · agy-turn.py claim-before-launch guard

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via a marathon lane (worktree-isolated Sonnet subagent, `marathon/gh174-215-222-189-2026-07-17`). Added case `(18a) GH-174: agy-turn.py claim-before-launch guard regression (XYZ_PYTHON=1)` to `test/marathon-drive.sh`, asserting a `task.claimed` event with `agent":"agy"` lands in the consumer repo's `.tick/events` under `XYZ_PYTHON=1`, mirroring the GH-171 Bash-mode assertion. No source change (confirmed already-correct per the 2026-07-17 note below). Independently re-verified on the marathon branch after merge: `bash test/marathon-drive.sh` 106/106, zero regressions. | Closed out — nothing further for this lane. |

## The bug

`relay-automation/agy-turn.sh` (Bash, canonical) now claims its handed-off task and verifies
ownership before launching `agy`, exiting 5 if ownership can't be established — this closes the
same "edited/committed without ever owning the token" gap GH-165 closed for Codex. `utils/py/
agy-turn.py` (the Python port, opt-in via `XYZ_PYTHON=1`) has no such block at all, so a
Python-mode agy turn can still edit/commit review feedback without claiming the token, leaving
GH-67's post-commit handoff backstop without authority to release/hand off — apparent
`no-progress`, same symptom class as GH-165/GH-171.

## Fix direction

Port the claim/verify/ping block from `relay-automation/agy-turn.sh` (post-GH-171) into
`utils/py/agy-turn.py`, following the same `TICK_BIN` env override → pinned-root `bin/tick` if it
exists → harness-local `bin/tick` fallback resolution `utils/py/codex-turn.py` already uses (mirror
its `claim_paths_for_turn`-adjacent logic and the claim/info/exit-5/ping sequence in `main()`).

## Phase 0 — Port and regression-test

### Checklist

- [x] Add the claim-before-launch block to `utils/py/agy-turn.py`'s `main()`, using the same
      `TICK_BIN`/pinned-root/harness-local resolution order as `utils/py/codex-turn.py`. → landed via
      GH-172 Phase 0, commit `7e9e683` (`claim_task_or_exit(...)` call confirmed live in `main()`).
- [ ] Extend the GH-171 vendored-consumer fixture in `test/marathon-drive.sh` (or add a dedicated
      python-mode variant) to run the full chain with `XYZ_PYTHON=1` and confirm the reviewer's
      claim event lands in the consumer repo's `.tick`, mirroring the existing Bash-mode GH-171
      assertions. **← remaining work for this lane.**
- [x] Confirm `XYZ_PYTHON=1 bash test/agy-turn.sh` green. → green except the pre-existing, unrelated
      `genuine breach should exit 5, got 0` failure (reproduces identically on pre-GH-172 `fafa890`).

### QA checklist — Phase 0

- [ ] The new regression test passes and specifically proves the agy-leg claim event lands under
      `XYZ_PYTHON=1` — not just that the suite is green overall.
- [ ] No regression in existing Bash-mode or Python-mode `codex-turn`/`agy-turn`/`marathon-drive`
      suites.
- [x] `python3 -m py_compile utils/py/agy-turn.py` clean (verified as part of GH-172 Phase 0).

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon-drive.sh",
  "fix_probes": [ { "type": "grep_absent", "path": "test/marathon-drive.sh", "pattern": "GH-174: agy claim event lands" } ],
  "artifacts": [ "test/marathon-drive.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist item 2 in this doc (the regression test)" },
  "lanes": { "agy_safe": [ "test/marathon-drive.sh" ], "orchestrator_only": [] }
}
```
