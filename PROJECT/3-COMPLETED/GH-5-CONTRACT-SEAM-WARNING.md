---
gh_issue: 5
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/5
title: Promote the pinned shared-contract seam to a first-class coordinator step + warn on coupled lanes
status: Shipped (2026-07-03 — Plan A lane 4, PR pending)
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: improvement
complexity: 3
risk: 2
effort: 2
related:
  - utils/marathon-plan.sh
  - test/marathon-plan.sh
non_goals:
  - No auto-generated CONTRACT.md scaffold. The plan NAMES the seam and says "pin a contract"; writing the file stays the coordinator's call (a scaffold would guess the interface). Deferred.
  - No dependency-graph inference beyond the directory-spine heuristic + the existing explicit `after GH-N` deps. A true producer→consumer import graph would need to parse source; the spine heuristic is the cheap, events-free proxy the issue proposed.
---

# GH-5 · Contract-seam warning for coupled lanes

## Status

| Most recently completed | What's next |
|---|---|
| **✅ SHIPPED (Plan A lane 4).** The one thing that made two lanes *actually* independent in the real run was a coordinator-pinned shared contract (both lanes coded TO the contract, not to each other's source). That was ad-hoc operator discipline with nothing to detect the coupling — operators found it only when an agent stalled waiting on another lane. Now `marathon-plan.sh` **detects the seam**: within a wave, any two write-disjoint lanes that share a directory spine (deeper than a top-level dir) are flagged in a new **"Contract seams — pin a contract"** section that names the pair, the shared dir, and the fix (pin a `CONTRACT.md`, point each lane prompt at it). Pairs directly with GH-4 work-stealing — a stolen task that's actually coupled would stall; this surfaces it first. | Merge PR + cross-model review. Auto-scaffold + import-graph inference deferred (non_goals). |

## Problem

xyz's scope explicitly excludes tightly-coupled work, but **nothing detected it**. The wave-packer defers a lane only on an **exact** write-set path collision, so two lanes that write disjoint files under a common directory (e.g. `src/schema/producer.js` and `src/schema/consumer.js`) co-wave and *look* independent — while the consumer stalls on the producer's not-yet-built output. The contract seam that would decouple them was a mantra ("code to the contract", rule 4) with no explicit "pin the contract" step and no coupling detector.

## Design

Additive to `utils/marathon-plan.sh` (the planner already sees every lane's write-set and builds collision-safe waves):

1. **Detect the seam (fix 2).** `sharedSpine(wsA, wsB)` returns the deepest directory of ≥2 segments shared by any path in two lanes' write-sets (top-level-only sharing — both under `src/` — is intentionally NOT a seam; too coarse). After wave-packing, every same-wave pair with a shared spine becomes a `contractSeams` entry + a `warn`/`coupled-lanes` finding. **Advisory** — it never re-waves the lanes (they *can* parallelize once a contract is pinned); the exit code is unchanged.
2. **Make "pin the contract" explicit (fix 1).** A new **"## Contract seams — pin a contract before launching (GH-5)"** section in the generated plan lists each coupled pair, the shared dir, and the instruction: pin a short `CONTRACT.md` for that seam and point each lane's prompt at it. When there are no seams it prints `None`, so the step is always visible.
3. **Deferred-coupled-work (fix 3)** is already served by the plan's existing **Held / flagged** section (unrated / needs-contract / blocked-dep) — the auditable "what could not be lane-split and why."

Only lanes with a **proven** write-set (from a preflight contract) are judged; a zone-inferred lane with no write-set is skipped (can't assert a seam it can't see).

## QA gate

- [x] `test/marathon-plan.sh` scenario K (+3): two write-disjoint lanes sharing `src/schema/` **are** flagged as a seam (named pair + dir); a third lane in a disjoint subtree (`utils/`) is **not** flagged (no false seam); the section states the pin-a-contract step.
- [x] Existing 36 marathon-plan checks green — the section is additive; top-level-only sharing (scenario A's `src/indepa.js`‖`src/indepb.js`) is correctly NOT flagged. `--check` determinism holds (deterministic output).
- [x] `validate.sh` green (the one `relay-dep-drift` blip is a known timing flake — passes 12/12 on re-run; unrelated to this planner-only change).
