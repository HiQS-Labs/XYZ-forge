---
gh_issue: 1280
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1280
title: "ATE/fuzz the GH-1248 outer loop: smoke-first Mac Studio campaign"
status: Active
created: 2026-10-30
updated: 2026-10-30
owner: claude
doc_type: plan
complexity: 3
risk: 2
effort: 3
phases: 3
branch: chore/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30
non_goals:
  - no production-code repair during the campaign
  - no new state adapter, suite, CI case or registry entry (GH-831)
  - no synthesis, healing, model-per-mutant or automatic issue filing
related:
  - "#1248"
  - "#1279"
  - "#299"
  - "#298"
goal: >
  A bounded smoke proves the existing ATE/Gen 4 tools actually invoke the GH-1248
  `factory-primitive` outer loop with working oracles, reset and cleanup; only then a
  frozen, Codex-reviewed campaign of at most eight hours runs, and every candidate gets a
  semantic replay and an accountable disposition, with evidence under
  `TESTS-RESULTS/2026-10-30+GH-1280/`.
---

# GH-1280 — ATE/fuzz the GH-1248 outer loop

## Status

| What was just completed | What's next |
|---|---|
| Plan QA rounds 1–3 (Codex FAIL each round; F1–F13, relay Escalated at the 3-round cap) — all findings implemented in this revision | Operator decision on the escalated plan review, then Phase 1 smoke |

The issue body is the experiment contract. This document is the execution record; it does
not restate the issue's bounds except where recon changes how they are enforced.

## Pinned identity

- Source: `HiQS-Labs/XYZ-forge` `development` @ `6147b988ac902f0f54d990256c876c474f68f760`
  (task clone base). The campaign runs against the committed task-branch HEAD, whose only
  delta from that SHA is this doc, the ledger row, the plan-QA relay thread and the evidence
  copy of the campaign supervisor (no production code change).
- Host: Mac Studio (`Mac13,1`), Python 3.14.7, `/usr/bin/sandbox-exec` present.
- Task clone: `XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30` (sibling of the primary).
  The primary checkout is never a cwd for any campaign command.

## Recon findings that shape the plan

Target CLI (`utils/py/harness.py`, `factory-primitive` parser at `:1311-1347`):

- Every target template fixes `factory-primitive` in the head, so a mutant can never reach the
  registry alias half of `harness.py`, `validate.sh` or `ci-local.sh`.
- `--run-root` is guarded under `temp/factory-primitive/` (`_run_root`, `:1302-1308`).
  `generate-manifest --output` and `tool --out-dir` are **not** guarded; dropping `--output`
  overwrites the tracked `scenarios/soak-v1.manifest.json` (`:784`, `:1329`).
- External reach: `init --from-prs` calls `gh` over the network and copies `releases.db`
  (`:639-705`); `packet` runs `node bin/marathon-yaml` (`:1052`); `tick` spawns one
  `sandbox-exec` child under `proc_group.run_bounded` (`:1078-1096`). The adapter is
  rules-only; no model CLI is reachable.
- Refusals: `ValueError`/`OSError`/`JSONDecodeError` → exit 2 with
  `factory-primitive: <msg>`; argparse → exit 2 usage; crash faults `os._exit(70)`; `tick`
  exit 1 for failed/skipped-busy.

Gen 4 tools:

- `gen4_campaign.py --mode run --no-synth --targets FILE` clones committed HEAD into a
  disposable sandbox (`:84-98`), runs every target with cwd = that clone, and after each
  batch `git reset --hard` + `git clean -fdxq` (wipes `temp/`). It records, but does not
  abort on, host-identity violations. It has **no no-new-signal stop** and checks
  `--duration` only between batches.
- `adaptive_ate.py` classification: a refusal is "handled" only if stderr matches a
  `usage`/`missing_file` keyword. Most `factory-primitive:` refusals carry no keyword, so
  they will surface as anomaly candidates; disposition is done by hand against the
  expected-refusal list below, not by trusting the tool's label.
