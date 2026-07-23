---
gh_issue: 272
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272
title: "Driven relay turn's tick release resolves wrong TICK_REPO_ROOT in a vendored same-repo lane — review content never lands"
status: "Contract authored 2026-07-23 (/10days sweep) — not yet fired"
created: 2026-07-23
updated: 2026-07-23
owner: noel
doc_type: bug
complexity: 3
risk: 2
effort: 2
ratings_provisional: true
related:
  - "#261 — prior fix that reproduced this exact class of bug and explicitly deferred it: 'a separate, real bug worth its own future issue' (merge 312a2c3)"
non_goals:
  - Re-litigating GH-261's own fix (already merged and correct for what it addressed).
  - A general redesign of TICK_REPO_ROOT resolution — fix the specific vendored-same-repo-lane
    mismatch this issue reproduces, not the whole resolution model.
goal: >
  A driven relay turn's tick release/done call, when run inside a worktree-isolated vendored
  same-repo lane, resolves TICK_REPO_ROOT to the CALLER's actual repo root — not the vendored
  `.xyz/` subpath — so review content lands where the watcher expects it instead of silently
  vanishing into the wrong namespace.
---

# GH-272 · `tick`'s TICK_REPO_ROOT resolves wrong in a vendored same-repo lane

## Status
| What was just completed | What's next |
|---|---|
| Contract authored 2026-07-23 (/10days sweep): confirmed still reproducible (no fix commits since the bug's own reported commit `70640ca`), root-cause area narrowed to `rtl_tick_bin`/`TICK_REPO_ROOT` resolution in `relay-turn-lib.sh`. Fixed a broken ROADMAP.md link that pointed at a doc that was referenced but never created. `swarm-preflight --gh-issue 272` verdict: ready. | Fire this contract: localize and fix the resolution mismatch, add a regression test reproducing the 2/2 failure. |

Reproduced 2/2 (default timeout, then `RELAY_TURN_TIMEOUT_S=900`): a worktree-isolated turn's own
`tick release`/`tick done` invocation logs `TICK_REPO_ROOT="<repo>/.xyz"`, but
`find-harness.sh --env` exports `TICK_REPO_ROOT=<repo>` (no `.xyz` suffix) for the same run. GH-261's
own fix commit (`312a2c3`) confirmed this exact behavior is real ("`.tick` claims do land in the
wrong repo when it leaks in") but deliberately deferred it as "a separate, real bug worth its own
future issue" rather than fixing it there — this issue is that follow-on.

No commit since the bug's own reported commit (`70640ca`, an ancestor of current HEAD) has touched
`relay-automation/relay-turn-lib.sh`, `codex-turn.sh`, or `relay-drive.sh` — nothing has changed since
the bug was last reproduced.

## Where to look

`relay-automation/relay-turn-lib.sh`'s `rtl_tick_bin()` (line ~173) and the `TICK_REPO_ROOT` resolution
used at token-claim/release/done time (lines ~648-650, ~1025-1049) — specifically how it's derived
inside a worktree-isolated turn for a vendored `.xyz/` same-repo lane, vs. the caller's own
`find-harness.sh --env` export.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "relay-automation/relay-turn-lib.sh", "pattern": "rtl_tick_bin" }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh" ],
  "remediation": {
    "source": "issue#272",
    "criteria": "A worktree-isolated turn's tick release/done resolves TICK_REPO_ROOT to the caller's actual repo root in a vendored same-repo lane, matching find-harness.sh --env's export — not the vendored .xyz/ subpath. Add a regression test reproducing the 2/2 failure mode from the issue body before the fix, green after."
  },
  "lanes": { "agy_safe": [], "orchestrator_only": [ "relay-automation/relay-turn-lib.sh" ] }
}
```

Note: `relay-turn-lib.sh` is kernel-zone (shared safety core for every turn-taker shim) — flagged
`orchestrator_only`, not `agy_safe`, per this repo's own lane convention. A Qwen-builder turn against
this file should run under the same worktree-isolation + reviewer-gate discipline as any kernel-zone
change, not as an unsupervised single-shot edit.
