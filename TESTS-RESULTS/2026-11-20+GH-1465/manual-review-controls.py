import io, json, pathlib, subprocess, sys, tempfile, threading, time
from unittest.mock import patch
sys.dont_write_bytecode=True
sys.path.insert(0,str(pathlib.Path(sys.argv[1])/'utils/py'))
import proc_group as pg, gate_env, relay_attest as ra

class Fake:
    pid=987654321
    returncode=0
    def __init__(self,poll_value,communicate):
        self.poll_value=poll_value
        self.communicate=communicate
    def poll(self): return self.poll_value

closed=threading.Event()
f=Fake(0,lambda **kw: (closed.wait(.3) and '' or '', ''))
with patch.object(pg.subprocess,'Popen',return_value=f), patch.object(pg,'group_rss_mb',return_value=(100,None)), patch.object(pg,'kill_existing',side_effect=lambda *a,**k:closed.set()):
    leader=pg.run_bounded(['mock-leader-exited'],timeout=1,max_rss_mb=1,rss_poll_s=.05)

started=threading.Event()
done=threading.Event()
def terminate(*a,**k):
    started.set()
    time.sleep(1.2)
    done.set()
def communicate(**kw):
    assert started.wait(1)
    return '', ''
f=Fake(None,communicate)
with patch.object(pg.subprocess,'Popen',return_value=f), patch.object(pg,'group_rss_mb',return_value=(100,None)), patch.object(pg,'kill_existing',side_effect=terminate):
    termination=pg.run_bounded(['mock-termination-in-flight'],timeout=2,max_rss_mb=1,rss_poll_s=.05)
    completed_before_return=done.is_set()
done.wait(2)
record=dict(attested_at='now',task='GH-1465',reviewer='codex',status='Approved',reviewed_head='a'*40,added_start=0,added_len=1,added_sha256='b'*64,gate_cmd='python -m pytest tests/test_verified.py',gate_exit=0,gate_cmd_format='json')
trailer=ra.trailer_text(record).encode()
canon=b''.join(ra._downgrade_uncited(ra._split_lines(trailer)))
normal=pg.run_bounded(['/bin/sh','-c','printf ok'],timeout=2)
result={'leader_exit_still_rss_guarded':leader.rss_killed,'termination_completed_before_return':completed_before_return,'gate_command_canonical_stable':canon==trailer,'nested_gate_environment_scrubbed':'MARATHON_REVIEWER_GATE_CMD' not in gate_env.gate_env({'MARATHON_REVIEWER_GATE_CMD':'bash test/gh505-relay-attest.sh','PATH':'/usr/bin:/bin'}),'normal_no_rss_control':normal.rc==0 and normal.stdout=='ok' and not normal.rss_killed}
expected=sys.argv[2]
if expected=='green':
    with tempfile.TemporaryDirectory(prefix='gh1465-contract-') as tmp:
        d=pathlib.Path(tmp)
        relay=d/'relay.md'
        recfile=d/'record.json'
        raw=b'STATUS: Approved\nNEXT: done\n\n### Reviewer\n[Pass] measured `src.py:1`\n'
        body=ra.canonical_bytes(raw)
        record.update(schema=ra.SCHEMA,relay_file=str(relay),relay_file_rel='relay.md',target_repo=tmp,isolated=True,artifact_sha256=None,transcript_repo=None,added_start=0,added_len=len(body),added_sha256=ra.sha256(body))
        for command in ('python -m pytest tests/test_verified.py','echo ordinary','printf "verified\\n"\ntrue'):
            record['gate_cmd']=command
            trailer=ra.trailer_text(record).encode()
            record['trailer_sha256']=ra.sha256(trailer)
            relay.write_bytes(raw+trailer)
            recfile.write_text(json.dumps(record))
            loaded,why=ra.load('GH-1465',expected_reviewer='codex',relay_file=str(relay),target_repo=tmp,path=str(recfile))
            assert loaded,why
        record['gate_cmd']='echo tampered'
        recfile.write_text(json.dumps(record))
        assert ra.load('GH-1465',expected_reviewer='codex',relay_file=str(relay),target_repo=tmp,path=str(recfile))[0] is None
        # Existing plain command records retain their previous trailer format.
        record.pop('gate_cmd_format')
        record['gate_cmd']='echo ordinary'
        trailer=ra.trailer_text(record).encode()
        record['trailer_sha256']=ra.sha256(trailer)
        relay.write_bytes(raw+trailer)
        recfile.write_text(json.dumps(record))
        assert ra.load('GH-1465',expected_reviewer='codex',relay_file=str(relay),target_repo=tmp,path=str(recfile))[0]
        result['load_roundtrip_and_tamper_and_legacy_controls']=True
        def git(*a): return subprocess.check_output(['git','-C',tmp,*a],text=True).strip()
        git('init','-q')
        git('config','user.name','GH1465 fixture')
        git('config','user.email','fixture@example.invalid')
        (d/'src.txt').write_text('before\n')
        git('add','src.txt','relay.md')
        git('commit','-qm','seed')
        pin=git('rev-parse','HEAD')
        r={'reviewed_head':pin,'relay_file_rel':'relay.md','isolated':True,'artifact_sha256':None}
        relay.write_bytes(relay.read_bytes()+b'\ntranscript update\n')
        git('add','relay.md'); git('commit','-qm','transcript')
        assert ra.source_matches(r,git('rev-parse','HEAD'),tmp)[0]
        assert ra.candidate_ok(r,git('rev-parse','HEAD'),tmp)[0]
        (d/'src.txt').write_text('after\n')
        git('add','src.txt'); git('commit','-qm','source drift')
        assert not ra.source_matches(r,git('rev-parse','HEAD'),tmp)[0]
        assert not ra.candidate_ok(r,git('rev-parse','HEAD'),tmp)[0]
        result['source_drift_refused_transcript_only_allowed']=True
print(json.dumps(result,sort_keys=True))
assert result['normal_no_rss_control']
assert all(result.values()) if expected=='green' else all(not v for k,v in result.items() if k!='normal_no_rss_control')
