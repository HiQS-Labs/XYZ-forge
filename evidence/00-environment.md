# Phase 0 — Environment Stamp

Captured: 2026-08-20
Branch: `linux-bringup` (created from `development` @ `cd0f5bd`, working tree clean)

## STOP CONDITIONS HIT

Two blockers were found before any repo command was run. Both are stated in full
in the "Blockers" section below. Phase 1 was **not** started.

---

## Where commands actually run

The Claude Code shell on this host is **not Linux**:

```
$ uname -a
MINGW64_NT-10.0-22631 DESKTOP-NVQQIAE 3.5.4-395fda67.x86_64 ... Msys
$ cat /etc/os-release
cat: /etc/os-release: No such file or directory
```

It is MSYS2 / Git Bash running on Windows. The repo is reached over a UNC path
(`\\wsl.localhost\Ubuntu\home\arnoldadero\XYZ-forge`), which is a 9P network
mount, not a local filesystem.

Real Linux is reachable, and every command in this record was executed there via:

```
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' \
  wsl.exe -d Ubuntu --cd /home/arnoldadero/XYZ-forge -- bash <script>
```

Three wrapper details were required to get that working, none obvious:

| Symptom | Cause | Fix |
|---|---|---|
| `/bin/sh: bash: not found` | default WSL distro is `docker-desktop`, which has no bash | `-d Ubuntu` |
| `ERROR: CreateProcessParseCommon:711: Failed to translate \\wsl.localhost\...` | cwd is a UNC path WSL cannot translate | `--cd <linux path>` |
| `bash: C:/Users/.../xyz-phase0.sh: No such file or directory` | MSYS rewrote `/tmp/x.sh` into a Windows path | `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'` |

## Environment stamp (from inside WSL Ubuntu)

```
$ uname -a
Linux DESKTOP-NVQQIAE 5.15.146.1-microsoft-standard-WSL2 #1 SMP Thu Jan 11 04:09:03 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux

$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.1 LTS"
VERSION_ID="24.04"
VERSION_CODENAME=noble

$ node --version
bash: node: command not found          # exit 127

$ npm --version
10.9.0                                  # NOTE: this is the WINDOWS npm — see Blocker 2

$ python3 --version
Python 3.12.3

$ git --version
git version 2.43.0

$ bash --version
GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)

$ nproc
4

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       597Mi       6.8Gi       2.2Mi       613Mi       7.2Gi
Swap:          2.0Gi          0B       2.0Gi

$ df -h $HOME
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc       1007G  1.5G  955G   1% /

$ echo "WSL: ${WSL_DISTRO_NAME:-native}"
WSL: Ubuntu

$ whoami && id
arnoldadero
uid=1000(arnoldadero) gid=1000(arnoldadero) groups=...,27(sudo),...
```

## Sandbox status

**Not sandboxed at the WSL level.** The `mktemp -d` probe the brief calls out
specifically was run and passed:

```
$ t=$(mktemp -d) && echo "mktemp OK: $t" && rmdir "$t"
mktemp OK: /tmp/tmp.pvvbUAj8IP        # exit 0
```

Scratch-dir creation works, so the described "prints nothing for minutes, then
fails, looks exactly like a hang" failure mode should not occur. Outbound network
also works (`git ls-remote https://github.com/HiQS-Suite/XYZ-forge` → exit 0).

---

## Blockers

### Blocker 1 — RAM is 8 GB, half the documented minimum. `[WSL]`

`free -h` reports **7.8 GiB total / 7.2 GiB available**. The cause is a hard cap
in the Windows-side WSL config, not the physical machine:

```
$ cat /mnt/c/Users/Askyla/.wslconfig
[wsl2]
memory=8GB
processors=4
swap=2GB
networkingMode=mirrored
```

The repo states its own floor. From
`marathon-system/nightwatch-wave-2-2026-08-10--gh392-hardware-sizing/RELAY.md:153`:

> **Hardware requirement & recommended minimum**: `16 GB RAM for the serial
> marathon.sh --plan route` is explicitly stated and covers the context (one
> builder and gate serially, normal host reserve).

So 16 GB is the floor for the *serial* path — the cheapest route — and this host
has 8 GB. The same document, at line 73, states what happens when the floor is
not met:

> ... `xyz doctor`, a wave clamp, and a refusal below a memory floor.
> **None of it exists.**

and at line 63:

> ... nothing reads host RAM, nothing clamps wave width, nothing refuses.
> Per-gate containment exists; host sizing [does not].

That is the important part: **the harness will not refuse to start.** It will
launch, run, and then fail through OOM or swap-thrash at an unpredictable depth —
precisely the "discover it three hours in" outcome the brief asks me to pre-empt.
Any marathon transcript produced under this cap would be evidence about an
undersized host, not about the harness.

Tagged `WSL` and not `LINUX`: this is a local config ceiling, not a repo defect.
It is fixable by editing `.wslconfig` and running `wsl --shutdown`.

### Blocker 2 — there is no Linux Node; `npm` resolves to the Windows binary. `[WSL]`

```
$ command -v node   ; # exit 1 — not found
$ command -v nodejs ; # exit 1 — not found
$ command -v npm    ; # exit 0
/mnt/c/Program Files/nodejs/npm
```

`npm --version` answering `10.9.0` is misleading. That is `npm.exe` under
`/mnt/c/Program Files/nodejs`, leaking into the WSL `PATH` through Windows interop.
No Linux Node exists: no `nvm` (`~/.nvm` absent), no apt `nodejs`/`npm` package
installed.

