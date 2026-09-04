---
title: Cross-agent dependency conflict detection — warn-only Phase 1 via dependency.drift event (GH-68)
date: 2026-07-01
status: Decided
gh_issue: 68
related:
  - relay-automation/relay-turn-lib.sh     # post-commit hook site + pre-turn read path
  - relay-automation/codex-turn.sh         # shim that reads drift events into the turn brief
  - relay-automation/agy-turn.sh           # shim that reads drift events into the turn brief
  - src/project.js                         # shared surface #1 — exported JS API / event verb list
  - .tick/events/                          # event log receiving the new dependency.drift verb
  - decisions/2026-06-18-epoch-fencing.md  # prior kernel schema extension (the discipline to follow)
---

# Cross-agent dependency conflict detection — warn-only Phase 1 (GH-68)

**Decision:** Add a **warn-only, inject-only** `dependency.drift` signal to the harness kernel:
a post-commit hook (in `relay-turn-lib.sh`) diffs three shared surfaces against the prior HEAD after
every relay turn lands; if any surface changed, it appends a `dependency.drift` event to
`.tick/events/`; both worker shims (`codex-turn.sh`, `agy-turn.sh`) read unacknowledged drift events
before seeding each turn prompt and inject a summary into the turn brief. **Phase 1 is warn-only —
no turn is blocked on drift; the blocking gate is an explicit follow-on.**

**The problem it solves:** Two agents working concurrently have no structural signal when Agent A's
landed commit silently changes a surface Agent B is mid-flight on. The Reviewer in the relay loop
can catch this by inspection, but that is best-effort and model-dependent. There is currently no
deterministic, per-turn notification. Specific gaps: no pre-turn signal that an upstream shared
surface changed since the agent last read it; `validate.sh` runs per-turn but only the active agent
runs it — Agent B does not re-validate after Agent A's commit lands between turns; the turn lock
(`relay-driver.lock`) guards the turn boundary, not cross-turn surface drift.

**The risk this accepts (named, not hidden):** a new event verb (`dependency.drift`) extends the
`.tick/events/` projection schema that the epoch-fencing kernel reads. The kernel is the highest-risk
component in the repo — a schema change here can break event ordering, epoch comparisons, or
watchdog logic. This is the same class of change as the 2026-06-18 epoch-fencing decision; the same
discipline applies: the new verb must be purely **additive** (existing verbs and their semantics
are unchanged), the projection kernel must ignore unknown verbs gracefully (already true per
`src/project.js` design), and the new verb must have no effect on epoch ordering.

**The warn-only bet (the load-bearing decision): inject into the brief, do not block.**
- A blocking gate on dep-drift would serialize turns that might actually be safe to proceed (the
  diff touches the shared surface but not the slice the peer agent is building). False positives
  would stall the swarm unnecessarily and erode trust in the gate.
- An injected brief summary gives the builder agent full context to self-assess whether the drift
  is relevant to its current task. A sufficiently scoped builder (per the swarm-preflight brief
  contract) can reason: "Agent A changed `relay-turn-lib.sh` lines 50–80; my task only touches the
  shim's exit path at lines 200–220 — no conflict." A hard block cannot make that call.
- The blocking gate — if justified by a field-observed false-negative (a drift that *was* relevant
  but the builder ignored) — is an explicit follow-on, not a deferred maybe. The warn-only posture
  makes the signal visible in production so the upgrade decision is data-driven.

**Mechanism (the invariants):**

1. **Detection lives in `relay-turn-lib.sh` post-commit step.** Detection is a kernel
   responsibility, not per-shim — both shims inherit it automatically and can't accidentally omit
   it. The post-commit step already runs after every successful relay turn commit; the diff is
   appended there.

2. **Three shared surfaces, no more.** The hook diffs exactly:
   - `relay-automation/relay-turn-lib.sh` — the containment kernel itself
   - `src/project.js` — the exported JS event projection API and verb list
   - The event-verb enumeration (any line containing a recognized verb token in `src/project.js`)
   
   NOT diffed: test files, docs, relay thread files, shim per-file logic, or operator docs. Surface
   changes in those areas do not break a peer agent's active build; including them would generate
   noise that degrades trust in the signal.

