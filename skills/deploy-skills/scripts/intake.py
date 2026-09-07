#!/usr/bin/env python3
"""Local skill collection, verified archives and shared transaction persistence (Python 3.9+)."""
from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import uuid
import zipfile

sys.dont_write_bytecode = True
SCHEMA = 1
STATE = ".deploy-skills.json"
PENDING = ".deploy-skills-pending.json"
NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")
RESERVED = {"backups", "catalog", "changelog", "targets", "intake", "sync"}


class DeployError(Exception):
    pass


def require(ok, message):
    if not ok:
        raise DeployError(message)


def utc():
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def safe_name(value):
    require(isinstance(value, str) and len(value) <= 64 and NAME.fullmatch(value)
            and value not in RESERVED, f"Invalid/reserved skill name: {value!r}")
    return value


def within(child, parent):
    return child != parent and parent in child.parents


def location(raw):
    """Validate a concrete path, including every existing symlink ancestor."""
    require(str(raw).strip() and not str(raw).startswith(("http:", "https:")), "Local path required")
    path = Path(os.path.abspath(Path(raw).expanduser()))
    for part in [path, *path.parents]:
        require(not part.is_symlink(), f"Symlinked root/ancestor refused: {part}; select its real path")
    require(path != Path(path.anchor) and path != Path.home(), f"Protected root: {path}")
    return path


def regular_bytes(path):
    require(path.is_file() and not path.is_symlink(), f"Expected regular file: {path}")
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    with os.fdopen(fd, "rb") as stream:
        require(stat.S_ISREG(os.fstat(stream.fileno()).st_mode), f"Not a regular file: {path}")
        return stream.read()


def read_json(path):
    try:
        return json.loads(regular_bytes(path))
    except (ValueError, UnicodeError) as exc:
        raise DeployError(f"Corrupt JSON {path}: {exc}") from exc


def atomic_bytes(path, data):
    location(path.parent)
    require(not path.is_symlink(), f"Refusing control-file symlink: {path}")
    tmp = path.with_name(f".{path.name}.{uuid.uuid4().hex}.tmp")
    try:
        with tmp.open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(tmp, path)
    finally:
        if tmp.exists():
            tmp.unlink()


def atomic_json(path, value):
    atomic_bytes(path, (json.dumps(value, indent=2, sort_keys=True) + "\n").encode())


def skill_info(folder):
    """Read the two discovery fields; leave the rest of the author's YAML untouched."""
    text = regular_bytes(folder / "SKILL.md").decode("utf-8")
    require(text.startswith("---\n") and "\n---" in text[4:], f"Missing frontmatter: {folder}/SKILL.md")
    header = text[4:].split("\n---", 1)[0]
    fields = {}
    lines = header.splitlines()
    for i, line in enumerate(lines):
        match = re.match(r"^(name|description):\s*(.*)$", line)
        if match:
            key, value = match.groups()
            require(key not in fields, f"Duplicate {key} in {folder}/SKILL.md")
            if value in ("|", "|-", "|+", ">", ">-", ">+"):
                block = []
                for following in lines[i + 1:]:
                    if following and not following[0].isspace():
                        break
                    block.append(following.strip())
                value = " ".join(block).strip()
            elif value.startswith('"'):
                try:
                    value = json.loads(value)
                except ValueError as exc:
                    raise DeployError(f"Invalid quoted {key} in {folder}") from exc
            elif value.startswith("'"):
                require(value.endswith("'"), f"Unclosed {key} in {folder}")
                value = value[1:-1].replace("''", "'")
            fields[key] = value
    name = safe_name(fields.get("name"))
    require(folder.name == name, f"Folder/name mismatch: {folder.name} != {name}")
    require(isinstance(fields.get("description"), str) and fields["description"].strip(),
            f"Missing description: {folder}/SKILL.md")
    return fields


