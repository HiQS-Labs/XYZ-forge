# GH1042 / GH1045 recovery verification

Production revision: `7128b49620a681ecec78e7c9a8b2722b709300e7` (development base `b9f07ea5`).

The manual replay uses real tick and the shipped marathon driver, with the existing attestation stub for deterministic approvals and a failing dispatch stub. It does not call a live model. Every expected recovery/refusal outcome passed, including two-phase shell traversal reaching p2 retry after p1 completion and a later shared-file commit. Completion write failure, red gate, source drift, wrong review/phase/lane, malformed/missing evidence and divergent ancestry refuse. Numeric and force generations recover without dispatch; explicit retry and unrelated token controls dispatch the failing stub as expected. Historical reviewed_candidate stays pinned; current HEAD is observational and cannot pass strict merge qualification. Historical recovery creates no fresh gate receipt and does not repeat completed post-approve/required-test obligations.

Existing gh491, gh505 and gh642 suites passed at `0275a7a0`. Marathon-drive first failed on the producer's event-order regression at that revision; the source was fixed to retain GH273 approval-event timing. Marathon-drive then passed at the final source revision `7128b496`. Before/after clone identity is identical for both focused runs. The final required full gate is pending and will cover all suites at publication head.

Plan QA: third round Approved, harness exit0. Earlier two textual approvals were structurally rejected (missing Log; verdict spelling); neither counts. Final independent QA is pending. No new test suites, registry entries or Bash changes.

Legacy limitation: records with no protected completion field remain strict current-head checks. No automatic inference/backfill of old divergent completion; intentional explicit retry re-reviews it.
