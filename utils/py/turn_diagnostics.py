"""Attribution for a timed-out turn — why exit 7 happened, not just that it did.

A turn shim caps its agent on wall-clock and reports exit 7. That number alone
cannot distinguish outcomes that need opposite responses:

  - the agent was genuinely slow            -> raise the turn budget
  - the agent spun in a runaway loop        -> a real defect in the work
  - a modal OS dialog blocked the process   -> no budget will ever be enough;
                                               a human has to dismiss it

The third case is not hypothetical. A target repo that reads credentials through
the macOS keyring (``keyring.get_password``) triggers a Keychain prompt, which is
presented by a *separate* process and blocks the caller until answered. In a
headless turn nobody answers it, so the turn burns its entire budget and dies at
the wall clock — indistinguishable in the log from an agent that was merely slow.
Observed 2026-08-02 against rebalance-OS, where a p5 turn timed out and the cause
could not be established after the fact.

This generalises past Keychain: any modal prompt in any target repo (credential
helper, ``sudo`` password, first-run trust dialog) produces the same signature.
The harness cannot prevent a target repo from doing this, but it can say so.

WHY A SAMPLER AND NOT A HANDLER. ``subprocess.run(..., timeout=N)`` kills the
child and reaps it *before* raising ``TimeoutExpired``, so by the time the shim
can react, every process that would carry the evidence is gone. Sampling has to
run alongside the turn. The thread is a daemon and every probe is wrapped, so a
probe failure degrades the verdict to ``timeout-unclassified`` and can never fail
the turn it is describing.

The exit code is deliberately unchanged: callers keep seeing 7. This adds a
reason string next to it.

Deliberately stdlib-only and cheap: one ``ps`` and one ``pgrep`` per interval, so
it stays affordable on a 30-minute turn. A network probe (``lsof -i``, to prove
the agent is waiting on its API) was considered and left out — it is slow enough
to matter at this cadence, and worktree progress already separates "working" from
"wedged" without it.
"""

from __future__ import annotations

import os
import subprocess
import threading
import time

#: How often to sample. Cheap probes, but a turn can run 30+ minutes.
DEFAULT_INTERVAL_S = 10.0

#: CPU seconds per wall second, across the agent's process tree, above which the
#: turn is judged to be burning CPU rather than waiting. Deliberately low: one
#: fully-busy core is 1.0, and anything sustained above this is not idle waiting.
CPU_BUSY_RATIO = 0.15

#: macOS presents Keychain/authorization dialogs from these processes. Both are
#: specific to authorization UI and do not run otherwise.
#:
#: ``osascript`` was tried here and REMOVED: it is a general-purpose AppleScript
#: interpreter, so any unrelated automation on the machine trips it. Measured on
#: a developer Mac, transient ``osascript`` processes appeared within a 4-second
#: window with no dialog on screen. A false "a dialog blocked your turn" verdict
#: is worse than no verdict — it sends an operator after a problem that does not
#: exist — so this list stays narrow. Anything added here must have no reason to
#: run except to present an auth prompt.
SECURITY_AGENT_PROCS = ("SecurityAgent", "CoreAuthUI")

#: Consecutive positive samples before a dialog is believed. A dialog that
#: *blocks* a turn stays on screen; a single hit can be a momentary auth that
#: resolved itself. Requiring two consecutive samples means the prompt was up for
#: at least one full interval, which is the thing that actually stalls a turn.
DIALOG_CONFIRM_SAMPLES = 2

REASON_SECURITY_DIALOG = "timeout-blocked-security-dialog"
REASON_CPU_BOUND = "timeout-cpu-bound"
REASON_SLOW_PROGRESS = "timeout-slow-but-progressing"
REASON_IDLE = "timeout-idle-no-progress"
REASON_UNCLASSIFIED = "timeout-unclassified"


def _run(cmd: list[str], timeout: float = 5.0) -> str:
    """Best-effort command capture. Never raises; '' means the probe failed."""
    try:
        out = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            timeout=timeout, check=False,
        )
        return out.stdout.decode("utf-8", "replace")
    except Exception:  # noqa: BLE001 — a probe must never fail the turn
        return ""


