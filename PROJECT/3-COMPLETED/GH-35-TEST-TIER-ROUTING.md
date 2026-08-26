---
gh_issue: 35
source: https://github.com/HiQS-Suite/XYZ-forge/issues/35
title: "3-Tier test suite selection (docs, utility libraries, core harness) + CPU governance"
status: Active (2-WORKING — Phases 1+2 built 2026-08-18; Phase 3 pending)
created: 2026-08-18
updated: 2026-08-18
owner: noelsaw1
doc_type: feedback
effort: 3
complexity: 3
risk: 3
phases: 3
goal: >
  Cut local gate latency and CPU saturation for scoped changes: docs changes gate on PDDA only
  (tier 1), registered utility subsystems run their focused suites (tier 2), everything else —
  and every fail-closed boundary — still runs the full suite (tier 3). CPU governance is a
  separate axis: a balanced cores/2 default, nice -n 10 workers, and explicit throttle/burst
  levers, so a push stops pegging the whole machine.
---

# GH-35: 3-Tier Test Suite Selection + CPU Governance

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1+2 BUILT 2026-08-18 (clone `XYZ-forge-gh35`, branch `development`)**: the Tier-2 subsystem registry lives in `utils/ci-route.sh` (one registry consumed by `githooks/pre-push`, `validate.sh`, and — in Phase 3 — CI); `validate.sh` gained `--tier 1|2|3`, `--subsystem`, `--auto`, `--paths-file`, `--throttle`/`--quiet-cpu`, `--burst`, `--max-parallel`, and env levers `XYZ_VALIDATE_THROTTLE`/`XYZ_VALIDATE_MAX_JOBS`; the balanced `cores/2` (floor 2, cap 4) default replaced `cores-2` (cap 8); every suite worker runs under `nice -n 10`; `githooks/pre-push` dispatches `route=fast`+`tier=2` pushes to `validate.sh --paths-file`. New suite `test/gh35-test-tiers.sh` 56/0 (registry drift guard, fail-closed boundaries, tier execution end-to-end against fixture clones, CPU-lever decisions); `test/gh544-pre-push-gate.sh` extended to 85/0 with the tier-2 dispatch + registry-gap-falls-back cases; `test/ci-route.sh` 48/0 with tier pins. | **Phase 3** (not started): `validate.sh --tier 3` explicit alias exists via the default but the phase's own items do not — hosted CI `canary-ubuntu` still consumes the legacy hardcoded 11-test `FAST_TESTS` array instead of the classifier's tier-2 set; `test/test-tier-registry.sh` (every file under `utils/`, `skills/`, `test/*.sh` explicitly classified) is only partially covered by the drift guard in `test/gh35-test-tiers.sh`. Also owed: measured before/after CPU + wall-clock evidence on a real push (the issue's success criterion), and the CI-coverage note below reconciled when CI alignment lands. |

## Quad Concepts
- Local gate latency and machine-wedging CPU load make scoped changes expensive → tiered selection + a balanced, niced concurrency default
- Test selection must never silently weaken the gate → one fail-closed registry; unknown paths, test edits, and kernel surfaces always escalate to the full suite
- Resource policy and test selection evolve independently → width/nice levers (`--throttle`/`--burst`/env) can never change WHICH tests run
- Tier 1/2 are pre-push speed only → every tier below 3 disclaims promotion evidence; `ci-local.sh` stays sequential full-suite (GH-509)

## Table of contents

- [Acceptance criteria (from the issue)](#acceptance-criteria-from-the-issue)
- [Phase 1 — Tier 1 docs fast-path](#phase-1--tier-1-docs-fast-path)
- [Phase 2 — Tier 2 utilities + CPU governance](#phase-2--tier-2-utilities--cpu-governance)
- [Phase 3 — Tier 3 + invariants (pending)](#phase-3--tier-3--invariants-pending)
- [Design decisions and deviations](#design-decisions-and-deviations)
- [Validation](#validation)

## Acceptance criteria (from the issue)

Transcribed from [#35](https://github.com/HiQS-Suite/XYZ-forge/issues/35); the checkboxes reflect
THIS repo's state, not the issue's. Phases 1+2 were the requested scope; Phase 3 is pending.

### Phase 1 (Tier 1 - Docs)
- [x] `utils/ci-route.sh` accurately classifies all doc/transcript/evidence paths as Tier 1 (`route=docs`). *(Widened per the issue's scope table: `*.md`, `*.txt`, `PROJECT/`, `docs/`, `relay-system/`, `decisions/`, `.pdda-*`, `.xyz-launch-artifact`.)*
- [x] `validate.sh --tier 1` runs deterministic PDDA and governance checks with minimal CPU. *(Same pair of gates the push hook's docs route runs — `pdda.sh run` + warn-only `pdda-local-checks.sh` — so the two cannot drift. Latency is PDDA's own, ~60-110s; the criterion's "<30s" is PDDA-internal work this phase deliberately did not duplicate.)*
- [x] Any non-doc file modification strictly fails closed out of Tier 1. *(Pinned: `test/ci-route.sh` tier cases + the classifier's zero-path/full-required branches.)*

### Phase 2 (Tier 2 - Utilities + CPU Throttling)
- [x] Concurrency default updated from aggressive `cores-2` (8 max) to balanced `cores/2` (4 max) with `nice -n 10` process priority reduction. *(Pinned portably — "auto-detected width <= 4 on any host" — in `test/gh35-test-tiers.sh`; nice observed as `nice=10` from inside a pool worker.)*
- [x] CLI flags `--throttle` (2 workers), `--burst` (max workers), and ambient env `XYZ_VALIDATE_THROTTLE=1` implemented and verified. *(Plus `--quiet-cpu`/`--max-parallel` aliases and `XYZ_VALIDATE_MAX_JOBS=N`, precedence flags > MAX_JOBS > THROTTLE > PARALLEL > host default.)*
- [x] `validate.sh --tier 2` and `githooks/pre-push` execute targeted subsystem tests on utility edits. *(7 subsystems mapped per the issue's matrix; the hook requires `route=fast` AND `tier=2` AND non-empty runnable suites, else full gate. Latency target <45s is a measurement item — see Validation.)*

### Phase 3 (Tier 3 - Core + Invariants)
- [ ] `validate.sh --tier 3` and `./validate.sh --auto` execute full acceptance suite for core changes. *(Both exist and route correctly today, but the phase's CI-alignment and registry-sweep items are not built.)*
- [ ] Hosted CI `canary-ubuntu` dynamically consumes classified Tier 2 tests for PRs.
- [ ] Any core kernel/driver touch, deleted test, or unmapped path strictly fails closed to Tier 3. *(This specific criterion IS already pinned by `test/gh35-test-tiers.sh` + `test/ci-route.sh`; it is unchecked only because the issue groups it under Phase 3.)*
- [ ] `ci-local.sh` and hosted macOS boundary remain 100% full sequential Tier 3 (GH-509 compliant). *(Unchanged and pinned by `test/gh544-parallel-default.sh`; same grouping note.)*
- [ ] Regression test `test/test-tier-registry.sh` prevents unclassified utility or test drift. *(Partial: `test/gh35-test-tiers.sh` pins every registered suite exists AND is in TESTS; the every-file-classified sweep is Phase 3.)*

## Phase 1 — Tier 1 docs fast-path

**Built.** The docs surface list in `utils/ci-route.sh` widened to the issue's scope table, and
`validate.sh --tier 1` runs the same docs gate the push hook runs for `route=docs` pushes
(`utils/pdda/pdda.sh run`, blocking; `utils/pdda-local-checks.sh run`, warn-only by contract).
Tier 1 runs no fixtures, so the GH-1 clone-identity bracket does not apply to it.

**QA gate:** `test/gh35-test-tiers.sh` §5 drives the real `validate.sh` in a fixture repo with
stubbed PDDA gates — green dispatch, red-refusal, and no-suite-runs pins. Classifier tier pins
in `test/ci-route.sh` §GH-35.

## Phase 2 — Tier 2 utilities + CPU governance

**Built.** Four surfaces changed together:

1. **The registry** (`utils/ci-route.sh`): the issue's 7 subsystems (hq, releases, telemetry,
   ate, swe-diagram, pdda, agent2agent) as one declarative mapping — paths in `subsystem_of()`,
   suites in `SUBSYSTEM_TESTS_<name>` — emitting `tier=`, `tier2_subsystems=`, `tier2_tests=`,
   `tier_reason=` alongside the existing GH-509 route keys. `utils/ci-route.sh subsystems [name]`
   lists the registry and fails loudly on a suite missing from disk.
2. **The runner** (`validate.sh`): `--tier 1|2|3`, `--subsystem <name>`, `--auto [range]`,
   `--paths-file <file>` (what the hook hands over). Tier 2 runs the selected suites through the
   SAME pool/driver-lock-lane/identity-bracket/GH-15-summary machinery as tier 3, plus static
   syntax checks on the changed files and the PDDA gate when docs paths are in the set.
3. **CPU governance** (`validate.sh`): balanced default `max(2, min(4, cores/2))` (was
   `cores-2` capped 8), every worker under `nice -n 10`, tier-2 default width 2, `--throttle`/
   `--quiet-cpu` (2 workers), `--burst` (restores `cores-2` capped 8), `--max-parallel N`
   (alias), env `XYZ_VALIDATE_THROTTLE=1` / `XYZ_VALIDATE_MAX_JOBS=N` / `XYZ_VALIDATE_PARALLEL`
   with flags > MAX_JOBS > THROTTLE > PARALLEL > host-detection precedence. Malformed env values
   exit 2 naming the variable; conflicting concurrency flags exit 2.
4. **The push hook** (`githooks/pre-push`): `route=docs` → docs gate (unchanged);
   `route=fast` AND `tier=2` AND non-empty runnable `tier2_tests` → `validate.sh --paths-file`
   under nice; anything else → the full gate. The hook re-derives nothing: validate.sh
   re-classifies the paths file and refuses (exit 2) unless it comes out tier 2.

**QA gate:** `test/gh35-test-tiers.sh` 56/0 — CPU-lever decisions via `--print-mode` (so the
suite cannot recurse), the registry drift guard (every registered suite exists AND is in
validate.sh's TESTS; a ghost suite fails the listing loudly), and end-to-end tier-1/tier-2
execution against fixture clones (real runner + real pool + stub suites): green/red per tier,
fail-closed refusal on a non-tier-2 path list, escalation when a subsystem's suites are missing
on disk, static-check failure on broken syntax, PDDA pulled in when docs paths ride along, and
`nice=10` observed from inside a pool worker. `test/gh544-pre-push-gate.sh` 85/0 — the hook's
tier-2 dispatch (args recorded by a stubbed validate.sh), the registry-gap-falls-back-to-full
case, and red-gate refusal on the tier-2 route.

## Phase 3 — Tier 3 + invariants (pending)

Not started; see the Status table. The fail-closed behaviors it asks for are already pinned
(unmapped → tier 3, test edits → tier 3, deleted tests → full, kernel surfaces → tier 3), and
`--auto`/tier-3 routing exists, but CI still runs the legacy hardcoded fast list and the
every-file-classified sweep (`test/test-tier-registry.sh`) is owed.

## Design decisions and deviations

1. **Tier is computed independently of route, and they deliberately disagree in two places.**
   An unmapped code path (e.g. `tool.js`) routes `fast` (CI still runs its containment list +
   changed-area tests) but is tier 3 locally (the push hook runs the full gate). An ordinary
   test edit routes fast but is tier 3 — per the issue-comment guardrail, a change to the
   routing contract's own evidence never weakens its own gate. CI behavior is unchanged; only
   the local push boundary got narrower.
2. **`utils/pdda/**` moved from blanket-full to the pdda subsystem, and `skills/agent2agent`
   code moved to the agent2agent subsystem** — both per the issue's Tier-2 matrix, changing the
   pre-GH-35 posture pinned in `test/ci-route.sh` (expectation updated in the same commit, with
   the reason in a comment). Consequence to reconcile in Phase 3: a hosted PR touching only
   `utils/pdda/pdda.sh` now takes CI's fast lane instead of the full lane; the local push
   boundary still runs the 7 PDDA suites.
3. **`skills/**/SKILL.md` stays docs (tier 1)** — explanatory markdown uses the docs gate; the
   skill's CODE paths (`scripts/`, `install.sh`, agents) route through subsystems. This matches
   the pinned pre-GH-35 behavior (`test/ci-route.sh`) and the issue's own "doc-only
   `skills/**/SKILL.md`" tier-1 scope line.
4. **CPU governance is not a substitute for limits** (issue-comment guardrail): `nice -n 10` is
   announced as a scheduling hint; the width default is the measurable half. No cgroup-style
   CPU caps were attempted — not portable to a developer-toolkit context on macOS.
5. **One registry, one classifier.** `validate.sh`, the hook, and CI (Phase 3) all consume
   `utils/ci-route.sh`; `--subsystem` resolves through its listing rather than a second table.
   The hook never asserts the tier itself — it hands over the path list and validate.sh
   re-classifies, refusing anything that is not tier 2.
6. **Fail-closed is the default answer of the classifier**: empty diff, missing classifier,
   force-push/unusable range, deleted/renamed test, unmapped path, kernel surface, test edit —
   all tier 3. A subsystem whose suites are missing on disk escalates rather than running
   nothing (the releases-skill lesson).

## Validation

| What | Result |
|---|---|
| `test/gh35-test-tiers.sh` (new, registered in TESTS same commit) | 56/0 |
| `test/gh544-pre-push-gate.sh` (extended) | 85/0 |
| `test/ci-route.sh` (extended with tier pins) | 48/0 |
| `test/gh544-parallel-default.sh` (pinned usage/reason contract) | 29/0 |
| `test/ci-workflow.sh` | green (exit 0) |
| `bash test/gh308-frozen-twin-guard.sh --check --staged` | clean — no frozen twin touched, no new Bash under `utils/`/`relay-automation/` |
| Full `./validate.sh` (tier 3) on this change | **GREEN 216/216** (2026-08-18, standalone clone `XYZ-forge-gh35`, 4-wide balanced, ~12 min wall) — first run was RED for real reasons this change then fixed (path-integrity: fictional example paths in tier assertions; GH-472: piped `grep -q` shapes; security-scan: un-baselined `ok()` eval in the new suite; roadmap-dashboard: stale committed artifact) plus one expected false alarm: the GH-1 identity bracket fired because the operator set the clone's git identity *mid-run* — verified bare/origin/HEAD untouched |
| Live tier-2 run, real repo | `./validate.sh --subsystem swe-diagram` → green 2/2 in **1.5s** (registry resolution, 2-wide niced pool, identity bracket, honest summary) |
| Measured push-latency + CPU deltas (issue success criterion) | width change proven via `--print-mode` (4 vs 8 on a 10-core host); wall-clock/CPU measurements on real pushes still owed here |
