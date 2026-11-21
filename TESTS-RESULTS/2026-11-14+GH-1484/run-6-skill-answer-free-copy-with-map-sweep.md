# run-6-skill-answer-free-copy-with-map-sweep

Agent id: `ab8eeb3be7b4cbbf6`

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory for all repository reading; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills through a Skill tool.

The ONE exception to "stay inside": first read this single instruction file in full and follow it exactly as your procedure (read nothing else in its folder):
"<local-path>"
Relative links inside it (../../4-occasional/..., ../../1-hourly/...) resolve under "skills/" inside the repository you are working in.

The operator asks:

"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"

Answer the operator by following that procedure. Your final message is the answer itself (max ~700 words), in the output shape the procedure specifies. After the answer, add a short section "Files I actually opened" listing each file path you read (not merely searched), and "Searches I ran" listing the search queries/tools you used.
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

**Bottom line:** build very little. Four of the six things an outer loop needs already exist here. What was not found in these searches is a committed timer that fires the loop, and anything that moves a prepared issue into the Jog queue without a person.

**Mode:** maps (`ROUTER.md`, `ARCHITECTURE.md` Skills Index), then grep. No `graphify-out/` or ask-self install. The codebase-memory index covers a different checkout, not this clone at `5967bde25`, so I did not use it.

**Outcome:** real work advances from backlog to landed PR and on to the next item with no person nudging.
**Constraints:** no second queue, runner or scheduler authority (flywheel `SKILL.md:16-22`); per-PR merge approval stays human (`:80-84`).

| Capability | Existing module | `file:line` | Owner of state/lock | Fit | Limiting constraint | Cost/risk to adapt |
|---|---|---|---|---|---|---|
| Wake on a clock, nobody present | hourly launchd installer | `utils/hq/install-hourly-scan.sh:28-45`; plist template `:23-26` | launchd agent, one machine | pattern only | wired to one read-only report script | low: copy the installer shape |
| Observe state, decide, cap spend, halt | `factory-primitive tick` | `utils/py/harness.py:1583-1657`, `:1815` | per-instance `state.db`, flock, `PAUSE` | adapt | tools are `note/summarize/probe/idle/plan-draft` only (`:30`), so it cannot dispatch | medium: real dispatch needs new explicit authorization (`GH-1248…md:96`) |
| Prepare an issue for pickup | `conveyor` | `skills/1-hourly/conveyor/SKILL.md:16-67` | capture doc and PRS row via `roadmap pickup` | use as is | checked: stops before queue admission; a preconfigured scheduler may invoke it (`:16`) | none |
| Pick the next item and admit it | — | `conveyor/SKILL.md:67`; `flywheel/SKILL.md:102-107` | `jog_queue` is the owner to extend | not found in these searches | "today Jog does not select or admit work from it" | this is the gap |
| Run one item under one writer | Jog | `utils/py/releases_app.py:951-964`, `:5072-5096`; `skills/2-daily/jog/SKILL.md:157-200` | `jog_queue` in `releases.db`, primary only; `relay-driver.lock` | use as is | checked: primary-only writer (`:5074`), reviewer required, orphan leases reconciled | none |
| Land without a person | — | `utils/py/jog_run.py:2497-2499` | merge-cleanup, per flywheel `:109-123` | not found in these searches | auto-merge is refused; approval is a policy boundary | do not build |
| Turn failures into new work | signal classifier, heartbeat | `utils/signal-triage.sh:1-28`; `utils/telemetry/write-xyz-heartbeat.sh:1-18` | none; classifier is stateless | adapt | headers only read; no consumer traced | unknown |

**Map sweep, reverse direction:**
- **Candidates:** `flywheel`, `conveyor`, `jog`, the hq hourly scan, and `factory-primitive` (in no map; found by grep).
- **Leads, not opened:** `10days` (selects and executes, but only when explicitly invoked), `handsfree` (session timer, not durable, per flywheel `:227-229`), `merge-cleanup`, `radar` (never executes), `task-sync` heartbeat, `self_healer.py` (header only).
- **Set aside:** relay and `tick` (inner turn loop), `work_connectors` (post-write fan-out), `start-marathon` (preparation never authorizes firing), PDDA and releases views (governance), and the remaining skills (lenses, audits, publishing).

