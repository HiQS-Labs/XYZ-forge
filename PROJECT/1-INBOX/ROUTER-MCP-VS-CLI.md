---
title: "ROUTER routing as an MCP vs CLI — worth-it verdict"
status: Proposed (1-INBOX — not yet active)
created: 2026-06-21
doc_type: feedback
---

# ROUTER routing: MCP vs CLI — worth-it verdict

Verdict: Not yet — likely Not worth it as an MCP. The benefit is asserted against a do-nothing baseline that currently costs ~nothing (we just routed a real issue correctly by reading ROUTER.md), and the MCP's carrying cost includes the one thing this repo's governance exists to prevent: a second source of truth.

Scorecard:

Test	Read
Needle	Operator/contributor forward (agent finds next step without 2-3 reads). But maintainability backward: an MCP that encodes routing = a copy of ROUTER/PDDA rules that must stay in sync — the exact fragmentation PDDA fights. If it instead just cats the markdown, it's a glorified file-read and adds ~nothing.
Reach	Every agent session — but per-event impact is tiny (the agent already reads these files well). Strongest case is non-Claude agents (Codex/agy) that don't auto-load CLAUDE.md — yet those call a CLI just as easily as an MCP tool.
Confidence	Asserted. Your own words: "a problem we did not experience yet." Zero measured instances of an agent failing to find next steps.
Price	Build a server + .mcp.json per clone + schema; carrying cost forever. And per your own memory, MCP servers go absent in headless/cron runs and are sandbox-fragile — so the routing aid vanishes exactly in the autonomous runs that'd benefit most. Displaces relay/marathon work.
Do-nothing	Agents read ROUTER.md + PDDA.md today; it works. Status-quo cost ≈ 0 right now.
Reversibility	Costly — once clones depend on .mcp.json and agents call the tool, removing it is a migration. A script is just a file you delete.
The repo-specific kicker: we spent the last two turns enforcing "PDDA owns the contract, ROUTER points, no duplicated spec." An MCP that re-encodes routing logic would violate that principle on day one. Building it would contradict the governance we just reinforced.

Cheaper version (the 20% that's the whole point): a deterministic CLI — bin/router next (or utils/router-next.sh) — that parses the canonical docs (ROADMAP's active entry → the linked PROJECT doc's ## Status "What's next" cell) and prints the next action. It reads the markdown rather than re-encoding it, so it stays single-source; it fits the existing validate.sh / pdda-*.sh rail; any agent (Claude, Codex, agy) calls it via Bash; no daemon; survives headless runs; deleting it is reversible in seconds. Optionally front it with a Claude Code skill for interactivity.

Do next: Don't build the MCP. Don't build the CLI yet either — there's no measured pain. If you notice agents actually scavenger-hunting for next steps, that observation is the trigger: build the CLI slice first, and reserve MCP for the day a non-CLI consumer appears that genuinely needs a structured protocol. Right now that consumer doesn't exist.

So: yes — it'd be overengineering a problem you haven't hit. File the idea (it's a legitimate GH- candidate if you want it tracked), and let real friction, not anticipation, pull it into existence.