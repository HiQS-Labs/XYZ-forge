# Running findings log

Append-only. One entry per issue, written when it was hit, with the exit code that proved it.
Tags: **LINUX** (real defect any Linux user hits) · **WSL** (artefact of this environment only,
not a repo bug) · **DOC** (docs wrong/missing/macOS-assuming) · **UNKNOWN** (needs a native
Linux box to disambiguate).

`evidence/FINDINGS.md` is the cleaned, issue-ready version of this file. This one is the raw
chronological record.

---

## F-001 — relay-xyz guard blocks read-only inspection inside a compound command

**Tag: LINUX** · Severity: low (safe direction — over-blocks, never under-blocks)

Command:
```bash
cd ~/XYZ-forge && sed -n "1,90p" relay-automation/marathon.sh
```
Exit: **2** (guard `exit 2`, tool call cancelled)

Expected per the guard's own contract, `relay-automation/hooks/relay-xyz-guard.sh:26`:

> `Only relay-automation/<driver>.sh paths block — test/<driver>.sh and reads are exempt,`

Actual: the read was blocked. The read-exemption at `:98-101` inspects only the **first word of
the whole command string**:

```bash
first="${FIELD%% *}"
case "$first" in
  cat|head|tail|less|more|wc|grep|rg|ls|bat|file|stat|chmod|git|find|awk|sed) exit 0 ;;
esac
```

With `cd ~/XYZ-forge && sed -n ...` the first word is `cd`, which is not in the list, so the
exemption misses and the driver-entrypoint case at `:105-128` blocks. Any compound command —
`cd X && cat file`, `set -e; head file`, a `for` loop — defeats the exemption. `cd <repo> && <read>`
is the single most common shape an agent emits, so the exemption misses in the common case.

Not WSL-specific: pure string matching, identical on any Linux or macOS host.

**Why the suite does not catch it.** `test/relay-xyz-skill-guard.sh` has a dedicated
"no false positives" section (`:56-68`) — but every case in it is a **bare** first word:

```
:60   run "sess-fp" Bash "cat relay-automation/poll.sh"
:61   pass "reading a harness file (cat) is not blocked"
:63   (bash -n …)
:66   (git status)
```

There is no case of the form `cd <dir> && <read>`. The test asserts exactly the shape the
implementation handles, so the gap is invisible to a green suite. Observed live in
`evidence/02-validate-sequential.log` — those three assertions pass in the same run in which the
real-world compound form was blocked.

A one-line test would pin it:

```bash
run "sess-fp" Bash "cd /tmp && cat relay-automation/poll.sh"   # expect RC 0, actual RC 2
```

Workaround used: the `Read` tool (not hooked), and bare-first-word reads.

Repro: `repro.sh probe-guard-read`.

---

## F-002 — "compute" is not a marathon verb anywhere in the repo

**Tag: DOC** · Severity: informational (correction to the task brief, not a repo defect)

The brief specifies a five-step lifecycle "compute, preflight, dry run, full run". Four of those
resolve to real commands (`evidence/01-command-map.md`). **"Compute" does not exist.**

```bash
grep -rn -i '\bcompute\b' utils/ relay-automation/*.md skills/ README.md
```
Exit: **0**, 9 hits, none a marathon lifecycle verb. The only marathon-adjacent hit is an internal
implementation comment, `utils/marathon-plan.sh:170`:

> `# One embedded Node program does the compute (parse ledger → resolve items → signals → score →`

The repo's actual documented lifecycle, `.claude/commands/pre-marathon.md:6-22`, is
**triage → preflight → dry-run → confirm → fire**. Ranking/wave-formation (the nearest thing to
"compute") is owned by the `marathon-triage` skill and implemented by `utils/marathon-plan.sh`.

Resolution adopted: treat `utils/marathon-plan.sh` as the compute step and say so, rather than
invent a verb. Recorded because a stranger reading the brief would go looking for a
`marathon compute` command that does not exist.

---

## F-003 — `marathon-plan.sh --help` advertises its inner Python path as the command name

**Tag: DOC** · Severity: low (cosmetic, but misdirects a first-time operator)

```bash
bash utils/marathon-plan.sh --help
```
Exit: **0**. First line of output:

```
Usage: utils/py/marathon_plan.py [--dry-run | --check] [--policy quick-wins|derisk-first]
```

The operator invoked `utils/marathon-plan.sh`; the help names `utils/py/marathon_plan.py`. That is
the `XYZ_PYTHON` dual-runtime shim (`README.md:271-277`) leaking its implementation path into
user-facing help. A reader who copies the usage line verbatim invokes the Python file directly,
bypassing the shim's Bash fallback — the exact escape hatch the dual-runtime design exists to
preserve.

`utils/swarm-preflight.sh --help` does **not** have this problem (`:94` prints its own shim path),
so the two sibling tools disagree.

Log: `evidence/02-marathon-plan-help.log`.

---

## F-004 — exit code 8 means "lane parked", not "relay block invalid"

**Tag: DOC** · Severity: informational (correction to the task brief)

The brief asks me to watch for exit `8 (relay block invalid)`. In this revision,
`relay-automation/marathon-drive.sh:65-66` defines:

> `8 lane parked (GH-45 attempt cap — no token seeded; re-fire with --force)`

There is a separate `bin/validate-relay-block` entrypoint, but its failures do not surface as
marathon exit 8. The brief's other three codes are correct: `6` containment violation (`:64`),
`7` turn timeout/hang (`:65`), `108` gate killed by the GH-390 guard (`README.md:243-245`).

Full table in `evidence/01-command-map.md` §4.

---

## F-005 — no headless builder on PATH; `claude` resolves to the Windows binary

**Tag: WSL** (the interop leak) + **DOC** (the missing prerequisite check)

```bash
bash skills/relay-xyz/find-harness.sh --check
```
Exit: **0**. Output:

```
  ok  harness  (/home/arnoldadero/XYZ-forge)
  ok  tick CLI  (/home/arnoldadero/XYZ-forge/bin/tick)
  --  codex CLI (Path A worker)  (not found)
  --  agy CLI   (Path A worker)  (not found)
  !   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available
```

`find-harness.sh --check` reports this correctly and clearly — the tool behaves well. Two notes:

1. **WSL artefact.** `command -v claude` succeeds and resolves to
   `/mnt/c/Users/Askyla/AppData/Roaming/npm/claude` — the **Windows** Claude Code, leaking into the
   Linux `PATH` through WSL interop. A `--builder claude` run would therefore appear satisfiable
   while actually dispatching a Windows binary against a Linux worktree. `find-harness.sh` does not
   probe for `claude`, so it neither reports nor is fooled by this; the hazard is for an operator
   or agent that checks `command -v claude` by hand. Same class as the `npm` interop leak recorded
   in `evidence/00-environment.md` Blocker 2.
