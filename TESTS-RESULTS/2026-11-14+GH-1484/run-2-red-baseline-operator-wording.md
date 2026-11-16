# run-2-red-baseline-operator-wording

Agent id: `a09b4ec6c52f14d3a` · tool calls: 25

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills. Work the way you normally would.

The operator asks:

"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"

Answer the operator. Your final message is the answer itself (max ~400 words). After the answer, add a short section "Files I actually opened" listing each file path you read (not merely searched), and "Searches I ran" listing the search queries/tools you used.
<context_window_protection>
  <priority_instructions>
    Raw tool output floods context window. MUST use context-mode MCP tools. Keep raw data in sandbox.
  </priority_instructions>

  <tool_selection_hierarchy>
    0. MEMORY: mcp__plugin_context-mode_context-mode__ctx_search(sort: "timeline")
       - After resume, check prior context before asking user.
    1. GATHER: mcp__plugin_context-mode_context-mode__ctx_batch_execute(commands, queries)
       - Primary research tool. Runs commands, auto-indexes, searches. ONE call replaces many steps.
       - Each command: {label: "section header", command: "shell command"}
       - label becomes FTS5 chunk title — descriptive labels improve search.
    2. FOLLOW-UP: mcp__plugin_context-mode_context-mode__ctx_search(queries: ["q1", "q2", ...])
       - All follow-up questions. ONE call, many queries (default relevance mode).
    3. PROCESSING: mcp__plugin_context-mode_context-mode__ctx_execute(language, code) | mcp__plugin_context-mode_context-mode__ctx_execute_file(path, language, code)
       - API calls, log analysis, data processing.
  </tool_selection_hierarchy>

  <forbidden_actions>
    - NO Bash for commands producing >20 lines output.
    - NO Read for analysis — use mcp__plugin_context-mode_context-mode__ctx_execute_file. Read IS correct for files you intend to Edit.
    - NO WebFetch — use mcp__plugin_context-mode_context-mode__ctx_fetch_and_index.
    - Bash ONLY for git/mkdir/rm/mv/navigation.
    - NO mcp__plugin_context-mode_context-mode__ctx_execute or mcp__plugin_context-mode_context-mode__ctx_execute_file for file creation/modification.
      mcp__plugin_context-mode_context-mode__ctx_execute is for analysis, processing, computation only.
  </forbidden_actions>

  <file_writing_policy>
    ALWAYS use native Write/Edit tools for file creation/modification.
    NEVER use mcp__plugin_context-mode_context-mode__ctx_execute, mcp__plugin_context-mode_context-mode__ctx_execute_file, or Bash to write files.
    Applies to all file types: code, configs, plans, specs, YAML, JSON, markdown.
  </file_writing_policy>

  <output_constraints>
    <artifact_policy>
      Write artifacts (code, configs, PRDs) to FILES. NEVER inline.
      Return only: file path + 1-line description.
    </artifact_policy>
  </output_constraints>
  <session_continuity>
    Skills, roles, and decisions set during this session remain active until the user revokes them.
    Do not drop behavioral directives as context grows.
  </session_continuity>

</context_window_protection>

## Final answer (verbatim, local paths replaced)

**Bottom line:** don't build another loop. The loop already exists (Jog + Marathon + scheduled `jog run --max-tasks 1 --checkpoint-root`), and every real trial so far stalled at the same few seams. Build those seams, in this order.

1. **Make one failed task stop only itself.** `utils/py/jog_run.py:2720-2726` and `:2767-2771` break the whole queue on any task failure. In the 2026-11-11 GH-1386 trial, the Agy reviewer hit a 429 credit error on #1171, so #1315 was never dispatched: 0 deliveries, "automatic progression: not demonstrated". Jog already continues past a task parked awaiting approval (`:2703-2719`); extend that to failures that are independent of the next item.

2. **Check reviewer capacity before spending a builder turn.** GH-1443 made dry-run catch 13 false-ready cases, but it explicitly leaves live credits and auth unverified. One real, cheap provider request at admission would have caught the 11-11 stop. I did not find a reviewer fallback in `jog_run.py`, though I only searched that file.

