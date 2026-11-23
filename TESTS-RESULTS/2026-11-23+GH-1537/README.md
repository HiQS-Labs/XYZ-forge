# GH-1537 manual red/green check: pre-push own-diff routing for development merges

No new suite (GH-831). Base = `5964566ef` (`githooks/pre-push` before the change). Candidate = `githooks/pre-push` at the head
recorded in `provenance.jsonl` (`repo_head`, hook sha256 prefix per row).

## What ran

1. `check.sh` (21 scenarios x {base, candidate}, 42 real `git push` runs; each row also records the push exit status). Each scenario builds a fresh fixture (bare origin, a pushing
   clone with `githooks/install.sh` installed, a second clone that moves origin behind its back), then pushes through the installed
   stub so the hook runs exactly as git runs it. The hook and `utils/ci-route.sh` are the real files; `validate.sh` and `pdda.sh` are stubs
   that print `stub full gate ran` / `stub documentation gate ran`, and gate admission is isolated exactly as `test/gh544-pre-push-gate.sh`
   isolates it. A row counts only if the push output is non-empty and the stub gate that ran matches the route. Output:
   `red-green-table.log`, `push-output.log`, `provenance.jsonl`.
2. `replay.sh`: a real-history replay of PR #1526's final refresh push (docs-only PR; it paid a full gate for this shape on 2026-11-19).
   Remote tip `5c5557936` (docs plus an earlier development merge), local `b7102ff9e` = "Merge remote-tracking branch 'origin/development'"
   whose development parent is `6c90ed1e2`. The live remote is a local bare mirror with `development` pinned to that parent.
   Result: **base `full`, candidate `docs`**; the own-diff paths are exactly `CHANGELOG.md` and `skills/1-hourly/start-task/SKILL.md`
   (the update range carries 33 paths). `replay/replay.log`.
3. Existing suites (`gh544-pre-push-gate`, `gh591-prepush-commit-boundary`, `gh35-test-tiers`, `gh4-ungated-clone-warning`, `ci-route`,
   `ci-workflow`) via `run-focused.sh` in a disposable full clone of the task clone with the pinned venv (mypy 1.14.1): one
   `suites-provenance.jsonl` row per suite (command, tested commit, hook sha256, exit status, python/mypy/bash versions, log pointer)
   plus the clone's identity bracket before and after (`HEAD`, `core.bare`, `git remote -v` fetch/push mappings, local `user.email`, unset recorded as `<unset>`; AGENTS.md / WORKTREE-SAFETY.md). `focused-suites.log`, `suites-provenance.jsonl`.

## Result (candidate mismatches: 0; rows red on base: 10)

| Scenario | Want | Base | Candidate | What it witnesses |
|---|---|---|---|---|
| merge_only_docs | docs | full | docs | the #1574-shape refresh (docs branch + development merge) now routes by its own diff |
| conflict_docs_only | docs | full | docs | a hand-resolved docs-only conflict is still the branch's own docs |
| side_tip_on_integration | docs | full | docs | stated policy: a side commit already on development counts as integration content |
| code_branch_merge | full | full | full | control: a branch whose own diff has code still routes full |
| evil_merge_code | full | full | full | control: a resolution that adds code is not merge-only |
| ours_merge_drops_dev_code | full | **docs** | full | an "ours" merge that keeps old source and edits a README: base under-gates it (Codex plan QA r1 F1) |
| other_branch_merge | full | full | full | control: merge of a commit not on development |
| other_branch_docs_only | full | **docs** | full | same, docs-only other branch that brought newer development |
| side_merge_after_integration | full | **docs** | full | CodeRabbit Major on PR #1584: a README-only side-branch merge pushed AFTER the integration tip is already in the remote branch (red at `9c18e49f0` too: `previous-head-vs-repaired.log`, the only scenario that changed) |
| ff_import_no_merge | full | full | full | control: linear import of development (no merge) is untouched |
| stale_base | full | full | full | control: tracking ref behind the advertised tip |
| stale_ours_merge | full | **docs** | full | stale tip AND an "ours" merge (r2 F6) |
| stale_before_merge_ours | full | **docs** | full | tracking tip older than the merged commit AND an "ours" merge (plan QA r3 residual) |
| rewound_tip_ours | full | **docs** | full | tracking tip CONTAINS the merge but advertised development was rewound (final QA r1 F1; the previous candidate also routed docs here: `previous-candidate-vs-repaired.log`) |
| followup_after_merge | docs | docs | docs | control: README-only follow-up after the merge was pushed stays docs |
| push_to_main | full | full | full | control: never narrowed for a push to `main` |
| two_refs_code | full | full | full | control: one code ref makes the whole push full |
| two_refs_partial_failure | full | **docs** | full | second ref's tree unreadable: partial classifier stdout no longer reads docs (plan QA r1 F3); its push exits nonzero by construction (a deleted tree object cannot be packed), so only route and gate marker are judged |
| first_push_docs / first_push_code | docs / full | same | same | control: first push of a branch unchanged |
| linear_docs | docs | docs | docs | control: linear docs push unchanged |

## Limits stated plainly

- The fixture gates are stubs. The routing decision (which gate would run) is what is under test, not the gate bodies.
- The two code PRs the issue names, #1467 and #1574, carry code in their own diffs (`utils/py/relay_drive.py` ...; `utils/py/express.py`,
  `test/gh267-express-skill.sh`), so their refresh pushes **still route full**; the saving is for docs-only PRs such as #1526.
- A refresh that merges development into a branch and cannot be proven integration-only (stale tip, offline probe, merge of something not on
  development) now takes the full gate even where the update range alone would have read docs. That is the issue's controls (c) and (d).
- Plan QA ended at the 3-round cap without a plan-level approval; the r3 residual (`stale_before_merge_ours`) was fixed afterwards and is
  verified here and at final QA rather than at plan level.
