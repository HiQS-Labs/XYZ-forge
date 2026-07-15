---
gh_issue: 211
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/211
title: "Consult and Relay - Compact shorter summaries TLDR;"
status: built 2026-07-15 — consult/SKILL.md updated in this repo; relay/SKILL.md updated + committed (not pushed, operator's call) in giant-brains-claude-skills `eb9271b`
created: 2026-07-15
updated: 2026-07-15
owner: noel
doc_type: enhancement
complexity: 1
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not changing relay's/consult's mechanics, grading vocabulary, verdict semantics, or reconciliation order (disagree-first stays load-bearing).
  - Not touching the relay-system/<date>/<slug>.md file format or consult.sh's transcript output — only the chat-facing report the agent gives the operator.
related:
  - skills/consult/SKILL.md (xyz-3-agents-swarm, canonical)
  - giant-brains-claude-skills/04-build/relay/SKILL.md (external repo, symlinked in via ~/.claude/skills/relay)
  - giant-brains-claude-skills/02-plan/linear/SKILL.md (pattern source: TLDR-before-detail, concise-but-detailed)
  - giant-brains-claude-skills/04-build/rabbit-hole/SKILL.md (pattern source: sorted-bucket triage)
goal: >
  Make relay's and consult's chat-facing output (not the relay log file or consult transcripts)
  open with a compact TLDR and close with feedback sorted into fixed categories, borrowing
  linear's "TLDR up front, detail below, nothing forces structure on trivial cases" discipline
  and rabbit-hole's "one sorted triage, not scattered prose" bucketing — so a user skimming a
  relay turn or consult synthesis gets the bottom line first and a scannable, grouped list of
  findings last, instead of prose they have to parse for both.
---

## Status

| What was just completed | What's next |
|---|---|
| Operator confirmed scope (pull + edit + commit in `giant-brains-claude-skills`, push left to operator). Pulled that repo (`5fcd9cc`, ff-only, unrelated reorg). Added a **Reporting to the human** section to `04-build/relay/SKILL.md` (TLDR promoted to line one, findings sorted `[Blocker]`→`[Should]`→`[Nit]`→`[Pass]` at the close, gated on volume) and committed there (`eb9271b`, unpushed). Added a **TLDR** + **Sorted categories** (Blocking / Worth doing, optional / Skip) to `consult`'s reconciliation step in `skills/consult/SKILL.md` here, keeping disagree-first ordering and verdict semantics unchanged in both skills. | Operator reviews and pushes `giant-brains-claude-skills` `eb9271b` when ready (not pushed by design). No further action needed here unless a live relay/consult run surfaces a gap in the new format. |

## Problem (as scoped in issue #211)

- `relay`'s and `consult`'s chat-facing reports lean on prose paragraphs (relay's "Framing" section, consult's "Disagree → Agree → Reconciled call" synthesis) with no mandated compact-summary-first / sorted-list-last shape, so a user has to read the whole reply to get the bottom line and again to extract the actionable findings.
- `relay` already has a grading vocabulary (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) but it's only specified for the turn block written into the relay log file — not for what the agent says back to the user in chat.
- `consult`'s synthesis is already ordered (disagree first, deliberately — "never average it away") but has no upfront TLDR and no sorted actionability buckets (blocking / optional / skip) at the close.

## Direction

Borrow, don't invoke: `linear` and `rabbit-hole` are output-shaping skills for *this* conversation's replies, not something `relay`/`consult` should call at runtime. Instead, fold their patterns into each skill's own "how to report to the operator" section:

- **TLDR at top** (linear's discipline): one to two sentences, the bottom line, before any framing prose — "Round 2 Reviewer done — Changes requested, 1 Blocker" (relay); "Both models agree the change is safe; Codex flagged one edge case" (consult).
- **Sorted categories at bottom** (rabbit-hole's discipline): group findings into fixed buckets instead of chronological/prose order — relay reuses its own `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` grades; consult adds a **Blocking / Worth doing, optional / Skip** triage under its existing Disagree → Agree → Reconciled-call synthesis.
- Keep both skills' existing load-bearing rules intact: relay's verdict semantics and file-vs-chat separation; consult's disagree-first ordering.
- Gate structure on volume, per `linear`'s own rule: 0–2 trivial findings or a clean Approved/agreement stays plain prose — don't force a bucketed list where there's nothing to sort.
