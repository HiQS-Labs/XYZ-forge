# GH-1258 Phase 1 smoke and manual checks (2026-10-30)

Implementation commit: `bb25278f` on `feat/XYZ-forge-gh1258-idea-skill-2026-10-30` (base `development@e305cbf3`). Plan QA: `relay-system/2026-10-30/gh1258-plan-qa.md`, Codex, Approved round 2 (attest `6be3b534`, reviewed `b2644d6b`). No new test, suite or gate (GH-831); everything below is an existing suite, an existing CLI, or a recorded manual witness.

## Main path: one real issue filed through `skills/1-hourly/idea/SKILL.md` (standard tier, Steps 0–11)

| Step | Command (from the task clone; intake lands in the primary checkout `hq park` resolves) | Observed |
|---|---|---|
| 3 prior art | `python3 utils/py/prior_art_recon.py --query "hq park title rated token"` | PASS, 0 open PRs, 0 merged, no matching issue |
| 4 recon-lite | read-only probe: `hq_roadmap_line` piped to `parse_rating` | neutral title unrated; `rated 80/55/50/65` in the title pre-rates; `rated 5/5` refuses exit 3 |
| 6 consult | `relay-automation/consult.sh --models codex,agy --label gh-idea-A-draft` | 2 answered, 0 failed → `relay-system/2026-10-30/gh-idea-A-draft-112341`; both "ship with conditions"; 6 dispositions applied before filing |
| 6 hash | `sed '$d' body.md \| shasum -a 256` | `4fa3dc539317f5780d2db97ca762113e1ac1c593a065d5bb238e6ba6be8e7ec7` written into the footer |
| 7 preview | `bash utils/hq/hq.sh park --title … XYZ-forge "$(cat body.md)"` | preview rendered, slug `GH-<N>-HQ-PARK-RATING-GRAMMAR`, dedupe passed |
| 8 create | `… park --create …` (`hq-park-create.log`) | issue [#1263](https://github.com/HiQS-Labs/XYZ-forge/issues/1263), capture `PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md`, DB pointer added, pdda frontmatter check passed |
| 8 rate | `releases roadmap rate --issue-num 1263 --rated 55/45/50/90` (`--dry-run` first; `roadmap-rate-readback.txt`) | row `rmi-01M66T7MQJ4X82GJFTJ2SZV72S` reads back 55/45/50/90, ovr none, section "Queue / parked intake" |
| 9 dispositions | `gh issue comment 1263 --body-file …` | https://github.com/HiQS-Labs/XYZ-forge/issues/1263#issuecomment-6527841022 |
| 10 preflight | `bash utils/swarm-preflight.sh --project-doc <primary>/PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md --target-root <primary> --dry-run` (`preflight-dryrun-gh1263.log`) | `verdict: ready (exit 0)`; the uncommitted capture and ledger did not change the verdict |
| write-set witness (plan QA r2 Nit) | `git status --porcelain --ignored` before and after the intake run (`intake-before.txt`, `intake-after.txt`, `intake-writeset.diff`) | delta is exactly `M releases.db`, `M releases.sql`, `?? PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md`; the 21 pre-existing entries are unchanged |
| start-marathon Step 2 classification | table at `skills/2-daily/start-marathon/SKILL.md:174-186` | **NEEDS-PROMOTE**: open, contract exists, dry-run exit 0, still in `1-INBOX` (promotion is the operator's step, not the skill's) |

The capture, `releases.db` and `releases.sql` for #1263 are **uncommitted in the primary checkout**, as the skill's Step 11 reports; the operator commits intake.

## Adjacent paths: red controls on mutated local copies (nothing filed)

| Control | Mutation (`red-controls/*.mutated.md`) | Command | Observed |
|---|---|---|---|
| STALE | `grep_absent` pattern replaced with `possible duplicate open issue`, already present in `utils/hq/hq.sh` at `development` | same preflight dry-run on the copy (`red-controls/stale-exit4.log`) | `verdict: STALE (exit 4)`, no packet |
| NOT-READY | artifact replaced with `utils/hq/hq-title-guard.sh` (absent at `development`, not in `artifacts_new`) | same (`red-controls/notready-exit5.log`) | `verdict: NOT-READY (exit 5)`, no packet |

Acceptance item 3's STALE wording ("filed, not admission-ready") was witnessed on the copy rather than by filing a second issue with a wrong probe; the skill's Step 10 text is what an operator would see.

## Acceptance item 1: one tier folder and one index row

- `ls -d skills/*/idea` → `skills/1-hourly/idea` (exactly one).
- `grep -c '[idea](skills/1-hourly/idea/SKILL.md)' ARCHITECTURE.md` → 1; the `1-hourly` header count corrected 15 → 17 (17 folders, 17 rows).
- Red control: a scratch copy of `ARCHITECTURE.md` with the row deleted has 0 matches; nothing automated flags it. `bash test/gh660-skill-drift.sh` (synthetic fixtures) stays green: 7 pass, 0 fail. The catch is the review checklist in `skills/README.md` ("The Skills Index row is part of the change"), as the plan states.

## Description length (GH-942)

`description:` of `skills/1-hourly/idea/SKILL.md` is 754 characters (cap 1024).

## Not run here

Full gate (`validate.sh`) and the push-hook qualification run on the final approved commit in a disposable `-gate` clone and are recorded in `provenance.jsonl` when they run. Phase 2 (start-task delta re-recon) and Phase 3 (retrofit) are out of scope.
