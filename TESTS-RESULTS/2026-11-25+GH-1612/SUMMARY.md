# GH-1612 evidence — deploy-day run sheet in `/yesterday-today`

Base `b479f74e0`; tested skill text = blob `6bbd309bc` (commit `540e04421`; unchanged since). Manual checks only (no new suite, GH-831). All ledgers, PRs and people in `inputs/` and the smoke files are fictional; role labels (`Dev A`, `Lead 1`, `Reviewer B`) stand in for people.

| Check | What it observes | Result | Log |
|---|---|---|---|
| A1 | Step 5a, six columns, "gates first", "add nothing", baseline sentence, one bullet per lesson 1-7, step 8 item 6, with line numbers; same patterns on the base copy; control removes the lesson-4 bullet | all 22 patterns found on the candidate; all 22 MISSING on base; control reports lesson 4 MISSING | `a1-content.log` |
| A2 | Added lines from `git diff --numstat`, total length, steps 1-9 headings | 30 added, 1 changed, file 107 to 136 lines; headings 1-9 present, plus 5a | `a2-size.log` |
| A3 | One fixed-pattern `rg -i` plus a manual proper-name look over the skill and this folder; plan file scanned apart; planted token and planted person name; generic role labels | the only pattern hits are the verb "saw" in two smoke lines; name look shows only "Daily Work" (the ledger convention) and "Claude Code" (a tool name); plan's `owner` field and this repo's own issue URL are the only plan hits (project metadata); both plants found; role labels pass | `a3-privacy-scan.log` |
| A4 smoke | Whole proposed body for three drafts plus a base replay, from the consumer entry point, read-only, nothing published | see below | `smoke-a-deploy-day.md`, `smoke-b-reread-cancels.md`, `smoke-c-no-deploy.md`, `smoke-base-replay.md` |
| A5 | Diff invariant (skill nonempty, paths limited to the allowlist); controls: synthetic `test/new-suite.sh`, empty skill diff | candidate accepted; both controls rejected (rc 1) | `a5-diff-invariant.log` |
| Route and gate | `ci-route.sh push` on the changed paths; `gh589-skill-viewer`, `path-integrity`, `pdda.sh run` | `route=docs tier=1`; 8/0 and 3/0; PDDA run: no errors (warnings pre-existing in other docs) | `route.log`, `suites-and-gate.log` |
| A6 | Delivered-revision receipt and the PR's actual base | filled in at delivery (see PR) | — |

## A4 smoke detail

Executors were fresh sub-agents (one per case), each given the skill path (the base copy for the replay) and fictional inputs, told to follow it literally and publish nothing. Each made only `Read` calls (4; 5; 4 and 4 for the two no-deploy executions; 4 for the base replay); the action counts equal the files they report opening, so no `gh`, host or write command ran. `git status --porcelain` stayed clean outside this folder. `a4-columns-order.log` is a scripted check over every captured body: column count, gate-before-support order, first section, goal header and SOP kept, and whether any run-sheet text is present.

Run history (all superseded runs are in git history; the receipts here are the last):
- Run 1 (`179e96fa0`): seven columns, support rows ahead of a later gate. Final QA round 1 called this a Blocker against "six columns, gates first". Step 5a was reworded (`352ae130b`).
- Run 2 (`11eca2dd6`): six columns and gates first, but the no-deploy body carried a "no deploy run sheet" note and the head re-check was timed at the 10:00 go-ahead instead of the 11:00 deploy. Final QA round 2 called these a Blocker and a Should. Step 5a was reworded again (`540e04421`: "otherwise add nothing (no section, question or note)"; "set for just before the deploy itself (not the earlier go-ahead)").
- Run 3 (this folder): the three skill cases re-run with new executors on the final text.

- (a) Deploy only in today's first body, with one complete gate, one gate with an owner but no time, and gates with no owner: one six-column sheet as the first section after the goal header; gate rows (staging go-ahead, deploy, check; production go-ahead, deploy, late check) before support rows (access, rehearsal, pre-deploy re-check, production re-check, config change); the owner-but-no-time gate and the no-owner gates became morning questions; the config change copied from an older checklist was marked a claim and not planned; the pre-deploy re-check is timed "just before the 11:00 deploy, not at the 10:00 go-ahead" with the reason; header, estimate and SOP intact.
- (b) Same, then a simulated guarded reread whose live body cancels the deploy: the first draft has the same six-column shape with gate rows first; the redraft from the new read has no sheet, no sheet questions and no note about a sheet; header intact.
- (c) A no-deploy day, executed twice: neither body has a run-sheet section, question or note. Execution 1 has the item-level phrase "Deployment: not planned in this ledger." on one item (same family as the base skill's "deployment unverified" labels); execution 2 has none. Both reported.
- Base replay of (a): no run sheet; the deploy gates stay as prose with OPEN markers and nothing is placed first, no pass/stop structure, no rehearsal or access rows.

Observations, not defects: the executors proposed owners and times for support rows and labelled them "proposed, to confirm", then asked about them; one executor noted the skill does not say what to do with deploy rows if the live body cancels the deploy mid-run (it dropped them, which is the intended reading of "otherwise add nothing").

Not exercised: steps 1-5's real GitHub reads, publishing, and the step-8 independent validator (they would write to or read a real ledger issue); no host read of any kind.
