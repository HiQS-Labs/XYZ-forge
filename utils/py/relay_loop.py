#!/usr/bin/env python3
import os
import sys
import subprocess
import time
import re
import shlex
import signal

def usage():
    print("""Usage: relay-automation/relay-loop.sh [--sleep-loop | --background] [--max-ticks N]
                                      [--min-delay S] [--bg-pidfile PATH]
                                      [--cross-model-cmd CMD] <poll.sh args...>

Adaptive-cadence wrapper over poll.sh (GH-33 Phase 2/3). Runs `poll.sh --emit-delay`
and turns its DECISION + DELAY into cadence.

  (default)      one tick; prints "NEXT-POLL: <seconds>"; exits poll.sh's code
                 (10 = stop). For a /loop dynamic tick, cron, or any scheduler.
  --sleep-loop   self-pace in pure bash (tick -> sleep DELAY -> repeat) until
                 DECISION: stop / exit 10. No /loop, no Claude dependency.
  --background   one tick; on DECISION: run-runner OR (when configured) a reachable
                 nudge-cross-model command, launch the turn DETACHED and return at
                 once (session freed; scheduler re-invokes next tick). A pidfile
                 prevents double-dispatch while a turn runs. Requires --relay-file
                 (default pidfile <relay-file>.bgpid) or an explicit --bg-pidfile.
                 Mutually exclusive with --sleep-loop. Unreachable or unset cross-
                 model commands degrade to poll.sh's manual nudge.
  --bg-pidfile P background-turn pidfile (default: <relay-file>.bgpid).
  --cross-model-cmd CMD
                 command to background-dispatch on DECISION: nudge-cross-model.
                 Wrapper-only; not forwarded to poll.sh.
  --max-ticks N  stop after N ticks (sleep-loop; 0 = unbounded). Runaway guard.
  --min-delay S  floor for the sleep (default 1s) so DELAY:0 never busy-spins; also
                 the re-check interval after a --background dispatch.

All other args pass straight through to poll.sh (--mode/--agent/--relay-file/...).
Env: POLL_BIN (poll.sh path), RELAY_LOOP_MIN_DELAY.
""")
    sys.exit(0)

def bg_alive(pidfile):
    if not os.path.exists(pidfile): return False
    try:
        with open(pidfile) as f:
            p = f.read().strip()
        if not p: return False
        pid = int(p)
        os.kill(pid, 0)
        return True
    except Exception:
        return False

def bg_launch(cmd, pidfile):
    log = f"{pidfile}.log"
    with open(log, "w") as f:
        if os.path.isfile(cmd) and os.access(cmd, os.X_OK):
            proc = subprocess.Popen([cmd], stdout=f, stderr=subprocess.STDOUT, start_new_session=True)
        else:
            proc = subprocess.Popen(cmd, shell=True, stdout=f, stderr=subprocess.STDOUT, start_new_session=True)
    with open(pidfile, "w") as f:
        f.write(f"{proc.pid}\n")

