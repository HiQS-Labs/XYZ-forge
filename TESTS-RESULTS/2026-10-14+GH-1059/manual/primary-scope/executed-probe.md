Manual fixture input; same real Git/Trash and stubbed API/URL envelope as original manual probe.

```python
import contextlib,io,json,os,subprocess,sys,tempfile,types
from pathlib import Path
from unittest.mock import patch
ROOT=Path.cwd().resolve();sys.path.insert(0,str(ROOT/'skills/2-daily/merge-cleanup/scripts'))
import scan_clones as sc,merge_cleanup as mc
results=[];captured=[]
with tempfile.TemporaryDirectory(prefix='gh1059-manual-',dir=ROOT/'temp') as raw:
 W=Path(raw).resolve();assert W.is_dir() and W.is_relative_to(ROOT/'temp')
 meta=W/'pr.json';stub=W/'gh';stub.write_text('#!/usr/bin/env python3\nimport json,os,sys\nif os.environ.get("GH1059_API_FAIL"): sys.exit(1)\nif sys.argv[1:3]==["pr","view"]: print(open(os.environ["GH1059_META"]).read())\nelif sys.argv[1:3]==["repo","view"]: print(json.dumps({"url":"https://github.com/Fixture/Repo"}))\nelif sys.argv[1:3]==["pr","list"]: print("[]")\nelse: sys.exit(1)\n');stub.chmod(0o755)
 home=W/'home';home.mkdir();(home/'.Trash').mkdir()
 def git(p,*args):
  p=Path(p).resolve();assert p.is_dir() and p.is_relative_to(W)
  return subprocess.run(['git','-C',str(p),*args],capture_output=True,text=True,check=True).stdout.strip()
 def repo(name):
  dest=W/name;assert dest.parent==W and not dest.exists()
  subprocess.run(['git','init','-q','-b','development',str(dest)],check=True,capture_output=True)
  git(dest,'config','user.name','fixture');git(dest,'config','user.email','fixture@example.invalid')
  (dest/'README').write_text('base');git(dest,'add','README');git(dest,'commit','-qm','base')
  return dest
 origin=W/'origin.git';subprocess.run(['git','init','-q','--bare','-b','development',str(origin)],check=True,capture_output=True)
 primary=repo('primary');git(primary,'remote','add','origin',str(origin));git(primary,'push','-qu','origin','development')
 (primary/'operator.txt').write_text('unrelated primary work must remain')
 base=git(primary,'rev-parse','HEAD')
 def candidate(name):
  dest=W/name;assert dest.parent==W and not dest.exists()
  subprocess.run(['git','clone','-q',str(origin),str(dest)],check=True,capture_output=True)
  git(dest,'config','user.name','fixture');git(dest,'config','user.email','fixture@example.invalid')
  git(dest,'switch','-qc',name);(dest/'change').write_text(name);git(dest,'add','change');git(dest,'commit','-qm',name);git(dest,'push','-qu','origin',name)
  head=git(dest,'rev-parse','HEAD');set_meta(name,head);return dest,head
 def set_meta(branch,head,**kw):
  data=dict(number=1059,url='https://github.com/Fixture/Repo/pull/1059',state='OPEN',isDraft=False,isCrossRepository=False,baseRefName='development',headRefName=branch,headRefOid=head);data.update(kw);meta.write_text(json.dumps(data))
 real=sc.run_git
 def fixture_git(p,args,**kw):
  if args==['remote','get-url','origin']:
   val='https://github.com/Other/Repo.git' if (Path(p)/'foreign-origin').exists() else 'https://github.com/Fixture/Repo.git'
   return subprocess.CompletedProcess(args,0,val+'\n','')
  return real(p,args,**kw)
 def record(name,condition,detail=''):
  assert condition,(name,detail);results.append({'case':name,'result':'PASS','detail':detail})
 def inspect(p):return sc.inspect_checkout(p,primary_repo_path=primary,published_pr=1059)
 def run(p,execute=False,argv_extra=()):
  buf=io.StringIO()
  with contextlib.redirect_stdout(buf),contextlib.redirect_stderr(buf):
   with patch.object(sys,'argv',['merge_cleanup.py','--primary',str(primary),'--retire-published-pr','1059','--checkout',str(p),*(['--execute'] if execute else []),*argv_extra]):
    rc=mc.main()
  captured.append(buf.getvalue());return rc
 with patch.dict(os.environ,{sc.GH_BIN_ENV:str(stub),'GH1059_META':str(meta),'PYTHONDONTWRITEBYTECODE':'1'}),patch.object(sc,'run_git',side_effect=fixture_git),patch.object(mc,'run_git',side_effect=fixture_git),patch.object(sc,'DEFAULT_SAFE_ROOTS',[W]),patch.object(sc,'DEFAULT_NEVER_DELETE',{W,primary}),patch.object(Path,'home',return_value=home):
  p,head=candidate('published');normal=sc.classify_local_refs(p);record('default merged-only behavior preserves open PR',normal['ok'] and bool(normal['unlanded']))
  q=inspect(p);record('published open PR eligible before merge',q['disposition']=='SAFE_REMOVE_CLONE',q['disposition_reason'])
  record('preview does not remove candidate',run(p)==0 and p.exists())
  with patch.object(mc,'prepare_primary_landing',side_effect=AssertionError('primary landing called')),patch.object(mc,'land_prs',side_effect=AssertionError('merge called')):
   record('execute uses Trash without primary landing or merges',run(p,True)==0 and not p.exists() and any((home/'.Trash').glob('published-*')))
  record('unrelated primary work preserved',(primary/'operator.txt').read_text()=='unrelated primary work must remain')
  p,head=candidate('guarded')
  for name,change in [('draft',{'isDraft':True}),('closed unmerged',{'state':'CLOSED'}),('fork',{'isCrossRepository':True}),('wrong base',{'baseRefName':'main'}),('wrong repo',{'url':'https://github.com/Other/Repo/pull/1059'}),('stale head',{'headRefOid':'0'*40}),('malformed head',{'headRefOid':None}),('malformed branch',{'headRefName':None}),('missing branch',{'headRefName':'missing'})]:
   set_meta('guarded',head,**change);r=sc.classify_local_refs(p,published_pr=1059);record(name+' preserved',not r['ok'] and bool(r['failed_query']),r['failed_query'])
  set_meta('guarded',head)
  with patch.dict(os.environ,{'GH1059_API_FAIL':'1'}):record('API outage preserves',not sc.classify_local_refs(p,published_pr=1059)['ok'])
  (p/'local-only').write_text('unique');record('dirty/untracked preserves',inspect(p)['disposition']=='PRESERVE_DIRTY');(p/'local-only').unlink()
  (p/'stash-content').write_text('unique');git(p,'add','stash-content');git(p,'stash','push','-qm','unique');record('stash preserves',inspect(p)['disposition']=='PRESERVE_STASH');git(p,'stash','pop','-q');(p/'stash-content').unlink()
  (p/'local-successor').write_text('unique');git(p,'add','-A');git(p,'commit','-qm','local successor');r=sc.classify_local_refs(p,published_pr=1059);record('unpushed successor preserves',bool(r['unlanded']))
  git(p,'switch','--detach',head);record('unpublished other ref still preserves',bool(sc.classify_local_refs(p,published_pr=1059)['unlanded']))
  p,head=candidate('detached');git(p,'switch','--detach',head);(p/'detached-only').write_text('unique');git(p,'add','detached-only');git(p,'commit','-qm','unique detached');record('detached local-only HEAD preserves',bool(sc.classify_local_refs(p,published_pr=1059)['unlanded']))
  p,head=candidate('dependent');wt=W/'dependent-worktree';git(p,'worktree','add','--detach',str(wt),head);record('parent with dependent worktree preserves',inspect(p)['disposition']=='PRESERVE_PARENT_CLONE');git(p,'worktree','remove',str(wt))
  with patch.object(sc,'inspect_driver_lock',return_value={'locked':True,'alive':True,'pid':os.getpid()}):record('live driver preserves',inspect(p)['disposition']=='ACTIVE_LOCKED')
  with patch.object(sc,'inspect_tick_claims',return_value={'verified':True,'has_claims':True,'details':'peer claim'}):record('peer claim preserves',inspect(p)['disposition']=='ACTIVE_TICK_CLAIM')
  with patch.object(sc,'inspect_open_handles',return_value={'verified':True,'active':True,'details':'peer process'}):record('peer open handle preserves',inspect(p)['disposition']=='ACTIVE_PROCESS')
  with patch.object(sc,'inspect_open_handles',return_value={'verified':False,'active':False,'details':'enumeration failed'}):record('unverifiable session preserves',inspect(p)['disposition']=='PRESERVE_UNVERIFIED_SESSION')
  (p/'foreign-origin').write_text('marker');record('foreign origin rejects whole explicit scope',run(p,True)==2 and p.exists());(p/'foreign-origin').unlink()
  record('protected primary cannot retire',run(primary,True)==2 and primary.exists())
  record('candidate ancestor/executing dir cannot retire',run(W,True)==2 and W.exists())
  try:run(p,argv_extra=('--teardown-only',))
  except SystemExit as e:record('mixed workflow modes rejected',e.code==2)
  else:raise AssertionError('mixed modes accepted')
  missing_home=W/'missing-home';missing_home.mkdir()
  with patch.object(Path,'home',return_value=missing_home):record('missing Trash refuses removal',run(p,True)==1 and p.exists())
  wt=W/'published-worktree';git(p,'worktree','add','--detach',str(wt),head);record('linked worktree retires via native Git',run(wt,True)==0 and not wt.exists() and p.exists());record('parent metadata deregistered worktree',str(wt) not in git(p,'worktree','list','--porcelain'))

  record('candidate now safe again',inspect(p)['disposition']=='SAFE_REMOVE_CLONE')
  for bad_primary in ['', '.']:
   with patch.object(sys,'argv',['merge_cleanup.py','--primary',bad_primary,'--retire-published-pr','1059','--checkout',str(p)]),patch.object(mc,'retire_published_checkouts',side_effect=AssertionError('missing primary identity reached retirement')):
    try:mc.main()
    except SystemExit as e:record('non-absolute primary rejects '+repr(bad_primary),e.code==2)
    else:raise AssertionError('non-absolute primary accepted')

  calls=[0];original_inspect=mc.inspect_checkout
  def changed_after_scan(*a,**k):
   value=original_inspect(*a,**k);calls[0]+=1
   if calls[0]==1:set_meta('dependent',head,isDraft=True)
   return value
  with patch.object(mc,'inspect_checkout',side_effect=changed_after_scan):record('fresh inspection catches changed publication',run(p,True)==1 and p.exists() and calls[0]==2)
  set_meta('dependent',head)
  for bad in [('0','--execute'),('-1','--execute'),('1059','--execute')]:
   with patch.object(sys,'argv',['merge_cleanup.py','--primary',str(primary),'--retire-published-pr',*bad]),patch.object(mc,'prepare_primary_landing',side_effect=AssertionError('invalid mode reached broad workflow')):
    try:mc.main()
    except SystemExit as e:record('invalid/missing retirement scope rejects '+str(bad),e.code==2)
    else:raise AssertionError('invalid scope accepted')

  source=(ROOT/'skills/2-daily/merge-cleanup/scripts/scan_clones.py').read_text()
  mutant=types.ModuleType('red_admission');mutant.__file__=str(ROOT/'skills/2-daily/merge-cleanup/scripts/scan_clones.py');changed=source.replace('if published is not None:','if False:');assert changed!=source;exec(compile(changed,mutant.__file__,'exec'),mutant.__dict__)
  with patch.object(mutant,'run_git',side_effect=fixture_git):record('RED removing admission breaks published success',bool(mutant.classify_local_refs(p,published_pr=1059)['unlanded']))
  mutant=types.ModuleType('red_draft');mutant.__file__=str(ROOT/'skills/2-daily/merge-cleanup/scripts/scan_clones.py');changed=source.replace('or pr.get("isDraft") is not False or pr.get("isCrossRepository") is not False','or pr.get("isCrossRepository") is not False');assert changed!=source;exec(compile(changed,mutant.__file__,'exec'),mutant.__dict__);set_meta('dependent',head,isDraft=True)
  with patch.object(mutant,'run_git',side_effect=fixture_git):
   r=mutant.classify_local_refs(p,published_pr=1059);record('RED removing draft guard admits draft refs',r['ok'] and not r['unlanded'])
 (ROOT/'temp/gh1059-manual-captured.log').write_text('\n'.join(captured))
(ROOT/'temp/gh1059-manual-results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(results,indent=2));print('Manual cases:',len(results))

```
