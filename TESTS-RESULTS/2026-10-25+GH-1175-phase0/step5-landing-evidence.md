# GH-416 landing evidence packet (assembled 2026-10-26 03:54:25Z → 03:56:05Z)

| Item | Value | Verdict |
|---|---|---|
| PR | #1225 `marathon/gh-416-doc-trues-up-batch-2026-10-25` → `development`, OPEN, MERGEABLE (mergeStateStatus UNSTABLE: skipped advisory jobs) | ok |
| Receipt | `marathon-drive/result@1` gh416-exec2: outcome approved, gate green, attempt 1/2, builder agy, reviewer codex | ok |
| reviewed_candidate | `80a11644` (reviewed_head `54751a04`, attest `relay-drive/attest@1`, phase_completion.candidate = 80a11644, added_sha256 5f6301e8…) | bound |
| PR head | `b8733346` = 80a11644 + one commit adding only `TESTS-RESULTS/2026-10-26+GH-416/jog/gh416-exec2/*` (4 files, +80) | allowed tail (receipt publication) |
| Product diff vs base | package.json +1/-1, package-lock.json +3/-1 (root devDependencies + `"dev": true` ×2), relay-xyz SKILL.md +2/-2 | exactly the planned scope; no test files touched despite 7 auto-allowlisted |
| Other added files | marathon-system/…/RELAY.md (+134), relay-system/2026-10-26/…-034224.md (+134), TESTS-RESULTS receipts | harness bookkeeping |
| Local gate on candidate | `validate.sh --auto development` → tier 3 full, 409/409, 787 s, receipt `.xyz/receipts/80a11644….json` | green (self-check, not promotion evidence) |
| Lane push gate | pre-push full gate GREEN 634 s (same tree) | green (duplicate run) |
| Hosted CI on PR head b8733346 | CI run 40266349575: vendored smoke gate pass; macOS promotion boundary + ubuntu canary SKIPPED (by design on PRs); CodeRabbit "rate limited" (no review) | partial: no hosted full-suite run on the candidate |
| Reviewer verdict | codex: "swept file: yes", acceptance both met, scratch probe on lock dev classification exit 0, Approved | ok |
| Acceptance in receipt | `acceptance.checked: false, unmet_count: 0` | not mechanically checked |
| Risk flags | none for behavior: no `--omit=dev`/`--production` installs anywhere; `npm ci` still installs devDependencies. | low |
| Issue closure | PR body has **no `Closes #416`**; wave_reconcile treats a mention as non-closer (GH-202) → issue and doc stay OPEN after merge | **blocker for "issue closed"** |
| `jog land` precondition | requires a **hosted wave-reconcile.yml** run green on the PR head or merge SHA; since GH-1127 (2026-10-18) that workflow is dispatch-only; last Jog landings (#1087, #942) predate GH-1127 | **blocker: needs a dispatch** |
| Primary publication checkpoint | primary has uncommitted jog-owned `releases.db/.sql` (cold-start park, retry-build, projected park) | must commit+push before merge-cleanup |
