# Plan draft: #1214 Plan (draft r4): evidence-gated lessons read-back + champion/ATE tie-in, borrowing from Google Harness² (Apache-2.0)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1214-d058e05d3214` (tick `slot_068`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: d058e05d3214132ac263ba00c8e501e60560f7b7e0daebe1be42043c32681d8c (updated 2026-10-25T06:58:19Z)
- Dependencies: none

## Scope

_Source: issue#1214:L41 (Phase 0: Decide scope (operator))_

- [x] **The single lessons home. Decided 2026-10-24 (operator):** the existing root `LESSONS-LEARNED.md`, converted to structured entries (QA agreed). `docs/LESSONS.md` doesn't exist. `/sop` looks for existing lessons docs before it scaffolds a new one (`sop/SKILL.md:50-67`), so it will find this file; its governance-path rule applies only when scaffolding. No other lessons file was found.
- [x] **Doc sections. Decided 2026-10-24 (operator): option B.** Completed-doc `## Lessons Learned` sections **stay advisory and become input to the writer.**
  - The GH-693 behavior is unchanged: the section is highly recommended, not required. `express.py` still scaffolds it, and `wave_reconcile` still warns and promotes. No gate.
  - When the Phase 1 writer runs, it reads the doc's section, if present, as a **candidate** and applies the admission rule. It either writes a curated entry whose `source` links back to the doc, or writes `NO_ENTRY`. Expect `NO_ENTRY` most of the time; the section keeps its value as the local record either way.
  - **No backfill** of the 124 existing sections. They are used only when that area is touched again; a one-off seeding pass would be a separately reviewed batch under the same admission rule.
  - Rejected: leaving them unconnected (A, two lesson stores drifting apart), copying all 124 (C, floods the store with entries lacking evidence), retiring them (D, reverses most of GH-693 for churn), making them mandatory again (E, reverses GH-693 and breaks D7).


_Source: codex-authored (codex-authored)_

Review the draft plan for evidence-gated lessons writing and read-back, including the champion and ATE tie-in in Phase 6a.

_Source: codex-authored (codex-authored)_

Verify the reported lessons sources, relay containment, vendoring, and Bash/Python parity constraints against current behavior.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The plan addresses Phase 1 and Phase 6a while keeping later phases separately scoped as described.

_Source: codex-authored (codex-authored)_

The plan uses the existing lessons home and identifies evidence admission and read-back behavior consistent with the stated constraints.

_Source: codex-authored (codex-authored)_

Verification uses the stated manual-check approach and accounts for existing suites where applicable.

## Open questions

_Source: issue#1214:L179 (Open questions)_

- Phase 3: which component resolves the model and skill identity for `config_sha256` (above).
- Phase 6b: how many passes, and what accept margin (above).

_Source: codex-authored (codex-authored)_

What requirements and accepted QA dispositions appear beyond the truncated issue body and in its comments?

_Source: codex-authored (codex-authored)_

What are the current implementation status and precise acceptance criteria for Phase 1 and Phase 6a?

## Write set

- `sentinel-overlay/sentinel-triage.sh` (issue#1214:L17)
- `utils/py/wave_reconcile.py` (issue#1214:L21)
- `LESSONS-LEARNED.md` (issue#1214:L22)
- `skills/3-weekly/sop/SKILL.md` (issue#1214:L23)
- `relay-automation/harvest-findings.sh` (issue#1214:L24)
- `relay-automation/proposals-sink.sh` (issue#1214:L25)
- `utils/pdda/check_inventory_ratchet.py` (issue#1214:L32)
- `AGENTS.md` (issue#1214:L33)
- `relay-automation/relay-turn-lib.sh` (issue#1214:L34)
- `skills/2-daily/start-marathon/SKILL.md` (issue#1214:L34)
- `utils/py/harness_app.py` (issue#1214:L35)
- `utils/py/express.py` (issue#1214:L45)
- `skills/1-hourly/start-task/SKILL.md` (issue#1214:L59)
- `skills/3-weekly/marathon-cleanup/SKILL.md` (issue#1214:L59)
- `utils/py/rtl.py` (issue#1214:L60)
- `relay-automation/smallcode-turn.sh` (issue#1214:L60)
- `skills/1-hourly/consult/SKILL.md` (issue#1214:L70)
- `utils/py/consult.py` (issue#1214:L70)
- `utils/py/marathon_drive.py` (issue#1214:L86)
- `utils/py/relay_drive.py` (issue#1214:L86)
- `utils/py/relay_attest.py` (issue#1214:L86)
- `utils/py/jog_run.py` (issue#1214:L90)
- `validate.sh` (issue#1214:L97)
- `utils/py/releases_app.py` (issue#1214:L115)
- `relay-automation/champion.sh` (issue#1214:L124)
- `skills/4-occasional/ate/SKILL.md` (issue#1214:L129)
- `utils/py/repro_synth.py` (issue#1214:L133)
- `utils/py/repro_builder.py` (issue#1214:L133)
- `skills/4-occasional/defect-campaign/SKILL.md` (issue#1214:L134)
- `utils/ate/variations.turn-shims.yaml` (issue#1214:L142)
- `utils/ate/variations.tool-calling.yaml` (issue#1214:L142)
- `utils/ate/variations.tool-density.yaml` (issue#1214:L142)
- `SHAKEDOWN/INDEX.md` (issue#1214:L175)

## Unresolved file names

- `xyz-vendor.sh` (issue#1214:L36; 2 tracked files share this name)
- `consult.sh` (issue#1214:L70; 2 tracked files share this name)
- `improve-loop.sh` (issue#1214:L99; 2 tracked files share this name)
- `heldout-check.sh` (issue#1214:L125; 2 tracked files share this name)
- `oracle-guard.sh` (issue#1214:L125; 2 tracked files share this name)
- `SKILL.md` (issue#1214:L141; 77 tracked files share this name)
- `measure.sh` (issue#1214:L146; 2 tracked files share this name)
- `champion.sh` (issue#1214:L146; 2 tracked files share this name)

## Contract probes

- none
