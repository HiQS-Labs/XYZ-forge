# Do-not-build list

This is the explicit anti-scope list for PDDA (and any repo-governance/safety layer built alongside
it), distilled from the June 23, 2026 external feedback review (Perplexity, ChatGPT, Gemini) and the
synthesis at
[`PROJECT/2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md`](2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md)
(see its "What to avoid building" section). Its purpose is the same as any anti-scope list: prevent
the same "should we build this?" argument from being re-litigated inside every plan, script, and PR
review. Pair with [`PROJECT/CONSTITUTION.md`](CONSTITUTION.md), which states what PDDA *is*; this
document states what it must not become.

## The list

| Do not build | Because an incumbent already owns it | Named in feedback |
|---|---|---|
| A generic spec-driven-development framework | GitHub Spec Kit, Agent OS, BMad Method already cover spec → plan → tasks → implement | Perplexity, ChatGPT |
| A generic PRD-to-tasks generator as a product surface | Task Master and Spec Kit already do this well | Perplexity, ChatGPT |
| A generic multi-agent platform or agent marketplace | LangGraph, AutoGen, OpenHands, GitHub Agent HQ/Copilot coding agent already cover multi-agent orchestration and autonomous issue-to-PR loops | Perplexity, ChatGPT |
| A full Kanban or visual project-management UI before the CLI/MCP contract is stable | Building a UI on top of an unstable contract locks in the wrong shape early; commodity PM tools already exist | Perplexity |
| Replacements for commodity Markdown linting when off-the-shelf tools are enough | `markdownlint`, Vale, and lychee already solve generic prose/link/header hygiene | Gemini, ChatGPT |
| New Bash or policy complexity unless a measured gap justifies it | Every unmeasured script is maintenance debt; Gemini's explicit "freeze the Bash" signal | Gemini |

Two entries are restated from the synthesis for emphasis, because they are the ones a future
contributor is most likely to reach for by habit:

- **A general replacement for AGENTS.md / CLAUDE.md / repo instruction files.** `AGENTS.md` is an
  open, widely-adopted format; `ROUTER.md` should stay a local index into it, not a competing
  standard. (ChatGPT)
- **A large "AI agile methodology" surface area.** The repo's differentiated lane is local evidence
  plus deterministic governance plus agent safety rails — not a new project-management methodology.
  (ChatGPT, Gemini)

## Why these are excluded, not just deferred

All three feedback sources converge on the same underlying reason, independent of style: PDDA's
value is the parts that are genuinely opinionated and hard to buy off the shelf — the pointer-only
`ROADMAP.md` contract, the exact active-doc lifecycle, the deterministic-before-advisory split, and
agent safety/containment rails (worktree isolation, epoch fencing, commit ownership, recovery). Every
item above is either a solved commodity problem (linting, generic task tracking) or a crowded
platform category (spec-driven development, multi-agent orchestration, autonomous coding runners)
where PDDA's safety-rail differentiation would not survive contact with better-funded incumbents.

## Deferred, not rejected

This list captures the synthesis's "avoid building" bullets. It does not cover the synthesis's
Phases 3–5 (artifact ergonomics, the rebalance evidence bridge, external integrations) — those are
explicitly **deferred pending an open decision**, not placed on this anti-scope list. In particular,
the evidence-bridge idea (Perplexity's distinctive proposal; ChatGPT and Gemini do not raise it) is a
deferred bet, not a rejected one. See the synthesis doc's "Open questions before promotion to
2-WORKING" for what has to be decided before any of that work starts. Do not read this document as
covering that gap — an item's absence here is not permission to build it; check the synthesis doc's
phase status first.

## Reconsideration trigger

An item on this list is fair to reconsider only when a **measured gap** justifies it — the same bar
Gemini's feedback sets for new Bash/policy complexity generally: a real, observed failure of the
off-the-shelf alternative, not a hypothetical nice-to-have. Reconsideration should update this file
and the synthesis doc together, not add scope silently through an unrelated PR.

## Sources

- [`PROJECT/2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md`](2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md)
  — "What to avoid building," "Decision summary," "Open questions before promotion to 2-WORKING."
- [`PROJECT/1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md`](1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md) — Step 20
  ("Decide what to delete or defer") and its "likely avoid building" list.
- [`PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md`](1-INBOX/PDDA/FEEDBACK-CHATGPT.md) — the incumbent
  comparison table and "What I'd stop refining."
- [`PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md`](1-INBOX/PDDA/FEEDBACK-GEMINI.md) — "freeze the Bash" /
  offload deterministic checks to `.markdownlint.json` signal.
