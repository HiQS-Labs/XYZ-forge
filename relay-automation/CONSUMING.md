# Consuming the relay tooling from ANOTHER repo (cross-repo mode)

> Written from first-time external-consumer feedback (KWFS-02, 2026-06-18). The containment core is
> solid; the friction was entirely the cross-repo path. This doc is that path, made explicit.

You want to review/build in **repo B** (your product repo) using the relay tooling that lives in
**repo A** (`xyz-3-agents-swarm`). Everything below is load-bearing — skipping any line is where
first-timers lose an hour.

## 1. The tooling is NOT self-contained — you cannot copy `bin/tick` alone

`bin/tick` requires `xyz-3-agents-swarm/src/` at runtime, and the shims
(`relay-automation/*-turn.sh`) source `relay-turn-lib.sh`. So either:

- **(recommended) Run from the xyz checkout** — clone `xyz-3-agents-swarm` and run the shim from
  there, pointing it at repo B (see §3); **or**
- **Vendor the trio** into repo B together: `relay-automation/` **+** `bin/tick` **+** `src/`. Not
  `bin/tick` by itself.

## 2. Run sandbox-OFF — including the PONG preflight

`agy` (and `codex`) fail **silently empty under a sandbox** (blocked backend → exit 0, no output).
The shim catches that as a hard failure (exit 5), but the preflight check fails the same way, so run
it sandbox-OFF too:

```bash
agy -p "Reply with exactly: PONG"     # MUST be run sandbox-OFF, else it prints nothing
```

If that prints nothing, you're sandboxed — not "agy is broken."

## 3. The cross-repo env contract (the recipe)

Run with **CWD = the tooling repo (A)** so `./bin/tick` and its `src/` resolve, and point the
guards at **repo B**:

```bash
cd /path/to/xyz-3-agents-swarm                 # CWD = tooling repo (A)

export AGY_AGENT=agy
export AGY_TURN_ROOT=/abs/path/to/repoB        # the git root containment guards + commits
export TICK_REPO_ROOT=/abs/path/to/repoB       # where tick writes .tick/ state
export TICK_BIN="$PWD/bin/tick"
export RELAY_AGENT=agy RELAY_PEER=<builder-id>
export RELAY_FILE=/abs/path/to/repoB/relay-system/<date>/<slug>.md   # REL lives INSIDE repo B
export RELAY_TASK=RELAY-TURN
export RELAY_TURN_TIMEOUT_S=600

bash relay-automation/agy-turn.sh              # sandbox-OFF
```

### ⚠ The sharp edge: TARGET paths must be ABSOLUTE

`agy`'s process CWD is the **tooling repo (A)**, so any **relative** file path in the relay file
resolves against the *wrong tree* and agy silently "finds nothing." **List every TARGET file under
review by absolute path** (`/abs/path/to/repoB/src/foo.php`), not `src/foo.php`.

> `agy-turn.sh` now prints a loud `CROSS-REPO mode … use ABSOLUTE TARGET paths` warning when
> `AGY_TURN_ROOT` differs from the CWD git root — heed it.

## 4. `.tick/` pollution in repo B

Seeding the turn token creates an untracked `.tick/` in repo B. Add it to repo B's `.gitignore`:

```
echo '.tick/' >> /abs/path/to/repoB/.gitignore
```

(The shim exempts `.tick/` from containment intrinsically, so it won't fail the turn — but it will
show as untracked until you ignore it.)

## 5. Known limitations (cost + commits)

- **Cost-blind lanes:** `agy` and `codex` emit no token data, so `tick analyze`/`cost` show nothing
  for those lanes. "Nothing" means *not captured*, not *zero*. Only the Claude lane is metered.
- **Commits land in repo B's history** with a generic `relay(RELAY-TURN): <agent> turn` message,
  file-scoped, **no push**. If you don't want interleaved relay commits in a product repo, squash
  them afterward. (A `--no-commit` stage-and-leave mode is a tracked follow-up, not yet available.)

## TL;DR checklist

- [ ] CWD = the xyz tooling repo (or vendor `relay-automation/` + `bin/tick` + `src/` into B).
- [ ] `AGY_TURN_ROOT` **and** `TICK_REPO_ROOT` = repo B (absolute).
- [ ] `RELAY_FILE` lives inside repo B; TARGET files listed by **absolute** path.
- [ ] PONG preflight + every turn run **sandbox-OFF**.
- [ ] `.tick/` added to repo B's `.gitignore`.
