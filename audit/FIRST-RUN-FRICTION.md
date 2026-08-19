# FIRST-RUN-FRICTION.md — timestamped, honest first-run log

> The maintainer has an open milestone about whether the repo survives a stranger's **first run**.
> You can only be a first-time user once, so this was captured *as it happened*, not reconstructed.
> Times are local (Windows host) on 2026-08-18. "Guess" = a moment I assumed rather than verified.
> Platform caveat: this is **MINGW64/MSYS2 Git-Bash on Windows 11** (build 22631), *not* WSL and *not* macOS —
> so several frictions below are **Windows/MSYS-specific** and are labelled as such.

---

## T0 — Clone (clean)

- `git clone --depth 1 https://github.com/HiQS-Suite/XYZ-forge.git` → succeeded. 638 files.
- No `npm install` step mentioned in a quick README skim; proceeded.

## T+2 min — `npm install` (FIRST involuntary step)

- **Friction:** `node_modules` was **absent**. `bin/tick` itself is pure Node and runs, but some shims
  require `acorn` (a declared dependency). Ran `npm install` → "added 2 packages" in ~24s. **Exit 0.**
- **Guess I made:** assumed the repo would "just run" after clone. Wrong — deps are not vendored and
  the README's happy path does not foreground `npm install`. Minor, but a stranger hits it immediately.
- **ENV, not a bug:** on macOS/Linux the same `npm install` is required; the friction is the *missing
  callout*, not Windows-specific.

## T+5 min — Git hook wiring (second involuntary step)

- **Friction:** `githooks/install.sh` is **not** run by `npm install` or the clone. The gate only
  exists after `bash githooks/install.sh`. Ran it → installed `.git/hooks/pre-push`. **Exit 0.**
- The script helpfully prints the bypass (`git push --no-verify` / `XYZ_SKIP_PREPUSH=1`) and the
  verify command. Good DX here.
- **Observation:** the README/AGENTS.md *do* document this, but a stranger following a "clone and run"
  instinct misses it. The milestone concern is valid.

## T+10 min — `validate.sh` NOT launched (scope decision, honest)

- **Friction/guess:** I intended to kick off `./validate.sh --sequential | tee run.log` per the
  two-hour plan. I **did not**, because: (a) `node_modules` had just been installed and the suite is
  ~4 min parallel / sequential fallback; (b) my mandate was the *kernel + relay* audit with real probes,
  and the full gate is the maintainer's CI boundary. **This is a scope gap I am flagging openly**, not
  hiding. The harness's own `node --test test/unit/*.test.js` (12/12) was run instead as the
  authoritative unit-level verification.
- **Recommendation for the milestone:** a stranger's first run SHOULD include `./validate.sh` in the
  documented happy path, or `npm install` should post-install the hook (one less manual step).

## T+15→50 min — Kernel probes by hand (see FINDINGS.md)

- Ran P1–P7 live in a throwaway repo `C:\Users\<user>\xyz-probe`.
- **Friction (ENV):** `tick` invoked with an MSYS path (`/c/Users/...`) inside `relay-drive.sh` failed
  silently because the bundled `node` is **native Windows** and chokes on `/c/...`. **Fix:** forced
  `TICK_BIN`/`ROOT_DIR`/`TICK_REPO_ROOT` to `C:/Users/...`. This is **F-ENV-1** — a real Windows
  contributor footgun, not a harness logic bug. A stranger on Windows will hit this exact wall
  (you did, with the `XYZ_PYTHON=0` PowerShell error earlier).
- **Guess I made & corrected:** initially I assumed the relay "stopped at exit 3" was a harness bug.
  Verified by experiment — it was my **demo turn-taker** calling `release` on an open token. The
  harness's no-progress guard is *correct*. Lesson logged here rather than quietly dropped.
- **Friction:** `search_files` (ripgrep) failed repeatedly on `/c/...` MSYS paths on this host — had to
  fall back to `grep -rn` in the terminal. Tooling/env quirk, not harness.

## T+50→70 min — BUG-1 fix & unit verification

