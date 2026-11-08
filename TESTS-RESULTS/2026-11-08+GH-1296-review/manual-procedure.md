# Focused manual controls

This is a controlled helper/freshness-boundary check, not historical same-wave acceptance or a full preflight run. Database and planner are fixtures only for the freshness cases.

Command: primary Python3.13 venv `python temp/gh1296-review/manual.py` from the task clone. Baseline module is `git show 08ff07de:utils/py/harness.py`, saved to `temp/gh1296-review/harness_before.py`.

```python
import importlib.util,sys,json,hashlib,tempfile
from pathlib import Path
from types import SimpleNamespace
root=Path.cwd();sys.path.insert(0,str(root/'utils/py'))
def load(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);sys.modules[name]=m;s.loader.exec_module(m);return m
before=load('before',root/'temp/gh1296-review/harness_before.py');after=load('after',root/'utils/py/harness.py')
cases=[('malformed',{'artifacts':['a'],'artifacts_new':[{}]},True),('normalized',{'artifacts':[' ./a ']},False),('missing',{'artifacts':['gone']},True),('new',{'artifacts':['new'],'artifacts_new':['new']},False),('parent',{'artifacts':['missing/../a']},True),('raw exemption',{'artifacts':[' new '],'artifacts_new':[' new ']},True)]
for label,c,blocked in cases:
 results=[]
 for m in (before,after):
  try:r=m._preflight_blockers({'contract':c},{'a'})
  except Exception as e:r=type(e).__name__
  results.append(r)
 assert isinstance(results[1],list) and bool(results[1])==blocked,(label,results)
 print(json.dumps({'case':label,'baseline':results[0],'candidate':results[1]}))
# Controlled packet inputs: receipt hash is real; planner/DB are fixtures. This checks freshness only.
with tempfile.TemporaryDirectory(prefix='gh1296-manual-') as td:
 t=Path(td);out=t/'out/plan-draft';out.mkdir(parents=True);(t/'backlog').mkdir();(t/'state.db').touch()
 doc=t/'capture.md';doc.write_text('original');alt=t/'earlier.md';alt.write_text('changed')
 proposal={'tick_id':'manual','provisional':{'waves':[[{'issue':1}]]}};p=out/'wave-proposal.json';p.write_text(json.dumps(proposal))
 receipt={'tool':'plan-draft','output_files':{'wave-proposal.json':hashlib.sha256(p.read_bytes()).hexdigest()}}
 class Conn:
  def execute(self,*a):return [{'json':json.dumps(receipt)}]
  def close(self):pass
 class ReachedIndex(Exception):pass
 def stop(*a):raise ReachedIndex()
 for mode in ('unchanged','edited','selected-other'):
  doc.write_text('edited' if mode=='edited' else 'original')
  (t/'backlog/manifest.json').write_text(json.dumps({'requests':{'r':{'issue':1,'doc_path':str(doc),'doc_sha256':hashlib.sha256(b'original').hexdigest()}}}))
  (t/'backlog/base-files.txt').write_text('a\n')
  after.connect=lambda *a:Conn();after._accepted_briefs=lambda *a:[];after._file_index=stop
  after._planner=lambda *a:SimpleNamespace(compute=lambda:{'deduped':[{'gh':1,'docRel':str(alt if mode=='selected-other' else doc)}]})
  try:after.make_packet(t,1,'codex');raise AssertionError('unexpected completion')
  except ReachedIndex:assert mode=='unchanged';result='passed freshness boundary'
  except ValueError as e:assert mode!='unchanged' and 'changed since init' in str(e);result=str(e)
  print(json.dumps({'case':mode,'candidate':result}))

```
