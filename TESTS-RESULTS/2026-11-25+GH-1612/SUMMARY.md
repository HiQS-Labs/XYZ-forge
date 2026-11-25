# GH-1612 evidence — deploy-day run sheet in `/yesterday-today`

Base `b479f74e0`, tested commit `71b641f28` (the skill text itself is unchanged since `352ae130b`). Manual checks only (no new suite, GH-831). All ledgers, PRs and people in `inputs/` and the smoke files are fictional; role labels (`Dev A`, `Lead 1`, `Reviewer B`) stand in for people.

| Check | What it observes | Result | Log |
|---|---|---|---|
| A1 | Step 5a, six columns, "gates first", "add nothing", baseline sentence, one bullet per lesson 1-7, step 8 item 6, with line numbers; same patterns on the base copy; control removes the lesson-4 bullet | all 21 patterns found on the candidate; all 21 MISSING on base; control reports lesson 4 MISSING | `a1-content.log` |
| A2 | Added lines from `git diff --numstat`, total length, steps 1-9 headings | 30 added, 1 changed, file 107 to 136 lines; headings 1-9 present, plus 5a | `a2-size.log` |
| A3 | One fixed-pattern `rg -i` plus a manual proper-name look over the skill and this folder; plan file scanned apart; planted token and planted person name; generic role labels | 0 pattern hits; name look shows only "Daily Work" (the ledger convention) and "Claude Code" (a tool name); plan's `owner` field and this repo's own issue URL are the only plan hits (project metadata); both plants found; role labels pass | `a3-privacy-scan.log` |
| A4 smoke | Whole proposed body for three drafts plus a base replay, from the consumer entry point, read-only, nothing published | see below | `smoke-a-deploy-day.md`, `smoke-b-reread-cancels.md`, `smoke-c-no-deploy.md`, `smoke-base-replay.md` |
| A5 | Diff invariant (skill nonempty, paths limited to the allowlist); controls: synthetic `test/new-suite.sh`, empty skill diff | candidate accepted; both controls rejected (rc 1) | `a5-diff-invariant.log` |
| Route and gate | `ci-route.sh push` on the changed paths; `gh589-skill-viewer`, `path-integrity`, `pdda.sh run` | `route=docs tier=1`; 8/0 and 3/0; PDDA run: no errors (warnings pre-existing in other docs) | `route.log`, `suites-and-gate.log` |
| A6 | Delivered-revision receipt and the PR's actual base | filled in at delivery (see PR) | — |

## A4 smoke detail

Executors were fresh sub-agents (one per case), each given the skill path (the base copy for the replay) and fictional inputs, told to follow it literally and publish nothing. Each made only `Read` calls (4, 5 plus one `ls`, 4, and 4 for the base replay); the action counts equal the files they report opening, so no `gh`, host or write command ran. `git status --porcelain` stayed clean outside this folder.

Run history. Run 1 (commit `a0e59c02d`, receipts at `179e96fa0`) used a seven-column table and ordered rows chronologically, so a rehearsal and a config step sat ahead of the production go-ahead. Codex final QA round 1 called that a Blocker against "six columns, gates first". Step 5a was reworded (commit `352ae130b`: "six columns ... Gate rows first (go-ahead, deploy, after-deploy checks), then support rows (access, rehearsal, config), each in time order") and the three skill cases were re-run with new executors; the receipts in this folder are run 2. `a4-columns-order.log` measures column count and row order on the receipts.

- (a) Deploy only in today's first body, with one complete gate, one gate with an owner but no time, and gates with no owner: one six-column sheet directly after the goal header; rows G1-G6 (gates) before S1-S3 (access check, rehearsal, config change); the owner-but-no-time gate (G3) and the no-owner gates (G4-G6) became morning questions Q1-Q4; the config change copied from an older checklist was marked a claim and not planned; the rehearsal and access check were their own rows; timers on the go-ahead checks say why; pass cells name what must be seen; header, estimate and SOP intact.
- (b) Same, then a simulated guarded reread whose live body cancels the deploy: the first draft had the same six-column shape; the executor redrafted from the new read and the final body has no sheet and no sheet questions; header intact; the cancelled deploy's gaps were kept as a parked item.
- (c) A no-deploy day: no run sheet and no gate questions. The draft carries one note line, "No deploy is planned today, so there is no deploy run sheet", under a "checked and not checked" heading; that is a statement, not a sheet.
- Base replay of (a): no run sheet; the deploy gates stay as prose with OPEN markers and nothing is placed first, no pass/stop structure, no rehearsal or access rows.

Observation, not a defect: the executor in (a) and (b) proposed owners and times for the support rows (S1, S2) and labelled them "proposed; confirm", then asked about them; the skill does not forbid a suggestion, only an unplanned gate carried as prose.

Not exercised: steps 1-5's real GitHub reads, publishing, and the step-8 independent validator (they would write to or read a real ledger issue); no host read of any kind.
