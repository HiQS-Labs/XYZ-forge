from __future__ import annotations

import argparse
import json
from pathlib import Path

from .state import canonical
from .tools import execute_tool
from .loop import generate_manifest, init_instance, run_tick, status

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE.parents[2]
DEFAULT_RUN_ROOT = REPO_ROOT / "temp" / "factory-primitive"
FAULTS = {"", "malformed-decision", "disallowed-decision", "escape-create", "escape-modify",
          "escape-external", "crash-intent", "crash-act", "crash-before-snapshot", "unbilled-error",
          "timeout-unknown", "tool-failure", "missing-receipt"}


def _run_root(value: str | None) -> Path:
    root = Path(value).resolve() if value else DEFAULT_RUN_ROOT.resolve()
    try:
        root.relative_to(DEFAULT_RUN_ROOT.resolve())
    except ValueError as exc:
        raise ValueError(f"run root must stay under {DEFAULT_RUN_ROOT}") from exc
    return root


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="GH-1248 deterministic outer-loop primitive")
    p.add_argument("--run-root", help="mutable run root under temp/factory-primitive")
    sub = p.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--instance", default="C")
    init.add_argument("--scenario", type=Path, default=PACKAGE / "scenarios" / "soak-v1.jsonl")
    init.add_argument("--manifest", type=Path, default=PACKAGE / "scenarios" / "soak-v1.manifest.json")
    init.add_argument("--daily-cap", type=float, default=1.0)
    init.add_argument("--max-call-cost", type=float, default=0.0)
    manifest = sub.add_parser("generate-manifest")
    manifest.add_argument("--scenario", type=Path, default=PACKAGE / "scenarios" / "soak-v1.jsonl")
    manifest.add_argument("--output", type=Path, default=PACKAGE / "scenarios" / "soak-v1.manifest.json")
    tick = sub.add_parser("tick")
    tick.add_argument("--instance", default="C")
    tick.add_argument("--slot", type=int, required=True)
    tick.add_argument("--fault", choices=sorted(FAULTS), default="")
    stat = sub.add_parser("status")
    stat.add_argument("--instance", default="C")
    tool = sub.add_parser("tool")
    tool.add_argument("--tool", required=True, choices=["note", "summarize", "probe", "idle"])
    tool.add_argument("--tick-id", required=True)
    tool.add_argument("--out-dir", type=Path, required=True)
    tool.add_argument("--args-json", required=True)
    tool.add_argument("--items-json", required=True)
    return p


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "tool":
            return execute_tool(args.tool, args.tick_id, args.out_dir,
                                json.loads(args.args_json), json.loads(args.items_json))
        if args.command == "generate-manifest":
            generate_manifest(args.scenario, args.output)
            return 0
        root = _run_root(args.run_root)
        if args.instance in {"", ".", ".."} or not all(c.isalnum() or c in "-_." for c in args.instance):
            raise ValueError("instance must be a simple name without path separators")
        instance = (root / "instances" / args.instance).resolve()
        instance.relative_to((root / "instances").resolve())
        if args.command == "init":
            if args.daily_cap <= 0 or args.max_call_cost < 0 or args.max_call_cost > args.daily_cap:
                raise ValueError("invalid daily cap or maximum call cost")
            init_instance(instance, args.scenario.resolve(), args.manifest.resolve(),
                          args.daily_cap, args.max_call_cost)
            print(canonical({"status": "initialized", "instance": str(instance)}))
            return 0
        if args.command == "tick":
            if not 1 <= args.slot <= 288:
                raise ValueError("slot must be in 1..288")
            outcome = run_tick(instance, args.slot, args.fault)
            print(canonical({"tick_id": f"slot_{args.slot:03d}", "status": outcome}))
            return 0 if outcome in {"completed", "paused", "uncertain", "unpersisted-intent-abort"} else 1
        if args.command == "status":
            print(json.dumps(status(instance), indent=2, sort_keys=True))
            return 0
        raise ValueError("unknown command")
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"factory-primitive: {exc}", file=__import__("sys").stderr)
        return 2
