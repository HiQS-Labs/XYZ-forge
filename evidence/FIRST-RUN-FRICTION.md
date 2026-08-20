# First-run friction

Every place this bring-up got stuck, guessed, or had to read source to proceed. Ordered as
encountered. The point of this file is not to complain — it is that a stranger following the docs
should not have to guess in the same places, and each entry names what they would have to guess.

A note on what is **not** here: a large amount of this repo behaved well. The GH-177 sandbox guard,
the `--target-root` build-turn refusal, `find-harness.sh --check`, `collect.sh`'s jq degradation and
the marathon halt-on-first-failure all produced clear, actionable, correctly-timed refusals. Several
of them are the reason a failure cost seconds instead of a wasted builder turn. Where a tool did the
right thing, it is said so below.

---

## 1. Which machine am I even on?

**Stuck for:** the first three commands.

The agent shell reports `MINGW64_NT-10.0-22631 ... Msys` and has no `/etc/os-release`. The repo lives
in WSL, reached over a UNC path (`\\wsl.localhost\...`), which is a 9P network mount. Every Linux
command has to be routed through `wsl.exe`, and three separate wrapper details were needed before that
worked at all — none of them guessable:

| Symptom | Cause | Fix |
|---|---|---|
| `/bin/sh: bash: not found` | default WSL distro is `docker-desktop`, which has no bash | `-d Ubuntu` |
| `CreateProcessParseCommon:711: Failed to translate \\wsl.localhost\...` | cwd is a UNC path WSL cannot translate | `--cd <linux path>` |
| `bash: C:/Users/.../x.sh: No such file or directory` | MSYS rewrote `/tmp/x.sh` into a Windows path | `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'` |

**Had to guess:** all three. Tagged **WSL** — not a repo defect, but it is the single biggest barrier
to a Windows-host/WSL-repo session, which is a common way this repo is used.

**Recurring cost, worth stating separately:** shell loop variables (`for t in a b; do echo "$t"; done`)
are silently emptied crossing the MSYS→WSL boundary. This produced two confusing empty-output results
before the pattern was recognised. Everything after that was written to a script file first and
executed by path. A stranger will lose time here at least once.

## 2. `git-bundle-snapshot.sh` is not where the brief says

**Read source to find:** it is at `utils/git-bundle-snapshot.sh`, not the repo root. `ls` at root
exits 2. Thirty seconds, but it is the first thing you are told to run before anything risky.

## 3. Node exists, and `command -v node` says it does not

**Stuck for:** ~20 minutes across two separate occasions, because the symptom changes shape.

Covered in detail in `LINUX-SETUP.md` §1 and findings F-006/F-008. The friction is not the cause — it
is that the three observations disagree and nothing reconciles them:

- interactive terminal: `node --version` works
- `bash -lc 'command -v node'`: empty
- `bash -lc 'command -v npm'`: **succeeds**, pointing at a Windows binary under `/mnt/c/`

The third is the dangerous one. A failure would have been fine; a *wrong* success is what costs time.
And the second occasion is worse than the first: after installing a builder with `npm install -g` and
watching it exit 0, `find-harness.sh --check` still reported it missing. Nothing in either tool
explains the disagreement.

**What a stranger needs told:** "if you manage Node with nvm, put the nvm bindir on PATH explicitly
before running anything in this repo, because non-interactive shells do not read `~/.bashrc`." That
sentence appears nowhere.

## 4. The `relay-xyz` skill cannot be loaded in this topology

**Blocked until worked around.** The guard refuses to run any marathon driver until the session proves
it loaded the `relay-xyz` skill. `skills/relay-xyz/install.sh` symlinks it into the **WSL** home, but
the Claude Code process driving the session is the **Windows** binary, which reads
`C:\Users\...\.claude\skills`. The documented one-command fix cannot make the skill loadable across
that split.

Resolved via the guard's own sanctioned alternative — it accepts running `find-harness.sh` as proof
(`relay-xyz-guard.sh:91-95`). **Had to read the guard's source to discover that**; it is not in the
error message. Tagged **WSL** (finding F-007): on a native Linux box `install.sh` puts the skill where
that machine's Claude Code reads it.

## 5. "Compute" is not a verb

**Had to establish by exhaustive grep.** The task brief specifies a lifecycle of
"compute, preflight, dry run, full run". Four map to real commands. **Compute does not exist** — nine
hits repo-wide, none a lifecycle verb, the closest being an implementation comment inside
`utils/marathon-plan.sh:170`. The repo's actual documented lifecycle is
**triage → preflight → dry-run → confirm → fire**.

Recorded rather than papered over, because a stranger reading the brief would go hunting for a
`marathon compute` command. Finding F-002.

Then, later and worse: the nearest functional equivalent (`marathon-plan.sh`) **cannot run in a
vendored repo at all** — `ROADMAP not found`, exit 3 — because it reads the harness's own PDDA ledger.
That is the exact deployment shape `xyz-vendor.sh` creates. Finding F-022.

## 6. agy: three separate walls in a row

This consumed the largest single block of time, and each wall looked like the previous one was wrong.

1. **Not installed, and not obviously installable.** No npm package publishes it
   (`@google/antigravity`, `@antigravity/cli`, `agy` — all nothing or placeholders).
   `antigravity.google/docs/cli` 404s. The Antigravity **IDE** was installed on the Windows side and
   contains no `agy` binary — only `antigravity-ide`. The repo's own doc documents only the **macOS**
   path (`~/.local/bin/agy`).
2. **Installed, and the harness's own preflight blocked it.** Once `agy` was present, every turn would
   have died at `exit 5`. Diagnosing this required reading four files
   (`agy-turn.sh` → `utils/py/agy-turn.py` → `utils/py/rtl.py` → `test/gh375-auth-timeout-verdict.sh`)
   and then calling the preflight function directly to get a verdict, because the exit code alone said
   nothing about why. Finding F-015.
