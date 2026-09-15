# Skills Army HQ

Your coding agents should share the same skills—not drift into separate, forgotten copies.

Skills Army HQ gives Claude Code, Codex, Antigravity, ZCode, and other compatible tools one durable
headquarters for reusable agent skills. Ask an agent to import or update a local skill once, preview
the rollout, and deploy directory links to every app you have chosen.

## What it gives you

- **One skill collection:** every configured app reads the same durable copy.
- **Conversational operations:** ask an agent to list, import, update, remove, deploy, or inspect
  skills instead of hand-copying folders.
- **Preview-first safety:** writes require `--apply`; foreign folders, unrelated links, and ownership
  conflicts are reported rather than overwritten.
- **Health checks:** identify missing or stale links, pending changes, conflicts, and recorded runtime
  prerequisites without changing the filesystem.
- **Recoverable updates:** replaced skills receive verified ZIP backups and transaction receipts;
  interrupted operations have an explicit recovery path.
- **Multi-app reach:** configure only the discovery folders you actually use. Targets begin disabled,
  and app discovery is verified separately from filesystem deployment.

The result is simple: improve a skill once, then deliberately roll that exact version across your
agent tools without wondering which copy each one loaded.

## The problem it solves

Without a shared collection, a useful new skill reaches Claude Code but not Codex, or yesterday's
copy remains in Antigravity after today's fix. Manual copying creates invisible version drift.
Skills Army HQ keeps the payloads in one place and makes deployment state inspectable.

The default collection used by XYZ Forge lives at `~/git-pulse-sync/Deployed Skills`, where Git Pulse
can carry the portable skill payloads between machines. Machine-specific targets, receipts, history,
backups, and configuration remain local and excluded from publication.

## Origin

This skill comes from **XYZ Forge**, maintained in the
[HiQS-Labs/XYZ-forge repository](https://github.com/HiQS-Labs/XYZ-forge),
at `skills/skills-army-hq/`. It replaces `skills-sync-trinity`.

It gives your existing coding agent a conversational interface for managing a
durable collection of local skills. Ask it to “list my deployed skills”, “import
this local skill folder”, or “preview syncing my skills to the configured apps”.
The agent instructions live in the skill folder's `SKILL.md`.

## Source ownership

XYZ Forge is the authoritative source for this managed package. The
[`HiQS-Labs/XYZ-skills-army-mini`](https://github.com/HiQS-Labs/XYZ-skills-army-mini) is a generated
projection: change managed files in
XYZ Forge, merge them, and republish. Do not maintain equivalent patches in both repositories.
Local collections and their receipts, targets, catalogs, history, backups, and imported skills are
operator-owned state and are never part of the generated repository.

## Where an installed copy lives

Initialization copies the **entire skill folder**, including this README, into
`~/git-pulse-sync/Deployed Skills/skills-army-hq/`. Updating the manager refreshes this
README along with its scripts and instructions. The installer also writes a real
copy at **`~/git-pulse-sync/Deployed Skills/README.md`**, beside `catalog.md`.
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

Requires Python 3.9+; macOS is the supported alpha platform. Clone the standalone repository, choose
a separate empty collection directory, preview initialization, then apply it:

```bash
git clone https://github.com/HiQS-Labs/XYZ-skills-army-mini.git
cd XYZ-skills-army-mini
python3 ./scripts/intake.py --root "/path/to/Deployed Skills" init
python3 ./scripts/intake.py --root "/path/to/Deployed Skills" --apply init
python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" list
```

Targets start disabled. Ask your agent to configure the apps you choose, preview
the changes, and sync them. Operations preview by default; `--apply` writes.
Only local Git skill folders are imported; runtime dependencies are not installed.
Overwritten skill folders are backed up as dated ZIPs, with same-day suffixes.
Foreign app folders and unrelated links are preserved rather than overwritten.

## Health check

Ask your agent: **“Run a health check on my deployed skills.”** The health check
uses the existing sync tool's read-only status command; no separate script is needed:

```bash
python3 "$HOME/git-pulse-sync/Deployed Skills/sync.py" --status
```

It validates the local collection and reports missing or incorrect directory
symlinks for enabled targets, stale managed links, ownership conflicts, and recorded
runtime prerequisites. It does not copy, delete, repair, or change settings.
Apps share the durable skill copies through symlinks, not separate payload copies.

Read the report: `actions` are pending link changes, `changes` are pending ownership
updates, and `errors` are conflicts or validation failures. Deployment is in sync
when all three are empty. Exit code `2` indicates errors; **exit code `0` alone does
not prove health**, because pending changes can still be reported. Disabled targets
are not required deployment destinations. Ask for a sync separately to apply repairs;
foreign entries require explicit review rather than automatic replacement.

This is a filesystem deployment health check, not proof that an app or extension
has loaded a skill or that its runtime dependencies work. Report app discovery and
runtime readiness separately as verified or unverified.

See [target setup](https://github.com/HiQS-Labs/XYZ-skills-army-mini/blob/main/references/targets.md)
for app-specific discovery guidance and
[recovery](https://github.com/HiQS-Labs/XYZ-skills-army-mini/blob/main/references/recovery.md)
for backups, interruptions, relocation, and migration.
