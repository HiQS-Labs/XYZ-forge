#!/usr/bin/env python3
"""Preview/reconcile owned directory symlinks from a local Deployed Skills collection."""
from __future__ import annotations

import argparse
import contextlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import uuid

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import intake as shared


def owned_record(root, state, target, name, previous=None):
    return {"collection": state["collection"], "root": str(target), "name": name,
            "text": str(root / name), **({"previous": previous} if previous is not None else {})}


# GH-660 remediation item 3: the collection is a distribution artifact of XYZ-forge's
# canonical skills/. A deploy that ships a vendored SKILL.md diverging from canonical is
# silent drift, so sync runs the forge-side checker (utils/py/skill_drift_check.py) and
# refuses --apply while any forge-owned skill is drifted. Only names present in the forge's
# skills/ are judged; collection-only skills stay informational ("unrecognized").
CHECKER = Path("utils") / "py" / "skill_drift_check.py"


def canonical_root(explicit, config, state):
    """Resolve the XYZ-forge checkout whose skills/ is canonical for this collection.

    Order: --canonical, XYZ_FORGE_ROOT, targets.json "canonical", then the repository the
    manager itself was vendored from. An explicit setting that does not resolve is an error;
    a stale provenance path is skipped. Returns (path, origin) or (None, None)."""
    candidates = [("--canonical", explicit), ("XYZ_FORGE_ROOT", os.environ.get("XYZ_FORGE_ROOT")),
                  ('targets.json "canonical"', config.get("canonical")),
                  ("skills-army-hq provenance", state["skills"].get("skills-army-hq", {}).get("repository"))]
    for origin, raw in candidates:
        if not raw:
            continue
        path = Path(raw).expanduser()
        if (path / CHECKER).is_file() and (path / "skills").is_dir():
            return path.resolve(), origin
        shared.require(origin == "skills-army-hq provenance",
                       f"Canonical root from {origin} lacks {CHECKER} or skills/: {path}")
    return None, None


def drift_report(root, canonical):
    """Ingest the forge checker's --json; exit 0/1 are both reports, anything else is a failure."""
    run = subprocess.run([sys.executable, "-B", str(canonical / CHECKER), "--canonical", str(canonical),
                          "--collection", str(root), "--json"], text=True, capture_output=True)
    shared.require(run.returncode in (0, 1), f"skill_drift_check failed ({run.returncode}): {run.stderr.strip()}")
    report = json.loads(run.stdout)
    return {"canonical": str(canonical), "ok": [e["skill"] for e in report["ok"]],
            "drifted": [{"skill": e["skill"], "vendored_path": e["vendored_path"], "canonical_path": e["canonical_path"]}
                        for e in report["drifted"]],
            "unrecognized": [e["skill"] for e in report["unrecognized"]]}


def warn(warnings, message):
    """Loud and immediate (stderr) so a refusal that follows still shows every finding."""
    warnings.append(message)
    print(f"skills-army-hq sync: WARN {message}", file=sys.stderr)


def drift_gate(root, state, config, found, explicit, apply, allow_drift, warnings):
    """WARN on every drifted forge-owned skill; REFUSE an apply that would deploy one."""
    canonical, origin = canonical_root(explicit, config, state)
    if canonical is None:
        warn(warnings, "drift check skipped: no canonical XYZ-forge root resolved "
                       "(set --canonical, XYZ_FORGE_ROOT, or targets.json \"canonical\")")
        return None
    drift = {**drift_report(root, canonical), "origin": origin}
    drifted = [e for e in drift["drifted"] if e["skill"] in found]
    for entry in drifted:
        remedy = (f"python3 {shlex.quote(str(root / 'intake.py'))} --root {shlex.quote(str(root))} --apply "
                  f"update {entry['skill']} --source {shlex.quote(str(Path(entry['canonical_path']).parent))}")
        warn(warnings, f"DRIFTED {entry['skill']}: vendored {entry['vendored_path']} != canonical "
                       f"{entry['canonical_path']} — re-vendor: {remedy}")
    deploying = any(t["enabled"] for t in config["targets"])
    if apply and drifted and deploying and not allow_drift:
        names = ", ".join(e["skill"] for e in drifted)
        shared.require(False, f"REFUSED: deploy would ship drifted vendored SKILL.md for {names}; "
                              f"canonical is {canonical / 'skills'} — re-vendor from it (or --allow-drift, loudly)")
    if apply and drifted and allow_drift:
        warn(warnings, f"--allow-drift: deploying {len(drifted)} drifted skill(s) against canonical {canonical}")
    return drift


