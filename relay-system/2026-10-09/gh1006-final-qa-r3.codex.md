# GH-1006 final independent QA — round 3

Shipped relay driver exited 0; attested Approved against c0abced3ae47fc9e0e4345f55eb7fc8cdf049e6d. Historical round-2 receipt remains separate; this supersedes its code approval for the changed artifact.

### Reviewer · Round 3 · codex

VERDICT: PASS
Basis: The placement correction preserves the reviewed observer payload and direct-child execution. Fresh focused evidence matches the current launcher and registry files. The GH-492 disposition follows the explicit standing non-Small flaky-suite policy. Code approval only; the historical full gate is RED, and a passing final classified macOS gate remains required before publication/readiness. No continuation, merge, or issue closure is approved.

swept file: yes

Coverage: read the complete current `relay-automation/marathon.sh` (705 lines), `validate.sh` (1590), `test/gh306-registry-bidirectional.sh` (205), `relay-automation/README.md` (805), `skills/1-hourly/relay-xyz/SKILL.md` (753), and GH-1006 plan (303). Inspected the CHANGELOG entry, current driver receipt/attested-candidate seams, Small registry, existing inventory suite, retained probe sources/results/provenance, package and read-only ledger. Graph tools are unavailable; current source fallback was used, with no graph generation/coverage claim. No git command, suite, executable fixture or launcher invocation was run. Revision/base labels remain producer-supplied; no ancestry verification is claimed.

- [Pass] **Embedding preserves the runtime contract.** `relay-automation/marathon.sh:54-56` dispatches the internal action before ordinary launcher setup and uses `exec python3 -`, preserving the PID/parent relationship. All six launcher action sites use that entrypoint (`:546`, `:564`, `:570`, `:628`, `:649`, `:652`). Probe A below found the 255-line payload hash equal to the historical helper hash and the former module absent. Bounds/defaults/legacy refusal remain at `:393-418`; absolute-slot consumption at `:211-249`; one observer outside the phase loop at `:560-575`; exact-child serial waits at `:638-660`. Receipt identity/qualification (`:129-157`), liveness-only heartbeat (`:160-180`), duplicate/re-verification exclusions (`:289-301`) and separate terminal reporting (`:303-307`) retain their reviewed meaning. No fix requested.
- [Pass] **Fresh lifecycle evidence measures the embedded entrypoint.** `embedded/probe-source.txt` launches the actual script, asserts a nonempty observer PID using ` - observe `, and measures until that reader exits. `embedded/checks.json` retains TERM 0.196s/143, INT 0.134s/130, group TERM 0.134s/143 and owner loss 0.153s/-9. `embedded/supplement-source.txt` extracts the embedded payload for N=6/N=18 whole-window and malformed/foreign heartbeat controls. Probe A found 38+13 passing controls with current launcher hashes and an equal identity bracket. The original logger red/disproof remains in `manual/signal-ledger.json` (group exit -13 versus protected-reader 143); its opt-in protection remains at `marathon.sh:527`. These are inspected producer measurements, not independent runtime reruns or proof of stopped descendants. No fix requested.
- [Pass] **The inventory correction keeps the existing guard effective.** `gate-correction/push-full-gate.log:420-424` retains the concrete refusal: `NEW script added (utils/py/marathon_progress.py) — loose scripts prohibited (GH-777).` The current helper is inside the existing entrypoint; `gate-correction/gh1006-embedded-ratchet.log` records `clean (matches baseline, 0 new scripts/connects)` and passing negative controls. The existing `test/gh777-inventory-ratchet.sh` still checks the live tree, rogue script, rogue connection and refused baseline growth; GH-777 remains registered. Probe A matches the retained successful log hash and all three corrected source hashes. No new guard, suite or baseline exception is requested.
- [Pass] **GH-492 retirement is an explicit policy disposition.** `gate-correction/gh492-idle-kill.sh.log` records 14 pass/2 fail, including blocked idle 0.6563s versus progressing 0.3743s; `push-full-gate.log:427-429` records its successful serial retry. The final red names GH-777 alone (`:916-919`). `utils/ci-route.sh:38` excludes the idle suite from Small; `validate.sh:219` documents removal and `test/gh306-registry-bidirectional.sh:48` explicitly exempts it while retaining the suite. This matches AGENTS' instruction to turn off an observed flaky suite outside Small; it does not establish an idle-diagnostics runtime fix. Current retained launcher 35/35, registry 10/10, inventory controls and idle focused 16/16 logs are hash-bound by `gate-correction/provenance.jsonl`. No fix requested.
- [Pass] **Documentation, package and held scope remain coherent.** Literal reviewer IDs remain in the eight recipes (`skills/1-hourly/relay-xyz/SKILL.md:407`, `:429`, `:451`; `relay-automation/README.md:546`, `:575`, `:603`, `:672`, `:689`), and verification still requires separate full clones (`README.md:476-496`; `SKILL.md:644-665`). Repair guidance at `SKILL.md:69-104` retains authorization, original deadline/attempts, one episode, three affirmative advisory seats, exclusions, independent QA/gates and publish-and-park. The plan's Conditional continuation section and `CHANGELOG.md:3-19` honestly hold #752/#1004-dependent continuation. Probe A found all 18 package members byte-equal to source, both retained ledger rows/eight events intact, and ratings 80/65/80/45 without override. No fix requested.
- [Unverified — needs clone run] **The final full gate remains owed after this approval.** The retained 952-second full run exited 1 and refused the push; its identity bracket matches. It is failure evidence, not qualification of this corrected artifact. Run the classified macOS gate on the final approved runtime in a disposable full clone and inspect intact identity plus actual PR base/head/diff and receipts before readiness. This reviewer ran no suite or signal fixture. Earlier 17/17 monitor and 223/223 driver results remain retained focused evidence for unchanged contracts, not a fresh full-gate result.

