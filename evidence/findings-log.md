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
