#!/usr/bin/env python3
"""Preview/reconcile owned directory symlinks from a local Deployed Skills collection."""
from __future__ import annotations

import argparse
import contextlib
import json
import os
from pathlib import Path
import sys
import uuid

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import intake as shared


def owned_record(root, state, target, name, previous=None):
    return {"collection": state["collection"], "root": str(target), "name": name,
            "text": str(root / name), **({"previous": previous} if previous is not None else {})}


def reconcile(root, state, config, found, adopt=(), migrate=()):
    """Plan only; unexpected entries are errors, not implicit ownership grants."""
    targets = sorted({shared.location(t["path"]) for t in config["targets"] if t["enabled"]})
    desired = {str(target / name): (target, name) for target in targets for name in found}
    actions, errors, changes = [], [], []
    for key in sorted(set(desired) | set(state["links"])):
        receipt = state["links"].get(key)
        parent, name = desired.get(key, (Path(receipt["root"]), receipt["name"])) if receipt else desired[key]
        path = parent / name
        wanted = str(root / name) if key in desired else None
        try:
            shared.location(parent)
            current = shared.link_text(path)
            if receipt:
                shared.require(current in (None, receipt["text"]), f"Lost ownership; retargeted link preserved: {path}")
            elif current is not None:
                if current == wanted:
                    shared.require(name in adopt, f"Correct but unowned link; explicitly --adopt {name}: {path}")
                    changes.append({"adopt": key})
                else:
                    shared.require(name in migrate, f"Foreign link preserved; review before --migrate {name}: {path}")
                    source = state["skills"].get(name, {}).get("source")
                    shared.require(source and path.resolve(strict=True) == Path(source).resolve(strict=True),
                                   f"Migration must match the recorded local source: {path}")
                    shared.require(shared.digest(path.resolve()) == found[name]["digest"],
                                   f"Migration source differs from copied payload: {path}")
                    changes.append({"migrate": key, "previous": current})
            if current != wanted:
                actions.append({"kind": "link", "root": str(parent), "name": name,
                                "before": current, "after": wanted})
            if wanted is None:
                if receipt:
                    del state["links"][key]
                    if current is None:
                        changes.append({"withdraw_missing": key})
            else:
                state["links"][key] = receipt or owned_record(root, state, parent, name, current)
        except (shared.DeployError, OSError, RuntimeError) as exc:
            errors.append({"path": key, "error": str(exc)})
    return actions, errors, changes


def retirement(root, state, config, source_arg, archive_directories, apply):
    """Explicit old-name migration only, not a generic foreign-entry deletion switch."""
    source, source_receipt = shared.source_record(source_arg)
    shared.require(source_receipt["name"] == "skills-sync-trinity", "Expected retired skills-sync-trinity source")
    actions, errors, changes = [], [], []
    for parent in sorted({shared.location(t["path"]) for t in config["targets"] if t["enabled"]}):
        path = parent / "skills-sync-trinity"
        if not path.exists() and not path.is_symlink():
            continue
        try:
            shared.require(shared.link_text(parent / "deploy-skills") == str(root / "deploy-skills")
                           and (parent / "deploy-skills" / "scripts" / "sync.py").is_file(),
                           f"Install and verify deploy-skills first: {parent}")
            if path.is_symlink():
                before = os.readlink(path)
                shared.require(path.resolve(strict=False) == source, f"Unrelated legacy link preserved: {path}")
                actions.append({"kind": "link", "root": str(parent), "name": path.name,
                                "before": before, "after": None})
                changes.append({"retired": str(path), "previous": before})
            else:
                shared.require(archive_directories, f"Real legacy folder preserved; explicitly select --archive-legacy: {path}")
                shared.require(shared.skill_info(path)["name"] == path.name
                               and shared.digest(path) == source_receipt["digest"],
                               f"Legacy directory does not match selected source: {path}")
                change = {"retired": str(path), "digest": source_receipt["digest"]}
                if apply:
                    change["backup"] = shared.archive(root, path)
                    stage = shared.location(root / ".staging" / uuid.uuid4().hex)
                    stage.mkdir(parents=True)
                    shared.require(path.stat().st_dev == stage.stat().st_dev,
                                   "Legacy folder is on a different filesystem; archive retained, folder preserved")
                    actions.append({"kind": "retire-directory", "name": path.name, "root": str(parent),
                                    "op": stage.name, "before": source_receipt["digest"], "after": None})
                changes.append(change)
        except (shared.DeployError, OSError, RuntimeError) as exc:
            errors.append({"path": str(path), "error": str(exc)})
    return actions, errors, changes


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", default=str(Path.home() / "Documents" / "Deployed Skills"))
    p.add_argument("--apply", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--status", action="store_true", help="Read-only reconciliation report")
    p.add_argument("--adopt", action="append", default=[], metavar="SKILL")
    p.add_argument("--migrate", action="append", default=[], metavar="SKILL")
    p.add_argument("--retire-trinity", metavar="LOCAL_SOURCE", help="Withdraw only the known replaced skill")
    p.add_argument("--archive-legacy", action="store_true", help="Explicitly archive a matching real legacy folder")
    args = p.parse_args(argv)
    try:
        root = shared.location(args.root)
        apply = args.apply and not args.dry_run and not args.status
        for name in args.adopt + args.migrate:
            shared.safe_name(name)
        shared.load(root)
        with shared.locked(root) if apply else contextlib.nullcontext():
            state, config = shared.load(root)
            shared.validate_history(root)
            found = shared.inventory(root, state)
            if args.retire_trinity:
                actions, errors, changes = retirement(root, state, config, args.retire_trinity,
                                                     args.archive_legacy, apply)
            else:
                shared.require(not args.archive_legacy, "--archive-legacy requires --retire-trinity")
                actions, errors, changes = reconcile(root, state, config, found, args.adopt, args.migrate)
            result = {"apply": apply, "skills": sorted(found), "actions": actions, "changes": changes,
                      "errors": errors, "prerequisites": {n: r.get("prerequisites", []) for n, r in state["skills"].items()}}
            print(json.dumps(result, indent=2))
            if apply and (actions or changes or errors):
                shared.transact(root, state, config, actions, "sync-partial" if errors else "sync", result)
            return 2 if errors else 0
    except (shared.DeployError, OSError, ValueError, KeyError, TypeError, RuntimeError) as exc:
        print(f"deploy-skills sync: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
