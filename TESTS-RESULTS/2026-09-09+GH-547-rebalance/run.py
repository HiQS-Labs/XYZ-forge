from pathlib import Path
import json,time,hashlib,datetime
import numpy as np,torch
from transformers import AutoModel,AutoTokenizer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score,f1_score,confusion_matrix
from collections import Counter
root=Path(__file__).resolve().parent;private=Path.home()/'.cache/xyz-modernbert-rebalance'
rows=json.loads((private/'labeled.json').read_text());assert hashlib.sha256((private/'labeled.json').read_bytes()).hexdigest()=='96c7bd405ca3605958da355b32ad987d452ce6658859e0e07bacfd7c7d54739d'
seen=set();test=[]
for r in rows:
 key=r['text'].strip().lower()
 if key not in seen:seen.add(key);test.append(r)
train=[r for r in json.loads((root.parent/'2026-09-09+GH-547-classifier/corpus.json').read_text()) if r['split']=='train'];y=[r['label'] for r in train];labels=sorted(set(y))
assert train and test;assert not(set(r['text'].lower() for r in train)&seen)
v=TfidfVectorizer(ngram_range=(1,2));x=v.fit_transform([r['text'] for r in train]);base=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,y);pred_base=base.predict(v.transform([r['text'] for r in test]))
path=Path.home()/'.cache/huggingface/hub/models--answerdotai--ModernBERT-base/snapshots/8949b909ec900327062f0ebf497f51aef5e6f0c8';torch.set_num_threads(4);tok=AutoTokenizer.from_pretrained(path,local_files_only=True);model=AutoModel.from_pretrained(path,local_files_only=True,attn_implementation='eager').eval()
assert max(len(tok(r['text'])['input_ids']) for r in train+test)<=model.config.max_position_embeddings
def encode(rs):
 chunks=[]
 for start in range(0,len(rs),8):
  inputs=tok([r['text'] for r in rs[start:start+8]],padding=True,truncation=False,return_tensors='pt')
  with torch.inference_mode():
   h=model(**inputs).last_hidden_state;m=inputs['attention_mask'].unsqueeze(-1);chunks.append(((h*m).sum(1)/m.sum(1)).numpy())
 return np.concatenate(chunks)
head=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(encode(train),y);times=[];preds=[]
for i in range(2):
 t=time.perf_counter();preds.append(head.predict(encode(test)));times.append(time.perf_counter()-t)
assert np.array_equal(*preds)
mask=[i for i,r in enumerate(test) if r['expected']!='out_of_scope'];expected=[test[i]['expected'] for i in mask];present=sorted(set(expected));assert mask
out={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'raw_count':len(rows),'unique_count':len(test),'supported_count':len(mask),'out_of_scope_count':len(test)-len(mask),'support':dict(Counter(expected)),'test_batch_seconds':times,'repeat_identical':True,'models':{},'label_hash':hashlib.sha256((private/'labeled.json').read_bytes()).hexdigest()}
for name,pred in [('tfidf',pred_base),('modernbert',preds[0])]:
 pp=[pred[i] for i in mask]
 out['models'][name]={'correct':sum(a==b for a,b in zip(expected,pp)),'accuracy':accuracy_score(expected,pp),'macro_f1_present_classes':f1_score(expected,pp,labels=present,average='macro',zero_division=0),'confusion_labels':labels,'confusion':confusion_matrix(expected,pp,labels=labels).tolist(),'out_of_scope_forced_labels':dict(Counter(str(pred[i]) for i,r in enumerate(test) if r['expected']=='out_of_scope'))}
private_rows=[dict(r,modernbert=str(preds[0][i]),tfidf=str(pred_base[i])) for i,r in enumerate(test)];(private/'predictions.json').write_text(json.dumps(private_rows,indent=2))
(root/'results.json').write_text(json.dumps(out,indent=2)+'\n');(root/'provenance.jsonl').write_text(json.dumps({'utc':out['utc'],'command':'python run.py','model_revision':path.name,'label_hash':out['label_hash'],'output_sha256':hashlib.sha256((root/'results.json').read_bytes()).hexdigest(),'status':'completed','private_text_published':False})+'\n')
print(json.dumps(out,indent=2))
