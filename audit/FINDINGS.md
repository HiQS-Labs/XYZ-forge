# FINDINGS.md — XYZ-forge audit (numbered, GitHub-issue-ready)

**Audit date:** 2026-08-18 · **Auditor:** Hermes (automated technical-audit pass)
**Harness under test:** `github.com/HiQS-Suite/XYZ-forge` @ `C:\Users\<user>\XYZ-forge`
**Reproduction:** every finding below is reproduced by the kernel probe script (P1–P7), which is proposed
in #51 alongside the containment probes — no network, no API keys.
**Environment:** see `audit/ENVIRONMENT.md`. Probe host is **MINGW64/MSYS on Windows 10** (NOT WSL — labelled carefully below).

Severity scale: **HIGH** (data loss / whole-repo breakage), **MEDIUM** (invariant gap, security-adjacent), **LOW** (hygiene / input coercion), **INFO** (behaviour confirmed, no action needed).

Each entry is written so it can be pasted straight into a GitHub issue.

---

## F1 — [MEDIUM] Path-overlap guard does not block a glob lane vs a literal sub-path on claim

**Command (repro P1):**
```bash
node bin/tick log task.created P1A --agent dispatcher --priority 5 --paths "src/auth/**"
node bin/tick log task.created P1B --agent dispatcher --priority 5 --paths "src/auth/login.js"
node bin/tick claim P1A --agent claude-a --paths "src/auth/**"   # -> won
node bin/tick claim P1B --agent codex   --paths "src/auth/login.js"  # -> won (overlap accepted)
```
**What the docs say would happen:** `src/paths.js` is described as the lane-overlap detector; the architecture promises "two agents may run concurrently only if their `paths` are disjoint." `src/auth/login.js` is *contained in* `src/auth/**`, so these lanes are NOT disjoint.
**What happened:** both claims returned `won`. The second (overlapping) claim was **not** rejected.
**Exit code:** 0 (both claims succeed).
**Severity:** MEDIUM — a core safety invariant (disjoint lanes) is not enforced at claim time for glob-vs-literal containment. Note: an *exact* duplicate path (`src/auth/**` vs `src/auth/**`) IS correctly rejected (verified: second claim `lost: already claimed`). So the gap is specifically glob-vs-literal / prefix containment, not the whole overlap check.
**Environment note:** harness bug, not environment-specific — the overlap logic is pure JS in `src/paths.js`.
**Suggested issue title:** `claim` accepts a lane contained in an already-claimed glob lane (F1)
**Suggested label:** bug, severity/medium, area/coordination-kernel

---

## F2 — [LOW] Non-numeric `--priority` / `--epoch` accepted and stored verbatim

**Command (repro P2):**
```bash
node bin/tick log task.created P2  --agent dispatcher --priority "not-a-number" --paths "x"
node bin/tick log task.created P2b --agent dispatcher --epoch "abc" --paths "x"
```
**What the docs say would happen:** `priority` is an integer used for lane ordering; `epoch` is a monotonic integer fence. Inputs are assumed numeric.
**What happened:** `--priority not-a-number` was **accepted and stored verbatim** (`priority: "not-a-number"` in the event). `--epoch abc` was coerced to `null` (safe).
**Exit code:** 0.
**Severity:** LOW — the epoch path is safe (null), but a non-numeric priority string can surface as `NaN`/string in downstream `tick next` ordering and `tick analyze` metrics. No crash observed, but silent type corruption.
**Environment note:** harness bug (input coercion in `bin/tick` arg parsing), not environment-specific.
**Suggested issue title:** `log` stores non-numeric `--priority` verbatim instead of rejecting/coercing (F2)
**Suggested label:** bug, severity/low, area/input-validation

---

## F3 — [INFO] Task id containing `../` is sanitised to a safe filename segment

**Command (repro P3):**
```bash
node bin/tick log task.created "../escape" --agent dispatcher --priority 1 --paths "x"
```
**What the docs say would happen:** undocumented; safe behaviour expected.
**What happened:** event file written as `...created-.._escape.jsonl`. The `../` was normalised to `.._` by `safeSegment()` — **no path traversal** occurs (the id never leaves the filename).
**Exit code:** 0.
**Severity:** INFO — invariant holds; recording as a negative control (the harness passed this one).
**Environment note:** harness behaviour, correct.

---

## F4 — [INFO] Mutating verb from a foreign directory resolves against `TICK_REPO_ROOT`, not cwd

**Command (repro P4):**
```bash
mkdir -p foreign && cd foreign
node ../bin/tick claim P1A --agent rogue --paths "src/auth/**"
```
**What the docs say would happen:** the kernel is "cwd-independent" via `TICK_REPO_ROOT` / `git rev-parse`.
**What happened:** `lost: P1A already claimed by claude-a` — resolved against the correct repo, **not** the foreign cwd.
**Exit code:** 0.
**Severity:** INFO — invariant holds (negative control passed).
**Environment note:** harness behaviour, correct. (Caveat: if `TICK_REPO_ROOT` is unset AND cwd is not inside a git repo, `tick` falls back to cwd; see F-ENV below.)

