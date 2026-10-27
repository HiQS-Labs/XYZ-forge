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

## Reviewer verdict — codex

**Changes requested — do not implement the stated 30-line plan unchanged.** The diagnosis of
the first refusal is correct, but the proposed evaluator call is neither in the same execution
context as Preflight nor safe for `command` probes.

- [Blocker] `extract_probes_from_doc` is the immediate reason the observed unattended promotion
  refuses: it supplies zero values to the `not valid_probes` guard at
  `utils/py/jog_run.py:1421-1430`, and the caller parks that returned reason at
  `utils/py/jog_run.py:1935-1944`. It is not the only later way the overall `jog run` can park:
  Preflight rejects a nonzero result at `utils/py/jog_run.py:1968-1989`. More importantly, the
  claimed “same evaluator” is not the same evaluation environment. Preflight resolves
  `target.ref`, creates a detached reference worktree, and evaluates there
  (`utils/py/swarm_preflight.py:1340-1364`); the proposed
  `contract_probes_from_doc(root, ...)` evaluates the mutable target checkout. A checkout ahead
  of (or different from) `target.ref` can promote here and immediately fail/stale at preflight.
  Revise the plan to establish one explicit, reference-pinned evaluation path (and say how its
  temporary worktree is cleaned up) before calling it equivalent to preflight.

- [Blocker] `eval_probes` executes `command` through `shell=True`
  (`utils/py/swarm_preflight.py:223-233`). `lint_probe` only rejects a few trivial strings and
  checks selected executable-path tokens (`utils/py/jog_run.py:1318-1336`); it neither makes a
  command read-only nor idempotent. The planned promotion check would therefore run an arbitrary
  contract command once in the mutable target clone, then preflight would run it again in its
  reference worktree (`utils/py/swarm_preflight.py:1364`). “Preflight will run it anyway” does
  not make the earlier, duplicate execution safe. The revised plan needs an explicit safe
  execution boundary/contract for command probes, or must explain a deliberately accepted,
  idempotence-enforced model; the existing lint is insufficient.

- [Should] Catch evaluator failures, not just `SystemExit` from `extract_contract`. The parser
  only requires that `fix_probes` be a non-empty list (`utils/py/swarm_preflight.py:92-94`), but
  `eval_probes` calls `p.get(...)` before its inner exception handler
  (`utils/py/swarm_preflight.py:199-206`). A list containing a scalar therefore raises instead of
  producing the promised unattended `unreviewed-probe-contract` park. Add this malformed-probe
  case to the manual adjacent controls and return a diagnostic park reason.

- [Pass] A lazy local import follows the established `marathon_drive` precedent
  (`utils/py/marathon_drive.py:2626-2635`). Both modules use the same local `utils/py` path and
  `harness_paths`; source inspection found no `swarm_preflight -> jog_run` import, so there is no
  import cycle or new vendored-layout risk from that import alone.

- [Pass] The proposed park-reason suffix preserves the only in-tree consumer-visible prefix.
  Narrow search: `rg -n -C 3 "unreviewed-probe-contract" --glob '!relay-system/**' .` exited 0;
  decisive matches were the producer at `utils/py/jog_run.py:1430`, documentation, and recorded
  evidence—no exact-match consumer was found.

- [Nit] `rated 70/60/50/80` is internally consistent with the stated priority/severity/appeal/
  effort rationale. Qualify “blocks every unattended run on a 1-INBOX doc” as the narrower
  documented cohort: 1-INBOX docs relying on JSON contract probes without valid frontmatter
  probes. The priority and effort claims are otherwise proportionate to the observed incident and
  scoped change.

- [Pass, contingent on the blockers] Existing `gh280` coverage plus the Python layer, routed
  gate, and a disposable-clone manual red/green receipt are commensurate under the no-new-tests
  rail. Keep the specified base red control and the three adjacent cases, and add the malformed
  non-object probe control above. Record the exact commands, exit codes, and decisive output in
  the committed `TESTS-RESULTS` provenance with the implementation.

## Author response — round 1 dispositions (claude-a)

- **Blocker 1 (wrong evaluation context): Accepted, and resolved by removing evaluation.** Promotion
  no longer calls `eval_probes`. It only parses the contract (`extract_contract`) and checks each
  probe's shape statically. "Unfixed or not" stays preflight's verdict, made in its ref-pinned
  worktree (`swarm_preflight.py:1340-1364`), which runs next. That gives one evaluation path, no
  temporary worktree at promotion, and nothing to clean up. Frontmatter probes were never
  executed at promotion either (`lint_probe` is static), so the two sources now behave the same way.
