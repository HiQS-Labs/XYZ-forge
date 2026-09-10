from pathlib import Path
from collections import Counter
import json,time,hashlib,datetime,copy,platform
import numpy as np,torch,transformers,sklearn,joblib
from transformers import AutoModel,AutoTokenizer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score,f1_score,confusion_matrix,precision_recall_fscore_support
root=Path(__file__).resolve().parent;p=Path.home()/'.cache/xyz-modernbert-calibrated'
manifest=json.loads((root/'input-hashes.json').read_text())
for name,h in manifest.items():assert hashlib.sha256((p/name).read_bytes()).hexdigest()==h,name
rows=json.loads((p/'sample.json').read_text());labels=sum([json.loads((p/n).read_text()) for n in ['labels-1.json','labels-2.json','labels-extra.json','holdout-labels.json']],[])
purposes=['bug_fix','feature_enhancement','research_evaluation','planning_design','documentation','maintenance','testing_validation','merge_closeout']
def validate(rs,ls):
 assert rs and ls,'empty data';lookup={r['id']:r for r in ls};assert len(lookup)==len(ls) and set(lookup)=={r['id'] for r in rs},'label IDs'
 seen=set()
 for split in ['train','validation','holdout']:
  batch=[r for r in rs if r['split']==split];assert batch,'empty split'
  texts={r['title'].lower().strip() for r in batch};assert len(texts)==len(batch) and not seen&texts,'duplicate text';seen|=texts
 for r in ls:assert r['purpose_primary'] in purposes+[None],'invalid purpose'
 return lookup
lookup=validate(rows,labels);controls={}
for name,rr,ll in [('empty',[],labels),('missing_label',rows,labels[:-1])]:
 try:validate(rr,ll)
 except AssertionError as e:controls[name]={'rejected':True,'reason':str(e)}
 else:raise AssertionError(name)
bad=copy.deepcopy(rows);next(r for r in bad if r['split']=='holdout')['title']=next(r for r in bad if r['split']=='train')['title']
bl=copy.deepcopy(labels);bl[0]['purpose_primary']='invalid'
for name,rr,ll in [('duplicate',bad,labels),('invalid_purpose',rows,bl)]:
 try:validate(rr,ll)
 except AssertionError as e:controls[name]={'rejected':True,'reason':str(e)}
 else:raise AssertionError(name)
for r in rows:r.update(lookup[r['id']])
splits={s:[r for r in rows if r['split']==s] for s in ['train','validation','holdout']}
def texts(rs):return ['Project: '+r['repo']+'\nTitle: '+r['title']+'\nDescription: '+r['description'] for r in rs]
report={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'counts':{s:len(rs) for s,rs in splits.items()},'description_truncated':{s:sum(r['description_truncated'] for r in rs) for s,rs in splits.items()},'controls':controls,'versions':{'python':platform.python_version(),'torch':torch.__version__,'transformers':transformers.__version__,'sklearn':sklearn.__version__},'axes':{},'timings':{}}
for axis in ['purpose','area']:
 report['axes'][axis]={'support':{s:dict(Counter(r[axis+'_primary'] or 'uncertain' for r in rs)) for s,rs in splits.items()},'models':{}}
t=time.perf_counter();vectorizer=TfidfVectorizer(ngram_range=(1,2));features={'tfidf':{}};features['tfidf']['train']=vectorizer.fit_transform(texts(splits['train']))
for s in ['validation','holdout']:features['tfidf'][s]=vectorizer.transform(texts(splits[s]))
report['timings']['tfidf_features_s']=time.perf_counter()-t
path=Path.home()/'.cache/huggingface/hub/models--answerdotai--ModernBERT-base/snapshots/8949b909ec900327062f0ebf497f51aef5e6f0c8';torch.set_num_threads(4);t=time.perf_counter();tok=AutoTokenizer.from_pretrained(path,local_files_only=True);model=AutoModel.from_pretrained(path,local_files_only=True,attn_implementation='eager').eval();report['timings']['model_load_s']=time.perf_counter()-t
report['max_tokens']=max(len(tok(t)['input_ids']) for rs in splits.values() for t in texts(rs));assert report['max_tokens']<=model.config.max_position_embeddings
features['modernbert']={}
for s,rs in splits.items():
 t=time.perf_counter();parts=[]
 for start in range(0,len(rs),4):
  inp=tok(texts(rs[start:start+4]),padding=True,truncation=False,return_tensors='pt')
  with torch.inference_mode():h=model(**inp).last_hidden_state;m=inp['attention_mask'].unsqueeze(-1);parts.append(((h*m).sum(1)/m.sum(1)).numpy())
 features['modernbert'][s]=normalize(np.concatenate(parts));report['timings']['modernbert_'+s+'_encoding_s']=time.perf_counter()-t
