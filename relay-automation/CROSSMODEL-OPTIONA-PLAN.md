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

## Design (hardened by Codex review 2026-06-15 — see footer)

**A mandatory safety shim `relay-automation/codex-turn.sh` is the turn-taker** (not a raw
`--agent-cmd` string — too brittle and no place to enforce safety). `relay-drive.sh
--agent-cmd "relay-automation/codex-turn.sh"` invokes it; the shim:

1. **Dispatches only for its agent.** Acts only when `RELAY_AGENT` is the Codex agent; for any other actor it **no-ops/defers** (that window drives its own turn). Fixes the "one `--agent-cmd` can't drive both sides" gap — Claude turns stay window-driven, Codex turns go headless.
2. **Builds the turn prompt** (embedded ▶ TAKE-YOUR-TURN steps + relay-file path) and runs `codex exec "<prompt>" < /dev/null`, capturing the transcript.
3. **Enforces a path allowlist itself** (the clean-tree gate is in `poll.sh`, NOT `relay-drive.sh`, so the shim owns this): snapshot `git diff --name-only` before; after the turn, **hard-fail + revert if any changed path is outside {relay file, artifact allowlist}**; stage **only** those exact paths.
4. **Commits file-scoped, NO push.** Coordination is shared-local `.tick/events/`; `tick` no longer depends on push, so unattended turns must not push (drops a failure mode). Push stays a separate operator step.
5. **Extracts the verdict** from the transcript (`grep 'VERDICT:' | tail -1`) for the supervisor.
6. **Budget cap:** `relay-drive --round-cap` (default ≤4) + note ~tokens/turn; each Codex turn is real API spend.

The supervisor's existing **close-mismatch + no-progress escalation** ([Pass]) provide the
containment for unattended turns; `poll.sh`'s cross-model branch stays the **manual-nudge
fallback** for non-headless agents ([Pass]).

## Sub-steps — ✅ SHIPPED 2026-06-15 (X1 + X2 done)
> **X1 ✅** `codex-turn.sh` built + `test/codex-turn.sh` 10/10 (dispatch-gating, allowlist revert, no-push, log-in-tree handling). `validate.sh` 19/19.
> **X2 ✅** live run: a real `codex exec` turn (no window) took a relay Reviewer turn in an isolated repo — found the seeded typo, wrote a graded block + verdict, released the token, and the shim committed **only `relay.md`, file-scoped, no push** (verified: repo had no remote; commit touched 1 file). **Cross-model coordination + Option A proven end-to-end.** Cost: a real Codex turn is tens-of-k tokens (cap rounds).
> **X3** record (this section + CHANGELOG + hub).

- **X1 — `codex-turn.sh` shim (mandatory) + test.** Build the shim per the Design above. *Accept:* a test injecting a **stub `codex`** that performs the *real turn-taker contract* — `tick claim/ping/release|done` **and** mutates the relay file (not just emits `VERDICT:`) — drives one turn through `relay-drive.sh`; plus a negative test: the stub touches an **off-allowlist file** → the shim **reverts it, stages nothing extra, and fails** (proves the allowlist guard). No push occurs.
- **X2 — live cross-model run:** one real Claude↔Codex relay on a small artifact; Codex turn headless via `codex exec` through the shim. *Accept:* relay closes `Approved`, Codex's block present, only allowlisted files changed, no push; captured metrics (rounds, tokens, human interventions).
- **X3 — record:** close item 196 cross-model; update Option-A status; capture cost.

## Risks
- **Cost** (real tokens/turn) — cap rounds + note spend.
- **Codex editing the shared tree** unexpectedly — constrain via prompt + clean-tree gate; consider a tighter sandbox flag.
- **Commit/push from Codex** — ensure Codex commits only the relay file + artifact (file-scoped), and that its git identity/attribution is acceptable.
- **Prompt-injection surface** on an unattended agent (Option-A general caveat).

## Resolved by Codex review (2026-06-15, headless via `codex exec` — the review itself dogfooded Option A)
**Verdict: Changes requested → all disposed into the Design/Sub-steps above.**
- [Blocker] D1 had no per-agent dispatch → **shim keyed on `RELAY_AGENT`** (no-op for non-Codex actors).
- [Blocker] clean-tree gate is in `poll.sh`, not `relay-drive.sh` → **the shim enforces the path allowlist itself** (diff before/after, revert off-lane, stage only allowlisted).
- [Blocker] `commit + push` is stale (shared-local `.tick`) → **commit file-scoped, NO push.**
- [Should] don't test a VERDICT-only fake → **X1 stub does the real `tick claim/ping/release/done` + file mutation**, plus a negative allowlist test.
- [Should] raw `--agent-cmd` brittle → **`codex-turn.sh` is mandatory.**
- [Pass] supervisor close-mismatch/no-progress guards = solid containment; `poll.sh` cross-model branch stays the manual fallback.
- Answers: D1-via-shim (D2 risks double-fire); repo-wide workspace-write not acceptable alone → shim allowlist is the real control; biggest risk = unattended off-lane edits getting committed → mitigated by the diff-allowlist + drop-push.
