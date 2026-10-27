---
title: "jog promotion reads the Preflight Contract's JSON fix_probes"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-27
owner: noelsaw1
gh_issue: 1232
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1232
doc_type: project
phases: 1
---

# GH-1232: jog promotion reads the Preflight Contract's JSON fix_probes

## Problem (observed)

GH-1175 Phase 0 (2026-10-26): an unattended `releases jog run` on #416 parked in under a second with
`unreviewed-probe-contract (no valid probes in unattended mode)`, although its capture doc carried a
JSON Swarm Preflight Contract that `swarm-preflight --dry-run` reported **ready (exit 0)**.

Cause, traced at base `5cab70c8`:

- `utils/py/jog_run.py:1354` `extract_probes_from_doc` reads only a frontmatter `fix_probes:` YAML
  list and treats each entry as a shell command (`lint_probe`, `:1318`).
- `promote_contract_to_working` (`:1379`, called from `:1939` with `interactive=sys.stdin.isatty()`)
  parks at `:1428-1430` when that list yields no valid probe and there is no tty.
- The probes preflight actually evaluates live in the contract's JSON `fix_probes`
  (`utils/py/swarm_preflight.py:54` `extract_contract`, `:195` `eval_probes`). Jog ignores them, so
  every unattended run on a 1-INBOX doc parks. GH-1087 only passed because its doc was already in
  2-WORKING.

## Requirements

1. An unattended promotion accepts the doc's JSON contract probes when the contract parses and
   **every** probe evaluates `unfixed` against the target (the same evaluator preflight uses).
2. A doc with no usable probes in either place still parks `unreviewed-probe-contract`.
3. A JSON `command` probe goes through the existing `lint_probe` (so `true` / `exit 0` stay rejected).
4. Frontmatter probes keep working unchanged, as an additional source.

## Preflight bet check

- **Outcome sought:** unattended Jog runs (#1175 Phase 1) can promote a correctly contracted 1-INBOX doc.
- **Smallest viable bet:** reuse `swarm_preflight.extract_contract` + `eval_probes` inside
  `promote_contract_to_working`, the same import pattern `marathon_drive.py:2627-2647` already uses.
  Not built: a new probe schema, a converter, a new parker, or any change to preflight.
- **Alternative rejected:** "promote via SOP 1b by hand first" (the Phase 0 workaround). It works, but
  every reconciler pass would have to do it, so the defect stays.
- **Rollback:** one function in one file; revert the commit.

## Plan

1. `utils/py/jog_run.py`: add `contract_probes_from_doc(root, doc_path)` next to
   `extract_probes_from_doc`. It returns `(probes, reason)`:
   - no `preflight contract` heading → `([], None)` (checked by regex first, as marathon_drive does,
     because `extract_contract` `sys.exit(3)`s without one);
   - import `extract_contract, eval_probes` inside `try`; parse inside `try/except SystemExit` → on
     failure `([], "contract did not parse")`;
   - any `command` probe whose `cmd` fails `lint_probe` → `([], "<lint reason>")`;
   - `eval_probes(root, contract)`; accept only if every verdict is `unfixed`; otherwise
     `([], "contract probes not all unfixed: landed=N blocked=N")`.
   It returns one label per probe (`grep_present:path`, `command:cmd`, …) for the existing
   interactive printout.
2. In `promote_contract_to_working`, when the frontmatter yields no valid probe, use the contract
   probes. If both are empty and the run is unattended, park as today; append the contract reason
   when there is one: `unreviewed-probe-contract (no valid probes in unattended mode; <reason>)`. The
   prefix stays the same for anything matching on it.
3. `skills/2-daily/jog/SKILL.md` "Fire-Time Promotion & Probe Linting": one bullet saying the JSON
   contract probes count, and when.

## Non-goals

- Converging the two probe schemas or removing frontmatter probes.
- Changing `swarm_preflight.py` or the preflight verdicts.
- New tests (AGENTS.md *No new tests*, GH-831).

## Verification

- Existing suites: `test/gh280-jog-marathon-adapter.sh` and `test/test_python_layer.py`, plus the
  routed final gate (`utils/ci-route.sh`).
- Manual smoke under `TESTS-RESULTS/2026-10-27+GH-1232/`, run in a disposable full clone, calling
  `promote_contract_to_working(..., interactive=False)` directly:
  - **Main path:** a 1-INBOX doc with a JSON contract whose probes read unfixed promotes (it returns
    the new path). **Red control:** the same doc at base `5cab70c8` parks.
  - **Adjacent paths:**
    - a doc with no probes anywhere still parks;
    - a contract whose probe already reads `landed` parks and names the counts;
    - a `command` probe of `true` parks with the lint reason.

## Rating (2026-10-27)

`rated 70/60/50/80`.

- **sev 60:** it blocks every unattended run on a 1-INBOX doc. It parks safely (no data loss) and a
  manual workaround exists (SOP 1b promotion).
- **pri 70:** a hard prerequisite for #1175 Phase 1. One incident (Phase 0), not a recurring class
  yet. Trend unknown.
- **appeal 50:** neutral.
- **effort 80:** one function, with an existing evaluator to reuse.

## Status

| What was just completed | What's next |
|---|---|
| Capture + plan written from recon at 5cab70c8 | Codex plan QA |
