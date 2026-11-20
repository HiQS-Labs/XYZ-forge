# run-8-skill-answer-free-opened-files-and-count

Agent id: `ae72b57dadcf63f7d`

## Prompt given (verbatim, local paths replaced)

You are working in the repository at "<verify-clone>". Stay inside that directory for all repository reading; do not read any other checkout of this repository or any memory/notes files outside it, and do not use anything you may have been shown from a memory index. Read-only: do not create, edit or delete any file, do not run tests, do not run git commands that change state. Do not load or invoke any skills through a Skill tool. Do not start subagents.

The ONE exception to "stay inside": first read this single instruction file in full and follow it exactly as your procedure (read nothing else in its folder):
"<local-path>"
Relative links inside it (../../4-occasional/..., ../../1-hourly/...) resolve under "skills/" inside the repository you are working in.

The operator asks:

"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"

Answer the operator by following that procedure. Your final message is the answer itself (max ~1000 words), in the output shape the procedure specifies. After the answer, add a short section "Files I actually opened" listing each file path you read (not merely searched), and "Searches I ran" listing the search queries/tools you used.

## Answer returned (verbatim, local paths replaced)

**Bottom line:** very little needs building. The loop already runs from "queued" to "PR ready"; it stalls because nothing moves prepared work into the queue and nothing committed wakes the runner. Those two joins, plus loop measurement, are what was not found in these searches.

## Step 1 — The problem, said back

- **What this asks for:** what to build so the flywheel's outer loop runs.
- **How it is handled today, per the operator:** not stated (only "struggling").
- **What it's not:** not stated.
- **Outcome (inferred):** finished work leads to the next item being chosen, built, checked and landed without a person pushing each step.
- **Constraints:** none stated.

Capabilities (inferred), with search synonyms:
1. Turn raw requests into ready work (refine / prepare).
2. Put ready work in line (admit / enqueue / pick up).
3. Take the next item and hand it to a builder (dispatch / lease).
4. Save progress between runs (checkpoint / publish / resume).
5. Start again on a clock (wake / schedule / launchd).
6. Decide, repair, land, advance (recover / sequence).
7. Watch and count the loop (observe / heartbeat / metrics).

## Step 2 — Search mode

- **Maps:** `ROUTER.md` and the `ARCHITECTURE.md` Skills Index.
- **Index:** the codebase-memory graph covers a different checkout, not this clone, so it was not used. There is no `graphify-out/`; ask_self was not queried.
- **Grep:** used for the rest, at `5967bde2`.

**Reverse sweep:** the maps name 79 skills and about 10 routed subsystems. Seven got a verdict from opened source; the rest are below as unopened leads or inferred set-asides.

- **Candidates (opened):** `flywheel`, `conveyor`, `jog` (`jog_run.py`), the RELEASES ledger's `jog_queue`, the HQ hourly scan, the `harness.py factory-primitive` subcommand.
- **Set aside (opened):** `handsfree` — same-conversation wake capped at 3 hours, "not a durable deployed scheduler" (`flywheel/SKILL.md:227-229`).
- **Unopened leads, not dismissed (search hits only):** `radar`, `10days`, `whack-a-mole`, `defect-campaign`, `ate`, `merge-cleanup`, `start-marathon`, `close-the-loop`, `todo-list`, `task-sync`, telemetry (`XYZ.json`), `poll.sh`, `wave_reconcile.py`.
- **Set aside, `inferred` from map purpose lines:** the remaining ~69 (review, planning lenses, CI, publishing, setup and audit skills).

## Step 3 — Fit table

