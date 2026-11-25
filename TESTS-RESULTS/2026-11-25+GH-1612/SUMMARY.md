# GH-1612 evidence: deploy-day run sheet in `/yesterday-today`

Base `b479f74e0`. Manual checks only (no new suite, script or test, GH-831). All ledgers, PRs and people in `inputs/` and the receipt are fictional; role labels (`Dev A`, `Lead 1`, `Reviewer B`) stand in for people.

| Check | Result | Receipt |
|---|---|---|
| Smoke: one read-only fresh-executor dry run of the skill from its path on a fictional deploy-day ledger | one six-column sheet first, gate rows before support rows, every incomplete gate's missing fields asked as morning questions, rehearsal covers the timed re-check's method, timer set for the deploy, nothing published | `smoke-deploy-day.md` |
| Size | 107 to 136 lines, 30 added (`git diff --numstat b479f74e0`); steps 1-9 keep their numbers | the diff |
| Privacy | one `rg -n -i` over the skill and this folder for client, product, host, email, IP and private-link shapes: see the result line below | this file |
| Route and gate | `ci-route.sh push` gives `route=docs tier=1`; `gh589-skill-viewer` 8/0, `path-integrity` 3/0, `pdda.sh run` no errors | `route.log`, `suites-and-gate.log` |

Privacy result line: 0 matches over the skill, `smoke-deploy-day.md`, `inputs/` and the logs (SUMMARY.md excluded because it names the patterns)

## Review state (honest)

Plan QA: Approved by Codex at round 3. Final QA: three rounds (the cap), ended `Escalated`. Rounds 1 and 2 found real defects in the smoke output (layout; a no-sheet note and a mistimed recheck) and step 5a was reworded each time. Round 3 left two open: (Blocker) a gate's missing execution-method field was not always asked as a morning question; (Should) the early rehearsal covered a different method from the timed check. After the cap, one line each was added to step 5a for those two points (`SKILL.md` lines 78 and 88-89) and the smoke above was run once. **That change was not re-reviewed**; independent review did not approve the final artifact, so the PR stays a draft. Whether an extra review round is worth it is the operator's call.

Earlier, more extensive evidence (content probes with base-copy and removed-lesson controls, a privacy scan with planted controls, a path-allowlist checker, a no-deploy day run twice, a cancelling-reread run and a base replay) is in git history at `90c4bed52`; it was cut from the branch as more machinery than a 30-line prompt change needs.

Not exercised: real GitHub reads, publishing, the step 8 validator against a real ledger issue; no host read of any kind.
