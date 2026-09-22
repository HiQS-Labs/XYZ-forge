# Marathon Phase p3
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P3-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L3 brief — #732 A.1–A.5: dated timing claims; render the per-suite timings the gate already records (umbrella #749)"
status: "Brief (input to the GH-749 marathon — not a tracked plan)"
created: 2026-09-22
updated: 2026-09-22
owner: Noel Saw
goal: >
  The docs stop promising gate times nobody measures, and validate.sh's own summary shows where the
  wall-clock went — from the GH-365 telemetry it already writes, without a new timing facility.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/749
  - https://github.com/HiQS-Labs/XYZ-forge/issues/732
  - https://github.com/HiQS-Labs/XYZ-forge/issues/365
---

# L3 — #732 A.1–A.5: dated timing claims + render the timings the gate already records

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-22) | Phase p3 fires after p2 is approved; p4 follows (both edit `validate.sh`) |

Umbrella: #749 · Issue: #732 items A.1, A.2, A.3, A.4, A.5 · Phase p3 · `depends_on: p2`

## Ground truth (verified at `origin/development` a0776330)

- Stale timing prose: `AGENTS.md:180` ("parallel by default (~4–6 min …"), `ROUTER.md:63` ("`--sequential` (~16 min)"), `ROUTER.md:89-90` ("a 16-minute gate … 3-minute one"), `githooks/pre-push:9-10` ("~4 min on a 10-core host … ~16 min"). Observed 2026-09-17→21: 18–23 min full at 4-wide, 648 s tier 2 (#732 body table).
- The hook already prints measured lines: `githooks/pre-push:262/:279/:296` — `docs|tier 2|full gate GREEN in Ns`.
- Telemetry already exists (GH-365): `validate.sh:1263` calls `rt_suite` per pooled suite; `test/lib/runner-telemetry.sh:146` writes one JSON record per suite with `"event":"suite"`, `"lane":"pool|driver-lock|sequential"`, `"name"`, `"duration_ms"`, `"rc"`; the serial re-run ladder `vp_rerun_alone` (`validate.sh:1326`) emits `"lane":"retry"` records at `:1341/:1348`. The file path is `$RT_FILE`, printed at `validate.sh:1519` ("telemetry: …"). The summary block is `validate.sh:1516-1525` (`rt_summary`, then `passed: N / TOTAL`).
- Width levers: `XYZ_VALIDATE_MAX_JOBS` applied at `validate.sh:932`, `--burst` at `:980`, both before the tier-2 default at `:994-996` which only fires when `PARALLEL_JOBS` is still empty — so the levers already work for tier 2 (A.4's earlier framing was wrong; the issue says so).
- Workers run `nice -n 10` (`validate.sh:697`); nothing in the rails says "one gate at a time on a host" (A.5).

## Deliverables (the lane's write-set — nothing else)

1. **A.1 — `AGENTS.md`, `ROUTER.md`, `githooks/pre-push`**: replace each undated estimate with either a pointer to the hook's measured `GREEN in Ns` line, or a number that carries the date, host class and width of a same-week run (use the #732 body table: 2026-09-17→21, 12-core macOS, 4-wide, 18–23 min full / 648 s tier 2 / 74–82 s docs). Do not add a new evergreen number. Keep every other sentence in those paragraphs intact.
2. **A.2 + A.3 — `validate.sh` summary**: after the `telemetry:` line (`:1519`), print a **"10 slowest suites"** block read from `$RT_FILE`: `event=suite` records only, lanes `pool|driver-lock|sequential` — never `lane=retry` (A.2 acceptance: retries are not double-counted) — each suite once (its first attempt), sorted by `duration_ms` desc, `name  duration_s  rc`. Then one line **"re-run ladder: N suite(s), Ss total"** summed from the `lane=retry` records (A.3: show the cost, keep the guarantee — do **not** change `vp_rerun_alone`'s serial, alone semantics). Implement with the same tools the file already uses for the telemetry summary (`grep`/`awk`/`sort`, see `_rt_count` at `:1509`); no new dependency, no Python, no new library file. Tag the block `GH-732`. Empty/absent `$RT_FILE` prints nothing extra and never changes the exit code.
3. **A.4 + A.5 — one sentence each** in the `--help` text of `validate.sh` and in `ROUTER.md`'s command rails: (A.4) `--burst` / `XYZ_VALIDATE_MAX_JOBS` are honoured for tier 2 — 2 is the default width, not a pin; (A.5) run one gate at a time on a host: a concurrent relay turn, second gate or pollers lengthen the run (`nice` protects the editor, not the wall-clock).
4. **`test/gh732-l3-gate-summary.sh`** — new suite, registered in `validate.sh`'s `TESTS` array (bidirectional gh35 tier guard: an unregistered `test/*.sh` turns the suite red). It feeds a **fixture JSONL** (synthetic records: ≥12 `event=suite` across the three lanes with distinct durations, ≥2 `lane=retry` records for suites that also have a pool record, one `event=summary`) through the new rendering path and asserts: exactly 10 rows, descending, retry records excluded from the rows, the re-run line's count and total match the fixture, and a missing file renders nothing. Do not run a live gate inside the test.

## Rules

Shortest diff (`/ponytail`): extend the existing summary; no new timing facility, no new telemetry event, no change to `rt_suite`/`runner-telemetry.sh`. Evidence under `TESTS-RESULTS/2026-09-22+GH-732/l3/` with the fixture, the rendered block, and `provenance.jsonl`. `bash validate.sh` green is the phase gate — its own summary must now show the new block (paste it into the evidence).

## Acceptance / Guard

- `grep -n '4–6 min\|~16 min\|16-minute\|3-minute\|~4 min' AGENTS.md ROUTER.md githooks/pre-push` returns no undated estimate.
- `test/gh732-l3-gate-summary.sh` green; a fixture where a retried suite's retry is slower than its first attempt still lists the first-attempt duration (retry excluded).
- `bash validate.sh --help` and `ROUTER.md` each carry the A.4 and A.5 sentences.
- Full gate summary in the clone shows the block and the re-run line; exit code semantics unchanged.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): AGENTS.md, ROUTER.md, githooks/pre-push, validate.sh, test/gh732-l3-gate-summary.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick claim MARATHON-P3-TURN --agent codex --paths "marathon-system/gh749-relay-gate-cost--p3/RELAY.md,AGENTS.md, ROUTER.md, githooks/pre-push, validate.sh, test/gh732-l3-gate-summary.sh"
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick ping MARATHON-P3-TURN --agent codex
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick release MARATHON-P3-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh749-relay-gate-cost--p3/RELAY.md and AGENTS.md, ROUTER.md, githooks/pre-push, validate.sh, test/gh732-l3-gate-summary.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: AGENTS.md, ROUTER.md, githooks/pre-push, validate.sh, test/gh732-l3-gate-summary.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick release MARATHON-P3-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick done MARATHON-P3-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick
   Edit ONLY marathon-system/gh749-relay-gate-cost--p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented A.1–A.5 in AGENTS.md, ROUTER.md, githooks/pre-push, validate.sh, and the new registered test/gh732-l3-gate-summary.sh.

- Replaced undated timing estimates with the hook’s measured `GREEN in Ns` output; documented tier-2 width overrides and one gate per host.
- Added the GH-732 summary directly after `telemetry:` using awk/sort over existing GH-365 records. First suite attempts across pool/driver-lock/sequential appear once, descending, capped at ten; retry suite records supply the separate count and cumulative seconds. The paired `event=retry` records are excluded to avoid doubling cost. Retry execution and verdict handling are unchanged.
- Added an early `--help`/`-h` handler for the existing usage text (previously no help handler existed), so help does not run gate setup or git/worktree checks.
- Focused fixture test PASS: twelve suites across all three lanes, duplicate first-attempt name, slower retries, paired retry events, summary/unrelated lane exclusions, exact ten-row output/order/durations/rc, missing/empty file silence, and help guidance. Bash syntax checks PASS. Stale timing-pattern scan found no matches.
- Witnessed negative controls: reversed sorting → rc 1; including both suite and retry events → rc 1; restored renderer → rc 0. Outputs and local provenance are in `.relay-scratch/`; these are temporary verification, not committed gate evidence.

Full gate intentionally not run under the turn’s explicit restriction. The harness must run the gate against the final state and retain the required TESTS-RESULTS evidence; that destination is outside this turn’s allowlist. No git commands run. Only the mandated NEXT metadata was updated above this appended block.

Next: agy reviews the implementation and focused checks; harness owns the full gate and commit.
