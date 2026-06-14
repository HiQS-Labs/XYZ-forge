# XYZ - A 3 Agent Coordination System (Beta)

An early skill to let Claude Code, Codex, and Gemini work the same codebase concurrently without colliding. 

## Status

- All 12 acceptance tests pass — run `./validate.sh`.
- Real-agent hand-test results: see [`REAL-AGENT-OBSERVATIONS.md`](REAL-AGENT-OBSERVATIONS.md).
- Spike recap: see [`RECAP.md`](RECAP.md).

## What it is

`tick` is a tiny CLI backed by an event log under `.tick/events/`. Each event is a separate JSONL file (one event per file = disjoint files = zero merge conflicts). `tick project` folds events into `.tick/STATE.md`. Coordination is **local-transport** (since Run 2): every verb is a pure append to a shared local `.tick/events/` — no git push or fetch per event. Peer agents see each other's events by reading the same shared directory, and a per-repo `O_EXCL` lock (`withClaimLock`, under `.tick/locks/`) serialises concurrent claims into a real mutex. `git` is still used for exactly one thing: `tick analyze` attributes work commits by author name.

## Quickstart (single repo)

```bash
# from the repo root:
./bin/tick init
./bin/tick log task.created TASK-001 \
  --agent dispatcher --priority 10 --paths "src/auth/**"
./bin/tick project
cat .tick/STATE.md
```

## CLI verbs

No verb touches the network — every verb appends locally to `.tick/events/`.

| Verb | Purpose |
|---|---|
| `tick init` | `mkdir -p .tick/events` |
| `tick log <type> <task> ...` | Append a raw event |
| `tick project` | Rebuild `.tick/STATE.md` from events |
| `tick claim <task> --agent <id> --paths <globs>` | Claim a task. Serialised by an `O_EXCL` lock so concurrent claims resolve to exactly one winner — a real mutex, no tie-breaker. Refused if the agent already holds 2 active claims (the cap). |
| `tick take --agent <id>` | Atomic `next` + `claim` under one lock — the recommended way to grab work, since it closes the `next`→`claim` race. Claims the task with the paths it was seeded with. |
| `tick next --agent <id>` | Return the next compatible task (read-only). Reports the claim limit instead of a task if the agent is at the cap. |
| `tick scope <task> --agent <id> --paths <globs>` | Replace the claim's path scope |
| `tick release <task> --agent <id> [--to <agent>]` | Release claim, optionally hand off |
| `tick break <task> --agent <id> --reason "..."` | Mark task circuit-broken; excluded from `tick next` for everyone |
| `tick done <task> --agent <id> [--note "..."]` | Mark complete |
| `tick ping <task> --agent <id> [--note "..."]` | Heartbeat on an active claim so `tick analyze` can tell a live claim from a parked/stalled one |
| `tick info <task>` | Print a task's current state — status, priority, owner, declared paths |
| `tick reap <agent> [--by <id>]` | Coordinator lever: release every active claim held by a presumed-crashed agent so peers can pick the work back up. Manual and logged — not auto-recovery. |
| `tick analyze [--format human\|md\|json] [--since <ref>] [--write <file>]` | Audit a multi-agent run: walks `.tick/events/` + `git log` and reports per-agent compliance (claimed before editing? declared paths matched? scope/done/break used?) plus cross-cutting collisions. Reusable across testing phases. |

`--paths` accepts comma-separated globs: `--paths "src/auth/**,tests/auth/**"`.

## Multi-agent setup: one shared event log

Coordination state lives in a single `.tick/events/` directory that every agent reads and writes, so the simplest (and tested) setup is **one shared `TICK_REPO_ROOT`**. There is no per-event push: an agent's `tick claim` is visible to peers the instant the event file lands, and the `O_EXCL` lock serialises concurrent claims. Point every agent's `tick` at the same root:

```bash
export TICK_REPO_ROOT=/path/to/shared/repo   # same value in every agent's session
./bin/tick init
```

Each agent passes its own ID with `--agent` on every verb. That flag — not git identity — is authoritative for claims; the old `--agent`-vs-`git config user.name` cross-check was removed in Run 2.

> **Caveat — git identity in a shared tree.** `tick analyze` attributes *work commits* by git author name, but a single working tree has only one `git config user.name` at a time, so per-agent attribution degrades if all agents commit from the same tree (this flipping was observed in Run 2). If you need clean per-agent `analyze` output, give each agent its own checkout that points at the same shared `TICK_REPO_ROOT`, or attribute from the `--agent` field in the event log rather than from commit authorship. This is a known open edge — see [`RECAP.md`](RECAP.md).

**Historical note.** Pre-Run-2 builds used a distributed transport: each critical event auto-`fetch`+`rebase`+`commit`+`push` so separate clones on a shared branch could see each other. That model — and its worktree friction (same-branch checkouts refused; per-child-branch pushes invisible to peers) — is what motivated the move to local transport. `bin/tick` no longer pushes.

## Agent integration prompt snippet

Paste this verbatim into each agent's system prompt or project instructions:

