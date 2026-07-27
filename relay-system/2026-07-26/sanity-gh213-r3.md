# RELAY · Sanity check: GH-213 memory-pressure defence plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-26.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(sanity-gh213-r3): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **GH-213-MEMORY-PRESSURE-DEFENCE.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-26

### Artifact — GH-213-MEMORY-PRESSURE-DEFENCE.md
````
# GH-213 — Memory-pressure defence

> Issue: https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/213
> Status: **proposed** — awaiting decision on Option A vs B. Codex sanity check pending.

**Component**: `utils/job_guard.py`, `utils/3-eyes`, `temp/memory-issues/`

## The ask, and the recommendation against most of it

After the 2026-07-25 / 2026-07-26 machine stalls (#209, #210) the obvious next step looked
like: stand up continuous memory monitoring — sampler → thresholds → Gemma classification →
routed alert, as a 3-Eyes registry job.

**Recommendation: don't build that.** Do the two-line-of-defence version instead. Reasons below.
The full version is specced in Option B if we decide the cheap version is insufficient.

## Why the big version is the wrong first move

**1. Monitoring is a workaround for a missing guard.** `job_guard.py` already *is* this
watchdog: memory ceiling → trip → kill → log to `job_rss.jsonl`. It didn't fire on 07-26 for
two specific, fixable reasons (#210): it reads RSS (31 MB observed vs 46.9 GB actual), and it
only evaluates on exit (a hung job never exits). Fix those and the collector dies at its
ceiling. There is no incident to detect, no alert to route, no classifier to invoke.

A monitor that reports "a job ate 46 GB" is strictly worse than a guard that stopped it at 4.

**2. The classifier has nothing to classify.** The sampler already writes the answer:

```bash
sort -t, -k3 -rn ~/Library/Logs/sysmem/sysmem-group-$(date +%F).csv | head -3
```

Top row is the culprit, by name, with a footprint. A 12B model would restate that in prose.
Gemma earns its keep on ambiguous, multi-source evidence — log-pattern triage, contradictory
health signals. "Which process is largest" is a `sort`.

**3. It adds a system to the incident surface.** A 3-Eyes job means a registry entry, a
`commands.allow` line (an operator-only edge, per its own docs), routes, breakers, relief
valves, dashboard regeneration, and a new failure mode where the monitor is wedged and nobody
notices — which is exactly what happened to the sampler itself on 07-26, wedged in `xpcproxy`
reporting `launchctl list` status 0.

**4. The expensive part already runs.** The sampler is installed
(`com.neochro.sys-mem-attribute`), holds ~25 MB, `Nice 10` / `Background`, and writes daily
rotated CSVs kept 21 days. Forensics are covered. What was missing on 07-26 was not the
ability to *see* the problem — it was anything that would *stop* it.

## Option A — recommended

**A1. Fix the guard (#210).** Swap `tree_rss_bytes()` for `phys_footprint` via
`proc_pid_rusage(2)` (ctypes, stdlib, no new dependency — working implementation in
`temp/memory-issues/sys-mem-attribute.py`). Keep RSS as the fallback where `rusage` returns
EPERM, and record which source produced each reading.

**A2. Evaluate running jobs, not just finished ones (#210).** The guard already polls; it just
doesn't act until exit. Add a wall-clock ceiling so an hourly job alive for 2.5 h is killed by
its own harness.

**A3. Put the two collectors under the guard (#209).** Neither `daily_sync.sh` nor
`github_sync.sh` invokes `job_guard` today.

**A4. One threshold in the health path — no new job.** `rebalance doctor` / the existing
`collector-health` job already runs and already files issues. Add one check reading the
sampler's newest `sysmem-sys-*.csv` row:

```python
# ponytail: one rule, existing job. A 3-Eyes job of its own only if this proves too coarse.
if row.free_gb < 1.0 or row.swap_used_gb > 32 or row.disk_free_gb < 90:
    warn(f"memory pressure: free={row.free_gb}GB swap={row.swap_used_gb}GB "
         f"disk_free={row.disk_free_gb}GB; largest={top_group_from_csv()}")
```

Thresholds are grounded in measurements, not guesses: `disk_free < 90 GB` because swap could
not grow at 30 GB free; `swap_used > 32 GB` is half of installed RAM (64 GB) and was 67 GB
during the stall; `free < 1 GB` because exec starvation began around 71 MB.

**Cost:** one metric change, one loop condition, one call-site each in two shell scripts, one
threshold. No new scheduled job, no `commands.allow` edit, no dashboard change, no model.

## Option B — the full 3-Eyes job, if A proves insufficient

Only worth it if we find real cases where the *machine* is starving but no single guarded job
is responsible — i.e. aggregate pressure across unguarded processes (Chrome, Docker, LM
Studio, a dozen VS Code windows). A1–A3 cannot catch that class; A4 detects it but only
reports.

Then: `registry/jobs.d/memory-pressure.toml` reading the sampler CSVs, `fire_when` on the
thresholds above, `routes = ["notify", "pdda-inbox"]`, breakers `single_instance` +
`trip_after_failures = 3`, relief `llm_daily_max` small. Gemma classifies **only** on breach —
never polling — and only where there's genuine ambiguity (which of several large groups is
anomalous *for this machine*, given 21 days of history). On 64 GB the model's ~9 GB resident
cost is unremarkable when the machine is healthy; the constraint is that it must never be
invoked while free memory is the scarce resource, which a breach-only trigger inverts. That
inversion is the main design risk in Option B and the main reason to prefer A.

Requires an operator edit to `registry/commands.allow`.

## Success criteria

- A recurrence of #209 is terminated by `job_guard` and appears as a `tripped_reason` row in
  `job_rss.jsonl` — no human involvement, no machine stall.
- `sysmem-*.csv` still holds the forensic trail for anything the guard doesn't own.
- No new scheduled job unless Option B is explicitly triggered by evidence.

## Sequencing

1. #210 (metric + running-job evaluation) — unblocks everything, smallest diff.
2. #209 A3 (put collectors under the guard) — depends on 1 being correct.
3. A4 threshold — after 1–2 are running, so it only fires on what the guard can't own.
4. Option B — only on evidence from 3.

## Open questions

- Does anything besides the two collectors need guarding? `three_eyes observe` /
  `CATALOG.md` lists 40 launchd agents; most are small, but that's unmeasured.
- Is the 46 GB allocation a bug in our code or in a dependency (the `multiprocessing` +
  model-fetch path in `daily_sync`)? A1–A3 contain the blast radius either way, but the root
  cause in #209 is still unknown.

## References

- #209 — the collectors that hang and leak ~46 GB
- #210 — the RSS blind spot that let it through
- `temp/memory-issues/TRIAGE-LOG.md` — incident write-ups (2026-07-25, 2026-07-26)
- `temp/memory-issues/sys-mem-attribute.py` — installed sampler; reference `proc_pid_rusage` impl
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · r1

- [Blocker] The Definition of Done is still the literal placeholder `_<fill in the acceptance criteria the Reviewer grades against>_`, so this relay has no agreed, testable bar for approving the plan. Fix: replace it with measurable acceptance criteria covering (at minimum) correct `phys_footprint`/fallback provenance, live-job termination and `tripped_reason` logging, both collector call sites, and the health-path threshold.
- [Should] A4 refers to the sampler's newest `sysmem-sys-*.csv` row, while the stated forensic command reads `sysmem-group-$(date +%F).csv`; that leaves the proposed implementation without a deterministic input filename/schema. Fix: name the canonical file pattern and required columns once, then use that same contract in A4 and the success criteria.
- [Should] A1 replaces tree RSS with per-PID `proc_pid_rusage(2)`, but it does not specify whether the guard aggregates descendants or how it selects the process to kill. The previous function name, `tree_rss_bytes()`, implies that child-process memory is material to the incident. Fix: explicitly require descendant traversal/aggregation (or document why the guarded PID includes all workload memory), define EPERM behavior per process, and state that the kill targets the guard's job process group.

**Verdict: Changes requested.**

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
