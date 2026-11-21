import ast,os,re,subprocess,tempfile
from pathlib import Path
source=Path("utils/py/relay_drive.py").read_text()
tree=ast.parse(source)
names={"relay_setup_section_lines","relay_extract_markdown_paths","relay_is_worktree_artifact_path","preflight_setup_artifact_paths"}
nodes=[n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name in names]
assert len(nodes)==4
ns=dict(os=os,re=re,subprocess=subprocess,root_dir=os.getcwd(),get_env=lambda k: os.getcwd() if k=="RELAY_TARGET_ROOT" else "")
def die(message): raise RuntimeError(message)
ns["die"]=die
exec(compile(ast.Module(body=nodes,type_ignores=[]),"relay-preflight-probe","exec"),ns)
branch="fix/gh1171-probe"
with tempfile.TemporaryDirectory() as d:
 fixture=Path(d).resolve(); subprocess.run(["git","init","-q",str(fixture)],check=True)
 subprocess.run(["git","-C",str(fixture),"symbolic-ref","HEAD","refs/heads/"+branch],check=True)
 subprocess.run(["git","-C",str(fixture),"-c","user.name=Probe","-c","user.email=probe@example.invalid","-c","commit.gpgsign=false","commit","-q","--allow-empty","-m","fixture"],check=True)
 ns["root_dir"]=str(fixture); ns["get_env"]=lambda k: str(fixture) if k=="RELAY_TARGET_ROOT" else ""
 p=fixture/"relay.md"; ns["relay_file"]=str(p)
 p.write_text("## Setup\nArtifact under review: branch `"+branch+"`\n")
 ns["preflight_setup_artifact_paths"]()
 p.write_text("## Setup\nArtifact under review: `docs/gh1171-missing.md`\n")
 try: ns["preflight_setup_artifact_paths"]()
 except RuntimeError as e: assert "artifact path not found in worktree" in str(e)
 else: raise AssertionError("missing file accepted")
print("branch accepted; missing file rejected")
