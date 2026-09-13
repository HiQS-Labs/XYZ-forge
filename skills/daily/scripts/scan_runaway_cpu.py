#!/usr/bin/env python3
"""
scan_runaway_cpu.py — Deterministic Scanner for Runaway CPU-Bound Processes on this Machine.

Used by the `/daily` skill (GH-194) as the machine CPU-health signal alongside
`scan_unclosed_loops.py`. Maintains a rolling snapshot at
`temp/daily-log/cpu-watch.json` so consecutive 15-minute cycles can be compared, and
flags processes that have pinned a core far longer than any legitimate foreground job:

  %CPU > 50  AND  duty cycle (CPU time / elapsed) > 0.5  AND  elapsed > 2h
  AND ( the same (pid, lstart) was seen in the previous cycle with growing CPU time
        OR elapsed > 24h )

Duty cycle is the load-bearing separator: during the 2026-09-06 incident the runaway
ran at 98% duty for 2d21h, while every legitimate long-lived process on this machine
(pulse_server, the mcp_server fleet) measured at or near 0% duty over days. Short
heavy jobs (builds, test suites, encodes) also run at duty ~1 but fail the 2h gate.

STRICTLY REPORT-ONLY: this scanner never signals or kills a process. A flagged line
carries the ready `kill <pid>` command; the operator decides.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

# --- Thresholds (agreed with the operator; false-alarm analysis in GH-194) ---------
CPU_PCT_THRESHOLD = 50.0
DUTY_CYCLE_THRESHOLD = 0.5
MIN_ELAPSED_SECONDS = 2 * 3600
PERSISTENT_ELAPSED_SECONDS = 24 * 3600
# CPU-time growth (seconds) between cycles required to call a persisted process
# "still accumulating" — absorbs ps sampling noise for an idle-but-alive process.
CPU_GROWTH_EPSILON = 1.0

# Known long-lived services: exempt before eligibility, even at pathological CPU.
# Keep this list explicit and short; anything legitimately compute-bound for days
# SHOULD surface — that is the point of the scanner.
SERVICE_EXEMPTIONS = (
    "rebalance.mcp_server",
    "pulse_server.py",
    "pet server",
    "Code Helper",
    "mem-watch",
    "backupd",
    "mds_stores",
    "kernel_task",
    "WindowServer",
)

# Mirrors scan_unclosed_loops.py's operator-machine convention: the /daily skill runs
# from the dev checkout and keeps its state under that checkout's gitignored temp/.
DEFAULT_STATE_PATH = Path("/Users/noelsaw/Documents/GH Repos/rebalanceOS/temp/daily-log/cpu-watch.json")

PS_COMMAND = ["ps", "-axo", "pid=,ppid=,pcpu=,etime=,cputime=,lstart=,command="]


def parse_ps_duration(text: str) -> float | None:
    """Parse a ps duration `[[dd-]hh:]mm:ss[.cc]` into seconds; None if not parseable.

    ps does not normalize carries — a 67.6-hour CPU time prints as `4056:39.31`
    (unbounded minutes) and a multi-day elapsed as `02-20:57:35` — so minute and
    hour components accept any non-negative count.
    """
    raw = text.strip()
    if not raw:
        return None
    days = 0.0
    if "-" in raw:
        day_part, _, raw = raw.partition("-")
        if not day_part.isdigit():
            return None
        days = float(day_part) * 86400
    parts = raw.split(":")
    if len(parts) > 3 or not all(p.strip() for p in parts):
        return None
    try:
        seconds = float(parts[-1]) if "." in parts[-1] else float(int(parts[-1]))
        minutes = float(int(parts[-2])) if len(parts) >= 2 else 0.0
        hours = float(int(parts[-3])) if len(parts) >= 3 else 0.0
    except ValueError:
        return None
    if seconds < 0 or minutes < 0 or hours < 0:
        return None
    return days + hours * 3600 + minutes * 60 + seconds


def is_exempt(command: str) -> bool:
    """True when the command matches a known long-lived service pattern."""
    return any(pattern in command for pattern in SERVICE_EXEMPTIONS)


def parse_ps_line(line: str) -> dict[str, Any] | None:
    """Parse one `ps -axo pid=,ppid=,pcpu=,etime=,cputime=,lstart=,command=` line.

    pid ppid pcpu etime cputime are single tokens; lstart is exactly five tokens
    (e.g. "Thu Sep 3 23:28:34 2026"); command is the remainder (may contain spaces).
    """
    tokens = line.split(None, 10)
    if len(tokens) < 11:
        return None
    pid_s, _ppid_s, pcpu_s, etime_s, cputime_s = tokens[:5]
    lstart = " ".join(tokens[5:10])
    command = tokens[10].rstrip("\n")
    if not pid_s.isdigit():
        return None
    try:
        pcpu = float(pcpu_s)
    except ValueError:
        return None
    elapsed = parse_ps_duration(etime_s)
    cpu_time = parse_ps_duration(cputime_s)
    if elapsed is None or cpu_time is None:
        return None
    return {
        "pid": int(pid_s),
        "pcpu": pcpu,
        "elapsed_s": elapsed,
        "cpu_s": cpu_time,
        "lstart": lstart,
        "command": command.strip(),
    }


def snapshot_processes() -> list[dict[str, Any]] | None:
    """One ps snapshot of the machine; None when ps itself failed (degraded cycle)."""
    try:
        res = subprocess.run(PS_COMMAND, capture_output=True, text=True, timeout=15)
    except Exception:
        return None
    if res.returncode != 0:
        return None
    parsed = []
    for line in res.stdout.splitlines():
        proc = parse_ps_line(line)
        if proc is not None:
            parsed.append(proc)
    return parsed


def process_key(proc: dict[str, Any]) -> tuple[int, str]:
    """(pid, lstart) — a restart gets a new lstart and counts as a fresh process."""
    return (proc["pid"], proc["lstart"])


def scan(
    processes: list[dict[str, Any]],
    prev_eligible: list[dict[str, Any]],
    prev_flagged: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Pure core: classify the snapshot against the previous cycle.

    Returns (eligible, flagged). `eligible` is everything that passed the threshold
    gates this cycle (the next cycle's persistence input); `flagged` is the subset
    that also satisfied the persistence-or-24h rule. Exempt processes appear in
    neither list, whatever their CPU.
    """
    prev_cpu = {process_key(p): float(p.get("cpu_s", 0.0)) for p in prev_eligible}
    prev_cycles = {process_key(p): int(p.get("cycles", 1)) for p in prev_flagged}

    eligible: list[dict[str, Any]] = []
    flagged: list[dict[str, Any]] = []
    for proc in processes:
        if is_exempt(proc["command"]):
            continue
        if not proc.get("elapsed_s") or not proc.get("cpu_s") or proc["elapsed_s"] <= 0:
            continue
        duty = proc["cpu_s"] / proc["elapsed_s"]
        if proc["pcpu"] <= CPU_PCT_THRESHOLD or duty <= DUTY_CYCLE_THRESHOLD:
            continue
        if proc["elapsed_s"] <= MIN_ELAPSED_SECONDS:
            continue
        proc = {**proc, "duty": round(duty, 4)}
        eligible.append(proc)

        key = process_key(proc)
        grew = key in prev_cpu and proc["cpu_s"] > prev_cpu[key] + CPU_GROWTH_EPSILON
        if not (grew or proc["elapsed_s"] > PERSISTENT_ELAPSED_SECONDS):
            continue
        cycles = prev_cycles.get(key, 0) + 1
        flagged.append(
            {
                **proc,
                "cycles": cycles,
                "kill_command": f"kill {proc['pid']}",
            }
        )
    return eligible, flagged


