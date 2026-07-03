Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f2a0f-0bd0-7082-aaee-f71bb3eb4fc2
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Review: GH-30 Phase 2 — wire the four transcript writers to the rtl_transcript_root resolver

Read ONLY these files directly (they are at your worktree root; do NOT search the wider filesystem).
Focus on the GH-30 Phase 2 edits (grep "GH-30 Phase 2" and "rtl_transcript_root"):
- `relay-automation/relay-turn-lib.sh` — the resolver `rtl_transcript_root` + `rtl_repo_slug` (already
  merged in Phase 1; here only as the contract the writers depend on).
- `relay-automation/consult.sh` — sources the lib (line ~57); `OUT` default (~line 88).
- `relay-automation/marathon-drive.sh` — sources the lib (~48); `save_transcript` (~440).
- `relay-automation/relay-drive.sh` — sources the lib (~31); `_cv_out_dir` (~321).
- `utils/swarm-preflight.sh` — sources the lib (~62); `OUT_DIR` resolution before the dry-run gate (~607).
- `test/archive-writers.sh` and the T8b/T8c/T8d block in `test/swarm-preflight.sh`.

## Context / contract
`rtl_transcript_root <root>` prints the relay-system BASE: unset `XYZ_ARCHIVE_ROOT` → `$root/relay-system`
(byte-for-byte today's path); set → `$XYZ_ARCHIVE_ROOT/relay-system/<slug>` (validated: absolute + exists
+ git repo, else it prints to stderr and returns 1). Phase 2's job: make each writer derive its transcript
dir from the resolver instead of hardcoding `$ROOT/relay-system`, WITHOUT changing behavior when the var is
unset, WHILE keeping explicit per-call overrides (`--out`/`OUT_DIR`) winning. Phase 2 deliberately does NOT
touch containment/commit (that's Phase 3) — do not flag that as missing.

## Answer these — grade each [Blocker]/[Should]/[Nit]/[Pass], cite file:line
1. **Regression safety.** With `XYZ_ARCHIVE_ROOT` unset, does every writer produce the EXACT path it did
   before (same `$ROOT/relay-system/<date|preflight/...>` string)? Any writer where the wiring changed the
   unset path (extra/missing slash, wrong root var — consult uses `$ROOT`, relay-drive uses `$ROOT_DIR`)?
2. **Override-wins.** Is the resolver invoked ONLY when the override is empty, so an explicit `--out`/`OUT_DIR`
   wins even if `XYZ_ARCHIVE_ROOT` is set-but-invalid? Any writer that calls the resolver unconditionally and
   would abort a valid `--out` run because of a bad archive var?
3. **Fail-loud under set -e / set -uo.** consult/marathon-drive/relay-drive run `set -euo pipefail`;
   swarm-preflight runs `set -uo` (NO -e). For each wiring, does an invalid archive reliably abort the writer
   (non-zero) with NO transcript written and NO silent fallback into the target repo? Check specifically:
   (a) `x="$(rtl_transcript_root ...)" || exit 1` — does `||` correctly catch the failure under each set-mode?
   (b) marathon-drive's `local date_dir _ts_base; _ts_base="$(...)" || return 1` — is the rc really preserved
   (not masked by `local`), and does `save_transcript` returning 1 actually propagate (it's called bare)?
4. **Source-path robustness.** Each writer sources `relay-turn-lib.sh` by its own dir
   (`$HERE/relay-turn-lib.sh`, `$(dirname "${BASH_SOURCE[0]}")/relay-turn-lib.sh`, or
   `$HERE/../relay-automation/relay-turn-lib.sh` for swarm in utils/). Does each path resolve for BOTH the
   central checkout AND a vendored `.xyz/` install (where these scripts live under `.xyz/relay-automation`
   and `.xyz/utils`)? Any writer that sourced via `$ROOT` (wrong — `$ROOT` may be a foreign CONSULT_ROOT)?
5. **Side effects of sourcing.** Sourcing the containment lib into consult.sh/swarm-preflight.sh (which
   previously did not) — any risk: a top-level side effect, a variable/function-name collision, or a
   non-zero return from `source` aborting the writer under `set -e`?
6. **Test adequacy.** Does `test/archive-writers.sh` actually prove the four behaviors end-to-end for at
   least one real writer, and are the structural checks a real regression lock (would they catch a future
   writer that re-hardcodes `$ROOT/relay-system`)? Name any missed case that matters for Phase 2 (not Phase 3).

Be specific and adversarial; say [Pass] with a reason where a case is genuinely handled. Do NOT propose
Phase 3 work. End with a one-line RECOMMENDATION (merge as-is / merge with nits / changes required).
hook: SessionStart
hook: SessionStart Completed
codex
I’m reviewing only the six named files plus the specified test block, and I’ll verify the Phase 2 wiring against the resolver contract with line-specific citations.
exec
/bin/zsh -lc "nl -ba relay-automation/consult.sh | sed -n '1,180p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
exec
/bin/zsh -lc "nl -ba test/archive-writers.sh | sed -n '1,320p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# archive-writers.sh — GH-30 Phase 2: the transcript writers honor the rtl_transcript_root resolver.
     3	#
     4	# Behavioral (end-to-end through a REAL writer, consult.sh, with stub advisors):
     5	#   - XYZ_ARCHIVE_ROOT unset       → transcript lands in "$ROOT/relay-system/<date>/…" (byte-for-byte)
     6	#   - XYZ_ARCHIVE_ROOT set (git)   → lands in "$archive/relay-system/<slug>/<date>/…" (namespaced)
     7	#   - explicit --out               → wins, and the resolver/archive is NOT consulted
     8	#   - XYZ_ARCHIVE_ROOT set-invalid → the writer fails LOUD (non-zero), no transcript, no silent fallback
     9	# Structural (regression lock for all four writers — marathon-drive/relay-drive drive full relay loops
    10	#   that need codex/agy + network, so they are covered structurally + by the resolver's own unit test
    11	#   test/archive-root.sh, not re-run end-to-end here):
    12	#   - each sources relay-turn-lib.sh AND calls rtl_transcript_root
    13	#   - none retains a hardcoded "$ROOT[_DIR]/relay-system/…" transcript default that bypasses the resolver
    14	source "$(dirname "$0")/_setup.sh" archive-writers
    15	
    16	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    17	CONSULT="$ROOT_REPO/relay-automation/consult.sh"
    18	
    19	# $A is a git clone whose origin remote is the bare "$REMOTE" (…/remote.git) → slug "remote".
    20	SLUG_A="remote"
    21	
    22	# One stub impersonating an advisor: codex is detected by `exec` as argv[1] (consult's codex form).
    23	STUB="$WORK/advisor-stub"
    24	cat >"$STUB" <<'STUB_EOF'
    25	#!/usr/bin/env bash
    26	set -u
    27	printf 'ANSWER from stub\n[Pass] fine\nRECOMMENDATION: ship\n'
    28	exit 0
    29	STUB_EOF
    30	chmod +x "$STUB"
    31	
    32	run_consult() { # env: XYZ_ARCHIVE_ROOT (optional); args: extra consult flags
    33	  CONSULT_ROOT="$A" CODEX_BIN="$STUB" AGY_BIN="$STUB" GEMINI_BIN="$STUB" CODEX_FLAGS=" " \
    34	  bash "$CONSULT" --prompt "review please" --label t --models codex "$@"
    35	}
    36	
    37	# --- (1) unset → transcript under $A/relay-system/<date>/ (byte-for-byte today's path) -----------
    38	unset XYZ_ARCHIVE_ROOT
    39	run_consult >/dev/null 2>&1 || fail "consult (unset) exited non-zero"
    40	found="$(ls -d "$A"/relay-system/*/t-* 2>/dev/null | head -1)"
    41	[ -n "$found" ] || fail "unset: no transcript under \$A/relay-system/<date>/t-*"
    42	pass "consult, XYZ_ARCHIVE_ROOT unset → \$ROOT/relay-system/<date>/ (regression-safe)"
    43	
    44	# --- (2) set to a git archive → namespaced under $archive/relay-system/<slug>/<date>/ ------------
    45	ARCHIVE="$WORK/archive"; git init -q "$ARCHIVE"
    46	XYZ_ARCHIVE_ROOT="$ARCHIVE" run_consult >/dev/null 2>&1 || fail "consult (archive) exited non-zero"
    47	found="$(ls -d "$ARCHIVE"/relay-system/"$SLUG_A"/*/t-* 2>/dev/null | head -1)"
    48	[ -n "$found" ] || fail "archive: no transcript under \$ARCHIVE/relay-system/$SLUG_A/<date>/t-*"
    49	pass "consult, XYZ_ARCHIVE_ROOT set → \$archive/relay-system/<slug>/<date>/ (namespaced)"
    50	
    51	# --- (3) explicit --out wins; the archive is NOT consulted (fresh archive stays empty) -----------
    52	ARCHIVE2="$WORK/archive2"; git init -q "$ARCHIVE2"
    53	NAMED="$WORK/named-out"
    54	XYZ_ARCHIVE_ROOT="$ARCHIVE2" run_consult --out "$NAMED" >/dev/null 2>&1 || fail "consult (--out) exited non-zero"
    55	[ -n "$(ls -d "$NAMED"/t-* 2>/dev/null | head -1)" ] || fail "override: no transcript under \$NAMED/t-*"
    56	[ -z "$(ls -d "$ARCHIVE2"/relay-system 2>/dev/null)" ] || fail "override: archive was written despite explicit --out"
    57	pass "consult, explicit --out wins and skips the archive redirect"
    58	
    59	# --- (4) set-but-invalid archive → writer FAILS LOUD, no silent fallback into $A -----------------
    60	before="$(ls -d "$A"/relay-system/*/t-* 2>/dev/null | wc -l | tr -d ' ')"
    61	XYZ_ARCHIVE_ROOT="$WORK/does-not-exist" run_consult >/dev/null 2>&1; rc=$?
    62	[ "$rc" != 0 ] || fail "invalid-archive: consult should exit non-zero, got 0"
    63	after="$(ls -d "$A"/relay-system/*/t-* 2>/dev/null | wc -l | tr -d ' ')"
    64	[ "$before" = "$after" ] || fail "invalid-archive: a transcript leaked into \$A/relay-system (silent fallback)"
    65	pass "consult, set-but-invalid XYZ_ARCHIVE_ROOT → hard fail, no fallback into the target repo"
    66	
    67	# --- (5) structural: every writer sources the resolver, calls it, and drops the hardcoded default -
    68	check_writer() {  # <path> <root-var-used-in-old-default>
    69	  local f="$ROOT_REPO/$1" rootvar="$2" base; base="$(basename "$f")"
    70	  grep -q 'source .*relay-turn-lib.sh' "$f" || fail "$base: does not source relay-turn-lib.sh"
    71	  grep -q 'rtl_transcript_root' "$f"        || fail "$base: does not call rtl_transcript_root"
    72	  # the exact hardcoded transcript default this phase replaced must be gone
    73	  if grep -Eq "\"\\\$$rootvar/relay-system/\\\$\\(date|\"\\\$$rootvar/relay-system/preflight" "$f"; then
    74	    fail "$base: still has a hardcoded \$$rootvar/relay-system transcript default (bypasses resolver)"
    75	  fi
    76	  pass "$base: sources + calls rtl_transcript_root, no hardcoded relay-system default"
    77	}
    78	check_writer "relay-automation/consult.sh"       ROOT
    79	check_writer "relay-automation/marathon-drive.sh" ROOT
    80	check_writer "relay-automation/relay-drive.sh"    ROOT_DIR
    81	check_writer "utils/swarm-preflight.sh"           ROOT
    82	
    83	echo "== archive-writers: $PASS passed, $FAIL failed =="
    84	[ "$FAIL" = 0 ]

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# consult.sh — one-shot cross-model CONSULT (a panel of advisors), repo-local.
     5	#
     6	# Fans out the SAME question to Codex and agy IN PARALLEL, advisory-only, captures each transcript,
     7	# and leaves the synthesis to the caller (Claude). This is NOT a relay: a relay is an iterative 1:1
     8	# Producer↔Reviewer loop; a consult is a parallel 1-shot 1:N "second opinion," reconciled once.
     9	#
    10	# PROVABLE no-mutation boundary (reworked after the dogfood found the old best-effort revert unsafe):
    11	# advisors run with CWD set to a THROWAWAY git worktree checked out from the operator's CURRENT state
    12	# (tracked WIP via `git stash create` + untracked-not-ignored files copied in). Any file an advisor
    13	# writes lands in that disposable worktree and is destroyed with it — the operator's real working tree
    14	# is NEVER the advisors' surface, so there is nothing to revert and ambient WIP can't be clobbered.
    15	# (Codex stays `-s read-only` on top of that; agy's writes, if any, are contained by the worktree.)
    16	#
    17	# Usage:
    18	#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,agy] [--label SLUG]
    19	#   consult.sh --prompt "question" [--out DIR] [--models codex,agy] [--label SLUG]
    20	#
    21	# Options:
    22	#   --prompt-file F   File whose contents are the consult question (it may reference repo paths).
    23	#   --prompt TEXT     Inline question (mutually exclusive with --prompt-file).
    24	#   --out DIR         Parent dir for the run (default: relay-system/<today>/). Each run gets its own
    25	#                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
    26	#   --models CSV      Which advisors to run (default: codex,agy). Also: `aider` (Aider↔OpenRouter,
    27	#                     OpenAI-standard — needs OPENROUTER_API_KEY). Legacy `gemini` remains accepted
    28	#                     as an explicit alias for older tests/callers.
    29	#   --label SLUG      Run-subdir + transcript stem (default: consult).
    30	#
    31	# Env config:
    32	#   CODEX_BIN / AGY_BIN        binaries (default: codex / agy); tests inject stubs
    33	#   AIDER_BIN / AIDER_MODEL    Aider binary + OpenRouter model (default: aider / openrouter/anthropic/
    34	#                              claude-3.5-sonnet) for `--models ...,aider`; reads OPENROUTER_API_KEY.
    35	#   GEMINI_BIN                 legacy alias for AGY_BIN when `--models ...gemini` is used explicitly
    36	#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
    37	#   AGY_AUTH_TIMEOUT_S         short wall-clock cap for the agy auth probe (`agy whoami`); default 5.
    38	#                              On failure/time-out consult skips the agy lane fast with an `agy login`
    39	#                              remedy instead of waiting for the main CONSULT_TIMEOUT watchdog.
    40	#   CONSULT_ROOT               git root to consult against (default: this repo)
    41	#   CONSULT_TIMEOUT            per-advisor wall-clock cap in seconds (default: 300). A hung CLI is
    42	#                              killed and reported as failed, so the other model still degrades gracefully.
    43	#   TICK_BIN                   tick binary for cost capture (default: <root>/bin/tick)
    44	#
    45	# Boundary note: advisors run in a throwaway git worktree, so they cannot touch the operator's REPO.
    46	# That is repo-isolation, NOT an OS sandbox — only Codex additionally gets `-s read-only`; a model
    47	# could still read elsewhere on disk or reach the network. The skill docs say "repo-isolated", not
    48	# "read-only", on purpose.
    49	#
    50	# Exit: 0 = at least one advisor answered · 5 = ALL advisors failed · 2 = usage · 3 = not a git repo.
    51	
    52	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    53	ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    54	# GH-30 Phase 2: the single transcript-root resolver (rtl_transcript_root) — redirects relay-system/
    55	# to $XYZ_ARCHIVE_ROOT when that is set, else byte-for-byte "$ROOT/relay-system". consult.sh lives
    56	# beside relay-turn-lib.sh, so source it by the script's own dir (NOT $ROOT, which may be a foreign repo).
    57	source "$HERE/relay-turn-lib.sh"
    58	CODEX_BIN="${CODEX_BIN:-codex}"
    59	AGY_BIN="${AGY_BIN:-${GEMINI_BIN:-agy}}"
    60	GEMINI_BIN="${GEMINI_BIN:-$AGY_BIN}"
    61	AIDER_BIN="${AIDER_BIN:-aider}"   # --models ...,aider → advisory via Aider↔OpenRouter (needs OPENROUTER_API_KEY)
    62	die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
    63	warn() { printf 'consult: %s\n' "$*" >&2; }
    64	
    65	PROMPT_FILE=""; PROMPT_TEXT=""; OUT=""; MODELS="codex,agy"; LABEL="consult"
    66	while (($# > 0)); do
    67	  case "$1" in
    68	    --prompt-file) PROMPT_FILE="${2:-}"; shift 2 ;;
    69	    --prompt)      PROMPT_TEXT="${2:-}"; shift 2 ;;
    70	    --out)         OUT="${2:-}"; shift 2 ;;
    71	    --models)      MODELS="${2:-}"; shift 2 ;;
    72	    --label)       LABEL="${2:-}"; shift 2 ;;
    73	    --help) sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    74	    *) die "unknown argument: $1" ;;
    75	  esac
    76	done
    77	
    78	[[ -n "$PROMPT_FILE" || -n "$PROMPT_TEXT" ]] || die "one of --prompt-file or --prompt is required"
    79	[[ -n "$PROMPT_FILE" && -n "$PROMPT_TEXT" ]] && die "--prompt-file and --prompt are mutually exclusive"
    80	if [[ -n "$PROMPT_FILE" ]]; then
    81	  [[ -f "$PROMPT_FILE" ]] || die "prompt file not found: $PROMPT_FILE"
    82	  PROMPT_TEXT="$(cat "$PROMPT_FILE")"
    83	fi
    84	
    85	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    86	  || { warn "consult requires a git repo (advisor isolation uses a throwaway worktree): $ROOT"; exit 3; }
    87	
    88	# GH-30 Phase 2: default the run parent to the transcript-root resolver (honors XYZ_ARCHIVE_ROOT).
    89	# An explicit --out (OUT already set) wins and skips the resolver entirely, so an invalid
    90	# XYZ_ARCHIVE_ROOT can never override a caller who named their own --out. Resolver hard-errors loudly.
    91	if [[ -z "$OUT" ]]; then
    92	  _ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
    93	  OUT="$_ts_base/$(date +%F)"
    94	fi
    95	RUN_DIR="$OUT/${LABEL}-$(date +%H%M%S)"
    96	mkdir -p "$RUN_DIR"
    97	
    98	# Advisor preamble: independent, advisory, structured, cite evidence. Each is told a peer answers the
    99	# SAME question separately and a coordinator reconciles — so it gives its OWN read, not a guessed consensus.
   100	PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
   101	the SAME question separately and a coordinator will reconcile both answers, so give your own honest, \
   102	specific read — do not hedge toward a consensus you cannot see. Read any repo files the question \
   103	references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — \
   104	[Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY \
   105	ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
   106	FULL_PROMPT="$PREAMBLE
   107	
   108	=== CONSULT QUESTION ===
   109	$PROMPT_TEXT"
   110	
   111	# --- build the throwaway worktree = operator's CURRENT visible state, isolated --------------------
   112	# tracked WIP (staged+unstaged) WITHOUT touching the real tree; falls back to HEAD when clean.
   113	base="$(git -C "$ROOT" stash create 2>/dev/null || true)"; base="${base:-HEAD}"
   114	WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
   115	cleanup() {
   116	  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
   117	  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
   118	}
   119	trap cleanup EXIT
   120	git -C "$ROOT" worktree add --detach "$WT" "$base" >/dev/null 2>&1 \
   121	  || die "could not create isolation worktree (base $base)"
   122	# overlay untracked-not-ignored files so advisors see brand-new files (e.g. a skill being reviewed).
   123	while IFS= read -r -d '' f; do
   124	  mkdir -p "$WT/$(dirname "$f")"
   125	  cp -p "$ROOT/$f" "$WT/$f" 2>/dev/null || true
   126	done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)
   127	
   128	# Run an advisor (CWD = throwaway worktree) under a wall-clock cap so a HUNG CLI degrades to a failure
   129	# (collected as [FAIL]) rather than stalling the whole consult. No dependency on coreutils `timeout`
   130	# (absent on stock macOS) — a sleep-then-kill watchdog. Output redirection handled here.
   131	_guarded_with_timeout() {  # <out> <secs> <cmd...>
   132	  local out="$1" secs="$2"; shift 2
   133	  local apid kpid rc=0
   134	  ( cd "$WT" && "$@" < /dev/null ) > "$out" 2>&1 &
   135	  apid=$!
   136	  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
   137	  kpid=$!
   138	  wait "$apid" || rc=$?
   139	  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
   140	  [[ "$rc" != 0 ]] && printf '\nconsult: advisor failed or exceeded the %ss cap\n' "$secs" >> "$out"
   141	  return "$rc"
   142	}
   143	_guarded() {  # <out> <cmd...>
   144	  local out="$1"; shift
   145	  _guarded_with_timeout "$out" "${CONSULT_TIMEOUT:-300}" "$@"
   146	}
   147	agy_auth_preflight() {  # <out> — writes the failure reason into <out> on skip
   148	  local out="$1" secs="${AGY_AUTH_TIMEOUT_S:-5}" tmp rc=0
   149	  tmp="${out}.auth"
   150	  _guarded_with_timeout "$tmp" "$secs" "$AGY_BIN" whoami || rc=$?
   151	  [[ "$rc" -eq 0 ]] && { rm -f "$tmp"; return 0; }
   152	  cat "$tmp" > "$out" 2>/dev/null || true
   153	  if [[ "$rc" -eq 7 ]]; then
   154	    printf '\nconsult: agy auth pre-flight timed out after %ss; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n' "$secs" >> "$out"
   155	  else
   156	    printf '\nconsult: agy auth pre-flight failed (exit %s). Run `agy login` in a normal terminal, then retry.\n' "$rc" >> "$out"
   157	  fi
   158	  rm -f "$tmp"
   159	  return "$rc"
   160	}
   161	
   162	run_codex() {
   163	  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
   164	  # Billing guard: strip OPENAI_API_KEY so a consult ALWAYS bills the ChatGPT-subscription login,
   165	  # never per-token API credits (CODEX_ALLOW_API_KEY=1 to opt back in). See codex-turn.sh.
   166	  local cenv=(env); [[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || cenv+=(-u OPENAI_API_KEY)
   167	  # ${_f[@]+...} guards an EMPTY flags array under `set -u` on bash 3.2 (macOS default).
   168	  _guarded "$out" "${cenv[@]}" "$CODEX_BIN" exec ${_f[@]+"${_f[@]}"} "$FULL_PROMPT"
   169	}
   170	run_agy() {
   171	  local out="$1" secs="${CONSULT_TIMEOUT:-300}"
   172	  agy_auth_preflight "$out" || return $?
   173	  _guarded "$out" "$AGY_BIN" --dangerously-skip-permissions --print-timeout "${secs}s" -p "$FULL_PROMPT"
   174	}
   175	run_gemini() {
   176	  local out="$1"
   177	  export GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}"   # isolated: run_gemini is its own subshell
   178	  if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
   179	    _guarded "$out" "$GEMINI_BIN" --yolo --skip-trust -o json -p "$FULL_PROMPT"
   180	  else

exec
/bin/zsh -lc "nl -ba relay-automation/marathon-drive.sh | sed -n '1,560p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# marathon-drive.sh — Phase 3: single-phase headless relay loop.
     5	#
     6	# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
     7	# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
     8	# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
     9	#
    10	# Usage:
    11	#   relay-automation/marathon-drive.sh \
    12	#     --phase-brief <FILE>       phase brief (markdown; baked into the relay template)
    13	#     --reviewer    <AGENT_ID>   reviewer agent (codex* or gemini*)
    14	#     [--builder    <AGENT_ID>]  builder agent (default: claude)
    15	#     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
    16	#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
    17	#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
    18	#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
    19	#     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
    20	#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
    21	#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
    22	#                                a relay-only phase (conversation → approval, no source edit).
    23	#     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
    24	#     [--dry-run]                render relay file and print tick seed cmd, then exit
    25	#
    26	# Environment overrides (for tests):
    27	#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
    28	#   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
    29	#   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
    30	#   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
    31	#
    32	# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
    33	#        5 pre-advance gate failed · 6 containment violation (turn-taker reverted an off-lane edit) ·
    34	#        8 lane parked (GH-45 attempt cap — no token seeded; re-fire with --force) · 2 usage.
    35	
    36	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    37	# _xyz_harness: the directory containing relay-automation/ (and bin/, src/, utils/).
    38	# Vendored install: HERE is <target>/.xyz/relay-automation → _xyz_harness is <target>/.xyz
    39	# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
    40	_xyz_harness="$(cd "$HERE/.." && pwd)"
    41	if [ "$(basename "$_xyz_harness")" = ".xyz" ]; then
    42	  ROOT="${MARATHON_ROOT:-"$(cd "$_xyz_harness/.." && pwd)"}"
    43	else
    44	  ROOT="${MARATHON_ROOT:-"$_xyz_harness"}"
    45	fi
    46	# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
    47	# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". Sourced beside this script.
    48	source "$HERE/relay-turn-lib.sh"
    49	TICK_BIN="${TICK_BIN:-"$_xyz_harness/bin/tick"}"
    50	RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
    51	AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
    52	
    53	# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
    54	# lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
    55	# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
    56	# token. --force bypasses for one fire and logs it. lane_attempt_reset clears the counter when a lane
    57	# COMPLETES successfully (Approved), so the cap counts CONSECUTIVE failures and can never permanently
    58	# wedge a lane (reviewer feedback: without a reset a default-keyed lane parks forever). A nested call
    59	# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
    60	# reset) exactly once. Byte-consistent mirror in relay-drive.sh; relay-turn-lib.sh/bin/tick untouched.
    61	_lane_key() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
    62	lane_attempt_gate() {
    63	  local root="$1" raw="$2" force="${3:-0}"
    64	  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
    65	  [ -n "$raw" ] || return 0
    66	  local max="${LANE_MAX_ATTEMPTS:-2}"; case "$max" in ''|*[!0-9]*) max=2 ;; esac
    67	  local key dir file count; key=$(_lane_key "$raw"); dir="$root/.tick/attempts"; file="$dir/$key"
    68	  mkdir -p "$dir" 2>/dev/null || true
    69	  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
    70	  if [ "$force" = "1" ]; then
    71	    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
    72	  elif [ "$count" -ge "$max" ]; then
    73	    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
    74	    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
    75	    return 8
    76	  fi
    77	  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
    78	  return 0
    79	}
    80	lane_attempt_reset() {  # clear a lane's counter after it completes successfully (Approved)
    81	  local root="$1" raw="$2"
    82	  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
    83	  [ -n "$raw" ] || return 0
    84	  rm -f "$root/.tick/attempts/$(_lane_key "$raw")" 2>/dev/null || true
    85	}
    86	
    87	if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
    88	  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
    89	  # .git/, so fall back to a hidden lock beside the scripts (the .xyz/ dir is itself gitignored in the
    90	  # foreign repo, so it stays uncommitted just the same). Same lock NAME as relay-drive so a marathon
    91	  # and a relay driver still mutually exclude in one clone. Unchanged when .git/ exists.
    92	  if [[ -d "$ROOT/.git" ]]; then
    93	    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    94	  else
    95	    _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
    96	  fi
    97	  if ! mkdir "$_lock" 2>/dev/null; then
    98	    # GH-42 self-heal: the lock exists — reclaim it only if its holder is dead. A crashed/killed/
    99	    # SIGKILL'd driver used to leave a stale lock that blocked every later run until a manual rmdir.
   100	    _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
   101	    if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
   102	      printf 'marathon-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
   103	      printf 'marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
   104	      exit 1
   105	    fi
   106	    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
   107	    rm -rf "$_lock"
   108	    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
   109	    # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
   110	    # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
   111	  fi
   112	  printf '%s\n' "$$" > "$_lock/pid"
   113	  trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
   114	  export RELAY_DRIVER_LOCKED=1
   115	fi
   116	
   117	die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
   118	log()  { printf 'marathon-drive: %s\n' "$*"; }
   119	
   120	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$_xyz_harness/utils/telemetry/append-xyz-completion.sh"}"
   121	
   122	# GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
   123	# marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
   124	# originated run (harness:"swarm", tagged via XYZ_HARNESS_CONTEXT=swarm baked into the generated
   125	# invocation). Stays SILENT when marathon.sh drives us per-phase (XYZ_HARNESS_CONTEXT=marathon-phase):
   126	# marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
   127	# failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
   128	# own exit code.
   129	xyz_marathon_emit() {  # <health> <description>
   130	  local ctx="${XYZ_HARNESS_CONTEXT:-}"
   131	  [[ "$ctx" == "marathon-phase" ]] && return 0
   132	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
   133	  local health="$1" desc="$2" harness title sid
   134	  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
   135	  title="$(basename "$PHASE_BRIEF_FILE" .md 2>/dev/null)"; [[ -n "$title" ]] || title="$PHASE_ID"
   136	  # sessionId: PHASE_ID defaults to "p1", which is a constant across every swarm/bare run — useless for
   137	  # telling one run from another. Let the invoker override it (swarm-preflight bakes the per-run slug
   138	  # into its generated command via XYZ_SESSION_ID); fall back to PHASE_ID otherwise (GH-75 review).
   139	  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
   140	  "$XYZ_APPEND_BIN" "$harness" "$sid" "$health" "$title" "$desc" >/dev/null 2>&1 || true
   141	}
   142	
   143	usage() {
   144	  cat <<'EOF'
   145	Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
   146	
   147	  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
   148	  --reviewer AGENT        Reviewer agent id; must start with 'codex' or 'gemini' (required).
   149	  --builder AGENT         Builder agent id (default: claude).
   150	  --round-cap N           relay-drive turn cap (default: 5).
   151	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
   152	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
   153	  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
   154	  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
   155	  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
   156	                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
   157	  --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
   158	                          stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
   159	                          with cwd = DIR. Omit for a same-repo phase.
   160	  --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
   161	  --force                 GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
   162	  --dry-run               Render the relay file and print the tick seed; exit without running.
   163	EOF
   164	}
   165	
   166	PHASE_BRIEF_FILE=""
   167	BUILDER="claude"
   168	REVIEWER=""
   169	ROUND_CAP=5
   170	PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
   171	PHASES_DIR=""        # resolved to default after ROOT is set
   172	PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
   173	RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
   174	ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
   175	REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
   176	FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
   177	DRY_RUN=0
   178	TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
   179	                     # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).
   180	
   181	while (($# > 0)); do
   182	  case "$1" in
   183	    --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
   184	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   185	    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
   186	    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
   187	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   188	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   189	    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
   190	    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
   191	    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
   192	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   193	    --require-clean)   REQUIRE_CLEAN=1; shift ;;
   194	    --force)           FORCE=1; shift ;;
   195	    --dry-run)         DRY_RUN=1; shift ;;
   196	    --help)            usage; exit 0 ;;
   197	    *)                 die "unknown argument: $1" ;;
   198	  esac
   199	done
   200	
   201	[[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
   202	[[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
   203	[[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
   204	[[ -n "$BUILDER"          ]] || die "--builder cannot be empty"
   205	[[ -n "$PHASE_ID"         ]] || die "--phase-id cannot be empty"
   206	if [[ -n "$TARGET_ROOT" ]]; then
   207	  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
   208	    || die "invalid --target-root (not a git repo): $TARGET_ROOT"
   209	fi
   210	
   211	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
   212	PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"
   213	# Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
   214	RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
   215	
   216	# Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing. Both actors are routed to
   217	# their shim by name prefix (claude/codex/agy/gemini), so the harness supports cross-model BUILDERS
   218	# (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
   219	export MARATHON_BUILDER="$BUILDER"
   220	export MARATHON_REVIEWER="$REVIEWER"
   221	export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" GEMINI_AGENT="" AIDER_AGENT=""
   222	route_agent() {  # <agent-id> → export the matching *_AGENT var marathon-agent.sh routes on
   223	  case "$1" in
   224	    claude*) export CLAUDE_AGENT="$1" ;;
   225	    codex*)  export CODEX_AGENT="$1" ;;
   226	    agy*)    export AGY_AGENT="$1" ;;
   227	    gemini*) export GEMINI_AGENT="$1" ;;
   228	    aider*)  export AIDER_AGENT="$1" ;;
   229	    *)       die "agent '$1' not recognized — must start with claude/codex/agy/gemini/aider" ;;
   230	  esac
   231	}
   232	[[ "$BUILDER" == "$REVIEWER" ]] && die "builder and reviewer must be different agent ids (got '$BUILDER' for both)"
   233	route_agent "$BUILDER"
   234	route_agent "$REVIEWER"
   235	# Reviewer must be a QA-capable model lane (codex/gemini/agy), never the Claude builder lane.
   236	case "$REVIEWER" in codex*|gemini*|agy*) ;; *) die "reviewer '$REVIEWER' must start with codex/gemini/agy" ;; esac
   237	
   238	# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
   239	# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
   240	# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
   241	# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
   242	if [[ -n "$ARTIFACT_PATHS" ]]; then
   243	  export ALLOW_PATHS="$ARTIFACT_PATHS"
   244	else
   245	  unset ALLOW_PATHS
   246	fi
   247	
   248	PHASE_DIR="$PHASES_DIR/$PHASE_ID"
   249	RELAY_FILE="$PHASE_DIR/RELAY.md"
   250	REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
   251	
   252	# ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
   253	# Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
   254	# off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
   255	# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
   256	# unattended runs (DRY_RUN skips it — nothing is committed).
   257	if ((! DRY_RUN)); then
   258	  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
   259	    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
   260	  if [[ -n "$dirty" ]]; then
   261	    log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
   262	    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
   263	    ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
   264	  fi
   265	fi
   266	
   267	# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
   268	
   269	mkdir -p "$PHASE_DIR"
   270	BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"
   271	
   272	# Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
   273	# repo root, so a relative "./bin/tick" is a guess — a real builder turn (2026-06-17) looked for it
   274	# in the phase dir, logged "tick not present", and skipped the token handoff entirely (phase then
   275	# escalated no-progress). An absolute path the agent can run from anywhere removes that failure mode.
   276	TICK_CLI="$TICK_BIN"
   277	case "$TICK_CLI" in /*) ;; *) TICK_CLI="$ROOT/$TICK_CLI" ;; esac
   278	
   279	# Builder/reviewer instruction text + the tick claim --paths depend on whether this phase targets
   280	# real artifact file(s) (--artifact) or is relay-only. Built here so the heredoc stays a flat template.
   281	if [[ -n "$ARTIFACT_PATHS" ]]; then
   282	  CLAIM_PATHS="${REL_RELAY},${ARTIFACT_PATHS}"
   283	  BUILDER_IMPL_LINE="Implement the brief by creating/editing the artifact file(s): ${ARTIFACT_PATHS}"
   284	  BUILDER_SCOPE_LINE="Edit ONLY these paths: ${REL_RELAY} and ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   285	  REVIEWER_READ_LINE="Read the latest builder block above AND review the artifact file(s) on disk: ${ARTIFACT_PATHS}."
   286	  REVIEWER_SCOPE_LINE="Edit ONLY ${REL_RELAY} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
   287	else
   288	  CLAIM_PATHS="${REL_RELAY}"
   289	  BUILDER_IMPL_LINE="Record your work directly in this relay file (relay-only phase — no source file to edit)."
   290	  BUILDER_SCOPE_LINE="Edit ONLY ${REL_RELAY}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   291	  REVIEWER_READ_LINE="Read the latest builder block above."
   292	  REVIEWER_SCOPE_LINE="Do NOT run git. Do NOT touch any other file."
   293	fi
   294	
   295	cat > "$RELAY_FILE" << RELAY_EOF
   296	# Marathon Phase ${PHASE_ID}
   297	STATUS: Open
   298	NEXT: ${BUILDER}
   299	
   300	<!-- marathon-drive: task=${RELAY_TASK} builder=${BUILDER} reviewer=${REVIEWER} round-cap=${ROUND_CAP} -->
   301	
   302	## Phase Brief
   303	
   304	${BRIEF_TEXT}
   305	
   306	---
   307	
   308	▶ TAKE YOUR TURN (${BUILDER} — BUILDER role)
   309	
   310	You are the BUILDER for this phase. Read the phase brief above and implement it.
   311	1. ${BUILDER_IMPL_LINE}
   312	2. Append a build block to this relay file: \`### Round N · Builder · ${BUILDER}\` summarizing what you did (files touched, key decisions).
   313	3. Use this exact tick binary (run it from any directory): ${TICK_CLI}
   314	   - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
   315	   - ${TICK_CLI} ping ${RELAY_TASK} --agent ${BUILDER}
   316	   - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
   317	4. ${BUILDER_SCOPE_LINE}
   318	
   319	---
   320	
   321	▶ TAKE YOUR TURN (${REVIEWER} — REVIEWER role)
   322	
   323	You are the REVIEWER for this phase. ${REVIEWER_READ_LINE}
   324	1. Append a review block: \`### Round N · Reviewer · ${REVIEWER}\` followed by your assessment.
   325	2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
   326	3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
   327	4. Use this exact tick binary (run it from any directory) for all token operations: ${TICK_CLI}
   328	   ${REVIEWER_SCOPE_LINE}
   329	RELAY_EOF
   330	
   331	if ((DRY_RUN)); then
   332	  log "dry-run: relay file rendered at $RELAY_FILE"
   333	  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
   334	  exit 0
   335	fi
   336	
   337	# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────
   338	
   339	git -C "$ROOT" add -- "$RELAY_FILE"
   340	git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
   341	log "relay file committed: $RELAY_FILE"
   342	
   343	# ── Step 3: seed tick token with handoff → builder ──────────────────────────
   344	
   345	export TICK_REPO_ROOT="$ROOT"
   346	
   347	reconcile_relay_task() {
   348	  local info status handoff claimer
   349	  if ! info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null)"; then
   350	    return 0  # no prior task state to reconcile
   351	  fi
   352	
   353	  status="$(printf '%s\n' "$info" | sed -n 's/^status:[[:space:]]*//p' | head -n1)"
   354	  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
   355	  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
   356	
   357	  case "$status" in
   358	    claimed)
   359	      die "relay task $RELAY_TASK already has a live claim by ${claimer:-unknown}; refusing to reap a live claim"
   360	      ;;
   361	    open)
   362	      [[ -n "$handoff" ]] || return 0
   363	      case "$handoff" in
   364	        "$BUILDER"|"$REVIEWER")
   365	          # GH-56: a rerun can inherit an OPEN handoff from the previous pass. Clear only that stale
   366	          # reservation by consuming it as its routed target, then releasing it unreserved. Never reap a
   367	          # live claim here; parked claims are the watchdog's authority path.
   368	          "$TICK_BIN" claim "$RELAY_TASK" --agent "$handoff" --paths "$REL_RELAY" > /dev/null
   369	          "$TICK_BIN" release "$RELAY_TASK" --agent "$handoff" > /dev/null
   370	          log "reconciled leaked open handoff: $RELAY_TASK (cleared stale reservation for $handoff)"
   371	          ;;
   372	        *)
   373	          die "relay task $RELAY_TASK is open but reserved for unexpected agent '$handoff'"
   374	          ;;
   375	      esac
   376	      ;;
   377	  esac
   378	}
   379	
   380	# GH-45: per-lane attempt cap — refuse to start this phase once it has hit LANE_MAX_ATTEMPTS
   381	# (keyed on PHASE_ID, stable across re-fires), seeding no token; --force overrides. Counted here, so
   382	# the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not double-count this same lane.
   383	lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID" "$FORCE" || exit $?
   384	
   385	reconcile_relay_task
   386	
   387	"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
   388	"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
   389	"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
   390	log "tick token seeded: $RELAY_TASK → $BUILDER"
   391	
   392	# ── Step 4: emit phase.start ────────────────────────────────────────────────
   393	
   394	"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
   395	log "phase start: running relay-drive --round-cap $ROUND_CAP"
   396	
   397	# ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────
   398	
   399	# relay-drive runs a bare executable --agent-cmd path directly (space-safe, even ".../GH Repos/..."),
   400	# falling back to eval only for command strings — so we pass the path as-is, no %q quoting needed.
   401	relay_exit=0
   402	target_root_args=()
   403	[[ -n "$TARGET_ROOT" ]] && target_root_args=(--target-root "$TARGET_ROOT")
   404	# GH-75: the nested relay loop reaches its own terminal exit once PER PHASE. Force its XYZ.json hook
   405	# silent (XYZ_HARNESS_CONTEXT=marathon-phase) so a per-phase relay completion never emits its own
   406	# record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
   407	# scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
   408	# its hook below.
   409	RELAY_FILE="$RELAY_FILE" \
   410	LANE_ATTEMPT_COUNTED=1 \
   411	XYZ_HARNESS_CONTEXT=marathon-phase \
   412	  "$RELAY_DRIVE_BIN" \
   413	    --relay-file "$RELAY_FILE" \
   414	    --relay-task "$RELAY_TASK" \
   415	    --agent-cmd  "$AGENT_CMD" \
   416	    --round-cap  "$ROUND_CAP" \
   417	    ${target_root_args[@]+"${target_root_args[@]}"} \
   418	  || relay_exit=$?
   419	
   420	# ── Step 6: act on relay-drive exit code ───────────────────────────────────
   421	
   422	escalate() {  # <reason> <relay-exit>
   423	  local reason="$1" rexit="$2"
   424	  cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
   425	# ESCALATION — Marathon Phase ${PHASE_ID}
   426	
   427	phase: ${PHASE_ID}
   428	task: ${RELAY_TASK}
   429	relay-drive-exit: ${rexit}
   430	reason: ${reason}
   431	relay-file: ${REL_RELAY}
   432	ESC_EOF
   433	  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
   434	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
   435	  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
   436	  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
   437	}
   438	
   439	save_transcript() {
   440	  # GH-30 Phase 2: resolve the transcript base (honors XYZ_ARCHIVE_ROOT; hard-errors if set-invalid).
   441	  # Declare then assign separately so the resolver's exit code isn't masked by `local` under set -e.
   442	  local date_dir _ts_base; _ts_base="$(rtl_transcript_root "$ROOT")" || return 1
   443	  date_dir="$_ts_base/$(date +%Y-%m-%d)"
   444	  mkdir -p "$date_dir"
   445	  local ts; ts="$(date +%H%M%S)"
   446	  local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
   447	  cp "$RELAY_FILE" "$dest"
   448	  git -C "$ROOT" add -- "$dest"
   449	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
   450	  log "transcript saved: $dest"
   451	}
   452	
   453	case "$relay_exit" in
   454	  0)
   455	    # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
   456	    log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
   457	    gate_exit=0
   458	    # Gate belongs to the target repo when --target-root is set (e.g. a foreign repo's `npm test`).
   459	    ( [[ -n "$TARGET_ROOT" ]] && cd "$TARGET_ROOT"; eval "$PRE_ADVANCE_CMD" ) || gate_exit=$?
   460	    if [[ "$gate_exit" -ne 0 ]]; then
   461	      log "pre-advance gate FAILED (exit $gate_exit) — escalating"
   462	      escalate "pre-advance-failed" "$relay_exit"
   463	      xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
   464	      exit 5
   465	    fi
   466	    "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
   467	    lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID"   # GH-45: success clears the attempt counter
   468	    save_transcript
   469	    log "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
   470	    xyz_marathon_emit green "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
   471	    exit 0
   472	    ;;
   473	  3)
   474	    log "relay escalated: no-progress (relay-drive exit 3)"
   475	    escalate "no-progress" 3
   476	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay no-progress"
   477	    exit 3
   478	    ;;
   479	  4)
   480	    log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
   481	    escalate "cap-or-close-mismatch" 4
   482	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay cap/close-mismatch"
   483	    exit 4
   484	    ;;
   485	  6)
   486	    # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
   487	    # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
   488	    # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
   489	    # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
   490	    log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
   491	    escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
   492	    xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
   493	    exit 6
   494	    ;;
   495	  *)
   496	    die "relay-drive exited with unexpected code $relay_exit"
   497	    ;;
   498	esac

