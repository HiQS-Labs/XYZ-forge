---
gh_issue: 12
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/12
title: "GH-12 — tick silently no-ops from a foreign CWD (relay handoff stall)"
status: Active
created: 2026-06-22
updated: 2026-06-22
owner: Noel (operator) · Claude (producer)
doc_type: bugfix
goal: >
  Close the two code-level follow-ups the inaugural dueling-claudes relay left open: (1) make `tick`
  fail loudly instead of silently no-op'ing when a coordination-mutation verb runs from a foreign CWD
  without TICK_REPO_ROOT — the root cause that stalled the relay handoff, previously only doc-patched;
  and (2) quote/route the dispatch at relay-automation/poll.sh:210 so it survives paths with spaces
  (defense-in-depth). Both fixes landed with regression tests; suite green at 37/37.
---

# GH-12 — `tick` silently no-ops from a foreign CWD

> **In-repo active-work doc for [issue #12](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/12)**, promoted from `PROJECT/1-INBOX/` on execution start, per `PROJECT/PDDA.md` → "GitHub issue intake". The live issue is the discussion surface; this doc is the canonical active-work record, carrying `gh_issue` forward.

## Status

| What was just completed | What's next |
|---|---|
| **Both fixes landed + regression-tested.** (1) `bin/tick` now surfaces the resolved repo root and **refuses** a coordination-mutation verb (`claim/take/scope/release/break/done/ping/reap`) when the root was *inferred* (not pinned via `TICK_REPO_ROOT`) and the repo has no `.tick/events` — closing the silent succeed-as-noop. (2) `relay-automation/poll.sh` runs a bare executable path **directly** (only command-strings fall back to `eval`), mirroring `relay-drive.sh`, so the space in the default `$ROOT_DIR/relay-automation/runner.sh` path no longer word-splits. New `test/tick-foreign-cwd.sh` (6 assertions) + a spaced-path case in `test/poll-driver.sh`; `relay-pkg.tar.gz` regenerated; **`validate.sh` 37/37**. | Operator review → commit + push → move this doc to `PROJECT/3-COMPLETED/` and close issue #12. Optional follow-ups (not blocking): extend the guard to `cost`/`log`; add a walk-up `.tick/` auto-resolver (direction b) if a sibling-clone-without-pin workflow ever appears. |

## Context

The inaugural **Dueling Claudes** relay (`relay-system/2026-06-22/dueling-claudes.md` @ `e18b51f`) closed **Approved** after one round — every finding was fixed **in the docs/recipe** and verified against the file. This doc tracks the one thing the relay did **not** close: the foreign-CWD `tick` trap had a **doc-level** workaround but a **code-level** root cause still latent in `tick`.

The relay hit it live. After the Reporter's *committed* handoff, the lock token stayed `claimed by claude-a`, the poll loop stalled, and the Maintainer had to recover the token by hand. "Hands-free" carried an asterisk that run — the recipe's own sharp edge broke autonomy until an agent intervened out-of-band. A one-line doc note doesn't durably close a tool that still fails **silently** for anyone who forgets.

## Root cause

`repoRoot()` in `bin/tick` resolves the root in three tiers: explicit `TICK_REPO_ROOT` → `git rev-parse --show-toplevel` → `process.cwd()`. From a foreign CWD with no `TICK_REPO_ROOT`, tier 2 returns **the wrong repo's** root:

- `claim` / `take` are not ownership-guarded — they `appendEvent`, which `ensureEventsDir` auto-creates. So a claim from the wrong repo **succeeds, in the wrong `.tick/`** — a no-op against the real harness lock.
- `release` / `done` / `break` / `scope` / `ping` *are* ownership-guarded, so they threw `task <X> not found` — technically loud, but with **no hint** it was a wrong-CWD problem, so it read as a mysterious failure.

The discriminator that makes a clean fix possible: the bug bites **only when the root was inferred** (tiers 2–3). When `TICK_REPO_ROOT` is set, the operator/recipe/test pinned it deliberately. Every test pins it, so gating the new behavior on "inferred root" gives near-zero blast radius.

## Fix landed

### Task 1 — `tick` fails loudly from a foreign CWD _(was Reporter `[Blocker]`, doc-patched, root cause now closed)_

- [x] `repoRoot()` now returns `{ root, source }` where `source ∈ {env, git, cwd}`.
- [x] New `assertResolvedRoot(verb, root, source)`, called before the verb switch, for the coordination-mutation verbs `claim/take/scope/release/break/done/ping/reap`:
  - **`source === 'env'` → trusted, no-op** (preserves the recipe/test form exactly).
  - Otherwise **echo the resolved root to stderr** — `tick: resolved repo root <root> via <git rev-parse|cwd fallback> (set TICK_REPO_ROOT to pin it)` (direction c: a wrong-repo target is always visible).
  - And if `<root>/.tick/events` is **missing**, **throw** rather than auto-create — directing the operator to `tick init` (if this really is the harness repo) or to set `TICK_REPO_ROOT` (direction a). This is the line that converts the silent claim-no-op into a hard error and gives `release`/`done` an actionable message.
- Best-effort `cost`/`log` are deliberately **excluded** so a turn's auxiliary cost capture never hard-fails on this.
- `.tick/` is gitignored, so a genuinely fresh clone has none — refusing a bare mutating verb there and pointing at `tick init` is the *correct* safe behavior, not a regression.

### Task 2 — `poll.sh` dispatch survives spaced paths _(was Reporter residual `[Nit]`, defense-in-depth)_

- [x] Added a `run_cmd()` helper: `if [[ -x "$1" ]]; then "$1"; else eval "$1"; fi`. `run-runner`/`run-watchdog` call it instead of bare `eval "$RUNNER_CMD"`.
- This mirrors the already-accepted, already-tested idiom in `relay-drive.sh:130-134` (the `--agent-cmd` fix). The default `RUNNER_CMD`/`WATCHDOG_CMD` is `$ROOT_DIR/relay-automation/...sh`, and `$ROOT_DIR` here sits under a `…/GH Repos/…` path (a space) — a bare executable path, now run directly. User-supplied command-strings (with args) still go through `eval`, as their callers shell-quote.

### Verification

- New `test/tick-foreign-cwd.sh` — foreign-CWD `release` refused + real lock untouched; foreign-CWD `claim` refused + no stray `.tick/` vivified; env-pinned release still works; inferred-root-with-`.tick/` still claims and echoes the resolved root. Registered in `validate.sh`.
- New spaced-path case in `test/poll-driver.sh` — a bare `--runner-cmd` path under `".../dir with space/..."` is invoked directly (sentinel asserts it ran, not word-split).
- `skills/relay-automation/relay-pkg.tar.gz` regenerated (`make-pkg.sh`) so the packaged `poll.sh` + `test/poll-driver.sh` match source (skill-extract drift check).
- **`./validate.sh` → 37/37.**

## Evidence (original)

- Relay thread: `relay-system/2026-06-22/dueling-claudes.md` — Reporter r1 Blocker #2 (foreign-CWD release); Maintainer r1 (manual token recovery after the committed handoff); Reporter close (residual note).
- Live repro of the related `--dry-run` defect during the relay: `poll.sh: line 210: …/GH: Permission denied` (the spaced `…/GH Repos/…` path split at the space).

## Already fixed in-thread (context only)

Dispositioned and verified inside the relay — not re-opened here: `--dry-run` mandatory for Path B (`DUELING-CLAUDES.md`); foreign-CWD `tick release` in the recipe/step-6 (the `TICK_REPO_ROOT=… …/bin/tick` form); `$(date …)` deadline re-eval; token-name drift; rule-9 wording. No disagreements were parked.
