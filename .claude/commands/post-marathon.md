# Close out a marathon

Treat `$ARGUMENTS` as optional scope for the run being closed. Preserve all manual edits, show the
operator the exact affected files/issues/docs before consequential actions, and stop on any failed
gate or contradictory completion evidence.

1. Inventory all changed files for the run, including manual edits, and verify that none will be
   omitted or overwritten. Commit the complete reviewed change set, then push its existing branch.
2. Create a pull request with concise notes covering scope, verification, known limitations, and
   the issues resolved by the run.
3. Wait for required checks and review. Merge only when they are green and the PR is mergeable; do
   not mask, bypass, or silently retry a failure.
4. Switch back to `development` and pull the merged result so the standing WIP branch is current.
5. Close every GitHub issue actually resolved by the run, citing the merged PR. Leave partial,
   ambiguous, or unrelated issues open and report them.
6. Move each verified-complete project document to `PROJECT/3-COMPLETED`; do not archive documents
   with remaining scope or missing delivery/verification evidence. Reconcile their lifecycle state
   and pointers as required by the repository's PDDA contract.
7. Run the full PDDA sweep with `utils/pdda/pdda.sh run`. Repair only in-scope findings; if any
   finding remains, report it and do not claim the closeout is complete.
8. End by invoking `/loose-ends` for the final repository-specific cleanup and verification pass.
