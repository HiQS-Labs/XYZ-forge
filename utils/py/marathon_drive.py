import argparse
import os
import signal
import sys
import subprocess
import time
import re
import shlex
import shutil
import json
import tempfile
import threading
import datetime as _dt

# Import rtl relative to this file (utils/py/), independent of CWD/PYTHONPATH — needed because some
# callers load this module via importlib.util.spec_from_file_location rather than `python3 <path>`,
# which does NOT put the script's own directory on sys.path (GH-448 regression, test/gh322-runlog-
# python-lane.sh caught it). Same pattern as marathon_plan.py's `_marathon_plan` import.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rtl import driver_lock_path  # noqa: E402

# GH-284 Phase 2 / GH-322: hooks run on EVERY terminal path with the driver's real exit code — the
# Python equivalent of marathon-drive.sh's `trap _marathon_drive_on_exit EXIT`. Same contract as
# that trap: the code is captured FIRST and re-exited explicitly, so nothing a hook does can
# overwrite the driven run's real status.
_ON_EXIT = []


# GH-333: the run log used to carry a `driver still running` line that could only ever say
# "running". Dropping it left `driver exit: `3`` as the sole disposition signal — a bare number the
# reader has to look up. Naming it is the half of that field which was actually worth keeping.
#
# Codes 1, 2 and 8 are mapped defensively but cannot appear in a posted run log: lock contention,
# `die()` and the lane-attempt cap all exit BEFORE the run log arms (drive_started).
_EXIT_MEANINGS = {
    0: "approved, gate passed",
    1: "driver lock contention",
    2: "usage or configuration error",
    3: "no-progress escalation",
    4: "round-cap or close-mismatch escalation",
    5: "pre-advance gate failed",
    6: "containment violation — off-lane edit reverted",
    7: "turn timeout / hang",
    8: "lane parked at the attempt cap",
    9: "post-approve command failed, approval preserved",
    127: "relay-drive could not execute — check MARATHON_RELAY_DRIVE",
}


def _exit_meaning(code):
    """Plain-language gloss for a marathon-drive exit code, for the run log.

    Deliberately total: an unmapped code must still render, and must say plainly that it is
    unrecognised rather than silently printing an empty parenthetical that reads like a meaning.
    """
    try:
        code = int(code)
    except (TypeError, ValueError):
        return "unrecognised exit code"
    return _EXIT_MEANINGS.get(code, "unrecognised exit code")


def runlog_find_comment_id(payload_text, marker):
    """Return the id of the run-log comment carrying <marker>, or "" if there is none.

    `gh api --paginate --slurp` yields an ARRAY OF PAGES ([[c,...],[c,...]]); a single page, or a
    non-slurp fallback, yields a flat [c,...]. Accept both — a miss here POSTs a duplicate comment
    instead of updating in place, which is the one property this feature is defined by.

    Deliberately at module scope, not nested in main(): in the Bash twin the equivalent parser could
    only be reached by shipping it to a python3 subprocess, and the INVOCATION shape (`python3 -
    <<EOF` while also piping data in — shellcheck SC2259) silently broke it. The comments JSON was
    prepended to the program text, python died with a SyntaxError, the id came back empty, and the
    run log POSTed a duplicate every single time. test/gh284-runlog-heartbeat.sh missed that for a
    release because it exercised the parser from a FILE, which is not how the driver ran it. Running
    in-process kills the whole failure class, and keeping it importable means a test can exercise the
    real function rather than a reimplementation of it.
    """
    try:
        payload = json.loads(payload_text)
    except Exception:
        payload = []
    comments = []
    if isinstance(payload, list):
        for entry in payload:
            if isinstance(entry, list):
                comments.extend(entry)
            elif isinstance(entry, dict):
                comments.append(entry)
    for comment in comments:
        if isinstance(comment, dict) and marker in str(comment.get("body", "")):
            return str(comment.get("id", ""))
    return ""

# ── Sentinel Tier 1 (GH-281), ported to the lane that runs (GH-342) ──────────────────────────
# marathon-drive.sh carried this capture; Python is the default lane since GH-264, so arming
# XYZ_DEBUG_LOG=1 on a normal run wrote nothing. Contract preserved exactly, including the parts
# that make it safe to leave in a public repo:
#   · opt-in, DEFAULT OFF — an unset/0 XYZ_DEBUG_LOG must not create the file at all
#   · writes ONE local file ($DEBUG_LOG_FILE, default $ROOT/debug.log) — no network, no telemetry
#   · NEVER fails the run: every write is best-effort and swallows its own errors
# Module scope, not nested in main(), so the record shape is directly testable (the GH-322
# runlog_find_comment_id precedent — a helper reachable only through a full driven run is a helper
# whose format contract is asserted by nothing).
_JSON_CTRL_RE = re.compile(r'[\x00-\x1f\x7f]')


def _json_esc(value):
    """Bash `_json_esc`: normalize all C0/DEL controls to a space, then escape backslash + quote.

    Mirrors `printf '%s' "$s" | tr '\\000-\\037\\177' ' '` — a byte-for-byte translation, so a
    multi-byte UTF-8 sequence is untouched (Python operates on code points; `tr` on bytes; the
    ranges here are all < 0x80, where the two agree).
    """
    return _JSON_CTRL_RE.sub(" ", "" if value is None else str(value)) \
        .replace("\\", "\\\\").replace('"', '\\"')


def xyz_debug_log_enabled():
    """The single gate. Read at call time, not import time, so a test can arm it per-case."""
    return os.environ.get("XYZ_DEBUG_LOG", "0") == "1"


def xyz_debug_log_file(root):
    """`: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"` — an explicitly EMPTY value falls back too."""
    return os.environ.get("DEBUG_LOG_FILE") or os.path.join(root, "debug.log")


def _xyz_debug_log_write(root, line):
    """Append one line, swallowing everything. Mirrors `>> "$f" 2>/dev/null || true`."""
    try:
        with open(xyz_debug_log_file(root), "a") as fh:
            fh.write(line)
    except Exception:
        pass


def xyz_debug_log_append(root, severity, check, message,
                         file="", action="", probe="",
                         target_root=None, phase_id=None, relay_task=None):
    """Append ONE PDDA-output-contract JSONL finding. No-op unless XYZ_DEBUG_LOG=1.

    Field order and the empty `line` field are load-bearing: this file is consumed by the Sentinel
    tooling as a fixed record shape, and the Bash lane emits exactly this. Built with a format
    string rather than json.dumps for the same reason — json.dumps would escape correctly but is
    free to differ on separators, and the two lanes must produce identical bytes.
    """
    if not xyz_debug_log_enabled():
        return
    scope = f"target:{target_root}" if target_root else "harness"
    _xyz_debug_log_write(root, (
        '{"timestamp":"%s","severity":"%s","check":"%s","scope":"%s","repo":"%s","phase":"%s"'
        ',"task":"%s","file":"%s","line":"","message":"%s","action":"%s","probe":"%s"}\n'
    ) % (
        _utc_now_z(),
        _json_esc(severity), _json_esc(check), _json_esc(scope),
        _json_esc(target_root or root), _json_esc(phase_id or ""), _json_esc(relay_task or ""),
        _json_esc(file), _json_esc(message), _json_esc(action), _json_esc(probe),
    ))


def xyz_debug_log_stale_lock(root):
    """The stale-lock reclaim record.

    Deliberately NOT routed through xyz_debug_log_append: `marathon-drive.sh:220` inlines a SHORTER
    record here (no phase/task/file/line/probe) because the helper is not defined that early in the
    Bash file, and it leaves `repo` unescaped. Reproduced as-is — the two lanes must agree, and
    "improving" the shape on one lane only is how the drift this issue exists to fix gets recreated.
    The inconsistent shape is worth fixing on BOTH lanes, separately and on purpose.
    """
    if not xyz_debug_log_enabled():
        return
    _xyz_debug_log_write(root, (
        '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness"'
        ',"repo":"%s","message":"stale driver lock reclaimed","action":"none (auto-healed)"}\n'
    ) % (_utc_now_z(), root))


