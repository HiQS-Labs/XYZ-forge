#!/usr/bin/env bash
# relay-turn-lib.sh — shared, model-AGNOSTIC safety core for headless relay turn-takers.
# SOURCED by codex-turn.sh and gemini-drive.sh (thin dispatch wrappers); not run on its own.
#
# Containment contract — decisions/2026-06-15-unattended-agent-containment.md (3-model validated):
#   (1) path-allowlist      — revert + FAIL on any change outside {relay file, ALLOW_PATHS}.
#                             REVIEWER-turn scoping: when the relay file's NEXT names the Reviewer,
#                             ALLOW_PATHS is dropped (allowlist = relay file ONLY), so a headless
#                             reviewer cannot edit the artifact it is reviewing — any such edit reverts.
#   (2) commit-bypass guard — if the agent committed during its own turn: reset --hard + FAIL (in-ROOT).
#                             In a worktree-isolated turn the agent CANNOT reach ROOT's HEAD, so a moved
#                             ROOT HEAD is a CONCURRENT PEER commit — PRESERVED, not reset (GH-13).
#   (3) no push             — stage only the allowlist, commit file-scoped, never push
# Keeping this in ONE place means a new turn-taker (gemini-drive.sh, …) inherits the exact
# boundary instead of reimplementing it — reimplementation is where a fourth bypass sneaks in.
#
# API (all state in namespaced RTL_* globals):
#   rtl_init        <root> <relay_file> <allow_csv>   — set ROOT + build normalized allowlist
#                                                       (REVIEWER turn → allowlist = relay file only)
#   rtl_turn_prompt <agent> <relay_file> <task> <csv> — emit the shared ▶ TAKE-YOUR-TURN prompt
#                                                       (REVIEWER turn → "do not edit the artifact")
#   rtl_before                                         — snapshot HEAD before the agent runs
#   rtl_enforce     <task> <agent> <log> <tool>        — guards (2)+(1)+(3); EXITS 6 on violation
#   rtl_run_bounded <timeout_secs> <cmd...>            — run <cmd...> under a wall-clock cap;
#                                                        returns 0 on success, the cmd's own exit
#                                                        code on normal failure, or 7 on timeout-kill.
#                                                        No dependency on coreutils `timeout` (absent
#                                                        on stock macOS) — sleep+kill watchdog pattern
#                                                        (same as consult.sh _guarded). Kills by PID;
#                                                        see function body for the process-group gap.
#
# rtl_enforce deliberately `exit 6`s the calling shell on any violation — that fails the turn.
# rtl_run_bounded returns 7 on timeout; the CALLER must decide whether to continue to rtl_enforce
# (it should — a killed agent may have left off-lane changes) and then exit 7 after enforcement.
# Exit-code priority: containment violation (6) takes precedence over timeout (7). Rationale: a
# containment violation means unsafe state was left in the repo; that signal is more critical to
# surface than the mechanism (timeout) that caused the agent to be killed. A shim that detects a
# timeout should still call rtl_enforce, and if rtl_enforce exits 6 the process exits 6 — correct.
# If rtl_enforce completes without violation the shim then exits 7 to report the timeout.

rtl_is_reviewer_turn() {  # <relay_file> — true if the file's NEXT pointer names the Reviewer role
  # The relay protocol's NEXT pointer (the FIRST `NEXT:` line — the header) names the ROLE that acts
  # next (Producer | Reviewer). A reviewer only appends findings to the relay file; it must never edit
  # the artifact. Match the header line only, so a body/instruction mention of "NEXT: Reviewer" can't
  # false-trigger. Portable (no GNU \b): BSD/macOS grep -E + POSIX classes. Missing/None → not reviewer.
  local f="$1" line
  [[ -f "$f" ]] || return 1
  line="$(grep -iE '^[[:space:]]*NEXT:' "$f" 2>/dev/null | head -1)"
  printf '%s' "$line" | grep -iqE 'Reviewer'
}

