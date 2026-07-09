---
gh_issue: 107
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/107
title: "Containment reverts a complete, passing turn when the builder writes an off-lane tool-cache dir (.codebase-memory/) [sibling of #54]"
status: SHIPPED 2026-07-04 (`524d345`, on `main`) — kernel zone, built on the Opus-serial track as specified
created: 2026-07-04
updated: 2026-07-08
owner: noel
doc_type: bugfix
goal: >
  Add an opt-in, default-off exemption to rtl_worktree_end's off-lane detection so a builder's own
  tool-cache side-effect writes (e.g. .codebase-memory/) don't discard an otherwise-correct,
  fully-allowlisted turn — without weakening containment's default behavior for anything else.
complexity: 3
risk: 4
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not honoring .gitignore wholesale as the exemption test — a target repo may not have gitignored its own tool's cache dir yet, which is exactly the failure mode reported
  - Not weakening containment by default — the exemption is opt-in (a configurable ignore-list), not a change to the default off-lane rule
  - Not addressing the separate agent-children process-leak issue mentioned in the same field report (out of scope, needs process-group changes at the turn-launch site)
related:
  - relay-automation/relay-turn-lib.sh
  - test/path-overlap.sh
  - test/relay-untracked-file-warn.sh
---

## Status

| What was just completed | What's next |
|---|---|
| **SHIPPED 2026-07-04 (`524d345`, on `main`).** Built on the kernel/Opus-serial track as specified — not a parallel Sonnet lane. `rtl_is_containment_ignored()` added to `relay-automation/relay-turn-lib.sh:345-364` and called in `rtl_worktree_end`'s off-lane loop before the `RTL_WT_OFFLANE=1` fallthrough. Built-in list (`.codebase-memory`, `.aider*`, `node_modules/.cache`), root-anchored, extended by the comma-separated `CONTAINMENT_IGNORE` env var (empty by default → default behavior byte-for-byte unchanged). Kernel-required [decisions record](../../decisions/2026-07-04-containment-ignore-toolcache.md) written alongside. Coverage: `test/worktree-isolation.sh` cases 7–9 (built-in exempted, `CONTAINMENT_IGNORE` glob exempted, and a control asserting a non-built-in path *without* the env still exits 6) — **31/31 green**, re-verified 2026-07-08. Python-layer inheritance asserted via `rtl.py` in `test/test_python_layer.py:118` (GH-112/#134 parity lane). | Nothing — item complete; issue #107 verified **CLOSED** (2026-07-08). The four-day ROADMAP staleness that hid this item's shipped state is filed as [#189](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/189). |

## Problem (grounded in the current code)

`rtl_worktree_end()` (`relay-automation/relay-turn-lib.sh:343-380`) walks `git status --porcelain -z`
inside the isolated worktree. For each changed path it exempts `.tick/*` and (conditionally) the
read-only `.relay-artifacts` seed, then:

```bash
rtl_in_allow "$path" && continue
RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
```

Any other changed path — including a brand-new, **untracked** directory the builder's own tooling
created as a side effect (e.g. an indexing/tool-cache dir like `.codebase-memory/`, written by a
codebase-memory MCP server or similar) — trips `RTL_WT_OFFLANE=1` and the *entire* turn is discarded,
even when the builder's actual code change was complete and correct (reproduced live: 442 lines
across 3 files + tests, independently re-verified 67/67 scoped tests green + tsc-clean, discarded
anyway).

Note this is a real, currently-observable failure mode in *this very repo* — a `.codebase-memory/`
directory has appeared untracked in this working tree during concurrent tool activity this session,
which is exactly the trigger pattern described in the issue.