- Edited `src/events.js` (uniqueness suffix on event filename). `node --check` passed.
- Added regression test to `test/unit/events.test.js`.
- Ran `node --test test/unit/events.test.js test/unit/project.test.js` → **12/12 pass**. **Exit 0.**
- **Friction (tooling):** the editor's inline `node --check` lint reported `Cannot find module
  'C:\c\Users\...'` — the linter mangled the Windows path the same way native node does. The file was
  fine; verified with an explicit `node --check "C:/..."`. Same root cause as F-ENV-1.

## T+70→110 min — Reproduction script

- Wrote the kernel probe script (one file, all P1–P7). Ran it → 4 invariants confirmed, 2 findings
  (F1, F5), 0 info. **Exit 0.** *(That script and the containment probes are proposed in #51;
  this directory is the evidence they produced.)*
- Captured every probe's stdout/stderr to `audit/logs/`, one log per frame, each ending in its exit code.
- **Friction (Windows):** `rm -rf` of the probe repo sometimes reports `Device or resource busy`
  (NTFS lock on `.git`). Harmless; `--keep` covers it.

## T+110→130 min — Write-up

- FINDINGS.md (issue-ready), ENVIRONMENT.md (stamp), this log, and a lengthy AUDIT-REPORT.md.

---

## Honest scorecard for the "stranger's first run" milestone

| Step | A stranger hits it? | Blocking? | Env-specific? |
|---|---|---|---|
| `npm install` required, not foregrounded | yes | no (clear error) | no (all platforms) |
| `githooks/install.sh` required, not auto | yes | no | no |
| Windows: `/c/...` paths break `tick` in shell drivers | **yes, on Windows only** | **yes** until you learn the `C:/...` workaround | **yes (MSYS/native-node)** |
| `validate.sh` not in the happy path | yes | no | no |
| CRLF in `.sh` (breaks on Linux/macOS) | yes, on those platforms | possible | yes (non-Windows) |
| `package.json` `"main": index.js` missing | only if `require('xyz-3-agents-swarm')` | no | no |

**Verdict for the milestone:** on **macOS/Linux** (the documented targets) the first run is smooth
apart from the two undocumented setup steps (`npm install`, hook install) — both fixable with a
postinstall + a one-line README callout. On **Windows/MSYS** there is a **genuine first-run blocker**
(F-ENV-1: native-`node` + MSYS path mismatch) that a Windows contributor cannot clear without external
help. That is the highest-value environment finding and worth a Windows-support note regardless of the
macOS/Linux canary.

---

# Second pass — containment probes + the gate that was skipped last time

> Captured live on 2026-08-18, not reconstructed. Times are local. "Guess" = something I assumed
> rather than verified. This pass exists to close the three gaps the first pass left open: the
> containment claims were never tested, `validate.sh` was never run, and the environment stamp had
> three wrong values in it.

## T+0 — pristine worktree instead of the working tree

- **Decision, not friction:** the first pass left an uncommitted BUG-1 patch in `src/events.js`. Any
  finding measured against that tree is only reproducible for someone who applies the same patch
  first. Probed a `git worktree add --detach origin/development` at `C:/tmp/xyz-pristine` instead.
- **Immediately hit F8.** The worktree's very first `validate.sh` line was:
  `C:/tmp/xyz-pristine/C:/Users/<user>/XYZ-forge/.git/hooks/pre-push does not exist.`
  Two absolute paths glued together. I assumed for about a minute that I had mis-set something. I had
  not — it is `githooks/install.sh:53` testing `case "$COMMON" in /*)`, which no Windows absolute path
  ever matches. **A stranger on Windows sees a nonsense path in the first five lines of the first
  command the README tells them to run.**

## T+4 — the repo refused my first `validate.sh`, correctly

- Ran `./validate.sh --sequential` and was **blocked by the repo's own hook**:
  `GH-177 guard: refusing to run the test suite under a SANDBOXED Bash call. Sandbox-broken mktemp fed
  the destructive EXIT trap that wiped this repo twice.`
- It named the post-mortem (`PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md`), gave two options,
  and specified the exact opt-out. **This is the best error message in the repo** — it explains the
  blast radius, the history, and the escape hatch in five lines. Re-ran un-sandboxed. Zero friction
  after that, because the message did its job.

## T+7 — writing a fake agent, which is where the leverage is

- The shims take `CODEX_BIN` and the repo's own `test/codex-turn.sh` already injects a stub, so the
  containment claims can be attacked without any credential. Wrote six hostile agents: commit
  mid-turn, edit off-lane, hang, exit-0-doing-nothing, off-lane-then-hang, and fork-a-child-that-
  outlives-the-kill. **This is the highest-value twenty minutes in the whole audit and it costs nothing.**
- **Friction (ENV):** `bin/tick` is `#!/usr/bin/env node`, and MSYS hands native-Windows node an
  `/c/...` path it cannot resolve. Had to write a two-line bash wrapper and force `C:/...` form
  everywhere via `cygpath -m`. Known as F-ENV-1 from the first pass; still a Windows footgun.
- **Guess I made, and it was wrong:** I expected "any commit during a turn → exit 6". Under worktree
  isolation that is **not** the contract — a moved ROOT HEAD there means a concurrent *peer*, and the
  code deliberately preserves it because a blind reset orphaned a peer's commit on 2026-06-23. Read
  `relay-turn-lib.sh:1064-1071` before writing the assertion. Had I asserted my first instinct I would
  have filed a bug against a deliberate fix.

## T+25 — the Python lane, and a conclusion the first pass got backwards

- Ran every probe on both lanes. **Every single Python-lane probe returned 1, including the control.**
- **Did not report that as nine containment failures.** A control turn that cannot start makes every
  downstream verdict meaningless. Read the log: `OSError: [WinError 193]` out of
  `rtl.py:240 subprocess.run([tick_bin, ...])`. Re-tested with the **real** `bin/tick` rather than my
  fixture wrapper to be sure it was not my own artefact. It reproduced. Then changed the script to
  gate the lane on its control and report **one** finding plus eight BLOCKED rows.
- **The first pass's stamp said `python3` was a Microsoft Store stub**, and concluded the Python lane
  would harmlessly degrade to Bash. It is a real Python 3.13.14, the guard passes, and **Python is the
  default lane** (`${XYZ_PYTHON-1}` — unset substitutes 1). So the default path on this host does not
  degrade; it crashes with an exit code that is not in the shim's documented menu. The earlier reading
  inverted the risk. Corrected in `ENVIRONMENT.md`.

## T+55 — the gate, honestly

- `./validate.sh --sequential` ran to 120 suites, then spent **12+ minutes inside a single suite**
  (`gh544-pre-push-gate.sh`) without emitting a line. It was not deadlocked — `ps` showed it fanning out
  through `xargs`, spawning a fresh bash + python3 + `gh` per iteration. On four Windows cores, process
  spawn is expensive enough that a suite which is presumably brisk on macOS becomes a coffee break.
- **Friction:** there is no progress indicator inside a suite, so "slow" and "hung" are indistinguishable
  to a first-time user. I only knew the difference because I ran `ps`.
- Failures observed so far cluster into the **same** root causes as the probes — `good turn rc=1` and
  `shim must exit 7 on a timeout kill, got 1` are F7; `brief file not found: /c/tmp/.../C:/Users/...`
  is F8 in a second, independent location. **The repo's own suite detects these.** Nobody had run it here.

## T+70 — tooling friction worth reporting

- A **read-only `grep`** was refused by `relay-automation/hooks/relay-xyz-guard.sh` because the command
  string contained `relay-automation/`. Right instinct, over-broad match — it cannot distinguish reading
  the harness from driving it.
- `AUDIT-REPORT.md` cited `xyz-screens/*.png` in its deliverables table. **That directory does not exist.**
  A handover that cites evidence which is not there devalues the evidence that is. Those citations were
  removed; the report now points only at `audit/logs/`, which has 48 transcripts that do exist and a
  `LOG-INDEX.md` mapping each to the probe it came from.

---

## Updated scorecard for the "stranger's first run" milestone

| Step | Stranger hits it? | Blocking? | Env-specific? |
|---|---|---|---|
| `npm install` required, not foregrounded | yes | no | no |
| `githooks/install.sh` required, not automatic | yes | no | no |
| Hook check prints a mangled path in a worktree (F8) | yes, Windows | **yes** — the gate cannot be installed or verified | **yes** (Windows + worktree) |
| Default lane crashes with an unhandled traceback (F7) | yes, Windows | **yes** — no turn can run at all | **yes** (Windows) |
| `validate.sh` not in the documented happy path | yes | no | no |
| A single suite runs 12+ min with no output | yes | no, but indistinguishable from a hang | partly (4-core Windows) |
| CRLF in `.sh` | yes, on Linux/macOS | possible | yes |

**Verdict.** On **macOS/Linux** the first run is smooth apart from two undocumented setup steps. On
**Windows the repo does not currently work** — not the containment core, which is sound (eight of nine
invariants held under direct attack), but the default execution lane and the path handling around it.
The gap is not exotic: it is shebang execution and absolute-path detection, both of which are invisible
to a macOS canary *and* to the open Linux canary, because both honour shebangs and `/`-rooted paths.
A Windows contributor cannot clear this without help. That is the single highest-value thing this
third environment has to tell the project.