2. **Not a repo defect.** `README.md:180-184` documents installing Codex/agy as a prerequisite.
   Recorded because nothing *fails* until deep into a marathon: `marathon.sh` defaults to
   `--builder codex` with no up-front existence check, so the absence surfaces mid-run rather than
   at parse time.

Log: `evidence/02-deps-probe.log`, `evidence/02-find-harness-check.log`.

---

## F-006 — nvm's node is invisible to non-interactive login shells

**Tag: WSL** (environment gotcha, not a repo defect) · Severity: high friction, blocks everything

```bash
wsl.exe -d Ubuntu -- bash -lc 'command -v node'
```
Exit: **1**, empty output — while `~/.nvm/versions/node/v22.23.2/bin/node` exists and works.

Cause: `nvm install` appends its loader to the **bottom** of `~/.bashrc` (line 119 here). Ubuntu's
stock `~/.bashrc` returns early when the shell is not interactive, at line 8:

```bash
case $- in
    *i*) ;;
      *) return;;
esac
```

`bash -lc` is a **login but non-interactive** shell, so the early return fires and the nvm block
never runs. `npm` then resolves to the Windows `npm` over interop (see F-005), which is worse than
a clean failure — a Windows npm resolving platform-gated dependencies against a Linux filesystem
yields a `node_modules` that breaks later in ways that read as repo bugs.

**This corrects `evidence/00-environment.md`**, which concluded "Every command from here on must be
run through a **login** shell (`wsl.exe -d Ubuntu -- bash -lc '...'`)". That is not sufficient — a
login shell alone does not load nvm. Verified directly: `sed -n "1,12p" ~/.bashrc` shows the guard,
`grep -n nvm ~/.bashrc` shows the loader at 119-121.

Not tagged LINUX because it is a property of nvm + Ubuntu's stock bashrc, not of this repo. It will
however hit **any** Linux user who installs node via nvm and then drives this repo from a
non-interactive shell (CI, cron, an agent harness) — which is the normal case for a marathon.

Fix applied: `evidence/_env/prelude.sh`, sourced by `evidence/_env/run.sh`, resolves the newest
nvm node bindir and prepends it to `PATH`, then asserts the result is not under `/mnt/c/`.
Verification, exit **0**:

```
PRELUDE OK: node=/home/arnoldadero/.nvm/versions/node/v22.23.2/bin/node (v22.23.2)  npm=…/npm (10.9.8)
```

Deliberately **not** fixed by editing `~/.profile`: an explicit per-run prelude keeps the evidence
reproducible instead of depending on hidden dotfile state.

Repro: `repro.sh probe-node-path`.

---

## F-007 — the `relay-xyz` skill is unreachable from a Windows-host / WSL-repo session

**Tag: WSL** · Severity: blocks marathon work until worked around

The guard (F-001) refuses to run any marathon driver until the session proves it loaded the
`relay-xyz` skill. Attempting that:

```
Skill(relay-xyz)  →  Unknown skill: relay-xyz
```

`skills/relay-xyz/install.sh:60-64` symlinks the skill into `$HOME/.claude/skills` and friends —
i.e. the **WSL** home, `/home/arnoldadero/.claude/skills`. But the Claude Code process driving this
session is the **Windows** binary (`claude.exe`, confirmed by `pgrep -a -f claude`), which reads
`C:\Users\Askyla\.claude\skills`. A WSL-side symlink pointing at a Linux path is not resolvable
there, so the documented one-command fix cannot make the skill loadable in this topology.

Squarely **WSL**: on a native Linux box, `bash skills/relay-xyz/install.sh` puts the skill where
that machine's Claude Code reads it and the guard is satisfied normally. Nothing in the repo is
wrong. Recorded because it is invisible until you hit it, and because the repo *is* commonly used
in exactly this Windows+WSL split.

Sanctioned workaround, not a bypass: the guard accepts running the skill's own locator as proof the
skill is being followed (`relay-xyz-guard.sh:91-95`). Per the skill's mandated **Preconditions**
block (`SKILL.md:95-113`) I read `SKILL.md` in full, then ran:

```bash
bash skills/relay-xyz/find-harness.sh --check
```
Exit: **0** — this is the step the skill requires, executed for its documented purpose.

---

## F-008 — a builder installed with nvm's `npm -g` is invisible to the harness

**Tag: LINUX** · Severity: high — silently makes marathon unrunnable while looking installed

Discovered by `repro.sh probe-builders`, not by reading. `codex` was installed successfully:

```bash
npm install -g @openai/codex
```
Exit: **0** (`evidence/04-codex-install.log`), binary at
`/home/arnoldadero/.nvm/versions/node/v22.23.2/bin/codex`, `codex --version` → `codex-cli 0.148.0`.

But from a non-interactive login shell — which is what every marathon turn runs in:

```
--- bare PATH (what a non-interactive marathon turn actually sees):
codex : <missing>
--- with prelude sourced:
codex : /home/arnoldadero/.nvm/versions/node/v22.23.2/bin/codex
```

And the harness's own readiness probe agrees it is absent:

```
--  codex CLI (Path A worker)  (not found)
!   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available
```

**This is F-006's consequence, and it is worse than F-006 itself.** `npm install -g` under nvm
installs into the nvm version's bindir — precisely the directory a non-interactive shell cannot
see. So the operator installs the builder, sees exit 0, sees a working `codex --version` in their
*interactive* terminal, and the marathon still cannot find it. The two observations disagree and
nothing explains why.

Compounding it: `marathon.sh` defaults `--builder codex` (`:90`) with **no up-front existence
check**, so the failure does not surface at plan-parse time — it surfaces mid-run, after the phase
directory, relay file and tick token have already been created.

Tagged LINUX, not WSL: nothing here involves WSL. Any Linux user who manages Node with nvm — the
most common way — and installs a builder with `npm -g` will hit it identically.

Repo-side improvement this suggests (not a fix I made — evidence gathering, not redesign):
`find-harness.sh --check` already knows the builder is missing; it could additionally probe common
install locations and say "installed at X but not on PATH" instead of a bare "not found".

Mitigation used here: `evidence/_env/run.sh` sources `evidence/_env/prelude.sh`, which puts the nvm
bindir on `PATH` before invoking anything, so every marathon in this bring-up runs with `codex`
genuinely resolvable. Verified: `repro.sh probe-builders` exit **0**.

---

