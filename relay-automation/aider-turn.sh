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
    exec python3 "$_xyz_root/utils/py/aider-turn.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
#
# aider-turn.sh — headless turn-taker for AIDER (https://aider.chat) driving any model via OPENROUTER
# (an OpenAI-standard gateway). Thin dispatch wrapper over the shared safety core (relay-turn-lib.sh) —
# the SAME containment contract as codex-turn.sh / agy-turn.sh, proving the boundary is model-agnostic.
# This lane is DISCRETE from the Codex lane: it shares no code or env with codex-turn.sh, so working on
# one never risks the other.
#
# WHY A SEPARATE SHIM: Aider is a file-EDITOR, not a shell-loop agent. Unlike codex/agy it does not run
# arbitrary shell (`tick`) mid-turn, and it AUTO-COMMITS by default. So this shim differs from the
# others in exactly two places, everything else is identical to the shared contract:
#   1. It performs the tick token ops ITSELF (take + ping before the turn); rtl_enforce (GH-67) then
#      closes/hands off the token after the file-scoped commit. Aider only edits files.
#   2. It runs aider with --no-auto-commits so Aider never git-commits — otherwise rtl_enforce's
#      commit-bypass guard (a moved HEAD) would fail every turn (exit 6). The harness owns the commit.
#
# Invoked by relay-drive.sh / marathon-agent.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   AIDER_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==AIDER_AGENT
#   ALLOW_PATHS     — comma-separated extra git paths the turn may change (the artifact(s))
#   RELAY_PEER      — the other agent's id, so rtl_enforce hands off "--to <peer>" when non-terminal
#   OPENROUTER_API_KEY — REQUIRED for the default OpenRouter seam. Aider reads it natively; this shim
#                        pre-flights it so a missing key fails fast (exit 5) instead of Aider hanging on
#                        an interactive prompt. NOT required when AIDER_OPENAI_API_BASE is set (below).
#   AIDER_OPENAI_API_BASE — GH-147 Phase 2 (LM_STUDIO lane): set this to select the LM Studio / any
#                     OpenAI-compatible seam instead of OpenRouter (e.g. http://127.0.0.1:1234/v1). Same
#                     env-var contract Phase 1 proved in relay-automation/consult.sh / utils/py/consult.py
#                     — reused verbatim, not redefined. Threads --openai-api-base/--openai-api-key into
#                     the aider invocation and skips the OPENROUTER_API_KEY pre-flight entirely. Unset
#                     (the default) keeps this shim byte-identical to the pre-GH-147 OpenRouter-only path.
#   AIDER_OPENAI_API_KEY — client key for AIDER_OPENAI_API_BASE (default: dummy — local servers usually
#                     ignore it, but Aider's client still requires a non-empty value; spike 0.2).
#   AIDER_MODEL     — model id. Default: openrouter/anthropic/claude-sonnet-5 (OpenRouter), or
#                     openai/agents-a1 when AIDER_OPENAI_API_BASE is set (LM Studio). Set it to any
#                     OpenRouter model, e.g. openrouter/openai/gpt-4o, openrouter/deepseek/deepseek-chat.
#                     Resolving a colloquial name (e.g. "GLM 5.2") to its canonical slug? Don't probe
#                     `aider --list-models` or curl the live catalog — run
#                     `relay-automation/resolve-model-alias.sh "<name>"` first (local alias table,
#                     GH-120); see the `/open-router` skill or README.md's "OpenRouter model-alias
#                     lookup" section.
#   AIDER_FLAGS     — optional extra flags appended to the aider invocation (advanced/override)
#   AIDER_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
#   AIDER_LOG       — where to write the aider transcript (default: a $TMPDIR file)
#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
#                     containment; off-lane in the worktree → exit 6). Default OFF.
#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 600). A hung/runaway aider
#                          is killed after this many seconds; the turn exits 7.
#
# Headless contract:
#   --message "<prompt>"   — run one instruction non-interactively, then exit
#   --yes-always           — auto-approve every confirmation (no interactive gate)
#   --no-auto-commits      — Aider must NOT git-commit (see WHY #2 above); the harness commits
#   --no-gitignore --no-check-update --no-analytics --no-show-model-warnings --no-stream --map-tokens 0
#   --file <path>          — one per allowlisted file (the relay file + each ALLOW_PATHS artifact), so
#                            Aider edits exactly the on-lane surface
#   --read <path>          — GH-119: on a REVIEW-ONLY turn (ALLOW_PATHS empty), the artifact under
#                            review (RTL_ARTIFACT, absolutized from RELAY_ARTIFACT_FILE by
#                            relay-turn-lib.sh) + every file its diff touches, so the model has
#                            full context but --yes-always can never make them writable.
#   OpenRouter needs no base-url flag — `--model openrouter/...` + OPENROUTER_API_KEY is Aider-native.
#
# Exit: 0 acted/deferred · 5 aider failed / no OPENROUTER_API_KEY / empty output · 6 off-allowlist edit
#       (reverted) · 7 timeout-killed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
# ($HERE/..). Explicit AIDER_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
ROOT="${AIDER_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
AIDER_BIN="${AIDER_BIN:-aider}"
# GH-147 Phase 2 (LM_STUDIO lane): two seams share this shim, same contract Phase 1 proved in
# consult.sh. AIDER_OPENAI_API_BASE set -> LM Studio / OpenAI-compatible seam (default model
# openai/agents-a1); unset -> the OpenRouter default, byte-identical to the pre-GH-147 behavior.
if [[ -n "${AIDER_OPENAI_API_BASE:-}" ]]; then
  AIDER_MODEL="${AIDER_MODEL:-openai/agents-a1}"