exec
/bin/zsh -lc "nl -ba relay-automation/relay-drive.sh | sed -n '1,420p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# relay-drive.sh — Phase 4(a): supervise a /relay thread to termination, with the
     5	# turn-token held as a tick **RELAY-TURN task** (claim / ping / release --to / done).
     6	#
     7	# This is the SUPERVISOR, not the turn-taker. Each turn is taken by --agent-cmd
     8	# (a fake in tests; the baton/live window in Option B; a headless CLI in a future
     9	# Option A). The turn-taker owns the work + thread mutation — it claims/resumes the
    10	# RELAY-TURN task as RELAY_AGENT, `tick ping`s it, appends its block + sets the
    11	# file's STATUS/verdict, then **`tick release RELAY-TURN --to <other>`** to hand off
    12	# (or **`tick done RELAY-TURN`** + STATUS: Approved on the final turn), and commits.
    13	#
    14	# Whose-turn is the tick token (so the Phase-1 handoff-exclusive rule applies and the
    15	# Phase-2 watchdog can see a stalled turn). The human-readable thread's STATUS is the
    16	# terminal (Approved/Closed) signal. The supervisor only:
    17	#   - reads the RELAY-TURN actor + the file STATUS to decide whether to continue,
    18	#   - invokes the turn-taker for the current actor,
    19	#   - enforces a round cap, and
    20	#   - escalates on no-progress (token actor didn't move) instead of looping forever.
    21	#
    22	# Turn-taker env: RELAY_FILE, RELAY_TASK, RELAY_AGENT (the current actor).
    23	# Exit: 0 = relay closed Approved/Closed · 3 = no-progress (stall) · 4 = cap / closed-not-approved /
    24	#       escalated-to-human-by-design (STATUS: Escalated) · 5 = review-once: reviewer completed a turn
    25	#       (non-approval handback — a successful single review, NOT a stall) ·
    26	#       8 = lane parked (GH-45 attempt cap — no token seeded; re-fire with --force) · 2 = usage.
    27	
    28	ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    29	# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
    30	# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT_DIR/relay-system". Sourced beside this script.
    31	source "$(dirname "${BASH_SOURCE[0]}")/relay-turn-lib.sh"
    32	TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
    33	CONSULT_SH="${CONSULT_SH:-"$ROOT_DIR/relay-automation/consult.sh"}"
    34	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT_DIR/utils/telemetry/append-xyz-completion.sh"}"
    35	
    36	# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
    37	# lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
    38	# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
    39	# token. --force bypasses for one fire and logs it. lane_attempt_reset clears the counter when a lane
    40	# COMPLETES successfully (Approved), so the cap counts CONSECUTIVE failures and can never permanently
    41	# wedge a lane (reviewer feedback: without a reset a default-keyed lane parks forever). A nested call
    42	# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
    43	# reset) exactly once. Byte-consistent mirror in marathon-drive.sh; relay-turn-lib.sh/bin/tick untouched.
    44	_lane_key() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
    45	lane_attempt_gate() {
    46	  local root="$1" raw="$2" force="${3:-0}"
    47	  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
    48	  [ -n "$raw" ] || return 0
    49	  local max="${LANE_MAX_ATTEMPTS:-2}"; case "$max" in ''|*[!0-9]*) max=2 ;; esac
    50	  local key dir file count; key=$(_lane_key "$raw"); dir="$root/.tick/attempts"; file="$dir/$key"
    51	  mkdir -p "$dir" 2>/dev/null || true
    52	  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
    53	  if [ "$force" = "1" ]; then
    54	    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
    55	  elif [ "$count" -ge "$max" ]; then
    56	    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
    57	    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
    58	    return 8
    59	  fi
    60	  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
    61	  return 0
    62	}
    63	lane_attempt_reset() {  # clear a lane's counter after it completes successfully (Approved)
    64	  local root="$1" raw="$2"
    65	  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
    66	  [ -n "$raw" ] || return 0
    67	  rm -f "$root/.tick/attempts/$(_lane_key "$raw")" 2>/dev/null || true
    68	}
    69	
    70	# GH-75: append ONE final-completion record to XYZ.json at the harness repo root when a STANDALONE
    71	# /relay session terminates. Stays SILENT when this relay-drive runs nested inside a marathon/swarm
    72	# phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
    73	# outer harness owns the whole-run record, so a per-phase relay completion must not double-emit.
    74	# Best-effort: a telemetry failure must never change the relay's own exit path.
    75	xyz_relay_emit() {  # <health>
    76	  case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
    77	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
    78	  local health="$1" slug title s desc
    79	  slug="$(basename "$RELAY_FILE" .md)"
    80	  title="$(grep -m1 '^# ' "$RELAY_FILE" 2>/dev/null | sed 's/^#[[:space:]]*//; s/[[:space:]]*$//')" || true
    81	  [[ -n "$title" ]] || title="$slug"
    82	  s="$(file_status)"
    83	  desc="Relay session ended: STATUS ${s:-unknown} (health ${health})."
    84	  "$XYZ_APPEND_BIN" relay "$slug" "$health" "$title" "$desc" >/dev/null 2>&1 || true
    85	}
    86	
    87	if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
    88	  # The driver lock lives in .git/ (never committed) for a normal harness clone. A GH-49 vendored
    89	  # .xyz/ copy has no .git/, so mkdir'ing a lock there would fail — fall back to a hidden lock beside
    90	  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
    91	  # the same). When .git/ exists the path is unchanged, so a normal clone behaves byte-identically.
    92	  if [[ -d "$ROOT_DIR/.git" ]]; then
    93	    _lock="$ROOT_DIR/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    94	  else
    95	    _lock="$ROOT_DIR/.relay-driver.lock";     _lock_label=".relay-driver.lock"
    96	  fi
    97	  if ! mkdir "$_lock" 2>/dev/null; then
    98	    # GH-42 self-heal: reclaim the lock only if its holder is dead. A crashed/killed driver used to
    99	    # leave a stale lock that blocked every later run until a manual rmdir.
   100	    _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
   101	    if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
   102	      printf 'relay-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
   103	      printf 'relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
   104	      exit 1
   105	    fi
   106	    printf 'relay-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
   107	    rm -rf "$_lock"
   108	    mkdir "$_lock" 2>/dev/null || { printf 'relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
   109	  fi
   110	  printf '%s\n' "$$" > "$_lock/pid"
   111	  trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
   112	  export RELAY_DRIVER_LOCKED=1
   113	fi
   114	
   115	usage() {
   116	  cat <<'EOF'
   117	Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]
   118	
   119	  --relay-file PATH   The relay thread (reads STATUS: as the terminal signal).
   120	  --agent-cmd CMD     Turn-taker; invoked with env RELAY_FILE + RELAY_TASK + RELAY_AGENT.
   121	                      Must take the turn on the RELAY-TURN task (claim/ping/append/
   122	                      release --to <other> | done) and commit.
   123	  --relay-task ID     The relay turn-token task (default: RELAY-TURN).
   124	  --round-cap N       Max turns before escalating (default: 6).
   125	  --target-root DIR   The target git repository root (must be an existing git repo).
   126	  --consult-verify    After each turn, invoke consult.sh to independently challenge the
   127	                      turn-taker's VERDICT. Fires 1-2 real API calls per turn (codex +
   128	                      gemini). Do NOT use in CI or budget-sensitive runs.
   129	  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
   130	                      isolated worktree at .relay-artifacts/<basename> so the reviewer can READ it
   131	                      without it being committed into the target repo. Requires worktree isolation
   132	                      (the default). The reviewer may not edit it (an edit fails the turn). Implements #15.
   133	  --review-once       Drive exactly ONE turn (a single review) and classify its outcome:
   134	                      Approved/Closed -> 0; a completed non-approval handback ("changes
   135	                      requested") -> 5 (NOT the stall's 3); reviewer-did-nothing stall -> 3;
   136	                      Escalated -> 4. Forces --round-cap 1.
   137	  --force             GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
   138	  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
   139	  --help
   140	EOF
   141	}
   142	
   143	die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }
   144	
   145	RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0; CONSULT_VERIFY=0; REVIEW_ONCE=0; ARTIFACT_FILE=""; FORCE=0
   146	while (($# > 0)); do
   147	  case "$1" in
   148	    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
   149	    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
   150	    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
   151	    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
   152	    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
   153	    --consult-verify) CONSULT_VERIFY=1; shift ;;
   154	    --review-once) REVIEW_ONCE=1; shift ;;
   155	    --artifact-file) ARTIFACT_FILE="${2:-}"; shift 2 ;;
   156	    --force) FORCE=1; shift ;;      # GH-45: bypass the per-lane attempt cap for this one fire
   157	    --dry-run) DRY_RUN=1; shift ;;
   158	    --help) usage; exit 0 ;;
   159	    *) die "unknown argument: $1" ;;
   160	  esac
   161	done
   162	[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
   163	[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }
   164	
   165	# --review-once drives a single review turn; its success oracle (a completed non-approval handback
   166	# exits 5, not the stall's 3) replaces the multi-round no-progress/cap logic, so force the cap to 1.
   167	((REVIEW_ONCE)) && ROUND_CAP=1
   168	
   169	if [[ -n "${TARGET_ROOT+set}" ]]; then
   170	  [[ -n "$TARGET_ROOT" ]] || die "--target-root requires a non-empty path"   # else git -C '' falls back to CWD
   171	  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
   172	    || die "invalid target root (not a git repo): $TARGET_ROOT"
   173	  export RELAY_TARGET_ROOT="$TARGET_ROOT"
   174	fi
   175	
   176	# Resolve --relay-file AFTER --target-root is known. With --target-root the thread lives in the
   177	# TARGET repo, so a repo-relative path must resolve relative to the target root, not the harness CWD
   178	# (GH-18 #2): if it isn't found as given but exists under --target-root, use that. Absolute paths and
   179	# CWD-relative paths that already resolve are unchanged. (ALLOW_PATHS is already target-relative — the
   180	# shim resolves it against RELAY_TARGET_ROOT in relay-turn-lib.sh.)
   181	if [[ ! -f "$RELAY_FILE" && -n "${TARGET_ROOT:-}" && "$RELAY_FILE" != /* && -f "$TARGET_ROOT/$RELAY_FILE" ]]; then
   182	  RELAY_FILE="$TARGET_ROOT/$RELAY_FILE"
   183	fi
   184	[[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
   185	
   186	# GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
   187	# dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
   188	if ((DRY_RUN == 0)) && ((REVIEW_ONCE == 0)); then
   189	  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
   190	  # stay hermetic; a real standalone run falls back to this clone.
   191	  lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK" "$FORCE" || exit $?
   192	fi
   193	
   194	# Containment default for unattended/driven runs: isolate the turn-taker in a throwaway worktree
   195	# (ROOT@HEAD) so an off-task model's stray creations/renames can't reach the real tree. The leaf
   196	# shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
   197	# DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
   198	# shim use keeps the leaf default OFF — only the orchestration layer defaults it ON.)
   199	: "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION
   200	
   201	# GH-32 #1: under worktree isolation the turn-taker runs in a throwaway worktree at ROOT@HEAD, so a
   202	# relay file that isn't committed at HEAD is INVISIBLE to it (untracked-not-ignored — relay-system/ is
   203	# tracked here except two specific files). The reviewer then "finds nothing" and silently does no work.
   204	# Warn loudly with the exact remedy; never block (a non-isolated run is free to use an uncommitted file,
   205	# and a relay file outside any git repo is fine too). Mirrors the cross-repo warning style in the shims.
   206	warn_if_relay_file_untracked() {
   207	  [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
   208	  local dir prefix rel
   209	  dir="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd)" || return 0   # not a real dir → skip
   210	  # --show-prefix yields the repo-root-relative path of $dir (empty at root); building the relative
   211	  # path this way avoids subtracting an absolute toplevel, which breaks under macOS /var → /private/var
   212	  # symlinks (logical pwd vs git's physical toplevel).
   213	  prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || return 0  # not in a git repo → skip
   214	  rel="${prefix}$(basename "$RELAY_FILE")"
   215	  git -C "$dir" cat-file -e "HEAD:$rel" 2>/dev/null && return 0           # present at HEAD → visible
   216	  printf 'relay-drive: WARNING — relay file is not committed at HEAD: %s\n' "$rel" >&2
   217	  printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, so this untracked\n' >&2
   218	  printf '  file is INVISIBLE to the reviewer (it will find nothing and do no work). Remedy: commit\n' >&2
   219	  printf '  the relay file first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
   220	}
   221	warn_if_relay_file_untracked
   222	
   223	# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
   224	# and export it so relay-turn-lib seeds it into the isolated worktree. It only works under isolation —
   225	# warn loudly if isolation is off, so the reviewer isn't left silently unable to see it.
   226	if [[ -n "$ARTIFACT_FILE" ]]; then
   227	  [[ -f "$ARTIFACT_FILE" ]] || die "artifact file not found: $ARTIFACT_FILE"
   228	  case "$ARTIFACT_FILE" in
   229	    /*) : ;;
   230	    *)  ARTIFACT_FILE="$(cd "$(dirname "$ARTIFACT_FILE")" && pwd)/$(basename "$ARTIFACT_FILE")" ;;
   231	  esac
   232	  export RELAY_ARTIFACT_FILE="$ARTIFACT_FILE"
   233	  [[ "$RELAY_WORKTREE_ISOLATION" != 0 ]] || \
   234	    printf 'relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.\n' >&2
   235	fi
   236	
   237	file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
   238	terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
   239	# Escalated is TERMINAL BY DESIGN: the reviewer handed back to a human (e.g. at the round cap),
   240	# typically WITHOUT releasing the token. The explicit status IS the intent signal — a true stall
   241	# leaves STATUS unchanged — so this is NOT a no-progress failure. Reported as a clean, distinct
   242	# outcome (exit 4 = terminal/not-approved) so a correct handback doesn't read as a stall (GH-18 #5).
   243	escalated_status() { case "$1" in Escalated) return 0 ;; *) return 1 ;; esac; }
   244	
   245	# Current actor of the RELAY-TURN token: claimer (if claimed) else handoff_to (if
   246	# open) else "" (done/missing). Echoes "<status>\t<actor>".
   247	token_state() {
   248	  local info status claimer handoff actor
   249	  info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null || true)"
   250	  status="$(printf '%s\n' "$info"  | sed -n 's/^status:[[:space:]]*//p'     | head -1)"
   251	  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
   252	  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
   253	  case "$status" in
   254	    claimed) actor="$claimer" ;;
   255	    open)    actor="$handoff" ;;
   256	    *)       actor="" ;;
   257	  esac
   258	  printf '%s\t%s\n' "$status" "$actor"
   259	}
   260	
   261	round=0
   262	while ((round < ROUND_CAP)); do
   263	  s="$(file_status)"
   264	  IFS=$'\t' read -r tstatus actor < <(token_state)
   265	
   266	  # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
   267	  # token no longer live (done/gone). file-terminal-but-token-live is a leaked
   268	  # close — escalate, never report success. (Codex r1 Blocker.)
   269	  if terminal_status "$s"; then
   270	    if [[ -n "$actor" ]]; then
   271	      printf 'relay-drive: STATUS %s but RELAY-TURN still live (%s/%s) — close mismatch, escalating\n' "$s" "$tstatus" "$actor" >&2
   272	      exit 4
   273	    fi
   274	    printf 'relay-drive: relay terminated (STATUS: %s, token done) after %d turn(s)\n' "$s" "$round"
   275	    lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK"   # GH-45: success clears the attempt counter
   276	    xyz_relay_emit green
   277	    exit 0
   278	  fi
   279	
   280	  # Escalated = terminal by design (handback to human); the token may legitimately stay live, so this
   281	  # is checked BEFORE the no-actor branch. A clean, distinct outcome — not a stall (GH-18 #5).
   282	  if escalated_status "$s"; then
   283	    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s) after %d turn(s)\n' "$s" "${actor:-done}" "$round" >&2
   284	    xyz_relay_emit orange
   285	    exit 4
   286	  fi
   287	
   288	  # file not terminal but the token is gone/done → also a mismatch.
   289	  if [[ -z "$actor" ]]; then
   290	    printf 'relay-drive: %s has no actor (token %s) but STATUS=%s — escalating\n' "$RELAY_TASK" "${tstatus:-missing}" "$s" >&2
   291	    # A `done` token under a non-terminal thread is the classic reused-token collision (GH-18 #1):
   292	    # a prior relay spent this id. Point at the fix so recovery isn't a scavenger hunt.
   293	    [[ "$tstatus" == "done" ]] && printf "  → '%s' is spent from a prior relay; seed + drive with a fresh --relay-task (e.g. RELAY-%s)\n" "$RELAY_TASK" "$(basename "$RELAY_FILE" .md)" >&2
   294	    exit 4
   295	  fi
   296	
   297	  if ((DRY_RUN)); then
   298	    printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
   299	  fi
   300	
   301	  prev="$tstatus:$actor"
   302	  RELAY_FILE="$RELAY_FILE" RELAY_TASK="$RELAY_TASK" RELAY_AGENT="$actor"
   303	  export RELAY_FILE RELAY_TASK RELAY_AGENT
   304	  # Invoke the turn-taker. A bare executable path (even absolute or containing spaces, e.g. a clone
   305	  # under ".../GH Repos/...") is run DIRECTLY so it survives spaces; a full command string
   306	  # (env-prefixed, shell-quoted, or %q-escaped by a caller) falls back to eval. This fixes spaced
   307	  # absolute --agent-cmd paths without breaking the command-string contract callers/tests rely on.
   308	  if [[ -x "$AGENT_CMD" ]]; then
   309	    "$AGENT_CMD"
   310	  else
   311	    eval "$AGENT_CMD"
   312	  fi
   313	  round=$((round + 1))
   314	
   315	  # --consult-verify: independent second opinion after each turn.
   316	  # Invokes consult.sh (codex + gemini) to challenge the turn-taker's self-reported VERDICT.
   317	  # On divergence: appends a conflict-warning advisory block, sets STATUS: Escalated, exits 4.
   318	  if ((CONSULT_VERIFY)); then
   319	    _cv_taker_verdict="$(sed -n '/^## Log/,$p' "$RELAY_FILE" | grep -E '^VERDICT: ' | tail -1 | sed 's/^VERDICT: //')"
   320	    _cv_label="consult-verify-$(basename "$RELAY_FILE" .md)-r${round}"
   321	    # GH-30 Phase 2: consult-verify transcripts follow the resolver (honors XYZ_ARCHIVE_ROOT). The
   322	    # relay thread + token stay in ROOT_DIR; only this transcript side can redirect. Hard-error loud.
   323	    _cv_out_dir="$(rtl_transcript_root "$ROOT_DIR")/$(date +%F)" || exit 1
   324	    # Write prompt to a temp file — avoids nested variable expansion fragility inside $()
   325	    _cv_prompt_file="$(mktemp -t cv-prompt.XXXXXX)"
   326	    printf 'Review the most recent log block in this relay file. Does the turn-taker'"'"'s VERDICT match their stated evidence in the Basis: line? Reply with exactly one of: AGREE-PASS (verdict supported), AGREE-FAIL (verdict supported), or DISAGREE (verdict not supported by evidence). One token only.\n\n=== RELAY FILE ===\n' > "$_cv_prompt_file"
   327	    cat "$RELAY_FILE" >> "$_cv_prompt_file"
   328	    _cv_consult_out="$(CONSULT_ROOT="$ROOT_DIR" "$CONSULT_SH" \
   329	      --prompt-file "$_cv_prompt_file" \
   330	      --label "$_cv_label" \
   331	      --out "$_cv_out_dir" 2>/dev/null)" || true
   332	    rm -f "$_cv_prompt_file"
   333	
   334	    # Parse advisor verdicts from transcript file paths in consult stdout ([ok] model -> path)
   335	    _cv_diverged=0; _cv_advisor_summary=""
   336	    while IFS= read -r _cv_line; do
   337	      _cv_path="$(printf '%s\n' "$_cv_line" | sed -n 's/.*-> //p' | sed 's/[[:space:]]*$//')"
   338	      [[ -z "$_cv_path" || ! -f "$_cv_path" ]] && continue
   339	      _cv_model="$(printf '%s\n' "$_cv_line" | sed -n 's/.*\[ok\][[:space:]]*//p' | sed 's/[[:space:]]*->.*$//' | sed 's/[[:space:]]*$//')"
   340	      _cv_response="$(grep -oE '(AGREE-PASS|AGREE-FAIL|DISAGREE)' "$_cv_path" | head -1 || true)"
   341	      [[ -z "$_cv_response" ]] && _cv_response="(no verdict found)"
   342	      _cv_advisor_summary+="${_cv_model:-advisor}: $_cv_response"$'\n'
   343	      [[ "$_cv_response" == "DISAGREE" ]] && _cv_diverged=1
   344	    done < <(printf '%s\n' "$_cv_consult_out")
   345	
   346	    if ((_cv_diverged)); then
   347	      printf 'relay-drive: consult-verify DIVERGENCE after %s turn (taker: %s)\n%s' \
   348	        "$actor" "$_cv_taker_verdict" "$_cv_advisor_summary" >&2
   349	      # Append conflict-warning advisory block (MUST include VERDICT: + Basis: for bin/validate-relay-block)
   350	      printf '\n### consult-verify advisory — divergence detected (round %d)\n\nVERDICT: FAIL\nBasis: consult disagreed with turn-taker verdict "%s" (see transcripts)\n%s\nTurn-taker self-reported: %s\n' \
   351	        "$round" "$_cv_taker_verdict" "$_cv_advisor_summary" "$_cv_taker_verdict" >> "$RELAY_FILE"
   352	      # Set STATUS: Escalated
   353	      sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Escalated/' "$RELAY_FILE"
   354	      _cv_relay_repo="$(git -C "$(dirname "$RELAY_FILE")" rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")"
   355	      git -C "$_cv_relay_repo" add "$RELAY_FILE" 2>/dev/null || true
   356	      git -C "$_cv_relay_repo" commit -m "relay-drive: consult-verify divergence escalation (round $round)" 2>/dev/null || true
   357	      printf 'relay-drive: relay escalated by consult-verify (STATUS: Escalated) after %d turn(s)\n' "$round" >&2
   358	      exit 4
   359	    else
   360	      printf 'relay-drive: consult-verify AGREED after %s turn (taker: %s)\n' "$actor" "$_cv_taker_verdict" >&2
   361	    fi
   362	  fi
   363	
   364	  # No-progress guard (skipped once terminal — the close check at loop top handles that).
   365	  IFS=$'\t' read -r ntstatus nactor < <(token_state)
   366	  ns="$(file_status)"
   367	  # A by-design Escalated handback this turn is terminal, NOT a stall — even if the reviewer left the
   368	  # token live. Catch it before the no-progress guard so it doesn't read as exit 3 (GH-18 #5).
   369	  if escalated_status "$ns"; then
   370	    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s:%s) after %d turn(s)\n' "$ns" "$ntstatus" "$nactor" "$round" >&2
   371	    xyz_relay_emit orange
   372	    exit 4
   373	  fi
   374	  # --review-once: the single review turn is complete. Classify with a review oracle so a correct
   375	  # "changes requested" handback is NOT conflated with a no-progress stall (GH-32 #2). Mirrors the
   376	  # Escalated carve-out above — a reviewer that actually DID something is a success, not exit 3.
   377	  if ((REVIEW_ONCE)); then
   378	    # --review-once bypasses the loop's normal terminal/cap exits, so it needs its own XYZ.json emits
   379	    # (approval → green, a completed changes-requested handback → orange, a genuine stall → red) — else
   380	    # this repo's own recommended one-shot review flow would never record a completion (GH-75 review).
   381	    if terminal_status "$ns"; then
   382	      printf 'relay-drive: review-once — reviewer approved/closed (STATUS: %s) after 1 turn\n' "$ns"
   383	      xyz_relay_emit green
   384	      exit 0
   385	    fi
   386	    if [[ "$ntstatus:$nactor" != "$prev" || "$ns" != "$s" ]]; then
   387	      printf 'relay-drive: review-once — reviewer completed a turn (STATUS: %s, token %s:%s); non-approval handback, not a stall\n' "$ns" "$ntstatus" "$nactor"
   388	      xyz_relay_emit orange
   389	      exit 5
   390	    fi
   391	    printf 'relay-drive: review-once — reviewer took no action (STATUS unchanged: %s, token still %s) — genuine stall\n' "$ns" "$prev" >&2
   392	    xyz_relay_emit red
   393	    exit 3
   394	  fi
   395	
   396	  if ! terminal_status "$ns" && [[ "$ntstatus:$nactor" == "$prev" ]]; then
   397	    printf 'relay-drive: no progress after %s turn (token still %s) — escalating\n' "$actor" "$prev" >&2
   398	    xyz_relay_emit red
   399	    exit 3
   400	  fi
   401	done
   402	
   403	# Cap reached: success only if file terminal AND token not live (same agreement).
   404	s="$(file_status)"; IFS=$'\t' read -r tstatus actor < <(token_state)
   405	if terminal_status "$s" && [[ -z "$actor" ]]; then
   406	  printf 'relay-drive: relay terminated (STATUS: %s)\n' "$s"; xyz_relay_emit green; exit 0
   407	fi
   408	printf 'relay-drive: round cap (%d) exceeded (STATUS: %s, token actor: %s) — escalating\n' "$ROUND_CAP" "$s" "${actor:-none}" >&2
   409	xyz_relay_emit red
   410	exit 4

