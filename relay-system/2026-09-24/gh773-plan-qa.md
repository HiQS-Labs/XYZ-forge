# RELAY · GH-773 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-23.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-773-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-773-MARATHON-DRIVE-GATE-MEMORY.md` (the plan). Read it in full, plus the code it cites: `utils/py/marathon_drive.py` (`_gate_group_rss_mb` ~L899-916, `run_pre_advance_gate` guarded loop ~L2340-2410, `write_terminal_result` ~L237-272) and `test/gh390-gate-guard.sh`. Issue with agreed design: https://github.com/HiQS-Labs/XYZ-forge/issues/773 (body + plan comment).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-23
- Definition of Done: the plan is ready to implement — grounded in the actual code, covers every acceptance line in the issue body, extends the existing guard in place (no new module/writer/schema), and its test plan detects the real failure with a red control.
- Operational envelope: a local developer CLI (marathon driver, single host, macOS + Linux CI). Tests and machinery must be commensurate with a one-helper, one-loop, one-test fix. Do not demand fail-closed modes, fallback probes, schema changes, or enterprise safeguards — those were explicitly rejected (AgentChorus #507818) and are listed as non-goals.
- Questions:
  1. Are the plan's recon claims correct against the code (line refs, the `-1`/`max(0,-1)` path, `ps` return code ignored, the loop polling `proc.poll()` before sampling)?
  2. Does the `(mb, status)` helper plus `group-missing` re-poll correctly separate a clean exit race from a real `ps` failure? Any case the plan misclassifies?
  3. Is the added "no samples at all → unknown (gate exited before first sample)" case correct and in scope, or does it break an existing assertion?
  4. Will a `ps` stub prepended to `PATH` reach the driver's `subprocess.run(["ps", ...])` in the driven test given how `run_driver` invokes `relay-automation/marathon-drive.sh`? Is any other code path in the driver calling `ps` that the stub would disturb?
  5. Is the red control sufficient to make the new assertions falsifiable?
  6. Is the rating 55/60/50/80 grounded per the rationale (appeal neutral, effort = cheapness)?
  7. Anything missing, wrongly scoped, or over-engineered? Cite file:line.
- Write findings only in this file (ALLOW_PATHS is empty). Set `STATUS: Approved` if the plan is ready as written.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: PASS

Basis: The plan is grounded in the current helper/loop/result contract, stays within the agreed one-helper/one-loop/one-test envelope, and its failing-`ps` case plus working-`ps` control make both the defect and false-positive direction observable. No pre-existing defect was found in the full plan.

- [Pass] Recon is accurate: `_gate_group_rss_mb()` discards `returncode`, returns `-1` only on the caught exceptions, and the loop polls before sampling then folds `-1` through `max(0, -1)` (`utils/py/marathon_drive.py:899-916`, `:2354-2367`). The terminal receipt remains an explicit allowlist with only gate result/exit/path, so this is log-only (`utils/py/marathon_drive.py:235-272`).
- [Pass] `(mb, status)` and the `group-missing` re-poll separate the clean-exit race correctly: rows-without-the-pgid are not called a probe failure until `proc.poll()` confirms the child is still alive; `ps-failed` remains unreadable regardless (`PROJECT/2-WORKING/GH-773-MARATHON-DRIVE-GATE-MEMORY.md:70-78`). A child that exits just after an alive re-poll can produce one conservative warning, but it was genuinely unmeasurable at that sample and does not change the gate result.
- [Pass] The no-sample summary is in scope and does not break the existing honest-gate assertion: the current loop can exit at its pre-sample poll (`utils/py/marathon_drive.py:2356-2361`), committed evidence records the resulting misleading `0MB` (`evidence/marathons/run-1/04-fullrun.log:987`), and the existing test only requires the substring `peak group RSS` (`test/gh390-gate-guard.sh:165-175`).
- [Pass] A prepended `ps` stub reaches the authoritative Python helper. `run_driver` invokes the shim without replacing `PATH` (`test/gh390-gate-guard.sh:89-100`), the shim execs Python (`relay-automation/marathon-drive.sh:9-18`), and `_gate_env()` does not scrub `PATH` (`utils/py/marathon_drive.py:2279-2283`). Probe: `rg -n 'subprocess\\.(run|Popen).*ps|\\["ps"|\\bps -' utils/py/marathon_drive.py relay-automation/marathon-drive.sh` (exit 0) produced only `utils/py/marathon_drive.py:902`, so no second driver `ps` path is shadowed.
- [Pass] The test plan is falsifiable: under the current implementation the exit-1 stub yields neither the one-shot warning nor an unknown summary, so the new driven assertions go red; the same `sleep 3` case with working `ps` rejects an over-broad implementation by requiring numeric telemetry and no warning (`PROJECT/2-WORKING/GH-773-MARATHON-DRIVE-GATE-MEMORY.md:84-88`). Execution is intentionally deferred to the required disposable full clone.
- [Pass] The 55/60/50/80 rating is internally grounded: priority follows the host-safety severity without a deadline, appeal is neutral, and effort 80 is cheapness for one helper/loop/test-file change (`PROJECT/2-WORKING/GH-773-MARATHON-DRIVE-GATE-MEMORY.md:42-48`).
- [Pass] Scope is minimal and DRY: it extends the existing guard and existing GH-390 test, with receipt/schema, fallback probes, fail-closed behavior, and the frozen Bash twin explicitly excluded (`PROJECT/2-WORKING/GH-773-MARATHON-DRIVE-GATE-MEMORY.md:66-105`).
- [Unverified — external source unavailable] The linked issue body/comment could not be independently re-fetched in this sandbox: `gh api repos/HiQS-Labs/XYZ-forge/issues/773` exited nonzero with `error connecting to api.github.com`; the embedded Definition of Done and locally recorded design were fully checked.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
