---
title: wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth
status: Proposed (1-INBOX — not yet active)
created: 2026-08-24
owner: noel
gh_issue: 215
source: https://github.com/HiQS-Labs/XYZ-forge/issues/215
doc_type: bugfix
complexity: 2
risk: 3
effort: 1
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: 46075c9
non_goals:
  - Auditing every other vendored script under .xyz/utils/ for the same one-level-too-shallow root-resolution pattern (this capture only confirms the two found)
related:
  - GH-216 (same reconciler chain, open ledger-format question, kept separate — needs a design call, not a mechanical fix)
goal: >
  wave_reconcile.py's subprocess step and roadmap-dashboard.sh's own root-resolution math both
  work correctly out of the box when the harness is vendored under .xyz/, with no hand-patching
  required by the consuming repo.
---

# GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
Running `.xyz/utils/py/wave_reconcile.py` (the post-PR-merge reconciler) in a repo that vendors
the harness under `.xyz/` (not a bare `utils/` at repo root) dies immediately at the
subprocess-orchestration step, then again one step later after a partial fix — both are simple
path-resolution mistakes that assume a non-vendored `utils/` layout at repo root.

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** 46075c9 (per `.xyz/VERSION`, vendored 2026-08-24T02:04:13Z)
- **Worker/CLI:** n/a — invoked directly via `python3 .xyz/utils/py/wave_reconcile.py`
- **Sandbox:** off (gh + subprocess calls run un-sandboxed)

## Reproduction
1. In a repo with `.xyz/` vendored, run `python3 .xyz/utils/py/wave_reconcile.py --pr <N> --dry-run`.
2. `run_subprocesses()` builds commands as `python3 utils/py/releases_app.py ...`, `python3 utils/timeline/export_timeline.py --preview`, `bash utils/roadmap-dashboard.sh`, `bash utils/marathon-plan.sh` (with `cwd=repo_root`); `run_validation_gate()` builds `bash utils/pdda-local-checks.sh` / `bash utils/pdda/pdda.sh`. None of these paths exist at `repo_root/utils/...` — only at `repo_root/.xyz/utils/...`. Dies at the first subprocess call.
3. After locally prefixing all six occurrences with `.xyz/`: reaches `bash .xyz/utils/roadmap-dashboard.sh`, which itself derives its root via `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` then `ROOT="$(cd "$HERE/.." && pwd)"` — correct only if the script lives at `repo_root/utils/roadmap-dashboard.sh`. Vendored one level deeper, `ROOT` resolves to `repo_root/.xyz` instead of `repo_root`, so it crashes with `ENOENT: .../.xyz/ROADMAP.md`.

**Expected:** both resolve correctly against the true repo root in a vendored install.
**Observed:** two sequential dies (missing-file error, then ENOENT), full rollback each time (rollback is `wave_reconcile.py`'s own journal, working as intended — not part of this bug).
**Frequency:** every time, both `--dry-run` and live.

```text
wave-reconcile:   -> roadmap-dashboard.sh
node:fs:440
Error: ENOENT: no such file or directory, open '<repo_root>/.xyz/ROADMAP.md'
```

## Impact
Blocks any vendored `.xyz/` install's post-merge reconciler from completing out of the box in any
consuming repo. Workaround: both hand-patched in the local vendored copy for the reporting session
only — not upstream, will regress on the next `.xyz/` vendor refresh.

**Local patch applied (for reference, not yet upstream):**
- `wave_reconcile.py`: prefixed the six `utils/...` command-path strings with `.xyz/`.
- `roadmap-dashboard.sh`: changed `ROOT="$(cd "$HERE/.." && pwd)"` to `ROOT="$(cd "$HERE/../.." && pwd)"`.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce both bugs in the intake repo against a vendored-layout fixture; confirm the two patches above are the right upstream fix (vs. e.g. resolving root via `git rev-parse --show-toplevel` instead of `dirname`-relative math, which would be robust to future vendoring-depth changes)
- [ ] Audit other vendored scripts under `.xyz/utils/` for the same one-level-too-shallow `dirname`-based root-resolution pattern (not done here — scope was these two)
- [ ] Set/correct triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression fixture (vendored-layout repo) covers the failure path before the fix lands
- [ ] The fix composes with the existing harness rather than adding a parallel path
