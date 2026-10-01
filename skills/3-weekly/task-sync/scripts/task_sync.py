#!/usr/bin/env python3
"""task_sync — unified IDE task-list grooming (GH-896).

One CLI over per-IDE adapters (zcode, agy). Default is dry-run; pass
``--apply`` to commit. Emits one merged JSON report; per-IDE sections
stay machine-addressable (the heartbeat consumes ``needs_summary``).

    task_sync.py --doctor
    task_sync.py                       # dry-run, both IDEs
    task_sync.py --apply               # the heartbeat invocation
    task_sync.py --set-title <id> "Short description of last action"
    task_sync.py --zcode-db /tmp/copy.sqlite --agy-root /tmp/agy-fixture ...

Safety contract (core-enforced, GH-896): schema-validate before write
with a clear abort; dry-run by default; write only on change; a failed
or empty-authoritative read never triggers a destructive write;
Antigravity writes are gated on the app being closed; the Electron store
is backed up and replaced atomically. One IDE's store failure never
blocks the other — each section reports its own error.
"""

from __future__ import annotations

import argparse
import importlib
import json
import os
import sys
import sqlite3
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import core  # noqa: E402

ADAPTERS = ("zcode", "agy")

SWEEP_KNOBS = ("hours", "all", "pin_hours", "no_pin", "unpin_days", "include_cron", "group")


def _build_adapter(name: str, args, apply: bool):
    module_name = "antigravity" if name == "agy" else name
    module = importlib.import_module(f"adapters.{module_name}")
    if name == "zcode":
        return module.ZcodeAdapter(db_path=args.zcode_db, apply=apply)
    if name == "agy":
        return module.AntigravityAdapter(
            agy_root=args.agy_root,
            apply=apply,
        )
    raise SystemExit(f"task-sync: unknown adapter {name!r}")


def _sweep_kwargs(args) -> dict:
    return {
        "hours": args.hours,
        "include_all": args.all,
        "pin": args.pin,
        "pin_hours": args.pin_hours,
        "unpin_days": args.unpin_days,
        "include_cron": args.include_cron,
        "group": args.group,
    }


def run_doctor(args) -> tuple[dict, int]:
    ides = {}
    red = 0
    receipt = core.receipt_path()
    receipt_state = "absent"
    receipt_red = None
    if os.path.exists(receipt):
        try:
            with open(receipt, "r", encoding="utf-8") as f:
                at = json.load(f).get("at", "unreadable")
            receipt_state = at
            if at == "unreadable":
                receipt_red = f"heartbeat receipt unreadable at {receipt}"
            else:
                age = datetime.now() - datetime.fromisoformat(at)
                if age > timedelta(hours=2):
                    receipt_red = (
                        f"heartbeat receipt stale: last apply {at} "
                        f"({age.total_seconds() / 3600:.1f}h ago) — heartbeat may be dead"
                    )
        except (OSError, ValueError):
            receipt_state = "unreadable"
            receipt_red = f"heartbeat receipt unreadable at {receipt}"
    for name in args.ide:
        adapter = _build_adapter(name, args, apply=False)
        try:
            ides[name] = adapter.doctor()
        except (core.AdapterError, OSError, sqlite3.Error) as exc:
            ides[name] = {"ok": False, "reds": [str(exc)]}
        if not ides[name].get("ok"):
            red = 1
    report = {
        "mode": "doctor",
        "heartbeat": {
            "receipt": receipt,
            "state": receipt_state,
            "note": "pending — no receipt yet" if receipt_state == "absent" else receipt_state,
        },
        "ides": ides,
    }
    if receipt_red:
        report["heartbeat"]["red"] = receipt_red
        red = 1
    return report, red


