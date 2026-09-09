---
title: "GH-514: skills: new co-author skill \"keel\" — balance modularity, flexibility, maintainability, and ponytail for spec writing and total refactors"
status: Parked
created: 2026-09-08
updated: 2026-09-08
owner: unassigned
goal: give technical specs and total-refactor plans a co-author skill that balances modularity (especially new builds), flexibility, and maintainability under a reversibility spine, with ponytail delegated to the mechanism layer only
gh_issue: 514
source: https://github.com/HiQS-Labs/XYZ-forge/issues/514
doc_type: enhancement
effort: 4
complexity: 2
risk: 1
---

# GH-514 — keel: four-axis spec/refactor co-author skill

## Status

| What was just completed | What's next |
|---|---|
| Design negotiated with operator and parked 2026-09-08; issue + ledger row live | Awaiting operator go to start the start-task lifecycle (isolated task clone, author `skills/keel/SKILL.md`, relay plan QA, PR) |

## Problem statement

Nothing in the skill surface arbitrates the standing tension between ponytail's
mechanism-minimalism and the business goals of modularity/flexibility
(future-proofing). Specs and total-refactor plans get written either
over-abstracted or ponytail-lazy into costly-to-undo contracts. Four
operator-confirmed failure classes:

1. **Flexibility theater** — speculative interfaces, config nobody sets, plugin
   systems for one plugin.
2. **Monolith accretion** — new builds with no seams that harden into mud;
   "total" refactors that reshuffle the mud.
3. **Lazy one-way doors** — minimalism applied where the decision was one-way.
4. **Modular in name only** — module-shaped code still costly to change safely.

## Design (operator-approved 2026-09-08)

**Precedence stack** — the skill's spine, encoded as hard rules, not norms:

1. **Explicit business goals are immune.** Modularity/flexibility/future-proofing
   stated in the spec are requirements; ponytail has zero standing over them. It
   minimizes the mechanism, never the whether.
2. **Reversibility arbitrates unstated structure only** (Easy / Costly / One-way
   door, the repo's shared scale). Ponytail wins ties on Easy doors;
   modularity/flexibility win when skipping them creates a Costly or One-way
   door. One-way doors are surfaced explicitly, never taken silently. This one
   rule derives the "modularity especially for new builds" weighting: new-build
   seams are cheap to add and costly to retrofit, so they pass.
3. **Ponytail owns the mechanism layer only** — delegated (mirroring
   workhorse's chaining), never duplicated inline.

**Payer rule:** every extension point names its payer — a concrete near-term
change *or* an explicit business requirement. Unpaid structure is banned; a
stated business goal is a valid payer, recorded as such in the spec.

**Four checks, one per failure class:** seam test (if the most-likely next
change lands, how many modules does it touch — >1 needs justification); payer
rule; reversibility rating on consequential choices with one-way doors flagged;
coupling check (shared mutable state, hidden dependencies, unisolatable tests).

**Mode:** co-author. Shapes a spec or refactor plan section by section and
leaves the four-axis reasoning in the doc. Delegation: minimalism axis →
`/ponytail`; ground-truth pass in refactor mode → `/recon` when present;
general SWE doc standards stay owned by `/swe`.

**Non-goals:** no audit mode, no numeric scoring rubric, no persistent
always-on mode, no intensity levels, no template generator.

Working name `keel` (alternates `plumb`, `tetra`); final name at authoring time.

## Acceptance criteria (debug-mantra plan pivot)

- [ ] `skills/keel/SKILL.md` exists, skill-creator frontmatter conventions
      (folded block-scalar description with colons, per c4088fae).
- [ ] SKILL.md states the precedence stack and payer rule as hard rules;
      ponytail is invoked, not copied inline.
- [ ] Spec mode and total-refactor mode each have a procedure applying the
      four checks; refactor mode delegates ground truth to `/recon` when
      present.
- [ ] Zero new Bash files (GH-551).
- [ ] Global symlinks installed only on explicit operator request.

## Rating rationale (2026-09-08)

rated 70/25/50/65 — pri 70: explicit operator request, currently the active
ask; sev 25: docs/skill artifact, no runtime or data risk (worst case: a
misleading skill steers future specs); appeal 50: neutral, none supplied;
effort 65: well-scoped single-file authoring with an existing QA loop.
