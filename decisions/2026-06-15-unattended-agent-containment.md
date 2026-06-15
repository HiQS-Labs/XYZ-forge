---
status: Decided
date: 2026-06-15
reversibility: Costly
revisit: "first real unattended Option-A run (no live window) — if any off-lane change reaches a commit or a push, reopen"
related:
  - decisions/2026-06-15-relay-turns-tick-native.md
decider: "@noelsaw1"
---

# Containment for an unattended committing agent = path-allowlist + commit-bypass guard + no-push

**Decision:** The safety boundary for a headless agent that takes relay turns and commits
(`relay-automation/codex-turn.sh`) is three enforced invariants, owned by the shim (not the
supervisor): (1) a **path allowlist** — revert + fail on any change outside {relay file,
artifact allowlist}; (2) a **commit-bypass guard** — snapshot `before_head`, `reset --hard` +
fail if the agent committed during its turn; (3) **no push** — commit file-scoped, leave
pushing to a separate human step. This is accepted as *sufficient* containment to let an
unattended agent commit to the working branch.

**The bet:** These three invariants close every path by which an off-lane or unreviewed change
could reach shared history without a human in the loop. If a real unattended run finds a fourth
escape (e.g. ignored-file damage, a `.git` edit, an `--no-verify` trick, a symlink), the bet is
wrong and the boundary needs another guard.

**Rejected:**
- *Raw `--agent-cmd` string as the turn-taker* — no place to enforce safety; Codex's own review
  flagged it as too brittle. The shim exists precisely to be that place.
- *Supervisor (`relay-drive.sh`) owns the clean-tree gate* — rejected; the shim owns it, so the
  boundary lives with the thing that runs the agent.
- *`git clean -Xdf` to also wipe ignored files* — rejected; it would destroy `.tick/` (the
  gitignored coordination state the turn legitimately writes). Ignored-file safety is deferred
  to the codex sandbox (`-c sandbox_permissions`) instead.

**Expected signal:** A real unattended Option-A run (a runner/service, no live window) completes
a multi-turn relay with **zero** off-allowlist changes reaching a commit or push — on the event
that run first happens, not a fixed date.

**Reversibility:** Costly — the contract is wired into `codex-turn.sh` + `test/codex-turn.sh`
(16 assertions) + the packaged skill tarball; changing it touches all three plus any agent-drive
shim that adopts it (e.g. a future `gemini-drive.sh`).

**Revisit trigger:** The first real unattended run (above). Also reopen immediately if any
adopting shim (Codex or Gemini) is observed letting an off-lane change through in a live turn.

## Updates
<!-- append-only, newest last -->
- 2026-06-15 — Recorded. Boundary is **3-model validated**: Claude authored the shim, Codex
  (headless review) added the allowlist + no-push contract, Gemini (manual `/relay`, 3rd model)
  found + cleared two bypasses *through* it — git-commit-bypass and quoted-path — and Approved
  the fixes (r3). `test/codex-turn.sh` 10→16, `validate.sh` 20/20. Strong early signal, but the
  "sufficient for unattended" bet stays **Decided** (not Validated) until a real no-window run.
- 2026-06-15 — Generalization in progress: **Gemini is building its own `gemini-drive.sh`** (a
  sibling turn-taker for itself, same role as `codex-turn.sh`). It should adopt these three
  invariants; if it does and behaves, that's corroborating evidence — if it lets an off-lane
  change through, that fires the revisit trigger.
- 2026-06-15 — **Corroborating evidence (2nd model adopted the boundary, live).** Refactored the
  three invariants into a shared sourced core (`relay-automation/relay-turn-lib.sh`); `codex-turn.sh`
  + a new `gemini-drive.sh` are thin wrappers over it. A **real `gemini -p` turn** (gemini-cli 0.46.0,
  GCA auth) took a relay review turn through `gemini-drive.sh`: edited only the relay file, committed
  file-scoped, no push, and **left the reviewed artifact untouched** — containment held for a second
  independent model. `test/gemini-drive.sh` 13/13, `validate.sh` 21/21. Bet still **Decided** (this
  was a single *supervised* turn, not a real multi-turn *unattended* run). Live run also surfaced a
  prompt-clarity gap (peer agent unnamed → released to a role name) — fixed with optional `RELAY_PEER`.
