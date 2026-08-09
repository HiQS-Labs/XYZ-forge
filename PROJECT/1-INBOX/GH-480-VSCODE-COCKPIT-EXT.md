---
title: "GH-480 — VS Code cockpit extension (Marathons / Releases / Worktrees, read-only alpha)"
status: 1-INBOX
created: 2026-08-09
owner: noel
doc_type: project
goal: >
  Pointer doc for GH-480: a standalone VS Code extension with a read-only Activity Bar view
  stacking Marathons, Releases, and Git Worktrees as collapsible card lists with copy-to-clipboard,
  so their names can be pasted into a chat session. Alpha is read-only — no preflight/dry-run/
  execute wiring yet.
---

Issue: [#480](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/480)

## Why this shape

Traced through two prior candidates first (see conversation history, not re-litigated here):

- **Traycer's own Activity Bar view** — checked the installed extension's `package.json`:
  `contributes.views` declares exactly one `type: "webview"` entry it fully owns. No
  `TreeDataProvider` contribution point, no documented plugin API. Not composable.
- **A Swift Mac app** — parallel-track idea from an earlier prompt; a worktree
  (`spike/xyz-cockpit-mac-app`) exists for it but is unstarted (bare checkout, no scaffold). Not
  pursued in this doc.

Landed on: a small standalone VS Code extension, own Activity Bar icon, one `WebviewViewProvider`
so the UI can be genuinely card-based (title/details/copy button) rather than constrained to
native `TreeItem` rendering.

## Data sources (alpha, read-only)

- **Marathons** — `PROJECT/2-WORKING/MARATHON-PLAN-*.md` frontmatter (title/status/created/updated).
- **Releases** — `RELEASES.md` blocks (`Release:`/`Codename:`/`Status:`/`Target Date:`/`Description:`).
  Per GH-381, this file is optional/sparse by design — an empty section is a valid, expected state,
  not a bug.
- **Git Worktrees** — `git worktree list --porcelain` in the open workspace folder(s).

No daemon, no auth, no network calls, nothing executed.

## Anti-goals (alpha)

- Not a Traycer/T3 Code replacement or client.
- No preflight/dry-run/execute action wiring — that decision (who/how/where the orchestrator is)
  is explicitly deferred to a follow-on issue once the alpha's data model is proven out.
- Not multi-repo aggregation beyond the folders already open in the workspace.

## DoD

- Extension activates in the Extension Development Host and renders real data from this repo.
- Copy button round-trips to the OS clipboard.
- Sections independently collapse/expand (caret) without losing state on view hide/show.
- `README.md` in the extension package documents exactly what it reads and that it executes nothing.
