---
title: Builder brief — WPCC ts-type-suppression detector (single-phase Marathon)
status: Active
created: 2026-06-25
updated: 2026-06-25
owner: Noel (with Claude Code, Opus 4.8)
parent: PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md
substrate_repo: WP-Code-Check (cwd is the target repo root via --target-root)
goal: >
  Single-phase --phase-brief fed to the headless Marathon builder: add one additive grep detector pattern
  (ts-type-suppression) + a .ts fixture to WPCC, regenerate the registry, and prove it via the narrow
  per-fixture gate — without touching the scanner core or anything outside the allowlist.
---

# Builder brief: add the `ts-type-suppression` WPCC detector

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-06-25 as the single-phase `--phase-brief` for the WPCC TS-lite dogfood; ALLOW_PATHS + narrow gate pinned. | Fed to the headless agy builder when the parent dogfood fires (awaiting operator GO). |


You are a headless builder operating inside the **WP-Code-Check** repo (your CWD is its root). Build ONE
new grep-based detector pattern. Additive only. Do not modify the scanner core, existing patterns, or any
file outside the allowlist.

## What to build

A new WPCC JSON pattern, `ts-type-suppression`, that flags TypeScript **type-system suppression**
directives in `.ts`/`.tsx` files:

| Must FLAG (bad) | Must NOT flag (good) |
|---|---|
| `// @ts-ignore` | `// @ts-expect-error  needs upstream fix #123` (has an explanation after it) |
| `// @ts-nocheck` | ordinary typed code with no suppression |
| `// @ts-expect-error` with **nothing** after it (bare) | a line that merely contains the text in a string literal, if reasonably excludable |

Severity is **advisory** → use `"severity": "LOW"` (WPCC emits these as warnings, never errors). Category
is `"typescript"`. Scope strictly to `"file_patterns": ["*.ts", "*.tsx"]` — never `.js`.

## Files to create/modify (these and ONLY these)

1. **`dist/patterns/ts-type-suppression.json`** (NEW) — top-level `dist/patterns/` (not a subfolder), so
   the loader picks it up. Mirror the shape of `dist/patterns/headless/api-key-exposure.json`:
   `id`, `version: "1.0.0"`, `enabled: true`, `detection_type: "direct"`, `category: "typescript"`,
   `severity: "LOW"`, `title`, `description`, `rationale`, and a `detection` block with
   `type: "grep"`, `file_patterns`, a `patterns[]` array (one entry per suppression form), and
   `exclude_patterns` to spare a documented `@ts-expect-error` that is followed by explanatory text.
   Include a `test_fixture` block pointing at the fixture below with `expected_violations` set to the
   number of bad cases you put in the fixture.
2. **`dist/tests/fixtures/ts-type-suppression.ts`** (NEW) — contains the bad cases (≥3: one each for
   `@ts-ignore`, `@ts-nocheck`, bare `@ts-expect-error`) AND the good cases (documented
   `@ts-expect-error // reason`, plus a couple of clean typed lines). Label each with a comment.
3. **`dist/PATTERN-LIBRARY.json`** (REGENERATE — do not hand-edit) — run
   `bash dist/bin/pattern-library-manager.sh` from `dist/` so the registry summary/counts include the
   new pattern.
4. **`dist/tests/run-fixture-tests.sh`** (optional) — add an expected-count row for the new fixture for
   suite hygiene. Not required for the gate.

## How to verify before you hand off (run from `dist/`)

```
bash bin/check-pattern-library-json.sh
./bin/check-performance.sh --format json --paths tests/fixtures/ts-type-suppression.ts --no-log \
  | jq '[.findings[]|select(.id=="ts-type-suppression")]'
```

The second command MUST list exactly your bad cases (≥3) and NONE of the good cases. If the good
`@ts-expect-error // reason` line is flagged, tighten `exclude_patterns`. If nothing is flagged, your
pattern probably isn't loading — confirm the file is in top-level `dist/patterns/`, valid JSON, and
`enabled: true`, and that it appears in `PATTERN-LIBRARY.json` after regeneration.

## Hard rules
- **Additive only.** Do not edit `dist/bin/check-performance.sh`, existing pattern JSONs, or anything
  outside the four files above.
- **Do not `git commit`** — the harness commits. Do not push.
- **Stay on `.ts`/`.tsx`.** A pattern that touches `.js` or `.php` behavior is a failed turn.
- Follow `CONTRIBUTING.md` ("Adding a New Pattern" + "Test Fixtures"). Match the BSD/macOS bash-3.2 +
  BSD-grep environment (POSIX character classes like `[[:space:]]`, as the existing patterns use).
- The full `run-fixture-tests.sh` suite is **known 7/10 red** for unrelated pre-existing reasons — do NOT
  try to "fix" it; your gate is the new fixture only.
