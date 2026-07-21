---
title: Cross-repo live marathon status query (repo + lane + in-flight task), no per-repo MCP servers
status: Shipped on branch (2-WORKING) — Phase 1 (marathon-live.sh) + Phase 2 (rollup embed) landed
  d919e92 on marathon/plan-l-followup-2026-07-19 (Plan L lane). Pending PR into development, then 3-COMPLETED.
created: 2026-07-17
updated: 2026-07-17
owner: noel
gh_issue: 218
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218
doc_type: feature
complexity: 3
risk: 1
effort: 2
phases: 2
ratings_provisional: true
non_goals:
  - No MCP server per vendored repo — everything needed (tick's own STATE.md, git worktree list,
    the driver lock file) is already a local file/process read on the same machine; a server would
    add auth, a long-running process per repo, and protocol client code to solve what cat/git/ps
    already solve. Boundary: if these were opaque remote repos on other machines, this calculus
    would flip — it doesn't apply here since everything is a local path.
  - Not a new Obsidian writer — reuse rollup.sh's existing embed-verbatim mechanism (GH-192).
  - Not full realtime push/streaming — periodic/on-demand polling, not a live event subscription.
related:
  - utils/hq/marathon-scan.sh (GH-158) — existing doc-status scanner this composes with, not
    replaces
  - utils/hq/rollup.sh (GH-192) — existing Obsidian embed mechanism, reused as-is
  - utils/hq/hq-lib.sh — hq_known_repos()/hq_repo_resolve(), the existing repo enumeration reused
  - skills/hq/SKILL.md — added a "Live marathon status" section 2026-07-17 documenting the
    deterministic lookup path (registry -> tick project's STATE.md -> driver lock -> worktree
    list -> ps) ahead of marathon-live.sh existing, so any Claude Code session already knows
    where to look
  - PROJECT/1-INBOX/GH-180... (does not exist yet) — /ponytail itself is tracked as an
    undocumented-convention gap (GH-180); out of scope here, just the lens applied
