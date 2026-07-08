#!/usr/bin/env bash
set -euo pipefail

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON:-0}" == "1" ]]; then
  _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export XYZ_ROOT="$_xyz_root"
  export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
  exec python3 "$_xyz_root/utils/py/consult.py" "$@"
fi
#
# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
#
# Fans out the SAME question to Codex and agy IN PARALLEL, advisory-only, captures each transcript,
# and leaves the synthesis to the caller (Claude). This is NOT a relay: a relay is an iterative 1:1
# Producer↔Reviewer loop; a consult is a parallel 1-shot 1:N "second opinion," reconciled once.
#
# PROVABLE no-mutation boundary (reworked after the dogfood found the old best-effort revert unsafe):
# advisors run with CWD set to a THROWAWAY git worktree checked out from the operator's CURRENT state
# (tracked WIP via `git stash create` + untracked-not-ignored files copied in). Any file an advisor
# writes lands in that disposable worktree and is destroyed with it — the operator's real working tree
# is NEVER the advisors' surface, so there is nothing to revert and ambient WIP can't be clobbered.
# (Codex stays `-s read-only` on top of that; agy's writes, if any, are contained by the worktree.)
#
# Usage:
#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,agy] [--label SLUG]
#   consult.sh --prompt "question" [--out DIR] [--models codex,agy] [--label SLUG]
#
# Options:
#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
#   --prompt TEXT     Inline question (mutually exclusive with --prompt-file).
#   --out DIR         Parent dir for the run (default: relay-system/<today>/). Each run gets its own
#                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
#   --models CSV      Which advisors to run (default: codex,agy). Also: `aider` (Aider↔OpenRouter,
#                     OpenAI-standard — needs OPENROUTER_API_KEY; or set AIDER_OPENAI_API_BASE for an
#                     OpenAI-compatible/LM Studio endpoint). Legacy `gemini` remains accepted as an
#                     explicit alias for older tests/callers.
#   --label SLUG      Run-subdir + transcript stem (default: consult).
#
# Env config:
#   CODEX_BIN / AGY_BIN        binaries (default: codex / agy); tests inject stubs
#   AIDER_BIN / AIDER_MODEL    Aider binary + model for `--models ...,aider`. Default model tracks the
#                              seam: openrouter/anthropic/claude-3.5-sonnet (OpenRouter) or openai/
#                              agents-a1 when AIDER_OPENAI_API_BASE is set. Reads OPENROUTER_API_KEY.
#   AIDER_OPENAI_API_BASE      OpenAI-compatible base URL (e.g. http://127.0.0.1:1234/v1 for LM Studio).
#   AIDER_OPENAI_API_KEY       client key for that base URL (default: dummy — local servers ignore it).
#   GEMINI_BIN                 legacy alias for AGY_BIN when `--models ...gemini` is used explicitly
#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
#   AGY_AUTH_TIMEOUT_S         short wall-clock cap for the agy auth probe (`agy whoami`); default 5.
#                              On failure/time-out consult skips the agy lane fast with an `agy login`
#                              remedy instead of waiting for the main CONSULT_TIMEOUT watchdog.
#   CONSULT_ROOT               git root to consult against (default: this repo)
#   CONSULT_TIMEOUT            per-advisor wall-clock cap in seconds (default: 300). A hung CLI is
#                              killed and reported as failed, so the other model still degrades gracefully.
#   TICK_BIN                   tick binary for cost capture (default: <root>/bin/tick)
#
# Boundary note: advisors run in a throwaway git worktree, so they cannot touch the operator's REPO.
# That is repo-isolation, NOT an OS sandbox — only Codex additionally gets `-s read-only`; a model
# could still read elsewhere on disk or reach the network. The skill docs say "repo-isolated", not
# "read-only", on purpose.
#
# Exit: 0 = at least one advisor answered · 5 = ALL advisors failed · 2 = usage · 3 = not a git repo.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
# GH-30 Phase 2: the single transcript-root resolver (rtl_transcript_root) — redirects relay-system/
# to $XYZ_ARCHIVE_ROOT when that is set, else byte-for-byte "$ROOT/relay-system". consult.sh lives
# beside relay-turn-lib.sh, so source it by the script's own dir (NOT $ROOT, which may be a foreign repo).
source "$HERE/relay-turn-lib.sh"
CODEX_BIN="${CODEX_BIN:-codex}"
AGY_BIN="${AGY_BIN:-${GEMINI_BIN:-agy}}"
GEMINI_BIN="${GEMINI_BIN:-$AGY_BIN}"
AIDER_BIN="${AIDER_BIN:-aider}"   # --models ...,aider → advisory via Aider↔OpenRouter (needs OPENROUTER_API_KEY)
die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
warn() { printf 'consult: %s\n' "$*" >&2; }

PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,agy"; LABEL="consult"
while (($# > 0)); do
  case "$1" in
    --prompt-file) PROMPT_FILE="${2:-}"; shift 2 ;;
    --prompt)      PROMPT_TEXT="${2:-}"; shift 2 ;;
    --out)         OUT="${2:-}"; shift 2 ;;
    --models)      MODELS="${2:-}"; shift 2 ;;
    --label)       LABEL="${2:-}"; shift 2 ;;
    --help) sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$PROMPT_FILE" || -n "$PROMPT_TEXT" ]] || die "one of --prompt-file or --prompt is required"
[[ -n "$PROMPT_FILE" && -n "$PROMPT_TEXT" ]] && die "--prompt-file and --prompt are mutually exclusive"
if [[ -n "$PROMPT_FILE" ]]; then
  [[ -f "$PROMPT_FILE" ]] || die "prompt file not found: $PROMPT_FILE"
  PROMPT_TEXT="$(cat "$PROMPT_FILE")"
fi

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { warn "consult requires a git repo (advisor isolation uses a throwaway worktree): $ROOT"; exit 3; }

# GH-30 Phase 2: default the run parent to the transcript-root resolver (honors XYZ_ARCHIVE_ROOT).
# An explicit --out (OUT already set) wins and skips the resolver entirely, so an invalid
# XYZ_ARCHIVE_ROOT can never override a caller who named their own --out. Resolver hard-errors loudly.
if [[ -z "$OUT" ]]; then
  _ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
  OUT="$_ts_base/$(date +%F)"
fi
RUN_DIR="$OUT/${LABEL}-$(date +%H%M%S)"
mkdir -p "$RUN_DIR"

