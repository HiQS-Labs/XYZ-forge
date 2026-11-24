---
gh_issue: 1590
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1590
title: "build_queue --daily-goals: a backticked foreign lead (`owner/repo#N`) on a checklist line lets a later #N become the item"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-24
updated: 2026-11-24
owner: Kickstart run 3 child (GH-1592)
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
phases: 1
goal: "A checklist line whose first reference is backticked and foreign admits nothing; a backticked local lead stays the item."
---

# GH-1590 — daily-goals backticked foreign lead

## Observed problem

On base `305ebc303`, `skills/1-hourly/kickstart/scripts/build_queue.py` runs `parse_daily_goals_refs` (lines 259-285)
on a body that `_sanitize_body` (146-150) has already passed through `INLINE_BACKTICK` (line 99). That deletes every
backticked span that `REF_BACKTICK` (line 96, local `#N` / `PR #N` only) did not unwrap, so a backticked foreign
reference vanishes and a later `#N` on the same unchecked line becomes the first reference and is admitted.

Read-only reproduction on `305ebc303` (`parse_daily_goals_refs(body, "me/repo", 1)`):

| Line | Now | Correct |
|---|---|---|
| ``- [ ] `other/repo#9` then #10`` | `[10]` | `[]` |
| `- [ ] other/repo#9 then #10` (bare foreign lead) | `[]` | `[]` |
| ``- [ ] `#10` then #11`` (backticked local lead) | `[10]` | `[10]` |
| ``- [ ] `me/repo#10` then #11`` (backticked same-repo qualified lead) | `[11]` | `[10]` |
| ``- [x] `o/r#9` #10`` then ``- [ ] #7`` | `[7]` | `[7]` |
| ``- [ ] #7``, a fenced block containing a backticked foreign reference, then ``- [ ] #99`` | `[7, 99]` | `[7, 99]` (a fenced-out reference must never become a lead) |
| ``prose `o/r#9` and #10 #11`` (no task list) | `[10, 11]` | `[10, 11]` |

Effect: a run scoped by `--daily-goals` can queue, and under the standing owner grant merge or close, an issue the
operator never listed. The queue rules fail closed elsewhere, so this is the one admission path that fails open.

## Recon map

- Entry: `--daily-goals` handling `build_queue.py:441-461`; `refs` feed `selected_prs` / `sel_issues` (462-486).
- Lead choice: first `ATOMIC_REF` match (line 98) on an unchecked `CHECKBOX` line (97), `parse_daily_goals_refs:273-276`.
- `_sanitize_body` is also the U15 hold-evidence sanitizer (line 187), so it must not change.
- Not a frozen twin; no suite under `test/` covers `build_queue.py`. Prior art: GH-1569 / PR #1589 (`TESTS-RESULTS/2026-11-23+GH-1569/`).
- Doc consumer: `skills/1-hourly/kickstart/SKILL.md` line 305 describes the lead rule.

## Plan

Smallest change, one file plus one doc line:

1. Add `FOREIGN_REF_BACKTICK` next to `REF_BACKTICK` (lines 96-99): ``re.compile(r"`([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#\d+)`")``.
2. In `parse_daily_goals_refs`, only when the body has a task list, recompute `lines` from
   `_sanitize_body(FOREIGN_REF_BACKTICK.sub(r"\1", FENCED_CODE.sub("", body or "")))`, so a backticked foreign
   reference stays visible and wins as the lead. Fenced blocks are removed FIRST, because unwrapping before that would
   turn a fenced-out reference into a live item (counterexample in the table). The no-task-list path is not touched (byte-identical).
3. Adjust the `SKILL.md` line 305 sentence to say a backticked foreign lead also admits nothing.
4. Record a manual red/green on the table above under `TESTS-RESULTS/2026-11-24+GH-1590/` with `provenance.jsonl`.

## Non-goals

`_sanitize_body`, `REF_BACKTICK`, hold logic, the no-task-list semantics, new tests (GH-831), the frozen Bash twins.

## Rating rationale (2026-11-24)

pri 45 / sev 40 / appeal 50 / effort 85. Severity: an unlisted item can enter an autonomous run's queue; the
run's other holds and the owner grant bound the damage and a human can recover. Priority: severity-led, raised
slightly because Kickstart run 3 consumes this path. Appeal: neutral 50. Effort: one file, a few lines. Recurrence:
one CodeRabbit Minor on #1589 (2026-11-23); no other reports, trend unknown.

## Acceptance

- [ ] ``- [ ] `other/repo#9` then #10`` admits no reference.
- [ ] A backticked local lead (``- [ ] `#10` then #11``) still admits only `#10`, and a backticked same-repo qualified lead admits only that number.
- [ ] A bare foreign lead, a checked `[x]` line and a fenced block holding a backticked foreign reference keep their current results.
- [ ] A body with no task list returns exactly what it returns today.
- [ ] Manual red and green controls on the table above are retained under `TESTS-RESULTS/2026-11-24+GH-1590/` with provenance, and no test file or suite is added.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash utils/pdda/pdda.sh run",
  "fix_probes": [
    {
      "type": "command",
      "cmd": "env python3 -B -I -c 'import importlib.util as u,sys;s=u.spec_from_file_location(\"bq\",\"skills/1-hourly/kickstart/scripts/build_queue.py\");m=u.module_from_spec(s);s.loader.exec_module(m);sys.exit(0 if m.parse_daily_goals_refs(\"- [ ] `other/repo#9` then #10\",\"me/repo\",1)==[10] else 1)'"
    },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-11-24+GH-1590/manual-check.md" },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-11-24+GH-1590/provenance.jsonl" }
  ],
  "artifacts": [
    "skills/1-hourly/kickstart/scripts/build_queue.py",
    "skills/1-hourly/kickstart/SKILL.md",
    "TESTS-RESULTS/2026-11-24+GH-1590/manual-check.md",
    "TESTS-RESULTS/2026-11-24+GH-1590/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-24+GH-1590/manual-check.md",
    "TESTS-RESULTS/2026-11-24+GH-1590/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1590",
    "criteria": "A backticked foreign lead on an unchecked checklist line admits no reference; a backticked local or same-repo lead admits only itself; the no-task-list path, bare foreign leads and checked lines are unchanged; manual red/green controls are retained under TESTS-RESULTS/2026-11-24+GH-1590/ with provenance and no test is added."
  }
}
```
