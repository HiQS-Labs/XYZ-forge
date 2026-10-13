# GH-830: gh620 fixture git calls failed silently

Base `staging/stabilize-2026-10`: `bc0a291e` for the base runs; the fix is rebased onto `6653ab16` as `e628df51`.

**Cause.** In `test/gh620-skills-army-mini-sync.sh`, `git()` returned the result without checking it. About 30 fixture calls (`clone`, `commit`, `push`, `init`, `rev-parse`) went unchecked, and stderr was captured and dropped. On 2026-09-25 (hosted run 36194249895) the `seed-owner` clone failed, and the suite crashed a line later with `FileNotFoundError …/seed-owner/TODO.md`. The failed clone and its reason were lost.

**Fix.** `git()` checks the return code. On failure it prints `FAIL: fixture setup failed: git -C <repo> <args> (exit N): <git stderr>` and exits 1. Every `git()` call in the suite builds or reads a fixture, so none tests a git failure and no opt-out is needed. There are no retries (#830 non-goal), and no assertion or product code changed. The suite pins its own git identity (`:14`), so commits cannot start failing because of the new check.

| Run | Result |
|---|---|
| Base, normal | rc 0, 28 passed, 0 failed |
| Base, red control (`seed-owner` clone from a missing repo) | rc 1, the incident's symptom: `FileNotFoundError …/seed-owner/TODO.md`, with the clone never named |
| Head, red control (same mutation) | rc 1: `FAIL: fixture setup failed: git -C … clone -q …/mini.git-missing …/seed-owner (exit 128): fatal: repository … does not exist` |
| Head, normal ×5 | rc 0 ×5, 28 passed, 0 failed |

The red control's script is `redcontrol.sh.txt`. It mutates a temporary copy of the suite and deletes it afterwards; the tree is clean after each run.

**Route.** A test file changed, so `tier=3`. Under #854 D2 that obligation is paid at the window's landing.
