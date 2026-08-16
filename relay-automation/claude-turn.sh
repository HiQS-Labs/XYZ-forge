#!/usr/bin/env bash
# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
# Historical Bash fallback only; update utils/py/claude-turn.py instead. See issue #308.
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
    exec python3 "$_xyz_root/utils/py/claude-turn.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
#
# claude-turn.sh — headless turn-taker for the CLAUDE builder agent. Thin dispatch wrapper over the
# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh and
# gemini-turn.sh (decisions/2026-06-15-unattended-agent-containment.md).
#
# Builder role: Claude is the PRODUCER (write/revise the artifact). Reviewers (Codex, Gemini) use
# the tighter "Bash,Read" allowlist — no Write surface; rtl_enforce is the real guard regardless.
#
# Invoked by relay-drive.sh as --agent-cmd (typically via marathon-agent.sh), with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   CLAUDE_AGENT      — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CLAUDE_AGENT
#   ALLOW_PATHS       — comma-separated extra git paths the turn may change (the artifact being built)
#   RELAY_PEER        — optional: the other agent's id, for explicit --to <peer> handoff
#   CLAUDE_BIN        — claude CLI binary or wrapper (default: claude); tests inject a stub.
#   CLAUDE_MODEL      — model to PIN via --model (default: claude-sonnet-4-6). Without this the
#                       headless turn inherits the operator's ambient model — an Opus session blew
#                       the budget cap mid-build on 2026-06-18. Pin it so cost is deterministic.
#   CLAUDE_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture
#   CLAUDE_LOG        — where to write the claude transcript JSON (default: $TMPDIR/claude-turn-$$.json)
#   CLAUDE_MAX_TURNS  — max turns passed to --max-turns (default: 12)
#   CLAUDE_MAX_BUDGET — max cost passed to --max-budget-usd (default: 0.50)
#   CLAUDE_BLOCK_CMDS — space-separated commands PATH-shadowed (blocked) for the builder's claude -p
#                       subprocess only (default: codex gemini consult consult.sh marathon-drive.sh
#                       relay-drive.sh). Stops an off-task builder from spawning external models /
#                       recursive marathons. Set empty to disable. (Phase 3.6; not airtight — an
#                       absolute-path call bypasses it; worktree isolation below is the airtight close.)
#   RELAY_WORKTREE_ISOLATION — 1 = run the builder turn in a THROWAWAY git worktree (ROADMAP 3.6 close):
#                       async/background writes land in a tree we delete, never ROOT; `.tick` stays
#                       shared via TICK_REPO_ROOT=ROOT; only the allowlist is copied back. An off-lane
#                       change detected in the worktree → exit 6 (contained AND escalated). Default OFF
#                       (unset) → the prior in-ROOT behaviour, byte-for-byte. Opt-in for unattended/
#                       real-repo runs (the Phase 6 WPCC dogfood gate).
#
# Auth: `claude -p` inherits the credentials stored by `claude login` (~/.claude/). A subscription
# login is sufficient — no API key needed. The binary must be installed and authenticated before
# running headless turns. JSON output schema (--output-format json): usage.{input_tokens,
# cache_read_input_tokens,output_tokens}, total_cost_usd, duration_ms, num_turns.
#
# Tool allowlist split:
#   builder (this shim)                   → "Bash,Read,Edit,Write"  (needs to mutate the artifact)
#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
# rtl_enforce is the real guard either way; the allowlist is a second, tighter layer.
#
#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900, raised from 600 by
#                          GH-386 so every builder shares one cap; see the Python twin for why the
#                          old value was not a cost control). A hung or
#                          runaway claude CLI is killed after this many seconds; the turn exits 7.
#                          The existing --max-budget-usd / --max-turns API-spend ceilings are
#                          complementary and remain unchanged — wall-clock is the NEW dimension.
#
# Exit: 0 acted/deferred · 3 claude not found · 5 claude failed · 6 off-allowlist edit (reverted) · 7 timeout-killed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
# ($HERE/..). Explicit CLAUDE_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
ROOT="${CLAUDE_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
CLAUDE_BIN="${CLAUDE_BIN:-}"
die() { printf 'claude-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
claude_agent="${CLAUDE_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$claude_agent" ]] || die "CLAUDE_AGENT required"

# Dispatch only for the Claude agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$claude_agent" ]]; then
  printf 'claude-turn: actor %s is not the Claude agent (%s) — deferring (window-driven)\n' "$me" "$claude_agent" >&2
  exit 0
