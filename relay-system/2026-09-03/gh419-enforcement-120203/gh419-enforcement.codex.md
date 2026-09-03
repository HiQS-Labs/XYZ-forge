**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-09-03T19:02:04.695540Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 94 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a068a6-4fcd-7481-87eb-e3b57d169ea4
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: vote APPROVE or REVISE on GH-419's design

Read `PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md` in this worktree. Also read, because the design claims to reuse them rather than invent anything:

- `GUIDING-PRINCIPLES.md` — the section "Marathon builder default & plan location (GH-212)"
- `validate.sh` lines 16–53 — the GH-45 linked-worktree refusal and its announced override
- `relay-automation/driver-lock-lib.sh` lines 12–35 — the `--git-common-dir` lock resolver
- `test/gh35-test-tiers.sh` lines 337–380 — especially the CONTROL at 367–370
- `relay-automation/marathon.sh` — the orchestrator being modified
- `AGENTS.md` §13 (red-control rule) and the frozen-twin policy around line 230

## Background you need

Three marathon process rules are currently documented-only in `skills/marathon-triage/SKILL.md` §0b/§0c and enforced by nothing:

1. Every marathon has a GitHub umbrella tracking issue.
2. Every marathon runs in a full clone — never a linked worktree, never the primary checkout.
3. Clone folders are named `marathon-gh-<umbrella>-<short-description>`.

Measured evidence that they are not followed: at least eight marathons appear in committed transcripts against **two** rows in the `marathons` ledger table; live clone folders are `gh271-waveA`, `gh396-phase0`, `gh405-mock-board` — a wave label, a phase number and a feature name under one shape — with `gh-8-…` / `gh-115-…` in older transcripts using a different separator.

The proposal: add three conditions to the refusal block that **already exists** in `marathon.sh --plan` (per GH-212 it already refuses exit 2 for a plan outside `PROJECT/2-WORKING/`), plus exactly one new `MARATHON.yaml` key (`umbrella:`). No new script, module, config file, or write path.

## Vote on exactly these

**1. APPROVE or REVISE the overall design.** Judge through a strict YAGNI / "laziest thing that actually works" lens. Specifically:
   - Does anything here invent a subsystem, module, abstraction or write path it does not need?
   - Is extending `marathon.sh`'s existing GH-212 refusal genuinely the cheapest reliable hook, or is there a cheaper one already in the tree that was missed? (Consider: `swarm-preflight.sh`, `validate.sh`, a PDDA check, the ledger CLI, a git hook.)
   - Is `umbrella:` in `MARATHON.yaml` the right single new input, or is there an existing field that already carries the marathon's identity?

**2. Rule specifically on the open question — should rule 2 refuse the PRIMARY CHECKOUT?**
   This is the one rule with no precedent in the tree. GH-45 deliberately *allows* the primary checkout for `validate.sh`, and `test/gh35-test-tiers.sh:367-370` asserts that as an explicit CONTROL. Refusing it for marathons is a new posture, not an extension of an existing one. Answer directly: **refuse it, warn on it, or drop that half of rule 2 entirely?** Give your reasoning in two or three sentences, and say what breaks if you are wrong.

**3. Name the single biggest risk in the plan as written** — the thing most likely to make this ship and then be quietly bypassed, or to refuse a legitimate marathon. Rule 3's name regex is a candidate (too strict and it refuses every real marathon while looking like a working guard) but say what you actually think.

## What "good" looks like in your answer