Probe A (read-only text/hash/AST/package/SQLite queries; exit 0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
from pathlib import Path
import ast,hashlib,json,re,sqlite3,tarfile
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
sha=lambda data: hashlib.sha256(data).hexdigest()
source=Path('relay-automation/marathon.sh').read_bytes()
payload=source.split(b"<<'MARATHON_PROGRESS_PY'\n",1)[1].split(b'\nMARATHON_PROGRESS_PY',1)[0]+b'\n'
historical=json.loads((p/'manual/provenance.jsonl').read_text().splitlines()[0])
assert sha(payload)==historical['source_sha256']
assert not Path('utils/py/marathon_progress.py').exists()
ast.parse(payload)
print('embedded payload: 255 lines; SHA256 matches historical helper; former module absent; AST valid')
for row in map(json.loads,(p/'embedded/provenance.jsonl').read_text().splitlines()):
 assert row['source_sha256']==sha(source)
for name,n in [('checks.json',38),('supplement-checks.json',13)]:
 rows=json.loads((p/'embedded'/name).read_text())
 assert len(rows)==n and all(r['passed'] for r in rows)
 print('embedded',name,len(rows),'passing controls')
 for row in rows:
  if 'latency_s' in row: print(row['check'],row['latency_s'],row['exit_code'])
assert (p/'embedded/identity-before.json').read_bytes()==(p/'embedded/identity-after.json').read_bytes()
assert (p/'gate-correction/gate-identity-before.json').read_bytes()==(p/'gate-correction/gate-identity-after.json').read_bytes()
print('embedded and failed-gate identity brackets byte-equal')
rows=list(map(json.loads,(p/'gate-correction/provenance.jsonl').read_text().splitlines()))
assert len(rows)==5 and rows[0]['exit_code']==1 and all(r['exit_code']==0 for r in rows[1:])
for row in rows:
 raw=(p/'gate-correction'/row['log']).read_bytes()
 assert raw and sha(raw)==row['sha256']
 for name,digest in row.get('source_sha256',{}).items(): assert sha(Path(name).read_bytes())==digest
print('gate correction: five nonempty hash-matched logs; historical full RED + four focused GREEN; current three source hashes match')
v=Path('validate.sh').read_text()
tests=re.search(r'^TESTS=\(\n(.*?)^\)',v,re.M|re.S).group(1)
registry=re.findall(r'^\s*"([^"]+)"',tests,re.M)
exempt=re.search(r'^EXEMPT=\(\n(.*?)^\)',Path('test/gh306-registry-bidirectional.sh').read_text(),re.M|re.S).group(1)
small=re.search(r'^SUBSYSTEM_TESTS_small="([^"]+)"',Path('utils/ci-route.sh').read_text(),re.M).group(1).split()
assert registry and small and 'gh492-idle-kill.sh' not in registry and 'gh492-idle-kill.sh' not in small
assert '"gh492-idle-kill.sh"' in exempt and Path('test/gh492-idle-kill.sh').is_file()
assert 'gh777-inventory-ratchet.sh' in registry and 'gh306-registry-bidirectional.sh' in registry
print('GH-492 absent from full/Small, exempt, suite retained; GH-777/GH-306 remain registered')
with tarfile.open('skills/1-hourly/relay-automation/relay-pkg.tar.gz') as tar:
 members=[m for m in tar.getmembers() if m.isfile()]
 assert len(members)==18 and all(tar.extractfile(m).read()==Path(m.name).read_bytes() for m in members)
 print('package: 18 members byte-match current source')
db=sqlite3.connect('file:releases.db?mode=ro',uri=True);db.execute('PRAGMA query_only=ON')
saved=json.loads((p/'recipe-fix/integration-readback.json').read_text())
rows=db.execute('select gh_number,global_id,section,status_marker,doc_path from roadmap_items where gh_number in (1005,1006)').fetchall()
events=db.execute('select gh_number,event,at from work_events where gh_number in (1005,1006) order by at,id').fetchall()
assert sorted(map(tuple,saved['rows']))==sorted(rows) and list(map(tuple,saved['events']))==events
assert db.execute('select rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr from roadmap_items where gh_number=1006').fetchone()==(80,65,80,45,None)
print('ledger: retained two rows/eight events match; GH-1006 ratings 80/65/80/45, no override')
PY
```

Decisive output: `embedded payload: 255 lines; SHA256 matches historical helper; former module absent; AST valid`; `embedded checks.json 38 passing controls`; `embedded supplement-checks.json 13 passing controls`; `embedded and failed-gate identity brackets byte-equal`; `gate correction: five nonempty hash-matched logs; historical full RED + four focused GREEN; current three source hashes match`; `GH-492 absent from full/Small, exempt, suite retained; GH-777/GH-306 remain registered`; `package: 18 members byte-match current source`; `ledger: retained two rows/eight events match; GH-1006 ratings 80/65/80/45, no override`.

Probe B (retained earlier focused-log integrity; exit 0):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
import hashlib,json
p=Path('TESTS-RESULTS/2026-10-09+GH-1006')
for line in (p/'focused/provenance.jsonl').read_text().splitlines():
 r=json.loads(line);raw=(p/'focused'/r['log']).read_bytes()
 assert raw and r['exit_code']==0 and hashlib.sha256(raw).hexdigest()==r['sha256']
 print(r['log'], 'retained exit 0; hash matches')
PY
```

Decisive output: `retained exit 0; hash matches` for `gh1006-final-marathon.log`, `gh1006-final-monitor.log`, `gh1006-candidate-receipts.log`, `gh1006-package.log`, and `gh1006-frozen.log`.

Whole-file sweep found no additional material pre-existing defect within the declared local operational envelope. This is not a repository-wide audit or validation of every external provider/CLI statement in the reference documentation. Only this relay file was edited.

Relay closed (Approved), no further review turn needed. Producer codex-author owns the remaining final classified gate and publication checks; this approval does not discharge them. The binding three-round review budget is exhausted.


### Attestation · relay-drive — 2026-10-09T16:49:43Z
task: RELAY-GH1006-FINAL-QA-GATE-CORRECTION
reviewer: codex
status: Approved
reviewed-head: c0abced3ae47fc9e0e4345f55eb7fc8cdf049e6d
added-range: 33985+11640
added-sha256: c0ddd16587c999b74bbdce969febcf4593125214a1ee6978ad7b3f478be86688