def run_sweep(args, apply: bool) -> tuple[dict, int]:
    ides = {}
    red = 0
    for name in args.ide:
        adapter = _build_adapter(name, args, apply=apply)
        try:
            ides[name] = adapter.sweep(**_sweep_kwargs(args))
        except (core.AdapterError, OSError, sqlite3.Error) as exc:
            ides[name] = core.new_ide_report()
            ides[name]["error"] = str(exc)
            red = 1
    report = core.merge_report("apply" if apply else "dry-run", ides)
    if apply and any(rep.get("error") is None for rep in ides.values()):
        report["receipt"] = core.write_receipt(report["mode"], ides)
    return report, red


def run_set_title(args) -> tuple[dict, int]:
    task_id, description = args.set_title
    ides = {}
    red = 0
    apply = args.apply
    for name in args.ide:
        adapter = _build_adapter(name, args, apply=apply)
        try:
            if name == "agy":
                ides[name] = adapter.set_title(task_id, description, auto_pin=args.auto_pin)
            else:
                ides[name] = adapter.set_title(task_id, description)
        except (core.AdapterError, OSError, sqlite3.Error) as exc:
            ides[name] = {"task_id": task_id, "found": False, "renamed": [], "error": str(exc)}
            red = 1
    report = core.merge_report("apply" if apply else "dry-run", ides)
    return report, red


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Unified IDE task-list grooming (zcode, agy). Dry-run by default."
    )
    parser.add_argument("--ide", default="zcode,agy",
                        help="comma-separated adapters to run (default: zcode,agy)")
    parser.add_argument("--apply", action="store_true",
                        help="commit writes (default is dry-run)")
    parser.add_argument("--doctor", action="store_true",
                        help="health check: store reachability, schema, app gate, heartbeat receipt")
    parser.add_argument("--set-title", nargs=2, metavar=("TASK_ID", "TITLE"),
                        help="set one task's title per selected IDE; stamps it with the "
                             "task's own last-activity mm-dd date (a supplied stamp is normalized)")
    parser.add_argument("--zcode-db", metavar="PATH", default=None,
                        help="override the ZCode task index DB (probes use copies)")
    parser.add_argument("--agy-root", metavar="PATH", default=None,
                        help="override the Antigravity root dir; its electron store is "
                             "<root>/app_storage.json (probes use fixture roots)")
    parser.add_argument("--hours", type=float, default=24.0,
                        help="sweep window in hours of last activity (default 24)")
    parser.add_argument("--all", action="store_true",
                        help="sweep everything recent rather than the default candidate set")
    parser.add_argument("--pin", dest="pin", action="store_true", default=True,
                        help="ZCode: pin tasks active within --pin-hours (default)")
    parser.add_argument("--no-pin", dest="pin", action="store_false",
                        help="skip pin writes (does not disable --unpin-days)")
    parser.add_argument("--pin-hours", type=float, default=24.0,
                        help="ZCode pin window in hours of last activity (default 24)")
    parser.add_argument("--unpin-days", type=float, default=None, metavar="N",
                        help="ZCode: also unpin tasks inactive for N days (default: never)")
    parser.add_argument("--include-cron", action="store_true",
                        help="ZCode: also touch automation-owned tasks (default: skip)")
    parser.add_argument("--group", metavar="NAME", default=None,
                        help="ZCode: add pinned-window tasks to this named task group")
    parser.add_argument("--auto-pin", action="store_true",
                        help="Agy: opt into derived pin writes including app_storage.json "
                             "for --set-title targets (gated, backed up, atomic)")
    args = parser.parse_args(argv)

    args.ide = [s.strip() for s in args.ide.split(",") if s.strip()]
    unknown = [s for s in args.ide if s not in ADAPTERS]
    if unknown:
        parser.error(f"unknown --ide value(s): {unknown} (choose from {list(ADAPTERS)})")
    if not args.ide:
        parser.error("--ide resolved to an empty list")
    if args.group and args.set_title:
        parser.error("--group applies to sweeps only; not valid with --set-title")

    if args.doctor:
        report, red = run_doctor(args)
    elif args.set_title:
        report, red = run_set_title(args)
    else:
        report, red = run_sweep(args, apply=args.apply)

    json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 3 if red else 0


if __name__ == "__main__":
    sys.exit(main())