---

## F5 — [HIGH] A single corrupted `.jsonl` in `.tick/events` poisons the entire coordination log

**Command (repro P5):**
```bash
node bin/tick log task.created P5 --agent dispatcher --priority 1 --paths "x"
printf 'this is not valid json {{{' > .tick/events/2026-08-18T13-25-30.000Z-dispatcher-created-P5.jsonl
node bin/tick project      # exit 1, throws
node bin/tick claim P5 --agent x --paths "x"   # exit 1, throws (UNRELATED task!)
```
**What the docs say would happen:** `.tick/events` is the source of truth; events are "atomic, replayable." No documented behaviour for a corrupt event file.
**What happened:** `readAllEvents()` does `JSON.parse` on every file with no try/catch. **One** corrupt file causes `Unexpected token 'h'... is not valid JSON` and **every** command that reads the log (`project`, `analyze`, `claim`, `release`, `next`, `info`) **crashes**, even for tasks that have nothing to do with the corrupt file. The error does **not** name the offending file, so the operator cannot find it without grepping.
**Exit code:** 1 (on `project`; the pipe in repro masks it, but a bare run exits non-zero and throws).
**Recovery:** manually locate and delete the bad file; kernel heals immediately (`project` exit 0 after removal, verified).
**Severity:** HIGH — a single bad byte in the event log (e.g. a crashed write, a partial append, an editor slip) takes down the **entire** multi-agent orchestration for the repo until a human intervenes blind. This is the worst failure mode for a coordination kernel whose whole value is durability.
**Environment note:** harness bug (missing per-file guard in `src/events.js:readAllEvents`). NOT environment-specific — pure JS, would reproduce identically on macOS/Linux (and is exactly the kind of thing the open Linux canary should catch).
**Suggested issue title:** One corrupt `.jsonl` in `.tick/events` crashes all log-reading commands (F5)
**Suggested label:** bug, severity/high, area/coordination-kernel, area/robustness
**Suggested fix:** wrap `JSON.parse` per-file in `readAllEvents`; on parse failure, record the file in a `.tick/corrupt.jsonl` quarantine + warn, and continue with the good events (don't let one bad file sink the projection).

---

## F6 — [INFO] Release-by-non-owner fence intact (negative control)

**Command (repro P7):**
```bash
node bin/tick claim P7 --agent owner1 --paths "y"
node bin/tick claim P7 --agent owner2 --paths "y"   # -> lost (owner1 holds)
node bin/tick release P7 --agent owner1             # -> released (legitimate owner)
```
**What happened:** only the live owner can act; the competing claim is rejected; the owner's release succeeds.
**Severity:** INFO — invariant holds.
**Environment note:** harness behaviour, correct.

---

## BUG-1 — [FIXED, VERIFIED] `appendEvent` silent event clobber on same ms+agent+action+task

(Recorded for completeness; fixed in this audit pass.)
**Root cause:** `src/events.js` built the event filename from only `ts-agent-action-task`; two same-millisecond events with identical fields produced the same filename and `fs.renameSync` overwrote the first silently.
**Fix:** append a uniqueness suffix (`-<n>`) when the target name exists.
**Verification:** `test/unit/events.test.js` now has a regression test; `node --test test/unit/*.test.js` → **12/12 pass**. repro P6 writes 50 same-ms heartbeats → 50/50 files persisted.
**Severity:** was MEDIUM (silent data loss); now resolved.

---

## Environment-specific notes (labelled, not attributed to the harness)

- **F-ENV-1 [ENV, not a bug]:** the bundled `node` is **native Windows**. The harness computes `ROOT_DIR` as an MSYS path (`/c/Users/...`); when `relay-drive.sh` invokes `tick` with that path, native `node` fails (`ENOENT: C:\c\Users\...`). **Fix/workaround:** force `TICK_BIN`/`ROOT_DIR`/`TICK_REPO_ROOT` to Windows-style `C:/Users/...` paths. On Linux/macOS (the harness's target) this does not occur. This is a **Windows/MSYS portability issue**, not a harness logic bug.
- **F-ENV-2 [ENV, not a bug]:** all shell/JS files in the repo use **CRLF**. `bash -n` passes on MSYS, but on Linux/macOS CRLF in `.sh` causes subtle failures. Recommend `.gitattributes` (`*.sh text eol=lf`). Portability hygiene.
- **Clarification on "WSL":** the probe host is **MINGW64/MSYS2 Git-Bash on Windows 10**, *not* WSL. It is a **third environment** distinct from the maintainer's macOS measurements and the open Linux canary. Any environment-tagged finding above is explicitly marked ENV and separated from harness bugs (F1, F2, F5) which are pure-JS and environment-independent.