3. **`dependency.drift` event schema (additive, Costly to change later):**
   ```json
   {
     "verb":        "dependency.drift",
     "task":        "<relay-task-id or 'post-commit'>",
     "agent":       "<agent-id that landed the change>",
     "surface":     "<file path that changed>",
     "prior_sha":   "<git object sha of prior file>",
     "current_sha": "<git object sha of new file>",
     "diff_lines":  <integer — changed line count, for triage>,
     "turn":        "<relay turn identifier if available, else null>"
   }
   ```
   The verb `dependency.drift` is **purely informational** — it carries no epoch, claims no task,
   and has no effect on any existing projection query. The projection kernel (`src/project.js`)
   must be updated to enumerate and pass through the new verb without error; it must not count it
   as a state-transition event.

4. **Acknowledgment model: watermark-based, not explicit ack.** Each shim records a
   `DEP_DRIFT_WATERMARK` (the event-log index it last processed) in its turn environment. On the
   next turn, it reads events after the watermark, filters for `dependency.drift`, and injects a
   one-line summary per unread event into the turn brief before the builder prompt. No explicit
   `tick ack` verb is required (too much shim friction); the watermark advances after injection.
   If the shim crashes before advancing the watermark, the next turn re-injects the same events
   (idempotent, not harmful — a builder seeing a duplicate drift notice is fine).

5. **Injection is capped and bounded.** If more than 5 unread `dependency.drift` events exist at
   turn start, inject only the 5 most recent and append: "+(N-5) earlier drift events omitted —
   check `.tick/events/` for full history." This prevents a burst of concurrent changes from
   bloating the turn brief past the turn prompt's effective context.

6. **Default path (no drift) is byte-identical.** When no shared surface changes between turns,
   no event is emitted and no injection occurs. The shim's existing turn-prompt construction is
   untouched. The new code path is only entered when the watermark check finds at least one
   unread `dependency.drift` event.

**Rejected alternatives:**

- **Block the turn when drift is detected.** Strongest safety posture but too many false positives
  in practice (two agents can change the same file in disjoint line ranges without conflict).
  Deferred as Phase 2 if field data shows the warn-only posture misses real conflicts.
- **Full symbol-level dependency graph.** Accurately identifies which *functions* a peer agent
  depends on. Too heavy for Phase 1: requires static analysis of JS and Bash across both shims and
  the relay thread; adds a mandatory analysis step on every commit. Surface-level diff is sufficient
  to surface most real conflicts without the analysis overhead.
- **Validate.sh re-run after every peer commit.** Would catch breakage but requires the peer's
  shim to monitor the repo continuously between turns — beyond the current pull model where each
  shim is stateless until its turn starts. Not ruled out, but orthogonal to this signal mechanism.
- **Reviewer-only mitigation (status quo).** Already exists; this is the structural complement, not
  a replacement. The Reviewer continues to catch semantic conflicts; `dependency.drift` catches
  surface-level churn the Reviewer might miss in a long diff.

**Backward compatibility:** Existing turns that do not change any of the three surfaces emit no
new event and experience no change in behavior. Shims that have not yet been updated to read the
watermark simply skip the injection step (the events accumulate in `.tick/events/` harmlessly).
The `dependency.drift` verb is unknown to the current projection kernel and will be passed through
without error (verified by the existing unknown-verb tolerance in `src/project.js`).

**Reversibility:** **Costly** (matching the intake doc rating). The schema addition (`dependency.drift`
verb) is straightforward to remove — delete the emission in `relay-turn-lib.sh`, the read path in
both shims, and the verb from `src/project.js`'s enumeration. Any accumulated events in
`.tick/events/` become inert unknown verbs. No operator data is lost. The watermark in the turn
environment vanishes on the next fresh shim invocation. Total revert: ~4 file changes, no
migration needed.

**Revisit trigger:** If a real conflict is missed by a builder that received the drift injection
but proceeded anyway (i.e., the warn-only posture produces a false negative that reaches `main`),
escalate Phase 1 → Phase 2: add a blocking gate with an operator override flag. Not warranted
until that evidence exists; the bet is that a scoped builder with a drift notice will self-triage
correctly.

**Pre-condition before any code lands:** This record must exist and be committed to `decisions/`
before any change to `relay-turn-lib.sh`, `src/project.js`, or either shim is written. The kernel
schema change is Costly; the record is the contract that makes it reviewable.
