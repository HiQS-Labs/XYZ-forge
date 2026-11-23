---
title: "GH-1240: next-steps-mod — Claude names the next steps every turn, no \"what's next?\" needed"
status: Complete
created: 2026-10-27
updated: 2026-10-28
owner: operator
gh_issue: 1240
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1240
doc_type: plan
effort: 1
complexity: 1
risk: 1
rating: "pri/sev/appeal/effort 45/10/70/75 · calc 200"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/964
  - https://github.com/HiQS-Labs/XYZ-forge/issues/967
goal: >
  A second Claude Code mod, deployed through Skills Army HQ, that makes every main-loop answer end
  with a Next:/Also: block and offers those steps as buttons, a Tab suggestion and /next-steps.
---

# GH-1240: next-steps-mod

## Status

| What was just completed | What's next |
|---|---|
| Issue filed; mod built at `skills/2-daily/next-steps-mod/` (manifest at the skill root so the HQ link auto-loads it); SKILL.md with the manual diagnostic; D1–D3 PASS recorded in `TESTS-RESULTS/2026-10-27+GH-1240/` (validate 2.1.309, tsc clean); Skills Index row + CHANGELOG. | Gate + PR; deploy with `intake.py add` + `sync.py --apply`; operator records D4–D7 and R1 in a fresh Desktop session. |

## Problem

In the Desktop session "10-27 PR review and fixes" (2026-10-27) the operator typed "So what are
natural next steps to close the loop?" and "Whats next?" to get a recommendation. The answer should
carry the recommendation unasked, every turn, and the recommendation should be one press away.

## Recon (base `82cc1f84`, Claude Code 2.1.309 in the Desktop app)

- **The previous customization method is Output Styles** (`/output-style`; built-ins Default,
  Concise, Explanatory, Learning, Proactive; `~/.claude/output-styles/*.md` for custom ones). It is
  still supported but only swaps prompt text. There is **no "Lean" style**: the engine's `lean`
  trait is the short system prompt (`CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT`), not a user customization.
- **Mod API** (bundled `plugin-authoring` skill, types of 2.1.309): `prompt.compose` appends a
  `session`-scope section after `next(e)`; `turn.complete` carries the final `answer`, `turnId`,
  `reason` and `agentId`; `ui.render` on `AbovePrompt` draws a band on the terminal and Desktop
  surfaces (`props.isWorking`, `props.hasSurvey`, `props.bodyColumns`); `$.prompt.suggest` sets the
  dim Tab-to-take suggestion; `$.prompt.submit({ asUser: true })` sends a prompt as the operator's own
  words; `$.command.register` + `command.run` add `/next-steps`.
- **Auto-load path:** a plugin inside `~/.claude/skills/<name>` is loaded and watched like a
  `--plugin-dir` folder. Skills Army HQ links exactly that path to `Deployed Skills/<name>`, so the
  manifest lives at the skill folder root (unlike `xyz-mod`, whose `mod/` subfolder needs
  `--plugin-dir`). This is GH-967 item 1 for this mod.
- **Engine-written files:** the engine lays `.claude-plugin/types/` beside a loaded mod. A nested
  `.gitignore` in the skill folder keeps that out of this repo and of the Pulse collection copy
  (the hourly Pulse writer refuses to sync a dirty tree).
- **Gate routing:** `skills/**` files no subsystem claims route as docs (`utils/ci-route.sh`);
  `test/gh589-skill-viewer.sh` needs valid `name`/`description` frontmatter in SKILL.md.

## Plan

1. `skills/2-daily/next-steps-mod/`: `.claude-plugin/plugin.json` (with `types`), `hooks/hooks.json`,
   `hooks/register.tsx`, `types/index.d.ts`, `tsconfig.json`, `.gitignore`, `SKILL.md`.
2. `ARCHITECTURE.md` Skills Index row; `CHANGELOG.md` entry.
3. Manual diagnostic (SKILL.md), recorded under `TESTS-RESULTS/2026-10-27+GH-1240/`.
4. Deploy: `intake.py add <forge>/skills/2-daily/next-steps-mod` then `sync.py --apply` against the
   Pulse root; verify `~/.claude/skills/next-steps-mod` resolves and a new session shows the band.

## Non-goals

Auto-submitting any prompt; a pane; a marketplace; changing the output style; new test suites
(GH-831); any tool-approval or prompt-rewrite hook.

## Risks

- **Mod API churn** (early access): contained, the mod is one folder; remove the HQ link to stop it.
- **Models ignore the block:** the band then says so and offers the one-press ask; the parser also
  tolerates a bullet or bold around `Next:`.
- **Band is terminal/Desktop only:** in VS Code the `Next:` line in the answer and `/next-steps` still
  work; the Tab suggestion depends on the surface.
