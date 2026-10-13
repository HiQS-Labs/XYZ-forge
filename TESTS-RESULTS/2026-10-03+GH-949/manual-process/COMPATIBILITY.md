# Candidate process compatibility review

Source: 76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d.

Read all six original `after/summary.json` cases: every expected-correct property passes. TERM/INT return 143/130, preserve prior bytes, append exactly one interrupted failure record, and leave no child. Missing timeout refuses before the sentinel runs. Oracle timeout fails explicitly and permits no late mutation; later idempotence timeout now returns structured failure and permits no late mutation. Normal exit0, own exit124 and observed timeout remain distinct.

Additional `compat_controls.py` witnesses in `compat-after/`: cancellation during unacknowledged CLI startup cleans up the TERM-resistant child; additional TERM/INT signals delivered during the cleanup grace do not prevent cleanup, and status retains the first signal (143 or130). Programmatic run_bounded catches a real SystemExit(77) raised by a timed SIGUSR1 handler after child readiness, cleans the child and re-raises the original exception. Successful leader exit still permits its background child to survive (the documented pre-existing policy); the supervisor independently cleans that owned group. All four case properties pass, every cleanup child-absence check is true.

No sources were modified. Raw commands, SHA and UTC provenance are in each output directory. Scope limits: repeated-signal injection was exercised in CLI ACK-wait cleanup, not every possible instruction boundary; SIGKILL and descendants deliberately creating a new session are not covered. The programmatic helper does not promise to install signal handlers for embedding callers. Production default-SIGTERM callers must opt into a cancellation boundary if they need unwind cleanup.
