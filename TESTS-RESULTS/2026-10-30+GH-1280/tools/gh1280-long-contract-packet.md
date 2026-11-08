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


## Smoke results (machine summaries)

### Controls (step 3) — elapsed 32.0s

- known-good init+tick: **PASS** — expect: rc 0, rc 0
- known-invalid run root: **PASS** — expect: rc 2 run-root refusal, nothing created
- idempotence oracle red then green: **PASS** — expect: red cmd rc 1 (FAIL), repeated completed tick rc 0 (PASS)
- sandbox denies outside write, allows in-root: **PASS** — expect: outside: refused, path absent; in-root: rc 0, file exists
- gate stops exactly at streak 50: **PASS** — expect: 51 executed (1 new + 50 seen), event 52 gated, no survivors
- canary edit stops the run: **PASS** — expect: stop reason CANARY VIOLATION; at most the in-flight case after the edit; no survivors

Sandbox red step detail: rc=2 stderr tail: `factory-primitive: [Errno 1] Operation not permitted: '/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/outside-probe'`

Gate-boundary control detail: `{"executed": 51, "first_gated_index": 51, "gated": 6, "stop_reason": "no-new-signal: 50 consecutive cases with no new signature", "survivors": []}`

Canary control detail: `{"events_at_edit": 5, "executed_after_edit": 0, "stop_reason": "CANARY VIOLATION: ['canary_file']", "survivors": [], "elapsed_s": 7.8}`

### Track B (step 5)

- B1 ordinary-smoke: PASS (rcs [0, 0, 0, 0, 0, 0]; status keys match True; ledger queries match True)
- B1 malformed-decision: PASS (rcs [0, 0, 0]; status keys match True; ledger queries match True)
- B1 disallowed-decision: PASS (rcs [0, 0, 0]; status keys match True; ledger queries match True)
- B1 escape-create: PASS (rcs [0, 1, 0]; status keys match True; ledger queries match True)
- B1 escape-modify: PASS (rcs [0, 1, 0]; status keys match True; ledger queries match True)
- B1 escape-external: PASS (rcs [0, 1, 0]; status keys match True; ledger queries match True)
- B1 crash-act: PASS (rcs [0, 70, 0, 0]; status keys match True; ledger queries match True)
- B1 crash-intent: PASS (rcs [0, 70, 0, 0]; status keys match True; ledger queries match True)
- B1 crash-before-snapshot: PASS (rcs [0, 70, 0, 0]; status keys match True; ledger queries match True)
- B1 missing-decision: PASS (rcs [0, 70, 0, 0, 0]; status keys match True; ledger queries match True)
- B1 missing-snapshot: PASS (rcs [0, 70, 0, 0, 0]; status keys match True; ledger queries match True)
- B1 missing-receipt: PASS (rcs [0, 70, 0, 0]; status keys match True; ledger queries match True)
- B1 unbilled-error: PASS (rcs [0, 0, 0]; status keys match True; ledger queries match True)
- B1 timeout-unknown: PASS (rcs [0, 0, 0]; status keys match True; ledger queries match True)
- B1 budget-cap: PASS (rcs [0, 0, 0, 0]; status keys match True; ledger queries match True)
- B1 tool-failure: PASS (rcs [0, 1, 0]; status keys match True; ledger queries match True)
- B1 instance-path-guard: PASS (rcs [2]; status keys match None; ledger queries match True)
- B2: PASS rows before {'receipts': 1, 'decisions': 1, 'intents': 1, 'tool_runs': 1} after {'receipts': 1, 'decisions': 1, 'intents': 1, 'tool_runs': 1}
- B3: PASS rcs [0, 70, 0, 0] receipts [{'tick_id': 'slot_001', 'status': 'uncertain'}, {'tick_id': 'slot_002', 'status': 'completed'}] quarantined 1 slot1 tool runs before/after recovery 0/0 slot1 outputs [] survivors []

### Track A (step 4) — supervisor tracker rebuilt from the complete telemetry

- events 200, stop `mutation budget reached (200)`, streak at end 2, distinct signatures 59, gated 0
- counts `{"usage": 166, "pass": 21, "run-root-guard": 12, "state-guard": 1}`
- per target `{"fp-help": {"usage": 42, "pass": 8}, "fp-genman": {"usage": 42, "pass": 8}, "fp-status": {"usage": 41, "run-root-guard": 8, "pass": 1}, "fp-init": {"pass": 4, "usage": 41, "run-root-guard": 4, "state-guard": 1}}`
- supervisor-classified candidates: 0
- gen4 report: mutations 200 batches 8 counts {'pass': 21, 'fail': 166, 'anomaly': 13} host_violations [] contamination [{'round': 2, 'target': 'fp-genman', 'seed': 1282, 'changed': ['?? " "']}, {'round': 6, 'target': 'fp-genman', 'seed': 1286, 'changed': ['?? 0']}] errors []

#### `ev/09-verify.json` (sha256 `293647ac0a86e2e72110970c6b4da786168ceb06e5711c45865039326e0fe5d9`)

````text
{
 "elapsed_s": 118.5,
 "checks": [
  {
   "check": "F1 real run reaches budget, watcher reports and sweeps",
   "pass": true,
   "detail": {
    "rc": 0,
    "stderr": "",
    "report": {
     "stop_reason": "mutation budget reached (100)",
     "events": 100,
     "gen4_rc": -15,
     "swept_pids": [],
     "survivors_after_sweep": [],
     "canaries_moved": [],
     "per_target": {
      "fp-help": {
       "usage": 17,
       "pass": 8
      },
      "fp-genman": {
       "usage": 22,
       "pass": 3
      },
      "fp-status": {
       "usage": 19,
       "run-root-guard": 6
      },
      "fp-init": {
       "pass": 3,
       "usage": 18,
       "run-root-guard": 3,
       "state-guard": 1
      }
     }
    }
   },
   "t": 44.9
  },
  {
   "check": "F3 invalid baseline refuses launch",
   "pass": true,
   "detail": {
    "rc": 3,
    "stderr": "refusing: invalid canary baseline: {'missing_dep': 'INVALID:rc=1'}\n"
   },
   "t": 45.2
  },
  {
   "check": "F3 invalid mid-run observation stops the run",
   "pass": true,
   "detail": {
    "events_at_removal": 10,
    "executed_after": 0,
    "report": {
     "stop_reason": "CANARY VIOLATION: ['flag_present']",
     "events": 10,
     "gated_events": 3,
     "survivors_after_sweep": []
    }
   },
   "t": 53.5
  },
  {
   "check": "F2 slow canary: discovery ends before its deadline",
   "pass": true,
   "detail": {
    "stop_reason": "discovery deadline reserve reached (wall 75s, reserve 30s)",
    "events": 5,
    "gated": 0,
    "ended_minus_deadline_s": -27.7,
    "watcher_stop_minus_launch_s": 45.0,
    "survivors": []
   },
   "t": 118.5
  },
  {
   "check": "F2 replay refused inside the total-deadline reserve",
   "pass": true,
   "detail": {
    "rc": 125,
    "stderr": "gh1280-gate: stopped: total deadline reserve reached (replay)\n"
   },
   "t": 118.5
  }
 ]
}
````

#### `ev/09-verify-v5-stdout.json` (sha256 `3f876621be5cecd66aedfc46f174135ed9df8f938d4bc1f443bb0c123f4d3f2c`)

````text
{"stop_reason": "gen4 exited rc=0", "elapsed_s": 45.8, "events": 100, "counts": {"usage": 76, "pass": 14, "run-root-guard": 9, "state-guard": 1}, "swept_pids": [], "survivors_after_sweep": [], "canaries_moved": []}
````

#### `ev/supervisor-r1-fixes.diff` (sha256 `96274e899e8f88898672348f29429d7d66f858788d1cac217091d6269fcd79fb`)

````text
--- ev/supervisor.smoke-version.py	2026-10-30 19:18:55
+++ supervisor.py	2026-10-30 19:18:55
@@ -41,16 +41,23 @@
 
 
 def canaries(spec):
+    """Digest each read-only observation. A failed or timed-out command is INVALID, never a
+    value to compare: an unavailable observation must stop the run (contract review F3)."""
     out = {}
     for name, cmd in spec.items():
         try:
             r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
