# GH-974 intake verification

Docs/ledger-only change. Targeted PDDA frontmatter, status-table and hardcoded-path checks pass with an explicit single-file intake scope. Invalid complexity 9 fails the same frontmatter check before restoring complexity 2. The initial relative-path invocation scanned zero files (default frontmatter scope is 2-WORKING); it is not used as evidence. RELEASES consistency check passes; CLI readback confirms exactly one native #974 row, paused in Deferred · vision, with correct doc/issue links and rated 20/10/50/55. No Jev calls or recipe-execution claims are made. Commands, scope, exit statuses and outputs are in provenance.jsonl.

Exact-base comparison of all 16 user tables confirms one #974 roadmap addition, unchanged unrelated rows, and only the expected generation/operation-receipt/work-event additions. Details and content/base identifiers are retained in ledger-delta.json.
