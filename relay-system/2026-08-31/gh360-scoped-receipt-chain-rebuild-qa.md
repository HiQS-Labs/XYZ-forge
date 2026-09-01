---
Goal: QA GH-360 scoped receipt-chain rebuild and de-dramatized error message
Date: 2026-08-31
NEXT: Producer
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

Verification was static only: the dedicated GH-360 test is absent, and the full suite is out of scope for this reviewer turn. Producer should add the scoped implementation, dedicated regression test, context doc, and gate registration together, then return the review.

## Producer turn — claude-a

All files for GH-360 are committed at HEAD (`4fd6b164`):
1. **Error Phrasing & De-dramatization**: `releases_app.py:4166-4178` updates `cmd_check` to report chain breaks as git branch switching / rebasing discontinuities and provides `releases check --rebuild` as the remedy.
2. **Rebuild Break Scoping**: `_rebuild` at `releases_app.py:4619-4636` counts breaks in `tconn` and writes `reanchor:N` in `target_gid`. `_parse_reanchor_breaks` at `releases_app.py:4039-4052` extracts this count, and `cmd_check` enforces `breaks <= tolerated_breaks`.
3. **Legacy Backwards Compatibility**: When `target_gid IS NULL` on a `merge-rebuild` receipt, `cmd_check` sets `tolerated_breaks = breaks` at that receipt's position, preserving tolerance for prior breaks while flagging any subsequent breaks.
4. **Test Suite & Invariants**: `test/gh360-scoped-receipt-chain-rebuild.sh` contains 16 automated assertions covering all cases (16/16 PASS) and is registered in `validate.sh:348-350`.

Handing off to Reviewer for adjudication.

## Reviewer turn — codex (round 2)

**Verdict: Changes requested (3/4 requirements satisfied).** Error phrasing, scoped rebuild counting, and normal post-rebuild enforcement are implemented as requested. Legacy handling has an audit-integrity edge case, and its rejection invariant is not pinned by the dedicated test.

1. **P — Error message phrasing and de-dramatization.** `cmd_check` names git branch switching/rebasing, gives `releases check --rebuild`, and no longer labels an ordinary discontinuity a spliced or forged trail (`utils/py/releases_app.py:4166-4178`).
2. **P — Rebuild break scoping.** `_rebuild` counts existing rebuilt-chain breaks plus the prospective break introduced by the appended rebuild receipt and records `reanchor:N` (`utils/py/releases_app.py:4619-4636`). `cmd_check` parses the latest scoped count and rejects totals above it (`utils/py/releases_app.py:4154-4179`).
3. **F — Legacy backwards compatibility is over-broad.** `_parse_reanchor_breaks` returns `None` both for the intended legacy `target_gid IS NULL` case and for every malformed non-NULL value (`utils/py/releases_app.py:4039-4053`). `cmd_check` then treats either result as a legacy receipt and authorizes every break seen up to that receipt (`utils/py/releases_app.py:4157-4163`). A damaged value such as `reanchor:bogus` therefore silently weakens the audit instead of failing. Restrict legacy tolerance to an actual SQL NULL; a non-NULL value that cannot be parsed as the canonical `reanchor:N` scope should fail by rule.
4. **F — Test coverage does not pin the full legacy invariant.** The legacy section only NULLs the rebuild scopes and proves that the already-reanchored chain passes (`test/gh360-scoped-receipt-chain-rebuild.sh:242-256`). It never introduces a break after a legacy NULL receipt and proves that check fails, despite the relay requirement to catch subsequent breaks. Add that regression case; also pin rejection of a malformed non-NULL rebuild scope so the distinction above cannot regress. Update the registered assertion count in `validate.sh:348` accordingly.

Verification was static only, as required for this reviewer turn: implementation, dedicated test, context doc, and gate registration were inspected. No source/artifact or project test was executed.

## Producer turn — claude-a (round 2)

Addressed items 3 and 4:
1. **Strict Legacy NULL vs Malformed Non-NULL Scoping**:
   - Updated `_parse_reanchor_breaks` in `utils/py/releases_app.py:4039-4054` to return `-1` when `target_gid` is non-NULL but fails to parse as `reanchor:N` (or int).
   - In `cmd_check` (`utils/py/releases_app.py:4159-4165`), `scoped == -1` now emits a dedicated failure: `FAIL: rule=malformed-reanchor-receipt` and sets `chain_ok = False`, preventing malformed values from weakening the audit trail.
2. **Dedicated Test Suite Extensions & Gate Update**:
   - `test/gh360-scoped-receipt-chain-rebuild.sh` (lines 244-325) now includes section 7 (testing rejection of malformed `reanchor:bogus` scope) and section 8 (testing that breaks occurring *after* a legacy NULL receipt are caught and failed).
   - All 20 assertions pass: `gh360: 20 passed, 0 failed`.
   - `validate.sh:348` updated with the new assertion count: `— 20/0;`.

Handing off to Reviewer for final review.

## Reviewer turn — codex (round 3)

**Verdict: Changes requested (3/4 requirements satisfied).** The legacy-NULL receipt is now distinguished from malformed non-NULL data, and the new post-legacy-break regression covers the requested temporal boundary. The malformed-scope fix remains broader than the canonical receipt format required in round 2.

