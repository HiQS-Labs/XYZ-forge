# Independent Codex plan QA — GH-1386 two-task trial

Reviewer: native independent plan_qa agent, 2026-11-11. Read-only; no implementation.

Verdict: conditionally acceptable; not dispatch-ready until prerequisites verified.

Findings: original GH1171 probe depended on symbolic HEAD, but preflight evaluates detached; original GH1315 fixture used /var symlink. Both corrected and rechecked: isolated real slash branch fixture and resolved temporary root. expect_nonzero:true correctly maps baseline failure to unfixed and successful behavior to landed. round_cap2 propagates. Add evidence directories to artifacts; record numeric timeout limits, prove actual generated packets, and verify clean primary checkpoint. Preserve full-gate requirement.

Supervisor dispositions: evidence directories added; numeric limits240s turn/idle and660s gate recorded with LANE_MAX_ATTEMPTS2. Actual generated packet and primary checkpoint checks remain explicit dispatch prerequisites. No implementation finding was waived. Baseline probes fail on the actual defects and their output/provenance is retained under each issue's TESTS-RESULTS directory.

The engine advances only after approved result, PR identity, committed receipt and published head. A failed first task stops the trial; manual second dispatch is prohibited.
