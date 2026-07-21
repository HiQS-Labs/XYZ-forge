---
gh_issue: 261
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261
title: "marathon-drive: reconcile the Bash/Python disjoint-failure union (last Phase-1 gate for the XYZ_PYTHON flip)"
status: "captured 2026-07-21 (auto-drafted by /10days) — scope narrowed to the Bash-side remainder"
created: 2026-07-21
updated: 2026-07-21
owner: noel
doc_type: bugfix
complexity: 4
risk: 5
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Re-porting anything on the Python side — utils/py/marathon_drive.py is already at parity
    (112/0 under XYZ_PYTHON=1, landed via GH-255/PR #262) and is explicitly out of scope here.
  - A partial/half fix. The issue's own author reverted an earlier symlink-strip experiment
    specifically because a fix that greens only one of the two interacting factors below would be
    worse than leaving the gap clean — this is safety-critical containment code.
related:
  - "#255 — Python cutover parity ledger (the sibling issue this was split out of; already CLEARED)"
  - "#171 / #172 — vendored-chain resolution exit-6-where-4/0-expected (the two factors this closes)"
goal: >
  test/marathon-drive.sh is green under XYZ_PYTHON=0 (Bash) at the same commit where it's already
  green under XYZ_PYTHON=1 (Python, done). "Fixed" = the vendored .xyz/ + worktree-isolation +
  macOS $TMPDIR scenario's containment path (relay-turn-lib.sh) no longer wrongly exits 6 where the
  turn should exit 4/0, via a consistent physical/logical canonicalization of RTL_ROOT + the relay
  file path AND correct re-anchoring when TICK_REPO_ROOT is inherited pointing at a different repo.
---

# GH-261 — marathon-drive: Bash-side vendored-chain containment fix (last Phase-1 gate)

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-21 by the `/10days` sweep from the issue's own text + its 2026-07-21 status-update comment. Python side of this issue is independently confirmed DONE (PR #262); only the Bash-side remainder is in scope here. Root cause is already fully diagnosed in the issue's own comment (two compounding factors, see below) — this doc's Phase 0 is verifying that diagnosis still holds at current HEAD, not rediscovering it. **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract (this one touches core containment logic — read the diagnosis carefully before firing), then fire as an orchestrator-direct kernel lane, not a delegated worktree lane. |

## Problem
`test/marathon-drive.sh` fails under Bash (`XYZ_PYTHON=0`) with ~8 assertions exiting 6 (containment
violation) where 4 or 0 is expected, in the vendored `.xyz/` + worktree-isolation + macOS `$TMPDIR`
scenario. Per the issue's diagnosis comment, this is two compounding factors in
`relay-automation/relay-turn-lib.sh` (the permanent Bash containment boundary):

1. **Symlink-form strip mismatch.** `RTL_ROOT` resolves to the physical (realpath) form of the
   temp-dir mount, while the relay file / artifact paths are built in the logical (symlinked)
   form of the same path — macOS's symlinked system temp-dir mount is the classic trigger. The
   repo-root-relative strip (`relay-turn-lib.sh:266`, `${a#"$RTL_ROOT"/}`) then leaves the relay
   file absolute, so it fails its own off-lane match and the turn is reverted (exit 6). Neither
   GH-51 (`--target-root`) nor GH-160 (subdir `RTL_ROOT`) covers this no-`--target-root`,
   already-toplevel case. A physical-realpath strip fallback fixes this factor in isolation (a
   standalone repro then exits 4, as expected).
2. **Inherited `TICK_REPO_ROOT`.** With `TICK_REPO_ROOT` inherited pointing away from the consumer
   repo (as `_setup.sh:97` exports it, and the GH-171 subshell doesn't unset it), exit-6 still fires
   *even with* the factor-1 fallback in place: the relay-file allowlist entry still lands absolute
   and unstripped. This is a distinct, unhandled interaction on top of factor 1, not covered by
   fixing factor 1 alone.

A prior fix attempt (symlink-strip only, addressing factor 1 alone) was deliberately reverted by the
operator: it would have greened factor 1's scenario while leaving factor 2 exactly as broken, and
touching this code half-right is worse than leaving it alone given it's the harness's core
containment boundary.

## Fix direction
Consistent physical/logical canonicalization of `RTL_ROOT` and the relay-file path throughout
`relay-turn-lib.sh`'s off-lane matching (not just the one strip site), AND correct re-anchoring of
the containment check when `TICK_REPO_ROOT` is inherited pointing at a different repo than the one
actually being contained. Both factors need to land together — see Non-goals.

## Definition of done
- [ ] `test/marathon-drive.sh` is green under **both** `XYZ_PYTHON=0` and `XYZ_PYTHON=1` at the same commit.
- [ ] Factor 1 (symlink-form strip mismatch) fixed: physical-realpath canonicalization applied consistently, not just at one strip site.
- [ ] Factor 2 (inherited `TICK_REPO_ROOT`) fixed: containment re-anchors correctly regardless of an inherited, wrongly-pointing `TICK_REPO_ROOT`.
- [ ] Regression coverage for both factors together (not just each in isolation) — a standalone fix for factor 1 alone was already shown to leave factor 2 broken.
- [ ] `bash validate.sh` green in both runtime modes, no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "GH-261" }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh", "test/marathon-drive.sh" ],
  "remediation": {
    "source": "issue#261",
    "criteria": "test/marathon-drive.sh is green under both XYZ_PYTHON=0 and XYZ_PYTHON=1 at the same commit. Both compounding factors (symlink-form strip mismatch; inherited TICK_REPO_ROOT re-anchoring) are fixed together, not just one in isolation. bash validate.sh green in both modes."
  },
  "lanes": { "agy_safe": [], "orchestrator_only": [ "relay-automation/relay-turn-lib.sh", "test/marathon-drive.sh" ] }
}
```