def cmd_is_reachable(cmd):
    if not cmd: return False
    if os.path.isfile(cmd) and os.access(cmd, os.X_OK): return True
    first = shlex.split(cmd)[0] if cmd else ""
    if not first: return False
    import shutil
    return shutil.which(first) is not None

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(here)))
    poll_bin_default = os.path.join(xyz_root, "relay-automation", "poll.sh")
    poll_bin = os.environ.get("POLL_BIN", poll_bin_default)
    
    sleep_loop = False
    background = False
    bg_pidfile = ""
    max_ticks = 0
    min_delay = int(os.environ.get("RELAY_LOOP_MIN_DELAY", 1))
    
    pass_args = []
    relay_file_arg = ""
    runner_cmd_arg = ""
    cross_model_cmd_arg = ""
    
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--sleep-loop": sleep_loop = True; i += 1
        elif arg == "--background": background = True; i += 1
        elif arg == "--bg-pidfile" and i + 1 < len(args): bg_pidfile = args[i+1]; i += 2
        elif arg == "--cross-model-cmd" and i + 1 < len(args): cross_model_cmd_arg = args[i+1]; i += 2
        elif arg == "--max-ticks" and i + 1 < len(args): max_ticks = int(args[i+1]); i += 2
        elif arg == "--min-delay" and i + 1 < len(args): min_delay = int(args[i+1]); i += 2
        elif arg in ("--help", "-h"): usage()
        elif arg == "--relay-file" and i + 1 < len(args): 
            relay_file_arg = args[i+1]
            pass_args.extend([arg, args[i+1]])
            i += 2
        elif arg == "--runner-cmd" and i + 1 < len(args):
            runner_cmd_arg = args[i+1]
            pass_args.extend([arg, args[i+1]])
            i += 2
        else:
            pass_args.append(arg)
            i += 1

    if not os.path.exists(poll_bin):
        print(f"relay-loop: poll.sh not found at {poll_bin}", file=sys.stderr)
        sys.exit(2)
        
    def run_poll(extra_args=[]):
        cmd = [poll_bin, "--emit-delay"] + extra_args + pass_args
        res = subprocess.run(cmd, capture_output=True, text=True)
        out = res.stdout
        print(out, end="")
        if res.stderr:
            print(res.stderr, file=sys.stderr, end="")
        
        delay = ""
        decision = ""
        reason = ""
        for line in out.splitlines():
            if line.startswith("DELAY: "): delay = line[7:].split()[0]
            elif line.startswith("DECISION: "): 
                parts = line[10:].split(" (", 1)
                decision = parts[0]
                if len(parts) > 1: reason = parts[1][:-1]
        
        return res.returncode, out, delay, decision, reason
        
    def tick():
        return run_poll()
        
    if background:
        if sleep_loop:
            print("relay-loop: --background is for the one-tick /loop model, not --sleep-loop", file=sys.stderr)
            sys.exit(2)
        if not bg_pidfile and relay_file_arg:
            bg_pidfile = f"{relay_file_arg}.bgpid"
        if not bg_pidfile:
            print("relay-loop: --background needs --relay-file or --bg-pidfile", file=sys.stderr)
            sys.exit(2)
        if not runner_cmd_arg:
            runner_cmd_arg = os.path.join(xyz_root, "relay-automation", "runner.sh")
            
        rc, out, delay, decision, reason = run_poll(["--dry-run"])
        
        if bg_alive(bg_pidfile):
            with open(bg_pidfile) as f: p = f.read().strip()
            print(f"BG-RUNNING: pid={p}")
            print(f"NEXT-POLL: {min_delay}")
            sys.exit(0)
            
        if os.path.exists(bg_pidfile):
            os.remove(bg_pidfile)
            
        if decision == "run-runner":
            bg_launch(runner_cmd_arg, bg_pidfile)
            with open(bg_pidfile) as f: p = f.read().strip()
            print(f"BG-DISPATCH: pid={p}")
            print(f"NEXT-POLL: {min_delay}")
            sys.exit(0)
        elif decision == "nudge-cross-model":
            if cmd_is_reachable(cross_model_cmd_arg):
                bg_launch(cross_model_cmd_arg, bg_pidfile)
                with open(bg_pidfile) as f: p = f.read().strip()
                print(f"BG-DISPATCH: pid={p}")
                print(f"NEXT-POLL: {min_delay}")
            else:
                cross_agent = "cross-model"
                m = re.match(r"^turn belongs to non-Claude agent '([^']+)'$", reason)
                if m: cross_agent = m.group(1)
                print(f"poll: {cross_agent} turn detected — manual nudge required: \"take your turn on {relay_file_arg or '<relay-file>'}\"", file=sys.stderr)
                d = delay if delay else min_delay
                print(f"NEXT-POLL: {d}")
            sys.exit(0)
        elif decision == "stop":
            print("NEXT-POLL: 0")
            sys.exit(10)
        else:
            d = delay if delay else min_delay
            print(f"NEXT-POLL: {d}")
            sys.exit(rc)
            
    if sleep_loop:
        ticks = 0
        while True:
            rc, out, delay, decision, reason = tick()
            if rc == 10: sys.exit(10)
            ticks += 1
            if max_ticks > 0 and ticks >= max_ticks: sys.exit(rc)
            d = int(delay) if delay else min_delay
            if d < min_delay: d = min_delay
            time.sleep(d)
            
    rc, out, delay, decision, reason = tick()
    d = delay if delay else min_delay
    print(f"NEXT-POLL: {d}")
    sys.exit(rc)

if __name__ == "__main__":
    main()
