# RELAY · GH-1196 plan QA: task-sync pins active Claude Desktop sessions
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 4 / 4

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
6. **Commit only the relay file** (`relay(gh1196-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md` (the PLAN; no code yet). Requirements are its Scope table, from https://github.com/HiQS-Labs/XYZ-forge/issues/1196.
- Source it extends (read in full): skills/3-weekly/task-sync/scripts/adapters/claude.py (ClaudeDesktopAdapter, lines 360–439), skills/3-weekly/task-sync/scripts/task_sync.py, skills/3-weekly/task-sync/scripts/core.py, skills/3-weekly/task-sync/SKILL.md ("Claude Desktop (GH-1191)" section), skills/3-weekly/task-sync/scripts/adapters/zcode.py (pin pattern, lines 194–266). Prior work and evidence: PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md, TESTS-RESULTS/2026-10-24+GH-1191/.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: a local single-operator read-only planner; the Desktop app's `set_pinned` is the only writer, driven by an agent following SKILL.md. Grade against the Scope table and commensurate complexity. No new `test/` suites or gate machinery (AGENTS.md, GH-831); manual probes + a live smoke under TESTS-RESULTS/.
- Native tool facts: `list_sessions` rows carry `pinned` (omitted when the app never recorded a pin, which means not pinned). `set_pinned(session_id, pinned)`; changing another session asks the operator first in default permission mode (declined when unattended).
- Definition of Done:
  1. R1–R3 each map to a plan step with a falsifiable check.
  2. It extends the existing loop and report shape; no second planner, CLI change or writer.
  3. The ordering change (running rows now have activity validated) and the never-unpin rule are sound and stated.
  4. Rating `rated 55/20/50/85` is grounded.

Questions:
1. Is the restructured loop in plan step 1 correct: does it keep every existing title behaviour (the #1191 probes) while adding pins? What breaks if a running row has missing activity?
2. Is treating a missing `pinned` key as unpinned correct given the tool fact above?
3. Is the native pin procedure in step 2 complete (recheck, decline = skip, receipt, guarded undo)?
4. Are the probes in step 3 and the red control enough, and not too many?
5. Anything over-engineered, under-specified or out of scope? Cite file:line.

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

- [Should] Define and prove the deliberate changed handling for a running row with malformed activity. Current code skips every `isRunning != false` row before reading `lastActivityAt` ([`adapters/claude.py:417-423`](skills/3-weekly/task-sync/scripts/adapters/claude.py#L417-L423)); proposed step 1 instead validates activity before the title-only running skip ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:62-66`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L62-L66)). For `{"sessionId":"local_run","title":"B","isArchived":false,"isRunning":true}` with `lastActivityAt` absent, the existing behavior is one skipped row and no error, while the stated restructure will abort the whole plan. Either retain the old skip for malformed running rows (then that row cannot be pinned), or explicitly make the abort intentional, narrow R3's unchanged-title claim, and add this exact probe with its expected outcome.
  Observed input: `{"sessionId":"local_run","title":"B","isArchived":false,"isRunning":true}` with no `lastActivityAt`.
  Affected scope: all running Desktop rows that are now activity-validated solely to be eligible for pin proposals.
  Falsifier: an existing-equivalent fixture with this row returns `skipped: 1`, no adapter error, and no rename/pin proposal under the chosen contract.
- [Should] Make R2's “still unpinned” recheck operationally complete: name the fresh tool read and exact `pinned` predicate before `set_pinned`. The supplied native fact guarantees `pinned` on `list_sessions` rows ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:58`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L58)), but step 2 only says “Recheck … still unpinned” ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:70-75`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L70-L75)); unlike the title procedure, it does not say how. Require a fresh `list_sessions` lookup (or document that `get_session` returns `pinned`) and treat absent/`false` as unpinned and `true` as skip. This makes a concurrent operator pin a no-op rather than a redundant native write.
  Observed input: the snapshot proposes `{"sessionId":"local_a"}` (missing `pinned`), then the recheck row is `{"sessionId":"local_a","pinned":true}`.
  Affected scope: every proposal whose pin state can change after the planning snapshot and before the native write.
  Falsifier: a recheck row with `pinned` missing or `false` proceeds to one `set_pinned("local_a", true)`; `pinned:true` produces no call and a recorded skip.
- [Pass] Missing `pinned` is correctly treated as unpinned by the proposed `row["pinned"] is not True` predicate; it accepts both a missing key and `false`, while excluding only literal `true` ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:65`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L65)). The probe wording at line 78 should state both expected proposal IDs/counts to avoid ambiguity, but that is a Nit once the R2 recheck is specified.
- [Pass] The plan keeps one planner/report surface: `pin` and `pin_hours` already flow through `_sweep_kwargs` ([`task_sync.py:52-61`](skills/3-weekly/task-sync/scripts/task_sync.py#L52-L61)) and `new_ide_report` already supplies `pinned` ([`core.py:76-85`](skills/3-weekly/task-sync/scripts/core.py#L76-L85)); no CLI, second adapter, or writer is proposed.

VERDICT: FAIL

Basis: R1/R2 are close and the never-unpin boundary is appropriately stated, but the plan needs an explicit decision and falsifiable probe for the new running-row validation behavior, plus a concrete current-pin recheck source before native mutation. No pre-existing defect was found in the swept adapter, CLI, core, skill procedure, or ZCode pin pattern beyond these plan omissions.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · Round 1

- Finding 1 (running row with malformed activity would now abort): **Implemented, keeping today's behaviour.**
  - A running row with missing, unparseable or future activity is skipped: no pin, no error.
  - Idle title candidates still abort on bad activity, as today.
  - Plan step 1 is updated, and step 3 adds your exact probe: running row without `lastActivityAt` → `skipped: 1`, no error, no pin or rename.
  - R3 ("title behaviour unchanged") therefore stands without narrowing.
- Finding 2 (recheck source for "still unpinned"): **Implemented.** Plan step 2 now rechecks with a fresh `list_sessions` call, because `get_session` doesn't return `pinned`.
  - The row must still exist, not be archived, not be self, be within `--pin-hours`, and have `pinned` missing or `false`.
  - `pinned: true` is a skip with no native call.
- Nit (probe wording): **Implemented.** Step 3 states the expected 2-of-3 IDs.

Round 2: please re-review plan steps 1–3.

### Reviewer · Round 2

swept file: yes

- [Should] Preserve the existing fail-closed handling of a missing `isRunning` flag. The current adapter skips any row whose value is not literal `false` ([`adapters/claude.py:417-420`](skills/3-weekly/task-sync/scripts/adapters/claude.py#L417-L420)). Step 1 now only says to skip archived/self before proposing a pin, then skips “running” rows for titles ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:62-66`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L62-L66)); it does not state the missing-flag case. Unless the implementation independently retains the old literal-`false` predicate, `{"sessionId":"local_flag","title":"B","isArchived":false,"lastActivityAt":"2026-10-24T12:00:00Z"}` can become a pin and/or rename candidate although it is currently one skipped row. Specify that a missing/non-boolean `isRunning` is skipped for both operations, and add that exact probe, so R3 remains falsifiable.
  Observed input: `{"sessionId":"local_flag","title":"B","isArchived":false,"lastActivityAt":"2026-10-24T12:00:00Z"}` with `isRunning` absent.
  Affected scope: every Desktop row whose running-state field is absent or not literal `false`.
  Falsifier: a probe with that row reports `skipped: 1`, no error, no pin and no rename; a row identical except for `isRunning:false` remains eligible according to its activity/pin state.
- [Should] Make the “guarded undo” compatible with the never-unpin promise. A re-read that merely finds `pinned:true` cannot establish that it is still the pin from this receipt: after task-sync pins `local_manual`, the operator can unpin and manually re-pin it, and the proposed undo would still call `set_pinned(local_manual, false)` ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:73-75`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L73-L75)). The available native state is only the boolean `pinned` ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:58`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L58)), so it supplies no ownership/version predicate. Remove automatic boolean-only undo (the receipt can still record the pin for operator-directed recovery), or identify a native provenance/revision predicate and require it before unpinning.
  Observed input: receipt `{"session_id":"local_manual","op":"pin"}`; task-sync successfully sets `pinned:true`; the operator then changes it `true → false → true` before undo.
  Affected scope: every pin receipt that may be undone after any intervening manual pin-state change.
  Falsifier: a native recheck exposes a stable pin provenance/revision that matches the recorded tool mutation; an undo with a nonmatching provenance/revision performs no `set_pinned(..., false)`.
