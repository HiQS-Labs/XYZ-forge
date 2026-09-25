# Test admission: one coverage decision per change

Agents must disclose proposed test growth and obtain the operator's GitHub review before landing changes. The gateway prepares and validates coverage decisions; it does not decide that valid JSON deserves approval. The execution registry remains `validate.sh` plus its existing non-shell lanes.

**Activation status:** implementation under PR #811. Native protection and separated agent credentials must be verified before this is described as enforced. A local hook can be bypassed; a candidate-authored status is not human approval.

## Author flow

1. Inspect existing coverage and choose `reuse`, `extend`, `add`, or `no-add`. Prefer an existing suite when it covers the behavior; do not manufacture tests to demonstrate activity. In a rationale JSON under `temp/`, supply exactly `outcome`, `behavior`, `existing_coverage`, `reason`, `red_evidence`, `cost`, and a full GitHub `issue` URL; values are nonempty strings, with an explanation for unknown cost.
2. Stage only intended changes, then run `python3 utils/py/gate_inventory.py admission prepare --rationale temp/coverage.json`. The tool writes `.github/test-admission.json`, binding the complete staged change set to the integration merge-base; stage that packet and commit. Re-run prepare after further edits, including evidence/doc changes in a PR containing code. Existing files edited to add assertions, weakened/deleted tests, moved files, and product changes invalidate the packet too.
3. Run `python3 utils/py/gate_inventory.py admission check`. The installed push hook runs this check before expensive tests. It validates a proposal, not an approval; normal verification and the push gate still apply. Pure documentation changes outside execution-sensitive paths are explicitly reported without a packet.
4. Publish the pushed branch with `python3 utils/py/gate_inventory.py admission publish --title 'Describe the change'`. The trusted development workflow opens/reuses a GitHub Actions bot PR and explicitly dispatches admission and CI. It refuses an existing human-authored PR rather than silently duplicating/replacing it. Inspect both exact-head check results; a dispatched workflow is not a passing check.
5. The operator reads the admission summary and complete diff, then uses **Review changes → Approve** on GitHub. New commits dismiss approval. Agents must never use the operator's credentials to submit this review. `python3 utils/py/gate_inventory.py admission catalog --pr NUMBER` generates the current catalog view from Git objects and authenticated GitHub review records; same-author, stale, absent or dismissed reviews are not accepted.

The report separates new/modified/deleted test **files**, registered shell-suite delta, and unknown case counts. A renamed test appears as deletion plus addition. `add` is required for new test-tree files; even helper additions require explicit disclosure. Case/invariant counts and semantic value are not inferred from filenames. Review the actual assertions, execution cost and overlap; there is no numerical test quota.

## Authority and credentials

GitHub's native required CODEOWNER review is the approval authority. The generated packet and catalog are projections, not a second execution registry or approval database. Git history retains packet revisions; GitHub retains review identity, revision and dismissal. The hosted check executes trusted development code and reads candidate Git objects as data, never running candidate scripts with its privileged token.

The operator is `noelsaw1` (GitHub ID 56978803). Bot-authored PRs avoid GitHub's author self-review restriction. GitHub authenticates accounts, not physical humans: **human-only approval requires agent credentials without pull-request review write or repository administration permission**. Provide agents a fine-grained token limited to this repo with Contents write, Pull requests read and Actions write; keep the operator's review/admin credentials out of their runtime. Review organization policy and Git transport credentials too; a restricted `GH_TOKEN` alone does not remove a broader token still available through `gh auth` or another runtime. No script here creates or silently replaces credentials.

## Activation and rollback — operator handoff

These are deployment steps, not performed merely by opening PR #811. The current PR is operator-authored and therefore needs an explicit bootstrap landing decision; do not forge a review or silently replace it.

1. Review/land the implementation on `development`, the current default branch. Verify the two workflows, CODEOWNERS, and protected reconciliation publisher are present there. Save the existing branch-protection, ruleset and Actions-permission responses for rollback.
2. Separate agent credentials as described above. In repository Actions settings, allow GitHub Actions to create pull requests (the API setting is `can_approve_pull_request_reviews=true`; native sole-CODEOWNER approval still excludes the bot). Keep default workflow permissions read-only.
3. Publish a real bot-authored change through the gateway, verify the current-head `test admission` and `vendored smoke gate (blocking on development + main)` checks, and inspect the coverage summary. Approve through the operator's browser; push a revision and witness dismissal/refusal until approved again. Verify bot updates and protected reconciliation dispatch, not only ordinary user-created PRs.
4. Apply native protection to `development`: required PR approval count 1; require CODEOWNER review; dismiss stale approvals; enforce for administrators; no bypass allowances; force pushes/deletions disabled. Set `require_last_push_approval=false` because task branches can be pushed by the operator account. Require the two named checks from GitHub Actions app ID 15368, with branches up to date. Read the resulting policy back and verify CODEOWNERS has no errors. Check names alone are not the human approval boundary.
5. Witness rejection of unapproved/missing/stale coverage and a direct integration push without risking an actual unreviewed landing. Confirm legitimate operator-reviewed coverage can land. Until those live checks and credential separation are demonstrated, label rollout **not activated/verified**. Do not close #805 merely because the local gate is green.

Protection payload (review before applying; do not overwrite an existing policy without merging its requirements):

```json
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context": "test admission", "app_id": 15368},
      {"context": "vendored smoke gate (blocking on development + main)", "app_id": 15368}
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "require_last_push_approval": false,
    "bypass_pull_request_allowances": {"users": [], "teams": [], "apps": []}
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

Under protection, the hosted reconciler publishes only its existing allowlisted artifacts plus its generated coverage packet through a bot PR. Pending reconciliation review pauses further expensive qualification; merged publication is excluded only when bot identity, branch namespace and the actual landed allowlisted diff match. No Actions direct-push bypass is granted. Unprotected downstream deployments retain their existing publishing behavior.

Rollback requires a reviewed revert and explicit restoration of the saved policy. A broken check must fail visibly; it must not remove protection or fall back to direct pushes. No approval service, extra model call per test, new database, automatic test deletion, or legacy-suite approval backfill is installed.
