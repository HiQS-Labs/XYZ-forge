#!/usr/bin/env bash
set -euo pipefail
#
# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
# Emits marathon.complete only when every phase is approved.
#
# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
# Cross-phase context injection (M6) and MARATHON-STATE.md projection (M7) are deliberately deferred —
# the boundary events already land in .tick/events/ (phase.start/approved/escalated, marathon.complete).
#
# Usage:
#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
#                                [--pre-advance-cmd CMD] [--dry-run] [--retry PHASE-ID]
#
# GH-212: default builder is `codex` — no per-call API charge (bills via the Codex/ChatGPT
# subscription; agy is the other cost-blind option). `--builder claude` spawns a headless Claude
# Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker, distinct from an
# interactive session. Use it only as an explicit, cost-acknowledged choice.
#
# GH-212: a plan's `--plan` YAML (+ its phase briefs) must resolve under PROJECT/2-WORKING/ in the
# target repo — not a standalone top-level folder (e.g. marathon-plans/<slug>/) an agent might
# pattern-match from a prior repo. Exempt: paths under this harness's own home (MARATHON_HOME —
# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
#
# GH-116: --retry <phase-id> recovers a phase whose relay task was left open/never-claimed
# (permanently spent, per this repo's claim-then-abandon constraint) WITHOUT manually renaming the
# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
# MARATHON-<ID>-TURN-<N> suffix (N starts at 2, checked via `tick info`) — every other phase derives
# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
#
# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
# max_review_rounds→--round-cap.
#
# Environment overrides (for tests):
#   MARATHON_HOME       — harness home (default: parent of this script's dir)
#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
#                         falling back to MARATHON_HOME outside a git repo)
#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
#
# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.

# GH-1006 / GH-777: observation routes through this existing entry point. The Python
# payload is read/report only; exec preserves the launcher's direct-child ownership.
if [[ "${1:-}" == "--progress-observer" ]]; then
  shift
  exec python3 - "$@" <<'MARATHON_PROGRESS_PY'
#!/usr/bin/env python3
"""Finite marathon observations; the launcher alone writes this projection.

No dispatch, worker signals, coordination writes or outcome decisions live here.
Driver terminal receipts remain authoritative; missing evidence stays unknown.
"""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import tempfile
import threading
import time
import uuid


def utc():
    return datetime.now(timezone.utc).isoformat()


def bounded_read(path):
    """Reject special/symlink files and cap reads, including concurrently growing files."""
    fd = None
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
        meta = os.fstat(fd)
        if not stat.S_ISREG(meta.st_mode) or meta.st_size > 1024 * 1024:
            return None
        with os.fdopen(fd, "rb") as stream:
            fd = None
            data = stream.read(1024 * 1024 + 1)
        return data.decode("utf-8") if len(data) <= 1024 * 1024 else None
    except (OSError, UnicodeError, TypeError):
        return None
    finally:
        if fd is not None:
            os.close(fd)


def read_json(path):
    try:
        value = json.loads(bounded_read(path) or "null")
        return value if isinstance(value, dict) else {}
    except ValueError:
        return {}


