---
title: "GH-505: Builder can approve and close its own relay; no merge path checks for a reviewer"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: make "STATUS: Approved" mean a reviewer approved — refuse a terminal status written by a non-reviewer turn, stop jog overriding the driver's escalation, and require an approving review from a different actor before any merge
gh_issue: 505
source: https://github.com/HiQS-Labs/XYZ-forge/issues/505
branch: fix/gh505-relay-reviewer-integrity
base_sha: 0b37c36f
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/482
  - https://github.com/BinoidCBD/LTVera-Pandas/issues/440
context_tags: [relay, review-integrity, governance, merge-gate]
non_goals:
  - Adding a new review subsystem, scoring model, or reviewer-quality metric
  - Changing the relay turn protocol, token model, or round-cap semantics
  - Retroactively auditing or reverting already-merged PRs
  - Fixing the separate no-test-gate-in-standalone-relay gap carried forward from the Sep 4th check
  - Introducing a second role-derivation implementation; Phase 1 ports the existing one
effort: 5
complexity: 3
risk: 3
phases: 4
---

# GH-505 — Relay reviewer integrity

## Status

| What was just completed | What's next |
|---|---|
| Findings verified at `0b37c36f`; intake parked and rated `85/85/50/55`; task clone and branch provisioned; recon complete — the directive-coverage gap is the crux | Codex plan QA on this document, then Phase 1 |

## Table of contents

