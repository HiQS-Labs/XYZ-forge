---
gh_issue: 1590
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1590
title: "build_queue --daily-goals: a backticked foreign lead no longer lets a later #N become the item"
status: "Prepared 2026-11-27 (1-INBOX, not enqueued, not started)"
created: 2026-11-27
updated: 2026-11-27
owner: Conveyor preparation (Flywheel Run A queue; ledger #1658)
doc_type: bugfix
ratings_provisional: true
non_goals:
  - Any change to the no-task-list path (lines without a checkbox): it stays byte-identical
  - Hold detection (`issue_hold_reason`, `AFTER`, `BLOCKED_BY`) and `_sanitize_body`'s other callers
  - Task-list syntaxes beyond the existing `CHECKBOX` grammar
  - A new test suite or gate machinery (GH-831); edits to `test/gh280-jog-marathon-adapter.sh`
goal: >
  On a daily-goals checklist line whose first reference is a backticked foreign reference
  (`other/repo#9`), parse_daily_goals_refs admits nothing from that line; local and plain-foreign
  leads and the no-task-list path behave exactly as today.
---

# GH-1590 · Backticked foreign lead on a daily-goals checklist line

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof (unfixed / simulated fix / fake fix), consumer validation and PRS rating prepared 2026-11-27 at `6142128d9c43`. No implementation, no queue admission. | Preparation review, publication of the Run A preparation PR, merge to `development`, then a fresh preflight at the integration ref (Conveyor step 6). Next owner: the Run A launch step (#1658). |

## Acceptance

- [ ] `parse_daily_goals_refs` admits nothing from a checklist line whose first reference is a backticked foreign reference (`- [ ] `other/repo#9` then #10` yields no item).
- [ ] Local leads (bare or backticked `#N`), plain foreign leads and the no-task-list path return exactly what they return today.
- [ ] A manual red/green check is recorded under `TESTS-RESULTS/` (GH-831: no new suite).

## Acceptance — deviations from the issue

The issue has no `## Acceptance` heading, so Preflight reports acceptance fidelity as advisory. The criteria above are declared here.

- [added] `parse_daily_goals_refs` admits nothing from a checklist line whose first reference is a backticked foreign reference (`- [ ] `other/repo#9` then #10` yields no item). — reason: restates the issue's example ("#10 should not be admitted") as a checkable criterion.
- [added] Local leads (bare or backticked `#N`), plain foreign leads and the no-task-list path return exactly what they return today. — reason: the issue says "Keep the no-task-list path byte-identical"; the probe's controls pin the other lead shapes so dropping every ref cannot read as fixed.
- [added] A manual red/green check is recorded under `TESTS-RESULTS/` (GH-831: no new suite). — reason: the issue asks for "existing coverage and a manual red/green only"; no suite covers `build_queue.py` directly.

## Recon note (parent-only)

The operator's brief asked for capture, contract, preflight and one independent review. The parent read the whole seam, so no separate research child was dispatched. Budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2` (2026-11-27).
- **Observed (reproduced):** `parse_daily_goals_refs("- [ ] `other/repo#9` then #10\n", "HiQS-Labs/XYZ-forge", 1)` returns `[10]`; expected `[]`. The plain (unbackticked) foreign lead already returns `[]`.
- **Call path:** `build_queue.py --daily-goals N` → `parse_daily_goals_refs(dg_obj.get("body"), slug, dg_num)` (`skills/1-hourly/kickstart/scripts/build_queue.py:461`) → `_sanitize_body` (`:146-150`) strips fences, unwraps backticked local refs (`REF_BACKTICK`, `:96`), then deletes every remaining inline code span (`INLINE_BACKTICK`, `:99`). A backticked `other/repo#9` is deleted, so on a task-list line (`:259-284`) `refs[:1]` picks the later `#10` (`ATOMIC_REF`, `:98`).
- **State writer / consumer:** none written here; the returned list becomes the daily-goals queue selection. A wrong item is admitted to the queue, which is the harm.
- **Smallest plan:** in `parse_daily_goals_refs` only, keep a backticked span that is itself a single `ATOMIC_REF` as its bare text before taking the first reference (so the foreign lead is consumed atomically and skipped), or equivalent. `_sanitize_body` stays as is for its other callers (hold detection).
- **Dependencies / overlap:** no open PR touches `build_queue.py`. The file is loaded at runtime by Jog's `hold_refusal` (`utils/py/jog_run.py`), which uses `AFTER`, `_sanitize_body` and `issue_hold_reason` only; those are non-goals here.
- **Discriminating check:** the fix probe (contract below) exits 0 only when the backticked foreign lead admits nothing **and** four controls hold (plain foreign lead `[]`, backticked local lead `[12]`, bare local lead `[11]`, no-task-list line `[14, 15]`). Matrix (`TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`): base 1; simulated fix 0; fake fix (`return []`) 1.
- **Write set:** `build_queue.py` plus one new delivery receipt (`artifacts_new`, with a `path_absent` probe).
- **Foreseeable approvals/runtime:** none; probe and gate need no network or `gh`.
- **Unknowns:** none blocking.
- **Next owner:** the Run A launch step (#1658), then Jog.

## Attempt and retry history (read 2026-11-27, nothing reset)

- No `roadmap_items` row, no `jog_queue` row, no capture, no branch or PR for #1590 before this preparation. Attempts consumed: 0.

## Rating rationale

`rated 55/45/50/90` (sum 240), written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms.

- Severity 45: a wrong issue can be admitted to a daily-goals queue; it needs a specific line shape.
- Priority 55: severity-led; found by CodeRabbit on PR #1589, not yet observed in a live run.
- Appeal 50: neutral.
- Effort 90: one function.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh280-jog-marathon-adapter.sh",
  "round_cap": 9,
  "prepared_commit": "6142128d9c433d6b12972c6cd9a6f864f0ed9da2",
  "artifacts": [
    "skills/1-hourly/kickstart/scripts/build_queue.py",
    "TESTS-RESULTS/2026-11-27+GH-1590/delivery.md"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-27+GH-1590/delivery.md"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "env PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'\nimport importlib.util as u\nsp = u.spec_from_file_location(\"bq\", \"skills/1-hourly/kickstart/scripts/build_queue.py\")\nm = u.module_from_spec(sp); sp.loader.exec_module(m)\nf, S, B = m.parse_daily_goals_refs, \"HiQS-Labs/XYZ-forge\", chr(96)\nassert f(\"- [ ] \" + B + \"other/repo#9\" + B + \" then #10\\n\", S, 1) == [], \"backticked foreign lead admitted a later #N\"\nassert f(\"- [ ] other/repo#9 then #10\\n\", S, 1) == [], \"plain foreign lead control\"\nassert f(\"- [ ] \" + B + \"#12\" + B + \" then #10\\n\", S, 1) == [12], \"backticked local lead control\"\nassert f(\"- [ ] #11 then #10\\n\", S, 1) == [11], \"local lead control\"\nassert f(\"Do #14 and \" + B + \"other/repo#9\" + B + \" #15\\n\", S, 1) == [14, 15], \"no-task-list path changed\"\nPY",
      "expect_nonzero": true
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-27+GH-1590/delivery.md"
    }
  ],
  "remediation": {
    "source": "issue#1590",
    "criteria": "parse_daily_goals_refs admits nothing from a checklist line whose first reference is a backticked foreign reference; local, plain-foreign and no-task-list results are unchanged. Change build_queue.py only (parse_daily_goals_refs); leave _sanitize_body and hold detection as they are. Record the probe's before/after output in TESTS-RESULTS/2026-11-27+GH-1590/delivery.md. No new suite, no suite edits."
  }
}
```

The probe is an inline manual check, not a suite: it exits 0 only when the fixed behavior and all controls hold, and `expect_nonzero: true` makes any crash read as unfixed. It is inline so it evaluates at `prepared_commit` itself. A readable copy and its red/green outputs are in `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`.
