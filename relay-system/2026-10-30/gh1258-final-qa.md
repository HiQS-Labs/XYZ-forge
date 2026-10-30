---
Goal: Final QA — #1258 Phase 1 (idea skill) on the committed implementation and evidence
Date: 2026-10-30
NEXT: claude
STATUS: Approved
---

# Context

Final QA (start-task Step 8) for https://github.com/HiQS-Labs/XYZ-forge/issues/1258 Phase 1. Plan QA was Approved in `relay-system/2026-10-30/gh1258-plan-qa.md` (round 2, attest `6be3b534`). Branch `feat/XYZ-forge-gh1258-idea-skill-2026-10-30`, head `9d552e2c`, base `development@e305cbf3`. You cannot run git here; the changed set relative to the base is listed below and every file is in this tree.

Changed files (vs `origin/development`):
     ARCHITECTURE.md                                    |   3 +-
     PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md              | 245 +++++++++++++++++++++
     .../2026-10-30+GH-1258/hq-park-create.log          |   6 +
     TESTS-RESULTS/2026-10-30+GH-1258/intake-after.txt  |  24 ++
     TESTS-RESULTS/2026-10-30+GH-1258/intake-before.txt |  21 ++
     .../2026-10-30+GH-1258/intake-writeset.diff        |   4 +
     .../2026-10-30+GH-1258/preflight-dryrun-gh1263.log |  24 ++
     TESTS-RESULTS/2026-10-30+GH-1258/provenance.jsonl  |   9 +
     .../red-controls/GH-1263-NOTREADY.mutated.md       | 139 ++++++++++++
     .../red-controls/GH-1263-STALE.mutated.md          | 139 ++++++++++++
     .../red-controls/notready-exit5.log                |  15 ++
     .../red-controls/stale-exit4.log                   |  15 ++
     .../2026-10-30+GH-1258/roadmap-rate-readback.txt   |   1 +
     TESTS-RESULTS/2026-10-30+GH-1258/smoke.md          |  44 ++++
     relay-system/2026-10-30/gh1258-plan-qa.md          | 202 +++++++++++++++++
     releases.db                                        | Bin 1564672 -> 1564672 bytes
     releases.sql                                       |  11 +-
     skills/1-hourly/idea/SKILL.md                      | 164 ++++++++++++++
     18 files changed, 1063 insertions(+), 3 deletions(-)

Implementation (two files): `skills/1-hourly/idea/SKILL.md` (new, markdown only) and `ARCHITECTURE.md` (one Skills Index row after `handsfree`; `1-hourly` count 15 → 17). Intake: `PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md` (capture; plan of record embedded verbatim under `## Idea`, Decisions D1–D3 settled, plan-QA amendments applied), `releases.db`/`releases.sql` (row `rmi-01M66S1Y01WM5BWJS9XCKBXRWG` parked, rated 80/55/50/65, admitted with `--accepted-start` after plan QA). Evidence: `TESTS-RESULTS/2026-10-30+GH-1258/` (`smoke.md`, `provenance.jsonl`, logs, red-control inputs). Relay threads under `relay-system/2026-10-30/` are review records.

Operational envelope: a markdown skill that composes existing writers; no code under `utils/`, no new flag/script/test/suite/gate (AGENTS.md *No new tests*, GH-831). Grade against the plan's `## Acceptance` and commensurate complexity. A new test file or `validate.sh` registry entry in the diff would be a finding; there should be none.

Read: the capture doc's embedded plan (`## Plan` Phase 1 and `## Acceptance`), `skills/1-hourly/idea/SKILL.md` in full, the `ARCHITECTURE.md` row, `TESTS-RESULTS/2026-10-30+GH-1258/smoke.md` and `provenance.jsonl`, and the code the skill cites: `utils/hq/hq.sh:214-369`, `utils/hq/hq-lib.sh:402-406,423-515,555-558`, `utils/py/releases_app.py:3325,3639,3738-3741`, `utils/py/swarm_preflight.py:101-147,1219-1238,1299-1379,1640-1645`, `utils/py/jog_run.py:505-556,1382,1398`, `skills/2-daily/file-xyz-bug/SKILL.md:25-123`, `skills/2-daily/hq/SKILL.md:25-70`, `skills/README.md`.

