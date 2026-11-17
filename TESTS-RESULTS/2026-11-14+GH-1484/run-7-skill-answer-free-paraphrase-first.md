# run-7-skill-answer-free-paraphrase-first

Agent id: `a6ccedfb8719daf26`

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory for all repository reading; do not read any other checkout of this repository or any memory/notes files outside it. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills through a Skill tool. Do not start subagents.

The ONE exception to "stay inside": first read this single instruction file in full and follow it exactly as your procedure (read nothing else in its folder):
"<local-path>"
Relative links inside it (../../4-occasional/..., ../../1-hourly/...) resolve under "skills/" inside the repository you are working in.

The operator asks:

"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"

Answer the operator by following that procedure. Your final message is the answer itself (max ~900 words), in the output shape the procedure specifies. After the answer, add a short section "Files I actually opened" listing each file path you read (not merely searched), and "Searches I ran" listing the search queries/tools you used.

## Answer returned (verbatim, local paths replaced)

**Bottom line:** most of the outer loop already exists and has already run on a timer here. What is not built is the join between three existing owners; a new runner, queue or scheduler was not found to be needed in these searches (listed at the end).

## Step 1 — Said back

- **What this asks for:** what to build so the flywheel's outer loop runs. "Outer loop" is not defined in your sentence; I read it (inference) as the cycle that picks the next piece of work, drives it, lands it and repeats without you prompting each turn.
- **How it is handled today, per the operator:** not running; you are struggling to start it. Details `not stated`.
- **What it's not:** `not stated`.

**Outcome:** eligible work advances from backlog to landed, repeatedly, with no session held open.
**Constraints:** none stated. The repo itself rules out a second runner or queue (`skills/2-daily/flywheel/SKILL.md:16-22`).
**Capabilities:** wake on a timer; take one queued item per wake and persist the result; fill the queue from prepared work; build and independently review; land approved work; restart or observe a dead run; feed results back as new work.

**Mode:** maps (`ROUTER.md`, `ARCHITECTURE.md` Skills Index), then grep. No graphify output or ask-self install in this clone, and the codebase-memory index covers other checkouts only, so it was not used.

## Step 2 — Map sweep

- **Candidates:** flywheel, jog, conveyor, merge-cleanup, HQ hourly scan, the `factory-primitive` in `harness.py`.
- **Candidates from excerpts only, kept out of the table:** radar, handsfree.
- **Set aside, with a line read:** relay and tick (turn ownership inside one review, `ARCHITECTURE.md:31-38`); handsfree as the timer (session-scoped, `skills/1-hourly/handsfree/SKILL.md:52-54`).
- **Set aside, inferred from the index line only:** 10days, start-marathon, defect-campaign, whack-a-mole, weekly-planner, telemetry, PDDA.

## Step 3 — Fit table

| Capability | Existing module | `file:line` | Owner of state or lock | Fit | Limiting constraint | Cost or risk to adapt |
|---|---|---|---|---|---|---|
| Wake on a timer | HQ hourly scan launchd installer and lock | `utils/hq/install-hourly-scan.sh:28-45`; `utils/hq/hourly-global-scan.sh:26-38` | #1168 shared scheduler, still `needs-doc` (`MARATHON-PLAN-2026-11-15.md:250`) | pattern only | Wired to the marathon scan only; a sleeping Mac misses wakes | Low to write; scheduling ownership is the Costly part |
| One item per wake, result published | `jog run --max-tasks 1 --checkpoint-root` | `utils/py/jog_run.py:2424-2432, 2622-2635` | `jog_queue` in `releases.db`; primary is the only writer (`releases_app.py:4717-4722`) | use as is | Checked: one machine, one primary, separate publication clone. Rehearsed under launchd; full qualification unmet (GH-1358 doc) | None new |
| Fill the queue from prepared work | conveyor, then `jog add <issue>` | `skills/1-hourly/conveyor/SKILL.md:67`; `releases_app.py:4725-4735` | conveyor owns preparation; Jog owns admission | adapt | "Today Jog does not select or admit work from" the ready label; `jog add` takes one explicit issue | Small selector; must revalidate at pickup (`flywheel/SKILL.md:102-107`) |
| Build and independent review | Jog's marathon executor | `utils/py/jog_run.py:202-211` | Marathon lane attempts | use as is | Checked: reviewer must be named and differ from builder | None |
| Land approved work | merge-cleanup pinned batch; `jog land` | `merge_cleanup.py:529-556`; `jog_run.py:196-206, 1347-1353` | merge-cleanup | use as is | Per-PR merge approval is yours (`flywheel/SKILL.md:80-84`); Jog refuses `--auto-merge` | A policy decision, not code |
| Restart or observe a dead run | `FACTORY_SUPERVISED` flag | `utils/py/harness.py:133-139` | none | pattern only | It records "no self-restart mechanism"; the GH-1358 observer was a local, untracked deployment | Unknown until #1168 is read |
| Feed results back as new work | Daily, radar | `flywheel/SKILL.md:156-162` | Daily owns its own logs | not found in these searches | "Not an automatic observer adapter" | Defer |