3. **The probe hangs and ignores SIGTERM.** `timeout 30 agy whoami` was still alive at 6m43s. Two
   background tasks and two 205 MB processes had to be killed by hand. A `timeout` that does not time
   out is a genuinely disorienting thing to hit mid-diagnosis.

**Trap for the next person:** `pkill -f "agy whoami"` matches its own shell's command line and kills
the session running it. Use `pkill -f '[a]gy whoami'`.

**Credit:** the code that made this diagnosable is excellent. `utils/py/rtl.py`'s comments state the
measurement, the date, the issue number and what the previous wrong fix cost (`4/0 to 0/4`). That is
why the fix could be made narrow — it was possible to know exactly which rule not to break.

## 7. The preflight contract: three failures to get one pass

**Read source to resolve.** Getting a valid contract took three attempts, each a different exit code,
and only the source explains the shape:

| Attempt | Result |
|---|---|
| new files in `artifacts[]` | exit **5** — `artifact path not found at target.ref` |
| `artifacts_new` as a parallel list | exit **3** — `artifacts_new entry not present in artifacts[]` |
| `artifacts_new` as a subset of `artifacts[]`, each with a `path_absent` probe | exit **0**, ready |

The exit-3 message says to copy `relay-automation/CONTRACT.example.md`. **That file never mentions
`artifacts_new`** — nor does README, ROUTER, AGENTS, or anything under `relay-automation/`. Outside
PROJECT captures and the CHANGELOG, the only prose mention repo-wide is one line in
`skills/marathon-triage/SKILL.md:93` that references the field without defining it.

Greenfield work is the normal case for a marathon, so this is on the main path, not an edge. Finding
F-019.

## 8. `--target-root` is advertised for the case that refuses it

**Cost one halted run** (2 seconds, no spend — the refusal is well-placed). The `--target-root` help
recommends it for a repo that gitignores harness output; that was exactly the target. `relay-drive`
then refused the combination, because `--target-root` keeps the relay thread in the harness repo by
design and a build turn therefore cannot report.

**This is the best failure in the whole bring-up.** It fired before a single builder turn was spent,
stated the cause in one sentence, and named two concrete remedies — one of which worked immediately.
The defect is only that the help promises a combination the driver rejects. Finding F-018.

The second-order cost is unstated though: taking the remedy means the target must now **track**
`marathon-system/` and `relay-system/` — the thing `--target-root` existed to avoid. For a genuinely
public repo, neither branch of the advice is available.

## 9. `--plan` does not resolve where the help says

**Cost one failed dry-run and a source read.** `marathon: plan not found: <path>` for a file that
plainly exists at that path inside `--target-root`. The help says "Plan and brief paths resolve against
DIR when set." The existence check at `:136` runs 19 lines before `_plan_base` is computed at `:155`.
The error message gives no hint that a different root was used. Absolute paths work. Finding F-017.

## 10. The sandbox, and the exit code that lied

Two entries that generalise beyond this repo.

**The sandbox.** Every test invocation is refused by `gh177-sandbox-test-guard.sh` until the Bash tool
is run unsandboxed. This is the guard doing its job — it converts the failure the brief warned about
("prints nothing for minutes and then fails, and it looks exactly like a hang") into an instant,
explanatory refusal naming the remedy. Worth stating clearly because it is easy to misattribute: the
sandbox is imposed by the **agent harness**, not by WSL. `mktemp -d` works fine inside WSL.

**The exit code.** A background task whose marathon halted with `EXIT_CODE: 2` was reported by the
harness notification as `completed (exit code 0)`. The same class of error is already recorded in
F-014, where `./validate.sh --sequential | tail -80` reported `tail`'s status for a suite that exited
1. It fired twice in one bring-up on two different mechanisms.

**The only defensible rule:** a run counts only if a `PIPESTATUS[0]`-derived `EXIT_CODE:` was written
to a log. Not the notification, not the terminal's last line. Every command in this bring-up went
through `evidence/_env/run.sh` for exactly this reason. Finding F-021.

## 11. Things that cost time and were nobody's fault

- **`node --test test/`** fails on Node 22 with `Cannot find module '.../test'` — a bare directory
  argument is resolved as a module path. `node --test` alone auto-discovers correctly. Not this repo's
  code; noted because it briefly looked like a harness problem.
- **`your 131072x1 screen size is bogus. expect trouble`** is printed by WSL on many invocations and
  is pure noise, but it appears in the middle of real output and reads like a warning about the thing
  you just ran.
- **`sudo -v` in another terminal does not help a ttyless agent session.** sudo 1.9.15p5 defaults to
  `timestamp_type=tty`, so a credential cache created in an interactive terminal is keyed to that tty.
  Cost one full round-trip with the operator before the cause was understood. Not a repo issue at all,
  but it will hit anyone driving this repo from an agent.

---

## What would have saved the most time

In order of time saved, if only these were fixed:

1. **One paragraph in the README about nvm and non-interactive shells.** It is the root of two
   findings (F-006, F-008), it makes an installed builder invisible, and its "wrong success" shape
   (Windows `npm` answering on a Linux box) is actively misleading. Cheapest fix, largest saving.
2. **`artifacts_new` in `CONTRACT.example.md`.** Three failed attempts and a source read, on the main
   path for the normal case, pointed at a file that does not contain the answer.
3. **The `--target-root` help sentence.** It recommends a combination another component refuses.
4. **`sqlite3`, `jq` and a global git identity in the prerequisites list.** Seven suites and one
   confusing exit-128 chain, all from three lines of documentation.
