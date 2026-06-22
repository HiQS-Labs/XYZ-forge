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
DEADLINE=$(date -v+45M +%s)   # compute ONCE here — NEVER inside the /loop string ($(date) there re-evaluates every tick and never expires)
bin/tick log   task.created "$TOKEN" --agent claude-a
bin/tick claim "$TOKEN" --agent claude-a
echo "Lock token: $TOKEN   ·   Deadline epoch: $DEADLINE   (paste BOTH as literals into the two loops below)"
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
/loop 60s run env TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-a --claude-agents "claude-a,claude-b" --relay-task $TOKEN --relay-file "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --artifact "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --deadline <DEADLINE-literal-from-step-0> --dry-run ; if it printed "DECISION: run-runner", take your claude-a turn on that relay file per its embedded instructions (file/refine the bug report, citing the other repo's files by ABSOLUTE path), append your block, set NEXT: claude-b, then hand off the lock with the repo-root env + ABSOLUTE bin/tick (a bare `tick` from your foreign CWD silently no-ops — this is the #1 deadlock cause): TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release $TOKEN --agent claude-a --to claude-b ; then commit the relay file (git -C the xyz repo; don't push — claude-b pushes). On "DECISION: stop", CronList + CronDelete this loop. Else do nothing.
```

**Window B — Claude B (Maintainer), opened on this repo** (no `env` prefix — CWD is already
this repo). The **gate** is the clause in caps:

```
/loop 60s run "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-b --claude-agents "claude-a,claude-b" --relay-task $TOKEN --relay-file "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --artifact "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --deadline <DEADLINE-literal-from-step-0> --dry-run ; if it printed "DECISION: run-runner", take your claude-b turn: verify the reported bug, fix it in this repo with the smallest change, append your turn block to the relay file, set NEXT: claude-a, then SHOW ME THE DIFF AND STOP — do NOT commit, push, or release the token until I say "go". After "go": commit, push, then `tick release $TOKEN --agent claude-b --to claude-a` (bare `tick` is fine here — window B's CWD is the xyz repo). On "DECISION: stop", CronList + CronDelete this loop. Else do nothing.
```

## The human's whole job

1. Run step 0 + start the two loops (above).
2. When Claude B shows a fix diff and stops, glance and say **"go"** (or "no, change X").
3. That's it. The loops self-close on `STATUS: Closed` or the 45-min deadline.

## Notes & limits

- **Same machine only.** Both windows share one filesystem (the relay file + `.tick/` lock).
  Two machines would need out-of-band `.tick/` sync — not built (see [CONSUMING.md](CONSUMING.md)).
- **`.tick/` is gitignored / per-device** — this is single-clone coordination, not cross-machine.
- **`--dry-run` is mandatory in Path B.** Both loops pass `--dry-run` so `poll.sh` only *advises*
  (`DECISION: …`) and the live Claude takes the turn. Without it, `poll.sh` dispatches `runner.sh`
  (a Path-A driver that needs `--task/--agent`) and the tick crashes. Path B is advisory-only.
- **Deadline self-closes the loop** so a dead peer window can't make you spin forever — but
  compute it ONCE (step 0) and paste the literal epoch; an inline `$(date …)` inside the `/loop`
  string re-evaluates every tick and never expires. Bump the `+45M` in step 0 if a fix may take longer.
- **Zero new code moves the risk into the command strings.** The two loop commands carry the whole
  turn contract and nothing tests a copy-pasted string — paste them exactly, literals and all.
- **Need a fix to land in the OTHER repo instead?** That's the only case that needs more: add
  `--target-root <other-repo>` per [CONSUMING.md](CONSUMING.md). Not needed for the default
  (all work in this repo).
- **Same-model blind spots.** Two Claude windows share a model; for genuinely independent review
  put Codex/agy in window B via Path A (see [skills/relay-xyz/SKILL.md](../skills/relay-xyz/SKILL.md)).