exec
/bin/zsh -lc "nl -ba utils/swarm-preflight.sh | sed -n '1,760p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# utils/swarm-preflight.sh — one durable intake planner for marathon runs (GH-25).
     3	#
     4	# Turns EITHER a single project doc OR an explicit bundle of GitHub issues into a
     5	# marathon-ready run packet: it normalizes both inputs into one shape, checks branch
     6	# freshness, proves the fix is still required, gates remediation readiness, assigns
     7	# Codex/agy lanes, and emits a self-contained packet the orchestrator hands to
     8	# relay-automation/marathon-drive.sh. It is the PRODUCER of the packet, never the
     9	# executor of the marathon (GUIDING-PRINCIPLES.md §8 — the operator decides).
    10	#
    11	# The planner reads the EXECUTION SURFACE OF RECORD, never a raw issue thread
    12	# (GUIDING-PRINCIPLES.md §11): every --gh-issue must already have an in-repo GH-* capture
    13	# doc, and that doc must carry a machine-readable preflight contract. The contract is a
    14	# single fenced ```json block under a heading matching /preflight contract/i, e.g.:
    15	#
    16	#     ## Swarm Preflight Contract
    17	#     ```json
    18	#     {
    19	#       "target":      { "repo": ".", "ref": "main" },
    20	#       "gate":        "bash validate.sh",
    21	#       "fix_probes":  [ { "type": "path_absent", "path": "utils/swarm-preflight.sh" } ],
    22	#       "artifacts":   [ "utils/swarm-preflight.sh", "test/swarm-preflight.sh" ],
    23	#       "remediation": { "source": "self#phases", "criteria": "Phases 1-7 of GH-25" },
    24	#       "lanes":       { "agy_safe": [], "orchestrator_only": [ "bin/", ".tick/" ] }
    25	#     }
    26	#     ```
    27	#
    28	# Usage:
    29	#   utils/swarm-preflight.sh --project-doc PROJECT/2-WORKING/GH-25-*.md
    30	#   utils/swarm-preflight.sh --gh-issue 25 --gh-issue 26 [--target-root REPO]
    31	#   utils/swarm-preflight.sh --project-doc DOC --dry-run        # checks only, no packet written
    32	#
    33	# Exit: 0 ready (packet emitted) · 2 usage · 3 contract missing/invalid ·
    34	#       4 stale/already-landed (fix not required) · 5 not marathon-ready ·
    35	#       6 blocked/missing-target · 7 ambiguous.
    36	#
    37	# Branch prompt (GH-69) — orchestrating-agent contract: a ready packet's provenance carries
    38	# `suggested_branch` (deterministic: marathon/<slug>-<run-date>) and `branch_ready` (does it already
    39	# exist?). If `branch_ready: false` and `skip_branch_prompt: false`, ASK THE OPERATOR before invoking
    40	# marathon-drive.sh — "This lane will commit to <branch>. Suggested branch: <suggested_branch>. Cut it
    41	# now? [yes / no / custom name]" (never auto-cut — GUIDING-PRINCIPLES.md §8). `skip_branch_prompt: true`
    42	# (risk==1 in the doc frontmatter AND an independent-zone artifact set — no kernel/shim path) means
    43	# proceed on the current branch without asking. packet.md/packet.json both carry these fields inline,
    44	# and the packet.md "Suggested branch" line already states which of the two applies — a driving agent
    45	# reading the packet doesn't need to recompute it.
    46	
    47	set -uo pipefail
    48	
    49	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    50	# Vendored install: HERE is <target>/.xyz/utils → parent is .xyz → target root is grandparent.
    51	_here_parent="$(cd "$HERE/.." && pwd)"
    52	if [ "$(basename "$_here_parent")" = ".xyz" ]; then
    53	  ROOT="${SWARM_PREFLIGHT_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
    54	  _DRIVE_CMD=".xyz/relay-automation/marathon-drive.sh"
    55	else
    56	  ROOT="${SWARM_PREFLIGHT_ROOT:-"$_here_parent"}"
    57	  _DRIVE_CMD="relay-automation/marathon-drive.sh"
    58	fi
    59	# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
    60	# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". relay-turn-lib.sh is a sibling
    61	# dir of utils/ (both under the harness root, or both under .xyz/ in a vendored install).
    62	source "$HERE/../relay-automation/relay-turn-lib.sh"
    63	NOW="${SWARM_PREFLIGHT_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
    64	TODAY="${SWARM_PREFLIGHT_TODAY:-"$(date -u +%Y-%m-%d)"}"
    65	
    66	die()  { printf 'swarm-preflight: %s\n' "$*" >&2; exit 2; }
    67	log()  { printf 'swarm-preflight: %s\n' "$*" >&2; }
    68	emit() { printf '%s\n' "$*"; }   # stdout: operator-facing report lines
    69	
    70	usage() {
    71	  cat <<'EOF'
    72	Usage: utils/swarm-preflight.sh (--project-doc DOC | --gh-issue N [--gh-issue N ...]) [options]
    73	
    74	  --project-doc DOC     One PROJECT/**.md doc to plan from (mutually exclusive with --gh-issue).
    75	  --gh-issue N          A GitHub issue number; repeatable for an explicit bundle. Each issue must
    76	                        have an in-repo GH-<N>-*.md capture doc carrying a preflight contract.
    77	  --target-root REPO    Repo the marathon would act on (default: this repo root).
    78	  --out DIR             Packet output directory (default: relay-system/preflight/<date>/<slug>).
    79	  --format text|json    Report format on stdout (default: text). JSON emits the normalized object.
    80	  --dry-run             Run all checks and print the verdict, but do NOT write the packet directory.
    81	  --help                Show this help.
    82	
    83	Exit: 0 ready · 2 usage · 3 contract missing/invalid · 4 stale/already-landed ·
    84	      5 not marathon-ready · 6 blocked/missing-target · 7 ambiguous.
    85	EOF
    86	}
    87	
    88	# ── arg parsing ──────────────────────────────────────────────────────────────
    89	PROJECT_DOC=""
    90	GH_ISSUES=()
    91	TARGET_ROOT=""
    92	OUT_DIR=""
    93	FORMAT="text"
    94	DRY_RUN=0
    95	
    96	while (($# > 0)); do
    97	  case "$1" in
    98	    --project-doc) PROJECT_DOC="${2:-}"; shift 2 ;;
    99	    --gh-issue)    GH_ISSUES+=("${2:-}"); shift 2 ;;
   100	    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
   101	    --out)         OUT_DIR="${2:-}"; shift 2 ;;
   102	    --format)      FORMAT="${2:-}"; shift 2 ;;
   103	    --dry-run)     DRY_RUN=1; shift ;;
   104	    --help)        usage; exit 0 ;;
   105	    *)             usage; die "unknown argument: $1" ;;
   106	  esac
   107	done
   108	
   109	# ── mode resolution: exactly one input mode (Phase 1) ────────────────────────
   110	if [[ -n "$PROJECT_DOC" && ${#GH_ISSUES[@]} -gt 0 ]]; then
   111	  usage; die "--project-doc and --gh-issue are mutually exclusive; pick one input mode"
   112	fi
   113	if [[ -z "$PROJECT_DOC" && ${#GH_ISSUES[@]} -eq 0 ]]; then
   114	  usage; die "one input mode required: --project-doc DOC or --gh-issue N"
   115	fi
   116	case "$FORMAT" in text|json) ;; *) die "--format must be 'text' or 'json'" ;; esac
   117	
   118	command -v node >/dev/null 2>&1 || die "node is required (Node stdlib only; no deps) but not found in PATH"
   119	
   120	# A throwaway workdir for the node programs + intermediate JSON; the packet dir is written at the end.
   121	TMP="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight.XXXXXX")"
   122	trap 'rm -rf "$TMP"' EXIT
   123	
   124	# ── node helper programs (written once, run with `VAR=val node file.mjs`) ─────
   125	# Writing to files (not heredoc-in-$()) avoids macOS bash 3.2 mis-parsing template
   126	# literals, and keeps env vars on the real `node` binary so process.env is populated.
   127	
   128	cat >"$TMP/extract-contract.mjs" <<'JS'
   129	import { readFileSync } from "node:fs";
   130	const doc = process.env.SP_DOC;
   131	const lines = readFileSync(doc, "utf8").split(/\r?\n/);
   132	const i = lines.findIndex(l => /^#{1,6}\s+.*preflight\s+contract/i.test(l));
   133	if (i < 0) { process.stderr.write(`no '## ... Preflight Contract' heading in ${doc}\n`); process.exit(3); }
   134	let start = -1;
   135	for (let j = i + 1; j < lines.length; j++) {
   136	  if (/^```json\s*$/i.test(lines[j])) { start = j + 1; break; }
   137	  if (/^#{1,6}\s+/.test(lines[j])) break;
   138	}
   139	if (start < 0) { process.stderr.write(`no fenced json block under the contract heading in ${doc}\n`); process.exit(3); }
   140	let end = -1;
   141	for (let j = start; j < lines.length; j++) { if (/^```\s*$/.test(lines[j])) { end = j; break; } }
   142	if (end < 0) { process.stderr.write(`unterminated json block in ${doc}\n`); process.exit(3); }
   143	let obj;
   144	try { obj = JSON.parse(lines.slice(start, end).join("\n")); }
   145	catch (e) { process.stderr.write(`invalid JSON contract in ${doc}: ${e.message}\n`); process.exit(3); }
   146	const get = (p) => p.split(".").reduce((o, k) => (o == null ? o : o[k]), obj);
   147	for (const [p, t] of [["target","object"],["target.repo","string"],["target.ref","string"],["gate","string"]]) {
   148	  const v = get(p);
   149	  if (v == null || (t === "string" && typeof v !== "string") || (t === "object" && typeof v !== "object")) {
   150	    process.stderr.write(`contract in ${doc} missing required field: ${p}\n`); process.exit(3);
   151	  }
   152	}
   153	if (!Array.isArray(obj.fix_probes) || obj.fix_probes.length === 0) {
   154	  process.stderr.write(`contract in ${doc} needs at least one fix_probes entry\n`); process.exit(3);
   155	}
   156	if (!Array.isArray(obj.artifacts) || obj.artifacts.length === 0) {
   157	  process.stderr.write(`contract in ${doc} needs at least one artifacts path\n`); process.exit(3);
   158	}
   159	process.stdout.write(JSON.stringify(obj));
   160	JS
   161	
   162	cat >"$TMP/merge-contracts.mjs" <<'JS'
   163	import { readFileSync } from "node:fs";
   164	const rows = readFileSync(process.env.SP_CONTRACTS, "utf8").trim().split(/\n/).map(s => JSON.parse(s));
   165	const base = rows[0];
   166	const out = {
   167	  target: { repo: base.target.repo, ref: base.target.ref },
   168	  gate: base.gate,
   169	  fix_probes: [...(base.fix_probes || [])],
   170	  artifacts: [...(base.artifacts || [])],
   171	  remediation: base.remediation || null,
   172	  lanes: {
   173	    agy_safe: [...((base.lanes || {}).agy_safe || [])],
   174	    orchestrator_only: [...((base.lanes || {}).orchestrator_only || [])],
   175	  },
   176	};
   177	for (const c of rows.slice(1)) {
   178	  if (c.target.repo !== out.target.repo || c.target.ref !== out.target.ref) {
   179	    process.stderr.write(`bundle disagreement: targets differ (${out.target.repo}@${out.target.ref} vs ${c.target.repo}@${c.target.ref})\n`);
   180	    process.exit(7);
   181	  }
   182	  if (c.gate !== out.gate) { process.stderr.write(`bundle disagreement: gate commands differ\n`); process.exit(7); }
   183	  out.fix_probes.push(...(c.fix_probes || []));
   184	  for (const a of c.artifacts || []) if (!out.artifacts.includes(a)) out.artifacts.push(a);
   185	  for (const a of (c.lanes || {}).agy_safe || []) if (!out.lanes.agy_safe.includes(a)) out.lanes.agy_safe.push(a);
   186	  for (const a of (c.lanes || {}).orchestrator_only || []) if (!out.lanes.orchestrator_only.includes(a)) out.lanes.orchestrator_only.push(a);
   187	}
   188	process.stdout.write(JSON.stringify(out));
   189	JS
   190	
   191	cat >"$TMP/eval-probes.mjs" <<'JS'
   192	import { readFileSync, existsSync, writeFileSync } from "node:fs";
   193	import { execSync } from "node:child_process";
   194	import { join } from "node:path";
   195	const root = process.env.SP_ROOT;
   196	const c = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
   197	const at = (p) => join(root, p || "");
   198	const probes = [], counts = { landed: 0, unfixed: 0, blocked: 0 };
   199	for (const p of c.fix_probes) {
   200	  let verdict = "unfixed"; // unfixed = fix still required (good); landed = already fixed; blocked = can't tell
   201	  try {
   202	    switch (p.type) {
   203	      case "path_absent":  if (existsSync(at(p.path))) verdict = "landed"; break;
   204	      case "path_present": if (!existsSync(at(p.path))) verdict = "blocked"; break;
   205	      case "grep_present":
   206	        if (!existsSync(at(p.path))) { verdict = "blocked"; break; }
   207	        if (!new RegExp(p.pattern).test(readFileSync(at(p.path), "utf8"))) verdict = "landed";
   208	        break;
   209	      case "grep_absent":
   210	        if (existsSync(at(p.path)) && new RegExp(p.pattern).test(readFileSync(at(p.path), "utf8"))) verdict = "landed";
   211	        break;
   212	      case "command": {
   213	        let rc = 0;
   214	        try { execSync(p.cmd, { cwd: root, stdio: "ignore" }); } catch { rc = 1; }
   215	        if (p.expect_nonzero ? rc === 0 : rc !== 0) verdict = "landed";
   216	        break;
   217	      }
   218	      default: verdict = "blocked";
   219	    }
   220	  } catch { verdict = "blocked"; }
   221	  counts[verdict]++;
   222	  probes.push({ type: p.type, path: p.path || null, verdict });
   223	}
   224	writeFileSync(process.env.SP_OUT, JSON.stringify(probes));
   225	const stale = counts.landed > 0 ? 1 : 0;
   226	const blocked = counts.blocked > 0 ? 1 : 0;
   227	const ambig = stale && counts.unfixed > 0 ? 1 : 0;
   228	process.stdout.write(`${stale} ${blocked} ${ambig}`);
   229	JS
   230	
   231	cat >"$TMP/lane-plan.mjs" <<'JS'
   232	import { readFileSync } from "node:fs";
   233	const c = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
   234	const arts = c.artifacts || [];
   235	const orchOnly = (c.lanes && c.lanes.orchestrator_only) || ["bin/", ".tick/", "relay-automation/relay-turn-lib.sh"];
   236	const agySafe = (c.lanes && c.lanes.agy_safe) || [];
   237	const isOrch = (p) => orchOnly.some(o => p === o || p.startsWith(o));
   238	const orchestrator = [], codex = [], agy = [];
   239	for (const a of arts) {
   240	  if (isOrch(a)) orchestrator.push(a);          // trust-critical kernel paths → orchestrator-only
   241	  else if (agySafe.includes(a)) agy.push(a);    // explicitly cleared for an agy builder slot
   242	  else codex.push(a);                            // default trusted code-writing lane
   243	}
   244	const topDir = (p) => p.split("/")[0];
   245	const coupled = arts.length > 1 && new Set(arts.map(topDir)).size === 1;
   246	const buildable = [...codex, ...agy];
   247	process.stdout.write(JSON.stringify({
   248	  orchestrator_owned: orchestrator,
   249	  codex_lane: codex,
   250	  agy_lane: agy,
   251	  agy_review_default: true,                       // agy's sanctioned role is reviewer-first (Phase 5)
   252	  coupling_warning: coupled ? "all artifacts share one top-level dir; treat as coupled" : null,
   253	  parallelizable: !coupled && buildable.length >= 2,
   254	  single_lane_only: coupled || buildable.length < 2,
   255	}));
   256	JS
   257	
   258	cat >"$TMP/normalize.mjs" <<'JS'
   259	import { readFileSync } from "node:fs";
   260	const e = process.env;
   261	const contract = JSON.parse(readFileSync(e.SP_CONTRACT, "utf8"));
   262	const probes = JSON.parse(readFileSync(e.SP_PROBES, "utf8"));
   263	const lanes = JSON.parse(readFileSync(e.SP_LANES, "utf8"));
   264	const docs = e.SP_DOCS.trim().split(/\n/).filter(Boolean);
   265	process.stdout.write(JSON.stringify({
   266	  schema: "swarm-preflight/run-candidate@1",
   267	  generated_at: e.SP_NOW,
   268	  mode: e.SP_MODE,
   269	  candidate: { slug: e.SP_SLUG },
   270	  provenance: {
   271	    source_docs: docs,
   272	    issues: e.SP_ISSUES ? e.SP_ISSUES.split(",").filter(Boolean) : [],
   273	    target_root: e.SP_ROOT,
   274	    branch: e.SP_BRANCH,
   275	    commit: e.SP_COMMIT,
   276	    suggested_branch: e.SP_SUGGESTED_BRANCH,
   277	    branch_ready: e.SP_BRANCH_READY === "1",
   278	    skip_branch_prompt: e.SP_SKIP_BRANCH_PROMPT === "1",
   279	  },
   280	  contract,
   281	  freshness: {
   282	    fetch_ok: e.SP_FETCH === "1",
   283	    upstream: e.SP_UP || null,
   284	    ahead: Number(e.SP_AHEAD || 0),
   285	    behind: Number(e.SP_BEHIND || 0),
   286	    dirty: e.SP_DIRTY === "1",
   287	    evaluated_ref: e.SP_REF || null,
   288	    evaluated_ref_commit: e.SP_REF_COMMIT || null,
   289	    checkout_matches_ref: e.SP_CHECKOUT_MATCHES_REF === "1",
   290	    head_behind_ref: Number(e.SP_HEAD_BEHIND_REF || 0),
   291	    candidate_state: e.SP_STATE,
   292	    probes,
   293	  },
   294	  readiness: { ready: e.SP_READY === "1", next_action: e.SP_NEXT || null },
   295	  lane_plan: lanes,
   296	}, null, 2));
   297	JS
   298	
   299	# field <file> <dot.path> — read one value out of a JSON file (empty string if absent).
   300	field() { SP_F="$1" SP_P="$2" node "$TMP/field.mjs"; }
   301	cat >"$TMP/field.mjs" <<'JS'
   302	import { readFileSync } from "node:fs";
   303	const o = JSON.parse(readFileSync(process.env.SP_F, "utf8"));
   304	const v = process.env.SP_P.split(".").reduce((a, k) => (a == null ? a : a[k]), o);
   305	process.stdout.write(Array.isArray(v) ? v.join(",") : (v == null ? "" : String(v)));
   306	JS
   307	
   308	# ── resolve target root (Phase 3 repo-presence) ──────────────────────────────
   309	TARGET_ROOT="${TARGET_ROOT:-$ROOT}"
   310	TARGET_TOPLEVEL="$(git -C "$TARGET_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
   311	if [[ -z "$TARGET_TOPLEVEL" ]]; then
   312	  emit "BLOCKED: --target-root is not a git repo: $TARGET_ROOT"
   313	  exit 6
   314	fi
   315	TARGET_ROOT="$TARGET_TOPLEVEL"
   316	
   317	# ── collect source capture docs (Phase 2 source resolution) ──────────────────
   318	# Both modes resolve to a list of capture-doc paths; the planner reads those docs,
   319	# never a raw issue thread (GUIDING-PRINCIPLES.md §11).
   320	SOURCE_DOCS=()
   321	SOURCE_ISSUES=()
   322	MODE=""
   323	
   324	resolve_path() { local p="$1"; [[ "$p" = /* ]] && printf '%s' "$p" || printf '%s' "$ROOT/$p"; }
   325	
   326	if [[ -n "$PROJECT_DOC" ]]; then
   327	  MODE="project-doc"
   328	  doc="$(resolve_path "$PROJECT_DOC")"
   329	  [[ -f "$doc" ]] || { emit "BLOCKED: project doc not found: $PROJECT_DOC"; exit 6; }
   330	  SOURCE_DOCS+=("$doc")
   331	else
   332	  MODE="gh-bundle"
   333	  for n in "${GH_ISSUES[@]}"; do
   334	    [[ "$n" =~ ^[0-9]+$ ]] || die "--gh-issue expects a number, got: $n"
   335	    cap="$(ls "$ROOT"/PROJECT/2-WORKING/GH-"$n"-*.md 2>/dev/null | head -1 || true)"
   336	    if [[ -z "$cap" ]]; then
   337	      emit "BLOCKED: issue #$n has no in-repo GH-$n-*.md capture doc under PROJECT/2-WORKING/."
   338	      emit "  Per GUIDING-PRINCIPLES.md §11 the planner reads the capture doc, not the issue thread."
   339	      emit "  Remediation: promote issue #$n to a GH-$n capture doc with a preflight contract first."
   340	      exit 6
   341	    fi
   342	    SOURCE_DOCS+=("$cap")
   343	    SOURCE_ISSUES+=("$n")
   344	  done
   345	fi
   346	
   347	# ── extract + merge the preflight contract(s) (Phase 1 / Phase 2 merge) ───────
   348	: >"$TMP/contracts.jsonl"
   349	for doc in "${SOURCE_DOCS[@]}"; do
   350	  # Capture rc directly — `if ! VAR=$(...)` would clobber $? to 0 via the `!` negation.
   351	  one="$(SP_DOC="$doc" node "$TMP/extract-contract.mjs")"; rc=$?
   352	  if [[ $rc -ne 0 ]]; then
   353	    emit "CONTRACT ERROR ($doc): see message above. The planner fails loud rather than guessing from prose."
   354	    exit "$rc"
   355	  fi
   356	  printf '%s\n' "$one" >>"$TMP/contracts.jsonl"
   357	done
   358	
   359	MERGED="$(SP_CONTRACTS="$TMP/contracts.jsonl" node "$TMP/merge-contracts.mjs")"; rc=$?
   360	if [[ $rc -ne 0 ]]; then
   361	  emit "AMBIGUOUS: the issue bundle's contracts disagree (see message above). Split the bundle or align the contracts."
   362	  exit "$rc"
   363	fi
   364	printf '%s' "$MERGED" >"$TMP/contract.json"
   365	
   366	# ── slug + provenance (Phase 2) ──────────────────────────────────────────────
   367	PRIMARY_DOC="${SOURCE_DOCS[0]}"
   368	SLUG="$(basename "$PRIMARY_DOC" .md | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
   369	[[ -n "$SLUG" ]] || SLUG="preflight"
   370	BRANCH="$(git -C "$TARGET_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "(detached)")"
   371	COMMIT="$(git -C "$TARGET_ROOT" rev-parse HEAD 2>/dev/null || echo "(none)")"
   372	
   373	# GH-69: deterministic branch suggestion for this lane (same slug+date convention as
   374	# marathon-plan.sh's suggested_branch), and whether it already exists — the orchestrator prompts
   375	# the operator to cut it only when branch_ready=false (GUIDING-PRINCIPLES §8: never auto-cut).
   376	SUGGESTED_BRANCH="marathon/${SLUG}-${TODAY}"
   377	BRANCH_READY=0
   378	if git -C "$TARGET_ROOT" show-ref --verify --quiet "refs/heads/$SUGGESTED_BRANCH" \
   379	   || git -C "$TARGET_ROOT" show-ref --verify --quiet "refs/remotes/origin/$SUGGESTED_BRANCH"; then
   380	  BRANCH_READY=1
   381	fi
   382	
   383	# ── Phase 3: freshness ───────────────────────────────────────────────────────
   384	FETCH_OK=1
   385	git -C "$TARGET_ROOT" fetch --prune --quiet 2>/dev/null || FETCH_OK=0
   386	UPSTREAM="$(git -C "$TARGET_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")"
   387	AHEAD=0; BEHIND=0
   388	if [[ -n "$UPSTREAM" ]]; then
   389	  read -r BEHIND AHEAD < <(git -C "$TARGET_ROOT" rev-list --left-right --count "${UPSTREAM}...HEAD" 2>/dev/null || echo "0 0")
   390	fi
   391	DIRTY=0
   392	[[ -n "$(git -C "$TARGET_ROOT" status --porcelain 2>/dev/null)" ]] && DIRTY=1
   393	FRESH_BLOCKED=0
   394	[[ "$FETCH_OK" -eq 0 ]] && FRESH_BLOCKED=1   # offline / fetch failed is a visible blocked state, not silent
   395	
   396	# ── Phase 3: resolve the declared target.ref and evaluate probes AGAINST IT ───
   397	# The contract's target.ref is the committish the marathon will branch from — NOT whatever
   398	# the target repo happens to have checked out. Probing the live working tree (a possibly
   399	# 30-commits-stale `main`) is the exact starvation trap GH-25 exists to kill: a fix already
   400	# shipped on origin/development reads as "still required" on a stale checkout, and the planner
   401	# green-lights building something that already exists. So resolve the ref and probe a throwaway
   402	# worktree OF THAT REF — path/grep/command probes then all see the ref's content, not the
   403	# (possibly stale or dirty) working tree.
   404	REF="$(field "$TMP/contract.json" target.ref)"
   405	REF_COMMIT="$(git -C "$TARGET_ROOT" rev-parse --verify --quiet "${REF}^{commit}" 2>/dev/null || true)"
   406	if [[ -z "$REF_COMMIT" ]]; then
   407	  emit "BLOCKED: contract target.ref '$REF' does not resolve in $TARGET_ROOT (fetch_ok=$FETCH_OK)."
   408	  emit "  The marathon would branch from this ref; if it can't be resolved the preflight is blind."
   409	  emit "  Remediation: push/fetch the ref, or correct target.ref in the contract."
   410	  exit 6
   411	fi
   412	HEAD_BEHIND_REF="$(git -C "$TARGET_ROOT" rev-list --count "HEAD..${REF_COMMIT}" 2>/dev/null || echo 0)"
   413	CHECKOUT_MATCHES_REF=0; [[ "$COMMIT" == "$REF_COMMIT" ]] && CHECKOUT_MATCHES_REF=1
   414	REF_WT="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight-ref.XXXXXX")"; rm -rf "$REF_WT"
   415	if ! git -C "$TARGET_ROOT" worktree add --detach --quiet "$REF_WT" "$REF_COMMIT" 2>/dev/null; then
   416	  emit "BLOCKED: could not create a worktree at target.ref '$REF' ($REF_COMMIT) in $TARGET_ROOT."
   417	  exit 6
   418	fi
   419	PROBE_SUMMARY="$(SP_ROOT="$REF_WT" SP_CONTRACT="$TMP/contract.json" SP_OUT="$TMP/probes.json" node "$TMP/eval-probes.mjs")"
   420	read -r STALE BLOCKED AMBIG <<<"$PROBE_SUMMARY"
   421	# GH-39 (A2): verify every declared artifact path exists at the evaluated ref. A "ready" packet whose
   422	# artifacts[] is missing/mistyped would fail the marathon at the first edit (the GH-29-adjacent failure
   423	# class). Checked in REF_WT — the ref's content — BEFORE the worktree is removed below.
   424	GH39_ART_MISSING=""
   425	_gh39_art_csv="$(field "$TMP/contract.json" artifacts)"
   426	if [[ -n "$_gh39_art_csv" ]]; then
   427	  IFS=',' read -ra _gh39_arts <<<"$_gh39_art_csv"
   428	  for _gh39_a in "${_gh39_arts[@]}"; do
   429	    read -r _gh39_a <<<"$_gh39_a"               # trim leading/trailing whitespace
   430	    [[ -z "$_gh39_a" ]] && continue
   431	    [[ -e "$REF_WT/$_gh39_a" ]] || { GH39_ART_MISSING="$_gh39_a"; break; }
   432	  done
   433	fi
   434	git -C "$TARGET_ROOT" worktree remove --force "$REF_WT" >/dev/null 2>&1 || rm -rf "$REF_WT"
   435	git -C "$TARGET_ROOT" worktree prune >/dev/null 2>&1 || true
   436	
   437	CAND_STATE="ready"
   438	if   [[ "$BLOCKED" -eq 1 || "$FRESH_BLOCKED" -eq 1 ]]; then CAND_STATE="blocked"
   439	elif [[ "$AMBIG" -eq 1 ]]; then CAND_STATE="ambiguous"
   440	elif [[ "$STALE" -eq 1 ]]; then CAND_STATE="stale"
   441	fi
   442	
   443	# ── Phase 4: remediation readiness gate ──────────────────────────────────────
   444	READY=1; READY_NEXT=""
   445	GATE_CMD="$(field "$TMP/contract.json" gate)"
   446	ART_CSV="$(field "$TMP/contract.json" artifacts)"
   447	ART_COUNT=0; [[ -n "$ART_CSV" ]] && ART_COUNT="$(awk -F, '{print NF}' <<<"$ART_CSV")"
   448	
   449	# GH-69 carve-out: a doc-only/trivial lane (risk==1, zone==independent) skips the branch-cut prompt
   450	# and proceeds on the current branch — ratings make this deterministic. Mirrors marathon-plan.sh's
   451	# KERNEL_PATHS/SHIM_RE zone heuristic (deliberately re-derived here, not imported, so the packet stays
   452	# self-contained without a marathon-plan.sh dependency).
   453	#
   454	# Match semantics MUST mirror marathon-plan.sh exactly, or the two planners can disagree on a lane's
   455	# zone: marathon-plan.sh's KERNEL_PATHS check is a PREFIX match (`a === k || a.startsWith(k)`), not
   456	# exact — an exact-match `case` here would classify e.g. `bin/tick+helper.sh` as `independent` (wrongly
   457	# skipping the branch prompt on a kernel-adjacent lane) while marathon-plan.sh classifies it `kernel`.
   458	# Likewise SHIM_RE is case-insensitive (`/i`); an unqualified case-sensitive match here could let a
   459	# differently-cased shim path (`relay-automation/Codex-turn.sh`) slip through as `independent`.
   460	# (agy relay QA, 2026-07-01, [Should] + [Nit].)
   461	FM_RISK="$(grep -m1 -E '^risk:[[:space:]]*[0-9]+' "$PRIMARY_DOC" 2>/dev/null | grep -oE '[0-9]+' || true)"
   462	ZONE_KERNEL_PATHS=(relay-automation/relay-turn-lib.sh bin/tick relay-automation/relay-drive.sh)
   463	ZONE="independent"
   464	if [[ -n "$ART_CSV" ]]; then
   465	  IFS=',' read -ra _z_arts <<<"$ART_CSV"
   466	  for _z_a in "${_z_arts[@]}"; do
   467	    read -r _z_a <<<"$_z_a"
   468	    for _z_k in "${ZONE_KERNEL_PATHS[@]}"; do
   469	      [[ "$_z_a" == "$_z_k" || "$_z_a" == "$_z_k"* ]] && { ZONE="kernel"; break; }
   470	    done
   471	    [[ "$ZONE" == "kernel" ]] && break
   472	  done
   473	  if [[ "$ZONE" != "kernel" ]]; then
   474	    for _z_a in "${_z_arts[@]}"; do
   475	      read -r _z_a <<<"$_z_a"
   476	      # Case-insensitive shim match: lowercase the path, mirroring SHIM_RE's `/i`. `tr`, not bash-4
   477	      # `${x,,}` — stock macOS bash is 3.2 (this repo's scripts stay 3.2-portable; see relay-turn-lib.sh).
   478	      _z_a_lc="$(printf '%s' "$_z_a" | tr '[:upper:]' '[:lower:]')"
   479	      case "$_z_a_lc" in
   480	        relay-automation/*-turn.sh|relay-automation/consult.sh)
   481	          # Bash case globs match `/` too (unlike marathon-plan.sh's SHIM_RE, whose [a-z0-9-]+ class
   482	          # can't cross a path separator) — reject a nested subdirectory explicitly, or
   483	          # relay-automation/subdir/foo+turn.sh would wrongly classify as shim (agy relay QA r2, [Nit]).
   484	          _z_rest="${_z_a_lc#relay-automation/}"
   485	          case "$_z_rest" in
   486	            */*) ;;
   487	            *) ZONE="shim" ;;
   488	          esac
   489	          ;;
   490	      esac
   491	      [[ "$ZONE" == "shim" ]] && break
   492	    done
   493	  fi
   494	fi
   495	SKIP_BRANCH_PROMPT=0
   496	[[ "$FM_RISK" == "1" && "$ZONE" == "independent" ]] && SKIP_BRANCH_PROMPT=1
   497	
   498	REMED_SRC="$(field "$TMP/contract.json" remediation.source)"
   499	REMED_CRIT="$(field "$TMP/contract.json" remediation.criteria)"
   500	DOC_HAS_PHASES=0
   501	grep -Eq '^##+ .*[Pp]hase|^- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null && DOC_HAS_PHASES=1
   502	
   503	if [[ -z "$GATE_CMD" ]];     then READY=0; READY_NEXT="add a runnable gate command to the contract"; fi
   504	if [[ "$ART_COUNT" -eq 0 ]]; then READY=0; READY_NEXT="add a bounded artifact / ALLOW_PATHS set to the contract"; fi
   505	if [[ -z "$REMED_SRC$REMED_CRIT" && "$DOC_HAS_PHASES" -eq 0 ]]; then
   506	  READY=0; READY_NEXT="research more: no phase plan or acceptance criteria — source is not runnable unattended"
   507	fi
   508	# GH-39 (A2): an artifact path that doesn't exist at the ref (detected in Phase 3) → not ready.
   509	# Guarded on READY==1 so the FIRST failure's reason wins (don't clobber an earlier next-action).
   510	if [[ "$READY" -eq 1 && -n "${GH39_ART_MISSING:-}" ]]; then
   511	  READY=0; READY_NEXT="artifact path not found at target.ref: $GH39_ART_MISSING — fix the contract artifacts[] or push the file"
   512	fi
   513	# GH-39 (A1): the gate command must be RUNNABLE — its program resolves. (Whether the gate currently
   514	# FAILS, proving the fix is still required, is already covered by fix_probes above; we deliberately do
   515	# NOT execute the full gate here — that is heavy and side-effectful, e.g. a suite that spawns worktrees.)
   516	# A `bash`/`sh <script>` gate must have its script; any other leading program must be on PATH.
   517	if [[ "$READY" -eq 1 && -n "$GATE_CMD" ]]; then
   518	  read -r -a _gh39_gw <<<"$GATE_CMD"
   519	  _gh39_g0="${_gh39_gw[0]}"
   520	  if [[ "$_gh39_g0" == "bash" || "$_gh39_g0" == "sh" ]]; then
   521	    # First NON-FLAG token after the interpreter is the script — so `bash -x script.sh` resolves
   522	    # `script.sh`, not `-x` (agy GH-39 review Nit).
   523	    _gh39_script=""
   524	    for _gh39_t in ${_gh39_gw[@]+"${_gh39_gw[@]:1}"}; do
   525	      [[ "$_gh39_t" == -* ]] && continue
   526	      _gh39_script="$_gh39_t"; break
   527	    done
   528	    [[ -n "$_gh39_script" && -f "$TARGET_ROOT/$_gh39_script" ]] || { READY=0; READY_NEXT="gate script not found at target.ref: ${_gh39_script:-<none>}"; }
   529	  elif ! command -v "$_gh39_g0" >/dev/null 2>&1; then
   530	    READY=0; READY_NEXT="gate program not on PATH: $_gh39_g0"
   531	  fi
   532	fi
   533	# GH-39 (A3): build-lane CLI presence — ADVISORY only (never blocks: keeps preflight portable in
   534	# keyless/CI environments where codex/agy aren't installed). Surfaced on the report below.
   535	GH39_LANE_NOTE="codex=$(command -v codex >/dev/null 2>&1 && echo present || echo absent) agy=$(command -v agy >/dev/null 2>&1 && echo present || echo absent)"
   536	
   537	# ── Phase 5: lane assignment ─────────────────────────────────────────────────
   538	SP_CONTRACT="$TMP/contract.json" node "$TMP/lane-plan.mjs" >"$TMP/lane-plan.json"
   539	
   540	# ── assemble the normalized run-candidate object (Phase 2 output shape) ───────
   541	ISSUES_CSV="$(IFS=,; printf '%s' "${SOURCE_ISSUES[*]:-}")"
   542	printf '%s\n' "${SOURCE_DOCS[@]}" >"$TMP/docs.txt"
   543	SP_CONTRACT="$TMP/contract.json" SP_PROBES="$TMP/probes.json" SP_LANES="$TMP/lane-plan.json" \
   544	  SP_DOCS="$(cat "$TMP/docs.txt")" SP_ISSUES="$ISSUES_CSV" SP_MODE="$MODE" SP_SLUG="$SLUG" \
   545	  SP_BRANCH="$BRANCH" SP_COMMIT="$COMMIT" SP_SUGGESTED_BRANCH="$SUGGESTED_BRANCH" SP_BRANCH_READY="$BRANCH_READY" \
   546	  SP_SKIP_BRANCH_PROMPT="$SKIP_BRANCH_PROMPT" \
   547	  SP_ROOT="$TARGET_ROOT" SP_NOW="$NOW" SP_STATE="$CAND_STATE" \
   548	  SP_FETCH="$FETCH_OK" SP_UP="$UPSTREAM" SP_AHEAD="$AHEAD" SP_BEHIND="$BEHIND" SP_DIRTY="$DIRTY" \
   549	  SP_REF="$REF" SP_REF_COMMIT="$REF_COMMIT" SP_HEAD_BEHIND_REF="$HEAD_BEHIND_REF" \
   550	  SP_CHECKOUT_MATCHES_REF="$CHECKOUT_MATCHES_REF" \
   551	  SP_READY="$READY" SP_NEXT="$READY_NEXT" \
   552	  node "$TMP/normalize.mjs" >"$TMP/run-candidate.json"
   553	
   554	# ── final verdict + exit code ────────────────────────────────────────────────
   555	VERDICT="ready"; CODE=0
   556	case "$CAND_STATE" in
   557	  blocked)   VERDICT="BLOCKED";   CODE=6 ;;
   558	  ambiguous) VERDICT="AMBIGUOUS"; CODE=7 ;;
   559	  stale)     VERDICT="STALE";     CODE=4 ;;
   560	  ready)     [[ "$READY" -eq 0 ]] && { VERDICT="NOT-READY"; CODE=5; } ;;
   561	esac
   562	
   563	# GH-51 [1]: emit --target-root ONLY for a FOREIGN target. For a same-repo lane it is redundant AND
   564	# routes relay-file path normalization through the cross-repo code path, which flags the legitimately
   565	# edited relay file (it lives in the thread repo, not the target) as off-lane → exit 6, discarding the
   566	# build. Omit the flag when the target IS this repo so same-repo lanes take the default (correct) path.
   567	TARGET_ROOT_LINE=""
   568	# Compare CANONICAL paths: TARGET_ROOT is the symlink-resolved git toplevel, but ROOT may be a raw
   569	# SWARM_PREFLIGHT_ROOT / a /var→/private/var symlink, so a bare string compare misfires (and would
   570	# wrongly emit --target-root for a same-repo lane). Resolve both with `pwd -P` before comparing.
   571	_root_canon="$(cd "$ROOT" 2>/dev/null && pwd -P || printf '%s' "$ROOT")"
   572	_target_canon="$(cd "$TARGET_ROOT" 2>/dev/null && pwd -P || printf '%s' "$TARGET_ROOT")"
   573	[[ "$_target_canon" != "$_root_canon" ]] && TARGET_ROOT_LINE=$'\n'"  --target-root $TARGET_ROOT \\"
   574	INVOCATION="XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=$SLUG $_DRIVE_CMD \\
   575	  --phase-brief <packet>/packet.md \\
   576	  --reviewer agy \\
   577	  --builder codex \\
   578	  --artifact $ART_CSV \\$TARGET_ROOT_LINE
   579	  --pre-advance-cmd '$GATE_CMD' \\
   580	  --require-clean"
   581	
   582	# ── emit report (stdout) ─────────────────────────────────────────────────────
   583	if [[ "$FORMAT" == "json" ]]; then
   584	  cat "$TMP/run-candidate.json"
   585	else
   586	  if [[ "$CHECKOUT_MATCHES_REF" -eq 1 ]]; then
   587	    REF_NOTE="checkout matches"
   588	  else
   589	    REF_NOTE="checkout HEAD is $HEAD_BEHIND_REF commit(s) behind the evaluated ref — probes read the ref, not your checkout"
   590	  fi
   591	  emit "swarm-preflight · $MODE · slug=$SLUG"
   592	  emit "  target-root : $TARGET_ROOT ($BRANCH @ ${COMMIT:0:9})"
   593	  emit "  branch      : suggested=$SUGGESTED_BRANCH branch_ready=$([[ "$BRANCH_READY" -eq 1 ]] && echo true || echo false) skip_branch_prompt=$([[ "$SKIP_BRANCH_PROMPT" -eq 1 ]] && echo true || echo false)"
   594	  emit "  freshness   : fetch_ok=$FETCH_OK upstream=${UPSTREAM:-none} ahead=$AHEAD behind=$BEHIND dirty=$DIRTY"
   595	  emit "  ref-probed  : $REF @ ${REF_COMMIT:0:9} ($REF_NOTE)"
   596	  emit "  candidate   : $CAND_STATE"
   597	  emit "  readiness   : ready=$READY${READY_NEXT:+ — next: $READY_NEXT}"
   598	  emit "  lane-cli    : ${GH39_LANE_NOTE:-unknown} (advisory)"
   599	  emit "  verdict     : $VERDICT (exit $CODE)"
   600	fi
   601	
   602	if [[ "$CODE" -ne 0 ]]; then
   603	  [[ "$FORMAT" == "json" ]] || { emit ""; emit "No packet written — candidate is not preflight-ready ($VERDICT)."; }
   604	  exit "$CODE"
   605	fi
   606	
   607	# GH-30 Phase 2: resolve the packet output dir ONCE (honors XYZ_ARCHIVE_ROOT), so the dry-run preview
   608	# and the real emit agree. An explicit --out (OUT_DIR set) wins and skips the resolver entirely, so an
   609	# invalid XYZ_ARCHIVE_ROOT can't override a named --out. Resolver hard-errors loudly on set-but-invalid.
   610	if [[ -z "$OUT_DIR" ]]; then
   611	  _sp_ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
   612	  OUT_DIR="$_sp_ts_base/preflight/$TODAY/$SLUG"
   613	fi
   614	
   615	if [[ "$DRY_RUN" -eq 1 ]]; then
   616	  [[ "$FORMAT" == "json" ]] || {
   617	    emit ""; emit "DRY-RUN: ready, but packet not written. Would emit to: $OUT_DIR"
   618	    emit "Would suggest:"; emit "$INVOCATION"
   619	  }
   620	  exit 0
   621	fi
   622	
   623	# ── Phase 6: emit the packet ─────────────────────────────────────────────────
   624	mkdir -p "$OUT_DIR"
   625	cp "$TMP/run-candidate.json" "$OUT_DIR/run-candidate.json"
   626	cp "$TMP/lane-plan.json" "$OUT_DIR/lane-plan.json"
   627	SP_F="$TMP/run-candidate.json" SP_K=freshness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/freshness.json"
   628	SP_F="$TMP/run-candidate.json" SP_K=readiness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/readiness.json"
   629	printf '%s\n' "$INVOCATION" >"$OUT_DIR/marathon-invocation.txt"
   630	
   631	# GH-39 B6 + #43-1: bake a SCOPE-LOCKED brief so the builder beelines (no doc-chasing, no wander) and
   632	# size the turn budget to the artifacts. Acceptance criteria are inlined from the capture doc's checklist
   633	# so the builder doesn't have to go read it (the thin-brief gap that made GH-36 v1 wander ~38k tokens).
   634	GH39_ACC="$(grep -E '^[[:space:]]*- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null | head -25)"
   635	[[ -n "$GH39_ACC" ]] || GH39_ACC="(no '- [ ]' checklist found in $PRIMARY_DOC — add an Acceptance criteria list)"
   636	GH39_ART_LOC=0
   637	IFS=',' read -ra _b6arts <<<"$ART_CSV"
   638	for _b6a in "${_b6arts[@]}"; do
   639	  read -r _b6a <<<"$_b6a"; [[ -z "$_b6a" ]] && continue
   640	  [[ -f "$TARGET_ROOT/$_b6a" ]] && GH39_ART_LOC=$((GH39_ART_LOC + $(wc -l <"$TARGET_ROOT/$_b6a" 2>/dev/null || echo 0)))
   641	done
   642	# GH-51 [4]: the old single >400-LOC step left mid-size, multi-file builds (e.g. GH-37: 335 LOC across
   643	# 4 shims+tests) on the 300s default — below the note's own warning — and the builder was killed
   644	# mid-turn. Scale by BOTH size and artifact count (each extra file adds build+verify coordination cost).
   645	GH39_ART_N="${#_b6arts[@]}"
   646	GH39_TIMEOUT=300
   647	{ [[ "$GH39_ART_LOC" -gt 200 ]] || [[ "$GH39_ART_N" -ge 3 ]]; } && GH39_TIMEOUT=600
   648	{ [[ "$GH39_ART_LOC" -gt 400 ]] || [[ "$GH39_ART_N" -ge 4 ]]; } && GH39_TIMEOUT=900
   649	
   650	cat >"$OUT_DIR/packet.md" <<EOF
   651	# Marathon preflight packet — $SLUG
   652	
   653	- Generated: $NOW
   654	- Mode: $MODE
   655	- Sources: $(printf '%s ' "${SOURCE_DOCS[@]}")
   656	- Target root: $TARGET_ROOT ($BRANCH @ ${COMMIT:0:9})
   657	- Suggested branch: \`$SUGGESTED_BRANCH\` (branch_ready=$([[ "$BRANCH_READY" -eq 1 ]] && echo true || echo false)$([[ "$BRANCH_READY" -eq 0 && "$SKIP_BRANCH_PROMPT" -eq 0 ]] && echo " — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8")$([[ "$SKIP_BRANCH_PROMPT" -eq 1 ]] && echo " — carve-out: risk=1/independent zone, proceed on the current branch without asking"))
   658	- Verdict: $VERDICT
   659	- Gate: \`$GATE_CMD\`
   660	- Artifacts: $ART_CSV
   661	- Suggested turn budget: \`RELAY_TURN_TIMEOUT_S=$GH39_TIMEOUT\` (sized to ≈ $GH39_ART_LOC LOC across $GH39_ART_N artifact(s); a build that also edits tests needs headroom over the 300s default)
   662	
   663	This packet is the producer's output. The orchestrator launches the run; the planner does not
   664	(GUIDING-PRINCIPLES.md §8).
   665	
   666	## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
   667	$GH39_ACC
   668	
   669	## Scope lock — builder, do exactly this and nothing else
   670	- Edit ONLY: \`$ART_CSV\` (plus the relay file). Any other edit is reverted and FAILS the turn.
   671	- Do NOT run the full gate (\`$GATE_CMD\`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
   672	- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.
   673	
   674	## Suggested marathon-drive.sh invocation
   675	
   676	\`\`\`bash
   677	$INVOCATION
   678	\`\`\`
   679	
   680	## Files in this packet
   681	- \`run-candidate.json\` — normalized run candidate (provenance + contract + checks)
   682	- \`freshness.json\` — branch state + fix-still-required probes
   683	- \`readiness.json\` — remediation readiness verdict
   684	- \`lane-plan.json\` — Codex / agy / orchestrator lane assignment
   685	- \`marathon-invocation.txt\` — the invocation hint above
   686	EOF
   687	
   688	# In --format json mode, stdout must hold only the JSON object — route the status to stderr.
   689	if [[ "$FORMAT" == json ]]; then
   690	  log "packet written: $OUT_DIR"
   691	else
   692	  emit ""; emit "Packet written: $OUT_DIR"
   693	fi
   694	exit 0

exec
/bin/zsh -lc "nl -ba relay-automation/relay-turn-lib.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
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
    70	  # Strip a trailing slash so a caller passing "/repo/" can't yield "/repo//relay-system" (a `//`
    71	  # prefix is implementation-defined under POSIX). Real caller roots are git-rev-parse output with no
    72	  # trailing slash, so this is byte-identical to today's "$ROOT/relay-system" on the common path.
    73	  local target_root="${1%/}"
    74	  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
    75	    printf '%s/relay-system' "$target_root"
    76	    return 0
    77	  fi
    78	  local ar="$XYZ_ARCHIVE_ROOT"
    79	  if [[ "$ar" != /* ]]; then
    80	    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: %s\n' "$ar" >&2
    81	    return 1
    82	  fi
    83	  if [[ ! -d "$ar" ]]; then
    84	    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): %s\n' "$ar" >&2
    85	    return 1
    86	  fi
    87	  # Model A: the archive is a committed git repo. A non-git dir would silently drop transcripts on the
    88	  # floor in Phase 3, so reject it now at the resolver rather than at commit time.
    89	  if ! git -C "$ar" rev-parse --git-dir >/dev/null 2>&1; then
    90	    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): %s\n' "$ar" >&2
    91	    return 1
    92	  fi
    93	  printf '%s/relay-system/%s' "$ar" "$(rtl_repo_slug "$target_root")"
    94	}
    95	
    96	# Deterministic per-repo slug for archive namespacing: origin remote basename (…/<name>[.git]),
    97	# else the target dir's basename. Sanitized to a SAFE single path segment: [A-Za-z0-9._-] only, never
    98	# empty, never "."/".." (a path-traversal segment would let a writer escape the relay-system base),
    99	# never leading "-" (option-shaped for a later `cd`/`git -C` consumer). Falls back to "repo".
   100	rtl_repo_slug() {  # <target_root>
   101	  local target_root="$1" url slug
   102	  url="$(git -C "$target_root" remote get-url origin 2>/dev/null || true)"
   103	  while [[ "$url" == */ ]]; do url="${url%/}"; done   # tolerate a trailing-slash remote (…/foo/ or …/foo.git/)
   104	  url="${url%.git}"
   105	  while [[ "$url" == */ ]]; do url="${url%/}"; done
   106	  if [[ -n "$url" ]]; then
   107	    slug="${url##*/}"; slug="${slug##*:}"   # strip path AND scp-style host: prefix
   108	  fi
   109	  [[ -z "${slug:-}" ]] && slug="$(basename -- "$target_root" 2>/dev/null || true)"
   110	  slug="$(printf '%s' "${slug:-repo}" | tr -c 'A-Za-z0-9._-' '_')"
   111	  while [[ "$slug" == -* ]]; do slug="${slug#-}"; done   # never option-shaped
   112	  case "$slug" in ''|.|..) slug="repo" ;; esac           # never empty or a path-traversal segment
   113	  printf '%s' "$slug"
   114	}
   115	
   116	rtl_init() {  # <root> <relay_file> <allow_csv>
   117	  # ROOT routing (GH-11): a foreign --target-root (exported by relay-drive as RELAY_TARGET_ROOT)
   118	  # routes the WHOLE turn — worktree base, allowlist copyback, file-scoped commit, enforce — from this
   119	  # one anchor. Unset/empty → the caller's <root> (today's behavior, byte-for-byte). Coordination
   120	  # (.tick) stays where TICK_REPO_ROOT points (the harness clone); only the ARTIFACT side moves.
   121	  RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"; local f="$2" csv="$3"
   122	  # GH-51 [1-kernel]: a SAME-REPO --target-root (notably `--target-root .`) left RTL_ROOT relative or
   123	  # redundant, so the repo-root-relative strip below (`${a#"$RTL_ROOT"/}`) could not remove an ABSOLUTE
   124	  # relay-file prefix — the relay file then failed the off-lane match and a legitimate same-repo turn
   125	  # was reverted (exit 6; the GH-37 marathon needed --target-root DROPPED to converge). When the target
   126	  # root resolves to the SAME git repo as the caller's own root, collapse so containment is
   127	  # byte-identical to the no-target-root path (a same-repo --target-root is a NO-OP). WHICH root string
   128	  # to collapse to matters: prefer the caller's own root ($1) when $1 IS the repo root, because $1 is
   129	  # the exact path form the rest of the turn uses (symlink-consistent — git rev-parse returns the
   130	  # PHYSICAL path, e.g. /private/var, while $1/the relay file may be the /var form; GH-51). But a GH-49
   131	  # vendored .xyz/ copy is a SUBDIR of the foreign repo, so its caller root ($1 = …/.xyz) is NOT the
   132	  # repo root — collapsing to $1 would root containment at .xyz/ and the foreign repo's own relay file
   133	  # would fail its off-lane match. Detect that (physical $1 != physical toplevel) and use the toplevel.
   134	  # Genuine foreign roots (a different toplevel) are untouched — the cross-repo path is unchanged.
   135	  if [[ -n "${RELAY_TARGET_ROOT:-}" ]]; then
   136	    local _tt _ct _c1; _tt="$(git -C "$RTL_ROOT" rev-parse --show-toplevel 2>/dev/null)"
   137	    _ct="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"
   138	    _c1="$(cd "$1" 2>/dev/null && pwd -P)"
   139	    if [[ -n "$_tt" && "$_tt" == "$_ct" ]]; then
   140	      if [[ "$_c1" == "$_ct" ]]; then RTL_ROOT="$1"; else RTL_ROOT="$_tt"; fi
   141	    fi
   142	  fi
   143	  # macOS/APFS (and any case-insensitive fs) reports git-status paths in the case the INDEX tracks
   144	  # (e.g. RELAY-SYSTEM/…), which can differ from the lowercase invocation arg the allowlist holds
   145	  # (relay-system/…). Detect it ONCE here so rtl_in_allow can compare case-insensitively on such
   146	  # filesystems (GH-17) — otherwise a reviewer's legit append to its own relay file is seen as
   147	  # off-allowlist and reverted with exit 6. Case-sensitive repos (Linux CI) keep a byte-for-byte
   148	  # exact compare. Non-repo / unset → false (the safe, case-sensitive default).
   149	  RTL_IGNORECASE="$(git -C "$RTL_ROOT" config --get core.ignorecase 2>/dev/null || echo false)"
   150	  [[ "$RTL_IGNORECASE" == "true" ]] || RTL_IGNORECASE=false
   151	  RTL_WT_USED=0          # set to 1 by rtl_worktree_begin; read by rtl_enforce's commit-bypass guard (GH-13)
   152	  RTL_ALLOW=("$f")
   153	  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
   154	  # and must never edit the artifact under review. When NEXT names the Reviewer, drop the caller's
   155	  # extra allowlist (relay file ONLY) so any artifact edit a headless reviewer makes is reverted by
   156	  # rtl_enforce. This is the boundary an over-eager agy reviewer crossed on 2026-06-20 (it edited
   157	  # validate.sh because the artifact sat on ALLOW_PATHS). Producer turns keep the full allowlist —
   158	  # they legitimately build.
   159	  if rtl_is_reviewer_turn "$f"; then
   160	    [[ -n "$csv" ]] && printf 'relay-turn: REVIEWER turn — scoping allowlist to the relay file only (ignoring ALLOW_PATHS=%s)\n' "$csv" >&2
   161	    csv=""
   162	  fi
   163	  local _extra p; IFS=',' read -ra _extra <<<"$csv"
   164	  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
   165	  local _n=() a                       # normalize to repo-root-relative (git status emits relative)
   166	  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
   167	  RTL_ALLOW=("${_n[@]}")
   168	  # GH-31 / #15: optional READ-ONLY artifact under review (a cross-repo or uncommitted PR/diff).
   169	  # RELAY_ARTIFACT_FILE is an ABSOLUTE path to the source (relay-drive absolutizes it). It is seeded
   170	  # read-only into the worktree by rtl_worktree_begin at .relay-artifacts/<basename> — NOT added to
   171	  # RTL_ALLOW, so it is never copied back to RTL_ROOT (no leak). The reviewer may READ it; an edit
   172	  # changes its signature and fails the turn (strict read-only). Empty/unset → no artifact (default).
   173	  RTL_ARTIFACT="${RELAY_ARTIFACT_FILE:-}"
   174	  RTL_ARTIFACT_REL=""
   175	  # NB: a trailing `[[ -n .. ]] && assign` would make rtl_init RETURN the test's status (1 when no
   176	  # artifact), and a `set -e` caller (the turn shims) would abort the turn. Use an if-block → returns 0.
   177	  if [[ -n "$RTL_ARTIFACT" ]]; then
   178	    RTL_ARTIFACT_REL=".relay-artifacts/$(basename "$RTL_ARTIFACT")"
   179	  fi
   180	}
   181	
   182	rtl_in_allow() {  # <path> — is <path> on the allowlist? Case-insensitive when RTL_IGNORECASE=true (GH-17).
   183	  local x="$1" a
   184	  # GH-59: git collapses an all-untracked new dir to `dir/` in porcelain output. Treat that as
   185	  # allowlisted ONLY when it is a TRUE ancestor of a concrete allowlisted file entry (e.g.
   186	  # greenfield/ -> greenfield/output.txt). This generalizes the old .relay-artifacts dir exemption
   187	  # without widening to bare prefixes such as `green/` for `greenfield/output.txt`.
   188	  if [[ "$x" == */ ]]; then
   189	    local dir="${x%/}"
   190	    if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
   191	      local dl al; dl="$(printf '%s' "$dir/" | tr '[:upper:]' '[:lower:]')"
   192	      for a in "${RTL_ALLOW[@]}"; do
   193	        al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
   194	        [[ "$al" == "$dl"* && "$al" != "$dl" ]] && return 0
   195	      done
   196	    else
   197	      for a in "${RTL_ALLOW[@]}"; do [[ "$a" == "$dir/"* && "$a" != "$dir/" ]] && return 0; done
   198	    fi
   199	  fi
   200	  if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
   201	    # `tr` not bash-4 `${x,,}`: stock macOS bash is 3.2 (this lib is deliberately BSD/macOS-portable).
   202	    local xl al; xl="$(printf '%s' "$x" | tr '[:upper:]' '[:lower:]')"
   203	    for a in "${RTL_ALLOW[@]}"; do
   204	      al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
   205	      [[ "$xl" == "$al" ]] && return 0
   206	    done
   207	    return 1
   208	  fi
   209	  for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done
   210	  return 1
   211	}
   212	
   213	rtl_run_bounded() {  # <timeout_secs> <cmd...>
   214	  # Run <cmd...> under a wall-clock ceiling without coreutils `timeout` (absent on stock macOS).
   215	  # Mirrors the consult.sh _guarded() pattern: sleep-then-kill watchdog, no external deps.
   216	  # Process-group note: `setsid` is absent on stock macOS so we kill by PID (same as consult.sh).
   217	  # A multi-process CLI whose children outlive the leader is a known gap; worktree isolation is
   218	  # the airtight follow-up (ROADMAP 3.6). The PID kill is sufficient for hung single-process CLIs.
   219	  # NOTE: disk-quota and per-turn spend ceilings are NOT yet enforced here — wall-clock only (R5
   220	  # partial). Disk-quota belongs in a TMPDIR watchdog; spend ceilings are model-shim-specific.
   221	  local secs="$1"; shift
   222	  local apid kpid rc=0
   223	  "$@" &
   224	  apid=$!
   225	  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
   226	  kpid=$!
   227	  wait "$apid" 2>/dev/null || rc=$?
   228	  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
   229	  # Distinguish timeout-kill (signal 9 → exit 137) from a genuine rc=137 from the CLI itself.
   230	  # We use rc=137 as the proxy for "killed by our watchdog" and map it to 7.
   231	  # This is the same tradeoff consult.sh accepts: a CLI that genuinely crashes with rc=137 looks
   232	  # like a timeout. Acceptable — both cases are "turn failed abnormally."
   233	  if [[ "$rc" -eq 137 ]]; then
   234	    return 7
   235	  fi
   236	  return "$rc"
   237	}
   238	
   239	# --- Worktree isolation (ROADMAP Part A Phase 3.6 — the airtight async/side-effect close) ----------
   240	# OPT-IN: callers gate on RELAY_WORKTREE_ISOLATION=1. Default OFF → behaviour is unchanged.
   241	# Run the agent turn in a THROWAWAY git worktree of RTL_ROOT@HEAD, so any async/background write
   242	# lands in a tree we delete — RTL_ROOT is never the agent's target. This closes the gap left by the
   243	# point-in-time `rtl_enforce` + the (macOS-absent) setsid process-group reap: ROOT safety no longer
   244	# depends on killing the process group, because the agent can't reach ROOT in the first place.
   245	# Coordination state (.tick) stays SHARED — the caller must run the agent with TICK_REPO_ROOT=RTL_ROOT.
   246	#
   247	# SEED LIMITATIONS (relay review 2026-06-23 F4/F5 — known constraints, documented; structural fix deferred):
   248	#   - Cross-repo / uncommitted artifact: the worktree is a checkout of RTL_ROOT@HEAD and seeds only
   249	#     allowlisted paths UNDER RTL_ROOT (below). An artifact in ANOTHER repo, or a brand-new uncommitted
   250	#     one, is neither at HEAD nor on the writable allowlist, so it would be invisible to an isolated turn.
   251	#     FIX (GH-31 / closes #15): set RELAY_ARTIFACT_FILE (relay-drive `--artifact-file`) to seed it as a
   252	#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
   253	#     allowlist. The reviewer may READ it; an edit changes its signature and fails the turn (strict-fail);
   254	#     it is never copied back to RTL_ROOT (no leak). See rtl_init (RTL_ARTIFACT) + the seed/exempt logic
   255	#     in rtl_worktree_begin/end. (Embedding inline still works for callers who prefer it.)
   256	_rtl_sig() {  # <path> — content signature of a file/dir, or "ABSENT". Used to detect what the turn
   257	  # actually changed IN THE WORKTREE, so rtl_worktree_end copies back ONLY worktree-modified paths and
   258	  # never clobbers a ROOT-direct edit with a stale seed (GH-22). git is already required by this lib.
   259	  local p="$1"
   260	  if [[ -f "$p" ]]; then

exec
/bin/zsh -lc "nl -ba test/swarm-preflight.sh | sed -n '1,420p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# test/swarm-preflight.sh — regression lock for utils/swarm-preflight.sh (GH-25).
     3	#
     4	# Standalone (does not source _setup.sh; the planner needs no tick/relay harness).
     5	# Builds throwaway git repos with preflight contracts and asserts the verdict + exit
     6	# code for the happy path and every failure mode: stale, not-ready, blocked, ambiguous,
     7	# contract-missing, missing GH capture, plus dry-run and the JSON shape parity check.
     8	
     9	set -uo pipefail
    10	
    11	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    12	ROOT="$(cd "$HERE/.." && pwd)"
    13	SP="$ROOT/utils/swarm-preflight.sh"
    14	
    15	WORK="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight.XXXXXX")"
    16	trap 'rm -rf "$WORK"' EXIT
    17	
    18	PASS=0; FAIL=0
    19	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    20	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    21	
    22	echo "== test: swarm-preflight =="
    23	echo "  workdir: $WORK"
    24	
    25	# Pin time so provenance is deterministic; never call the real clock in tests.
    26	export SWARM_PREFLIGHT_NOW="2026-06-25T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-06-25"
    27	
    28	# make_repo <name> <contract-json> [extra-doc-body] → echoes the repo root
    29	make_repo() {
    30	  local name="$1" contract="$2" extra="${3:-}"
    31	  local r="$WORK/$name"
    32	  mkdir -p "$r/PROJECT/2-WORKING"
    33	  {
    34	    printf -- '---\ntitle: %s\n---\n# %s\n%s\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
    35	      "$name" "$name" "$extra" "$contract"
    36	  } >"$r/PROJECT/2-WORKING/GH-900-$name.md"
    37	  # GH-39 (A2): seed the artifact paths the fixtures declare so a happy-path candidate's artifacts[]
    38	  # actually exist at the ref (preflight now blocks missing artifact paths). Covers src/a.js,
    39	  # test/a.test.js, and the single-letter fixtures a/b. Extra files are harmless (only declared
    40	  # artifacts are checked; no fix_probe in these fixtures targets these paths).
    41	  mkdir -p "$r/src" "$r/test"
    42	  : >"$r/src/a.js"; : >"$r/test/a.test.js"; : >"$r/a"; : >"$r/b"
    43	  git -C "$r" init -q -b main 2>/dev/null || { git -C "$r" init -q; git -C "$r" symbolic-ref HEAD refs/heads/main; }
    44	  git -C "$r" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
    45	  git -C "$r" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
    46	  printf '%s' "$r"
    47	}
    48	
    49	run() { SWARM_PREFLIGHT_ROOT="$1" bash "$SP" --target-root "$1" "${@:2}"; }
    50	
    51	DOC="PROJECT/2-WORKING/GH-900"   # glob prefix used below via the actual filename
    52	
    53	# ── T1: happy path → ready, exit 0, packet emitted ───────────────────────────
    54	R="$(make_repo happy '{
    55	  "target": { "repo": ".", "ref": "main" },
    56	  "gate": "true",
    57	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
    58	  "artifacts": [ "src/a.js", "test/a.test.js" ],
    59	  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
    60	}' '## Phase 1
    61	- [ ] build it')"
    62	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-happy.md" --out "$R/packet" 2>&1)"; rc=$?
    63	[[ $rc -eq 0 ]] && pass "T1 happy path exit 0" || fail "T1 expected exit 0, got $rc — $out"
    64	grep -q "verdict     : ready" <<<"$out" && pass "T1 verdict ready" || fail "T1 verdict not ready: $out"
    65	[[ -f "$R/packet/run-candidate.json" && -f "$R/packet/lane-plan.json" && -f "$R/packet/packet.md" \
    66	   && -f "$R/packet/freshness.json" && -f "$R/packet/readiness.json" && -f "$R/packet/marathon-invocation.txt" ]] \
    67	  && pass "T1 packet is self-contained (6 files)" || fail "T1 packet incomplete: $(ls "$R/packet" 2>&1)"
    68	node -e 'JSON.parse(require("fs").readFileSync(process.argv[1]))' "$R/packet/run-candidate.json" \
    69	  && pass "T1 run-candidate.json is valid JSON" || fail "T1 run-candidate.json invalid JSON"
    70	# GH-75: the generated invocation self-propagates the swarm harness tag — the operator runs it verbatim
    71	# and the marathon-drive run records harness:"swarm" (not "marathon") in XYZ.json, no extra step.
    72	head -1 "$R/packet/marathon-invocation.txt" | grep -q '^XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=[^ ]* relay-automation/marathon-drive.sh' \
    73	  && pass "T1 marathon-invocation.txt carries XYZ_HARNESS_CONTEXT=swarm + per-run XYZ_SESSION_ID (GH-75)" \
    74	  || fail "T1 invocation missing swarm tag / session id: $(head -1 "$R/packet/marathon-invocation.txt")"
    75	# GH-39 B6 + #43-1: the packet bakes a scope-locked brief — inlined acceptance criteria, an explicit
    76	# scope-lock (incl. "don't run the full gate"), and a size-based turn-budget recommendation.
    77	grep -q "Scope lock" "$R/packet/packet.md" && pass "T1b packet has a scope-lock block" || fail "T1b packet missing scope-lock"
    78	grep -q "do not run the full gate\|Do NOT run the full gate" "$R/packet/packet.md" && pass "T1b scope-lock forbids self-running the gate" || fail "T1b scope-lock missing no-gate rule"
    79	grep -q "build it" "$R/packet/packet.md" && pass "T1b acceptance criteria inlined from the capture doc" || fail "T1b acceptance not inlined"
    80	grep -q "RELAY_TURN_TIMEOUT_S=" "$R/packet/packet.md" && pass "T1b packet recommends a turn budget" || fail "T1b missing turn-budget recommendation"
    81	# GH-51 [1]: a SAME-REPO lane (root==target, as T1 is) must NOT emit --target-root — it routes relay-file
    82	# path normalization through the cross-repo code path, flagging the legitimately edited relay file as
    83	# off-lane (exit 6) and discarding the build (the GH-37 dogfood's root-cause blocker).
    84	grep -q -- '--target-root' "$R/packet/marathon-invocation.txt" \
    85	  && fail "T1c same-repo invocation must OMIT --target-root (GH-51 off-lane fix)" \
    86	  || pass "T1c same-repo invocation omits --target-root (GH-51 off-lane fix)"
    87	# GH-51 [4]: the small happy fixture (2 artifacts, 0 LOC) keeps the 300s default budget.
    88	grep -q "RELAY_TURN_TIMEOUT_S=300" "$R/packet/packet.md" \
    89	  && pass "T1d small build keeps the 300s budget" || fail "T1d expected 300s budget for the small fixture: $(grep RELAY_TURN_TIMEOUT_S "$R/packet/packet.md")"
    90	
    91	# ── T16 (GH-51 [1]+[4]): foreign target emits --target-root; 4-artifact build scales budget to 900s ──
    92	R16="$(make_repo budgetscale '{
    93	  "target": { "repo": ".", "ref": "main" },
    94	  "gate": "true",
    95	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
    96	  "artifacts": [ "src/a.js", "test/a.test.js", "a", "b" ],
    97	  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
    98	}' '## Phase 1
    99	- [ ] build it')"
   100	out="$(run "$R16" --project-doc "PROJECT/2-WORKING/GH-900-budgetscale.md" --out "$R16/packet" 2>&1)"; rc=$?
   101	grep -q "RELAY_TURN_TIMEOUT_S=900" "$R16/packet/packet.md" \
   102	  && pass "T16 GH-51[4]: 4-artifact build scales the budget to 900s" \
   103	  || fail "T16 expected 900s budget for 4 artifacts: $(grep RELAY_TURN_TIMEOUT_S "$R16/packet/packet.md")"
   104	# Foreign target (root != target) MUST still emit --target-root (cross-repo build needs it).
   105	fout="$(SWARM_PREFLIGHT_ROOT="$ROOT" bash "$SP" --target-root "$R16" --project-doc "$R16/PROJECT/2-WORKING/GH-900-budgetscale.md" --out "$R16/packet-foreign" 2>&1)"; frc=$?
   106	if [[ -f "$R16/packet-foreign/marathon-invocation.txt" ]]; then
   107	  # emitted path is the symlink-resolved git toplevel, so assert flag PRESENCE (not the raw $R16 path).
   108	  grep -q -- '--target-root ' "$R16/packet-foreign/marathon-invocation.txt" \
   109	    && pass "T16b foreign target emits --target-root <repo>" \
   110	    || fail "T16b foreign target must emit --target-root: $(cat "$R16/packet-foreign/marathon-invocation.txt")"
   111	else
   112	  fail "T16b foreign-target packet not written (rc=$frc): $fout"
   113	fi
   114	
   115	# ── T2: stale (fix already landed) → exit 4, no packet ───────────────────────
   116	R="$(make_repo stale '{
   117	  "target": { "repo": ".", "ref": "main" },
   118	  "gate": "true",
   119	  "fix_probes": [ { "type": "path_absent", "path": "PROJECT/2-WORKING/GH-900-stale.md" } ],
   120	  "artifacts": [ "src/a.js" ],
   121	  "remediation": { "criteria": "x" }
   122	}' '## Phase 1')"
   123	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-stale.md" --out "$R/packet" 2>&1)"; rc=$?
   124	[[ $rc -eq 4 ]] && pass "T2 stale → exit 4" || fail "T2 expected exit 4, got $rc — $out"
   125	[[ ! -d "$R/packet" ]] && pass "T2 no packet written for stale" || fail "T2 packet should not exist"
   126	
   127	# ── T3: not-ready (no gate) → exit 5 with one explicit next action ────────────
   128	R="$(make_repo notready '{
   129	  "target": { "repo": ".", "ref": "main" },
   130	  "gate": "",
   131	  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
   132	  "artifacts": [ "src/a.js" ],
   133	  "remediation": { "criteria": "x" }
   134	}' '## Phase 1')"
   135	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-notready.md" 2>&1)"; rc=$?
   136	[[ $rc -eq 5 ]] && pass "T3 not-ready → exit 5" || fail "T3 expected exit 5, got $rc — $out"
   137	grep -q "next: add a runnable gate" <<<"$out" && pass "T3 names one concrete next action" || fail "T3 missing next action: $out"
   138	
   139	# ── T4: blocked — target not a git repo → exit 6 ─────────────────────────────
   140	out="$(SWARM_PREFLIGHT_ROOT="$WORK" bash "$SP" --project-doc x.md --target-root "$WORK/not-a-repo" 2>&1)"; rc=$?
   141	[[ $rc -eq 6 ]] && pass "T4 non-git target → exit 6" || fail "T4 expected exit 6, got $rc — $out"
   142	
   143	# ── T5: blocked — gh-issue with no local capture doc → exit 6 ─────────────────
   144	R="$(make_repo nocap '{
   145	  "target": { "repo": ".", "ref": "main" },
   146	  "gate": "true",
   147	  "fix_probes": [ { "type": "path_absent", "path": "x" } ],
   148	  "artifacts": [ "a" ]
   149	}')"
   150	out="$(run "$R" --gh-issue 4242 2>&1)"; rc=$?
   151	[[ $rc -eq 6 ]] && pass "T5 missing GH capture → exit 6" || fail "T5 expected exit 6, got $rc — $out"
   152	grep -q "GUIDING-PRINCIPLES.md" <<<"$out" && pass "T5 cites the §11 rationale" || fail "T5 missing rationale: $out"
   153	
   154	# ── T6: contract missing → exit 3 (fail loud, no guessing) ────────────────────
   155	R="$WORK/nocontract"; mkdir -p "$R/PROJECT/2-WORKING"
   156	printf -- '---\ntitle: x\n---\n# x\nno contract here\n' >"$R/PROJECT/2-WORKING/GH-900-nocontract.md"
   157	git -C "$R" init -q && git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
   158	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-nocontract.md" 2>&1)"; rc=$?
   159	[[ $rc -eq 3 ]] && pass "T6 missing contract → exit 3" || fail "T6 expected exit 3, got $rc — $out"
   160	
   161	# ── T7: ambiguous bundle (gate mismatch across two issues) → exit 7 ──────────
   162	R="$WORK/bundle"; mkdir -p "$R/PROJECT/2-WORKING"
   163	mkcap() { printf -- '---\ntitle: %s\n---\n# %s\n## Swarm Preflight Contract\n```json\n%s\n```\n' "$1" "$1" "$2" >"$R/PROJECT/2-WORKING/GH-$3-$1.md"; }
   164	mkcap one '{ "target": { "repo": ".", "ref": "main" }, "gate": "true", "fix_probes": [ { "type": "path_absent", "path": "a" } ], "artifacts": [ "a" ] }' 11
   165	mkcap two '{ "target": { "repo": ".", "ref": "main" }, "gate": "false", "fix_probes": [ { "type": "path_absent", "path": "b" } ], "artifacts": [ "b" ] }' 12
   166	git -C "$R" init -q && git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
   167	out="$(run "$R" --gh-issue 11 --gh-issue 12 2>&1)"; rc=$?
   168	[[ $rc -eq 7 ]] && pass "T7 disagreeing bundle → exit 7" || fail "T7 expected exit 7, got $rc — $out"
   169	
   170	# ── T8: dry-run on a ready candidate → exit 0, NO packet ─────────────────────
   171	R="$(make_repo dryrun '{
   172	  "target": { "repo": ".", "ref": "main" },
   173	  "gate": "true",
   174	  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
   175	  "artifacts": [ "src/a.js" ],
   176	  "remediation": { "criteria": "x" }
   177	}' '## Phase 1')"
   178	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --out "$R/packet" --dry-run 2>&1)"; rc=$?
   179	[[ $rc -eq 0 ]] && pass "T8 dry-run exit 0" || fail "T8 expected exit 0, got $rc — $out"
   180	[[ ! -d "$R/packet" ]] && pass "T8 dry-run writes no packet" || fail "T8 dry-run must not write packet"
   181	
   182	# ── T8b/T8c/T8d: GH-30 Phase 2 — dry-run "Would emit to" follows the transcript-root resolver ──
   183	# Unset XYZ_ARCHIVE_ROOT → byte-for-byte the old "$ROOT/relay-system/preflight/…" path.
   184	out8b="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --dry-run 2>&1)"
   185	grep -q "Would emit to: $R/relay-system/preflight/" <<<"$out8b" \
   186	  && pass "T8b dry-run, XYZ_ARCHIVE_ROOT unset → \$ROOT/relay-system/preflight/ (regression-safe)" \
   187	  || fail "T8b expected \$R/relay-system/preflight/, got: $(grep 'Would emit' <<<"$out8b")"
   188	# Set XYZ_ARCHIVE_ROOT (a git repo, Model A) → namespaced $archive/relay-system/<repo-slug>/preflight/.
   189	# Fixture repo has no origin remote, so <repo-slug> falls back to its dir basename "dryrun".
   190	ARCH="$WORK/sp-archive"; git init -q "$ARCH"
   191	out8c="$(XYZ_ARCHIVE_ROOT="$ARCH" run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --dry-run 2>&1)"
   192	grep -q "Would emit to: $ARCH/relay-system/dryrun/preflight/" <<<"$out8c" \
   193	  && pass "T8c dry-run, XYZ_ARCHIVE_ROOT set → \$archive/relay-system/<slug>/preflight/ (namespaced)" \
   194	  || fail "T8c expected \$ARCH/relay-system/dryrun/preflight/, got: $(grep 'Would emit' <<<"$out8c")"
   195	# Explicit --out wins over BOTH the default and the archive redirect.
   196	out8d="$(XYZ_ARCHIVE_ROOT="$ARCH" run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --out "$R/named" --dry-run 2>&1)"
   197	grep -q "Would emit to: $R/named" <<<"$out8d" \
   198	  && pass "T8d explicit --out wins over the resolver/archive default" \
   199	  || fail "T8d expected \$R/named, got: $(grep 'Would emit' <<<"$out8d")"
   200	
   201	# ── T9: project-doc and gh-bundle normalize to the same shape (keys parity) ──
   202	R="$(make_repo parity '{
   203	  "target": { "repo": ".", "ref": "main" },
   204	  "gate": "true",
   205	  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
   206	  "artifacts": [ "src/a.js" ],
   207	  "remediation": { "criteria": "x" }
   208	}' '## Phase 1')"
   209	# rename so the same doc is reachable as GH-55 capture for the bundle path
   210	cp "$R/PROJECT/2-WORKING/GH-900-parity.md" "$R/PROJECT/2-WORKING/GH-55-parity.md"
   211	git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm add >/dev/null
   212	pj="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-parity.md" --format json 2>/dev/null)"
   213	gj="$(run "$R" --gh-issue 55 --format json 2>/dev/null)"
   214	kp="$(node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(Object.keys(o).concat(Object.keys(o.freshness)).sort().join(","))' <<<"$pj")"
   215	kg="$(node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(Object.keys(o).concat(Object.keys(o.freshness)).sort().join(","))' <<<"$gj")"
   216	[[ -n "$kp" && "$kp" == "$kg" ]] && pass "T9 both modes produce structurally identical shape" || fail "T9 shape mismatch: [$kp] vs [$kg]"
   217	
   218	# ── T10: usage errors → exit 2 ───────────────────────────────────────────────
   219	bash "$SP" >/dev/null 2>&1; [[ $? -eq 2 ]] && pass "T10a no input mode → exit 2" || fail "T10a expected exit 2"
   220	bash "$SP" --project-doc x --gh-issue 1 >/dev/null 2>&1; [[ $? -eq 2 ]] && pass "T10b mutually exclusive → exit 2" || fail "T10b expected exit 2"
   221	
   222	# ── T11: ref-honoring — a fix landed on a NON-checked-out ref is detected ─────
   223	# Regression lock for the starvation trap (the bug this fix closes): probes MUST evaluate
   224	# target.ref, not the current checkout. Build a repo on main WITHOUT the file, add it on
   225	# branch `feat`, leave main checked out, and declare ref: feat. Pre-fix this read "ready"
   226	# (absent on the main working tree); post-fix it must read "stale" (present on feat).
   227	R="$(make_repo reffix '{
   228	  "target": { "repo": ".", "ref": "feat" },
   229	  "gate": "true",
   230	  "fix_probes": [ { "type": "path_absent", "path": "LANDED_ON_FEAT.txt" } ],
   231	  "artifacts": [ "src/a.js" ],
   232	  "remediation": { "criteria": "x" }
   233	}' '## Phase 1')"
   234	git -C "$R" -c user.email=t@t -c user.name=t checkout -q -b feat
   235	echo x >"$R/LANDED_ON_FEAT.txt"
   236	git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm landed >/dev/null
   237	git -C "$R" -c user.email=t@t -c user.name=t checkout -q main   # STALE checkout: main lacks the file feat has
   238	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-reffix.md" 2>&1)"; rc=$?
   239	[[ $rc -eq 4 ]] && pass "T11 ref-honoring: fix on non-checked-out ref → stale (exit 4)" || fail "T11 expected exit 4 (probe must read target.ref=feat, not main), got $rc — $out"
   240	grep -q "behind the evaluated ref" <<<"$out" && pass "T11 report surfaces stale checkout vs evaluated ref" || fail "T11 missing staleness signal: $out"
   241	
   242	# ── T12: unresolvable target.ref → blocked, exit 6 (fail loud, not blind) ─────
   243	R="$(make_repo badref '{
   244	  "target": { "repo": ".", "ref": "origin/does-not-exist" },
   245	  "gate": "true",
   246	  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
   247	  "artifacts": [ "src/a.js" ],
   248	  "remediation": { "criteria": "x" }
   249	}' '## Phase 1')"
   250	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-badref.md" 2>&1)"; rc=$?
   251	[[ $rc -eq 6 ]] && pass "T12 unresolvable target.ref → exit 6" || fail "T12 expected exit 6, got $rc — $out"
   252	grep -q "does not resolve" <<<"$out" && pass "T12 names the unresolvable ref" || fail "T12 missing message: $out"
   253	
   254	# ── T13: GH-39 (A2) — a declared artifact path that doesn't exist at the ref → not-ready (exit 5) ──
   255	R="$(make_repo artmiss '{
   256	  "target": { "repo": ".", "ref": "main" },
   257	  "gate": "true",
   258	  "fix_probes": [ { "type": "path_absent", "path": "NEVER.txt" } ],
   259	  "artifacts": [ "src/does-not-exist.js" ],
   260	  "remediation": { "criteria": "x" }
   261	}' '## Phase 1')"
   262	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-artmiss.md" 2>&1)"; rc=$?
   263	[[ $rc -eq 5 ]] && pass "T13 GH-39: missing artifact path → not-ready (exit 5)" || fail "T13 expected exit 5, got $rc — $out"
   264	grep -q "artifact path not found" <<<"$out" && pass "T13 names the missing artifact path" || fail "T13 missing message: $out"
   265	
   266	# ── T14: GH-39 (A1) — a `bash <script>` gate whose script doesn't exist → not-ready (exit 5) ──
   267	R="$(make_repo gatemiss '{
   268	  "target": { "repo": ".", "ref": "main" },
   269	  "gate": "bash no-such-gate.sh",
   270	  "fix_probes": [ { "type": "path_absent", "path": "NEVER.txt" } ],
   271	  "artifacts": [ "src/a.js" ],
   272	  "remediation": { "criteria": "x" }
   273	}' '## Phase 1')"
   274	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gatemiss.md" 2>&1)"; rc=$?
   275	[[ $rc -eq 5 ]] && pass "T14 GH-39: unrunnable gate (missing script) → not-ready (exit 5)" || fail "T14 expected exit 5, got $rc — $out"
   276	grep -q "gate script not found" <<<"$out" && pass "T14 names the missing gate script" || fail "T14 missing message: $out"
   277	
   278	# ── T15: GH-39 (A1) — a gate WITH FLAGS (`bash -x <script>`) resolves the SCRIPT, not the flag ──
   279	R="$(make_repo gateflag '{
   280	  "target": { "repo": ".", "ref": "main" },
   281	  "gate": "bash -x src/a.js",
   282	  "fix_probes": [ { "type": "path_absent", "path": "NEVER.txt" } ],
   283	  "artifacts": [ "src/a.js" ],
   284	  "remediation": { "criteria": "x" }
   285	}' '## Phase 1')"
   286	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gateflag.md" 2>&1)"; rc=$?
   287	[[ $rc -eq 0 ]] && pass "T15 GH-39: gate with flags resolves the script, not the flag (ready)" || fail "T15 expected exit 0, got $rc — $out"
   288	
   289	# make_repo_risk <name> <risk> <contract-json> [extra-doc-body] → echoes the repo root
   290	# Same as make_repo but injects a `risk:` frontmatter field (GH-69 carve-out reads this).
   291	make_repo_risk() {
   292	  local name="$1" risk="$2" contract="$3" extra="${4:-}"
   293	  local r="$WORK/$name"
   294	  mkdir -p "$r/PROJECT/2-WORKING"
   295	  {
   296	    printf -- '---\ntitle: %s\nrisk: %s\n---\n# %s\n%s\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
   297	      "$name" "$risk" "$name" "$extra" "$contract"
   298	  } >"$r/PROJECT/2-WORKING/GH-900-$name.md"
   299	  mkdir -p "$r/src" "$r/test" "$r/relay-automation" "$r/bin"
   300	  : >"$r/src/a.js"; : >"$r/test/a.test.js"; : >"$r/a"; : >"$r/b"
   301	  : >"$r/relay-automation/relay-turn-lib.sh"; : >"$r/bin/tick"; : >"$r/relay-automation/relay-drive.sh"
   302	  git -C "$r" init -q -b main 2>/dev/null || { git -C "$r" init -q; git -C "$r" symbolic-ref HEAD refs/heads/main; }
   303	  git -C "$r" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
   304	  git -C "$r" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
   305	  printf '%s' "$r"
   306	}
   307	
   308	# ── T17 (GH-69): branch_ready reflects real branch existence; suggested_branch is slug+date ──
   309	R="$(make_repo_risk branchready 2 '{
   310	  "target": { "repo": ".", "ref": "main" },
   311	  "gate": "true",
   312	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   313	  "artifacts": [ "src/a.js" ],
   314	  "remediation": { "criteria": "x" }
   315	}')"
   316	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-branchready.md" --out "$R/packet" 2>&1)"
   317	grep -q "suggested=marathon/gh-900-branchready-2026-06-25" <<<"$out" \
   318	  && pass "T17a suggested_branch is slug+run-date" || fail "T17a wrong suggested_branch: $out"
   319	grep -q "branch_ready=false" <<<"$out" \
   320	  && pass "T17b branch_ready=false when the branch doesn't exist yet" || fail "T17b: $out"
   321	node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1]));process.exit(j.provenance.suggested_branch==="marathon/gh-900-branchready-2026-06-25"&&j.provenance.branch_ready===false?0:1)' \
   322	  "$R/packet/run-candidate.json" \
   323	  && pass "T17c run-candidate.json.provenance carries suggested_branch + branch_ready=false" \
   324	  || fail "T17c packet JSON shape wrong: $(cat "$R/packet/run-candidate.json")"
   325	grep -q "ask the operator before proceeding" "$R/packet/packet.md" \
   326	  && pass "T17d packet.md tells the orchestrator to ask before proceeding" || fail "T17d missing ask-operator note"
   327	
   328	# Now actually cut the suggested branch and re-run — branch_ready must flip to true.
   329	git -C "$R" branch marathon/gh-900-branchready-2026-06-25 >/dev/null 2>&1
   330	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-branchready.md" --out "$R/packet2" 2>&1)"
   331	grep -q "branch_ready=true" <<<"$out" \
   332	  && pass "T17e branch_ready=true once the suggested branch exists" || fail "T17e: $out"
   333	
   334	# ── T18 (GH-69): skip_branch_prompt carve-out — risk=1 + independent zone ──
   335	R="$(make_repo_risk lowrisk 1 '{
   336	  "target": { "repo": ".", "ref": "main" },
   337	  "gate": "true",
   338	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   339	  "artifacts": [ "src/a.js" ],
   340	  "remediation": { "criteria": "x" }
   341	}')"
   342	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-lowrisk.md" --out "$R/packet" 2>&1)"
   343	grep -q "skip_branch_prompt=true" <<<"$out" \
   344	  && pass "T18a risk=1 + independent artifacts → skip_branch_prompt=true" || fail "T18a: $out"
   345	grep -q "carve-out: risk=1/independent zone" "$R/packet/packet.md" \
   346	  && pass "T18b packet.md documents the carve-out instead of the ask-operator note" || fail "T18b: $(cat "$R/packet/packet.md" | grep 'Suggested branch')"
   347	
   348	# ── T19 (GH-69): carve-out does NOT apply when risk != 1 ──
   349	R="$(make_repo_risk midrisk 2 '{
   350	  "target": { "repo": ".", "ref": "main" },
   351	  "gate": "true",
   352	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   353	  "artifacts": [ "src/a.js" ],
   354	  "remediation": { "criteria": "x" }
   355	}')"
   356	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-midrisk.md" 2>&1)"
   357	grep -q "skip_branch_prompt=false" <<<"$out" \
   358	  && pass "T19a risk=2 → skip_branch_prompt=false (carve-out needs risk==1)" || fail "T19a: $out"
   359	
   360	# ── T20 (GH-69): carve-out does NOT apply when the zone is kernel, even at risk=1 ──
   361	R="$(make_repo_risk kernelrisk1 1 '{
   362	  "target": { "repo": ".", "ref": "main" },
   363	  "gate": "true",
   364	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   365	  "artifacts": [ "bin/tick" ],
   366	  "remediation": { "criteria": "x" }
   367	}')"
   368	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-kernelrisk1.md" 2>&1)"
   369	grep -q "skip_branch_prompt=false" <<<"$out" \
   370	  && pass "T20a risk=1 but kernel-zone artifact → skip_branch_prompt=false" || fail "T20a: $out"
   371	
   372	# ── T21 (GH-69, agy relay QA [Should]): kernel-path match is a PREFIX match, mirroring
   373	# marathon-plan.sh's `a === k || a.startsWith(k)` — a kernel-ADJACENT artifact (bin/tick+helper.sh,
   374	# which startsWith "bin/tick" but isn't an exact match) must still classify as kernel, not
   375	# independent, or the two planners disagree and the carve-out wrongly fires on a kernel-adjacent lane.
   376	R="$(make_repo_risk kernelprefix 1 '{
   377	  "target": { "repo": ".", "ref": "main" },
   378	  "gate": "true",
   379	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   380	  "artifacts": [ "bin/tick+helper.sh" ],
   381	  "remediation": { "criteria": "x" }
   382	}')"
   383	: >"$R/bin/tick+helper.sh"
   384	git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
   385	git -C "$R" -c user.email=t@t -c user.name=t commit -qm "add tick-helper" >/dev/null 2>&1
   386	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-kernelprefix.md" 2>&1)"
   387	grep -q "skip_branch_prompt=false" <<<"$out" \
   388	  && pass "T21a risk=1 but kernel-ADJACENT artifact (bin/tick+helper.sh) → skip_branch_prompt=false" \
   389	  || fail "T21a: $out"
   390	
   391	# ── T22 (GH-69, agy relay QA [Nit]): shim match is case-INSENSITIVE, mirroring SHIM_RE's `/i` — a
   392	# differently-cased shim path must still classify as shim (not independent), same as marathon-plan.sh.
   393	R="$(make_repo_risk shimcase 1 '{
   394	  "target": { "repo": ".", "ref": "main" },
   395	  "gate": "true",
   396	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   397	  "artifacts": [ "relay-automation/Codex-turn.sh" ],
   398	  "remediation": { "criteria": "x" }
   399	}')"
   400	: >"$R/relay-automation/Codex-turn.sh"
   401	git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
   402	git -C "$R" -c user.email=t@t -c user.name=t commit -qm "add Codex-turn.sh" >/dev/null 2>&1
   403	out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-shimcase.md" 2>&1)"
   404	grep -q "skip_branch_prompt=false" <<<"$out" \
   405	  && pass "T22a differently-cased shim path (Codex-turn.sh) still classifies as shim, not independent" \
   406	  || fail "T22a: $out"
   407	
   408	# ── T23 (GH-69, agy relay QA r2 [Nit]): a NESTED subdirectory under relay-automation/ must NOT
   409	# classify as shim — bash case globs match `/` (unlike marathon-plan.sh's SHIM_RE, whose
   410	# [a-z0-9-]+ class can't cross a path separator), so relay-automation/subdir/foo+turn.sh must be
   411	# independent, not shim. At risk=1 that makes it independent-zone → skip_branch_prompt=TRUE (the
   412	# opposite of T22, which is a direct, non-nested shim and should NOT skip).
   413	R="$(make_repo_risk shimnested 1 '{
   414	  "target": { "repo": ".", "ref": "main" },
   415	  "gate": "true",
   416	  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
   417	  "artifacts": [ "relay-automation/subdir/foo+turn.sh" ],
   418	  "remediation": { "criteria": "x" }
   419	}')"
   420	mkdir -p "$R/relay-automation/subdir"

