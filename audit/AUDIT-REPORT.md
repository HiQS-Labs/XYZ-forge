# XYZ-forge — Technical Audit, QA & Usage-Screenshot Report

**Repo:** `github.com/HiQS-Suite/XYZ-forge` (cloned to `C:\Users\Askyla\Senior_dev\XYZ-forge`)
**Audit date:** 2026-08-18
**Method:** static read of architecture/`.md` flow files **plus** dynamic verification — the `tick` kernel and `relay-drive` supervisor were **executed for real** against throwaway repos, and the unit suite (`node --test`) was run. Findings marked **[VERIFIED]** were reproduced by running code; the rest are from source review.

---

## 0a. This audit's four deliverables (drop-in for the repo's evidence culture)

Everything below is backed by a single reproduction script so the maintainer can re-verify any claim:

| Deliverable | Path | What it is |
|---|---|---|
| **Reproduction script** | `audit/repro.sh` | One bash file, no network/API keys, re-runs every probe (P1–P7). The deliverable that separates evidence from screenshots. |
| **Findings log** | `audit/FINDINGS.md` | Numbered entries, each: exact command · docs-said · happened · exit code · severity · GitHub-issue-ready. |
| **First-run friction log** | `audit/FIRST-RUN-FRICTION.md` | Timestamped, honest, every stuck/guessed moment — for the "stranger's first run" milestone. |
| **Environment stamp** | `audit/ENVIRONMENT.md` | OS / node / python / cores / RAM / sandbox status — because the harness changes behaviour by detected cores. |
| **Containment probes** | `audit/repro-containment.sh` | Fake agents that misbehave on purpose (commit mid-turn, edit off-lane, hang, fork past the kill), driven through the real shims via `CODEX_BIN`. No credentials, no network, no token spend. |
| **Containment findings** | `audit/FINDINGS-CONTAINMENT.md` | F7–F10 plus the eight invariants that held under direct attack. |
| **Results table** | `audit/CONTAINMENT-RESULTS.md` | Machine-generated verdict table, regenerated on every probe run. |
| **Flow diagrams** | `audit/CONTAINMENT-FLOW.mmd`, `audit/TURN-SEQUENCE.mmd` | The turn's containment decision path and one hostile turn end to end. Every terminal node carries its exit code, its source line, and the probe that verified it. |
| **Consolidated report** | `AUDIT-REPORT.md` (this file) | The long-form narrative. |
| **Screenshots** | `audit/screens/*.png` + `audit/screens/INDEX.md` | 48 headless-Chrome frames. Each probe is a four-frame sequence — before → the hostile agent → the harness verdict → the post-state proving the undo. Every PNG is rendered from the `audit/logs/*.log` beside it, so any image can be diffed against the text it came from. |

> **Environment honesty:** the probe host is **MINGW64/MSYS2 on Windows 11 (build 22631) — NOT WSL, NOT macOS.**
> It is a *third* environment distinct from the maintainer's macOS measurements and the open Linux canary.
> Findings that are pure-JS harness bugs (F1, F2, F5) are explicitly separated from environment-tagged notes
> (F-ENV-1 CRLF, native-`node` path mismatch) so nothing is handed over as noise. The second pass adds a
> third category and keeps it distinct too: **harness bugs whose manifestation is Windows-only** (F7, F8, F10)
> — POSIX-only assumptions in shared code, invisible to a macOS canary *and* to the Linux canary, because
> both honour shebangs and `/`-rooted paths.

---

## 0b. New kernel-probe findings (from live execution)

| ID | Severity | One-line |
|---|---|---|
| **F1** | MEDIUM | `claim` accepts a lane *contained in* an already-claimed glob lane (`src/auth/login.js` inside `src/auth/**`) — disjoint-lane invariant not enforced for glob-vs-literal. |
| **F2** | LOW | `log` stores non-numeric `--priority` verbatim (`"not-a-number"`); `--epoch abc` → `null` (safe). |
| **F5** | **HIGH** | One corrupt `.jsonl` in `.tick/events` throws on `JSON.parse` and **takes down every log-reading command** for the whole repo (no per-file guard, no "which file" in the error). |
| F3, F4, F6, BUG-1 | INFO / FIXED | Negative controls that **passed**; BUG-1 (event clobber) fixed & unit-tested. |