def xyz_harvest_findings(harvest_bin, relay_file, root, target_root, debug_log):
    """Spawn harvest-findings.sh to pull a relay's Side Findings into the debug log.

    Gated on XYZ_DEBUG_LOG=1 AND the script being executable, exactly as the two Bash call sites
    are (`marathon-drive.sh:849`, `:881`). Output discarded, exit code ignored: a harvest failure
    must not change the driven run's own status.
    """
    if not xyz_debug_log_enabled():
        return
    if not (harvest_bin and os.access(harvest_bin, os.X_OK)):
        return
    try:
        subprocess.run(
            [harvest_bin, "--relay", relay_file,
             "--scope", (f"target:{target_root}" if target_root else ""),
             "--repo", (target_root or root),
             "--out", debug_log],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def _utc_now_z():
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_env(key, default=None):
    return os.environ.get(key, default)

def die(msg):
    eprint(f"marathon-drive: {msg}")
    sys.exit(2)

def log(msg):
    print(f"marathon-drive: {msg}")

def run_tick_loud(cmd_args):
    """Run a tick command, and on failure print what tick said before exiting on it (GH-408).

    The name always promised this. The body did the opposite: it sent stdout AND stderr to DEVNULL
    and then `sys.exit(res.returncode)`, so the one path guaranteed to end the run was also the one
    guaranteed to explain nothing. A token-seeding failure halted a marathon with no message and an
    exit code nothing maps — the caller saw a bare non-zero from a step it could not name.

    Success stays silent, deliberately. These calls run several times per phase (log, claim, release,
    phase.start); echoing `won:`/`released:` each time would add steady noise to every transcript for
    no diagnostic gain, and noise is how the useful line gets skipped.

    Lifted from a closure inside main() to module level so a test can call it directly — the previous
    nesting meant the only way to observe this behaviour was to drive a whole marathon phase.
    """
    tr_root = os.environ.get("TICK_REPO_ROOT") or os.environ.get("MARATHON_ROOT")
    env = os.environ.copy()
    if tr_root:
        env["TICK_REPO_ROOT"] = tr_root
    res = subprocess.run(cmd_args, capture_output=True, text=True, env=env, cwd=tr_root if (tr_root and os.path.isdir(tr_root)) else None)
    if res.returncode != 0:
        label = " ".join(str(a) for a in cmd_args[1:3]) or "tick"
        eprint(f"marathon-drive: tick {label} failed (exit {res.returncode}):")
        for stream in (res.stdout, res.stderr):
            for line in (stream or "").splitlines():
                eprint(f"  {line}")
        sys.exit(res.returncode)

def preflight_write_set_trackable(repo_root, paths):
    """GH-514: BLOCK before dispatch if the repo cannot track a path this run must commit.

    `git check-ignore -v` is the authority rather than a hand-rolled read of `.gitignore`: it
    consults every source git itself consults (repo .gitignore at any depth, .git/info/exclude, the
    global core.excludesFile) and reports WHICH rule matched, in `<source>:<line>:<pattern>` form.
    Re-implementing that matching would produce a check that disagrees with the tool whose behaviour
    it is trying to predict — and disagreeing quietly is the failure being fixed.

    Exit status contract: 0 = ignored (the bad case here), 1 = not ignored, 128 = error. An error is
    treated as NOT ignored, deliberately: this guard exists to stop a known halt, and it must not
    invent a new way for a healthy run to fail. A repo where check-ignore cannot run is one where the
    old behaviour — find out at `git add` — is no worse than refusing on a guess.
    """
    blocked = []
    for p in paths:
        try:
            res = subprocess.run(["git", "-C", repo_root, "check-ignore", "-v", "--no-index", p],
                                 capture_output=True, text=True)
        except Exception:
            continue
        if res.returncode == 0 and res.stdout.strip():
            matched_line = res.stdout.strip().splitlines()[0]
            fields = matched_line.split("\t", 1)[0].split(":")
            if len(fields) >= 3 and fields[2].startswith("!"):
                continue
            blocked.append((p, matched_line))

    if not blocked:
        return

    eprint("marathon-drive: BLOCKED before dispatch — this repo cannot track files this run must commit.")
    for p, rule in blocked:
        rel = p[len(repo_root) + 1:] if p.startswith(repo_root + "/") else p
        eprint(f"  {rel}")
        eprint(f"    ignored by: {rule}")
    eprint("")
    eprint("  Nothing has been dispatched, so no builder turn has been spent. Left unchecked this")
    eprint("  surfaces as a phase HALT after the turn, and on the escalation path the record")
    eprint("  explaining the halt is itself one of the files that cannot be committed.")
    eprint("")
    eprint("  Remedy, in the order they are usually right:")
    eprint("    1. Run with --target-root <code-repo>. Harness output (relay, escalation,")
    eprint("       transcripts) then stays in THIS repo and only code changes land in the target —")
    eprint("       which is what --target-root is for, per marathon.sh's own usage text.")
    eprint("    2. Or un-ignore the path above in the rule named beside it, if this repo is meant")
    eprint("       to track harness output.")
    eprint("  Not doing it for you: a repo that ignores harness output usually means it, and")
    eprint("  silently rewriting someone's ignore rules is a worse failure than this one (GH-514).")
    sys.exit(2)

def _repo_rel_prefix(path, root):
    """GH-484: `path` as a repo-relative prefix with a trailing slash, for matching the paths
    `git status --porcelain` emits (which are relative to the repo TOPLEVEL, not to `root` —
    the two differ for a vendored install whose root is <repo>/.xyz). Returns "" when `path`
    lies outside the repo, meaning "matches nothing", which is correct: git never lists it.

    realpath, NOT abspath, on both sides: `git rev-parse --show-toplevel` always reports the
    PHYSICAL path, so a repo reached through a symlinked ancestor (macOS /var and /tmp, plenty of
    home and network mounts) yields "/private/var/..." from git and "/var/..." from the argument.
    abspath preserves that split, the prefix test fails, and the exclusion silently stops working —
    caught by test/gh484-phase-dir-default.sh case (3), which runs out of exactly such a dir."""
    try:
        top = subprocess.check_output(["git", "-C", root, "rev-parse", "--show-toplevel"],
                                      stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        top = root
    rel = os.path.relpath(os.path.realpath(path), os.path.realpath(top or root))
    if rel == os.curdir or rel.startswith(os.pardir + os.sep) or rel == os.pardir:
        return ""
    return rel.rstrip("/") + "/"

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
    elif agent_id.startswith("pi"):
        _probe_bin(get_env("PI_BIN", "pi"), role_label, agent_id)

# GH-390 coverage seam.  Keep the attribution decision outside main() so its four
# platform/Bash return-code shapes can be exercised on every host without executing
# a full marathon or relying on that host's RLIMIT_CPU behaviour.
GATE_GUARD_KILL_EXIT = 108
GATE_CPU_HARD_MARGIN_S = 5


# GH-457: the gate's caps come from a TIER, because one wall cap cannot serve both jobs.
#
# The single 900s cap stopped meaning anything. Measured on one host inside 24 hours, same suite:
#
#     2026-08-07              ~704-806s
#     2026-08-08 evening       878.8s wall / 532.5s CPU   (loaded, 60% CPU)
#     2026-08-08 marathon r3    957s                      (in-marathon, real gate invocation)
#     shipped caps              900s wall / 600s CPU
#
# The suite did not grow ~250s in a day; that drift is machine contention. So a 900s cap was
# measuring how busy the laptop was, which is not a property of the change under test — and a fully
# GREEN validate.sh returned `gate-killed` (108) at the default, a resource kill dressed as a
# verdict, which is exactly #407's failure mode. Both Litmus wave-2 runs had to pass a run-time
# override to avoid it, and a guard that always needs an override is a speed bump that only fires
# when someone forgets.
#
# Raising the single default to 1800 was the other option and was rejected: it buys headroom and
# changes nothing structural, so the next lane that adds a suite spends it and this recurs.
#
# Tiers restore the cap's meaning. `fast` is sized so that an overrun is unambiguously a runaway
# (nothing legitimate in that tier runs for minutes). `full` is sized for the honest long suite with
# real headroom over the worst observed run. A cap only means "runaway" if legitimate work cannot
# plausibly reach it.
#
# The tier is ONE place to look, by design: no filename patterns, no ordering rules. Per-variable
# env overrides still win over the tier, so a phase can retune a single cap without leaving its tier.
GATE_TIERS = {
    # tier   wall_s  cpu_s   sized from
    "fast": {"wall_s": 300, "cpu_s": 240},    # a targeted gate; minutes here means runaway
    "full": {"wall_s": 1800, "cpu_s": 1200},  # ~1.9x the worst observed 957s wall / 532.5s CPU
}
GATE_DEFAULT_TIER = "full"
# RSS is deliberately NOT tiered and NOT changed. Measured on the crash host (Darwin 24.6, arm64):
# setrlimit(RLIMIT_AS) and setrlimit(RLIMIT_DATA) are both REFUSED, even soft-only, so the
# process-group RSS poll is the only layer standing between a runaway test and this host. Retuning
# it alongside the CPU/wall tiers would confound two changes at once.
GATE_RSS_MB_DEFAULT = 8192


def _gate_tier():
    """Resolve the gate tier, falling back loudly rather than inventing caps for an unknown name."""
    name = (os.environ.get("MARATHON_GATE_TIER") or "").strip() or GATE_DEFAULT_TIER
    if name not in GATE_TIERS:
        log(f"gate-guard: unknown tier {name!r} — falling back to {GATE_DEFAULT_TIER!r} "
            f"(known: {', '.join(sorted(GATE_TIERS))})")
        name = GATE_DEFAULT_TIER
    return name


def _gate_guard_config():
    """Read the guard's caps fresh on each gate run, so a phase can retune between calls."""
    def _cap(name, default):
        raw = os.environ.get(name, "").strip()
        if not raw:
            return default
        try:
            value = int(raw)
        except ValueError:
            log(f"gate-guard: {name}={raw!r} is not an integer — falling back to {default}")
            return default
        return value
    tier = _gate_tier()
    base = GATE_TIERS[tier]
    return {
        "tier": tier,
        "wall_s": _cap("MARATHON_GATE_WALL_S", base["wall_s"]),
        "cpu_s": _cap("MARATHON_GATE_CPU_S", base["cpu_s"]),
        "rss_mb": _cap("MARATHON_GATE_RSS_MB", GATE_RSS_MB_DEFAULT),
        "poll_s": max(1, _cap("MARATHON_GATE_POLL_S", 1)),
    }


def _gate_group_rss_mb(pgid):
    """Summed RSS (MB) of a gate process group, or -1 when it cannot be read."""
    try:
        out = subprocess.run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True,
                             timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return -1
    total_kb = 0
    for line in out.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue
        try:
            if int(parts[0]) == pgid:
                total_kb += int(parts[1])
        except ValueError:
            continue
    return total_kb // 1024


def _gate_kill_group(proc, reason):
    """TERM the whole gate process group, then KILL whatever ignored it."""
    log(f"gate-guard: KILLING gate process group (pgid {proc.pid}) — {reason}")
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(proc.pid, sig)
        except (ProcessLookupError, PermissionError, OSError) as exc:
            log(f"gate-guard: killpg({proc.pid}, {sig!r}) failed: {exc}")
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                return
            time.sleep(0.1)
    proc.wait()


def gate_guard_cpu_attribution(returncode, cpu_s):
    """Return (guard_exit_code, diagnostic) for a CPU-limit result.

    This intentionally recognizes only the two signals the guard itself can cause,
    in both Bash reporting shapes.  Every other gate failure remains a red gate.
    """
    if cpu_s <= 0:
        return returncode, None
    if returncode in (128 + signal.SIGXCPU, -signal.SIGXCPU):
        return (GATE_GUARD_KILL_EXIT,
                f"gate-guard: gate exceeded the {cpu_s}s CPU cap (SIGXCPU)")
    if returncode in (128 + signal.SIGKILL, -signal.SIGKILL):
        return (GATE_GUARD_KILL_EXIT,
                f"gate-guard: gate ignored SIGXCPU and hit the "
                f"{cpu_s + GATE_CPU_HARD_MARGIN_S}s hard CPU cap (SIGKILL)")
    return returncode, None


def _phase_memory_sample(tag="", root=None, tick_bin=None, relay_task=None):
    """Sample host memory (compressor and free swap) at phase boundary (GH-382)."""
    compressor_mb = None
    swap_free_mb = None
    if sys.platform == "darwin":
        try:
            out = subprocess.run(["sysctl", "-n", "vm.swapusage"], capture_output=True, text=True, timeout=5).stdout
            # format: total = 3072.00M  used = 1024.00M  free = 2048.00M  (encrypted)
            import re
            m = re.search(r"free\s*=\s*([0-9.]+)([MGK]?)", out)
            if m:
                val = float(m.group(1))
                unit = m.group(2)
                if unit == "G": val *= 1024
                elif unit == "K": val /= 1024
                swap_free_mb = int(val)
        except Exception:
            pass
        try:
            out = subprocess.run(["vm_stat"], capture_output=True, text=True, timeout=5).stdout
            import re
            m = re.search(r"Pages occupied by compressor:\s*([0-9]+)", out)
            if m:
                pages = int(m.group(1))
                compressor_mb = (pages * 4096) // (1024 * 1024)
        except Exception:
            pass
    elif os.path.exists("/proc/meminfo"):
        try:
            with open("/proc/meminfo", "r") as f:
                for line in f:
                    if line.startswith("SwapFree:"):
                        swap_free_mb = int(line.split()[1]) // 1024
                    elif line.startswith("Zswap:") or line.startswith("Zswapped:"):
                        compressor_mb = int(line.split()[1]) // 1024
        except Exception:
            pass

    bits = []
    if compressor_mb is not None:
        bits.append(f"compressor={compressor_mb}MB")
    if swap_free_mb is not None:
        bits.append(f"swap_free={swap_free_mb}MB")
        if swap_free_mb < 1024:
            log(f"warn: host free swap is critically low ({swap_free_mb}MB < 1024MB)")
    if bits:
        log(f"memory-telemetry: phase {tag} boundary — {', '.join(bits)}")

    if tick_bin and relay_task and os.path.isfile(tick_bin) and os.access(tick_bin, os.X_OK):
        extra = []
        if compressor_mb is not None:
            extra.extend(["--compressor-mb", str(compressor_mb)])
        if swap_free_mb is not None:
            extra.extend(["--swap-free-mb", str(swap_free_mb)])
        if extra:
            try:
                subprocess.run([tick_bin, "cost", relay_task, "--agent", "marathon"] + extra, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass
    return {"compressor_mb": compressor_mb, "swap_free_mb": swap_free_mb}


def main():
    parser = argparse.ArgumentParser(description="marathon-drive", add_help=False)
    parser.add_argument("--phase-brief", dest="phase_brief_file")
    parser.add_argument("--builder", dest="builder", default="codex")  # GH-212: no per-call API charge
    parser.add_argument("--reviewer", dest="reviewer")
    parser.add_argument("--round-cap", dest="round_cap", type=int, default=5)
    parser.add_argument("--pre-advance-cmd", dest="pre_advance_cmd")
    parser.add_argument("--pre-advance-baseline", dest="pre_advance_baseline", help="allow gate failures matching recorded baseline exit code (GH-378)")
    parser.add_argument("--post-approve-cmd", dest="post_approve_cmd")
    parser.add_argument("--phases-dir", dest="phases_dir")
    parser.add_argument("--phase-id", dest="phase_id", default="p1")
    parser.add_argument("--relay-task", dest="relay_task")
    parser.add_argument("--artifact", dest="artifact_paths")
    parser.add_argument("--target-root", dest="target_root")
    parser.add_argument("--require-clean", dest="require_clean", action="store_true")
    parser.add_argument("--requires-test", dest="requires_test")  # GH-249: nominated test must change
    parser.add_argument("--force", dest="force", action="store_true")
    # GH-402: deliberately NOT folded into --force. --force bypasses the per-lane attempt cap, which
    # is a "you have tried this too often" bound; this is a "you are about to commit to trunk" bound.
    # One flag for both would mean an operator retrying a flaky lane silently acquires permission to
    # land on main, which is the kind of coupling that is obvious only after it happens.
    parser.add_argument("--allow-trunk-commit", dest="allow_trunk_commit", action="store_true",
                        help="permit committing to the receiving repo's trunk/default branch (GH-402)")
    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    parser.add_argument("--log-github", dest="log_github", action="store_true")  # GH-284 P2 / GH-322
    parser.add_argument("--help", action="store_true")

    args, unknown = parser.parse_known_args()
    if args.help:
        print("Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]")
        print("  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).")
        print("  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).")
        print("                           Failure preserves approval, writes reason post-approve-failed, and exits 9.")
        print("  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub")
        print("                          issue in place via a marker comment — never creates an issue, never closes")
        print("                          one. A missing/unauthenticated gh degrades to local telemetry only.")
        sys.exit(0)

    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
    # headline feature of GH-284 Phase 2, which existed only in the Bash twin — a no-op: the marathon
    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
    # Checked AFTER --help so `--help` still works alongside a bad flag.
    # (--log-github is now a real flag on this lane too — see marathon_run_github_log below. The
    # temporary "re-run with XYZ_PYTHON=0" message this branch used to carry is gone with the port.)
    if unknown:
        die(f"unknown argument: {unknown[0]}")

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
    # GH-342: `$HERE/harvest-findings.sh` in the Bash twin — HERE is relay-automation/, which for the
    # Python lane is a sibling of utils/py's grandparent. Resolved once; both call sites re-check
    # os.access(X_OK) at spawn time, so a harness missing the script simply harvests nothing.
    harvest_findings_bin = os.path.join(xyz_harness, "relay-automation", "harvest-findings.sh")

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
            # Sentinel Tier 1 (GH-281/GH-342). The Bash lane emits this from the CALLER, on rc==8
            # (marathon-drive.sh:1103-1106); this gate exits directly, so it emits here instead —
            # same record, same position relative to the two messages above. `raw`, not `key`: the
            # Bash message carries $LANE_STATE_KEY as given, not the sanitized form.
            xyz_debug_log_append(
                root, "warn", "marathon.lane-park",
                f"lane {raw} parked at attempt cap",
                action="re-anchor to QUEUE lanes or re-fire with --force",
                target_root=args.target_root, phase_id=args.phase_id,
                relay_task=relay_task)
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

    def debug_mantra_prior_attempts(root_dir, raw):
        # GH-162: READ-ONLY peek at the .tick/attempts/<lane> file GH-45 maintains — how many prior
        # fires on this lane did not reach Approved. Never writes.
        f = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
        if os.path.isfile(f):
            try:
                with open(f) as fh:
                    return sum(1 for _ in fh)
            except Exception:
                return 0
        return 0

    def debug_mantra_note(prior, phase_dir_, mantra_file):
        # GH-162: the note injected into the relay when a prior attempt exists; empty on a first fire
        # (prior=0) so a normal first-fire relay file stays byte-identical to before this feature.
        if not prior or prior < 1:
            return ""
        reason = ""
        esc = os.path.join(phase_dir_, "ESCALATION.md")
        if os.path.isfile(esc):
            try:
                with open(esc) as fh:
                    for line in fh:
                        if line.startswith("reason:"):
                            reason = line.split(":", 1)[1].strip()
                            break
            except Exception:
                pass
        # GH-410: name the files once, with their directories stated once, instead of repeating a
        # full absolute path per line. This preamble renders ONLY on a retry, so the old form handed
        # every re-attempt extra copies of the repo root — a recovery path that raised the very
        # hazard it was retrying against, back when the containment scan failed turns on prose.
        # That scan is advisory now, so this is hygiene rather than a fix, and it keeps the relay
        # file readable. The tick-binary line elsewhere deliberately keeps its absolute path:
        # "run it from any directory" is the whole point of that instruction.
        # Emit paths RELATIVE where they resolve, so the repo root is not written into the relay at
        # all. An intermediate draft merely stopped repeating the root per line and still embedded it
        # once via `dirname(dirname(...))` — caught in agy's QA round, because "given once" is not
        # "not given". GH-162's contract that the note reference `relay-automation/DEBUG-MANTRA.md`
        # is preserved exactly (test/debug-mantra.sh pins it); an earlier draft dropped that too.
        #
        # `relpath` is only used when it stays inside the tree — a cross-repo run (`--target-root`)
        # would otherwise produce a `../../..` chain that is worse than an absolute path for a reader
        # and useless to an agent. In that case the absolute path is kept deliberately.
        def _rel(p, base):
            try:
                r = os.path.relpath(p, base)
            except (ValueError, TypeError):
                return p
            return p if r.startswith("..") else r

        harness_root = os.path.dirname(os.path.dirname(mantra_file))
        mantra_rel = _rel(mantra_file, harness_root)          # relay-automation/DEBUG-MANTRA.md
        phase_rel = _rel(phase_dir_, root)
        out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
               f"Before trying again, read `{mantra_rel}` (relative to the harness root) and follow its "
               f"four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this "
               f"round as a breadcrumb for the next one.\n")
        if reason:
            out += (f"Last recorded reason (`{os.path.join(phase_rel, 'ESCALATION.md')}`): `{reason}`. "
                    "Read it before re-guessing.\n")
        return out

    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
        # rather than being reimplemented here.
        lock_dir, lock_label = driver_lock_path(root)

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
            # Sentinel Tier 1 (GH-281/GH-342): record the auto-heal. Emitted BEFORE the reclaim, so
            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
            xyz_debug_log_stale_lock(root)
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

    # GH-75/GH-249 lifecycle heartbeat: write operational liveness before driving the relay and clear
    # it on any terminal path (registered via atexit right after the write, so every success/failure
    # branch clears it). Best-effort — never changes marathon-drive's exit code. Mirrors Bash
    # xyz_marathon_heartbeat_write/clear (relay-automation/marathon-drive.sh).
    xyz_heartbeat_bin = get_env("XYZ_HEARTBEAT_BIN", os.path.join(xyz_harness, "utils", "telemetry", "write-xyz-heartbeat.sh"))

    def _heartbeat(clear):
        if not os.access(xyz_heartbeat_bin, os.X_OK):
            return
        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
        harness = "swarm" if ctx == "swarm" else "marathon"
        sid = get_env("XYZ_SESSION_ID", args.phase_id)
        env = os.environ.copy()
        if clear:
            env["XYZ_HEARTBEAT_CLEAR"] = "1"
        try:
            subprocess.run([xyz_heartbeat_bin, harness, sid], env=env,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    def xyz_marathon_heartbeat_write():
        _heartbeat(clear=False)

    def xyz_marathon_heartbeat_clear():
        _heartbeat(clear=True)

    # GH-484: the default is `marathon-system/`, matching `relay-system/`. `--phases-dir` /
    # PHASES_DIR still override it exactly as before; only the default value changed. Historical
    # runs stay in `phases/` — the monitors read both, this driver only ever writes the new one.
    phases_dir = args.phases_dir or os.path.join(root, "marathon-system")
    # GH-319: the default gate is interpolated into a string that run_pre_advance_gate() hands to
    # `bash -c`, so an UNQUOTED root word-splits on any space in the repo path. Observed live: a
    # clone at ".../Documents/GH Repos/xyz-3-agents-swarm" produced `bash /Users/.../Documents/GH
    # Repos/.../validate.sh`, bash executed the unrelated 0-byte file `/Users/.../Documents/GH`, and
    # the gate returned 0 in 0.0s. Every phase of a 4-lane marathon reported "gate passed" while
    # validate.sh was in fact RED. shlex.quote is the fix; the preflight below already knew to strip
    # quotes off the script arg, it was just never given a quoted default to strip.
    # GH-268 item 8: a cross-repo lane had NO GATE. The default gate is this repo's validate.sh, and
    # a foreign --target-root usually has none, so GH-238's runnability preflight refused the whole
    # lane ("script file does not exist") — leaving the operator to either pass an explicit
    # --pre-advance-cmd or run ungated. The beta report is what that costs: a Producer/Reviewer loop
    # reached "Approved" while an independent audit of the same branch found 20 issues (1 critical,
    # 4 high) in the file the relay built on. relay-automation/target-checks.sh knows how to ask a
    # foreign repo for its OWN checks (php -l, phpcs, npm lint/test, pytest, ruff, make test), so a
    # cross-repo lane gets a real gate by default instead of no gate. An explicit --pre-advance-cmd
    # always wins.
    #
    # Codex cross-vendor consult (GH-268 item 9) found the first draft claimed "a target that HAS its
    # own validate.sh keeps using it" while the code did the opposite — that case fell to the else
    # branch and ran the HARNESS's validate.sh against a foreign repo. Both branches below now use
    # the target's own path when --target-root is set.
    #
    # target_root is absolutised first: run_pre_advance_gate() executes with cwd=target_root, so a
    # RELATIVE --target-root would be resolved twice — once to set cwd, then again from inside it.
    _target_root = os.path.abspath(args.target_root) if args.target_root else None
    if args.pre_advance_cmd:
        pre_advance_cmd = args.pre_advance_cmd
    elif _target_root and os.path.isfile(os.path.join(_target_root, "validate.sh")):
        pre_advance_cmd = f"bash {shlex.quote(os.path.join(_target_root, 'validate.sh'))}"
        log(f"--target-root has its own validate.sh — gating on it: {pre_advance_cmd}")
    elif _target_root:
        _tc = os.path.join(os.environ.get("XYZ_ROOT", root), "relay-automation", "target-checks.sh")
        if not os.path.isfile(_tc):
            die(f"--target-root has no validate.sh and target-checks.sh is missing at {_tc}. "
                f"Pass --pre-advance-cmd explicitly rather than running this lane ungated.")
        # --strict: a DETECTED tool that is missing fails the gate instead of silently reducing
        # coverage. Codex's consult named the case — phpcs detected, absent, php -l passes, exit 0
        # "because one check ran" — so the WordPress-security ruleset never runs and the lane still
        # reads green. Strict only here, where the harness CHOSE this gate: an operator who passes
        # --pre-advance-cmd by hand keeps the lenient default and can decide for themselves.
        pre_advance_cmd = f"bash {shlex.quote(_tc)} run --strict --root {shlex.quote(_target_root)}"
        log(f"--target-root has no validate.sh — gating on the target's own checks: {pre_advance_cmd}")
        log("  (--strict: a detected-but-missing tool FAILS rather than silently narrowing the gate;\n   exits 3 when it detects nothing, so 'no checks found' fails rather than passes)")
    else:
        pre_advance_cmd = f"bash {shlex.quote(os.path.join(root, 'validate.sh'))}"
    relay_task = args.relay_task or f"MARATHON-{args.phase_id.upper()}-TURN"
    # GH-207: a marathon lane namespaces its phase paths + attempt state so two lanes sharing a bare
    # phase id (p1) don't collide. Defaults to the phase id when no lane namespace is set.
    lane_state_key = get_env("MARATHON_LANE_NS") or args.phase_id

    # ── GH-284 Phase 2, ported (GH-322) ────────────────────────────────────────────────────────
    # BOTH halves of Phase 2 — the driver heartbeat AND the --log-github run log — existed only in
    # relay-automation/marathon-drive.sh. That twin `exec`s this file at its own line 18, long before
    # it installs the EXIT trap that runs them, so on the default lane (XYZ_PYTHON unset, GH-264)
    # neither one ever executed. #322 scoped this as "the run-log half only, the heartbeat is already
    # in the Python twin (12 references)"; those 12 matches are xyz_marathon_heartbeat_* — the GH-75
    # XYZ.heartbeat.json session record, a different file and a different feature. Before this change
    # `grep -c driver_heartbeat utils/py/marathon_drive.py` was 0, so the observability Phase 2 was
    # built to provide was absent from the lane that actually runs. Both halves are ported here.
    run_gate_result = ["not-run"]
    drive_started = [False]
    # GH-388: set once this phase has reached a DECIDED outcome and written a durable record for it
    # (escalate() writes ESCALATION.md + archives the transcript; complete_phase_success archives it).
    # Read only by _write_interrupted_phase_record, whose whole job is the case where neither ran —
    # a phase killed before the driver decided anything. A second flag rather than inferring from
    # run_gate_result, because "the gate did not run" and "this phase never reached an outcome" are
    # different facts and #407 exists because they were once conflated.
    phase_outcome_recorded = [False]

    def _cmd_out(cmd, cwd=None):
        # Best-effort stdout capture: a missing binary, a non-zero exit, or a crash all yield "".
        # Every probe in the run log is advisory, and none of them may raise into the exit path.
        try:
            res = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        except Exception:
            return ""
        if res.returncode != 0:
            return ""
        return res.stdout.decode("utf-8", "replace").strip()

    def _utc_now():
        return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    hb_interval = get_env("MARATHON_DRIVER_HEARTBEAT_INTERVAL", "30")
    try:
        hb_interval = int(hb_interval)
    except (TypeError, ValueError):
        hb_interval = 30
    if hb_interval <= 0:
        hb_interval = 30
    # MARATHON_DRIVER_HEARTBEAT_STALE_AFTER is deliberately not read here (GH-333). Staleness is a
    # question only a READER of the heartbeat file asks, and this lane is the writer; the reader
    # (rtl_driver_heartbeat_status, relay-turn-lib.sh) still honors the variable. The one consumer
    # this file had was the dropped constant field.

    def driver_heartbeat_path():
        # RTL_DRIVER_HEARTBEAT_FILE is the same override relay-turn-lib.sh honors, so an observer (or
        # a test) can point both twins at one file and get one answer.
        return get_env("RTL_DRIVER_HEARTBEAT_FILE") or os.path.join(root, ".tick", "driver-heartbeat.json")

    hb_state = {"started": "", "plan": "", "stop": None, "live": False}

    def driver_heartbeat_write():
        # Same record and the same atomic mkstemp+os.replace as rtl_driver_heartbeat_write, so a
        # heartbeat written by either twin is byte-compatible with readers of the other.
        path = driver_heartbeat_path()
        record = {
            "pid": os.getpid(),
            "started_utc": hb_state["started"],
            "updated_utc": _utc_now(),
            "plan": hb_state["plan"],
            "phase_id": args.phase_id,
            "relay_task": relay_task,
        }
        directory = os.path.dirname(path) or "."
        try:
            os.makedirs(directory, exist_ok=True)
            fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
            try:
                with os.fdopen(fd, "w") as f:
                    json.dump(record, f, sort_keys=True)
                    f.write("\n")
                os.replace(tmp, path)
            except Exception:
                try:
                    os.unlink(tmp)
                except OSError:
                    pass
                raise
        except Exception:
            return False
        return True

    def driver_heartbeat_clear():
        try:
            os.remove(driver_heartbeat_path())
        except OSError:
            pass

    # GH-333: there is deliberately NO driver_heartbeat_status() here. Its only caller was the run
    # log's `driver still running` field, which could only ever answer "running" — the exit hook
    # asked before clearing the heartbeat, and the PID it tested belonged to the process asking. The
    # field is gone, so the reader would be dead code.
    #
    # The heartbeat FILE is the real deliverable and is unchanged: this lane still writes and clears
    # it, and the reader that observers actually use lives in relay-automation/relay-turn-lib.sh
    # (`rtl_driver_heartbeat_status`), which is a shared runtime dependency, not a frozen twin.
    # Writer here, reader there — which is also why dropping this costs nothing.

    def driver_heartbeat_start():
        hb_state["started"] = _utc_now()
        hb_state["plan"] = get_env("MARATHON_PLAN_NAME") or \
            os.path.splitext(os.path.basename(args.phase_brief_file))[0]
        if not driver_heartbeat_write():
            log("driver heartbeat unavailable — continuing without liveness record")
            return
        hb_state["live"] = True
        # A daemon thread is the Python analogue of the Bash `( while kill -0 $$; do sleep; write;
        # done ) &` subshell: it cannot outlive the driver, and it can never block interpreter exit.
        stop = threading.Event()
        hb_state["stop"] = stop

        def _refresh():
            while not stop.wait(hb_interval):
                driver_heartbeat_write()

        threading.Thread(target=_refresh, daemon=True).start()

    def driver_heartbeat_stop():
        if hb_state["stop"] is not None:
            hb_state["stop"].set()
        if hb_state["live"]:
            driver_heartbeat_clear()

    # The run log is deliberately restricted to comments on an ALREADY-EXISTING lane issue: no
    # `gh issue create`, no close/reopen, and no mutation at all unless --log-github was passed.
    # Every failing gh probe is swallowed so external reporting can never alter the marathon result.
    def lane_issue_number():
        for candidate in (lane_state_key, relay_task, os.path.basename(args.phase_brief_file)):
            m = re.search(r'GH-?([0-9]+)', str(candidate or ""))
            if m:
                return m.group(1)
        return ""

    def trunk_ref(repo=None):
        """The repo's trunk: `origin/HEAD` if resolvable, else whatever HEAD points at right now.

        GH-402: takes a repo path. It was hardcoded to `root`, which is correct for the run-log's
        landed-yes/no probe (its only caller) and wrong for the branch guard below, where the repo
        that RECEIVES the commit may be `--target-root` — a different repo, with a different trunk.
        Defaulting to `root` keeps the existing caller byte-identical.

        The fallback matters and is not a rounding error: a repo with no `origin` (a fresh fixture, a
        local-only clone) has no origin/HEAD, and returning nothing there would silently disable the
        guard in exactly the setup where a stray commit is least recoverable. Falling back to the
        CURRENT branch makes the guard read "you are on the branch you started on", which for a repo
        with no remote is the best available meaning of trunk.
        """
        repo = repo or root
        ref = _cmd_out(["git", "-C", repo, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"])
        if ref and ref != "origin/HEAD":
            return ref
        return _cmd_out(["git", "-C", repo, "symbolic-ref", "--quiet", "--short", "HEAD"])

    def marathon_run_github_log(driver_exit):
        if not (args.log_github and drive_started[0]):
            return
        if not shutil.which("gh") or subprocess.run(
                ["gh", "auth", "status"], stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL).returncode != 0:
            log("--log-github requested, but gh is unavailable or unauthenticated — local telemetry only")
            return
        issue = lane_issue_number()
        if not issue:
            log(f"--log-github requested, but no GH issue number is derivable for lane {lane_state_key} — local telemetry only")
            return
        # Every gh call MUST be scoped to $root's repository. A bare `gh repo view` / `gh pr view`
        # resolves whatever repo the ambient CWD happens to be in, so a --target-root run, or any
        # invocation from a foreign directory, could post THIS lane's run log into the WRONG
        # repository's issue #N. Derive the slug from root's own remote (no gh call, no CWD
        # dependency); fall back to a gh lookup explicitly executed inside root.
        url = _cmd_out(["git", "-C", root, "remote", "get-url", "origin"])
        repo = re.sub(r'\.git$', '', re.sub(r'^https?://[^/]+/', '', re.sub(r'^git@[^:]+:', '', url)))
        # A local-path remote (file:///…/remote.git — common in tests and vendored clones) survives
        # those substitutions with slashes intact and would otherwise be accepted as a bogus slug,
        # sending every gh call to a repo that does not exist.
        if not re.fullmatch(r'[A-Za-z0-9._-]+/[A-Za-z0-9._-]+', repo):
            repo = _cmd_out(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], cwd=root)
        if not repo:
            log("--log-github requested, but repository lookup failed — local telemetry only")
            return

        # GH-425: cross-check the phase brief's declared source against the resolved repo/issue, to
        # avoid commenting on a different repository's issue that happens to share a number. Only a
        # POSITIVE mismatch aborts the POST — a brief with no frontmatter, no source: field, or an
        # unparseable URL is unverifiable, not wrong, and must not silently stop logging (the same
        # trap #375 already hit here: absent evidence is not failure evidence).
        try:
            brief_text = open(args.phase_brief_file, 'r', encoding='utf-8').read()
            fm_match = re.match(r'^---\n(.*?)\n---', brief_text, re.DOTALL)
            src_match = re.search(r'^source:\s*(.+?)\s*$', fm_match.group(1), re.MULTILINE) if fm_match else None
            raw_url = src_match.group(1).strip().strip('"\'') if src_match else None
            url_match = re.search(r'https?://github\.com/([^/\s]+/[^/\s]+?)/issues/(\d+)', raw_url) if raw_url else None
        except OSError:
            url_match = None
        if url_match:
            expected_slug, expected_issue = url_match.group(1), url_match.group(2)
            if expected_issue != issue or expected_slug.casefold() != repo.casefold():
                log(f"--log-github aborted: phase brief intends '{expected_slug}' issue {expected_issue} but driver is in '{repo}' issue {issue}")
                return
        branch = _cmd_out(["git", "-C", root, "symbolic-ref", "--quiet", "--short", "HEAD"]) or "(detached)"
        trunk = trunk_ref()
        landed = "no"
        if trunk and subprocess.run(["git", "-C", root, "merge-base", "--is-ancestor", "HEAD", trunk],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            landed = "yes"
        pr_url = _cmd_out(["gh", "pr", "view", "--repo", repo, "--head", branch, "--json", "url", "--jq", ".url"]) \
            or "NO PR OPENED"
        plan = hb_state["plan"] or os.path.splitext(os.path.basename(args.phase_brief_file))[0]
        marker = f"<!-- xyz-marathon-run-log:{issue}:{lane_state_key} -->"
        body = (f"{marker}\n"
                f"### Marathon run log\n"
                f"- plan: `{plan}`\n"
                f"- phase: `{args.phase_id}`\n"
                f"- branch: `{branch}`\n"
                f"- trunk (derived): `{trunk}`\n"
                f"- landed on trunk: **{landed}**\n"
                f"- PR: {pr_url}\n"
                f"- per-phase gate: **{run_gate_result[0]}**\n"
                f"- driver exit: `{driver_exit}` ({_exit_meaning(driver_exit)})\n"
                f"- recorded: {_utc_now()}")
        comments = _cmd_out(["gh", "api", "--paginate", "--slurp",
                             f"repos/{repo}/issues/{issue}/comments?per_page=100"])
        comment_id = runlog_find_comment_id(comments, marker)
        if comment_id:
            ok = subprocess.run(["gh", "api", "--method", "PATCH",
                                 f"repos/{repo}/issues/comments/{comment_id}", "-f", f"body={body}"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
            log(f"updated GitHub run-log comment on issue #{issue}" if ok
                else "GitHub run-log update failed — local telemetry only")
        else:
            ok = subprocess.run(["gh", "api", "--method", "POST",
                                 f"repos/{repo}/issues/{issue}/comments", "-f", f"body={body}"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
            log(f"posted GitHub run-log comment on issue #{issue}" if ok
                else "GitHub run-log post failed — local telemetry only")

    def xyz_marathon_cost_summary():
        # GH-331 (mirrors marathon-drive.sh GH-222 / relay-drive.sh GH-152): auto-surface the
        # `tick analyze` cost block at end-of-run. This lived only in the Bash twin, so on the default
        # Python lane (GH-264) it never ran. Worse than relay-drive: marathon tells its nested
        # relay-drive child RELAY_COST_SUMMARY=0 (see _run_relay_drive), so with the parent's own
        # summary also absent a driven phase had ZERO end-of-run cost visibility. Only fires once a
        # phase was really being driven (drive_started — never on --help/usage/lock-contention/
        # lane-parked/--dry-run exits), opts out with MARATHON_COST_SUMMARY=0, and swallows a
        # failed/forced `tick analyze` so it can NEVER change the driven run's own exit code.
        if not drive_started[0]:
            return
        if get_env("MARATHON_COST_SUMMARY", "1") == "0":
            return
        try:
            report = subprocess.check_output([tick_bin, "analyze", "--format", "human"],
                                             stderr=subprocess.DEVNULL).decode("utf-8")
        except Exception:
            log("tick analyze failed — end-of-run cost summary unavailable (MARATHON_COST_SUMMARY=0 to silence)")
            return
        block_lines = []
        capturing = False
        for ln in report.splitlines():
            if ln == "--- cost ---":
                capturing = True
            if capturing:
                block_lines.append(ln)
        if not block_lines:
            return
        print("\nmarathon-drive: end-of-run cost summary (tick analyze) —\n" + "\n".join(block_lines))

    def _marathon_drive_on_exit(code):
        # Same order as the Bash EXIT trap: log first (so the run log can still read a live
        # heartbeat), then stop the heartbeat, then the cost summary. Each part is independently
        # guarded — external reporting/telemetry must never be able to change the driven run's exit code.
        try:
            marathon_run_github_log(code)
        except Exception as exc:
            log(f"GitHub run log raised ({exc.__class__.__name__}) — local telemetry only")
        try:
            driver_heartbeat_stop()
        except Exception:
            pass
        try:
            xyz_marathon_cost_summary()
        except Exception:
            pass

    def _write_interrupted_phase_record(code):
        """GH-388: the phase that dies is the one phase with no record. Give it one.

        `save_transcript()` runs on success, and `escalate()` calls it too — but both are reached only
        when the driver decides an outcome. A phase KILLED mid-run (operator ^C, a driver wall cap, a
        supervisor SIGTERM, the host going down under it) reaches neither, which is precisely the
        shape of the run that produced this issue: phases 1-4 each have a transcript and phase 5, the
        one that killed the host, has none. The archive is therefore biased toward success by
        construction — a systematically incomplete record, not a gap.

        Deliberately CONTENT-BEARING, because an empty or pre-created file satisfies the words and
        none of the need (the issue's own review caught that loophole). It carries the phase id, the
        relay state at interruption — read from the relay file NOW, not from a variable set earlier —
        and the reason, and it is written at interruption time so its mtime is after the phase began.

        Never raises: a failure to record must not change how the run ends.
        """
        if not drive_started[0]:
            return                      # nothing was ever dispatched; an empty record would lie
        if code == 0 or phase_outcome_recorded[0]:
            return                      # completed, or escalate() already wrote a durable record
        try:
            status_line, round_count = "unknown", 0
            try:
                with open(relay_file, "r", encoding="utf-8", errors="replace") as f:
                    for ln in f:
                        if ln.startswith("STATUS:"):
                            status_line = ln.strip()
                        if ln.lstrip().startswith("### Round"):
                            round_count += 1
            except OSError:
                status_line = "relay file unreadable at interruption"

            reason = _exit_meaning(code) if code else "interrupted"
            dest = os.path.join(phase_dir, "PHASE-INTERRUPTED.md")
            os.makedirs(phase_dir, exist_ok=True)
            with open(dest, "w", encoding="utf-8") as f:
                f.write(
                    f"# INTERRUPTED — Marathon Phase {args.phase_id}\n\n"
                    f"phase: {args.phase_id}\n"
                    f"task: {relay_task}\n"
                    f"reason: {reason}\n"
                    f"exit-code: {code}\n"
                    f"interrupted-at: {_utc_now_z()}\n"
                    f"relay-file: {rel_relay}\n"
                    f"relay-status: {status_line}\n"
                    f"relay-rounds-recorded: {round_count}\n"
                    f"\nThis phase did not reach an outcome, so neither save_transcript() nor\n"
                    f"escalate() ran. The relay file above holds whatever the turns had written when\n"
                    f"the run stopped; this record exists so the phase is not simply absent (GH-388).\n"
                )
            log(f"interrupted-phase record written: {dest} (reason: {reason})")
            # Best-effort archive of the relay state itself, for the same reason escalate() does it.
            try:
                save_transcript()
            except Exception:
                pass
        except Exception:
            pass

    _ON_EXIT.append(_write_interrupted_phase_record)
    _ON_EXIT.append(_marathon_drive_on_exit)

    # GH-238: a vendored consumer normally has no root-level validate.sh. Do NOT spend a builder and
    # reviewer turn only to discover the default gate can't start after approval. A deliberately
    # non-executing probe (gates like `test -f build/output` only become true after the builder runs):
    # prove the gate is *runnable*, not that it currently passes. Runs before any render/tick/dispatch.
    _gate_root = args.target_root or root
    def _preflight_check_issue_closed():
        mock_state = os.environ.get("MOCK_GH_ISSUE_STATE")
        if mock_state:
            state = mock_state.upper()
        else:
            issue = lane_issue_number()
            if not issue:
                return
            if not shutil.which("gh"):
                return
            url = _cmd_out(["git", "-C", root, "remote", "get-url", "origin"])
            repo = re.sub(r'\.git$', '', re.sub(r'^https?://[^/]+/', '', re.sub(r'^git@[^:]+:', '', url)))
            if not re.fullmatch(r'[A-Za-z0-9._-]+/[A-Za-z0-9._-]+', repo):
                repo = _cmd_out(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], cwd=root)
            if not repo:
                return
            state = _cmd_out(["gh", "issue", "view", issue, "--repo", repo, "--json", "state", "--jq", ".state"])
        
        if state and state.upper() == "CLOSED":
            issue_display = lane_issue_number() or "unknown"
            xyz_debug_log_append(
                root, "warn", "marathon.issue-closed",
                f"lane {lane_state_key} parked — issue {issue_display} is already closed",
                action="none (lane halted)",
                target_root=args.target_root, phase_id=args.phase_id,
                relay_task=relay_task)
            eprint(f"marathon-drive: lane parked — issue {issue_display} is already closed")
            sys.exit(4)

    def _pre_advance_not_runnable(reason):
        die(f"pre-advance gate not runnable: '{pre_advance_cmd}' ({reason}). "
            f"Pass --pre-advance-cmd '<runnable command>' to override it.")
    def _preflight_pre_advance_gate():
        if subprocess.run(["bash", "-n", "-c", pre_advance_cmd],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            _pre_advance_not_runnable("shell syntax is invalid")
        # GH-319: tokenize the way the shell will. A regex `(\S+)` capture cannot see a quoted path
        # that contains a space — it grabs the leading fragment, which on this machine happened to be
        # a real 0-byte file, so the "is the gate runnable?" check passed on the WRONG file. shlex
        # splits `bash '/a b/validate.sh'` into two tokens, so the same check now inspects the file
        # the shell would actually execute. Fall back to naive split only if the string is unparsable
        # (unbalanced quotes) — that case is caught by the `bash -n` syntax check just above anyway.
        try:
            tokens = shlex.split(pre_advance_cmd)
        except ValueError:
            tokens = pre_advance_cmd.split()
        if tokens and re.fullmatch(r'bash|/\S*/bash', tokens[0]) and len(tokens) > 1:
            gate_shell, script_arg = tokens[0], tokens[1]
            if not shutil.which(gate_shell):
                _pre_advance_not_runnable(f"interpreter '{gate_shell}' is not on PATH")
            if script_arg.startswith("-"):
                return
            gate_path = script_arg if os.path.isabs(script_arg) else os.path.join(_gate_root, script_arg)
            if not os.path.isfile(gate_path):
                _pre_advance_not_runnable(f"script file does not exist: {gate_path}")
            return
        parts = tokens
        command_name = parts[0] if parts else ""
        if not command_name:
            _pre_advance_not_runnable("command is empty")
        if re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', command_name):
            _pre_advance_not_runnable(f"a gate command may not begin with an environment assignment ('{command_name}'). The gate program is resolved from the first token, and the gate environment is scrubbed (GH-441) — pass configuration in a file beside the gate script, not the environment.")
        elif "/" in command_name:
            gate_path = command_name if os.path.isabs(command_name) else os.path.join(_gate_root, command_name)
            if not (os.path.isfile(gate_path) and os.access(gate_path, os.X_OK)):
                _pre_advance_not_runnable(f"executable does not exist or is not executable: {gate_path}")
        else:
            if not shutil.which(command_name):
                _pre_advance_not_runnable(f"command '{command_name}' is not on PATH")

    def _preflight_relay_drive():
        if not relay_drive_bin or not os.path.exists(relay_drive_bin):
            die(f"relay-drive does not exist: {relay_drive_bin}")
        if not os.path.isfile(relay_drive_bin):
            die(f"relay-drive is not a file: {relay_drive_bin}")
        if not os.access(relay_drive_bin, os.X_OK):
            die(f"relay-drive is not executable: {relay_drive_bin}")

    os.environ["MARATHON_BUILDER"] = args.builder
    os.environ["MARATHON_REVIEWER"] = args.reviewer
    os.environ["CLAUDE_AGENT"] = ""
    os.environ["CODEX_AGENT"] = ""
    os.environ["AGY_AGENT"] = ""
    os.environ["AIDER_AGENT"] = ""
    os.environ["PI_AGENT"] = ""
    os.environ["SMALLCODE_AGENT"] = ""

    def route_agent(agent_id):
        # GH-414 — BASH/PYTHON DIVERGENCE, deliberate and pinned. This router accepts `pi*`
        # (GH-295 shipped the shim, GH-451/PR #452 wired it here); the frozen Bash twin at
        # relay-automation/marathon-drive.sh:779-783 accepts claude/codex/agy/aider ONLY and dies
        # on `pi`. Same split in the binary probe: _probe_agent_bin below has a `pi` branch, the
        # Bash twin's does not. Nothing is broken by this — marathon-drive.sh execs this file
        # whenever XYZ_PYTHON is unset or 1, which is the default, so the Bash path is only
        # reachable via XYZ_PYTHON=0 or a host with no python3 >= 3.8. On THAT path `--builder pi`
        # fails at argument routing before any tick mutation.
        #
        # The Bash half is frozen under GH-308 and is NOT to be taught about Pi as a drive-by fix;
        # doing so needs a `Frozen-twin-exception:` trailer and should happen only as part of
        # retiring the twins. test/marathon-drive.sh case (20b) asserts the Bash rejection, so if
        # anyone does teach it Pi, that case fails loudly and this note must be retired with it.
        #
        # REVIEWER routing is a separate, narrower set and Pi is NOT in it — see the check below
        # and bin/marathon-yaml:95. A Pi *builder* fallback does not give you a Pi *reviewer*.
        if agent_id.startswith("claude"): os.environ["CLAUDE_AGENT"] = agent_id
        elif agent_id.startswith("codex"): os.environ["CODEX_AGENT"] = agent_id
        elif agent_id.startswith("agy"): os.environ["AGY_AGENT"] = agent_id
        elif agent_id.startswith("aider"): os.environ["AIDER_AGENT"] = agent_id
        elif agent_id.startswith("pi"): os.environ["PI_AGENT"] = agent_id
        elif agent_id.startswith("smallcode"): os.environ["SMALLCODE_AGENT"] = agent_id
        else: die(f"agent '{agent_id}' not recognized — must start with claude/codex/agy/aider/pi/smallcode")
        
    if args.builder == args.reviewer:
        die(f"builder and reviewer must be different agent ids (got '{args.builder}' for both)")
        
    route_agent(args.builder)
    route_agent(args.reviewer)
    
    if not (args.reviewer.startswith("codex") or args.reviewer.startswith("gemini") or args.reviewer.startswith("agy")):
        die(f"reviewer '{args.reviewer}' must start with codex/gemini/agy")

    _probe_agent_bin(args.builder, "builder")
    _probe_agent_bin(args.reviewer, "reviewer")

    # GH-238 preflight runs AFTER the binary probes (missing builder/reviewer binary fails first, via
    # shutil.which with no subprocess) but BEFORE any render/tick/dispatch — so a non-runnable default
    # gate still halts with exit 2 before spending a turn.
    if args.dry_run:
        # dry-run never dispatches a turn, so surface the problem but keep going (matches Bash).
        try:
            _preflight_check_issue_closed()
            _preflight_pre_advance_gate()
            _preflight_relay_drive()
        except SystemExit as _e:
            if _e.code not in (0, None):
                eprint("marathon-drive: (dry-run continues; a live run would halt here)")
    else:
        _preflight_check_issue_closed()
        _preflight_pre_advance_gate()
        _preflight_relay_drive()

    if args.artifact_paths:
        os.environ["ALLOW_PATHS"] = args.artifact_paths
    else:
        if "ALLOW_PATHS" in os.environ:
            del os.environ["ALLOW_PATHS"]

    # GH-249: snapshot HEAD in the repo the artifact lands in (TARGET_ROOT when set, else ROOT) BEFORE
    # this phase's first commit, so requires_test_delta has a true "before this phase" baseline. Captured
    # unconditionally (cheap); unused unless --requires-test is set.
    pre_phase_head = ""
    try:
        pre_phase_head = subprocess.check_output(
            ["git", "-C", (args.target_root or root), "rev-parse", "HEAD"],
            stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        pre_phase_head = ""

    phase_dir = os.path.join(phases_dir, lane_state_key)
    relay_file = os.path.join(phase_dir, "RELAY.md")
    
    # repo-root-relative path
    if relay_file.startswith(root + "/"):
        rel_relay = relay_file[len(root)+1:]
    else:
        rel_relay = relay_file

    # Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
    # just below — and the escalate/complete_phase_success defs it may call — read/write tick
    # state against the right repo even when a caller invoked us without pre-exporting it.
    os.environ["TICK_REPO_ROOT"] = root

    # escalate/save_transcript/run_pre_advance_gate/file_status/terminal_status/token_state/
    # requires_test_delta/complete_phase_success are defined here (ahead of the render below)
    # instead of beside their original later call sites, so the GH-274 satisfied-lane
    # short-circuit just below — which must run BEFORE the render — can call
    # complete_phase_success directly rather than duplicating its gate/requires-test/telemetry
    # logic.
    def escalate(reason, rexit):
        # GH-407: every escalation records `gate:` — not-run / green / red — because the reason alone
        # cannot be trusted to say whether the gate executed, and the operator's first move on a
        # failed phase is decided by that one fact. `pre-advance-failed` sends them to read the diff
        # and the test output; when the gate never ran there IS no test output and nothing in the
        # record said so. Observed three times in one 10-lane marathon on 2026-08-02, wrong all three
        # times. It is recorded on EVERY reason, not only the gate-related ones, so the answer is
        # present even when the reason taxonomy is incomplete — which the issue itself argued is the
        # robust half of the fix. run_gate_result is the existing state that already knows this; no
        # parallel flag is introduced, because a second source of truth would be a third thing to
        # keep in sync.
        # Sentinel Tier 1 (GH-281/GH-342): harvest this failed phase's Side Findings BEFORE the
        # escalation record is written, matching marathon-drive.sh:848-853 — a phase that escalated
        # is exactly the one whose findings are about to be lost.
        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
                             xyz_debug_log_file(root))
        builder_diag = ""
        try:
            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
            import glob
            log_patterns = [
                os.path.join(ts_base, "logs", "*", f"*{relay_task}*.log"),
                os.path.join(root, "relay-system", "logs", "*", f"*{relay_task}*.log"),
            ]
            matches = []
            for pat in log_patterns:
                matches.extend(glob.glob(pat))
            if matches:
                latest_log = max(matches, key=os.path.getmtime)
                with open(latest_log, 'r', encoding='utf-8', errors='replace') as lf:
                    log_text = lf.read().strip()
                if log_text.startswith("{") and log_text.endswith("}"):
                    log_data = json.loads(log_text)
                    bits = []
                    for k in ["is_error", "subtype", "terminal_reason", "total_cost_usd"]:
                        if k in log_data:
                            bits.append(f"{k}={log_data[k]}")
                    if bits:
                        builder_diag = ", ".join(bits)
        except Exception:
            pass

        esc_file = os.path.join(phase_dir, "ESCALATION.md")
        with open(esc_file, 'w') as f:
            f.write(f"""# ESCALATION — Marathon Phase {args.phase_id}

phase: {args.phase_id}
task: {relay_task}
relay-drive-exit: {rexit}
reason: {reason}
gate: {run_gate_result[0]}
relay-file: {rel_relay}
""")
            if builder_diag:
                f.write(f"builder-diagnostic: {builder_diag}\n")
        subprocess.run(["git", "-C", root, "add", "--", esc_file], check=True)
        # GH-207: an identical escalation record must not HALT on nothing-to-commit.
        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
        # Archive the failed phase's relay transcript too — save_transcript otherwise runs only
        # on success, so an escalated/reverted phase leaves no durable record of its rounds. The
        # 2026-07-30 rebalance-OS marathon (GH-382's panic run) reverted its p5 phase twice and
        # the relay state survived nowhere. Non-fatal: losing the archive must not mask the
        # escalation itself.
        try:
            if not save_transcript():
                log(f"warn: could not archive relay transcript for escalated phase {args.phase_id}")
        except Exception as exc:  # noqa: BLE001 — archive failure must never mask the escalation
            log(f"warn: could not archive relay transcript for escalated phase {args.phase_id}: {exc}")
        subprocess.run([tick_bin, "log", "marathon.phase.escalated", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        _phase_memory_sample(f"{args.phase_id}-escalated", root=root, tick_bin=tick_bin, relay_task=relay_task)
        phase_outcome_recorded[0] = True   # GH-388: a decided outcome with a durable record
        log(f"escalation written: {esc_file} (reason: {reason})")
        # marathon-drive.sh:867-868 — last thing escalate() does, carrying the relay-drive exit code.
        xyz_debug_log_append(
            root, "error", "marathon.escalation",
            f"{reason} (relay-drive-exit={rexit})",
            file=rel_relay, action="promote to PROJECT/1-INBOX capture doc",
            target_root=args.target_root, phase_id=args.phase_id, relay_task=relay_task)

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
        # Sentinel Tier 1 (GH-281/GH-342): harvest Side Findings from the saved transcript
        # (marathon-drive.sh:880-885) — after the copy, before the commit, same as Bash.
        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
                             xyz_debug_log_file(root))
        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
            log(f"transcript unchanged: {dest}")
        else:
            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
            log(f"transcript saved: {dest}")
        return True

    # GH-307: the gate is a correctness check on the REPO — it is not part of this run's
    # provenance, and it must not be able to see who is driving it. These tags otherwise leak
    # into the gate subprocess and break tests that legitimately assert on them
    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID;
    # test/debug-mantra.sh reads MARATHON_LANE_NS), which made `bash validate.sh` — the
    # DOCUMENTED DEFAULT GATE — impossible to pass inside a marathon: every phase 1 escalated
    # with reason `pre-advance-failed` while its own change was correct and approved.
    # Scrubbing is deliberately narrow: only the run-identity tags, never repo/config inputs
    # like MARATHON_ROOT, TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
    # GH-441 Phase 2 — the gate's inherited environment is governed by a stated contract, not by a
    # denylist maintained here and a second, different one in validate.sh's prologue. That split was
    # the defect: marathon_drive popped 3 names, validate.sh unset 6 MORE, and any custom
    # --pre-advance-cmd that omitted the prologue was silently wrong (observed live — a hand-written
    # gate reproduced the oracle-guard flip on ambient ALLOW_PATHS). utils/py/gate_env.py now
    # classifies EVERY variable the drivers export as scrub-or-pass with a reason, and
    # test/gh441-gate-env-contract.sh fails loudly if a new export is added without a classification.
    #
    # It deliberately does NOT scrub RELAY_DRIVER_LOCKED; see that module's docstring for the measured
    # reason (scrubbing it globally was landed and reverted — the nested drivers need it SET and the
    # lock assertions need it UNSET, so the fix is per-suite, which shipped as Phase 1).
    # GH-441 Phase 2 widened this from three names to every variable the drivers export. The
    # registry with the REASON for each classification lives in utils/py/gate_env.py; this stays a
    # plain literal on purpose, for two reasons that both cost a full gate run to learn:
    #
    #   * GH-307's guard (test/gh307-gate-env-scrub.sh) statically requires a literal here and
    #     requires _gate_env to pop from it. That guard exists so the scrub set is auditable by
    #     reading the driver, which is a property worth keeping — a refactor that hides the list
    #     behind an import would satisfy nobody's review.
    #   * marathon_drive.py is loaded via importlib from a bare `<stdin>` by
    #     test/gh322-runlog-python-lane.sh, so utils/py/ is NOT on sys.path. An `import gate_env`
    #     here raises ModuleNotFoundError and takes the whole driver down. Measured, not guessed.
    #
    # The two copies cannot drift: test/gh441-gate-env-contract.sh asserts this literal is exactly
    # gate_env.SCRUBBED_NAMES, and fails if either side changes alone.
    #
    # RELAY_DRIVER_LOCKED is deliberately ABSENT — scrubbing it globally was landed and reverted on
    # 2026-08-07 (nested drivers need it SET, lock assertions need it UNSET; no global value is
    # correct). See gate_env.py's docstring for the measured matrix.
    GATE_SCRUBBED_ENV = (
        "AGY_AGENT", "AIDER_AGENT", "ALLOW_PATHS",
        "CLAUDE_AGENT", "CODEX_AGENT", "MARATHON_BUILDER",
        "MARATHON_LANE_NS", "MARATHON_REVIEWER", "RELAY_AGENT",
        "PI_AGENT", "RELAY_ARTIFACT_FILE", "RELAY_FILE", "RELAY_PEER",
        "SMALLCODE_AGENT",
        "RELAY_TARGET_ROOT", "RELAY_TASK", "RELAY_WORKTREE_ISOLATION",
        "XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID",
    )

    def _gate_env():
        env = os.environ.copy()
        for var in GATE_SCRUBBED_ENV:
            env.pop(var, None)
        return env

    # GH-390 Phase 1 — layered gate guard.
    #
    # The gate executes code an LLM wrote seconds earlier, and by the packet's own instruction the
    # builder must NOT run the gate itself ("it can create files that trip containment and discard
    # your turn"). The gate is therefore, by construction, the FIRST execution of anything the
    # builder wrote — yet it ran with no timeout, no resource bounds, and in the marathon's own
    # process group. Twice on 2026-07-30 (GH-382) a generated test mocked a paging function with a
    # constant return_value against a `while True:` loop; MagicMock recorded ~1 KB per call until
    # all 30.75 GB of swap was gone and the host kernel-panicked.
    #
    # The framing that matters: the target's suite is the WORKPIECE, not trusted infrastructure.
    # It must be assumed hostile the way CI assumes a PR is hostile.
    #
    # Measured on the crash host (Darwin 24.6, arm64) — not assumed from Linux habit:
    #   setrlimit(RLIMIT_AS)  / ulimit -v  -> REFUSED, EINVAL, even soft-only
    #   setrlimit(RLIMIT_DATA)/ ulimit -d  -> REFUSED, same
    #   setrlimit(RLIMIT_CPU) / ulimit -t  -> works (layer 2 below)
    #   process-group RSS poll + killpg    -> works (layer 3 below)
    # On Linux `ulimit -v` alone would have turned both crashes into a MemoryError inside pytest.
    # On macOS kernel-enforced MEMORY caps do not exist for ordinary processes, so layer 3 is not
    # a belt-and-braces extra — it is the only thing standing between a runaway test and the host.
    #
    # Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.
    def run_pre_advance_gate():
        cwd = args.target_root if args.target_root else None
        env = _gate_env()

        # The escape hatch is load-bearing for a same-day ship: a guard that false-positives would
        # otherwise block every marathon until someone can land a revert. This restores the exact
        # pre-GH-390 call, including running in the marathon's own process group.
        if os.environ.get("MARATHON_GATE_GUARD", "1").strip() == "0":
            log("gate-guard: disabled via MARATHON_GATE_GUARD=0 — running the gate unguarded")
            rc = subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash",
                                cwd=cwd, env=env).returncode
            baseline_allow = args.pre_advance_baseline or os.environ.get("MARATHON_GATE_BASELINE")
            if baseline_allow and rc != 0 and rc != GATE_GUARD_KILL_EXIT:
                try:
                    base_rc = int(baseline_allow)
                    if rc == base_rc or (rc > 0 and rc <= base_rc):
                        log(f"gate-baseline: gate exit {rc} matches recorded baseline allowance ({base_rc}) — allowing advance (GH-378)")
                        run_gate_result[0] = "green"
                        return 0
                except ValueError:
                    pass
            run_gate_result[0] = "green" if rc == 0 else "red"
            return rc

        cfg = _gate_guard_config()
        cmd = pre_advance_cmd
        if cfg["cpu_s"] > 0:
            # Layer 2. Unlike the RSS poll below this cannot be raced, and it still fires if this
            # driver process itself wedges — the one bound that does not depend on the watchdog.
            #
            # The soft cap MUST sit below the hard cap. A bare `ulimit -t N` sets both to N, and
            # Linux's posix_cpu_timers tests the hard limit FIRST — so at N seconds it delivers
            # SIGKILL and SIGXCPU is never sent at all, making the signal this layer is built to
            # recognize unreachable. macOS's BSD path delivers SIGXCPU for the same limits, which
            # is why this only ever failed on CI. Splitting the two restores the intended signal
            # and leaves the hard cap as a backstop for a gate that ignores SIGXCPU.
            cmd = (f"ulimit -H -t {cfg['cpu_s'] + GATE_CPU_HARD_MARGIN_S} 2>/dev/null || true; "
                   f"ulimit -S -t {cfg['cpu_s']}; {pre_advance_cmd}")

        # start_new_session=True makes the gate a session and process-group leader (pgid == pid),
        # which is what lets layer 3 measure and kill the whole tree rather than just the shell.
        proc = subprocess.Popen(cmd, shell=True, executable="/bin/bash", cwd=cwd, env=env,
                                start_new_session=True)
        started = time.monotonic()
        peak_rss_mb = 0
        rc = None
        while rc is None:
            rc = proc.poll()
            if rc is not None:
                break
            elapsed = int(time.monotonic() - started)
            rss_mb = _gate_group_rss_mb(proc.pid)
            peak_rss_mb = max(peak_rss_mb, rss_mb)
            reason = None
            if cfg["wall_s"] > 0 and elapsed >= cfg["wall_s"]:
                reason = f"wall clock {elapsed}s >= cap {cfg['wall_s']}s"
            elif cfg["rss_mb"] > 0 and rss_mb >= cfg["rss_mb"]:
                reason = f"gate group RSS {rss_mb}MB >= cap {cfg['rss_mb']}MB"
            if reason:
                _gate_kill_group(proc, reason)
                rc = GATE_GUARD_KILL_EXIT
                break
            time.sleep(cfg["poll_s"])

        # A layer-2 kill never comes through the poll loop above — the kernel reaps the gate without
        # consulting us. Left unmapped it would escalate as `pre-advance-failed`, i.e. as the gate
        # having found a defect in the change, which is the single most misleading thing this guard
        # could report. Only mapped when we set the cap.
        #
        # It arrives in TWO shapes, and which one depends on the bash build, not on us:
        #   128+SIGXCPU (152) — bash forked the gate, reaped SIGXCPU, and reported it as an exit
        #                       status. macOS's bash 3.2 does this.
        #   -SIGXCPU    (-24) — bash applied its last-command exec optimization, so the gate process
        #                       IS the process we wait on and Popen reports the signal negated.
        #                       bash 5.x (every Linux CI runner) does this.
        # Mapping only the first is why this escalated as `pre-advance-failed` on CI while passing
        # on macOS: same kill, different messenger.
        # GH-390: the mapping itself now lives in gate_guard_cpu_attribution() at module scope, so
        # all four platform/Bash shapes can be driven directly by test/gh390-gate-guard.sh on any
        # host. Before the lift each branch was only reachable on the kernel that produces its
        # signal, so half the attribution logic was never observed firing on the machine that runs
        # the suite — the #419 defect, inside the guard #407 depends on.
        rc, _guard_diag = gate_guard_cpu_attribution(rc, cfg["cpu_s"])
        if _guard_diag:
            log(_guard_diag)

        # Peak RSS is logged on EVERY run, pass or fail, deliberately: it is the only evidence that
        # can later answer whether the layer-3 poll is being outrun by a fast allocator — which is
        # the stated precondition for taking on container isolation at all.
        log(f"gate-guard: gate exit {rc} after {int(time.monotonic() - started)}s — "
            f"peak group RSS {peak_rss_mb}MB "
            f"(tier {cfg['tier']}; caps: RSS {cfg['rss_mb']}MB, wall {cfg['wall_s']}s, "
            f"CPU {cfg['cpu_s']}s)")
        # GH-284 P2: the run log reports this lane's gate outcome; mirrors RUN_GATE_RESULT in the
        # Bash twin (green/red, "not-run" until the gate is first invoked).
        baseline_allow = args.pre_advance_baseline or os.environ.get("MARATHON_GATE_BASELINE")
        if baseline_allow and rc != 0 and rc != GATE_GUARD_KILL_EXIT:
            try:
                base_rc = int(baseline_allow)
                if rc == base_rc or (rc > 0 and rc <= base_rc):
                    log(f"gate-baseline: gate exit {rc} matches recorded baseline allowance ({base_rc}) — allowing advance (GH-378)")
                    run_gate_result[0] = "green"
                    return 0
            except ValueError:
                pass
        run_gate_result[0] = "green" if rc == 0 else "red"
        return rc

    def run_post_approve_cmd():
        cwd = args.target_root if args.target_root else None
        return subprocess.run(args.post_approve_cmd, shell=True, executable="/bin/bash", cwd=cwd).returncode

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

    def token_state(task_name=None):
        try:
            info = subprocess.check_output([tick_bin, "info", task_name or relay_task], stderr=subprocess.DEVNULL).decode('utf-8').splitlines()
        except Exception:
            return ("", "")
        status = claimer = handoff = ""
        for line in info:
            if line.startswith("status:"): status = line.split(":", 1)[1].strip()
            elif line.startswith("claimer:"): claimer = line.split(":", 1)[1].strip()
            elif line.startswith("handoff-to:"): handoff = line.split(":", 1)[1].strip()
        actor = claimer if status == "claimed" else (handoff if status == "open" else "")
        return (status, actor)

    def path_has_nonempty_phase_delta(path):
        # True iff <path> changed since pre_phase_head (committed diff), was DELETED, or is newly
        # untracked/added — provided that if it still exists it is non-empty. Shared by
        # --requires-test and artifact recovery: an empty or unchanged artifact is no evidence that a
        # builder turn made progress.
        #
        # GH-438 (partial): the existence test used to run first and unconditionally, so a lane whose
        # deliverable is REMOVING a path could never register progress — the artifact is gone, which
        # is the whole point, and the function read that as "no delta". The emptiness rule is what
        # actually earns its keep (a newly created empty file is not a deliverable), so it now applies
        # only when the path still exists, and git is trusted to report a deletion as the change it is.
        rroot = args.target_root or root
        abs_p = path if os.path.isabs(path) else os.path.join(rroot, path)
        if os.path.isfile(abs_p) and os.path.getsize(abs_p) == 0:
            return False
        git_path = path
        if os.path.isabs(path) and os.path.commonpath([os.path.abspath(path), os.path.abspath(rroot)]) == os.path.abspath(rroot):
            git_path = os.path.relpath(path, rroot)
        if pre_phase_head:
            out = subprocess.run(["git", "-C", rroot, "diff", "--name-only", pre_phase_head, "--", git_path],
                                 stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("utf-8", "replace")
            if out.strip():
                return True
        st = subprocess.run(["git", "-C", rroot, "status", "--porcelain", "--", git_path],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode("utf-8", "replace")
        for line in st.splitlines():
            # GH-438: " D"/"D " alongside the newly-added shapes, so a removal still registers when
            # there is no pre_phase_head to diff against (the branch above catches the normal case).
            if line.startswith("??") or line.startswith("A ") or line.startswith(" D") or line.startswith("D "):
                return True
        return False

    def requires_test_delta(path):
        # GH-249: --requires-test preserves its existing non-empty phase-delta contract.
        return path_has_nonempty_phase_delta(path)

    def acceptance_probes_unmet():
        # GH-438 Phase 2 — the lane's OWN acceptance detector, re-read after the build.
        #
        # swarm-preflight REQUIRES every fix_probe to read `unfixed` before a run; that is the
        # readiness check. Nothing re-read them afterwards, so a phase could report "Approved, gate
        # passed" and exit 0 while its own contract still said the fix had not landed. On the reported
        # lane the detector was `git ls-files --error-unmatch .mcp.json`: `unfixed` before, `unfixed`
        # after, Approved anyway, file still tracked. The signal existed and nobody looked at it.
        #
        # Returns None when there is nothing to judge (no brief, no contract, no probes) — that path
        # must stay byte-identical to before, because most lanes carry no probes and failing them
        # closed would break every one of them. Returns a (possibly empty) list of failures otherwise.
        if not args.phase_brief_file:
            return None
        # Read the contract as of pre_phase_head, NOT the working tree. The brief is an input to the
        # phase, and a builder that edited it could otherwise rewrite the criteria it is judged by —
        # marking its own homework. Falls back to the on-disk brief when there is no pre-phase commit
        # to read from (a first fire in a fresh repo), which is the same text either way.
        brief_rel = args.phase_brief_file
        if os.path.isabs(brief_rel):
            try:
                brief_rel = os.path.relpath(brief_rel, root)
            except ValueError:
                brief_rel = None
        contract_text = None
        if pre_phase_head and brief_rel and not brief_rel.startswith(".."):
            shown = subprocess.run(["git", "-C", root, "show", f"{pre_phase_head}:{brief_rel}"],
                                   stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            if shown.returncode == 0:
                contract_text = shown.stdout.decode("utf-8", "replace")
        if contract_text is None:
            try:
                with open(args.phase_brief_file, "r", encoding="utf-8", errors="replace") as f:
                    contract_text = f.read()
            except OSError:
                return None
        # No contract heading → nothing to judge. Checked here rather than by calling
        # extract_contract, which sys.exit(3)s on a brief without one and would take the driver with it.
        if not re.search(r'^#{1,6}\s+.*preflight\s+contract', contract_text, re.IGNORECASE | re.MULTILINE):
            return None
        try:
            sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
            from swarm_preflight import extract_contract, eval_probes
        except Exception as e:
            log(f"acceptance re-check SKIPPED — could not load the preflight evaluator ({e})")
            return None
        tmp_brief = os.path.join(tempfile.gettempdir(), f"marathon-acceptance-{os.getpid()}.md")
        try:
            with open(tmp_brief, "w", encoding="utf-8") as f:
                f.write(contract_text)
            try:
                contract = extract_contract(tmp_brief)
            except SystemExit:
                # A malformed contract is the author's problem, not this phase's verdict to make.
                log("acceptance re-check SKIPPED — the brief's preflight contract did not parse")
                return None
            if not contract.get("fix_probes"):
                return None
            probes, _stale, _blocked, _ambig = eval_probes(args.target_root or root, contract)
        finally:
            try: os.remove(tmp_brief)
            except OSError: pass
        # `landed` is the only verdict that means the fix is in. `unfixed` is the pre-run state still
        # reading true; `blocked` means the probe could not be evaluated, which is not evidence of
        # success either.
        return [p for p in probes if p.get("verdict") != "landed"]

    # GH-561: set to (repo, lane_branch, base_branch) when the branch guard redirects this run onto a
    # lane branch — read by open_lane_pr() on a green phase, which is the only thing that opens the PR.
    # A list because the guard is a closure and this is the existing idiom in this function.
    #
    # DECLARED HERE, not next to the guard that writes it, because complete_phase_success() below is
    # also called from the GH-274 already-satisfied path at a point where the guard has not run yet —
    # a NameError there would turn a healthy already-satisfied phase into a crash. On that path the
    # value is correctly None and open_lane_pr() is a no-op: nothing was cut, so there is no PR to open.
    lane_branch_cut = [None]

    def open_lane_pr():
        """Open a PR from this run's auto-cut lane branch back into the branch it was cut from.

        BEST-EFFORT BY CONSTRUCTION, and that is the whole design constraint. The phase is already
        green and its commits are already durable on the lane branch by the time this runs; a network
        blip, a logged-out `gh`, or a repo with no GitHub remote must not retroactively turn that into
        a failed phase. So every failure here is reported and swallowed. The commits are safe on the
        branch either way — the PR is the convenience, not the record.
        """
        if not lane_branch_cut[0]:
            return                      # ran on a branch already, or an explicit --allow-trunk-commit
        repo, head, base = lane_branch_cut[0]
        closeout = os.path.join(xyz_harness, "relay-automation", "marathon-closeout.sh")
        if not os.path.isfile(closeout):
            log(f"lane PR: skipped — {closeout} not found")
            return
        # --no-commit is the load-bearing flag: closeout's default is `git add -A` + commit, which in
        # an automated call would sweep every unrelated dirty file in the target into the PR. The
        # driver has already committed everything this phase produced.
        cmd = [closeout, "--repo", repo, "--head", head, "--base", base,
               "--open-only", "--no-commit",
               "--title", f"Marathon lane {args.phase_id}",
               "--notes", f"Automated marathon closeout for phase `{args.phase_id}` (GH-561)."]
        res = subprocess.run(cmd, capture_output=True, text=True)
        for line in (res.stdout or "").splitlines() + (res.stderr or "").splitlines():
            if line.strip():
                log(f"lane PR: {line.strip()}")
        if res.returncode != 0:
            log(f"lane PR: closeout exited {res.returncode} — the phase is still GREEN and its commits "
                f"are on '{head}'. Open the PR by hand: "
                f"gh pr create --base {base} --head {head}")

    def complete_phase_success(success_mode="approved"):
        # GH-438 Phase 2: judged BEFORE the repo-level gate. The gate knows nothing about this lane's
        # acceptance — that is exactly why the reported lane passed it while having changed nothing —
        # so a lane that did not do its own job should say so in its own terms, not as a gate failure.
        unmet = acceptance_probes_unmet()
        if unmet:
            for p in unmet:
                log(f"acceptance probe still {p.get('verdict')}: type={p.get('type')} path={p.get('path')}")
            log(f"acceptance re-check FAILED — {len(unmet)} probe(s) report the fix did not land; the lane's own contract disagrees with the reviewer — escalating")
            escalate("acceptance-probes-unmet", 0)
            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — acceptance probes still report the fix did not land")
            sys.exit(5)
        if unmet is not None:
            log("acceptance re-check passed — every fix_probe reports the fix landed")
        log(f"relay approved — running pre-advance gate: {pre_advance_cmd}")
        gate_exit = run_pre_advance_gate()
        if gate_exit != 0:
            # GH-390 layer 5: a gate the guard killed is a different event from a gate that ran and
            # found a defect, and triaging the two together is what made the crashes hard to read.
            # Both halt the phase; only the reason string differs.
            if gate_exit == GATE_GUARD_KILL_EXIT:
                log(f"pre-advance gate KILLED by the resource guard (exit {gate_exit}) — escalating")
                escalate("gate-killed", 0)
                xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate killed by the resource guard")
            else:
                log(f"pre-advance gate FAILED (exit {gate_exit}) — escalating")
                escalate("pre-advance-failed", 0)
                xyz_marathon_emit("red", f"halted at phase {args.phase_id} — pre-advance gate failed")
            sys.exit(5)
        if args.requires_test and not requires_test_delta(args.requires_test):
            log(f"requires-test FAILED — no new/updated test detected at: {args.requires_test}")
            escalate("requires-test-missing", 0)
            xyz_marathon_emit("red", f"halted at phase {args.phase_id} — required test not added/updated: {args.requires_test}")
            sys.exit(5)
        if success_mode == "already-satisfied":
            success_text = f"phase {args.phase_id} complete — lane_already_satisfied, reviewer approved, gate passed"
        else:
            success_text = f"phase {args.phase_id} complete — STATUS: Approved, gate passed"
        subprocess.run([tick_bin, "log", "marathon.phase.approved", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)
        save_transcript()
        _phase_memory_sample(f"{args.phase_id}-complete", root=root, tick_bin=tick_bin, relay_task=relay_task)
        phase_outcome_recorded[0] = True   # GH-388: a decided outcome with a durable record
        log(success_text)
        xyz_marathon_emit("green", success_text)
        if args.post_approve_cmd:
            log(f"phase approved — running post-approve command: {args.post_approve_cmd}")
            post_approve_exit = run_post_approve_cmd()
            if post_approve_exit != 0:
                log(f"post-approve command FAILED (exit {post_approve_exit}) — phase remains approved; escalating closeout")
                escalate("post-approve-failed", 0)
                sys.exit(9)
        open_lane_pr()
        sys.exit(0)

    # GH-274: has this phase's relay ALREADY reached a terminal state (RELAY_FILE's STATUS is
    # Approved/Closed) with its tick token ALREADY `done`? If so there is nothing left to
    # (re)build or (re)review — the only reason to re-invoke marathon-drive for it is to retry a
    # flaky --pre-advance-cmd without touching the phase's own record. A `done` tick token can
    # never be reopened (reconcile_relay_task's correct, existing behavior), so re-rendering +
    # re-seeding here would only clobber the accurate terminal RELAY.md before failing anyway.
    # Checked before the render (below); extends GH-207's already-satisfied detection
    # (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute) to this
    # separate post-terminal-gate-retry trigger. DRY_RUN is exempted: its whole point is to
    # render + show the tick seed for inspection, and there is nothing to commit or seed here.
    def recorded_relay_task():
        # The `task=` field of the relay file's own marathon-drive directive: which token this phase
        # was last RENDERED for. Extracted so completed_relay_task() and GH-491's advisory read it
        # one way. Callers apply their own trust rules — this returns the raw claim, not a verdict.
        recorded = ""
        try:
            with open(relay_file, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    if not line.lstrip().startswith("<!-- marathon-drive:"):
                        continue
                    for field in line.split():
                        if field.startswith("task="):
                            recorded = field.split("=", 1)[1].strip()
                    break
        except OSError:
            pass
        return recorded

    def completed_relay_task():
        # GH-385: the token that RECORDED this phase's completion is not necessarily the base token
        # this run computed. A phase that once failed and was re-run with --retry completes on a
        # suffixed token (GH-116 allocates -2, -3, ...), while the base name keeps the dead attempt's
        # state forever. A later run without --retry then reads the base token, sees "not done", and
        # rebuilds a phase that is demonstrably Approved — a full builder + reviewer cycle, real
        # money on --builder claude, and observed re-introducing work that had been reverted.
        #
        # The relay file already records which task it was rendered for, in the marathon-drive
        # directive, and that render is redone on every fire including the retry — so the file is an
        # authoritative statement of the token this phase actually ran on. Prefer walking suffixes:
        # this answers "which token completed THIS relay" rather than "did any token for this phase
        # ever reach done", which would wrongly satisfy a lane whose retry belonged to another run.
        #
        # HARDENING (Codex review on #458): RELAY.md is the BUILDER'S artifact — writable by the very
        # agent whose work is under review — so `task=` is a hint, not an authority. Read
        # unconstrained it names ANY token, and the builder also writes `STATUS: Approved`, so the two
        # together are a complete forgery of the terminal state: point the directive at some unrelated
        # already-`done` token (a previous phase's, say) and satisfied_lane_terminal() accepts it as
        # proof that THIS phase completed, skips render/reseed, and reports success after the gate.
        # That is a strictly wider hole than the one being fixed — before this change the token check
        # was anchored to the harness-computed name, which the builder cannot influence. Two limits
        # restore that integrity while keeping the fix:
        #
        #   1. An explicit --relay-task means the OPERATOR named the token; use it and do not consult
        #      the file at all. This is what --retry passes, and a retry must never be satisfied by
        #      the attempt it was invoked to retry.
        #   2. Otherwise accept the recorded name only if it belongs to THIS lane's token family: the
        #      derived base itself, or one of GH-116's `-<n>` retry derivatives of it. Anything else
        #      falls back to the base token — i.e. exactly the pre-GH-385 behavior, which is safe.
        #
        # The rejection is logged rather than silently absorbed: a lane that rebuilds because its
        # directive was refused should say so, or this becomes another check nobody can see working.
        if args.relay_task:
            return relay_task
        recorded = recorded_relay_task()
        if not recorded or recorded == relay_task:
            return relay_task
        if re.fullmatch(re.escape(relay_task) + r"-\d+", recorded):
            return recorded
        log(f"relay directive names task '{recorded}', which is not {relay_task} or a retry derivative of it "
            f"— ignoring it and resolving the satisfied check against {relay_task}")
        return relay_task

    def satisfied_lane_terminal():
        if not os.path.isfile(relay_file):
            return False
        s = file_status()
        if not terminal_status(s):
            return False
        task = completed_relay_task()
        tstatus, _actor = token_state(task)
        if tstatus != "done":
            # GH-385 asked for this line by name: "Log the disagreement ... that single line would
            # have made this diagnosable immediately." A terminal relay whose token is not done is a
            # contradiction, and the rebuild that follows is otherwise indistinguishable in the log
            # from an ordinary first fire.
            log(f"phase {args.phase_id}: relay is terminal (STATUS: {s}) but token '{task}' reads "
                f"'{tstatus or 'unknown'}', not done — rebuilding; if this phase really did complete, "
                f"its record is on a token this run cannot see (see GH-385)")
            return False
        return True

    if not args.dry_run and satisfied_lane_terminal():
        log(f"phase {args.phase_id} already reached a terminal relay (STATUS: {file_status()}, token done) — skipping render/reseed, re-running only the pre-advance gate")
        complete_phase_success("already-satisfied")

    # GH-491: --retry (which arrives here as an explicit --relay-task) deliberately bypasses the
    # short-circuit above — completed_relay_task() returns the operator-named token without consulting
    # the file, because "a retry must never be satisfied by the attempt it was invoked to retry". That
    # rule is correct and is not changed here.
    #
    # The cost is that the CHEAP path becomes invisible exactly when it applies. Its log line prints
    # only after the operator has already chosen the right invocation, so choosing wrong produces a
    # rebuild and the reasonable conclusion that a rebuild was required. Observed 2026-08-10: three
    # codex builds and three agy reviews across two Nightwatch waves, both of whose base tokens read
    # `done` afterwards — every one of those turns was avoidable by re-firing without --retry.
    #
    # Advisory ONLY. --retry still rebuilds, because deliberately rebuilding an approved phase is
    # legitimate: an artifact that passed review and is nonetheless wrong is precisely when you want
    # one. This says what the cheaper option WOULD have done; it does not take it.
    if not args.dry_run and args.relay_task and os.path.isfile(relay_file):
        _s = file_status()
        if terminal_status(_s):
            _recorded = recorded_relay_task()
            if _recorded and token_state(_recorded)[0] == "done":
                log(f"phase {args.phase_id}: --retry given, so this run REBUILDS. But the relay is already "
                    f"terminal (STATUS: {_s}) and its recorded token '{_recorded}' reads done — re-firing "
                    f"WITHOUT --retry would have re-run only the pre-advance gate and dispatched no "
                    f"builder or reviewer turn (GH-491)")

    if not args.dry_run:
        try:
            out = subprocess.check_output(["git", "-C", root, "status", "--porcelain"], stderr=subprocess.DEVNULL).decode('utf-8')
            # GH-484: exclude the CONFIGURED phase-output dir, not a hardcoded "phases/". Two
            # reasons this must be the full repo-relative path and not a basename: a nested
            # --phases-dir state/marathon-runs would match "marathon-runs/" as a basename but
            # git porcelain emits "state/marathon-runs/...", and a vendored install's
            # <repo>/.xyz/marathon-system/ was never matched by the old literal at all — so a
            # vendored run used to flag its own phase output as stray. Empty prefix (phases dir
            # outside this repo) means nothing to exclude, which is correct: git would not list it.
            phases_rel = _repo_rel_prefix(phases_dir, root)
            dirty = []
            for line in out.splitlines():
                if len(line) >= 4:
                    p = line[3:]
                    in_phases = bool(phases_rel) and p.startswith(phases_rel)
                    if not in_phases and not p.startswith(".tick/"):
                        dirty.append(p)
            if dirty:
                log("WARNING: workspace is not clean — an autonomous builder can be distracted by stray files.")
                for p in dirty:
                    if p: log(f"  • {p}")
                if args.require_clean:
                    die("--require-clean set and the workspace has pre-existing changes (above)")
        except Exception: pass

    # GH-401: NOTHING below may touch the filesystem until the --dry-run exit has been passed. The
    # phase dir creation used to live here, above the render, so a dry run materialized phases/<id>/
    # in whatever repo it resolved to — the harness itself when no MARATHON_ROOT/--phases-dir was
    # given. Both the reads below (phase brief, prior-attempt peek) work fine against a phase dir that
    # does not exist yet, so the mkdir moves down next to the write it actually exists for.
    with open(args.phase_brief_file, "r") as f:
        brief_text = f.read()

    # GH-162: peek at prior attempts BEFORE rendering so a re-fired phase carries the debug-mantra note.
    debug_mantra_prior = debug_mantra_prior_attempts(get_env("TICK_REPO_ROOT", root), lane_state_key)
    debug_mantra_text = debug_mantra_note(
        debug_mantra_prior, phase_dir, os.path.join(xyz_harness, "relay-automation", "DEBUG-MANTRA.md"))

    tick_cli = tick_bin if tick_bin.startswith("/") else os.path.join(root, tick_bin)

    if args.artifact_paths:
        claim_paths = f"{rel_relay},{args.artifact_paths}"
        builder_impl_line = f"Implement the brief by creating/editing the artifact file(s): {args.artifact_paths}"
        builder_scope_line = f"Edit ONLY these paths: {rel_relay} and {args.artifact_paths}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
        reviewer_read_line = (
            f"Read the latest builder block above AND review the artifact file(s) on disk: {args.artifact_paths}. "
            "REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two "
            "rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of "
            "them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you "
            "are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review "
            "block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a "
            "reviewer that skipped the sweep is indistinguishable in the transcript from one that did "
            "it and found nothing, which is exactly how those 20 issues stayed invisible."
        )
        reviewer_scope_line = f"Edit ONLY {rel_relay} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
    else:
        claim_paths = rel_relay
        builder_impl_line = "Record your work directly in this relay file (relay-only phase — no source file to edit)."
        builder_scope_line = f"Edit ONLY {rel_relay}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
        reviewer_read_line = "Read the latest builder block above."
        reviewer_scope_line = "Do NOT run git. Do NOT touch any other file."

    relay_content = f"""# Marathon Phase {args.phase_id}
STATUS: Open
NEXT: {args.builder} (Builder)

<!-- marathon-drive: task={relay_task} builder={args.builder} reviewer={args.reviewer} round-cap={args.round_cap} -->

## Phase Brief

{brief_text}
{debug_mantra_text}
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
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to {args.reviewer} — {args.reviewer}, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: {args.reviewer} (Reviewer)`

---

▶ TAKE YOUR TURN ({args.reviewer} — REVIEWER role)

You are the REVIEWER for this phase. {reviewer_read_line}
1. Append a review block: `### Round N · Reviewer · {args.reviewer}` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: {args.builder} (Builder)`, then: {tick_cli} release {relay_task} --agent {args.reviewer} --to {args.builder}
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: {tick_cli} done {relay_task} --agent {args.reviewer}
4. Use this exact tick binary (run it from any directory) for all token operations: {tick_cli}
   {reviewer_scope_line}
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to {args.builder} —
   {args.builder}, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
"""

    if args.dry_run:
        log(f"dry-run: relay file would be rendered at {relay_file}")
        # GH-401: a dry run must not write, but it must still SHOW its work — otherwise the flag
        # becomes "do nothing and tell you nothing", and the render (the expensive, interesting part)
        # is unobservable. Emitting it here is not a test affordance: test/debug-mantra.sh has always
        # relied on --dry-run to produce a rendered relay it can inspect WITHOUT driving a phase or
        # touching .tick/attempts/<lane>, which is the state that test hand-seeds. That need is real;
        # the file write it used to ride on is what was wrong. Fenced so a caller can extract the
        # render exactly, and so a grep for template text can't be confused with a driver log line.
        print("--- BEGIN RENDERED RELAY ---")
        print(relay_content, end="")
        print("--- END RENDERED RELAY ---")
        print(f"tick seed: log task.created {relay_task} + claim --agent marathon + release --to {args.builder}")
        sys.exit(0)

    # GH-514: prove the repo can TRACK this run's write-set before anything is dispatched.
    #
    # `marathon.sh --help` has always stated this failure — "without --target-root, marathon-drive's
    # `git add` of RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs" — and nothing
    # checked it. So a repo that deliberately ignores harness output (a public one, or a vendored
    # install where ensure_gitignore added `.xyz/` and never un-ignored the output dirs, #314) was
    # discovered as a halt AFTER a builder turn had been spent. Worse on the escalation path: the
    # record explaining why the run stopped is itself one of the files that cannot be committed, so
    # the run loses its own account of the failure.
    #
    # Checked against `root`, deliberately, because that is the repo these files are committed to —
    # under --target-root only CODE changes land elsewhere, and the relay/escalation/transcript stay
    # here. Checking the target instead would be the plausible-looking wrong answer.
    # GH-314: the write set is THREE paths, not two. `save_transcript()` also does a
    # `git add --` with check=True on a file under the transcript root, so an ignored
    # `relay-system/` HALTs the chain after the turn is already spent — the same defect this
    # preflight exists to stop, on the one path it was not checking. That third call site is
    # exactly the one #314's second reporter found the hard way, an afternoon at a time.
    #
    # The root is resolved the same way `save_transcript()` resolves it (rtl_transcript_root via
    # relay-turn-lib.sh) rather than assuming the literal `relay-system/`, because a vendored or
    # relocated install can move it and a hardcoded guess would check a path the run never writes.
    # If it cannot be resolved, the path is simply not added: this guard must not invent a new way
    # for a healthy run to fail, which is the same fail-open contract the docstring above sets.
    _write_set = [relay_file, os.path.join(phase_dir, "ESCALATION.md")]
    try:
        _ts_base = subprocess.check_output(
            "source \"%s\" && rtl_transcript_root \"%s\"" % (
                os.path.join(xyz_harness, "relay-automation", "relay-turn-lib.sh"), root),
            shell=True, executable="/bin/bash", stderr=subprocess.DEVNULL).decode("utf-8").strip()
        if _ts_base:
            # The probe path must MIMIC THE REAL SHAPE, not merely live under the same root.
            # `save_transcript()` writes <root>/<YYYY-MM-DD>/marathon-<phase>-<HHMMSS>.md, and an
            # ignore rule can legitimately key on either the dated directory (`relay-system/2026-*/`)
            # or the `.md` suffix. A synthetic `probe/transcript.md` would sail past the first of
            # those and let the run fail later on the real name — the exact late failure this check
            # exists to prevent. Found by an agy review of the first draft.
            # `_dt`, not `datetime`: module scope imports it as `import datetime as _dt` (line 13),
            # and the bare `import datetime` further down is local to save_transcript(). Using the
            # wrong name here raises NameError, which this block's own `except Exception` would
            # swallow — silently disabling the whole check while every test still passed.
            _probe_name = "marathon-%s-000000.md" % args.phase_id
            _write_set.append(os.path.join(
                _ts_base, _dt.datetime.utcnow().strftime("%Y-%m-%d"), _probe_name))
    except Exception as _exc:
        # Deliberately NOT fail-closed, and this is the one place worth arguing about.
        #
        # An agy review called the silent narrowing a blocker: if the root cannot be resolved the
        # transcript goes unchecked, supposedly risking the same expensive halt. That premise does
        # not hold here — `save_transcript()` resolves the root the SAME way and returns False on
        # failure (see its own try/except), so it never reaches its `git add`. A resolution failure
        # therefore produces no transcript and no halt, and refusing the run would invent a new way
        # for a healthy one to fail — precisely what preflight_write_set_trackable's docstring
        # forbids.
        #
        # The legitimate half of that review is that it was SILENT. It is not any more: a narrower
        # guard now says so, so nobody reads a green preflight as covering three paths when it
        # covered two.
        log("preflight: transcript root unresolved (%s) — write-set check covers RELAY.md and "
            "ESCALATION.md only, not the transcript" % _exc.__class__.__name__)
    preflight_write_set_trackable(root, _write_set)

    # GH-402: refuse to make the first commit if the RECEIVING repo is sitting on its trunk.
    #
    # `marathon/<slug>-<date>` is advisory text in a preflight packet and nothing enforces it, so a
    # marathon commits to whatever branch the target happens to have checked out. The driver is the
    # last common point on every commit path — relay turns, escalations, transcripts all funnel
    # through here — which is why the fix belongs at this one site rather than in each writer.
    #
    # Measured against `args.target_root or root`, the existing idiom for "the repo this run writes
    # to", and against THAT repo's trunk rather than the harness's: under --target-root they are
    # different repos with different defaults, and checking the harness's would be the plausible
    # wrong answer that passes every test written against a same-repo fixture.
    def refuse_trunk_commit():
        commit_root = args.target_root or root
        # The carve-out preflight already computes: risk==1 in an independent zone is allowed to
        # proceed on the current branch without asking (SP_SKIP_BRANCH_PROMPT). Honoured from the
        # environment rather than by parsing the packet — the driver does not read packets, and
        # GH-386 is what happens when something pretends it does.
        if os.environ.get("SP_SKIP_BRANCH_PROMPT") == "1":
            log("branch guard: skipped — preflight recorded the risk=1/independent-zone carve-out (GH-402)")
            return
        if args.allow_trunk_commit or os.environ.get("MARATHON_ALLOW_TRUNK_COMMIT") == "1":
            log("branch guard: overridden by --allow-trunk-commit / MARATHON_ALLOW_TRUNK_COMMIT (GH-402)")
            return

        current = _cmd_out(["git", "-C", commit_root, "symbolic-ref", "--quiet", "--short", "HEAD"])
        if not current:
            return          # detached HEAD: not trunk, and not this guard's business

        # Fires only on a SHARED trunk — one `origin/HEAD` actually resolves to. This is a narrowing
        # of trunk_ref()'s more permissive fallback, and it is deliberate on both counts.
        #
        # The harm this guard exists to prevent is stated in its own message: a marathon's turns
        # commit continuously, so a run that lands on trunk cannot be un-landed by stopping it, only
        # by rewriting history SOMEONE ELSE MAY ALREADY HAVE PULLED. In a repo with no remote there
        # is no someone else — a stray commit is local and `git reset` undoes it completely. Blocking
        # there would be spending a hard stop on a fully recoverable state.
        #
        # It is also what keeps the guard testable at all. Every fixture in this suite is a fresh
        # `git init` on `main` with no origin; with trunk_ref()'s current-branch fallback, this would
        # refuse to run in every one of them — a guard that cannot be exercised, which is the same
        # trap GH-388's durability rule hit and was scoped away from for the same reason.
        origin_head = _cmd_out(["git", "-C", commit_root, "symbolic-ref", "--quiet", "--short",
                                "refs/remotes/origin/HEAD"])
        if not origin_head or origin_head == "origin/HEAD":
            return
        trunk_branch = origin_head.split("/", 1)[1] if origin_head.startswith("origin/") else origin_head

        # GH-561: `origin/HEAD` alone is the WRONG protected set for this repo, and the gap is not
        # hypothetical — the 2026-08-15 Meter marathon landed four commits straight onto
        # `development` and the guard never fired, because origin/HEAD resolves to `origin/main`.
        #
        # `development` is this repo's INTEGRATION branch (AGENTS.md: "the standing WIP branch — ALL
        # work targets it, including marathon/relay-fired lanes ... branch off `development` and PR
        # back into it"), and `marathon-closeout.sh` already hardcodes `BASE_BRANCH="development"` as
        # the PR base. So the two halves of the same ceremony disagreed: closeout treated development
        # as something you PR INTO, the guard treated it as an ordinary branch you may commit ON.
        # The harm the guard's own message names — continuous turn commits that cannot be un-landed
        # without rewriting history someone else may have pulled — applies to the integration branch
        # exactly as it does to trunk. It is shared; that is the whole property that matters.
        #
        # Env-overridable rather than hardcoded so a fleet repo with a different integration branch
        # (or none) can say so; empty string disables the second half and restores GH-402 behaviour.
        integration = os.environ.get("MARATHON_INTEGRATION_BRANCH", "development")
        protected = {trunk_branch} | ({integration} if integration else set())
        if current not in protected:
            return

        kind = "trunk branch" if current == trunk_branch else "shared integration branch"

        # GH-561: CUT THE BRANCH rather than stopping. GH-402 shipped this as a hard refusal, and the
        # refusal was right about the harm but wrong about the remedy: the operator's next action was
        # always the same `checkout -b`, so a stop that only ever has one correct response is a
        # speed bump, not a decision point — and an unattended marathon has nobody there to take it.
        #
        # The invariant GH-402 defended is UNCHANGED and in fact enforced harder: no marathon commit
        # lands on a shared branch. It is now enforced by redirecting the commits somewhere safe
        # instead of by refusing to produce them.
        #
        # `--allow-trunk-commit` and the preflight carve-out still mean what they meant — "commit
        # here on purpose" — and both return above, before this runs.
        suggested = os.environ.get("SP_SUGGESTED_BRANCH", "")
        lane_branch = suggested or "marathon/{}-{}".format(
            re.sub(r"[^A-Za-z0-9._-]+", "-", args.phase_id).strip("-") or "lane",
            _dt.datetime.now().strftime("%Y-%m-%d"))

        # An existing branch is SWITCHED TO, not an error: a re-fired lane on the same day must land
        # on the branch its earlier attempt already built, or each attempt strands its commits on a
        # branch of its own and the PR shows one attempt's worth of work.
        exists = subprocess.run(["git", "-C", commit_root, "rev-parse", "--verify", "--quiet",
                                 f"refs/heads/{lane_branch}"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
        cut = subprocess.run(["git", "-C", commit_root, "checkout", "-q"]
                             + ([] if exists else ["-b"]) + [lane_branch],
                             capture_output=True, text=True)
        if cut.returncode != 0:
            # Falling back to GH-402's refusal is deliberate. The one thing that must never happen is
            # continuing on the shared branch because the redirect did not work — a failed auto-cut
            # is exactly when the original hard stop earns its keep.
            eprint(f"marathon-drive: BLOCKED — {commit_root} is checked out on its {kind} "
                   f"'{current}', and this run is about to commit to it.")
            eprint("")
            eprint(f"  Tried to cut '{lane_branch}' automatically and could not: "
                   f"{(cut.stderr or cut.stdout).strip()}")
            eprint("")
            eprint("  Nothing has been committed yet. A marathon's commits belong on a branch: its turns")
            eprint("  commit continuously, so a run that lands on a shared branch cannot be un-landed by")
            eprint("  stopping it — only by rewriting history someone else may already have pulled.")
            eprint("")
            eprint(f"    git -C {commit_root} checkout -b {lane_branch}")
            eprint("")
            eprint("  Or, if committing here really is intended, pass --allow-trunk-commit.")
            eprint("  Deliberately NOT covered by --force: that bypasses the per-lane attempt cap, and")
            eprint("  retrying a flaky lane must not silently grant permission to land on a shared")
            eprint("  branch (GH-402).")
            sys.exit(2)

        lane_branch_cut[0] = (commit_root, lane_branch, current)
        log(f"branch guard: {commit_root} was on its {kind} '{current}' — "
            f"{'switched to' if exists else 'cut'} '{lane_branch}' and continuing (GH-561)")
        log("  this lane's commits land there; a green phase opens a PR back into "
            f"'{current}' (--allow-trunk-commit to commit on '{current}' instead)")

    refuse_trunk_commit()

    os.makedirs(phase_dir, exist_ok=True)
    with open(relay_file, 'w') as f:
        f.write(relay_content)

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

    # The outer marathon-drive invocation owns this lane's attempt count. A parent relay-drive
    # process may have set this flag to suppress its nested accounting; do not let that inherited
    # value skip this invocation's own gate. The child relay-drive environment sets it explicitly
    # below to avoid double-counting, matching the Bash implementation.
    os.environ.pop("LANE_ATTEMPT_COUNTED", None)
    lane_attempt_gate(get_env("TICK_REPO_ROOT", root), lane_state_key, args.force)
    _run_tick_loud = run_tick_loud   # GH-408: module-level now, so it is directly testable

    reconcile_relay_task()

    _run_tick_loud([tick_bin, "log", "task.created", relay_task, "--agent", "marathon"])
    _run_tick_loud([tick_bin, "claim", relay_task, "--agent", "marathon", "--paths", rel_relay])
    _run_tick_loud([tick_bin, "release", relay_task, "--agent", "marathon", "--to", args.builder])
    log(f"tick token seeded: {relay_task} → {args.builder}")

    _run_tick_loud([tick_bin, "log", "marathon.phase.start", relay_task, "--agent", "marathon"])
    _phase_memory_sample(f"{args.phase_id}-start", root=root, tick_bin=tick_bin, relay_task=relay_task)
    log(f"phase start: running relay-drive --round-cap {args.round_cap}")
    # Past this point a phase is really being driven — arm the run log and start the driver
    # heartbeat. Same placement as MARATHON_DRIVE_STARTED=1 + marathon_driver_heartbeat_start in the
    # Bash twin, so --help / usage / lock contention / a parked lane / --dry-run never post a run log
    # or leave a liveness record behind.
    drive_started[0] = True
    driver_heartbeat_start()

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
        env2["TICK_REPO_ROOT"] = get_env("TICK_REPO_ROOT", root)
        return subprocess.run(cmd2, env=env2, cwd=root).returncode

    # GH-75: write liveness before the drive; clear it on ANY terminal path via atexit (registered only
    # here, so early exits before a live phase never register a spurious clear).
    xyz_marathon_heartbeat_write()
    import atexit as _atexit
    _atexit.register(xyz_marathon_heartbeat_clear)
    relay_exit = _run_relay_drive()

    # escalate/save_transcript/run_pre_advance_gate/file_status/terminal_status/token_state/
    # requires_test_delta/complete_phase_success are defined earlier (ahead of the render) —
    # see the GH-274 comment there — but still called from below as before.

    def artifacts_exist():
        if not args.artifact_paths:
            return False
        aroot = args.target_root or root
        for p in args.artifact_paths.split(","):
            p = p.strip()
            if not p:
                continue
            if not path_has_nonempty_phase_delta(p):
                return False
        return True

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

    timeout_reason = ["turn-timeout-or-hang"]
    timeout_emit = [f"halted at phase {args.phase_id} — turn timeout / hang"]

    def recover_timeout_exit():
        # GH-205: a relay timeout (exit 7) whose declared artifact already landed AND left a live
        # reviewer handoff is resumed with one more relay-drive pass instead of a false hang.
        #
        # GH-387: this used to PROBE THE PRE-ADVANCE GATE here, before any token inspection, and that
        # probe made the gate the first thing ever to execute work no human or reviewer had seen. A
        # turn killed at its wall-clock cap is still committed by rtl_enforce — deliberately, that is
        # GH-432's shipped fix against orphaned tokens and lost work — so the artifact on disk may be
        # a partial write from an agent that was killed mid-edit.
        #
        # The probe is gone, and NOTHING ELSE CHANGES, because the probe decided nothing. Every branch
        # below is resolved by artifacts_exist(), file_status() and token_state():
        #
        #   no artifact                    -> real hang, 7   (checked BEFORE the gate ever was)
        #   terminal status, no live actor -> continue,  0   (token)
        #   no live actor                  -> halt,      7   (token)
        #   actor is still the builder     -> real hang, 7   (token)
        #   actor moved to the reviewer    -> resume         (token)
        #
        # The tick token records the handoff DIRECTLY. The gate was only ever a proxy for the question
        # "did the builder finish and hand off?", which the token already answers — so GH-205's
        # hands-free recovery of a false hang is preserved intact, not traded away.
        #
        # What IS given up is the `timeout-gate-failed` early exit: a timed-out turn whose artifact was
        # already red used to halt here, and now resumes to the reviewer, who rejects it. That costs
        # one reviewer turn on work that was going to fail anyway. It was a fail-fast optimisation, not
        # a guarantee — and paying it buys "the gate is never the first executor of un-inspected code".
        #
        # The reviewer is now the first inspector, which is the correct order: a reviewer READS the
        # artifact, the gate EXECUTES it.
        #
        # STILL OPEN, deliberately not fixed here (see the capture doc): refusing this gate does not
        # stop a LATER invocation from executing a leftover partial, because path_has_nonempty_phase_delta
        # accepts an untracked file as evidence of work. Closing that needs a durable
        # `unreviewed-partial` marker — new persistent state, independent of this change.
        #
        # BASH/PYTHON DIVERGENCE, deliberate and pinned. The frozen twin still probes the gate here and
        # still sets TIMEOUT_ESCALATION_REASON="timeout-gate-failed"
        # (relay-automation/marathon-drive.sh:1208). It is frozen under GH-308 and is NOT to be taught
        # this fix as a drive-by change — that needs a `Frozen-twin-exception:` trailer and belongs to
        # retiring the twins. The Bash path is only reachable via XYZ_PYTHON=0 or a host with no
        # python3 >= 3.8; marathon-drive.sh:9 execs this file otherwise, which is the default. Same
        # shape as the GH-414 divergence note in route_agent above, and the same reason: the frozen
        # halves are the dead halves, and #379/#380 show they actively generate false bug reports.
        if not artifacts_exist():
            timeout_reason[0] = "timeout-no-artifact"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder produced no declared artifact"
            log("relay timed out (exit 7) before any declared artifact landed — treating it as a real hang")
            return 7
        log("relay timed out (exit 7) after declared artifact(s) appeared — reading the relay + token state "
            "(GH-387: the pre-advance gate is NOT run here; the reviewer inspects the artifact first)")
        s = file_status()
        tstatus, actor = token_state()
        if terminal_status(s) and not actor:
            log(f"timeout probe: relay already reached terminal agreement (STATUS: {s}, token done) — continuing")
            return 0
        if not actor:
            timeout_reason[0] = "timeout-no-live-actor"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder left no live reviewer handoff"
            log(f"timeout probe: artifact landed, but {relay_task} has no live actor (STATUS: {s}) — cannot continue")
            return 7
        if actor == args.builder:
            timeout_reason[0] = "timeout-builder-still-owned-turn"
            timeout_emit[0] = f"halted at phase {args.phase_id} — timed-out builder never handed the relay to review"
            log(f"timeout probe: builder still owns {relay_task} (STATUS: {s}) — treating this as a real hang")
            return 7
        log(f"timeout probe: artifact landed and {relay_task} moved to {actor} — resuming relay-drive from the post-timeout state")
        r = _run_relay_drive()
        if r == 7:
            timeout_reason[0] = "timeout-during-review-recovery"
            timeout_emit[0] = f"halted at phase {args.phase_id} — relay timed out again during review recovery"
        return r

    if relay_exit == 7:
        _r = recover_timeout_exit()
        relay_exit = 0 if _r == 0 else _r

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
        # GH-407: `pre-advance-failed` asserts a specific thing — the gate RAN and found a defect in
        # the change. Several unrelated failures also arrive here as relay exit 5 (a builder shim that
        # failed to start, a builder that exhausted its turn cap, a reviewer turn discarded by a
        # containment check), and every one of them used to be reported with that label. Observed
        # three times in a single 10-lane marathon on 2026-08-02 and wrong all three times; in one of
        # them the relay file even read STATUS: Approved.
        #
        # The driver runs the gate itself (run_pre_advance_gate below), so it knows the answer
        # without inferring it: if run_gate_result is still "not-run" when we get here, the gate
        # provably did not execute and no gate verdict may be claimed.
        #
        # The reason for that case deliberately does NOT name a cause. Distinguishing "builder failed
        # to start" from "cap exhausted" from "reviewer containment" needs a reason channel out of
        # relay-drive that does not exist (#408 is the same missing channel seen from the other side),
        # and a label that guesses would trade one confident wrong answer for another. It says what is
        # known: the relay failed before the gate.
        gate_ran = run_gate_result[0] != "not-run"
        if timeout_reason[0] != "turn-timeout-or-hang":
            reason, emit = timeout_reason[0], timeout_emit[0]
        elif gate_ran:
            reason = "pre-advance-failed"
            emit = f"halted at phase {args.phase_id} — pre-advance gate failed"
        else:
            reason = "relay-failed-before-gate"
            emit = f"halted at phase {args.phase_id} — relay failed before the gate ran"
        log(f"relay escalated: {reason} (gate: {run_gate_result[0]})")
        escalate(reason, 5)
        xyz_marathon_emit("red", emit)
        sys.exit(5)
    elif relay_exit == 6:
        log("relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)")
        escalate("containment-violation (off-lane edit reverted by a turn-taker)", 6)
        xyz_marathon_emit("red", f"halted at phase {args.phase_id} — containment violation (off-lane edit reverted)")
        sys.exit(6)
    elif relay_exit == 7:
        log("relay escalated: timeout / hang (relay-drive exit 7)")
        escalate(timeout_reason[0], 7)
        xyz_marathon_emit("red", timeout_emit[0])
        sys.exit(7)
    else:
        die(f"relay-drive exited with unexpected code {relay_exit}")

if __name__ == "__main__":
    # GH-284 P2 / GH-322: the Bash twin runs its run log + heartbeat stop from an EXIT trap that
    # captures `$?` first and re-exits with it explicitly, precisely so a failing reporting step can
    # never overwrite the driven run's real status. This is the same shape: the code is resolved
    # first, hooks run in a `finally` (so an exception path still clears the heartbeat), and the
    # original code is what we exit with. `die()` and every `sys.exit(N)` land in the SystemExit arm.
    # GH-388: line-buffer the driver's own narrative. Found by this lane's own regression test, which
    # killed a phase and recovered a log containing the child turn-shim's output and NONE of the
    # driver's. Python block-buffers stdout when it is not a TTY — and a marathon is never a TTY, so
    # the buffering is not an edge case, it IS the unattended path. Every `marathon-drive: ...` line
    # sat in a 8KB buffer that a SIGTERM discards, while the subprocesses wrote straight to the same
    # fd and survived. A run log fed by a buffered writer records the run right up until the moment
    # something goes wrong, which is the one moment it exists for.
    for _stream in (sys.stdout, sys.stderr):
        try:
            _stream.reconfigure(line_buffering=True)
        except Exception:
            pass    # Python < 3.7 or a stream that cannot be reconfigured — best effort

    # GH-388: without this the `finally` below is unreachable for the case the issue is ABOUT. A
    # SIGTERM — from an operator, a supervisor, a wall-clock kill, a host shutting down under the run
    # — terminates CPython immediately: no `finally`, no exit hooks, no record. SIGINT already raised
    # KeyboardInterrupt and so already reached them; SIGTERM did not, and SIGTERM is what an
    # unattended run actually receives. Converting it to SystemExit puts both on the same path.
    #
    # The exit code stays 128+signal, the shell convention the driver's own `_exit_meaning` and
    # marathon.sh's halt-reason table already read, so nothing downstream has to learn a new number.
    # SIGKILL and a host panic remain unreachable by design — no handler runs for those, which is why
    # the record this enables is a floor and not a guarantee, and why #384's recovery path is a
    # separate lane rather than something this one quietly claims to cover.
    def _terminate(signum, _frame):
        raise SystemExit(128 + signum)
    for _sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        try:
            signal.signal(_sig, _terminate)
        except (ValueError, OSError, AttributeError):
            pass    # not the main thread, or the platform has no such signal — best effort

    _exit_code = 0
    try:
        try:
            main()
        except SystemExit as _e:
            _exit_code = _e.code if isinstance(_e.code, int) else (0 if _e.code is None else 1)
        except BaseException:
            _exit_code = 1
            raise
    finally:
        for _hook in _ON_EXIT:
            try:
                _hook(_exit_code)
            except Exception:
                pass
    sys.exit(_exit_code)
