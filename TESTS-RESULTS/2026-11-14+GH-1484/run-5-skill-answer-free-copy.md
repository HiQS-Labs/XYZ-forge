# run-5-skill-answer-free-copy

Agent id: `a4ea97cbacb874460`

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory for all repository reading; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills through a Skill tool.

The ONE exception to "stay inside": first read this single instruction file in full and follow it exactly as your procedure (read nothing else in its folder):
"<local-path>"
Relative links inside it (../../4-occasional/..., ../../1-hourly/...) resolve under "skills/" inside the repository you are working in.

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

**Bottom line:** most of the outer loop already exists and has run on a schedule. What is missing is small: nothing moves prepared issues into the Jog queue without you, and the scheduled wake and its watcher exist only as test evidence, not as an installable tool. No consumer of the `status:ready-for-pickup` label was found in these searches (`git grep` over `utils`, `relay-automation`, `bin`, `src`).

**Mode:** maps first (`ROUTER.md`, `ARCHITECTURE.md` Skills Index, `skills/README.md`), then `git grep`, at HEAD `5967bde25`. No index was used: this clone has no `graphify-out/` or ask-self install, and codebase-memory lists other checkouts only (first 50 of 86 projects seen).

**Outcome:** after one item lands, the next eligible item starts without you carrying it.

**Capabilities searched:** wake without a chat session; pick the next item and run one bounded task; publish state between wakes and recover; move prepared work into the queue; prepare issues for pickup; land approved work and advance; notice a silent or stuck run.

| Capability | Existing module | `file:line` | Owner of state or lock | Fit | Limiting constraint | Cost or risk to adapt |
|---|---|---|---|---|---|---|
| Pick next, run one task | `jog run --max-tasks 1` | `utils/py/jog_run.py:2465`, `2621-2643` | `jog_queue` in `releases.db`; `JogSupervisorLock` `:1500` | use as is | Checked: a second driver exits 4 (`:1530-1536`), so one primary only | None |
| Publish between wakes, recover | `JogCheckpoint` | `utils/py/jog_run.py:2103-2213` | Journal `.tick/jog/checkpoint.json` | use as is | Checked: refuses foreign changes and unpublished commits (`:2146-2150`, `:2207`); needs a separate publication clone (`:2127-2130`) | None |
| Wake without a chat | launchd installer | `utils/hq/install-hourly-scan.sh:28-45` | launchd | adapt | Installs only the read-only marathon scan; the Jog wake plist is evidence with hardcoded temp paths (`TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/continuation/continuation.plist:22-50`) | Low |
| Prepare issues for pickup | `conveyor` | `skills/1-hourly/conveyor/SKILL.md:8-16` | PRS row via `roadmap pickup` | use as is | Checked: stops before queue admission (`:10`) | None |
| Move prepared work into the queue | `jog add` | `utils/py/releases_app.py:4725-4792` | `jog_queue`, primary-only (`:4728`) | adapt | Human-invoked; "today Jog does not select or admit work from it" (`conveyor/SKILL.md:67`) | Medium: this is an authority decision |
| Land approved, advance | `jog land` | `utils/py/jog_run.py:1347-1386` | merge-cleanup batch plus your per-PR approval | use as is | Checked: `--auto-merge` is refused (`:196-199`, `:2497-2499`) | None |
| Notice a silent run | inline observer | `.../continuation/observer.plist:11-40` | None; observe-only | pattern only | Not found in `utils/` in these searches; local, awake-host only | Low |
| Decide over the backlog | `factory-primitive` | `utils/py/harness.py:1804-1921`, `863-900` | `temp/factory-primitive/` | pattern only | No scheduler or queue integration (`PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md:60`) | High to promote |

**Composition:** launchd fires `jog run --max-tasks 1 --target-root … --checkpoint-root …`. Jog owns selection, the lock and the queue; `JogCheckpoint` publishes each wake; conveyor feeds prepared packets; merge-cleanup lands what you approve. The `flywheel` skill already describes this join (`skills/2-daily/flywheel/SKILL.md:186-243`). It ran this way on 2026-11-08 and produced PRs #1371–1373 (`continuation/FINAL-RESULTS.md:23-31`).

**New remainder:**
- **Admission step:** one command that takes conveyor-ready issues and calls the existing `jog add` writer. The GH-1358 record names this as unmet: "Admission remains assisted/no-row discovery unmet" (`PROJECT/1-INBOX/GH-1358-DURABLE-FACTORY-QUALIFICATION.md:196`, `:211`).
- **Checked-in installer:** the Jog wake and observer as an installable unit, extending `install-hourly-scan.sh`.

**Unknowns:**
- **Unread candidates:** I did not open merge-cleanup, 10days, radar, handsfree, `marathon-scan.sh`, `cmd_roadmap_pickup`, or the GH-1360, GH-1356 and GH-1254 docs.
- **Live issue state:** I did not check #522, #1022, #1168, #1175 or #1200 on GitHub; the repo docs assign admission to those owners.
- **Authority:** the rehearsal summary says it "does not authorize building a supervisor" (`.../SUMMARY.md:19`), so the admission step needs your decision.

**One next action:** run `recon` on Jog admission (`cmd_jog_add` through pickup in `jog_run_main`) before designing the admission step.

## Files I actually opened
All under the verify clone unless noted.
- `<local-path>`
- `ROUTER.md`, `skills/README.md`, `ARCHITECTURE.md` (26-160, 428-576), `AGENTS.md` (40-69)
- `skills/4-occasional/swe-diagram/SKILL.md`, `skills/1-hourly/recon/SKILL.md`, `skills/2-daily/flywheel/SKILL.md`, `skills/1-hourly/conveyor/SKILL.md`
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`, `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`
- `PROJECT/1-INBOX/GH-1298-FLYWHEEL-ARC.md`, `PROJECT/1-INBOX/GH-1358-DURABLE-FACTORY-QUALIFICATION.md`
- `utils/py/jog_run.py` (194-201, 1347-1386, 1500-1567, 2103-2222, 2423-2752)
- `utils/py/releases_app.py` (4717-4798), `utils/py/harness.py` (863-902, 1800-1929)
- `utils/hq/hourly-global-scan.sh`, `utils/hq/install-hourly-scan.sh`
- `TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/SUMMARY.md`, and in its `continuation/` folder: `FINAL-RESULTS.md`, `continuation.plist`, `observer.plist` (1-40)

## Searches I ran
- `ls` of the repo root, `skills/*`, `utils/py`, `PROJECT/1-INBOX`, `PROJECT/2-WORKING`, `TESTS-RESULTS`
- codebase-memory `list_projects` (twice; first page only)
- `rg` for headings in `ARCHITECTURE.md`
- `rg -i 'outer[- ]loop'` over `*.md`
- `rg -i 'launchd|launchctl|crontab|\.plist|StartInterval'` (file list)
- `git grep` for function and class names in `jog_run.py`, `releases_app.py`, `harness.py`
- `git grep "ready-for-pickup"` in `utils`, `relay-automation`, `bin`, `src`
- `git grep SCHEDULE_SILENCE`
- `git grep 'StartInterval|launchctl (load|bootstrap)'` in `utils`, `relay-automation`, `skills`, `bin`
- `git grep 1477` (returned only unrelated telemetry hits)