def write_context(path, data):
    fd, temporary = tempfile.mkstemp(prefix=".marathon-progress.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(data, stream)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def git_value(root, *args):
    try:
        return subprocess.check_output(["git", "-C", root, *args], stderr=subprocess.DEVNULL,
                                       timeout=2, text=True).strip() or "unknown"
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def matching_receipt(context):
    phase = context.get("phase", {})
    result = read_json(phase.get("result_file"))
    target = result.get("target_repo")
    if not isinstance(target, dict):
        return {}
    if (result.get("schema") != "marathon-drive/result@1"
            or result.get("execution_id") != phase.get("execution_id")
            or result.get("phase") != phase.get("id")
            or result.get("lane") != phase.get("lane")
            or target.get("path") != context["product_root"]):
        return {}
    token = result.get("token")
    family = phase["token_family"]
    if not isinstance(token, str) or not (token == family or token.startswith(family + "-")):
        return {}
    return result


def qualified(result):
    gate = result.get("gate")
    acceptance = result.get("acceptance")
    return (result.get("outcome") == "approved" and result.get("exit_code") == 0
            and isinstance(gate, dict) and gate.get("result") == "green" and gate.get("exit") == 0
            and bool(re.fullmatch(r"[0-9a-f]{40}(?:[0-9a-f]{24})?", str(result.get("reviewed_candidate"))))
            and bool(re.fullmatch(r"[0-9a-f]{40}(?:[0-9a-f]{24})?", str(result.get("reviewed_head"))))
            and isinstance(result.get("attest_path"), str) and bool(result["attest_path"])
            and not (isinstance(acceptance, dict) and acceptance.get("checked")
                     and acceptance.get("unmet_count") != 0))


def heartbeat(context):
    beat = read_json(context["heartbeat_file"])
    phase = context.get("phase", {})
    if (not phase or beat.get("phase_id") != phase.get("id")
            or beat.get("pid") != phase.get("driver_pid")):
        return {"state": "unknown"}
    token = beat.get("relay_task")
    family = phase["token_family"]
    if not isinstance(token, str) or not (token == family or token.startswith(family + "-")):
        return {"state": "unknown"}
    try:
        stamp = datetime.fromisoformat(beat["updated_utc"].replace("Z", "+00:00"))
        started = datetime.fromisoformat(beat["started_utc"].replace("Z", "+00:00"))
        # Driver timestamps have whole-second resolution; PID/phase/token provide attribution.
        run_started = datetime.fromisoformat(context["started_utc"]).replace(microsecond=0)
        age = (datetime.now(timezone.utc) - stamp).total_seconds()
        if age < 0 or started < run_started or stamp < started:
            raise ValueError("foreign or future heartbeat")
        return {"state": "liveness only", "age_s": round(age, 1), "pid": beat.get("pid")}
    except (KeyError, TypeError, ValueError, AttributeError):
        return {"state": "unknown"}


def emit(context, kind, **extra):
    phase = context.get("phase", {})
    relay = bounded_read(phase.get("relay_file")) or ""
    fields = {}
    for line in relay.splitlines():
        if line.startswith(("STATUS:", "NEXT:")):
            key, value = line.split(":", 1)
            fields.setdefault(key, value.strip())
    result = matching_receipt(context) if phase else {}
    report = {
        "kind": kind, "observed_at": utc(), "run_id": context["run_id"],
        "plan": context["plan"], "harness_root": context["harness_root"],
        "coordination_root": context["root"], "product_root": context["product_root"],
        "initial_head": context["initial_head"], "initial_origin": context["initial_origin"],
        "phase": phase.get("id", "not started"), "phase_index": phase.get("index", 0),
        "role": fields.get("NEXT", "unknown"), "relay_status": fields.get("STATUS", "unknown"),
        "heartbeat": heartbeat(context), "returned_success": context["returned_success"],
        "verified_phases": context["verified_phases"], "total_phases": context["total"],
        "last_product_milestone": context["last_milestone"],
        "gate": result["gate"] if isinstance(result.get("gate"), dict) else "unknown",
        "reviewed_candidate": result.get("reviewed_candidate") if re.fullmatch(
            r"[0-9a-f]{40}(?:[0-9a-f]{24})?", str(result.get("reviewed_candidate"))) else "unknown",
        "result_file": phase.get("result_file"), "relay_file": phase.get("relay_file"),
        "run_log": context["run_log"], **extra,
    }
    print("marathon-progress: " + json.dumps(report, sort_keys=True), flush=True)


def due_slots(start, interval, count, emitted, now):
    """Consume overdue slots; only the latest gets a present-time snapshot."""
    latest = min(count, int((now - start) // interval))
    return range(emitted + 1, max(emitted, latest) + 1)


def observe(path):
    initial = read_json(path)
    owner = initial["owner"]
    start, interval, count = initial["started_monotonic"], initial["interval"], initial["count"]
    stopped = threading.Event()
    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, lambda *_: stopped.set())
    emitted = 0
    while not stopped.is_set():
        context = read_json(path)
        if context.get("run_id") != initial["run_id"]:
            emit(initial, "observation-ended", reason="context unavailable or changed",
                 next_action="Inspect the original run log; execution status unknown")
            return
        if context.get("observation_stop"):
            return
        if os.getppid() != owner:
            emit(context, "owner-lost", execution_status="unknown", descendants="unknown",
                 next_action="Establish ownership and stopped descendants before any re-fire")
            return
        slots = list(due_slots(start, interval, count, emitted, time.monotonic()))
        for slot in slots:
            if slot != slots[-1]:
                print("marathon-progress: " + json.dumps({"kind": "missed-check", "run_id": initial["run_id"],
                                                        "check": slot, "count": count}, sort_keys=True), flush=True)
            else:
                emit(context, "check", check=slot, count=count)
            emitted = slot
        if emitted == count:
            emit(context, "observation-ended", execution_status="continues independently",
                 next_action="Inspect this run log or use marathon-detail.sh; no automatic retry")
            return
        stopped.wait(min(0.25, max(0, start + (emitted + 1) * interval - time.monotonic())))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("init", "phase", "driver", "finish", "observe", "terminal"))
    parser.add_argument("context", type=Path)
    for name in ("root", "product-root", "harness-root", "plan", "run-log", "phases-dir",
                 "heartbeat-file", "phase-id", "lane", "token-family", "execution-id", "result-file"):
        parser.add_argument("--" + name)
    for name in ("owner", "total", "interval", "count", "index", "exit-code", "driver-pid"):
        parser.add_argument("--" + name, type=int)
    args = parser.parse_args()
    if args.action == "observe":
        observe(args.context)
        return
    if args.action == "init":
        context = {"run_id": uuid.uuid4().hex, "owner": args.owner, "plan": str(Path(args.plan).resolve()),
                   "root": str(Path(args.root).resolve()), "product_root": os.path.abspath(args.product_root),
                   "harness_root": str(Path(args.harness_root).resolve()), "run_log": args.run_log,
                   "phases_dir": str(Path(args.phases_dir).resolve()), "heartbeat_file": args.heartbeat_file,
                   "initial_head": git_value(args.product_root, "rev-parse", "HEAD"),
                   "initial_origin": git_value(args.product_root, "remote", "get-url", "origin"),
                   "started_monotonic": time.monotonic(), "started_utc": utc(),
                   "interval": args.interval, "count": args.count,
                   "total": args.total, "returned_success": 0, "verified_phases": 0,
                   "milestones": [], "last_milestone": None}
        write_context(args.context, context)
        print(context["run_id"])
        return
    context = read_json(args.context)
    if args.action == "phase":
        context["phase"] = {"id": args.phase_id, "index": args.index, "lane": args.lane,
                            "token_family": args.token_family, "execution_id": args.execution_id,
                            "result_file": args.result_file,
                            "relay_file": str(Path(context["phases_dir"]) / args.lane / "RELAY.md")}
        write_context(args.context, context)
    elif args.action == "driver":
        context["phase"]["driver_pid"] = args.driver_pid
        write_context(args.context, context)
    elif args.action == "finish":
        context["phase"]["exit_code"] = args.exit_code
        result = matching_receipt(context)
        if args.exit_code == 0:
            context["returned_success"] += 1
        if args.exit_code == 0 and qualified(result):
            context["verified_phases"] += 1
            candidate = result["reviewed_candidate"]
            if (result.get("reason") != "already-satisfied" and candidate != context["initial_head"]
                    and candidate not in context["milestones"]):
                context["milestones"].append(candidate)
                context["last_milestone"] = {"phase": result["phase"], "candidate": candidate,
                                             "observed_at": utc(), "result_file": context["phase"]["result_file"]}
        write_context(args.context, context)
    else:
        context["observation_stop"] = True
        write_context(args.context, context)
        emit(context, "terminal", exit_code=args.exit_code, descendants="unknown",
             next_action="Inspect halt/repair evidence before any re-fire" if args.exit_code else "Review completed run evidence")


if __name__ == "__main__":
    main()
MARATHON_PROGRESS_PY
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARATHON_HOME="${MARATHON_HOME:-"$(cd "$HERE/.." && pwd)"}"
if [[ -n "${MARATHON_ROOT:-}" ]]; then
  ROOT="$MARATHON_ROOT"
elif ROOT="$(git -C "${PWD:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  ROOT="$MARATHON_HOME"
fi
TICK_BIN="${TICK_BIN:-"$MARATHON_HOME/bin/tick"}"
DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
YAML_BIN="${MARATHON_YAML_BIN:-"$MARATHON_HOME/bin/marathon-yaml"}"
CLOSEOUT_BIN="${MARATHON_CLOSEOUT_BIN:-"$MARATHON_HOME/relay-automation/marathon-closeout.sh"}"

die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
log() { printf 'marathon: %s\n' "$*"; }

XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$MARATHON_HOME/utils/telemetry/append-xyz-completion.sh"}"

# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
# run isn't silently absent from XYZ.json (GH-75 review: an early halt used to skip the tail entirely,
# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
xyz_marathon_run_emit() {  # <health> <description>
  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
  local plan; plan="$(basename "$PLAN")"; plan="${plan%.*}"; [[ -n "$plan" ]] || plan="marathon"
  "$XYZ_APPEND_BIN" marathon "$plan" "$1" "$plan" "$2" >/dev/null 2>&1 || true
}

usage() {
  cat <<'EOF'
Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
                    [--dry-run] [--force] [--retry PHASE-ID] [--closeout-pr]

  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
                          the target repo (GH-212) — exempt: paths under this harness's own home
                          (shipped examples), or MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
  --builder AGENT         Builder agent id (default: codex — no per-call API charge; bills via the
                          Codex/ChatGPT subscription). --builder claude spawns a headless Claude
                          Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker —
                          an explicit, cost-acknowledged choice, not the default.
  --phases-dir DIR        Where to create <dir>/<id>/ (default: <repo-root>/marathon-system).
  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
                          The relay thread, tick token, marathon-system/ and relay-system/ transcripts all stay
                          in THIS harness repo — only code changes land in DIR. Use this when the target
                          repo cannot track harness output (e.g. a public repo that gitignores marathon-system/
                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
                          RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.
                          Plan and brief paths resolve against DIR when set.
                          GH-255 — pick the right knob for what is actually ignored: if the target
                          ignores ONLY relay-system/, prefer XYZ_ARCHIVE_ROOT (GH-30), which
                          redirects just the transcripts and leaves the code artifact and the
                          .tick token anchored to the target. --target-root is the answer when
                          marathon-system/ is ignored too, because XYZ_ARCHIVE_ROOT does not
                          redirect RELAY.md / ESCALATION.md and will leave that run blocked.
  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
  --force                 GH-45: bypass the per-lane attempt cap for this run.
  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix. This REBUILDS the
                          phase — a full builder + reviewer cycle — because a retry must never be
                          satisfied by the attempt it was invoked to retry.
                          GH-491: if the phase's relay is already terminal (STATUS: Approved) and its
                          token is done, and only the GATE went red, do NOT use this. Re-fire the plan
                          plainly instead: the driver detects the satisfied lane and re-runs only the
                          pre-advance gate, dispatching no turns. Use --retry when the ARTIFACT is what
                          needs to change.
  --closeout-pr           Open (but never merge) a PR after a successful marathon. Closeout failure is logged
                          and does not change the successful marathon exit code.
  --progress-interval-s N Opt in to finite stdout/run-log observations (default: 600 seconds).
  --progress-check-count N Number of checks across the entire chain (default: 6).
                          Interval <=86400, count <=144, window <=86400s. Window end stops only
                          observation; it never retries or stops work. Requires Python driver.
EOF
}

PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
PROGRESS_ENABLED=0; PROGRESS_INTERVAL=600; PROGRESS_COUNT=6
while (($# > 0)); do
  case "$1" in
    --plan)            PLAN="${2:-}"; shift 2 ;;
    --builder)         BUILDER="${2:-}"; shift 2 ;;
    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
    --progress-interval-s) [[ $# -ge 2 ]] || die "$1 requires a positive integer"; PROGRESS_ENABLED=1; PROGRESS_INTERVAL="$2"; shift 2 ;;
    --progress-check-count) [[ $# -ge 2 ]] || die "$1 requires a positive integer"; PROGRESS_ENABLED=1; PROGRESS_COUNT="$2"; shift 2 ;;
    --help)            usage; exit 0 ;;
    *)                 die "unknown argument: $1" ;;
  esac
done
[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
if ((PROGRESS_ENABLED)); then
  [[ "$PROGRESS_INTERVAL" =~ ^[1-9][0-9]*$ && ${#PROGRESS_INTERVAL} -le 5 ]] || die "progress interval must be a positive integer <=86400"
  [[ "$PROGRESS_COUNT" =~ ^[1-9][0-9]*$ && ${#PROGRESS_COUNT} -le 3 ]] || die "progress count must be a positive integer <=144"
  PROGRESS_INTERVAL=$((10#$PROGRESS_INTERVAL)); PROGRESS_COUNT=$((10#$PROGRESS_COUNT))
  ((PROGRESS_INTERVAL <= 86400 && PROGRESS_COUNT <= 144 && PROGRESS_INTERVAL * PROGRESS_COUNT <= 86400)) || die "progress interval/count/window exceeds bounds (86400s/144/86400s)"
  [[ "${XYZ_PYTHON-1}" == 1 ]] || die "progress observation requires the Python driver's terminal receipts; omit progress flags for XYZ_PYTHON=0"
fi

# GH-212: plan-location guard. A marathon's plan artifacts (this YAML + its phase briefs) belong
# under PROJECT/2-WORKING/<capture-doc>/, not a standalone top-level folder (e.g. marathon-plans/)
# an agent might pattern-match from a prior repo. Exempt: paths under this harness's own home
# (MARATHON_HOME) — shipped reference examples (e.g. MARATHON.example.yaml), not an agent-authored
# plan for a target repo. Override for a legitimate non-default location:
# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
_plan_abs="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
# Canonicalize with `pwd -P` unconditionally (relative AND already-absolute input): ROOT can come
# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
# (whatever form the caller passed), so either side of this comparison can be a logical (non -P)
# path — canonicalize both or a macOS /var -> /private/var checkout falsely flags every plan.
# symlinks (e.g. macOS /var -> /private/var), so a logical (non -P) comparison here would falsely
# flag every plan as "outside" on such a checkout (same pitfall swarm-preflight.sh works around).
# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
# so this guard must measure against that repo — otherwise every cross-repo plan falsely "resolves
# outside PROJECT/2-WORKING/" and dies. GH-212's intent is unchanged: the plan must sit under
# PROJECT/2-WORKING/ of whichever repo owns it.
_plan_base="${TARGET_ROOT:-$ROOT}"
_root_canon="$(cd "$_plan_base" 2>/dev/null && pwd -P || printf '%s' "$_plan_base")"
_home_canon="$(cd "$MARATHON_HOME" 2>/dev/null && pwd -P || printf '%s' "$MARATHON_HOME")"
_plan_rel_root="${_plan_abs#"$_root_canon"/}"
case "$_plan_rel_root" in
  PROJECT/2-WORKING/*) ;;   # in the expected home — proceed
  *)
    case "$_plan_abs" in
      "$_home_canon"/*) ;;   # harness-owned reference material — exempt
      *)
        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
        fi
        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
        ;;
    esac
    ;;
esac

export TICK_REPO_ROOT="$ROOT"

# ── GH-388: the chain run log ────────────────────────────────────────────────────────────────────
# This file persisted NOTHING of its own — no tee, no `exec >`, no log-file variable. What was
# durable got written per phase, ON COMPLETION, so the phase that DIES is the one phase with no
# record, and the chain-level narrative existed only on the operator's terminal. Whether any of it
# survived a crash depended on whether whoever typed the command happened to redirect stdout
# somewhere durable. In the run that produced this issue they had — to a path the platform clears at
# boot — and after the panic reboot it was gone.
#
# Where the run narrative goes is the HARNESS's decision now, not the invoker's. Same transcript root
# the per-phase transcripts already use (rtl_transcript_root), so one place holds both.
#
# Armed here, deliberately AFTER plan parse/validate and BEFORE the phase loop: a usage error, an
# unparseable plan or a --plan outside PROJECT/2-WORKING has no run to narrate, and must not leave an
# empty log implying one happened. --dry-run is excluded for the same reason.
MARATHON_RUN_LOG=""
if ((DRY_RUN == 0)); then
  # Sourced only if present. MARATHON_HOME is overridable (tests point it at a minimal fake home,
  # and a vendored `.xyz/` install may lag a re-vendor), so an unconditional `source` turns a missing
  # optional helper into a dead marathon — which is how this first landed, breaking the GH-212
  # harness-home-exempt case. A missing lib costs the durability CHECK, not the run log.
  _dl_lib="$MARATHON_HOME/relay-automation/durable-log-lib.sh"
  if [[ -f "$_dl_lib" ]]; then
    # shellcheck source=/dev/null
    source "$_dl_lib"
  else
    xyz_non_durable_reason() { :; }
    xyz_non_durable_conf() { printf '(durable-log-lib.sh not installed)'; }
    _xyz_realish_path() { printf '%s' "${1:-}"; }
  fi
  # Resolved by SOURCING the shared resolver rather than re-deriving `<root>/relay-system` here — a
  # second copy of that rule is how the run log and the per-phase transcripts would end up in
  # different places the first time XYZ_ARCHIVE_ROOT's contract changed.
  # `|| _run_log_base=""` is load-bearing: under `set -e` an assignment whose command substitution
  # exits non-zero terminates the script, so a fake/partial MARATHON_HOME turned "the resolver is
  # unavailable" into a bare exit 127 with no message — the shape of failure this whole issue is
  # about, reproduced by its own fix. Caught by test/marathon.sh's GH-212 harness-home-exempt case.
  _run_log_base="$(set +e; source "$MARATHON_HOME/relay-automation/relay-turn-lib.sh" >/dev/null 2>&1; rtl_transcript_root "$ROOT" 2>/dev/null)" || _run_log_base=""
  if [[ -z "$_run_log_base" ]]; then
    # The resolver was unavailable (partial install / fake home), NOT unresolvable. Those are
    # different failures and only the second deserves a hard stop: with XYZ_ARCHIVE_ROOT unset the
    # documented default is <root>/relay-system, and a run that can record itself there should.
    if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
      _run_log_base="$ROOT/relay-system"
    else
      die "XYZ_ARCHIVE_ROOT is set but no durable transcript root could be resolved from it — fix it, or unset it to use <root>/relay-system (GH-388). A marathon that cannot record itself must not start."
    fi
  fi

  # Scoped to RELOCATION, matching rtl_default_log: a run log inside the repo being driven shares
  # that repo's fate; one outside it, in storage a reboot erases, is the silent relocation this
  # issue is about. Without the scoping every fixture repo under $TMPDIR would refuse to run.
  _run_log_reason="$(xyz_non_durable_reason "$_run_log_base")"
  if [[ -n "$_run_log_reason" ]] && [[ "$(_xyz_realish_path "$_run_log_base")" != "$(_xyz_realish_path "$ROOT")"/* ]]; then
    die "the resolved run-log root $_run_log_base is under $_run_log_reason, which this harness records as non-durable storage ($(xyz_non_durable_conf)), and it is OUTSIDE the repo being driven ($ROOT). A marathon's own record must survive a reboot — that is the whole of GH-388. Point XYZ_ARCHIVE_ROOT at a committed archive, or unset it."
  fi

  _run_log_dir="$_run_log_base/run-logs/$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
  mkdir -p "$_run_log_dir" || die "could not create the run-log directory $_run_log_dir"
  _plan_slug="$(basename "${PLAN%.*}" | tr -c 'A-Za-z0-9._-' '_')"
  MARATHON_RUN_LOG="$_run_log_dir/marathon-${_plan_slug}-$(date +%H%M%S 2>/dev/null || echo unknown)-$$.log"
  export MARATHON_RUN_LOG

  # `tee -a` via process substitution, so output is captured AS IT IS PRODUCED rather than buffered
  # to the end — the whole point is that the record survives a run that never reaches its end.
  # stderr is folded in: an escalation reason arriving on stderr and a phase heading on stdout,
  # interleaved in one file, is the narrative an operator actually needs to read afterwards.
  # Opt-in cancellation must keep its run-log reader alive through a group INT/TERM; otherwise
  # the terminal write hits SIGPIPE and substitutes that status for the original interruption.
  exec > >(if ((PROGRESS_ENABLED)); then trap '' INT TERM; fi; tee -a "$MARATHON_RUN_LOG") 2>&1
  # Printed at chain start, per acceptance: an operator has to know where to look afterwards, and
  # afterwards is exactly when the terminal is gone.
  log "run log: $MARATHON_RUN_LOG"
fi

# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
PLAN_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PLAN" | head -n1 | sed 's/[[:space:]]*$//')"
phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
log "plan: $PLAN — $phase_count phase(s) in execution order"

# GH-1006: one finite reader, one launcher-written projection, no second executor.
PROGRESS_PID=""; PROGRESS_PHASE_PID=""; PROGRESS_CONTEXT=""
progress_exit() {
  local run_exit=$?
  trap - EXIT INT TERM
  # Context cancellation avoids signalling a cached PID after the finite observer has exited.
  if bash "$HERE/marathon.sh" --progress-observer terminal "$PROGRESS_CONTEXT" --exit-code "$run_exit"; then
    wait "$PROGRESS_PID" 2>/dev/null || true
  else
    log "terminal observation unavailable (run exit $run_exit); reader exits on owner loss"
  fi
  exit "$run_exit"
}
progress_signal() {
  local sig="$1" status="$2"
  trap '' INT TERM
  [[ -z "$PROGRESS_PHASE_PID" ]] || kill -s "$sig" "$PROGRESS_PHASE_PID" 2>/dev/null || true
  log "interrupted by $sig; direct phase signalled, descendant ownership unknown"
  exit "$status"
}
if ((PROGRESS_ENABLED)); then
  log "progress observation: interval=${PROGRESS_INTERVAL}s count=$PROGRESS_COUNT window=$((PROGRESS_INTERVAL * PROGRESS_COUNT))s; stdout/run-log only"
  if ((DRY_RUN == 0)); then
    PROGRESS_CONTEXT="${MARATHON_RUN_LOG}.progress.json"
    PROGRESS_RUN_ID="$(bash "$HERE/marathon.sh" --progress-observer init "$PROGRESS_CONTEXT" --owner "$$" \
      --root "$ROOT" --product-root "${TARGET_ROOT:-$ROOT}" --harness-root "$MARATHON_HOME" \
      --plan "$PLAN" --run-log "$MARATHON_RUN_LOG" --total "$phase_count" \
      --phases-dir "${PHASES_DIR:-$ROOT/marathon-system}" \
      --heartbeat-file "${RTL_DRIVER_HEARTBEAT_FILE:-$ROOT/.tick/driver-heartbeat.json}" \
      --interval "$PROGRESS_INTERVAL" --count "$PROGRESS_COUNT")" || die "could not initialize progress observation"
    bash "$HERE/marathon.sh" --progress-observer observe "$PROGRESS_CONTEXT" &
    PROGRESS_PID=$!
    trap progress_exit EXIT
    trap 'progress_signal INT 130' INT
    trap 'progress_signal TERM 143' TERM
  fi
fi

idx=0
# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
# tabs → \037 so empty fields (no rounds / no depends_on / no artifact / no turn_timeout_s) are
# preserved positionally.
while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact turn_timeout_s name; do
  [[ -n "$id" ]] || continue
  idx=$((idx + 1))
  rounds="${rounds:-2}"
  cap=$((2 * rounds + 1))
  lane_ns=""
  [[ -n "$PLAN_NAME" ]] && lane_ns="${PLAN_NAME}--${id}"
  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
  # Briefs live beside the plan, so they resolve against the repo the plan came from. On a
  # --target-root run that is the TARGET repo, not this harness — resolving against $ROOT would
  # look for the target's briefs inside the harness clone and die "brief file not found".
  brief_base="${TARGET_ROOT:-$ROOT}"
  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$brief_base/$brief" ;; esac
  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"

  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}${turn_timeout_s:+, turn-timeout=${turn_timeout_s}s}) ──"

  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
               --phase-brief "$brief_path" --round-cap "$cap" )
  [[ -n "$PHASES_DIR" ]] && drive_args+=( --phases-dir "$PHASES_DIR" )
  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
  # GH-116: only the phase named by --retry gets a task-name override — every other phase still lets
  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
  if [[ -n "$RETRY_PHASE" && "$id" == "$RETRY_PHASE" ]]; then
    id_upper="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
    retry_n=2
    # First unused suffix, not a hardcoded -2: keep bumping while that task name already exists
    # (tick info exits 0 once a task has any recorded state — spent or not, it's not reusable).
    while "$TICK_BIN" info "MARATHON-${id_upper}-TURN-${retry_n}" >/dev/null 2>&1; do
      retry_n=$((retry_n + 1))
    done
    retry_task="MARATHON-${id_upper}-TURN-${retry_n}"
    log "phase $id: --retry requested — overriding relay task to $retry_task (first unused suffix)"
    drive_args+=( --relay-task "$retry_task" )
  fi
  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi

  if ((PROGRESS_ENABLED && DRY_RUN == 0)); then
    progress_execution="${PROGRESS_RUN_ID}-${idx}"
    progress_result="${MARATHON_RUN_LOG}.phase-${idx}.result.json"
    progress_family="MARATHON-$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')-TURN"
    [[ -z "$RETRY_PHASE" || "$id" != "$RETRY_PHASE" ]] || progress_family="$retry_task"
    bash "$HERE/marathon.sh" --progress-observer phase "$PROGRESS_CONTEXT" --phase-id "$id" --index "$idx" \
      --lane "${lane_ns:-$id}" --token-family "$progress_family" \
      --execution-id "$progress_execution" --result-file "$progress_result" || log "phase observation unavailable: $id"
    drive_args+=( --execution-id "$progress_execution" --result-file "$progress_result" )
  fi

  phase_exit=0
  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
  # stays silent — this orchestrator emits a SINGLE harness:"marathon" whole-run record below, never
  # one per phase.
  if ((PROGRESS_ENABLED && DRY_RUN == 0)); then
    # Bash waits on a foreground command before handling trapped signals. Background + wait is
    # interruptible, yet still serial: no successor starts before this exact child returns.
    if [[ -n "$turn_timeout_s" ]]; then
      MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
        RELAY_TURN_TIMEOUT_S="$turn_timeout_s" bash "$DRIVE_BIN" "${drive_args[@]}" &
    else
      MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
        bash "$DRIVE_BIN" "${drive_args[@]}" &
    fi
    PROGRESS_PHASE_PID=$!
    bash "$HERE/marathon.sh" --progress-observer driver "$PROGRESS_CONTEXT" --driver-pid "$PROGRESS_PHASE_PID" || log "driver heartbeat attribution unavailable: $id"
    wait "$PROGRESS_PHASE_PID" || phase_exit=$?
    PROGRESS_PHASE_PID=""
    bash "$HERE/marathon.sh" --progress-observer finish "$PROGRESS_CONTEXT" --exit-code "$phase_exit" || log "phase result observation unavailable: $id"
  elif [[ -n "$turn_timeout_s" ]]; then
    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
      RELAY_TURN_TIMEOUT_S="$turn_timeout_s" \
      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
  else
    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
  fi
  if [[ "$phase_exit" -ne 0 ]]; then
    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
    case "$phase_exit" in
      3) _halt_reason="relay no-progress" ;;
      4) _halt_reason="relay cap/close-mismatch" ;;
      5) _halt_reason="pre-advance gate failed" ;;
      6) _halt_reason="containment violation" ;;
      7) _halt_reason="turn timeout / hang" ;;
      *) _halt_reason="marathon-drive exit $phase_exit" ;;
    esac
    xyz_marathon_run_emit red "halted at phase $idx of $phase_count ($id) — $_halt_reason"
    exit "$phase_exit"
  fi
done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')

if ((DRY_RUN)); then
  log "dry-run complete: $phase_count phase(s) would run in order"
  exit 0
fi

if ((CLOSEOUT_PR)); then
  closeout_plan="${PLAN_NAME:-$(basename "${PLAN%.*}")}"
  closeout_event_dir="$ROOT/.tick/events"
  closeout_event_count=0
  closeout_event_types=""
  if [[ -d "$closeout_event_dir" ]]; then
    closeout_event_count="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | wc -l | tr -d '[:space:]')"
    closeout_event_types="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | LC_ALL=C sort | while IFS= read -r event_file; do
      sed -n 's/.*"type":"\([^"]*\)".*/\1/p' "$event_file"
    done | LC_ALL=C sort -u | paste -sd, -)"
  fi
  closeout_notes="Marathon plan: $closeout_plan
Phases approved: $phase_count/$phase_count
Tick events: $closeout_event_count${closeout_event_types:+ ($closeout_event_types)}"
  if ! bash "$CLOSEOUT_BIN" --repo "$ROOT" --auto-pr --title "Marathon: $closeout_plan" --notes "$closeout_notes"; then
    log "closeout PR failed after successful marathon; leaving marathon successful"
  fi
fi
"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true

# GH-75: the whole-run success record (title/sessionId = plan name, "N of M phase(s) approved").
xyz_marathon_run_emit green "$phase_count of $phase_count phase(s) approved"

log "marathon complete — all $phase_count phase(s) approved"
exit 0
