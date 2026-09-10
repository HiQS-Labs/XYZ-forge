from pathlib import Path
from collections import Counter
import json,time,hashlib,datetime,platform
import numpy as np,torch,transformers,sklearn
from transformers import AutoModel,AutoTokenizer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score,f1_score,confusion_matrix,recall_score
root=Path(__file__).resolve().parent;p=Path.home()/'.cache/xyz-modernbert-real-v2'
files=['train-labeled.json','validation-labeled.json','holdout-unlabeled.json','holdout-labels.json','taxonomy.md']
manifest=json.loads((root/'input-hashes.json').read_text())
for n in files:assert hashlib.sha256((p/n).read_bytes()).hexdigest()==manifest[n],n
tr=json.loads((p/files[0]).read_text());va=json.loads((p/files[1]).read_text());te=json.loads((p/files[2]).read_text());annotations=json.loads((p/files[3]).read_text());lookup={r['id']:r for r in annotations};assert len(lookup)==len(annotations)==len(te) and set(lookup)=={r['id'] for r in te}
for r in te:r.update({k:v for k,v in lookup[r['id']].items() if k!='id'})
labels=sorted(set(r['label'] for r in tr));assert len(labels)==6
splits=[tr,va,te]
def validate(ss):
 assert all(ss),'empty split'
 seen=set()
 for split in ss:
  texts={r['text'].strip().lower() for r in split};assert len(texts)==len(split),'duplicate within split';assert not seen&texts,'duplicate across splits';seen|=texts
validate(splits);controls={}
for name,ss in [('empty',[tr,va,[]]),('duplicate',[tr,va,te+[tr[0]]])]:
 try:validate(ss)
 except AssertionError as e:controls[name]={'rejected':True,'reason':str(e)}
 else:raise AssertionError(name)
y=[r['label'] for r in tr]
def score(rs,pred):
 truth=[r['label'] for r in rs];present=sorted(set(truth));return {'n':len(rs),'correct':sum(a==b for a,b in zip(truth,pred)),'accuracy':accuracy_score(truth,pred),'macro_f1_all_six':f1_score(truth,pred,labels=labels,average='macro',zero_division=0),'macro_f1_present':f1_score(truth,pred,labels=present,average='macro',zero_division=0),'support':dict(Counter(truth)),'recall':dict(zip(labels,recall_score(truth,pred,labels=labels,average=None,zero_division=0).tolist())),'confusion':confusion_matrix(truth,pred,labels=labels).tolist()}
report={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'labels':labels,'counts':dict(zip(['train','validation','holdout'],map(len,splits))),'created_at_ranges':{name:[min(r['created_at'] for r in rs),max(r['created_at'] for r in rs)] for name,rs in zip(['train','validation','holdout'],splits)},'training_support':dict(Counter(y)),'reviewer_confidence':dict(Counter(r['confidence'] for r in te)),'controls':controls,'models':{},'timings':{},'versions':{'python':platform.python_version(),'torch':torch.__version__,'transformers':transformers.__version__,'sklearn':sklearn.__version__}}
majority=Counter(y).most_common(1)[0][0];report['models']['majority']={name:score(rs,[majority]*len(rs)) for name,rs in [('validation',va),('holdout',te)]}
t=time.perf_counter();v=TfidfVectorizer(ngram_range=(1,2));x=v.fit_transform([r['text'] for r in tr]);base=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,y);bp={name:base.predict(v.transform([r['text'] for r in rs])) for name,rs in [('validation',va),('holdout',te)]};report['timings']['tfidf_fit_and_both_splits_s']=time.perf_counter()-t;report['models']['tfidf']={name:score(rs,bp[name]) for name,rs in [('validation',va),('holdout',te)]}
path=Path.home()/'.cache/huggingface/hub/models--answerdotai--ModernBERT-base/snapshots/8949b909ec900327062f0ebf497f51aef5e6f0c8';torch.set_num_threads(4);tok=AutoTokenizer.from_pretrained(path,local_files_only=True);model=AutoModel.from_pretrained(path,local_files_only=True,attn_implementation='eager').eval()
assert max(len(tok(r['text'])['input_ids']) for rs in splits for r in rs)<=model.config.max_position_embeddings
# Test labels only enter score(), never encode() or fit().
def encode(rs):
 chunks=[]
 for start in range(0,len(rs),8):
  inp=tok([r['text'] for r in rs[start:start+8]],padding=True,truncation=False,return_tensors='pt')
  with torch.inference_mode():h=model(**inp).last_hidden_state;m=inp['attention_mask'].unsqueeze(-1);chunks.append(((h*m).sum(1)/m.sum(1)).numpy())
 return np.concatenate(chunks)
t=time.perf_counter();x=encode(tr);head=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,y);report['timings']['train_encode_and_fit_s']=time.perf_counter()-t
vp=head.predict(encode(va));preds=[]
for i in range(2):
 t=time.perf_counter();xt=encode(te);preds.append(head.predict(xt));report['timings'][f'holdout_pass_{i+1}_s']=time.perf_counter()-t
assert np.array_equal(*preds);report['repeat_identical']=True
report['models']['modernbert']={'validation':score(va,vp),'holdout':score(te,preds[0])}
idx=[i for i,r in enumerate(te) if r['confidence']=='high'];assert idx
for name,pred in [('modernbert',preds[0]),('tfidf',bp['holdout'])]:report['models'][name]['high_confidence_holdout']=score([te[i] for i in idx],[pred[i] for i in idx])
shuf=np.array(y);np.random.default_rng(547).shuffle(shuf);control=LogisticRegression(C=1,max_iter=2000,random_state=547).fit(x,shuf);report['models']['shuffled_labels']={'holdout':score(te,control.predict(xt))}
private=[dict(r,modernbert=str(preds[0][i]),tfidf=str(bp['holdout'][i])) for i,r in enumerate(te)];(p/'predictions.json').write_text(json.dumps(private,indent=2))
(root/'results.json').write_text(json.dumps(report,indent=2)+'\n');(root/'provenance.jsonl').write_text(json.dumps({'utc':report['utc'],'command':'python run.py','model_revision':path.name,'input_hashes':manifest,'results_sha256':hashlib.sha256((root/'results.json').read_bytes()).hexdigest(),'status':'completed','scope':'real-activity supervised work-intent classification','independent_labels':'blinded model sub-agent, not human ground truth'})+'\n')
for name,r in report['models'].items():print(name,{s:(x['correct'],x['n'],round(x['macro_f1_all_six'],3)) for s,x in r.items()})
print('timings',report['timings'])
