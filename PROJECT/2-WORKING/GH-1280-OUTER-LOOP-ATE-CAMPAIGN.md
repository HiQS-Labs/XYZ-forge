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
| Intake parked (`rmi-01M67SH0DNCK9GA383FQNXZDHW`, `rated 55/40/50/35`); recon of the target CLI and the ATE/Gen 4 tools; this plan | Codex plan review, then Phase 1 smoke |

The issue body is the experiment contract. This document is the execution record; it does
not restate the issue's bounds except where recon changes how they are enforced.

## Pinned identity

- Source: `HiQS-Labs/XYZ-forge` `development` @ `6147b988ac902f0f54d990256c876c474f68f760`
  (task clone base). The campaign runs against the committed task-branch HEAD, whose only
  delta from that SHA is this doc and the ledger row (no code change).
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
- **Built:** nothing in production code. Campaign inputs (target list, environment, bounds)
  and a short supervisor shell loop live in the session scratchpad; the copies that evidence
  needs are committed under `TESTS-RESULTS/2026-10-30+GH-1280/` after the campaign.
- **Not built:** a state-machine adapter, a gen4 no-new-signal feature, a classifier, a new
  suite or registry entry, any fix.
- **Alternative rejected:** running `gen4_campaign.py` with its nine defaults — they do not
  include `factory-primitive`, so it would exercise zero relevant cases.
- **Rollback / containment:** all writes land in disposable clones under `$TMPDIR` and the
  `temp/factory-primitive/` run roots of those clones; the PR adds only evidence and this
  doc. Revert = close the PR and trash the clones.

## Containment

- Gen 4 runs with `--repo <task clone>` and `--sandbox-root $TMPDIR/gh1280-sb-<phase>`, so
  every mutant's cwd is a disposable clone of the task clone, never the task clone itself.
- Sanitized target environment: `PATH=/usr/bin:/bin`, the absolute interpreter path
  `/opt/homebrew/bin/python3` in the target, `HOME=$TMPDIR/gh1280-home`, no
  `GH_TOKEN`/`GITHUB_TOKEN`/model keys. With `gh` and `node` absent from `PATH`, a mutant that
  synthesizes `--from-prs` or `packet` fails closed instead of reaching the network.
- Base argv never includes `--from-prs`, `packet` or `tool`.
- Hard wall cap: `proc_group.run_bounded` wraps the whole gen4 invocation (own process group,
  killed with descendants on timeout). After each run, `pgrep -f gh1280-sb` must be empty.
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

### Phase 1 — Smoke (≤20 min discovery + ≤10 min replay/cleanup)

1. **Pin and inspect.** Verify task-clone identity (origin, `core.bare=false`, HEAD), Python,
   `sandbox-exec`; `pgrep` shows no `harness.py factory-primitive` or `gen4_campaign`
   processes; take the identity canaries. → no peer or primary state involved.
2. **Freeze the smoke contract** to `$SCRATCH/smoke/contract.json`: targets, env, seeds,
   bounds, expected-refusal table hash, stop conditions.
3. **Controls.** In a disposable clone (`$TMPDIR/gh1280-ctl`, full clone of the task clone):
   - known-good: `init --daily-cap 1 --max-call-cost 0` then `tick --slot 1` → rc 0;
   - known-invalid: `--run-root ../outside status` → rc 2 run-root refusal;
   - negative control (witnessed red): `domain_oracles.py --mode idempotence` on a command
     that appends to a receipt file must FAIL, then the same oracle on a repeated completed
     `tick --slot 1` must PASS;
   - containment negative control: `--mode containment` on a command that touches the
     host canary must FAIL, then on `status` must PASS.
4. **Track A** — `gen4_campaign.py --mode run --no-synth --targets smoke-targets.json
   --max-mutations 200 --batch 25 --corpus-cap 100 --seed 1280 --duration 1200 --keep-sandbox`
   under a `run_bounded` hard cap of 1,500 s. Targets (each `timeout: 30`):
   `fp-help` (`--help`), `fp-genman` (`generate-manifest --output
   temp/factory-primitive/ate-smoke/manifest.json`), `fp-status`
   (`--run-root temp/factory-primitive/fz status`), `fp-init`
   (`--run-root temp/factory-primitive/fz init --daily-cap 1 --max-call-cost 0`).
   `tick` stays out of Track A: within a batch there is no initialized instance, and seeding
   one would need a new wrapper. → telemetry nonempty; per-target invocation count > 0
   (zero for any target fails the smoke).
