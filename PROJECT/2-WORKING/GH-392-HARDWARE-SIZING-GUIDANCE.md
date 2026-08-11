---
gh_issue: 392
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392
title: "GH-392 — publish hardware sizing guidance (part (a) only; the capability probe is deferred)"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch, wave 2. Acceptance criteria authored onto the issue (it had none) and scoped to part (a). Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 1
risk: 1
effort: 2
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#390 — the runtime counterpart: its layer 4 is a host free-memory floor. This lane is the STATIC sizing guidance; 390 is containment. Neither substitutes for the other."
  - "#382 — the measured crash profile these numbers came from."
non_goals:
  - "Part (b), the capability probe. The issue calls the two parts 'deliberately separable' and this lane takes the seam at that word. No probe, no wave clamp, no refusal, no `xyz doctor`."
  - "Changing any default. Nothing in this lane makes the harness behave differently — it only tells an operator what the harness already does."
  - "Re-measuring. The figures in the issue were taken from a real run (138 samples, 10s sampling, 32 GB M1 Max) and are published as-is, attributed and dated."
goal: >
  XYZ publishes no hardware requirement of any kind. README's Prerequisites table lists Codex CLI,
  agy CLI, Node 18+, git and Python 3.8+ — verified 2026-08-10, four rows, no RAM figure. So a new
  operator on a 16 GB Mac gets no signal before dispatching a 7-lane parallel wave that wants
  7-14 GB. Publish the measured sizing guidance, including the per-lane budgeting rule, so an
  operator can size a run the table does not enumerate.
---

# GH-392 · the harness has no published hardware requirement

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch wave 2. **Acceptance criteria authored onto the issue** — it had none — and deliberately scoped to part (a) only. The issue's own text calls (a) and (b) "deliberately separable", and (a)'s content is described there as "ready to publish as-is". | Preflight, then fire as phase 1 of 2 — first, because its write-set is documentation and cannot affect the phase that follows it. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392

## The defect

`README.md`'s Prerequisites section (`:129`) is a four-row table — Codex CLI, agy CLI, Node 18+ and
git, Python 3.8+ — and **states no hardware requirement at all**. Verified against the tree on
2026-08-10, not assumed.

That would be a minor omission if the harness's memory cost were uniform. It is not:

| Path | Shape | Measured |
|---|---|---|
| A — serial marathon | serial by construction (GH-241): one builder + one gate | **~2.2 GB steady**, peak 2.26 GB across 138 samples |
| B — `/10days` Step 7 | one agent per lane per wave | **7-14 GB** for a real 7-lane first wave, uncapped |

**The headline measurement is good news and is easy to misreport:** XYZ itself is not
memory-hungry. A fully active serial marathon occupies ~7% of a 32 GB machine and does not move. All
of the risk is in *how many lanes run at once*, and nothing bounds that by hardware.

**The specific misreading this lane exists to prevent:** `/10days` says `kernel ≤ 1 per wave`, which
looks like a bound. It is a **coordination/zone cap, not a memory cap** — enforced independently of
write-set collision (`utils/marathon-plan-zones.default.json`, `maxPerWave`), so it constrains which
lanes may share a wave and never how much memory they use. A reader who takes it as a memory guard
concludes a 7-lane wave is already governed.

**And the opposite overstatement must be avoided too.** Saying the harness has no memory protection
would be false: the GH-390 gate guard enforces an RSS cap on a gate and kills it — observed live on
2026-08-10 (`gate exit 0 after 752s — peak group RSS 1042MB … caps: RSS 8192MB`). What does not exist
is *host-aware wave sizing*. Per-gate containment and host sizing are different things, and the
guidance has to say which one is missing.

## Acceptance

