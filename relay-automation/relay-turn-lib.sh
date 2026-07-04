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
#   (3b) archive transcript — GH-30 Phase 3 (Model A): when XYZ_ARCHIVE_ROOT redirected the relay file
#                             into a SEPARATE git repo (the archive), rtl_init flags RTL_ARCHIVE_MODE and
#                             rtl_enforce commits the transcript into THAT repo via an isolated `git -C`
#                             step — never RTL_ROOT. Code artifacts + the .tick token stay on RTL_ROOT,
#                             so token-tree and transcript-tree can differ without the (2) reset hazard.
#                             Unset var / same-repo relay file → mode 0, byte-for-byte the paths above.
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

# GH-30 Phase 1 — single transcript-root resolver (the ONLY place the relay-system base is decided).
# Every transcript writer (consult.sh, marathon-drive.sh, relay-drive.sh, swarm-preflight.sh,
# extract-relay-telemetry.sh) is meant to call this instead of hardcoding "$ROOT/relay-system"
# (writer wiring lands in Phase 2). It emits the relay-system BASE dir; callers append their own
# "/<date>/<slug>" tail exactly as they do today.
#
#   rtl_transcript_root <target_root>   # <target_root> = the repo transcripts default under
#
# Contract:
#   - XYZ_ARCHIVE_ROOT unset/empty → "$target_root/relay-system"   (byte-for-byte today's path)
#   - XYZ_ARCHIVE_ROOT set         → "$XYZ_ARCHIVE_ROOT/relay-system/<repo-slug>", namespaced per
#                                    source repo so one central archive holds many repos collision-free.
# Model A (decided 2026-07-02 — separate COMMITTED git archive repo) → when set, XYZ_ARCHIVE_ROOT
# MUST be absolute, exist, AND be a git repo. Any failure is a HARD ERROR (stderr + return 1) — never
# a silent fallback into the foreign tree (the whole point of the setting is to keep transcripts OUT
# of repo B). The commit-into-archive semantics ride on top of this in Phase 3; Phase 1 only resolves
# the path and validates the target.
rtl_transcript_root() {  # <target_root> → prints relay-system base; returns 1 on invalid archive
  # Strip a trailing slash so a caller passing "/repo/" can't yield "/repo//relay-system" (a `//`
  # prefix is implementation-defined under POSIX). Real caller roots are git-rev-parse output with no
  # trailing slash, so this is byte-identical to today's "$ROOT/relay-system" on the common path.
  local target_root="${1%/}"
  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
    printf '%s/relay-system' "$target_root"
    return 0
  fi
  local ar="$XYZ_ARCHIVE_ROOT"
  if [[ "$ar" != /* ]]; then
    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: %s\n' "$ar" >&2
    return 1
  fi
  if [[ ! -d "$ar" ]]; then
    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): %s\n' "$ar" >&2
    return 1
  fi
  # Model A: the archive is a committed git repo. A non-git dir would silently drop transcripts on the
  # floor in Phase 3, so reject it now at the resolver rather than at commit time.
  if ! git -C "$ar" rev-parse --git-dir >/dev/null 2>&1; then
    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): %s\n' "$ar" >&2
    return 1
  fi
  printf '%s/relay-system/%s' "$ar" "$(rtl_repo_slug "$target_root")"
}

# Deterministic per-repo slug for archive namespacing: origin remote basename (…/<name>[.git]),
# else the target dir's basename. Sanitized to a SAFE single path segment: [A-Za-z0-9._-] only, never
# empty, never "."/".." (a path-traversal segment would let a writer escape the relay-system base),
# never leading "-" (option-shaped for a later `cd`/`git -C` consumer). Falls back to "repo".
rtl_repo_slug() {  # <target_root>
  local target_root="$1" url slug
  url="$(git -C "$target_root" remote get-url origin 2>/dev/null || true)"
  while [[ "$url" == */ ]]; do url="${url%/}"; done   # tolerate a trailing-slash remote (…/foo/ or …/foo.git/)
  url="${url%.git}"
  while [[ "$url" == */ ]]; do url="${url%/}"; done
  if [[ -n "$url" ]]; then
    slug="${url##*/}"; slug="${slug##*:}"   # strip path AND scp-style host: prefix
  fi
  [[ -z "${slug:-}" ]] && slug="$(basename -- "$target_root" 2>/dev/null || true)"
  slug="$(printf '%s' "${slug:-repo}" | tr -c 'A-Za-z0-9._-' '_')"
  while [[ "$slug" == -* ]]; do slug="${slug#-}"; done   # never option-shaped
  case "$slug" in ''|.|..) slug="repo" ;; esac           # never empty or a path-traversal segment
  printf '%s' "$slug"
}

