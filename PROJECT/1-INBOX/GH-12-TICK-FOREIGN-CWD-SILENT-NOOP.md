---
gh_issue: 12
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/12
title: "Relay follow-ups: dueling-claudes — tick silently no-ops from a foreign CWD (stalled the relay handoff)"
status: Proposed (1-INBOX — not yet active)
created: 2026-06-22
updated: 2026-06-22
owner: Noel (operator)
doc_type: bugfix
goal: >
  Close the two code-level follow-ups the inaugural dueling-claudes relay left open: (1) make `tick`
  fail loudly instead of silently no-op'ing when a mutating subcommand runs from a foreign CWD without
  TICK_REPO_ROOT — the root cause that stalled the relay handoff, currently only doc-patched; and
  (2) quote the dispatch at relay-automation/poll.sh:210 so it survives paths with spaces
  (defense-in-depth). This is a capture, not an active-work doc.
---

# GH-12 — `tick` silently no-ops from a foreign CWD

> **In-repo capture of [issue #12](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/12)**, per `PROJECT/PDDA.md` → "GitHub issue intake". The live issue is the discussion surface; this doc is the back-reference. It carries no `## Status` table while it sits in `1-INBOX`; on execution start it promotes to `PROJECT/2-WORKING/` (keeping the `GH-` prefix + `gh_issue`) and takes on the full active-doc contract.

## Context

The inaugural **Dueling Claudes** relay (`relay-system/2026-06-22/dueling-claudes.md` @ `e18b51f`) closed **Approved** after one round — both `[Blocker]`s, one `[Should]`, and two `[Nit]`s were fixed **in the docs/recipe** and verified against the file. This issue tracks the one thing the relay did **not** close: the foreign-CWD `tick` trap has a **doc-level** workaround but a **code-level** root cause still latent in `tick`.

The relay hit it live. After the Reporter's *committed* handoff, the lock token stayed `claimed by claude-a`, the poll loop stalled, and the Maintainer had to recover the token by hand (release from the correct context + re-claim). "Hands-free" carried an asterisk this run: the recipe's own sharp edge broke autonomy until an agent intervened out-of-band. The docs now warn and use the absolute/env form — but the tool itself still fails **silently** for anyone who forgets, which is the class of bug a one-line doc note doesn't durably close.

## Actionable checklist

- [ ] **`tick`: fail loudly instead of silently no-op'ing when a mutating subcommand runs from a foreign CWD.** A bare `release` / `done` / `claim` run from a CWD that isn't the harness clone, without `TICK_REPO_ROOT`, resolves the wrong/missing `.tick/` and **succeeds as a no-op** — the exact failure that stalled this relay's handoff. Direction (any/all): (a) error when a mutating subcommand can't find the task's `.tick/`, or when the caller isn't the claimer, rather than succeeding-as-noop; (b) auto-resolve the harness root (walk up for `.tick/` / `bin/tick`) so a bare call from a sibling clone still works; (c) at minimum echo the resolved `TICK_REPO_ROOT` so a wrong-repo target is visible. _(Reporter `[Blocker]`, Round 1 — doc-patched, root cause open.)_

- [ ] **`relay-automation/poll.sh:210` — quote the dispatch.** `eval "$RUNNER_CMD"` is unquoted and word-splits on a path containing spaces (`/Users/…/GH Repos/…` → tries to exec `/Users/…/GH`). Reachable only if `--dry-run` is omitted (Path B now mandates it), so this is defense-in-depth: quote the command or build it as an argv array. _(Reporter residual `[Nit]`, Round 1.)_

## Evidence

- Relay thread: `relay-system/2026-06-22/dueling-claudes.md` — Reporter r1 Blocker #2 (foreign-CWD release); Maintainer r1 (manual token recovery after the committed handoff); Reporter close (residual note).
- Live repro of the related `--dry-run` defect during the relay: `poll.sh: line 210: /Users/…/GH: Permission denied`.

## Already fixed in-thread (context only — not tasks)

These were dispositioned and verified inside the relay; listed so a future actioner doesn't re-open them:

- `--dry-run` made mandatory for Path B — fixed in `relay-automation/DUELING-CLAUDES.md`.
- Foreign-CWD `tick release` in the recipe + the thread's embedded step 6 — fixed to the `TICK_REPO_ROOT=… …/bin/tick` form.
- `$(date …)` deadline re-eval, token-name drift, rule-9 "clean tree" wording — all fixed.

**Disagreements / parked:** none. Both follow-ups above were logged as out-of-scope-for-the-relay backlog, not disputed.
