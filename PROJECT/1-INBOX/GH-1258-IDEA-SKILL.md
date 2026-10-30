---
gh_issue: 1258
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1258
title: "idea skill (was file-issue): recon + debug-mantra plan in the GitHub issue at filing time, so issues enter the flywheel admissible (dogfood plan; ledger row at pickup)"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: unassigned
doc_type: feedback
complexity: 3
risk: 2
effort: 3
phases: 3
ratings_provisional: true
non_goals:
  - no code under utils/
  - no new tests (GH-831)
  - no ledger auto-admission (#522 decides)
  - no retrofit of the 281 backlog in Phase 1
related:
  - #1175
  - #522
  - #1177
  - #1176
goal: >
  Phase 1 done = skills/1-hourly/idea/SKILL.md exists with its ARCHITECTURE.md row, and one real
  issue filed through it passes swarm-preflight --dry-run with exit 0 (Acceptance in the embedded plan).
---

## Key concepts

- idea skill (skills/1-hourly/idea)
- hq park --create as the only writer
- releases roadmap rate after park
- body contract with checkbox Acceptance + Preflight Contract
- filing-time consult = draft review only (D2)
- delta re-recon at pickup

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# idea skill (was file-issue): recon + debug-mantra plan in the GitHub issue at filing time, so issues enter the flywheel admissible (dogfood plan; ledger row at pickup)

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Outcome

An `idea` skill (`skills/1-hourly/idea`; the `/idea` front door that `hq park`, `file-xyz-bug` and `PROJECT/PDDA.md` already name but nobody built; drafted under the working name `file-issue`, settled as `idea` in D1) that produces, at filing time, grounded, provisionally rated intake that satisfies #522's "plan substance" gate: a plan in the GitHub issue, grounded by recon and debug-mantra while the context is fresh, with a PRS proposal and a Preflight Contract stub. Admission stays #522's decision; PDDA already holds `ratings_provisional` captures out of auto-selection (PDDA.md:161-165), so this skill makes issues *admission-ready*, not admitted. The reconciler of #1175 then pays only a delta re-recon at entry instead of the full recon + plan + plan-QA that `start-task` Steps 4–6 pay today inside every lane.

This issue is written the way the skill would write one. It records design and an implementation plan; creating it authorizes no implementation, no ledger write, no dispatch. **The ledger row is deliberately not added yet** (operator decision 2026-10-29); `releases roadmap add` happens when the work is picked up.

## Observed (measured 2026-10-29, `development` `2fc3f0be`)

| Claim | Command / source | Observed |
|---|---|---|
| Intake is the flywheel's bottleneck | #1175 Phase 0 step 6 (2026-10-27) | 0 admissible of 281 open; 204 (73%) no ledger row; 64 no contract; 7 of 11 contracted were STALE |
| The one "ready" issue was still not admissible | #1175 step 6, #670 | plan step adds a test (GH-831), no `## Acceptance`, no independent plan review |
| Open issues carrying the #522 plan sections | `gh issue list --state open --limit 300` + regex over bodies | 281 open · `## Acceptance` 90 · plan/remedy section 31 · observed/repro 71 · `## Non-goals` 34 · risk/rollback 5 · rating in body 19 · **all four core sections 2** |
| Where plan work is paid today | `skills/1-hourly/start-task/SKILL.md` Steps 4–6 | recon, surgical plan and Codex relay plan QA are run per issue when `start-task` picks it up, i.e. at execution time, not at filing time |
| What `hq park` writes | `utils/hq/hq.sh:224` `cmd_park`; create path `hq.sh:314-339`; `hq-lib.sh:423` `hq_render_capture` | `gh issue create --body "$request"` (`hq.sh:314`), then the capture doc with the **same `$request` embedded verbatim under `## Idea`** (`hq-lib.sh:492-494`) plus TODO stubs, then `releases roadmap add --raw-text "$(hq_roadmap_line …)"` (`hq.sh:339`). `hq_roadmap_line` carries **no `rated` token** (`hq-lib.sh:554-557`), so a rating in the body never reaches `parse_rating`. Judgment fields only via `HQ_PARK_WHY/KEY_CONCEPTS/NON_GOALS/RELATED/COMPLEXITY/RISK/EFFORT/PHASES` env |
| The `/idea` skill is referenced, not built | `grep -rn "/idea"` skills, PDDA.md:162; `ls ~/.claude/skills`, all repos' `skills/**/SKILL.md` | 3 references (hq, file-xyz-bug, PDDA.md "auto-drafted intake (e.g. the `/idea` skill) ships best-guess ratings marked provisional"); no `idea`, `triage`, `intake` or `file-issue` skill exists on this device |
| #522 expects an upstream producer | #522 body, "Plan substance" row | "Recon/debug-mantra/workhorse can produce this upstream; the monitor consumes it." The monitor "may report `NEEDS-PLAN`; it must not draft the missing plan" |
| Spike entry cost for one hand-picked issue | `TESTS-RESULTS/2026-10-25+GH-1175-phase0/SUMMARY.md` stage table | survey + intake ≈ 6 min agent, 1 operator touch (pick + scope); scope narrowing and a contract rewrite were needed; promotion park on first run (#1232, now fixed) |
| Prior art scan | `python3 utils/py/prior_art_recon.py --query "issue intake plan skill" --since-days 60` | no matching roadmap item, no matching helper; related open work #1022 (weekly intake/registration), PR #1024, #885 (fast lane), #1008 |
| Section-count survey receipt | regex over `gh issue list --state open --limit 300 --json number,body` bodies: `^##+\s*Acceptance`, `^##+\s*(Plan\|Proposed remedy\|Remedy\|Light plan\|Implementation\|Phases?)\b`, `^##+\s*(Observed\|Repro\|Reproduc\|Problem\|Symptom)`, `^##+\s*Non-goals`, `^##+\s*(Risk\|Rollback)`, `rated\s+\d+/\d+/\d+/\d+` | counts in the row above; the raw list is in this issue's consult comment |

Two things that look like "plan drift" and are not: preflight `STALE` (exit 4) is set when probes report the fix **already landed** (`swarm_preflight.py:242`), so the 7 STALE issues are delivered-but-open, a closing-discipline problem (#1234), not plan rot. Real plan rot (`file:line` going out of date) is already bounded by the recon convention of pinning a commit SHA and by #522 binding plan hash + target base SHA; the plan below adds the cheap delta check at entry.

## Recon Map — issue intake front door

Commit: `2fc3f0be` · Mode: grep + direct source reads · Lanes: single, this session.

### Subject and change class
Add a new skill (markdown only; it resolves HQ through the hq skill's existing `find-hq.sh`, no locator of its own) that composes existing skills and the existing `hq park` + `roadmap rate` writers. No new writer, no new ledger table, no new contract version, no new test suite, no change under `utils/`.

### The seams

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Issue creation + capture + ledger | `utils/hq/hq.sh:224` `cmd_park`; `hq-lib.sh:423` `hq_render_capture`; `releases roadmap add --raw-text` | GitHub, `PROJECT/1-INBOX`, `releases.db` | the skill writes the issue itself instead of through `hq park` (second write path); or passes a body `hq park` cannot carry (it takes `$request` verbatim, so the plan must be the request) |
| Plan-substance gate | #522 "Proposed admission contract", rows "Remediation plan in the issue" and "Plan substance" | future admission monitor, `start-marathon` Step 2 classification | the issue template omits a required section, or the plan lives only in the capture doc (local-only plan fails the gate) |
| Preflight Contract | `swarm_preflight.py:101-147` (required fields `target.repo`, `target.ref`, `gate`, ≥1 `fix_probes`, ≥1 `artifacts`); probe types `jog_run.py:1382` (`path_absent`, `path_present`, `grep_present`, `grep_absent`, `command`); stub emitted at `swarm_preflight.py:1254-1263`; example `relay-automation/CONTRACT.example.md`; heading located by `/preflight\s+contract/i` (`jog_run.py:1398`), so a contract inside the issue body reaches the capture doc through `hq_render_capture`'s verbatim `## Idea` copy with **no new slot** | Jog promotion (`contract_probes_from_doc`, GH-1232 fixed), preflight dry-run (publishes nothing, but fetches and creates/removes a detached worktree: `swarm_preflight.py:1299`, `:1359`, `:1379`) | a stub probe already satisfied at `target.ref` (STALE, exit 4; landed + unfixed = AMBIGUOUS, exit 7: `:242-244`, `:1642-1645`); an artifact that does not exist at `target.ref` and is not listed in `artifacts_new` (NOT-READY, exit 5: `:1366-1373`, `:1471-1472`); a `command` probe with an empty `cmd`; a `target.ref` that is not the integration base (`development`, `start-task` Step 1) |
| Capture doc frontmatter | `PROJECT/PDDA.md` "GitHub issue intake": minimum `gh_issue, source, title, status, created, doc_type`; `ratings_provisional: true` is an eligibility gate (PDDA.md:155-166) | `pdda.sh run`, auto-selection | the skill clears `ratings_provisional` itself (PDDA.md says a human clears it) |
| Acceptance extractor | `swarm_preflight.py:505-556`: `## Acceptance` heading, then `- [ ]` / `- [x]` bullets only; prose under the heading is not a criterion | preflight `remed_crit`, readiness (`:1468`) | the issue's Acceptance section is prose; preflight then reports "no phase plan or acceptance criteria" |
| PRS rating | `start-task` Step 5 policy; `releases_app.py:3325` `parse_rating`; two canonical writers: the `rated N/N/N/N [ovr N]` token in `roadmap add --raw-text` (GH-249), and `releases roadmap rate --issue-num N --rated a/b/c/d [--ovr]` (`releases_app.py:3366`, refuses to overwrite without `--force`) | `roadmap add`, `roadmap rate`, #1177 placeholder-rating hygiene | the skill writes `50/50/50/50`, `51/50/50/50`-style fabrications, or 1–5 PDDA values into PRS columns (the #1177 defect class); or it tries to pass the rating through `hq park`, which drops it |
| Independent review | #522 "Independent review" row: acceptance bound to plan content hash; author `approved: true` insufficient; reviewer identity to be specified | admission | the skill self-approves, or records a review without the hash it reviewed |
| Recon / debug-mantra | `skills/1-hourly/recon/SKILL.md` Step 5 map template and skip rules; `debug-mantra/SKILL.md` "When the target is a plan, not a bug" (4 pivots) | plan quality | the skill runs full recon on a typo (ceremony) or skips it on a multi-file change (the recon skill's own calibration rule) |
| Existing intake neighbours | `hq park`, `file-xyz-bug` (cross-repo sibling), `relay-to-issue`, `10days` scanner, #1022 `weekly-prepare` | duplicate intake | two skills own the same write; `file-xyz-bug` and this skill diverge on format |
| Skill packaging | `skills/README.md` (one tier folder, Skills Index row in `ARCHITECTURE.md`), GH-942 1024-char description limit, `test/gh660-skill-drift.sh` (vendored copies), Skills Army HQ `intake.py --apply add` | deployed collection, vendored `.xyz/skills` | tier path literal missing from manifests; description over limit |

### Call paths in
- Operator: `/idea <one-liner>` → skill → (tier decision) → recon-lite → debug-mantra plan pivot → issue body rendered → `hq park --create --title T <project> "<body>"` → `gh issue create` → capture doc → `roadmap add`.
- Later, reconciler (#1175 Phase 1) → `start-marathon` Step 2 classification → `swarm-preflight --dry-run` → `jog add`.

### State
- Writes: GitHub issue (via `hq park`), `PROJECT/1-INBOX/GH-<n>-<slug>.md` (via `hq_render_capture`, which embeds the body verbatim), `roadmap_items` row (via `roadmap add`), then the rating via `releases roadmap rate --issue-num <n> --rated …` (existing CLI verb; `hq park` cannot carry it). Two existing writers, no new one. The skill fills the env fields `hq park` already accepts and supplies the body.
- Reads: repo source, `gh issue list` (dedupe, already in `hq.sh:306`), `prior_art_recon.py`, `swarm-preflight --dry-run` (publishes nothing; it does fetch and create/remove a detached worktree in the target checkout, so it runs against the primary only when the primary is clean, as `start-marathon` Step 2 already notes). Consult receipts land under `relay-system/<date>/` outside the intake write path.

### Contracts
- `Swarm Preflight Contract` JSON block under a heading matching `preflight contract` (consumer: preflight, Jog promotion; declared `swarm_preflight.py`, `MACHINE-CONTRACTS.md`).
- `rated a/b/c/d` token (consumer: `parse_rating`; declared `start-task` Step 5, GH-249).
- #522 plan sections (consumer: admission monitor, not yet built; declared #522).

### Build, failure and rollback today
Filing today is `hq park` with a raw request, or hand-written issues. Failure mode: an issue that cannot be admitted (0 of 281). Rollback of this change: delete the skill folder and its index row; nothing else references it.

### Unknowns
| Unknown | Why it matters | What would settle it |
|---|---|---|
| Who is the trusted reviewer for #522 "independent review" | decides whether a filing-time consult counts as review or only as a draft review | operator decision on #522; this plan records the consult + hash and leaves "reviewed" to #522 |
| ~~Does `hq park` need the plan body in the capture doc too~~ settled by recon: `hq_render_capture` embeds `$request` verbatim, so issue and doc carry the same plan and contract | #522 needs the plan **in the issue**; PDDA wants the doc to carry actionable substance; both hold with one body | Issue = plan of record; doc = verbatim copy (not a pointer) that the contract parser and acceptance extractor read. A later edit to the issue body does not propagate to the doc: the skill states this and the PDDA issue-doc sync check already flags drift |
| Retrofit batch size the rater can absorb | 281 existing issues will not benefit otherwise | E1-style batches under #1022/#1177, operator-approved |

### Current-state radius, one line
`hq park` (3 writers behind it), the 1-INBOX capture format, preflight's contract parser, the PRS rating token, and every future admission consumer in #522/#1175.

## Debug-mantra plan pivots applied

1. **Reproduce.** Every number above was re-run on 2026-10-29, not recalled from the spike.
2. **Fail path.** The path the skill changes is operator → `hq park` → three writers; traced above with `file:line`. Nothing downstream of `roadmap add` changes.
3. **Falsify.** Each acceptance criterion below names how it fails and where the red evidence lands (`TESTS-RESULTS/`, no new suite per GH-831). Root cause the plan fixes: issues are filed without the information admission needs, at the moment that information is cheapest. The fix site is the filing moment, which is the origin, not downstream.
4. **Breadcrumbs.** Recon ledger: the Observed table. Walked against shipped work: #1232 (promotion lint) is closed, so the contract stub this skill emits is now honored unattended; #1213 (landing) is merged; #522 and #1022 are open and are consumers, not duplicates.

## Plan

### Tiers (the load-bearing design choice)

| Tier | When | Recon | Plan | Rating | Contract |
|---|---|---|---|---|---|
| **trivial** | ≤ 2–3 line fix, typo, path repoint (ROUTER issue-first floor) | none (recon skill's own skip rule) | `## Observed` + `## Acceptance` only | none | none; files **no issue**, says so, and exits (issue-first exempts it) |
| **standard** (default) | bounded fix or feature in an existing system | recon-lite: entry points, seams, every write site, pinned SHA | all #522 sections | PRS proposal + rationale, `ratings_provisional: true` | stub with ≥1 probe that is **unfixed today** |
| **spike** | design/arc issue, unknown blast radius (#1175-shaped) | recon map | outcome, position vs existing issues, phases, decisions needed | PRS proposal | none; body states `NEEDS-SPIKE: not admittable` |

Alternatives considered and rejected: (a) always full recon: ceremony on small issues, and the recon skill forbids it; (b) a single template with optional sections: the 2-of-281 measurement shows optional sections do not get filled; (c) a new Python intake writer: a second write path next to `hq park`, rejected under DRY. Strongest counterargument to tiers: the skill may mis-tier. Mitigation: the tier is printed in the preview and the operator can override before `--create`.

### Issue body contract (standard tier), one section per #522 gate

Headings are a format, not eleven independent gates: what admission consumes is the content rules in the right column.

```
## Observed              repro or direct observation; measured table (claim · command · observed), with receipts
## Root cause            (or "Diagnosis / existing gap" for a feature) origin and fix site; "removes the class" or "one instance" and why
## Plan                  ordered steps, each naming the existing subsystem and writer it extends
## Blast radius          seams table from recon-lite pinned to Recon <sha>; intended integration base (development) and
                         its resolved SHA at filing, stated separately; truthful effective write-set incl. helpers/docs;
                         builder/reviewer route named
## Dependencies          issues/PRs this needs or that need it
## Acceptance            `- [ ]` checkbox items only (swarm_preflight.py:509 reads nothing else); each names its red
                         control and where the evidence lands; none satisfiable by an empty input
## Verification          existing suite or manual check under TESTS-RESULTS/ (GH-831: no new tests)
## Non-goals
## Risk and rollback
## PRS proposal          pri/sev/appeal/effort, one issue-specific rationale line each; appeal 50 unless the operator
                         sets it; never 1–5 values, never a template default
## Preflight Contract    JSON (target.ref = development, gate, fix_probes unfixed at target.ref, artifacts; every new
                         file in both artifacts and artifacts_new with a path_absent probe); omitted for spike tier
Recon: <sha> · base: development@<sha> · tier: standard · review: <pending | consult <run-id> models=<codex,agy | one model, degraded> hash <sha256 of the body above this line>>
```

The review hash covers the body **excluding** the footer line, so inserting the hash does not change what was hashed.

### Phase 1 — the skill (markdown + locator), standard tier end to end

Operational sequence: harvest → tier → prior art → recon-lite → body → **consult (draft review) → hash → footer** → preview → `hq park --create` → `roadmap rate` → `swarm-preflight --dry-run` → report. Review happens before publication, so the published body already carries its review footer.

1. Create `skills/1-hourly/idea/SKILL.md` (tier 1-hourly: it is the in-task intake loop, `skills/README.md`). Description under 1024 chars (GH-942). Steps: harvest from the session first (`file-xyz-bug` Step 1 table, reused by reference), tier decision with printed reason (trivial = obvious, local, reversible, no design decision; a short diff alone does not qualify, `start-task` Step 5), `prior_art_recon.py --query`, recon-lite per the recon skill's Step 1–3 sized to the radius, `/debug-mantra plan` pivots, render the body contract above, preview, then `hq park --create` with `HQ_PARK_*` env filled from the recon (`WHY`, `KEY_CONCEPTS`, `NON_GOALS`, `RELATED`, `COMPLEXITY`, `RISK`, `EFFORT`, `PHASES`). The body is the `$request`: `hq park` files it as the issue body and embeds it verbatim in the capture doc, so the contract and acceptance checkboxes reach the doc with no HQ change.
2. Resolve HQ through the hq skill's `find-hq.sh`; do not ship a second locator. The skill runs in the repo it stands in; cross-repo stays `file-xyz-bug`.
3. The Preflight Contract: emit the `swarm_preflight.py:1254` shape with `target.ref` = the intended integration base (`development` here, per `start-task` Step 1) and at least one `grep_absent`/`path_absent` probe the recon showed is unfixed at that ref; every new file goes in both `artifacts` and `artifacts_new` with a `path_absent` probe (else NOT-READY, `:1366-1373`). Then run `swarm-preflight --dry-run` on the capture doc. The skill refuses to report success on **any** nonzero exit and prints the verdict and reason: STALE (4) means the probe is already satisfied at `target.ref`, which is either a wrong probe or delivered work, and the skill says which it found; AMBIGUOUS (7), NOT-READY (5), BLOCKED (6) and contract errors (3) are named the same way. It never auto-invents a replacement probe.
4. Rating: propose `pri/sev/50/effort` with one issue-specific rationale line per axis in the body. Write it with the existing verb `releases roadmap rate --issue-num <n> --rated a/b/c/d` right after `hq park --create` (`hq park` drops ratings; `roadmap rate` is the canonical writer, `releases_app.py:3366`), then read it back with `releases roadmap list` and print the exact row. `ratings_provisional: true` stays set in the doc; the skill never clears it (PDDA.md:155-166) and never passes `--force`.
5. Review: before publishing, run `consult` (one-shot Codex + agy, read-only) with the four start-task Step 6 questions on the rendered body; record the run id and the sha256 of the body-above-footer in the footer. This is a draft review, evidence for #522's reviewer, not the review itself; it does not substitute for `start-task` Step 6 relay plan QA (`start-task` forbids that substitution). The skill never writes `approved`.
6. Dogfood: file one real issue with the skill, then run `start-marathon` Step 2 classification and `swarm-preflight --dry-run` on it. Record both under `TESTS-RESULTS/<date>+GH-<this>/` with `provenance.jsonl`.
7. Skills Index row in `ARCHITECTURE.md`; `skills/README.md` needs no change. Deploy via Skills Army HQ `intake.py --apply add` after merge (not part of the PR).

### Phase 2 — entry-side delta re-recon (one paragraph in `start-task`, no code; after Phase 1 evidence)

- `start-task` Step 4 only (the #1175 reconciler's `add` path does not exist yet and is not a second edit site): when the issue carries `Recon: <sha>` and the SHA resolves, run the **unfiltered** `git diff --stat <sha>..HEAD`. Empty diff: reuse the Recon Map and plan. Non-empty: re-recon the changed paths that intersect the map's blast radius, and for changes outside it grep the diff for the map's named seams (files and symbols); a hit means full recon. An unresolvable SHA is a full recon, never treated as an empty diff.
- What is skipped is recon work only. `start-task` Step 6 relay plan QA still runs on every non-simple change; the filing-time consult is input to it, not a replacement.
- This is the part that turns the upfront cost into a saving per issue. It is text in one SKILL.md file and lands as its own PR once Phase 1 has run on at least five issues.

### Phase 3 — retrofit mode (after Phase 1 is proven on ≥5 new issues)

- `/idea --retrofit <n>`: same pipeline over an existing issue, writes the plan as an issue **comment** (never rewrites the operator's body), proposes the rating through the prs-backfill rater's approved-plan path (#1176 tooling, #1177 hygiene), batches operator-approved per E1. Out of scope until Phase 1 evidence exists.

## Acceptance

- [ ] `ls -d skills/*/idea` resolves to exactly one tier folder and `ARCHITECTURE.md` has its row. Red control (manual, recorded): delete the index row in a scratch copy and confirm the review checklist in `skills/README.md` ("The Skills Index row is part of the change") is what catches it; `test/gh660-skill-drift.sh` runs on synthetic fixtures (`test/gh660-skill-drift.sh:10-19`) and is only required to stay green.
- [ ] An issue filed through the skill carries every section of the body contract with non-empty content: the four core regexes hit, `## Acceptance` yields ≥ 1 `- [ ]` item through `swarm_preflight.py`'s extractor, and the footer has `Recon: <sha>` and `base: development@<sha>`. Red control (manual, recorded under `TESTS-RESULTS/`): a body of eleven empty headings plus footer must be refused by the skill's preview step, not filed.
- [ ] `swarm-preflight --dry-run` on the capture doc the skill produced exits 0 (READY). Red control: filing with a probe already satisfied at `target.ref` makes the skill stop with the STALE verdict and reason in its output and files nothing; a new-file artifact missing from `artifacts_new` makes it stop with NOT-READY (witnessed manually, recorded).
- [ ] `start-marathon` Step 2 classifies the new issue READY or NEEDS-PROMOTE (presence of capture + contract in `1-INBOX`; not admission), never NEEDS-CONTRACT or NEEDS-CAPTURE.
- [ ] `releases roadmap list` read-back shows the exact `rated a/b/c/d` the skill proposed, each axis with an issue-specific rationale line in the body, no axis on the 1–5 scale, no template default; `ratings_provisional: true` stays in the doc. Red control: a body with a missing or boilerplate rationale line is refused before `roadmap rate` runs; `roadmap rate` without `--force` refuses a second write (existing behaviour, witnessed).
- [ ] The skill writes only through `hq park` and `releases roadmap rate`: after a `--create` run, `git status --porcelain --ignored` shows only the capture doc and the ledger dump, consult receipts under `relay-system/`, and nothing under `utils/`; `releases.sql` has no new table. (A clean status is evidence, not proof; the SKILL.md names the two verbs and the dogfood transcript is the witness.)
- [ ] Trivial tier files nothing and prints the issue-first exemption; spike tier files with `NEEDS-SPIKE` and no contract.
- [ ] No new test suite, no `validate.sh` registry entry, no new gate machinery (GH-831).

## Verification

Existing suites: `gh660-skill-drift.sh`, `skills-army-hq.sh` (deploy), `pdda.sh run` (capture doc health). Everything else is a manual check with `provenance.jsonl` under `TESTS-RESULTS/<date>+GH-<this>/`, per AGENTS.md *No new tests*.

## Non-goals

- No admission decision, no `jog add`, no auto-promotion to `2-WORKING` (#522 owns admission; PDDA owns promotion).
- No new writer, ledger table, contract version or rating scale. No SQLite work and no change under `utils/` in this issue. The rating reaches the ledger through the existing `roadmap rate` verb, not through a new `hq park` parameter.
- No continuous scanning (#1022, #1175). No cross-repo filing (`file-xyz-bug`).
- No rewriting of existing issue bodies in retrofit mode.
- Not a replacement for `start-task`; it front-loads Steps 4–6 and Phase 2 lets `start-task` skip what is already done.

## Risk and rollback

- Risk: operators stop reading the plan because the skill wrote it. Mitigation: preview before `--create`, tier printed, provisional ratings held out of auto-selection by PDDA's existing gate.
- Risk: body length. GitHub bodies are fine at this size; the capture doc stays a pointer.
- Rollback: `git rm -r skills/1-hourly/idea`, drop the index row, revert the Phase 2 paragraph in `start-task` if it landed. Issues, capture docs and ratings already filed keep their value; a wrong rating is corrected with `roadmap rate --force` and a recorded reason.

## Decisions (settled 2026-10-30; consult `relay-system/2026-10-30/gh1258-decisions-104723`, Codex and agy both answered and both recommended b/a/a; coordinator agreed)

- D1: Name = **`idea`**, folder `skills/1-hourly/idea`. Claude Code dispatches `/<folder-name>` only; a trigger phrase in `description:` never makes `/idea` reach another folder, and Skills Army HQ derives link names from the folder (`skills/3-weekly/skills-army-hq/scripts/sync.py:245`). Naming the folder `idea` makes all five existing references resolve with zero edits (`skills/2-daily/hq/SKILL.md:64`, `skills/2-daily/file-xyz-bug/SKILL.md:3,12`, `PROJECT/PDDA.md:162`, `utils/hq/hq.sh:219`, `utils/hq/hq-lib.sh:418`). No `idea` folder exists in any skills root or in the Deployed Skills collection. Write-set: `skills/1-hourly/idea/SKILL.md` plus one `ARCHITECTURE.md` row. Ladder rung 2.
- D2: A filing-time consult is **draft review only**. The skill writes the footer `review: consult <run-id> models=<list>[, degraded] hash <sha>` and the dispositions comment, and never writes an approved/reviewed marker; #522 decides what counts once reviewer identity and authority exist (#522 row "Independent review"; `start-task` Step 6 stays mandatory, `start-task/SKILL.md:214`). The only addition is the `models=` token: `consult.sh` exits 0 on one answer, so a single-model run must be legible from the issue alone even when the `relay-system/` receipt is never committed. The hash binds the **published** body (what #522 checks has not changed since review); the reviewed input is the run's `*.PROMPT.txt` snapshot. Ladder rung 3 (one token).
- D3: Ledger row for this issue **at pickup, by `start-task` Step 3**, not now. `hq park` has no existing-issue mode (`utils/hq/hq.sh:314` always runs `gh issue create`; the dedupe at `:306` would refuse this title). No gate flags an open issue without a capture doc (`utils/pdda/pdda.sh:387,405,682` scan existing docs and rows only); the only cost is invisibility to ledger consumers until then. Sequence at pickup, existing verbs only: capture doc → `releases roadmap add --issue-num 1258 …` → `releases roadmap rate --issue-num 1258 --rated 80/55/50/65` → `roadmap list` read-back. Ladder rung 1 now.

## PRS proposal

`rated 80/55/50/65` · pri 80: step 6 of the spike found 0 admissible issues, so this is on the critical path of #1175 Phase 1 · sev 55: no data loss; the cost of the gap is wasted lane time and a halted flywheel · appeal 50: not set by the operator · effort 65: one SKILL.md plus a Skills Index row, composition of existing skills and two existing CLI verbs, one dogfood run with recorded receipts, a later one-paragraph `start-task` edit; no code under `utils/`.

Recon: `2fc3f0be` · base: development@2fc3f0be · tier: standard · review: consult `relay-system/2026-10-29/gh1258-plan-223724` models=codex, degraded (plan review; dispositions and hash in the consult comment) · decisions: consult `relay-system/2026-10-30/gh1258-decisions-104723` models=codex,agy (hash of the body above this line in the decisions comment)

---
Evidence: #1175 Phase 0 ([`TESTS-RESULTS/2026-10-25+GH-1175-phase0/`](https://github.com/HiQS-Labs/XYZ-forge/tree/development/TESTS-RESULTS/2026-10-25+GH-1175-phase0)), #522 admission contract, `utils/hq/hq.sh`, `utils/hq/hq-lib.sh`, `utils/py/swarm_preflight.py`, `utils/py/jog_run.py`, `skills/1-hourly/{recon,debug-mantra,start-task,consult}/SKILL.md`, `PROJECT/PDDA.md`.

## Why

Phase 0 of #1175 found 0 admissible of 281 open issues; nothing produces plan-in-issue intake upstream. This skill is that producer.

## Phase 0 — Explore & scope

### Checklist

- [ ] See `## Acceptance` in the embedded issue body above (checkbox items; the plan of record is #1258).

### QA checklist — Phase 0

- [ ] See `## Verification` in the embedded issue body above.
