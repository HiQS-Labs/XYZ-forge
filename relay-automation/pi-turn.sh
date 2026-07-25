#!/usr/bin/env bash
set -euo pipefail

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
  if command -v python3 >/dev/null 2>&1 \
     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export XYZ_ROOT="$_xyz_root"
    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    exec python3 "$_xyz_root/utils/py/pi-turn.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
#
# pi-turn.sh — headless turn-taker for PI (https://pi.dev, package @earendil-works/pi-coding-agent).
# Thin dispatch wrapper over the shared safety core (relay-turn-lib.sh) — the SAME containment
# contract as codex-turn.sh / agy-turn.sh / aider-turn.sh, proving the boundary is model-agnostic
# (decisions/2026-06-15-unattended-agent-containment.md). GH-295.
#
# WHY A SEPARATE SHIM (not just another agy-style lane): Pi has no built-in sandbox of its own — same
# posture as agy — so containment here relies ENTIRELY on relay-turn-lib.sh's worktree isolation
# (RELAY_WORKTREE_ISOLATION=1) + rtl_enforce, not a Pi-native sandbox flag (there isn't one). Unlike
# agy, Pi's `--mode json` streams per-call usage/cost fields inline, so this shim adds a real
# cost.tokens capture (agy is fully cost-blind; Pi is not) — see the capture block at the bottom.
#
# Invoked by relay-drive.sh / marathon-agent.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   PI_AGENT       — the agent id this shim drives; NO-OPS unless RELAY_AGENT==PI_AGENT
#   ALLOW_PATHS    — comma-separated extra git paths the turn may change (e.g. the artifact)
#   RELAY_PEER     — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
#                    prompt says "the other agent", which a live model may resolve to a role name)
#   PI_BIN         — pi binary (default: pi); tests inject a stub
#   PI_PROVIDER    — model provider passed as `pi --provider <name>` (default: openrouter — reuses
#                    this harness's existing OPENROUTER_API_KEY seam, verified working in the Phase 0
#                    smoke test). Any other provider Pi supports may be set; this shim then skips the
#                    OPENROUTER_API_KEY pre-flight (Pi's own env-var auto-detection for that provider
#                    is trusted instead — same posture aider-turn.sh takes for its LM_STUDIO seam).
#   PI_MODEL       — model id passed as `pi --model <id>`. REQUIRED, NO DEFAULT. GH-280/aider#5486
#                    documented the exact class of bug a silent/unlisted default model id causes
#                    (billed against an unintended model); this shim refuses to guess and fails loud
#                    (exit 5) if PI_MODEL is unset. Operator must set it explicitly, e.g.
#                    PI_MODEL=openai/gpt-mini-latest.
#   PI_FLAGS       — optional extra flags appended to the pi invocation (advanced/override)
#   PI_TURN_ROOT   — git root to guard (default: this repo); tests point at a fixture
#   PI_LOG         — where to write the pi transcript (default: GH-161 persistent path under
#                    rtl_transcript_root(ROOT)/logs/, gitignored; falls back to a $TMPDIR file on any
#                    resolver failure). Also exported as RTL_LOG so relay-turn-lib.sh's rtl_trace/
#                    rtl_log_always decision-point instrumentation lands in this same transcript.
#   RTL_TRACE      — 1 = also emit fine-grained decision-point trace lines (root resolution, allowlist
#                    match, worktree seed/copy-back, containment verdict) into PI_LOG. Default off.
#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
#                     async/side-effect containment; off-lane in the worktree → exit 6). Default OFF.
#
#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
#                          runaway pi CLI is killed after this many seconds; the turn exits 7.
#
# Headless contract (validated Phase 0, 2026-07-23):
#   --provider <name> --model <id> --no-session --mode json -p "<prompt>"
#   `--api-key` is intentionally OMITTED: Pi auto-detects OPENROUTER_API_KEY (and other providers'
#   native env vars) from the environment with zero extra config (Phase 0 confirmed this).
#   `--mode json` streams a sequence of NEWLINE-DELIMITED JSON objects (JSONL), NOT one JSON blob and
#   NOT a JSON array — each line is independently parseable. The final `turn_end`/`agent_end` event
#   carries a `message.usage` block with `input`/`output`/`cost.total` fields; the cost-capture block
#   below scans every line and keeps the LAST usage seen (best-effort, never fails the turn).
#   Pi's built-in tools (read/bash/edit/write) are enabled by default with no separate
#   auto-approve/`--yes`-style flag needed in `-p` (print/headless) mode — Phase 0's real file-edit
#   task confirmed this; there is no interactive approval gate to disable, unlike Codex.
#
# Exit: 0 acted/deferred · 5 pi failed / produced empty output / PI_MODEL unset / auth pre-flight
#       failed · 6 off-allowlist edit (reverted) · 7 timeout-killed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
# ($HERE/..). Explicit PI_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
ROOT="${PI_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
PI_BIN="${PI_BIN:-pi}"
PI_PROVIDER="${PI_PROVIDER:-openrouter}"
die() { printf 'pi-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
pi_agent="${PI_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$pi_agent" ]] || die "PI_AGENT required"

