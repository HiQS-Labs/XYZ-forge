---
title: Marathon Plan — XYZ Forge Retrospective Adoption (#777)
status: Active (2-WORKING)
created: 2026-09-24
updated: 2026-09-24
owner: noel
branch: development
doc_type: project
roadmap_exempt: true
reversibility: Easy — file-scoped feature branches, no destructive schema drops
goal: >
  Adopt rebalanceOS #257 retrospective lessons and starter kit into XYZ Forge
  across two sequentially ordered waves with audited disjoint write sets and single-owner registries.
---

# Marathon Plan 2026-09-24 — XYZ Forge (#777)

## Status

| What was just completed | What's next |
|---|---|
| Master Umbrella #777 created; Codex QA relay completed & adjudicated; related issues linked | **Wave 1 Execution:** Lane 1 (Start-Task Prior-Art) ‖ Lane 2 (PDDA Proof-of-Done Gate) |

## Disjoint Write-Set Collision Matrix

| Lane | Subsystem Target | Primary Write Set (Disjoint) | Tests & Verification |
|---|---|---|---|
| **Wave 1 Lane 1** | `/start-task` Prior-Art Fan-Out | `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/marathon-triage/SKILL.md`, `utils/py/prior_art_recon.py` | `test/gh777-start-task-prior-art.sh` |
| **Wave 1 Lane 2** | PDDA Proof-of-Done Gate | `.github/pull_request_template.md`, `utils/pdda/pdda-doc-ready.sh`, `utils/pdda/pdda-install.sh` | `test/gh777-pdda-doc-ready.sh` |
| **Wave 2 Lane 1** | Shrink-Only Inventory Ratchet | `utils/pdda/check_inventory_ratchet.py`, `utils/pdda/inventory_ratchet_baseline.json` | `test/gh777-inventory-ratchet.sh` |
| **Wave 2 Lane 2** | Tri-State Health & Non-Inert Testing | `utils/py/gate_status.py`, `src/flightdeck/connectors.py` | `test/gh777-tri-state-health.sh` |
| **Wave 2 Lane 3** | Central Registry & Test Hygiene | `validate.sh`, `ci-local.sh`, `test/gh777-test-hygiene.sh` (Sole owner of central runner files) | `./validate.sh --sequential`, `bash ci-local.sh` |

---

## Wave 1: Skill Rails & PDDA Mechanical Gates

### Lane 1: Sub-Agent Prior-Art Recon in `/start-task`
- **Goal:** Update `/start-task` Step 0 to execute a bounded, single-child read-only probe across open PRs (`gh pr list`), `releases.db` roadmap, and existing `lib/*` / `utils/py/*` helpers before authoring new utilities. Reports `UNKNOWN` gracefully if sibling repos are offline.
- **Write Set:** `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/marathon-triage/SKILL.md`, `utils/py/prior_art_recon.py`.
- **Proof of Done:** `test/gh777-start-task-prior-art.sh` passes; dry run demonstrates prior-art citation in plan output.

### Lane 2: PR Template & PDDA "Proof of Done" Mechanical Gate
- **Goal:** Add mandatory prior-art search log and "Proof of Done" test commands to PR template. Update `pdda-doc-ready.sh` to mechanically block capture doc promotion if placeholder sections (e.g. `Lessons Learned: (fill in...)`) or unverified claims are present.
- **Write Set:** `.github/pull_request_template.md`, `utils/pdda/pdda-doc-ready.sh`, `utils/pdda/pdda-install.sh`.
- **Proof of Done:** `test/gh777-pdda-doc-ready.sh` asserts placeholder rejection and valid proof-of-done acceptance.

---

## Wave 2: CI Ratchets, Tri-State Health & Invariant Testing (Ordered after Wave 1)

### Lane 1: Shrink-Only Inventory Ratchets
- **Goal:** Create `utils/pdda/check_inventory_ratchet.py` enforcing shrink-only baselines on loose scripts in `scripts/`/`utils/`, direct SQLite connects (with explicit allowlist for canonical gateways `releases_app.py`, `flightdeck/connectors.py`, `hq-lib.sh`), and raw LLM clients.
- **Write Set:** `utils/pdda/check_inventory_ratchet.py`, `utils/pdda/inventory_ratchet_baseline.json`.
- **Proof of Done:** `test/gh777-inventory-ratchet.sh` passes with negative mutation control.

### Lane 2: Tri-State Health Probes & Non-Inert Testing Invariants
- **Goal:** Update health checks (`gate-status.sh`, `releases_app.py doctor`) so probe timeouts/errors return `UNKNOWN` (exit 2, never green). Add companion broken-probe tests and enforce `SOP.md` §6 non-inert duplicate fixtures in aggregation suites.
- **Write Set:** `utils/py/gate_status.py`, `src/flightdeck/connectors.py`.
- **Proof of Done:** `test/gh777-tri-state-health.sh` passes with simulated probe failure asserting non-green exit.

### Lane 3: Central Registry & Test Suite Hygiene Integration
- **Goal:** Single owning lane for `validate.sh` and `ci-local.sh`: register new ratchets, add `assert collected > 0` guard, foreign-CWD invocation safety, and clock pinning at the UTC boundary.
- **Write Set:** `validate.sh`, `ci-local.sh`, `test/gh777-test-hygiene.sh`.
- **Proof of Done:** `./validate.sh --sequential` and `bash ci-local.sh` pass with new test hygiene checks active.

---

## Acceptance & Quality Checklist
- [ ] Every lane runs in an isolated task clone branched from `development`.
- [ ] Central registries (`validate.sh`, `releases.db`) are modified only by Lane 3 in Wave 2.
- [ ] Wave 1 merges and passes full gate before Wave 2 commences.
- [ ] All inventory ratchets ratchet downward permanently.
