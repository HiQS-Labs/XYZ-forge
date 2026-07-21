import argparse
import os
import sys
import subprocess
import time
import re
import shutil

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_env(key, default=None):
    return os.environ.get(key, default)

def die(msg):
    eprint(f"marathon-drive: {msg}")
    sys.exit(2)

def log(msg):
    print(f"marathon-drive: {msg}")

def _probe_bin(bin_name, role_label, agent_id):
    if shutil.which(bin_name):
        return
    die(f"{role_label} binary '{bin_name}' not found on PATH (--{role_label} agent '{agent_id}')")

def _probe_claude_bin(role_label):
    claude_bin = get_env("CLAUDE_BIN")
    if claude_bin:
        if shutil.which(claude_bin):
            return
    else:
        if shutil.which("claude"):
            return
        local_claude = os.path.join(os.path.expanduser("~"), ".claude", "local", "claude")
        if os.access(local_claude, os.X_OK):
            return
    die(f"{role_label} binary 'claude' not found on PATH (set CLAUDE_BIN or use a codex/agy --{role_label} agent)")

def _probe_agent_bin(agent_id, role_label):
    # GH-117: fail before any tick mutation or clean-workspace scan if the lane's
    # builder/reviewer binary would be undispatchable.
    if agent_id.startswith("claude"):
        _probe_claude_bin(role_label)
    elif agent_id.startswith("codex"):
        _probe_bin(get_env("CODEX_BIN", "codex"), role_label, agent_id)
    elif agent_id.startswith("agy"):
        _probe_bin(get_env("AGY_BIN", "agy"), role_label, agent_id)
    elif agent_id.startswith("aider"):
        _probe_bin(get_env("AIDER_BIN", "aider"), role_label, agent_id)

