# Recovery and explicit migration

## Retargeted owned links

`--adopt`, `--migrate`, and `--migrate-from` do not override a retargeted link that
already has an ownership receipt. Stop the competing installer first. With explicit
operator approval, inspect the exact app entry with `ls -ld` and `readlink`, and
record its old link text in a separate recovery note outside the app's discovery
folder. Verify the intended copied skill is intact. Remove **only that symlink**
with `unlink /exact/app/skills/skill-name` (no trailing slash, no recursive command,
never a real directory). This is the narrow manual recovery exception to the
normal script-only rule; do not edit receipts. Preview `sync.py --status`: it must
plan to recreate that exact entry pointing into the collection. Apply `sync.py
--apply`, then verify read-through and the new sync event in `changelog.md`.
Unrelated conflicts may still yield exit 2; inspect each result. The separate note
preserves the external link text, which sync cannot recover after it is removed.

## Interrupted first initialization

If `.deploy-skills-pending.json` exists, use the source bundle's `intake.py --root
/exact/collection recover`, then the same command with `--apply` before `recover`.
Recovery works even before the first state file has been published.

A failure **before** the pending receipt is written may leave a lock file or staged
copy but no recoverable transaction. Do not blindly ignore or delete these names:
they do not prove ownership. Confirm no initializer is running, inspect the exact
folder, and obtain approval to move the whole failed collection to a uniquely named
backup outside any app discovery root. Retry `init` at the now-absent original path,
using the intact source bundle. Preserve the failed folder until the new collection
is verified. This conservative alpha procedure is intentional; retry does not
silently erase partial state or user files.

## Moving the collection and concurrent previews

Do not rename or move an initialized collection as routine file housekeeping: its
absolute root and link destinations are recorded in metadata. If accidentally
moved, restore the original path before operating. A deliberate relocation is not
automated in this alpha: preserve the old collection, withdraw its owned app links
through disable/sync, initialize a new empty `--root`, and re-import local source
skills and configure targets there. Retain old backups/history separately; never
rewrite receipts to pretend they belong to the new root. Locally edited payloads
need preservation in a local source repository before re-import.

### Relocating into a git-synced checkout (GH-536)

When the new `--root` lives inside a checkout that another scheduled writer pushes
(a Git Pulse sync checkout, say), three extra rules apply — all learned live, each
from a real leak or wedge:

1. **Exclude machine state before the first push.** The collection's `.gitignore`
   must carry at minimum: `.deploy-skills.json`, `.deploy-skills-pending.json`,
   `targets.json`, `backups/`, `*.zip`, `*.lock`, `.staging/`, `__pycache__/`,
   `*.pyc`. Note `*.lock`, not `.lock` — the first push leaked
   `.deploy-skills.lock` on exactly that distinction.
2. **Commit immediately after every mutation.** The carrier's pre-write
   `pull --rebase` refuses on uncommitted tracked changes, wedging its whole
   cycle (observed: exit 128, the documented 229-run failure class).
3. **Verify cross-device digests against the checkout's copy, not the
   publisher's live folder** — git normalizes file modes (only the executable
   bit survives), so byte-identical payloads can digest differently.

Adoption on other machines does NOT bootstrap state inside the shared checkout;
see SKILL.md → "Adopting the collection on another machine".

Previews deliberately take no write lock. Do not run them during an apply: they
can observe intermediate state and report transient conflicts. Wait for the writer
to finish, then preview again; never delete its lock file.

## Renaming an existing deploy-skills alpha collection

Keep the existing collection and its `.deploy-skills*` metadata filenames; the
brand change does not reset history or ownership. Preview each command, then repeat
with `--apply` (before intake subcommands): use the new bundle's intake to `add`
the local `skills-army-hq` folder, then `activate-manager`. Run the collection's
`sync.py` to install the new app links. Finally `remove deploy-skills` (creates a
ZIP), and sync again to withdraw only its owned old-name links. Inspect conflicts;
never delete foreign entries. The new manager is protected from removal, and the
old manager cannot be removed while its convenience links remain active.

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
known local source until migration finishes. Install and verify skills-army-hq first,
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
