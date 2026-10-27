import json,glob,re,os,sys,collections
S=sys.argv[1]
iss=json.load(open(f'{S}/open.json')); prs=json.load(open(f'{S}/prs.json'))
rm=json.load(open(f'{S}/roadmap.json')); jog=json.load(open(f'{S}/jog.json'))
rows=collections.defaultdict(list)
for r in rm:
    if r.get('is_selected_repo') and r.get('gh_number'): rows[r['gh_number']].append(r)
jogst={}
for j in jog:
    n=j.get('gh_number'); jogst[n]=j.get('status')
docs={}
for p in glob.glob('PROJECT/1-INBOX/GH-*.md')+glob.glob('PROJECT/2-WORKING/GH-*.md'):
    m=re.match(r'GH-(\d+)-',os.path.basename(p))
    if m: docs.setdefault(int(m.group(1)),[]).append(p)
def has_contract(ps):
    for p in ps:
        t=open(p,errors='ignore').read()
        if re.search(r'(?im)^#+\s*(swarm\s+)?preflight contract',t): return True
    return False
prref=collections.defaultdict(list)
for p in prs:
    txt=p['title']+' '+p['headRefName']+' '+(p['body'] or '')
    for n in set(int(x) for x in re.findall(r'(?:#|gh-?|GH-)(\d{2,4})',txt,re.I)): prref[n].append(p['number'])
PLAN=re.compile(r'(?im)^#{1,4}\s*(remediation|proposed (fix|remediation|work|change)|plan|fix|implementation plan|scope|remedy|proposal)')
ACC=re.compile(r'(?im)^#{1,4}\s*acceptance|acceptance criteria|^- \[ \]')
out=[]
stats=collections.Counter(); dom=collections.Counter()
for i in iss:
    n=i['number']; b=i['body'] or ''
    r=rows.get(n,[])
    rated=[x for x in r if x.get('rating_pri') is not None]
    rt=None; ph=False
    if rated:
        x=rated[0]; rt=(x['rating_pri'],x['rating_sev'],x['rating_appeal'],x['rating_effort'],x.get('rating_ovr'))
        ax=rt[:4]; ph= all(v<=5 for v in ax) or ax==(50,50,50,50)
    d=docs.get(n,[]); c=has_contract(d)
    plan=bool(PLAN.search(b)); acc=bool(ACC.search(b))
    labels=[l['name'] for l in i['labels']]
    miss=[]
    if not r: miss.append('row')
    if not d: miss.append('doc')
    elif not c: miss.append('contract')
    if not plan: miss.append('plan-in-issue')
    if not rated: miss.append('rating')
    elif ph: miss.append('placeholder-rating')
    if prref.get(n): miss.append('open-PR#'+','.join(map(str,prref[n])))
    if jogst.get(n) in ('failed','parked','running','pending'): miss.append('jog:'+jogst[n])
    design = bool(re.search(r'(?i)records design only|does not authorize implementation',b))
    if design: miss.append('design-only')
    out.append(dict(n=n,title=i['title'][:80],miss=miss,rating=rt,docs=d,blen=len(b),labels=labels,acc=acc))
    core=[m for m in miss if not m.startswith('open-PR') and not m.startswith('jog') and m!='design-only']
    stats['admissible' if not core else 'not']+=1
    if core: dom[core[0]]+=1
    for m in core: stats['miss:'+m]+=1
json.dump(out,open(f'{S}/survey.json','w'),indent=1)
print(dict(stats)); print('first-missing:',dict(dom))
out.sort(key=lambda o:(len([m for m in o['miss']]), -(sum(o['rating'][:4]) if o['rating'] else 0)))
for o in out[:30]: print(o['n'],o['miss'],o['rating'],o['docs'][:1],o['title'])