- Replay (`fuzz_engine.py --mode replay`) matches `rc + signal + stderr digest`. Per the
  defect-campaign skill, that alone is `confounded`; each candidate also gets a semantic
  re-check (below).
- `repro_builder.minimize_argv` weakens the predicate to rc (+substring). Minimization is
  therefore skipped; unminimized observations are retained.
- `domain_oracles.py` offers idempotence, containment, zero-state and crash-recovery checks
  (CLI `:571-586`).
- GH-1248 `TESTS-RESULTS/2026-10-28+GH-1248/controls-checkpoint2.jsonl`: 17 fault controls,
  each a fresh run root with exact commands and an expected `detail`. These are the
  stateful semantic oracles reused here.

## Smallest viable bet

- **Outcome sought:** evidence of whether the outer loop has replayable robustness defects
  that the 17 recorded controls missed, on a stated surface, with containment proven.
- **Built:** nothing in production code. Campaign inputs (target list, sandbox profile,
  environment, bounds) and a ~260-line Python campaign supervisor live in the session scratchpad;
  the supervisor's evidence copy is `TESTS-RESULTS/2026-10-30+GH-1280/tools/supervisor.py`, and
  the rest is committed there after the campaign. The supervisor carries a small temporary
  stderr classification (`EXPECTED`/`classify`) used only to decide the no-new-signal stop and
  to pre-sort candidates for the manual disposition in step 11; it is not a defect verdict.
- **Not built:** a state-machine adapter, a production gen4 no-new-signal feature, a new suite
  or registry entry, any fix.
- **Alternative rejected:** running `gen4_campaign.py` with its nine defaults — they do not
  include `factory-primitive`, so it would exercise zero relevant cases.
- **Rollback / containment:** all writes land in disposable clones under `$TMPDIR` and the
  `temp/factory-primitive/` run roots of those clones; the PR adds only evidence and this
  doc. Revert = close the PR and trash the clones.

## Containment

- Gen 4 runs with `--repo <task clone>` and `--sandbox-root $TMPDIR/gh1280-sb-<phase>`, so
  every mutant's cwd is a disposable clone of the task clone, never the task clone itself.
- **OS sandbox around every mutant (review F1).** Each Track A target is
  `/usr/bin/sandbox-exec -f <profile> /opt/homebrew/bin/python3 utils/py/harness.py
  factory-primitive {mutant}`. The profile (the same `sandbox-exec` mechanism `harness.py`
  already uses for its tool child, `:1085-1096`) is `(allow default)` plus
  `(deny network*)` and `(deny file-write*)` except `(subpath "<gen4 sandbox root>")` and
  `/dev`. A mutant such as `generate-manifest --output ../../etc/passwd` is therefore denied
  by the kernel before any write outside the disposable clone. Track A excludes `tick`, so the
  nested-sandbox case never arises; Track B commands are fixed (not mutated) and run unwrapped
  inside their own disposable clone.
- Sanitized environment: gen4 is launched under `env -i` with only `PATH=/usr/bin:/bin`,
  `HOME=<sandbox root>/home`, `TMPDIR=<sandbox root>/tmp`, `PYTHONDONTWRITEBYTECODE=1` and
  `LANG=C.UTF-8`. No `GH_TOKEN`/`GITHUB_TOKEN`/model keys are inherited; `gh` and `node` are not
  on `PATH`, so a mutant that reaches `--from-prs` or `packet` fails closed.
