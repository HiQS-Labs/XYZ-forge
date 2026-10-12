# RELAY · GH1022 Phase6 qualified Jog reader final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1022-phase6-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: utils/py/releases_app.py whole file; test/gh123-lock-progress-bound.sh whole file and unchanged production token policy; PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase6; phase6-jog-manual-results.json and phase6-plan relay
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Final QA genuinely new qualified Jog read seam and existing Linux fixture correction; whole owning-file sweep, legacy compatibility, real UNKNOWN/read-only/ownership/drift behavior, no execution permission, no CI case/assertion/registration addition. Own normal new-scope cap3 previously authorized; this cannot reopen/reset corrective accumulation R6FAIL6/6 or imply umbrella completion.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

Frozen candidate c08a432d, owner app source bound in phase6-jog-manual-results.json; plan Approved atbf6f389a, attested373fc7d7. Whole-file review mandatory for final owner source. New read seam: shared _jog_rows qualifies canonical join; legacy13 fields/filter/order/missing-table preserved; inventory --all explicit, one declared root only, read-only connect optional/default writers unchanged. Canonical repo helper/header/sidecar/journal/schema/generation functions reused. Invalid/missing ownership/schema/generation or observed drift =>UNKNOWN/nonzero/no rows/no dispatch; unregistered row retained held. All declared repositories must qualify and carry canonical GIDs. Quiet actualmodule/CLI24 controls pass atcurrent source, no new CI cases. Fixture data/schema/git/negative-control writes only in isolated temp roots, no connectors/builders.

Untouched developmentff895 Ubuntu38198894599 reproduces same existing gh123 failures as prior draft9ebe. Minimal existing PYMOVE file mode a+→w+ removes LinuxO_APPEND positional-write mismatch; no new case/params/assertion/registration, no production policy/bound/time change. Mac focused suites in disposable verification clone running at53b4a79c (before only added repository grammar check atc08); Jog34/34 passed, adapter/lock pending. Current exactcandidate full normal gate and corrected Linux hosted qualification remain pending, not claimed. Read baseline committed evidence and test+unchanged writer; do not run suites/fixture executables or live commands here. Harmless in-memory read probes allowed.

Important: R6 remains FAIL6/6 with Medium S5 title grammar gap trackedGH1028, three proposed individualtestsGH1027 unapproved. Do not reopen corrective R6, reset/replace its artifact, claim its source Approved, or downgrade tracked severity. This is genuinely new planned W7 prerequisite and in-scope existing CI fixture diagnosis, expressly authorized normal cap3. W7 global census/rollover/selection, W8 construction/readiness, W9freeze/approval,W10sharedfire/phase/resume/landing,W11audit remain active. Review source, plan and claims. Report other pre-existing owner defects with concrete input/scope/falsifier/severity; no blanket owner clearance without reading whole file. No source edits, extraagents, suites, pytest, fixture programs, connectors/network/production/Git writes except this relay. Handing off to Reviewer(codex)—take the final new-scope turn.

### Reviewer · Round 1

VERDICT: FAIL
Basis: The qualified Jog query passes the bounded checks below. The mandatory whole-owner sweep established one pre-existing Medium dashboard rendering defect requiring Producer disposition. This is the new final-QA round only; accumulation R6 remains FAIL6/6, GH1028 remains Medium, GH1027 remains unapproved, and W7–W11/weekly execution remain held. No umbrella or landing approval.

swept file: yes
Read all 7039 owner-source lines, all 102 gh123 fixture lines, the production telemetry writer, Phase6, complete plan relay and seeded manual/baseline evidence. S1 is the pre-existing defect established by this sweep; no blanket runtime clearance is claimed.

- [Should] S1 — Medium, pre-existing: dashboard renders ledger text as active HTML (`utils/py/releases_app.py:6595`). The actual renderer returned an unescaped image/event-handler element from a legal nonempty roadmap title. Release text and section names also enter HTML directly (`:6571`, `:6574`, `:6592`). Use standard-library HTML escaping at dashboard text interpolation boundaries, preserving stored text and other readers. Verify with recorded manual rendering controls; no new suite/case/gate requested. This is an owning-file finding, not corrective accumulation R6 re-review.
  Observed input: roadmap row `(section='Queue', gh_number=777, title='<img src=x onerror="alert(1)">', status_marker=NULL, position=1)`; actual renderer returned `<li> GH-777 <img src=x onerror="alert(1)"></li>` and `dashboard_escaped_markup: False`, exit0. No browser/JavaScript execution was attempted.
  Affected scope: stored text interpolated into cmd_dashboard HTML text nodes; this title meets the canonical nonempty title constraint and direct intake grammar. No identity-policy or JSON/markdown change requested.
  Falsifier: render this exact title and ordinary `A & B < C`; expected escaped text (`&lt;img...&gt;`, `A &amp; B &lt; C`), no active image/event-handler element, and unchanged ordinary title display. Current already-escaped output would falsify S1; measured output is raw.