## F-009 — `issue-doc-sync` reports "gh absent/offline" when gh is present, authenticated, and working

**Tag: LINUX** (OS-independent; hits anyone working from a fork) · Severity: low (warn-only) but
the message actively misdirects

Seen 19 times in the baseline run (`evidence/02-validate-sequential.log`):

```
WARN [pdda-check-issue-doc-sync] PROJECT/2-WORKING/GH-544-LOCAL-GATE-BEFORE-PUSH.md:1
  issue #544 state unavailable (gh absent/offline and no cached state) — sync NOT evaluated;
  run: utils/pdda/pdda.sh gh-refresh
SUMMARY [pdda-check-issue-doc-sync] errors=0 warns=19 info=0
```

Every clause of the diagnosis is false. `gh` is installed and authenticated:

```bash
command -v gh          # /usr/bin/gh          (gh version 2.97.0)
gh auth status         # ✓ Logged in to github.com account arnoldadero
```
Exit: **0**, token scopes `gist, read:org, repo, workflow`.

The real cause:

```bash
gh repo set-default --view
# X No default remote repository has been set.

gh issue view 544 --json number,state
# GraphQL: Could not resolve to an issue or pull request with the number of 544. (repository.issue)
```

`origin` on this clone is the **fork**, `https://github.com/arnoldadero/XYZ-forge.git`; the issues
live upstream in `HiQS-Suite/XYZ-forge`. With no default repo set, `gh` resolves against the fork,
which has no issue #544 — so the lookup legitimately fails, and the check reports that failure as
"gh absent/offline".

Two consequences:

1. **The suggested remedy cannot work.** The warning tells the operator to run
   `utils/pdda/pdda.sh gh-refresh`. That refreshes the cache using the same `gh` resolution, so it
   fails identically and the warning persists — a loop with no exit.
2. **It will silently degrade `marathon-triage`.** That skill classifies every candidate against
   live issue state and, per `skills/marathon-triage/SKILL.md:78`, assigns `UNKNOWN` when GitHub is
   unavailable — and `UNKNOWN` items are excluded from the queue. On a fork, that is every item.
   The skill behaves correctly given its input; the input is wrong for a reason nothing surfaces.

The correct fix for an operator is `gh repo set-default HiQS-Suite/XYZ-forge`, which is not
mentioned anywhere in the warning or in `ROUTER.md`'s PDDA section.

Distinguishing "the tool is missing" from "the tool ran and returned not-found" is a two-branch
change in the check; conflating them is what makes this misleading rather than merely terse.

Not a blocker for this bring-up: warn-only, `errors=0`, suite still green.

---

## Phase 3 baseline result

```bash
./validate.sh --sequential
```
Exit: **1** · duration **1387s (23m07s)** · `passed: 216 / 230` (`evidence/02-validate-sequential.log:6167`)

> **Note on the exit code.** The background-task notification reported "exit code 0". That was the
> exit status of the `| tail -80` pipeline, not of `validate.sh`. The runner's recorded
> `EXIT_CODE: 1` is the true one — this is exactly the trap `evidence/_env/run.sh` uses
> `PIPESTATUS[0]` to avoid, and it is worth stating because a pipeline-masked exit code is how a
> red suite gets reported as green.

**Duration note (not a defect).** `ROUTER.md` budgets `--sequential` at ~16 min; this host took
23 min on 4 cores. The README's measurement provenance is a 32 GB M1 Max. Sizing expectation, not
a failure.

The 14 failing suites triage to **five** root causes, four of them environmental prerequisites the
docs do not state:

| Failing suite | Root cause | Finding |
|---|---|---|
| `gh32-releases-app`, `gh53-releases-merge-resolve`, `gh54-merged-dump-refusals`, `gh57-releases-fuzz`, `gh57-live-merge-resolve`, `gh69-roadmap-shadow` | `sqlite3` not installed | F-010 |
| `gh77-standup-triage` | `jq` not installed | F-011 |
| `gh399-packet-acceptance-continuation` | no global git identity | F-012 |
| `gh35-test-tiers` | Linux `nice` ceiling is 19, test wants 20 | F-013 |
| `relay-self-sufficiency`, `relay-file-seeding-visibility`, `archive-writers`, `gh382-marathon-memory-telemetry`, `python:test_python_layer.py` | not yet isolated / contaminated | F-014 |

---

## F-010 — the releases suite needs `sqlite3`, which the README does not list

**Tag: DOC** · Severity: medium — 6 of the 14 failures

```
evidence/02-validate-sequential.log:3814
/home/arnoldadero/XYZ-forge/test/gh53-releases-merge-resolve.sh: line 108: sqlite3: command not found
:3815  FAIL: expected 2 releases after merging one from each side, got  — a side was dropped
```

`README.md:180-184` lists prerequisites as Codex CLI, agy CLI, **Node 18+ and git**, and
**Python 3.8+**. `sqlite3` is not among them. Stock Ubuntu 24.04 does not ship the `sqlite3` CLI.

The confusing part is that `releases.db` work *mostly* works without it: `ROUTER.md` routes
releases operations through `python3 utils/py/releases_app.py`, and Python's built-in `sqlite3`
module is present (`evidence/02-deps-probe.log`). So the documented path works while six test
suites fail — a discrepancy with no visible explanation unless you read the test source.

Six suites fail as a group: `gh32-releases-app`, `gh53-releases-merge-resolve`,
`gh54-merged-dump-refusals`, `gh57-releases-fuzz`, `gh57-live-merge-resolve`, `gh69-roadmap-shadow`.

Fix: `sudo apt-get install -y sqlite3`. Not applied by me — `sudo` requires a password on this host
(`sudo -n true` → "a password is required").

---

## F-011 — `standup/collect.sh` hard-requires `jq`, undocumented

**Tag: DOC** · Severity: medium — 1 suite, ~40 assertions

```
evidence/02-validate-sequential.log:3878
collect.sh: jq is required and was not found on PATH — every lens degraded (D5).
```

Every subsequent assertion in `gh77-standup-triage` then fails with `got ''` — the lenses produce
nothing, so ~40 assertions fail from one missing binary. To its credit the tool **degrades loudly
and says exactly why**, which is the right behaviour; the gap is only that `jq` is not in the
README's prerequisite list.

Worth contrasting with `relay-xyz-guard.sh:43-71`, which needs the same parsing and handles absence
properly — jq fast path, `python3` fallback, fail-open. `collect.sh` hard-fails instead. The repo
therefore contains both a graceful and a hard dependency on jq, with only the graceful one
documented as optional.

Fix: `sudo apt-get install -y jq`. Not applied — see F-010 on sudo.

---