-            out[name] = hashlib.sha256((str(r.returncode) + r.stdout).encode()).hexdigest()[:16]
+            out[name] = (hashlib.sha256(r.stdout.encode()).hexdigest()[:16] if r.returncode == 0
+                         else "INVALID:rc=%d" % r.returncode)
         except subprocess.TimeoutExpired:
-            out[name] = "timeout"  # never equals a baseline digest, so it stops the run
+            out[name] = "INVALID:timeout"
     return out
 
 
+def canary_problems(base, now):
+    return [k for k in base if base[k] != now.get(k) or str(now.get(k)).startswith("INVALID")]
+
+
 def sweep(patterns):
     found = []
     for pat in patterns:
@@ -142,9 +149,15 @@
             if l.strip():
                 t.feed(json.loads(l))
     reason = t.stop_reason()
+    base = json.load(open(c["baseline"]))
+    if reason is None:  # exact deadline at the launch boundary (contract review F2)
+        if c.get("mode") == "replay":
+            if time.time() >= base["total_deadline"] - c.get("replay_reserve_s", 300):
+                reason = "total deadline reserve reached (replay)"
+        elif time.time() >= base["discovery_deadline"] - c.get("reserve_s", 0):
+            reason = "discovery deadline reserve reached"
     if reason is None:
-        base = json.load(open(c["baseline"]))
-        moved = [k for k, v in canaries(c["canaries"]).items() if base.get(k) != v]
+        moved = canary_problems(base["canaries"], canaries(c["canaries"]))
         reason = "CANARY VIOLATION: %s" % moved if moved else None
     if reason:
         with open(stopfile, "w") as fh:
@@ -184,7 +197,15 @@
         print("refusing: campaign-pattern processes already running: %s" % pre, file=sys.stderr)
         return 3
     base = canaries(c["canaries"])
-    json.dump(base, open(c["baseline"], "w"))
+    bad_base = [k for k, v in base.items() if v.startswith("INVALID")]
+    if bad_base:
+        print("refusing: invalid canary baseline: %s" % {k: base[k] for k in bad_base}, file=sys.stderr)
+        return 3
+    launch = time.time()
+    dl = {"discovery_deadline": launch + c["wall_s"], "total_deadline": launch + c.get("total_s", c["wall_s"])}
+    stop_at = dl["discovery_deadline"] - c.get("reserve_s", 0)  # leave room for canary + kill + sweep
+    json.dump(dict(dl, canaries=base), open(c["baseline"], "w"))
+    report.update(launch_epoch=launch, **dl, watcher_stop_epoch=stop_at)
     if os.path.exists(c["stopfile"]):
         os.remove(c["stopfile"])
     t0 = time.monotonic()
@@ -210,12 +231,11 @@
             break
         if os.path.exists(c["stopfile"]):
             reason = "gate: " + open(c["stopfile"]).read().strip()
-        elif time.monotonic() - t0 >= c["wall_s"]:
-            reason = "wall time reached (%ds)" % c["wall_s"]
+        elif time.time() >= stop_at:
+            reason = "discovery deadline reserve reached (wall %ds, reserve %ds)" % (c["wall_s"], c.get("reserve_s", 0))
         elif time.monotonic() - last_canary >= 5:
             last_canary = time.monotonic()
-            now = canaries(c["canaries"])
-            moved = [k for k in base if base[k] != now[k]]
+            moved = canary_problems(base, canaries(c["canaries"]))
             if moved:
                 reason = "CANARY VIOLATION: %s" % moved
         if reason is None and proc.poll() is not None:
@@ -235,6 +255,7 @@
     except Exception:
         pass
     killed = sweep(c["sweep_patterns"])
+    report["discovery_processes_ended_epoch"] = time.time()
     time.sleep(1)
     survivors = subprocess.run(["/usr/bin/pgrep", "-f", "|".join(c["sweep_patterns"])],
                                capture_output=True, text=True).stdout.split()
@@ -243,7 +264,7 @@
                   events=t.events, gated_events=getattr(t, "gated", 0), streak_at_stop=t.streak, quiet_batches_at_stop=t.quiet_batches,
                   counts=t.counts, per_target=t.per_target, signatures=sorted(t.seen),
                   candidates=t.candidates, swept_pids=killed, survivors_after_sweep=survivors,
-                  canaries_moved=[k for k in base if base[k] != final[k]])
+                  canaries_moved=canary_problems(base, final))
     json.dump(report, open(c["report"], "w"), indent=1)
     print(json.dumps({k: report[k] for k in ("stop_reason", "elapsed_s", "events", "counts",
                                              "swept_pids", "survivors_after_sweep", "canaries_moved")}))
````

#### `ev/06-replay-control.txt` (sha256 `99a993f2439127bbccb9975cfe9b8e13a44f294d9dcf1b81f0e96bd29f6e8931`)

````text
== replay (replay contract) of fp-status corpus 07b6a970364e
{
  "id": "07b6a970364e",
  "argv": [
    "--run-root",
    "temp/factory-primitive/fz",
    "status",
    "étrue"
  ],
  "recorded": [
    2,
    0,
    "e115aff343c5d3b3",
    "fast_<1s"
  ],
  "observed": [
    2,
    0,
    "e115aff343c5d3b3",
    "fast_<1s"
  ],
  "reproduced": true
}
rc=0
== same replay under the exhausted DISCOVERY contract (must be gated)
{
  "id": "07b6a970364e",
  "argv": [
    "--run-root",
    "temp/factory-primitive/fz",
    "status",
    "étrue"
  ],
  "recorded": [
    2,
    0,
    "e115aff343c5d3b3",
    "fast_<1s"
  ],
  "observed": [
    125,
    0,
    "c1914b11624463e3",
    "fast_<100ms"
  ],
  "reproduced": false
}
rc=1
== semantic re-check in control clone (clean control = base argv, then mutant)
gh1280-gate: stopped: CANARY VIOLATION: ['canary_file']
argv=[--run-root temp/factory-primitive/fz status] rc=125
gh1280-gate: stopped: CANARY VIOLATION: ['canary_file'] (decided before event 1)
argv=[--run-root temp/factory-primitive/fz status étrue] rc=125
git status lines:        0
== semantic re-check (refreshed ctl baseline)
                                    {init,generate-manifest,tick,status,packet,tool} ...
harness.py factory-primitive: error: argument command: invalid choice: '--run-root temp/factory-primitive/fz status' (choose from 'init', 'generate-manifest', 'tick', 'status', 'packet', 'tool')
argv=[--run-root temp/factory-primitive/fz status] rc=2
                                    {init,generate-manifest,tick,status,packet,tool} ...
harness.py factory-primitive: error: argument command: invalid choice: '--run-root temp/factory-primitive/fz status étrue' (choose from 'init', 'generate-manifest', 'tick', 'status', 'packet', 'tool')
argv=[--run-root temp/factory-primitive/fz status étrue] rc=2
git status lines:        0
== semantic re-check (word-split argv)
  "unknown_cost": false
}
argv=[--run-root temp/factory-primitive/fz status] rc=0
                                    {init,generate-manifest,tick,status,packet,tool} ...
harness.py factory-primitive: error: unrecognized arguments: étrue
argv=[--run-root temp/factory-primitive/fz status étrue] rc=2
git status lines:        0
````

#### `ev/06-candidate-status-creates-state.txt` (sha256 `bc931aae006055123588855d470361842b1303952f0bdc7a1bedd8119085f7f2`)

````text
== clean control: fresh root, init
{"instance":"/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-ctl/clone/temp/factory-primitive/gh1280/cand-clean/instances/C","status":"initialized"}
rc=0
== failing case: status first, then init
{
  "heartbeat": null,
  "last_receipt": null,
  "lock": "free",
  "paused": false,
  "pending": 0,
  "quarantined": 0,
  "quarantined_ids": [],
  "spent_or_reserved": 0,
  "ticks": {},
  "unknown_cost": false
}
status rc=0
1F 1D:

instances/C/ state.db
factory-primitive: instance already initialized; use a new run root
init rc=2
{"status":"failed","tick_id":"slot_001"}
tick rc=1
````

#### `ev/07-final-checks.txt` (sha256 `a98a3bcc4e246ee858b29303593905523ea1b150681a1ab4e17e6927658ba638`)