- Base argv never includes `--from-prs`, `packet` or `tool`.
- **Independent supervisor (review F2, F3, F8).** One short Python script in the scratchpad
  (a copy is committed with the evidence; it is not a suite, repo gate or adapter) has two
  modes:
  - **Launch gate (exact boundary).** Every Track A target is
    `sandbox-exec -f <profile> python3 supervisor.py --gate <contract> -- utils/py/harness.py
    factory-primitive {mutant}`. `fuzz_engine.fuzz` appends case N-1's telemetry before it
    launches case N (`fuzz_engine.py:290-315`), so the gate, reading the whole telemetry file
    first, sees every prior case. It refuses the launch (rc 125, `gh1280-gate: stopped`, the
    harness never runs) when the no-new-signal limit or mutation budget is reached, or when a
    read-only canary has moved since the recorded baseline; it writes the reason to a stop file
    inside the sandbox root. Otherwise it `execv`s the harness in the same process. A gated
    event is excluded from every count.
  - **Watcher.** Launches gen4 in its own process group and polls every 1 s for the stop file,
    the discovery wall and gen4 exit; canaries every 5 s. On stop it sends SIGTERM then
    SIGKILL to the gen4 group, then kills every process whose argv contains
    `harness.py factory-primitive` or the profile path (each mutant runs in its own session via
    `run_bounded`, so a group kill alone is not enough), and records the PIDs. Before launch it
    asserts that no such process exists on the host.
  - **Latency, stated.** The no-new-signal, budget and canary stops are exact at the launch
    boundary. The discovery wall and a canary change that happens *during* a running mutant
    are detected within 1 s / 5 s; the mutant then in flight is killed, bounded by its 30 s
    timeout. Termination grace (10 s + sweep) is reserved inside each hard wall.
- Identity canaries recorded before and after each phase: for the primary checkout and the
  task clone, `git rev-parse HEAD`, `git status --porcelain | shasum`, `git config --list
  --local | shasum`, `core.bare`, remotes; plus `shasum releases.db` in the primary and a
  canary file under `$TMPDIR/gh1280-canary/`.
- Temporary sleep prevention for the long window only: `caffeinate -i -w <supervisor pid>`.

## Expected refusals (classified, not defects)

| Signature | Meaning |
|---|---|
| rc 2, argparse `usage:` / `error:` on stderr | unknown flag, missing value, bad choice |
| rc 2, `factory-primitive: run root must stay under …` | run-root guard |
| rc 2, `factory-primitive: instance must be a simple name…` | instance guard |
| rc 2, `factory-primitive: slot must be in 1..288` | slot guard |
| rc 2, `factory-primitive: instance already initialized…` / not initialized | state guard |
| rc 2, `factory-primitive: invalid daily cap…` / cost cap messages | cap guard |
| rc 2, `factory-primitive: <OSError/JSON message>` naming a mutated path | missing/bad input file |
| rc 1, empty stderr, `tick` | failed / skipped-busy tick |
| rc 0 on `--help`-shaped mutants | help printed |

Anything else — a Python traceback, rc not in {0,1,2,70}, a signal, a timeout, an rc 0 that
produced a file outside the clone's `temp/`, or a write to a tracked file — is a candidate.
Before Phase 1 runs, each listed message is confirmed verbatim against `harness.py`.


## Ordered plan

### Phase 1 — Smoke (≤20 min discovery + ≤10 min replay/cleanup, all tracks together)

**One smoke clock (review F9).** A monotonic discovery deadline `D = T0 + 1,200 s` is set
immediately before step 3, and the whole smoke must finish by `T0 + 1,800 s`. Order: step 3 (controls), step 5
(Track B), then step 4 (Track A); each receives only `D − now`, Track A's watcher
wall is `D − now` at its launch, and anything still pending at `D` is held, not extended. The
200-mutation cap is cumulative. Replay and cleanup (steps 6–7) use the remaining time to
`T0 + 1,800 s`. The recorded timeline (start/end of each step) is part of the evidence.

1. **Pin and inspect.** Verify task-clone identity (origin, `core.bare=false`, HEAD), Python,
   `sandbox-exec`; no `harness.py factory-primitive` or `gen4_campaign` process exists on the
   host; take the identity canaries. → no peer or primary state involved.
2. **Freeze the smoke contract** to `smoke/contract.json` (scratchpad, later committed): targets,
   sandbox profile, env, seeds, bounds, expected-refusal patterns, stop conditions, and their
   sha256.
