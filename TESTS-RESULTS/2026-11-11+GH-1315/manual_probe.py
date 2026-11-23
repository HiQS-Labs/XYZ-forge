import sys,tempfile,copy
from pathlib import Path
sys.path.insert(0,str(Path("skills/3-weekly/skills-army-hq/scripts").resolve()))
import sync
with tempfile.TemporaryDirectory() as d:
 root=Path(d).resolve()/"collection"; target=Path(d).resolve()/"target"; root.mkdir(); target.mkdir()
 for parent in (root,target):
  p=parent/"example"; p.mkdir(); (p/"SKILL.md").write_text("---\nname: example\ndescription: fixture\n---\n")
 state={"collection":"fixture","skills":{},"links":{}}
 config={"targets":[{"path":str(target),"enabled":True}]}
 found={"example":{"digest":sync.shared.digest(root/"example")}}
 actions,errors,changes=sync.reconcile(root,copy.deepcopy(state),config,found,legacy=["example"],archive_directories=True,apply=False)
 assert errors and any("adopt" in e["error"].lower() for e in errors), (actions,errors,changes)
 assert not actions, actions
 assert not (root/"backups").exists()
 assert (target/"example").is_dir() and not (target/"example").is_symlink()
 print("unadopted preview refuses with adoption remedy before side effects")
