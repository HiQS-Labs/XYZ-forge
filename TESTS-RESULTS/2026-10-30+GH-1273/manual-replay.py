import sys,json,hashlib,tempfile, pathlib
sys.path.insert(0,'utils/py')
import relay_attest as a
pre=b'STATUS: Open\n\n## Log\n\nHistorical FAIL sentence.\n\nOther paragraph.\n'
review=b'\n### Reviewer\nVERDICT: PASS\nBasis: source.py:1\n'
for name,old,new,expected in [
 ('separator-delete',pre,pre.replace(b'\n\nOther',b'\nOther'),True),
 ('separator-add',pre,pre.replace(b'\n\nOther',b'\n\n\nOther'),True),
 ('rewrite',pre,pre.replace(b'FAIL',b'PASS'),False),
 ('delete-sentence',pre,pre.replace(b'Historical FAIL sentence.\n',b''),False),
 ('fenced-blank',pre+b'```\nx\n\ny\n```\n',pre+b'```\nx\ny\n```\n',False),
 ('indented-blank',pre+b'    x\n\n    y\n',pre+b'    x\n    y\n',False)]:
 post=new+review
 strict=a.canonical_bytes(post).startswith(a.canonical_prefix(old,post))
 end=len(a.canonical_prefix(old,post)) if strict else a.separator_prefix_end(old,post)
 assert (end is not None)==expected,(name,end)
 if expected: assert b'VERDICT: PASS' in a.canonical_bytes(post)[end:]
 print(name,'PASS','strict='+str(strict),'offset='+str(end))
# Legacy and fallback records use unchanged loader coordinates and trailer bytes.
for name,history in [('legacy',pre),('fallback',pre.replace(b'\n\nOther',b'\nOther'))]:
 post=history.replace(b'STATUS: Open',b'STATUS: Approved')+review
 canon=a.canonical_bytes(post)
 end=len(a.canonical_prefix(pre,post)) if name=='legacy' else a.separator_prefix_end(pre,post)
 with tempfile.TemporaryDirectory() as d:
  f=pathlib.Path(d)/'relay.md'; rec=dict(schema=a.SCHEMA,task='replay',reviewer='codex',status='Approved',reviewed_head='abc',added_start=end,added_len=len(canon)-end,added_sha256=a.sha256(canon[end:]),relay_file=str(f),target_repo=d,isolated=True,attested_at='2026-10-30',driver_pid=1)
  rec['trailer_sha256']=a.sha256(a.trailer_text(rec).encode()); f.write_bytes(post+a.trailer_text(rec).encode()); r=pathlib.Path(d)/'record.json';r.write_text(json.dumps(rec))
  assert a.load('replay',expected_reviewer='codex',relay_file=str(f),target_repo=d,path=str(r))[1] is None
  assert a.load('replay',expected_reviewer='wrong',relay_file=str(f),target_repo=d,path=str(r))[0] is None
 print(name,'loader-roundtrip PASS; wrong reviewer refused')

p=b"STATUS: Open\n\n    x\n\n\n\n    y\n"
q=p.replace(b"\n\n\n\n",b"\n\n\n")+review
assert a.separator_prefix_end(p,q) is None
print('long-indented-run refused PASS')
p=b"STATUS: Open\n\n[Pass] claim\n\n\n\nfile.py:1\n"
q=(p.replace(b"Open\n\n",b"Approved\n")+review).replace(b"[Pass]",a._UNCITED)
assert a.separator_prefix_end(p,q) is not None
print('citation-position separator accepted PASS')

p=b"STATUS: Open\n\n<pre>\n<!-- note -->\nalpha\n\nbeta\n</pre>\n"
q=p.replace(b"alpha\n\nbeta",b"alpha\nbeta")+review
assert a.separator_prefix_end(p,q) is None
print('HTML enclosing literal with comment refused PASS')
