---
title: "relay-to-issue — post-relay transcript → checklist GitHub issue"
status: Active
created: 2026-06-22
updated: 2026-06-22
owner: Noel (operator) · Claude (builder)
doc_type: tooling
goal: >
  Ship a repeatable, invokable Claude Code skill that reads a finished /relay
  producer↔reviewer thread, summarizes the conclusion (agreements + unresolved
  disagreements), and files ONE checklist-style GitHub issue in the repo the
  relay was actually about — so review follow-ups become spin-off-ready tasks
  without hand-copying. Deterministic plumbing in a shipped script; judgment in
  the skill.
---

# relay-to-issue — post-relay transcript → checklist GitHub issue

## Status

| What was just completed | What's next |
|---|---|
| **Skill shipped** — `skills/relay-to-issue/` (`SKILL.md` + `relay-to-issue.sh` + `install.sh`). `resolve` smoke-tested green against the live `dueling-claudes` thread (thread auto-detect, header parse, target-repo resolution → `current-repo`, dedup, gh-auth probe all working; `bash -n` clean). | Operator to (a) `bash skills/relay-to-issue/install.sh` to register `/relay-to-issue`, then (b) run it un-sandboxed against a real closed relay to confirm an actual `gh issue create` end-to-end (sandbox blocks the gh keychain, so live posting wasn't exercised here). |

## Summary

The relay harness produces a markdown transcript (`relay-system/<date>/<slug>.md`) but
nothing turns its outcome into trackable work — the operator re-reads it and hand-files
issues. This skill closes that gap: one invocation distills a closed relay into a single
GitHub issue whose body is a markdown checklist of the actionable findings, posted to the
**subject** repo (which is often not the harness repo — see [GH-11](GH-11-CROSS-REPO-TARGETING.md)).

## Design

**Work split.** `relay-to-issue.sh` owns the deterministic, repeatable plumbing; the LLM
owns the judgment (reading the transcript, writing the title + checklist body).

**Two subcommands.**
- `resolve` — prints machine-readable facts (thread path, slug/date, title/status/round,
  target repo + source, dedup status, gh-auth). The skill gates on this first.
- `file` — creates the issue from a title + body file, then appends a provenance+dedup
  stamp to the thread; optional `--inbox` drops a `PROJECT/1-INBOX/GH-<n>` pointer when the
  issue lands in this repo.

**Operator-chosen behavior** (clarified up front):
- **One issue + checklist** (each box spin-off-ready), not one issue per item.
- **Target = the repo the relay was about** — inferred from cited absolute paths; falls back
  to the current repo for same-repo relays; **ambiguous (multiple repos cited) → fail loud**,
  never auto-post to a guess. An optional `TARGET-REPO: owner/name` thread header wins.
- **Auto-post** via `gh` (no confirm step), guarded by a dedup stamp so re-runs don't double-file.
- **Input = the relay thread file**, newest auto-detected or `--thread <path|slug>`.

**Safety rails baked in:** dedup stamp (re-run safe), provenance link (issue ↔ thread ↔ commit),
empty-relay guard (clean Approve files nothing), disagreements kept as `⚠️ DECIDE` boxes,
`gh` preflight before any write.

## Verification

- `bash -n` clean on both scripts.
- `resolve` (no-arg + `--thread <slug>`) green against `relay-system/2026-06-22/dueling-claudes.md`:
  correct thread, parsed header, `TARGET_REPO` resolved, `ALREADY_FILED: NONE`.
- Live `gh issue create` deferred to an un-sandboxed run (sandbox blocks the gh keychain;
  `resolve` reported `GH_AUTH: missing` here purely for that reason and degraded gracefully).

## Relationship to existing work

- **Downstream of** `/relay` (portable scaffold/protocol) and `/relay-xyz` (this repo's harness
  driver). This is the **post-relay** step; it does not scaffold or run a relay.
- **Mirrors** the existing GitHub-issue intake convention ([ROUTER.md](../../ROUTER.md) → "GitHub
  issue intake") in reverse: that flow is issue→`1-INBOX`; `--inbox` here is relay→issue→`1-INBOX`.
