#!/usr/bin/env bash
set -euo pipefail
#
# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
#
# Fans out the SAME question to Codex and Gemini IN PARALLEL, advisory-only, captures each transcript,
# and leaves the synthesis to the caller (Claude). This is NOT a relay: a relay is an iterative 1:1
# Producer↔Reviewer loop; a consult is a parallel 1-shot 1:N "second opinion," reconciled once.
#
# PROVABLE no-mutation boundary (reworked after the dogfood found the old best-effort revert unsafe):
# advisors run with CWD set to a THROWAWAY git worktree checked out from the operator's CURRENT state
# (tracked WIP via `git stash create` + untracked-not-ignored files copied in). Any file an advisor
# writes lands in that disposable worktree and is destroyed with it — the operator's real working tree
# is NEVER the advisors' surface, so there is nothing to revert and ambient WIP can't be clobbered.
# (Codex stays `-s read-only` on top of that; Gemini's writes, if any, are contained by the worktree.)
#
# Usage:
#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,gemini] [--label SLUG]
#   consult.sh --prompt "question" [--out DIR] [--models codex,gemini] [--label SLUG]
#
# Options:
#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
#   --prompt TEXT     Inline question (mutually exclusive with --prompt-file).
#   --out DIR         Parent dir for the run (default: relay-system/<today>/). Each run gets its own
#                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
#   --models CSV      Which advisors to run (default: codex,gemini).
#   --label SLUG      Run-subdir + transcript stem (default: consult).
#
# Env config:
#   CODEX_BIN / GEMINI_BIN     binaries (default: codex / gemini); tests inject stubs
#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
#   GOOGLE_GENAI_USE_GCA       gemini personal-login auth (default: true)
#   CONSULT_GEMINI_JSON=1      capture gemini as -o json (enables best-effort cost.tokens) instead of
#                              readable text (Codex token parsing is still deferred — format un-probed)
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
CODEX_BIN="${CODEX_BIN:-codex}"
GEMINI_BIN="${GEMINI_BIN:-gemini}"
die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
warn() { printf 'consult: %s\n' "$*" >&2; }

PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,gemini"; LABEL="consult"
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

OUT="${OUT:-$ROOT/relay-system/$(date +%F)}"
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
_guarded() {  # <out> <cmd...>
  local out="$1"; shift
  local secs="${CONSULT_TIMEOUT:-300}" apid kpid rc=0
  ( cd "$WT" && "$@" < /dev/null ) > "$out" 2>&1 &
  apid=$!
  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
  kpid=$!
  wait "$apid" || rc=$?
  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
  [[ "$rc" != 0 ]] && printf '\nconsult: advisor failed or exceeded the %ss cap\n' "$secs" >> "$out"
  return "$rc"
}

run_codex() {
  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
  # ${_f[@]+...} guards an EMPTY flags array under `set -u` on bash 3.2 (macOS default).
  _guarded "$out" "$CODEX_BIN" exec ${_f[@]+"${_f[@]}"} "$FULL_PROMPT"
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

# --- fan out in parallel (indexed arrays — macOS bash 3.2 has no `declare -A`) --------------------
PIDS=(); PMODELS=(); POUTS=()
IFS=',' read -ra _models <<<"$MODELS"
for m in "${_models[@]}"; do
  m="${m// /}"; [[ -n "$m" ]] || continue
  case "$m" in
    codex)
      f="$RUN_DIR/${LABEL}.codex.md"
      run_codex "$f" & PIDS+=("$!"); PMODELS+=("codex"); POUTS+=("$f") ;;
    gemini)
      ext="md"; [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
      f="$RUN_DIR/${LABEL}.gemini.$ext"
      run_gemini "$f" & PIDS+=("$!"); PMODELS+=("gemini"); POUTS+=("$f") ;;
    *) warn "unknown model '$m' — skipping" ;;
  esac
done
((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"

# --- collect results -----------------------------------------------------------------------------
answered=0; failed=0; summary=""; i=0
while ((i < ${#PIDS[@]})); do
  pid="${PIDS[$i]}"; model="${PMODELS[$i]}"; out="${POUTS[$i]}"
  if wait "$pid"; then
    answered=$((answered + 1)); summary+=$'\n'"  [ok]   $model -> $out"
  else
    failed=$((failed + 1));   summary+=$'\n'"  [FAIL] $model -> $out (see transcript for error)"
  fi
  i=$((i + 1))
done

# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
  gj="$RUN_DIR/${LABEL}.gemini.json"
  if [[ -s "$gj" ]]; then
    "${TICK_BIN:-$ROOT/bin/tick}" cost "CONSULT-$LABEL" --agent gemini --from-gemini-json "$gj" --tool gemini \
      2>/dev/null || warn "gemini tokens not captured (no parseable stats)"
  fi
fi

printf 'consult: %d answered, %d failed -> %s%s\n' "$answered" "$failed" "$RUN_DIR" "$summary"
((answered > 0)) || { warn "all advisors failed"; exit 5; }
exit 0
