---
title: jog run --dry-run ignores --target-root readiness; preflight park misreported as landing halt
status: In Progress
created: 2026-11-11
updated: 2026-11-11
owner: Noel Saw
branch: fix/XYZ-forge-gh1426-jog-dryrun-target-readiness-2026-11-11
gh_issue: 1426
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1426
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
reported_from: LTVera-Pandas
harness_commit: 046b41538
non_goals:
  - Bootstrapping .venv in target clones (operator clone-setup responsibility)
  - Changing swarm_preflight readiness rules
goal: >
  `jog run --dry-run --target-root <clone>` surfaces each pending item's preflight verdict and
  readiness reason without mutating anything, and a live preflight park prints the real reason
  instead of "advancing halted at landing boundary".
---

# GH-1426 — jog dry-run ignores target readiness; preflight park misreported

## Status

| What was just completed | What's next |
|---|---|
| Plan QA round 1 (Codex) returned FAIL with 3 Should findings; all were dispositioned and the plan amended (effect contract, `--out`, summary rc check, repaired preflight contract). Pre-fix R1/R2 red controls captured in a disposable fixture. | Codex plan QA round 2, then implement Steps 1–5. |

## Rating rationale (2026-11-11)

`rated 55/45/50/70` (pri/sev/appeal/effort), row `rmi-01M76VWXM3AWQ4HKP7ADP1850S`.

- **sev 45:** recoverable. The row parks, no data or work is lost, but the console misreports the
  cause and the operator must re-run preflight by hand to learn it. Not work-blocking: rerunning
  after fixing the clone succeeds.
- **pri 55:** a scheduled unattended Jog fire burned its slot (lease + lock taken) on a setup gap that
  a dry-run is the documented pre-fire check for. Kept close to severity.