rtl_init() {  # <root> <relay_file> <allow_csv>
  # ROOT routing (GH-11): a foreign --target-root (exported by relay-drive as RELAY_TARGET_ROOT)
  # routes the WHOLE turn — worktree base, allowlist copyback, file-scoped commit, enforce — from this
  # one anchor. Unset/empty → the caller's <root> (today's behavior, byte-for-byte). Coordination
  # (.tick) stays where TICK_REPO_ROOT points (the harness clone); only the ARTIFACT side moves.
  RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"; local f="$2" csv="$3"
  RTL_WT_USED=0          # set to 1 by rtl_worktree_begin; read by rtl_enforce's commit-bypass guard (GH-13)
  RTL_ALLOW=("$f")
  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
  # and must never edit the artifact under review. When NEXT names the Reviewer, drop the caller's
  # extra allowlist (relay file ONLY) so any artifact edit a headless reviewer makes is reverted by
  # rtl_enforce. This is the boundary an over-eager agy reviewer crossed on 2026-06-20 (it edited
  # validate.sh because the artifact sat on ALLOW_PATHS). Producer turns keep the full allowlist —
  # they legitimately build.
  if rtl_is_reviewer_turn "$f"; then
    [[ -n "$csv" ]] && printf 'relay-turn: REVIEWER turn — scoping allowlist to the relay file only (ignoring ALLOW_PATHS=%s)\n' "$csv" >&2
    csv=""
  fi
  local _extra p; IFS=',' read -ra _extra <<<"$csv"
  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
  local _n=() a                       # normalize to repo-root-relative (git status emits relative)
  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
  RTL_ALLOW=("${_n[@]}")
}

rtl_in_allow() { local x="$1" a; for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done; return 1; }

rtl_run_bounded() {  # <timeout_secs> <cmd...>
  # Run <cmd...> under a wall-clock ceiling without coreutils `timeout` (absent on stock macOS).
  # Mirrors the consult.sh _guarded() pattern: sleep-then-kill watchdog, no external deps.
  # Process-group note: `setsid` is absent on stock macOS so we kill by PID (same as consult.sh).
  # A multi-process CLI whose children outlive the leader is a known gap; worktree isolation is
  # the airtight follow-up (ROADMAP 3.6). The PID kill is sufficient for hung single-process CLIs.
  # NOTE: disk-quota and per-turn spend ceilings are NOT yet enforced here — wall-clock only (R5
  # partial). Disk-quota belongs in a TMPDIR watchdog; spend ceilings are model-shim-specific.
  local secs="$1"; shift
  local apid kpid rc=0
  "$@" &
  apid=$!
  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
  kpid=$!
  wait "$apid" 2>/dev/null || rc=$?
  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
  # Distinguish timeout-kill (signal 9 → exit 137) from a genuine rc=137 from the CLI itself.
  # We use rc=137 as the proxy for "killed by our watchdog" and map it to 7.
  # This is the same tradeoff consult.sh accepts: a CLI that genuinely crashes with rc=137 looks
  # like a timeout. Acceptable — both cases are "turn failed abnormally."
  if [[ "$rc" -eq 137 ]]; then
    return 7
  fi
  return "$rc"
}

# --- Worktree isolation (ROADMAP Part A Phase 3.6 — the airtight async/side-effect close) ----------
# OPT-IN: callers gate on RELAY_WORKTREE_ISOLATION=1. Default OFF → behaviour is unchanged.
# Run the agent turn in a THROWAWAY git worktree of RTL_ROOT@HEAD, so any async/background write
# lands in a tree we delete — RTL_ROOT is never the agent's target. This closes the gap left by the
# point-in-time `rtl_enforce` + the (macOS-absent) setsid process-group reap: ROOT safety no longer
# depends on killing the process group, because the agent can't reach ROOT in the first place.
# Coordination state (.tick) stays SHARED — the caller must run the agent with TICK_REPO_ROOT=RTL_ROOT.
#
# SEED LIMITATIONS (relay review 2026-06-23 F4/F5 — known constraints, documented; structural fix deferred):
#   - Cross-repo artifact: the worktree is a checkout of RTL_ROOT@HEAD and seeds only allowlisted paths
#     UNDER RTL_ROOT (below). An artifact in ANOTHER repo is neither at HEAD nor seeded, so it is invisible
#     to an isolated turn. Until a read-only out-of-ROOT seed exists, embed a cross-repo artifact inline in
#     the relay file, or stage it under RTL_ROOT. (RELAY_TARGET_ROOT relocates the single artifact root,
#     not "harness in repo A + artifact in repo B".)
#   - Uncommitted artifact on a REVIEWER turn: rtl_init drops ALLOW_PATHS on a reviewer turn, so only the
#     relay file is seeded. A brand-new (untracked) artifact-under-review is then neither at HEAD nor
#     seeded — the reviewer reads a missing/stale file. COMMIT review inputs before an isolated reviewer
#     turn. The real fix — a read-only seed set distinct from the writable allowlist, so a reviewer can
#     READ but not WRITE the artifact in the worktree — is tracked as #15, not done here.
rtl_worktree_begin() {
  # Create the worktree, seed the CURRENT working-tree allowlist into it (the HEAD checkout may be
  # stale, e.g. an uncommitted relay file), and echo the worktree path. Returns non-zero on failure
  # so the caller can fall back to an in-ROOT run. Sets RTL_WT.
  local wt a
  wt="$(mktemp -d "${TMPDIR:-/tmp}/rtl-wt.XXXXXX")" || return 1
  rm -rf "$wt"                         # git worktree add wants a non-existent path
  if ! git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
    rm -rf "$wt" 2>/dev/null; return 1
  fi
  for a in "${RTL_ALLOW[@]}"; do       # seed current content (overwrite HEAD versions)
    if [[ -e "$RTL_ROOT/$a" ]]; then
      mkdir -p "$wt/$(dirname "$a")"
      cp -R "$RTL_ROOT/$a" "$wt/$a"
    else
      rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
                                       # deletion, else the HEAD checkout would resurrect it on copy-back
    fi                                 # (Codex review r2, 2026-06-20 — symmetric to the in-turn delete)
  done
  RTL_WT="$wt"; RTL_WT_USED=1   # GH-13: mark the turn worktree-isolated so rtl_enforce won't reset a concurrent peer's ROOT commit
  printf '%s\n' "$wt"
}

rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist back unless off-lane found
  # Contain + DETECT: if the agent touched anything outside {allowlist, .tick} in the worktree, that's
  # an off-lane attempt — do NOT copy anything back (the turn must fail like an in-ROOT exit-6), set
  # RTL_WT_OFFLANE=1, and destroy the worktree. Otherwise copy ONLY the allowlist back to RTL_ROOT —
  # edits/creates propagate, AND an allowlisted path the turn DELETED in the worktree is removed from
  # RTL_ROOT too (so an isolated Producer that deletes an artifact isn't silently undone — Codex review
  # 2026-06-20) — then destroy the worktree.
  local wt="${1:-${RTL_WT:-}}" a entry xy path
  RTL_WT_OFFLANE=0
  [[ -n "$wt" && -d "$wt" ]] || return 0
  while IFS= read -r -d '' entry; do
    [[ -n "$entry" ]] || continue
    xy="${entry:0:2}"; path="${entry:3}"
    case "$xy" in R*|C*) IFS= read -r -d '' _ || true ;; esac   # rename/copy: consume 2nd NUL field
    case "$path" in .tick/*|.tick) continue ;; esac
    rtl_in_allow "$path" && continue
    RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
  done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
  if ((RTL_WT_OFFLANE == 0)); then
    for a in "${RTL_ALLOW[@]}"; do
      if [[ -e "$wt/$a" ]]; then
        mkdir -p "$RTL_ROOT/$(dirname "$a")"
        cp -R "$wt/$a" "$RTL_ROOT/$a"
      elif [[ -e "$RTL_ROOT/$a" ]]; then
        rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
      fi
    done
  fi
  git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
  git -C "$RTL_ROOT" worktree prune >/dev/null 2>&1 || true
  RTL_WT=""
}

rtl_turn_prompt() {  # <agent> <relay_file> <task> <allow_csv> [peer]
  local agent="$1" f="$2" task="$3" csv="$4" peer="${5:-}"
  # Name the peer explicitly when known — a live Gemini turn (2026-06-15) released the token to the
  # literal role "Producer" because "the other agent" was unnamed. RELAY_PEER closes that ambiguity.
  local handoff="release --to the other agent (the role named by NEXT in the file)"
  [[ -n "$peer" ]] && handoff="release --to ${peer}"
  # Emit repo-root-relative EDIT paths (relay file, artifact) so they resolve against the turn's CWD —
  # which under worktree isolation IS the throwaway worktree. An ABSOLUTE edit path would invite the
  # model to write straight into RTL_ROOT, bypassing the worktree (Codex review 2026-06-20). RTL_ROOT
  # is set by rtl_init (always called first). Residual: a sync absolute write the model constructs
  # itself is still backstopped by rtl_enforce on ROOT (revert + exit 6); an ASYNC one remains the
  # known process-detachment gap.
  # The TICK invocation is the EXCEPTION and is deliberately ABSOLUTE + env-pinned: tick is a tool, not
  # an edit target, and .tick is SHARED coordination state that must resolve to the harness root no
  # matter the CWD. A bare/`./bin/tick` from a worktree or foreign CWD silently no-ops -> the token
  # never releases -> deadlock (relay review 2026-06-23 F1). tickroot = the harness clone (where
  # bin/tick + .tick live), i.e. TICK_REPO_ROOT (exported by the shim), falling back to RTL_ROOT.
  local root="${RTL_ROOT:-}" tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}" f_rel csv_rel="" p _a
  f_rel="${f#"${root:+$root/}"}"
  if [[ -n "$csv" ]]; then
    IFS=',' read -ra _a <<<"$csv"
    for p in "${_a[@]}"; do [[ -n "$p" ]] && csv_rel+="${csv_rel:+,}${p#"${root:+$root/}"}"; done
  fi
  # REVIEWER-turn scoping: drop the csv from the "edit only" clause and tell the model plainly it must
  # not edit the artifact — so the prompt matches the relay-file-only allowlist rtl_init enforces (an
  # agent told it MAY edit X and then reverted is needless friction; tell it the truth up front).
  local role_note=""
  if rtl_is_reviewer_turn "$f"; then
    csv_rel=""
    role_note=' You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn.'
  fi
  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. For the %s token ALWAYS use the absolute, env-pinned tick — a bare or ./bin/tick from a worktree/foreign CWD silently no-ops and DEADLOCKS the relay: TICK_REPO_ROOT="%s" "%s/bin/tick". Token sequence: (1) claim it FIRST — claim %s --agent %s --paths %s — the --paths flag is MANDATORY; without it the claim silently fails (prints usage) and your later release errors "task ... is open". (2) ping is optional. (3) when finished, %s (or done + set STATUS: Approved when approving). Edit ONLY %s%s.%s NEVER run git yourself — no add/commit/push/reset; a self-commit FAILS your whole turn. Do NOT touch any other file. The harness makes the one file-scoped commit for you after you hand off the token.' \
    "$agent" "$f_rel" "$task" "$tickroot" "$tickroot" "$task" "$agent" "$f_rel" "$handoff" "$f_rel" "${csv_rel:+ and: $csv_rel}" "$role_note"
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
    if [[ "${RTL_WT_USED:-0}" == "1" ]]; then
      # GH-13: this turn ran in a throwaway worktree, so the agent CANNOT have moved ROOT's HEAD — a
      # moved ROOT HEAD is therefore a CONCURRENT PEER commit. Never reset it: a blind `reset --hard`
      # here orphaned a peer agent's commit on 2026-06-23 (recovered via reflog). The agent's own writes
      # were already contained by rtl_worktree_end (off-lane → exit 6; else allowlist copyback), so just
      # preserve the peer commit and fall through to allowlist enforcement + a file-scoped commit ON TOP.
      printf '%s-turn: ROOT HEAD moved during a worktree-isolated turn — a concurrent peer committed; preserving it (not resetting), committing this turn on top.\n' "$RTL_TOOL" >&2
    else
      # In-ROOT (direct/attended) turn: the agent ran in ROOT and may have committed off-lane changes.
      # Undo its commit and fail — the documented attended-mode containment. A concurrent PEER commit in
      # this mode is indistinguishable from a self-commit here, so before discarding it we save the
      # current HEAD under refs/relay-orphan/<sha>: the reset abandons it from the branch, but the ref
      # keeps it reachable, so a wrongly-caught peer commit is never lost (recover via
      # `git log refs/relay-orphan/*`). The default DRIVEN path uses worktree isolation (handled above);
      # this is the cheap backstop for the in-ROOT path (GH-13, relay review 2026-06-23 F6).
      git -C "$RTL_ROOT" update-ref "refs/relay-orphan/$(git -C "$RTL_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)" HEAD 2>/dev/null || true
      git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
      printf '%s-turn: %s committed during its turn (forbidden) — reset to %s (prior HEAD saved to refs/relay-orphan/), failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
      exit 6
    fi
  fi
  # (1) allowlist enforcement on tracked-tree changes (.tick is gitignored, so token ops don't show).
  # -z = NUL-delimited RAW unquoted paths (spaces/special chars can't slip the match or break the
  # revert); rename/copy records (R/C) carry a second NUL field — check both old+new. We deliberately
  # do NOT `git clean -Xdf` (it would wipe .tick, the coordination state the turn legitimately writes);
  # ignored-file safety belongs to the agent sandbox, tracked as future.
  RTL_LOG_REL="${log:+${log#"$RTL_ROOT"/}}"
  RTL_VIOLATION=0
  # Pre-existing ambient WIP (same status+path as before the turn) is left untouched, never failed.
  # (Documented minor gap: a file already dirty that the agent edits further to the SAME status code
  # isn't caught — acceptable for review turns.)
  local entry xy path src
  while IFS= read -r -d '' entry; do
    [[ -n "$entry" ]] || continue
    xy="${entry:0:2}"; path="${entry:3}"
    case "$xy" in
      R*|C*)
        IFS= read -r -d '' src || true
        # A rename counts as pre-existing only if BOTH dest and src were dirty before — else enforce
        # both paths. Prevents a staged rename whose dest matches an ambient rename's dest from hiding
        # a clean file's move/deletion via the src field (Gemini review 2026-06-15, rename-hijack).
        if rtl_was_dirty_before "$entry" && rtl_was_dirty_before "$src"; then continue; fi
        rtl_check "$path"; rtl_check "$src"
        ;;
      *)
        rtl_was_dirty_before "$entry" && continue
        rtl_check "$path"
        ;;
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