def reconcile(root, state, config, found, adopt=(), migrate=(), migrate_from=None):
    """Plan only; unexpected entries are errors, not implicit ownership grants."""
    targets = sorted({shared.location(t["path"]) for t in config["targets"] if t["enabled"]})
    desired = {str(target / name): (target, name) for target in targets for name in found}
    actions, errors, changes = [], [], []
    migrate_from = migrate_from or {}
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
                    shared.require(name in migrate or name in migrate_from,
                                   f"Foreign link preserved; review before explicit migration: {path}")
                    source = migrate_from.get(name) or state["skills"].get(name, {}).get("source")
                    shared.require(source and path.resolve(strict=True) == Path(source).resolve(strict=True),
                                   f"Migration must match the explicitly selected local source: {path}")
                    if name not in migrate_from:
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
    source, source_receipt, _ = shared.source_record(source_arg)
    shared.require(source_receipt["name"] == "skills-sync-trinity", "Expected retired skills-sync-trinity source")
    actions, errors, changes = [], [], []
    for parent in sorted({shared.location(t["path"]) for t in config["targets"] if t["enabled"]}):
        path = parent / "skills-sync-trinity"
        if not path.exists() and not path.is_symlink():
            continue
        try:
            shared.require(shared.link_text(parent / "skills-army-hq") == str(root / "skills-army-hq")
                           and (parent / "skills-army-hq" / "scripts" / "sync.py").is_file(),
                           f"Install and verify skills-army-hq first: {parent}")
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
    p.add_argument("--root", default=shared.default_root(),
                   help="Collection root (env: XYZ_SKILLS_ROOT)")
    p.add_argument("--apply", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--status", action="store_true", help="Read-only reconciliation report")
    p.add_argument("--adopt", action="append", default=[], metavar="SKILL")
    p.add_argument("--migrate", action="append", default=[], metavar="SKILL")
    p.add_argument("--migrate-from", action="append", default=[], metavar="SKILL=LOCAL_SOURCE",
                   help="Explicitly replace a selected alternative source link; preserve old link text")
    p.add_argument("--retire-trinity", metavar="LOCAL_SOURCE", help="Withdraw only the known replaced skill")
    p.add_argument("--archive-legacy", action="store_true", help="Explicitly archive a matching real legacy folder")
    p.add_argument("--canonical", metavar="FORGE_ROOT",
                   help="XYZ-forge checkout whose skills/ is canonical (else XYZ_FORGE_ROOT, targets.json \"canonical\")")
    p.add_argument("--allow-drift", action="store_true",
                   help="Deploy despite drifted vendored skills; the drift is still reported and recorded")
    args = p.parse_args(argv)
    try:
        root = shared.location(args.root)
        apply = args.apply and not args.dry_run and not args.status
        for name in args.adopt + args.migrate:
            shared.safe_name(name)
        migrate_from = {}
        for selection in args.migrate_from:
            name, separator, raw = selection.partition("=")
            shared.require(separator and raw, "--migrate-from requires SKILL=LOCAL_SOURCE")
            shared.safe_name(name)
            source = Path(raw).expanduser().resolve(strict=True)
            shared.require(name not in migrate_from and shared.skill_info(source)["name"] == name,
                           "Duplicate or mismatched alternative source")
            # The prior instructions may differ from the new copy. Only inspect its
            # identity here: explicit selection retires a link, never copies its payload.
            run = shared.subprocess.run(["git", "--no-optional-locks", "-C", str(source),
                                         "rev-parse", "--show-toplevel"], text=True, capture_output=True)
            shared.require(run.returncode == 0 and shared.within(source, Path(run.stdout.strip()).resolve()),
                           "Alternative source must be a skill folder inside a local Git repo")
            migrate_from[name] = str(source)
        shared.load(root)
        with shared.locked(root) if apply else contextlib.nullcontext():
            state, config = shared.load(root)
            shared.validate_history(root)
            found = shared.inventory(root, state)
            warnings, drift = [], None
            if args.retire_trinity:
                actions, errors, changes = retirement(root, state, config, args.retire_trinity,
                                                     args.archive_legacy, apply)
            else:
                shared.require(not args.archive_legacy, "--archive-legacy requires --retire-trinity")
                drift = drift_gate(root, state, config, found, args.canonical, apply, args.allow_drift, warnings)
                actions, errors, changes = reconcile(root, state, config, found, args.adopt, args.migrate, migrate_from)
            result = {"apply": apply, "skills": sorted(found), "actions": actions, "changes": changes,
                      "errors": errors, "warnings": warnings, "drift": drift,
                      "prerequisites": {n: r.get("prerequisites", []) for n, r in state["skills"].items()}}
            print(json.dumps(result, indent=2))
            if apply and (actions or changes or errors):
                shared.transact(root, state, config, actions, "sync-partial" if errors else "sync", result)
            return 2 if errors else 0
    except (shared.DeployError, OSError, ValueError, KeyError, TypeError, RuntimeError) as exc:
        print(f"skills-army-hq sync: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