rtl_init() {  # <root> <relay_file> <allow_csv>
  # ROOT routing (GH-11): a foreign --target-root (exported by relay-drive as RELAY_TARGET_ROOT)
  # routes the WHOLE turn — worktree base, allowlist copyback, file-scoped commit, enforce — from this
  # one anchor. Unset/empty → the caller's <root> (today's behavior, byte-for-byte). Coordination
  # (.tick) stays where TICK_REPO_ROOT points (the harness clone); only the ARTIFACT side moves.
  RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"; local f="$2" csv="$3"
  # GH-51 [1-kernel]: a SAME-REPO --target-root (notably `--target-root .`) left RTL_ROOT relative or
  # redundant, so the repo-root-relative strip below (`${a#"$RTL_ROOT"/}`) could not remove an ABSOLUTE
  # relay-file prefix — the relay file then failed the off-lane match and a legitimate same-repo turn
  # was reverted (exit 6; the GH-37 marathon needed --target-root DROPPED to converge). When the target
  # root resolves to the SAME git repo as the caller's own root, collapse so containment is
  # byte-identical to the no-target-root path (a same-repo --target-root is a NO-OP). WHICH root string
  # to collapse to matters: prefer the caller's own root ($1) when $1 IS the repo root, because $1 is
  # the exact path form the rest of the turn uses (symlink-consistent — git rev-parse returns the
  # PHYSICAL path, e.g. /private/var, while $1/the relay file may be the /var form; GH-51). But a GH-49
  # vendored .xyz/ copy is a SUBDIR of the foreign repo, so its caller root ($1 = …/.xyz) is NOT the
  # repo root — collapsing to $1 would root containment at .xyz/ and the foreign repo's own relay file
  # would fail its off-lane match. Detect that (physical $1 != physical toplevel) and use the toplevel.
  # Genuine foreign roots (a different toplevel) are untouched — the cross-repo path is unchanged.
  if [[ -n "${RELAY_TARGET_ROOT:-}" ]]; then
    local _tt _ct _c1; _tt="$(git -C "$RTL_ROOT" rev-parse --show-toplevel 2>/dev/null)"
    _ct="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"
    _c1="$(cd "$1" 2>/dev/null && pwd -P)"
    if [[ -n "$_tt" && "$_tt" == "$_ct" ]]; then
      if [[ "$_c1" == "$_ct" ]]; then RTL_ROOT="$1"; else RTL_ROOT="$_tt"; fi
    fi
  fi
  # macOS/APFS (and any case-insensitive fs) reports git-status paths in the case the INDEX tracks
  # (e.g. RELAY-SYSTEM/…), which can differ from the lowercase invocation arg the allowlist holds
  # (relay-system/…). Detect it ONCE here so rtl_in_allow can compare case-insensitively on such
  # filesystems (GH-17) — otherwise a reviewer's legit append to its own relay file is seen as
  # off-allowlist and reverted with exit 6. Case-sensitive repos (Linux CI) keep a byte-for-byte
  # exact compare. Non-repo / unset → false (the safe, case-sensitive default).
  RTL_IGNORECASE="$(git -C "$RTL_ROOT" config --get core.ignorecase 2>/dev/null || echo false)"
  [[ "$RTL_IGNORECASE" == "true" ]] || RTL_IGNORECASE=false
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
  # GH-30 Phase 3 (Model A): the relay file may live in a SEPARATE git repo (the ARCHIVE) when
  # XYZ_ARCHIVE_ROOT redirected the transcript out of RTL_ROOT. Detect that here so rtl_enforce
  # commits the transcript INTO the archive repo (never RTL_ROOT), while the code artifacts AND the
  # .tick token stay anchored on RTL_ROOT. An out-of-root relay file survived the `${a#"$RTL_ROOT"/}`
  # strip above as an ABSOLUTE path (leading '/'), so it is already inert to the RTL_ROOT status/commit
  # loop (git-status there never lists it) and to the worktree machinery (which skips absolute entries);
  # this block just records WHICH repo to commit it into and its path within that repo. Default — relay
  # file under RTL_ROOT, or archive == target (a same-repo redirect) — leaves RTL_ARCHIVE_MODE=0, so
  # every existing path is byte-for-byte unchanged. Non-git RTL_ROOT / non-git relay dir → mode 0 too.
  RTL_ARCHIVE_MODE=0; RTL_RELAY_REPO=""; RTL_RELAY_ARCHIVE_REL=""
  local _fdir _frepo _rroot_top _fabs
  _fdir="$(cd "$(dirname "$f")" 2>/dev/null && pwd -P || true)"
  if [[ -n "$_fdir" ]]; then
    _frepo="$(git -C "$_fdir" rev-parse --show-toplevel 2>/dev/null || true)"
    _rroot_top="$(git -C "$RTL_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$_frepo" && -n "$_rroot_top" && "$_frepo" != "$_rroot_top" ]]; then
      RTL_ARCHIVE_MODE=1
      RTL_RELAY_REPO="$_frepo"
      _fabs="$_fdir/$(basename "$f")"
      RTL_RELAY_ARCHIVE_REL="${_fabs#"$_frepo"/}"
    fi
  fi
  # GH-31 / #15: optional READ-ONLY artifact under review (a cross-repo or uncommitted PR/diff).
  # RELAY_ARTIFACT_FILE is an ABSOLUTE path to the source (relay-drive absolutizes it). It is seeded
  # read-only into the worktree by rtl_worktree_begin at .relay-artifacts/<basename> — NOT added to
  # RTL_ALLOW, so it is never copied back to RTL_ROOT (no leak). The reviewer may READ it; an edit
  # changes its signature and fails the turn (strict read-only). Empty/unset → no artifact (default).
  RTL_ARTIFACT="${RELAY_ARTIFACT_FILE:-}"
  RTL_ARTIFACT_REL=""
  # NB: a trailing `[[ -n .. ]] && assign` would make rtl_init RETURN the test's status (1 when no
  # artifact), and a `set -e` caller (the turn shims) would abort the turn. Use an if-block → returns 0.
  if [[ -n "$RTL_ARTIFACT" ]]; then
    RTL_ARTIFACT_REL=".relay-artifacts/$(basename "$RTL_ARTIFACT")"
  fi
}

