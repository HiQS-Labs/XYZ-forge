# Security scan reads transient parallel test files

During #764's full `validate.sh`, `security-scan.sh` returned 1 in the parallel pool after `grep`
reported scan errors on four temporary `_gh15-*` and `_gh528-*` test files in `test/`. They were
being created and removed by peer suites. The runner's built-in isolated retry passed, and the
overall gate finished 411/411. The retained evidence is
`TESTS-RESULTS/2026-09-23+GH-764/validate.log`.

This is outside #764's three baseline failures. During triage, check whether the scanner should
scan only tracked paths or take a stable input snapshot, and preserve failure-on-real-read-errors.
No issue or RELEASES row has been created for this observation yet.