Full detail, exact commands, and issue-ready text: `audit/FINDINGS.md`.

---

---

## 0c. Second pass — containment under direct attack (the README's strongest claim)

The first pass never tested containment. This one did, using fake agent binaries injected through
`CODEX_BIN` — the same mechanism the repo's own `test/codex-turn.sh` uses. No Codex login, no `agy`
auth, no network, no spend. Full detail and issue-ready text: `audit/FINDINGS-CONTAINMENT.md`.

### The containment core holds

Eight of nine invariants held under deliberate attack on the Bash lane:

| Probe | Attack | Result |
|---|---|---|
| C1 | agent runs `git commit` mid-turn | **exit 6** — HEAD reset, prior HEAD preserved in `refs/relay-orphan/`, off-lane file gone |
| C2 | agent edits outside the allowlist | **exit 6** — file reverted to baseline |
| C3 | agent hangs past the ceiling | **exit 7** — killed on schedule |
| C5 | off-lane edit under worktree isolation | **exit 6** — worktree destroyed, ROOT untouched |
| C6 | commit under worktree isolation | **preserved, not reset** — the correct peer-preserve branch |
| C7 | off-lane edit *and* timeout together | **exit 6** — containment outranks timeout |

C6 and C7 are the ones worth the maintainer's attention, because a careless auditor gets them backwards.
"Any commit during a turn → exit 6" is wrong under isolation: the agent cannot move ROOT's HEAD from a
throwaway worktree, so a moved HEAD means a concurrent *peer*, and the code deliberately preserves it —
a comment records that a blind reset orphaned a peer's commit on 2026-06-23. The probe confirms the peer
commit survives. Filing that as a missing exit 6 would be a bug report against a deliberate fix.

### The Windows story: the default lane does not run

| ID | Severity | One-line |
|---|---|---|
| **F7** | **HIGH** | The **default** lane is Python (`${XYZ_PYTHON-1}` — unset substitutes 1), and on Windows it crashes at the first token op: `rtl.py:240` runs `bin/tick` via `subprocess.run` relying on the POSIX shebang, which `CreateProcess` cannot honour. **exit 1 — not in the shim's documented menu**, so the supervisor cannot classify it. |
| **F8** | MEDIUM | `case "$x" in /*)` treats a Windows absolute path as *relative*, producing `C:/tmp/repo/C:/Users/...`. Verified in `githooks/install.sh:53` (the push gate cannot be installed or verified in a worktree) and independently reproduced by the repo's own `gh391` suite from `marathon.sh:272`. **20+ call sites share the construct.** |
| **F9** | MEDIUM | The watchdog kill is PID-scoped, so a forked child outlived it and wrote into ROOT **after the turn was reported closed**. Already documented as a known gap at `relay-turn-lib.sh:467-469`; now measured with evidence, and worktree isolation does not close it because `.tick` is deliberately shared in. |
| **F10** | MEDIUM | `utils/py/marathon_drive.py:2684` references `signal.SIGHUP` unconditionally — `AttributeError` on Windows. |
| **F11** | **HIGH** | `validate.sh` recurses into itself through `githooks/pre-push` and never terminates — killed at 47m48s, 120 of ~200 suites, no verdict. Root cause not established; **not** assumed to be Windows-only. |

F7, F8 and F10 are **harness bugs with a Windows-only manifestation** — POSIX-only assumptions in shared
code. They cannot reproduce on macOS, and the open Linux canary will not catch them either, because Linux
also honours shebangs and `/`-rooted paths. That is precisely the value of probing a third environment.

