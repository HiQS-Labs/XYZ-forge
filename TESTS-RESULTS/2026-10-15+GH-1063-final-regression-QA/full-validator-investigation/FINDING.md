# Initial pooled PermissionError, passing built-in retry

The dedicated full validator at5c46c49b reported rc1 for gh648-l4-285-revalidate.sh in the pool. Its retained initial log shows PermissionError during the existing process-group fixture observation/cleanup after four successful modes. The validator's own sequential retry passed all modes and its no-kill mutation control, with raw output retained. Full final result409/409,1314.53s, identity unchanged.

The fixture, codex-turn.py, agy-turn.py and proc_group.py are byte-identical to pre-batch69666c47, proven by Git blob identities. Existing framework classifies a passing-alone retry as contended; that classification is not a proven OS-level cause of this PermissionError. No test/fixture/guard changed, no new case or extra standalone suite run was added, and this does not erase the pooled failure. Retain as a qualified initial-attempt warning.
