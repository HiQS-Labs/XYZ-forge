---
title: Explicitly document Claude CLI is NOT a default builder — Claude Code is orchestrator/reviewer only
status: Fixed and verified 2026-07-17 — both doc edits landed, PDDA clean.
created: 2026-07-17
updated: 2026-07-17
owner: noel
gh_issue: 221
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/221
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
non_goals:
  - No code/behavior change — `marathon.sh`/`marathon-drive.sh` already default `--builder` to `codex`
    (GH-212) and `--builder claude` already requires an explicit flag. This is purely closing a
    documentation gap that was letting sessions drift into treating Claude CLI as a peer builder
    option instead of an explicit opt-in.
related:
  - AGENTS.md — added the explicit "Builder/orchestrator role split (GH-221)" rail
  - skills/relay-xyz/SKILL.md — added the same role split at the top of "The two automated paths"
    (this file IS vendored — skills/ is in xyz-vendor.sh's VENDOR_DIRS — so a vendored repo's own
    sessions get the same guidance, not just the harness checkout)
  - GUIDING-PRINCIPLES.md#marathon-builder-default--plan-location-gh-212 — the pre-existing GH-212
    section, which frames --builder claude as a COST caveat only; this issue adds the missing ROLE
    framing alongside it
  - relay-automation/xyz-vendor.sh — VENDOR_DIRS confirmed to include skills/, so this fix reaches
    every vendored .xyz/ on next (re-)vendor; existing already-vendored copies need a re-vendor to
    pick up the new SKILL.md text (not done automatically by this doc)
goal: >
  Close a documentation gap that was observed causing real drift: some Claude Code sessions
  (terminal and VS Code) attempted to use the Claude CLI as a marathon/relay builder. The code-level
  default was already correct (GH-212: --builder defaults to codex), but the only existing doc
  caveat was cost-framed ("don't assume it's free"), not role-framed. Nothing stated the operator's
  actual intended architecture: Claude Code is the orchestrator/reviewer; Agy CLI and Codex CLI are
  the builders; Claude CLI is opt-in only, never a session's own default reach.
roadmap_exempt: false
---

# GH-221 · Builder/orchestrator role split — explicit documentation fix

## Status

| What was just completed | What's next |
|---|---|
| Confirmed the gap via direct read of `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ROUTER.md`, and the vendored `skills/relay-xyz/SKILL.md`: none stated the three-way role split, only a cost caveat (GH-212). Filed [#221](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/221). Added the explicit role statement to `AGENTS.md`'s "Repo-specific rails" and to `skills/relay-xyz/SKILL.md`'s "The two automated paths" section (the vendored copy, so it reaches every `.xyz/` install on next vendor). `pdda.sh run` clean. | None — docs-only fix, both edits landed. Optional follow-up (not done here): re-run `xyz-vendor.sh` against the 6 existing vendored copies on disk so they pick up the updated `SKILL.md` text immediately instead of on their next natural re-vendor. |

## Key concepts

- **The code-level default was already right.** GH-212 already made `codex` the default `--builder`
  in `marathon.sh`/`marathon-drive.sh`/`utils/py/marathon_drive.py`; `--builder claude` already
  requires an explicit flag. No script behavior changed here.
- **The existing doc caveat was cost-framed, not role-framed.** `GUIDING-PRINCIPLES.md`'s GH-212
  section says `--builder claude` "spawns a headless Claude Code CLI subprocess... use it only as an
  explicit, cost-acknowledged choice" — true, but a session reasoning "codex is just the default,
  claude CLI is a supported option" can still talk itself into using it, because nothing said this
  crosses an *architectural* line (orchestrator/reviewer vs. builder), not just a *cost* line.
- **The vendored skill doc had zero coverage at all.** `skills/relay-xyz/SKILL.md` — the doc a
  vendored (non-harness) repo's session actually reads before driving a relay/marathon — had no
  mention of "builder," "orchestrator," or a role split anywhere. Since `skills/` is one of
  `xyz-vendor.sh`'s `VENDOR_DIRS`, fixing it there (not just in the root-only `AGENTS.md`) is what
  makes the fix reach every vendored `.xyz/` install, not just this harness checkout.
- **Root-level `AGENTS.md`/`GUIDING-PRINCIPLES.md`/`ROUTER.md` are NOT vendored** —
  `xyz-vendor.sh`'s `VENDOR_DIRS="relay-automation bin src utils test skills"` never includes them.
  A vendored repo has no access to the root harness's own `AGENTS.md`, so any root-only doc fix is
  invisible to a vendored install by construction — the fix has to live inside `skills/` (or
  `relay-automation/`'s own `--help`/comments, which already carry the cost caveat) to actually
  propagate.

## Fix

- [x] `AGENTS.md` "Repo-specific rails" — added an explicit role-statement bullet: Claude Code =
      orchestrator/reviewer, never a default builder; Agy/Codex CLI = the builders; Claude CLI =
      opt-in only, user-chosen locally, never a session's own default reach.
- [x] `skills/relay-xyz/SKILL.md` — added the same role statement at the top of "The two automated
      paths" (the section that introduces Codex/agy as the headless turn-takers), so it's read
      before a session picks a builder. This file is vendored, so it reaches every `.xyz/` install.
- [x] `utils/pdda/pdda.sh run` — clean.

## Swarm Preflight Contract

Not applicable — this is a direct docs-only fix (≤2 files, no artifacts_new, no gate script), landed
inline rather than via a marathon lane.