else
  AIDER_MODEL="${AIDER_MODEL:-openrouter/anthropic/claude-sonnet-5}"
fi
die() { printf 'aider-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
aider_agent="${AIDER_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$aider_agent" ]] || die "AIDER_AGENT required"

# Dispatch only for the aider agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$aider_agent" ]]; then
  printf 'aider-turn: actor %s is not the aider agent (%s) — deferring (window-driven)\n' "$me" "$aider_agent" >&2
  exit 0
fi

# Auth pre-flight. Two seams share this shim (GH-147 Phase 2): OpenRouter is pure API-key (a missing
# key would make aider prompt interactively and deadlock the headless turn, so fail fast with the
# remedy — mirrors agy's `agy login` pre-flight); the LM Studio / OpenAI-compatible seam authenticates
# via AIDER_OPENAI_API_BASE + AIDER_OPENAI_API_KEY (dummy default) instead and needs no
# OPENROUTER_API_KEY at all — mirrors run_aider() in relay-automation/consult.sh verbatim.
aider_auth_args=()
if [[ -n "${AIDER_OPENAI_API_BASE:-}" ]]; then
  # Keep credentials out of process argv: Aider/LiteLLM reads OPENAI_API_KEY from its environment.
  export OPENAI_API_KEY="${AIDER_OPENAI_API_KEY:-dummy}"
  aider_auth_args=(--openai-api-base "$AIDER_OPENAI_API_BASE")
