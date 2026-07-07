---
gh_issue: 163
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/163
title: "Review wp-code-check / WP-DB-Toolkit for existing fast AST tooling reusable for swarmability"
status: Phase 0 complete — verdict recorded, not applicable to GH-156 as-is
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: research
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not a commitment to adopt either repo's tooling verbatim
  - Not a build lane — this is a review that feeds GH-156's Phase 0, not a standalone feature
related:
  - PROJECT/1-INBOX/GH-156-SWARMABILITY-PRELIGHT.md
  - ~/Documents/GH Repos/wp-code-check
  - ~/Documents/GH Repos/WP-DB-Toolkit
goal: >
  Determine whether wp-code-check or WP-DB-Toolkit already ship fast AST parsing infrastructure
  that could be reused for GH-156's swarmability-scoring work, instead of building fresh parsing
  infra from scratch.
roadmap_exempt: false
---

## Key concepts

- GH-156 (swarmability prelight) needs to reason about task-scoped code impact; building an AST
  parser from scratch may be unnecessary if a sibling repo already has one.
- `wp-code-check` and `WP-DB-Toolkit` are sibling repos on disk (`~/Documents/GH Repos/`), same
  author, built for a related static-analysis purpose.
- This is a review/spike, not a build: confirm existence, language coverage, and whether the output
  shape fits GH-156's graph-signal model.
- Feeds directly into GH-156's Phase 0 scoring contract — the outcome here is an input to that
  doc, not a standalone deliverable.

# GH-163 · Review wp-code-check / WP-DB-Toolkit for existing fast AST tooling

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 complete (2026-07-07): both sibling repos opened and read. Verdict: **not applicable as-is** — neither repo ships reusable general-purpose AST/call-graph infra for GH-156's stated need. See findings below. | Feed this verdict into GH-156's Phase 0 scoring-contract doc: budget for building fresh parsing infra (nikic/php-parser for PHP + a JS parser) rather than assuming reuse. No further work needed on this doc unless GH-156's owner wants deeper detail. |

## Idea

Review sibling repos `wp-code-check` and `WP-DB-Toolkit` (both on disk under
`~/Documents/GH Repos/`) for already-existing fast AST tooling that could be reused for this
repo's swarmability/parallelization scoring work (GH-156) instead of building fresh parsing
infra.

## Why

GH-156 (Prelight: swarmability scoring using codebase-memory-mcp graph signals) needs to reason
about task-scoped code impact to suggest safe parallel lanes. If `wp-code-check` or
`WP-DB-Toolkit` already ship a fast AST parser (for JS/PHP or similar) built for a related static-
analysis purpose, reusing or adapting it could be materially cheaper than building new parsing
infra from scratch for the swarmability prelight.

## Phase 0 — Explore & scope

Purpose: confirm what actually exists before GH-156 commits to building anything new.

### Checklist

