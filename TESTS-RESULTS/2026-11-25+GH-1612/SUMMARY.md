# GH-1612 evidence — deploy-day run sheet in `/yesterday-today`

Base `b479f74e0`, tested commit `a0e59c02d`. Manual checks only (no new suite, GH-831). All ledgers, PRs and people in `inputs/` and the smoke files are fictional; role labels (`Dev A`, `Lead 1`, `Reviewer B`) stand in for people.

| Check | What it observes | Result | Log |
|---|---|---|---|
| A1 | Step 5a, six columns, "gates first", "add nothing", baseline sentence, one bullet per lesson 1-7, step 8 item 6, with line numbers; same patterns on the base copy; control removes the lesson-4 bullet | all 19 patterns found on the candidate; all 19 MISSING on base; control reports lesson 4 MISSING | `a1-content.log` |
| A2 | Added lines from `git diff --numstat`, total length, steps 1-9 headings | 30 added, 1 changed, file 107 to 136 lines; headings 1-9 present, plus 5a | `a2-size.log` |
| A3 | One fixed-pattern `rg -i` plus a manual proper-name look over the skill and this folder; plan file scanned apart; planted token and planted person name; generic role labels | 0 pattern hits; name look shows only the generic term "Daily Work" (the ledger convention); plan's `owner` field and this repo's own issue URL are the only plan hits (project metadata); both plants found; role labels pass | `a3-privacy-scan.log` |
| A4 smoke | Whole proposed body for three drafts plus a base replay, from the consumer entry point, read-only, nothing published | see below | `smoke-a-deploy-day.md`, `smoke-b-reread-cancels.md`, `smoke-c-no-deploy.md`, `smoke-base-replay.md` |
| A5 | Diff invariant (skill nonempty, paths limited to the allowlist); controls: synthetic `test/new-suite.sh`, empty skill diff | candidate accepted (5 paths); both controls rejected (rc 1) | `a5-diff-invariant.log` |
| Route and gate | `ci-route.sh push` on the changed paths; `gh589-skill-viewer`, `path-integrity`, `pdda.sh run` | `route=docs tier=1`; 8/0 and 3/0; PDDA run: no errors (warnings pre-existing in other docs) | `route.log`, `suites-and-gate.log` |
| A6 | Delivered-revision receipt and the PR's actual base | filled in at delivery (see PR) | — |

## A4 smoke detail

Executors were four fresh sub-agents, each given the skill path (the base copy for the replay) and fictional inputs, told to follow it literally and publish nothing. Each made only `Read` calls (4, 5, 4 and 4); the action counts equal the files they report opening, so no `gh`, host or write command ran. `git status --porcelain` stayed clean outside this folder.

- (a) Deploy only in today's first body, with one complete gate, one gate with an owner but no time, and gates with no owner: one six-column sheet (plus a `#` column) directly after the goal header; the owner-but-no-time gate and the no-owner gates became morning questions 1-4; the config change copied from an older checklist was marked a claim and not planned; the rehearsal and a pre-deploy re-check with a timer were their own rows; pass cells name what must be seen (a build id and a count of sample orders); header, estimate and SOP intact.
- (b) Same, then a simulated guarded reread whose live body cancels the deploy: the executor redrafted from the new read and the final body has no sheet and no sheet questions; header intact; the cancelled deploy's gaps were kept as a parked item.
- (c) A no-deploy day: zero run-sheet output.
- Base replay of (a): no run sheet; the deploy gates stay as prose with OPEN markers and nothing is placed first, no pass/stop structure, no rehearsal or access rows.

Observations, not defects: the executor in (a) ordered the rows chronologically, so the production go-ahead is row 7, not among the first rows; the skill line "gates first (go-ahead, deploy, after-deploy checks)" lists the three gate kinds and does not say "all go-ahead rows before any deploy row". The executor in (a) also proposed an owner ("Dev A, to confirm") for one row; it still marked the row not planned and asked the question.

Not exercised: steps 1-5's real GitHub reads, publishing, and the step-8 independent validator (they would write to or read a real ledger issue); no host read of any kind.
