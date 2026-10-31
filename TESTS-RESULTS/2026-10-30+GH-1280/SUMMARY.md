# GH-1280 — outer-loop ATE campaign: summary

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1280 · Plan: `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md`
Reviews: plan QA `relay-system/2026-10-30/gh1280-plan-qa.md` (Escalated 3/3, operator proceeded),
contract QA `relay-system/2026-10-30/gh1280-long-contract-qa.md` (round 2 PASS), final QA
`relay-system/2026-10-30/gh1280-final-qa.md`.

## Verdict

**One new low-severity defect, nothing else.** 10,000 sandboxed `factory-primitive` invocations
produced zero supervisor candidates (no traceback, no unexpected exit code). Every gen4 anomaly is
an expected refusal. The one real defect (D1) was found in the smoke and reproduced in all 4 replays.
No host, git, ledger or canary change; no surviving process. Stop/go for a later stateful
campaign: **go, after two changes** (see the end).

## Budgets actually used

| Phase | Wall | Cases | Stop |
|---|---|---|---|
| Smoke (controls, Track B, Track A, replay) | 428 s of 1,800 s | 200 Track A + 17 B1 + B2 + B3 | mutation budget (200) |
| Contract-fix verification (v1–v5) | see `ev/09-verify.json` | 100 + 0 + ≤400 + slow-canary runs | per check |
| Long discovery | 4,496 s of 21,600 s | 10,000 in 200 batches of 50 (133.6/min) | mutation budget (10,000) |
| Postprocessing (Phase 3 replays) | under 10 min of 2 h | 28 R1 + 8 R2 + 1 R3 + 6 R3b + 3 D1 | — |

Launch 1793413513, discovery processes ended 1793418008 (17,105 s before the discovery deadline),
total deadline 1793442313. Times in `ev/timeline.txt`. The 6 h wall and the no-new-signal stop
were not reached; the 10,000 budget stopped first, as the contract predicted.

## Classification denominators (long run, cases per class per target)

| Target | usage | pass | run-root-guard | cap-guard | state-guard | sandbox-denied | input-error |
|---|---|---|---|---|---|---|---|
| fp-help (`--help`) | 2,062 | 438 | | | | | |
| fp-genman (`generate-manifest --output …`) | 2,270 | 225 | | | | 2 | 3 |
| fp-status (`--run-root … status`) | 2,270 | 59 | 171 | | | | |
| fp-init (`--run-root … init …`) | 2,347 | 51 | 63 | 21 | 18 | | |
| **Total (10,000)** | 8,949 | 773 | 234 | 21 | 18 | 2 | 3 |

Candidates: 0. gen4's own counts (pass 773, fail 8,949, anomaly 278) agree: its 278 anomalies are
exactly the 234 + 21 + 18 + 2 + 3 expected refusals.

## Dispositions

| ID | Signal | Disposition | Evidence |
|---|---|---|---|
| D1 | `status` on a never-initialized run root returns rc 0 and creates `instances/C/state.db`; a later `init` refuses ("instance already initialized", rc 2) and `tick` fails (rc 1) | **New defect, low severity** | `ev/06-candidate-status-creates-state.txt`, `ev/11-phase3.json` R2 |
| D2 | 41 gen4 contamination events, all fp-genman: untracked files such as `NaN`, `-1`, `" "` in the clone root | **Expected behaviour** (not a defect) | `runs/long/campaign-report.json`, `ev/11-phase3.json` R3 |
| D3 | gen4 cluster `c0cfa89b249b9917`, 234 members, "rc=2 with unclassified stderr" | **Expected refusal; gen4 oracle gap (faulty oracle)** | `ev/11-phase3.json` R4 |
| D4 | R1 replay mismatch, fp-genman seed 12994 idx 1 (recorded rc 2, replay rc 0) | **Expected refusal, state-dependent; replay setup fault** | `ev/12-phase3b.json` (a) |
| D5 | clean-control `tick` rc 1 under the sandbox profile | **Environment limit of the sandbox** (not a defect) | `ev/12-phase3b.json` (b) |
| D6 | supervisor novelty: 2,302 of 2,313 signatures are `usage` lines | **Faulty oracle (campaign tooling)** | `runs/long/supervisor-report.json` `signatures` |

