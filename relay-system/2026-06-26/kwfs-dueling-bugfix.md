# Dueling Claudes — KISS-woo-fast-search gate-verifiable bug-fix loop

**STATUS:** Open
**NEXT:** claude-b
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

### REPORT — #72 (Reporter / claude-a)

**Issue:** stale README/AUDIT.md security & performance warnings (documentation, low).

**Problem:** The README "Security & Performance Notes" section and all four `AUDIT.md` findings still
warn users about issues that are **already fixed** — XSS via unescaped JS, unbounded `all_with_meta`
customer loads, `wc_get_orders limit => -1` counting, and the `esc_attr` benchmark. All resolved in
commits `2a9398b`, `58ccc06`, `068a37e`. The docs currently scare users about non-existent bugs.

**Files (ABSOLUTE, plugin repo):**
- `/Users/noelsaw/Local Sites/bloomz-prod-08-15/app/public/wp-content/plugins/KISS-woo-fast-search/README.md`
- `/Users/noelsaw/Local Sites/bloomz-prod-08-15/app/public/wp-content/plugins/KISS-woo-fast-search/AUDIT.md`

**Gate needle contract:** the gate verifies this by **grepping for specific stale phrases** in
`tests/gate.php`. Open `tests/gate.php`, find the `#72` needle list, and ensure **none** of those exact
phrases remain in README.md / AUDIT.md. The gate fails on *presence* — you must **remove** the
offending sentences, not append "(Fixed)". Annotating in place will leave `#72` RED.

**Definition of done:**
- `bash tests/run.sh` shows the `#72` invariant **PASS** (FAIL → PASS).
- No remaining doc text implies any of the four findings is still open; any retained note is phrased as
  resolved with the commit refs above.

**Out of scope:** docs only — touch no code, no other files.

**NEXT:** claude-b — verify, fix smallest, run the gate, capture the `#72` FAIL→PASS delta, show the
diff, stop for operator "go".

---

### FIX — #72 (Maintainer / claude-b)

**Verified against real code first** (so I wasn't deleting a still-valid warning):
- `admin/kiss-woo-admin.js` calls `escapeHtml` 35× → XSS warning is stale.
- `includes/class-kiss-woo-search.php` uses `wc_customer_lookup` + `COUNT(*)` → unbounded-query warning is stale.
- `grep "limit.*=>.*-1" includes/` → 0 hits → the `limit => -1` counting finding is stale.
All three claimed-fix commits (`2a9398b`, `58ccc06`, `068a37e`) are consistent with current code.

**Smallest change (docs only, no code touched):**
- `README.md` — rewrote the two "Security & Performance Notes" bullets to state the issues are resolved (with commit refs). Removed the gate needle phrases `without escaping` and `unbounded WooCommerce queries`.
- `AUDIT.md` — collapsed the 4-row Findings table to a `Status` column marking every finding **RESOLVED** with its commit ref; intro now says "All findings below have been resolved." Removed the gate needle phrases `could be rendered as HTML/JS in the admin view` and `loads every order object to count them`. No finding reads as open.

**Gate delta (`bash tests/run.sh`):**
- `#72`: **FAIL → PASS** (all 4 needle checks green: README ×2, AUDIT ×2).
- Holistic: `3 passed, 8 failed` → `7 passed, 4 failed`. Residual 4 = `#70` (×2), `#71`, `#75` key-method — out of scope for this phase, expected red. `GATE: FAIL` overall is expected per the scope note (success = phase approved, not GATE: PASS).

**Transcript:** this Claude Code session — plugin window, CWD = the target plugin repo, branch `BUG-FIXES-2026-06-26`. Code/doc edits are uncommitted in the working tree pending operator "go".

**NEXT:** claude-a — review the diff, then report the next phase in scope order (`#71`).

---

### REPORT — #71 (Reporter / claude-a)

**Issue:** process artifacts shipped in the plugin distributable (packaging, low).

**Problem:** `relay-system/` and `PROJECT/` (QA transcripts, working/design docs) are tracked for
history but would land in the distributed plugin zip. The dueling/marathon scaffolding now adds more
that must never ship.

**Files (ABSOLUTE, plugin repo):**
- `/Users/noelsaw/Local Sites/bloomz-prod-08-15/app/public/wp-content/plugins/KISS-woo-fast-search/.distignore` (create)

**Gate needle contract:** the gate's `#71` check in `tests/gate.php` is a pure file assertion — open it,
read exactly what it requires `.distignore` to contain, and satisfy that. At minimum it expects
`relay-system/` and `PROJECT/` excluded. **Also exclude the swarm/test scaffolding** so it never ships:
`.tick/`, `tests/`, `.claude/`, `MARATHON.yaml`, `phases-briefs/`, `phases/`. (The plugin tree already
has an untracked `.claude/` and will get a `.tick/` from any local run — both must be excluded.)

**Definition of done:**
- `bash tests/run.sh` shows the `#71` invariant **PASS** (FAIL → PASS).
- Exclusion only affects the build artifact; nothing is removed from version control (history intact).
- A staged/built zip would contain none of: `relay-system/`, `PROJECT/`, `.tick/`, `tests/`, `.claude/`,
  `MARATHON.yaml`, `phases-briefs/`, `phases/`.

**Out of scope:** no code, no build-tool rewrite — just the ignore list.

**NEXT:** claude-b — verify, create `.distignore`, run the gate, capture the `#71` FAIL→PASS delta,
show the diff, stop for operator "go".

---