# Dispatch only for the Pi agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$pi_agent" ]]; then
  printf 'pi-turn: actor %s is not the Pi agent (%s) — deferring (window-driven)\n' "$me" "$pi_agent" >&2
  exit 0
fi

# GH-295: PI_MODEL has NO default — an unset/guessed model id is exactly the footgun GH-280 documented
# for Aider (silently billing an unintended model). Fail loud before any mutation.
if [[ -z "${PI_MODEL:-}" ]]; then
  printf 'pi-turn: PI_MODEL is not set — refusing to guess a model id (GH-280 class of bug). Set PI_MODEL explicitly, e.g. PI_MODEL=openai/gpt-mini-latest. Run `pi --list-models` to see what your provider/account exposes.\n' >&2
  exit 5
fi

# Auth pre-flight: the default provider (openrouter) reuses this harness's existing OPENROUTER_API_KEY
# seam; a missing key would make Pi either fail cryptically or (worse) hang on an interactive prompt.
# A non-default PI_PROVIDER is trusted to have its own env-var auto-detection (mirrors aider-turn.sh's
# AIDER_OPENAI_API_BASE seam skipping the same check) — Pi supports many provider env vars (`pi --help`
# lists them) and this shim does not attempt to enumerate/validate all of them.
if [[ "$PI_PROVIDER" == "openrouter" && -z "${OPENROUTER_API_KEY:-}" ]]; then
  printf 'pi-turn: OPENROUTER_API_KEY is not set — Pi cannot reach OpenRouter (or set PI_PROVIDER to a different provider with its own credential env var). Export it, then retry.\n' >&2
  exit 5
fi

# Anchor tick coordination to the harness root (not just under worktree isolation) — mirrors
# codex-turn.sh/agy-turn.sh. Preserve an inherited TICK_REPO_ROOT (vendored .xyz / marathon runs).
: "${TICK_REPO_ROOT:=$ROOT}"
export TICK_REPO_ROOT
# GH-161: resolve the transcript path and export RTL_LOG BEFORE rtl_init, so its own decision-trace
# line (and every later rtl_trace/rtl_log_always call) lands in this turn's transcript.
PI_LOG="${PI_LOG:-$(rtl_default_log "$ROOT" pi-turn "$t")}"
export RTL_LOG="$PI_LOG"
rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief.
drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"

# Claim the specific handed-off task in the shim and prove ownership BEFORE launching Pi (mirrors
# codex-turn.sh/agy-turn.sh GH-165: rtl_enforce's post-commit release/done is ownership-guarded).
claim_paths="${f#"$ROOT"/}"
if [[ -n "${ALLOW_PATHS:-}" ]]; then
  IFS=',' read -ra _claim_allow <<<"${ALLOW_PATHS}"
  for _ap in "${_claim_allow[@]}"; do
    _ap="${_ap#"${_ap%%[![:space:]]*}"}"
    _ap="${_ap%"${_ap##*[![:space:]]}"}"
    [[ -n "$_ap" ]] && claim_paths="$claim_paths,$_ap"
  done
fi
_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$(rtl_tick_bin "$_tickroot")"
if [[ -x "$_tickbin" ]]; then
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
  _claimer="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$t" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
  if [[ "$_claimer" != "$me" ]]; then
    printf 'pi-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
    exit 5
  fi
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
fi

# Build the pi invocation. --no-session keeps each turn ephemeral (no session file left behind);
# --mode json is what carries the per-call usage/cost fields the capture block below parses.
turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
pi_args=(--provider "$PI_PROVIDER" --model "$PI_MODEL" --no-session --mode json)
read -ra _piflags <<<"${PI_FLAGS:-}"
[[ "${#_piflags[@]}" -gt 0 ]] && pi_args+=("${_piflags[@]}")

rtl_before
bounded_rc=0

# Worktree isolation (opt-in; same wiring as agy-turn.sh). Pi has no sandbox of its own to grant an
# extra --add-dir style allowance to (unlike codex) — containment is entirely the worktree + rtl_enforce.
wt=""; cwd_wrap=()
if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
  if wt="$(rtl_worktree_begin)"; then
    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    printf 'pi-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'pi-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    exit 5
  fi
fi

# GH-161: >> (append), not > (truncate) — rtl_init already wrote its trace line into PI_LOG above
# (RTL_LOG was exported before rtl_init ran); a truncating redirect here would silently wipe it.
rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} "$PI_BIN" "${pi_args[@]}" -p "$prompt" < /dev/null >> "$PI_LOG" 2>&1 \
  || bounded_rc=$?

