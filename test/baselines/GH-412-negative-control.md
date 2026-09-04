# GH-412 negative control — pre-fix EEXIST lock collision exit status

Pre-fix, `src/lock.js` threw a generic `Error` on `EEXIST` and `bin/tick` caught all errors and exited 1. Consequently:
- A transient lock collision when two turns claimed concurrently exited `1`.
- `rtl.py` treated exit 1 as a durable failure and aborted without retrying.

```
$ tick claim T1 --agent codex --paths "src/*"
tick: error: another tick claim is in progress for this clone (lock held) — retry shortly, or remove .tick/locks/claim.lock if a prior claim was killed
$ echo $?
1
```

Post-fix:
- `src/lock.js` tags `EEXIST` lock collisions with `code = 'EX_TEMPFAIL'` and `exitCode = 75`.
- `bin/tick` exits with code 75 on transient lock collisions.
- `rtl.py` retries on exit 75 with exponential backoff before failing, while durable losses (exit 1) remain unretried.
