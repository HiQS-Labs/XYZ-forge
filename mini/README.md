# XYZ mini

A small set of skills for getting two or more AI coding agents to check each other's work —
without a framework to learn first.

XYZ mini is the beginner-sized sibling of [XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge).
The forge carries the full harness: marathons, release ledgers, governance docs, dozens of skills.
Mini carries seven skills and a `TODO.md`. Everything here is published from the forge by a
deterministic script, so every managed file (everything listed in `MANIFEST.txt`) is byte-identical
to its forge source at the revision named in `.xyz-forge-revision`. `TODO.md` is yours.

## What is in the box

| Skill | What it does |
|---|---|
| `relay` | A turn-based review loop between two agents through one shared markdown file, so you stop copy-pasting between windows. |
| `consult` | Ask Codex and Gemini (agy) the same question in parallel, in isolated worktrees, and get both answers with provenance stamps. |
| `agent-chorus` | A structured multi-agent discussion with named seats and a transcript. |
| `debug-mantra` | Four steps that keep a debugging session honest: reproduce, trace, falsify, cross-reference. |
| `ponytail` | The laziest solution that actually works. Cuts scope, dependencies and abstraction. |
| `honest` | A read-only maturity check that says what a repo actually does versus what it claims. |
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

`ponytail`, `agent-chorus` and `consult` ship an `install.sh` that creates those links for
Claude Code, Codex and Gemini in one go:

```bash
bash "$(git rev-parse --show-toplevel)/skills/consult/install.sh"
```

## Requirements

- `git`, `bash`, `python3` (3.8+)
- For `consult`: the `codex` and/or `agy` CLIs on your `PATH`. If one advisor is unavailable consult
  degrades to a single-model answer and says so; if none can answer it exits 5.
- Nothing else. There is no `tick` binary, no database, no project lifecycle here.

## Try it

1. `consult`: `relay-automation/consult.sh --prompt "Is this function thread-safe?" --models codex,agy`
   writes both answers under `relay-system/<date>/`.
2. `relay`: open two agent windows, have one run `/relay` to scaffold a thread, and take turns.
3. `debug-mantra`: paste a stack trace and run `/debug-mantra`.

## Where the rest lives

Want marathons, release planning, or the other fifty skills? That is
[XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge). Bugs in a skill you found here belong in
the forge's issue tracker; fixes flow back to mini on the next publication.

`TODO.md` is yours: it is seeded once and never overwritten.

## License

See `LICENSE` and `LICENSE-COMMERCIAL.md`.