fi

# Preserve an inherited harness tick root from the orchestrator (e.g. vendored .xyz marathon runs);
# default to this shim's ROOT only when the caller did not already pin TICK_REPO_ROOT. (GH-171)
: "${TICK_REPO_ROOT:=$ROOT}"
export TICK_REPO_ROOT

# GH-58: Discovery of claude binary + fail-fast
resolved_claude=""
if [[ -n "${CLAUDE_BIN:-}" ]]; then
  if command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
    resolved_claude="$CLAUDE_BIN"
  fi
else
  if command -v claude >/dev/null 2>&1; then
    resolved_claude="claude"
  elif [[ -x "$HOME/.claude/local/claude" ]]; then
    resolved_claude="$HOME/.claude/local/claude"
  fi
fi

if [[ -z "$resolved_claude" ]]; then
  printf 'claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder\n' >&2
  exit 3
fi
CLAUDE_BIN="$resolved_claude"

rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"

# GH-172: Claude is a driven builder shim too, so it needs the same pre-launch ownership proof as the
# Codex/Aider/agy shims. Otherwise a "successful" builder edit can still commit while the handed-off
# token remains open under the old owner, and rtl_enforce has no authority to release/done it.
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
    printf 'claude-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
    exit 5
  fi
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
fi

# Transcript: $TMPDIR file, NOT the repo tree (the in-tree log guard deletes it).
# JSON format required: the cost block (usage.input_tokens / total_cost_usd / duration_ms)
# is only emitted with --output-format json.
CLAUDE_LOG="${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}"

# Model pin: `claude -p` otherwise inherits the operator's AMBIENT model (whatever the interactive
# session / global config selects). A headless builder must pin its own model, or its cost is
# hostage to that ambient choice — a real smoke run on 2026-06-18 inherited `claude-opus-4-8[1m]`
# and blew the $0.50 cap in 4 turns ($0.53) because the ceiling below was sized for Sonnet.
# Default to the spike's model; override with CLAUDE_MODEL for an intentionally heavier builder.
model="${CLAUDE_MODEL:-claude-sonnet-4-6}"

# Cost ceilings: sized from the M2 authenticated spike (2026-06-17, Sonnet 4.6).
# Real relay turn (minimal fixture): 7 turns, $0.172, 26s wall-clock, 207k cache-read + 1.4k output.
# --max-turns 12: observed 7; headroom for complex builder turns (multi-file edits, retries).
# --max-budget-usd 0.50: observed $0.17; ~3× margin for heavier content. The cache-read bulk
#   (~207k tokens) is cheap; output tokens ($15/M) dominate on complex turns.
# NOTE: these ceilings are valid only for the pinned model — raise --max-budget-usd if CLAUDE_MODEL
# points at a costlier model (e.g. Opus), or the turn will hard-stop mid-build like the 06-18 run.
max_turns="${CLAUDE_MAX_TURNS:-12}"
max_budget="${CLAUDE_MAX_BUDGET:-0.50}"

# Phase 3.6 — bound the builder's side-effect surface. `--allowedTools Bash` lets the headless
# builder run ANYTHING; a 2026-06-17 dogfood builder ran `consult` (real Codex+Gemini API calls) as
# an off-task side-quest. Shadow the external-model / recursive-spawn commands on PATH for the
# `claude -p` subprocess ONLY — the reviewer turn (codex-turn/gemini-turn) is a SEPARATE process with
# a normal PATH, so codex/gemini review is unaffected. Even if the builder runs `consult.sh` by path,
# its internal bare `codex`/`gemini` calls hit these stubs. NOT airtight (an absolute-path call to the
# real binary bypasses it) — worktree isolation is the airtight follow-up (ROADMAP 3.6). Override the
# set with CLAUDE_BLOCK_CMDS; set it empty to disable.
block_cmds="${CLAUDE_BLOCK_CMDS-codex gemini consult consult.sh marathon-drive.sh relay-drive.sh}"
shadow_dir=""
if [[ -n "$block_cmds" ]]; then
  shadow_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-turn-shadow.XXXXXX")"
  for c in $block_cmds; do
    { printf '#!/usr/bin/env bash\n'
      printf 'printf "blocked: %%s is off-limits to a headless builder turn (CLAUDE_BLOCK_CMDS)\\n" %q >&2\n' "$c"
      printf 'exit 127\n'
    } > "$shadow_dir/$c"
    chmod +x "$shadow_dir/$c"
  done
