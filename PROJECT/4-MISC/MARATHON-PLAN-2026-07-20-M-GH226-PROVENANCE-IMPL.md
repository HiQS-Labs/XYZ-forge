---
title: Marathon Plan M (2026-07-20) — GH-226 provenance surfacing, two-lane implementation
status: "RETIRED 2026-08-03 to 4-MISC — never fired, and no longer fireable as written. #226 CLOSED. Lane C's core gate (consult.sh <-> consult.py parity) is now illegal: relay-automation/consult.sh is FROZEN under GH-308, Python authoritative. Wave 1 targets relay-turn-lib.sh (GH-308 Tier C containment logic) in Bash, against the phase-out-Bash policy. #223, its assumed baseline gap, is CLOSED. The GOAL — surface the existing FIRSTHAND_COUNT provenance signal into the operator report instead of a bare warn() — remains valid and is carried forward as a fresh Python-only issue; this doc is kept for its design record only."
created: 2026-07-20
updated: 2026-08-03
owner: noel
branch: gh-226/provenance-coordination
doc_type: project
source: GH-226 § Decision (Jedi thread answers 2026-07-20) + Plan I inventory
generated_by: hand-authored (single issue, two disjoint code lanes)
lanes: [226]
execution: >
  Wave 1 single-sources the firsthand-vs-operator-asserted contract in the shared predicate
  (Lane R owns the predicate); Wave 2 renders that signal into the two operator surfaces in
  parallel (Lane C consult, Lane R relay). Disjoint files → Wave 2 lanes run concurrently.
roadmap_exempt: true
goal: >
  Surface the already-computed firsthand-vs-operator-asserted provenance signal into the
  operator-facing report per GH-226's locked contract — Disagree/adjudication body + inline
  annotations, never the TLDR — for consult and relay under separate stamp contracts, without
  reworking GH-211's TLDR/category structure and without crossing the giant-brains repo boundary.
---

# Marathon Plan M — 2026-07-20 · GH-226 provenance surfacing (two-lane)

> **DRAFT for review.** This plan implements the contract locked in
> [GH-226 § Decision](../1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md). It is held
> until Jedi confirms scope on [#226](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226).
> Nothing here fires automatically.

## Status

| What was just completed | What's next |
|---|---|
| Planning (Plan I) closed; contract + file ownership locked in GH-226's doc. This fireable two-lane plan drafted. | Jedi sign-off on #226 → promote GH-226 doc 1-INBOX → 2-WORKING → run `swarm-preflight --gh-issue 226` → fire Wave 1, then Wave 2. |

## Design premise (from the inventory — this is not a from-scratch build)

The firsthand-vs-operator-asserted signal Jedi named as the Q3 priority **already exists**:
`relay-automation/consult.sh` computes `FIRSTHAND_COUNT` and a prompt-echoed classifier into a
`*.PROVENANCE.txt` sidecar today, surfaced only as a `warn()`. This plan is **surface + placement +
one contract tweak**, not a new classifier. That keeps risk/effort low.

Two stamp contracts, kept distinct (GH-226 Q2):
- **consult** — *advisor grounding*: did the advisor read the repo (`firsthand`) or answer from the
  prompt/priors (`operator-asserted` → flag `conditional`)?
- **relay** — *reviewer citation discipline*: did the reviewer quote evidence for a "verified"
  finding, or assert it? (existing `rtl_check_uncited_findings` per-line downgrade.)

## Phase / wave summary

| Wave | Lane | Deliverable | Primary artifact(s) | cx/risk/eff |
|---|---|---|---|---|
| 1 | R (predicate) | Extend the shared `rtl_has_uncited_claim` predicate to distinguish `firsthand` vs `operator-asserted` at the source, returning a classification not just a boolean. Single-sourced so both lanes consume one definition. | `relay-automation/relay-turn-lib.sh` | 2/2/2 |
| 2 | C (consult) | Render the existing `FIRSTHAND_COUNT`/classifier signal into the operator report — Disagree/adjudication body + inline `Sorted categories` notes; flag prompt-only conclusions `conditional`. TLDR untouched. Keep bash ↔ Python at parity. | `skills/consult/SKILL.md`, `relay-automation/consult.sh`, `utils/py/consult.py` | 2/2/2 |
| 2 | R (relay) | Render reviewer-citation provenance inline in the relay report surface using the Wave-1 classification; keep the stamp definition distinct from consult's. | `relay-automation/relay-turn-lib.sh` (render path), `relay-automation/new-relay.sh` | 2/2/2 |

Wave 2's two lanes touch disjoint files → run concurrently, each in its own `isolation: "worktree"`.

## Collision map

| Zone (file) | Lane(s) | Parallel-safe? | Wave |
|---|---|---|---|
| `relay-automation/relay-turn-lib.sh` — predicate contract | R | ⚠️ **Wave-1 exclusive** — the shared dependency; must land before Wave 2 consumes it | 1 |
| `skills/consult/SKILL.md` | C | ✅ | 2 |
| `relay-automation/consult.sh` + `utils/py/consult.py` | C | ✅ (parity pair — same lane edits both) | 2 |
| `relay-automation/new-relay.sh` + relay render path | R | ✅ | 2 |

Only shared dependency is the Wave-1 predicate; serializing it into Wave 1 removes the one real
collision. After that, C and R are file-disjoint.

## Gates (per wave, before advancing)

- **Wave 1:** `bash test/relay-uncited-findings.sh` (predicate behavior) + `bash validate.sh`.
- **Wave 2:** `bash test/consult.sh` + `bash test/relay-uncited-findings.sh` + `bash validate.sh`.
- Parity check: any stamp string added to `consult.sh` must appear in `consult.py` and vice-versa
  (this is why the parity pair is one lane, not two).
- A red gate stops the run — no force-merge, leave the branch for inspection.

## Explicit non-goals (carry from GH-226)

- No edit to `giant-brains-claude-skills` — relay's *external* operator report is a later follow-up.
- No change to GH-211's TLDR/category *structure* — provenance is additive, below the TLDR.
- No reopening GH-178's shipped A4 stamp beyond extending the shared predicate's return type.

## How to fire (only after Jedi GO + promotion to 2-WORKING)

```
utils/swarm-preflight.sh --gh-issue 226          # expect exit 0
# Wave 1: single lane, relay-turn-lib.sh predicate contract; gate; merge.
# Wave 2: two isolation:"worktree" lanes (consult / relay) in parallel; per-lane ancestry check;
#         merge one at a time; wave gate; remove worktrees.
```

After landing: `utils/pdda/pdda.sh run`, update CHANGELOG.md, comment the result on #226.
