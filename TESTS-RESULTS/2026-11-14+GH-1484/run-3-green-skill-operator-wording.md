# run-3-green-skill-operator-wording

Agent id: `a03565a5309341133` · tool calls: 39

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory for all repository reading; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills through a Skill tool.

The ONE exception to "stay inside": first read this single instruction file in full and follow it exactly as your procedure (read nothing else in its folder or its repository):
"<task-clone>/skills/3-weekly/connect-the-dots/SKILL.md"
Links inside it resolve to the same relative paths inside the repository you are working in.

The operator asks:

"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"

Answer the operator by following that procedure. Your final message is the answer itself (max ~600 words), in the output shape the procedure specifies. After the answer, add a short section "Files I actually opened" listing each file path you read (not merely searched), and "Searches I ran" listing the search queries/tools you used.
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

**Bottom line:** almost every part of the outer loop already exists in this repo. The gap is the durable wake and the decision about what it fires, so the build is small.

**Mode:** maps (`ROUTER.md`, `ARCHITECTURE.md` Skills Index, `README.md`), then grep. No graphify output exists in this clone, and the codebase-memory index covers a different checkout, so I did not use it. Checked at `5967bde25`.

**Outcome:** eligible work advances from backlog to a reviewed PR with nobody prompting each step.
**Constraints:** no second queue, runner or scheduler (`flywheel/SKILL.md:16-22`, GH-1248 non-goals); merges stay per-PR approved.

| Capability | Existing module | `file:line` | State owner | Fit | Limiting constraint | Cost to adapt |
|---|---|---|---|---|---|---|
| Wake unattended on a timer | HQ launchd installer | `utils/hq/install-hourly-scan.sh:28-45`; `hourly-global-scan.sh:26-38` | launchd plist; #1168 is the named scheduler owner | pattern only | Runs one read-only scan; #1168 has no doc in this repo | Low: one more job, same template |
| Claim work so no second agent takes it | Jog lease, plus `tick` claim/take | `utils/py/releases_app.py:5072-5096`; `src/claim.js:28-93`; `src/take.js:23-68` | `jog_queue` in `releases.db`; `.tick/events` | use as is (Jog) | Checked scope: Jog is primary-only and serial, which fits one loop. `tick` is per-clone and a hard kill leaves a stale lock (`src/lock.js:17-18`) | None for a serial loop |
| Survive a restart without redoing work | Jog orphan-lease reconcile; factory primitive tick | `releases_app.py:5138-5193`; `utils/py/harness.py:1596-1602,1688-1691` | same owners | use as is (Jog) | Checked side effects: a dead-PID row returns to pending and parks after 3 attempts | None |
| Decide the next action each wake | Factory primitive (GH-1248) | `harness.py:1583-1757`, tools at `:30` | per-instance `state.db` under `temp/` | adapt | Tools are note/summarize/probe/idle/plan-draft only; the plan forbids Jog execution | High: needs new authorization |
| Record a receipt per completion | `perform_write` callers; primitive receipts table | `releases_app.py:5096,5132`; `harness.py:64-66` | `releases.db` | use as is | Checked ownership: Jog already writes through it | None |
| Keep polling between wakes | `relay-loop` adaptive cadence | `utils/py/relay_loop.py:15-21` | `poll.sh` decision | pattern only | Relay-scoped | — |
| Run variations unattended | ATE runner | `utils/ate/scripts/run_variations.py:5-27`; `ate/SKILL.md:48,63-69` | `error_log.jsonl` | pattern only | Hard-resets its target repo; has no check-in loop of its own | — |

**Composition.** A launchd job modelled on the HQ installer fires the existing Jog run/resume verb on the primary clone. Jog keeps the queue, lease, restart recovery and receipts. The flywheel skill stays the in-session driver for review and landing. `handsfree` is session-bound, not durable (`handsfree/SKILL.md:13-16`).

**New remainder.**
- One scheduled job entry under #1168, with a missed-run and overlap policy.
- A choice of what the wake may fire: Jog directly, or the GH-1248 executive given a dispatch tool. The second needs explicit authorization (`GH-1248-OUTER-LOOP-PRIMITIVE.md:96`).
- A source of admissible work. `GH-1298-FLYWHEEL-ARC.md:34-36` says the earlier runs agree that supply and landing are the gaps, not the loop.

**Unknowns.**
- #1168's live state and contract; reading the issue would settle it.
- Whether a repeated unattended Jog run is a clean no-op on an empty queue; I read only the dry-run branch (`jog_run.py:2542-2569`).
- `perform_write`, `tick reap`, the plist template and the GH-1254/GH-1358 plans were not opened.
- Outcome feedback (radar, defect-campaign) was not found in these searches as code, only as skill index rows I did not open.

**One next action:** `recon` on Jog's run/resume path, to confirm it is safe as the callee of a scheduled wake.

## Files I actually opened
All under `<verify-clone>/` except the first:
- `<task-clone>/skills/3-weekly/connect-the-dots/SKILL.md`
- `ROUTER.md`, `ARCHITECTURE.md`, `README.md` (80-154)
- `skills/2-daily/flywheel/SKILL.md`, `skills/4-occasional/ate/SKILL.md`, `skills/1-hourly/handsfree/SKILL.md` (1-45)
- `src/claim.js`, `src/lock.js`, `src/next.js`, `src/take.js`
- `utils/ate/scripts/run_variations.py` (1-140)
- `utils/py/harness.py` (1-80, 1583-1797), `utils/py/releases_app.py` (5072-5201), `utils/py/jog_run.py` (1-40, 2536-2575), `utils/py/relay_loop.py` (1-80)
- `relay-automation/watchdog.sh` (1-70)
- `utils/hq/hourly-global-scan.sh`, `utils/hq/install-hourly-scan.sh`
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`, `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`
- `PROJECT/1-INBOX/GH-1360-GENERIC-MONITOR-SUPERVISOR.md`, `PROJECT/1-INBOX/GH-1298-FLYWHEEL-ARC.md`

## Searches I ran
- `ls` / `wc -l` / `find` over the repo root, `skills/`, `bin/`, `src/`, `utils/`, `utils/ate`, `utils/hq`, `utils/py/factory_primitive`, `utils/py/work_connectors`, `PROJECT/*`
- `mcp__codebase-memory-mcp__list_projects` (index check only)
- `rg -i "tick|claim|lease|reap|ttl|heartbeat|cron|launchd|schedul" README.md`
- `rg -i "stale|reap|ttl|lease|expire|heartbeat|ping" src/claim.js src/lock.js src/next.js src/take.js bin/tick`
- `git grep -l -i -E "launchd|launchctl|crontab|LaunchAgents|systemd"`
- `git grep -l -i -E "watchdog|supervis|daemon"` over `utils/py/*.py`, `relay-automation/*.sh`, `utils/*.sh`
- `git grep` for resume/recover/select function definitions in `jog_run.py`, `marathon_drive.py`, `releases_app.py`, `relay_loop.py`, `poll.py`
- `git grep -E "^def [a-z_]*receipt"` over `utils/py/*.py`
- `git grep -l -i -E "outer[- ]loop"` (run after the capability searches)
- `git grep -E "^def |add_parser"` in `utils/py/harness.py`
- `git grep -E "#1168|GH-1168"`
- `git grep -i -E "driver[-_ ]lock|flock|def cmd_|jog_queue"` in `jog_run.py`, and jog verbs in `releases_app.py`
- One `rg --glob` search failed with a usage error and was re-run as `git grep`.