codex
I have the relevant code paths. Next I’m checking the failure/override mechanics and whether the new `source` calls introduce any top-level side effects or vendored-path regressions.
exec
/bin/zsh -lc "rg -n \"GH-30 Phase 2|rtl_transcript_root|relay-turn-lib\\.sh|save_transcript|_cv_out_dir|OUT_DIR|set -euo|set -uo\" relay-automation/consult.sh relay-automation/marathon-drive.sh relay-automation/relay-drive.sh utils/swarm-preflight.sh relay-automation/relay-turn-lib.sh test/archive-writers.sh test/swarm-preflight.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
relay-automation/consult.sh:2:set -euo pipefail
relay-automation/consult.sh:54:# GH-30 Phase 2: the single transcript-root resolver (rtl_transcript_root) — redirects relay-system/
relay-automation/consult.sh:56:# beside relay-turn-lib.sh, so source it by the script's own dir (NOT $ROOT, which may be a foreign repo).
relay-automation/consult.sh:57:source "$HERE/relay-turn-lib.sh"
relay-automation/consult.sh:88:# GH-30 Phase 2: default the run parent to the transcript-root resolver (honors XYZ_ARCHIVE_ROOT).
relay-automation/consult.sh:92:  _ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
relay-automation/relay-turn-lib.sh:2:# relay-turn-lib.sh — shared, model-AGNOSTIC safety core for headless relay turn-takers.
relay-automation/relay-turn-lib.sh:58:#   rtl_transcript_root <target_root>   # <target_root> = the repo transcripts default under
relay-automation/relay-turn-lib.sh:69:rtl_transcript_root() {  # <target_root> → prints relay-system base; returns 1 on invalid archive
relay-automation/relay-turn-lib.sh:80:    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: %s\n' "$ar" >&2
relay-automation/relay-turn-lib.sh:84:    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): %s\n' "$ar" >&2
relay-automation/relay-turn-lib.sh:90:    printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): %s\n' "$ar" >&2
relay-automation/relay-turn-lib.sh:567:  # commit changed a shared surface — the containment kernel (relay-turn-lib.sh), the projection API
relay-automation/relay-turn-lib.sh:577:      for _surf in relay-automation/relay-turn-lib.sh src/project.js src/events.js; do
test/archive-writers.sh:2:# archive-writers.sh — GH-30 Phase 2: the transcript writers honor the rtl_transcript_root resolver.
test/archive-writers.sh:12:#   - each sources relay-turn-lib.sh AND calls rtl_transcript_root
test/archive-writers.sh:70:  grep -q 'source .*relay-turn-lib.sh' "$f" || fail "$base: does not source relay-turn-lib.sh"
test/archive-writers.sh:71:  grep -q 'rtl_transcript_root' "$f"        || fail "$base: does not call rtl_transcript_root"
test/archive-writers.sh:76:  pass "$base: sources + calls rtl_transcript_root, no hardcoded relay-system default"
relay-automation/relay-drive.sh:2:set -euo pipefail
relay-automation/relay-drive.sh:29:# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
relay-automation/relay-drive.sh:31:source "$(dirname "${BASH_SOURCE[0]}")/relay-turn-lib.sh"
relay-automation/relay-drive.sh:43:# reset) exactly once. Byte-consistent mirror in marathon-drive.sh; relay-turn-lib.sh/bin/tick untouched.
relay-automation/relay-drive.sh:180:# shim resolves it against RELAY_TARGET_ROOT in relay-turn-lib.sh.)
relay-automation/relay-drive.sh:321:    # GH-30 Phase 2: consult-verify transcripts follow the resolver (honors XYZ_ARCHIVE_ROOT). The
relay-automation/relay-drive.sh:323:    _cv_out_dir="$(rtl_transcript_root "$ROOT_DIR")/$(date +%F)" || exit 1
relay-automation/relay-drive.sh:331:      --out "$_cv_out_dir" 2>/dev/null)" || true
relay-automation/marathon-drive.sh:2:set -euo pipefail
relay-automation/marathon-drive.sh:46:# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
relay-automation/marathon-drive.sh:48:source "$HERE/relay-turn-lib.sh"
relay-automation/marathon-drive.sh:60:# reset) exactly once. Byte-consistent mirror in relay-drive.sh; relay-turn-lib.sh/bin/tick untouched.
relay-automation/marathon-drive.sh:239:# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
relay-automation/marathon-drive.sh:439:save_transcript() {
relay-automation/marathon-drive.sh:440:  # GH-30 Phase 2: resolve the transcript base (honors XYZ_ARCHIVE_ROOT; hard-errors if set-invalid).
relay-automation/marathon-drive.sh:442:  local date_dir _ts_base; _ts_base="$(rtl_transcript_root "$ROOT")" || return 1
relay-automation/marathon-drive.sh:468:    save_transcript
utils/swarm-preflight.sh:47:set -uo pipefail
utils/swarm-preflight.sh:59:# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
utils/swarm-preflight.sh:60:# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". relay-turn-lib.sh is a sibling
utils/swarm-preflight.sh:62:source "$HERE/../relay-automation/relay-turn-lib.sh"
utils/swarm-preflight.sh:92:OUT_DIR=""
utils/swarm-preflight.sh:101:    --out)         OUT_DIR="${2:-}"; shift 2 ;;
utils/swarm-preflight.sh:235:const orchOnly = (c.lanes && c.lanes.orchestrator_only) || ["bin/", ".tick/", "relay-automation/relay-turn-lib.sh"];
utils/swarm-preflight.sh:462:ZONE_KERNEL_PATHS=(relay-automation/relay-turn-lib.sh bin/tick relay-automation/relay-drive.sh)
utils/swarm-preflight.sh:477:      # `${x,,}` — stock macOS bash is 3.2 (this repo's scripts stay 3.2-portable; see relay-turn-lib.sh).
utils/swarm-preflight.sh:607:# GH-30 Phase 2: resolve the packet output dir ONCE (honors XYZ_ARCHIVE_ROOT), so the dry-run preview
utils/swarm-preflight.sh:608:# and the real emit agree. An explicit --out (OUT_DIR set) wins and skips the resolver entirely, so an
utils/swarm-preflight.sh:610:if [[ -z "$OUT_DIR" ]]; then
utils/swarm-preflight.sh:611:  _sp_ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
utils/swarm-preflight.sh:612:  OUT_DIR="$_sp_ts_base/preflight/$TODAY/$SLUG"
utils/swarm-preflight.sh:617:    emit ""; emit "DRY-RUN: ready, but packet not written. Would emit to: $OUT_DIR"
utils/swarm-preflight.sh:624:mkdir -p "$OUT_DIR"
utils/swarm-preflight.sh:625:cp "$TMP/run-candidate.json" "$OUT_DIR/run-candidate.json"
utils/swarm-preflight.sh:626:cp "$TMP/lane-plan.json" "$OUT_DIR/lane-plan.json"
utils/swarm-preflight.sh:627:SP_F="$TMP/run-candidate.json" SP_K=freshness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/freshness.json"
utils/swarm-preflight.sh:628:SP_F="$TMP/run-candidate.json" SP_K=readiness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/readiness.json"
utils/swarm-preflight.sh:629:printf '%s\n' "$INVOCATION" >"$OUT_DIR/marathon-invocation.txt"
utils/swarm-preflight.sh:650:cat >"$OUT_DIR/packet.md" <<EOF
utils/swarm-preflight.sh:690:  log "packet written: $OUT_DIR"
utils/swarm-preflight.sh:692:  emit ""; emit "Packet written: $OUT_DIR"
test/swarm-preflight.sh:9:set -uo pipefail
test/swarm-preflight.sh:182:# ── T8b/T8c/T8d: GH-30 Phase 2 — dry-run "Would emit to" follows the transcript-root resolver ──
test/swarm-preflight.sh:301:  : >"$r/relay-automation/relay-turn-lib.sh"; : >"$r/bin/tick"; : >"$r/relay-automation/relay-drive.sh"

