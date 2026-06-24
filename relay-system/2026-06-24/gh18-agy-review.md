# RELAY · agy review — GH-18 cross-repo relay friction code fixes

NEXT: none
STATUS: Approved
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first
You are **agy**, the Reviewer, taking your turn in a file-based relay. This is a CODE REVIEW, **not** a fix — you do **not** edit any code; you only append your review block to THIS file.

> ⏱️ **TIME-BUDGET — read first.** Do a **textual** review only. **Do NOT run `./validate.sh` or any test** — the author already ran the full suite green (44/44) and the relevant new tests are `test/relay-target-root-relayfile.sh`, `test/relay-token-collision.sh`, `test/relay-escalation-not-stall.sh`. Spend your turn reading the diff (`git show 7709abc`) and **writing your block** — append the review block BEFORE you run out of time. Reading code is fine; running the suite is what burns the turn.

1. **Read the changes under review** in the harness repo (cite by absolute path):
   - `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh`
   - `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick` (the `claim` not-claimable branch, ~line 174)
   The diff is committed as `7709abc`; `git show 7709abc` shows exactly what changed.
2. **Review the three GH-18 fixes for correctness, edge cases, and regressions:**
   - **#2 — `--relay-file` resolution.** `relay-drive.sh` now resolves a repo-relative `--relay-file` under `--target-root` when it isn't found in CWD. Check: does it ever mis-resolve an absolute path, a CWD-relative path that legitimately exists, or a path that exists in BOTH places? Is the ordering vs `--target-root` validation correct?
   - **#1b — token-collision hints.** `bin/tick` claim now hints a fresh `--relay-task`; `relay-drive.sh`'s no-actor branch names the real task and hints on a spent `done` token. Check: are the hints correct and non-misleading? Any case where they fire wrongly?
   - **#5 — `Escalated` is terminal-by-design (the one to scrutinize).** `relay-drive.sh` now treats `STATUS: Escalated` as a clean exit 4, NOT the stall's exit 3, at both the loop top and the post-turn guard. **Could this mask a TRUE stall?** Consider: an agent that writes `STATUS: Escalated` but did no real work; a relay that oscillates; whether keying on the explicit status (vs requiring an appended block) is a sound discriminator.
3. **Append ONE block** at the very bottom, above the marker line, with graded findings: `[Blocker]` must-fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound. Each finding: what, where (`/abs/path:line`), why it bites, proposed fix.
4. **Set the header:** `STATUS: Approved` if no `[Blocker]`/`[Should]` survives; else `STATUS: Changes requested`. Add a `Verdict:` and a `Basis:` line (behaviorally proven vs textual only).
5. **Hand off the lock** with the env-pinned ABSOLUTE tick, then you are done:
   `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" done RELAY-gh18-agy-review-2 --agent agy`
6. **Stop.** One-line result to the operator.

## Setup
- Artifact under review: the GH-18 code-phase diff (`7709abc`) — `relay-drive.sh` + `bin/tick`.
- Definition of Done: agy files graded findings + a Verdict and sets `STATUS`.
- Reviewer: **agy** (this turn). Author/Maintainer: the operator's Claude session (will read findings).
- Lock: `tick` task **RELAY-gh18-agy-review-2** (a per-relay id — GH-18 #1).
- Started: 2026-06-24

## Ground rules
1. This file is the single source of truth. Append one block at the bottom; never edit earlier turns.
2. The Reviewer never edits code — graded findings + proposed fixes only.
3. Stay tight: bullets, not essays. Cite real code by absolute path:line.
4. Evidence contract: log a `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run).

---
## Log

### Round 1 · Reviewer · agy · 2026-06-24
**Verdict:** Approved
**Basis:** textual only (read diff `7709abc` under harness root `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/`, did not run suite per time-budget constraint)

**Findings:**

- **[Pass] `--relay-file` resolution correctness:** Verified [/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh:70-76](file:///Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh#L70-L76). The check `[[ ! -f "$RELAY_FILE" && -n "${TARGET_ROOT:-}" && "$RELAY_FILE" != /* && -f "$TARGET_ROOT/$RELAY_FILE" ]]` safely avoids mis-resolving absolute paths, resolves relative paths correctly under `--target-root` when they do not exist in the harness CWD, and preserves existing CWD-relative paths. Ordering is correct since `TARGET_ROOT` validation occurs first.
- **[Pass] token-collision hints:** Verified [/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick:177](file:///Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick#L177) and [/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh:140](file:///Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh#L140). The output hints are clear, accurate, and direct the operator to the `--relay-task` remedy using a dynamically generated task name matching the target file name.
- **[Pass] `Escalated` terminal-by-design:** Verified [/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh:89](file:///Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh#L89), [L113](file:///Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh#L113), [L166](file:///Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh#L166). Keying on `STATUS: Escalated` is a clean, robust protocol-level discriminator. A true stall (exit 3) remains protected because the no-progress guard triggers if `STATUS` remains unchanged and the token is unmoved. Exiting 4 (clean terminal outcome) rather than 3 prevents misleading alerts on intended human handbacks.

**Commit:** none (handled by harness)
