---
title: "--target-root BUILD turns silently lose the relay Log — GH-245's guard only covers --review-once"
status: "Active (2-WORKING) — promoted 2026-07-27 by the /10days sweep. Buggy conjunct re-verified live at relay-automation/relay-drive.sh:273. Preflight contract below is LIVE."
created: 2026-07-27
updated: 2026-07-27
owner: unassigned
gh_issue: 289
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/289
doc_type: bugfix
complexity: 3
risk: 4
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Redesigning --target-root itself, or changing where relay threads live by default.
  - Changing the --artifact-file read-only seed contract (it is read-only by design; this
    doc only records that it cannot substitute for a writable relay file on a build turn).
related:
  - relay-automation/relay-drive.sh (the GH-245 guard)
  - relay-automation/relay-turn-lib.sh (ALLOW_PATHS / relay-Log round-trip)
goal: >
  A --target-root BUILD turn either reports its findings into the relay Log like any other
  turn, or refuses fast at startup the way a --review-once turn already does — never
  completes at full cost and silently discards the Log.
---

# GH-289 — `--target-root` build turns silently lose the relay Log

## Status
| What was just completed | What's next |
|---|---|
| Selected by the 2026-07-27 `/10days` sweep as one of the 3 critical bugs. The defect was **re-verified in live source**, not taken from the issue text: `relay-automation/relay-drive.sh:273` still reads `if ((REVIEW_ONCE)) && [[ -n "${TARGET_ROOT:-}" ]]`, so the GH-245 fast-refusal never fires for a build turn. | Fire the contract below. Minimal fix is dropping the `((REVIEW_ONCE))` conjunct so the guard covers build turns too; the issue also documents two deeper directions (seed the relay file writable and copy back, or resolve the relay file into the target root). Pick one and cover it with a regression test. |

## Symptom

A relay driven with `--target-root` in **build** shape (not `--review-once`) runs the full turn,
costs a full model turn, and then discards the relay Log. The run surfaces as `no-progress` or
`cap-or-close-mismatch` — i.e. it reads as a *model* failure, when it is a harness
misconfiguration. Codex, the safer builder, takes the blame; agy silently bypasses the guard
instead of tripping it.

## Mechanism

GH-245 added a fast-refusal for exactly this failure — the turn's isolation worktree is based on
the TARGET repo, so a relay file resolving outside that root physically cannot be appended to. But
the guard is gated on `REVIEW_ONCE`:

```bash
if ((REVIEW_ONCE)) && [[ -n "${TARGET_ROOT:-}" ]]; then    # relay-drive.sh:273
```

A build turn takes the same worktree shape and hits the same unwritable-path condition, but never
reaches the refusal. `--artifact-file` cannot substitute: it seeds **read-only**, so a build turn
still has no writable path for its findings.

## Impact

Per the issue, there is currently **no working configuration** for the ordinary cross-repo shape
"harness in repo A, code in repo B, Codex as builder." That blocks any cross-repo marathon lane
that wants Codex as the builder. Cost and trust burn on every occurrence; nothing is corrupted.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_present", "path": "relay-automation/relay-drive.sh", "pattern": "\\(\\(REVIEW_ONCE\\)\\) && \\[\\[ -n \"\\$\\{TARGET_ROOT:-\\}\" \\]\\]" },
    { "type": "path_absent", "path": "test/gh289-target-root-build-turn.sh" }
  ],
  "artifacts":   [
    "relay-automation/relay-drive.sh",
    "relay-automation/relay-turn-lib.sh",
    "test/gh289-target-root-build-turn.sh",
    "validate.sh"
  ],
  "artifacts_new": [ "test/gh289-target-root-build-turn.sh" ],
  "remediation": {
    "source":   "issue#289",
    "criteria": "A --target-root BUILD turn no longer completes-then-discards its relay Log: it either writes the Log successfully, or refuses fast at startup with the same clear diagnostic the --review-once path already emits. The GH-245 guard's existing --review-once behavior is unchanged. A new regression test drives the build-turn shape (not just --review-once) and asserts the outcome is never a silent full-cost discard. The new test is REGISTERED in validate.sh's TESTS array (validate.sh does not glob test/)."
  },
  "lanes":       {
    "agy_safe":          [ "test/gh289-target-root-build-turn.sh" ],
    "orchestrator_only": [ "bin/", ".tick/" ]
  }
}
```

> **Probe polarity note.** This fix *removes* the buggy conjunct, so the probe is `grep_present`:
> preflight reports `landed` once that pattern no longer matches. (`grep_absent` is for fixes that
> *add* a marker.) Verified against `utils/swarm-preflight.sh:261-267`, not assumed.

## Phase 1 — Fix the guard and prove it

### Checklist

- [ ] Reproduce the build-turn discard before changing anything
- [ ] Choose the fix direction (minimal: drop the `((REVIEW_ONCE))` conjunct)
- [ ] Land the regression test FIRST and observe it fail
- [ ] Apply the fix; test passes
- [ ] Register the new test in `validate.sh`'s `TESTS` array

### QA checklist — Phase 1

- [ ] The `--review-once` guard's existing behavior is byte-for-byte unchanged
- [ ] The regression test drives the BUILD shape, not `--review-once`
- [ ] The failure mode is no longer misattributable to the model (diagnostic names the harness cause)
- [ ] `bash validate.sh` green with the new test registered
