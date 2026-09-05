# Agy — GH-299 Gen 4 ATE: 3-hour unattended soak (tonight)

You are running the first real soak of the Gen 4 ATE stack on branch `feat/gh299-gen4-ate`.
Read `PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md` first (Status + QA gates), then do exactly
the following. Do not modify tracked files on this branch except the two evidence paths named
in step 6. Do not merge anything. Do not run `git push --no-verify`.

## 0. Setup (5 min)

```bash
cd ~/marathon-clones/gh299-gen4            # a normal clone, NOT a linked worktree (GH-45)
git fetch -q && git checkout -q feat/gh299-gen4-ate && git pull -q
bash githooks/install.sh --check           # must print INSTALLED
python3 utils/py/telemetry_schema.py --mode suite
python3 utils/py/domain_oracles.py   --mode suite
python3 utils/py/adaptive_ate.py     --mode suite
python3 utils/py/fuzz_engine.py      --mode suite
python3 utils/py/repro_synth.py      --mode suite
python3 utils/py/gen4_campaign.py    --mode suite
```
All six must print `SUITE_RESULT=PASS`. If any does not, STOP and write the failure verbatim to
`relay-system/2026-09-04/gh299-gen4-soak-agy.md` — that is the whole deliverable in that case.

## 1. The soak (2h 45m wall clock, unattended)

```bash
DATE=$(date +%F)
OUT="TESTS-RESULTS/${DATE}+GH-299/soak-agy"
mkdir -p "$OUT"
nohup python3 utils/py/gen4_campaign.py --mode run \
  --repo "$PWD" \
  --sandbox-root "${TMPDIR:-/tmp}/gen4-soak-$DATE" \
  --out "$OUT" \
  --duration 9900 \
  --batch 25 --seed 20260904 \
  --parity \
  --keep-sandbox \
  > "$OUT/stdout.log" 2>&1 &
echo $! > "$OUT/campaign.pid"
```
Notes:
- `--parity` turns on the cross-twin oracle for `codex-turn-twins` / `agy-turn-twins`
  (`XYZ_PYTHON=0`). Phase 3 already saw 6/12 divergences on `codex-turn.sh`; expect more —
  they are a FINDING to report, not something to fix tonight.
- The campaign resets its sandbox on any contamination event and keeps going; it never
  touches this clone's `.git`. If `campaign.log` shows `HOST VIOLATION`, kill the run
  (`kill $(cat $OUT/campaign.pid)`) and report immediately — that is a Blocker.
- Check progress at most every 30 min: `tail -3 "$OUT/campaign.log"`. Do nothing else with the
  repo while it runs.

## 2. When it finishes (report writes `campaign-report.json` + `campaign-summary.md`)

Verify, in this order, and record each result verbatim:
```bash
python3 -c "import json; d=json.load(open('$OUT/campaign-report.json')); print(d['mutations'], d['verdict'], len(d['clusters']), len(d['false_positives']), d['parity_divergences'])"
python3 utils/py/telemetry_schema.py --mode validate --path "$OUT/telemetry.jsonl"
git status --porcelain          # must show ONLY the $OUT/ paths
git diff --stat                 # must be empty
python3 utils/py/repro_synth.py --mode cluster --telemetry "$OUT/telemetry.jsonl"
ls "$OUT/synth/" 2>/dev/null
```

Bars from the plan (Phase 5 gate): `mutations >= 10000`, `zero_host_contamination: true`,
`zero_false_positives: true`, `telemetry_line_valid: true`. State each as met / not met with the
number. Do not round.

## 3. Triage the clusters (max 30 min, $0 — no LLM calls needed)

For each cluster in `campaign-summary.md`:
1. Run the synthesized suite in `$OUT/synth/` with `XYZ_ROOT=<sandbox clone path from the report>`.
   It PASSES when the defect reproduces. Record rc.
2. Classify the cluster as one of: `real-defect` (traceback/crash/hang on a reachable input),
   `handled-but-noisy` (the tool rejects correctly but stderr is not usage-shaped, so Tier-1
   could not classify it — a calibration gap, note the stderr head), `parity` (twins diverge),
   or `harness-artifact` (sandbox/tooling issue, explain).
3. Do NOT fix anything. Do NOT file issues tonight. Just the table.

## 4. Deliverable

Write `relay-system/2026-09-04/gh299-gen4-soak-agy.md` with:
- the six suite results from step 0
- the exact numbers from step 2 against the four bars
- the cluster table from step 3 (digest · members · rc · class · one-line why · suite rc)
- the parity divergence count and the three most common twin stderr heads
- any `contamination_events` / `errors` from the report, verbatim
- your verdict in one line: "Phase 5 gate: MET / NOT MET (which bar failed)"
- the Tier-1 anomaly rate (`counts.anomaly / mutations`) — the plan wants >95% classified
  deterministically, so anomaly rate must be < 5%; state the number

Commit ONLY that file plus the `$OUT/` directory (report, summary, telemetry.jsonl, synth/, logs):
```bash
git add "relay-system/2026-09-04/gh299-gen4-soak-agy.md" "$OUT"
git commit -m "test(ate): GH-299 Gen 4 3h soak evidence (agy) — <mutations> mutations, gate <MET|NOT MET>"
git push
```
The pre-push gate will run (~9 min). If it goes red, do not bypass it — leave the commit local
and put the gate's failing suite names at the top of your report file.

## 5. Hard rules

- Never run the campaign with `--sandbox-root` inside this clone; it refuses anyway.
- Never `git clean`, `git reset`, or `git checkout` in this clone; the sandbox is the only
  disposable tree.
- If the machine is needed (thermal / battery / user active), `kill $(cat $OUT/campaign.pid)`;
  the report is still written on the next batch boundary. Report the shorter duration honestly.
