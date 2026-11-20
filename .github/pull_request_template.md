## Summary
<!-- Brief description of changes made and why -->

## Prior-Art & Ground Truth
- [ ] **Prior-Art Search Run**: `python3 utils/py/prior_art_recon.py --query "<topic>"` (or pasted `gh pr list` / grep search)
- [ ] **Grounded Recon**: Verified no overlapping PR, existing helper, or conflicting roadmap item.

## Proof of Done
- [ ] **Mechanical Verification Command**: `bash test/<existing-suite>.sh` (or `./validate.sh`, AST check, ratchet delta, or a manual check recorded under `TESTS-RESULTS/` — no new suites, GH-831)
- [ ] **Test Output**: (Paste the exact passing test output / collected count)

## Governance & PDDA
- [ ] **Linked Issue**: Closes #...
- [ ] **Capture Doc Updated**: `PROJECT/2-WORKING/GH-...` status table refreshed (or `roadmap_exempt: true`)
- [ ] **No Hardcoded Machine Paths**: Clean under `check_machine_paths.py` (0 `/Users/` violations)

## Changelog
<!-- Optional: When CHANGELOG_WRITES=landing is configured, the post-landing reconciler synthesizes the CHANGELOG.md entry from this section at merge time. If omitted or empty, the PR title is used. -->