def snapshot(folder):
    """Hash bytes, modes and internal relative link text without traversing links."""
    require(folder.is_dir() and not folder.is_symlink(), f"Expected real skill folder: {folder}")
    entries = {"": {"kind": "dir", "mode": stat.S_IMODE(folder.stat().st_mode)}}
    directory_edges = {}
    for base, dirs, files in os.walk(folder, followlinks=False, onerror=lambda e: (_ for _ in ()).throw(e)):
        directory_edges[Path(base).resolve()] = []
        for name in sorted(dirs + files):
            path = Path(base) / name
            rel = path.relative_to(folder).as_posix()
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                target = os.readlink(path)
                require(not os.path.isabs(target), f"Absolute payload link: {path}")
                try:
                    resolved = path.resolve(strict=True)
                except (OSError, RuntimeError) as exc:
                    raise DeployError(f"Dangling/cyclic payload link: {path}") from exc
                require(within(resolved, folder.resolve()) and resolved not in path.parents,
                        f"External/cyclic payload link: {path}")
                entries[rel] = {"kind": "link", "text": target, "mode": stat.S_IMODE(mode)}
                if resolved.is_dir():
                    directory_edges[Path(base).resolve()].append(resolved)
            elif stat.S_ISDIR(mode):
                entries[rel] = {"kind": "dir", "mode": stat.S_IMODE(mode)}
                directory_edges[Path(base).resolve()].append(path.resolve())
            elif stat.S_ISREG(mode):
                entries[rel] = {"kind": "file", "mode": stat.S_IMODE(mode),
                                "sha256": hashlib.sha256(regular_bytes(path)).hexdigest()}
            else:
                raise DeployError(f"Special file refused: {path}")
    visited, active = set(), set()
    def visit(directory):
        require(directory not in active, f"Cyclic directory links: {directory}")
        if directory in visited:
            return
        active.add(directory)
        for child in directory_edges.get(directory, []):
            visit(child)
        active.remove(directory)
        visited.add(directory)
    visit(folder.resolve())
    require(len(entries) > 1, f"Empty skill: {folder}")
    return entries


def digest(folder):
    return hashlib.sha256(json.dumps(snapshot(folder), sort_keys=True).encode()).hexdigest()


def source_record(raw):
    source = Path(raw).expanduser().resolve(strict=True)
    info = skill_info(source)
    result = subprocess.run(["git", "--no-optional-locks", "-C", str(source), "rev-parse", "--show-toplevel"],
                            text=True, capture_output=True)
    require(result.returncode == 0, f"Source must be in a local Git repository: {source}")
    repo = Path(result.stdout.strip()).resolve()
    require(within(source, repo), f"Select a skill folder inside the repository: {source}")
    def git(*args):
        run = subprocess.run(["git", "--no-optional-locks", "-C", str(repo), *args], text=True, capture_output=True)
        require(run.returncode == 0, f"Cannot inspect source repository: {run.stderr.strip()}")
        return run.stdout.strip()
    return source, {**info, "source": str(source), "repository": str(repo),
                    "commit": git("rev-parse", "HEAD"),
                    "dirty": bool(git("status", "--porcelain", "--", str(source))),
                    "digest": digest(source), "updated": utc(), "prerequisites": []}


def defaults():
    return {"schema": SCHEMA, "targets": [
        {"id": "claude", "path": "~/.claude/skills", "enabled": False,
         "consumers": ["VS Code Claude Code extension"]},
        {"id": "codex", "path": "~/.agents/skills", "enabled": False,
         "consumers": ["VS Code Codex extension", "Codex desktop app"]},
        {"id": "antigravity", "path": "~/.gemini/config/skills", "enabled": False,
         "consumers": ["Antigravity app"]},
        {"id": "zcode", "path": "~/.zcode/skills", "enabled": False,
         "consumers": ["Zcode GLM app"]}]}


def validate_targets(root, config):
    require(isinstance(config, dict) and config.get("schema") == SCHEMA
            and isinstance(config.get("targets"), list), "Invalid targets.json schema")
    ids, paths = set(), []
    for target in config["targets"]:
        require(isinstance(target, dict) and isinstance(target.get("id"), str)
                and NAME.fullmatch(target["id"]) and target["id"] not in ids,
                "Invalid/duplicate target id")
        ids.add(target["id"])
        require(type(target.get("enabled")) is bool and isinstance(target.get("path"), str)
                and isinstance(target.get("consumers"), list)
                and all(isinstance(c, str) for c in target["consumers"]), "Invalid target fields")
        path = location(target["path"])
        require(path != root and not within(path, root) and not within(root, path),
                f"Collection/target overlap: {path}")
        require(not path.exists() or path.is_dir(), f"Target is not a directory: {path}")
        for other in paths:
            require(not within(path, other) and not within(other, path), f"Nested target roots: {path}")
        paths.append(path)
    return config


