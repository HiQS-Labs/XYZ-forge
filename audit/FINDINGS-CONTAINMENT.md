# FINDINGS — containment pass (numbered, GitHub-issue-ready)

**Audit date:** 2026-08-18 · **Harness under test:** `HiQS-Suite/XYZ-forge` @ `911878c`, probed in a
**pristine `origin/development` worktree** (`git worktree add --detach`) so nothing here depends on the
uncommitted BUG-1 patch from the earlier pass.
**Reproduction:** `bash audit/repro-containment.sh` — one file, no agent credentials, no network, no token spend.
**Evidence:** every claim below has a screenshot in `audit/screens/` and the log it was rendered from in
`audit/logs/`. Index: `audit/screens/INDEX.md`.
**Environment:** `audit/ENVIRONMENT.md`. Probe host is **MINGW64/MSYS2 Git-Bash on Windows 11 build 22631** —
**not WSL**, not macOS. A third environment, and every finding below is explicitly tagged
**HARNESS BUG** or **WINDOWS-ONLY** so nothing lands as noise.

Severity: **HIGH** (blocks a documented path) · **MEDIUM** (real defect, bounded blast radius) ·
**LOW** (hygiene) · **INFO** (invariant confirmed — negative control).

---

## How these were tested without spending a cent

Every turn shim resolves its agent binary from an environment variable —
`relay-automation/codex-turn.sh:71`, `CODEX_BIN="${CODEX_BIN:-codex}"` — and the repo's own
`test/codex-turn.sh` already injects a stub that way. So the containment claims can be tested with
**fake agents that misbehave on purpose**: one that runs `git commit` mid-turn, one that edits outside
the allowlist, one that sleeps past the watchdog, one that exits 0 having done nothing, one that forks a
child to outlive its own death. No Codex login, no `agy` auth, no network, no tokens.

---

## F7 — [HIGH] The DEFAULT lane crashes on Windows with an undocumented exit code

**Command (probe D1):**
```bash
# NO XYZ_PYTHON set anywhere — this is the untouched default a stranger gets
env RELAY_AGENT=codex RELAY_FILE="$FIX/relay.md" RELAY_TASK=RELAY-TURN \
    CODEX_AGENT=codex CODEX_BIN="$STUB_GOOD" CODEX_TURN_ROOT="$FIX" \
    TICK_REPO_ROOT="$FIX" TICK_BIN="$XYZ/bin/tick" \
    bash relay-automation/codex-turn.sh
```

**What the docs say would happen:** `codex-turn.sh:56-57` documents the exit menu as
`0 acted/deferred · 5 codex failed / token ownership missing · 6 off-allowlist edit (reverted) ·
7 timeout-killed · 2 usage`. `codex-turn.sh:6-7` states Python is authoritative and the Bash file is a
"historical fallback"; the GH-112 comment says "Default (unset/0) runs the canonical Bash implementation
below — Bash stays the supported default until the port is promoted."

**What happened:** the code does not match its own comment. `codex-turn.sh:9` reads
`"${XYZ_PYTHON-1}"` — single `-`, so an **unset** variable substitutes `1`. The default is **Python**,
not Bash. The guard at `codex-turn.sh:13-14` then finds `python3` 3.13.14 on PATH, passes, and execs
`utils/py/codex-turn.py`. That crashes immediately at the first token operation:

```
File "utils\py\rtl.py", line 240, in claim_task_or_exit
  claim_res = subprocess.run([tick_bin, "claim", task, ...])
OSError: [WinError 193] %1 is not a valid Win32 application
```

`rtl.py:240` runs the tick binary as `subprocess.run([tick_bin, ...])` with no interpreter, relying on
the shebang. `bin/tick` is `#!/usr/bin/env node` with no `.exe`/`.cmd` form. POSIX `execve` honours a
shebang; Windows `CreateProcess` does not. Five call sites do this: `rtl.py:240, 248, 281, 320, 332`.

**Exit code:** **1** — an unhandled Python traceback. 1 is **not in the shim's documented menu**, so
`relay-drive.sh`'s exit-code dispatch cannot classify it as a containment failure, a timeout, or an
ownership problem.

**Severity:** HIGH. On Windows the documented default path cannot run a single turn, and it fails in the
one way a supervisor cannot interpret. Confirmed independently by the repo's **own** suite on this host:
`test/codex-turn.sh` → `FAIL: good turn rc=1`, `test/gh278-turn-timeout-parity.sh` →
`FAIL: py-shim: shim must exit 7 on a timeout kill, got 1`.

