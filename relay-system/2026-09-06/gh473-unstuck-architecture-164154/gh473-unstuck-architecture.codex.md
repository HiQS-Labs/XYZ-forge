**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-09-06T23:41:56.603378Z  WARN codex_skills::interface: ignoring interface.icon_small: icon path with '..' must resolve under plugin assets/
2026-09-06T23:41:56.603768Z  WARN codex_skills::interface: ignoring interface.icon_large: icon path with '..' must resolve under plugin assets/
2026-09-06T23:41:56.621083Z  WARN codex_core::agents_md: project doc exceeds remaining budget; truncating path=file:///private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-95764-zxehmm18/AGENTS.md remaining_bytes=32768
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-95764-zxehmm18
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a07919-9bbe-7790-bdf6-cee69e0604ab
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review the proposed new skill at `skills/unstuck/SKILL.md`, its boundary decision in
`PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md`, and the three-line handoff added to
`skills/workhorse/SKILL.md`.

Answer one binary architectural question: should this mid-flight recovery behavior remain a
separate `/unstuck` skill with a narrow `/workhorse` handoff, or should it be folded into
`/workhorse` itself?

Good means: it reliably interrupts overengineering and review-loop churn, restores movement toward
the original goal, does not dismiss real correctness/safety blockers, and does not become another
heavy process that keeps the agent stuck. Identify any blocking defect in the proposed five-rung
contract. Advisory only; do not edit files.

codex
I’ll use the repository’s codebase-memory workflow at Verify depth, then read the cited skill and boundary docs directly for line-specific evidence.
exec
/bin/zsh -lc "sed -n '1,240p' /Users/noelsaw/.codex/skills/codebase-memory/SKILL.md && sed -n '1,220p' ROUTER.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-95764-zxehmm18
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
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = the *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`); the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth (`ROADMAP.md` retired per GH-269)
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `MACHINE-CONTRACTS.md` = the Jog ↔ Preflight ↔ Marathon machine-contract reference (`marathon-invocation@1`, `marathon-drive/result@1`) and their version/deprecation policy
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is retired — the RELEASES DB is the single source of truth.)
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Governance lives in `PROJECT/PDDA.md` → "ROADMAP contract".
- Promoting a capture from `1-INBOX` to `2-WORKING` is a DB-verb procedure (`roadmap repoint` + `roadmap update` / `roadmap move`), never a markdown edit — the exact steps and their two known gate traps (`updated:` frontmatter key, bullet-format `raw_text`) live in `SOP.md` → "Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP contract".
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in the roadmap ledger immediately** (`releases roadmap add`) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
- **`GH-<n>` numbering spans two repos.** This repo succeeded [`Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm) and the migration did **not** renumber references, so a `GH-<n>` in a source comment, test name, or CHANGELOG entry may belong to either repo. Upstream ledger entries are preserved verbatim in [`docs/ROADMAP-UPSTREAM-ARCHIVE.md`](docs/ROADMAP-UPSTREAM-ARCHIVE.md), which states its own numbering caveat and is not parsed by anything. Where an upstream number is cited from code that ships here, mirror it as a closed `[upstream archive]` issue so the citation resolves locally (#407, #408 are the pattern) rather than editing the comment. Raised externally as GH-406 §3.1.
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## Command rails

For repo correctness:

```bash
bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
bash githooks/install.sh --check # is this clone gated? exit 1 if not
./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
./validate.sh --sequential # force the sequential run (~16 min)
./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
```

**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
remote refs, development). Run the gate from a normal clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
announced override for disposable runs.

**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
install covers every branch and every linked worktree of that clone (GH-549). Bypass with
`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
goes public (free there).

**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
3-minute one. **GH-35 (2026-08-18) rebalanced the width to `cores/2` (floor 2, cap 4) and put every
worker under `nice -n 10`** — the original `cores − 2` (up to 8) saturated developer machines badly
enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
and the reason, so a fallback is never silent.

**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
agent-chorus); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
`--tier 1` runs the docs gate, and everything else — unknown paths, test edits, kernel surfaces —
runs the full suite. `--auto` classifies a local diff the same way. Tiers 1 and 2 are pre-push
speed and are labelled NOT promotion evidence; only `ci-local.sh`'s sequential full run qualifies
(GH-509).

**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
decision taken with that evidence outstanding, mitigated by the announced fallback rather than
discharged. See `PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md`, #509 and #544.

For document hygiene:

```bash
utils/pdda/pdda.sh run
```

For targeted PDDA debugging (subcommands of the single dispatcher):

```bash
utils/pdda/pdda.sh frontmatter
utils/pdda/pdda.sh status-table
utils/pdda/pdda.sh hardcoded-paths
utils/pdda/pdda.sh roadmap
utils/pdda/pdda.sh roadmap-coverage
utils/pdda/pdda.sh changelog
utils/pdda/pdda.sh stale
utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
utils/pdda/pdda.sh releases         # validate RELEASES.md, the OPTIONAL release-planning ledger (warn-only; skips a missing file)
utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
utils/pdda/pdda.sh gh-refresh       # refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
utils/pdda/pdda.sh catchup          # LLM repo triage + ROUTER.md recommendations (delegates to pdda-catchup.sh)
utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
```

## The RELEASES DB — two subsystems, one ledger (GH-32 / GH-69)

`releases.db` + `releases.sql` hold TWO mirrored subsystems, both operated through ONE CLI,
`utils/py/releases_app.py` (alias: the `/releases` skill). Read
[RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file — the SQLite binary is
derived; the SQL dump is what git actually merges, and a conflicted merge has a one-command
resolver (`utils/releases-merge-resolve.sh`).

```bash
python3 utils/py/releases_app.py check          # trio consistency, receipt chain, crash recovery
python3 utils/py/releases_app.py next           # the next unshipped release, by target date
python3 utils/py/releases_app.py add|ship ...   # RELEASE writes — never hand-edit releases.sql
python3 utils/py/releases_app.py roadmap add ... # GH-238: park one issue as a roadmap row (the intake write path)
                                                #   GH-249: put `rated N/N/N/N [ovr N]` in --raw-text to score it
python3 utils/py/releases_app.py roadmap rate ...# GH-253: score a row that is ALREADY parked (--force to re-score)
python3 utils/py/releases_app.py roadmap list   # read the roadmap rows (--json for machine consumers)
python3 utils/py/releases_app.py roadmap sync   # LEGACY-mode only (mirrors ROADMAP.md); a guarded no-op in this repo
```

**Subsystem 1 — releases** (GH-32, Phase 0 side-by-side): the release ledger. App-managed writes
only; `RELEASES.md` is still the human file during the shadow phase.
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical → GH-269 retired ROADMAP.md): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list` / `ROADMAP-DASHBOARD.md`.
`ROADMAP.md` has been retired and removed. `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`,
`test/gh238-hq-releases-mode.sh`, and `test/gh269-roadmap-retired.sh`.

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP-DASHBOARD.md` (or `releases roadmap list`), then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap add` for intake; `hq park` routes there automatically) and finish by regenerating `ROADMAP-DASHBOARD.md` (`utils/roadmap-dashboard.sh`) — the push gate refuses a ledger write with a stale dashboard (GH-243).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in the dashboard's queue section (or `releases roadmap list`), then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It reads and synthesizes `RELEASES.md` first, then routes explicit requests into confirmation-gated cleanup, planning, or publication; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended variation-test fuzzing whose implementation lives under `utils/ate/` — start at its canonical interface in `skills/ate/SKILL.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

