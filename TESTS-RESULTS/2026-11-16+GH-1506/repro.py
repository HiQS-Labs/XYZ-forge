import ast, importlib.util, json, os, pathlib, subprocess, sys, tempfile, time
root=pathlib.Path(sys.argv[1]).resolve()
sys.dont_write_bytecode=True
sys.path.insert(0,str(root/'utils/py'))
import turn_diagnostics as td
source=(root/'utils/py/agy-turn.py').read_text()
node=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='_probe_idle_blocker')
ns={'subprocess':subprocess}
exec(compile(ast.Module(body=[node],type_ignores=[]),'actual-probe','exec'),ns)
results=[]
for trial in range(2):
 with tempfile.TemporaryDirectory(prefix='forge-diag-control-') as tmp:
  p=pathlib.Path(tmp); log=p/'empty.log';log.write_text('')
  worker=subprocess.Popen([sys.executable,'-c',"import sys,time; f=open(sys.argv[1],'w'); print('READY',flush=True); time.sleep(30)",str(p/'innocent.lock')],stdout=subprocess.PIPE,text=True,start_new_session=True)
  try:
   assert worker.stdout.readline().strip()=='READY'
   lock=ns['_probe_idle_blocker'](worker,str(log))
   assert lock[0]=='lock',lock
   assert 'does not establish' in lock[1] and 'it was waiting' not in lock[1]
  finally:
   worker.terminate();worker.wait(timeout=5)
  # No fcntl/flock calls or competing owner exist in this controlled worker.
  tree=p/'tree';tree.mkdir();(tree/'source.txt').write_text('unchanged')
  baseline=td._newest_mtime(str(tree))
  d=td.TurnDiagnostics(worktree=str(tree));d.samples=[(0.,0.,1),(1.,0.,1)];d.mtime_start=baseline;d.mtime_last=baseline
  clean=d.classify()
  (tree/'temp').mkdir();onlylog=tree/'temp/transport.log';onlylog.write_text('harness log only')
  os.utime(onlylog,(baseline+2,baseline+2))
  d.mtime_last=td._newest_mtime(str(tree)); contaminated=d.classify()
  assert clean[0]!=td.REASON_SLOW_PROGRESS
  assert contaminated[0]==td.REASON_SLOW_PROGRESS
  assert 'not established' in contaminated[1] and 'legacy category' in contaminated[1]
  assert 'file-activity=yes' in contaminated[1]
  assert (tree/'source.txt').read_text()=='unchanged'
  git=p/'git';git.mkdir();subprocess.run(['git','init','-q',str(git)],check=True)
  (git/'request-a.md').write_text('scaffold');(git/'request-b.md').write_text('scaffold')
  counts=[len(subprocess.check_output(['git','-C',str(git),'status','--porcelain'],text=True).splitlines()) for _ in range(2)]
  assert counts==[2,2]
  results.append({'trial':trial+1,'benign_open_file_probe':lock,'no_log_control':clean,'log_only_classification':contaminated,'unchanged_dirty_tree_counts':counts})
print(json.dumps({'scope':'component reproduction: exact AST-extracted probe, imported classifier with controlled CPU samples, real git status; NOT full agy-turn CLI','source_head':subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),'results':results},indent=2))
