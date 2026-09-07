---
gh_issue: 478
source: https://github.com/HiQS-Labs/XYZ-forge/issues/478
title: "GH-478 — ATE runaway-process guard: in-suite watchdog + standalone sweep"
status: "Active (2-WORKING — 2026-09-06, rev 3 after Codex plan QA rounds 1–3). Harness-side watchdog scope; engine-side termination cap deferred to its own effort."
created: 2026-09-06
updated: 2026-09-06
owner: noel
doc_type: bugfix
rating: "pri/sev/appeal/effort 80/80/50/65 · calc 275"
effort: 3
complexity: 2
risk: 2
phases: 1
ratings_provisional: false
goal: >
  No ATE invocation can hang past a bounded timeout inside a suite, and no ATE child's
  process group — including a leader-less one — can outlive its suite unnoticed. One
  shared Python runner (utils/py/proc_group.py) owns bounded process-group launching
  and killing for the ATE callers and the suite-layer guard alike; a standalone Python
  sweep finds and (only on an explicit flag) stops orphaned ATE leaders machine-wide.
non_goals:
  - The engine-side termination cap inside generate_pairwise (issue part 4 — a separate effort; on development @ 3f1d6f0c the incident call raises a TypeError in seconds rather than hanging, so the bound must be re-validated against the unmerged gen4 relay branch's 3-arg variant when it lands).
  - Wiring the guard into the unmerged gen4 relay branch's suites (lands with that branch; the standalone sweep covers it machine-wide in the meantime).
  - Retrying or re-running failed/timed-out engine calls; auto-killing anything without an explicit operator flag.
  - Modifying relay-automation/ (vendored into per-repo .xyz/ copies — the guard factors its proven pattern instead of editing the vendored core).
  - The sweep signals matched ATE LEADERS only; descendant cleanup outside guarded suites is the in-suite guard's job (group kill) and is deliberately out of scope for the sweep.
---

# GH-478 — ATE runaway-process guard

## Status

| What was just completed | What's next |
|---|---|
| Rev 3→4 2026-09-06: rounds 1–4 of Codex plan QA adjudicated and IMPLEMENTED — `utils/py/proc_group.py` is the one shared runner (`run_harness`/`execute` consume it; `fuzz_engine._kill_group` retired; the bash reaper kills only through the `--kill-pgid` seam, asserted statically by the suite); PGID tracking reaps leader-less groups and FORGETS completed ones (recycle-aliasing guard); fail-closed pgid publication on BOTH sides (proc_group kills its child + rc 125 on write failure; the bash seam refuses rc 2 without a proven numeric pgid) with a two-phase `--ack-file` handshake; token-aware sweep (script shapes, spaced `python -c` incident shape, non-Python `-c` refused) with `--limit-pids` containment; witnessed mutations in `test/baselines/GH-478-negative-control.md`. **BRANCH REBUILT to exactly 2 commits** (d16901d5 watchdog, 87492f18 sweep+governance) per the operator's fixed two-commit contract; relay thread (4 rounds, escalated at cap) committed as QA evidence. Verified: gh478 43/43, gh-gen4-phase2 18/18, gh142 30/30, gh-gen4-phase3 20/20, gh35-test-tiers 71/71; pdda zero errors; releases check clean. | **PAUSED 2026-09-06 for reboot — resume here:** (1) `./validate.sh` full gate on this final tree (the last full-gate run pre-dates the round-4 fixes; its interrupted successor was killed); (2) `git push -u origin fix/gh478-ate-runaway-guard` (the pre-push hook re-runs the gate); (3) open the PR against `development`, "Part of #478", stating relay QA status honestly: rounds 1–3 blockers fixed + witnessed; round-4 blockers (publication fail-open, recycled-PGID aliasing, duplicate bash killer, two-commit DoD, recheck wording, mutation-leak) FIXED in these commits but NOT re-reviewed — the relay escalated at its 4-round cap; offer raising the cap for a round-5 re-review. |

## Problem and evidence

2026-09-03 23:28 → 2026-09-06 ~20:26 local: `python -c "from utils.py.adaptive_ate import generate_pairwise ..."` (a gen4 adaptive-ate test snippet) ran **2d21h at ~90–98% CPU** (~67.6 CPU-hours) inside `marathon-clones/marathon-gh-299-gen4-ate`, blocking the `&&`-chained gen4 suites behind it the whole time. Detected only by a chance process-table inspection; no harness mechanism capped, reaped, or reported it. Full evidence in #478.

Reproduction note (recon, 2026-09-06): the incident's exact invocation does **not** hang on `development` @ `3f1d6f0c` — the merged gen4 API raises `TypeError` on that call shape within seconds. The hang lived in the unmerged gen4 relay branch's `generate_pairwise` variant. The watchdog is therefore defense-in-depth against any future hang of any origin, not a fix for a live development defect.

## Prior art — extend, don't duplicate

- `relay-automation/relay-turn-lib.sh:rtl_run_bounded` + `test/gh369-group-kill.sh` — the proven process model (setsid-style session leader, PGID == PID, group kill), which round 2 required consolidating rather than copying a fourth time. The consolidation landed as `utils/py/proc_group.py` (below); `relay-automation/` itself is untouched because it is vendored into per-repo `.xyz/` copies.
- `test/lib/fixture-guard.sh` — the sourceable, fail-loud shared-lib shape.
- `gh142-ate-exit-contract.sh` + `ATE_GH_TIMEOUT_S` — one Python-internal subprocess cap for one call site; generalized here, not replaced.
- `runner-envelope.sh` — brackets a *runner*; not a per-invocation watchdog. Untouched.
- `test/gh308-frozen-twin-guard.sh` — new executables belong in `utils/py/`; the sweep is Python under `utils/py/`.
- `test/gh204-sed-portability.sh` — in-place edits use the portable `sed -i.bak` + backup-cleanup idiom (caught by the full gate, fixed in 6929ea94).

## Requirements

- **R1 — one shared runner + guard library**:
  - `utils/py/proc_group.py` owns bounded process-group running for EVERYONE: `start_new_session=True` (PGID == PID, atomic at fork — the only portable way; macOS ships no `setsid`), wall-clock expiry → group TERM, grace, KILL; `run_bounded()` API for Python callers; CLI seam `--timeout/--grace/--pgid-file/--kill-pgid` for bash. pgid publication FAILS CLOSED: if the file cannot be written, the just-started group is killed and rc 125 returned.
  - `test/lib/runaway-guard.sh` (sourceable like `fixture-guard.sh`): `run_with_timeout <seconds> <cmd...>` delegates to proc_group.py, verifies its own scratch file and the published numeric pgid (refuses, rc 2, if either is unproven — the tracking boundary never fails open), returns **124** on a witnessed timeout, the child's rc otherwise; `runaway_guard_track <pgid>` + `runaway_guard_reap` — probe NEGATIVE pgids (a session group stays a valid kill target after its leader exits), kill through the `--kill-pgid` seam, announce each loudly, set `RUNAWAY_GUARD_REAPED=1`; errexit-safe by construction. `runaway_guard_init [<owner-cleanup...>]` installs ONE composed EXIT trap: capture incoming `$?`, reap, run the owner cleanup, exit the original status — or exit 1 when green-but-reaped. Refuses when an EXIT trap already exists unowned.
  - Cap override: `ATE_WATCHDOG_TIMEOUT` (default 300 s).
- **R2 — wiring**: `test/gh-gen4-phase2-adaptive-ate.sh` sources the guard, wraps every `adaptive_ate.py` engine invocation with `run_with_timeout`, and installs the composed trap via `runaway_guard_init cleanup` (no raw EXIT trap of its own). Other suites adopt the guard in their own changes.
- **R3 — registered suite** `test/gh478-runaway-guard.sh`, in `validate.sh`'s `TESTS` array AND `utils/ci-route.sh` `SUBSYSTEM_TESTS_ate`:
  - healthy-path red control (rc/stdout passthrough); hung child capped (rc 124, bounded wall clock, override named);
  - TERM-resistant grandchild dead (gh369 shape); LEADER-LESS group reaped at the EXIT trap (with a vacuousness guard);
  - reaper announce/no-op; composed-trap semantics (owner cleanup runs, original failure preserved, green-but-reaped exits 1); init refusal;
  - sweep: real script shapes (interpreter-present and interpreter-suppressed renderings), the spaced `python -c` incident shape, non-Python `-c` refused, basename/substring near-matches refused, age gate, dry run signal-free, `--kill` TERM + escalation under `--limit-pids` containment, self/ancestor exclusion;
  - witnessed mutations (timeout disabled under an independent emergency cap; matcher broadened; matcher narrowed) in `test/baselines/GH-478-negative-control.md`; pgid-publication failure is proven to fail closed.
- **R4 — standalone sweep** `utils/py/ate_runaway_sweep.py` (executable Python): one `ps -axo pid=,ppid=,uid=,etime=,lstart=,command=` snapshot; matching is TOKEN-AWARE on the whitespace-split command column (ps does not preserve argv — documented heuristic), accepting: a token whose basename is exactly `adaptive_ate.py` as argv[0] or preceded by a python-ish basename (macOS renders the interpreter `Python`, capital-P, or suppresses it entirely — both handled), or a python-ish interpreter before `-c` (or `-c` suppressed-leading) with the module mark `utils.py.adaptive_ate` in the remainder — the incident's spaced shape. Never a raw substring. UID-scoped, ancestors excluded, `--max-age-minutes` (default 30). Identity RECHECK before any signal: uid + lstart must match exactly (lstart is immutable — the recycling guard) and the snapshot command must be CONTAINED in the fresh command (shim re-exec legitimately grows the interpreter prefix — this containment contract is a deliberate, documented revision of the naive full-command equality). Dry run is the default; `--kill` is the explicit flag (TERM, `--grace-seconds` default 5, then KILL, every signal logged); `--limit-pids` is the containment lever the suite runs under. Matched ATE leaders only (see non-goals).
- **R5 — commit structure and greenness**: the branch carries TWO feature commits (watchdog; sweep+governance) plus scoped review-mandated follow-ups (the gh204 portability fix; round-3 reconciliation) and the relay protocol's own thread commit — each feature commit's tree is green under `./validate.sh`, `utils/pdda/pdda.sh run` zero new errors, `releases check` clean.

## Implementation order (as landed)

1. Commit 1 — shared runner + refactored callers + guard + wiring + suite + registration.
2. Commit 2 — standalone sweep + suite sweep cases + baseline + governance.
3. Follow-ups from QA/gate: gh204 portability fix; round-3 reconciliation (SUBSYSTEM_TESTS_ate re-registration, shape-B spaced fix, kill seam consolidation, fail-closed publication, plan coherence).
4. Round-4 relay review; push through the pre-push gate; PR against `development` ("Part of #478").

## Risks / rollback

- The guard changes a hot suite (`gh-gen4-phase2-adaptive-ate`): the 300 s default is orders of magnitude above observed engine-call durations; a trip is loud and fails the case rather than hanging the gate. The setsid mechanism is what the turn shims run in production (gh369-pinned).
- Refactoring `run_harness`/`execute` onto the shared runner changes timeout behavior from SIGKILL-only to TERM→grace→KILL (gentler, still bounded); their suites (gh142 30/30, fuzz-engine 20/20, phase2 18/18) pin the observable contracts (rc, timeout flags, result shapes).
- Trap composition, matcher renderings, recheck identity, and pgid publication each have a dedicated red control or fail-closed case.
- Rollback: revert the branch; no schema, no persistent state, no data migration.

## Rating rationale

`rated 80/80/50/65` — sev 80: silently work-blocking (the incident blocked the gen4 chain for ~3 days at one pinned core; no data loss, so not the top band); pri 80: severity-led, operator-directed now; appeal 50: neutral (operator did not supply a preference); effort 65: contained guard + suite + sweep across a handful of files, no schema or gate-machinery changes. Recurrence: first recorded incident of this class (no prior runaway reports in the 14-day window), but the failure mode is generic to every future engine loop bug — which is the argument for the machine-wide sweep, not a score multiplier.
