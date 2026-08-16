# Lane brief — GH-207: make marathon retry/resume tolerate pre-existing lane state

Execution surface of record: `PROJECT/1-INBOX/GH-207-MARATHON-RETRY-RESUME-BRITTLE.md`
(issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/207)

## Task

Three brittleness modes, all from the harness assuming a lane starts from empty state:

1. **Namespace lane state by marathon.** `marathon-drive.sh` keys `.tick/attempts/<lane>` (see
   `_lane_key`, line ~77) and the committed `phases/<id>/RELAY.md` render by the bare plan-local
   lane id in a shared per-repo namespace, so `p1` from one marathon inherits another marathon's
   attempt history and renders. Introduce a `MARATHON_LANE_NS` key —
   `<marathon-name>--<lane-id>` — passed from `marathon.sh` (plan `name:`), used for both the
   attempt file and the phase-render path. Bare-id behavior stays as fallback when no plan name is
   supplied (direct marathon-drive.sh invocation).
2. **Idempotent re-render.** A retry whose re-rendered `phases/<id>/RELAY.md` is byte-identical to
   what is already committed must skip the commit and continue, not HALT on `nothing to commit`.
3. **Already-satisfied lane path.** When the lane's artifact already exists and the pre-advance
   gate passes, a no-diff builder turn routes to the reviewer instead of `no-progress` escalation;
   on reviewer approval mark the lane satisfied (`lane_already_satisfied`) and advance the
   `depends_on` chain. Green gate AND reviewer approval are both required — this path must not
   mask a genuinely stalled lane.
4. **(Minor)** Suppress `dependency.drift` events for 0-line diffs on harness-owned files observed
   in driven worktrees.

## Definition of done

- `test/marathon-drive.sh`: two plans sharing a lane id do not share attempt state; identical
  re-render does not HALT; a pre-built gate-green lane reaches satisfied and unblocks its
  dependent; a stalled lane (red gate) still escalates.
- `bash validate.sh` green.
