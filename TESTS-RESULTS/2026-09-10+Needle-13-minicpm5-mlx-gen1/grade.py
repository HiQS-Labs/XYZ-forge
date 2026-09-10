import json, re, sys, copy
from pathlib import Path

def grade(obj,key):
    assert isinstance(obj,dict) and set(obj)=={'decisions','answers','limitations'}, 'top-level schema'
    rows=obj['decisions']; assert isinstance(rows,list) and rows, 'empty decisions'
    assert len(rows)==len(key), 'decision count'
    ids=[r['id'] for r in rows]; assert len(set(ids))==len(ids) and set(ids)==set(key), 'case identity'
    for r in rows:
        assert set(r)=={'id','decision','reason'}, 'decision schema'
        assert r['decision'] in {'ACCEPT','HOLD'} and isinstance(r['reason'],str) and r['reason'].strip(), 'decision vocabulary/reason'
    answers=obj['answers']; assert isinstance(answers,list) and len(answers)==6, 'answer count'
    assert {a['question'] for a in answers}=={'Q'+str(n) for n in range(1,7)}, 'question identity'
    for a in answers:
        assert set(a)=={'question','answer','evidence'} and isinstance(a['answer'],str) and a['answer'].strip(), 'answer schema'
        assert isinstance(a['evidence'],list) and a['evidence'] and all(isinstance(e,str) and e for e in a['evidence']), 'evidence schema'
    assert isinstance(obj['limitations'],list) and obj['limitations'], 'limitations'
    mismatches=[{'id':r['id'],'expected':key[r['id']],'actual':r['decision']} for r in rows if r['decision']!=key[r['id']]]
    return {'n':len(rows),'correct':len(rows)-len(mismatches),'false_accept':sum(x['actual']=='ACCEPT' for x in mismatches),'false_hold':sum(x['actual']=='HOLD' for x in mismatches),'mismatches':mismatches,'pass':not mismatches}

if __name__=='__main__':
 key=json.loads(Path(sys.argv[1]).read_text())
 if sys.argv[2]=='--controls':
    good={'decisions':[{'id':i,'decision':v,'reason':'fixture'} for i,v in key.items()],'answers':[{'question':'Q'+str(i),'answer':'fixture','evidence':['fixture:1']} for i in range(1,7)],'limitations':['fixture']}
    assert grade(good,key)['pass']; controls=[]
    for name in ['empty','duplicate','missing','flipped']:
        bad=copy.deepcopy(good)
        if name=='empty': bad['decisions']=[]
        if name=='duplicate': bad['decisions'][-1]=bad['decisions'][0]
        if name=='missing': bad['decisions'].pop()
        if name=='flipped': bad['decisions'][0]['decision']='ACCEPT' if bad['decisions'][0]['decision']=='HOLD' else 'HOLD'
        try: rejected=not grade(bad,key)['pass']
        except (AssertionError,KeyError,TypeError): rejected=True
        assert rejected,name
        controls.append({'control':name,'rejected':rejected})
    print(json.dumps({'positive_control':True,'negative_controls':controls},indent=2))
 else:
    text=Path(sys.argv[2]).read_text(); objects=[]
    for chunk in re.findall(r'```json\s*\n(.*?)\n```',text,re.S):
        try:
            obj=json.loads(chunk)
            if isinstance(obj,dict) and 'decisions' in obj: objects.append(obj)
        except ValueError: pass
    # Codex CLI emits final text on both logged streams. Collapse only byte-equivalent semantic objects.
    raw_count=len(objects)
    unique={json.dumps(o,sort_keys=True):o for o in objects}
    assert len(unique)==1, f'Expected one distinct final JSON answer; got {len(unique)} from {raw_count} blocks'
    objects=list(unique.values())
    report=grade(objects[0],key)
    report['transport_json_copies']=raw_count
    out=Path(sys.argv[3]); out.write_text(json.dumps(objects[0],indent=2)+'\n')
    print(json.dumps(report,indent=2))
