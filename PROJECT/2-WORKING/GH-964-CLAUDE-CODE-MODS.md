---
gh_issue: 964
source: https://github.com/HiQS-Labs/XYZ-forge/issues/964
title: "Explore Claude Code mods for XYZ-forge: turn-free status commands via a manual skill + diagnostic (GH-831-safe)"
status: In Progress
created: 2026-10-04
updated: 2026-10-04
owner: operator
goal: "One read-only Claude Code mod gives /xyz-status — hosted runs, tick claims, marathon/relay driver state — with no Claude turn, verified by a manual diagnostic."
complexity: 1
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Intake parked and rated (35/15/50/70); recon done on base `8853cd6a`; plan written. | Codex plan QA (relay), then build. |

## Problem

Waiting on hosted `wave-reconcile` runs and pre-push gates costs agent turns of `gh run watch`
polling (merge batch #957, 2026-10-03). Claude Code ≥ 2.1.287 can register slash commands from a
mod that answer with text and never start a model turn. XYZ has no such command today.

## Recon (base `8853cd6a`, Claude Code 2.1.289)

- **Mod API** (bundled `plugin-authoring` skill, `types/claude-code.d.ts` of 2.1.289):
  `$.command.register({ name, description, immediate })` inside `session.start`, answered by a
  `command.run` hook returning `{ text }`. `immediate: true` runs it while a turn is streaming.
  `$.process.run(argv, { cwd, timeoutMs })` runs a host command by argv (no shell), default cwd
  the session's, 30 s default timeout. A built-in command name is refused.
- **Name collision:** `/xyz` is already the `xyz` skill (`skills/2-daily/xyz/`, tick coordination).
  The command is therefore **`/xyz-status`**, and the skill folder is **`xyz-mod`** (a skill named
  `xyz-status` would itself become `/xyz-status`).
- **Existing read-only sources the command reuses (DRY; no logic re-implemented in the mod):**
  - hosted runs: `gh run list --workflow wave-reconcile.yml --branch development --limit 5`
    (the same query merge-cleanup uses for its hosted wait);
  - tick claims: `bin/tick claims` (read-only, from the event fold; the verb merge-cleanup reads);
  - marathon / relay driver state: `relay-automation/marathon-ls.sh` (read-only cross-repo monitor:
    REPO, STATE LIVE/STALE/IDLE/GONE, PHASE, LAST-TICK, PID, RELAY-FILE).
  The issue's "open relay threads with STATUS" has no existing lister; `marathon-ls.sh` covers the
  driven relays. Hand-parsing `relay-system/**` in JS would be a second implementation — dropped.
  The issue's optional `/xyz row N` is deferred (non-goal below).
- **Gate routing:** `utils/ci-route.sh` treats non-core `skills/**` files that no subsystem claims as
  docs (Small tier, lines 56–68); `xyz-mod` is not a core skill. `test/gh589-skill-viewer.sh` counts
  `skills/*/*/SKILL.md`, so the new skill needs valid `name`/`description` frontmatter and nothing
  else. No installer is added (`skills-army-hq` owns deployment), so `gh678` is untouched.

## Preflight bet check

- **Outcome sought:** the operator sees what is in flight without spending a model turn.
- **Smallest viable bet:** one mod, one command, three existing read-only commands, text output.
- **Not built:** panes/bands, timers or notifiers, tool-call hooks of any kind, prompt rewriting,
  `/xyz row N`, a marketplace, an installer, a `*.test.ts` or any registered suite.
- **Alternative rejected:** a skill or a shell alias. A skill costs a model turn (the problem
  itself); a shell alias works in the terminal but not inside the VS Code chat panel.
- **Rollback / containment:** delete `skills/2-daily/xyz-mod/` and stop passing `--plugin-dir`.
  The mod registers no `tool.call`, `prompt.*` or `session.append` hook, so it cannot approve,
  block or rewrite anything. Reversibility: **Easy**.

## Plan (one ordered list)

1. Add `skills/2-daily/xyz-mod/mod/` with three files:
   - `.claude-plugin/plugin.json` — `{ "name": "xyz-mod", "version": "0.1.0", "description": … }`;
   - `hooks/hooks.json` — `{ "modules": ["./register.ts"] }`;
   - `hooks/register.ts` — `session.start` registers `xyz-status` (`immediate: true`); the
     `command.run` hook runs the three commands above with `$.process.run` (cwd = session cwd,
     15 s timeout each), and returns one text block with a heading per source. A source that fails
     or is missing prints its exit code and first stderr line instead of hiding it (never an empty
     "nothing in flight" for a failed query). No other hooks.
   -> expect `claude plugin validate skills/2-daily/xyz-mod/mod` to list only `session.start`,
   `command.run`, `command.register`, `process.run`.
2. Add `skills/2-daily/xyz-mod/SKILL.md` (operator-invoked): what the mod does, how to load it
   (`claude --plugin-dir <abs path>/skills/2-daily/xyz-mod/mod`, or hot reload), the manual
   diagnostic below, and the read-only boundary.
3. Add one row to the `ARCHITECTURE.md` Skills Index and a `CHANGELOG.md` entry.
4. **Manual diagnostic** (in SKILL.md; recorded under `TESTS-RESULTS/2026-10-04+GH-964/` with
   `provenance.jsonl`), run once:
   - `claude --version` ≥ 2.1.287;
   - `claude plugin validate` output matches the hook/call list in step 1 and names no `tool.call`;
   - each underlying command runs once from the repo root and exits 0 (or reports its error);
   - `/xyz-status` in a live session prints all three sections and starts no turn;
   - **red control:** point the mod at a missing script (temporary local edit, not committed) and
     see that section print the error instead of an empty result.
   -> expect all green, red control red.
5. Gate: changed paths are docs/skill files only → `utils/pdda/pdda.sh run` plus
   `./validate.sh --auto` in a disposable full clone (expect it to pick the Small/docs tier).

## Non-goals

`/xyz row N`; open-relay parsing outside `marathon-ls.sh`; drawing (panes/bands are terminal and
desktop only); notifiers; any tool-approval or rewrite hook; marketplace; installer; new tests.

## Risks

- **Mod API churn:** mods are new (Oct 2026); a later Claude Code may rename calls. Contained: the
  mod is optional and loads only via `--plugin-dir`.
- **`gh` auth or network absent:** that section prints the error; the other two still answer.
- **Slow `marathon-ls.sh`** on many repos: bounded by the 15 s timeout, reported as a timeout.

## Rating rationale (2026-10-04)

`rated 35/15/50/70`. Severity 15: no defect, an operator time-saver. Priority 35: operator asked
for it; it removes polling turns seen in #957, nothing is blocked. Appeal 50: neutral (no operator
score given). Effort 70: three small files plus a skill doc. Recurrence: not a defect class; the
polling cost was observed once (merge batch #957).
