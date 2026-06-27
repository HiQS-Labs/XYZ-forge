# Dueling Claudes — two windows, one bug-fix relay, no copy-paste

Two live Claude Code windows run a report → fix loop on **the same machine**, talking only
through one shared relay file. **No new code** — this is a recipe over the shipped harness
([poll.sh](poll.sh), `/loop`, `tick`) and the portable `/relay` protocol.

- **Claude A** — *Reporter*. Finds/cites the problem and files a graded report into the shared
  relay file. Never edits code. **Two review targets, identical mechanics:** (a) a **bug in
  another repo** — window open on that OTHER repo, cites findings by absolute path; or (b)
  **this repo's own code/protocol** (e.g. the Codex relay machinery) — Claude A is a session in a
  SEPARATE repo / VS Code window that reads THIS repo's code by **absolute path**. Only *what
  Claude A reads* differs; the loops, lock, and gate are the same. Either way Claude A is on a
  foreign CWD, so the foreign-CWD rules below (absolute `bin/tick`, `git -C` the xyz repo) apply.
- **Claude B** — *Maintainer*. Window open on THIS repo. Verifies each finding, fixes with the
  smallest change, then **stops before commit/push for your "go"** — the one human gate.

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

## Per run — 3 steps

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
3. That's it. The loops self-close on `STATUS: Closed` or the deadline.

## Worked examples

Two recorded runs. Copy the matching pair, swap the literals (token, deadline epoch, relay-file
path), and paste. The command strings ARE the contract — paste them exactly, literals and all.

### A. Bug-fix, cross-repo (the inaugural run, 2026-06-22)