def load_state(state_path: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Previous cycle's (eligible, flagged); missing or malformed state = first sighting."""
    try:
        data = json.loads(state_path.read_text(encoding="utf-8"))
        return data.get("eligible", []), data.get("flagged", [])
    except (OSError, json.JSONDecodeError):
        return [], []


def save_state(state_path: Path, eligible: list[dict[str, Any]], flagged: list[dict[str, Any]]) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "eligible": eligible,
        "flagged": flagged,
    }
    state_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def format_candidate(proc: dict[str, Any]) -> str:
    """One flagged candidate, deterministic: PID 4377 python (90.7% CPU, 02-20:57:35 elapsed, duty 98%, cycles 3) [kill: kill 4377]"""
    return (
        f"PID {proc['pid']} {_short_command(proc['command'])} "
        f"({proc['pcpu']:.1f}% CPU, {_format_elapsed(proc['elapsed_s'])} elapsed, "
        f"duty {round(proc['duty'] * 100)}%, cycles {proc['cycles']}) [{proc['kill_command']}]"
    )


def _short_command(command: str, width: int = 60) -> str:
    cmd = " ".join(command.split())
    return cmd if len(cmd) <= width else cmd[: width - 1] + "…"


def _format_elapsed(seconds: float) -> str:
    total = int(seconds)
    days, rem = divmod(total, 86400)
    hours, rem = divmod(rem, 3600)
    minutes, secs = divmod(rem, 60)
    if days:
        return f"{days}d{hours:02d}:{minutes:02d}:{secs:02d}"
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


