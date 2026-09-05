# RELAY · GH-299 Gen 4 ATE — final QA review (all 5 phases)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-04.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-299-gen-4-ate-final-qa-review-all-5-phases): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh299-gen4-qa-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-04

### Artifact — gh299-gen4-qa-brief.md
````
# GH-299 Gen 4 ATE — QA brief for the reviewer (agy)

Branch: `feat/gh299-gen4-ate` (5 phase commits on top of `development`).
Plan of record: `PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md` (read its Status + QA gates tables first).

## What landed (one module per phase, one suite per phase)

| Phase | Module | Suite | Claim to verify |
|---|---|---|---|
| 0 | `utils/py/telemetry_schema.py` | (embedded `--mode suite`) | one JSONL contract shared by every pillar; torn lines detected |
| 1 | `utils/py/domain_oracles.py` | `test/gh-gen4-phase1-domain-oracles.sh` | zero-state, host containment, idempotence, crash-recovery — each with a positive AND a negative control |
| 2 | `utils/py/adaptive_ate.py`, `utils/py/calibrate_tier1.py`, `utils/ate/tier1-calibration.json` | `test/gh-gen4-phase2-adaptive-ate.sh` | 12-flag grid → ≤200 cases, 100% valid 2-way coverage (independent brute-force walk); Tier-1 FN=0 on 50/20 benchmark; tier-2 never invoked on a clean run |
| 3 | `utils/py/fuzz_engine.py` | `test/gh-gen4-phase3-fuzz-engine.sh` | byte-identical seed replay; novelty-capped corpus; smaller-mutant-wins; parity oracle +/- controls; real twin run contained |
| 4 | `utils/py/repro_synth.py` (+ `repro_builder.py --mode synth`) | `test/gh-gen4-phase4-repro-synth.sh` | cluster-before-minimize: 50 same-cause rows → 1 suite; emitted suite passes while defect reproduces and FAILS after the fix |
| 5 | `utils/py/gen4_campaign.py` | `test/gh-gen4-phase5-campaign.sh` | bounded soak in a disposable clone: 0 contamination, host identity + tree unchanged; poison target caught and sandbox restored |

## How to verify (run these; do not trust the doc)

```bash
for m in telemetry_schema domain_oracles adaptive_ate fuzz_engine repro_synth gen4_campaign; do python3 utils/py/$m.py --mode suite | tail -1; done
python3 utils/py/calibrate_tier1.py --verify
for p in 1 2 3 4 5; do bash test/gh-gen4-phase$p-*.sh | tail -1; done
bash test/gh155-phase3-repro-builder.sh | tail -1      # Gen 3 minimizers must be untouched
```

## What to review hardest

1. **Negative controls are real, not vacuous.** For each oracle/classifier, confirm the "(-)" assertion would actually fail if the oracle were a no-op. Name any control that cannot fail.
2. **DRY against Gen 3.** `domain_oracles.py` must import `metamorphic_oracle` primitives, `repro_synth.py` must import `repro_builder` minimizers — flag any re-implementation.
3. **Host safety.** `check_host_containment` refuses a work root inside the host; `gen4_campaign.make_sandbox` refuses a sandbox inside the repo; `fuzz_engine.execute` kills the whole process group on timeout. Try to break each.
4. **Tier-1 honesty.** `calibrate_tier1.py` must exit 1 when FN=0 is unsatisfiable (the suite plants such a benchmark). Confirm the shipped calibration's `score.false_negatives == 0`.
5. **Registry.** All five suites appear in `validate.sh` TESTS and in `utils/ci-route.sh` `SUBSYSTEM_TESTS_ate`; `subsystem_of` maps the new modules to `ate`.
6. **What is NOT claimed.** The Phase-5 bar (>10,000 mutations, multi-hour) is recorded as owed in the doc and CHANGELOG. Confirm no sentence in the doc/CHANGELOG/PR claims it.

## Known findings already recorded (do not re-report; confirm they are recorded)
- 6/12 parity divergences between `codex-turn.sh` default and `XYZ_PYTHON=0` (doc Status row, CHANGELOG).
- `ci-route.sh` mutants classify 100% as Tier-1 *anomaly* (its error output is not usage-shaped) — a calibration gap for the soak triage.
- `validate.sh` removed from default campaign targets after a mutant ran the full gate inside the sandbox.

Verdict format: `APPROVE` or `CHANGES REQUESTED` with a numbered list — each item names a file:line and the exact command that demonstrates it.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
