# RELAY · GH-1255 and rebalanceOS GH-368 Codex capture plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh1255-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: .relay-artifacts/GH-1255-CODEX-CAPTURE.md plus upstream utils/clio-capture/clio-codex-tail.sh, INSTALL.md, clio-store.py and test/clio-codex-tail.sh
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-29
- Definition of Done: Grade the complete plan against Forge #1255, submitted-event provenance, replay/retry semantics, bounded canary and existing-suite-only scope. Check grounded ratings, dependency order and rollback. Operational envelope: local personal capture utility, not a multi-tenant service. Keep machinery commensurate; do not require unrelated infrastructure. Production edits are forbidden until plan approval. Review the actual upstream code in target root. Target-device rollout/schema observations are supplied evidence, not runtime verification. Source/standalone parity receipt is in the Forge tracking commit. Flag any plan gap preventing a safe implementation. Writes limited to this relay thread.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The parser direction and scope fit the request. Resolve the two replay-safety plan gaps below before implementation; neither requires another service, suite, schema or gate. This is static plan/source review, not a claim that candidate code has failed.
swept file: yes

Read the complete seeded plan, upstream tailer, INSTALL, store helper and existing Codex suite. The pre-existing age-only lock defect below is in scope; no additional pre-existing defect requiring expansion of this capture fix was identified. GitHub issue bodies #1255 and upstream #368 were read through the connector. Target-device/schema observations and publication parity remain supplied evidence, not independent runtime verification.

- [Should] R1 — Specify durable replay intent and its retry acceptance. Step 3 (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:70`) requests a known-file rewind, while the retry description at line 50 says to leave the file cursor unchanged. With the existing success-only checkpoint, merely overriding offset/eligibility in memory loses that rewind when the writer fails: the following ordinary tick reloads the old EOF. State explicitly how the existing state records the pending rewind/eligibility before delivery, without advancing over unaccepted bytes or changing the global capture cutoff. Extend the existing retry case to cover this combination, including a failure after one accepted row and retry without the backfill environment variable. Do not introduce a second state store.
  Observed input: `utils/clio-capture/clio-codex-tail.sh:229-256` reloads a known offset and skips EOF; `:298-315` leaves its stored state untouched on writer nonzero. The new known-file rewind is specified at plan line 70, but its failure checkpoint is unspecified.
  Affected scope: explicit replay of an already-known root rollout whose prior cursor has passed the missed events, followed by writer failure and an ordinary scheduled retry.
  Falsifier: in the disposable clone, seed a known EOF cursor, replay two eligible historical events, reject the second write, then run normally without `CLIO_TAIL_BACKFILL`. Both events must ultimately exist exactly once, original source bytes/global cutoff must match, and no undelivered event may be skipped. If the proposed design already achieves that, document its state transition and retain that existing-suite receipt.

- [Should] R2 — Make replay exclusive against the scheduled tailer. Step 7 (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:74`) backs up state and replays history without specifying quiescence. The current lock treats age greater than 300 seconds as proof of death, with no owner-liveness check or renewal (`utils/clio-capture/clio-codex-tail.sh:53-67`); INSTALL's assertion that a live lock is never taken is too strong. A manual history replay overlapping a scheduled tick can therefore have its lock removed if it lasts beyond that age. Cheapest correction: document temporarily pausing the existing Codex tailer schedule, verifying no invocation remains, taking the state backup, performing replay, and restoring the identical schedule after completion or failure. Correct the lock wording in the already-planned INSTALL edit. No replacement scheduler or lock framework is requested.
  Observed input: the concrete predicate at tailer line 56 is only `now - born > 300`; line 61 removes the lock and line 66 unconditionally removes it on exit. There is no distinction between a dead holder and a still-running replay. Plan line 74 supplies no exclusion procedure.
  Affected scope: manual explicit replay while another invocation can start, particularly a replay lasting more than 300 seconds. Actual target replay duration has not been measured.
  Falsifier: an existing, explicitly cited deployment procedure that already stops and drains all Codex tailer invocations through replay, or a clone-run overlapping long-holder check showing the live holder cannot be displaced. Either would remove the need for an additional procedure here.

- [Pass] Provenance and storage scope are appropriate: plan lines 25, 69 and 78 prohibit response-item fallback, retain legacy/child behavior, and require nonempty SQLite rows plus stable replay IDs. Upstream first-file provenance is independent of resumed context (`clio-codex-tail.sh:121-139`); the writer forwards `source_event_id` (`INSTALL.md:173-178`), and the store supplies durable pending receipts plus replay dedup (`clio-store.py:229-271`). Preserve these paths.
- [Pass] Canary remains diagnostic and bounded: plan line 71 specifies one warning at three complete root-active zero-acceptance ticks, reset/suppression conditions, and compatible stdout; it explicitly admits assistant activity can trigger the warning. Lines 72 and 78 reuse existing verification and require a red control. No additional monitoring subsystem is warranted.
- [Pass] Rating, dependency order and rollback are grounded at plan level: line 29 treats the reports as one incident with unknown trend; lines 68-74 gate production edits, upstream landing, publication and deployment in order; lines 50 and 63 retain captured history on rollback. Session `01a18930` remains explicitly unrecoverable under the supplied submitted-event evidence (lines 52-54), consistent with upstream #368 rather than silently substituting injected text.
- [Nit] Make the final live acceptance procedure explicit at plan line 74: timestamp a substantive new Desktop submission on the requested target, observe its `agent=codex` SQLite row within 120 seconds, and record each requested session as recovered or unrecoverable. Forge #1255's Acceptance section requires this; checking schedule configuration alone does not establish delivery latency.
- [Unverified — needs clone run] No tailer, test suite, executable fixture, deployment or live DB probe was run in this reviewer workspace. Modern-shape delivery, replay/retry interaction, canary sensitivity and compatibility remain required clone checks. Static citations above are not behavioral test receipts.

