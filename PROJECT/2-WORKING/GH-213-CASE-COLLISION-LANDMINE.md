---
gh_issue: 213
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/213
title: "committed case-variant relay-system/ path is a latent exit-6 landmine on macOS"
status: built 2026-07-16 (codex + agy, 4 turns, Approved) — verified independently after a pre-advance gate false-negative, see Status
created: 2026-07-16
updated: 2026-07-16
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not touching rtl_in_allow's existing GH-17 case-insensitive comparison (that already handles a
    single logical path rendered differently by git status — this is about two genuinely DISTINCT
    tracked paths colliding, a different failure mode).
  - Not auto-fixing a detected collision (e.g. auto git mv) — detect and warn only; the remediation
    is a manual, deliberate git mv the operator runs.
  - Not reproducible from this repo's own history (verified: no uppercase RELAY-SYSTEM path was ever
    committed here) — reported from a downstream vendored install. The fix is a general-purpose
    detector, not a fix for a specific instance in this repo.
related:
  - skills/relay-xyz/find-harness.sh
  - test/find-harness.sh
  - relay-automation/relay-turn-lib.sh (GH-17 precedent, not touched by this fix)
goal: >
  Detect, before a headless relay/marathon turn runs, when a repo has two git-tracked paths that
  differ only in case (a landmine on any case-insensitive/preserving filesystem, e.g. macOS default),
  and warn loudly with a git mv remediation — via find-harness.sh --check, which already reports
  harness/readiness state before a relay is driven.
---

## Status

| What was just completed | What's next |
|---|---|
| Built via the marathon (phase `gh213`, codex builder + agy reviewer, 4 turns, relay `STATUS: Approved`, tick token `done`). All 20 `test/find-harness.sh` cases pass including the 5 new case-collision assertions. **The marathon's own pre-advance gate false-negatived on an unrelated, pre-existing test in the SAME shared gate command (`test/marathon.sh`'s GH-205 resume sub-case) — not a defect in this phase's code.** Root cause: the shared `--pre-advance-cmd` nested `bash test/marathon.sh` (which itself invokes the real `marathon.sh`/`marathon-drive.sh`, acquiring the same `.git/relay-driver.lock` and touching the same `.tick/` state) INSIDE the already-running outer `marathon-drive.sh` process — confirmed by re-running `bash test/marathon.sh` standalone immediately after (33/33 green, including the exact sub-case that "failed" nested). This is itself a live, concrete instance of the class of bug GH-209 is about (env/lock-state bleeding between a live marathon process and a nested invocation of the same scripts) — noted back into GH-209's own capture doc. Recovery: verified independently rather than re-running the (already-good) build; the two remaining phases continue via `MARATHON-REMAINING.yaml` with a gate that doesn't nest `test/marathon.sh`. | Continue with `gh209`/`gh203` via `MARATHON-REMAINING.yaml`. |

## Problem

Both `RELAY-SYSTEM/` and `relay-system/` were observed to exist in a downstream vendored install's
tree — i.e. git's index holds two genuinely DISTINCT tracked paths differing only by case. On a
case-insensitive-but-case-preserving filesystem (macOS default, `core.ignorecase=true`), the checkout
can only materialize ONE physical directory for both, so `git status`/containment logic downstream
can misread what's actually on disk. A headless relay turn built on top of this can misinterpret the
mismatch as an off-lane edit and revert a legitimate change (exit 6).

This is NOT the same bug GH-17 already fixed: GH-17's `rtl_in_allow` (relay-turn-lib.sh) made the
allowlist comparison case-insensitive so a SINGLE logical path rendered in a different case by `git
status` (e.g. because the index tracks it as `RELAY-SYSTEM/x.md`) still matches an allowlist entry
held as `relay-system/x.md`. GH-213 is structural: TWO tracked paths, not one path rendered two ways.

Not reproducible from this repo's own git history (no uppercase `RELAY-SYSTEM/*` path was ever
committed here — verified via `git log --all --diff-filter=A --name-only -- "RELAY-SYSTEM/*"`), so
this is scoped as a general-purpose defensive detector rather than a fix targeting a specific
instance in this repo.

## Acceptance criteria

- [x] `skills/relay-xyz/find-harness.sh --check` detects, in the CALLER's own repo (where `--check`
      is run from, not necessarily `$HARNESS`), any two git-tracked paths whose lowercased forms are
      identical but whose exact forms differ.
- [x] The check only fires when the caller's repo has `core.ignorecase=true` (the condition under
      which the collision is actually dangerous — a case-sensitive checkout, e.g. Linux CI, can hold
      both paths safely).
- [x] On a detected collision, `--check` prints a clear warning naming BOTH colliding paths and a
      `git mv` remediation, in the same "`!` "-prefixed advisory style as the file's other checks
      (e.g. the GH-70 concurrency warning already there).
- [x] `--check` stays fail-open: the new check never changes `find-harness.sh`'s exit code (always 0
      on `--check`, per its existing documented contract).
- [x] `test/find-harness.sh` gains regression cases: (a) a fixture repo with `core.ignorecase=true`
      and two case-colliding tracked paths (seed via `git update-index --add --cacheinfo` — this
      works regardless of the test machine's own filesystem case-sensitivity, no real collision on
      disk needed) triggers the warning; (b) an ordinary repo with no such collision does NOT
      trigger it; (c) a repo with `core.ignorecase=false` and the same colliding paths does NOT
      trigger it (matches point 2 above).
- [x] `bash test/find-harness.sh` and full `validate.sh` green.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/find-harness.sh",
  "fix_probes": [ { "type": "grep_absent", "path": "skills/relay-xyz/find-harness.sh", "pattern": "CASE-COLLISION LANDMINE" } ],
  "artifacts": [ "skills/relay-xyz/find-harness.sh", "test/find-harness.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Acceptance criteria checklist in this doc" },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```

## Scope lock
Edit only: `skills/relay-xyz/find-harness.sh`, `test/find-harness.sh`.