- [x] Open `wp-code-check`: identify whether it has AST parsing (vs. regex/heuristic checks), which
      language(s) it covers, and how the parser is invoked (library, CLI, or embedded).

  **Finding:** Yes, but narrow. `dist/bin/ast/wpcc-ast-check.php` uses a real parser —
  **nikic/php-parser** (via `PhpParser\ParserFactory`, `NodeTraverser`,
  `ParentConnectingVisitor` — `wpcc-ast-check.php:28-30,102-103,120,129`). It sits alongside the
  main product, which is otherwise regex/grep-based (`package.json:3` markets itself as "zero
  dependencies"). Caveats:
  - **PHP only** — no JS/TS parser anywhere in the repo (grepped for Babel/acorn/esprima/
    tree-sitter: zero matches).
  - The `nikic/php-parser` dependency itself is **not vendored** — it's resolved at runtime from
    `temp/WP-PHP-Parser-loader/lib/PhpParser` (`dist/bin/ast/autoload.php:33-40`), a separate
    gitignored external plugin (`kissplugins/WP-PHP-Parser-loader`), not shipped with this repo.
  - **CLI-only, not wired into the main scanner.** `wpcc-ast-check.php` is a standalone script
    taking `--paths/--rule/--config/--output`; grepping `wp-audit` and all `dist/bin/*.sh` entry
    points for calls into it returns zero matches. It's recent, experimental, in-progress work
    (`CHANGELOG.md:4332-4333`, "[1.0.5] - 2025-12-27", "Phase 2.5: PHP-Parser Deep Analysis").
  - The visitor classes (`ReturnArrayShapeVisitor`, `HookRegistrationVisitor`) are plain PHP
    classes with public getters, so technically importable if you supply your own PhpParser
    autoload — but there's no packaged module, no published API, no JS/Node bridge.

- [x] Open `WP-DB-Toolkit`: same three questions.

  **Finding:** No real AST/parser-library infra for JS/PHP/SQL. The only real-parser usage anywhere
  is Python's stdlib `ast` module (`scan-registry.py:18,66-68`), used narrowly to pull a docstring
  first-line out of the repo's own `.py`/`.sh` scripts for a doc-registry linter — not for symbols,
  calls, or structure. Everything else that looks like parsing is regex: `chunk_code()`
  (`wpdbtk/ask_self_helpers.py:74-130`) splits Python source into RAG chunks on a regex match for
  `def`/`class` lines, no real parse, no scope awareness. No `@babel/parser`, `acorn`, `esprima`,
  `php-parser`/`nikic/php-parser`, `tree-sitter`, `sqlglot`, or `sqlparse` dependency exists anywhere
  (no `composer.json` in the repo at all; `package.json` only has `@playwright/test`;
  `requirements.txt` files list FastAPI/mlx, no parser libs). SQL is handled as data (mysqldump
  exports, BigQuery views), not parsed into a syntax tree. `scan-registry.py` is a private CLI
  linter, not a reusable library — confirmed by inspecting the MCP tool registry
  (`wpdbtk-mcp.py:9-26`), which exposes only WooCommerce/MySQL data-extraction and RAG (self-ask)
  tools, nothing code-structural.

- [x] For any AST tooling found, note its output shape (raw AST, symbol list, call graph, etc.) and
      compare against GH-156's proposed output schema (`swarmability_score`, `candidate_lanes`,
      `shared_surfaces`, `hotspots`, `reasons`).

  **Finding:** `wp-code-check`'s AST subsystem outputs **flat JSON findings + narrow auxiliary
  lists**, not a graph. `generate_finding()` (`wpcc-ast-check.php:398-419`) produces violation
  records: `{id, severity, impact, file, line, message, code, context, guards, sanitizers}`. The
  closest thing to structure is `HookRegistrationVisitor`'s three flat arrays
  (`HookRegistrationVisitor.php:52-66`): `registrations` (hook↔callback bindings),
  `fire_points` (`do_action`/`apply_filters` call sites), and `callables` (keyed function/method →
  params map). This is a narrow, WordPress-hook-specific bipartite relation (hook name ↔
  callback), **not** a general call graph, symbol table, or import/dependency graph — it has no
  concept of arbitrary function-to-function calls. Parsed AST/Node objects are consumed transiently
  in-process and never serialized. **None of this maps onto GH-156's proposed schema**
  (`swarmability_score`, `candidate_lanes`, `shared_surfaces`, `hotspots`, `reasons`) — there's no
  notion of "lanes," "shared surfaces," or a score anywhere in either repo. WP-DB-Toolkit's nearest
  analog, `ChunkRow`/`SearchHit` (`ask_self/ask_self_backend.py:21-57`), is a flat
  text-chunk-plus-embedding-vector record for semantic search — no function/caller/callee/import
  fields at all, also no match to GH-156's schema.

- [x] Record a clear verdict: reusable as-is, reusable with adaptation, or not applicable — with the
      concrete reason in each case (language mismatch, output shape mismatch, licensing, etc.).

  **Verdict: Not applicable, for both repos**, against GH-156's stated need (parse code into
  symbols/call graphs for task-scoped impact reasoning):
  - `wp-code-check`: language mismatch (PHP-only, GH-156 likely needs JS too), output-shape
    mismatch (flat findings/hook-wiring lists, not a symbol/call graph), and integration mismatch
    (external non-vendored dependency, CLI-only, not wired into anything, experimental/unreleased).
  - `WP-DB-Toolkit`: no real parser infra at all for JS/PHP/SQL — only a narrow stdlib-`ast` use for
    docstring extraction and a regex-based RAG chunker. Nothing structural to reuse.
  - **One reuse candidate at the design-pattern level, not the code level:** `wp-code-check`'s
    `HookRegistrationVisitor` (visitor pattern over `nikic/php-parser`'s AST) is a reasonable
    reference for *how* to build a PHP-side call/hook extractor, if GH-156 ends up needing one —
    but the library dependency, JS-side coverage, and the actual graph data structure would all
    still need to be built fresh.

- [x] If reusable, note the adaptation cost so GH-156's Phase 0 can factor it into that doc's scoring
      contract decision.

  **N/A — no reusable component found**, so there is no adaptation cost to estimate. GH-156's
  Phase 0 should plan to build fresh parsing infra (e.g. `nikic/php-parser` for PHP + a JS parser
  such as `@babel/parser` or `tree-sitter` for JS/TS) from scratch, rather than budgeting time for
  adapting either sibling repo's tooling.

### QA checklist — Phase 0

- [x] Both repos were actually opened and read, not assumed from memory or naming.
- [x] The verdict is one of the three concrete outcomes above, with a stated reason.
- [x] If a reusable candidate is found, the finding is written back into GH-156's doc (or flagged for
      that doc's owner to incorporate). — No reusable candidate found; this doc's verdict itself
      (see Status table) is the flag for GH-156's owner to incorporate into that doc's Phase 0
      scoring-contract decision.
