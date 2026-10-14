# RELAY · GH1042 + GH1045 final implementation QA
NEXT: —
STATUS: Approved
ROUND: 3 / 3

## Setup
Producer: Codex outer session. Reviewer: independent Codex CLI through shipped relay.
Definition of done: separate GH1042 force gate-only and GH1045 historical completion acceptance, strict GH505 current-candidate merge validation, no new suites/gates/Bash edits, truthful historical receipt identities.
Review against development b9f07ea5b8d95bac62a3ed9f886770fee883030f. Production source commit 7128b49620a681ecec78e7c9a8b2722b709300e7; evidence/docs e5564d7a. Review the full relevant functions in utils/py/marathon_drive.py and utils/py/relay_attest.py; read Jog's actual merge consumer without changing it.
Plan: PROJECT/2-WORKING/GH-1042-FORCE-GATE-ONLY-REFIRE.md; plan QA receipt: relay-system/2026-10-13/gh1042-plan.codex.md (first two structural failures rejected; third exit0 Approved).
Evidence: TESTS-RESULTS/2026-10-13+GH-1042/SUMMARY.md, fixed-results.json, final-focused-results.json, provenance.jsonl and raw logs. 33 manual expected outcomes passed at final source. Existing marathon-drive passed at final source after finding/fixing approval-event timing. gh491/gh505/gh642 passed at preceding source; final full gate will run exactly once through push boundary after approval. Clone identity stayed unchanged.
Operational envelope: local single-user harness, same GH505 containment boundary; no enterprise threat-model expansion. No automatic unsafe legacy backfill. Old divergent runs without completion metadata retain strict refusal and require explicit rebuild. Grade requirements and commensurate complexity; reject scope creep/new suites. No provider calls claimed in manual fixture replay.
Reviewer may read/query and use narrow non-mutating source probes; may NOT run suites/pytest/executable fixtures here, create production files, git commits or pushes. Edit only this thread. Final review Basis must distinguish inspected retained evidence from independently executed behavior. The actual full gate is pending, not claimed passed.

## Log

### Round 1 · Producer
Did: implemented optional protected phase completion using existing atomic approval writer; resolved satisfaction before force allocation; support base/numeric/force family; retain strict merge checks and no-fresh-review receipt on historical recovery. Preserved GH273 approval-event timing after suite caught regression. Separate issue captures/rated accepted-start rows maintained.
Verification: recorded manual replay, 33 expected observations pass; corrected marathon-drive suite pass at7128b496; earlier gh491/gh505/gh642 passes; no tests or gate machinery added. Required full publication gate pending.
Open questions: Can any source drift before initial stamp incorrectly become satisfied? Can wrong-phase/lane/review or unreachable completion pass? Does historical recovery mutate or misreport approval for current HEAD? Are completion-write failure and old-reader fallback conservative? Are final evidence claims honest and source changes surgical? Review source, not producer claims.
Commit: e5564d7a.

## ▶ TAKE YOUR TURN — codex
Append `### Round 1 · Reviewer · <timestamp>` with a literal line `VERDICT: PASS` / `VERDICT: FAIL` / `VERDICT: PARKED`, nonempty `Basis: ...`, `swept file: yes/no`, cited graded findings and `Commit: none`. The machine verdict value MUST be exactly PASS, FAIL or PARKED; NEVER use Approved as that line's value. For PASS set header STATUS: Approved and NEXT: codex (Reviewer) and mark the pinned tick token done. For findings set STATUS: Open, NEXT: producer and release token to producer. Do not edit old blocks except header fields. Only this thread may change; no git or suites. Review the actual committed source and retained evidence. Three-round cap applies.

### Round 1 · Reviewer · 2026-10-13T15:55:16.579662+00:00
VERDICT: PASS
Basis: Inspected the supplied local source, the canonical plan, retained manual replay source/results/raw logs, final focused receipts and provenance. This is source review plus inspection of producer-run evidence, not an independently executed behavioral replay. No git, suite, pytest, executable fixture, provider call or merge was run. The supplied source identity is 7128b496; git identity/diff was not independently queried under this turn's prohibition. Graph discovery found no index for this checkout; nearest XYZ-forge generation 2026-09-01T15:54:30Z was stale/different-root, with changed/untracked coverage for these paths. Exact local source was therefore authoritative.
swept file: yes

