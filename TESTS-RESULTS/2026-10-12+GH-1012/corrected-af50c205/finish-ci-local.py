import hashlib,json,re,shutil,subprocess
from pathlib import Path
ROOT=Path('/private/tmp/XYZ-forge-gh1012-corrected-release-2026-10-12-verify')
OUT=Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/corrected-release')
F='af50c205e3f04f3fc6a02ac6c402f2013123b127'
args={'head':('rev-parse','HEAD'),'origin':('remote','get-url','origin'),'bare':('rev-parse','--is-bare-repository'),'shallow':('rev-parse','--is-shallow-repository'),'name':('config','--local','--get','user.name'),'email':('config','--local','--get','user.email'),'status':('status','--porcelain=v1'),'tracked_status':('status','--porcelain=v1','--untracked-files=no'),'common':('rev-parse','--git-common-dir'),'gitdir':('rev-parse','--absolute-git-dir'),'local_config':('config','--local','--list')}
after={}
for k,v in args.items():
 r=subprocess.run(['git',*v],cwd=ROOT,capture_output=True,text=True);after[k]={'rc':r.returncode,'value':r.stdout.strip(),'stderr':r.stderr.strip()}
before=json.loads((OUT/'identity-before.json').read_text());(OUT/'identity-after.json').write_text(json.dumps(after,indent=2)+'\n')
assert before==after,'external identity/content changed'
records=[]
for p in (ROOT/'.tick/telemetry').glob('ci-local-sequential*'):
 rows=[json.loads(s) for s in p.read_text().splitlines()]
 if rows[0].get('commit')==F and rows[-1].get('event')=='run.summary' and rows[-1].get('recorded')=='yes':records.append((p,rows))
assert len(records)==1,[(str(p),rows[-1]) for p,rows in records]
p,rows=records[0];summary=rows[-1];assert summary['failed']==0 and summary['envelope_drift']=='none'
shutil.copyfile(p,OUT/'ci-local.telemetry.jsonl')
record=ROOT/'.gate-evidence'/f'{F}.txt';text=record.read_text();assert f'commit: {F}' in text and 'result: green' in text and 'NOT-promotion-evidence: self-reported' in text
shutil.copyfile(record,OUT/'gate-record.txt')
verdicts=[line.split('\t') for line in text.split('--- per-suite verdicts ---\n',1)[1].splitlines()];assert verdicts and all(v[1] in ('pass','skip') for v in verdicts)
skips=[v[0] for v in verdicts if v[1]=='skip'];assert skips==['acorn-extract.sh']
assert any(x.get('event')=='stage' and x.get('stage')=='npm ci + acorn-extract' and x.get('rc')==0 for x in rows) or any(x.get('event')=='stage' and x.get('name')=='npm ci + acorn-extract' and x.get('rc')==0 for x in rows)
raw=(OUT/'ci-local.log').read_bytes();shells=[v[0] for v in verdicts if v[0].endswith('.sh')];start=raw.index(('=== '+shells[0]+' ===\n').encode());segment=raw[start:].replace(b'SKIP (already run above): acorn-extract.sh\n',b'',1)
size=int(re.search(r'output-bytes: (\d+)',text)[1]);expected=re.search(r'output-sha256: ([0-9a-f]{64})',text)[1];transcript=segment[:size];matched=len(transcript)==size and hashlib.sha256(transcript).hexdigest()==expected
if matched:(OUT/'suite-transcript.log').write_bytes(transcript)
result={'candidate':F,'exit':0,'identity_unchanged':True,'start':rows[0],'summary':summary,'verdicts_recorded':len(verdicts),'pass_verdicts':sum(v[1]=='pass' for v in verdicts),'duplicate_skip':skips,'acorn_ran_in_npm_stage':True,'suite_transcript_hash_verified':matched,'record_output_bytes':size,'record_output_sha256':expected,'full_log_sha256':hashlib.sha256(raw).hexdigest(),'limit':'local self-reported full gate; live-agent turn deliberately skipped; exact resulting-main hosted boundary still required'}
(OUT/'local-full-summary.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
