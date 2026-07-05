import os
import shlex
import subprocess
import tempfile
import sys

class RelayTurnLib:
    def __init__(self, root, xyz_root, relay_file, allow_paths):
        self.root = root
        self.xyz_root = xyz_root
        self.relay_file = relay_file
        self.allow_paths = allow_paths
        fd, self.state_file = tempfile.mkstemp()
        os.close(fd)
        
    def __del__(self):
        # Guard against a partially-initialized instance (mkstemp raised before
        # state_file was bound) — __del__ can still fire and must not AttributeError.
        if not hasattr(self, "state_file"):
            return
        try:
            os.remove(self.state_file)
        except OSError:
            pass

    def _run_rtl(self, cmd_str, capture=True):
        # Build the bridge script; every interpolated path is shell-quoted and
        # TICK_REPO_ROOT is passed via the child env (not embedded in the source)
        # so a path/value with quotes or `$()` can't inject shell syntax.
        lib = shlex.quote(os.path.join(self.xyz_root, "relay-automation", "relay-turn-lib.sh"))
        state = shlex.quote(self.state_file)
        state_tmp = shlex.quote(self.state_file + ".tmp")
        script = f"""
source {lib} >/dev/null 2>&1
if [ -s {state} ]; then
  source {state}
else
  rtl_init {shlex.quote(self.root)} {shlex.quote(self.relay_file)} {shlex.quote(self.allow_paths)} >/dev/null 2>&1
fi

{cmd_str}
RC=$?

vars=$(compgen -v | grep '^RTL_' || true)
if [ -n "$vars" ]; then
  declare -p $vars > {state_tmp} 2>/dev/null
  mv {state_tmp} {state}
fi

exit $RC
"""
        env = dict(os.environ)
        env["TICK_REPO_ROOT"] = os.environ.get("TICK_REPO_ROOT", self.root)
        # Never sys.exit() here: callers (before/enforce/worktree_begin) must be
        # able to inspect a non-zero return code and route it (containment exit 6,
        # worktree-failure exit 5). Fail-fast for the must-succeed derivation calls
        # lives in _run_checked, one layer up.
        return subprocess.run(["bash", "-c", script], capture_output=capture, text=True, env=env)

    def _run_checked(self, cmd_str, capture=True):
        # For derivation calls (artifact/prompt/drift) whose failure means the turn
        # cannot proceed: preserve the original fail-fast behavior explicitly, at the
        # call site rather than buried in the shared runner.
        res = self._run_rtl(cmd_str, capture=capture)
        if res.returncode != 0:
            print(f"rtl: relay-turn-lib call failed (exit {res.returncode})", file=sys.stderr)
            sys.exit(res.returncode)
        return res

    def get_artifact(self):
        res = self._run_checked("echo -n \"${RTL_ARTIFACT:-}\"")
        return res.stdout.strip()

    def turn_prompt(self, agent, task, peer):
        cmd = f"rtl_turn_prompt {shlex.quote(agent)} {shlex.quote(self.relay_file)} {shlex.quote(task)} {shlex.quote(self.allow_paths)} {shlex.quote(peer)}"
        res = self._run_checked(cmd)
        return res.stdout.strip()

    def drift_brief(self, agent, tick_repo_root):
        cmd = f"rtl_drift_brief {shlex.quote(agent)} {shlex.quote(tick_repo_root)}"
        res = self._run_checked(cmd)
        return res.stdout.strip()
        
    def before(self):
        res = self._run_rtl("rtl_before", capture=False)
        return res.returncode
        
    def enforce(self, task, agent, log_file, model_name):
        cmd = f"rtl_enforce {shlex.quote(task)} {shlex.quote(agent)} {shlex.quote(log_file)} {shlex.quote(model_name)}"
        res = self._run_rtl(cmd, capture=False)
        return res.returncode
        
    def worktree_begin(self):
        # prints the worktree path to stdout
        res = self._run_rtl("rtl_worktree_begin")
        if res.returncode == 0:
            return res.stdout.strip()
        return None
        
    def worktree_end(self, wt_path):
        cmd = f"""
rtl_worktree_end {shlex.quote(wt_path)}
echo -n "${{RTL_WT_OFFLANE:-0}}"
"""
        res = self._run_rtl(cmd)
        return res.stdout.strip() == "1"
