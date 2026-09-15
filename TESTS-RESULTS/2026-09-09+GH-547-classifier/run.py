from pathlib import Path
import json,hashlib,time,datetime,platform,copy
import numpy as np
import torch,transformers,sklearn
from transformers import AutoTokenizer,AutoModel
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score,f1_score,recall_score,confusion_matrix
root=Path(__file__).resolve().parent
rows=json.loads((root/'corpus.json').read_text())
def validate(rs):
 train=[r for r in rs if r['split']=='train'];test=[r for r in rs if r['split']=='test']
 assert train and test,'empty split'
 assert len({r['label'] for r in train})==6,'missing training class'
 assert len({r['id'] for r in rs})==len(rs),'duplicate ID'
 assert not ({r['text'].strip().lower() for r in train}&{r['text'].strip().lower() for r in test}),'cross-split duplicate'
 return train,test
tr,te=validate(rows);controls={}
mutations={'empty_test':[r for r in rows if r['split']=='train'],'missing_class':[r for r in rows if not(r['split']=='train' and r['label']=='merged')]}
dup=copy.deepcopy(rows);next(r for r in dup if r['split']=='test')['text']=tr[0]['text'];mutations['duplicate']=dup
for k,v in mutations.items():
 try:validate(v)
 except AssertionError as e:controls[k]={'rejected':True,'reason':str(e)}
 else:raise AssertionError('control passed unexpectedly: '+k)
y=[r['label'] for r in tr];yt=[r['label'] for r in te];labels=sorted(set(y))
def score(pred):return {'accuracy':accuracy_score(yt,pred),'macro_f1':f1_score(yt,pred,average='macro',zero_division=0),'recall':dict(zip(labels,recall_score(yt,pred,labels=labels,average=None,zero_division=0).tolist())),'confusion_matrix':confusion_matrix(yt,pred,labels=labels).tolist(),'predictions':[{'id':r['id'],'expected':r['label'],'predicted':str(p)} for r,p in zip(te,pred)]}
results={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'versions':{'python':platform.python_version(),'torch':torch.__version__,'transformers':transformers.__version__,'sklearn':sklearn.__version__},'counts':{'train':len(tr),'test':len(te)},'labels':labels,'controls':controls,'models':{},'timings':{},'device':'cpu'}
results['models']['majority']=score([labels[0]]*len(te))
t=time.perf_counter();v=TfidfVectorizer(ngram_range=(1,2));x=v.fit_transform([r['text'] for r in tr]);xt=v.transform([r['text'] for r in te]);base=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,y);results['models']['tfidf']=score(base.predict(xt));results['timings']['tfidf_fit_and_predict_s']=time.perf_counter()-t
path=Path.home()/'.cache/huggingface/hub/models--answerdotai--ModernBERT-base/snapshots/8949b909ec900327062f0ebf497f51aef5e6f0c8'
torch.set_num_threads(4);t=time.perf_counter();tok=AutoTokenizer.from_pretrained(path,local_files_only=True);model=AutoModel.from_pretrained(path,local_files_only=True,attn_implementation='eager').eval();results['timings']['load_s']=time.perf_counter()-t
assert max(len(tok(r['text'])['input_ids']) for r in rows)<=model.config.max_position_embeddings
def encode(rs):
 parts=[]
 for start in range(0,len(rs),8):
  inp=tok([r['text'] for r in rs[start:start+8]],padding=True,return_tensors='pt',truncation=False)
  with torch.inference_mode():
   hidden=model(**inp).last_hidden_state;mask=inp['attention_mask'].unsqueeze(-1);pooled=(hidden*mask).sum(1)/mask.sum(1)
  parts.append(pooled.numpy())
 return np.concatenate(parts)
t=time.perf_counter();x=encode(tr);results['timings']['train_encoding_s']=time.perf_counter()-t
t=time.perf_counter();head=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,y);results['timings']['linear_fit_s']=time.perf_counter()-t
predictions=[]
for i in range(2):
 t=time.perf_counter();xt=encode(te);pred=head.predict(xt);results['timings'][f'test_pass_{i+1}_24_messages_s']=time.perf_counter()-t;predictions.append(pred)
assert np.array_equal(*predictions),'repeat predictions differ'
results['repeat_predictions_identical']=True;results['models']['modernbert_frozen']=score(predictions[0])
shuffled=np.array(y);np.random.default_rng(547).shuffle(shuffled);bad=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,shuffled);results['models']['shuffled_label_control']=score(bad.predict(xt))
s=results['models']['modernbert_frozen'];results['screen_pass']=s['accuracy']>=.8 and s['macro_f1']>=.8 and min(s['recall'].values())>=.5
results['input_hashes']={n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in ['corpus.json','PROTOCOL.md','run.py']}
(root/'results.json').write_text(json.dumps(results,indent=2)+'\n')
with (root/'provenance.jsonl').open('w') as f:f.write(json.dumps({'utc':results['utc'],'command':'python run.py','model_revision':path.name,'input_hashes':results['input_hashes'],'output_sha256':hashlib.sha256((root/'results.json').read_bytes()).hexdigest(),'scope':'synthetic supervised activity classification screen','status':'completed'})+'\n')
print(json.dumps({k:v for k,v in results.items() if k!='models'},indent=2))
for k,v in results['models'].items():print(k,v['accuracy'],v['macro_f1'],v['recall'])
