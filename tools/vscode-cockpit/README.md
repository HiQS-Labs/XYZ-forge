# XYZ Cockpit (alpha)

A read-only VS Code Activity Bar view of this workspace's Marathons, Releases, and Git Worktrees.
Each entry is a card with a copy-to-clipboard button, so a name can be pasted straight into a chat
session. See [GH-480](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/480).

## What it reads

- **Marathons** — YAML frontmatter (`title`, `status`, `updated`/`created`, `owner`) from every
  `PROJECT/2-WORKING/MARATHON-PLAN-*.md` file in each open workspace folder. Copies the filename
  stem, e.g. `MARATHON-PLAN-2026-08-06`.
- **Releases** — blocks in `RELEASES.md` (`Release:` / `Codename:` / `Status:` / `Target Date:` /
  `Milestone:` / `Description:`). This file is optional and often sparse by design (GH-381) — an
  empty section here is expected, not a bug. Copies the codename, or the version if there is none.
- **Git Worktrees** — `git worktree list --porcelain` run in each open workspace folder. Copies the
  worktree's filesystem path.

## What it does NOT do

Nothing is executed. No preflight, dry run, or marathon is triggered from this view — it only reads
files and runs `git worktree list`. Wiring up actions is deliberately out of scope for this alpha;
see the anti-goals in the GH-480 pointer doc
(`PROJECT/1-INBOX/GH-480-VSCODE-COCKPIT-EXT.md` at the time this was written).

## Develop

```bash
cd tools/vscode-cockpit
npm install
npm run compile   # or: npm run watch
```

Then press F5 (or Run → "Run XYZ Cockpit Extension") to launch an Extension Development Host with
this extension loaded. Open this repo (or any workspace with the same file layout) in that window
and click the XYZ Cockpit icon in the Activity Bar.
