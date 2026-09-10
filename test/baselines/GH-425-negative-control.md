# GH-425: receipt attribution negative control

Observed 2026-09-08 in the gh425-p1 builder turn. These are focused local
observations, not a full-suite or merge-readiness attestation.

The test imports the real reconciler and creates a non-empty receipt containing
`{"pr": 999, "status": "PASS"}` for requested PR #425. Subprocess execution is
forbidden by the test; CLI boundary tests mock unrelated Git/GitHub and downstream
operations. No Git command or full project gate was run. Fixture files and raw
logs were confined to `.relay-scratch/` through `GH425_SCRATCH`.

Pre-fix `utils/py/wave_reconcile.py` SHA256:
`e1f2f79759bab3b9c19fc6f4dce68db38c3ba504879125d752d7f80c12c92c09`.

Command before changing production code (exit 1):

```bash
GH425_SCRATCH="$PWD/.relay-scratch" bash test/gh425-gate-provenance-pr.sh Receipts.test_wrong_pr_is_rejected
```

The regression assertion goes red because the old function returns success (0),
although this PR has no receipt of its own (required exit 6):

```text
test_wrong_pr_is_rejected (__main__.Receipts.test_wrong_pr_is_rejected) ... FAIL

======================================================================
FAIL: test_wrong_pr_is_rejected (__main__.Receipts.test_wrong_pr_is_rejected)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "<stdin>", line 52, in test_wrong_pr_is_rejected
AssertionError: 0 != 6 : unrelated PR #999 was accepted for PR #425:
wave-reconcile:   Provenance receipts verified for PR #425 (GH-430 compliant)


----------------------------------------------------------------------
Ran 1 test in 0.002s

FAILED (failures=1)
```

The fix accepts top-level `pr` or `pr_number` as a positive integer or decimal
string, or a `commit` exactly equal to the full `mergeCommit.oid` fetched for the
PR. Conflicting explicit PR fields cannot be rescued by a commit match. Issue
numbers, filenames, empty files, malformed/non-object JSON, and abbreviated SHAs
do not establish identity. Success names the actual receipt, JSONL line, and
matched field. It does not claim test success or Git tracking verification.

Candidate `utils/py/wave_reconcile.py` SHA256:
`67b5e706ddb6551bc6ad33816c7500bd3c87d1b714d3a09ed842998372f1c7ca`.

Command after the fix (exit 0):

```bash
GH425_SCRATCH="$PWD/.relay-scratch" bash test/gh425-gate-provenance-pr.sh
```

```text
test_cli_gate_and_ungated_path (__main__.Receipts.test_cli_gate_and_ungated_path) ... ok
test_empty_or_malformed_receipts_fail (__main__.Receipts.test_empty_or_malformed_receipts_fail) ... ok
test_later_record_and_error_log (__main__.Receipts.test_later_record_and_error_log) ... ok
test_matching_pr_names_receipt_and_field (__main__.Receipts.test_matching_pr_names_receipt_and_field) ... ok
test_merge_commit_matches_exactly (__main__.Receipts.test_merge_commit_matches_exactly) ... ok
test_metadata_requests_merge_commit (__main__.Receipts.test_metadata_requests_merge_commit) ... ok
test_missing_directory_fails (__main__.Receipts.test_missing_directory_fails) ... ok
test_missing_identity_cannot_match_null (__main__.Receipts.test_missing_identity_cannot_match_null) ... ok
test_names_and_symlinks_are_not_evidence (__main__.Receipts.test_names_and_symlinks_are_not_evidence) ... ok
test_unattributable_receipts_fail (__main__.Receipts.test_unattributable_receipts_fail) ... ok
test_wrong_pr_is_rejected (__main__.Receipts.test_wrong_pr_is_rejected) ... ok

----------------------------------------------------------------------
Ran 11 tests in 0.023s

OK
```

The same wrong-PR assertion that failed against the original implementation now
passes. Positive PR and full-commit matches, missing directory (exit 6), both CLI
flag spellings, rejection before downstream calls, and ungated behavior are
covered. Python AST parsing and Bash syntax validation also passed.

## Integration follow-up outside this turn's allowlist

`test/wave-reconcile.sh:107` creates only `{"status":"PASS","trials":10}`;
its line 243 invokes `--gate` for PRs 1001, 1002, and 1003. Static inspection shows
that fixture will be rejected by the new contract. Update it to contain explicit
receipt rows for those PR numbers. It was not edited or run: the operator permits
only the reconciler, the new focused suite, this baseline, and the relay file.
The harness owns the subsequent project gate and committed gate provenance.