```
You are coordinating with other AI agents on this codebase via the `tick` CLI
at bin/tick. Your agent ID is <YOUR-ID>.

ONE-TIME SETUP (run once at session start):
  git config user.name <YOUR-ID>
  git config user.email <YOUR-ID>@trinity.local
This lets `tick analyze` attribute your work commits by git author name. (Your
`--agent <YOUR-ID>` flag is what's authoritative for claims; identity is only
for post-run attribution.)

BEFORE EDITING ANY FILES — grab a task first:
  Preferred: `tick take --agent <YOUR-ID>` — atomically runs `next` + `claim`
  under one lock, so you never lose a task to the next->claim race. It prints
  `won: <TASK-ID> ...`, or `(no available task)`.

  Manual equivalent (use if you need to declare extra paths up front):
    1. `tick next --agent <YOUR-ID>` to see what task is yours.
    2. `tick claim <TASK-ID> --agent <YOUR-ID> --paths "<glob1>,<glob2>"`
       declaring every file glob you intend to touch.
    3. If it prints `lost: ...`, someone else holds it — run `tick next` again.

CLAIM LIMIT: You may hold AT MOST 2 active claims at once. Finish (`tick done`)
or release (`tick release`) a task before claiming a third. `tick next` and
`tick claim` will refuse to give you a third — that is expected, not an error.

DEPENDENCIES: Use only the Node standard library — `node:http`, `node:test`,
`node:assert`. Do NOT install dependencies, do NOT edit `package.json`, do NOT
create a lockfile. `package.json` is shared and outside every task's scope;
touching it collides with the other agent and fails the run.

WHILE WORKING:
  - If you discover you need to edit files outside your declared paths, run
    `tick scope <TASK-ID> --agent <YOUR-ID> --paths "<expanded globs>"` BEFORE
    editing. This warns peer agents off the new scope.
  - If you get stuck or detect a poisoned task (failing tests after multiple
    attempts), run `tick break <TASK-ID> --agent <YOUR-ID> --reason "..."` so
    no other agent burns budget on it.

WHEN DONE:
  - Run `tick done <TASK-ID> --agent <YOUR-ID>` (after your final commit).
  - To pass the task to another agent instead, run
    `tick release <TASK-ID> --agent <YOUR-ID> --to <other-agent-id>`.

After the session, `tick analyze` will be run against the event log + git
history to measure: did you claim before editing? did your declared paths
match your actual edits? did you use scope/done/break correctly? Behave
accordingly.

Note: `tick` verbs are local-only — they append an event file under
`.tick/events/` and never touch the network. Commit your code changes with
normal git; `tick` does not push for you.
```

## Multi-agent flow

Seed the event log with non-overlapping tasks before starting agents:

```bash
tick log task.created TASK-A --agent dispatcher --priority 10 --paths "src/auth/**"
tick log task.created TASK-B --agent dispatcher --priority 10 --paths "src/billing/**"
tick log task.created TASK-C --agent dispatcher --priority 5  --paths "tests/**"
# events are local — no push needed; peers read the same shared .tick/events/
```

Then start each agent (all pointed at the same `TICK_REPO_ROOT`) with the integration prompt loaded.

## Constraints

- **Shared event log.** All coordinating agents read and write one `.tick/events/` (the same `TICK_REPO_ROOT`). Cross-clone / cross-branch sync is Phase 2.
- **Honest declaration required.** `tick` does not enforce that an agent's edits stay within declared paths. A pre-commit hook is one Phase 2 enforcement option.
- **Lock-serialised claims.** Concurrent `tick claim` / `tick take` calls are serialised by an `O_EXCL` lock under `.tick/locks/` — exactly one wins, the other is told to retry. No network, no push.

## Tests

```bash
./validate.sh        # run all acceptance tests
./test/handoff.sh    # run one
```

Each test runs in an isolated `$TMPDIR` working tree and exercises the protocol end-to-end against a shared local `.tick/events/`. (A bare remote is still scaffolded for the few assertions that touch git-level operations like author identity, but coordination no longer depends on push/pull.) Cleanup is automatic.

## Auditing a real-agent run

After any multi-agent session — Day 5 hand-test, future Phase 2 runs, anything — run:

```bash
./bin/tick analyze                                          # human-readable to stdout
./bin/tick analyze --format json                            # for downstream tooling
./bin/tick analyze --write REAL-AGENT-OBSERVATIONS.md       # append/replace the auto-analyzed section in-place
```

The analyzer walks `.tick/events/` and `git log`, attributes each work commit to whichever agent's claim window contains it (using git author name as the agent identifier — set `git config user.name` to your agent ID; see the shared-tree caveat above), and reports per-agent:

- **Claimed before editing?** Counts work commits not covered by any active claim by that agent.
- **Declared paths matched actual edits?** Per-commit comparison of touched files against the active claim's globs (claim paths ∪ scope_changed paths).
- **Used `tick scope` / `tick done` / `tick break`?** Direct event counts.
- **Drift examples + unclaimed work examples** for forensic inspection.

Cross-cutting: file collisions (same file edited by 2+ agents) and wasted work (commits on circuit-broken tasks).

Subjective questions in REAL-AGENT-OBSERVATIONS.md (what the prompt needed, what felt like friction) still require each agent to self-report.
