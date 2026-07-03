---
gh_issue: 77
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77
title: Aider ↔ OpenRouter turn-taker lane (OpenAI-standard, discrete from Codex)
status: Shipped
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
roadmap_exempt: false
related:
  - relay-automation/aider-turn.sh
  - relay-automation/marathon-agent.sh
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-turn-lib.sh
non_goals:
  - No cost.tokens capture — Aider `--message` mode emits no machine-readable usage JSON on stdout (same cost-floor partial as the Codex/agy lanes)
  - Not added to the vendored relay-pkg tarball yet — main-clone use first; packaging is a follow-on
  - Aider stays a BUILDER lane; reviewer lanes remain codex/gemini/agy
---

# GH-77 · Aider ↔ OpenRouter turn-taker lane

## Status

| Most recently completed | What's next |
|---|---|
| **✅ SHIPPED 2026-07-02 — marathon + relay + consult.** New `relay-automation/aider-turn.sh` headless turn-taker drives Aider against OpenRouter (OpenAI-standard) behind the shared `relay-turn-lib.sh` containment core — **discrete from Codex** (no shared code/env). Two Aider-specific adaptations: the SHIM performs the tick token ops (`claim <task> --paths` + `ping`; `rtl_enforce` GH-67 does the release/done) since Aider can't run shell mid-turn — and **asserts ownership (`claimer == self` via `tick info`) before launching Aider, failing the turn (exit 5) if the claim didn't stick** so a turn can never commit with the token still open under the old owner, and it runs Aider with `--no-auto-commits` so the harness owns the commit (else the commit-bypass guard trips). Additive routing in `marathon-agent.sh` + `marathon-drive.sh` (`aider*` builder lane; Codex paths byte-identical) — the same dispatcher `relay-drive.sh` uses, so Aider is a first-class **relay** turn-taker too. **Also wired into `consult.sh`** (`--models …,aider`) — the cross-model advisor behind `relay-drive.sh --consult-verify`. `OPENROUTER_API_KEY` pre-flight fails fast. `test/aider-turn.sh` (32 checks, incl. relay-dispatch + token-ownership guard + aux-file redirect) + `test/consult.sh` (+2 aider checks) in `validate.sh` — green. **Live E2E DONE 2026-07-03** — a real `gpt-4o-mini` turn via OpenRouter, which surfaced + fixed the aux-file containment bug (below). | Optional follow-on: add `aider-turn.sh` to the vendored `relay-pkg` (make-pkg) if a consumer needs it. |

> **Live-E2E fix (2026-07-03).** The first real Aider turn failed **exit 6** — Aider writes its own `.aider.chat.history.md` + `.aider.input.history` into CWD, which (with `--no-gitignore`) land untracked and trip `rtl_enforce`'s off-allowlist guard, so **every real turn failed** even though the stub tests (which never create them) passed. Fix: the shim redirects Aider's chat/input/llm history files to a throwaway dir outside the repo via `--chat-history-file`/`--input-history-file`/`--llm-history-file`. Re-run confirmed **exit 0**, a file-scoped commit (relay file only), no `.aider.*` leak, token handed to the peer. Regression: the test stub now mimics Aider's aux-file write, so dropping the redirect flips the good turn back to exit 6.

## Problem

The harness has headless lanes for Codex (`codex-turn.sh`) and agy (`agy-turn.sh`) but none for Aider ↔ OpenRouter. OpenRouter is an OpenAI-standard gateway to the whole model catalog behind one key, so an Aider lane adds broad build-model diversity with no new provider integration. The lane must be **discrete from Codex** so working on one never risks the other.

## Design

`relay-automation/aider-turn.sh` — thin dispatch wrapper over `relay-turn-lib.sh`, same containment contract as codex/agy. Two differences, because Aider is a file-EDITOR (no mid-turn shell) that auto-commits:

1. **Shim-owned token ops.** Aider won't run `tick`. The shim `claim`s the specific `RELAY_TASK` — `tick claim <task> --agent <me> --paths <relay+artifacts>`, NOT `tick take` (which grabs *whatever* task is offered to the agent, not the named one — the root-cause bug caught in testing) — then `ping`s. After the turn, `rtl_enforce` (GH-67) does the authoritative `release --to <peer>` / `done` from the relay file's STATUS; it's ownership-guarded, so it only works because the shim made this agent the claimer.
2. **`--no-auto-commits`.** Aider auto-commits by default; the moved HEAD would trip `rtl_enforce`'s commit-bypass guard (exit 6) every turn. The harness owns the file-scoped commit.

OpenRouter needs no base-url flag — `--model openrouter/…` + `OPENROUTER_API_KEY` is Aider-native. Config: `AIDER_MODEL` (default `openrouter/anthropic/claude-3.5-sonnet`), `AIDER_BIN`, `AIDER_FLAGS`, `AIDER_TURN_ROOT`, `AIDER_LOG`; honors `ALLOW_PATHS`, `RELAY_PEER`, `RELAY_WORKTREE_ISOLATION`, `RELAY_TURN_TIMEOUT_S`. Files added to the chat via `--file` (relay file + each `ALLOW_PATHS` artifact) as ROOT-relative paths so worktree isolation copy-back works. Exit contract mirrors agy: 0 · 5 (failed/no-key/empty) · 6 (off-lane) · 7 (timeout) · 2 (usage).

Routing: `marathon-agent.sh` dispatches `AIDER_AGENT`; `marathon-drive.sh` `route_agent` maps `aider*` → `AIDER_AGENT` (builder lane). Both additive; Codex/agy branches unchanged.

## QA gate

- [x] `test/aider-turn.sh` (32 checks): defer, good turn + token handoff to peer, **aux/history files redirected out of the tree (no `.aider.*` leak — GH-77 live-E2E fix)**, Approved → `tick done`, **unowned-token refusal (exit 5 before any mutation — GH-77 review [Blocker] fix)**, off-lane/commit-bypass/spaced-path revert (exit 6), empty-output (exit 5), missing `OPENROUTER_API_KEY` (exit 5), ambient WIP untouched, worktree isolation copy-back
- [x] **Live E2E against a real OpenRouter key (2026-07-03):** real `gpt-4o-mini` turn → exit 0, file-scoped commit, no `.aider.*` leak, token handed to peer
- [x] Codex/agy/marathon tests unchanged and green (routing is additive)
- [x] `validate.sh` green with the new test
