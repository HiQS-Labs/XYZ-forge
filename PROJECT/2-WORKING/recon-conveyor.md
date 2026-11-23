---
title: Conveyor recon map
status: reference
created: 2026-11-09
updated: 2026-11-09
owner: codex
goal: Record traced conveyor handoff seams.
roadmap_exempt: true
---

# Recon Map — Conveyor upstream preparation
Commit: 39207869450ee7115dcd9b552fb1bcacd15e203b · Mode: grep-only · Lanes: A–D in one context (bounded skill composition)

## Status

| What was just completed | What's next |
|---|---|
| Traced the existing preparation and execution handoff. | Use this map with the GH-1401 canonical plan. |

## Subject and change class
Existing-issue intake preparation; cross-module instruction composition, no runtime/state authority replacement.

## The seams — where a change here escapes this file
| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| New versus existing intake | skills/1-hourly/idea/SKILL.md:80 | issue filing vs retrofit | conveyor creates duplicate issue or claims idea supports retrofit |
| Prior art | utils/py/prior_art_recon.py:178 | GitHub/PRS/helper discovery | missing/error/empty results are treated as proof of absence |
| Capture/PRS pickup | utils/py/releases_app.py:7043; SOP.md:71 | docs and canonical ledger | preparation sets accepted-start or creates competing writer |
| Contract schema | utils/py/swarm_preflight.py:54 | markdown into execution packet | bad target/probes/artifacts reaches dispatch |
| Probe semantics | utils/py/swarm_preflight.py:196 | target ref bug state into readiness | fix polarity falsely marks task already-landed |
| Consumer | utils/py/jog_run.py:1577; skills/2-daily/jog/SKILL.md:90 | capture into Jog promotion/preflight | label is mistaken for admission |

## Call paths in
Operator existing issue -> conveyor instructions -> prior_art_recon.main (utils/py/prior_art_recon.py:178) -> read existing doc/issue -> recon -> synthesize capture -> PRS roadmap pickup -> contract parser/Jog shape lint -> swarm-preflight --project-doc. Later explicit Jog add/run -> fire-time promotion -> preflight -> executor (skills/2-daily/jog/SKILL.md:90-109).

## State
Capture markdown holds plan/contract; PRS canonical CLI owns row writes. pickup creates/reuses selection row; accepted-start is separate qualified execution admission (utils/py/releases_app.py:4119-4251). GitHub issue state remains completion authority. No ready-for-pickup label selector found by bounded repository search; label is advisory discoverability only. Publication must reach integration ref before final label, because future consumers read that ref.

## Contracts
extract_contract validates target.repo/ref and gate strings, nonempty fix_probes/artifacts, optional artifacts_new subset and lanes (utils/py/swarm_preflight.py:54-151). Jog contract_probes_from_doc validates known probe types, nonempty path/pattern/cmd and command lint, without executing probes (utils/py/jog_run.py:1577-1632). eval_probes judges unfixed/landed/blocked; command success means unfixed by default, expect_nonzero reverses it (utils/py/swarm_preflight.py:196-245). New artifacts must have matching path_absent probe; detailed example at relay-automation/CONTRACT.example.md:1.

## Build, failure and rollback today
--project-doc reads inbox directly; --gh-issue searches only PROJECT/2-WORKING (utils/py/swarm_preflight.py:1221-1245). --dry-run still fetches and creates/removes a detached worktree; it is not side-effect-free research (skills/1-hourly/idea/SKILL.md:204). Gate command is inspected, not executed by preflight. No conveyor scheduler exists. Existing docs-only classification supports PDDA gate, while ledger changes follow actual classifier. Workflow can be reverted without schema migration.

## Step N+1 Downstream Checks
- Consumer hop: label does not select/advance anything; explicit Jog pickup owns queue/promotion, rejects malformed probes, runs ref-pinned preflight, parks not-ready and dispatches ready (skills/2-daily/jog/SKILL.md:90-109). This is an intentional publication signal, not a new nonterminal runtime status.
- Retry hop: conveyor rerun must reuse doc/row and marker comment, revalidate at current ref; no lease or retry daemon. Jog parks not-ready rather than looping (same lifecycle).
- Parameter role: artifacts constrain builder allowlist; fix_probes classify existing state, never generate work entities; --gh-issue chooses docs, --project-doc supplies one existing capture.
- Rollout/rollback: existing format/readers/writers unchanged; no queued-format migration. Last safe rollback always before removing the skill; prep docs remain valid existing inputs.

## Unknowns
| Unknown | Why it matters | What would settle it |
|---|---|---|
| Future external label automation | must not claim native event dispatch | operator-configured scheduler/event details at invocation; no setup in this issue |
| Backlog-wide contract quality | no guarantee every issue can be prepared | per-item recon, exact preflight and held outcome |

## Current-state radius, one line
Existing issue/capture/PRS writers, swarm preflight and Jog handoff; #1400 owns downstream flywheel composition separately. No runtime edits required.