Handing off to Producer (codex-producer) — resolve R1/R2 in the plan and disposition every finding, then return for Round 2. Production edits remain unapproved.

### Producer · Round 1 dispositions

R1 — Implemented in the revised plan: persist per-file rewind/eligibility through existing state_update before delivery, never alter global cutoff. A failed second row must retry on an ordinary tick and leave both SQLite events exactly once. No second state store.
R2 — Implemented via the cheapest documented procedure: record/temporarily stop only the scheduled Codex tailer, verify all invocations drained, back up state, replay exclusively and restore the identical prior schedule in a finally/cleanup path. Correct the age-only lock wording in INSTALL; no lock framework or scheduler code expansion.
Pass findings acknowledged. Live-acceptance nit — Implemented: timestamp a substantive target Desktop submission, verify its SQLite row within 120 seconds, and report each requested session recovered/unrecoverable. Clone/live verification remains outstanding; no claim of delivery.
Round 2 request: review these precise revisions against R1/R2 and the unchanged scope. Previously read upstream source is unchanged; avoid broadening into unrelated systems. Production code remains unchanged. Handing off to Reviewer.

### Reviewer · Round 2

VERDICT: PASS
Basis: Approve the plan for implementation. R1/R2 and the live-acceptance clarification are addressed without adding another state store, scheduler, suite or gate. This is plan approval, not implementation, merge, deployment or recovery acceptance.
swept file: yes

Read the entire revised artifact, upstream `utils/clio-capture/clio-codex-tail.sh`, `utils/clio-capture/INSTALL.md`, `utils/clio-capture/clio-store.py`, and `test/clio-codex-tail.sh`, including unchanged sections. Re-read Forge #1255 and rebalanceOS #368 through the GitHub connector. No additional pre-existing defect requiring expansion of this capture plan was identified; the previously identified age-only lock limitation remains addressed by exclusive replay and corrected documentation.

- [Pass] R1 resolved at plan level (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:70`): "Before any replay write, atomically checkpoint that file at offset zero/eligibility 0 through existing state_update, preserving the global capture cutoff." The same step requires an ordinary retry without the flag after the second writer call fails, exactly-once stored results and unchanged source bytes/cutoff. This uses the existing checkpoint owner (`clio-codex-tail.sh:80`) and preserves the success-only advancement path (`clio-codex-tail.sh:311`). Clone execution must still establish the behavior.
- [Pass] R2 resolved at plan level (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:74`): stop only the existing scheduled tailer, verify scheduled/manual invocations drained, back up state, replay exclusively, and restore the identical previously loaded job in cleanup on success or failure; leave a previously unloaded job unloaded. Correcting INSTALL's claim accounts for the actual age-only predicate (`clio-codex-tail.sh:56`) without expanding the lock mechanism.
- [Pass] Live-acceptance clarification resolved (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:74`): timestamp a substantive target Desktop submission and observe its matching `agent=codex` SQLite row within 120 seconds, with each requested session reported recovered/unrecoverable. Keep Forge #1255 open until acceptance is met. The unavailable session is not silently counted as recovered; the submitted-event-only constraint at plan lines 25 and 54 agrees with rebalanceOS #368's instruction to report response-item-only sessions unrecoverable.
- [Pass] Complete-plan provenance and replay contracts remain sound: plan lines 25 and 69 exclude response-item capture and retain legacy parsing; line 70 retains child exclusion and stable stored identities. First-file provenance is enforced at `clio-codex-tail.sh:121-136`, source IDs derive from original line offset/hash at `:198`, the writer forwards them at `INSTALL.md:173-178`, and SQLite capture uses durable pending receipts with replay-aware insertion at `clio-store.py:258-271`.
- [Pass] Scope, canary and evidence remain commensurate (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:61`, `:71-78`): one warning at three complete root-active zero-acceptance ticks, explicit reset/suppression, compatible stdout and an acknowledged assistant-activity false-positive limitation. Existing-suite/manual checks must prove nonempty SQLite rows, stable replay IDs, compatibility and sensitive red controls. No new monitoring service, suite or gate is needed.
- [Pass] Rating, dependency order and rollback remain appropriate at plan level (`.relay-artifacts/GH-1255-CODEX-CAPTURE.md:29`, `:63`, `:68-74`): one continuing incident with unknown trend; plan approval before production edits, independent final review before upstream landing, publication after merge, then authorized deployment and acceptance. Code rollback preserves captured history and never rewinds the canonical DB.
- [Unverified — needs clone run] No tailer, executable fixture, test suite, deployment or live DB probe ran in this review workspace. Modern-shape delivery, durable replay retry, canary sensitivity and compatibility still require the planned disposable-clone checks. Target schema/session observations and publication parity remain supplied evidence, not independently measured results in this turn.

Relay closed (Approved), no further turn needed. Producer (codex-producer) may proceed with the approved implementation and required clone verification; later merge/deployment authority remains separate.


### Attestation · relay-drive — 2026-10-30T01:15:49Z
task: RELAY-gh1255-plan
reviewer: codex
status: Approved
reviewed-head: 7625b526bc4a0e43f3da0aae5ce5a9e8be872659
added-range: 13381+4393
added-sha256: 8e8fc3c3a45d9b15d4345a70e6fffc25fa9598a517ef8a9d75788a3b8c45fdc8
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
