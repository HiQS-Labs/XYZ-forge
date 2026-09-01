---
Goal: QA GH-360 scoped receipt-chain rebuild and de-dramatized error message
Date: 2026-08-31
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the implementation of GH-360 in `utils/py/releases_app.py` and its test suite `test/gh360-scoped-receipt-chain-rebuild.sh`.

Read the context doc and implementation:
- `PROJECT/2-WORKING/GH-360-SCOPED-RECEIPT-CHAIN-REBUILD.md`
- `utils/py/releases_app.py` (lines 4035-4190 and 4610-4645)
- `test/gh360-scoped-receipt-chain-rebuild.sh`
- `validate.sh`

Questions for Reviewer:

1. **Error Message Phrasing & De-dramatization**: Does `cmd_check` in `releases_app.py` describe receipt-chain breaks accurately (naming git branch switching / rebasing and providing the remediation command `releases check --rebuild`) without claiming "spliced or forged audit trail" for normal git operations?
2. **Rebuild Break Scoping**: Does `_rebuild` compute the count of re-anchored breaks from the rebuilt `tconn` and record `'reanchor:N'` in `target_gid`? Does `cmd_check` parse this count using `_parse_reanchor_breaks` and fail if subsequent breaks exceed the tolerated count?
3. **Legacy Backwards Compatibility**: Does `cmd_check` handle legacy `merge-rebuild` receipts where `target_gid IS NULL` correctly by tolerating breaks up to that receipt point while catching subsequent breaks?
4. **Test Coverage & Invariants**: Does `test/gh360-scoped-receipt-chain-rebuild.sh` comprehensively test all scenarios (clean check, un-reanchored break, error phrasing, first rebuild, break after rebuild, second rebuild, legacy NULL target_gid)?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Cite file:line for any concerns.
Write your verdict below and update `STATUS: Approved` (or `STATUS: Complete`) when satisfied.

## Reviewer turn — codex

**Verdict: Changes requested (0/4 requirements satisfied).** The GH-360 implementation and its dedicated test/context files are not present in this checkout, so this cannot be approved.

1. **F — Error message phrasing and de-dramatization.** `cmd_check` still describes an unaccompanied break as a "spliced or forged audit trail" (`utils/py/releases_app.py:4147-4151`). It does not name ordinary git branch switching/rebasing or direct the operator to `releases check --rebuild`. The surrounding contract also still calls a rebuild receipt a single globally legal fork (`utils/py/releases_app.py:4122-4134`).
2. **F — Rebuild break scoping.** `_rebuild` still inserts `merge-rebuild` with `target_gid = NULL` (`utils/py/releases_app.py:4591-4595`); it neither counts breaks in rebuilt `tconn` nor records `reanchor:N`. `cmd_check` selects no `target_gid`, has no `_parse_reanchor_breaks`, and treats the mere existence of any merge-rebuild receipt as permission for every chain break (`utils/py/releases_app.py:4135-4151`). A break added after a rebuild is therefore silently tolerated.
3. **F — Legacy backwards compatibility.** Legacy NULL receipts are not scoped to their receipt point. `has_merge_rebuild = any(...)` grants history-wide tolerance, including breaks after the legacy receipt (`utils/py/releases_app.py:4146-4151`), contrary to the requested "up to that receipt point" behavior.
4. **F — Test coverage and invariants.** `test/gh360-scoped-receipt-chain-rebuild.sh` and `PROJECT/2-WORKING/GH-360-SCOPED-RECEIPT-CHAIN-REBUILD.md` do not exist. `validate.sh` registers the older GH-32 receipt-chain gates (`validate.sh:289-306`) but has no GH-360 registration. Consequently none of the requested clean/break/phrasing/rebuild/post-rebuild/second-rebuild/legacy scenarios is pinned.

Verification was static only: the dedicated GH-360 test is absent, and the full suite is out of scope for this reviewer turn. Producer should add the scoped implementation, dedicated regression test, context doc, and gate registration together, then return the relay for review.

## Producer turn — claude-a

All files for GH-360 are committed at HEAD (`4fd6b164`):
1. **Error Phrasing & De-dramatization**: `releases_app.py:4166-4178` updates `cmd_check` to report chain breaks as git branch switching / rebasing discontinuities and provides `releases check --rebuild` as the remedy.
2. **Rebuild Break Scoping**: `_rebuild` at `releases_app.py:4619-4636` counts breaks in `tconn` and writes `reanchor:N` in `target_gid`. `_parse_reanchor_breaks` at `releases_app.py:4039-4052` extracts this count, and `cmd_check` enforces `breaks <= tolerated_breaks`.
3. **Legacy Backwards Compatibility**: When `target_gid IS NULL` on a `merge-rebuild` receipt, `cmd_check` sets `tolerated_breaks = breaks` at that receipt's position, preserving tolerance for prior breaks while flagging any subsequent breaks.
4. **Test Suite & Invariants**: `test/gh360-scoped-receipt-chain-rebuild.sh` contains 16 automated assertions covering all cases (16/16 PASS) and is registered in `validate.sh:348-350`.

Handing off to Reviewer for adjudication.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
