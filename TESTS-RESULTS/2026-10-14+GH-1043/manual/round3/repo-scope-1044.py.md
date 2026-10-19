```python
from pathlib import Path
from types import ModuleType,SimpleNamespace
from unittest.mock import patch
from contextlib import redirect_stdout
from io import StringIO
import sqlite3,json
root=Path.cwd()
def load(p):
 m=ModuleType(p.stem);m.__file__=str(p);exec(compile(p.read_text(),str(p),"exec"),m.__dict__);return m
m=load(root/"skills/3-weekly/weekly-planner/scripts/planner_core.py");r=load(root/"utils/py/releases_app.py");realconnect=sqlite3.connect
def memory():
 src=realconnect(f"file:{root/'releases.db'}?mode=ro",uri=True);dst=realconnect(":memory:");src.backup(dst);src.close();dst.row_factory=sqlite3.Row
 dst.execute("PRAGMA foreign_keys=ON")
 dst.execute("INSERT INTO repos (global_id,slug) VALUES ('repo-01ARZ3NDEKTSV4RRFFQ69G5FAV','Other/Project')")
 other=dst.execute("SELECT id FROM repos WHERE slug='Other/Project'").fetchone()[0]
 row=dict(dst.execute("SELECT * FROM roadmap_items WHERE gh_number=418").fetchone());row.pop("id")
 row.update(repo_id=other,global_id="rmi-01ARZ3NDEKTSV4RRFFQ69G5FAV",title="Foreign repository work",issue_url=None,raw_text="")
 keys=list(row);dst.execute("INSERT INTO roadmap_items ("+",".join(keys)+") VALUES ("+",".join("?" for _ in keys)+")",list(row.values()))
 return dst
buf=StringIO()
with patch.object(r,"resolve_root",return_value=root),patch.object(r,"artifact_paths",return_value={"db":root/"releases.db"}),patch.object(r,"connect",side_effect=lambda p:memory()),redirect_stdout(buf):
 r.cmd_roadmap_list(SimpleNamespace(root=str(root),as_json=True))
live={i["number"]:i for i in json.loads(Path("TESTS-RESULTS/2026-10-14+GH-1043/manual/open-issues-snapshot.json").read_text())}
with patch.object(m,"ensure_temp_dir",return_value=root/".relay-scratch/tmp"),patch.object(m,"get_open_issues",return_value=live),patch.object(m,"get_release_milestones",return_value={}):
 with patch.object(sqlite3,"connect",side_effect=lambda *a,**k:memory()):
  db=m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
 with patch.object(sqlite3,"connect",side_effect=sqlite3.OperationalError("controlled direct-reader failure")),patch.object(m,"run_cmd",return_value=buf.getvalue()):
  cli=m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
print("DB GH418 titles:",[i["title"] for i in db["roadmap_items"] if i["gh_number"]==418])
print("CLI GH418 titles:",[i["title"] for i in cli["roadmap_items"] if i["gh_number"]==418])
print("CLI repo identity keys:",sorted(set(json.loads(buf.getvalue())[-1]) & {"repo_id","repo_slug"}))
assert [i["title"] for i in db["roadmap_items"] if i["gh_number"]==418] == [i["title"] for i in cli["roadmap_items"] if i["gh_number"]==418]
assert not any(i["title"] == "Foreign repository work" for i in cli["roadmap_items"])
old=json.loads(buf.getvalue());[row.pop("is_selected_repo") for row in old]
with patch.object(m,"ensure_temp_dir",return_value=root/".relay-scratch/tmp"),patch.object(m,"get_open_issues",return_value=live),patch.object(m,"get_release_milestones",return_value={}),patch.object(sqlite3,"connect",side_effect=sqlite3.OperationalError("controlled failure")),patch.object(m,"run_cmd",return_value=json.dumps(old)):
 try: m.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
 except ValueError as e: print("Old producer rejected:",e)
 else: raise AssertionError("old producer accepted")
print("PASS selected repository fallback and old-producer stop")

mut=ModuleType("scope_red_control");mut.__file__=str(root/"skills/3-weekly/weekly-planner/scripts/planner_core.py")
exec(compile(Path(mut.__file__).read_text().replace('raw_items = [row for row in raw_items if row["is_selected_repo"]]','raw_items = raw_items'),mut.__file__,"exec"),mut.__dict__)
with patch.object(mut,"ensure_temp_dir",return_value=root/".relay-scratch/tmp"),patch.object(mut,"get_open_issues",return_value=live),patch.object(mut,"get_release_milestones",return_value={}),patch.object(sqlite3,"connect",side_effect=sqlite3.OperationalError("controlled failure")),patch.object(mut,"run_cmd",return_value=buf.getvalue()):
 red=mut.ingest_weekly_intake(root,"HiQS-Labs/XYZ-forge")
assert any(i["title"] == "Foreign repository work" for i in red["roadmap_items"])
print("RED CONTROL witnessed foreign row when selected-repository filter is removed")

```