# Advisor preamble: independent, advisory, structured, cite evidence. Each is told a peer answers the
# SAME question separately and a coordinator reconciles — so it gives its OWN read, not a guessed consensus.
PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
the SAME question separately and a coordinator will reconcile both answers, so give your own honest, \
specific read — do not hedge toward a consensus you cannot see. Read any repo files the question \
references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — \
[Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY \
ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
FULL_PROMPT="$PREAMBLE

=== CONSULT QUESTION ===
$PROMPT_TEXT"

# --- build the throwaway worktree = operator's CURRENT visible state, isolated --------------------
# tracked WIP (staged+unstaged) WITHOUT touching the real tree; falls back to HEAD when clean.
base="$(git -C "$ROOT" stash create 2>/dev/null || true)"; base="${base:-HEAD}"
WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
cleanup() {
  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT
git -C "$ROOT" worktree add --detach "$WT" "$base" >/dev/null 2>&1 \
  || die "could not create isolation worktree (base $base)"
# overlay untracked-not-ignored files so advisors see brand-new files (e.g. a skill being reviewed).
while IFS= read -r -d '' f; do
  mkdir -p "$WT/$(dirname "$f")"
  cp -p "$ROOT/$f" "$WT/$f" 2>/dev/null || true
done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)

# Run an advisor (CWD = throwaway worktree) under a wall-clock cap so a HUNG CLI degrades to a failure
# (collected as [FAIL]) rather than stalling the whole consult. No dependency on coreutils `timeout`
# (absent on stock macOS) — a sleep-then-kill watchdog. Output redirection handled here.
_guarded_with_timeout() {  # <out> <secs> <cmd...>
  local out="$1" secs="$2"; shift 2
  local apid kpid rc=0
  ( cd "$WT" && "$@" < /dev/null ) > "$out" 2>&1 &
  apid=$!
  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
  kpid=$!
  wait "$apid" || rc=$?
  # GH-109: kill the watchdog's `sleep` GRANDCHILD before the watchdog subshell itself. If we kill
  # $kpid first, its still-running `sleep "$secs"` is orphaned (reparented to PID 1) and keeps
  # sleeping to completion silently — harmless alone, but it accumulates on rapid/repeated consults.
  # `pkill -P "$kpid"` (direct children of the watchdog subshell, macOS/BSD-compatible) reaps it first.
  pkill -P "$kpid" 2>/dev/null || true
  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
  [[ "$rc" != 0 ]] && printf '\nconsult: advisor failed or exceeded the %ss cap\n' "$secs" >> "$out"
  return "$rc"
}
_guarded() {  # <out> <cmd...>
  local out="$1"; shift
  _guarded_with_timeout "$out" "${CONSULT_TIMEOUT:-300}" "$@"
}
agy_auth_preflight() {  # <out> — writes the failure reason into <out> on skip
  local out="$1" secs="${AGY_AUTH_TIMEOUT_S:-5}" tmp rc=0
  tmp="${out}.auth"
  _guarded_with_timeout "$tmp" "$secs" "$AGY_BIN" whoami || rc=$?
  [[ "$rc" -eq 0 ]] && { rm -f "$tmp"; return 0; }
  cat "$tmp" > "$out" 2>/dev/null || true
  if [[ "$rc" -eq 7 ]]; then
    printf '\nconsult: agy auth pre-flight timed out after %ss; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n' "$secs" >> "$out"
  else
    printf '\nconsult: agy auth pre-flight failed (exit %s). Run `agy login` in a normal terminal, then retry.\n' "$rc" >> "$out"
  fi
  rm -f "$tmp"
  return "$rc"
}

run_codex() {
  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
  # Billing guard: strip OPENAI_API_KEY so a consult ALWAYS bills the ChatGPT-subscription login,
  # never per-token API credits (CODEX_ALLOW_API_KEY=1 to opt back in). See codex-turn.sh.
  local cenv=(env); [[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || cenv+=(-u OPENAI_API_KEY)
  # ${_f[@]+...} guards an EMPTY flags array under `set -u` on bash 3.2 (macOS default).
  _guarded "$out" "${cenv[@]}" "$CODEX_BIN" exec ${_f[@]+"${_f[@]}"} "$FULL_PROMPT" || return $?

  local tmp="${out}.tmp"
  local model="unknown" provider="unknown" sandbox="unknown"
  if [[ -f "$out" ]]; then
    model="$(grep -m1 '^model:' "$out" | sed 's/^model:[[:space:]]*//' || true)"
    provider="$(grep -m1 '^provider:' "$out" | sed 's/^provider:[[:space:]]*//' || true)"
    sandbox="$(grep -m1 '^sandbox:' "$out" | sed 's/^sandbox:[[:space:]]*//' || true)"
    {
      printf '> **ATTESTATION**\n> Model: %s\n> Provider: %s\n> Sandbox: %s\n\n' "${model:-unknown}" "${provider:-unknown}" "${sandbox:-unknown}"
      cat "$out"
    } > "$tmp" && mv "$tmp" "$out"
  fi
}
run_agy() {
  local out="$1" secs="${CONSULT_TIMEOUT:-300}"
  agy_auth_preflight "$out" || return $?
  _guarded "$out" "$AGY_BIN" --dangerously-skip-permissions --print-timeout "${secs}s" -p "$FULL_PROMPT"
  local rc=$?
  if [[ "$rc" -eq 0 && -s "$out" ]]; then
    # GH-178 B1: Detect if agy escaped the isolation worktree ($WT) and read from the real repo root.
    if grep -qF "$ROOT" "$out" 2>/dev/null; then
      printf '\nconsult: [FAIL] agy transcript cited the real repo root (%s) instead of the isolation worktree. This is a known agy isolation breach (grounding escaped $WT). Failing the turn to prevent a silent breach.\n' "$ROOT" >> "$out"
      return 5
    fi
  fi
  return "$rc"
}
run_gemini() {
  local out="$1"
  export GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}"   # isolated: run_gemini is its own subshell
  if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
    _guarded "$out" "$GEMINI_BIN" --yolo --skip-trust -o json -p "$FULL_PROMPT"
  else
    _guarded "$out" "$GEMINI_BIN" --yolo --skip-trust -p "$FULL_PROMPT"
  fi
}
# Fail closed: Aider can exit 0 while printing an auth/config error transcript, or return only
# reasoning tokens with empty visible content (GH-147 spike 0.1/0.4). Either is a failed advisor, not
# a real answer — trusting the exit code alone false-greens the consult. Scoped to the aider lane.
_aider_answer_ok() {  # <out> — nonzero if the transcript shows failure or has no visible answer
  local out="$1"
  if [[ ! -s "$out" ]] || ! grep -qE '[^[:space:]]' "$out"; then
    printf '\nconsult: Aider returned no visible content (empty answer — likely reasoning-only or a silent failure).\n' >> "$out"
    return 5
  fi
  if grep -qiE 'litellm\.[A-Za-z]*Error|AuthenticationError|Incorrect API key|invalid_api_key|Unable to list models|No API key was provided|NotFoundError|Traceback \(most recent call last\)' "$out"; then
    printf '\nconsult: Aider transcript shows an auth/config failure — counted as FAILED (was exit 0).\n' >> "$out"
    return 5
  fi
  return 0
}
run_aider() {
  local out="$1" model
  local -a auth=()
  # Two seams share the Aider/OpenAI-compatible client (GH-147). If AIDER_OPENAI_API_BASE is set this
  # is the LM Studio / OpenAI-compatible path; otherwise it's the OpenRouter default (byte-identical).
  if [[ -n "${AIDER_OPENAI_API_BASE:-}" ]]; then
    # LM Studio etc.: the client still requires a non-empty key even when the local server ignores it,
    # so a dummy is fine for a keyless endpoint (spike 0.2). No OPENROUTER_API_KEY needed here.
    model="${AIDER_MODEL:-openai/agents-a1}"
    auth=(--openai-api-base "$AIDER_OPENAI_API_BASE" --openai-api-key "${AIDER_OPENAI_API_KEY:-dummy}")
  else
    # OpenRouter is pure API-key; a missing key would make Aider prompt interactively (deadlock under
    # the cap). Skip fast with the remedy — this advisor is counted [FAIL], the others still answer.
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      printf 'consult: OPENROUTER_API_KEY not set — Aider cannot reach OpenRouter (or set AIDER_OPENAI_API_BASE for an OpenAI-compatible/LM Studio endpoint). Export it, then retry.\n' > "$out"
      return 5
    fi
    model="${AIDER_MODEL:-openrouter/anthropic/claude-3.5-sonnet}"
  fi
  # ADVISORY only: pass NO --file (Aider edits nothing) + --no-auto-commits; it answers to stdout, which
  # is exactly what a consult captures.
  _guarded "$out" "$AIDER_BIN" --model "$model" ${auth[@]+"${auth[@]}"} --message "$FULL_PROMPT" \
    --yes-always --no-auto-commits --no-gitignore --no-check-update --no-analytics \
    --no-show-model-warnings --no-stream --map-tokens 0 || return 5
  _aider_answer_ok "$out"
}

# --- advisor registry (GH-178 A1) ------------------------------------------------------------------
# name -> run-function, as parallel arrays (bash 3.2 / macOS has no `declare -A`; see
# resolve-model-alias.sh for the same convention). Adding a 5th advisor is a DATA addition here — one
# entry in each array plus its own run_<vendor>() — not a new case arm in the fan-out loop below. See
# "Adding a new consult advisor" in relay-automation/README.md for the full recipe.
ADV_NAMES=(codex agy gemini aider)
ADV_RUNFNS=(run_codex run_agy run_gemini run_aider)

# --- fan out in parallel (indexed arrays — macOS bash 3.2 has no `declare -A`) --------------------
PIDS=(); PMODELS=(); POUTS=()
IFS=',' read -ra _models <<<"$MODELS"
for m in "${_models[@]}"; do
  m="${m// /}"; [[ -n "$m" ]] || continue
  fn=""; i=0
  while ((i < ${#ADV_NAMES[@]})); do
    [[ "${ADV_NAMES[$i]}" == "$m" ]] && { fn="${ADV_RUNFNS[$i]}"; break; }
    i=$((i + 1))
  done
  if [[ -z "$fn" ]]; then warn "unknown model '$m' — skipping"; continue; fi
  ext="md"; [[ "$m" == "gemini" && "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
  f="$RUN_DIR/${LABEL}.${m}.${ext}"
  "$fn" "$f" & PIDS+=("$!"); PMODELS+=("$m"); POUTS+=("$f")
done
((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"

# --- collect results -----------------------------------------------------------------------------
answered=0; failed=0; summary=""; i=0
survivor_model=""; survivor_out=""; POK=()
while ((i < ${#PIDS[@]})); do
  pid="${PIDS[$i]}"; model="${PMODELS[$i]}"; out="${POUTS[$i]}"
  if wait "$pid"; then
    answered=$((answered + 1)); summary+=$'\n'"  [ok]   $model -> $out"
    survivor_model="$model"; survivor_out="$out"; POK+=(1)
  else
    failed=$((failed + 1));   summary+=$'\n'"  [FAIL] $model -> $out (see transcript for error)"; POK+=(0)
  fi
  i=$((i + 1))
done

# GH-178 A4 (deliberately narrow slice — NOT the full firsthand-vs-asserted provenance taxonomy; see
# PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md for what's future-scoped). Mechanically
# stamp any ANSWERED advisor whose own transcript carries ZERO explicit file:line or quoted-content
# citations anywhere — same stdout+prepended-transcript+sidecar mechanism as A2's SINGLE-MODEL stamp.
# Does NOT check whether a present citation is ACCURATE (no citation-verification engine); it only
# catches an answer with no citation attempt at all. Scoped to not fire when the advisor DID cite
# something anywhere in its answer.
CITELESS_MODELS=(); i=0
while ((i < ${#PIDS[@]})); do
  if [[ "${POK[$i]}" == "1" ]]; then
    model="${PMODELS[$i]}"; out="${POUTS[$i]}"
    if ! grep -qE '"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+' "$out" 2>/dev/null; then
      CITELESS_MODELS+=("$model")
      nocite="**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional ($model's answer carries no quoted span or file:line citation anywhere, despite the consult PREAMBLE asking advisors to cite evidence.)"
      case "$out" in
        *.json) : ;;  # don't corrupt structured output — the sidecar marker below still covers it
        *) { printf '%s\n\n' "$nocite"; cat "$out"; } > "$out.stamped" && mv "$out.stamped" "$out" ;;
      esac
      printf '%s\n' "$nocite" > "$RUN_DIR/${LABEL}.${model}.NO-CITATION.txt"
    fi
  fi
  i=$((i + 1))
done

# GH-178 A2: a panel that started with MORE THAN ONE requested advisor but ended with exactly one
# survivor is not a reconciled cross-model result — no second read happened, so treating its verdict
# as reconciled is exactly the failure mode this consult exists to avoid. Stamp it MECHANICALLY —
# into the surviving transcript itself, plus a format-agnostic sidecar marker — so the caveat travels
# with the data (a future read of relay-system/<date>/... days later still sees it) instead of living
# only in this run's stdout, which an operator can simply not have watched. Deliberately does NOT
# fire when only one model was ever requested (--models codex alone): that is an intentional
# single-model query, not a degrade, and existing single-model callers must stay unstamped.
DEGRADED=0
if ((${#PIDS[@]} > 1 && answered == 1)); then
  DEGRADED=1
  stamp="**SINGLE-MODEL — NOT RECONCILED** (only $survivor_model answered; $failed of ${#PIDS[@]} requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)"
  case "$survivor_out" in
    *.json) : ;;  # don't corrupt structured output — the sidecar marker below still covers it
    *) { printf '%s\n\n' "$stamp"; cat "$survivor_out"; } > "$survivor_out.stamped" \
         && mv "$survivor_out.stamped" "$survivor_out" ;;
  esac
  printf '%s\n' "$stamp" > "$RUN_DIR/DEGRADED-SINGLE-MODEL.txt"
fi

# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
  gj="$RUN_DIR/${LABEL}.gemini.json"
  if [[ -s "$gj" ]]; then
    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
      2>/dev/null || warn "gemini tokens not captured (no parseable stats)"
  fi
fi

printf 'consult: %d answered, %d failed -> %s%s\n' "$answered" "$failed" "$RUN_DIR" "$summary"
((DEGRADED)) && warn "SINGLE-MODEL — NOT RECONCILED (stamped into $survivor_out and $RUN_DIR/DEGRADED-SINGLE-MODEL.txt)"
((${#CITELESS_MODELS[@]} > 0)) && warn "NO FIRSTHAND VERIFICATION CITED for: ${CITELESS_MODELS[*]} (stamped into transcript(s) + sidecar(s) in $RUN_DIR)"
((answered > 0)) || { warn "all advisors failed"; exit 5; }
exit 0
