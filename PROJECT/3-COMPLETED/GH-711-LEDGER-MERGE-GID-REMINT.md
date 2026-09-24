---
gh_issue: 711
source: https://github.com/HiQS-Labs/XYZ-forge/issues/711
title: "merge-cleanup B1: a gid re-mint on development (from a prior keep-ours landing) makes every older branch's ledger merge a false 'duplicate gh_number' handoff"
status: Complete
created: 2026-09-21
updated: 2026-09-24
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/60 · calc 270"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  merge-cleanup B1's duplicate-gh_number guard fires only when BOTH sides changed something under
  that gh_number, so a gid re-mint on development no longer hands off every older branch.
---

# GH-711 — merge-cleanup B1: a gid re-mint on development (from a prior keep-ours landing) makes every older branch's ledger merge a false 'duplicate gh_number' handoff

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`skills/merge-cleanup/scripts/ledger_merge.py:186-196` `classify()` builds `by_gh` over the union of
both sides and never checks the base; after a keep-ours B1 landing replays development's rows
through the writer (re-minting gids), every branch forked before it sees base = old gid, ours = old
gid (unchanged), theirs = old gid deleted + new gid added — a theirs-only change that the guard
reports as `gh_number N: 2 different rows`. Cost #706 a repair slot on 2026-09-18. No commit
references #711. TestB1Classify/TestPhase5EndToEnd live in `test/gh534_phase_b_tests.py`.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] In `classify()`, before reporting `gh_number N: 2 different rows`, any gid whose row is byte-
      identical to the base on the side that still carries it, while the other side deleted that
      gid, is dropped from consideration — a natural-key duplicate is a conflict only if both
      sides changed something under that gh_number.
- [ ] Regression in `test/gh534_phase_b_tests.py`: base has (gid A, gh 678); ours = base; theirs
      deletes A and adds (gid B, gh 678, same content) plus its own add — classification is
      disjoint, keep theirs, replay ours-only ops. Red control: ours also edits A → still a
      handoff.
- [ ] `skills/merge-cleanup/SKILL.md` describes the narrowed guard where it documents the B1 handoff.
- [ ] `bash validate.sh` exits 0.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "skills/merge-cleanup/scripts/ledger_merge.py",
      "pattern": "k in oc for k in keys"
    },
    {
      "type": "grep_absent",
      "path": "test/gh534_phase_b_tests.py",
      "pattern": "re.mint|remint|unchanged_from_base|byte.identical"
    }
  ],
  "artifacts": [
    "skills/merge-cleanup/scripts/ledger_merge.py",
    "test/gh534_phase_b_tests.py",
    "skills/merge-cleanup/SKILL.md"
  ],
  "remediation": {
    "source": "issue#711",
    "criteria": "Narrow B1's duplicate-gh_number guard to both-sides-changed; pin the re-mint case and its red control"
  },
  "lanes": {
    "agy_safe": [
      "skills/merge-cleanup/scripts/ledger_merge.py",
      "test/gh534_phase_b_tests.py",
      "skills/merge-cleanup/SKILL.md"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
