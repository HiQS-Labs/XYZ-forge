---
Goal: Adversarially validate a diagnosis about DeusData/codebase-memory-mcp before it is filed upstream
Date: 2026-08-30
Producer: commandcode
Reviewer: deepseek
NEXT: Producer
STATUS: Open
---

# Context

A three-arm duplication audit of an unrelated repo used `codebase-memory-mcp` as one arm. It found
that the knowledge graph cannot answer *"the same decision is encoded in several places with
different values"* — the highest-value class of duplication — and traced that to `Variable` nodes
carrying no `value` property.

**Before this is filed upstream, the diagnosis needs to be adversarially checked.** A wrong or
overstated claim in a public issue against a healthy project is worse than no issue.

## The repo under review

`/Users/noelsaw/Documents/GH Repos/codebase-memory-mcp` — upstream `DeusData/codebase-memory-mcp` at
HEAD `ec08f76`, which is **after** the `v0.10.8` release. It is a C codebase (~2,114 files).
Read it directly. Do **not** edit it; this is a review turn.

## The claim to validate

> The indexer **already extracts** module-level `NAME = "value"` constant pairs, and then **discards
> them**. They are held in `CBMStringConstantMap` — declared at `internal/cbm/cbm.h:557-563`,
> carried on the extraction context at `internal/cbm/cbm.h:595`, populated by
> `handle_string_constants` at `internal/cbm/extract_unified.c:984` (and `:1052`, `:1238`), and
> consumed at `internal/cbm/extract_calls.c:40,53` purely for constant propagation into call
> arguments. The map is per-file, capped at `CBM_MAX_STRING_CONSTANTS` = 256, and is never written
> onto the emitted node. `CBMDefinition` (`internal/cbm/cbm.h:185-232`) — the struct that carries
> `label = "Variable"` (emitted at `internal/cbm/extract_defs.c:5358`, `:5497`, `:6708`, `:6736`) —
> has **no** `value` field. Therefore `Variable` nodes in the graph expose no value, and a Cypher
> query like `MATCH (a:Variable),(b:Variable) WHERE a.name =~ '.*MAX_BYTES.*' AND a.value != b.value`
> is not expressible.
>
> **Consequence claimed:** exposing this is an *exposure* change over data the extractor already
> computes, not a new extraction capability — and is therefore far cheaper than it first appears.

The two real-world misses that motivated it, both of which had to be found by grep instead:

1. One BigQuery byte ceiling written in **15 places with 7 different values**, under four different
   constant names plus inline literals — e.g. `_MAX_BYTES_BILLED = 2_000_000_000` shipped under a
   comment reading `# 2 GiB hard ceiling` (a 7.4% discrepancy between stated and actual policy).
2. **Five rival definitions of "what counts as a paid order", with three different value sets** —
   `_REVENUE_VALID_STATUSES`, `_REAL_SALE_STATUSES`, `PAID_FINANCIAL_STATUSES`,
   `MONEY_COLLECTED_STATUSES`, plus 11 inline sites. These share **no name token** and live in five
   packages with disjoint imports, so identifier search cannot find them, and `SIMILAR_TO` does not
   apply because they are module-level constants rather than function bodies.

# Questions — answer each with `file:line` citations

1. **Is the claim true at HEAD `ec08f76`?** Specifically: does `CBMDefinition` still lack any
   value/initializer field, and is `CBMStringConstantMap` genuinely discarded after extraction rather
   than surfaced on a node or an edge somewhere the audit missed? Check the graph-write path and the
   MCP schema output (`get_graph_schema`), not just the struct. **If any part is already exposed,
   say so and kill the issue.**

2. **Is `CBMStringConstantMap` string-literal-only?** `values[]` is `const char *` and the populator
   is named `handle_string_constants`. Would a numeric constant — `10 * 1024**3`, `2_000_000_000`,
   `256 * 1024 * 1024` — be captured at all, or does miss #1 above still require new extraction work?
   Be precise: captured-but-as-text is a different answer from not-captured.

3. **Does it capture tuple / collection values** like `("paid", "partially_refunded")` or
   `frozenset({408, 429, 500})`? Miss #2 depends entirely on this. If it captures only scalar string
   literals, say so plainly — it materially shrinks what the proposed change buys.

4. **What is the real scope of exposing it as `Variable.value`?** Name the files and functions that
   would have to change (struct, populator, graph write, schema, serialization, and the MCP query
   surface). Then attack the design: does the **256-per-file cap** silently truncate on large modules?
   Does the map's **per-file scoping** break anything for cross-file comparison? Is the map populated
   *before* or *after* the `Variable` defs are emitted — i.e. is the data even available at the point
   the node is written, or does this need a second pass? **That last question is the one most likely
   to make the "cheap exposure change" framing wrong; check it first.**

5. **Upstream or fork?** Given the project's activity (v0.10.8 shipped 2026-08-19, ~20 open issues in
   the last two days, several on Go/cgo extraction), is this better filed upstream as a feature
   request, or carried as a local patch? Note that the reporter is running **v0.8.1** — roughly nine
   minor releases behind — so also judge whether being that far behind undermines the report.

Flag anything wrong, overstated, missing, or misattributed. Cite `file:line` wherever you disagree
with a specific claim above. If the diagnosis survives, sharpen it into the two or three sentences
that should open the upstream issue.

Producer: write your findings below. Reviewer: adjudicate them, then set `STATUS: Approved` or
`STATUS: Closed` if the answer is settled either way.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (commandcode)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
