---
gh_issue: 977
source: https://github.com/HiQS-Labs/XYZ-forge/issues/977
title: "roadmap update --raw-text without a rated token keeps the row's saved rating"
status: "Prepared 2026-11-25 (1-INBOX, held: not enqueued, not started)"
created: 2026-11-25
updated: 2026-11-25
owner: Conveyor preparation (Day 2 Flywheel proving-arc candidate; ledger #1610, ranking #1616)
doc_type: bugfix
ratings_provisional: true
non_goals:
  - Any change to `roadmap rate`, `roadmap pickup` or `roadmap add` rating semantics
  - A sweep or repair of historical rows (the issue notes a sweep is possible; it is a separate decision)
  - A new test suite or gate machinery (GH-831)
goal: >
  A text-only `roadmap update --raw-text` (a bullet with no `rated` token) must leave the row's saved
  ratings intact instead of nulling all five rating columns, so the SOP Step 1b promotion path stops
  silently dropping a row's rank.
---

# GH-977 · roadmap update keeps the saved rating

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof, both-consumer validation and PRS rating prepared on 2026-11-25. No implementation, no queue admission. | Independent preparation review, publication of this preparation PR, then an explicit `/jog 977` or `/start-task 977` by the operator. |

## Acceptance

- [ ] `roadmap update --raw-text` must preserve an existing rating when the new bullet carries no `rated` token (or refuse with a message naming the rating it would drop).
- [ ] SOP.md Step 1b: say that the promotion bullet must carry the existing `rated` token, until the verb is fixed.
- [ ] Red control on an existing suite: rate, then update raw text without a token, then read back the four fields.
- [ ] A text-only update leaves all five stored rating fields (`rating_pri`, `rating_sev`, `rating_appeal`, `rating_effort`, `rating_ovr`) unchanged; the chosen shape is preserve, not refuse.
- [ ] An update whose new text carries an explicit `rated` token still replaces the scores.
- [ ] The existing `test/gh257-roadmap-ledger-fixes.sh` Case 8 "Rated -> Unrated" is edited deliberately to pin preserve-on-omit; no new suite is added.

## Acceptance — deviations from the issue

The issue states its acceptance under `## Ask`, not `## Acceptance`, so Preflight cannot compare the two lists (it reports `no-issue-section`, advisory). The first three criteria above are the issue's three Ask bullets copied verbatim. The rest are declared here.

- [added] A text-only update leaves all five stored rating fields (`rating_pri`, `rating_sev`, `rating_appeal`, `rating_effort`, `rating_ovr`) unchanged; the chosen shape is preserve, not refuse. — reason: the issue allows either shape; the newest triage note on #977 (2026-11-25) prefers preserving, and the Ask's "four fields" omits the override column, which the writer also nulls.
- [added] An update whose new text carries an explicit `rated` token still replaces the scores. — reason: the issue is silent; the existing writer contract (GH-249/GH-257) must keep working, and the probe checks it as the positive control.
- [added] The existing `test/gh257-roadmap-ledger-fixes.sh` Case 8 "Rated -> Unrated" is edited deliberately to pin preserve-on-omit; no new suite is added. — reason: that case currently pins the clearing behavior (test lines 147-152), so the fix turns the existing gate red until the case is made truthful; AGENTS.md (GH-831) allows editing an existing suite only for this.

## Recon note (parent-only; no research child, per the operator's brief)

- **Baseline:** `origin/development` at `086b657ea37dc2c7d3e1433e29157b451b331f1c` (2026-11-25).
- **State writer:** `cmd_roadmap_update` in `utils/py/releases_app.py:4108`. It re-parses the replacement text with `parse_rating` (`:4181`) and, inside `mutate`, writes all five rating columns unconditionally whenever `--raw-text` is given (`:4231`). A bullet with no token parses to five NULLs.
- **Downstream consumers:** `roadmap list` (calc rank), LEADERBOARD views, Jog/start-task selection. The `rated` work event survives, so history still looks rated while the row reads NULL (the issue's observation).
- **Entry paths:** SOP.md Step 1b step 3 (line 83) is the documented path that hits it; recurrence recorded on #977 (2026-10-06 GH-976, 2026-11-14 GH-1466).
- **Retry boundary:** none: a single ledger write; repair is one `roadmap rate` per row. Reversibility: Easy.
- **Dependencies:** none open. Open PRs touching these files: none (#1608 touches skills-army-hq only; #1024 is a draft unrelated to `releases_app.py`).
- **Discriminating check:** `TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py` drives the real CLI in a disposable ledger. It exits 0 only when a text-only update keeps all five fields and an explicit token still rescores; any crash exits nonzero, which Preflight reads as unfixed.
- **Foreseeable approvals/runtime:** none beyond the normal gate; the builder may not run the gate itself.
- **Unknowns:** whether any other roadmap row already lost its rating (a sweep for rated events with NULL fields is out of scope; named in the issue).
- **Next owner:** the operator (explicit `/jog 977` or `/start-task 977`).

## Attempt and retry history (read 2026-11-25, nothing reset)

- `jog_queue`: no row for #977. `roadmap_items`: no row for #977 before this preparation. `work_events` and `op_receipts`: none.
- Branches and PRs: no remote branch or PR for #977 (PR #978 is GH-976, which first reported this defect). `relay-system/`: no receipts. No prior capture doc.
- #977 comments: 2026-11-14 recurrence note; 2026-11-25 triage narrowing (prefer preserve; GH-257 pins clearing).
- Attempts consumed: 0 queue, 0 native.

## Rating rationale

`rated 65/55/50/85` (sum 255), written through `roadmap pickup` on 2026-11-25; `ratings_provisional` stays true until the operator confirms.

- Severity 55: silent loss of ranking metadata (not of work), on a documented path, recoverable with one `roadmap rate`.
- Priority 65: severity-led plus recurrence: 1 distinct incident in 2026-11-11..11-25 (the 2026-11-14 GH-1466 hit), 0 in 2026-10-28..11-11, and the 2026-10-06 GH-976 hit before both windows; coverage limit: only issue/comment evidence, no sweep of the ledger. #1616 ranks this first.
- Appeal 50: neutral (no operator preference supplied).
- Effort 85: one conditional in the writer, one suite case edited, one SOP sentence.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh257-roadmap-ledger-fixes.sh && bash test/gh549-work-events.sh",
  "round_cap": 2,
  "artifacts": [
    "utils/py/releases_app.py",
    "test/gh257-roadmap-ledger-fixes.sh",
    "SOP.md",
    "TESTS-RESULTS/2026-11-25+GH-977/"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-25+GH-977/readiness_probe.py",
      "expect_nonzero": true
    }
  ],
  "remediation": {
    "source": "issue#977",
    "criteria": "roadmap update --raw-text with no rated token keeps all five stored rating fields (preserve, not refuse); an explicit rated token still replaces them; the existing gh257 suite Case 8 is edited to pin preserve-on-omit; SOP.md Step 1b stays true of the verb. No new suite."
  }
}
```

The probe is a retained manual check, not a suite: it exits 0 only when the fixed behavior is observed, and `expect_nonzero: true` makes any crash read as unfixed. Probe evidence (unfixed, simulated fix, comment-only edit) and both consumers' exit codes are in `TESTS-RESULTS/2026-11-25+GH-977/`.
