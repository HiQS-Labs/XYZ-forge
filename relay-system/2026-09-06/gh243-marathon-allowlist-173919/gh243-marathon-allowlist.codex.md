Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-24846-s8q1x7m2
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a0794e-2970-7d63-901e-a06461263940
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: QA a two-line change to a git pre-push guard

You are reviewing a plan, not writing code. Be adversarial. The two questions I most want attacked
are marked **ATTACK 1** and **ATTACK 2** at the end. Read the real files in this worktree — do not
take my summaries on trust.

Relevant files, all present in your worktree:

- `githooks/dashboard-staleness-guard.sh` — the guard. The block in question is at lines 147-158.
- `test/gh243-dashboard-staleness-guard.sh` — its suite; tests 7 and 8 are the matched pair from GH-315.
- `utils/roadmap-dashboard.sh` — the renderer whose staleness the guard protects.
- `utils/py/releases_app.py` — the ledger CLI; `roadmap list --json` is the renderer's only data input.

## What "good" looks like for this review

A verdict of **Approve**, **Approve with changes**, or **Changes requested**, followed by findings
each labelled Blocker / Should / Nit. A finding must cite a file:line or a command whose output
would settle it. "Consider being careful about X" with no anchor is not a finding. If you believe
the plan is correct, say so plainly rather than manufacturing objections — but if the safety
argument has a hole, that hole is the most valuable thing you can hand back.

## Context: the defect

`dashboard-staleness-guard.sh` refuses a push whose commit range writes `releases.sql`/`releases.db`
without also modifying `ROADMAP-DASHBOARD.md`. GH-243 built that for one cause: a parked roadmap row
silently dropped by the renderer because of malformed `raw_text`. The guard detects the situation by
regenerating the dashboard and checking for drift.

GH-315 (closed 2026-08-29) found a second, legitimate reason a ledger write produces no dashboard
diff: the write targets a table the dashboard does not render at all. Its fix was an allowlist of
literal INSERT prefixes — `jog_queue`, `op_receipts`, and the `settings` generation counter — with
everything else falling through to the refusal.

Today a `releases marathon add --tracking-issue .../issues/462` write was refused by that same
branch. The marathon write's dump fan-out is `marathons` + `issue_refs` + `op_receipts` + the
generation counter. The last two are allowlisted; the first two are not, so the range hits the
catch-all and gets the "a parked row was dropped by the renderer" message — which is false. Nothing
was dropped. This is GH-315's defect recurring with different table names.

Reproduction: the push of merge commit `196424fb` was refused 2 seconds after start (the guard runs
before the test suite). `bash utils/roadmap-dashboard.sh` emits no warnings and produces no diff.

## The proposed fix

Two case arms added to the existing GH-315 classifier, above the catch-all:

```bash
    '-'INSERT\ INTO\ marathons*|'+'INSERT\ INTO\ marathons*) ;;
    '-'INSERT\ INTO\ issue_refs*|'+'INSERT\ INTO\ issue_refs*) ;;
```

Plus a new test 7b in `test/gh243-dashboard-staleness-guard.sh`, mirroring test 7 exactly but with a
marathon fan-out as the payload, asserting rc 0. Test 8 (a `roadmap_items` write in the same shape
still refuses) is left untouched as the red control. Negative control: revert the two arms, confirm
7b fails and 8 still passes.

## ATTACK 1 — the safety proof

The governing rule in this repo is **never weaken a check to make a gate pass.** Allowlisting these
two tables is only legitimate if they genuinely have no dashboard projection. My evidence:

1. `utils/roadmap-dashboard.sh` contains no SQL; its only data input is
   `releases_app.py roadmap list --json` (line 59).
2. That command returns 132 rows whose `global_id` values carry exactly one prefix, `rmi-`. No
   `mar-`, no `ref-`. The field set is the `roadmap_items` column list: `doc_path, gh_number,
   global_id, issue_url, position, raw_text, section, status_marker, title`.
3. The substrings `marathon` and `ref-` do appear in that JSON but only inside `raw_text`/`title` —
   prose in issue titles, e.g. "GH-202 · wave_reconcile aborts on marathon-plan exit 5".

**Attack this.** Specifically:

- Is there any path by which a `marathons` or `issue_refs` row reaches `ROADMAP-DASHBOARD.md`?
  Trace `roadmap list` in `releases_app.py` yourself. Does it join, subquery, or resolve
  `issue_refs` to populate `issue_url`? A row reachable as a *value* through a join is still a
  projection, and my evidence (3) would not catch it.
- Does anything else the guard protects — not just `ROADMAP-DASHBOARD.md` — consume these tables?
- Is empirical output from one database a sound basis at all, given the current DB may simply have
  no marathon whose issue also sits in the roadmap? What input would falsify my claim?

## ATTACK 2 — allowlist vs. inverting the check

The allowlist has now gone short twice: jog in GH-315, marathon today. The obvious alternative is to
invert it — refuse only when a `roadmap_items` line changed, one arm replacing four:

```bash
    '-'INSERT\ INTO\ roadmap_items*|'+'INSERT\ INTO\ roadmap_items*) non_jog_data=1; break ;;
```

I **rejected** this on the grounds that the allowlist fails closed (an unclassified table refuses
and forces a human to look) while the inverted denylist fails open (a future second projected table
would ship stale, silently, with the guard reporting success).

**Attack this too.** Is my fail-closed/fail-open framing right? Consider that the current allowlist
has produced two false refusals and zero true catches in its lifetime — does a guard that cries wolf
twice and never catches anything actually fail closed in any useful sense, or does it just train
people to reach for `git push --no-verify`, which skips the entire test suite? Is there a third
option better than both — for example, having the guard ask `releases_app.py` which tables the
renderer projects, at the cost of a git hook depending on the app at push time? Name the option you
would ship and why.

## Also worth your attention

- `issue_refs` is reachable from `roadmap_items.issue_url` as a value. Is allowlisting it separable
  from `marathons`, or should only `marathons` be added?
- GH-315 explicitly recorded that its classifier does not match non-INSERT dump grammars. Is the
  literal `INSERT INTO <table> ` prefix match still the right granularity, or does adding a fourth
  and fifth entry make the fragility worse?
- Is a two-line guard change the right scope at all, or should this be filed and the marathon write
  simply parked out of the current push?

codex
I’m using the codebase-memory skill because this review hinges on exact call paths and table projections. I’ll verify the graph’s coverage, then inspect the cited shell and Python source directly.
exec
/bin/zsh -lc "sed -n '1,240p' /Users/noelsaw/.codex/skills/codebase-memory/SKILL.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-24846-s8q1x7m2
 succeeded in 0ms:
---
name: codebase-memory
description: "Use the codebase knowledge graph for structural code queries. Triggers on: explore the codebase, understand the architecture, what functions exist, show me the structure, who calls this function, what does X call, trace the call chain, find callers of, show dependencies, impact analysis, dead code, unused functions, high fan-out, refactor candidates, code quality audit, graph query syntax, Cypher query examples, edge types, how to use search_graph."
---

# Codebase Memory — Knowledge Graph Tools

Graph tools return precise structural results in ~500 tokens vs ~80K for grep.

## Quick Decision Matrix

| Question | Tool call |
|----------|----------|
| Who calls X? | `trace_path(direction="inbound")` |
| What does X call? | `trace_path(direction="outbound")` |
| Full call context | `trace_path(direction="both")` |
| Find by name pattern | `search_graph(name_pattern="...")` |
| Dead code | `search_graph(max_degree=0, exclude_entry_points=true)` |
| Cross-service edges | `query_graph` with Cypher |
| Impact of local changes | `detect_changes()` |
| Risk-classified trace | `trace_path(risk_labels=true)` |
| Text search | `search_code` or Grep |

## Exploration Workflow
1. `list_projects` — check if project is indexed
2. `get_graph_schema` — understand node/edge types
3. `search_graph(label="Function", name_pattern=".*Pattern.*")` — find code
4. `get_code_snippet(qualified_name="project.path.FuncName")` — read source

## Tracing Workflow
1. `search_graph(name_pattern=".*FuncName.*")` — discover exact name
2. `trace_path(function_name="FuncName", direction="both", depth=3)` — trace
3. `detect_changes()` — map git diff to affected symbols

## Evidence Tiers
- **Scout (Tier 1):** fast positive lookup with few graph calls and targeted source checks. Treat results as provisional; never make absence, exhaustive, dead-code, or complete-impact claims.
- **Verify (Tier 2, default):** task-directed searches, relevant trace directions, exact snippets for material claims, and all relevant result pages.
- **Auditor (Tier 3):** bounded-scope full verification with a current graph generation, complete relevant pagination, both call directions and broader relationships when material, plus explicit unresolved limitations.
- **Every tier:** after candidate paths are known, call `check_index_coverage` once with every evidence path. For negative or exhaustive claims also include the relevant scopes. A clean result means no recorded gap, not proof of completeness. For partial, skipped, excluded, stale, pending, or unknown coverage, read/grep the reported ranges or scope before relying on the graph.

## Sessions and Subagents
- At session start or after compaction, call `list_projects`/`index_status` before structural exploration, then choose Scout, Verify, or Auditor for the task.
- Before delegating, query the graph and coverage in the parent. Pass the tier, exact project, generation/freshness, bounded scope, queries and pagination state, qualified symbols, paths, call-chain findings, coverage ranges/reasons, source fallback already performed, and unresolved questions to the child.
- Runtimes such as Hermes isolate child context: put those graph findings in the `context` argument to `delegate_task`; do not assume the child inherits MCP access or the parent's conversation.
- A child without MCP tools must not call or claim MCP access. It should work from the supplied evidence and use read/grep on exact source, especially every reported missed-coverage range.

## Quality Analysis
- Dead code: `search_graph(max_degree=0, exclude_entry_points=true)`
- High fan-out: `search_graph(min_degree=10, relationship="CALLS", direction="outbound")`
- High fan-in: `search_graph(min_degree=10, relationship="CALLS", direction="inbound")`

## 15 MCP Tools
`index_repository`, `index_status`, `list_projects`, `delete_project`,
`search_graph`, `search_code`, `trace_path`, `detect_changes`,
`query_graph`, `get_graph_schema`, `get_code_snippet`, `get_architecture`,
`check_index_coverage`, `manage_adr`, `ingest_traces`

## Edge Types
CALLS, HTTP_CALLS, ASYNC_CALLS, DATA_FLOWS, IMPORTS, DEFINES, DEFINES_METHOD,
HANDLES, IMPLEMENTS, OVERRIDE, USAGE, CALL_REFERENCE, CONFIGURES, FILE_CHANGES_WITH,
SIMILAR_TO, SEMANTICALLY_RELATED, CONTAINS_FILE, CONTAINS_FOLDER,
CONTAINS_PACKAGE

## Cypher Examples (for query_graph)
```
MATCH (a)-[r:HTTP_CALLS]->(b) RETURN a.name, b.name, r.url_path, r.confidence LIMIT 20
MATCH (f:Function) WHERE f.name =~ '.*Handler.*' RETURN f.name, f.file_path
MATCH (a)-[r:CALLS]->(b) WHERE a.name = 'main' RETURN b.name
```

