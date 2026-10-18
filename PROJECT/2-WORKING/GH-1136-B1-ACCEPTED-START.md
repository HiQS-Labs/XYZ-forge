---
gh_issue: 1136
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1136
title: "merge-cleanup B1 replay drops accepted-start on replayed (added) roadmap rows"
status: Active
created: 2026-10-18
updated: 2026-10-18
owner: claude
goal: "A roadmap row added on the replayed side keeps its accepted-start (status_label in-progress) through B1, via the existing writer; repair GH-1112's lost label"
doc_type: fix
effort: 1
complexity: 2
risk: 2
phases: 1
fix_probes:
  - "grep -q 'accepted-start' skills/2-daily/merge-cleanup/scripts/ledger_merge.py"
---

# GH-1136 — B1 replay drops accepted-start on added rows

Branch `fix/XYZ-forge-gh1136-b1-accepted-start-2026-10-18` off `development@e93214fe`. Found by the Codex post-merge review on #1124.

## Status

| What was just completed | What's next |
|---|---|
| Recon + plan | Codex plan QA → implement → focused suites + manual control → final QA → PR → merge on green |

## Observed

- At #1123's B1 repair (keep=theirs, generation 1761→1778), the PR side's GH-1112 and GH-1114 rows carried `status_label='in-progress'` (`releases.sql:871-872` at 2528c264). After replay both were NULL. GH-1112 is still NULL at e93214fe; #1112 is open.
- `ledger_merge.classify` (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:228-250`) turns an **added** row into `{"op": "add", "row": row}` without checking its columns.
- `replay_ops` (`:293-328`) then runs `roadmap add`, then `rate`, then `update --section/--status-marker`. It never re-applies `status_label`, so the label is dropped silently.
- An **updated** row whose `status_label` changed already hands off honestly: `status_label` is not in `REPLAYABLE_COLUMNS` (`:52-54`, `:240-244`). No change is needed there.
- The only writer for this field is `roadmap update --gid <gid> --accepted-start` (`utils/py/releases_app.py:3900-3960`). It requires `--gid` alone, qualified owned identity, and an **open** native issue. It reads that state from GitHub and refuses otherwise. `add` re-mints the gid, so the replay must look the new gid up.

## Fix (smallest, existing writer only)

In `replay_ops`, add branch, after the existing add/rate/update steps:
- If `row.get("status_label") == "in-progress"`, resolve the new row's gid from `roadmap list --json`. Match on `gh_number` and `issue_url`, and require exactly one match.
- Then run `roadmap update --gid <gid> --accepted-start`, and log it like the other verbs.
- Any non-zero result or an ambiguous lookup **fails the replay**. That is the existing "stops at the first refusal" contract, so B1 hands off and the operator decides; nothing is dropped silently.
- A closed native issue is therefore a handoff, not a skip. Development merges do not close issues (only default-branch merges do), so this should be rare. If you think a skip-with-log is the better rule for a closed issue, say so.
- **No change** to `classify`, `REPLAYABLE_COLUMNS`, `releases_app.py` or the add, rate and update verbs.
- **Data repair** (operator-authorized as part of #1136): `roadmap update --gid rmi-01M56GEJJR4PXDB80R4JG60NG1 --accepted-start` for GH-1112, through the CLI, committed with the PR. #1112 is open. The start time becomes the repair time; the original 2026-10-17 start is lost and recorded as such in the PR.

## Verification (disposable full clone for suites; no new test file or case)

- Existing suites:
  - `test/gh436-merge-cleanup.sh`, which includes the gh534 phase B/C B1 tests.
  - Any suite that exercises `replay_ops` (bounded `git grep` at implementation).
- Manual control `TESTS-RESULTS/2026-10-18+GH-1136/replay-controls.py.txt` with `.log.txt` and `provenance.jsonl`. It runs in a temp copy of the repo's ledger, with `read_native_issue` stubbed at the subprocess boundary, because the real call goes to GitHub:
  - (a) An add op whose row has `status_label='in-progress'` ends with the label `in-progress` on the new gid.
  - (b) **Red control**, the same op on the base `replay_ops`: the label is NULL.
  - (c) An add op without the label is unchanged; no accepted-start call is made.
  - (d) A stubbed closed native issue makes the replay return False with the refusal logged.
- Pre-push gate on the final commit.

## Non-goals

- Replaying a **change** of `status_label` on an existing row (it already hands off honestly).
- Preserving the original start timestamp. The writer stamps its own time, and changing that is a writer-contract change.
- Other replay columns.

## Risk / rollback

- **Risk:** a B1 repair that previously "succeeded" (with silent label loss) may now hand off when accepted-start is refused. That is the intended fail-closed behavior.
- **Rollback:** revert the commit. The GH-1112 repair is a normal ledger write.
