---
gh_issue: 808
source: https://github.com/HiQS-Labs/XYZ-forge/issues/808
title: "gh251-validate-pytest-skip.sh burns ~22% of the full gate on two nested tier-2 runs — scope it to the pytest lane"
status: Active (2-WORKING)
created: 2026-09-24
updated: 2026-09-24
owner: agent-b
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
non_goals:
  - No deletion or weakening of gh251's assertions; the GH-251 pytest-skip contract and GH-732 yaml-fault diagnostic stay byte-identical in coverage.
  - No tiering-policy or width changes (#732 owns those).
  - No validate.sh seam unless the retarget measurably fails the ≤120 s target (that would be a separate, kernel-surface decision).
related:
  - "#805 (test-value audit; this is the top cost item in its sample)"
  - "#732 (gate-cost ledger; biggest single lever found)"
  - "test/gh251-validate-pytest-skip.sh"
  - "validate.sh (pytest lane, T2_PYTEST)"
goal: >
  gh251's two nested `validate.sh --paths-file` invocations select the cheapest tier-2
  lane that still triggers T2_PYTEST, cutting the suite from ~1044 s (21.7% of the
  hosted sequential full gate) to ≤120 s with identical assertions, a witnessed red
  control, and committed matched before/after timing evidence.
---

## Key concepts

- `test/gh251-validate-pytest-skip.sh:14` names `utils/py/releases_app.py` in its `PATHS_FILE`, so each of its two nested `validate.sh --paths-file` runs (`:18`, `:54`) executes the ~24-suite `releases` lane — up to ~48 suite executions hidden inside one TESTS entry — to assert five output strings about the pytest lane.
- The pytest lane runs at tier 2 whenever `T2_PYTEST=1` (`validate.sh:908/:928/:937`); any `*.py` path in the paths-file sets it. The assertions need **no specific subsystem** — only a real, mapped tier-2 path.
- Cheapest measured candidate: `skills/3-weekly/skills-army-hq/scripts/sync.py` → `skills-army-hq` lane = 2 suites, **34.8 s** total (hosted 2026-09-24 artifact), vs `ate` 114.7 s (9 suites) and `releases` ~500+ s (~24 suites). Python lane itself: 20.9 s; the absent-pytest leg skips pytest execution, so it pays only lane + boot.
- Measured baseline: **1044.4 s** hosted sequential (`TESTS-RESULTS/2026-09-24+GH-591/wave-326e48…/validation.jsonl`), 705.8 s local 4-wide (`TESTS-RESULTS/2026-09-21+GH-740/`); zero sleeps in the suite — cost is real nested work.

## Status

| What was just completed | What's next |
|---|---|
| Fix landed on branch (`0f1b811e`): PATHS_FILE → `skills/3-weekly/skills-army-hq/scripts/sync.py`. Matched standalone timing **1050.6 s → 67.5 s (−93.6%)**, 6/6 assertions both sides; red control witnessed (exit 1 → restore → green); evidence in `TESTS-RESULTS/2026-09-24+GH-808/`. | Full qualifying gate (`ci-local.sh`) once in the disposable clone, final relay QA (Codex), push through pre-push gate, PR vs `development`. |

## Rating rationale (2026-09-24)

`rated 72/50/50/82` — **pri 72**: operator-directed follow-up of the #805 audit's top cost item; taxes every full gate run but blocks nothing. **sev 50**: recurring waste (~17 min per hosted sequential run; the local pool's longest pole at 705.8 s), no data loss or work blocking; recoverable by this fix. **appeal 50**: neutral — no explicit user preference. **effort 82**: two-line test-local diff plus verification protocol; no product surface. Recurrence: not a defect class — a cost regression silently compounding since the nested-run design landed (flagged 2026-09-22 in GH-749 CAPTURE.md:30 and never picked up).

## Plan (ordered)

1. Retarget `PATHS_FILE` in `test/gh251-validate-pytest-skip.sh` from `utils/py/releases_app.py` to `skills/3-weekly/skills-army-hq/scripts/sync.py`, with a comment stating why that path (cheapest `.py`-bearing tier-2 lane; the suite only needs `T2_PYTEST=1`, not a specific subsystem). -> expect a 2-line diff.
2. Focused verification in the disposable gate clone: `bash test/gh251-validate-pytest-skip.sh` green, and the captured output still shows `--paths-file classified tier 2` + `Running python3 -m pytest test/test_python_layer.py`. -> expect 5 pass, 0 fail.
3. Witnessed red control (same clone): mutate the expected `SKIPPED: python:test_python_layer.py (pytest not importable…)` string in `validate.sh`, watch both sections fail, restore, watch green. -> expect red, then green, output captured.
4. Matched before/after timing (same clone, same host, standalone `time bash test/gh251…` at base vs task commit). -> expect before ≈ 700–1050 s, after ≤ 120 s.
5. Full qualifying gate ONCE (`bash ci-local.sh`) at the final commit, pre/post identity checks on the clone. -> expect GREEN + `.gate-evidence/<sha>.txt`.
6. Final relay QA (Codex) on the diff + evidence; push through the pre-push gate; open PR vs `development`; cite #808, #805, #732, #749.

## QA gate (phase 1 of 1)

- Focused suite green; red control witnessed; before/after timing captured into `TESTS-RESULTS/2026-09-24+GH-808/` with provenance; `ci-local.sh` GREEN; PR base `development`.
