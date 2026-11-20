# GH-1543 (KS-15) manual check — run_record.py v1 contract

Manual check, not a test suite (`AGENTS.md` *No new tests*, GH-831). Candidate commit and file hashes
are recorded in `provenance.jsonl`.

## Checks & Results

| Check | Observed | Verdict |
|---|---|---|
| Baseline absence (6270a2b5d) | git cat-file -e rc=128 (absent before GH-1543) | pass |
| Validate run-1 baseline shape | rc=0, valid=true, amendments=4, unresolved=[OA-3:pending], gates=2 (856s + unrecorded), escalated->applied progression accepted | pass |
| Validate run-2 active shape (--require-landing-clone) | rc=0, landing_clone parsed, OA-1 superseded by OA-2, OA-2 in unresolved+escalated | pass |
| Bad-input validate: missing version | rc=1, stderr=run_record: missing mandatory RUN-RECORD-VERSION: 1 header | pass |
| Bad-input validate: wrong version | rc=1, stderr=run_record: line 1: unsupported RUN-RECORD-VERSION '2' (expected 1) | pass |
| Bad-input validate: duplicate LANDING_CLONE | rc=1, stderr=run_record: duplicate LANDING_CLONE headers at lines [2, 3] | pass |
| Bad-input validate: OPERATOR_AMENDMENT missing operator-turn cite | rc=1, stderr=run_record: line 2: OPERATOR_AMENDMENT OA-1 must cite an operator turn/comment/decision | pass |
| Bad-input validate: duplicate amendment ID | rc=1, stderr=run_record: line 3: duplicate amendment ID 'PN-1' | pass |
| Bad-input validate: APPLIED unknown ID | rc=1, stderr=run_record: line 2: APPLIED references undeclared amendment ID 'NOPE' | pass |
| Bad-input validate: APPLIED reserved word empty action | rc=1, stderr=run_record: line 3: APPLIED PN-1 missing action/reason after disposition 'escalated' | pass |
| Bad-input validate: APPLIED repeated after terminal applied | rc=1, stderr=run_record: line 4: duplicate terminal disposition for 'PN-1' (already 'applied') | pass |
| Bad-input append duplicate ID | rc=1, sha256 unchanged (93e9a6c13040) | pass |
| Bad-input append OPERATOR_AMENDMENT no cite | rc=1, sha256 unchanged (93e9a6c13040) | pass |
| Bad-input append APPLIED unknown ID | rc=1, sha256 unchanged (93e9a6c13040) | pass |
| Bad-input append APPLIED reserved empty | rc=1, sha256 unchanged (93e9a6c13040) | pass |
| Bad-input snapshot empty file | rc=1, stderr=run_record: cannot create snapshot from empty input | pass |
| Redaction sentinel (positive contamination + cleanup) | pre-snapshot matched path/token/tags; post-snapshot 0 sentinels, ~ + [REDACTED] present, validate rc=0 | pass |
| Concurrency: 8 distinct-ID parallel appends | all 8 rc=0, 8/8 amendments present, validate rc=0 (0 lost/torn lines) | pass |
| Concurrency: 4-way same-ID race | sorted exit codes=[0, 1, 1, 1] (exactly 1 win, 3 rejections), final record valid with 1 PN-RACE | pass |
| Checkpoint refusal: omitted --primary | rc=2 | pass |
| Checkpoint refusal: --clone == --primary | rc=1, run_record: refusing checkpoint: --clone resolves to --primary checkout | pass |
| Checkpoint refusal: --clone == LANDING_CLONE | rc=1, run_record: refusing checkpoint: --clone resolves to the record's LANDING_CLONE | pass |
| Checkpoint refusal: protected branch development | rc=1, run_record: refusing checkpoint on protected integration branch 'development' | pass |
| Checkpoint refusal: protected branch main | rc=1, run_record: refusing checkpoint on protected integration branch 'main' | pass |
| Checkpoint refusal: ../outside.md traversal | rc=1, run_record: --dest must not contain '..' traversal: '../outside.md' | pass |
| Checkpoint refusal: target branch escaping symlink | rc=1, starting branch preserved (development), 0 bytes outside | pass |
| Checkpoint refusal: dirty staged unrelated file | rc=1, run_record: refusing checkpoint: --clone has staged, unstaged, or untracked changes | pass |
| Checkpoint failed-push retry + bare-remote blob | retry committed=False pushed=True; bare remote changed from PRE-PUBLICATION-SENTINEL to redacted snapshot (240 bytes) | pass |
| Checkpoint idempotent no-op rerun | rc=0, committed=False, pushed=False, push_status=up-to-date | pass |

## Scope boundary

This check verifies the KS-15 record contract (`run_record.py` v1 grammar, sibling-locked atomic append,
redacted snapshot, and confined branch checkpoint) on saved fixtures and disposable local clones.
Live run-2 checkpoint publication remains uncredited until run 2 (KS-15 acceptance).
