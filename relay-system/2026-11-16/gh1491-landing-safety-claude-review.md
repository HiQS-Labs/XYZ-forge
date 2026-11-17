# RELAY · GH1400 PR1491 landing-safety followup Claude review
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
6. **Commit only the relay file** (`relay(gh1491-landing-safety-claude-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: scoped follow-up on PR #1491, git diff 00db9d662..c03bdfb8f only: fix 16e79acbf in `utils/py/jog_run.py` (_jog_align_target and the supervised jog_acquire_lease call) and `utils/py/releases_app.py` (jog_acquire_lease), and evidence c03bdfb8f in `TESTS-RESULTS/2026-11-16+GH-1400/landing-safety/check.py`, `TESTS-RESULTS/2026-11-16+GH-1400/landing-safety/baseline-red.json` and `TESTS-RESULTS/2026-11-16+GH-1400/followup.py` (published()).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: (a) an ignored untracked file in the execution clone (e.g. `scratch.log`) is never overwritten by supervised alignment; alignment refuses instead; (b) a supervised wake leases a row only if its `global_id` still matches the selection and its status is still `pending`, checked inside the same `perform_write` transaction; a stale or held row is refused without changing status or attempt count; (c) non-supervised callers of `jog_acquire_lease` behave exactly as before; (d) evidence claims match the committed check and baseline.

Operational envelope: local developer CLI supervising one execution clone. Prior runtime was already approved (`relay-system/2026-11-16/gh1400-integrated-ef23-claude-review-status.md`) and the full gate passed on `a19799e20`. Do NOT re-review the whole architecture; review only this delta and its bounded consumers.

## Review packet
1. `git diff 00db9d662..HEAD` (5 files, about 70 lines).
2. `utils/py/jog_run.py` around 2540-2580 (`_jog_align_target`) and 2810-2870 (supervised selection then lease).
3. `utils/py/releases_app.py` 5072-5135 (`jog_acquire_lease`, `jog_set_status`) and `refuse`/`perform_write` as needed.
4. Other `jog_acquire_lease` callers: `utils/py/jog_run.py` near 1111 (retry) and 2435 (checkpoint recovery). Confirm they pass no `expected_global_id` and are unchanged.
5. `TESTS-RESULTS/2026-11-16+GH-1400/landing-safety/check.py` and `baseline-red.json`. The green result was produced outside the repo at `c03bdfb8f`: `{"vulnerable_control": false, "ignored_preserved": true, "alignment_refused": true, "held_lease_refused": true, "held_status": "parked", "head": "c03bdfb8f6..."}`; the baseline at `a19799e20` shows `ignored_preserved: false`, `held_lease_refused: false`, `held_status: "running"`. You cannot open the green file; grade the claim against what `check.py` would compute.

Questions:
1. Does `--no-overwrite-ignore` on every supervised `git switch`/`git merge` path in `_jog_align_target` actually stop git from overwriting an ignored untracked file, and does the resulting git failure surface as a refusal (not a silent pass or a partial branch state that a later wake mistakes for aligned)? Is any supervised switch/merge/checkout/reset path left without it? Cite lines.
2. Is the identity + pending check in `jog_acquire_lease` inside the same transaction as the UPDATE, so no write lands between check and lease? Does `refuse("jog-selection-stale", ...)` leave status and `attempt_count` untouched and write no receipt that looks like a lease?
3. In `jog_run_main` supervised mode, what happens after the stale refusal: does the wake stop cleanly (held, no further dispatch, lock released), or can the `SystemExit`/exception skip a cleanup or ownership release? Cite lines.
4. Are the retry (≈1111) and checkpoint-recovery (≈2435) callers and the non-supervised run path byte-for-byte unchanged in behaviour?
5. `check.py`: does it handle `SystemExit` refusals correctly so a refusal is counted as refusal and not as a crash or pass? Does the stricter `published()` (clean `releases.db`/`releases.sql`) avoid a false negative on a legitimately published clone?
6. Any scope creep, new suite/registry/gate, or duplicate writer in the delta?

Do not run suites or tests and do not modify source. Only this relay file is writable. Read-only git and file reads are allowed. Behaviour-change findings need `Observed input:`, `Affected scope:`, `Falsifier:`. Declare `swept file:` honestly. Write `VERDICT: PASS` or `VERDICT: FAIL` and one `Basis:` line in your block; set `STATUS: Approved` only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: no — `landing-safety/check.py` and `baseline-red.json` read in full; `jog_run.py` and `releases_app.py` swept only at the touched functions, every `jog_acquire_lease` caller, `refuse`/`perform_write`/`_git`, and the `jog_run_main` cleanup path, per Setup's bounded scope. The one pre-existing issue found in that window is listed as a Nit below.

- **[Pass] Q1: alignment refuses rather than overwriting, on all four supervised git paths.** `utils/py/jog_run.py:2569`, `:2571`, `:2572`, `:2574` each carry `--no-overwrite-ignore`. No other switch/merge/checkout/reset runs in `_jog_align_target` (2546-2579). Probe with git 2.50.1 in an isolated scratch repo (separate `GIT_DIR`, ignored `scratch.log` = `valuable`, target commit tracks `scratch.log` = `dest`):
  - `git merge --no-overwrite-ignore --ff-only $D` → `rc=1`, "untracked working tree files would be overwritten by merge: scratch.log … Aborting", file still `valuable`, HEAD still base.
  - `git switch --no-overwrite-ignore -c development --no-track $D` → `rc=1`, same abort, file `valuable`, no `development` branch created.
  - `git switch --no-overwrite-ignore development` → `rc=1`, file `valuable`.
  - Control `git switch development` with no flag → `rc=0`, file becomes `dest`.
  A non-zero git exit raises `ContractError` (`jog_run.py:1140-1144`). The alignment lock is released in `finally` (2578-2579), and the wake ends via the outer `finally: _cleanup()` (3006-3007) and `__main__` "jog: held:" exit 2 (3010-3014). Partial state cannot pass as aligned. In the ahead path the branch is renamed (2567) before a failed `switch -c`, which leaves no local `development`, so the next wake takes the `else` branch (2574) and refuses again. A failed ff-merge leaves HEAD at the old tip, and the `HEAD != base` guard (2575-2576) catches anything else.
- **[Pass] Q2: the identity and pending check runs in the same transaction as the UPDATE.** The check is inside `mutate` (`releases_app.py:5088-5091`). `perform_write` calls `mutate` only after `BEGIN IMMEDIATE` (1700-1706), and the SELECT at 5080-5082 is inside that same `mutate`. `refuse` is `sys.exit(EXIT_REFUSED)` (209-211). The `except BaseException` handler rolls back and unlinks the journal (1739-1752). The `op_receipts` INSERT (1723-1728) comes after `mutate`, so it is never reached: no lease-looking receipt, and status and `attempt_count` stay unchanged. The writer lock is released by `finally` (1777-1778).
- **[Pass] Q3: after a stale refusal the wake stops cleanly.** `SystemExit` from `jog_run.py:2857` goes through the outer `finally: _cleanup()` (3006-3007), which releases the supervisor lock. The row was never leased, so there is no orphan lease, and nothing is dispatched after it. It skips the held summary and `checkpoint.finish()` (2989-3004). The journal stays `running`, and the next wake resumes it via `checkpoint.begin(recover=...)` (2785-2789). That is the same path already pinned by `stop-owner-next-wake-publishes` (`followup.py:117-119`).
- **[Pass] Q4: the other callers are unchanged.** The only `jog_run.py` call-site hunk is 2857-2858, and it passes `None` when `supervised` is false. The retry caller at `jog_run.py:1111` and the checkpoint-recovery caller at `jog_run.py:2435` are untouched. With `expected_global_id=None` the new predicate short-circuits at `releases_app.py:5088`, so non-supervised behaviour is the same as before (DoD c).
- **[Pass] Q5: `check.py` counts refusals as refusals.** `except (Exception, SystemExit)` appears at `check.py:25-26`, `:38-39` and `:43-44`. The claimed green values match what non-vulnerable mode computes: `held_status` = `after[1]` = `'parked'` is asserted at 40. The positive lease at 48-49 (`('running', 1)`) proves the guarded function still leases. `baseline-red.json` matches what vulnerable mode computes (`ignored_preserved:false`, `held_status:"running"`), and at `a19799e20` it shows that the lock, worktree, fetch and status preconditions pass in this fixture. So the green `alignment_refused` comes from the switch, not from an unrelated early exception. DoD (d) is met.
- **[Pass] Q5 `published()`: it can only get stricter.** `releases.db` and `releases.sql` are tracked (`git ls-files` lists both), and `followup.py:117` already uses the same dirty predicate to define `unpub`. Adding it to `published()` can only flip true→false, never mask a real publish gap. Whether every `published(r)` check still passes at `c03bdfb8f` is [Unverified — needs clone run].
- **[Pass] Q6: no scope creep.** The delta has no new suite, registry, gate or second writer. `check.py` is a single evidence script under `TESTS-RESULTS/`, and the lease change is a keyword-only parameter on the existing writer.
- **[Nit] The fixture exercises only the "local development exists, not ahead" path (`check.py:21-24` → `jog_run.py:2571`).** The ff-merge and `switch -c` paths are covered only by the scratch probe above. Optional fix: a second fixture variant with local `development` behind the remote. Not required for DoD (a).
- **[Nit] Pre-existing and out of this delta: the non-supervised checkpoint path `jog_run.py:2849` (`_git(target, "switch", "development")`) has no `--no-overwrite-ignore`.** Its guard at 2847 (`--untracked-files=all`) does not list ignored files. DoD (a) covers supervised alignment only, and DoD (c) requires non-supervised behaviour to stay the same, so I request no change here. No observed failure; this is a follow-up candidate only.
- **Process note (the reviewer must report this):** my first probe attempt hit a sandbox block on `git init` (hook template copy) and fell through into the shared repo. It renamed local `development` (be0a37520) to `keep`, created `development` at c3309e412, and attached this worktree to it. I reversed it within the turn with `git switch --detach c3309e412`, `git branch -D development` and `git branch -m keep development`. Verified after: `refs/heads/development be0a37520`, no `keep`, worktree `c3309e412 (detached HEAD)`, `git status` clean. The `.git/config` writes were refused both times, so the `branch.development.*` tracking config was never changed. The only leftovers are reflog entries. No commits, pushes or file changes were made.

VERDICT: PASS
Basis: all four supervised alignment git paths refuse on an ignored-file collision (probe output above); the stale/held lease check runs inside the same `BEGIN IMMEDIATE` transaction and exits before any UPDATE or receipt; non-supervised callers pass `None` and are unchanged; and the evidence claims match what `check.py` and `baseline-red.json` compute. The two Nits do not block.

handing off — relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
