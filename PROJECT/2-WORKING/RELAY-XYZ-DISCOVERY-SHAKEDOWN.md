---
complexity: low
risk: low
effort: low
ratings_provisional: true
title: relay-xyz discovery shakedown — why other VS Code sessions can't find the skill
slug: relay-xyz-discovery-shakedown
status: Active
created: 2026-06-21
updated: 2026-06-21
owner: Noel (operator) · Claude (auditor)
branch: main
related:
  - skills/relay-xyz/SKILL.md            # the audited skill
  - skills/relay-xyz/find-harness.sh     # the bundled locator (proven green)
  - skills/relay-xyz/install.sh          # the fix added by this audit
  - docs/relay-history/relay-xyz-skill-review.md
non_goals:
  - Not importing the shakedown skill into this repo — it lives in the Giant Brains library; here it is only the lens.
  - Not reorganizing the giant-brains-claude-skills clones or repointing unrelated skills without sign-off.
goal: >
  Audit, through the shakedown lens (static path audit + live scenario matrix), why relay-xyz's files
  are reported "not found" in other VS Code sessions, separate the real root cause from the suspected
  one, and apply the safe in-scope fixes. Outcome: the script locator is already robust; discovery
  rots one layer above it, on a single hand-made symlink — now made reproducible via install.sh.
---

## Status

| What was just completed | What's next |
|---|---|
| Discovery layer: shakedown lens → locator GREEN, root-caused symlink-only discovery, shipped `install.sh` + anchored the verify-block. Drive layer: a sibling-agent headless run exposed two cracks — fixed both: space-safe `--agent-cmd` dispatch (no more `eval` split on `…/GH Repos/…`) + worktree isolation defaulted ON for driven runs (closes the rogue-model containment gap). Suite green except a pre-existing `runner-loop.sh` failure (reproduces with these changes stashed; unrelated). | Operator decision on the one remaining flagged item: repair the two dangling `consult`/`wpcc` symlinks. (The `GitHub-Repos` "clone split" was a misread — it was a symlink alias to `GH Repos`; alias now deleted, 20 skill symlinks repointed.) Optional follow-ups: minor #4a/#4b (role-vs-model assertion; per-run RELAY-TURN id). |