goal: >
  Let the operator (or Claude, mid-session) ask "what marathons are running right now?" across
  every XYZ-vendored repo on this machine, and get back repo name + marathon/lane name + the
  specific task in flight + claimant — by composing existing local primitives (tick's own
  STATE.md, the HQ repo registry, git worktree list, rollup.sh's embed mechanism), not by standing
  up new per-repo infrastructure.
roadmap_exempt: false
---

# GH-218 · Cross-repo live marathon status query

## Status

| What was just completed | What's next |
|---|---|
| **Both phases shipped `d919e92`** on `marathon/plan-l-followup-2026-07-19` (Plan L lane). **Phase 1** — `utils/hq/marathon-live.sh`: read-only cross-repo live status composing `hq_known_repos`/`hq_repo_resolve` + each repo's own `tick project` STATE.md `## Claimed` parse + driver-lock/`marathon/*`-worktree liveness cross-check; emits repo\|lane\|task\|claimant\|live\|last-activity, no new per-repo MCP server. **Phase 2** — `utils/hq/rollup.sh` embeds it as `## Live Marathons (cross-repo, right now)` via a shared `demote_embed` helper. Tests: new `test/hq-marathon-live.sh` (live/claimed-not-driving/idle matrix, read-only asserted, registered in `validate.sh`, 7/7); `test/hq-rollup.sh` +2 cases (embedded live section + live-failure banner, 27/27). | Open a PR into `development`. **Follow-up (not blocking):** update the `skills/hq/SKILL.md` "Live marathon status" section to point at `marathon-live.sh` instead of the manual walk. On merge (`Closes #218`), move to `3-COMPLETED`. |

## Key concepts

- **Repo discovery is already solved.** `hq_known_repos()` (`utils/hq/hq-lib.sh`) aggregates the
  XYZ install registry (`~/.config/xyz/registry.tsv`), rebalance's project registry, and git-pulse's
  PDDA registry — the same enumeration `marathon-scan.sh` already uses. No new discovery code.
- **Live state is already solved, per-repo.** `tick project` (or `bin/tick project` under a
  vendored `.xyz/bin/tick`) regenerates `.tick/STATE.md` from `.tick/events/` — deterministic,
  local, already exists. Its `## Claimed` section names the exact task id (e.g.
  `MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN`) and claimant agent (e.g. `agy`) currently holding
  work. This is the live signal the doc-status scanner (`marathon-scan.sh`) can't see.
- **Corroboration, not replacement, needed for "is it ACTUALLY running right now" vs. "claimed but
  stalled."** Cross-check: (a) does the repo's driver lock file exist
  (`.git/relay-driver.lock` or a vendored `.xyz/.relay-driver.lock`)? (b) does
  `git worktree list` show a `marathon/*`-branch worktree with activity in the last N minutes
  (commit timestamp or dirty working tree)? Both are cheap, already-shaped checks (the
  `.git/relay-driver.lock` path and the GH-203 `lsof`-based staleness pattern already exist in this
  codebase for a similar purpose).
- **Obsidian output is already solved.** `rollup.sh` embeds `marathon-scan.sh`'s report verbatim
  as a demoted-heading section (GH-192) — the same mechanism applies to a new
  `marathon-live.sh` report with a ~10-20 line diff, not a new writer.

## Phase 1 — `utils/hq/marathon-live.sh`

### Checklist
- [ ] New script: source `hq-lib.sh`, call `hq_known_repos` + `hq_repo_resolve` (same pattern as
      `marathon-scan.sh`'s existing repo loop) to get every known repo's absolute path
- [ ] For each resolved repo, locate its own tick binary (native `bin/tick` or vendored
      `.xyz/bin/tick` — reuse `find-harness.sh`'s resolution logic/pattern, don't reinvent)
- [ ] Run `tick project` in that repo (regenerates `.tick/STATE.md`), parse the `## Claimed`
      section: task id + claimant
- [ ] Cross-check liveness: driver lock file present? a `marathon/*` worktree with activity in the
      last N minutes (configurable, default e.g. 30)?
- [ ] Emit one compact Markdown table: repo | marathon/lane (parsed from the task id) | task |
      claimant | live (yes/no) | last activity timestamp
- [ ] Read-only — never writes into any target repo, matching `marathon-scan.sh`'s safety posture
- [ ] `--out FILE` flag (default under the hub repo's `PROJECT/2-WORKING/`), mirroring
      `marathon-scan.sh`'s existing flag shape

### QA checklist — Phase 1
- [ ] No new repo-discovery mechanism — reuses `hq_known_repos`/`hq_repo_resolve` verbatim
- [ ] No new per-repo state mechanism — reuses `tick project`'s existing STATE.md, doesn't
      reimplement event-log parsing
- [ ] Test fixture(s) prove: a repo with a live claim + held lock reports "live"; a repo with a
      claim but no lock/no recent worktree activity reports "claimed, not currently driving"; a
      repo with nothing claimed reports idle
- [ ] `bash validate.sh` green (new test registered)

## Phase 2 — `rollup.sh` Obsidian hook

### Checklist
- [ ] Extend `utils/hq/rollup.sh` to also shell out to `marathon-live.sh` and embed its report
      verbatim as a new `## Live Marathons (cross-repo, right now)` section, heading-demoted the
      same way the existing `marathon-scan.sh` embed already is (GH-192)
- [ ] No new Obsidian-writing code — this is purely a second call into the existing embed helper
- [ ] `test/hq-rollup.sh` extended with a case proving the new section appears

### QA checklist — Phase 2
- [ ] Reuses the exact embed mechanism GH-192 already built — no parallel Obsidian-writing path
- [ ] `bash validate.sh` green, no regression to existing `hq-rollup.sh` cases

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "utils/hq/marathon-live.sh" },
    { "type": "path_absent", "path": "test/hq-marathon-live.sh" },
    { "type": "grep_absent", "path": "utils/hq/rollup.sh", "pattern": "marathon-live" }
  ],
  "artifacts": [
    "utils/hq/marathon-live.sh",
    "test/hq-marathon-live.sh",
    "utils/hq/rollup.sh",
    "test/hq-rollup.sh"
  ],
  "artifacts_new": [ "utils/hq/marathon-live.sh", "test/hq-marathon-live.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 1 and Phase 2 checklists in this doc" },
  "lanes": { "agy_safe": [ "utils/hq/marathon-live.sh", "test/hq-marathon-live.sh", "utils/hq/rollup.sh", "test/hq-rollup.sh" ], "orchestrator_only": [] }
}
```
