# Recovery and explicit migration

All mutations default to preview. Exit 0 means the requested operation succeeded
(or a clean preview/no-op); exit 2 means failure or sync with preserved conflicts.
An OS advisory lock serializes both tools. A dead process releases its lock; a live
holder is never displaced. A pending receipt blocks further ordinary mutations.

For an interrupted operation, run `intake.py recover`, inspect its intended event,
then `intake.py --apply recover`. Recovery validates the receipt checksum and
expected pre/post state. It resumes the known operation; it does not overwrite an
unexpected external edit. Corrupt metadata/config/history or a changed pre-state
requires inspection and preservation, not deleting receipts to silence the error.
Keep the source bundle available if the copied manager is interrupted mid-swap;
its intake script can recover the same `--root`. No third recovery tool is required.

Updates and removals create verified `backups/skill-yyyy-mm-dd.zip` archives (UTC);
same-day collisions use `-02`, `-03`, etc. Verification checks file bytes, modes,
internal link text, member count and CRC before withdrawing the prior copy.
Staged old versions remain under `.staging/<operation>/old` as an additional
recovery copy; there is no automatic backup retention/deletion policy. Partial ZIPs
may remain after a failure but are never recorded as verified backups. For rollback,
prefer the intact staged prior folder after checking its digest against the history.
ZIP restore must preserve Unix permissions and symlink types (ordinary unzip tools
vary); extract into a new staging folder and verify those before replacing anything.
Do not extract over the live collection or an app root. Restore link text from the
history only when the old target exists and the app entry is free or still exactly
matches this collection. Run catalog and sync to reconcile the restored payload.

Correct but unowned links require `sync.py --adopt SKILL` followed by the same
command with `--apply`. Existing source links require `--migrate SKILL`: each must
resolve to that skill's recorded local source and match the copied digest. Old link
text is retained in ownership metadata and history. These flags do not authorize
replacement of arbitrary symlinks or real directories.

When the operator deliberately chooses a different source version (or retires an
equivalent link into a different clone), preview `--migrate-from SKILL=/old/repo/skill`.
This one-time selection must match the existing link's resolved destination and
local repo/skill identity. Unlike `--migrate`, it permits different prior content;
explain that difference and obtain that specific choice before apply. It still
cannot replace a real directory, and records the old link text for rollback.

## Retiring skills-sync-trinity

The replacement ships no old-name alias. If an old installation exists, keep its
known local source until migration finishes. Install and verify deploy-skills first,
then preview `sync.py --retire-trinity /repo/skills/skills-sync-trinity` against
enabled targets. Apply only the reviewed matches. Symlinks must point to that exact
known source. Real directories are preserved unless the operator explicitly selects
`--archive-legacy`; then content must match that source, a verified ZIP is required,
and the directory is moved to retained staging on the same filesystem. Cross-device
moves refuse with the archive retained. Unknown copies/links are conflicts, not
candidates for force-overwrite. Only the specifically named old skill is retired.

The transaction mechanism protects against interrupted local operations and
detectable external edits; it is not a security boundary against a hostile process
with write access to the same user's files. Avoid other installers changing the
same targets during a sync. There is no recursive deletion in app roots.
