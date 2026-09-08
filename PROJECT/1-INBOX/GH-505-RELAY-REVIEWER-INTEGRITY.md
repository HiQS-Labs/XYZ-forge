---
title: "GH-505: Builder can approve and close its own relay; no merge path checks for a reviewer"
status: Parked
created: 2026-09-08
updated: 2026-09-08
owner: unassigned
goal: make "STATUS: Approved" mean a reviewer approved — refuse a terminal status written by a non-reviewer turn, stop jog overriding the driver's escalation, and require an approving review from a different actor before any merge
gh_issue: 505
source: https://github.com/HiQS-Labs/XYZ-forge/issues/505
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
effort: 5
complexity: 3
risk: 3
---

# GH-505 — Relay reviewer integrity: a builder can approve its own work

## Status

| What was just completed | What's next |
|---|---|
| Issue #505 filed with evidence; all three findings independently verified against `origin/development` at `0b37c36f` and confirmed reproducible ([verification comment](https://github.com/HiQS-Labs/XYZ-forge/issues/505#issuecomment-5590351925)) | Park + rate, then plan the four fixes in dependency order and QA the plan with Codex before any implementation |

## Why

The relay file is the only artifact in this harness that says a second model looked
at a change. Three independent layers trust the word `Approved` in that file, and
none of them checks who wrote it. The builder — the agent whose own work is under
review — can write it, and the shared per-turn prompt tells it to.

The consequence is not theoretical. The companion report
([LTVera-Pandas#440](https://github.com/BinoidCBD/LTVera-Pandas/issues/440)) traces one
wave of harness-produced commits carrying 19 new defects, one Critical, through this
path. PRs merged in under two minutes verified 57% of their items; the same pipeline's
PRs that a person read first verified 86%.

This repo already knows the shape of the bug. `utils/py/marathon_drive.py:2647-2651`
calls the builder writing `STATUS: Approved` "a complete forgery of the terminal
state" — and that hardening closed the *token* half of the forgery while leaving the
STATUS half open.

## Key concepts

- **Terminal STATUS** — `Approved` or `Closed` in the relay file header. Ends the relay.
- **Role derivation** — `rtl_is_reviewer_turn` (`relay-automation/relay-turn-lib.sh:63`)
  already derives Producer vs Reviewer from the token and rendered directive,
  specifically so "no agent can get it wrong" (GH-397). It is used to fence the
  reviewer's file edits. It is not consulted for the terminal decision.
- **The gap** — capability present, never applied at the one place it decides whether
  a review happened.

## Verified findings (at `0b37c36f`)

| # | Finding | Evidence | Sev |
|---|---|---|---|
| 1 | `terminal_status()` tests the STATUS word only, never the actor role | `relay_drive.py:355-356`; both terminal paths `:571-579` and `:830-833`. At `:571` `actor` is in scope one line above the test and used only to detect a live token. `:830` prints "reviewer approved/closed" without checking for a reviewer. `RELAY_AGENT` exported at `:619`, never read for this decision. | High |
| 2 | Shared per-turn prompt instructs every role to set Approved | `relay-turn-lib.sh:1011` — `(or done + set STATUS: Approved when approving)` sits in the shared `printf`, with `$role_note` interpolated *after* it. Builders receive it. | High |
| 3 | Jog overrides the driver's own escalation on that word | `jog_run.py:1374-1387` converts a non-zero driver exit to `return 0` when the header reads `done`/`approved`. | High |
| 4 | No merge path checks for a review | `express.py:599`, `marathon-closeout.sh:292`, `jog_run.py:1432`, `skills/merge-cleanup/scripts/merge_cleanup.py` — zero matches for `reviewDecision`/`APPROVED`/`reviews` in all four. No hook matches `gh pr merge` or `gh issue close`. `gh api .../branches/development/protection` returns `Branch not protected`. | High |

`marathon-closeout.sh` is the most careful of the four and still misses it: it gates on
CI green (`:276`) and mergeability (`:283-288`), both about conflicts and checks,
neither about a reviewer.

**Correction to the issue as filed:** it cites `utils/py/merge_cleanup.py:55`. That
path does not exist at `0b37c36f`; the script is at
`skills/merge-cleanup/scripts/merge_cleanup.py`. The finding stands; only the path is wrong.

**Not independently verified:** the LTVera-Pandas transcript census (137 relay files,
78 terminal, 9 producer-written) and the 57%/86% verified-rate split live in another
repo and were not re-checked. They motivate severity, not the mechanism.

## Fix order (dependency-ordered)

1. **Refuse a terminal STATUS from a non-reviewer turn** in `relay_drive.py`, at both
   terminal paths. Expose the existing shell role derivation to Python rather than
   trusting `NEXT:` prose.
2. **Remove the Approved clause from the shared prompt** (`relay-turn-lib.sh:1011`),
   adding it only to the reviewer `role_note` at `:994-1000`; update the
   `relay-drive.sh:32` header comment to match.
3. **Delete the jog override** (`jog_run.py:1374-1387`).
4. **Require an approving review from a different actor before any `gh pr merge`**,
   enforced by a PreToolUse hook and by GitHub branch protection on `development`.

Fixing 1 alone is insufficient: 3 can still override a correct escalation.

Each fix needs a fixture test that goes **red without it** — for 1, a builder turn that
appends a block, writes `STATUS: Approved` and runs `tick done` must exit non-zero,
with a reviewer-written control that still exits 0. Tests belong beside
`test/gh376-relay-drive-lock-parity.sh`.

## Rating rationale — 2026-09-08

`rated 85/85/50/55` (pri/sev/appeal/effort; effort scores cheapness).

- **Severity 85.** Unreviewed code merges while the transcript records that it was
  reviewed. Every downstream reader — jog, closeout, an operator skimming `STATUS:` —
  is misled at exactly the point where checking stops. High band per policy: the
  consequence is wrong work reaching a deliverable, and recovery means re-auditing
  merged history. Held below 90 because it degrades review quality rather than
  destroying data, and the landing boundary still runs tests.
- **Priority 85.** Severity-led. Raised by recurrence, and by this being the mechanism
  behind a companion Critical finding in a downstream repo. Not 90+ because no client
  deliverable is currently blocked.
- **Appeal 50.** Neutral — the operator supplied no desirability preference.
- **Effort 55.** Fixes are localized and the role-derivation helper already exists, but
  the work spans four files plus new fixture tests, a PreToolUse hook, and a GitHub
  branch-protection change. Not a quick win; not an architectural rewrite.

**Recurrence evidence.** Window 2026-08-25 → 2026-09-08 versus the preceding 14 days.
Same class = relay review integrity, meaning the transcript claims a review that did
not happen as recorded:

- **#482** (2026-09-07, open) — `relay-drive.sh --artifact-file` silently seeds nothing;
  the reviewer completes a turn without ever seeing the artifact.
- **#505** (2026-09-08, this issue) — the review can be closed by the party under review.
- Prior fix on the same seam: the `marathon_drive.py:2647-2651` hardening closed the
  token half of this exact forgery, leaving the STATUS half.

Two distinct incidents in the current window plus one prior partial fix on the same
seam. The preceding window was not systematically counted — treat its trend as
**unknown**, not zero. Coverage limit: this counts issues in this repo only.