## F-012 — the suite requires a GLOBAL git identity, and nothing says so

**Tag: LINUX** (a macOS-workstation assumption) · Severity: medium

```
evidence/02-validate-sequential.log:1866
FAIL: C4 no relay file produced (marathon-drive rc=1):
subprocess.CalledProcessError: Command '['git','-C','/tmp/gh399-continuation.FtK2dc/wrapped',
  'commit','-q','-m','marathon: render phase gh399 relay (gh399-test)']' returned non-zero exit status 128
```

Exit 128 from `git commit` is the "who are you?" error. Confirmed by direct probe
(`evidence/03-probe-git-identity.log`, before-fix):

```
global user.email : <UNSET>
global user.name  : <UNSET>
git commit exit: 128
    Author identity unknown
    *** Please tell me who you are.
    fatal: empty ident name (for <arnoldadero@DESKTOP-NVQQIAE.>) not allowed
```

Many suites `git init` a scratch repo under `mktemp -d` and commit into it. Those scratch repos
inherit only **global** config, so with no global identity every such commit fails 128 — and the
suite reports the downstream symptom ("no relay file produced") rather than the cause.

This is a macOS-assumption in the classic sense: any machine that has ever committed has a global
identity, so it is invisible to the maintainers and guaranteed on a fresh Linux box or container.

**Fix applied**, then verified (`evidence/03-probe-git-identity-after.log`, exit **0**):

```bash
git config --global user.email "arnold.adero@gmail.com"
git config --global user.name  "Askyla"
# probe: git commit exit: 0 — RESULT: commit succeeded
```

Repo-side improvement this suggests: the scratch-repo helper could set a local identity
(`git -C "$d" config user.email test@example.invalid`) so the suite is independent of operator
config — one line, and the whole class disappears.

---

## F-013 — `gh35-test-tiers` asserts `nice` 20, which Linux cannot reach

**Tag: LINUX** · Severity: medium — a genuine, unfixable-by-config platform difference

```
evidence/02-validate-sequential.log:3132
FAIL: the suite worker ran 10 below its caller (caller nice=10, worker nice=19, wanted 20)
```

Linux's nice range is **−20..19**. BSD/macOS is **−20..20**. `validate.sh` runs workers under
`nice -n 10` (GH-35, `ROUTER.md` "Command rails"); when the caller is itself at nice 10, a further
`nice -n 10` should reach 20 — and does on macOS, but Linux clamps to 19.

Probed directly:

```bash
nice -n 10 sh -c "nice -n 10 nice"   # -> 19   (macOS would print 20)
nice -n 19 sh -c "nice"              # -> 19
```

So the assertion is **unreachable on Linux by construction**. It is not a misconfiguration and no
amount of environment fixing will satisfy it — the test encodes a BSD niceness ceiling.

This is the single most clearly "would hit any Linux user" finding in this run: the repo's own gate
cannot go green on Linux until this expectation is relaxed to `min(caller + 10, 19)` or the
assertion is made platform-aware.

Also visible in that section, harmless but noisy: `your 131072x1 screen size is bogus. expect
trouble` — a WSL TTY artefact, not related.

---

## F-014 — METHODOLOGY: I contaminated the baseline by installing Codex mid-run

**Tag: n/a — this is my error, recorded so the evidence is not over-trusted**

The baseline started 13:54:15 and ended 14:17:33. I installed the Codex CLI at 14:04:00–14:04:31,
**inside that window**. The log then shows, from line 6119:

```
2026-08-20T11:17:08Z ERROR codex_api::endpoint::responses_websocket:
  failed to connect to websocket: HTTP error: 401 Unauthorized, url: wss://api.openai.com/v1/responses
```

(11:17 UTC = 14:17 EAT.) A `codex` binary that was **absent** when the run started became
**present but unauthenticated** partway through. Suites that branch on "is a worker on PATH" would
have taken the skip path early and the attempt path late.

The five unexplained failures in the table above — `relay-self-sufficiency`,
`relay-file-seeding-visibility`, `archive-writers` (*"consult (unset) exited non-zero"*),
`gh382-marathon-memory-telemetry`, `python:test_python_layer.py` — are exactly the ones plausibly
touched by a half-present builder. **I am not claiming they are environmental, and I am not
claiming they are real defects. They are not yet isolated.**

Correct course, per the brief's "re-run sequentially after the last fix and capture a clean log":
apply the F-010/F-011/F-012 fixes, ensure `codex` is in a stable state (installed AND
authenticated), then re-run `--sequential` untouched from start to finish. Only that second log is
baseline evidence. This first one is retained because its per-suite failures are still what
diagnosed F-010 through F-013, all four of which are independently reproduced by direct probe
rather than by the contaminated run.

Lesson worth keeping: never mutate the environment while the source-of-truth run is in flight,
even with a change that looks unrelated.

---

## F-015 — agy 1.1.16 removed `whoami`; the auth preflight then hard-blocks the whole agy lane

**Tag: LINUX** · Severity: **critical** — makes `--builder agy` unusable · **FIXED** (`a4706d1`)

`relay-automation/agy-turn.sh:147` (and the authoritative `utils/py/agy-turn.py`) gate every agy turn
behind `agy_auth_preflight`, which runs `agy whoami`. On agy **1.1.16** that subcommand does not
exist:

```bash
agy --help </dev/null
```
Exit: **0**. Subcommands: `agent agents changelog help install mcp models plugin plugins update`.
No `whoami`. **And no `login`** — which is the remedy every failure path in this file tells the
operator to run.

The argument therefore falls through to agy's **interactive TUI**, which writes its terminal-takeover
escape sequence and blocks. It also ignores SIGTERM:

```bash
timeout 8 agy whoami </dev/null      # rc=137, elapsed 248s
timeout -s KILL 8 agy whoami </dev/null   # rc=137, elapsed 8s
```
Measured twice from the process table: `timeout 30 agy whoami` was still alive at **6m43s**;
`timeout 8 agy whoami` at **2m26s**. Only SIGKILL ends it. (`rtl_run_bounded` uses `kill -9`, so the
harness itself does not hang — but every naive `timeout` caller does.)

The capture at timeout is therefore **escape codes and no prose**:

```
\e[?2026$p\e[?2027$p\e[>4m\e[=0;1u\e[?1049h\e[?25l\e[?5W\e[?2004h\e[>4;2m\e[=1;1u\e[?u\e[H\e[2J
```

`rtl.agy_auth_timeout_verdict` matched TTY failures by **prose** only
(`AGY_AUTH_TTY_MARKERS = ("could not open tty", "error opening tty")`), so it read that as "timed out
with no TTY diagnostic" → `failed` → lane blocked. Measured against the authoritative Python path
(`evidence/marathons/run-1/00e-agy-preflight-verdict.log`):