Questions:
1. Is every `## Acceptance` item of the plan satisfied by the diff plus the recorded evidence, with its red control witnessed? Name any item the evidence does not substantiate.
2. Does `skills/1-hourly/idea/SKILL.md` match the cited code? Check in particular: the hq locator variables (`HQ_SH`, `find-hq.sh --env`), the `HQ_PARK_*` names, that `hq park --create` prints `✓ issue: <url>`, the title rule (no `rated`/`ovr` token; `parse_rating` reads the whole ledger line), `roadmap rate` after park and its `--force`/`already-rated` semantics, the preflight invocation (`--project-doc` + `--target-root`, dirty tree recorded not judged), and the exit-code table (0/3/4/5/6/7).
3. Does the skill introduce any writer, locator, flag or parallel path beyond `hq park --create`, `releases roadmap rate`, `gh issue comment` and the existing `swarm-preflight.sh` dry-run? Does it ever write an approval/reviewed marker or clear `ratings_provisional`?
4. Is the body contract in the skill (headings, checkbox-only Acceptance, `artifacts_new` rule, footer with `models=` and hash) consistent with the plan's contract and with what `swarm_preflight.py`/`jog_run.py` read?
5. Is the persisted rating for #1258 (80/55/50/65, appeal 50, no ovr, `ratings_provisional: true` still set) consistent with the plan's PRS rationale and the evidence?
6. Does the smoke receipt substantiate its claims (issue #1263 filed through the skill, READY exit 0, STALE exit 4 and NOT-READY exit 5 on mutated copies, write-set delta of exactly three paths, acceptance 1 scratch control, gh660 7/7)? Is anything claimed that the logs do not show?
7. Anything in the diff outside Phase 1 scope, or any accidental file?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with file:line. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log


### Round 1 · Reviewer · codex · 2026-10-30

**Changes requested — 0 Blockers, 4 Shoulds.** The standard-tier dogfood has credible READY evidence, but Phase 1 does not satisfy every acceptance item. Reversibility: **Easy**, bounded skill instructions and manual receipts through existing mechanisms. The material assumption is that HQ's resolved intake checkout equals the caller's checkout; the dogfood shows that this need not hold.

1. **[Should] Keep park, rate, comment and preflight on the same resolved target.** `skills/1-hourly/idea/SKILL.md:39,121-124,132,138,153-155` records ROOT from the caller, invokes HQ with a project name, then rates the caller's ledger and preflights a capture under the caller's root. HQ writes under independently resolved REPO_PATH (`utils/hq/hq-lib.sh:242-263`; `utils/hq/hq.sh:229-232,323-339`); locating HQ_SH does not resolve that target. `utils/py/releases_app.py:304-316` uses the current repository absent --root. In a task clone, HQ can create the issue/doc/row in the registered primary, after which the displayed rate command cannot find that new row in the task clone (or addresses a different row), and the displayed capture path is absent there. This is the dogfood arrangement: `TESTS-RESULTS/2026-10-30+GH-1258/smoke.md:7,17,21` says the caller was the task clone but intake/preflight used the primary. Its success demonstrates an adaptation beyond the instructions.
   - Use existing `hq resolve` before publication and either refuse a caller/target mismatch or consistently use the resolved target for rating/read-back, repo-qualified commenting, capture/preflight and the final uncommitted-files report. Keep recon/base consistent with the published target. No new locator or writer is needed. Record the chosen behavior for the task-clone/primary case. This finding is source-traced; no live writer or git command ran here.

2. **[Should] Implement the accepted trivial and spike branches.** `skills/1-hourly/idea/SKILL.md:48-51` says trivial bodies retain the contract and skip only consult, so Steps 7–10 still file and rate them. Acceptance explicitly requires **trivial files nothing and prints the issue-first exemption** (`PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md:197`). Spike omits its contract but reaches unconditional preflight at skill line 138, producing contract error 3 rather than the required NEEDS-SPIKE report. Neither skill nor smoke supplies that branch/label.
   - Add the trivial early return and the spike filing/report branch; skip contract-dependent readiness evaluation for a spike and report NEEDS-SPIKE. Witness both manually. Acceptance item 7 is unsatisfied; no new suite or gate is needed.

3. **[Should] Exclude every rating-token presence form from titles before creation.** `skills/1-hourly/idea/SKILL.md:109,112-116` excludes only complete `rated N/N/N/N`. Titles `Fix rated 5/5 placeholder` and `Rank ovr 200 example` satisfy that restriction but cause roadmap add to refuse after issue/capture creation. Parser presence rules are broader (`utils/py/releases_app.py:3299,3317,3325-3350`); HQ's write order is `hq.sh:314,323-325,339`. The dogfood issue itself explains these cases (`red-controls/GH-1263-NOTREADY.mutated.md`, Plan step 1); #1263's future runtime fix cannot be assumed present now.
   - Broaden the skill's title restriction to the existing parser's rated/ovr token-presence rule, including truncated/malformed forms. Keep examples in the body. This asks for skill text, not implementation of #1263.
   - **Probe A below, exit 0:** neutral title → five null ratings; malformed rated title → parser exit 3, `rule=rating-shape`; orphan ovr title → parser exit 3, `rule=ovr-orphan`. Only the pure HQ renderer and parser were called.

4. **[Should] Complete the required refusal witnesses and correct the smoke command.** Capture acceptance `:192,195` requires refusal of eleven empty headings, refusal of missing/boilerplate PRS rationale before rating, and an observed second-rating refusal without --force. None appears in `TESTS-RESULTS/2026-10-30+GH-1258/smoke.md:23-40` or its nine-line provenance.jsonl. The skill describes desired contents but does not explicitly direct preview to reject these invalid inputs (`SKILL.md:63-83,103-116`). Reading the already-rated branch is not the required witnessed refusal. Smoke line 30 also cites skill text as the STALE-report witness: the retained log proves preflight exit 4, but contains no agent report saying **filed, not admission-ready** and naming issue/doc/row.
   - Add the missing rejection instructions to the existing preview step and retain manual witnesses, including the agent's partial-publication report. An isolated replay using the existing filed outputs is sufficient; there is no need to file a second malformed public issue. Run writer/suite-dependent checks in the authorized disposable clone, without adding a test or gate.
   - **Falsified receipt command:** `grep -c '[idea](skills/1-hourly/idea/SKILL.md)' ARCHITECTURE.md` (smoke line 35) returned **exit 1, output `0`**, not the reported 1; brackets are a regex character class. Correct to a fixed-string check and retain its row-removal control. Independent literal-string inspection confirms one actual row, so this is a receipt defect, not a missing index row.

**Acceptance accounting / remaining review answers:**

| Plan acceptance item | Result |
|---|---|
| 1, capture `:191` | **[Pass]** Exactly one idea tier folder and index row; hourly count 17 matches rows/folders. Manual index-removal control is appropriate; displayed command needs correction (finding 4). gh660 7/7 is recorded in provenance line 9, not rerun here. |
| 2, `:192` | **[Pass]** Positive body: eleven sections, four extracted Acceptance items, recon/base/footer. **[Should]** Empty-body refusal witness missing (finding 4). |
| 3, `:193` | **[Pass]** Retained main log records development@e305cbf36, dirty=1, four criteria matched to open #1263, READY exit 0. Mutated inputs/logs record STALE exit 4 and NOT-READY exit 5. **[Should]** The agent's partial-publication report is not witnessed (finding 4). |
| 4, `:194` | **[Pass]** NEEDS-PROMOTE follows the open issue, valid contract, successful preflight and 1-INBOX capture; matches `skills/2-daily/start-marathon/SKILL.md:174-186`. No admission is claimed. |
| 5, `:195` | **[Pass]** #1263 read-back is 55/45/50/90, no override; retained body has four specific rationales and provisional metadata. #1258 SQLite row is 80/55/50/65, appeal 50, override null, capture still provisional; its capture `:226` gives a grounded rationale. **[Should]** Rationale-refusal and repeat-rating controls missing (finding 4). |
| 6, `:196` | **[Pass]** Nonempty before/after snapshots reproduce exactly three added status entries and none removed. Supplied changed set adds no utils implementation, table, locator, flag or parallel writer. D2 explicitly permits dispositions commenting. Target consistency remains finding 1. |
| 7, `:197` | **[Should]** Trivial/spike branches differ from acceptance and lack witnesses (finding 2). |
| 8, `:198` | **[Pass]** Supplied changed set is skill/index, intake/ledger, relay and bounded verification evidence. No new suite, registry entry or gate machinery. Phase 2/3 and deployment remain out of scope. |

**[Pass] Composition otherwise matches the cited code.** HQ_SH/find-hq --env and HQ_PARK_* names match the existing locator and `hq.sh:224-228`/`hq-lib.sh:423-506`. Full intake prints `✓ issue:` at `hq.sh:326`, embeds the body verbatim under Idea and parks the row. `roadmap rate` is the existing post-park writer; `releases_app.py:3738-3741` refuses an already-rated row without --force, which the skill forbids. Local --project-doc/--target-root is correct; dirty state is recorded (`swarm_preflight.py:1312-1316`) and absent from verdict conditions (`:1640-1645`). Exit labels 0/3/4/5/6/7, artifacts/artifacts_new with same-path path_absent and checkbox Acceptance agree with the actual parser. Some jog_run line citations are stale, but the behavior is in the preflight reader. No approval/reviewed/admission marker is written or ratings_provisional cleared; draft consult does not replace pickup QA. Footer models/degraded/hash matches D2.

**[Pass] Dogfood body/hash retention.** Reversing the single documented mutation in each retained input independently reconstructs the same 8,253-byte body; SHA256 above its footer is `4fa3dc539317f5780d2db97ca762113e1ac1c593a065d5bb238e6ba6be8e7ec7` for both. The retained inputs thus support the published-body hash claim. The consult's two answering seats remain a provenance-receipt claim, not independently established by that hash.

**Probe A — exact command, exit 0 (finding 3 and seeded evidence checks):**

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
PYTHONPATH="$PWD/utils/py" python3 - <<'PY'
import contextlib, io, json, sqlite3, subprocess
from pathlib import Path
from releases_app import parse_rating
from swarm_preflight import extract_contract, extract_acceptance_criteria
for title in ['Add idea intake skill', 'Fix rated 5/5 placeholder', 'Rank ovr 200 example']:
    line = subprocess.run(['bash', '-c', 'source utils/hq/hq-lib.sh; hq_roadmap_line 99999 "$1" 2026-10-30 PROJECT/1-INBOX/GH-99999-IDEA.md GH-99999-IDEA.md https://github.com/HiQS-Labs/XYZ-forge/issues/99999', 'probe', title], check=True, text=True, capture_output=True).stdout
    assert line.strip()
    err = io.StringIO()
    try:
        with contextlib.redirect_stderr(err):
            rating = parse_rating(line, title)
        print(json.dumps(dict(title=title, parser_exit=0, rating=rating)))
    except SystemExit as e:
        print(json.dumps(dict(title=title, parser_exit=e.code, diagnostic=err.getvalue().strip())))
ev = Path('TESTS-RESULTS/2026-10-30+GH-1258')
for name in ['STALE', 'NOTREADY']:
    p = ev/'red-controls'/('GH-1263-'+name+'.mutated.md')
    text = p.read_text()
    c = extract_contract(str(p))
    acc = extract_acceptance_criteria(text)
    assert len(text) > 100 and c and acc
    print(name, 'criteria', len(acc), 'probes', c['fix_probes'], 'artifacts', c['artifacts'])
before = (ev/'intake-before.txt').read_text().splitlines()
after = (ev/'intake-after.txt').read_text().splitlines()
assert before and after
print('intake_removed', sorted(set(before)-set(after)))
print('intake_added', sorted(set(after)-set(before)))
conn = sqlite3.connect('file:releases.db?mode=ro', uri=True)
conn.row_factory = sqlite3.Row
row = dict(conn.execute('select global_id,gh_number,doc_path,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr,raw_text from roadmap_items where gh_number=1258').fetchone())
print('rating1258', json.dumps(row))
print('provisional1258', 'ratings_provisional: true' in Path('PROJECT/1-INBOX/GH-1258-IDEA-SKILL.md').read_text())
print('tier_folders', [str(p) for p in Path('skills').glob('*/idea')])
print('index_rows', sum('[idea](skills/1-hourly/idea/SKILL.md)' in l for l in Path('ARCHITECTURE.md').read_text().splitlines()))
PY
```

Decisive output beyond finding 3: both inputs parsed four criteria. `intake_removed []`; `intake_added [' M releases.db', ' M releases.sql', '?? PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md']`; #1258 row `rmi-01M66S1Y01WM5BWJS9XCKBXRWG` scores 80/55/50/65, override null; `provisional1258 True`; one tier folder and one index row.

**Probe B — exact command, exit 0 (hash and manual index control):**

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
PYTHONPATH="$PWD/utils/py" python3 - <<'PY'
import hashlib,re
from pathlib import Path
ev=Path('TESTS-RESULTS/2026-10-30+GH-1258')
for variant,old,new in [('STALE','"pattern": "possible duplicate open issue"','"pattern": "title carries rating grammar"'),('NOTREADY','"artifacts": [ "utils/hq/hq-title-guard.sh" ]','"artifacts": [ "utils/hq/hq.sh" ]')]:
    text=(ev/'red-controls'/('GH-1263-'+variant+'.mutated.md')).read_text()
    assert text.count(old)==1
    body=text.split('## Idea\n\n',1)[1].split('\n\n## Why\n',1)[0].replace(old,new)
    lines=body.splitlines(keepends=True)
    footer=lines[-1]
    expected=re.search(r'hash ([a-f0-9]{64})',footer).group(1)
    measured=hashlib.sha256(''.join(lines[:-1]).encode()).hexdigest()
    print(variant,'original-body reconstruction',len(body),'bytes','hash_match',measured==expected,measured)
    headings=re.findall(r'^## (.+)$',body,re.M)
    print('headings',headings)
index=Path('ARCHITECTURE.md').read_text()
row='[idea](skills/1-hourly/idea/SKILL.md)'
assert index.count(row)==1
mutated='\n'.join(l for l in index.splitlines() if row not in l)
print('index fixed-string before',index.count(row),'after row removal',mutated.count(row))
PY
```

Decisive output: both reconstructions `8253 bytes hash_match True` with the recorded hash; all eleven headings present; `index fixed-string before 1 after row removal 0`. Mutations were in-memory strings only.

**Verification boundary:** No git, live writer, full preflight, validate.sh, test/*.sh, pytest or executable fixture ran here. Seeded logs/provenance are retained author evidence; clone-only execution was not repeated. Final-commit gate qualification is **[Unverified — needs clone run]**, explicitly left to the harness, not an additional finding. Only this relay file was edited; scratch stayed under .relay-scratch/. Commit is harness-owned. Return to claude for the four bounded corrections and missing manual receipts.

VERDICT: FAIL
Basis: Source trace and non-mutating parser/hash/SQLite/snapshot checks support the standard dogfood, but target consistency, tier branches, title-token exclusions and required refusal evidence remain incomplete against Phase 1 acceptance.

## Author response — round 1 dispositions (claude)

All four Shoulds accepted and implemented in commit `9a750392` (skill text + receipts; no code under `utils/`, no new test).

- **1 target resolution → Implemented** @ `skills/1-hourly/idea/SKILL.md` Step 0: `TARGET=$(bash "$HQ_SH" resolve <project> | sed -n 's/^REPO_PATH=//p')`, caller/target mismatch printed once, recon SHA must resolve in the target; Steps 8–11 use `--root "$TARGET"`, `$TARGET/PROJECT/1-INBOX/…`, `gh -C "$TARGET"`, `--target-root "$TARGET"`, and the report names `$TARGET`. Smoke table gains the "0 target" row recording that the dogfood caller was the task clone and the resolved target the primary.
- **2 trivial/spike branches → Implemented** @ Step 2 (trivial = issue-first exemption, prints the exemption line and files nothing; spike = no contract, Steps 5–9, then `NEEDS-SPIKE` instead of preflight) and Step 10 (spike branch). Witnesses: `TESTS-RESULTS/2026-10-30+GH-1258/trivial-tier-witness.txt` (status 7→7, HEAD unchanged, no gh call) and `spike-tier-body.md` + `spike-tier-preview.log` (body check `ok spike`, preview rendered, `NEEDS-SPIKE` line, nothing filed). Guardrails updated.
- **3 title token rule → Implemented** @ Step 7: presence rule `(^|[^[:alnum:]_])(rated|ovr)[[:space:]]+[0-9]` checked with `grep -Eiq` before preview; lists `rated 5/5`, `rated 70`, `ovr 200` as refused forms; the malformed-after-creation failure is explained there.
- **4 refusal witnesses + receipt → Implemented** @ Step 5: a runnable body check (python block in the skill; extracted verbatim to `body-check/bodycheck.extracted.py`) refuses missing/empty headings, non-checkbox Acceptance, missing or boilerplate axis rationales, 1–5-scale axes, a missing contract (standard tier) and a bad footer. Witnesses in `body-check/witnesses.txt`: #1263 body ok (exit 0); eleven empty headings refused (exit 1); boilerplate rationale refused (exit 1); prose acceptance refused (exit 1); spike body without contract ok. Second `roadmap rate` refused `already-rated` exit 3 with row unchanged (`roadmap-rate-second-write-refused.log`). Step 10's exact report line and its replay for the STALE control (`red-controls/stale-report-replay.txt`). Receipt grep corrected to `grep -cF` (returns 1); provenance rows appended (16 rows, valid JSONL).

**Verification:** `python3 body-check/bodycheck.extracted.py` on the five inputs (exit codes recorded); `grep -cF` → 1; the skill's description stays 754 chars. Textual for the skill prose; behavioural for the check, the rate refusal and the preflight controls.
**Re-review this:** Steps 0, 2, 5, 7, 10 of the skill; `smoke.md` sections "Step 5 body check", "Rating: second write refused", "Trivial and spike tiers", "Title token rule"; acceptance accounting for items 2, 5, 7.
**Commit:** `9a750392` (this turn's thread commit follows).


### Round 2 · Reviewer · codex · 2026-10-30

**Changes requested — 0 Blockers, 1 Should.** Round-1 findings 2–4 are addressed by the revised instructions and retained manual receipts. Finding 1 is substantially addressed, but its new comment command uses an unsupported CLI option and cannot complete Step 9. Reversibility: **Easy**; the remaining correction is confined to skill text. The relevant assumption is that GitHub CLI accepts Git's directory-selection flag; the help-only negative control disproves it.

1. **[Should] Replace `gh -C` with a supported repository selector.** `skills/1-hourly/idea/SKILL.md:47-48,188-189` instructs `gh -C "$TARGET" issue comment N --body-file dispositions.md`. GitHub CLI does not support `-C`: the command fails during option parsing, before the dispositions comment can be posted. Both standard and spike paths reach Step 9 after filing and rating, leaving their required dispositions record unwritten. The historical main-path comment receipt used `gh issue comment`, not this revised command (`TESTS-RESULTS/2026-10-30+GH-1258/smoke.md:17`), so it cannot validate the new spelling.
   - Use the issue URL returned by `hq park` directly, e.g. `gh issue comment "$ISSUE_URL" --body-file dispositions.md`, or use `--repo <resolved owner/repo>`. Remove the `-C` advice in Step 0 as well. The URL form keeps the resolved target explicit and requires no additional locator, writer or directory change. A help-only syntax witness is sufficient for this correction; do not post a duplicate comment just to test it.
   - **Root cause:** target pinning was expressed using a Git option on `gh`; **fix site:** the two new skill instructions above; **why here:** the existing CLI already accepts an issue URL and `--repo`.
   - **Exact negative probe:** `gh -C "$PWD" issue comment --help` → **exit 1**, decisive output `unknown shorthand flag: 'C' in -C`.
   - **Exact positive syntax control:** `gh issue comment https://github.com/HiQS-Labs/XYZ-forge/issues/1263 --help` → **exit 0**, decisive output `gh issue comment {<number> | <url>} [flags]` and inherited `-R, --repo [HOST/]OWNER/REPO`. Both calls were help-only; neither sent a comment or exercised authentication.

**Round-1 dispositions and acceptance accounting:**

- **[Pass] Targeted ledger and preflight operations.** `skills/1-hourly/idea/SKILL.md:27-52,175-196` now resolves HQ's REPO_PATH, explains the task-clone/primary difference, pins rating/read-back with `--root "$TARGET"`, and pins capture/preflight with the target path. The GitHub comment operation is the sole remaining Should above. Recon must resolve in the target. Smoke `:9` explicitly records the differing caller and target.
- **[Pass] Tier branch instructions.** Skill `:59-67,191-193,227` now stops trivial intake with the issue-first exemption and routes spike intake through filing/rating/commenting before reporting NEEDS-SPIKE without contract-dependent preflight. Retained `trivial-tier-witness.txt:1-5` supplies the no-write receipt. `spike-tier-preview.log:1-6` supplies preview rendering and the NEEDS-SPIKE report; `smoke.md:52` correctly calls this **preview only**, not an executed spike publication. Actual spike `--create` remains unverified by that receipt; the existing standard dogfood witnesses the shared HQ writer. No additional public spike is requested for the command correction above.
- **[Pass] Title-token exclusion.** Skill `:158-170` rejects rated/ovr token-presence forms before preview, including truncated ratings and orphan overrides. This addresses the parser failure traced in round 1; the case-insensitive grep is conservatively broader than the parser's lowercase rule. No runtime fix for #1263 is assumed present.
- **[Pass] Required refusal evidence and receipt correction.** Skill `:104-130` explicitly refuses the malformed draft before publication. `body-check/witnesses.txt:1-5` records the positive standard/spike inputs and empty-heading, boilerplate-PRS and prose-Acceptance red controls. The extracted checker matches the embedded block. `roadmap-rate-second-write-refused.log:1`, `provenance.jsonl:12` and `smoke.md:47` retain the already-rated refusal, exit 3, with unchanged-rating read-back. `red-controls/stale-report-replay.txt:1` now names issue, doc, row, STALE exit 4 and the deliberately wrong satisfied probe. `smoke.md:61` corrects the index check to fixed-string grep and acknowledges the original false receipt. These close round-1 finding 4 without adding a suite or registry entry.
- **[Pass] Other Phase 1 claims remain supported within the prior verification boundary.** `ARCHITECTURE.md:49,60` has the hourly count and skill row; the main body retains eleven headings, four extractable Acceptance items, contract and matching footer hash. The read-only #1258 row remains 80/55/50/65 with null override, and its capture retains `ratings_provisional: true`. The 16-record provenance file and retained READY/STALE/NOT-READY, write-set and gh660 receipts remain author evidence. No admission marker, forced rerating, new ledger table, new test suite or change to a runtime writer is called for by the revision. Acceptance items 1–6 and 8 otherwise retain round 1's supported conclusions; item 7 now has the intended textual branches with the preview qualification above.

**Verification boundary:** This turn used source/receipt reads, pure parser/hash/string inspection, read-only SQLite, and the two help-only CLI controls. It did not execute the retained checker/fixtures, any git command, a live writer, preflight, validate.sh, test/*.sh or pytest. Final-commit gate qualification remains **[Unverified — needs clone run]**, owned by the harness. The lesson at `LESSONS-LEARNED.md:38-83` was inspected; this revision does not tighten an existing hosted receipt gate. Only this relay file was edited; scratch remained under .relay-scratch/. Return to claude for the bounded command correction and syntax receipt.

VERDICT: FAIL
Basis: The prior tier/title/refusal corrections are supported, but the newly introduced `gh -C` command deterministically exits 1 and prevents the required dispositions comment on every filing path.

## Author response — round 2 dispositions (claude)

- **1 `gh -C` → Implemented** in `074c78c6` @ `skills/1-hourly/idea/SKILL.md` Step 0 ("`gh issue comment` addressed by the issue **URL** that `hq park` printed (or `--repo OWNER/REPO`; `gh` has no `-C`)") and Step 9 (`gh issue comment "$ISSUE_URL" --body-file dispositions.md`, with the `{<number> | <url>}` / `-R` note). Witness `TESTS-RESULTS/2026-10-30+GH-1258/gh-comment-syntax-witness.txt` (URL-form `--help` exit 0; `-C` form exit 1) and a provenance row. The defect also reproduced live: two filings made through the skill after round 1 (#1265, #1266) hit the `-C` failure at Step 9 and their dispositions were re-posted by URL; the receipt records that.

**Verification:** `grep -c 'gh -C' SKILL.md` → 0; the two help-only controls as above. No other file changed.
**Re-review this:** Step 0 and Step 9 wording only.
**Commit:** `074c78c6`.


### Round 3 · Reviewer · codex · 2026-10-30

**Ship — 0 Blockers, 0 Shoulds.** The round-2 command correction resolves the last requested change. Reversibility: **Easy**, confined to skill wording and a manual syntax receipt. The relevant assumption is that addressing the returned issue URL selects the target independently of the caller's checkout; the installed CLI's accepted syntax supports that assumption.

- **[Pass] Supported, target-pinned comment command.** `skills/1-hourly/idea/SKILL.md:47-50,188-191` now directs `gh issue comment "$ISSUE_URL" --body-file dispositions.md`, explicitly sourcing the URL from HQ's Step 8 output. Step 0 and Step 9 agree; neither instructs `gh -C`. Both standard and spike publication paths can reach the existing dispositions writer using supported syntax. No additional writer, locator, runtime flag or admission operation is introduced.
- **[Pass] Retained receipt matches independent syntax checks.** `TESTS-RESULTS/2026-10-30+GH-1258/gh-comment-syntax-witness.txt:1-2` and `provenance.jsonl:17` record the accepted URL form and rejected directory flag. Independent help-only controls below reproduce both outcomes. The receipt's additional claim about live #1265/#1266 comments is author evidence; this approval does not depend on independently establishing those postings.
- **[Pass] Prior acceptance accounting retained.** The round-1 and round-2 source/receipt findings remain applicable: target resolution, tier branches, rating-token exclusion, body/refusal controls, rating semantics, retained READY/STALE/NOT-READY evidence, bounded write-set and scope are addressed. The spike witness remains **preview only**, as explicitly qualified in round 2 and `smoke.md:52`; no new executed spike-publication claim is made. This round verifies the requested Step 0/Step 9 correction without reopening settled requirements.

**Independent probes (outer Python probe exit 0):**

Setup: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`. Python used `subprocess.run(..., text=True, capture_output=True)` for the following exact argument-equivalent commands and verified nonempty output:

```bash
gh issue comment https://github.com/HiQS-Labs/XYZ-forge/issues/1263 --help
# exit 0
# gh issue comment {<number> | <url>} [flags]
# -R, --repo [HOST/]OWNER/REPO   Select another repository using the [HOST/]OWNER/REPO format

gh -C "$PWD" issue comment --help
# exit 1
# unknown shorthand flag: 'C' in -C
```

The second command is the witnessed red control. Neither command sent a comment or exercised authentication. Non-mutating string/JSON inspection additionally reported `obsolete gh -C occurrences: 0`, `URL comment command occurrences: 1`, and `provenance_records: 17 latest_log: gh-comment-syntax-witness.txt`.

**Verification boundary:** Only source/receipt reads, in-memory string/JSON checks and help-only CLI probes ran this turn. No git command, live writer, executable fixture, retained checker, preflight, validate.sh, test/*.sh or pytest ran. Final-commit gate qualification remains **[Unverified — needs clone run]**, owned by the harness after this turn; Approved records independent artifact QA, not that unexecuted gate. The applicable lesson in `LESSONS-LEARNED.md:38-83` was inspected; this correction does not tighten a hosted evidence gate. Only this relay file was edited, and scratch remained under .relay-scratch/. Commit remains harness-owned.

VERDICT: PASS
Basis: Both revised instructions use the supported issue-URL comment form, independently witnessed with an exit-0 syntax check and exit-1 red control; the remaining Phase 1 findings were resolved in prior rounds, with their stated evidence limits preserved.

### Attestation · relay-drive — 2026-10-30T16:51:03Z
task: RELAY-gh1258-final-qa
reviewer: codex
status: Approved
reviewed-head: 6c840741620ea639fc94f5e91a69a744bfdfa16c
added-range: 29290+3731
added-sha256: 4167755ec0fab2238c0dbd1829196697d66a61dbee62e33e2a569d83ce3f751a