**Environment note:** **HARNESS BUG, WINDOWS-ONLY manifestation.** The defect is a POSIX-only assumption
in shared Python code, not an MSYS quirk. It cannot reproduce on macOS/Linux, where the shebang resolves.
It is exactly the class of thing the open Linux canary will not catch either, because Linux honours shebangs too.

**Suggested issue title:** Python lane (the `${XYZ_PYTHON-1}` default) cannot exec `bin/tick` on Windows — WinError 193, exit 1 (F7)
**Suggested labels:** bug, severity/high, area/python-port, platform/windows, `runtime:python`
**Suggested fix:** resolve the interpreter explicitly rather than relying on the shebang — e.g.
`subprocess.run([node_bin, tick_bin, ...])`, or ship a `bin/tick.cmd` shim on Windows. Separately, either
fix the comment at `codex-turn.sh:10` or flip `${XYZ_PYTHON-1}` to `${XYZ_PYTHON-0}` so the documented
default and the actual default agree.

**Evidence:** `audit/screens/d1-1-what-the-default-is.png` (the lane switch and the guard passing),
`d1-2-real-tick-under-python.png` (WinError 193 against the **real** `bin/tick`, not a fixture wrapper),
`d1-3-default-turn.png` (the full traceback), `d1-4-after.png`.

---

## F8 — [MEDIUM] POSIX-only absolute-path test mangles Windows paths — 20+ call sites

**Command (repro):**
```bash
git worktree add --detach /c/tmp/xyz-pristine origin/development
cd /c/tmp/xyz-pristine && bash githooks/install.sh --check
```

**What the docs say would happen:** `githooks/install.sh:45-49` explains the design deliberately uses
`git rev-parse --git-common-dir` precisely so that "from a worktree, `--git-common-dir` points at the
PARENT clone, and that is where git looks for hooks" — i.e. one install is meant to cover every worktree.

**What happened:**
```
githooks: NOT INSTALLED in this clone.
  C:/tmp/xyz-pristine/C:/Users/Askyla/Senior_dev/XYZ-forge/.git/hooks/pre-push does not exist.
```
Two absolute paths concatenated. Root cause is `githooks/install.sh:53`:
```sh
case "$COMMON" in /*) ;; *) COMMON="$REPO/$COMMON" ;; esac
```
The `/*` glob is a POSIX-only test for "is this absolute". Git for Windows returns
`C:/Users/.../.git`, which does not match `/*`, so an already-absolute path is treated as relative and
prefixed with the repo root.

**Precondition:** a **linked worktree** on **Git for Windows**. In a normal clone `--git-common-dir`
returns the relative `.git`, the `*` branch fires correctly, and the check passes — verified.

**Exit code:** 1 from `--check`; `validate.sh` then prints its ungated-clone warning on every run.

**Severity:** MEDIUM. The pre-push hook is described at `validate.sh:327` as "the only gate while this
repo is private (GH-544)". In a worktree on Windows it cannot be installed or verified, and the warning
that is supposed to make that state visible prints a nonsense path that sends the operator hunting.

**This is a class, not an instance.** The same POSIX-only test appears at **20+ call sites**. A second
instance was reproduced independently by the repo's own suite during this audit's `validate.sh` run —
`test/gh391-emit-marathon-yaml.sh`:
```
marathon: phase gh10: brief file not found: /c/tmp/xyz-pristine/C:/Users/.../packets/gh-10-alpha/packet.md
```
from the identical construct at `relay-automation/marathon.sh:272`. Others worth auditing together:
`relay-automation/marathon-drive.sh:1010` (`TICK_CLI`), `durable-log-lib.sh:29`, `gate-env.sh:31`, and the
`_src` symlink-resolution loops repeated across `skills/*/install.sh`.

**Environment note:** **HARNESS BUG, WINDOWS-ONLY manifestation.** On macOS/Linux `--git-common-dir` and
`readlink` return `/`-rooted paths, so the test is correct there and the bug is invisible.

