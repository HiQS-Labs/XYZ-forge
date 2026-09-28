# #853 — Sweep, Document and the Guard decision (#854 window)

**Sweep, pipe-to-grep.** Every remaining `| grep -q` site listed in `test/baselines/GH-139-pipe-grep-baseline.txt` was
converted to the here-string form `grep -q PAT <<<"$X"` (the #810 fix shape the gh139 guard recommends). The baseline
went from **113 sites in 33 files to 11 sites in 5**.
- **Not converted:** the 11 that remain are comments, or `gh460`'s deliberate SIGPIPE red control. `gh460` is left
  whole, and its 7 sites stay in the baseline.
- **Method:** the bulk conversion used a regex (`echo`/`printf '%s'` of one variable piped into `grep -q`). Six sites were
  converted by hand: `debug-mantra`, `gh57` ×2, `gh77`, `hq-hardening`, `preflight-docs`.
- **Two conversion defects, caught by the suites and fixed before commit:**
  - A dropped `--` separator at 5 sites (`gh369` red).
  - The regex rewrote `gh460`'s control (`gh460` red); that file was restored.

**Sweep, interpreter paths.** 0 unsafe `sys.executable` or shebang constructions remain in `test/`:
- `gh610:100` and `gh666:121` are deliberate negative controls;
- `gh610:162` uses `shlex.quote`;
- `gh788` already ratchets the shape.

**Document.** One paragraph in `AGENTS.md`, after *A check that cannot fail is not a check*: a flaky suite is fixed in
place if it is in a tier, and turned off if it is not (#802).

**Guard.** Skipped by operator decision: `decisions/2026-09-28-gh853-guard-skipped.md`.

**Checks.** `results.txt` lists all 29 edited suites plus the gh139 guard; every one exits 0. One log per suite is in this folder.
