# RELAY · GH1022 Phase6 qualified Jog reader final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
