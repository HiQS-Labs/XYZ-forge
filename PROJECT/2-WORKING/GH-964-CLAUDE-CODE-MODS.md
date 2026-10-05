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
| Plan approved by Codex (round 2). Built `skills/2-daily/xyz-mod/` (mod + skill doc). Manual diagnostic recorded in `TESTS-RESULTS/2026-10-04+GH-964/`: D1, D2, D3, D6 and red control R1 pass; headless `/xyz-status` ran with `num_turns` 0. | Codex final QA, then PR. Operator owes D4/D5 (`/plugin` active; `/xyz-status` in the terminal and VS Code), then go / no-go. |

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
  - hosted runs: `gh run list --branch development --limit 8` — no `--workflow` filter, so both
    `wave-reconcile.yml` and the `ci.yml` gate runs show (same reader family merge-cleanup uses at
    `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:451`); labelled "recent 8", not a
    complete in-flight inventory;
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
     `command.run` hook first resolves the repo root with `git rev-parse --show-toplevel` from the
     session cwd (so a session started in `src/` still works), prints that root as the first line,
     then runs the three readers by **absolute path** under that root with `cwd` = root and
     `TICK_REPO_ROOT` = root (so `bin/tick` cannot follow an inherited root to another checkout),
     15 s timeout each, and returns one text block with a heading per source. Each reader is
     independent: a nonzero exit, a thrown `$.process.run` (missing file, timeout) or empty stdout
     prints `ERROR (<exit or reason>): <first stderr line>` for that section and the other sections
     still answer — never an empty "nothing in flight" for a failed query. Outside a git repo the
     command says so and stops. No other hooks.
   -> expect `claude plugin validate skills/2-daily/xyz-mod/mod` to list only `session.start`,
   `command.run`, `command.register`, `process.run`.
2. Add `skills/2-daily/xyz-mod/SKILL.md` (operator-invoked): what the mod does, how to load it
   (`claude --plugin-dir <abs path>/skills/2-daily/xyz-mod/mod`, or hot reload), the manual
   diagnostic below, and the read-only boundary.
3. Add one row to the `ARCHITECTURE.md` Skills Index and a `CHANGELOG.md` entry.
4. **Manual diagnostic** — a written checklist in SKILL.md, no runner script. Results recorded under
   `TESTS-RESULTS/2026-10-04+GH-964/` with `provenance.jsonl`. **Healthy** for a reader means exit 0
   **and** non-empty stdout; anything else is **FAIL** for that check.
   - D1 `claude --version` ≥ 2.1.287.
   - D2 `claude plugin validate <mod>` lists only the hooks/calls in step 1 and no `tool.call`,
     `prompt.*` or `session.append` hook.
   - D3 each reader, run by hand from the repo root with the same argv, is healthy.
   - D4 `/plugin` shows the mod active when launched with `--plugin-dir`.
   - D5 `/xyz-status` in the **terminal** and in the **VS Code extension** prints the root line and
     three healthy sections and starts no model turn (no assistant reply follows it).
   - D6 run `/xyz-status` from a session started in `src/`: the root line names the repo root and
     the sections are healthy.
   - **Red control R1:** temporarily point one reader at a missing path (local edit, not committed):
     that section is FAIL (`ERROR …`), the other two stay healthy. Restore, re-run: all healthy.
     Record healthy / mutant / restored outcomes.
   -> expect D1–D6 healthy, R1 mutant FAIL, R1 restored healthy.
5. Gate: changed paths route as docs, tier 1 (`utils/ci-route.sh:63`, reviewer probe in
   `relay-system/2026-10-04/gh964-plan-qa.md`). Run `utils/pdda/pdda.sh run`; that is the tier-1
   docs gate. The Small registry (`validate.sh --sequential --subsystem small`) is the hosted
   reconcile's qualifying run for this landing and is not claimed locally.
6. Record the go / no-go (keep, extend, drop) in this doc's Status table and on the issue.

## Acceptance mapping (issue #964 → plan)

| Issue acceptance item | Where |
|---|---|
| Claude Code ≥ 2.1.287 on the main machine; `/plugin` shows the mod active with `--plugin-dir` | D1, D4 (2.1.289 installed 2026-10-04) |
| `/xyz` prints hosted runs, `tick` claims and open relays with no turn, in VS Code and terminal | Step 1 + D5. Command is `/xyz-status` (name collision). Hosted runs cover `wave-reconcile` and `ci.yml` gate runs. Relays: driven relays via `marathon-ls.sh`; undriven `relay-system/**` thread STATUS **deferred** (no existing reader; parsing in the mod would duplicate logic) |
| `claude plugin validate` lists no approval/rewrite calls (recorded) | D2 |
| Manual diagnostic green once, recorded; unknown path makes it fail | D1–D6, R1 |
| No new registered suite or registry entry (GH-831) | Non-goals; step 5 |
| Go / no-go recorded | Step 6 |
| Optional `/xyz row N` | **Deferred** (non-goal) |

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
