---
gh_issue: 314
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314
title: "A pre-existing phases//relay-system/ ignore rule HALTs a marathon mid-chain, and the transcript path was outside the preflight"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 1
risk: 2
effort: 1
ratings_provisional: true
goal: >
  Close the third of the three write-set paths a marathon commits, so a target that gitignores
  the transcript root is refused before any paid turn instead of after two.
---

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-14** on `fix/critical-2026-08-14`. `preflight_write_set_trackable` now receives the transcript path alongside `RELAY.md` and `ESCALATION.md`. `test/gh314-transcript-writeset.sh` is **5/0** and registered; control observed and recorded. | Operator review. **The `xyz-vendor.sh` half is deliberately NOT built** — see the deviations below. |

## Why

GH-514 built `preflight_write_set_trackable` and **cites #314 in its own source comment**, which
reads as if it closed it. It did not. The preflight received two of the three paths a run commits.
`save_transcript()` performs a third `git add -- <transcript>` with `check=True` under the
transcript root (`relay-system/` by default), and that path was never passed in.

The transcript is the **latest** of the three, so its omission is the most expensive: the builder
and reviewer turns are already spent by the time it runs. #314's second reporter found exactly
this — un-ignore one path, burn a full phase, crash on the next, roughly 1.5h per landmine,
discovered serially, in a repo (`aegis-sleuth-slack-bot`) that had deliberately chosen not to track
harness output.

## Key concepts

- The transcript root is resolved the same way `save_transcript()` resolves it — sourcing
  `relay-turn-lib.sh` and calling `rtl_transcript_root` — rather than assuming the literal
  `relay-system/`, because a vendored or relocated install can move it and a hardcoded guess would
  check a path the run never writes.
- **Fail-open on resolution failure**, matching `preflight_write_set_trackable`'s existing
  docstring contract: this guard exists to stop a known halt and must not invent a new way for a
  healthy run to fail.

## Acceptance

Authored by this lane — the tracking issue has no `## Acceptance` section. Derived from the issue
body and the operator preference recorded on the ROADMAP entry ("fail fast in preflight naming all
three paths, wired into `--dry-run` too — explicitly **not** `git add -f`, which would publish
silently").

1. All three committed paths — `RELAY.md`, `ESCALATION.md`, and the transcript — are checked before
   dispatch. **[met]**
2. A target that gitignores only the transcript root is refused without spending a builder turn.
   **[met — dispatch count 0, was 2]**
3. The refusal names the offending path. **[met]**
4. A healthy target is not refused. **[met — control case 2]**
5. The fix does **not** use `git add -f`, which would publish output a repo deliberately withheld.
   **[met — no `-f` added]**

## Acceptance — deviations from the issue

- [dropped] The `xyz-vendor.sh ensure_gitignore` half (un-ignoring `phases/`/`relay-system/` at
  vendor time) — reason: the operator preference recorded on the ROADMAP is fail-fast in preflight
  rather than mutating a consuming repo's `.gitignore`, and the issue itself notes that a repo
  which deliberately withholds harness output has **no supported configuration** — that is a
  product decision, not a bug to patch here. Also related to #440, whose `ensure_gitignore` change
  landed separately.
- [dropped] Wiring into `--dry-run` — reason: not verified in this lane; the preflight runs on the
  live path only. Left explicitly open rather than claimed.

## The control, and what it falsified

Recorded at `test/baselines/GH-314-negative-control.md`. The suite's first draft assumed the
pre-fix tree dies in an unhandled `CalledProcessError`, mirroring GH-514. **It does not** — pre-fix
it still refuses cleanly, still names `relay-system`, and emits no traceback (exit 4 vs 2). The
only assertion that changes is the dispatch count: **2 paid builder turns before the refusal**.
So the cost is the proof and the traceback assertion is a guard.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "rtl_transcript_root" }
  ],
  "artifacts":   [ "utils/py/marathon_drive.py", "test/", "validate.sh" ],
  "remediation": { "source": "issue#314", "criteria": "Check the transcript path in the pre-dispatch write-set preflight so an ignored relay-system/ costs no paid turns" },
  "lanes":       { "agy_safe": [ "test/" ], "orchestrator_only": [ "utils/py/marathon_drive.py", "validate.sh" ] }
}
```

Contract auto-drafted by the 2026-08-14 fix-now pass — artifacts/lanes not yet operator-verified.