- [Pass] Round 1’s running-row activity regression is now explicitly kept: malformed activity on a running row skips without error or proposal, while bad activity on an idle row still aborts ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:63`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L63)); the planned probe names the prior missing-activity input and expected result ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:82`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L82)).
- [Pass] Round 1’s pre-write-pin race is now specified as a fresh `list_sessions` read with a literal predicate: missing/`false` proceeds and `true` is a recorded no-call skip ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:70-72`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L70-L72)).

VERDICT: FAIL

Basis: The prior activity-order and recheck findings are resolved, and the plan still extends the existing adapter/report surface without a second planner. However, it must retain the pre-existing fail-closed missing-running-flag behavior and make undo incapable of removing a later manual pin before R1–R3 and the never-unpin boundary can be approved. No other pre-existing defect was found in the swept adapter, CLI, core, SKILL procedure, or ZCode pin pattern.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · Round 2

- Finding 1 (missing `isRunning` must stay fail-closed): **Implemented.** Plan step 1 now skips any row whose `isRunning` is missing or not a literal boolean, for both pins and titles. Step 3 adds your exact probe: that row → `skipped: 1`, no error, no pin, no rename; the same row with `isRunning: false` is eligible.
- Finding 2 (boolean-only undo could remove a later manual pin): **Implemented (the reviewer's first option).** Automatic undo is removed: `pinned` carries no ownership, so task-sync never calls `set_pinned(..., false)`. The receipt line stays for operator-directed recovery. R2 and plan steps 2 and 4 are updated.

Round 3 (last): please re-review plan steps 1–4 and the R2 row.

### Reviewer · Round 3

swept file: yes

- [Should] Retain the existing fail-closed `isArchived` predicate explicitly. The implementation currently skips any row whose archived flag is not literal `false` ([`adapters/claude.py:417-420`](skills/3-weekly/task-sync/scripts/adapters/claude.py#L417-L420)), but plan step 1 only names archived rows, self rows, and malformed `isRunning` ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:62-66`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L62-L66)). For `{\"sessionId\":\"local_arch_flag\",\"title\":\"B\",\"isRunning\":false,\"lastActivityAt\":\"2026-10-24T12:00:00Z\"}` with `isArchived` absent, the present adapter records one skip; an implementation that reads “skip archived” as only `isArchived is True` can instead pin and rename it. State `isArchived is not False` is skipped for both operations and add this exact probe.
  Observed input: `{\"sessionId\":\"local_arch_flag\",\"title\":\"B\",\"isRunning\":false,\"lastActivityAt\":\"2026-10-24T12:00:00Z\"}` with `isArchived` absent; current `row.get(\"isArchived\") is not False` skips it.
  Affected scope: every Desktop row whose archived-state field is absent or not literal `false`.
  Falsifier: a probe with this row reports `skipped: 1`, no error, no pin and no rename; the same row with `isArchived: false` remains eligible according to activity/pin state.
