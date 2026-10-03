import pathlib,subprocess,os,time,json,shutil
base=pathlib.Path('/private/tmp/xyz-ci-stabilization-20260930/completion-handoff-probe')
if not base.exists(): subprocess.run(['git','clone','--branch','development','--single-branch','https://github.com/HiQS-Labs/XYZ-forge.git',str(base)],check=True)
work=base/'temp/completion-handoff';work.mkdir(parents=True,exist_ok=True)
s=(base/'utils/telemetry/append-xyz-completion.sh').read_text()
s=s.replace('holder="$(cat "$lockdir/pid" 2>/dev/null || true)"','holder="$(cat "$lockdir/pid" 2>/dev/null || true)"\n  if [[ "${ROLE:-}" == W && -n "$holder" && ! -e "$BARRIER/W-seen" ]]; then touch "$BARRIER/W-seen"; while [[ ! -e "$BARRIER/W-go" ]]; do sleep .01; done; fi')
s=s.replace('python3 - "$XYZ_JSON"','if [[ "${ROLE:-}" == A ]]; then touch "$BARRIER/A-held"; while [[ ! -e "$BARRIER/A-go" ]]; do sleep .01; done; fi\npython3 - "$XYZ_JSON"')
s=s.replace('records.insert(0, {',"if os.environ.get('ROLE') == 'B':\n    import pathlib,time\n    b=pathlib.Path(os.environ['BARRIER']); (b/'B-read').touch()\n    while not (b/'B-go').exists(): time.sleep(.01)\nrecords.insert(0, {")
writer=work/'writer.sh';writer.write_text(s)
def wait(name):
 deadline=time.monotonic()+15
 while not (work/name).exists():
  assert time.monotonic()<deadline,name
  time.sleep(.01)
def start(role):
 env=os.environ.copy();env.update(ROLE=role,BARRIER=str(work),XYZ_JSON_PATH=str(work/'records.json'))
 return subprocess.Popen(['bash',str(writer),'relay',role,'green',role,role],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
a=start('A');wait('A-held');w=start('W');wait('W-seen');(work/'A-go').touch();assert a.wait(timeout=15)==0
b=start('B');wait('B-read');owner_before=(work/'records.json.lock/pid').read_text().strip();(work/'W-go').touch();assert w.wait(timeout=15)==0
lock_exists_during_b=(work/'records.json.lock').exists();(work/'B-go').touch();assert b.wait(timeout=15)==0
records=json.loads((work/'records.json').read_text())
result={'writer_rcs':[a.returncode,w.returncode,b.returncode],'live_b_pid':b.pid,'lock_owner_before_w':owner_before,'lock_exists_while_b_paused_after_w':lock_exists_during_b,'records':[r['sessionId'] for r in records],'expected':['A','W','B'],'lost_record':'W','source':'instrumented copy, production unchanged','tested_sha':subprocess.check_output(['git','-C',str(base),'rev-parse','HEAD'],text=True).strip()}
assert result['writer_rcs']==[0,0,0] and len(records)==2 and not lock_exists_during_b,result
(work/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
