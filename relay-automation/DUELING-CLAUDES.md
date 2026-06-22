# Dueling Claudes — two windows, one bug-fix relay, no copy-paste

Two live Claude Code windows run a bug-report → fix loop across two repos on **the same
machine**, talking only through one shared relay file. **No new code** — this is a recipe over
the shipped harness ([poll.sh](poll.sh), `/loop`, `tick`) and the portable `/relay` protocol.

- **Claude A** — *Reporter*. Window open on the OTHER repo. Finds/cites a bug, files a report
  into the shared relay file (which lives in THIS repo). Never edits this repo's code.
- **Claude B** — *Maintainer*. Window open on THIS repo. Fixes the bug, then **stops before
  commit/push for your "go"** — the one human gate.

All commits land in **this** repo (`xyz-3-agents-swarm`), so no `--target-root` is needed.

## How it works (why it's zero-code)

| Piece | Role |
|---|---|
| The shared **relay file** (`relay-system/<date>/<slug>.md`) | the no-copy-paste channel — both windows read/append it on disk |
| The **`tick` RELAY-TURN token** | the lock — `poll.sh` only says `run-runner` when the token is claimable by *your* agent id |
| **`/loop` + `poll.sh`** in each window | the automation — polls every 60s, takes the turn when it's yours, idles otherwise |
| A **dirty relay file** | the gate — after B edits but before it commits, `poll.sh` returns `idle` ("my turn but scope dirty"), parking the loop until your "go" |

## One-time per clone

Makes the skill + harness findable from **any** repo (so Claude A, sitting in the other repo,
can still reach this harness):

```bash
bash "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/skills/relay-xyz/install.sh"
```

## Per bug — 3 steps

### 0. Pick a fresh lock token and seed it

A `done` token can't be reopened, so use a unique name per relay (date-stamped is fine). Run
this once, in **this** repo, before starting the loops — it creates the token and makes it
Claude A's (Reporter's) turn first:

```bash
cd "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm"
TOKEN="DUELING-$(date +%m%d-%H%M)"
bin/tick log   task.created "$TOKEN" --agent claude-a
bin/tick claim "$TOKEN" --agent claude-a
echo "Lock token: $TOKEN   (pass this as --relay-task in both loops)"
```

### 1. Scaffold the thread (or reuse one)

Use `/relay` to scaffold `relay-system/<date>/<slug>.md`. The inaugural one already exists:
[relay-system/2026-06-22/dueling-claudes.md](../relay-system/2026-06-22/dueling-claudes.md).
Its embedded `▶ TAKE YOUR TURN` block tells each window exactly what to do — including B's gate.

### 2. Start one `/loop` in each window

Absolute paths because `/loop` runs from each window's own CWD; the `env TICK_REPO_ROOT=…`
prefix on Claude A is load-bearing — without it `tick` looks for the lock in the wrong repo.
Replace `$TOKEN` with the value from step 0 and `<slug>`/date with your thread.

**Window A — Claude A (Reporter), opened on the other repo:**

```
/loop 60s run env TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-a --claude-agents "claude-a,claude-b" --relay-task $TOKEN --relay-file "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --artifact "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --deadline "$(date -v+45M +%s)" ; if it printed "DECISION: run-runner", take your claude-a turn on that relay file per its embedded instructions (file/refine the bug report, citing the other repo's files by ABSOLUTE path), append your block, then `tick release $TOKEN --agent claude-a --to claude-b` and commit+push the relay file. On "DECISION: stop", CronList + CronDelete this loop. Else do nothing.
```

**Window B — Claude B (Maintainer), opened on this repo** (no `env` prefix — CWD is already
this repo). The **gate** is the clause in caps:

```
/loop 60s run "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-b --claude-agents "claude-a,claude-b" --relay-task $TOKEN --relay-file "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --artifact "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --deadline "$(date -v+45M +%s)" ; if it printed "DECISION: run-runner", take your claude-b turn: verify the reported bug, fix it in this repo with the smallest change, append your turn block to the relay file, then SHOW ME THE DIFF AND STOP — do NOT commit, push, or release the token until I say "go". After "go": commit, push, then `tick release $TOKEN --agent claude-b --to claude-a`. On "DECISION: stop", CronList + CronDelete this loop. Else do nothing.
```

## The human's whole job

1. Run step 0 + start the two loops (above).
2. When Claude B shows a fix diff and stops, glance and say **"go"** (or "no, change X").
3. That's it. The loops self-close on `STATUS: Closed` or the 45-min deadline.

## Notes & limits

- **Same machine only.** Both windows share one filesystem (the relay file + `.tick/` lock).
  Two machines would need out-of-band `.tick/` sync — not built (see [CONSUMING.md](CONSUMING.md)).
- **`.tick/` is gitignored / per-device** — this is single-clone coordination, not cross-machine.
- **Deadline self-closes the loop** so a dead peer window can't make you spin forever. Bump
  `+45M` if a fix may take longer.
- **Need a fix to land in the OTHER repo instead?** That's the only case that needs more: add
  `--target-root <other-repo>` per [CONSUMING.md](CONSUMING.md). Not needed for the default
  (all work in this repo).
- **Same-model blind spots.** Two Claude windows share a model; for genuinely independent review
  put Codex/agy in window B via Path A (see [skills/relay-xyz/SKILL.md](../skills/relay-xyz/SKILL.md)).
