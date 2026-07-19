---
gh_issue: 58
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/58
title: marathon --builder claude fails headless (exec claude not found) — add CLAUDE_BIN discovery + fail-fast
status: Closed — Queued (rated + contracted — marathon-ready)
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
roadmap_exempt: false
non_goals:
  - Not making the `claude` CLI itself genuinely headless-runnable — that is environmental (the CLI's own auth/PTY needs), out of scope. This lane fixes the shim's resolution + error path only.
  - Not touching the kernel (relay-turn-lib.sh / bin/tick / relay-drive.sh) — claude-turn.sh is a shim.
  - Not changing codex/agy turn-takers (they already resolve via their own locators).
related:
  - relay-automation/claude-turn.sh
---

# GH-58 — marathon `--builder claude` fails headless (`exec: claude: not found`)

## Bug

`relay-automation/claude-turn.sh` does `CLAUDE_BIN="${CLAUDE_BIN:-claude}"` then `exec`s it with **no
PATH discovery and no fail-fast**. In a headless/marathon shell where `claude` is not on `PATH`, the
turn dies with a raw `exec: claude: not found` (mislabels downstream as a generic builder failure).
codex/agy resolve their binaries via a locator; claude does not.

## Fix direction (scope = both halves, per GUIDING-PRINCIPLES #7 least-code + #8 honest)

1. **Discovery:** resolve `CLAUDE_BIN` robustly — check `PATH` first, then the known install location
   `~/.claude/local/claude` (the location the issue confirms). Keep it a small, ordered probe.
2. **Fail-fast:** when unresolvable, exit with a distinct non-zero code and a clear message —
   `claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder` — instead of a raw
   `exec: not found`. Honest surfacing so the operator sees *why* and *what to do*.

## Build note

Build this lane with `--builder codex` or `--builder agy` (NOT `--builder claude` — the very path it
fixes). Shim zone → not kernel-serializing.

## Definition of done

- `claude-turn.sh` resolves `CLAUDE_BIN` via PATH then `~/.claude/local/claude`; when unresolvable it
  fails fast with the clear message + distinct exit code (no raw `exec: not found`).
- No behavior change when `claude` IS resolvable (default path unchanged).
- New `test/claude-turn.sh` (stubbed PATH) asserts the clear-error path; wired into `validate.sh`.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). Shim zone (agy-safe),
single script + a new test. Gate is a new test (none exists today).

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/claude-turn.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/claude-turn.sh", "pattern": "GH-58" } ],
  "artifacts":   [ "relay-automation/claude-turn.sh", "test/claude-turn.sh" ],
  "remediation": { "source": "GH-58#fix-direction", "criteria": "claude-turn.sh resolves CLAUDE_BIN via PATH then common install locations (~/.claude/local/claude); when unresolvable it fails fast with a clear message ('claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder') and a distinct exit code rather than a raw 'exec: not found'; unchanged behavior when claude resolves; NEW test/claude-turn.sh with a stubbed PATH asserts the clear-error path and is wired into validate.sh; GH-58 marker comment." },
  "lanes":       { "agy_safe": [ "relay-automation/claude-turn.sh", "test/claude-turn.sh" ], "orchestrator_only": [] }
}
```
