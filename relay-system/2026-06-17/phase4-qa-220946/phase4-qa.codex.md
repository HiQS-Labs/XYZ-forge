Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ed922-a5c8-7d90-918e-1e739a02ec58
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Phase 4 (M5) QA review — multi-phase Marathon orchestrator

You are an INDEPENDENT QA reviewer. REPORT-ONLY / advisory — do NOT modify files. Read the files
yourself in this worktree and be adversarial + concrete: cite file:line, give a SCENARIO, not a vague
worry. If a section is clean, say so plainly rather than inventing findings.

## What was built (Phase 4 / M5 — multi-phase chaining)
A `MARATHON.yaml` plan now runs end-to-end: parse → resolve `depends_on` order → run each phase via
`marathon-drive.sh` → HALT on the first phase failure → emit `marathon.complete` on full success.

Review these files:
- `src/marathon-yaml.js` + `bin/marathon-yaml`  — zero-dep MARATHON.yaml reader (parse / validate / topo order)
- `relay-automation/marathon.sh`                 — the orchestrator (chaining / halt / events)
- `relay-automation/marathon-drive.sh`           — single-phase driver, newly generalized with `--phase-id`
- `test/marathon-yaml.sh`, `test/marathon.sh`    — unit tests (they STUB marathon-drive)
- `relay-automation/MARATHON.example.yaml`        — example plan

## Focus areas (be concrete, cite file:line)
1. **Parser correctness** (`src/marathon-yaml.js`): YAML-subset edge cases — quoting, inline/whole-line
   comments, indentation, list-item parsing, value coercion; topological-sort determinism + cycle
   detection; validation gaps (what malformed plan slips through as "valid"?).
2. **Orchestrator correctness** (`relay-automation/marathon.sh`): the TSV read (tab-coalescing was already
   fixed by translating tabs → `\037` before `read` — is that fix correct AND complete?), round-cap math
   (`2*max_review_rounds+1`), halt semantics + exit-code propagation, brief/path resolution, `set -euo
   pipefail` pitfalls, the `marathon.complete` emission point.
3. **The 3 roadmap QA invariants** — assess each against the code:
   (a) **State cleanliness** — when phase p2 starts after p1, is the git working tree clean so p2's
       `rtl_before` snapshot doesn't capture p1 residue? (marathon-drive commits per phase.)
   (b) **Peer threading** — is `RELAY_PEER` set on every turn handoff, in every phase?
   (c) **Boundary events** — `marathon.phase.start` / `approved` / `escalated` + `marathon.complete`
       all emitted at the right points?
4. **Portability** — the suite must pass on Linux CI (ubuntu), not just macOS. Any BSD-vs-GNU or
   bash-3.2 hazards in the new code (`tr`, `read`, `printf`, process substitution `< <(...)`, `$'\037'`,
   `paste`, `cut`)?
5. **What the unit tests MISS** — they stub marathon-drive. What real-run failure could slip past them?

Respond with: (1) a one-line ANSWER (ship-ready? any blockers?); (2) graded FINDINGS —
[Blocker]/[Should]/[Nit]/[Pass] — each with file:line + scenario; (3) a one-line RECOMMENDATION.
codex
I’m reviewing the cited runtime and test files directly, starting with the parser and orchestrator paths so I can check the claimed invariants against the actual control flow and tests.
exec
/bin/zsh -lc "pwd && rg --files src bin relay-automation test | rg '"'^(src/marathon-yaml'"\\.js|bin/marathon-yaml|relay-automation/marathon\\.sh|relay-automation/marathon-drive\\.sh|relay-automation/MARATHON\\.example\\.yaml|test/marathon-yaml\\.sh|test/marathon\\.sh)"'$'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
bin/marathon-yaml
src/marathon-yaml.js
relay-automation/MARATHON.example.yaml
relay-automation/marathon-drive.sh
relay-automation/marathon.sh
test/marathon.sh
test/marathon-yaml.sh

exec
/bin/zsh -lc 'git status --short' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 3042ms:
2026-06-17 22:09:58.671 xcodebuild[83192:105271341]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-17 22:09:59.036 xcodebuild[83192:105271334] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-x1ubCzA5' (errno=Operation not permitted)
2026-06-17 22:09:59.744 xcodebuild[83198:105271405]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-06-17 22:09:59.938 xcodebuild[83198:105271404] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.