exec
/bin/zsh -lc 'wc -l skills/unstuck/SKILL.md PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md skills/workhorse/SKILL.md GUIDING-PRINCIPLES.md PROJECT/PDDA.md && nl -ba skills/unstuck/SKILL.md && nl -ba PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md && nl -ba skills/workhorse/SKILL.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-95764-zxehmm18
 succeeded in 0ms:
     134 skills/unstuck/SKILL.md
      67 PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md
     223 skills/workhorse/SKILL.md
     178 GUIDING-PRINCIPLES.md
    1114 PROJECT/PDDA.md
    1716 total
     1	---
     2	name: unstuck
     3	description: >-
     4	  Interrupt a stalled AI work session and restore movement toward the original
     5	  outcome. Use when the agent is overengineering, inventing machinery around the
     6	  work, reopening settled decisions, exhausting review rounds, polishing controls
     7	  after the plan is ready, or reporting lots of activity with no milestone change.
     8	  Also fires on /unstuck, "we're stuck", "rabbit hole", "stop overengineering",
     9	  "the cogs are moving but the goal isn't", or "get back to the plan". Do not use
    10	  for a new ambiguous problem that needs the full /workhorse ladder, a still-unknown
    11	  failure that needs /debug-mantra, or ordinary implementation minimization that
    12	  /ponytail already covers.
    13	metadata:
    14	  argument-hint: "[original goal or current stalled session]"
    15	---
    16
    17	# /unstuck — Goal-Movement Interrupt
    18
    19	`unstuck` is a mid-flight interrupt, not another planning framework. It stops a session that is
    20	optimizing its own machinery instead of changing the state of the user's task.
    21
    22	The governing question is:
    23
    24	> **What is the smallest action that changes the original goal's observable state?**
    25
    26	Activity is not movement. More findings, helpers, review rounds, scaffolding, or stronger controls
    27	do not count unless they enable the next milestone or prevent a demonstrated correctness or safety
    28	failure.
    29
    30	## The five-rung recovery ladder
    31
    32	```text
    33	1. Freeze the cogs       ──► Stop adding machinery, reviews, and scope; preserve current work
    34	2. Re-anchor the goal    ──► Original outcome, current milestone, last verified movement
    35	3. Test the blocker      ──► Required to advance, required for safety, polish, or machinery?
    36	4. Choose one next move  ──► Smallest bounded action that changes task state
    37	5. Act, verify, exit     ──► One action, one movement check, one explicit next state
    38	```
    39
    40	### Rung 1 — Freeze the cogs
    41
    42	Pause invention before diagnosing the stall. Do not add a helper, abstraction, cache, wrapper,
    43	review round, orchestration layer, new plan, or new acceptance gate during this rung. Do not discard
    44	working changes either.
    45
    46	Record four lines:
    47
    48	- original requested outcome;
    49	- current milestone;
    50	- last action that measurably advanced it;
    51	- activity consuming time now.
    52
    53	An exhausted round cap is a boundary, not an invitation to raise the cap. A settled decision stays
    54	settled unless new evidence contradicts it.
    55
    56	### Rung 2 — Re-anchor the finish line
    57
    58	State the nearest observable milestone in one sentence. It must describe changed task state, such
    59	as “the accepted plan is launched,” “the failing test passes,” “the PR exists,” or “the operator has
    60	chosen between A and B.” “Improve the helper,” “make the review cleaner,” and “investigate further”
    61	are activities, not milestones.
    62
    63	List only what must be true for that milestone. Preserve explicit user requirements and repository
    64	gates; delete self-created prerequisites from the critical path.
    65
    66	### Rung 3 — Test the claimed blocker
    67
    68	For every remaining item, ask:
    69
    70	> **If this item were fixed now, could the next milestone proceed?**
    71
    72	Classify it from evidence, not discomfort:
    73
    74	| Class | Meaning | Disposition |
    75	|---|---|---|
    76	| Goal blocker | Its absence directly prevents the next milestone | Fix the narrow blocker |
    77	| Required correctness or safety | A failing check, violated contract, data-loss/security risk, or explicit gate | Satisfy it; never dismiss it as a cog |
    78	| External decision or dependency | Progress genuinely requires authority, input, credentials, or outside state | Ask one exact question or name the dependency |
    79	| Polish | Improves confidence or elegance but does not gate the milestone | Park it |
    80	| Cog | New machinery, process, or review about doing the work | Stop it and use the existing path |
    81
    82	A review finding is not automatically blocking because a reviewer found it. Tie it to an acceptance
    83	criterion, observable failure, safety invariant, or required gate. Conversely, do not relabel a real
    84	failure as polish merely to create motion.
    85
    86	### Rung 4 — Choose one goal-moving action
    87
    88	Choose the first safe option that applies:
    89
    90	1. execute the already accepted plan or next committed step;
    91	2. fix one narrow, evidenced blocker, then resume the plan;
    92	3. use an existing seam, supported command, or bounded manual bridge instead of building machinery;
    93	4. ask the operator one crisp decision that genuinely cannot be inferred.
    94
    95	Do not produce a new multi-step plan unless the old one is invalidated by evidence. Park optional
    96	ideas in the current thread or existing project document; do not create a new artifact merely to
    97	park them.
    98
    99	If two plausible paths remain and the choice materially affects the outcome, run **one** `/consult`
   100	with a binary question: “Which option advances the stated milestone with fewer new assumptions?”
   101	The coordinator breaks the tie. No second consult, no review of the review, and no cap extension.
   102
   103	Before acting, retain normal authorization and safety boundaries. `/unstuck` removes self-created
   104	process debt; it never grants permission to push, publish, delete, spend money, bypass a gate, or
   105	perform an irreversible operation.
   106
   107	### Rung 5 — Act once, verify movement, exit
   108
   109	Take the selected action. Then check the milestone itself, not the machinery around it.
   110
   111	Return this receipt:
   112
   113	```text
   114	UNSTUCK
   115	Goal: <original outcome>
   116	Stall: <what was consuming motion>
   117	Move: <single action taken or exact decision requested>
   118	Evidence: <observable milestone change or named blocker>
   119	Parked: <non-blocking cogs/polish, or none>
   120	Next: <one next task state>
   121	```
   122
   123	If the action did not move the goal, do not invent another mechanism. Name the falsified assumption,
   124	reclassify the blocker once, and either take the now-obvious existing path or stop on the exact
   125	external dependency. The skill ends when movement resumes or the real blocker is legible.
   126
   127	## Routing boundary
   128
   129	- Start a complex problem from scratch with `/workhorse`.
   130	- Minimize an implementation that is otherwise moving with `/ponytail`.
   131	- Diagnose an unknown failure with `/debug-mantra`.
   132	- Interrupt a live process whose activity no longer advances its goal with `/unstuck`.
   133
   134	The shortest path back to the plan is the product.
     1	---
     2	gh_issue: 473
     3	source: https://github.com/HiQS-Labs/XYZ-forge/issues/473
     4	title: "feat(skill): add /unstuck goal-movement interrupt"
     5	status: Active
     6	created: 2026-09-06
     7	updated: 2026-09-06
     8	owner: Codex
     9	goal: give stalled AI sessions a bounded recovery ladder that restores movement toward the original outcome
    10	doc_type: feedback
    11	effort: 1
    12	complexity: 2
    13	risk: 1
    14	phases: 1
    15	---
    16
    17	# GH-473: Unstuck Skill
    18
    19	## Status
    20
    21	| What was just completed | What's next |
    22	|---|---|
    23	| Failure shape captured from a session that exhausted review caps while polishing supporting machinery; `/unstuck` selected as a separate mid-flight interrupt | Implement the recovery ladder, add the narrow `/workhorse` handoff, then forward-test realistic stalled-session prompts |
    24
    25	## Decision
    26
    27	Keep `/unstuck` separate from `/workhorse`.
    28
    29	`/workhorse` begins with an ambiguous problem and supplies a governed end-to-end method. `/unstuck`
    30	begins later, when a method is already in flight but the session is looping, inventing machinery,
    31	reopening settled decisions, or treating review activity as progress. Folding both into one ladder
    32	would make workhorse heavier at its healthy path and make the interrupt harder to invoke when the
    33	agent needs a sharp context reset.
    34
    35	The only workhorse change is a handoff: when successive passes produce no observable goal movement,
    36	route to `/unstuck` instead of automatically adding another diagnostic, design, or review cycle.
    37
    38	## Recovery contract
    39
    40	The skill must:
    41
    42	1. restate the original outcome, current milestone, last verified movement, and exact blocker;
    43	2. classify current activity as goal-blocking work, required safety/correctness, optional polish, or
    44	   machinery about the work;
    45	3. test every claimed blocker with: “If this is fixed, can the next milestone proceed?”;
    46	4. freeze settled decisions and park non-blocking ideas without implementing them;
    47	5. select one smallest bounded action that changes externally observable task state;
    48	6. use at most one `/consult` for a genuine tie, ask a binary decision, and have the coordinator
    49	   break disagreement rather than start another review loop;
    50	7. report whether the action moved the goal and stop if a real external decision or dependency is
    51	   still required.
    52
    53	Safety, preservation, explicit user scope, and real correctness failures are never dismissed as
    54	“cogs.” The skill removes self-created process debt; it does not waive gates that protect people,
    55	data, security, or irreversible state.
    56
    57	## Acceptance criteria
    58
    59	1. Add a concise, self-contained `skills/unstuck/SKILL.md` with discriminating triggers.
    60	2. Keep the boundary with `/workhorse`, `/ponytail`, and `/debug-mantra` explicit.
    61	3. Add only one narrow handoff to `skills/workhorse/SKILL.md`.
    62	4. Forward-test a review-cap loop, a proposed new helper subsystem, and a genuine unresolved blocker.
    63	5. Pass the skill validator and relevant PDDA checks.
    64
    65	## Lessons Learned (For Future Agents)
    66
    67	Pending implementation and forward test.
     1	---
     2	name: workhorse
     3	description: >
     4	  End-to-end disciplined problem resolution ladder: establishes ground truth via
     5	  /debug-mantra, engineers the leanest safe solution via /ponytail (reusing and
     6	  extending existing subsystems with zero code sprawl), enforces AGENTS.md, SOP.md,
     7	  and GUIDING PRINCIPLES governance, checks cross-repo CHANGELOG cohesion, stress-tests
     8	  the plan via /consult with Codex and Agy, runs bounded /recon on ambiguous stateful
     9	  targets, proves preservation before irreversible operations, and executes with verified
    10	  runnable checks.
    11	  Trigger on /workhorse, "workhorse", "tackle this", "work through this problem",
    12	  "methodical progress", or when an ambiguous or complex task requires structured,
    13	  governed execution across the full ladder.
    14	metadata:
    15	  argument-hint: "[task, PR, issue, or problem description]"
    16	---
    17
    18	# /workhorse — Governed End-to-End Problem Resolution Ladder
    19
    20	`workhorse` is a 6-rung execution ladder that transforms ambiguous symptoms, complex bugs, PR reviews, or feature requests into clean, minimal, cross-model-verified, durable solutions.
    21
    22	It coordinates existing specialized skills (`debug-mantra`, `recon`, `ponytail`, `consult`) and repository governance rules rather than creating duplicate procedural abstractions.
    23
    24	---
    25
    26	## The 6-Rung Ladder
    27
    28	```text
    29	1. Ground Truth & Diagnostics  (/debug-mantra)  ──► Reproduce raw artifact, trace paths, falsify hypotheses
    30	2. Least-Mechanism Design      (/ponytail)      ──► YAGNI, stdlib first, ZERO duplicate subsystems, minimal diff
    31	3. Governance & Cohesion Gate                   ──► AGENTS.md, SOP.md, GUIDING-PRINCIPLES.md, CHANGELOG parity
    32	4. Cross-Model Consensus       (/consult)       ──► Parallel fan-out (Codex + Agy), reconcile disagreements
    33	5. Preservation & Irreversibility Gate          ──► Inventory state, prove preservation, establish rollback or confirm loss
    34	6. Governed Execution & Verification            ──► Apply minimal diff, execute runnable checks, verify done
    35	```
    36
    37	---
    38
    39	## Rung 1: Ground Truth & Diagnostics (`/debug-mantra`)
    40
    41	Establish primitive ground truth before theorizing or proposing any changes.
    42
    43	1. **First is reproducibility / raw artifact inspection:**
    44	   - For a failure/bug: capture a fast, deterministic runnable repro (failing test, curl, CLI run).
    45	   - For an attribution or architecture question: inspect the raw object (database row, message payload, exact file lines) before assuming. Screenshots, rendered views, and memory are **hypothesis-zero**, not axioms.
    46	2. **Know the fail path:**
    47	   - Trace the execution path end-to-end. Enumerate all controlling knobs (configs, env vars, branch conditions, concurrency).
    48	   - Flip one axis at a time in the differential.
    49	3. **Question your hypothesis (Disproof First):**
    50	   - Generate 2–3 ranked hypotheses. Identify the cleanest **disproof** for each.
    51	   - Run the disproof first: if it fails, discard immediately to avoid chasing phantoms.
    52	4. **Every run is a breadcrumb:**
    53	   - Maintain a running session ledger of observations, probes, and ruled-out paths.
    54
    55	*When the target is a plan, PR, or architecture (Plan Pivot):*
    56	- Measure ground truth at plan time (re-run live counts and file:lines; do not cite remembered state).
    57	- Trace the exact path being modified across all callers before proposing modifications.
    58	- Falsify acceptance criteria (specify how each criterion fails and where red-control evidence lands).
    59	- Maintain a recon ledger against what has already shipped.
    60
    61	---
    62
    63	## Rung 2: Least-Mechanism Architecture (`/ponytail`)
    64
    65	Channel a pragmatic senior engineer: build the simplest, shortest, most durable mechanism that satisfies the requirement.
    66
    67	1. **The Ponytail Rungs:**
    68	   - *Rung 1:* Does this added code/machinery need to exist at all? (YAGNI).
    69	   - *Rung 2:* Standard library does it? Use it.
    70	   - *Rung 3:* Native platform/framework feature covers it? Use it.
    71	   - *Rung 4:* Already-installed dependency solves it? Use it. Never add dependencies for what a few lines can do.
    72	   - *Rung 5:* Can it be a small focused diff? Shortest working diff wins.
    73	2. **The Subsystem Reuse Law:**
    74	   - **Do not invent new modules, helper utilities, or parallel execution paths.**
    75	   - Audit existing modules in `src/rebalance/lib/`, `XYZ-forge/utils/`, etc., and extend them logically.
    76	   - Extending an existing abstraction beats standing up a parallel, siloed system that will silently drift.
    77	3. **Deliberate Shortcuts & Runnable Checks:**
    78	   - Mark deliberate minimal simplifications with an explanatory comment (e.g. `// ponytail: sqlite single-thread, revisit if throughput exceeds threshold`).
    79	   - Every non-trivial change leaves behind **one runnable check** (an assert-based check, unit test, or integration probe).
    80
    81	---
    82
    83	## Rung 3: Governance & Cross-Repo Cohesion
    84
    85	Validate that the proposed minimal solution complies with the repository's foundational rules and history.
    86
    87	1. **`AGENTS.md` Alignment:**
    88	   - Respect single entry points (e.g. orchestrator dispatch chains in `index_ops.py` or `releases_app.py`).
    89	   - Honor disabled or paused subsystems (never silently revive paused components).
    90	   - Adhere to containment and worktree safety rules.
    91	2. **`SOP.md` Alignment:**
    92	   - Any performance or efficacy claim must be backed by measurable, reproducible test evidence.
    93	   - Follow the issue-first and capture-doc protocols where required.
    94	3. **`GUIDING-PRINCIPLES.md` Alignment:**
    95	   - Check the North Star: Durable, Reversible, DRY.
    96	   - Single-writer per contract/table.
    97	   - Introduce an FSM if state transitions exceed 4 states or multiple conditional branches.
    98	4. **`CHANGELOG.md` Check:**
    99	   - Review recent entries in `CHANGELOG.md` across relevant repos (`XYZ-forge`, `rebalanceOS`, etc.).
   100	   - Ensure terms, patterns, and architectural conventions match the active codebase state rather than legacy/superseded patterns.
   101	5. **PDDA & Releases Ledger Intake:**
   102	   - *Tracking Doc:* For non-trivial tasks, confirm a capture doc exists in `PROJECT/1-INBOX/` or `PROJECT/2-WORKING/` with frontmatter `status: active`.
   103	   - *Releases DB / Roadmap:* Verify the issue is registered in `releases.db` (`releases roadmap add <GH-NUM>` / `releases jog add`) in releases-mode repos.
   104
   105	---
   106
   107	## Rung 4: Cross-Model Consensus (`/consult`)
   108
   109	Stress-test the finalized plan or architecture across independent AI models before touching production code.
   110
   111	1. **Fan-Out (`consult.sh`):**
   112	   - Formulate a crisp prompt referencing the real file paths and problem context.
   113	   - Run `consult.sh --prompt "..." --label ...` to query **Codex** and **Agy** in parallel in isolated throwaway worktrees.
   114	2. **Reconcile Without Averaging (Surface the Seams):**
   115	   - **TLDR:** 1–2 sentence summary of the reconciled call and confidence level.
   116	   - **Disagreements:** Explicitly list every point where advisors differed, with your adjudication and technical rationale.
   117	   - **Agreements:** Highlight points where both models independently concurred.
   118	   - **Sorted Categories:**
   119	     - **Blocking:** Legitimate risks or defects caught by an advisor; must be addressed before proceeding.
   120	     - **Worth Doing / Optional:** Valid improvements or cleanups to consider.
   121	     - **Skip / Out of Scope:** Ideas noted and explicitly dismissed with rationale.
   122	3. **Finalize the Plan:** Incorporate blocking feedback directly into the execution steps.
   123	   - If an action is not plainly Easy to reverse, include its provisional resolved target,
   124	     reversibility classification, preservation invariant, evidence, and rollback in the consult.
   125	     Rung 5 revalidates them immediately before execution.
   126
   127	---
   128
   129	## Rung 5: Preservation & Irreversibility Gate
   130
   131	Run this rung before **every** mutation. Easy work records the classification in one line. Costly
   132	and One-way-door operations must produce the full preservation proof below; implementation
   133	complexity never lowers this requirement.
   134
   135	1. **Resolve and classify the exact target:** Name the concrete path, ref, record, service, or
   136	   published artifact and classify the action `Easy`, `Costly`, or `One-way door`. If the target is
   137	   unresolved, stop.
   138	2. **Inventory the relevant state carriers:** Record each carrier as `checked`, `not applicable`, or
   139	   `unknown`; any `unknown` blocks mutation. For multiple stale clones or folders, evaluate each
   140	   candidate separately. If its origin, purpose, or relationship to the canonical destination is
   141	   ambiguous, run a bounded `/recon` **for that candidate** and retain the Recon Map as evidence.
   142	3. **State the preservation invariant:** Say exactly what must remain true after the operation and
   143	   what pre-mutation evidence would prove nothing is lost. Match the evidence to the claim:
   144	   - ancestry proves graph reachability;
   145	   - patch equivalence proves change-set similarity;
   146	   - content or semantic evidence proves bytes or behavior;
   147	   - provenance evidence proves origin and attribution.
   148
   149	   None substitutes for another unless it answers the invariant. In particular, a commit not being
   150	   an ancestor is **not** evidence that its content is missing, and a clean diff is not provenance.
   151	4. **Make recovery or permanent loss explicit:** A Costly operation needs a tested rollback. A true
   152	   One-way door has none: state the exact permanent loss, residual uncertainty, and resolved target,
   153	   then obtain fresh, operation-specific operator confirmation. General permission to work
   154	   unattended is not confirmation of a particular permanent loss.
   155	5. **Bind and refresh the proof:** Bind evidence to the resolved target and current state. Re-run the
   156	   inventory and preservation checks immediately before mutation; a changed path, ref, worktree,
   157	   process/session, or evidence artifact invalidates the prior proof.
   158
   159	**Repository retirement minimum.** Follow `WORKTREE-SAFETY.md` and `/merge-cleanup`, and require its
   160	report to cover dirty, untracked, and relevant ignored files; all ref namespaces, reflogs,
   161	unreachable objects, and stashes; registered worktrees; nested repositories/submodules and
   162	local-only object stores where applicable; remotes and PR state; hooks/config; and active processes
   163	or sessions. A specialized handoff supplies domain mechanics; it does not waive this rung. Reject
   164	an incomplete report and run `/recon` per preservation-unproven clone before disposition.
   165
   166	---
   167
   168	## Rung 6: Governed Execution & Verification
   169
   170	1. **Execute:** Apply the approved minimal diff to the working branch.
   171	2. **Verify:**
   172	   - Run the runnable check left behind in Rung 2.
   173	   - Execute the repository validation suite (e.g., `validate.sh` in XYZ-forge or `pytest` in rebalanceOS).
   174	   - Ensure working tree and tests are green.
   175	   - For destructive work, verify the preservation invariant against the destination or recovery
   176	     artifact. Post-deletion absence alone cannot prove that nothing was lost; the proof must already
   177	     exist from Rung 5.
   178	3. **Ledger Closeout & PDDA Reconciliation:**
   179	   - *Doc Promotion:* If a working doc was created, update frontmatter to `status: completed` and move to `PROJECT/3-COMPLETED/` (or let `wave_reconcile` handle it).
   180	   - *Ledger Integrity:* Run local PDDA/releases checks (e.g. `pdda-local-checks.sh` or `releases roadmap list`) to ensure zero orphaned or unanchored states remain.
   181	4. **Report & Close:**
   182	   - Present a concise completion summary:
   183	     - Root cause & ground truth established (Rung 1).
   184	     - Minimal diff & reused modules (Rung 2).
   185	     - Governance checks passed (Rung 3).
   186	     - Consult reconciliation takeaways (Rung 4).
   187	     - Preservation proof, reversibility classification, and confirmation result (Rung 5).
   188	     - Test execution and verification results (Rung 6).
   189
   190	---
   191
   192	## Proportional Rigor & Escape Hatches
   193
   194	- **Fast-Track (Trivial + Easy to Reverse):**
   195	  Only when an action is both obvious/mechanical/trivial **and** classified Easy to reverse:
   196	  - Execute Rungs 1, 2, 5, and 6 directly (observe ground truth → shortest diff → classify → verify).
   197	  - Explicitly skip Rung 4 in one line: `[workhorse fast-track: trivial and Easy to reverse; skipped consult]`.
   198	  - Destructive, externally published, Costly, or One-way-door actions never fast-track, however
   199	    simple the command or small the diff.
   200
   201	- **Handoff to Specialized Skills:**
   202	  - **Stalled Loop / No Goal Movement:** If successive passes only polish supporting machinery,
   203	    reopen settled decisions, or exhaust a review cap without changing the task milestone, hand off
   204	    to `/unstuck`. Do not restart this ladder or add another consult cycle by default.
   205	  - **Iterative 1:1 Co-Authoring:** If Rung 4 reveals that an artifact requires multiple iterative drafting rounds, hand off to `/relay-xyz`.
   206	  - **Open-Ended Research / Ideation:** If the task is purely investigatory without code modifications, hand off to `/recon` or `/feynman`.
   207	  - **Ambiguous Stale State:** For each stale clone or folder whose disposition is not already
   208	    proven, run a bounded `/recon` before deciding whether to preserve, merge, archive, or remove it.
   209	  - **Immediate Landing / Fleet Cleanup:** When the task is purely about consolidating branches and
   210	    merging PRs, route to `/merge-cleanup` within Rung 5's preservation contract; reject execution
   211	    when its report leaves a relevant carrier unchecked or unknown.
   212
   213	- **Pushback & Routing Authority:**
   214	  If an operator invokes `/workhorse` on an emergency fire drill (incident rollback) or pure open-ended Q&A, the agent is explicitly authorized to state: *"Fast-tracking to immediate remedy / routing to research mode."*
   215
   216	---
   217
   218	## Operating Rules
   219
   220	- Apply all 6 rungs in order. Never skip Rung 1 (ground truth) or Rung 5 (preservation) to jump to
   221	  Rung 6 (execution).
   222	- Keep communication concise and results-driven.
   223	- If a consult or verification surfaces unexpected failure, loop back to Rung 1 (falsify hypothesis & trace fail path) rather than guessing a patch.

