---
gh_issue: 1193
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1193
title: "merge-cleanup: --retire-published-pr refuses start-task's sibling task clones when the primary is outside DEFAULT_SAFE_ROOTS"
status: active
created: 2026-10-24
updated: 2026-10-24
owner: claude-opus-5-5 (start-task, 2026-10-24)
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: false
rating: 55/45/50/85
non_goals:
  - Widening DEFAULT_SAFE_ROOTS, the default scan roots or full-sweep teardown (#722).
  - New safety checks, flags or tests (GH-831).
goal: >
  merge_cleanup.py --retire-published-pr can retire start-task's sibling task clones and helpers
  on any machine, with every existing fail-closed check intact.
---

# GH-1193 — `--retire-published-pr` refuses sibling task clones outside DEFAULT_SAFE_ROOTS

## Status

| What was just completed | What's next |
|---|---|
| Fix `f7d148ec`; smoke + focused suites green (`TESTS-RESULTS/2026-10-24+GH-1193/`); final Codex QA Approved (`relay-system/2026-10-24/gh1193-final-qa.md`, `40a7a07a`). | Full route gate once on the final commit in the disposable `-gate` clone, then PR against development; awaiting merge. |

`merge_cleanup.py --retire-published-pr` (GH-1059, start-task Step 9) checks every `--checkout`
against the four hard-coded `DEFAULT_SAFE_ROOTS` in
`skills/2-daily/merge-cleanup/scripts/scan_clones.py`. start-task's GH-970 rule puts task clones
and their `-gate`/`-verify` helpers next to the primary clone, so on a machine whose primary is
`~/Documents/GitHub-Repos/XYZ-forge` the mode refuses everything start-task creates
(`Refusing: path is not strictly within SAFE_ROOTS`). Seen 2026-10-24 closing out PR #1190.

## Asks

- For published-PR retirement only, also accept the `--primary` clone's parent folder as a safe
  root, unless that parent is a `NEVER_DELETE` root (`~`, `~/Documents`, `~/Desktop`, …).
- Keep every other fail-closed check (absolute non-symlink checkout, not the primary or its
  ancestor, same origin, live published-PR head proof, fresh re-inspection, NEVER_DELETE).

## Acceptance

- [ ] The PR #1190 preview command no longer refuses on SAFE_ROOTS.
- [ ] A primary whose parent is a NEVER_DELETE root does not widen the roots.
- [ ] `DEFAULT_SAFE_ROOTS` and WORKTREE-SAFETY.md §16.1 stay identical (parity test green);
      the derived root is documented beside the list.
- [ ] No new tests (GH-831); existing merge-cleanup suites stay green.

Related: #722 (same root cause in the default audit scan; stays open), #1059, #970.

## Plan (start-task, 2026-10-24, base `45eb73a7`)

### Recon (ground truth)

- `DEFAULT_SAFE_ROOTS` — `skills/2-daily/merge-cleanup/scripts/scan_clones.py:26`; consumed by
  `is_safe_deletable_path(path, safe_roots=None, never_delete=None)` (`:64`), which already takes an
  explicit `safe_roots` list.
- The published-retirement path (`merge_cleanup.py` `retire_published_checkouts`, `:1482`) runs the
  root check from **three source sites** (four evaluations: `inspect_checkout` runs at the initial
  inspection and again in `refresh_for_teardown`), all with the default list:
  1. its own up-front guard (`:1501`) → `Published retirement refused: Refusing: path is not strictly within SAFE_ROOTS`;
  2. `inspect_checkout` (`scan_clones.py:935`) → `safe_deletable=False` → `PRESERVE_UNSAFE_ROOT` (`:1106`);
  3. `teardown_checkout` (`merge_cleanup.py:890`) → `Safety violation`.
  `inspect_checkout` already receives `primary_repo_path` and `published_pr`, so it can tell it is on
  the retirement path without a new parameter.
- Tests: no suite calls `retire_published_checkouts` (GH-1059 was verified manually). The pins that
  matter: `test/gh534_phase_a_tests.py` `test_doc_and_code_root_lists_agree` (regex on the first
  `SAFE_ROOTS = [...]` block in WORKTREE-SAFETY.md §16.1) and `test/gh436-merge-cleanup.py`
  orchestration asserting `teardown_checkout(candidate, dry_run=...)` on the normal teardown path.
  Fixtures widen roots with `mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", ...)`, so the
  default must keep being read from the module global at call time.
- Route: `.py` under `skills/*/merge-cleanup/` plus `WORKTREE-SAFETY.md` and merge-cleanup `SKILL.md`
  → full gate (`utils/ci-route.sh`).

### Bet

- Outcome: start-task Step 9 can retire its own sibling clones on any machine, so they stop piling up.
- Smallest bet: one helper in `scan_clones.py` returns `DEFAULT_SAFE_ROOTS` plus the primary's
  parent unless that parent is a `NEVER_DELETE` root; the three checks on the retirement path use it.
- Rejected: (A) adding `~/Documents/GitHub-Repos` to `DEFAULT_SAFE_ROOTS` — fixes one operator's
  machine only, widens the default scan/teardown for everyone, and the next layout breaks again.
  Widening the **default scan** to the primary's parent is #722's scope and stays there.
- Rollback: revert the commit; the default list and all other checks are untouched.

### Non-goals

- Changing `DEFAULT_SAFE_ROOTS`, the default scan roots, or full-sweep teardown (#722).
- Any new safety check, flag, or test (GH-831).

### Implementation (ordered)

1. `scan_clones.py`: add `published_retirement_roots(primary)` beside `DEFAULT_SAFE_ROOTS` —
   `DEFAULT_SAFE_ROOTS + [primary.resolve().parent]`, or just `DEFAULT_SAFE_ROOTS` when that parent
   resolves to a `DEFAULT_NEVER_DELETE` member. In `inspect_checkout` pass
   `safe_roots=published_retirement_roots(primary_repo_path)` only when `published_pr` and
   `primary_repo_path` are both set; otherwise `None` (unchanged default).
2. `merge_cleanup.py`: `teardown_checkout(checkout, dry_run=True, safe_roots=None)` forwards
   `safe_roots` to its check; `retire_published_checkouts` computes the roots once and passes them to
   its own guard and to `teardown_checkout`. The normal-sweep call stays byte-identical.
3. `WORKTREE-SAFETY.md` §16.1: one sentence after the code block naming the derived per-run root
   (list unchanged → parity holds). `skills/2-daily/merge-cleanup/SKILL.md`: one sentence in
   "Automatic retirement after ready PR publication".

### Acceptance checks (no new tests)

- Main path (smoke): the PR #1190 preview command from the issue, run with this branch's driver,
  prints no `SAFE_ROOTS` refusal; any remaining refusal names a real reason. **Red control:** the same
  command with the `origin/development` driver refuses on SAFE_ROOTS.
- Adjacent paths (smoke): `published_retirement_roots(Path.home()/"Documents"/"x")` returns exactly
  `DEFAULT_SAFE_ROOTS` (NEVER_DELETE parent not added); a same-origin `--checkout` outside both the
  defaults and the primary's parent still refuses on SAFE_ROOTS.
- Existing suites: `python3 test/gh534_phase_a_tests.py`, `bash test/gh436-merge-cleanup.sh`
  focused; full route gate once on the final commit in a disposable `-gate` clone.
- Receipts under `TESTS-RESULTS/2026-10-24+GH-1193/`.

### Rating rationale (2026-10-24) — `rated 55/45/50/85`

- sev 45: blocks automatic Step 9 cleanup for every operator whose primary is outside the four
  roots; clones accumulate (disk, clutter, stale-clone confusion). No data loss; fully recoverable.
- pri 55: severity-led, nudged up because every start-task run on such a machine hits it.
- appeal 50: neutral (no operator preference stated).
- effort 85: three call sites and one helper; no schema or CLI change.
- Recurrence: last 14 days — 1 incident (PR #1190, 2026-10-24); preceding 14 days — 0 seen for this
  mode (introduced by #1059). Same-class #722 (2026-09-21) is the default-scan variant, not a repeat.
