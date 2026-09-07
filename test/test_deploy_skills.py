"""GH-484 behavioral tests. Every write is confined to a validated temporary fixture."""
from __future__ import annotations

import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.dont_write_bytecode = True
REPO = Path(__file__).resolve().parents[1]
BUNDLE = REPO / "skills" / "skills-army-hq"
spec = importlib.util.spec_from_file_location("deploy_intake_test", BUNDLE / "scripts" / "intake.py")
intake = importlib.util.module_from_spec(spec)
spec.loader.exec_module(intake)


def tree(path):
    """Independent byte/link/mode/mtime observer, never follows symlinks."""
    result = {}
    for base, dirs, files in os.walk(path, followlinks=False):
        for name in sorted(dirs + files):
            p = Path(base) / name
            st = p.lstat()
            result[str(p.relative_to(path))] = (st.st_mode, st.st_mtime_ns,
                os.readlink(p) if p.is_symlink() else hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None)
    return result


class DeploySkillsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="gh484-fixture-")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name).resolve()
        self.repo = self.work / "source repo"
        self.repo.mkdir()
        self.bundle = self.repo / "skills" / "skills-army-hq"
        shutil.copytree(BUNDLE, self.bundle, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
        self.git("init", "-q")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-qm", "fixture")
        self.root = self.work / "Documents" / "Deployed Skills"
        self.home = self.work / "alternate home"
        self.home.mkdir()
        self.target = self.work / "app skills"
        self.env = {**os.environ, "HOME": str(self.home), "PYTHONDONTWRITEBYTECODE": "1"}
        self.cli("--apply", "init")

    def git(self, *args):
        run = subprocess.run(["git", "-C", str(self.repo), *args], capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stderr)

    def cli(self, *args, sync=False, code=0, copied=False):
        name = "sync.py" if sync else "intake.py"
        script = self.root / name if copied else self.bundle / "scripts" / name
        run = subprocess.run([sys.executable, "-B", str(script), "--root", str(self.root), *map(str, args)],
                             env=self.env, cwd=self.home, capture_output=True, text=True, timeout=30)
        self.assertEqual(run.returncode, code, f"{args}\n{run.stdout}\n{run.stderr}")
        return run

    def source(self, name="sample"):
        folder = self.repo / "skills" / name
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text(f"---\nname: {name}\ndescription: Fixture behavior.\n---\n\nRead only.\n")
        (folder / "run.py").write_text("print('fixture')\n")
        (folder / "run.py").chmod(0o755)
        (folder / "link.py").symlink_to("run.py")
        return folder

    def enable(self, target=None, ident="fixture"):
        self.cli("--apply", "targets", "--id", ident, "--path", target or self.target, "--consumer", "Fixture app")

    def state(self):
        return json.loads((self.root / intake.STATE).read_text())

    def test_a1_copied_manager_and_no_source_dependency(self):
        self.repo.rename(self.work / "source hidden")
        self.cli("list", copied=True)
        self.cli("--apply", "catalog", copied=True)
        self.cli("--status", sync=True, copied=True)
        self.assertTrue((self.root / "skills-army-hq" / "SKILL.md").is_file())
        self.assertEqual(len(list((self.root / "skills-army-hq").rglob("*.py"))), 2)

    def test_a1_incomplete_manager_refused(self):
        (self.bundle / "scripts" / "sync.py").unlink()
        old = tree(self.work)
        self.cli("init", code=2)
        self.assertEqual(tree(self.work), old)

    def test_a1_legacy_manager_activation_preserves_collection(self):
        manager = self.root / "skills-army-hq"
        legacy = self.root / "deploy-skills"
        manager.rename(legacy)
        skill = legacy / "SKILL.md"
        skill.write_text(skill.read_text().replace("name: skills-army-hq", "name: deploy-skills"))
        state = self.state()
        identity = state["collection"]
        record = state["skills"].pop("skills-army-hq")
        record.update(name="deploy-skills", digest=intake.digest(legacy))
        state["skills"]["deploy-skills"] = record
        intake.atomic_json(self.root / intake.STATE, state)
        for name in ("intake.py", "sync.py"):
            (self.root / name).unlink()
            (self.root / name).symlink_to(f"deploy-skills/scripts/{name}")
        self.cli("--apply", "remove", "deploy-skills", code=2)
        self.cli("--apply", "add", self.bundle)
        before = tree(self.root)
        self.cli("activate-manager")
        self.assertEqual(tree(self.root), before)
        self.cli("--apply", "activate-manager")
        self.cli("--apply", "remove", "deploy-skills", copied=True)
        self.cli("list", copied=True)
        self.assertEqual(self.state()["collection"], identity)
        self.assertFalse(legacy.exists())
        self.assertTrue(list((self.root / "backups").glob("deploy-skills-*.zip")))
        for name in ("intake.py", "sync.py"):
            self.assertEqual(os.readlink(self.root / name), f"skills-army-hq/scripts/{name}")

    def test_a1_readme_copied_updated_and_archived(self):
        source = self.bundle / "README.md"
        deployed = self.root / "skills-army-hq" / "README.md"
        landing = self.root / "README.md"
        original = source.read_bytes()
        self.assertTrue(original)
        self.assertEqual(deployed.read_bytes(), original)
        self.assertFalse(landing.is_symlink())
        self.assertEqual(landing.read_bytes(), original)
        revised = original + b"\nFixture provenance update.\n"
        source.write_bytes(revised)
        self.cli("update", "skills-army-hq")
        self.assertEqual(deployed.read_bytes(), original)
        self.assertEqual(landing.read_bytes(), original)
        self.cli("--apply", "update", "skills-army-hq")
        self.assertEqual(deployed.read_bytes(), revised)
        self.assertEqual(landing.read_bytes(), revised)
        archives = list((self.root / "backups").glob("skills-army-hq-*.zip"))
        self.assertEqual(len(archives), 1)
        with zipfile.ZipFile(archives[0]) as archive:
            self.assertEqual(archive.read("skills-army-hq/README.md"), original)
        self.repo.rename(self.work / "source hidden")
        self.assertEqual(deployed.read_bytes(), revised)
        landing.unlink()
        self.cli("--apply", "catalog", copied=True)
        self.assertEqual(landing.read_bytes(), revised)
        landing.write_bytes(b"corrupted landing copy")
        with self.assertRaises(AssertionError):
            self.assertEqual(landing.read_bytes(), revised)
        deployed.write_bytes(b"corrupted copy")
        with self.assertRaises(AssertionError):
            self.assertEqual(deployed.read_bytes(), revised)

    def test_a2_archives_round_trip_and_same_day_collisions(self):
        source = self.source()
        self.cli("--apply", "add", source)
        expected = intake.snapshot(self.root / "sample")
        for version in (2, 3):
            (source / "run.py").write_text(f"print({version})\n")
            self.cli("--apply", "update", "sample")
        archives = sorted((self.root / "backups").glob("sample-*.zip"))
        self.assertEqual(len(archives), 2)
        self.assertTrue(any(p.name.endswith("-02.zip") for p in archives))
        first = next(p for p in archives if not p.name.endswith("-02.zip"))
        restored = self.work / "restore"
        restored.mkdir()
        with zipfile.ZipFile(first) as z:
            self.assertIsNone(z.testzip())
            for member in z.infolist():
                p = restored / member.filename
                self.assertTrue(p.resolve().is_relative_to(restored))
                mode = member.external_attr >> 16
                if stat.S_ISDIR(mode):
                    p.mkdir(parents=True, exist_ok=True)
                elif stat.S_ISLNK(mode):
                    p.symlink_to(z.read(member).decode())
                else:
                    p.parent.mkdir(parents=True, exist_ok=True)
                    p.write_bytes(z.read(member))
                if not stat.S_ISLNK(mode):
                    p.chmod(stat.S_IMODE(mode))
        self.assertEqual(intake.snapshot(restored / "sample"), expected)
        self.cli("--apply", "remove", "sample")
        self.assertFalse((self.root / "sample").exists())
        self.assertEqual(len(list((self.root / "backups").glob("sample-*.zip"))), 3)

    def test_a2_archive_crc_and_copy_failure_preserve_live_payload(self):
        source = self.source()
        self.cli("--apply", "add", source)
        self.enable(); self.cli("--apply", sync=True)
        old = intake.snapshot(self.root / "sample")
        (source / "run.py").write_text("changed\n")
        for target, kwargs in (("testzip", {"return_value": "bad"}),):
            with patch.object(intake.zipfile.ZipFile, target, **kwargs), patch("sys.stdout", new_callable=io.StringIO):
                self.assertEqual(intake.main(["--root", str(self.root), "--apply", "update", "sample"]), 2)
        with patch.object(intake.shutil, "copytree", side_effect=OSError("injected copy failure")), patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(intake.main(["--root", str(self.root), "--apply", "update", "sample"]), 2)
        self.assertEqual(intake.snapshot(self.root / "sample"), old)
        self.assertEqual(os.readlink(self.target / "sample"), str(self.root / "sample"))
        self.assertFalse((self.root / intake.PENDING).exists())

    def test_a2_self_update_preserves_runnable_manager(self):
        (self.bundle / "SKILL.md").write_text((self.bundle / "SKILL.md").read_text() + "\nFixture update.\n")
        self.cli("--apply", "update", "skills-army-hq")
        self.cli("list", copied=True)
        self.cli("--status", sync=True, copied=True)
        self.assertEqual(len(list((self.root / "backups").glob("skills-army-hq-*.zip"))), 1)

    def test_a3_previews_write_nothing(self):
        source = self.source()
        old = tree(self.work)
        self.cli("add", source)
        self.cli("--apply", "--dry-run", "add", source)
        self.cli("catalog")
        self.cli("targets", "--id", "fixture", "--path", self.target)
        self.cli(sync=True)
        self.cli("--apply", "--dry-run", sync=True)
        self.assertEqual(tree(self.work), old)
        new = self.work / "new collection"
        run = subprocess.run([sys.executable, str(self.bundle / "scripts" / "intake.py"), "--root", str(new), "init"], env=self.env, capture_output=True)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertFalse(new.exists())

    def test_a3_names_malformed_sources_and_symlinks(self):
        source = self.source()
        original = (source / "SKILL.md").read_text()
        for content in ("", "---\nname: ../outside\ndescription: bad\n---\n", original.replace("name: sample", "name: SAMPLE"), original.replace("description: Fixture behavior.", "description:")):
            (source / "SKILL.md").write_text(content)
            self.cli("--apply", "add", source, code=2)
            self.assertFalse((self.root / "sample").exists())
        (source / "SKILL.md").write_text(original)
        for destination in (str(self.home), "../../outside", "missing", "."):
            link = source / "invalid"
            link.symlink_to(destination)
            self.cli("--apply", "add", source, code=2)
            link.unlink()
        a, b = source / "a", source / "b"
        a.mkdir(); b.mkdir()
        (a / "to-b").symlink_to("../b"); (b / "to-a").symlink_to("../a")
        self.cli("--apply", "add", source, code=2)

    def test_a3_overlap_alias_and_denied_scan(self):
        self.cli("--apply", "targets", "--id", "bad", "--path", self.root / "nested", code=2)
        self.cli("--apply", "targets", "--id", "bad", "--path", self.root.parent, code=2)
        alias = self.work / "alias"
        alias.symlink_to(self.home)
        self.cli("--apply", "targets", "--id", "bad", "--path", alias / "skills", code=2)
        with patch.object(intake.os, "walk", side_effect=PermissionError("denied scan")):
            with self.assertRaises(PermissionError):
                intake.inventory(self.root, self.state())

    def test_a4_owned_links_idempotence_removed_disabled_and_dedup(self):
        self.cli("--apply", "add", self.source())
        self.enable(); self.enable(ident="same-physical-root")
        first = json.loads(self.cli("--apply", sync=True).stdout)
        self.assertEqual(len(first["actions"]), 2)
        self.assertEqual(set(p.name for p in self.target.iterdir()), {"skills-army-hq", "sample"})
        old = (self.root / "changelog.md").read_bytes()
        self.assertEqual(json.loads(self.cli("--apply", sync=True).stdout)["actions"], [])
        self.assertEqual((self.root / "changelog.md").read_bytes(), old)
        (self.target / "sample").unlink()
        self.cli("--apply", sync=True)
        self.assertTrue((self.target / "sample").is_symlink())
        self.cli("--apply", "targets", "--id", "fixture", "--remove")
        self.cli("--apply", "targets", "--id", "same-physical-root", "--disable")
        self.cli("--apply", sync=True)
        self.assertEqual(list(self.target.iterdir()), [])
        self.assertEqual(self.state()["links"], {})

    def test_a4_foreign_real_link_and_lost_ownership_preserved(self):
        self.cli("--apply", "add", self.source())
        self.enable(); self.cli("--apply", sync=True)
        (self.target / "sample").unlink()
        (self.target / "sample").symlink_to("foreign-dangling")
        (self.target / "skills-army-hq").unlink()
        (self.target / "skills-army-hq").mkdir()
        old = tree(self.target)
        self.cli("--apply", "remove", "sample")
        self.cli("--apply", sync=True, code=2)
        self.assertEqual(tree(self.target), old)
        self.assertEqual(len(self.state()["links"]), 2)

    def test_a4_adopt_and_selected_source_migration(self):
        source = self.source()
        self.cli("--apply", "add", source)
        self.enable(); self.target.mkdir()
        (self.target / "sample").symlink_to(source)
        (self.target / "skills-army-hq").symlink_to(self.root / "skills-army-hq")
        self.cli(sync=True, code=2)
        self.cli("--apply", "--migrate", "sample", "--adopt", "skills-army-hq", sync=True)
        self.assertEqual(os.readlink(self.target / "sample"), str(self.root / "sample"))
        self.assertEqual(self.state()["links"][str(self.target / "sample")]["previous"], str(source))

    def test_a4_partial_sync_reports_failure_and_keeps_success(self):
        self.enable(); self.target.mkdir()
        (self.target / "skills-army-hq").mkdir()
        other = self.work / "other app"
        self.enable(other, "other")
        run = self.cli("--apply", sync=True, code=2)
        result = json.loads(run.stdout)
        self.assertEqual(len(result["errors"]), 1)
        self.assertEqual(len(result["actions"]), 1)
        self.assertTrue((other / "skills-army-hq").is_symlink())
        self.assertIn("sync-partial", (self.root / "changelog.md").read_text())

    def test_a4_alternative_source_requires_exact_explicit_selection(self):
        source = self.source()
        self.cli("--apply", "add", source)
        prior = self.repo / "alternate" / "sample"
        prior.parent.mkdir(); shutil.copytree(source, prior, symlinks=True)
        (prior / "run.py").write_text("different version\n")
        self.enable(); self.target.mkdir()
        (self.target / "sample").symlink_to(prior)
        self.cli("--apply", "--migrate", "sample", sync=True, code=2)
        self.assertEqual(os.readlink(self.target / "sample"), str(prior))
        self.cli("--apply", "--migrate-from", f"sample={source}", sync=True, code=2)
        self.assertEqual(os.readlink(self.target / "sample"), str(prior))
        self.cli("--apply", "--migrate-from", f"sample={prior}", sync=True)
        self.assertEqual(os.readlink(self.target / "sample"), str(self.root / "sample"))
        self.assertEqual((prior / "run.py").read_text(), "different version\n")

    def test_a7_missing_manager_entry_blocks_usability(self):
        (self.root / "sync.py").unlink()
        before = tree(self.work)
        self.cli("--status", sync=True, code=2)
        self.assertEqual(tree(self.work), before)

    def test_a5_missing_payload_corrupt_state_and_history_refuse_prune(self):
        source = self.source()
        self.cli("--apply", "add", source); self.enable(); self.cli("--apply", sync=True)
        (self.root / "sample").rename(self.work / "manual withdrawal")
        before = tree(self.target)
        self.cli("--apply", sync=True, code=2)
        self.assertEqual(tree(self.target), before)
        self.cli("--apply", "remove", "sample")
        self.cli("--apply", sync=True)
        self.assertFalse((self.target / "sample").is_symlink())
        for control in (intake.STATE, "targets.json", "changelog.md"):
            file = self.root / control
            old = file.read_bytes()
            file.write_text("corrupt\n")
            before = tree(self.target)
            self.cli("--apply", sync=True, code=2)
            self.assertEqual(tree(self.target), before)
            file.write_bytes(old)

    def test_a5_live_shared_lock_refuses_without_stealing(self):
        with intake.locked(self.root):
            before = (self.root / ".deploy-skills.lock").read_bytes()
            self.cli("--apply", sync=True, code=2)
            self.cli("--apply", "catalog", code=2)
            self.assertEqual((self.root / ".deploy-skills.lock").read_bytes(), before)
        self.cli("--apply", "catalog")

    def crash(self, point, args, sync=False):
        script = self.bundle / "scripts" / ("sync.py" if sync else "intake.py")
        code = '''import importlib.util,os,sys
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location("crash_cli",sys.argv[1]); mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
shared=mod.shared if hasattr(mod,"shared") else mod
point=sys.argv[2]
if point == "rename":
 old=shared.Path.rename
 def wrapped(self,*a,**kw):
  result=old(self,*a,**kw)
  if self.name == "sample": os._exit(77)
  return result
 shared.Path.rename=wrapped
else:
 old=getattr(shared,point)
 def wrapped(*a,**kw):
  result=old(*a,**kw)
  if point != "atomic_json" or a[0].name == shared.STATE: os._exit(77)
  return result
 setattr(shared,point,wrapped)
raise SystemExit(mod.main(sys.argv[3:]))
'''
        run = subprocess.run([sys.executable, "-B", "-c", code, str(script), point, "--root", str(self.root), "--apply", *args],
                             env=self.env, capture_output=True, text=True, timeout=30)
        self.assertEqual(run.returncode, 77, run.stderr)
        self.assertTrue((self.root / intake.PENDING).is_file())

    def test_a5_crash_each_publish_boundary_recovers_once(self):
        source = self.source()
        self.cli("--apply", "add", source)
        for point in ("rename", "action_apply", "atomic_json", "history"):
            with self.subTest(point=point):
                (source / "run.py").write_text(f"version {point}\n")
                self.crash(point, ["update", "sample"])
                self.cli("--apply", "catalog", code=2)
                self.cli("recover")
                receipt = json.loads((self.root / intake.PENDING).read_text())
                self.cli("--apply", "recover")
                self.assertEqual(intake.snapshot(self.root / "sample"), intake.snapshot(source))
                self.assertEqual((self.root / "changelog.md").read_text().count("operation:" + receipt["event"]["id"]), 1)
                self.assertFalse((self.root / intake.PENDING).exists())

    def test_a5_link_crash_and_corrupt_pending_fail_closed(self):
        self.enable()
        self.crash("action_apply", [], sync=True)
        pending = self.root / intake.PENDING
        good = pending.read_bytes()
        bad = json.loads(good); bad["actions"][0]["after"] = "/foreign"
        pending.write_text(json.dumps(bad))
        old = tree(self.target)
        self.cli("--apply", "recover", code=2)
        self.assertEqual(tree(self.target), old)
        pending.write_bytes(good)
        self.cli("--apply", "recover")
        self.assertEqual(os.readlink(self.target / "skills-army-hq"), str(self.root / "skills-army-hq"))

    def test_a10_retirement_is_explicit_and_recoverable(self):
        legacy = self.source("skills-sync-trinity")
        self.enable(); self.cli("--apply", sync=True)
        entry = self.target / legacy.name
        entry.symlink_to(legacy)
        old = tree(self.work)
        self.cli("--retire-trinity", legacy, sync=True)
        self.assertEqual(tree(self.work), old)
        self.cli("--apply", "--retire-trinity", legacy, sync=True)
        self.assertFalse(entry.is_symlink())
        self.assertIn(str(legacy), (self.root / "changelog.md").read_text())
        shutil.copytree(legacy, entry, symlinks=True)
        self.cli("--apply", "--retire-trinity", legacy, sync=True, code=2)
        self.assertTrue(entry.is_dir())
        self.cli("--apply", "--retire-trinity", legacy, "--archive-legacy", sync=True)
        self.assertFalse(entry.exists())
        self.assertEqual(len(list((self.root / "backups").glob("skills-sync-trinity-*.zip"))), 1)

    def test_a10_old_discoverable_skill_is_absent(self):
        self.assertFalse((REPO / "skills" / "skills-sync-trinity" / "SKILL.md").exists())
        self.assertTrue((BUNDLE / "SKILL.md").is_file())

    def test_a6_shipped_consult_has_no_recursive_install_artifact(self):
        self.assertEqual(intake.skill_info(REPO / "skills" / "consult")["name"], "consult")
        self.assertGreater(len(intake.snapshot(REPO / "skills" / "consult")), 1)

    def test_a7_swe_description_fits_zcode_discovery_limit(self):
        description = intake.skill_info(REPO / "skills" / "swe")["description"]
        self.assertTrue(description)
        self.assertLessEqual(len(description), 1024)


if __name__ == "__main__":
    unittest.main(verbosity=2)
