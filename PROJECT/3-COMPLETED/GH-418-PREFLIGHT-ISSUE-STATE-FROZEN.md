---
gh_issue: 418
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418
title: "GH-418 — swarm-preflight can pass a lane whose issue is closed and whose artifacts are frozen"
status: "Shipped 2026-08-08 in release 0.2.0 Litmus wave 1 — built, agy-approved, full gate green (704s); issue #418 CLOSED after per-criterion verification. Designated first child of #419. Grew a third phase mid-run from its own review: agy found a pre-existing uncaught UnicodeDecodeError that crashed swarm-preflight outright on any binary file under test/, in code it had not been asked to review."
created: 2026-08-05
updated: 2026-08-05
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#419 — the parent policy. This lane is its designated first child: the proof the trustworthy-gate contract works on a real gate before anything is asked of the rest of the tree."
  - "#400 — supplies the degradation posture reused verbatim here: undeterminable reports `unknown` loudly and never blocks. Also added the `gh issue view` call this lane extends by one field."
  - "#368 — COLLIDES BY DESIGN. Its recommended fix edits `utils/marathon-plan.sh`, which carries the GH-308 FROZEN banner, so the check this lane builds would refuse that lane. See Sequencing."
  - "#308 — the FROZEN banner this lane learns to read. Python is authoritative; `utils/swarm-preflight.sh` is frozen and out of scope."
non_goals:
  - "Blocking when the issue state cannot be determined. Reuse #400's posture exactly — an unreachable network is not evidence of staleness."
  - "Any change to `utils/swarm-preflight.sh`. Frozen by GH-308; behavior changes go in `utils/py/swarm_preflight.py`."
  - "Blocking on a closed issue outright in every case. Some lanes legitimately follow up on a closed issue. The requirement is that the operator is told, not that the run is forbidden."
  - "Auto-retiring stale plan docs. Reporting is in scope; filesystem mutation is not."
  - "Hardcoding a list of frozen files. The banner is read from disk so a newly frozen twin is covered without editing preflight."
goal: >
  Preflight decides whether a lane is fireable and never asks the two questions that determine
  whether the work should run at all: is the issue still open, and are the target files writable by
  policy. A lane can read READY, emit a packet, and send a builder to edit a frozen Bash twin to
  close an issue that shipped two weeks ago. Every gate reports green — the #419 class, in the gate
  that decides what fires.
---

# GH-418 · preflight never asks whether the work should run

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-05 as a lane of release 0.2.0 Litmus. Preflight contract authored and verified READY via `--dry-run`; acceptance reads `match — 6/6 criteria copied verbatim from issue #418`. The #368 collision was identified and recorded in both docs. | Operator go, **after #368 fires**. Then Phase 1 (issue state on the existing `gh` call) and Phase 2 (the FROZEN-banner check plus the regression suite). |

Captured 2026-08-05 as a lane of release **0.2.0 Litmus**. Not fired. #419's capture doc names this
issue as its designated first child, and this doc does not change that ordering — it records the
contract so the lane can be preflighted.

