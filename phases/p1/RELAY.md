# Marathon Phase p1
STATUS: Open
NEXT: agy

<!-- marathon-drive: task=MARATHON-NM2L-R1 builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Phase brief — Sleuth "Near-Miss 2-lite" deterministic "did you mean?" tier

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

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/chat-module.js,src/command-intent-resolver.js,tests/command-near-miss-lite.test.js
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-NM2L-R1 --agent agy --paths "phases/p1/RELAY.md,src/chat-module.js,src/command-intent-resolver.js,tests/command-near-miss-lite.test.js"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-NM2L-R1 --agent agy
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-NM2L-R1 --agent agy --to codex
4. Edit ONLY these paths: phases/p1/RELAY.md and src/chat-module.js,src/command-intent-resolver.js,tests/command-near-miss-lite.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/chat-module.js,src/command-intent-resolver.js,tests/command-near-miss-lite.test.js.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-NM2L-R1 --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-NM2L-R1 --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