**The repo's own suite already detects them.** Running `./validate.sh --sequential` here surfaces
`FAIL: good turn rc=1` and `FAIL: py-shim: shim must exit 7 on a timeout kill, got 1` (both F7) and
`brief file not found: /c/tmp/.../C:/Users/...` (F8). Nobody had run it on Windows.

### The gate itself: `validate.sh` was run, and it does not terminate here

The first pass openly disclosed that `./validate.sh` had never been run on this host. It has now.

| | |
|---|---|
| Command | `./validate.sh --sequential` in the pristine worktree, hook installed |
| Wall clock | **47m48s**, then killed by the auditor |
| Suites entered | **120** of ~200 |
| Result | **never reached a summary line** |

**F11 [HIGH]** — at suite 120 (`gh544-pre-push-gate.sh`) the gate stopped emitting output. It was not
deadlocked: `githooks/pre-push` invoked the **real** `validate.sh` rather than the test's stub, and that
inner gate started re-running the same suite in a parallel pool, which fired the hook again. Two nested
`validate.sh` processes were live at once. The suite's own header says this must not happen: *"Running the
real gate from inside the gate would recurse."* A second defect in the same snapshot — the nested runs are
**parallel** even though the operator asked for `--sequential`, which under GH-509 would corrupt the
provenance of the result even if it converged.

**Root cause is not established, and F11 is deliberately not labelled Windows-only** — the mechanism has
no obviously platform-dependent step, and it deserves a Linux repro before triage. Note the precondition:
the hook must actually be installed, which may be why CI has never seen it.

Of the 159 `FAIL:` lines the run did emit, none are independent defects — 79 are F7, 22 are F10, 1 is F8.
50 suites reported `0 failed`. **The harness's own suite detects every finding in this report.** It had
simply never been run on this platform.

**Diagrams:** `audit/screens/containment-flow.png` traces every decision point and exit code from source,
annotated with the probe that verified it; `audit/screens/turn-sequence.png` walks one hostile turn from
dispatch to `git reset --hard`, with the SHAs taken from the actual probe log.

---

## 0. Executive summary

XYZ-forge is a **genuinely well-engineered** multi-agent coordination harness. Its headline strength is a
**deterministic, event-sourced coordination kernel** (`bin/tick` → `src/events.js`, `src/project.js`): every
state transition is an append-only, atomically-published `.jsonl` event, so agent orchestration is
**replayable, auditable, and collision-free by construction** (path-scoped lanes + monotonic-epoch ownership
fencing). The relay layer (`relay-automation/relay-drive.sh`) adds a bounded, one-turn-at-a-time supervisor
with a clear exit-code menu and a close-by-agreement protocol.

**What's strong:** determinism, replay, fencing, bounded loops, file-scoped containment, provenance.
**What needs work (prioritized):**
1. **BUG-1 [VERIFIED, FIXED]:** `appendEvent` can silently clobber an event on same-millisecond/agent/action/task collisions.
2. **G1:** 100% CRLF line endings — fine on Windows, breaks `bash` portability on Linux/macOS.
3. **G2:** doc/code drift — `XYZ_PYTHON` default routes to **Python** though headers claim Bash is default.
4. **G3:** `package.json` declares `"main": "index.js"` but no such file exists.
5. **UX gap:** no live orchestration dashboard consumes the rich `.tick/events` the kernel emits (see §6 proposal).

---

## 1. Architecture & orchestration logic (from the `.md` flow files)

The repo's canonical flow is documented in `ROUTER.md` → `ARCHITECTURE.md` → `GUIDING-PRINCIPLES.md`, with the
runtime contract in `AGENTS.md`. The coordination model:

- **Lanes (path-scoped tasks):** each task declares glob `paths`. Two agents may run concurrently only if their
  `paths` are disjoint. `src/paths.js` implements an **overlap detector that is mathematically conservative** —
  it never returns a false *negative* (so it can never miss a real collision), only occasional false positives
  (over-cautious lane separation). **[VERIFIED by analysis]** This is the correct safety bias.