exec
/bin/zsh -lc "awk 'BEGIN{in=0} /"'^[A-Za-z_][A-Za-z0-9_]*'"\\(\\)[[:space:]]*\\{/ {print NR \":FUNC \" "'$0; next} /''^[[:space:]]*#/ || /''^[[:space:]]*$/ {next} {print NR ":TOP " $0}'"' relay-automation/relay-turn-lib.sh | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
awk: syntax error at source line 1
 context is
	 >>> BEGIN{in <<< =0} /^[A-Za-z_][A-Za-z0-9_]*\(\)[[:space:]]*\{/ {print NR ":FUNC " $0; next} /^[[:space:]]*#/ || /^[[:space:]]*$/ {next} {print NR ":TOP " $0}
awk: illegal statement at source line 1
	missing }

exec
/bin/zsh -lc 'bash -n relay-automation/relay-turn-lib.sh && echo OK' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
OK

codex
The lib parses cleanly. I’m doing one more pass on whether sourcing it can execute anything at load time versus only defining functions.
exec
/bin/zsh -lc "perl -ne 'if (/"'^[A-Za-z_][A-Za-z0-9_]*'"\\(\\)[[:space:]]*\\{/) { print "'$. . ":FUNC $_"; next } if (/''^'"\\s*#/ || /"'^'"\\s*"'$/) { next } print $. . ":TOP $_"'"' relay-automation/relay-turn-lib.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
41:FUNC rtl_is_reviewer_turn() {  # <relay_file> — true if the file's NEXT pointer names the Reviewer role
46:TOP   local f="$1" line
47:TOP   [[ -f "$f" ]] || return 1
48:TOP   line="$(grep -iE '^[[:space:]]*NEXT:' "$f" 2>/dev/null | head -1)"
49:TOP   printf '%s' "$line" | grep -iqE 'Reviewer'
50:TOP }
69:FUNC rtl_transcript_root() {  # <target_root> → prints relay-system base; returns 1 on invalid archive
73:TOP   local target_root="${1%/}"
74:TOP   if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
75:TOP     printf '%s/relay-system' "$target_root"
76:TOP     return 0
77:TOP   fi
78:TOP   local ar="$XYZ_ARCHIVE_ROOT"
79:TOP   if [[ "$ar" != /* ]]; then
80:TOP     printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: %s\n' "$ar" >&2
81:TOP     return 1
82:TOP   fi
83:TOP   if [[ ! -d "$ar" ]]; then
84:TOP     printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): %s\n' "$ar" >&2
85:TOP     return 1
86:TOP   fi
89:TOP   if ! git -C "$ar" rev-parse --git-dir >/dev/null 2>&1; then
90:TOP     printf 'rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): %s\n' "$ar" >&2
91:TOP     return 1
92:TOP   fi
93:TOP   printf '%s/relay-system/%s' "$ar" "$(rtl_repo_slug "$target_root")"
94:TOP }
100:FUNC rtl_repo_slug() {  # <target_root>
101:TOP   local target_root="$1" url slug
102:TOP   url="$(git -C "$target_root" remote get-url origin 2>/dev/null || true)"
103:TOP   while [[ "$url" == */ ]]; do url="${url%/}"; done   # tolerate a trailing-slash remote (…/foo/ or …/foo.git/)
104:TOP   url="${url%.git}"
105:TOP   while [[ "$url" == */ ]]; do url="${url%/}"; done
106:TOP   if [[ -n "$url" ]]; then
107:TOP     slug="${url##*/}"; slug="${slug##*:}"   # strip path AND scp-style host: prefix
108:TOP   fi
109:TOP   [[ -z "${slug:-}" ]] && slug="$(basename -- "$target_root" 2>/dev/null || true)"
110:TOP   slug="$(printf '%s' "${slug:-repo}" | tr -c 'A-Za-z0-9._-' '_')"
111:TOP   while [[ "$slug" == -* ]]; do slug="${slug#-}"; done   # never option-shaped
112:TOP   case "$slug" in ''|.|..) slug="repo" ;; esac           # never empty or a path-traversal segment
113:TOP   printf '%s' "$slug"
114:TOP }
116:FUNC rtl_init() {  # <root> <relay_file> <allow_csv>
121:TOP   RTL_ROOT="${RELAY_TARGET_ROOT:-$1}"; local f="$2" csv="$3"
135:TOP   if [[ -n "${RELAY_TARGET_ROOT:-}" ]]; then
136:TOP     local _tt _ct _c1; _tt="$(git -C "$RTL_ROOT" rev-parse --show-toplevel 2>/dev/null)"
137:TOP     _ct="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"
138:TOP     _c1="$(cd "$1" 2>/dev/null && pwd -P)"
139:TOP     if [[ -n "$_tt" && "$_tt" == "$_ct" ]]; then
140:TOP       if [[ "$_c1" == "$_ct" ]]; then RTL_ROOT="$1"; else RTL_ROOT="$_tt"; fi
141:TOP     fi
142:TOP   fi
149:TOP   RTL_IGNORECASE="$(git -C "$RTL_ROOT" config --get core.ignorecase 2>/dev/null || echo false)"
150:TOP   [[ "$RTL_IGNORECASE" == "true" ]] || RTL_IGNORECASE=false
151:TOP   RTL_WT_USED=0          # set to 1 by rtl_worktree_begin; read by rtl_enforce's commit-bypass guard (GH-13)
152:TOP   RTL_ALLOW=("$f")
159:TOP   if rtl_is_reviewer_turn "$f"; then
160:TOP     [[ -n "$csv" ]] && printf 'relay-turn: REVIEWER turn — scoping allowlist to the relay file only (ignoring ALLOW_PATHS=%s)\n' "$csv" >&2
161:TOP     csv=""
162:TOP   fi
163:TOP   local _extra p; IFS=',' read -ra _extra <<<"$csv"
164:TOP   for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
165:TOP   local _n=() a                       # normalize to repo-root-relative (git status emits relative)
166:TOP   for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
167:TOP   RTL_ALLOW=("${_n[@]}")
173:TOP   RTL_ARTIFACT="${RELAY_ARTIFACT_FILE:-}"
174:TOP   RTL_ARTIFACT_REL=""
177:TOP   if [[ -n "$RTL_ARTIFACT" ]]; then
178:TOP     RTL_ARTIFACT_REL=".relay-artifacts/$(basename "$RTL_ARTIFACT")"
179:TOP   fi
180:TOP }
182:FUNC rtl_in_allow() {  # <path> — is <path> on the allowlist? Case-insensitive when RTL_IGNORECASE=true (GH-17).
183:TOP   local x="$1" a
188:TOP   if [[ "$x" == */ ]]; then
189:TOP     local dir="${x%/}"
190:TOP     if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
191:TOP       local dl al; dl="$(printf '%s' "$dir/" | tr '[:upper:]' '[:lower:]')"
192:TOP       for a in "${RTL_ALLOW[@]}"; do
193:TOP         al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
194:TOP         [[ "$al" == "$dl"* && "$al" != "$dl" ]] && return 0
195:TOP       done
196:TOP     else
197:TOP       for a in "${RTL_ALLOW[@]}"; do [[ "$a" == "$dir/"* && "$a" != "$dir/" ]] && return 0; done
198:TOP     fi
199:TOP   fi
200:TOP   if [[ "${RTL_IGNORECASE:-false}" == "true" ]]; then
202:TOP     local xl al; xl="$(printf '%s' "$x" | tr '[:upper:]' '[:lower:]')"
203:TOP     for a in "${RTL_ALLOW[@]}"; do
204:TOP       al="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
205:TOP       [[ "$xl" == "$al" ]] && return 0
206:TOP     done
207:TOP     return 1
208:TOP   fi
209:TOP   for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done
210:TOP   return 1
211:TOP }
213:FUNC rtl_run_bounded() {  # <timeout_secs> <cmd...>
221:TOP   local secs="$1"; shift
222:TOP   local apid kpid rc=0
223:TOP   "$@" &
224:TOP   apid=$!
225:TOP   ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
226:TOP   kpid=$!
227:TOP   wait "$apid" 2>/dev/null || rc=$?
228:TOP   kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
233:TOP   if [[ "$rc" -eq 137 ]]; then
234:TOP     return 7
235:TOP   fi
236:TOP   return "$rc"
237:TOP }
256:FUNC _rtl_sig() {  # <path> — content signature of a file/dir, or "ABSENT". Used to detect what the turn
259:TOP   local p="$1"
260:TOP   if [[ -f "$p" ]]; then
261:TOP     git hash-object -- "$p" 2>/dev/null || echo "ERR:$p"
262:TOP   elif [[ -d "$p" ]]; then
264:TOP     ( cd "$p" 2>/dev/null && find . -type f -print0 2>/dev/null | LC_ALL=C sort -z \
265:TOP         | xargs -0 git hash-object 2>/dev/null ) | git hash-object --stdin 2>/dev/null || echo "ERR:$p"
266:TOP   else
267:TOP     echo "ABSENT"
268:TOP   fi
269:TOP }
271:FUNC rtl_worktree_begin() {
275:TOP   local wt a
276:TOP   wt="$(mktemp -d "${TMPDIR:-/tmp}/rtl-wt.XXXXXX")" || return 1
277:TOP   rm -rf "$wt"                         # git worktree add wants a non-existent path
278:TOP   if ! git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
279:TOP     rm -rf "$wt" 2>/dev/null; return 1
280:TOP   fi
281:TOP   for a in "${RTL_ALLOW[@]}"; do       # seed current content (overwrite HEAD versions)
282:TOP     if [[ -e "$RTL_ROOT/$a" ]]; then
283:TOP       mkdir -p "$wt/$(dirname "$a")"
284:TOP       cp -R "$RTL_ROOT/$a" "$wt/$a"
285:TOP     else
286:TOP       rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
288:TOP     fi                                 # (Codex review r2, 2026-06-20 — symmetric to the in-turn delete)
289:TOP   done
296:TOP   : >"${wt}.seedsig"
297:TOP   for a in "${RTL_ALLOW[@]}"; do _rtl_sig "$wt/$a" >>"${wt}.seedsig"; done
302:TOP   if [[ -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
303:TOP     mkdir -p "$wt/.relay-artifacts"
304:TOP     cp "$RTL_ARTIFACT" "$wt/$RTL_ARTIFACT_REL"
305:TOP     _rtl_sig "$wt/.relay-artifacts" >"${wt}.artifactsig"
306:TOP   fi
307:TOP   RTL_WT="$wt"; RTL_WT_USED=1   # GH-13: mark the turn worktree-isolated so rtl_enforce won't reset a concurrent peer's ROOT commit
308:TOP   printf '%s\n' "$wt"
309:TOP }
311:FUNC rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist back unless off-lane found
318:TOP   local wt="${1:-${RTL_WT:-}}" a entry xy path
319:TOP   RTL_WT_OFFLANE=0
320:TOP   [[ -n "$wt" && -d "$wt" ]] || return 0
330:TOP   RTL_WT_USED=1
331:TOP   while IFS= read -r -d '' entry; do
332:TOP     [[ -n "$entry" ]] || continue
333:TOP     xy="${entry:0:2}"; path="${entry:3}"
334:TOP     case "$xy" in R*|C*) IFS= read -r -d '' _ || true ;; esac   # rename/copy: consume 2nd NUL field
335:TOP     case "$path" in .tick/*|.tick) continue ;; esac
339:TOP     case "$path" in
340:TOP       .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
341:TOP         if [[ -f "${wt}.artifactsig" ]] && [[ "$(_rtl_sig "$wt/.relay-artifacts")" == "$(cat "${wt}.artifactsig")" ]]; then
342:TOP           continue
343:TOP         fi
344:TOP         RTL_WT_OFFLANE=1; continue ;;
345:TOP     esac
346:TOP     rtl_in_allow "$path" && continue
347:TOP     RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
348:TOP   done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
349:TOP   if ((RTL_WT_OFFLANE == 0)); then
350:TOP     local i=0 seedsig nowsig _ln; local _seeds=()
352:TOP     if [[ -f "${wt}.seedsig" ]]; then
353:TOP       while IFS= read -r _ln; do _seeds+=("$_ln"); done <"${wt}.seedsig"
354:TOP     fi
355:TOP     for a in "${RTL_ALLOW[@]}"; do
360:TOP       seedsig="${_seeds[i]-}"; i=$((i+1))
361:TOP       nowsig="$(_rtl_sig "$wt/$a")"
362:TOP       [[ -n "$seedsig" && "$nowsig" == "$seedsig" ]] && continue
363:TOP       if [[ -e "$wt/$a" ]]; then
364:TOP         mkdir -p "$RTL_ROOT/$(dirname "$a")"
365:TOP         cp -R "$wt/$a" "$RTL_ROOT/$a"
366:TOP       elif [[ -e "$RTL_ROOT/$a" ]]; then
367:TOP         rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
368:TOP       fi
369:TOP     done
370:TOP   fi
371:TOP   rm -f "${wt}.seedsig" "${wt}.artifactsig"   # GH-22 + GH-31: clean up the sidecar signature files
372:TOP   git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
373:TOP   git -C "$RTL_ROOT" worktree prune >/dev/null 2>&1 || true
374:TOP   RTL_WT=""
375:TOP }
377:FUNC rtl_turn_prompt() {  # <agent> <relay_file> <task> <allow_csv> [peer]
378:TOP   local agent="$1" f="$2" task="$3" csv="$4" peer="${5:-}"
381:TOP   local handoff="release --to the other agent (the role named by NEXT in the file)"
382:TOP   [[ -n "$peer" ]] && handoff="release --to ${peer}"
394:TOP   local root="${RTL_ROOT:-}" tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}" f_rel csv_rel="" p _a
395:TOP   f_rel="${f#"${root:+$root/}"}"
396:TOP   if [[ -n "$csv" ]]; then
397:TOP     IFS=',' read -ra _a <<<"$csv"
398:TOP     for p in "${_a[@]}"; do [[ -n "$p" ]] && csv_rel+="${csv_rel:+,}${p#"${root:+$root/}"}"; done
399:TOP   fi
403:TOP   local role_note=""
404:TOP   if rtl_is_reviewer_turn "$f"; then
405:TOP     csv_rel=""
406:TOP     role_note=' You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn.'
407:TOP   fi
410:TOP   local art_note=""
411:TOP   [[ -n "${RTL_ARTIFACT_REL:-}" ]] && art_note=" The artifact under review is at ${RTL_ARTIFACT_REL} — READ it for your review, but do NOT edit it (any edit fails your turn)."
412:TOP   printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. For the %s token ALWAYS use the absolute, env-pinned tick — a bare or ./bin/tick from a worktree/foreign CWD silently no-ops and DEADLOCKS the relay: TICK_REPO_ROOT="%s" "%s/bin/tick". Token sequence: (1) claim it FIRST — claim %s --agent %s --paths %s — the --paths flag is MANDATORY; without it the claim silently fails (prints usage) and your later release errors "task ... is open". (2) ping is optional. (3) when finished, %s (or done + set STATUS: Approved when approving). Edit ONLY %s%s.%s%s NEVER run git yourself — no add/commit/push/reset; a self-commit FAILS your whole turn. Do NOT touch any other file. The harness makes the one file-scoped commit for you after you hand off the token. Do NOT run the full project test/gate suite (e.g. validate.sh) yourself — running it can create files that trip containment and DISCARD your whole turn; verify ONLY with the specific test for the file(s) you changed. The harness runs the gate after your turn.' \
413:TOP     "$agent" "$f_rel" "$task" "$tickroot" "$tickroot" "$task" "$agent" "$f_rel" "$handoff" "$f_rel" "${csv_rel:+ and: $csv_rel}" "$role_note" "$art_note"
414:TOP }
416:FUNC rtl_before() {
417:TOP   RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
420:TOP   RTL_BEFORE=()
421:TOP   local fld
422:TOP   while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
423:TOP     < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
424:TOP }
426:FUNC rtl_was_dirty_before() {  # <porcelain-entry> — true if this exact status+path was dirty pre-turn
427:TOP   local e="$1" b
428:TOP   for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
429:TOP   return 1
430:TOP }
432:FUNC rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
433:TOP   local p="$1"
434:TOP   [[ -n "$p" ]] || return 0
437:TOP   case "$p" in .tick/*|.tick) return 0 ;; esac
439:TOP   if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
440:TOP   rtl_in_allow "$p" && return 0
441:TOP   printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
442:TOP   git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
443:TOP   RTL_VIOLATION=1
444:TOP }
446:FUNC rtl_enforce() {  # <task> <agent> <log> <tool>
447:TOP   local task="$1" agent="$2" log="$3"; RTL_TOOL="$4"
450:TOP   if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
451:TOP     if [[ "${RTL_WT_USED:-0}" == "1" ]]; then
457:TOP       printf '%s-turn: ROOT HEAD moved during a worktree-isolated turn — a concurrent peer committed; preserving it (not resetting), committing this turn on top.\n' "$RTL_TOOL" >&2
458:TOP     else
466:TOP       git -C "$RTL_ROOT" update-ref "refs/relay-orphan/$(git -C "$RTL_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)" HEAD 2>/dev/null || true
467:TOP       git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
468:TOP       printf '%s-turn: %s committed during its turn (forbidden) — reset to %s (prior HEAD saved to refs/relay-orphan/), failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
469:TOP       exit 6
470:TOP     fi
471:TOP   fi
477:TOP   RTL_LOG_REL="${log:+${log#"$RTL_ROOT"/}}"
478:TOP   RTL_VIOLATION=0
482:TOP   local entry xy path src
483:TOP   while IFS= read -r -d '' entry; do
484:TOP     [[ -n "$entry" ]] || continue
485:TOP     xy="${entry:0:2}"; path="${entry:3}"
486:TOP     case "$xy" in
487:TOP       R*|C*)
488:TOP         IFS= read -r -d '' src || true
492:TOP         if rtl_was_dirty_before "$entry" && rtl_was_dirty_before "$src"; then continue; fi
493:TOP         rtl_check "$path"; rtl_check "$src"
494:TOP         ;;
495:TOP       *)
496:TOP         rtl_was_dirty_before "$entry" && continue
497:TOP         rtl_check "$path"
498:TOP         ;;
499:TOP     esac
500:TOP   done < <(git -C "$RTL_ROOT" status --porcelain -z)

exec
/bin/zsh -lc 'nl -ba relay-automation/relay-turn-lib.sh | tail -n 40' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
   596	# per-device, gitignored): only drift events NEWER than the watermark and NOT authored by <agent> are
   597	# surfaced; the watermark then advances past everything scanned. Idempotent — a crash before the
   598	# advance just re-injects the same notice next turn, which is harmless. Capped at the 5 most recent
   599	# (older ones summarized as a count). Echoes NOTHING when there is no unread drift, so the default
   600	# turn-prompt path is unchanged. See decisions/2026-07-01-cross-agent-dep-conflict.md §4–5.
   601	rtl_drift_brief() {  # <agent> <tickroot>
   602	  local me="$1" tickroot="$2"
   603	  [[ -n "$me" && -n "$tickroot" ]] || return 0
   604	  local evdir="$tickroot/.tick/events"
   605	  [[ -d "$evdir" ]] || return 0
   606	  local seg; seg="$(printf '%s' "$me" | tr -c 'A-Za-z0-9._-' '_')"
   607	  local wmfile="$tickroot/.tick/dep-drift-watermark-$seg"
   608	  local wm=""; [[ -f "$wmfile" ]] && wm="$(head -n1 "$wmfile" 2>/dev/null || true)"
   609	  local f base newest="$wm"
   610	  local -a unread=()
   611	  # drift event filenames embed the action token 'dependency.drift' (appendEvent naming); the ISO-ts
   612	  # prefix makes lexicographic order == chronological (LC_ALL=C for a stable ASCII sort).
   613	  while IFS= read -r f; do
   614	    [[ -n "$f" ]] || continue
   615	    base="$(basename "$f")"
   616	    if [[ -n "$wm" ]] && ! [[ "$base" > "$wm" ]]; then continue; fi   # already processed (<= watermark)
   617	    [[ "$base" > "$newest" ]] && newest="$base"
   618	    grep -Fq "\"agent\":\"$me\"" "$f" 2>/dev/null && continue          # skip the agent's OWN changes
   619	    unread+=("$f")
   620	  done < <(LC_ALL=C ls -1 "$evdir"/*dependency.drift*.jsonl 2>/dev/null | LC_ALL=C sort)
   621	  [[ -n "$newest" ]] && printf '%s\n' "$newest" > "$wmfile" 2>/dev/null || true
   622	  local n=${#unread[@]}
   623	  ((n)) || return 0
   624	  local start=0; ((n>5)) && start=$((n-5))
   625	  printf '\n[cross-agent dependency drift — informational, warn-only; re-check if your task depends on these]\n'
   626	  local i surf dl ag
   627	  for ((i=start;i<n;i++)); do
   628	    surf="$(sed -n 's/.*"surface":"\([^"]*\)".*/\1/p' "${unread[$i]}" | head -n1)"
   629	    dl="$(sed -n 's/.*"diff_lines":\([0-9]*\).*/\1/p' "${unread[$i]}" | head -n1)"
   630	    ag="$(sed -n 's/.*"agent":"\([^"]*\)".*/\1/p' "${unread[$i]}" | head -n1)"
   631	    printf -- '- %s changed %s (%s lines) since your last turn.\n' "${ag:-a peer}" "${surf:-?}" "${dl:-?}"
   632	  done
   633	  ((n>5)) && printf -- '+%d earlier drift event(s) omitted — see .tick/events/ for full history.\n' "$((n-5))"
   634	  return 0
   635	}

codex
There’s one subtle shell-semantic risk left: `relay-drive.sh` combines `rtl_transcript_root` and `date` in the same assignment. I’m checking whether a failing first substitution is masked by the second one.
exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; f(){ return 1; }; x=\""'$(f)/$(date +%F)" || echo caught; rc=$?; printf "rc=%s x=%s'"\\n\" \""'$rc" "$x"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689
 succeeded in 0ms:
rc=0 x=/2026-07-03

codex
**Answer**
No. Phase 2 is not safe to merge as-is: `consult.sh`, `marathon-drive.sh`, and `swarm-preflight.sh` are wired correctly, but `relay-drive.sh` does not fail loud on an invalid `XYZ_ARCHIVE_ROOT` in its `consult-verify` writer because the resolver failure is masked and the downstream `consult.sh` failure is swallowed ([relay-drive.sh:323](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:323), [relay-drive.sh:331](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:331)).

**Findings**
1. `[Pass] Regression safety.` With `XYZ_ARCHIVE_ROOT` unset, the resolver prints exactly `"$target_root/relay-system"` ([relay-turn-lib.sh:73](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:73), [relay-turn-lib.sh:75](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:75)). The four writers append the same suffixes as before: consult uses `"$ROOT/relay-system/<date>/<label>-<time>"` ([consult.sh:91](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:91)), marathon uses `"$ROOT/relay-system/<date>/marathon-..."` ([marathon-drive.sh:442](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:442)), relay-drive uses `"$ROOT_DIR/relay-system/<date>"` for consult-verify ([relay-drive.sh:323](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:323)), and swarm-preflight uses `"$ROOT/relay-system/preflight/<date>/<slug>"` ([swarm-preflight.sh:610](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:610)). The roots themselves come from `pwd`-style resolution, and the resolver strips any trailing slash, so I do not see an unset-path slash regression ([consult.sh:52](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:52), [marathon-drive.sh:36](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:36), [relay-drive.sh:28](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:28), [swarm-preflight.sh:49](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:49)).

2. `[Pass] Override-wins.` The two writers that expose override surfaces gate the resolver behind an empty override check: consult only resolves when `OUT` is empty ([consult.sh:65](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:65), [consult.sh:91](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:91)), and swarm-preflight only resolves when `OUT_DIR` is empty ([swarm-preflight.sh:92](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:92), [swarm-preflight.sh:610](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:610)). Marathon and relay-drive do not offer a transcript-dir override flag in this phase, so there is no override contract for them to violate ([marathon-drive.sh:10](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:10), [relay-drive.sh:117](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:117)).

3. `[Blocker] Fail-loud is broken in relay-drive's consult-verify path.` Consult and swarm use the safe single-substitution form `x="$(rtl_transcript_root ...)" || exit 1` ([consult.sh:92](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:92), [swarm-preflight.sh:611](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:611)); marathon also preserves the resolver rc by separating `local` from the assignment, and the bare `save_transcript` call is under `set -e`, so a `return 1` aborts the script before any transcript write ([marathon-drive.sh:2](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:2), [marathon-drive.sh:442](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:442), [marathon-drive.sh:468](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:468)). Relay-drive is different: `_cv_out_dir="$(rtl_transcript_root "$ROOT_DIR")/$(date +%F)" || exit 1` puts a second command substitution in the same assignment, so a failing resolver is masked by the succeeding `date`, and then the consult invocation is explicitly swallowed with `|| true` ([relay-drive.sh:323](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:323), [relay-drive.sh:331](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:331)). That violates the stated hard-error/no-fallback contract.

4. `[Pass] Source-path robustness.` All four scripts source the lib by their own directory, not by `$ROOT`, which is the right choice for both the central checkout and a vendored `.xyz` layout: consult and marathon source a sibling file ([consult.sh:52](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:52), [consult.sh:57](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:57), [marathon-drive.sh:36](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:36), [marathon-drive.sh:48](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:48)), relay-drive does the same via `dirname "${BASH_SOURCE[0]}"` ([relay-drive.sh:31](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:31)), and swarm correctly walks from `utils/` to sibling `relay-automation/` ([swarm-preflight.sh:49](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:49), [swarm-preflight.sh:62](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:62)).

5. `[Pass] Side effects of sourcing look acceptable.` The lib is intentionally namespaced around `rtl_*` functions and `RTL_*` globals ([relay-turn-lib.sh:17](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:17)), and the sourcing sites only depend on `rtl_transcript_root` ([consult.sh:57](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:57), [swarm-preflight.sh:62](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:62)). I do not see top-level work in the file; it is a function library from the first function definition onward ([relay-turn-lib.sh:41](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:41), [relay-turn-lib.sh:601](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:601)). Under `set -e`, a missing or syntactically bad lib would abort consult/marathon/relay-drive immediately, but that is a packaging failure, not a new behavioral side effect.

6. `[Should] Test adequacy is not enough for this phase.` `test/archive-writers.sh` proves the behavior end-to-end only through `consult.sh`; the other writers get structural greps only ([archive-writers.sh:3](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/archive-writers.sh:3), [archive-writers.sh:67](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/archive-writers.sh:67)). That did not catch the real `relay-drive.sh:323` bug, and it would also miss future re-hardcodes done via an intermediate variable rather than the exact literal pattern it greps for ([archive-writers.sh:73](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/archive-writers.sh:73)). The swarm T8b/T8c/T8d block is useful, but it only checks dry-run preview strings and override text; it does not cover the invalid-archive fail-loud path ([swarm-preflight.sh test:182](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/swarm-preflight.sh:182)).

**Recommendation**
Changes required.
tokens used
103,668
**Answer**
No. Phase 2 is not safe to merge as-is: `consult.sh`, `marathon-drive.sh`, and `swarm-preflight.sh` are wired correctly, but `relay-drive.sh` does not fail loud on an invalid `XYZ_ARCHIVE_ROOT` in its `consult-verify` writer because the resolver failure is masked and the downstream `consult.sh` failure is swallowed ([relay-drive.sh:323](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:323), [relay-drive.sh:331](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:331)).

**Findings**
1. `[Pass] Regression safety.` With `XYZ_ARCHIVE_ROOT` unset, the resolver prints exactly `"$target_root/relay-system"` ([relay-turn-lib.sh:73](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:73), [relay-turn-lib.sh:75](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:75)). The four writers append the same suffixes as before: consult uses `"$ROOT/relay-system/<date>/<label>-<time>"` ([consult.sh:91](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:91)), marathon uses `"$ROOT/relay-system/<date>/marathon-..."` ([marathon-drive.sh:442](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:442)), relay-drive uses `"$ROOT_DIR/relay-system/<date>"` for consult-verify ([relay-drive.sh:323](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:323)), and swarm-preflight uses `"$ROOT/relay-system/preflight/<date>/<slug>"` ([swarm-preflight.sh:610](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:610)). The roots themselves come from `pwd`-style resolution, and the resolver strips any trailing slash, so I do not see an unset-path slash regression ([consult.sh:52](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:52), [marathon-drive.sh:36](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:36), [relay-drive.sh:28](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:28), [swarm-preflight.sh:49](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:49)).

2. `[Pass] Override-wins.` The two writers that expose override surfaces gate the resolver behind an empty override check: consult only resolves when `OUT` is empty ([consult.sh:65](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:65), [consult.sh:91](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:91)), and swarm-preflight only resolves when `OUT_DIR` is empty ([swarm-preflight.sh:92](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:92), [swarm-preflight.sh:610](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:610)). Marathon and relay-drive do not offer a transcript-dir override flag in this phase, so there is no override contract for them to violate ([marathon-drive.sh:10](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:10), [relay-drive.sh:117](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:117)).

3. `[Blocker] Fail-loud is broken in relay-drive's consult-verify path.` Consult and swarm use the safe single-substitution form `x="$(rtl_transcript_root ...)" || exit 1` ([consult.sh:92](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:92), [swarm-preflight.sh:611](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:611)); marathon also preserves the resolver rc by separating `local` from the assignment, and the bare `save_transcript` call is under `set -e`, so a `return 1` aborts the script before any transcript write ([marathon-drive.sh:2](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:2), [marathon-drive.sh:442](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:442), [marathon-drive.sh:468](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:468)). Relay-drive is different: `_cv_out_dir="$(rtl_transcript_root "$ROOT_DIR")/$(date +%F)" || exit 1` puts a second command substitution in the same assignment, so a failing resolver is masked by the succeeding `date`, and then the consult invocation is explicitly swallowed with `|| true` ([relay-drive.sh:323](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:323), [relay-drive.sh:331](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:331)). That violates the stated hard-error/no-fallback contract.

4. `[Pass] Source-path robustness.` All four scripts source the lib by their own directory, not by `$ROOT`, which is the right choice for both the central checkout and a vendored `.xyz` layout: consult and marathon source a sibling file ([consult.sh:52](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:52), [consult.sh:57](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:57), [marathon-drive.sh:36](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:36), [marathon-drive.sh:48](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/marathon-drive.sh:48)), relay-drive does the same via `dirname "${BASH_SOURCE[0]}"` ([relay-drive.sh:31](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-drive.sh:31)), and swarm correctly walks from `utils/` to sibling `relay-automation/` ([swarm-preflight.sh:49](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:49), [swarm-preflight.sh:62](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:62)).

5. `[Pass] Side effects of sourcing look acceptable.` The lib is intentionally namespaced around `rtl_*` functions and `RTL_*` globals ([relay-turn-lib.sh:17](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:17)), and the sourcing sites only depend on `rtl_transcript_root` ([consult.sh:57](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/consult.sh:57), [swarm-preflight.sh:62](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/utils/swarm-preflight.sh:62)). I do not see top-level work in the file; it is a function library from the first function definition onward ([relay-turn-lib.sh:41](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:41), [relay-turn-lib.sh:601](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/relay-automation/relay-turn-lib.sh:601)). Under `set -e`, a missing or syntactically bad lib would abort consult/marathon/relay-drive immediately, but that is a packaging failure, not a new behavioral side effect.

6. `[Should] Test adequacy is not enough for this phase.` `test/archive-writers.sh` proves the behavior end-to-end only through `consult.sh`; the other writers get structural greps only ([archive-writers.sh:3](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/archive-writers.sh:3), [archive-writers.sh:67](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/archive-writers.sh:67)). That did not catch the real `relay-drive.sh:323` bug, and it would also miss future re-hardcodes done via an intermediate variable rather than the exact literal pattern it greps for ([archive-writers.sh:73](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/archive-writers.sh:73)). The swarm T8b/T8c/T8d block is useful, but it only checks dry-run preview strings and override text; it does not cover the invalid-archive fail-loud path ([swarm-preflight.sh test:182](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32873-24689/test/swarm-preflight.sh:182)).

**Recommendation**
Changes required.
