---
title: agy consult lane hangs on expired auth — fast pre-flight probe
status: Complete (3-COMPLETED)
created: 2026-06-28
updated: 2026-06-29
closed: 2026-06-29
owner: noelsaw1
branch: main
gh_issue: 37
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37
doc_type: project
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Make the agy (Antigravity) lane fail FAST when its session auth has expired, instead of opening an
  interactive browser prompt and hanging to the 300s cap — so a cross-model consult degrades to
  Codex-only in seconds with the real cause, not after a 5-minute silent stall.
---

## Status

| What was just completed | What's next |
|---|---|
| **✅ SHIPPED + CLOSED 2026-06-29 via marathon dogfood** (Codex builder + agy reviewer → **Approved**, `validate.sh` **60/60**). Codex added a fast `agy whoami` auth pre-flight to both `agy-turn.sh` and `consult.sh`: on failure the lane exits in seconds (shim exit 5; consult degrades) naming the `agy login` remedy, instead of the 300s interactive-prompt hang. New `agy-turn` test (auth-fail → exit 5, no commit) added; all existing exit-6 containment assertions preserved (personally verified). | **Done.** Marathon landed after surfacing 5 harness defects (see GH-37 dogfood findings, filed separately) — the build itself was correct on the first turn; the blockers were swarm-preflight/marathon harness gaps (timeout sizing, artifact-set scope, leaked-token reuse, self-verify-trips-containment, and the `--target-root .` relay-file off-lane false-positive). |

## Asks (acceptance criteria) — ✅ all delivered (verified 2026-06-29)
- [x] Fast pre-flight auth probe (`agy whoami`) in the agy shim + `consult.sh`; on failure **skip the agy lane within seconds** naming the remedy (`agy login`), not a 300s hang.
- [x] Forces non-interactive failure: expired token / `whoami` non-zero → shim exits 5 immediately, no turn.
- [x] Documents the `agy login` re-auth step in both shim headers.
- [x] Re-verified by the marathon gate: valid auth → agy lane answered (agy reviewed + Approved); auth-fail path covered by a new `agy-turn.sh` test (exit 5, no commit).
- [x] `bash validate.sh` green (**60/60**); Codex lane behavior unchanged.

## Lane note
**Builder = Codex** (deliberate): GH-37 is the agy-auth failure itself, so an agy builder lane would hit
the very hang it is meant to fix. agy may serve as reviewer **only if** its auth is valid that session;
otherwise Codex self-review or a Claude inline review. The fix is shim-scoped — the containment kernel
(`relay-turn-lib.sh`, `bin/`, `.tick/`) is off-lane.

## Swarm Preflight Contract
```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/consult.sh", "pattern": "GH-37" } ],
  "artifacts":   [ "relay-automation/consult.sh", "relay-automation/agy-turn.sh" ],
  "remediation": { "source": "self#asks", "criteria": "Fast agy auth pre-flight: expired auth skips the lane in seconds with the agy login remedy; no 300s hang." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ "bin/", ".tick/", "relay-automation/relay-turn-lib.sh" ] }
}
```

## Related
- #20 (agy first-class footing, closed), #22 (agy worktree data loss, closed).
- `PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md`, `PROJECT/1-INBOX/agy-1.0.10-hang-bug-report.md`.
- Promoted from the 1-INBOX intake (2026-06-28) on adding the preflight contract.