| `AGY_AUTH_TIMEOUT_S` | `agy_auth_preflight()` | verdict |
|---|---|---|
| 5  | `False` | BLOCKED (exit 5) |
| 15 | `False` | BLOCKED (exit 5) |
| 30 | `False` | BLOCKED (exit 5) |

**Raising the timeout does not help** — the probe can never complete. Meanwhile the lane demonstrably
works (`evidence/marathons/run-1/00c-agy-live-probe.log`):

```
agy -p "Reply with exactly: MARATHON-PROBE-OK"   -> rc=0, 14s, "MARATHON-PROBE-OK"
agy models                                        -> rc=0, 7.6-8.5s, real model list from the backend
```

So this is the **third** arrival of the false-block direction that GH-375 and its follow-up were both
written to prevent — reaching it through a new spelling rather than a new branch.

**Fix applied** (`fix/agy-tui-takeover-auth-verdict`, merged to `linux-bringup`): treat a **mute**
terminal takeover as positive evidence of the TTY cause. The follow-up's rule is preserved verbatim —
reclassify ONLY on positive evidence — because a terminal takeover *is* that evidence, written in
control codes rather than English. The second half of the predicate keeps the fatal cases fatal: the
capture must also carry nothing readable after escape-stripping, so a device-code login prompt (which
has readable text) still blocks, and silence still blocks. Also adds `"error entering raw mode"` to
`AGY_AUTH_TTY_MARKERS` — the same TTY failure in 1.1.16's wording.

Verified:

| Check | Result |
|---|---|
| `test/agy-tui-takeover-verdict.sh` (new, includes a pre-fix replay) | 8 pass / 0 fail |
| `test/gh375-auth-timeout-verdict.sh` | 14 pass / 0 fail — no regression |
| `test/gh375-agy-auth-preflight.sh` | pass — no regression |
| live `agy_auth_preflight()` at 5s / 15s / 30s | `False` → **`True`** |
| live marathon run 1 | `agy-turn: NOTE — agy auth is unverifiable headless (expected); proceeding` |

**Not fixed, deliberately:** the preflight still burns its full timeout (default 20s) on every agy
turn, because `agy whoami` can never complete. That is a cost question, not a correctness one, and
choosing a replacement probe is a maintainer's design decision — `agy models` is a real candidate at
rc=0 in ~8s, but `AGY_AUTH_TIMEOUT_DEFAULT_S` would have to rise from 20s only if it were used, and
GH-492 criterion 4 explicitly prefers recording the finding over shipping a weaker probe.

Repro: `repro.sh probe-agy-auth`.

---

## F-016 — `swarm-preflight` reports `agy=present` from a bare `command -v`, disagreeing with `find-harness.sh`

**Tag: LINUX** · Severity: low (advisory line only) but it is a readiness signal that can read green
while the lane is dead

`utils/swarm-preflight.sh:780`:

```bash
GH39_LANE_NOTE="codex=$(command -v codex >/dev/null 2>&1 && echo present || echo absent) agy=$(command -v agy >/dev/null 2>&1 && echo present || echo absent)"
```

A bare `command -v` establishes only that a file is on `PATH`. It says nothing about whether the
binary runs, is authenticated, or — as F-015 shows — whether the harness's own preflight will refuse
the lane. During this bring-up `swarm-preflight` printed `lane-cli : codex=present agy=present` in
the same minute that `agy-turn.py`'s preflight returned `False` at every timeout tried.

`skills/relay-xyz/find-harness.sh` is the better-behaved sibling: it resolves through `AGY_BIN`, falls
back to the well-known `~/.local/bin/agy` location (`:192-196`), and reports a clear
`-- agy CLI (Path A worker) (not found)`. The two tools answered differently about the same machine
within one run — earlier, before agy was installed, `find-harness.sh` said not-found while a bare
`command -v` in a different shell said present, purely because of PATH differences between the
prelude-sourced and non-prelude shells.

Not a blocker; recorded because "lane-cli: agy=present" is exactly the line an operator would scan to
decide whether a lane is safe to fire.

Log: `evidence/marathons/run-1/02-preflight.log`, `evidence/marathons/run-1/00-guard-proof.log`.

---

## F-017 — `marathon.sh --plan` is checked against the process CWD, not `--target-root`, contradicting its own help

**Tag: LINUX** · Severity: medium — a documented invocation fails with a misleading error

```bash
relay-automation/marathon.sh \
  --plan PROJECT/2-WORKING/RUN1-LEDGER-EXPORTS/MARATHON.yaml \
  --target-root "$HOME/marathon-target" --builder agy --dry-run
```
Exit: **2** · `marathon: plan not found: PROJECT/2-WORKING/RUN1-LEDGER-EXPORTS/MARATHON.yaml`

The plan exists at exactly that path **inside the target root**, and `marathon.sh`'s own help
(`:96`) states:

> `Plan and brief paths resolve against DIR when set.`

The cause is an ordering bug, visible in the source:

```
relay-automation/marathon.sh:136   [[ -f "$PLAN" ]] || die "plan not found: $PLAN"
relay-automation/marathon.sh:155   _plan_base="${TARGET_ROOT:-$ROOT}"
```

The existence check runs **19 lines before** the base it is documented to resolve against is
computed. `_plan_base` is used for the GH-212 location *policy* check, but by then the file has
already had to exist relative to the process CWD. The brief path has the same shape at `:271`
(`brief_base="${TARGET_ROOT:-$ROOT}"`), which is computed later still.

The error message compounds it: "plan not found: <relative path>" gives no hint that the path was
resolved against a different root than the flag implies.

Workaround: pass `--plan` as an absolute path. Verified — the same invocation with an absolute plan
path reached `marathon: dry-run complete: 4 phase(s) would run in order`, exit **0**
(`evidence/marathons/run-1/03-dryrun.log`).

Repro: `repro.sh probe-plan-resolution`.

---

## F-018 — `--target-root` is recommended for exactly the case `relay-drive` then refuses

**Tag: DOC** · Severity: **high** — the documented remedy for a gitignoring target cannot run a build turn

`marathon.sh`'s `--target-root` help says, verbatim:

> Use this when the target repo cannot track harness output (e.g. a public repo that gitignores
> `marathon-system/` and `relay-system/` on purpose): without it, marathon-drive's `git add` of
> RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.

That described this bring-up's target repo exactly — its `.gitignore` carried `marathon-system/` and
`relay-system/`. So `--target-root` was used, as documented. The run then halted on phase 1:

```bash
relay-automation/marathon.sh --plan <abs>/MARATHON.yaml --target-root "$HOME/marathon-target" \
  --builder agy --pre-advance-cmd "npm test"
```
Exit: **2** (marathon-drive exit 2) · elapsed 2s · no builder turn spent

```
relay-drive: --target-root build turn cannot report: relay file
  '<harness>/marathon-system/run1-ledger-exports--r1p1/RELAY.md' resolves outside the target root
  '/home/arnoldadero/marathon-target', so a build turn (ALLOW_PATHS="") has no writable path for its
  findings and the turn would be discarded after full cost. Vendor the harness into the target repo
  (relay-automation/xyz-vendor.sh '/home/arnoldadero/marathon-target') and drop --target-root, or
  move the relay thread under the target root.
```

Both statements are individually correct and they contradict each other. `--target-root` keeps the
relay thread in the harness repo *by design* (the help says so in its second sentence), and that is
precisely what makes a build turn unable to report.

**Credit where due — the refusal is exemplary.** It fires before any builder turn is spent, states
the cause in one sentence, and names two concrete remedies. `marathon: HALT: phase r1p1 failed
(marathon-drive exit 2) — chain stops; later phases NOT started` behaved exactly as documented. The
defect is the help text promising a combination the driver rejects, not the driver.

Resolution used (the first remedy it names): `relay-automation/xyz-vendor.sh <target>` (exit **0**),
drop `--target-root`, un-ignore `marathon-system/` and `relay-system/` in the target, and invoke
`.xyz/relay-automation/marathon.sh` from the target root. That path works —
`evidence/marathons/run-1/04-fullrun.log`.

Note the second-order consequence the help does not mention: taking the remedy means the target repo
must now **track** `marathon-system/` and `relay-system/`, which is the exact thing the help offered
`--target-root` to avoid. For a genuinely public repo that gitignores harness output on purpose,
neither branch of the advice is available.

Logs: `evidence/marathons/run-1/04-fullrun-take1-halt.log`, `evidence/marathons/run-1/04b-vendor-target.log`.

---

## F-019 — `artifacts_new` is mandatory for greenfield lanes and absent from the example the error points at

**Tag: DOC** · Severity: medium — a hard exit-3 whose named remedy does not contain the answer

A contract listing not-yet-existing files in `artifacts[]` fails readiness:

```bash
utils/swarm-preflight.sh --project-doc <doc> --target-root <target> --dry-run
```
Exit: **5** · `readiness : ready=0 — next: artifact path not found at target.ref: src/export-csv.js
— fix the contract artifacts[] or push the file`

The correct field is `artifacts_new` (GH-89) — a **subset marker over** `artifacts[]`, exempting those
paths from the GH-39 A2 existence check, gated on a matching `fix_probes` `path_absent` entry. Getting
there took two more failed attempts, each a separate exit code:

1. `artifacts_new` as a **parallel** list (not also in `artifacts[]`) → exit **3**,
   `artifacts_new entry not present in artifacts[]: src/export-csv.js`
2. Only then does the subset relationship become apparent — from the source, not the docs.

The exit-3 message says:

> To fix, add a minimal valid contract in <doc> (copy `relay-automation/CONTRACT.example.md` for a
> detailed example)

```bash
grep -q 'artifacts_new' relay-automation/CONTRACT.example.md
```
Exit: **1** — the field appears **nowhere** in the file the error tells you to copy. Nor in
`README.md`, `ROUTER.md`, `AGENTS.md`, or anywhere under `relay-automation/`. Outside PROJECT capture
docs and the CHANGELOG, the only prose mention in the repo is one line in
`skills/marathon-triage/SKILL.md:93`, which references the field without defining it.

So a first-time operator building anything greenfield — which is the normal case for a marathon —
hits a hard exit 3 and is pointed at a document that cannot resolve it. The semantics are recoverable
only by reading `utils/swarm-preflight.sh:181-190` and `:228-243`.

Repro: `repro.sh probe-artifacts-new-doc`.

---

## F-020 — the agent's Bash tool is sandboxed; the GH-177 guard blocks every suite run until it is disabled

**Tag: WSL** (agent-harness artefact, not a repo defect) · Severity: high friction

The brief asks explicitly whether this shell is sandboxed. **It is.** Any attempt to run a test:

```bash
bash test/agy-tui-takeover-verdict.sh
```
is intercepted before execution by `relay-automation/hooks/gh177-sandbox-test-guard.sh`:

```
GH-177 guard: refusing to run the test suite under a SANDBOXED Bash call.
Sandbox-broken mktemp fed the destructive EXIT trap that wiped this repo twice
(see PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md).
```

This is the repo protecting itself correctly, and it is the good outcome: the guard converts the
failure mode the brief warned about — "prints nothing for minutes and then fails, and it looks exactly
like a hang" — into an immediate, explanatory refusal. Every test and marathon invocation in this
bring-up therefore ran with the sandbox explicitly disabled, which is the second option the guard
itself offers.

Worth stating plainly for anyone reproducing this: `mktemp -d` works fine *inside* WSL
(`evidence/00-environment.md` proved it, exit 0). The sandbox is imposed by the **agent harness**
around the Bash tool, not by WSL, and the two are easy to confuse.

---

## F-021 — a background-task notification reported exit 0 for a run whose real exit was 2

**Tag: WSL** (agent-harness artefact) · Severity: medium — this is how a red run gets reported green

The run-1 take-1 marathon halted:

```
marathon: HALT: phase r1p1 failed (marathon-drive exit 2) — chain stops; later phases NOT started
MARATHON_FULLRUN_RC=2
EXIT_CODE: 2
```

The agent harness's completion notification for that same background task read
`completed (exit code 0)`.

`evidence/_env/run.sh` records the truth because it takes `PIPESTATUS[0]` rather than the pipeline's
status — the same trap already recorded in F-014, arriving from a different direction. Recorded again
because it fired twice in this bring-up on two different mechanisms, and because "the notification
said it passed" is not evidence. Only the logged `EXIT_CODE:` trailer is.

---

## F-022 — the compute/ranking step cannot run in a vendored repo at all

**Tag: LINUX** · Severity: medium — the lifecycle's first step is unavailable in the documented
deployment shape

```bash
cd ~/marathon-target && bash .xyz/utils/marathon-plan.sh --check
```
Exit: **3** · `ROADMAP not found: /home/arnoldadero/marathon-target/ROADMAP.md`

