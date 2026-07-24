import os
import shlex
import subprocess
import tempfile
import sys

def split_allow_paths(allow_paths):
    paths = []
    for path in (allow_paths or "").split(","):
        path = path.strip()
        if path:
            paths.append(path)
    return paths

def claim_paths_for_turn(root, relay_file, allow_paths):
    # Resolve both through realpath before computing the relative path. `root` and `relay_file` can
    # come from different resolution paths — e.g. root via resolve_turn_root's `git rev-parse
    # --show-toplevel` fallback, which returns the PHYSICAL path, vs. a caller-supplied relay_file
    # still in macOS's unresolved /var-or-/tmp-symlink form — and a symlink-form mismatch here makes
    # relpath climb all the way out to an unrelated "../../.."-prefixed path instead of a clean
    # repo-relative one (the same GH-51 class of bug relay-turn-lib.sh's rtl_init already guards
    # against on the bridged/bash side; this native Python computation had no equivalent). (GH-296)
    paths = [os.path.relpath(os.path.realpath(relay_file), os.path.realpath(root))]
    paths.extend(split_allow_paths(allow_paths))
    return paths

def resolve_tick_repo_root(root):
    return os.environ.get("TICK_REPO_ROOT", root)

def resolve_turn_root(explicit_root, xyz_root):
    # Mirror the Bash shims' ROOT default (codex-turn.sh): an explicit override wins, else the
    # CWD's git toplevel — so a shim invoked from inside a same-repo vendored .xyz/ (relay-xyz's
    # documented `cd $HARNESS`) roots at the TRUE target repo, not xyz_root (the harness's own
    # directory on disk, which can differ from the git toplevel in that layout even though both
    # paths belong to the same git repo) — else xyz_root as a last resort off a git repo. (GH-296)
    if explicit_root:
        return explicit_root
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, check=True)
        top = out.stdout.strip()
        if top:
            return top
    except Exception:
        pass
    return xyz_root

def resolve_tick_bin(tick_repo_root, xyz_root):
    candidates = []
    tick_bin_env = os.environ.get("TICK_BIN")
    if tick_bin_env:
        candidates.append(tick_bin_env)
    candidates.append(os.path.join(tick_repo_root, "bin", "tick"))
    candidates.append(os.path.join(xyz_root, "bin", "tick"))

    for candidate in candidates:
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None

def make_tick_env(tick_repo_root):
    env = dict(os.environ)
    env["TICK_REPO_ROOT"] = tick_repo_root
    return env

def claim_task_or_exit(root, xyz_root, relay_file, allow_paths, task, agent, tool_name):
    tick_repo_root = resolve_tick_repo_root(root)
    tick_bin = resolve_tick_bin(tick_repo_root, xyz_root)
    if not tick_bin:
        return tick_repo_root, None

    tick_env = make_tick_env(tick_repo_root)
    claim_paths = ",".join(claim_paths_for_turn(root, relay_file, allow_paths))
    subprocess.run(
        [tick_bin, "claim", task, "--agent", agent, "--paths", claim_paths],
        env=tick_env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    info_res = subprocess.run([tick_bin, "info", task], env=tick_env, capture_output=True, text=True)
    claimer = "none"
    for line in info_res.stdout.splitlines():
        if line.startswith("claimer:"):
            claimer = line.split(":", 1)[1].strip()
            break

    if claimer != agent:
        print(
            f"{tool_name}: could not establish token ownership of {task} (claimer={claimer}, expected {agent}) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info {task}`",
            file=sys.stderr,
        )
        sys.exit(5)

    subprocess.run(
        [tick_bin, "ping", task, "--agent", agent],
        env=tick_env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return tick_repo_root, tick_bin

# ASCII-only slug alphabet — mirrors the Bash `tr -c 'A-Za-z0-9._-' '_'` sanitizer exactly. Python's
# str.isalnum() would also pass Unicode letters/digits (e.g. `é`), diverging from the Bash contract.
_SLUG_SAFE = frozenset("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")

def _ascii_slug(s):
    return "".join(c if c in _SLUG_SAFE else "_" for c in s)

def _rtl_repo_slug(target_root):
    # Mirror Bash rtl_repo_slug: origin remote basename, else target dir basename, sanitized to a SAFE
    # single path segment ([A-Za-z0-9._-]; never empty, never "."/"..", never leading "-").
    url = ""
    try:
        url = subprocess.check_output(["git", "-C", target_root, "remote", "get-url", "origin"],
                                      stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        url = ""
    while url.endswith("/"):
        url = url[:-1]
    if url.endswith(".git"):
        url = url[:-4]
    while url.endswith("/"):
        url = url[:-1]
    slug = ""
    if url:
        slug = url.rsplit("/", 1)[-1].rsplit(":", 1)[-1]   # strip path AND scp-style host: prefix
    if not slug:
        slug = os.path.basename(target_root) or ""
    slug = _ascii_slug(slug or "repo")
    while slug.startswith("-"):
        slug = slug[1:]
    if slug in ("", ".", ".."):
        slug = "repo"
    return slug

def _rtl_transcript_root(target_root, quiet=False):
    # Mirror Bash rtl_transcript_root: <root>/relay-system on the common path; when XYZ_ARCHIVE_ROOT is
    # set, validate it (ABSOLUTE, exists, is a git repo — Model A) and namespace as
    # <archive>/relay-system/<repo-slug>. Returns None on an invalid archive so the caller (rtl_default_log)
    # falls back to $TMPDIR, exactly as the Bash `... || fallback` does. quiet=True mirrors Bash callers
    # that redirect the resolver's stderr (rtl_default_log) — direct callers keep the diagnostics.
    def _warn(msg):
        if not quiet:
            print(msg, file=sys.stderr)
    target_root = (target_root or "").rstrip("/")
    ar = os.environ.get("XYZ_ARCHIVE_ROOT", "")
    if not ar:
        return f"{target_root}/relay-system"
    if not os.path.isabs(ar):
        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: {ar}")
        return None
    if not os.path.isdir(ar):
        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): {ar}")
        return None
    if subprocess.run(["git", "-C", ar, "rev-parse", "--git-dir"],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): {ar}")
        return None
    return f"{ar}/relay-system/{_rtl_repo_slug(target_root)}"

def rtl_default_log(root, tool, task):
    # GH-161: persistent turn-transcript path under <transcript-root>/logs/<date>/, falling back to
    # $TMPDIR when the transcript root can't be resolved/created. Mirrors Bash rtl_default_log.
    fallback = os.path.join(tempfile.gettempdir(), f"{tool}-{os.getpid()}.log")
    base = _rtl_transcript_root(root, quiet=True)   # Bash redirects the resolver's stderr here
    if not base:
        return fallback
    tslug = _ascii_slug(task or "")
    try:
        day = subprocess.check_output(["date", "+%Y-%m-%d"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        day = "unknown-date"
    path = os.path.join(base, "logs", day, f"{tool}-{tslug}-{os.getpid()}.log")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return path
    except Exception:
        return fallback

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
