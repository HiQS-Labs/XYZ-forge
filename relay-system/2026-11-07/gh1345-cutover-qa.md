# RELAY · GH-1345 review: cutover, rows at pickup (Tasks 2, 3, 4, 6, 11, 5, 12)
<!--
  Single source of truth for this review relay thread.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## Setup
- Artifacts under review:
  1. `utils/hq/hq.sh`
  2. `utils/pdda/pdda.sh`
  3. `utils/py/releases_app.py`
  4. `utils/py/harness.py`
  5. `utils/py/express.py`
  6. `utils/py/jog_run.py`
  7. `skills/1-hourly/idea/SKILL.md`
  8. `skills/1-hourly/start-task/SKILL.md`
  9. `skills/2-daily/file-xyz-bug/SKILL.md`
  10. `skills/2-daily/hq/SKILL.md`
  11. `skills/2-daily/jog/SKILL.md`
  12. `skills/2-daily/start-marathon/SKILL.md`
  13. `skills/2-daily/workhorse/SKILL.md`
  14. `skills/3-weekly/10days/SKILL.md`
  15. `AGENTS.md`
  16. `PROJECT/PDDA.md`
  17. `ROUTER.md`
  18. `CHANGELOG.md`
- Base commit: `5f6ef0db` (development tip after PR #1350)
- Change under review: `git diff 5f6ef0db..HEAD` (+560/-164 lines across 20 files)

## Log

### Reviewer · Round 1

swept file: yes

#### Findings

1. **[Pass] Task 2: Filing paths stop creating ledger rows; inbox coverage passes without row (`utils/hq/hq.sh:440-470`, `utils/pdda/pdda.sh:405-425`).**
   - Verified `hq park --create` under `ROADMAP_SOURCE=releases` defers row creation to pickup (`✓ ledger:  row creation deferred to pickup (decision 6)`).
   - Verified `test/gh238-hq-releases-mode.sh` passes 100% and checks `SELECT COUNT(*) FROM roadmap_items == 0` after filing.
   - Verified `utils/pdda/pdda.sh` passes unstarted `PROJECT/1-INBOX/GH-*.md` captures without a ledger pointer as `INFO [pdda-check-roadmap-coverage] ... (deferred-pickup)`.
   - Verified active `PROJECT/2-WORKING/` doc without a row fails with `ERROR [pdda-check-roadmap-coverage] ... (rc=1)` (falsification confirmed).

2. **[Pass] Task 3 & Task 11: Idempotent pickup writer and rating contract (`utils/py/releases_app.py:3325-3450, 4120-4200`).**
   - Verified `cmd_roadmap_pickup`:
     - Creates row exactly once with 4-axis rating on 1–100 scale.
     - Refuses placeholder ratings (`50/50/50/50` or all <= 5) with `rc=3`.
     - Preserves existing ratings and operator `ovr` across repeat invocations.
     - Grandfathered rows (D-a) are preserved and repointed cleanly.
   - Verified integration in `express.py` (hotfix rating 70/60/50/85), `jog_run.py` promotion fallback, and start skills (`start-task`, `jog`, `start-marathon`, `10days`, `workhorse`).
   - Verified `test/gh267-express-skill.sh` passes 126/126.

3. **[Pass] Task 4: Readiness and factory discovery of unstarted no-row issues (`utils/py/harness.py:482-550, 950-1010`).**
   - Verified `_unregistered_record` evaluates capture doc, Preflight Contract artifacts/writeset/zone, and PRS proposals.
   - Promotes fully specified unstarted issues to `state = "ready"` and `section = "Queue / parked intake"`, setting `dbRank` from the proposal.
   - Verified `init_from_prs` discovers open unstarted issues without rows, excluding `umbrella` labeled containers, and pools them by priority rank.

4. **[Pass] Task 6: Duplicate guards intact (`utils/hq/hq.sh:400-410, 444-455`).**
   - Verified `hq park --create` searches open issues before filing.
   - Verified `hq park --gh-issue` reuses existing capture doc (`reusing existing capture`) when present.
   - Verified `UNIQUE(repo_id, gh_number)` constraint enforced at pickup in `releases.db`.

5. **[Pass] Task 12: Standard issue sections and umbrella handling (`utils/hq/hq.sh:340-360, 410-435`, `skills/2-daily/file-xyz-bug/SKILL.md:83-115`).**
   - Verified `hq park --create` emits standard `/idea` sections: `## Observed`, `## Acceptance`, `## Preflight Contract`, `## PRS proposal`.
   - Verified `/file-xyz-bug` specifies rendering the same standard sections and tags multiphase containers with `umbrella`.
   - Verified `harness.py` excludes `umbrella` issues from atomic intake counts.

6. **[Pass] Task 5: Backlog rollout guidance (`PROJECT/1-INBOX/GH-1345-CUTOVER-ROWS-AT-PICKUP.md`).**
   - Verified #1298 supply step instructions documented: prepare issue text, capture doc, and contract only, creating zero rows at intake.

7. **[Pass] Rails & Gates (`AGENTS.md`, `test/gh308-frozen-twin-guard.sh`).**
   - No new test suites added (GH-831 rail satisfied).
   - Frozen twin guard passed: zero frozen bash twins modified, zero new bash scripts added.
   - All covering regression suites passed: `test/gh238-hq-releases-mode.sh`, `test/hq-park.sh` (23/23), `test/hq-park-synthesis.sh` (35/35), `test/gh267-express-skill.sh` (126/126), `test/gh174-harness-registry.sh` (8/8), `releases_app.py check`, `pdda.sh roadmap-coverage`, and `pdda.sh run` (0 errors).

VERDICT: PASS
Basis: All acceptance criteria from Issue #1345 are satisfied, validated by covering suites and falsification controls, and conformant with repo rails.
STATUS: Approved
