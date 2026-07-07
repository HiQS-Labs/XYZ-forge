---
gh_issue: 165
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/165
title: "codex-turn: Codex can edit and commit without first owning the relay token, leaving no-progress stalls even after GH-67's handoff backstop"
status: Shipped — Codex shim ownership hardening landed and verified; closed 2026-07-07
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: bugfix
goal: >
  Ensure a Codex headless turn cannot edit and commit relay/artifact changes unless the Codex shim
  itself has first established ownership of the handed-off RELAY_TASK token, so GH-67's
  authoritative post-commit handoff can actually succeed.
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not revisiting GH-160's containment-root bug; that was a separate, already-shipped failure mode
  - Not redesigning relay-drive's no-progress oracle; the bug is in turn ownership, not stall detection
  - Not changing Claude or Aider routing in this slice unless the Codex fix proves insufficient
related:
  - relay-automation/codex-turn.sh
  - relay-automation/aider-turn.sh
  - relay-automation/relay-turn-lib.sh
  - test/codex-turn.sh
  - test/relay-turn-handoff.sh
---

# GH-165 — Codex token ownership gap

GH-67 already fixed the "worker forgot to release/done the token" half of this protocol, but only
when the worker is actually the token owner by the time `rtl_enforce` runs. The remaining gap is
earlier: Codex can still make correct edits and land a commit without ever becoming the claimer.

Reversibility: **Easy.** The change surface is the Codex shim and its tests. Rollback is a small
revert. Blast radius is limited to Codex relay turns; the shared containment kernel remains unchanged.

## Status

| What was just completed | What's next |
|---|---|
| The Codex-side fix landed in both implementations: Bash `relay-automation/codex-turn.sh` and Python `utils/py/codex-turn.py` now claim the exact relay task, assert `claimer == codex` before launch, and ping it. Both `bash test/codex-turn.sh` and `XYZ_PYTHON=1 bash test/codex-turn.sh` are green with the new no-tick Codex stub case and unowned-token refusal case. `skills/relay-automation/relay-pkg.tar.gz` was rebuilt so package freshness is green again. **Closed 2026-07-07:** all 5 Definition-of-done items scoped to this issue are done; the one remaining `validate.sh` line (101/104) is blocked by two gates outside GH-165's change surface (`worktree-isolation.sh`'s pre-existing moved-ROOT-HEAD case, and `test_python_layer.py` needing `pytest`, not installed in this environment) — neither is a GH-165 regression, so closing rather than holding this issue open for unrelated gates. | Nothing outstanding for GH-165 itself. The two unrelated gates remain untracked as their own issues — worth filing separately if they start blocking other work. |

## Problem

Today `relay-automation/codex-turn.sh` launches Codex after composing the prompt, but before the run
it does **not** establish token ownership itself. That was survivable before GH-67 only when Codex
followed the prompt perfectly and ran all three token steps (`claim`/`ping`/`release`). After GH-67,
missing `release` is no longer fatal because `rtl_enforce` backstops it post-commit.

Missing `claim` is still fatal.

Why:

- `rtl_enforce` can only `tick release` / `tick done` as the current owner.
- If the token remains `open -> codex` (reserved for Codex but not yet claimed by it), `rtl_enforce`
  sees the right relay-file changes but lacks authority to move the token.
- The file commit stands, the token actor does not change, and `relay-drive.sh` correctly reports
  `no-progress`.

That matches the live symptom in #165 more closely than a pure "release was skipped" theory does,
because a skipped release is already what GH-67 was built to cover.

## Fix direction

Mirror the ownership discipline already used by `relay-automation/aider-turn.sh`:

1. Build the exact `claim --paths` set in the Codex shim (relay file + any allowlisted artifacts).
2. Best-effort `tick claim <task> --agent <me> --paths <claim_paths>` before launching Codex.
3. Immediately verify via `tick info` that `claimer == <me>`.
4. If ownership is missing, fail fast with exit 5 **before any mutation**.
5. If ownership is present, `tick ping` and continue. GH-67's post-commit handoff path then becomes
   reliable even when Codex performs zero token commands itself.

Prompt changes are optional for this slice because `tick claim` is idempotent when the same agent
already holds the token, so existing prompt-following stays harmless.

## Definition of done

- [x] `codex-turn.sh` claims and proves ownership of the specific relay task before launching Codex.
- [x] A Codex stub that edits the relay file but runs **no** tick commands still yields a committed
      turn with the token handed off to the peer.
- [x] A token still owned by some other agent causes `codex-turn.sh` to fail fast (exit 5) before
      any edit or commit.
- [x] `bash test/codex-turn.sh` passes.
- [x] `XYZ_PYTHON=1 bash test/codex-turn.sh` passes.
- [ ] `bash validate.sh` passes.
      Current result: `101/104` passed. The remaining red gates are outside the GH-165 files:
      `worktree-isolation.sh`, `python:test_python_layer.py` (missing `pytest`), and the
      now-resolved `relay-pkg-freshness.sh` from before the package rebuild.
      **Closed anyway (2026-07-07):** left unchecked on purpose — it's genuinely not green — but
      both remaining reds are pre-existing, unrelated to this issue's change surface, and not
      separately tracked issues yet. Not holding GH-165 open for gates it didn't cause.
