# RELAY · PR1044 expanded landing review
NEXT: codex-producer
STATUS: Open
ROUND: 2 / 3

## Setup
Operator requests merging PR1044 and Skills Army deployment, explicitly choosing repair/review of the full expanded planner scope. Review the complete final diff against origin/development. Original peer head b706ac89 is preserved in ancestry; ledger conflicts were resolved disjointly through the supported writer at 5f2b8bb8. Production repair is80338e0d; this packet adds only immutable evidence.

Scope: skills/1-hourly/recon/SKILL.md, skills/2-daily/review-code/SKILL.md, weekly-planner/SKILL.md + scripts/planner_core.py, daily-planner/SKILL.md, capture and metadata. N+1 requires exact consumer behavior, logical boundary through wrappers, retry/parameter roles and conditional rollout compatibility. Existing neutral skipped-independent-review notes must survive. Planner must ground native input in successful complete live GitHub data; preserve native empty/filter-empty; scope repo rows; exclude cut releases; retain ratings/risk/build metadata on common DB/CLI path; retain deferred vision work; keep held/cyclic dependents out of landing instructions; do not classify ordinary validation receipts as held. Team/blocker prose is calibrated to actual implementation.

Verification already run in separate disposable full clone:26 manual outcomes (original five failed witnesses, repaired passes, in-memory guard negative control, original five fixture replay), live weekly generation, source ledger hashes unchanged, manifest12 shipped/8 dialed-in for0.6.0, existing GH777 inventory ratchet plus negative control. Receipts and exact probe inputs under TESTS-RESULTS/2026-10-14+GH-1043. The unapproved new test suite is removed; original input is retained only as manual evidence. Full publication gate remains pending after QA.

