# GH-1426: manual checks and focused suites

These are manual checks (GH-831: no new suites). They were run in a disposable fixture made of two full
clones of XYZ-forge at `origin/development` `0f21b761a`: `<verify>/primary` (the Jog primary, pinned
through an isolated `GIT_CONFIG_GLOBAL`) and `<verify>/target` (the execution clone). Neither machine
config nor the primary checkout was touched.

**Fixture.** In the target, GH-1426's doc was moved to `2-WORKING` with a contract gated on
`.venv/bin/pytest -q test/test_python_layer.py`; the target has no `.venv`. GH-1427 was left in `1-INBOX`
unchanged. In the primary, GH-1426 and GH-1427 were queued with `jog add`, and the pre-existing pending
GH-1315 was dropped so the fixture is isolated. "Pre" runs used the base `jog_run.py`. "Post" runs used
`jog_run.py` byte-identical to task commit `8ad2ff632`.

| Check | Pre-fix (red) | Post-fix | Verdict |
|---|---|---|---|
| R1 dry-run + `--target-root` | `r1-pre-dryrun.txt`: `would process 2 pending item(s)`, no reason | `r1-post-dryrun.txt`: GH-1426 `NOT-READY (exit 5) — next: gate program not found … .venv/bin/pytest`; GH-1427 `CONTRACT ERROR: … missing required field: target (1-INBOX doc; live run promotes it first)` | PASS |
| R1 effect contract | n/a | `r1-post-before.snap` = `r1-post-after.snap`: primary `releases.db`/`releases.sql` sha256, `.tick/jog` files, primary and target `git status`, target worktree list all unchanged | PASS |
| R2 live preflight park | `r2-pre-live.txt`: `marathon execution gh1426-exec1 …` then `advancing halted at landing boundary.`; row reason `… No packet written — …` | `r2-post-live.txt`: `running preflight for GH-1426 (execution gh1426-exec2 …)`, `preflight refused: NOT-READY (exit 5) — next: …`, `advancing halted: GH-1426 parked — preflight-refused (exit 5): NOT-READY (exit 5) — next: …`. The row reason carries the cause. This run is a rerun (attempt 2, retry-build mode): adjacent path. | PASS |
| R3 no `--target-root` unchanged | `r3-pre-samestate-notarget.txt` (base code, same queue state) | `r3-post-dryrun-notarget.txt` (fixed code): `diff` empty | PASS |
| R4 summary helper cases | n/a | `r4-summary-cases.txt`: a contradicted `ready` is qualified; empty output → `exit 2`; die, contract-error, NOT-READY and ready lines all produce non-empty summaries | PASS |
| R5 1-INBOX identity | n/a | numeric `gh_issue: 1427` → evaluated via `--project-doc` (R1 post). URL-valued `gh_issue` → `r5-url-dryrun.txt`: `not evaluated — 1-INBOX doc … has no numeric gh_issue: 1427 …` | PASS |
| Smoke: invalid target | n/a | `smoke-invalid-target.txt`: `--target-root` = primary → `live run would refuse --target-root: …`, exit 2 | PASS |
| Existing suites | | `gh280-jog-marathon-adapter.log` 227 pass / 0 fail (I7, I7b, G8 green). `jog-queue.log` 34 pass / 0 fail. Run in a disposable full clone at `8ad2ff632`; HEAD, origin and `core.bare` were identical before and after. | PASS |

Paths in the captured outputs are rewritten to `<verify>`, `<task-clone>`, `<gate-clone>` and `<tmp>`.