elif [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
  printf 'aider-turn: OPENROUTER_API_KEY is not set — Aider cannot reach OpenRouter (or set AIDER_OPENAI_API_BASE for an OpenAI-compatible/LM Studio endpoint). Export it, then retry.\n' >&2
  exit 5
fi

rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"

prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief.
drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
# Aider can't run shell mid-turn, and this shim owns the token ops — tell the model so, so it spends the
# turn on the file edit(s) instead of emitting tick commands it can't run.
prompt="${prompt}"$'\n\n'"NOTE (Aider harness): do NOT run any tick commands — the harness has already claimed the token and will release/close it for you after your edit. Spend this turn ONLY editing the file(s) added to the chat: append your block to the relay file and set its STATUS, and edit the artifact(s) if this is a build turn."

# GH-251 review mode: on a REVIEW-ONLY turn (ALLOW_PATHS empty) Aider is being used as a REVIEWER, not
# an editor. Aider defaults to an editor posture and drifts into "what changes would you like?" instead
# of reporting — so the review never lands as a relay-file append and relay-drive --review-once then
# CORRECTLY scores the unchanged file a stall (GH-245), discarding a completed review. Make the review
# posture explicit: the relay file is the ONLY writable target (the artifact is --read), so the model
# must spend the turn appending a graded review THERE. If it still doesn't, the transcript-salvage
# backstop after the run (also GH-251) recovers the review from the turn transcript.
if [[ -z "${ALLOW_PATHS:-}" ]]; then
  prompt="${prompt}"$'\n\n'"REVIEW MODE (Aider harness, GH-251): this is a REVIEW turn — do NOT propose or make code edits. Read the artifact under review, then APPEND your graded review to the relay file added to the chat: a findings list with file:line citations, then a final line 'Verdict: Approved' or 'Verdict: Changes requested'. The relay file is the ONLY file you may edit this turn."
fi

# --file targets: the relay file + each ALLOW_PATHS artifact, as ROOT-RELATIVE paths so they resolve
# against the turn's CWD (ROOT normally; the throwaway worktree under isolation). Passing relative paths
# is what makes worktree isolation work — Aider edits the worktree copy, which rtl_worktree_end then
# copies back (an absolute ROOT path would bypass the worktree and defeat containment).
rel_relay="${f#"$ROOT"/}"
file_args=(--file "$rel_relay")
claim_paths="$rel_relay"
if [[ -n "${ALLOW_PATHS:-}" ]]; then
  IFS=',' read -ra _aps <<<"${ALLOW_PATHS}"
  for _ap in "${_aps[@]}"; do _ap="${_ap#"${_ap%%[![:space:]]*}"}"; _ap="${_ap%"${_ap##*[![:space:]]}"}"; [[ -n "$_ap" ]] && { file_args+=(--file "$_ap"); claim_paths="$claim_paths,$_ap"; }; done
fi

# GH-119: on a REVIEW-ONLY turn (ALLOW_PATHS empty — the Reviewer must never edit the artifact), give
# Aider structural READ access to the artifact under review plus every file its diff actually touches.
# Root cause of the bug this closes: with --yes-always, ANY file a model names in a SEARCH/REPLACE
# block becomes writable, regardless of role — a reviewer that spots a referenced file in the diff can
# emit an edit for it, and the harness's all-or-nothing containment then discards the WHOLE turn
# (including the correctly-scoped relay-file edit) when that off-lane write is caught. --read is
# structurally read-only in Aider even under --yes-always, so this gives full context with no writable
# surface — the build/fix path (ALLOW_PATHS set) is completely untouched.
read_args=()
if [[ -z "${ALLOW_PATHS:-}" && -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
  # Absolute path: RELAY_ARTIFACT_FILE is always absolutized by the caller (relay-turn-lib.sh), so it
  # resolves correctly whether the turn runs CWD=ROOT or CWD=<isolated worktree> — it is never an edit
  # target (never added to RTL_ALLOW / copied back), so no worktree-relative form is needed.
  read_args+=(--read "$RTL_ARTIFACT")
  # Parse changed-file paths out of the diff (git-show / unified-diff format) and add each, resolved
  # repo-relative so it resolves under worktree isolation too (a tracked file exists at HEAD there).
  while IFS= read -r _cp; do
    [[ -n "$_cp" && -f "$ROOT/$_cp" && "$_cp" != "$rel_relay" ]] && read_args+=(--read "$_cp")
  done < <(sed -nE 's#^diff --git a/(.+) b/.+$#\1#p; s#^\+\+\+ b/(.+)$#\1#p' "$RTL_ARTIFACT" | sort -u)
fi

# The shim performs the token ops Aider can't (claim THIS handed-off task + ping). rtl_enforce (GH-67)
# does the authoritative release/done AFTER the file-scoped commit, but it is ownership-guarded — it
# only fires if THIS agent is the token's claimer. Use `claim <task> --paths` (NOT `take`, which grabs
# whatever task is offered to the agent, not the specific RELAY_TASK).
#
# GH-77 [Blocker] fix: PROVE ownership before launching Aider. The claim stays best-effort (it may
# already be held by self, and the prompt forbids Aider from running tick), but if it truly MISSED we
# must not proceed: the turn would still edit + commit while the token stayed open under the OLD owner,
# and rtl_enforce — being ownership-guarded — could then only WARN, deadlocking the lane. So after
# claiming, assert `claimer == self` via `tick info` and fail the turn (exit 5, before any mutation).
_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$(rtl_tick_bin "$_tickroot")"
if [[ -x "$_tickbin" ]]; then
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
  _claimer="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$t" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
  if [[ "$_claimer" != "$me" ]]; then
    printf 'aider-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
    exit 5
  fi
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
fi

# GH-161/GH-280: persistent, gitignored transcript (relay-system/logs/<day>/...) instead of an
# ephemeral $TMPDIR path — codex-turn.sh/agy-turn.sh already switched to rtl_default_log; this shim
# was missed, so every aider-turn failure transcript was lost as soon as the tmp file was reaped,
# including the GH-280 worktree-mode failures this was supposed to help diagnose.
AIDER_LOG="${AIDER_LOG:-$(rtl_default_log "$ROOT" aider-turn "$t")}"

# GH-77 live-E2E fix: redirect Aider's own aux/history files OUT of the target repo. By default Aider
# writes `.aider.chat.history.md` + `.aider.input.history` (and `.aider.llm.history`) into CWD; with
# `--no-gitignore` they land as UNTRACKED files in the working tree and trip rtl_enforce's off-allowlist
# guard (exit 6) — so every REAL turn failed even though the stub tests (which never create them) passed.
# Point them at a throwaway dir outside the repo so containment only ever sees the intended relay/artifact
# edits. (`--map-tokens 0` already suppresses the `.aider.tags.cache.*` repo-map; `--no-analytics` the rest.)
AIDER_AUX_DIR="${AIDER_AUX_DIR:-${TMPDIR:-/tmp}/aider-aux-$$}"; mkdir -p "$AIDER_AUX_DIR" 2>/dev/null || true

# GH-186: vendored installs can run older aider builds where --add-gitignore-files still exists and
# is needed for gitignored relay files, while current aider releases removed it and now hard-fail on
# the flag. Probe the installed binary's actual CLI surface instead of hardcoding either behavior.
aider_supports_add_gitignore_files() {
  local _help
  _help="$("$AIDER_BIN" --help 2>/dev/null)" || return 1
  grep -q -- '--add-gitignore-files' <<<"$_help"
}

# Build the aider invocation. --no-auto-commits is LOAD-BEARING (see WHY #2). AIDER_FLAGS is an escape
# hatch for version-specific flag differences.
#
# GH-168 + GH-186: old aider builds may still need --add-gitignore-files for gitignored relay files,
# while current aider releases removed the flag entirely. Always pass --no-gitignore; add the legacy
# flag only when the installed aider advertises it in --help.
turn_timeout="${RELAY_TURN_TIMEOUT_S:-600}"
gitignore_args=(--no-gitignore)
if aider_supports_add_gitignore_files; then
  gitignore_args+=(--add-gitignore-files)
fi
aider_args=(--model "$AIDER_MODEL" --yes-always --no-auto-commits
            ${aider_auth_args[@]+"${aider_auth_args[@]}"}
            "${gitignore_args[@]}"
            --no-check-update --no-analytics --no-show-model-warnings --no-stream --map-tokens 0
            --chat-history-file "$AIDER_AUX_DIR/chat.history.md"
            --input-history-file "$AIDER_AUX_DIR/input.history"
            --llm-history-file  "$AIDER_AUX_DIR/llm.history"
            "${file_args[@]}" ${read_args[@]+"${read_args[@]}"})
read -ra _xflags <<<"${AIDER_FLAGS:-}"
[[ "${#_xflags[@]}" -gt 0 ]] && aider_args+=("${_xflags[@]}")

# GH-251: content signature of the relay file BEFORE the turn, so a review-only turn that produced a
# graded review in the transcript but landed NO relay-file append can be detected (unchanged file) and
# the review salvaged from the transcript after the run. Captured at ROOT so it reflects the copy-back
# state under worktree isolation too.
_relay_presig="$(git -C "$ROOT" hash-object -- "$f" 2>/dev/null || cksum <"$f" 2>/dev/null || echo none)"

rtl_before
bounded_rc=0

# Worktree isolation (opt-in; same wiring as agy-turn.sh / claude-turn.sh). CWD = a throwaway worktree
# of ROOT@HEAD; .tick coordination state stays SHARED via TICK_REPO_ROOT=ROOT. Default OFF → the in-ROOT
# run is byte-for-byte the prior behaviour.
wt=""; cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$ROOT")
if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
  if wt="$(rtl_worktree_begin)"; then
    export TICK_REPO_ROOT="$_tickroot"
    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    printf 'aider-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'aider-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    exit 5
  fi
fi

# Run aider headless (edits the files added to the chat; NO git — --no-auto-commits), then enforce the
# boundary. CWD is pinned to ROOT (or the worktree) so aider operates on the right git tree.
rtl_run_bounded "$turn_timeout" "${cwd_wrap[@]}" "$AIDER_BIN" "${aider_args[@]}" --message "$prompt" \
  < /dev/null > "$AIDER_LOG" 2>&1 || bounded_rc=$?

# Worktree teardown FIRST (regardless of rc): copies the allowlist back to ROOT unless an off-lane
# change was detected → exit 6 (containment takes precedence over timeout 7 / failure 5).
if [[ -n "$wt" ]]; then
  rtl_worktree_end "$wt"
  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
    printf 'aider-turn: aider made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
    exit 6
  fi
fi

if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'aider-turn: aider exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'aider-turn: aider failed (exit %s) — see %s\n' "$bounded_rc" "$AIDER_LOG" >&2; exit 5
fi
# Empty-output guard (mirrors agy): a clean exit with NO transcript is a phantom turn (e.g. a blocked
# backend) — treat it as a failure, not a silent no-op that would advance the relay on false success.
if [[ "$bounded_rc" -eq 0 && ! -s "$AIDER_LOG" ]]; then
  printf 'aider-turn: aider exited 0 but produced NO output — likely a blocked/misconfigured backend. Failing the turn.\n' >&2
  exit 5
fi
# GH-251 transcript-salvage backstop. On a REVIEW-ONLY turn (ALLOW_PATHS empty), if the relay file is
# byte-unchanged after the turn but the transcript carries a graded review (a `Verdict:` anchor), Aider
# produced a real review that it failed to land as a relay-file append. Recover it: append the turn
# transcript to the relay file (attributed, verbatim, fenced) so the completed review LANDS instead of
# being discarded as a stall. Runs BEFORE rtl_enforce so the salvaged append is the file-scoped commit.
#
# Composition with the GH-245 evidence-based --review-once classifier is preserved: an EMPTY turn is
# already failed above (empty-output guard, exit 5); a turn that produced output but NO gradeable review
# leaves no `Verdict:` anchor here, so it is NOT salvaged, the relay file stays unchanged, and the drive
# still scores it a genuine stall. Only a turn that truly produced a graded review is rescued.
if [[ -z "${ALLOW_PATHS:-}" && "$bounded_rc" -eq 0 && -s "$AIDER_LOG" ]]; then
  _relay_postsig="$(git -C "$ROOT" hash-object -- "$f" 2>/dev/null || cksum <"$f" 2>/dev/null || echo none)"
  if [[ "$_relay_postsig" == "$_relay_presig" ]] && grep -qiE 'verdict[[:space:]]*:' "$AIDER_LOG" 2>/dev/null; then
    {
      printf '\n\n---\n\n### Review salvaged from %s transcript (aider-turn.sh · GH-251)\n\n' "$AIDER_MODEL"
      printf '_Aider completed a review turn but did not land it as a relay-file append; the harness\n'
      printf 'recovered the graded review from the turn transcript verbatim below (attributed, not edited)._\n\n'
      printf '```text\n'
      cat "$AIDER_LOG"
      printf '\n```\n'
    } >>"$f"
    printf 'aider-turn: review turn landed no relay-file delta but the transcript carried a graded review — salvaged it into the relay file (attributed; GH-251)\n' >&2
  fi
fi

# Always enforce containment even after a timeout-kill; rtl_enforce may exit 6 (precedence over 7) and
# performs the authoritative token release/done (GH-67) now that this agent is the token's claimer.
rtl_enforce "$t" "$me" "$AIDER_LOG" "aider"
if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi

# NOTE: OpenRouter returns a usage block in its API response, but Aider does not surface a machine
# -readable token JSON on stdout in --message mode, so there is no cost.tokens capture here (this lane
# is a cost floor, same Phase-1 partial as the Codex/agy lanes).
