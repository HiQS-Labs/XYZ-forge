# GH-1280 — long-run contract review packet

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1280 · Plan: `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md`
(task branch `chore/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30` @ `623ba2c7`). Plan QA relay:
`relay-system/2026-10-30/gh1280-plan-qa.md` (Escalated at 3/3; operator chose to proceed to the smoke with F11–F13
implemented, and this review is the gate before the long window).

## Smoke verdict (producer's reading — for you to check)

**Smoke PASS, with deviations below.** Clock: T0 1793412427, discovery deadline D = T0+1200, end T0+1800; actual
smoke 428 s (controls 32 s → Track B → Track A 82 s → replay/cleanup). All controls passed, including witnessed reds
for the idempotence oracle, the OS sandbox, the launch gate (exact streak boundary) and the canary stop. Track B
17/17 B1, B2 and B3 passed. Track A ran 200 real `factory-primitive` invocations, 50 per target, under the OS
sandbox; no host violation, canaries unchanged, no surviving process.

## Deviations and corrections during the smoke (all recorded, none hidden)

1. **Gate-boundary control used a stub target.** To get an exact count (one signature only), control (e) ran the
   real watcher and gate against `stub.py` (identical refusal every case) rather than the harness. Result: 51 executed,
   event 52 gated, no survivors. The real harness ran behind the same gate in Track A, where the stop came from the
   mutation budget (also enforced by the gate: the 201st launch is refused — see the replay control text).
2. **Control-checker bug.** First controls run marked (e) FAIL only because the check required the stop reason to
   start with `gate:`; the watcher's own tracker reached the same decision first and logged it without the prefix.
   The behaviour was correct (51/52). Check relaxed, all controls re-run from scratch: 6/6 PASS.
3. **Two faulty Track B comparators.** Run 1: exact `status` equality failed in 16/17 cases because GH-1257 later
   added `heartbeat`, `last_receipt`, `lock`, `quarantined_ids`; every recorded key matched. Run 2: `budget-cap`
   differed only by the wall-clock `ts` inside a stored event. Comparator now checks recorded status keys and drops
   `ts`; both earlier runs are retained as `05-track-b.run1-faulty-status-oracle.json` and
   `05-track-b.run2-faulty-ts-oracle.json`. Run 3: 17/17.
4. **Supervisor cleanup crash on the Track A run.** gen4 exited by itself at the 200 budget; the watcher's
   `os.killpg` then raised `PermissionError` (macOS refuses killpg once the group leader has exited), so the watcher
   wrote no report and did not run its sweep. Manual checks immediately afterwards: no campaign process, canaries
   unchanged (`07-final-checks.txt`). The report was rebuilt from the complete telemetry with the same tracker. Fix:
   catch `PermissionError` (diff vs the committed copy is only this and richer `--replay-telemetry` output). **The
   watcher's own sweep therefore has been witnessed on the stub runs only, not on a real-harness run.**
5. **Stop limit not exercised on the real target.** The 50-case streak never triggered in Track A (streak at end: 2);
   the budget stop came first.


## Round 1 findings — fixes and evidence (round 2 packet)

- **F1 (Blocker) — corrected cleanup path now exercised on the real harness.** `09-verify.json` check F1: a 100-case
  real run where the watcher's budget stop ended gen4 (report written, no survivors, canaries unchanged).
  `09-verify-v5-stdout.json`: the exact smoke crash path — contract budget raised so **gen4 exits by itself**
  (`gen4 exited rc=0`, gen4_rc 0) — and the corrected watcher wrote its own report and swept: 100 events, no
  survivors, canaries unchanged. The smoke crash and its reconstructed report stay as historical evidence.
- **F2 — one total deadline, owned mechanically.** At launch the watcher writes `discovery_deadline = L + wall_s`
  and `total_deadline = L + total_s` into the baseline file. Frozen: `wall_s` 21600, `total_s` 28800, `reserve_s`
  120. The discovery gate refuses every launch at `discovery_deadline − reserve_s` (exact); the watcher stops at the
  same point, and the 120 s reserve covers a worst-case canary block (8 × 10 s), 10 s termination grace and the sweep,
  so discovery processes end before the discovery deadline. Replays run only through the replay contract, whose gate
  refuses at `total_deadline − 300 s`; the operator-session supervisor (this session) owns the remaining
  postprocessing and stops by the total deadline. Final post-sweep observations are postprocessing, not discovery.
  Evidence `09-verify.json` F2: with an 8 s canary, wall 75 s and reserve 30 s, discovery processes ended 27.7 s
  before the discovery deadline; a replay gate inside the total reserve refused (rc 125).
- **F3 — invalid observations are never baselines.** `canaries()` marks any nonzero exit or timeout `INVALID:…`
  (digesting stdout only for rc 0, so an empty successful `status --porcelain` stays valid); the watcher refuses to
  launch on an invalid baseline (exit 3, no telemetry) and `canary_problems()` treats a later INVALID as a
  violation. Evidence `09-verify.json` F3: missing-dependency baseline refused launch; a canary that became invalid
  mid-run stopped the run with 0 further executions and no survivors.
- Supervisor diff since the smoke version: `supervisor-r1-fixes.diff` (embedded below).

## Candidate found (to be dispositioned in Phase 3, not now)

`status` on a never-initialized run root returns rc 0 and creates `instances/C/state.db`
(`utils/py/harness.py:1267` `status()` → `connect()`); a later `init` on that root then refuses
`instance already initialized` (rc 2) and `tick` fails (rc 1). Clean control (fresh root → `init`) rc 0. Replay
text: `06-candidate-status-creates-state.txt`. Provisional class: new defect, low severity (experimental tool,
recoverable by using a new run root).

## Coverage, honestly

83% of Track A cases were argparse usage refusals (`usage` 166/200); the mutator rarely reaches deeper code. `tick`,
`packet`, `tool` and `init --from-prs` are excluded from fuzzing by design; stateful coverage is the fixed Track B
controls only, not fuzzed state sequences. Track B is not expanded in the long run (it has no discovery component).

## Proposed long window (frozen; see sha256-bound files below)

Same four Track A targets, same sandbox profile shape, same gate and watcher; seed 12800; discovery wall 21,600 s
(6 h; total window 28,800 s; watcher/gate stop reserve 120 s), 10,000 mutations, batch 50, corpus cap 500, 30 s per command; gate stops at 500 consecutive cases or 3
consecutive 50-case batches with no new signature, or any canary change; postprocessing ≤ 2 h after discovery within
an 8 h total. At the smoke's measured rate (~2.5 cases/s), the 10,000 cap would be reached in roughly 70 minutes, so a
budget or no-new-signal stop is expected long before the wall. Temporary sleep prevention: `caffeinate -i -w <watcher
pid>` for the run only.

## Questions for the reviewer

1. Does the smoke evidence below support opening the long window, given deviations 1–5? Is any of them a reason to
   hold (in particular 4: the watcher sweep on a real run)?
2. Is the frozen contract consistent with the issue's long-run bounds and the plan? Name any bound that is wrong.
3. Is the candidate correctly scoped as a single candidate for Phase 3 (not a reason to stop the run)?
4. Any containment gap visible in the profile, env, targets or supervisor as frozen?

Grade against the stated requirements and commensurate complexity (one supervised local experiment, disposable
clones, no production code, no new tests). Cite file/section for each finding.
