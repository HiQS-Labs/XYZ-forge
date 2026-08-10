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
# GH-161 observability (see PROJECT/1-INBOX/GH-161-HARNESS-OBSERVABILITY.md for the survey behind
# this): instrumentation writes into the turn's own transcript, never a separate log file.
#   rtl_trace       <message...>       — NEW fine-grained decision-point line. Opt-in: fires only when
#                                        RTL_TRACE=1 AND RTL_LOG is set (the routine/successful path is
#                                        silent by default, to avoid noise on every turn forever).
#   rtl_log_always  <message...>       — routes an EXISTING unconditional diagnostic (one already
#                                        printed to stderr elsewhere in this file) into RTL_LOG too.
#                                        Requires only RTL_LOG to be set — no new gating.
#   rtl_default_log <root> <tool> <task> — persistent default transcript path (reuses
#                                        rtl_transcript_root; falls back to the historical PID-keyed
#                                        tmp path on any resolver/mkdir failure). The shim exports
#                                        RTL_LOG to this same path before calling rtl_init, so
#                                        rtl_trace/rtl_log_always land in the file a human already
#                                        opens to debug a turn.
#
# rtl_enforce deliberately `exit 6`s the calling shell on any violation — that fails the turn.
# rtl_run_bounded returns 7 on timeout; the CALLER must decide whether to continue to rtl_enforce
# (it should — a killed agent may have left off-lane changes) and then exit 7 after enforcement.
# Exit-code priority: containment violation (6) takes precedence over timeout (7). Rationale: a
# containment violation means unsafe state was left in the repo; that signal is more critical to
# surface than the mechanism (timeout) that caused the agent to be killed. A shim that detects a
# timeout should still call rtl_enforce, and if rtl_enforce exits 6 the process exits 6 — correct.
# If rtl_enforce completes without violation the shim then exits 7 to report the timeout.

