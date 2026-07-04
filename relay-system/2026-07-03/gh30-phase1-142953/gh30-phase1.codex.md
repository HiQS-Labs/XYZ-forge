Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f29e3-5dd9-79c3-a7bd-451a5065dc42
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Review: GH-30 Phase 1 — transcript-root resolver (PR #105)

Read ONLY these two files directly (they are at the repo root of your worktree; do NOT search the
wider filesystem):
- **`relay-automation/relay-turn-lib.sh`** — focus ONLY on the two new functions `rtl_transcript_root`
  and `rtl_repo_slug` (search for "GH-30 Phase 1"). Ignore the rest of the file.
- **`test/archive-root.sh`** — the 7 checks that cover them.

## Context
The relay/consult/marathon tooling writes transcripts into `$ROOT/relay-system/<date>/…`. When run
against a foreign repo B, that pollutes B. GH-30 adds an optional `XYZ_ARCHIVE_ROOT` to redirect them.
This PR is **Phase 1 ONLY**: the resolver + validation + tests. There is deliberately NO writer wiring
(Phase 2) and NO containment/commit change (Phase 3) — do NOT flag those as missing; they are
out of scope by design.

## The contract the resolver must honor
- `rtl_transcript_root <target_root>` prints the relay-system BASE dir (callers append their own
  `/<date>/…` tail).
- `XYZ_ARCHIVE_ROOT` **unset/empty** → prints `$target_root/relay-system` — must be **byte-for-byte**
  today's path (regression-critical; any drift breaks every existing writer once Phase 2 wires it).
- `XYZ_ARCHIVE_ROOT` **set** → prints `$XYZ_ARCHIVE_ROOT/relay-system/<slug>`. Model A (decided): the
  archive is a **committed git repo**, so when set it MUST be absolute AND exist AND be a git repo —
  any failure is a HARD ERROR (message to stderr, `return 1`), **never** a silent fallback into the
  foreign tree (a silent fallback would defeat the entire feature).
- `rtl_repo_slug <target_root>`: origin remote basename (strip `.git`, strip path, strip scp `host:`
  prefix), fallback to target dir basename, sanitized to a single `[A-Za-z0-9._-]` segment, never empty.

## Answer these — grade each [Blocker]/[Should]/[Nit]/[Pass], cite `relay-turn-lib.sh:LINE`
1. **Regression safety (highest priority).** Is the unset-branch output EXACTLY `$target_root/relay-system`
   with no trailing slash, no double slash, no surprise when `target_root` has a trailing slash or is `.`?
2. **Fail-loud, never silent-fallback.** For set-but-relative, set-but-missing, set-but-non-git: does it
   ALWAYS `return 1` with nothing printed to stdout (so a caller doing `x=$(rtl_transcript_root …) || exit`
   can't accidentally get a foreign-tree path)? Any branch that could print a path AND be invalid?
2b. **`set -u` / `set -e` safety.** The function reads `${XYZ_ARCHIVE_ROOT:-}` and local vars — could it
   trip `unbound variable` or a masked-return-code bug (e.g. `local x=$(...)` swallowing the rc) if a
   caller runs under `set -euo pipefail`?
3. **Slug correctness & injection safety.** Does `rtl_repo_slug` produce a safe single path segment for:
   an `https://…/foo.git` remote; an scp `git@github.com:org/foo.git` remote; a remote with a trailing
   slash; no remote at all; a target dir basename containing spaces or `..`? Could any input yield a slug
   with `/`, `..`, an empty string, or a leading `-`?
4. **Determinism.** Same inputs → same output every time (no `$RANDOM`, no time, no CWD dependence)?
   Does it depend on the caller's CWD, or only on the passed `<target_root>` (it uses `git -C`)?
5. **Test coverage gaps.** Does `test/archive-root.sh` actually assert the above? Name any case it
   MISSES that a Phase-1 resolver should cover (e.g. trailing-slash target, scp-style remote, empty slug).

Be specific and adversarial; say [Pass] with a reason where a case is genuinely handled. Do NOT propose
Phase 2/3 work. End with a one-line RECOMMENDATION (merge as-is / merge with nits / changes required).
hook: SessionStart
hook: SessionStart Completed
codex
Reading the two requested files directly and isolating the Phase 1 resolver/test logic. I’ll check the resolver against the stated contract, then verify whether the seven tests actually pin those behaviors.
exec
/bin/zsh -lc "nl -ba test/archive-root.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
exec
/bin/zsh -lc "nl -ba relay-automation/relay-turn-lib.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# archive-root.sh — GH-30 Phase 1: the single transcript-root resolver in relay-turn-lib.sh.
     3	# Covers rtl_transcript_root / rtl_repo_slug in isolation (no writer wiring — that's Phase 2):
     4	#   - XYZ_ARCHIVE_ROOT unset  → "$target/relay-system" (byte-for-byte today's path; regression guard)
     5	#   - set to a valid git repo → "$archive/relay-system/<slug>" (slug from origin remote basename)
     6	#   - set relative            → HARD ERROR (never a silent fallback into the foreign tree)
     7	#   - set-but-missing         → HARD ERROR
     8	#   - set to a NON-git dir     → HARD ERROR (Model A: the archive is a committed git repo)
     9	#   - slug fallback           → target with no origin remote uses its dir basename
    10	source "$(dirname "$0")/_setup.sh" archive-root
    11	
    12	LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
    13	[ -f "$LIB" ] || fail "relay-turn-lib.sh not found at $LIB"
    14	# shellcheck disable=SC1090
    15	source "$LIB"
    16	
    17	# $A is a git clone whose origin remote is the bare "$REMOTE" (…/remote.git) → slug "remote".
    18	SLUG_A="remote"
    19	
    20	# --- (1) unset → byte-for-byte today's path -----------------------------------------------------
    21	unset XYZ_ARCHIVE_ROOT
    22	out="$(rtl_transcript_root "$A")"; rc=$?
    23	[ "$rc" = 0 ] || fail "unset: expected rc 0, got $rc"
    24	[ "$out" = "$A/relay-system" ] || fail "unset: expected '$A/relay-system', got '$out'"
    25	pass "unset XYZ_ARCHIVE_ROOT → \$target/relay-system (regression-safe)"
    26	
    27	# --- (2) set to a valid git repo → namespaced by slug -------------------------------------------
    28	ARCHIVE="$WORK/archive"; git init -q "$ARCHIVE"
    29	out="$(XYZ_ARCHIVE_ROOT="$ARCHIVE" rtl_transcript_root "$A")"; rc=$?
    30	[ "$rc" = 0 ] || fail "set-valid: expected rc 0, got $rc"
    31	[ "$out" = "$ARCHIVE/relay-system/$SLUG_A" ] || fail "set-valid: expected '$ARCHIVE/relay-system/$SLUG_A', got '$out'"
    32	pass "set to git repo → \$archive/relay-system/<slug> (namespaced per source repo)"
    33	
    34	# --- (3) set relative → hard error (no silent fallback) -----------------------------------------
    35	out="$(XYZ_ARCHIVE_ROOT="relative/dir" rtl_transcript_root "$A" 2>/dev/null)"; rc=$?
    36	[ "$rc" != 0 ] || fail "set-relative: expected non-zero rc, got 0 (output '$out')"
    37	[ -z "$out" ] || fail "set-relative: expected no stdout path, got '$out'"
    38	pass "set relative path → hard error, no fallback"
    39	
    40	# --- (4) set-but-missing → hard error -----------------------------------------------------------
    41	out="$(XYZ_ARCHIVE_ROOT="$WORK/does-not-exist" rtl_transcript_root "$A" 2>/dev/null)"; rc=$?
    42	[ "$rc" != 0 ] || fail "set-missing: expected non-zero rc, got 0 (output '$out')"
    43	[ -z "$out" ] || fail "set-missing: expected no stdout path, got '$out'"
    44	pass "set to a missing dir → hard error"
    45	
    46	# --- (5) set to a non-git dir → hard error (Model A) --------------------------------------------
    47	PLAINDIR="$WORK/plain"; mkdir -p "$PLAINDIR"
    48	out="$(XYZ_ARCHIVE_ROOT="$PLAINDIR" rtl_transcript_root "$A" 2>/dev/null)"; rc=$?
    49	[ "$rc" != 0 ] || fail "set-nongit: expected non-zero rc, got 0 (output '$out')"
    50	[ -z "$out" ] || fail "set-nongit: expected no stdout path, got '$out'"
    51	pass "set to a non-git dir → hard error (Model A requires a committed archive)"
    52	
    53	# --- (6) slug fallback: target with no origin remote → dir basename -----------------------------
    54	NOREMOTE="$WORK/lonerepo"; git init -q "$NOREMOTE"   # git repo, but no origin remote
    55	out="$(XYZ_ARCHIVE_ROOT="$ARCHIVE" rtl_transcript_root "$NOREMOTE")"; rc=$?
    56	[ "$rc" = 0 ] || fail "slug-fallback: expected rc 0, got $rc"
    57	[ "$out" = "$ARCHIVE/relay-system/lonerepo" ] || fail "slug-fallback: expected '…/relay-system/lonerepo', got '$out'"
    58	pass "no origin remote → slug falls back to target dir basename"
    59	
    60	# --- (7) rtl_repo_slug sanitizes to a single safe path segment ----------------------------------
    61	slug="$(rtl_repo_slug "$A")"
    62	[ "$slug" = "$SLUG_A" ] || fail "slug: expected '$SLUG_A', got '$slug'"
    63	case "$slug" in */*) fail "slug contains a path separator: '$slug'";; esac
    64	pass "rtl_repo_slug returns a single sanitized segment ('$slug')"
    65	
    66	echo "== archive-root: $PASS passed, $FAIL failed =="
    67	[ "$FAIL" = 0 ]

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# relay-turn-lib.sh — shared, model-AGNOSTIC safety core for headless relay turn-takers.
     3	# SOURCED by codex-turn.sh and gemini-drive.sh (thin dispatch wrappers); not run on its own.
     4	#
     5	# Containment contract — decisions/2026-06-15-unattended-agent-containment.md (3-model validated):
     6	#   (1) path-allowlist      — revert + FAIL on any change outside {relay file, ALLOW_PATHS}.
     7	#                             REVIEWER-turn scoping: when the relay file's NEXT names the Reviewer,
     8	#                             ALLOW_PATHS is dropped (allowlist = relay file ONLY), so a headless
     9	#                             reviewer cannot edit the artifact it is reviewing — any such edit reverts.
    10	#   (2) commit-bypass guard — if the agent committed during its own turn: reset --hard + FAIL (in-ROOT).
    11	#                             In a worktree-isolated turn the agent CANNOT reach ROOT's HEAD, so a moved
    12	#                             ROOT HEAD is a CONCURRENT PEER commit — PRESERVED, not reset (GH-13).
    13	#   (3) no push             — stage only the allowlist, commit file-scoped, never push
    14	# Keeping this in ONE place means a new turn-taker (gemini-drive.sh, …) inherits the exact
    15	# boundary instead of reimplementing it — reimplementation is where a fourth bypass sneaks in.
    16	#
    17	# API (all state in namespaced RTL_* globals):
    18	#   rtl_init        <root> <relay_file> <allow_csv>   — set ROOT + build normalized allowlist
    19	#                                                       (REVIEWER turn → allowlist = relay file only)
    20	#   rtl_turn_prompt <agent> <relay_file> <task> <csv> — emit the shared ▶ TAKE-YOUR-TURN prompt
    21	#                                                       (REVIEWER turn → "do not edit the artifact")
    22	#   rtl_before                                         — snapshot HEAD before the agent runs
    23	#   rtl_enforce     <task> <agent> <log> <tool>        — guards (2)+(1)+(3); EXITS 6 on violation
    24	#   rtl_run_bounded <timeout_secs> <cmd...>            — run <cmd...> under a wall-clock cap;
    25	#                                                        returns 0 on success, the cmd's own exit
    26	#                                                        code on normal failure, or 7 on timeout-kill.
    27	#                                                        No dependency on coreutils `timeout` (absent
    28	#                                                        on stock macOS) — sleep+kill watchdog pattern
    29	#                                                        (same as consult.sh _guarded). Kills by PID;
    30	#                                                        see function body for the process-group gap.
    31	#
    32	# rtl_enforce deliberately `exit 6`s the calling shell on any violation — that fails the turn.
    33	# rtl_run_bounded returns 7 on timeout; the CALLER must decide whether to continue to rtl_enforce
    34	# (it should — a killed agent may have left off-lane changes) and then exit 7 after enforcement.
    35	# Exit-code priority: containment violation (6) takes precedence over timeout (7). Rationale: a
    36	# containment violation means unsafe state was left in the repo; that signal is more critical to
    37	# surface than the mechanism (timeout) that caused the agent to be killed. A shim that detects a
    38	# timeout should still call rtl_enforce, and if rtl_enforce exits 6 the process exits 6 — correct.
    39	# If rtl_enforce completes without violation the shim then exits 7 to report the timeout.
    40	
    41	rtl_is_reviewer_turn() {  # <relay_file> — true if the file's NEXT pointer names the Reviewer role
    42	  # The relay protocol's NEXT pointer (the FIRST `NEXT:` line — the header) names the ROLE that acts
    43	  # next (Producer | Reviewer). A reviewer only appends findings to the relay file; it must never edit
    44	  # the artifact. Match the header line only, so a body/instruction mention of "NEXT: Reviewer" can't
    45	  # false-trigger. Portable (no GNU \b): BSD/macOS grep -E + POSIX classes. Missing/None → not reviewer.
    46	  local f="$1" line
    47	  [[ -f "$f" ]] || return 1
    48	  line="$(grep -iE '^[[:space:]]*NEXT:' "$f" 2>/dev/null | head -1)"
    49	  printf '%s' "$line" | grep -iqE 'Reviewer'
    50	}
    51	
    52	# GH-30 Phase 1 — single transcript-root resolver (the ONLY place the relay-system base is decided).
    53	# Every transcript writer (consult.sh, marathon-drive.sh, relay-drive.sh, swarm-preflight.sh,
    54	# extract-relay-telemetry.sh) is meant to call this instead of hardcoding "$ROOT/relay-system"
    55	# (writer wiring lands in Phase 2). It emits the relay-system BASE dir; callers append their own
    56	# "/<date>/<slug>" tail exactly as they do today.
    57	#
    58	#   rtl_transcript_root <target_root>   # <target_root> = the repo transcripts default under
    59	#
    60	# Contract:
    61	#   - XYZ_ARCHIVE_ROOT unset/empty → "$target_root/relay-system"   (byte-for-byte today's path)
    62	#   - XYZ_ARCHIVE_ROOT set         → "$XYZ_ARCHIVE_ROOT/relay-system/<repo-slug>", namespaced per
    63	#                                    source repo so one central archive holds many repos collision-free.
    64	# Model A (decided 2026-07-02 — separate COMMITTED git archive repo) → when set, XYZ_ARCHIVE_ROOT
    65	# MUST be absolute, exist, AND be a git repo. Any failure is a HARD ERROR (stderr + return 1) — never
    66	# a silent fallback into the foreign tree (the whole point of the setting is to keep transcripts OUT
    67	# of repo B). The commit-into-archive semantics ride on top of this in Phase 3; Phase 1 only resolves
    68	# the path and validates the target.
    69	rtl_transcript_root() {  # <target_root> → prints relay-system base; returns 1 on invalid archive
    70	  local target_root="$1"
    71	  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
    72	    printf '%s/relay-system' "$target_root"
    73	    return 0
    74	  fi
    75	  local ar="$XYZ_ARCHIVE_ROOT"
    76	  if [[ "$ar" != /* ]]; then
    77	    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: %s\n' "$ar" >&2
    78	    return 1
    79	  fi
    80	  if [[ ! -d "$ar" ]]; then
    81	    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): %s\n' "$ar" >&2
    82	    return 1
    83	  fi
    84	  # Model A: the archive is a committed git repo. A non-git dir would silently drop transcripts on the
    85	  # floor in Phase 3, so reject it now at the resolver rather than at commit time.
    86	  if ! git -C "$ar" rev-parse --git-dir >/dev/null 2>&1; then
    87	    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): %s\n' "$ar" >&2
    88	    return 1
    89	  fi
    90	  printf '%s/relay-system/%s' "$ar" "$(rtl_repo_slug "$target_root")"
    91	}
    92	
    93	# Deterministic per-repo slug for archive namespacing: origin remote basename (…/<name>[.git]),
    94	# else the target dir's basename. Sanitized to [A-Za-z0-9._-] so it is always a safe single path
    95	# segment. Never empty (falls back to "repo").
    96	rtl_repo_slug() {  # <target_root>
    97	  local target_root="$1" url slug
    98	  url="$(git -C "$target_root" remote get-url origin 2>/dev/null || true)"
    99	  url="${url%.git}"
   100	  if [[ -n "$url" ]]; then
   101	    slug="${url##*/}"; slug="${slug##*:}"   # strip path AND scp-style host: prefix
   102	  fi
   103	  [[ -z "${slug:-}" ]] && slug="$(basename -- "$target_root" 2>/dev/null || true)"
   104	  slug="$(printf '%s' "${slug:-repo}" | tr -c 'A-Za-z0-9._-' '_')"
   105	  [[ -z "$slug" ]] && slug="repo"
   106	  printf '%s' "$slug"
   107	}
   108	
   109	rtl_init() {  # <root> <relay_file> <allow_csv>
   110	  # ROOT routing (GH-11): a foreign --target-root (exported by relay-drive as RELAY_TARGET_ROOT)
   111	  # routes the WHOLE turn — worktree base, allowlist copyback, file-scoped commit, enforce — from this
   112	  # one anchor. Unset/empty → the caller's <root> (today's behavior, byte-for-byte). Coordination
   113	  # (.tick) stays where TICK_REPO_ROOT points (the harness clone); only the ARTIFACT side moves.
   114	  RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"; local f="$2" csv="$3"
   115	  # GH-51 [1-kernel]: a SAME-REPO --target-root (notably `--target-root .`) left RTL_ROOT relative or
   116	  # redundant, so the repo-root-relative strip below (`${a#"$RTL_ROOT"/}`) could not remove an ABSOLUTE
   117	  # relay-file prefix — the relay file then failed the off-lane match and a legitimate same-repo turn
   118	  # was reverted (exit 6; the GH-37 marathon needed --target-root DROPPED to converge). When the target
   119	  # root resolves to the SAME git repo as the caller's own root, collapse so containment is
   120	  # byte-identical to the no-target-root path (a same-repo --target-root is a NO-OP). WHICH root string
   121	  # to collapse to matters: prefer the caller's own root ($1) when $1 IS the repo root, because $1 is
   122	  # the exact path form the rest of the turn uses (symlink-consistent — git rev-parse returns the
   123	  # PHYSICAL path, e.g. /private/var, while $1/the relay file may be the /var form; GH-51). But a GH-49
   124	  # vendored .xyz/ copy is a SUBDIR of the foreign repo, so its caller root ($1 = …/.xyz) is NOT the
   125	  # repo root — collapsing to $1 would root containment at .xyz/ and the foreign repo's own relay file
   126	  # would fail its off-lane match. Detect that (physical $1 != physical toplevel) and use the toplevel.
   127	  # Genuine foreign roots (a different toplevel) are untouched — the cross-repo path is unchanged.
   128	  if [[ -n "${RELAY_TARGET_ROOT:-}" ]]; then
   129	    local _tt _ct _c1; _tt="$(git -C "$RTL_ROOT" rev-parse --show-toplevel 2>/dev/null)"
   130	    _ct="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"
   131	    _c1="$(cd "$1" 2>/dev/null && pwd -P)"
   132	    if [[ -n "$_tt" && "$_tt" == "$_ct" ]]; then
   133	      if [[ "$_c1" == "$_ct" ]]; then RTL_ROOT="$1"; else RTL_ROOT="$_tt"; fi
   134	    fi
   135	  fi
   136	  # macOS/APFS (and any case-insensitive fs) reports git-status paths in the case the INDEX tracks
   137	  # (e.g. RELAY-SYSTEM/…), which can differ from the lowercase invocation arg the allowlist holds
   138	  # (relay-system/…). Detect it ONCE here so rtl_in_allow can compare case-insensitively on such
   139	  # filesystems (GH-17) — otherwise a reviewer's legit append to its own relay file is seen as
   140	  # off-allowlist and reverted with exit 6. Case-sensitive repos (Linux CI) keep a byte-for-byte
   141	  # exact compare. Non-repo / unset → false (the safe, case-sensitive default).
   142	  RTL_IGNORECASE="$(git -C "$RTL_ROOT" config --get core.ignorecase 2>/dev/null || echo false)"
   143	  [[ "$RTL_IGNORECASE" == "true" ]] || RTL_IGNORECASE=false
   144	  RTL_WT_USED=0          # set to 1 by rtl_worktree_begin; read by rtl_enforce's commit-bypass guard (GH-13)
   145	  RTL_ALLOW=("$f")
   146	  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
   147	  # and must never edit the artifact under review. When NEXT names the Reviewer, drop the caller's
   148	  # extra allowlist (relay file ONLY) so any artifact edit a headless reviewer makes is reverted by
   149	  # rtl_enforce. This is the boundary an over-eager agy reviewer crossed on 2026-06-20 (it edited
   150	  # validate.sh because the artifact sat on ALLOW_PATHS). Producer turns keep the full allowlist —
   151	  # they legitimately build.
   152	  if rtl_is_reviewer_turn "$f"; then
   153	    [[ -n "$csv" ]] && printf 'relay-turn: REVIEWER turn — scoping allowlist to the relay file only (ignoring ALLOW_PATHS=%s)\n' "$csv" >&2
   154	    csv=""
   155	  fi
   156	  local _extra p; IFS=',' read -ra _extra <<<"$csv"
   157	  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
   158	  local _n=() a                       # normalize to repo-root-relative (git status emits relative)
   159	  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
   160	  RTL_ALLOW=("${_n[@]}")
   161	  # GH-31 / #15: optional READ-ONLY artifact under review (a cross-repo or uncommitted PR/diff).
   162	  # RELAY_ARTIFACT_FILE is an ABSOLUTE path to the source (relay-drive absolutizes it). It is seeded
   163	  # read-only into the worktree by rtl_worktree_begin at .relay-artifacts/<basename> — NOT added to
   164	  # RTL_ALLOW, so it is never copied back to RTL_ROOT (no leak). The reviewer may READ it; an edit
   165	  # changes its signature and fails the turn (strict read-only). Empty/unset → no artifact (default).
   166	  RTL_ARTIFACT="${RELAY_ARTIFACT_FILE:-}"
   167	  RTL_ARTIFACT_REL=""
   168	  # NB: a trailing `[[ -n .. ]] && assign` would make rtl_init RETURN the test's status (1 when no
   169	  # artifact), and a `set -e` caller (the turn shims) would abort the turn. Use an if-block → returns 0.
   170	  if [[ -n "$RTL_ARTIFACT" ]]; then
   171	    RTL_ARTIFACT_REL=".relay-artifacts/$(basename "$RTL_ARTIFACT")"
   172	  fi
   173	}
   174	
   175	rtl_in_allow() {  # <path> — is <path> on the allowlist? Case-insensitive when RTL_IGNORECASE=true (GH-17).
   176	  local x="$1" a
   177	  # GH-59: git collapses an all-untracked new dir to `dir/` in porcelain output. Treat that as
   178	  # allowlisted ONLY when it is a TRUE ancestor of a concrete allowlisted file entry (e.g.
   179	  # greenfield/ -> greenfield/output.txt). This generalizes the old .relay-artifacts dir exemption
   180	  # without widening to bare prefixes such as `green/` for `greenfield/output.txt`.
   181	  if [[ "$x" == */ ]]; then
   182	    local dir="${x%/}"
   183	    if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
   184	      local dl al; dl="$(printf '%s' "$dir/" | tr '[:upper:]' '[:lower:]')"
   185	      for a in "${RTL_ALLOW[@]}"; do
   186	        al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
   187	        [[ "$al" == "$dl"* && "$al" != "$dl" ]] && return 0
   188	      done
   189	    else
   190	      for a in "${RTL_ALLOW[@]}"; do [[ "$a" == "$dir/"* && "$a" != "$dir/" ]] && return 0; done
   191	    fi
   192	  fi
   193	  if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
   194	    # `tr` not bash-4 `${x,,}`: stock macOS bash is 3.2 (this lib is deliberately BSD/macOS-portable).
   195	    local xl al; xl="$(printf '%s' "$x" | tr '[:upper:]' '[:lower:]')"
   196	    for a in "${RTL_ALLOW[@]}"; do
   197	      al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
   198	      [[ "$xl" == "$al" ]] && return 0
   199	    done
   200	    return 1
   201	  fi
   202	  for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done
   203	  return 1
   204	}
   205	
   206	rtl_run_bounded() {  # <timeout_secs> <cmd...>
   207	  # Run <cmd...> under a wall-clock ceiling without coreutils `timeout` (absent on stock macOS).
   208	  # Mirrors the consult.sh _guarded() pattern: sleep-then-kill watchdog, no external deps.
   209	  # Process-group note: `setsid` is absent on stock macOS so we kill by PID (same as consult.sh).
   210	  # A multi-process CLI whose children outlive the leader is a known gap; worktree isolation is
   211	  # the airtight follow-up (ROADMAP 3.6). The PID kill is sufficient for hung single-process CLIs.
   212	  # NOTE: disk-quota and per-turn spend ceilings are NOT yet enforced here — wall-clock only (R5
   213	  # partial). Disk-quota belongs in a TMPDIR watchdog; spend ceilings are model-shim-specific.
   214	  local secs="$1"; shift
   215	  local apid kpid rc=0
   216	  "$@" &
   217	  apid=$!
   218	  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
   219	  kpid=$!
   220	  wait "$apid" 2>/dev/null || rc=$?
   221	  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
   222	  # Distinguish timeout-kill (signal 9 → exit 137) from a genuine rc=137 from the CLI itself.
   223	  # We use rc=137 as the proxy for "killed by our watchdog" and map it to 7.
   224	  # This is the same tradeoff consult.sh accepts: a CLI that genuinely crashes with rc=137 looks
   225	  # like a timeout. Acceptable — both cases are "turn failed abnormally."
   226	  if [[ "$rc" -eq 137 ]]; then
   227	    return 7
   228	  fi
   229	  return "$rc"
   230	}
   231	
   232	# --- Worktree isolation (ROADMAP Part A Phase 3.6 — the airtight async/side-effect close) ----------
   233	# OPT-IN: callers gate on RELAY_WORKTREE_ISOLATION=1. Default OFF → behaviour is unchanged.
   234	# Run the agent turn in a THROWAWAY git worktree of RTL_ROOT@HEAD, so any async/background write
   235	# lands in a tree we delete — RTL_ROOT is never the agent's target. This closes the gap left by the
   236	# point-in-time `rtl_enforce` + the (macOS-absent) setsid process-group reap: ROOT safety no longer
   237	# depends on killing the process group, because the agent can't reach ROOT in the first place.
   238	# Coordination state (.tick) stays SHARED — the caller must run the agent with TICK_REPO_ROOT=RTL_ROOT.
   239	#
   240	# SEED LIMITATIONS (relay review 2026-06-23 F4/F5 — known constraints, documented; structural fix deferred):
   241	#   - Cross-repo / uncommitted artifact: the worktree is a checkout of RTL_ROOT@HEAD and seeds only
   242	#     allowlisted paths UNDER RTL_ROOT (below). An artifact in ANOTHER repo, or a brand-new uncommitted
   243	#     one, is neither at HEAD nor on the writable allowlist, so it would be invisible to an isolated turn.
   244	#     FIX (GH-31 / closes #15): set RELAY_ARTIFACT_FILE (relay-drive `--artifact-file`) to seed it as a
   245	#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
   246	#     allowlist. The reviewer may READ it; an edit changes its signature and fails the turn (strict-fail);
   247	#     it is never copied back to RTL_ROOT (no leak). See rtl_init (RTL_ARTIFACT) + the seed/exempt logic
   248	#     in rtl_worktree_begin/end. (Embedding inline still works for callers who prefer it.)
   249	_rtl_sig() {  # <path> — content signature of a file/dir, or "ABSENT". Used to detect what the turn
   250	  # actually changed IN THE WORKTREE, so rtl_worktree_end copies back ONLY worktree-modified paths and
   251	  # never clobbers a ROOT-direct edit with a stale seed (GH-22). git is already required by this lib.
   252	  local p="$1"
   253	  if [[ -f "$p" ]]; then
   254	    git hash-object -- "$p" 2>/dev/null || echo "ERR:$p"
   255	  elif [[ -d "$p" ]]; then
   256	    # Stable per-dir signature: hash each tracked-or-untracked file's content in sorted order.
   257	    ( cd "$p" 2>/dev/null && find . -type f -print0 2>/dev/null | LC_ALL=C sort -z \
   258	        | xargs -0 git hash-object 2>/dev/null ) | git hash-object --stdin 2>/dev/null || echo "ERR:$p"
   259	  else
   260	    echo "ABSENT"

codex
The resolver logic is isolated now. I’m checking two edge classes that matter for a merge decision: unset-branch path stability and whether slug generation has any portability or safety drift that the current tests do not pin.
exec
/bin/zsh -lc 'basename -- /tmp/foo' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
foo

codex
The portability check on `basename --` is fine in this environment. I hit the sandbox when trying to synthesize temp repos, so the remaining edge calls are from code inspection rather than runtime setup.
exec
/bin/zsh -lc pwd in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021

exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; source relay-automation/relay-turn-lib.sh; root="'$(pwd); printf "[%s]'"\\n\" \""'$(rtl_transcript_root "$root/")"; printf "[%s]'"\\n\" \""'$(rtl_transcript_root .)"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
[/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021//relay-system]
[./relay-system]

exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; source relay-automation/relay-turn-lib.sh; out="'$(XYZ_ARCHIVE_ROOT=relative/dir rtl_transcript_root . 2>/dev/null) || rc=$?; printf "rc=%s out=[%s]'"\\n\" \""'${rc:-0}" "$out"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
rc=1 out=[]

exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; source relay-automation/relay-turn-lib.sh; printf \"slug=[%s]\\n\" \""'$(rtl_repo_slug .)"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 3643ms:
slug=[xyz-3-agents-swarm]

codex
I’ve confirmed one critical behavior under `set -euo pipefail`: the relative-archive failure path returns `1` and leaves stdout empty. I’m polling the slug call once to see what this repo’s own origin format exercises in practice.
codex
I have the merge-critical gap now: the tests never exercise unsafe-but-valid slug shapes. I’m confirming one of them (`..`) directly because the current sanitizer allows dots unchanged, which would escape the intended archive namespace.
exec
/bin/zsh -lc "bash -lc 'source relay-automation/relay-turn-lib.sh; printf \"[%s]\\n\" \""'$(rtl_repo_slug ..)"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
exec
/bin/zsh -lc "bash -lc 'source relay-automation/relay-turn-lib.sh; printf \"[%s]\\n\" \""'$(rtl_repo_slug -foo)"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 2734ms:
[..]

 succeeded in 2700ms:
[-foo]

codex
I’m checking the URL parsing branch without creating repos by stubbing `git remote get-url origin`. That isolates whether the string logic itself handles scp and trailing-slash remotes the way the contract says.
exec
/bin/zsh -lc "bash -lc 'git(){ if [[ \""'$*" == *"remote get-url origin"* ]]; then printf "%s'"\\n\" \"git@github.com:org/foo.git\"; else command git \""'$@"; fi; }; source relay-automation/relay-turn-lib.sh; printf "[%s]'"\\n\" \""'$(rtl_repo_slug /tmp/whatever)"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
[foo]

exec
/bin/zsh -lc "bash -lc 'git(){ if [[ \""'$*" == *"remote get-url origin"* ]]; then printf "%s'"\\n\" \"https://github.com/org/foo.git/\"; else command git \""'$@"; fi; }; source relay-automation/relay-turn-lib.sh; printf "[%s]'"\\n\" \""'$(rtl_repo_slug /tmp/whatever)"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021
 succeeded in 0ms:
[whatever]

codex
**Answer**

Changes required. The hard-error behavior is correct, but the slug resolver does not yet satisfy the “safe single path segment” contract, and the tests miss a few contract-critical edges.

**Findings**

- `[Should]` Regression safety is only correct for normalized `target_root` inputs. The unset branch is a raw concat at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:71), so `target_root=/repo/` becomes `/repo//relay-system` and `target_root=.` becomes `./relay-system`. The test only covers the happy-path normalized case at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:20).

- `[Pass]` Fail-loud / no silent fallback is implemented correctly. All invalid `XYZ_ARCHIVE_ROOT` branches return `1` before the only stdout print at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:90), and the tests do assert nonzero rc plus empty stdout for relative, missing, and non-git inputs at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:35), [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:41), and [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:48).