codex
The graph service is not exposed in this consult runtime, so I’m following its required fallback: targeted source reads and literal-reference checks only. The proposed boundary is internally coherent so far; I’m now testing whether the ladder has a safety or termination hole.
exec
/bin/zsh -lc "git diff -- skills/unstuck/SKILL.md PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md skills/workhorse/SKILL.md; rg -n \"unstuck|Stalled Loop|successive passes|round cap|goal movement\" skills PROJECT test ARCHITECTURE.md GUIDING-PRINCIPLES.md | head -200; nl -ba GUIDING-PRINCIPLES.md | sed -n '1,110p'; nl -ba PROJECT/PDDA.md | sed -n '1,150p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-95764-zxehmm18
 succeeded in 3292ms:
2026-09-06 16:42:28.937 xcodebuild[1942:477257917]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 16:42:29.285 xcodebuild[1942:477257860] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-xkETbA45' (errno=Operation not permitted)
2026-09-06 16:42:30.035 xcodebuild[2103:477260007]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-09-06 16:42:30.245 xcodebuild[2103:477259918] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:20:  - GH-255 (found on the same run; that one misdirects the operator, this one wastes a full round cap silently)
PROJECT/1-INBOX/GH-255-ARCHIVE-ROOT-REMEDY.md:20:  - GH-256 (found on the same run; the two failures compound — this one misdirects, that one wastes a round cap silently)
skills/relay-xyz/SKILL.md:235:`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
skills/relay-xyz/SKILL.md:407:  | `4` | escalated by design (`STATUS: Escalated`), round cap, or a close mismatch |
skills/relay-xyz/SKILL.md:595:Open with a human sentence ("Driving a headless Codex or agy review of `<artifact>` — round cap 4…") and
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:4:title: "feat(skill): add /unstuck goal-movement interrupt"
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:23:| Failure shape captured from a session that exhausted review caps while polishing supporting machinery; `/unstuck` selected as a separate mid-flight interrupt | Implement the recovery ladder, add the narrow `/workhorse` handoff, then forward-test realistic stalled-session prompts |
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:27:Keep `/unstuck` separate from `/workhorse`.
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:29:`/workhorse` begins with an ambiguous problem and supplies a governed end-to-end method. `/unstuck`
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:35:The only workhorse change is a handoff: when successive passes produce no observable goal movement,
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:36:route to `/unstuck` instead of automatically adding another diagnostic, design, or review cycle.
PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:59:1. Add a concise, self-contained `skills/unstuck/SKILL.md` with discriminating triggers.
PROJECT/1-INBOX/RADAR-REPORT-2026-09-01.md:341:2026-08-23 fix(marathon-drive): let a productive relay extend past a stalled round cap (#115) → T6
PROJECT/3-COMPLETED/GH-77-STANDUP-SESSION-TRIAGE.md:43:> **Review closed ESCALATED at the round cap; the build started instead.** Per-round finding counts
PROJECT/1-INBOX/RADAR-REPORT-2026-08-28.md:156:| #256 (open) | `utils/py/marathon_drive.py` | no preflight checks artifact reachability; phase burns full round cap |
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:101:- #115 GH-115 · marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4) — `not-ready`
PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md:80:also escalated at the fixed round cap 5 while demonstrably converging (each round fixed the prior
PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md:2:title: "GH-115: marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)"
PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md:7:goal: let a relay that is demonstrably converging continue past the round cap, and make cap escalations distinguish stall from progress
PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md:54:- [ ] A relay that is converging (new commits or resolved review items each round) passes the round cap with a bounded, recorded extension instead of escalating.
test/relay-escalation-not-stall.sh:27:# its block, WITHOUT releasing the token (round cap) — the by-design handback to a human.
test/relay-escalation-not-stall.sh:30:printf '\n### Reviewer · Round 1\nHanded back to human (round cap reached).\n' >> "$A/relayA.md"
test/runner-loop.sh:3:# FAIL, and stop without done when the round cap is exceeded.
test/runner-loop.sh:120:  pass "runner exits non-zero when the round cap is exceeded"
test/poll-relay.sh:77:[ "$rc" -eq 4 ] && pass "round cap without Approved escalates (exit 4)" || fail "expected exit 4, got $rc"
skills/workhorse/SKILL.md:202:  - **Stalled Loop / No Goal Movement:** If successive passes only polish supporting machinery,
skills/workhorse/SKILL.md:204:    to `/unstuck`. Do not restart this ladder or add another consult cycle by default.
skills/unstuck/SKILL.md:2:name: unstuck
skills/unstuck/SKILL.md:8:  Also fires on /unstuck, "we're stuck", "rabbit hole", "stop overengineering",
skills/unstuck/SKILL.md:17:# /unstuck — Goal-Movement Interrupt
skills/unstuck/SKILL.md:19:`unstuck` is a mid-flight interrupt, not another planning framework. It stops a session that is
skills/unstuck/SKILL.md:53:An exhausted round cap is a boundary, not an invitation to raise the cap. A settled decision stays
skills/unstuck/SKILL.md:103:Before acting, retain normal authorization and safety boundaries. `/unstuck` removes self-created
skills/unstuck/SKILL.md:132:- Interrupt a live process whose activity no longer advances its goal with `/unstuck`.
skills/unstuck/agents/openai.yaml:3:  short_description: "Break stalled loops and restore goal movement"
skills/unstuck/agents/openai.yaml:4:  default_prompt: "Use /unstuck to re-anchor the goal, stop non-essential machinery, and choose one bounded next move."
test/baselines/GH-402-negative-control.md:40:relay-drive: round cap (3) exceeded (STATUS: Open, token actor: codex) — escalating
     1	# Guiding Principles
     2
     3	North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
     4
     5	## The North Star
     6
     7	There is no perfect architecture and no finished codebase. The bar is not perfection — it is that
     8	every change leaves the harness **more durable, more reversible, and less duplicated** than it found
     9	it, and that the three stay in balance:
    10
    11	- **Durable** — it removes the root cause and the next planned change builds on it, rather than being
    12	  torn out when the obvious next feature lands.
    13	- **Reversible** — the cost of being wrong is known and bounded before the change lands. A change
    14	  nobody can undo is a bet, not a fix, and gets treated as one.
    15	- **DRY** — nothing canonical lives in two places where it can drift. One source of truth, and every
    16	  other surface is a pointer or a projection of it.
    17
    18	**Do not build a new layer, module, or sub-system when an existing piece of code can be extended
    19	easily, logically, and safely.** Extending an existing abstraction beats standing up a parallel,
    20	siloed system, even when the parallel path is faster to write today — the parallel path is what
    21	later has to be kept in sync, and what silently drifts when it isn't. If the existing abstraction
    22	genuinely cannot carry the new case, say so in one line, with the reason, before forking.
    23
    24	These three pull against each other, and that tension is the decision, not a problem to average
    25	away: the most durable fix is often the least reversible, and collapsing two near-duplicates is a
    26	DRY win that can widen the blast radius. Name the trade and pick; do not split the difference by
    27	building both.
    28
    29	This section is canonical. `AGENTS.md` owns how it is applied to a given change — the reversibility
    30	scale (§3) and blast-radius sizing (§4) — and principles 6, 7, and 10 below are the build-time and
    31	done-time expressions of it. Where another doc restates this, that doc is the copy and this is the
    32	original.
    33
    34	## Purpose
    35
    36	`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
    37
    38	## The quality bar
    39
    40	Every agent turn is a signal. A turn is high-quality only when it is all four:
    41
    42	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    43	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    44	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    45	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    46
    47	Fail a pillar, and the turn, feature, or relay review isn't done.
    48
    49	## How it's built
    50
    51	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    52
    53	2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
    54
    55	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    56
    57	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
    58
    59	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    60
    61	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    62
    63	7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    64
    65	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    66
    67	9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.
    68
    69	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    70
    71	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    72
    73	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    74
    75	13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
    76
    77	## Applying this
    78
    79	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    80
    81	---
    82
    83	## Conventions
    84
    85	### Strict-mode policy (bash `set -e`)
    86
    87	Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:
    88
    89	- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
    90	  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
    91	  orphan a peer. Abort-on-error (`-e`) is the correct default there.
    92	- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
    93	  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
    94	  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
    95	  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
    96	  per-call error handling instead. This is an exemption, not an oversight.
    97
    98	Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
    99	its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
   100	unless they fit the analysis-tool profile above, in which case they add the exemption header.
   101
   102	### Tool install paths — never inside another app's folder (GH-347)
   103
   104	**This harness's tool binaries never live inside another application's private directory.** Not the
   105	worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.
   106
   107	The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
   108	reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
   109	readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
   110	PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
     1	# Project-Driven Doc Automation (PDDA)
     2
     3	PDDA is the document operating layer for this repo. Its job is to keep project plans, bug-fix docs,
     4	research notes, and roadmap pointers clean enough that an agent can pick up work with minimal drift
     5	and enough structure that routine hygiene can be automated instead of re-decided every session.
     6
     7	The core idea is simple:
     8
     9	- deterministic scripts enforce the parts that should never require judgment
    10	- an LLM reviewer flags structural or planning-quality gaps that are hard to express as regex alone
    11	- `ROADMAP.md` stays a pointer/index, while project detail lives in the individual project docs
    12
    13	## Goals
    14
    15	- Keep `PROJECT/2-WORKING` limited to docs that are truly active.
    16	- Ensure every active doc answers two questions at a glance: what was just completed, and what is next.
    17	- Make phased plans automation-ready by requiring explicit QA gates.
    18	- Prevent plan rot: stale files, missing next steps, hardcoded paths, and hidden scope drift.
    19	- Give agents one repeatable contract for project docs, bug-fix docs, and experimental plans.
    20
    21	## Non-goals
    22
    23	- PDDA does not replace the project docs themselves.
    24	- PDDA does not decide product strategy.
    25	- PDDA does not auto-rewrite nuanced plan content without review.
    26	- PDDA does not turn `ROADMAP.md` into a second execution plan.
    27
    28	## Canonical document model
    29
    30	PDDA assumes four lifecycle buckets:
    31
    32	- `PROJECT/1-INBOX`: new ideas, rough proposals, untriaged notes
    33	- `PROJECT/2-WORKING`: active docs that should be updated as work progresses
    34	- `PROJECT/3-COMPLETED`: completed docs with an outcome
    35	- `PROJECT/4-MISC`: reference, stale, superseded, or abandoned docs
    36
    37	Within that model:
    38
    39	- `ROADMAP.md` is the index of current, completed, attempted, and deferred work
    40	- project detail lives in the individual `PROJECT/**` documents
    41	- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
    42	- `blank.md` placeholders are scaffolding and should be ignored by PDDA checks
    43
    44	## Required contract for active docs
    45
    46	Every doc in `PROJECT/2-WORKING` should have:
    47
    48	1. YAML frontmatter with at least `title`, `status`, `created`, `updated`, `owner`, and `goal`
    49	2. a near-top status table with the exact columns:
    50
    51	```md
    52	## Status
    53
    54	| What was just completed | What's next |
    55	|---|---|
    56	| ... | ... |
    57	```
    58
    59	3. clear phase or work sections if the doc is a plan
    60	4. a table of contents (`## Table of contents`) listing each phase, if the plan is multi-phase — so a
    61	   cold agent can see the full phase span and jump to the live one without scrolling the whole body
    62	5. QA gates or acceptance criteria after each phase if the plan is multi-phase
    63	6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
    64	   pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
    65	7. repo-relative paths only; no hardcoded absolute local paths
    66	8. before moving to `PROJECT/3-COMPLETED`, a `## Lessons Learned (For Future Agents)` section appended to capture quirks and gotchas
    67
    68	Recommended fields when relevant:
    69
    70	- `related`
    71	- `context_tags` (e.g. `[auth, flaky-tests, build]`)
    72	- `reviewed`
    73	- `branch`
    74	- `non_goals`
    75	- `gh_issue`
    76	- `effort`, `complexity`, `risk`, `phases` — triage ratings; **required for medium-large work** (see
    77	  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))
    78
    79	## Quad Concepts (opt-in)
    80
    81	An **opt-in** glance layer, **off by default**. The `## Status` table says *where* the work is; Quad
    82	Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how, so an operator
    83	can see whether the real pain points are covered. (Distinct from `context_tags`: those are for search;
    84	this is for glance.)
    85
    86	When enabled system-wide via the `.pdda-quad` lever (or the `PDDA_QUAD` env var — **orthogonal** to the
    87	enforcement mode), tracked plan docs must carry a `## Quad Concepts` section of **1–4 bullets**,
    88	conventionally right after `## Status`:
    89
    90	```md
    91	## Quad Concepts
    92	- <pain the doc addresses> → <how it addresses it>
    93	```
    94
    95	- **Shape (deterministic):** 1–4 **top-level, non-empty** `-`/`*` bullets in the first `## Quad Concepts`
    96	  section. `pain → fix` phrasing is the convention (nudged by the LLM readiness rubric), not a hard regex.
    97	- **Scope:** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and `PROJECT/3-COMPLETED` (the last keeps a
    98	  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
    99	- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
   100	  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
   101	- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
   102	- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
   103	  a one-screen view of what the active portfolio is addressing.
   104
   105	## Triage ratings for medium-large work
   106
   107	So automation can pick *which* task to pursue without re-reading every plan, every newly recorded
   108	**medium-large** task or project carries four triage fields in its frontmatter:
   109
   110	| Field | Range | Meaning |
   111	|---|---|---|
   112	| `effort` | integer `1`–`5` | how much work — `1` low, `5` highest |
   113	| `complexity` | integer `1`–`5` | how intricate / how many moving parts — `1` low, `5` highest |
   114	| `risk` | integer `1`–`5` | blast radius + uncertainty — `1` safe/contained, `5` one-way-door or unknown |
   115	| `phases` | positive integer | total number of phases in the plan |
   116
   117	```yaml
   118	effort: 2
   119	complexity: 3
   120	risk: 1
   121	phases: 4
   122	```
   123
   124	`risk` should track the repo's existing reversibility scale (`Easy / Costly / One-way door`,
   125	`AGENTS.md` #3): `1`–`2` ≈ Easy, `3` ≈ Costly, `4`–`5` ≈ one-way door / high uncertainty. It is not a
   126	parallel notion of danger — it is that scale expressed as a number.
   127
   128	**Scope.** Required for medium-large work (project plans, experiments, features, multi-phase efforts).
   129	Genuinely small/trivial docs (a typo, a path repoint, a ≤2–3 line bug-fix — the same floor as the
   130	issue-first SOP) do not need them. "Medium-large" is a judgment, so *presence* is enforced by the LLM
   131	layer, not a regex (below).
   132
   133	### How to combine them — derive, don't store
   134
   135	There is deliberately **no stored composite "score" field.** A frozen aggregate would (a) drift from
   136	the three numbers it came from, violating Principle #4 (*one canonical place per fact*), and (b) bake a
   137	weighting choice into every doc that you then cannot re-tune without rewriting them. Compute the
   138	selection signal **live, at selection time**, from the raw fields:
   139
   140	- **`risk` is a gate, not an addend.** A trivial-but-risky task (`effort 1`, `complexity 1`, `risk 5`)
   141	  is easy to *do* but exactly what automation should not auto-pick — folding risk into a linear sum
   142	  lets it slip through mid-ranked. Gate on it instead.
   143	- **`effort` and `complexity` are correlated** (complex work is usually effortful), so summing them is
   144	  a rough "size" proxy, not two independent signals — treat the sum as one ease axis, not two.
   145
   146	Reference selection rule (tune the thresholds per repo):
   147
   148	```text
   149	eligible      = risk <= 2 AND not ratings_provisional   # safety gate; risk >= 4 => route to a human
   150	ease          = effort + complexity       # 2..10, lower = easier

exec
/bin/zsh -lc "nl -ba PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md | sed -n '1,130p'; nl -ba skills/relay-xyz/SKILL.md | sed -n '220,250p;395,420p'; if [ -f skills/unstuck/agents/openai.yaml ]; then nl -ba skills/unstuck/agents/openai.yaml; fi; rg -n \"forward-test|skill validator|validate.*skill|skills.*validator\" test utils skills | head -120" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-95764-zxehmm18
 succeeded in 0ms:
     1	---
     2	title: "GH-115: marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)"
     3	status: active
     4	created: 2026-08-22
     5	updated: 2026-08-22
     6	owner: orchestrator (Claude Code)
     7	goal: let a relay that is demonstrably converging continue past the round cap, and make cap escalations distinguish stall from progress
     8	gh_issue: 115
     9	source: https://github.com/HiQS-Labs/XYZ-forge/issues/115
    10	branch: gh-115/round-cap-escalation
    11	doc_type: bugfix
    12	effort: 1
    13	complexity: 2
    14	risk: 1
    15	related:
    16	  - "#113 — same marathon-drive seam; shared artifact utils/py/marathon_drive.py"
    17	---
    18
    19	# GH-115 — premature round-cap escalation
    20
    21	## Status
    22
    23	| What was just completed | What's next |
    24	|---|---|
    25	| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 1 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |
    26
    27
    28	Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: headless-reliability class.
    29	All four Daybreak waves ended in harness escalations, two of them this exact
    30	`cap-or-close-mismatch` shape, while the underlying relays were productive (wave 4 closed
    31	Approved on its own evidence).
    32
    33	## Bug
    34
    35	`marathon-drive.sh` defaults to `--round-cap 5` per fire. On phases where builder and
    36	reviewer iterate productively past 5 rounds, the runner escalates
    37	`cap/close-mismatch (relay-drive exit 4)` even though the lane is active and converging —
    38	halting automated execution and requiring manual restart.
    39
    40	## Plan
    41
    42	1. Progress-aware extension in `utils/py/relay_drive.py` (authoritative Python lane; the Bash
    43	   twin is FROZEN per GH-308) / `utils/py/marathon_drive.py`: at the cap, if the last round produced new commits or newly
    44	   resolved review items, grant a bounded extension (one increment, hard ceiling 2× cap) and
    45	   record it in the transcript; a round with no progress still escalates exit 4.
    46	2. Per-phase cap override: honor a `round-cap:` key in the phase brief and a CLI flag.
    47	3. Escalation record distinguishes `cap-stalled` from `cap-progressing-extended` so post-run
    48	   triage stops re-litigating productive runs.
    49	4. `test/gh115-round-cap.sh`: scripted relay hitting the cap while progressing → extended then
    50	   approved; hitting the cap stalled → exit 4 unchanged. Register in validate.sh TESTS.
    51
    52	## Acceptance
    53
    54	- [ ] A relay that is converging (new commits or resolved review items each round) passes the round cap with a bounded, recorded extension instead of escalating.
    55	- [ ] A relay that is stalled at the cap (no progress) still escalates exit 4, unchanged.
    56	- [ ] `test/gh115-round-cap.sh` green and registered in validate.sh.
    57
    58	## Swarm Preflight Contract
    59
    60	```json
    61	{
    62	  "target":        { "repo": ".", "ref": "development" },
    63	  "gate":          "bash validate.sh",
    64	  "fix_probes":    [ { "type": "path_absent", "path": "test/gh115-round-cap.sh" } ],
    65	  "artifacts":     [ "utils/py/relay_drive.py", "utils/py/marathon_drive.py", "test/gh115-round-cap.sh", "validate.sh" ],
    66	  "artifacts_new": [ "test/gh115-round-cap.sh" ],
    67	  "remediation":   { "source": "self#plan", "criteria": "cap with progress extends bounded and is recorded; cap without progress still escalates exit 4; gh115 suite green" },
    68	  "lanes":         { "agy_safe": [ "test/gh115-round-cap.sh" ], "orchestrator_only": [ "relay-automation/" ] }
    69	}
    70	```
    71
    72	## Lessons Learned (For Future Agents)
    73
    74	Three durable lessons from this lane. (1) The reviewer caught a real producer/consumer root
    75	mismatch in the new escalation-reason channel — relay_drive wrote under the harness root while
    76	marathon_drive read under the marathon root, which silently degrades to the old generic reason in
    77	the vendored layout; cross-process file channels need one explicitly shared root and an
    78	integration assertion on the consumer side, not just the producer's stdout. (2) This lane's own
    79	Test 5 initially set `MARATHON_ROOT="$ROOT"` (the real repo, not the `$A` fixture), committing a
    80	live transcript onto the working clone during every gate run — the GH-195 incident. The
    81	`marathon-root-audit.sh` guard missed it because it only recognizes `bash <driver>.sh`
    82	invocations, not direct `python3 marathon_drive.py` calls. Fixture-scope every driver env var and
    83	pass an explicit `--pre-advance-cmd` in tests. (3) Both this lane and GH-8 used phase-id `p1`,
    84	so their `marathon-system/p1/` transcripts collided at merge time; the resolution (relocating one
    85	lane's transcript to `p1-gh115/`) worked but cost a manual conflict pass — concurrent lanes need
    86	distinct phase ids up front, per the run-hygiene note in relay-xyz.
   220	`--builder claude` / a `claude-turn.sh` shim stay fully supported, but only as an explicit,
   221	cost-acknowledged choice the *user* makes locally, never something a session reaches for on its own
   222	reasoning that it's "just another supported turn-taker." If a task needs a headless build lane and
   223	neither agy nor codex is on PATH, stop and ask — don't default to spawning a headless Claude CLI turn.
   224
   225	| Path | One session? | Models | Driver |
   226	|---|---|---|---|
   227	| **A. Headless single-session** | yes — Claude drives both roles | Codex / agy as co-equal headless workers | `relay-drive.sh` + a turn-taker shim |
   228	| **B. Hands-free poll** | no — two live Claude windows | all-Claude | `poll.sh` under `/loop` in each window |
   229
   230	Path A is the marquee flow — what "have Codex or agy review this for me" means. Path B is the all-Claude
   231	self-serializing loop: no human nudge, no second model.
   232
   233	### Path A — headless single-session (relay-drive.sh + a shim)
   234
   235	`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
   236	as the terminal signal). The **turn-taker** is `--agent-cmd` — a shipped shim (`codex-turn.sh` or
   237	`agy-turn.sh`) that owns the safety boundary: path-allowlist, commit-bypass guard, **no push**.
   238	Whose-turn is a `tick` relay task, handed off with `tick release --to`.
   239
   240	End-to-end headless review of an artifact (run after Preconditions — `$TICK` and `$HARNESS` set, CWD
   241	is the harness clone). Choose either worker. The examples below pass `ALLOW_PATHS="$ARTIFACT"`, which
   242	fits a **build/fix** turn; for a pure **review** turn set `ALLOW_PATHS=""` (relay file only) so the
   243	reviewer reports instead of editing — see the env table's `ALLOW_PATHS` row (note that fixed log paths break concurrent same-machine runs; prefer the shims' per-PID default or use per-PID `$$` variables):
   244
   245	#### The one-line form (GH-346 Phase 3a) — name the reviewer, skip the table
   246
   247	If a profile exists for the model you want, the whole env block below collapses to one call:
   248
   249	```bash
   250	eval "$(relay-automation/resolve-profile.sh 'glm 5.3 max' --env)"
   395	- **Inspect whose-turn mid-drive:** `"$TICK" info <task>` prints the token's `status` / `claimer` /
   396	  `handoff-to` (this is what the driver reads internally). The verb is **`info`**, not `status` —
   397	  `tick status` is not a verb and errors with `unknown verb: status`.
   398	- **Single deliberate review turn:** pass `--review-once` to `relay-drive.sh` to drive exactly ONE
   399	  turn and classify the outcome by exit code, so a correct "changes requested" review is not mistaken
   400	  for a stall:
   401
   402	  | Exit | Meaning |
   403	  |---|---|
   404	  | `0` | reviewer Approved/Closed |
   405	  | `5` | reviewer completed a turn and handed back **without** approving ("changes requested") — a *successful* single review, not a stall |
   406	  | `3` | genuine stall — the reviewer did nothing (token + STATUS unchanged) |
   407	  | `4` | escalated by design (`STATUS: Escalated`), round cap, or a close mismatch |
   408
   409	  Without `--review-once` a non-approval handback advances the multi-round loop instead (the producer
   410	  takes the next turn); use `--review-once` when you want exactly one review and a clean exit code.
   411
   412	- **Review an external / cross-repo artifact (a PR or diff from another repo):** pass
   413	  `--artifact-file <path>` to `relay-drive.sh` to seed it READ-ONLY into the isolated worktree at
   414	  `.relay-artifacts/<basename>` — the reviewer reads it there without it being committed into the
   415	  target repo (a reviewer edit fails the turn). To scaffold the thread for such a review, use
   416	  `relay-automation/new-relay.sh --title T --reviewer <agent> --artifact-file <path>` (add `--embed`
   417	  to inline the artifact in a fence-collision-safe block instead of referencing the seed path). The
   418	  scaffolder only writes a thread; you still drive it with `relay-drive.sh` per the paths above.
   419
   420	- **Drive a full relay/build that lands in a DIFFERENT repo (`--target-root`):** the *normal* case —
     1	interface:
     2	  display_name: "Unstuck"
     3	  short_description: "Break stalled loops and restore goal movement"
     4	  default_prompt: "Use /unstuck to re-anchor the goal, stop non-essential machinery, and choose one bounded next move."
skills/skills-sync-trinity/scripts/sync_trinity.py:147:            scripts_dir / "validate_skill.py",

codex
## ANSWER

Keep `/unstuck` separate, with the narrow `/workhorse` handoff. It has a distinct entry state—recovering an already-running process—while `/workhorse` owns starting complex work from ambiguity (`skills/unstuck/SKILL.md:127`, `skills/workhorse/SKILL.md:18`). Folding them together would burden the healthy path and weaken the interrupt’s context-reset effect.

## FINDINGS

- [Blocker] A round cap is treated too categorically. “An exhausted round cap is a boundary” (`skills/unstuck/SKILL.md:53`) and the workhorse handoff’s cap trigger (`skills/workhorse/SKILL.md:202`) can interrupt a review that is still resolving evidenced correctness findings. That contradicts the repo’s established progress-aware policy: converging review receives a bounded extension, while only no-progress review escalates (`PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md:42`). Make “no qualifying movement” the trigger; cap exhaustion alone is insufficient.

- [Should] Rung 3 says to classify “every remaining item” (`skills/unstuck/SKILL.md:68`), broader than the decision document’s better wording, “every claimed blocker” (`PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:45`). The broader form risks turning the interrupt into backlog triage—the process weight it is meant to stop.

- [Should] “Original outcome” should mean the latest authoritative goal, including subsequent user changes. Otherwise re-anchoring can restore a superseded request despite the instruction to preserve explicit requirements (`skills/unstuck/SKILL.md:63`).

- [Pass] The separation is DRY: `/unstuck` owns the recovery contract, while `/workhorse` contains only a three-line pointer (`skills/workhorse/SKILL.md:201`). This matches the one-canonical-source principle (`GUIDING-PRINCIPLES.md:15`).

- [Pass] The safety boundary is strong: evidenced correctness and safety failures must be satisfied (`skills/unstuck/SKILL.md:74`), and the skill grants no additional mutation authority (`skills/unstuck/SKILL.md:103`).

- [Pass] Termination is bounded: one action, one movement check, and at most one reclassification (`skills/unstuck/SKILL.md:107`, `skills/unstuck/SKILL.md:123`).

## RECOMMENDATION

Keep `/unstuck` separate; before shipping, make the trigger progress-aware and narrow Rung 3 from “every remaining item” to “every claimed blocker.”
tokens used
57,005
## ANSWER

Keep `/unstuck` separate, with the narrow `/workhorse` handoff. It has a distinct entry state—recovering an already-running process—while `/workhorse` owns starting complex work from ambiguity (`skills/unstuck/SKILL.md:127`, `skills/workhorse/SKILL.md:18`). Folding them together would burden the healthy path and weaken the interrupt’s context-reset effect.

## FINDINGS

- [Blocker] A round cap is treated too categorically. “An exhausted round cap is a boundary” (`skills/unstuck/SKILL.md:53`) and the workhorse handoff’s cap trigger (`skills/workhorse/SKILL.md:202`) can interrupt a review that is still resolving evidenced correctness findings. That contradicts the repo’s established progress-aware policy: converging review receives a bounded extension, while only no-progress review escalates (`PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md:42`). Make “no qualifying movement” the trigger; cap exhaustion alone is insufficient.

- [Should] Rung 3 says to classify “every remaining item” (`skills/unstuck/SKILL.md:68`), broader than the decision document’s better wording, “every claimed blocker” (`PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:45`). The broader form risks turning the interrupt into backlog triage—the process weight it is meant to stop.

- [Should] “Original outcome” should mean the latest authoritative goal, including subsequent user changes. Otherwise re-anchoring can restore a superseded request despite the instruction to preserve explicit requirements (`skills/unstuck/SKILL.md:63`).

- [Pass] The separation is DRY: `/unstuck` owns the recovery contract, while `/workhorse` contains only a three-line pointer (`skills/workhorse/SKILL.md:201`). This matches the one-canonical-source principle (`GUIDING-PRINCIPLES.md:15`).

- [Pass] The safety boundary is strong: evidenced correctness and safety failures must be satisfied (`skills/unstuck/SKILL.md:74`), and the skill grants no additional mutation authority (`skills/unstuck/SKILL.md:103`).

- [Pass] Termination is bounded: one action, one movement check, and at most one reclassification (`skills/unstuck/SKILL.md:107`, `skills/unstuck/SKILL.md:123`).

## RECOMMENDATION

Keep `/unstuck` separate; before shipping, make the trigger progress-aware and narrow Rung 3 from “every remaining item” to “every claimed blocker.”
