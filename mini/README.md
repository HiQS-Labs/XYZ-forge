# XYZ mini

A small set of skills for getting two or more AI coding agents to check each other's work —
without a framework to learn first.

XYZ mini is the beginner-sized sibling of [XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge).
The forge carries the full harness: marathons, release ledgers, governance docs, dozens of skills.
Mini carries eleven skills and a `TODO.md`. Everything here is published from the forge by a
deterministic script, so every managed file (everything listed in `MANIFEST.txt`) is byte-identical
to its forge source at the revision named in `.xyz-forge-revision` — except paths registered as
adapted in [ORIGIN.md](ORIGIN.md), which carry mini-local changes and name their upstream there.
Publications may run from any forge branch; `.xyz-forge-revision` records which one. `TODO.md` is
yours.

## What is in the box

| Skill | What it does |
|---|---|
| `relay` | A turn-based review loop between two agents through one shared markdown file, so you stop copy-pasting between windows. |
| `consult` | Ask Codex and Gemini (agy) the same question in parallel, in isolated worktrees, and get both answers with provenance stamps. |
| `agent-chorus` | A structured multi-agent discussion with named seats and a transcript. |
| `debug-mantra` | Four steps that keep a debugging session honest: reproduce, trace, falsify, cross-reference. |
| `unstuck` | A mid-flight interrupt for a stalled agent session: freeze the machinery, re-anchor the goal, test the claimed blocker, take the one smallest move that changes task state. |
| `ponytail` | The laziest solution that actually works. Cuts scope, dependencies and abstraction. |
| `honest` | A read-only maturity check that says what a repo actually does versus what it claims. |
| `weekly-planner` | Dual-horizon weekly planning and team orchestration with topological merge sequencing and adversarial conflict audits. |
| `daily-planner` | Adaptive daily planning skill that pivots the active weekly plan based on yesterday's landed PRs and closures. |
| `review-code` | A meticulous code and PR review ladder: maps blast radius, tests fixes against live ground truth, then posts the graded report to the GitHub PR or issue and renders it on-screen — both, every run. |
| `skill-viewer` | Lists the skills in this repo from their frontmatter. |

Run `python3 skills/skill-viewer/scripts/list_skills.py` from the repo root to see the live list.

## Install a skill

Each skill is a folder with a `SKILL.md`. Point your agent's skill directory at it. For Claude Code:

```bash
git clone https://github.com/HiQS-Labs/XYZ-mini.git
cd XYZ-mini
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/relay" ~/.claude/skills/relay        # repeat per skill you want
```

`ponytail`, `agent-chorus`, `consult`, `weekly-planner`, `daily-planner` and `review-code` ship an `install.sh` that creates those links:

```bash
bash "$(git rev-parse --show-toplevel)/skills/consult/install.sh"
```

## Requirements

- `git`, `bash`, `python3` (3.8+)
- For `consult`: the `codex` and/or `agy` CLIs on your `PATH`. If one advisor is unavailable consult
  degrades to a single-model answer and says so; if none can answer it exits 5.
- For `review-code`: the `gh` CLI, authenticated, so the final verdict can be posted to the GitHub
  PR or issue; with no GitHub target the review is reported on-screen only.
- Nothing else. There is no `tick` binary, no database, no project lifecycle here.

## Try it

1. `consult`: `relay-automation/consult.sh --prompt "Is this function thread-safe?" --models codex,agy`
   writes both answers under `relay-system/<date>/`.
2. `relay`: open two agent windows, have one run `/relay` to scaffold a thread, and take turns.
3. `debug-mantra`: paste a stack trace and run `/debug-mantra`.
4. `unstuck`: when a session is narrating instead of moving, run `/unstuck`.

## Where the rest lives

Want marathons, release planning, or the other fifty skills? That is
[XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge). Bugs in a skill you found here belong in
the forge's issue tracker; fixes flow back to mini on the next publication.

`TODO.md` is yours: it is seeded once and never overwritten.

## License

See `LICENSE` and `LICENSE-COMMERCIAL.md`.
