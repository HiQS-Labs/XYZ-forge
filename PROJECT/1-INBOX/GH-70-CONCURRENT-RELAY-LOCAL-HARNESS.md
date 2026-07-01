---
title: "GH-70 · relay-xyz: per-repo harness for concurrent automated relays"
status: queued
priority: 3
risk: 2
created: 2026-07-01
issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/70
roadmap_section: queue
non_goals:
  - No change to the global lock in relay-drive.sh (GH-42 fix is correct)
  - No auto-cutting of branches across repos
  - No changes to relay-turn-lib.sh or the tick kernel
---

# GH-70 · relay-xyz: per-repo harness for concurrent automated relays

## Problem

`relay-drive.sh` holds a **global mutex** per harness clone — `.git/relay-driver.lock` for a
normal clone, `.relay-driver.lock` inside a vendored `.xyz/` dir. Only **one** automated relay
can run at a time in a given clone. This is intentional (GH-42 ROOT HEAD hazard — concurrent
worktrees on the same `ROOT@HEAD` can corrupt git state), but it means two external repos
(e.g. sleuth-app + rebalance-OS) **cannot run simultaneous automated relays** when both resolve
to the centralized xyz-3-agents-swarm harness.

From relay-drive.sh lines 31–56:
```
relay-drive: another driver is active in this repo (pid %s, lock: %s).
relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).
exit 1
```

## Why the existing GH-49 vendored `.xyz/` already solves it (partially)

GH-49 (`xyz-vendor.sh`) snapshots the full harness (16-file `relay-pkg` manifest + `bin/tick` +
`src/*.js`) into a gitignored `.xyz/` in a foreign repo. When relay-drive.sh runs from
`.../sleuth-app/.xyz/relay-automation/relay-drive.sh`:

```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# → .../sleuth-app/.xyz
```

The lock becomes `.../sleuth-app/.xyz/.relay-driver.lock` — entirely independent from
rebalance-OS's lock at `.../rebalance-OS/.xyz/.relay-driver.lock`. **Concurrent relays across
repos are already possible** for any repo that ran `xyz-vendor.sh`.

`find-harness.sh` already prefers a local `.xyz/` when present
(env → `.xyz/` → current-repo → script-relative), so the locator wires this up automatically.

## What's still missing

1. **`install.sh` (tick-only) ≠ harness**: repos that ran `install.sh` get `bin/tick` +
   `src/*.js` but NOT `relay-automation/`. sleuth-app's `xyz-tick/` install falls back to the
   centralized harness and its global lock. Only `xyz-vendor.sh` gives the full harness.

2. **relay-xyz SKILL.md doesn't explain any of this**: no mention of the global-lock
   limitation, when concurrency is possible, or that `xyz-vendor.sh` is the correct path for
   per-repo relay isolation. The "When to use" and Preconditions sections are silent on it.

3. **No concurrency-readiness warning**: nothing tells the operator "this foreign repo is using
   the centralized harness; if you want concurrent relays, run `xyz-vendor.sh` first."

## Plan

### Phase 1 — Document (no code change, low-cost)

Update `skills/relay-xyz/SKILL.md`:

- Add a **"Concurrent relays across repos"** subsection under Preconditions explaining:
  - The global-lock limitation when using the centralized harness
  - That `xyz-vendor.sh` (GH-49) enables per-repo lock isolation → concurrency
  - When each path applies: `install.sh` (tick-only, no relay capability) vs
    `xyz-vendor.sh` (full harness, per-repo lock)
  - Example: two repos with `.xyz/` installs, each running `relay-drive.sh` from their
    own `.xyz/relay-automation/`, holding independent locks

- Update "When to use" to mention the foreign-repo concurrency case.

**Deliverable:** updated SKILL.md, no script changes, no new tests needed.

### Phase 2 — Concurrency-readiness check in find-harness.sh (additive)

In `find-harness.sh --check`, detect when the resolved harness is the centralized
xyz-3-agents-swarm clone (not a local `.xyz/`) and the centralized lock is currently held.
Emit a **warn-and-continue** message:

```
relay-xyz: WARNING — using centralized harness (no local .xyz/ found in this repo).
  If another relay is running, this one will block. For concurrent relays, run:
  relay-automation/xyz-vendor.sh vendor <this-repo>
```

Fail-open: the check never blocks a relay from starting, only advises.

**Deliverable:** patched `find-harness.sh`, updated `--check` output. Add a test assertion
to `test/relay-xyz-skill-guard.sh` or a new `test/find-harness.sh`.

### Phase 3 — `install.sh --with-harness` (optional, deferred)

Extend `install.sh` with a `--with-harness` flag that delegates to `xyz-vendor.sh vendor`
under the hood, so the two install paths converge for operators who want full capability
from one command. Defer until there's a concrete user-facing need; `xyz-vendor.sh` is
already the documented path.

**Defer condition:** a second external repo asks for concurrent relay capability and finds
`xyz-vendor.sh` too indirect.

## Sequencing

- Phase 1 is independent and safe to run any time (doc-only, Sonnet High).
- Phase 2 depends on Phase 1 (need the documented rationale before adding the check).
- Phase 3 is deferred; no dependency on 1 or 2.
- No dependency on GH-65, GH-68, or any kernel work.

## Verification (Phase 2)

Adversarial proof:
1. Foreign repo with NO `.xyz/` → `find-harness.sh --check` prints the warning, resolves
   to centralized harness, exits 0 (fail-open).
2. Foreign repo WITH `.xyz/` → `find-harness.sh --check` resolves to `.xyz/`, no warning.
3. Two foreign repos each with `.xyz/`, both running `relay-drive.sh` simultaneously →
   each acquires its own `.relay-driver.lock`, both complete without blocking.

## Related

- [GH-42](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/42) —
  original concurrent relay ROOT HEAD bug (the lock exists because of this)
- [GH-49](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/49) —
  vendored `.xyz/` harness (already enables per-repo isolation)
- [GH-65](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/65) —
  GH-49b: vendor the marathon runtime (same pattern, marathon lane)