- **appeal 50:** neutral; the operator gave no preference.
- **effort 70:** one file (`utils/py/jog_run.py`), reusing preflight's existing `--dry-run` and output.
- **Recurrence** (issues with "jog" in the title, created 2026-10-28..2026-11-11 vs 2026-10-14..2026-10-27):
  one incident of this exact defect (#1426). Adjacent "Jog parks or misjudges only at live fire" defects
  with different root causes: #1332 in the recent window; #1093, #1100, #1232 in the prior window.
  The class recurs, but no shared root cause is claimed, so there is no recurrence uplift. Coverage is
  limited to title search.

## Recon (base `0f21b761a`)

The pointers from the report are re-verified against current `development`; line numbers have not moved.

- **Entry:** `releases_app.py jog run` → `jog_run.jog_run_main` (`utils/py/jog_run.py:2163`).
- **Dry-run branch** (`jog_run.py:2221-2241`): opens `releases.db` read-only, lists pending
  `jog_queue` rows (capped by `--max-tasks`), prints `would process N pending item(s)`, returns.
  It never reads `--target-root`. It runs before `_require_jog_primary`. The jog SKILL.md
  (`skills/2-daily/jog/SKILL.md:141`) documents: "Read-only list/export/dry-run do not need a primary pin."
- **Live target validation** `_execution_root` (`jog_run.py:530-544`): `_require_jog_primary(root)`, then
  target-is-a-separate-full-clone, same-origin (`primary_config_key`), and no ledger delta in the clone.
  Everything after the primary check is read-only git.
- **Live marathon path** `run_marathon_phase` (`jog_run.py:552-610`): resolves `swarm_preflight.py`
  (target → target/.xyz → harness home), appends an execution record, saves state, then **prints
  `jog: marathon execution <id> …` (595) before preflight runs**. It runs preflight with
  `capture_output=True` (597-600). If refused, it records `preflight-refused` and returns
  `("parked", "preflight-refused (exit N): <last output line>")`. The last line is
  `No packet written — candidate is not preflight-ready (NOT-READY).`, so the `readiness … next:` cause is dropped.
- **Park echo** (`jog_run.py:2393-2395`): any non-`failed`, non-continued action from the marathon path
  prints `jog: advancing halted at landing boundary.`. That includes pre-dispatch parks (preflight
  refused, preflight script missing, invalid invocation, receipt publication failed). None of these is a
  landing boundary. The legacy relay path keeps its own text at 2453 after a real landing handoff, which is correct there.
- **Legacy relay preflight park** (`jog_run.py:2415-2417`): prints `preflight failed (exit N); parking item.`
  and also drops the reason. This is the same defect class in the same function.
- **Preflight** (`utils/py/swarm_preflight.py`): `--dry-run` writes no packet and exits 0 when ready
  (1727-1733). A non-ready candidate exits with its verdict code (4/5/6/7) **before** the dry-run
  check (1707-1713), so dry-run and live give the same verdict. Its text output carries
  `  readiness   : ready=N — next: <reason>` and `  verdict     : <VERDICT> (exit N)` (1702-1704). Early
  refusals print a `BLOCKED: …` / `CONTRACT ERROR …` line instead. The gate-program check is at
  1585-1600. **Side effects, live and dry alike** (plan QA r1): `git fetch --prune` in the target (1309).
  It also adds a transient detached worktree at the contract's `target.ref`, then removes and prunes it
  (1365-1391). Contract `command` probes run with `shell=True` in that worktree (231-235), before the
  dry-run exit (1727). None of these touches either ledger or takes a Jog lock or lease. Git takes its own
  short-lived ref and worktree locks. After the ready verdict, if `--out` is unset, preflight shells out
  to `rtl_transcript_root` (1715-1721). That call is read-only, but it exits 1 on an invalid
  `XYZ_ARCHIVE_ROOT`. The live Jog call passes `--out`, so it never reaches that shell-out.
- **Doc location gotcha:** `--gh-issue N` mode requires `PROJECT/2-WORKING/GH-N-*.md` in the target
  (1242-1248). A live run first **promotes** a 1-INBOX doc (`jog_run.py:2341-2352`, a mutation), so a naive
  dry-run preflight would report a false `BLOCKED` for every 1-INBOX item. Preflight's `--project-doc
  <path>` mode evaluates the same contract and readiness from an explicit doc, with the issue taken from
  frontmatter (1494), and needs no promotion. The slug (basename, 1285-1288) and checklist source
  (1509-1514) match what a post-promotion run sees, because promotion keeps the basename and content
  (`jog_run.py:1638-1677`). This **approximates** post-promotion preflight. It does not prove that the
  promotion itself would succeed: unattended probe-lint refusal at `jog_run.py:1687-1691` stays separate.
  `find_issue_doc` is the canonical issue-identity resolver (`wave_reconcile`), so the doc used is the
  one for issue N.
- **Tests pinning touched text:** `test/jog-queue.sh:174-176` and `test/gh280-jog-marathon-adapter.sh:795-803`
  (I7) assert `would process` from the dry-run path. I7 already passes `--target-root "$FT"` via
  `jog_run_root`, so I7 will exercise the new path. G8 (`gh280…:703-712`) pins the park reason prefix
  `preflight-refused (exit 6)`. No test or skill doc pins `advancing halted at landing boundary` or
  `marathon execution <id>`.
- **Untraced:** the `--checkpoint-root` continuation branch is unchanged and not traced further. The
  vendored `.xyz` preflight resolution is reused as is.

## Plan

**Outcome sought:** before a fire, the operator can trust `jog run --dry-run --target-root <clone>` to say
which items would park at preflight and why. After a fire, the console states the real cause of a park.

**Smallest viable bet:** reuse preflight's own `--dry-run` per item, and echo its verdict/`next:` line in
both the dry-run and the live park paths. All changes stay in `utils/py/jog_run.py`. The existing tests
change only where they must stay truthful.

**Alternatives rejected:** (a) A Jog-side probe for `.venv/bin/pytest` would duplicate preflight's
readiness rules, a second subsystem that drifts. (b) Running the live path in a "no-dispatch" mode would
take the lease and lock and promote docs, which breaks the dry-run zero-mutation contract.
(c) Failing dry-run with a nonzero exit when an item is not ready changes a script-visible contract that
was not requested. Dry-run stays exit 0 and reports.

**Rollback / containment:** a single-file revert of `utils/py/jog_run.py` (and the test text edit, if any).
No schema, ledger or contract changes. Reversibility: **Easy**.

### Ordered implementation

1. **Factor the shared pieces (DRY, no behaviour change).**
   - `_resolve_preflight_py(target)`: extract the existing target → `.xyz` → harness-home lookup from
     `run_marathon_phase`. `run_marathon_phase` calls it unchanged.
   - `_validate_execution_target(root, target)`: extract the read-only checks of `_execution_root` after
     `_require_jog_primary`. `_execution_root` = `_require_jog_primary(root)` + this helper.
   - `_preflight_summary(proc)`: one line from a completed preflight run: `"<verdict line value>[ — next:
     <reason>]"` from the `verdict` / `readiness` lines. If those are absent, it falls back to the first
     `BLOCKED` / `CONTRACT ERROR` / `swarm-preflight:` line, then the last non-empty output line, then
     `exit N`. It reads stdout and stderr together and never returns an empty string. If the process
     return code differs from the `(exit K)` in the printed verdict (a post-verdict failure), it appends
     `; preflight exited <rc>: <last line>`. A contradicted `ready` is therefore never reported unqualified
     (plan QA r1).
   → expect: `bash test/gh280-jog-marathon-adapter.sh` stays green with no other edit.