rtl_in_allow() {  # <path> — is <path> on the allowlist? Case-insensitive when RTL_IGNORECASE=true (GH-17).
  local x="$1" a
  # GH-59: git collapses an all-untracked new dir to `dir/` in porcelain output. Treat that as
  # allowlisted ONLY when it is a TRUE ancestor of a concrete allowlisted file entry (e.g.
  # greenfield/ -> greenfield/output.txt). This generalizes the old .relay-artifacts dir exemption
  # without widening to bare prefixes such as `green/` for `greenfield/output.txt`.
  if [[ "$x" == */ ]]; then
    local dir="${x%/}"
    if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
      local dl al; dl="$(printf '%s' "$dir/" | tr '[:upper:]' '[:lower:]')"
      for a in "${RTL_ALLOW[@]}"; do
        al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
        [[ "$al" == "$dl"* && "$al" != "$dl" ]] && return 0
      done
    else
      for a in "${RTL_ALLOW[@]}"; do [[ "$a" == "$dir/"* && "$a" != "$dir/" ]] && return 0; done
    fi
  fi
  if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
    # `tr` not bash-4 `${x,,}`: stock macOS bash is 3.2 (this lib is deliberately BSD/macOS-portable).
    local xl al; xl="$(printf '%s' "$x" | tr '[:upper:]' '[:lower:]')"
    for a in "${RTL_ALLOW[@]}"; do
      al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
      [[ "$xl" == "$al" ]] && return 0
    done
    return 1
  fi
  for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done
  return 1
}

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
#   - Cross-repo / uncommitted artifact: the worktree is a checkout of RTL_ROOT@HEAD and seeds only
#     allowlisted paths UNDER RTL_ROOT (below). An artifact in ANOTHER repo, or a brand-new uncommitted
#     one, is neither at HEAD nor on the writable allowlist, so it would be invisible to an isolated turn.
#     FIX (GH-31 / closes #15): set RELAY_ARTIFACT_FILE (relay-drive `--artifact-file`) to seed it as a
#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
#     allowlist. The reviewer may READ it; an edit changes its signature and fails the turn (strict-fail);
#     it is never copied back to RTL_ROOT (no leak). See rtl_init (RTL_ARTIFACT) + the seed/exempt logic
#     in rtl_worktree_begin/end. (Embedding inline still works for callers who prefer it.)
_rtl_sig() {  # <path> — content signature of a file/dir, or "ABSENT". Used to detect what the turn
  # actually changed IN THE WORKTREE, so rtl_worktree_end copies back ONLY worktree-modified paths and
  # never clobbers a ROOT-direct edit with a stale seed (GH-22). git is already required by this lib.
  local p="$1"
  if [[ -f "$p" ]]; then
    git hash-object -- "$p" 2>/dev/null || echo "ERR:$p"
  elif [[ -d "$p" ]]; then
    # Stable per-dir signature: hash each tracked-or-untracked file's content in sorted order.
    ( cd "$p" 2>/dev/null && find . -type f -print0 2>/dev/null | LC_ALL=C sort -z \
        | xargs -0 git hash-object 2>/dev/null ) | git hash-object --stdin 2>/dev/null || echo "ERR:$p"
  else
    echo "ABSENT"
  fi
}

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
    # GH-30 Phase 3: an ABSOLUTE allowlist entry is the archive relay file — it lives in a DIFFERENT
    # repo, not this RTL_ROOT worktree. Skip it: the agent edits it at its real location and rtl_enforce
    # commits it to the archive. (Keeps seedsig index aligned with the copyback loop, which skips it too.)
    [[ "$a" == /* ]] && continue
    if [[ -e "$RTL_ROOT/$a" ]]; then
      mkdir -p "$wt/$(dirname "$a")"
      cp -R "$RTL_ROOT/$a" "$wt/$a"
    else
      rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
                                       # deletion, else the HEAD checkout would resurrect it on copy-back
    fi                                 # (Codex review r2, 2026-06-20 — symmetric to the in-turn delete)
  done
  # GH-22: snapshot each seeded allowlist path's signature so rtl_worktree_end copies back ONLY paths
  # the turn modified in the worktree — an agent that wrote ROOT directly (real agy resolves the relay
  # file to its absolute ROOT path even with CWD=worktree) must not be overwritten by the stale seed.
  # Persist to a sidecar file (NOT inside the worktree — that would read as an off-lane untracked file)
  # because the caller invokes this via wt="$(rtl_worktree_begin)", a subshell whose globals are lost;
  # rtl_worktree_end re-reads the sidecar by the worktree path it is handed. One line per RTL_ALLOW entry.
  : >"${wt}.seedsig"
  for a in "${RTL_ALLOW[@]}"; do [[ "$a" == /* ]] && continue; _rtl_sig "$wt/$a" >>"${wt}.seedsig"; done
  # GH-31 / #15: seed the read-only artifact under review so an ISOLATED reviewer can READ it (it is
  # neither at HEAD nor on the writable allowlist). Snapshot the .relay-artifacts dir signature to a
  # sidecar so rtl_worktree_end can exempt it from off-lane detection ONLY while unchanged — a reviewer
  # edit changes the signature and trips off-lane (strict read-only). NOT in RTL_ALLOW ⇒ never copied back.
  if [[ -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
    mkdir -p "$wt/.relay-artifacts"
    cp "$RTL_ARTIFACT" "$wt/$RTL_ARTIFACT_REL"
    _rtl_sig "$wt/.relay-artifacts" >"${wt}.artifactsig"
  fi
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
  # GH-13/#14: rtl_worktree_begin runs in a `wt="$(...)"` subshell, so the RTL_WT_USED=1 it sets there
  # is LOST before rtl_enforce runs — which left the "a moved ROOT HEAD is a concurrent PEER commit;
  # preserve it, don't reset" branch in rtl_enforce as DEAD CODE for the command-substitution shims
  # (codex/agy). Every moved ROOT HEAD then wrongly hit the in-ROOT reset+exit-6 path, discarding a
  # worktree builder's whole turn (the 2026-06-29 codex marathon, #14). This function runs in the
  # caller's shell and is always reached before rtl_enforce for a worktree turn, so re-assert the flag
  # here to restore the GH-13 protection. (The agent ran CWD=worktree, so its OWN commits can't reach
  # ROOT; a moved ROOT HEAD is genuinely a peer/harness commit. Off-lane worktree content is already
  # contained below before rtl_enforce sees it.)
  RTL_WT_USED=1
  while IFS= read -r -d '' entry; do
    [[ -n "$entry" ]] || continue
    xy="${entry:0:2}"; path="${entry:3}"
    case "$xy" in R*|C*) IFS= read -r -d '' _ || true ;; esac   # rename/copy: consume 2nd NUL field
    case "$path" in .tick/*|.tick) continue ;; esac
    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
    # not silently discarded). git collapses an all-untracked dir to ".relay-artifacts/", so match both.
    case "$path" in
      .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
        if [[ -f "${wt}.artifactsig" ]] && [[ "$(_rtl_sig "$wt/.relay-artifacts")" == "$(cat "${wt}.artifactsig")" ]]; then
          continue
        fi
        RTL_WT_OFFLANE=1; continue ;;
    esac
    rtl_in_allow "$path" && continue
    RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
  done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
  if ((RTL_WT_OFFLANE == 0)); then
    local i=0 seedsig nowsig _ln; local _seeds=()
    # Re-read the seed signatures written by rtl_worktree_begin (one line per RTL_ALLOW entry).
    if [[ -f "${wt}.seedsig" ]]; then
      while IFS= read -r _ln; do _seeds+=("$_ln"); done <"${wt}.seedsig"
    fi
    for a in "${RTL_ALLOW[@]}"; do
      # GH-30 Phase 3: skip the absolute archive relay-file entry — never seeded here (committed to the
      # archive by rtl_enforce). Skipped in lockstep with the begin seedsig loop, so `i` stays aligned.
      [[ "$a" == /* ]] && continue
      # GH-22: copy back ONLY paths the turn changed IN THE WORKTREE. If the worktree path is identical
      # to what was seeded, the turn did not touch it here — leave RTL_ROOT alone so a ROOT-direct edit
      # (agy writing the absolute ROOT path) survives for rtl_enforce to commit, instead of being
      # overwritten by the stale seed. No recorded seed signature → copy as before (safe fallback).
      seedsig="${_seeds[i]-}"; i=$((i+1))
      nowsig="$(_rtl_sig "$wt/$a")"
      [[ -n "$seedsig" && "$nowsig" == "$seedsig" ]] && continue
      if [[ -e "$wt/$a" ]]; then
        mkdir -p "$RTL_ROOT/$(dirname "$a")"
        cp -R "$wt/$a" "$RTL_ROOT/$a"
      elif [[ -e "$RTL_ROOT/$a" ]]; then
        rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
      fi
    done
  fi
  rm -f "${wt}.seedsig" "${wt}.artifactsig"   # GH-22 + GH-31: clean up the sidecar signature files
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
  # GH-31 / #15: point the reviewer at the seeded read-only artifact (worktree-relative; it is NOT a
  # writable edit target — an edit fails the turn).
  local art_note=""
  [[ -n "${RTL_ARTIFACT_REL:-}" ]] && art_note=" The artifact under review is at ${RTL_ARTIFACT_REL} — READ it for your review, but do NOT edit it (any edit fails your turn)."
  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. For the %s token ALWAYS use the absolute, env-pinned tick — a bare or ./bin/tick from a worktree/foreign CWD silently no-ops and DEADLOCKS the relay: TICK_REPO_ROOT="%s" "%s/bin/tick". Token sequence: (1) claim it FIRST — claim %s --agent %s --paths %s — the --paths flag is MANDATORY; without it the claim silently fails (prints usage) and your later release errors "task ... is open". (2) ping is optional. (3) when finished, %s (or done + set STATUS: Approved when approving). Edit ONLY %s%s.%s%s NEVER run git yourself — no add/commit/push/reset; a self-commit FAILS your whole turn. Do NOT touch any other file. The harness makes the one file-scoped commit for you after you hand off the token. Do NOT run the full project test/gate suite (e.g. validate.sh) yourself — running it can create files that trip containment and DISCARD your whole turn; verify ONLY with the specific test for the file(s) you changed. The harness runs the gate after your turn.' \
    "$agent" "$f_rel" "$task" "$tickroot" "$tickroot" "$task" "$agent" "$f_rel" "$handoff" "$f_rel" "${csv_rel:+ and: $csv_rel}" "$role_note" "$art_note"
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
  # Stage each allowlisted path INDEPENDENTLY (not one batched `git add -- a b c`): a single pathspec
  # that matches nothing — e.g. an allowlist entry the turn was permitted to create but didn't — makes
  # a batched `git add` abort and stage NOTHING, dropping even the paths that DID change. That is the
  # GH-29 cross-repo new-file gap: a builder that ADDS files under --target-root reported "no tracked
  # changes" and never committed, because a sibling non-matching entry aborted the batch (the modified
  # registry files were left `M` too — proof it was a whole-batch abort, not a new-file-only miss).
  # `-A` per path stages additions, modifications, AND deletions; `|| true` tolerates a non-matching
  # entry so the rest still stage. New untracked allowlisted files are added (they already passed the
  # exact-match enforcement above, so they ARE on-lane).
  local _ap
  for _ap in "${RTL_ALLOW[@]}"; do
    git -C "$RTL_ROOT" add -A -- "$_ap" 2>/dev/null || true
  done
  if git -C "$RTL_ROOT" diff --cached --quiet; then
    printf '%s-turn: %s turn produced no tracked changes (token-only move?)\n' "$RTL_TOOL" "$agent"
  else
    git -C "$RTL_ROOT" commit -q -m "relay(${task}): ${agent} turn (${RTL_TOOL} headless; no push)"
    printf '%s-turn: committed %s turn (file-scoped, no push)\n' "$RTL_TOOL" "$agent"
  fi
  # (3b) GH-30 Phase 3 (Model A): commit the TRANSCRIPT (relay file) into the SEPARATE archive repo,
  # never RTL_ROOT. This is an ISOLATED `git -C "$RTL_RELAY_REPO"` step — it CANNOT move RTL_ROOT's HEAD,
  # so it can never orphan a concurrent peer commit in the target tree (the GH-13 hazard is guarded at
  # the top of this function on RTL_ROOT only, and holds even when token-tree ≠ transcript-tree). The
  # .tick token handoff (step 4 below) stays anchored to TICK_REPO_ROOT — the target/harness clone —
  # so token and transcript may live in different trees safely. A pathspec commit isolates it to the
  # relay file alone (other repos' transcripts already sitting in the archive are untouched). Best
  # effort: a failed archive commit WARNs (the transcript file is still on disk) and NEVER fails the
  # turn — the file-scoped code commit already stood, and this transcript is a record, not the gate.
  if [[ "${RTL_ARCHIVE_MODE:-0}" == "1" && -n "${RTL_RELAY_REPO:-}" && -n "${RTL_RELAY_ARCHIVE_REL:-}" ]]; then
    git -C "$RTL_RELAY_REPO" add -- "$RTL_RELAY_ARCHIVE_REL" 2>/dev/null || true
    if git -C "$RTL_RELAY_REPO" diff --cached --quiet -- "$RTL_RELAY_ARCHIVE_REL" 2>/dev/null; then
      printf '%s-turn: archive transcript unchanged — nothing to commit to %s\n' "$RTL_TOOL" "$RTL_RELAY_REPO"
    elif git -C "$RTL_RELAY_REPO" commit -q \
           -m "relay(${task}): ${agent} transcript (${RTL_TOOL} headless; archive; no push)" \
           -- "$RTL_RELAY_ARCHIVE_REL" 2>/dev/null; then
      printf '%s-turn: committed transcript to archive %s (%s; no push)\n' "$RTL_TOOL" "$RTL_RELAY_REPO" "$RTL_RELAY_ARCHIVE_REL"
    else
      printf '%s-turn: WARN could not commit transcript to archive %s (%s) — file written but uncommitted; check the archive repo git identity\n' "$RTL_TOOL" "$RTL_RELAY_REPO" "$RTL_RELAY_ARCHIVE_REL" >&2
    fi
  fi
  # (4) authoritative token handoff (GH-67). The turn prompt asks the worker to release/done the
  # token itself, but headless workers frequently DON'T — both codex (stall) and agy (Approved) turns
  # were observed leaving the token `open` with no handoff, which DEADLOCKS the relay (manual
  # `tick log task.done` was the only recovery). Close or hand off deterministically here, from the
  # harness, after the file-scoped commit. Design (GH-67 Option A): inspect the relay file STATUS —
  # Approved|Closed → `tick done`, else → `tick release --to <RELAY_PEER>`.
  #   - Idempotent: a token already `done`/`circuit_broken`, or already `open`+handed-to-peer (the
  #     worker DID release), is left untouched — no duplicate event.
  #   - Ownership-guarded by tick itself: release/done throw unless `agent` is the current claimer, so
  #     a token this agent never claimed yields a WARN, never a turn failure (the commit already stood).
  #   - CWD-independent: absolute env-pinned tick (TICK_REPO_ROOT + $tickroot/bin/tick), exactly as the
  #     turn prompt mandates; the relay file lives in the HARNESS clone (tickroot), not RELAY_TARGET_ROOT.
  local _relay_file="${RELAY_FILE:-}" _peer="${RELAY_PEER:-}"
  local _tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}" _tickbin
  _tickbin="$_tickroot/bin/tick"
  [[ "$_relay_file" != /* && -n "$_relay_file" && ! -f "$_relay_file" && -f "$_tickroot/$_relay_file" ]] \
    && _relay_file="$_tickroot/$_relay_file"
  if [[ -n "$task" && -n "$_relay_file" && -x "$_tickbin" ]]; then
    local _info _tstatus _thandoff _rstatus
    _info="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$task" 2>/dev/null || true)"
    _tstatus="$(printf '%s\n' "$_info"  | sed -n 's/^status:[[:space:]]*//p'     | head -n1)"
    _thandoff="$(printf '%s\n' "$_info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
    # Same bold-markdown-tolerant STATUS read poll.sh uses (real threads write `**STATUS:** Approved`).
    _rstatus="$(sed -n 's/^[*]*STATUS[*]*:[*]*[[:space:]]*//p' "$_relay_file" 2>/dev/null | head -n1 | sed 's/[[:space:]]*$//')"
    if [[ "$_tstatus" == "done" || "$_tstatus" == "circuit_broken" ]]; then
      : # worker (or a prior step) already closed the token — nothing to hand off
    elif [[ "$_rstatus" == "Approved" || "$_rstatus" == "Closed" ]]; then
      if TICK_REPO_ROOT="$_tickroot" "$_tickbin" done "$task" --agent "$agent" >/dev/null 2>&1; then
        printf '%s-turn: relay STATUS=%s → closed token (tick done %s)\n' "$RTL_TOOL" "$_rstatus" "$task"
      else
        printf '%s-turn: WARN could not `tick done %s` as %s (not current owner?) — inspect `tick info %s`\n' "$RTL_TOOL" "$task" "$agent" "$task" >&2
      fi
    elif [[ "$_tstatus" == "open" && -n "$_peer" && "$_thandoff" == "$_peer" ]]; then
      : # worker already handed the token to the peer — nothing to do
    elif [[ -n "$_peer" ]]; then
      if TICK_REPO_ROOT="$_tickroot" "$_tickbin" release "$task" --agent "$agent" --to "$_peer" >/dev/null 2>&1; then
        printf '%s-turn: handed off token %s → %s (tick release --to)\n' "$RTL_TOOL" "$task" "$_peer"
      else
        printf '%s-turn: WARN could not `tick release %s --to %s` as %s (not current owner?) — inspect `tick info %s`\n' "$RTL_TOOL" "$task" "$_peer" "$agent" "$task" >&2
      fi
    else
      printf '%s-turn: WARN relay STATUS not terminal and no RELAY_PEER set — token %s left as-is (set RELAY_PEER for auto-handoff)\n' "$RTL_TOOL" "$task" >&2
    fi
  fi
  # (5) GH-68: cross-agent dependency-drift signal (warn-only, additive, non-blocking). If this turn's
  # commit changed a shared surface — the containment kernel (relay-turn-lib.sh), the projection API
  # (src/project.js), or the event-verb schema (src/events.js) — emit a `dependency.drift` event so
  # the NEXT agent's shim can inject a heads-up into its turn brief. Best-effort: a failed emit never
  # fails the turn; the no-surface-change path emits nothing and is byte-identical to before.
  # Contract: decisions/2026-07-01-cross-agent-dep-conflict.md.
  if [[ -n "$task" && -x "$_tickbin" && -n "${RTL_BEFORE_HEAD:-}" ]]; then
    local _newhead
    _newhead="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
    if [[ "$_newhead" != none && "$_newhead" != "$RTL_BEFORE_HEAD" ]]; then
      local _surf _psha _csha _dl
      for _surf in relay-automation/relay-turn-lib.sh src/project.js src/events.js; do
        _psha="$(git -C "$RTL_ROOT" rev-parse "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
        _csha="$(git -C "$RTL_ROOT" rev-parse "$_newhead:$_surf" 2>/dev/null || true)"
        [[ "$_psha" == "$_csha" ]] && continue   # unchanged (or absent at both revs) — no drift
        _dl="$(git -C "$RTL_ROOT" diff --numstat "$RTL_BEFORE_HEAD" "$_newhead" -- "$_surf" 2>/dev/null \
                | awk '{a+=$1+0; d+=$2+0} END{print a+d+0}')"
        if TICK_REPO_ROOT="$_tickroot" "$_tickbin" drift "$_surf" \
             --agent "$agent" --task "$task" \
             --prior-sha "${_psha:-none}" --current-sha "${_csha:-none}" \
             --diff-lines "${_dl:-0}" >/dev/null 2>&1; then
          printf '%s-turn: dependency.drift — %s changed %s (%s lines); signalled for the next turn\n' "$RTL_TOOL" "$agent" "$_surf" "${_dl:-0}"
        fi
      done
    fi
  fi
}

# GH-68 warn-only: build a heads-up block of UNREAD cross-agent dependency-drift events for <agent>,
# for a shim to PREPEND to its turn brief. The watermark is per-agent under .tick (coordination state,
# per-device, gitignored): only drift events NEWER than the watermark and NOT authored by <agent> are
# surfaced; the watermark then advances past everything scanned. Idempotent — a crash before the
# advance just re-injects the same notice next turn, which is harmless. Capped at the 5 most recent
# (older ones summarized as a count). Echoes NOTHING when there is no unread drift, so the default
# turn-prompt path is unchanged. See decisions/2026-07-01-cross-agent-dep-conflict.md §4–5.
rtl_drift_brief() {  # <agent> <tickroot>
  local me="$1" tickroot="$2"
  [[ -n "$me" && -n "$tickroot" ]] || return 0
  local evdir="$tickroot/.tick/events"
  [[ -d "$evdir" ]] || return 0
  local seg; seg="$(printf '%s' "$me" | tr -c 'A-Za-z0-9._-' '_')"
  local wmfile="$tickroot/.tick/dep-drift-watermark-$seg"
  local wm=""; [[ -f "$wmfile" ]] && wm="$(head -n1 "$wmfile" 2>/dev/null || true)"
  local f base newest="$wm"
  local -a unread=()
  # drift event filenames embed the action token 'dependency.drift' (appendEvent naming); the ISO-ts
  # prefix makes lexicographic order == chronological (LC_ALL=C for a stable ASCII sort).
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    base="$(basename "$f")"
    if [[ -n "$wm" ]] && ! [[ "$base" > "$wm" ]]; then continue; fi   # already processed (<= watermark)
    [[ "$base" > "$newest" ]] && newest="$base"
    grep -Fq "\"agent\":\"$me\"" "$f" 2>/dev/null && continue          # skip the agent's OWN changes
    unread+=("$f")
  done < <(LC_ALL=C ls -1 "$evdir"/*dependency.drift*.jsonl 2>/dev/null | LC_ALL=C sort)
  [[ -n "$newest" ]] && printf '%s\n' "$newest" > "$wmfile" 2>/dev/null || true
  local n=${#unread[@]}
  ((n)) || return 0
  local start=0; ((n>5)) && start=$((n-5))
  printf '\n[cross-agent dependency drift — informational, warn-only; re-check if your task depends on these]\n'
  local i surf dl ag
  for ((i=start;i<n;i++)); do
    surf="$(sed -n 's/.*"surface":"\([^"]*\)".*/\1/p' "${unread[$i]}" | head -n1)"
    dl="$(sed -n 's/.*"diff_lines":\([0-9]*\).*/\1/p' "${unread[$i]}" | head -n1)"
    ag="$(sed -n 's/.*"agent":"\([^"]*\)".*/\1/p' "${unread[$i]}" | head -n1)"
    printf -- '- %s changed %s (%s lines) since your last turn.\n' "${ag:-a peer}" "${surf:-?}" "${dl:-?}"
  done
  ((n>5)) && printf -- '+%d earlier drift event(s) omitted — see .tick/events/ for full history.\n' "$((n-5))"
  return 0
}
