# GH-1537 manual red/green check: pre-push own-diff routing for development merges

No new suite (GH-831). Base = `5964566ef` (`githooks/pre-push` before the change). Candidate = `githooks/pre-push` at the head
recorded in `provenance.jsonl` (`repo_head`, hook sha256 prefix per row).

## What ran

1. `check.sh` (19 scenarios x {base, candidate}, 38 real `git push` runs). Each scenario builds a fresh fixture (bare origin, a pushing
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
3. Existing suites on the candidate commit in a disposable full clone with the pinned venv (mypy 1.14.1): `gh544-pre-push-gate` 103/0,
   `gh591-prepush-commit-boundary`, `gh35-test-tiers` 72/0, `gh4-ungated-clone-warning` 6/0, `ci-route` 81/0, `ci-workflow` (all rc 0).
   `focused-suites.log`. (An earlier run without the venv failed identically on base and candidate: environment fault, not the change.)

## Result (candidate mismatches: 0; rows red on base: 8)

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
| ff_import_no_merge | full | full | full | control: linear import of development (no merge) is untouched |
| stale_base | full | full | full | control: tracking ref behind the advertised tip |
| stale_ours_merge | full | **docs** | full | stale tip AND an "ours" merge (r2 F6) |
| stale_before_merge_ours | full | **docs** | full | tracking tip older than the merged commit AND an "ours" merge (r3 residual) |
| followup_after_merge | docs | docs | docs | control: README-only follow-up after the merge was pushed stays docs |
| push_to_main | full | full | full | control: never narrowed for a push to `main` |
| two_refs_code | full | full | full | control: one code ref makes the whole push full |
| two_refs_partial_failure | full | **docs** | full | second ref's tree unreadable: partial classifier stdout no longer reads docs (r1 F3) |
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
