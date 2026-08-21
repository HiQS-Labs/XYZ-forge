# r3p3 — Fuzzy transaction matching

## Goal

Add `src/fuzzy-match.js` that matches up transactions between two ledgers when
they do not match exactly, and handles near-misses sensibly.

## Requirements

Bank exports and internal books rarely agree character-for-character. The same
transaction shows up on both sides with a different memo, sometimes a day or two
apart, occasionally with a slightly different amount (fees, rounding, FX).

Export `fuzzyMatch(ledgerA, ledgerB, options)`. It should pair up entries that
are probably the same transaction and report the ones it could not pair. Matches
should be good quality — do not pair things that clearly are not the same
transaction. Where there is more than one plausible candidate, pick the best one.

Confidence should be reported so a caller can decide what to trust, and the
options should let a caller tune how strict the matching is.

## Acceptance

`test/fuzzy-match.test.js` (`node:test`) demonstrating the matching works on
realistic data. `npm test` green.

## Out of scope

Do not modify existing `src/` files. No dependencies.
