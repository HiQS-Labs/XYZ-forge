# Smoke: base replay on the deploy input (red control)

Executor: a fresh sub-agent, read-only (4 `Read` calls: `inputs/base-SKILL.md` (the skill at base `b479f74e0`, 107 lines), `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`; no writes, no `gh`). Same input as smoke (a). Nothing published.

Result: the base skill produces no run sheet. Deploy gates stay as a prose section ("Deploy plan ... Planned steps, not approvals") and a bullet list; there is no six-column table, no per-step pass evidence or stop condition, and the proposed body has no section placed ahead of everything else for deploy gates (the opening sections were "Done since yesterday" and "Reviews and deploy gates"). Gaps were marked OPEN in prose and questions were asked only in the chat reply, not as a morning section. Relevant excerpt of the base body, verbatim:

```markdown
## Deploy plan (from the team's deploy checklist, linked in the repo deploy docs)
Planned steps, not approvals. Order is as listed.
- Go-ahead for staging: Lead 1, at 10:00, by a comment on PR #104 (see "Reviews and deploy gates" above). Pass: comment present from Lead 1 at the current head. Stop: any open Must finding.
- Deploy to staging: Dev A, 11:00, runs the repo's deploy script from the shared build machine with the deploy key. Pass: health page shows build bbb2222 and 3 sample orders listed. Stop: health page red.
- After-deploy check on staging: Dev C, method: run the saved search query against staging. OPEN: no time given, no pass criterion given. Needs the team to fill in.
- Production go-ahead: someone from the team, this evening. OPEN: no owner named, no method. Needs the team to fill in.
- Late-evening after-deploy check on production: OPEN: nobody named yet. Not checked.
- Config change on the staging host: set flag NEW_SEARCH=on (copied from last month's checklist). UNCONFIRMED: this is a write to a server, and its source is last month's checklist. Do not treat it as approved. Confirm it is still current and get the operator's explicit approval before anyone acts on it.
```

Note for the reviewer: the base executor still flagged the missing fields, because the fictional input marked them in words; the base carries them as prose, as the issue describes. The measured differences are the absence of the sheet, of the rows' pass/stop structure, of the early rehearsal and access rows, and of first placement.
