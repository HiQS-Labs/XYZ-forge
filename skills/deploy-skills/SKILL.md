---
name: deploy-skills
description: >-
  Manage a durable local skill collection and global app symlinks through conversation.
  Use to import, update, list, remove, or deploy skill folders from repositories already
  on disk, configure deployment targets, or replace skills-sync-trinity. Not for remote
  downloads, publishing skills, or installing their runtime dependencies.
---

# Deploy skills

Keep actual skill folders in the user's `Documents/Deployed Skills`. Apps discover
directory symlinks to these stable copies, not disposable task clones. This skill is
the conversational interface for existing agents/extensions; no extension install
or background service is required. macOS/Python 3.9+ is the supported alpha; other
POSIX devices need local verification. Windows locking is not implemented.

Resolve this loaded skill's physical folder to locate `scripts/intake.py` and
`scripts/sync.py`. Invoke with `python3`, quoting paths. Both work from any CWD.
After initialization, root `intake.py` and `sync.py` are convenience links into the
copied manager. Exactly these two scripts own mutation; do not hand-edit receipts
or imitate their filesystem operations. Read [recovery.md](references/recovery.md)
for interruptions, backups, or legacy migration, and [targets.md](references/targets.md)
before choosing app paths or claiming discovery.

## Conversational workflow

Translate requests such as “deploy recon from this repo”, “what is deployed?”,
“refresh consult”, or “stop deploying to this app” into the operations below.
Resolve ambiguous repository/skill names before writing. Do not scan the whole
device or add dependencies merely because an imported skill mentions them.

1. Read/list the collection and selected source's `SKILL.md`. Explain intended
   copies, affected targets, conflicts and runtime prerequisites. Initialization
   copies this entire manager into an empty collection; it leaves targets disabled.
2. Preview the exact mutation (default; `--dry-run` always overrides `--apply`).
   A request to deploy/update/remove the named skills authorizes that previewed
   normal operation. Ask before expanding targets, replacing a foreign entry, or
   archiving a real legacy app directory. Never treat a preview as a deployment.
3. Apply the intake/target operation, then preview and apply sync when requested.
   Review every nonzero result: independent targets can succeed while conflicts
   remain. Do not force, steal a lock, delete a conflicting folder, or retry blindly.
4. Verify copied payload hashes, link read-through, catalog and history. Report
   filesystem deployment separately from each actual app/extension's discovery
   and runtime readiness. Refresh/restart discovery only as that app supports it.

## Commands

Put global options **before** the intake subcommand. Substitute local paths/names;
the examples below are templates, not a hardcoded source inventory.

```bash
python3 /path/to/deploy-skills/scripts/intake.py init
python3 /path/to/deploy-skills/scripts/intake.py --apply init
python3 "$HOME/Documents/Deployed Skills/intake.py" list
python3 "$HOME/Documents/Deployed Skills/intake.py" add /path/to/local-repo/skills/example
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply add /path/to/local-repo/skills/example
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply update example
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply update example --source /new/repo/skills/example
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply remove example
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply catalog
python3 "$HOME/Documents/Deployed Skills/intake.py" targets
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply targets --id chosen-app --path /verified/app/skills --consumer "Chosen app"
python3 "$HOME/Documents/Deployed Skills/intake.py" --apply targets --id chosen-app --disable
python3 "$HOME/Documents/Deployed Skills/sync.py" --status
python3 "$HOME/Documents/Deployed Skills/sync.py" --apply
```

Both scripts accept `--root /chosen/collection` for redirected Documents or another
explicit collection. Home/path values are computed locally, never copied from a
different user's configuration. Source intake is restricted to local Git repos;
dirty and unmerged working folders are allowed and recorded with commit and digest.
External, absolute, dangling and cyclic payload links are refused. Copies retain
internal relative links, file modes and bytes. Do not run copied `install.sh` files:
their legacy write policies can bypass managed ownership.

Actual valid immediate skill folders are the desired set. `catalog.md` is generated;
`targets.json` is editable configuration; `.deploy-skills.json` is provenance and
owned-link state; `changelog.md` is audit history. Manual valid additions can be
adopted by `catalog`; unexplained missing folders stop sync until explicit `remove`
acknowledges them. The manager itself is protected from removal to preserve recovery.
Disabling/removing a target does not erase its ownership receipts: sync withdraws
its still-matching links. Foreign folders and retargeted links remain untouched.

## Runtime dependencies are separate

Copying instructions does not bundle the source repo's tools, config or services.
Record requirements locally using `intake.py --apply prerequisite SKILL "TEXT"`;
list/status and catalog expose them without declaring them satisfied automatically.
Inspect the imported skill before invoking its tools from a neutral working folder.

For XYZ relay skills, use the existing locator and a command-scoped `XYZ_HARNESS`
pointing to a maintained full harness (or the caller's existing `.xyz`). Never point
it at a disposable clone or rewrite global shell startup files. Consult requires
its target repo context. Daily requires its Rebalance context and may contain private
paths; keep imported payloads, source receipts, targets, history and ZIPs out of the
public repo. Missing prerequisites block usability claims, not truthful inventory.
