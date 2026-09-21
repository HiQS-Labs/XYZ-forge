---
title: relay-drive --review-once misgrades a real reviewer block as a zero-output stall (exit 3, not 5)
status: Proposed (1-INBOX — not yet active)
created: 2026-09-20
owner: agent-b
gh_issue: 720
source: https://github.com/HiQS-Labs/XYZ-forge/issues/720
doc_type: bugfix
complexity: 2
risk: 3
effort: 1
phases: 1
ratings_provisional: true
reported_from: Jev-unofficial-toolkit
harness_commit: 5e60cb01   # origin/development at capture; relay_drive.py identical at the report-time local HEAD b22e2641
non_goals:
  - Changing how marathon phases name their round blocks
  - Auto-handoff when RELAY_PEER is unset (separate WARN, separate issue if wanted)
related:
  - GH-397 (introduced the block-count oracle)
  - GH-648 (headless turn-timeout umbrella, Wave 2 lists #397)
goal: >
  A --review-once turn that appends a graded findings block and hands back without
  approving exits 5, regardless of whether the reviewer titled the block
  "### Round N · Reviewer · …" or "### Reviewer (<agent>)". Either the block-count
  regex accepts what the shipped scaffold/shim prompts actually elicit, or the
  scaffold/shim prompts state the exact heading the regex requires.
---

# GH-720 — relay-drive --review-once misgrades a real reviewer block as a zero-output stall

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
relay-drive.sh --review-once reported DRIVER_EXIT=3 (no-progress stall) on an agy turn that actually landed: review block appended, header flipped NEXT: Producer, commit 68413b89 in XYZ-forge; expected exit 5 (handed back without approving).

## Environment
- **Observed from:** `Jev-unofficial-toolkit` (centralized harness via `XYZ_HARNESS`; no vendored `.xyz/`)
- **Harness commit:** `b22e2641` (driver ran at `44d93f5c`; `utils/py/relay_drive.py` identical between the two)
- **Worker/CLI:** agy (`~/.local/bin/agy`), via `relay-automation/agy-turn.sh`
- **Runtime:** Python (default, `XYZ_PYTHON` unset) — message originates at `utils/py/relay_drive.py:1073`
- **Sandbox:** off (`dangerouslyDisableSandbox: true`, as relay-xyz requires for agy)

## Reproduction
1. Scaffold a thread with the shipped scaffolder, embedded artifact, agy as reviewer:
   `relay-automation/new-relay.sh --title "QA: …" --reviewer agy --producer claude-a --artifact-file <path> --embed --round-cap 2 --slug jev-pr8-agy-review --print > relay-system/2026-09-20/jev-pr8-agy-review.md`
   (then filled the Definition of Done with 8 numbered questions; committed the file.)
2. Seed the token: `tick log task.created RELAY-jev-pr8-agy-review --agent claude-a && tick claim … --paths <relay> && tick release … --to agy`
3. Drive one review turn:
   `AGY_AGENT=agy ALLOW_PATHS="" AGY_LOG=<scratch>/agy-turn-pr8.log relay-automation/relay-drive.sh --relay-file relay-system/2026-09-20/jev-pr8-agy-review.md --relay-task RELAY-jev-pr8-agy-review --agent-cmd relay-automation/agy-turn.sh --reviewer agy --review-once --round-cap 2`

**Expected:** exit `5` — "reviewer completed a turn and handed back without approving" (SKILL.md exit table). The turn appended a 37-line block with 8 graded findings, `VERDICT: FAIL`, `swept file: yes`, flipped `NEXT: Reviewer` → `NEXT: Producer`, and the shim committed it (`68413b89 relay(RELAY-jev-pr8-agy-review): agy turn (agy headless; no push)`).
**Observed:** exit `3`, with the GH-397 "NO review block" line, although the block is present at `relay-system/2026-09-20/jev-pr8-agy-review.md:713` under the heading `### Reviewer (agy)`.
**Frequency:** every time the heading lacks the `·` form — three observations across two reviewers, plus one control that matched (see Evidence).

```text
agy-turn: committed agy turn (file-scoped, no push)
agy-turn: WARN relay STATUS not terminal and no RELAY_PEER set — token RELAY-jev-pr8-agy-review left as-is (set RELAY_PEER for auto-handoff)
relay-drive: review-once — the relay file moved but the reviewer appended NO review block: a zero-output turn is not review coverage (GH-397) — genuine stall
DRIVER_EXIT=3
```

## Evidence (four turns, same harness code, same driver flags)

| Relay thread | Reviewer | Heading the reviewer wrote | Block substantive? | Driver exit |
|---|---|---|---|---|
| `relay-system/2026-09-20/jev-pr8-agy-review.md` | agy | `### Reviewer (agy)` | yes — 8 graded findings, VERDICT | **3** (misgraded as stall) |
| `relay-system/2026-09-20/jev-gh12-plan-codex.md` | codex | `### Reviewer — Round 1` | yes — 10 graded findings, VERDICT | **3** (misgraded as stall) |
| `relay-system/2026-09-20/jev-gh12-final-codex.md` r1 | codex | `### Reviewer · Round 1 (codex)` | yes — 8 graded findings, VERDICT | **5** (correct: handed back) |
| `relay-system/2026-09-20/jev-gh12-final-codex.md` r2 | codex | `### Reviewer · Round 2 (codex)` | yes — Approved | 4 (`close-mismatch`, unrelated: intake clone had unmerged paths) |

The only variable between the exit-3 rows and the exit-5 row is the heading's `·` separator, which is what the regex keys on. Reviewers are not told which form to use, so the outcome depends on the model's whim.

## Cause (by inspection, unconfirmed by a fix)
`utils/py/relay_drive.py:39` (verified at `origin/development` 5e60cb01):
```python
pat = re.compile(r"^### (Round .*· Reviewer ·|Reviewer · Round )", re.M)
```
Only `### Round N · Reviewer · …` or `### Reviewer · Round N …` count. That heading format is documented in `skills/relay/SKILL.md:77` but is **not** stated in the `▶ TAKE YOUR TURN` block that `new-relay.sh` embeds (it says only "Append ONE block at the very bottom"), and `agy-turn.sh` / `relay-turn-lib.sh`'s prompt does not mention it either. A headless reviewer following the scaffold's own instructions therefore has no reason to produce the heading the oracle demands. Same ROLE-first thread, second turn (`### Reviewer (agy) — r2`) would misgrade identically.

## Impact
A correct "changes requested" review is reported as a stall (red telemetry, exit 3). Anything keyed on the exit code — `/loop` pollers, marathon lanes, an operator script that retries on 3 — retries or escalates a turn that succeeded. Workaround: read the relay file, not the exit code.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (not just in the reporting repo)
- [ ] Decide: widen `review_blocks_added` to accept `### Reviewer …` / `### <role> (<agent>)` headings (and keep the "zero-output" intent by requiring a non-empty body after the heading), **or** make `new-relay.sh` + the turn prompt state the exact required heading — reuse whichever path is smaller (`/ponytail`)
- [ ] Add a regression case to the GH-397 test with the `### Reviewer (agy)` heading
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression test covers the failure path before the fix lands
- [ ] The fix composes with the existing harness rather than adding a parallel path
