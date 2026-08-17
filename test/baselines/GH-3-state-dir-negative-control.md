# GH-3 / GH-430 state-dir durability negative control — `test/gh430-state-dir-tracked-default.sh`

Recorded 2026-08-16. Per the standing rule: a check never observed failing is not evidence.

## What had to be falsifiable

GH-3's defect: `improve-loop.sh --state-dir` defaulting to `${TMPDIR:-/tmp}` means a run's only
audit trail (`provenance.jsonl`) evaporates on the next tmp purge. The fix (landed as GH-430,
predating this Ballast lane) roots the default inside the repo instead
(`relay-automation/improve-loop.sh:75`: `STATE_DIR="${STATE_DIR:-$HERE/state/improve-loop.$$}"`).

## Controls (revert-and-replay)

Mutation performed in a disposable scratch clone (`~/xyz-disposable/gh3-negcontrol`, never `/tmp`,
never the primary clone): `relay-automation/improve-loop.sh:75` reverted to the pre-GH-430 shape
(`STATE_DIR="${STATE_DIR:-${TMPDIR:-/tmp}/improve-loop.$$}"`).

## PRE-FIX (mutated) — the control is OBSERVED failing

```
== test: gh430-state-dir-tracked-default ==
  PASS: run without --state-dir completed (exit 0)
  PASS: captured the default STATE_DIR from the run log (/var/folders/.../T//improve-loop.80878)
  FAIL: default STATE_DIR is NOT inside the repo: /var/folders/.../T//improve-loop.80878
  FAIL: default STATE_DIR is still under a tmp root: /var/folders/.../T//improve-loop.80878
  PASS: default STATE_DIR path is NOT gitignored -> tracked-eligible: /var/folders/.../T//improve-loop.80878
  PASS: provenance.jsonl exists and is non-empty at the default path
  PASS: run with explicit --state-dir completed (exit 0)
  PASS: explicit --state-dir still wins over the default
  gh430-state-dir-tracked-default: 6 pass, 2 fail
```

The two FAIL assertions are the point: they pin exactly GH-3's defect (default lands outside the
repo, under a tmp root that macOS purges within ~3 days). A stray `git check-ignore` invocation
against a path outside the repo also emits a harmless `fatal:` line to stderr in this mutated
state — not a test failure, just `git`'s own diagnostic for an out-of-repo path.

## POST-FIX (current main) — same file, same assertions, green

```
== test: gh430-state-dir-tracked-default ==
  PASS: run without --state-dir completed (exit 0)
  PASS: captured the default STATE_DIR from the run log (relay-automation/state/improve-loop.79479)
  PASS: default STATE_DIR resolves inside this repo
  PASS: default STATE_DIR is not under /tmp or $TMPDIR
  PASS: default STATE_DIR path is NOT gitignored -> tracked-eligible: relay-automation/state/improve-loop.79479
  PASS: provenance.jsonl exists and is non-empty at the default path
  PASS: run with explicit --state-dir completed (exit 0)
  PASS: explicit --state-dir still wins over the default
  gh430-state-dir-tracked-default: 8 pass, 0 fail
```

## Acceptance disposition

All 3 of GH-3's acceptance criteria are now satisfied: (1) durable repo-adjacent default — landed
pre-Ballast as GH-430, (2) claim-citability — `improve-loop.sh:162` prints
`provenance: $STATE_DIR/provenance.jsonl` and the default path is git-tracked-eligible (confirmed
above), (3) this negative control. Closing #3 as landed rather than re-scoping or swapping: the
remaining gap at freeze time was solely this recorded control, not unmet functionality.