3. **Controls** in a disposable full clone of the task clone (`<ctl clone>`):
   - known-good: `init --daily-cap 1 --max-call-cost 0` then `tick --slot 1` → rc 0;
   - known-invalid: `--run-root ../outside status` → rc 2 run-root refusal;
   - idempotence negative control (witnessed red): `domain_oracles.py --mode idempotence` on a
     command that appends to a receipt file must FAIL, then the same oracle on a repeated
     completed `tick --slot 1` must PASS;
   - sandbox negative control (witnessed red): the Track A wrapper running
     `generate-manifest --output <outside path>` must be denied and the outside path must not
     exist afterwards, while `--output temp/factory-primitive/ate-smoke/manifest.json` succeeds;
   - supervisor negative controls, using the real watcher and gate against the real target in
     a throwaway sandbox (not a file replay): (a) a run whose base argv is a guaranteed
     expected refusal (`--run-root ../outside status`) must launch exactly 51 harness
     invocations — 1 new signature plus 50 already-seen — and the next case must be gated
     (rc 125);
     (b) touching the canary file mid-run must make the next launch gated and the watcher stop
     with `CANARY VIOLATION`; (c) after each, the sweep finds no surviving process.
4. **Track A** — the supervisor launches `gen4_campaign.py --mode run --no-synth --targets
   smoke-targets.json --max-mutations 200 --batch 25 --corpus-cap 100 --seed 1280
   --duration <D − now> --keep-sandbox --sandbox-root <sb>` with discovery hard-stopped by the
   watcher at `D`. Targets (each `timeout: 30`, all sandbox-wrapped and gated):
   `fp-help` (`--help`), `fp-genman` (`generate-manifest --output
   temp/factory-primitive/ate-smoke/manifest.json`), `fp-status`
   (`--run-root temp/factory-primitive/fz status`), `fp-init`
   (`--run-root temp/factory-primitive/fz init --daily-cap 1 --max-call-cost 0`).
   `tick` stays out of Track A: within a batch there is no initialized instance, and seeding
   one would need a new wrapper. Track A state is reset per batch, not per case, so `init`
   observations are not labelled independent per-case fixtures.
   Stop when, across all targets in telemetry order, 50 consecutive cases produce only
   signatures already seen and matching the expected-refusal table.
   → telemetry nonempty; per-target invocation count > 0 (zero for any target fails the smoke).
5. **Track B** — stateful checks only where an existing command and predicate express them,
   each in its own fresh run root inside `<ctl clone>`:
   - B1: re-run the 17 GH-1248 checkpoint2 control cases. The recorded command strings are
     **not** executed verbatim (review F4): the interpreter is replaced by the pinned
     `/opt/homebrew/bin/python3`, the historical run root by
     `temp/factory-primitive/gh1280/b1/<case>`, and the absolute `state.db` argument of the
     two SQL controls (`missing-decision`, `missing-snapshot`) by the new case's
     `instances/C/state.db`. Each adapted argv is recorded, and every mutable path is resolved
     and asserted to lie inside `<ctl clone>/temp/factory-primitive/` before it runs; a case
     that cannot be relocated is held. Each case's exit codes and final `status` are compared
     against its recorded log;
   - B2: idempotence — after one completed `tick --slot 1`, `domain_oracles.py --mode
     idempotence --repetitions 3` on the same tick; also assert the `receipts`/`decisions`
     row counts in `state.db` are unchanged;
   - B3: crash (review F5) — `init`, `tick --slot 1 --fault crash-act` → rc 70, then the
     recovery `tick --slot 2`, then `status`. Predicate (review F10): slot 1 is reconciled
     `uncertain` and its item quarantined; the crashed intent has **zero** tool executions and
     zero tool output both before and after recovery (`crash-act` exits at `harness.py:1207`,
     before `_run_tool` at `:1210`; `tool_started_at` metadata alone is not an execution);
     legitimate slot-2 work for a different intent is allowed; no process matching the case's
     run root survives.
   A fresh run root per case is the fixture reset; the clone is discarded afterwards. If any
   of B1–B3 cannot show reset, predicate, replay and cleanup, that check is **held** and
   reported as such.