def _parse_ps_time(value: str) -> float:
    """Parse a ``ps`` TIME field into seconds.

    Handles the shapes ps emits across platforms: ``mm:ss.ss``, ``hh:mm:ss``,
    and ``dd-hh:mm:ss``. Returns 0.0 on anything unrecognised rather than
    raising — a malformed field must not fail the turn.
    """
    value = (value or "").strip()
    if not value:
        return 0.0
    days = 0.0
    if "-" in value:
        head, _, value = value.partition("-")
        try:
            days = float(head)
        except ValueError:
            return 0.0
    parts = value.split(":")
    try:
        nums = [float(p) for p in parts]
    except ValueError:
        return 0.0
    if len(nums) == 3:
        h, m, s = nums
    elif len(nums) == 2:
        h, m, s = 0.0, nums[0], nums[1]
    elif len(nums) == 1:
        h, m, s = 0.0, 0.0, nums[0]
    else:
        return 0.0
    return days * 86400 + h * 3600 + m * 60 + s


def _descendant_cpu_seconds(root_pid: int) -> tuple[float, int]:
    """Total CPU seconds and process count for root_pid's descendants.

    Excludes root_pid itself — the shim's own CPU is not the agent's. Returns
    (0.0, 0) if the ps probe fails, which classify() treats as "no signal"
    rather than "idle".
    """
    out = _run(["ps", "-axo", "pid=,ppid=,time="])
    if not out:
        return (0.0, 0)
    children: dict[int, list[int]] = {}
    cpu: dict[int, float] = {}
    for line in out.splitlines():
        fields = line.split(None, 2)
        if len(fields) < 3:
            continue
        try:
            pid, ppid = int(fields[0]), int(fields[1])
        except ValueError:
            continue
        children.setdefault(ppid, []).append(pid)
        cpu[pid] = _parse_ps_time(fields[2])
    total, count, stack = 0.0, 0, list(children.get(root_pid, []))
    seen = set()
    while stack:
        pid = stack.pop()
        if pid in seen:
            continue
        seen.add(pid)
        total += cpu.get(pid, 0.0)
        count += 1
        stack.extend(children.get(pid, []))
    return (total, count)


def _security_dialog_present() -> bool:
    """True if a process known to present modal auth dialogs is running."""
    for name in SECURITY_AGENT_PROCS:
        if _run(["pgrep", "-x", name], timeout=3.0).strip():
            return True
    return False


def _newest_mtime(root: str | None) -> float:
    """Newest mtime under root, or 0.0 if unavailable.

    Bounded: stops after MAX_ENTRIES so a large worktree cannot make a probe
    expensive enough to perturb the turn it is measuring.
    """
    if not root or not os.path.isdir(root):
        return 0.0
    MAX_ENTRIES = 4000
    newest, seen = 0.0, 0
    try:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules", ".venv")]
            for name in filenames:
                seen += 1
                if seen > MAX_ENTRIES:
                    return newest
                try:
                    m = os.stat(os.path.join(dirpath, name)).st_mtime
                except OSError:
                    continue
                if m > newest:
                    newest = m
    except Exception:  # noqa: BLE001
        return newest
    return newest


