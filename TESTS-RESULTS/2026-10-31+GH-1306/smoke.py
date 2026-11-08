"""GH-1306 manual smoke (no suite, GH-831): intake.py update on an unadopted identical skill.

Usage: python3 -B smoke.py <skills-army-hq bundle dir>
Builds a disposable Pulse-shaped collection (adopt-existing gives `sample` a self-referencing source;
`catalog` gives `other` no source, the 2026-10-30 shape), then drives the bundle's intake.py. Prints one PASS/FAIL line per check; exits 1 on any FAIL.
"""
import json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

BUNDLE = Path(sys.argv[1]).resolve()
fails = 0


def check(label, ok, extra=""):
    global fails
    fails += not ok
    print(f"{'PASS' if ok else 'FAIL'} {label}{(' — ' + extra) if extra and not ok else ''}")


with tempfile.TemporaryDirectory(prefix="gh1306-smoke-") as tmp:
    work = Path(tmp).resolve()
    repo, home = work / "source repo", work / "home"
    home.mkdir()
    env = {**os.environ, "HOME": str(home), "PYTHONDONTWRITEBYTECODE": "1"}
    env.pop("XYZ_FORGE_ROOT", None)
    env.pop("XYZ_SKILLS_ROOT", None)

    def git(*args, cwd=repo):
        subprocess.run(["git", "-C", str(cwd), "-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid", *args],
                       check=True, capture_output=True)

    repo.mkdir()
    git("init", "-q")
    src = repo / "skills" / "sample"
    src.mkdir(parents=True)
    (src / "SKILL.md").write_text("---\nname: sample\ndescription: Smoke fixture.\n---\n\nRead only.\n")
    (src / "run.py").write_text("print('smoke')\n")
    pulse = repo / "Deployed Skills"
    pulse.mkdir()
    shutil.copytree(BUNDLE, pulse / "skills-army-hq", ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    shutil.copyfile(BUNDLE / "README.md", pulse / "README.md")
    shutil.copytree(src, pulse / "sample")
    for name in ("intake.py", "sync.py"):
        (pulse / name).symlink_to(f"skills-army-hq/scripts/{name}")
    (pulse / ".gitignore").write_text(".deploy-skills*\ntargets.json\ncatalog.md\nchangelog.md\nbackups/\n.staging/\n*.zip\n*.lock\n__pycache__/\n*.pyc\n")
    git("add", ".")
    git("commit", "-qm", "fixture")

    def cli(*args):
        run = subprocess.run([sys.executable, "-B", str(pulse / "intake.py"), "--root", str(pulse), *args],
                             env=env, cwd=home, capture_output=True, text=True, timeout=60)
        return run

    def receipt(name):
        return json.loads((pulse / ".deploy-skills.json").read_text())["skills"].get(name, {})

    def head():
        return subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()

    run = cli("--apply", "init", "--adopt-existing")
    check("setup: adopt-existing", run.returncode == 0, run.stderr)
    check("setup: adopt-existing source points inside the collection",
          receipt("sample").get("source") == str(pulse / "sample"), str(receipt("sample")))
    # The 2026-10-30 shape: a payload registered by `catalog` has no source key at all.
    other = repo / "skills" / "other"
    shutil.copytree(src, other)
    (other / "SKILL.md").write_text("---\nname: other\ndescription: Smoke fixture two.\n---\n\nRead only.\n")
    shutil.copytree(other, pulse / "other")
    git("add", ".")
    git("commit", "-qm", "other")
    run = cli("--apply", "catalog")
    check("setup: catalog", run.returncode == 0, run.stderr)
    check("setup: other has no recorded source", "source" not in receipt("other"), str(receipt("other")))
    payload = (pulse / "other" / "run.py").read_bytes()
    commit_before = head()

    # Main path: preview, then apply.
    run = cli("update", "other", "--source", str(other))
    check("preview exits 0", run.returncode == 0, run.stderr)
    check("preview does not say Unchanged", "Unchanged" not in run.stdout, run.stdout)
    check("preview says will RECORD", "will RECORD source" in run.stderr, run.stderr)
    check("preview leaves receipt without source", not receipt("other").get("source"), str(receipt("other")))
    run = cli("--apply", "update", "other", "--source", str(other))
    print("  apply stdout:", run.stdout.strip().replace("\n", " ")[:300])
    print("  apply stderr:", run.stderr.strip().replace("\n", " ")[:300])
    rec = receipt("other")
    check("apply exits 0", run.returncode == 0, run.stderr)
    check("apply records source", rec.get("source") == str(other.resolve()), str(rec))
    check("apply records commit", bool(rec.get("commit")), str(rec))
    check("payload bytes unchanged", (pulse / "other" / "run.py").read_bytes() == payload)
    check("no backup archive written", not list((pulse / "backups").glob("*")) if (pulse / "backups").exists() else True)
    check("no blocked-pulse WARN", "WARN not committed" not in run.stderr, run.stderr)
    check("no Pulse commit for receipt-only update", head() == commit_before)

    # Adjacent shape: an adopt-existing receipt whose source is the collection's own folder.
    run = cli("--apply", "update", "sample", "--source", str(src))
    check("adopt-existing receipt re-points to the owning repo", run.returncode == 0 and
          receipt("sample").get("source") == str(src.resolve()), run.stdout + run.stderr)

    # Adjacent path 1: rerun the same command (idempotent).
    run = cli("--apply", "update", "sample", "--source", str(src))
    check("rerun prints Unchanged", run.returncode == 0 and "Unchanged: sample" in run.stdout, run.stdout + run.stderr)

    # Adjacent path 2: a real content change still copies.
    (src / "run.py").write_text("print('smoke v2')\n")
    run = cli("--apply", "update", "sample", "--source", str(src))
    check("changed payload copies", run.returncode == 0 and (pulse / "sample" / "run.py").read_text() == "print('smoke v2')\n",
          run.stdout + run.stderr)

print(f"{'ALL PASS' if not fails else f'{fails} FAIL'}")
sys.exit(1 if fails else 0)
