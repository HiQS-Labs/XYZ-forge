### ANSWER
The proposed policy for bounded unattended marathon progress and safe minor repairs is viable but demands strict isolation for the repair loop. A runtime recovery controller is unjustified; the existing `jog_run.py` supervisor and `start-task` machinery should be leveraged instead. PR-based continuation requires a new primitive to swap the active harness to a vendored PR clone without losing queue identity. A three-agent consult is a useful heuristic gate but must be unanimous and subordinate to deterministic constraints.

### FINDINGS
*   **[Blocker]** Hot-patching the active harness violates containment. Repairs MUST run in a separate full clone, and continuation MUST use an isolated vendored harness pinned to the immutable repair SHA.
*   **[Blocker]** Open PR #1004 fixes must not be duplicated. Any continuation mechanism must handle unmerged dependencies via explicit launch-time permission, as proposed. Consumer recovery must ignore #1004 unless explicitly included.
*   **[Should]** Require unanimity for the three-agent consult. Any dissenting or abstaining model indicates ambiguity, which is unsafe for automated harness mutations.
*   **[Should]** Resolve the timeline conflict by pausing observation during repair, and decoupling "halt reporting" (which becomes "escalated to repair") from "terminal marathon failure".

### RECOMMENDATION
Implement the bounded recovery as a `jog_run.py` supervisor extension that monitors execution asynchronously, delegates repairs to `start-task` in a disposable clone gated by a unanimous `consult.py` vote, and resumes via a pinned vendored harness.

---

### RECONCILED DESIGN INPUT

#### 1. Monitoring vs. Runtime Recovery Controller
*   **[Agree]** A runtime recovery controller is unjustified. (See `GUIDING-PRINCIPLES.md:18-22`: "Do not build a new layer... when an existing piece of code can be extended").
*   **[Agree]** Use a skill-driven bounded recovery procedure instead of a bespoke controller.
*   **[Optional]** Monitoring location: Integrate the 600s x6 observation loop directly into `utils/py/jog_run.py` during `marathon-drive` dispatch. By replacing the blocking `subprocess.run(argv...)` at `jog_run.py:594` with `subprocess.Popen` and a polling loop, `jog` can monitor progress (via `.tick/events/` and driver receipts) without introducing a second executor, preserving chain-wide timing and the single outer driver lock (`jog_run.py:721`).

#### 2. PR-Based Continuation within Current Contracts
*   **[Agree]** PR-based continuation can be supported safely *only if* the repaired harness is pinned and strictly isolated, satisfying "no hot-patching active installed harness."
*   **[Blocking]** Missing primitive: We lack a mechanism to resume a `jog` queue item using an *alternative harness path* (the PR's SHA) while maintaining the original execution ledger (`.tick/jog/<gid>/`). `jog_run.py:218` (`_ledger_abs_path`) and `jog_resume` (`jog_run.py:651`) assume the current `MARATHON_HOME`/`MARATHON_ROOT`.
*   **Already Supported:** PR creation (`marathon_drive.py`), receipt parsing (`jog_run.py:128`), and retry dispatch (`jog_run.py:707`).
*   **Desired Addition:** A primitive (e.g., a `--harness-override <path>` flag or a schema update to `JOG_EXECUTION_STATE_SCHEMA`) for `jog resume` or `jog retry-build` to execute the next phase using a vendored instance of the PR clone.

#### 3. Three-Agent Vote Utility
*   **[Agree]** A three-agent vote (`utils/py/consult.py`) is useful as an adversarial safety net, but **cannot** override deterministic constraints (e.g., `validate.sh` or containment rules in `marathon_drive.py`). Models hallucinate safety; deterministic constraints veto regardless of vote.
*   **[Blocking]** Unanimity is REQUIRED. If any model disagrees or abstains (e.g., fails auth or returns empty, `consult.py:195`), the repair must be parked. Modifying the harness itself is highly sensitive; a simple majority is insufficient to prove safety. 

#### 4. Eligibility, Budgets, and Meaningful Progress
*   **Eligibility:** Minor corrections only.
    *   *Stop cases:* Code touches locks, containment, gates, auth, schemas, or network bridges. Genuine review caps are escalation outcomes, not machinery defects.
*   **Meaningful Progress:**
    *   *Product:* Accepted deliverable + relevant verification.
    *   *Preparation:* Reviewed repair PR against `development` or reproducible blocker handoff, separately reported.
*   **[Should]** Requirement Conflicts:
    *   *Observation vs. Recovery:* A 1-hour observation (600s x6) conflicts with a several-hour recovery. The observation timer MUST pause while the recovery procedure is active.
    *   *Immediate Halt vs. Explicit Recovery:* An immediate terminal report invalidates the repair intent. A marathon halt should trigger an interim "Escalated to Repair" state rather than a terminal cancellation, explicitly extending the deadline for the repair budget.

#### 5. Surgical Implementation Boundary & Risks
*   **Execution Path:**
    1.  `marathon_drive` exits with a halt code (e.g., `3` no-progress, `4` cap).
    2.  `jog_run.py` observes the halt and evaluates the opt-in recovery budget.
    3.  `jog` spawns `consult.py` with the error context for a unanimous vote.
    4.  If approved, `jog` spawns `start-task` in a NEW disposable clone (target: `development`).
    5.  `start-task` applies the fix, creates a PR, and runs `validate.sh`.
    6.  If the PR succeeds, `jog` clones the PR SHA into an isolated directory, vendors it, and invokes `jog resume` using the new vendored harness.
*   **[Blocking]** Checks: `validate.sh` and `pdda.sh run` MUST pass cleanly on the isolated repair clone before a PR is opened.
*   **[Blocking]** Risks: Overlap with unmerged dependencies (PR #1004). Consumer recovery must explicitly accept the base state of `development` and ignore #1004.
*   **[Blocking]** Rollback: If the repair fails, times out, or is vetoed, delete the disposable clone and park the queue row with the original marathon halt receipt (`jog_run.py:387`).
