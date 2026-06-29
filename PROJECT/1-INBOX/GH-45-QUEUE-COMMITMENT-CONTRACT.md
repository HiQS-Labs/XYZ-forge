---
gh_issue: 45
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/45
title: QUEUE 'must-complete' commitment contract + anti-rabbit-hole / WIP-discipline safeguard
status: Proposed (1-INBOX — not yet active)
created: 2026-06-28
doc_type: feedback
complexity: medium
risk: medium
effort: medium
ratings_provisional: true
related:
  - PROJECT/2-WORKING/QUEUE-PLANNER.md
  - PROJECT/2-WORKING/GH-39-SWARM-PREFLIGHT-GAPS.md
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-drive.sh
  - utils/queue-plan.sh
goal: >
  Turn the QUEUE/wave from a suggestion into a bounded commitment contract so a session cannot
  silently abandon the parallel wave to deep-dive one item. The harness must enforce a per-lane
  attempt cap (refuse-to-re-fire + surface findings) and flag off-wave drift, so straying requires
  an explicit operator override rather than a quiet slide.
---

> **Inbox capture + remediation plan.** Per PDDA, a `1-INBOX/GH-*.md` doc carries no `## Status`
> table while it sits here; it is the capture, not the active-work doc. Promote to `2-WORKING/`
> (keeping the `GH-45` prefix and adding the exact status table) when execution starts.

## Problem (observed 2026-06-28)