**D1 — status creates state.** Target: `factory-primitive status`. Mutant argv:
`--run-root <fresh root> status`, then `init --daily-cap 1 --max-call-cost 0`, then `tick --slot 1`.
Violated invariant: a read-only status query must not create instance state; `init` must work on a
root nobody has initialized. Suspected root cause: `status()` opens the database through
`connect()`, which creates the file and schema (`utils/py/harness.py:1267`). Impact: low, the tool is
experimental and a new run root recovers. Owner: GH-1248 outer-loop code. Replay: the smoke
replay, two sandboxed replays and one unsandboxed replay (`ev/14-d1-unsandboxed.txt`) all give
status 0 → init 2; the database exists after status alone. Controls: clean root → `init` rc 0 in
every run; unsandboxed clean `init` → `tick` rc 0 (`ev/05-track-b.json` B2, `ev/12-phase3b.json` (b))
against status-first → `tick` rc 1 unsandboxed (`ev/14-d1-unsandboxed.txt`). Under the sandbox
`tick` fails even on a clean root (D5), so only the unsandboxed pair attributes the `tick` failure.
Existing issue: none found (search returned only the parent #1248). To be filed for normal triage
after this review; not fixed here.

**D2 — `generate-manifest --output` writes where it is told.** The fuzzer mutated the output path
into names like `NaN` and `2147483647`; the command wrote the manifest there, inside the disposable
clone, which the sandbox allows. Replay R3 (`--output NaN`) gives rc 0 and one untracked `NaN`. This
is an output flag honouring its argument, not a guard failure. The two `sandbox-denied` cases show
the outer sandbox refusing paths outside the clone. Owner: none. No issue.

**D3 — gen4 cannot read the harness's refusal text.** All 234 members carry
`factory-primitive: run root must stay under …`, the deliberate run-root guard (R4: 234 of 234
match). gen4 lists the cluster under its own `false_positives`. The supervisor's expected-refusal
table already classifies it. Not a harness defect; no issue.

**D4 — a flaky-looking replay, explained.** In the campaign, idx 0 (`--output temp`) wrote a *file*
named `temp`, so idx 1 (`--output temp/factory-primitive/…`) failed with `[Errno 20] Not a
directory` — the expected `input-error` refusal. Phase 3's reset left an ignored `temp/` directory
behind, so the first replay passed. Replayed from gen4's reset state (`git clean -fdxq`), it gives
exactly rc 2 with the recorded message. Not flaky; my replay reset was wrong.

**D5 — `tick` under the sandbox.** The same clean `init` → `tick` gives rc 0 unsandboxed and rc 1
(`{"status":"failed"}`) under `profile-long.sb`. `tick` was excluded from fuzzing by design, so this
changes no result; it limits any future sandboxed stateful campaign (see below).

**D6 — the no-new-signal stop could never fire.** Argparse usage errors echo the mutated tokens in
their last line, so almost every usage case looked new (streak at stop: 4). The stop came from the
budget, which is why the run stayed bounded. Campaign-tooling fix for next time: give `usage` cases
a signature based on the argparse error kind only.

## Coverage, honestly

- **Exercised:** argument parsing and the guards on `--help`, `generate-manifest --output`,
  `status` and `init` (run-root, cap, state, input errors), under an OS sandbox; 773 cases reached
  real command bodies (pass). Stateful behaviour only through the fixed Track B controls (17
  checkpoint2 replays, repeated tick, crash-act recovery), all passing.
- **Excluded by design:** `tick`, `packet`, `tool`, `init --from-prs`; fuzzed state sequences.
- **Weakness:** 89% of cases were usage refusals; the mutator rarely gets past argparse.
- **Held tracks:** none held; Track B was not repeated in the long run (no discovery component).

## Deviations

Smoke deviations 1–5 and the contract-review fixes are in `relay-system/2026-10-30/gh1280-long-contract-qa.md`.
Since then:

1. **Long-run corpus deleted by my replay reset.** `phase3.py` ran `git clean -fdq` in the long clone,
   which removed gen4's untracked `.fuzz_corpus/` before it was copied. The complete telemetry is
   kept (`runs/long/telemetry.jsonl.gz`, sha256 of the uncompressed file in `provenance.jsonl`) and
   records every corpus decision; `ev/13-corpus-long-from-telemetry.jsonl` lists the 1,736 admissions
   (it is not the final membership, because 874 admissions evicted an older entry).
2. **D4 replay setup fault**, above.
3. **`controls.py` is historical:** it writes the smoke-era flat baseline format; the long run used
   the watcher's `{discovery_deadline, total_deadline, canaries}` baseline.

## Stop/go for a later stateful campaign

**Go, after two changes:** (1) fix D6 so the no-new-signal stop can work; (2) solve D5 first —
find what `tick` needs that the profile denies — or `tick` cannot be fuzzed inside the sandbox. A
stateful campaign should then fuzz operation sequences (`init`/`tick`/`status`/`packet`) on one run
root per batch, with the Track B predicates as oracles.