- [Pass] GH1042: `utils/py/marathon_drive.py:2799` through startup satisfaction and force allocation at `:2920` resolve the recorded base/numeric/force family before allocating a fresh force token. Explicit token selection remains authoritative. Retained `fixed-results.json` records force/base/numeric recovery without dispatch and explicit/unrelated-token rebuild controls with dispatch; `baseline-results.json` records the pre-fix force dispatch.
- [Pass] GH1045 authority: `utils/py/relay_attest.py` functions `record_phase_completion` and `phase_completion_candidate` extend the existing atomic record writer, bind phase/lane/review identity, validate the stamped candidate with strict `candidate_ok`, and require ancestry to current HEAD. Missing metadata retains strict legacy validation; malformed metadata refuses. `utils/py/marathon_drive.py:2673` stamps only after gate, required-test and final candidate validation; write failure exits 4. Retained refusal logs cover pre-completion drift, wrong phase/lane/review, missing/empty evidence, malformed candidate, divergent ancestry, post-hook drift and completion-write failure.
- [Pass] Historical receipt and merge separation: `utils/py/marathon_drive.py:2721` checks recovery-time committed source drift against recovery HEAD, retains the historical candidate, skips repeated completed hooks/test-delta obligations, and suppresses new gate/phase-QA receipts (`:2773`, result writer `:201`). Jog's actual consumer at `utils/py/jog_run.py:414` and `_merge_reviewed_pr` at `:1430` still requires the live PR head to equal the validated candidate, applies strict `candidate_ok`, and pins merge with `--match-head-commit`. Historical completion does not authorize an unreviewed successor merge. These checks concern committed candidates, as in the existing GH505 contract.
- [Pass] Retained evidence is candid about the event-order regression and its repair: `complete_phase_success` emits approval before the post-approve hook but stamps completion afterward. `marathon-drive-final.log` ends with `marathon-drive: 162 pass, 0 fail`; `final-focused-results.json` and `provenance.jsonl` identify source 7128b496. Earlier gh491/gh505/gh642 runs are explicitly attributed to 0275a7a0. The two-phase raw log shows p1 recovery followed by p2 retry dispatch and the intended stub exit 7; its old standalone result object is not treated as a fresh traversal receipt.
- [Pass] Independently executed read-only evidence probe, exit 0, decisive output: `33/33 retained outcomes match; both retained identity pairs match`. Command:
  ```python
  import json,pathlib
  p=pathlib.Path('TESTS-RESULTS/2026-10-13+GH-1042')
  r=json.loads((p/'fixed-results.json').read_text())
  assert r and len(r)==33 and all(x['ok'] and x['rc']==x['expected'] for x in r)
  assert all(json.loads((p/(s+'identity-before.json')).read_text())==json.loads((p/(s+'identity-after.json')).read_text()) for s in ('','final-'))
  print('33/33 retained outcomes match; both retained identity pairs match')
  ```
  Executed via `python3 -` with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`. Separate read-only `ast.parse` of all three reviewed Python files exited 0. Neither probe establishes fresh runtime behavior.
- [Unverified — needs clone run] The final full publication gate remains pending. This PASS approves the reviewed implementation for that next gate; it does not assert publication/merge readiness or a fresh end-to-end provider run. No blocking source finding within the bounded review.

Commit: none

### Attestation · relay-drive — 2026-10-13T15:55:35Z
task: RELAY-GH1042-FINAL-20261013
reviewer: codex
status: Approved
reviewed-head: 8077b03ac6235498bd6e2e098e95a9fae59b1127
added-range: 3777+4331
added-sha256: 23d622ed60ec8d3c324adcdb9b399888d0b6584514f21bc54e26fa87f3f504d7

### Round 2 · Producer
Round1 approved source7128b496 with driver exit0. Subsequent producer control found legacy --force had lost its existing fresh rebuild escape: exit4/no dispatch. Implemented five-line force fallthrough only on an unsatisfied terminal approval; this NEVER satisfies or merges it. Normal render/seed/build/review must run on a fresh force token. Plain recovery still refuses. Within approved plan step1's genuinely unsatisfied force case.
Verification: source9b392b35: all34 manual outcomes pass; existing Marathon suite passes; identity unchanged. New immutable raw receipts in TESTS-RESULTS/2026-10-13+GH-1042/after-legacy-force/ and appended provenance. Prior evidence retained. Full gate remains pending.

## ▶ TAKE YOUR TURN — codex (round 2 current instructions)
Review current committed source against development b9f07ea5, focusing on the newly preserved unsatisfied-force rebuild and unchanged refusal/satisfaction/merge boundaries, and reconcile all prior implementation findings against actual source. Read the new current-revision manual/focused evidence. Keep reviewer writes ONLY in this thread; no git, suites or executable fixtures. Append Round2 Reviewer, exact literal VERDICT: PASS/FAIL/PARKED, nonempty Basis, swept file: yes/no, cited findings and Commit: none. For PASS set STATUS: Approved and NEXT: — and mark token done. Do not write Approved as a machine verdict value. Three-round budget, this is round2. Old round1 approval is not final for changed code.

### Round 2 · Reviewer · 2026-10-13T16:03:02.752689+00:00
VERDICT: PASS
Basis: Ship with conditions: source review approves proceeding to the pending publication gate. Inspected the current supplied source, canonical plan, retained manual runner, after-legacy-force raw logs/results, focused receipts and appended provenance. Independently executed only a read-only JSON consistency/AST probe, not the behavioral fixtures. No git, suites, pytest, provider calls or merge were run. Source identity 9b392b358189545b0d077ca0cc3b9a51d778e8ba is attributed by retained receipts; committed identity and a development-b9f07ea5 diff were not independently queried under the no-git restriction. Graph project pagination was exhausted: this checkout is not indexed; nearest XYZ-forge generation 2026-09-01T15:54:30Z is a different root with changed/not-tracked coverage for the three source paths, so exact local source was used. Review sweep covers the relevant complete functions and their consumer boundaries, not every unrelated function in these large modules.
swept file: yes

- [Pass] Restored rebuild escape: `utils/py/marathon_drive.py:2874` (`satisfied_lane_terminal`) returns false after refused attestation only for force without an explicit relay task. It does not assign completion state or publish success. The following `resolve_force_relay_task` call at `:2926` preserves the existing spent-token allocation, followed by ordinary render/seed/relay dispatch. Explicit task selection remains authoritative. The retained `after-legacy-force/legacy-force-regression.log` and provenance identify the pre-fix source7128b496 exit4/no dispatch; `legacy-force-rebuild.log` shows fresh MARATHON-P1-TURN-R2, relay dispatch and intended stub exit7 at source9b392b35. This is a rebuild-path observation, not a successful real builder/reviewer run.
- [Pass] Refusal and satisfaction remain separate. `completed_relay_task` still restricts recorded identities to the base/numeric/force family. `attested_terminal` validates the protected record, optional historical completion and strict candidate check. Plain divergent legacy recovery still exits4 in `legacy-later-refuses.log`. Force fallthrough cannot make a refused record satisfied; a newly dispatched build must obtain a new approval. Existing successful force recovery continues to short-circuit before allocation. No blocking defect found in the bounded source sweep.
- [Pass] Reconciled prior authority findings against current source: `relay_attest.py:359-408` binds completion to phase/lane/review, validates the completion candidate, and requires ancestry; absent metadata uses strict legacy checking and malformed metadata refuses. `complete_phase_success` retains approval-before-hook ordering, stamps only after final candidate validation, and exits4 on write failure. Historical recovery checks committed recovery-time drift, retains the historical candidate, skips repeated completed side effects and suppresses fresh gate/phase-QA receipts. `jog_run.py:414` and `_merge_reviewed_pr` at `:1430` still require expected candidate equality, strict `candidate_ok` and `--match-head-commit`. Historical satisfaction therefore grants no successor merge authority within the existing committed-candidate contract.
- [Pass] Current evidence: retained manual-results.json has 34/34 matching expected outcomes, final-focused-results.json attributes both successful commands to 9b392b35, provenance retains earlier source identities, and marathon-drive-final.log ends `marathon-drive: 162 pass, 0 fail`. The before/after clone identity objects match. The stubbed runner and its assertions were inspected but not executed here; no provider or full-gate result is inferred.
- [Pass] Independently executed probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` exited 0. Decisive output: `34/34 retained outcomes match; force dispatch/plain refusal confirmed; identity pair equal; 2 current-source receipts pass; 3 AST parses pass`. Probe body:
  ```python
  import ast,json,pathlib
  p=pathlib.Path('TESTS-RESULTS/2026-10-13+GH-1042/after-legacy-force')
  r=json.loads((p/'manual-results.json').read_text())
  assert len(r)==34 and all(x['ok'] and x['rc']==x['expected'] for x in r)
  d={x['name']:x for x in r}
  assert d['legacy-force-rebuild']['rc']==7 and d['legacy-force-rebuild']['dispatched']
  assert d['legacy-later-refuses']['rc']==4 and not d['legacy-later-refuses']['dispatched']
  assert json.loads((p/'final-identity-before.json').read_text())==json.loads((p/'final-identity-after.json').read_text())
  f=json.loads((p/'final-focused-results.json').read_text())
  assert len(f)==2 and all(x['exit_code']==0 and x['sha']=='9b392b358189545b0d077ca0cc3b9a51d778e8ba' for x in f)
  for name in ('marathon_drive','relay_attest','jog_run'): ast.parse(pathlib.Path('utils/py/'+name+'.py').read_text())
  print('34/34 retained outcomes match; force dispatch/plain refusal confirmed; identity pair equal; 2 current-source receipts pass; 3 AST parses pass')  [Unverified — no citation]
  ```