A session quietly abandoned the QUEUE's parallel wave to deep-dive one item. **GH-39 swallowed a
whole session** (4 marathon attempts + salvage + offshoots) while the actual Wave-1 lanes (GH-37
ready-but-never-fired, Part B chaos, GH-24) sat untouched — and the QUEUE doc went stale. The work
was not worthless (it surfaced #42/#43), but it was **off-plan and unsurfaced**: nothing flagged
"you're 4 attempts deep on a non-wave item; the wave is stalled."

The failure has two halves and the fix must hit both:

1. **No attempt ceiling.** Re-firing a failed lane is free and silent. There is no counter and no
   refusal — the operator (or an over-eager session) can re-fire forever.
2. **No drift signal.** Nothing compares "what the session is doing" against "what the wave
   committed to," so off-wave effort accrues invisibly until a human notices.

## Goal

Make the QUEUE/wave a **commitment contract**, not a suggestion — drift bounded, visible, and
requiring explicit human override, not a silent slide. Concretely: a lane declares `max_attempts`,
`out_of_scope`, and `on_failure`; the harness **enforces the attempt cap** (refuse-to-re-fire +
surface findings); a session that strays off the committed wave is **flagged, not silent**.

## Where this plugs into the existing architecture (grounding)

- A **lane** = a queue-plan "ready item," keyed by its `PROJECT/**` doc (`--project-doc`). A
  **fire** = one `marathon-drive`/`relay-drive` run, keyed by `RELAY_TASK` (`MARATHON-<PHASE_ID>-TURN`).
- `utils/queue-plan.sh` already (a) reads `ROADMAP.md` + project docs, (b) emits machine-readable
  drift findings (`already-landed`, `not-ready`, `blocked`, coverage gaps), and (c) **generates the
  QUEUE doc**. It is the natural home for the contract fields and the drift signal — no new daemon.
- There is **no per-lane attempt counter today**; re-fires are unbounded and untracked. This is the
  single missing enforcement primitive, and the highest-leverage thing to build.
- `tick`/`.tick/` already holds coordination state, so a small JSON counter file there is the
  cheapest place to record attempts (no new store, no schema migration).

## Remediation plan (phased; QA gate after each phase)

Phases are ordered by leverage. **Phase 1 + Phase 2 are the core**; 3 is mostly free fallout; 4 is
explicitly nice-to-have and gated on the core proving out (see the diminishing-returns rule this
issue itself is about). The `/ponytail` review section below recommends what to actually build first.

### Phase 1 — Declarative lane contract in the QUEUE doc (idea 1 + idea 3)

Make the commitment **data**, not prose, so both humans and the harness read the same source.

- Extend `utils/queue-plan.sh`'s QUEUE-doc renderer so each emitted lane carries a fenced,
  machine-readable block:
  - `definition_of_done` — the acceptance bar (reuse the preflight contract's `gate` when present).
  - `out_of_scope` — what this lane must NOT touch (reinforces the GH-39 scope-lock).
  - `max_attempts` — integer, default **2**.
  - `on_failure` — `park` (default): capture findings as issues, stop; never silently re-chase.
  - `slice_tier` per acceptance item — `core` | `nice-to-have` (feeds Phase 4).
- Add an `active_commitment` header to the QUEUE doc: the explicit list of lanes this wave owns.
- Document the **re-anchor rule** in `AGENTS.md`: after each lane attempt, re-read `active_commitment`
  before continuing; opening work *outside* it requires an explicit "replan" note in the QUEUE doc.

**QA gate / acceptance:**
- A generated QUEUE doc shows, per lane, `definition_of_done` / `out_of_scope` / `max_attempts` /
  `on_failure`, plus a top-level `active_commitment`. `queue-plan --check` still passes (no drift
  regression). `AGENTS.md` states the re-anchor + park rule. One unit test asserts the renderer emits
  the contract block with defaults.

### Phase 2 — Attempt-cap enforcement (idea 2 — THE anti-rabbit-hole)

The one mechanism that would have stopped the GH-39 spiral at attempt 2.

- Record fires per lane in `.tick/lane-attempts.json` (`{ "<lane-key>": { attempts, last_task, last_outcome } }`).
  Lane-key = the project-doc path (stable across re-fires); marathon/relay increment on start.
- `marathon-drive.sh` / `relay-drive.sh` **refuse to start** a lane already at `max_attempts`,
  exiting non-zero with: `lane <X> parked after <N> attempts — findings: <…>; override with --force.`
- `--force` (explicit operator override) bypasses the cap for that one fire and logs the override.
- On a parked lane, emit the park summary (last outcome + any spawned sub-issues) so findings are
  surfaced, not buried.

**QA gate / acceptance:**
- Re-firing a lane already at `max_attempts` exits non-zero with the park message and writes no relay
  token. `--force` overrides and is logged. A regression test (`test/lane-attempt-cap.sh`) drives a
  lane to the cap, asserts refusal, then asserts `--force` proceeds. `validate.sh` stays green.

### Phase 3 — Drift signal in queue-plan (idea 4)

Mostly falls out of Phase 2's counter + queue-plan's existing drift machinery.

- `queue-plan` (and/or `--check`) flags **DRIFT** when: (a) a lane's `attempts` ≥ `max_attempts`
  (parked but un-reconciled), or (b) a lane has spawned > K sub-issues in the session (default K=2),
  or (c) effort/attempts on a **non-`active_commitment`** item exceed a threshold → emit
  `DRIFT: off-wave deep-dive in progress` as a `warn` finding (consistent with existing severity).

**QA gate / acceptance:**
- With a seeded `.tick/lane-attempts.json` at the cap, `queue-plan --check` emits a `DRIFT` finding
  and the documented non-zero/`warn` per the existing exit-code contract. Covered by a queue-plan test.

### Phase 4 — Diminishing-returns / "stop polishing" gate (idea 5) — NICE-TO-HAVE, gated

Only build if Phases 1–3 prove insufficient in practice.

- Once a lane's `core` slices pass, the lane is **done by default**; `nice-to-have` slices need an
  explicit re-commitment line in the QUEUE doc to be fired. Prevents the GH-39 "keep adding A4/A5/B7"
  tail. A Stop-hook re-anchor reminder is the optional belt-and-suspenders form of Phase 1's doc rule.

**QA gate / acceptance:**
- A lane with all `core` slices checked is reported `done (core)` by queue-plan and is not re-emitted
  as ready without an explicit re-commitment marker. (Defer the Stop-hook unless the doc rule visibly
  fails.)

## Non-goals

- No new long-running daemon, watcher, or scheduler — enforcement rides existing scripts
  (`queue-plan`, `marathon-drive`, `relay-drive`) and existing state (`.tick/`).
- No change to the relay containment kernel or `tick` claim semantics (out of scope; see #42/#43).
- Not a replacement for human judgment — the cap *surfaces and pauses*, the operator decides
  (`--force`); it never silently kills work.
- No retroactive enforcement on in-flight lanes; applies to waves generated after this lands.

## Provenance

Filed from the GH-39 session retrospective (the operator caught the drift). Relates to
[GH-39](../2-WORKING/GH-39-SWARM-PREFLIGHT-GAPS.md) (scope-lock brief / B6), #42 (concurrency),
#43 (build robustness). The `/ponytail` cost review below was run before promotion to scope the
leanest viable build.