**Composition:** a timer fires `factory-primitive tick`, which already locks, snapshots the backlog, enforces budget and pauses. Conveyor prepares issues, Jog runs them one at a time, and merge-cleanup lands approved batches.

**New remainder:**
1. **A committed timer.** The 12-hour run used a gitignored driver (`GH-1248-OUTER-LOOP-PRIMITIVE.md:34`).
2. **One admission step.** It would take prepared, rated rows into `jog add` through the primary writer.
3. **A watchdog.** There is no missed-tick record without one (same line).

**Unknowns:**
- Issue #1328 holds the outer-loop policy and was not read.
- `make_packet` (`harness.py:1445`) and `cmd_jog_add` were not opened; either may narrow item 2.
- GH-1248's non-goals exclude production schedulers and queue integration, so items 1 and 2 need your explicit go.
- A session note dated 2026-10-31 says the #1248 next phase belongs to another session. Confirm before starting.

**One next action:** run `recon` on the seam between `run_tick` and `jog add`.

## Files I actually opened
Paths are relative to `<verify-clone>/` unless absolute.

Read in full:
- `<local-path>`
- `ROUTER.md`
- `ARCHITECTURE.md`
- `skills/2-daily/flywheel/SKILL.md`
- `skills/1-hourly/conveyor/SKILL.md`
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`
- `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`
- `utils/hq/install-hourly-scan.sh`
- `utils/hq/hourly-global-scan.sh`

Read in part (line ranges):
- `utils/py/harness.py` (1583-1657, 1800-1931)
- `utils/py/releases_app.py` (951-972, 5072-5100)
- `utils/py/jog_run.py` (2465-2500)
- `skills/2-daily/jog/SKILL.md` (155-200)
- `skills/4-occasional/swe-diagram/SKILL.md` (37-66)
- `skills/1-hourly/recon/SKILL.md` (48-61)
- `PROJECT/1-INBOX/GH-1356-FLYWHEEL-BATCH2-SUPERVISOR-RUN.md` (1-90)
- `PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md` (28-40)
- `utils/hq/com.xyz-3-agents-swarm.hq-marathon-scan.plist.template` (1-40)
- `utils/hq/marathon-scan.sh` (1-40)
- `utils/signal-triage.sh` (1-30)
- `utils/py/self_healer.py` (1-40)
- `utils/telemetry/write-xyz-heartbeat.sh` (1-30)
- `utils/py/work_connectors/__init__.py` (1-30)

## Searches I ran
- `ls` of the repo root, `skills/*`, `utils/*`, `PROJECT/`, `PROJECT/2-WORKING`, `ARCHITECTURE/`, `docs/`, `.github/workflows`, `utils/py/factory_primitive`; checks for `graphify-out`, `.ask_self`, `.codebase-memory`.
- codebase-memory `list_projects` (two pages), to check index coverage only.
- `git grep -l -i -E "outer[- ]loop"` (excluding CHANGELOG, `releases.sql`, html, `relay-system`).
- `git grep -l "factory_primitive"`.
- `git grep -n "FACTORY_SUPERVISED"`.
- `git grep -n -E "factory[-_]primitive|def .*(tick|heartbeat|pause|reconcile|budget|snapshot|plan_draft|status)"` and `"^def "` on `utils/py/harness.py`.
- `git grep -n -E "^TOOLS|^FAULTS"` on `utils/py/harness.py`.
- `git grep -n -E "jog_… |CREATE TABLE IF NOT EXISTS jog|driver.lock"` on `releases_app.py` and `jog_run.py`.
- `git grep` for headings in the jog, recon and swe-diagram skills.
- `git grep -n -i -E "schedul|daemon|cron|autonom|queue"` on `PROJECT/DO-NOT-BUILD.md` and `GUIDING-PRINCIPLES.md`.
- `git grep -n -i` keyword lines in the handsfree, radar and task-sync skills and `AGENTS.md` (lines only, files not opened).
- A `schedule:|cron:` search of `.github/workflows` returned 0 matches, but it ran through the rewritten grep, so treat it as unconfirmed.