`git status --porcelain -z` does not list gitignored paths at all, so if a target repo's
`.gitignore` already covered the tool's cache dir, this loop would never see it and the bug would
not fire — but a target repo has no reason to have pre-anticipated a specific tool's cache
directory, so relying on `.gitignore` (suggestion #1 in the issue) is not a real fix; it only works
after the fact, once someone notices and adds the entry.

## Fix

Add an **opt-in, configurable ignore-list** checked in the same loop, before the final
`rtl_in_allow` / off-lane fallthrough (around `relay-turn-lib.sh:377-379`):

```bash
rtl_in_allow "$path" && continue
rtl_is_containment_ignored "$path" && continue   # NEW: opt-in tool-cache exemption
RTL_WT_OFFLANE=1
```

`rtl_is_containment_ignored()`: checks `$path` (or its top-level segment) against a list of glob
patterns from `CONTAINMENT_IGNORE` (comma-separated env var, empty by default — a fresh install's
behavior is byte-for-byte unchanged) union a small built-in default list of well-known tool-cache
dirs (`.codebase-memory/`, `.aider*`, `node_modules/.cache/`) that this harness itself has already
had to gitignore in its own `.gitignore` for the same reason.

This is deliberately **opt-in and additive**: it does not change the off-lane rule for anything not
on the ignore-list, and it does not touch tracked-file detection at all (suggestion #3 in the
issue — "only revert tracked off-lane edits" — is a bigger philosophical change to the containment
model and is explicitly deferred, not built here).

## Definition of done

- [x] `rtl_is_containment_ignored()` added to `relay-turn-lib.sh`, checked in `rtl_worktree_end`'s
      off-lane loop before the final off-lane fallthrough. → `relay-turn-lib.sh:345-364`
- [x] Default behavior (no `CONTAINMENT_IGNORE` set, no built-in match) is byte-for-byte unchanged —
      an untracked non-cache-dir path still trips off-lane exactly as today. → asserted by the
      control case, `test/worktree-isolation.sh:163-169` (still exits 6, makes no commit)
- [x] A path matching the built-in default list (e.g. `.codebase-memory/`) no longer trips off-lane;
      the rest of the turn's allowlisted changes still copy back and commit normally.
- [x] `CONTAINMENT_IGNORE` env var extends the built-in list without needing a code change.
      → `test/worktree-isolation.sh:155-160`
- [x] New `test/relay-turn-lib.sh`-adjacent coverage (or extend an existing containment test file)
      for: built-in-ignored path exempted, `CONTAINMENT_IGNORE`-supplied path exempted, an
      unrelated untracked path still trips off-lane as before. → `test/worktree-isolation.sh`
      cases 7–9, plus an assertion that the ignored cache dir is discarded with the worktree and
      never copied back to `RTL_ROOT`.
- [x] `bash validate.sh` green. — green at ship time (Plan C integration, 2026-07-04, exit 0). A
      2026-07-08 re-run exits 1, but **only** on two environmental gaps unrelated to this change and
      already documented in CHANGELOG: `acorn-extract.sh` (npm `acorn` module absent) and
      `python:test_python_layer.py` (`pytest` absent). This item's covering gate,
      `test/worktree-isolation.sh`, is 31/31.

**Kernel-track extra (required by this doc's own blast-radius section):**

- [x] `decisions/` record written alongside the code change →
      [2026-07-04-containment-ignore-toolcache.md](../../decisions/2026-07-04-containment-ignore-toolcache.md)

## Reversibility & blast radius

**Higher than usual — this is the containment kernel.** `relay-turn-lib.sh` is the file every
turn-taker sources; a mistake here is repo-wide, not lane-scoped. The change is additive (a new
opt-in exemption path, default-off), which keeps the blast radius to "a path on the ignore-list is
now exempt" rather than "off-lane detection behaves differently for anything." Still: **route
through the kernel/Opus-serial track, not a parallel Sonnet lane** — same convention as Part B
(epoch-fencing) and Plan A's kernel items — and require a `decisions/` record given the containment
core is being touched.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "GH-107" }
  ],
  "artifacts": [
    "relay-automation/relay-turn-lib.sh"
  ],
  "remediation": "Add rtl_is_containment_ignored() to relay-automation/relay-turn-lib.sh: checks a changed path (from rtl_worktree_end's off-lane loop, before the final off-lane fallthrough) against a comma-separated CONTAINMENT_IGNORE env var (empty by default) unioned with a small built-in list of known tool-cache dirs (.codebase-memory/, .aider*, node_modules/.cache/). Call it in the loop right before the RTL_WT_OFFLANE=1 fallthrough, after the existing rtl_in_allow check. Default behavior (nothing set, no built-in match) must be byte-for-byte unchanged. Add test coverage for: built-in-ignored path exempted, CONTAINMENT_IGNORE-supplied path exempted, unrelated untracked path still trips off-lane. GH-107 marker comment near the fix. This touches the containment kernel -- write a decisions/ record alongside the code change.",
  "lanes": {
    "agy_safe": [],
    "orchestrator_only": ["relay-automation/relay-turn-lib.sh"],
    "note": "KERNEL ZONE. Route through the Opus-serial track (same as Part B epoch-fencing / Plan A kernel lanes), not a parallel Sonnet build. Must not run concurrently with any other lane touching relay-turn-lib.sh, bin/tick, or relay-drive.sh."
  }
}
```

## Provenance

Field report from a real vendored-install marathon dogfood run (2026-07-04), one of three
independent friction points (siblings: #106 codex approval hang, #108 gate scoping) that each
individually blocked a correct, complete build from advancing cleanly through the harness on a real
external repo. Sibling of #54 (in-turn fs-touching tests) — same containment mechanism, different
trigger (a tool's own cache writes vs. a test's fixture writes).
