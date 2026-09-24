VERDICT: safe with change — adjust F1's condition to `force_promote or issue_state == "CLOSED" or (is_merged and issue_state is None)` (do not let `is_merged` override `issue_state == "OPEN"`).

---

### 1. F1 Narrowing vs MERGED Closers
- **MERGED closers do not need gating on `"CLOSED"` in live mode**: live `fetch_issue_state` ([utils/py/wave_reconcile.py:305-322](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/wave_reconcile.py#L305-L322)) queries GitHub and aborts (`die`, exit 6) on any failure; it returns only `"OPEN"` or `"CLOSED"`. `None` occurs only offline for legacy manifests.
- **Why F1 as proposed is flawed**: `force_promote or is_merged or issue_state == "CLOSED"` evaluates to `True` when `is_merged` is true and `issue_state == "OPEN"`. At call site 2 ([utils/py/wave_reconcile.py:2123](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/wave_reconcile.py#L2123), when `doc_path` is `None`), this would mark an open issue Completed in [ROADMAP.md](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/ROADMAP.md) / [releases.db](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/releases.db) on a merged PR, violating GH-202.
- **The right formula**: `force_promote or issue_state == "CLOSED" or (is_merged and issue_state is None)` at [utils/py/wave_reconcile.py:327](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/wave_reconcile.py#L327). This keeps GH-202 open-issue protections intact while restoring legacy offline promotion for merged PRs and requiring confirmed CLOSED for declined PRs.

### 2. F3 vs Code: Native-Read Failure in `reconcile-state`
- **Refusing the sweep is correct (keep writer code; edit fixture via F3)**.
- In [utils/py/releases_app.py:4066-4071](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/releases_app.py#L4066-L4071), #527's per-row skip applies strictly to *local ledger data defects* (mismatched URL/number or unresolvable identity) before remote calls.
- Once identity is valid, remote I/O failures in [`read_native_issue`](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/releases_app.py#L5410-L5425) ([utils/py/releases_app.py:4074](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/releases_app.py#L4074)) and `gh issue view` ([utils/py/releases_app.py:4086](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/releases_app.py#L4086)) indicate API outages, rate limits, or auth drops. Skipping per-row on network errors would guess by omission.
- The failure in [test/gh527-issue-url-repair.sh:142-147](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/test/gh527-issue-url-repair.sh#L142-L147) was caused purely by `fake-gh` lacking the REST `api repos/.../issues/N` endpoint; F3 fixes the mock to model real CLI contracts.

### 3. F4: Tolerating Missing `repos` Table
- **Fixture-side fix is the only legitimate fix**.
- The `repos` table is not from migration 003; it was defined in `MIGRATION_001` ([utils/py/releases_app.py:496](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/utils/py/releases_app.py#L496)). Every valid production `releases.db` has had `repos` since inception.
- [test/gh496-phase2-reconciliation-views.sh:93-117](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/test/gh496-phase2-reconciliation-views.sh#L93-L117) manually created a partial schema that populated `roadmap_items.repo_id = 1` without creating `repos`. Tolerating missing `repos` in product code would weaken repo-identity scoping for broken test mocks.

### 4. Weakening Landed Controls
- **None of the fixture edits weaken landed controls**:
  - **F2**: Updates [test/wave-reconcile.sh:138-146](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/test/wave-reconcile.sh#L138-L146) to provide the confirmed close GH-646 now requires for declined PRs, and adds a red control (PR 1004 / GH-778) verifying unknown-state declined PRs remain in `2-WORKING`.
  - **F3**: Updates [test/gh527-issue-url-repair.sh](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/test/gh527-issue-url-repair.sh) `fake-gh` to satisfy REST schema; GH-901 is still proven skipped per-row and GH-900 is still reconciled.
  - **F4**: Updates [test/gh496-phase2-reconciliation-views.sh](file:///Users/noelsaw/Documents/GitHub%20Repos/XYZ-forge-gh646-pr-completion/test/gh496-phase2-reconciliation-views.sh) to include `repos`, restoring Schema 001 conformance without altering test assertions.
