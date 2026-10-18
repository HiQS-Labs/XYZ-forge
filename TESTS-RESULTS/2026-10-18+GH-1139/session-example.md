# Manual Acceptance Walkthrough & Paper Red Control (GH-1139)

Fictional two-item session scenario evaluating `skills/2-daily/todo-list/SKILL.md` and its
subroutine delegation to `skills/1-hourly/handsfree/SKILL.md`. No real repositories, live
schedulers, or background processes are mutated by this artifact.

## 1. Input Conversation Snapshot

**Assistant (preceding turn):**
> Here is the recommended order to finish the release prep:
> 1. Run the hosted smoke workflow on `ExampleOrg/Widget` (`gh workflow run smoke.yml --ref main`) and verify run `#901` finishes green.
> 2. Update `docs/RELEASE-NOTES.md` with the verified smoke run link and open the release PR.
> *(Note: we already deferred the optional benchmark comparison to next month.)*

**User (current turn):**
> `/todo-list`

---

## 2. Expected `todo-list` Execution Trace

1. **Ordered numbered checklist extraction (`skills/2-daily/todo-list/SKILL.md` §1.1–1.2):**
   - Extracts the 2 actionable items in the recommended order (`1` then `2`), excluding the
     deferred benchmark comparison.
   - Renders at the top of the response:
     - `1. [-] Run hosted smoke workflow on ExampleOrg/Widget and verify run #901 finishes green (acceptance: run #901 conclusion=success)`
     - `2. [ ] Update docs/RELEASE-NOTES.md with verified smoke run link and open release PR (acceptance: PR opened with run #901 link)`
2. **Dual persistence (`skills/2-daily/todo-list/SKILL.md` §1.3):**
   - Updates the session's native todo/task tool (when present) and writes
     `temp/todo-list-2026-10-18-a1b2c3.md` containing:
     - `start: 2026-10-18T08:40:00-07:00`
     - `deadline: 2026-10-18T10:20:00-07:00 (100 minutes / 10 x 10m max)`
     - `wakes: 0 / 10`
     - `scheduler_job: sched-77 (cancel via native scheduler delete/cancel in this conversation)`
     - `active_item: 1 (awaiting workflow run #901 on SHA 1234abcd)`
     - Numbered checklist items `1` (`[-]`) and `2` (`[ ]`).
3. **Watchdog timer delegation (`skills/2-daily/todo-list/SKILL.md` §2 & `skills/1-hourly/handsfree/SKILL.md` §Start.2–3):**
   - Calls `handsfree` with subroutine overrides:
     - **Deadline/cap override:** `10 x 10 minutes` (earlier of `100 minutes` or `10 wakes`).
     - **Shared note override:** `temp/todo-list-2026-10-18-a1b2c3.md` (single note and single job ID `sched-77`).
     - **Checklist wake-action override:** wake prompt checks the `100m / 10-wake` deadline first, inspects `active_item: 1` (`run #901`), marks `[x]` only on verified pass, and starts item `2`.
   - **Unsupported-scheduler branch:** If the current harness has no verified same-conversation scheduler (for example a CLI session without `/loop` or `/schedule` return-to-chat support), `todo-list` leaves the timer unarmed, records `scheduler: unarmed (no same-conversation scheduler in this harness)` in `temp/todo-list-2026-10-18-a1b2c3.md`, informs the user, and still begins item `1` immediately.
4. **Immediate execution (`skills/2-daily/todo-list/SKILL.md` §3.1–3.3):**
   - Starts item `1` immediately in the current turn (dispatches `smoke.yml`, records `run #901` in `temp/todo-list-2026-10-18-a1b2c3.md`, and yields while `run #901` is in progress).
5. **10-minute wake advancement & early cancellation (`skills/2-daily/todo-list/SKILL.md` §3.4):**
   - At `wake 1 / 10` (`+10m`), `run #901` did not wake the session on its own. The scheduled wake inspects `run #901`, observes `conclusion=success`, marks item `1` as `[x]` in the note and chat, and immediately executes item `2` (`docs/RELEASE-NOTES.md` + release PR).
   - Once item `2` is verified `[x]`, the agent cancels `sched-77` in the same conversation (at `wake 1 / 10`, well before the 100-minute / 10-wake cap), verifies readback shows `sched-77` inactive/absent, updates `temp/todo-list-2026-10-18-a1b2c3.md`, and reports all items `[x]`.

---

## 3. Paper Red Controls (Must Fail Acceptance)

1. **Red Control A — Un-overridden 3-hour (`18`-wake) deadline:**
   - *Mutated behavior:* Caller arms `handsfree` with `deadline = start + 180 minutes` (`18 wakes`) instead of `10 x 10 minutes` (`100 minutes` / `10 wakes`).
   - *Expected result:* **FAIL** against `skills/2-daily/todo-list/SKILL.md` §2.1 (*"Set the hard deadline to 100 minutes from start and cap recurring 10-minute wakes at 10 iterations"*).
2. **Red Control B — Missing numbered checklist in state note:**
   - *Mutated behavior:* Caller writes a generic `temp/handsfree-...md` note with no numbered `1..N` checklist or starts waiting for the first 10-minute tick before executing item `1`.
   - *Expected result:* **FAIL** against `skills/2-daily/todo-list/SKILL.md` §1.3 and §3.1.