- [Pass] Shared `_jog_rows` joins repo_id AND gh_number (`utils/py/releases_app.py:4613`). Fresh in-memory execution produced exactly one `Owner A` row for RepoA/B issue777, and retained `title=None` after deleting only the owning roadmap row. The exact 13 legacy fields remained `id,global_id,gh_number,position,status,attempt_count,lease_pid,failure_reason,created_at,updated_at,title,doc_path,issue_url`. Filter/order and legacy missing-table behavior remain explicit (`:4601`, `:4612`, `:4730`).
- [Pass] Read-seam source reuses connection/schema/journal/identity owners: quoted optional readonly URI/default unchanged (`utils/py/releases_app.py:432`), readonly inventory connection (`:4650`), schema6/positive generation (`:4661`, `:4665`), every declared repository and row GID (`:4675`, `:4688`), final generation/artifact checks before publishing (`:4707`). UNKNOWN starts with no rows/false completeness/dispatch (`:4634`); handler emits JSON and exits2 (`:4721`). These are source checks, not fresh filesystem/concurrency runs.
- [Pass] Seed source binding is exact: fresh SHA256 `aed2ae502b03ebd90a1526fb223716865dd947edc12eb658245f252c841403db` equals `phase6-jog-manual-results.json` source_sha256. Fresh evidence hash `0ffb3c99a38e792a3893df0ba5db917a302c5cc741d81fc779704db76553794d` matches retained `TESTS-RESULTS/2026-10-11+GH-1022/provenance.jsonl:158`. There are 24 controls/24 recorded passes; their module/CLI/drift checks were not independently rerun here.
- [Pass] Existing fixture correction uses `w+` (`test/gh123-lock-progress-bound.sh:63`) for the positional-write descriptor, preserving six locked handovers/pwrite/truncate and existing bounds/assertions (`:65`, `:68`, `:79`). Production uses O_RDWR|O_CREAT (`utils/telemetry/append-xyz-completion.sh:69`). Untouched-baseline evidence records moving-queue exit75 at2s (`TESTS-RESULTS/2026-10-11+GH-1022/ubuntu-baseline-failed.log:438`). This supports the fixture diagnosis; corrected Linux qualification is pending.
- [Unverified — needs clone run] Exact-candidate gate, focused release/Jog/adapter/lock runs and corrected Linux qualification remain outside this turn. No validate.sh, test/*.sh, pytest, executable fixture program, Git command, connector/provider/builder or live queue operation ran. Post-turn harness/disposable-clone evidence remains required. Reader denies dispatch (`utils/py/releases_app.py:4703`); W7–W11 remain active (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:645`).

Graph limitation: both list_projects pages omit this worktree. Nearest Forge graph is another checkout at generation `2026-09-01T15:54:30Z`; discovery is stale. Coverage reports metadata_changed for owner/test/writer and missing plan/evidence freshness. Direct current whole-source reads ground this review; no current exhaustive caller-graph claim or reindex mutation.

Quoted fresh probe command (definitions only; in-memory query/render reads, no main/writer/fixture program):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import ast, contextlib, hashlib, io, json, sqlite3
from pathlib import Path
from types import SimpleNamespace
p=Path('utils/py/releases_app.py'); source=p.read_text(); tree=ast.parse(source)
ns={'__name__':'review_probe','__file__':str(p.resolve())}
exec(compile(tree,str(p),'exec'),ns)
print('source_sha256:',hashlib.sha256(p.read_bytes()).hexdigest())
e=Path('TESTS-RESULTS/2026-10-11+GH-1022/phase6-jog-manual-results.json')
data=json.loads(e.read_text())
print('seed_source_matches:',data['source_sha256']==hashlib.sha256(p.read_bytes()).hexdigest())
print('seed_controls:',data['count'],len(data['controls']),sum(x['pass'] for x in data['controls']))
print('seed_sha256:',hashlib.sha256(e.read_bytes()).hexdigest())
c=sqlite3.connect(':memory:'); c.row_factory=sqlite3.Row
c.executescript('CREATE TABLE jog_queue(id,global_id,repo_id,gh_number,position,status,attempt_count,lease_pid,failure_reason,created_at,updated_at); CREATE TABLE roadmap_items(repo_id,global_id,gh_number,title,doc_path,issue_url); CREATE TABLE repos(id,global_id,slug);')
c.execute('INSERT INTO jog_queue VALUES(1,?,1,777,1,?,0,NULL,NULL,?,?)',('jog-'+'1'*26,'pending','2026-10-11','2026-10-11'))
for rid,title in [(1,'Owner A'),(2,'Foreign B')]:
 c.execute('INSERT INTO roadmap_items VALUES(?,?,777,?,NULL,?)',(rid,'rmi-'+str(rid)*26,title,'https://github.com/acme/'+('a' if rid==1 else 'b')+'/issues/777'))
rows=ns['_jog_rows'](c)
print('qualified_rows:',len(rows),[r['title'] for r in rows])
print('legacy_keys:',','.join(rows[0]))
c.execute('DELETE FROM roadmap_items WHERE repo_id=1')
print('unregistered_title:',ns['_jog_rows'](c)[0]['title'])
c.close()
# Run only the actual dashboard renderer on an in-memory read connection.
d=sqlite3.connect(':memory:'); d.row_factory=sqlite3.Row
d.executescript("CREATE TABLE settings(key,value); INSERT INTO settings VALUES('generation','1'); CREATE TABLE op_receipts(id); CREATE TABLE releases(version,codename,status,target_date,shipped_date,description,exit_criterion,id); CREATE TABLE manifest_items(release_id,state); CREATE TABLE roadmap_items(section,gh_number,title,status_marker,position);")
payload='<img src=x onerror="alert(1)">'
d.execute('INSERT INTO roadmap_items VALUES(?,777,?,NULL,1)',('Queue',payload))
ns['resolve_root']=lambda explicit: explicit
ns['artifact_paths']=lambda root: {'db':'/dev/null','dump':str(Path('.relay-scratch/tmp/missing-dump').resolve())}
original=sqlite3.connect
sqlite3.connect=lambda *args,**kwargs:d
try:
 out=io.StringIO()
 with contextlib.redirect_stdout(out): ns['cmd_dashboard'](SimpleNamespace(root='read-probe'))
 print('dashboard_raw_markup:',next(line.strip() for line in out.getvalue().splitlines() if payload in line))
 print('dashboard_escaped_markup:', '&lt;img' in out.getvalue())
finally: sqlite3.connect=original
PY
```

Exit status: 0. Decisive output:

```text
source_sha256: aed2ae502b03ebd90a1526fb223716865dd947edc12eb658245f252c841403db
seed_source_matches: True
seed_controls: 24 24 24
seed_sha256: 0ffb3c99a38e792a3893df0ba5db917a302c5cc741d81fc779704db76553794d
qualified_rows: 1 ['Owner A']
legacy_keys: id,global_id,gh_number,position,status,attempt_count,lease_pid,failure_reason,created_at,updated_at,title,doc_path,issue_url
unregistered_title: None
dashboard_raw_markup: <h2>Roadmap</h2><h3>Queue</h3><ul><li> GH-777 <img src=x onerror="alert(1)"></li></ul>
dashboard_escaped_markup: False
```

Handoff receipt: env-pinned claim succeeded first; env-pinned release --to author succeeded. A shell heredoc delimiter collision rejected the first relay-write command before it ran; the release had already been issued by the tool sequence. This corrected write changes only this relay. Reclaim was refused as spent/reserved; no new token was invented.

Handing off to Producer (author) — disposition S1 and return for the next new-scope final-QA turn; go to the author window and say 'take your turn'. Do not reopen/reset accumulation R6 or imply W7–W11 completion.

### Producer · Round 2

S1 Implemented at e6549bb7: standard-library html_escape at all seven stored-text interpolation boundaries plus derived issue text. Stored values and JSON/Markdown readers unchanged. Actual dashboard before emitted active img markup; after three inputs across seven boundaries all escaped/ordinary Unicode retained (source-bound before/after JSON). No browser/JavaScript execution or new CI test/case. Existing dashboard all pass, artifact10/10 in disposable e654 clone, clean. Actual Jog24 controls rerun with current owner sourcehash pass. Prior focused53b4 Jog34/34, adapter223/223, lock6/6 retained with exact source limits; final full normal gate and corrected Linux existingCI pending, not claimed.

Continue ONLY within previously authorized genuine Phase6 normal cap3; Round2/3 in this same artifact with all R1 history retained. Status checkpoint did not grant additional authority. Accumulation corrective R6FAIL6/6 remains closed/unchanged and MediumGH1028 tracked; do not reopen/reset it or call its source Approved. Whole final owner sweep remains required by this new-scope protocol; report any pre-existing finding with input/scope/falsifier/severity. No producer source edits beyond S1 and current status/history clarification. No new review budget, test approval, gate bypass, live execution or full1022 completion. W7–W11 active and weeklyHELD.

Review current exact HEAD/source/evidence; no source edits, agents, executable fixtures/suites/pytest, connectors/network/production writes or Git edits outside this relay. Harmless in-memory rendering/read probes permitted. Handing off to Reviewer(codex)—take Round2 within the existing cap.

### Reviewer · Round 2

VERDICT: FAIL
Basis: S1 is resolved on current source. The whole owning-file sweep established one additional pre-existing Low diagnostic defect, S2, requiring Producer disposition. No defect was established in the new qualified Jog read seam. This verdict is confined to the existing Phase6 final-QA cap3; corrective accumulation R6 remains FAIL6/6, GH1028 remains Medium, GH1027 remains unapproved, and weekly/W7–W11 remain held. No landing, execution or umbrella approval.

swept file: yes
Read all 7040 lines of utils/py/releases_app.py, the entire 102-line gh123 fixture and production telemetry writer, Phase6 and its current resumption, the complete plan/final relay histories, current manual JSON and retained suite/provenance evidence. S2 is the additional pre-existing defect established this turn; this sweep is not an exhaustive runtime/concurrency attestation.

- [Pass] S1 resolved: all seven stored-text boundaries use standard-library html_escape (utils/py/releases_app.py:6572, :6573, :6575, :6593, :6596), including derived issue text. Fresh actual-render controls below return seven escaped occurrences each for the exact malicious title, ordinary comparison text and Unicode; no active img markup. Current source SHA256 is ac72d6f83e75db54cb52ab7c5135a8a20fd358a1defbd32789bff8bdbf8bfad8. The R1 raw-markup failure remains the red control; no browser/JavaScript executed.
- [Should] S2 — Low, pre-existing: a present dump without a generation header prevents the entire dashboard from rendering its diagnostic warning. dump_generation_from_text returns None, which cmd_dashboard passes to the numeric %d formatter (utils/py/releases_app.py:6541, :6545). Keep the observation visibly stale/unavailable and render the dashboard; format the absent dump generation explicitly without changing canonical parsing, writing, recovery or acceptance policy. A recorded narrow manual control is sufficient; no new CI case/suite/gate requested. Producer may explicitly disposition this small owning-file diagnostic defect; it does not expand corrective R6.
  Observed input: existing dump bytes "-- releases-app canonical dump\n", DB settings generation="1", otherwise readable in-memory dashboard tables. Actual renderer produced no HTML and raised "TypeError: %d format: a real number is required, not NoneType". Probe exit0 catches and reports this renderer exception.
  Affected scope: dashboard rendering when a present dump has no parseable canonical generation header (including a truncated/empty dump); the DB remains independently readable. No request to accept the dump as canonical.
  Falsifier: run the quoted exact control with matching generation1, differing generation2, and the no-header bytes. Expected matching output without STALE SYNC, differing output with STALE SYNC, and no-header output with an explicit unavailable/stale warning and no exception. Already-rendered no-header output would disprove S2; current output fails.
  Root cause: dashboard assumes the canonical parser always returns an integer while diagnosing noncanonical dump state; Fix site: dashboard warning formatting; Why not upstream/downstream: parser's None accurately reports missing evidence and should remain unchanged.
- [Pass] Qualified Jog query still joins both repo_id and gh_number (utils/py/releases_app.py:4614). Fresh in-memory actual _jog_rows execution yielded one Owner A row beside Foreign B issue777; deleting only the owned roadmap row retained title=None. Exact legacy 13 fields/filter/order remain (:4602–:4627); inventory reads via readonly connect (:4651), validates all declared repositories/GIDs and generation (:4662–:4702), withholds rows on drift (:4708) and always denies dispatch (:4704). These source/bounded-query checks do not establish filesystem concurrency behavior.
- [Pass] Current Jog manual evidence binds the current source, contains 24 controls/24 recorded passes, and hashes to 7b26eb982d1f37a620feb924586ca16bb80376912727e129619fbd810614abc6; the dashboard-after JSON also binds current source and hashes to e2fe111ea3b4ef035d7c896cc11be1d3ec90ccf3c27991ff3198773cf6e001e1. Both are retained in TESTS-RESULTS/2026-10-11+GH-1022/provenance.jsonl (timestamp 2026-10-12T04:02:44). Seeded 24 filesystem/CLI controls were read, not independently rerun.
- [Pass] Fixture correction remains open(..., 'w+') (test/gh123-lock-progress-bound.sh:63) with the existing six handovers, pwrite/truncate and bounds (:65–:86); production O_RDWR|O_CREAT remains (utils/telemetry/append-xyz-completion.sh:69). Seeded e654 dashboard log ends "gh75-dashboard.sh: all pass"; artifacts log ends "10 pass, 0 fail", with matching recorded provenance entries at 2026-10-12T04:04:09. These are Producer clone receipts, not fresh suite executions by this reviewer.
- [Unverified — needs clone run] Exact-candidate normal gate and corrected Linux qualification remain pending as explicitly stated in the Phase6 resumption. No validate.sh, test/*.sh, pytest, executable fixture program, Git command, network/provider/connector/build execution or live queue operation ran here. No CI addition is requested. W7–W11 remain active and the inventory grants no execution authority (PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase6; utils/py/releases_app.py:4704).

Graph limitation: list_projects returned all82 entries with has_more=false and omitted this worktree. Nearest XYZ-forge graph refers to another checkout, generation2026-09-01T15:54:30Z. Coverage reported metadata_changed for owner/test/writer and missing freshness for plan/evidence. Direct current-source reads cover the material claims; no reindex or exhaustive caller-graph claim.

Quoted S1/source-binding probe command (definitions and in-memory renderer only; exit0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, contextlib, hashlib, io, json, sqlite3
from pathlib import Path
from types import SimpleNamespace
p=Path('utils/py/releases_app.py')
ns={'__name__':'review_probe','__file__':str(p.resolve())}
exec(compile(ast.parse(p.read_text()),str(p),'exec'),ns)
print('source_sha256:',hashlib.sha256(p.read_bytes()).hexdigest())
ns['resolve_root']=lambda root:root
ns['artifact_paths']=lambda root:{'db':'/dev/null','dump':str(Path('.relay-scratch/tmp/absent').resolve())}
original=sqlite3.connect
for value in ['<img src=x onerror="alert(1)">','A & B < C','Ordinary owner ✅']:
 c=original(':memory:');c.row_factory=sqlite3.Row
 c.executescript("CREATE TABLE settings(key,value); INSERT INTO settings VALUES('generation','1'); CREATE TABLE op_receipts(id); CREATE TABLE releases(version,codename,status,target_date,shipped_date,description,exit_criterion,id); CREATE TABLE manifest_items(release_id,state); CREATE TABLE roadmap_items(section,gh_number,title,status_marker,position);")
 c.execute('INSERT INTO releases VALUES(?,?,?,NULL,NULL,?,?,1)',(value,value,value,value,value))
 c.execute('INSERT INTO roadmap_items VALUES(?,777,?,?,1)',(value,value,value))
 sqlite3.connect=lambda *a,**k:c
 output=io.StringIO()
 try:
  with contextlib.redirect_stdout(output): ns['cmd_dashboard'](SimpleNamespace(root='read-probe'))
  rendered=output.getvalue()
  print(repr(value),'escaped_count:',rendered.count(ns['html_escape'](value)),'active_img:', '<img ' in rendered)
 finally: sqlite3.connect=original
base=Path('TESTS-RESULTS/2026-10-11+GH-1022')
for name in ['phase6-jog-manual-results.json','phase6-dashboard-after.json']:
 data=json.loads((base/name).read_text())
 print(name,'source_matches:',data['source_sha256']==hashlib.sha256(p.read_bytes()).hexdigest(),'sha256:',hashlib.sha256((base/name).read_bytes()).hexdigest())
 if 'count' in data: print('seed_controls:',data['count'],len(data['controls']),sum(x['pass'] for x in data['controls']))
PY
```

Decisive output:

```text
source_sha256: ac72d6f83e75db54cb52ab7c5135a8a20fd358a1defbd32789bff8bdbf8bfad8
'<img src=x onerror="alert(1)">' escaped_count: 7 active_img: False
'A & B < C' escaped_count: 7 active_img: False
'Ordinary owner ✅' escaped_count: 7 active_img: False
phase6-jog-manual-results.json source_matches: True sha256: 7b26eb982d1f37a620feb924586ca16bb80376912727e129619fbd810614abc6
seed_controls: 24 24 24
phase6-dashboard-after.json source_matches: True sha256: e2fe111ea3b4ef035d7c896cc11be1d3ec90ccf3c27991ff3198773cf6e001e1
```

Quoted S2 diagnostic probe command (definitions/in-memory DB; dump controls only under .relay-scratch; exit0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, contextlib, io, sqlite3
from pathlib import Path
from types import SimpleNamespace
p=Path('utils/py/releases_app.py')
ns={'__name__':'review_probe','__file__':str(p.resolve())}
exec(compile(ast.parse(p.read_text()),str(p),'exec'),ns)
original=sqlite3.connect
dump=Path('.relay-scratch/tmp/dashboard-header-control.sql').resolve()
ns['resolve_root']=lambda root:root
ns['artifact_paths']=lambda root:{'db':'/dev/null','dump':str(dump)}
for header in ['-- generation: 1\n','-- generation: 2\n','-- releases-app canonical dump\n']:
 dump.write_text(header)
 c=original(':memory:');c.row_factory=sqlite3.Row
 c.executescript("CREATE TABLE settings(key,value); INSERT INTO settings VALUES('generation','1'); CREATE TABLE op_receipts(id); CREATE TABLE releases(version,codename,status,target_date,shipped_date,description,exit_criterion,id); CREATE TABLE manifest_items(release_id,state); CREATE TABLE roadmap_items(section,gh_number,title,status_marker,position);")
 sqlite3.connect=lambda *a,**k:c
 output=io.StringIO()
 try:
  with contextlib.redirect_stdout(output): ns['cmd_dashboard'](SimpleNamespace(root='read-probe'))
  print(repr(header),'rendered:',bool(output.getvalue()),'stale:', 'STALE SYNC' in output.getvalue())
 except Exception as e:
  print(repr(header),'rendered:',bool(output.getvalue()),'error:',type(e).__name__+': '+str(e))
 finally: sqlite3.connect=original
PY
```

Decisive output:

```text
'-- generation: 1\n' rendered: True stale: False
'-- generation: 2\n' rendered: True stale: True
'-- releases-app canonical dump\n' rendered: False error: TypeError: %d format: a real number is required, not NoneType
```

Handing off to Producer (author) — disposition S2 within this same normal cap3, preserving all R1/R2 history and corrective R6's closed FAIL6/6. Go to the author window and say 'take your turn'. Full gate/Linux qualification remain required separately.

### Producer · Round 3

S2 Implemented: one-line dashboard warning formatting displays unavailable for parserNone; canonical parsing and recovery unchanged. Exact actual-render matching/different/no-header/empty controls preserve firsttwo behaviors andwitness lasttwo pre-fix TypeError→explicit unavailable stale warning withHTML. Source-bound before/afterJSON retains parserNone. Current Jog24 andthreeescaping×sevenstored-text controls refreshed/pass. No newCI test/case/param/registration/gate, no browser/JS/live DB orconnector execution. Existing e654 dashboard/artifact checks retained; exactcandidate fullnormal gate andcorrectedLinuxexistingCI remainpending.

All S1/S2 dispositions now concrete; review current exactsource/evidence andowningfiles. Round3/3 is the last turn in the previouslyauthorized normalnew-scope cap; preserveall R1/R2 history. If findings remain, set Escalated atcap—no reset/replacement oradditionalround. R6FAIL6/6 remainsclosedunchanged; MediumGH1028 tracked,GH1027 individualtest proposals unapproved. W7–W11 active;this readerprerequisite isnot umbrella/landing/execution approval. No source edits/agents/suites/pytest/fixture programs/network/builders/external writes; onlythisrelay,harmlessin-memory renderer/readprobes. Handing off to Reviewer(codex)—take the last normalPhase6 turn.

### Reviewer · Round 3

VERDICT: PASS
Basis: S1 and S2 are resolved on the current source. The qualified Jog reader meets the reviewed owner-read contract in source and bounded in-memory checks; no additional actionable pre-existing defect was established by this owning-file sweep. Approval closes only this genuinely new Phase6 final-QA relay at its existing cap3. It does not attest the pending full gate/Linux qualification, grant execution or landing permission, or complete W7–W11/weekly/GH1022. Corrective accumulation R6 remains closed FAIL6/6; GH1028 remains Medium and GH1027 remains unapproved.

swept file: yes
Swept the entire current releases_app.py (7040 lines), all 102 gh123 fixture lines and the production telemetry writer; read Phase6 and its resumption, the plan/final histories and current manual/provenance evidence. This is a static owning-file review with narrow read/render measurements, not exhaustive concurrency, provider or all-CRUD clearance.

- [Pass] S2 resolved at utils/py/releases_app.py:6545: absent parser generation now formats as "unavailable". Fresh actual-render checks preserve matching generation1 without STALE SYNC and differing generation2 with STALE SYNC; both no-header and empty dump render with an explicit unavailable/stale warning while the parser still returns None (:1300). Restoring the former numeric formatter solely in memory reproduces TypeError and zero HTML. That witnessed red control grounds the repair; canonical parsing/recovery policy is unchanged.
- [Pass] S1 remains resolved at utils/py/releases_app.py:6572, :6573, :6575, :6593, :6596. Fresh actual-render controls return seven escaped occurrences each for the exact img/event-handler payload, ordinary comparison text and Unicode; active_img is False. Stored values and non-HTML readers are untouched by these interpolation boundaries. No browser/JavaScript executed.
- [Pass] The shared query qualifies BOTH repo_id and gh_number (utils/py/releases_app.py:4614). Fresh actual _jog_rows returns exactly one Owner A row beside Foreign B issue777, retains title=None after deleting only the owning enrichment, and retains the exact legacy13 fields. Active filter/order and missing-table legacy behavior remain explicit (:4602, :4616, :4731); unsupported default schemas remain advisory (:4618).
- [Pass] Inventory is one declared root's held observation, using optional readonly connect with writer default unchanged (utils/py/releases_app.py:432, :4651). Required tables/columns, migration6, positive generation, all declared repositories and observed GIDs qualify before publication (:4652–:4702). Common-dir journal/SQLite sidecar/WAL header checks precede opening; generation/artifact drift withholds rows (:4640–:4649, :4708). UNKNOWN/nonzero and no-dispatch remain explicit (:4634, :4704, :4722). These are source checks; the seeded filesystem/CLI controls were not independently rerun.
- [Pass] Fresh source SHA256 is 77e99f1783313347ad8f672d31751759731f466af7c8fba6f62d98e2d5a46960. Current Jog24, dashboard escaping and generation-after JSON all bind these bytes, and their artifact hashes match retained provenance.jsonl receipts at 2026-10-12T04:13:07. The 24/24 Jog results are Producer evidence, distinguished from fresh bounded query/render observations.
- [Pass] Existing gh123 correction is confined to open(..., 'w+') (test/gh123-lock-progress-bound.sh:63), preserving the six inherited-descriptor handovers, pwrite/truncate and existing assertions/bounds (:65–:100). Production retains O_RDWR|O_CREAT (utils/telemetry/append-xyz-completion.sh:69), per-holder default30 and separate total cap (:55–:56). No new CI case/assertion/registration or production token-policy change is part of this correction.
- [Unverified — needs clone run] Exact-current-source full normal gate and corrected Linux qualification remain pending, as recorded in PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md's final Phase6 resumption. Earlier focused receipts do not attest this final source. The post-turn harness/disposable clone must establish them before the corresponding publication/qualification claim. No validate.sh, test/*.sh, pytest, executable fixture program, Git command, connector/network/builder or live queue action ran here.

Graph limitation: list_projects returned all82 entries with has_more=false and omitted this worktree. Nearest Forge coverage generation2026-09-01T15:54:30Z reports metadata_changed for owner/test/writer and missing plan/evidence freshness. Direct current-source inspection grounds the review; no reindex or exhaustive current caller-graph claim.

Quoted fresh probe command (module definitions, actual in-memory read/render calls; temp dump bytes only in .relay-scratch; transposed red changes only an in-memory function):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import ast, contextlib, hashlib, io, json, sqlite3
from pathlib import Path
from types import SimpleNamespace
p=Path('utils/py/releases_app.py'); source=p.read_text()
ns={'__name__':'review_probe','__file__':str(p.resolve())}
exec(compile(ast.parse(source),str(p),'exec'),ns)
sha=hashlib.sha256(p.read_bytes()).hexdigest()
print('source_sha256:',sha)
base=Path('TESTS-RESULTS/2026-10-11+GH-1022')
receipts=[json.loads(x) for x in (base/'provenance.jsonl').read_text().splitlines() if x.strip()]
for name in ['phase6-jog-manual-results.json','phase6-dashboard-after.json','phase6-dashboard-generation-after.json']:
 data=json.loads((base/name).read_text()); digest=hashlib.sha256((base/name).read_bytes()).hexdigest()
 print(name,'source_matches:',data['source_sha256']==sha,'provenance_matches:',any(r.get('artifact')==str(base/name) and r.get('sha256')==digest for r in receipts))
 if 'count' in data: print('recorded_Jog_controls:',data['count'],len(data['controls']),sum(x['pass'] for x in data['controls']))
original=sqlite3.connect
dump=Path('.relay-scratch/tmp/r3-header.sql').resolve()
ns['resolve_root']=lambda root:root
ns['artifact_paths']=lambda root:{'db':'/dev/null','dump':str(dump)}
ddl="CREATE TABLE settings(key,value); INSERT INTO settings VALUES('generation','1'); CREATE TABLE op_receipts(id); CREATE TABLE releases(version,codename,status,target_date,shipped_date,description,exit_criterion,id); CREATE TABLE manifest_items(release_id,state); CREATE TABLE roadmap_items(section,gh_number,title,status_marker,position);"
def render(header,value=None):
 dump.write_text(header)
 c=original(':memory:');c.row_factory=sqlite3.Row;c.executescript(ddl)
 if value is not None:
  c.execute('INSERT INTO releases VALUES(?,?,?,NULL,NULL,?,?,1)',(value,value,value,value,value))
  c.execute('INSERT INTO roadmap_items VALUES(?,777,?,?,1)',(value,value,value))
 sqlite3.connect=lambda *a,**k:c
 out=io.StringIO()
 try:
  with contextlib.redirect_stdout(out): ns['cmd_dashboard'](SimpleNamespace(root='read-probe'))
  html=out.getvalue()
  return {'rendered':bool(html),'stale':'STALE SYNC' in html,'unavailable':'Dump generation (unavailable)' in html,'escaped_count':html.count(ns['html_escape'](value)) if value else None,'active_img':'<img ' in html}
 except Exception as e: return {'error':type(e).__name__+': '+str(e),'rendered':bool(out.getvalue())}
 finally: sqlite3.connect=original
for header in ['-- generation: 1\n','-- generation: 2\n','-- releases-app canonical dump\n','']:
 print('header:',repr(header),'parser:',ns['dump_generation_from_text'](header),'result:',render(header))
for value in ['<img src=x onerror="alert(1)">','A & B < C','Ordinary owner ✅']:
 print('escaping:',repr(value),render('-- generation: 1\n',value))
f=next(x for x in ast.parse(source).body if isinstance(x,ast.FunctionDef) and x.name=='cmd_dashboard')
text=ast.get_source_segment(source,f)
needle='(db_gen, dump_gen if dump_gen is not None else "unavailable")'
assert needle in text
red=text.replace('!= Dump generation (%s)','!= Dump generation (%d)').replace(needle,'(db_gen, dump_gen)')
saved=ns['cmd_dashboard']
exec(compile(red,'<in-memory-S2-red-control>','exec'),ns)
print('S2_transposed_red:',render('-- releases-app canonical dump\n'))
ns['cmd_dashboard']=saved
c=original(':memory:');c.row_factory=sqlite3.Row
c.executescript('CREATE TABLE jog_queue(id,global_id,repo_id,gh_number,position,status,attempt_count,lease_pid,failure_reason,created_at,updated_at); CREATE TABLE roadmap_items(repo_id,global_id,gh_number,title,doc_path,issue_url);')
c.execute("INSERT INTO jog_queue VALUES(1,?,1,777,1,'pending',0,NULL,NULL,'2026-10-12','2026-10-12')",('jog-'+'1'*26,))
for rid,title in [(1,'Owner A'),(2,'Foreign B')]:
 c.execute('INSERT INTO roadmap_items VALUES(?,?,777,?,NULL,?)',(rid,'rmi-'+str(rid)*26,title,'https://github.com/acme/'+('a' if rid==1 else 'b')+'/issues/777'))
rows=ns['_jog_rows'](c)
print('qualified_query:',len(rows),[r['title'] for r in rows],'legacy_keys:',','.join(rows[0]))
c.execute('DELETE FROM roadmap_items WHERE repo_id=1')
print('unregistered_title:',ns['_jog_rows'](c)[0]['title'])
c.close()
PY
```

Exit status: 0. Decisive output:

```text
source_sha256: 77e99f1783313347ad8f672d31751759731f466af7c8fba6f62d98e2d5a46960
phase6-jog-manual-results.json source_matches: True provenance_matches: True
recorded_Jog_controls: 24 24 24
phase6-dashboard-after.json source_matches: True provenance_matches: True
phase6-dashboard-generation-after.json source_matches: True provenance_matches: True
header: '-- generation: 1\n' parser: 1 result: {'rendered': True, 'stale': False, 'unavailable': False, 'escaped_count': None, 'active_img': False}
header: '-- generation: 2\n' parser: 2 result: {'rendered': True, 'stale': True, 'unavailable': False, 'escaped_count': None, 'active_img': False}
header: '-- releases-app canonical dump\n' parser: None result: {'rendered': True, 'stale': True, 'unavailable': True, 'escaped_count': None, 'active_img': False}
header: '' parser: None result: {'rendered': True, 'stale': True, 'unavailable': True, 'escaped_count': None, 'active_img': False}
escaping: '<img src=x onerror="alert(1)">' {'rendered': True, 'stale': False, 'unavailable': False, 'escaped_count': 7, 'active_img': False}
escaping: 'A & B < C' {'rendered': True, 'stale': False, 'unavailable': False, 'escaped_count': 7, 'active_img': False}
escaping: 'Ordinary owner ✅' {'rendered': True, 'stale': False, 'unavailable': False, 'escaped_count': 7, 'active_img': False}
S2_transposed_red: {'error': 'TypeError: %d format: a real number is required, not NoneType', 'rendered': False}
qualified_query: 1 ['Owner A'] legacy_keys: id,global_id,gh_number,position,status,attempt_count,lease_pid,failure_reason,created_at,updated_at,title,doc_path,issue_url
unregistered_title: None
```

Relay closed (Approved), no further review turn needed. Handing the completed token back to author via done; author/harness owns the file-scoped commit and the separate exact-candidate gate/Linux qualification. Preserve corrective R6 and all earlier round history; W7–W11 remain active and weekly HELD.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