def main():
    parser = argparse.ArgumentParser(description="marathon-drive", add_help=False)
    parser.add_argument("--phase-brief", dest="phase_brief_file")
    parser.add_argument("--builder", dest="builder", default="codex")  # GH-212: no per-call API charge
    parser.add_argument("--reviewer", dest="reviewer")
    parser.add_argument("--round-cap", dest="round_cap", type=int, default=5)
    parser.add_argument("--pre-advance-cmd", dest="pre_advance_cmd")
    parser.add_argument("--phases-dir", dest="phases_dir")
    parser.add_argument("--phase-id", dest="phase_id", default="p1")
    parser.add_argument("--relay-task", dest="relay_task")
    parser.add_argument("--artifact", dest="artifact_paths")
    parser.add_argument("--target-root", dest="target_root")
    parser.add_argument("--require-clean", dest="require_clean", action="store_true")
    parser.add_argument("--force", dest="force", action="store_true")
    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    parser.add_argument("--help", action="store_true")

    args, unknown = parser.parse_known_args()
    if args.help:
        print("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        sys.exit(0)

    if not args.phase_brief_file:
        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        die("--phase-brief FILE required")
    if not os.path.isfile(args.phase_brief_file):
        die(f"phase brief not found: {args.phase_brief_file}")
    if not args.reviewer:
        eprint("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        die("--reviewer AGENT required")
    if not args.builder:
        die("--builder cannot be empty")
    if not args.phase_id:
        die("--phase-id cannot be empty")

    if args.target_root:
        try:
            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        except subprocess.CalledProcessError:
            die(f"invalid --target-root (not a git repo): {args.target_root}")

    here = os.path.dirname(os.path.abspath(__file__))
    xyz_harness = os.path.abspath(os.path.join(here, "..", ".."))
    if os.path.basename(xyz_harness) == ".xyz":
        default_root = os.path.abspath(os.path.join(xyz_harness, ".."))
    else:
        default_root = xyz_harness
    
    root = get_env("MARATHON_ROOT", default_root)
    tick_bin = get_env("TICK_BIN", os.path.join(xyz_harness, "bin", "tick"))
    relay_drive_bin = get_env("MARATHON_RELAY_DRIVE", os.path.join(xyz_harness, "relay-automation", "relay-drive.sh"))
    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))

    def _lane_key(raw):
        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)

    def lane_attempt_gate(root_dir, raw, force):
        if get_env("LANE_ATTEMPT_COUNTED"): return 0
        if not raw: return 0
        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
        try: max_attempts = int(max_attempts)
        except ValueError: max_attempts = 2

        key = _lane_key(raw)
        attempts_dir = os.path.join(root_dir, ".tick", "attempts")
        os.makedirs(attempts_dir, exist_ok=True)
        attempts_file = os.path.join(attempts_dir, key)

        count = 0
        if os.path.isfile(attempts_file):
            try:
                with open(attempts_file, "r") as f:
                    count = len(f.readlines())
            except Exception:
                pass
        
        if force:
            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
        elif count >= max_attempts:
            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
            sys.exit(8)

        # append fire
        ts = "fire"
        try:
            ts = subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        except:
            pass
        with open(attempts_file, "a") as f:
            f.write(f"{ts} fire\n")
        return 0

    def lane_attempt_reset(root_dir, raw):
        if get_env("LANE_ATTEMPT_COUNTED"): return
        if not raw: return
        attempts_file = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
        if os.path.exists(attempts_file):
            try: os.remove(attempts_file)
            except: pass

    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
        git_path = os.path.join(root, ".git")
        if os.path.isdir(git_path):
            lock_dir = os.path.join(root, ".git", "relay-driver.lock")
            lock_label = ".git/relay-driver.lock"
        elif os.path.isfile(git_path):
            common = ""
            try:
                common = subprocess.check_output(
                    ["git", "-C", root, "rev-parse", "--git-common-dir"],
                    stderr=subprocess.DEVNULL).decode('utf-8').strip()
            except Exception:
                common = ""
            if common:
                if not os.path.isabs(common):
                    common = os.path.join(root, common)
                lock_dir = os.path.join(common, "relay-driver.lock")
                lock_label = ".git/relay-driver.lock"
            else:
                lock_dir = os.path.join(root, ".relay-driver.lock")
                lock_label = ".relay-driver.lock"
        else:
            lock_dir = os.path.join(root, ".relay-driver.lock")
            lock_label = ".relay-driver.lock"
        
        try:
            os.mkdir(lock_dir)
        except OSError:
            holder = ""
            pid_file = os.path.join(lock_dir, "pid")
            if os.path.isfile(pid_file):
                try:
                    with open(pid_file, 'r') as f: holder = f.read().strip()
                except: pass
            
            is_running = False
            if holder:
                try:
                    os.kill(int(holder), 0)
                    is_running = True
                except: pass
            
            if is_running:
                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
                sys.exit(1)
            
            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
            try:
                shutil.rmtree(lock_dir)
                os.mkdir(lock_dir)
            except:
                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
                sys.exit(1)
        
        with open(os.path.join(lock_dir, "pid"), 'w') as f:
            f.write(str(os.getpid()) + "\n")
        
        os.environ["RELAY_DRIVER_LOCKED"] = "1"
        def cleanup_lock():
            try: shutil.rmtree(lock_dir)
            except: pass
        import atexit
        atexit.register(cleanup_lock)

    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(xyz_harness, "utils", "telemetry", "append-xyz-completion.sh"))

    def xyz_marathon_emit(health, desc):
        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
        if ctx == "marathon-phase": return
        if not os.access(xyz_append_bin, os.X_OK): return
        
        harness = "swarm" if ctx == "swarm" else "marathon"
        title = os.path.splitext(os.path.basename(args.phase_brief_file))[0]
        if not title: title = args.phase_id
        
        sid = get_env("XYZ_SESSION_ID", args.phase_id)
        subprocess.run([xyz_append_bin, harness, sid, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    phases_dir = args.phases_dir or os.path.join(root, "phases")
    pre_advance_cmd = args.pre_advance_cmd or f"bash {root}/validate.sh"
    relay_task = args.relay_task or f"MARATHON-{args.phase_id.upper()}-TURN"
    # GH-207: a marathon lane namespaces its phase paths + attempt state so two lanes sharing a bare
    # phase id (p1) don't collide. Defaults to the phase id when no lane namespace is set.
    lane_state_key = get_env("MARATHON_LANE_NS") or args.phase_id

    # GH-238: a vendored consumer normally has no root-level validate.sh. Do NOT spend a builder and
    # reviewer turn only to discover the default gate can't start after approval. A deliberately
    # non-executing probe (gates like `test -f build/output` only become true after the builder runs):
    # prove the gate is *runnable*, not that it currently passes. Runs before any render/tick/dispatch.
    _gate_root = args.target_root or root
    def _pre_advance_not_runnable(reason):
        die(f"pre-advance gate not runnable: '{pre_advance_cmd}' ({reason}). "
            f"Pass --pre-advance-cmd '<runnable command>' to override it.")
    def _preflight_pre_advance_gate():
        if subprocess.run(["bash", "-n", "-c", pre_advance_cmd],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            _pre_advance_not_runnable("shell syntax is invalid")
        m = re.match(r'^\s*(bash|/\S*/bash)\s+(\S+)', pre_advance_cmd)
        if m:
            gate_shell, script_arg = m.group(1), m.group(2)
            if not shutil.which(gate_shell):
                _pre_advance_not_runnable(f"interpreter '{gate_shell}' is not on PATH")
            if len(script_arg) >= 2 and script_arg[0] in "\"'" and script_arg[-1] == script_arg[0]:
                script_arg = script_arg[1:-1]
            if script_arg.startswith("-"):
                return
            gate_path = script_arg if os.path.isabs(script_arg) else os.path.join(_gate_root, script_arg)
            if not os.path.isfile(gate_path):
                _pre_advance_not_runnable(f"script file does not exist: {gate_path}")
            return
        parts = pre_advance_cmd.split()
        command_name = parts[0] if parts else ""
        if not command_name:
            _pre_advance_not_runnable("command is empty")
        if "/" in command_name:
            gate_path = command_name if os.path.isabs(command_name) else os.path.join(_gate_root, command_name)
            if not (os.path.isfile(gate_path) and os.access(gate_path, os.X_OK)):
                _pre_advance_not_runnable(f"executable does not exist or is not executable: {gate_path}")
        else:
            if not shutil.which(command_name):
                _pre_advance_not_runnable(f"command '{command_name}' is not on PATH")
    if args.dry_run:
        # dry-run never dispatches a turn, so surface the problem but keep going (matches Bash).
        try:
            _preflight_pre_advance_gate()
        except SystemExit as _e:
            if _e.code not in (0, None):
                eprint("marathon-drive: (dry-run continues; a live run would halt here)")
    else:
        _preflight_pre_advance_gate()

    os.environ["MARATHON_BUILDER"] = args.builder
    os.environ["MARATHON_REVIEWER"] = args.reviewer
    os.environ["CLAUDE_AGENT"] = ""
    os.environ["CODEX_AGENT"] = ""
    os.environ["AGY_AGENT"] = ""
    os.environ["AIDER_AGENT"] = ""

    def route_agent(agent_id):
        if agent_id.startswith("claude"): os.environ["CLAUDE_AGENT"] = agent_id
        elif agent_id.startswith("codex"): os.environ["CODEX_AGENT"] = agent_id
        elif agent_id.startswith("agy"): os.environ["AGY_AGENT"] = agent_id
        elif agent_id.startswith("aider"): os.environ["AIDER_AGENT"] = agent_id
        else: die(f"agent '{agent_id}' not recognized — must start with claude/codex/agy/aider")
        
    if args.builder == args.reviewer:
        die(f"builder and reviewer must be different agent ids (got '{args.builder}' for both)")
        
    route_agent(args.builder)
    route_agent(args.reviewer)
    
    if not (args.reviewer.startswith("codex") or args.reviewer.startswith("gemini") or args.reviewer.startswith("agy")):
        die(f"reviewer '{args.reviewer}' must start with codex/gemini/agy")

    _probe_agent_bin(args.builder, "builder")
    _probe_agent_bin(args.reviewer, "reviewer")

    if args.artifact_paths:
        os.environ["ALLOW_PATHS"] = args.artifact_paths
    else:
        if "ALLOW_PATHS" in os.environ:
            del os.environ["ALLOW_PATHS"]

    phase_dir = os.path.join(phases_dir, lane_state_key)
    relay_file = os.path.join(phase_dir, "RELAY.md")
    
    # repo-root-relative path
    if relay_file.startswith(root + "/"):
        rel_relay = relay_file[len(root)+1:]
    else:
        rel_relay = relay_file
        
    if not args.dry_run:
        try:
            out = subprocess.check_output(["git", "-C", root, "status", "--porcelain"], stderr=subprocess.DEVNULL).decode('utf-8')
            dirty = []
            for line in out.splitlines():
                if len(line) >= 4:
                    p = line[3:]
                    if not p.startswith("phases/") and not p.startswith(".tick/"):
                        dirty.append(p)
            if dirty:
                log("WARNING: workspace is not clean — an autonomous builder can be distracted by stray files.")
                for p in dirty:
                    if p: log(f"  • {p}")
                if args.require_clean:
                    die("--require-clean set and the workspace has pre-existing changes (above)")
        except Exception: pass

    os.makedirs(phase_dir, exist_ok=True)
    with open(args.phase_brief_file, "r") as f:
        brief_text = f.read()

    tick_cli = tick_bin if tick_bin.startswith("/") else os.path.join(root, tick_bin)

    if args.artifact_paths:
        claim_paths = f"{rel_relay},{args.artifact_paths}"
        builder_impl_line = f"Implement the brief by creating/editing the artifact file(s): {args.artifact_paths}"
        builder_scope_line = f"Edit ONLY these paths: {rel_relay} and {args.artifact_paths}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
        reviewer_read_line = f"Read the latest builder block above AND review the artifact file(s) on disk: {args.artifact_paths}."
        reviewer_scope_line = f"Edit ONLY {rel_relay} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
    else:
        claim_paths = rel_relay
        builder_impl_line = "Record your work directly in this relay file (relay-only phase — no source file to edit)."
        builder_scope_line = f"Edit ONLY {rel_relay}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
        reviewer_read_line = "Read the latest builder block above."
        reviewer_scope_line = "Do NOT run git. Do NOT touch any other file."

    relay_content = f"""# Marathon Phase {args.phase_id}
STATUS: Open
NEXT: {args.builder}

<!-- marathon-drive: task={relay_task} builder={args.builder} reviewer={args.reviewer} round-cap={args.round_cap} -->

## Phase Brief

{brief_text}

---

▶ TAKE YOUR TURN ({args.builder} — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. {builder_impl_line}
2. Append a build block to this relay file: `### Round N · Builder · {args.builder}` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): {tick_cli}
   - {tick_cli} claim {relay_task} --agent {args.builder} --paths "{claim_paths}"
   - {tick_cli} ping {relay_task} --agent {args.builder}
   - {tick_cli} release {relay_task} --agent {args.builder} --to {args.reviewer}
4. {builder_scope_line}

---

▶ TAKE YOUR TURN ({args.reviewer} — REVIEWER role)

You are the REVIEWER for this phase. {reviewer_read_line}
1. Append a review block: `### Round N · Reviewer · {args.reviewer}` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: {tick_cli} release {relay_task} --agent {args.reviewer} --to {args.builder}
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: {tick_cli} done {relay_task} --agent {args.reviewer}
4. Use this exact tick binary (run it from any directory) for all token operations: {tick_cli}
   {reviewer_scope_line}
"""

    with open(relay_file, 'w') as f:
        f.write(relay_content)

    if args.dry_run:
        log(f"dry-run: relay file rendered at {relay_file}")
        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
        sys.exit(0)

    subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
    # GH-207: only commit when the render actually changed — a byte-identical re-render must not HALT on
    # a "nothing to commit" git error; treat it as unchanged and continue.
    if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
        log(f"relay file unchanged: {relay_file}")
    else:
        subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
        log(f"relay file committed: {relay_file}")

    os.environ["TICK_REPO_ROOT"] = root

    def reconcile_relay_task():
        try:
            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
        except:
            return
        
        status, claimer, handoff = "", "", ""
        for line in info:
            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
            
        if status == "claimed":
            die(f"relay task {relay_task} already has a live claim by {claimer or 'unknown'}; refusing to reap a live claim")
        elif status == "open":
            if not handoff: return
            if handoff in [args.builder, args.reviewer]:
                _run_tick_loud([tick_bin, "claim", relay_task, "--agent", handoff, "--paths", rel_relay])
                _run_tick_loud([tick_bin, "release", relay_task, "--agent", handoff])
                log(f"reconciled leaked open handoff: {relay_task} (cleared stale reservation for {handoff})")
            else:
                die(f"relay task {relay_task} is open but reserved for unexpected agent '{handoff}'")

    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
    def _run_tick_loud(cmd_args):
        res = subprocess.run(cmd_args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode != 0:
            sys.exit(res.returncode)

    reconcile_relay_task()

    _run_tick_loud([tick_bin, "log", "task.created", relay_task, "--agent", "marathon"])
    _run_tick_loud([tick_bin, "claim", relay_task, "--agent", "marathon", "--paths", rel_relay])
    _run_tick_loud([tick_bin, "release", relay_task, "--agent", "marathon", "--to", args.builder])
    log(f"tick token seeded: {relay_task} → {args.builder}")

    _run_tick_loud([tick_bin, "log", "marathon.phase.start", relay_task, "--agent", "marathon"])
    log(f"phase start: running relay-drive --round-cap {args.round_cap}")

    def _run_relay_drive(review_once=False):
        cmd2 = [relay_drive_bin, "--relay-file", relay_file, "--relay-task", relay_task,
                "--agent-cmd", agent_cmd]
        if review_once:
            cmd2.append("--review-once")   # GH-207: one approval pass, no round-cap
        else:
            cmd2.extend(["--round-cap", str(args.round_cap)])
        if args.target_root:
            cmd2.extend(["--target-root", args.target_root])
        env2 = os.environ.copy()
        env2["RELAY_FILE"] = relay_file
        env2["LANE_ATTEMPT_COUNTED"] = "1"
        env2["XYZ_HARNESS_CONTEXT"] = "marathon-phase"
        env2["RELAY_COST_SUMMARY"] = "0"
        return subprocess.run(cmd2, env=env2).returncode

    relay_exit = _run_relay_drive()

    def escalate(reason, rexit):
        esc_file = os.path.join(phase_dir, "ESCALATION.md")
        with open(esc_file, 'w') as f:
            f.write(f"""# ESCALATION — Marathon Phase {args.phase_id}

phase: {args.phase_id}
task: {relay_task}
relay-drive-exit: {rexit}
reason: {reason}
relay-file: {rel_relay}
""")
        subprocess.run(["git", "-C", root, "add", "--", esc_file], check=True)
        # GH-207: an identical escalation record must not HALT on nothing-to-commit.
        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
        subprocess.run([tick_bin, "log", "marathon.phase.escalated", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        log(f"escalation written: {esc_file} (reason: {reason})")

    def save_transcript():
        try:
            # We must use relay-turn-lib.sh to resolve rtl_transcript_root
            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
        except subprocess.CalledProcessError:
            return False
        
        import datetime
        now = datetime.datetime.utcnow()
        date_dir = os.path.join(ts_base, now.strftime("%Y-%m-%d"))
        os.makedirs(date_dir, exist_ok=True)
        dest = os.path.join(date_dir, f"marathon-{args.phase_id}-{now.strftime('%H%M%S')}.md")
        shutil.copy2(relay_file, dest)
        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
            log(f"transcript unchanged: {dest}")
        else:
            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
            log(f"transcript saved: {dest}")
        return True

    def run_pre_advance_gate():
        cwd = args.target_root if args.target_root else None
        return subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash", cwd=cwd).returncode

    def artifacts_exist():
        if not args.artifact_paths:
            return False
        aroot = args.target_root or root
        for p in args.artifact_paths.split(","):
            p = p.strip()
            if not p:
                continue
            ap = p if os.path.isabs(p) else os.path.join(aroot, p)
            if not os.path.exists(ap):
                return False
        return True

    def file_status():
        try:
            with open(relay_file) as f:
                for line in f:
                    if line.startswith("STATUS:"):
                        return line.split(":", 1)[1].strip()
        except Exception:
            pass
        return ""

    def terminal_status(s):
        return s in ("Approved", "Closed")

    def token_state():
        try:
            info = subprocess.check_output([tick_bin, "info", relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
        except Exception:
            return ("", "")
        status = claimer = handoff = ""
        for line in info:
            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
        actor = claimer if status == "claimed" else (handoff if status == "open" else "")
        return (status, actor)

    def complete_phase_success(success_mode="approved"):
        log(f"relay approved — running pre-advance gate: {pre_advance_cmd}")
        gate_exit = run_pre_advance_gate()
        if gate_exit != 0:
            log(f"pre-advance gate FAILED (exit {gate_exit}) — escalating")
            escalate("pre-advance-failed", 0)
            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate failed")
            sys.exit(5)
        if success_mode == "already-satisfied":
            success_text = f"phase {args.phase_id} complete — lane_already_satisfied, reviewer approved, gate passed"
        else:
            success_text = f"phase {args.phase_id} complete — STATUS: Approved, gate passed"
        subprocess.run([tick_bin, "log", "marathon.phase.approved", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)
        save_transcript()
        log(success_text)
        xyz_marathon_emit("green", success_text)
        sys.exit(0)

    def recover_already_satisfied_lane():
        # GH-207: a stalled builder (exit 3) whose declared artifact is already built AND gate-green gets
        # ONE routed reviewer pass instead of a false no-progress escalation. Returns 0 to route to
        # complete_phase_success(already-satisfied); 3 to fall through to the ordinary no-progress halt.
        if not args.artifact_paths or not artifacts_exist():
            return 3
        log(f"relay stalled (exit 3) with declared artifact(s) already present — probing the pre-advance gate: {pre_advance_cmd}")
        if run_pre_advance_gate() != 0:
            log("already-satisfied probe: pre-advance gate FAILED — treating it as real no-progress")
            return 3
        s = file_status()
        tstatus, actor = token_state()
        if terminal_status(s) and not actor:
            log(f"already-satisfied probe: relay already reached terminal agreement (STATUS: {s}, token done)")
            return 0
        if tstatus == "claimed" and actor == args.builder:
            subprocess.run([tick_bin, "release", relay_task, "--agent", args.builder, "--to", args.reviewer], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif tstatus == "open" and actor == args.builder:
            subprocess.run([tick_bin, "claim", relay_task, "--agent", args.builder, "--paths", claim_paths], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run([tick_bin, "release", relay_task, "--agent", args.builder, "--to", args.reviewer], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            log(f"already-satisfied probe: artifact + gate are green, but current actor is {actor or 'none'} (token {tstatus or 'missing'}) — cannot auto-route to review")
            return 3
        log(f"already-satisfied probe: routed the stalled builder turn to reviewer {args.reviewer} for one approval pass")
        review_exit = _run_relay_drive(review_once=True)
        if review_exit == 0:
            return 0
        if review_exit == 5:
            log("already-satisfied probe: reviewer declined approval — lane remains unsatisfied")
            return 3
        return review_exit

    if relay_exit == 0:
        complete_phase_success()
    elif relay_exit == 3:
        if recover_already_satisfied_lane() == 0:
            complete_phase_success("already-satisfied")
        log("relay escalated: no-progress (relay-drive exit 3)")
        escalate("no-progress", 3)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay no-progress")
        sys.exit(3)
    elif relay_exit == 4:
        log("relay escalated: cap/close-mismatch (relay-drive exit 4)")
        escalate("cap-or-close-mismatch", 4)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — relay cap/close-mismatch")
        sys.exit(4)
    elif relay_exit == 5:
        log("relay escalated: pre-advance gate failed")
        escalate("pre-advance-failed", 5)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate failed")
        sys.exit(5)
    elif relay_exit == 6:
        log("relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)")
        escalate("containment-violation (off-lane edit reverted by a turn-taker)", 6)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — containment violation (off-lane edit reverted)")
        sys.exit(6)
    elif relay_exit == 7:
        log("relay escalated: timeout / hang (relay-drive exit 7)")
        escalate("turn-timeout-or-hang", 7)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — turn timeout / hang")
        sys.exit(7)
    else:
        die(f"relay-drive exited with unexpected code {relay_exit}")

if __name__ == "__main__":
    main()
