# GH-858: gh69-roadmap-shadow is red under PYTHONUNBUFFERED=1

Base `staging/stabilize-2026-10` at `bc0a291e`.

**Cause.** `cmd | grep -q` under `set -o pipefail`. `grep -q` exits on the first match. The unbuffered Python writer then gets EPIPE, and pipefail reports a failure even though the match succeeded (the #139 / GH-460 mechanism).

**Fix.** The three baselined sites (`:129`, `:174`, `:190`) use the capture-then-match form that #139 documents: `grep -q PAT <<<"$(cmd)"`. The suite's entry in `test/baselines/GH-139-pipe-grep-baseline.txt` goes from 3 to 0 (removed). No new test, and no assertion changed.

| Run | Result |
|---|---|
| Base, `PYTHONUNBUFFERED=1` (red control) | rc 1: `FAIL: and the receipt chain is still intact`, 84 pass, 1 fail |
| Head, `PYTHONUNBUFFERED=1` ×5 | rc 0 ×5 ( pass, 0 fail) |
| Head, default environment ×5 | rc 0 ×5 |
| `test/gh139-pipe-grep-guard.sh` | rc 0: 3 passed, the baseline is tight, no stale entries |

**Route.** `changed_tests=gh69-roadmap-shadow.sh`, `tier=3`, because a test file changed. Under #854 D2 the tier-3 obligation is paid at the window's landing.
