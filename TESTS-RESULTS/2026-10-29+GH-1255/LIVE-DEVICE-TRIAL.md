# Manual live-source trial without deployment

The reviewed candidate f89758e36fc3038130eabbe61966bc2c6f1540a2 captured the operator's actual current Codex submission on this device into an isolated SQLite database. The unchanged base tailer captured zero. This was a foreground manual trial; it did not test the installed launchd path or delivery to the normal database.

The trial used a private byte-exact snapshot of the current rollout and separate HOME, CODEX_HOME, CLIO_CONFIG, cursor and SQLite files. The existing writer was extracted unchanged from the reviewed INSTALL heredoc and used with the reviewed store helper; no runtime installer or launchctl command ran. Eligibility was pinned to the actual current submitted event, whose modern type and nonempty text were checked before execution.

| Check | Observed result |
|---|---|
| Unchanged base tailer | delivered=0, no current-prompt row |
| Reviewed candidate | delivered=1; one matching codex row with expected repository context and source ID |
| Normal rerun | delivered=0; stable current record ID, no duplicate |
| Explicit backfill | Current record ID/count unchanged; earlier session submissions admitted only into the isolated test store |
| JSONL and Markdown previews | Current normalized prompt present exactly once in JSONL and present in Markdown |
| Isolation | Private source snapshot unchanged, original source prefix unchanged, installed helper hashes unchanged |

Initial verification assertions were corrected for documented output semantics: queries must account for canonical UTC-second timestamps, and Markdown comparison must account for HTML escaping and the writer's whitespace trimming. These were trial-check corrections; candidate production code was not changed.

Sanitized results and code/input hashes are retained in live-device-trial.json. The raw rollout, prompt text, local path, machine label, test databases and verification script remain private in gitignored temp and are not published. Public synthetic reproduction remains in the existing Codex suite; this private-source result is independently inspectable only by the operator.

This proves the actual source-event → tailer → shared writer → SQLite → query/export path can be exercised without a PR merge or deployment. It does not establish installed scheduling, two-minute automatic delivery, normal-store backfill or fleet acceptance. Those remain deployment checks. No new suite, runner or CI gate was added.