2. **Dry-run target readiness** (dry-run branch). With `--target-root`, call
   `_validate_execution_target` (no primary pin, matching the documented read-only contract). If the
   target is invalid, print `jog: [dry-run] live run would refuse --target-root: <reason>` and exit 2.
   For each listed item (same `--max-tasks` cap), run `swarm_preflight --gh-issue N --dry-run --out <path>`
   with `cwd=target, SWARM_PREFLIGHT_ROOT=target`, as the live call does. Also set
   `PYTHONDONTWRITEBYTECODE=1` for the child. `<path>` is a prospective, never-created directory under the
   system temp dir. It keeps the archive-root shell-out off the dry-run path, as in live (plan QA r1). If `find_issue_doc(target, N)`
   resolves to a 1-INBOX doc, run `--project-doc <that doc> --dry-run` instead, and label the line
   `(1-INBOX doc; live run promotes it first)`. Print `     preflight: <summary>` under each item. Without
   `--target-root`, output is byte-identical to today.
   **Effect contract** (plan QA r1): no write to the primary's `releases.db`/`releases.sql`, no
   `.tick/jog` state, no Jog supervisor lock, no lease, no packet. In the target, preflight's own
   operations run exactly as an operator's manual `swarm-preflight.sh --dry-run` would: `git fetch`, the
   transient ref worktree (created, removed and pruned), and any contract `command` probes. These are
   accepted, documented effects of reusing the one readiness engine. They are not "read-only". A probe
   that writes is the contract author's choice and behaves the same as in a live run.
   → expect: red control R1 (below) names `.venv/bin/pytest` per item; jog-queue.sh dry-run assertions unchanged.
3. **Live preflight park reason** (`run_marathon_phase`). Reword the pre-preflight line to
   `jog: running preflight for GH-N (execution <id>, packet: …)`, because the execution record already exists
   at that point and the record keeps its id. The existing `jog: dispatching marathon-drive` line still
   marks the real dispatch. When preflight refuses, print `jog: GH-N preflight refused: <summary>` and return
   `("parked", "preflight-refused (exit N): <summary>")`. The G8 prefix is preserved, and the stored reason
   now carries the `next:` cause.
   → expect: G8 green; R2 shows the verdict and `next:` on the console.
4. **Truthful halt line** (marathon branch, `jog_run.py:2393-2395`). For `parked`, print
   `jog: advancing halted: GH-N parked — <reason>` instead of the fixed landing-boundary text. This covers
   preflight, invalid invocation, missing preflight and awaiting-landing parks alike. The reason already
   says which one it is. `failed` and the legacy relay path's landing text are unchanged.
   → expect: R2 console has no `landing boundary` for a preflight park.
5. **Legacy relay preflight park** (`jog_run.py:2415-2417`): append `: <summary>` to the existing print and
   failure reason, using the same helper. This is a one-line change in the same defect class.
