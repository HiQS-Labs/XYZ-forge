---
gh_issue: 454
source: https://github.com/HiQS-Labs/XYZ-forge/issues/454
title: "GH-454: wave_reconcile dies on an unnamed release and enforces PDDA full-mode on an observe-mode repo"
status: 2-WORKING
created: 2026-09-05
updated: 2026-09-08
owner: unassigned
goal: "both reconciler defects fixed: unnamed releases render, PDDA gating scoped to mode"
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
marathon: gh-490
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/490 — marathon umbrella"
---


## Status

| What was just completed | What's next |
| --- | --- |
| Promoted from 1-INBOX with a swarm-preflight contract; lane of marathon gh-490 | Implement per the contract; lane brief in PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md |

# GH-454 — Reconciler dies on an unnamed release, and overrides the repo's PDDA mode

> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

Two independent defects, both hit in one real five-PR merge-cleanup run, both rolling the whole
wave back. A third from the same run is the surviving half of GH-215 — commented there.

## Environment

- **Observed from:** `rebalanceOS` (vendored `.xyz/`, `tier=2`, vendored 2026-09-02T21:20:08Z)
- **Harness commit:** `fd8bcca8`
- **Worker/CLI:** n/a — invoked directly as `python3 .xyz/utils/py/wave_reconcile.py --pr <N>`
- **Runtime:** Python (default; `XYZ_PYTHON` unset) — matches the `runtime:python` issue label
- **Sandbox:** off

## Reproduction

**Defect 1 — unnamed release.**

1. Have a release row in `releases.db` with both `codename` and `version` NULL. Nothing in the
   schema forbids it; `releases_app.py` creates them, and this one had sat there for days.
2. Run `python3 .xyz/utils/py/wave_reconcile.py --root <repo> --pr <N>`.

**Defect 2 — PDDA mode override.**

1. In a repo whose `.pdda-mode` reads `observe` and which has standing non-blocking findings
   (rebalanceOS has 23), confirm `bash utils/pdda/pdda.sh run` exits **0**.
2. Run the reconciler with no `utils/pdda-local-checks.sh` present.

**Expected:** (1) an unnamed release renders under a placeholder or is skipped with a warning;
(2) the gate honours `pdda.sh`'s exit code, which already encodes `.pdda-mode` via
`pdda_gated_exit`.

**Observed:** (1) `AttributeError`, exit 1, full rollback; (2) gate fails and rolls back despite
exit 0, because the findings print the word `ERROR`.

**Frequency:** every time, both defects, `--dry-run` and live.

```text
wave-reconcile:   -> export_timeline.py --preview
  File ".../export_timeline.py", line 278, in release_columns
    "slug": (codename or version).lower(),
AttributeError: 'NoneType' object has no attribute 'lower'
wave-reconcile: Rolling back all uncommitted mutations...

wave-reconcile: Running PDDA doc-hygiene gate...
wave-reconcile: ERROR — PDDA validation gate failed:
wave-reconcile: Rolling back all uncommitted mutations...
```

## The two lines

```python
# utils/timeline/export_timeline.py:278
"slug": (codename or version).lower(),

# utils/py/wave_reconcile.py, run_validation_gate()
if r.returncode != 0 or "ERROR" in r.stdout:
```

The second clause is the defect in Defect 2. It is also brittle independently of mode: a bare
substring test fires on `ERROR` anywhere in stdout — a doc title, a file path, a quoted finding —
so even a `full`-mode repo with zero findings can fail on a filename.

## Impact

With GH-215's surviving half, these are what stand between the reconciler and unattended
operation, which **GH-421** depends on. All three have workarounds; all three require the caller
to already know them, and each failure rolls the wave back with an error that does not name the
real cause.

Workarounds used in the reporting repo: gave the release a codename (fixes one row, not the
class); added a repo-owned `utils/pdda-local-checks.sh` that reports on stderr and returns
`pdda.sh`'s exit code — arguably the sanctioned seam, but every vendoring repo in `observe` mode
has to rediscover it, and the discovery path is a rolled-back wave.

## Rating

`rated 72/78/80/78` — calc **308**. pri 72 (workarounds exist), sev 78 (hard stop + rollback;
Defect 2 overrides a declared repo policy), appeal 80 (unblocks GH-421), effort 78 inverted
(a one-line guard and a deleted clause).

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist

- [ ] Reproduce both in the intake repo, not only in the reporting repo
- [ ] Decide Defect 1's shape: placeholder slug vs. skip-with-warning (does any consumer rely on
      every release appearing in the timeline?)
- [ ] Decide Defect 2's shape: drop the stdout clause, or match a structured marker `pdda.sh`
      actually emits (`^ERROR [`) — do not invent a third validation path
- [ ] Check whether `utils/pdda-local-checks.sh` should be documented as the seam, or whether its
      existence is itself the smell
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0

- [ ] A regression test covers each failure path before the fix lands: one release row with both
      fields NULL; one `observe`-mode repo whose findings print `ERROR` while exiting 0
- [ ] Neither fix adds a parallel code path — reuse the existing gate and the existing slug helper
- [ ] The `observe`-mode test asserts the reconciler *completes*, not merely that it warns

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/wave_reconcile.py",
      "pattern": "\"ERROR\" in r\\.stdout",
      "note": "bug evidence \u2014 un-scoped PDDA error check (run_validation_gate) must be present pre-fix"
    },
    {
      "type": "grep_present",
      "path": "utils/timeline/export_timeline.py",
      "pattern": "codename or version",
      "note": "bug evidence \u2014 must fire unfixed at pre-work time"
    },
    {
      "type": "path_absent",
      "path": "test/gh454-reconciler-defects.sh",
      "note": "new lane artifact \u2014 must not exist yet"
    }
  ],
  "artifacts": [
    "utils/timeline/export_timeline.py",
    "utils/py/wave_reconcile.py",
    "test/gh454-reconciler-defects.sh"
  ],
  "remediation": {
    "source": "issue#454",
    "criteria": "an unnamed release no longer aborts the reconcile; the PDDA full-gate overreach is scoped to its documented surface; both pinned red-first"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/",
      "utils/timeline/",
      "test/"
    ],
    "orchestrator_only": []
  },
  "artifacts_new": [
    "test/gh454-reconciler-defects.sh"
  ]
}
```

## Acceptance

- A release with neither codename nor version no longer aborts `wave_reconcile` (placeholder slug or skip-with-warning).
- The reconciler's PDDA full-gate overreach is scoped to its documented surface.
- Both defects pinned red-first in a new suite.

## Acceptance — reviewer-tightened criteria (CodeRabbit round 1)

- [ ] A release with neither codename nor version renders under slug `unnamed-<gid8>`; `wave_reconcile` exits 0 and completes.
- [ ] Observe mode: the PDDA gate reports `ERROR` findings, prints `not blocking in observe mode`, exits 0, and the reconcile completes.
- [ ] Full mode: the PDDA gate exits non-zero and the reconcile rolls back.
## Merge evidence

- PR #495 merged 2026-09-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
