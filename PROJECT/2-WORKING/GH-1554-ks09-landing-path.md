---
issue: 1554
title: "kickstart(KS-09): unambiguous landing path, pinned LANDING_CLONE, exit-4/exit-8 handling, and build_queue reconcile text"
status: active
roadmap_id: rmi-01M7W9APMQ41N8F5V89G3HQAZQ
parent_arc: 1541
milestone: KS-09
owner: antigravity
goal: "Pin one LANDING_CLONE for the whole kickstart run, codify exit-4 (--record-sweep deferred) and exit-8 (preserve MERGED + wait/reconcile within deadline) handling in kickstart/SKILL.md, and fix build_queue.py:206 reconcile text."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1554 (KS-09) — Unambiguous Landing Path

## Status

| What was just completed | What's next |
|---|---|
| Implemented KS-09 unambiguous landing path (`LANDING_CLONE`, exit-4 `--record-sweep`, exit-8 preserve/reconcile/HOLD) in `SKILL.md` and `build_queue.py`; passed disposable-clone Controls 1A/1B/2/3, mypy (0 issues), and PDDA (0 errors). | Complete Codex Final QA, open PR, and land. |

## Objective
Make kickstart's landing path unambiguous (issue #1541 KS-09, U10): one pinned `LANDING_CLONE:` for the entire run, one canonical `merge-cleanup --execute` writer, deterministic exit-4 and exit-8 handling, and removal of the contradicting `"Reconcile once at the end."` line in `build_queue.py`.

## Grounded Recon
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2498-2517`: resolves `--primary` and checks `policy_paths.primary_root(str(primary_repo))`, refusing with exit `2` when `--primary` differs from a pinned Jog primary.
- `skills/2-daily/merge-cleanup/SKILL.md:129-145,366-377`: `--primary` is the sole checkout that `git merge --ff-only`, `wave_reconcile.py`, `releases_app.py`, and `pdda.sh` write to; attempt records live at `<primary>/.tick/merge-cleanup/<owner>-<repo>/pr-<N>.json` (2-repair ceiling); post-merge reconciliation runs after EACH verified remote merge (exit 8 if a hosted `wave-reconcile.yml` run is active); exit 4 means `landed, QA pending` and accepts `--record-sweep <file>` with first line `verdict: clean|findings|deferred`.
- `skills/1-hourly/kickstart/scripts/build_queue.py:205-206`: currently emits `"Reconcile once at the end."` for Bucket C, directly contradicting `merge-cleanup/SKILL.md:370`'s per-merge durability sequence.
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).
- `utils/ci-route.sh`: classifies edits to `skills/1-hourly/kickstart/**`, `PROJECT/**`, `TESTS-RESULTS/**`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add **Unambiguous Landing Path & Exit-Code Handling (KS-09, U10)** subsection:
     - **Single Pinned `LANDING_CLONE:`:** the run record declares exactly one `LANDING_CLONE:` header for the entire run; every `merge_cleanup.py --execute`, `--reconcile-pr`, `--record-sweep`, and `--retire-published-pr` invocation passes `--primary <LANDING_CLONE>` (never a second landing clone, and never the user's primary checkout unless the run explicitly pinned it). When a Jog primary pin conflicts with `LANDING_CLONE` (`merge_cleanup.py:2502-2515`), resolve the pin explicitly before launch rather than switching primaries mid-run. Task builds NEVER write to `--primary` or `LANDING_CLONE`. KS-04, KS-08, and KS-20 read attempt records ONLY from `<LANDING_CLONE>/.tick/merge-cleanup/` so the 2-repair ceiling cannot be reset.
     - **Exit 4 (`landed, QA pending`):** under `qualification.full_suite=promotion`, write a sweep receipt file whose first line is `verdict: deferred` (citing the deferred promotion gate policy) and run `merge_cleanup.py --primary <LANDING_CLONE> --record-sweep <file>`.
     - **Exit 8 (active hosted `wave-reconcile.yml` run during local reconciliation):** preserve the `MERGED` PR and its incomplete durability checkpoint, stop further landings immediately, wait via the host's supported background/wakeup mechanism within the original run wall deadline until the hosted run and any promotion quiet window end, then re-check stopped-ownership and remote PR state and run `merge_cleanup.py --primary <LANDING_CLONE> --reconcile-pr <N> --execute` (never forcing reconciliation with `--force-local-reconcile` and never re-merging). If the original deadline expires before reconciliation completes, stay in a recorded `HOLD`.
2. **`skills/1-hourly/kickstart/scripts/build_queue.py`:**
   - Update line 206 from `"Reconcile once at the end."` to `"Merge-cleanup reconciles after each verified merge; run one post-batch sweep at the end."` (matching `merge-cleanup/SKILL.md:370`).
   - Verify `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py`.
3. **Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1554/`, no new test suite GH-831):**
   - **Control 1 (Wrong-primary refusal + pinned LANDING_CLONE + Bucket C text):** disposable-clone replay calling `merge_cleanup.py` with a wrong `--primary` against a pinned Jog primary (red refusal rc=2), vs the pinned `LANDING_CLONE` invocation (green); plus pre-change vs changed `build_queue.py` Bucket C output proving `"Reconcile once at the end."` is replaced.
   - **Control 2 (Exit 4 `--record-sweep` with `verdict: deferred`):** disposable-clone seed of a QA-pending batch record where pre-change path had no deferred sweep receipt (QA pending) and changed `merge_cleanup.py --primary <LANDING_CLONE> --record-sweep <file>` with `verdict: deferred` resolves the batch cleanly (rc=0).
   - **Control 3 (Exit 8 active hosted reconciliation + deadline expiry):** controlled state-machine + real CLI contract verification confirming: MERGED PR + active hosted run -> hold without re-merge or `--force-local-reconcile` -> reconcile once via `--reconcile-pr N --execute` after hosted run & quiet window end within deadline; expired deadline -> stays recorded HOLD.
   - Run `./utils/pdda/pdda.sh run` (0 errors), `utils/ci-route.sh`, and generate `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` defines the single pinned `LANDING_CLONE:` rule, exit-4 `--record-sweep` (`verdict: deferred`), and exit-8 preserve/wait/`--reconcile-pr`/deadline-hold protocol.
- `skills/1-hourly/kickstart/scripts/build_queue.py` removes `"Reconcile once at the end."` and passes `mypy`.
- Paired red/green checks, mypy, PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1554/`.