- [Unverified — needs clone run] Final full publication gate remains pending. This verdict approves the reviewed implementation for that next gate, not publication/merge readiness. Runtime behavior was assessed from retained producer evidence rather than independently rerun during this turn.

Commit: none

### Attestation · relay-drive — 2026-10-13T16:03:13Z
task: RELAY-GH1042-FINAL-20261013-2
reviewer: codex
status: Approved
reviewed-head: c98e12017fdf894a1ddd72e708ba50ca73fc2154
added-range: 9915+5381
added-sha256: 6d0b5287bdc959761411cc6ad14355d75604c02273163e476b3cc3509620582d

### Publication handoff · Producer
PR #1054: https://github.com/HiQS-Labs/XYZ-forge/pull/1054 (development, non-draft, MERGEABLE). Full pre-push409/409 atd37140db, no retries, clone identity unchanged. Gate receipts committed in7be78ea0; its metadata-only documentation gate passed67s. Production blobs unchanged from reviewed source9b392b35. This handoff adds only publication facts, not a new reviewer verdict. Await merge/reconciliation; no Jog dispatched.

### Round 3 · Producer · 2026-10-14
Did: refreshed the existing PR1054 branch onto development7bc727cb using the installed disjoint-only ledger resolver; corrected stale plan acceptance/pending states; added the missing durable bet record and append-only changelog correction; corrected GH1045 raw-text title; repaired positions of only GH1042/GH1045 through the existing releases_app.perform_write owner, preserving every other row field. The CLI has no positional-update verb; no CLI/runtime subsystem was added. Production recovery/attestation code is unchanged by review corrections.

