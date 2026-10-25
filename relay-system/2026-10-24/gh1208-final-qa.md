# RELAY · GH-1208 final QA: jog land local reconcile evidence + receipts
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh-1208-final-qa-jog-land-local-reconcile-evidence-receipts): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1208-JOG-LAND-LOCAL-RECEIPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1208-JOG-LAND-LOCAL-RECEIPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: FINAL QA of the committed implementation at `e98f3162` (fix commit `f5a4e42f`; plan approved in
  `relay-system/2026-10-24/gh1208-plan-qa.md` r2, attested `94542fbb`). Approve when, against the live tree:
  (1) `utils/py/jog_run.py` `jog_land` carries exactly the approved change — hosted evidence first and unchanged, local
  evidence = `roadmap_items` row for GH-N in `Completed` whose `raw_text` contains `(PR #N)`, read on the existing read-only
  connection; refusal when neither names both remedies; `landing.json` records `hosted_reconcile: matching[0] | null` and
  `local_reconcile: {roadmap_gid, raw_text} | null`; nothing else in `utils/`, `src/`, `relay-automation/`, `bin/`, `test/`
  changed vs `80e67677` (`git diff --name-only 80e67677..HEAD -- utils src relay-automation bin test githooks`);
  (2) the receipts under `TESTS-RESULTS/2026-10-24+GH-1208/` substantiate `SUMMARY.md`: unmodified gh280 223/223 on the fixed
  code; variant GH1127 reverted → `hosted wave-reconcile is not green` refusal (red control); variant GH1127 fixed → suite
  225/225 rc=0 with `landing.json` `hosted_reconcile == null` and a `local_reconcile` object naming the GH-901 row
  (`landing-fixed-gh1127.json`), L6/L7 replay green; variant NEITHER fixed → the combined refusal, no landing. Re-grep the
  retained logs yourself; `reevaluation.txt` explains the driver's two anchoring FAILs honestly;
  (3) the variant edits (`variant-GH1127.sh`, `variant-NEITHER.sh` vs `test/gh280-jog-marathon-adapter.sh`) touch only the
  stub's wave-reconcile `run list` answer, a GH-901 `roadmap add` + `ROADMAP_SOURCE=releases` seed, the L5 step removal
  (NEITHER) and marker capture — no change to what the fix is measured against;
  (4) issue #1208's acceptance (land with local receipt and no hosted run; refuse with neither; idempotent replay) is met,
  with the stated Limit (legacy-ROADMAP repos without a ledger row keep hosted-only behaviour);
  (5) no new test, suite, registry entry, resolver or writer (GH-831); the capture doc's Status, rating 78/75/50/85 and
  `accepted-start` admission are consistent with the evidence.
  The tier-3 `ci-local.sh` full gate is running separately in a disposable clone on `f5a4e42f` (code identical to
  `e98f3162`); its log is attached to the PR, outside this review.
- Operational envelope: a ~20-line either/or evidence change in one function of a single-operator harness; grade against
  #1208, #1131, GH-1108/#1116 and GH-831. Do not request a new receipt format, hosted re-enablement, a second authority
  or enterprise threat models. Reviewer writes stay in this thread.
- Paths to read: `utils/py/jog_run.py` (`jog_land`), `TESTS-RESULTS/2026-10-24+GH-1208/**`,
  `PROJECT/2-WORKING/GH-1208-JOG-LAND-LOCAL-RECEIPT.md`, `relay-system/2026-10-24/gh1208-plan-qa.md`,
  `test/gh280-jog-marathon-adapter.sh:20-75,995-1045`, `utils/py/wave_reconcile.py:1516-1581`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The bounded implementation and retained red/green controls support the requested landing behavior. Final QA needs one evidence correction: the cited unmodified-suite run is missing from provenance coverage, contrary to AGENTS.md's committed-run-evidence requirement. No observed implementation defect warrants a behavior change. Reversibility: Easy — one function and the existing read-only connection/landing writer.
swept file: yes

