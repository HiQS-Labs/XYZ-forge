import os
import shlex
import subprocess
import tempfile
import sys

# GH-375 — agy's auth pre-flight cannot decide on exit status alone. `agy whoami` EXITS 0 while
# failing to run at all when there is no TTY ("CLI error: bubbletea: error opening TTY: ... open
# /dev/tty: device not configured"), and every marathon or driven relay turn is headless, so that is
# the NORMAL path under automation rather than an edge case. Both callers (agy-turn.py, consult.py)
# had the same shape and the same hole, so the verdict lives here once rather than in two copies
# that can drift.
#
# Matched as line PREFIXES, not as a bare "error" substring anywhere in the output. `whoami` prints
# ACCOUNT IDENTITY on success — a substring test would fail any lane whose handle, org, or banner
# happens to contain "error", and a false failure stops the run outright, which is a worse outcome
# than the bug being fixed. The TTY signature is matched separately: it is the exact shape the issue
# reports and it does not necessarily carry an error prefix.
# GH-375 follow-up. AGY_AUTH_TIMEOUT_S defaulted to 5 while `agy whoami` cost 1.3-2.3s idle on the
# reference machine — under 2x headroom, and concurrent load closed it twice. The second time was AFTER
# the timeout branch was taught to reclassify a TTY-diagnosed timeout as unverifiable: the probe was
# killed before it could FLUSH its diagnostic, so the capture was empty, the reclassification had
# nothing to match on, and the lane was blocked anyway. That flush race was predicted by one reviewer
# and dismissed by another (and by me) as bounded; it then fired in the next consult and cost the agy
# seat. Observed, so no longer a judgement call.
#
# 20s is chosen against the measurement, not by feel: ~9x the worst idle probe, which leaves room for
# the load that closed a 2x margin. The cost is bounded and lands only on a genuine interactive-login
# hang, which now takes 20s to reject instead of 5 — a rare path, and rejecting it late is cheaper than
# blocking a working lane. Same reasoning as GH-457's tiers: size a cap against what the thing actually
# costs, not against a number that looks tidy.
AGY_AUTH_TIMEOUT_DEFAULT_S = 20
WORST_OBSERVED_WHOAMI_S = 2.3   # 1.3 / 1.9 / 2.3 measured idle, 2026-08-09

AGY_AUTH_ERROR_PREFIXES = ("cli error:", "error:", "panic:", "fatal:")
AGY_AUTH_TTY_MARKERS = ("could not open tty", "error opening tty")


def agy_auth_output_verdict(out_file):
    """Classify agy's own probe output. Returns (severity, message).

    severity is one of:
      ""              — nothing suspicious; treat the probe as passed.
      "unverifiable"  — the probe COULD NOT RUN, so it established nothing either way. Report it
                        loudly; do NOT fail the lane on it.
      "failed"        — the probe ran and agy reported an error. Fail the lane.

    THE THIRD STATE IS THE WHOLE POINT, and it was learned the expensive way. GH-375's suggested fix
    was to treat the TTY error as a failed probe and stop the turn. That was implemented literally and
    it broke the agy lane outright: test/relay-self-sufficiency.sh went 4/0 to 0/4 with `agy shim
    exited 5`, on a machine where agy was signed in and working.

    The measurement that settles it, taken on this repo:

      * `agy whoami` cannot run headless at all. It exits 0 while printing
        `CLI error: bubbletea: error opening TTY: ... /dev/tty: device not configured`.
      * `agy -p` — the print mode the ACTUAL turn uses — runs headless perfectly well. The live turn
        in relay-self-sufficiency.sh claims its token, writes the relay file and commits.

    So a TTY error from `whoami` says nothing about whether auth works; it says this probe is the
    wrong instrument in this environment. Treating it as failure converts an unmeasurable check into
    a hard block on a lane that demonstrably works — strictly worse than the bug GH-375 reported,
    which merely let a possibly-unauthed lane proceed. One of two working builders, stopped by its
    own guard.

    What GH-375 established stands and is preserved: exit status alone cannot decide this, and the
    captured output must not be deleted. Those were the real defects. The inference "the probe could
    not run, therefore auth is bad" is the part that does not follow.
    """
    try:
        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
            output = f.read()
    except OSError:
        return ("unverifiable", "the probe produced no readable output")
    # EMPTY OUTPUT IS NOT TREATED AS FAILURE, deliberately. "A probe that establishes nothing must
    # not report success" is a tempting rule and it was written here first — then it failed a turn
    # within minutes: test/gh410-containment-advisory.sh's agy stub prints nothing for `whoami`, so
    # the pre-flight rejected it, the turn exited 5 before running, and a containment assertion that
    # had nothing to do with auth went red. That is the false-failure direction this function's whole
    # matching strategy is built to avoid, and it arrived on first contact.
    #
    # The asymmetry is the point: agy exiting 0 with a VISIBLE error is observed and documented
    # (GH-375). Agy exiting 0 SILENTLY on success is not something this repo can rule out, and
    # guessing wrong there breaks every turn in the fleet rather than one. Match the evidence that
    # exists; do not infer failure from the absence of evidence. stderr is folded into this capture,
    # so a real error has somewhere to appear.
    for raw in output.splitlines():
        line = raw.strip()
        low = line.lower()
        # TTY FIRST, and it must stay first: agy's TTY banner is itself prefixed `CLI error:`, so the
        # error-prefix branch below would otherwise claim it and fail a lane that is perfectly fine.
        if any(m in low for m in AGY_AUTH_TTY_MARKERS):
            return ("unverifiable", f"agy could not run headless, so auth was not verified: {line}")
        if any(low.startswith(p) for p in AGY_AUTH_ERROR_PREFIXES):
            return ("failed", f"agy reported an error: {line}")
    return ("", "")


