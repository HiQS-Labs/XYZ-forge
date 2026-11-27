import ast, os, shutil, subprocess, tempfile, textwrap
src = open("utils/py/relay_drive.py", encoding="utf-8").read()
fn = [n for n in ast.walk(ast.parse(src)) if isinstance(n, ast.FunctionDef) and n.name == "commit_relay_file"]
assert len(fn) == 1, "commit_relay_file not found exactly once"
for _k in [k for k in os.environ if k.startswith("GIT_")]: del os.environ[_k]
os.environ.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
d = tempfile.mkdtemp(prefix="gh1423-probe-")
try:
    g = lambda *a: subprocess.run(["git", "-C", d, *a], capture_output=True, text=True)
    g("init", "-q")
    for k, v in (("user.name", "probe"), ("user.email", "probe"), ("commit.gpgsign", "false"),
                 ("core.hooksPath", os.path.join(d, ".git", "hooks"))):
        g("config", k, v)
    with open(os.path.join(d, ".gitignore"), "w") as fh: fh.write("relay-system/\n")
    os.makedirs(os.path.join(d, "relay-system")); rf = os.path.join(d, "relay-system", "t.md")
    with open(rf, "w") as fh: fh.write("a\n")
    g("add", ".gitignore"); g("add", "-f", "relay-system/t.md")
    assert g("commit", "-qm", "init").returncode == 0, "fixture commit failed"
    with open(rf, "a") as fh: fh.write("b\n")
    ns = {"subprocess": subprocess, "os": os, "relay_file": rf, "transcript_repo": lambda: d,
          "eprint": lambda *a, **k: None}
    exec(textwrap.dedent(ast.get_source_segment(src, fn[0])), ns)
    ok = ns["commit_relay_file"]("m1")
    landed = g("rev-list", "--count", "HEAD").stdout.strip() == "2"
    assert landed, "fixture: the attest commit did not land"
    assert ok is True, "tracked relay file under a gitignored dir: commit landed but reported failure"
    os.remove(os.path.join(d, ".gitignore")); g("commit", "-qam", "drop ignore rule")
    with open(rf, "a") as fh: fh.write("n\n")
    assert ns["commit_relay_file"]("m-plain") is True, "repo without the ignore rule must still attest"
    assert not g("status", "--porcelain", "--", "relay-system").stdout, "plain-repo commit did not land"
    hook = os.path.join(d, ".git", "hooks", "pre-commit")
    with open(hook, "w") as fh: fh.write("#!/bin/sh\nexit 1\n")
    os.chmod(hook, 0o755)
    with open(rf, "a") as fh: fh.write("c\n")
    assert ns["commit_relay_file"]("m2") is False, "a real commit failure must still report False"
finally:
    shutil.rmtree(d, ignore_errors=True)