- A clear **APPROVE** or **REVISE** in the first line. If REVISE, list the specific changes required, each one a concrete edit.
- A direct verdict on the primary-checkout question — do not hedge to "it depends".
- Cite file:line for any claim about what the tree currently does. If you cannot verify something, say so rather than assuming.
- Be blunt about over-engineering. If a rule is not worth enforcing mechanically at all — if a doc line and reviewer attention are the correct amount of machinery — say that plainly. Saying "enforce less" is a valid and welcome answer.
- Do not write or modify any files. Advisory only.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the referenced design and enforcement points, then give an independent approve/revise vote with line citations.
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (completed)
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (completed)
mcp: codebase-memory-mcp/check_index_coverage started
mcp: codebase-memory-mcp/check_index_coverage (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "nl -ba relay-automation/driver-lock-lib.sh | sed -n '1,70p' && nl -ba test/gh35-test-tiers.sh | sed -n '337,380p' && nl -ba skills/marathon-triage/SKILL.md | sed -n '1,120p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
exec
/bin/zsh -lc "nl -ba relay-automation/marathon.sh | sed -n '1,430p' && nl -ba AGENTS.md | sed -n '180,270p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
     3	#
     4	# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
     5	# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
     6	# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
     7	# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
     8	# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
     9	# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
    10	# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
    11	#
    12	#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
    13	#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
    14	#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
    15	#
    16	# API:
    17	#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
    18	set -u
    19	
    20	driver_lock_path_for_repo() {
    21	  local repo="$1"
    22	  if [ -d "$repo/.git" ]; then
    23	    printf '%s/.git/relay-driver.lock' "$repo"
    24	    return 0
    25	  fi
    26	  if [ -f "$repo/.git" ]; then
    27	    local common
    28	    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    29	    if [ -n "$common" ]; then
    30	      printf '%s/relay-driver.lock' "$common"
    31	      return 0
    32	    fi
    33	  fi
    34	  printf '%s/.relay-driver.lock' "$repo"
    35	}
   337	# ── (9) GH-45: the gate REFUSES to run from a linked worktree ────────────────────────────────────
   338	# The 2026-08-19 incident: a gate run from a linked worktree corrupted the PARENT clone (shared
   339	# .git) — core.bare=true, origin repointed at a deleted temp path, every refs/remotes/origin/*
   340	# deleted, development overwritten with fixture commits. The guard must refuse BEFORE anything
   341	# runs, name those consequences (an operator who doesn't know what breaks will override), honor
   342	# the explicit override, and stay silent in a normal clone — the last one is the control that
   343	# proves the guard FIRES rather than merely that the gate still works.
   344	R7="$(mkfixture)"
   345	cp "$REPO/ci-local.sh" "$R7/ci-local.sh"; chmod +x "$R7/ci-local.sh"
   346	git -C "$R7" add -A >/dev/null 2>&1 && git -C "$R7" commit -qm gate >/dev/null 2>&1
   347	WT45="$WORK/wt45"
   348	git -C "$R7" worktree add -q "$WT45" -b wt45 >/dev/null 2>&1
   349	require_fixture "$WT45" "GH-45 fixture worktree"
   350	
   351	out="$( cd "$WT45" && bash validate.sh --tier 1 2>&1 )"; rc=$?
   352	ok "GH-45: a linked worktree is REFUSED before anything runs (exit 2)" "[ $rc -eq 2 ]"
   353	ok "  and the message names the real consequence (core.bare)" \
   354	   "printf '%s' \"\$out\" | grep 'core.bare=true' >/dev/null"
   355	ok "  and names the rest (origin repointed, remote refs deleted, development overwritten)" \
   356	   "printf '%s' \"\$out\" | grep 'deleted every refs/remotes/origin' >/dev/null && printf '%s' \"\$out\" | grep 'development with fixture commits' >/dev/null"
   357	ok "  and names the explicit override" \
   358	   "printf '%s' \"\$out\" | grep 'XYZ_ALLOW_WORKTREE_GATE=1' >/dev/null"
   359	ok "  and NOTHING ran — no docs gate, no suite banners" \
   360	   "! printf '%s' \"\$out\" | grep -E 'stub-pdda ran|^Running ' >/dev/null"
   361	
   362	out="$( cd "$WT45" && XYZ_ALLOW_WORKTREE_GATE=1 bash validate.sh --tier 1 2>&1 )"; rc=$?
   363	ok "GH-45: the override runs the gate AND announces itself (exit $rc)" \
   364	   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'explicit request' >/dev/null && printf '%s' \"\$out\" | grep 'stub-pdda ran' >/dev/null"
   365	
   366	# THE CONTROL: the same fixture's MAIN checkout must still run — this is what distinguishes a
   367	# guard that fires from a gate that simply never worked.
   368	out="$( cd "$R7" && bash validate.sh --tier 1 2>&1 )"; rc=$?
   369	ok "GH-45 CONTROL: the normal checkout of the SAME repo still runs the gate (exit $rc)" \
   370	   "[ $rc -eq 0 ] && printf '%s' \"\$out\" | grep 'stub-pdda ran' >/dev/null"
   371	ok "  and says nothing about worktrees (silent pass-through)" \
   372	   "! printf '%s' \"\$out\" | grep -i 'worktree' >/dev/null"
   373	
   374	# ci-local.sh runs the SAME suite, so it carries the same guard (issue requirement 4).
   375	out="$( cd "$WT45" && bash ci-local.sh --fast 2>&1 )"; rc=$?
   376	ok "GH-45: ci-local.sh refuses from a linked worktree too (exit 2)" "[ $rc -eq 2 ]"
   377	ok "  with the same consequence message and override" \
   378	   "printf '%s' \"\$out\" | grep 'core.bare=true' >/dev/null && printf '%s' \"\$out\" | grep 'XYZ_ALLOW_WORKTREE_GATE=1' >/dev/null"
   379	# Invoking validate.sh by ABSOLUTE path from OUTSIDE the worktree must not slip past: HERE
   380	# itself is checked, not just the CWD.
     1	---
     2	name: marathon-triage
     3	description: >
     4	  Triage PDDA intake and active work into a ranked, preflight-checked, collision-safe marathon
     5	  candidate list. Reconcile GH capture docs with live issue state, identify missing or stale
     6	  preflight contracts, run dry-run readiness checks, and group disjoint write-sets into safe waves.
     7	  Use when asked to triage the inbox, build or refresh a marathon queue, choose work to swarm next,
     8	  identify concurrent issues, or plan a marathon without executing it. Requires this repo's
     9	  PROJECT lifecycle, ROADMAP ledger, and swarm-preflight.sh / marathon-plan.sh resolved from the
    10	  harness root (bare repo root or a vendored `.xyz/` install — see Workflow Step 0).
    11	---
    12	
    13	# Marathon triage
    14	
    15	Produce an honest, ranked marathon plan without firing work. Treat `PROJECT/**` as the execution
    16	record, GitHub as the live signal stream, and deterministic preflight output as stronger than prose.
    17	
    18	## Guardrails
    19	
    20	- Read `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ROADMAP.md`, and `PROJECT/PDDA.md` first.
    21	- Default to read-only. Do not move docs, promote intake, author contracts, close issues, generate a
    22	  plan file, cut a branch, or fire a marathon without explicit operator confirmation.
    23	- Never override a deterministic PDDA or preflight finding with narrative judgment.
    24	- Use the repo's standing target branch policy. Do not invent a branch or silently substitute a
    25	  builder.
    26	- If GitHub is unavailable, mark live-state evidence `UNKNOWN`; do not infer it from stale local text.
    27	
    28	## Workflow
    29	
    30	### 0. Resolve the harness root
    31	
    32	`swarm-preflight.sh` and `marathon-plan.sh` may live at the repo root or, in a vendored install,
    33	under `.xyz/`. Resolve once, using the same precedence as other self-locating skills in this repo
    34	(env override → vendored `.xyz/` → current repo root):
    35	
    36	```bash
    37	HARNESS="${XYZ_HARNESS:-${XYZ_REPO_ROOT:-}}"
    38	[ -n "$HARNESS" ] || HARNESS="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    39	[ -x "$HARNESS/.xyz/utils/swarm-preflight.sh" ] && HARNESS="$HARNESS/.xyz"
    40	```
    41	
    42	Reference every script below as `$HARNESS/utils/swarm-preflight.sh` and
    43	`$HARNESS/utils/marathon-plan.sh` — not bare `utils/...` paths, which resolve to nothing (or to an
    44	unrelated `utils/` directory) in a vendored `.xyz/` install.
    45	
    46	### 0b. Every marathon has an umbrella tracking issue — open it first
    47	
    48	**A marathon without a GitHub umbrella issue does not start.** The umbrella is the marathon's
    49	identity: waves, clone folder, ledger row and closeout all key off its number.
    50	
    51	Today this is under-enforced and the gap is measurable: `releases_app.py marathon add` requires
    52	`--tracking-issue` (`utils/py/releases_app.py:4901`) and `marathons.tracking_ref_id` is `NOT NULL`
    53	(`:479`) — but the executor never reads either. `marathon_drive.py` has no `--tracking-issue` flag
    54	and the `MARATHON.yaml` schema has no field for one, so the requirement binds only if someone
    55	chooses to create the ledger row. Most runs have not: **at least eight marathons are visible in
    56	committed transcripts and `marathon-system/`, against two rows in the `marathons` table.**
    57	
    58	Procedure, before any triage work:
    59	
    60	1. Open the umbrella issue. Title it for the arc, not the first item. Body lists the candidate
    61	   member issues, the wave sketch, and the acceptance rule for the marathon as a whole.
    62	2. Register it in the ledger immediately:
    63	   ```bash
    64	   python3 "$HARNESS/utils/py/releases_app.py" marathon add \
    65	     --tracking-issue https://github.com/<org>/<repo>/issues/<n> --status planned
    66	   ```
    67	   Offline, `TMP-XXXXXX` is an accepted placeholder — but reconcile it before the marathon closes,
    68	   or the ledger row permanently names an issue that does not exist. The token is **shape-checked
    69	   only** (`check_tracking_token`, `:1675-1694`); GitHub is never queried, so a typo in the URL is
    70	   accepted silently.
    71	3. Dial every member issue into the same release, and link them to this marathon.
    72	
    73	Carry the umbrella number into every downstream artifact: the clone folder name (step 0c), the
    74	plan doc, each phase brief, and the closeout. If you cannot name the umbrella issue, you are not
    75	ready to triage — you are still deciding what the marathon is.
    76	
    77	### 0c. Marathons run in a full clone, deterministically named
    78	
    79	**Two rules, both currently unenforced by code.** State them explicitly in the plan so a reviewer
    80	can check them.
    81	
    82	**A full clone, never a linked worktree and never the primary checkout.** The mechanism that makes
    83	this necessary is real but indirect: `validate.sh:16-53` refuses to run inside a linked worktree
    84	(GH-45, exit 2), and `driver_lock_path_for_repo` (`relay-automation/driver-lock-lib.sh:20-35`)
    85	resolves a linked worktree's lock to its **parent's** `.git/relay-driver.lock`, so a worktree
    86	cannot run a second driver concurrently. Nothing refuses a marathon launched from the primary
    87	checkout — `test/gh35-test-tiers.sh:367-370` proves the primary checkout runs the gate normally —
    88	so this rule is on the operator, not the harness.
    89	
    90	**Clone folder name is derived, not chosen:**
    91	
    92	```
    93	marathon-gh-<umbrella-issue-number>-<short-description>
    94	```
    95	
    96	`<short-description>` is lowercase, hyphen-separated, three words or fewer, describing the arc —
    97	not a wave label, not a phase number. One clone per marathon; a second attempt at the same arc
    98	reuses the name with a `-r2` suffix rather than inventing a new slug.
    99	
   100	```bash
   101	CLONE="$HOME/marathon-clones/marathon-gh-${UMBRELLA}-${SLUG}"
   102	git clone <remote> "$CLONE"
   103	```
   104	
   105	This replaces the current free-form convention, which has drifted badly and is the reason a
   106	salvage operation once could not find its own artifacts: live folders are `gh271-waveA`,
   107	`gh396-phase0` and `gh405-mock-board` — a wave label, a phase number and a feature name, three
   108	different meanings under one shape — while committed transcripts also show `gh-8-…` and `gh-115-…`
   109	with a different separator, plus a `gh-115-clean` retry folder with no stated relationship to its
   110	original.
   111	
   112	### 1. Inventory intake and active work
   113	
   114	List open issues and all issue capture docs in deterministic order:
   115	
   116	```bash
   117	gh issue list --state open --limit 200 --json number,title,labels \
   118	  --jq 'sort_by(.number) | .[] | "\(.number)\t\(.title)\t[\(.labels|map(.name)|join(","))]"'
   119	
   120	find PROJECT/1-INBOX PROJECT/2-WORKING -maxdepth 1 -type f \

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
    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
    16	#                                [--pre-advance-cmd CMD] [--dry-run] [--retry PHASE-ID]
    17	#
    18	# GH-212: default builder is `codex` — no per-call API charge (bills via the Codex/ChatGPT
    19	# subscription; agy is the other cost-blind option). `--builder claude` spawns a headless Claude
    20	# Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker, distinct from an
    21	# interactive session. Use it only as an explicit, cost-acknowledged choice.
    22	#
    23	# GH-212: a plan's `--plan` YAML (+ its phase briefs) must resolve under PROJECT/2-WORKING/ in the
    24	# target repo — not a standalone top-level folder (e.g. marathon-plans/<slug>/) an agent might
    25	# pattern-match from a prior repo. Exempt: paths under this harness's own home (MARATHON_HOME —
    26	# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    27	#
    28	# GH-116: --retry <phase-id> recovers a phase whose relay task was left open/never-claimed
    29	# (permanently spent, per this repo's claim-then-abandon constraint) WITHOUT manually renaming the
    30	# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
    31	# MARATHON-<ID>-TURN-<N> suffix (N starts at 2, checked via `tick info`) — every other phase derives
    32	# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
    33	# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
    34	#
    35	# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
    36	# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
    37	# max_review_rounds→--round-cap.
    38	#
    39	# Environment overrides (for tests):
    40	#   MARATHON_HOME       — harness home (default: parent of this script's dir)
    41	#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
    42	#                         falling back to MARATHON_HOME outside a git repo)
    43	#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
    44	#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
    45	#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
    46	#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
    47	#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
    48	# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
    49	#
    50	# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
    51	
    52	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    53	MARATHON_HOME="${MARATHON_HOME:-"$(cd "$HERE/.." && pwd)"}"
    54	if [[ -n "${MARATHON_ROOT:-}" ]]; then
    55	  ROOT="$MARATHON_ROOT"
    56	elif ROOT="$(git -C "${PWD:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
    57	  :
    58	else
    59	  ROOT="$MARATHON_HOME"
    60	fi
    61	TICK_BIN="${TICK_BIN:-"$MARATHON_HOME/bin/tick"}"
    62	DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
    63	YAML_BIN="${MARATHON_YAML_BIN:-"$MARATHON_HOME/bin/marathon-yaml"}"
    64	CLOSEOUT_BIN="${MARATHON_CLOSEOUT_BIN:-"$MARATHON_HOME/relay-automation/marathon-closeout.sh"}"
    65	
    66	die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
    67	log() { printf 'marathon: %s\n' "$*"; }
    68	
    69	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$MARATHON_HOME/utils/telemetry/append-xyz-completion.sh"}"
    70	
    71	# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
    72	# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
    73	# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
    74	# run isn't silently absent from XYZ.json (GH-75 review: an early halt used to skip the tail entirely,
    75	# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
    76	xyz_marathon_run_emit() {  # <health> <description>
    77	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
    78	  local plan; plan="$(basename "$PLAN")"; plan="${plan%.*}"; [[ -n "$plan" ]] || plan="marathon"
    79	  "$XYZ_APPEND_BIN" marathon "$plan" "$1" "$plan" "$2" >/dev/null 2>&1 || true
    80	}
    81	
    82	usage() {
    83	  cat <<'EOF'
    84	Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
    85	                    [--dry-run] [--force] [--retry PHASE-ID] [--closeout-pr]
    86	
    87	  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
    88	                          the target repo (GH-212) — exempt: paths under this harness's own home
    89	                          (shipped examples), or MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    90	  --builder AGENT         Builder agent id (default: codex — no per-call API charge; bills via the
    91	                          Codex/ChatGPT subscription). --builder claude spawns a headless Claude
    92	                          Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker —
    93	                          an explicit, cost-acknowledged choice, not the default.
    94	  --phases-dir DIR        Where to create <dir>/<id>/ (default: <repo-root>/marathon-system).
    95	  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
    96	                          The relay thread, tick token, marathon-system/ and relay-system/ transcripts all stay
    97	                          in THIS harness repo — only code changes land in DIR. Use this when the target
    98	                          repo cannot track harness output (e.g. a public repo that gitignores marathon-system/
    99	                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
   100	                          RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.
   101	                          Plan and brief paths resolve against DIR when set.
   102	                          GH-255 — pick the right knob for what is actually ignored: if the target
   103	                          ignores ONLY relay-system/, prefer XYZ_ARCHIVE_ROOT (GH-30), which
   104	                          redirects just the transcripts and leaves the code artifact and the
   105	                          .tick token anchored to the target. --target-root is the answer when
   106	                          marathon-system/ is ignored too, because XYZ_ARCHIVE_ROOT does not
   107	                          redirect RELAY.md / ESCALATION.md and will leave that run blocked.
   108	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
   109	  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
   110	  --force                 GH-45: bypass the per-lane attempt cap for this run.
   111	  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix. This REBUILDS the
   112	                          phase — a full builder + reviewer cycle — because a retry must never be
   113	                          satisfied by the attempt it was invoked to retry.
   114	                          GH-491: if the phase's relay is already terminal (STATUS: Approved) and its
   115	                          token is done, and only the GATE went red, do NOT use this. Re-fire the plan
   116	                          plainly instead: the driver detects the satisfied lane and re-runs only the
   117	                          pre-advance gate, dispatching no turns. Use --retry when the ARTIFACT is what
   118	                          needs to change.
   119	  --closeout-pr           Open (but never merge) a PR after a successful marathon. Closeout failure is logged
   120	                          and does not change the successful marathon exit code.
   121	EOF
   122	}
   123	
   124	PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
   125	TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
   126	while (($# > 0)); do
   127	  case "$1" in
   128	    --plan)            PLAN="${2:-}"; shift 2 ;;
   129	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   130	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   131	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   132	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   133	    --dry-run)         DRY_RUN=1; shift ;;
   134	    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
   135	    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
   136	    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
   137	    --help)            usage; exit 0 ;;
   138	    *)                 die "unknown argument: $1" ;;
   139	  esac
   140	done
   141	[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
   142	[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
   143	
   144	# GH-212: plan-location guard. A marathon's plan artifacts (this YAML + its phase briefs) belong
   145	# under PROJECT/2-WORKING/<capture-doc>/, not a standalone top-level folder (e.g. marathon-plans/)
   146	# an agent might pattern-match from a prior repo. Exempt: paths under this harness's own home
   147	# (MARATHON_HOME) — shipped reference examples (e.g. MARATHON.example.yaml), not an agent-authored
   148	# plan for a target repo. Override for a legitimate non-default location:
   149	# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
   150	_plan_abs="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
   151	# Canonicalize with `pwd -P` unconditionally (relative AND already-absolute input): ROOT can come
   152	# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
   153	# (whatever form the caller passed), so either side of this comparison can be a logical (non -P)
   154	# path — canonicalize both or a macOS /var -> /private/var checkout falsely flags every plan.
   155	# symlinks (e.g. macOS /var -> /private/var), so a logical (non -P) comparison here would falsely
   156	# flag every plan as "outside" on such a checkout (same pitfall swarm-preflight.sh works around).
   157	# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
   158	# so this guard must measure against that repo — otherwise every cross-repo plan falsely "resolves
   159	# outside PROJECT/2-WORKING/" and dies. GH-212's intent is unchanged: the plan must sit under
   160	# PROJECT/2-WORKING/ of whichever repo owns it.
   161	_plan_base="${TARGET_ROOT:-$ROOT}"
   162	_root_canon="$(cd "$_plan_base" 2>/dev/null && pwd -P || printf '%s' "$_plan_base")"
   163	_home_canon="$(cd "$MARATHON_HOME" 2>/dev/null && pwd -P || printf '%s' "$MARATHON_HOME")"
   164	_plan_rel_root="${_plan_abs#"$_root_canon"/}"
   165	case "$_plan_rel_root" in
   166	  PROJECT/2-WORKING/*) ;;   # in the expected home — proceed
   167	  *)
   168	    case "$_plan_abs" in
   169	      "$_home_canon"/*) ;;   # harness-owned reference material — exempt
   170	      *)
   171	        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
   172	          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
   173	        fi
   174	        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
   175	        ;;
   176	    esac
   177	    ;;
   178	esac
   179	
   180	export TICK_REPO_ROOT="$ROOT"
   181	
   182	# ── GH-388: the chain run log ────────────────────────────────────────────────────────────────────
   183	# This file persisted NOTHING of its own — no tee, no `exec >`, no log-file variable. What was
   184	# durable got written per phase, ON COMPLETION, so the phase that DIES is the one phase with no
   185	# record, and the chain-level narrative existed only on the operator's terminal. Whether any of it
   186	# survived a crash depended on whether whoever typed the command happened to redirect stdout
   187	# somewhere durable. In the run that produced this issue they had — to a path the platform clears at
   188	# boot — and after the panic reboot it was gone.
   189	#
   190	# Where the run narrative goes is the HARNESS's decision now, not the invoker's. Same transcript root
   191	# the per-phase transcripts already use (rtl_transcript_root), so one place holds both.
   192	#
   193	# Armed here, deliberately AFTER plan parse/validate and BEFORE the phase loop: a usage error, an
   194	# unparseable plan or a --plan outside PROJECT/2-WORKING has no run to narrate, and must not leave an
   195	# empty log implying one happened. --dry-run is excluded for the same reason.
   196	MARATHON_RUN_LOG=""
   197	if ((DRY_RUN == 0)); then
   198	  # Sourced only if present. MARATHON_HOME is overridable (tests point it at a minimal fake home,
   199	  # and a vendored `.xyz/` install may lag a re-vendor), so an unconditional `source` turns a missing
   200	  # optional helper into a dead marathon — which is how this first landed, breaking the GH-212
   201	  # harness-home-exempt case. A missing lib costs the durability CHECK, not the run log.
   202	  _dl_lib="$MARATHON_HOME/relay-automation/durable-log-lib.sh"
   203	  if [[ -f "$_dl_lib" ]]; then
   204	    # shellcheck source=/dev/null
   205	    source "$_dl_lib"
   206	  else
   207	    xyz_non_durable_reason() { :; }
   208	    xyz_non_durable_conf() { printf '(durable-log-lib.sh not installed)'; }
   209	    _xyz_realish_path() { printf '%s' "${1:-}"; }
   210	  fi
   211	  # Resolved by SOURCING the shared resolver rather than re-deriving `<root>/relay-system` here — a
   212	  # second copy of that rule is how the run log and the per-phase transcripts would end up in
   213	  # different places the first time XYZ_ARCHIVE_ROOT's contract changed.
   214	  # `|| _run_log_base=""` is load-bearing: under `set -e` an assignment whose command substitution
   215	  # exits non-zero terminates the script, so a fake/partial MARATHON_HOME turned "the resolver is
   216	  # unavailable" into a bare exit 127 with no message — the shape of failure this whole issue is
   217	  # about, reproduced by its own fix. Caught by test/marathon.sh's GH-212 harness-home-exempt case.
   218	  _run_log_base="$(set +e; source "$MARATHON_HOME/relay-automation/relay-turn-lib.sh" >/dev/null 2>&1; rtl_transcript_root "$ROOT" 2>/dev/null)" || _run_log_base=""
   219	  if [[ -z "$_run_log_base" ]]; then
   220	    # The resolver was unavailable (partial install / fake home), NOT unresolvable. Those are
   221	    # different failures and only the second deserves a hard stop: with XYZ_ARCHIVE_ROOT unset the
   222	    # documented default is <root>/relay-system, and a run that can record itself there should.
   223	    if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
   224	      _run_log_base="$ROOT/relay-system"
   225	    else
   226	      die "XYZ_ARCHIVE_ROOT is set but no durable transcript root could be resolved from it — fix it, or unset it to use <root>/relay-system (GH-388). A marathon that cannot record itself must not start."
   227	    fi
   228	  fi
   229	
   230	  # Scoped to RELOCATION, matching rtl_default_log: a run log inside the repo being driven shares
   231	  # that repo's fate; one outside it, in storage a reboot erases, is the silent relocation this
   232	  # issue is about. Without the scoping every fixture repo under $TMPDIR would refuse to run.
   233	  _run_log_reason="$(xyz_non_durable_reason "$_run_log_base")"
   234	  if [[ -n "$_run_log_reason" ]] && [[ "$(_xyz_realish_path "$_run_log_base")" != "$(_xyz_realish_path "$ROOT")"/* ]]; then
   235	    die "the resolved run-log root $_run_log_base is under $_run_log_reason, which this harness records as non-durable storage ($(xyz_non_durable_conf)), and it is OUTSIDE the repo being driven ($ROOT). A marathon's own record must survive a reboot — that is the whole of GH-388. Point XYZ_ARCHIVE_ROOT at a committed archive, or unset it."
   236	  fi
   237	
   238	  _run_log_dir="$_run_log_base/run-logs/$(date +%Y-%m-%d 2>/dev/null || echo unknown-date)"
   239	  mkdir -p "$_run_log_dir" || die "could not create the run-log directory $_run_log_dir"
   240	  _plan_slug="$(basename "${PLAN%.*}" | tr -c 'A-Za-z0-9._-' '_')"
   241	  MARATHON_RUN_LOG="$_run_log_dir/marathon-${_plan_slug}-$(date +%H%M%S 2>/dev/null || echo unknown)-$$.log"
   242	  export MARATHON_RUN_LOG
   243	
   244	  # `tee -a` via process substitution, so output is captured AS IT IS PRODUCED rather than buffered
   245	  # to the end — the whole point is that the record survives a run that never reaches its end.
   246	  # stderr is folded in: an escalation reason arriving on stderr and a phase heading on stdout,
   247	  # interleaved in one file, is the narrative an operator actually needs to read afterwards.
   248	  exec > >(tee -a "$MARATHON_RUN_LOG") 2>&1
   249	  # Printed at chain start, per acceptance: an operator has to know where to look afterwards, and
   250	  # afterwards is exactly when the terminal is gone.
   251	  log "run log: $MARATHON_RUN_LOG"
   252	fi
   253	
   254	# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
   255	PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
   256	[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
   257	PLAN_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PLAN" | head -n1 | sed 's/[[:space:]]*$//')"
   258	phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
   259	log "plan: $PLAN — $phase_count phase(s) in execution order"
   260	
   261	idx=0
   262	# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
   263	# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
   264	# tabs → \037 so empty fields (no rounds / no depends_on / no artifact / no turn_timeout_s) are
   265	# preserved positionally.
   266	while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact turn_timeout_s name; do
   267	  [[ -n "$id" ]] || continue
   268	  idx=$((idx + 1))
   269	  rounds="${rounds:-2}"
   270	  cap=$((2 * rounds + 1))
   271	  lane_ns=""
   272	  [[ -n "$PLAN_NAME" ]] && lane_ns="${PLAN_NAME}--${id}"
   273	  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
   274	  # Briefs live beside the plan, so they resolve against the repo the plan came from. On a
   275	  # --target-root run that is the TARGET repo, not this harness — resolving against $ROOT would
   276	  # look for the target's briefs inside the harness clone and die "brief file not found".
   277	  brief_base="${TARGET_ROOT:-$ROOT}"
   278	  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$brief_base/$brief" ;; esac
   279	  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"
   280	
   281	  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}${turn_timeout_s:+, turn-timeout=${turn_timeout_s}s}) ──"
   282	
   283	  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
   284	               --phase-brief "$brief_path" --round-cap "$cap" )
   285	  [[ -n "$PHASES_DIR" ]] && drive_args+=( --phases-dir "$PHASES_DIR" )
   286	  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
   287	  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
   288	  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
   289	  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
   290	  # GH-116: only the phase named by --retry gets a task-name override — every other phase still lets
   291	  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
   292	  if [[ -n "$RETRY_PHASE" && "$id" == "$RETRY_PHASE" ]]; then
   293	    id_upper="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
   294	    retry_n=2
   295	    # First unused suffix, not a hardcoded -2: keep bumping while that task name already exists
   296	    # (tick info exits 0 once a task has any recorded state — spent or not, it's not reusable).
   297	    while "$TICK_BIN" info "MARATHON-${id_upper}-TURN-${retry_n}" >/dev/null 2>&1; do
   298	      retry_n=$((retry_n + 1))
   299	    done
   300	    retry_task="MARATHON-${id_upper}-TURN-${retry_n}"
   301	    log "phase $id: --retry requested — overriding relay task to $retry_task (first unused suffix)"
   302	    drive_args+=( --relay-task "$retry_task" )
   303	  fi
   304	  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi
   305	
   306	  phase_exit=0
   307	  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
   308	  # stays silent — this orchestrator emits a SINGLE harness:"marathon" whole-run record below, never
   309	  # one per phase.
   310	  if [[ -n "$turn_timeout_s" ]]; then
   311	    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
   312	      RELAY_TURN_TIMEOUT_S="$turn_timeout_s" \
   313	      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
   314	  else
   315	    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
   316	      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
   317	  fi
   318	  if [[ "$phase_exit" -ne 0 ]]; then
   319	    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
   320	    case "$phase_exit" in
   321	      3) _halt_reason="relay no-progress" ;;
   322	      4) _halt_reason="relay cap/close-mismatch" ;;
   323	      5) _halt_reason="pre-advance gate failed" ;;
   324	      6) _halt_reason="containment violation" ;;
   325	      7) _halt_reason="turn timeout / hang" ;;
   326	      *) _halt_reason="marathon-drive exit $phase_exit" ;;
   327	    esac
   328	    xyz_marathon_run_emit red "halted at phase $idx of $phase_count ($id) — $_halt_reason"
   329	    exit "$phase_exit"
   330	  fi
   331	done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')
   332	
   333	if ((DRY_RUN)); then
   334	  log "dry-run complete: $phase_count phase(s) would run in order"
   335	  exit 0
   336	fi
   337	
   338	if ((CLOSEOUT_PR)); then
   339	  closeout_plan="${PLAN_NAME:-$(basename "${PLAN%.*}")}"
   340	  closeout_event_dir="$ROOT/.tick/events"
   341	  closeout_event_count=0
   342	  closeout_event_types=""
   343	  if [[ -d "$closeout_event_dir" ]]; then
   344	    closeout_event_count="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | wc -l | tr -d '[:space:]')"
   345	    closeout_event_types="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | LC_ALL=C sort | while IFS= read -r event_file; do
   346	      sed -n 's/.*"type":"\([^"]*\)".*/\1/p' "$event_file"
   347	    done | LC_ALL=C sort -u | paste -sd, -)"
   348	  fi
   349	  closeout_notes="Marathon plan: $closeout_plan
   350	Phases approved: $phase_count/$phase_count
   351	Tick events: $closeout_event_count${closeout_event_types:+ ($closeout_event_types)}"
   352	  if ! bash "$CLOSEOUT_BIN" --repo "$ROOT" --auto-pr --title "Marathon: $closeout_plan" --notes "$closeout_notes"; then
   353	    log "closeout PR failed after successful marathon; leaving marathon successful"
   354	  fi
   355	fi
   356	"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true
   357	
   358	# GH-75: the whole-run success record (title/sessionId = plan name, "N of M phase(s) approved").
   359	xyz_marathon_run_emit green "$phase_count of $phase_count phase(s) approved"
   360	
   361	log "marathon complete — all $phase_count phase(s) approved"
   362	exit 0
   180	    the evidence record — it stays sequential and does not call `validate.sh`.
   181	  - Bypasses are `git push --no-verify` and `XYZ_SKIP_PREPUSH=1`. Both announce themselves. Use them
   182	    deliberately, not reflexively — they skip the local boundary even when hosted CI later runs.
   183	  - **PR checks are meaningful again only after a hosted run actually appears for the commit.** A
   184	    configured workflow is not evidence; query the run and cite its SHA.
   185	
   186	- **Never use a git command that overwrites the working tree from a committed state to undo a
   187	  working-tree experiment.** In this clone other agents hold uncommitted work you cannot see.
   188	  Three spellings destroyed peer work three times in one session (GH-527) and the common factor
   189	  is not obvious from any one of them:
   190	  - `git reset --hard <anything>`
   191	  - `git checkout -- <path>` (restores **HEAD**, not the state before your edit)
   192	  - tree-wide `git stash` (and it may time out before its `pop`)
   193	
   194	  To undo your own experiment, copy the file first (`cp f f.bak`) and restore from that. The
   195	  blast radius is **tracked** modifications; untracked files survive. `relay-automation/hooks/gh527-destructive-git-guard.sh`
   196	  snapshots the doomed tracked files into `.tick/orphan-backups/` before the command runs, so
   197	  this is recoverable rather than prevented — the snapshot is a net, not permission to swing.
   198	- **Preflight sandboxed branch mutations (GH-50).** A sandbox may let `git switch --track` rewrite
   199	  the index and working tree, then deny the `.git/config` lock and leave HEAD on the old branch.
   200	  Before a harness runs a tracking switch or destructive branch mutation such as `git branch -D`,
   201	  wrap the complete command with `utils/git-sandbox-guard.sh --repo <root> -- <git command>` so it
   202	  refuses before mutation when the config cannot be written. Never truncate git stderr for branch
   203	  operations: the decisive `could not lock config file` line can otherwise disappear behind an
   204	  unrelated upstream hint.
   205	- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
   206	- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
   207	  containment, skill-first relay work, durable fixes, and verified done.
   208	- `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
   209	  governance.
   210	- Before approving a PDDA dependency sync, follow the repo-owned
   211	  [PDDA sync review policy](PROJECT/PDDA-SYNC-POLICY.md); a green suite after fixups does not by
   212	  itself establish that deleted local behaviour was safe to remove.
   213	- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
   214	  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
   215	- **Scratch and temporary files go in `temp/`, never the repo root.** `/temp/` is already gitignored
   216	  (`.gitignore:13`). Probes, reproduction scripts, one-off analysis, captured command output,
   217	  half-written notes — anything you would not put in a commit — belongs there or outside the repo
   218	  entirely. **Do not create `scratch-*.md`, `notes-*.md`, `*.tmp` or similar at the repo root.**
   219	
   220	  This is a housekeeping rule with a real failure mode behind it, which is why it is a rail and not a
   221	  preference. Root-level scratch is *untracked*, so it survives branch switches, rebases and
   222	  worktree teardown; it accumulates silently across sessions until nobody can say which agent or
   223	  which lane produced it, or whether it is safe to delete. It also puts unreviewed prose one
   224	  `git add -A` away from a commit — and `marathon-closeout.sh` has already swept 20 unrelated files
   225	  into a lane's PR once (2026-08-10), which is exactly this hazard firing.
   226	
   227	  A file that turns out to be worth keeping gets *promoted* deliberately — into `PROJECT/1-INBOX/`
   228	  as a capture doc, into `test/baselines/` as recorded evidence, or into the CHANGELOG — rather than
   229	  being left at the root in the hope that someone later works out what it was.
   230	- **Frozen Bash twins (GH-308).** Python in `utils/py/` is authoritative for the eleven Tier-A
   231	  entry points (`agy-turn`, `aider-turn`, `claude-turn`, `codex-turn`, `pi-turn`, `poll`,
   232	  `relay-loop`, `relay-drive`, `consult`, `marathon-drive`, and `swarm-preflight`). Their `.sh`
   233	  files are historical `XYZ_PYTHON=0` fallbacks: put behavior fixes in the named Python twin, not
   234	  the Bash body. Before committing, run `bash test/gh308-frozen-twin-guard.sh --check --staged`; the
   235	  `Frozen Bash twin guard (GH-308)` step in `.github/workflows/ci.yml` runs the same guard with
   236	  `--base <PR base> --allow-exceptions` on every PR to reject a committed twin edit. **Escape
   237	  hatch:** a safety defect in a fallback can warrant an edit anyway — GH-319 left a silently-fake
   238	  pre-advance gate in `marathon-drive.sh` under `XYZ_PYTHON=0`. Such a commit must carry a trailer
   239	  that **names the twin it covers**, with an em-dash before the reason:
   240	
   241	  ```
   242	  Frozen-twin-exception: relay-automation/marathon-drive.sh — silently-fake pre-advance gate (GH-319)
   243	  ```
   244	
   245	  **Per file, not per PR (GH-321).** Every frozen twin changed in the range must be named by some
   246	  trailer in that range; one exception no longer excuses a different, undeclared edit riding along
   247	  on the same branch — the common case on a multi-lane marathon PR. A trailer naming a path that is
   248	  not a frozen twin fails loudly rather than silently covering nothing, and the bare
   249	  `Frozen-twin-exception: <reason>` form (no path) no longer covers anything. Comma-separate to cover
   250	  several twins with one reason. No trailer, no edit.
   251	
   252	  **`utils/marathon-plan.sh` is no longer the exception (GH-362).** It was, while its Python "port"
   253	  shelled out to a copied node engine with documented gaps; GH-340 deleted that copy and made the
   254	  Python lane native, so the exception outlived its reason and marathon-plan is now the **12th frozen
   255	  twin**. `relay-turn-lib.sh` remains a shared Bash runtime dependency rather than a twin, and is the
   256	  only non-frozen file left in the Tier-A surface.
   257	
   258	  **No new Bash either (GH-551).** New executables are Python in `utils/py/`; the same guard rejects
   259	  a **new** `.sh` file added under `utils/` or `relay-automation/` unless a
   260	  `New-bash-exception: <path> — <reason>` trailer names it (per file, like GH-321). `test/`, git
   261	  hooks, and existing shims are out of scope.
   262	
   263	  **Two edits the guard permits without a trailer, both narrow (GH-362).** A commit that *introduces*
   264	  a path's `FROZEN` banner establishes the freeze for that path and is not a violation of it — a range
   265	  reaching back before the freeze (a release merge, a bisect, an old fork base) contains exactly that
   266	  commit. The exemption covers the establishing edit only; anything touching the path *after* it in
   267	  the same range still needs a trailer. Relatedly, the pre-GH-321 pathless trailer is tolerated **only**
   268	  inside such a commit, because it is permanently in git history and cannot be rewritten — a new
   269	  pathless trailer is still rejected everywhere.
   270	- **Builder/orchestrator role split (GH-221)** — **Claude Code (terminal and VS Code agents) is the

exec
/bin/zsh -lc "nl -ba PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md && nl -ba GUIDING-PRINCIPLES.md | sed -n '/Marathon builder default/,/"'^[[:space:]]*$/p'"' && nl -ba validate.sh | sed -n '16,53p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
     1	---
     2	title: Make the three marathon process rules deterministic by extending marathon.sh's existing --plan refusal
     3	status: Proposed (1-INBOX — not yet active)
     4	created: 2026-09-03
     5	owner: noelsaw1
     6	gh_issue: 419
     7	source: https://github.com/HiQS-Labs/XYZ-forge/issues/419
     8	doc_type: feature
     9	complexity: 2
    10	risk: 2
    11	effort: 2
    12	phases: 2
    13	ratings_provisional: true
    14	non_goals:
    15	  - Any new script, module, config file, or write path. If it needs a new file other than its test, the design is wrong.
    16	  - A GitHub API call inside the gate. It must work offline; existence-checking is the ledger's job.
    17	  - Enforcement inside marathon_drive.py — it is a single-phase driver; marathon-wide rules belong at the orchestrator, once.
    18	  - Clone-creation automation. The gate validates the name; the operator still runs git clone.
    19	  - Retiring ROADMAP.md (GH-269) or fixing the planner source (GH-418).
    20	related:
    21	  - GH-212 (plan-location refusal — the existing gate this extends)
    22	  - GH-45 (linked-worktree refusal + announced override — the pattern to reuse)
    23	  - GH-417 (marathon umbrella whose process this hardens)
    24	  - GH-418 (planner ledger source — separate defect, same arc)
    25	goal: >
    26	  Turn three documented-only marathon rules — umbrella issue, full clone, derived clone folder
    27	  name — into deterministic refusals, by adding three conditions to a refusal block that already
    28	  exists in marathon.sh, introducing exactly one new input and no new files.
    29	---
    30	
    31	# GH-419: three marathon rules, one existing gate
    32	
    33	> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.
    34	
    35	## Why this is cheap
    36	
    37	The instinct on reading "make three process rules deterministic" is to build a preflight module.
    38	That would be wrong here, because **the gate already exists**.
    39	
    40	GUIDING-PRINCIPLES §"Marathon builder default & plan location (GH-212)" records that
    41	`marathon.sh --plan` **already refuses (exit 2)** a plan resolving outside `PROJECT/2-WORKING/`,
    42	with a documented env override and an exemption for shipped reference examples. That is a
    43	plan-validation refusal block with exactly the shape these three rules need.
    44	
    45	So the whole change is **three more conditions in one existing block**, plus one new YAML key.
    46	
    47	`relay-automation/marathon.sh` carries no frozen-twin banner and has no Python twin, so no
    48	`Frozen-twin-exception:` trailer is required.
    49	
    50	## The one new input
    51	
    52	```yaml
    53	umbrella: https://github.com/HiQS-Labs/XYZ-forge/issues/417
    54	name: gh406-remediation
    55	phases: [...]
    56	```
    57	
    58	Rules 2 and 3 need **no** new input — both derive from this key plus the cwd.
    59	
    60	## The three conditions
    61	
    62	| Rule | Check | Reuses |
    63	|---|---|---|
    64	| 1. Umbrella present | `umbrella:` matches the issue-URL shape, or `TMP-XXXXXX`. **No network call.** | the `check_tracking_token` posture (`releases_app.py:1675-1694`) |
    65	| 2. Full clone | refuse a linked worktree; refuse the harness's own checkout | the `--git-common-dir` idiom already written twice (`validate.sh:16-53`, `driver-lock-lib.sh:20-35`) — do not write a third |
    66	| 3. Derived name | `basename "$PWD"` equals `marathon-gh-<n>-<slug>`, `<n>` from rule 1's key | nothing new; the name is checked against data already in hand |
    67	
    68	Escape hatch: one env override per rule, **announced on stderr, never silent** — the GH-45 pattern
    69	verbatim. A bypass that says nothing is indistinguishable from no guard.
    70	
    71	## Phases
    72	
    73	1. **The three conditions + the `umbrella:` key.** One edit to the existing refusal block.
    74	2. **Controls.** Three reds (one per rule, each fired against a fixture) and one green (a
    75	   correctly-shaped marathon still runs), recorded in `test/baselines/`. Per §13 a green gate with
    76	   no witnessed red is not evidence — and rule 3's green control matters most, because a
    77	   too-strict name regex would refuse every real marathon while looking like a working guard.
    78	
    79	## The one place a reviewer should push back
    80	
    81	Rule 2's "never the primary checkout" has **no precedent in the tree**. GH-45 deliberately *allows*
    82	the primary checkout for `validate.sh`, and `test/gh35-test-tiers.sh:367-370` asserts that as an
    83	explicit CONTROL. Refusing it for marathons is a new posture, not an extension of an existing one.
    84	It is the piece most likely to be over-engineering, and the reviewers are asked to rule on it
    85	directly.
    86	
    87	## Swarm Preflight Contract
    88	
    89	```json
    90	{
    91	  "target":      { "repo": ".", "ref": "development" },
    92	  "gate":        "bash validate.sh",
    93	  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "umbrella" } ],
    94	  "artifacts":   [
    95	    "relay-automation/marathon.sh",
    96	    "test/gh419-marathon-rule-enforcement.sh",
    97	    "test/baselines/GH-419-negative-control.md"
    98	  ],
    99	  "remediation": { "source": "issue#419", "criteria": "a marathon without a valid umbrella key, or from a worktree/primary checkout, or in a wrongly-named folder, is refused exit 2; each refusal is overridable by one announced env var; a correctly-shaped marathon still runs" },
   100	  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
   101	}
   102	```
   130	### Marathon builder default & plan location (GH-212)
   131	
   132	Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
   133	right behavior without pattern-matching a downstream repo's prior drift:
   134	
   135	- **Builder default is `codex`, not a billed CLI.** `marathon.sh`/`marathon-drive.sh` (and the
   136	  `XYZ_PYTHON=1` port) default `--builder` to `codex` — build turns bill via the Codex/ChatGPT
   137	  subscription, not the Anthropic API (agy is the other cost-blind option). `--builder claude`
   138	  spawns a headless Claude Code CLI subprocess instead: a separate, per-call API-billed turn-taker.
   139	  Use it only as an explicit, cost-acknowledged choice — never assume it's free because an
   140	  interactive session is already running. `swarm-preflight.sh`'s suggested invocation and
   141	  `marathon.sh`'s own default now agree; don't let them drift apart again.
   142	- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
   143	  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
   144	  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
   145	  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
   146	  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
   147	  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.
   148	
   149	---
   150	
   151	## Appendix: AI Doc Review Heuristics
   152	
   153	When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.
   154	
   155	**Heuristics**
   156	
   157	1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
   158	2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
   159	3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
   160	4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
   161	5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
   162	6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
   163	7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
   164	8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.
   165	
   166	**Tie-breakers**
   167	
   168	- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
   169	- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
   170	- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.
   171	
   172	**Reject or escalate when**
   173	
   174	- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
   175	- "Done" has no runnable verification step.
   176	- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
   177	- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
   178	- ROADMAP.md would need execution detail to make the plan legible.
    16	# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
    17	# A linked worktree shares the parent clone's .git common directory — config, refs, and object
    18	# store alike. A suite that escapes its fixture (or resolves one to an empty string) therefore
    19	# reaches the PARENT clone, not a sandbox: the observed 2026-08-19 run set core.bare=true,
    20	# repointed origin at a deleted temp path, deleted every refs/remotes/origin/*, and overwrote
    21	# development with fixture commits (GH-564's class, firing for real). The detection is the same
    22	# --git-common-dir idiom the GH-448 driver-lock resolver uses: in the main checkout the absolute
    23	# git dir IS the common dir; in a linked worktree it is <common>/worktrees/<name> and differs.
    24	# Fail closed for every mode — tiers 1 and 2 run fixture-driven suites too. BOTH the invocation
    25	# CWD (where a suite's `git -C ""` escape lands) and HERE (whose clone the identity bracket
    26	# asserts) are checked, so invoking the script by absolute path from outside cannot slip past.
    27	_wt_refuses() {  # <dir>... -> exit 2 if any dir lives in a linked worktree
    28	  local d a c ca
    29	  for d in "$@"; do
    30	    a="$( cd "$d" 2>/dev/null && git rev-parse --absolute-git-dir 2>/dev/null )" || continue
    31	    c="$( cd "$d" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null )" || continue
    32	    [ -n "$a" ] && [ -n "$c" ] || continue
    33	    ca="$( cd "$d" 2>/dev/null && cd "$c" 2>/dev/null && pwd -P )" || continue
    34	    [ -n "$ca" ] || continue
    35	    if [ "$a" != "$ca" ]; then
    36	      cat >&2 <<WTREFUSE
    37	validate.sh: REFUSING — '$d' is a linked git worktree, which shares the parent clone's
    38	  .git (config, refs, objects). Suites that write to 'the repo' reach the PARENT, not a
    39	  fixture: an observed run set core.bare=true, repointed origin at a deleted temp path,
    40	  deleted every refs/remotes/origin/*, and overwrote development with fixture commits.
    41	  Run the gate from a normal clone. Override with XYZ_ALLOW_WORKTREE_GATE=1 only if you
    42	  accept that blast radius.
    43	WTREFUSE
    44	      exit 2
    45	    fi
    46	  done
    47	}
    48	if [ "${XYZ_ALLOW_WORKTREE_GATE:-0}" != "1" ]; then
    49	  _wt_refuses "$HERE" "${PWD:-.}"
    50	else
    51	  # Announced, never silent — a bypass that says nothing is indistinguishable from no guard.
    52	  echo "validate.sh: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
    53	fi

exec
/bin/zsh -lc "nl -ba relay-automation/marathon.sh | sed -n '1,195p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
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
    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
    16	#                                [--pre-advance-cmd CMD] [--dry-run] [--retry PHASE-ID]
    17	#
    18	# GH-212: default builder is `codex` — no per-call API charge (bills via the Codex/ChatGPT
    19	# subscription; agy is the other cost-blind option). `--builder claude` spawns a headless Claude
    20	# Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker, distinct from an
    21	# interactive session. Use it only as an explicit, cost-acknowledged choice.
    22	#
    23	# GH-212: a plan's `--plan` YAML (+ its phase briefs) must resolve under PROJECT/2-WORKING/ in the
    24	# target repo — not a standalone top-level folder (e.g. marathon-plans/<slug>/) an agent might
    25	# pattern-match from a prior repo. Exempt: paths under this harness's own home (MARATHON_HOME —
    26	# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    27	#
    28	# GH-116: --retry <phase-id> recovers a phase whose relay task was left open/never-claimed
    29	# (permanently spent, per this repo's claim-then-abandon constraint) WITHOUT manually renaming the
    30	# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
    31	# MARATHON-<ID>-TURN-<N> suffix (N starts at 2, checked via `tick info`) — every other phase derives
    32	# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
    33	# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
    34	#
    35	# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
    36	# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
    37	# max_review_rounds→--round-cap.
    38	#
    39	# Environment overrides (for tests):
    40	#   MARATHON_HOME       — harness home (default: parent of this script's dir)
    41	#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
    42	#                         falling back to MARATHON_HOME outside a git repo)
    43	#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
    44	#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
    45	#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
    46	#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
    47	#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
    48	# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
    49	#
    50	# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
    51	
    52	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    53	MARATHON_HOME="${MARATHON_HOME:-"$(cd "$HERE/.." && pwd)"}"
    54	if [[ -n "${MARATHON_ROOT:-}" ]]; then
    55	  ROOT="$MARATHON_ROOT"
    56	elif ROOT="$(git -C "${PWD:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
    57	  :
    58	else
    59	  ROOT="$MARATHON_HOME"
    60	fi
    61	TICK_BIN="${TICK_BIN:-"$MARATHON_HOME/bin/tick"}"
    62	DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
    63	YAML_BIN="${MARATHON_YAML_BIN:-"$MARATHON_HOME/bin/marathon-yaml"}"
    64	CLOSEOUT_BIN="${MARATHON_CLOSEOUT_BIN:-"$MARATHON_HOME/relay-automation/marathon-closeout.sh"}"
    65	
    66	die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
    67	log() { printf 'marathon: %s\n' "$*"; }
    68	
    69	XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$MARATHON_HOME/utils/telemetry/append-xyz-completion.sh"}"
    70	
    71	# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
    72	# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
    73	# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
    74	# run isn't silently absent from XYZ.json (GH-75 review: an early halt used to skip the tail entirely,
    75	# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
    76	xyz_marathon_run_emit() {  # <health> <description>
    77	  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
    78	  local plan; plan="$(basename "$PLAN")"; plan="${plan%.*}"; [[ -n "$plan" ]] || plan="marathon"
    79	  "$XYZ_APPEND_BIN" marathon "$plan" "$1" "$plan" "$2" >/dev/null 2>&1 || true
    80	}
    81	
    82	usage() {
    83	  cat <<'EOF'
    84	Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
    85	                    [--dry-run] [--force] [--retry PHASE-ID] [--closeout-pr]
    86	
    87	  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
    88	                          the target repo (GH-212) — exempt: paths under this harness's own home
    89	                          (shipped examples), or MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    90	  --builder AGENT         Builder agent id (default: codex — no per-call API charge; bills via the
    91	                          Codex/ChatGPT subscription). --builder claude spawns a headless Claude
    92	                          Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker —
    93	                          an explicit, cost-acknowledged choice, not the default.
    94	  --phases-dir DIR        Where to create <dir>/<id>/ (default: <repo-root>/marathon-system).
    95	  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
    96	                          The relay thread, tick token, marathon-system/ and relay-system/ transcripts all stay
    97	                          in THIS harness repo — only code changes land in DIR. Use this when the target
    98	                          repo cannot track harness output (e.g. a public repo that gitignores marathon-system/
    99	                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
   100	                          RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.
   101	                          Plan and brief paths resolve against DIR when set.
   102	                          GH-255 — pick the right knob for what is actually ignored: if the target
   103	                          ignores ONLY relay-system/, prefer XYZ_ARCHIVE_ROOT (GH-30), which
   104	                          redirects just the transcripts and leaves the code artifact and the
   105	                          .tick token anchored to the target. --target-root is the answer when
   106	                          marathon-system/ is ignored too, because XYZ_ARCHIVE_ROOT does not
   107	                          redirect RELAY.md / ESCALATION.md and will leave that run blocked.
   108	  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
   109	  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
   110	  --force                 GH-45: bypass the per-lane attempt cap for this run.
   111	  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix. This REBUILDS the
   112	                          phase — a full builder + reviewer cycle — because a retry must never be
   113	                          satisfied by the attempt it was invoked to retry.
   114	                          GH-491: if the phase's relay is already terminal (STATUS: Approved) and its
   115	                          token is done, and only the GATE went red, do NOT use this. Re-fire the plan
   116	                          plainly instead: the driver detects the satisfied lane and re-runs only the
   117	                          pre-advance gate, dispatching no turns. Use --retry when the ARTIFACT is what
   118	                          needs to change.
   119	  --closeout-pr           Open (but never merge) a PR after a successful marathon. Closeout failure is logged
   120	                          and does not change the successful marathon exit code.
   121	EOF
   122	}
   123	
   124	PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
   125	TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
   126	while (($# > 0)); do
   127	  case "$1" in
   128	    --plan)            PLAN="${2:-}"; shift 2 ;;
   129	    --builder)         BUILDER="${2:-}"; shift 2 ;;
   130	    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
   131	    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
   132	    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
   133	    --dry-run)         DRY_RUN=1; shift ;;
   134	    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
   135	    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
   136	    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
   137	    --help)            usage; exit 0 ;;
   138	    *)                 die "unknown argument: $1" ;;
   139	  esac
   140	done
   141	[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
   142	[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
   143	
   144	# GH-212: plan-location guard. A marathon's plan artifacts (this YAML + its phase briefs) belong
   145	# under PROJECT/2-WORKING/<capture-doc>/, not a standalone top-level folder (e.g. marathon-plans/)
   146	# an agent might pattern-match from a prior repo. Exempt: paths under this harness's own home
   147	# (MARATHON_HOME) — shipped reference examples (e.g. MARATHON.example.yaml), not an agent-authored
   148	# plan for a target repo. Override for a legitimate non-default location:
   149	# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
   150	_plan_abs="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
   151	# Canonicalize with `pwd -P` unconditionally (relative AND already-absolute input): ROOT can come
   152	# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
   153	# (whatever form the caller passed), so either side of this comparison can be a logical (non -P)
   154	# path — canonicalize both or a macOS /var -> /private/var checkout falsely flags every plan.
   155	# symlinks (e.g. macOS /var -> /private/var), so a logical (non -P) comparison here would falsely
   156	# flag every plan as "outside" on such a checkout (same pitfall swarm-preflight.sh works around).
   157	# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
   158	# so this guard must measure against that repo — otherwise every cross-repo plan falsely "resolves
   159	# outside PROJECT/2-WORKING/" and dies. GH-212's intent is unchanged: the plan must sit under
   160	# PROJECT/2-WORKING/ of whichever repo owns it.
   161	_plan_base="${TARGET_ROOT:-$ROOT}"
   162	_root_canon="$(cd "$_plan_base" 2>/dev/null && pwd -P || printf '%s' "$_plan_base")"
   163	_home_canon="$(cd "$MARATHON_HOME" 2>/dev/null && pwd -P || printf '%s' "$MARATHON_HOME")"
   164	_plan_rel_root="${_plan_abs#"$_root_canon"/}"
   165	case "$_plan_rel_root" in
   166	  PROJECT/2-WORKING/*) ;;   # in the expected home — proceed
   167	  *)
   168	    case "$_plan_abs" in
   169	      "$_home_canon"/*) ;;   # harness-owned reference material — exempt
   170	      *)
   171	        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
   172	          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
   173	        fi
   174	        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
   175	        ;;
   176	    esac
   177	    ;;
   178	esac
   179	
   180	export TICK_REPO_ROOT="$ROOT"
   181	
   182	# ── GH-388: the chain run log ────────────────────────────────────────────────────────────────────
   183	# This file persisted NOTHING of its own — no tee, no `exec >`, no log-file variable. What was
   184	# durable got written per phase, ON COMPLETION, so the phase that DIES is the one phase with no
   185	# record, and the chain-level narrative existed only on the operator's terminal. Whether any of it
   186	# survived a crash depended on whether whoever typed the command happened to redirect stdout
   187	# somewhere durable. In the run that produced this issue they had — to a path the platform clears at
   188	# boot — and after the panic reboot it was gone.
   189	#
   190	# Where the run narrative goes is the HARNESS's decision now, not the invoker's. Same transcript root
   191	# the per-phase transcripts already use (rtl_transcript_root), so one place holds both.
   192	#
   193	# Armed here, deliberately AFTER plan parse/validate and BEFORE the phase loop: a usage error, an
   194	# unparseable plan or a --plan outside PROJECT/2-WORKING has no run to narrate, and must not leave an
   195	# empty log implying one happened. --dry-run is excluded for the same reason.

exec
/bin/zsh -lc "nl -ba skills/marathon-triage/SKILL.md | sed -n '15,105p'; rg -n -i 'umbrella|MARATHON.yaml|marathon-gh|tracking' relay-automation PROJECT/2-WORKING skills/marathon-triage -g '*.yaml' -g '*.md' -g '*.sh' -g '*.py' | head -n 180" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
    15	Produce an honest, ranked marathon plan without firing work. Treat `PROJECT/**` as the execution
    16	record, GitHub as the live signal stream, and deterministic preflight output as stronger than prose.
    17	
    18	## Guardrails
    19	
    20	- Read `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ROADMAP.md`, and `PROJECT/PDDA.md` first.
    21	- Default to read-only. Do not move docs, promote intake, author contracts, close issues, generate a
    22	  plan file, cut a branch, or fire a marathon without explicit operator confirmation.
    23	- Never override a deterministic PDDA or preflight finding with narrative judgment.
    24	- Use the repo's standing target branch policy. Do not invent a branch or silently substitute a
    25	  builder.
    26	- If GitHub is unavailable, mark live-state evidence `UNKNOWN`; do not infer it from stale local text.
    27	
    28	## Workflow
    29	
    30	### 0. Resolve the harness root
    31	
    32	`swarm-preflight.sh` and `marathon-plan.sh` may live at the repo root or, in a vendored install,
    33	under `.xyz/`. Resolve once, using the same precedence as other self-locating skills in this repo
    34	(env override → vendored `.xyz/` → current repo root):
    35	
    36	```bash
    37	HARNESS="${XYZ_HARNESS:-${XYZ_REPO_ROOT:-}}"
    38	[ -n "$HARNESS" ] || HARNESS="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    39	[ -x "$HARNESS/.xyz/utils/swarm-preflight.sh" ] && HARNESS="$HARNESS/.xyz"
    40	```
    41	
    42	Reference every script below as `$HARNESS/utils/swarm-preflight.sh` and
    43	`$HARNESS/utils/marathon-plan.sh` — not bare `utils/...` paths, which resolve to nothing (or to an
    44	unrelated `utils/` directory) in a vendored `.xyz/` install.
    45	
    46	### 0b. Every marathon has an umbrella tracking issue — open it first
    47	
    48	**A marathon without a GitHub umbrella issue does not start.** The umbrella is the marathon's
    49	identity: waves, clone folder, ledger row and closeout all key off its number.
    50	
    51	Today this is under-enforced and the gap is measurable: `releases_app.py marathon add` requires
    52	`--tracking-issue` (`utils/py/releases_app.py:4901`) and `marathons.tracking_ref_id` is `NOT NULL`
    53	(`:479`) — but the executor never reads either. `marathon_drive.py` has no `--tracking-issue` flag
    54	and the `MARATHON.yaml` schema has no field for one, so the requirement binds only if someone
    55	chooses to create the ledger row. Most runs have not: **at least eight marathons are visible in
    56	committed transcripts and `marathon-system/`, against two rows in the `marathons` table.**
    57	
    58	Procedure, before any triage work:
    59	
    60	1. Open the umbrella issue. Title it for the arc, not the first item. Body lists the candidate
    61	   member issues, the wave sketch, and the acceptance rule for the marathon as a whole.
    62	2. Register it in the ledger immediately:
    63	   ```bash
    64	   python3 "$HARNESS/utils/py/releases_app.py" marathon add \
    65	     --tracking-issue https://github.com/<org>/<repo>/issues/<n> --status planned
    66	   ```
    67	   Offline, `TMP-XXXXXX` is an accepted placeholder — but reconcile it before the marathon closes,
    68	   or the ledger row permanently names an issue that does not exist. The token is **shape-checked
    69	   only** (`check_tracking_token`, `:1675-1694`); GitHub is never queried, so a typo in the URL is
    70	   accepted silently.
    71	3. Dial every member issue into the same release, and link them to this marathon.
    72	
    73	Carry the umbrella number into every downstream artifact: the clone folder name (step 0c), the
    74	plan doc, each phase brief, and the closeout. If you cannot name the umbrella issue, you are not
    75	ready to triage — you are still deciding what the marathon is.
    76	
    77	### 0c. Marathons run in a full clone, deterministically named
    78	
    79	**Two rules, both currently unenforced by code.** State them explicitly in the plan so a reviewer
    80	can check them.
    81	
    82	**A full clone, never a linked worktree and never the primary checkout.** The mechanism that makes
    83	this necessary is real but indirect: `validate.sh:16-53` refuses to run inside a linked worktree
    84	(GH-45, exit 2), and `driver_lock_path_for_repo` (`relay-automation/driver-lock-lib.sh:20-35`)
    85	resolves a linked worktree's lock to its **parent's** `.git/relay-driver.lock`, so a worktree
    86	cannot run a second driver concurrently. Nothing refuses a marathon launched from the primary
    87	checkout — `test/gh35-test-tiers.sh:367-370` proves the primary checkout runs the gate normally —
    88	so this rule is on the operator, not the harness.
    89	
    90	**Clone folder name is derived, not chosen:**
    91	
    92	```
    93	marathon-gh-<umbrella-issue-number>-<short-description>
    94	```
    95	
    96	`<short-description>` is lowercase, hyphen-separated, three words or fewer, describing the arc —
    97	not a wave label, not a phase number. One clone per marathon; a second attempt at the same arc
    98	reuses the name with a `-r2` suffix rather than inventing a new slug.
    99	
   100	```bash
   101	CLONE="$HOME/marathon-clones/marathon-gh-${UMBRELLA}-${SLUG}"
   102	git clone <remote> "$CLONE"
   103	```
   104	
   105	This replaces the current free-form convention, which has drifted badly and is the reason a
skills/marathon-triage/SKILL.md:46:### 0b. Every marathon has an umbrella tracking issue — open it first
skills/marathon-triage/SKILL.md:48:**A marathon without a GitHub umbrella issue does not start.** The umbrella is the marathon's
skills/marathon-triage/SKILL.md:52:`--tracking-issue` (`utils/py/releases_app.py:4901`) and `marathons.tracking_ref_id` is `NOT NULL`
skills/marathon-triage/SKILL.md:53:(`:479`) — but the executor never reads either. `marathon_drive.py` has no `--tracking-issue` flag
skills/marathon-triage/SKILL.md:54:and the `MARATHON.yaml` schema has no field for one, so the requirement binds only if someone
skills/marathon-triage/SKILL.md:60:1. Open the umbrella issue. Title it for the arc, not the first item. Body lists the candidate
skills/marathon-triage/SKILL.md:65:     --tracking-issue https://github.com/<org>/<repo>/issues/<n> --status planned
skills/marathon-triage/SKILL.md:69:   only** (`check_tracking_token`, `:1675-1694`); GitHub is never queried, so a typo in the URL is
skills/marathon-triage/SKILL.md:73:Carry the umbrella number into every downstream artifact: the clone folder name (step 0c), the
skills/marathon-triage/SKILL.md:74:plan doc, each phase brief, and the closeout. If you cannot name the umbrella issue, you are not
skills/marathon-triage/SKILL.md:93:marathon-gh-<umbrella-issue-number>-<short-description>
skills/marathon-triage/SKILL.md:101:CLONE="$HOME/marathon-clones/marathon-gh-${UMBRELLA}-${SLUG}"
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:74:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:82:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/GH-204-BSD-SED-PORTABILITY.md:17:  - "#224 — Linux MVP RC umbrella (this is a Phase 2 exit item)"
relay-automation/xyz-vendor.sh:330:#   bin/               tick, validate-relay-block, marathon-yaml
PROJECT/2-WORKING/GH-193-AGENTCHORUS-GEN2.md:46:merged PR as item completion, but this umbrella continues (phases 2-3). Recorded here instead.
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:87:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:95:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:10:  Everything needed to fire the 2026-09-01 xyz-harness-quickwins marathon: MARATHON.yaml,
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:22:Umbrella tracking issue: [XYZ-forge #376](https://github.com/HiQS-Labs/XYZ-forge/issues/376) —
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:34:3. Copy `MARATHON.yaml` + `phases-briefs/` →
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:37:   `bin/marathon-yaml PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml`
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:38:   `relay-automation/marathon.sh --plan PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml --dry-run`
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:41:6. Land as a PR into XYZ-forge `development`, one umbrella close-out; close the seven
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:46:- `bin/marathon-yaml`: valid (after `depends_on` was made single-id / transitive).
relay-automation/README.md:33:| `xyz-releases-onboard.sh` | **GH-197** onboarding SOP script to migrate a legacy `RELEASES.md` into the Tier 2 SQLite ledger (`releases.db` + `releases.sql`), auditing `.gitignore` for `!releases.db` carve-outs, prepending the app-managed banner, reconciling `MIG-` references to GitHub issue URLs with shared-tracking-URL collision detection, and running validation without auto-committing. |
relay-automation/README.md:145:5. **Reconcile**: maps legacy `MIG-` placeholders to target repository GitHub issue URLs (`reconcile --map`), detecting shared-tracking-URL collisions and stopping with a report without auto-filing issues.
relay-automation/README.md:153:- `MARATHON_HOME`: the harness install that owns `bin/tick`, `bin/marathon-yaml`, and telemetry helpers. Default: the script's own parent dir (`relay-automation/..`).
relay-automation/README.md:160:./.xyz/relay-automation/marathon.sh --plan marathon-plans/my-wave/MARATHON.yaml
relay-automation/README.md:163:Override them independently only when you genuinely need a non-default harness or repo root. The lower-level binary overrides (`TICK_BIN`, `MARATHON_YAML_BIN`, `XYZ_APPEND_BIN`) still win if set.
relay-automation/README.md:482:For multi-phase plans, prefer the per-lane `turn_timeout_s:` field in `MARATHON.yaml`; `marathon.sh`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md:79:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md:35:   writability and refuses tracking/branch-mutation operations up front with a named error,
PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml:5:# Run with:  relay-automation/marathon.sh --plan PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml
relay-automation/MARATHON.example.yaml:26:# the MARATHON.yaml + its phase briefs belong under PROJECT/2-WORKING/<capture-doc>/ in the target
relay-automation/MARATHON.example.yaml:34:#   relay-automation/marathon.sh --plan PROJECT/2-WORKING/<capture>/MARATHON.yaml \
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/phases-briefs/p1-routing-validation.md:55:- `bin/marathon-yaml:99` — reviewer regex is `/^(codex|agy)/`. **Already correct.**
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/phases-briefs/p1-routing-validation.md:62:`marathon_drive.py` or `bin/marathon-yaml` for this issue** — they are already correct, and
relay-automation/relay-turn-lib.sh:999:  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
relay-automation/relay-turn-lib.sh:1003:    printf '%s-turn: ⚠️  NOTICE: tracking ref origin/development is %d commits ahead. Consider rebasing between phases.\n' \
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:7:#     branch and `bin/marathon-yaml`'s reviewer regex is `/^(codex|agy)/`. What REMAINS is
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:47:#     --plan PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml --dry-run
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:80:    depends_on: p2-turn-supervision   # transitively after p1 (marathon-yaml takes one id)
PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:16:  - https://github.com/HiQS-Labs/XYZ-forge/issues/141 (original pre-rename tracking URL)
PROJECT/2-WORKING/GH-123-LINUX-CANARY-REMAINDER.md:17:  - "#224 — Linux MVP RC umbrella (Phase 2 exit item)"
relay-automation/xyz-releases-onboard.sh:102:note "== Step 2: Checking for tracking reference collisions =="
relay-automation/xyz-releases-onboard.sh:128:    SELECT r.global_id, r.version, r.tracking_ref_id, ir.url, ir.temp_id
relay-automation/xyz-releases-onboard.sh:130:    LEFT JOIN issue_refs ir ON ir.id = r.tracking_ref_id
relay-automation/xyz-releases-onboard.sh:137:    WHERE rule = 'tracking-issue-missing' AND disposition IS NULL
relay-automation/xyz-releases-onboard.sh:200:  printf 'xyz-releases-onboard.sh: STOPPED — shared-tracking-URL collision detected:\n' >&2
relay-automation/xyz-releases-onboard.sh:202:  printf 'No issues have been filed. Fix duplicate tracking references before onboarding.\n' >&2
relay-automation/xyz-releases-onboard.sh:214:note "== Step 3: Reconciling tracking references in staged ledger =="
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-29.md:85:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
relay-automation/marathon.sh:4:# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
relay-automation/marathon.sh:30:# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
relay-automation/marathon.sh:35:# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
relay-automation/marathon.sh:44:#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
relay-automation/marathon.sh:63:YAML_BIN="${MARATHON_YAML_BIN:-"$MARATHON_HOME/bin/marathon-yaml"}"
relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
relay-automation/marathon.sh:87:  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
relay-automation/marathon.sh:141:[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
relay-automation/marathon.sh:172:          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-01.md:87:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-27.md:78:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-27.md:86:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:100:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `already-closed`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-03.md:126:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-26.md:76:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-26.md:84:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/GH-314-ARCHIVE-TEMPLATE-MANGLE.md:27:release's tracking issue** (2026-08-24) - ...`. Cosmetic but recurring for every entry
PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:113:and `_ROADMAP_MULTI_KEY_RE` returns `None` for umbrella titles naming several issues
PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:143:- [x] Anchor the GH key; refuse umbrella titles; keep the `#N` prefix form
PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:151:- [x] agy minor finding: dotted-range umbrella titles (`GH-135..140`) carry no key
PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:206:document now stores nothing. This also corrected two of **this** repo's umbrella rows, which had
PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:235:   titles are the same ambiguity as a duplicate GH number — and more reachable now that umbrella
PROJECT/2-WORKING/GH-259-JOG-SERIAL-QUEUE.md:107:     `"jog task above"` extracts session context, opens the tracking issue via `gh issue create`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:121:- #391 GH-391 · nothing generates MARATHON.yaml, so every multi-phase run starts with an undocumented hand-authoring step — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:245:- #113 GH-113 · fix(marathon-yaml): validator rejects agy reviewer — blocks multi-phase YAML plans — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-09-02.md:85:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-28.md:79:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-28.md:86:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:96:- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:106:- #174 GH-174 · Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator — `needs-contract`

exec
/bin/zsh -lc "rg -n \"check_tracking_token|tracking_token|tracking\" utils/py/releases_app.py PROJECT/2-WORKING relay-automation test -g '*.py' -g '*.yaml' -g '*.sh' | head -n 200; rg --files PROJECT/2-WORKING | rg 'MARATHON\\.yaml"'$'"' | head -n 30" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
utils/py/releases_app.py:244:    tracking = release["tracking_url"] or release["tracking_temp"] or "—"
utils/py/releases_app.py:263:""" % (release["global_id"], release["milestone"] or "—", tracking,
utils/py/releases_app.py:269:    return conn.execute("""SELECT r.*, t.url AS tracking_url, t.temp_id AS tracking_temp
utils/py/releases_app.py:270:                           FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id
utils/py/releases_app.py:479:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:495:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:991:    _emit(w, "marathons", ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"],
utils/py/releases_app.py:992:          _rows(conn, """SELECT m.global_id, r.global_id AS repo_gid, t.global_id AS tracking_ref_gid,
utils/py/releases_app.py:995:                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id"""))
utils/py/releases_app.py:1002:                "shipped_date", "description", "exit_criterion", "tracking_ref_gid",
utils/py/releases_app.py:1007:                    rel.exit_criterion, t.global_id AS tracking_ref_gid,
utils/py/releases_app.py:1011:                    JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1565:    for rel in conn.execute("""SELECT rel.*, t.url AS tracking_url, t.temp_id AS tracking_temp
utils/py/releases_app.py:1566:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1592:        if rel["tracking_url"]:
utils/py/releases_app.py:1593:            w("Tracking Issue: %s" % rel["tracking_url"])
utils/py/releases_app.py:1594:        elif rel["tracking_temp"]:
utils/py/releases_app.py:1595:            w("Tracking Issue: %s" % rel["tracking_temp"])
utils/py/releases_app.py:1675:def check_tracking_token(token, allow_mig=False):
utils/py/releases_app.py:1679:        refuse("tracking-required",
utils/py/releases_app.py:1680:               "every release/marathon requires a tracking GH issue (SOP 1/2): pass an issue "
utils/py/releases_app.py:1693:           "tracking reference %r must be https://github.com/<org>/<repo>/issues/<n> or "
utils/py/releases_app.py:1700:    kind, value = check_tracking_token(token, allow_mig=allow_mig)
utils/py/releases_app.py:1724:def tracking_token_to_url(conn, root, token):
utils/py/releases_app.py:1725:    """GH-222: canonicalize `releases update --tracking-issue <N|URL>` to a real issue URL.
utils/py/releases_app.py:1738:            refuse("tracking-issue-slug",
utils/py/releases_app.py:1743:    kind, value = check_tracking_token(token)
utils/py/releases_app.py:1745:        refuse("tracking-repoint-shape",
utils/py/releases_app.py:1930:                tracking_raw = fv("Tracking Issue")
utils/py/releases_app.py:1931:                if tracking_raw and GH_ISSUE_URL_RE.match(tracking_raw.strip()):
utils/py/releases_app.py:1932:                    ref = issue_ref_for_token(conn, tracking_raw.strip())
utils/py/releases_app.py:1938:                    _grandfather(conn, import_run, gid, "tracking-issue-missing", tracking_raw,
utils/py/releases_app.py:1959:                             tracking_ref_id, marathon_id, gh_release_url, milestone,
utils/py/releases_app.py:1995:            ref = issue_ref_for_token(conn, args.tracking_issue)
utils/py/releases_app.py:2004:                         target_date, shipped_date, description, exit_criterion, tracking_ref_id,
utils/py/releases_app.py:2027:        # GH-222: `--tracking-issue <N|URL>` re-points the tracking ref (validated pre-write,
utils/py/releases_app.py:2029:        new_tracking_url = None
utils/py/releases_app.py:2030:        if args.tracking_issue is not None:
utils/py/releases_app.py:2031:            new_tracking_url = tracking_token_to_url(conn, root, args.tracking_issue)
utils/py/releases_app.py:2039:            tracking_ref_id = row["tracking_ref_id"]
utils/py/releases_app.py:2040:            if new_tracking_url is not None:
utils/py/releases_app.py:2041:                ref = issue_ref_for_token(conn, new_tracking_url)
utils/py/releases_app.py:2042:                tracking_ref_id = ref["id"]
utils/py/releases_app.py:2044:                         shipped_date=?, description=?, exit_criterion=?, tracking_ref_id=?,
utils/py/releases_app.py:2055:                          tracking_ref_id,
utils/py/releases_app.py:2079:            if new_tracking_url is not None:
utils/py/releases_app.py:2080:                print("re-pointed tracking issue -> %s (old ref row kept its identity)"
utils/py/releases_app.py:2081:                      % new_tracking_url)
utils/py/releases_app.py:2258:        kind, value = check_tracking_token(args.issue)
utils/py/releases_app.py:2293:        kind, value = check_tracking_token(args.issue)
utils/py/releases_app.py:2369:        kind, value = check_tracking_token(args.issue)
utils/py/releases_app.py:2417:        kind, value = check_tracking_token(args.issue)
utils/py/releases_app.py:2496:            ref = issue_ref_for_token(conn, args.tracking_issue)
utils/py/releases_app.py:2498:            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:2513:                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
utils/py/releases_app.py:2577:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:2582:            print("%s  %-8s %-12s %-8s target=%s shipped=%s tracking=%s items=%d" % (
utils/py/releases_app.py:2626:                           (rel["tracking_ref_id"],)).fetchone()
utils/py/releases_app.py:2784:            tracking = release["tracking_url"] or release["tracking_temp"]
utils/py/releases_app.py:2791:                ("Tracking issue", tracking, "text"),
utils/py/releases_app.py:4470:        cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:4473:                            ref_ids[row["tracking_ref_gid"]], row["status"], row["created_at"]))
utils/py/releases_app.py:4479:                              tracking_ref_id, marathon_id, gh_release_url, milestone,
utils/py/releases_app.py:4486:                            ref_ids[row["tracking_ref_gid"]],
utils/py/releases_app.py:4799:                                 WHERE rule = 'tracking-issue-missing' AND supplied_value = ?
utils/py/releases_app.py:4833:    sp.add_argument("--tracking-issue", required=True,
utils/py/releases_app.py:4843:    sp.add_argument("--tracking-issue", metavar="N|URL",
utils/py/releases_app.py:4844:                    help="GH-222: re-point the tracking issue (bare number expands against the "
utils/py/releases_app.py:4901:    sp_add.add_argument("--tracking-issue", required=True, help="issue URL or TMP-XXXXXX")
test/gh349-releases-roadmap-vendored.sh:61:- [GH-420 — external pull request tracking](docs/pr-420.md) - narrative body. (rated 50/40/60/70 ovr 220) -> [#420](https://github.com/OtherOrg/AnotherRepo/pull/420)
test/gh103-timeline-exporter.sh:77:rq marathon add --tracking-issue "$GH/700"
test/gh103-timeline-exporter.sh:80:   --marathon "$MAR" --tracking-issue "$GH/1"
test/gh103-timeline-exporter.sh:245:# path turned that into artifacts that silently stop tracking the ledger. The versioned-no-target
test/gh103-timeline-exporter.sh:249:rq add --version 9.9.9 --codename Tiebreak --status draft --description "Versioned, no target." --tracking-issue "$GH/910"
test/gh103-timeline-exporter.sh:250:rq add --codename "Night Owl" --status draft --description "Codename-only one." --tracking-issue "$GH/911"
test/gh103-timeline-exporter.sh:251:rq add --codename Falcon --status draft --description "Codename-only two." --tracking-issue "$GH/912"
test/gh425-source-url-slug.sh:2:# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"a temporary copy with the GH-425 slug guard removed accepted a foreign repository's same-numbered issue; the real lane refuses it while accepting source=tracking plus related=origin"}
test/gh425-source-url-slug.sh:3:# GH-425 — source: identifies the tracking issue; related: retains a foreign origin.
test/gh425-source-url-slug.sh:35:TRACKING_SLUG="Acme-Org/tracking-repo"
test/gh425-source-url-slug.sh:92:            f"source: points at repository {res['slug']} ({number_note}), but tracking issue "
test/gh425-source-url-slug.sh:93:            f"#{issue_number} belongs to {tracking_slug} — `source:` must cite the tracking "
test/gh425-source-url-slug.sh:109:R_OK="$WORK/tracking-plus-related"; capture "$R_OK" "$TRACKING_URL" $'related:\n  - "'"$ORIGIN_URL"$' — originating issue"\n'; init_repo "$R_OK"
test/gh425-source-url-slug.sh:112:  && pass "C3 tracking source plus foreign related origin is READY" \
test/gh425-source-url-slug.sh:118:[ "$rc_number" -eq 5 ] && grep -q 'tracking repository is right, but the tracking issue number is wrong' <<<"$out_number" \
relay-automation/relay-turn-lib.sh:999:  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
relay-automation/relay-turn-lib.sh:1003:    printf '%s-turn: ⚠️  NOTICE: tracking ref origin/development is %d commits ahead. Consider rebasing between phases.\n' \
test/gh360-dump-multiline-values.sh:33:RA "$R" add --version 1.0.0 --status draft --tracking-issue TMP-AAAAAA --description "$DESC" > /dev/null
relay-automation/xyz-releases-onboard.sh:102:note "== Step 2: Checking for tracking reference collisions =="
relay-automation/xyz-releases-onboard.sh:128:    SELECT r.global_id, r.version, r.tracking_ref_id, ir.url, ir.temp_id
relay-automation/xyz-releases-onboard.sh:130:    LEFT JOIN issue_refs ir ON ir.id = r.tracking_ref_id
relay-automation/xyz-releases-onboard.sh:137:    WHERE rule = 'tracking-issue-missing' AND disposition IS NULL
relay-automation/xyz-releases-onboard.sh:200:  printf 'xyz-releases-onboard.sh: STOPPED — shared-tracking-URL collision detected:\n' >&2
relay-automation/xyz-releases-onboard.sh:202:  printf 'No issues have been filed. Fix duplicate tracking references before onboarding.\n' >&2
relay-automation/xyz-releases-onboard.sh:214:note "== Step 3: Reconciling tracking references in staged ledger =="
test/gh351-manifest-unship.sh:53:REL="$(ra add --version 1.0.0 --status active --tracking-issue https://github.com/Org/Repo/issues/100 --description "v1.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
test/gh351-manifest-unship.sh:99:REL2="$(ra add --version 2.0.0 --status active --tracking-issue https://github.com/Org/Repo/issues/200 --description "v2.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
test/gh438-acceptance-recheck.sh:16:# deliverable is untracking it, and a builder that does what the real one did — edits .gitignore,
test/gh50-sandboxed-git-guard.sh:4:# gh50-sandboxed-git-guard.sh — GH-50: a guarded tracking switch must refuse
test/gh32-releases-app.sh:89:OUT="$(sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id) SELECT 'rel-SHORT', id, '9.9.9', 'draft', 'x', (SELECT id FROM issue_refs LIMIT 1) FROM repos LIMIT 1" 2>&1)"; RC=$?
test/gh32-releases-app.sh:91:OUT="$(sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id) SELECT 'rel-01IIIIIIIIIIIIIIIIIIIIIIII', id, '9.9.8', 'draft', 'x', (SELECT id FROM issue_refs LIMIT 1) FROM repos LIMIT 1" 2>&1)"; RC=$?
test/gh32-releases-app.sh:93:sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id) SELECT 'rel-01ARZ3NDEKTSV4RRFFQ69G5FAV', id, '9.9.7', 'draft', 'x', (SELECT id FROM issue_refs LIMIT 1) FROM repos LIMIT 1" 2>/dev/null
test/gh32-releases-app.sh:98:rout add --version 0.1.0 --status draft --description "seed." --tracking-issue "https://github.com/A/B/issues/7"
test/gh32-releases-app.sh:101:V="$(rlog add --version 0.2.0 --status draft --description seed2 --tracking-issue "https://github.com/A/B/issues/8" --marathon mar-01ARZ3NDEKTSV4RRFFQ69G5FAV)"
test/gh32-releases-app.sh:117:N="$(sql "SELECT COUNT(*) FROM grandfather_entries WHERE rule = 'tracking-issue-missing'")"; ok "each MIG- ref is a tracked grandfather entry (rule=tracking-issue-missing)" "$(is "$N" "9"; echo $?)"
test/gh32-releases-app.sh:148:if ! grep -qE 'INSERT INTO (releases|manifest_items|marathons|legacy_lines|doc_lines)\([^)]*(^|, )(id|repo_id|release_id|issue_ref_id|tracking_ref_id|marathon_id|item_id)[,)]' "$R/releases.sql"; then ok "the canonical dump contains no integer PKs/FKs as values (rows are GID/natural-keyed)" 0; else ok "dump grammar clean of integer keys" 1; fi
test/gh32-releases-app.sh:155:V="$(rlog add --version 1.0.0 --status draft --description x --tracking-issue "https://example.com/x")"; if has "$V" "rule=issue-url-shape"; then ok "bad tracking URL shape refused, rule named" 0; else ok "url shape" 1; fi
test/gh32-releases-app.sh:156:V="$(rlog add --version 1.0.0 --status draft --description x --tracking-issue "MIG-ABC123")"; if has "$V" "rule=mig-import-only"; then ok "MIG- placeholder refused in an ordinary write (import-only shape)" 0; else ok "mig import-only" 1; fi
test/gh32-releases-app.sh:157:rout add --version 1.0.0 --status draft --description x --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:158:V="$(rlog add --version 1.0.0 --status draft --description x2 --tracking-issue "https://github.com/A/B/issues/2")"; if has "$V" "rule=version-uniqueness"; then ok "versioned-duplicate refusal (UNIQUE(repo_id, version) — the narrowed guarantee)" 0; else ok "versioned dup" 1; fi
test/gh32-releases-app.sh:159:rout add --status draft --description x --codename Twin --tracking-issue "https://github.com/A/B/issues/3"
test/gh32-releases-app.sh:160:rout add --status draft --description y --codename Twin --tracking-issue "https://github.com/A/B/issues/4"
test/gh32-releases-app.sh:173:V="$(rlog add --version 1.0.0 --status draft --description "$LONG" --tracking-issue "https://github.com/A/B/issues/1")"
test/gh32-releases-app.sh:177:V="$(rlog add --version 2.0.0 --status draft --description "$LONG" --tracking-issue "https://github.com/A/B/issues/2")"
test/gh32-releases-app.sh:185:rout add --version 1.0.0 --status draft --description "One." --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:186:rout add --version 2.0.0 --status draft --description "Two." --tracking-issue "https://github.com/A/B/issues/2"
test/gh32-releases-app.sh:217:rout add --version 1.0.0 --status draft --description "One." --tracking-issue "TMP-ABC123"
test/gh32-releases-app.sh:255:V="$(rlog add --version 5.5.5 --status draft --description x --tracking-issue "https://github.com/A/B/issues/5")"; GRC=$?
test/gh32-releases-app.sh:262:rout add --version 5.5.5 --status draft --description x --tracking-issue "https://github.com/A/B/issues/5"
test/gh32-releases-app.sh:272:  RA add --version 9.9.9 --status draft --description "crash" --tracking-issue "https://github.com/A/B/issues/99" >/dev/null 2>&1
test/gh32-releases-app.sh:293:rout add --version 1.0.0 --status draft --description "One." --codename Iota --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:303:sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, codename, status, description, tracking_ref_id) SELECT 'rel-01ARZ3NDEKTSV4RRFFQ69G5FAV', id, '2.0.0', 'Bypass', 'draft', 'direct write', (SELECT tracking_ref_id FROM releases LIMIT 1) FROM repos LIMIT 1;"
test/gh32-releases-app.sh:311:rout add --version 1.0.0 --status draft --description "One." --codename Iota --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:354:rout add --version 1.0.0 --status draft --description "One." --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:365:# GH-222: `update --tracking-issue` re-points the tracking ref through perform_write. The
test/gh32-releases-app.sh:369:V="$(RELEASES_GH_BIN=/bin/false rlog update --gid "$K1" --tracking-issue "https://github.com/A/B/issues/2")"
test/gh32-releases-app.sh:370:TU="$(sql "SELECT t.url FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id WHERE r.global_id = '$K1'")"
test/gh32-releases-app.sh:377:V="$(rlog update --gid "$K1" --tracking-issue 9)"
test/gh32-releases-app.sh:378:if has "$V" "rule=tracking-issue-slug"; then ok "GH-222 bare number with no org/repo slug and no origin remote is refused, rule named" 0; else ok "GH-222 bare number unresolved" 1; fi
test/gh32-releases-app.sh:380:rout update --gid "$K1" --tracking-issue 9
test/gh32-releases-app.sh:381:TU="$(sql "SELECT t.url FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id WHERE r.global_id = '$K1'")"
test/gh32-releases-app.sh:383:V="$(rlog update --gid "$K1" --tracking-issue "https://example.com/x")"
test/gh32-releases-app.sh:385:V="$(rlog update --gid "$K1" --tracking-issue "TMP-ABC123")"
test/gh32-releases-app.sh:386:TU2="$(sql "SELECT t.url FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id WHERE r.global_id = '$K1'")"
test/gh32-releases-app.sh:387:if has "$V" "rule=tracking-repoint-shape" && [ "$TU2" = "$TU" ]; then ok "GH-222 re-point to a TMP- placeholder refused, nothing changed (a re-point is URL-to-URL; placeholders belong to add/reconcile)" 0; else ok "GH-222 placeholder refused" 1; fi
test/gh32-releases-app.sh:402:rout add --version 3.0.0 --status draft --description "Preview seed." --tracking-issue "https://github.com/A/B/issues/3"
test/gh32-releases-app.sh:416:rout add --version 2.0.0 --status draft --description "Later target." --target-date 2026-12-01 --codename Later --tracking-issue "https://github.com/A/B/issues/20"
test/gh32-releases-app.sh:417:rout add --version 1.0.0 --status draft --description "Earlier target." --target-date 2026-09-01 --codename Sooner --tracking-issue "https://github.com/A/B/issues/10"
test/gh32-releases-app.sh:418:rout add --version 0.9.0 --status draft --description "No target." --codename Undated --tracking-issue "https://github.com/A/B/issues/9"
test/gh32-releases-app.sh:419:rout add --version 0.5.0 --status draft --description "Ships first." --target-date 2026-08-01 --codename Gone --tracking-issue "https://github.com/A/B/issues/5"
test/gh32-releases-app.sh:476:                 tracking_ref_id) VALUES (?,?,?,?,?,?,?)""",
test/gh32-releases-app.sh:580:rout add --version 1.0.0 --status draft --description "Dial first." --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:599:OUT="$(sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id, baseline_count) SELECT 'rel-01ARZ3NDEKTSV4RRFFQ69G5FAV', repo_id, '8.8.8', 'draft', 'partial baseline', tracking_ref_id, 5 FROM releases WHERE global_id='$B1'" 2>&1)"; RC=$?
test/gh32-releases-app.sh:611:rout add --version 2.0.0 --status active --description "Activate first." --tracking-issue "https://github.com/A/B/issues/2"
test/gh32-releases-app.sh:622:rout add --version 3.0.0 --status draft --description "Empty at activation." --tracking-issue "https://github.com/A/B/issues/3"
test/gh32-releases-app.sh:641:rout marathon add --tracking-issue "https://github.com/A/B/issues/70"
test/gh32-releases-app.sh:643:rout add --version 1.0.0 --status draft --description "With a marathon." --marathon "$M1" --tracking-issue "https://github.com/A/B/issues/1"
test/gh32-releases-app.sh:644:rout add --version 2.0.0 --status draft --description "Without one." --tracking-issue "https://github.com/A/B/issues/2"
test/gh39-releases-project-sync.sh:43:    {"id": "f-tracking", "name": "Tracking issue"},
test/gh39-releases-project-sync.sh:115:RA add --version 1.0.0 --codename Alpha --status draft --target-date 2026-09-01 --description "First release." --tracking-issue "https://github.com/A/B/issues/1" >/dev/null
test/gh39-releases-project-sync.sh:116:RA add --version 2.0.0 --codename Beta --status active --target-date 2026-10-01 --description "Second release." --tracking-issue "https://github.com/A/B/issues/2" >/dev/null
test/gh57-live-merge-resolve.sh:84:  ra "$r" add --version 1.0.0 --status draft --description 'side one.' --tracking-issue TMP-SIDE01 >/dev/null
test/gh57-live-merge-resolve.sh:87:      --tracking-issue "TMP-SIDE1$i" >/dev/null
test/gh57-live-merge-resolve.sh:92:  ra "$r" add --version 2.0.0 --status draft --description 'main one.' --tracking-issue TMP-MAIN01 >/dev/null
test/gh57-live-merge-resolve.sh:265:ra "$R8" add --version 1.0.0 --status draft --description 'side one.' --tracking-issue TMP-SIDE01 >/dev/null
test/gh57-live-merge-resolve.sh:269:ra "$R8" add --version 2.0.0 --status draft --description 'main one.' --tracking-issue TMP-MAIN01 >/dev/null
test/gh57-releases-fuzz.sh:83:    --tracking-issue "https://github.com/GH57/ledger/issues/$issue" >/dev/null
test/gh57-releases-fuzz.sh:196:  CRASH_OUT="$(RELEASES_APP_CRASH_AT="$BOUNDARY" ra "$R4" add --version 4.0.0 --status draft --description crash --tracking-issue "https://github.com/GH57/ledger/issues/401" 2>&1)"; RC=$?
test/gh57-releases-fuzz.sh:198:  BLOCK_OUT="$(ra "$R4" add --version 4.1.0 --status draft --description blocked --tracking-issue "https://github.com/GH57/ledger/issues/402" 2>&1)"; RC=$?
test/gh57-releases-fuzz.sh:227:LOCK_OUT="$(RELEASES_APP_LOCK_WAIT=0 ra "$R5" add --version 5.0.0 --status draft --description locked --tracking-issue "https://github.com/GH57/ledger/issues/501" 2>&1)"; RC=$?
test/pdda-roadmap-coverage.sh:139:# Scenario 3: a doc tracking an issue with no cached (and no live, gh-offline) state — must degrade
test/gh197-vendor-tier-split.sh:10:#   7. Shared-tracking-URL collision: report + nonzero stop, no auto-filing.
test/gh197-vendor-tier-split.sh:235:# --- 7. Shared-tracking-URL collision detection & recovery ---
test/gh197-vendor-tier-split.sh:251:Description: Second release reusing the same tracking issue.
test/gh197-vendor-tier-split.sh:260:  && pass "Shared-tracking-URL collision: non-zero exit on collision ($col_rc)" \
test/gh197-vendor-tier-split.sh:261:  || fail "Shared-tracking-URL collision: unexpectedly succeeded (exit $col_rc)"
test/gh197-vendor-tier-split.sh:264:  && pass "Shared-tracking-URL collision: reports collision on stderr/stdout" \
test/gh197-vendor-tier-split.sh:265:  || fail "Shared-tracking-URL collision: collision message not found ($col_out)"
test/gh197-vendor-tier-split.sh:268:  && pass "Shared-tracking-URL collision: names colliding URL in report" \
test/gh197-vendor-tier-split.sh:269:  || fail "Shared-tracking-URL collision: colliding URL not named"
test/gh197-vendor-tier-split.sh:272:  && pass "Shared-tracking-URL collision: names both colliding versions in report" \
test/gh197-vendor-tier-split.sh:273:  || fail "Shared-tracking-URL collision: colliding versions not named in report"
test/gh197-vendor-tier-split.sh:277:  && pass "Shared-tracking-URL collision: releases.db was NOT created at root" \
test/gh197-vendor-tier-split.sh:278:  || fail "Shared-tracking-URL collision: releases.db leaked to target root"
test/gh197-vendor-tier-split.sh:280:  && pass "Shared-tracking-URL collision: releases.sql was NOT created at root" \
test/gh197-vendor-tier-split.sh:281:  || fail "Shared-tracking-URL collision: releases.sql leaked to target root"
test/gh197-vendor-tier-split.sh:283:  && pass "Shared-tracking-URL collision: RELEASES.md was NOT mutated" \
test/gh197-vendor-tier-split.sh:284:  || fail "Shared-tracking-URL collision: RELEASES.md was mutated"
test/gh197-vendor-tier-split.sh:300:Description: Second release with fixed tracking issue.
test/gh197-vendor-tier-split.sh:309:  && pass "Shared-tracking-URL collision: recovery succeeds on retry after fixing duplicate" \
test/gh197-vendor-tier-split.sh:310:  || fail "Shared-tracking-URL collision: retry failed after fixing duplicate ($col_retry_out)"
test/gh197-vendor-tier-split.sh:312:  && pass "Shared-tracking-URL collision: releases.db created on successful retry" \
test/gh197-vendor-tier-split.sh:313:  || fail "Shared-tracking-URL collision: releases.db missing on retry"
test/gh32-release-target-advisory.sh:57:  --tracking-issue "$TRACK" \
test/gh32-release-target-advisory.sh:61:  --tracking-issue "$TRACK" \
test/gh32-release-target-advisory.sh:81:  --tracking-issue "$TRACK" \
test/gh32-release-target-advisory.sh:103:ra add --version 2.0.0 --codename Undated --status draft --tracking-issue "$TRACK" \
test/gh557-unknown-blocks-manifest.sh:140:  # unknown tracking slug as "cannot contradict" — so `source:` still reads ok.
test/gh54-merged-dump-refusals.sh:39:  RA "$R" add --version 1.0.0 --status draft --tracking-issue TMP-AAAAAA --description "A one." > /dev/null
test/gh54-merged-dump-refusals.sh:41:    RA "$R" add --version "1.$i.9" --status draft --tracking-issue "TMP-AAAA0$i" --description "A extra." > /dev/null
test/gh54-merged-dump-refusals.sh:46:  RA "$R" add --version 2.0.0 --status draft --tracking-issue TMP-BBBBBB --description "B one." > /dev/null
test/gh233-agent-chorus-concurrency.sh:5:# 1. Multi-agent concurrent joins and heartbeat tracking
test/gh53-releases-merge-resolve.sh:65:  python3 "$APP" --root "$R" add --version 1.0.0 --status draft --tracking-issue TMP-AAAAAA --description "A one." > /dev/null
test/gh53-releases-merge-resolve.sh:67:    python3 "$APP" --root "$R" add --version "1.$i.9" --status draft --tracking-issue "TMP-EXTRA$i" --description "A extra $i." > /dev/null
test/gh53-releases-merge-resolve.sh:72:  python3 "$APP" --root "$R" add --version 2.0.0 --status draft --tracking-issue TMP-BBBBBB --description "B one." > /dev/null
test/gh75-dashboard.sh:42:sqlite3 "$R/releases.db" "INSERT INTO releases (global_id, repo_id, version, codename, status, description, tracking_ref_id) VALUES ('rel-01234567890123456789012345', 1, '1.0', 'Alpha', 'active', 'Initial release', 1);"
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml
PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml

exec
/bin/zsh -lc "nl -ba skills/marathon-triage/SKILL.md | sed -n '77,125p'; nl -ba PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml; nl -ba PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
    77	### 0c. Marathons run in a full clone, deterministically named
    78	
    79	**Two rules, both currently unenforced by code.** State them explicitly in the plan so a reviewer
    80	can check them.
    81	
    82	**A full clone, never a linked worktree and never the primary checkout.** The mechanism that makes
    83	this necessary is real but indirect: `validate.sh:16-53` refuses to run inside a linked worktree
    84	(GH-45, exit 2), and `driver_lock_path_for_repo` (`relay-automation/driver-lock-lib.sh:20-35`)
    85	resolves a linked worktree's lock to its **parent's** `.git/relay-driver.lock`, so a worktree
    86	cannot run a second driver concurrently. Nothing refuses a marathon launched from the primary
    87	checkout — `test/gh35-test-tiers.sh:367-370` proves the primary checkout runs the gate normally —
    88	so this rule is on the operator, not the harness.
    89	
    90	**Clone folder name is derived, not chosen:**
    91	
    92	```
    93	marathon-gh-<umbrella-issue-number>-<short-description>
    94	```
    95	
    96	`<short-description>` is lowercase, hyphen-separated, three words or fewer, describing the arc —
    97	not a wave label, not a phase number. One clone per marathon; a second attempt at the same arc
    98	reuses the name with a `-r2` suffix rather than inventing a new slug.
    99	
   100	```bash
   101	CLONE="$HOME/marathon-clones/marathon-gh-${UMBRELLA}-${SLUG}"
   102	git clone <remote> "$CLONE"
   103	```
   104	
   105	This replaces the current free-form convention, which has drifted badly and is the reason a
   106	salvage operation once could not find its own artifacts: live folders are `gh271-waveA`,
   107	`gh396-phase0` and `gh405-mock-board` — a wave label, a phase number and a feature name, three
   108	different meanings under one shape — while committed transcripts also show `gh-8-…` and `gh-115-…`
   109	with a different separator, plus a `gh-115-clean` retry folder with no stated relationship to its
   110	original.
   111	
   112	### 1. Inventory intake and active work
   113	
   114	List open issues and all issue capture docs in deterministic order:
   115	
   116	```bash
   117	gh issue list --state open --limit 200 --json number,title,labels \
   118	  --jq 'sort_by(.number) | .[] | "\(.number)\t\(.title)\t[\(.labels|map(.name)|join(","))]"'
   119	
   120	find PROJECT/1-INBOX PROJECT/2-WORKING -maxdepth 1 -type f \
   121	  -name 'GH-[0-9]*.md' -print | LC_ALL=C sort -V
   122	```
   123	
   124	Read `ROADMAP.md` pointers and each candidate's frontmatter, status table, acceptance criteria, and
   125	`Swarm Preflight Contract`. Do not treat a title match as a contract.
     1	# ── RESCOPED 2026-09-01 AFTER XYZ-forge #367 AND #375 MERGED ───────────────────────────────
     2	# This plan was authored against `development @ 6fe36fbb` and preflighted there. Two things
     3	# landed on `development` afterwards that change phase p1. Both are recorded in the capture
     4	# docs; this is the summary.
     5	#
     6	#  1. #373 IS MOSTLY ALREADY FIXED (PR #367, GH-346 Phase 2). `route_agent` has no gemini
     7	#     branch and `bin/marathon-yaml`'s reviewer regex is `/^(codex|agy)/`. What REMAINS is
     8	#     only the FROZEN twin `relay-automation/marathon-drive.sh`, which still accepts `gemini*`
     9	#     at :795 and advertises it at :33, :593, :772, :794. That is a GH-308 frozen-twin edit
    10	#     needing a `Frozen-twin-exception:` trailer — decide deliberately whether to spend it.
    11	#     The original GH-373 preflight contract listed the two ALREADY-FIXED files as its
    12	#     artifacts and omitted the one still carrying the defect; it has been corrected.
    13	#
    14	#  2. #368 WILL SILENTLY BREAK THE GH-346 PROFILE RESOLVER (PR #375). `utils/py/profile_resolve.py`
    15	#     derives the lane set by parsing `route_agent`'s source rather than copying it. Both fix
    16	#     directions #368 proposes rewrite that shape; the derivation then yields nothing and every
    17	#     profile degrades to tier 4 — no crash, no blocked turn, just a feature that quietly stops
    18	#     resolving. p1 must update the derivation in the same change. Added to p1's artifacts along
    19	#     with `test/gh346-profile-resolve.sh`, which already asserts the derived lane set equals
    20	#     route_agent's and so fails loudly instead of drifting.
    21	#
    22	# Re-run `swarm-preflight.sh --dry-run` after this rescope: the earlier "ready (exit 0)" was
    23	# measured against the old contracts.
    24	
    25	# XYZ harness quick wins — the seven findings from the 2026-09-01 LTVera health-and-isolation
    26	# marathon (issues #368-#374, filed same day with run-log evidence). Sequenced, NOT concurrent:
    27	# marathon.sh runs phases strictly one at a time with review between them (GH-241).
    28	#
    29	# Serialization analysis (shared files that force depends_on — it does not buy parallelism):
    30	#   * utils/py/marathon_drive.py is in p1 (routing/validation) AND p3 (interrupt snapshot)
    31	#     → p3 depends_on p1.
    32	#   * utils/py/relay_drive.py is in p2 (supervision telemetry) AND p3 (escalation tail)
    33	#     → p3 depends_on p2.
    34	#   * relay-automation/relay-turn-lib.sh + utils/py/rtl.py are in p2 (group kill) AND p4
    35	#     (drift filter) → p4 depends_on p2.
    36	#   * p1 and p2 share nothing → the only real ordering constraint between them is review
    37	#     bandwidth; p2 is ordered after p1 to keep one writer at a time on the drive twins.
    38	#
    39	# FROZEN TWINS (GH-308): behavior changes go in the .py lanes —
    40	# relay-automation/{marathon-drive,relay-drive,agy-turn}.sh are frozen; the preflight
    41	# contracts already list only authoritative paths. relay-automation/marathon-agent.sh and
    42	# relay-turn-lib.sh are NOT frozen (checked 2026-09-01) and may be edited directly.
    43	#
    44	# This repo HAS a root validate.sh — marathon.sh's default gate is `bash validate.sh`
    45	# (aggregate tick acceptance suite). Always --dry-run first:
    46	#   relay-automation/marathon.sh \
    47	#     --plan PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml --dry-run
    48	#
    49	# Builder/reviewer: codex + agy (the intended cross-model pair). Contingency: if the codex
    50	# workspace is still out of credits (the condition that produced #368), phase p1's own fix
    51	# is what makes an agy/agy-qa same-lane run routable — run p1 first with whatever lanes
    52	# are available (claude is per-call billed and NOT authorized by default).
    53	
    54	name: 2026-09-01-xyz-harness-quickwins
    55	phases:
    56	  - id: p1-routing-validation
    57	    name: "#368 + #373 — same-lane agent routing + reviewer-validation alignment"
    58	    reviewer: agy
    59	    brief: PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/phases-briefs/p1-routing-validation.md
    60	    artifact: utils/py/marathon_drive.py,utils/py/agy-turn.py,relay-automation/marathon-agent.sh,relay-automation/marathon-drive.sh,utils/py/profile_resolve.py,test/gh346-profile-resolve.sh,test/gh368-same-lane-routing.sh,test/gh373-reviewer-validation.sh
    61	    turn_timeout_s: 1800
    62	    max_review_rounds: 3
    63	
    64	  - id: p2-turn-supervision
    65	    name: "#369 + #370 — process-group turn cap + worktree progress telemetry"
    66	    reviewer: agy
    67	    brief: PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/phases-briefs/p2-turn-supervision.md
    68	    artifact: relay-automation/relay-turn-lib.sh,utils/py/rtl.py,utils/py/relay_drive.py,test/gh369-group-kill.sh,test/gh370-progress-telemetry.sh
    69	    turn_timeout_s: 1800
    70	    max_review_rounds: 3
    71	    depends_on: p1-routing-validation
    72	
    73	  - id: p3-incident-records
    74	    name: "#371 + #372 — interrupted-phase tree snapshot + escalation root-cause tail"
    75	    reviewer: agy
    76	    brief: PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/phases-briefs/p3-incident-records.md
    77	    artifact: utils/py/marathon_drive.py,utils/py/relay_drive.py,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh
    78	    turn_timeout_s: 1800
    79	    max_review_rounds: 3
    80	    depends_on: p2-turn-supervision   # transitively after p1 (marathon-yaml takes one id)
    81	
    82	  - id: p4-drift-filter
    83	    name: "#374 — drift-brief path-existence filter"
    84	    reviewer: agy
    85	    brief: PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/phases-briefs/p4-drift-filter.md
    86	    artifact: relay-automation/relay-turn-lib.sh,utils/py/rtl.py,test/gh374-drift-path-filter.sh
    87	    turn_timeout_s: 1500
    88	    max_review_rounds: 2
    89	    depends_on: p2-turn-supervision
     1	# Marathon: Bulkhead (0.7.3, #179) core-manifest remainder — deterministic three of the five
     2	# open members: #168 #50 #2. (#113 and #114 are deliberately EXCLUDED: they share a write-set
     3	# on utils/py/agy-turn.py and both need live-agy behavioral debugging — routed to a focused
     4	# solo arc instead; see PROJECT/2-WORKING/GH-113/GH-114 capture docs.)
     5	# Run with:  relay-automation/marathon.sh --plan PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml
     6	# Lanes are serialized via depends_on because all three register suites in validate.sh.
     7	# Lane ids are globally unique (gh<issue>-*) — bare p1/p2 ids collide in shared .tick/attempts/.
     8	# All three capture docs preflighted ready (swarm-preflight --dry-run, 2026-08-24; GH-2 after
     9	# the acceptance-verbatim sync committed alongside this plan).
    10	# Builder is codex (marathon.sh --builder codex), so every reviewer must be agy —
    11	# marathon-drive requires builder != reviewer agent ids.
    12	
    13	name: gh2-50-168-bulkhead-core-remainder
    14	phases:
    15	  - id: gh168-wave-reconcile-scope
    16	    name: "GH-168: wave_reconcile — unrelated pre-existing drift warns, PR-attributable drift stays fatal, idempotent double-run"
    17	    reviewer: agy
    18	    brief: PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh168-wave-reconcile-scope.md
    19	    artifact: utils/py/wave_reconcile.py,test/gh168-wave-reconcile-scope.sh,validate.sh
    20	    max_review_rounds: 3
    21	
    22	  - id: gh50-sandboxed-git-guard
    23	    name: "GH-50: git-sandbox-guard preflight — refuse switch --track/branch -D before tree mutation when .git/config is unwritable"
    24	    reviewer: agy
    25	    brief: PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md
    26	    artifact: utils/git-sandbox-guard.sh,test/gh50-sandboxed-git-guard.sh,AGENTS.md,validate.sh
    27	    depends_on: gh168-wave-reconcile-scope
    28	    max_review_rounds: 3
    29	
    30	  - id: gh2-orphan-backup-repro
    31	    name: "GH-2: orphan-backup relocation — mktemp-failure reproducer, derived-path call-site audit, containment checks"
    32	    reviewer: agy
    33	    brief: PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh2-orphan-backup-repro.md
    34	    artifact: test/gh2-orphan-backup-repro.sh,PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md,validate.sh
    35	    depends_on: gh50-sandboxed-git-guard
    36	    max_review_rounds: 3

exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '1660,1715p'; nl -ba utils/py/releases_app.py | sed -n '4770,4920p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
  1660	                hand_edits += 1
  1661	                lines.append("[drift] Release %s: %s is %r in the file, %r in the DB "
  1662	                             "(file edited by hand, or stale after a CLI write)"
  1663	                             % (version, label, file_val, db_val))
  1664	    lines.append("")
  1665	    lines.append("summary: %d file-only block(s), %d field-level difference(s). File-only blocks "
  1666	                 "and unexpected field drift are hand-edits — each resets the Phase 0 "
  1667	                 "sole-writer clock. Stale-after-CLI directions do not." % (len(only_file),
  1668	                                                                            hand_edits))
  1669	    _atomic_write(paths["drift"], "\n".join(lines) + "\n")
  1670	
  1671	
  1672	# ── structural validation (refused in BOTH modes — lenient tolerates imported legacy debt,
  1673	#    never new corruption) and GH-28 thresholds (strict: refuse / lenient: warn and write) ───────
  1674	
  1675	def check_tracking_token(token, allow_mig=False):
  1676	    """Returns ('url', url) or ('temp', temp_id); refuses otherwise, naming the rule."""
  1677	    token = (token or "").strip()
  1678	    if not token:
  1679	        refuse("tracking-required",
  1680	               "every release/marathon requires a tracking GH issue (SOP 1/2): pass an issue "
  1681	               "URL or a TMP-XXXXXX offline placeholder")
  1682	    if GH_ISSUE_URL_RE.match(token):
  1683	        return ("url", token)
  1684	    if TMP_RE.match(token):
  1685	        return ("temp", token)
  1686	    if MIG_RE.match(token):
  1687	        if allow_mig:
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
  1715	    try:
  4770	
  4771	def cmd_reconcile(args):
  4772	    root = resolve_root(args.root)
  4773	    conn = connect(artifact_paths(root)["db"])
  4774	    try:
  4775	        if not args.map:
  4776	            refuse("reconcile-map", "pass --map TMP-XXXXXX=<url> (repeatable)")
  4777	
  4778	        def mutate(conn):
  4779	            for pair in args.map:
  4780	                if "=" not in pair:
  4781	                    refuse("reconcile-map", "--map expects TMP-XXXXXX=<url>, got %r" % pair)
  4782	                temp, url = pair.split("=", 1)
  4783	                temp, url = temp.strip(), url.strip()
  4784	                if not (TMP_RE.match(temp) or MIG_RE.match(temp)):
  4785	                    refuse("reconcile-map",
  4786	                           "--map key %r must be a TMP-XXXXXX or MIG-XXXXXX placeholder" % temp)
  4787	                if not GH_ISSUE_URL_RE.match(url):
  4788	                    refuse("issue-url-shape",
  4789	                           "mapped URL %r must be https://github.com/<org>/<repo>/issues/<n>"
  4790	                           % url)
  4791	                row = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
  4792	                                   (temp,)).fetchone()
  4793	                if not row:
  4794	                    refuse("unknown-temp-ref", "no issue_refs row carries temp id %r" % temp)
  4795	                conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL WHERE id = ?",
  4796	                             (url, row["id"]))
  4797	                if temp.startswith("MIG-"):
  4798	                    conn.execute("""UPDATE grandfather_entries SET disposition = ?
  4799	                                 WHERE rule = 'tracking-issue-missing' AND supplied_value = ?
  4800	                                   AND disposition IS NULL""",
  4801	                                 ("reconciled:%s" % now_iso(), temp))
  4802	                print("reconciled %s -> %s (row %s kept its identity)"
  4803	                      % (temp, url, row["global_id"]))
  4804	
  4805	        perform_write(root, conn, "reconcile", None, mutate)
  4806	    finally:
  4807	        conn.close()
  4808	
  4809	
  4810	# ── CLI ─────────────────────────────────────────────────────────────────────────────────────────
  4811	
  4812	def build_parser():
  4813	    p = argparse.ArgumentParser(prog="releases",
  4814	                                 description="GH-32 SQLite-backed RELEASES ledger CLI "
  4815	                                             "(Phase 0+1: side-by-side generation only)")
  4816	    p.add_argument("--root", help="repo root (default: git toplevel of the CWD)")
  4817	    sub = p.add_subparsers(dest="cmd", required=True)
  4818	
  4819	    sp = sub.add_parser("init", help="create the DB + dump; settings default lenient")
  4820	    sp.add_argument("--slug", help="repo slug (default: root directory basename)")
  4821	
  4822	    sp = sub.add_parser("import", help="ONE-SHOT legacy ledger import (Phase 0)")
  4823	    sp.add_argument("file", nargs="?",
  4824	                    help="path to the legacy RELEASES.md (default: <root>/RELEASES.md)")
  4825	
  4826	    sp = sub.add_parser("add", help="add a release (validated write)")
  4827	    for flag in ("--version", "--codename", "--target-date", "--shipped-date", "--description",
  4828	                 "--exit-criterion", "--milestone", "--gh-release-url", "--marathon"):
  4829	        sp.add_argument(flag)
  4830	    sp.add_argument("--status", required=True, choices=STATUSES)
  4831	    for flag in ("--front-door", "--shakedown", "--license"):
  4832	        sp.add_argument(flag, choices=["Yes", "No"])
  4833	    sp.add_argument("--tracking-issue", required=True,
  4834	                    help="issue URL or TMP-XXXXXX (GitHub-down fallback)")
  4835	
  4836	    sp = sub.add_parser("update", help="update a release by --gid")
  4837	    sp.add_argument("--gid", required=True)
  4838	    for flag in ("--version", "--codename", "--status", "--target-date", "--shipped-date",
  4839	                 "--description", "--exit-criterion", "--milestone", "--gh-release-url"):
  4840	        sp.add_argument(flag)
  4841	    for flag in ("--front-door", "--shakedown", "--license"):
  4842	        sp.add_argument(flag, choices=["Yes", "No"])
  4843	    sp.add_argument("--tracking-issue", metavar="N|URL",
  4844	                    help="GH-222: re-point the tracking issue (bare number expands against the "
  4845	                         "org/repo slug or the github origin remote; the new URL is stored "
  4846	                         "canonically like `add`)")
  4847	
  4848	    sp = sub.add_parser("migrate",
  4849	                        help="upgrade a LIVE ledger to the registry's schema version "
  4850	                             "(idempotent; feature commands never self-migrate)")
  4851	
  4852	    sp = sub.add_parser("baseline",
  4853	                        help="capture a release's kickoff commitment count (write-once)")
  4854	    sp.add_argument("--gid", required=True)
  4855	
  4856	    sp = sub.add_parser("ship", help="mark a release shipped, with evidence")
  4857	    sp.add_argument("--gid", required=True)
  4858	    sp.add_argument("--evidence", default="",
  4859	                    help="exit-criterion run cite (REQUIRED — an empty value is refused with rule=ship-needs-evidence)")
  4860	    sp.add_argument("--date", help="shipped date (default: today)")
  4861	
  4862	    sp = sub.add_parser("manifest", help="manifest items")
  4863	    msub = sp.add_subparsers(dest="manifest_cmd", required=True)
  4864	    # GH-111: `dial-in` is the verb; `add` stays as a back-compatible alias so existing scripts
  4865	    # and the vendored payload keep working while the vocabulary moves.
  4866	    for _name, _help in (("dial-in", "dial an issue into a release (one release at a time)"),
  4867	                         ("add", "alias for dial-in (pre-GH-111 name)")):
  4868	        _p = msub.add_parser(_name, help=_help)
  4869	        _p.add_argument("--gid", required=True)
  4870	        _p.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4871	        _p.add_argument("--reason", default=None,
  4872	                        help="the case for committing this task to this release")
  4873	        _p.add_argument("--marathon", default=None,
  4874	                        help="marathon gid; must be THIS release's marathon")
  4875	    sp_ship = msub.add_parser("ship",
  4876	                              help="mark a dialed-in item shipped (REQUIRES --evidence)")
  4877	    sp_ship.add_argument("--gid", required=True)
  4878	    sp_ship.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4879	    sp_ship.add_argument("--evidence", default="",
  4880	                         help="commit, PR, or test receipt (empty is refused)")
  4881	    sp_mar = msub.add_parser("marathon",
  4882	                             help="link an already dialed-in item to its release's marathon")
  4883	    sp_mar.add_argument("--gid", required=True)
  4884	    sp_mar.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4885	    sp_mar.add_argument("--marathon", required=True, help="marathon gid; must be THIS release's")
  4886	    sp_cut = msub.add_parser("cut",
  4887	                             help="cut an item from a release's manifest (REQUIRES --reason)")
  4888	    sp_cut.add_argument("--gid", required=True)
  4889	    sp_cut.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4890	    sp_cut.add_argument("--reason", default="")
  4891	    sp_unship = msub.add_parser("unship",
  4892	                                help="retract a falsely shipped manifest item back to dialed_in "
  4893	                                     "(REQUIRES --reason)")
  4894	    sp_unship.add_argument("--gid", required=True)
  4895	    sp_unship.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4896	    sp_unship.add_argument("--reason", default="")
  4897	
  4898	    sp = sub.add_parser("marathon", help="marathon CRUD (v1: add/list)")
  4899	    msub = sp.add_subparsers(dest="marathon_cmd", required=True)
  4900	    sp_add = msub.add_parser("add")
  4901	    sp_add.add_argument("--tracking-issue", required=True, help="issue URL or TMP-XXXXXX")
  4902	    sp_add.add_argument("--status", default="planned", choices=MARATHON_STATUSES)
  4903	    msub.add_parser("list")
  4904	
  4905	    sp = sub.add_parser("list", help="list releases")
  4906	    sp.add_argument("--all-repos", action="store_true",
  4907	                    help="aggregate RELEASES_APP_EXTRA_DBS too; duplicate GIDs fail loudly")
  4908	    sp.add_argument("--status", choices=STATUSES)
  4909	
  4910	    sp = sub.add_parser("show", help="full record for one release (by --gid or --version)")
  4911	    sp.add_argument("--gid")
  4912	    sp.add_argument("--version")
  4913	    sp.add_argument("--full", action="store_true",
  4914	                    help="print long values verbatim (default elides them at %d chars)"
  4915	                         % SHOW_ELIDE)
  4916	
  4917	    sp = sub.add_parser("next", help="the next unshipped release, by target date")
  4918	    sp.add_argument("--verbose", action="store_true", help="also print its full record")
  4919	
  4920	    sp = sub.add_parser("gen", help="side-by-side generation (Phase 0: NEVER writes RELEASES.md)")

exec
/bin/zsh -lc "rg -n 'MARATHON_ROOT|git-common-dir|worktree|MARATHON_ALLOW|MARATHON.yaml' relay-automation/marathon.sh utils/swarm-preflight.sh utils/py/swarm_preflight.py githooks relay-automation/hooks utils/pdda test/marathon.sh | head -n 240" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
relay-automation/marathon.sh:4:# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
relay-automation/marathon.sh:26:# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
relay-automation/marathon.sh:30:# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
relay-automation/marathon.sh:35:# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
relay-automation/marathon.sh:41:#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
relay-automation/marathon.sh:47:#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
relay-automation/marathon.sh:54:if [[ -n "${MARATHON_ROOT:-}" ]]; then
relay-automation/marathon.sh:55:  ROOT="$MARATHON_ROOT"
relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
relay-automation/marathon.sh:87:  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
relay-automation/marathon.sh:89:                          (shipped examples), or MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
relay-automation/marathon.sh:141:[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
relay-automation/marathon.sh:149:# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
relay-automation/marathon.sh:152:# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
relay-automation/marathon.sh:171:        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
relay-automation/marathon.sh:172:          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
relay-automation/marathon.sh:174:        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
relay-automation/marathon.sh:311:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
relay-automation/marathon.sh:315:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
test/marathon.sh:2:# marathon.sh test: the multi-phase orchestrator parses MARATHON.yaml, runs phases in depends_on
test/marathon.sh:8:# themselves. An ambient MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 inherited from an outer marathon run
test/marathon.sh:13:unset MARATHON_ALLOW_PLAN_OUTSIDE_WORKING
test/marathon.sh:46:  RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
test/marathon.sh:203:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_RESUME" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
test/marathon.sh:230:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_HANG" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
test/marathon.sh:275:phases_dir="\${phases_dir:-\${MARATHON_ROOT:-}/marathon-system}"
test/marathon.sh:276:printf '%s|%s|%s|%s\n' "\$phase_brief" "\$phases_dir" "\${MARATHON_ROOT:-}" "\${TICK_BIN:-}" >> "$WORK/vendored-drive-ran"
test/marathon.sh:283:  unset MARATHON_HOME MARATHON_ROOT MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
test/marathon.sh:314:# --- (13) GH-212: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 overrides the refusal ---
test/marathon.sh:316:OVERRIDE_OUT="$(MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 run_marathon "$A/outside.yaml" 2>&1)"; rc=$?
test/marathon.sh:317:[ "$rc" -eq 0 ] && pass "GH-212: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 permits a plan outside PROJECT/2-WORKING/" \
utils/swarm-preflight.sh:345:const isFsTouching = (raw) => /(mktemp|git(?:\s+-C\s+\S+)?\s+(?:worktree|init)|mkdir\s|touch\s|rm\s+-|cat\s+>|printf\s+.*>|>>|writeFileSync|appendFileSync|mkdtempSync|(?<!-)>(?![=>&]))/s.test(raw);
utils/swarm-preflight.sh:629:# worktree OF THAT REF — path/grep/command probes then all see the ref's content, not the
utils/swarm-preflight.sh:642:if ! git -C "$TARGET_ROOT" worktree add --detach --quiet "$REF_WT" "$REF_COMMIT" 2>/dev/null; then
utils/swarm-preflight.sh:643:  emit "BLOCKED: could not create a worktree at target.ref '$REF' ($REF_COMMIT) in $TARGET_ROOT."
utils/swarm-preflight.sh:650:# class). Checked in REF_WT — the ref's content — BEFORE the worktree is removed below.
utils/swarm-preflight.sh:676:git -C "$TARGET_ROOT" worktree remove --force "$REF_WT" >/dev/null 2>&1 || rm -rf "$REF_WT"
utils/swarm-preflight.sh:677:git -C "$TARGET_ROOT" worktree prune >/dev/null 2>&1 || true
utils/swarm-preflight.sh:760:# NOT execute the full gate here — that is heavy and side-effectful, e.g. a suite that spawns worktrees.)
utils/swarm-preflight.sh:905:  GH39_BUDGET_LINE="\`turn_timeout_s: ${GH39_TIMEOUT}\` in this phase's MARATHON.yaml entry (≈ ${GH39_ART_LOC} LOC across ${GH39_ART_N} artifact(s) — over the ${GH39_TURN_TIMEOUT_DEFAULT_S}s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement."
utils/swarm-preflight.sh:907:  GH39_BUDGET_LINE="none needed — ≈ ${GH39_ART_LOC} LOC across ${GH39_ART_N} artifact(s) fits the ${GH39_TURN_TIMEOUT_DEFAULT_S}s default. Set \`turn_timeout_s:\` in this phase's MARATHON.yaml entry only to raise it; marathon.sh reads that field, and nothing reads a bare RELAY_TURN_TIMEOUT_S written into a packet."
utils/swarm-preflight.sh:914:  GH54_VERIFY_RULE="- Do NOT run ANY test or gate yourself — not \`$GATE_CMD\`, and NOT \`$FS_TOUCHING_TESTS_CSV\` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree."
utils/swarm-preflight.sh:923:  GH54_VERIFY_RULE="- Do NOT run the full gate (\`$GATE_CMD\`) or any scoped/single-file variant of it yourself — even a single-file invocation can silently run the whole suite if the gate script is a compound (e.g. \`a && b\`) command, and any resulting artifacts trip containment as off-lane. Read the acceptance criteria and your own diff as the verification; the harness runs the real gate after your turn, outside the worktree."
utils/py/swarm_preflight.py:365:    pattern = r'(mktemp|git(?:\s+-C\s+\S+)?\s+(?:worktree|init)|mkdir\s|touch\s|rm\s+-|cat\s+>|printf\s+.*>|>>|writeFileSync|appendFileSync|mkdtempSync|(?<!-)>(?![=>&]))'
utils/py/swarm_preflight.py:1332:        subprocess.check_call(["git", "-C", target_root, "worktree", "add", "--detach", "--quiet", ref_wt, ref_commit], stderr=subprocess.DEVNULL)
utils/py/swarm_preflight.py:1334:        emit(f"BLOCKED: could not create a worktree at target.ref '{ref}' ({ref_commit}) in {target_root}.")
utils/py/swarm_preflight.py:1352:    try: subprocess.check_call(["git", "-C", target_root, "worktree", "remove", "--force", ref_wt], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/swarm_preflight.py:1354:    try: subprocess.check_call(["git", "-C", target_root, "worktree", "prune"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/swarm_preflight.py:1374:            "either. Those tests create temporary git fixtures/files inside your isolated worktree, which "
utils/py/swarm_preflight.py:1376:            "instead; the harness runs the real gate after your turn, outside the worktree."
utils/py/swarm_preflight.py:1772:    # at 600 mid-edit. The per-phase field `turn_timeout_s:` in MARATHON.yaml is the mechanism that
utils/py/swarm_preflight.py:1777:            f"`turn_timeout_s: {gh39_timeout}` in this phase's MARATHON.yaml entry "
utils/py/swarm_preflight.py:1785:            f"{TURN_TIMEOUT_DEFAULT_S}s default. Set `turn_timeout_s:` in this phase's MARATHON.yaml "
relay-automation/hooks/write-ops-log.sh:34:    ("git worktree remove", re.compile(r"\bgit\b(?:[^-]*|.*-C\s+[^\s]+.*)\bworktree\b.*\bremove\b")),
relay-automation/hooks/write-ops-log.sh:35:    ("git worktree prune", re.compile(r"\bgit\b(?:[^-]*|.*-C\s+[^\s]+.*)\bworktree\b.*\bprune\b")),
githooks/install.sh:16:# resolved git hooks directory (`git rev-parse --git-path hooks`, which from a linked worktree
githooks/install.sh:17:# resolves to the PARENT clone's `.git/hooks` — so one install covers every worktree). Living in git
githooks/install.sh:48:# makes one install cover every linked worktree: from a worktree, --git-common-dir points at the
githooks/install.sh:50:COMMON="$(git rev-parse --git-common-dir 2>/dev/null)" || {
githooks/install.sh:202:echo "  It runs the gate before any push, on EVERY branch in this clone (and its worktrees),"

exec
/bin/zsh -lc "nl -ba bin/marathon-yaml | sed -n '1,360p'; rg -n 'marathon\\.sh|marathon-drive\\.sh' skills/marathon-triage/SKILL.md SOP.md ROUTER.md README.md relay-automation -g '*.md' -g '*.sh' | head -n 240" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
     1	#!/usr/bin/env node
     2	'use strict';
     3	
     4	// marathon-yaml — read + validate MARATHON.yaml, emit phases in execution order (Phase 4 / M5).
     5	// Zero-dep (Node stdlib). Bash orchestrators consume the TSV; --format json for tooling.
     6	//
     7	// Usage:  bin/marathon-yaml <MARATHON.yaml> [--format tsv|json]
     8	// TSV columns (tab-separated), one phase per line, in resolved depends_on order:
     9	//   id  reviewer  max_review_rounds  depends_on  brief  artifact  turn_timeout_s  name
    10	// Exit: 0 ok · 1 parse/validation error · 2 usage.
    11	
    12	const fs = require('fs');
    13	
    14	const PHASE_FIELDS = new Set([
    15	  'id', 'name', 'reviewer', 'max_review_rounds', 'depends_on', 'brief', 'artifact', 'turn_timeout_s',
    16	]);
    17	
    18	function stripQuotes(v) {
    19	  if (v.length >= 2 && ((v[0] === '"' && v.endsWith('"')) || (v[0] === "'" && v.endsWith("'")))) {
    20	    return v.slice(1, -1);
    21	  }
    22	  return v;
    23	}
    24	
    25	function splitKV(s) {
    26	  const i = s.indexOf(':');
    27	  if (i < 0) return null;
    28	  const key = s.slice(0, i).trim();
    29	  let val = s.slice(i + 1).trim();
    30	  const c = val.indexOf(' #');
    31	  if (c >= 0) val = val.slice(0, c).trim();
    32	  return [key, stripQuotes(val)];
    33	}
    34	
    35	function indentOf(line) {
    36	  let n = 0;
    37	  while (n < line.length && line[n] === ' ') n++;
    38	  return n;
    39	}
    40	
    41	function parseMarathonYaml(text) {
    42	  const out = { name: '', phases: [] };
    43	  let inPhases = false;
    44	  let cur = null;
    45	  const lines = String(text).split(/\r?\n/);
    46	  for (let ln = 0; ln < lines.length; ln++) {
    47	    const raw = lines[ln];
    48	    const noComment = raw.replace(/^(\s*)#.*$/, '$1');
    49	    if (noComment.trim() === '') continue;
    50	    const indent = indentOf(raw);
    51	    const trimmed = raw.trim();
    52	
    53	    if (indent === 0) {
    54	      if (trimmed === 'phases:') { inPhases = true; cur = null; continue; }
    55	      const kv = splitKV(trimmed);
    56	      if (kv && kv[0] === 'name') { out.name = kv[1]; inPhases = false; continue; }
    57	      throw new Error(`line ${ln + 1}: unexpected top-level line: ${trimmed}`);
    58	    }
    59	
    60	    if (!inPhases) throw new Error(`line ${ln + 1}: indented line outside phases: ${trimmed}`);
    61	
    62	    if (trimmed.startsWith('- ')) {
    63	      cur = {
    64	        id: '', name: '', reviewer: '', max_review_rounds: '', depends_on: '', brief: '', artifact: '',
    65	        turn_timeout_s: '',
    66	      };
    67	      out.phases.push(cur);
    68	      const rest = trimmed.slice(2).trim();
    69	      if (rest) {
    70	        const kv = splitKV(rest);
    71	        if (!kv) throw new Error(`line ${ln + 1}: malformed list item: ${trimmed}`);
    72	        if (!PHASE_FIELDS.has(kv[0])) throw new Error(`line ${ln + 1}: unknown phase field '${kv[0]}'`);
    73	        cur[kv[0]] = kv[1];
    74	      }
    75	      continue;
    76	    }
    77	
    78	    if (!cur) throw new Error(`line ${ln + 1}: phase field before any '- id:' item: ${trimmed}`);
    79	    const kv = splitKV(trimmed);
    80	    if (!kv) throw new Error(`line ${ln + 1}: malformed phase field: ${trimmed}`);
    81	    if (!PHASE_FIELDS.has(kv[0])) throw new Error(`line ${ln + 1}: unknown phase field '${kv[0]}'`);
    82	    cur[kv[0]] = kv[1];
    83	  }
    84	  return out;
    85	}
    86	
    87	function resolveOrder(plan) {
    88	  const phases = plan.phases || [];
    89	  if (phases.length === 0) throw new Error('no phases defined');
    90	  const byId = new Map();
    91	  for (const p of phases) {
    92	    if (!p.id) throw new Error('a phase is missing its id');
    93	    if (byId.has(p.id)) throw new Error(`duplicate phase id: ${p.id}`);
    94	    if (!p.reviewer) throw new Error(`phase ${p.id}: missing reviewer`);
    95	    // GH-346 Phase 2 (allowlist #6): `gemini` removed — it was a phantom. No gemini shim exists in
    96	    // this tree, so a plan naming a gemini reviewer VALIDATED here and then died at drive time in
    97	    // marathon_drive.py's route_agent(). Rejecting it at plan-validation time is the honest
    98	    // failure point. Kept in lockstep with the Python gate; the allowlist test pins both.
    99	    if (!/^(codex|agy)/.test(p.reviewer)) {
   100	      throw new Error(`phase ${p.id}: reviewer '${p.reviewer}' must start with codex or agy`);
   101	    }
   102	    if (p.depends_on === p.id) throw new Error(`phase ${p.id}: depends_on itself`);
   103	    byId.set(p.id, p);
   104	  }
   105	  for (const p of phases) {
   106	    // depends_on is scalar-and-single (a single phase id). The YAML flow-sequence form
   107	    // (depends_on: [p1]) is NOT supported by this hand-rolled reader — it survives as the
   108	    // literal string "[p1]" and would otherwise fail below as a bewildering unknown-phase
   109	    // lookup. Reject it with a message naming the field's shape instead (GH-241).
   110	    if (p.depends_on && /^\[.*\]$/.test(p.depends_on)) {
   111	      throw new Error(
   112	        `phase ${p.id}: depends_on must be a single phase id (a scalar), not a YAML flow sequence '${p.depends_on}' — ` +
   113	        `this reader does not support list dependencies; name one phase id, unquoted (e.g. 'depends_on: p1')`);
   114	    }
   115	    if (p.depends_on && !byId.has(p.depends_on)) {
   116	      throw new Error(`phase ${p.id}: depends_on unknown phase '${p.depends_on}'`);
   117	    }
   118	  }
   119	  const order = [];
   120	  const done = new Set();
   121	  const remaining = phases.slice();
   122	  let guard = 0;
   123	  while (remaining.length) {
   124	    if (guard++ > phases.length + 1) throw new Error('dependency cycle detected');
   125	    let progressed = false;
   126	    for (let i = 0; i < remaining.length; i++) {
   127	      const p = remaining[i];
   128	      if (!p.depends_on || done.has(p.depends_on)) {
   129	        order.push(p);
   130	        done.add(p.id);
   131	        remaining.splice(i, 1);
   132	        progressed = true;
   133	        break;
   134	      }
   135	    }
   136	    if (!progressed) throw new Error('dependency cycle detected');
   137	  }
   138	  return order;
   139	}
   140	
   141	function die(msg, code) { process.stderr.write(`marathon-yaml: ${msg}\n`); process.exit(code == null ? 1 : code); }
   142	
   143	const args = process.argv.slice(2);
   144	let file = '';
   145	let format = 'tsv';
   146	for (let i = 0; i < args.length; i++) {
   147	  if (args[i] === '--format') { format = args[++i]; }
   148	  else if (args[i] === '--help' || args[i] === '-h') {
   149	    process.stdout.write('Usage: bin/marathon-yaml <MARATHON.yaml> [--format tsv|json]\n'); process.exit(0);
   150	  } else if (!file) { file = args[i]; }
   151	  else die(`unexpected argument: ${args[i]}`, 2);
   152	}
   153	if (!file) die('a MARATHON.yaml path is required', 2);
   154	if (format !== 'tsv' && format !== 'json') die(`unknown --format: ${format}`, 2);
   155	
   156	let text;
   157	try { text = fs.readFileSync(file, 'utf8'); } catch (e) { die(`cannot read ${file}: ${e.message}`); }
   158	
   159	let order;
   160	let plan;
   161	try {
   162	  plan = parseMarathonYaml(text);
   163	  order = resolveOrder(plan);
   164	} catch (e) {
   165	  die(e.message);
   166	}
   167	
   168	if (format === 'json') {
   169	  process.stdout.write(JSON.stringify({ name: plan.name, phases: order }, null, 2) + '\n');
   170	} else {
   171	  for (const p of order) {
   172	    process.stdout.write([
   173	      p.id, p.reviewer, p.max_review_rounds || '', p.depends_on || '', p.brief || '',
   174	      p.artifact || '', p.turn_timeout_s || '', p.name || '',
   175	    ].join('\t') + '\n');
   176	  }
   177	}
README.md:202:**Recommended minimum: 16 GB RAM for the serial `marathon.sh --plan` route.** That minimum covers
README.md:213:| 16 GB | Serial `marathon.sh --plan` only | Do not use `/10days` per-lane parallel dispatch. |
README.md:347:- **Marathon** (`relay-automation/marathon.sh`) — chains several relay build→review phases from a
README.md:402:- **Automated Runner Concurrency (Separate Full Clones):** Because linked worktrees share the parent repository's `.git/relay-driver.lock` (GH-42, GH-564), automated runners (`marathon.sh` / `relay-drive.sh`) running simultaneously must be dispatched in **separate standalone full clones**.
README.md:425:| **Marathon** | Automation | The multi-phase orchestrator (`marathon.sh`) and phase loop driver (`marathon-drive.sh`) executing a plan on a branch. | Serial orchestrator |
relay-automation/CONSUMING.md:64:- **Set:** `consult.sh`, `marathon-drive.sh`, `relay-drive.sh`, `swarm-preflight.sh`, and `new-relay.sh`
relay-automation/target-checks.sh:32:#   marathon-drive.sh --target-root /path/to/repo \
relay-automation/relay-drive.sh:64:# reset) exactly once. Byte-consistent mirror in marathon-drive.sh; relay-turn-lib.sh/bin/tick untouched.
relay-automation/relay-drive.sh:93:# phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
relay-automation/relay-drive.sh:151:  # marathon-drive.sh:195-196 silently did not exist. Resolution now goes through GH-448's shared
relay-automation/marathon.sh:4:# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
relay-automation/marathon.sh:5:# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
relay-automation/marathon.sh:15:#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
relay-automation/marathon.sh:32:# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
relay-automation/marathon.sh:33:# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
relay-automation/marathon.sh:43:#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
relay-automation/marathon.sh:62:DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
relay-automation/marathon.sh:71:# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
relay-automation/marathon.sh:73:# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
relay-automation/marathon.sh:84:Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
relay-automation/marathon.sh:95:  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
relay-automation/marathon.sh:217:  # about, reproduced by its own fix. Caught by test/marathon.sh's GH-212 harness-home-exempt case.
relay-automation/marathon.sh:291:  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
relay-automation/README.md:86:| Bare `marathon-drive.sh` | Exactly one `marathon` record per invocation |
relay-automation/README.md:87:| Swarm-originated `marathon-drive.sh` (`XYZ_HARNESS_CONTEXT=swarm`) | Exactly one `swarm` record per invocation |
relay-automation/README.md:88:| `marathon.sh` orchestrated multi-phase run | Exactly one `marathon` record for the whole run; nested phase-level `marathon-drive.sh` completion hooks stay silent |
relay-automation/README.md:105:| Any `marathon-drive.sh` phase | Overwritten once right after `marathon.phase.start` |
relay-automation/README.md:106:| Nested `relay-drive.sh` inside `marathon-drive.sh` | Silent; the phase-level marathon heartbeat owns freshness so a nested relay round does not double-write |
relay-automation/README.md:116:| [MARATHON.example.yaml](MARATHON.example.yaml) | Example multi-build marathon manifest for `marathon.sh`. |
relay-automation/README.md:149:## `marathon.sh` roots
relay-automation/README.md:151:`marathon.sh` resolves two different roots on purpose:
relay-automation/README.md:160:./.xyz/relay-automation/marathon.sh --plan marathon-plans/my-wave/MARATHON.yaml
relay-automation/README.md:482:For multi-phase plans, prefer the per-lane `turn_timeout_s:` field in `MARATHON.yaml`; `marathon.sh`
relay-automation/README.md:559:- **Set:** all transcript writers (`consult.sh`, `marathon-drive.sh`,
relay-automation/driver-lock-lib.sh:4:# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
relay-automation/marathon-drive.sh:24:# marathon-drive.sh — Phase 3: single-phase headless relay loop.
relay-automation/marathon-drive.sh:31:#   relay-automation/marathon-drive.sh \
relay-automation/marathon-drive.sh:152:# at end-of-run so a marathon-drive.sh phase (standalone or as one phase of a marathon.sh chain)
relay-automation/marathon-drive.sh:161:# own exit. Driven via marathon.sh, each phase's marathon-drive subprocess still prints its OWN
relay-automation/marathon-drive.sh:162:# cumulative total at ITS exit (marathon.sh is untouched by this fix and holds no cross-phase state
relay-automation/marathon-drive.sh:426:# marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
relay-automation/marathon-drive.sh:428:# invocation). Stays SILENT when marathon.sh drives us per-phase (XYZ_HARNESS_CONTEXT=marathon-phase):
relay-automation/marathon-drive.sh:429:# marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
relay-automation/marathon-drive.sh:498:# (re)build or (re)review — the only reason to re-invoke marathon-drive.sh for it is to
relay-automation/marathon-drive.sh:590:Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
relay-automation/marathon-drive.sh:1249:# record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
relay-automation/marathon-agent.sh:21:# Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
relay-automation/hooks/relay-xyz-guard.sh:107:  *relay-automation/marathon-drive.sh*|\
relay-automation/hooks/relay-xyz-guard.sh:108:  *relay-automation/marathon.sh*|\
relay-automation/claude-turn.sh:48:#                       subprocess only (default: codex gemini consult consult.sh marathon-drive.sh
relay-automation/claude-turn.sh:188:block_cmds="${CLAUDE_BLOCK_CMDS-codex gemini consult consult.sh marathon-drive.sh relay-drive.sh}"
relay-automation/relay-turn-lib.sh:105:# Every transcript writer (consult.sh, marathon-drive.sh, relay-drive.sh, swarm-preflight.sh,
relay-automation/relay-turn-lib.sh:311:  # root-cause; 312a2c3's own message names the test/marathon-drive.sh GH-171/GH-172 failures Plan K
relay-automation/relay-turn-lib.sh:883:        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback

exec
/bin/zsh -lc "rg -n 'MARATHON_ROOT|TARGET_ROOT|target-root|ROOT=' relay-automation/marathon.sh test/marathon.sh | sed -n '1,220p'; nl -ba test/marathon.sh | sed -n '1,70p'; nl -ba test/marathon.sh | sed -n '280,340p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
relay-automation/marathon.sh:41:#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
relay-automation/marathon.sh:54:if [[ -n "${MARATHON_ROOT:-}" ]]; then
relay-automation/marathon.sh:55:  ROOT="$MARATHON_ROOT"
relay-automation/marathon.sh:56:elif ROOT="$(git -C "${PWD:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
relay-automation/marathon.sh:59:  ROOT="$MARATHON_HOME"
relay-automation/marathon.sh:95:  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
relay-automation/marathon.sh:105:                          .tick token anchored to the target. --target-root is the answer when
relay-automation/marathon.sh:125:TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
relay-automation/marathon.sh:131:    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
relay-automation/marathon.sh:152:# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
relay-automation/marathon.sh:157:# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
relay-automation/marathon.sh:161:_plan_base="${TARGET_ROOT:-$ROOT}"
relay-automation/marathon.sh:180:export TICK_REPO_ROOT="$ROOT"
relay-automation/marathon.sh:275:  # --target-root run that is the TARGET repo, not this harness — resolving against $ROOT would
relay-automation/marathon.sh:277:  brief_base="${TARGET_ROOT:-$ROOT}"
relay-automation/marathon.sh:287:  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
relay-automation/marathon.sh:311:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
relay-automation/marathon.sh:315:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
test/marathon.sh:46:  RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
test/marathon.sh:145:TICK_REPO_ROOT="$A" "$TICK" log task.created "MARATHON-P2-TURN-2" --agent test >/dev/null 2>&1
test/marathon.sh:189:  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "$pdir_rel/**,src/gh205.js" >/dev/null 2>&1 || true
test/marathon.sh:190:  TICK_REPO_ROOT="$A" "$TICK" release "$task" --agent codex --to agy >/dev/null 2>&1 || true
test/marathon.sh:197:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "$pdir_rel/**" >/dev/null 2>&1 || true
test/marathon.sh:198:TICK_REPO_ROOT="$A" "$TICK" done "$task" --agent agy >/dev/null 2>&1 || true
test/marathon.sh:203:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_RESUME" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
test/marathon.sh:230:MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_HANG" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
test/marathon.sh:275:phases_dir="\${phases_dir:-\${MARATHON_ROOT:-}/marathon-system}"
test/marathon.sh:276:printf '%s|%s|%s|%s\n' "\$phase_brief" "\$phases_dir" "\${MARATHON_ROOT:-}" "\${TICK_BIN:-}" >> "$WORK/vendored-drive-ran"
test/marathon.sh:283:  unset MARATHON_HOME MARATHON_ROOT MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
     1	#!/usr/bin/env bash
     2	# marathon.sh test: the multi-phase orchestrator parses MARATHON.yaml, runs phases in depends_on
     3	# order via marathon-drive (STUBBED), HALTS on the first failure (later phases NOT started), and
     4	# emits marathon.complete only when every phase is approved. (Phase 4 / M5)
     5	source "$(dirname "$0")/_setup.sh" marathon
     6	unset MARATHON_LANE_NS
     7	# GH-217: this suite's own GH-212 assertions (tests 12-14) must decide the plan-location policy
     8	# themselves. An ambient MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 inherited from an outer marathon run
     9	# (legitimate there, via marathon.sh's documented override) flips test 12's expected exit-2 refusal
    10	# to exit 0 — the gate_env scrub is the primary fix; this unset is defensive hygiene so the suite
    11	# stays honest even under a hand-rolled --pre-advance-cmd that skips the helper. Test 13 sets the
    12	# override explicitly per-invocation, which is unaffected by an unset here.
    13	unset MARATHON_ALLOW_PLAN_OUTSIDE_WORKING
    14	REPO="$(cd "$(dirname "$0")/.." && pwd)"
    15	MSH="$REPO/relay-automation/marathon.sh"
    16	YBIN="$REPO/bin/marathon-yaml"
    17	
    18	mkdir -p "$A/briefs" "$A/PROJECT/2-WORKING"
    19	for p in p1 p2 p3 a b; do printf 'brief for %s\n' "$p" > "$A/briefs/$p.md"; done
    20	
    21	# Stub marathon-drive: record "id|cap|reviewer|artifact|relay-task|turn-timeout|lane-ns" per phase;
    22	# exit 4 if id == STUB_FAIL_PHASE. (GH-116: relay-task column captures marathon.sh's --relay-task
    23	# override, if any. GH-207: lane-ns captures the marathon-scoped lane key passed from plan name.)
    24	STUB="$WORK/drive.sh"
    25	cat > "$STUB" <<'STUB'
    26	#!/usr/bin/env bash
    27	set -u
    28	pid=""; cap=""; rev=""; art=""; rtask=""; timeout="${RELAY_TURN_TIMEOUT_S:-}"; lane_ns="${MARATHON_LANE_NS:-}"; pdir=""
    29	while (($#)); do case "$1" in
    30	  --phase-id) pid="$2"; shift 2;;
    31	  --round-cap) cap="$2"; shift 2;;
    32	  --reviewer) rev="$2"; shift 2;;
    33	  --artifact) art="$2"; shift 2;;
    34	  --relay-task) rtask="$2"; shift 2;;
    35	  --phases-dir) pdir="$2"; shift 2;;
    36	  *) shift;;
    37	esac; done
    38	printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$pid" "$cap" "$rev" "$art" "$rtask" "$timeout" "$lane_ns" "$pdir" >> "$WORK/phases-ran"
    39	[ "$pid" = "${STUB_FAIL_PHASE:-__none__}" ] && exit 4
    40	exit 0
    41	STUB
    42	chmod +x "$STUB"
    43	
    44	run_marathon() {  # <plan> <extra-args…>
    45	  local plan="$1"; shift
    46	  RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
    47	    bash "$MSH" --plan "$plan" "$@"
    48	}
    49	
    50	cat > "$A/PROJECT/2-WORKING/m.yaml" <<'YAML'
    51	name: chain
    52	phases:
    53	  - id: p1
    54	    reviewer: codex
    55	    max_review_rounds: 2
    56	    brief: briefs/p1.md
    57	  - id: p2
    58	    reviewer: agy
    59	    depends_on: p1
    60	    max_review_rounds: 3
    61	    brief: briefs/p2.md
    62	    artifact: src/p2.js
    63	    turn_timeout_s: 1200
    64	  - id: p3
    65	    reviewer: codex
    66	    depends_on: p2
    67	    brief: briefs/p3.md
    68	YAML
    69	
    70	# GH-346 Phase 2: these fixtures used `reviewer: gemini` purely as "a valid reviewer that
   280	rm -f "$WORK/vendored-drive-ran"; rm -rf "$V/.tick"
   281	(
   282	  cd "$V"
   283	  unset MARATHON_HOME MARATHON_ROOT MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
   284	  ./.xyz/relay-automation/marathon.sh --plan PROJECT/2-WORKING/vendored.yaml
   285	) >/dev/null 2>&1
   286	rc=$?
   287	[ "$rc" -eq 0 ] && pass "GH-206: vendored marathon.sh runs with zero env overrides" \
   288	  || fail "GH-206: vendored marathon.sh exit=$rc"
   289	IFS='|' read -r vendored_brief vendored_phases vendored_root vendored_tick < "$WORK/vendored-drive-ran"
   290	vendored_tick_home="$(cd "$(dirname "$vendored_tick")/.." && pwd -P)"
   291	[[ "$vendored_brief" == "$vendored_root/briefs/p1.md" \
   292	   && "$vendored_phases" == "$vendored_root/marathon-system" \
   293	   && "$vendored_root" == "$(git -C "$V" rev-parse --show-toplevel)" \
   294	   && "$vendored_tick_home" == "$vendored_root/.xyz" \
   295	   && "$vendored_tick" != "$vendored_root/bin/tick" ]] \
   296	  && pass "GH-206: vendored run resolves repo-local briefs/phases separately from harness-local tick" \
   297	  || fail "GH-206: vendored root split wrong: [$(cat "$WORK/vendored-drive-ran" 2>/dev/null)]"
   298	grep -q "marathon.complete" <<<"$(ls "$V/.tick/events/" 2>/dev/null)" \
   299	  && pass "GH-206: vendored run emits marathon.complete in the consumer repo tick log" \
   300	  || fail "GH-206: vendored run missing consumer repo marathon.complete"
   301	
   302	# --- (12) GH-212: a plan outside PROJECT/2-WORKING/ is refused by default -------
   303	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
   304	printf 'name: outside\nphases:\n  - id: p1\n    reviewer: codex\n    brief: briefs/p1.md\n' > "$A/outside.yaml"
   305	OUTSIDE_OUT="$(run_marathon "$A/outside.yaml" 2>&1)"; rc=$?
   306	[ "$rc" -eq 2 ] && pass "GH-212: plan outside PROJECT/2-WORKING/ is refused by default (exit 2)" \
   307	  || fail "GH-212: expected exit 2 for an outside-PROJECT/2-WORKING plan, got $rc: $OUTSIDE_OUT"
   308	grep -q "resolves outside PROJECT/2-WORKING" <<<"$(printf '%s\n' "$OUTSIDE_OUT")" \
   309	  && pass "GH-212: refusal names the plan-location convention" \
   310	  || fail "GH-212: expected a plan-location error message, got: $OUTSIDE_OUT"
   311	[ ! -f "$WORK/phases-ran" ] && pass "GH-212: refused plan runs zero phases" \
   312	  || fail "GH-212: refused plan should not run any phase: [$(cat "$WORK/phases-ran")]"
   313	
   314	# --- (13) GH-212: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 overrides the refusal ---
   315	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
   316	OVERRIDE_OUT="$(MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 run_marathon "$A/outside.yaml" 2>&1)"; rc=$?
   317	[ "$rc" -eq 0 ] && pass "GH-212: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 permits a plan outside PROJECT/2-WORKING/" \
   318	  || fail "GH-212: override run exit=$rc: $OVERRIDE_OUT"
   319	[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1" ] \
   320	  && pass "GH-212: override run actually executes the phase" \
   321	  || fail "GH-212: override run: [$(cat "$WORK/phases-ran" 2>/dev/null)]"
   322	
   323	# --- (14) GH-212: a plan under the harness's own home is exempt, no override needed --
   324	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
   325	mkdir -p "$WORK/fake-home"
   326	printf 'name: homeplan\nphases:\n  - id: p1\n    reviewer: codex\n    brief: briefs/p1.md\n' > "$WORK/fake-home/homeplan.yaml"
   327	HOME_OUT="$(MARATHON_HOME="$WORK/fake-home" run_marathon "$WORK/fake-home/homeplan.yaml" 2>&1)"; rc=$?
   328	[ "$rc" -eq 0 ] && pass "GH-212: a plan under MARATHON_HOME (harness-owned reference material) is exempt" \
   329	  || fail "GH-212: harness-home-exempt plan exit=$rc: $HOME_OUT"
   330	[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1" ] \
   331	  && pass "GH-212: harness-home-exempt plan actually executes the phase" \
   332	  || fail "GH-212: harness-home plan: [$(cat "$WORK/phases-ran" 2>/dev/null)]"
   333	
   334	# --- (15) GH-485: --phases-dir override with nested path --------------------
   335	rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
   336	run_marathon "$A/PROJECT/2-WORKING/m.yaml" --phases-dir "custom/nested/phases" >/dev/null 2>&1; rc=$?
   337	[ "$rc" -eq 0 ] && pass "GH-485: chain with --phases-dir custom/nested/phases exits 0" \
   338	  || fail "GH-485: custom --phases-dir exit=$rc"
   339	grep -q "^p1|5|codex||||chain--p1|custom/nested/phases$" "$WORK/phases-ran" \
   340	  && pass "GH-485: --phases-dir is passed through to the driver" \

exec
/bin/zsh -lc "rg -n 'marathon add|marathons|tracking_ref_id|MARATHON' utils/py/releases_app.py releases.sql | head -n 200; rg -n 'MARATHON.*yaml|MARATHON.yaml' PROJECT/1-INBOX PROJECT/2-WORKING -g '*.md' -g '*.yaml' | head -n 180" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
utils/py/releases_app.py:104:MARATHON_STATUSES = ("planned", "running", "done", "escalated", "abandoned")
utils/py/releases_app.py:270:                           FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id
utils/py/releases_app.py:475:CREATE TABLE marathons (
utils/py/releases_app.py:479:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:495:  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
utils/py/releases_app.py:496:  marathon_id INTEGER REFERENCES marathons(id),
utils/py/releases_app.py:693:  marathon_id INTEGER REFERENCES marathons(id)
utils/py/releases_app.py:991:    _emit(w, "marathons", ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"],
utils/py/releases_app.py:994:                         FROM marathons m JOIN repos r ON r.id = m.repo_id
utils/py/releases_app.py:995:                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id"""))
utils/py/releases_app.py:1011:                    JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1012:                    LEFT JOIN marathons mar ON mar.id = rel.marathon_id ORDER BY rel.id"""
utils/py/releases_app.py:1030:        mfi_join = " LEFT JOIN marathons mar ON mar.id = mi.marathon_id"
utils/py/releases_app.py:1566:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:1959:                             tracking_ref_id, marathon_id, gh_release_url, milestone,
utils/py/releases_app.py:1998:                row = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2004:                         target_date, shipped_date, description, exit_criterion, tracking_ref_id,
utils/py/releases_app.py:2039:            tracking_ref_id = row["tracking_ref_id"]
utils/py/releases_app.py:2042:                tracking_ref_id = ref["id"]
utils/py/releases_app.py:2044:                         shipped_date=?, description=?, exit_criterion=?, tracking_ref_id=?,
utils/py/releases_app.py:2055:                          tracking_ref_id,
utils/py/releases_app.py:2215:                mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2307:            mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
utils/py/releases_app.py:2498:            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:2513:                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
utils/py/releases_app.py:2577:                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
utils/py/releases_app.py:2626:                           (rel["tracking_ref_id"],)).fetchone()
utils/py/releases_app.py:4469:    for row in tables.get("marathons", []):
utils/py/releases_app.py:4470:        cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
utils/py/releases_app.py:4479:                              tracking_ref_id, marathon_id, gh_release_url, milestone,
utils/py/releases_app.py:4902:    sp_add.add_argument("--status", default="planned", choices=MARATHON_STATUSES)
releases.sql:87:-- table: marathons
releases.sql:88:INSERT INTO marathons(global_id, repo_gid, tracking_ref_gid, status, created_at) VALUES('mar-01M0EC2ZXJCCJ88KASQPDBTBJ9', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'ref-01M0EC2ZXN2SS1XD2N3E56GT18', 'planned', '2026-08-20T01:20:38Z');
releases.sql:89:INSERT INTO marathons(global_id, repo_gid, tracking_ref_gid, status, created_at) VALUES('mar-01M1M3WWJDKKTRP5PSCG9HNEYW', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'ref-01M1M3WWJPRG2GGK16EMA0RSZC', 'planned', '2026-09-03T17:08:38Z');
releases.sql:94:INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJ4GE194HWHJJS2AV2', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.4.0', 'Plumbline', 'draft', '2026-11-14', NULL, 'Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431''s own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.', NULL, 'ref-01M0BTBRMKMJ8FDX4CNF6GS6HW', NULL, 'https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431', 'Plumbline', 'No', 'No', 'Yes', NULL, NULL, NULL);
releases.sql:410:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0H9CC0981F9CSAMV7BXRYXP', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '111', 'GH-111 · retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state', 'Completed', '35', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-111-DIALED-IN.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/111', '- **GH-111 · retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state** ✅ **SHIPPED 2026-08-21 (PR #116; issue closed)** — membership became machine-checkable instead of a sentence someone remembered to write: three states (`dialed_in`/`shipped`/`cut`), exclusivity by a partial unique index over ACTIVE membership only, a real `releases migrate` upgrade path where none existed, and BASELINES replacing what the freeze used to buy (progress against the live manifest, growth against the kickoff count). Closed #109 (the viewer asserted marathon membership the data never claimed) and #110 (`shipped` was a state nothing could write). rated 85/75/70/35. → [GH-111-DIALED-IN.md](PROJECT/3-COMPLETED/GH-111-DIALED-IN.md) · [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111)', '2026-08-21T04:31:03Z', '2026-08-25T02:10:14Z', '85', '75', '70', '35', NULL);
releases.sql:434:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0QMC4DSZ9V5A2E24T29RGD8', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '182', 'GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design', 'In progress', '6', '🚧', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-182-HEALER-FACADE-SAFETY.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/182', '- **GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design** 🚧 **queued 2026-08-23 for THE MARATHON (release 0.7.3 "Bulkhead", #179) — Gen 3.5 soak cohort, auto-filed per SOP §1** — fail-fast sandbox requirements (disposable root covering the target, never the invoking checkout), mandatory regression gate, configurable realistic timeouts, restore-on-any-exit; no reachable in-place patch path. rated 75/55/80/55. → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/3-COMPLETED/GH-182-HEALER-FACADE-SAFETY.md) · [#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)', '2026-08-23T15:38:36Z', '2026-08-26T15:44:01Z', '75', '55', '80', '55', NULL);
releases.sql:437:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M0R1R2MGX6WRH12BC42ZZFTH', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '195', 'GH-195 · marathon-root-audit''s blind spot: a direct `python3 marathon_drive.py` call', 'Completed', '20', '✅', NULL, NULL, NULL, 'PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/195', '- **GH-195 · marathon-root-audit''s blind spot: a direct `python3 marathon_drive.py` call** ✅ **SHIPPED 2026-08-23 (in PR #194)** — GH-115''s own new test committed a live transcript onto the real clone on every `validate.sh` run because `marathon-root-audit.sh` only audits `bash <driver>.sh` invocations, never a direct Python call; same defect class as GH-401, reopened via a different invocation shape. Root-caused via direct instrumentation after ~2.5h of correctly-reasoned-but-wrong process-hunting. rated 60/40/50/20. → [GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md](PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md) · [#195](https://github.com/HiQS-Labs/XYZ-forge/issues/195)', '2026-08-23T19:32:19Z', '2026-08-25T02:10:14Z', '60', '40', '50', '20', NULL);
releases.sql:467:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M12KVYMQE9R3DHMN6RCC41G4', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '280', 'Recalibrate Jog as a serial supervisor over Marathon execution', 'In progress', '21', '🆕', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-280-JOG-MARATHON-RECALIBRATION.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/280', '- **[GH-280](https://github.com/HiQS-Labs/XYZ-forge/issues/280) · [Jog ↔ Marathon recalibration](PROJECT/2-WORKING/GH-280-JOG-MARATHON-RECALIBRATION.md)** — active implementation plan; Phase 1 pins additive invocation/result contracts before the opt-in adapter.', '2026-08-27T22:01:24Z', '2026-08-27T23:56:22Z', NULL, NULL, NULL, NULL, NULL);
releases.sql:491:INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr) VALUES('rmi-01M1M9HWTHDERQGFZMFX3EQS60', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '418', 'Marathon planner still reads the frozen ROADMAP.md', 'Queue / parked intake', '42', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-418-MARATHON-ADOPT-RELEASES-DB.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/418', '- **GH-418 · Marathon planner still reads the frozen ROADMAP.md — DB-parked items are invisible since the ROADMAP_SOURCE=releases flip** 🆕 **captured 2026-09-03 via HQ** — .pdda-mode says the DB is planning truth and router_audit calls ROADMAP.md frozen legacy, but marathon_plan.py:126 reads ROADMAP.md and neither planner file mentions the flip (0 grep hits). Proof: the 09-01/09-02 plans surface #349/#351, which exist only in ROADMAP.md and not in roadmap_items. 37 DB-parked items are unplannable. Concrete testable slice of GH-269. — [GH-418-MARATHON-ADOPT-RELEASES-DB.md](PROJECT/1-INBOX/GH-418-MARATHON-ADOPT-RELEASES-DB.md) · [#418](https://github.com/HiQS-Labs/XYZ-forge/issues/418) (rated 88/78/80/75)', '2026-09-03T18:47:29Z', '2026-09-03T18:47:29Z', '88', '78', '80', '75', NULL);
PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:389:  `MARATHON.yaml` becoming generated output, Slack-launch reducing to "insert a row, driver picks it
PROJECT/1-INBOX/GH-418-MARATHON-ADOPT-RELEASES-DB.md:16:  - Changing the executor. marathon.sh / marathon_drive.py consume a MARATHON.yaml and read neither source.
PROJECT/1-INBOX/GH-418-MARATHON-ADOPT-RELEASES-DB.md:52:2. **The planner was not producing the work.** Every `MARATHON.yaml` on disk is hand-authored —
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:121:- #391 GH-391 · nothing generates MARATHON.yaml, so every multi-phase run starts with an undocumented hand-authoring step — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:181:- #241 GH-241 · MARATHON.example.yaml understates sequencing and depends_on's scalar-only shape — `blocked`
PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml:5:# Run with:  relay-automation/marathon.sh --plan PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:47:#     --plan PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml --dry-run
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:10:  Everything needed to fire the 2026-09-01 xyz-harness-quickwins marathon: MARATHON.yaml,
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:34:3. Copy `MARATHON.yaml` + `phases-briefs/` →
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:37:   `bin/marathon-yaml PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml`
PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/README.md:38:   `relay-automation/marathon.sh --plan PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml --dry-run`

exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '2475,2530p'; nl -ba releases.sql | sed -n '80,93p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
exec
/bin/zsh -lc "nl -ba relay-automation/README.md | sed -n '145,175p'; nl -ba relay-automation/README.md | sed -n '76,92p'; nl -ba AGENTS.md | sed -n '88,137p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
   145	5. **Reconcile**: maps legacy `MIG-` placeholders to target repository GitHub issue URLs (`reconcile --map`), detecting shared-tracking-URL collisions and stopping with a report without auto-filing issues.
   146	6. **Verification**: executes `releases check` to ensure ledger consistency.
   147	7. **Commit command**: prints the exact `git add` and `git commit` command for the operator without making the commit.
   148	
   149	## `marathon.sh` roots
   150	
   151	`marathon.sh` resolves two different roots on purpose:
   152	
   153	- `MARATHON_HOME`: the harness install that owns `bin/tick`, `bin/marathon-yaml`, and telemetry helpers. Default: the script's own parent dir (`relay-automation/..`).
   154	- `MARATHON_ROOT`: the target repo that owns the plan's `brief:` files, `marathon-system/`, `.tick/`, and commit target. Default: `git -C "$PWD" rev-parse --show-toplevel`; outside a git repo it falls back to `MARATHON_HOME`.
   155	
   156	That split preserves dev-checkout behavior (`MARATHON_HOME == MARATHON_ROOT`) and makes vendored installs work with no bin overrides:
   157	
   158	```bash
   159	cd /path/to/target-repo
   160	./.xyz/relay-automation/marathon.sh --plan marathon-plans/my-wave/MARATHON.yaml
   161	```
   162	
   163	Override them independently only when you genuinely need a non-default harness or repo root. The lower-level binary overrides (`TICK_BIN`, `MARATHON_YAML_BIN`, `XYZ_APPEND_BIN`) still win if set.
   164	
   165	## `marathon-plan.sh` zone config
   166	
   167	`utils/marathon-plan.sh` can now load a repo-specific zone model instead of hardcoding xyz's own
   168	`kernel` / `shim` filenames:
   169	
   170	- Resolution order: `--zones-config <file>` → `QUEUE_PLAN_ZONES_FILE` → `QUEUE_PLAN_ROOT/.marathon-plan-zones.json` → built-in `utils/marathon-plan-zones.default.json`.
   171	- Explicit files fail loud on read/JSON/schema errors; only an absent root-local file falls through.
   172	- Schema:
   173	  - `zones[]`: ordered first-match rules.
   174	  - `name`: emitted zone label.
   175	  - `pathPrefixes` / `pathRegex` / `pathRegexCaseInsensitive`: proven write-set matching.
    76	| `health` | string | `green`, `orange`, or `red` |
    77	| `title` | string | Short human-readable label for the run |
    78	| `description` | string | One-line outcome summary |
    79	| `updatedAt` | string | UTC timestamp in ISO-8601 `YYYY-MM-DDTHH:MM:SSZ` form |
    80	
    81	Emit cadence:
    82	
    83	| Flow | `XYZ.json` emit contract |
    84	|---|---|
    85	| Standalone `relay-drive.sh` | Exactly one record when the relay terminates: `Approved`/`Closed` => `green`; explicit `Escalated` / review handback => `orange`; no-progress / review-once stall / round-cap => `red` |
    86	| Bare `marathon-drive.sh` | Exactly one `marathon` record per invocation |
    87	| Swarm-originated `marathon-drive.sh` (`XYZ_HARNESS_CONTEXT=swarm`) | Exactly one `swarm` record per invocation |
    88	| `marathon.sh` orchestrated multi-phase run | Exactly one `marathon` record for the whole run; nested phase-level `marathon-drive.sh` completion hooks stay silent |
    89	
    90	`XYZ.heartbeat.json` is the companion in-flight marker. It is a single mutable object, not an array:
    91	
    92	```json
    88	When you give executable steps, put them in one numbered list in execution order. Keep verification
    89	inline (`-> expect ...`). Do not scatter action items across prose.
    90	
    91	### 6. Verified beats plausible
    92	
    93	Do not claim success without the relevant test, script, or observable proof. If verification was
    94	skipped or failed, say that plainly and include the result.
    95	
    96	An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
    97	ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
    98	you merely ran and can no longer show counts as no claim at all.
    99	
   100	**A check that cannot fail is not a check.** A passing assertion is evidence only once you have seen
   101	it fail: mutate the thing it guards — break the code, transpose the fix, delete the value — and watch
   102	it go red. If you cannot make it fail, it is decorative, and it is worse than nothing because it
   103	reports confidence it never earned. This is the precise way this principle fails while looking
   104	satisfied: you *did* verify, and the verification was hollow. Three examples from GH-377/GH-379, all
   105	of which passed cleanly before they were mutated — an `awk` range that terminated on its own first
   106	line, `not matches -- "$pat"` where the helper already supplied `--` so the check searched for the
   107	literal string `--`, and a telemetry `rc` assertion that no *passing* run could ever exercise.
   108	
   109	**An empty input passes every check.** Before asserting anything about extracted data, assert that
   110	you extracted some: a failed command substitution yields an empty string, a shell redirect creates
   111	the file regardless, and a scanner then reports CLEAN against zero bytes. Size-check the artifact,
   112	or guard the extraction with its own assertion, before trusting a verdict computed from it.
   113	
   114	**Never expose the operator's machine to the network without asking.** A tunnel, port forward, or
   115	remote bridge needs explicit permission each time — running the tests is not permission, and neither
   116	is working on the feature that provides it. `SOP.md` §3b has the incident and the teardown rule that
   117	goes with it.
   118	
   119	### 7. Record only consequential bets
   120	
   121	If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
   122	`PROJECT/PDDA.md`. Below that threshold, skip the ritual.
   123	
   124	### 8. Stay quiet on trivial work
   125	
   126	Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
   127	local change.
   128	
   129	## Repo-specific rails
   130	
   131	- **This repo's purpose is to keep a long-horizon marathon under load — and that is a work-selection
   132	  filter, not a slogan.** The harness is only proven by work long enough, parallel enough, and
   133	  failure-prone enough to tax the whole system: worktree isolation, path claims, the driver lock,
   134	  multi-round handoff, escalation, and resume. Short, single-shot tasks land fine but prove nothing.
   135	  Four rules follow, and they are load-bearing:
   136	
   137	  1. **Exactly one long-horizon marathon is in flight at a time.** When one lands, choosing the next

 succeeded in 0ms:
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
    80	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M3DS9TKSCVKQQNPH7TCMPY', 'https://github.com/HiQS-Labs/XYZ-forge/issues/414', NULL, '2026-09-03T17:00:23Z');
    81	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M3DSNJNF3N7KEK6GD7SYRY', 'https://github.com/HiQS-Labs/XYZ-forge/issues/410', NULL, '2026-09-03T17:00:23Z');
    82	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M3DT14MSYYASB9B8748B9Y', 'https://github.com/HiQS-Labs/XYZ-forge/issues/411', NULL, '2026-09-03T17:00:23Z');
    83	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M3DTCZ05VSHP2G1RRD9HXZ', 'https://github.com/HiQS-Labs/XYZ-forge/issues/415', NULL, '2026-09-03T17:00:24Z');
    84	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M3DTRPMD53CY81B8M6TVNM', 'https://github.com/HiQS-Labs/XYZ-forge/issues/412', NULL, '2026-09-03T17:00:24Z');
    85	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M3WWJPRG2GGK16EMA0RSZC', 'https://github.com/HiQS-Labs/XYZ-forge/issues/417', NULL, '2026-09-03T17:08:38Z');
    86	INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES('ref-01M1M9HXP6MAVCEM5RDPX29BSP', 'https://github.com/HiQS-Labs/XYZ-forge/issues/418', NULL, '2026-09-03T18:47:30Z');
    87	-- table: marathons
    88	INSERT INTO marathons(global_id, repo_gid, tracking_ref_gid, status, created_at) VALUES('mar-01M0EC2ZXJCCJ88KASQPDBTBJ9', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'ref-01M0EC2ZXN2SS1XD2N3E56GT18', 'planned', '2026-08-20T01:20:38Z');
    89	INSERT INTO marathons(global_id, repo_gid, tracking_ref_gid, status, created_at) VALUES('mar-01M1M3WWJDKKTRP5PSCG9HNEYW', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'ref-01M1M3WWJPRG2GGK16EMA0RSZC', 'planned', '2026-09-03T17:08:38Z');
    90	-- table: releases
    91	INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJJHRS147J73WWGGEJ', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.1.0', 'Quicksilver', 'shipped', '2026-08-01', NULL, 'Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).', NULL, 'ref-01M0BTBRMJKGF9H80N3ZMF92DS', NULL, 'https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308', 'Quicksilver', 'No', 'No', 'Yes', NULL, NULL, NULL);
    92	INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJW4B6HWAHKW82GFGS', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.2.0', 'Litmus', 'shipped', '2026-09-05', '2026-08-14', 'Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).', '`bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.', 'ref-01M0BTBRMJJT3BG3V8F58X2NYZ', NULL, NULL, 'Litmus', 'No', 'No', 'Yes', NULL, NULL, NULL);
    93	INSERT INTO releases(global_id, repo_gid, version, codename, status, target_date, shipped_date, description, exit_criterion, tracking_ref_gid, marathon_gid, gh_release_url, milestone, front_door_reviewed, shakedown_reviewed, license_file, baseline_count, baseline_at, baseline_source) VALUES('rel-01M0BTBRMJNQM0474RQEYWKJKV', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '0.3.0', 'Nightwatch', 'shipped', '2026-10-10', '2026-08-14', 'An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop''s own evidence has never survived a reboot (#430).', '`bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus''s was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release''s question. Half A audits the frozen manifest — each entry''s gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render''s `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.', 'ref-01M0BTBRMJS3ZFBVSD21PBVSRG', NULL, NULL, 'Nightwatch', 'No', 'No', 'Yes', NULL, NULL, NULL);

exec
/bin/zsh -lc "nl -ba PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md | sed -n '35,105p'; nl -ba AGENTS.md | sed -n '330,385p'; rg -n 'red-control|red control|witnessed red|cannot fail|empty input' AGENTS.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-73354-k5skf9ls
 succeeded in 0ms:
    35	## Why this is cheap
    36	
    37	The instinct on reading "make three process rules deterministic" is to build a preflight module.
    38	That would be wrong here, because **the gate already exists**.
    39	
    40	GUIDING-PRINCIPLES §"Marathon builder default & plan location (GH-212)" records that
    41	`marathon.sh --plan` **already refuses (exit 2)** a plan resolving outside `PROJECT/2-WORKING/`,
    42	with a documented env override and an exemption for shipped reference examples. That is a
    43	plan-validation refusal block with exactly the shape these three rules need.
    44	
    45	So the whole change is **three more conditions in one existing block**, plus one new YAML key.
    46	
    47	`relay-automation/marathon.sh` carries no frozen-twin banner and has no Python twin, so no
    48	`Frozen-twin-exception:` trailer is required.
    49	
    50	## The one new input
    51	
    52	```yaml
    53	umbrella: https://github.com/HiQS-Labs/XYZ-forge/issues/417
    54	name: gh406-remediation
    55	phases: [...]
    56	```
    57	
    58	Rules 2 and 3 need **no** new input — both derive from this key plus the cwd.
    59	
    60	## The three conditions
    61	
    62	| Rule | Check | Reuses |
    63	|---|---|---|
    64	| 1. Umbrella present | `umbrella:` matches the issue-URL shape, or `TMP-XXXXXX`. **No network call.** | the `check_tracking_token` posture (`releases_app.py:1675-1694`) |
    65	| 2. Full clone | refuse a linked worktree; refuse the harness's own checkout | the `--git-common-dir` idiom already written twice (`validate.sh:16-53`, `driver-lock-lib.sh:20-35`) — do not write a third |
    66	| 3. Derived name | `basename "$PWD"` equals `marathon-gh-<n>-<slug>`, `<n>` from rule 1's key | nothing new; the name is checked against data already in hand |
    67	
    68	Escape hatch: one env override per rule, **announced on stderr, never silent** — the GH-45 pattern
    69	verbatim. A bypass that says nothing is indistinguishable from no guard.
    70	
    71	## Phases
    72	
    73	1. **The three conditions + the `umbrella:` key.** One edit to the existing refusal block.
    74	2. **Controls.** Three reds (one per rule, each fired against a fixture) and one green (a
    75	   correctly-shaped marathon still runs), recorded in `test/baselines/`. Per §13 a green gate with
    76	   no witnessed red is not evidence — and rule 3's green control matters most, because a
    77	   too-strict name regex would refuse every real marathon while looking like a working guard.
    78	
    79	## The one place a reviewer should push back
    80	
    81	Rule 2's "never the primary checkout" has **no precedent in the tree**. GH-45 deliberately *allows*
    82	the primary checkout for `validate.sh`, and `test/gh35-test-tiers.sh:367-370` asserts that as an
    83	explicit CONTROL. Refusing it for marathons is a new posture, not an extension of an existing one.
    84	It is the piece most likely to be over-engineering, and the reviewers are asked to rule on it
    85	directly.
    86	
    87	## Swarm Preflight Contract
    88	
    89	```json
    90	{
    91	  "target":      { "repo": ".", "ref": "development" },
    92	  "gate":        "bash validate.sh",
    93	  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "umbrella" } ],
    94	  "artifacts":   [
    95	    "relay-automation/marathon.sh",
    96	    "test/gh419-marathon-rule-enforcement.sh",
    97	    "test/baselines/GH-419-negative-control.md"
    98	  ],
    99	  "remediation": { "source": "issue#419", "criteria": "a marathon without a valid umbrella key, or from a worktree/primary checkout, or in a wrongly-named folder, is refused exit 2; each refusal is overridable by one announced env var; a correctly-shaped marathon still runs" },
   100	  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
   101	}
   102	```
   330	    touched deliberately or by an escaped fixture. Only a **separate full clone** isolates any of it.
   331	  - **Why it escapes at all:** `git -C ""` is documented to leave the working directory unchanged and
   332	    `cd ""` is a bash no-op, and these suites run without `set -e` — so one unguarded
   333	    `r="$(mktemp -d …)"` silently redirects every "fixture" operation onto the caller's clone. It
   334	    fires under **parallel** load (the failure mode of `mktemp`), which is why a serial re-run of the
   335	    same suite reproduces nothing and must not be read as an all-clear. GH-177 family.
   336	  - **Until #564's suite-wide invariant gate lands**, treat any clone you ran the suite in as
   337	    suspect: check `git config --get core.bare`, `git remote -v`, `git config --local --get user.email`,
   338	    and `git log --oneline -1` before trusting a push, a fetch, or a green run from it. A guarded
   339	    fixture helper (`require_fixture`: the path must exist AND live under `$WORK` — containment, not
   340	    a null check) is the pattern to copy; `test/gh544-pre-push-gate.sh` has it, 31 other suites do
   341	    not.
   342	  - **Validate a sandbox path at the USE boundary, not where it was created (GH-567).** An empty
   343	    variable does not fail — `git -C ""` uses the current directory, `cd ""` is a no-op,
   344	    `rm -rf "$VAR/"` becomes `/`, `find "$VAR" -delete` becomes `.`. So guard immediately before the
   345	    first dangerous use **in every function that receives the path**, not once at the `mktemp` that
   346	    derived it: a variable that was safe at line 10 can be empty at line 50, and a derivation-site
   347	    check never covers a path passed in from elsewhere. Assert non-empty, a **resolved** descendant
   348	    of the sandbox root, and the expected type — `require_fixture`'s current `case "$p" in "$WORK"/*)`
   349	    is lexical and still accepts `$WORK/../../<real repo>`, so harden it before copying it into the
   350	    other 31. `set -e` is not the containment proof; these suites deliberately run without it.
   351	  - **A clone whose identity changed under a run cannot attribute that run (GH-567).** If a suite
   352	    fails only under parallel load, compare `core.bare`, `git remote -v`, the local user identity and
   353	    `HEAD` against their pre-run values **before** blaming your diff. Unexpected drift invalidates
   354	    every result from that clone — re-clone, then run candidate and base at the same width. Identity
   355	    intact means it is your diff or ordinary flakiness: investigate normally. This is a trigger, not a
   356	    licence to write failures off as harness noise; the 2026-08-15 incident cost several full-suite
   357	    runs to a single green control run treated as proof, which is one sample from a nondeterministic
   358	    process.
   359	  - **An audit that recognizes only one invocation shape stops covering the same operation reached a
   360	    different way (GH-195).** `marathon-root-audit.sh` exists (GH-401) specifically to catch an
   361	    unscoped marathon-drive invocation writing into the real clone instead of a fixture — but its
   362	    detector only matches `bash <driver>.sh`. A test that calls `python3 marathon_drive.py` directly
   363	    is invisible to it. That exact gap let `test/gh115-round-cap.sh` commit a live transcript onto
   364	    whichever real clone was running `validate.sh`, every single run, reproduced across 4 separate
   365	    clones including a brand-new one. **If you add or harden an audit that matches on invocation
   366	    text, ask what it does NOT match, not just what it does.** Diagnosing this cost ~2.5h chasing
   367	    plausible-but-wrong external causes (a leftover process, a second concurrent agent, a scheduled
   368	    job) before a one-shot stack-trace at the actual write call site named the real culprit in one
   369	    run — when a repeatable artifact exists (here: the per-clone `.tick/attempts/<phase>` fire
   370	    ledger, timestamp-correlated to each gate run), inspect it directly before building a
   371	    process-hunting hypothesis chain. Full writeup:
   372	    [GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md](PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md).
   373	- **The local macOS run is the gate; hosted ubuntu is advisory (GH-509).** XYZ is a developer toolkit
   374	  for **macOS**; Linux and Windows are on the roadmap and not here yet. So `./validate.sh` (or
   375	  `./ci-local.sh`) on your Mac is the highest-fidelity evidence available — it is the shipping
   376	  platform with the real toolchain — and it runs a **superset** of the hosted job, including
   377	  `registry-lock-concurrency.sh`, which CI skips for a contended-Linux flake. The hosted `canary-ubuntu`
   378	  job is `continue-on-error: true`: its red means *portability drift*, not breakage, and must not be
   379	  reported as a broken commit. Two consequences that bite: **never defer a test run to CI** — CI is
   380	  advisory and tests the wrong OS; and **a green local run is self-reported**, so it does not qualify a
   381	  promotion. Promotion needs a hosted **macOS** run for that exact commit. When a claim really is about
   382	  Linux, the canary is the right instrument and its red is authoritative.
   383	- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
   384	  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
   385	  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
100:**A check that cannot fail is not a check.** A passing assertion is evidence only once you have seen
109:**An empty input passes every check.** Before asserting anything about extracted data, assert that

2026-09-03T19:03:22.880975Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 94 column 5
codex
**ANSWER — REVISE.** Extending `marathon.sh` is the right minimal execution hook, and `umbrella:` is the right new input; however, the design cannot accept that key today and checks the wrong root in supported cross-repo runs.

**FINDINGS**

- **[Blocker]** `bin/marathon-yaml` rejects every unknown top-level key, so `umbrella:` makes the proposed plans unparsable (`unexpected top-level line`) rather than enforceable. Add `umbrella` to that parser’s top-level schema/output and test it; the proposal’s “one edit” and artifact list are therefore false. [bin/marathon-yaml:41-57](bin/marathon-yaml:41), [GH-419 design:50-58](PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md:50)

- **[Should]** Define one canonical *execution clone root*—`TARGET_ROOT` when supplied, otherwise `ROOT`—and derive both worktree status and basename from it, not `$PWD`. `marathon.sh` intentionally has separate harness and target roots, and `--target-root` makes the plan/briefs belong to the target repo. A `$PWD` guard will refuse valid invocations or validate the harness clone instead of the clone that receives the work. [relay-automation/marathon.sh:54-60](relay-automation/marathon.sh:54), [relay-automation/marathon.sh:95-106](relay-automation/marathon.sh:95), [relay-automation/marathon.sh:157-162](relay-automation/marathon.sh:157)

- **[Should]** Resolve the `TMP-XXXXXX` contradiction before implementation. The design permits it but requires `marathon-gh-<n>-…`, where a temporary token has no numeric issue number. Either disallow TMP for an executable marathon or specify its deterministic folder form. The ledger’s token validator does accept TMP, but only as a shape check. [GH-419 design:62-66](PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md:62), [releases_app.py:1675-1694](utils/py/releases_app.py:1675)

- **[Should]** **Drop the “primary checkout” half of rule 2 entirely.** Git can reliably identify a linked worktree, but cannot identify an operator’s semantically “primary” full clone without adding state/configuration; the existing two-root model explicitly supports development-checkout use. Enforce “not linked worktree” plus the derived-name rule and retain the documented operational warning. If this call is wrong, an operator can still run a marathon in their valuable main full clone and expose it to marathon/test mutations—but a brittle pseudo-detection would quietly refuse legitimate standalone clones. [validate.sh:27-45](validate.sh:27), [test/gh35-test-tiers.sh:366-372](test/gh35-test-tiers.sh:366), [relay-automation/README.md:149-163](relay-automation/README.md:149)

- **[Pass]** `marathon.sh` is the cheapest reliable hook for a multi-phase marathon: its existing plan refusal is before execution and returns exit 2. `swarm-preflight`, PDDA, the ledger, and a push hook are optional/preparatory or too late; bare `marathon-drive.sh` is explicitly a distinct standalone flow. [relay-automation/marathon.sh:144-178](relay-automation/marathon.sh:144), [relay-automation/README.md:83-88](relay-automation/README.md:83)

- **[Pass]** No existing YAML field carries the umbrella identity: current `name` values are arbitrary plan names, while the ledger has a tracking reference that the executor does not read. `umbrella:` is justified; do not add a ledger lookup or write path. [PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:54-55](PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:54), [releases_app.py:2488-2503](utils/py/releases_app.py:2488)

- **[Pass]** The planned red controls are directionally correct and required: a passing-only check is explicitly non-evidence. [AGENTS.md:100-112](AGENTS.md:100)

**Biggest risk:** the unmodified YAML parser rejects `umbrella:`; the feature would ship with a plausible guard in `marathon.sh` but every compliant manifest would fail before reaching it.

**RECOMMENDATION:** Revise the plan to include the parser change, root-selection contract, and TMP naming decision; keep the `marathon.sh` hook, but remove primary-checkout refusal.
tokens used
94,725
**ANSWER — REVISE.** Extending `marathon.sh` is the right minimal execution hook, and `umbrella:` is the right new input; however, the design cannot accept that key today and checks the wrong root in supported cross-repo runs.

**FINDINGS**

- **[Blocker]** `bin/marathon-yaml` rejects every unknown top-level key, so `umbrella:` makes the proposed plans unparsable (`unexpected top-level line`) rather than enforceable. Add `umbrella` to that parser’s top-level schema/output and test it; the proposal’s “one edit” and artifact list are therefore false. [bin/marathon-yaml:41-57](bin/marathon-yaml:41), [GH-419 design:50-58](PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md:50)

- **[Should]** Define one canonical *execution clone root*—`TARGET_ROOT` when supplied, otherwise `ROOT`—and derive both worktree status and basename from it, not `$PWD`. `marathon.sh` intentionally has separate harness and target roots, and `--target-root` makes the plan/briefs belong to the target repo. A `$PWD` guard will refuse valid invocations or validate the harness clone instead of the clone that receives the work. [relay-automation/marathon.sh:54-60](relay-automation/marathon.sh:54), [relay-automation/marathon.sh:95-106](relay-automation/marathon.sh:95), [relay-automation/marathon.sh:157-162](relay-automation/marathon.sh:157)

- **[Should]** Resolve the `TMP-XXXXXX` contradiction before implementation. The design permits it but requires `marathon-gh-<n>-…`, where a temporary token has no numeric issue number. Either disallow TMP for an executable marathon or specify its deterministic folder form. The ledger’s token validator does accept TMP, but only as a shape check. [GH-419 design:62-66](PROJECT/1-INBOX/GH-419-MARATHON-RULE-ENFORCEMENT.md:62), [releases_app.py:1675-1694](utils/py/releases_app.py:1675)

- **[Should]** **Drop the “primary checkout” half of rule 2 entirely.** Git can reliably identify a linked worktree, but cannot identify an operator’s semantically “primary” full clone without adding state/configuration; the existing two-root model explicitly supports development-checkout use. Enforce “not linked worktree” plus the derived-name rule and retain the documented operational warning. If this call is wrong, an operator can still run a marathon in their valuable main full clone and expose it to marathon/test mutations—but a brittle pseudo-detection would quietly refuse legitimate standalone clones. [validate.sh:27-45](validate.sh:27), [test/gh35-test-tiers.sh:366-372](test/gh35-test-tiers.sh:366), [relay-automation/README.md:149-163](relay-automation/README.md:149)

- **[Pass]** `marathon.sh` is the cheapest reliable hook for a multi-phase marathon: its existing plan refusal is before execution and returns exit 2. `swarm-preflight`, PDDA, the ledger, and a push hook are optional/preparatory or too late; bare `marathon-drive.sh` is explicitly a distinct standalone flow. [relay-automation/marathon.sh:144-178](relay-automation/marathon.sh:144), [relay-automation/README.md:83-88](relay-automation/README.md:83)

- **[Pass]** No existing YAML field carries the umbrella identity: current `name` values are arbitrary plan names, while the ledger has a tracking reference that the executor does not read. `umbrella:` is justified; do not add a ledger lookup or write path. [PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:54-55](PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/MARATHON.yaml:54), [releases_app.py:2488-2503](utils/py/releases_app.py:2488)

- **[Pass]** The planned red controls are directionally correct and required: a passing-only check is explicitly non-evidence. [AGENTS.md:100-112](AGENTS.md:100)

**Biggest risk:** the unmodified YAML parser rejects `umbrella:`; the feature would ship with a plausible guard in `marathon.sh` but every compliant manifest would fail before reaching it.

**RECOMMENDATION:** Revise the plan to include the parser change, root-selection contract, and TMP naming decision; keep the `marathon.sh` hook, but remove primary-checkout refusal.
