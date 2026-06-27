---
title: Single-turn review ergonomics (untracked-relay warn + completed-non-approval exit code)
status: Active (2-WORKING)
created: 2026-06-27
updated: 2026-06-27
owner: noel
gh_issue: 32
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/32
goal: >
  Make a deliberate single review turn legible: warn when the relay file is invisible
  to an isolated worktree, give "reviewer completed a turn and requested changes" a
  distinct exit code from a genuine stall, and document the token-inspect verb.
doc_type: bugfix
non_goals:
  - Not changing the default isolation behavior (warn, don't flip the default)
  - Not the external-artifact delivery flow (that is GH-31)
related:
  - PROJECT/2-WORKING/GH-31-CROSS-REPO-ARTIFACT-REVIEW.md
  - PROJECT/1-INBOX/GH-22-AGY-WORKTREE-ISOLATION-DATA-LOSS.md
  - relay-automation/relay-drive.sh
roadmap_exempt: false
---

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 shipped: untracked-relay-file preflight warn in `relay-drive.sh` (`warn_if_relay_file_untracked`, isolation-gated, non-blocking) + regression test `test/relay-untracked-file-warn.sh` (5 assertions). `./validate.sh` **49/49**. | Phase 2 — distinct exit code for a completed non-approval ("Changes requested") turn, extending the Escalated→exit-4 carve-out. |

## Table of Contents

- [Status](#status)
- [Background](#background)
- [Phase 1 — Untracked-relay-file preflight warn](#phase-1--untracked-relay-file-preflight-warn)
- [Phase 2 — Distinct exit code for a completed non-approval turn](#phase-2--distinct-exit-code-for-a-completed-non-approval-turn)
- [Phase 3 — Document the token-inspect verb](#phase-3--document-the-token-inspect-verb)

## Background

Confirmed in code:

- `relay-drive.sh:90` → `: "${RELAY_WORKTREE_ISOLATION:=1}"` — driven turns run in a worktree at `ROOT@HEAD`. A brand-new relay thread is **untracked**, so it is absent from that worktree and the reviewer can't read/write it. (The reporter's "gitignored" diagnosis is wrong — it's untracked-not-ignored.)
- `relay-drive.sh:23,224-225` → exit `3` = no-progress (stall). A correct single review that requests changes (STATUS unchanged, token released) reads as exit 3.
- `relay-drive.sh:95-97,217-218` → the Escalated handback **already** has a carve-out to exit 4 ("not a stall"). Phase 2 extends this existing pattern.

## Phase 1 — Untracked-relay-file preflight warn

- [x] In the driver preflight, detect when `RELAY_WORKTREE_ISOLATION=1` and `RELAY_FILE` is **not** present in `HEAD` (uses `git rev-parse --show-prefix` + `git cat-file -e HEAD:<rel>` — symlink-safe on macOS `/var`→`/private/var`).
- [x] Emit a loud, multi-line WARN naming the exact remedy: commit the relay file first, or set `RELAY_WORKTREE_ISOLATION=0`.
- [x] Warn only — never block (verified: a true stall after the warn still exits 3).
- [x] Reuse the existing cross-repo warning style (loud `relay-drive: WARNING …` to stderr).

### QA checklist — Phase 1

- [ ] Isolation=1 + uncommitted relay file → warn fires with the remedy text.
- [ ] Isolation=1 + committed relay file → no warn.
- [ ] Isolation=0 → no warn regardless of tracked state.
- [ ] `./validate.sh` green; a regression test asserts the warn fires.

## Phase 2 — Distinct exit code for a completed non-approval turn

- [ ] Define the outcome: reviewer **claimed, took its turn, released the token** (or set STATUS to a non-terminal "Changes requested"), without Approve/Escalate.
- [ ] Give it a distinct exit code (or a `--review-once`/`--single-turn` mode that maps "completed + released" → 0) so it is not conflated with exit 3 (genuine stall = token actor never moved).
- [ ] Model it on the existing Escalated carve-out (`relay-drive.sh:95-97,217-218`) so the no-progress guard is reached only for a true stall.
- [ ] Document the new code in the `Exit:` header block and the relay-xyz skill.

### QA checklist — Phase 2

- [ ] Single review turn that requests changes + releases → new code (not 3).
- [ ] Genuine stall (token actor unchanged, no release) → still exit 3.
- [ ] Approve → still exit 0; Escalated → still exit 4.
- [ ] `./validate.sh` green with a test per outcome.

## Phase 3 — Document the token-inspect verb

- [ ] Confirm the correct `tick` verb to inspect a task token mid-drive (`tick show <task>` vs `tick status`).
- [ ] Add it to the relay-xyz skill command list and the README turn-protocol section.
- [ ] If `tick status <task>` should work but is silent, file/fix the gap; otherwise document the right verb.

### QA checklist — Phase 3

- [ ] The documented verb prints token state for a live task (verified by running it).
- [ ] Skill command list includes the verb.
- [ ] No hardcoded absolute paths in the docs.
</content>