- [Should] **Cover the cited baseline run in the existing provenance evidence.** Artifact `:40,113-116` and `TESTS-RESULTS/2026-10-24+GH-1208/SUMMARY.md:6-9` cite the unmodified 223/223 run. Its retained log ends with `223 pass, 0 fail` and `rc=0` (`gh280-unmodified-f5a4e42f.log:226-227`), but the only `provenance.jsonl` under this evidence directory contains 18 records, none covering that log's digest. AGENTS.md requires provenance committed in the same PR for any cited run. Concrete fix: retain the baseline's original run provenance, or extend the existing manifest with an accurately attributed record for this retained baseline (artifact path, digest, size, revision and exit result, following the existing format). Do not invent missing execution metadata or add a suite. This is an evidence correction, not a request to change runtime behavior.

  Read-only probe, exit `0` (with `PYTHONDONTWRITEBYTECODE=1` and scratch `TMPDIR`):
  ```sh
  python3 - <<'PY'
  import hashlib,json
  from pathlib import Path
  b=Path('TESTS-RESULTS/2026-10-24+GH-1208')
  records=[json.loads(s) for s in (b/'checks-f5a4e42f/provenance.jsonl').read_text().splitlines() if s.strip()]
  raw=(b/'gh280-unmodified-f5a4e42f.log').read_bytes()
  assert raw and records
  digest=hashlib.sha256(raw).hexdigest()
  print(len(raw),digest)
  print(len(records),any(r.get('sha256')==digest for r in records))
  print([str(p.relative_to(b)) for p in b.rglob('provenance.jsonl')])
  PY
  ```
  Decisive output: `13573 9538f6eadf8203ab855be710d50989bb93180e930ce6b029d5f8452536a89801`; `18 False`; `['checks-f5a4e42f/provenance.jsonl']`.

- [Pass] **The live function implements the approved either/or gate without the old empty-list crash.** `utils/py/jog_run.py:1189-1201` retains the hosted query, validation and first matching run's completed/success predicate. `:1202-1218` reads `roadmap_items` through the existing read-only connection, constrains GH number and `Completed`, and matches the exact `(PR #N)` substring with null-safe raw text. `:1219-1223` refuses with both remedies before queue completion at `:1230-1234`. The existing marker at `:1235-1239` records a green hosted object or null, and the local row object or null. `_committed_jog_receipt` and `_landing_tail_proof` remain the source-level approval/tail boundaries (`:1041-1134`); this turn does not attest their historical diff.
- [Pass] **The local receipt agrees with the actual reconciler output.** `wave_reconcile.py:1520-1521,1550-1558` writes `Completed` and `SHIPPED ... (PR #N)`. In retained `checks-f5a4e42f/landing-fixed-gh1127.json`, `hosted_reconcile` is null and `local_reconcile.roadmap_gid` is `rmi-01M5RKXFK1T9EH4JF8J8KXT3J6`; its raw text exactly equals the GH-901 `Completed` row in `rows-fixed-gh1127.json`, including `(PR #42)`. Root cause: the landing consumer retained a per-merge hosted requirement after dispatch-only decision #1131; fix site: `jog_land`; upstream dispatch-only behavior is intentional (`.github/workflows/wave-reconcile.yml:3-10`).
- [Pass] **The retained controls support the functional claims.** Re-grepping nonempty logs gives: unmodified 223 PASS / 0 FAIL (`gh280-unmodified-f5a4e42f.log:226-227`, rc=0); reverted GH1127 refuses at `reverted-gh1127.log:175` with `hosted wave-reconcile is not green for the landed PR head` (retained `.rc` = 1); fixed GH1127 has 225 PASS / 0 FAIL lines, consisting of the existing 223 assertions plus two manual marker observations (`fixed-gh1127.log:175-189,228`, retained `.rc` = 0); fixed NEITHER refuses at `fixed-neither.log:175` with the combined local/hosted remedy (retained `.rc` = 1). L6/L7 successful replay and unchanged manifest/receipt counts are explicitly present at fixed log `:184-189`. These are reviewed retained clone results, not newly executed suites.
- [Pass] **The variant edits preserve the measurement.** A read-only Python `difflib.unified_diff` comparison of each retained variant against `test/gh280-jog-marathon-adapter.sh` (exit 0) found only the workflow-specific empty hosted answer, GH-901 roadmap/releases-mode seed and its commit, diagnostic/marker capture, and the NEITHER removal of L5 reconciliation. Existing L5 assertions and L6/L7 replay checks are unchanged (`variant-GH1127.sh:1010-1062`; `variant-NEITHER.sh:1010-1015`). No assertion was removed to obtain green. Recomputing SHA-256 and byte sizes for all 18 manifest entries returned zero mismatches. The two driver FAILs are accounted for honestly: `checks.sh:68-69` anchors `^PASS`, while fixed log `:175,184` begins with two spaces; `reevaluation.txt:1-5` explains this and reports the actual results.
- [Pass] **Capture status, scope and admission agree with the retained state.** The seeded artifact equals the tracked capture byte for byte; `:40` distinguishes the committed fix from the still-running full gate and pending PR. `:135-139` states the legacy-ledger limitation, and `:143-150` grounds 78/75/50/85 without claiming measured frequency. `releases.sql:893` carries those ratings and the working-doc pointer; `:4013` records `in_flight` with `"accepted_start": true`. Artifact `:16-21` preserves the explicit non-goals and GH-831 boundary.
- [Unverified — needs clone run] **The separate full gate and the plan's DB-byte replay check are not established by this turn.** Artifact `:129-132` asks for before/after DB SHA-256; retained L6/L7 checks establish unchanged selected counts, not byte identity. No byte-hash pair is retained in these receipts. Do not report byte identity as measured. The tier-3 gate is expressly outside this review; no suite, fixture, pytest or gate was executed here.
- [Unverified — no git permitted] **Historical change scope remains for the harness/outer reviewer.** The user prohibits all git commands in this turn, so I did not execute the requested `80e67677..HEAD` path comparison, independently establish commit identity, or attest that no other runtime/test files changed. Source inspection and variant comparisons above do not substitute for that range check.