# Worktree teardown FIRST (regardless of rc). Copies the allowlist back to ROOT unless an off-lane
# change was detected → exit 6 (containment takes precedence over timeout 7 / failure 5).
if [[ -n "$wt" ]]; then
  rtl_worktree_end "$wt"
  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
    printf 'pi-turn: pi made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
    exit 6
  fi
fi

if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'pi-turn: pi exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'pi-turn: pi failed (exit %s)\n' "$bounded_rc" >&2; exit 5
fi
# Empty-output guard (mirrors agy-turn.sh): a clean exit with NO transcript is a phantom turn — treat
# it as a failure, not a silent no-op that would advance the relay on false success.
if [[ "$bounded_rc" -eq 0 && ! -s "$PI_LOG" ]]; then
  printf 'pi-turn: pi exited 0 but produced NO output — likely a blocked/misconfigured backend. Failing the turn.\n' >&2
  exit 5
fi
# Always enforce containment even after a timeout-kill: a killed-mid-edit agent may have left
# off-lane changes. rtl_enforce may exit 6 (containment violation takes precedence over timeout 7).
rtl_enforce "$t" "$me" "$PI_LOG" "pi"
enforce_rc=$?

# Best-effort cost capture: Pi's --mode json stream is JSONL (one JSON object per line), not a single
# blob — scan every line and keep the LAST usage block seen (the turn_end/agent_end event carries the
# cumulative usage for the whole turn). NEVER fails the turn — the turn already committed above;
# missing/unparseable stats just skip the tick cost event, same "loud-partial, not fatal" posture
# claude-turn.sh's equivalent capture takes. This is a genuine improvement over agy's fully cost-blind
# lane (GH-295 Phase 0 finding): Pi is the first non-Claude lane with real per-turn token visibility.
if [[ -s "$PI_LOG" ]] && command -v python3 >/dev/null 2>&1; then
  _pi_usage="$(python3 - "$PI_LOG" <<'PYEOF' 2>/dev/null
import json, sys
path = sys.argv[1]
tin = tout = 0
try:
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line or not line.startswith("{"):
                continue
            try:
                d = json.loads(line)
            except Exception:
                continue
            msg = d.get("message")
            if not isinstance(msg, dict):
                continue
            usage = msg.get("usage")
            if not isinstance(usage, dict):
                continue
            tin = usage.get("input", tin) or tin
            tout = usage.get("output", tout) or tout
except Exception:
    pass
print(f"{tin} {tout}")
PYEOF
)"
  read -r _pi_tokens_in _pi_tokens_out <<<"${_pi_usage:-0 0}"
  if [[ "${_pi_tokens_in:-0}" -gt 0 || "${_pi_tokens_out:-0}" -gt 0 ]]; then
    _cost_tickroot="${TICK_REPO_ROOT:-$ROOT}"
    _cost_tickbin="$(rtl_tick_bin "$_cost_tickroot")"
    if [[ -x "$_cost_tickbin" ]]; then
      TICK_REPO_ROOT="$_cost_tickroot" "$_cost_tickbin" cost "$t" --agent "$me" \
        --tokens-in "$_pi_tokens_in" --tokens-out "$_pi_tokens_out" --tool pi \
        || printf 'pi-turn: tokens not captured for %s\n' "$t" >&2
    fi
  else
    printf 'pi-turn: tokens not captured for %s (zero or no usage in transcript)\n' "$t" >&2
  fi
fi

if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi
exit "$enforce_rc"