def validate_state(root, state):
    require(isinstance(state, dict) and state.get("schema") == SCHEMA
            and state.get("root") == str(root), "Invalid metadata schema/root; do not prune links")
    require(re.fullmatch(r"[a-f0-9]{32}", state.get("collection", "")) is not None,
            "Invalid collection identity")
    require(all(isinstance(state.get(k), dict) for k in ("skills", "links")), "Invalid metadata records")
    for name, record in state["skills"].items():
        safe_name(name)
        require(isinstance(record, dict) and isinstance(record.get("digest"), str)
                and re.fullmatch(r"[a-f0-9]{64}", record["digest"])
                and isinstance(record.get("prerequisites", []), list)
                and all(isinstance(p, str) for p in record.get("prerequisites", [])), "Invalid skill receipt")
    for key, record in state["links"].items():
        require(isinstance(record, dict), "Invalid owned-link receipt")
        name = safe_name(record.get("name"))
        target = location(record.get("root", ""))
        require(key == str(target / name) and record.get("text") == str(root / name)
                and record.get("collection") == state["collection"], "Invalid owned-link identity")
        require(not within(target, root) and not within(root, target) and target != root,
                "Owned target overlaps collection")
    return state


def load(root, pending=False):
    require(root.is_dir(), f"Collection missing: {root}; run intake.py init")
    require(pending or not (root / PENDING).exists(), "Interrupted operation: run intake.py recover --apply")
    state = validate_state(root, read_json(root / STATE))
    config = validate_targets(root, read_json(root / "targets.json"))
    for name in ("intake.py", "sync.py"):
        link = root / name
        require(link.is_symlink() and os.readlink(link) == f"deploy-skills/scripts/{name}"
                and link.is_file(), f"Manager entry missing or changed: {link}; preserve state and inspect recovery")
    return state, config


def inventory(root, state, allow_missing=()):
    found = {}
    for path in sorted(root.iterdir()):
        if path.name.startswith(".") or path.name == "backups":
            continue
        if path.is_dir() or path.is_symlink() and path.name not in ("intake.py", "sync.py"):
            require(not path.is_symlink(), f"Collection payload must be a real folder: {path}")
            info = skill_info(path)
            require(info["name"].casefold() not in {n.casefold() for n in found}, "Case-fold skill collision")
            found[info["name"]] = {**info, "digest": digest(path)}
    missing = set(state["skills"]) - set(found) - set(allow_missing)
    require(not missing, f"Unexplained missing skills: {sorted(missing)}; explicitly remove to acknowledge")
    return found


