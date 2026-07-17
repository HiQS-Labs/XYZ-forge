---
title: "Phase brief: GH-213 case-collision preflight guard (marathon builder input, not a capture doc)"
status: consumed 2026-07-16 (phase built and Approved — see PROJECT/2-WORKING/GH-213-CASE-COLLISION-LANDMINE.md)
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh213 phase of
  PROJECT/2-WORKING/MARATHON-2026-07-16-GH213-209-203/MARATHON.yaml — not itself an active-doc
  capture; the canonical capture doc is GH-213-CASE-COLLISION-LANDMINE.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Phase built and Approved 2026-07-16 (see the canonical capture doc's own Status table). | None — this brief's job (feeding the marathon builder turn) is done. |

## Phase: GH-213 — case-collision preflight guard in find-harness.sh

Full context: [GH-213-CASE-COLLISION-LANDMINE.md](../GH-213-CASE-COLLISION-LANDMINE.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/213

### What to build

Add a new check to `skills/relay-xyz/find-harness.sh`'s `--check` case, alongside its existing
advisory checks (the "ok"/"! " style lines — see the GH-70 concurrency-readiness check right above
where you'll add this one, for the exact style to match).

**Detection:** in the CALLER's own repo (the repo `--check` is actually run from — use
`git rev-parse --show-toplevel`, NOT `$HARNESS`, since a vendored install's harness and the repo
being checked are different directories), scan `git ls-files` for any two tracked paths whose
lowercased forms are identical but whose exact forms differ (a genuine case-collision pair — e.g.
`relay-system/x.md` and `RELAY-SYSTEM/y.md` as two distinct git-tracked paths, not the same path
rendered two ways). Only run this check when the caller's repo has `core.ignorecase=true`
(`git config --get core.ignorecase`) — that's the condition under which the collision is actually
dangerous (a case-sensitive checkout, e.g. Linux CI, can hold both paths safely with no landmine).

**On a detected collision:** print a clear warning naming BOTH colliding paths, explaining that only
one can exist as a real directory on this filesystem and a headless relay turn can misread `git
status` here and revert a legitimate edit (exit 6), and pointing at the remediation: `git mv` one
variant to match the other's casing, commit, re-run `--check`.

**Must NOT change `find-harness.sh`'s exit code.** `--check` is documented as fail-open (always exit
0) — this is a new advisory line, same as the existing checks, never a new blocking condition.

**Portability constraint:** this script is explicitly bash 3.2-safe (see its own header comment: "no
`readlink -f`, no associative arrays") — macOS ships bash 3.2 by default. POSIX `awk`'s `tolower()`
works fine here and is the natural tool for a lowercase-and-detect-duplicates pass over `git ls-files`
output; avoid bash 4+ constructs like `${var,,}` or associative arrays.

### Why this is different from GH-17 (don't touch that fix)

`relay-automation/relay-turn-lib.sh`'s `rtl_in_allow` (GH-17) already makes the allowlist comparison
case-insensitive so a SINGLE logical path rendered differently by `git status` (because the index
tracks it under one casing) still matches an allowlist entry held in another casing. That's a
different, narrower problem than this one — GH-213 is about TWO genuinely distinct tracked paths
colliding at the filesystem level, not one path rendered two ways. Do not modify
`relay-turn-lib.sh` or `test/relay-case-insensitive.sh` for this phase.

### Tests to add (`test/find-harness.sh` — extend the existing file, don't replace it)

The existing file has 3 cases already (GH-70's concurrency-readiness checks) using a lightweight
`ok(){...}` pass/fail helper, no shared `_setup.sh` harness — follow that same style. Add:

1. A fixture repo with `core.ignorecase=true` and two git-INDEX entries that differ only by case.
   Seed this via low-level plumbing (`git hash-object -w`, `git update-index --add --cacheinfo`)
   rather than actually writing two case-variant files to disk — that works regardless of the test
   machine's own filesystem case-sensitivity, and is exactly how a real downstream collision would
   appear in `git ls-files` regardless of what's materialized on disk. Assert `--check` emits the new
   warning naming both paths.
2. An ordinary repo (no such collision) — assert the warning is absent.
3. A repo with the same colliding index entries but `core.ignorecase=false` — assert the warning is
   absent (matches the "only dangerous under ignorecase=true" scoping).
4. All three cases: assert `--check` still exits 0 (fail-open, unchanged contract).

### Acceptance / done means

- `bash test/find-harness.sh` green (existing 3 cases + your new ones).
- Full `validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix).
