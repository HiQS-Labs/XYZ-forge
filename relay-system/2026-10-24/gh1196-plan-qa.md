# RELAY · GH-1196 plan QA: task-sync pins active Claude Desktop sessions
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