## Gotchas
1. `search_graph(relationship="HTTP_CALLS")` filters nodes by degree — use `query_graph` with Cypher to see actual edges.
2. `query_graph` has a 100k row ceiling — add a Cypher `LIMIT` for broad queries or use `search_graph` pagination.
3. `trace_path` needs exact names — use `search_graph(name_pattern=...)` first.
4. `direction="outbound"` misses cross-service callers — use `direction="both"`.
5. `search_graph` results default to 50 per page — check `has_more` and use `offset`.

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (completed)
mcp: codebase-memory-mcp/index_status started
mcp: codebase-memory-mcp/index_status (completed)
mcp: codebase-memory-mcp/search_graph started
mcp: codebase-memory-mcp/search_graph (completed)
mcp: codebase-memory-mcp/get_code_snippet started
mcp: codebase-memory-mcp/get_code_snippet (completed)
mcp: codebase-memory-mcp/trace_path started
mcp: codebase-memory-mcp/trace_path (failed)
MCP tool call requires approval, but approval policy is never
exec
/bin/zsh -lc "nl -ba githooks/dashboard-staleness-guard.sh | sed -n '1,230p'
nl -ba test/gh243-dashboard-staleness-guard.sh | sed -n '1,360p'
nl -ba utils/roadmap-dashboard.sh | sed -n '1,260p'
nl -ba utils/py/releases_app.py | sed -n '620,720p;2460,2550p;2920,3020p;3100,3200p;3525,3590p'
rg -n \"marathons|issue_refs|roadmap_items|roadmap list|ROADMAP-DASHBOARD\" utils/py/releases_app.py utils/roadmap-dashboard.sh githooks/dashboard-staleness-guard.sh test/gh243-dashboard-staleness-guard.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-24846-s8q1x7m2
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# dashboard-staleness-guard.sh — refuse a push whose range writes the roadmap ledger but not the
     3	# dashboard (GH-243, the enforcement half of GH-169 item 3).
     4	#
     5	# WHY: since the ROADMAP_SOURCE=releases flip, ROADMAP-DASHBOARD.md is the ONLY human-readable
     6	# view of the roadmap ledger — the DB is what every tool trusts, and nothing else re-renders the
     7	# view. A ledger write (releases.sql / releases.db) that ships without a dashboard regeneration
     8	# publishes a web/agent view that silently disagrees with the data under it.
     9	#
    10	# WHERE IT RUNS: called by githooks/pre-push with the same "<local_sha> <remote_sha>" ref pairs
    11	# the gate already parses — the push boundary is this repo's one wired, branch-independent
    12	# enforcement point (GH-549); a pre-commit hook would need a second stub wiring that does not
    13	# exist. Local commits stay free and ungated on purpose.
    14	#
    15	# SCOPE: applies only when the repo being pushed declares ROADMAP_SOURCE=releases in .pdda-mode.
    16	# Legacy-mode repos and branches predating the flip are untouched. A new branch (all-zero remote
    17	# sha) has no computable range; it falls through to the full gate like every other unclassifiable
    18	# push — this guard only ever ADDS a refusal, never replaces the gate.
    19	#
    20	# Usage: dashboard-staleness-guard.sh <repo_root> <local_sha> <remote_sha> [<local_sha> <remote_sha>...]
    21	# Exit:  0 ok (guard passed or not applicable) · 1 refuse the push · 2 usage.
    22	set -uo pipefail
    23	
    24	REPO="${1:-}"; shift || true
    25	[ -n "$REPO" ] && [ -d "$REPO" ] || { echo "dashboard-staleness-guard: usage: <repo_root> <local_sha> <remote_sha>..." >&2; exit 2; }
    26	
    27	grep -q "ROADMAP_SOURCE=releases" "$REPO/.pdda-mode" 2>/dev/null || exit 0
    28	
    29	SYS_TMP="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)" || SYS_TMP="/tmp"
    30	GUARD_ROOT=""
    31	GUARD_ROOT_PHYS=""
    32	GUARD_INODE=""
    33	GUARD_DEV=""
    34	
    35	get_dev_inode() {
    36	  local target="$1"
    37	  # GNU coreutils spells --format as -c and uses -f for --file-system; BSD spells --format as -f.
    38	  # Probing BSD-first therefore SUCCEEDS on Linux for the wrong reason: `-f` is accepted, "%d %i"
    39	  # is read as a filename, and stdout gets a multi-line filesystem block instead of "<dev> <inode>".
    40	  # The caller's "${x%% *}" then yields an empty device and the guard reports an identity mismatch
    41	  # between two identical inodes. `-c` is not a BSD flag, so probing GNU-first fails cleanly there.
    42	  stat -c "%d %i" "$target" 2>/dev/null || stat -f "%d %i" "$target" 2>/dev/null || true
    43	}
    44	
    45	cleanup_guard() {
    46	  local exit_code=$?
    47	  [ -n "$GUARD_ROOT" ] || return "$exit_code"
    48	  [ -e "$GUARD_ROOT" ] || return "$exit_code"
    49	  if [ -L "$GUARD_ROOT" ]; then
    50	    echo "dashboard-staleness-guard: refusing cleanup — guard root is a symlink" >&2
    51	    exit 1
    52	  fi
    53	  local cur_phys
    54	  cur_phys="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || {
    55	    echo "dashboard-staleness-guard: failed to resolve guard root physical path" >&2
    56	    exit 1
    57	  }
    58	  if [ -n "$GUARD_ROOT_PHYS" ] && [ "$cur_phys" != "$GUARD_ROOT_PHYS" ]; then
    59	    echo "dashboard-staleness-guard: refusing cleanup — guard root path drifted ($cur_phys != $GUARD_ROOT_PHYS)" >&2
    60	    exit 1
    61	  fi
    62	  local cur_dev_inode
    63	  cur_dev_inode="$(get_dev_inode "$cur_phys")"
    64	  local cur_dev="${cur_dev_inode%% *}"
    65	  local cur_inode="${cur_dev_inode##* }"
    66	  if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ] || [ -z "$cur_dev" ] || [ -z "$cur_inode" ] || \
    67	     [ "$cur_dev" != "$GUARD_DEV" ] || [ "$cur_inode" != "$GUARD_INODE" ]; then
    68	    echo "dashboard-staleness-guard: refusing cleanup — guard root identity mismatch ($cur_dev:$cur_inode != $GUARD_DEV:$GUARD_INODE)" >&2
    69	    exit 1
    70	  fi
    71	  case "$cur_phys" in
    72	    "$SYS_TMP"/*) rm -rf "$cur_phys" || exit 1 ;;
    73	    *) echo "dashboard-staleness-guard: refusing cleanup of non-descendant $cur_phys" >&2; exit 1 ;;
    74	  esac
    75	  return "$exit_code"
    76	}
    77	trap cleanup_guard EXIT INT TERM
    78	
    79	GUARD_ROOT="$(mktemp -d "$SYS_TMP/staleness-guard.XXXXXX")"
    80	[ -n "$GUARD_ROOT" ] || { echo "dashboard-staleness-guard: mktemp failed" >&2; exit 1; }
    81	
    82	GUARD_ROOT_PHYS="$(cd -P "$GUARD_ROOT" 2>/dev/null && pwd -P)" || GUARD_ROOT_PHYS=""
    83	[ -n "$GUARD_ROOT_PHYS" ] && [ -d "$GUARD_ROOT_PHYS" ] || { echo "dashboard-staleness-guard: failed to resolve guard root" >&2; exit 1; }
    84	case "$GUARD_ROOT_PHYS" in
    85	  "$SYS_TMP"/*) ;;
    86	  *) echo "dashboard-staleness-guard: guard root $GUARD_ROOT_PHYS is not a resolved descendant of $SYS_TMP" >&2; exit 1 ;;
    87	esac
    88	
    89	init_dev_inode="$(get_dev_inode "$GUARD_ROOT_PHYS")"
    90	GUARD_DEV="${init_dev_inode%% *}"
    91	GUARD_INODE="${init_dev_inode##* }"
    92	if [ -z "$GUARD_DEV" ] || [ -z "$GUARD_INODE" ]; then
    93	  echo "dashboard-staleness-guard: failed to establish guard root device/inode identity" >&2
    94	  exit 1
    95	fi
    96	
    97	while [ "$#" -ge 2 ]; do
    98	  local_sha="$1"; remote_sha="$2"; shift 2
    99	  case "$remote_sha" in
   100	    ''|0000000000000000000000000000000000000000) continue ;;   # new branch: no range to inspect
   101	  esac
   102	  git -C "$REPO" cat-file -e "${remote_sha}^{commit}" 2>/dev/null || continue
   103	
   104	  touched_ledger=0
   105	  touched_dashboard=0
   106	  while IFS= read -r path; do
   107	    case "$path" in
   108	      releases.sql|releases.db) touched_ledger=1 ;;
   109	      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
   110	    esac
   111	  done < <(git -C "$REPO" diff --no-renames --name-only "$remote_sha" "$local_sha" 2>/dev/null)
   112	
   113	  if [ "$touched_ledger" -eq 1 ] && [ "$touched_dashboard" -eq 0 ]; then
   114	    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
   115	    # Run the diagnosis against a commit-pinned temporary projection of local_sha inside the
   116	    # private GUARD_ROOT_PHYS so uncommitted working-tree modifications do not skew the classification.
   117	    TMP_PROJ="$GUARD_ROOT_PHYS/proj-$local_sha"
   118	    mkdir -p "$TMP_PROJ"
   119	
   120	    drift_detected=1
   121	    if git -C "$REPO" archive "$local_sha" 2>/dev/null | tar -x -C "$TMP_PROJ" 2>/dev/null \
   122	       && [ -f "$TMP_PROJ/utils/roadmap-dashboard.sh" ]; then
   123	      if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
   124	        drift_detected=0
   125	      else
   126	        drift_detected=1
   127	      fi
   128	    fi
   129	
   130	    if [ "$drift_detected" -eq 1 ]; then
   131	      cat >&2 <<'EOF'
   132	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   133	(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
   134	view would ship stale against the data under it (GH-243 / GH-169 item 3).
   135	
   136	Fix (one command, then commit the result into the same push):
   137	    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
   138	
   139	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   140	EOF
   141	    else
   142	      # The other legitimate no-diff case: a ledger change the dashboard cannot render.
   143	      # jog_queue rows have no dashboard projection, and a jog write's full dump fan-out is
   144	      # jog_queue + its op_receipts audit rows + the settings generation counter — none of
   145	      # which the dashboard renders (GH-315). If every changed data line targets exactly
   146	      # that set, allow; any other table's data change keeps the dropped-row refusal below.
   147	      non_jog_data=0
   148	      while IFS= read -r dline; do
   149	        case "$dline" in
   150	          '-'INSERT\ INTO\ jog_queue*|'+'INSERT\ INTO\ jog_queue*) ;;
   151	          '-'INSERT\ INTO\ op_receipts*|'+'INSERT\ INTO\ op_receipts*) ;;
   152	          *INSERT\ INTO\ settings*generation*) ;;
   153	          '-'INSERT\ INTO\ *|'+'INSERT\ INTO\ *) non_jog_data=1; break ;;
   154	        esac
   155	      done < <(git -C "$REPO" diff --no-renames "$remote_sha" "$local_sha" -- releases.sql 2>/dev/null)
   156	      if [ "$non_jog_data" -eq 0 ]; then
   157	        continue
   158	      fi
   159	      cat >&2 <<'EOF'
   160	dashboard-staleness-guard: REFUSING the push — this range writes the roadmap ledger
   161	(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
   162	dashboard produces NO diff (GH-243 / GH-257).
   163	
   164	This happens when a parked row was dropped by the renderer (e.g. malformed raw_text).
   165	To diagnose:
   166	    bash utils/roadmap-dashboard.sh
   167	and inspect stderr for warnings on dropped rows. Correct the row with:
   168	    releases roadmap update --issue-num <N> --raw-text "- **GH-<N> · <title>** ..."
   169	then regenerate and commit:
   170	    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
   171	
   172	Bypass (deliberately loud, e.g. a WIP branch): git push --no-verify
   173	EOF
   174	    fi
   175	    exit 1
   176	  fi
   177	done
   178	
   179	exit 0
     1	#!/bin/bash
     2	# test/gh243-dashboard-staleness-guard.sh — the GH-243 push guard: a roadmap-ledger write without a
     3	# dashboard regeneration is refused, releases-mode only, and only when a real range exists.
     4	set -eu
     5	source test/_setup.sh "GH-243" || { echo "setup failed"; exit 1; }
     6	
     7	root="$(cd "$HERE/.." && pwd)"
     8	GUARD="$root/githooks/dashboard-staleness-guard.sh"
     9	
    10	# Fixture: a releases-mode repo with a base commit, then a ledger-only commit on top.
    11	R="$WORK/fixture"
    12	mkdir -p "$R"
    13	cd "$R"
    14	git init -q .
    15	git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    16	echo "ROADMAP_SOURCE=releases" > .pdda-mode
    17	echo "-- dump v1" > releases.sql
    18	echo "dash v1" > ROADMAP-DASHBOARD.md
    19	git add .pdda-mode releases.sql ROADMAP-DASHBOARD.md
    20	git -c user.email=t@t -c user.name=t commit -q -m "v1"
    21	BASE="$(git rev-parse HEAD)"
    22	
    23	echo "-- dump v2" > releases.sql
    24	git add releases.sql
    25	git -c user.email=t@t -c user.name=t commit -q -m "ledger write, no dashboard"
    26	LEDGER_ONLY="$(git rev-parse HEAD)"
    27	cd "$root"
    28	
    29	# 1. Ledger write without dashboard -> refuse (exit 1) with the regen instruction.
    30	rc=0; out="$(bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" 2>&1)" || rc=$?
    31	[ "$rc" -eq 1 ] || fail "expected refusal (1), got $rc"
    32	grep -q "roadmap-dashboard.sh" <<<"$out" || fail "refusal missing the regeneration instruction"
    33	
    34	# 2. Same range with the dashboard regenerated in it -> pass.
    35	cd "$R"
    36	echo "dash v2" > ROADMAP-DASHBOARD.md
    37	git add ROADMAP-DASHBOARD.md
    38	git -c user.email=t@t -c user.name=t commit -q -m "regen dashboard"
    39	FIXED="$(git rev-parse HEAD)"
    40	cd "$root"
    41	bash "$GUARD" "$R" "$FIXED" "$BASE" || fail "regenerated range should pass, got $?"
    42	
    43	# 3. Legacy-mode repo (no releases marker) -> guard is inert even on a ledger-only range.
    44	cd "$R"; : > .pdda-mode; cd "$root"
    45	bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" || fail "legacy-mode repo must not be guarded, got $?"
    46	cd "$R"; echo "ROADMAP_SOURCE=releases" > .pdda-mode; cd "$root"
    47	
    48	# 4. New branch (all-zero remote sha) -> no range, no refusal.
    49	bash "$GUARD" "$R" "$LEDGER_ONLY" "0000000000000000000000000000000000000000" \
    50	  || fail "new-branch push must fall through, got $?"
    51	
    52	# 5. Non-ledger range (docs commit only) -> pass.
    53	cd "$R"
    54	echo "readme" > README.md
    55	git add README.md
    56	git -c user.email=t@t -c user.name=t commit -q -m docs
    57	DOCS="$(git rev-parse HEAD)"
    58	cd "$root"
    59	bash "$GUARD" "$R" "$DOCS" "$FIXED" || fail "non-ledger range must pass, got $?"
    60	
    61	# 6. Usage error -> exit 2.
    62	rc=0; bash "$GUARD" >/dev/null 2>&1 || rc=$?
    63	[ "$rc" -eq 2 ] || fail "expected usage exit 2, got $rc"
    64	
    65	
    66	# 7. GH-315: jog-queue-only ledger write, renderer in-sync, no dashboard change -> ALLOW
    67	# (jog rows have no dashboard projection; a no-diff regen is the expected outcome, not a
    68	# dropped-row symptom). The fixture needs a renderer whose --check passes to reach the
    69	# guard's no-drift branch at all.
    70	mkdir -p "$R/utils"
    71	printf '#!/usr/bin/env bash\nexit 0\n' > "$R/utils/roadmap-dashboard.sh"
    72	chmod +x "$R/utils/roadmap-dashboard.sh"
    73	cd "$R"
    74	git add utils/roadmap-dashboard.sh
    75	git -c user.email=t@t -c user.name=t commit -q -m "add passing renderer"
    76	RENDERED="$(git rev-parse HEAD)"
    77	{ echo "-- dump v3"
    78	  echo "INSERT INTO settings(key, value) VALUES('generation', '9');"
    79	  echo "INSERT INTO jog_queue VALUES('seed');"
    80	  echo "INSERT INTO op_receipts(op, target_gid) VALUES('jog-add', 'seed');"
    81	} > releases.sql
    82	git add releases.sql
    83	git -c user.email=t@t -c user.name=t commit -q -m "jog-only ledger write"
    84	JOG_ONLY="$(git rev-parse HEAD)"
    85	cd "$root"
    86	bash "$GUARD" "$R" "$JOG_ONLY" "$RENDERED" \
    87	  || fail "jog-queue-only ledger write must pass the no-drift branch (GH-315), got $?"
    88	
    89	# 8. Control: a roadmap_items data change in the same no-drift shape still refuses.
    90	cd "$R"
    91	{ echo "-- dump v4"; echo "INSERT INTO roadmap_items VALUES('r1');"; } > releases.sql
    92	git add releases.sql
    93	git -c user.email=t@t -c user.name=t commit -q -m "roadmap-only ledger write"
    94	ROADMAP_ONLY="$(git rev-parse HEAD)"
    95	cd "$root"
    96	rc=0; out="$(bash "$GUARD" "$R" "$ROADMAP_ONLY" "$RENDERED" 2>&1)" || rc=$?
    97	[ "$rc" -eq 1 ] || fail "expected no-drift refusal (1) for non-jog data, got $rc"
    98	grep -q "NO diff" <<<"$out" || fail "expected the no-diff refusal message"
    99	
   100	echo "== GH-243 ALL PASSED =="
     1	#!/usr/bin/env bash
     2	# utils/roadmap-dashboard.sh — render a read-only dashboard from ROADMAP.md (GH-27).
     3	
     4	set -euo pipefail
     5	
     6	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     7	# GH-272: releases-merge-resolve.sh drives this renderer against a --root TARGET repo —
     8	# the ledger it renders and the dashboard it writes must follow the target, not this
     9	# script's own checkout. Self-location stays the default for every other caller.
    10	ROOT="${ROADMAP_DASHBOARD_ROOT:-$(cd "$HERE/.." && pwd)}"
    11	SOURCE_FILE="${ROADMAP_DASHBOARD_SOURCE:-"$ROOT/ROADMAP.md"}"
    12	OUTPUT_FILE="${ROADMAP_DASHBOARD_OUTPUT:-"$ROOT/ROADMAP-DASHBOARD.md"}"
    13	
    14	usage() {
    15	  cat <<'EOF'
    16	Usage: bash utils/roadmap-dashboard.sh [--check]
    17	
    18	  Default: render ROADMAP-DASHBOARD.md from the canonical root ROADMAP.md.
    19	  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
    20	EOF
    21	}
    22	
    23	MODE="write"
    24	if (($# > 1)); then
    25	  usage
    26	  exit 2
    27	fi
    28	if (($# == 1)); then
    29	  case "$1" in
    30	    --check) MODE="check" ;;
    31	    --help|-h) usage; exit 0 ;;
    32	    *) usage; exit 2 ;;
    33	  esac
    34	fi
    35	
    36	command -v node >/dev/null 2>&1 || {
    37	  echo "roadmap-dashboard: node is required" >&2
    38	  exit 2
    39	}
    40	
    41	TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/roadmap-dashboard.XXXXXX")"
    42	trap 'rm -rf "$TMP_DIR"' EXIT
    43	RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"
    44	
    45	# GH-243: in a releases-mode repo the DB is the roadmap's source of truth and ROADMAP.md is
    46	# frozen — render from `roadmap list --json` (each row's lossless raw_text under its section)
    47	# instead of the legacy file. An explicit ROADMAP_DASHBOARD_SOURCE still wins (test seam), and
    48	# any failure here falls back to the legacy file rather than emitting an empty dashboard.
    49	if [ -z "${ROADMAP_DASHBOARD_SOURCE:-}" ] \
    50	   && (grep -q "ROADMAP_SOURCE=releases" "$ROOT/.pdda-mode" 2>/dev/null || [ ! -f "$ROOT/ROADMAP.md" ]) \
    51	   && [ -f "$ROOT/releases.db" ] && command -v python3 >/dev/null 2>&1; then
    52	  DB_SRC="$TMP_DIR/roadmap-from-db.md"
    53	  DB_JSON="$TMP_DIR/roadmap-rows.json"
    54	  # JSON goes through a temp file passed as argv — `python3 -` takes its PROGRAM from the
    55	  # heredoc on stdin, so piping data in as well would feed the parser nothing (the PR #240
    56	  # rollup.sh bug, same shape). The APP resolves from HERE (this script's own checkout) while
    57	  # --root follows $ROOT: under ROADMAP_DASHBOARD_ROOT (GH-272) the target repo may ship the
    58	  # ledger without a utils/ tree at all.
    59	  if python3 "$HERE/py/releases_app.py" --root "$ROOT" roadmap list --json > "$DB_JSON" 2>/dev/null \
    60	     && python3 - "$DB_JSON" > "$DB_SRC" <<'PY'
    61	import json, sys
    62	with open(sys.argv[1]) as f:
    63	    rows = json.load(f)
    64	print("# ROADMAP (rendered from the RELEASES DB — GH-243; ROADMAP.md is frozen legacy)\n")
    65	print("## Ledger\n")   # the renderer only counts sections below this heading
    66	sections = {}
    67	for r in rows:
    68	    sections.setdefault(r.get("section") or "(unsectioned)", []).append(r)
    69	for section, items in sections.items():
    70	    print(f"### {section}\n")
    71	    for r in sorted(items, key=lambda x: x.get("position") or 0):
    72	        line = (r.get("raw_text") or "").strip()
    73	        if not line:
    74	            gh = f"GH-{r['gh_number']} · " if r.get("gh_number") is not None else ""
    75	            line = f"- **{gh}{r.get('title', '')}**"
    76	        print(line)
    77	    print()
    78	PY
    79	  then
    80	    [ -s "$DB_SRC" ] && SOURCE_FILE="$DB_SRC"
    81	  fi
    82	fi
    83	
    84	if [ ! -f "$SOURCE_FILE" ]; then
    85	  echo "roadmap-dashboard: source not found: $SOURCE_FILE" >&2
    86	  exit 3
    87	fi
    88	
    89	node - "$SOURCE_FILE" >"$RENDERED" <<'NODE'
    90	const fs = require("fs");
    91	
    92	const sourcePath = process.argv[2];
    93	const raw = fs.readFileSync(sourcePath, "utf8");
    94	const lines = raw.split(/\r?\n/);
    95	
    96	const banner = "<!-- GENERATED by utils/roadmap-dashboard.sh — DO NOT EDIT; edit ROADMAP.md -->";
    97	const ledgerSections = [
    98	  "Queue / parked intake",
    99	  "Queue",              // GH-243: early `releases roadmap add` rows parked under the short name
   100	  "In progress",
   101	  "Completed",
   102	  "Deferred · vision",
   103	];
   104	const knownStatuses = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲"];
   105	const extraStatuses = ["⚠️"];
   106	
   107	function escapeCell(value) {
   108	  return String(value)
   109	    .replace(/\|/g, "\\|")
   110	    .replace(/</g, "&lt;")
   111	    .replace(/>/g, "&gt;");
   112	}
   113	
   114	function stripMarkdown(value) {
   115	  return value
   116	    .replace(/`([^`]+)`/g, "$1")
   117	    .replace(/\*\*([^*]+)\*\*/g, "$1")
   118	    .replace(/\*([^*]+)\*/g, "$1")
   119	    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
   120	    .trim();
   121	}
   122	
   123	function parseBullet(block) {
   124	  const text = block.map((line) => line.trim()).join(" ").replace(/\s+/g, " ").trim();
   125	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   126	  const title = titleMatch ? stripMarkdown(titleMatch[1]) : stripMarkdown(text.replace(/^- /, ""));
   127	
   128	  let status = "—";
   129	  for (const emoji of knownStatuses.concat(extraStatuses)) {
   130	    if (text.includes(emoji)) {
   131	      status = emoji;
   132	      break;
   133	    }
   134	  }
   135	
   136	  const links = [];
   137	  const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
   138	  let match;
   139	  while ((match = linkPattern.exec(text)) !== null) {
   140	    links.push(`[${match[1]}](${match[2]})`);
   141	  }
   142	
   143	  return { title, status, links };
   144	}
   145	
   146	function formatTally(items) {
   147	  const counts = new Map();
   148	  for (const emoji of knownStatuses) counts.set(emoji, 0);
   149	  const extras = [];
   150	
   151	  for (const item of items) {
   152	    if (counts.has(item.status)) {
   153	      counts.set(item.status, counts.get(item.status) + 1);
   154	      continue;
   155	    }
   156	    if (item.status !== "—") {
   157	      if (!counts.has(item.status)) extras.push(item.status);
   158	      counts.set(item.status, (counts.get(item.status) || 0) + 1);
   159	    }
   160	  }
   161	
   162	  const ordered = knownStatuses.slice();
   163	  for (const emoji of extras) {
   164	    if (!ordered.includes(emoji)) ordered.push(emoji);
   165	  }
   166	
   167	  return ordered.map((emoji) => `${emoji} ${counts.get(emoji) || 0}`).join(" · ");
   168	}
   169	
   170	const sections = new Map();
   171	for (const heading of ledgerSections) sections.set(heading, []);
   172	
   173	let inLedger = false;
   174	let currentSection = null;
   175	const droppedRows = [];
   176	
   177	for (let i = 0; i < lines.length; i++) {
   178	  const line = lines[i];
   179	
   180	  if (!inLedger) {
   181	    if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   182	    continue;
   183	  }
   184	
   185	  if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   186	
   187	  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   188	  if (sectionMatch) {
   189	    const heading = sectionMatch[1].trim();
   190	    currentSection = sections.has(heading) ? heading : null;
   191	    continue;
   192	  }
   193	
   194	  if (!currentSection) continue;
   195	
   196	  const trimmed = line.trim();
   197	  if (!trimmed || trimmed.startsWith("<!--") || trimmed.startsWith("#")) continue;
   198	
   199	  if (!/^- \*\*[^\r\n*]+?\*\*/.test(line)) {
   200	    // GH-257: track non-empty dropped/unparseable line under an active ledger section
   201	    const issueMatch = trimmed.match(/(?:GH-?|#)(\d+)/i);
   202	    const id = issueMatch ? `#${issueMatch[1]}` : JSON.stringify(trimmed.length > 30 ? trimmed.slice(0, 30) + "..." : trimmed);
   203	    droppedRows.push({ section: currentSection, id, line: trimmed });
   204	    continue;
   205	  }
   206	
   207	  const block = [line];
   208	  while (i + 1 < lines.length) {
   209	    const next = lines[i + 1];
   210	    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^\s*[-*+]\s+/.test(next)) break;
   211	    block.push(next);
   212	    i += 1;
   213	  }
   214	  sections.get(currentSection).push(parseBullet(block));
   215	}
   216	
   217	if (droppedRows.length > 0) {
   218	  const ids = droppedRows.map((d) => d.id).join(", ");
   219	  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
   220	}
   221	
   222	const output = [];
   223	output.push(banner);
   224	output.push("");
   225	output.push("# ROADMAP Dashboard");
   226	output.push("");
   227	output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
   228	output.push("");
   229	
   230	for (const heading of ledgerSections) {
   231	  const items = sections.get(heading) || [];
   232	  output.push(`## ${heading}`);
   233	  output.push("");
   234	  output.push(`Summary: ${items.length} items | Tally: ${formatTally(items)}`);
   235	  output.push("");
   236	  output.push("| Item | Status | Links |");
   237	  output.push("| --- | --- | --- |");
   238	  for (const item of items) {
   239	    const links = item.links.length > 0 ? item.links.join(" · ") : "—";
   240	    output.push(`| ${escapeCell(item.title)} | ${escapeCell(item.status)} | ${links} |`);
   241	  }
   242	  if (items.length === 0) {
   243	    output.push("| — | — | — |");
   244	  }
   245	  output.push("");
   246	}
   247	
   248	process.stdout.write(output.join("\n"));
   249	NODE
   250	
   251	if [[ "$MODE" == "check" ]]; then
   252	  if [[ ! -f "$OUTPUT_FILE" ]]; then
   253	    echo "roadmap-dashboard: missing artifact: $OUTPUT_FILE" >&2
   254	    exit 1
   255	  fi
   256	  if cmp -s "$RENDERED" "$OUTPUT_FILE"; then
   257	    echo "roadmap-dashboard: artifact is in sync"
   258	    exit 0
   259	  fi
   260	  echo "roadmap-dashboard: artifact drift detected: $OUTPUT_FILE" >&2
   620	    BEGIN…END contains its own semicolons. Only trigger-free scripts may use it; migration
   621	    004 issues its trigger DDL as explicit single execute() calls instead.
   622	    """
   623	    if "CREATE TRIGGER" in script.upper():
   624	        raise ValueError("_ddl_statements cannot split trigger bodies; issue them individually")
   625	    # sqlite3.complete_statement() is comment- and string-literal-aware; a naive split(";")
   626	    # cuts mid-statement on the first `--` comment containing a semicolon.
   627	    statements, buffer = [], ""
   628	    for line in script.splitlines(keepends=True):
   629	        buffer += line
   630	        if sqlite3.complete_statement(buffer):
   631	            statements.append(buffer.strip())
   632	            buffer = ""
   633	    if buffer.strip():
   634	        statements.append(buffer.strip())
   635	    return statements
   636	
   637	
   638	def _table_exists(conn, name):
   639	    return conn.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
   640	                        (name,)).fetchone() is not None
   641	
   642	
   643	def _col(row, name, default=None):
   644	    """Read a column that may not exist yet on an un-migrated ledger. sqlite3.Row raises
   645	    IndexError for an absent key, so a bare row["baseline_count"] would turn "you have not run
   646	    `releases migrate`" into a traceback."""
   647	    try:
   648	        return row[name]
   649	    except (IndexError, KeyError):
   650	        return default
   651	
   652	
   653	def _has_column(conn, table, column):
   654	    """Schema probe. The dump writer uses it so a PRE-migration database can still be dumped
   655	    (and therefore digested) — `perform_migration` needs `business_digest` on the old shape
   656	    before it touches anything, and the dump grammar's absent-trailing-fields-read-as-NULL rule
   657	    makes the shorter record a legal dump rather than a lossy one."""
   658	    if not _table_exists(conn, table):
   659	        return False
   660	    return any(r["name"] == column for r in conn.execute("PRAGMA table_info(%s)" % table))
   661	
   662	
   663	def _ensure_roadmap_schema(conn, stamp=True):
   664	    """Apply migration 002 idempotently. MUST run inside a perform_write mutate when the DB
   665	    predates it: the new schema_migrations row is business state, and a schema change outside a
   666	    receipt would trip check's receipt-vs-change bypass detection — correctly.
   667	
   668	    GH-111: issued as individual execute() calls, NOT executescript(). Python's sqlite3
   669	    COMMITs any open transaction before running a script, so the old idiom would silently
   670	    split perform_migration()'s single transaction when 002 and 004 are both pending —
   671	    leaving 002 durable after a 004 failure while the journal still claims all-or-nothing.
   672	
   673	    stamp=False is the REGISTRY entry point: `apply_migrations` owns the ledger row there, and
   674	    `_rebuild` calls it with stamping suppressed entirely so it can write the ledger itself
   675	    afterwards. A self-stamping callback would collide with that on the primary key.
   676	    """
   677	    for statement in _ddl_statements(MIGRATION_002_DDL):
   678	        conn.execute(statement)
   679	    if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None:
   680	        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (2, ?)",
   681	                     (now_iso(),))
   682	
   683	
   684	MIGRATION_004_ITEMS_NEW = """
   685	CREATE TABLE manifest_items_new (
   686	  id INTEGER PRIMARY KEY,
   687	  global_id TEXT NOT NULL UNIQUE {mfi_gid},
   688	  release_id INTEGER NOT NULL REFERENCES releases(id),
   689	  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   690	  state TEXT NOT NULL CHECK (state IN ('dialed_in','shipped','cut')),
   691	  dialed_in_at TEXT,
   692	  dial_reason TEXT,
   693	  marathon_id INTEGER REFERENCES marathons(id)
   694	)"""
   695	
   696	MIGRATION_004_EVENTS_NEW = """
   697	CREATE TABLE manifest_state_events_new (
   698	  id INTEGER PRIMARY KEY,
   699	  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
   700	  from_state TEXT NOT NULL CHECK (from_state IN ('open','dialed_in','shipped','cut')),
   701	  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','dialed_in','shipped','cut')),
   702	  at TEXT NOT NULL,
   703	  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)
   704	)"""
   705	
   706	
   707	def _migration_004(conn):
   708	    """GH-111: retire FREEZE for DIALED-IN membership.
   709	
   710	    TRANSACTION-SAFE BY CONSTRUCTION — every statement goes through execute(), never
   711	    executescript(), which would COMMIT the caller's transaction and silently void
   712	    perform_migration()'s FK bracket, rollback, digest chain and receipt coupling.
   713	
   714	    Parent (manifest_items) is rebuilt before child (manifest_state_events), and `id`
   715	    values are carried across verbatim so the child's item_id linkage — and with it the
   716	    event digest chain — still resolves. Both CHECK vocabularies change, which SQLite
   717	    cannot do in place, hence the rebuilds. `open` stays legal in the EVENT table forever:
   718	    historical rows are copied unchanged rather than remapped, because rewriting them
   719	    would be the silent history edit this repo forbids everywhere else.
   720	    """
  2460	                refuse("dialed-in-elsewhere",
  2461	                       "issue is already dialed into %s — a task belongs to ONE release at a time."
  2462	                       % (", ".join("%s (%s)" % (h["global_id"], h["codename"] or "?")
  2463	                                    for h in held)))
  2464	
  2465	            if (item["state"], "dialed_in") not in LEGAL_ITEM_TRANSITIONS:
  2466	                refuse("transition",
  2467	                       "cannot move an item from %r to 'dialed_in' (legality is CLI-enforced)"
  2468	                       % item["state"])
  2469	
  2470	            if _has_column(conn, "manifest_items", "updated_at"):
  2471	                conn.execute("UPDATE manifest_items SET state='dialed_in', updated_at=? WHERE id=?",
  2472	                             (now_iso(), item["id"]))
  2473	            else:
  2474	                conn.execute("UPDATE manifest_items SET state='dialed_in' WHERE id=?",
  2475	                             (item["id"],))
  2476	            # item state and its event land in ONE transaction, matching ship/cut: a direct writer
  2477	            # that skips the event is caught by the digest chain.
  2478	            conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at,
  2479	                            reason) VALUES (?, 'shipped', 'dialed_in', ?, ?)""",
  2480	                         (item["id"], now_iso(), reason))
  2481	            print("manifest item %s un-shipped (shipped -> dialed_in); retraction event appended"
  2482	                  % item["global_id"])
  2483	
  2484	        perform_write(root, conn, "manifest-unship", args.gid, mutate)
  2485	    finally:
  2486	        conn.close()
  2487	
  2488	def cmd_marathon_add(args):
  2489	    root = resolve_root(args.root)
  2490	    paths = artifact_paths(root)
  2491	    conn = connect(paths["db"])
  2492	    try:
  2493	        gid = new_gid("mar-")
  2494	
  2495	        def mutate(conn):
  2496	            ref = issue_ref_for_token(conn, args.tracking_issue)
  2497	            repo_id = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()["id"]
  2498	            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
  2499	                         created_at) VALUES (?, ?, ?, ?, ?)""",
  2500	                         (gid, repo_id, ref["id"], args.status, now_iso()))
  2501	            print("marathon %s added (status %s)" % (gid, args.status))
  2502	
  2503	        perform_write(root, conn, "marathon-add", gid, mutate)
  2504	    finally:
  2505	        conn.close()
  2506	
  2507	
  2508	def cmd_marathon_list(args):
  2509	    root = resolve_root(args.root)
  2510	    conn = connect(artifact_paths(root)["db"])
  2511	    try:
  2512	        for row in conn.execute("""SELECT m.global_id, m.status, m.created_at, t.url, t.temp_id
  2513	                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
  2514	                                   ORDER BY m.id"""):
  2515	            print("%s  %-9s  %s  %s" % (row["global_id"], row["status"], row["created_at"],
  2516	                                        row["url"] or row["temp_id"]))
  2517	    finally:
  2518	        conn.close()
  2519	
  2520	
  2521	def _repo_label(path):
  2522	    return os.path.basename(os.path.normpath(path))
  2523	
  2524	
  2525	def _aggregate_all_repos(root, conn):
  2526	    """v1 aggregation surface: this DB plus RELEASES_APP_EXTRA_DBS (colon-separated). The
  2527	    Phase-3 cockpit card reads the hq registry instead; until then this is the testable reader.
  2528	    Duplicate global IDs across DBs fail the aggregation LOUDLY, never merge silently (PRD)."""
  2529	    extra = [p for p in os.environ.get("RELEASES_APP_EXTRA_DBS", "").split(":") if p]
  2530	    seen = {}
  2531	    for r in conn.execute("SELECT global_id FROM releases"):
  2532	        seen.setdefault(r["global_id"], set()).add(_repo_label(root))
  2533	    for db_path in extra:
  2534	        if not os.path.exists(db_path):
  2535	            refuse("extra-db-missing", "RELEASES_APP_EXTRA_DBS entry %s does not exist" % db_path)
  2536	        econn = connect(db_path)
  2537	        try:
  2538	            for r in econn.execute("SELECT global_id FROM releases"):
  2539	                seen.setdefault(r["global_id"], set()).add(_repo_label(os.path.dirname(db_path)))
  2540	        finally:
  2541	            econn.close()
  2542	    dups = {g: locs for g, locs in seen.items() if len(locs) > 1}
  2543	    # cross-repo codename duplication warns, never refuses — the survey's "Silverlining in two
  2544	    # repos" case. Emitted before the duplicate-GID exit so a failing aggregation still carries
  2545	    # its warnings.
  2546	    names = {}
  2547	    for db_path in [None] + extra:
  2548	        c = conn if db_path is None else connect(db_path)
  2549	        try:
  2550	            for r in c.execute("SELECT codename FROM releases WHERE codename IS NOT NULL"):
  2920	# U+2014 EM DASH is deliberately EXCLUDED: `GH-100 — 2026 planning` is a single-issue title whose
  2921	# key would otherwise be silently dropped. The ASCII hyphen is excluded for the same reason.
  2922	# The first pass conflated the two dashes; codex QA separated them, 2026-08-31.
  2923	_ROADMAP_MULTI_KEY_RE = re.compile(
  2924	    r"^(?:GH-|#)\d+\s*(?:[/,+&\u2013]|\.\.\.?)\s*(?:GH-|#)?\d+")
  2925	
  2926	# Markdown task-list items (`- [ ]`, `- [x]`) share the `- [` prefix with a link bullet but are
  2927	# not ledger entries; without this they parsed as rows with an empty or "x" title.
  2928	_ROADMAP_TASKBOX_RE = re.compile(r"^- \[[ xX]\]")
  2929	
  2930	
  2931	def _is_ledger_bullet(line):
  2932	    """A ledger entry opener: a bold bullet or a link bullet, never a task-list checkbox."""
  2933	    if line.startswith("- **"):
  2934	        return True
  2935	    return line.startswith("- [") and not _ROADMAP_TASKBOX_RE.match(line)
  2936	
  2937	
  2938	def _roadmap_gh_number(title):
  2939	    """The GH number a ledger entry is keyed by, or None. Anchored at the head of the title."""
  2940	    if _ROADMAP_MULTI_KEY_RE.match(title):
  2941	        return None
  2942	    m = _ROADMAP_KEY_RE.match(title)
  2943	    return int(m.group(1)) if m else None
  2944	
  2945	
  2946	# A scheme in a markdown link target: `https:`, `mailto:`, or a Windows drive prefix `C:`. Any of
  2947	# these means the target is not a repo-relative path, whatever it ends with.
  2948	_DOC_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
  2949	
  2950	
  2951	def _doc_pointer(target):
  2952	    """The repo-relative document path a link target names, or None.
  2953	
  2954	    The `doc_path` column is a path a consumer resolves against the filesystem, so an absolute
  2955	    URL, a mail address or a drive-lettered path in it yields a miss indistinguishable from a
  2956	    dead pointer. codex QA found the first cut let all three through, because the extraction
  2957	    regexes accepted any `.md`-suffixed target and this check was only consulted on the fallback
  2958	    branch. It is now the SINGLE validator every candidate passes through, whichever regex found
  2959	    it — a scheme-bearing `https://github.com/acme/specs/blob/main/DESIGN.md` is rejected here
  2960	    even though it ends `.md`."""
  2961	    if not target:
  2962	        return None
  2963	    target = target.strip()
  2964	    if not target:
  2965	        return None
  2966	    if _DOC_SCHEME_RE.match(target) or target.startswith("/") or "\\" in target:
  2967	        return None
  2968	    path = target.split("#", 1)[0].split("?", 1)[0]
  2969	    return path if path.endswith(".md") else None
  2970	
  2971	
  2972	def _roadmap_issue_url(raw, link_target, gh_number):
  2973	    """The URL a ledger entry is keyed to, or None.
  2974	
  2975	    Exactly two things count as evidence of identity: the bullet's OWN link target, and a URL in
  2976	    the block whose number corroborates the title's GH key. Nothing else — an unanchored search
  2977	    keyed GH-94 to a DIFFERENT repo's issue #2 and GH-68 to a PR, because both hooks cite other
  2978	    work in passing.
  2979	
  2980	    An earlier cut kept a third branch for UNKEYED entries: the first URL on the bullet's first
  2981	    line. codex QA showed that branch is wrong on the reporting repo's live data, where it stored
  2982	    a BLOCKER as the row's identity — `Grow Willies …` took #42 (a blocker that has its own ledger
  2983	    row) and `Marathon Plan 2026-07-07 …` took #47 (merely its only fireable lane). Being first is
  2984	    not evidence. An unkeyed entry whose own link is a document now stores nothing.
  2985	
  2986	    Position never implies identity here: no URL beats a wrong URL."""
  2987	    if link_target:
  2988	        target = link_target.strip()
  2989	        m = ROADMAP_URL_RE.fullmatch(target)
  2990	        if m:
  2991	            num = int(target.rsplit("/", 1)[1])
  2992	            if gh_number is None or num == gh_number:
  2993	                return m.group(0)
  2994	    if gh_number is None:
  2995	        return None
  2996	    for cand in ROADMAP_URL_RE.findall(raw):
  2997	        if int(cand.rsplit("/", 1)[1]) == gh_number:
  2998	            return cand
  2999	    return None
  3000	
  3001	
  3002	def parse_roadmap_ledger(path):
  3003	    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
  3004	    from its bullet line (`- **` or `- [`) to the next bullet, `###`, or `##`."""
  3005	    lines = open(path, encoding="utf-8").read().splitlines()
  3006	    entries = []
  3007	    sec = None
  3008	    inledger = False
  3009	    pos = {}
  3010	    i, n = 0, len(lines)
  3011	    while i < n:
  3012	        line = lines[i]
  3013	        if re.match(r"^##\s+Ledger\s*$", line.strip()):
  3014	            inledger = True
  3015	            i += 1
  3016	            continue
  3017	        if inledger and re.match(r"^##\s+", line):
  3018	            break
  3019	        if inledger and line.startswith("### "):
  3020	            sec = line[4:].strip()
  3100	                   "malformed --raw-text: does not reference issue GH-%d / #%d" % (issue_num, issue_num))
  3101	    return stripped
  3102	
  3103	
  3104	
  3105	def cmd_roadmap_add(args):
  3106	    root = resolve_root(args.root)
  3107	    paths = artifact_paths(root)
  3108	    conn = connect(paths["db"])
  3109	    try:
  3110	        basename = os.path.basename(args.doc_path)
  3111	        # hq park passes the hq_roadmap_line rendering via --raw-text so preview and stored row
  3112	        # share ONE template; the inline fallback exists only for direct CLI use.
  3113	        if args.raw_text:
  3114	            raw_text = validate_raw_text(args.raw_text, args.issue_num)
  3115	        else:
  3116	            raw_text = "- **GH-%d · %s** 🆕 **captured %s via HQ** — [%s](%s) · [#%d](%s)" % (
  3117	                args.issue_num, args.title, args.created, basename, args.doc_path,
  3118	                args.issue_num, args.issue_url
  3119	            )
  3120	        # GH-249: the rating rides in the ledger line, parsed by the SAME parse_rating() the
  3121	        # markdown sync uses — one grammar, one parser, never a second scorer. Before this, ratings
  3122	        # could only enter through `roadmap sync`, which GH-169 turned into a no-op in releases-mode
  3123	        # repos, so every row parked after the flip was silently unrated.
  3124	        rating = parse_rating(raw_text, args.title)
  3125	
  3126	        if args.dry_run:
  3127	            print("ROADMAP line: %s" % raw_text)
  3128	            if rating["rating_pri"] is not None:
  3129	                print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
  3130	                if rating["rating_ovr"] is not None:
  3131	                    print("ovr: %d" % rating["rating_ovr"])
  3132	            return
  3133	
  3134	        # Dup guard — only when the shadow table exists; a pre-migration ledger gets the schema
  3135	        # installed inside mutate (mirrors cmd_roadmap_sync) instead of a raw OperationalError.
  3136	        if _table_exists(conn, "roadmap_items"):
  3137	            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
  3138	            if row:
  3139	                refuse("roadmap-duplicate", "issue %s is already parked in the roadmap" % args.issue_url)
  3140	
  3141	            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
  3142	            if row2:
  3143	                refuse("roadmap-duplicate", "issue GH-%d is already parked in the roadmap" % args.issue_num)
  3144	
  3145	        gid = new_gid("rmi-")
  3146	
  3147	        def mutate(conn):
  3148	            _ensure_roadmap_schema(conn)
  3149	            ts = now_iso()
  3150	            section = "Queue / parked intake"   # the canonical ledger queue heading (GH-243)
  3151	            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
  3152	            pos = (max_pos[0] or 0) + 1 if max_pos else 1
  3153	            
  3154	            repo = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()
  3155	            if not repo:
  3156	                refuse("no-repo", "the DB has no repos row; run `releases init` first")
  3157	            
  3158	            # Mirrors cmd_roadmap_sync: feature commands never self-migrate. A rated line meeting
  3159	            # a ledger with no rating columns is refused BY NAME rather than written with its
  3160	            # scores silently dropped — an unrated row is indistinguishable from "never scored".
  3161	            rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
  3162	            if not rating_ok and rating["rating_pri"] is not None:
  3163	                refuse("schema-behind",
  3164	                       "GH-%d carries `rated` scores but this ledger has no rating columns. Run "
  3165	                       "`releases migrate` first — intake stores scores, it never installs schema."
  3166	                       % args.issue_num)
  3167	
  3168	            cols = ["global_id", "repo_id", "gh_number", "title", "section", "position",
  3169	                    "status_marker", "doc_path", "issue_url", "raw_text", "first_seen", "updated_at"]
  3170	            vals = [gid, repo["id"], args.issue_num, args.title, section, pos,
  3171	                    "🆕", args.doc_path, args.issue_url, raw_text, ts, ts]
  3172	            if rating_ok:
  3173	                cols += list(RATING_COLUMNS)
  3174	                vals += [rating[c] for c in RATING_COLUMNS]
  3175	            conn.execute("INSERT INTO roadmap_items(%s) VALUES (%s)"
  3176	                         % (", ".join(cols), ", ".join("?" * len(cols))), vals)
  3177	                          
  3178	        perform_write(root, conn, "roadmap-add", gid, mutate)
  3179	        print("added roadmap entry %s for GH-%d" % (gid, args.issue_num))
  3180	    finally:
  3181	        conn.close()
  3182	
  3183	def cmd_roadmap_rate(args):
  3184	    """GH-253: score a roadmap row that is already parked.
  3185	
  3186	    GH-249 taught intake to STORE a rating, but rows parked between the GH-169 flip and that fix
  3187	    were written unrated and had no path back — `roadmap add` only inserts, `roadmap sync` is a
  3188	    no-op in releases-mode, and nothing else writes the columns. That made "unrated" permanent for
  3189	    exactly the rows the bug created. This is the way back.
  3190	
  3191	    The rating is rendered into the SAME `rated N/N/N/N [ovr N]` token the ledger line carries and
  3192	    handed to the SAME parse_rating() — the token in raw_text and the five columns are written in
  3193	    one transaction so the lossless shadow can never disagree with the scores derived from it.
  3194	    """
  3195	    root = resolve_root(args.root)
  3196	    paths = artifact_paths(root)
  3197	    conn = connect(paths["db"])
  3198	    try:
  3199	        if not _table_exists(conn, "roadmap_items"):
  3200	            refuse("no-ledger", "this DB has no roadmap_items table; run `releases migrate` first")
  3525	            ts = now_iso()
  3526	            ins_cols = ["global_id", "repo_id"] + fields + ["first_seen", "updated_at"]
  3527	            ins_sql = "INSERT INTO roadmap_items(%s) VALUES (%s)" % (
  3528	                ", ".join(ins_cols), ", ".join("?" for _ in ins_cols))
  3529	            upd_sql = "UPDATE roadmap_items SET %s, updated_at=? WHERE id=?" % (
  3530	                ", ".join("%s=?" % f for f in fields))
  3531	            for e in adds:
  3532	                c.execute(ins_sql,
  3533	                          [new_gid("rmi-"), repo["id"]] + [e[f] for f in fields] + [ts, ts])
  3534	            for row, e in updates:
  3535	                c.execute(upd_sql, [e[f] for f in fields] + [ts, row["id"]])
  3536	            for row in removes:
  3537	                c.execute("DELETE FROM roadmap_items WHERE id = ?", (row["id"],))
  3538	
  3539	        txn = perform_write(root, conn, "roadmap-sync", None, mutate)
  3540	        print(summary + " (txn %s, generation %d)" % (txn[:12], get_generation(conn)))
  3541	    finally:
  3542	        conn.close()
  3543	
  3544	
  3545	def cmd_roadmap_list(args):
  3546	    root = resolve_root(args.root)
  3547	    conn = connect(artifact_paths(root)["db"])
  3548	    try:
  3549	        if getattr(args, "as_json", False):
  3550	            # Machine-readable contract for consumers (hq rollup): the human rendering below is
  3551	            # a display, not an API — its column offsets shift whenever a field widens.
  3552	            rows = []
  3553	            if _table_exists(conn, "roadmap_items"):
  3554	                for r in conn.execute("SELECT * FROM roadmap_items ORDER BY section, position"):
  3555	                    rows.append({"global_id": r["global_id"], "gh_number": r["gh_number"],
  3556	                                 "title": r["title"], "section": r["section"],
  3557	                                 "position": r["position"], "status_marker": r["status_marker"],
  3558	                                 "doc_path": _col(r, "doc_path"), "issue_url": _col(r, "issue_url"),
  3559	                                 "raw_text": _col(r, "raw_text")})
  3560	            print(json.dumps(rows, ensure_ascii=False))
  3561	            return
  3562	        if not _table_exists(conn, "roadmap_items"):
  3563	            print("(no roadmap shadow yet — run `releases roadmap sync`)")
  3564	            return
  3565	        for r in conn.execute("""SELECT * FROM roadmap_items ORDER BY section, position"""):
  3566	            gh = ("GH-%d" % r["gh_number"]) if r["gh_number"] is not None else "-"
  3567	            cre = ("%s/%s/%s" % (r["complexity"], r["risk"], r["effort"])
  3568	                   if r["complexity"] is not None else "-")
  3569	            # calc is DERIVED here, never stored — the equal-weighted sum of the four axes, and
  3570	            # the override wins over it for ranking wherever both exist.
  3571	            score = "-"
  3572	            if _col(r, "rating_pri") is not None:
  3573	                calc = sum(_col(r, c) for c in RATING_COLUMNS[:4])
  3574	                score = str(calc)
  3575	                if _col(r, "rating_ovr") is not None:
  3576	                    score = "%s>%d" % (score, r["rating_ovr"])
  3577	            print("%s  %-7s %-22s #%-3d cre=%-6s calc=%-8s %s %s" % (
  3578	                r["global_id"], gh, (r["section"] or "")[:22], r["position"], cre, score,
  3579	                r["status_marker"] or " ", r["title"][:64]))
  3580	    finally:
  3581	        conn.close()
  3582	
  3583	
  3584	def resolve_issue_number(target):
  3585	    """Resolve a target string or int into a GitHub issue number (int)."""
  3586	    if isinstance(target, int):
  3587	        return target
  3588	    s = str(target).strip()
  3589	    if s.isdigit():
  3590	        return int(s)
githooks/dashboard-staleness-guard.sh:5:# WHY: since the ROADMAP_SOURCE=releases flip, ROADMAP-DASHBOARD.md is the ONLY human-readable
githooks/dashboard-staleness-guard.sh:109:      ROADMAP-DASHBOARD.md)     touched_dashboard=1 ;;
githooks/dashboard-staleness-guard.sh:114:    # GH-257 Task 4: check whether regenerating ROADMAP-DASHBOARD.md produces drift or no diff.
githooks/dashboard-staleness-guard.sh:133:(releases.sql / releases.db) without regenerating ROADMAP-DASHBOARD.md, so the human-readable
githooks/dashboard-staleness-guard.sh:137:    bash utils/roadmap-dashboard.sh && git add ROADMAP-DASHBOARD.md && git commit -m "docs: regenerate roadmap dashboard"
githooks/dashboard-staleness-guard.sh:161:(releases.sql / releases.db) without modifying ROADMAP-DASHBOARD.md, but regenerating the
githooks/dashboard-staleness-guard.sh:170:    bash utils/roadmap-dashboard.sh && git add releases.db releases.sql ROADMAP-DASHBOARD.md && git commit -m "docs: fix roadmap row and regenerate dashboard"
test/gh243-dashboard-staleness-guard.sh:18:echo "dash v1" > ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:19:git add .pdda-mode releases.sql ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:36:echo "dash v2" > ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:37:git add ROADMAP-DASHBOARD.md
test/gh243-dashboard-staleness-guard.sh:89:# 8. Control: a roadmap_items data change in the same no-drift shape still refuses.
test/gh243-dashboard-staleness-guard.sh:91:{ echo "-- dump v4"; echo "INSERT INTO roadmap_items VALUES('r1');"; } > releases.sql
utils/roadmap-dashboard.sh:12:OUTPUT_FILE="${ROADMAP_DASHBOARD_OUTPUT:-"$ROOT/ROADMAP-DASHBOARD.md"}"
utils/roadmap-dashboard.sh:18:  Default: render ROADMAP-DASHBOARD.md from the canonical root ROADMAP.md.
utils/roadmap-dashboard.sh:19:  --check: exit 0 when ROADMAP-DASHBOARD.md is in sync; non-zero on drift.
utils/roadmap-dashboard.sh:43:RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"
utils/roadmap-dashboard.sh:46:# frozen — render from `roadmap list --json` (each row's lossless raw_text under its section)
utils/roadmap-dashboard.sh:59:  if python3 "$HERE/py/releases_app.py" --root "$ROOT" roadmap list --json > "$DB_JSON" 2>/dev/null \
utils/py/releases_app.py:270:                           FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id
utils/py/releases_app.py:464:CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
utils/py/releases_app.py:475:CREATE TABLE marathons (
utils/py/releases_app.py:479:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:495:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:496:  marathon_id INTEGER REFERENCES marathons(id),
utils/py/releases_app.py:509:  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:594:CREATE TABLE IF NOT EXISTS roadmap_items (  -- GH-69/GH-269: roadmap ledger.
utils/py/releases_app.py:611:CREATE INDEX IF NOT EXISTS idx_roadmap_repo ON roadmap_items(repo_id);
utils/py/releases_app.py:689:  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:693:  marathon_id INTEGER REFERENCES marathons(id)
utils/py/releases_app.py:798:    """GH-108: the pri/sev/appeal/effort rating columns on roadmap_items.
utils/py/releases_app.py:813:        if _has_column(conn, "roadmap_items", column):
utils/py/releases_app.py:816:        conn.execute("ALTER TABLE roadmap_items ADD COLUMN %s INTEGER "
utils/py/releases_app.py:988:    _emit(w, "issue_refs", ["global_id", "url", "temp_id", "created_at"],
utils/py/releases_app.py:989:          _rows(conn, "SELECT global_id, url, temp_id, created_at FROM issue_refs ORDER BY id"))
utils/py/releases_app.py:991:    _emit(w, "marathons", ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"],
utils/py/releases_app.py:994:                         FROM marathons m JOIN repos r ON r.id = m.repo_id
utils/py/releases_app.py:995:                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id"""))
utils/py/releases_app.py:1011:                    JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1012:                    LEFT JOIN marathons mar ON mar.id = rel.marathon_id ORDER BY rel.id"""
utils/py/releases_app.py:1024:                    JOIN issue_refs t ON t.id = mi.issue_ref_id{join} ORDER BY mi.id"""
utils/py/releases_app.py:1030:        mfi_join = " LEFT JOIN marathons mar ON mar.id = mi.marathon_id"
utils/py/releases_app.py:1070:    if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:1082:                        FROM roadmap_items ri JOIN repos r ON r.id = ri.repo_id
utils/py/releases_app.py:1084:        if _has_column(conn, "roadmap_items", "rating_pri"):
utils/py/releases_app.py:1089:        _emit(w, "roadmap_items", rmi_cols, _rows(conn, rmi_select.format(extra=rmi_extra)))
utils/py/releases_app.py:1566:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1584:                                  JOIN issue_refs t ON t.id = mi.issue_ref_id
utils/py/releases_app.py:1698:    """Find or create the issue_refs row for a URL/TMP-/MIG- token (identity is the row, so
utils/py/releases_app.py:1702:    row = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % col, (value,)).fetchone()
utils/py/releases_app.py:1706:    conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) "
utils/py/releases_app.py:1710:    return conn.execute("SELECT * FROM issue_refs WHERE global_id = ?", (gid,)).fetchone()
utils/py/releases_app.py:1998:                row = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2215:                mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2262:            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
utils/py/releases_app.py:2265:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2297:            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
utils/py/releases_app.py:2300:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2307:            mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2373:                ref = conn.execute("SELECT * FROM issue_refs WHERE url = ?", (value,)).fetchone()
utils/py/releases_app.py:2375:                ref = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
utils/py/releases_app.py:2378:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2421:            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
utils/py/releases_app.py:2424:                refuse("unknown-issue", "no issue_refs row for %r" % value)
utils/py/releases_app.py:2498:            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:2513:                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
utils/py/releases_app.py:2577:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:2625:        ref = conn.execute("SELECT url, temp_id FROM issue_refs WHERE id = ?",
utils/py/releases_app.py:2642:                                JOIN issue_refs t ON t.id = mi.issue_ref_id
utils/py/releases_app.py:2807:# agents edit; this code only READS it and mirrors the ledger into roadmap_items. The parser is a
utils/py/releases_app.py:3136:        if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3137:            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
utils/py/releases_app.py:3141:            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
utils/py/releases_app.py:3151:            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
utils/py/releases_app.py:3161:            rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
utils/py/releases_app.py:3175:            conn.execute("INSERT INTO roadmap_items(%s) VALUES (%s)"
utils/py/releases_app.py:3199:        if not _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3200:            refuse("no-ledger", "this DB has no roadmap_items table; run `releases migrate` first")
utils/py/releases_app.py:3212:            "FROM roadmap_items WHERE " + where, (param,)).fetchone()
utils/py/releases_app.py:3215:        if not _has_column(conn, "roadmap_items", "rating_pri"):
utils/py/releases_app.py:3245:                "UPDATE roadmap_items SET raw_text = ?, updated_at = ?, %s WHERE %s"
utils/py/releases_app.py:3269:        row = conn.execute("SELECT global_id, doc_path, raw_text FROM roadmap_items "
utils/py/releases_app.py:3286:            conn.execute("UPDATE roadmap_items SET doc_path = ?, raw_text = ?, updated_at = ? "
utils/py/releases_app.py:3306:        if not _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3307:            refuse("no-ledger", "this DB has no roadmap_items table; run `releases migrate` first")
utils/py/releases_app.py:3315:        has_rating_cols = _has_column(conn, "roadmap_items", "rating_pri")
utils/py/releases_app.py:3318:            "SELECT %s FROM roadmap_items WHERE %s" % (", ".join(select_cols), where), (param,)).fetchone()
utils/py/releases_app.py:3366:            conn.execute("UPDATE roadmap_items SET %s WHERE %s" % (", ".join(updates), where), params)
utils/py/releases_app.py:3416:            has_rows = bool(_table_exists(conn, "roadmap_items")
utils/py/releases_app.py:3417:                            and conn.execute("SELECT 1 FROM roadmap_items LIMIT 1").fetchone())
utils/py/releases_app.py:3426:                           "parsed 0 entries from %s (%s); refusing to delete roadmap_items%s"
utils/py/releases_app.py:3431:                n_rows = conn.execute("SELECT COUNT(*) FROM roadmap_items").fetchone()[0]
utils/py/releases_app.py:3469:        rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
utils/py/releases_app.py:3477:        if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3478:            for r in conn.execute("SELECT * FROM roadmap_items WHERE repo_id = ?", (repo["id"],)):
utils/py/releases_app.py:3483:        schema_missing = not _table_exists(conn, "roadmap_items") or conn.execute(
utils/py/releases_app.py:3527:            ins_sql = "INSERT INTO roadmap_items(%s) VALUES (%s)" % (
utils/py/releases_app.py:3529:            upd_sql = "UPDATE roadmap_items SET %s, updated_at=? WHERE id=?" % (
utils/py/releases_app.py:3537:                c.execute("DELETE FROM roadmap_items WHERE id = ?", (row["id"],))
utils/py/releases_app.py:3553:            if _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3554:                for r in conn.execute("SELECT * FROM roadmap_items ORDER BY section, position"):
utils/py/releases_app.py:3562:        if not _table_exists(conn, "roadmap_items"):
utils/py/releases_app.py:3565:        for r in conn.execute("""SELECT * FROM roadmap_items ORDER BY section, position"""):
utils/py/releases_app.py:3671:        has_rm = _table_exists(conn, "roadmap_items")
utils/py/releases_app.py:3678:                LEFT JOIN roadmap_items ri ON ri.gh_number = jq.gh_number
utils/py/releases_app.py:4210:            for r in conn.execute("""SELECT temp_id, created_at FROM issue_refs
utils/py/releases_app.py:4237:                                     JOIN issue_refs t ON t.id = mi.issue_ref_id
utils/py/releases_app.py:4309:# re.S: a dumped value may contain newlines (a roadmap_items raw_text, say). parse_dump
utils/py/releases_app.py:4467:    for row in tables.get("issue_refs", []):
utils/py/releases_app.py:4468:        cur = conn.execute("""INSERT INTO issue_refs(global_id, url, temp_id, created_at)
utils/py/releases_app.py:4474:    for row in tables.get("marathons", []):
utils/py/releases_app.py:4475:        cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:4537:    for row in tables.get("roadmap_items", []):
utils/py/releases_app.py:4538:        conn.execute("""INSERT INTO roadmap_items(global_id, repo_id, gh_number, title, section,
utils/py/releases_app.py:4738:        roadmap_items = conn.execute("""
utils/py/releases_app.py:4740:            FROM roadmap_items 
utils/py/releases_app.py:4745:        for item in roadmap_items:
utils/py/releases_app.py:4796:                row = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
utils/py/releases_app.py:4799:                    refuse("unknown-temp-ref", "no issue_refs row carries temp id %r" % temp)
utils/py/releases_app.py:4800:                conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL WHERE id = ?",
utils/py/releases_app.py:4944:    sp_rs = rsub.add_parser("sync", help="mirror legacy ROADMAP.md's ledger into roadmap_items (one-way)")
utils/py/releases_app.py:4947:                       help="permit clearing roadmap_items when the ledger is genuinely empty. "

codex
The direct trace is already sharper than the empirical argument: `roadmap list --json` executes a single `SELECT * FROM roadmap_items` and copies `issue_url` from that same row; it does not join `issue_refs` or `marathons`. I’m checking the dump grammar and whether the proposed glob accidentally covers table-name prefixes.
exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '440,625p;940,1100p;1685,1720p;2475,2525p;3095,3185p;4290,4335p'
nl -ba utils/roadmap-dashboard.sh | sed -n '89,245p'
nl -ba ROUTER.md | sed -n '1,120p'
nl -ba GUIDING-PRINCIPLES.md | sed -n '1,120p'
git status --short
git rev-parse HEAD" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-24846-s8q1x7m2
 succeeded in 12663ms:
2026-09-06 17:43:04.245 xcodebuild[10471:482635282]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:43:04.862 xcodebuild[10471:482635229] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-LsngSGZ1' (errno=Operation not permitted)
2026-09-06 17:43:06.437 xcodebuild[11543:482637538]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:43:06.889 xcodebuild[11543:482637454] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? .relay-artifacts/
?? relay-system/2026-09-06/gh243-marathon-allowlist-173919/
?? relay-system/2026-09-06/needle-oracle-140920/
?? skills/timbre/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-d1bTf496' (errno=Operation not permitted)
2026-09-06 17:43:10.282 xcodebuild[13373:482641417]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:43:11.105 xcodebuild[13373:482641342] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-3aDNJu2D' (errno=Operation not permitted)
2026-09-06 17:43:12.304 xcodebuild[14184:482643091]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 17:43:13.169 xcodebuild[14184:482643004] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
4123419abd6c8da66cebfd812bba95f8610581fa

exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '1070,1100p'
nl -ba utils/py/releases_app.py | sed -n '1688,1714p'
nl -ba utils/py/releases_app.py | sed -n '2468,2520p'
nl -ba utils/roadmap-dashboard.sh | sed -n '120,235p'
rg -n \"dashboard-staleness-guard|gh243-dashboard\" githooks/pre-push validate.sh ci-local.sh test utils .github 2>/dev/null" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-24846-s8q1x7m2
 succeeded in 0ms:
  1070	    if _table_exists(conn, "roadmap_items"):
  1071	        # GH-108's five rating columns are appended in fixed trailing order, emitted only when the
  1072	        # schema has them (same absent-reads-as-NULL rule as the GH-111 fields above). `calc` is
  1073	        # NEVER dumped: it is derived at read time from the four axes, and storing a derived value
  1074	        # invites the drift class this grammar exists to prevent.
  1075	        rmi_cols = ["global_id", "repo_gid", "gh_number", "title", "section", "position",
  1076	                    "status_marker", "complexity", "risk", "effort", "doc_path", "issue_url",
  1077	                    "raw_text", "first_seen", "updated_at"]
  1078	        rmi_select = """SELECT ri.global_id, r.global_id AS repo_gid, ri.gh_number, ri.title,
  1079	                        ri.section, ri.position, ri.status_marker, ri.complexity, ri.risk,
  1080	                        ri.effort, ri.doc_path, ri.issue_url, ri.raw_text, ri.first_seen,
  1081	                        ri.updated_at{extra}
  1082	                        FROM roadmap_items ri JOIN repos r ON r.id = ri.repo_id
  1083	                        ORDER BY ri.id"""
  1084	        if _has_column(conn, "roadmap_items", "rating_pri"):
  1085	            rmi_cols += list(RATING_COLUMNS)
  1086	            rmi_extra = "".join(", ri.%s" % c for c in RATING_COLUMNS)
  1087	        else:
  1088	            rmi_extra = ""
  1089	        _emit(w, "roadmap_items", rmi_cols, _rows(conn, rmi_select.format(extra=rmi_extra)))
  1090	
  1091	    if _table_exists(conn, "jog_queue"):
  1092	        jq_cols = ["global_id", "repo_gid", "gh_number", "position", "status",
  1093	                   "created_at", "updated_at", "attempt_count", "lease_pid", "failure_reason"]
  1094	        jq_select = """SELECT jq.global_id, r.global_id AS repo_gid, jq.gh_number,
  1095	                       jq.position, jq.status, jq.created_at, jq.updated_at,
  1096	                       jq.attempt_count, NULL AS lease_pid, jq.failure_reason
  1097	                       FROM jog_queue jq JOIN repos r ON r.id = jq.repo_id
  1098	                       ORDER BY jq.position, jq.id"""
  1099	        _emit(w, "jog_queue", jq_cols, _rows(conn, jq_select))
  1100	
  1688	            return ("temp", token)
  1689	        refuse("mig-import-only",
  1690	               "MIG-XXXXXX placeholders are import-only (migration debt, distinct from the "
  1691	               "GitHub-down TMP- fallback); disposition them via `releases reconcile`")
  1692	    refuse("issue-url-shape",
  1693	           "tracking reference %r must be https://github.com/<org>/<repo>/issues/<n> or "
  1694	           "TMP-XXXXXX" % token)
  1695	
  1696	
  1697	def issue_ref_for_token(conn, token, allow_mig=False):
  1698	    """Find or create the issue_refs row for a URL/TMP-/MIG- token (identity is the row, so
  1699	    re-adding an existing URL reuses it)."""
  1700	    kind, value = check_tracking_token(token, allow_mig=allow_mig)
  1701	    col, other = ("url", "temp_id") if kind == "url" else ("temp_id", "url")
  1702	    row = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % col, (value,)).fetchone()
  1703	    if row:
  1704	        return row
  1705	    gid = new_gid("ref-")
  1706	    conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) "
  1707	                 "VALUES (?, ?, ?, ?)",
  1708	                 (gid, value if kind == "url" else None,
  1709	                  value if kind == "temp" else None, now_iso()))
  1710	    return conn.execute("SELECT * FROM issue_refs WHERE global_id = ?", (gid,)).fetchone()
  1711	
  1712	
  1713	def _github_slug_from_origin(root):
  1714	    """Best-effort '<org>/<repo>' from a github.com origin remote; None when unresolved."""
  2468	                       % item["state"])
  2469	
  2470	            if _has_column(conn, "manifest_items", "updated_at"):
  2471	                conn.execute("UPDATE manifest_items SET state='dialed_in', updated_at=? WHERE id=?",
  2472	                             (now_iso(), item["id"]))
  2473	            else:
  2474	                conn.execute("UPDATE manifest_items SET state='dialed_in' WHERE id=?",
  2475	                             (item["id"],))
  2476	            # item state and its event land in ONE transaction, matching ship/cut: a direct writer
  2477	            # that skips the event is caught by the digest chain.
  2478	            conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at,
  2479	                            reason) VALUES (?, 'shipped', 'dialed_in', ?, ?)""",
  2480	                         (item["id"], now_iso(), reason))
  2481	            print("manifest item %s un-shipped (shipped -> dialed_in); retraction event appended"
  2482	                  % item["global_id"])
  2483	
  2484	        perform_write(root, conn, "manifest-unship", args.gid, mutate)
  2485	    finally:
  2486	        conn.close()
  2487	
  2488	def cmd_marathon_add(args):
  2489	    root = resolve_root(args.root)
  2490	    paths = artifact_paths(root)
  2491	    conn = connect(paths["db"])
  2492	    try:
  2493	        gid = new_gid("mar-")
  2494	
  2495	        def mutate(conn):
  2496	            ref = issue_ref_for_token(conn, args.tracking_issue)
  2497	            repo_id = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()["id"]
  2498	            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
  2499	                         created_at) VALUES (?, ?, ?, ?, ?)""",
  2500	                         (gid, repo_id, ref["id"], args.status, now_iso()))
  2501	            print("marathon %s added (status %s)" % (gid, args.status))
  2502	
  2503	        perform_write(root, conn, "marathon-add", gid, mutate)
  2504	    finally:
  2505	        conn.close()
  2506	
  2507	
  2508	def cmd_marathon_list(args):
  2509	    root = resolve_root(args.root)
  2510	    conn = connect(artifact_paths(root)["db"])
  2511	    try:
  2512	        for row in conn.execute("""SELECT m.global_id, m.status, m.created_at, t.url, t.temp_id
  2513	                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
  2514	                                   ORDER BY m.id"""):
  2515	            print("%s  %-9s  %s  %s" % (row["global_id"], row["status"], row["created_at"],
  2516	                                        row["url"] or row["temp_id"]))
  2517	    finally:
  2518	        conn.close()
  2519	
  2520	
   120	    .trim();
   121	}
   122	
   123	function parseBullet(block) {
   124	  const text = block.map((line) => line.trim()).join(" ").replace(/\s+/g, " ").trim();
   125	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   126	  const title = titleMatch ? stripMarkdown(titleMatch[1]) : stripMarkdown(text.replace(/^- /, ""));
   127	
   128	  let status = "—";
   129	  for (const emoji of knownStatuses.concat(extraStatuses)) {
   130	    if (text.includes(emoji)) {
   131	      status = emoji;
   132	      break;
   133	    }
   134	  }
   135	
   136	  const links = [];
   137	  const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
   138	  let match;
   139	  while ((match = linkPattern.exec(text)) !== null) {
   140	    links.push(`[${match[1]}](${match[2]})`);
   141	  }
   142	
   143	  return { title, status, links };
   144	}
   145	
   146	function formatTally(items) {
   147	  const counts = new Map();
   148	  for (const emoji of knownStatuses) counts.set(emoji, 0);
   149	  const extras = [];
   150	
   151	  for (const item of items) {
   152	    if (counts.has(item.status)) {
   153	      counts.set(item.status, counts.get(item.status) + 1);
   154	      continue;
   155	    }
   156	    if (item.status !== "—") {
   157	      if (!counts.has(item.status)) extras.push(item.status);
   158	      counts.set(item.status, (counts.get(item.status) || 0) + 1);
   159	    }
   160	  }
   161	
   162	  const ordered = knownStatuses.slice();
   163	  for (const emoji of extras) {
   164	    if (!ordered.includes(emoji)) ordered.push(emoji);
   165	  }
   166	
   167	  return ordered.map((emoji) => `${emoji} ${counts.get(emoji) || 0}`).join(" · ");
   168	}
   169	
   170	const sections = new Map();
   171	for (const heading of ledgerSections) sections.set(heading, []);
   172	
   173	let inLedger = false;
   174	let currentSection = null;
   175	const droppedRows = [];
   176	
   177	for (let i = 0; i < lines.length; i++) {
   178	  const line = lines[i];
   179	
   180	  if (!inLedger) {
   181	    if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   182	    continue;
   183	  }
   184	
   185	  if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   186	
   187	  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   188	  if (sectionMatch) {
   189	    const heading = sectionMatch[1].trim();
   190	    currentSection = sections.has(heading) ? heading : null;
   191	    continue;
   192	  }
   193	
   194	  if (!currentSection) continue;
   195	
   196	  const trimmed = line.trim();
   197	  if (!trimmed || trimmed.startsWith("<!--") || trimmed.startsWith("#")) continue;
   198	
   199	  if (!/^- \*\*[^\r\n*]+?\*\*/.test(line)) {
   200	    // GH-257: track non-empty dropped/unparseable line under an active ledger section
   201	    const issueMatch = trimmed.match(/(?:GH-?|#)(\d+)/i);
   202	    const id = issueMatch ? `#${issueMatch[1]}` : JSON.stringify(trimmed.length > 30 ? trimmed.slice(0, 30) + "..." : trimmed);
   203	    droppedRows.push({ section: currentSection, id, line: trimmed });
   204	    continue;
   205	  }
   206	
   207	  const block = [line];
   208	  while (i + 1 < lines.length) {
   209	    const next = lines[i + 1];
   210	    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^\s*[-*+]\s+/.test(next)) break;
   211	    block.push(next);
   212	    i += 1;
   213	  }
   214	  sections.get(currentSection).push(parseBullet(block));
   215	}
   216	
   217	if (droppedRows.length > 0) {
   218	  const ids = droppedRows.map((d) => d.id).join(", ");
   219	  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
   220	}
   221	
   222	const output = [];
   223	output.push(banner);
   224	output.push("");
   225	output.push("# ROADMAP Dashboard");
   226	output.push("");
   227	output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
   228	output.push("");
   229	
   230	for (const heading of ledgerSections) {
   231	  const items = sections.get(heading) || [];
   232	  output.push(`## ${heading}`);
   233	  output.push("");
   234	  output.push(`Summary: ${items.length} items | Tally: ${formatTally(items)}`);
   235	  output.push("");
githooks/pre-push:87:if [ -x "$REPO/githooks/dashboard-staleness-guard.sh" ] && [ "${#_real_ref_pairs[@]}" -gt 0 ]; then
githooks/pre-push:93:  bash "$REPO/githooks/dashboard-staleness-guard.sh" "$REPO" "${_guard_args[@]}" || exit 1
validate.sh:519:  "gh243-dashboard-staleness-guard.sh" # GH-243 (push guard: ledger write without dashboard regen is refused)
test/gh257-roadmap-ledger-fixes.sh:13:GUARD="$root/githooks/dashboard-staleness-guard.sh"
test/gh243-dashboard-staleness-guard.sh:2:# test/gh243-dashboard-staleness-guard.sh — the GH-243 push guard: a roadmap-ledger write without a
test/gh243-dashboard-staleness-guard.sh:8:GUARD="$root/githooks/dashboard-staleness-guard.sh"

exec
/bin/zsh -lc "nl -ba utils/roadmap-dashboard.sh | sed -n '217,285p'
nl -ba test/gh257-roadmap-ledger-fixes.sh | sed -n '1,260p'
nl -ba githooks/pre-push | sed -n '70,105p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-24846-s8q1x7m2
 succeeded in 0ms:
   217	if (droppedRows.length > 0) {
   218	  const ids = droppedRows.map((d) => d.id).join(", ");
   219	  process.stderr.write(`roadmap-dashboard: warning: dropped ${droppedRows.length} unparseable row(s): ${ids}\n`);
   220	}
   221	
   222	const output = [];
   223	output.push(banner);
   224	output.push("");
   225	output.push("# ROADMAP Dashboard");
   226	output.push("");
   227	output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
   228	output.push("");
   229	
   230	for (const heading of ledgerSections) {
   231	  const items = sections.get(heading) || [];
   232	  output.push(`## ${heading}`);
   233	  output.push("");
   234	  output.push(`Summary: ${items.length} items | Tally: ${formatTally(items)}`);
   235	  output.push("");
   236	  output.push("| Item | Status | Links |");
   237	  output.push("| --- | --- | --- |");
   238	  for (const item of items) {
   239	    const links = item.links.length > 0 ? item.links.join(" · ") : "—";
   240	    output.push(`| ${escapeCell(item.title)} | ${escapeCell(item.status)} | ${links} |`);
   241	  }
   242	  if (items.length === 0) {
   243	    output.push("| — | — | — |");
   244	  }
   245	  output.push("");
   246	}
   247	
   248	process.stdout.write(output.join("\n"));
   249	NODE
   250	
   251	if [[ "$MODE" == "check" ]]; then
   252	  if [[ ! -f "$OUTPUT_FILE" ]]; then
   253	    echo "roadmap-dashboard: missing artifact: $OUTPUT_FILE" >&2
   254	    exit 1
   255	  fi
   256	  if cmp -s "$RENDERED" "$OUTPUT_FILE"; then
   257	    echo "roadmap-dashboard: artifact is in sync"
   258	    exit 0
   259	  fi
   260	  echo "roadmap-dashboard: artifact drift detected: $OUTPUT_FILE" >&2
   261	  diff -u "$OUTPUT_FILE" "$RENDERED" || true
   262	  exit 1
   263	fi
   264	
   265	cp "$RENDERED" "$OUTPUT_FILE"
   266	echo "roadmap-dashboard: wrote $OUTPUT_FILE"
     1	#!/usr/bin/env bash
     2	# test/gh257-roadmap-ledger-fixes.sh — regression suite for GH-257:
     3	# 1. validate --raw-text on roadmap add and update against renderer bold bullet shape (single line)
     4	# 2. emit warning on dropped unparseable rows in roadmap-dashboard.sh
     5	# 3. roadmap update subcommand for parked raw_text with auditable receipt and rating sync
     6	# 4. staleness guard diagnostic guidance when regeneration yields no diff
     7	set -euo pipefail
     8	source test/_setup.sh "GH-257" || { echo "setup failed"; exit 1; }
     9	
    10	root="$(cd "$HERE/.." && pwd)"
    11	app() { python3 "$root/utils/py/releases_app.py" "$@"; }
    12	RENDERER="$root/utils/roadmap-dashboard.sh"
    13	GUARD="$root/githooks/dashboard-staleness-guard.sh"
    14	
    15	R="$WORK/repo"
    16	mkdir -p "$R/utils/py"
    17	cp -r "$root/utils/"* "$R/utils/"
    18	cd "$R"
    19	git init -q .
    20	git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    21	echo "ROADMAP_SOURCE=releases" > .pdda-mode
    22	mkdir -p PROJECT/1-INBOX
    23	touch PROJECT/1-INBOX/GH-255-test.md
    24	
    25	app --root "$R" init --slug "test-repo"
    26	
    27	# -----------------------------------------------------------------------------
    28	# Case 1: roadmap add with malformed --raw-text is REFUSED at step 1
    29	# -----------------------------------------------------------------------------
    30	for bad_input in \
    31	  "- [ ] #255 malformed checkbox" \
    32	  "-   **GH-255 · repeated spaces** 🆕" \
    33	  "-	**GH-255 · tab after dash** 🆕" \
    34	  "- **GH-255 unclosed bold" \
    35	  "- **** empty title GH-255" \
    36	  $'- **GH-255 · title**\n- [ ] #999 smuggled row' \
    37	  $'- **GH-255 · title**\r\nmalformed continuation'
    38	do
    39	  rc=0
    40	  out="$(app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    41	    --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    42	    --raw-text "$bad_input" 2>&1)" || rc=$?
    43	
    44	  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' should be refused on add, got rc=0"
    45	  case "$out" in
    46	    *"rule=invalid-raw-text"*) pass "roadmap add refused malformed raw_text: '$bad_input'" ;;
    47	    *) fail "expected invalid-raw-text rule for '$bad_input', got: $out" ;;
    48	  esac
    49	done
    50	
    51	# -----------------------------------------------------------------------------
    52	# Case 2: roadmap add with mismatched issue number in --raw-text is REFUSED
    53	# -----------------------------------------------------------------------------
    54	rc=0
    55	out="$(app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    56	  --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    57	  --raw-text "- **GH-999 · wrong issue** 🆕" 2>&1)" || rc=$?
    58	
    59	[ "$rc" -ne 0 ] || fail "mismatched issue number in raw_text should be refused, got rc=0"
    60	case "$out" in
    61	  *"rule=invalid-raw-text"*"GH-255"*) pass "roadmap add refused mismatched issue number" ;;
    62	  *) fail "expected issue number mismatch refusal, got: $out" ;;
    63	esac
    64	
    65	# -----------------------------------------------------------------------------
    66	# Case 3: roadmap add with valid --raw-text SUCCEEDS
    67	# -----------------------------------------------------------------------------
    68	app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    69	  --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    70	  --raw-text "- **GH-255 · valid initial title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
    71	pass "roadmap add succeeded with valid raw_text"
    72	
    73	# -----------------------------------------------------------------------------
    74	# Case 4: roadmap update with symmetric negative controls is REFUSED
    75	# -----------------------------------------------------------------------------
    76	for bad_input in \
    77	  "- [ ] #255 bad update" \
    78	  "-   **GH-255 · extra spaces**" \
    79	  "-	**GH-255 · tab after dash**" \
    80	  "- **GH-255 unclosed title" \
    81	  "- **** empty title GH-255" \
    82	  $'- **GH-255 · title**\n- [ ] #999 bad line' \
    83	  $'- **GH-255 · title**\r\ncontinuation'
    84	do
    85	  rc=0
    86	  out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$bad_input" 2>&1)" || rc=$?
    87	  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' on update should be refused, got rc=0"
    88	  case "$out" in
    89	    *"rule=invalid-raw-text"*) pass "roadmap update refused malformed raw_text: '$bad_input'" ;;
    90	    *) fail "expected invalid-raw-text on roadmap update for '$bad_input', got: $out" ;;
    91	  esac
    92	done
    93	
    94	# -----------------------------------------------------------------------------
    95	# Case 5: roadmap update --dry-run prints changes and PROVABLY mutates nothing
    96	# -----------------------------------------------------------------------------
    97	raw_before="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
    98	out="$(app --root "$R" roadmap update --issue-num 255 \
    99	  --raw-text "- **GH-255 · dry run title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)" \
   100	  --dry-run)"
   101	case "$out" in
   102	  *"raw_text: "*"- **GH-255 · dry run title**"*) pass "roadmap update --dry-run reported planned diff" ;;
   103	  *) fail "expected dry-run diff output, got: $out" ;;
   104	esac
   105	raw_after="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
   106	[ "$raw_before" = "$raw_after" ] || fail "dry-run must not mutate database"
   107	pass "dry-run verified non-mutating against database"
   108	
   109	# -----------------------------------------------------------------------------
   110	# Case 6: roadmap update SUCCEEDS and generates roadmap-update receipt
   111	# -----------------------------------------------------------------------------
   112	NEW_TEXT="- **GH-255 · updated title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
   113	app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT"
   114	pass "roadmap update succeeded for GH-255"
   115	
   116	list_out="$(app --root "$R" roadmap list --json)"
   117	case "$list_out" in
   118	  *"- **GH-255 · updated title**"*) pass "roadmap list reflects updated raw_text" ;;
   119	  *) fail "roadmap list did not show updated raw_text: $list_out" ;;
   120	esac
   121	
   122	grep -q "roadmap-update" "$R/releases.sql" || fail "releases.sql missing roadmap-update receipt event"
   123	pass "releases.sql carries roadmap-update receipt"
   124	
   125	# -----------------------------------------------------------------------------
   126	# Case 7: roadmap update is IDEMPOTENT (no-op on unchanged text)
   127	# -----------------------------------------------------------------------------
   128	receipt_count_before="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
   129	out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT")"
   130	case "$out" in
   131	  *"unchanged; nothing written"*) pass "roadmap update idempotent when text unchanged" ;;
   132	  *) fail "expected unchanged text report, got: $out" ;;
   133	esac
   134	receipt_count_after="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
   135	[ "$receipt_count_before" -eq "$receipt_count_after" ] || fail "idempotent update must not write extra receipts"
   136	pass "idempotent update wrote zero additional receipts"
   137	
   138	# -----------------------------------------------------------------------------
   139	# Case 8: roadmap update synchronizes ALL FIVE rating columns
   140	# -----------------------------------------------------------------------------
   141	# Unrated -> Rated
   142	RATED_TEXT="- **GH-255 · rated title** 🆕 (rated 80/70/90/60 ovr 320) — [#255](https://github.com/org/repo/issues/255)"
   143	app --root "$R" roadmap update --issue-num 255 --raw-text "$RATED_TEXT"
   144	read pri sev app_score eff ovr <<<"$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number = 255" | tr '|' ' ')"
   145	[ "$pri" = "80" ] && [ "$sev" = "70" ] && [ "$app_score" = "90" ] && [ "$eff" = "60" ] && [ "$ovr" = "320" ] \
   146	  || fail "expected rating columns (80 70 90 60 320), got ($pri $sev $app_score $eff $ovr)"
   147	pass "roadmap update correctly populated all 5 rating columns"
   148	
   149	# Rated -> Unrated (must reset all 5 rating columns to NULL, not leave old scores)
   150	UNRATED_TEXT="- **GH-255 · unrated again** 🆕 — [#255](https://github.com/org/repo/issues/255)"
   151	app --root "$R" roadmap update --issue-num 255 --raw-text "$UNRATED_TEXT"
   152	cleared_counts="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE gh_number = 255 AND (rating_pri IS NOT NULL OR rating_sev IS NOT NULL OR rating_appeal IS NOT NULL OR rating_effort IS NOT NULL OR rating_ovr IS NOT NULL)")"
   153	[ "$cleared_counts" = "0" ] || fail "expected all rating columns to be NULL, found non-null values"
   154	pass "roadmap update correctly cleared all 5 rating columns to NULL on unrated line"
   155	
   156	# -----------------------------------------------------------------------------
   157	# Case 9: schema-behind refusal on pre-migration ledger without rating columns
   158	# -----------------------------------------------------------------------------
   159	R_OLD="$WORK/pre_migration_repo"
   160	mkdir -p "$R_OLD/utils/py"
   161	cp -r "$root/utils/"* "$R_OLD/utils/"
   162	cd "$R_OLD"
   163	git init -q .
   164	echo "ROADMAP_SOURCE=releases" > .pdda-mode
   165	mkdir -p PROJECT/1-INBOX
   166	touch PROJECT/1-INBOX/GH-100-test.md
   167	app --root "$R_OLD" init --slug "old-repo"
   168	app --root "$R_OLD" roadmap add --issue-num 100 --issue-url "https://github.com/org/repo/issues/100" \
   169	  --title "old 100" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-100-test.md" \
   170	  --raw-text "- **GH-100 · old initial** 🆕 — [#100](https://github.com/org/repo/issues/100)"
   171	
   172	# Simulate pre-migration schema by dropping rating columns
   173	sqlite3 "$R_OLD/releases.db" <<'EOSQL'
   174	CREATE TABLE roadmap_items_old AS SELECT id, global_id, repo_id, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at FROM roadmap_items;
   175	DROP TABLE roadmap_items;
   176	ALTER TABLE roadmap_items_old RENAME TO roadmap_items;
   177	EOSQL
   178	
   179	rc=0
   180	out="$(app --root "$R_OLD" roadmap update --issue-num 100 \
   181	  --raw-text "- **GH-100 · rated line on old ledger** 🆕 (rated 80/70/90/60) — [#100](https://github.com/org/repo/issues/100)" 2>&1)" || rc=$?
   182	[ "$rc" -ne 0 ] || fail "rated update against pre-migration ledger should be refused, got rc=0"
   183	case "$out" in
   184	  *"rule=schema-behind"*) pass "roadmap update refused rated line on pre-migration ledger with schema-behind" ;;
   185	  *) fail "expected schema-behind refusal, got: $out" ;;
   186	esac
   187	
   188	# -----------------------------------------------------------------------------
   189	# Case 10: renderer (utils/roadmap-dashboard.sh) emits stderr warning on dropped rows
   190	# -----------------------------------------------------------------------------
   191	MOCK_SRC="$WORK/mock_roadmap.md"
   192	cat > "$MOCK_SRC" <<'EOFMOCK'
   193	# ROADMAP
   194	## Ledger
   195	### Queue / parked intake
   196	- **GH-1 · valid row** 🟢 — [doc](doc.md)
   197	- [ ] #999 malformed row
   198	- #1000 another dropped bullet
   199	- **GH-1001 unclosed bold
   200	EOFMOCK
   201	
   202	MOCK_OUT="$WORK/mock_dashboard.md"
   203	err_out="$(ROADMAP_DASHBOARD_SOURCE="$MOCK_SRC" ROADMAP_DASHBOARD_OUTPUT="$MOCK_OUT" bash "$RENDERER" 2>&1 >/dev/null)" || true
   204	case "$err_out" in
   205	  *"roadmap-dashboard: warning: dropped 3 unparseable row(s): #999, #1000, #1001"*)
   206	    pass "renderer warned on dropped unparseable rows (including unclosed bold) on stderr"
   207	    ;;
   208	  *) fail "expected warning naming dropped rows #999, #1000, #1001, got: $err_out" ;;
   209	esac
   210	
   211	# -----------------------------------------------------------------------------
   212	# Case 11: End-to-end historical reproduction of malformed row diagnosis & fix
   213	# -----------------------------------------------------------------------------
   214	cd "$R"
   215	bash "$R/utils/roadmap-dashboard.sh"
   216	git add .pdda-mode releases.db releases.sql ROADMAP-DASHBOARD.md utils/ PROJECT/
   217	git -c user.email=t@t -c user.name=t commit -q -m "v1 clean base"
   218	BASE_COMMIT="$(git rev-parse HEAD)"
   219	
   220	# Simulate the historical bug: a malformed row (- [ ] #256 ...) is directly injected into ledger
   221	sqlite3 "$R/releases.db" <<'EOSQL'
   222	INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, status_marker, doc_path, issue_url, raw_text, first_seen, updated_at)
   223	VALUES ('rmi-01M0ZVV0000000000000000256', 1, 256, 'bad 256', 'Queue / parked intake', 99, '🆕', 'PROJECT/1-INBOX/GH-255-test.md', 'https://github.com/org/repo/issues/256', '- [ ] #256 historical malformed row', datetime('now'), datetime('now'));
   224	EOSQL
   225	python3 -c "import sys; sys.path.insert(0, '$root/utils/py'); import releases_app as rel; root = rel.resolve_root('$R'); conn = rel.connect(rel.artifact_paths(root)['db']); gen = rel.get_generation(conn); open(rel.artifact_paths(root)['dump'], 'w').write(rel.dump_text(conn, gen)); conn.close()"
   226	
   227	# 1. Regenerating dashboard yields warnings and dropped row:
   228	dash_warn="$(bash "$R/utils/roadmap-dashboard.sh" 2>&1 >/dev/null)" || true
   229	case "$dash_warn" in
   230	  *"warning: dropped 1 unparseable row(s): #256"*) pass "end-to-end: renderer detected injected malformed row #256" ;;
   231	  *) fail "expected dropped row warning for #256, got: $dash_warn" ;;
   232	esac
   233	
   234	# 2. Commit the ledger change only (dashboard unchanged because row was dropped)
   235	git add releases.db releases.sql
   236	git -c user.email=t@t -c user.name=t commit -q -m "ledger has bad row #256, dashboard unchanged"
   237	BAD_COMMIT="$(git rev-parse HEAD)"
   238	cd "$root"
   239	
   240	# 3. Staleness guard catches it and outputs no-diff diagnosis:
   241	# Add uncommitted modification in working tree to PROVE guard is isolated to commit projection
   242	echo "dirty working tree modification" >> "$R/ROADMAP-DASHBOARD.md"
   243	
   244	GUARD_TMP="$WORK/guard_isolated_tmp"
   245	mkdir -p "$GUARD_TMP"
   246	
   247	rc=0
   248	guard_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
   249	[ "$rc" -eq 1 ] || fail "guard should refuse bad commit, got $rc"
   250	case "$guard_out" in
   251	  *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
   252	    pass "end-to-end: staleness guard accurately diagnosed no-diff dropped row (even with dirty working tree)"
   253	    ;;
   254	  *) fail "expected no-diff diagnostic output from guard, got: $guard_out" ;;
   255	esac
   256	[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after no-diff refusal"
   257	pass "guard cleaned up temporary root after no-diff refusal"
   258	
   259	# Restore working tree
   260	git -C "$R" checkout ROADMAP-DASHBOARD.md
    70	  esac
    71	done
    72	if [ "$_saw_line" -eq 1 ] && [ "$_all_deletes" -eq 1 ]; then
    73	  echo "pre-push: delete-only push — no gate to run."
    74	  exit 0
    75	fi
    76	
    77	if [ "${XYZ_SKIP_PREPUSH:-0}" != "0" ]; then
    78	  # Announced, never silent: a skipped gate that says nothing is indistinguishable from a passing one.
    79	  echo "pre-push: SKIPPED by XYZ_SKIP_PREPUSH — nothing was verified before this push." >&2
    80	  exit 0
    81	fi
    82	
    83	# GH-243: deterministic dashboard-staleness guard — a roadmap-ledger write (releases.sql/.db)
    84	# without a ROADMAP-DASHBOARD.md regeneration is refused before any suite spends a second.
    85	# Releases-mode scoping, the range walk, and the refusal text live in the guard script (testable
    86	# on its own); it only ever ADDS a refusal and never substitutes for the gate below.
    87	if [ -x "$REPO/githooks/dashboard-staleness-guard.sh" ] && [ "${#_real_ref_pairs[@]}" -gt 0 ]; then
    88	  _guard_args=()
    89	  for _pair in "${_real_ref_pairs[@]}"; do
    90	    IFS='|' read -r _gl _gr <<<"$_pair"
    91	    _guard_args+=("$_gl" "${_gr:-0000000000000000000000000000000000000000}")
    92	  done
    93	  bash "$REPO/githooks/dashboard-staleness-guard.sh" "$REPO" "${_guard_args[@]}" || exit 1
    94	fi
    95	
    96	# A docs-only commit is still checked, but by the deterministic documentation gate instead of the
    97	# full runtime suite. Reuse the CI classifier rather than growing a second definition of "docs".
    98	# These routes are intentionally narrow: a new branch, force push, unavailable remote base, missing
    99	# classifier, non-linear history, or anything other than an exact `route=docs` (tier 1) or
   100	# `route=fast`+`tier=2` (registered utility subsystems) falls back to the full gate. A bad range
   101	# must cost time, never coverage.
   102	classify_push() {
   103	  [ -x "$REPO/utils/ci-route.sh" ] || return 1
   104	  [ "${#_real_ref_pairs[@]}" -gt 0 ] || return 1
   105	


consult: advisor failed or exceeded the 300s cap
