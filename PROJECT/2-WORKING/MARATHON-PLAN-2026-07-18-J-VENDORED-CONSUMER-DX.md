---
title: Marathon Plan J (2026-07-18) — vendored-consumer DX gaps (GH-238, GH-239)
status: Triaged, not yet fired — capture docs + preflight contracts still owed
created: 2026-07-18
updated: 2026-07-18
owner: noel
branch: development
doc_type: project
source: external field reports filed from a vendored `.xyz/` consumer (Hypercart-Dev-Tools/rebalance-OS)
generated_by: hand-authored (two small, related issues, same theme, disjoint write-sets)
lanes: [238, 239]
execution: parallel (2 lanes, disjoint write-sets) — codex/agy relay per lane
roadmap_exempt: true
goal: >
  Close the two DX gaps that make the harness behave worse in a vendored `.xyz/` install than in
  its home repo: a pre-advance gate that defaults to a file consumers don't have (and fails only
  AFTER a paid build+review cycle), and a preflight-contract gate that ships no example to copy.
  Both are cheap, both are onboarding-surface, and both are currently being routed around rather
  than fixed.
---

# Marathon Plan J — 2026-07-18 · vendored-consumer DX

> Two field reports from the same consuming repo on the same day. Neither is a logic defect; both
> are defaults/onboarding assuming the consumer looks like this repo. Grouped because they share a
> root cause and a reviewer can hold both in one head.

## Status

| What was just completed | What's next |
|---|---|
| **Triaged 2026-07-18.** Both field reports from the vendored `.xyz/` consumer verified against source and captured as GH-238 (pre-advance gate defaults to a `validate.sh` consumers lack, failing only after a paid build+review cycle) and GH-239 (swarm-preflight ships no contract example, so the gate gets routed around). Capture docs + this plan promoted to `2-WORKING`; disjoint write-sets confirmed for two parallel lanes. | Fire the two lanes (codex/agy relay per lane): GH-238 fail-fast at plan load + document the gate in `MARATHON.example.yaml`; GH-239 ship `relay-automation/CONTRACT.example.md` + print the skeleton on exit 3. Then move this plan to `3-COMPLETED`. |

## Triage

### GH-238 — pre-advance gate defaults to `bash validate.sh`, halts *after* approval

**Verdict: confirmed, as reported.** Verified in source:

| Claim | Evidence | Holds? |
|---|---|---|
| Default is `bash <ROOT>/validate.sh` | [marathon-drive.sh:376](relay-automation/marathon-drive.sh#L376) — `PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"` | ✅ |
| Resolved late, never existence-checked | Line 334 sets it empty (`# resolved to default after ROOT is set`); 376 fills it; nothing probes the path before the first builder turn | ✅ |
| Gate runs after relay approval | [marathon-drive.sh:751](relay-automation/marathon-drive.sh#L751) — `log "relay approved — running pre-advance gate"` | ✅ |
| `MARATHON.example.yaml` doesn't mention the gate | Read in full — 46 lines, documents per-phase fields only; zero mention of `--pre-advance-cmd`, `validate.sh`, or gating | ✅ |

Cost shape is the real finding: a consumer without `validate.sh` pays a **full builder turn plus a
full reviewer turn** before learning the run can't advance. Exit 5 after the money is spent.

Note also lines 662 and 779 — the gate is *also* probed on relay timeout (exit 7) and stall
(exit 3) as a rescue path. A missing gate file degrades those recovery paths too, not just the
happy path. The reporter didn't catch this; it widens the fix slightly.

- **Severity:** medium. Not data-losing, but wastes a paid cycle per rediscovery, per repo.
- **Distinct from** #170 / #232 (those are `validate.sh`'s *own tests* failing inside this repo).
- **Recommended fix:** the reporter's option 1 — **fail fast at plan load**. Resolve and probe the
  gate command before the first builder turn; refuse to start with an actionable message. Cheap,
  turns a 2-turn-late failure into an immediate one, and preserves the gate's intent (option 2,
  "skip with a warning", silently weakens a safety gate — reject it). Fold in option 4 (document
  the default in `MARATHON.example.yaml`) as part of the same change, not a separate lane.
- **On option 3** (mode-dependent default via the `.xyz` basename check at line ~52): plausible but
  it makes the default *invisible and context-dependent*, which is the exact failure class being
  fixed. Prefer one default plus a loud early failure.

### GH-239 — no preflight-contract example ships

**Verdict: confirmed, and slightly worse than reported.** Verified:

| Claim | Evidence | Holds? |
|---|---|---|
| Schema lives only in the script header | [utils/swarm-preflight.sh:24-36](utils/swarm-preflight.sh#L24-L36) — a comment block, sole source | ✅ |
| Exit 3 on missing/invalid contract | Header line 44 + `emit "CONTRACT ERROR ($doc): see message above."` around line 527 | ✅ |
| No consumer-facing example ships | Only `relay-automation/MARATHON.example.yaml` exists as a shipped example; there is no contract equivalent | ✅ |

Worse than reported: real filled-in contracts *do* exist in this repo — a dozen-plus
`PROJECT/**/GH-*.md` capture docs carry them — but `PROJECT/**` is **not** part of a vendored
`.xyz/` install. So the working examples are exactly the ones a consumer can never see. The
knowledge exists and is structurally non-shippable under the current vendor boundary.

- **Severity:** medium-high on consequence, low on effort. The observed behaviour is that
  consumers skip `swarm-preflight.sh` entirely and hand-author `MARATHON.yaml` — which means the
  freshness / fix-still-required / lane-collision gates are being routinely bypassed. A safety gate
  that is cheaper to route around than to satisfy is not a working gate.
- **Recommended fix:** the reporter's option 1 (**ship `relay-automation/CONTRACT.example.md`**,
  annotated per field, mirroring how `MARATHON.example.yaml` earns its keep) plus option 2
  (**exit-3 message prints the minimal valid skeleton and the target file**). Both are additive and
  low-risk. Do them in one lane.
- **Skip option 3** (`--emit-contract-skeleton`) for v0 — new CLI surface for a problem two docs
  solve. Revisit only if the example alone doesn't move consumer behaviour.
- **`fix_probes` needs the most annotation.** The reporter is right that authoring them blind is the
  hard part, and that guessing wrong yields a STALE (exit 4) verdict reading as "already done" —
  a *false* completion signal, the worst kind. Probe polarity is the trap: probes detect the
  **bug**, not the fix (`grep_present` = bug evidence, `grep_absent` = fix landed). The example must state this
  explicitly and inline; it's the single most-mistaken field.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint.**

## Collision map

| Zone | Lane | Write-set | Parallel-safe? |
|---|---|---|---|
| kernel (driver) | J1 / #238 | `relay-automation/marathon-drive.sh`, `relay-automation/MARATHON.example.yaml` | ✅ vs J2 |
| independent | J2 / #239 | `relay-automation/CONTRACT.example.md` (new), `utils/swarm-preflight.sh` | ✅ vs J1 |

Disjoint — no shared file. Kernel cap is ≤1/wave and J1 is the only kernel lane, so the pair
satisfies the cap. **Both may run in one wave.**

Caveat: both lanes edit harness files that `validate.sh` and `test/*.sh` cover, so the gate run at
the end of each lane exercises shared test files. Sequence the *gates*, not the builds, if the
suite proves flaky under concurrency.

## Waves

**Wave 1:** #238 ‖ #239

## Per-lane scoring

| Lane | cx | risk | eff | zone | deps | notes |
|---|---|---|---|---|---|---|
| #238 | 2 | 2 | 2 | kernel | — | touches the driver's startup path; needs a regression test that a missing gate file fails *before* turn 1 |
| #239 | 1 | 1 | 2 | independent | — | additive doc + one error-message change; lowest-risk work in the queue |

## Blocking prerequisite (do this before firing)

Neither issue has an in-repo `GH-*` capture doc, and `swarm-preflight.sh --gh-issue` requires one
**with a preflight contract** in `PROJECT/2-WORKING/`. So:

1. Write `PROJECT/1-INBOX/GH-238-*.md` and `GH-239-*.md` captures (via `/idea` or `/triage`).
2. Add a preflight contract to each; promote both to `PROJECT/2-WORKING/`.
3. `utils/swarm-preflight.sh --gh-issue 238 --gh-issue 239 --dry-run` to confirm READY.
4. Park both in `ROADMAP.md` so the generated marathon plan picks them up.
5. Fire each lane, scoped by `ALLOW_PATHS` per the collision map — and **pass an explicit
   `--pre-advance-cmd`**, which is the very bug #238 describes.

Step 2 is itself a live demonstration of GH-239: authoring those two contracts by hand, from the
script header, is exactly the onboarding cost the issue is about. Worth noting what it actually
takes — that's the strongest evidence for the fix.

## Non-goals

- Not fixing `validate.sh`'s own failing tests (#170 / #232) — different problem, different lane.
- Not changing the vendor boundary so `PROJECT/**` ships. Larger call; the shipped-example fix
  makes it unnecessary for now.
- Not adding new CLI surface to `swarm-preflight.sh` (deferred `--emit-contract-skeleton`).
