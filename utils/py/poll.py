#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import time
import re
from rtl import resolve_tick_bin, resolve_tick_repo_root

def die(msg):
    print(f"poll: {msg}", file=sys.stderr)
    sys.exit(2)

def parked_count(tick_bin, analysis_file):
    if analysis_file:
        if not os.path.exists(analysis_file):
            die(f"analysis file does not exist: {analysis_file}")
        try:
            with open(analysis_file) as f:
                data = json.load(f)
        except Exception:
            return 0
    else:
        try:
            res = subprocess.run([tick_bin, "analyze", "--format", "json"], capture_output=True, text=True)
            data = json.loads(res.stdout)
        except Exception:
            return 0
    return len(data.get("parked_suspects", []))

def relay_field(relay_file, key):
    try:
        with open(relay_file) as f:
            for line in f:
                # Bash regex: s/^[\`*]*$1[\`*]*:[\`*]*[[:space:]]*//
                match = re.match(r'^[`*]*' + re.escape(key) + r'[`*]*:[`*]*\s*(.*)', line)
                if match:
                    val = match.group(1)
                    return val.strip('`* \t\n')
    except Exception:
        pass
    return ""

def relay_next_agent(relay_file):
    val = relay_field(relay_file, "NEXT")
    if not val: return ""
    return val.split()[0]

def commit_gate_ok(repo, match):
    if not repo or not match:
        return True
    try:
        res = subprocess.run(["git", "-C", repo, "log", "--oneline", "-30"], capture_output=True, text=True)
        import re
        if re.search(match, res.stdout):
            return True
    except Exception:
        pass
    return False

def scope_clean(git_root, scope):
    if not scope: return True
    try:
        res = subprocess.run(["git", "-C", git_root, "status", "--porcelain", "--"] + scope, capture_output=True, text=True)
        if res.stdout.strip():
            return False
    except Exception:
        pass
    return True

def read_task(tick_bin, task_id):
    t_status = ""
    t_claimer = ""
    t_handoff = ""
    t_paths = ""
    try:
        res = subprocess.run([tick_bin, "info", task_id], capture_output=True, text=True)
        for line in res.stdout.splitlines():
            if line.startswith("status:"): t_status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): t_claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): t_handoff = line.split(":", 1)[1].strip()
            elif line.startswith("paths:"): t_paths = line.split(":", 1)[1].strip()
    except Exception:
        pass
    return t_status, t_claimer, t_handoff, t_paths

def tick_my_turn(agent, t_status, t_claimer, t_handoff):
    if t_status == "open" and (not t_handoff or t_handoff == agent):
        return True
    if t_status == "claimed" and t_claimer == agent:
        return True
    return False

def is_claude_agent(agent, claude_agents_str):
    if not claude_agents_str: return False
    return agent in [a.strip() for a in claude_agents_str.split(",")]

