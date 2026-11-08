# GH-1341 manual checks (2026-11-04)

No new tests (GH-831). Docs-only change to two skill files; verification is the docs gate plus a
read of the instruction as its consumer loads it, plus read-only `gh` lookups that walk each branch
of the section 4 post/edit decision. Output: `smoke-output.txt`.

| # | Check | Observed | Verdict |
|---|---|---|---|
| 1 | Consumer read: both `SKILL.md` frontmatters parse (PyYAML) and their descriptions mention the closeout; todo-list has `## 4. Close the loop on GitHub`; both run ends (section 3 step 4, section 2 wake prompt) call it; start-task links the anchor and Step 6 calls the closeout at an early stop | all `True` | pass |
| 2 | Main path: lookup for this branch's real marker on #1341 | exit 0, empty → create branch | pass |
| 3 | Adjacent: comment that only *quotes* the template marker | `contains()` matched comment 6638233042 (false positive); `startswith()` empty | pass — found the defect, now fixed (skill uses `startswith`) |
| 4 | Adjacent (rerun): a comment whose body starts with the looked-for text | exit 0, id 6638233042 → edit branch | pass |
| 5 | Failed lookup (issue 999999) | HTTP 404, exit 1 → `unposted`, never create | pass |
| 6 | Docs gate `utils/pdda/pdda.sh run` | exit 0, 0 errors; warnings 44 → 40, none from this diff | pass |

Limits: live create and PATCH were not run here, because they write to the issue. The first real
create, and its rerun edit, happens when this task posts its own start-task closeout on #1341 at
Step 9; that result goes in the PR, not in this receipt. The deployed copy
(`~/.claude/skills/todo-list` → Deployed Skills) still serves origin until the post-merge
`intake.py update todo-list`; the read above is of the source file the deployer copies.
