# RELAY · GH1400 integrated ef23 Claude review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1400-integrated-ef23-claude-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the integrated GH-1400 supervisor candidate `ef23e77b24e51add4be9476191257bcbc7d7c432` (task delta vs origin/development f346d8908a42: `utils/py/jog_run.py`, `utils/py/releases_app.py`, `skills/2-daily/jog/SKILL.md`, `CHANGELOG.md`, `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, `decisions/2026-11-15-gh1400-bounded-jog-wake.md`, `releases.sql`), its upstream integration vs published PR head `0d1dc0fe8395` (notably `utils/py/swarm_preflight.py` and its Jog consumer seams), and the evidence-only commit `7a95a1d0c8c8` (`TESTS-RESULTS/2026-11-16+GH-1400/integration-ef23-review/`).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the integrated candidate preserves the approved task-local failure continuation (`relay-system/2026-11-16/gh1400-followup-final.claude.md`, attested PASS at `185db9741037`) with no new integration regression; shared-safety conditions still stop all dispatch; saved-approved-result adoption on restart happens exactly once and inconsistent or missing receipts hold; Jog's use of the upstream `swarm_preflight.py` changes still works; evidence and limits are stated honestly.

## Review packet

Read in this order:
1. `git diff f346d8908..ef23e77b2 -- utils/py/jog_run.py utils/py/releases_app.py skills/2-daily/jog/SKILL.md CHANGELOG.md releases.sql` (task delta on development).
2. `git diff 0d1dc0fe8..ef23e77b2 -- utils/py/swarm_preflight.py` and confirm `git diff 0d1dc0fe8..ef23e77b2 -- utils/py/jog_run.py utils/py/releases_app.py` is empty (Jog runtime blobs unchanged from the attested head). Then check Jog's preflight consumer seams against the new preflight (`--gh-issue`/`--out`, readiness exit handling, `marathon-invocation.json` publication).
3. `git show ef23e77b2` (plan outer-loop alignment only) and `git show 7a95a1d0c --stat` (reports only).
4. `relay-system/2026-11-16/gh1400-integrated-ef23-review-status.md` (the verification agent's bounded source assessment; it is NOT an independent approval, so do not inherit its conclusions — verify cited lines yourself).
5. `TESTS-RESULTS/2026-11-16+GH-1400/integration-ef23-review/SUMMARY.md`, `results.json`, `provenance.jsonl`, identity JSON, and the per-control logs (`restart-*`, `red-*`, `stop-*`, `local*`, `held.log`, `jog-adapter.log`).

Questions:
1. Classification: does `_jog_task_local_failure` and its use in `jog_run_main` still continue only on a task-local red gate, fail closed on every exception or non-matching field, and sit only on the supervised `failed` path after integration? Cite lines.
2. Shared safety: can any path skip the lock/ownership, deadline/max-tasks, target-alignment or checkpoint checks before the next dispatch? Cite lines.
3. Saved-result adoption: does `_jog_supervise_recover` → `jog_resume` → `publish_jog_receipt` adopt a saved approved result exactly once without a builder, keep budgets, and hold on missing/corrupt/mismatched receipts? Which `restart-*` log proves each?
4. Integration: does any upstream change (especially `swarm_preflight.py`) break or weaken a Jog seam, exit code or file contract? Cite both sides.
5. Evidence honesty: do the 23/23 controls and 227/227 suite logs match the claims, are identities unchanged, and are limits (shared environment fault indistinguishable from task-local red, one bounded attempt per later task, mid-wake checkpoint contradiction detected at finish, synthetic-only controls) stated truthfully?
6. Any scope creep, new suite/registry/gate, env leak, retry or duplicate writer in the task delta?

Pending, not a finding: the classified full gate runs once on the approved commit after this review. Grade it as pending.

Do not run suites or tests and do not modify source. Only this relay file is writable. Read-only git and file reads are allowed. Behaviour-change findings need `Observed input:`, `Affected scope:`, `Falsifier:`. Whole-file sweep of all touched files is not expected for `swarm_preflight.py`'s unrelated upstream refactor; declare `swept file:` honestly for what you read.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude)

swept file: no — read in full: the task diff `f346d8908..ef23e77b2` for `jog_run.py`/`releases_app.py`/`SKILL.md`/`CHANGELOG.md`/`releases.sql`; the whole `0d1dc0fe8..ef23e77b2` diff of `swarm_preflight.py` (1437 lines); `jog_run.py:636-675`, `:2496-2635`, `:2770-3006`; `load_marathon_result` (`jog_run.py:135-165`); `cmd_jog_retry` (`releases_app.py:4937-4975`). Not read: the remaining ~2,400 lines of `jog_run.py` and the parts of `swarm_preflight.py` the refactor did not touch. I found no defects in the code I read that block this change.

Identity probes (read-only git, all exit 0):
- `git diff --stat 0d1dc0fe8..ef23e77b2 -- utils/py/jog_run.py utils/py/releases_app.py` → empty. `git diff --stat 185db9741037 0d1dc0fe8 -- utils/py/jog_run.py utils/py/releases_app.py skills/2-daily/jog/SKILL.md` → empty. So the Jog runtime is byte-identical to the head the follow-up review attested (`gh1400-followup-final.claude.md:112` `VERDICT: PASS`, `:8` `STATUS: Approved`).
- `git diff --quiet ef23e77b2 HEAD -- utils/py/ skills/` → unchanged. HEAD differs from the candidate only by the evidence and relay commits.

Findings:
- [Pass] Q1 classification. `_jog_task_local_failure` (`jog_run.py:2500-2525`) returns a reason only when all of these hold: exactly one new execution (`len(executions) != prior_executions + 1` → None); status `projected-failed` and outcome `escalated`; the receipt loads and matches the issue and execution (`_jog_result_identity`); `reason == "pre-advance-failed"`, `exit_code == 5`, `gate.result == "red"`, the gate exit is an int, not a bool, and not in `(0, GATE_GUARD_KILL_EXIT)` (`marathon_drive.py:971` `= 108`); `approval_preserved` is not set; and the target realpath matches. `ContractError/OSError/TypeError/ValueError/AttributeError` all return None. `load_marathon_result` requires `gate` and `target_repo` to be dicts (`jog_run.py:162-164`), so the field reads after the try block cannot raise AttributeError. The only call is `jog_run.py:2916`, inside `if action == "failed":` (`:2915`), and it is guarded by `supervised and`. On match the row stays as `jog_set_status(..., action)` left it (`:2893`, `failed`); the loop selects only `status = 'pending'` (`:2824`), so the row is never retried.
- [Pass] Q2 shared safety. A `continue` at `:2921` returns to the loop top. There the deadline check (`:2809`) and the max-tasks check (`:2812`) run first, then the pending select, then `_jog_align_target` and `_validate_execution_target` (`:2836-2838`). `_jog_align_target` takes the conservative clone lock and holds on dependent worktrees, tracked changes or a detached HEAD (`:2546-2557`). Each selected item counts before dispatch (`:2858-2859`). The supervisor lock is taken conservatively for the whole run (`JogSupervisorLock(root, conservative=supervised)`, task diff hunk at `:2762`). Unknown or initializing lock owners raise an error (diff `:1544-1545`). A dispatch deadline overrun raises ContractError from `_jog_process` (`:2528-2543`) and never continues. As stated, checkpoint ownership is not rechecked between dispatches. `check_owned()` runs only in `begin`/`finish` (`:2221`, `:2231`, `:2257`).
- [Pass] Q3 adoption. `_jog_supervise_recover` (`:2582-2634`) raises on a live or stopped lease pid. It parks an orphan running row that has no executions. For the latest execution, or the latest gate retry, it requires a result path, a loadable receipt, a matching identity, a matching target, `outcome == "approved"`, and an invocation `target_root` equal to the target. Only then does it call `jog_resume`. Any ContractError parks the row as `supervision held: …`. `results.json` shows the builder ran once: `restart-adopts-once` has `after_kill.starts {"901": 1}` and `starts {"901": 1, "902": 1}` after restart, with GH-901 `parked` `awaiting-landing (PR #901 …)` (`restart-adopts-once-restart.log` lines 3-4 `terminal Marathon result re-projected` / `recovered GH-901 without a new builder or attempt`). In `restart-missing-holds` GH-901 is parked with `supervision held: marathon result unreadable`. In `restart-corrupt-holds` GH-901 is parked with `supervision held: marathon result at …`. In all three, attempt_count stays 1. `red-mismatched-receipt` stops the run (`902` stays `pending`, reason `result receipt does not match the selected issue/execution`).
- [Pass] Q4 integration. The `swarm_preflight.py` delta is a structural refactor. `main()` is split into `parse_args`/`resolve_source_selection`/…/`write_packet` (diff `:1423-1433`), and type annotations are added. Jog depends on four things, and each is preserved: `--gh-issue` stays `action="append"` (diff `:692`), and `--out` stays `dest="out_dir"` (`swarm_preflight.py:1333`); the exit codes are unchanged, `STALE` 4 / `NOT-READY` 5 / `BLOCKED` 6 / `AMBIGUOUS` 7 (diff `:1141-1144`), still `sys.exit(code)` before any packet is written (diff `:1232-1236`); `marathon-invocation.json` is still written to `out_dir` with `harness_root: root` / `target_root` (`swarm_preflight.py:1214-1218`, diff `:1284-1291`); `SWARM_PREFLIGHT_ROOT` still sets the root (diff `:707`). On the Jog side, `jog_run.py:644-671` uses exit 4 as completed-stale and any other non-zero exit as parked/halted, and pins both roots. Behavioural evidence: `test/gh280-jog-marathon-adapter.sh:261,451` runs the real copied preflight. `jog-adapter.log` shows `PASS: A1 root preflight exits 0` and `PASS: E1 vendored preflight exits 0`, and `G8 preflight refusal parks with exit code` passes.
- [Pass] Q5 evidence. `followup.log` reads `{"complete": true, "passed": 23, "required": 23, "failed": [] , "source": "ef23e77b2…"}`, and the 23 IDs in `required.json` match. `jog-adapter.log` ends `227 pass, 0 fail`. `cmp identity-before.json` matches both `*-identity-after.json`. `provenance.jsonl` records head `ef23e77b2…` and exit 0 for both runs. The `baseline-red` control (baseline `1d9658c3`) shows the old code stopping (`starts {"901": 1, "902": 0}`). The limits are stated truthfully. Shared fault indistinguishable from task-local red: `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md:308-309`. One attempt per later task: `:310`. Fixture-only preflight and worker: `provenance.jsonl` `"scope": "23 real-entrypoint synthetic controls; fixture preflight and worker"`. Mid-wake checkpoint contradiction caught at finish: status doc. Note: the 23 controls use a fixture `swarm_preflight.py` (`followup.py:56`), so the adapter suite is the only real-preflight evidence. That is adequate for a refactor that preserves the interface.
- [Pass] Q6 scope. There is no new suite, registry, gate, queue or ledger. The flag is opt-in (`--supervise-until`, `jog_run.py:2656`). The env passthrough is unchanged (`{**os.environ, "SWARM_PREFLIGHT_ROOT": target}`, `:647`). Retry history gets a single writer: the gate-retry record is appended once before dispatch and updated in place (task diff `:97-117`). Supervised mode never calls retry-build (`SKILL.md` delta: "This wake never calls retry-build").
- [Nit] `jog retry` under a supervised wake. `cmd_jog_retry` resets a failed row to `pending` (`releases_app.py:4966`). The next supervised wake's `_jog_supervise_recover` then scans that pending row (`jog_run.py:2588-2589`), finds the latest execution not approved, and re-parks it with `supervision held: latest execution is not approved; explicit retry decision required` (`:2622-2623`, `:2630-2631`). This matches the documented intent ("failed results remain held for an explicit retry decision"; plan `:197-198`), so I am not asking for a code change. Fix (docs only, optional): add one line to the SKILL.md wake section saying that `jog retry` does not re-arm a row for a supervised wake, and that `retry-build` is the explicit path.
- Pending, not a finding: the classified full gate on the approved commit runs after this review.

VERDICT: PASS
Basis: Static reads confirm the integrated candidate keeps the approved task-local continuation byte-for-byte: Jog blobs are identical to the attested head `185db9741037`. Continuation sits only on the supervised `failed` path and fails closed. Shared-safety checks run before every dispatch. Recovery adopts a saved approved result once and holds on missing, corrupt or mismatched receipts. The upstream `swarm_preflight.py` refactor keeps every seam Jog uses. The evidence matches its claims and states its limits. The only finding is one optional docs Nit. The full gate is pending.


### Attestation · relay-drive — 2026-11-17T04:53:41Z
task: RELAY-gh1400-integrated-ef23-claude-review
reviewer: claude
status: Approved
reviewed-head: 628b1369aed61945145c6ce0a06f830cdb7793f6
added-range: 9499+8494
added-sha256: 9e6af767601aa7d60ef9282e2ff5bf9514a16d248a50f039c90cc38dc24269ca
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
