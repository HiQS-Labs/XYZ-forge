# run-0-baseline-capability-wording-contaminated

Agent id: `ad73497cf09c4cf17` · tool calls: 14

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<task-clone>". Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills. Work the way you normally would.

The operator asks:

"We want an unattended overnight loop that claims tasks so two agents never collide, runs parameter variations to find edge-case failures, and records completion receipts. What should we build?"

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

Do not build a new loop. Almost all of this already exists in the repo; the new work is a thin composition plus two known gaps.

**What already covers each need**

| Need | Existing owner | Material limit |
|---|---|---|
| Claim so two agents never collide | `tick` kernel: `src/claim.js:28-93` (path-overlap rejection, per-agent cap, monotonic epoch fencing), `tick take` atomic next+claim (`bin/tick:156`) | Per-clone, local only. No stale-lock detection: a hard kill leaves `.tick/locks/claim.lock` to remove by hand (`src/lock.js:17-18`). `reap` is manual and coordinator-only (`src/scope.js:167`). |
| Parameter variations for edge cases | ATE: `utils/ate/scripts/run_variations.py` (Cartesian grid), `utils/py/adaptive_ate.py` (pairwise), `utils/py/fuzz_engine.py`, per `skills/4-occasional/ate/SKILL.md:19-27` | No implicit check-in loop; it needs an external supervisor (`SKILL.md:48,69`). Every variation hard-resets the target repo, so it needs a disposable clone. Multi-hour campaigns need separate approval (`SKILL.md:101`). |
| Completion receipts | Jog: every transition goes through `perform_write` with receipt chain; dead-`lease_pid` rows reconcile at startup (`skills/2-daily/jog/SKILL.md:172-176`). `tick done` also logs completion events. | Jog is a serial queue of GH issues with one writer, not a parallel claim pool. |
| Unattended outer loop | GH-1248 factory primitive: `python3 utils/py/harness.py factory-primitive tick` with heartbeat, lock, PAUSE, budget and a `receipts` table (`utils/py/harness.py:64`), which completed a 12-hour, 144-slot run | Synthetic and read-only by contract; real dispatch needs new explicit authorization (`GH-1248` doc, Phase 5). Watchdog and missed-tick record are still deferred. |

**What to build (the remainder)**

1. **One driver, not a subsystem.** Have the outer loop do `tick take` → run one bounded ATE grid in a disposable full clone → `tick done` or `tick break`, writing the receipt through the existing receipts path. The scheduler is the existing five-minute tick driver.
2. **Stale-claim recovery.** `tick ping` exists but nothing acts on it. An overnight run needs heartbeat-age reaping and stale-lock detection (already labelled "Phase 2" in `src/lock.js`).
3. **ATE supervision.** Wire `checkin.py` into the loop's tick so abort and time-budget checks actually run.

**Decisions for you before anything is built**

- GH-1248's non-goals forbid "a competing queue" and production schedulers, so this needs your explicit authorization as a Phase 5 follow-up.
- Your memory notes say the #1248 next phase is owned by another session, so check with it first.
- `GUIDING-PRINCIPLES.md` (per ROUTER) requires extending what exists over a parallel system.

I did not run anything. This is from reading source and docs, not from exercising the tools.

## Files I actually opened
- `ROUTER.md`
- `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`
- `skills/4-occasional/ate/SKILL.md`
- `README.md` (lines 80-111)
- `src/claim.js`
- `src/lock.js`
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`
- `bin/tick` (lines 140-189)
- `skills/2-daily/jog/SKILL.md` (lines 166-199)

All paths are relative to `<task-clone>/`.

## Searches I ran
- `ls` of the repo root, `skills/*`, `.tick`, `utils`, `utils/py`, `utils/ate`, `utils/py/factory_primitive`, `bin`, `src`, `PROJECT/2-WORKING`
- `rg -i 'jog|marathon|claim|receipt|simulator|battery|sweep|variation|overnight|unattended' ROUTER.md`
- `rg -i 'claim|release|lease|expire|heartbeat' README.md`
- `rg -i 'receipt|jog_queue|claim|lease|one-writer|unattended|overnight' skills/2-daily/jog/SKILL.md`
- `rg -i 'stale|ttl|expire|heartbeat' src/claim.js src/lock.js src/take.js bin/tick`
- `rg 'def |add_argument|add_parser' utils/py/ate_runaway_sweep.py`
- `rg -i 'receipts|CREATE TABLE|uncertain|heartbeat\.json|PAUSE' utils/py/harness.py`
- `rg -i 'reap|stale|ttl' src/scope.js`
- `rg -i 'loop|queue|scheduler|orchestr|parallel' PROJECT/DO-NOT-BUILD.md`
- `rg -i 'outer loop|overnight|unattended|tick|ATE|handsfree' skills/2-daily/flywheel/SKILL.md`
- `wc -l` on candidate docs