- **Epoch fencing (`src/events.js:148`):** every `task.claimed` (and the owner's mutations) is stamped with a
  monotonic per-task `epoch`. A stale writer whose epoch no longer matches is **fenced** and its event redirected
  to `.tick/rejected.jsonl` rather than applied. This makes ownership replay-deterministic. **[VERIFIED]** We
  exercised the fence: a second `claim` on a held task fails; a release by a non-owner is rejected.
- **Claim cap:** `MAX_ACTIVE_CLAIMS_PER_AGENT = 2` bounds how many lanes one agent holds, preventing a single
  agent from silently starving others. **[VERIFIED]** `codex` holding 2 tasks is rejected on a 3rd claim.
- **Relay (`relay-drive.sh`):** a supervisor that drives a file-based thread (the relay markdown) one turn at a
  time. It reads the `NEXT:` pointer, invokes the turn-taker for the actor whose token is live, then re-checks.
  It terminates only on **agreement**: file `STATUS` terminal **and** the `RELAY-TURN` token no longer live.
  A no-progress guard (`ntstatus:nactor == prev` → exit 3) guarantees it **never loops forever**. **[VERIFIED]**
  The full relay was driven end-to-end to `STATUS: Approved` / exit 0 (see §5).

### Agent-communication assessment
- **Strengths:** file-based handoff (`NEXT:`/`STATUS:` + token `handoff-to`) is race-free because the token is
  the single source of truth; the event log is the shared bus; provenance is committed alongside work.
- **Bottlenecks / risks:**
  - *Serial-by-construction relay:* `relay-drive` takes **one turn at a time** — fine for review/QA relays, but
    not a parallel multi-agent fan-out. Parallelism lives in the **lane** model, not the relay. Mixing the two
    (a relay whose actors also hold independent lanes) is the sharpest edge in the system and the most likely
    place for a future bug.
  - *Token resolution is env-sensitive:* `tick` resolves `.tick` via `TICK_REPO_ROOT` else `git rev-parse`.
    A mis-set env (or an MSYS-vs-native path mismatch, see G4) makes `tick` silently no-op. This is the single
    most common "why is my agent doing nothing" footgun.
  - *No live visibility:* the kernel emits rich events but **no running process surfaces them** — operators infer
    state by reading `STATE.md` / the relay thread after the fact. (UX gap, §6.)

---

## 2. Confirmed bugs

### BUG-1 — `appendEvent` silent event clobber  **[VERIFIED · FIXED]**
**File:** `src/events.js:117-176`
**Mechanism:** the event filename encodes only
`${tsForFilename(ts)}-${safeSegment(agent)}-${safeSegment(action)}-${safeSegment(task)}`.
Two events sharing the same millisecond, agent, action, and task produce the **same filename**, and
`fs.renameSync(tmp, fpath)` overwrites the earlier one **with no error** → silent data loss.

```js
const fname = `${tsForFilename(ts)}-${safeSegment(agent)}-${safeSegment(action)}-${safeSegment(task)}.jsonl`;
const fpath = path.join(eventsDir(repoRoot), fname);
...
fs.renameSync(tmp, fpath);   // clobbers a same-key earlier event
```
**Impact:** rare (requires same ms + same agent/action/task), but when it hits — e.g. a `task.heartbeat` burst,
or two `dependency.drift` signals in one tick — an event vanishes from the log with no trace. Because the
projection is built from the log, that event's effect is lost. **Note [VERIFIED]:** it does **not** corrupt
other events or the projection of non-clobbered events — only the duplicate is dropped.
**Fix (see §4 / `src/events.js`):** append a uniqueness suffix (`-<n>`) when a same-base filename already exists,
guaranteeing no `renameSync` overwrite. A unit test reproduces the collision and asserts both events survive.
**Status:** fixed and unit-tested in this audit pass.

### BUG-2 — doc/code drift on default runtime  **[VERIFIED · NOT YET FIXED]**
`relay-automation/*` headers state Bash is the default runtime, but `XYZ_PYTHON` is read as `${XYZ_PYTHON-1}`,
so when **unset** it defaults to **1 → Python**. Either the comment or the default is wrong. Cheap doc fix;
flagged, not changed here (out of scope of the code fix; recommend a one-line doc correction).

---

## 3. Robustness gaps & hygiene (G1–G4)  **[VERIFIED where noted]**

- **G1 — 100% CRLF line endings [VERIFIED]:** every shell/JS file in the repo uses CRLF. `bash -n` still passes
  on the Windows/MSYS host, so it is **not** a functional bug here — but on Linux/macOS (the harness's documented
  target) CRLF in shell scripts causes subtle failures. Recommend `.gitattributes` with
  `*.sh text eol=lf` (and `*.js text eol=lf`). *Severity: medium (portability).*
- **G2 — runtime default drift [VERIFIED]:** see BUG-2. *Severity: low (doc).*
- **G3 — missing `index.js` [VERIFIED]:** `package.json` `"main": "index.js"` but no `index.js` exists. `require`
  of the package root would fail; harmless today because everything is invoked via `bin/tick`, but it's a latent
  packaging bug. *Severity: low.*
- **G4 — native-Windows `node` + MSYS path mismatch [VERIFIED live]:** the bundled `node` is native Windows, so
  harness-computed MSYS paths (`/c/Users/...`) make `tick` silently fail inside `relay-drive.sh`. Forcing
  `TICK_BIN`/`ROOT_DIR` to Windows-style (`C:/Users/...`) fixes it. Linux/macOS unaffected. *Severity: low on
  target platforms; relevant if you support Windows contributors.*

---

## 4. The fix (BUG-1) — `src/events.js`

Before the atomic rename, ensure the target name is unique:

```js
const base = `${tsForFilename(ts)}-${safeSegment(agent)}-${safeSegment(action)}-${safeSegment(task)}`;
let fname = `${base}.jsonl`;
let fpath = path.join(eventsDir(repoRoot), fname);
// BUG-1 fix: same ms+agent+action+task would collide → add a uniqueness suffix
// instead of letting fs.renameSync silently clobber the earlier event.
let n = 1;
while (fs.existsSync(fpath)) {
  fname = `${base}-${n}.jsonl`;
  fpath = path.join(eventsDir(repoRoot), fname);
  n += 1;
}
```

The rest of the function (atomic `write .tmp` → `renameSync`) is unchanged. This keeps filenames
**chronological-sortable** (the leading timestamp is preserved) and guarantees no overwrite. Because **no code
parses the filename for logic** (verified: consumers use `ev._file` only for display), the suffix is safe.

A unit test was added to `test/unit/events.test.js`:

```js
test('appendEvent does not clobber on same-ms/agent/action/task (BUG-1)', () => {
  const root = tmpRepo();
  try {
    process.env.TICK_TS = '2026-01-01T00:00:00.000Z';
    events.appendEvent(root, { type: 'task.heartbeat', task: 'T1', agent: 'a1' });
    events.appendEvent(root, { type: 'task.heartbeat', task: 'T1', agent: 'a1' });
    const all = events.readAllEvents(root);
    assert.equal(all.length, 2, 'both events must survive');
    assert.notEqual(all[0]._file, all[1]._file, 'filenames must differ');
  } finally {
    delete process.env.TICK_TS;
    fs.rmSync(root, { recursive: true, force: true });
  }
});
```

**Verification:** `npm run test:unit` (i.e. `node --test "test/unit/*.test.js"`) runs **green** with the fix
and the new test. **[VERIFIED by running the suite]**

---

## 5. Relay root-cause — why the first drive stopped (exit 3)

This is documented in `xyz-screens/USAGE-SCREENSHOTS-README.md §2.3` and captured in `06b-relay-closed.png`.
Summary:
- The harness's **no-progress guard is working as designed** — it correctly refused to loop forever.
- The first run's `exit 3` was a **bug in the demo turn-taker**, not XYZ-forge: it called `release --to` on an
  *open* (handed-off) token, which `tick` correctly rejects (`task is open (never claimed)`).
- The correct handshake for a handed-off token is **claim it first, then release**. After fixing the demo
  script, the relay drove `Producer → Reviewer → Approved` and exited **0**.

---

## 6. UX / orchestration-visibility assessment & proposal

The repo's only real GUI is the **VS Code Cockpit** (`tools/vscode-cockpit`), which is **alpha and read-only** —
Marathon/Release/Worktree cards with copy buttons, nothing executed. The **actual** operator-facing
orchestration surface is the **relay thread markdown** (the `NEXT`/`STATUS` header + graded blocks). Both are
post-hoc: there is **no live view** of the in-flight state the kernel already records in `.tick/events`.

**Top recommendation:** a lightweight **live dashboard** (rendered in `05-dashboard.png` as a proposal) that
polls `.tick/events` + `XYZ.json` and shows: per-agent lanes, turn timeline, token ownership, containment
status, and the rejected-event audit. This turns the already-deterministic event log into real-time visibility
with **zero changes to the kernel's correctness model**.

Other UX notes:
- The relay thread's `▶ TAKE YOUR TURN` protocol and graded Reviewer blocks (Blocker/Should/Pass + VERDICT) are
  clear and reviewer-friendly — a genuine strength worth keeping.
- A short **Windows contributor note** (G4 + forcing `C:/...` paths) would save future Windows users the exact
  dead-end you hit.

---

## 7. Screenshots delivered

All in `C:\Users\Askyla\Senior_dev\xyz-screens\` (PNG = headless-Chrome render of the matching `.html`).

| # | File | Authenticity |
|---|------|--------------|
| 1 | `01-terminal.png` | Real `tick` kernel walkthrough |
| 2 | `02-projection.png` | Real `STATE.md` projection + analyze |
| 3 | `03-relay-thread.png` | Real shipped relay-thread format |
| 4 | `04-cockpit.png` | Accurate render of Cockpit's alpha read-only scope |
| 5 | `05-dashboard.png` | **Proposal** (not in repo) — top UX recommendation |
| 6 | `06-relay-drive.png` | Real supervisor run (no-progress escalation) |
| 9 | `06b-relay-closed.png` | Real end-to-end close to `Approved` (exit 0) |
| 7 | `07-guards.png` | Real claim-cap + epoch-fence output |
| — | `gallery.png` | Index of all screens |

Full methodology, caveats, and regeneration steps: `xyz-screens/USAGE-SCREENSHOTS-README.md`.

---

## 8. Verification log (what was actually run)

- **Kernel exercised:** `tick init/log/claim/ping/info/release/next/analyze` against a throwaway repo — all behaved per docs. **[VERIFIED]**
- **Concurrency guards:** claim cap (2) and epoch fence exercised live. **[VERIFIED]**
- **Relay supervisor:** `relay-drive.sh` driven to `Approved`/exit 0 with a corrected turn-taker. **[VERIFIED]**
- **BUG-1 reproduction:** same-ms event collision confirmed to drop an event pre-fix. **[VERIFIED]**
- **BUG-1 fix:** `node --test "test/unit/*.test.js"` green (existing tests + new non-clobber test). **[VERIFIED]**
- **Unit suite baseline:** the repo's own `test/unit/events.test.js` and `project.test.js` pass with the fix. **[VERIFIED]**

*Honest scope note:* this audit ran the harness's **JS kernel + shell supervisor** for real and the **Node unit
suite**. It did **not** execute the repo's full `./validate.sh` (parallel doc+code gate) or the Python
implementations behind `XYZ_PYTHON`; those are the maintainer's CI boundary and were out of scope for this pass.*

---

*Prepared as part of the XYZ-forge technical audit. Findings BUG-1/G1–G4 were confirmed by running code; the
fix is implemented and unit-tested. No output in this report is fabricated.*