*Copied verbatim from [issue #392](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392) (`## Acceptance`), fetched 2026-08-10 after the revision below. Deviations, if any, are recorded in the same block.*

*Revised 2026-08-10 after an adversarial codex + agy consult on the first draft. The changes are
recorded under "Draft defects found by review" below.*

**Scope: part (a) — documentation — ONLY.** Part (b), the capability probe, is explicitly deferred
and is not satisfied, partially satisfied, or prototyped by this work. The issue itself calls the two
"deliberately separable"; this block splits them at that seam. **The diff is documentation only** —
no probe, no clamp, no refusal, no new flag, no behavioural change. A code change made "to support
the prose" is out of scope by definition.

- [ ] README's Prerequisites section states a hardware requirement where it states none today (verified 2026-08-10: four rows, no RAM figure), naming a **recommended minimum** and the workload that minimum covers. A bare "recommended: 16 GB" with no stated mode, agent mix, or host reserve does not satisfy this.
- [ ] The two execution paths are **defined by command**, not referred to by name. "Path A" and "Path B" are the issue's vocabulary and appear nowhere in the README today, so the text must say which invocation each is — the serial `marathon.sh --plan` route versus the `/10days` per-lane parallel dispatch — before using any shorthand for them.
- [ ] The published table covers 16 / 24 / 32 / 64 GB and, for each, says which execution path is supported — not merely "more is better". 16 GB must be stated as the serial path only.
- [ ] The per-lane budgeting rule is published alongside the table, not just the minimum: a serial marathon holds ~2.2 GB steady, and a concurrent lane costs ~1.5–2 GB **plus the target repo's own test suite, which is unbounded and must be named as the term the operator has to supply**. An operator must be able to size a wave width the table does not enumerate, and must be told which part of the arithmetic the harness cannot know.
- [ ] The figures carry their measurement provenance, not just a date: host spec, sample count and interval, the agent mix that was running, and whether the number is steady-state or peak. The issue records these (32 GB M1 Max, 138 samples at 10s, builder + agy reviewer + three pytest gates, 2.19 GB avg / 2.26 GB peak). A number a later reader cannot re-measure cannot be retired either.
- [ ] The text states that `kernel ≤ 1 per wave` is a **coordination/zone cap, not a memory cap**. It is enforced independently of write-set collision (`utils/marathon-plan-zones.default.json`, `maxPerWave`), so describing it purely as a write-conflict rule is imprecise in the direction that matters: it constrains which lanes may share a wave, never how much memory they use.
- [ ] The documentation does not claim the harness sizes, clamps, or refuses a wave by host memory — it does none of those. It must **also not imply that no memory protection exists at all**: the GH-390 gate guard enforces an RSS cap on a gate and kills it, observed live. The honest statement is that per-gate resource containment exists and host-aware wave sizing does not.
- [ ] "Supported" is defined where it is first used — whether it means "will run to completion", "will run without swapping", or "is recommended" — so a reader on a 16 GB host can determine from the published text alone whether a 7-lane parallel wave is supported, and a builder cannot satisfy the criterion by declaring everything unsupported.

### Draft defects found by review

Recorded because the first draft would have been graded against them:

1. **"Path A" was used as if defined.** It is the issue's vocabulary and appears nowhere in the
   README, making the criterion neither reviewable nor safely implementable. Now criterion 2.
2. **Criterion 7 would have licensed a false statement.** "No clamp, no refusal" is true of
   host-aware wave sizing but reads as "no memory protection exists", and the GH-390 gate guard
   demonstrably kills an over-budget gate on an RSS cap. Corrected rather than softened.
3. **"Write-conflict rule" was imprecise** — the zone cap applies even without an exact path
   collision, so the sharper term is a coordination/zone cap.
4. **"Supported" and the measurement provenance were both underspecified**, each satisfiable by an
   opaque sentence.

## Litmus tests

- **A docs lane cannot be gated by its own test**, so the reviewer *is* the gate here. That is the
  known weakness of this lane shape and it is why criteria 5, 6 and 7 are phrased as things a
  reviewer can check by reading, not as things the author asserts.
- **A green suite proves nothing about this lane** — `validate.sh` does not read README prose. The
  gate protects against collateral damage, not against a bad table.
- **If the numbers cannot be attributed to a specific run, criterion 4 fails**, and re-measuring is
  out of scope. Publish what the issue measured, attributed, or stop and say so.

## Reversibility & blast radius

**Minimal, and lower than any other Nightwatch lane.** Documentation only. Nothing a running
marathon executes reads `README.md`, so this phase cannot affect the phase that follows it — which
is why it is ordered first. Fully revertible by reverting one commit.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "README.md", "pattern": "per concurrent lane" }
  ],
  "artifacts":     ["README.md"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #392", "criteria": "publish the measured hardware sizing guidance in README Prerequisites, part (a) only — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes": { "agy_safe": ["README.md"], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` reports the fix as still
required while the marker string the fix introduces is missing from `README.md`. Once the per-lane
budgeting rule is published, the probe stops reporting and the lane is no longer fireable — which is
the intended behaviour, not a defect.

## Provenance

Filed from the measured crash profile behind #382 and the two host crashes analysed in #390.
Promoted to `2-WORKING` 2026-08-10 as part of Nightwatch wave 2
([MARATHON-2026-08-10-NIGHTWATCH-WAVE-2](MARATHON-2026-08-10-NIGHTWATCH-WAVE-2/MARATHON.yaml)),
scoped to part (a) only. Wave 1 (GH-358 Phase 1) shipped in PR #489.