> **Lens, not import.** Methodology borrowed from the Giant Brains `shakedown` skill; that skill stays
> in its library. This doc is the native deliverable, written to `PROJECT/2-WORKING/` per the operator
> (not to shakedown's default `SHAKEDOWN/` folder).

---

# 🔧 Shakedown — relay-xyz — 2026-06-21 18:12 PDT

**Target:** relay-xyz (`skills/relay-xyz/`, symlinked into the user skills dir)
**Target HEAD:** `33d8946` — Doc updates and relay transcripts
**Env:** Darwin 24.6.0 arm64 · bash 3.2 (macOS default)
**Verdict:** 🚧 **discovery failure is real and root-caused — but NOT where it was suspected.** The
script *locator* (`find-harness.sh`) is ✅ green under every foreign condition tested. The failure is
one layer up, at **skill discovery**: relay-xyz is reachable only through a single hand-made absolute
symlink that a fresh clone never gets and that silently rots (two sibling links are dangling right
now). Fixed for new clones by `install.sh`; residual cross-skill hygiene flagged below.

## The signature failure (restated)

The shakedown signature is "works in the session that wrote it, 'No such file or directory' in another
session." Here the symptom is reported one notch earlier than usual: not "the script isn't found" but
"the *skill* isn't found." That distinction is the whole finding — the locator can only help **after**
Claude Code has loaded the SKILL.md, and the failure is **upstream of that**.

## Static audit

Script-path hygiene inside `SKILL.md`, graded:

- **Locator loop** (`find-harness.sh` discovery + `--env`/`--check`) — ✅ all anchors are `$HOME`-,
  CWD-, or git-root-relative; no machine path hardcoded. `find-harness.sh` self-locates with a
  symlink-safe `cd -P` walk and resolves the harness via override → git-root → its-own-real-location.
- **Path A driver** (`relay-drive.sh` + `codex-turn.sh`/`agy-turn.sh`) — ✅ anchored: invoked after
  `cd "$HARNESS"` and `tick` is called by the absolute `$TICK`. CWD drift is tolerated.
- **Path B poll** (`poll.sh` under `/loop`) — ✅ but only because the section explicitly tells each
  window to run the Preconditions block / `cd` into `$HARNESS` first.
- **Verify block** (`validate.sh`, `test/codex-turn.sh`, `test/agy-turn.sh`) — ⚠️ **was** CWD-relative
  with no restated `cd "$HARNESS"` precondition → would 404 from a foreign session. **Fixed** in this
  audit (now `bash "$HARNESS/validate.sh"` etc.).
- **Bundled-script hygiene** — ✅ `find-harness.sh` and the new `install.sh` both carry the
  `BASH_SOURCE` self-location block, are bash-3.2-safe, and have the execute bit set.

## Live harness

Run A — invoke the locator as installed (`~/.claude/skills/relay-xyz/find-harness.sh`, a symlink into
this clone) from a matrix of conditions. All foreign CWDs were created under a sandbox-writable temp
root so the `cd`s were genuine (an earlier run silently fell back to the repo CWD when `mktemp`
in `/var/folders` was sandbox-blocked — a reminder that a "green" can be an un-run test):

| Scenario | Result | Resolved harness root |
|---|---|---|
| A. Control — CWD = harness repo | ✅ exit 0 | harness repo |
| B. Foreign non-git CWD | ✅ exit 0 | harness repo |
| C. Foreign **git** repo CWD (another VS Code project) | ✅ exit 0 | harness repo |
| D. Spaces in foreign CWD | ✅ exit 0 | harness repo |
| E. SKILL.md locator loop verbatim, `XYZ_HARNESS` unset, from foreign git repo | ✅ exit 0 | harness repo |
| F. Clone with `relay-system/` but **no** `relay-automation/` (portable `/relay` only) | ✅ exit 0 | harness repo |

**Run A is uniformly green.** The locator's symlink-resolution (move 3: "…/skills/relay-xyz → repo
root") correctly walks back through the user-dir symlink to the real harness clone every time. So the
*documented script-discovery command is CWD-robust on this machine* — the suspected culprit is sound.

## Root cause — the layer the locator can't reach

What is **not** robust is skill discovery itself:

```text
~/.claude/skills/relay-xyz  ->  /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skills/relay-xyz
```

1. **The repo's skills live in top-level `skills/`, which Claude Code does not scan.** It scans project
   `.claude/skills/` and user `~/.claude/skills/`. relay-xyz is discoverable **only** because that one
   user-level symlink exists. `git ls-files` tracks `SKILL.md` + `find-harness.sh` — nothing tracked
   recreates the symlink.
2. **A fresh clone / other machine has no symlink → the skill is invisible in every session there.**
   That is the literal "other VS Code sessions not finding the files" report. It reproduces
   deterministically on any clone that never ran the manual `ln -s`.
3. **The mechanism silently rots — and already has.** Two sibling user-skill symlinks are dangling
   *right now*, proving the model fails quietly (full paths in the block below). relay-xyz resolves
   today, but it is one `mv`/rename away from joining them.

```text
consult -> …/GH Repos/xyz-3-agents-swarm/skill/consult   (DANGLING: repo has skills/, plural)
wpcc    -> …/wp-code-check/skills/wpcc                    (DANGLING: target missing)
```
4. **Repo-root naming — RETRACTED (auditor misread), since resolved.** Skill symlinks referenced both
   `Documents/GH Repos/` and `Documents/GitHub-Repos/` — but `GitHub-Repos` was a **symlink alias →
   `GH Repos`** (one physical directory, verified `pwd -P`), not a second clone, so there was never any
   divergence. The original "clone split" finding was wrong (recorded for honesty — the byte-identical
   `.git` should have been the tell). Cleanup applied 2026-06-21: the alias was deleted and the 20 skill
   symlinks repointed straight at `GH Repos`, removing the crutch.

## Fixes applied (in scope)

1. **`skills/relay-xyz/install.sh`** — idempotent, self-locating, no hardcoded path. Symlinks this
   clone's `skills/relay-xyz` into `~/.claude/skills/`, replaces a stale/dangling link, refuses to
   clobber a real dir, then verifies `find-harness.sh` resolves. One command makes any clone
   discoverable — the durable fix for #1/#2. Smoke-tested: idempotent re-run + harness verify pass.
2. **`SKILL.md` verify-block anchored** to `$HARNESS/…` (was CWD-relative) — closes the one in-file
   path that would 404 from a foreign session.
3. **`SKILL.md` "First-time setup" section** added above Preconditions, pointing at `install.sh` and
   naming the "skills live in top-level `skills/`, Claude Code doesn't scan it" trap explicitly.

## Drive-layer hardening (from a sibling-agent headless run)

A sibling Claude Code agent drove a real Path-A relay against this harness from a *foreign clone*
(codex reviewer, agy producer). It independently confirmed the discovery layer holds —
`find-harness.sh` "worked cleanly from a foreign clone", and the no-push / file-scoped-commit boundary
and codex turns ran clean — but it exposed two cracks one layer down, both now fixed:

1. **Space-in-path bug — `relay-drive.sh:110` `eval "$AGENT_CMD"`.** An absolute `--agent-cmd` under
   `…/GH Repos/…` word-split on the space (`…/GH: Permission denied`), so Path A was broken on the
   operator's own default path. **Fix:** smart dispatch — a bare executable path is invoked directly
   (`"$AGENT_CMD"`, space-safe); a command string (env-prefixed / shell-quoted / `%q`-escaped, as
   `poll-relay` and `marathon-drive` pass) still falls back to `eval`. `marathon-drive.sh` simplified to
   pass the bare path (dropped its `%q` workaround). Regression locked in `test/poll-relay.sh` (spaced
   bare path is invoked, not split) + updated `test/marathon-drive.sh` case 11. **poll-relay 12/0,
   marathon-drive 38/0.**
2. **Containment not airtight under a rogue model.** The agy producer went off-task; the shim reverted
   the tracked files it modified, but the allowlist sweep doesn't catch untracked *creations/renames*.
   **Fix (operator-approved): worktree isolation defaulted ON for driven runs** — `relay-drive.sh`
   exports `RELAY_WORKTREE_ISOLATION=1`, so each turn-taker runs in a throwaway `git worktree` of
   `ROOT@HEAD` (off-lane creations can't reach ROOT). Override per run with `=0`. Implemented at the
   drive layer (not the leaf shim default) to avoid the fragile blast radius on the shim unit tests;
   the leaf default stays OFF for direct/attended use. No test runs `relay-drive → real shim`, so the
   suite is unaffected by the new default.

Logged, not yet done (sibling #4): (a) turn role follows the `NEXT:` pointer, not the model id — assert
the acting model matches its assigned role; (b) `RELAY-TURN` is a singleton — a `done` token isn't
reclaimable, so mint a unique task id per run (matches the known `relay-turn-token-reuse` note).

Transparency: the sibling's 4 `relay(RELAY-SHAKEDOWN…)` turn commits were already on local `main` ahead
of this work; the discovery-audit push carried them to `origin/main`. Operator elected to leave them.

## Flagged — NOT touched (needs operator sign-off)

- **Dangling `consult` and `wpcc` symlinks** — collateral evidence of symlink rot, separate skills.
  `consult` is repairable in place (repoint `skill/consult` → `skills/consult`); `wpcc` needs its
  source clone. Out of relay-xyz's scope — offered, not done.
- ~~`GH Repos` vs `GitHub-Repos` clone split~~ — **resolved / retracted:** `GitHub-Repos` was a symlink
  alias to `GH Repos`, not a clone. The alias has been deleted and the 20 skill symlinks repointed to
  `GH Repos`; nothing further to do.

## What I could not verify

- Shakedown's harness tests the **documented command under varied CWD/install conditions**; it does
  **not** instrument Claude Code's internal skill resolver. So I cannot certify *how* the runtime
  enumerates skills — only that (a) the documented script-discovery command is CWD-robust here, and
  (b) the skill is absent from any clone lacking the user-dir symlink, which is the resolver's only
  input for this skill.
- All foreign-CWD scenarios ran on **this** machine/$HOME. A literal second machine was not exercised;
  the fresh-clone failure is inferred from the install topology (no tracked step recreates the symlink)
  and confirmed by the two already-dangling siblings, not from a live second host.
- The reproduction was via shell, not via a real foreign VS Code session — if a session still reports
  failure after `install.sh`, capture the exact failing command + CWD and add it as a scenario.
