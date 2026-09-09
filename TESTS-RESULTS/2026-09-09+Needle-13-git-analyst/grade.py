#!/usr/bin/env python3
"""Phase2 structural/verdict checker. Semantic scoring requires independent review."""
import json,re,sys,copy
from pathlib import Path

def extract(text):
    blocks=re.findall(r'```json\s*\n(.*?)\n```',text,re.S)
    if not blocks: blocks=[text.strip()]
    objs=[json.loads(x) for x in blocks]
    assert len(objs)==1,'exactly one JSON answer'
    return objs[0]

def grade(obj,key):
    assert isinstance(obj,dict) and set(obj)=={'assessments','limitations'},'top-level schema'
    rows=obj['assessments'];assert isinstance(rows,list) and len(rows)==len(key)>0,'nonempty case count'
    assert len({r['id']for r in rows})==len(rows) and {r['id']for r in rows}==set(key),'case identity'
    assert isinstance(obj['limitations'],list) and obj['limitations'] and all(isinstance(s,str) and s.strip()for s in obj['limitations']),'limitations'
    result=[]
    for r in rows:
        assert set(r)=={'id','verdict','analysis','next_step','evidence'},'assessment schema'
        assert r['verdict'] in {'SUPPORTED','CONTRADICTED','UNKNOWN'},'verdict vocabulary'
        assert all(isinstance(r[k],str) and r[k].strip()for k in ['analysis','next_step']),'nonempty analysis'
        assert isinstance(r['evidence'],list) and r['evidence'] and all(isinstance(s,str)for s in r['evidence']),'evidence shape'
        k=key[r['id']]; correct=r['verdict']==k['verdict'];valid=set(r['evidence'])<=set(k['valid_evidence_ids'])
        result.append({'id':r['id'],'correct':correct,'expected':k['verdict'],'actual':r['verdict'],'valid_evidence_ids':valid,'critical_false_support':k['critical'] and r['verdict']=='SUPPORTED' and not correct})
    return {'n':len(rows),'correct':sum(r['correct']for r in result),'valid_evidence_id_cases':sum(r['valid_evidence_ids']for r in result),'critical_false_support':sum(r['critical_false_support']for r in result),'rows':result,'semantic_review_required':True}

if __name__=='__main__':
    key=json.loads(Path(sys.argv[1]).read_text())
    if sys.argv[2]=='--controls':
        good={'assessments':[{'id':i,'verdict':k['verdict'],'analysis':'fixture','next_step':'verify','evidence':[k['valid_evidence_ids'][0]]}for i,k in key.items()],'limitations':['fixture']}
        assert grade(good,key)['correct']==len(key)
        results={}
        for name in ['empty','duplicate','missing','flipped','invented_citation','critical_false_support']:
            bad=copy.deepcopy(good)
            if name=='empty':bad['assessments']=[]
            elif name=='duplicate':bad['assessments'][-1]=bad['assessments'][0]
            elif name=='missing':bad['assessments'].pop()
            elif name=='flipped':bad['assessments'][0]['verdict']='UNKNOWN'
            elif name=='invented_citation':bad['assessments'][0]['evidence']=['FAKE-E1']
            else:next(r for r in bad['assessments']if r['id']=='G03')['verdict']='SUPPORTED'
            try:
                g=grade(bad,key);rejected=g['correct']<len(key) or g['valid_evidence_id_cases']<len(key) or g['critical_false_support']>0
            except AssertionError:rejected=True
            assert rejected,name;results[name]=rejected
        print(json.dumps({'positive':True,'negative_controls':results},indent=2))
    else:
        obj=extract(Path(sys.argv[2]).read_text());g=grade(obj,key)
        if len(sys.argv)>3:Path(sys.argv[3]).write_text(json.dumps(obj,indent=2)+'\n')
        print(json.dumps(g,indent=2))
