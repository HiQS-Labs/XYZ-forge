import sys,subprocess,tempfile,pathlib,os,json,time
writer=sys.argv[1];n=int(sys.argv[2]);delay=float(sys.argv[3]);d=pathlib.Path(tempfile.mkdtemp(prefix='ate-records-'));target=d/'records.json'
ps=[]
for i in range(n):
 ps.append(subprocess.Popen(['bash',writer,'relay',str(i),'green','T','D'],env={**os.environ,'XYZ_JSON_PATH':str(target)},stdout=subprocess.DEVNULL,stderr=subprocess.PIPE))
 if delay: time.sleep(delay)
rcs=[p.wait(timeout=40) for p in ps];records=json.loads(target.read_text());ids={r['sessionId'] for r in records}
assert all(rc==0 for rc in rcs) and len(records)==n and ids=={str(i) for i in range(n)},(rcs,len(records),ids)
print(json.dumps({'writers':n,'delay':delay,'records':len(records),'zero_exits':True,'distinct':len(ids)}))