- [Should] Remove or qualify the rollback promise to manually unpin receipt entries. Step 2 correctly says there is no automatic undo because native `pinned` has no ownership ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:70-75`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L70-L75)), but Bet check says the receipt pins are “undone with `set_pinned(false)`” ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:97`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L97)). That contradicts the plan’s never-unpin safety rationale: the receipt cannot prove ownership after an operator has changed the boolean. Limit rollback to reverting the planner/SKILL change; any operator-directed unpin must be an explicit manual choice, not a promised rollback action.
  Observed input: receipt `{\"session_id\":\"local_manual\",\"op\":\"pin\"}`; task-sync pins it, then an operator changes `true → false → true` before the documented rollback.
  Affected scope: every receipt entry acted on after an intervening manual pin-state change.
  Falsifier: native state gains a stable pin provenance or revision matching the recorded mutation; a nonmatching recheck then performs no `set_pinned(..., false)`.
- [Pass] The plan now preserves the existing missing/non-boolean `isRunning` skip and specifies the corresponding no-proposal probe ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:63`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L63), [`GH-1196-TASK-SYNC-DESKTOP-PINS.md:84`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L84)).
- [Pass] The native recheck and no-automatic-undo contract are now concrete: a fresh `list_sessions` accepts only missing/`false` pin state, and a boolean-only undo is forbidden ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:71-75`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L71-L75)).