def agy_auth_timeout_verdict(out_file):
    """Classify a probe that TIMED OUT. Returns (severity, message) — never "".

    A separate function from agy_auth_output_verdict on purpose. That one reads an output stream from
    a process that EXITED, where "nothing suspicious" legitimately means pass. A timeout has no exit
    status to interpret, and silence there is not reassurance — so this function never returns the
    pass verdict, and reusing the other one here would have converted a hung probe into a green one.

    GH-375 follow-up. The three-state fix covered `whoami` EXITING with a TTY error. It did not cover
    the probe blowing its timeout, which still went straight to fatal — and that is the branch that
    actually fired: a /consult on 2026-08-09 lost its agy seat to

        consult: agy auth pre-flight timed out after 5s; likely expired auth opening an interactive
                 login. Run `agy login` in a normal terminal, then retry.

    on a machine where, measured in the same minute, `agy whoami` printed the TTY error and `agy -p`
    (what the turn actually uses) answered correctly. A false block, from the guard, on a working lane
    — the same failure direction GH-375's own fix was written to avoid, one branch over.

    The rule: reclassify ONLY on positive evidence of the TTY cause. If the captured output already
    says agy could not open a TTY, the timeout carries no more information about auth than the fast
    failure did — on a platform where `whoami` can never succeed headlessly, a timeout is just a
    slower spelling of the same thing. Anything else — an interactive login prompt, an unfamiliar
    error, or NO output at all — stays fatal, which keeps the branch's original purpose intact for a
    genuine hang on a login prompt.

    Deliberately narrower than "a timeout is unverifiable". That broader rule would also swallow the
    real hang this branch exists to catch, and silence is exactly the shape a login prompt waiting on
    stdin produces.
    """
    try:
        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
            output = f.read()
    except OSError:
        output = ""
    for raw in output.splitlines():
        line = raw.strip()
        if any(m in line.lower() for m in AGY_AUTH_TTY_MARKERS):
            return ("unverifiable",
                    "agy could not open a TTY and then exceeded the probe timeout, so auth was not "
                    f"verified (the timeout is the same TTY failure, slower): {line}")
    return ("failed", "the probe timed out with no TTY diagnostic, which is the shape of a genuine "
                      "hang on an interactive login prompt")


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
    #
    # GH-417: --show-toplevel returns the PHYSICAL path, so ROOT can differ in symlink form from a
    # relay-file path the caller built from its own $PWD. That is survivable, not accidental:
    # relay-turn-lib.sh's rtl_init canonicalizes both sides before stripping (GH-261, 312a2c3), and
    # claim_paths_for_turn above does the same natively. Read the "caught live" warning at
    # relay-turn-lib.sh's GH-160 collapse as scoped to that collapse — it is not an argument against
    # this default. Pinned by test/gh417-turn-root-symlink-prefix.sh, whose control shows the exit-6
    # failure returning the moment that canonicalization is removed.
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


# GH-410: ADVISORY ONLY — never a verdict.
#
# `worktree_end` above is the containment verdict: it diffs the worktree's own git state, so it
# observes writes that actually happened, and all five turn shims exit 6 on it identically.
#
# This function answers a strictly weaker question — does the transcript NAME the real repo root —
# and the two diverge in both directions. An agent that quietly touched the real tree without naming
# it is not detected here; an agent that merely cites an absolute path in a finding is. Measured
# (#410): two phases in one run, same builder and same isolation settings, where the one with TEN
# repo-root mentions was Approved and the one with NINE failed three consecutive times.
#
# It used to fail the turn, which discarded completed reviews. Three exemption patches were spent
# trying to make it precise (#183 `TICK_REPO_ROOT=`, #187 `file://` and `](`) and a fourth shape was
# still outstanding: the harness's own retry preamble renders absolute paths into the relay file, so
# an agent following instructions writes the trigger into its own transcript.
#
# Do NOT re-promote this to a verdict without first making reads observable. If that ever happens,
# the seeding in marathon_drive's retry preamble has to be fixed first.
def narration_mentions_root(log_path, root):
    """Count transcript lines naming `root`, ignoring known-benign shapes. (count, first_line).

    Returns (0, None) when the log is missing, empty, or names nothing. The exemptions are kept only
    to stop the advisory from being pure noise — they are no longer load-bearing, because nothing
    fails on this result.
    """
    if not root or not log_path or not os.path.exists(log_path):
        return 0, None
    try:
        if os.path.getsize(log_path) == 0:
            return 0, None
    except OSError:
        return 0, None

    count, first = 0, None
    try:
        with open(log_path, "r", errors="replace") as fh:
            for line in fh:
                if line.startswith("[trace] "):
                    continue
                if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
                    continue
                if root in line:
                    count += 1
                    if first is None:
                        first = line.strip()
    except OSError:
        return 0, None
    return count, first

def driver_lock_path(root):
    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
    # SAME path or it probes a location the driver never writes and reports a live run as idle.
    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
    #   no .git (vendored)   -> <root>/.relay-driver.lock                    (vendored .xyz/ copy)
    # Returns (lock_path, lock_label) — lock_label is always the SHORT display form used in messages.
    git_path = os.path.join(root, ".git")
    if os.path.isdir(git_path):
        return os.path.join(root, ".git", "relay-driver.lock"), ".git/relay-driver.lock"
    if os.path.isfile(git_path):
        common = ""
        try:
            common = subprocess.check_output(
                ["git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir"],
                stderr=subprocess.DEVNULL).decode("utf-8").strip()
        except Exception:
            common = ""
        if common:
            return os.path.join(common, "relay-driver.lock"), ".git/relay-driver.lock"
    return os.path.join(root, ".relay-driver.lock"), ".relay-driver.lock"