Running the mandated `npm install` in this state is worse than it failing outright:
it would drive the **Windows** npm against a **Linux** filesystem, resolving
platform-gated optional dependencies and any native addons for `win32`. The
resulting `node_modules` would be wrong in a way that produces confusing downstream
failures rather than a clean error — and those failures would look like repo bugs.
`npm` would in any case be unable to find a `node` runtime to execute.

Tagged `WSL`. Fix is to install a real Linux Node (nvm or NodeSource) inside the
Ubuntu distro before Phase 1.

---

## Corrections to the brief

- **`git-bundle-snapshot.sh` is not at the repo root.** It is at
  `utils/git-bundle-snapshot.sh`. `ls git-bundle-snapshot.sh` at root → exit 2.
- **`origin` is a fork, not upstream.** `origin` is
  `https://github.com/arnoldadero/XYZ-forge.git`, not `HiQS-Suite/XYZ-forge`.
  The brief's Phase 1 says to clone `HiQS-Suite/XYZ-forge`; a checkout already
  exists here and it points elsewhere. Which of the two is the intended subject
  needs confirming before Phase 1 — they may have diverged.

---

## Resolutions

### Fork sync — CONFIRMED in sync with `HiQS-Suite/XYZ-forge`

`upstream` added as `https://github.com/HiQS-Suite/XYZ-forge.git` and fetched.
Compared by `git show-ref` and `git ls-remote --heads` (both agree):

| ref | origin (`arnoldadero`) | upstream (`HiQS-Suite`) | match |
|---|---|---|---|
| `development` | `cd0f5bdbcde2de2a1856239a64edbcc24c09c993` | `cd0f5bdbcde2de2a1856239a64edbcc24c09c993` | yes |
| `main` | `291441182115f3640149261c01324636c54faf56` | `291441182115f3640149261c01324636c54faf56` | yes |

`linux-bringup` is based on `cd0f5bd`, which is exactly `upstream/development`.
Working the fork is therefore equivalent to working upstream. The Phase 0
"corrections to the brief" note about the fork is resolved — no divergence.

> Caveat worth recording: within a single `bash -c` invocation, a `git fetch upstream`
> followed immediately by `git rev-parse upstream/development` returned
> `fatal: ambiguous argument`. `show-ref` and `ls-remote` in a later invocation both
> resolved fine. Treat same-invocation post-fetch `rev-parse` as unreliable here and
> verify with `show-ref`. Tag: `WSL` (9P/ref-cache timing), not a repo defect.

### Blocker 2 (no Linux Node) — RESOLVED

`nvm` v0.40.1 installed, then Node 22 LTS. Version chosen from `README.md:21`
("Requires **Node 18+** and **git** (the `tick` kernel runs on Node)"); the repo
has no `.nvmrc`, no `.node-version`, and no `engines` field in `package.json`, so
22 LTS was taken as a safe choice above the stated floor.

```
$ bash -lc 'command -v node && node --version && command -v npm && npm --version'
/home/arnoldadero/.nvm/versions/node/v22.23.2/bin/node
v22.23.2
/home/arnoldadero/.nvm/versions/node/v22.23.2/bin/npm
10.9.8
                                          # nvm install exit=0, alias exit=0

$ file -b "$(command -v node)"
ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), dynamically linked, ...
```

Explicitly asserted in the install script and passing: `OK: node is a LINUX binary`
/ `OK: npm is a LINUX binary` — i.e. neither resolves under `/mnt/c/`.

**Operational consequence:** nvm puts `node` on `PATH` via shell rc files, which
non-interactive shells do not read. Every command from here on must be run through
a **login** shell (`wsl.exe -d Ubuntu -- bash -lc '...'`). A plain
`bash script.sh` will not see Node and will fail the same way the pre-fix
environment did. This is a live trap for anyone following these notes.

### Blocker 1 (RAM) — STAGED, NOT YET IN EFFECT

Host has **23.9 GB physical / 4 logical CPUs**, so the documented 16 GB floor is
affordable. `C:\Users\Askyla\.wslconfig` edited (backup at `.wslconfig.bak-20260820`):

```diff
 [wsl2]
-memory=8GB
+memory=16GB
 processors=4
-swap=2GB
+swap=8GB
 networkingMode=mirrored
```

**This does not take effect until the WSL VM is restarted** — `.wslconfig` is read
only at VM boot. `free -h` still reports 7.8 GiB.

`wsl --shutdown` has not been run. It tears down the whole VM, and at stamp time
two other Claude Code sessions held live WSL interop:

```
$ pgrep -a -f "marathon|node|npm|claude|codex"
36  /init .../@anthropic-ai/claude-code/bin/claude.exe    # elapsed 31:35
969 /init .../@anthropic-ai/claude-code/bin/claude.exe    # elapsed 09:50
```

Docker was not running (`failed to connect to the docker API ... daemon is running`),
so nothing is at risk there. Awaiting operator approval before restarting.

Note the CPU count is unchanged at **4 logical processors**, which is the ceiling of
this host. The sizing doc budgets `1.5-2 GB per concurrent lane`; memory will no
longer be the binding constraint after restart, but core count may be. Recorded now
so it is not mistaken later for a harness defect.

---

## Repo state at stamp time (untouched)

```
$ git status --porcelain=v1 -b
## development...origin/development     # clean, no modifications, no stashes

$ git log --oneline -1
cd0f5bd Merge pull request #93 from HiQS-Suite/fix/gh91-relay-scratch

$ [ -d node_modules ] && echo PRESENT || echo ABSENT
ABSENT
```

Branch `linux-bringup` created from this point. Nothing else has been modified.
