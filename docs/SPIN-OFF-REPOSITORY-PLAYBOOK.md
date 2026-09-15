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
When the child repository is the package, map the canonical parent package directory directly onto
the child root. An empty destination means “preserve paths relative to this source directory”; it
must never mean an unvalidated filesystem destination. Do not create a second landing-page source
or a redundant wrapper directory.

## 3. Bootstrap the child

Create the child only after a clean preview. Publish the closed package at its intended repository
boundary, plus the child gitignore, applicable licenses, `MANIFEST.txt`, and
`.xyz-forge-revision`. If package tooling executes from the generated repository root, recognize
that shape only through those publisher-owned control files, retain strict folder/name validation
for ordinary skill sources, and exclude VCS and repository-only metadata when installing the
package. Never publish PDDA, release/relay state, personal collections, receipts, targets, backups,
secrets, or machine-local configuration.

## 4. Add only minimum parent tests

Keep one parent end-to-end publisher contract plus the smallest detached-runtime smoke. Use a
literal expected payload set independent of the manifest and witness it fail when a required entry
is removed. Exercise preview, apply, idempotence, ownership/seed behavior when applicable,
divergence refusal, push read-back, and only the runtime behavior changed by detachment. For a
root-projected package, assert the literal root payload equals the canonical folder's tracked files,
the root README equals its canonical source, initialization installs the declared skill-name folder,
and repository metadata does not enter that installed payload. Do not add a framework, matrix, fuzz
campaign, recovery system, or mirrored child battery for an MVP.

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
