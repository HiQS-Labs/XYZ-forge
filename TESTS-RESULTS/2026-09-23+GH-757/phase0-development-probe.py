import collections,hashlib,importlib.util,json,re,sys,urllib.parse,urllib.request
from pathlib import Path
source=Path(sys.argv[1]) if len(sys.argv)>1 else Path('../Needle-fork/spike/coding_core/prepare_openhands.py')
spec=importlib.util.spec_from_file_location('openhands',source)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
pages=[]
for offset in (0,100,200):
 q=urllib.parse.urlencode({'dataset':m.DATASET,'config':'default','split':'train','offset':offset,'length':100})
 with urllib.request.urlopen('https://datasets-server.huggingface.co/rows?'+q,timeout=60) as f:d=json.load(f)
 assert d['num_rows_total']==67074 and len(d['rows'])==100
 assert all(not r.get('truncated_cells') for r in d['rows'])
 pages.extend(r['row'] for r in d['rows'])
 print('fetched',offset,'..',offset+99,file=sys.stderr)
old=pages[:100]
old_ids={r['instance_id'] for r in old};old_repos={r['repo'] for r in old}
agg=collections.Counter();taskaudit=collections.Counter();labels=collections.Counter();repos=collections.Counter();issues=collections.Counter();audits=collections.Counter();errors=collections.Counter();examples=[]
for r in pages[100:]:
 agg['source_rows']+=1
 if r['repo'] in old_repos or r['instance_id'] in old_ids:
  agg['old_repo_or_issue_overlap']+=1;continue
 if r.get('resolved')!=1:
  agg['unresolved']+=1;continue
 try: rows=m.trajectory_rows(r,[],context='q3',audit=audits)
 except Exception as e: errors[type(e).__name__]+=1;continue
 if not rows: agg['no_q3_rows']+=1;continue
 agg['eligible_trajectories']+=1
 messages=m._json_value(r.get('trajectory'),'trajectory')
 users=[z.get('content','') for z in messages if isinstance(z,dict) and z.get('role')=='user']
 first=next((z for z in users if isinstance(z,str) and z.strip()),'')
 match=re.search(r'<issue_description>(.*?)</issue_description>', first, re.S)
 taskaudit['source_has_issue_tag']+=bool(match and match.group(1).strip())
 taskaudit['source_fallback_user_text']+=not bool(match and match.group(1).strip())
 taskaudit['task_at_cap']+=len(rows[0]['task'])>=2000
 taskaudit['observation_at_cap']+=len(rows[0]['observation'])>=2000
 taskaudit['multiple_user_messages']+=len(users)>1
 capped=[rows[min(len(rows)-1,(2*j+1)*len(rows)//16)] for j in range(8)]
 agg['eligible_rows_raw']+=len(rows);agg['eligible_rows_cap8']+=len(capped)
 repos[r['repo']]+=1;issues[r['instance_id']]+=1
 labels.update(x['target'] for x in capped)
 if len(examples)<8: examples.append({'repo_sha256':hashlib.sha256(r['repo'].encode()).hexdigest()[:12],'n_rows':len(rows),'sample_labels':[x['target'] for x in capped[:4]],'task_len':len(rows[0]['task']),'observation_len':len(rows[0]['observation'])})
receipt={'dataset':m.DATASET,'revision':m.REVISION,'source_offset':[0,299],'new_window':[100,299],'old_window_repo_count':len(old_repos),'old_window_issue_count':len(old_ids),'counts':dict(agg),'new_repository_count':len(repos),'new_issue_count':len(issues),'labels_cap8':dict(labels),'audit':dict(audits),'task_audit':dict(taskaudit),'errors':dict(errors),'max_trajectories_per_repo':max(repos.values(),default=0),'max_trajectories_per_issue':max(issues.values(),default=0),'examples_sanitized':examples}
Path('phase0-development-probe.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
