# RELAY · GH-72 lock fix review — TOCTOU + contention retry policy
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-01.
-->

NEXT: codex
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-72-lock-fix-review-toctou-contention-retry-policy): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: the **GH-72 advisory-lock fix** in commit `24d5869` — `acquire_advisory_lock`,
  `release_advisory_lock`, `cleanup` in **`install.sh`** and **`relay-automation/xyz-vendor.sh`** (the
  two are intentionally identical except `say` vs `note`), plus the new stress test
  `test/registry-lock-concurrency.sh`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-01
- Definition of Done: confirm the fix **fully closes** GH-72 and is safe to close the issue — i.e. the
  lock now reliably prevents a lost registry row under concurrency, with NO new correctness or
  portability regression. Verdict: **Approved** (safe to close #72) or **Changes requested** (with the
  blocking defect).

## What was fixed (verify each; the lock had TWO defects)

1. **empty-pid TOCTOU** (found by an earlier /consult): a loser reading `$lockdir/pid` before the
   winner wrote it saw an empty holder, judged the fresh lock stale, and `rm -rf`'d it. Fix: empty pid
   is treated as "winner mid-acquire → wait", never reclaimed on sight; only a pid absent ~2s (orphaned
   mkdir) or a confirmed-dead **non-empty** holder is reclaimed.
2. **retry/fail-open-under-contention defect** (found by a concurrency stress test, NOT the consult):
   the old policy used `sleep 1` + fail-open after 5 attempts, so under N-way contention losers gave up
   in ~5s and wrote **unlocked** — 16 concurrent writers landed only 7 rows. Fix: fast 0.1s retry with
   a **wall-clock** deadline (`XYZ_LOCK_WAIT_S`, default 30s); fail-open only on a genuinely stuck
   holder, never a lost fast race.
3. **ownership-checked release + cleanup**: only delete a lock whose `pid` names us (or is gone), never
   a peer's lock a reclaim may have handed off.

**Please assess, citing file:line:**
- Is there any REMAINING race that can still lose a registry row or delete a live lock under
  concurrency? (Re-examine the empty-pid path, the reclaim conditions, and release/cleanup ownership.)
- Is the fail-open still correct (never hard-fails install/vendor) and deadlock-free (registry →
  projection ordering unchanged)?
- **Portability:** `sleep 0.1` and `date +%s` — acceptable on the macOS/bash target? The code falls
  back to `sleep 1` if `sleep 0.1` fails; is that fallback sound (does it merely slow down, not break)?
- Any off-by-one / integer / `set -euo pipefail` interaction in the new loop (`empty_streak`,
  `deadline`)?
- Is `test/registry-lock-concurrency.sh` a fair regression guard, or does it have a gap that would let
  a real race pass?

Land a clear **Approved** or **Changes requested** with any blocking defect + a concrete fix.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — 2026-07-01
- [Blocker] `install.sh:297-306` and `relay-automation/xyz-vendor.sh:236-246` still bootstrap a missing registry with `> "$reg"` **before** `run_with_advisory_lock`. Two first writers can both observe "missing"; writer A can finish the locked rewrite, then writer B can truncate the file back to header-only and take the lock, dropping A's row. Concrete fix: move registry-file initialization under the same advisory lock as the read-modify-write path (for example, have the locked writer create headers in `$tmp` when `$reg` is absent, or take the lock before any `> "$reg"` bootstrap).
- [Pass] `install.sh:151-170` / `relay-automation/xyz-vendor.sh:126-145` do close the original empty-pid TOCTOU and contention fail-open defects for an already-existing lock: empty pid waits, reclaim only happens after a sustained empty streak or a confirmed-dead non-empty pid, and the wait budget is wall-clock rather than attempt-count based.
- [Pass] `install.sh:87-99,174-183` / `relay-automation/xyz-vendor.sh:59-75,149-158` keep cleanup/release from deleting a peer's handed-off lock. I also do not see a new deadlock path in the reviewed functions; the registry -> projection lock order stays one-way.
- [Pass] `sleep 0.1` plus `date +%s` is acceptable on the stated macOS/bash target, and the `sleep 1` fallback degrades latency rather than correctness there. `empty_streak >= 20` and `date +%s >= deadline` are off-by-one sane for the intended defaults.
- [Should] `test/registry-lock-concurrency.sh:33-47` is not a sufficient guard for the blocker above because it does not deliberately widen the unlocked bootstrap window; a passing stress run can miss this interleaving. Concrete fix: add a deterministic first-create race harness, or refactor bootstrap so a test can force the "missing file" interleaving before the lock is taken.
**Verdict:** Changes requested
VERDICT: FAIL
Basis: static review only; I did not run scripts in this turn per the relay instructions.

### Producer — claude-a — 2026-07-01 (round 2)
Dispositions of the round-1 findings:
- **[Blocker] unlocked registry bootstrap → Implemented** (`01de46c`). Header creation now happens
  INSIDE the locked writer (`write_install_registry_row` / `write_registry_row`) when `$reg` is absent;
  removed the unlocked `> "$reg"` from `register_install` / `register_vendor`. Bootstrap is now atomic
  under the same advisory lock as the read-modify-write, so two concurrent first-writers can't truncate
  each other's row. Verified: `validate.sh` 75/75; `test/registry-lock-concurrency.sh` (16 concurrent
  writers on a **fresh** registry — the bootstrap-contention case — ×2 rounds) stable across repeats.
- **[Should] test doesn't deterministically widen the bootstrap window → Modified/Accepted-as-limitation.**
  The bootstrap race is now eliminated *structurally* (header is under the lock), so the stress test's
  fresh-registry round 1 exercises 16 concurrent first-writers against the fixed path. I did not add a
  deterministic interleave-injection harness — with the structural fix the marginal value is low; noting
  it honestly rather than over-building.
- All your [Pass] items (empty-pid wait, wall-clock fail-open, ownership-checked release/cleanup,
  portability, no new deadlock) unchanged by this commit.

Please re-review the bootstrap fix (`install.sh` `write_install_registry_row` + `register_install`;
`relay-automation/xyz-vendor.sh` `write_registry_row` + `register_vendor`) and set **Approved** if GH-72
is now safe to close, or flag any remaining blocker.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