codex
I’ve confirmed the exact files in scope. Next I’m reading them with line numbers so I can anchor each finding to the actual branches and failure paths instead of inferring from the summary.
exec
/bin/zsh -lc 'nl -ba test/marathon.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc 'nl -ba relay-automation/MARATHON.example.yaml' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc 'nl -ba relay-automation/marathon-drive.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	# MARATHON.example.yaml — a multi-phase plan for marathon.sh (Phase 4 / M5).
     2	# Run it with:  relay-automation/marathon.sh --plan relay-automation/MARATHON.example.yaml
     3	# Each phase runs through marathon-drive.sh in depends_on order; the chain HALTS on the first
     4	# phase that fails its review/gate (that phase's ESCALATION.md is left behind), and emits a
     5	# marathon.complete event only when every phase is approved.
     6	#
     7	# Per-phase fields:
     8	#   id                 phase id → phases/<id>/RELAY.md + tick token MARATHON-<ID>-TURN   (required)
     9	#   reviewer           codex* or gemini* — the model that reviews this phase              (required)
    10	#   brief              path (repo-relative) to the phase's task markdown                  (required)
    11	#   artifact           comma-separated repo-relative file(s) the builder may create/edit  (optional)
    12	#   max_review_rounds  round-cap = 2*N+1 (default 2 → cap 5)                              (optional)
    13	#   depends_on         run this phase only after the named phase is approved              (optional)
    14	#   name               human label for logs                                              (optional)
    15	
    16	name: example-refactor
    17	phases:
    18	  - id: p1
    19	    name: Define the event schema
    20	    reviewer: codex
    21	    brief: phases-briefs/p1-schema.md
    22	    artifact: src/schema.js
    23	    max_review_rounds: 2
    24	
    25	  - id: p2
    26	    name: Single-writer lease on top of the schema
    27	    reviewer: gemini
    28	    brief: phases-briefs/p2-lease.md
    29	    artifact: src/lease.js
    30	    depends_on: p1
    31	    max_review_rounds: 3

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# marathon.sh test: the multi-phase orchestrator parses MARATHON.yaml, runs phases in depends_on
     3	# order via marathon-drive (STUBBED), HALTS on the first failure (later phases NOT started), and
     4	# emits marathon.complete only when every phase is approved. (Phase 4 / M5)
     5	source "$(dirname "$0")/_setup.sh" marathon
     6	REPO="$(cd "$(dirname "$0")/.." && pwd)"
     7	MSH="$REPO/relay-automation/marathon.sh"
     8	YBIN="$REPO/bin/marathon-yaml"
     9	
    10	mkdir -p "$A/briefs"
    11	for p in p1 p2 p3 a b; do printf 'brief for %s\n' "$p" > "$A/briefs/$p.md"; done
    12	
    13	# Stub marathon-drive: record "id|cap|reviewer|artifact" per phase; exit 4 if id == STUB_FAIL_PHASE.
    14	STUB="$WORK/drive.sh"
    15	cat > "$STUB" <<'STUB'
    16	#!/usr/bin/env bash
    17	set -u
    18	pid=""; cap=""; rev=""; art=""
    19	while (($#)); do case "$1" in
    20	  --phase-id) pid="$2"; shift 2;;
    21	  --round-cap) cap="$2"; shift 2;;
    22	  --reviewer) rev="$2"; shift 2;;
    23	  --artifact) art="$2"; shift 2;;
    24	  *) shift;;
    25	esac; done
    26	printf '%s|%s|%s|%s\n' "$pid" "$cap" "$rev" "$art" >> "$WORK/phases-ran"
    27	[ "$pid" = "${STUB_FAIL_PHASE:-__none__}" ] && exit 4
    28	exit 0
    29	STUB
    30	chmod +x "$STUB"
    31	
    32	run_marathon() {  # <plan> <extra-args…>
    33	  local plan="$1"; shift
    34	  MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
    35	    bash "$MSH" --plan "$plan" "$@"
    36	}
    37	
    38	cat > "$A/m.yaml" <<'YAML'
    39	name: chain
    40	phases:
    41	  - id: p1
    42	    reviewer: codex
    43	    max_review_rounds: 2
    44	    brief: briefs/p1.md
    45	  - id: p2
    46	    reviewer: gemini
    47	    depends_on: p1
    48	    max_review_rounds: 3
    49	    brief: briefs/p2.md
    50	    artifact: src/p2.js
    51	  - id: p3
    52	    reviewer: codex
    53	    depends_on: p2
    54	    brief: briefs/p3.md
    55	YAML
    56	
    57	# --- (1) full chain: order + round-cap math + marathon.complete ------------
    58	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
    59	run_marathon "$A/m.yaml" >/dev/null 2>&1; rc=$?
    60	[ "$rc" -eq 0 ] && pass "full chain exits 0" || fail "chain exit=$rc"
    61	[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1,p2,p3" ] \
    62	  && pass "phases run in execution order p1,p2,p3" || fail "order: [$(cat "$WORK/phases-ran")]"
    63	grep -q "^p2|7|gemini|src/p2.js$" "$WORK/phases-ran" \
    64	  && pass "p2: round-cap=7 (2*3+1), reviewer + artifact passed through" || fail "p2 args: [$(grep p2 "$WORK/phases-ran")]"
    65	grep -q "^p1|5|codex|$" "$WORK/phases-ran" \
    66	  && pass "p1: round-cap=5 (default max_review_rounds=2)" || fail "p1 cap: [$(grep p1 "$WORK/phases-ran")]"
    67	ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
    68	  && pass "marathon.complete emitted on full success" || fail "marathon.complete missing"
    69	
    70	# --- (2) halt on failure: p2 fails -> p3 NOT started, exit 4, no complete --
    71	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
    72	STUB_FAIL_PHASE=p2 run_marathon "$A/m.yaml" >/dev/null 2>&1; rc=$?
    73	[ "$rc" -eq 4 ] && pass "halt propagates the failing phase's exit (4)" || fail "halt exit=$rc (expected 4)"
    74	[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1,p2" ] \
    75	  && pass "chain halts after p2 — p3 NOT started" || fail "ran: [$(cat "$WORK/phases-ran")]"
    76	ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
    77	  && fail "marathon.complete must NOT be emitted on halt" || pass "no marathon.complete on halt"
    78	
    79	# --- (3) depends_on reorders authored-out-of-order phases -----------------
    80	cat > "$A/r.yaml" <<'YAML'
    81	name: reorder
    82	phases:
    83	  - id: b
    84	    reviewer: codex
    85	    depends_on: a
    86	    brief: briefs/b.md
    87	  - id: a
    88	    reviewer: gemini
    89	    brief: briefs/a.md
    90	YAML
    91	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
    92	run_marathon "$A/r.yaml" >/dev/null 2>&1
    93	[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "a,b" ] \
    94	  && pass "orchestrator runs in depends_on order (a before b)" || fail "ran: [$(cat "$WORK/phases-ran")]"
    95	
    96	# --- (4) a phase with no brief -> hard error (exit 2) ---------------------
    97	printf 'name: nb\nphases:\n  - id: p1\n    reviewer: codex\n' > "$A/nobrief.yaml"
    98	rm -f "$WORK/phases-ran"
    99	run_marathon "$A/nobrief.yaml" >/dev/null 2>&1; rc=$?
   100	[ "$rc" -eq 2 ] && pass "phase without a brief -> error (exit 2)" || fail "no-brief exit=$rc (expected 2)"
   101	
   102	# --- (5) malformed plan -> halt before running ANY phase -----------------
   103	printf 'name: bad\nphases:\n  - id: p1\n    reviewer: claude\n    brief: briefs/p1.md\n' > "$A/bad.yaml"
   104	rm -f "$WORK/phases-ran"
   105	run_marathon "$A/bad.yaml" >/dev/null 2>&1; rc=$?
   106	{ [ "$rc" -eq 2 ] && [ ! -f "$WORK/phases-ran" ]; } \
   107	  && pass "malformed plan halts before any phase runs (exit 2)" || fail "bad plan: rc=$rc, ran=[$(cat "$WORK/phases-ran" 2>/dev/null)]"
   108	
   109	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
   110	exit 0

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
    34	#        2 usage.
    35	
    36	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    37	ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    38	TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
    39	RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
    40	AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
    41	
    42	die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
    43	log()  { printf 'marathon-drive: %s\n' "$*"; }
    44	
    45	usage() {
    46	  cat <<'EOF'
    47	Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
    48	
    49	  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
    50	  --reviewer AGENT        Reviewer agent id; must start with 'codex' or 'gemini' (required).
    51	  --builder AGENT         Builder agent id (default: claude).
    52	  --round-cap N           relay-drive turn cap (default: 5).
    53	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
    54	  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
    55	  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
    56	  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
    57	  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
    58	                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
    59	  --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
    60	  --dry-run               Render the relay file and print the tick seed; exit without running.
    61	EOF
    62	}
    63	
    64	PHASE_BRIEF_FILE=""
    65	BUILDER="claude"
    66	REVIEWER=""
    67	ROUND_CAP=5
    68	PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
    69	PHASES_DIR=""        # resolved to default after ROOT is set
    70	PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
    71	RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
    72	ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
    73	REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
    74	DRY_RUN=0
    75	
    76	while (($# > 0)); do
    77	  case "$1" in
    78	    --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
    79	    --builder)         BUILDER="${2:-}"; shift 2 ;;
    80	    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
    81	    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
    82	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    83	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    84	    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
    85	    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
    86	    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
    87	    --require-clean)   REQUIRE_CLEAN=1; shift ;;
    88	    --dry-run)         DRY_RUN=1; shift ;;
    89	    --help)            usage; exit 0 ;;
    90	    *)                 die "unknown argument: $1" ;;
    91	  esac
    92	done
    93	
    94	[[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
    95	[[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
    96	[[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
    97	[[ -n "$BUILDER"          ]] || die "--builder cannot be empty"
    98	[[ -n "$PHASE_ID"         ]] || die "--phase-id cannot be empty"
    99	
   100	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
   101	PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"
   102	# Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
   103	RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
   104	
   105	# Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing.
   106	# Builder is always Claude in Phase 3; reviewer is Codex or Gemini (detected by name prefix).
   107	export CLAUDE_AGENT="$BUILDER"
   108	export MARATHON_BUILDER="$BUILDER"
   109	export MARATHON_REVIEWER="$REVIEWER"
   110	case "$REVIEWER" in
   111	  codex*)  export CODEX_AGENT="$REVIEWER"; export GEMINI_AGENT="" ;;
   112	  gemini*) export GEMINI_AGENT="$REVIEWER"; export CODEX_AGENT="" ;;
   113	  *)       die "reviewer '$REVIEWER' not recognized — must start with 'codex' or 'gemini'" ;;
   114	esac
   115	
   116	# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
   117	# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
   118	# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
   119	# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
   120	if [[ -n "$ARTIFACT_PATHS" ]]; then
   121	  export ALLOW_PATHS="$ARTIFACT_PATHS"
   122	fi
   123	
   124	PHASE_DIR="$PHASES_DIR/$PHASE_ID"
   125	RELAY_FILE="$PHASE_DIR/RELAY.md"
   126	REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
   127	
   128	# ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
   129	# Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
   130	# off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
   131	# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
   132	# unattended runs (DRY_RUN skips it — nothing is committed).
   133	if ((! DRY_RUN)); then
   134	  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
   135	    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
   136	  if [[ -n "$dirty" ]]; then
   137	    log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
   138	    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
   139	    ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
   140	  fi
   141	fi
   142	
   143	# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────
   144	
   145	mkdir -p "$PHASE_DIR"
   146	BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"
   147	
   148	# Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
   149	# repo root, so a relative "./bin/tick" is a guess — a real builder turn (2026-06-17) looked for it
   150	# in the phase dir, logged "tick not present", and skipped the token handoff entirely (phase then
   151	# escalated no-progress). An absolute path the agent can run from anywhere removes that failure mode.
   152	TICK_CLI="$TICK_BIN"
   153	case "$TICK_CLI" in /*) ;; *) TICK_CLI="$ROOT/$TICK_CLI" ;; esac
   154	
   155	# Builder/reviewer instruction text + the tick claim --paths depend on whether this phase targets
   156	# real artifact file(s) (--artifact) or is relay-only. Built here so the heredoc stays a flat template.
   157	if [[ -n "$ARTIFACT_PATHS" ]]; then
   158	  CLAIM_PATHS="${REL_RELAY},${ARTIFACT_PATHS}"
   159	  BUILDER_IMPL_LINE="Implement the brief by creating/editing the artifact file(s): ${ARTIFACT_PATHS}"
   160	  BUILDER_SCOPE_LINE="Edit ONLY these paths: ${REL_RELAY} and ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   161	  REVIEWER_READ_LINE="Read the latest builder block above AND review the artifact file(s) on disk: ${ARTIFACT_PATHS}."
   162	  REVIEWER_SCOPE_LINE="Edit ONLY ${REL_RELAY} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
   163	else
   164	  CLAIM_PATHS="${REL_RELAY}"
   165	  BUILDER_IMPL_LINE="Record your work directly in this relay file (relay-only phase — no source file to edit)."
   166	  BUILDER_SCOPE_LINE="Edit ONLY ${REL_RELAY}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
   167	  REVIEWER_READ_LINE="Read the latest builder block above."
   168	  REVIEWER_SCOPE_LINE="Do NOT run git. Do NOT touch any other file."
   169	fi
   170	
   171	cat > "$RELAY_FILE" << RELAY_EOF
   172	# Marathon Phase ${PHASE_ID}
   173	STATUS: Open
   174	NEXT: ${BUILDER}
   175	
   176	<!-- marathon-drive: task=${RELAY_TASK} builder=${BUILDER} reviewer=${REVIEWER} round-cap=${ROUND_CAP} -->
   177	
   178	## Phase Brief
   179	
   180	${BRIEF_TEXT}
   181	
   182	---
   183	
   184	▶ TAKE YOUR TURN (${BUILDER} — BUILDER role)
   185	
   186	You are the BUILDER for this phase. Read the phase brief above and implement it.
   187	1. ${BUILDER_IMPL_LINE}
   188	2. Append a build block to this relay file: \`### Round N · Builder · ${BUILDER}\` summarizing what you did (files touched, key decisions).
   189	3. Use this exact tick binary (run it from any directory): ${TICK_CLI}
   190	   - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
   191	   - ${TICK_CLI} ping ${RELAY_TASK} --agent ${BUILDER}
   192	   - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
   193	4. ${BUILDER_SCOPE_LINE}
   194	
   195	---
   196	
   197	▶ TAKE YOUR TURN (${REVIEWER} — REVIEWER role)
   198	
   199	You are the REVIEWER for this phase. ${REVIEWER_READ_LINE}
   200	1. Append a review block: \`### Round N · Reviewer · ${REVIEWER}\` followed by your assessment.
   201	2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
   202	3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
   203	4. Use this exact tick binary (run it from any directory) for all token operations: ${TICK_CLI}
   204	   ${REVIEWER_SCOPE_LINE}
   205	RELAY_EOF
   206	
   207	if ((DRY_RUN)); then
   208	  log "dry-run: relay file rendered at $RELAY_FILE"
   209	  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
   210	  exit 0
   211	fi
   212	
   213	# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────
   214	
   215	git -C "$ROOT" add -- "$RELAY_FILE"
   216	git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
   217	log "relay file committed: $RELAY_FILE"
   218	
   219	# ── Step 3: seed tick token with handoff → builder ──────────────────────────
   220	
   221	export TICK_REPO_ROOT="$ROOT"
   222	"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
   223	"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
   224	"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
   225	log "tick token seeded: $RELAY_TASK → $BUILDER"
   226	
   227	# ── Step 4: emit phase.start ────────────────────────────────────────────────
   228	
   229	"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
   230	log "phase start: running relay-drive --round-cap $ROUND_CAP"
   231	
   232	# ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────
   233	
   234	# relay-drive runs the turn-taker via `eval "$AGENT_CMD"`, so the value must be a shell-quoted
   235	# command string — an un-quoted path with a space (".../GH Repos/...") would split on the space
   236	# and try to exec the wrong token. printf %q makes the path eval-safe (relay-drive stays unmodified).
   237	AGENT_CMD_Q="$(printf '%q' "$AGENT_CMD")"
   238	relay_exit=0
   239	RELAY_FILE="$RELAY_FILE" \
   240	  "$RELAY_DRIVE_BIN" \
   241	    --relay-file "$RELAY_FILE" \
   242	    --relay-task "$RELAY_TASK" \
   243	    --agent-cmd  "$AGENT_CMD_Q" \
   244	    --round-cap  "$ROUND_CAP" \
   245	  || relay_exit=$?
   246	
   247	# ── Step 6: act on relay-drive exit code ───────────────────────────────────
   248	
   249	escalate() {  # <reason> <relay-exit>
   250	  local reason="$1" rexit="$2"
   251	  cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
   252	# ESCALATION — Marathon Phase ${PHASE_ID}
   253	
   254	phase: ${PHASE_ID}
   255	task: ${RELAY_TASK}
   256	relay-drive-exit: ${rexit}
   257	reason: ${reason}
   258	relay-file: ${REL_RELAY}
   259	ESC_EOF
   260	  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
   261	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
   262	  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
   263	  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
   264	}
   265	
   266	save_transcript() {
   267	  local date_dir; date_dir="$ROOT/relay-system/$(date +%Y-%m-%d)"
   268	  mkdir -p "$date_dir"
   269	  local ts; ts="$(date +%H%M%S)"
   270	  local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
   271	  cp "$RELAY_FILE" "$dest"
   272	  git -C "$ROOT" add -- "$dest"
   273	  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
   274	  log "transcript saved: $dest"
   275	}
   276	
   277	case "$relay_exit" in
   278	  0)
   279	    # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
   280	    log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
   281	    gate_exit=0
   282	    eval "$PRE_ADVANCE_CMD" || gate_exit=$?
   283	    if [[ "$gate_exit" -ne 0 ]]; then
   284	      log "pre-advance gate FAILED (exit $gate_exit) — escalating"
   285	      escalate "pre-advance-failed" "$relay_exit"
   286	      exit 5
   287	    fi
   288	    "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
   289	    save_transcript
   290	    log "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
   291	    exit 0
   292	    ;;
   293	  3)
   294	    log "relay escalated: no-progress (relay-drive exit 3)"
   295	    escalate "no-progress" 3
   296	    exit 3
   297	    ;;
   298	  4)
   299	    log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
   300	    escalate "cap-or-close-mismatch" 4
   301	    exit 4
   302	    ;;
   303	  6)
   304	    # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
   305	    # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
   306	    # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
   307	    # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
   308	    log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
   309	    escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
   310	    exit 6
   311	    ;;
   312	  *)
   313	    die "relay-drive exited with unexpected code $relay_exit"
   314	    ;;
   315	esac

exec
/bin/zsh -lc 'nl -ba relay-automation/marathon.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
     5	# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
     6	# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
     7	# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
     8	# Emits marathon.complete only when every phase is approved.
     9	#
    10	# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
    11	# Cross-phase context injection (M6) and MARATHON-STATE.md projection (M7) are deliberately deferred —
    12	# the boundary events already land in .tick/events/ (phase.start/approved/escalated, marathon.complete).
    13	#
    14	# Usage:
    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder claude] [--phases-dir DIR]
    16	#                                [--pre-advance-cmd CMD] [--dry-run]
    17	#
    18	# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
    19	# brief→--phase-brief (required to run), artifact→--artifact, max_review_rounds→--round-cap.
    20	#
    21	# Environment overrides (for tests):
    22	#   MARATHON_ROOT       — repo root (default: parent of this script's dir)
    23	#   MARATHON_DRIVE      — marathon-drive.sh path (default: this script's dir/marathon-drive.sh)
    24	#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <repo-root>/bin/marathon-yaml)
    25	#   TICK_BIN            — tick binary (default: <repo-root>/bin/tick)
    26	# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
    27	#
    28	# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
    29	
    30	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    31	ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    32	TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
    33	DRIVE_BIN="${MARATHON_DRIVE:-"$HERE/marathon-drive.sh"}"
    34	YAML_BIN="${MARATHON_YAML_BIN:-"$ROOT/bin/marathon-yaml"}"
    35	
    36	die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
    37	log() { printf 'marathon: %s\n' "$*"; }
    38	
    39	PLAN=""; BUILDER="claude"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0
    40	while (($# > 0)); do
    41	  case "$1" in
    42	    --plan)            PLAN="${2:-}"; shift 2 ;;
    43	    --builder)         BUILDER="${2:-}"; shift 2 ;;
    44	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    45	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    46	    --dry-run)         DRY_RUN=1; shift ;;
    47	    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
    48	    *)                 die "unknown argument: $1" ;;
    49	  esac
    50	done
    51	[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
    52	[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
    53	PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
    54	export TICK_REPO_ROOT="$ROOT"
    55	
    56	# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
    57	PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
    58	[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
    59	phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
    60	log "plan: $PLAN — $phase_count phase(s) in execution order"
    61	
    62	idx=0
    63	# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
    64	# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
    65	# tabs → \037 so empty fields (no rounds / no depends_on / no artifact) are preserved positionally.
    66	while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact name; do
    67	  [[ -n "$id" ]] || continue
    68	  idx=$((idx + 1))
    69	  rounds="${rounds:-2}"
    70	  cap=$((2 * rounds + 1))
    71	  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
    72	  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$ROOT/$brief" ;; esac
    73	  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"
    74	
    75	  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}) ──"
    76	
    77	  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
    78	               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
    79	  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
    80	  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
    81	  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
    82	
    83	  phase_exit=0
    84	  MARATHON_ROOT="$ROOT" TICK_BIN="$TICK_BIN" bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
    85	  if [[ "$phase_exit" -ne 0 ]]; then
    86	    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
    87	    exit "$phase_exit"
    88	  fi
    89	done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')
    90	
    91	if ((DRY_RUN)); then
    92	  log "dry-run complete: $phase_count phase(s) would run in order"
    93	  exit 0
    94	fi
    95	"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true
    96	log "marathon complete — all $phase_count phase(s) approved"
    97	exit 0

exec
/bin/zsh -lc 'nl -ba bin/marathon-yaml' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc 'nl -ba test/marathon-yaml.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env node
     2	'use strict';
     3	
     4	// marathon-yaml — read + validate MARATHON.yaml, emit phases in execution order (Phase 4 / M5).
     5	// Zero-dep (Node stdlib). Bash orchestrators consume the TSV; --format json for tooling.
     6	//
     7	// Usage:  bin/marathon-yaml <MARATHON.yaml> [--format tsv|json]
     8	// TSV columns (tab-separated), one phase per line, in resolved depends_on order:
     9	//   id  reviewer  max_review_rounds  depends_on  brief  artifact  name
    10	// Exit: 0 ok · 1 parse/validation error · 2 usage.
    11	
    12	const fs = require('fs');
    13	const { parseMarathonYaml, resolveOrder } = require('../src/marathon-yaml');
    14	
    15	function die(msg, code) { process.stderr.write(`marathon-yaml: ${msg}\n`); process.exit(code == null ? 1 : code); }
    16	
    17	const args = process.argv.slice(2);
    18	let file = '';
    19	let format = 'tsv';
    20	for (let i = 0; i < args.length; i++) {
    21	  if (args[i] === '--format') { format = args[++i]; }
    22	  else if (args[i] === '--help' || args[i] === '-h') {
    23	    process.stdout.write('Usage: bin/marathon-yaml <MARATHON.yaml> [--format tsv|json]\n'); process.exit(0);
    24	  } else if (!file) { file = args[i]; }
    25	  else die(`unexpected argument: ${args[i]}`, 2);
    26	}
    27	if (!file) die('a MARATHON.yaml path is required', 2);
    28	if (format !== 'tsv' && format !== 'json') die(`unknown --format: ${format}`, 2);
    29	
    30	let text;
    31	try { text = fs.readFileSync(file, 'utf8'); } catch (e) { die(`cannot read ${file}: ${e.message}`); }
    32	
    33	let order;
    34	let plan;
    35	try {
    36	  plan = parseMarathonYaml(text);
    37	  order = resolveOrder(plan);
    38	} catch (e) {
    39	  die(e.message);
    40	}
    41	
    42	if (format === 'json') {
    43	  process.stdout.write(JSON.stringify({ name: plan.name, phases: order }, null, 2) + '\n');
    44	} else {
    45	  for (const p of order) {
    46	    process.stdout.write([
    47	      p.id, p.reviewer, p.max_review_rounds || '', p.depends_on || '', p.brief || '', p.artifact || '', p.name || '',
    48	    ].join('\t') + '\n');
    49	  }
    50	}

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# marathon-yaml test: the zero-dep MARATHON.yaml reader parses the constrained subset, resolves
     3	# depends_on into execution order, and fails loudly on malformed/cyclic/incomplete plans (Phase 4 / M5).
     4	source "$(dirname "$0")/_setup.sh" marathon-yaml
     5	MARA="$(cd "$(dirname "$0")/.." && pwd)/bin/marathon-yaml"
     6	run() { node "$MARA" "$@" 2>"$WORK/err"; }   # stdout to caller; stderr captured for assertions
     7	
     8	# --- (1) linear 3-phase chain: execution order + field extraction ----------
     9	cat > "$WORK/m1.yaml" <<'YAML'
    10	name: trinity-sync-refactor
    11	phases:
    12	  - id: p1
    13	    name: Event schema
    14	    reviewer: codex
    15	    max_review_rounds: 2
    16	    brief: briefs/p1.md
    17	    artifact: src/schema.js
    18	  - id: p2
    19	    name: single-writer lease
    20	    reviewer: gemini               # gemini for architecture
    21	    depends_on: p1
    22	    max_review_rounds: 3
    23	  - id: p3
    24	    name: claim-cap wiring
    25	    reviewer: codex
    26	    depends_on: p2
    27	    max_review_rounds: 2
    28	YAML
    29	out="$(run "$WORK/m1.yaml")"; rc=$?
    30	[ "$rc" -eq 0 ] && pass "linear chain parses (exit 0)" || fail "parse failed: $(cat "$WORK/err")"
    31	[ "$(printf '%s\n' "$out" | cut -f1 | paste -sd, -)" = "p1,p2,p3" ] \
    32	  && pass "execution order resolves to p1,p2,p3" || fail "order wrong: [$out]"
    33	p2row="$(printf '%s\n' "$out" | awk -F'\t' '$1=="p2"{print $2"|"$3"|"$4}')"
    34	[ "$p2row" = "gemini|3|p1" ] \
    35	  && pass "p2 fields parsed (reviewer|rounds|depends_on, inline comment stripped)" || fail "p2 fields wrong: [$p2row]"
    36	p1ba="$(printf '%s\n' "$out" | awk -F'\t' '$1=="p1"{print $5"|"$6}')"
    37	[ "$p1ba" = "briefs/p1.md|src/schema.js" ] \
    38	  && pass "p1 brief + artifact columns parsed" || fail "p1 brief/artifact wrong: [$p1ba]"
    39	
    40	# --- (2) depends_on reorders authored-out-of-order phases ------------------
    41	cat > "$WORK/m2.yaml" <<'YAML'
    42	name: reorder
    43	phases:
    44	  - id: b
    45	    reviewer: codex
    46	    depends_on: a
    47	  - id: a
    48	    reviewer: gemini
    49	YAML
    50	out="$(run "$WORK/m2.yaml")"
    51	[ "$(printf '%s\n' "$out" | cut -f1 | paste -sd, -)" = "a,b" ] \
    52	  && pass "depends_on reorders out-of-order phases (a before b)" || fail "reorder wrong: [$out]"
    53	
    54	# --- (3) missing reviewer -> loud error -----------------------------------
    55	printf 'name: x\nphases:\n  - id: p1\n' > "$WORK/m3.yaml"
    56	run "$WORK/m3.yaml" >/dev/null; rc=$?
    57	{ [ "$rc" -ne 0 ] && grep -q "missing reviewer" "$WORK/err"; } \
    58	  && pass "missing reviewer -> error" || fail "should error on missing reviewer (rc=$rc)"
    59	
    60	# --- (4) unknown depends_on -> error --------------------------------------
    61	printf 'name: x\nphases:\n  - id: p1\n    reviewer: codex\n    depends_on: nope\n' > "$WORK/m4.yaml"
    62	run "$WORK/m4.yaml" >/dev/null; rc=$?
    63	{ [ "$rc" -ne 0 ] && grep -q "unknown phase" "$WORK/err"; } \
    64	  && pass "unknown depends_on -> error" || fail "should error on unknown dep (rc=$rc)"
    65	
    66	# --- (5) dependency cycle -> error ----------------------------------------
    67	printf 'name: x\nphases:\n  - id: p1\n    reviewer: codex\n    depends_on: p2\n  - id: p2\n    reviewer: codex\n    depends_on: p1\n' > "$WORK/m5.yaml"
    68	run "$WORK/m5.yaml" >/dev/null; rc=$?
    69	{ [ "$rc" -ne 0 ] && grep -q "cycle" "$WORK/err"; } \
    70	  && pass "dependency cycle -> error" || fail "should detect cycle (rc=$rc)"
    71	
    72	# --- (6) duplicate id -> error --------------------------------------------
    73	printf 'name: x\nphases:\n  - id: p1\n    reviewer: codex\n  - id: p1\n    reviewer: gemini\n' > "$WORK/m6.yaml"
    74	run "$WORK/m6.yaml" >/dev/null; rc=$?
    75	{ [ "$rc" -ne 0 ] && grep -q "duplicate" "$WORK/err"; } \
    76	  && pass "duplicate phase id -> error" || fail "should error on duplicate id (rc=$rc)"
    77	
    78	# --- (7) non-codex/gemini reviewer -> error -------------------------------
    79	printf 'name: x\nphases:\n  - id: p1\n    reviewer: claude\n' > "$WORK/m7.yaml"
    80	run "$WORK/m7.yaml" >/dev/null; rc=$?
    81	{ [ "$rc" -ne 0 ] && grep -q "must start with codex or gemini" "$WORK/err"; } \
    82	  && pass "reviewer must be codex*/gemini* -> error" || fail "should reject 'claude' reviewer (rc=$rc)"
    83	
    84	# --- (8) json format emits the marathon name ------------------------------
    85	run "$WORK/m1.yaml" --format json | grep -q '"name": "trinity-sync-refactor"' \
    86	  && pass "--format json emits the marathon name" || fail "json format broken"
    87	
    88	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    89	exit 0

exec
/bin/zsh -lc 'nl -ba src/marathon-yaml.js' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	'use strict';
     2	
     3	// marathon-yaml.js — zero-dep reader for the CONSTRAINED MARATHON.yaml subset (Phase 4 / M5).
     4	// Not a general YAML parser: it understands exactly the structure the spec defines —
     5	//   name: <marathon name>
     6	//   phases:
     7	//     - id: p1
     8	//       name: <phase name>
     9	//       reviewer: codex | gemini (or codex*/gemini*)
    10	//       max_review_rounds: <int>
    11	//       depends_on: <phase id>        (optional)
    12	// Disambiguation is by indent: a top-level `name:` (indent 0) is the marathon name; an indented
    13	// `name:` is a phase field. Anything outside this shape is a parse error, on purpose — better a loud
    14	// failure than a silently-misread orchestration plan.
    15	
    16	// brief = path to the phase's task markdown; artifact = comma-separated repo-relative file(s) the
    17	// builder may create/edit. Both optional in the schema but the orchestrator needs `brief` to run a phase.
    18	const PHASE_FIELDS = new Set(['id', 'name', 'reviewer', 'max_review_rounds', 'depends_on', 'brief', 'artifact']);
    19	
    20	function stripQuotes(v) {
    21	  if (v.length >= 2 && ((v[0] === '"' && v.endsWith('"')) || (v[0] === "'" && v.endsWith("'")))) {
    22	    return v.slice(1, -1);
    23	  }
    24	  return v;
    25	}
    26	
    27	// Split "key: value" into [key, value]; returns null if not a key:value line.
    28	function splitKV(s) {
    29	  const i = s.indexOf(':');
    30	  if (i < 0) return null;
    31	  const key = s.slice(0, i).trim();
    32	  let val = s.slice(i + 1).trim();
    33	  // drop trailing inline comment (only when clearly separated — ` #...`)
    34	  const c = val.indexOf(' #');
    35	  if (c >= 0) val = val.slice(0, c).trim();
    36	  return [key, stripQuotes(val)];
    37	}
    38	
    39	function indentOf(line) {
    40	  let n = 0;
    41	  while (n < line.length && line[n] === ' ') n++;
    42	  return n;
    43	}
    44	
    45	function parseMarathonYaml(text) {
    46	  const out = { name: '', phases: [] };
    47	  let inPhases = false;
    48	  let cur = null; // current phase being filled
    49	  const lines = String(text).split(/\r?\n/);
    50	  for (let ln = 0; ln < lines.length; ln++) {
    51	    const raw = lines[ln];
    52	    const noComment = raw.replace(/^(\s*)#.*$/, '$1'); // whole-line comment → blank (keep indent token)
    53	    if (noComment.trim() === '') continue;
    54	    const indent = indentOf(raw);
    55	    const trimmed = raw.trim();
    56	
    57	    if (indent === 0) {
    58	      if (trimmed === 'phases:') { inPhases = true; cur = null; continue; }
    59	      const kv = splitKV(trimmed);
    60	      if (kv && kv[0] === 'name') { out.name = kv[1]; inPhases = false; continue; }
    61	      throw new Error(`line ${ln + 1}: unexpected top-level line: ${trimmed}`);
    62	    }
    63	
    64	    if (!inPhases) throw new Error(`line ${ln + 1}: indented line outside phases: ${trimmed}`);
    65	
    66	    if (trimmed.startsWith('- ')) {
    67	      cur = { id: '', name: '', reviewer: '', max_review_rounds: '', depends_on: '', brief: '', artifact: '' };
    68	      out.phases.push(cur);
    69	      const rest = trimmed.slice(2).trim(); // inline first field, e.g. "id: p1"
    70	      if (rest) {
    71	        const kv = splitKV(rest);
    72	        if (!kv) throw new Error(`line ${ln + 1}: malformed list item: ${trimmed}`);
    73	        if (!PHASE_FIELDS.has(kv[0])) throw new Error(`line ${ln + 1}: unknown phase field '${kv[0]}'`);
    74	        cur[kv[0]] = kv[1];
    75	      }
    76	      continue;
    77	    }
    78	
    79	    // an indented field line belonging to the current phase
    80	    if (!cur) throw new Error(`line ${ln + 1}: phase field before any '- id:' item: ${trimmed}`);
    81	    const kv = splitKV(trimmed);
    82	    if (!kv) throw new Error(`line ${ln + 1}: malformed phase field: ${trimmed}`);
    83	    if (!PHASE_FIELDS.has(kv[0])) throw new Error(`line ${ln + 1}: unknown phase field '${kv[0]}'`);
    84	    cur[kv[0]] = kv[1];
    85	  }
    86	  return out;
    87	}
    88	
    89	// Validate + resolve depends_on into a deterministic execution order (topological).
    90	// Throws on: empty plan, duplicate id, missing required field, bad reviewer, unknown/self/cyclic dep.
    91	function resolveOrder(plan) {
    92	  const phases = plan.phases || [];
    93	  if (phases.length === 0) throw new Error('no phases defined');
    94	  const byId = new Map();
    95	  for (const p of phases) {
    96	    if (!p.id) throw new Error('a phase is missing its id');
    97	    if (byId.has(p.id)) throw new Error(`duplicate phase id: ${p.id}`);
    98	    if (!p.reviewer) throw new Error(`phase ${p.id}: missing reviewer`);
    99	    if (!/^(codex|gemini)/.test(p.reviewer)) {
   100	      throw new Error(`phase ${p.id}: reviewer '${p.reviewer}' must start with codex or gemini`);
   101	    }
   102	    if (p.depends_on === p.id) throw new Error(`phase ${p.id}: depends_on itself`);
   103	    byId.set(p.id, p);
   104	  }
   105	  for (const p of phases) {
   106	    if (p.depends_on && !byId.has(p.depends_on)) {
   107	      throw new Error(`phase ${p.id}: depends_on unknown phase '${p.depends_on}'`);
   108	    }
   109	  }
   110	  // Topological sort (single-parent depends_on chain, but handle a general DAG deterministically:
   111	  // preserve authoring order among ready nodes).
   112	  const order = [];
   113	  const done = new Set();
   114	  const remaining = phases.slice();
   115	  let guard = 0;
   116	  while (remaining.length) {
   117	    if (guard++ > phases.length + 1) throw new Error('dependency cycle detected');
   118	    let progressed = false;
   119	    for (let i = 0; i < remaining.length; i++) {
   120	      const p = remaining[i];
   121	      if (!p.depends_on || done.has(p.depends_on)) {
   122	        order.push(p);
   123	        done.add(p.id);
   124	        remaining.splice(i, 1);
   125	        progressed = true;
   126	        break; // restart scan to keep authoring order deterministic
   127	      }
   128	    }
   129	    if (!progressed) throw new Error('dependency cycle detected');
   130	  }
   131	  return order;
   132	}
   133	
   134	module.exports = { parseMarathonYaml, resolveOrder };

codex
I have the new files. I’m now checking the adjacent relay runtime because one of the requested invariants, `RELAY_PEER` on every handoff, cannot be answered from the orchestrator alone.
exec
/bin/zsh -lc 'nl -ba relay-automation/relay-drive.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc 'nl -ba relay-automation/marathon-agent.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# marathon-agent.sh — dispatcher for Marathon multi-phase loops. Routes a relay turn to the
     5	# correct model shim based on RELAY_AGENT; lets relay-drive.sh use a single --agent-cmd for
     6	# runs that mix Claude, Codex, and Gemini turns.
     7	#
     8	# Invoked by relay-drive.sh as --agent-cmd, with env:
     9	#   RELAY_FILE  — relay thread file
    10	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    11	#   RELAY_AGENT — current actor (determines which shim to exec)
    12	# Routing config (all optional; leave unset to skip that model):
    13	#   CLAUDE_AGENT      — agent id that routes to claude-turn.sh
    14	#   CODEX_AGENT       — agent id that routes to codex-turn.sh
    15	#   GEMINI_AGENT      — agent id that routes to gemini-turn.sh
    16	# Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
    17	#   MARATHON_BUILDER  — builder agent id; when RELAY_AGENT matches this, RELAY_PEER = MARATHON_REVIEWER
    18	#   MARATHON_REVIEWER — reviewer agent id; when RELAY_AGENT is the reviewer, RELAY_PEER = MARATHON_BUILDER
    19	# All other env (ALLOW_PATHS, *_LOG, *_FLAGS, etc.) pass through to the shim.
    20	#
    21	# Exit: 0 no-op (deferred) · 2 usage / unknown agent · inherits shim exit codes.
    22	
    23	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    24	die() { printf 'marathon-agent: %s\n' "$*" >&2; exit 2; }
    25	
    26	me="${RELAY_AGENT:-}"
    27	[[ -n "$me"              ]] || die "RELAY_AGENT required"
    28	[[ -n "${RELAY_FILE:-}"  ]] || die "RELAY_FILE required"
    29	
    30	claude_agent="${CLAUDE_AGENT:-}"
    31	codex_agent="${CODEX_AGENT:-}"
    32	gemini_agent="${GEMINI_AGENT:-}"
    33	
    34	# RELAY_PEER threading: builder's peer is the reviewer; reviewer's peer is the builder.
    35	# A live turn that lacks an explicit peer can release to a literal role-string (Gemini 2026-06-15).
    36	if [[ -n "${MARATHON_BUILDER:-}" && -n "${MARATHON_REVIEWER:-}" ]]; then
    37	  if [[ "$me" == "$MARATHON_BUILDER" ]]; then
    38	    export RELAY_PEER="$MARATHON_REVIEWER"
    39	  else
    40	    export RELAY_PEER="$MARATHON_BUILDER"
    41	  fi
    42	fi
    43	
    44	case "$me" in
    45	  "$claude_agent")
    46	    [[ -n "$claude_agent" ]] || die "RELAY_AGENT='$me' matched an empty CLAUDE_AGENT — set CLAUDE_AGENT"
    47	    exec "$HERE/claude-turn.sh"
    48	    ;;
    49	  "$codex_agent")
    50	    [[ -n "$codex_agent" ]] || die "RELAY_AGENT='$me' matched an empty CODEX_AGENT — set CODEX_AGENT"
    51	    exec "$HERE/codex-turn.sh"
    52	    ;;
    53	  "$gemini_agent")
    54	    [[ -n "$gemini_agent" ]] || die "RELAY_AGENT='$me' matched an empty GEMINI_AGENT — set GEMINI_AGENT"
    55	    exec "$HERE/gemini-turn.sh"
    56	    ;;
    57	  *)
    58	    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/GEMINI_AGENT to map it to a shim"
    59	    ;;
    60	esac

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
    23	# Exit: 0 = relay closed Approved/Closed · 3 = no-progress · 4 = cap / closed-not-approved · 2 = usage.
    24	
    25	ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    26	TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
    27	
    28	usage() {
    29	  cat <<'EOF'
    30	Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]
    31	
    32	  --relay-file PATH   The relay thread (reads STATUS: as the terminal signal).
    33	  --agent-cmd CMD     Turn-taker; invoked with env RELAY_FILE + RELAY_TASK + RELAY_AGENT.
    34	                      Must take the turn on the RELAY-TURN task (claim/ping/append/
    35	                      release --to <other> | done) and commit.
    36	  --relay-task ID     The relay turn-token task (default: RELAY-TURN).
    37	  --round-cap N       Max turns before escalating (default: 6).
    38	  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
    39	  --help
    40	EOF
    41	}
    42	
    43	die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }
    44	
    45	RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0
    46	while (($# > 0)); do
    47	  case "$1" in
    48	    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    49	    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
    50	    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
    51	    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    52	    --dry-run) DRY_RUN=1; shift ;;
    53	    --help) usage; exit 0 ;;
    54	    *) die "unknown argument: $1" ;;
    55	  esac
    56	done
    57	[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
    58	[[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
    59	[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }
    60	
    61	file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
    62	terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
    63	
    64	# Current actor of the RELAY-TURN token: claimer (if claimed) else handoff_to (if
    65	# open) else "" (done/missing). Echoes "<status>\t<actor>".
    66	token_state() {
    67	  local info status claimer handoff actor
    68	  info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null || true)"
    69	  status="$(printf '%s\n' "$info"  | sed -n 's/^status:[[:space:]]*//p'     | head -1)"
    70	  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
    71	  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
    72	  case "$status" in
    73	    claimed) actor="$claimer" ;;
    74	    open)    actor="$handoff" ;;
    75	    *)       actor="" ;;
    76	  esac
    77	  printf '%s\t%s\n' "$status" "$actor"
    78	}
    79	
    80	round=0
    81	while ((round < ROUND_CAP)); do
    82	  s="$(file_status)"
    83	  IFS=$'\t' read -r tstatus actor < <(token_state)
    84	
    85	  # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
    86	  # token no longer live (done/gone). file-terminal-but-token-live is a leaked
    87	  # close — escalate, never report success. (Codex r1 Blocker.)
    88	  if terminal_status "$s"; then
    89	    if [[ -n "$actor" ]]; then
    90	      printf 'relay-drive: STATUS %s but RELAY-TURN still live (%s/%s) — close mismatch, escalating\n' "$s" "$tstatus" "$actor" >&2
    91	      exit 4
    92	    fi
    93	    printf 'relay-drive: relay terminated (STATUS: %s, token done) after %d turn(s)\n' "$s" "$round"
    94	    exit 0
    95	  fi
    96	
    97	  # file not terminal but the token is gone/done → also a mismatch.
    98	  if [[ -z "$actor" ]]; then
    99	    printf 'relay-drive: RELAY-TURN has no actor (token %s) but STATUS=%s — escalating\n' "${tstatus:-missing}" "$s" >&2
   100	    exit 4
   101	  fi
   102	
   103	  if ((DRY_RUN)); then
   104	    printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
   105	  fi
   106	
   107	  prev="$tstatus:$actor"
   108	  RELAY_FILE="$RELAY_FILE" RELAY_TASK="$RELAY_TASK" RELAY_AGENT="$actor"
   109	  export RELAY_FILE RELAY_TASK RELAY_AGENT
   110	  eval "$AGENT_CMD"
   111	  round=$((round + 1))
   112	
   113	  # No-progress guard (skipped once terminal — the close check at loop top handles that).
   114	  IFS=$'\t' read -r ntstatus nactor < <(token_state)
   115	  if ! terminal_status "$(file_status)" && [[ "$ntstatus:$nactor" == "$prev" ]]; then
   116	    printf 'relay-drive: no progress after %s turn (token still %s) — escalating\n' "$actor" "$prev" >&2
   117	    exit 3
   118	  fi
   119	done
   120	
   121	# Cap reached: success only if file terminal AND token not live (same agreement).
   122	s="$(file_status)"; IFS=$'\t' read -r tstatus actor < <(token_state)
   123	if terminal_status "$s" && [[ -z "$actor" ]]; then
   124	  printf 'relay-drive: relay terminated (STATUS: %s)\n' "$s"; exit 0
   125	fi
   126	printf 'relay-drive: round cap (%d) exceeded (STATUS: %s, token actor: %s) — escalating\n' "$ROUND_CAP" "$s" "${actor:-none}" >&2
   127	exit 4