class TurnDiagnostics:
    """Samples a running turn so a timeout can be attributed to a cause.

    Usage mirrors the shims' existing shape::

        diag = TurnDiagnostics(worktree=run_cwd)
        diag.start()
        try:
            subprocess.run(..., timeout=turn_timeout)
        except subprocess.TimeoutExpired:
            bounded_rc = 7
        finally:
            diag.stop()
        if bounded_rc == 7:
            reason, detail = diag.classify()
    """

    def __init__(self, worktree: str | None = None, interval: float = DEFAULT_INTERVAL_S):
        self.worktree = worktree
        self.interval = interval
        self.root_pid = os.getpid()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        # Sticky once CONFIRMED: a dialog that blocked the turn and was then
        # dismissed still explains the stall, so this is never cleared. It is
        # only set after DIALOG_CONFIRM_SAMPLES consecutive positives, so a
        # momentary auth elsewhere on the machine cannot set it.
        self.security_dialog_seen = False
        self._dialog_streak = 0
        self.samples: list[tuple[float, float, int]] = []   # (wall, cpu_seconds, nproc)
        self.mtime_start = 0.0
        self.mtime_last = 0.0

    def _sample(self) -> None:
        cpu, nproc = _descendant_cpu_seconds(self.root_pid)
        self.samples.append((time.monotonic(), cpu, nproc))
        if _security_dialog_present():
            self._dialog_streak += 1
            if self._dialog_streak >= DIALOG_CONFIRM_SAMPLES:
                self.security_dialog_seen = True
        else:
            self._dialog_streak = 0
        self.mtime_last = _newest_mtime(self.worktree)

    def _loop(self) -> None:
        while not self._stop.is_set():
            try:
                self._sample()
            except Exception:  # noqa: BLE001 — never fail the turn being measured
                pass
            self._stop.wait(self.interval)

    def start(self) -> None:
        self.mtime_start = _newest_mtime(self.worktree)
        self.mtime_last = self.mtime_start
        self._thread = threading.Thread(target=self._loop, name="turn-diagnostics", daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if self._thread is not None:
            self._thread.join(timeout=2.0)

    def cpu_ratio(self) -> float | None:
        """CPU seconds per wall second over the sampled window, or None.

        Anchored on the PEAK observed cumulative CPU, not the last sample. A
        process's accounting disappears from ``ps`` the moment it exits, and the
        final sample is taken *after* the timeout kill — so reading the last
        sample scores a dead runaway as 0.00s/s and reports it as idle, which is
        exactly backwards. Cumulative CPU only rises while a process lives, so
        the peak is the true total for the tree.
        """
        if len(self.samples) < 2:
            return None
        t0, c0, _ = self.samples[0]
        t_peak, c_peak = t0, c0
        for t, c, _ in self.samples:
            if c > c_peak:
                t_peak, c_peak = t, c
        span = t_peak - t0
        if span <= 0:
            return None
        return max(0.0, (c_peak - c0)) / span

    def classify(self) -> tuple[str, str]:
        """Return (reason, human-readable detail) for a timed-out turn.

        Order matters: a security dialog outranks everything, because no budget
        change fixes it and the operator action is specific.
        """
        ratio = self.cpu_ratio()
        progressed = self.mtime_last > self.mtime_start > 0
        bits = []
        if ratio is not None:
            bits.append(f"cpu={ratio:.2f}s/s")
        bits.append(f"samples={len(self.samples)}")
        if self.worktree:
            bits.append("worktree-progress=" + ("yes" if progressed else "no"))
        detail = ", ".join(bits)

        if self.security_dialog_seen:
            return (
                REASON_SECURITY_DIALOG,
                "a modal auth dialog (Keychain/authorization) was on screen during this turn; "
                "the target repo requested credentials and no one could answer. Raising the turn "
                "budget will not help — run the agent with credentials preloaded, or stub the "
                f"target's keyring path. [{detail}]",
            )
        if ratio is None:
            return (REASON_UNCLASSIFIED, f"insufficient samples to attribute the timeout [{detail}]")
        if ratio >= CPU_BUSY_RATIO:
            return (
                REASON_CPU_BOUND,
                "the agent's process tree burned CPU continuously — this looks like a runaway "
                f"loop in the work, not a slow turn. [{detail}]",
            )
        if progressed:
            return (
                REASON_SLOW_PROGRESS,
                "the agent was writing files but did not finish — genuinely slow; raising the "
                f"turn budget is the appropriate response. [{detail}]",
            )
        return (
            REASON_IDLE,
            "no CPU and no file progress — the agent was blocked waiting on something external "
            f"(a lock, a prompt, or a hung network call) rather than working. [{detail}]",
        )
