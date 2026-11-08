# GH1358 scheduled requeue composition plan QA

STATUS: Approved
Reviewer: independent native Codex retry_composition_plan; 2026-11-08.

Concrete plan: selected pending row with prior attempt_count uses existing
run_marathon_phase mode=retry-build; first attempt remains mode=run. No new queue,
retry loop, cap, or supervisor. Explicit jog retry preserves attempt_count.

Verdict: Approved, no blocking findings. Selected attempt_count is read before
lease increment. Existing retry-build finds the prior receipt (skipping new
incomplete record), suffixes its token, and keeps the Marathon phase/lane key and
attempt cap. Cold-start reconciliation still parks missing-result executions
before selection; no automatic refire is introduced.

Required evidence: first dispatch unchanged, explicit retry followed by scheduled
fresh token, prior receipt/counters retained, missing-result cold start still parks.
Use existing adapter plus manual evidence; no new suite. Reviewer edited no files
and executed no suites. Review preceded the one-line implementation.