Repro: the retained old two-phase row has rc7 but result.exit_code0/outcome approved from the earlier p1 seed. Existing manual-replay now unlinks the seed result before shell traversal. Fresh existing34-outcome replay passed; the failed p2 retry has result null and dispatched=true. Clone identity/config remained identical. Retained new evidence: TESTS-RESULTS/2026-10-14+GH-1042-review-corrections/. No new CI tests/cases, no cap reset, no live provider/Marathon/Jog activation. Updated-head normal publication gate remains pending.

Review scope: review these corrections and the current-base integration, adjudicate the original five CodeRabbit findings against actual source/evidence, verify the ledger write uses the existing transaction owner and changes only intended metadata, and check that earlier historical receipts/approvals are not rewritten. Original final QA round1/round2 and attestations remain intact. This is the remaining third round of the existing three-round budget.

## ▶ TAKE YOUR TURN — codex (round 3 current instructions)
Read current committed changes and retained evidence. Edit ONLY this existing relay file. Do not run git, suites, pytest, executable fixtures, provider calls or writes outside this relay. Narrow nonmutating JSON/source probes are permitted under .relay-scratch or TMPDIR. Append `### Round 3 · Reviewer · <timestamp>` with literal `VERDICT: PASS`, `VERDICT: FAIL` or `VERDICT: PARKED`, nonempty Basis, `swept file: yes/no`, graded cited findings and `Commit: none`. For PASS set STATUS: Approved/NEXT: — and mark the pinned token done. For findings set STATUS: Open/NEXT: producer and release to producer. Do not edit old log blocks or call a passing gate an independent review. Cap3/3; no further round is authorized. Distinguish inspected producer evidence from any independently executed probes and from the still-pending publication gate.