````text
== final smoke checks 2026-10-31T02:14:15Z epoch 1793412855
processes: none
task HEAD 623ba2c729259c1148d0b4e3fd9735ce4c53784d status-lines        0
primary HEAD 73ac994adc4037c20dc025745d69f0dde730eb63 status-lines        0 core.bare false
outside-probe exists: no
sb-ctl/outside exists: no
````

#### `ev/timeline.txt` (sha256 `9f2e6a0d60b6a36e0b4bc3185f6488fad0aa7f3019eda395b2b9e280d54587e6`)

````text
T0=1793412427 D=1793413627 END=1793414227
controls start 1793412427
controls end 1793412459 rc=
controls rerun start 1793412475
controls rerun end 1793412507
trackB start 1793412553
trackB end 1793412553
trackB start 1793412558
trackB end 1793412569
trackB rerun start 1793412594
trackB rerun end 1793412605
trackB rerun2 start 1793412632
trackB rerun2 end 1793412643
trackA start 1793412651 wall=971
trackA end 1793412733 rc=0
````

#### `ev/00-identity.txt` (sha256 `5d2d9ee03c0260317f901992bb7255b988ccb023c9e859793892acf20605d699`)

````text
== identity 2026-10-31T02:06:16Z
noel’s Mac Studio
Mac13,1
Python 3.14.7
-rwxr-xr-x  1 root  wheel  102560 Aug 16  2025 /usr/bin/sandbox-exec
https://github.com/HiQS-Labs/XYZ-forge.git
623ba2c729259c1148d0b4e3fd9735ce4c53784d
false
       0
processes:
none
````


## Frozen long-run contract and tooling (bound by sha256)

#### `contract-long.json` (sha256 `86e5b10a249edc790bf47f392fb53a68c8e1a5eae8b1bb3e13e0122cc32a2057`)

````json
{
 "name": "long",
 "target_names": [
  "fp-help",
  "fp-genman",
  "fp-status",
  "fp-init"
 ],
 "seed": 12800,
 "batch": 50,
 "streak_stop": 500,
 "quiet_batch_stop": 3,
 "max_mutations": 10000,
 "canaries": {
  "primary_head": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge\" --no-optional-locks rev-parse HEAD",
  "primary_status": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge\" --no-optional-locks status --porcelain",
  "primary_config": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge\" --no-optional-locks config --local --list",
  "primary_ledger": "shasum \"/Users/noelsaw/Documents/GH Repos/XYZ-forge/releases.db\"",
  "task_head": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30\" --no-optional-locks rev-parse HEAD",
  "task_status": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30\" --no-optional-locks status --porcelain",
  "task_config": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30\" --no-optional-locks config --local --list",
  "canary_file": "shasum \"/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/canary/canary.txt\""
 },
 "sweep_patterns": [
  "harness\\.py factory-primitive",
  "gen4_campaign\\.py",
  "gh1280/profile-"
 ],
 "telemetry": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long/telemetry.jsonl",
 "stopfile": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/STOP",
 "baseline": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/baseline.json",
 "wall_s": 21600,
 "total_s": 28800,
 "reserve_s": 120,
 "replay_reserve_s": 300,
 "report": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long/supervisor-report.json",
 "gen4_cwd": "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30",
 "gen4_env": {
  "PATH": "/usr/bin:/bin",
  "HOME": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/home",
  "TMPDIR": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/tmp",
  "PYTHONDONTWRITEBYTECODE": "1",
  "LANG": "C.UTF-8"
 },
 "gen4_log": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long/gen4.log",
 "gen4_argv": [
  "/opt/homebrew/bin/python3",
  "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30/utils/py/gen4_campaign.py",
  "--mode",
  "run",
  "--no-synth",
  "--repo",
  "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30",
  "--sandbox-root",
  "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long",
  "--out",
  "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long",
  "--targets",
  "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/targets-long.json",
  "--max-mutations",
  "10000",
  "--batch",
  "50",
  "--corpus-cap",
  "500",
  "--seed",
  "12800",
  "--duration",
  "21600",
  "--keep-sandbox",
  "--json"
 ]
}
````

#### `contract-long-replay.json` (sha256 `24613a033de39b173ce759338ecb7e95c7dbe6fc2fef850141b78a0f13e273b6`)

````json
{
 "name": "long",
 "target_names": [
  "fp-help",
  "fp-genman",
  "fp-status",
  "fp-init"
 ],
 "seed": 12800,
 "batch": 50,
 "streak_stop": null,
 "quiet_batch_stop": null,
 "max_mutations": 1000000000,
 "canaries": {
  "primary_head": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge\" --no-optional-locks rev-parse HEAD",
  "primary_status": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge\" --no-optional-locks status --porcelain",
  "primary_config": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge\" --no-optional-locks config --local --list",
  "primary_ledger": "shasum \"/Users/noelsaw/Documents/GH Repos/XYZ-forge/releases.db\"",
  "task_head": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30\" --no-optional-locks rev-parse HEAD",
  "task_status": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30\" --no-optional-locks status --porcelain",
  "task_config": "git -C \"/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30\" --no-optional-locks config --local --list",
  "canary_file": "shasum \"/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/canary/canary.txt\""
 },
 "sweep_patterns": [
  "harness\\.py factory-primitive",
  "gen4_campaign\\.py",
  "gh1280/profile-"
 ],
 "telemetry": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long/no-discovery-telemetry.jsonl",
 "stopfile": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/STOP-replay",
 "baseline": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/baseline.json",
 "wall_s": 21600,
 "total_s": 28800,
 "reserve_s": 120,
 "replay_reserve_s": 300,
 "report": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long/supervisor-report.json",
 "gen4_cwd": "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30",
 "gen4_env": {
  "PATH": "/usr/bin:/bin",
  "HOME": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/home",
  "TMPDIR": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/tmp",
  "PYTHONDONTWRITEBYTECODE": "1",
  "LANG": "C.UTF-8"
 },
 "gen4_log": "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long/gen4.log",
 "gen4_argv": [
  "/opt/homebrew/bin/python3",
  "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30/utils/py/gen4_campaign.py",
  "--mode",
  "run",
  "--no-synth",
  "--repo",
  "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30",
  "--sandbox-root",
  "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long",
  "--out",
  "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/out-long",
  "--targets",
  "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/targets-long.json",
  "--max-mutations",
  "10000",
  "--batch",
  "50",
  "--corpus-cap",
  "500",
  "--seed",
  "12800",
  "--duration",
  "21600",
  "--keep-sandbox",
  "--json"
 ],
 "mode": "replay"
}
````

#### `targets-long.json` (sha256 `ea2fe08d7adada9c9a1150577e07a86838c47b1c0274097f93055cd883e6ff96`)

````json
[
 {
  "name": "fp-help",
  "target": "/usr/bin/sandbox-exec -f /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/profile-long.sb /opt/homebrew/bin/python3 /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/supervisor.py --gate /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/contract-long.json -- utils/py/harness.py factory-primitive {mutant}",
  "base": [
   "--help"
  ],
  "timeout": 30
 },
 {
  "name": "fp-genman",
  "target": "/usr/bin/sandbox-exec -f /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/profile-long.sb /opt/homebrew/bin/python3 /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/supervisor.py --gate /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/contract-long.json -- utils/py/harness.py factory-primitive {mutant}",
  "base": [
   "generate-manifest",
   "--output",
   "temp/factory-primitive/ate-smoke/manifest.json"
  ],
  "timeout": 30
 },
 {
  "name": "fp-status",
  "target": "/usr/bin/sandbox-exec -f /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/profile-long.sb /opt/homebrew/bin/python3 /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/supervisor.py --gate /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/contract-long.json -- utils/py/harness.py factory-primitive {mutant}",
  "base": [
   "--run-root",
   "temp/factory-primitive/fz",
   "status"
  ],
  "timeout": 30
 },
 {
  "name": "fp-init",
  "target": "/usr/bin/sandbox-exec -f /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/profile-long.sb /opt/homebrew/bin/python3 /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/supervisor.py --gate /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/contract-long.json -- utils/py/harness.py factory-primitive {mutant}",
  "base": [
   "--run-root",
   "temp/factory-primitive/fz",
   "init",
   "--daily-cap",
   "1",
   "--max-call-cost",
   "0"
  ],
  "timeout": 30
 }
]
````