Review source first, especially degraded native input, dependency ordering, holds, selected repository, release metadata and daily downstream rendering. Graph project XYZ-forge generation2026-09-01 is stale and lacks planner paths; use exact source and bounded reads. Read-only review; do not run test/*.sh, validate.sh, or mutate any artifact other than this thread. No new code/tests, no git commands. One-off nonmutating in-memory checks are allowed, with no bytecode or generated files. Report actual actionable bugs with file:line; unknowns stay unknown, do not invent unrelated scope.

## Log
### Round1 · Producer
Implemented the bounded repairs; all recorded focused/manual verification passed. Independent final review is requested before publication/merge.

## Reviewer instructions
APPEND your whole review block at ABSOLUTE EOF after all existing text. Do not insert above any current block or marker. Change only NEXT/STATUS/ROUND in the header. Write VERDICT: PASS, FAIL, or PARKED and a nonempty Basis. On PASS set STATUS: Approved, NEXT: —, and mark task RELAY-GH1044-LANDING-20261014 done. Keep actionable findings concise and confidence grounded. This thread is the sole allowed writable path.

### Round1 · Reviewer codex
VERDICT: FAIL

Basis: Two required planner contracts still fail against the actual ledger and canonical CLI output. Reviewed the expanded source and skill diffs against locally recorded origin/development `3473ba8cbde89c5b671529c0b006364b543fb2ed`, using read-only object decoding without Git commands; reviewer checkout HEAD is `0200a96279c5fd2c8d6279324fb75b9c1fd4d494`. Read the capture, ledger metadata and committed manual evidence. Graph project `XYZ-forge`, generation `2026-09-01T15:54:30Z`, has no planner results and marks these paths untracked; exact source reads supplied the evidence.

1. **[Blocker — high confidence] Canonical deferred rows enter the active queue.** `skills/3-weekly/weekly-planner/scripts/planner_core.py:882` derives `is_deferred` only from title/raw prose, ignoring `section`. The real ledger places GH-920 and GH-974 in `Deferred · vision`, with paused markers, yet both return in `roadmap_items` with `is_deferred=False`. The consumer at `:924` consequently sends them into active candidates, and `main` publishes those as weekly `tasks` at `:1331`. GH-916 is correctly deferred only because its title begins `Deferred:`. Respect the canonical deferred section (and supported explicit pause semantics) before assigning active work; retain these rows in `deferred_items`. Probe command below exited **0** and printed `active deferred rows: [(920, 'Deferred · vision', False), (974, 'Deferred · vision', False)]`, with control `deferred prefix control: [916]`. Root cause: disposition is inferred from prose instead of the authoritative section; fix site: intake classification, before assignment, rather than hiding tasks in a renderer.

2. **[Blocker — high confidence] Actual CLI fallback loses PRS ratings and risk.** The fallback at `skills/3-weekly/weekly-planner/scripts/planner_core.py:830` assumes the CLI supplies the fields consumed at `:873`, but `utils/py/releases_app.py:4439`–`:4445` emits none of `rating_pri/sev/appeal/effort/ovr` or `risk`. With the actual reader output and a controlled direct-reader failure, all **64** scored active tasks become unscored; GH-418 changes from **321** to **None**. Missing risk also takes the default non-gated branch at `planner_core.py:875`. The recorded `cli_scoring_risk_build` check supplies a fabricated enriched CLI row, so it cannot establish this producer/consumer contract. Extend the canonical JSON reader contract or use an existing supported source that preserves these fields; do not report native scored/gated parity from this fallback as written. Probe command below exited **0** and printed `actual CLI rows: 355`, `rating/risk keys: []`, `scored DB/CLI: 64 0`, and `GH-418 DB/CLI: [321, None]`. Root cause: the fallback producer does not export the metadata its new consumer requires; fix the source contract rather than inventing a second scoring parser.

#### Exact read-only probe for both findings
The GitHub input is the committed snapshot, not a new live lookup. The actual CLI reader function runs with its connection pinned read-only and root discovery stubbed, so no Git command or executable fixture runs. Milestone data is held constant to isolate the roadmap fallback.

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import patch
from contextlib import redirect_stdout
from io import StringIO
import sqlite3, json
root=Path.cwd()
def load(p):
 m=ModuleType(p.stem);m.__file__=str(p);exec(compile(p.read_text(),str(p),"exec"),m.__dict__);return m
m=load(root/"skills/3-weekly/weekly-planner/scripts/planner_core.py")
r=load(root/"utils/py/releases_app.py");connect=sqlite3.connect
live={i["number"]:i for i in json.loads(Path("TESTS-RESULTS/2026-10-14+GH-1043/manual/open-issues-snapshot.json").read_text())}
def ro(p):
 c=connect(f"file:{p}?mode=ro",uri=True);c.row_factory=sqlite3.Row;return c
buf=StringIO()
with patch.object(r,"resolve_root",return_value=root),patch.object(r,"artifact_paths",return_value={"db":root/"releases.db"}),patch.object(r,"connect",side_effect=ro),redirect_stdout(buf):
 r.cmd_roadmap_list(SimpleNamespace(root=str(root),as_json=True))
with patch.object(m,"ensure_temp_dir",return_value=root/".relay-scratch/tmp"),patch.object(m,"get_open_issues",return_value=live),patch.object(m,"run_cmd",return_value=""):
 milestones=m.get_release_milestones(root,"HiQS-Labs/XYZ-forge");db=m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
with patch.object(m,"ensure_temp_dir",return_value=root/".relay-scratch/tmp"),patch.object(m,"get_open_issues",return_value=live),patch.object(m,"get_release_milestones",return_value=milestones),patch.object(m,"run_cmd",return_value=buf.getvalue()),patch.object(sqlite3,"connect",side_effect=sqlite3.OperationalError("direct reader unavailable")):
 cli=m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
print("active deferred rows:",[(i["gh_number"],i["section"],i["is_deferred"]) for i in db["roadmap_items"] if i["gh_number"] in (920,974)])
print("deferred prefix control:",[i["gh_number"] for i in db["deferred_items"] if i["gh_number"]==916])
rows=json.loads(buf.getvalue());print("actual CLI rows:",len(rows));print("rating/risk keys:",sorted(set(rows[0]) & {"rating_pri","rating_sev","rating_appeal","rating_effort","rating_ovr","risk"}))
print("scored DB/CLI:",sum(i["prs_score"] is not None for i in db["roadmap_items"]),sum(i["prs_score"] is not None for i in cli["roadmap_items"]))
print("GH-418 DB/CLI:",[next(i["prs_score"] for i in x["roadmap_items"] if i["gh_number"]==418) for x in (db,cli)])
PY
```

#### Confirmed repairs and limits
- `planner_core.py:448`–`:466`: additional in-memory calls confirmed held-chain ready `[]` (original head returned `[2, 3]`), cyclic ready `[3]`, prerequisite order `[1, 2]`, and ordinary validation-receipt ready `[1]`. The held-chain daily renderer emitted no `P0 ACTION: Land PR` (`:1226`). Native zero-open intake remained `native_prs` with zero tasks (`:861`). These observations agree with the recorded original-failure receipts.
- `recon/SKILL.md:84`–`:103` and `review-code/SKILL.md:150`–`:166` establish exact consumer advancement, transparent delegation, retry/parameter roles, and conditional rollout/rollback checks. The baseline comparison does not remove an existing skipped-independent-review note.
- Read-only ledger hashes match the recorded receipts: `releases.db` `13beb45f7e1bca3bc4dd85ee775fd63397351ee358b4d39ceda2aceda9f0043d`; `releases.sql` `853d7a6cf3d9208a5892ff240f971790418726e4babf5ec1ae005fb2e375d8c6`.
- **[Unverified — needs clone run]** Full publication gate remains pending. No validate/test/pytest/fixture execution was performed here. GitHub refresh failed (`gh pr diff 1044 --repo HiQS-Labs/XYZ-forge`, exit 1: `error connecting to api.github.com`); origin freshness beyond the recorded local baseline and IDE discovery/deployment are unverified. No approval, merge, or deployment attestation is given.

Handoff: repair the two intake contracts, record actual producer/consumer evidence using existing/manual verification, then return for independent review. Only this relay file was changed outside permitted scratch and pinned tick state.

### Round 2 · Producer
Both Round1 findings are repaired at28c014b6. Canonical deferred sections / pause markers route to deferred_items before assignment; actual canonical roadmap JSON now additively exports all five RATING_COLUMNS plus risk through _col. Native repository identity follows settings.repo_slug, matching the canonical CLI, including full owner/repo slugs. Known JSON consumers (site_build.py and hq/rollup.sh) read required keys and tolerate extras. No schema change/new suite/gate.

Verification: reran26 prior manual outcomes; actual355-row canonical CLI fallback equals DB for79 active candidates,62 scored, risk/build flags and GH-418 score321. Both GH-920/GH-974 remain parked in both modes. Removing producer metadata / canonical deferral guards reproduced failures. Existing GH646 suite42/42 and GH777 ratchet passed in the separate full verify clone. Exact inputs/outputs/provenance under TESTS-RESULTS/2026-10-14+GH-1043/manual/round2. Full publication gate remains running on the preceding head and will be rerun for the production follow-up.

Review the follow-up and confirm previous repairs remain intact. APPEND at absolute EOF with exact heading `### Round 2 · Reviewer (codex)`, VERDICT: PASS or FAIL and nonempty Basis. On PASS set STATUS: Approved, NEXT: —, and mark RELAY-GH1044-LANDING-20261014 done. Do not rewrite any previous body block.


### Round 2 · Reviewer (codex)
VERDICT: FAIL

Basis: Both Round1 findings are repaired, and prior bounded planner checks still pass. One required selected-repository contract remains broken on the degraded native CLI path. Reviewed expanded source against locally recorded origin/development `3473ba8cbde89c5b671529c0b006364b543fb2ed` by read-only object decoding, without Git commands. Seeded HEAD is `2b76b11add161c92748fe76a7cc740b2f2d5cd7b`, containing production follow-up `28c014b6`. Graph project `XYZ-forge`, generation `2026-09-01T15:54:30Z`, is stale/not tracking planner paths; exact source reads supplied the evidence.

1. **[Blocker — high confidence] Native CLI fallback still mixes repositories.** `skills/3-weekly/weekly-planner/scripts/planner_core.py:830` invokes the unscoped JSON reader. Unlike the direct reader's `WHERE repo_id = ?` at `:822`, `utils/py/releases_app.py:4438` selects every roadmap row and exports no repository identity. URL checks at `planner_core.py:864`–`:869` apply only when a URL exists, but the canonical schema permits null `issue_url` and issue numbers are unique per repository (`releases_app.py:634`–`:651`). On a shared ledger with an imported URL-less foreign row whose issue number overlaps a selected-repository open issue, direct-reader failure schedules foreign work as selected-repository work. The producer's `repo_scoped_roadmap` manual check covers only the direct reader. Preserve selected-repository identity through the canonical JSON seam (or provide a supported scoped reader), and apply it before assignment. Check existing consumers before changing the default scope of all JSON reads.

   Probe below copies the seeded read-only ledger into memory and adds one foreign row **in memory only**. It invokes the actual canonical reader, holds live input constant at the committed 242-issue snapshot, and compares direct vs degraded CLI intake. No foreign row in production is claimed. Command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/repo_scope_probe.py` exited **0**. Decisive output:

   ```text
   DB GH418 titles: ['Marathon planner still reads the frozen ROADMAP.md']
   CLI GH418 titles: ['Marathon planner still reads the frozen ROADMAP.md', 'Foreign repository work']
   CLI repo identity keys: []
   ```

#### Exact nonmutating scope probe

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY_SCOPE'
from pathlib import Path
from types import ModuleType,SimpleNamespace
from unittest.mock import patch
from contextlib import redirect_stdout
from io import StringIO
import sqlite3,json
root=Path.cwd()
def load(p):
 m=ModuleType(p.stem);m.__file__=str(p);exec(compile(p.read_text(),str(p),"exec"),m.__dict__);return m
m=load(root/"skills/3-weekly/weekly-planner/scripts/planner_core.py");r=load(root/"utils/py/releases_app.py");realconnect=sqlite3.connect
def memory():
 src=realconnect(f"file:{root/'releases.db'}?mode=ro",uri=True);dst=realconnect(":memory:");src.backup(dst);src.close();dst.row_factory=sqlite3.Row
 dst.execute("PRAGMA foreign_keys=ON")
 dst.execute("INSERT INTO repos (global_id,slug) VALUES ('repo-01ARZ3NDEKTSV4RRFFQ69G5FAV','Other/Project')")
 other=dst.execute("SELECT id FROM repos WHERE slug='Other/Project'").fetchone()[0]
 row=dict(dst.execute("SELECT * FROM roadmap_items WHERE gh_number=418").fetchone());row.pop("id")
 row.update(repo_id=other,global_id="rmi-01ARZ3NDEKTSV4RRFFQ69G5FAV",title="Foreign repository work",issue_url=None,raw_text="")
 keys=list(row);dst.execute("INSERT INTO roadmap_items ("+",".join(keys)+") VALUES ("+",".join("?" for _ in keys)+")",list(row.values()))
 return dst
buf=StringIO()
with patch.object(r,"resolve_root",return_value=root),patch.object(r,"artifact_paths",return_value={"db":root/"releases.db"}),patch.object(r,"connect",side_effect=lambda p:memory()),redirect_stdout(buf):
 r.cmd_roadmap_list(SimpleNamespace(root=str(root),as_json=True))
live={i["number"]:i for i in json.loads(Path("TESTS-RESULTS/2026-10-14+GH-1043/manual/open-issues-snapshot.json").read_text())}
with patch.object(m,"ensure_temp_dir",return_value=root/".relay-scratch/tmp"),patch.object(m,"get_open_issues",return_value=live),patch.object(m,"get_release_milestones",return_value={}):
 with patch.object(sqlite3,"connect",side_effect=lambda *a,**k:memory()):
  db=m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
 with patch.object(sqlite3,"connect",side_effect=sqlite3.OperationalError("controlled direct-reader failure")),patch.object(m,"run_cmd",return_value=buf.getvalue()):
  cli=m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
print("DB GH418 titles:",[i["title"] for i in db["roadmap_items"] if i["gh_number"]==418])
print("CLI GH418 titles:",[i["title"] for i in cli["roadmap_items"] if i["gh_number"]==418])
print("CLI repo identity keys:",sorted(set(json.loads(buf.getvalue())[-1]) & {"repo_id","repo_slug"}))
PY_SCOPE
```

#### Confirmed repairs and limits

- Read-only command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/round2_probe.py` exited **0**. Actual JSON reader: **355 rows**, all five rating keys plus risk. Real-ledger DB/CLI parity: **79 active / 62 scored**, GH-418 **321**, GH-920/GH-974 parked in both. In-memory metadata removal produced **0 scored**; in-memory canonical section/pause guard removal returned **[920, 974]** to active work. These independently confirm committed round2 producer-contract evidence.
- Same probe: held-chain ready **[]**, cyclic ready **[3]**, prerequisite order **[1, 2]**, ordinary validation-receipt ready **[1]**, no held-chain daily `P0 ACTION: Land PR`, native empty **['native_prs', 0]**, unavailable/invalid/truncated live issue input rejected. Target release **0.6.0**, manifest **12 shipped / 8 dialed-in**.
- Ledger hashes unchanged: `releases.db` `13beb45f7e1bca3bc4dd85ee775fd63397351ee358b4d39ceda2aceda9f0043d`; `releases.sql` `853d7a6cf3d9208a5892ff240f971790418726e4babf5ec1ae005fb2e375d8c6`.
- Source confirms exact consumer advancement, transparent delegation, retry/parameter roles, and conditional rollout/rollback in N+1 instructions. The unapproved `test/test_planner_core.py` remains absent. JSON additions are additive; `utils/py/site_build.py:98` checks required-key inclusion and `utils/hq/rollup.sh:56` reads named fields, so those inspected consumers tolerate extra keys.
- `gh pr view 1044 --repo HiQS-Labs/XYZ-forge --json number,baseRefName,headRefOid,state` exited **0**: PR **OPEN**, base **development**, remote head **b706ac89f1695a314a14c4aaba70bc0bc83d5874**. Local repairs are not yet attested as the remote PR head.
- **[Unverified — needs clone run]** Final publication gate remains outstanding for the repaired candidate. GH646/GH777 passes are producer receipts, not reviewer reruns. No validate/test/pytest/executable fixture ran here. IDE discovery/deployment and current live issue refresh are unverified; probes use the committed snapshot. No merge or deployment approval is given.

Handoff: repair selected-repository filtering through the actual CLI fallback, record a bounded shared-ledger comparison using existing/manual verification, then return for independent review. Only this relay file changed outside permitted scratch and pinned tick state.
