---
gh_issue: 381
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/381
title: "GH-381 — release-horizon planning: a --horizon batch mode on /release-plan, an Iterations band, and the admission rule that keeps RELEASES.md from becoming a pre-CHANGELOG"
status: "Proposed (1-INBOX — not yet active). Local half SHIPPED: RELEASES.md now states it is optional and carries the admission rule + band convention; 0.1.0 has a band; pdda.sh verified green with the new field. Upstream half is a handoff to Hypercart-Dev-Tools/pdda."
created: 2026-07-30
updated: 2026-07-30
owner: noel
doc_type: plan
related: GH-284, GH-334, GH-336
effort: 4
complexity: 3
risk: 3
phases: 3
supersedes: "#389 — filed in a parallel session ~25 min after this one, covering the contract layer; closed as duplicate and folded in here. Its capture doc was removed so this is the single canonical doc."
non_goals:
  - "A new /Releases skill. Operator chose a --horizon batch mode on /release-plan so everything writing RELEASES.md has exactly ONE enforcement point for the admission rule."
  - "Persisted `Iteration 1:`..`Iteration 5:` labels. Operator chose a reserved, un-enumerated band — see the adjudication below."
  - "A blocking pdda.sh check. Warn at most; same reasoning as GH-347's install-path convention."
  - Backfilling shipped patch releases into RELEASES.md. That is the thing being prevented.
  - Changing what CHANGELOG.md records. It stays the sole history of what shipped.
  - "Making RELEASES.md mandatory, or prompting anyone to fill it in. It is optional by design."
goal: >
  Give RELEASES.md an admission rule that can be pointed at when declining an entry, a reserved
  iteration band so patch releases have somewhere to NOT be, and a --horizon mode that proposes a
  4–5 release arc from the survivor set /10days already computes and discards — while making the
  file's optionality explicit enough that assistants stop offering to fill it.
---

# GH-381 · release-horizon planning, and an admission rule

## Status
| What was just completed | What's next |
|---|---|
| **Local half shipped.** `RELEASES.md` now opens by stating it is optional and must not be topped up, then states the admission rule and band convention; `0.1.0` carries `Iterations: 0.1.0-0.1.4`. Verified `pdda.sh releases` → **rc=0, 0 errors, 0 warns** with the new field before relying on it. | **Upstream half** — the `PROJECT/PDDA.md` contract and `/release-plan --horizon`, both in `Hypercart-Dev-Tools/pdda`. Prompt ready at [PDDA-MAINTAINER-PROMPT.md](../4-MISC/PDDA-MAINTAINER-PROMPT.md). |

## Adjudication — two proposals merged into one

This doc is the merge of **#381** (this issue: the planner skill, filed first and more complete on
command surface, tests, and reversibility) and **#389** (a parallel session: the admission rule, the
band, and the upstream/sync analysis). #389 is closed and its doc removed; this is the single
canonical doc, with one ROADMAP pointer.

Two conflicts existed. The operator resolved both, and in each case the losing option was the one
that quietly grows the file:

**1 · `--horizon` on `/release-plan`, not a new `/Releases` skill.**
Everything that writes `RELEASES.md` then has exactly **one** enforcement point for the admission
rule. `/release-plan` already does interview → propose canonical version → preview → append; horizon
planning is the same act at a different granularity. A third sibling beside `/release-plan` and
`/release` gives one rule two enforcement points, which is how it ends up applied on one path and
not the other. Everything in #381's proposed behavior survives — it just lands as a mode.

**2 · A reserved band, not five persisted `Iteration N:` labels.**
This answers the "Open decision" the original doc left open, and it is the more consequential call.

```text
Release: 0.2.0
Iterations: 0.2.0-0.2.4
```

Five persisted slots per release is **20–25 named rows across a 5-release horizon, each an
invitation to fill in what shipped** — the pre-CHANGELOG drift arriving as *structure* rather than
as appended blocks. A band says "0.2.1–0.2.4 exist, ship freely, CHANGELOG.md records them," and
leaves nothing to fill in.

It also makes the rule **mechanically checkable**, which is the only kind `--horizon` can enforce:
*a version inside an existing band is already accounted for, so a block for it is by definition a
duplicate.* That is a test. "Is this release meaningful?" is not.

The original doc's own instinct — *"the smallest one-source-of-truth representation"* — points the
same way: one optional field beats five required ones.

## The problem being solved

`RELEASES.md` is documented as a ledger *"for major releases"*, and that adjective in one passing
clause of `PROJECT/PDDA.md` is the entire rule. Nothing elaborates or enforces it.

The failure mode is worth stating precisely, because it is **not** "someone adds a wrong entry":

> The file stays **correct at every individual step** while becoming the wrong thing.

