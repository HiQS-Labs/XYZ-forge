from pathlib import Path
import json,time,hashlib,platform,datetime
import torch,transformers
from transformers import AutoTokenizer,AutoModelForMaskedLM
root=Path(__file__).resolve().parent
model_path=Path.home()/'.cache/huggingface/hub/models--answerdotai--ModernBERT-base/snapshots/8949b909ec900327062f0ebf497f51aef5e6f0c8'
out={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'python':platform.python_version(),'torch':torch.__version__,'transformers':transformers.__version__,'device':'cpu','mps_available':torch.backends.mps.is_available(),'model_revision':model_path.name,'input_hashes':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in ['QUESTIONS.md','packet.json']},'runs':[]}
t=time.perf_counter()
tok=AutoTokenizer.from_pretrained(model_path,local_files_only=True)
model=AutoModelForMaskedLM.from_pretrained(model_path,local_files_only=True,attn_implementation='eager').eval()
out.update(load_seconds=time.perf_counter()-t,architecture=type(model).__name__,can_generate=model.can_generate(),max_positions=model.config.max_position_embeddings)
packet=(root/'QUESTIONS.md').read_text()+'\n'+(root/'packet.json').read_text()
out['shared_input_tokens']=len(tok(packet,truncation=False)['input_ids'])
out['comparison']={'grade':'N/A','reason':'Masked-language checkpoint has no trained analyst verdict/evidence/analysis output head. No generative benchmark responses attempted; smoke outputs are not analyst answers.'}
torch.set_num_threads(4)
for i in range(2):
 text='The capital of France is '+tok.mask_token+'.'
 inputs=tok(text,return_tensors='pt');positions=(inputs['input_ids'][0]==tok.mask_token_id).nonzero().flatten();assert positions.numel()==1
 t=time.perf_counter()
 with torch.inference_mode(): logits=model(**inputs).logits[0,positions.item()]
 values,indices=logits.softmax(-1).topk(5)
 out['runs'].append({'run':i+1,'task':'masked-token smoke, not shared analyst benchmark','input':text,'seconds':time.perf_counter()-t,'top5':[{'token':tok.decode([j]),'probability':v} for v,j in zip(values.tolist(),indices.tolist())]})
(root/'results.json').write_text(json.dumps(out,indent=2)+'\n')
(root/'provenance.jsonl').write_text(json.dumps({'utc':out['utc'],'command':'python probe.py','model_revision':out['model_revision'],'input_hashes':out['input_hashes'],'result_sha256':hashlib.sha256((root/'results.json').read_bytes()).hexdigest(),'status':'completed','scope':'runtime smoke and benchmark compatibility only'})+'\n')
print(json.dumps(out,indent=2))
