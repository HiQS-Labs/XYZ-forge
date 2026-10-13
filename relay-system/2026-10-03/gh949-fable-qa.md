# RELAY · PR 953 independent Claude Fable 5.1 high QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr-953-independent-claude-fable-5-1-high-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-949-ATE-REMEDIATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-949-ATE-REMEDIATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-fable-qa   ·   Producer: codex-producer
- Started: 2026-10-03
- Definition of Done: Independent whole-file QA of PR #953 head92a8a230c57ce65f4fdb9c1725a8429f4d9816e0: all F1–F9/K1 requirements, preserved callers/contracts, grounded before/after evidence, no unjustified new machinery.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## QA packet

User explicitly requested Claude Code Fable5.1 high via relay-xyz. Launch is pinned to claude-fable-5-1 and high effort, first-party subscription authentication. Sign this independent review as Claude Code Fable5.1 high; the earlier GPT6AstraLight label identifies a different review.

Target PR https://github.com/HiQS-Labs/XYZ-forge/pull/953 at92a8a230c57ce65f4fdb9c1725a8429f4d9816e0, base ancestry3fbed72f781d1ad060e298b798a44c32edef393d. Read canonical plan, recon-gh949-ate-remediation.md, TESTS-RESULTS/2026-10-03+GH-949/SUMMARY.md and relevant raw provenance. Review all six complete changed runtime files: utils/py/proc_group.py, utils/py/domain_oracles.py, utils/py/metamorphic_oracle.py, utils/ate/scripts/run_variations.py, skills/1-hourly/relay-xyz/find-harness.sh, test/lib/runner-envelope.sh. Trace material consumers (fuzz_engine, claude_cli, wave_reconcile, checkin/compile_issue, runner callers) by direct source as needed. Don't assume previous QA proves correctness.

Scope is a local developer CLI. Examine actual cancellation/cleanup, launch-before-admission, all timeout and idempotence observations, directory links/common and worktree Git metadata, structured failure records/UTC, unset HOME and gate selector precedence. Normal-success background children and deliberate session escape/SIGKILL are outside this contract. Zero-budget returns nonzero/no new rows but retains existing initialization; only empty grids promise no writes. Proportionality: no new executor, gate, suite, schema or speculative enterprise infrastructure.

Evidence: all original manual repaired controls and nine existing focused suites pass. Prior independent final QA identified and fixed first-versus-later rc/stdout comparison; red/green actual-process receipts retained. Full local push gate passed870s on992914e6, no bypass/identity drift. Final head differs only by docs/ledger merge and receipts; runtime identical. Hosted blocking smoke succeeded at92a8a230; promotion and advisory jobs skipped by conditions. These are supplied receipts, not assertions that you reran them.

Graph handoff: Verify tier; nearest project XYZ-forge is primary checkout, generation2026-09-01T15:54:30Z. Search claude_cli exhausted with0 results. Coverage: proc_group/domain_oracles/claude_cli/locator/envelope not_tracked; ATE excludedsubtree; metamorphic metadata matches only other checkout. Direct source is required for material claims. Prior recon documents call paths and uncertainty. Do not claim graph access if unavailable.

Review-only, relay file only writable. Do not run mutation-heavy suites, pytest, executable fixtures, model calls, installs or Git commands in the relay worktree. Narrow read-only/in-memory probes allowed under .relay-scratch per protocol; runtime fixture work must be reported as needing a separate full clone. Do not commit or push yourself; harness handles file-scoped commit. A concrete blocker needs observed input, affected scope, falsifier, exact citation and small fix direction. Record PASS/FAIL with honest evidence limits, sweep declaration, and token handoff. No merge authority. Marker stays last.

## Log

### Reviewer · Round 1 (claude-fable-qa — Claude Code Fable5.1 high)

swept file: yes