private=[];saved={'vectorizer':vectorizer,'heads':{}}
def metrics(rs,axis,pred,proba,threshold,classes):
 truth=[r[axis+'_primary'] for r in rs];known=[i for i,y in enumerate(truth) if y is not None];accepted=[i for i,v in enumerate(proba) if v>=threshold];yt=[truth[i] for i in known];yp=[str(pred[i]) for i in known];universe=sorted(set(classes)|set(yt))
 return {'labeled_n':len(known),'uncertain_truth_n':len(rs)-len(known),'correct':sum(a==b for a,b in zip(yt,yp)),'raw_accuracy':accuracy_score(yt,yp) if known else None,'macro_f1':f1_score(yt,yp,labels=universe,average='macro',zero_division=0) if known else None,'confusion_labels':universe,'confusion':confusion_matrix(yt,yp,labels=universe).tolist(),'threshold':threshold if threshold<=1 else 'reject_all','accepted_n':len(accepted),'coverage':len(accepted)/len(rs),'accepted_accuracy':sum(truth[i]==pred[i] and truth[i] is not None for i in accepted)/len(accepted) if accepted else None,'unknown_false_accepts':sum(truth[i] is None for i in accepted),'correct_labeled_retained':sum(truth[i]==pred[i] and truth[i] is not None for i in accepted)}
for axis in ['purpose','area']:
 field=axis+'_primary';tr=splits['train'];va=splits['validation'];te=splits['holdout'];ti=[i for i,r in enumerate(tr) if r[field] is not None];vi=[i for i,r in enumerate(va) if r[field] is not None];y=[tr[i][field] for i in ti];yv=[va[i][field] for i in vi];classes=sorted(set(y));assert len(classes)>1 and vi
 majority=Counter(y).most_common(1)[0][0];report['axes'][axis]['majority']=metrics(te,axis,[majority]*len(te),[1]*len(te),0,classes)
 for method,fs in features.items():
  t=time.perf_counter();best=None;grid=[]
  for C in [.1,1,10,100]:
   for weight in [None,'balanced']:
    head=LogisticRegression(C=C,class_weight=weight,max_iter=2000,random_state=547).fit(fs['train'][ti],y);pred=head.predict(fs['validation'][vi]);score=f1_score(yv,pred,labels=classes,average='macro',zero_division=0);grid.append({'C':C,'weight':weight,'validation_macro_f1':score})
    if best is None or score>best[0]:best=(score,head,C,weight)
  score,head,C,weight=best;vp=head.predict(fs['validation']);vc=head.predict_proba(fs['validation']).max(1);threshold=2.
  for t0 in np.arange(0,1,.05):
   ids=[i for i,x in enumerate(vc) if x>=t0]
   if len(ids)>=5 and sum(va[i][field] is not None and va[i][field]==vp[i] for i in ids)/len(ids)>=.8:threshold=float(t0);break
  pred=head.predict(fs['holdout']);conf=head.predict_proba(fs['holdout']).max(1);repeat=[]
  for z in range(2):
   st=time.perf_counter();q=head.predict(fs['holdout']);repeat.append(time.perf_counter()-st);assert np.array_equal(pred,q)
  result={'selected_C':C,'class_weight':weight,'grid':grid,'validation':metrics(va,axis,vp,vc,threshold,classes),'holdout':metrics(te,axis,pred,conf,threshold,classes),'head_repeat_seconds':repeat,'repeat_identical':True}
  secfield=axis+'_secondary';secondary=sorted({a for i in ti for a in tr[i][secfield]});fitted=[];unsupported=[];sp=np.zeros((len(te),len(secondary)),dtype=int);st=np.zeros_like(sp)
  for j,label in enumerate(secondary):
   sy=np.array([int(label in tr[i][secfield]) for i in ti]);st[:,j]=[int(label in r[secfield]) for r in te]
   if sy.sum()<3 or len(sy)-sy.sum()<3:unsupported.append(label);continue
   sec=LogisticRegression(C=C,class_weight=weight,max_iter=2000,random_state=547).fit(fs['train'][ti],sy);sp[:,j]=(sec.predict_proba(fs['holdout'])[:,1]>=.5);fitted.append(label)
  ki=[i for i,r in enumerate(te) if r[field] is not None];prec,rec,f1,_=precision_recall_fscore_support(st[ki],sp[ki],average='micro',zero_division=0) if secondary else (0,0,0,None)
  unseen=sorted({a for r in te for a in r[secfield]}-set(secondary));result['secondary']={'trained_labels':fitted,'unsupported_training_labels':unsupported,'unseen_holdout_labels':unseen,'micro_precision':prec,'micro_recall':rec,'micro_f1':f1,'known_axis_rows':len(ki),'positive_truth_entries_scored':int(st[ki].sum()),'note':'No qualification when truth has no positives; unseen labels excluded from matrix and listed explicitly.'}
  report['axes'][axis]['models'][method]=result;report['timings'][method+'_'+axis+'_search_and_evaluation_s']=time.perf_counter()-t;saved['heads'][method+'_'+axis]={'head':head,'threshold':threshold}
  private.extend({'id':r['id'],'axis':axis,'model':method,'expected':r[field],'predicted':str(pred[i]),'accepted':bool(conf[i]>=threshold)} for i,r in enumerate(te))
joblib.dump(saved,p/'fitted-heads.joblib');(p/'predictions.json').write_text(json.dumps(private,indent=2));(root/'results.json').write_text(json.dumps(report,indent=2)+'\n');(root/'provenance.jsonl').write_text(json.dumps({'utc':report['utc'],'command':'python run.py','model_revision':path.name,'input_hashes':manifest,'result_sha256':hashlib.sha256((root/'results.json').read_bytes()).hexdigest(),'status':'completed','private_data_exported':False})+'\n')
for axis,r in report['axes'].items():
 for method,x in r['models'].items():print(axis,method,x['holdout'])
