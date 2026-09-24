---
title: relay-drive --review-once misgrades a real reviewer block as a zero-output stall (exit 3, not 5)
status: Complete
created: 2026-09-20
updated: 2026-09-24
owner: agent-b
gh_issue: 720
source: https://github.com/HiQS-Labs/XYZ-forge/issues/720
doc_type: bugfix
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: false   # rated 2026-09-22 at marathon-triage; risk 2: regex widening with a regression control, exit-code consumers are the blast radius
reported_from: Jev-unofficial-toolkit
harness_commit: 5e60cb01   # origin/development at capture; relay_drive.py identical at the report-time local HEAD b22e2641
non_goals:
  - Changing how marathon phases name their round blocks
  - Auto-handoff when RELAY_PEER is unset (separate WARN, separate issue if wanted)
related:
  - GH-749 (marathon umbrella — this is lane L1)
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

## Status

| What was just completed | What's next |
|---|---|
| 2026-09-22: promoted to 2-WORKING as lane L1 of marathon GH-749 (`/marathon-triage` → `/unstuck`); ratings confirmed (e1/c2/r2/p1); preflight contract added. | Marathon phase p1 fires from `~/marathon-clones/marathon-gh-749-relay-gate-cost`: widen `review_blocks_added`, add the GH-397 regression case, gate green, lands in the GH-749 delivery PR. |

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/relay_drive.py", "pattern": "GH-720" },
    { "type": "grep_absent", "path": "test/gh648-l8-zero-output-handback.sh", "pattern": "Reviewer \\(agy\\)" }
  ],
  "artifacts": [
    "utils/py/relay_drive.py",
    "test/gh648-l8-zero-output-handback.sh",
    "relay-automation/new-relay.sh"
  ],
  "remediation": {
    "source": "issue#720",
    "criteria": "review_blocks_added in utils/py/relay_drive.py counts a reviewer block headed `### Reviewer (<agent>)` or `### Reviewer — Round N` when a non-empty body follows the heading, so --review-once exits 5 on a real changes-requested handback; a heading with no body still reads as zero output (exit 3, GH-397); test/gh648-l8-zero-output-handback.sh gains the `### Reviewer (agy)` regression case that fails before the fix; relay-automation/new-relay.sh's TAKE YOUR TURN block names the accepted heading forms."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/relay_drive.py",
      "test/gh648-l8-zero-output-handback.sh",
      "relay-automation/new-relay.sh"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- [ ] `relay-drive.sh --review-once` on a thread whose reviewer appended a substantive block under `### Reviewer (agy)` exits **5**, not 3 (red control: the same run at `origin/development` exits 3).
- [ ] A reviewer turn that appends only a heading with no body, or nothing at all, still exits **3** with the GH-397 "zero-output turn is not review coverage" line.
- [ ] Both existing heading forms (`### Round N · Reviewer · …`, `### Reviewer · Round N …`) still count — the marathon-phase and relay-thread paths in `test/gh648-l8-zero-output-handback.sh` stay green.
- [ ] `relay-automation/new-relay.sh`'s embedded `▶ TAKE YOUR TURN` block states the accepted reviewer heading forms (one sentence; no new prompt file).
- [ ] Evidence under `TESTS-RESULTS/<UTC-date>+GH-720/` with `provenance.jsonl`; `bash validate.sh` green in the marathon clone.

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
- [x] Set/correct the triage ratings; clear `ratings_provisional` once real — done 2026-09-22 (marathon-triage, GH-749)

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression test covers the failure path before the fix lands
- [ ] The fix composes with the existing harness rather than adding a parallel path

## Merge evidence

- PR #729 merged 2026-09-21 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #750 merged 2026-09-22 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
