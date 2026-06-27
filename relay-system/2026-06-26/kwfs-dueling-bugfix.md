# Dueling Claudes — KISS-woo-fast-search gate-verifiable bug-fix loop

**STATUS:** Open
**NEXT:** claude-a
**Lock token:** see seed output (DUELING-KWFS-*)
**Reporter (claude-a):** xyz-3-agents-swarm window (this repo) — files graded reports, never edits code.
**Maintainer (claude-b):** the plugin window, CWD = the plugin repo below — verifies, fixes, runs the gate, stops for operator "go".

**Target repo (Maintainer's native CWD), absolute:**
`/Users/noelsaw/Local Sites/bloomz-prod-08-15/app/public/wp-content/plugins/KISS-woo-fast-search`
Current branch there: `BUG-FIXES-2026-06-26` (fixes commit on that branch; no push until operator go).

**Gate (objective referee):** `bash tests/run.sh` in the plugin repo. A fix is verified by red→green
on its issue's invariant — not by one Claude's opinion of another's diff. This is what makes a
same-model dueling loop trustworthy here.

---

## Scope — four gate-verifiable phases, in order

Run them strictly in this order (last one shares a file with the third):

1. **#72** — remove stale README/AUDIT.md security/perf warnings  → gate `#72` (phrase grep)
2. **#71** — `.distignore` to exclude process artifacts + swarm scaffolding from the zip → gate `#71` (file check)
3. **#68** — route HPOS edit URLs through `KISS_Woo_Order_Formatter::get_edit_url()` at the call
   site (`includes/class-kiss-woo-search.php:960`) → gate `#68` (+ confirm no `post.php?post=` literal remains)
4. **#70** — converge the three order formatters on one identical key set (incl. `payment`/`shipping`
   keys) → gate `#70` (static key-set equality)

### Out of scope — DO NOT attempt or "approve" in this loop
`#73` coupon rebuild, `#76` analytics path, `#75` cache wiring/invalidation, `#69` payment/shipping
**values**. These need production-scale data and stay in `tests/HUMAN-VERIFY.md`. The holistic gate will
read **"4 passed, 1 failed · GATE: FAIL"** after a clean run — that residual red is the `#75` key-method
human checkpoint, **not** a loop failure. Success = all four phases approved, not GATE: PASS.

---

## ▶ TAKE YOUR TURN — claude-a (Reporter, this xyz window)

1. Pick the next phase not yet reported below, in scope order (#72 → #71 → #68 → #70).
2. Append a `### REPORT — #<n>` block containing: the problem, the **exact files by ABSOLUTE plugin
   path**, the **gate needle contract** (what `tests/gate.php` checks and how to flip it green), the
   definition of done, and the explicit out-of-scope note. Do not edit any code.
3. Set `NEXT: claude-b`, release the lock to claude-b, commit this relay file in the xyz repo (no push).
4. If every phase is reported AND approved by the Maintainer, set `STATUS: Closed`.

## ▶ TAKE YOUR TURN — claude-b (Maintainer, the plugin window)

1. Read the latest unaddressed `REPORT — #<n>` above.
2. Verify it against the real plugin code. Fix it with the **smallest change** in this (plugin) repo.
3. Run `bash tests/run.sh`; record the before→after gate delta for that issue.
4. Append a `### FIX — #<n>` block: diff summary, the gate delta (e.g. `#70: FAIL → PASS`), and where
   the transcript landed. Set `NEXT: claude-a`.
5. **SHOW THE OPERATOR THE DIFF AND STOP.** Do not commit, push, or release the token until the
   operator says "go".
6. After "go": commit the code fix in the plugin repo (no push); stage+commit this relay file with
   `git -C "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm"`; then release the lock to claude-a.

---

## Turn log

_(empty — Reporter takes the first turn when its loop fires)_
