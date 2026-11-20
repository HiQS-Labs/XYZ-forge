# Relay: GH-1551 (KS-07) Plan QA — Long Operations Cannot Run in the Foreground

STATUS: Approved
NEXT: Done
ROUND: 2 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1551-ks07-bg-long-ops-2026-11-20
ISSUE: #1551
ROADMAP_ID: rmi-01M7W39TSPD8DMM0575S9FDM8Z
CANDIDATE_SHA: 2288337c5b1ee6377d3d1ea0689328b455609b2e

## Producer Round 1 — Plan QA Submission

Please review `PROJECT/2-WORKING/GH-1551-KS07-BG-LONG-OPS.md` against issue #1541 (KS-07, U7, U8) and `skills/1-hourly/kickstart/SKILL.md`.

Key points:
- Pure runbook rule in `skills/1-hourly/kickstart/SKILL.md` (zero new guard/runner/wrapper per KS-07).
- Mandates host-native background execution + completion notification for `merge-cleanup --execute` and full gates; unsupported host halts via Transition 3 rather than foreground fallback.
- Paired real >10-min (`605s`) red/green probe (600s foreground timeout kill vs 605s host-native background completion) plus honest U7 (run-2 >10-min single-consumption check remains uncredited until run 2) and U8 boundaries.

If the plan is sound, set `STATUS: Approved` and `NEXT: Done`.


## Reviewer Round 1 — codex

**Block — two bounded plan corrections required.** The core instruction change matches #1551 and #1541 KS-07: host-native background launch and completion notification, no new runner, unsupported-host hold, and U7 credit explicitly deferred until real run 2. This is an Easy, reversible runbook change; its practical failure boundary is host capability, already covered by Transition 3. No implementation or live-run acceptance is approved here.

1. **[Must] Remove unconditional task-branch CHANGELOG writing.** `PROJECT/2-WORKING/GH-1551-KS07-BG-LONG-OPS.md:26` requires updating `CHANGELOG.md`, contrary to `ROUTER.md` and `PROJECT/PDDA.md:462-465`: default `off` and opt-in `landing` both forbid PR-branch entries; only explicit legacy `branch` permits them. Replace step 2 with honoring the configured mode (no branch edit under off/landing). Do not introduce a config change to satisfy this step. This avoids reintroducing the serial changelog conflicts the current policy removes.
2. **[Must] Make the seeded active plan satisfy its promised PDDA gate.** The complete 34-line plan has no `updated`, `owner`, or `goal` frontmatter and no near-top `## Status` table. `PROJECT/PDDA.md` Required contract for active docs requires all four. Add the missing fields and exact `What was just completed | What's next` table before implementation; otherwise the plan's own zero-error PDDA acceptance is not ready to pass. No new phase structure is needed.

Evidence: read-only `gh issue view 1541 --repo HiQS-Labs/XYZ-forge --json body` and corresponding `1551` query exited 0; decisive text requires the host-supported background/completion mechanism, paired >10-minute control, U7 real-run single consumption, and U8 no manufactured production incidents. `nl -ba PROJECT/2-WORKING/GH-1551-KS07-BG-LONG-OPS.md` exited 0 and showed step 2 at line 26 and the missing required metadata/status table across lines 1–34. `rg -n "CHANGELOG_WRITES|landing|branch" PROJECT/PDDA.md` exited 0 and confirmed the mode policy at lines 462–465. These are source/document observations, not an executed PDDA gate result.

Verification limits: no phase gate command is configured in this relay, so no validate/test/pytest/fixture or PDDA execution was performed. The 605-second paired probe is planned evidence, not observed evidence; implementation QA must inspect actual native launch/completion receipts, command, exit status, nonempty artifacts, and limitations. Do not call an artificial timeout on a dummy workload a replay of the actual landing entry point; label the controlled mechanism check precisely. U7 and capability publication credit remain outstanding as stated. Graph project inventory was consulted; this review uses exact Markdown and issue contents, not structural code or exhaustive graph claims. Only this relay file was edited; no git commands were run.

STATUS remains Open. NEXT is antigravity to revise the plan and resubmit.

## Producer Round 2 — Revisions Applied

Updated `PROJECT/2-WORKING/GH-1551-KS07-BG-LONG-OPS.md` at `1379c598bf4e`:
1. Removed unconditional `CHANGELOG.md` task-branch edit; plan now honors configured `CHANGELOG_WRITES` mode (`PROJECT/PDDA.md:462-465`, no PR-branch edit under `off`/`landing`).
2. Added required PDDA active-doc frontmatter (`owner`, `goal`, `updated`) and near-top `## Status` table (`What was just completed | What's next`).
3. Labeled the 605-second paired probe precisely as a controlled foreground-timeout vs host-native-background mechanism check (not a replay of the production landing entry point) with U7 real-run acceptance explicitly deferred.

Please re-review and set `STATUS: Approved` and `NEXT: Done` if ready.


## Reviewer Round 2 — codex

**Approved — plan QA only.** Both Round 1 blockers are resolved in the seeded plan. Its frontmatter now includes `owner`, `goal`, and `updated`, and its near-top `## Status` table uses the required exact columns. Plan step 2 honors the configured `CHANGELOG_WRITES` mode without introducing a configuration change. Step 3 now explicitly calls the synthetic 605s pair a controlled mechanism check, not a production-entry-point replay; U7 credit remains deferred until a real run-2 >10-minute operation completes through native background execution and its result is consumed exactly once.

The bet remains Easy and reversible: a concise instruction in the existing child contract, with no new execution subsystem. The intended rejection is explicit: foreground launch of the named long operations is forbidden, and missing host capability must hold via Transition 3. The paired red/green mechanism evidence and source walkthrough are planned checks of that contract; they do not by themselves certify real-run U7 acceptance. No further plan correction is required.

Evidence: `cat PROJECT/2-WORKING/GH-1551-KS07-BG-LONG-OPS.md` exited 0 and showed the corrected metadata/status table, mode-aware step 2, and precisely scoped mechanism probe. Source reads of `skills/1-hourly/kickstart/SKILL.md` and `PROJECT/PDDA.md` confirmed the child contract and active-doc/CHANGELOG policies. Fresh `gh issue view 1551 --repo HiQS-Labs/XYZ-forge --json body` and the corresponding 1541 query each exited 1 with `error connecting to api.github.com`; live issue revalidation was unavailable, so this round relies on the issue evidence retained in Round 1 and the seeded plan, not a fresh remote assertion. Graph inventory was consulted; this is a direct Markdown review with no structural code or graph-completeness claim.

Verification limits: no phase gate is configured here, and no validate/test/pytest/fixture or PDDA gate ran. Implementation, actual 605s launch/completion receipts, nonempty provenance artifacts, PDDA execution, and real-run U7 acceptance remain for their stated later checks. Approval does not assume a later automatic gate will run. Only this relay file was edited; no git commands were run.

### Attestation · relay-drive — 2026-11-20T09:10:40Z
task: RELAY-PLAN-QA
reviewer: codex
status: Approved
reviewed-head: e6f8770a2178c180a90f659c0e647203c2dc9cdf
added-range: 4844+2238
added-sha256: c2c7250167d87d3cff4fbc584fa4f573318838e1d547d734a93b27a1bf55127e
gate-run: undeclared
