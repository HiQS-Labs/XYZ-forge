# r1p3 — CLI with JSON output

## Goal

Add `src/cli.js` exposing `run(argv, io)` — a testable command-line entry point
over the existing parse/validate/summarize functions.

## Requirements

1. Signature `run(argv, io)` where `argv` is the argument array (no `node`/script
   prefix) and `io` is `{ stdout, stderr, readFile }`. Injecting `io` is what
   makes this testable — do not read `process.argv` or call `console.log`
   directly inside `run`.
2. Usage: `ledgerkit <file> [--json] [--summary]`.
3. Default (no flags): validate the file and print a human-readable report — one
   line per problem, or `OK: N entries, balanced` when clean.
4. `--summary`: print the `summarize()` table instead, one line per row.
5. `--json`: print a single JSON object to stdout instead of any human text:
   `{ ok, entries, problems, summary }`. `--json` wins over `--summary`.
6. Return an exit code, do not call `process.exit`: `0` clean, `1` validation
   problems, `2` usage error (missing file argument, unknown flag), `3` parse
   error (`E_PARSE` from the parser — report the failing line number on stderr).

## Acceptance

Add `test/cli.test.js` (`node:test`) driving `run()` with a fake `io` that
captures output into strings and serves file contents from memory. Cover each of
the four exit codes and both output modes. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies. No `bin` entry in
package.json — this phase delivers the library-side entry point only.