VERDICT: FAIL

Basis: The prior running-row and ownership findings are resolved; the plan remains one planner/report surface and its rating is commensurate. It still needs exact `isArchived` fail-closed parity and a non-contradictory rollback promise. No other pre-existing defect was found in the swept adapter, CLI, core, SKILL procedure, or ZCode pin pattern.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · Round 3

Operator, 2026-10-24: "Yes, allow one more Codex plan review round on #1196, then build and PR it." This reopens the relay for one extra round (ROUND 4 / 4).

- Finding 1 (`isArchived` fail-closed parity): **Implemented.** Plan step 1 says any row whose `isArchived` is not literal `false` is skipped for pins and titles (`GH-1196-TASK-SYNC-DESKTOP-PINS.md:63`). Step 3 adds your exact probe: `isArchived` absent → `skipped: 1`, no error, no pin, no rename; the same row with `isArchived: false` is eligible (`:85`).
- Finding 2 (rollback promise): **Implemented.** Rollback is now only reverting the PR to stop new pins. Existing pins stay; the receipt lists them, and any unpin is the operator's own manual choice. task-sync never unpins (`:98`).

Round 4 (operator-authorized, last): please re-review plan steps 1–4, R2 and the Bet check rollback line.

### Reviewer · Round 4

swept file: yes

- [Should] Remove the remaining boolean-only undo promise from the plan's Key concepts. It says that an undo “checks the session is still pinned” ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:37`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L37)), while the native procedure correctly says `pinned` has no ownership and therefore forbids automatic undo ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:70-75`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L70-L75)); a boolean recheck cannot distinguish task-sync's pin from a later manual re-pin. Replace the Key-concepts sentence with the already-stated contract: task-sync only adds pins; it never unpins, and the receipt is for an operator-directed choice.
  Observed input: receipt `{"session_id":"local_manual","op":"pin"}`; task-sync sets `pinned:true`; the operator changes it `true → false → true` before the described undo.
  Affected scope: every pin receipt whose later boolean state is used as authority to call `set_pinned(..., false)`.
  Falsifier: `list_sessions` exposes stable pin provenance or a revision matching the recorded mutation; without a matching value, no unpin call occurs.
- [Pass] The round-3 fixes now preserve both fail-closed eligibility predicates: non-literal `isArchived` and missing/non-boolean `isRunning` rows are skipped for pins and titles, with falsifiable probes ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:62-66`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L62-L66), [`GH-1196-TASK-SYNC-DESKTOP-PINS.md:83-85`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L83-L85)).
- [Pass] R1–R3 map to falsifiable checks, and the plan keeps the existing planner/report surface with a fresh pin recheck and no added writer ([`GH-1196-TASK-SYNC-DESKTOP-PINS.md:44-48`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L44-L48), [`GH-1196-TASK-SYNC-DESKTOP-PINS.md:70-89`](PROJECT/1-INBOX/GH-1196-TASK-SYNC-DESKTOP-PINS.md#L70-L89)).

VERDICT: FAIL

Basis: Steps 1–4 and the Bet-check rollback are now sound, and no other pre-existing defect was found in the swept plan, adapter, CLI, core, skill procedure, or ZCode pin pattern. However, the Key-concepts undo sentence contradicts the plan's never-unpin safety boundary. This was the operator-authorized final round, so the relay is escalated rather than opened for another ordinary cycle.

Handing off to Producer for escalation disposition — go to the Producer window and say “take your turn”.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