Whole-artifact sweep completed, including frontmatter, status, observations, implementation shape, alternatives, rollback, verification, limitation and ratings. No additional pre-existing defects found in the artifact or the bounded `jog_land` path beyond the evidence gap above. Graph discovery found only a foreign-checkout index (`XYZ-forge`, generation `2026-09-01T15:54:30Z`); coverage reported changed/missing metadata, so claims use current local source and retained receipts. The suite's recorded partial range `628-629` was read directly. A supplementary AST-expression probe initially failed due to the probe selecting the function docstring instead of its `try` block; corrected extraction exited 0 and rejected absent/null/empty/PR-420 text while accepting `(PR #42)`. It executed only extracted expressions, never the repository function.

Handing off to Producer (claude-a) — cover the baseline run in provenance and disposition the unverified limits, then return for Round 2 QA.

### Producer · Round 1 — claude-a

- **Should — Accepted.** `checks-f5a4e42f/provenance.jsonl` gained a record for `../gh280-unmodified-f5a4e42f.log` (sha256 9538f6ea…, 13573 bytes, exact command, revision f5a4e42f, exit 0 / 223 pass). Re-run your probe: the digest is now present.
- **Unverified (replay byte identity) — explicitly deferred, not claimed.** The plan's `releases.db` sha256 before/after L6 is not in the receipts; L6/L7 establish unchanged manifest/receipt counts only. Capturing the hashes needs another variant edit and rerun, which the operator bounded for this task; `SUMMARY.md` records it as not measured.
- **Unverified (range scope) — supplied.** `scope-80e67677-to-head.txt` lists every changed path base→head and shows the protected-surface delta is exactly `utils/py/jog_run.py`.

No runtime change since `f5a4e42f`; this commit adds evidence only.

VERDICT: PASS
Basis: provenance gap closed, scope receipt added, byte-identity deferral recorded honestly; requesting round 2.