6. **Classify and replay** every Track A candidate: dedupe by target + violated invariant +
   suspected root cause; replay with `fuzz_engine.py --mode replay` in the kept sandbox; then
   a semantic re-check (the same argv run once in a fresh clone under the same OS sandbox, with
   the outcome compared against the expected-refusal table plus a `git status --porcelain` and
   outside-`temp/` file check). A clean control (the base argv) and the failing mutant are
   recorded side by side. No minimization (it weakens the predicate).
   **Replay has its own contract (review F12):** replay targets use the same sandbox profile
   and gate but a separate `replay-contract.json` (own stop file, no discovery telemetry,
   canary check kept), so an exhausted discovery run never blocks a replay, while a further
   discovery launch stays refused. Gen 4's automatic post-discovery replay
   (`gen4_campaign.py:203-219`) is deliberately suppressed, because the watcher stops gen4 as
   soon as discovery stops; replays are run by hand within the replay reserve, at most one per
   deduplicated candidate plus its clean control, each with the 30 s timeout. A witnessed
   control shows one replay reaching the harness after a discovery stop.
7. **Cleanup and canaries.** Identity canaries unchanged; process sweep empty; sandbox and
   control clones trashed after evidence is copied out.

Smoke passes only if: controls behave as stated (including every witnessed red), every
Track A target has >0 invocations, telemetry is valid, canaries are unchanged and no process
survives. Zero defects is acceptable; zero relevant cases is a fail.

### Phase 2 — Contract review and long window

8. **Freeze the long-run contract** from the smoke result: only the tracks that passed;
   targets, profile, env and seeds fixed; bounds ≤ 6 h discovery, 10,000 mutations, 50 per
   batch, 30 s per command, corpus 500; postprocessing ≤ 2 h; supervisor hard cap 8 h total.
9. **Codex review** (`relay-xyz`, review-only, `ALLOW_PATHS=""`, after `find-harness.sh
   --check`) of the frozen contract and smoke evidence, bound to their sha256. No long window
   without an Approved verdict; if review cannot run, record **Independent review did not
   run** and stop.
10. **Run** one gen4 invocation under the same watcher and launch gate (review F3, F8). The
    gate enforces exactly, before each launch: 3 consecutive batches (a batch = one gen4 round:
    one target, one seed) **or** 500 consecutive cases with no new signature beyond expected
    refusals, whichever comes first; 10,000 mutations; any canary change. The watcher enforces
    the 6 h discovery wall (≤1 s latency) and the 8 h total cap, and stops on invalid telemetry,
    a missing dependency or a surviving process after a sweep. Changing any frozen value starts
    a new run.

### Phase 3 — Disposition, review, evidence

11. **Replay and classify** every candidate as new defect / known rediscovery / expected
    refusal / flaky-inconclusive / faulty oracle, with clean and failing controls. Each
    candidate row records (review F6): target, mutant argv, violated invariant, suspected root
    cause, severity/impact, owner (the GH-1248 outer-loop code), evidence paths, replay result
    and controls, and any existing issue it rediscovers.
12. **Codex review** (`relay-xyz`) of dispositions and the report, bound to hashes.
13. **Evidence** under `TESTS-RESULTS/2026-10-30+GH-1280/`: contracts, profile, target lists,
    supervisor copy, telemetry, campaign reports, control outputs, replay outputs, canary
    diffs, review receipts, `SUMMARY.md`, `provenance.jsonl`. `SUMMARY.md` states exercised and
    excluded coverage, actual budgets used (time, mutations, batches), classification
    denominators (cases per class per target), held tracks, and a stop/go recommendation for a
    later stateful campaign. Commit after the campaign ends, push, open a PR against
    `development`. A new defect is reported to the operator for normal issue-first triage;
    nothing is filed automatically and nothing is fixed.

