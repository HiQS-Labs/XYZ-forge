#!/usr/bin/env bash
# relay-turn-lib.sh — shared, model-AGNOSTIC safety core for headless relay turn-takers.
# SOURCED by codex-turn.sh and gemini-drive.sh (thin dispatch wrappers); not run on its own.
#
# Containment contract — decisions/2026-06-15-unattended-agent-containment.md (3-model validated):
#   (1) path-allowlist      — revert + FAIL on any change outside {relay file, ALLOW_PATHS}
#   (2) commit-bypass guard — reset --hard + FAIL if the agent committed during its own turn
#   (3) no push             — stage only the allowlist, commit file-scoped, never push
# Keeping this in ONE place means a new turn-taker (gemini-drive.sh, …) inherits the exact
# boundary instead of reimplementing it — reimplementation is where a fourth bypass sneaks in.
#
# API (all state in namespaced RTL_* globals):
#   rtl_init        <root> <relay_file> <allow_csv>   — set ROOT + build normalized allowlist
#   rtl_turn_prompt <agent> <relay_file> <task> <csv> — emit the shared ▶ TAKE-YOUR-TURN prompt
#   rtl_before                                         — snapshot HEAD before the agent runs
#   rtl_enforce     <task> <agent> <log> <tool>        — guards (2)+(1)+(3); EXITS 6 on violation
#
# rtl_enforce deliberately `exit 6`s the calling shell on any violation — that fails the turn.

rtl_init() {  # <root> <relay_file> <allow_csv>
  RTL_ROOT="$1"; local f="$2" csv="$3"
  RTL_ALLOW=("$f")
  local _extra p; IFS=',' read -ra _extra <<<"$csv"
  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
  local _n=() a                       # normalize to repo-root-relative (git status emits relative)
  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
  RTL_ALLOW=("${_n[@]}")
}

rtl_in_allow() { local x="$1" a; for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done; return 1; }

rtl_turn_prompt() {  # <agent> <relay_file> <task> <allow_csv> [peer]
  local agent="$1" f="$2" task="$3" csv="$4" peer="${5:-}"
  # Name the peer explicitly when known — a live Gemini turn (2026-06-15) released the token to the
  # literal role "Producer" because "the other agent" was unnamed. RELAY_PEER closes that ambiguity.
  local handoff="release --to the other agent (the role named by NEXT in the file)"
  [[ -n "$peer" ]] && handoff="release --to ${peer}"
  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. Use ./bin/tick for the %s token (claim/ping, then %s, or done + set STATUS: Approved when approving). Edit ONLY %s%s. Do NOT run git (no add/commit/push) and do NOT touch any other file — the harness commits for you.' \
    "$agent" "$f" "$task" "$handoff" "$f" "${csv:+ and: $csv}"
}

rtl_before() {
  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
  RTL_BEFORE=()
  local fld
  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
}

rtl_was_dirty_before() {  # <porcelain-entry> — true if this exact status+path was dirty pre-turn
  local e="$1" b
  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
  return 1
}

rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
  local p="$1"
  [[ -n "$p" ]] || return 0
  # tick's own state dir is coordination state the turn legitimately writes — exempt it intrinsically,
  # independent of whether the HOST repo gitignores .tick (field report MBP16 [2]).
  case "$p" in .tick/*|.tick) return 0 ;; esac
  # the shim's own transcript log, if it lands in the tree, is not an agent edit — drop it, don't flag
  if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
  rtl_in_allow "$p" && return 0
  printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
  RTL_VIOLATION=1
}

rtl_enforce() {  # <task> <agent> <log> <tool>
  local task="$1" agent="$2" log="$3"; RTL_TOOL="$4"
  # (2) commit-bypass guard: the agent must NOT git. If HEAD moved, its edits are hidden from
  # `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
  if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
    git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
    printf '%s-turn: %s committed during its turn (forbidden) — reset to %s, failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
    exit 6
  fi
  # (1) allowlist enforcement on tracked-tree changes (.tick is gitignored, so token ops don't show).
  # -z = NUL-delimited RAW unquoted paths (spaces/special chars can't slip the match or break the
  # revert); rename/copy records (R/C) carry a second NUL field — check both old+new. We deliberately
  # do NOT `git clean -Xdf` (it would wipe .tick, the coordination state the turn legitimately writes);
  # ignored-file safety belongs to the agent sandbox, tracked as future.
  RTL_LOG_REL="${log:+${log#"$RTL_ROOT"/}}"
  RTL_VIOLATION=0
  local entry xy path src
  while IFS= read -r -d '' entry; do
    [[ -n "$entry" ]] || continue
    xy="${entry:0:2}"; path="${entry:3}"
    # pre-existing ambient WIP (same status+path as before the turn) — leave it untouched, don't fail.
    # (Documented minor gap: a file already dirty that the agent edits further to the SAME status code
    # isn't caught — acceptable for review turns.)
    if rtl_was_dirty_before "$entry"; then
      case "$xy" in R*|C*) IFS= read -r -d '' src || true ;; esac   # keep the -z stream aligned
      continue
    fi
    case "$xy" in
      R*|C*) IFS= read -r -d '' src || true; rtl_check "$path"; rtl_check "$src" ;;
      *)     rtl_check "$path" ;;
    esac
  done < <(git -C "$RTL_ROOT" status --porcelain -z)
  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; exit 6; }
  # (3) stage ONLY the allowlist; commit file-scoped; NO push.
  git -C "$RTL_ROOT" add -- "${RTL_ALLOW[@]}" 2>/dev/null || true
  if git -C "$RTL_ROOT" diff --cached --quiet; then
    printf '%s-turn: %s turn produced no tracked changes (token-only move?)\n' "$RTL_TOOL" "$agent"
  else
    git -C "$RTL_ROOT" commit -q -m "relay(${task}): ${agent} turn (${RTL_TOOL} headless; no push)"
    printf '%s-turn: committed %s turn (file-scoped, no push)\n' "$RTL_TOOL" "$agent"
  fi
}
