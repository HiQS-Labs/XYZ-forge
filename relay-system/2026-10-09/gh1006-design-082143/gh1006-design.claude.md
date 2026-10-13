**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (claude's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

---

## ANSWER

The proposed policy is substantially sound. The monitoring placement is the sharpest design risk. The "minor repair" procedure is justified in principle but has one blocking gap: there is no existing primitive to stop, checkpoint, and resume a live `marathon.sh` child phase, which the PR-continuation path requires. The three-agent consult vote is useful for diagnosis only; it cannot override deterministic safety predicates. Implement the observation window first; leave recovery as a separate, explicitly opt-in second step.

---

## FINDINGS

### Q1 — Monitoring placement and executor separation

**[Blocker]** `marathon.sh` blocks on each child with no interleaved reads (`marathon.sh:55-65` — `set -euo pipefail`, sequential phase calls with no background jobs). A polling loop inside `marathon.sh` would require backgrounding the current child, which changes `marathon.sh`'s exit semantics and can corrupt the ordered chain. The safe placement is a **separate observer process** (not a second executor) launched before the `marathon.sh` invocation from the operator shell — reading `.tick/driver-heartbeat.json` (`marathon_drive.py:1473-1476`), `RELAY.md` STATUS lines (`marathon_drive.py:206-216`), and `.tick/events/` at 600 s intervals. This is read-only; it never writes, never sends signals, and never competes for the driver lock (`marathon_drive.py:1269`, `RELAY_DRIVER_LOCKED`). Six probes at 600 s = 60-minute window; observation terminates after the sixth probe regardless, which maps cleanly to the operator's away window.

**[Pass]** The heartbeat record (`marathon_drive.py:1480-1509`) already carries `pid`, `phase_id`, `relay_task`, `updated_utc` — sufficient for identity snapshot and heartbeat-age check without any new writes. `relay_attest` import at `marathon_drive.py:22` and the relay STATUS parse at lines 206-216 cover phase/role observation. No new writeable state is needed for read-only observation.

**[Should]** The observer should emit a structured terminal report (JSON or markdown) to a file in `marathon-system/<phase-id>/OBSERVATION-<timestamp>.md` — not to stdout — so the operator can read it on return without it mixing with marathon output. This file must be outside the lane's write-set to avoid triggering containment.

---

### Q2 — PR-based continuation

**[Blocker]** No existing primitive can stop a live marathon phase and resume it from a different commit. `marathon.sh` has `--retry PHASE-ID` (`marathon.sh:111-118`) but it rebuilds the phase from scratch (new relay-task suffix, full builder+reviewer cycle). There is no `--resume-from-sha` or pinned-harness invocation. PR-continuation requires: (a) stopping the running child cleanly, (b) landing the repair PR (not merging automatically — the policy is correct to prohibit auto-merge), (c) re-invoking marathon against the repair SHA with old attempt identity preserved. None of (a)-(c) is implemented. The `--result-file` receipt (`marathon_drive.py:280-102`) records identity but does not support "resume from receipt."

**[Pass]** Already supported: `--force` bypasses the attempt cap for explicit re-runs; `--retry` issues a fresh relay task; `XYZ_ARCHIVE_ROOT` preserves old transcript roots. These primitives can be composed manually by the operator — which is the right answer for a first version rather than a new controller.

**[Should]** The missing primitive is a documented operator procedure, not new code: (1) kill marathon.sh (`SIGTERM` to the PID recorded in the heartbeat), (2) run repair in a separate full clone, (3) publish PR, (4) re-launch marathon with `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` plus the verified repair SHA pinned via `MARATHON_HOME` override. Document this procedure in a new `MARATHON-RECOVERY.md` under `relay-automation/`. Do not implement a recovery controller.

---

### Q3 — Three-agent vote

**[Should]** A three-seat consult (codex, agy, claude — `consult.py:41` imports the three resolver paths) is useful for **diagnosing** whether a failure is a harness defect vs. a task defect vs. external state. Evidence requirement: each advisor reads the ESCALATION.md, the run log, and the last relay STATUS — no additional probes. Disagreement treatment: any advisor may emit a `[Blocking]` finding that vetoes the repair attempt; abstention (no response within `CONSULT_IDLE_DEFAULT_S` = 90 s per `consult.py:51`) counts as a non-vote, not a veto, but is recorded. **Unanimity is required** for a repair attempt to proceed — not majority — because the downside of a false-positive repair (consumed attempt, extended wall time, a PR that doesn't fix the root cause) is worse than a false-negative (park and escalate). A single dissent or abstain should park and hand off.

**[Pass]** Safety predicates (attempt cap, containment, lock) veto the repair regardless of vote outcome because they are enforced by the harness machinery unconditionally. The vote only informs the operator's decision to trigger a repair; it does not modify any exit code or bypass any guard.

---

### Q4 — Repair eligibility, budgets, progress definition, conflicts

**[Agree]** Meaningful progress = accepted deliverable (relay STATUS: Approved on at least one phase) + relevant verification receipt (gate passed, `.xyz/receipts/<sha>.json` exists). Heartbeat updates, log lines, and token spending alone do not count. Preparation progress = a reviewed PR with passing CI, separately listed. These are the right definitions.

**[Agree]** Repair eligibility predicates (each must hold; any failure parks):
1. Exit code 3 (no-progress) or 4 (round-cap), NOT 6 (containment) — containment violations are not minor harness defects.
2. ESCALATION.md names a specific reproducible harness path (not a task misunderstanding).
3. Observation window has not expired (repair must start before the 6th probe).
4. Attempt count < attempt_max (no cap bypass by repair).
5. No open PR #1004 dependency unresolved (the policy states dependency must be explicit launch-time opt-in — `MARATHON_RESUME_UNMERGED_DEP=1`).

**[Blocker — conflict]** The 60-minute observation window and a multi-hour repair are incompatible as a single budget. A repair involving a full clone, build, QA, and PR review cannot complete in the residual observation window. **Resolution**: the repair budget is separate from the observation window and is set at launch time (e.g. `--repair-deadline=+4h`). Observation is always bounded to x6 × 600 s. Recovery proceeds independently, possibly outlasting the observation window.

**[Blocker — conflict]** "Immediate terminal report" on escalation vs. "explicit recovery" — the driver halts on exit 3/4 and writes ESCALATION.md. If recovery is desired, the operator must re-invoke marathon; the halted child is already gone. There is no "immediate halt then seamlessly continue" primitive. Recovery is always a re-invocation, not a continuation. The policy must say this plainly.

---

### Q5 — Implementation boundary

**[Agree — ordered steps]**

1. **Observation script** (new `relay-automation/marathon-observe.sh`): reads heartbeat + RELAY.md + `.tick/events/` at 600 s × 6 intervals; writes `OBSERVATION-<ts>.md`; no driver interaction. File:line anchor: heartbeat reader pattern from `marathon_drive.py:1473-1476`.

2. **Repair eligibility check** (new `relay-automation/marathon-repair-eligible.sh`): given ESCALATION.md + result receipt JSON, emits yes/no with reason. References `marathon_drive.py:37-48` exit code table.

3. **Consult hook**: invoke existing `utils/py/consult.py` with codex/agy/claude seats on the ESCALATION.md. No new consult machinery.

4. **Operator procedure doc** (`relay-automation/MARATHON-RECOVERY.md`): documents the stop → repair-clone → PR → re-launch sequence with exact flag combinations.

5. **`marathon.sh` launch-time flags**: `--repair-deadline=+Nh`, `--resume-unmerged-dep=SHA` (opt-in resume against an unmerged repair). These are additive args, not behavioral changes.

**Falsifiable checks (existing only):**
- `test/gh284-runlog-heartbeat.sh` — validates heartbeat write/clear; an observer reading a stale heartbeat will catch a dead driver.
- Manual: re-run marathon with `--dry-run`; confirm observation script exits after 6th probe with no side-effects on driver.
- Manual receipt inspection: `marathon-drive/result@1` JSON outcome field must match expected escalation type before repair-eligible check fires.

**Risks:**
- Observer process leak if operator kills the terminal; mitigate with `trap cleanup EXIT` in the observe script.
- PR #1004 not merged: any recovery path that touches `harness_paths.py` or `relay-turn-lib.sh` will carry PR #1004's defects. The `--resume-unmerged-dep` flag must gate this explicitly.

**Unsupported guarantees:**
- Completion of the marathon is explicitly not guaranteed (stated in the issue; correct).
- The observer cannot determine whether a build turn is making genuine progress vs. cycling on the same error — only ESCALATION.md can, after the fact.

**Unresolved decision:**
- Who triggers the consult? Manual operator action or the repair-eligible script automatically? The policy says "operator decides"; the implementation must not auto-trigger the repair consult — it should emit a prompt the operator can act on.

---

## RECOMMENDATION

Implement the observation script and repair-eligible check first (Steps 1-2), gated by the operator procedure doc (Step 4), before any `marathon.sh` flag additions — the flags are worthless without the documented procedure and the eligibility check to back them.
