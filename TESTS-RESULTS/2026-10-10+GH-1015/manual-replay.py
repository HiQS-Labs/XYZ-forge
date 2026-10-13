"""One-off retained manual replay; not a registered test, runner or gate."""
from pathlib import Path
from contextlib import redirect_stdout
import copy,hashlib,io,json,os,signal,subprocess,sys,tempfile

source=Path(sys.argv[1]).read_text()
payload=source.split("<<'MARATHON_PROGRESS_PY'\n",1)[1].split('\nMARATHON_PROGRESS_PY',1)[0]
namespace={'__name__':'manual_observer_replay'}
exec(compile(payload,'embedded-marathon-observer','exec'),namespace)
rows=[]
with tempfile.TemporaryDirectory(prefix='gh1015-manual-',dir=Path('temp').absolute()) as raw:
    base=Path(raw);physical=base/'physical';physical.mkdir();logical=base/'logical';logical.symlink_to(physical,target_is_directory=True)
    def action(*args):
        old=sys.argv;sys.argv=['observer',*map(str,args)]
        try:
            with redirect_stdout(io.StringIO()):namespace['main']()
        finally:sys.argv=old
    def check(name,product,mutation=None):
        ctx=base/(name+'.context.json');receipt_path=base/(name+'.receipt.json')
        receipt={'schema':'marathon-drive/result@1','execution_id':'owned-execution','phase':'p1','lane':'p1','token':'owned-token-1','target_repo':{'path':os.path.abspath(product)},'outcome':'approved','exit_code':0,'gate':{'result':'green','exit':0},'reviewed_candidate':'a'*40,'reviewed_head':'a'*40,'attest_path':'synthetic-attestation'}
        if mutation:mutation(receipt)
        receipt_path.write_text(json.dumps(receipt))
        action('init',ctx,'--owner',os.getppid(),'--root',base,'--product-root',product,'--harness-root',base,'--plan',base/'plan.yaml','--run-log',base/'run.log','--phases-dir',base/'phases','--heartbeat-file',base/'heartbeat.json','--interval',1,'--count',2,'--total',1)
        action('phase',ctx,'--phase-id','p1','--index',1,'--lane','p1','--token-family','owned-token','--execution-id','owned-execution','--result-file',receipt_path)
        action('finish',ctx,'--exit-code',0)
        context=json.loads(ctx.read_text());out=io.StringIO()
        with redirect_stdout(out):namespace['emit'](context,'manual-snapshot')
        emitted=json.loads(out.getvalue().split('marathon-progress: ',1)[1]);assert emitted
        rows.append({'case':name,'verified_phases':context['verified_phases'],'gate':emitted['gate'],'context_path':context['product_root'],'receipt_path':receipt['target_repo']['path']})
        return ctx
    check('physical',physical);ctx=check('absolute-symlink',logical);check('relative-symlink',os.path.relpath(logical))
    for key,value in [('execution_id','foreign'),('token','foreign'),('schema','foreign'),('phase','foreign'),('lane','foreign')]:
        check('foreign-'+key,physical,lambda r,k=key,v=value:r.update({k:v}))
    check('foreign-target',physical,lambda r:r.update(target_repo={'path':str(base/'other')}))
    check('non-green',physical,lambda r:r.update(gate={'result':'red','exit':1}))
    check('missing-review',physical,lambda r:r.pop('reviewed_head'))
    context=json.loads(ctx.read_text());context['started_monotonic']=0;Path(ctx).write_text(json.dumps(context))
    clock=namespace['time'].monotonic;old_signals={s:signal.getsignal(s) for s in (signal.SIGINT,signal.SIGTERM)};out=io.StringIO()
    try:
        namespace['time'].monotonic=lambda:2.1
        with redirect_stdout(out):namespace['observe'](ctx)
    finally:
        namespace['time'].monotonic=clock
        for s,v in old_signals.items():signal.signal(s,v)
    lines=[x.split('marathon-progress: ',1)[1] for x in out.getvalue().splitlines()];assert len(lines)==3,lines
    parsed=[json.loads(x) for x in lines];assert [x['kind'] for x in parsed]==['missed-check','check','observation-ended']
    ordering=[list(json.loads(x))==sorted(json.loads(x)) for x in lines]
result={'source_sha256':hashlib.sha256(source.encode()).hexdigest(),'observations':rows,'finite_emissions':parsed,'sorted_json_keys':ordering,'limits':'Synthetic receipts and controlled clock; no provider worker or live product execution.'}
assert rows[0]['verified_phases']==1
assert all(r['verified_phases']==0 for r in rows[3:]),rows
print(json.dumps(result,indent=2))
if '--expect-fixed' in sys.argv:assert all(r['verified_phases']==1 for r in rows[:3]) and all(ordering),result
