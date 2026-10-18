# RELAY · gh1118-ci-leaderboard-recs
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1118-ci-leaderboard-recs): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: this thread's Round 1 block (a recommendation set for GitHub issue #1118, the CI experiments leaderboard). Read-only: no source files change.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: each of the three recommendations, the speed-up estimate and the re-test plan is either confirmed with the decisive evidence named, or dissented with a concrete counter-observation. No new tooling is proposed.  [Unverified — no citation]

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (agy)

**Goal.** Independent confirmation or dissent on three recommendations for #1118 (CI experiments leaderboard), an estimate of the whole-suite speed-up if they are followed, and a plan for when to re-measure before merging. Operational envelope: a single-maintainer repo with a ~400-suite local gate (`validate.sh`) and a hosted macOS reconcile; no CI budget team, no SLOs. Commensurate complexity applies: do not propose new frameworks, dashboards or suites.

**Evidence on the board (from #1118 and the linked issues; treat as data):**
- Full gate, sequential, quiet Mac: **36.2 min**. #1114 bounded parallel on the same set: **11.1 min** (one sample per arm; ShellCheck unavailable in both arms). #1114 on a loaded host: **19.6 min**, 406/406 suites, but green only after **four first-attempt failures were rescued by retry** (`gh360-scoped-receipt-chain-rebuild.sh`, `gh484-phase-dir-default.sh`, `gh648-l4-285-revalidate.sh`, `jog-queue.sh`).
- #1112 targeted subprocess/setup reduction: five covering suites **465.77 s → 62.17 s** (corrected after a false-pass fix); the marathon tier audit alone **111.52 s → 4.78 s**; twelve covering suites green; no full-gate comparison yet.
- #1111 / draft PR #1115: tier-routing audit process overhead **162.14 s → 79.10 s** (two samples per arm, same 7,412-path output); its candidate full gate was **408/409** with an unattributed PermissionError in `gh648-l4-285-revalidate.sh`; PR is evidence-only.
- #1114 bookkeeping skip: four solo bookkeeping runs = **59 min over 30 days**.
- #1076 / #1079 selective qualification: prototype, no adopted savings.
- A separate sequential full gate run today in a throwaway clone (merge batch #1103) took roughly **26 min** on a loaded host, 7,352 PASS lines, exit 0.
- Today's pre-push qualifying gate on PR #1116 reported **409/409 in 859 s (14.3 min)** — the operator should confirm which mode that gate ran in; if it was already parallel, #1114's 11.1 min quiet number is the comparable figure.

**Recommendations under review:**
1. **Add a cost column to the board** (full-gate runs consumed, review rounds, operator minutes per track) and cap each track at one more full-gate run before a continue/stop decision. Rationale: four experiments each burning 15–55 min gates to prove they save minutes.
2. **#1114 parallel: block adoption as a qualification gate until the receipt separates first-attempt failures from retry-rescued passes**; a rescued green hides flaky suites, and flaky suites hide regressions. Keep developing it; it is the only track that changes the hour-scale wait.
3. **Choose one of #1111 and #1112 by one comparable full-gate A/B; back only #1112's marathon-audit piece first** (111.5 s → 4.8 s, separable, independently revertible); park router batching and #1111 until that lands and is measured.

**Speed-up estimate under review (whole gate, quiet host, sequential 36.2 min baseline):**
- #1114 parallel alone: 36.2 → ~11.1 min (−69%), single sample, unverified on hosted macOS.
- #1112 marathon-audit piece: −107 s per run. In sequential mode that is −1.8 min (36.2 → ~34.4). In parallel mode it only helps if the audit sits on the critical path; otherwise ~0.
- Combined realistic range: **~9.5–11 min** when both land and the audit is on the parallel critical path; **~11 min** otherwise. Savings do not multiply. #1111 overlaps #1112 and adds nothing on top of it. The bookkeeping skip saves ~2 min/day of hosted time, not local wall time.

**Re-test plan under review ("measure twice or three times, cut once"):**
- Trigger: after #1112's marathon-audit piece is landed and #1114's receipt reports first-attempt failures and retry counts.
- Protocol: quiet host, same commit, A/B/B/A with three runs per arm (sequential vs parallel, both including the audit change); record executed-set identity, first-attempt failures, rescues, wall time. Then one hosted macOS parallel run on the same commit.
- Merge threshold: identical executed set in every run; zero first-attempt failures in at least 2 of 3 parallel runs with the third fully attributed; median parallel wall time ≤ 40% of median sequential; hosted run green without rescues.
- Stop rule: if two consecutive measurement rounds do not meet the threshold, park #1114 as a developer-local accelerator only (not the qualifying gate) and keep sequential as the gate.

**Questions (answer each; cite the issue/comment or number you rely on):**
1. Do you confirm or dissent on recommendation 1? Is a one-more-full-gate cap too tight for #1114?
2. Recommendation 2: is "no rescued passes in the qualifying receipt" the right bar, or is a bounded retry acceptable if first-attempt failures are reported? Name the risk you weigh.
3. Recommendation 3: is choosing the marathon-audit piece first correct, or does #1111's smaller surface deserve the slot? Give the deciding observation.
4. Is the combined speed-up estimate (~9.5–11 min from 36.2) sound given the samples available? What single measurement would most change it?
5. Is the re-test protocol sufficient and proportionate (3 runs per arm + 1 hosted)? Would you cut or add a step?
6. Anything on the board that should be stopped outright today?

Grade each answer [Confirm]/[Dissent]/[Nit]; a Dissent must carry Observed input / Affected scope / Falsifier. End with VERDICT: PASS and STATUS: Approved if the recommendation set stands as amended by your Nits, otherwise VERDICT: FAIL with the amendments required.

### Reviewer · Round 1

swept file: yes

- [Pass] **Evidence check on PR #1116's 859 s (14.3 min) run (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:81`):** We do not need to wait for operator confirmation on which mode PR #1116 ran in — the retained telemetry is committed in this tree at `TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz:1` (`SUMMARY.md:61`) and proves PR #1116's 859 s run executed in `"mode": "parallel", "width": 4, "tier": 3, "registered": 406` with `0` retries (`"passed": 409, "failed": 0, "total": 409`), because `githooks/pre-push:299` invokes `./validate.sh` with its `validate.sh:696` 4-wide balanced parallel default.
  - Probe command (exit `0`):
    ```sh
    export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"
    python3 -c 'import gzip,json; rows=[json.loads(l) for l in gzip.open("TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz","rt") if l.strip()]; s=[r for r in rows if r.get("event")=="run.start"][0]; u=[r for r in rows if r.get("event")=="run.summary"][0]; rt=[r for r in rows if r.get("event")=="retry" or r.get("lane")=="retry"]; print("start=",s["mode"],"width=",s["width"],"dur_s=",round((u["ts_ms"]-s["ts_ms"])/1000,2),"retries=",len(rt))'
    ```
  - Decisive output: `start= parallel width= 4 dur_s= 858.47 retries= 0`
- [Pass] **Q1 — Recommendation 1 (cost column + 1-more-full-gate cap) (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:84,100`):** `[Confirm]` on adding the cost column (`full-gate runs consumed`, `review rounds`, `operator minutes per track`) and capping `#1111`, `#1112`, and `#1076/#1079` at one more full-gate run before a continue/stop decision. `[Nit]` for `#1114`: a literal 1-run cap conflicts with the Re-test Plan (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:95`), so phrase the cap as **at most 1 more diagnostic full-gate run during implementation**, plus the fixed qualification re-test budget (amended in Q5) once the receipt separates first-attempt failures from rescues.
- [Pass] **Q2 — Recommendation 2 (#1114 parallel qualification bar) (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:85,101`):** `[Confirm]` that **"no rescued passes in a qualifying receipt" (`retries == 0` / `CONTENDED == 0`) is the right bar for a qualification gate** (`utils/py/wave_reconcile.py:496-528`, `ci-local.sh:435`), while bounded retry (`vp_rerun_alone` in `validate.sh:1347-1371`) stays acceptable only in the developer-local pre-push guard (`githooks/pre-push:21-24`). Today, `validate.sh:1357-1362` appends retry-rescued suites to `PASSED+=("$t")` and `CONTENDED+=("$t")`, and `validate.sh:1587` writes `.xyz/receipts/<sha>.json` via `utils/py/gate_receipt.py:28-43` with `--exit-code 0 --passed "${#PASSED[@]}" --total "$TOTAL"`, omitting `CONTENDED` / retry counts altogether.
  - **Risk weighed:** Allowing bounded retries inside a *qualifying* receipt merely because `first_attempt_failures` is logged turns `valid_pass_receipt` (`utils/py/gate_receipt.py:54-56`) into a flake/race amnesty: automated consumers (`utils/py/wave_reconcile.py:531-571`) gate on `exit_code == 0`, so a real concurrency race, unserialized driver-lock caller (`validate.sh:1254`), or OS-level process-group bug (`test/gh648-l4-285-revalidate.sh:148`, where `os.killpg(proc.pid, 0)` only catches `ProcessLookupError` and not macOS `PermissionError`/`EPERM` on a zombie/exiting pty leader) gets stamped green. `AGENTS.md` ("A flaky suite is fixed in place if it is in a tier, and turned off if it is not") already forbids carrying flaky suites in qualifying tiers; `first_attempt_failures > 0` in `gate_receipt.py` must therefore mark the receipt non-qualifying (`qualifying: false`).
- [Pass] **Q3 — Recommendation 3 (#1112 marathon-audit piece first vs #1111) (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:86,102`):** `[Confirm]` backing `#1112`'s marathon-audit piece (`test/marathon-root-audit.sh`, `111.52 s → 4.78 s`, `-106.7 s` sequential) first and parking `#1111` + `#1112` router batching.
  - **Deciding observation:** `test/marathon-root-audit.sh:27-31,406-408` is a self-contained static test scanner (reading every `test/*.sh` line-by-line in bash regex) that touches **zero** production routing code (`utils/ci-route.sh`) and is not in `SUBSYSTEM_TESTS_small` (`utils/ci-route.sh:38`), giving it a single-test-file blast radius and a `-96%` runtime reduction (`93.49 s` in PR #1116's parallel run `TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz:1`). By contrast, both `#1111` (`162.14 s → 79.10 s`, `-51%`, which also hit the `gh648-l4-285-revalidate.sh` `PermissionError` in PR #1115) and `#1112`'s router-batching piece target the 7,412-file loop in `test/gh365-tier-fail-closed.sh:39-51` / `utils/ci-route.sh:75-133`, where `#1112` already suffered a false-pass bug (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:76`).
- [Nit] **Q4 — Combined speed-up estimate (`~9.5–11 min` from `36.2 min`) and critical-path mechanics (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:88-91,103`):** `[Confirm]` the headline `~9.5–11 min` quiet-host range (and `~14.0–14.3 min` on a typical dev host per PR #1116's `858.47 s` parallel run), with two factual `[Nit]` amendments from `TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz`:
  1. **In `xargs -P 4` (`validate.sh:1311`), `marathon-root-audit.sh` savings divide by worker width (`~-22.4 s`), not `-107 s` or `0 s`, and `#1111` (`test/gh365-tier-fail-closed.sh`) is a distinct suite from `test/marathon-root-audit.sh`.** All 4 workers stay 100% saturated from `t = 0 s` until `+735.36 s`; `marathon-root-audit.sh` (`validate.sh:302`, `93.49 s`, `+286.83 s → +380.32 s`) and `gh365-tier-fail-closed.sh` (`validate.sh:291`, `140.42 s`, `+264.55 s → +404.97 s`) both execute mid-run. The actual tail critical path is `gh436-merge-cleanup.sh` (`validate.sh:606`, `220.10 s`, starting late at `+620.93 s` and finishing at `+841.03 s`, `65–105 s` after the other 3 workers drain at `+736.17 s..+775.89 s`), followed by serial `python:test_python_layer.py` (`16.25 s`, `+842.02 s → +858.27 s`). Shrinking `marathon-root-audit.sh` from `93.49 s → 4.78 s` pulls `gh436-merge-cleanup.sh`'s dequeue earlier by `~88.7 s / 4 = 22.39 s` (`837.81 s → 815.42 s` in 4-worker replay).
  - Probe command (exit `0`):
    ```sh
    export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"
    python3 -c 'import gzip,json; rows=[json.loads(l) for l in gzip.open("TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz","rt") if l.strip()]; s0=[r["ts_ms"] for r in rows if r.get("event")=="run.start"][0]; pool=sorted([r for r in rows if r.get("event")=="suite" and r.get("lane")=="pool"], key=lambda r:int(r["started_ms"])); w=[0]*4; [w.__setitem__(min(range(4),key=lambda i:w[i]), w[min(range(4),key=lambda i:w[i])]+(4780 if r["name"]=="marathon-root-audit.sh" else int(r["duration_ms"]))) for r in pool]; print("pool_sum_s=",round(sum(int(r["duration_ms"]) for r in pool)/1000,2),"tail=",[(r["name"],round((int(r["started_ms"])-s0)/1000,1),round((int(r["ended_ms"])-s0)/1000,1)) for r in sorted(pool,key=lambda r:int(r["ended_ms"]),reverse=True)[:3]],"sim_with_1112_s=",round(max(w)/1000,2))'
    ```
  - Decisive output: `pool_sum_s= 3074.17 tail= [('gh436-merge-cleanup.sh', 620.9, 841.0), ('gh280-jog-marathon-adapter.sh', 631.8, 775.9), ('gh589-xyz-mini-sync.sh', 720.0, 737.8)] sim_with_1112_s= 815.42`
  2. **Single measurement that would most change the estimate:** Locally, measuring `validate.sh` with the late heavy suites (`gh436-merge-cleanup.sh` at `validate.sh:606`, `gh280-jog-marathon-adapter.sh` at `validate.sh:618`) moved to the top of `TESTS` so `xargs -P 4` schedules them first instead of stranding one worker for the final `103 s` (would drop up to `~70 s` of tail idle overhang toward the `768.5 s` 4-worker mean). For hosted CI, one `macos-latest` parallel timing sample (`ci.yml:124,157`: 3-core runner currently taking `60–92 min` sequentially).
- [Nit] **Q5 — Re-test protocol (`3 runs per arm + 1 hosted`) (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:93-97,104`):** `[Nit]` — `3 sequential + 3 parallel` full runs (`~2.5–3 hours` of quiet-Mac wall time) plus a hosted `macos-latest` run (`ci.yml:125`: `$4.65` per 75 macOS min, ~10x Linux) is too heavy for a single-maintainer envelope (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:72`) and undercuts Recommendation 1. Amend the protocol to:
  1. **Add a 30-second focused pre-check before any full gate:** Fix the unguarded `PermissionError` in `test/gh648-l4-285-revalidate.sh:148,159` (`except (ProcessLookupError, PermissionError):`) and run the 4 previously rescued suites (`gh360-scoped-receipt-chain-rebuild.sh`, `gh484-phase-dir-default.sh`, `gh648-l4-285-revalidate.sh`, `jog-queue.sh`) concurrently in a disposable clone first.
  2. **Cut local arms from `3 seq + 3 par` (`A/B/B/A`) to `1 seq + 2 par` (`A/B/B`) on the same commit** (~60 min total instead of ~150 min; PR #1116's `858.47 s` 0-retry run at `TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz:1` already provides one clean 409/409 parallel sample today).
  3. **Tighten the merge threshold from "0 first-attempt failures in ≥2 of 3 parallel runs" to "0 first-attempt failures (`CONTENDED=0`, `FAILED=0`) in 2/2 back-to-back parallel runs"** (if 1 of 2 has a contended failure, fix the suite's isolation/lane placement first rather than accepting a 33% rescue rate into the qualifying gate).
- [Pass] **Q6 — What on the board should be stopped outright today (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:77-79,105`):** `[Confirm]` stopping three items today:
  1. **`#1076 / #1079` selective qualification prototype** (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:79`): stop outright — `utils/ci-route.sh:38` (`SUBSYSTEM_TESTS_small`) and `utils/py/wave_reconcile.py:593-619` (`select_qualification_gate`, GH-831 D5) already ship deterministic Tier-1 Small vs Tier-3 Full qualification routing, and `AGENTS.md` ("No new tests (GH-831)... Do not add new gate machinery: guards, lanes, runners or telemetry stages") bars new selector machinery.
  2. **`#1111` / draft PR `#1115`** (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:77,86`): close/stop outright — superseded by `#1112` and only evidence-only.
  3. **`#1112`'s router-batching half** (`relay-system/2026-10-17/gh1118-ci-leaderboard-recs.md:86`): park/stop until `test/marathon-root-audit.sh` lands alone; in 4-wide parallel mode `test/gh365-tier-fail-closed.sh:39-51` (`140.42 s` at `validate.sh:291`) contributes only `~20 s` of net wall time (`837.81 s → 817.40 s` in 4-worker replay) and does not justify touching `utils/ci-route.sh` now.

VERDICT: PASS
Basis: All three recommendations, the `~9.5–11 min` quiet-host (`~14.0–14.3 min` normal-host) speed-up estimate, and the re-test/stop rules are confirmed against `validate.sh:1254-1589`, `utils/py/gate_receipt.py:28-56`, `utils/py/wave_reconcile.py:463-619`, and today's committed 4-wide parallel telemetry in `TESTS-RESULTS/2026-10-17+GH-1108/final-approved-gate-telemetry.jsonl.gz:1`, with non-blocking `[Nit]` refinements on the 4-worker critical-path math (`gh436-merge-cleanup.sh` tail straggler vs `marathon-root-audit.sh` `1/4` pool share) and a leaner `1 seq + 2 par` (`0/2` rescues) re-test budget.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
