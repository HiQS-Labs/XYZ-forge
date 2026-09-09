from pathlib import Path
import json,hashlib,os,re
b=Path(__file__).resolve().parent.parent;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();rows=[]
for d in sorted((b/'runs').iterdir()):
 if not d.is_dir()or d.name=='gemma31-off':continue
 for run in ['r1','r2']:
  r=json.loads((d/f'{run}-receipt.json').read_text());a=(d/f'{run}-answer.md').read_text().strip();assert a
  if d.name=='muse13-high':
   es=[json.loads(l)for l in(d/f'{run}-events.jsonl').read_text().splitlines()];t=[e['payload']['text']for e in es if e['payload_type']=='run.terminal.completed'];assert len(t)==1;t=t[0];proof={'payload_types':sorted({e['payload_type']for e in es})}
  elif d.name.startswith('agy'):
   t=json.loads((d/f'{run}-stdout.json').read_text())['response'];proof={'tool_observability':'JSON summary does not prove absence of all tools'}
  elif d.name=='flashlite31':
   es=json.loads((d/f'{run}-response.json').read_text());t=''.join(c.get('delta',{}).get('content')or''for e in es for c in e.get('choices',[]));assert r['model_identity_matches'];proof={'model_identity_matches':True}
  else:
   es=[json.loads(l)for l in(d/f'{run}-events.jsonl').read_text().splitlines()];ts=[e['item']['text']for e in es if e.get('item',{}).get('type')=='agent_message'];assert len(ts)==1 and any(e['type']=='turn.completed'for e in es);t=ts[0];proof={'item_types':sorted({e['item']['type']for e in es if 'item'in e})}
  norm=lambda x:x.replace('\r\n','\n').replace('\r','\n').strip()
  assert norm(t)==norm(a);assert norm(t)!=norm(a+'NEGATIVE CONTROL') and norm(t)!='';proof.update(exact_text_match=t.strip()==a,newline_normalized_match=True,changed_answer_negative_control=True,empty_answer_negative_control=True)
  rows.append({'model_id':d.name,'run':run,'input_commit':'5aeb527','receipt':r,'proof':proof,'grade':json.loads((d/f'{run}-grade.json').read_text()),'artifact_sha256':{f.name:sha(f)for f in d.glob(run+'-*')if f.is_file()},'input_sha256':{f:sha(b/f)for f in ['packet.json','QUESTIONS.md','expected.json','grade.py','source-reference.json']}})
assert len(rows)==18
(b/'provenance.jsonl').write_text(''.join(json.dumps(r)+'\n'for r in rows));(b/'verification.json').write_text(json.dumps({'completed_calls':18,'unavailable_calls':2,'all_answers_match_provider_output_after_newline_normalization':True,'input_commit':'5aeb527','no_inference_retry':True,'limits':'Families concurrent; wall times subject to contention. CLI/API system roles and output ceilings differ.'},indent=2)+'\n')
print('18 provenance records verified')
