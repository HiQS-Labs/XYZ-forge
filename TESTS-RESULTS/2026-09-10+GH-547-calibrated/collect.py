from pathlib import Path
import sqlite3,json,re,random,hashlib,collections
p=Path(__file__).parent
c=sqlite3.connect((Path.home()/'Library/Application Support/rebalance-os/rebalance.db').as_uri()+'?mode=ro',uri=True);c.row_factory=sqlite3.Row
raw=[dict(r) for r in c.execute("select repo_full_name,number,item_type,title,body,created_at from github_items where lower(repo_full_name) like 'hiqs-labs/%' order by created_at,repo_full_name,number")]
seen=set();rows=[]
for r in raw:
 key=re.sub(r'\s+',' ',r['title'].lower()).strip()
 if key in seen or any(w in key for w in ['modernbert','luna/needle','model benchmarks','human-adjudicated hiqs']):continue
 seen.add(key);rows.append(r)
parent=list(range(len(rows)))
def find(i):
 while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
 return i
def union(a,b):parent[find(a)]=find(b)
lookup={(r['repo_full_name'].lower(),r['number']):i for i,r in enumerate(rows)}
for i,r in enumerate(rows):
 for n in re.findall(r'(?:#|GH-)(\d+)',r['title'],re.I):
  j=lookup.get((r['repo_full_name'].lower(),int(n)))
  if j is not None:union(i,j)
g={}
for i,r in enumerate(rows):g.setdefault(find(i),[]).append(r)
reps=[max(v,key=lambda r:r['created_at'] or '') for v in g.values()];reps.sort(key=lambda r:(r['created_at'] or '',r['repo_full_name'],r['number']))
a=int(.65*len(reps));b=int(.8*len(reps));rng=random.Random(5473)
# Candidate enrichment only; these buckets are NOT truth labels.
def bucket(r):
 t=r['title'].lower()
 for name,pat in [('merge_closeout',r'reconcil|close.?out|post.merge|land(ing)? '),('documentation',r'^docs|readme|documentation'),('research_evaluation',r'audit|benchmark|research|spike|compar|feasibility'),('planning_design',r'plan|design|requirements|roadmap|umbrella'),('testing_validation',r'^test|validation|test coverage|regression test'),('maintenance',r'^chore|dependenc|refactor|relocat|release:'),('feature_enhancement',r'^feat|\badd\b|introduc'),('bug_fix',r'^fix|fail|broken|crash|incorrect')]:
  if re.search(pat,t):return name
 return 'other'
pool=reps[:a];selected=[]
for name in ['merge_closeout','documentation','research_evaluation','planning_design','testing_validation','maintenance','feature_enhancement','bug_fix']:
 choices=[r for r in pool if bucket(r)==name];selected+=rng.sample(choices,min(12,len(choices)))
remaining=[r for r in pool if r not in selected];selected+=rng.sample(remaining,128-len(selected))
va=rng.sample(reps[a:b],32)
old=set()
for f in [Path.home()/'.cache/xyz-modernbert-real-v2/sample.json',Path.home()/'.cache/xyz-modernbert-rebalance/sample.json']:
 if f.exists():old.update(r['text'].strip().lower() for r in json.loads(f.read_text()))
new=[r for r in reps[b:] if r['title'].strip().lower() not in old];te=rng.sample(new,40)
allrows=[]
for split,rs in [('train',selected),('validation',va),('holdout',te)]:
 for i,r in enumerate(sorted(rs,key=lambda r:r['created_at'] or '')):
  body=r['body'] or '';allrows.append({'id':f'{split}-{i+1:03}','split':split,'repo':r['repo_full_name'],'number':r['number'],'source_type':r['item_type'],'created_at':r['created_at'],'title':r['title'],'description':body[:1800],'description_truncated':len(body)>1800})
(p/'sample.json').write_text(json.dumps(allrows,indent=2))
for split in ['train','validation','holdout']:(p/(split+'.json')).write_text(json.dumps([r for r in allrows if r['split']==split],indent=2))
for k in [0,1]:
 rs=[r for r in allrows if r['split']!='holdout'];(p/f'annotation-{k+1}.json').write_text(json.dumps([r for i,r in enumerate(rs) if i%2==k],indent=2))
print('counts',collections.Counter(r['split'] for r in allrows),'family_count',len(g),'train enrichment',collections.Counter(bucket(r) for r in selected),'holdout eligible',len(new))
