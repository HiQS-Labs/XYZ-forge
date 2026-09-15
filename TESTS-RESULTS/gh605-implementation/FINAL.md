# Final GH605 lane verification — 2026-09-14

**Result: corrected code reviewed and pushed; live Rev.2 board converged; PR607
ready for review, awaiting merge.** Automatic synchronization remains disabled.

## Source and integration

The operator-authorized last two corrections are complete: mock seed-ID regression
fixed and independent full-file review Approved. Review input 96261ab2, attestation
94665101, driver exit 0, 19 files / 17,729 lines; focused Python tests 79/79.
Removing the one-line seed fix fails the distinct-ID assertion; restoring it gives
51/51 board tests. The work-state suite passes 28/28.

Final implementation candidate: `85cf25cca187eb6cf45ace571260c3db51ef8666`.
Development `4ee561ed0339777bdf8e7ef9f38de64ed55348c3` is integrated; canonical
ledger generation 648. Kanban production and GH605 tests are byte-identical to the
approved review input. Upstream GH615 test-only wrapping correction was authored
by Sol High and independently reviewed by Astra: GH615 8/8, GH616 7/7, GH617 9/9,
GH365 16/16.

## Final normal push gate

`git push origin HEAD:refs/heads/fix/work-state-projection` exited 0, no bypass.
**381/381 passed in 795 seconds** (378 registered suites plus gate invariants).
Separate full verification clone retained a clean worktree and unchanged identity:
canonical origin, core.bare=false, expected user email, HEAD=85cf25cc.

Log: `forge-gh605-verify-20260913/temp/gh605-validation/settled-final-prepush.log`.
SHA256: `3f989e3f79daee6faad358d5d5d4b0a2be66c7bee48931390ef529afe0d08a01`.

The earlier partial ef231262 gate was deliberately interrupted (exit 143) before
publication to integrate the incoming GH617 ledger conflict. It is not a pass or
a test failure. Its separate `approved-final-prepush.log` is retained.

PR607 was made ready for review, then returned to draft after the live acceptance
probe exposed the JSON-boundary defect below. Base development, mergeable, not merged. Hosted smoke
and CodeRabbit passed on 85cf25cc; macOS promotion and Ubuntu canary were skipped,
not claimed as executed promotion.

## Local policy and live application

Local settings are saved in `~/.xyz/device_config.json`. The policy metadata now
reports `available_manual`; automatic `work_connectors.github_board.enabled`
remains false. Scope is noelsaw1/project4, XYZ Forge only, Ready top10, Done7days,
activity3days. No automatic rollout or primary-checkout deployment is included.

The first final apply refused source-digest drift before creating an audit or
writing to the board. The refreshed preview had identical changes and board;
only updated_at on PR607/618 changed. The second apply refused unresolved drift,
again before audit creation or writes. Local replay proved decisions identical,
but fresh unresolved identities were tuples while saved JSON contains lists;
JSON-normalizing the fresh unresolved list made it exactly equal to the saved list.

Sol High corrected one producer output expression and extended the existing real
integration fixture with a missing-ledger OPEN issue. Witnessed red before fix;
51/51 board tests green after. The fixture asserts JSON round-trip equality,
successful apply with nonempty unresolved evidence, preservation of the unknown
issue, and refusal of genuine unresolved tampering. No drift comparison is relaxed.
Fresh bounded relay round7 Approved, driver exit0, reviewed
`d43616f7885b4082a84f5794efc2cd5350c98097`, attestation dc218240. Full current
board_sync1492lines and board-policy1012lines were read; prior round6 approval
applies only to the unchanged broader surface. Parent independently79/79pass.
Parent focused-log SHA256:
`5e9256a1314e9bad30f642aac102f0bcb2e813e4eb63b30d42f053ab05489fef`.
The corrected candidate `dc21824044a166a816d8236b1dd3daeadbb2e569` passed its normal
push gate381/381 in789seconds, exit0, and published without bypass. The full clone
retained a clean worktree and unchanged origin/core.bare/email/HEAD identity.
Log SHA256: `8aaff3a86bfbba7e94dd2dc821ef32aab84b8a637155933cfc00c84c0a8a0f27`.
This is branch push-gate evidence, not a production promotion receipt.

During the corrected candidate's parallel gate, GH53's ordinary merge fixture
failed with `dump-duplicate-setting` for `generation`. No production comparison
was weakened: independent serial reproduction in full clone2 passed15/15. The
gate's existing serial retry also passed and classified this suite as contended.
Retained parallel log SHA256:
`44823fe8d0d3a4ea9ef4db1bd7ed79e2793337415f47f9eac6b3011c0fa56e12`.
Independent serial log SHA256:
`83e8f2b462cc803300915a0b51457bfb3dbd7f314fb7b3fd9c5b5fd035953f09`.

## Live convergence result

The corrected preview proposed64changes:52Done,9In review,3Backlog. Initial apply
completed64/64 with durable request acknowledgements. Independent readback found
six newly added linked issues592/593/595/603/605/613 in In progress despite successful
writes to the verified In review option df73e18b. The source of those subsequent
changes is unproven (a board workflow is a possibility). A fresh preview isolated
those six corrections; one fresh audited apply completed6/6. No blind mutation retry,
workflow/config change, or card deletion was performed.

Independent paginated GitHub readback then verified every original64 target status,
no missing original IDs, no duplicate identities, and exact preservation of Ready10
and original In progress6 (issues5/32/141/201/325/496). Final123cards:
Ready10, In progress6, In review15, Done89, Backlog3. Issues463/471/475 moved from
Done to Backlog because they are outside7days; none was deleted.

Fresh policy preview at2026-09-14T07:50:18Z returned0changes,0warnings. It still
reports120unresolved repo identities, primarily missing-ledger open issues, plus
ambiguous/reopened/stale evidence. Those are preserved/unknown, not verified idle
or active. The operational policy is applied, not a claim of perfect source data.

Raw artifacts remain in the originating Codex workspace and task clone temp logs;
sanitized hashes/counts are in completion.json. Keep clones and local-only audits
until PR607 is merged and the cleanup SOP can prove safe removal. No merge occurred.
