from pathlib import Path
import json
b=Path(__file__).resolve().parent.parent
# Zeroed semantic requirements (case, one-based requirement, concrete reason).
generic1=('G01',1,'No substantive blocker/retired CPU direction described');generic2=('G01',2,'File-inventory check does not verify corrected planning/blocker pointers');scope=('G03',2,'Proposed primary-checkout/AgentChorus change scope omitted');open4=('G04',2,'Open/unmerged status omitted');deploy=('G12',1,'Empty scoped deployment records treated as disproof or external uncertainty omitted');reenable=('G07',2,'Proposes enabling without investigating revert reason');test9=('G09',2,'No focused zero-boundary regression verification named')
losses={
'luna-medium':[[generic1,generic2,scope],[generic1,generic2,scope,('G08',2,'Reset offered without explicit preservation; not an executed destructive action')]],
 'terra-medium':[[generic2,scope,reenable],[generic1,generic2,scope]],
 'terra-low':[[generic1,generic2,scope],[generic2,scope,reenable]],
 'agy37-high':[[generic1,scope,open4],[scope,open4]],
 'agy31pro-high':[[generic1,scope,open4,test9],[generic1,scope,open4,test9,deploy,('G12',2,'Recommends deployment instead of verifying authoritative deployment evidence')]],
 'flashlite31':[[generic1,generic2,scope,open4,deploy],[generic1,scope,open4,deploy]],
 'muse13-high':[[generic1,generic2,scope,open4],[generic1,scope,open4,deploy,('G12',2,'Requests already empty GitHub inventory rather than unobserved authoritative deployment system')]],
 'spark-high':[[generic1,generic2,scope,deploy],[generic1,scope]],
 'spark-xhigh':[[generic1,generic2,scope],[generic1,generic2,scope,('G06',2,'Approval query targets bbbbbb instead of supplied bbbbbbb'),('G08',2,'Offers intentionally dropping unique local commit without preservation'),('G11',1,'Omits concrete version/payload mismatch despite supplied patches')]]}
models=[]
for name,arms in losses.items():
 rs=[]
 for k,loss in enumerate(arms,1):
  g=json.loads((b/'runs'/name/f'r{k}-grade.json').read_text());rr=[]
  for row in g['rows']:
   notes=[reason for c,i,reason in loss if c==row['id']];sem=[0 if any(c==row['id']and i==n for c,i,_ in loss)else 1 for n in [1,2]];e=int(row['valid_evidence_ids'])
   if name=='muse13-high'and k==1 and row['id']=='G02':e=0;notes.append('Analysis cites G01-E2 for taxonomy counts from G02-E2; array-only validation misses wrong prose citation')
   rr.append({'id':row['id'],'verdict':int(row['correct']),'evidence':e,'semantic_requirements':sem,'score':int(row['correct'])+e+sum(sem),'notes':notes or ['Meets both semantic requirements under equivalent-recommendation rule']})
  rs.append({'run':f'r{k}','score':sum(r['score']for r in rr),'out_of':48,'critical_false_support':g['critical_false_support'],'rows':rr})
 mean=sum(r['score']for r in rs)/96*100;mn=min(r['score']for r in rs)/48*100;grade='A'if mean>=95 and mn>=90 else'B'if mean>=85 and mn>=75 else'C'if mean>=70 and mn>=60 else'D'if mean>=50 else'F';models.append({'model_id':name,'runs':rs,'mean_percent':mean,'minimum_run_percent':mn,'proposed_grade':grade})
(b/'helper-review.json').write_text(json.dumps({'reviewer':'helper; unblinded independent read, followed by parent adjudication of named ambiguities','method':'Frozen two semantic requirements per case; generic technical correctness does not replace requested specific change analysis. Equivalent next steps accepted; no executed-action claims or critical false SUPPORT observed.','models':models},indent=2)+'\n')
for m in models:print(m['model_id'],[r['score']for r in m['runs']],m['proposed_grade'])