6. **Verify:** run the focused suites `bash test/gh280-jog-marathon-adapter.sh` and `bash test/jog-queue.sh` in
   a disposable full clone (`…-gate`). Record manual checks R1/R2/R3 under
   `TESTS-RESULTS/2026-11-11+GH-1426/` with `provenance.jsonl`. Then run the final gate on the route
   `utils/ci-route.sh` assigns (Python change → full route), once, on the final commit.

### Acceptance → check map

| Acceptance | Check |
|---|---|
| Dry-run + `--target-root` prints per-item verdict and `next:`; zero ledger writes or locks | **R1 (red control, manual):** a fixture queue with 2 pending items whose clone lacks the gate program. Pre-fix: `would process 2` and no reason. Fixed: each item prints `NOT-READY (exit 5) — next: gate program not found …`. Before/after: primary `releases.db` and `releases.sql` sha256 unchanged; `.tick/jog` unchanged; primary and target `git status --porcelain` unchanged; target `git worktree list` unchanged. I7 (existing) stays green on a ready target. |
| No `--target-root` → unchanged output | `test/jog-queue.sh` case 12 (existing) + R3 (manual): diff of dry-run output with no target, before vs after = empty. |
| Live preflight park prints the verdict and `next:`, not "landing boundary" | **R2 (red control, manual):** a live run against the same unready clone. Pre-fix console = the four lines in the report. Fixed: `preflight refused: NOT-READY (exit 5) — next: …` and `advancing halted: GH-N parked — preflight-refused (exit 5): …`. G8 (existing) still matches its prefix. |
| `marathon execution <id>` not printed before preflight | R2 console shows `running preflight for GH-N (execution …)`. A grep shows no `marathon execution` print precedes the preflight `subprocess.run`. |
| Existing Jog suites pass; evidence in TESTS-RESULTS | gh280 + jog-queue runs in a disposable clone, provenance committed. |
| (plan QA r1) Summary never hides a post-verdict failure | **R4 (manual, one-liner):** `_preflight_summary` on a synthetic completed process with stdout `  verdict     : ready (exit 0)` and returncode 1 → output contains `preflight exited 1`. On empty output with returncode 2 → `exit 2`. |

**Test non-scope:** no new suite, registry entry, fixture runner or guard (GH-831). Existing tests are
edited only if a pinned string changes; none is expected to.

**Non-goals:** bootstrapping `.venv` in clones; changing preflight readiness rules or output; a dry-run
exit-code contract; dry-run 1-INBOX promotion; sibling issues #1427 (claude-turn ceilings) and #1428
(reviewer gate / codex sandbox).

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** `046b41538`
- **Worker/CLI:** jog → marathon executor, builder `claude-builder`, reviewer `claude-reviewer`
- **Runtime:** Python (default)
- **Sandbox:** off

## Symptom

`jog run --dry-run --target-root <clone>` reported "would process 4 pending item(s)". The live `jog run` with the same flags then parked the first item at preflight (`exit 5 NOT-READY: gate program not found under target_root …: .venv/bin/pytest`). The disposable clone had no `.venv`. Dry-run never evaluates target readiness, so the gap only showed up after the live run took the lease and lock. The live run's console output also misreported what happened.

## Observed

| Claim | Command | Observed |
|---|---|---|
| Dry-run passes with a clone that is not ready | `releases_app.py jog run --dry-run --target-root <clone> --builder claude-builder --reviewer claude-reviewer` | `would process 4 pending item(s)`, exit 0 |
| Live run refuses at preflight | same command without `--dry-run` | row parked: `preflight-refused (exit 5): No packet written — candidate is not preflight-ready (NOT-READY).` |
| Cause is visible only by re-running preflight by hand | `swarm-preflight.sh --gh-issue 993 --dry-run` in the clone | `readiness: ready=0 — next: gate program not found under target_root <clone>: .venv/bin/pytest`, `dirty=0`, ref matches |
| Dry-run path skips the target | `utils/py/jog_run.py:2221-2238` | lists pending rows only; no preflight or target probe |
| Misleading console text | `utils/py/jog_run.py:2394` | any `parked` action prints `jog: advancing halted at landing boundary.` (including preflight-refused) |
| Misleading console text | `utils/py/jog_run.py:595` | prints `jog: marathon execution <id> …` before preflight runs; no Marathon execution happened |
| Cause swallowed | `utils/py/jog_run.py:597-600` | preflight runs with `capture_output=True`; its `readiness … next:` line is not echoed |