| Capability | Existing module | `file:line` | Owner of state or lock | Fit | Limiting constraint | Cost or risk to adapt |
|---|---|---|---|---|---|---|
| 1. Prepare work | `conveyor` | `skills/1-hourly/conveyor/SKILL.md:8,15-16` | Capture doc + PRS row via `roadmap pickup` | use as is | Checked: stops before queue admission (`:10`), which is all this row needs | None |
| 2. Admit to queue | `jog_queue`, `cmd_jog_add` | `utils/py/releases_app.py:951,4725` | `jog_queue`, primary clone only | adapt | "today Jog does not select or admit work from it" (`conveyor/SKILL.md:67`); "normal no-row admission" still unmet (`GH-1358…md:211`) | Small; must not become a second queue |
| 3. Dispatch next item | `jog_run_main` | `utils/py/jog_run.py:2465-2483,2621-2637` | `JogSupervisorLock` (`:1500-1505`) | use as is | Checked: primary-only (`:2571`); strict position order, not rank. Ran on a 60s schedule (`GH-1358…md:79`) | None |
| 4. Save between runs | `--checkpoint-root` | `utils/py/jog_run.py:2482,2598-2610` | Jog checkpoint journal, under the same lock | use as is | Checked: opt-in, needs `--max-tasks`. Published without rescue (`GH-1358…md:92`) | None |
| 5. Wake on a clock | HQ hourly scan installer | `utils/hq/install-hourly-scan.sh:21-45`; `hourly-global-scan.sh:21-41` | Its own mkdir lock | pattern only | Read-only scan, not a dispatcher. The Jog launchd jobs were local and unloaded after (`GH-1358…md:145`); sleep gaps seen (`:147`) | Medium; another issue (#1168) is said to own the one scheduler (`GH-1360…md:22`) |
| 6. Decide, repair, land | `flywheel` | `skills/2-daily/flywheel/SKILL.md:64-84,186-243` | Each linked skill; per-PR merge approval stays (`:80-81`) | use as is | Checked: instruction-level and session-bound; "no observed effect on real-world throughput" (`GH-1400…md:109`) | None |
| 6b. Deterministic decision loop | `factory-primitive` | `utils/py/harness.py:1805-1844` | `temp/factory-primitive` `state.db` | pattern only | "creates no scheduler or queue integration" (`GH-1248…md:60`) | High if promoted |
| 7. Watch and count | — | — | — | not found in these searches (`outer.loop\|supervisor`, `launchd\|plist`) | An observer ran but only as a local job (`GH-1358…md:139`); loop called "uninstrumented" (`GH-1353…md:26`) | Unknown |

## Step 4 — Connect the dots

**Composition:** `conveyor` prepares; the `jog_queue` holds the line; `jog run --max-tasks 1 --checkpoint-root` dispatches and publishes under the one supervisor lock; `flywheel` sequences repair and landing; `merge-cleanup` lands on per-PR approval. The middle of this chain has already run on a schedule.

**New remainder (the only design work):**
1. An admission step that turns a `status:ready-for-pickup` item into a `jog add`, revalidated at pickup, writing only through the existing queue owner.
2. A committed, installable wake for that one Jog command, modelled on the HQ installer and placed under whichever owner #1168 names.
3. Loop counters and a committed observer.

**Unknowns:**
- The three Step 1 headings marked not stated — which stage actually stalls for you settles all three.
- #1168's scheduler: referenced, implementation not read.
- `PROJECT/2-WORKING/GH-1015-OBSERVER-PATH/`: not opened; it may already cover part of row 7.
- Whether findings from shipped work (`radar`, `whack-a-mole`, `10days`) feed intake: search hits only.
- Merge approval is a policy boundary, not a gap; an unattended loop still stops there.

**One next action:** run `recon` on the Jog pickup and admission path (`jog_run.py` promotion plus `cmd_jog_add`) before designing the admission step.

## Files I actually opened

Paths are relative to `<verify-clone>/` unless absolute.

- `<scratchpad>/ctd-deseeded-v4/SKILL.md`
- `ROUTER.md`
- `ARCHITECTURE.md` (lines 26-157, 430-576)
- `skills/4-occasional/swe-diagram/SKILL.md` (35-64)
- `skills/1-hourly/recon/SKILL.md` (46-70)
- `skills/1-hourly/start-task/SKILL.md` (195-209)
- `skills/2-daily/flywheel/SKILL.md`
- `skills/1-hourly/conveyor/SKILL.md`
- `skills/2-daily/jog/SKILL.md` (28-46)
- `utils/py/jog_run.py` (1-40, 1500-1508, 2465-2639)
- `utils/py/harness.py` (186-192, 1834-1843)
- `utils/hq/hourly-global-scan.sh` (1-60)
- `utils/hq/install-hourly-scan.sh` (1-60)
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`
- `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`
- `PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md` (1-40)
- `PROJECT/2-WORKING/GH-1376-FLYWHEEL-SKILL.md` (1-40)
- `PROJECT/1-INBOX/GH-1358-DURABLE-FACTORY-QUALIFICATION.md`
- `PROJECT/1-INBOX/GH-1360-GENERIC-MONITOR-SUPERVISOR.md`
- `PROJECT/1-INBOX/GH-1353-NEXTGEN-FLYWHEEL.md`

## Searches I ran

- `ls` of the repo root, `skills/*/`, `ARCHITECTURE/`, `PROJECT/`, `PROJECT/2-WORKING`, `PROJECT/1-INBOX` (filtered to 13xx/14xx), `utils/py`, `utils/py/factory_primitive`; `wc -l` on candidate files; `git rev-parse HEAD`.
- `mcp__codebase-memory-mcp__list_projects` — index is for another checkout, so not queried.
- `rg -l -i "outer.loop|supervisor"` across the repo, excluding CHANGELOG, SQL, HTML, test results, relay threads and completed docs.
- `rg -l -i "launchd|launchagent|crontab|plist"` across the repo, same style of exclusions.
- `rg -l "1168"` across the repo.
- `rg -n` in `utils/py/jog_run.py` for `checkpoint-root|max-tasks|jog_run_main|supervisor lock|driver.lock|admission`.
- `rg -n` in `utils/py/releases_app.py` for `jog_queue|cmd_jog`.
- `rg -n` in `utils/py/harness.py` for `factory.primitive|add_parser`.
- `rg -n -i` in the `jog`, `radar`, `10days` and `handsfree` skill files for scheduling, readiness and execution terms (hits only; those files were not read apart from `jog` 28-46).
- `grep -n` for headings and `paraphrase` in `start-task/SKILL.md` and `ARCHITECTURE.md`.
- Three early searches failed on flag errors and were re-run in the forms above.
