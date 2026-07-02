### 1. Direct Answer
The A/B framing is correct in identifying the core architectural choice between task-token single-use finality (Option A) and task-token reuse (Option B). **Option A is the correct design.** Option B is a premature optimization that violates Principle #7 (Least code) and creates log drift (violating Principle #2). Once a task is completed, its token must be permanently sealed; any rework should require a new task ID to preserve event log integrity.

---

### 2. Graded Findings
*   **[Blocker] Silent Task Resurrection:** The logic in [src/project.js:109-110](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/src/project.js#L109-L110) and [src/project.js:123](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/src/project.js#L123) allows a higher-epoch `task.claimed` event to silently overwrite `task.done` without generating a rejection trace (resulting in `claimed 0` as confirmed by [test/fixtures/canary-token-reuse/verify-fixture.sh:39-44](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/fixtures/canary-token-reuse/verify-fixture.sh#L39-L44)). This violates the guarantee of terminal state finality.
*   **[Should] Implement Option A (Terminality-Seal Only):** The projection kernel [src/project.js:50](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/src/project.js#L50) should be modified to reject any claim that occurs after an authorized terminal event, recording a new rejection reason `claim-after-terminal`.
*   **[Nit] Refactor `foldWithMeta` to a Single Chronological Pass:** The current implementation filters and sorts claims, releases, and terminals separately before reconciling them. Tracking the active owner and terminal state in a single chronological loop over the sorted event stream would prevent "retroactive invalidation" bugs and simplify the code.

---

### 3. One-Line Recommendation
Implement Option A directly in `src/project.js` to seal task tokens post-terminality without adding complex schema verbs.

---

### 4. Concrete Answers

#### 1. Framing
The A-vs-B framing is correct, but Option A is the foundational prerequisite. Even if Option B (`task.reopened`) were desired, the kernel must first know how to enforce terminality and reject unauthorized claims.
Furthermore, task tokens should be strictly single-use. Under **Principle #2 (One canonical event log)** ([GUIDING-PRINCIPLES.md:24-25](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/GUIDING-PRINCIPLES.md#L24-L25)), reusing a task ID merges separate lifecycles into a single event sequence, corrupting historical metrics and audit trails. Rework should always use a fresh task ID (e.g. `GH-41-2`), validating Option A as the correct architectural model.

#### 2. Recommendation & Guiding Principles
We recommend **Option A** decided by:
*   **Principle #7: Least code that clears the bar** ([GUIDING-PRINCIPLES.md:32-34](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/GUIDING-PRINCIPLES.md#L32-L34)): Option A requires zero changes to the schema dictionary [src/events.js:11-37](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/src/events.js#L11-L37) and no downstream updates to client shims. Option B adds a net-new verb and introduces complex validation rules.
*   **Principle #6: Build durable, not band-aid** ([GUIDING-PRINCIPLES.md:30-31](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/GUIDING-PRINCIPLES.md#L30-L31)): Option A establishes a durable invariant (terminal is terminal), eliminating the possibility of silent resurrection bugs entirely.

#### 3. If Option B is Selected: Three Sub-Decisions
*   **(a) Reopen Authorization Model:** Only the last authorized owner of the terminal state (at the terminal epoch) or an administrative agent (e.g., `marathon` or `operator`) may emit `task.reopened`. It must carry the terminal epoch to validate ownership.
*   **(b) Rejection-Reason Taxonomy:** `claim-after-terminal` must be a new, distinct rejection reason in `rejected.jsonl`. Folding it into `stale-epoch` or `non-owner-agent` masks a critical security anomaly as a routine race condition.
*   **(c) Replay-Determinism Ordering Rule:** Events are processed in filename-sorted order. If `task.reopened` occurs before `task.done` in the sorted list (due to clock skew or reordered sync), the fold applies it. If the task is not yet terminal when `reopened` is processed, the reopen is rejected (e.g., `reopen-active-task`). This guarantees the final state remains a pure function of the event set.

#### 4. Technical Spike
A prototype spike is highly feasible using [test/fixtures/canary-token-reuse/verify-fixture.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/fixtures/canary-token-reuse/verify-fixture.sh).
*   **What to Measure:**
    1.  **Canary Resolution:** The mutated stream projects to `done` and registers `rejections.length === 1` with reason `claim-after-terminal`.
    2.  **Regression Check:** Run `bash validate.sh` to confirm no existing epoch-fence tests regress.
    3.  **Order-Independence:** Shuffle event timestamps to ensure the projection outputs remain deterministic.
*   **Risks:** CLI-level commands like `nextEpoch` or client validation logic may fail or get stuck when interacting with a terminal task; these boundaries must handle the rejection gracefully.
