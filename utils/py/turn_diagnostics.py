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
it stays affordable on a 30-minute turn. Network state is sampled once, only when
an otherwise-idle observation is classified. An established connection proves
that the turn may still be waiting on its backend; no connection does *not* prove
that it is wedged. If ``lsof`` is unavailable or fails, attribution degrades to
``timeout-unclassified`` and never changes the turn's exit code.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import threading
import time
from typing import TextIO

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

#: CPU-seconds growth between two samples that counts as "the tree did something".
#: Deliberately not zero: ``ps`` reports CPU at 10ms granularity and a fully idle
#: tree still jitters in the last digit, so an exact-equality test would score a
#: blocked turn as progressing every few samples and the idle clock would never
#: accumulate. 0.05s over a sample interval is far below anything real work
#: produces and far above the jitter.
CPU_PROGRESS_EPSILON_S = 0.05

#: Samples required before ``idle_seconds()`` will answer at all. An idle KILL is
#: irreversible, so it must never rest on one unlucky reading — a turn that is
#: genuinely working but happened to be between syscalls at sample time looks
#: identical to a blocked one for exactly one sample.
IDLE_MIN_SAMPLES = 3

REASON_SECURITY_DIALOG = "timeout-blocked-security-dialog"
REASON_CPU_BOUND = "timeout-cpu-bound"
REASON_SLOW_PROGRESS = "timeout-slow-but-progressing"
REASON_IDLE = "timeout-idle-unknown"
REASON_IDLE_IN_FLIGHT = "timeout-idle-in-flight"
REASON_UNCLASSIFIED = "timeout-unclassified"

TERMINATION_IDLE_KILL = "idle-kill"
TERMINATION_WALL_CAP = "wall-cap"
TERMINATION_CHILD_ORPHAN = "child-orphan"
TERMINATION_UNKNOWN = "unknown"
TERMINATION_KINDS = frozenset({
    TERMINATION_IDLE_KILL, TERMINATION_WALL_CAP,
    TERMINATION_CHILD_ORPHAN, TERMINATION_UNKNOWN,
})


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


def _tree_pids(root_pid: int, ps_output: str | None = None) -> list[int]:
    """Return *root_pid* and every descendant visible in one ``ps`` snapshot."""
    out = ps_output if ps_output is not None else _run(["ps", "-axo", "pid=,ppid="])
    if not out:
        return [root_pid]
    children: dict[int, list[int]] = {}
    for line in out.splitlines():
        fields = line.split(None, 2)
        if len(fields) < 2:
            continue
        try:
            pid, ppid = int(fields[0]), int(fields[1])
        except ValueError:
            continue
        children.setdefault(ppid, []).append(pid)
    pids, stack, seen = [root_pid], list(children.get(root_pid, [])), {root_pid}
    while stack:
        pid = stack.pop()
        if pid in seen:
            continue
        seen.add(pid)
        pids.append(pid)
        stack.extend(children.get(pid, []))
    return pids