**Suggested issue title:** `case "$x" in /*)` treats Windows absolute paths as relative — mangled path concatenation across 20+ sites (F8)
**Suggested labels:** bug, severity/medium, platform/windows, area/portability, `runtime:bash`
**Suggested fix:** one shared helper, e.g. `_is_abs() { case "$1" in /*|[A-Za-z]:/*|[A-Za-z]:\\*) return 0;; *) return 1;; esac; }`, and replace the inline tests with it.

**Evidence:** `audit/logs/` — the worktree `--check` output; `audit/run.log` for the gh391 instance.

---

## F9 — [MEDIUM] A forked child outlives the watchdog kill and writes into ROOT after the turn ends

**Command (probe C8):** fake agent forks a child that writes a marker at T+8s, then hangs; ceiling set to 3s.
```bash
RELAY_TURN_TIMEOUT_S=3 bash relay-automation/codex-turn.sh   # CODEX_BIN = forking stub
# then wait past the child's timer and look for the marker
```

**What the docs say would happen:** `relay-turn-lib.sh:467-469` documents this openly — "Process-group
note: `setsid` is absent on stock macOS so we kill by PID (same as consult.sh). A multi-process CLI whose
children outlive the leader is a known gap; worktree isolation is the airtight follow-up (ROADMAP 3.6)."

**What happened:** exactly as documented, now **measured**. The shim returned 7 at the ceiling. Nine
seconds later `orphan-marker.txt` was present in ROOT — a process the harness believed it had killed
wrote into the repo **after the turn had been reported closed**.

**Exit code:** 7 (correct for the leader), but the containment boundary was already breached.

**Severity:** MEDIUM. Not a new defect — the maintainer already knows and wrote it down. The value here is
that it is now a reproducible probe with evidence rather than a comment, and that the recommended
mitigation is checkable: **worktree isolation does not close it either**, because `.tick` is deliberately
shared into the worktree (`codex-turn.sh:166`) and the orphan keeps its inherited CWD.

**Environment note:** **HARNESS BUG (documented gap).** Not Windows-specific — the PID-scoped kill is the
same on macOS and Linux. Reproducible anywhere.

**Suggested issue title:** Watchdog kill is PID-scoped, so a forked child writes into ROOT after the turn closes (F9)
**Suggested labels:** bug, severity/medium, area/containment, known-gap, `runtime:bash` (verified in the Bash lib; the Python twin was NOT reachable on this host, so no `runtime:parity` claim is made)
**Suggested fix:** kill the process group where available (`setsid`/`kill -- -$pgid` on Linux, `posix_spawn`
+ process group on macOS ≥ 10.15), falling back to the current PID kill with the gap logged loudly.

**Evidence:** `audit/screens/c8-bash-2-agent.png` (the forking agent), `c8-bash-3-verdict.png`
(exit 7 plus the post-wait marker check), `c8-bash-4-after.png` (the marker sitting in ROOT).

---

## F10 — [MEDIUM] Python lane references `signal.SIGHUP`, which does not exist on Windows

**Command:** surfaced by the harness's own gate during this audit —
`bash test/gh319-gate-path-with-space.sh`.

**What happened:**
```
FAIL: dry-run at a spaced root failed (rc=1):
    for _sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
AttributeError: module 'signal' has no attribute 'SIGHUP'
```
Source: `utils/py/marathon_drive.py:2684`.

**Severity:** MEDIUM — an unconditional module-level assumption that aborts the Python marathon driver on
any Windows host. Same family as F7: the port is a faithful translation of POSIX shell into POSIX-only Python.

**Environment note:** **HARNESS BUG, WINDOWS-ONLY manifestation.**

**Suggested issue title:** `signal.SIGHUP` is unconditional in `marathon_drive.py` — AttributeError on Windows (F10)
**Suggested labels:** bug, severity/medium, area/python-port, platform/windows, `runtime:python`
**Suggested fix:** `_sigs = [signal.SIGTERM, signal.SIGINT] + ([signal.SIGHUP] if hasattr(signal, "SIGHUP") else [])`.

---

## Negative controls — containment invariants that HELD (Bash lane)

These are the point of the exercise. Each was attacked with a hostile fake agent and each held. Recorded
as INFO because the repo's culture treats a passing negative control as evidence, not as absence of news.

