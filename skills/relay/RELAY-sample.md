# RELAY · detect_abuse.py evidence-grade retrofit
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: —
STATUS: Approved
ROUND: 3 / 5

## Setup
- Artifact under review: `scripts/detect_abuse.py`
- Definition of Done: every emitted finding carries a FACT / PATTERN / HYPOTHESIS grade, enforced in-script — no central orchestration.
- Producer: Claude Code (window A)   ·   Reviewer: Claude Code (window B)
- Handoff: manual nudge
- Started: 2026-06-13

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:` (what it ran / skipped / couldn't run); the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. An `Approved` can't silently mean "looked fine on read": if correctness rides on runtime behavior and nothing ran, `textual only` is the strongest honest verdict. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · 2026-06-13 09:14 PT
**Did:**
- Imported `Grade` from `evidence.py`; wrapped all three abuse signals as `Finding(grade=...)`.
- Velocity spike → PATTERN; known-bad fingerprint match → FACT; shared-device cluster → HYPOTHESIS.
**Review this:** Are the grade assignments defensible against the June 8 logs? Anything still emitting an ungraded dict?
**Verification:** ran `pytest tests/test_detect_abuse.py -q` → 11 passed; impossible to replay June 8 prod logs locally (no fixture — only the synthetic set exists).
**Open questions:** Is shared-device really HYPOTHESIS, or should clustering confidence bump it to PATTERN?
**Commit:** a91c44e

### Round 1 · Reviewer · 2026-06-13 10:02 PT
**Verdict:** Changes requested
**Basis:** behaviorally proven — ran `pytest -q` (11 passed) and `python -m detect_abuse --replay tests/fixtures/synthetic.jsonl`, inspected emitted grades line by line.
**Findings & proposals:** (I propose; I do not edit the artifact)
- [Blocker] `fingerprint match → FACT` (line 96): the match is fuzzy (Levenshtein ≤ 2), not exact. A near-match isn't a FACT. — Proposed fix: downgrade to PATTERN, or gate FACT behind exact-match and let ≤2 fall through to PATTERN.
- [Blocker] `chargeback_ratio` emit (line 148) still returns a bare dict — fails the DoD's "every finding graded" bar. — Proposed fix: wrap in `Finding(grade=Grade.PATTERN)`.
- [Should] Shared-device HYPOTHESIS is correct as-is — clustering confidence is associative, not causal. Keep it HYPOTHESIS; don't bump.
- [Nit] `Grade` import is unsorted relative to the rest of the `evidence` imports. — Proposed fix: move it into alpha order.
**Commit:** none (comments only)

### Round 2 · Producer · 2026-06-13 10:41 PT
Verified both blockers against the source before deciding — the fuzzy-match over-claim and the bare-dict emit both hold up. Dispositions agreed with operator:
**Decisions on proposals:** (operator-approved)
- [Blocker] fuzzy-match → FACT — **Modified** → kept FACT but gated it: line 96 now requires exact match after hash-normalization; ≤2 on raw IDs falls through to PATTERN. The ≤2 window only ever fired on casing/encoding artifacts of the *same* device, so exact-after-normalize preserves intent without over-claiming. · Proof: `pytest -q` → 12 passed (added `test_fuzzy_id_is_pattern_not_fact`).
- [Blocker] `chargeback_ratio` bare dict — **Implemented** → wrapped at line 148 in `Finding(grade=Grade.PATTERN)`. · Proof: textual only — no test exercises the chargeback path yet; flagging so the Reviewer can confirm behaviorally.
- [Should] shared-device — **Implemented** (no-op) → kept as HYPOTHESIS per your call.
- [Nit] import order — **Implemented** → sorted the `evidence` imports.
**Did:** Added `test_fuzzy_id_is_pattern_not_fact` covering the normalization boundary.
**Verification:** ran `pytest tests/test_detect_abuse.py -q` → 12 passed; skipped a chargeback-path test (no fixture for it — that's the one fix I could only confirm textually).
**Re-review this:** the line-148 chargeback wrap — please confirm it actually emits PATTERN at runtime, since I couldn't.
**Commit:** 7e1d220

### Round 2 · Reviewer · 2026-06-13 11:19 PT
**Verdict:** Changes requested
**Basis:** behaviorally proven — re-ran the suite (12 passed) and hand-drove the chargeback path with a crafted event.
**Prior fixes:**
- fuzzy-match gate (line 96) — **behaviorally proven**: `test_fuzzy_id_is_pattern_not_fact` exercises the exact boundary; confirmed FACT only on exact-after-normalize.
- chargeback wrap (line 148) — **textually fixed, NOT behaviorally proven**: code reads correctly, but I drove it with `python -m detect_abuse --replay -` and a synthetic chargeback event and it raised `KeyError: 'merchant_id'` before reaching the grade wrap. The wrap is right; the path to it is broken.
**Findings & proposals:**
- [Blocker] line 142: `event['merchant_id']` assumes a key that's absent on refund-type events, so the chargeback finding never emits — the line-148 grade is dead code under those inputs. — Proposed fix: `event.get('merchant_id')` with an early continue when absent, and add a refund-event test fixture.
- [Pass] fuzzy-match gate (line 96): drove the exact-after-normalize boundary myself — FACT fires only on true exact match, ≤2 falls to PATTERN as intended. Sound.
**Answers:**
- "confirm the line-148 chargeback wrap emits PATTERN at runtime" → No — it doesn't reach the wrap. Driving the path raised `KeyError: 'merchant_id'` first (see Blocker above). The wrap itself is correct; the path to it is broken.
**Commit:** none (comments only)

### Round 3 · Producer · 2026-06-13 11:53 PT
Verified the KeyError against the source before deciding — reproduced it on a refund event, confirmed line 142 is the cause. Disposition agreed with operator:
**Decisions on proposals:** (operator-approved)
- [Blocker] missing `merchant_id` KeyError — **Implemented** → line 142 now `event.get('merchant_id')` with an early `continue` when absent; added `tests/fixtures/refund_event.jsonl` and `test_chargeback_emits_pattern`. · Proof: `pytest -q` → 13 passed, and the new test asserts a PATTERN-graded finding emits on the refund event.
**Did:** Nothing beyond the fix + its test.
**Verification:** ran `pytest tests/test_detect_abuse.py -q` → 13 passed; ran `python -m detect_abuse --replay tests/fixtures/refund_event.jsonl` → emits one `Finding(grade=PATTERN)`, no exception.
**Re-review this:** the line-142 guard + the new chargeback test — that was the last unproven path.
**Commit:** 4c1f8aa

### Round 3 · Reviewer · 2026-06-13 12:08 PT
**Verdict:** Approved
**Basis:** behaviorally proven — ran `pytest -q` (13 passed) and replayed both `synthetic.jsonl` and `refund_event.jsonl`; every emitted finding carries a grade and the chargeback path now reaches its PATTERN wrap. No bare dicts remain.
**Prior fixes:**
- chargeback path (line 142) — **behaviorally proven**: the KeyError is gone and `test_chargeback_emits_pattern` covers the previously-dead path.
**Findings & proposals:**
- [Pass] every emit path (velocity, fingerprint, shared-device, chargeback) now returns a `Finding(grade=...)` — replayed both fixtures and grepped for bare-dict returns, none remain. DoD met.
**Answers:**
- "is the line-142 guard + new chargeback test the last unproven path?" → Yes — that was the only path I couldn't drive before; it's now covered and green. Nothing left unverified.
**Commit:** none (comments only)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