- [Phase 1 — refuse a terminal STATUS from a non-reviewer turn](#phase-1--refuse-a-terminal-status-from-a-non-reviewer-turn)
- [Phase 2 — take the Approved clause out of the shared prompt](#phase-2--take-the-approved-clause-out-of-the-shared-prompt)
- [Phase 3 — delete the jog override and seed the role directive](#phase-3--delete-the-jog-override-and-seed-the-role-directive)
- [Phase 4 — require a review before any merge](#phase-4--require-a-review-before-any-merge)

## Observed problem

Three layers trust the word `Approved` in a relay file. None checks who wrote it, and
the shared per-turn prompt tells the builder to write it. Verified at `0b37c36f`;
full evidence in the [intake capture](../1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md)
and the [verification comment](https://github.com/HiQS-Labs/XYZ-forge/issues/505#issuecomment-5590351925).

## Recon findings — the crux

`rtl_is_reviewer_turn` (`relay-automation/relay-turn-lib.sh:63`) already answers "is
this turn the reviewer's", in **two tiers**:

1. **Authoritative.** If the relay file carries `<!-- marathon-drive: … builder=X
   reviewer=Y … -->` and `RELAY_AGENT` is set, the role is *computed*. An ambiguous
   pair (`builder == reviewer`, a self-review lane) deliberately falls through rather
   than guess.
2. **Fallback.** Otherwise it matches the first `NEXT:` header line against
   `Reviewer` — prose the acting model can write itself. GH-397's own comment says
   hanging a containment boundary on that honor system "fails OPEN".

**Coverage measured in this clone: 68 of 201 relay files carry the directive; 133 do
not.** Only `marathon-drive.sh:1039` renders it. So a naive port of this helper would
leave two thirds of relays on the honor system — the builder writes `NEXT: Reviewer`,
then writes `STATUS: Approved`, and the new check passes.

**But the identity exists where it is missing.** `jog_run.py` already takes and
validates a reviewer (`:190-191`, against `_MARATHON_REVIEWER_PREFIXES` at `:175`) and
already knows its builder — then seeds a relay file (`:1320-1335`) containing
`NEXT: {builder}` and `STATUS: Open` and no directive. Phase 3 renders the directive
jog already has the data for, which moves jog-seeded relays onto the authoritative
tier instead of widening the fallback.

This is why the fix order below is a dependency chain, not a preference.

## Smallest affected surface

| File | Change |
|---|---|
| `utils/py/relay_drive.py` | Port role derivation; gate both terminal paths on it |
| `relay-automation/relay-turn-lib.sh` | Move the Approved clause into the reviewer `role_note` |
| `relay-automation/relay-drive.sh` | Update the stale header comment at `:32` |
| `utils/py/jog_run.py` | Delete the override; render the role directive when seeding |
| `githooks/` + repo settings | Merge review gate; branch protection on `development` |
| `test/` | Four new fixtures, each with a red control |

No new module, no second role implementation, no parallel write path.

## Implementation

### Phase 1 — refuse a terminal STATUS from a non-reviewer turn

1. Add a `is_reviewer_turn(relay_file, agent)` helper to `relay_drive.py` mirroring
   `rtl_is_reviewer_turn`'s two tiers exactly, including the `builder == reviewer`
   fall-through. Return a tristate: `True`, `False`, or `UNKNOWN` (no directive) —
   the shell version collapses the last two, and that collapse is what fails open.
2. At the post-turn block (`:826-846`), when `terminal_status(ns)` holds and the
   derivation returns `False`, restore the pre-turn STATUS (`s` is in scope), print
   `relay-drive: STATUS <ns> written by non-reviewer <actor> — ignored, handing to
   reviewer`, point `NEXT:` at the reviewer, and continue the loop.
3. At the loop top (`:571-579`), apply the same test so a file that *starts* terminal
   without a reviewer block escalates rather than exits 0.
4. `UNKNOWN` escalates with `exit 4`, reason `terminal-role-unprovable`, rather than
   silently accepting. **This is the deliberate fail-closed choice** and the main
   question for plan QA — it is a behavior change for the 133 directive-less relays.
   Phase 3 removes the largest slice of those; any remainder is a hand-run `/relay`
   thread, where escalating to a human is the correct outcome anyway.

**Acceptance.** `test/gh505-relay-terminal-role.sh`:
- builder turn appends a block, writes `STATUS: Approved`, runs `tick done` → driver exits non-zero. **Red control: fails on `0b37c36f`.**
- same words from the reviewer turn → exits 0.
- directive-less relay with a terminal STATUS → exit 4, reason `terminal-role-unprovable`.
- `builder == reviewer` self-review lane → falls through, does not crash.

Sits beside `test/gh376-relay-drive-lock-parity.sh`.

### Phase 2 — take the Approved clause out of the shared prompt

1. `relay-turn-lib.sh:1011`: remove `(or done + set STATUS: Approved when approving)`
   from the shared `printf`; the shared text becomes `(3) when finished, %s.`
2. Add the clause to the reviewer `role_note` only (`:994-1000`).
3. Update the stale `relay-drive.sh:32` header comment to match.

**Acceptance.** `test/gh505-prompt-role-split.sh`: render the builder prompt, assert
it does **not** contain `STATUS: Approved`; render the reviewer prompt, assert it
does. Red control: both contain it on `0b37c36f`.

### Phase 3 — delete the jog override and seed the role directive

1. Delete `jog_run.py:1374-1387` entirely; `return proc.returncode` unconditionally.
   The comment's premise — "a terminal STATUS on the relay file IS success" — is
   exactly the assumption Phase 1 invalidates.
2. In the seeding block (`:1320-1335`), render
   `<!-- marathon-drive: task={task_name} builder={builder} reviewer={reviewer} round-cap={cap} -->`
   using the identities jog already holds, so jog relays reach Phase 1's authoritative tier.
3. Seed `NEXT:` unchanged; the directive, not the pointer, carries authority.

**Acceptance.** `test/gh505-jog-no-override.sh`: a jog drive whose relay ends
`STATUS: Approved` written by the builder returns non-zero. Red control: returns 0 on
`0b37c36f`. Plus: a jog-seeded relay file contains a directive whose `reviewer` matches
the `--reviewer` argument.

**Risk.** Deleting the override may surface genuinely-stuck single-phase drives that
previously self-cleared. That is the defect, not a regression — but it changes jog's
observable exit behavior, so it needs calling out in the PR.

### Phase 4 — require a review before any merge

1. A PreToolUse hook matching `gh pr merge` that refuses unless
   `gh pr view --json reviewDecision` is `APPROVED` **and** the approving actor differs
   from the PR author. Extend the existing `githooks/`+`.claude/hooks` pattern; do not
   add a new hook framework.
2. Enable branch protection on `development` requiring one approving review.
3. Leave the four call sites untouched — the hook is the single choke point, which is
   DRY and cannot be bypassed by adding a fifth call site later.

**Acceptance.** `test/gh505-merge-review-gate.sh`: a `gh pr merge` invocation against a
PR with `reviewDecision: null` is refused; one with an approving review from a
different actor proceeds. Red control: both proceed on `0b37c36f`.

**Open question for QA.** Branch protection is a repo-settings change, not a code
change, so it cannot be covered by a test in this PR and is not reversible by revert.
Recommend landing it as a separate, explicitly-approved operator action after the code
merges, and saying so in the PR rather than doing it silently.

## Dependencies and ordering

Phase 1 → 3 is a hard dependency: with the override intact, Phase 1's escalation is
discarded by jog. Phase 3's directive seeding depends on Phase 1's derivation existing.
Phase 2 is independent and can land in any order. Phase 4 is independent of 1–3 and is
the only defence for a merge that never went through a relay at all.

## Risks and rollback

| Risk | Mitigation |
|---|---|
| Fail-closed escalation on 133 directive-less relays | Phase 3 converts the jog slice; remainder are hand-run threads where human escalation is correct. Quantified above, not assumed. |
| A stuck jog drive that previously self-cleared now returns non-zero | Intended. Called out in the PR. |
| Branch protection locks out an automated lane mid-flight | Landed separately as an operator action, after code. |

Rollback for Phases 1–3 is `git revert` of the branch. Phase 4's branch protection is
a settings toggle, reversible in the GitHub UI but not by revert — hence the split.

## Verification

Full `./validate.sh` gate in a **separate disposable clone**, never this task clone.
Four new fixtures must each be demonstrated red on `0b37c36f` before their fix.
