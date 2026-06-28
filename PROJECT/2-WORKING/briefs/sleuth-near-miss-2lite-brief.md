---
title: Builder brief — Sleuth "Near-Miss 2-lite" deterministic "did you mean?" tier
status: Phase 0 — pre-registration (brief for the Sleuth marathon dogfood)
created: 2026-06-24
updated: 2026-06-24
owner: Noel (with Claude Code, Opus 4.8)
parent: PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md
goal: >
  Builder brief for the headless Marathon turn: insert a deterministic, flag-gated
  near-miss "did you mean?" recovery tier at Sleuth's mention-dispatch dead-end,
  reusing the existing scorer — additive, default-OFF, suggest-only.
---

# Phase brief — Sleuth "Near-Miss 2-lite" deterministic "did you mean?" tier

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 pre-registration brief written (task, dispatch seam, flag, scorer reuse all specified). | Fire the Marathon turn against `sleuth-app` per the parent dogfood doc — or retire the brief if the substrate is superseded. |

**Repo:** sleuth-app (Node) · **Branch:** marathon-dogfood/near-miss-2lite
**Read first:** `ARCHITECTURE.md` and `PROJECT/1-INBOX/COMMAND-NEAR-MISS-AI-FALLBACK.md` (Phase 2-lite).
**Match repo conventions:** `Arg`-prefixed params, `#Try…Async` private methods, PascalCase functions.

## Task (additive, flag-gated, default-OFF — NO regression when OFF)

Insert a deterministic near-miss recovery tier at the mention-dispatch dead-end, reusing the existing
scorer. **No LLM, no auto-execution, suggest-only.**

1. **Flag:** add `COMMAND_NEAR_MISS_LITE` (default OFF), read the same way other Sleuth feature flags
   are read. OFF ⇒ behavior is byte-for-byte unchanged.
2. **Tier:** add `#TryHandleNearMissCommandAsync(ArgSlackApp, ArgEventInfo, NormalizedCommandText)` to
   `src/chat-module.js`, called at the seam **between the Phase 0 probe (line ~807) and the generic-AI-chat
   fallthrough (line ~809)** — i.e. after all deterministic routes + web-search auto-routes declined.
   - When the flag is OFF → return `false` immediately (fall through).
   - Score the message via the existing `RetrieveScoredCandidates` (`src/command-intent-resolver.js:459`,
     surfaces `{ Entry, Score }`). Do NOT use `RetrieveCandidateCommands` (it discards the score).
   - If the top candidate's `Score` ≥ a **score floor** (a named placeholder constant, e.g.
     `NEAR_MISS_SCORE_FLOOR`, with a comment that it is provisional pending Phase 0 counter data):
     reply with that candidate's syntax example — *"Did you mean the `<id>` command? Try `<syntax>`."* —
     and return `true`.
   - Below the floor → return `false` (fall through to today's generic chat).
3. **Loop safety:** never act on the bot's own messages (mirror existing guards).

## Constraints
- **ALLOW_PATHS only:** `src/chat-module.js`, `src/command-intent-resolver.js` (only if a one-line
  export of `RetrieveScoredCandidates` is needed), `tests/command-near-miss-lite.test.js` (new). Touch
  nothing else.
- **Suggest-only:** no execution, no model call, no nagging on genuine conversation.

## Definition of done (the objective gate)
- New `tests/command-near-miss-lite.test.js` proves: (a) flag OFF → no near-miss reply (current
  behavior); (b) a high-score wrong-syntax miss → exactly one "did you mean" suggestion; (c) a
  below-floor conversational message → falls through, no suggestion.
- `npm run validate:commands` passes.
- `npx jest command-intent-resolver catalog-regex-aliases chat-module --silent` passes at **≥134/0**
  (clean baseline was 134/0; your new tests add to it).
- Bump `package.json` version + CHANGELOG per AGENTS.md.
