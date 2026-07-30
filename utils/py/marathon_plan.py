#!/usr/bin/env python3
"""marathon-plan (Python path) — native planner CLI wrapper.

GH-340: this used to shell out to the copied `utils/py/_marathon_plan_node.js` and hard-require
`node`. It now drives the native Python engine in `utils/py/_marathon_plan.py` directly, so a
production Python marathon-plan run needs neither Node nor that JS file. The former `docOf` and
PR-review-overlay parity shims are folded into the native engine (no ROADMAP input mutation, no
post-render patching).

`utils/marathon-plan.sh` (Bash) remains the authoritative, dual-maintained twin per GH-308; this
change does not alter the `XYZ_PYTHON=0` fallback.

CLI contract (unchanged): [--dry-run | --check] [--policy quick-wins|derisk-first] [--deep]
[--require-gh] [--format text|json]. `--zones-config` is translated to QUEUE_PLAN_ZONES_FILE by
the Bash entry point before this script runs.
"""
import os
import sys
import subprocess
import tempfile
import shutil
import datetime

# Import the native engine relative to this file (utils/py/), independent of CWD/PYTHONPATH.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _marathon_plan as engine  # noqa: E402


def die(msg):
    sys.stderr.write(f"marathon-plan: {msg}\n")
    sys.exit(2)


def emit(msg):
    sys.stderr.write(f"{msg}\n")


def usage():
    print("""Usage: utils/py/marathon_plan.py [--dry-run | --check] [--policy quick-wins|derisk-first]
                           [--deep] [--require-gh] [--format text|json]

  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
  --dry-run        Print the report; write no marathon-plan doc.
  --check          Re-render and compare against today's marathon-plan doc; non-zero on drift. Writes nothing.
  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
                   (authoritative ref-based freshness/probe verdict; slower, needs network).
  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
  --format F       text (default) | json (findings as one JSON object per line).

Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.""")
    sys.exit(0)


def main():
    policy = "quick-wins"
    out_format = "text"
    run_mode = "write"
    deep = False
    require_gh = False

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--dry-run":
            run_mode = "dry-run"
            i += 1
        elif arg == "--check":
            run_mode = "check"
            i += 1
        elif arg == "--policy":
            if i + 1 < len(args):
                policy = args[i + 1]
                i += 2
            else:
                die("missing argument for --policy")
        elif arg == "--deep":
            deep = True
            i += 1
        elif arg == "--require-gh":
            require_gh = True
            i += 1
        elif arg == "--format":
            if i + 1 < len(args):
                out_format = args[i + 1]
                i += 2
            else:
                die("missing argument for --format")
        elif arg in ("--help", "-h"):
            usage()
        else:
            usage()
            die(f"unknown argument: {arg}")

    if policy not in ("quick-wins", "derisk-first"):
        die("--policy must be 'quick-wins' or 'derisk-first'")
    if out_format not in ("text", "json"):
        die("--format must be 'text' or 'json'")

    here = os.path.dirname(os.path.abspath(__file__))
    here_parent = os.path.dirname(here)
    is_vendored = os.path.basename(os.path.dirname(here_parent)) == ".xyz"

    if is_vendored:
        root = os.environ.get("QUEUE_PLAN_ROOT", os.path.dirname(os.path.dirname(here_parent)))
        sp_cmd = ".xyz/utils/swarm-preflight.sh"
        md_cmd = ".xyz/relay-automation/marathon-drive.sh"
        mp_cmd = ".xyz/utils/marathon-plan.sh"
    else:
        root = os.environ.get("QUEUE_PLAN_ROOT", os.path.dirname(here_parent))
        sp_cmd = "utils/swarm-preflight.sh"
        md_cmd = "relay-automation/marathon-drive.sh"
        mp_cmd = "utils/marathon-plan.sh"

    roadmap = os.environ.get("QUEUE_PLAN_ROADMAP", os.path.join(root, "ROADMAP.md"))
    queue_dir = os.environ.get("QUEUE_PLAN_QUEUE_DIR", os.path.join(root, "PROJECT", "2-WORKING"))

    now = os.environ.get("QUEUE_PLAN_NOW", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    today = os.environ.get("QUEUE_PLAN_TODAY", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d"))

    if not os.path.isfile(roadmap):
        emit(f"ROADMAP not found: {roadmap}")
        sys.exit(3)

    tmp_dir = tempfile.mkdtemp(prefix="marathon-plan.")
    render_out = os.path.join(tmp_dir, f"MARATHON-PLAN-{today}.md")
    queue_doc = os.path.join(queue_dir, f"MARATHON-PLAN-{today}.md")

    swarm_preflight = os.path.join(here_parent, "swarm-preflight.sh")
    if not (deep and os.path.isfile(swarm_preflight) and os.access(swarm_preflight, os.X_OK)):
        swarm_preflight = ""

    # UTILS_DIR is the dir holding marathon-plan-zones.default.json — utils/ (parent of utils/py).
    cfg = {
        "root": root,
        "roadmap": roadmap,
        "queue_dir": queue_dir,
        "today": today,
        "now": now,
        "policy": policy,
        "format": out_format,
        "deep": deep,
        "require_gh": require_gh,
        "swarm_preflight": swarm_preflight,
        "sp_cmd": sp_cmd,
        "md_cmd": md_cmd,
        "mp_cmd": mp_cmd,
        "utils_dir": here_parent,
        "zones_config": os.environ.get("QUEUE_PLAN_ZONES_CONFIG", ""),
        "gh_state_file": os.environ.get("QUEUE_PLAN_GH_STATE_FILE", ""),
        "branches_file": os.environ.get("QUEUE_PLAN_BRANCHES_FILE", ""),
        "gh_force": os.environ.get("QUEUE_PLAN_GH", ""),
        "base_files_file": os.environ.get("QUEUE_PLAN_BASE_FILES_FILE", ""),
        "zones_file_env": os.environ.get("QUEUE_PLAN_ZONES_FILE", ""),
    }

    try:
        rc = engine.run(cfg, render_out)
    except engine.ZoneConfigError as e:
        sys.stderr.write(f"marathon-plan: {e}\n")
        shutil.rmtree(tmp_dir, ignore_errors=True)
        sys.exit(3)
    except engine.EngineExit as e:
        if e.message:
            sys.stderr.write(f"{e.message}\n")
        shutil.rmtree(tmp_dir, ignore_errors=True)
        sys.exit(e.code)

    if run_mode == "check":
        if not os.path.isfile(queue_doc):
            emit(f"check: missing artifact: {os.path.relpath(queue_doc, root) if queue_doc.startswith(root) else queue_doc}")
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(1)
        try:
            subprocess.check_call(["cmp", "-s", render_out, queue_doc])
            emit(f"check: MARATHON-PLAN-{today}.md is in sync")
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(0)
        except subprocess.CalledProcessError:
            emit(f"check: drift detected in MARATHON-PLAN-{today}.md")
            subprocess.call(["diff", "-u", queue_doc, render_out], stdout=sys.stderr)
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(1)

    if run_mode == "dry-run":
        shutil.rmtree(tmp_dir, ignore_errors=True)
        sys.exit(rc)

    os.makedirs(queue_dir, exist_ok=True)
    shutil.copy2(render_out, queue_doc)

    rel_doc = os.path.relpath(queue_doc, root) if queue_doc.startswith(root) else queue_doc
    emit(f"wrote {rel_doc}")

    shutil.rmtree(tmp_dir, ignore_errors=True)
    sys.exit(rc)


if __name__ == "__main__":
    main()
