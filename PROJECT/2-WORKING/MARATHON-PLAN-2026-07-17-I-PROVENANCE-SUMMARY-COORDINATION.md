---
title: Marathon Plan I (2026-07-17) — provenance follow-up vs. summary-surface coordination (GH-226)
status: Active — standalone planning marathon captured; waiting on Jedi feedback and/or operator GO
created: 2026-07-17
updated: 2026-07-17
owner: noel
branch: development
doc_type: project
source: Jedi Wright Slack follow-up 2026-07-17 + GH-178/GH-211 split history
generated_by: hand-authored (single issue, 2 sequential planning phases, same-day)
lanes: [226]
execution: sequential single planning lane — inventory the surfaces first, then decide whether the
  next implementation pass stays one issue or splits by repo/surface
roadmap_exempt: true
goal: >
  Give Jedi's "full provenance + already-reworked summary surface" concern its own standalone
  marathon surface, keyed to GH-226, so the follow-up can be discussed and edited directly on
  GitHub before any code-facing provenance pass starts guessing at the final contract.
---

# Marathon Plan I — 2026-07-17 · provenance follow-up vs. summary-surface coordination

> Single issue, planning-first, intentionally standalone. This marathon does not assume the final
> code change shape; it exists to make the next provenance pass explicit, editable, and bounded.

## Status

| What was just completed | What's next |
|---|---|
| Opened [#226](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226), parked the local intake doc, and keyed this standalone marathon plan to that issue so Jedi can edit the GH issue directly if he wants. | Wait for Jedi clarification or operator GO, then fire the single planning lane to inventory GH-211/GH-178 surfaces and decide whether the next execution stays one issue or splits by repo/surface. |

## Why this gets its own marathon

This is not just "another provenance bug."

- **GH-211** already changed the operator-facing report shape.
- **GH-178** intentionally did not ship the full provenance taxonomy.
- The relay summary surface is partly owned outside this repo (`giant-brains-claude-skills`), so a
  future implementation pass may cross a repo boundary even if the planning pass lives here.

That makes the next move a coordination marathon, not a blind code lane.

## Phase summary

| Phase | Deliverable | Primary artifact(s) | cx/risk/eff | Fireable? |
|---|---|---|---|---|
| 1 | Inventory every operator-facing summary surface touched by GH-211 and every provenance surface touched by GH-178 | `PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md` | 1/1/1 | ✅ ready |
| 2 | Decide whether the next implementation stays one coordinated issue or splits by repo/surface, then sync this plan to that decision | `PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md`, this plan | 2/2/1 | ⏸ after Phase 1 |

## Collision map

| Zone (shared file) | Parallel-safe? | Phase |
|---|---|---|
| `PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md` | ✅ only this marathon should touch it | Phase 1 / 2 |
| `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-I-PROVENANCE-SUMMARY-COORDINATION.md` | ✅ only this marathon should touch it | Phase 2 |

No repo-code files are in scope for this planning marathon. If Phase 2 concludes code changes are
needed, those should be split into their own explicitly-owned follow-up issue(s) unless the blast
radius still looks safely single-lane.

## Execution contract

- **Path:** one planning lane only. No code edits, no transcript-mechanics edits, no external-repo
  edits in this marathon.
- **Phase 1** must produce an explicit inventory section in GH-226's local doc.
- **Phase 2** must state one of two outcomes, not hedge:
  - keep GH-226 as the single coordinated execution issue, or
  - split follow-up issue(s) by repo/surface and link them.
- If Jedi clarifies scope on GitHub before the lane is fired, treat that comment as an input to
  Phase 1's inventory/decision, not as a separate undocumented side channel.

## How to fire

```
utils/swarm-preflight.sh --gh-issue 226 --dry-run
relay-automation/marathon-drive.sh ...   # single planning lane, docs only
```

After the lane lands: re-run `utils/pdda/pdda.sh roadmap-coverage` and update GH-226 with the
decision so the next implementation pass has one canonical starting point.
