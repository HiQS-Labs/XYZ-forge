"""GH-1315 readiness probe (preparation receipt, not a test suite; retained manual check, GH-831).

Exit 0 ONLY when the FIXED behavior is positively observed through the real CLI; any other outcome
(bug still present, harness error, crash) exits nonzero.  The contract pairs it with
`expect_nonzero: true`, so Preflight reads "unfixed" unless this script succeeds.

Fixed behavior (issue #1315 "Expected"): for a skill that has a copy in the collection but is NOT
recorded in .deploy-skills.json, `sync.py --migrate-legacy NAME --archive-legacy` refuses in preview
(exit 2) with the SAME error as apply (exit 2) for that folder, and the error names the skill and the
adoption remedy; neither mode creates a backup ZIP, a new staging directory or a link, or touches the
real legacy folder.  A skill that IS recorded still previews AND applies (managed link plus retained
archive): the positive control.

All writes are confined to one resolved temp directory; HOME points inside it.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
BUNDLE = Path("skills/3-weekly/skills-army-hq/scripts").resolve()
BODY = "---\nname: {n}\ndescription: fixture\n---\nbody\n"


def run(env, script, root, *args):
    p = subprocess.run([sys.executable, "-B", str(BUNDLE / script), "--root", str(root), *args],
                       env=env, cwd=env["HOME"], capture_output=True, text=True, timeout=60)
    return p.returncode, p.stdout, p.stderr


def snapshot(path):
    return sorted((str(p.relative_to(path)), p.is_symlink(), p.read_bytes() if p.is_file() and not p.is_symlink() else b"")
                  for p in path.rglob("*"))


def main():
    with tempfile.TemporaryDirectory(prefix="gh1315-probe-") as raw:
        work = Path(raw).resolve()
        home = work / "home"
        home.mkdir()
        env = {**os.environ, "HOME": str(home), "PYTHONDONTWRITEBYTECODE": "1"}
        env.pop("XYZ_FORGE_ROOT", None)
        root, target = work / "Deployed Skills", work / "app skills"
        rc, out, err = run(env, "intake.py", root, "--apply", "init")
        assert rc == 0, ("init", rc, out, err)
        rc, out, err = run(env, "intake.py", root, "--apply", "targets", "--id", "fixture",
                           "--path", str(target), "--consumer", "Fixture app")
        assert rc == 0, ("targets", rc, out, err)
        rc, out, err = run(env, "sync.py", root, "--apply")  # baseline: skills-army-hq linked, nothing else pending
        assert rc == 0, ("baseline sync", rc, out, err)
        # an unadopted skill: a copy in the collection, never recorded in .deploy-skills.json
        for parent in (root, target):
            (parent / "xyz").mkdir(parents=True)
            (parent / "xyz" / "SKILL.md").write_text(BODY.format(n="xyz"))
        state = json.loads((root / ".deploy-skills.json").read_text())
        assert "xyz" not in state["skills"], "fixture must leave xyz unadopted"
        before, target_before = snapshot(work), snapshot(target)
        staging_before = {q.name for q in root.glob(".staging/*")}
        legacy = ("--migrate-legacy", "xyz", "--archive-legacy")

        def refusal(out):
            """The error entries that concern the selected legacy folder, parsed from the CLI's JSON."""
            errors = json.loads(out)["errors"]
            return [e["error"] for e in errors if e["path"].rstrip("/").split("/")[-1] == "xyz"]

        rc, out, err = run(env, "sync.py", root, *legacy)
        preview_errors = refusal(out)
        assert rc == 2 and len(preview_errors) == 1, ("preview must refuse like apply", rc, out, err)
        assert "adopt" in preview_errors[0].lower(), ("preview refusal must name the adoption remedy", preview_errors)
        assert snapshot(work) == before, "preview must not write anything"

        rc, out, err = run(env, "sync.py", root, *legacy, "--apply")
        assert rc == 2 and refusal(out) == preview_errors, ("apply must refuse with the same reason as preview",
                                                           rc, refusal(out), preview_errors, err)
        # A refused apply may still record a sync-partial history entry; what it must NOT leave is a
        # backup ZIP, a new staging directory or a link, and the legacy folder must be intact.
        assert not list(root.glob("backups/*.zip")), "refused apply must not write a backup ZIP"
        assert {q.name for q in root.glob(".staging/*")} == staging_before, "refused apply must not add a staging directory"
        assert snapshot(target) == target_before, "refused apply must leave the app root untouched"
        assert (target / "xyz").is_dir() and not (target / "xyz").is_symlink()
        # positive control: a skill RECORDED in state still previews cleanly and plans the link
        shutil.rmtree(target / "xyz")  # the refused fixture is done; keep it from muddying the control
        shutil.rmtree(root / "xyz")
        repo = work / "source repo"
        (repo / "skills" / "sample").mkdir(parents=True)
        (repo / "skills" / "sample" / "SKILL.md").write_text(BODY.format(n="sample"))
        for git in (("init", "-q"), ("add", "."), ("-c", "user.name=Probe", "-c", "user.email=probe@example.invalid",
                                                   "commit", "-qm", "fixture")):
            subprocess.run(["git", "-C", str(repo), *git], check=True, capture_output=True)
        rc, out, err = run(env, "intake.py", root, "--apply", "add", str(repo / "skills" / "sample"))
        assert rc == 0, ("add", rc, out, err)
        (target / "sample").mkdir()
        (target / "sample" / "SKILL.md").write_text(BODY.format(n="sample") + "stale installer copy\n")
        before = snapshot(work)
        rc, out, err = run(env, "sync.py", root, "--migrate-legacy", "sample", "--archive-legacy")
        result = json.loads(out)
        assert rc == 0 and result["errors"] == [], ("recorded skill must still preview cleanly", rc, out, err)
        assert any(a["kind"] == "link" and a["name"] == "sample" for a in result["actions"]), result["actions"]
        assert snapshot(work) == before, "recorded-skill preview must not write anything"
        rc, out, err = run(env, "sync.py", root, "--migrate-legacy", "sample", "--archive-legacy", "--apply")
        assert rc == 0, ("recorded skill must still apply", rc, out, err)
        assert (target / "sample").is_symlink() and (target / "sample").resolve() == (root / "sample").resolve()
        assert len(list(root.glob("backups/sample-*.zip"))) == 1, "apply must retain the archive of the legacy folder"
        print("unadopted legacy migration is refused by preview and apply (adoption remedy named); "
              "no backup ZIP, staging directory or link; recorded-skill preview and apply unchanged")


if __name__ == "__main__":
    main()
