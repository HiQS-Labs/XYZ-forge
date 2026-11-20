# OL-09 independent preparation QA — round 1 of 2 — receipt

Reviewer: Claude Opus 5.5 sub-agent, read-only, no children. Reviewed 2026-11-17 ~20:33–20:36Z (inside the 20:31:12–21:16:12Z window).
Verdict: APPROVE (round 1). The OL-09 five-point instruction milestone is satisfied **once the evidence is published**. No blocking defects. Three small, non-blocking evidence notes below. No OL-10, unattended, runtime-enforcement, canonical-pickup or readiness credit.

## Inputs read

- Live #1400 body (read-only `gh`): OL-09 checklist text line 92, table row line 17 ("authorized through reviewed ready PR; no deployment or merge"), lines 23 (daily-goal intake retained, risk deferral opt-in, OL-09/OL-10 reported separately).
- Live #1476 (OPEN, 5 comments, no labels), PR #1514 (OPEN, not draft, head `2e22cce06edaa1a4f0a58b85cff9e23ab62a18af`, unmerged). Live #1517/#1518/#1171/#1520 states: all OPEN, no labels.
- Branch clone HEAD `2e22cce06…`: `skills/1-hourly/conveyor/SKILL.md` lines 22–58 ("Research depth and RAW intake"), `skills/3-weekly/10days/SKILL.md` Steps 3–6 (lines ~232–436, grep-level).
- `ol09-followup/`: SUMMARY.md, freshness.json, freshness.diff (hunk headers + def scan), issue-1520.json (body + updatedAt), issue-1517.json (acceptance block).
- `real-preparation-trial/`: SUMMARY.md, raw-1517/RESULT.md, research-receipt.md, capture-GH-1517.repaired.md, provenance.jsonl, preflight/result.json + repair-result.json + 1517-repaired.out tail, held-1518/RESULT.md, prepared-1171/RESULT.md.

## Checks performed and results

| OL-09 clause | Check | Result |
| --- | --- | --- |
| Accept unprepared requests | #1517 RESULT: no row/capture/contract at intake; selection note frozen before child; isolated writer 30/30/50/90, ovr null | Pass (branch policy, isolated writer only) |
| Corrected capture is what passed preflight | sha256 of `capture-GH-1517.repaired.md` = `eb3e1108…`, equals the isolated-root doc that repair-result.json ran (exit 0) and equals provenance.jsonl record; original capture `50459585…` retained with exit 5 | Pass — binding is exact |
| Acceptance verbatim | Issue-1517 snapshot "Acceptance" block found as exact substring in repaired capture | Pass |
| Bounded medium default | One read-only child, numeric deadline, budget 1/1 → 0; receipt covers SHA, owner/writer, retry boundaries, probe, artifacts, acceptance, approvals, unknowns, next owner (Conveyor line 53 checklist) | Pass |
| Reuse applicable evidence | #1171 capture byte-identical (freshness.json); relay_drive.py diff hunks at 372, 687, 738, 990, 1074, 1144 with no `def` changes — first hunk precedes the probed functions (425–464). #1517 diff hunks at SKILL.md 653 and script 2392, both outside receipt's cited paragraph (494–495) and sweep trigger path; receipt line numbers after 2392 shift (+~20), acknowledged | Pass; verdicts correctly kept pinned to 6000f3de |
| Deepen for justified risk/effort | Walkthroughs 1–2 against Conveyor "Deeper when justified" (state/authority/recovery/high actual effort; cheapness ≠ effort) | Pass as instruction check only; no live deep research claimed, correctly labelled |
| Preserve unknowns as holds | #1518 held for operator, no capture/row/label, live unchanged; #1171 held on exhausted 2/2 budget, candidate ae942d0f preserved, no reset | Pass |
| Risk deferral only on request | Walkthroughs 3–4: default keeps #1518 visible; explicit opt-in scoped to named batch, expires, product decision stays held — matches Conveyor lines 49–51 and 10days Step 3 HELD semantics | Pass as hypothetical instruction check |
| Daily-goal intake (#1400 row 17) | #1520 body: three explicit links, ≤ default five, explicit selection, time window; dispositions in SUMMARY match Conveyor lines 24–30 (link ≠ admission, no invented goals) | Pass; snapshot updatedAt 20:32:25Z equals live |

## Small evidence notes (non-blocking)

1. #1400 header line 5 still reads "OL-09 remains unchecked … No implementation has started." That is stale against ready PR #1514 and this evidence; the publication step should supersede it additively (not rewrite history) when the box is ticked.
2. `ol09-followup/` and `real-preparation-trial/held-1518/` are untracked at `2e22cce06`. The award is conditional on them being committed/published as-is; the follow-up SUMMARY should append this QA receipt and the publication SHA rather than editing earlier receipts.
3. Walkthrough 1's citation "#1328 R3/W2" was not independently verified in this round (time box). It does not affect the decision; the hold stands on Conveyor's own "A product/human decision stays held" rule.

## Limitations

- Instruction-consumer review, not an end-to-end or runtime-enforcement test; deep-research and risk-deferral paths are paper walkthroughs only.
- 10days path not executed (grep-level read of Steps 3–6); OL-09 text does not require a 10days run.
- #1328 and AGENTS/ROUTER not fully read; graph not used (direct source reads only); verify origin not fetched per instruction.
- Preflight outputs reviewed by exit codes, hashes and tails, not full packet content.
- Isolated ledger is a scratch copy; canonical-ledger behavior unverified (OL-10 territory).

## Scoring

OL-09: award 5 points after publication of these artifacts and this receipt (8/20 → 13/20 on the follow-up's local scale; #1400 baseline accounting is the operator's). OL-10 and unattended qualification: not earned, not assessed.