Sweep covered, in full: the artifact, `recon-gh949-ate-remediation.md`, `TESTS-RESULTS/2026-10-03+GH-949/SUMMARY.md`, and all six runtime files (`proc_group.py` 251 lines, `domain_oracles.py` 647, `metamorphic_oracle.py` 401, `run_variations.py` 602, `find-harness.sh` 510, `runner-envelope.sh` 125). Consumers read by direct source: `fuzz_engine.py:245`, `claude_cli.py:46`, `wave_reconcile.py:654`, `test/lib/runaway-guard.sh:56-125`, `checkin.py:66-130`, `compile_issue.py:52-64`, `validate.sh:1238`, `ci-local.sh:399`. Graph not used (packet reports these paths not_tracked); no Git commands run by me, so base behaviour is taken from recon, not re-observed. Probes ran under `.relay-scratch/` only (`probe.py`, exit 0, plus two shell probes quoted below). Suites, pytest, `validate.sh` and ATE fixtures were NOT run here.

**VERDICT: FAIL**

**Basis:** nine of ten requirements hold on source and on my own probes, and the retained before/after evidence is real and non-empty. One observed defect blocks: the oracle CLIs now put the command under test in its own session but have no cancellation boundary, so terminating the oracle (including by this repo's own timeout wrapper) leaves the command running with nothing left to enforce its timeout. That is the F1/F8 failure class this PR exists to remove, it is reachable through an existing caller, and the fix is a few lines using the helper this PR already added.

#### Findings

- **[Blocker] B1 — oracle CLI termination orphans the command under test.** `domain_oracles.py:127` and `metamorphic_oracle.py:185` now launch through `run_bounded` (`start_new_session=True`, `proc_group.py:122-125`), but `domain_oracles.py:646-647` and `metamorphic_oracle.py:400-401` call `sys.exit(main())` with no `cancellation_signals()`. Default SIGTERM kills the Python process before `run_bounded`'s `except BaseException` cleanup (`proc_group.py:139-146`) can run, and a group kill of the oracle no longer reaches the command because it left that group.
  - Observed input: `python3 utils/py/proc_group.py --timeout 2 --grace 1 -- python3 utils/py/domain_oracles.py --mode idempotence --cmd "sh -c 'echo \$\$ > $s/p1; exec sleep 40'" --cwd "$s" --repetitions 2` → `guard_rc=124`, then `kill -0` on the recorded pid → `group-kill: oracle command pid 88842 SURVIVED`. Same command run directly and sent `kill -TERM` → `oracle_rc_after_TERM=143`, `direct-TERM: oracle command pid 90870 SURVIVED`. Both survivors were killed by the probe afterwards (`p1 cleaned`, `p2 cleaned`).
  - Affected scope: any `domain_oracles.py` / `metamorphic_oracle.py` CLI run (modes zero-state, containment, idempotence, crash-recovery recover step, suite) that receives SIGTERM or is group-killed by a cap — i.e. `runaway-guard.sh:91-93` `run_with_timeout`, `fuzz_engine.py:245` fuzzing the `domain-oracles-cli` target (`gen4_campaign.py:72`), or an operator `kill`. Library callers are unaffected.
  - Falsifier: run the same two commands at base `3fbed72f` in a disposable clone. Expected: the group-kill case shows the pid gone at base (recon line 37: base `_run` was raw `subprocess.run`, same process group), which makes this a regression; if the pid also survives at base it is a pre-existing gap, still inside plan step 1 ("At CLI entry boundaries translate SIGTERM into catchable cancellation"). After the fix both probes must report the pid gone and rc 124 / 143.
  - Fix direction: wrap the two `__main__` blocks exactly as `proc_group.py:246-251` and `run_variations.py:597-602` already do (`with cancellation_signals(): sys.exit(main())`, `except Cancelled: sys.exit(128 + exc.signum)`). No new helper, executor or suite. Then correct artifact line 87 and SUMMARY line 24, which say only two CLI boundaries own handlers. Limit to state honestly: threaded `--concurrent` idempotence still waits for worker children to hit their own timeout; that is bounded and may stay as is.

- **[Should] S1 — the linked-worktree config blind spot fixed for F3 still exists in the touched metamorphic file.** `metamorphic_oracle.py:102-108` hashes `<repo>/.git/config` only; in a linked worktree `.git` is a file, the path does not exist, and `config_hash` stays `""` before and after, so `check_zero_mutation` (`:153`) and `differential_oracle.py:27` cannot see a config change.
  - Observed input: this relay worktree — `python3 -c "import os; print(os.path.isfile('.git'), os.path.exists('.git/config'))"` → `git_is_file True config_exists False`.
  - Affected scope: `_capture_repo_state` when `repo_dir` is a linked worktree.
  - Falsifier: in a clone, a linked worktree plus `git config` change wrapped in `check_zero_mutation`; expected today `passed: True` with empty mutations. If it reports the change, this finding is wrong.
  - Fix direction: not required for this PR's F3 (which is scoped to `host_identity`); either reuse the `--git-common-dir` resolution from `domain_oracles.py:241-267` or file a follow-up issue. Producer's call; I will not hold approval on it.

- **[Pass] F1/F7 process helper.** Cleanup-and-re-raise on any exception: `proc_group.py:139-146`; spawn errors still propagate because `Popen` sits outside the `try` (`:122`); result shape unchanged (`:71-78`). Probe E: SIGINT during `run_bounded(... "sleep 60 & echo $$ $! > pids; wait")` → `"raised": "KeyboardInterrupt", "survivors": []`. Probe G: CLI under SIGTERM → `"rc": 143, "group_alive": false`; under SIGINT → `"rc": 130, "group_alive": false`. Probe F: no `--timeout` → `"rc": 2, "sentinel_exists": false`, `error: --timeout is required unless --kill-pgid is used` (`:173-174`, before `Popen` at `:176`). `--kill-pgid` stays timeout-free (`:168-170`), matching `runaway-guard.sh:64-65`. Codes 125/124/127 unchanged (`:179,196,226,237`).
- **[Pass] Callers preserved.** `fuzz_engine.py:245-253`, `claude_cli.py:46-48`, `wave_reconcile.py:654-660` read only `timed_out/rc/stdout/stderr`, all still present at `proc_group.py:71-78`. `run_with_timeout` always passes `--timeout` (`runaway-guard.sh:91-93`).
- **[Pass] F8 oracle timeout.** `_run` marks `completed = not timed_out` and launch failure `completed False` (`domain_oracles.py:124-136`); zero-state and containment reject it (`:221-222`, `:324-325`); idempotence rejects first and later runs (`:375-378`, `metamorphic_oracle.py:187-189,207-208`). Probe B: missing executable → `[127, false, false]`; `exit 124` → `[124, true, false]`; timeout → `[124, false, true]`, `"timeout_wall_s": 1.11`, `"late_write_exists": false` four seconds after return. Probe C (threaded): `"passed": false, "completed": false, "exit_codes": [null, null]`.
- **[Pass] First-versus-later comparison (final QA R1 repair).** `domain_oracles.py:383-387`. Probe D: first-only output → `"first_only_passed": false, "reasons": ["output digest differs from first run"]`; stable output → `"stable_passed": true`. Retained receipts agree: `manual-idempotence/before/results.json` shows `"passed": true` for rc 3 vs `[0, 0]`; `after/results.json` shows `"exit code differs from first run"`.
- **[Pass] F2 directory links.** `domain_oracles.py:95-103` adds symlinked directory entries without following them. Probe A: `add_detected True retarget_detected True remove_restores True counts 2 3 3` (target contents not traversed).
- **[Pass] F3 linked Git config — on source only.** Common-dir and `config.worktree` resolution with errors surfaced, not compared as empty: `domain_oracles.py:244-267`, enforced at `:326-327`. I did not run Git, so runtime behaviour rests on the supplied `manual-state` and `manual-contracts` receipts.
- **[Pass] F4/F5/F9 and cancellation rows — on source.** Empty grid refused before the control write: `run_variations.py:436-438` precedes `:451`. Zero-budget returns 2 with no row: `:462-464`, `:581-583`; initialization at `:451-455` is retained as the artifact states. Spawn error and interruption become one row then stop: `:484-492`, `:497-499`, `:567-572`. UTC: `:422`, `:552`. Readers accept the rows: `checkin.py:69`, `compile_issue.py:52-64`. Receipt `manual-contracts/results.json`: `"rc": 2 ... "row_bytes_preserved": true`, `"category": "spawn_error", "checkin_rc": 0`.
- **[Unverified — needs clone run]** F1 ATE cancellation end to end (130/143, one `interrupted` row, prior bytes kept), F4 no-write, F5 one-row. Source supports each; proving them needs a scratch Git repo and the ATE runner, which this turn may not run.
- **[Pass] F6 HOME absent.** Guards at `find-harness.sh:122-126`, `:129-139`, `:356`; no root-relative fallback remains. Probe: `env -u HOME -u XDG_CONFIG_HOME XYZ_HARNESS="$PWD" bash skills/1-hourly/relay-xyz/find-harness.sh --root --quiet` → rc 0, printed this worktree; same with `XDG_CONFIG_HOME` set → rc 0. The "missing fallback truthfully refuses" half is **[Unverified — needs clone run]** (needs a directory outside any harness).
- **[Pass] K1 selector scrub — on source.** `runner-envelope.sh:62` unsets `XYZ_HARNESS XYZ_REPO_ROOT` once in `runner_envelope_begin`; `XYZ_HARNESS_DB` still wins (`:65`). Neither runner reads the scrubbed names (`rg "XYZ_REPO_ROOT|XYZ_HARNESS\b" validate.sh ci-local.sh` → no hits outside the envelope), and both call begin before dispatch (`validate.sh:1238`, `ci-local.sh:399`). The 50/0 and 41/0 suite counts are supplied receipts, not rerun.
- **[Pass] Proportionality.** No new executor, gate, suite, schema or dependency in the six files; the only new surface is `Cancelled` + `cancellation_signals` (`proc_group.py:44-68`), reused by two entry points.
- **[Nit] N1** `check_zero_mutation` still uses leader-only `subprocess.run(timeout)` (`metamorphic_oracle.py:127-144`); a timed-out command's children can write after return. Verdict is already fail, and the plan scoped step 2 to idempotence — note only.
- **[Nit] N2** `tree_digest` ignores empty directories: probe A `"empty_dir_add_detected": false` (`domain_oracles.py:95-105`). Pre-existing, outside F2.
- **[Nit] N3** In both cleanup paths a `TimeoutExpired` from `proc.wait(timeout=grace + 5)` would replace the original exception (`proc_group.py:142`, `:241`). No observed input; needs a group that outlives SIGKILL.
- **[Nit] N4** A later-run timeout is reported as "exit code / output digest diverged across repetitions" (`domain_oracles.py:377-378`); the verdict is right, the wording is not.
- **[Nit] N5** With neither `HOME` nor `XDG_CONFIG_HOME`, `CONFIG_FILE` is empty, so `--check` would print a save hint redirecting to `''` (`find-harness.sh:410-416`) and the not-found message prints blank location lines (`:265-266`). Read from source, not observed.
- **[Nit] N6** Artifact is internally stale: line 87 says "final review/gate outstanding" while line 93 records the gate green and PR open; Phase 3 boxes at lines 79, 83, 85 are unchecked against that same status. Reconcile when closing.
- **[Nit] N7** Duplicate `import sys` (`run_variations.py:39`, `:41`). Cancellation that lands outside `run_harness` (for example during classification at `:525`) exits 130/143 without a row for a harness run that had already finished — inside the stated "active run" contract, noted for the record.

Pre-existing defects found in the swept files: S1, N1, N2, N3, N5. None of them blocks. B1 is the only item I need dispositioned before approval.

Handing off to Producer (codex-producer) — go to the Producer window and say "take your turn": disposition B1 and S1, apply the B1 fix, and attach the two B1 probe commands re-run green.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