## Step 4 — Connect the dots

**Composition:** the #1168 scheduler wakes `jog run --max-tasks 1 --checkpoint-root`. Jog keeps the queue, lock, build and review. merge-cleanup lands the batch you approve. Flywheel stays the instruction layer over all three.

**New remainder (the only part to design):**
1. A tracked wake job for Jog under #1168. The only tracked launchd installer found drives the HQ scan; the Jog wake in GH-1358 was deployed by hand and then removed.
2. A selector that turns conveyor's ready-for-pickup issues into `jog add` after revalidation. The GH-1356 closeout records "three genuine no-row pickups: NOT MET" and that parent-assisted steps "do not prove automatic next selection" (`SUMMARY.md:8, 22`).
3. A decision on the landing boundary. The loop stops at your per-PR approval by policy; batch approval already exists (`flywheel/SKILL.md:109-122`).

**Unknowns:**
- "Outer loop" and "what it's not" are `not stated`; a one-line definition from you settles both.
- Issues #1168, #1328, #1386 and #1399 were not read (no GitHub access used); only their mentions in repo docs.
- Radar, 10days, Daily and the telemetry scripts were not opened, so the feedback row is bounded.
- Loop metrics: GH-1353 calls the loop "uninstrumented"; not searched in source.
- Your notes say the next flywheel phase belongs to another session; I could not check its current state from this clone.

**One next action:** run `recon` on the wake-to-queue seam, i.e. `jog_run_main` and `cmd_jog_add` plus issue #1168, before anything is written.

## Files I actually opened

Paths are relative to `<verify-clone>/` unless absolute.

- `<scratchpad>/ctd-deseeded-v3/SKILL.md` (full)
- `ROUTER.md`, `ARCHITECTURE.md`, `skills/2-daily/flywheel/SKILL.md`, `skills/1-hourly/conveyor/SKILL.md` (full)
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`, `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, `PROJECT/2-WORKING/recon-gh1400-supervision-composition.md` (full)
- `PROJECT/1-INBOX/GH-1298-FLYWHEEL-ARC.md`, `GH-1353-NEXTGEN-FLYWHEEL.md`, `GH-1356-FLYWHEEL-BATCH2-SUPERVISOR-RUN.md`, `GH-1360-GENERIC-MONITOR-SUPERVISOR.md` (full); `GH-1358-DURABLE-FACTORY-QUALIFICATION.md` (lines 1-140)
- `TESTS-RESULTS/2026-11-08+GH-1356-closeout/SUMMARY.md`, `utils/hq/hourly-global-scan.sh`, `utils/hq/install-hourly-scan.sh` (full)
- Excerpts: `utils/py/jog_run.py` (1-60, 190-235, 1347-1375, 2420-2440, 2543-2560), `utils/py/releases_app.py` (4717-4760, 5198-5240), `utils/py/harness.py` (120-150), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (529-556), `utils/py/wave_reconcile.py` (1-25), `utils/hq/marathon-scan.sh` (1-30), `skills/1-hourly/handsfree/SKILL.md` (36-60), `skills/4-occasional/swe-diagram/SKILL.md` (37-66), `skills/1-hourly/recon/SKILL.md` (48-62), `AGENTS.md` (50-60)

## Searches I ran

- `ls` of the repo root, `skills/`, `utils/hq`, `utils/telemetry`, `PROJECT/*`; `wc -l` on maps and candidates.
- codebase-memory `list_projects` (two pages): no index for this clone.
- `rg -i "outer loop|outer-loop"` file list. This is the problem's own phrase, run alongside the capability reading; it surfaced the GH-1248/1356/1358 documents.
- `rg` for `FACTORY_SUPERVISED`, `supervisor`, `#1168|GH-1168`, `max_tasks|checkpoint_root`, `auto_merge|park`, `jog_` function definitions, harness subcommands, radar "two sinks / never executes", start-task "Step 6 / paraphrase".
- `git grep -l -i -E "launchctl|LaunchAgents"` excluding evidence folders: three tracked files, none for Jog.
- `git grep -n "ready-for-pickup" -- '*.py' '*.sh'`: no matches.
- One `rg -l -g` launchd search failed on flags and was re-run as the `git grep` above.
