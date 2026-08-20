# LINUX-SETUP.md — the cold-start path that actually works

Written against Ubuntu 24.04 (WSL2), Node 22.23.2, `linux-bringup` @ `cd0f5bd`.
Every command here was run and its exit code logged; the log for each is named in the step.

This is **not** what `README.md` says. The README's Quickstart is three commands:

```bash
npm install
bash githooks/install.sh
./validate.sh
```

That is correct as far as it goes, and it is enough to run the **test suite**. It is not enough to
run a **marathon**, which is what most people arrive wanting. The gap is steps 0, 5, 6 and 7 below.

---

## 0. Get a real Linux Node — and make it visible to non-interactive shells

**This is the step that costs people an hour.** See F-006.

The repo needs Node 18+ (`README.md:21`). If you install it with `nvm`, the installer appends its
loader to the **bottom** of `~/.bashrc`. Ubuntu's stock `~/.bashrc` returns at line 8 when the
shell is not interactive:

```bash
case $- in
    *i*) ;;
      *) return;;
esac
```

So a login-but-non-interactive shell — `bash -lc`, cron, CI, an agent harness, and every marathon
turn — never loads nvm. `command -v node` comes back empty.

On WSL specifically it gets worse rather than failing cleanly: `npm` still resolves, to
`/mnt/c/Program Files/nodejs/npm` — the **Windows** npm, leaking in over interop. Running
`npm install` in that state builds a `node_modules` with `win32` dependency resolution against a
Linux filesystem, which breaks later in ways that look like repo bugs.

Install Node:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
nvm install 22          # README requires 18+; no .nvmrc or engines field exists, 22 LTS is safe
nvm alias default 22
```

Then **prove** it before continuing — do not trust `npm --version`, which lies here:

```bash
command -v node    # must NOT be empty, must NOT be under /mnt/c/
command -v npm     # must NOT be under /mnt/c/
file -b "$(command -v node)"   # must say: ELF 64-bit LSB executable
```

Two ways to make it stick for non-interactive shells. Pick one:

**a) Per-run prelude (what this bring-up used — reproducible, no hidden state):**

```bash
. evidence/_env/prelude.sh && xyz_assert_linux_node
```

It resolves the newest nvm node bindir, prepends it to `PATH`, and asserts the result is not a
Windows binary. Log: it prints `PRELUDE OK: node=… npm=…` and returns 0.

**b) Fix your dotfiles (better for a workstation):** put the nvm loader in `~/.profile`, which
login shells read and which has no interactive guard — not in `~/.bashrc`, where it is unreachable.

## 1. Clone and branch

```bash
git clone https://github.com/HiQS-Suite/XYZ-forge
cd XYZ-forge
git checkout -b <your-branch>
```

## 2. Snapshot before anything risky

The repo ships this because it has twice had a working tree wiped (`utils/git-bundle-snapshot.sh:4`):

```bash
bash utils/git-bundle-snapshot.sh
```

Writes `~/Backups/XYZ-forge/XYZ-forge-<stamp>.bundle` and verifies it before promoting it from
`.tmp`. Recovery is `git clone <bundle> recovered/`.
**Note: it is at `utils/git-bundle-snapshot.sh`, not the repo root.** Log: `evidence/01-snapshot.log`, exit 0.

## 3. Install dependencies

```bash
npm install
```

Two packages, ~3s. Log: `evidence/01-npm-install.log`, exit 0. Skip it and the suite dies at
`Cannot find module 'acorn'` (`README.md:31-32`).

## 4. Wire the push gate

```bash
bash githooks/install.sh          # idempotent
bash githooks/install.sh --check  # exit 1 if this clone is ungated
```

Log: `evidence/01-githooks-install.log`, exit 0. `.git/hooks/` does not travel with a clone, so
this is per-clone. Harmless if you never push; `--uninstall` reverses it.

## 5. Run the suite — **un-sandboxed**

```bash
./validate.sh --print-mode    # says which mode it would pick, runs nothing
./validate.sh --sequential    # the source of truth
```

On this 4-core host `--print-mode` reported `PARALLEL mode 2-wide … cores/2 (floor 2, cap 4)`, and
told the truth about its own standing: *"NOT promotion evidence: the qualifying gate is
ci-local.sh's sequential run (GH-509)."* Logs: `evidence/03-validate-print-mode.log`,
`evidence/02-validate-sequential.log`.

The suite creates scratch dirs with `mktemp -d`. Under a sandboxed agent shell those are blocked,
and the run prints nothing for minutes before failing — it looks exactly like a hang. `README.md:44-51`
calls this the repo's single most common false alarm. Check first:

```bash
t=$(mktemp -d) && echo "OK $t" && rmdir "$t"
```

## 6. Make the `relay-xyz` skill discoverable — required before any marathon work

**Missing from the README's setup path entirely.** A `PreToolUse` hook
(`relay-automation/hooks/relay-xyz-guard.sh`) refuses to execute `marathon.sh`, `marathon-drive.sh`,
`relay-drive.sh`, `poll.sh`, `codex-turn.sh` or `agy-turn.sh` until the session proves it loaded
the `relay-xyz` skill. The repo keeps skills in top-level `skills/`, which Claude Code does not
scan, so on a fresh clone the skill is invisible and the guard blocks everything:

```bash
bash skills/relay-xyz/install.sh   # symlinks skills/relay-xyz into ~/.claude/skills/ (and codex/gemini)
```

> **Windows-host + WSL-repo caveat (F-007).** If your Claude Code is the *Windows* binary while the
> repo lives in WSL, this cannot work: the installer symlinks into WSL's
> `/home/<you>/.claude/skills`, but Windows Claude Code reads `C:\Users\<you>\.claude\skills`, and a
> Linux-path symlink does not resolve there. On a native Linux box this step just works.

Then run the locator the skill mandates — this is also what satisfies the guard
(`relay-xyz-guard.sh:91-95`):

```bash
bash skills/relay-xyz/find-harness.sh --check
```

Log: `evidence/02-find-harness-check.log`, exit 0. It reports the harness root, the `tick` CLI, and
**which builders are on PATH** — which is the next step.

## 7. Install a builder CLI — marathon does nothing without one

`find-harness.sh --check` on a fresh box says:

```
  --  codex CLI (Path A worker)  (not found)
  --  agy CLI   (Path A worker)  (not found)
  !   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available
