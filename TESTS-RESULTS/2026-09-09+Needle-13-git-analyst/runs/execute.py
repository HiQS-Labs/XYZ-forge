import concurrent.futures,datetime,json,os,pathlib,subprocess,urllib.request
root=pathlib.Path.cwd();b=root/'TESTS-RESULTS/2026-09-09+Needle-13-git-analyst'
def family(ids):
 for name in ids:
  d=b/'runs'/name;d.mkdir(exist_ok=True)
  for run in ['r1','r2']:
   env=os.environ.copy();env.update(CONSULT_ROOT=str(root),CODEX_BIN=str(b/'adapters'/(name+'.py')),CODEX_FLAGS='',LOCAL_SPIKE_ROOT=str(d),LOCAL_SPIKE_RUN=run,ANALYST_PROMPT_FILE=str(b/'QUESTIONS.md'),ANALYST_SOURCE_REFERENCE=str(b/'source-reference.json'),CONSULT_TIMEOUT='900',CONSULT_IDLE_S='120')
   print('START',name,run,flush=True)
   with (d/(run+'-consult.log')).open('x')as f:
    p=subprocess.run(['bash','relay-automation/consult.sh','--models','codex','--prompt-file',str(b/'QUESTIONS.md'),'--out',str(root/'relay-system/2026-09-09'),'--label','git-analyst-'+name+'-'+run],env=env,stdout=f,stderr=subprocess.STDOUT)
   answer=d/(run+'-answer.md')
   if name=='muse13-high' and not answer.exists():
    events=[json.loads(l)for l in (d/(run+'-events.jsonl')).read_text().splitlines()if l.strip()]
    (d/(run+'-extraction-needed.json')).write_text(json.dumps({'event_types':[e.get('type')for e in events]},indent=2))
   if answer.exists():
    g=subprocess.run(['python3',str(b/'grade.py'),str(b/'expected.json'),str(answer),str(d/(run+'-answer.json'))],capture_output=True,text=True)
    (d/(run+'-grade.json')).write_text(g.stdout);(d/(run+'-grader-stderr.txt')).write_text(g.stderr)
   print('END',name,run,p.returncode,flush=True)
   if p.returncode:break
try:
 j=json.load(urllib.request.urlopen('http://localhost:1234/api/v1/models',timeout=10));matches=[m for m in j['models']if m['key']=='google/gemma-4-31b-qat'];available=bool(matches and matches[0].get('loaded_instances'))
except Exception as e:available=False;matches=[];error=type(e).__name__
d=b/'runs/gemma31-off';d.mkdir(exist_ok=True);(d/'availability.json').write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'available':available,'matches':matches,'error':locals().get('error'),'no_inference_if_unavailable':True},indent=2))
families=[['luna-medium','terra-medium','terra-low','spark-high','spark-xhigh'],['agy37-high','agy31pro-high'],['flashlite31'],['muse13-high']]
if available:families.append(['gemma31-off'])
with concurrent.futures.ThreadPoolExecutor(max_workers=5)as ex:
 for f in concurrent.futures.as_completed([ex.submit(family,x)for x in families]):f.result()
