#!/usr/bin/env python3
import os
import sys
import subprocess
import tempfile
import shutil
import datetime

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

if __name__ == "__main__":
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
                policy = args[i+1]
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
                out_format = args[i+1]
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
    
    # Python strftime %Y-%m-%dT%H:%M:%SZ
    now = os.environ.get("QUEUE_PLAN_NOW", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    today = os.environ.get("QUEUE_PLAN_TODAY", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d"))

    if not os.path.isfile(roadmap):
        emit(f"ROADMAP not found: {roadmap}")
        sys.exit(3)

    try:
        subprocess.check_call(["node", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        die("node is required (Node stdlib only; no deps) but not found in PATH")

    tmp_dir = tempfile.mkdtemp(prefix="marathon-plan.")
    render_out = os.path.join(tmp_dir, f"MARATHON-PLAN-{today}.md")
    queue_doc = os.path.join(queue_dir, f"MARATHON-PLAN-{today}.md")

    swarm_preflight = os.path.join(here_parent, "swarm-preflight.sh")
    if not (deep and os.path.isfile(swarm_preflight) and os.access(swarm_preflight, os.X_OK)):
        swarm_preflight = ""

    env = os.environ.copy()
    env.update({
        "QP_ROOT": root,
        "QP_ROADMAP": roadmap,
        "QP_QUEUE_DIR": queue_dir,
        "QP_TODAY": today,
        "QP_NOW": now,
        "QP_POLICY": policy,
        "QP_FORMAT": out_format,
        "QP_DEEP": "1" if deep else "0",
        "QP_REQUIRE_GH": "1" if require_gh else "0",
        "QP_SWARM_PREFLIGHT": swarm_preflight,
        "QP_SP_CMD": sp_cmd,
        "QP_MD_CMD": md_cmd,
        "QP_MP_CMD": mp_cmd,
        "QP_RENDER_OUT": render_out,
        "QP_GH_STATE_FILE": os.environ.get("QUEUE_PLAN_GH_STATE_FILE", ""),
        "QP_BRANCHES_FILE": os.environ.get("QUEUE_PLAN_BRANCHES_FILE", ""),
        "QP_GH_FORCE": os.environ.get("QUEUE_PLAN_GH", ""),
        "QP_BASE_FILES_FILE": os.environ.get("QUEUE_PLAN_BASE_FILES_FILE", ""),
    })

    node_script = os.path.join(here, "_marathon_plan_node.js")
    
    try:
        rc = subprocess.call(["node", node_script], env=env)
    except Exception as e:
        sys.stderr.write(f"node error: {e}\n")
        sys.exit(1)

    if rc in (2, 3):
        shutil.rmtree(tmp_dir, ignore_errors=True)
        sys.exit(rc)

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