## Acceptance criteria (from the issue)

- Exact source, target, fixture, seed/corpus, environment and driver identities recorded;
  telemetry proves relevant outer-loop invocations.
- Smoke controls, including a witnessed negative control and cleanup, passed before the long
  window; the `relay-xyz` Codex contract review is recorded.
- Discovery stayed within all bounds and stopped at the no-new-signal limit or earlier.
- Host/git/ledger identity and canaries unchanged; no unauthorized write or surviving
  descendant process.
- Expected refusals separated from candidate defects; every candidate has a semantic replay
  and an accountable disposition with clean/failing controls.
- Stateful coverage claimed only where reset, operation sequence and semantic predicate were
  actually exercised.
- No synthesis, healing, model-per-mutant, automatic filing, production execution, commit or
  push during the campaign.
- Report includes exercised/excluded coverage and actual budgets; every cited result has
  committed `provenance.jsonl`.

## Rating rationale (2026-10-30)

`rated 55/40/50/35`. Severity 40: no defect has been observed; the campaign looks for latent
robustness defects in a new, not-yet-production outer loop, so the consequence is bounded.
Priority 55: the operator asked for it now and it gates trust in #1248 before wider use.
Appeal 50: neutral, no operator score given. Effort 35: a multi-hour supervised campaign with
two Codex reviews and an evidence package, but no production code. Recurrence: not applicable
(an experiment, not an incident report); trend unknown.

## Plan QA dispositions (relay `relay-system/2026-10-30/gh1280-plan-qa.md`)

| Finding | Disposition |
|---|---|
| F1 outer write containment | Implemented — `sandbox-exec` profile wraps every Track A mutant; witnessed-red control |
| F2 descendant kill | Implemented — supervisor sweeps by argv pattern after asserting none pre-exist |
| F3 no-new-signal limits | Implemented — supervisor enforces 50-case smoke streak and 3-batch / 500-case long limits from live telemetry |
| F4 historical SQL paths | Implemented — adapted argv, resolved-path assertion, hold on failure |
| F5 B3 recovery | Implemented — recovery `tick --slot 2` and explicit predicate |
| F6 report fields | Implemented — candidate row fields and SUMMARY contents named |
| F7 rating rationale | Implemented — section restored |
| F8 stop boundary | Implemented — launch gate inside each mutant decides before case N runs; watcher latency stated |
| F9 one smoke clock | Implemented — shared deadline `D` set before controls; each step gets `D − now` |
| F10 B3 zero executions | Implemented — crashed intent must have zero tool executions/output |
| F11 tracker boundary | Implemented — batch closes at its own last case (frozen batch size); novelty = first occurrence of a signature only; the reviewer's probe now stops before event 201 |
| F12 replay blocked | Implemented — separate replay contract; gen4 auto-replay suppressed; witnessed post-stop replay control |
| F13 stale descriptions | Implemented — inventory and classifier description refreshed; canary commands now carry a 10 s timeout |

## Verification route

Changed paths are this doc, the ledger row, the relay thread and `TESTS-RESULTS/**` evidence.
The gate is the one `utils/ci-route.sh` selects for those paths (expected: documentation
route, `utils/pdda/pdda.sh run`). No new tests (GH-831).

## Risks

- **Candidate flood** from keyword-less refusals → handled by the expected-refusal table;
  each table row is verified against source before use.
- **Duration overshoot** because gen4 checks time between batches → the supervisor stops on
  wall time, not gen4.
- **Mutant reaches network or writes outside** → `sandbox-exec` denies both; `gh`/`node`
  absent from `PATH`.
- **Tracked-file overwrite** by `generate-manifest` without `--output` → inside the
  disposable gen4 clone only; recorded by gen4's contamination check and treated as a
  candidate for disposition.
