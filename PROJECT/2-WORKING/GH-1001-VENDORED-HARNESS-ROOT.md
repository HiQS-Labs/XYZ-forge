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
| Implemented A1–A3/B1–B4; focused suites + ci-local green (4b2aa888); red controls recorded; Codex final QA Approved r1 (attested). | PR open against development; awaiting merge. |

## Issue map (one branch, one PR)

| Issue | Scope | Rating (pri/sev/appeal/effort) | Acceptance | State |
|---|---|---|---|---|
| [#1001](https://github.com/HiQS-Labs/XYZ-forge/issues/1001) | `harness_home()` precedence; issue-closed check repo; park message | 80/75/50/70 | A1–A3 | PR ready; awaiting merge |
| [#1002](https://github.com/HiQS-Labs/XYZ-forge/issues/1002) | GH-113 scratch relocation; cap gate order; dry-run cap line; builder preamble truth | 65/65/50/55 | B1–B4 | PR ready; awaiting merge |

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
  incident (GH-1 Phase 2, 2026-10-02, two attempts); prior same-class: #381 (2026-09-02, an unresolved
  exit-6 containment failure; its root-artifact cause is still a hypothesis), #310 (2026-08-29 lane parked at cap). Effort 55: regex + worktree-only nested path,
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
   *Verify (split route, plan QA S5):* the targeted running-`.xyz` assertion below passes **with** a
   foreign `XYZ_HARNESS` exported (red control: the same probe on the unfixed file prints
   `XYZ-forge False XYZ-forge`); the complete focused suites `bash test/gh396-find-harness-roots.sh` and
   `bash test/gh280-jog-marathon-adapter.sh` pass with ambient harness-location overrides cleared
   (`env -u XYZ_HARNESS -u XYZ_REPO_ROOT`). A1 does not claim to repair the locator/runner inheritance
   failures tracked in #912 (out of scope).
   Add one assertion to `test/gh396-find-harness-roots.sh` (existing suite, keeps it truthful about the
   changed precedence): a script file under a fixture `.xyz/utils/py/` with `XYZ_HARNESS` pointing at a
   different harness resolves to the fixture `.xyz`.
2. **A2 — issue-closed check repo** (`utils/py/marathon_drive.py` `_preflight_check_issue_closed`): use
   `_gate_root` for the origin lookup and the `gh repo view` fallback.
3. **A3 — park message names the repo**: `lane parked — issue N in <owner/repo> is already closed`
   (mock path prints `(mocked state)`), same text in the debug-log record.
   *Verify A2/A3 (plan QA S2):* a command-recording manual check under `TESTS-RESULTS/2026-10-08+GH-1001/`
   (source-closure harness like the reviewer's probe, stubbed `_cmd_out`, no real git/gh): with
   `root=harness`, `_gate_root=consumer`, issue CLOSED in harness and OPEN in consumer → queries consumer
   and continues; states reversed → exit 4 with stderr and debug record naming consumer; forced
   `gh repo view` fallback runs with `cwd=consumer`. Red control: the unfixed function queries
   `git -C harness` and parks on the harness state. The `MOCK_GH_ISSUE_STATE` check stays only for the
   mocked-message branch; an existing suite that pins the old message text is updated in place
   (grep `already closed` under `test/`).
4. **B1 — scratch relocation** (`relay-turn-lib.sh::rtl_scratch_relocate`): accept prefixes
   `(tmp|temp|scratch|debug)` or `(test|fix|repro|probe)[-_]`; add an optional 4th arg `nested` that,
   only when passed, matches the **basename** of a nested untracked **file** and recreates its
   subdirectory under the scratch dest. `rtl_worktree_end` passes `nested`; `rtl_check` does not.
   Untracked-only and dotfile rules unchanged.
   **Collapsed untracked directories (plan QA S1, Modified):** git's default porcelain reports a wholly
   new directory as one `dir/` entry, so a probe inside it never reaches the file check. Rather than
   switching the whole worktree scan to `--untracked-files=all` (which would expand every untracked tree,
   e.g. a builder's `node_modules/`, into per-file entries and change GH-59 collapsed-directory
   handling for every turn), `rtl_worktree_end` expands **only** a `dir/` entry that is not allowlisted
   and not containment-ignored: `git -C "$wt" ls-files --others --exclude-standard -z -- dir/`. If every
   file in it is scratch-shaped, each is relocated and the entry passes; if any is not, the entry is
   off-lane exactly as today and nothing is moved.
   *Verify:* `bash test/gh113-headless-scratch.sh` — existing controls stay green (nested `src/tmp.json`
   via `rtl_check` still violates; tracked edit still violates; `offlane.md` still violates); extend its
   worktree block with the two observed shapes (`test-satori.mjs` at root, `tools/spike/test_satori.mjs`
   nested inside an **already tracked** directory) → not off-lane and relocated; a wholly **new**
   directory containing only `probe_x.mjs` → relocated, OFFLANE=0; the same new directory with
   `notes.md` beside the probe → OFFLANE=1, nothing relocated and nothing copied back. Red controls (plan QA S6):
   the **positive** relocation assertions (hyphenated root probe, nested probe in a tracked directory,
   scratch-only new directory) must fail on the base revision; the **mixed-directory refusal**
   assertion already holds on base, so its red witness is a temporary mutation in the disposable
   candidate clone that makes the all-files-scratch decision accept a mixed directory — the OFFLANE=1
   assertion must go red, then green again once restored. Both receipts with provenance go to
   `TESTS-RESULTS/2026-10-08+GH-1002/`. Suites run in a
   disposable full clone for candidate and base.
5. **B2 — cap check before the relay commit** (`marathon_drive.py`): reuse the existing read-only
   reader `debug_mantra_prior_attempts` (`:1206-1216`, plan QA N1 — renamed to a neutral
   `lane_attempt_count` with the debug-mantra caller at `:2929` kept on it) for a park-check placed
   before the relay-file write/commit; the single append stays in `lane_attempt_gate` at its current spot.
   The pre-commit check ignores an inherited `LANE_ATTEMPT_COUNTED` (as the driver already clears it at
   `:3272-3277`), honors `--force`, and keeps the parked receipt count, stderr text and debug-log record
   (`:1171-1181`). A lane at the cap parks (exit 8) with no new commit; a lane under the cap behaves
   exactly as today (counted once, at the same point).
6. **B3 — dry-run shows attempts vs cap**: one log line in the dry-run branch,
   `dry-run: lane <key> attempts N/<cap>` plus `— next live fire would PARK` when N ≥ cap **and not
   `--force`**; with `--force` at or over the cap it says `— --force set: next live fire proceeds`
   (plan QA S3). Read-only (no `makedirs`).
   *Verify B2/B3:* `bash test/lane-attempt-cap.sh`; manual check recorded under
   `TESTS-RESULTS/2026-10-08+GH-1002/`: a fixture repo with a hand-seeded `.tick/attempts/<lane>` at the
   cap → dry-run prints the PARK line, and with `--force` the proceed line, both leaving attempt-file
   bytes and HEAD unchanged; live fire exits 8 and `git rev-list --count HEAD` is unchanged (red control:
   the same fire on the unfixed driver adds one commit); inherited `LANE_ATTEMPT_COUNTED=1` at cap still
   parks; an under-cap fire adds exactly one attempt line; a forced capped fire adds exactly one; a parked
   fire adds none. Existing gh280 C8 receipt assertions (`test/gh280-jog-marathon-adapter.sh:340-347`)
   stay green. `test/lane-attempt-cap.sh` measures the Bash helpers only, so it is supporting, not proof.
7. **B4 — builder preamble** (`utils/py/agy-turn.py:383-392`): state the real rule — scratch-shaped
   untracked files at the root are relocated and reported; nested ones too, **but only in an isolated
   worktree turn**; in a non-isolated turn a nested one still fails, and any other off-lane file or
   tracked edit fails the turn (plan QA S4). *Verify:* manual prompt-text check under GH-1002 evidence
   (grep the rendered preamble for the worktree qualifier; red control: base text lacks it).
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