def format_summary(flagged: list[dict[str, Any]]) -> str:
    """The one-line markdown summary consumed by the daily log template."""
    if not flagged:
        return "- **Machine CPU Health**: clean (0 runaway CPU candidates)"
    shown = ", ".join(format_candidate(p) for p in flagged[:2])
    more = len(flagged) - 2
    if more > 0:
        shown += f", +{more} more"
    return f"- **Machine CPU Health**: {len(flagged)} runaway candidate{'s' if len(flagged) != 1 else ''} — {shown} `[Details: temp/daily-log/cpu-watch.json]`"


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan for runaway CPU-bound processes (report-only)")
    parser.add_argument("--json", action="store_true", help="Output the raw JSON analysis")
    parser.add_argument("--summary-line", action="store_true", help="Output the 1-line markdown summary (default)")
    parser.add_argument(
        "--state-path",
        type=Path,
        default=DEFAULT_STATE_PATH,
        help="Rolling snapshot path (default: the dev checkout's temp/daily-log/cpu-watch.json)",
    )
    parser.add_argument(
        "--update-state",
        action="store_true",
        default=True,
        help="Write the rolling snapshot so the next cycle can compare (default: on)",
    )
    args = parser.parse_args()

    processes = snapshot_processes()
    if processes is None:
        print("- **Machine CPU Health**: scanner degraded (ps unavailable this cycle)")
        return 0

    prev_eligible, prev_flagged = load_state(args.state_path)
    eligible, flagged = scan(processes, prev_eligible, prev_flagged)
    if args.update_state:
        save_state(args.state_path, eligible, flagged)

    if args.json:
        print(
            json.dumps(
                {
                    "summary_line": format_summary(flagged),
                    "thresholds": {
                        "cpu_pct": CPU_PCT_THRESHOLD,
                        "duty_cycle": DUTY_CYCLE_THRESHOLD,
                        "min_elapsed_s": MIN_ELAPSED_SECONDS,
                        "persistent_elapsed_s": PERSISTENT_ELAPSED_SECONDS,
                    },
                    "exemptions": list(SERVICE_EXEMPTIONS),
                    "eligible_count": len(eligible),
                    "flagged": flagged,
                    "state_path": str(args.state_path),
                },
                indent=2,
            )
        )
    else:
        print(format_summary(flagged))
    return 0


if __name__ == "__main__":
    sys.exit(main())