- **Blocker 2 (`shell=True` command run twice): Accepted, resolved by the same change.** No probe
  runs at promotion. A `command` probe's `cmd` gets only the existing static `lint_probe`. A new
  manual control proves this: a `touch .promotion-ran && false` probe leaves no marker.
- **Should (malformed probes): Accepted.** The shape check covers non-dict entries, unknown types,
  and missing `path`/`pattern`/`cmd`, and parks with `contract probe N malformed: <why>`. It is
  added to the manual controls.
- **Nit (cohort wording): Accepted.** The rating rationale now names the cohort: 1-INBOX docs that
  rely on JSON contract probes without frontmatter probes.
- The "landed probe parks" adjacent case is dropped. Promotion no longer evaluates probes, so a
  landed probe promotes and preflight reports it STALE, as it does today for 2-WORKING docs.

Revised plan: `PROJECT/1-INBOX/GH-1232-JOG-PROMOTION-PROBE-SCHEMA.md` (Requirements 1 and 3, the
bet check, Plan step 1, Verification). Round 2: is the static-shape design sufficient for the
stated requirement, and is anything still missing?

## Reviewer verdict — codex (round 2)

**Approved.** The revised static-shape admission is sufficient for the stated requirement: it
removes the sole first-promotion refusal for a contract-only doc without creating a second,
mutable-checkout execution path. Preflight remains the single ref-pinned verdict and can still
park a stale, blocked, or otherwise not-ready contract.

- [Pass] The acceptance rule is now correctly scoped. `promote_contract_to_working` needs a
  reviewed/usable probe source before its unattended guard (`utils/py/jog_run.py:1421-1430`); it
  does not need to decide whether the fix is landed. The next preflight resolves `target.ref` and
  evaluates in its detached worktree (`utils/py/swarm_preflight.py:1340-1364`), returning a
  nonzero result that Jog parks (`utils/py/jog_run.py:1968-1989`). Thus a well-formed but already
  landed probe promotes and is then classified by the existing preflight semantics, rather than
  being misclassified at promotion.

- [Pass] Not evaluating `command` probes at promotion resolves the prior safety objection.
  `eval_probes` invokes command probes with `shell=True` (`utils/py/swarm_preflight.py:223-233`),
  while the proposed admission is limited to static `lint_probe` validation. The planned marker
  control is the right proof that promotion does not execute it.

- [Should] In Plan step 1, import only `extract_contract`; `eval_probes` is no longer used and
  retaining it contradicts the parse-only design. Also spell every required `path`, `pattern`, and
  `cmd` as a **non-empty** string. An empty `path` currently makes the evaluator use `root`
  (`utils/py/swarm_preflight.py:201-204`), so accepting it as merely a string would not be a
  meaningful well-formed probe. This is a local implementation clarification, not a new schema.

- [Pass] The parser boundary is adequate once the stated shape checks are implemented. The shared
  parser already requires a non-empty `fix_probes` list (`utils/py/swarm_preflight.py:108-110`);
  rejecting scalar entries before any `p.get(...)` follows the evaluator's failure surface
  (`utils/py/swarm_preflight.py:199-206`) and gives the requested stable park reason.

- [Pass] Import risk remains low: both modules prepend their own `utils/py` directory and import
  `harness_paths` (`utils/py/jog_run.py:36-42`, `utils/py/swarm_preflight.py:16-24`). Narrow probe:
  `rg -n "from jog_run|import jog_run|harness_paths" utils/py/swarm_preflight.py utils/py/jog_run.py utils/py/harness_paths.py`;
  exit 0; decisive output contained only each module's `harness_paths` import and no
  `swarm_preflight -> jog_run` import. A lazy `extract_contract` import therefore introduces no
  cycle or vendored-layout change.

- [Pass] The rating and verification remain proportionate. Keep the existing-suite/Python-layer
  run plus routed gate, and the disposable-clone red/green receipt with all four listed adjacent
  controls. The previous narrow consumer probe also found no exact-match consumer of the reason
  prefix, so preserving `unreviewed-probe-contract` remains safe.

### System · relay-drive — 2026-10-27T15:18:20Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted

## Author note — round 2 turn failed validation (claude-a)

Codex's round-2 turn approved the plan, but the turn left out the required verdict line, so
relay-drive reverted it to Open. Its two clarifications are now in the plan: import only
`extract_contract`, and require non-empty `path`/`pattern`/`cmd`. Round 3: re-review the plan and
end your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a
non-empty `Basis:` line (GH-533).
