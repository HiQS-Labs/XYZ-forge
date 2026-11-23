import os,sys,json,subprocess,hashlib
from pathlib import Path
sys.path.insert(0,str(Path('utils/py').resolve()))
import rtl,gate_receipt as g,relay_attest as a
root=Path.cwd();out=root/'temp/gh1399-controls';results=[]
def git(*args):return subprocess.check_output(['git',*args],text=True).strip()
def commit(path,text):
 p=root/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text);git('add',str(path));git('-c','user.name=Control','-c','user.email=control@example.invalid','commit','-m','docs: synthetic admission control');return git('rev-parse','HEAD')
def check(name,fn,expected=True):
 try:fn();ok=True;why='accepted'
 except Exception as e:ok=False;why=str(e)
 results.append(dict(name=name,accepted=ok,expected=expected,detail=why));assert ok==expected,(name,why)
git('switch','-c','fix/gh1399-managed-control')
record=out/'accounting/.tick/attempts/managed';record.parent.mkdir(parents=True,exist_ok=True);record.write_text('2026-01-01 legacy\n')
count,ctx=rtl.lane_attempt_reserve(str(out/'accounting'),'managed',str(root),cap=3)
assert count==2
os.environ[rtl.ATTEMPT_CONTEXT_ENV]=json.dumps(ctx)
reviewed=git('rev-parse','HEAD');rf=root/'relay-system/2026-11-10/gh1399-synthetic-control.md';rf.parent.mkdir(parents=True,exist_ok=True);rf.write_text('STATUS: Approved\n\n### Reviewer synthetic input\nVERDICT: PASS\n')
canon=a.canonical(str(rf));rec=dict(schema=a.SCHEMA,task='GH1399-SYNTHETIC',reviewer='fixture',status='Approved',reviewed_head=reviewed,added_start=0,added_len=len(canon),added_sha256=a.sha256(canon),relay_file=str(rf),relay_file_rel=str(rf.relative_to(root)),target_repo=str(root),isolated=True,attested_at='2026-11-11T00:00:00Z',artifact_sha256=None)
trailer=a.trailer_text(rec);rec['trailer_sha256']=a.sha256(trailer.encode());rf.write_text(rf.read_text()+trailer);git('add',str(rf));git('-c','user.name=Control','-c','user.email=control@example.invalid','commit','-m','docs: synthetic protected review input')
ctx['attestation']=str(a.path_for(rec['task'],str(root)));rec['attempt_context']=ctx;a.write(rec);rtl.lane_attempt_finish(ctx,'active',reviewed,attestation=ctx['attestation']);os.environ[rtl.ATTEMPT_CONTEXT_ENV]=json.dumps(ctx)
check('live-reviewed-candidate',lambda:g.attempt_admission(str(root)))
before=record.read_bytes();archive=rtl.archive_lane_attempts(str(record));archctx=json.loads(os.environ[rtl.ATTEMPT_CONTEXT_ENV]);assert Path(archive).read_bytes()==before
check('archived-reference',lambda:g.attempt_admission(str(root)))
check('stale-live-reference-resolves-archive',lambda:g.attempt_admission(str(root),context_override={k:v for k,v in ctx.items() if k!='attestation'}))
commit(Path('relay-system/2026-11-10/gh1399-synthetic-postapprove.md'),'allowed transcript closeout\n')
check('postapprove-transcript',lambda:g.attempt_admission(str(root)))
check('failed-closeout-resume-same-proof',lambda:g.attempt_admission(str(root)))
commit(Path('README.md'),(root/'README.md').read_text()+'\n<!-- unrelated source after approval -->\n')
check('unrelated-candidate',lambda:g.attempt_admission(str(root)),False)
assert Path(archive).read_bytes()==before and len(before.splitlines())==2
results.append(dict(name='archive-byte-count-preservation',sha256=hashlib.sha256(before).hexdigest(),count=2))
(out/'managed-results.json').write_text(json.dumps(results,indent=2));print(json.dumps(results,indent=2))