@contextlib.contextmanager
def locked(root):
    try:
        import fcntl
    except ImportError as exc:
        raise DeployError("This build requires POSIX advisory locks; Windows support is unverified") from exc
    location(root)
    lock = root / ".deploy-skills.lock"
    fd = os.open(lock, os.O_RDWR | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        require(stat.S_ISREG(os.fstat(fd).st_mode), "Lock must be a regular file")
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise DeployError("Collection busy: another intake/sync operation holds the OS lock") from exc
        os.ftruncate(fd, 0)
        os.write(fd, f"pid={os.getpid()} started={utc()}\n".encode())
        yield
    finally:
        os.close(fd)


def archive(root, folder):
    before = snapshot(folder)
    destination = root / "backups"
    location(destination)
    destination.mkdir(exist_ok=True)
    stem = f"{folder.name}-{utc()[:10]}"
    index = 1
    while True:
        path = destination / f"{stem}{'' if index == 1 else '-' + str(index).zfill(2)}.zip"
        try:
            stream = path.open("xb")
            break
        except FileExistsError:
            index += 1
    try:
        with stream, zipfile.ZipFile(stream, "w", zipfile.ZIP_DEFLATED) as output:
            for rel, entry in before.items():
                kind = entry["kind"]
                member = zipfile.ZipInfo(f"{folder.name}/{rel}" + ("/" if kind == "dir" and rel else ""))
                member.create_system = 3
                typ = {"link": stat.S_IFLNK, "file": stat.S_IFREG, "dir": stat.S_IFDIR}[kind]
                member.external_attr = (typ | entry["mode"]) << 16
                data = entry["text"].encode() if kind == "link" else regular_bytes(folder / rel) if kind == "file" else b""
                output.writestr(member, data)
        with zipfile.ZipFile(path) as check:
            require(check.testzip() is None and len(check.infolist()) == len(before), "ZIP verification failed")
            for rel, entry in before.items():
                member = check.getinfo(f"{folder.name}/{rel}" + ("/" if entry["kind"] == "dir" and rel else ""))
                data = check.read(member)
                require(stat.S_IMODE(member.external_attr >> 16) == entry["mode"], "ZIP permission mismatch")
                if entry["kind"] == "file":
                    require(hashlib.sha256(data).hexdigest() == entry["sha256"], "ZIP byte mismatch")
                elif entry["kind"] == "link":
                    require(data.decode() == entry["text"], "ZIP link mismatch")
        require(snapshot(folder) == before, f"Skill changed during backup: {folder}")
        return str(path.relative_to(root))
    except Exception:
        # Incomplete archives are preserved for diagnosis, never reported as a backup.
        raise


def link_text(path):
    if path.is_symlink():
        return os.readlink(path)
    require(not path.exists(), f"Foreign real entry preserved: {path}")
    return None


def render_catalog(root, state, config):
    lines = ["# Deployed Skills", "", "Generated by deploy-skills; folders are the desired collection.", "",
             "| Skill | Description | Source / revision | Updated (UTC) | Digest | Targets |",
             "|---|---|---|---|---|---|"]
    def esc(value):
        return str(value).replace("|", "\\|").replace("\n", " ")
    found = inventory(root, state)
    for name, info in found.items():
        receipt = state["skills"].get(name, {})
        statuses = []
        for target in config["targets"]:
            if target["enabled"]:
                path = location(target["path"]) / name
                good = path.is_symlink() and os.readlink(path) == str(root / name)
                statuses.append(f"{target['id']}: {'linked' if good else 'not linked'}")
        lines.append(f"| [{name}]({name}/SKILL.md) | {esc(info['description'])} | "
                     f"{esc(receipt.get('source', 'manual/unadopted'))} @ {receipt.get('commit', 'unknown')} | "
                     f"{receipt.get('updated', 'unknown')} | {info['digest']} | {esc('; '.join(statuses))} |")
    lines.extend(["", "## Runtime prerequisites", ""])
    for name, receipt in state["skills"].items():
        for prerequisite in receipt.get("prerequisites", []):
            lines.append(f"- {name}: {esc(prerequisite)}")
    return "\n".join(lines) + "\n"


def history(root, event):
    path = root / "changelog.md"
    old = regular_bytes(path).decode() if path.exists() else "# Deployment Changelog\n\n"
    require(old.startswith("# Deployment Changelog\n") and old.endswith("\n"), "Corrupt changelog header/tail")
    # Whole records have an end marker; interrupted writes are avoided by atomic replacement.
    records = old.split("\n## ")[1:]
    require(all(r.rstrip().endswith("<!-- end -->") for r in records), "Corrupt changelog record; recover before mutation")
    marker = f"<!-- operation:{event['id']} -->"
    if marker in old:
        return
    block = f"\n## {event['time']} — {event['kind']}\n{marker}\n\n"
    block += "```json\n" + json.dumps(event["details"], indent=2, sort_keys=True) + "\n```\n<!-- end -->\n"
    atomic_bytes(path, (old + block).encode())


def action_apply(root, action):
    kind = action["kind"]
    if kind == "payload":
        name = safe_name(action["name"])
        dest = root / name
        stage = root / ".staging" / action["op"]
        require(re.fullmatch(r"[a-f0-9]{32}", action["op"]) is not None, "Invalid stage receipt")
        location(stage)
        new, old = stage / "new", stage / "old"
        expected = action["after"]
        current = digest(dest) if dest.exists() else None
        require(not dest.is_symlink(), f"Payload replaced externally: {dest}")
        if current == expected:
            return
        require(current == action["before"] or current is None and old.exists(), f"Payload pre-state changed: {dest}")
        if old.exists():
            require(digest(old) == action["before"], "Prior staged payload changed")
        if expected is not None:
            require(digest(new) == expected, "Staged payload digest mismatch")
        if dest.exists():
            require(not old.exists(), "Existing prior payload staging; inspect recovery")
            dest.rename(old)
        if expected is not None:
            new.rename(dest)
    elif kind == "link":
        parent = location(action["root"])
        name = safe_name(action["name"]) if action["name"] not in ("intake.py", "sync.py") else action["name"]
        require(parent == root or not within(parent, root) and not within(root, parent), "Invalid link root")
        parent.mkdir(parents=True, exist_ok=True)
        path = parent / name
        current = link_text(path)
        if current == action["after"]:
            return
        require(current == action["before"], f"Link pre-state changed; preserving: {path}")
        # One atomic replacement: a crash cannot leave a migrated link unlinked.
        # A pinned directory fd also keeps leaf writes out of a redirected parent.
        fd = os.open(parent, os.O_RDONLY | os.O_DIRECTORY | getattr(os, "O_NOFOLLOW", 0))
        temporary = ".deploy-skills-link-" + uuid.uuid4().hex
        try:
            location(parent)
            require(os.fstat(fd).st_ino == parent.stat().st_ino, "Target root changed")
            require(link_text(path) == current, "Link changed at mutation boundary")
            if action["after"] is None:
                os.unlink(name, dir_fd=fd)
            elif current is None:
                os.symlink(action["after"], name, dir_fd=fd)
            else:
                os.symlink(action["after"], temporary, dir_fd=fd)
                os.replace(temporary, name, src_dir_fd=fd, dst_dir_fd=fd)
            os.fsync(fd)
        finally:
            try:
                os.unlink(temporary, dir_fd=fd)
            except FileNotFoundError:
                pass
            os.close(fd)
    elif kind == "retire-directory":
        parent = location(action["root"])
        path = parent / "skills-sync-trinity"
        stage = location(root / ".staging" / action["op"])
        old = stage / "retired"
        if not path.exists() and not path.is_symlink():
            require(digest(old) == action["before"], "Missing retired directory and backup staging")
            return
        require(digest(path) == action["before"], "Legacy directory changed; preserved")
        require(not old.exists(), "Legacy staging occupied")
        path.rename(old)
    else:
        raise DeployError(f"Unknown operation: {kind}")


def receipt_digest(receipt):
    return hashlib.sha256(json.dumps({k: v for k, v in receipt.items() if k != "checksum"},
                                    sort_keys=True).encode()).hexdigest()


def validate_receipt(root, receipt):
    require(receipt.get("schema") == SCHEMA and receipt.get("root") == str(root), "Invalid recovery receipt")
    require(receipt.get("checksum") == receipt_digest(receipt), "Corrupt recovery receipt checksum; inspect before mutation")
    validate_state(root, receipt["state"])
    validate_targets(root, receipt["targets"])
    require(isinstance(receipt.get("actions"), list), "Invalid recovery actions")
    for action in receipt["actions"]:
        kind = action.get("kind")
        if kind in ("payload", "retire-directory"):
            require(re.fullmatch(r"[a-f0-9]{32}", action.get("op", "")), "Invalid staged operation")
            name = safe_name(action["name"])
            require(kind != "retire-directory" or name == "skills-sync-trinity", "Invalid retirement")
            for key in ("before", "after"):
                value = action.get(key)
                require(value is None or isinstance(value, str) and re.fullmatch(r"[a-f0-9]{64}", value),
                        "Invalid payload digest")
        elif kind == "link":
            parent = location(action["root"])
            name = action["name"]
            if parent == root:
                require(name in ("intake.py", "sync.py") and action["before"] is None
                        and action["after"] == f"deploy-skills/scripts/{name}", "Invalid manager entry")
            else:
                safe_name(name)
                require(not within(parent, root) and not within(root, parent), "Link root overlaps collection")
                require(action["after"] in (None, str(root / name)), "Unexpected link destination")
            require(action["before"] is None or isinstance(action["before"], str), "Invalid link pre-state")
        else:
            raise DeployError("Invalid recovery action kind")
    return receipt


def finish(root, receipt):
    validate_receipt(root, receipt)
    validate_history(root)
    for action in receipt["actions"]:
        action_apply(root, action)
    atomic_json(root / STATE, receipt["state"])
    atomic_json(root / "targets.json", receipt["targets"])
    atomic_bytes(root / "catalog.md", render_catalog(root, receipt["state"], receipt["targets"]).encode())
    history(root, receipt["event"])
    (root / PENDING).unlink()
    # Staging is retained (not silently recursively deleted); ZIPs are the user-facing backups.


def transact(root, state, config, actions, kind, details):
    receipt = {"schema": SCHEMA, "root": str(root), "state": state, "targets": config,
               "actions": actions, "event": {"id": uuid.uuid4().hex, "time": utc(), "kind": kind, "details": details}}
    receipt["checksum"] = receipt_digest(receipt)
    validate_receipt(root, receipt)
    validate_history(root)
    require(not (root / PENDING).exists(), "Pending operation exists; recover it first")
    atomic_json(root / PENDING, receipt)
    finish(root, receipt)


def validate_history(root):
    # Validate history before side effects, not only when appending at the end.
    require(not (root / "changelog.md").is_symlink(), "Changelog symlink refused")
    if (root / "changelog.md").exists():
        text = regular_bytes(root / "changelog.md").decode()
        require(text.startswith("# Deployment Changelog\n") and text.endswith("\n")
                and all(r.rstrip().endswith("<!-- end -->") for r in text.split("\n## ")[1:]),
                "Corrupt changelog; inspect before mutation")


def stage_payload(root, source, before, after):
    op = uuid.uuid4().hex
    stage = root / ".staging" / op
    location(stage)
    stage.mkdir(parents=True)
    if source is not None:
        shutil.copytree(source, stage / "new", symlinks=True)
        require(digest(stage / "new") == after and digest(source) == after, "Source changed during staging")
    return {"kind": "payload", "name": source.name if source else "", "op": op, "before": before, "after": after}


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", default=str(Path.home() / "Documents" / "Deployed Skills"))
    p.add_argument("--apply", action="store_true", help="Apply the requested mutation; default is preview")
    p.add_argument("--dry-run", action="store_true", help="Write nothing")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("init")
    add = sub.add_parser("add"); add.add_argument("source")
    update = sub.add_parser("update"); update.add_argument("name"); update.add_argument("--source")
    remove = sub.add_parser("remove"); remove.add_argument("name"); remove.add_argument("--allow-empty", action="store_true")
    for verb in ("list", "catalog", "recover"):
        sub.add_parser(verb)
    target = sub.add_parser("targets")
    target.add_argument("--id"); target.add_argument("--path")
    target.add_argument("--consumer", action="append", default=[])
    target.add_argument("--disable", action="store_true"); target.add_argument("--remove", action="store_true")
    note = sub.add_parser("prerequisite"); note.add_argument("name"); note.add_argument("text")
    return p


def main(argv=None):
    args = parser().parse_args(argv)
    try:
        root = location(args.root)
        apply = args.apply and not args.dry_run
        if args.command == "init":
            source = Path(__file__).resolve().parent.parent
            info = skill_info(source)
            require((source / "scripts" / "sync.py").is_file(), "Manager is incomplete: missing scripts/sync.py")
            initial_digest = digest(source)
            require(not within(root, source) and not within(source, root) and root != source, "Source/collection overlap")
            if (root / STATE).exists():
                load(root)
                print("Collection already initialized")
                return 0
            require(not root.exists() or not any(root.iterdir()), f"Init requires empty folder: {root}")
            print(json.dumps({"operation": "init", "root": str(root), "manager": str(source), "apply": apply}))
            if not apply:
                return 0
            root.mkdir(parents=True, exist_ok=True)
            with locked(root):
                require(set(p.name for p in root.iterdir()) <= {".deploy-skills.lock"},
                        "Collection changed during init; inspect or recover")
                state = {"schema": SCHEMA, "root": str(root), "collection": uuid.uuid4().hex,
                         "skills": {"deploy-skills": {**info, "source": str(source), "digest": initial_digest,
                                                      "updated": utc(), "prerequisites": []}}, "links": {}}
                action = stage_payload(root, source, None, initial_digest)
                links = [{"kind": "link", "root": str(root), "name": f"{n}.py", "before": None,
                          "after": f"deploy-skills/scripts/{n}.py"} for n in ("intake", "sync")]
                transact(root, state, defaults(), [action, *links], "init", {"manager_digest": initial_digest})
            return 0
        if args.command == "recover":
            receipt = validate_receipt(root, read_json(root / PENDING))
            print(json.dumps({"operation": "recover", "event": receipt.get("event"), "apply": apply}))
            if apply:
                with locked(root):
                    finish(root, read_json(root / PENDING))
            return 0
        state, config = load(root)
        if args.command == "list":
            print(json.dumps({"skills": inventory(root, state), "receipts": state["skills"], "targets": config}, indent=2))
            return 0
        if args.command == "targets" and not args.id:
            print(json.dumps(config, indent=2)); return 0
        # Preview follows exactly the same validation path but never takes a write lock.
        with locked(root) if apply else contextlib.nullcontext():
            state, config = load(root)
            validate_history(root)
            found = inventory(root, state, [args.name] if args.command == "remove" else [])
            details, actions = {}, []
            if args.command in ("add", "update"):
                raw = args.source if args.command == "add" else args.source or state["skills"].get(args.name, {}).get("source")
                require(raw, "No source receipt; provide --source")
                source, record = source_record(raw)
                name = record["name"]
                if args.command == "update":
                    require(name == safe_name(args.name) and name in found, "Update name/source mismatch or absent skill")
                require(not within(source, root) and not within(root, source) and source != root, "Source/collection overlap")
                require(name not in found or args.command == "update", f"Skill already exists: {name}; use update")
                before = found.get(name, {}).get("digest")
                if before == record["digest"]:
                    print(f"Unchanged: {name}"); return 0
                details = {"name": name, "source": str(source), "before": before, "after": record["digest"], "commit": record["commit"]}
                if apply:
                    if before:
                        details["backup"] = archive(root, root / name)
                    actions.append(stage_payload(root, source, before, record["digest"]))
                record["prerequisites"] = state["skills"].get(name, {}).get("prerequisites", [])
                state["skills"][name] = record
            elif args.command == "remove":
                name = safe_name(args.name)
                require(name != "deploy-skills", "Disable targets and sync before retiring the manager; keep its recovery tools available")
                require(name in state["skills"] or name in found, f"Unknown skill: {name}")
                require(len(found.keys() - {name}) or args.allow_empty, "Removing final skill requires --allow-empty")
                details = {"name": name, "before": found.get(name, {}).get("digest"), "links": "run sync apply to withdraw owned links"}
                if name in found and apply:
                    details["backup"] = archive(root, root / name)
                    action = stage_payload(root, None, details["before"], None); action["name"] = name
                    actions.append(action)
                state["skills"].pop(name, None)
            elif args.command == "targets":
                require(NAME.fullmatch(args.id), "Invalid target id")
                previous = next((t for t in config["targets"] if t["id"] == args.id), None)
                config["targets"] = [t for t in config["targets"] if t["id"] != args.id]
                if not args.remove:
                    require(args.path or previous, "New target needs --path")
                    config["targets"].append({"id": args.id, "path": args.path or previous["path"],
                                              "consumers": args.consumer or (previous or {}).get("consumers", []),
                                              "enabled": not args.disable})
                validate_targets(root, config)
                details = {"targets": config["targets"]}
            elif args.command == "prerequisite":
                name = safe_name(args.name)
                require(name in state["skills"], "Skill must be adopted first")
                if args.text in state["skills"][name].get("prerequisites", []):
                    print("Prerequisite already recorded"); return 0
                state["skills"][name].setdefault("prerequisites", []).append(args.text)
                details = {"name": name, "prerequisite": args.text}
            elif args.command == "catalog":
                for name, info in found.items():
                    state["skills"].setdefault(name, {**info, "updated": utc(), "prerequisites": []})
                details = {"skills": sorted(found)}
            print(json.dumps({"operation": args.command, "apply": apply, **details}, indent=2))
            if apply:
                transact(root, state, config, actions, args.command, details)
        return 0
    except (DeployError, OSError, ValueError, KeyError, TypeError, RuntimeError) as exc:
        print(f"deploy-skills: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