def main():
    agent = os.environ.get("AGENT", "")
    mode = os.environ.get("MODE", "")
    relay_file = os.environ.get("RELAY_FILE", "")
    artifact = os.environ.get("ARTIFACT", "")
    claude_agents = os.environ.get("CLAUDE_AGENTS", "")
    relay_task = os.environ.get("RELAY_TASK", "RELAY-TURN")
    task = os.environ.get("TASK", "")
    analysis_file = os.environ.get("ANALYSIS_FILE", "")
    watchdog_authority = os.environ.get("WATCHDOG_AUTHORITY", "0") == "1"
    watchdog_cmd = os.environ.get("WATCHDOG_CMD", "")
    run_cmd_env = os.environ.get("RUN_CMD", "")
    runner_cmd = os.environ.get("RUNNER_CMD", "")
    dry_run = os.environ.get("DRY_RUN", "0") == "1"
    deadline_str = os.environ.get("DEADLINE", "")
    turn_source = os.environ.get("TURN_SOURCE", "tick")
    peer_commit_repo = os.environ.get("PEER_COMMIT_REPO", "")
    peer_commit_match = os.environ.get("PEER_COMMIT_MATCH", "")
    emit_delay = os.environ.get("EMIT_DELAY", "0") == "1"
    
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--mode" and i+1 < len(args): mode = args[i+1]; i+=2
        elif arg == "--agent" and i+1 < len(args): agent = args[i+1]; i+=2
        elif arg == "--relay-file" and i+1 < len(args): relay_file = args[i+1]; i+=2
        elif arg == "--artifact" and i+1 < len(args): artifact = args[i+1]; i+=2
        elif arg == "--claude-agents" and i+1 < len(args): claude_agents = args[i+1]; i+=2
        elif arg == "--relay-task" and i+1 < len(args): relay_task = args[i+1]; i+=2
        elif arg == "--task" and i+1 < len(args): task = args[i+1]; i+=2
        elif arg == "--analysis-file" and i+1 < len(args): analysis_file = args[i+1]; i+=2
        elif arg == "--watchdog-authority": watchdog_authority = True; i+=1
        elif arg == "--watchdog-cmd" and i+1 < len(args): watchdog_cmd = args[i+1]; i+=2
        elif arg == "--runner-cmd" and i+1 < len(args): runner_cmd = args[i+1]; i+=2
        elif arg == "--run":
            if i+1 < len(args): run_cmd_env = args[i+1]; i+=2
            else: die("--run requires an argument")
        elif arg == "--dry-run": dry_run = True; i+=1
        elif arg == "--deadline" and i+1 < len(args): deadline_str = args[i+1]; i+=2
        elif arg == "--turn-source" and i+1 < len(args): turn_source = args[i+1]; i+=2
        elif arg == "--peer-commit-repo" and i+1 < len(args): peer_commit_repo = args[i+1]; i+=2
        elif arg == "--peer-commit-match" and i+1 < len(args): peer_commit_match = args[i+1]; i+=2
        elif arg == "--emit-delay": emit_delay = True; i+=1
        elif arg.startswith("-"): die(f"Unknown flag: {arg}")
        else: i+=1

    if not agent: die("--agent is required")
    if not mode: die("one of --mode relay or --mode xyz is required")
    
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    tick_repo_root = resolve_tick_repo_root(xyz_root)
    tick_bin = resolve_tick_bin(tick_repo_root, xyz_root) or os.environ.get("TICK_BIN", "tick")
    git_root = os.environ.get("POLL_GIT_ROOT", os.environ.get("GIT_ROOT", "."))
    deadline = int(deadline_str) if deadline_str else 0

    poll_delay_idle = int(os.environ.get("POLL_DELAY_IDLE", 300))
    poll_delay_dirty = int(os.environ.get("POLL_DELAY_DIRTY", 30))
    poll_delay_wait_commit = int(os.environ.get("POLL_DELAY_WAIT_COMMIT", 90))
    poll_delay_nudge = int(os.environ.get("POLL_DELAY_NUDGE", 120))

    if not runner_cmd:
        runner_cmd = os.environ.get("RUNNER_CMD", run_cmd_env)
        if not runner_cmd:
            runner_cmd = os.path.join(xyz_root, "relay-automation", "runner.sh")
    if not watchdog_cmd:
        watchdog_cmd = os.environ.get("WATCHDOG_CMD", "")
        
    stop = False
    my_turn = False
    clean = True
    cross_model = False
    cross_agent = ""
    wait_commit = False
    
    parked = False
    if turn_source == "tick" or analysis_file:
        if parked_count(tick_bin, analysis_file) > 0:
            parked = True
            
    if mode == "relay":
        if not relay_file: die("relay mode requires --relay-file")
        if not os.path.exists(relay_file): die(f"relay file does not exist: {relay_file}")
        
        status = relay_field(relay_file, "STATUS")
        if status in ("Approved", "Closed"):
            stop = True
            
        if turn_source == "file":
            nxt = relay_next_agent(relay_file)
            if nxt and nxt == agent:
                if commit_gate_ok(peer_commit_repo, peer_commit_match):
                    my_turn = True
                    scope = [relay_file]
                    if artifact: scope.append(artifact)
                    clean = scope_clean(git_root, scope)
                else:
                    wait_commit = True
            elif nxt and nxt != agent and not is_claude_agent(nxt, claude_agents):
                cross_model = True
                cross_agent = nxt
        else:
            t_status, t_claimer, t_handoff, t_paths = read_task(tick_bin, relay_task)
            if tick_my_turn(agent, t_status, t_claimer, t_handoff):
                my_turn = True
                scope = [relay_file]
                if artifact: scope.append(artifact)
                clean = scope_clean(git_root, scope)
            elif t_status == "open" and t_handoff and t_handoff != agent and not is_claude_agent(t_handoff, claude_agents):
                cross_model = True
                cross_agent = t_handoff
    else:
        if not task: die("xyz mode requires --task")
        t_status, t_claimer, t_handoff, t_paths = read_task(tick_bin, task)
        if tick_my_turn(agent, t_status, t_claimer, t_handoff):
            my_turn = True
            if t_paths:
                scope = [p.strip() for p in t_paths.split(",")]
                clean = scope_clean(git_root, scope)
                
    expired = False
    if deadline and int(time.time()) >= deadline:
        expired = True
        
    decision = ""
    reason = ""
    if expired: decision = "stop"; reason = "deadline reached (self-expire)"
    elif stop: decision = "stop"; reason = "relay STATUS is terminal"
    elif cross_model: decision = "nudge-cross-model"; reason = f"turn belongs to non-Claude agent '{cross_agent}'"
    elif my_turn and clean: decision = "run-runner"; reason = "my turn and artifact scope clean"
    elif my_turn: decision = "idle"; reason = "my turn but artifact scope dirty"
    elif wait_commit: decision = "idle"; reason = "my turn by NEXT but peer fix commit not yet landed"
    elif parked and watchdog_authority: decision = "run-watchdog"; reason = "parked suspect and I hold watchdog authority"
    elif parked: decision = "idle"; reason = "parked suspect but no watchdog authority"
    else: decision = "idle"; reason = "nothing runnable"
    
    print(f"DECISION: {decision} ({reason})")
    
    if emit_delay:
        delay = 0
        dreason = ""
        if decision in ("run-runner", "run-watchdog"): delay = 0; dreason = "act now"
        elif decision == "stop": delay = 0; dreason = "loop ends"
        elif decision == "nudge-cross-model": delay = poll_delay_nudge; dreason = "awaiting cross-model turn"
        elif decision == "idle":
            if wait_commit: delay = poll_delay_wait_commit; dreason = "awaiting peer commit"
            elif my_turn: delay = poll_delay_dirty; dreason = "scope dirty, retry soon"
            else: delay = poll_delay_idle; dreason = "idle backoff"
        else:
            delay = poll_delay_idle; dreason = "idle backoff"
            
        if deadline and delay > 0:
            rem = deadline - int(time.time())
            if 0 < rem < delay:
                delay = rem
                dreason = f"{dreason} (clamped to deadline)"
        print(f"DELAY: {delay} ({dreason})")
        
    if dry_run:
        sys.exit(10 if decision == "stop" else 0)
        
    def run_cmd(cmd_str):
        if not cmd_str: return
        if os.path.isfile(cmd_str) and os.access(cmd_str, os.X_OK):
            subprocess.run([cmd_str])
        else:
            subprocess.run(cmd_str, shell=True)
        
    if decision == "run-runner":
        run_cmd(runner_cmd)
    elif decision == "run-watchdog":
        run_cmd(watchdog_cmd)
    elif decision == "nudge-cross-model":
        print(f"poll: {cross_agent} turn detected — manual nudge required: \"take your turn on {relay_file or '<relay-file>'}\"", file=sys.stderr)
    elif decision == "stop":
        sys.exit(10)
    elif decision == "idle":
        pass

if __name__ == "__main__":
    main()
