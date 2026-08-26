Build GH-238 in this repo (HiQS-Labs/XYZ-forge): make hq.sh releases-mode aware so intake parking and rollup stop touching ROADMAP.md in repos where the releases DB is the source of truth. Read https://github.com/HiQS-Labs/XYZ-forge/issues/238 first — it is the spec; #169 is the surrounding transition plan.

Two parts, in this order:

PART A — new CLI verb `releases roadmap add` in utils/py/releases_app.py (~3700 lines; study `cmd_add`, the `roadmap sync`/`roadmap list` handlers, and the op_receipts pattern before writing anything):
- Inserts ONE intake row into roadmap_items: GH issue number + URL, title, created date (YYYY-MM-DD), capture-doc relpath (PROJECT/1-INBOX/GH-<n>-<slug>.md). Match the field semantics hq_roadmap_line produces today (utils/hq/hq.sh).
- Follow the house write discipline exactly: GID-keyed row, validated like `add`/`update`, one op_receipts entry, regenerate the canonical releases.sql dump after the write so DB and dump never diverge (mirror how existing write verbs chain into check/rebuild).
- Dup-guard: refuse a second row for the same issue URL with a readable error.
- `--dry-run` that prints what would be written and writes nothing.

PART B — rewire utils/hq/hq.sh (564 lines):
- Write path: in `hq park --create`, when the TARGET repo's mode probe (the existing PDDA_MODE / .pdda-mode checks at ~L223/L345/L384/L428) says releases-mode, call the new verb inside the target repo instead of hq_roadmap_insert (~L254 roadmap= / ~L303 insert). Non-releases repos keep the current text append, byte-for-byte unchanged.
- Preview path (park without --create) must state which sink it WOULD write to (ROADMAP.md line vs releases roadmap add command).
- Read path is OUT OF SCOPE: status/rollup reading via the releases CLI is tracked separately as GH-239 — do not touch LOCAL_ROADMAP/status display here.
- Keep the post-park dashboard regeneration (~L308) firing in both modes (releases-mode may use `releases gen` if that is the right equivalent — check what it emits before deciding).
- Failure mode: releases-mode target but CLI/DB missing or verb fails → explicit error, NO silent fallback to appending ROADMAP.md text.

Tests (hermetic, following the existing suite conventions in test/):
- CLI: roadmap add happy path, dup-guard, dry-run, receipt row present, dump regenerated.
- hq.sh: fixture target repos with and without releases-mode; assert the right sink is chosen, the preview names it, and the no-fallback failure mode holds.

Ground rules:
- ROADMAP.md phase-out context only — do NOT touch the merge/conflict machinery (.gitattributes, releases-merge-resolve.sh); that is settled by GH-32/#53 and the #234 closure.
- Do not invent schema columns; if roadmap_items lacks a field you need, stop and report rather than migrating the schema unilaterally.
- Run the relevant existing tests (utils/validate.sh selection for hq/releases if present) before declaring done, and report pass/fail honestly.
- Deliverable: working code + tests on a branch named gh238-hq-releases-mode, a summary of every file touched, and any spec ambiguities you hit listed explicitly — do not silently choose on ambiguity, list the choice you made and why.