- `[Pass]` `set -u` / `set -e` handling is sound in these two functions. The env var is guarded with `${XYZ_ARCHIVE_ROOT:-}` before dereference at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:71), and `rtl_repo_slug` uses explicit fallbacks rather than a `local x=$(...)` pattern that would swallow failure semantics at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:98).

- `[Blocker]` `rtl_repo_slug` does not enforce a safe path segment strongly enough. The sanitizer at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:104) preserves `.` and `-`, so basename inputs like `..` and `-foo` survive unchanged. That violates the stated safety contract: `.../relay-system/..` escapes the repo namespace, and a leading `-` is option-shaped for later shell consumers.

- `[Should]` Remote parsing is incomplete for trailing-slash origin URLs. Because `.git` is stripped before any trailing `/` cleanup at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:99), an origin like `https://host/org/foo.git/` yields an empty remote basename and falls back to the target dir basename at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:103) instead of slug `foo`. The scp case itself is handled correctly by [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:101).

- `[Pass]` Determinism is good. There is no time/random/CWD lookup; repo metadata is read via `git -C "$target_root"` at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:98), and the unset branch emits only the literal argument string at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:72).

- `[Should]` Test coverage misses important contract cases. The invalid-path tests discard stderr entirely at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:35), so they do not assert the required error message exists; the slug test at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:60) only checks “no slash” for one benign slug and misses `..`, leading `-`, scp-style remotes, trailing-slash remotes, and the unset-branch `target_root=/repo/` / `.` cases.

