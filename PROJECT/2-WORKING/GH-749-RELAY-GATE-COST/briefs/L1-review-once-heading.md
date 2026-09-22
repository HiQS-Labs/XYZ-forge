---
title: "L1 brief — #720: a real reviewer block is not a zero-output stall (umbrella #749)"
status: "Brief (input to the GH-749 marathon — not a tracked plan)"
created: 2026-09-22
updated: 2026-09-22
owner: Noel Saw
goal: >
  relay-drive --review-once must exit 5 (handed back without approving) when the reviewer appended a
  substantive block under any heading form the shipped scaffold elicits, and still exit 3 on a genuinely
  empty turn (GH-397).
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/749
  - https://github.com/HiQS-Labs/XYZ-forge/issues/720
  - https://github.com/HiQS-Labs/XYZ-forge/issues/397
---

# L1 — #720: a real reviewer block is not a zero-output stall

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-22); contract in `PROJECT/2-WORKING/GH-720-REVIEW-ONCE-BLOCK-REGEX.md` preflight-ready | Phase p1 fires first in the chain |

Umbrella: #749 · Issue: #720 · Phase p1 · no `depends_on`

## Ground truth (from the issue — verified at `origin/development` a0776330)

`utils/py/relay_drive.py:39`, inside `review_blocks_added(before, after)`:

```python
pat = re.compile(r"^### (Round .*· Reviewer ·|Reviewer · Round )", re.M)
```

Only `### Round N · Reviewer · …` (marathon phases) and `### Reviewer · Round N …` (relay threads) count as an appended review block. The `▶ TAKE YOUR TURN` block that `relay-automation/new-relay.sh` embeds (`:105`, "Append ONE block at the very bottom") never states that heading, so headless reviewers write `### Reviewer (agy)` or `### Reviewer — Round 1` and a 37-line graded review is reported as exit 3 "zero-output turn" (four observations in the issue's Evidence table; the only variable is the `·` separator).

## Goal — the smallest change that makes the exit code true

1. **`utils/py/relay_drive.py`** — widen `review_blocks_added` so a block counts when its heading is a reviewer heading in any of the elicited forms **and a non-empty body follows it**:
   - `### Round N · Reviewer · <agent>` and `### Reviewer · Round N …` (existing — must keep counting),
   - `### Reviewer (<agent>)`, `### Reviewer (<agent>) — r2`, `### Reviewer — Round N`, `### Reviewer — Round N (<agent>)`.
   - A heading with nothing but whitespace before the next heading / marker / EOF is **not** a block (GH-397's intent: zero output is not coverage). Keep the function pure (two strings in, an int out) and the docstring's GH-397 rationale; tag the change `GH-720` in a comment.
   - Do **not** touch the bash twin `relay-automation/relay-drive.sh` (FROZEN, GH-308) and do not add a config knob.
2. **`test/gh648-l8-zero-output-handback.sh`** — this is the suite that pins `review_blocks_added` (it already asserts the `### Round 1 · Reviewer · agy` form, the header-flip-only case = 0, and the unchanged case = 0). Add, in the same unittest style:
   - `### Reviewer (agy)` + graded body → 1 (**red before the fix**: the assertion fails at HEAD),
   - `### Reviewer — Round 1` + body → 1,
   - `### Reviewer (agy)` heading followed by only blank lines → 0,
   - the two existing forms still → 1 (unchanged assertions stay).
   The suite is already registered in `validate.sh` — no registry edit in this lane.
3. **`relay-automation/new-relay.sh`** — one sentence in the embedded `▶ TAKE YOUR TURN` block, next to step 4 ("Append ONE block"), naming the accepted reviewer heading forms. No new prompt file; do not restructure the block.

## Rules

Python twin authoritative. Shortest diff (`/ponytail`). No new module, helper file, or parallel oracle. Evidence: `TESTS-RESULTS/2026-09-22+GH-720/` with the red control (new assertion failing at HEAD, captured before the fix) and the green run, plus `provenance.jsonl`. `bash validate.sh` green is the phase gate.

## Acceptance / Guard

- `test/gh648-l8-zero-output-handback.sh`: `### Reviewer (agy)` with body → counted; heading-only → not counted; both legacy forms → counted; header flip without a block → not counted.
- `relay-drive.sh --review-once` on the issue's reproduction shape (block under `### Reviewer (agy)`, header flipped `NEXT: Producer`) exits **5**; a turn that appends nothing exits **3** with the GH-397 line.
- `new-relay.sh --print` output contains the heading sentence; `test/new-relay.sh` stays green.