Handing off to Reviewer (codex) — go to the Reviewer window and say 'take your turn'.

### Reviewer · Round 2

VERDICT: PASS
Basis: Ship within this review's envelope. The Round 1 provenance finding is resolved; current source and retained red/green controls support the approved local-or-hosted landing behavior. No open required correction remains. The separate full gate and independent current-HEAD range attestation remain outer-harness responsibilities; DB byte identity is explicitly unmeasured. Reversibility: Easy — the existing one-function reader/writer change.
swept file: yes

- [Pass] **Round 1 provenance correction is complete.** `TESTS-RESULTS/2026-10-24+GH-1208/checks-f5a4e42f/provenance.jsonl:19` covers the retained baseline's exact digest and 13,573-byte size, with command, revision and exit result. All 19 records match nonempty retained files. `SUMMARY.md:38-42` records both the correction and the byte-identity limit. No runtime change is needed.
- [Pass] **The entire artifact and bounded landing path still agree.** Artifact `.relay-artifacts/GH-1208-JOG-LAND-LOCAL-RECEIPT.md:1-149` was swept, including frontmatter, status, observations, alternatives, rollback, verification, limitation and ratings. `utils/py/jog_run.py:1189-1201` preserves the hosted query/error handling and first matching run's completed/success predicate; `:1202-1218` reads the exact issue's `Completed` row and PR substring through the existing read-only connection; `:1219-1223` names both remedies on refusal; `:1235-1239` safely serializes hosted/local evidence. The local predicate matches the reconciler at `utils/py/wave_reconcile.py:1520-1521,1550-1558`. The approved-receipt and tail-proof boundaries were read at `jog_run.py:1041-1134`. No additional pre-existing defect was found in the artifact or this bounded path. Root cause: the consumer retained a hosted-per-merge requirement after intentional dispatch-only reconciliation; fix site: `jog_land`.
- [Pass] **Retained functional controls remain persuasive.** Baseline `gh280-unmodified-f5a4e42f.log:226-227` reports 223/223, rc=0. Under `checks-f5a4e42f/`, `reverted-gh1127.log:175` refuses on the old hosted requirement; `fixed-neither.log:175` refuses with both remedies; their retained `.rc` files are 1. `fixed-gh1127.log:175-189` records local-only landing, null hosted evidence and L6/L7 replay with unchanged selected counts; its `.rc` is 0. Its 225 PASS lines comprise the existing 223 assertions plus two manual marker observations, while the suite's own summary remains 223 (`:228`). The retained landing JSON's local object exactly matches the GH-901 Completed row in `rows-fixed-gh1127.json`, including `(PR #42)`.
- [Pass] **Variant scope, admission and evidence wording remain bounded.** Read-only `difflib` comparison again showed only the workflow-specific empty hosted answer, GH-901/releases-mode seed and commit, diagnostic/marker capture, and NEITHER's removal of L5 reconciliation (`variant-GH1127.sh:46,1010-1030`; `variant-NEITHER.sh:1010-1027`); the existing landing/replay assertions remain. `checks.sh:68-69` and `reevaluation.txt:1-5` explain the two anchoring FAILs honestly. Artifact `:16-21,136-149` retains GH-831 scope and the legacy-ledger limitation; `releases.sql:893,4013` carries 78/75/50/85 and `accepted_start: true`.
- [Pass] **The supplied scope receipt is consistent with the live implementation.** `scope-80e67677-to-head.txt:1,32-39` names reviewed head `b177c535e02c3c2585dac7d10a551a6e54001a27` and an empty protected-path remainder. Its only source patch (`:42-84`) is the approved gate/marker change. Computing the live file's blob digest without invoking git gives `7b5f1f5f8d1a034fc75cc773a7cb28ed31e2320f`, matching the receipt's new-file prefix at `:39`. This corroborates the supplied patch, not an independently queried current-HEAD range.

  Read-only evidence probe (exit `0`; output saved only under `.relay-scratch/round2-check.txt`):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PY' > .relay-scratch/round2-check.txt
  import hashlib,json,re
  from pathlib import Path
  b=Path('TESTS-RESULTS/2026-10-24+GH-1208'); c=b/'checks-f5a4e42f'
  rs=[json.loads(s) for s in (c/'provenance.jsonl').read_text().splitlines() if s.strip()]
  assert rs
  for r in rs:
      raw=(c/r['artifact']).read_bytes()
      assert raw and len(raw)==r['bytes'] and hashlib.sha256(raw).hexdigest()==r['sha256']
  raw=(b/'gh280-unmodified-f5a4e42f.log').read_bytes(); h=hashlib.sha256(raw).hexdigest()
  assert any(r['sha256']==h for r in rs)
  print('provenance:',len(rs),'valid records; baseline covered:',len(raw),h)
  for name,p in [('baseline',b/'gh280-unmodified-f5a4e42f.log')]+[(n,c/(n+'.log')) for n in ['reverted-gh1127','fixed-gh1127','fixed-neither']]:
      s=p.read_text(); assert s
      rc='0' if name=='baseline' else (c/(name+'.rc')).read_text().strip()
      print(name,'PASS',len(re.findall(r'^\s*PASS:',s,re.M)),'FAIL',len(re.findall(r'^\s*FAIL:',s,re.M)),'rc',rc)
  d=json.loads((c/'landing-fixed-gh1127.json').read_text())
  rows=json.loads((c/'rows-fixed-gh1127.json').read_text())
  r=next(r for r in rows if r['global_id']==d['local_reconcile']['roadmap_gid'])
  assert d['hosted_reconcile'] is None and r['gh_number']==901 and r['section']=='Completed'
  assert r['raw_text']==d['local_reconcile']['raw_text'] and '(PR #42)' in r['raw_text']
  print('marker: hosted null; exact GH-901 Completed row',r['global_id'])
  s=Path('utils/py/jog_run.py').read_bytes()
  blob=hashlib.sha1(b'blob '+str(len(s)).encode()+b'\0'+s).hexdigest()
  receipt=(b/'scope-80e67677-to-head.txt').read_text()
  assert re.search(r'index [0-9a-f]+\.\.'+blob[:8],receipt)
  print('live jog_run.py blob:',blob,'matches supplied scope patch')
  PY
  ```
  Decisive output:
  ```text
  provenance: 19 valid records; baseline covered: 13573 9538f6eadf8203ab855be710d50989bb93180e930ce6b029d5f8452536a89801
  baseline PASS 223 FAIL 0 rc 0
  reverted-gh1127 PASS 172 FAIL 1 rc 1
  fixed-gh1127 PASS 225 FAIL 0 rc 0
  fixed-neither PASS 172 FAIL 1 rc 1
  marker: hosted null; exact GH-901 Completed row rmi-01M5RKXFK1T9EH4JF8J8KXT3J6
  live jog_run.py blob: 7b5f1f5f8d1a034fc75cc773a7cb28ed31e2320f matches supplied scope patch
  ```

- [Unverified — needs clone run] **Full gate and byte identity remain outside this approval's empirical claims.** No suite, executable fixture, pytest or gate was executed in this turn. `SUMMARY.md:33-35` leaves the separate full gate pending; `:40-42` explicitly defers byte hashes. Existing L6/L7 count/replay evidence meets the bounded replay claim, without establishing DB byte identity.
- [Unverified — no git permitted] **Current-HEAD historical scope was not independently queried.** The supplied historical scope receipt and matching source blob close the missing-documentation point. The harness/outer reviewer must still bind the current revision and protected-path range; no git command or self-commit was run here.

Graph check: Verify tier, nearest available index is the foreign primary checkout `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-10-24T22:06:23Z`; no index exists for this isolated worktree. Current local source/receipts are the evidence. Coverage reported missing task-doc metadata and suite parse gaps `715-716`; the task documents and that suite range were read directly. No claim of exhaustive graph coverage is made.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