#### `profile-long.sb` (sha256 `20e04079ada6c1d5c23e25bcc2c3d238d48759efe8b8b8b0aeef198a37ca756b`)

````
(version 1)
(allow default)
(deny network*)
(deny file-write*)
(allow file-write* (subpath "/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long") (literal "/dev/null") (literal "/dev/zero") (literal "/dev/tty") (literal "/dev/dtracehelper") (subpath "/dev/fd"))
````

#### `supervisor.py` (sha256 `5994a64db6c9a964eb44ebb78ba6411aa85045b80bebb5ff203fd046074271d7`)

````python
#!/usr/bin/env python3
"""GH-1280 campaign supervisor: an independent foreground stop for one gen4_campaign run.

Not a suite, gate or adapter. It launches gen4 in its own process group, reads telemetry as it
grows, and stops the run on wall time, a no-new-signal streak, a canary change or invalid
telemetry. On stop it kills the gen4 group and then every surviving campaign process (each
mutant runs in its own session, so a group kill alone misses it).

usage: supervisor.py --contract contract.json [--replay-telemetry FILE]
"""
import argparse, hashlib, json, os, re, signal, subprocess, sys, time

EXPECTED = [  # (class, rc, stderr regex) — verified against utils/py/harness.py
    ("usage", 2, r"usage: harness\.py factory-primitive"),
    ("run-root-guard", 2, r"factory-primitive: run root must stay under "),
    ("instance-guard", 2, r"factory-primitive: instance must be a simple name"),
    ("slot-guard", 2, r"factory-primitive: slot must be in 1\.\.288"),
    ("state-guard", 2, r"factory-primitive: instance already initialized"),
    ("cap-guard", 2, r"factory-primitive: (invalid daily cap|--limit must be|--unregistered must be)"),
    ("sandbox-denied", 2, r"factory-primitive: .*Operation not permitted"),
    ("input-error", 2, r"factory-primitive: (\[Errno \d+\]|scenario |Expecting |Extra data|Invalid |Unterminated )"),
]


def classify(rc, stderr):
    if rc == 0:
        return "pass"
    if "Traceback (most recent call last)" in stderr:
        return "CANDIDATE:traceback"
    for name, want_rc, rx in EXPECTED:
        if rc == want_rc and re.search(rx, stderr):
            return name
    return "CANDIDATE:rc%d" % rc


def signature(target, rc, cls, stderr):
    last = (stderr.strip().splitlines() or [""])[-1]
    last = re.sub(r"'[^']*'|\"[^\"]*\"|/\S+", "P", last)
    last = re.sub(r"\d+", "N", last)[:160]
    return "%s|%d|%s|%s" % (target, rc, cls, last)


def canaries(spec):
    """Digest each read-only observation. A failed or timed-out command is INVALID, never a
    value to compare: an unavailable observation must stop the run (contract review F3)."""
    out = {}
    for name, cmd in spec.items():
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            out[name] = (hashlib.sha256(r.stdout.encode()).hexdigest()[:16] if r.returncode == 0
                         else "INVALID:rc=%d" % r.returncode)
        except subprocess.TimeoutExpired:
            out[name] = "INVALID:timeout"
    return out


def canary_problems(base, now):
    return [k for k in base if base[k] != now.get(k) or str(now.get(k)).startswith("INVALID")]


def sweep(patterns):
    found = []
    for pat in patterns:
        r = subprocess.run(["/usr/bin/pgrep", "-f", pat], capture_output=True, text=True)
        found += [int(p) for p in r.stdout.split() if int(p) != os.getpid()]
    for pid in set(found):
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    return sorted(set(found))


class Tracker:
    def __init__(self, c):
        self.c, self.seen, self.events, self.streak = c, set(), 0, 0
        self.batch_key, self.batch_new, self.quiet_batches = None, False, 0
        self.counts, self.per_target, self.candidates = {}, {}, []

    def target_of(self, seed):
        names = self.c["target_names"]
        return names[(seed - self.c["seed"] - 1) % len(names)]

    def feed(self, ev):
        x = ev.get("extra", {})
        rc, stderr = ev["exit_code"], x.get("stderr_sample", "")
        if rc == 125 and "gh1280-gate: stopped" in stderr:
            self.gated = getattr(self, "gated", 0) + 1  # refused at the launch boundary; never ran
            return
        tgt = self.target_of(x["seed"])
        cls = classify(rc, stderr)
        sig = signature(tgt, rc, cls, stderr)
        new = sig not in self.seen
        self.seen.add(sig)
        self.events += 1
        self.counts[cls] = self.counts.get(cls, 0) + 1
        pt = self.per_target.setdefault(tgt, {})
        pt[cls] = pt.get(cls, 0) + 1
        if cls.startswith("CANDIDATE"):
            self.candidates.append({"target": tgt, "class": cls, "rc": rc, "mutant": x.get("mutant"),
                                    "seed": x["seed"], "index": x.get("index"), "signature": sig,
                                    "stderr_tail": stderr[-600:], "corpus_id": x.get("corpus_id")})
        # Novelty is the signature's first occurrence only; a repeated candidate is captured
        # above but is not new signal (review F11).
        self.streak = 0 if new else self.streak + 1
        key = (tgt, x["seed"])
        if key != self.batch_key:
            self.batch_key, self.batch_new, self.batch_n = key, False, 0
        self.batch_new |= new
        self.batch_n += 1
        if self.batch_n == self.c["batch"]:  # close the batch at its last case, not the next one
            self.quiet_batches = 0 if self.batch_new else self.quiet_batches + 1

    def stop_reason(self):
        c = self.c
        if c.get("streak_stop") and self.streak >= c["streak_stop"]:
            return "no-new-signal: %d consecutive cases with no new signature" % self.streak
        if c.get("quiet_batch_stop") and self.quiet_batches >= c["quiet_batch_stop"]:
            return "no-new-signal: %d consecutive batches without a new signature" % self.quiet_batches
        if self.events >= c["max_mutations"]:
            return "mutation budget reached (%d)" % self.events
        return None


def read_new(path, pos):
    if not os.path.exists(path):
        return [], pos
    with open(path) as fh:
        fh.seek(pos)
        data = fh.read()
    lines = data.split("\n")
    complete, tail = lines[:-1], lines[-1]
    return [json.loads(l) for l in complete if l.strip()], pos + len(data) - len(tail)


