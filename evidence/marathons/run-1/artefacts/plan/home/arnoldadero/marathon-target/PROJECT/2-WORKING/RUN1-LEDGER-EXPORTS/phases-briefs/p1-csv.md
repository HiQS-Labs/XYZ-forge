# r1p1 — CSV export

## Goal

Add `src/export-csv.js` exporting `toCSV(entries, options)`, which renders parsed
ledger entries (the shape `src/parse.js` produces) as RFC 4180 CSV.

## Requirements

1. Header row, exactly: `date,account,amount,currency,memo`.
2. One row per entry, in the order given.
3. Amounts render with exactly two decimal places (`-125.4` becomes `-125.40`).
4. RFC 4180 quoting, and this is the part that matters: a field containing a
   comma, a double quote, CR or LF must be wrapped in double quotes, and any
   embedded double quote must be doubled (`"` becomes `""`). Memos are free text
   and will contain all of these.
5. Line terminator is CRLF (`\r\n`), per RFC 4180. Do not emit a trailing CRLF
   after the final row.
6. `options.header === false` suppresses the header row. Default is to emit it.

## Acceptance

Add `test/export-csv.test.js` using `node:test` + `node:assert`, covering at
minimum: the plain case, a memo containing a comma, a memo containing a double
quote, a memo containing a newline, two-decimal formatting of an integer amount,
and `header: false`. `npm test` must be green.

## Out of scope

Do not modify `src/parse.js`, `src/validate.js`, or `src/index.js`. Do not add
dependencies — this repo has none and must keep none.