**One collision is known and deliberate.** See [Sequencing](#sequencing-and-the-368-collision).

## The problem

`swarm-preflight` validates a contract's *internal consistency* — artifacts exist, probes still
detect the bug, the base is fresh. It performs **no issue-state check at all**, and has **no
knowledge of the GH-308 FROZEN banner**.

The measured evidence is the 2026-08-03 read-only triage that retired four marathon plans:

| Plan | Lanes | Live state |
|---|---|---|
| J (2026-07-18) | #238, #239 | **both CLOSED** — shipped via PR #243 the following day |
| K (2026-07-19) | 17 lanes | **16 CLOSED**, only #191 open (self-described deferred backlog) |
| 2026-07-23 | #279, #280 | **#279 CLOSED**, #294 CLOSED, #280 open as bookkeeping only |
| M (2026-07-20) | #226 | #226 **CLOSED**; plan targets `relay-automation/consult.sh`, which is **FROZEN** |

None of that is discoverable from preflight. It was re-derived by hand, twice, weeks apart.

Plan M is the sharpest case: its Lane C gates on *"any stamp string added to `consult.sh` must appear
in `consult.py` and vice-versa"* — following that plan's own gate would violate GH-308.

## Why the plumbing makes this cheap

#400 added an issue-body fetch to `utils/py/swarm_preflight.py`. Adding `state` to that same
`--json` list is **one field on a call that already happens** — no new network path and no new
offline contract, since #400's degradation rules already cover the unreachable case. The frozen
check is a local read of artifacts the contract already enumerates.

## Acceptance

*Copied verbatim from [issue #418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418)
(`## Acceptance`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

- [ ] Preflight fetches the source issue's `state` on the call that already fetches its body, and records it in `run-candidate.json` on every run, including when it cannot be determined.
- [ ] A lane whose source issue is CLOSED does not silently read READY: preflight reports it prominently, and the emitted packet states the issue was closed and when, so the builder's own context window carries the fact.
- [ ] An artifact path in the contract that carries the GH-308 `FROZEN` banner sets NOT-READY with no packet written, naming the file and pointing at its authoritative twin.
- [ ] The frozen check reads the banner from the file on disk rather than a hardcoded list, so a newly frozen twin is covered without editing preflight.
- [ ] Undeterminable issue state (no `gh`, unauthenticated, offline) reports `unknown` and does **not** block, matching #400's degradation contract.
- [ ] A regression test pins the measured cases: a contract naming `relay-automation/consult.sh` as a write target fails, and a lane whose issue is closed does not emit a packet that reads as fully green.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

## Sequencing and the #368 collision

**This lane's frozen-artifact check would refuse lane #368**, and that is not hypothetical:

- `utils/marathon-plan.sh` carries the GH-308 FROZEN banner (verified 2026-08-05).
- #368's recommended fix (its Option B) is to delete a misleading comment at `:67` — the only place
  the false claim exists; `utils/py/marathon_plan.py` does not carry it.
- Criterion 3 says an artifact carrying the banner **sets NOT-READY with no packet written**. A
  comment-only correction is not a behavior change, but the criterion as written does not
  distinguish the two.

Three ways out, and the lane must pick one rather than discover it at fire time:

1. **Fire #368 before this lane lands.** Cheapest, and #368 is a one-line change.
2. **Let the frozen check distinguish a comment-only diff from a behavior change.** More correct,
   materially more work, and it needs its own negative control — a check that decides "this diff is
   only comments" is itself a decision gate under #419.
3. **Accept the refusal and route #368 through the deviations mechanism.** Honest, but it makes the
   frozen check a thing lanes routinely work around, which is how a gate becomes a suggestion.

**Recommendation: (1).** It costs nothing and leaves the check strict.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Issue state. Add `state` to the existing `gh issue view --json` call, record it in `run-candidate.json` on every run including `unknown`, and surface a CLOSED issue prominently in both the preflight output and the emitted packet. Non-blocking by design. | `utils/py/swarm_preflight.py` | 2/1/2 |
| 2 | Frozen artifacts. Read the GH-308 banner from each contract artifact on disk — never a hardcoded list — and set NOT-READY with no packet when one is a declared write target, naming the file and its authoritative twin. Plus the regression suite pinning both measured cases. | `utils/py/swarm_preflight.py`, `test/gh418-issue-state-frozen.sh`, `validate.sh` | 2/2/2 |

## Litmus tests

- **The negative control is mandatory here, not optional.** This lane is #419's proof of concept; a
  suite that only shows the new checks passing would be the ninth instance, added by the issue that
  exists to prevent it. Pre-fix replay is available and cheap — both checks are net-new behavior on
  an existing code path, so the old code can run the new suite.
- **The closed-issue case must not block.** A test asserting NOT-READY on a closed issue would
  contradict criterion 2 and the issue's own non-goals. The assertion is that the fact is *reported*
  and reaches the packet — not that the run is forbidden.
- **The frozen check must be observed refusing a real file.** `relay-automation/consult.sh` is the
  measured case from Plan M and is the fixture; a synthetic file with a hand-written banner would
  not prove the banner is read from disk.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh418-issue-state-frozen.sh" },
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "issue_state" },
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "FROZEN" }
  ],
  "artifacts":     [ "utils/py/swarm_preflight.py", "test/gh418-issue-state-frozen.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh418-issue-state-frozen.sh" ],
  "remediation":   { "source": "issue#418", "criteria": "issue-state + FROZEN-banner checks in preflight — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*, and `grep_absent` reports `landed` when the pattern *is found*. All three assert the
pre-fix state — verified 2026-08-05: `issue_state` and `FROZEN` each occur **0 times** in
`utils/py/swarm_preflight.py`, so neither probe can read `landed` before the work ships.

## Method note

The four-plan triage table is carried from the issue, which recorded it from live `gh` state on
2026-08-03. The FROZEN banner on `utils/marathon-plan.sh` and the two zero-occurrence probe markers
were re-verified on 2026-08-05 against `development` @ `2c95a56`.