def _network_state(root_pid: int) -> str:
    """Return network state for *root_pid* and its current descendants."""
    pids = ",".join(str(pid) for pid in _tree_pids(root_pid))
    try:
        probe = subprocess.run(
            ["lsof", "-a", "-n", "-P", "-p", pids,
             "-iTCP", "-sTCP:ESTABLISHED", "-F", "n"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            timeout=5.0, check=False,
        )
    except Exception:  # noqa: BLE001 — attribution must not fail the turn
        return "unclassified"
    if probe.returncode == 0:
        return "established" if probe.stdout.strip() else "none"
    if probe.returncode == 1:
        return "none"
    return "unclassified"


def termination_record(
    termination: str, reason: str, detail: str, *, exit_code: int = 7,
    observed_at: float | None = None,
) -> dict[str, object]:
    """Build one stable, JSON-safe termination record for a run log."""
    kind = termination if termination in TERMINATION_KINDS else TERMINATION_UNKNOWN
    return {
        "event": "turn-termination", "termination": kind, "reason": reason,
        "detail": detail, "exit_code": exit_code,
        "observed_at": time.time() if observed_at is None else observed_at,
    }


def emit_termination_record(
    termination: str, reason: str, detail: str, *, exit_code: int = 7,
    observed_at: float | None = None, stream: TextIO | None = None,
) -> dict[str, object]:
    """Write one structured termination record and return the same record."""
    record = termination_record(
        termination, reason, detail, exit_code=exit_code, observed_at=observed_at,
    )
    print(json.dumps(record, sort_keys=True), file=stream or sys.stderr, flush=True)
    return record


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


def _descendant_cpu_by_pid(root_pid: int) -> dict[int, float]:
    """Latest cumulative CPU seconds for each visible descendant."""
    out = _run(["ps", "-axo", "pid=,ppid=,time="])
    if not out:
        return {}
    cpu: dict[int, float] = {}
    for line in out.splitlines():
        fields = line.split(None, 2)
        if len(fields) < 3:
            continue
        try:
            pid = int(fields[0])
        except ValueError:
            continue
        cpu[pid] = _parse_ps_time(fields[2])
    return {pid: cpu.get(pid, 0.0) for pid in _tree_pids(root_pid, out)[1:]}


def _descendant_cpu_seconds(root_pid: int) -> tuple[float, int]:
    """Total CPU seconds and process count for root_pid's live descendants.

    Excludes root_pid itself — the shim's own CPU is not the agent's. Returns
    (0.0, 0) if the ps probe fails, which classify() treats as "no signal"
    rather than "idle".
    """
    cpu = _descendant_cpu_by_pid(root_pid)
    return (sum(cpu.values()), len(cpu))


# Existing suites monkeypatch the stable two-tuple probe above. Keep that seam
# while the production sampler uses the richer per-PID snapshot.
_ORIGINAL_DESCENDANT_CPU_SECONDS = _descendant_cpu_seconds


def _security_dialog_present() -> bool:
    """True if a process known to present modal auth dialogs has a visible window.

    Process existence alone over-triggers: SecurityAgent can linger as a
    backgrounded MachService (parent pid 1) well after any prompt it raised
    was answered — observed over an hour after an unrelated Keychain access
    elsewhere on the machine, with no dialog on screen. Requiring a visible
    window (System Events' ``visible`` property, scoped to this ONE named
    process — not "any osascript is running", the general approach already
    rejected above) is what actually distinguishes a blocking dialog from a
    quiescent daemon. If the visibility probe itself fails (no Accessibility
    permission, osascript unavailable), that name is skipped rather than
    assumed present — this function's caller already treats no-signal as no
    dialog, and understating a real block costs less than a false alarm.
    """
    for name in SECURITY_AGENT_PROCS:
        if not _run(["pgrep", "-x", name], timeout=3.0).strip():
            continue
        visible = _run(
            ["osascript", "-e",
             'tell application "System Events" to get visible of process "%s"' % name],
            timeout=3.0,
        ).strip()
        if visible == "true":
            return True
    return False


def _newest_mtime(root: str | None) -> float:
    """Newest mtime under root, or 0.0 if unavailable.

    Bounded: stops after MAX_ENTRIES so a large worktree cannot make a probe
    expensive enough to perturb the turn it is measuring.
    """
    if not root:
        return 0.0
    # GH-492: accept a single FILE as the progress signal, not just a directory. A consult runs
    # every advisor inside ONE shared worktree, so a directory mtime cannot tell which advisor is
    # working — but each advisor writes its own transcript, and that file growing IS its progress.
    if os.path.isfile(root):
        try:
            st = os.stat(root)
            # SUM, not max: callers only ever compare this value against its own previous reading,
            # so it just has to be non-decreasing and to move when EITHER input moves. Size is
            # included because an appending writer on a coarse mtime clock can add bytes without the
            # timestamp advancing — that is still progress, and a max() would hide it entirely
            # behind the numerically larger mtime.
            return st.st_mtime + float(st.st_size)
        except OSError:
            return 0.0
    if not os.path.isdir(root):
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

    def __init__(self, worktree: str | None = None, interval: float = DEFAULT_INTERVAL_S,
                 root_pid: int | None = None):
        self.worktree = worktree
        self.interval = interval
        # GH-492: a turn shim IS the process tree it measures, so its own pid is the right default.
        # A consult is not: it launches every advisor as a sibling under one parent, so measuring
        # `os.getpid()` there sums ALL advisors and one busy model masks another's hang. Passing the
        # advisor's own pid scopes the CPU reading to that advisor's subtree.
        self.root_pid = root_pid if root_pid is not None else os.getpid()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        # Sticky once CONFIRMED: a dialog that blocked the turn and was then
        # dismissed still explains the stall, so this is never cleared. It is
        # only set after DIALOG_CONFIRM_SAMPLES consecutive positives, so a
        # momentary auth elsewhere on the machine cannot set it.
        self.security_dialog_seen = False
        self._dialog_streak = 0
        self.samples: list[tuple[float, float, int]] = []   # (wall, cpu_seconds, nproc)
        # A child disappears from ps when it exits. Retain each PID's peak so a
        # workload made of short-lived children cannot erase CPU already spent.
        self._pid_cpu_peaks: dict[int, float] = {}
        self.mtime_start = 0.0
        self.mtime_last = 0.0
        # GH-492: monotonic timestamp of the last sample that showed the tree doing
        # SOMETHING — CPU growth past the jitter epsilon, or a file newer than the
        # one we last saw. `idle_seconds()` measures forward from here.
        self._last_progress_t: float | None = None
        # The process tree is reaped before classify() runs, so an in-flight
        # signal must be captured while the turn is alive. Probe at most once,
        # after enough otherwise-idle samples exist to justify the cost.
        self._network_probe_attempted = False
        self._network_state_observed: str | None = None

    def _sample(self) -> None:
        if _descendant_cpu_seconds is _ORIGINAL_DESCENDANT_CPU_SECONDS:
            current_cpu = _descendant_cpu_by_pid(self.root_pid)
            for pid, seconds in current_cpu.items():
                self._pid_cpu_peaks[pid] = max(self._pid_cpu_peaks.get(pid, 0.0), seconds)
            cpu, nproc = sum(self._pid_cpu_peaks.values()), len(current_cpu)
        else:
            # Backward-compatible test/probe seam: callers have long replaced
            # this helper with a two-tuple stub.
            cpu, nproc = _descendant_cpu_seconds(self.root_pid)
        now = time.monotonic()
        prev_cpu = self.samples[-1][1] if self.samples else None
        self.samples.append((now, cpu, nproc))
        if _security_dialog_present():
            self._dialog_streak += 1
            if self._dialog_streak >= DIALOG_CONFIRM_SAMPLES:
                self.security_dialog_seen = True
        else:
            self._dialog_streak = 0
        mtime_now = _newest_mtime(self.worktree)
        # GH-492: "progress" is deliberately the SAME two signals classify() already
        # reasons about, so an early idle kill can never disagree with the verdict
        # printed for it. A first sample counts as progress: it establishes the
        # baseline rather than starting the clock in the past.
        if (
            prev_cpu is None
            or cpu > prev_cpu + CPU_PROGRESS_EPSILON_S
            or mtime_now > self.mtime_last
        ):
            self._last_progress_t = now
        self.mtime_last = mtime_now
        if (
            not self._network_probe_attempted
            and len(self.samples) >= IDLE_MIN_SAMPLES
            and self.cpu_ratio() is not None
            and self.cpu_ratio() < CPU_BUSY_RATIO
            and not (self.mtime_last > self.mtime_start > 0)
        ):
            self._network_probe_attempted = True
            self._network_state_observed = _network_state(self.root_pid)

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

        Uses the PEAK observed cumulative CPU, not the last sample. A
        process's accounting disappears from ``ps`` the moment it exits, and the
        final sample is taken *after* the timeout kill — so reading the last
        sample scores a dead runaway as 0.00s/s and reports it as idle, which is
        exactly backwards. Cumulative CPU only rises while a process lives, so
        the peak is the true total for the tree.
        """
        if len(self.samples) < 2:
            return None
        t0, c0, _ = self.samples[0]
        c_peak = c0
        for _, c, _ in self.samples:
            if c > c_peak:
                c_peak = c
        # The denominator is the full observed window. Using the timestamp of
        # the CPU peak makes a brief startup burst look continuously busy after
        # a long idle hang.
        span = self.samples[-1][0] - t0
        if span <= 0:
            return None
        return max(0.0, (c_peak - c0)) / span

    def idle_seconds(self) -> float | None:
        """Wall seconds since the tree last showed CPU growth or file progress.

        ``None`` means "not enough evidence to say" — fewer than
        ``IDLE_MIN_SAMPLES`` readings, or no sample taken yet. Callers MUST treat
        ``None`` as "do not kill"; it is the not-yet-measured state, not zero.

        GH-492: this exists so a hang can be contained on a short idle threshold
        instead of only at the full wall cap. The observed incident produced 90
        consecutive samples reading ``cpu=0.02s/s, worktree-progress=no`` and they
        were unanimous from the start — the run learned nothing between sample 3
        and sample 90, it just spent ~900s to reach the same conclusion.

        Note this measures IDLENESS, not the turn's age. A turn that works for ten
        minutes and then blocks reports a small number here, which is correct: the
        thing worth killing early is the blockage, and its clock starts when the
        work stopped.
        """
        if len(self.samples) < IDLE_MIN_SAMPLES or self._last_progress_t is None:
            return None
        return max(0.0, time.monotonic() - self._last_progress_t)

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
        # Never probe here: timeout handling has already reaped the child tree.
        # A missing cached observation means live sampling never established a
        # safe idle window, so attribution must remain unclassified.
        network = self._network_state_observed
        if network is None:
            return (
                REASON_UNCLASSIFIED,
                f"live sampling never established a safe idle window for the network probe [{detail}]",
            )
        if network == "unclassified":
            return (
                REASON_UNCLASSIFIED,
                f"idle signals were observed, but the one-shot network probe failed [{detail}]",
            )
        if network == "established":
            return (
                REASON_IDLE_IN_FLIGHT,
                "no CPU or file growth was observed, but an established outbound connection "
                f"means the turn may still be awaiting its backend [{detail}]",
            )
        return (
            REASON_IDLE,
            "no CPU or file growth was observed and no established connection was visible; "
            f"without a positive in-flight signal the cause remains unknown [{detail}]",
        )

    def termination_record(
        self, termination: str, *, exit_code: int = 7,
        observed_at: float | None = None,
    ) -> dict[str, object]:
        """Classify this observation and package it for the run log."""
        reason, detail = self.classify()
        return termination_record(
            termination, reason, detail,
            exit_code=exit_code, observed_at=observed_at,
        )

    def emit_termination_record(
        self, termination: str, *, exit_code: int = 7,
        observed_at: float | None = None, stream: TextIO | None = None,
    ) -> dict[str, object]:
        """Classify and emit this observation as one structured log line."""
        reason, detail = self.classify()
        return emit_termination_record(
            termination, reason, detail,
            exit_code=exit_code, observed_at=observed_at, stream=stream,
        )
