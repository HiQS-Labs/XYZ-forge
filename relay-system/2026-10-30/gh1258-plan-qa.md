---
Goal: Plan QA — #1258 Phase 1 (idea skill: SKILL.md + ARCHITECTURE.md row)
Date: 2026-10-30
NEXT: codex
STATUS: Open
---

# Context

Independent plan QA for https://github.com/HiQS-Labs/XYZ-forge/issues/1258 before any build. Base `e305cbf3` (development). The plan of record is the issue body, embedded verbatim in `PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md` (read that file; it is in this tree). Scope under review is **Phase 1 only**: create `skills/1-hourly/idea/SKILL.md` (markdown only) and its `ARCHITECTURE.md` Skills Index row. Phases 2 and 3 are later PRs and are not under review.

Three operator decisions are already settled (the doc's `## Decisions` section): D1 name `idea`; D2 a filing-time consult is draft review only (footer `review: consult <run-id> models=<list>[, degraded] hash <sha>`, no approval marker); D3 the ledger row for #1258 is added at pickup (done in this tree: row `rmi-01M66S1Y01WM5BWJS9XCKBXRWG`, rated 80/55/50/65). Do not reopen them.

A prior Codex consult (2026-10-29, 18 findings, 17 accepted) already corrected the plan: capture doc embeds the body verbatim; rating via `releases roadmap rate`; `## Acceptance` as `- [ ]` items only; `artifacts_new` for new files; refuse on any nonzero preflight exit; `target.ref = development`; unfiltered delta re-recon. Grade the plan as it stands now, not that history.

Operational envelope: a markdown skill that composes existing writers. **No code under `utils/`, no new flags, no new scripts, no new tests or suites (AGENTS.md *No new tests*, GH-831), no schema or gate changes.** Commensurate complexity: this is a SKILL.md and one index row. Do not ask for machinery the plan's non-goals exclude; if the plan cannot work without one, say so as a Blocker with the concrete failing input.

Read the plan doc in full, plus the code it cites:
- `utils/hq/hq.sh:214-369` (`cmd_park`: preview/create, dedupe `:306-312`, `gh issue create` `:314`, `roadmap add` `:339`, `HQ_PARK_*` env `:217-250`) and `utils/hq/hq-lib.sh:423-515` (`hq_render_capture`), `:555-560` (`hq_roadmap_line`).
- `utils/py/releases_app.py` `roadmap rate` (`--help`; refuses an already-rated row without `--force`).
- `utils/py/swarm_preflight.py:101-147` (required contract fields), `utils/py/jog_run.py:1382` (probe types), `:1398` (heading regex), `:505-556` (acceptance extractor), `:1299-1379` (`--dry-run` fetch + detached worktree), `:1366-1373,1471-1472` (artifacts missing at target.ref → NOT-READY unless in `artifacts_new`).
- `skills/2-daily/file-xyz-bug/SKILL.md:25-123` (Step 1 harvest table the plan reuses by reference), `skills/2-daily/hq/SKILL.md`, `skills/1-hourly/start-task/SKILL.md` (Step 5 tier rule, Step 6), `skills/README.md` (tier contract, Skills Index row), `ARCHITECTURE.md:55-62` (row format).

Questions:
1. Write-set: is `skills/1-hourly/idea/SKILL.md` + one `ARCHITECTURE.md` row complete and minimal for Phase 1? Name any file the plan's own acceptance or the repo's skill contract requires that is missing, or any it names that is unnecessary. Cite file:line.
2. Operational sequence (plan step 1: harvest → tier → prior art → recon-lite → body → consult → hash → footer → preview → `hq park --create` → `roadmap rate` → read-back → `swarm-preflight --dry-run` → report): is every step executable as written against the cited code? In particular: (a) `hq park`'s dedupe and title handling with a long rendered body; (b) whether `roadmap rate` after `hq park` can be refused (does `hq_roadmap_line` ever carry a `rated` token?); (c) whether `swarm-preflight --dry-run` on a just-filed issue can reach READY when the capture doc is only local and uncommitted, or whether the plan must say what state the tree is in at that step; (d) which file the acceptance extractor reads (issue body vs capture doc) and whether the verbatim embed under `## Idea` keeps `## Acceptance` extractable.
3. Body contract: does the Preflight Contract stub as specified (`target.ref = development`, `gate`, ≥1 `fix_probes` unfixed at target.ref, `artifacts` + `artifacts_new` with `path_absent`) parse and classify READY under `swarm_preflight.py`/`jog_run.py` for a brand-new skill whose only artifact is a file that does not yet exist? Give the concrete probe that would make it STALE or AMBIGUOUS by mistake.
4. Acceptance: are the `## Acceptance` items falsifiable with their named red controls, given no new tests may be added? Any item that cannot be witnessed on an existing suite or a recorded manual check?
5. Rating 80/55/50/65 (pri/sev/appeal/effort-as-cheapness): grounded in the plan's Observed table? Appeal is 50 (operator did not set it).
6. Is anything in Phase 1 in tension with D1–D3 as settled, or with the GH-831 rail?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, citing file:line; every `[Blocker]`/`[Should]` that asks for a behaviour change carries `Observed input:`, `Affected scope:` and `Falsifier:`. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log


### Round 1 · Reviewer · codex · 2026-10-30

**Verdict:** Changes requested — 0 Blockers, 4 Shoulds. The approach fits the existing writers; all requested corrections are plan/skill text. Reversibility: **Easy**, since the functional change is markdown and its index entry. References below to `plan` mean `PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md`.

**Findings & proposals:**

1. **[Should] Keep rating grammar out of the explicit issue title.** `plan:65,174` assumes HQ's rendered roadmap line cannot carry a rating. The template adds none itself but interpolates the title verbatim (`utils/hq/hq-lib.sh:555-557`). `roadmap add` parses the entire line (`utils/py/releases_app.py:3639`); `roadmap rate` then refuses an already-rated row even if the requested score is identical (`:3738-3741`).
   - **Observed input:** title `Handle rated 80/55/50/65 placeholders`, a plausible issue about the #1177 rating defects. Probe A below exited 0: the neutral-title control returned all rating columns `None`; this title returned `80/55/50/65`. No DB writer ran.
   - **Affected scope:** Phase 1 title preparation and the post-park rating step, not D3's completed pickup of #1258.
   - **Falsifier:** render the chosen title with `hq_roadmap_line` and pass it to the existing `parse_rating`; it should remain unrated before `roadmap rate`. Specify a concise, single-line `--title` without rating tokens, preserving literal score examples in the body. Do not use `--force` to evade the refusal. Witness the real writer sequence in the later disposable-clone dogfood.

2. **[Should] Make the STALE red control agree with publication order.** `plan:169,173-174` runs preflight after `hq park --create` and `roadmap rate`, but `:193` promises a STALE probe "files nothing." HQ has already created the GitHub issue (`utils/hq/hq.sh:314`), capture (`:323-325`) and ledger row (`:339`) before that verdict. Refusing success does not undo publication.
   - **Observed input:** the `plan:193` red control, with an already-satisfied probe, following the stated `:169` sequence. Source order establishes the earlier publication; no live issue was created during this review.
   - **Affected scope:** standard-tier failure reporting and acceptance criterion 3.
   - **Falsifier:** run that negative control in the authorized dogfood environment and inspect the issue/doc/row after exit 4. The minimal correction is to expect a failed/partial intake report naming those existing outputs and no admission, rather than "files nothing." Empty-section validation can still refuse publication at preview. No transaction, rollback automation, new writer or gate is needed.

3. **[Should] Define the local-doc preflight invocation and reconcile the clean-tree precondition.** `plan:102` says preflight runs against the primary only when clean, while `:169,173-174` runs it immediately after writers that leave capture and ledger uncommitted (`utils/hq/hq.sh:366`). Following both has no defined next step. This is a plan contradiction; the implementation does not reject dirty trees merely for being dirty.
   - **Observed input:** a clean checkout before `/idea`, then successful HQ creation/rating with a new untracked `PROJECT/1-INBOX/GH-<n>-*.md` and modified ledger files, with no commit step before preflight.
   - **Affected scope:** every standard-tier filing and Phase 1 dogfood.
   - **Falsifier:** state the checkout and source-doc state explicitly. The existing invocation is `bash "$HARNESS/utils/swarm-preflight.sh" --project-doc "$ABS_CAPTURE" --target-root "$TARGET_ROOT" --dry-run`: read the fresh local doc directly, evaluate probes at resolved `development`. `--project-doc` accepts a local file (`utils/py/swarm_preflight.py:1219-1225`); `--gh-issue` instead searches only `2-WORKING` (`:1232-1238`). Dirty state is recorded (`:1312-1316,1619`) and absent from exit-verdict conditions (`:1640-1645`), so the uncommitted capture can reach READY; no commit/promotion requirement needs inventing. Remove or qualify the contradictory clean-only claim and retain the fetch/detached-worktree side-effect warning (`:1299,1359,1379`). Full runtime result: **[Unverified — needs clone run]**.

4. **[Should] Separate the two implementation files from mandatory committed verification evidence.** The functional write-set at `plan:177,220` is complete, but `:176,191-202` also requires dogfood/red-control evidence under `TESTS-RESULTS/<date>+GH-1258/` with `provenance.jsonl`. `AGENTS.md:114-116` requires cited run provenance committed in the same PR. A literal two-file-only PR cannot satisfy that contract.
   - **Observed input:** a PR containing only SKILL.md and ARCHITECTURE.md, with the `plan:176` dogfood receipt uncommitted: it has no committed `TESTS-RESULTS/<date>+GH-1258/provenance.jsonl` despite claiming the required run.
   - **Affected scope:** Phase 1 delivery/write-set and review containment; no additional functional subsystem and no reopening of D1's name decision.
   - **Falsifier:** explicitly allow the bounded verification report/transcript and `provenance.jsonl` alongside the two implementation files, and identify where the real dogfood capture/ledger outputs are retained. Evaluate `plan:196` as a before/after delta for the intake operation, separately from implementation and verification files. No new suite or registry entry is requested.

**Confirmed passes / answers:**

- **[Pass] Packaging.** `skills/README.md:3,8,23-24` requires one tier folder and the Skills Index row. `skills/1-hourly/idea/SKILL.md` plus `ARCHITECTURE.md` is the complete minimal functional write-set. No README, locator, manifest, code or test-file change is required by that contract. Adjust the hourly count at `ARCHITECTURE.md:49` in the same file; deployment remains after merge (`plan:177`). Evidence is addressed in finding 4.
- **[Pass] Long body, title and dedupe.** With the explicit `--title T` at `plan:97`, HQ uses T for title/slug (`utils/hq/hq.sh:252-254`) and duplicate search (`:306-312`). The long body stays the request argument and reaches `gh issue create --body` (`:314`) and the capture's `## Idea` verbatim (`hq-lib.sh:492-494`). A duplicate refusal is an expected stop, not grounds to bypass the writer. Ordinary titles produce an unrated row; finding 1 covers the exception. `roadmap rate --help` exited 0 and confirmed the planned selectors, `--rated`, and deliberate `--force` semantics.
- **[Pass] Acceptance extraction.** Probe B rendered a nonempty 362-byte body into a 1,815-byte capture, verified verbatim body inclusion, equal one-item issue/capture acceptance lists and contract equality. Preflight reads the local capture for its inline packet checklist (`swarm_preflight.py:716-750,1498-1504`), and also extracts Acceptance from both fetched issue and capture for fidelity comparison (`:853-899,1484-1488`). Thus it reads both, for different purposes. The `## Idea` embed does not hide the heading; checkbox-only criteria are supported (`:506-556`).
- **[Pass] New-file contract and wrong-probe controls.** The Probe B contract below has required target/gate/probes/artifacts, lists the new skill in both `artifacts` and `artifacts_new`, and supplies its same-path `path_absent` probe (`swarm_preflight.py:102-125,1332-1336`). New artifacts bypass the existing-path requirement (`:1366-1373`). The missing-skill probe evaluated `unfixed`, flags `(stale,blocked,ambiguous)=(0,0,0)`. A mistaken `path_absent` probe on existing `ARCHITECTURE.md` evaluated `landed` / STALE; combined with the missing-skill probe it became AMBIGUOUS. `grep_absent` on the existing index for `Skills Index` also evaluated `landed` / STALE. Use a feature-specific absent pattern for the index edit. Jog recognizes the heading and these probe types (`utils/py/jog_run.py:1382-1435`). Probe B evaluated seeded files, not a git ref: complete ref-pinned READY/NOT-READY exits are **[Unverified — needs clone run]**.
- **[Pass] Acceptance and GH-831.** Apart from finding 2, missing row, empty sections, lost checkbox/footer, wrong rating/rationale, unintended write paths, tier output and added test/gate machinery are observable through existing checks or recorded manual inspection. `test/gh660-skill-drift.sh:10-19` uses synthetic fixtures; the plan correctly requires a separate manual row-removal control for the real index. No new tests, scripts, schemas or gates are needed. Full preflight, writer-refusal witnessing, existing suites and dogfood remain **[Unverified — needs clone run]**. No git, gate, pytest or executable fixture ran here.
- **[Pass] Ratings and decisions.** Provisional `80/55/50/65` is reasonably grounded in `plan:61-68,226`: measured intake blockage supports priority 80; wasted lane time without data loss supports severity 55; unset appeal remains 50; composing markdown and existing writers with dogfood supports moderate effort-cheapness 65. The intake bottleneck is corroborated by `TESTS-RESULTS/2026-10-25+GH-1175-phase0/SUMMARY.md:15`; this is rationale review, not a fresh GitHub census. D1 name/tier, D2 draft-only consult with models/degraded/hash footer, D3 pickup ledger row, and GH-831 remain intact. The producer/evidence lesson (`LESSONS-LEARNED.md:38-65`) calls for no gate change here: this phase creates an upstream producer and explicitly excludes gate changes.

**Probe A — exact command, exit 0:**

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
PYTHONPATH="$PWD/utils/py" python3 - <<'PY'
import subprocess
from releases_app import parse_rating
for title in ('Add idea intake skill', 'Handle rated 80/55/50/65 placeholders'):
    r = subprocess.run(['bash', '-c', 'source utils/hq/hq-lib.sh; hq_roadmap_line 99999 "$1" 2026-10-30 PROJECT/1-INBOX/GH-99999-IDEA.md GH-99999-IDEA.md https://github.com/HiQS-Labs/XYZ-forge/issues/99999', 'probe', title], check=True, text=True, capture_output=True)
    print(title, '=>', parse_rating(r.stdout, title))
PY
```

Decisive output: neutral title → all five columns `None`; rating-example title → `{'rating_pri': 80, 'rating_sev': 55, 'rating_appeal': 50, 'rating_effort': 65, 'rating_ovr': None}`. Separate command `PYTHONPATH="$PWD/utils/py" python3 utils/py/releases_app.py roadmap rate --help`: exit 0.

**Probe B — exact command, exit 0:**

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
PYTHONPATH="$PWD/utils/py" python3 - <<'PY'
import json, os, subprocess
from pathlib import Path
from swarm_preflight import extract_contract, extract_acceptance_criteria, eval_probes
new = 'skills/1-hourly/idea/SKILL.md'
c = dict(target=dict(repo='.', ref='development'), gate='bash validate.sh', fix_probes=[dict(type='path_absent', path=new)], artifacts=[new], artifacts_new=[new])
body = chr(10).join(['## Observed', 'Missing skill.', '## Acceptance', '- [ ] Skill and index exist.', '## Preflight Contract', '```json', json.dumps(c), '```', ''])
r = subprocess.run(['bash', '-c', 'source utils/hq/hq-lib.sh; hq_render_capture 99999 https://github.com/HiQS-Labs/XYZ-forge/issues/99999 "Add idea skill" 2026-10-30 feedback XYZ-forge XYZ-forge "$1"', 'probe', body], check=True, capture_output=True, text=True)
assert r.stdout.strip() and body in r.stdout
p = Path(os.environ['TMPDIR'])/'capture.md'
p.write_text(r.stdout)
print('bytes', len(body.encode()), len(r.stdout.encode()), 'contract_equal', extract_contract(str(p)) == c)
print('acceptance', extract_acceptance_criteria(body), extract_acceptance_criteria(r.stdout))
for probes in [c['fix_probes'], [dict(type='path_absent', path='ARCHITECTURE.md')], [dict(type='path_absent', path='ARCHITECTURE.md')] + c['fix_probes'], [dict(type='grep_absent', path='ARCHITECTURE.md', pattern='Skills Index')]]:
    print(eval_probes(str(Path.cwd()), dict(fix_probes=probes)))
PY
```

Decisive output: `bytes 362 1815 contract_equal True`; both acceptance lists `['Skill and index exist.']`; probe verdicts respectively `unfixed (0,0,0)`, `landed (1,0,0)`, `landed,unfixed (1,0,1)`, `landed (1,0,0)`. Output capture stayed under `.relay-scratch/tmp/`; no gate was executed.

**Commit:** Harness-owned; reviewer did not run git or edit the seeded artifact.

VERDICT: FAIL
Basis: Textual plan/source trace plus observed pure rendering/parsing probes; four bounded plan corrections remain. Full preflight, writer refusal, dogfood and gates need the authorized disposable-clone run.

## Author response — round 1 dispositions (claude)

All four Shoulds accepted; no Blockers. Applied to the artifact `PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md` and, byte-identically, to the #1258 issue body (so the acceptance fidelity comparison still holds); dispositions also posted as a #1258 comment.

- **1 title rating token → Implemented** @ Recon Map row "What `hq park` writes" (`hq_roadmap_line` interpolates the title; `parse_rating` reads the whole line) and @ plan step 4 ("The `--title` is one line with no `rated N/N/N/N` token … `roadmap rate` refuse (`:3738-3741`)").
- **2 STALE red control vs publication order → Implemented** @ Acceptance item 3: "report **filed, not admission-ready**, naming the issue, capture doc and ledger row that `hq park --create` already wrote (nothing admitted, nothing rolled back)".
- **3 preflight invocation / clean-tree claim → Implemented** @ Recon Map "Reads" bullet: `--project-doc` with `--target-root`, uncommitted capture and ledger recorded not judged (`swarm_preflight.py:1219-1225,1312-1316,1640-1645`), runs right after `hq park --create` in the dirty tree.
- **4 evidence in the PR write-set → Implemented** @ plan step 7: PR write-set = two implementation files + intake (capture doc, `releases.db`, `releases.sql`) + `TESTS-RESULTS/2026-10-30+GH-1258/` with `provenance.jsonl`; `ARCHITECTURE.md:49` count corrected in the same edit.

**Verification:** `git diff` of the capture doc shows exactly the five replaced spans; no other line changed. Textual only (plan artifact).
**Re-review this:** the four spans above, and whether anything in the revised step 7 write-set exceeds Phase 1.
**Commit:** harness-owned (this turn's commit).