Reporter on the OTHER repo files a bug, Maintainer fixes it here. The two `/loop` blocks under
[Per run -> step 2](#2-start-one-loop-in-each-window) are this run, against
[relay-system/2026-06-22/dueling-claudes.md](../relay-system/2026-06-22/dueling-claudes.md).

### B. Code/protocol review, same-repo (2026-06-23)

Claude A (Reporter) is a session in a **separate repo / VS Code window**; it reviews THIS repo's
own Codex relay machinery (`codex-turn.sh` + `relay-turn-lib.sh`) by absolute path. Claude B
(Maintainer) is a session on THIS repo. Thread:
[relay-system/2026-06-23/codex-relay-review.md](../relay-system/2026-06-23/codex-relay-review.md).

Because the Reporter is on a foreign CWD it must (i) read the code-under-review and the relay
file by **absolute path** (relative paths resolve against ITS repo, not this one); (ii) hand off
the lock with the env-pinned absolute `bin/tick`; and (iii) stage+commit the relay file with
`git -C "<xyz repo>"` — a bare `git commit` from its CWD would touch the wrong repo. On the same
machine the files are reachable, but that Claude session will prompt for permission to read/write
paths outside its own workspace — approve them (or add the xyz repo as an additional dir).

**Step 0 — seed (run once in this repo).** `tick claim` requires `--paths` (scope the lock to the
relay file); compute the deadline ONCE and paste the literal — never inline `$(date)` in a loop.

```bash
cd "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm"
TOKEN="DUELING-CODEX-0623"                 # fresh name per run; a done token can't reopen
DEADLINE=$(date -v+60M +%s)                # e.g. 1782251974 — paste this literal into BOTH loops
RELAY="relay-system/2026-06-23/codex-relay-review.md"
bin/tick log   task.created "$TOKEN" --agent claude-a
bin/tick claim "$TOKEN" --agent claude-a --paths "$RELAY"
echo "TOKEN=$TOKEN  DEADLINE=$DEADLINE"
```

**Window B — Claude A (Reporter), reviewer of this repo's code.** Even on the same repo, the
`env TICK_REPO_ROOT=` prefix + absolute `bin/tick` are kept so the command is identical whether
A sits in this clone or another — a bare `tick` from a foreign CWD silently no-ops (the #1
deadlock cause):

```
/loop 60s run env TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-a --claude-agents "claude-a,claude-b" --relay-task DUELING-CODEX-0623 --relay-file "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --artifact "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --deadline 1782251974 --dry-run ; if it printed "DECISION: run-runner", take your claude-a (Reporter) turn on that relay file per its embedded TAKE YOUR TURN block — do a CODE/PROTOCOL REVIEW of "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/codex-turn.sh" and "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh" (you are on a FOREIGN repo — read by ABSOLUTE path, cite findings by ABSOLUTE path:line, grade each [Blocker]/[Should]/[Nit]/[Pass] with a concrete proposed fix, set a Verdict), append your block to the relay file by absolute path, set NEXT: claude-b, then hand off the lock with the repo-root env + ABSOLUTE bin/tick: TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release DUELING-CODEX-0623 --agent claude-a --to claude-b ; then stage+commit the relay file in the xyz repo (git -C "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" add/commit — a bare git from your CWD hits the wrong repo; do NOT push, claude-b pushes after the operator go). On "DECISION: stop", CronList + CronDelete this loop, then stop. Else do nothing.
```

**Window A — Claude B (Maintainer), this repo** (no `env` prefix — CWD is this repo; bare `tick`
is fine). The gate is the clause in caps:

```
/loop 60s run "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-b --claude-agents "claude-a,claude-b" --relay-task DUELING-CODEX-0623 --relay-file "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --artifact "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --deadline 1782251974 --dry-run ; if it printed "DECISION: run-runner", take your claude-b (Maintainer) turn: verify each Reporter finding against the REAL code in relay-automation/codex-turn.sh + relay-turn-lib.sh, fix the [Blocker]/[Should] ones with the smallest change, log a disposition for every finding, append your turn block with a one-line Verification, set NEXT: claude-a — then SHOW ME THE DIFF AND STOP. Do NOT commit, push, or release the token until I say "go". After "go": git commit, git push origin main, then release: TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release DUELING-CODEX-0623 --agent claude-b --to claude-a. On "DECISION: stop", CronList + CronDelete this loop, then stop. Else do nothing.
```

## Fewer permission prompts — run the poll SANDBOXED (target Claude especially)

If the per-minute poll prompts the operator on every tick, the culprit is usually NOT the command
rule — it's a **sandbox bypass**. In Claude Code, disabling the Bash sandbox
(`dangerouslyDisableSandbox`) is a SEPARATE per-command approval that **no `permissions.allow`
entry can suppress** — so a loop that bypasses the sandbox prompts on every single tick, forever.

`poll.sh --dry-run` is **read-only** (a `git -C <root> status` + a `tick` read) and runs fine INSIDE
the sandbox — confirmed in live runs. So:

- **Run the poll sandboxed** — do NOT pass a sandbox bypass on the poll command. The **target
  (Reporter) Claude** is the common offender: if it reflexively disables the sandbox to reach the
  xyz repo from its own foreign CWD, that bypass — not the path — is what keeps prompting you.
- **Add the poll command to `permissions.allow`** (the prefix rule) so the sandboxed command itself
  is pre-approved, e.g. an entry matching `Bash(/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh:*)`.

Between the two, the per-minute poll stops prompting entirely. (The infrequent turn actions —
`git -C` commit, `tick release` — fire once per TURN, not per tick; and the Maintainer's commit is
gated behind your "go" anyway, so they're not the noisy part.)

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
  Mitigated when a **runnable gate** is the referee (a fix is accepted on red→green, not on opinion) —
  proven in the 2026-06-26 cross-repo run.
- **The token only works if BOTH windows run it.** Field finding (2026-06-26): if the Maintainer Claude
  just reads the relay file and does the work without `tick claim`/`ping`/`release`, the token
  coordinates nothing — the Reporter's poll idles as `parked suspect but no watchdog authority` and every
  handoff needs a manual `reap`+`claim`. The token also went **`spent — not claimable`** after several
  `release --to peer` round-trips. Practical fallback that worked: **retire the token and drive off the
  relay file's `NEXT:` + the peer's fix commits** (a 2-min commit-watcher auto-advanced the relay). See
  [PROJECT/2-WORKING/AUTOMATED-RELAY.md → Field findings](../PROJECT/2-WORKING/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26).
- **Run the in-loop gate sandbox-OFF.** Re-running the target's `bash tests/run.sh` from a watcher under
  the Claude Bash sandbox false-fails (PHP can't create lock files → bogus "syntax errors"); trust the
  Maintainer's un-sandboxed run and spot-confirm sandbox-off.
