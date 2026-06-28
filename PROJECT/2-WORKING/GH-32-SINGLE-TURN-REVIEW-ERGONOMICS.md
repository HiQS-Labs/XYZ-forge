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
| **All 3 phases shipped.** Phase 3: confirmed the inspect verb is `tick info <task>` (`tick status` → `unknown verb`); documented `tick info` + `--review-once`/exit-5 in the relay-xyz SKILL and `relay-automation/README.md`. `./validate.sh` **50/50**. | Close #32; move on to GH-31 (Phase 1 = design the `--artifact-file` copy-into-worktree contract). Doc can move to `3-COMPLETED` once #32 is closed. |

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

- [x] In the driver preflight, detect when `RELAY_WORKTREE_ISOLATION=1` and `RELAY_FILE` is **not** present in `HEAD` (uses `git rev-parse --show-prefix` + `git cat-file -e HEAD:<rel>` — symlink-safe on macOS where `/var` is itself a symlink).
- [x] Emit a loud, multi-line WARN naming the exact remedy: commit the relay file first, or set `RELAY_WORKTREE_ISOLATION=0`.
- [x] Warn only — never block (verified: a true stall after the warn still exits 3).
- [x] Reuse the existing cross-repo warning style (loud `relay-drive: WARNING …` to stderr).

### QA checklist — Phase 1

- [ ] Isolation=1 + uncommitted relay file → warn fires with the remedy text.
- [ ] Isolation=1 + committed relay file → no warn.
- [ ] Isolation=0 → no warn regardless of tracked state.
- [ ] `./validate.sh` green; a regression test asserts the warn fires.

## Phase 2 — Distinct exit code for a completed non-approval turn

- [x] Define the outcome: reviewer **claimed, took its turn, released the token** (or set STATUS to a non-terminal "Changes requested"), without Approve/Escalate.
- [x] Give it a distinct exit code: added `--review-once` mode + **exit 5** for a completed non-approval handback (token moved OR STATUS changed), keeping exit 3 for a genuine stall (token state unchanged).
- [x] Model it on the existing Escalated carve-out: the review oracle sits just after the Escalated check, before the no-progress guard, so Escalated still wins (exit 4).
- [x] Documented the new code in the `Exit:` header block and `--help`. (relay-xyz skill doc update tracked with Phase 3.)

### QA checklist — Phase 2

- [ ] Single review turn that requests changes + releases → new code (not 3).
- [ ] Genuine stall (token actor unchanged, no release) → still exit 3.
- [ ] Approve → still exit 0; Escalated → still exit 4.
- [ ] `./validate.sh` green with a test per outcome.

## Phase 3 — Document the token-inspect verb

- [x] Confirmed the correct verb is **`tick info <task>`** (prints status/claimer/handoff-to; the same call the driver uses). `tick status` errors with `unknown verb: status` — the reporter just guessed the wrong verb; no CLI gap to fix.
- [x] Added it to the relay-xyz SKILL ("Inspecting token state, and a one-shot review" subsection) and the `relay-automation/README.md` exit-code/turn sections.
- [x] No silent-verb gap — documented the right verb rather than adding an alias.

### QA checklist — Phase 3

- [ ] The documented verb prints token state for a live task (verified by running it).
- [ ] Skill command list includes the verb.
- [ ] No hardcoded absolute paths in the docs.
</content>
