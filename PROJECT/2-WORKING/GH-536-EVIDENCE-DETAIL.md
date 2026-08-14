---
gh_issue: 536
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/536
title: "Atomic local test runner — ci-local.sh should run tests and record results in one step"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
ratings_provisional: true
goal: >
  Make the gate-evidence record carry an output hash and per-suite verdicts, so a reader can tell
  "the suite ran and passed" from "someone stamped green" — without changing what the record is
  allowed to mean.
---

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-14** on `fix/gh536-gate-evidence`. `gate-record.sh` gained optional `--suite-log` and `--verdicts`; `ci-local.sh` captures both and passes them through. `test/gh536-evidence-detail.sh` is **19/0** and registered; `gh509-gate-evidence` still 17/0. | Operator review, and a decision on the issue's framing — three of its four premises were factually wrong (see below), so it wants retitling rather than closing. |

## Why

The issue proposed creating `ci-local.sh` as an atomic pipeline. **`ci-local.sh` already exists** —
added by `d4d2a39f` on 2026-08-11 16:49, over two days before the issue was filed on 2026-08-13
22:50 — and already implements three of its five numbered requirements:

1. *Refuse if dirty* — delegated to `gate-record.sh`, which refuses with exit 3.
2. *Run `validate.sh` and capture output* — `ci-local.sh:262`.
4. *Never write green after a failed run* — **stronger than the issue assumes.** On any failed step
   the script `exit 1`s at line ~274, which is *before* the record block at ~283. The record is
   unreachable after a failure, and `--fast`/`--probe` runs deliberately do not record either.

`utils/gate-status.sh:59` pointing at `./ci-local.sh` is therefore correct advice, not a dangling
reference.

**What was genuinely missing is requirements 3 and 5**, and the criticism behind them lands: the
record was six lines whose only claim about the run was `result: green` — a bare assertion about
output that no longer exists by the time anyone reads it.

## Key concepts

- **Tamper-evident is not attested, and the difference is the whole design.** The issue argued that
  an automated pipeline hashing its own results is "a meaningfully different trust level" and the
  `NOT-promotion-evidence` disclaimer could soften. **Rejected.** A hash computed on your own
  machine over output you produced proves diligence, not provenance — someone can stub a suite and
  hash the doctored result. GH-509's reasoning is about attestation, which is why promotion needs a
  machine that is not yours. The suite **pins** the disclaimer so a future edit cannot quietly drop
  it.
- **`PIPESTATUS[0]` is load-bearing** in the capture: `bash test/$t | tee -a` makes `$?` tee's
  status, so a failing suite would be recorded as passing. `pipefail` is set 150 lines away; reading
  PIPESTATUS directly says which element is under test.
- **Degrade honestly.** With no flags the record states `output-sha256: unavailable (...)` rather
  than omitting the line — a missing field reads as an older format, a stated absence cannot.

## Acceptance

Authored by this lane against the issue's numbered "Recommended solution", scoped to the two items
that were not already implemented.

1. The evidence record carries a SHA-256 of the suite transcript. **[met]**
2. The record carries per-suite verdicts, distinguishing pass / FAIL / skip. **[met]**
3. `ci-local.sh` captures both and passes them to `gate-record.sh` in the same run. **[met]**
4. A failing suite cannot be recorded as passing through the capture pipeline. **[met — PIPESTATUS]**
5. The existing dirty-tree refusal is unchanged and still observed. **[met — suite case 4]**
6. The `NOT-promotion-evidence` disclaimer is unchanged and pinned by a test. **[met]**
7. A caller passing no flags still records, and says what is missing. **[met]**

## Acceptance — deviations from the issue

- [dropped] "Create `ci-local.sh` as an atomic pipeline" (requirements 1, 2, 4) — reason: already
  implemented before the issue was filed; verified in the tree rather than assumed.
- [dropped] Treating hashed local evidence as a higher trust level — reason: a self-computed hash is
  tamper-evident, not attested; adopting it would make the hosted-macOS boundary optional, which is
  the exact circularity GH-509's agy review rejected.

## Note on how the issue went wrong

Worth recording because it will recur: a `find`/`grep` for `ci-local.sh` through this repo's RTK
proxy returns **empty even though the file is present**. The same false negative hit this session
three separate times (`ps`, `git status`, and the `find` for this very file) before switching to
`/bin`-absolute commands. Upstream `rtk-ai/rtk` fixed exactly this class in **v0.43.0** (`grep: run
the invoked engine instead of substituting rg for grep`, `grep: surface the engine error and exit
code`, `git: propagate exit code on git status failure`); this machine runs **0.42.2**.
