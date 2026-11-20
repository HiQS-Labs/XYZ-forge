# GH-1543 (KS-15) manual check — run_record.py v1 contract

Manual check, not a test suite (`AGENTS.md` *No new tests*, GH-831). Candidate commit and file hashes
are recorded in `provenance.jsonl`. Full runnable commands and decisive outputs are retained in
`outputs/check-transcript.log` (and the redacted snapshot sample in `outputs/redacted-snapshot.md`).

## Checks & Results

| Check | Observed | Verdict |
|---|---|---|
| Baseline absence (6270a2b5d) | git cat-file -e rc=128 (absent before GH-1543) | pass |
| Validate run-1 baseline shape | rc=0, valid=True, amendments=4, unresolved=['OA-3:pending'], gates=2 | pass |
| Validate run-2 active shape (--require-landing-clone) | rc=0, landing_clone=~/kickstart-clones-ks1541/landing, unresolved=['OA-2'], escalated=['OA-2'] | pass |
| Bad-input validate: missing version | rc=1, stderr=run_record: missing mandatory RUN-RECORD-VERSION: 1 header | pass |
| Bad-input validate: wrong version | rc=1, stderr=run_record: line 1: unsupported RUN-RECORD-VERSION '2' (expected 1) | pass |
| Bad-input validate: duplicate LANDING_CLONE | rc=1, stderr=run_record: duplicate LANDING_CLONE headers at lines [2, 3] | pass |
| Bad-input validate: OPERATOR_AMENDMENT missing cite | rc=1, stderr=run_record: line 2: OPERATOR_AMENDMENT OA-1 must cite an operator turn/comment/decision | pass |
| Bad-input validate: duplicate amendment ID | rc=1, stderr=run_record: line 3: duplicate amendment ID 'PN-1' | pass |
| Bad-input validate: APPLIED unknown ID | rc=1, stderr=run_record: line 2: APPLIED references undeclared amendment ID 'NOPE' | pass |
| Bad-input validate: APPLIED reserved word empty action | rc=1, stderr=run_record: line 3: APPLIED PN-1 missing action/reason after disposition 'escalated' | pass |
| Bad-input validate: APPLIED repeated after terminal applied | rc=1, stderr=run_record: line 4: duplicate terminal disposition for 'PN-1' (already 'applied') | pass |
| Bad-input validate: superseded by older amendment (F3) | rc=1, stderr=run_record: line 4: APPLIED OA-2 disposition 'superseded' must name a declared newer amendment ID (declared after OA-2) | pass |
| Bad-input validate: superseded by self (F3) | rc=1, stderr=run_record: line 3: APPLIED OA-1 disposition 'superseded' must name a declared newer amendment ID (declared after OA-1) | pass |
| Bad-input append duplicate ID | rc=1, sha256 unchanged (8f95af7a619e), stderr=run_record: line 3: duplicate amendment ID 'PN-1' | pass |
| Bad-input append OPERATOR_AMENDMENT no cite | rc=1, sha256 unchanged (8f95af7a619e), stderr=run_record: line 3: OPERATOR_AMENDMENT OA-1 must cite an operator turn/comment/decision | pass |
| Bad-input append APPLIED unknown ID | rc=1, sha256 unchanged (8f95af7a619e), stderr=run_record: line 3: APPLIED references undeclared amendment ID 'NOPE' | pass |
| Bad-input append APPLIED reserved empty | rc=1, sha256 unchanged (8f95af7a619e), stderr=run_record: --kind applied requires --id and --action | pass |
| Bad-input append superseded by self (F3) | rc=1, sha256 unchanged (8f95af7a619e), stderr=run_record: line 3: APPLIED PN-1 disposition 'superseded' must name a declared newer amendment ID (declared after PN-1) | pass |
| Bad-input snapshot empty file | rc=1, stderr=run_record: cannot create snapshot from empty input | pass |
| Redaction sentinel (Bearer + Basic + Token + tokens + home path + tags, F1) | snapshot rc=0, validate rc=0, leaks=0, Bearer+Basic+Token redacted, ~ preserved | pass |
| Concurrency: 8 distinct-ID parallel appends | rcs=[0, 0, 0, 0, 0, 0, 0, 0], amendments=8, validate rc=0 | pass |
| Concurrency: 4-way same-ID race | sorted rcs=[0, 1, 1, 1], amendments=1, validate rc=0 | pass |
| Checkpoint refusal: omitted --primary | rc=2 | pass |
| Checkpoint refusal: --clone == --primary | rc=1, stderr=run_record: refusing checkpoint: --clone resolves to --primary checkout | pass |
| Checkpoint refusal: --clone == LANDING_CLONE | rc=1, stderr=run_record: refusing checkpoint: --clone resolves to the record's LANDING_CLONE | pass |
| Checkpoint refusal: protected branch development | rc=1, stderr=run_record: refusing checkpoint on protected integration branch 'development' | pass |
| Checkpoint refusal: protected branch main | rc=1, stderr=run_record: refusing checkpoint on protected integration branch 'main' | pass |
| Checkpoint refusal: ../outside.md traversal | rc=1, stderr=run_record: --dest must not contain '..' traversal: '../outside.md' | pass |
| Checkpoint refusal: .git metadata target (F2) | rc=1, stderr=run_record: --dest must not target Git metadata (.git): '.git' | pass |
| Checkpoint refusal: .git/config metadata target (F2) | rc=1, stderr=run_record: --dest must not target Git metadata (.git): '.git/config' | pass |
| Checkpoint refusal: nested .git metadata target (F2) | rc=1, stderr=run_record: --dest must not target Git metadata (.git): 'docs/.git/hooks/pre-commit' | pass |
| Checkpoint refusal: target branch escaping symlink | rc=1, starting branch preserved (development), files outside=0, stderr=run_record: target branch 'docs/sym-escape' has symlink entry at 'escape_link'; refusing before branch switch | pass |
| Checkpoint refusal: dirty staged unrelated file | rc=1, stderr=run_record: refusing checkpoint: --clone has staged, unstaged, or untracked changes | pass |
| Checkpoint failed-push retry + bare-remote blob | fail rc=1, retry rc=0 committed=False pushed=True remote_bytes=190 | pass |
| Checkpoint idempotent no-op rerun | rc=0, committed=False, pushed=False, push_status=up-to-date | pass |

## Scope boundary

This check verifies the KS-15 record contract (`run_record.py` v1 grammar, sibling-locked atomic append,
redacted snapshot, and confined branch checkpoint) on saved fixtures and disposable local clones.
Live run-2 checkpoint publication remains uncredited until run 2 (KS-15 acceptance).
