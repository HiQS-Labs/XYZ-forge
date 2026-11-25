# GH-1601 evidence — `/yesterday-today`

Base `ac0e8b65b`. Manual checks only (no new suite, GH-831). Every log is in this folder. The smoke run's source repository and issue numbers are withheld on purpose; it read a real yesterday/today ledger pair in an external repository, read-only.

| Check | What it observes | Result | Log |
|---|---|---|---|
| A1 | Skill file exists, frontmatter `name`, three trigger phrases, daily-planner boundary sentence, line count; base contrast | present, 105 lines, all four found; base has no such path | `a1-a4-text.log` |
| A2 | Each of the nine requirement items maps to a line in the skill; red control removes item 7's lines | all nine OK with line numbers; red control reports item 7 missing (4 patterns) | `a2-nine-points.log` |
| A3 | One `rg -i` pattern list (client/people names, logins, email shapes, local hostnames) over the nonempty deliverables and the `ARCHITECTURE.md` diff; planted-string control | no hits; planted fictional marker detected (rc 0) | `a3-privacy-scan.log` |
| A4 | Index row: first cell and nonempty purpose cell; `gh589-skill-viewer`, `path-integrity` | row present (base: 0 matches); 8/0 and 3/0 | `a1-a4-text.log`, `suites-and-gate.log` |
| A5 smoke | Steps 1-2 from the consumer entry point, read-only, against a real ledger pair | see below | `smoke-steps1-2.log` |
| A6 | Diff invariant on the nonempty candidate diff; red controls (synthetic `test/new-suite.sh`, empty diff) | candidate passes (rc 0); both controls rejected (rc 1) | `a6-diff-invariant.log` |
| Route and gate | `utils/ci-route.sh push` on the changed paths; `utils/pdda/pdda.sh run` | `route=docs tier=1`; PDDA run: no errors (warnings pre-existing in other docs) | `route.log`, `suites-and-gate.log` |

## A5 smoke detail

The receipt (`smoke-steps1-2.log`) is one run, in order: the skill read through this clone's path; step 1 for today (Wednesday) and yesterday (the latest working day before it, Tuesday) against a real ledger pair in an external repository, where the `Daily Work Ledger` title search returned a confirmed empty result and the team's own title convention matched exactly one issue for each date; step 2 reading yesterday's body and 10 comments and counting 10 checked and 34 unchecked boxes (the claims the skill would verify next).

Adjacent paths. (A) A simulated today with no ledger: the title search succeeded with no matches, so the skill's printed stop is "confirmed absent, offer to create, nothing written". (B) A failed lookup (a repository that does not exist): `gh` exits nonzero, so the skill reports "unavailable", stops before drafting and makes no creation offer. The stop lines are what the skill directs an agent to print; the receipt records the observed command results that select them. Zero-write: only `gh issue list` and `gh issue view` ran, and the only path changed in the checkout was the receipt file.

Not exercised: steps 3-9 (they need a real ledger update and the independent validator, which would write to an external issue); the Slack read (the skill says to state it was not checked).
