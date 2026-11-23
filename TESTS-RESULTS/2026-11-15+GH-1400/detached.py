import json,pathlib,sys
sys.argv=[sys.argv[0],'--out',str(pathlib.Path.cwd()/'temp/gh1400-manual/detached-before')]
s=pathlib.Path('temp/gh1400-manual/check.py').read_text();exec(s[:s.index("required=['adoption")])
r,t,g,receipt=setup('detached');j.jog_set_status(str(r),901,'parked',failure_reason='controlled hold');git(t,'switch','--detach');(t/'unique.txt').write_text('unique detached work');git(t,'add','unique.txt');git(t,'commit','-m','unique detached work');head=git(t,'rev-parse','HEAD');p=wake('detached',r,t);refs=git(t,'for-each-ref','--format=%(refname)','--contains',head,'refs/heads')
result={'candidate':git(source,'rev-parse','HEAD'),'original_head':head,'current_head':git(t,'rev-parse','HEAD'),'containing_branches':refs,'starts':(t/'.tick/starts').read_text(),'rc':p.returncode,'pass':head==git(t,'rev-parse','HEAD') or bool(refs),'predicate':'unique detached work remains current or preserved under a named branch'}
(out/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
