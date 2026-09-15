# Generated spin-off repository playbook

Use this recipe when one focused package in XYZ Forge has a distinct audience but must not become a
second maintenance authority. XYZ Forge stays authoritative; the child is a generated projection.

## 1. Qualify the split

Name one audience and use case, the exact package boundary, runtime dependencies and licenses,
managed versus child-owned seed paths, and explicit non-goals. Do not split a package that needs
broad Forge governance, databases, release machinery, or routine manual cherry-picks to work.

## 2. Declare the parent manifest

Add one explicit target profile to the existing publisher. Map tracked parent sources to child
destinations and mark each `managed` or `seed`. Keep target-specific data to the manifest, display
identity, environment variable, and default sibling checkout; do not create a plugin framework.
When a package README also serves as the child landing page, map the same canonical parent file to
both destinations. Do not create a second landing-page source that can drift.

## 3. Bootstrap the child

Create the child only after a clean preview. Publish the closed package, landing README/gitignore,
applicable licenses, `MANIFEST.txt`, and `.xyz-forge-revision`. Never publish PDDA, release/relay
state, personal collections, receipts, targets, backups, secrets, or machine-local configuration.

## 4. Add only minimum parent tests

Keep one parent end-to-end publisher contract plus the smallest detached-runtime smoke. Use a
literal expected payload set independent of the manifest and witness it fail when a required entry
is removed. Exercise preview, apply, idempotence, ownership/seed behavior when applicable,
divergence refusal, push read-back, and only the runtime behavior changed by detachment. When a
README is the child landing page, assert its bytes equal the canonical parent README. Do not add a
framework, matrix, fuzz campaign, recovery system, or mirrored child battery for an MVP.

## 5. Land, then publish

Merge the parent PR first. Publish only from a clean landed integration-branch commit. Read back
child `origin/main`, compare every managed byte and executable mode, then verify `MANIFEST.txt` and
`.xyz-forge-revision`. Link the parent issue/PR and generated child commit in the closeout.

## 6. Maintain without drift

Managed changes follow one path: parent edit and tests -> parent PR -> merge -> publisher -> child
read-back. Child seed changes stay in the child. A contribution to a managed child path must first
land in Forge. Add scheduled automation only after manual publication creates measured burden.

## 7. Roll back

For a bad publication, revert the generated child commit, repair the parent, and republish. Never
leave a managed child hand-patch that is absent from the parent.
