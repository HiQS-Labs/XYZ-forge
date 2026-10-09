---
gh_issue: 1001
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1001
title: "harness_paths: global XYZ_HARNESS overrides vendored .xyz root; marathon-drive parks lane on the wrong repo's issue"
status: In Progress
created: 2026-10-08
updated: 2026-10-08
owner: operator
doc_type: bugfix
goal: "A vendored marathon run resolves its own repo and survives incidental builder scratch, so one stray probe or one global env var no longer kills a phase."
effort: 2
complexity: 2
risk: 2
phases: 1
related:
  - PROJECT/2-WORKING/GH-1002-OFFLANE-SCRATCH-CAP.md
---

## Status

| What was just completed | What's next |
|---|---|
| Recon + debug-mantra verified both diagnoses on origin/development 38ac9ee4; intake registered and rated; plan written. | Codex plan QA via relay-xyz. |

## Issue map (one branch, one PR)

| Issue | Scope | Rating (pri/sev/appeal/effort) | Acceptance | State |
|---|---|---|---|---|
| [#1001](https://github.com/HiQS-Labs/XYZ-forge/issues/1001) | `harness_home()` precedence; issue-closed check repo; park message | 80/75/50/70 | A1–A3 | Plan |
| [#1002](https://github.com/HiQS-Labs/XYZ-forge/issues/1002) | GH-113 scratch relocation; cap gate order; dry-run cap line; builder preamble truth | 65/65/50/55 | B1–B4 | Plan |

Branch `fix/gh-1001-1002-vendored-marathon` off `origin/development` 38ac9ee4, clone
`~/marathon-clones/xyz-gh1001-1002-vendored-marathon`. Grouped because both change `utils/py/marathon_drive.py`.

### Rating rationale (2026-10-08)

- **#1001 — 80/75/50/70.** Work-blocking for every vendored marathon on a Mac that exports `XYZ_HARNESS`
  (the relay-xyz-documented setup): the lane parks on a healthy issue, and with the `MARATHON_ROOT`
  workaround ~15 tool paths still run the forge clone's (different-version) scripts. Recoverable by env
  pinning, so not the 90+ corruption band. Same class recurred: #395 (2026-09-02, closed) and #912
  (2026-10-01, open) are both a global `XYZ_HARNESS` overriding a local root — a repeat class, not one
  root cause. Effort 70: one precedence move plus two small call-site fixes.
- **#1002 — 65/65/50/55.** Discards completed work: one stray untracked probe threw away a converging
  phase (two builder/reviewer rounds, ~20 min) and burned the cap. Recoverable with `--force`. One
  incident (GH-1 Phase 2, 2026-10-02, two attempts); prior same-class: #381 (2026-09-02 exit 6 from a
  root artifact), #310 (2026-08-29 lane parked at cap). Effort 55: regex + worktree-only nested path,
  gate split, dry-run line, preamble text, two existing suites updated.
- Appeal 50 (neutral) on both; no user override.

## Recon (summary; full map with ledger in `TESTS-RESULTS/2026-10-08+GH-1001/recon.md` once recorded)

- #1001 root cause: `e53f5d06` (GH-396 PR #403 review fixups, merged 2026-09-03) put the `XYZ_HARNESS`
  check at `utils/py/harness_paths.py:44-45` **before** the `__main__`-under-`.xyz/` branch (`:46-55`).
  The first version of the module (`d639dcbc`) and pre-GH-396 `marathon_drive.py` both derived the root
  from the script's own location. Repro (vendored copy, this Mac): `XYZ_HARNESS` set →
  `harness_home=XYZ-forge is_vendored=False repo_root=XYZ-forge`; unset → `<repo>/.xyz True <repo>`.
- Secondary: `_preflight_check_issue_closed` reads the slug from `git -C root` (`marathon_drive.py:1899`)
  although `_gate_root = args.target_root or root` is computed at `:1888`; the park message (`:1917`)
  omits the repo queried.
- #1002: the verdict is `relay-automation/relay-turn-lib.sh::rtl_worktree_end` (`:862-926`); the
  GH-113 relocation `rtl_scratch_relocate` (`:1142-1160`) accepts only root-level names with
  `test_`-style prefixes. Attempt 1 failed on `test-font.mjs`/`test-satori.{cjs,mjs}` (hyphen), attempt 2
  on `tools/spike/test_satori.mjs` (nested). No "SCRATCH RELOCATION" line in any log. Every fire appends
  one line to `.tick/attempts/<lane>` (`marathon_drive.py:1143-1185`); the relay-file commit
  (`:3236-3247`) runs before `lane_attempt_gate` (`:3277`), so a capped fire adds a commit. Dry-run
  (`:3014-3027`) exits before the gate and prints no attempts line. The builder preamble
  (`utils/py/agy-turn.py:383-392`) says only tracked edits fail — not true for nested/hyphen scratch.
- Worktree copy-back is allowlist-only (`relay-turn-lib.sh:895-897`), so an untracked file outside the
  allowlist can never land in ROOT whether the turn fails or not.
- `relay-automation/marathon-drive.sh` is FROZEN (GH-308; Python is the live path), so no Bash edits there.

## Preflight bet check

- **Outcome sought:** a vendored marathon on the operator's Mac runs against its own repo with no env
  pinning, and a builder's incidental probe file costs a warning, not a phase.
- **Smallest viable bet:** reorder one precedence check; point one `git -C` at the existing `_gate_root`;
  widen one regex and allow nested names only inside the worktree path; split the cap gate into a
  read-only check before the commit and the existing append after it; one dry-run line; correct one
  prompt sentence.
- **Not built:** no change to whether containment failures count toward the cap (GH-45 stays: an outer
  re-fire loop would otherwise be unbounded); no change to the in-ROOT `rtl_check` path (nested scratch
  there still violates, `test/gh113-headless-scratch.sh:78-82` unchanged); no Bash marathon-drive edits;
  no new suite, guard or registry entry (GH-831); no fix for the other `XYZ_HARNESS`-class issue #912.
- **Alternatives rejected:** (1) read the wrapper's `XYZ_ROOT` — agent shims and
  `active_explorer.py:152` set it to other values, so it is not a reliable marker; (2) doc-only "unset
  XYZ_HARNESS" guidance — the relay-xyz docs recommend exporting it, and #395/#912 show the class
  recurs; (3) exclude containment failures from the cap — unbounded refire risk.
- **Rollback:** each change is a small hunk in one file; revert the commit. Reversibility: Easy.

## Plan

1. **A1 — `harness_home()` precedence** (`utils/py/harness_paths.py`). Move the `__main__`-under-`.xyz/`
   block above the `XYZ_HARNESS` check; keep `XYZ_HARNESS` as the fallback when the running script is
   not inside a `.xyz/`. Update the docstring to state the order. `is_vendored()` needs no change: its
   path-None branch falls through to `harness_home()`, which now returns the `.xyz` dir.
   *Verify:* rerun the repro above with `XYZ_HARNESS` exported → `<repo>/.xyz True <repo>`; red control:
   same probe on the unfixed file prints `XYZ-forge False XYZ-forge`. `bash test/gh396-find-harness-roots.sh`
   and `bash test/gh280-jog-marathon-adapter.sh` stay green with and without `XYZ_HARNESS` exported.
   Add one assertion to `test/gh396-find-harness-roots.sh` (existing suite, keeps it truthful about the
   changed precedence): a script file under a fixture `.xyz/utils/py/` with `XYZ_HARNESS` pointing at a
   different harness resolves to the fixture `.xyz`.
2. **A2 — issue-closed check repo** (`utils/py/marathon_drive.py` `_preflight_check_issue_closed`): use
   `_gate_root` for the origin lookup and the `gh repo view` fallback.
3. **A3 — park message names the repo**: `lane parked — issue N in <owner/repo> is already closed`
   (mock path prints `(mocked state)`), same text in the debug-log record.
   *Verify A2/A3:* `MOCK_GH_ISSUE_STATE=CLOSED` dry-run shows the new message; an existing suite that
   pins the old message text is updated in place (grep `already closed` under `test/`).
4. **B1 — scratch relocation** (`relay-turn-lib.sh::rtl_scratch_relocate`): accept prefixes
   `(tmp|temp|scratch|debug)` or `(test|fix|repro|probe)[-_]`; add an optional 4th arg `nested` that,
   only when passed, matches the **basename** of a nested path (file only; a collapsed `dir/` entry never
   matches) and recreates its subdirectory under the scratch dest. `rtl_worktree_end` passes `nested`;
   `rtl_check` does not. Untracked-only and dotfile rules unchanged.
   *Verify:* `bash test/gh113-headless-scratch.sh` — existing controls stay green (nested `src/tmp.json`
   via `rtl_check` still violates; tracked edit still violates; `offlane.md` still violates); extend its
   worktree block with the two observed shapes (`test-satori.mjs` at root, `tools/spike/test_satori.mjs`
   nested) → not off-lane and relocated, plus a control that nested `tools/spike/notes.md` in the worktree
   still flags off-lane.
5. **B2 — cap check before the relay commit** (`marathon_drive.py`): split `lane_attempt_gate` into a
   read-only `_lane_attempt_count()` used by a park-check placed before the relay-file write/commit, and
   the existing append at its current spot. A lane at the cap parks (exit 8) with no new commit; a lane
   under the cap behaves exactly as today (still counted once, at the same point).
6. **B3 — dry-run shows attempts vs cap**: one log line in the dry-run branch,
   `dry-run: lane <key> attempts N/<cap>` plus `— next live fire would PARK` when N ≥ cap. Read-only
   (no `makedirs`).
   *Verify B2/B3:* `bash test/lane-attempt-cap.sh`; manual check recorded under
   `TESTS-RESULTS/2026-10-08+GH-1002/`: a fixture repo with a hand-seeded `.tick/attempts/<lane>` at the
   cap → dry-run prints the PARK line; live fire exits 8 and `git rev-list --count HEAD` is unchanged
   (red control: the same fire on the unfixed driver adds one commit).
7. **B4 — builder preamble** (`utils/py/agy-turn.py:383-392`): state the real rule — scratch-shaped
   untracked files (root or nested) are relocated and reported; any other off-lane file or tracked edit
   fails the turn.
8. Docs: CHANGELOG entry; this doc's status; `TESTS-RESULTS/2026-10-08+GH-1001/` and `+GH-1002/` with
   `provenance.jsonl` for the manual checks.

## Verification route

Changed paths include Python, Bash and existing tests, so the final gate is the classified non-doc tier
(`ci-local.sh` / full `validate.sh`), run once on the final approved commit in a separate disposable
full clone. Focused suites during iteration: gh396, gh280, gh113, lane-attempt-cap, plus any suite that
greps `already closed`.

## Risks

- A1 changes precedence for a script **inside** a `.xyz/` while `XYZ_HARNESS` names a different harness
  (gh396 case (b), a main checkout's `.xyz` vs a linked worktree's). New behaviour: the running copy
  wins. Believed correct; `XYZ_CALLER_ROOT` still overrides `repo_root()`. Open question for the reviewer.
- The Bash `find-harness.sh` precedence test ("valid XYZ_HARNESS override wins over local .xyz",
  `test/gh396-find-harness-roots.sh:148-155`) is about cwd discovery by a locator that is not itself
  vendored; A1 leaves it unchanged, so Python and Bash precedence intentionally differ for the
  "running from inside .xyz" case. Open question for the reviewer.
- B1 nested relocation could hide a deliverable named like scratch outside the allowlist; it would have
  been discarded anyway (allowlist-only copy-back), and is now preserved in `.tick/scratch` with a warning.
