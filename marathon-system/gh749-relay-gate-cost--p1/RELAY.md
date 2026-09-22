# Marathon Phase p1
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P1-TURN-2 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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

**Retry note (2026-09-22):** the first attempt landed this fix (`45b7d2cd`, Approved) but its gate went red on `relay-pkg-freshness.sh` — `relay-automation/new-relay.sh` is packaged into `skills/relay-automation/relay-pkg.tar.gz`, so any edit there must be followed by `bash skills/relay-automation/make-pkg.sh` (the tarball is now in this lane's write-set). If the fix is already present in the tree, verify it against the acceptance list, regenerate the tarball if `bash test/relay-pkg-freshness.sh` reports drift, and hand off — do not rewrite working code.

Python twin authoritative. Shortest diff (`/ponytail`). No new module, helper file, or parallel oracle. Evidence: `TESTS-RESULTS/2026-09-22+GH-720/` with the red control (new assertion failing at HEAD, captured before the fix) and the green run, plus `provenance.jsonl`. `bash validate.sh` green is the phase gate.

## Acceptance / Guard

- `test/gh648-l8-zero-output-handback.sh`: `### Reviewer (agy)` with body → counted; heading-only → not counted; both legacy forms → counted; header flip without a block → not counted.
- `relay-drive.sh --review-once` on the issue's reproduction shape (block under `### Reviewer (agy)`, header flipped `NEXT: Producer`) exits **5**; a turn that appends nothing exits **3** with the GH-397 line.
- `new-relay.sh --print` output contains the heading sentence; `test/new-relay.sh` stays green.


## Debug mantra (auto-triggered — 2 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/gh749-relay-gate-cost--p1/ESCALATION.md`): `unattested-terminal`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/relay_drive.py, test/gh648-l8-zero-output-handback.sh, relay-automation/new-relay.sh, skills/relay-automation/relay-pkg.tar.gz
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick claim MARATHON-P1-TURN-2 --agent codex --paths "marathon-system/gh749-relay-gate-cost--p1/RELAY.md,utils/py/relay_drive.py, test/gh648-l8-zero-output-handback.sh, relay-automation/new-relay.sh, skills/relay-automation/relay-pkg.tar.gz"
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick ping MARATHON-P1-TURN-2 --agent codex
   - /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick release MARATHON-P1-TURN-2 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh749-relay-gate-cost--p1/RELAY.md and utils/py/relay_drive.py, test/gh648-l8-zero-output-handback.sh, relay-automation/new-relay.sh, skills/relay-automation/relay-pkg.tar.gz. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/relay_drive.py, test/gh648-l8-zero-output-handback.sh, relay-automation/new-relay.sh, skills/relay-automation/relay-pkg.tar.gz. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick release MARATHON-P1-TURN-2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick done MARATHON-P1-TURN-2 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-749-relay-gate-cost/bin/tick
   Edit ONLY marathon-system/gh749-relay-gate-cost--p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 1 · Builder · codex

Existing GH-720 implementation verified; no artifact changes needed. The Python counter accepts all six requested heading forms and rejects whitespace-only bodies before headings, markers, and EOF. Existing regressions cover both legacy forms, header-only mutations, and unchanged text. The scaffold already names accepted headings and requires a non-empty body. All 18 packaged source files match the tarball byte-for-byte; regeneration is unnecessary.

Verification this turn:
- Executed the embedded Python unittest from `test/gh648-l8-zero-output-handback.sh` with bytecode disabled: all 6 tests passed.
- Negative control: replaced the counter in memory with the brief's old regex, then ran the same tests; the supported-heading regression failed (exit 1), as expected.
- Ran `new-relay.sh --print`: accepted-heading guidance and non-empty-body requirement present.
- Compared every regular tarball member against its live source: no drift; non-empty member list asserted.
- Scratch logs: `.relay-scratch/gh720-green.log`, `gh720-red-control.log`, `gh720-scaffold.log`, and `gh720-package-before.log`. These are ephemeral verification records, not committed provenance.

Prior escalation says `unattested-terminal`, exit 0, gate not run, with no turn log; it does not establish a remaining parser or packaging failure. No live relay reproduction, shell test suite, or full gate was run in this linked worktree. Full gate and committed evidence remain the harness's responsibility under this turn's scope restrictions. Only this relay file changed, with the explicitly required NEXT header update and this appended block; no git commands were run.

Handing off to agy for independent review and terminal attestation.
