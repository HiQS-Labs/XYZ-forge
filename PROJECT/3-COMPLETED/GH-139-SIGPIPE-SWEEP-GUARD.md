---
gh_issue: 139
source: https://github.com/HiQS-Suite/XYZ-forge/issues/139
title: "test: GH-460's SIGPIPE shape is still open across the suite — sweep + ratchet guard"
status: Active (2-WORKING — built 2026-08-22)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: bugfix
effort: 3
complexity: 3
risk: 4
goal: >
  Convert the convertible mass of pipe-into-grep -q assertions to the capture-then-match form
  (grep -q PAT <<<"$(producer)") so no reader can vanish under a writer, and land a ratchet
  guard that fails on any NEW occurrence while the residual baseline may only shrink.
---

# GH-139: the SIGPIPE sweep and guard

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on `fix/gh135-140-followups-2026-08-22`** — **369 of 482** pipe-into-`grep -q` sites converted across 91 suites to `grep -q PAT <<<"$(producer)"` (command substitution completes before grep starts; here-strings are fed from a file — SIGPIPE impossible). **113 residual** sites are inventoried in `test/baselines/GH-139-pipe-grep-baseline.txt`: function bodies, grouped/multi-pipe conditions, and text that only LOOKS like the shape (quoted assertion prose, embedded python). New `test/gh139-pipe-grep-guard.sh` (registered in TESTS) fails when any file's count grows past baseline or a new file carries the shape, reports shrinks as INFO. Mutation-tested: appending one new occurrence turns it red. | The residual 113 ratchet down by hand-conversion (function-def and single-line `{ …; }` groups are the easy next tranche). Two live flakes already confirmed this class during the Wave-1 and this wave's own gating (gh131 first-line match; gh322 on a pristine clone). |

## The transform and its honesty

`cmd | grep -q PAT ctx` → `grep -q PAT <<<"$(cmd)" ctx` — truthiness-equivalent except the
vanishing case where a producer FAILS while emitting matching stdout (under pipefail the old
form failed; the new form passes). No suite in this corpus depends on that case; GH-460's own
fix blessed the file-based form. Skipped shapes were skipped for stated reasons (quote parity,
continuation fragments, `{ } ;` producers, multiple pipes) rather than best-effort rewriting:
a wrong conversion is worse than a baselined one.

## Verification

`bash -n` clean on all 91 changed suites; the five most-swept suites re-run green individually
(marathon-drive, gh385, gh544, consult, gh528 — the last after repairing nine continuation-pair
artifacts the mechanical pass got wrong, each caught by suite run, none by bash -n); full gate
green. Converter kept out of the tree — the diff itself is the reviewable record; the guard is
the durable artifact.