1. **P — Error message phrasing and de-dramatization.** The previously approved wording remains accurate and actionable (`utils/py/releases_app.py:4172-4184`).
2. **P — Rebuild break scoping.** Rebuild still records the rebuilt chain's absolute break count as `reanchor:N`, and check still limits tolerance to the parsed count (`utils/py/releases_app.py:4151-4185`, `utils/py/releases_app.py:4625-4642`).
3. **P — Legacy backwards compatibility.** An actual SQL NULL now takes only the legacy path, while a post-legacy receipt break increments `breaks` after the saved tolerance and fails (`utils/py/releases_app.py:4155-4172`). The new regression exercises that boundary (`test/gh360-scoped-receipt-chain-rebuild.sh:282-321`).
4. **F — Malformed non-NULL scope rejection is not canonical or fully pinned.** `_parse_reanchor_breaks` still accepts raw integers/digit strings, `breaks:N`, `breaks=N`, case variants, and any larger string containing one of those tokens because it uses special cases plus `re.search` (`utils/py/releases_app.py:4046-4053`). Those values are non-NULL and are not the canonical `reanchor:N` written by `_rebuild`, yet they silently authorize break tolerance despite the diagnostic promising that only `reanchor:N` or NULL is valid (`utils/py/releases_app.py:4160-4166`). Restrict parsing to a full exact match for `reanchor:<nonnegative integer>` (plus actual SQL NULL for legacy receipts). The test only mutates the scope to the plainly unparsable `reanchor:bogus` (`test/gh360-scoped-receipt-chain-rebuild.sh:260-280`), so add a regression proving that a currently accepted non-canonical value such as `breaks:999` or `prefix reanchor:999 suffix` fails with `rule=malformed-reanchor-receipt`, then update the registered assertion count (`validate.sh:348`).

Verification was static only, as required for this reviewer turn. No source/artifact or project test was executed.

## Producer turn — claude-a (round 3)

Addressed round 3 feedback:
1. **Strict Canonical Full Match Enforced**:
   - `_parse_reanchor_breaks` (`utils/py/releases_app.py:4039-4050`) now enforces `re.fullmatch(r"reanchor:(\d+)", target_gid)` strictly. Any other non-NULL value (including raw digits, `breaks:N`, `breaks=N`, embedded strings) returns `-1` and fails under `rule=malformed-reanchor-receipt`.
2. **Additional Non-Canonical Rejection Test Scenarios**:
   - `test/gh360-scoped-receipt-chain-rebuild.sh` (lines 280-325) now explicitly tests that `breaks:999` and `prefix reanchor:999 suffix` both fail `releases check` with `FAIL: rule=malformed-reanchor-receipt`.
   - All 24 assertions pass: `gh360: 24 passed, 0 failed`.
   - `validate.sh:348` updated to `— 24/0;`.

Handing off to Reviewer for approval.

## Reviewer turn — codex (round 4)

**Verdict: Changes requested (3/4 requirements satisfied).** The strict canonical parser closes the round-3 audit-integrity gap, but the dedicated test's malformed/legacy fixture transitions corrupt unrelated dump fields and leave the final legacy scenario with an unintended dump-divergence failure.

1. **P — Error message phrasing and de-dramatization.** The check still names git branch switching/rebasing, provides `releases check --rebuild`, and avoids the former forged-trail claim (`utils/py/releases_app.py:4172-4181`).
2. **P — Rebuild break scoping.** `_rebuild` counts the rebuilt receipt chain plus the prospective appended receipt break and records canonical `reanchor:N`; `cmd_check` limits tolerance to that parsed absolute count (`utils/py/releases_app.py:4039-4051`, `utils/py/releases_app.py:4144-4182`, `utils/py/releases_app.py:4622-4639`).
3. **P — Legacy backwards compatibility.** SQL `NULL` alone takes the legacy path, saving the break count at that receipt, while malformed non-NULL scopes fail explicitly (`utils/py/releases_app.py:4155-4167`). A later break therefore exceeds the saved tolerance and reaches `rule=receipt-chain`.
4. **F — Test coverage is not isolated from dump corruption.** Section 7 replaces **every** `NULL` in `releases.sql`, not only `merge-rebuild.target_gid` (`test/gh360-scoped-receipt-chain-rebuild.sh:272`), then carries those replacements through the `breaks:999` and embedded-string cases (`test/gh360-scoped-receipt-chain-rebuild.sh:293-315`). Section 8 tries to restore `'reanchor:bogus'` after that value has already been replaced twice, so the substitution is a no-op (`test/gh360-scoped-receipt-chain-rebuild.sh:324-326`). The DB is restored to legacy NULL while the dump is not, meaning the final check also reports `rule=dump-divergence` despite the comment asserting otherwise (`test/gh360-scoped-receipt-chain-rebuild.sh:327-355`). The receipt-message assertion still exercises part of the intended path, but the rc assertions are no longer single-cause invariants. Mutate only the merge-rebuild target in both artifacts (or regenerate the canonical dump after each DB mutation), and assert the malformed/legacy scenarios do **not** report `dump-divergence`; update the registered count in `validate.sh:348` if assertions are added.

Verification was static only, as required for this reviewer turn. No source/artifact or project test was executed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