def gate(c, argv):
    """Launch boundary: runs (inside the mutant's sandbox) before every mutant. Telemetry for
    case N-1 is appended before case N launches, so the decision here is exact.

    Replay uses its own contract (separate stop file, no discovery telemetry), so an exhausted
    discovery run never blocks a replay; the canary check still applies (review F12)."""
    stopfile = c["stopfile"]
    if os.path.exists(stopfile):
        print("gh1280-gate: stopped: %s" % open(stopfile).read().strip(), file=sys.stderr)
        return 125
    t = Tracker(c)
    if os.path.exists(c["telemetry"]):
        for l in open(c["telemetry"]):
            if l.strip():
                t.feed(json.loads(l))
    reason = t.stop_reason()
    base = json.load(open(c["baseline"]))
    if reason is None:  # exact deadline at the launch boundary (contract review F2)
        if c.get("mode") == "replay":
            if time.time() >= base["total_deadline"] - c.get("replay_reserve_s", 300):
                reason = "total deadline reserve reached (replay)"
        elif time.time() >= base["discovery_deadline"] - c.get("reserve_s", 0):
            reason = "discovery deadline reserve reached"
    if reason is None:
        moved = canary_problems(base["canaries"], canaries(c["canaries"]))
        reason = "CANARY VIOLATION: %s" % moved if moved else None
    if reason:
        with open(stopfile, "w") as fh:
            fh.write("%s (decided before event %d)\n" % (reason, t.events + 1))
        print("gh1280-gate: stopped: %s" % reason, file=sys.stderr)
        return 125
    os.execv(sys.executable, [sys.executable] + argv)


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--gate":
        c = json.load(open(sys.argv[2]))
        return gate(c, sys.argv[sys.argv.index("--") + 1:])
    ap = argparse.ArgumentParser()
    ap.add_argument("--contract", required=True)
    ap.add_argument("--replay-telemetry", help="negative control: feed a frozen telemetry file, run nothing")
    a = ap.parse_args()
    c = json.load(open(a.contract))
    t = Tracker(c)
    report = {"contract_sha256": hashlib.sha256(open(a.contract, "rb").read()).hexdigest()}

    if a.replay_telemetry:
        for i, l in enumerate(open(a.replay_telemetry)):
            t.feed(json.loads(l))
            r = t.stop_reason()
            if r:
                report.update(stop_reason=r, stopped_at_event=i + 1)
                break
        report.update(events=t.events, counts=t.counts, per_target=t.per_target, signatures=sorted(t.seen),
                      candidates=t.candidates, streak_at_end=t.streak, gated_events=getattr(t, "gated", 0))
        print(json.dumps(report, indent=1))
        return 0

    pre = subprocess.run(["/usr/bin/pgrep", "-f", "|".join(c["sweep_patterns"])],
                                       capture_output=True, text=True).stdout.split()
    if pre:
        print("refusing: campaign-pattern processes already running: %s" % pre, file=sys.stderr)
        return 3
    base = canaries(c["canaries"])
    bad_base = [k for k, v in base.items() if v.startswith("INVALID")]
    if bad_base:
        print("refusing: invalid canary baseline: %s" % {k: base[k] for k in bad_base}, file=sys.stderr)
        return 3
    launch = time.time()
    dl = {"discovery_deadline": launch + c["wall_s"], "total_deadline": launch + c.get("total_s", c["wall_s"])}
    stop_at = dl["discovery_deadline"] - c.get("reserve_s", 0)  # leave room for canary + kill + sweep
    json.dump(dict(dl, canaries=base), open(c["baseline"], "w"))
    report.update(launch_epoch=launch, **dl, watcher_stop_epoch=stop_at)
    if os.path.exists(c["stopfile"]):
        os.remove(c["stopfile"])
    t0 = time.monotonic()
    proc = subprocess.Popen(c["gen4_argv"], cwd=c["gen4_cwd"], env=c["gen4_env"], start_new_session=True,
                            stdout=open(c["gen4_log"], "w"), stderr=subprocess.STDOUT)
    report.update(gen4_pid=proc.pid, started=time.strftime("%Y-%m-%dT%H:%M:%S%z"))
    pos, reason, last_canary = 0, None, 0.0
    while reason is None:
        time.sleep(1)
        try:
            evs, pos = read_new(c["telemetry"], pos)
        except (ValueError, KeyError) as exc:
            reason = "invalid telemetry: %s" % exc
            break
        for ev in evs:
            try:
                t.feed(ev)
            except (KeyError, TypeError) as exc:
                reason = "invalid telemetry event: %s" % exc
                break
            reason = reason or t.stop_reason()
        if reason:
            break
        if os.path.exists(c["stopfile"]):
            reason = "gate: " + open(c["stopfile"]).read().strip()
        elif time.time() >= stop_at:
            reason = "discovery deadline reserve reached (wall %ds, reserve %ds)" % (c["wall_s"], c.get("reserve_s", 0))
        elif time.monotonic() - last_canary >= 5:
            last_canary = time.monotonic()
            moved = canary_problems(base, canaries(c["canaries"]))
            if moved:
                reason = "CANARY VIOLATION: %s" % moved
        if reason is None and proc.poll() is not None:
            reason = "gen4 exited rc=%s" % proc.returncode
    try:
        os.killpg(proc.pid, signal.SIGTERM)
        proc.wait(timeout=10)
    except (ProcessLookupError, PermissionError, subprocess.TimeoutExpired):
        # PermissionError: macOS refuses killpg once the group leader has exited (smoke run 1)
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass
    try:  # pick up the last lines the run wrote
        for ev in read_new(c["telemetry"], pos)[0]:
            t.feed(ev)
    except Exception:
        pass
    killed = sweep(c["sweep_patterns"])
    report["discovery_processes_ended_epoch"] = time.time()
    time.sleep(1)
    survivors = subprocess.run(["/usr/bin/pgrep", "-f", "|".join(c["sweep_patterns"])],
                               capture_output=True, text=True).stdout.split()
    final = canaries(c["canaries"])
    report.update(stop_reason=reason, elapsed_s=round(time.monotonic() - t0, 1), gen4_rc=proc.returncode,
                  events=t.events, gated_events=getattr(t, "gated", 0), streak_at_stop=t.streak, quiet_batches_at_stop=t.quiet_batches,
                  counts=t.counts, per_target=t.per_target, signatures=sorted(t.seen),
                  candidates=t.candidates, swept_pids=killed, survivors_after_sweep=survivors,
                  canaries_moved=canary_problems(base, final))
    json.dump(report, open(c["report"], "w"), indent=1)
    print(json.dumps({k: report[k] for k in ("stop_reason", "elapsed_s", "events", "counts",
                                             "swept_pids", "survivors_after_sweep", "canaries_moved")}))
    bad = report["survivors_after_sweep"] or report["canaries_moved"] or (reason or "").startswith(("CANARY", "invalid"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
````

#### `prep.py` (sha256 `4e2095baec57c1955bf254e51c3549abf964c5f41ea6d7e6c7d3f0a816b98b92`)

````python
#!/usr/bin/env python3
"""GH-1280 campaign setup: write a sandbox profile, gate contract and gen4 target list for one
sandbox root. Campaign tooling only (no suite, no production code).

usage: prep.py NAME --wall S --max N --batch B --streak K [--quiet-batches Q] [--stub] [--seed S]
  writes SP/sb-NAME/{home,tmp}, SP/profile-NAME.sb, SP/contract-NAME.json,
         SP/contract-NAME-replay.json, SP/targets-NAME.json, SP/out-NAME/
"""
import argparse, json, os

SP = os.path.dirname(os.path.realpath(__file__))
TASK = "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30"
PRIMARY = "/Users/noelsaw/Documents/GH Repos/XYZ-forge"
PY = "/opt/homebrew/bin/python3"


def git(repo, args):
    return 'git -C "%s" --no-optional-locks %s' % (repo, args)


CANARIES = {
    "primary_head": git(PRIMARY, "rev-parse HEAD"),
    "primary_status": git(PRIMARY, "status --porcelain"),
    "primary_config": git(PRIMARY, "config --local --list"),
    "primary_ledger": 'shasum "%s/releases.db"' % PRIMARY,
    "task_head": git(TASK, "rev-parse HEAD"),
    "task_status": git(TASK, "status --porcelain"),
    "task_config": git(TASK, "config --local --list"),
    "canary_file": 'shasum "%s/canary/canary.txt"' % SP,
}
SWEEP = ["harness\\.py factory-primitive", "gen4_campaign\\.py", "gh1280/profile-"]

TRACK_A = [  # name, base argv after `factory-primitive`
    ("fp-help", ["--help"]),
    ("fp-genman", ["generate-manifest", "--output", "temp/factory-primitive/ate-smoke/manifest.json"]),
    ("fp-status", ["--run-root", "temp/factory-primitive/fz", "status"]),
    ("fp-init", ["--run-root", "temp/factory-primitive/fz", "init", "--daily-cap", "1", "--max-call-cost", "0"]),
]


def profile(root):
    return ("(version 1)\n(allow default)\n(deny network*)\n(deny file-write*)\n"
            '(allow file-write* (subpath "%s") (literal "/dev/null") (literal "/dev/zero")'
            ' (literal "/dev/tty") (literal "/dev/dtracehelper") (subpath "/dev/fd"))\n' % root)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("--wall", type=int, required=True)
    ap.add_argument("--max", type=int, required=True)
    ap.add_argument("--batch", type=int, required=True)
    ap.add_argument("--streak", type=int, required=True)
    ap.add_argument("--quiet-batches", type=int)
    ap.add_argument("--corpus-cap", type=int, default=100)
    ap.add_argument("--total", type=int, help="total window seconds from launch (discovery + postprocessing)")
    ap.add_argument("--reserve", type=int, default=0, help="watcher stops this many seconds before the discovery deadline")
    ap.add_argument("--seed", type=int, default=1280)
    ap.add_argument("--stub", help="sleep seconds for a stub target (supervisor controls)")
    a = ap.parse_args()
    root = os.path.join(SP, "sb-" + a.name)
    out = os.path.join(SP, "out-" + a.name)
    for d in (root, os.path.join(root, "home"), os.path.join(root, "tmp"), out):
        os.makedirs(d, exist_ok=True)
    prof = os.path.join(SP, "profile-%s.sb" % a.name)
    open(prof, "w").write(profile(root))
    contract = os.path.join(SP, "contract-%s.json" % a.name)
    replay = os.path.join(SP, "contract-%s-replay.json" % a.name)
    head = "/usr/bin/sandbox-exec -f %s %s %s/supervisor.py --gate %%s --" % (prof, PY, SP)
    if a.stub:
        targets = [{"name": "stub", "target": (head % contract) + " %s/stub.py {mutant}" % SP,
                    "base": ["status"], "timeout": 30, "env": {"STUB_SLEEP": a.stub}}]
    else:
        targets = [{"name": n, "target": (head % contract) + " utils/py/harness.py factory-primitive {mutant}",
                    "base": b, "timeout": 30} for n, b in TRACK_A]
    env = {"PATH": "/usr/bin:/bin", "HOME": root + "/home", "TMPDIR": root + "/tmp",
           "PYTHONDONTWRITEBYTECODE": "1", "LANG": "C.UTF-8"}
    tfile = os.path.join(SP, "targets-%s.json" % a.name)
    json.dump(targets, open(tfile, "w"), indent=1)
    c = {"name": a.name, "target_names": [t["name"] for t in targets], "seed": a.seed, "batch": a.batch,
         "streak_stop": a.streak, "quiet_batch_stop": a.quiet_batches, "max_mutations": a.max,
         "canaries": CANARIES, "sweep_patterns": SWEEP, "telemetry": os.path.join(out, "telemetry.jsonl"),
         "stopfile": os.path.join(root, "STOP"), "baseline": os.path.join(root, "baseline.json"),
         "wall_s": a.wall, "total_s": a.total or a.wall, "reserve_s": a.reserve, "replay_reserve_s": 300, "report": os.path.join(out, "supervisor-report.json"),
         "gen4_cwd": TASK, "gen4_env": env, "gen4_log": os.path.join(out, "gen4.log"),
         "gen4_argv": [PY, TASK + "/utils/py/gen4_campaign.py", "--mode", "run", "--no-synth", "--repo", TASK,
                       "--sandbox-root", root, "--out", out, "--targets", tfile, "--max-mutations", str(a.max),
                       "--batch", str(a.batch), "--corpus-cap", str(a.corpus_cap), "--seed", str(a.seed),
                       "--duration", str(a.wall), "--keep-sandbox", "--json"]}
    json.dump(c, open(contract, "w"), indent=1)
    r = dict(c, telemetry=os.path.join(out, "no-discovery-telemetry.jsonl"), stopfile=os.path.join(root, "STOP-replay"),
             streak_stop=None, quiet_batch_stop=None, max_mutations=10 ** 9, mode="replay")
    json.dump(r, open(replay, "w"), indent=1)
    print(json.dumps({"contract": contract, "replay": replay, "targets": tfile, "profile": prof, "root": root, "out": out}))


if __name__ == "__main__":
    main()
````

#### `stub.py` (sha256 `1ff56681c9a82fcb1b6206cec26013aeb5c7f96de45f671aa05f1a4b6174bb3f`)

````python
"""GH-1280 supervisor-control stub: a target whose every mutant yields one identical refusal."""
import os, sys, time

time.sleep(float(os.environ.get("STUB_SLEEP", "0")))
sys.stderr.write("factory-primitive: run root must stay under STUB\n")
sys.exit(2)
````

#### `controls.py` (sha256 `74e663408bd8f7a8c85e190cac1cc86229660ccce6ad8957da3e74f27d16736d`)

````python
#!/usr/bin/env python3
"""GH-1280 smoke step 3: required controls. Writes ev/03-controls.json. Campaign tooling only."""
import json, os, subprocess, sys, threading, time

SP = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, SP)
import supervisor as sup  # noqa: E402

PY = "/opt/homebrew/bin/python3"
CLONE = os.path.join(SP, "sb-ctl", "clone")
HP = ["utils/py/harness.py", "factory-primitive"]
results, t0 = [], time.time()


def run(argv, cwd=CLONE, timeout=60, env=None):
    e = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", **(env or {}))
    r = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=e)
    return {"argv": argv, "rc": r.returncode, "stdout": r.stdout[-1500:], "stderr": r.stderr[-1500:]}