Live run console output, complete:

```text
jog: processing GH-993 (attempt 1) at position 1
jog: preflight script resolved outside this root (<clone>/.xyz/utils/py/swarm_preflight.py); SWARM_PREFLIGHT_ROOT pins evaluation to <clone>
jog: marathon execution gh993-exec1 for GH-993 (packet: <primary>/.tick/jog/<gid>/gh993-exec1/preflight)
jog: advancing halted at landing boundary.
```

Frequency: every time (deterministic: a target clone without the gate program).

## Root cause

Root cause: `jog run --dry-run` is hermetic toward the ledger, and it also does not inspect `--target-root`, so target readiness is not checked until a live run has already taken the lease and lock. Fix site: the dry-run branch of `jog_run_main` plus the park-message/echo path. Why not downstream: preflight already detects the condition correctly, so the defect is that Jog neither surfaces it early nor reports it accurately.

## Acceptance

- [ ] `jog run --dry-run --target-root <clone>` runs read-only `swarm_preflight --dry-run` per pending item against the clone and prints each item's verdict and `readiness next:` reason. Red control: with a clone lacking `.venv/bin/pytest`, dry-run currently prints `would process N`; fixed, it names the missing gate program per item. Still zero ledger writes, zero locks.
- [ ] Without `--target-root`, dry-run keeps its current queue-only output (no regression for read-only listing).
- [ ] When a live item parks at preflight, the console prints the preflight verdict and its `next:` reason, not `advancing halted at landing boundary.` Red control: the console output above.
- [ ] The `marathon execution <id>` line is printed only after preflight returns ready, or is reworded to say preflight is starting.
- [ ] Existing Jog suites (gh280 / Jog adapter) still pass; evidence recorded under `TESTS-RESULTS/` (no new suites, GH-831).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/gh280-jog-marathon-adapter.sh && bash test/jog-queue.sh",
  "fix_probes": [
    {"type": "grep_absent", "path": "utils/py/jog_run.py", "pattern": "def _preflight_summary\\("}
  ],
  "artifacts": ["utils/py/jog_run.py"]
}
```

(Plan QA r1 repaired this contract: the old one had a string `target`, a descriptive gate and an
unsupported `grep` probe type, and `extract_contract` refused it with exit 3. The probe reports `landed`
once the shared summary helper exists. The legacy landing string is intentionally retained, so it is not
probed.)

## PRS proposal

pri 55: an unattended scheduled Jog fire wasted its slot on a setup gap a dry-run should have caught.
sev 45: recoverable (row parks, no data loss), but the console misreports the cause, so the operator has to debug by hand.
appeal 50: makes dry-run trustworthy as the pre-fire check operators already rely on.
effort 70: small; reuses the existing preflight `--dry-run` and its output, in one file.

## Non-goals

- Bootstrapping `.venv` in target clones (operator/clone-setup responsibility; could be a separate follow-up).
- Changing preflight's readiness rules.

## Phase 0 — Diagnose & scope

### Checklist
- [ ] Reproduce in the intake repo with a target clone lacking its gate program
- [ ] Confirm write-set: `utils/py/jog_run.py` (dry-run branch ~2221, preflight call ~595-600, park message ~2394)
- [ ] Reuse `swarm_preflight --dry-run`; no new probe path (`/ponytail`)
- [ ] Set real ratings; clear `ratings_provisional`

### QA checklist — Phase 0
- [ ] Repro confirmed from the report, not assumed
- [ ] Existing suite or recorded manual check covers the failure path before the fix lands (GH-831)
- [ ] Fix composes with the existing harness rather than adding a parallel path