| ID | The attack | Documented promise | Observed | Evidence |
|---|---|---|---|---|
| **C0** | well-behaved agent (control) | exit 0, file-scoped commit, no push | **exit 0**, committed, no push | `c0-bash-*.png` |
| **C1** | `git commit` mid-turn, in-ROOT | prior HEAD → `refs/relay-orphan/`, `reset --hard`, exit 6 (`relay-turn-lib.sh:1080-1084`) | **exit 6**; HEAD back at seed; `sneaky.md` gone; `refs/relay-orphan/4fd12bb` present | `c1-bash-*.png` |
| **C2** | edit a tracked file outside the allowlist | reverted, exit 6 (`relay-turn-lib.sh:1117`) | **exit 6**; `untouchable.md` restored to baseline | `c2-bash-*.png` |
| **C3** | sleep 120s against a 5s ceiling | killed, exit 7 (`relay-turn-lib.sh:464-488`) | **exit 7**, killed on schedule | `c3-bash-*.png` |
| **C4** | exit 0 having done nothing | shim must own the token itself or exit 5 (`codex-turn.sh:124-129`) | **exit 0** — shim claimed the token, committed nothing, warned that STATUS was non-terminal with no `RELAY_PEER` | `c4-bash-*.png` |
| **C5** | off-lane edit under `RELAY_WORKTREE_ISOLATION=1` | worktree destroyed, nothing copied back, exit 6 | **exit 6**, ROOT untouched | `c5-bash-*.png` |
| **C6** | `git commit` under worktree isolation | **NOT** a reset — peer-preserve (`relay-turn-lib.sh:1064-1071`) | **preserved**, turn continued — correct | `c6-bash-*.png` |
| **C7** | off-lane edit **and** timeout together | 6 outranks 7 (`relay-turn-lib.sh:56-60`) | **exit 6**, off-lane reverted | `c7-bash-*.png` |

**C6 deserves a note.** The naive expectation is "any commit during a turn → exit 6". That is wrong under
isolation, and deliberately so: the agent cannot move ROOT's HEAD from inside a throwaway worktree, so a
moved HEAD there means a **concurrent peer** committed. The comment records that a blind reset here
orphaned a peer's commit on 2026-06-23. The probe confirms the peer commit survives. An auditor who
flagged this as a missing exit 6 would be filing a bug against a deliberate fix.

**C7 likewise.** A hung agent that also went off-lane still gets its edits reverted — the timeout does not
short-circuit enforcement, which is the correct precedence and is not obvious from the exit code alone.

---

## Observations (not filed as defects)

- **`dependency.drift` false positives.** Every successful fixture turn emitted
  `dependency.drift — codex changed relay-automation/relay-turn-lib.sh (0 lines)` for harness files the
  turn never touched, all reporting `(0 lines)`. Warn-only by design and it never blocked, but a drift
  signal that fires on a zero-line change to a file outside the fixture will train operators to ignore it.
- **A read-only `grep` tripped the relay-xyz guard hook.** `relay-automation/hooks/relay-xyz-guard.sh`
  refused a command whose only crime was containing the string `relay-automation/` in a `grep` pattern.
  Correct instinct, over-broad match.
- **The GH-177 sandbox guard did its job.** Attempting `./validate.sh` from a sandboxed shell was refused
  with a pointer to `PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md` and the exact opt-out. This is
  the best first-run error message in the repo.

---

## F11 — [HIGH] `validate.sh` recurses into itself through the pre-push hook and never terminates

**Command:**
```bash
git worktree add --detach /c/tmp/xyz-pristine origin/development
cd /c/tmp/xyz-pristine && npm install
bash githooks/install.sh          # wire the pre-push gate
./validate.sh --sequential 2>&1 | tee audit/run.log
```

**What the docs say would happen:** `test/gh544-pre-push-gate.sh:16` states the design explicitly —
*"The pre-push hook is driven with a STUB validate.sh in a throwaway repo. Running the real gate from
inside the gate would recurse."* `validate.sh:163` repeats it: the suite "drives `githooks/pre-push`
against a STUB validate.sh so it cannot recurse."

**What happened:** the gate reached suite 120 of ~200 (`gh544-pre-push-gate.sh`) and then produced **no
further output for 17 minutes**. It was not deadlocked. A process snapshot shows the protection did not
hold:

```
./validate.sh --sequential                       <- the gate the operator started
 `- test/gh544-pre-push-gate.sh                   <- suite 120
    `- githooks/pre-push                          <- the real hook, fired by the suite's push
       `- C:/tmp/xyz-pristine/validate.sh         <- the REAL gate, not the test's stub
          `- vp_run_one gh544-pre-push-gate.sh    <- the SAME suite again, in a PARALLEL pool
             `- ...pre-push fires again, and a third validate.sh starts
