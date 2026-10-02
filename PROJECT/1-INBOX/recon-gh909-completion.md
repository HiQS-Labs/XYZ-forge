# Recon Map — GH-909 completion locking
Base57bd97af; graph+current source reads, lanes A/B/C/D bounded.

Shared writer utils/telemetry/append-xyz-completion.sh27–38 chooses target and arguments;45–101 mkdir/PID ownership/reclamation;108–136 JSON read/prepend/atomicreplace. Calls: relay_drive.py489–504, marathon_drive.py1323–1335, marathon.sh71–79, all best effort and XYZ_APPEND_BIN configurable. Existing fcntl art releases_app.py374–425; use stdlib mechanism, no release-ledger dependency.

Stored JSON schema/paths remain; lock representation changes from deleted directory to stable file. Test seams xyz-completion.sh179, gh123-lock-progress-bound.sh31–63, gh358-lock-instrumentation.sh60–62 encode old directory ownership and need actualflock fixtures. No newtests. Graph metadata2026-09-01 stale lead; writer/test metadata matched but currentexactsource read. Unknown external lockpathusers/networkFS; no support claim. Rollback quiesce emitters, revert writer+fixtures together, preserveJSON.