`utils/marathon-plan.sh` is the planner/ranker — the nearest thing this repo has to the brief's
"compute" step (F-002). It reads the **harness's own PDDA `ROADMAP.md` ledger**, scores it into waves,
and writes `PROJECT/2-WORKING/MARATHON-PLAN-<date>.md`. A consuming repo has no such ledger.

That matters because a vendored install is not an edge case — it is what `relay-automation/xyz-vendor.sh`
creates, what `README.md`'s "`marathon.sh` roots" section documents
(`cd /path/to/target-repo && ./.xyz/relay-automation/marathon.sh ...`), and — per **F-018** — the only
configuration in which a build turn can report at all. So in the one deployment shape that actually
works end to end, the ranking step does not run.

The same command in the harness repo works as designed:

```bash
cd ~/XYZ-forge && bash utils/marathon-plan.sh --check
```
Exit: **4** (drift present) · `SUMMARY [marathon-plan] items=22 active=0 waves=0 drift=true held=11`
— a real ranking pass with per-item held reasons.

Not a blocker for a hand-written plan: preflight and dry-run are the steps that gate a fire, and both
work fine vendored. Recorded because an operator following the lifecycle in order will hit exit 3 on
step one and have no way to tell whether they mis-configured something or the step simply does not
apply to them. Nothing in the output says "this step is harness-only".

Log: `evidence/marathons/run-2/01-03-compute-preflight-dryrun.log`.

---

## F-023 — the GH-68 drift detector fires on every path that exists at neither rev

**Tag: LINUX** · Severity: medium — warn-only, but it pollutes **every** agent turn brief and buries
the real signal

`relay-automation/relay-turn-lib.sh:1350-1353` watches a hardcoded list of shared surfaces:

```bash
for _surf in relay-automation/relay-turn-lib.sh src/project.js src/events.js; do
  _psha="$(git -C "$RTL_ROOT" rev-parse "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
  _csha="$(git -C "$RTL_ROOT" rev-parse "$_newhead:$_surf"        2>/dev/null || true)"
  [[ "$_psha" == "$_csha" ]] && continue   # unchanged (or absent at both revs) — no drift
```

The comment states the intended behaviour for a path absent at both revisions. That is exactly the case
it gets wrong.

**Why.** `git rev-parse <sha>:<missing-path>` exits 128 **but echoes its argument back on stdout** —
the standard rev-parse fallback for an unresolvable argument. Measured directly
(`evidence/07-drift-probe.log`):

```
--- src/project.js ---            (exists in worktree: NO)
  _psha=[3daa280311ae05710b24daf2d65af5b907c981b6:src/project.js]
  _csha=[a7222a5de42d20a6aa177691c17e2912de6418ac:src/project.js]
  => DIFFERENT -> drift WOULD be emitted
  raw rev-parse: rc=128 stdout=[3daa280...:src/project.js]

--- src/parse.js ---              (exists in worktree: yes)
  _psha=[ceadf4b6621a4d9b36d7ae6bcdacef1ee075800f]
  _csha=[ceadf4b6621a4d9b36d7ae6bcdacef1ee075800f]
  => equal -> continue (NO drift emitted)
```

The two echoed strings differ because the SHA prefixes differ, so the `continue` guard never fires and
drift is emitted with `--diff-lines 0`. The `(0 lines)` in the operator output is the tell: a genuine
drift always has a non-zero diff.

**Blast radius.** In this bring-up's target repo none of the three watched paths exists — the vendored
harness lives at `.xyz/relay-automation/relay-turn-lib.sh`, and `src/project.js` / `src/events.js` are
xyz's own files that no consuming repo has. So **all three fire on every commit**:

```
marathon-drive log, per turn:
  agy-turn: dependency.drift — agy changed relay-automation/relay-turn-lib.sh (0 lines); signalled for the next turn
  agy-turn: dependency.drift — agy changed src/project.js (0 lines); signalled for the next turn
  agy-turn: dependency.drift — agy changed src/events.js (0 lines); signalled for the next turn
```

**42 `dependency.drift` events in a single four-phase run**, every one false.

This is not merely log noise. GH-68's entire purpose is to inject the notice into the **next agent's
turn brief**, and it does — captured live from the process table during run 1:

```
agy --dangerously-skip-permissions --print-timeout 900s -p [cross-agent dependency drift —
informational, warn-only; re-...
```

So every builder and reviewer turn after the first opens with a heads-up about three files that do not
exist in the repository it is working on. In a vendored install — again, the deployment shape that
actually works — the signal is **100% false positives by construction**, which means a real drift event
would be indistinguishable from the noise it arrives in.