3. **Build the landing packet.** This means one approval request per parked PR, bound to the exact head, with diff scope, attestation and CI. Phase 0 measured about 23.5 hours of approval wait against 28 minutes of unattended drive. The flywheel skill describes batch landing through merge-cleanup, but GH-1400 records "no observed effect on real-world throughput" because it is instructions only.

4. **Then rerun the unmet qualification rather than a soak.** GH-1358 still lacks no-row admission and two successive PR-ready wakes. GH-1356 scored "three genuine no-row pickups" as NOT MET. Feed that run with conveyor-prepared issues (GH-1401), since Phase 0 found 0 of 281 open issues admissible.

**What not to build:**
- **A new supervisor, reconciler or queue.** The launchd wake was already rehearsed in GH-1358 and published checkpoints without manual Git rescue.
- **More work on the #1248 primitive.** Its tools are `note`, `summarize`, `probe`, `idle` and `plan-draft`; it never admits, runs or lands Jog work.
- **Longer runs.** The trials failed in minutes on preparation and provider limits, not on endurance.

**Caveats:**
- This checkout is at `5967bde25` and contains nothing on GH-1477 or GH-1484, so the simulator plan is not reflected here.
- I read the code and committed evidence only and ran nothing.
- Whether halting the queue on failure was deliberate is not something I confirmed; treat step 1 as a design decision for you to make.

## Files I actually opened
All under `<verify-clone>/`:
- `skills/2-daily/flywheel/SKILL.md`
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`
- `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`
- `PROJECT/1-INBOX/GH-1298-FLYWHEEL-ARC.md`
- `PROJECT/1-INBOX/GH-1353-NEXTGEN-FLYWHEEL.md`
- `PROJECT/1-INBOX/GH-1356-FLYWHEEL-BATCH2-SUPERVISOR-RUN.md`
- `PROJECT/1-INBOX/GH-1358-DURABLE-FACTORY-QUALIFICATION.md`
- `PROJECT/1-INBOX/GH-1360-GENERIC-MONITOR-SUPERVISOR.md`
- `PROJECT/3-COMPLETED/GH-1401-CONVEYOR.md`
- `PROJECT/3-COMPLETED/GH-1443-JOG-READINESS.md`
- `PROJECT/3-COMPLETED/GH-1453-JOG-LOCAL-RECONCILE.md` (first 30 lines)
- `relay-system/2026-10-31/flywheel-arc-review.md`
- `TESTS-RESULTS/2026-11-11+GH-1386/SUMMARY.md`
- `TESTS-RESULTS/2026-11-10+GH-1386/interventions.md`
- `TESTS-RESULTS/2026-11-08+GH-1356-closeout/SUMMARY.md`
- `utils/py/jog_run.py` (lines 2690-2774)

## Searches I ran
- `rg -il "outer loop|outer-loop|flywheel"` (returned 0 matches in 0 files; treated as unreliable and rerun with `git grep`)
- `git grep -il` / `-ic` for `outer loop`, `outer-loop`, `flywheel`
- `git grep -il` for `1484`, `connect-the-dots`
- `git grep -n -i flywheel` in `README.md`, `AGENTS.md`, `ROUTER.md`, `ARCHITECTURE.md`, `GUIDING-PRINCIPLES.md`
- `git grep -n -i` for `GH-1386`, `GH-1399`, `GH-1328` under `PROJECT/`
- `git grep -l` for `checkpoint-root`, `launchd|LaunchAgents`, `factory reconcile` under `utils bin skills tools src`
- `git grep -n -i -E "max[-_]tasks|continue[-_]on|stop.*queue|halt.*queue|RESOURCE_EXHAUSTED|fallback.reviewer|reviewer.fallback"` in `utils/py/jog_run.py`
- `git grep` for `automatic (progression|transition|continuation)|next eligible` in `skills/2-daily/jog/SKILL.md` (no hits)
- `git log --oneline -8`, `git status --short`, `ls` and `wc -l` over `PROJECT/`, `TESTS-RESULTS/`, `skills/`, `utils/py`
