# GH947 synthetic verification

Implementation e2d32906, HiQS pinned source 452f6e48d7fc76b4b21c00a6b325ea015aa7a372.
Existing profile suite 51 pass; Claude subscription Python cases and 4 turn controls pass;
process-group suite 43 pass. Clone remote/HEAD unchanged after suites. No new test suite,
registry entry or production clock override. Manual command text is retained for review.

Twenty synthetic controls cover real installed tsx from foreign and copied vendored
contexts, full native consult argv with stub binary, refusal before worker dispatch,
old protocol, pin/digest/config/build/provider mismatches, unsupported actor zero claims,
subsequent-turn reuse, expiry during preflight and modelUsage mismatch. All live provider
calls are stubs; no real Claude CLI exists here and no published recipe was fabricated.
Two positive fixture admissions measured 366.145ms /228.712ms; exactly one HiQS resolver
subprocess each. This is tiny synthetic data, not a production performance benchmark.

Expiry mutation witnessed AssertionError, then restored and all controls passed. Full
qualifying gate and independent final Agy review remain outstanding at this checkpoint.
HiQS PR6/PR29 publication defects and maintained recipe/live pilot block merge/milestone.
