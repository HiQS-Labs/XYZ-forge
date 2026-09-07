# Deploy Skills

This skill comes from **XYZ Forge**, maintained in the
[HiQS-Labs/XYZ-forge repository](https://github.com/HiQS-Labs/XYZ-forge),
at `skills/deploy-skills/`. It replaces `skills-sync-trinity`.

It gives your existing coding agent a conversational interface for managing a
durable collection of local skills. Ask it to “list my deployed skills”, “import
this local skill folder”, or “preview syncing my skills to the configured apps”.
The agent instructions live in the skill folder's `SKILL.md`.

## Where this copy lives

Initialization copies the **entire skill folder**, including this README, into
`~/Documents/Deployed Skills/deploy-skills/`. Updating the manager refreshes this
README along with its scripts and instructions. The installer also writes a real
copy at **`~/Documents/Deployed Skills/README.md`**, beside `catalog.md`.
That top-level README is installer-managed and refreshed during applied operations;
keep personal notes in a separate file. It is an actual copy, not a link
back to the source checkout, so deleting a temporary clone does not remove it.
Configured apps receive directory symlinks to the durable skill folders.

The collection's `catalog.md` lists its skills, `targets.json` records deployment
destinations, and `changelog.md` records operations. Local source paths, available
Git revisions and payload digests are recorded in `.deploy-skills.json`; those
receipts identify the particular imported copy, whereas the link above identifies
the upstream project. Keep local receipts and imported private skills private.

## Getting started

Requires Python 3.9+; macOS is the supported alpha platform. From an existing local
checkout, preview initialization, then apply it:

```bash
python3 /path/to/XYZ-forge/skills/deploy-skills/scripts/intake.py init
python3 /path/to/XYZ-forge/skills/deploy-skills/scripts/intake.py --apply init
python3 "$HOME/Documents/Deployed Skills/intake.py" list
```

Targets start disabled. Ask your agent to configure the apps you choose, preview
the changes, and sync them. Operations preview by default; `--apply` writes.
Only local Git skill folders are imported; runtime dependencies are not installed.
Overwritten skill folders are backed up as dated ZIPs, with same-day suffixes.
Foreign app folders and unrelated links are preserved rather than overwritten.

Inside the `deploy-skills` folder, see `references/targets.md` for app-specific
verification and `references/recovery.md` for backups, interruptions and migration.