**Recommendation**

Changes required: fix slug sanitization (`..` / leading `-`) and add the missing contract tests before merge.
tokens used
50,232
**Answer**

Changes required. The hard-error behavior is correct, but the slug resolver does not yet satisfy the “safe single path segment” contract, and the tests miss a few contract-critical edges.

**Findings**

- `[Should]` Regression safety is only correct for normalized `target_root` inputs. The unset branch is a raw concat at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:71), so `target_root=/repo/` becomes `/repo//relay-system` and `target_root=.` becomes `./relay-system`. The test only covers the happy-path normalized case at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:20).

- `[Pass]` Fail-loud / no silent fallback is implemented correctly. All invalid `XYZ_ARCHIVE_ROOT` branches return `1` before the only stdout print at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:90), and the tests do assert nonzero rc plus empty stdout for relative, missing, and non-git inputs at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:35), [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:41), and [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:48).

- `[Pass]` `set -u` / `set -e` handling is sound in these two functions. The env var is guarded with `${XYZ_ARCHIVE_ROOT:-}` before dereference at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:71), and `rtl_repo_slug` uses explicit fallbacks rather than a `local x=$(...)` pattern that would swallow failure semantics at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:98).

- `[Blocker]` `rtl_repo_slug` does not enforce a safe path segment strongly enough. The sanitizer at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:104) preserves `.` and `-`, so basename inputs like `..` and `-foo` survive unchanged. That violates the stated safety contract: `.../relay-system/..` escapes the repo namespace, and a leading `-` is option-shaped for later shell consumers.

- `[Should]` Remote parsing is incomplete for trailing-slash origin URLs. Because `.git` is stripped before any trailing `/` cleanup at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:99), an origin like `https://host/org/foo.git/` yields an empty remote basename and falls back to the target dir basename at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:103) instead of slug `foo`. The scp case itself is handled correctly by [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:101).

- `[Pass]` Determinism is good. There is no time/random/CWD lookup; repo metadata is read via `git -C "$target_root"` at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:98), and the unset branch emits only the literal argument string at [relay-turn-lib.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/relay-automation/relay-turn-lib.sh:72).

- `[Should]` Test coverage misses important contract cases. The invalid-path tests discard stderr entirely at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:35), so they do not assert the required error message exists; the slug test at [archive-root.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-99435-13021/test/archive-root.sh:60) only checks “no slash” for one benign slug and misses `..`, leading `-`, scp-style remotes, trailing-slash remotes, and the unset-branch `target_root=/repo/` / `.` cases.

**Recommendation**

Changes required: fix slug sanitization (`..` / leading `-`) and add the missing contract tests before merge.