```

`marathon.sh` defaults to `--builder codex` (`marathon.sh:90`) and does **not** check up front that
it exists, so the absence surfaces mid-run rather than at parse time.

```bash
npm install -g @openai/codex     # log: evidence/04-codex-install.log, exit 0
codex login                      # interactive, opens a browser — cannot be scripted
```

`codex` bills via the ChatGPT/Codex subscription, not per API call. `--builder claude` is
per-call API-billed and is an explicit cost decision, never a default (`marathon.sh:18-21`).

Do **not** trust a bare `command -v claude` on WSL: it resolves to the Windows `claude.exe` over
interop and would dispatch a Windows binary against a Linux worktree.

## 8. PDDA — required for marathon, and it is a separate repo

`README.md:107-108`: "Marathon **requires** PDDA". XYZ-forge already *is* PDDA-installed
(`utils/pdda/pdda.sh` is the in-repo runtime). What you need PDDA's installer for is your
**target** repo — the one the marathon will act on:

```bash
git clone https://github.com/Hypercart-Dev-Tools/pdda.git
bash pdda/install.sh /path/to/target-repo      # observe mode, idempotent
```

Log: `evidence/03-pdda-install.log`, exit 0, 45s, all checks passed. It creates
`PROJECT/{1-INBOX,2-WORKING,3-COMPLETED,4-MISC}`, `ROADMAP.md`, `CHANGELOG.md`, `RELEASES.md`,
`.pdda-mode` (= `observe`), and the runtime under `utils/pdda/`.

You need that tree because `marathon.sh` **refuses a plan that does not resolve under
`PROJECT/2-WORKING/`** in the target repo (`marathon.sh:23-26`, GH-212). Override with
`MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` only if you know why you are doing it.

## 9. Optional but recommended tools

Not required by the Quickstart, but several paths degrade without them:

| Tool | Used by | Absent on a stock Ubuntu 24.04 |
|---|---|---|
| `jq` | the relay guard's fast path (falls back to `python3`) | yes |
| `sqlite3` | inspecting `releases.db` by hand (the app uses Python's module) | yes |
| `shellcheck` | shell linting | yes |
| `gh` | `marathon-triage`, `swarm-preflight` live-issue reconciliation | present here |

```bash
sudo apt-get install -y jq sqlite3 shellcheck
```

Probe what you actually have: `bash evidence/_env/probe-deps.sh` (log: `evidence/02-deps-probe.log`).

---

## Hardware

`README.md:188` — **16 GB RAM minimum** for the serial `marathon.sh --plan` route; a serial
marathon measured ~2.2 GB steady. Nothing in the harness reads host RAM, clamps wave width, or
refuses to start on an undersized box (`README.md:225-228`), so an under-provisioned host does not
fail fast — it fails at an unpredictable depth. Check before you start:

```bash
free -h
```

On WSL that is capped by `%USERPROFILE%\.wslconfig`, not by physical RAM, and the file is read only
at VM boot — `wsl --shutdown` is required for a change to take effect.
