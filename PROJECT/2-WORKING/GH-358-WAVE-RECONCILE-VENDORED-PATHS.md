---
gh_issue: 358
source: https://github.com/HiQS-Labs/XYZ-forge/issues/358
title: "GH-358: wave_reconcile resolves its five harness tools repo-root-relative, so it is inert on every vendored install"
status: Active
created: 2026-09-01
updated: 2026-09-01
owner: claude
doc_type: bugfix
fix_probes:
  - bash test/gh358-wave-reconcile-vendored-paths.sh
  - bash test/wave-reconcile.sh
goal: resolve wave_reconcile's harness tools against the harness home so a vendored (Tier 2) install can complete a post-merge closeout (GH-358)
---
## Status

| What was just completed | What's next |
|---|---|
| Fix + regression suite landed on `fix/358-wave-reconcile-vendored-paths`; Codex QA relay Approved; validate.sh green | Merge PR #359, re-vendor `.xyz/` into LTVera-Pandas, then run the blocked `jog land GH-337 --pr 338` |

# GH-358 — wave_reconcile resolves harness tools repo-root-relative

## The defect

`utils/py/wave_reconcile.py:708-712` named five harness tools as repo-root-relative paths and
ran them with `cwd=repo_root`:

```python
sync_cmd     = ["python3", "utils/py/releases_app.py", "roadmap", "sync"]
check_cmd    = ["python3", "utils/py/releases_app.py", "check"]
timeline_cmd = ["python3", "utils/timeline/export_timeline.py", "--preview"]
dash_cmd     = ["bash", "utils/roadmap-dashboard.sh"]
plan_cmd     = ["bash", "utils/marathon-plan.sh", "--format", "json"]
```

On a vendored (Tier 2) install those five files exist **only** under `<repo>/.xyz/`. All five were
therefore unreachable, and the reconciler died on its first downstream step and rolled back:

```
wave-reconcile:   -> releases roadmap sync
wave-reconcile: ERROR — Subprocess 'releases roadmap sync' failed with exit 2:
python3: can't open file '<repo>/utils/py/releases_app.py': [Errno 2] No such file or directory
wave-reconcile: Rolling back all uncommitted mutations...
```

Found in `BinoidCBD/LTVera-Pandas` while reconciling merged PR #338 against `.xyz` at
`source_commit` 6d23ac86. `--dry-run` fails identically, so this is not write-path-specific:
**no vendored install could complete a post-merge closeout at all.**

This is the defect class `jog_run.harness_home()` was written to prevent (it names GH-279 #2 in
its own docstring) and that `marathon_plan.py:112-124` already guards with an `is_vendored`
check. `wave_reconcile.py` had neither — it used `__file__` nowhere.

## The fix

One helper, `harness_tool(repo_root, rel_path)`, used at the five call sites.

**Resolution order is repo-first, harness-second, and the order is load-bearing** — it is not a
preference:

1. If the *target repo* carries the tool, use the repo-relative path. Every existing
   wave-reconcile suite (`test/wave-reconcile.sh`, `gh168`, `gh202`, `gh232`) installs its mocks
   at `$REPO/utils/...` and depends on them shadowing the real tool. A canonical checkout is its
   own harness home, so repo-first is a no-op there.
2. Otherwise fall back to an absolute path under `harness_home()` — the vendored case.
3. If neither has it, return the repo-relative path so the error still names the tool the caller
   asked for, exactly as before.

## What deliberately did NOT change

`run_validation_gate()` at `utils/py/wave_reconcile.py:762` keeps its plain repo-root-relative
`utils/pdda/pdda.sh`. **PDDA is a target-repo tool** — LTVera-Pandas ships its own at its root. A
blanket `.xyz/` prefix over the file would have pointed the doc-hygiene gate at the harness
instead of the repository being reconciled. Harness tools resolve against the harness home;
target-repo tools resolve against the repo. That distinction is the fix.

Section 2 of the test enforces it with a decoy planted at `.xyz/utils/pdda/pdda.sh` that must
never run.

## Verification

`test/gh358-wave-reconcile-vendored-paths.sh`, registered in `validate.sh`. The fixture is a real
vendored layout: harness under `$REPO/.xyz`, target repo owning none of the five tools, and a
fixture guard that refuses if any of them leaks to the repo root.

Mocks assert by dropping **marker files**, not log lines. The first draft grepped the reconciler's
stdout and passed four assertions that were checking nothing — `wave_reconcile` captures
subprocess stdout and does not echo it on success. A file on disk is the primitive that cannot be
faked.

- Post-fix: **9/0**.
- Pre-fix control: **1/8**, reproducing `can't open file '<repo>/utils/py/releases_app.py'` verbatim.
- `./validate.sh`: exit 0, with all four pre-existing wave-reconcile suites still green — the
  actual gate on whether repo-first preserved their mock seam.

## Note on the number

`test/gh358-lock-instrumentation.sh` already carries a "GH-358" from the pre-rename numbering
(nothing by that number is in this repo's `ROADMAP.md`). This work is HiQS-Labs/XYZ-forge#358.
The filenames are distinct and neither is renumbered: renaming a green suite to tidy a comment
costs more history than it buys clarity. Both files say so.

## Lessons Learned (For Future Agents)

- A harness tool resolves against the harness home; a target-repo tool resolves against the repo.
  Getting that backwards is invisible in a canonical checkout, where the two are the same
  directory, and only shows up in a vendored install.
- `marathon_plan.py` and `jog_run.py` had already solved this. The bug was not a hard problem, it
  was an unapplied one — worth grepping for the *pattern* rather than the symptom next time.
- An assertion that greps a process's stdout for a subprocess's output can pass vacuously. Assert
  on a side effect the subprocess itself produces.