```

**Two nested `validate.sh` processes were live simultaneously**, each running its own parallel pool
(`marathon-root-audit.sh`, `gh308-frozen-twin-guard.sh`, `model-alias.sh` all visible in-flight). Each
level re-enters `gh544-pre-push-gate.sh`, which starts the next level. The run cannot converge.

**A second defect visible in the same snapshot:** the operator asked for `--sequential`. The nested
invocations are **parallel** — the recursive call does not inherit the mode and host-detects its own
width. Given GH-509's rule that "sequential is the only form that qualifies a claim", a nested parallel
run inside a sequential gate would corrupt the provenance of the result even if it did terminate.

**Exit code:** none. The run was killed by the auditor after **47m48s**, having entered 120 suites and
never reached a summary line.

**Severity:** HIGH. On this host the gate — per `validate.sh:327` "the only gate while this repo is
private" — **cannot produce a verdict at all**. A Windows contributor can never find out whether their
change is green.

**Root cause NOT established.** The hook resolves its target as
`REPO="$(git rev-parse --show-toplevel)"` (`githooks/pre-push:35`) and runs `$REPO/validate.sh`. Why that
resolved to the real repo rather than the test's throwaway is not something this audit pinned down, and
it is not being guessed at here. Given F8 in the same area, a path-resolution difference under Git for
Windows is the first place to look, but that is a hypothesis, not a finding.

**Environment note:** **UNKNOWN whether Windows-only.** Deliberately *not* labelled Windows-specific: the
root cause is unknown and the mechanism has no obviously platform-dependent step. Worth reproducing on
Linux before triage — if it reproduces there, it is considerably more serious than a portability bug.
**Precondition:** the hook must be installed (`bash githooks/install.sh`) for this to trigger at all,
which may be why CI has not seen it.

**Suggested issue title:** `validate.sh` recurses into itself via `githooks/pre-push` in gh544-pre-push-gate — gate never terminates (F11)
**Suggested labels:** bug, severity/high, area/gate, needs-repro/linux — **`runtime:` label deliberately omitted**: `validate.sh` and `githooks/pre-push` are not one of the dual-runtime twins, and ROUTER.md says omit rather than guess
**Suggested fix (defence in depth):** an explicit re-entrancy guard — export `XYZ_VALIDATE_ACTIVE=1` on
entry and refuse-with-explanation if it is already set. That closes the whole class regardless of why the
stub was bypassed, and makes the failure loud instead of silent.

**Evidence:** `audit/screens/gate-recursion.png` (the process tree),
`audit/screens/validate-summary.png` (the run's final state), `audit/run.log` (full output, 120 suites).

---

## What the gate did report before it recursed

120 suites entered, 159 `FAIL:` lines. They are not 159 independent defects — they collapse into the
findings above:

| Signature in `audit/run.log` | Count | Root cause |
|---|---|---|
| `rc=1` / `Traceback` / `WinError 193` | 77 | **F7** — Python lane cannot exec `bin/tick` |
| `must exit 7 on a timeout kill, got 1` | 2 | **F7** — same crash, surfaced by the parity suite |
| `AttributeError: module 'signal' has no attribute 'SIGHUP'` | 22 | **F10** |
| `brief file not found: /c/tmp/xyz-pristine/C:/Users/...` | 1 | **F8** — mangled path concatenation |

50 suites reported `0 failed`. **The harness's own suite detects every one of these findings.** It had
simply never been run on Windows — which is exactly what the "does the repo survive a stranger's first
run" milestone is asking about.

---

## Addendum — three guard hooks fired on read-only commands

Recorded because the repo's guards are good and slightly over-eager, and a first-time contributor will
read a refusal as "I broke something":

1. `relay-xyz-guard.sh` refused a **`grep`** whose only offence was containing the string
   `relay-automation/` in its pattern.
2. `gh177-sandbox-test-guard.sh` refused a **heredoc writing this very findings file**, because the text
   being written contained `./validate.sh --sequential`. It matches on command text, not on execution.
3. The same guard correctly refused the real sandboxed `validate.sh` run — and that refusal was the best
   error message encountered in the whole audit: it named the post-mortem, the blast radius, and the
   exact opt-out. The mechanism is right; the matcher is too broad.
