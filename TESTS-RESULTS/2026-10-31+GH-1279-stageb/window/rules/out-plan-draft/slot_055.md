# Plan draft: #1258 idea skill (was file-issue): recon + debug-mantra plan in the GitHub issue at filing time, so issues enter the flywheel admissible (dogfood plan; ledger row at pickup)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1258-a0b2f5b0dd7f` (tick `slot_055`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: a0b2f5b0dd7fdfa869a288f15551c4510c865d7b847dc8f31dbe12bf112f5b75 (updated 2026-10-30T16:18:43Z)
- Dependencies: none

## Scope

_Source: issue#1258:L1 (Outcome)_

An `idea` skill (`skills/1-hourly/idea`; the `/idea` front door that `hq park`, `file-xyz-bug` and `PROJECT/PDDA.md` already name but nobody built; drafted under the working name `file-issue`, settled as `idea` in D1) that produces, at filing time, grounded, provisionally rated intake that satisfies #522's "plan substance" gate: a plan in the GitHub issue, grounded by recon and debug-mantra while the context is fresh, with a PRS proposal and a Preflight Contract stub. Admission stays #522's decision; PDDA already holds `ratings_provisional` captures out of auto-selection (PDDA.md:161-165), so this skill makes issues *admission-ready*, not admitted. The reconciler of #1175 then pays only a delta re-recon at entry instead of the full recon + plan + plan-QA that `start-task` Steps 4–6 pay today inside every lane.

This issue is written the way the skill would write one. It records design and an implementation plan; creating it authorizes no implementation, no ledger write, no dispatch. **The ledger row is deliberately not added yet** (operator decision 2026-10-29); `releases roadmap add` happens when the work is picked up.

## Acceptance criteria

_Source: issue#1258:L103 (Acceptance            `- [ ]` checkbox items only (swarm_preflight.py:509 reads nothing else); each names its red)_

control and where the evidence lands; none satisfiable by an empty input

_Source: issue#1258:L139 (Acceptance)_

- [ ] `ls -d skills/*/idea` resolves to exactly one tier folder and `ARCHITECTURE.md` has its row. Red control (manual, recorded): delete the index row in a scratch copy and confirm the review checklist in `skills/README.md` ("The Skills Index row is part of the change") is what catches it; `test/gh660-skill-drift.sh` runs on synthetic fixtures (`test/gh660-skill-drift.sh:10-19`) and is only required to stay green.
- [ ] An issue filed through the skill carries every section of the body contract with non-empty content: the four core regexes hit, `## Acceptance` yields ≥ 1 `- [ ]` item through `swarm_preflight.py`'s extractor, and the footer has `Recon: <sha>` and `base: development@<sha>`. Red control (manual, recorded under `TESTS-RESULTS/`): a body of eleven empty headings plus footer must be refused by the skill's preview step, not filed.
- [ ] `swarm-preflight --dry-run` on the capture doc the skill produced exits 0 (READY). Red control: filing with a probe already satisfied at `target.ref` makes the skill stop with the STALE verdict and reason in its output and report **filed, not admission-ready**, naming the issue, capture doc and ledger row that `hq park --create` already wrote (nothing admitted, nothing rolled back); a new-file artifact missing from `artifacts_new` makes it stop with NOT-READY (witnessed manually, recorded).
- [ ] `start-marathon` Step 2 classifies the new issue READY or NEEDS-PROMOTE (presence of capture + contract in `1-INBOX`; not admission), neve

## Open questions

_Source: issue#1258:L62 (Unknowns)_

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Who is the trusted reviewer for #522 "independent review" | decides whether a filing-time consult counts as review or only as a draft review | operator decision on #522; this plan records the consult + hash and leaves "reviewed" to #522 |
| ~~Does `hq park` need the plan body in the capture doc too~~ settled by recon: `hq_render_capture` embeds `$request` verbatim, so issue and doc carry the same plan and contract | #522 needs the plan **in the issue**; PDDA wants the doc to carry actionable substance; both hold with one body | Issue = plan of record; doc = verbatim copy (not a pointer) that the contract parser and acceptance extractor read. A later edit to the issue body does not propagate to the doc: the skill states this and the PDDA issue-doc sync check already flags drift |
| Retrofit batch size the rater can absorb | 281 existing issues will not benefit otherwise | E1-style batches under #1022/#1177, operator-approved |

## Write set

- `PROJECT/PDDA.md` (issue#1258:L3)
- `skills/1-hourly/start-task/SKILL.md` (issue#1258:L14)
- `utils/hq/hq.sh` (issue#1258:L15)
- `utils/hq/hq-lib.sh` (issue#1258:L15)
- `utils/py/releases_app.py` (issue#1258:L15)
- `utils/py/prior_art_recon.py` (issue#1258:L19)
- `utils/py/swarm_preflight.py` (issue#1258:L22)
- `skills/2-daily/hq/find-hq.sh` (issue#1258:L29)
- `relay-automation/CONTRACT.example.md` (issue#1258:L37)
- `utils/py/jog_run.py` (issue#1258:L37)
- `utils/pdda/pdda.sh` (issue#1258:L38)
- `skills/1-hourly/recon/SKILL.md` (issue#1258:L42)
- `skills/README.md` (issue#1258:L44)
- `test/gh660-skill-drift.sh` (issue#1258:L44)
- `ARCHITECTURE.md` (issue#1258:L44)
- `skills/3-weekly/skills-army-hq/scripts/intake.py` (issue#1258:L44)
- `MACHINE-CONTRACTS.md` (issue#1258:L55)
- `releases.sql` (issue#1258:L127)
- `AGENTS.md` (issue#1258:L127)
- `validate.sh` (issue#1258:L148)
- `test/skills-army-hq.sh` (issue#1258:L152)
- `skills/3-weekly/skills-army-hq/scripts/sync.py` (issue#1258:L170)
- `skills/2-daily/hq/SKILL.md` (issue#1258:L170)
- `skills/2-daily/file-xyz-bug/SKILL.md` (issue#1258:L170)

## Unresolved file names

- `hq.sh` (issue#1258:L15; 2 tracked files share this name)
- `SKILL.md` (issue#1258:L133; 77 tracked files share this name)
- `consult.sh` (issue#1258:L171; 2 tracked files share this name)

## Contract probes

- none
