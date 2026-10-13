## Code Review Report: PR #1036 corrected stable candidate

**Verdict: Approved.** No outstanding confirmed Blocker or Should finding. The two original P2 findings were fixed under explicit operator authorization. Native independent final release QA round2 of cap3 is Approved. Main merge remains conditional on immediate head/base/check revalidation.

**Target:** main B `a076b1b117a68252dc3d9d1c4901b0c31fcb4db3` to frozen development F `af50c205e3f04f3fc6a02ac6c402f2013123b127`: 366 commits, 2,162 no-rename changed paths. Ground-truth review uses the complete range manifest, entry/runtime/state lanes and firsthand seam controls; it does not claim a whole-file audit of every path.

| Category | Count | Status |
|:---|:---:|:---|
| Blocker | 0 | Clear |
| Should | 0 | Original two findings resolved |
| Nit | 0 | None required |
| Pass | 8 | Source-bound checks below |

### Recon and corrected findings

- **[Pass] Adapted deletion ownership:** `utils/py/xyz_mini_sync.py:365,372,375` retains adapted-root markers in the existing manifest even when every payload is deleted. Metadata rows are excluded from deletion and failed-publication payload retry checks (`:240,368`). At F, two subsequent publications preserve the deleted entry. Original D reproduces resurrection; removing the retry marker filter in a separate fixture turns the accepted retry red. Upstream removal/re-add controls are retained in the child-fix evidence.
- **[Pass] Transaction-owned README:** `skills/3-weekly/skills-army-hq/scripts/intake.py:439,447,454,745,824` captures only a clean, tracked, regular old-manager mirror before update and rechecks the new mirror afterward. A clean manager update now commits; unrelated dirt and preexisting staged README edits refuse auto-commit. The hourly pulse remains the sole push writer. The inherited transaction still refreshes the working root README; this fix does not protect every prior working-tree README edit.
- **[Pass] Least mechanism:** both corrections extend existing ownership/transaction machinery; no new subsystem, CI suite, case or parameter. Supporting #1035 preserved both implementation and original carrier histories. #1037 plan QA Approved round1; final implementation QA Approved rounds1/2 of cap3, native Codex method.

### Exact-candidate evidence

- **[Pass] Exact F canonical full local gate:** `ci-local.sh --base B`, sequential, tier3, exit0; terminal summary10 pipeline stages passed/0 failed, envelope drift none, record retained. The406 registered shell suites plus Python and gamma yield408 recorded verdicts:407 passes and only the duplicate acorn skip, after the npm/acorn stage passed. Clone identity/envelope checks passed. External HEAD, origin, bare/shallow settings, local identity/config, git/common directories and status are unchanged. The916,525-byte shell transcript matches the gate record SHA-256 `0b16ebea7fe76cd28c7a28d9e6fac24b008ca6b2e1d8ec0d3f17831e47e97ea0`. The intentional live-agent self-sufficiency exclusion is declared; this is self-reported local proof, not main qualification. Native independent final release QA round2 of cap3 is Approved, source-bound and separately recorded; prior D Changes Requested round1 remains preserved.

- **[Pass] Hosted landing:** reconciliation38313598719 qualified landing489ba1b4 with409 passed/0 failed and no envelope drift. Its publisher F adds only10 declared governance/receipt paths, with unchanged runtime/gate blobs and no baseline SQL keys removed. Standard catchup changed the already-completed #1010 pointer from its policy doc to its recon capture; the policy doc remains unchanged. This landing run is not credited as F's final local run.
- **[Pass] Recovery:** fresh full-clone fixtures construct a merge with parents B,F and tree F. Revert mainline1 restores exact B blobs/modes/tree; mainline2 fails that comparison. Git recovery does not establish live database or installed-state recovery.
- **[Pass] Distribution package:** all18 archived relay-package members match source bytes and executable modes at F. Existing D-bound cancellation, observer, identity, selector/board and relay progress controls remain applicable because their source blobs are unchanged by D..F; receipt provenance remains D, not relabeled F.
- **[Pass] Hosted PR CI:** exact F run38321150935 succeeded after ordinary approval of that pending run; blocking vendored smoke passed. Main-only macOS and Ubuntu advisory jobs were skipped as configured. No policy or credential changed; no replacement run or bypass.

### Scope, limits and readiness

The operator explicitly deferred #954 and #1024. Unpublished admission/maintained Claude advisory recipe/live pilot and unfinished observer/intake/reconciliation/planner override work are omitted. Neither head is an ancestor or a required static API dependency of F. Separate work, #1024 FAIL/Escalated4/4 and #1031 remain intact. #930 is held; #1033 is separate; old #1034 is unmerged and untouched. All five heads were checked as known objects and not ancestors of F.

Inherited limits remain: older Darwin Python3.9 lacks os.waitid for configured xyz_work; linked-worktree config visibility is deferred; direct marathon phase signals do not prove descendant ownership. No live provider turn, installed downstream restore, provider pilot or full browser interaction was exercised; historical individual test approvals were not audited. Earlier scratch setup failures remain disclosed in the original receipts. No scope expansion, cap reset, deployment, schedule activation or cleanup was performed.

Final receipts use a separately identified evidence-carrier commit/PR recorded in the promotion body; its head differs from the tested F. F remains the tested head; changed F/B requires revalidation. Stable requires the exact resulting-main `MACOS-BOUNDARY: green SHA`; a local self-reported record, smoke or advisory canary does not establish it. Canonical #1012 issue/plan write remains separately denied by automatic approval review and was not retried.
