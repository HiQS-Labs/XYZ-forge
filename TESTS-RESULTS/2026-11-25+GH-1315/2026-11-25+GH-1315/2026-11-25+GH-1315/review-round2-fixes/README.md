# Codex round-2 finding F2: controls (2026-11-25)

The probe now requires, for the unadopted folder, one identical error in preview AND apply that states the ownership reason (not adopted / no recorded source / not recorded) and the remedy `intake.py update xyz --source ...`. Run in the disposable verify clone against `f2115e986`:

- `probe-1315-f2-reviewer-adoption-service-unavailable.txt`: the reviewer's own input (error `adoption service unavailable`, exit 2 in both modes) now FAILS the probe (exit 1).
- `probe-1315-f2-reason-no-remedy.txt`, `probe-1315-f2-remedy-no-reason.txt`: an error with only the reason, or only the command, also FAILS (exit 1).
- `probe-1315-simfix.txt`: the simulated real fix passes (exit 0). `probe-1315-comment.txt`: comment-only edit stays unfixed (exit 1). `probe-1315-unfixed.txt`: unfixed today (exit 1).
