---
title: Headless Codex isolated-turn friction — .tick lock outside the workspace sandbox
status: Active (2-WORKING)
created: 2026-06-28
updated: 2026-06-28
owner: noelsaw1
branch: main
gh_issue: 36
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/36
doc_type: project
goal: >
  Let a headless Codex turn claim/release the shared .tick token under worktree isolation with the
  DEFAULT flags — or fail fast with the exact remedy — instead of silently deadlocking because the
  shared .tick/ lock lives outside Codex's workspace-write sandbox.
---

## Status

| What was just completed | What's next |
|---|---|
| Promoted from `1-INBOX` to a marathon-ready capture doc with a Swarm Preflight Contract (2026-06-28). Containment confirmed intact (worktree + empty allowlist + `rtl_enforce` held — Codex only wrote the relay file); this is an ergonomics fix. | Fire the **primary** (shim-scoped) fix in `codex-turn.sh`: a writable-root for `.tick/` under isolation, OR a loud preflight that fails fast with the remedy. **Secondary** (relay-file-at-HEAD warn into `rtl_worktree_begin`) is kernel-scoped → deferred to the kernel-serial bucket, NOT this lane. |

## Scope (primary only)
**Finding 1 (this lane):** under `RELAY_WORKTREE_ISOLATION=1`, Codex's CWD is the throwaway worktree but
`.tick/` lives at `TICK_REPO_ROOT` (harness root), outside the default `-s workspace-write` sandbox → the
token write fails → deadlock. Fix in [codex-turn.sh](../../relay-automation/codex-turn.sh): add the harness
root (or just `.tick/`) as a Codex writable root under isolation, OR a loud preflight that detects a
sandboxed `.tick/` write and fails fast with the exact remedy. No silent deadlock.

**Finding 2 (NOT this lane):** surfacing the relay-file-at-HEAD warn from `rtl_worktree_begin` touches the
containment kernel (`relay-turn-lib.sh`) — it belongs in the kernel-serial bucket of the QUEUE, not here.
Keeping it off this lane keeps the kernel off the allowlist.

## Acceptance criteria
- [ ] A headless isolated Codex turn claims/releases the token with the **default** flags, or fails fast
  with the exact remedy (no silent deadlock to the timeout).
- [ ] `bash validate.sh` green; containment behavior unchanged (worktree + off-lane enforcement still hold).

## Swarm Preflight Contract
```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/codex-turn.sh", "pattern": "GH-36" } ],
  "artifacts":   [ "relay-automation/codex-turn.sh" ],
  "remediation": { "source": "self#acceptance-criteria", "criteria": "Isolated Codex turn writes the shared .tick token with default flags or fails fast with the remedy; no silent deadlock; containment unchanged." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ "bin/", ".tick/", "relay-automation/relay-turn-lib.sh" ] }
}
```

## Related
- Sibling of GH-32 (single-turn ergonomics, closed — Finding 2 already mitigated there for `relay-drive.sh`).
- Promoted from the 1-INBOX intake (2026-06-28) on adding the preflight contract.
