---
Goal: Plan QA — GH-1232 jog promotion reads the Preflight Contract's JSON fix_probes
Date: 2026-10-27
NEXT: codex
STATUS: Open
---

# Context

Review the plan in `PROJECT/1-INBOX/GH-1232-JOG-PROMOTION-PROBE-SCHEMA.md` (issue https://github.com/HiQS-Labs/XYZ-forge/issues/1232) before implementation. Base `5cab70c8`.

Requirement: an unattended `releases jog run` on a 1-INBOX doc whose JSON Swarm Preflight Contract would pass `swarm-preflight --dry-run` must promote rather than park `unreviewed-probe-contract`. A doc with no usable probes still parks. Observed in GH-1175 Phase 0 on #416.

Operational envelope: a ~30-line change in one function of `utils/py/jog_run.py`, plus one SKILL.md bullet. Reuse the existing evaluator. Do not ask for new tests (AGENTS.md *No new tests*, GH-831), new suites, new schemas or machinery. Grade against the stated requirements and commensurate complexity.

Read:
- the plan doc in full
- `utils/py/jog_run.py` lines 1318–1337 (`lint_probe`), 1354–1376 (`extract_probes_from_doc`), 1379–1440 (`promote_contract_to_working`), and its call site around 1930–1945
- `utils/py/swarm_preflight.py` lines 54–151 (`extract_contract`) and 195–245 (`eval_probes`)
- `utils/py/marathon_drive.py` lines 2615–2655 (existing import/SystemExit precedent)
- `skills/2-daily/jog/SKILL.md` "Fire-Time Promotion & Probe Linting" (lines 90–96)

Questions:

1. Is the recon right? Is `extract_probes_from_doc` the only reason a correctly contracted 1-INBOX doc parks unattended, or does a later step in `promote_contract_to_working` or `jog run` also block it? Cite file:line.
2. Is "accept only when every contract probe evaluates `unfixed`" the right acceptance rule? Is it safe to run `eval_probes` (which executes `command` probes) at promotion time in the target clone, given preflight runs the same evaluator immediately after?
3. Does importing `swarm_preflight` from `jog_run.py` (via the marathon_drive pattern) risk side effects, import cycles or vendored-layout breakage? Note that `swarm_preflight` imports `harness_paths`, and so does `jog_run`.
4. Is the park reason change (same prefix, with the contract reason appended) safe for every consumer that matches on `unreviewed-probe-contract`?
5. Are the rating (70/60/50/80) and its rationale grounded?
6. Are the verification (existing gh280 suite + python layer, routed gate, and the manual smoke with red control and three adjacent cases) sufficient and commensurate?

Flag anything wrong, missing, or over/under-scoped, citing file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Write your verdict below and set STATUS to Approved if the plan can proceed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