fi

rtl_before
# GH-386: 600 -> 900. MUST stay equal to the Python twin's default (GH-320's invariant, pinned by
# test/gh320-twin-timeout-parity.sh); the rationale for the value lives in utils/py/claude-turn.py.
turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
bounded_rc=0

# Worktree isolation (opt-in; ROADMAP Part A Phase 3.6 — the airtight async/side-effect close).
# When RELAY_WORKTREE_ISOLATION=1, run the builder in a throwaway git worktree so any async/background
# write lands in a tree we delete, never ROOT. `.tick` coordination state stays SHARED via
# TICK_REPO_ROOT=ROOT. Default OFF → the in-ROOT path below is byte-for-byte the prior behaviour.
wt=""; cwd_wrap=()
if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
  if wt="$(rtl_worktree_begin)"; then
    # Run claude with CWD = the worktree; keep tick pointed at the real repo's shared state.
    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    printf 'claude-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'claude-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    [[ -n "$shadow_dir" ]] && rm -rf "$shadow_dir"; exit 5
  fi
fi

# PATH prefix on a shell function call works in bash: bash sets the var in the current scope for
# the duration of the call, so rtl_run_bounded's backgrounded `$CLAUDE_BIN ...` inherits it.
PATH="${shadow_dir:+$shadow_dir:}$PATH" \
  rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} "$CLAUDE_BIN" -p "$prompt" \
    --model "$model" \
    --allowedTools "Bash,Read,Edit,Write" \
    --permission-mode acceptEdits \
    --output-format json \
    --max-turns "$max_turns" \
    --max-budget-usd "$max_budget" \
    < /dev/null > "$CLAUDE_LOG" 2>&1 || bounded_rc=$?
[[ -n "$shadow_dir" ]] && rm -rf "$shadow_dir"

# Worktree teardown FIRST (regardless of rc — a killed/crashed builder may have left work or off-lane
# edits in the worktree). Copies the allowlist back to ROOT unless an off-lane change was detected.
wt_offlane=0
if [[ -n "$wt" ]]; then
  rtl_worktree_end "$wt"
  wt_offlane="${RTL_WT_OFFLANE:-0}"
fi
# Containment (off-lane → 6) takes precedence over timeout (7) and failure (5), per the exit contract.
if [[ "$wt_offlane" == "1" ]]; then
  printf 'claude-turn: builder made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
  exit 6
fi
if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'claude-turn: claude -p exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'claude-turn: claude -p failed (exit %s)\n' "$bounded_rc" >&2; exit 5
fi
# Always enforce containment even after a timeout-kill: a killed-mid-edit agent may have left
# off-lane changes. rtl_enforce may exit 6 (containment violation takes precedence over timeout 7).
rtl_enforce "$t" "$me" "$CLAUDE_LOG" "claude"
if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi

# Best-effort cost capture: parse the claude CLI's JSON token stats and emit a cost.tokens event.
# NEVER fails the turn — the turn already committed; missing/unparseable stats → loud-partial signal.
# JSON path: .usage.input_tokens, .usage.output_tokens, .total_cost_usd (claude --output-format json)
if [[ -s "$CLAUDE_LOG" ]]; then
  tokens_in="$(python3 -c "import json,sys; d=json.load(open('$CLAUDE_LOG')); print(d.get('usage',{}).get('input_tokens',0)+d.get('usage',{}).get('cache_read_input_tokens',0))" 2>/dev/null || echo 0)"
  tokens_out="$(python3 -c "import json,sys; d=json.load(open('$CLAUDE_LOG')); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)"
  if [[ "$tokens_in" -gt 0 || "$tokens_out" -gt 0 ]]; then
    _cost_tickroot="${TICK_REPO_ROOT:-$ROOT}"
    _cost_tickbin="$(rtl_tick_bin "$_cost_tickroot")"
    if [[ -x "$_cost_tickbin" ]]; then
      TICK_REPO_ROOT="$_cost_tickroot" "$_cost_tickbin" cost "$t" --agent "$me" \
        --tokens-in "$tokens_in" --tokens-out "$tokens_out" --tool claude \
        || printf 'claude-turn: tokens not captured for %s\n' "$t" >&2
    fi
  else
    printf 'claude-turn: tokens not captured for %s (zero or no stats in transcript)\n' "$t" >&2
  fi
fi