rtl_is_reviewer_turn() {  # <relay_file> [agent] — true if THIS turn is the Reviewer's
  # GH-397: two value domains have always competed in the NEXT: header. A /relay thread writes a ROLE
  # (Producer|Reviewer); marathon-drive writes an AGENT ID (claude|codex|agy). The role test below can
  # never match the latter, so on EVERY marathon reviewer turn this returned false and the reviewer
  # received the BUILDER's "you may edit the artifact" prompt plus the full ALLOW_PATHS allowlist —
  # the exact scope the 2026-06-20 agy over-reach crossed (see the rtl_init comment below).
  #
  # The tempting fix — instruct the acting model to rewrite NEXT: itself — is not safe here.
  # test/agy-turn.sh (S2) locks in today's honest behavior: an agent that skips the flip is caught by
  # NOTHING (rtl_enforce guards the allowlist and the commit boundary, not block content). Hanging a
  # containment boundary on that honor system fails OPEN: one forgotten flip silently hands the
  # reviewer write authority over the artifact it is reviewing.
  #
  # So derive the role instead of trusting an assertion. marathon-drive renders a machine-readable
  # role directive into the relay file, and relay-drive exports RELAY_AGENT from the TICK TOKEN —
  # authoritative turn state, not prose. When BOTH are present the answer is computed and no agent can
  # get it wrong. Everything else — a plain /relay thread, a hand-run turn, a marathon relay rendered
  # before the directive existed — falls through to the historical NEXT:-header test below, unchanged.
  local f="$1" agent="${2:-${RELAY_AGENT:-}}" line directive builder reviewer
  [[ -f "$f" ]] || return 1
  if [[ -n "$agent" ]]; then
    directive="$(grep -E '^[[:space:]]*<!--[[:space:]]*marathon-drive:' "$f" 2>/dev/null | head -1)"
    if [[ -n "$directive" ]]; then
      builder="$(printf '%s' "$directive"  | sed -n 's/.*[[:space:]]builder=\([^[:space:]>]*\).*/\1/p')"
      reviewer="$(printf '%s' "$directive" | sed -n 's/.*[[:space:]]reviewer=\([^[:space:]>]*\).*/\1/p')"
      # Same agent on both sides carries no role signal (a self-review lane) — fall through rather
      # than guess. Only an unambiguous builder≠reviewer pair is allowed to decide the boundary.
      if [[ -n "$builder" && -n "$reviewer" && "$builder" != "$reviewer" ]]; then
        [[ "$agent" == "$reviewer" ]] && return 0
        [[ "$agent" == "$builder"  ]] && return 1
      fi
    fi
  fi
  # The relay protocol's NEXT pointer (the FIRST `NEXT:` line — the header) names the ROLE that acts
  # next (Producer | Reviewer). A reviewer only appends findings to the relay file; it must never edit
  # the artifact. Match the header line only, so a body/instruction mention of "NEXT: Reviewer" can't
  # false-trigger. Portable (no GNU \b): BSD/macOS grep -E + POSIX classes. Missing/None → not reviewer.
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

# GH-161: minimal decision-point tracing, written into the turn's own transcript (CODEX_LOG/AGY_LOG,
# via RTL_LOG — exported by the shim before rtl_init runs) instead of a new log file. See
# PROJECT/1-INBOX/GH-161-HARNESS-OBSERVABILITY.md for the survey/decisions this implements.
rtl_trace() {  # <message...> — see the API note above rtl_init; opt-in fine-grained trace line
  [[ "${RTL_TRACE:-0}" == "1" && -n "${RTL_LOG:-}" ]] || return 0
  # 2>/dev/null listed BEFORE the >>"$RTL_LOG" append target: bash opens redirects left-to-right, so
  # an append-target open failure (e.g. an unwritable/missing dir) reports to the ALREADY-redirected
  # fd 2, keeping this silent-on-failure per the "logging must never fail a turn" contract.
  printf '[trace] %s\n' "$*" 2>/dev/null >>"$RTL_LOG" || true
}

rtl_log_always() {  # <message...> — see the API note above rtl_init; mirrors an existing stderr printf
  [[ -n "${RTL_LOG:-}" ]] || return 0
  printf '[trace] %s\n' "$*" 2>/dev/null >>"$RTL_LOG" || true
}

# Persistent default transcript path, reusing rtl_transcript_root so no new path-resolution logic is
# introduced. IMPORTANT: the resolved directory ("$root/relay-system/logs" on the common path) MUST
# stay gitignored (see .gitignore's "relay-system/logs/" entry) — rtl_check already removes any file
# that lands in the tracked tree matching RTL_LOG_REL ("the shim's own transcript log ... is not an
# agent edit"), so an UN-ignored path here would be silently deleted at the end of every single turn,
# defeating the entire point of "persistent." Falls back to today's PID-keyed tmp path (byte-identical
# to the pre-GH-161 default) on any resolver or mkdir failure — logging must never fail a turn.
rtl_default_log() {  # <root> <tool-turn-name> <task> — e.g. rtl_default_log "$ROOT" codex-turn "$t"
  local root="$1" tool="$2" task="$3" base tslug day path
  base="$(rtl_transcript_root "$root" 2>/dev/null)" || { printf '%s/%s-%s.log' "${TMPDIR:-/tmp}" "$tool" "$$"; return 0; }
  tslug="$(printf '%s' "$task" | tr -c 'A-Za-z0-9._-' '_')"
  day="$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
  path="$base/logs/$day/${tool}-${tslug}-$$.log"
  if mkdir -p "$(dirname "$path")" 2>/dev/null; then
    printf '%s' "$path"
  else
    printf '%s/%s-%s.log' "${TMPDIR:-/tmp}" "$tool" "$$"
  fi
}

rtl_tick_bin() {  # [<tick_repo_root>] → absolute tick executable path
  local tickroot="${1:-${TICK_REPO_ROOT:-${RTL_ROOT:-}}}"
  [[ -n "${TICK_BIN:-}" ]] && { printf '%s' "$TICK_BIN"; return 0; }
  [[ -n "$tickroot" && -x "$tickroot/bin/tick" ]] && { printf '%s/bin/tick' "$tickroot"; return 0; }
  local _rtl_here _rtl_harness
  _rtl_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  _rtl_harness="$(cd "$_rtl_here/.." && pwd)"
  printf '%s/bin/tick' "$_rtl_harness"
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
  local _gh51_collapsed=0 _gh160_collapsed=0
  if [[ -n "${RELAY_TARGET_ROOT:-}" ]]; then
    local _tt _ct _c1; _tt="$(git -C "$RTL_ROOT" rev-parse --show-toplevel 2>/dev/null)"
    _ct="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"
    _c1="$(cd "$1" 2>/dev/null && pwd -P)"
    if [[ -n "$_tt" && "$_tt" == "$_ct" ]]; then
      _gh51_collapsed=1
      if [[ "$_c1" == "$_ct" ]]; then RTL_ROOT="$1"; else RTL_ROOT="$_tt"; fi
    fi
  fi
  # GH-160: a VENDORED .xyz/ install's own $1 (codex-turn.sh/agy-turn.sh's default ROOT, used
  # whenever marathon-drive/relay-drive don't export CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do)
  # is the .xyz/ SUBDIR itself, not the repo it's vendored into — even with NO --target-root at all
  # (the GH-51 block above only runs when RELAY_TARGET_ROOT is set). Left uncorrected, RTL_ROOT
  # anchors containment at .xyz/: the repo-root-relative strip below never matches an ABSOLUTE
  # relay-file path (it isn't under .xyz/), so the relay file's own turn-append fails its off-lane
  # match — and rtl_worktree_begin's `-e "$RTL_ROOT/$a"` seed check for every OTHER allowlisted
  # artifact resolves under .xyz/ too, finds nothing there, and deletes the artifact from the
  # worktree handed to the agent (the "codex says the worktree doesn't contain my files" symptom —
  # codex was telling the truth). Unconditional (not gated on RELAY_TARGET_ROOT, unlike the GH-51
  # block above): whenever RTL_ROOT is not itself the toplevel of the git repo it resolves into —
  # i.e. it is some ancestor's subdirectory, exactly the vendored-.xyz shape — collapse to that
  # toplevel. A normal (non-vendored) RTL_ROOT already IS its own toplevel, so this is a no-op there.
  # STRING-based, not `rev-parse --show-toplevel` (physical path, e.g. /private/var): the relay file
  # and artifact paths are built by the CALLER from RTL_ROOT's own (possibly symlinked, e.g. /var)
  # string form, so correcting to the physical toplevel would just move the mismatch — the relay
  # file's absolute prefix would then fail to strip against a /private/var-rooted RTL_ROOT instead of
  # a .xyz-rooted one (caught live: an early version of this fix did exactly that). `--show-prefix`
  # gives the repo-root-relative form of RTL_ROOT itself; stripping that suffix off RTL_ROOT's own
  # string yields the toplevel in RTL_ROOT's OWN symlink form, matching what the rest of the turn uses.
  #
  # GH-417 — scope of the warning above. It is about THIS collapse, which runs BEFORE the GH-261
  # normalization below and would therefore change RTL_ROOT's symlink form while the allowlist is
  # still holding the caller's. It is NOT a verdict on `--show-toplevel` generally, and in particular
  # not on utils/py/rtl.py:resolve_turn_root, which defaults ROOT to exactly that construct on purpose
  # (GH-296) and is safe doing so: GH-261 (312a2c3) canonicalizes BOTH RTL_ROOT and each absolute
  # allowlist entry to physical form before stripping, so by then either form resolves. The two
  # statements read as a contradiction for three weeks and cost Marathon Plan K's Wave 1 a wrong
  # root-cause; 312a2c3's own message names the test/marathon-drive.sh GH-171/GH-172 failures Plan K
  # measured two days earlier and could not explain. test/gh417-turn-root-symlink-prefix.sh pins all
  # of it, including that removing GH-261's canonicalization brings exit 6 straight back.
  local _gh160_prefix
  _gh160_prefix="$(git -C "$RTL_ROOT" rev-parse --show-prefix 2>/dev/null)"
  if [[ -n "$_gh160_prefix" ]]; then
    _gh160_collapsed=1
    RTL_ROOT="${RTL_ROOT%/"${_gh160_prefix%/}"}"
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
  # GH-173 B3: remember reviewer-turn-ness for rtl_enforce (called AFTER the turn, by which point the
  # agent has already flipped NEXT to the other role — rtl_is_reviewer_turn "$f" would read false then).
  if rtl_is_reviewer_turn "$f"; then
    RTL_WAS_REVIEWER_TURN=1
    [[ -n "$csv" ]] && printf 'relay-turn: REVIEWER turn — scoping allowlist to the relay file only (ignoring ALLOW_PATHS=%s)\n' "$csv" >&2
    csv=""
  else
    RTL_WAS_REVIEWER_TURN=0
  fi
  local _extra p; IFS=',' read -ra _extra <<<"$csv"
  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
  # GH-261: RTL_ROOT and an absolute RTL_ALLOW entry (the relay file, typically) can each
  # independently arrive in EITHER symlink form — e.g. RTL_ROOT via `git rev-parse --show-toplevel`
  # (physical, /private/var/... on macOS) while the caller built the relay-file path from its own
  # $PWD (logical, /var/...), or vice versa depending on which code path ran. Whichever direction
  # the mismatch goes, the prefix strip below is a silent no-op: the entry survives absolute, fails
  # its own off-lane match in rtl_worktree_end, and the whole turn is wrongly reverted as a
  # containment violation (exit 6). Canonicalize BOTH sides to their physical form before stripping
  # so either direction resolves; a genuinely foreign path (a real XYZ_ARCHIVE_ROOT redirect, GH-30
  # Phase 3, below) still won't share RTL_ROOT's prefix even in physical form, so this is a no-op
  # for that case — it stays absolute as intended.
  local _rtl_root_phys
  _rtl_root_phys="$(cd "$RTL_ROOT" 2>/dev/null && pwd -P)" || _rtl_root_phys="$RTL_ROOT"
  local _n=() a                       # normalize to repo-root-relative (git status emits relative)
  for a in "${RTL_ALLOW[@]}"; do
    if [[ "$a" == /* && -e "$a" ]]; then
      local _a_dir
      _a_dir="$(cd "$(dirname "$a")" 2>/dev/null && pwd -P)"
      [[ -n "$_a_dir" ]] && a="$_a_dir/$(basename "$a")"
    fi
    if [[ "$a" == "$_rtl_root_phys"/* ]]; then
      a="${a#"$_rtl_root_phys"/}"
    else
      a="${a#"$RTL_ROOT"/}"
    fi
    _n+=("$a")
  done
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
  rtl_trace "rtl_init: RTL_ROOT=$RTL_ROOT (gh51_collapsed=$_gh51_collapsed gh160_collapsed=$_gh160_collapsed ignorecase=$RTL_IGNORECASE)"
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

# GH-107: opt-in tool-cache exemption for rtl_worktree_end's off-lane loop. A builder's own tooling
# can write an untracked cache dir as a side effect of an otherwise fully-allowlisted turn (observed
# live: .codebase-memory/ from a codebase-memory MCP server discarded a 442-line, 67/67-green build);
# without an exemption that single stray dir fails the whole turn (sibling of #54 — same mechanism,
# different trigger). Built-in list = tool caches this harness has already had to gitignore for the
# same reason; CONTAINMENT_IGNORE (comma-separated glob patterns, empty by default) extends it with
# no code change. Deliberately additive and root-anchored: tracked-file detection and every
# non-matching path keep today's off-lane behavior byte-for-byte; a nested cache (e.g.
# sub/.codebase-memory/) is NOT exempted by the built-ins — opt in explicitly via CONTAINMENT_IGNORE.
rtl_is_containment_ignored() {  # <path> — is <path> an exempted tool-cache side-effect write?
  local x="$1" pat
  local pats=('.codebase-memory' '.aider*' 'node_modules/.cache')
  if [[ -n "${CONTAINMENT_IGNORE:-}" ]]; then
    # read -ra (not an unquoted for-loop) so a glob pattern like `.mytool*` is never pathname-expanded
    # against the CWD; bash-3.2/BSD-portable like the rest of this lib.
    local extra=()
    IFS=',' read -ra extra <<<"$CONTAINMENT_IGNORE"
    pats+=("${extra[@]}")
  fi
  for pat in "${pats[@]}"; do
    pat="${pat%/}"
    [[ -n "$pat" ]] || continue
    # Match the path itself, git's collapsed all-untracked form `dir/`, and anything under it.
    # $pat is intentionally unquoted: case-glob matching is the contract.
    # shellcheck disable=SC2254
    case "$x" in $pat|$pat/|$pat/*) return 0 ;; esac
  done
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

# GH-284: a driver heartbeat is deliberately a small, local JSON file rather than a process-name
# probe. Sandboxed observers can read this file even when `ps` sees no host processes. The status
# rule is intentionally asymmetric: a live PID is running even if the write is old; only an old
# heartbeat *and* an absent PID is stale. This avoids the dangerous false "finished" answer while a
# live driver is temporarily delayed.
rtl_driver_heartbeat_path() {  # <repo-root>
  printf '%s/.tick/driver-heartbeat.json' "$1"
}

rtl_driver_heartbeat_write() {  # <repo-root> <pid> <started-utc> <plan> <phase-id> <relay-task>
  local root="$1" pid="$2" started="$3" plan="$4" phase_id="$5" relay_task="$6" path updated
  path="${RTL_DRIVER_HEARTBEAT_FILE:-$(rtl_driver_heartbeat_path "$root")}"
  updated="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
  python3 - "$path" "$pid" "$started" "$updated" "$plan" "$phase_id" "$relay_task" <<'PYEOF'
import json
import os
import sys
import tempfile

path, pid, started, updated, plan, phase_id, relay_task = sys.argv[1:]
record = {
    "pid": int(pid),
    "started_utc": started,
    "updated_utc": updated,
    "plan": plan,
    "phase_id": phase_id,
    "relay_task": relay_task,
}
directory = os.path.dirname(path) or "."
fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(record, f, sort_keys=True)
        f.write("\n")
    os.replace(tmp, path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
PYEOF
}

rtl_driver_heartbeat_clear() {  # <repo-root>
  local root="$1" path
  path="${RTL_DRIVER_HEARTBEAT_FILE:-$(rtl_driver_heartbeat_path "$root")}"
  rm -f -- "$path" 2>/dev/null || true
}

rtl_driver_heartbeat_status() {  # <repo-root> [stale-after-seconds] → running|finished|stale
  local root="$1" stale_after="${2:-120}" path fields pid age
  path="${RTL_DRIVER_HEARTBEAT_FILE:-$(rtl_driver_heartbeat_path "$root")}"
  [[ -f "$path" ]] || { printf 'finished'; return 1; }
  case "$stale_after" in ''|*[!0-9]*) stale_after=120 ;; esac
  fields="$(python3 - "$path" <<'PYEOF'
import datetime as dt
import json
import sys

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    pid = int(data["pid"])
    updated = dt.datetime.fromisoformat(str(data["updated_utc"]).replace("Z", "+00:00"))
    age = max(0, int((dt.datetime.now(dt.timezone.utc) - updated).total_seconds()))
    print(f"{pid}\t{age}")
except Exception:
    pass
PYEOF
)"
  [[ "$fields" == *$'\t'* ]] || { printf 'finished'; return 1; }
  pid="${fields%%$'\t'*}"; age="${fields#*$'\t'}"
  case "$pid:$age" in *[!0-9:]*|:*) printf 'finished'; return 1 ;; esac
  if kill -0 "$pid" 2>/dev/null; then
    printf 'running'
    return 0
  fi
  if [[ "$age" -gt "$stale_after" ]]; then
    printf 'stale'
    return 2
  fi
  printf 'finished'
  return 1
}

# --- Worktree isolation (ROADMAP Part A Phase 3.6 — the airtight async/side-effect close) ----------
# Before touching anything below: read WORKTREE-SAFETY.md (repo root) — it documents the
# git-worktree footguns and the safe recovery path for a corrupted RTL_ROOT/.git (GH-177). This is
# the one place in the harness that runs `git worktree add`/cleanup at runtime; every turn shim
# (aider/agy/codex/claude-turn.sh) and consult.sh reach worktree isolation through this file.
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
  local wt a wt_root _root_abs _tmp_abs _gcd
  # GH-236: in /tmp-rooted environments $TMPDIR can resolve INSIDE the working root, which drops the
  # throwaway isolation worktree inside the very tree the turn operates on and breaks codex turns —
  # a failure that then surfaces mislabeled as a turn timeout. Default to $TMPDIR so behaviour is
  # unchanged everywhere else; ONLY when $TMPDIR lands inside RTL_ROOT, relocate the worktree root
  # under the repo's own git metadata dir (never part of the working tree, never under $TMPDIR) —
  # git worktree add accepts a checkout there and git status ignores it.
  wt_root="${TMPDIR:-/tmp}"
  _root_abs="$(cd "$RTL_ROOT" 2>/dev/null && pwd -P)"
  _tmp_abs="$(cd "$wt_root" 2>/dev/null && pwd -P)"
  if [[ -n "$_root_abs" && -n "$_tmp_abs" && ( "$_tmp_abs" == "$_root_abs" || "$_tmp_abs" == "$_root_abs"/* ) ]]; then
    _gcd="$(git -C "$RTL_ROOT" rev-parse --git-common-dir 2>/dev/null)"
    [[ -n "$_gcd" && "$_gcd" != /* ]] && _gcd="$RTL_ROOT/$_gcd"
    if [[ -n "$_gcd" ]] && mkdir -p "$_gcd/rtl-worktrees" 2>/dev/null; then
      wt_root="$_gcd/rtl-worktrees"
      rtl_trace "rtl_worktree_begin: RELOCATED worktree root off \$TMPDIR (inside RTL_ROOT) -> $wt_root (GH-236)"
    fi
  fi
  wt="$(mktemp -d "${wt_root}/rtl-wt.XXXXXX")" || return 1
  rm -rf "$wt"                         # git worktree add wants a non-existent path
  if ! git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
    rm -rf "$wt" 2>/dev/null; return 1
  fi
  rtl_trace "rtl_worktree_begin: WT=$wt"
  for a in "${RTL_ALLOW[@]}"; do       # seed current content (overwrite HEAD versions)
    # GH-30 Phase 3: an ABSOLUTE allowlist entry is the archive relay file — it lives in a DIFFERENT
    # repo, not this RTL_ROOT worktree. Skip it: the agent edits it at its real location and rtl_enforce
    # commits it to the archive. (Keeps seedsig index aligned with the copyback loop, which skips it too.)
    if [[ "$a" == /* ]]; then
      rtl_trace "rtl_worktree_begin: SKIP (archive-absolute) $a"
      continue
    fi
    if [[ -e "$RTL_ROOT/$a" ]]; then
      mkdir -p "$wt/$(dirname "$a")"
      cp -R "$RTL_ROOT/$a" "$wt/$a"
      rtl_trace "rtl_worktree_begin: SEED $a"
    else
      rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
                                       # deletion, else the HEAD checkout would resurrect it on copy-back
      rtl_trace "rtl_worktree_begin: SEED-DELETE $a (already absent in ROOT)"
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
  rtl_trace "rtl_worktree_end: WT=$wt"
  # GH-266: the harness's own transcript-log directory, when NOT redirected via XYZ_ARCHIVE_ROOT (the
  # default), lives inside RTL_ROOT itself and is genuinely new/untracked in a fresh isolated worktree
  # — exempt it the same way .tick/ is exempted below, mirroring rtl_check()'s $RTL_LOG_REL exemption
  # (line ~683). When XYZ_ARCHIVE_ROOT IS set, rtl_transcript_root resolves outside RTL_ROOT entirely,
  # so nothing here would ever appear in this worktree's own git status — no exemption needed then.
  local _rtl_log_top=""
  [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]] && _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
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
    # GH-266: git collapses an all-untracked dir to one line (same reasoning as .relay-artifacts
    # below) — match both the bare transcript-log directory name and any path under it.
    if [[ -n "$_rtl_log_top" ]]; then
      case "$path" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) continue ;; esac
    fi
    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
    # not silently discarded). git collapses an all-untracked dir to ".relay-artifacts/", so match both.
    case "$path" in
      .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
        if [[ -f "${wt}.artifactsig" ]] && [[ "$(_rtl_sig "$wt/.relay-artifacts")" == "$(cat "${wt}.artifactsig")" ]]; then
          continue
        fi
        rtl_trace "rtl_worktree_end: OFFLANE path=$path (artifact modified)"
        RTL_WT_OFFLANE=1; continue ;;
    esac
    rtl_in_allow "$path" && continue
    rtl_is_containment_ignored "$path" && continue   # GH-107: opt-in tool-cache exemption
    rtl_trace "rtl_worktree_end: OFFLANE path=$path"
    RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
  done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
  rtl_trace "rtl_worktree_end: OFFLANE_VERDICT=$RTL_WT_OFFLANE"
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
      if [[ -n "$seedsig" && "$nowsig" == "$seedsig" ]]; then
        rtl_trace "rtl_worktree_end: UNCHANGED $a (left ROOT alone)"
        continue
      fi
      if [[ -e "$wt/$a" ]]; then
        mkdir -p "$RTL_ROOT/$(dirname "$a")"
        # GH-140: copy into a temp path beside the destination, then atomically rename it into place —
        # NOT a direct in-place `cp -R` onto $RTL_ROOT/$a. A plain cp truncates+rewrites an existing
        # destination at the SAME inode; if $a is a script actively being interpreted right now (this
        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback
        # targets for a Seam #1-style lane), the live reader can observe a half-old/half-new file mid
        # execution. A 2026-07-05 run hit exactly this: the outer process crashed with a garbled parse
        # immediately after copyback, then corrupted further into wiping the working tree. `mv` on the
        # same filesystem is an atomic rename (same pattern as append-xyz-completion.sh's os.replace) —
        # an fd already open on the old $RTL_ROOT/$a keeps reading the old inode until it closes, and it
        # never observes a nonexistent or half-written path in between.
        local _tmp="$RTL_ROOT/$(dirname "$a")/.rtl-copyback.$$.$(basename "$a")"
        rm -rf "$_tmp"
        cp -R "$wt/$a" "$_tmp"
        if [[ -d "$_tmp" && ! -L "$_tmp" ]]; then
          # rename(2) cannot atomically replace a non-empty directory — remove the old one first.
          # No live process reads a directory as an executing script, so this narrow window is safe.
          rm -rf "$RTL_ROOT/$a"
          mv "$_tmp" "$RTL_ROOT/$a"
        else
          # Regular file (or symlink): rename(2) atomically clobbers an existing destination directly —
          # no separate rm, no window where the path is missing.
          mv -f "$_tmp" "$RTL_ROOT/$a"
        fi
        rtl_trace "rtl_worktree_end: COPIED $a"
      elif [[ -e "$RTL_ROOT/$a" ]]; then
        rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
        rtl_trace "rtl_worktree_end: DELETED $a (removed from ROOT)"
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
  local root="${RTL_ROOT:-}" tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}" tickbin f_rel csv_rel="" p _a
  tickbin="$(rtl_tick_bin "$tickroot")"
  # GH-304: derive the repo-root-relative EDIT path robustly. A plain `${f#"$root/"}` string-strip
  # silently no-ops when $f and $root arrive in different symlink forms (git's PHYSICAL /private/var
  # toplevel vs a /var-form path built from $PWD on macOS) — the absolute path then leaks into the
  # prompt, inviting a write straight into RTL_ROOT past the worktree. Canonicalize both sides to their
  # physical form before stripping (mirrors rtl_init's RTL_ALLOW normalization), so the seed path
  # (rtl_worktree_begin) and the prompt path stay in lockstep. Falls back to the raw string strip for a
  # relative or nonexistent $f — byte-for-byte the prior behaviour for the common same-CWD case.
  f_rel="${f#"${root:+$root/}"}"
  if [[ "$f" == /* && -e "$f" ]]; then
    local _f_dir _f_phys _root_phys
    _f_dir="$(cd "$(dirname "$f")" 2>/dev/null && pwd -P)"
    _root_phys="$(cd "$root" 2>/dev/null && pwd -P)"
    if [[ -n "$_f_dir" && -n "$_root_phys" ]]; then
      _f_phys="$_f_dir/$(basename "$f")"
      [[ "$_f_phys" == "$_root_phys"/* ]] && f_rel="${_f_phys#"$_root_phys"/}"
    fi
  fi
  if [[ -n "$csv" ]]; then
    IFS=',' read -ra _a <<<"$csv"
    for p in "${_a[@]}"; do [[ -n "$p" ]] && csv_rel+="${csv_rel:+,}${p#"${root:+$root/}"}"; done
  fi
  # REVIEWER-turn scoping: drop the csv from the "edit only" clause and tell the model plainly it must
  # not edit the artifact — so the prompt matches the relay-file-only allowlist rtl_init enforces (an
  # agent told it MAY edit X and then reverted is needless friction; tell it the truth up front).
  local role_note=""
  # GH-397: pass the acting agent explicitly — $1 here is the turn's real actor, so the role lookup
  # never has to fall back to the RELAY_AGENT env or to agent-maintained NEXT: prose.
  if rtl_is_reviewer_turn "$f" "$agent"; then
    csv_rel=""
    role_note=' You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn.'
  fi
  # GH-31 / #15: point the reviewer at the seeded read-only artifact (worktree-relative; it is NOT a
  # writable edit target — an edit fails the turn).
  local art_note=""
  [[ -n "${RTL_ARTIFACT_REL:-}" ]] && art_note=" The artifact under review is at ${RTL_ARTIFACT_REL} — READ it for your review, but do NOT edit it (any edit fails your turn)."
  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. For the %s token ALWAYS use the absolute, env-pinned tick — a bare or ./bin/tick from a worktree/foreign CWD silently no-ops and DEADLOCKS the relay: TICK_REPO_ROOT="%s" "%s". Token sequence: (1) claim it FIRST — claim %s --agent %s --paths %s — the --paths flag is MANDATORY; without it the claim silently fails (prints usage) and your later release errors "task ... is open". (2) ping is optional. (3) when finished, %s (or done + set STATUS: Approved when approving). Edit ONLY %s%s.%s%s NEVER run git yourself — no add/commit/push/reset; a self-commit FAILS your whole turn. Do NOT touch any other file. The harness makes the one file-scoped commit for you after you hand off the token. Do NOT run the full project test/gate suite (e.g. validate.sh) yourself — running it can create files that trip containment and DISCARD your whole turn; verify ONLY with the specific test for the file(s) you changed. The harness runs the gate after your turn.' \
    "$agent" "$f_rel" "$task" "$tickroot" "$tickbin" "$task" "$agent" "$f_rel" "$handoff" "$f_rel" "${csv_rel:+ and: $csv_rel}" "$role_note" "$art_note"
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

# GH-141 — recoverability-only mitigation for the concurrent peer-edit race.
#
# rtl_check CANNOT distinguish "a peer session's concurrent mid-turn edit" from "the agent's own
# off-lane self-escape": both produce byte-identical porcelain diffs, and rtl_before's snapshot is
# taken once at turn start, so anything that turns dirty DURING the turn window looks identical.
# Any fix of the shape "don't revert a newly-dirty non-allowlisted path" would silently disable
# rtl_enforce's documented backstop against the already-observed GH-22 self-escape vector.
#
# So the revert DECISION IS DELIBERATELY UNCHANGED. This only copies the pre-revert content aside
# first, turning "not recoverable in general" (GH-141's live 2026-07-05 incident, and a second
# occurrence on 2026-07-18) into a recoverable one. Mirrors the refs/relay-orphan/<sha> pattern
# rtl_enforce already uses for the moved-HEAD case. Backups land under .tick/, which rtl_check
# exempts intrinsically, so a backup can never itself be flagged as off-lane.
rtl_orphan_backup() {  # <path> — copy pre-revert content aside; must never block the revert
  local p="$1" dest
  [[ -n "$p" && -e "$RTL_ROOT/$p" ]] || return 0
  : "${RTL_ORPHAN_BACKUP:="$RTL_ROOT/.tick/orphan-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
  dest="$RTL_ORPHAN_BACKUP/$p"
  mkdir -p "$(dirname "$dest")" 2>/dev/null || return 0
  cp -R "$RTL_ROOT/$p" "$dest" 2>/dev/null || return 0
  printf '%s-turn: pre-revert copy of %s saved under %s\n' "$RTL_TOOL" "$p" "$RTL_ORPHAN_BACKUP" >&2
  rtl_log_always "rtl_check: orphan-backup path=$p dest=$RTL_ORPHAN_BACKUP"
}

rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
  local p="$1"
  [[ -n "$p" ]] || return 0
  # tick's own state dir is coordination state the turn legitimately writes — exempt it intrinsically,
  # independent of whether the HOST repo gitignores .tick (field report MBP16 [2]).
  case "$p" in .tick/*|.tick) return 0 ;; esac
  # the shim's own transcript log, if it lands in the tree, is not an agent edit — drop it, don't flag
  if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
  # GH-261: the exact-match exemption above only fires for the ONE transcript file itself; when the
  # harness's own transcript-log directory is entirely new/untracked, git collapses it to one line
  # (e.g. "relay-system/"), which never equals $RTL_LOG_REL's deeper file path. Mirrors
  # rtl_worktree_end's GH-266 fix, applied here to the non-worktree containment path too.
  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
    local _rtl_log_top; _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
    case "$p" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) return 0 ;; esac
  fi
  if rtl_in_allow "$p"; then
    rtl_trace "rtl_check: ALLOW path=$p"
    return 0
  fi
  printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
  rtl_log_always "rtl_check: OFF-ALLOWLIST path=$p tool=$RTL_TOOL — reverting"
  rtl_orphan_backup "$p"   # GH-141: recoverable copy BEFORE the destructive revert below
  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
  RTL_VIOLATION=1
}

# GH-173 B3 / GH-178 A4 follow-up (code review on PR #184): the claim-trigger and citation regexes
# are shared by both call sites below — rtl_check_uncited_findings's per-line downgrade, and
# rtl_has_uncited_claim's read-only predicate (used by consult.sh's A4 stamp) — so the two stay in
# lockstep on one definition of "claim"/"citation" instead of drifting apart.
#   RTL_CLAIM_WORD_RE — free-form phrasing a model might use INSTEAD of the [Pass] tag to assert
#                        correctness. Widened 2026-07-08 from a 3-word list ([Pass]/verified/
#                        confirmed) — that list let an assertion like "looks good, no issues, ship
#                        it" bypass the backstop entirely (none of the 3 tokens present), undermining
#                        the "mechanical, not prompt-compliance-dependent" premise for any vocabulary
#                        outside that short list. The [Pass] TAG itself is deliberately NOT folded
#                        into this variable — see the warning below.
#   RTL_CITATION_RE    — a quoted span ("..."/`...`) or a file:line reference (name:NNN).
# WARNING — do not add `\[Pass\]` (or any other backslash-escaped literal) to either of these
# strings. Both are passed to awk via `-v` and matched as a DYNAMIC regex (`line ~ var`); macOS's
# default /usr/bin/awk ("one true awk") string-unescapes a -v value before compiling it as a regex,
# which silently turns the literal string \[Pass\] into the bracket EXPRESSION [Pass] — i.e. "any
# single P, a, or s character" — matching almost every line instead of the literal tag. Caught in
# review of this very follow-up (the widened-vocabulary tests below false-matched an unrelated
# [Blocker] line and a bare "RECOMMENDATION: ship" line). Reproduce with:
#   printf 'xyz\n' | awk -v re='\[Pass\]' '$0 ~ re {print "false match: " $0}'   # prints on macOS awk
# The [Pass] tag check MUST stay an inline `/\[Pass\]/` literal in each awk SCRIPT below (not a -v
# value) — inline /regex/ delimiters are compiled directly, bypassing the -v string-unescape step.
RTL_CLAIM_WORD_RE='(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)'
RTL_CITATION_RE='"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+'

# GH-173 B3: mechanical uncited-"verified" check. new-relay.sh's own Reviewer template ("▶ TAKE YOUR
# TURN" block) now ASKS for a citation on any [Pass]/"verified" finding, but a prompt instruction is
# model compliance, not a guarantee — Jedi Wright's beta report hit exactly that gap (a "verified"
# claim with no quote). This does NOT verify a citation is ACCURATE (out of scope, no real
# citation-verification engine); it only catches the ABSENCE of one, mechanically, and downgrades the
# claim in place so the caveat is structural rather than trusting the model followed the instruction.
# A "citation" is a quoted span ("..."/`...`) or a file:line reference (name:NNN) within the next
# RTL_CITATION_WINDOW (default 3) lines, INCLUDING the claim's own line (inline citations count).
rtl_check_uncited_findings() {  # <relay_file_path> — rewrites the file in place
  local f="$1" win="${RTL_CITATION_WINDOW:-3}" tmp
  [[ -n "$f" && -f "$f" ]] || return 0
  tmp="${f}.rtlcite.$$"
  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
    { line[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        # already downgraded (prior pass) -> never re-flag. Required for idempotency: a prose "verified"
        # claim is appended-to, not replaced, so the trigger word "verified" is still on the line.
        if (line[i] ~ /\[Unverified — no citation\]/) { print line[i]; continue }
        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
        if (!claim) { print line[i]; continue }
        cited = 0
        for (j = i; j <= NR && j <= i + win; j++) {
          if (line[j] ~ cite_re) { cited = 1; break }
        }
        if (cited) { print line[i]; continue }
        out = line[i]
        if (out ~ /\[Pass\]/) { gsub(/\[Pass\]/, "[Unverified — no citation]", out) }
        else { out = out "  [Unverified — no citation]" }
        print out
      }
    }
  ' "$f" > "$tmp" && mv "$tmp" "$f"
}

# GH-178 A4 follow-up (code review on PR #184): read-only predicate reused by consult.sh's advisor
# citeless-stamp so B3 and A4 share one definition of "claim"/"citation" rather than two independent
# implementations drifting apart. Flags <file> as having an uncited claim if EITHER (a) the file has
# ZERO citations anywhere (the original A4 spec — "carries zero explicit citations anywhere"), OR
# (b) at least one claim-bearing line's own RTL_CITATION_WINDOW has no citation nearby, even though
# the file cites something elsewhere. (b) is the fix for the gap the code review flagged: the
# original consult.sh check only asked "is there a citation ANYWHERE in the whole transcript" — one
# incidental citation early in a long answer let several later uncited [Pass]/verified claims slip
# through unflagged. Mirrors grep -q's convention: exit 0 (true) = flag it, exit 1 = adequately cited.
# Missing/unreadable file fails safe (flagged), matching the old grep-based check's behavior on a
# missing $out.
rtl_has_uncited_claim() {  # <file>
  local f="$1" win="${RTL_CITATION_WINDOW:-3}"
  [[ -n "$f" && -f "$f" ]] || return 0
  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
    { line[NR] = $0; if ($0 ~ cite_re) any_cite = 1 }
    END {
      flag = !any_cite
      for (i = 1; i <= NR && !flag; i++) {
        if (line[i] ~ /\[Unverified — no citation\]/) continue
        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
        if (!claim) continue
        cited = 0
        for (j = i; j <= NR && j <= i + win; j++) {
          if (line[j] ~ cite_re) { cited = 1; break }
        }
        if (!cited) flag = 1
      }
      exit (flag ? 0 : 1)
    }
  ' "$f"
}

# GH-235 A4 v0: prompt-trace classifier for ALREADY-CITED claims only. Shares the same claim/citation
# detector as rtl_has_uncited_claim() above; the only extra question is whether the nearby citation
# string was discovered firsthand in the transcript or merely echoed from the operator prompt text
# persisted by consult.sh. Known limitation: exact/whitespace-normalized substring matching can still
# false-FIRSTHAND when the advisor reformats a prompt citation (e.g. prompt says "consult.sh lines
# 117-126", answer cites consult.sh:117). v0 accepts that; do not fuzzy-match it here.
rtl_classify_cited_claims() {  # <transcript_file> <prompt_file>
  local transcript="$1" prompt="$2" win="${RTL_CITATION_WINDOW:-3}"
  [[ -n "$transcript" && -f "$transcript" && -n "$prompt" && -f "$prompt" ]] || return 0
  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
    function norm(s,    t) {
      t = s
      gsub(/[[:space:]]+/, " ", t)
      sub(/^ /, "", t)
      sub(/ $/, "", t)
      return t
    }
    FNR == NR { prompt = prompt $0 "\n"; next }
    { line[NR] = $0 }
    END {
      prompt_norm = norm(prompt)
      for (i = 1; i <= NR; i++) {
        if (line[i] ~ /\[Unverified — no citation\]/) continue
        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
        if (!claim) continue
        first_token = ""
        echoed_token = ""
        for (j = i; j <= NR && j <= i + win; j++) {
          rest = line[j]
          while (match(rest, cite_re)) {
            token = substr(rest, RSTART, RLENGTH)
            if (first_token == "") first_token = token
            if (index(prompt_norm, norm(token)) > 0) {
              echoed_token = token
              break
            }
            rest = substr(rest, RSTART + RLENGTH)
          }
          if (echoed_token != "") break
        }
        if (first_token == "") continue
        if (echoed_token != "") print "ECHOED " echoed_token
        else print "FIRSTHAND " first_token
      }
    }
  ' "$prompt" "$transcript"
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
      rtl_log_always "rtl_enforce: HEAD_MOVED branch=peer-preserve (worktree-isolated; concurrent peer commit kept)"
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
      rtl_log_always "rtl_enforce: HEAD_MOVED branch=in-root-reset agent=$agent reset_to=${RTL_BEFORE_HEAD:0:8}"
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
  rtl_trace "rtl_enforce: RTL_VIOLATION=$RTL_VIOLATION"
  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; rtl_log_always "rtl_enforce: VIOLATION off-lane edits reverted; failing the turn"; exit 6; }
  # GH-173 B3: downgrade any uncited [Pass]/verified Reviewer finding BEFORE staging, so the fix lands
  # in the SAME commit as the turn instead of needing a second one. Reviewer-only (Producer findings
  # aren't graded by this template); RTL_WAS_REVIEWER_TURN was captured in rtl_init, before NEXT flipped.
  if [[ "${RTL_WAS_REVIEWER_TURN:-0}" == "1" && -n "${RELAY_FILE:-}" ]]; then
    rtl_check_uncited_findings "$RELAY_FILE"
    rtl_trace "rtl_enforce: checked $RELAY_FILE for uncited [Pass]/verified findings"
  fi
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
  # GH-198: commit file-scoped — a bare `git commit` (no pathspec) commits the ENTIRE staged index,
  # not just what the loop above just staged. If RTL_ROOT already had unrelated content staged when
  # the turn started (e.g. an operator's own in-progress `git add`), it silently rides along into the
  # relay's commit under a message that only names the relay file. Scope the commit to the allowlist,
  # skipping archive-absolute entries (GH-30 Phase 3) the same way rtl_worktree_begin's seeding loop
  # does above — an absolute path is the archive relay file in a DIFFERENT repo, not a valid pathspec
  # under RTL_ROOT.
  #
  # GH-29-class guard: `git commit -- <paths>` is NOT per-path independent like the `git add -A --`
  # loop above — ONE pathspec that matches nothing (e.g. a declared artifact the turn never touched)
  # makes the WHOLE commit abort, dropping every file, not just the unmatched one. So cross-check
  # against what's ACTUALLY staged and only pass entries that are; this also correctly handles "only
  # pre-existing unrelated content is staged, the turn itself changed nothing" as a no-op instead of
  # either an empty-pathspec commit-everything (the original bug) or an aborted commit.
  local _staged _commit_paths=()
  _staged="$(git -C "$RTL_ROOT" diff --cached --name-only)"
  for _ap in "${RTL_ALLOW[@]}"; do
    [[ "$_ap" == /* ]] && continue
    grep -qxF "$_ap" <<<"$_staged" && _commit_paths+=("$_ap")
  done
  if [[ "${#_commit_paths[@]}" -eq 0 ]]; then
    # GH-304 (secondary): an empty commit set is AMBIGUOUS when the relay file is gitignored (this repo
    # gitignores parts of relay-system/). `git add -A` can't stage a gitignored path, so a turn that DID
    # append findings to a gitignored relay file lands here with the SAME empty _commit_paths as a
    # genuine token-only no-op — and both used to print byte-identical "no tracked changes (token-only
    # move?)" output, costing real diagnosis time (reported from 3 separate repos). Distinguish them: if
    # the relay file (RTL_ALLOW[0], repo-root-relative) is gitignored, say so plainly and point at the
    # file, instead of implying nothing happened. Fall back to the original message otherwise.
    local _relay_rel="${RTL_ALLOW[0]:-}"
    if [[ -n "$_relay_rel" && "$_relay_rel" != /* ]] \
       && git -C "$RTL_ROOT" check-ignore -q -- "$_relay_rel" 2>/dev/null; then
      printf '%s-turn: %s turn made no git commit — relay file %s is gitignored, so any content it appended is NOT git-tracked (this is expected, NOT a stall — read the file to confirm what the turn wrote)\n' "$RTL_TOOL" "$agent" "$_relay_rel"
      rtl_log_always "rtl_enforce: COMMIT none (relay file gitignored, on-disk change untracked) agent=$agent rel=$_relay_rel"
    else
      printf '%s-turn: %s turn produced no tracked changes (token-only move?)\n' "$RTL_TOOL" "$agent"
      rtl_log_always "rtl_enforce: COMMIT none (no tracked changes) agent=$agent"
    fi
  else
    git -C "$RTL_ROOT" commit -q -m "relay(${task}): ${agent} turn (${RTL_TOOL} headless; no push)" -- "${_commit_paths[@]}"
    printf '%s-turn: committed %s turn (file-scoped, no push)\n' "$RTL_TOOL" "$agent"
    rtl_log_always "rtl_enforce: COMMIT $(git -C "$RTL_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown) agent=$agent"
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
      rtl_log_always "rtl_enforce: ARCHIVE_COMMIT none (unchanged) repo=$RTL_RELAY_REPO"
    elif git -C "$RTL_RELAY_REPO" commit -q \
           -m "relay(${task}): ${agent} transcript (${RTL_TOOL} headless; archive; no push)" \
           -- "$RTL_RELAY_ARCHIVE_REL" 2>/dev/null; then
      printf '%s-turn: committed transcript to archive %s (%s; no push)\n' "$RTL_TOOL" "$RTL_RELAY_REPO" "$RTL_RELAY_ARCHIVE_REL"
      rtl_log_always "rtl_enforce: ARCHIVE_COMMIT ok repo=$RTL_RELAY_REPO rel=$RTL_RELAY_ARCHIVE_REL"
    else
      printf '%s-turn: WARN could not commit transcript to archive %s (%s) — file written but uncommitted; check the archive repo git identity\n' "$RTL_TOOL" "$RTL_RELAY_REPO" "$RTL_RELAY_ARCHIVE_REL" >&2
      rtl_log_always "rtl_enforce: ARCHIVE_COMMIT FAILED repo=$RTL_RELAY_REPO rel=$RTL_RELAY_ARCHIVE_REL"
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
  #   - CWD-independent: absolute env-pinned tick (TICK_REPO_ROOT + rtl_tick_bin), exactly as the turn
  #     prompt mandates; the relay file lives in the HARNESS clone (tickroot), not RELAY_TARGET_ROOT.
  local _relay_file="${RELAY_FILE:-}" _peer="${RELAY_PEER:-}"
  local _tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}" _tickbin
  _tickbin="$(rtl_tick_bin "$_tickroot")"
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
      rtl_trace "rtl_enforce: token-handoff branch=already-terminal status=$_tstatus task=$task"
    elif [[ "$_rstatus" == "Approved" || "$_rstatus" == "Closed" ]]; then
      if TICK_REPO_ROOT="$_tickroot" "$_tickbin" done "$task" --agent "$agent" >/dev/null 2>&1; then
        printf '%s-turn: relay STATUS=%s → closed token (tick done %s)\n' "$RTL_TOOL" "$_rstatus" "$task"
        rtl_log_always "rtl_enforce: token-handoff branch=done status=$_rstatus task=$task"
      else
        printf '%s-turn: WARN could not `tick done %s` as %s (not current owner?) — inspect `tick info %s`\n' "$RTL_TOOL" "$task" "$agent" "$task" >&2
        rtl_log_always "rtl_enforce: token-handoff branch=done-FAILED task=$task agent=$agent"
      fi
    elif [[ "$_tstatus" == "open" && -n "$_peer" && "$_thandoff" == "$_peer" ]]; then
      rtl_trace "rtl_enforce: token-handoff branch=already-handed-off peer=$_peer task=$task"
    elif [[ -n "$_peer" ]]; then
      if TICK_REPO_ROOT="$_tickroot" "$_tickbin" release "$task" --agent "$agent" --to "$_peer" >/dev/null 2>&1; then
        printf '%s-turn: handed off token %s → %s (tick release --to)\n' "$RTL_TOOL" "$task" "$_peer"
        rtl_log_always "rtl_enforce: token-handoff branch=release-to-peer peer=$_peer task=$task"
      else
        printf '%s-turn: WARN could not `tick release %s --to %s` as %s (not current owner?) — inspect `tick info %s`\n' "$RTL_TOOL" "$task" "$_peer" "$agent" "$task" >&2
        rtl_log_always "rtl_enforce: token-handoff branch=release-FAILED task=$task peer=$_peer"
      fi
    else
      printf '%s-turn: WARN relay STATUS not terminal and no RELAY_PEER set — token %s left as-is (set RELAY_PEER for auto-handoff)\n' "$RTL_TOOL" "$task" >&2
      rtl_log_always "rtl_enforce: token-handoff branch=warn-stuck task=$task"
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
  # GH-161: our own rtl_trace/rtl_log_always calls above may have APPENDED to RTL_LOG after the
  # earlier in-loop cleanup (rtl_check drops the shim's own transcript log when it happens to land
  # inside the tracked tree — "not an agent edit"), recreating that file. Sweep it again here, once,
  # so a log path that happens to sit inside RTL_ROOT still leaves the tree exactly as clean as before
  # this instrumentation existed. Gate on `git status --porcelain` (NOT tracked-vs-untracked): a
  # gitignored persistent log (the GH-161 default, under relay-system/logs/) must NEVER be swept here —
  # it is untracked BY DESIGN and is meant to survive. `git status --porcelain` naturally excludes
  # ignored paths, so it only flags the genuine stray case rtl_check already handles mid-loop (an
  # un-ignored log path that reappeared after our late writes) — never a tracked file, never an
  # intentionally-ignored one.
  # RTL_LOG_REL is only genuinely "in RTL_ROOT" when the earlier `${log#"$RTL_ROOT"/}` strip actually
  # matched, leaving a RELATIVE path — the overwhelmingly common CODEX_LOG=/dev/null case (used by most
  # of the test suite, and any operator override outside the repo) leaves RTL_LOG_REL as the ORIGINAL
  # absolute path unstripped. Passing that straight to `git status --porcelain --` as a pathspec is a
  # FATAL git error ("outside repository", exit 128) that — unguarded — would trip the caller's `set -e`
  # and silently kill an otherwise-successful turn. Skip entirely unless it is repo-relative.
  if [[ -n "$RTL_LOG_REL" && "$RTL_LOG_REL" != /* ]]; then
    local _rtl_log_leftover
    _rtl_log_leftover="$(git -C "$RTL_ROOT" status --porcelain -- "$RTL_LOG_REL" 2>/dev/null || true)"
    # NB: an `if`/`fi` here, not `[[ .. ]] && rm ..` — as the LAST statement of this function, a bare
    # `test && action` returns the test's own (false) status when there is nothing to sweep, which
    # under the caller's `set -e` (every turn-taker shim) would silently exit the whole turn nonzero.
    # An `if` with no `else` always returns 0 when its condition is false.
    if [[ -n "$_rtl_log_leftover" ]]; then
      rm -f "$RTL_ROOT/$RTL_LOG_REL"
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
