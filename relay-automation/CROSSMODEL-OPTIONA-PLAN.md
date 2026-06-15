---
title: Cross-model relay (Claude ↔ Codex) via headless `codex exec` — Option A wiring
status: Draft (for Codex relay-review)
created: 2026-06-15
builds-on: Phases 1–4 + (a) tick-native + self-expiring loops; Option-A headless spike PASSED 2026-06-15
---

# Cross-model relay: Claude ↔ Codex, Codex driven headless by `codex exec`

## Goal
A real `/relay` where the **Codex side takes its turns with no window** — `codex exec`
reads the relay file, writes its block, advances the `RELAY-TURN` token, commits. Proves
**cross-model coordination** (closes item 196's cross-model sense) and lands **Option A**
(headless CLI) for the Codex participant. The Claude side stays as today (`/loop` poll, or manual).

## Spike facts (2026-06-15)
`codex exec "<prompt>" < /dev/null` → non-interactive, authed (`approval: never`,
`sandbox: workspace-write`), emits a parseable `VERDICT:`, exit 0; ~11k tokens for a trivial
turn (Codex defaults high reasoning). So Codex can read/edit files + run `tick`/`git` in-turn.

## Design decisions (resolve in review)
1. **Who dispatches the Codex turn?**
   - **D1 — supervisor:** `relay-drive.sh --agent-cmd "codex exec \"$(turn-prompt)\" < /dev/null"` drives whichever side holds the token; for the Codex side the agent-cmd is `codex exec`.
   - **D2 — poll cross-model dispatch:** `poll.sh`'s cross-model branch, instead of *printing* the nudge, *runs* `codex exec` when the token is handed to a Codex agent. (Lean **D1** for a first cut — one driver, explicit; keep poll's cross-model branch as the nudge for the non-headless case.)
2. **The Codex turn prompt.** Pass the embedded ▶ TAKE-YOUR-TURN steps + the relay-file path; instruct Codex to: claim+ping `RELAY-TURN`, append its graded review block + verdict to the relay file, `tick release --to <claude>` (or `done`+`STATUS: Approved` on approve), commit + push. (Codex has workspace-write, so it can.)
3. **Budget cap.** A per-turn token ceiling and a per-relay round cap (`relay-drive --round-cap`), since each Codex turn is a real API spend. Document a sane default (e.g. cap rounds at 4; note ~tokens/turn).
4. **Tree-scope safety.** Codex runs with workspace-write over the repo. Constrain its turn to the artifact + relay file (prompt instruction + the artifact-scoped clean-tree gate already in place); flag if a tighter sandbox (`-c sandbox_permissions=...`) is warranted.
5. **Verdict extraction.** `codex exec` wraps output in transcript chrome; `grep 'VERDICT:' | tail -1` (runner already does this) — confirm robust against Codex's formatting.

## Sub-steps
- **X1 — turn-taker shim:** a small `codex-turn.sh` (or `--agent-cmd` string) that builds the turn prompt from the relay file and runs `codex exec ... < /dev/null`, returning Codex's output for verdict parse. *Accept:* a fake-`codex` test (inject a stub `codex` that emits a block + VERDICT) drives one Codex turn through `relay-drive.sh`.
- **X2 — live cross-model run:** one real Claude↔Codex relay on a small artifact; Codex turn headless via `codex exec`. *Accept:* relay closes `Approved`, Codex's block present, captured metrics (rounds, tokens, human interventions).
- **X3 — record:** close item 196 cross-model; update Option-A status; capture cost.

## Risks
- **Cost** (real tokens/turn) — cap rounds + note spend.
- **Codex editing the shared tree** unexpectedly — constrain via prompt + clean-tree gate; consider a tighter sandbox flag.
- **Commit/push from Codex** — ensure Codex commits only the relay file + artifact (file-scoped), and that its git identity/attribution is acceptable.
- **Prompt-injection surface** on an unattended agent (Option-A general caveat).

## Open questions for the reviewer (Codex)
1. D1 (supervisor `--agent-cmd`) vs D2 (poll dispatches `codex exec`) — right call for a first cut?
2. Is `codex exec` workspace-write over the whole repo acceptable for a relay turn, or should we pass a tighter `-c sandbox_permissions`/`--cd` scope?
3. Biggest risk you see in letting `codex exec` take + commit a relay turn unattended, and the cheapest mitigation?