def record(name, ok, expect, steps):
    results.append({"control": name, "pass": bool(ok), "expect": expect, "steps": steps,
                    "t": round(time.time() - t0, 1)})
    print(("PASS " if ok else "FAIL ") + name, flush=True)


# (a) known-good
s = [run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/good", "init", "--daily-cap", "1", "--max-call-cost", "0"]),
     run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/good", "tick", "--slot", "1"])]
record("known-good init+tick", s[0]["rc"] == 0 and s[1]["rc"] == 0, "rc 0, rc 0", s)

# (b) known-invalid
s = [run([PY] + HP + ["--run-root", "../outside", "status"])]
record("known-invalid run root", s[0]["rc"] == 2 and "run root must stay under" in s[0]["stderr"]
       and not os.path.exists(os.path.join(SP, "sb-ctl", "outside")), "rc 2 run-root refusal, nothing created", s)

# (c) idempotence oracle: witnessed red, then green
red_cmd = "%s -c \"import random; open('temp/factory-primitive/gh1280/idem-red.txt','a').write(str(random.random()))\"" % PY
s = [run([PY, "utils/py/domain_oracles.py", "--mode", "idempotence", "--cmd", red_cmd, "--cwd", CLONE, "--repetitions", "3", "--json"])]
red_ok = s[0]["rc"] == 1
s += [run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/idem", "init", "--daily-cap", "1", "--max-call-cost", "0"]),
      run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/idem", "tick", "--slot", "1"])]
green_cmd = "%s utils/py/harness.py factory-primitive --run-root temp/factory-primitive/gh1280/idem tick --slot 1" % PY
s += [run([PY, "utils/py/domain_oracles.py", "--mode", "idempotence", "--cmd", green_cmd, "--cwd", CLONE, "--repetitions", "3", "--json"])]
record("idempotence oracle red then green", red_ok and s[-1]["rc"] == 0, "red cmd rc 1 (FAIL), repeated completed tick rc 0 (PASS)", s)

# (d) OS sandbox: witnessed red (outside write denied), then green (in-root write succeeds)
ctl = json.load(open(os.path.join(SP, "contract-ctl-replay.json")))
json.dump(sup.canaries(ctl["canaries"]), open(ctl["baseline"], "w"))
wrap = ["/usr/bin/sandbox-exec", "-f", os.path.join(SP, "profile-ctl.sb"), PY, os.path.join(SP, "supervisor.py"), "--gate",
        os.path.join(SP, "contract-ctl-replay.json"), "--"] + HP
outside = os.path.join(SP, "outside-probe", "manifest.json")
s = [run(wrap + ["generate-manifest", "--output", outside])]
red_ok = s[0]["rc"] != 0 and not os.path.exists(os.path.dirname(outside))
s += [run(wrap + ["generate-manifest", "--output", "temp/factory-primitive/ate-smoke/manifest.json"])]
green_ok = s[-1]["rc"] == 0 and os.path.exists(os.path.join(CLONE, "temp/factory-primitive/ate-smoke/manifest.json"))
record("sandbox denies outside write, allows in-root", red_ok and green_ok, "outside: refused, path absent; in-root: rc 0, file exists", s)


# (e) supervisor launch gate + watcher on a stub target
def prep(name, *args):
    return json.loads(subprocess.run([PY, os.path.join(SP, "prep.py"), name] + list(args),
                                     capture_output=True, text=True, check=True).stdout)


p = prep("stub1", "--wall", "300", "--max", "200", "--batch", "25", "--streak", "50", "--stub", "0")
s = [run([PY, os.path.join(SP, "supervisor.py"), "--contract", p["contract"]], cwd=SP, timeout=420)]
evs = [json.loads(l) for l in open(os.path.join(p["out"], "telemetry.jsonl"))]
gated = [i for i, e in enumerate(evs) if e["exit_code"] == 125]
executed = len(evs) - len(gated)
rep = json.load(open(os.path.join(p["out"], "supervisor-report.json")))
ok = (executed == 51 and gated and gated[0] == 51 and all(i >= 51 for i in gated)
      and "no-new-signal" in rep["stop_reason"] and not rep["survivors_after_sweep"])
s.append({"executed": executed, "first_gated_index": gated[0] if gated else None, "gated": len(gated),
          "stop_reason": rep["stop_reason"], "survivors": rep["survivors_after_sweep"]})
record("gate stops exactly at streak 50", ok, "51 executed (1 new + 50 seen), event 52 gated, no survivors", s)

p = prep("stub2", "--wall", "120", "--max", "200", "--batch", "25", "--streak", "100000", "--stub", "0.5")
box = {}
th = threading.Thread(target=lambda: box.update(r=run([PY, os.path.join(SP, "supervisor.py"), "--contract", p["contract"]],
                                                      cwd=SP, timeout=300)))
th.start()
tel = os.path.join(p["out"], "telemetry.jsonl")
while not (os.path.exists(tel) and sum(1 for _ in open(tel)) >= 5):
    time.sleep(0.5)
with open(os.path.join(SP, "canary", "canary.txt"), "a") as fh:
    fh.write("deliberate canary edit (control e-b)\n")
touched = sum(1 for _ in open(tel))
th.join()
rep = json.load(open(os.path.join(p["out"], "supervisor-report.json")))
evs = [json.loads(l) for l in open(tel)]
after = [e for e in evs[touched:] if e["exit_code"] != 125]
ok = "CANARY VIOLATION" in rep["stop_reason"] and len(after) <= 1 and not rep["survivors_after_sweep"]
record("canary edit stops the run", ok, "stop reason CANARY VIOLATION; at most the in-flight case after the edit; no survivors",
       [box.get("r"), {"events_at_edit": touched, "executed_after_edit": len(after), "stop_reason": rep["stop_reason"],
                       "survivors": rep["survivors_after_sweep"], "elapsed_s": rep["elapsed_s"]}])

json.dump({"elapsed_s": round(time.time() - t0, 1), "controls": results}, open(os.path.join(SP, "ev", "03-controls.json"), "w"), indent=1)
print("all pass" if all(r["pass"] for r in results) else "SOME CONTROLS FAILED")
sys.exit(0 if all(r["pass"] for r in results) else 1)
````

#### `track_b.py` (sha256 `cf79763fff681b44a48fe33bcbe7c876694bea4cab0690a216e73bbb47e46f3f`)

````python
#!/usr/bin/env python3
"""GH-1280 smoke step 5 (Track B): stateful checks in the disposable control clone.

B1 replays the 17 GH-1248 checkpoint2 controls with relocated argv and compares exit codes,
final status and the two recorded ledger queries against the recorded logs. B2 checks a
repeated completed tick leaves the state rows unchanged. B3 checks crash-act recovery.
Usage: track_b.py DEADLINE_EPOCH. Writes ev/05-track-b.json. Campaign tooling only.
"""
import json, os, re, shlex, sqlite3, subprocess, sys, time

SP = os.path.dirname(os.path.realpath(__file__))
TASK = "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30"
CLONE = os.path.join(SP, "sb-ctl", "clone")
FPROOT = os.path.realpath(os.path.join(CLONE, "temp", "factory-primitive"))
PY = "/opt/homebrew/bin/python3"
SRC = os.path.join(TASK, "TESTS-RESULTS", "2026-10-28+GH-1248")
DEADLINE = float(sys.argv[1])
Q1 = "SELECT tick_id,status FROM receipts ORDER BY tick_id"
Q2 = "SELECT tick_id,tool,status FROM tool_runs NATURAL JOIN intents"


def run(argv, timeout=120):
    r = subprocess.run(argv, cwd=CLONE, capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
    return {"argv": argv, "rc": r.returncode, "stdout": r.stdout, "stderr": r.stderr[-800:]}


def query(db, q):
    c = sqlite3.connect("file:%s?mode=ro" % db, uri=True)
    c.row_factory = sqlite3.Row
    rows = [dict(r) for r in c.execute(q)]
    c.close()
    return rows


def parse_log(path):
    text = open(path).read()
    rcs = [int(x) for x in re.findall(r"^exit_code=(-?\d+)$", text, re.M)]
    outs = re.findall(r"^stdout:\n(.*?)\nstderr:", text, re.M | re.S)
    queries = {}
    for q, line in re.findall(r"^query=(.*)\n(.*)$", text, re.M):
        queries[q] = json.loads(line)
    return rcs, outs, queries


def adapt(cmd, case, new_root):
    argv = shlex.split(cmd)
    old_root = "temp/factory-primitive/evidence/checkpoint2/" + case
    out = []
    for i, tok in enumerate(argv):
        if i == 0 and tok.endswith("python3"):
            tok = PY
        elif old_root in tok:
            tail = tok.split(old_root, 1)[1]
            tok = new_root + tail if not os.path.isabs(tok) else os.path.join(CLONE, new_root) + tail
        out.append(tok)
    for tok in out:  # every mutable path must resolve inside the clone's run root
        if "factory-primitive/" in tok and not tok.startswith("utils/") and "--" != tok[:2]:
            p = os.path.realpath(tok if os.path.isabs(tok) else os.path.join(CLONE, tok))
            if not p.startswith(FPROOT + os.sep):
                raise ValueError("unrelocatable path %r -> %s" % (tok, p))
    return out


results = {"B1": [], "B2": None, "B3": None}
for line in open(os.path.join(SRC, "controls-checkpoint2.jsonl")):
    if time.time() >= DEADLINE:
        results["B1"].append({"held": "discovery deadline reached"})
        break
    d = json.loads(line)
    case, new_root = d["case"], "temp/factory-primitive/gh1280/b1/" + d["case"]
    rec_rcs, rec_outs, rec_q = parse_log(os.path.join(SRC, d["log"]))
    try:
        cmds = [adapt(c, case, new_root) for c in d["commands"]]
    except ValueError as exc:
        results["B1"].append({"case": case, "held": str(exc)})
        continue
    steps = [run(a) for a in cmds]
    rcs = [s["rc"] for s in steps]
    db = os.path.join(CLONE, new_root, "instances", "C", "state.db")
    got_q = {q: query(db, q) for q in rec_q} if os.path.exists(db) else {}
    status_match = None
    if steps and "status" in cmds[-1]:
        try:
            # GH-1257 later added heartbeat/last_receipt/lock/quarantined_ids; compare the recorded keys
            got, rec = json.loads(steps[-1]["stdout"]), json.loads(rec_outs[-1])
            status_match = {k: got.get(k) for k in rec} == rec
        except (ValueError, IndexError):
            status_match = False
    def norm(q):  # wall-clock "ts" inside stored event JSON differs by run; drop it
        f = lambda row: {k: ({x: y for x, y in json.loads(v).items() if x != "ts"} if k == "json" else v) for k, v in row.items()}
        return {k: [f(r) for r in rows] for k, rows in q.items()}
    ok = rcs == rec_rcs and norm(got_q) == norm(rec_q) and status_match is not False
    results["B1"].append({"case": case, "pass": ok, "rcs": rcs, "recorded_rcs": rec_rcs, "status_match": status_match,
                          "queries_match": norm(got_q) == norm(rec_q), "queries": got_q, "recorded_queries": rec_q,
                          "adapted_argv": cmds, "stderr_tails": [s["stderr"] for s in steps if s["stderr"]],
                          "recorded_detail": d.get("detail")})
    print(("PASS " if ok else "FAIL ") + "B1 " + case, flush=True)

# B2: repeated completed tick leaves rows unchanged (the oracle digest check ran in control c)
root = "temp/factory-primitive/gh1280/b2"
s = [run([PY, "utils/py/harness.py", "factory-primitive", "--run-root", root, "init", "--daily-cap", "1", "--max-call-cost", "0"]),
     run([PY, "utils/py/harness.py", "factory-primitive", "--run-root", root, "tick", "--slot", "1"])]
db = os.path.join(CLONE, root, "instances", "C", "state.db")
tables = ["receipts", "decisions", "intents", "tool_runs"]
before = {t: query(db, "SELECT count(*) n FROM %s" % t)[0]["n"] for t in tables}
s += [run([PY, "utils/py/harness.py", "factory-primitive", "--run-root", root, "tick", "--slot", "1"]) for _ in range(3)]
after = {t: query(db, "SELECT count(*) n FROM %s" % t)[0]["n"] for t in tables}
ok = all(x["rc"] == 0 for x in s) and before == after and len({x["stdout"] for x in s[2:]}) == 1
results["B2"] = {"pass": ok, "rows_before": before, "rows_after": after, "repeat_stdout": [x["stdout"] for x in s[1:]]}
print(("PASS " if ok else "FAIL ") + "B2 repeated tick", flush=True)

# B3: crash-act, recovery tick, status
root = "temp/factory-primitive/gh1280/b3"
H = [PY, "utils/py/harness.py", "factory-primitive", "--run-root", root]
s = [run(H + ["init", "--daily-cap", "1", "--max-call-cost", "0"]), run(H + ["tick", "--slot", "1", "--fault", "crash-act"])]
inst = os.path.join(CLONE, root, "instances", "C")
db = os.path.join(inst, "state.db")
runs_before = query(db, "SELECT count(*) n FROM tool_runs NATURAL JOIN intents WHERE tick_id='slot_001'")[0]["n"]
s += [run(H + ["tick", "--slot", "2"]), run(H + ["status"])]
receipts = query(db, Q1)
runs_after = query(db, "SELECT count(*) n FROM tool_runs NATURAL JOIN intents WHERE tick_id='slot_001'")[0]["n"]
out_hits = [os.path.join(dp, f) for dp, _, fs in os.walk(os.path.join(inst, "out")) for f in fs
            if "slot_001" in f or "slot_001" in dp]
status = json.loads(s[-1]["stdout"]) if s[-1]["rc"] == 0 else {}
live = subprocess.run(["/usr/bin/pgrep", "-f", root], capture_output=True, text=True).stdout.split()
ok = (s[1]["rc"] == 70 and s[2]["rc"] == 0 and {"tick_id": "slot_001", "status": "uncertain"} in receipts
      and status.get("quarantined") == 1 and runs_before == 0 and runs_after == 0 and not out_hits and not live)
results["B3"] = {"pass": ok, "rcs": [x["rc"] for x in s], "receipts": receipts, "status": status,
                 "slot1_tool_runs_before_recovery": runs_before, "slot1_tool_runs_after_recovery": runs_after,
                 "slot1_output_files": out_hits, "surviving_pids": live}
print(("PASS " if ok else "FAIL ") + "B3 crash-act recovery", flush=True)

json.dump(results, open(os.path.join(SP, "ev", "05-track-b.json"), "w"), indent=1)
allok = all(r.get("pass") for r in results["B1"]) and results["B2"]["pass"] and results["B3"]["pass"]
print("TRACK B " + ("PASS" if allok else "NOT ALL PASS"))
````

#### `verify.py` (sha256 `bdb9c9a11013a5c48182ac5f7d347f95a1dcba795fcddcc4ecc4702912b07a67`)

````python
#!/usr/bin/env python3
"""GH-1280 contract-review fix verification (F1–F3), real harness, disposable gen4 clones.
Writes ev/09-verify.json. Campaign tooling only."""
import json, os, subprocess, sys, threading, time

SP = os.path.dirname(os.path.realpath(__file__))
PY = "/opt/homebrew/bin/python3"
res, t0 = [], time.time()


def prep(name, *args, extra_canaries=None):
    p = json.loads(subprocess.run([PY, os.path.join(SP, "prep.py"), name] + list(args), capture_output=True,
                                  text=True, check=True).stdout)
    if extra_canaries:
        for f in (p["contract"], p["replay"]):
            c = json.load(open(f)); c["canaries"].update(extra_canaries); json.dump(c, open(f, "w"), indent=1)
    return p


def sup(p, timeout=900):
    r = subprocess.run([PY, os.path.join(SP, "supervisor.py"), "--contract", p["contract"]], cwd=SP,
                       capture_output=True, text=True, timeout=timeout)
    rep = os.path.join(p["out"], "supervisor-report.json")
    return r, (json.load(open(rep)) if os.path.exists(rep) else None)


def record(name, ok, detail):
    res.append({"check": name, "pass": bool(ok), "detail": detail, "t": round(time.time() - t0, 1)})
    print(("PASS " if ok else "FAIL ") + name, flush=True)


# F1: natural real-harness budget exit; the watcher must write its own report and sweep
p = prep("v1", "--wall", "300", "--max", "100", "--batch", "25", "--streak", "100000")
r, rep = sup(p)
record("F1 real run reaches budget, watcher reports and sweeps",
       r.returncode == 0 and rep and rep["events"] == 100 and not rep["survivors_after_sweep"] and not rep["canaries_moved"],
       {"rc": r.returncode, "stderr": r.stderr[-400:], "report": rep and {k: rep[k] for k in (
           "stop_reason", "events", "gen4_rc", "swept_pids", "survivors_after_sweep", "canaries_moved", "per_target")}})

# F3a: invalid baseline refuses launch
p = prep("v2", "--wall", "60", "--max", "50", "--batch", "25", "--streak", "100000",
         extra_canaries={"missing_dep": "test -e %s/does-not-exist" % SP})
r, rep = sup(p, timeout=60)
record("F3 invalid baseline refuses launch", r.returncode == 3 and "invalid canary baseline" in r.stderr
       and not os.path.exists(os.path.join(p["out"], "telemetry.jsonl")), {"rc": r.returncode, "stderr": r.stderr[-300:]})

# F3b: an observation that becomes invalid mid-run stops the run at the next launch
flag = os.path.join(SP, "v3-flag")
open(flag, "w").write("present\n")
p = prep("v3", "--wall", "300", "--max", "400", "--batch", "25", "--streak", "100000",
         extra_canaries={"flag_present": "test -e %s" % flag})
box = {}
th = threading.Thread(target=lambda: box.update(out=sup(p)))
th.start()
tel = os.path.join(p["out"], "telemetry.jsonl")
while not (os.path.exists(tel) and sum(1 for _ in open(tel)) >= 10):
    time.sleep(0.5)
os.remove(flag)
at = sum(1 for _ in open(tel))
th.join()
r, rep = box["out"]
evs = [json.loads(l) for l in open(tel)]
ran_after = sum(1 for e in evs[at:] if e["exit_code"] != 125)
record("F3 invalid mid-run observation stops the run",
       rep and "CANARY VIOLATION" in rep["stop_reason"] and "flag_present" in rep["stop_reason"] and ran_after <= 1
       and not rep["survivors_after_sweep"],
       {"events_at_removal": at, "executed_after": ran_after, "report": rep and {k: rep[k] for k in (
           "stop_reason", "events", "gated_events", "survivors_after_sweep")}})

# F2: slow canary (8 s) near the deadline; discovery processes must end before the discovery deadline
p = prep("v4", "--wall", "75", "--max", "10000", "--batch", "25", "--streak", "100000", "--reserve", "30",
         "--total", "120", extra_canaries={"slow": "sleep 8; echo slow"})
r, rep = sup(p, timeout=300)
ok = rep and rep["discovery_processes_ended_epoch"] <= rep["discovery_deadline"] and not rep["survivors_after_sweep"]
record("F2 slow canary: discovery ends before its deadline",
       ok, rep and {"stop_reason": rep["stop_reason"], "events": rep["events"], "gated": rep["gated_events"],
                    "ended_minus_deadline_s": round(rep["discovery_processes_ended_epoch"] - rep["discovery_deadline"], 1),
                    "watcher_stop_minus_launch_s": round(rep["watcher_stop_epoch"] - rep["launch_epoch"], 1),
                    "survivors": rep["survivors_after_sweep"]})

# F2: replay gate honours the total deadline reserve (v4 total 120 s, replay reserve 300 s → already refused)
c = json.load(open(p["replay"]))
r = subprocess.run(["/usr/bin/sandbox-exec", "-f", p["profile"], PY, os.path.join(SP, "supervisor.py"), "--gate", p["replay"],
                    "--", "-c", "print('ran')"], capture_output=True, text=True)
record("F2 replay refused inside the total-deadline reserve", r.returncode == 125 and "total deadline" in r.stderr,
       {"rc": r.returncode, "stderr": r.stderr[-200:]})

json.dump({"elapsed_s": round(time.time() - t0, 1), "checks": res}, open(os.path.join(SP, "ev", "09-verify.json"), "w"), indent=1)
print("all pass" if all(x["pass"] for x in res) else "SOME CHECKS FAILED")
````