exec
/bin/zsh -lc "rg -n \"RELAY_PEER|marathon\\.phase\\.|task\\.created|claim|release|done|phase.approved|phase.escalated|phase.start\" relay-automation bin src test" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
src/take.js:8:// Atomic next+claim under one lock. Eliminates the TOCTOU gap between
src/take.js:9:// `tick next` and `tick claim` where another agent can snatch the task
src/take.js:12:// Uses the task's own declared paths as the claim paths (the agent can call
src/take.js:14://   { won: true, task, priority }          — task claimed
src/take.js:16://   { limitReached: true, holding: [...] } — agent is at the claim cap
src/take.js:26:    // Exclude paths held by ANY active claim — other agents (lane separation)
src/take.js:29:    // would inflate the concurrent-claim metric without real parallel work).
src/take.js:30:    const claimedPaths = [];
src/take.js:32:      if (t.status === 'claimed') {
src/take.js:33:        for (const p of t.claim.paths) claimedPaths.push(p);
src/take.js:40:      if (setsOverlap(t.paths, claimedPaths)) continue;
src/take.js:57:    appendEvent(repoRoot, { type: 'task.claimed', task: chosen.id, agent, paths: chosen.paths });
test/claim-cap.sh:2:# Run 2 P1/P2: per-agent claim cap (MAX_ACTIVE_CLAIMS_PER_AGENT = 2).
test/claim-cap.sh:3:# An agent may hold at most 2 active claims. The 3rd claim is refused and
test/claim-cap.sh:4:# writes ZERO events; `tick next` reports the limit; after `tick done` frees a
test/claim-cap.sh:5:# slot, the 3rd claim succeeds. Tasks have non-overlapping paths so the cap —
test/claim-cap.sh:6:# not path-routing — is what blocks the 3rd claim.
test/claim-cap.sh:7:source "$(dirname "$0")/_setup.sh" claim-cap
test/claim-cap.sh:12:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-1 --agent dispatcher --priority 10 --paths "src/one/**"   >/dev/null
test/claim-cap.sh:13:TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created TASK-2 --agent dispatcher --priority 10 --paths "src/two/**"   >/dev/null
test/claim-cap.sh:14:TICK_TS=2026-05-04T10:00:00.200Z tick_a log task.created TASK-3 --agent dispatcher --priority 10 --paths "src/three/**" >/dev/null
test/claim-cap.sh:17:# alice claims two — both win (non-overlapping paths, under the cap).
test/claim-cap.sh:18:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >"$WORK/c1.out"
test/claim-cap.sh:19:TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/two/**" >"$WORK/c2.out"
test/claim-cap.sh:21:  pass "alice claimed two tasks (under cap)"
test/claim-cap.sh:23:  fail "alice could not claim two tasks: $(cat "$WORK/c1.out" "$WORK/c2.out")"
test/claim-cap.sh:26:# Snapshot event count before the capped claim attempt.
test/claim-cap.sh:29:# Third claim must be refused with the limit message.
test/claim-cap.sh:30:TICK_TS=2026-05-04T10:00:03.000Z tick_a claim TASK-3 --agent alice --paths "src/three/**" >"$WORK/c3.out"
test/claim-cap.sh:31:if grep -q "claim limit reached" "$WORK/c3.out"; then
test/claim-cap.sh:32:  pass "third claim refused with limit message"
test/claim-cap.sh:34:  fail "third claim was not refused: $(cat "$WORK/c3.out")"
test/claim-cap.sh:40:  pass "refused claim wrote zero events ($BEFORE == $AFTER)"
test/claim-cap.sh:42:  fail "refused claim wrote events ($BEFORE -> $AFTER)"
test/claim-cap.sh:47:if grep -q "claim limit reached" "$WORK/n.out"; then
test/claim-cap.sh:48:  pass "tick next reports the claim limit"
test/claim-cap.sh:54:TICK_TS=2026-05-04T10:00:04.000Z tick_a done TASK-1 --agent alice >/dev/null
test/claim-cap.sh:56:# Now the third claim should succeed.
test/claim-cap.sh:57:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-3 --agent alice --paths "src/three/**" >"$WORK/c3b.out"
test/claim-cap.sh:59:  pass "third claim succeeds after a slot is freed"
test/claim-cap.sh:61:  fail "third claim still refused after done: $(cat "$WORK/c3b.out")"
relay-automation/marathon-agent.sh:16:# Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
relay-automation/marathon-agent.sh:17:#   MARATHON_BUILDER  — builder agent id; when RELAY_AGENT matches this, RELAY_PEER = MARATHON_REVIEWER
relay-automation/marathon-agent.sh:18:#   MARATHON_REVIEWER — reviewer agent id; when RELAY_AGENT is the reviewer, RELAY_PEER = MARATHON_BUILDER
relay-automation/marathon-agent.sh:34:# RELAY_PEER threading: builder's peer is the reviewer; reviewer's peer is the builder.
relay-automation/marathon-agent.sh:35:# A live turn that lacks an explicit peer can release to a literal role-string (Gemini 2026-06-15).
relay-automation/marathon-agent.sh:38:    export RELAY_PEER="$MARATHON_REVIEWER"
relay-automation/marathon-agent.sh:40:    export RELAY_PEER="$MARATHON_BUILDER"
bin/tick:10:const { claim } = require('../src/claim');
bin/tick:11:const { scope, release, circuitBreak, done, reap, heartbeat } = require('../src/scope');
bin/tick:60:  tick claim <task> --agent <id> --paths <globs>
bin/tick:61:  tick take --agent <id>                           (atomic next+claim)
bin/tick:64:  tick release <task> --agent <id> [--to <agent>]
bin/tick:66:  tick done <task> --agent <id> [--note "..."]
bin/tick:115:    case 'claim': {
bin/tick:118:      const result = claim(root, {
bin/tick:124:        process.stdout.write(`lost: claim limit reached (holding ${result.holding.join(', ')}) — finish or release first\n`);
bin/tick:128:        process.stdout.write(`won: ${task} claimed by ${flags.agent}\n`);
bin/tick:132:        process.stdout.write(`lost: ${task} is ${result.unavailable} — not claimable\n`);
bin/tick:135:      process.stdout.write(`lost: ${task} already claimed by ${result.winner || 'unknown'}\n`);
bin/tick:143:        process.stdout.write(`(claim limit reached — holding ${tr.holding.join(', ')} — finish or release a task first)\n`);
bin/tick:156:        process.stdout.write(`(claim limit reached — holding ${t.holding.join(', ')} — finish or release a task first)\n`);
bin/tick:173:    case 'release': {
bin/tick:176:      release(root, { task, agent: flags.agent, to_agent: typeof flags.to === 'string' ? flags.to : undefined });
bin/tick:177:      process.stdout.write(`released: ${task}\n`);
bin/tick:189:    case 'done': {
bin/tick:192:      done(root, { task, agent: flags.agent, note: typeof flags.note === 'string' ? flags.note : undefined });
bin/tick:193:      process.stdout.write(`done: ${task}\n`);
bin/tick:211:        process.stdout.write(`(no active claims held by ${agent})\n`);
bin/tick:213:        process.stdout.write(`reaped ${result.reaped.length} claim(s) from ${agent}: ${result.reaped.join(', ')}\n`);
bin/tick:229:      const paths = t.status === 'claimed' ? t.claim.paths : t.paths;
bin/tick:231:      if (t.status === 'claimed') lines.push(`claimer:  ${t.claim.agent}`);
src/lock.js:8:// `tick claim` does project(read) -> cap-check -> appendEvent(write). That is a
src/lock.js:9:// TOCTOU window: two concurrent `tick claim` processes for the SAME agent could
src/lock.js:12:// Fix: a per-clone O_EXCL lock serialises one agent's own claim calls. The
src/lock.js:17:// Known limitation: a hard process kill mid-claim leaves a stale lock. Recovery
src/lock.js:18:// is `rm <repo>/.tick/locks/claim.lock`. Stale-detection is Phase 2.
src/lock.js:23:  return path.join(locksDir, 'claim.lock');
src/lock.js:26:// Run `fn` while holding the per-clone claim lock. `fs.openSync(.., 'wx')` is an
src/lock.js:36:        'another tick claim is in progress for this clone (lock held) — retry shortly, ' +
src/lock.js:37:        `or remove ${path.relative(repoRoot, lp)} if a prior claim was killed`
test/poll-driver.sh:4:# (ii) fake live integration. NOTE: per-agent claim cap is 2, so my-turn cases use
test/poll-driver.sh:5:# open+handoff-to-me (the poller never claims) to stay cap-safe; distinct claimers
test/poll-driver.sh:25:# open + handoff_to <agent> (no active claim held → cap-safe); each call uses a fresh seed.
test/poll-driver.sh:26:handoff_to(){ tick_a log task.created "$1" --agent dispatcher >/dev/null; tick_a claim "$1" --agent "seed-$1" --paths "z/**" >/dev/null; tick_a release "$1" --agent "seed-$1" --to "$2" >/dev/null; }
test/poll-driver.sh:27:# claimed by <agent>
test/poll-driver.sh:28:claim_by(){ tick_a log task.created "$1" --agent dispatcher >/dev/null; tick_a claim "$1" --agent "$2" --paths "z/**" >/dev/null; }
test/poll-driver.sh:38:claim_by RT-resume alice
test/poll-driver.sh:40:  && pass "claimed-by-me (resume) -> run-runner" || fail "expected run-runner (resume)"
test/poll-driver.sh:41:tick_a done RT-resume --agent alice >/dev/null   # free alice's slot
test/poll-driver.sh:43:claim_by RT-other bob
test/poll-driver.sh:45:  && pass "claimed-by-other -> idle" || fail "expected idle"
test/poll-driver.sh:51:claim_by RT-parked bobp
test/poll-driver.sh:94:claim_by RT-live-parked bobw
relay-automation/consult.sh:65:done
relay-automation/consult.sh:109:done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)
relay-automation/consult.sh:157:done
relay-automation/consult.sh:170:done
src/claim.js:7:// Local-transport claim (Run 2: git transport removed).
src/claim.js:10:// claim calls. Together that makes `tick claim` a real mutex: read current
src/claim.js:12:// no auto-release. Those existed only to reconcile the old distributed
src/claim.js:14:function claim(repoRoot, { task, agent, paths }) {
src/claim.js:16:    throw new Error('claim requires --paths (declare every glob you intend to touch)');
src/claim.js:23:    // Already terminal — not claimable.
src/claim.js:24:    if (t && (t.status === 'done' || t.status === 'circuit_broken')) {
src/claim.js:28:    // Already claimed.
src/claim.js:29:    if (t && t.status === 'claimed') {
src/claim.js:30:      if (t.claim.agent === agent) {
src/claim.js:33:      return { won: false, task, winner: t.claim.agent };
src/claim.js:41:    // Per-agent claim cap.
src/claim.js:47:    appendEvent(repoRoot, { type: 'task.claimed', task, agent, paths });
src/claim.js:53:module.exports = { claim };
test/concurrent-claim.sh:2:# AC #1: two agents race to claim the same task. The O_EXCL lock serialises
test/concurrent-claim.sh:5:source "$(dirname "$0")/_setup.sh" concurrent-claim
test/concurrent-claim.sh:8:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 10 --paths "src/auth/**" >/dev/null
test/concurrent-claim.sh:10:# Alice claims first.
test/concurrent-claim.sh:11:tick_a claim TASK-007 --agent alice --paths "src/auth/**" >"$WORK/a.out"
test/concurrent-claim.sh:13:  pass "alice won the claim"
test/concurrent-claim.sh:18:# Bob tries to claim the same task — must lose.
test/concurrent-claim.sh:19:tick_b claim TASK-007 --agent bob --paths "src/auth/**" >"$WORK/b.out"
test/concurrent-claim.sh:21:  pass "bob lost the claim (task already held by alice)"
test/concurrent-claim.sh:26:# STATE.md must show exactly alice as claimer.
test/concurrent-claim.sh:29:  pass "STATE.md shows TASK-007 claimed by alice"
test/concurrent-claim.sh:34:# Idempotent re-claim by alice returns won.
test/concurrent-claim.sh:35:tick_a claim TASK-007 --agent alice --paths "src/auth/**" >"$WORK/a2.out"
test/concurrent-claim.sh:37:  pass "alice's idempotent re-claim returns won"
test/concurrent-claim.sh:39:  fail "idempotent re-claim failed: $(cat "$WORK/a2.out")"
test/concurrent-claim.sh:42:# Terminal task can't be claimed.
test/concurrent-claim.sh:43:tick_a done TASK-007 --agent alice >/dev/null
test/concurrent-claim.sh:44:tick_a claim TASK-007 --agent bob --paths "src/auth/**" >"$WORK/done.out"
test/concurrent-claim.sh:45:if grep -q "^lost:.*done" "$WORK/done.out"; then
test/concurrent-claim.sh:46:  pass "done task returns lost with unavailable=done"
test/concurrent-claim.sh:48:  fail "done task claim unexpected: $(cat "$WORK/done.out")"
relay-automation/marathon.sh:12:# the boundary events already land in .tick/events/ (phase.start/approved/escalated, marathon.complete).
relay-automation/marathon.sh:50:done
relay-automation/marathon.sh:89:done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')
relay-automation/relay-drive.sh:5:# turn-token held as a tick **RELAY-TURN task** (claim / ping / release --to / done).
relay-automation/relay-drive.sh:9:# Option A). The turn-taker owns the work + thread mutation — it claims/resumes the
relay-automation/relay-drive.sh:11:# file's STATUS/verdict, then **`tick release RELAY-TURN --to <other>`** to hand off
relay-automation/relay-drive.sh:12:# (or **`tick done RELAY-TURN`** + STATUS: Approved on the final turn), and commits.
relay-automation/relay-drive.sh:34:                      Must take the turn on the RELAY-TURN task (claim/ping/append/
relay-automation/relay-drive.sh:35:                      release --to <other> | done) and commit.
relay-automation/relay-drive.sh:56:done
relay-automation/relay-drive.sh:64:# Current actor of the RELAY-TURN token: claimer (if claimed) else handoff_to (if
relay-automation/relay-drive.sh:65:# open) else "" (done/missing). Echoes "<status>\t<actor>".
relay-automation/relay-drive.sh:67:  local info status claimer handoff actor
relay-automation/relay-drive.sh:70:  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
relay-automation/relay-drive.sh:73:    claimed) actor="$claimer" ;;
relay-automation/relay-drive.sh:86:  # token no longer live (done/gone). file-terminal-but-token-live is a leaked
relay-automation/relay-drive.sh:93:    printf 'relay-drive: relay terminated (STATUS: %s, token done) after %d turn(s)\n' "$s" "$round"
relay-automation/relay-drive.sh:97:  # file not terminal but the token is gone/done → also a mismatch.
relay-automation/relay-drive.sh:119:done
test/reap.sh:2:# Run 2 P5: `tick reap <agent>` releases every active claim held by a
test/reap.sh:11:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-1 --agent dispatcher --priority 10 --paths "src/one/**" >/dev/null
test/reap.sh:12:TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created TASK-2 --agent dispatcher --priority 10 --paths "src/two/**" >/dev/null
test/reap.sh:14:# alice claims both, then "crashes" (just stops).
test/reap.sh:15:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >/dev/null
test/reap.sh:16:TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/two/**" >/dev/null
test/reap.sh:18:# Coordinator reaps alice's claims. tick_b shares TICK_REPO_ROOT with tick_a.
test/reap.sh:20:if grep -q "reaped 2 claim(s) from alice" "$WORK/reap.out"; then
test/reap.sh:21:  pass "reap released both of alice's claims"
test/reap.sh:26:# Two task.released events for alice must exist in the log.
test/reap.sh:27:RELEASED=$(ls "$A/.tick/events/" | grep -c "alice-released" || true)
test/reap.sh:29:  pass "two task.released events emitted for alice"
test/reap.sh:31:  fail "expected 2 alice-released events, got $RELEASED"
test/reap.sh:34:# STATE.md: tasks must no longer be claimed by alice.
test/reap.sh:37:  fail "TASK-1 still claimed by alice after reap"
test/reap.sh:39:  pass "TASK-1 no longer claimed by alice after reap"
test/reap.sh:42:# A peer can now claim a reaped task.
test/reap.sh:43:TICK_TS=2026-05-04T10:00:10.000Z tick_b claim TASK-1 --agent bob --paths "src/one/**" >"$WORK/bob.out"
test/reap.sh:45:  pass "a peer can claim a reaped task"
test/reap.sh:47:  fail "peer could not claim reaped task: $(cat "$WORK/bob.out")"
test/reap.sh:50:# Reaping an agent with no active claims is a clean no-op.
test/reap.sh:52:if grep -q "no active claims held by alice" "$WORK/reap2.out"; then
test/reap.sh:53:  pass "reap of an agent with no claims is a clean no-op"
src/scope.js:16://   - task is not currently claimed
src/scope.js:17://   - the claimer doesn't match `agent`
src/scope.js:18:// Only `reap` bypasses this (it explicitly operates on other agents' claims).
src/scope.js:23:  if (t.status !== 'claimed') throw new Error(`task ${task} is ${t.status} — only the claiming agent can mutate it`);
src/scope.js:24:  if (t.claim.agent !== agent) throw new Error(`task ${task} is claimed by ${t.claim.agent}, not ${agent}`);
src/scope.js:34:function release(repoRoot, { task, agent, to_agent }) {
src/scope.js:36:  emitEvent(repoRoot, 'task.released', { task, agent, to_agent });
src/scope.js:46:function done(repoRoot, { task, agent, note }) {
src/scope.js:48:  emitEvent(repoRoot, 'task.done', { task, agent, note });
src/scope.js:52:// Liveness heartbeat (Run 3). The claiming agent emits one of these while
src/scope.js:53:// actively working a task so the post-run parked-claim check has a work-activity
src/scope.js:55:// claim window with no heartbeat for longer than the threshold is flagged as a
src/scope.js:56:// suspected parked claim by `tick analyze`. Heartbeats never change projected
src/scope.js:65:// Manual liveness lever (P5). Release every active claim held by a (presumed
src/scope.js:67:// task.released carries `agent = <crashed agent>` — that is what the
src/scope.js:68:// projection needs to treat the claim as released — plus a note recording the
src/scope.js:75:    if (t.status === 'claimed' && t.claim && t.claim.agent === agent) {
src/scope.js:84:      type: 'task.released',
src/scope.js:95:module.exports = { scope, release, circuitBreak, done, reap, heartbeat };
relay-automation/CROSSMODEL-OPTIONA-PLAN.md:42:## Sub-steps — ✅ SHIPPED 2026-06-15 (X1 + X2 done)
relay-automation/CROSSMODEL-OPTIONA-PLAN.md:44:> **X2 ✅** live run: a real `codex exec` turn (no window) took a relay Reviewer turn in an isolated repo — found the seeded typo, wrote a graded block + verdict, released the token, and the shim committed **only `relay.md`, file-scoped, no push** (verified: repo had no remote; commit touched 1 file). **Cross-model coordination + Option A proven end-to-end.** Cost: a real Codex turn is tens-of-k tokens (cap rounds).
relay-automation/CROSSMODEL-OPTIONA-PLAN.md:47:- **X1 — `codex-turn.sh` shim (mandatory) + test.** Build the shim per the Design above. *Accept:* a test injecting a **stub `codex`** that performs the *real turn-taker contract* — `tick claim/ping/release|done` **and** mutates the relay file (not just emits `VERDICT:`) — drives one turn through `relay-drive.sh`; plus a negative test: the stub touches an **off-allowlist file** → the shim **reverts it, stages nothing extra, and fails** (proves the allowlist guard). No push occurs.
relay-automation/CROSSMODEL-OPTIONA-PLAN.md:62:- [Should] don't test a VERDICT-only fake → **X1 stub does the real `tick claim/ping/release/done` + file mutation**, plus a negative allowlist test.
relay-automation/marathon-drive.sh:16:#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
relay-automation/marathon-drive.sh:32:# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
relay-automation/marathon-drive.sh:53:  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
relay-automation/marathon-drive.sh:92:done
relay-automation/marathon-drive.sh:126:REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
relay-automation/marathon-drive.sh:138:    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
relay-automation/marathon-drive.sh:155:# Builder/reviewer instruction text + the tick claim --paths depend on whether this phase targets
relay-automation/marathon-drive.sh:190:   - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
relay-automation/marathon-drive.sh:192:   - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
relay-automation/marathon-drive.sh:201:2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
relay-automation/marathon-drive.sh:202:3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
relay-automation/marathon-drive.sh:209:  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
relay-automation/marathon-drive.sh:222:"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
relay-automation/marathon-drive.sh:223:"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
relay-automation/marathon-drive.sh:224:"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
relay-automation/marathon-drive.sh:227:# ── Step 4: emit phase.start ────────────────────────────────────────────────
relay-automation/marathon-drive.sh:229:"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
relay-automation/marathon-drive.sh:230:log "phase start: running relay-drive --round-cap $ROUND_CAP"
relay-automation/marathon-drive.sh:262:  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
relay-automation/marathon-drive.sh:279:    # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
relay-automation/marathon-drive.sh:288:    "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
test/poll-relay.sh:3:# The fake turn-taker does REAL tick ops (claim/ping/release/done). The happy path
test/poll-relay.sh:14:#   takes the token (claim+ping), appends a block, then per MODE+role:
test/poll-relay.sh:15:#   normal     -> reviewer(RA): 1st turn release-to-producer (changes requested),
test/poll-relay.sh:16:#                 2nd turn STATUS:Approved + `tick done` ; producer(PA): release-to-reviewer
test/poll-relay.sh:17:#   loop       -> reviewer never approves (always release back) — drives the cap
test/poll-relay.sh:18:#   noprogress -> claim+ping but never release/done
test/poll-relay.sh:25:"$TICK" claim "$t" --agent "$me" --paths "z/**" >/dev/null 2>&1   # idempotent if already held
test/poll-relay.sh:31:  if [ "$n" -ge 2 ] && { [ "$mode" = normal ] || [ "$mode" = approvenodone ]; }; then
test/poll-relay.sh:34:    [ "$mode" = normal ] && "$TICK" done "$t" --agent "$me" >/dev/null 2>&1   # approvenodone: skip done -> leaked live token
test/poll-relay.sh:37:    "$TICK" release "$t" --agent "$me" --to "$other" >/dev/null 2>&1
test/poll-relay.sh:40:  "$TICK" release "$t" --agent "$me" --to "$other" >/dev/null 2>&1
test/poll-relay.sh:50:  tick_a log task.created "$1" --agent dispatcher >/dev/null
test/poll-relay.sh:51:  tick_a claim "$1" --agent dispatcher --paths "z/**" >/dev/null
test/poll-relay.sh:52:  tick_a release "$1" --agent dispatcher --to ra >/dev/null   # open + handoff_to ra
test/poll-relay.sh:65:[ "$(task_status RELAY-TURN-1)" = "done" ] && pass "RELAY-TURN token ended done (re-handed across turns)" || fail "token not done: $(task_status RELAY-TURN-1)"
test/poll-relay.sh:80:# --- (3b) close mismatch: STATUS Approved but token never `done` (Codex r1) ---
test/poll-relay.sh:82:bash "$DRIVE" --relay-file "$R5" --relay-task RELAY-TURN-5 --agent-cmd "$(AC approvenodone)" --round-cap 8 >/dev/null 2>&1
test/poll-relay.sh:84:[ "$rc" -eq 4 ] && pass "close mismatch (STATUS Approved, token not done) escalates (exit 4)" || fail "expected exit 4, got $rc"
test/poll-relay.sh:85:[ "$(task_status RELAY-TURN-5)" = "claimed" ] && pass "leaked live token is NOT reported as a clean close" || fail "token should still be live, got: $(task_status RELAY-TURN-5)"
src/project.js:8:// Tie-breaker for concurrent claims on the same task: earliest event ts wins;
src/project.js:10:// expected to have a corresponding task.released event (auto-emitted by the
src/project.js:11:// claim verb after re-projection).
src/project.js:30:      claim: null,
src/project.js:35:    // First, find the deterministic winning claim and the absolute terminal
src/project.js:36:    // event (done/break) — these decide the task's terminal state.
src/project.js:39:      if (ev.type === 'task.done' || ev.type === 'task.circuit_break') terminal = ev;
src/project.js:42:    // Collect claims, then determine the live-claim winner: earliest ts (lex
src/project.js:43:    // agent on tie) whose agent has not subsequently emitted a release with a
src/project.js:44:    // ts >= the claim's.
src/project.js:45:    const claims = evs.filter(e => e.type === 'task.claimed');
src/project.js:46:    const releases = evs.filter(e => e.type === 'task.released');
src/project.js:47:    const liveClaims = claims.filter(c =>
src/project.js:48:      !releases.some(r => r.agent === c.agent && r.ts >= c.ts)
src/project.js:57:    // apply scope_changed updates that occurred AFTER the winning claim.
src/project.js:60:        case 'task.created':
src/project.js:64:        case 'task.released':
src/project.js:77:      if (terminal.type === 'task.done') {
src/project.js:78:        t.status = 'done';
src/project.js:84:      t.status = 'claimed';
src/project.js:85:      t.claim = {
src/project.js:90:      // Once claimed, clear handoff_to (handoff was satisfied by the new claim).
src/project.js:91:      // But if the latest event is a release-with-handoff after this claim,
src/project.js:92:      // keep it. Walk events: take the last release.to_agent that occurred
src/project.js:93:      // AFTER the winning claim.
src/project.js:96:        if (ev.type === 'task.released' && ev.to_agent && ev.ts > winner.ts) {
src/project.js:119:  const claimed = all.filter(t => t.status === 'claimed');
src/project.js:120:  const done = all.filter(t => t.status === 'done');
src/project.js:133:  if (!claimed.length) lines.push('_(none)_');
src/project.js:134:  for (const t of claimed) {
src/project.js:135:    const paths = t.claim.paths.length ? ` paths: ${JSON.stringify(t.claim.paths)}` : '';
src/project.js:136:    lines.push(`- ${t.id} by ${t.claim.agent}${paths}`);
src/project.js:141:  if (!done.length) lines.push('_(none)_');
src/project.js:142:  for (const t of done) lines.push(`- ${t.id}`);
src/project.js:164:// --- Per-agent claim cap (Run 2, P1) ------------------------------------
src/project.js:165:// An agent may hold at most this many simultaneously-active claims.
src/project.js:169:// Task IDs currently actively claimed by `agent` (status === 'claimed').
src/project.js:173:    if (t.status === 'claimed' && t.claim && t.claim.agent === agent) {
relay-automation/QUICKSTART.md:69:./bin/tick log task.created RELAY-TURN --agent claude-a
relay-automation/QUICKSTART.md:70:./bin/tick claim   RELAY-TURN --agent claude-a --paths "$ARTIFACT"
relay-automation/QUICKSTART.md:71:./bin/tick release RELAY-TURN --agent claude-a --to codex
relay-automation/QUICKSTART.md:81:What to expect: Codex takes the turn (claims/pings the token, appends its block to `$RELAY`,
relay-automation/QUICKSTART.md:82:releases or `done`s the token), then the shim **reverts anything off the allowlist**, commits
relay-automation/watchdog.sh:49:# matched the healthy-run summary line "parked-claim suspects: none" and would
relay-automation/watchdog.sh:169:done
relay-automation/watchdog.sh:189:done <<<"$parked_suspects"
test/circuit-break.sh:7:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 100 --paths "src/auth/**" >/dev/null
test/circuit-break.sh:8:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-008 --agent dispatcher --priority 1   --paths "src/billing/**" >/dev/null
test/circuit-break.sh:16:# Alice must claim before breaking (ownership enforcement).
test/circuit-break.sh:17:TICK_TS=2026-05-04T10:00:04.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
relay-automation/poll.sh:9:# Two modes (one decision engine, shared tick claimability):
relay-automation/poll.sh:10:#   xyz   — runnable state = a build task (--task) claimable/resumable by --agent
relay-automation/poll.sh:11:#   relay — runnable state = the RELAY-TURN tick task (claimable/resumable by --agent);
relay-automation/poll.sh:85:done
relay-automation/poll.sh:125:  T_CLAIMER="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
relay-automation/poll.sh:131:#   open + (no handoff | handoff==me)  OR  claimed + claimer==me
relay-automation/poll.sh:134:  [[ "$T_STATUS" == "claimed" && "$T_CLAIMER" == "$AGENT" ]] && return 0
relay-automation/poll.sh:142:  for x in "${_ca[@]}"; do [[ "$x" == "$a" ]] && return 0; done
src/analyze.js:10:// from .tick/events/. The primary metric is concurrent-claim time: how much of
src/analyze.js:11:// the run window had two agents holding active claims at once.
src/analyze.js:29:// Per-(agent, task) claim windows from the event timeline. A window opens at
src/analyze.js:30:// task.claimed and closes at the next terminal event for that task
src/analyze.js:31:// (task.released / task.done / task.circuit_break). With the git transport
src/analyze.js:32:// gone there is no tie-breaker and no auto-release — claim.js refuses a second
src/analyze.js:33:// claimer outright — so at most one window is open per task at a time.
src/analyze.js:45:      if (ev.type === 'task.claimed') {
src/analyze.js:52:        ev.type === 'task.released' ||
src/analyze.js:53:        ev.type === 'task.done' ||
src/analyze.js:67:// Concurrent-claim-time metric (Run 2, P4). How much of the run window had
src/analyze.js:68:// >= 2 distinct agents each holding >= 1 active claim simultaneously. This is
src/analyze.js:70:// lopsided split, this can't. An agent may hold up to 2 claims at once (the
src/analyze.js:114:// Parked-claim detection (Run 3). A claim window is a "parked-claim suspect" if
src/analyze.js:116:// threshold at any point in the window. Activity points are: the claim itself
src/analyze.js:121:// 3 criterion disqualifies a run with any parked-claim suspect.
src/analyze.js:160:// coordination math deliberately ignores) + the claim windows. Reports tokens / wall-clock /
src/analyze.js:163:function computeCost(allEvents, windows, doneTaskIds, runWindowMs, runType) {
src/analyze.js:164:  const doneCount = doneTaskIds.size;
src/analyze.js:186:  // Per-task + per-agent wall-clock from CLOSED claim windows (still-open windows have no duration).
src/analyze.js:198:  // Coverage measures how many DONE-tasks carry token data — that's what makes per-done trustworthy.
src/analyze.js:199:  // (Tokens spent on not-yet-done tasks still count toward the total spend, but not toward coverage.)
src/analyze.js:200:  // instrumentedDone < doneCount => tokens are a FLOOR, and the renderers must say so
src/analyze.js:203:  for (const id of doneTaskIds) if (instrumentedTasks.has(id)) instrumentedCount++;
src/analyze.js:204:  const partial = instrumentedCount < doneCount;
src/analyze.js:205:  const perDone = doneCount > 0;
src/analyze.js:213:      done_tasks: doneCount,
src/analyze.js:214:      coverage: `${instrumentedCount}/${doneCount}`,
src/analyze.js:225:      tokens_per_done: perDone ? Math.round(totT / doneCount) : null,
src/analyze.js:226:      walltime_per_done_ms: perDone ? Math.round(runWindowMs / doneCount) : null,
src/analyze.js:235:  // run window, parked-claims) byte-identical to pre-cost runs. (COST-OBSERVABILITY-PLAN, Phase 1 QA.)
src/analyze.js:244:        claims: 0,
src/analyze.js:246:        dones: 0,
src/analyze.js:247:        releases: 0,
src/analyze.js:260:      case 'task.claimed': a.claims++; break;
src/analyze.js:262:      case 'task.done': a.dones++; break;
src/analyze.js:263:      case 'task.released': a.releases++; if (ev.to_agent) a.handoffs++; break;
src/analyze.js:269:  // The dispatcher only seeds task.created events — drop it from per-agent.
src/analyze.js:282:  const doneTaskIds = new Set(events.filter(e => e.type === 'task.done').map(e => e.task));
src/analyze.js:283:  const cost = computeCost(allEvents, windows, doneTaskIds, parallelism.run_window_ms, process.env.TICK_RUN_TYPE);
src/analyze.js:291:      created: events.filter(e => e.type === 'task.created').length,
src/analyze.js:292:      claimed: events.filter(e => e.type === 'task.claimed').length,
src/analyze.js:293:      released: events.filter(e => e.type === 'task.released').length,
src/analyze.js:296:      done: events.filter(e => e.type === 'task.done').length,
src/analyze.js:312:    out.push(`concurrent-claim time: ${humanDuration(p.concurrent_ms)} of ${humanDuration(p.run_window_ms)} run window (${p.concurrent_pct}%)`);
src/analyze.js:314:    out.push('concurrent-claim time: not computable (run window too short)');
src/analyze.js:318:    out.push(`parked-claim suspects: ${ps.length} (DISQUALIFIES run)`);
src/analyze.js:323:    out.push('parked-claim suspects: none');
src/analyze.js:329:    out.push(`  claims: ${a.claims}, done: ${a.dones}, heartbeats: ${a.heartbeats}`);
src/analyze.js:330:    out.push(`  released: ${a.releases} (${a.handoffs} as handoff), broken: ${a.breaks}, scope_changes: ${a.scope_changes}, commented: ${a.comments}`);
src/analyze.js:340:      (tk.partial ? ` — PARTIAL, floor only: ${tk.coverage} done-tasks instrumented` : ''));
src/analyze.js:343:    if (c.per_unit.tokens_per_done !== null) {
src/analyze.js:344:      out.push(`per done-task: ${ge}${c.per_unit.tokens_per_done} tokens, ${humanDuration(c.per_unit.walltime_per_done_ms)} wall-clock`);
src/analyze.js:346:      out.push('per done-task: n/a (0 tasks done)');
src/analyze.js:361:    out.push(`- **Concurrent-claim time (primary metric):** both agents held an active claim simultaneously for ${humanDuration(p.concurrent_ms)} of the ${humanDuration(p.run_window_ms)} run window (**${p.concurrent_pct}%**)`);
src/analyze.js:363:    out.push('- **Concurrent-claim time (primary metric):** not computable (run window too short)');
src/analyze.js:367:    out.push(`- **Parked-claim suspects (DISQUALIFIES run):** ${ps.length} — ` +
src/analyze.js:370:    out.push('- **Parked-claim suspects:** none');
src/analyze.js:378:    out.push(`- **Tasks claimed:** ${a.claims}`);
src/analyze.js:379:    out.push(`- **Tasks completed (\`tick done\`):** ${a.dones}`);
src/analyze.js:382:    out.push(`- **Releases:** ${a.releases} (${a.handoffs} as handoff), comments: ${a.comments}`);
src/analyze.js:396:        ? ` — ⚠️ **PARTIAL (floor only):** ${tk.coverage} done-tasks instrumented; treat as a lower bound, not an exact sum`
src/analyze.js:400:    if (c.per_unit.tokens_per_done !== null) {
src/analyze.js:401:      out.push(`- **Cost per done-task:** ${ge}${c.per_unit.tokens_per_done} tokens, ${humanDuration(c.per_unit.walltime_per_done_ms)} wall-clock`);
src/analyze.js:403:      out.push('- **Cost per done-task:** n/a (0 tasks done)');
relay-automation/runner.sh:12:- claimability guard: open+handoff_to=agent => claim, claimed+claimer=agent => resume, else poll
relay-automation/runner.sh:19:  --agent AGENT           Agent id to assert against handoff/claimer state.
relay-automation/runner.sh:47:claimability_mode() {
relay-automation/runner.sh:48:  local status handoff_to claimer
relay-automation/runner.sh:51:  claimer="$(read_task_field "claimer" || true)"
relay-automation/runner.sh:54:    printf 'claim\n'
relay-automation/runner.sh:58:  if [[ "$status" == "claimed" && "$claimer" == "$AGENT" ]]; then
relay-automation/runner.sh:77:claim_task() {
relay-automation/runner.sh:81:  "$TICK_BIN" claim "$TASK_ID" --agent "$AGENT" --paths "$task_paths" >/dev/null
relay-automation/runner.sh:98:      "$TICK_BIN" done "$TASK_ID" --agent "$AGENT" >/dev/null
relay-automation/runner.sh:121:  printf 'runner: %s not claimable for %s; polling again in %ss\n' "$TASK_ID" "$AGENT" "$POLL_SECONDS" >&2
relay-automation/runner.sh:172:done
relay-automation/runner.sh:188:  case "$(claimability_mode)" in
relay-automation/runner.sh:189:    claim)
relay-automation/runner.sh:190:      claim_task
relay-automation/runner.sh:200:      die "unexpected claimability mode"
relay-automation/runner.sh:213:done
test/handoff.sh:2:# AC #4: alice releases TASK-007 with --to bob. Bob's `tick next` returns
test/handoff.sh:7:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 1   --paths "src/auth/**" >/dev/null
test/handoff.sh:8:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-099 --agent dispatcher --priority 100 --paths "src/billing/**" >/dev/null
test/handoff.sh:17:# Alice claims and immediately hands off TASK-007 to bob.
test/handoff.sh:18:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/handoff.sh:19:TICK_TS=2026-05-04T10:00:06.000Z tick_a release TASK-007 --agent alice --to bob >/dev/null
test/marathon.sh:11:for p in p1 p2 p3 a b; do printf 'brief for %s\n' "$p" > "$A/briefs/$p.md"; done
test/marathon.sh:25:esac; done
relay-automation/gemini-turn.sh:16:#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
relay-automation/gemini-turn.sh:20:#   RELAY_PEER       — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
relay-automation/gemini-turn.sh:55:prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
src/next.js:8://   0. If the agent is already at the claim cap, return { limitReached } —
src/next.js:12://      currently-claimed paths held by *other* agents.
src/next.js:19:  // Per-agent claim cap: an agent at the cap is not routed new work.
src/next.js:25:  const claimedByOthers = [];
src/next.js:27:    if (t.status === 'claimed' && t.claim.agent !== agent) {
src/next.js:28:      for (const p of t.claim.paths) claimedByOthers.push(p);
src/next.js:35:    if (setsOverlap(t.paths, claimedByOthers)) continue;
test/runner-loop.sh:2:# Proves the runner's injectable verdict loop: claim via handoff, resume/retry on
test/runner-loop.sh:3:# FAIL, and stop without done when the round cap is exceeded.
test/runner-loop.sh:36:# 1. PASS via the claim path: the task is open but handed off to codex, so the
test/runner-loop.sh:37:# runner must claim it by name, run the agent command once, then emit task.done.
test/runner-loop.sh:47:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-PASS --agent dispatcher --priority 10 --paths "README.md" >/dev/null
test/runner-loop.sh:48:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-PASS --agent alice --paths "README.md" >/dev/null
test/runner-loop.sh:49:TICK_TS=2026-05-04T10:00:02.000Z tick_a release TASK-PASS --agent alice --to codex >/dev/null
test/runner-loop.sh:57:DONE_EVENTS=$(ls "$A/.tick/events/" | grep -c "codex-done-TASK-PASS" || true)
test/runner-loop.sh:58:if [ "$DONE_EVENTS" = "1" ] && [ "$(status_of TASK-PASS)" = "done" ]; then
test/runner-loop.sh:59:  pass "runner claims the handed-off task and emits task.done"
test/runner-loop.sh:61:  fail "expected TASK-PASS done by codex, got status=$(status_of TASK-PASS) done_events=$DONE_EVENTS"
test/runner-loop.sh:64:# 2. FAIL then PASS via the resume path: the task is already claimed by codex.
test/runner-loop.sh:86:TICK_TS=2026-05-04T10:01:00.000Z tick_a log task.created TASK-RETRY --agent dispatcher --priority 8 --paths "README.md" >/dev/null
test/runner-loop.sh:87:TICK_TS=2026-05-04T10:01:01.000Z tick_a claim TASK-RETRY --agent codex --paths "README.md" >/dev/null
test/runner-loop.sh:95:if [ "$(cat "$RETRY_STATE")" = "2" ] && [ "$(status_of TASK-RETRY)" = "done" ]; then
test/runner-loop.sh:96:  pass "runner retried exactly once before emitting task.done"
test/runner-loop.sh:98:  fail "expected TASK-RETRY to take 2 runs and end done"
test/runner-loop.sh:101:# 3. Round cap exceeded: repeated FAILs return non-zero and MUST NOT emit task.done.
test/runner-loop.sh:111:TICK_TS=2026-05-04T10:02:00.000Z tick_a log task.created TASK-CAP --agent dispatcher --priority 6 --paths "README.md" >/dev/null
test/runner-loop.sh:112:TICK_TS=2026-05-04T10:02:01.000Z tick_a claim TASK-CAP --agent codex --paths "README.md" >/dev/null
test/runner-loop.sh:120:CAP_DONE_EVENTS=$(ls "$A/.tick/events/" | grep -c "codex-done-TASK-CAP" || true)
test/runner-loop.sh:121:if [ "$CAP_DONE_EVENTS" = "0" ] && [ "$(status_of TASK-CAP)" = "claimed" ]; then
test/runner-loop.sh:122:  pass "runner leaves the task claimed and emits no done event on round-cap failure"
test/runner-loop.sh:124:  fail "expected TASK-CAP to stay claimed with no done event"
relay-automation/PHASE-4A-SCOPE.md:11:secretly a 4–5 hour job. Every claim below is checkable against the current code:
relay-automation/PHASE-4A-SCOPE.md:15:- **tick owns whose-turn + liveness:** a `RELAY-TURN` task; current actor = its `claimer`/`handoff_to`. Hand off with `tick release RELAY-TURN --to <other-agent>`; final turn does `tick done RELAY-TURN`.
relay-automation/PHASE-4A-SCOPE.md:19:1. **poll.sh relay mode** — replace the `NEXT == my-role` check (`poll.sh:140-157`) with `tick info RELAY-TURN` claimability — **which already exists in xyz mode** (`open + handoff-to=me` / `claimed + claimer=me`). Net: relay+xyz guards converge (likely *less* code). Keep reading the file's `STATUS` for the stop decision. Clean-tree scope unchanged.
relay-automation/PHASE-4A-SCOPE.md:20:2. **relay-drive.sh** (`relay-drive.sh:~60-110`) — loop selects the actor from `RELAY-TURN` state (not file `NEXT`); the no-progress guard checks that the token moved (claimer/handoff changed) rather than `NEXT`.
relay-automation/PHASE-4A-SCOPE.md:21:3. **Turn-taker contract** — must now `tick ping RELAY-TURN` during the turn (so the watchdog can see liveness) and `tick release RELAY-TURN --to <other>` (or `done` on approve) instead of `sed`-flipping `NEXT`.
relay-automation/PHASE-4A-SCOPE.md:23:5. **Role↔agent plumbing** *(added — Codex Blocker)* — once whose-turn moves from file `NEXT` to the token's `handoff_to`/`claimer`, the manual-nudge + cross-model path must rederive from the **token's agent**, not `--my-role`/`--roles`/`--claude-agents` (`poll.sh:41-46,117-130,140-157,180-206`), and the supervisor→taker env contract changes from `RELAY_ROLE` to an **agent id** (`relay-drive.sh:20-22,78-88`). Not trivial wiring.
relay-automation/PHASE-4A-SCOPE.md:24:6. **Tests — a FULL SLICE, not an add-on** *(re-priced — Codex Blocker)*. Today they are baton-file fakes: `poll-driver.sh` only seeds `NEXT`/`STATUS` + analysis fixtures; `poll-relay.sh` mutates the file with `sed` and the fake taker **never** claims/pings/releases/completes a task. Converting both to drive real `RELAY-TURN` tick state is its own slice of work:
relay-automation/PHASE-4A-SCOPE.md:25:   - `poll-driver.sh` relay cases → seed a real `RELAY-TURN` (`handoff_to`/`claimer`/`status`) and assert decisions from tick state.
relay-automation/PHASE-4A-SCOPE.md:26:   - `poll-relay.sh` fake taker → real `tick claim/ping/release/done`.
relay-automation/PHASE-4A-SCOPE.md:27:   - **NEW `test/watchdog-relay.sh`** — stalled `RELAY-TURN` (claim + stale heartbeat) → parked suspect → escalated. **The payoff test** ((a)'s reason for being).
relay-automation/PHASE-4A-SCOPE.md:32:**Original claim ~2.5 passes was rosy.** Codex's independent number, accepted:
relay-automation/PHASE-4A-SCOPE.md:37:- **Revised: ~3.5 passes / ~4–5 hours.** Conversion work, no new core (the `tick` primitive + handoff-exclusive rule are verified sufficient), but the relay poll/supervisor/**test** contract all move off `NEXT`/`sed` together — that's the cost. Biggest risk = exactly that rewrite, not the `tick release --to` primitive.
relay-automation/PHASE-4A-SCOPE.md:40:1. **Token/verdict split** — termination reads the file's `STATUS` while the token is tick; getting handoff-vs-terminate clean (release on continue, done on approve) without the two fighting.
relay-automation/PHASE-4A-SCOPE.md:41:2. ~~**`release`/`done` semantics on `RELAY-TURN`**~~ **RESOLVED (Codex):** `release`/`done`/`ping` are ownership-guarded append-only events and projection already re-opens/re-targets a repeatedly handed-off task correctly (`src/scope.js:34-37,46-61`, `src/project.js:45-54,90-100`). Not a runtime risk — just needs the **multi-turn integration test** (now scope item 6).
relay-automation/PHASE-4A-SCOPE.md:42:3. **Test-harness tick ops (THE time sink, confirmed)** — both fake turn-takers + poll-driver fixtures move off `sed`/`NEXT` onto real `tick claim/ping/release/done`. Codex priced this as a full slice, not an add-on.
test/handoff-exclusive.sh:2:# Proves A1 rule: a task handed off to a specific agent cannot be claimed or taken by another.
test/handoff-exclusive.sh:6:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 1 --paths "src/auth/**" >/dev/null
test/handoff-exclusive.sh:8:# Alice claims and hands off to bob
test/handoff-exclusive.sh:9:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/handoff-exclusive.sh:10:TICK_TS=2026-05-04T10:00:02.000Z tick_a release TASK-007 --agent alice --to bob >/dev/null
test/handoff-exclusive.sh:12:# Now Charlie tries to claim it directly
test/handoff-exclusive.sh:14:CLAIM_OUT=$(TICK_TS=2026-05-04T10:00:03.000Z tick_b claim TASK-007 --agent charlie --paths "src/auth/**" 2>&1)
test/handoff-exclusive.sh:17:  pass "wrong-handoff_to claim is refused"
test/handoff-exclusive.sh:19:  fail "expected wrong-handoff claim to be refused, got: $CLAIM_OUT"
test/handoff-exclusive.sh:24:  pass "wrong-handoff claim emitted ZERO events"
test/handoff-exclusive.sh:44:# POSITIVE ROUTED CASE — claim: the task reserved for bob (TASK-007) is claimed by bob (handoff_to == caller).
test/handoff-exclusive.sh:45:CLAIM_BOB=$(TICK_TS=2026-05-04T10:00:05.000Z tick_b claim TASK-007 --agent bob --paths "src/auth/**" 2>&1)
test/handoff-exclusive.sh:47:  pass "handoff target (bob) can claim the task routed to it"
test/handoff-exclusive.sh:49:  fail "expected bob to claim TASK-007 via handoff routing, got: $CLAIM_BOB"
test/handoff-exclusive.sh:53:# (TASK-007 is now claimed by bob, so the only open bob-handoff is TASK-008 → unambiguous.)
test/handoff-exclusive.sh:54:TICK_TS=2026-05-04T10:00:06.000Z tick_a log task.created TASK-008 --agent dispatcher --priority 1 --paths "src/api/**" >/dev/null
test/handoff-exclusive.sh:55:TICK_TS=2026-05-04T10:00:07.000Z tick_a claim TASK-008 --agent alice --paths "src/api/**" >/dev/null
test/handoff-exclusive.sh:56:TICK_TS=2026-05-04T10:00:08.000Z tick_a release TASK-008 --agent alice --to bob >/dev/null
src/events.js:9:  'task.created',
src/events.js:10:  'task.claimed',
src/events.js:11:  'task.released',
src/events.js:15:  'task.done',
src/events.js:23:  'marathon.phase.start',
src/events.js:24:  'marathon.phase.approved',
src/events.js:25:  'marathon.phase.escalated',
src/events.js:26:  'marathon.phase.revision',
src/events.js:31:  'task.claimed',
src/events.js:33:  'task.released',
src/events.js:35:  'task.done',
test/chaos-concurrent-pollers.sh:2:# Concurrent-poller safety: two pollers race to claim the same available turn
test/chaos-concurrent-pollers.sh:3:# token. The O_EXCL claim lock serialises them — exactly one wins, the other
test/chaos-concurrent-pollers.sh:14:  # Seed exactly one claimable task for this trial.
test/chaos-concurrent-pollers.sh:15:  tick_a log task.created "$TASK" --agent dispatcher --priority 10 \
test/chaos-concurrent-pollers.sh:21:  # Launch two concurrent claimers as background subshells — a genuine race.
test/chaos-concurrent-pollers.sh:23:  tick_a claim "$TASK" --agent poller-a --paths "src/chaos/**" >"$OUT_A" 2>&1 &
test/chaos-concurrent-pollers.sh:24:  tick_a claim "$TASK" --agent poller-b --paths "src/chaos/**" >"$OUT_B" 2>&1 &
test/chaos-concurrent-pollers.sh:39:  # Release the winning claim so the next trial starts with a clean cap.
test/chaos-concurrent-pollers.sh:40:  tick_a done "$TASK" --agent "$WINNER" >/dev/null 2>&1
test/chaos-concurrent-pollers.sh:41:done
relay-automation/PHASE-5-PLAN.md:30:`handoff-to` routing from `src/claim.js`/`src/take.js`). So: ship the 4 relay
relay-automation/PHASE-5-PLAN.md:33:wrong-`handoff_to` claim with **zero** events) — apply/verify the Phase-1 patch if
relay-automation/codex-turn.sh:10:#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
relay-automation/codex-turn.sh:14:#   RELAY_PEER      — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
relay-automation/codex-turn.sh:47:prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
test/projection-idempotent.sh:6:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-001 --agent dispatcher --priority 10 --paths "src/foo/**" >/dev/null
test/projection-idempotent.sh:7:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-002 --agent dispatcher --priority 5 --paths "src/bar/**" >/dev/null
test/projection-idempotent.sh:8:TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.claimed TASK-001 --agent alice --paths "src/foo/**" >/dev/null
relay-automation/claude-turn.sh:14:#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
relay-automation/claude-turn.sh:18:#   RELAY_PEER        — optional: the other agent's id, for explicit --to <peer> handoff
relay-automation/claude-turn.sh:66:prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
relay-automation/claude-turn.sh:108:  done
relay-automation/PHASE-4-PLAN.md:13:> claimability (the file's `STATUS` is the terminal signal only); the Phase-1 rule + Phase-2
relay-automation/PHASE-4-PLAN.md:34:- **xyz mode** — runnable state is `tick`-native (an in-lane task claimable/resumable by me).
relay-automation/PHASE-4-PLAN.md:44:   - xyz turn → scope = the claimed task's paths from `tick info <task>`: `git status --porcelain -- <task-paths>`.
relay-automation/PHASE-4-PLAN.md:54:- **(4a) xyz build turn** — poll claims the next in-lane task and runs `runner.sh`; the existing Phase-1/3 mechanics handle claim exclusivity + verdict. Removes the "your turn" nudge between build turns.
test/analyze.sh:3:# when the git transport was stripped). Drift/unclaimed detection is deferred.
test/analyze.sh:7:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-001 --agent dispatcher --priority 10 --paths "src/auth/**"    >/dev/null
test/analyze.sh:8:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-002 --agent dispatcher --priority  5 --paths "src/billing/**" >/dev/null
test/analyze.sh:9:TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-003 --agent dispatcher --priority  1 --paths "src/poison/**"  >/dev/null
test/analyze.sh:11:# alice: claims TASK-001 at 10:01, done at 10:15.
test/analyze.sh:12:# bob:   claims TASK-002 at 10:05 (overlaps alice's window), done at 10:30.
test/analyze.sh:13:# → concurrent-claim window = 10:05-10:15 (10 min out of ~40 min run window).
test/analyze.sh:14:TICK_TS=2026-05-04T10:01:00.000Z tick_a claim TASK-001 --agent alice --paths "src/auth/**"    >/dev/null
test/analyze.sh:15:TICK_TS=2026-05-04T10:05:00.000Z tick_b claim TASK-002 --agent bob   --paths "src/billing/**" >/dev/null
test/analyze.sh:16:TICK_TS=2026-05-04T10:15:00.000Z tick_a done  TASK-001 --agent alice                          >/dev/null
test/analyze.sh:17:TICK_TS=2026-05-04T10:30:00.000Z tick_b done  TASK-002 --agent bob                            >/dev/null
test/analyze.sh:19:# alice: claims and breaks TASK-003 at 10:40-10:41.
test/analyze.sh:20:TICK_TS=2026-05-04T10:40:00.000Z tick_a claim TASK-003 --agent alice --paths "src/poison/**" >/dev/null
test/analyze.sh:31:echo "$HUMAN" | grep -q "claimed:3" \
test/analyze.sh:32:  && pass "event count: 3 claimed" \
test/analyze.sh:33:  || fail "expected claimed:3"
test/analyze.sh:35:echo "$HUMAN" | grep -q "done:2" \
test/analyze.sh:36:  && pass "event count: 2 done" \
test/analyze.sh:37:  || fail "expected done:2"
test/analyze.sh:44:echo "$HUMAN" | grep -A2 "\[alice\]" | grep -q "claims: 2, done: 1" \
test/analyze.sh:45:  && pass "alice: 2 claims, 1 done" \
test/analyze.sh:48:echo "$HUMAN" | grep -A2 "\[bob\]" | grep -q "claims: 1, done: 1" \
test/analyze.sh:49:  && pass "bob: 1 claim, 1 done" \
test/analyze.sh:52:# Concurrent-claim time: alice (10:01-10:15) overlaps bob (10:05-10:30).
test/analyze.sh:54:if echo "$HUMAN" | grep "concurrent-claim time" | grep -qE "\([1-9][0-9]*%\)"; then
test/analyze.sh:55:  pass "concurrent-claim time is non-zero (overlapping claim windows detected)"
test/analyze.sh:57:  fail "expected non-zero concurrent-claim time; got: $(echo "$HUMAN" | grep concurrent)"
src/marathon-yaml.js:113:  const done = new Set();
src/marathon-yaml.js:121:      if (!p.depends_on || done.has(p.depends_on)) {
src/marathon-yaml.js:123:        done.add(p.id);
test/marathon-yaml.sh:24:    name: claim-cap wiring
relay-automation/relay-turn-lib.sh:24:  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
relay-automation/relay-turn-lib.sh:26:  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
relay-automation/relay-turn-lib.sh:30:rtl_in_allow() { local x="$1" a; for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done; return 1; }
relay-automation/relay-turn-lib.sh:34:  # Name the peer explicitly when known — a live Gemini turn (2026-06-15) released the token to the
relay-automation/relay-turn-lib.sh:35:  # literal role "Producer" because "the other agent" was unnamed. RELAY_PEER closes that ambiguity.
relay-automation/relay-turn-lib.sh:36:  local handoff="release --to the other agent (the role named by NEXT in the file)"
relay-automation/relay-turn-lib.sh:37:  [[ -n "$peer" ]] && handoff="release --to ${peer}"
relay-automation/relay-turn-lib.sh:38:  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. Use ./bin/tick for the %s token (claim/ping, then %s, or done + set STATUS: Approved when approving). Edit ONLY %s%s. Do NOT run git (no add/commit/push) and do NOT touch any other file — the harness commits for you.' \
relay-automation/relay-turn-lib.sh:48:  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
relay-automation/relay-turn-lib.sh:54:  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
relay-automation/relay-turn-lib.sh:109:  done < <(git -C "$RTL_ROOT" status --porcelain -z)
test/watchdog-relay.sh:3:# is now a tick task, a claim with no heartbeat past the threshold is a parked
test/watchdog-relay.sh:10:# Stalled RELAY-TURN: claimed ~1h before the latest event, never pinged.
test/watchdog-relay.sh:11:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created RELAY-TURN --agent dispatcher >/dev/null
test/watchdog-relay.sh:12:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim RELAY-TURN --agent ra --paths "z/**" >/dev/null
test/watchdog-relay.sh:13:# Healthy RELAY-TURN-2: claimed close to the run-end (small gap → not parked).
test/watchdog-relay.sh:14:TICK_TS=2026-05-04T10:58:00.000Z tick_a log task.created RELAY-TURN-2 --agent dispatcher >/dev/null
test/watchdog-relay.sh:15:TICK_TS=2026-05-04T10:58:30.000Z tick_a claim RELAY-TURN-2 --agent rb --paths "y/**" >/dev/null
test/watchdog-relay.sh:17:TICK_TS=2026-05-04T11:00:00.000Z tick_a log task.created OTHER --agent dispatcher >/dev/null
test/gemini-turn.sh:23:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/gemini-turn.sh:26:"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
test/gemini-turn.sh:38:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to gemini >/dev/null; }
test/codex-turn.sh:16:# Stub `codex`: ignores its args; performs a real turn as $RELAY_AGENT — claim/ping the
test/codex-turn.sh:17:# token, append a block to $RELAY_FILE, release to claude-a. STUB_MODE=bad also writes an
test/codex-turn.sh:25:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/codex-turn.sh:28:"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
test/codex-turn.sh:45:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }
test/heartbeat.sh:3:# and `tick analyze` flags a claim window with no heartbeat for longer than the
test/heartbeat.sh:4:# parked-claim threshold (10 min) as a parked-claim suspect — the work-activity
test/heartbeat.sh:9:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-1 --agent dispatcher --priority 10 --paths "src/http/**" >/dev/null
test/heartbeat.sh:10:TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created TASK-2 --agent dispatcher --priority 10 --paths "src/store/**" >/dev/null
test/heartbeat.sh:12:# alice claims both (cross-half, within the cap of 2).
test/heartbeat.sh:13:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/http/**" >/dev/null
test/heartbeat.sh:14:TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/store/**" >/dev/null
test/heartbeat.sh:16:# Ownership guard: a non-claimer cannot heartbeat the task.
test/heartbeat.sh:32:# Close both windows. TASK-1: claimed 10:00:01, beat 10:05:01, done 10:08:01
test/heartbeat.sh:33:# (max gap 5m < 10m → healthy). TASK-2: claimed 10:00:02, NO beats, done
test/heartbeat.sh:35:TICK_TS=2026-05-04T10:08:01.000Z tick_a done TASK-1 --agent alice >/dev/null
test/heartbeat.sh:36:TICK_TS=2026-05-04T10:20:02.000Z tick_a done TASK-2 --agent alice >/dev/null
test/heartbeat.sh:42:  pass "analyze flags only the heartbeat-less claim as parked (TASK-2)"
test/heartbeat.sh:51:  pass "heartbeat-covered claim window is not flagged parked"
test/skill-extract.sh:19:for f in $want; do [ -f "$D/$f" ] || { echo "  missing: $f" >&2; miss=1; }; done
test/skill-extract.sh:23:for s in "$D"/relay-automation/*.sh "$D"/test/*.sh; do bash -n "$s" 2>/dev/null || { echo "  parse fail: $s" >&2; ok=0; }; done
relay-automation/README.md:20:| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
relay-automation/README.md:38:  instructions (review/produce, append your block, `tick release RELAY-TURN --to <other>` or
relay-automation/README.md:39:  `done` on approve, commit, push); otherwise do nothing.
relay-automation/README.md:42:**Whose-turn is the `RELAY-TURN` tick task** (handed off via `tick release --to`), so the
relay-automation/README.md:44:a window acts only when the token is claimable by **its** agent **and** the artifact scope is
test/path-overlap.sh:2:# AC #2: agent-A claims TASK-007 with paths src/auth/**.
test/path-overlap.sh:8:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 5  --paths "src/auth/**" >/dev/null
test/path-overlap.sh:9:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-008 --agent dispatcher --priority 99 --paths "src/auth/login.js" >/dev/null
test/path-overlap.sh:10:TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-009 --agent dispatcher --priority 1  --paths "src/billing/**" >/dev/null
test/path-overlap.sh:11:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/path-overlap.sh:18:  fail "bob got TASK-008 even though it overlaps src/auth/** claimed by alice"
test/claude-turn.sh:16:# performs a real turn as $RELAY_AGENT — claim/ping the token, append a block, release.
test/claude-turn.sh:29:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/claude-turn.sh:32:"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to gemini >/dev/null 2>&1
test/claude-turn.sh:54:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }
test/scope-change.sh:2:# AC #3: alice claims with src/auth/** then `tick scope` to add src/middleware/**.
test/scope-change.sh:7:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 5  --paths "src/auth/**" >/dev/null
test/scope-change.sh:8:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-010 --agent dispatcher --priority 50 --paths "src/middleware/**" >/dev/null
test/scope-change.sh:9:TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-011 --agent dispatcher --priority 1  --paths "src/billing/**" >/dev/null
test/scope-change.sh:10:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/marathon-drive.sh:110:# marathon.phase.approved event emitted (check events dir directly)
test/marathon-drive.sh:111:ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.phase.approved" \
test/marathon-drive.sh:112:  && pass "marathon.phase.approved event emitted" \
test/marathon-drive.sh:113:  || fail "marathon.phase.approved not found in tick events"
test/marathon-drive.sh:193:while (($# > 0)); do case "$1" in --agent-cmd) acmd="${2:-}"; shift 2 ;; *) shift ;; esac; done
test/marathon-drive.sh:211:# (a) the artifact path is baked into the relay and the tick claim --paths includes it
test/marathon-drive.sh:216:  && pass "tick claim --paths includes relay + artifact" || fail "claim --paths should declare the artifact"
test/auto-sync.sh:3:# This test verifies the O_EXCL claim lock: concurrent shell-level claim calls
test/auto-sync.sh:8:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-L1 --agent dispatcher --priority 10 --paths "src/lock/**" >/dev/null
test/auto-sync.sh:9:TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-L2 --agent dispatcher --priority  8 --paths "src/other/**" >/dev/null
test/auto-sync.sh:11:# Fire two claim attempts in parallel; lock serialises them.
test/auto-sync.sh:13:# ("another tick claim in progress"), not a "lost:" on stdout.
test/auto-sync.sh:14:tick_a claim TASK-L1 --agent alice --paths "src/lock/**" >"$WORK/a.out" 2>&1 &
test/auto-sync.sh:15:tick_b claim TASK-L1 --agent bob   --paths "src/lock/**" >"$WORK/b.out" 2>&1 &
test/auto-sync.sh:24:is_loser()  { echo "$1" | grep -qE "^lost:|another tick claim is in progress"; }
test/auto-sync.sh:33:[ "$WINS" = "1" ]   && pass "exactly one agent won the concurrent claim" \
test/auto-sync.sh:35:[ "$LOSSES" = "1" ] && pass "exactly one agent lost the concurrent claim" \
test/auto-sync.sh:38:# Exactly one task.claimed event must exist for TASK-L1 (no double-write).
test/auto-sync.sh:40:  | xargs grep -l '"type":"task.claimed"' 2>/dev/null | wc -l | tr -d ' ')
test/auto-sync.sh:42:  && pass "exactly one task.claimed event written (lock integrity)" \
test/auto-sync.sh:43:  || fail "expected 1 claimed event for TASK-L1, got $CLAIMED_COUNT"
test/auto-sync.sh:47:pass "projection succeeded after concurrent claims (no corrupted state)"
test/_setup.sh:57:done
test/take.sh:2:# Run 3: `tick take --agent <id>` is the atomic next+claim verb that replaced the
test/take.sh:3:# `tick next` + `tick claim` two-step (closing the TOCTOU race). This test covers
test/take.sh:4:# the two properties the Run 3 plan gates on — atomic selection+claim, and the
test/take.sh:5:# same-half double-claim refusal — plus the claim cap and cross-agent lane
test/take.sh:10:TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-A1 --agent dispatcher --priority 10 --paths "src/http/**" >/dev/null
test/take.sh:11:TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created TASK-A2 --agent dispatcher --priority 8  --paths "src/http/**" >/dev/null
test/take.sh:12:TICK_TS=2026-05-04T10:00:00.200Z tick_a log task.created TASK-B1 --agent dispatcher --priority 5  --paths "src/store/**" >/dev/null
test/take.sh:14:# 1. Atomic next+claim: take selects the highest-priority available task AND
test/take.sh:15:#    claims it in one call. The claim event must exist immediately after.
test/take.sh:22:CLAIMED=$(ls "$A/.tick/events/" | grep -c "alice-claimed-TASK-A1" || true)
test/take.sh:24:  pass "take atomically emitted the task.claimed event"
test/take.sh:26:  fail "expected 1 alice-claimed-TASK-A1 event, got $CLAIMED"
test/take.sh:29:# 2. Same-half double-claim refusal + cross-half allowed: alice already holds the
test/take.sh:30:#    http lane (A1). Her next take must SKIP A2 (http, overlaps her own claim)
test/take.sh:39:  fail "take handed alice TASK-A2, which overlaps her own active claim"
test/take.sh:47:if grep -q "claim limit reached" "$WORK/t3.out"; then
test/take.sh:48:  pass "take enforces the per-agent claim cap (2)"
test/take.sh:50:  fail "take did not enforce the claim cap: $(cat "$WORK/t3.out")"
test/take.sh:54:#    A1 claim — so bob gets nothing rather than colliding into the http lane.
test/take.sh:57:  pass "take keeps a second agent out of a lane already claimed by the first"
test/cost.sh:80:# Two done coordination tasks (REG-1 by alpha, REG-2 by beta).
test/cost.sh:81:p2 log task.created REG-1 --agent dispatcher >/dev/null; p2 claim REG-1 --agent alpha --paths "x/**" >/dev/null; p2 done REG-1 --agent alpha >/dev/null
test/cost.sh:82:p2 log task.created REG-2 --agent dispatcher >/dev/null; p2 claim REG-2 --agent beta  --paths "y/**" >/dev/null; p2 done REG-2 --agent beta  >/dev/null
test/cost.sh:98:# REG-1 instrumented (5/5), REG-2 not -> 1 of 2 done-tasks instrumented => PARTIAL floor.
test/cost.sh:101:[ "$(p2j cost.tokens.partial)" = "true" ]        && pass "partial flag true (1/2 done-tasks instrumented)" || fail "partial should be true"
test/cost.sh:102:[ "$(p2j cost.tokens.coverage)" = "1/2" ]        && pass "coverage reads 1/2 (done-tasks)" || fail "coverage=$(p2j cost.tokens.coverage)"
test/cost.sh:103:[ "$(p2j cost.per_unit.tokens_per_done)" = "5" ] && pass "tokens_per_done = 10/2 = 5 (floor)" || fail "per-done=$(p2j cost.per_unit.tokens_per_done)"

exec
/bin/zsh -lc 'nl -ba relay-automation/relay-turn-lib.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# relay-turn-lib.sh — shared, model-AGNOSTIC safety core for headless relay turn-takers.
     3	# SOURCED by codex-turn.sh and gemini-drive.sh (thin dispatch wrappers); not run on its own.
     4	#
     5	# Containment contract — decisions/2026-06-15-unattended-agent-containment.md (3-model validated):
     6	#   (1) path-allowlist      — revert + FAIL on any change outside {relay file, ALLOW_PATHS}
     7	#   (2) commit-bypass guard — reset --hard + FAIL if the agent committed during its own turn
     8	#   (3) no push             — stage only the allowlist, commit file-scoped, never push
     9	# Keeping this in ONE place means a new turn-taker (gemini-drive.sh, …) inherits the exact
    10	# boundary instead of reimplementing it — reimplementation is where a fourth bypass sneaks in.
    11	#
    12	# API (all state in namespaced RTL_* globals):
    13	#   rtl_init        <root> <relay_file> <allow_csv>   — set ROOT + build normalized allowlist
    14	#   rtl_turn_prompt <agent> <relay_file> <task> <csv> — emit the shared ▶ TAKE-YOUR-TURN prompt
    15	#   rtl_before                                         — snapshot HEAD before the agent runs
    16	#   rtl_enforce     <task> <agent> <log> <tool>        — guards (2)+(1)+(3); EXITS 6 on violation
    17	#
    18	# rtl_enforce deliberately `exit 6`s the calling shell on any violation — that fails the turn.
    19	
    20	rtl_init() {  # <root> <relay_file> <allow_csv>
    21	  RTL_ROOT="$1"; local f="$2" csv="$3"
    22	  RTL_ALLOW=("$f")
    23	  local _extra p; IFS=',' read -ra _extra <<<"$csv"
    24	  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
    25	  local _n=() a                       # normalize to repo-root-relative (git status emits relative)
    26	  for a in "${RTL_ALLOW[@]}"; do _n+=("${a#"$RTL_ROOT"/}"); done
    27	  RTL_ALLOW=("${_n[@]}")
    28	}
    29	
    30	rtl_in_allow() { local x="$1" a; for a in "${RTL_ALLOW[@]}"; do [[ "$x" == "$a" ]] && return 0; done; return 1; }
    31	
    32	rtl_turn_prompt() {  # <agent> <relay_file> <task> <allow_csv> [peer]
    33	  local agent="$1" f="$2" task="$3" csv="$4" peer="${5:-}"
    34	  # Name the peer explicitly when known — a live Gemini turn (2026-06-15) released the token to the
    35	  # literal role "Producer" because "the other agent" was unnamed. RELAY_PEER closes that ambiguity.
    36	  local handoff="release --to the other agent (the role named by NEXT in the file)"
    37	  [[ -n "$peer" ]] && handoff="release --to ${peer}"
    38	  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. Use ./bin/tick for the %s token (claim/ping, then %s, or done + set STATUS: Approved when approving). Edit ONLY %s%s. Do NOT run git (no add/commit/push) and do NOT touch any other file — the harness commits for you.' \
    39	    "$agent" "$f" "$task" "$handoff" "$f" "${csv:+ and: $csv}"
    40	}
    41	
    42	rtl_before() {
    43	  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
    44	  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
    45	  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
    46	  RTL_BEFORE=()
    47	  local fld
    48	  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
    49	    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
    50	}
    51	
    52	rtl_was_dirty_before() {  # <porcelain-entry> — true if this exact status+path was dirty pre-turn
    53	  local e="$1" b
    54	  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
    55	  return 1
    56	}
    57	
    58	rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
    59	  local p="$1"
    60	  [[ -n "$p" ]] || return 0
    61	  # tick's own state dir is coordination state the turn legitimately writes — exempt it intrinsically,
    62	  # independent of whether the HOST repo gitignores .tick (field report MBP16 [2]).
    63	  case "$p" in .tick/*|.tick) return 0 ;; esac
    64	  # the shim's own transcript log, if it lands in the tree, is not an agent edit — drop it, don't flag
    65	  if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
    66	  rtl_in_allow "$p" && return 0
    67	  printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
    68	  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
    69	  RTL_VIOLATION=1
    70	}
    71	
    72	rtl_enforce() {  # <task> <agent> <log> <tool>
    73	  local task="$1" agent="$2" log="$3"; RTL_TOOL="$4"
    74	  # (2) commit-bypass guard: the agent must NOT git. If HEAD moved, its edits are hidden from
    75	  # `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
    76	  if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
    77	    git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
    78	    printf '%s-turn: %s committed during its turn (forbidden) — reset to %s, failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
    79	    exit 6
    80	  fi
    81	  # (1) allowlist enforcement on tracked-tree changes (.tick is gitignored, so token ops don't show).
    82	  # -z = NUL-delimited RAW unquoted paths (spaces/special chars can't slip the match or break the
    83	  # revert); rename/copy records (R/C) carry a second NUL field — check both old+new. We deliberately
    84	  # do NOT `git clean -Xdf` (it would wipe .tick, the coordination state the turn legitimately writes);
    85	  # ignored-file safety belongs to the agent sandbox, tracked as future.
    86	  RTL_LOG_REL="${log:+${log#"$RTL_ROOT"/}}"
    87	  RTL_VIOLATION=0
    88	  # Pre-existing ambient WIP (same status+path as before the turn) is left untouched, never failed.
    89	  # (Documented minor gap: a file already dirty that the agent edits further to the SAME status code
    90	  # isn't caught — acceptable for review turns.)
    91	  local entry xy path src
    92	  while IFS= read -r -d '' entry; do
    93	    [[ -n "$entry" ]] || continue
    94	    xy="${entry:0:2}"; path="${entry:3}"
    95	    case "$xy" in
    96	      R*|C*)
    97	        IFS= read -r -d '' src || true
    98	        # A rename counts as pre-existing only if BOTH dest and src were dirty before — else enforce
    99	        # both paths. Prevents a staged rename whose dest matches an ambient rename's dest from hiding
   100	        # a clean file's move/deletion via the src field (Gemini review 2026-06-15, rename-hijack).
   101	        if rtl_was_dirty_before "$entry" && rtl_was_dirty_before "$src"; then continue; fi
   102	        rtl_check "$path"; rtl_check "$src"
   103	        ;;
   104	      *)
   105	        rtl_was_dirty_before "$entry" && continue
   106	        rtl_check "$path"
   107	        ;;
   108	    esac
   109	  done < <(git -C "$RTL_ROOT" status --porcelain -z)
   110	  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; exit 6; }
   111	  # (3) stage ONLY the allowlist; commit file-scoped; NO push.
   112	  git -C "$RTL_ROOT" add -- "${RTL_ALLOW[@]}" 2>/dev/null || true
   113	  if git -C "$RTL_ROOT" diff --cached --quiet; then
   114	    printf '%s-turn: %s turn produced no tracked changes (token-only move?)\n' "$RTL_TOOL" "$agent"
   115	  else
   116	    git -C "$RTL_ROOT" commit -q -m "relay(${task}): ${agent} turn (${RTL_TOOL} headless; no push)"
   117	    printf '%s-turn: committed %s turn (file-scoped, no push)\n' "$RTL_TOOL" "$agent"
   118	  fi
   119	}

codex
The relay runtime does thread `RELAY_PEER`; I’m checking whether the new marathon boundary events and clean-tree assumptions are consistent with the lower-level contracts, and whether the unit suite actually exercises those edges.
exec
/bin/zsh -lc "nl -ba src/events.js | sed -n '1,120p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc "nl -ba relay-automation/codex-turn.sh | sed -n '1,160p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc "nl -ba relay-automation/claude-turn.sh | sed -n '1,160p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# codex-turn.sh — headless turn-taker for the CODEX agent. Thin dispatch wrapper over the
     5	# shared safety core (relay-turn-lib.sh); the containment contract lives there.
     6	#
     7	# Invoked by relay-drive.sh as --agent-cmd, with env:
     8	#   RELAY_FILE  — relay thread file (always allowlisted)
     9	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    10	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    11	# Shim config:
    12	#   CODEX_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CODEX_AGENT
    13	#   ALLOW_PATHS     — comma-separated extra git paths the turn may change (e.g. the artifact)
    14	#   RELAY_PEER      — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
    15	#                     prompt says "the other agent", which a live model may resolve to a role name)
    16	#   CODEX_BIN       — codex binary (default: codex); tests inject a stub
    17	#   CODEX_FLAGS     — autonomy flags for `codex exec` (default: -s workspace-write). On a fresh device
    18	#                     whose ~/.codex/config.toml still prompts/blocks writes, the turn produces no
    19	#                     changes (field report MBP16 [3]); escalate with e.g.
    20	#                     CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' or add -c approval_policy=never.
    21	#   CODEX_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
    22	#   CODEX_LOG       — where to write the codex transcript (default: stderr)
    23	#
    24	# Exit: 0 acted/deferred · 5 codex failed · 6 off-allowlist edit (reverted) · 2 usage.
    25	
    26	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    27	# shellcheck source=relay-turn-lib.sh
    28	source "$HERE/relay-turn-lib.sh"
    29	
    30	ROOT="${CODEX_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    31	CODEX_BIN="${CODEX_BIN:-codex}"
    32	die() { printf 'codex-turn: %s\n' "$*" >&2; exit 2; }
    33	
    34	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
    35	codex_agent="${CODEX_AGENT:-}"
    36	[[ -n "$me" ]] || die "RELAY_AGENT required"
    37	[[ -n "$f" ]] || die "RELAY_FILE required"
    38	[[ -n "$codex_agent" ]] || die "CODEX_AGENT required"
    39	
    40	# Dispatch only for the Codex agent; defer otherwise (that window drives its own turn).
    41	if [[ "$me" != "$codex_agent" ]]; then
    42	  printf 'codex-turn: actor %s is not the Codex agent (%s) — deferring (window-driven)\n' "$me" "$codex_agent" >&2
    43	  exit 0
    44	fi
    45	
    46	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
    47	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
    48	
    49	# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
    50	# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
    51	# read-only); operator-overridable for tighter/looser policies.
    52	read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write}"
    53	# Transcript: default to a $TMPDIR file (NOT the repo tree — the in-tree log guard deletes it).
    54	# Persists the transcript so the headless run is auditable. (Codex token-stats parsing is a follow-up
    55	# — its usage format isn't probed yet, so cost.tokens for Codex turns stays a Phase-1 partial.)
    56	CODEX_LOG="${CODEX_LOG:-${TMPDIR:-/tmp}/codex-turn-$$.log}"
    57	rtl_before
    58	"$CODEX_BIN" exec "${_cflags[@]}" "$prompt" < /dev/null > "$CODEX_LOG" 2>&1 \
    59	  || { printf 'codex-turn: codex exec failed\n' >&2; exit 5; }
    60	rtl_enforce "$t" "$me" "$CODEX_LOG" "codex"

 succeeded in 0ms:
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	
     6	const SCHEMA_VERSION = '0.1.0';
     7	
     8	const EVENT_TYPES = new Set([
     9	  'task.created',
    10	  'task.claimed',
    11	  'task.released',
    12	  'task.scope_changed',
    13	  'task.commented',
    14	  'task.heartbeat',
    15	  'task.done',
    16	  'task.circuit_break',
    17	  // Cost signals (Phase 1, COST-OBSERVABILITY-PLAN). Deterministic, additive, ignored by the
    18	  // coordination metrics — they describe what a turn COST, not how it coordinated.
    19	  'cost.tokens',
    20	  'cost.human',
    21	  // Marathon phase-chain signals (Phase 3, marathon-drive.sh). Emitted at phase boundaries by
    22	  // marathon-drive, not by individual turn-takers. Not coordination signals — ignored by tick analyze.
    23	  'marathon.phase.start',
    24	  'marathon.phase.approved',
    25	  'marathon.phase.escalated',
    26	  'marathon.phase.revision',
    27	  'marathon.complete',
    28	]);
    29	
    30	const CRITICAL_EVENTS = new Set([
    31	  'task.claimed',
    32	  'task.scope_changed',
    33	  'task.released',
    34	  'task.circuit_break',
    35	  'task.done',
    36	]);
    37	
    38	function eventsDir(repoRoot) {
    39	  return path.join(repoRoot, '.tick', 'events');
    40	}
    41	
    42	function ensureEventsDir(repoRoot) {
    43	  fs.mkdirSync(eventsDir(repoRoot), { recursive: true });
    44	}
    45	
    46	function isoNow() {
    47	  if (process.env.TICK_TS) return process.env.TICK_TS;
    48	  return new Date().toISOString();
    49	}
    50	
    51	function tsForFilename(iso) {
    52	  return iso.replace(/:/g, '-');
    53	}
    54	
    55	function safeSegment(s) {
    56	  return String(s).replace(/[^A-Za-z0-9._-]/g, '_');
    57	}
    58	
    59	function appendEvent(repoRoot, {
    60	  type, task, agent, note, paths, to_agent, reason, priority,
    61	  tokens_in, tokens_out, tokens_total, human_minutes, tool,
    62	}) {
    63	  if (!EVENT_TYPES.has(type)) {
    64	    throw new Error(`unknown event type: ${type}`);
    65	  }
    66	  if (!task) throw new Error('task is required');
    67	  if (!agent) throw new Error('agent is required');
    68	
    69	  ensureEventsDir(repoRoot);
    70	
    71	  const ts = isoNow();
    72	  const action = type.replace(/^(task|cost)\./, '');
    73	  const fname = `${tsForFilename(ts)}-${safeSegment(agent)}-${safeSegment(action)}-${safeSegment(task)}.jsonl`;
    74	  const fpath = path.join(eventsDir(repoRoot), fname);
    75	
    76	  const event = {
    77	    schema_version: SCHEMA_VERSION,
    78	    ts,
    79	    type,
    80	    task,
    81	    agent,
    82	  };
    83	  if (paths) event.paths = paths;
    84	  if (note !== undefined) event.note = note;
    85	  if (to_agent) event.to_agent = to_agent;
    86	  if (reason !== undefined) event.reason = reason;
    87	  if (priority !== undefined) event.priority = priority;
    88	  // Cost fields — only stamped when present, so non-cost events stay byte-identical to before.
    89	  if (tokens_in !== undefined) event.tokens_in = tokens_in;
    90	  if (tokens_out !== undefined) event.tokens_out = tokens_out;
    91	  if (tokens_total !== undefined) event.tokens_total = tokens_total;
    92	  if (human_minutes !== undefined) event.human_minutes = human_minutes;
    93	  if (tool !== undefined) event.tool = tool;
    94	
    95	  fs.writeFileSync(fpath, JSON.stringify(event) + '\n');
    96	  return { path: fpath, event };
    97	}
    98	
    99	function readAllEvents(repoRoot) {
   100	  const dir = eventsDir(repoRoot);
   101	  if (!fs.existsSync(dir)) return [];
   102	  const files = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl')).sort();
   103	  return files.map(f => {
   104	    const raw = fs.readFileSync(path.join(dir, f), 'utf8').trim();
   105	    const ev = JSON.parse(raw);
   106	    ev._file = f;
   107	    return ev;
   108	  });
   109	}
   110	
   111	module.exports = {
   112	  SCHEMA_VERSION,
   113	  EVENT_TYPES,
   114	  CRITICAL_EVENTS,
   115	  appendEvent,
   116	  readAllEvents,
   117	  eventsDir,
   118	  ensureEventsDir,
   119	  isoNow,
   120	};

exec
/bin/zsh -lc "nl -ba test/marathon-drive.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# claude-turn.sh — headless turn-taker for the CLAUDE builder agent. Thin dispatch wrapper over the
     5	# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh and
     6	# gemini-turn.sh (decisions/2026-06-15-unattended-agent-containment.md).
     7	#
     8	# Builder role: Claude is the PRODUCER (write/revise the artifact). Reviewers (Codex, Gemini) use
     9	# the tighter "Bash,Read" allowlist — no Write surface; rtl_enforce is the real guard regardless.
    10	#
    11	# Invoked by relay-drive.sh as --agent-cmd (typically via marathon-agent.sh), with env:
    12	#   RELAY_FILE  — relay thread file (always allowlisted)
    13	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    14	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    15	# Shim config:
    16	#   CLAUDE_AGENT      — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CLAUDE_AGENT
    17	#   ALLOW_PATHS       — comma-separated extra git paths the turn may change (the artifact being built)
    18	#   RELAY_PEER        — optional: the other agent's id, for explicit --to <peer> handoff
    19	#   CLAUDE_BIN        — claude CLI binary or wrapper (default: claude); tests inject a stub.
    20	#   CLAUDE_MODEL      — model to PIN via --model (default: claude-sonnet-4-6). Without this the
    21	#                       headless turn inherits the operator's ambient model — an Opus session blew
    22	#                       the budget cap mid-build on 2026-06-18. Pin it so cost is deterministic.
    23	#   CLAUDE_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture
    24	#   CLAUDE_LOG        — where to write the claude transcript JSON (default: $TMPDIR/claude-turn-$$.json)
    25	#   CLAUDE_MAX_TURNS  — max turns passed to --max-turns (default: 20; size from spike output)
    26	#   CLAUDE_MAX_BUDGET — max cost passed to --max-budget-usd (default: 2.00; size from spike output)
    27	#   CLAUDE_BLOCK_CMDS — space-separated commands PATH-shadowed (blocked) for the builder's claude -p
    28	#                       subprocess only (default: codex gemini consult consult.sh marathon-drive.sh
    29	#                       relay-drive.sh). Stops an off-task builder from spawning external models /
    30	#                       recursive marathons. Set empty to disable. (Phase 3.6; not airtight — an
    31	#                       absolute-path call bypasses it; worktree isolation is the airtight follow-up.)
    32	#
    33	# Auth: `claude -p` inherits the credentials stored by `claude login` (~/.claude/). A subscription
    34	# login is sufficient — no API key needed. The binary must be installed and authenticated before
    35	# running headless turns. JSON output schema (--output-format json): usage.{input_tokens,
    36	# cache_read_input_tokens,output_tokens}, total_cost_usd, duration_ms, num_turns.
    37	#
    38	# Tool allowlist split:
    39	#   builder (this shim)                   → "Bash,Read,Edit,Write"  (needs to mutate the artifact)
    40	#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
    41	# rtl_enforce is the real guard either way; the allowlist is a second, tighter layer.
    42	#
    43	# Exit: 0 acted/deferred · 5 claude failed · 6 off-allowlist edit (reverted) · 2 usage.
    44	
    45	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    46	# shellcheck source=relay-turn-lib.sh
    47	source "$HERE/relay-turn-lib.sh"
    48	
    49	ROOT="${CLAUDE_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    50	CLAUDE_BIN="${CLAUDE_BIN:-claude}"
    51	die() { printf 'claude-turn: %s\n' "$*" >&2; exit 2; }
    52	
    53	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
    54	claude_agent="${CLAUDE_AGENT:-}"
    55	[[ -n "$me" ]] || die "RELAY_AGENT required"
    56	[[ -n "$f" ]] || die "RELAY_FILE required"
    57	[[ -n "$claude_agent" ]] || die "CLAUDE_AGENT required"
    58	
    59	# Dispatch only for the Claude agent; defer otherwise (that window drives its own turn).
    60	if [[ "$me" != "$claude_agent" ]]; then
    61	  printf 'claude-turn: actor %s is not the Claude agent (%s) — deferring (window-driven)\n' "$me" "$claude_agent" >&2
    62	  exit 0
    63	fi
    64	
    65	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
    66	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
    67	
    68	# Transcript: $TMPDIR file, NOT the repo tree (the in-tree log guard deletes it).
    69	# JSON format required: the cost block (usage.input_tokens / total_cost_usd / duration_ms)
    70	# is only emitted with --output-format json.
    71	CLAUDE_LOG="${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}"
    72	
    73	# Model pin: `claude -p` otherwise inherits the operator's AMBIENT model (whatever the interactive
    74	# session / global config selects). A headless builder must pin its own model, or its cost is
    75	# hostage to that ambient choice — a real smoke run on 2026-06-18 inherited `claude-opus-4-8[1m]`
    76	# and blew the $0.50 cap in 4 turns ($0.53) because the ceiling below was sized for Sonnet.
    77	# Default to the spike's model; override with CLAUDE_MODEL for an intentionally heavier builder.
    78	model="${CLAUDE_MODEL:-claude-sonnet-4-6}"
    79	
    80	# Cost ceilings: sized from the M2 authenticated spike (2026-06-17, Sonnet 4.6).
    81	# Real relay turn (minimal fixture): 7 turns, $0.172, 26s wall-clock, 207k cache-read + 1.4k output.
    82	# --max-turns 12: observed 7; headroom for complex builder turns (multi-file edits, retries).
    83	# --max-budget-usd 0.50: observed $0.17; ~3× margin for heavier content. The cache-read bulk
    84	#   (~207k tokens) is cheap; output tokens ($15/M) dominate on complex turns.
    85	# NOTE: these ceilings are valid only for the pinned model — raise --max-budget-usd if CLAUDE_MODEL
    86	# points at a costlier model (e.g. Opus), or the turn will hard-stop mid-build like the 06-18 run.
    87	max_turns="${CLAUDE_MAX_TURNS:-12}"
    88	max_budget="${CLAUDE_MAX_BUDGET:-0.50}"
    89	
    90	# Phase 3.6 — bound the builder's side-effect surface. `--allowedTools Bash` lets the headless
    91	# builder run ANYTHING; a 2026-06-17 dogfood builder ran `consult` (real Codex+Gemini API calls) as
    92	# an off-task side-quest. Shadow the external-model / recursive-spawn commands on PATH for the
    93	# `claude -p` subprocess ONLY — the reviewer turn (codex-turn/gemini-turn) is a SEPARATE process with
    94	# a normal PATH, so codex/gemini review is unaffected. Even if the builder runs `consult.sh` by path,
    95	# its internal bare `codex`/`gemini` calls hit these stubs. NOT airtight (an absolute-path call to the
    96	# real binary bypasses it) — worktree isolation is the airtight follow-up (ROADMAP 3.6). Override the
    97	# set with CLAUDE_BLOCK_CMDS; set it empty to disable.
    98	block_cmds="${CLAUDE_BLOCK_CMDS-codex gemini consult consult.sh marathon-drive.sh relay-drive.sh}"
    99	shadow_dir=""
   100	if [[ -n "$block_cmds" ]]; then
   101	  shadow_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-turn-shadow.XXXXXX")"
   102	  for c in $block_cmds; do
   103	    { printf '#!/usr/bin/env bash\n'
   104	      printf 'printf "blocked: %%s is off-limits to a headless builder turn (CLAUDE_BLOCK_CMDS)\\n" %q >&2\n' "$c"
   105	      printf 'exit 127\n'
   106	    } > "$shadow_dir/$c"
   107	    chmod +x "$shadow_dir/$c"
   108	  done
   109	fi
   110	
   111	rtl_before
   112	claude_rc=0
   113	PATH="${shadow_dir:+$shadow_dir:}$PATH" "$CLAUDE_BIN" -p "$prompt" \
   114	  --model "$model" \
   115	  --allowedTools "Bash,Read,Edit,Write" \
   116	  --permission-mode acceptEdits \
   117	  --output-format json \
   118	  --max-turns "$max_turns" \
   119	  --max-budget-usd "$max_budget" \
   120	  < /dev/null > "$CLAUDE_LOG" 2>&1 || claude_rc=$?
   121	[[ -n "$shadow_dir" ]] && rm -rf "$shadow_dir"
   122	[[ "$claude_rc" -eq 0 ]] || { printf 'claude-turn: claude -p failed (exit %s)\n' "$claude_rc" >&2; exit 5; }
   123	rtl_enforce "$t" "$me" "$CLAUDE_LOG" "claude"
   124	
   125	# Best-effort cost capture: parse the claude CLI's JSON token stats and emit a cost.tokens event.
   126	# NEVER fails the turn — the turn already committed; missing/unparseable stats → loud-partial signal.
   127	# JSON path: .usage.input_tokens, .usage.output_tokens, .total_cost_usd (claude --output-format json)
   128	if [[ -s "$CLAUDE_LOG" ]]; then
   129	  tokens_in="$(python3 -c "import json,sys; d=json.load(open('$CLAUDE_LOG')); print(d.get('usage',{}).get('input_tokens',0)+d.get('usage',{}).get('cache_read_input_tokens',0))" 2>/dev/null || echo 0)"
   130	  tokens_out="$(python3 -c "import json,sys; d=json.load(open('$CLAUDE_LOG')); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)"
   131	  if [[ "$tokens_in" -gt 0 || "$tokens_out" -gt 0 ]]; then
   132	    "${TICK_BIN:-$ROOT/bin/tick}" cost "$t" --agent "$me" \
   133	      --tokens-in "$tokens_in" --tokens-out "$tokens_out" --tool claude \
   134	      || printf 'claude-turn: tokens not captured for %s\n' "$t" >&2
   135	  else
   136	    printf 'claude-turn: tokens not captured for %s (zero or no stats in transcript)\n' "$t" >&2
   137	  fi
   138	fi

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# marathon-drive.sh test: single-phase driver — renders relay file, seeds tick token,
     3	# calls relay-drive, runs pre-advance gate, saves transcript, emits phase events.
     4	# Uses MARATHON_RELAY_DRIVE + MARATHON_AGENT_CMD + stub pre-advance-cmd to avoid real CLI.
     5	source "$(dirname "$0")/_setup.sh" marathon-drive
     6	export TICK_BIN="$TICK"
     7	DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
     8	tick_a init >/dev/null
     9	
    10	# Set up the fixture repo as the marathon root: .gitignore .tick/, seed an initial commit.
    11	printf '.tick/\n' > "$A/.gitignore"
    12	git -C "$A" add .gitignore >/dev/null 2>&1
    13	git -C "$A" commit -q -m "init"
    14	INIT_HEAD="$(git -C "$A" rev-parse HEAD)"   # saved so we can hard-reset between cases
    15	
    16	# Stub relay-drive: writes EXIT_CODE to $WORK/relay-drive-exit, echoes args, then exits.
    17	STUB_RD="$WORK/relay-drive.sh"
    18	cat > "$STUB_RD" << 'STUB_EOF'
    19	#!/usr/bin/env bash
    20	set -u
    21	printf '%s\n' "$*" > "$WORK/relay-drive-args"
    22	exit "${RELAY_DRIVE_EXIT:-0}"
    23	STUB_EOF
    24	chmod +x "$STUB_RD"
    25	
    26	# Phase brief file used across tests.
    27	BRIEF="$WORK/brief.md"
    28	printf '## Implement a hello-world function\nWrite a function that returns "hello".\n' > "$BRIEF"
    29	
    30	run_driver() {  # <extra-args…>
    31	  MARATHON_ROOT="$A" \
    32	  MARATHON_RELAY_DRIVE="$STUB_RD" \
    33	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    34	  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
    35	  bash "$DRIVER" \
    36	    --phases-dir "$A/phases" \
    37	    --phase-brief "$BRIEF" \
    38	    --reviewer gemini \
    39	    --pre-advance-cmd "true" \
    40	    "$@"
    41	}
    42	
    43	# ── (1) dry-run: relay file rendered, no commit, no tick events ───────────
    44	run_driver --dry-run >/dev/null 2>&1; rc=$?
    45	[ "$rc" -eq 0 ] && pass "dry-run exits 0" || fail "dry-run exit=$rc"
    46	[ -f "$A/phases/p1/RELAY.md" ] && pass "dry-run renders phases/p1/RELAY.md" || fail "relay file should exist after dry-run"
    47	git -C "$A" diff --cached --quiet && pass "dry-run makes no staged changes" || fail "dry-run should not stage anything"
    48	# relay file is unstaged in dry-run — no git add yet
    49	before_head="$(git -C "$A" rev-parse HEAD)"
    50	run_driver --dry-run >/dev/null 2>&1 || true   # run again to confirm HEAD stability
    51	[ "$(git -C "$A" rev-parse HEAD)" = "$before_head" ] && pass "dry-run makes no commits" || fail "dry-run should not commit"
    52	
    53	# Clean up the dry-run rendered file (it's untracked) before next test.
    54	rm -rf "$A/phases"
    55	
    56	# ── (2) relay file template: builder + reviewer sections present ──────────
    57	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
    58	grep -q "TAKE YOUR TURN.*claude.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
    59	  && pass "relay file has builder TAKE YOUR TURN section" \
    60	  || fail "builder TAKE YOUR TURN section missing"
    61	grep -q "TAKE YOUR TURN.*gemini.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
    62	  && pass "relay file has reviewer TAKE YOUR TURN section" \
    63	  || fail "reviewer TAKE YOUR TURN section missing"
    64	grep -q "STATUS: Open" "$A/phases/p1/RELAY.md" 2>/dev/null \
    65	  && pass "relay file has STATUS: Open" \
    66	  || fail "STATUS: Open missing"
    67	grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
    68	  && pass "phase brief text baked into relay file" \
    69	  || fail "brief text not in relay file"
    70	# clean for next case
    71	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
    72	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
    73	
    74	# ── (3) tick token seeded: task created + handed to builder ──────────────
    75	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
    76	# Verify task exists by checking the tick events dir directly (most reliable).
    77	ls "$A/.tick/events/" 2>/dev/null | grep -q "MARATHON-P1-TURN" \
    78	  && pass "MARATHON-P1-TURN tick task created (event file present)" \
    79	  || fail "MARATHON-P1-TURN tick task not found — no event file in .tick/events/"
    80	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
    81	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
    82	
    83	# ── (4) relay-drive called with correct args ──────────────────────────────
    84	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
    85	grep -q -- "--relay-file" "$WORK/relay-drive-args" \
    86	  && pass "relay-drive called with --relay-file" \
    87	  || fail "--relay-file arg missing from relay-drive invocation"
    88	grep -q -- "--relay-task" "$WORK/relay-drive-args" \
    89	  && pass "relay-drive called with --relay-task" \
    90	  || fail "--relay-task arg missing from relay-drive invocation"
    91	grep -q -- "--round-cap" "$WORK/relay-drive-args" \
    92	  && pass "relay-drive called with --round-cap" \
    93	  || fail "--round-cap arg missing from relay-drive invocation"
    94	grep -q -- "--agent-cmd" "$WORK/relay-drive-args" \
    95	  && pass "relay-drive called with --agent-cmd" \
    96	  || fail "--agent-cmd arg missing from relay-drive invocation"
    97	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
    98	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
    99	
   100	# ── (5) happy path: relay exit 0 → pre-advance passes → transcript saved ─
   101	GATE_CMD="$WORK/gate-pass.sh"
   102	printf '#!/usr/bin/env bash\nprintf "gate: passed\n"; exit 0\n' > "$GATE_CMD"
   103	chmod +x "$GATE_CMD"
   104	
   105	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1; rc=$?
   106	[ "$rc" -eq 0 ] && pass "happy path exits 0 (relay approved + gate passed)" || fail "happy path exit=$rc"
   107	ls "$A/relay-system"/*/marathon-p1-*.md >/dev/null 2>&1 \
   108	  && pass "transcript saved under relay-system/<date>/" \
   109	  || fail "transcript not found in relay-system/"
   110	# marathon.phase.approved event emitted (check events dir directly)
   111	ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.phase.approved" \
   112	  && pass "marathon.phase.approved event emitted" \
   113	  || fail "marathon.phase.approved not found in tick events"
   114	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   115	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   116	
   117	# ── (6) pre-advance gate failure → ESCALATION.md, exit 5 ─────────────────
   118	GATE_CMD_FAIL="$WORK/gate-fail.sh"
   119	printf '#!/usr/bin/env bash\nprintf "gate: FAILED\n" >&2; exit 1\n' > "$GATE_CMD_FAIL"
   120	chmod +x "$GATE_CMD_FAIL"
   121	
   122	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD_FAIL" >/dev/null 2>&1; rc=$?
   123	[ "$rc" -eq 5 ] && pass "pre-advance failure exits 5" || fail "pre-advance failure exit=$rc (expected 5)"
   124	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on gate failure" || fail "ESCALATION.md missing"
   125	grep -q "pre-advance-failed" "$A/phases/p1/ESCALATION.md" \
   126	  && pass "ESCALATION.md records pre-advance-failed reason" \
   127	  || fail "reason field missing in ESCALATION.md"
   128	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   129	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   130	
   131	# ── (7) relay cap/mismatch (exit 4) → ESCALATION.md, driver exits 4 ──────
   132	RELAY_DRIVE_EXIT=4 run_driver >/dev/null 2>&1; rc=$?
   133	[ "$rc" -eq 4 ] && pass "relay cap escalation exits 4" || fail "relay cap exit=$rc (expected 4)"
   134	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on relay cap" || fail "ESCALATION.md missing on cap"
   135	grep -q "relay-drive-exit: 4" "$A/phases/p1/ESCALATION.md" \
   136	  && pass "ESCALATION.md records relay-drive-exit: 4" \
   137	  || fail "relay-drive-exit field wrong in ESCALATION.md"
   138	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   139	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   140	
   141	# ── (8) relay no-progress (exit 3) → ESCALATION.md, driver exits 3 ───────
   142	RELAY_DRIVE_EXIT=3 run_driver >/dev/null 2>&1; rc=$?
   143	[ "$rc" -eq 3 ] && pass "relay no-progress exits 3" || fail "relay no-progress exit=$rc (expected 3)"
   144	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on no-progress" || fail "ESCALATION.md missing on no-progress"
   145	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   146	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   147	
   148	# ── (8b) containment violation (exit 6) → ESCALATION.md, driver exits 6 (Phase 3.6) ───
   149	# A turn-taker shim exits 6 when it reverts an off-lane edit; relay-drive propagates it. The
   150	# driver must treat that as a DEFINED escalation, not die "unexpected code 6" (dogfood 2026-06-17).
   151	RELAY_DRIVE_EXIT=6 run_driver >/dev/null 2>&1; rc=$?
   152	[ "$rc" -eq 6 ] && pass "containment violation escalation exits 6 (not 'unexpected')" || fail "containment exit=$rc (expected 6)"
   153	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on containment violation" || fail "ESCALATION.md missing on exit 6"
   154	grep -q "containment-violation" "$A/phases/p1/ESCALATION.md" \
   155	  && pass "ESCALATION.md records containment-violation reason" \
   156	  || fail "containment-violation reason missing in ESCALATION.md"
   157	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   158	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   159	
   160	# ── (9) MARATHON_BUILDER/MARATHON_REVIEWER exported for peer threading ────
   161	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1 || true
   162	# We can only verify this indirectly: marathon-agent.sh reads MARATHON_BUILDER/REVIEWER.
   163	# Here we just confirm the env vars are wired through by checking drive output doesn't error.
   164	pass "MARATHON_BUILDER/MARATHON_REVIEWER wired (no dispatcher errors in happy path)"
   165	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   166	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   167	
   168	# ── (10) custom round-cap reaches relay-drive ─────────────────────────────
   169	RELAY_DRIVE_EXIT=0 run_driver --round-cap 9 >/dev/null 2>&1 || true
   170	grep -q "9" "$WORK/relay-drive-args" \
   171	  && pass "--round-cap 9 passed to relay-drive" \
   172	  || fail "custom round-cap not found in relay-drive args"
   173	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   174	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   175	
   176	# ── (11) agent-cmd path with spaces survives relay-drive's eval ────────────
   177	# Regression: the real relay-drive `eval "$AGENT_CMD"`s the turn-taker. A repo path with a
   178	# space (".../GH Repos/...") splits on the space unless marathon-drive shell-quotes it.
   179	# The default stub above only RECORDS args; this case uses a stub that EVALs them like the real
   180	# relay-drive (line 110), with the agent script living under a directory that contains a space.
   181	SPACED_AGENT="$WORK/dir with space/agent.sh"
   182	mkdir -p "$WORK/dir with space"
   183	cat > "$SPACED_AGENT" <<AG
   184	#!/usr/bin/env bash
   185	printf 'ran\n' > "$WORK/spaced-agent-ran"
   186	AG
   187	chmod +x "$SPACED_AGENT"
   188	EVAL_RD="$WORK/relay-drive-eval.sh"
   189	cat > "$EVAL_RD" <<'RD'
   190	#!/usr/bin/env bash
   191	set -u
   192	acmd=""
   193	while (($# > 0)); do case "$1" in --agent-cmd) acmd="${2:-}"; shift 2 ;; *) shift ;; esac; done
   194	eval "$acmd"   # mirrors relay-drive.sh:110 — splits a spaced path unless the caller quoted it
   195	exit 0
   196	RD
   197	chmod +x "$EVAL_RD"
   198	rm -f "$WORK/spaced-agent-ran"
   199	MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$SPACED_AGENT" \
   200	  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
   201	  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
   202	    --reviewer gemini --pre-advance-cmd "true" >/dev/null 2>&1 || true
   203	[ -f "$WORK/spaced-agent-ran" ] \
   204	  && pass "agent-cmd path with spaces survives relay-drive eval" \
   205	  || fail "spaced agent-cmd path broke relay-drive eval — marathon-drive must shell-quote --agent-cmd"
   206	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   207	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   208	
   209	# ── (12) --artifact: real write surface (template targets it + ALLOW_PATHS reaches the turn-taker) ─
   210	ART="src/feature.js"
   211	# (a) the artifact path is baked into the relay and the tick claim --paths includes it
   212	RELAY_DRIVE_EXIT=0 run_driver --artifact "$ART" >/dev/null 2>&1 || true
   213	grep -q "$ART" "$A/phases/p1/RELAY.md" 2>/dev/null \
   214	  && pass "artifact path baked into relay template" || fail "artifact path missing from relay"
   215	grep -q -- "--paths \"phases/p1/RELAY.md,$ART\"" "$A/phases/p1/RELAY.md" 2>/dev/null \
   216	  && pass "tick claim --paths includes relay + artifact" || fail "claim --paths should declare the artifact"
   217	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   218	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   219	# (b) ALLOW_PATHS is exported down to the turn-taker (eval-ing stub relay-drive + env-recording agent)
   220	ENV_AGENT="$WORK/env-agent.sh"
   221	cat > "$ENV_AGENT" <<AG
   222	#!/usr/bin/env bash
   223	printf '%s\n' "\${ALLOW_PATHS:-UNSET}" > "$WORK/allow-paths-seen"
   224	AG
   225	chmod +x "$ENV_AGENT"
   226	rm -f "$WORK/allow-paths-seen"
   227	MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
   228	  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
   229	  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
   230	    --reviewer gemini --artifact "$ART" --pre-advance-cmd "true" >/dev/null 2>&1 || true
   231	grep -q "$ART" "$WORK/allow-paths-seen" 2>/dev/null \
   232	  && pass "ALLOW_PATHS exported to the turn-taker env" \
   233	  || fail "ALLOW_PATHS not propagated to agent-cmd (builder would have no write surface)"
   234	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   235	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   236	# (c) relay-only (no --artifact) leaves ALLOW_PATHS UNSET — containment default unchanged
   237	rm -f "$WORK/allow-paths-seen"
   238	MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
   239	  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
   240	  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
   241	    --reviewer gemini --pre-advance-cmd "true" >/dev/null 2>&1 || true
   242	grep -q "UNSET" "$WORK/allow-paths-seen" 2>/dev/null \
   243	  && pass "relay-only phase leaves ALLOW_PATHS unset (no extra write surface)" \
   244	  || fail "relay-only phase should not export ALLOW_PATHS"
   245	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   246	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   247	
   248	# ── (13) --require-clean: hard-stop on a dirty workspace (Phase 3.6) ───────
   249	# A clean tree starts fine; a stray untracked file + --require-clean is a hard stop (exit 2),
   250	# so unattended runs don't proceed with distracting context in the tree.
   251	RELAY_DRIVE_EXIT=0 run_driver --require-clean >/dev/null 2>&1; rc=$?
   252	[ "$rc" -eq 0 ] && pass "--require-clean passes on a clean workspace" || fail "--require-clean exit=$rc on clean tree (expected 0)"
   253	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   254	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   255	printf 'stray distracting brief\n' > "$A/STRAY.md"   # an untracked file outside the marathon's paths
   256	RELAY_DRIVE_EXIT=0 run_driver --require-clean >/dev/null 2>&1; rc=$?
   257	[ "$rc" -eq 2 ] && pass "--require-clean hard-stops (exit 2) on a dirty workspace" || fail "--require-clean exit=$rc on dirty tree (expected 2)"
   258	[ ! -f "$A/phases/p1/RELAY.md" ] && pass "dirty + --require-clean does not seed the phase" || fail "phase seeded despite --require-clean on dirty tree"
   259	# without --require-clean it only warns (still runs)
   260	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1; rc=$?

exec
/bin/zsh -lc "nl -ba relay-automation/gemini-turn.sh | sed -n '1,160p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# gemini-turn.sh — headless turn-taker for the GEMINI agent. Thin dispatch wrapper over the
     5	# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh,
     6	# proving the boundary is model-agnostic (decisions/2026-06-15-unattended-agent-containment.md).
     7	#
     8	# History: first drafted standalone by Gemini (fe0bd61), an exact parallel to codex-turn.sh.
     9	# Reconciled here onto the shared core (boundary in ONE place, not duplicated) AND corrected the
    10	# headless invocation: the Gemini CLI has NO `exec` subcommand — headless is `gemini -p`, and an
    11	# unattended turn needs GCA auth + `--yolo` + `--skip-trust` (caught by live-running the CLI 0.46.0).
    12	#
    13	# Invoked by relay-drive.sh as --agent-cmd, with env:
    14	#   RELAY_FILE  — relay thread file (always allowlisted)
    15	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    16	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    17	# Shim config:
    18	#   GEMINI_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==GEMINI_AGENT
    19	#   ALLOW_PATHS      — comma-separated extra git paths the turn may change (e.g. the artifact)
    20	#   RELAY_PEER       — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
    21	#                      prompt says "the other agent", which a live model may resolve to a role name)
    22	#   GEMINI_BIN       — gemini binary (default: gemini); tests inject a stub
    23	#   GEMINI_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
    24	#   GEMINI_LOG       — where to write the gemini transcript (default: stderr)
    25	#
    26	# Auth/headless contract (validated 2026-06-15, gemini-cli 0.46.0):
    27	#   GOOGLE_GENAI_USE_GCA=true  — personal Google login (free tier), reuses ~/.gemini/oauth_creds.json
    28	#   -p "<prompt>"              — non-interactive (headless) mode
    29	#   --yolo                     — auto-approve tool calls (shell for tick, edit for the relay file)
    30	#   --skip-trust               — bypass the trusted-folder prompt in an automated environment
    31	#
    32	# Exit: 0 acted/deferred · 5 gemini failed · 6 off-allowlist edit (reverted) · 2 usage.
    33	
    34	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    35	# shellcheck source=relay-turn-lib.sh
    36	source "$HERE/relay-turn-lib.sh"
    37	
    38	ROOT="${GEMINI_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    39	GEMINI_BIN="${GEMINI_BIN:-gemini}"
    40	die() { printf 'gemini-turn: %s\n' "$*" >&2; exit 2; }
    41	
    42	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
    43	gemini_agent="${GEMINI_AGENT:-}"
    44	[[ -n "$me" ]] || die "RELAY_AGENT required"
    45	[[ -n "$f" ]] || die "RELAY_FILE required"
    46	[[ -n "$gemini_agent" ]] || die "GEMINI_AGENT required"
    47	
    48	# Dispatch only for the Gemini agent; defer otherwise (that window drives its own turn).
    49	if [[ "$me" != "$gemini_agent" ]]; then
    50	  printf 'gemini-turn: actor %s is not the Gemini agent (%s) — deferring (window-driven)\n' "$me" "$gemini_agent" >&2
    51	  exit 0
    52	fi
    53	
    54	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
    55	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
    56	
    57	# Transcript/log: default to a $TMPDIR file (NOT the repo tree — the safety guard in
    58	# relay-turn-lib.sh deletes any in-tree log). A persisted transcript is both the debug record AND
    59	# the token source: `-o json` makes the CLI emit a stats block we parse for cost.tokens (Phase 1).
    60	GEMINI_LOG="${GEMINI_LOG:-${TMPDIR:-/tmp}/gemini-turn-$$.json}"
    61	GEMINI_OUTPUT_FORMAT="${GEMINI_OUTPUT_FORMAT:-json}"
    62	
    63	# Run the Gemini turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
    64	rtl_before
    65	GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
    66	  "$GEMINI_BIN" --yolo --skip-trust -o "$GEMINI_OUTPUT_FORMAT" -p "$prompt" < /dev/null > "$GEMINI_LOG" 2>&1 \
    67	  || { printf 'gemini-turn: gemini -p failed\n' >&2; exit 5; }
    68	rtl_enforce "$t" "$me" "$GEMINI_LOG" "gemini"
    69	
    70	# Best-effort cost capture (Phase 1, COST-OBSERVABILITY-PLAN): parse the CLI's own token stats and
    71	# log a cost.tokens event. NEVER fails the turn — the turn already committed; a missing/unparseable
    72	# stats block just means "tokens not captured" (the loud-partial signal), not a failed turn.
    73	if [[ -s "$GEMINI_LOG" ]]; then
    74	  "${TICK_BIN:-$ROOT/bin/tick}" cost "$t" --agent "$me" --from-gemini-json "$GEMINI_LOG" --tool gemini \
    75	    || printf 'gemini-turn: tokens not captured for %s (no parseable stats in transcript)\n' "$t" >&2
    76	fi

codex
I’ve found one likely fault line already: `max_review_rounds` is never validated by the parser, so I’m checking how Bash arithmetic actually behaves under `set -u` when the YAML contains a non-integer or an octal-looking string.
exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; rounds=08; cap="'$((2 * rounds + 1)); printf "%s'"\\n\" \""'$cap"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; rounds=-1; cap="'$((2 * rounds + 1)); printf "%s'"\\n\" \""'$cap"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 exited 1 in 0ms:
bash: 08: value too great for base (error token is "08")

 succeeded in 0ms:
-1

exec
/bin/zsh -lc "bash -lc 'set -euo pipefail; rounds=nope; cap="'$((2 * rounds + 1)); printf "%s'"\\n\" \""'$cap"'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 exited 1 in 0ms:
bash: nope: unbound variable

codex
I’m validating the parser edge cases directly now. The first hard issue is integer handling; next I’m probing whether quoted values survive `#` comments or get truncated despite being quoted.
codex
The environment blocks here-doc execution, so I’m switching to inline `node -e` probes. I only need enough to confirm whether quoted `#` values are preserved or silently mangled.
exec
/bin/zsh -lc "node -e 'const {parseMarathonYaml}=require(\"./src/marathon-yaml\"); const text=\"name: demo\\nphases:\\n  - id: p1\\n    reviewer: codex\\n    brief: \\\"briefs/p1 # final.md\\\"\\n\"; console.log(JSON.stringify(parseMarathonYaml(text), null, 2));'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
{
  "name": "demo",
  "phases": [
    {
      "id": "p1",
      "name": "",
      "reviewer": "codex",
      "max_review_rounds": "",
      "depends_on": "",
      "brief": "\"briefs/p1",
      "artifact": ""
    }
  ]
}

exec
/bin/zsh -lc "node -e 'const {parseMarathonYaml}=require(\"./src/marathon-yaml\"); const text=\"name: demo # keep\\nphases:\\n  - id: p1 # id comment\\n    reviewer: codex # reviewer comment\\n    name: \\\"alpha # beta\\\"\\n\"; console.log(JSON.stringify(parseMarathonYaml(text), null, 2));'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
{
  "name": "demo",
  "phases": [
    {
      "id": "p1",
      "name": "\"alpha",
      "reviewer": "codex",
      "max_review_rounds": "",
      "depends_on": "",
      "brief": "",
      "artifact": ""
    }
  ]
}

codex
I’ve got the substantive failure modes. I’m doing one last lightweight verification pass: syntax-only checks for the shell entrypoints and a parse of the example plan, which are safe under the read-only sandbox.
exec
/bin/zsh -lc 'bash -n relay-automation/marathon.sh && bash -n relay-automation/marathon-drive.sh && bash -n relay-automation/marathon-agent.sh && bash -n relay-automation/relay-drive.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
exec
/bin/zsh -lc 'node bin/marathon-yaml relay-automation/MARATHON.example.yaml --format json' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-82027-1848
 succeeded in 0ms:
{
  "name": "example-refactor",
  "phases": [
    {
      "id": "p1",
      "name": "Define the event schema",
      "reviewer": "codex",
      "max_review_rounds": "2",
      "depends_on": "",
      "brief": "phases-briefs/p1-schema.md",
      "artifact": "src/schema.js"
    },
    {
      "id": "p2",
      "name": "Single-writer lease on top of the schema",
      "reviewer": "gemini",
      "max_review_rounds": "3",
      "depends_on": "p1",
      "brief": "phases-briefs/p2-lease.md",
      "artifact": "src/lease.js"
    }
  ]
}

codex
ANSWER: Not ship-ready; I found 2 blockers in the new chain: `max_review_rounds` is not actually validated, and cross-phase clean-state is not guaranteed before p2 starts.

FINDINGS
- [Blocker] `max_review_rounds` can slip through as invalid and then crash or mis-cap the orchestrator. `src/marathon-yaml.js:95-108` validates reviewer/IDs/deps but never checks `max_review_rounds`; `relay-automation/marathon.sh:69-70` immediately does `cap=$((2 * rounds + 1))`. Scenario: `max_review_rounds: nope` exits under `set -u` with `nope: unbound variable`; `08` errors as invalid octal; `0` yields cap `1`, which gives the builder one turn and no reviewer turn.
- [Blocker] The state-cleanliness invariant is not enforced between phases. `relay-automation/marathon.sh:77-84` never passes `--require-clean`; `relay-automation/marathon-drive.sh:128-140` only warns on dirt; `relay-automation/marathon-drive.sh:279-289` runs an arbitrary gate but never proves the tree is clean afterward; `relay-automation/relay-turn-lib.sh:42-50,88-90` then snapshots any leftover dirt as ambient state for the next phase. Scenario: p1’s gate rewrites a tracked snapshot or generated file and exits `0` without committing it; p2 starts anyway, and its `rtl_before` baseline now includes p1 residue.
- [Should] Quoted values containing ` #` are silently mangled because comment stripping is not quote-aware. `src/marathon-yaml.js:20-36` strips inline comments before understanding quoted strings. Scenario: `brief: "briefs/p1 # retry.md"` parses as `"briefs/p1`, then `relay-automation/marathon.sh:71-73` fails later with “brief file not found” instead of a parse error; `name: "alpha # beta"` is truncated the same way.
- [Should] Multi-file `artifact` values are fragile if written the natural way with spaces after commas. `relay-automation/marathon-drive.sh:157-160` passes `artifact` through raw; `relay-automation/relay-turn-lib.sh:23-27` splits on commas but never trims whitespace. Scenario: `artifact: src/a.js, src/b.js` leaves the second allowlist entry as `" src/b.js"`, so a legitimate edit to `src/b.js` is treated as off-allowlist and reverted.
- [Should] The unit tests named in scope miss the real-run failure modes. `test/marathon.sh:13-35` replaces `marathon-drive.sh` with a stub, so it cannot catch dirty-tree carryover, real boundary-event placement, or peer-threading regressions; `test/marathon-yaml.sh:8-86` has no coverage for invalid `max_review_rounds` or quoted `#` values. Scenario: the suite stays green while a real chain starts p2 on a dirty tree or truncates a quoted `brief:`.
- [Pass] Topological ordering and halt-on-first-failure look correct. `src/marathon-yaml.js:110-131` gives deterministic author-order topo resolution among ready phases, and `relay-automation/marathon.sh:83-89` stops the chain on the first nonzero phase exit.
- [Pass] Boundary events are placed correctly in the real driver. `relay-automation/marathon-drive.sh:221-230` emits `marathon.phase.start` after seeding; `279-289` emits `marathon.phase.approved` only after the gate passes; `249-263,293-309` emit `marathon.phase.escalated` on defined failures; `relay-automation/marathon.sh:91-96` emits `marathon.complete` only after all phases succeed.
- [Pass] Peer threading is wired through every phase handoff. `relay-automation/marathon-drive.sh:107-109` exports builder/reviewer IDs; `relay-automation/marathon-agent.sh:36-41` derives `RELAY_PEER` from the current actor before dispatching to the model shim.
- [Pass] I do not see a Linux CI portability blocker in the new code paths. The scripts are explicitly Bash (`relay-automation/marathon.sh:1-2`, `relay-automation/marathon-drive.sh:1-2`), and the constructs used here are Bash-3.2+/GNU/BSD safe. I only verified syntax and example-plan parsing in this read-only sandbox, not the full write-path suite.

RECOMMENDATION: Hold shipment until `max_review_rounds` is validated in the parser and the chain proves a clean worktree between phases; then add regressions for quoted `#` values and spaced multi-file `artifact` lists.
tokens used
87,125
ANSWER: Not ship-ready; I found 2 blockers in the new chain: `max_review_rounds` is not actually validated, and cross-phase clean-state is not guaranteed before p2 starts.

FINDINGS
- [Blocker] `max_review_rounds` can slip through as invalid and then crash or mis-cap the orchestrator. `src/marathon-yaml.js:95-108` validates reviewer/IDs/deps but never checks `max_review_rounds`; `relay-automation/marathon.sh:69-70` immediately does `cap=$((2 * rounds + 1))`. Scenario: `max_review_rounds: nope` exits under `set -u` with `nope: unbound variable`; `08` errors as invalid octal; `0` yields cap `1`, which gives the builder one turn and no reviewer turn.
- [Blocker] The state-cleanliness invariant is not enforced between phases. `relay-automation/marathon.sh:77-84` never passes `--require-clean`; `relay-automation/marathon-drive.sh:128-140` only warns on dirt; `relay-automation/marathon-drive.sh:279-289` runs an arbitrary gate but never proves the tree is clean afterward; `relay-automation/relay-turn-lib.sh:42-50,88-90` then snapshots any leftover dirt as ambient state for the next phase. Scenario: p1’s gate rewrites a tracked snapshot or generated file and exits `0` without committing it; p2 starts anyway, and its `rtl_before` baseline now includes p1 residue.
- [Should] Quoted values containing ` #` are silently mangled because comment stripping is not quote-aware. `src/marathon-yaml.js:20-36` strips inline comments before understanding quoted strings. Scenario: `brief: "briefs/p1 # retry.md"` parses as `"briefs/p1`, then `relay-automation/marathon.sh:71-73` fails later with “brief file not found” instead of a parse error; `name: "alpha # beta"` is truncated the same way.
- [Should] Multi-file `artifact` values are fragile if written the natural way with spaces after commas. `relay-automation/marathon-drive.sh:157-160` passes `artifact` through raw; `relay-automation/relay-turn-lib.sh:23-27` splits on commas but never trims whitespace. Scenario: `artifact: src/a.js, src/b.js` leaves the second allowlist entry as `" src/b.js"`, so a legitimate edit to `src/b.js` is treated as off-allowlist and reverted.
- [Should] The unit tests named in scope miss the real-run failure modes. `test/marathon.sh:13-35` replaces `marathon-drive.sh` with a stub, so it cannot catch dirty-tree carryover, real boundary-event placement, or peer-threading regressions; `test/marathon-yaml.sh:8-86` has no coverage for invalid `max_review_rounds` or quoted `#` values. Scenario: the suite stays green while a real chain starts p2 on a dirty tree or truncates a quoted `brief:`.
- [Pass] Topological ordering and halt-on-first-failure look correct. `src/marathon-yaml.js:110-131` gives deterministic author-order topo resolution among ready phases, and `relay-automation/marathon.sh:83-89` stops the chain on the first nonzero phase exit.
- [Pass] Boundary events are placed correctly in the real driver. `relay-automation/marathon-drive.sh:221-230` emits `marathon.phase.start` after seeding; `279-289` emits `marathon.phase.approved` only after the gate passes; `249-263,293-309` emit `marathon.phase.escalated` on defined failures; `relay-automation/marathon.sh:91-96` emits `marathon.complete` only after all phases succeed.
- [Pass] Peer threading is wired through every phase handoff. `relay-automation/marathon-drive.sh:107-109` exports builder/reviewer IDs; `relay-automation/marathon-agent.sh:36-41` derives `RELAY_PEER` from the current actor before dispatching to the model shim.
- [Pass] I do not see a Linux CI portability blocker in the new code paths. The scripts are explicitly Bash (`relay-automation/marathon.sh:1-2`, `relay-automation/marathon-drive.sh:1-2`), and the constructs used here are Bash-3.2+/GNU/BSD safe. I only verified syntax and example-plan parsing in this read-only sandbox, not the full write-path suite.

RECOMMENDATION: Hold shipment until `max_review_rounds` is validated in the parser and the chain proves a clean worktree between phases; then add regressions for quoted `#` values and spaced multi-file `artifact` lists.
