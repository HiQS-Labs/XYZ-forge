---
gh_issue: 20
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/20
title: "Give agy first-class footing alongside Codex in live relay docs"
status: Completed
created: 2026-06-25
updated: 2026-06-25
owner: Noel (operator) · Codex (producer)
doc_type: feedback
goal: >
  Remove the live doc/skill bias that presents Codex as the primary headless relay
  agent and agy as a secondary swap-in, so the shipped product surfaces treat both
  Path-A workers as co-equal where the runtime actually supports both.
---

# GH-20 — agy first-class footing in live relay docs

> **In-repo capture of [issue #20](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/20), promoted to `PROJECT/2-WORKING/` on execution start.** The live issue is the discussion surface; this doc is the canonical active-work record, per `PROJECT/PDDA.md` → "GitHub issue intake".

## Status

| What was just completed | What's next |
|---|---|
| **Shipped + archived 2026-06-25.** Rewrote the live operator surfaces so Codex and agy are framed as co-equal Path-A workers where the runtime actually supports both, and removed the stale `QUICKSTART.md` path references that made the consolidation brittle. `test/codex-turn.sh` 27/27, `test/agy-turn.sh` 22/22, `validate.sh` 45/45. | Closed [#20](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/20) + archived to `3-COMPLETED`. Reopen only if doc drift resurfaces the Codex-first bias. |

## Summary

The runtime already ships both `codex-turn.sh` and `agy-turn.sh`, but the live
operator surfaces still tell a "Codex first, agy optional" story:

- root `README.md` routes newcomers to a headless **Codex** path
- `relay-automation/README.md` only has a named **Headless Codex** bring-up
- `skills/relay-xyz/SKILL.md` frames Codex as the marquee headless flow and agy as a swap
- `skills/relay-xyz/find-harness.sh` labels both CLIs as "reviewers" rather than co-equal Path-A workers

That doc skew matters because these files are the front door. The ask is not to
claim parity the runtime does not have; it is to give agy equal footing anywhere
the product genuinely supports both lanes today.

## Initial asks

1. Make the front door (`README.md`) stop implying the headless path is specifically Codex-first.
2. Rename/restructure the canonical bring-up in `relay-automation/README.md` so Codex and agy both appear as first-class headless workers.
3. Rework `skills/relay-xyz/SKILL.md` so the Path-A examples and framing are symmetric, not "Codex by default, agy by swap."
4. Clean up adjacent live labels (`find-harness.sh`, operator wording) that still make agy look secondary where the runtime supports it equally.

## Notes for execution

- Keep the claims script-accurate. Do not invent symmetry where the tools still differ (for example, Codex and agy have different auth/runtime caveats and cost visibility).
- Prefer one canonical bring-up section over duplicated parallel docs.
- Verification should distinguish doc regressions from the known dirty-tree interaction in `test/runner-loop.sh` when `README.md` is edited live.

## Completion notes

- Shipped surfaces: root `README.md`, `relay-automation/README.md`, `skills/relay-xyz/SKILL.md`, `skills/relay-automation/SKILL.md`, `skills/relay-xyz/find-harness.sh`, `FRONTDOOR.md`, and the active project hub `PROJECT/2-WORKING/AUTOMATED-RELAY.md`.
- Durability cleanup: removed the stale deleted-file reference from `test/path-integrity.sh`, so the suite no longer expects `relay-automation/QUICKSTART.md` to exist.
- Verification: `bash test/codex-turn.sh` passed, `bash test/agy-turn.sh` passed, and `bash validate.sh` passed `45 / 45` on a clean tree via a temporary doc-only stash because `test/runner-loop.sh` intentionally fails with a dirty live `README.md`.