### Round 3 · Reviewer · 2026-10-14 23:44:32 UTC
VERDICT: PASS
Basis: Ship with conditions: approve the supplied corrections for the pending updated-head publication gate. Reviewed the complete relevant completion/attestation functions, force startup path, Jog merge consumer, existing ledger transaction owner, plan/decision/changelog corrections and retained producer evidence. Independently executed only read-only source/JSON/immutable-SQLite consistency probes; no behavioral fixture, suite, pytest, provider call, git command, commit, push or merge. Producer replay is attributed by committed provenance to source519e901419e6e8607eafbbc29fbbd5dcd1ceee7c. GitHub connector reads supplied the original five review comments and historical source/base blobs; local byte hashes independently establish the comparisons below. No current local commit identity is asserted. Graph project pagination exhausted; this checkout has no project. Nearest XYZ-forge generation2026-09-01T15:54:30Z is a different root, with metadata_changed/not_tracked coverage for all four evidence paths. Exact local source supplied the Verify-tier fallback. Scope is the relevant functions and corrections, not every unrelated function in these modules.
swept file: yes

- [Pass] CodeRabbit minor finding4261368769, durable bet: `CHANGELOG.md:3` appends a dated correction linking `decisions/2026-10-14-gh1042-historical-completion.md:1`. The decision supplies the expected recovery/strict-merge signal, concrete2026-10-28 review date, iterate recommendation, revisit conditions and rollback. It explicitly retains an unverified operational claim if no independently authorized run occurs. The original consequential changelog entry is unchanged, rather than retrospectively rewritten. This satisfies `PROJECT/PDDA.md:1025`. No live run is authorized by this approval.
- [Pass] CodeRabbit minor finding4261368837, stale plan: `PROJECT/2-WORKING/GH-1042-FORCE-GATE-ONLY-REFIRE.md:30` marks the three acceptance rows Verified and names PR1054. Its evidence section at `:72` distinguishes round2/old409-of409 qualification from still-required round3/current publication qualification. The checkpoint and handoff preserve their dated source identities. Historical verification is established by retained evidence; these labels confer no updated-head merge readiness.
- [Pass] CodeRabbit minor findings4261368852/4261368866, positions and title: `TESTS-RESULTS/2026-10-14+GH-1042-review-corrections/pr1054-position-repair.json` has exactly two before/after rows, changing only position to127/128. Independently queried immutable `releases.db` shows both positions unique in In progress and the same GH1045 heading in title/raw_text. Current row comparison preserves every other field apart from the separately recorded GH1045 raw_text/updated_at correction. Existing `utils/py/releases_app.py:1657` owns lock, intent journal, BEGIN IMMEDIATE, generation, receipt, durable dump and connector dispatch; its local blob `fa25aee8e4c5a37a13cb748e8ebe3726f95eeac3` matches development7bc727cb. Actual op_receipts contains `roadmap-position-repair` immediately followed by `roadmap-update`, with matching after/before digests. The retained receipt and existing-owner source support the one-time operation; I did not execute that write or inspect an independently retained mutation script. No new CLI/runtime writer was introduced.
- [Pass] CodeRabbit minor finding4261368880, stale two-phase result: `TESTS-RESULTS/2026-10-13+GH-1042/manual-replay.py:143` now unlinks the seed result before shell traversal. Read-only comparison to PR head730e707 finds exactly that inserted executable line, after normalizing the scratch copy's trailing LF. Exit0 decisive output: `Manual replay correction is exactly one inserted seed-result unlink (trailing scratch LF normalized)`. The new `results.json` row is rc7/dispatched=true/result=null; `two-phase-later-retry.log` shows completed p1 recovery, MARATHON-P2-TURN-2 dispatch and p2 halt. This is stubbed dispatch evidence, not a successful p2/provider run. The older `after-legacy-force/manual-results.json` blob remains `1f3a1dca036b4db652c99013eb745cc782453a3e`, matching head730e707; its stale approved p1 object is preserved and explicitly superseded for that association.
- [Pass] Current-base integration and historical preservation: nonempty GitHub-fetched development7bc727cb dump contained3372 INSERT rows. Independent exact-line comparison retains every row except the replaced generation setting; unrelated business/provenance rows are intact. The original relay through the publication handoff is an exact prefix after normalizing only its first three mutable headers; round1/round2 reviews and attestations are unchanged. Original provenance blob `1db4c1b463ff3ce2048551aa0292e1654b63e269` matches head730e707. Current correction provenance's40 artifact hashes all match. No old approval or result was rewritten to make the new replay appear successful.
- [Pass] Reconciled production authority: local blobs of `marathon_drive.py` (`180b0f9d1e0edf682102b5bb7b47487243b67d59`), `relay_attest.py` (`3e6185bf93e7c8f628cb836aae45e1537a861b11`) and `jog_run.py` (`c3fd8a03370f33f238e15a6c40a2d63fa362694a`) match reviewed source9b392b35 via GitHub blob identity and locally computed SHA1 over the Git blob byte format, without invoking git. `marathon_drive.py:2874` refuses unsatisfied terminal approval unless force without explicit task falls through to fresh rebuild, and satisfaction precedes allocation at `:2926`. `relay_attest.py:359` uses the existing atomic writer; `:375` checks phase/lane/review binding, strict completion candidate and ancestry. Missing legacy metadata stays strict, malformed completion refuses. `marathon_drive.py:2673` preserves approval-before-hook timing, validates after the hook, fails completion-write errors, retains historical candidate and checks committed recovery-time drift. Historical recovery skips completed hooks/test-delta obligations and suppresses fresh review/gate receipts. `jog_run.py:414` still forwards the historical expected candidate; `:1454` requires live PR head equality, strict candidate_ok and match-head-commit. No successor merge authority is granted within the existing GH505 committed-candidate boundary. Four independently parsed ASTs passed; this is syntax evidence only.
- [Pass] Independently executed consistency probe below: exit0; decisive output: `34/34 outcomes; wrong-rc red control rejected; failed p2 result null; identity equal; 40 hashes match; two positions unique; metadata preserved; 3372 base rows retained except generation; old changelog/relay history unchanged`. The remote-review/base-comparison scratch inputs contain the nonempty connector-fetched historical relay/changelog and development7bc727cb INSERT rows. Command:
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PY'
  import copy,hashlib,json,pathlib,re,sqlite3
  p=pathlib.Path('TESTS-RESULTS/2026-10-14+GH-1042-review-corrections')
  rows=json.loads((p/'results.json').read_text())
  def valid(r): return len(r)==34 and all(x['ok'] and x['rc']==x['expected'] for x in r)
  assert valid(rows)
  bad=copy.deepcopy(rows);bad[0]['rc']+=1;assert not valid(bad)
  d={x['name']:x for x in rows};t=d['two-phase-later-retry']
  assert t['rc']==7 and t['dispatched'] and t['result'] is None
  assert json.loads((p/'pr1054-gate-identity-before.json').read_text())==json.loads((p/'pr1054-gate-identity-after-manual.json').read_text())
  v=[json.loads(x) for x in (p/'provenance.jsonl').read_text().splitlines()]
  assert len(v)==1 and all(hashlib.sha256((p/n).read_bytes()).hexdigest()==h for n,h in v[0]['artifacts'].items())
  q=json.loads((p/'pr1054-position-repair.json').read_text())
  assert len(q['before'])==len(q['after'])==2
  for a,b in zip(q['before'],q['after']):
   assert {k:v for k,v in a.items() if k!='position'}=={k:v for k,v in b.items() if k!='position'}
  assert [x['position'] for x in q['after']]==[127,128]
  c=sqlite3.connect('file:'+str(pathlib.Path('releases.db').resolve())+'?mode=ro&immutable=1',uri=True);c.row_factory=sqlite3.Row
  for a in q['after']:
   b=dict(c.execute('select * from roadmap_items where global_id=?',(a['global_id'],)).fetchone())
   omit={'raw_text','updated_at'} if a['gh_number']==1045 else set()
   assert {k:v for k,v in a.items() if k not in omit}=={k:v for k,v in b.items() if k not in omit}
   assert c.execute('select count(*) from roadmap_items where section=? and position=?',(b['section'],b['position'])).fetchone()[0]==1
   if a['gh_number']==1045: assert '**'+b['title']+'**' in b['raw_text']
  base=json.loads(pathlib.Path('.relay-scratch/tmp/base-comparison.json').read_text())
  assert base['baseRows'] and base['oldEntry']
  local=set(pathlib.Path('releases.sql').read_text().splitlines())
  missing=[x for x in base['baseRows'] if x not in local]
  assert len(missing)==1 and missing[0].startswith('INSERT INTO settings(') and "'generation'" in missing[0]
  assert base['oldEntry'] in pathlib.Path('CHANGELOG.md').read_text()
  old=json.loads(pathlib.Path('.relay-scratch/tmp/remote-review.json').read_text())['relay']['content']
  def normal(s):
   for k in ('NEXT','STATUS','ROUND'): s=re.sub(r'^'+k+r':.*$',k+':',s,count=1,flags=re.M)
   return s
  assert old and normal(pathlib.Path('relay-system/2026-10-13/gh1042-final.codex.md').read_text()).startswith(normal(old))
  print('34/34 outcomes; wrong-rc red control rejected; failed p2 result null; identity equal; 40 hashes match; two positions unique; metadata preserved; 3372 base rows retained except generation; old changelog/relay history unchanged')
    PY
  ```
  The in-memory wrong-rc control tests this consistency assertion's sensitivity; it is not a runtime mutation or new suite. The producer's34 expected behavioral outcomes were inspected, not rerun here.
- [Unverified — needs clone run] The updated-head normal publication gate and hosted exact-head qualification remain pending. Original gate409/409 at d37140db is historical evidence only. The GitHub connector still reports published head730e707, not the supplied refreshed corrections; no fresh publication or live mergeability is claimed. This PASS permits the next authorized qualification step, not merge/promotion or a fourth review round. No blocking finding within the bounded final review.

Commit: none

### Attestation · relay-drive — 2026-10-14T23:45:05Z
task: RELAY-GH1042-FINAL-20261013-R3
reviewer: codex
status: Approved
reviewed-head: 6edaeacded5e0aaa8a0f5d1f7edbab99e355ab87
added-range: 18537+10410
added-sha256: 34c943ea039c497a17798d11bd096989de2f4e670f1e687d8131e680327052b5