5. **Track B** — stateful checks only where an existing command and predicate express them,
   each in its own fresh run root inside `$TMPDIR/gh1280-ctl`:
   - B1: re-run the 17 GH-1248 checkpoint2 control cases with their recorded commands and
     compare final `status` and exit codes to the recorded `detail`/log;
   - B2: idempotence — after one completed `tick --slot 1`, `domain_oracles.py --mode
     idempotence --repetitions 3` on the same tick; also assert the `receipts`/`decisions`
     row counts in `state.db` are unchanged;
   - B3: crash — `tick --slot 1 --fault crash-act` → rc 70, then `status` shows the
     classified `uncertain` state with no retry, then `pgrep -f gh1280-ctl` is empty.
   The GH-1248 tool sandbox profile is the reset boundary for writes; a fresh run root per
   case is the fixture reset. If any of B1–B3 cannot show reset, predicate, replay and
   cleanup, Track B is **held** and reported as such.
6. **Classify and replay** every Track A candidate: dedupe by target + violated invariant;
   replay with `fuzz_engine.py --mode replay` in the kept sandbox; then a semantic re-check
   (the same argv run once in a fresh clone, with the outcome compared against the
   expected-refusal table and a `git status --porcelain` / out-of-`temp/` file check). A
   clean control (the base argv) and the failing mutant are recorded side by side.
7. **Cleanup and canaries.** Identity canaries unchanged; no surviving process; sandbox and
   control clones trashed after evidence is copied out.

Smoke passes only if: controls behave as stated (including both witnessed reds), every
Track A target has >0 invocations, telemetry is valid, canaries are unchanged and no process
survives. Zero defects is acceptable; zero relevant cases is a fail.

### Phase 2 — Contract review and long window

8. **Freeze the long-run contract** from the smoke result: only the tracks that passed;
   targets, env and seeds fixed; bounds ≤ 6 h discovery, 10,000 mutations, 50 per batch,
   30 s per command, corpus 500; postprocessing ≤ 2 h; external hard cap 8 h.
9. **Codex review** (`relay-xyz`, review-only, `ALLOW_PATHS=""`, after `find-harness.sh
   --check`) of the frozen contract and smoke evidence, bound to their sha256. No long window
   without an Approved verdict; if review cannot run, record **Independent review did not
   run** and stop.
10. **Run** in segments, because gen4 has no no-new-signal stop: each segment is one gen4
    invocation of 500 mutations (10 batches of 50) with seed `1280 + 1000·k`, a fresh
    sandbox, and the same targets. Between segments the supervisor loop checks: elapsed
    discovery < 6 h, total mutations < 10,000, canaries unchanged, no surviving process,
    telemetry valid, and whether the segment produced any signature not already in the
    expected-refusal table or a prior segment. A segment with no new signature (500 cases)
    stops discovery — this is the issue's "500 cases with no new signature" limit; the
    3-batch variant is not separately enforceable without changing gen4 and is recorded as a
    limit. Any safety stop condition ends the run immediately.

### Phase 3 — Disposition, review, evidence

11. **Replay and classify** every candidate as new defect / known rediscovery / expected
    refusal / flaky-inconclusive / faulty oracle, with clean and failing controls.
12. **Codex review** (`relay-xyz`) of dispositions and the report, bound to hashes.
13. **Evidence** under `TESTS-RESULTS/2026-10-30+GH-1280/`: contracts, target lists,
    telemetry, campaign reports, control outputs, replay outputs, canary diffs, review
    receipts, `SUMMARY.md`, `provenance.jsonl`. Commit after the campaign ends, push, open a
    PR against `development`. A new defect is reported to the operator for normal issue-first
    triage; nothing is filed automatically and nothing is fixed.

## Verification route

Changed paths are this doc, the ledger row and `TESTS-RESULTS/**` evidence. The gate is the
one `utils/ci-route.sh` selects for those paths (expected: documentation route,
`utils/pdda/pdda.sh run`). No new tests (GH-831).

## Risks

- **Candidate flood** from keyword-less refusals → handled by the expected-refusal table;
  each table row is verified against source before use.
- **Duration overshoot** because gen4 checks time between batches → external `run_bounded`
  cap and 30 s per-mutant timeouts bound one batch to ~25 min worst case at 50 × 30 s.
- **Mutant reaches network** → `gh`/`node` absent from `PATH`; `HOME` sandboxed.
- **Tracked-file overwrite** by `generate-manifest` without `--output` → inside the
  disposable gen4 clone only; recorded by gen4's contamination check and treated as a
  candidate for disposition (likely "known behaviour": unguarded output path).
