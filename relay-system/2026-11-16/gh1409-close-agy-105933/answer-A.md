### (1) Short Direct Answer

**Yes, issue #1409 should be closed as completed, conditioned on filing a dedicated follow-up issue for the `development` branch protection / bot-bypass policy.** 

All code, workflow logic (R1–R5), and manual verification controls specified in the approved implementation plan ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:59-75`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L59-L75)) landed in `development` via PR #1413 (`efcfc6140`), and the hosted label exception was subsequently exercised by PR #1494. The only outstanding item from Phase 0—branch protection on `development`—was formally designated a non-goal ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:17`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L17)) because it is hard-blocked on an unscheduled operator design decision regarding `wave-reconcile.yml:41-48`. Leaving #1409 open misrepresents completed delivery as active work.

---

### Analysis of Consult Questions

#### 1. Phase 0, 1, and 2 Item Mapping

* **Phase 0:**
  * *Add `.github/CODEOWNERS` over judge files:* **Dropped by accepted decision.** Dropped on 2026-11-10 because this is a single-maintainer repo where GitHub ignores self-approval ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:16`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L16); [`gh1409-final-qa.md:15-16`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/relay-system/2026-11-10/gh1409-final-qa.md#L15-L16)).
  * *Require `vendored smoke gate` on `main`:* **Delivered.** Applied via GitHub repository branch protection settings on 2026-11-10 ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:53-54`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L53-L54)).
  * *Require `vendored smoke gate` on `development`:* **Still Open / Blocked.** Designated a non-goal pending an operator bot-bypass policy ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:17, 55-56`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L17-L56)).
* **Phase 1:**
  * *Resolve trusted BASE_SHA (merge ref's first parent):* **Delivered.** Added to [`.github/workflows/ci.yml:554-557`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L554-L557).
  * *Pin `check_inventory_ratchet.py` with monotonic-shrink check:* **Delivered.** Ratchet comparison logic at [`.github/workflows/ci.yml:562-571`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L562-L571); checkout from `$BASE_SHA` at line 575.
  * *Refuse added `SQLITE-BYPASS-OK:` / `SQLITE-GATEWAY-OK:` lines outside `test/`:* **Delivered.** Implemented via `git diff -U0 ... | grep` at [`.github/workflows/ci.yml:572-574`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L572-L574).
  * *Live `judge-change` label escape hatch:* **Delivered.** Implemented via `gh pr view ... | grep -qx judge-change` at [`.github/workflows/ci.yml:558-561`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L558-L561).
  * *Pin `gh421` and `gh308` to base:* **Delivered.** Checkout at [`.github/workflows/ci.yml:576`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L576); step-level `BASE_SHA` consumed at line 596.
  * *Pin the four vendored suites to base:* **Delivered.** Checkout at [`.github/workflows/ci.yml:577-578`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L577-L578); executed from `.xyz/test/` at lines 616-620.
* **Phase 2:**
  * *Witnessed red/green controls and provenance:* **Delivered.** Documented in [`TESTS-RESULTS/2026-11-10+GH-1409/SUMMARY.md:13-22`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/TESTS-RESULTS/2026-11-10+GH-1409/SUMMARY.md#L13-L22), [`controls-procedure.md`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/TESTS-RESULTS/2026-11-10+GH-1409/controls-procedure.md), and [`provenance.jsonl`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/TESTS-RESULTS/2026-11-10+GH-1409/provenance.jsonl).

**Nothing else is open.** Live execution of the `judge-change` label was witnessed on hosted CI in PR #1494.

#### 2. Soundness of the Delivered Step (R1–R5)

**The delivered step strictly accomplishes R1–R5.** Outside the documented, operator-accepted non-goals (PR edits to `.github/workflows/ci.yml` itself, `test/lib/*` helper modifications, and maintainer label application), **no bypass or leak exists:**

1. **Base Derivation (R1):** [`.github/workflows/ci.yml:554-555`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L554-L555):
   ```bash
   git rev-parse --verify -q 'HEAD^2' >/dev/null || { echo "::error::HEAD is not a PR merge commit"; exit 1; }
   BASE_SHA="$(git rev-parse 'HEAD^1')"
   ```
   Fails closed if the checked-out ref is not a merge commit.
2. **Ratchet Integrity (R2):** [`.github/workflows/ci.yml:566-570`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L566-L570):
   ```python
   files = lambda d: {b.split(":")[0] for b in d.get("sqlite_bypasses", [])}
   grown = sorted(set(head.get("scripts", [])) - set(base.get("scripts", []))) + sorted(files(head) - files(base))
   more = lambda k: len(set(head.get(k, []))) > len(set(base.get(k, [])))
   if grown or more("sqlite_bypasses") or head.get("sqlite_bypasses_count", 0) > base.get("sqlite_bypasses_count", 0):
       sys.exit("inventory baseline grew vs PR base: " + (", ".join(grown) or "bypass count"))
   ```
   Checking `files(head) - files(base)` prevents introducing a new bypassed file. Checking `more("sqlite_bypasses")` checks distinct bypass cardinality (`set`), closing the same-file bypass addition vector.
3. **Marker Suppression (R3):** [`.github/workflows/ci.yml:572-574`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L572-L574):
   ```bash
   if git diff -U0 "$BASE_SHA" HEAD -- '*.py' '*.sh' ':!test/**' | grep -E '^\+[^+].*SQLITE-(BYPASS|GATEWAY)-OK:'; then
     echo "::error::new SQLITE-*-OK suppression marker added (label judge-change if intended)"; exit 1
   fi
   ```
   `check_inventory_ratchet.py:25` only scans `.sh` and `.py` (`SCRIPT_EXTS = {".sh", ".py"}`). Any newly added or moved marker line in those extensions outside `test/**` matches `^\+[^+].*SQLITE-(BYPASS|GATEWAY)-OK:` and fails the job.
4. **Judge Restoration (R4):** [`.github/workflows/ci.yml:575-578`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/ci.yml#L575-L578) restores all seven scripts in place directly from `$BASE_SHA`.

#### 3. Handling the `development` Branch Protection Decision

Keeping #1409 open for the `development` protection decision is an anti-pattern:
* **The blocker is external to #1409:** [`.github/workflows/wave-reconcile.yml:48`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/wave-reconcile.yml#L48) actively enforces `test "$(gh api "repos/$REPO/branches/development" --jq .protected)" = false`. Enabling branch protection on `development` currently breaks the repository's post-merge reconciler.
* **Misleading state:** An open issue #1409 with an active capture doc in `PROJECT/2-WORKING/` tells future agents that base-pinning work is unfinished or buggy.
* **Separation of concerns:** Resolving how hosted bots authenticate or bypass branch protection on `development` is an infrastructure/bot architecture decision, not a vendored-smoke judge-pinning task.

---

### (2) Graded Findings

* **[Pass] Implementation Completeness (R1–R5):** `.github/workflows/ci.yml:547-579` implements all five functional requirements cleanly without adding new test suites or violating repo gate rails (GH-831).
* **[Pass] Verification & Hosted Receipts:** Six red/green manual controls were recorded with `provenance.jsonl` ([`SUMMARY.md`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/TESTS-RESULTS/2026-11-10+GH-1409/SUMMARY.md)), and PR #1494 proved the live `judge-change` label path in hosted execution.
* **[Should] Decouple `development` Protection into a New Issue:** File a tracking issue titled `ci(wave-reconcile): define bot-bypass policy to permit branch protection on development`. The issue must state:
  1. `main` requires `vendored smoke gate`, but `development` remains unprotected ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:53-56`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L53-L56)).
  2. `wave-reconcile.yml:41-48` fails closed if `development` is protected.
  3. Acceptance criteria: design and implement a sanctioned bot-bypass policy for hosted reconciliation pushes, then enable branch protection requiring `vendored smoke gate` on `development`.
* **[Nit] Reconciler Document Promotion:** PR #1413 intentionally omitted a closing keyword ("Leaves #1409 open until merge and reconcile"). Now that PR #1413 has merged (`efcfc6140`) and reconciled (`c7bddbb49`), closing #1409 on GitHub will allow the reconciler to promote [`GH-1409-VENDORED-SMOKE-BASE-PIN.md`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md) from `2-WORKING/` to `3-COMPLETED/`.

---

### (3) Recommendation

**Recommendation: (B) Close #1409 as completed after opening a follow-up issue for the `development` protection decision.**

* **Confidence:** High (95%).
* **Strongest Fact:** All code, workflow pins (R1–R5), and verification controls for #1409 landed in `development` via PR #1413 (`efcfc6140`), whereas `development` branch protection was explicitly re-scoped to an out-of-scope non-goal ([`GH-1409-VENDORED-SMOKE-BASE-PIN.md:17`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md#L17)) because [`wave-reconcile.yml:48`](file:///private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-67346-rqz0oill/.github/workflows/wave-reconcile.yml#L48) strictly prohibits protected branches until an independent bot-bypass policy is architected.
