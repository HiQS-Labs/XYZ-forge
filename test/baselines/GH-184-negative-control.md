# GH-184 negative control (pre-fix, recorded 2026-08-23)

Soak evidence: #177 §3.5. PR #160 accidentally committed
`.relay-scratch/probe_telemetry.json`. A shim driven through its real-turn path
outside a worktree then exited 0 — "tester turn produced no tracked changes
(token-only move?)" — while rtl's sanctioned non-worktree discard of
`.relay-scratch/` deleted the tracked file:

    RELAY_AGENT=tester AGY_AGENT=tester RELAY_FILE=RELAY.md bash relay-automation/agy-turn.sh
    -> exit 0; git status: ' D .relay-scratch/probe_telemetry.json'

Post-fix expectation: the artifact is removed and a derived guard
(`git ls-files .relay-scratch/` must be empty, negative control on a fixture
repo that DID commit one) keeps the lane untracked. Verified by
test/gh184-no-tracked-scratch.sh.
