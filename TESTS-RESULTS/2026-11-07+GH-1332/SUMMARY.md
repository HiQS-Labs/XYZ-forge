# GH-1332 item 2: `jog retry-gate` accepts a relay-receipt-only tail

**Problem.**
After the relay hit its 5-turn cap (`cap-stalled`) one turn before the reviewer's approval, the review was completed by driving one more codex turn on the same relay. That added commits that changed only `marathon-system/<lane>/RELAY.md`. `jog retry-gate` previously refused:
`jog: refusing gate retry for GH-X — head is <curr> but the execution ran on <prior>; the head moved between runs (use jog retry-build)`
A rebuild threw away an approved build.

**Solution.**
- Added `_is_relay_receipt_tail` in `utils/py/jog_run.py`:
  - Enforces identical candidate-ok invariant as GH-505 (`relay_attest._candidate_ok`):
    1. `prior_head` must be an ancestor of `curr_head` (`git merge-base --is-ancestor`).
    2. Any commits between `prior_head` and `curr_head` must change content ONLY within `relay-system/`, the lane's relay file (`marathon-system/<lane>/RELAY.md`), `--phases-dir`, `receipt["relay_file_rel"]`, or `--relay-file` and marathon's phase records beside it (`ESCALATION.md`, `PHASE-INTERRUPTED.md`).
    3. Requires `changed_paths` to be non-empty (empty commits are refused as non-relay movement).
- Updated `_jog_retry_gate_locked`:
  - When pre-dispatch HEAD differs from `prior_head`, verifies `_is_relay_receipt_tail`. If valid, advances `prior_head = curr_head` instead of refusing with exit 2.
  - Checks `if published == prior_head and receipt.get("outcome") == "approved":` so fresh tail commits dispatch a new gate retry and publish a new receipt.

**Verification.**
- Existing suite `test/gh280-jog-marathon-adapter.sh` updated with tests K3, K3b, K3c:
  - K3: refuses empty commit head movement (exit 2).
  - K3b: refuses non-relay code modification head movement (exit 2).
  - K3c: accepts commit touching only the lane's `RELAY.md`, flips gate green, dispatches `gate-retry-1`, approves receipt via satisfied-lane path, advances head by transcript commit, spends 0 new tick tokens, and parks awaiting landing.
- All 226 assertions in `test/gh280-jog-marathon-adapter.sh` pass.
- Standard repo gates verified clean:
  - `releases_app.py check`: clean (0 failures).
  - `pdda.sh run`: clean (0 errors).
  - `gh308-frozen-twin-guard.sh`: clean (0 frozen twin edits).
  - `test/gh549-work-events.sh`: clean (125 passed; registered `roadmap-pickup` extractor in `releases_app.py`).
- Zero new test suites added (GH-831 compliant).
