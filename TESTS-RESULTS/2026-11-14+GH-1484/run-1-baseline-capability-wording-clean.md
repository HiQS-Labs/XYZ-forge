# run-1-baseline-capability-wording-clean

Agent id: `abca09c9a082c8269` · tool calls: 13

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills. Work the way you normally would.

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

Build almost nothing new: all three capabilities already exist in this repo, and its own rules say to extend them rather than add a parallel runner or queue. What you need is a wiring exercise plus two small gaps to close. I read the docs and skill contracts only and ran nothing.

**What already covers each requirement**

| Need | Existing piece | Where |
|---|---|---|
| Claims so two agents never collide | `tick` path-scoped claims under an `O_EXCL` lock, with per-task epoch fencing that rejects stale writers. On top of that, Jog's `jog_queue` leases and the per-clone `relay-driver.lock`. | `src/claim.js`, `src/lock.js`, `decisions/2026-06-18-epoch-fencing.md` |
| Parameter variations for edge cases | ATE: `run_variations.py` (Cartesian grid), `adaptive_ate.py` (pairwise with constraints), `fuzz_engine.py` (seeded mutation and replay), `gen4_campaign.py` (bounded campaigns). | `skills/4-occasional/ate/SKILL.md` |
| Completion receipts | Jog transitions go through the receipted RELEASES ledger; Marathon emits `marathon-drive/result@1`; Jog commits an evidence bundle with a hashed `receipt.json`. | `skills/2-daily/jog/SKILL.md` |
| Unattended sequencing | `jog run` (serial) or Marathon (multi-lane), coordinated by Flywheel. | `skills/2-daily/flywheel/SKILL.md` |

**Recommended shape**

1. Scope each night's discovery with the `defect-campaign` skill: one target, one falsifiable invariant, bounded duration.
2. Run the ATE campaign in a disposable full clone, because every variation hard-resets its target repo.
3. Triage findings into issues by hand, then queue them through Jog for fixing, with builder and reviewer as different agents.

**Gaps that are real work**

- **Stale claim lock:** a hard kill mid-claim leaves `.tick/locks/claim.lock` behind, and recovery is a manual `rm`. Overnight, that stalls the loop until morning, so stale-lock detection is the first thing to build.
- **No ATE supervisor:** ATE has no implicit check-in loop, and `checkin.py` has no memory between calls. Handsfree caps at 3 hours, so an overnight run needs a scheduler that calls `checkin.py` and enforces the wall-clock deadline.
- **Single-machine claims:** epochs are assigned under a per-clone lock, and cross-machine concurrent claims are explicitly out of scope. Keep both agents on one host, in separate clones.
- **Findings to queue is manual by design:** automatic filing, synthesis and healing are meant to stay off for discovery. Automating that bridge is your decision, not a default.

**Caveats to plan around**

- Flywheel is beta: two tasks advancing end to end without intervention is still unproven.
- Real Jog runs do not merge; published work parks for landing through merge-cleanup.
- An ATE exit code of 0 means the loop finished, not that it found nothing.

## Files I actually opened
- `ROUTER.md` (full)
- `skills/4-occasional/ate/SKILL.md` (full)
- `decisions/2026-06-18-epoch-fencing.md` (full)
- `README.md` (lines 60–189)
- `skills/2-daily/jog/SKILL.md` (lines 28–102, 149–248)
- `src/lock.js` (lines 1–30)
- `GUIDING-PRINCIPLES.md` (lines 5–16)
- `skills/4-occasional/defect-campaign/SKILL.md` (lines 1–40)
- `skills/1-hourly/handsfree/SKILL.md` (lines 1–12)

All paths are under `<verify-clone>/`.

## Searches I ran
- `ls` of the repo root, `utils/ate`, `bin`, `src`, `skills/4-occasional`, and filtered listings of `PROJECT/1-INBOX` and `PROJECT/2-WORKING`
- `rg -il 'unattended|overnight'` and `rg -il 'parameter variation|param.*sweep|edge-case|variation'` (both returned an unreliable zero through the rtk wrapper; the first was re-run with `git grep`, the second was not)
- `git grep -il -E 'unattended|overnight' -- '*.md'` (excluding CHANGELOG, relay-system, TESTS-RESULTS)
- `git grep -il -E 'claim'` across `skills/**/SKILL.md`
- `git grep -n -i 'claim' -- README.md`
- `git grep -n -i -E 'receipt|claim|unattended|overnight|one-writer|jog_queue|lease' -- skills/2-daily/jog/SKILL.md`
- `git grep` for verb names in `bin/tick` (no hits)
- `git grep -n -i -E 'north star|extend what exists|parallel system' -- GUIDING-PRINCIPLES.md PROJECT/DO-NOT-BUILD.md`
- `git grep -n -i -E 'ate|fuzz|variation|defect-campaign|overnight|unattended' -- skills/2-daily/flywheel/SKILL.md`
