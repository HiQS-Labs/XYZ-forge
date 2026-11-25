# GH-1601 evidence — `/yesterday-today`

Base `ac0e8b65b`. Manual checks only (no new suite, GH-831). Every log is in this folder. The smoke run's source repository and issue numbers are withheld on purpose; it read a real yesterday/today ledger pair in an external repository, read-only.

| Check | What it observes | Result | Log |
|---|---|---|---|
| A1 | Skill file exists, frontmatter `name`, three trigger phrases, daily-planner boundary sentence, line count; base contrast | present, 105 lines, all four found; base has no such path | `a1-a4-text.log` |
| A2 | Each of the nine requirement items maps to a line in the skill; red control removes item 7's lines | all nine OK with line numbers; red control reports item 7 missing (4 patterns) | `a2-nine-points.log` |
| A3 | One `rg -i` pattern list (client/people names, logins, email shapes, local hostnames) over the nonempty deliverables and the `ARCHITECTURE.md` diff; planted-string control | no hits; planted `BinoidCBD`-style string detected (rc 0) | `a3-privacy-scan.log` |
| A4 | Index row: first cell and nonempty purpose cell; `gh589-skill-viewer`, `path-integrity` | row present (base: 0 matches); 8/0 and 3/0 | `a1-a4-text.log`, `suites-and-gate.log` |
| A5 smoke | Steps 1-2 from the consumer entry point, read-only, against a real ledger pair | see below | `smoke-steps1-2.log` |
| A6 | Diff invariant on the nonempty candidate diff; red controls (synthetic `test/new-suite.sh`, empty diff) | candidate passes (rc 0); both controls rejected (rc 1) | `a6-diff-invariant.log` |
| Route and gate | `utils/ci-route.sh push` on the changed paths; `utils/pdda/pdda.sh run` | `route=docs tier=1`; PDDA run: no errors (warnings pre-existing in other docs) | `route.log`, `suites-and-gate.log` |

## A5 smoke detail

Main path. Today resolved to Wednesday, yesterday to Tuesday (the latest working day before today). The `Daily Work Ledger` title search returned `[]` (rc 0, a confirmed empty result), so the skill's step 1 falls back to the team's own title convention and the ledger's weekly links; the `Planned Work Ledger` search returned the week's ledgers. Step 2 read yesterday's body and 10 comments and counted 10 checked and 34 unchecked boxes, each of which the skill treats as a claim.

Adjacent path. Simulated **today** = Thursday 2026-12-31, a date with no ledger. The title search succeeded with `[]` (rc 0): confirmed absent, so step 1 would stop and offer to create the ledger. The lookup did not fail (rc 0), which is the difference from "unavailable". The command log contains only `gh issue list` and `gh issue view` reads; no `gh issue edit` or `create` ran, and `git status` outside this folder shows only the task's own changes.

Not exercised: steps 3-9 (they need a live ledger update and the independent validator, which would write to an external issue); the Slack read (no connector used, per the skill "say it was not checked").
