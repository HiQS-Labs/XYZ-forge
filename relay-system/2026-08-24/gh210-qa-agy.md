# RELAY · GH-210 wave_reconcile state-correctness QA (Agy)

NEXT: —
STATUS: Approved
ROUND: 4 / 4

## Setup
- Artifacts under review: PR #210 head `86586b4d` — the #202 fixes (exit-5 tolerance,
  issue-state gating) plus the round-1 review-driven changes (fail-closed live gh, live-path
  mock tests, dynamic dates, tightened idempotency). Suites: gh202 11/11, wave-reconcile 11/0.
- Reviewer: Agy (Antigravity CLI 1.1.19, `agy -p`)
- Producer: GLM 5.3 (orchestrator)
- Started/finished: 2026-08-24

## Log

### Round 1 — Reviewer (Agy): VERDICT: CHANGES-REQUESTED
Blocker: live gh failure silently promoted open issues (None-means-promote). Majors: live path
untested; hardcoded date timebomb. Minor: loose idempotency match. Note: exit-4 tolerance query.

### Round 2 — Producer: all accepted and implemented
Fail-closed die() on live gh failure ("refusing to guess issue state"); mock-gh live-path tests
(success + failure, zero mis-promotion); dynamic dates; exact-bullet idempotency. Exit-4 kept
(GH-168 scoping landed via #194) — rationale accepted round 2.

### Round 3 — Reviewer (Agy): VERDICT: APPROVED
"The critical blocker of blind promotion on live gh CLI failures has been completely
remediated with proper fail-closed logic… All changes are clean, strictly scoped to the review
feedback." No required changes.

### Round 4 — Producer disposition
Status: Approved. Merge proceeds on local gate + hosted canary verification.

---

### Reviewer output — round 1 (verbatim)

## Findings
- [SEVERITY: blocker] `gh` command failure causes silent mis-promotion — In `fetch_issue_state`, if the live `gh issue view` command fails (e.g., network error, API rate limit, or `gh` not installed), it silently catches the error and returns `None`. Because the downstream logic safely assumes `None` means "promote" for backward compatibility with legacy offline manifests, a transient `gh` failure during a live reconcile will blindly promote all open issues, corrupting the ledger state.
- [SEVERITY: major] Live `gh` code path is untested — The suite `test/gh202-wave-reconcile-issue-state.sh` uses `--offline "$REPO/manifest.json"` for both the modern and legacy manifest test cases. It completely bypasses the new live `gh issue view` subprocess logic, leaving the most fragile part of the fix entirely without coverage.
- [SEVERITY: major] Test suite timebomb (environment sensitivity) — The test suite hardcodes the date `2026-08-24` in its directory structures and fixture files (e.g., `mkdir -p "$REPO/TESTS-RESULTS/2026-08-24"`). Since `wave_reconcile.py` relies on `datetime.now()` for validation (and the PR explicitly adds `ship_date = datetime.now().strftime("%Y-%m-%d")`), this suite is time-sensitive and will falsely fail as soon as it runs on a different day. 
- [SEVERITY: minor] Idempotency string match is slightly loose — The check `if "PR #" + str(pr_id) + " merged" in content:` could theoretically match user text discussing the PR elsewhere in the document. It would be safer to check for a more specific string like `f"\n- PR #{pr_id} merged"`.
- [SEVERITY: note] Exit 4 (drift) tolerance — The PR explicitly preserves exit 4 tolerance. If GH-168 recently scoped drift such that reconciling against a drifted environment is unsafe, we may want to rethink tolerating exit 4 here. The exit 5 tolerance itself is correctly implemented as a log-and-continue.

## Required changes (if any)
- Modify `fetch_issue_state` to explicitly fail (e.g., via `die()` or by raising an exception) if the live `gh issue view` command fails (non-zero exit code or `OSError`). The `None` fallback should strictly be reserved for legacy offline manifests that lack the `"issues"` key.
- Update `test/gh202-wave-reconcile-issue-state.sh` to include a test case that runs a live reconcile (without `--offline`) and mocks the `gh` command to verify both successful issue state retrieval and safe failure handling.
- Replace the hardcoded `2026-08-24` dates in the test suite with a dynamic date evaluation (e.g., `TODAY=$(date +%Y-%m-%d)`) to prevent the test from breaking on future dates.
- (Optional) Tighten the idempotency check in `record_merge_evidence` to match the exact evidence bullet point text.

## Verdict
VERDICT: CHANGES-REQUESTED
The fix correctly implements exit 5 tolerance and successfully introduces issue-state gating for offline manifests. However, the implementation for live reconciles contains a critical safety flaw: if the `gh` CLI fails due to a network error or rate limit, it silently defaults to promoting the document, which would irreversibly corrupt the ledger state. Furthermore, this live `gh` path is completely untested by the suite, and the suite itself contains a date-based timebomb that will cause it to fail tomorrow. Please enforce strict failure on `gh` errors, cover the live path with a mock `gh` test, and use dynamic dates in the test setup.


### Reviewer output — round 2 (verbatim)

## Findings
- **Fail-closed live `gh` checks (Round 1 BLOCKER)**: Implemented perfectly. `fetch_issue_state()` now calls `die()` with exit code 6 on `OSError`, non-zero `gh` exit code, or JSON parsing failures instead of defaulting to `None` (which would have caused blind promotion). The `None` return is correctly scoped *only* to legacy offline manifests.
- **Live-path test coverage (Round 1 MAJOR)**: Added excellent coverage using a mock `gh` script injected into the test environment's `PATH`. Both the success (issue OPEN) and failure (API error via `GH_MOCK_FAIL`) paths are tested, proving that the new fail-closed behavior successfully prevents mis-promotions.
- **Dynamic test dates (Round 1 MAJOR)**: The timebomb in the test suite was cleanly resolved by generating test fixtures using `$TODAY="$(date +%Y-%m-%d)"` instead of hardcoded dates.
- **Idempotency match (Round 1 MINOR)**: Tightened the matching criteria to precisely target the exact bullet string injected (`"\n- PR #<id> merged "`).
- **Exit 4 rationale (Round 1 NOTE)**: Rationale accepted. Drift tolerance logic correctly belongs here per GH-168/PR #194.

## Required changes
None.

## Verdict
**VERDICT: APPROVED**

The producer has successfully addressed all findings from round 1. The critical blocker of blind promotion on live `gh` CLI failures has been completely remediated with proper fail-closed logic, ensuring transient API/network errors abort the run rather than modifying documents. The test suite is now robust against the progression of time and includes comprehensive live-path mocking to verify both the happy and unhappy paths of the GitHub CLI integration. All changes are clean, strictly scoped to the review feedback, and keep the PR aligned with our QA standards. Excellent work.

