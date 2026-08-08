---
title: "Phase brief: GH-289 gh289-target-root-build-turn (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-27
updated: 2026-07-27
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh289-target-root-build-turn phase of
  MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY — not itself an active-doc capture; the canonical
  capture doc is GH-289-TARGET-ROOT-BUILD-TURN-LOG-LOSS.md one level up.
roadmap_exempt: true
---

# Brief — GH-289: `--target-root` BUILD turns must not silently discard the relay Log

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and preflighted by the 2026-07-27 /10days sweep — `swarm-preflight --gh-issue` exit 0 (READY). Not yet fired. | Fire as marathon phase 2 of 4, after gh311 repairs the gate. |

**Parent doc:** `PROJECT/2-WORKING/GH-289-TARGET-ROOT-BUILD-TURN-LOG-LOSS.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/289
**Runs SECOND — must land before gh308 stamps a FROZEN banner on `relay-drive.sh`.**

## The defect (re-verified live at HEAD)

`relay-automation/relay-drive.sh:273`:

```bash
if ((REVIEW_ONCE)) && [[ -n "${TARGET_ROOT:-}" ]]; then
```

GH-245 added this fast-refusal for a real failure: the turn's isolation worktree is based on the
TARGET repo, so a relay file resolving outside that root physically cannot be appended to — the
turn completes at full cost and is discarded. But the guard is gated on `REVIEW_ONCE`, so a
**build** turn takes the same shape, hits the same unwritable condition, and never reaches the
refusal.

`--artifact-file` cannot substitute: it seeds **read-only**, so a build turn still has no writable
path for its findings.

## Why it matters more than it reads

- The run surfaces as `no-progress` / `cap-or-close-mismatch` — it reads as a **model** failure
  when it is a harness misconfiguration. Codex takes the blame; agy silently bypasses the guard.
- Per the issue there is currently **no working configuration** for the ordinary cross-repo shape
  "harness in repo A, code in repo B, Codex as builder." That blocks cross-repo marathon lanes.

## What to build

Minimal fix: drop the `((REVIEW_ONCE))` conjunct so the guard covers build turns too.

The issue documents two deeper directions if the minimal fix proves insufficient — seed the relay
file writable and copy it back, or resolve the relay file into the target root. Pick one
deliberately and say why in the relay Log.

## Acceptance criteria

- A `--target-root` BUILD turn either writes its Log successfully, or refuses fast at startup with
  the same clear diagnostic the `--review-once` path already emits. It never completes-then-discards.
- **Land `test/gh289-target-root-build-turn.sh` FIRST and observe it FAIL** against current code,
  then fix. A regression test that passes before the fix proves nothing.
- The test drives the BUILD shape, not `--review-once`.
- The existing `--review-once` guard behavior is byte-for-byte unchanged.
- The diagnostic makes the harness cause unmistakable, so the failure can't be misattributed to the model.
- Register the new test in `validate.sh`'s `TESTS` array (`validate.sh` does not glob `test/`).

## Do not

- Redesign `--target-root`, or change where relay threads live by default.
- Change the `--artifact-file` read-only seed contract.

## Gate

`bash validate.sh`