**Suggested fix** (not applied — evidence gathering, not redesign; and changing it mid-bring-up would
make run 3's transcripts inconsistent with runs 1 and 2):

```diff
-  _psha="$(git -C "$RTL_ROOT" rev-parse "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
-  _csha="$(git -C "$RTL_ROOT" rev-parse "$_newhead:$_surf"        2>/dev/null || true)"
+  _psha="$(git -C "$RTL_ROOT" rev-parse --verify --quiet "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
+  _csha="$(git -C "$RTL_ROOT" rev-parse --verify --quiet "$_newhead:$_surf"        2>/dev/null || true)"
```

`--verify --quiet` suppresses the echo-back, so an absent path yields `""` at both revs and the existing
`continue` guard works as its comment already promises. One flag pair, no logic change.

Worth noting separately: the watch list is **hardcoded to xyz's own filenames**
(`src/project.js`, `src/events.js`). `utils/marathon-plan.sh` already solved this general problem — it
takes a repo-specific zone model via `--zones-config` / `QUEUE_PLAN_ZONES_FILE` precisely so foreign
repos are not matched against xyz's filenames. The drift watcher has the same need and no such lever.

Repro: `repro.sh probe-drift-false-positive`.

---

## F-024 — a builder quota limit is reported to the operator as an auth failure, with an impossible remedy

**Tag: LINUX** · Severity: **high** — the operator is pointed at a non-existent command while the real
cause is a limit that resets in seven days

### What happened

Runs 1 and 2 (8 phases, ~30 turns) consumed the agy individual quota. Run 3's first builder turn then
failed:

```
agy-turn: agy -p failed (exit 1)
agy-turn: auth was NEVER VERIFIED for this turn, and the turn failed — agy could not run headless,
  so auth was not verified: CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY:
  open /dev/tty: no such device or address
agy-turn: No reliable headless auth probe for agy exists (GH-375); `agy -p` is the only honest test
  and it IS the turn. If this turn fails on credentials, run `agy login` in a real terminal.
marathon-drive: relay escalated: relay-failed-before-gate (gate: not-run)
marathon: HALT: phase r3p1 failed (marathon-drive exit 5) — chain stops; later phases NOT started
```

marathon-drive exit **5**, reason `relay-failed-before-gate`, gate `not-run`, 0 rounds.

### The actual cause

Probed directly, three consecutive attempts (`evidence/marathons/run-3/02-agy-p-retest.log`):

```
attempt 1: rc=1  15s  Error: Individual quota reached. Please upgrade your subscription to
                      increase your limits. Resets in 166h55m7s.
attempt 2: rc=1  15s  (same)
attempt 3: rc=1  15s  (same)
```

Nothing to do with a TTY. Nothing to do with auth. The account is authenticated and simply out of
quota for another ~7 days.

### Why it presents as a TTY error

agy renders the quota message through its interactive TUI. Under worktree isolation the turn has no
openable `/dev/tty`, so bubbletea fails first and its TTY error is the only thing that reaches the
shim. Three layers sit between the operator and the truth:

```
quota exhausted  ->  TUI cannot open /dev/tty  ->  shim reports "auth was never verified"
                                               ->  printed remedy: `agy login`
```

`agy login` is **not a subcommand of agy 1.1.16** (F-015). So an operator following the printed advice
runs a command that does not exist, learns nothing, and has no reason to suspect a quota window.

Note this is a *different* failure from F-015 with a *similar* signature, which makes it harder, not
easier: F-015 is `whoami` hanging during the pre-flight; F-024 is `agy -p` — the real turn — failing
after the pre-flight already waved it through.

### What the harness got right

Worth stating, because the design is doing real work here:

- It refused to advance: `gate: not-run`. It did not run the gate against an unbuilt artifact.
- It halted the chain and did not start r3p2–r3p4, exactly as `marathon.sh:4-8` documents.
- It wrote `ESCALATION.md` carrying the relay-drive exit code and reason.
- It saved a transcript anyway, so the failed turn is inspectable.
- It said "auth was **NEVER VERIFIED**" rather than "auth is bad" — the GH-492 hedge is correct. The
  defect is the layer above, which converts a correctly-hedged observation into a confident wrong
  remedy.

### Suggested resolution

Match agy's own error text before attributing anything to auth. `Individual quota reached` /
`upgrade your subscription` / `Resets in` are stable, greppable strings, and they are present in the
turn's captured output whenever the TUI manages to emit anything at all. A quota failure should
surface as "builder out of quota, resets in X" — a completely different operator action from
re-authenticating.

### Consequence for F-015

F-015's write-up floated `agy models` as a candidate replacement auth probe (rc=0 in ~8s). **That
suggestion is withdrawn.** Measured during this failure, `agy models` also returns **rc=1** under
quota exhaustion, so it would report "not authenticated" for an account that is authenticated and
merely out of quota — swapping one misdiagnosis for another.

Full record: `evidence/marathons/run-3/3a-agy-quota-halt/`.

---

## F-025 — cost telemetry records nothing for the agy and codex lanes

**Tag: LINUX** · Severity: medium — the run's own cost report cannot answer "what did this cost?"

Every marathon ends with a cost summary. After a complete four-phase run:

```
marathon-drive: end-of-run cost summary (tick analyze) —
--- cost ---
run type: unspecified
tokens: ≥0 total (≥0 in / ≥0 out) — PARTIAL, floor only: 0/8 done-tasks instrumented
human minutes (self-reported): 0
wall-clock (run window): 42m 36s
per done-task: ≥0 tokens, 5m 19s wall-clock
memory: swap free min: 8192MB
  turn peak RSS: agy: 197MB peak RSS, codex: 289MB peak RSS
```

**`0/8 done-tasks instrumented`** — eight completed tasks, zero token records. The summary is honest
about it (`≥0`, `PARTIAL, floor only`), which is the right way to report missing data, but the
practical result is that a completed campaign cannot report its own spend.

What *is* captured and useful: wall-clock per done-task, and peak RSS per agent — the latter is
genuinely good data (agy 197 MB, codex 289 MB) and directly answers the sizing question in
`evidence/00-environment.md`.

This appears to be known rather than broken: `relay-automation/README.md:29` describes the Pi lane as
*"the first non-Claude lane with actual `tick cost --tool pi` capture"*, implying agy and codex have
none. Recorded because the gap is invisible until a run finishes and the summary reads `≥0`, and
because "report the spend" is a normal thing to ask of a long-horizon campaign.

Workable substitute, used in this bring-up: turn counts from the commit log
(`git log --oneline | grep -oE 'relay\(MARATHON-R[0-9]P[0-9]-TURN\): (agy|codex)'`) plus wall clock,
plus the builders' own quota state.

---

## F-026 — the claude builder lane can never have a trusted workspace

**Tag: LINUX** · Severity: low (warn-only, turn still proceeds) but it silently drops project permissions

With `--builder claude` and `RELAY_WORKTREE_ISOLATION=1` (the default for marathon turns), every turn
runs in a fresh throwaway worktree with a random name:

```
claude-turn: worktree isolation ON (/tmp/rtl-wt.Qzd3vw)
claude-turn: WARNING: workspace '/tmp/rtl-wt.Qzd3vw' is not trusted; Claude may ignore project
  permissions. Run Claude Code interactively in this directory and accept the trust dialog, or set
  projects['/tmp/rtl-wt.Qzd3vw']["hasTrustDialogAccepted"] to true in /home/arnoldadero/.claude.json.
```

Both remedies are impossible by construction. The directory is created for that turn, has a random
`mktemp` suffix, and is destroyed afterwards — so it cannot be visited interactively beforehand, and
cannot be pre-listed in `~/.claude.json`. The next turn gets a different random path.

Consequence: the claude builder lane always runs with `permissions.allow` from the project's
`.claude/settings.json` **silently ignored**. On this host that was 16 dropped entries, observed
directly:

```
Ignoring 16 permissions.allow entries from .claude/settings.json: this workspace has not been
trusted.
```

The warning is correct and the turn proceeds, so this is not a blocker — the shim passes
`--dangerously-skip-permissions` for exactly this reason. But it means a repo cannot narrow what a
claude builder may do via `permissions.allow`: the setting has no effect in an isolated worktree, and
the only working posture is the blanket skip.

Two observations rather than a fix:

1. Trusting the worktree's **parent** template (`RTL_ROOT`) does not help — Claude Code keys trust on
   the exact workspace path.
2. `xyz-vendor`-style installs make this worse, not better, because the worktree is seeded from the
   target repo whose `.claude/settings.json` is the one being ignored.

Recorded because "set `hasTrustDialogAccepted` for this path" is advice a reader will try, waste time
on, and find cannot be followed.

---