Add `0.2.1` because it genuinely shipped. Add `0.2.2` for symmetry. Each edit is defensible alone,
and within a quarter the file is a **de-facto pre-CHANGELOG**: a second hand-maintained history,
guaranteed to disagree with `CHANGELOG.md` the first time someone updates one and not the other.
**Two sources of truth for the same fact is the defect**; the row count is only the symptom, which
is why "keep it short" is not a fix and an admission rule is.

## The optionality problem, which is the same problem upstream

There is a second pressure, and it is the one an LLM maintainer applies: a sparse planning file
*looks* incomplete, so a helpful assistant offers to populate it. Repeat that across sessions and
the drift above happens without anyone deciding to cause it — **one helpful suggestion at a time.**

The tooling is already correct here and needs no change: `pdda.sh releases` is warn-only, never
blocks, and skips entirely when the file is absent (*"RELEASES.md not found — nothing to check"*).
**The problem is purely the prose.** `PROJECT/PDDA.md` describes the format and the fields at length
and never says the file is optional, so a reader infers it is expected.

Fixed locally by making the first section of `RELEASES.md` an explicit instruction not to top it up.
The upstream fix is the same in the contract.

## Where each half lives — and why that split is mandatory

| Change | File | Sync-managed? | Fixed by |
|---|---|---|---|
| Optionality + admission rule + `Iterations:` in the contract | `PROJECT/PDDA.md` | **YES** — `file PROJECT/PDDA.md` in `pdda-sync-manifest.conf` | upstream |
| `--horizon` mode | `pdda/SKILLS/RELEASE-PLAN/` | lives upstream | upstream |
| Optionality + rule at the point of use | `RELEASES.md` | **no** — not in the manifest | **here — done** |
| `/10days` handoff of its survivor set | `skills/10days/SKILL.md` | no | here |

**Editing `PROJECT/PDDA.md` in this repo would be silently reverted by the next `pdda-sync.sh` run.**
Verified by reading the manifest, not assumed. `RELEASES.md` is absent from it, which is what made
the local half safe to ship immediately.

## The `/10days` link

`/10days` already scans an issue window, verifies each issue is still valid and not already fixed,
and ranks the survivors — then **discards that set** once its marathon file is built. It is exactly
the raw material for a release arc, already computed and already verified. `--horizon` should accept
that ranked list rather than re-deriving it, and the original issue's milestone-derived hand-off
(resolve `Milestone:` → filter to the selected iteration → let `/10days` gate it) is the right shape
for the return trip.

## Acceptance criteria

- [x] `RELEASES.md` states it is **optional** and must not be proactively filled — done here.
- [x] `RELEASES.md` states the admission rule and the band convention — done here.
- [x] `Iterations:` verified additive: `pdda.sh releases` rc=0 / 0 warns, `pdda.sh run` green.
- [ ] `PROJECT/PDDA.md` (upstream) says the file is optional, states the admission rule as a rule
      rather than an adjective, and defines `Iterations:`.
- [ ] All vendored `PROJECT/PDDA.md` copies updated — 10 on disk; see the drift note below.
- [ ] `/release-plan --horizon` proposes 4–5 blocks in one preview and **refuses a version inside an
      existing band**.
- [ ] `/10days` documents handing its ranked survivor set to `--horizon`.
- [ ] Preview-and-confirm before any GitHub write (milestones, issue assignment); never publish or
      set `Status: Shipped` automatically. *(carried from the original #381)*
- [ ] Tests cover 4 vs 5 release horizons, band exhaustion, milestone absence/ambiguity, and that
      `/10days` receives only the selected candidate set. *(carried from the original #381)*
- [ ] A written answer for band exhaustion — widen, or promote. Undecided is how bands rot.

## Drift found while scoping this

Of **10 live `PROJECT/PDDA.md` copies** on disk, 8 are byte-identical to upstream at 1015 lines.
Two are not:

| Repo | Lines | Differing lines |
|---|---|---|
| `xyz-3-agents-swarm` (this repo) | **839** | 394 |
| `fast-key-replacement-macos` | **464** | 711 |

This repo is one of only two out-of-sync copies, and the divergence is substantive: upstream defines
`Front-door reviewed:` / `Shakedown reviewed:` / `License file:` while ours defines **`Milestone:`**,
which upstream does not have at all.

That matters beyond tidiness. `Milestone:` is load-bearing here — it is the release → issue-set join
key (GH-284 Phase 3) that this whole plan's `/10days` hand-off depends on — and since
`PROJECT/PDDA.md` **is** sync-managed, the next `pdda-sync.sh` into this repo will overwrite our copy
and take `Milestone:` with it. **`Milestone:` needs upstreaming before this repo is re-synced**, not
after. Flagged in the maintainer prompt.
