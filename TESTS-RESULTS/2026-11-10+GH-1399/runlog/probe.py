import ast,json,subprocess
from pathlib import Path
def load(text):
 tree=ast.parse(text);f=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='runlog_find_comment_id');ns={'json':json};exec(compile(ast.Module(body=[f],type_ignores=[]),'runlog-control','exec'),ns);return ns[f.name]
old=load(subprocess.check_output(['git','show','b14ff1c92:utils/py/marathon_drive.py'],text=True));new=load(Path('utils/py/marathon_drive.py').read_text());marker='<!-- xyz-marathon-run-log:1399:p1 -->';quoted={'id':101,'body':'Example:\n```\n'+marker+'\n```'};owned={'id':202,'body':marker+'\n### Marathon run log'}
cases=[('genuine',[owned],'202'),('quoted-only',[quoted],''),('quoted-first',[quoted,owned],'202'),('paginated',[[quoted],[owned]],'202'),('marker-prefix',[{'id':303,'body':marker+' suffix'}],''),('CRLF',[dict(owned,body=marker+'\r\nlog')],'202'),('empty',[],'')];results=[]
for name,rows,expected in cases:
 payload=json.dumps(rows);before=old(payload,marker);after=new(payload,marker);assert after==expected,(name,after);results.append(dict(name=name,old=before,fixed=after,expected=expected))
assert old(json.dumps([quoted,owned]),marker)=='101';assert old(json.dumps([quoted]),marker)=='101';assert new('not json',marker)==''
Path('temp/gh1399-runlog/result.json').write_text(json.dumps(results,indent=2));print('quoted controls RED at base; all fixed flat/paginated/exact/CRLF/empty controls PASS')
