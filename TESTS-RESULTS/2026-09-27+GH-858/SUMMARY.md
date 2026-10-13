# GH-858: gh69-roadmap-shadow is red under PYTHONUNBUFFERED=1

Base `staging/stabilize-2026-10` at `bc0a291e`. Fix at `8ad34382`.

**Cause.** Three `cmd | grep -q` checks run under `set -o pipefail` (`:129`, `:174`, `:190`). `grep -q` exits on its first match, the unbuffered Python writer then gets EPIPE, and pipefail reports a failure even though the match succeeded (the #139 / GH-460 mechanism). All three pipelines are susceptible. The receipt check (`:129`) is the one that reproduced the failure.

**Fix.** Capture first, then match, and keep the producer's exit status: `_gh858="$(cmd)" && grep -q PAT <<<"$_gh858"`. The variable name is private because `ok` evaluates these checks in the suite's own shell, which already uses `out`. The PR #864 review (Codex) caught that the first version, `grep -q PAT <<<"$(cmd)"`, dropped the producer's status. That is fixed in `8ad34382` and checked with the reviewer's falsifier. The suite's GH-139 baseline entry goes from 3 to 0 (removed). No new test, and no assertion's intent changed.

| Run | Result |
|---|---|
| Base, `PYTHONUNBUFFERED=1` (red control) | rc 1: `FAIL: and the receipt chain is still intact`, 84 pass, 1 fail |
| Head `8ad34382`, `PYTHONUNBUFFERED=1` ×5 | rc 0 ×5, 85 pass, 0 fail |
| Head `8ad34382`, default environment ×5 | rc 0 ×5, 85 pass, 0 fail |
| `test/gh139-pipe-grep-guard.sh` | rc 0: 3 passed, the baseline is tight |
| Falsifier through the suite's `ok`/`eval` form (a producer returning status 3) | match + rc 0 → PASS; match + rc 3 → FAIL; no match + rc 0 → FAIL |

**Coverage caveat (pre-existing, not changed here).** `:352`'s `--gid` path counts a skip as a pass (`fixture has no gh_number-less row`), so these runs do not prove successful `--gid` scoring.

**Route.** `changed_tests=gh69-roadmap-shadow.sh`, `tier=3`, because a test file changed. Under #854 D2 that obligation is paid at the window's landing.
