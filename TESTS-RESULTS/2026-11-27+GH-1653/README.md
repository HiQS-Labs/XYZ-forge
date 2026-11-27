# GH-1653 verification — Jog books its own gate attempt for receipt publication

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1653 · Plan: `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md` ·
Plan QA: `relay-system/2026-11-27/gh1653-plan-qa.md`. Base `52813e56f`; implementation `8164e2ec1`, test fix `e9127b18`.
No new suite or registry entry (GH-831): focused cases were added to the existing `test/gh280-jog-marathon-adapter.sh`.
All runs in disposable full clones, never the primary.

## Results

| Check | Command | Result |
|---|---|---|
| Focused suite, fix | `bash test/gh280-jog-marathon-adapter.sh` at `ad6e5a6bd` (merged with `origin/development` incl. PR #1669) | **262 pass, 0 fail** (`gh280-green.log`; includes #1669's cases); `test/jog-queue.sh`, `gh139`, `gh460` exit 0; 245/0 at `8f47703f5`/`cc6c73d9e`/`4f83f0b45`, 242/0 at `e9127b18` |
| Red control, base runtime | same suite with `utils/py/jog_run.py` + `gate_receipt.py` from `52813e56f`, `TEST_SOFT_FAIL=1` | **225 pass, 17 fail** (`gh280-red-base-runtime.log`): wake (G4), gate-only retry (K2) and retry-build (K4) each refused with `gate-attempt: REFUSED — task qualification has no attempt reservation`, the Day 3 string |
| Two-resume probe (plan QA R1-S5) | reviewer's script inserted temporarily after G4-retry's first failed push (`two-resume-probe-fragment.sh`) | `resume A exit=2 B exit=4 rows_while_A_held=2 total_rows=2` — B refused by the supervisor lock, exactly one added row (A's failure is the fixture's receipt-push sentinel) (`two-resume-probe.log`) |
| Smoke, real installed hook (GH-1088) | `bash smoke.sh <task clone> <empty dir>` | main path: `published`, remote lane subject `jog: publish gh1653-smoke1 approved execution receipts`, one completed row archived; adjacent rerun: `receipt already published ...; no attempt booked`, rows unchanged; control: unreserved push refused by the installed stub (`smoke-installed-hook.log`) |
| Full gate `./validate.sh` | gate clone at `8164e2ec1` with the start-task attempt context | RED: `gh139-pipe-grep-guard.sh`, `gh460-pipe-buffer-sigpipe.sh` — two `| grep -q` sites in the new test lines (`validate-full-8164e2ec1-tail.log`). Fixed in `e9127b18`; both guards then exit 0 and the smoke's installed-hook full gate (which ran the same suite set at `e9127b18`) passed. The first smoke run hit the same red (`smoke-installed-hook-run1-gate-red.log`); its admission step already passed and each refused push left a consumed `failed` row (1, then 2). |
| Final QA r1 Form 2 probes (reviewer's scripts) | `final-qa-r1-probe1.sh` (resume lock initialization race), `final-qa-r1-probe2.sh` (completed-row archive vs replacement budget) | both **reproduced** at `e9127b18` (AssertionError) and **fixed** at `4f83f0b45`: probe1 `A entered=True exit=0; B entered=False exit=2` (B refused: owner initializing); probe2 replacement active row survives at the live path (`final-qa-r1-probe*.log`) |

| Final QA r2 probes (reviewer's scripts) | `final-qa-r2-probe-branch.py` (saved-receipt settlement vs another branch's active row), `final-qa-r2-probe-mixed.sh` (resume initializing vs retry-gate) | both **reproduced** at `4f83f0b45` (AssertionError) and **fixed** at `cc6c73d9e`: `finish called=False; archive=False`; `resume entered=True exit=0; retry-gate entered=False exit=2` (`final-qa-r2-probe-*.log`) |

| CLI `jog resume` smoke, real installed hook | `bash smoke-cli.sh <task clone> <empty dir>` at `ad6e5a6bd` (also 12/12 at `8f47703f5`) | **0 expectations failed (12 OK)**: refused resume rc=2, one `failed` row, remote OID `absent`→`absent`; `jog resume` rc 0, remote lane = bundle commit, subject `jog: publish gh1653-cli1 approved execution receipts`, archive `failed,completed`, receipt saved; rerun rc 0 re-projected, nothing booked, ref unchanged; unreserved push refused (`smoke-cli-installed-hook.log`) |
| Final QA r3 probe (reviewer's script) + stale control | `final-qa-r3-probe-wake.sh` (resume initializing vs unsupervised wake) | **reproduced** at `cc6c73d9e`, **fixed** at `8f47703f5`: `resume entered=True exit=0; wake entered=False exit=2`; a fresh owner-less lock is refused, an owner-less lock aged 60s is still reclaimed (`final-qa-r3-probe-wake.log`) |

| Final QA r4 probe (reviewer's extended script) | `final-qa-r4-probe-wake-extended.sh` (owner stalled 11 s before its PID write) | **reproduced** (AssertionError): pre-existing two-step lock protocol; tracked as #1671, not fixed here |
| Consult tie-break at the final-QA cap | `final-consult/` | agy PROCEED; Codex HOLD on an out-of-band manual booking under Jog's key — declined as out of envelope (see relay round 4 Producer) |

## What the cases assert (gh280)

- **G4**: wake publishes the bundle on the bare remote lane ref through real per-ref admission; one completed `GH-901-jog-publish` row archived under the coordinator root.
- **G4-neg**: unreserved task push from the same clone refused with the admission message; no remote ref.
- **G4-retry**: failed receipt push parks and keeps 1 consumed row; restart (`jog resume`) books a 2nd; at the cap publication refuses `budget exhausted after 2`, rows and the exact remote OID unchanged; a CLI resume with room in the cap (`LANE_MAX_ATTEMPTS=3`) publishes the bundle; a supervised wake (`--supervise-until`, lock held) recovers and publishes the same pending receipt without self-refusal.
- **G4-archive**: (b) failed + active at the cap with the remote at the prior SHA refuses; saved-completed, saved-active and unsaved-active interrupted finishes: resume settles the same row id, no booking or push, ref unchanged; a saved receipt with nothing pending re-projects with the execution clone retired.
- **K2**: the gate-only retry creates the absent lane ref with its bundle; reservation archived under the coordinator, not the execution clone.

Field evidence (not replayed here): Day 3 at `3f2ffa353` (#1611 handback). Live OL-13 credit stays with the Day 4 run (#1657).
