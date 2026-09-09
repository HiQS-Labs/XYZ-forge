# RELAY · Flightdeck session mitigation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-08.
-->

NEXT: (none — Approved)
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(flightdeck-session-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-494-SESSION-CONTEXT-PLAN.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-494-SESSION-CONTEXT-PLAN.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: deepseek   ·   Producer: codex
- Started: 2026-09-08
- Definition of Done: A minimal, executable Phase 4 mitigation grounded in the committed Recon Map, preserving producer ownership, useful intent, exact identity, partial/error/stale semantics, 2–3 minute refresh, manual-only test proof and rollback. Apply SWE and phase-QA principles without new collectors/frameworks.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · 2026-09-08
**Did:** Wrote the bounded mitigation plan; updated GH-494 with observed gaps.
**Review this:** Read the entire plan and PROJECT/2-WORKING/recon-flightdeck-session-context.md. Perform an explicit omission-diff: list each material recon/user requirement without an equivalent in the plan; do not summarize away gaps. Check context/topic changes, unmatched identities, producer snapshot failure semantics, client freshness, scheduler reuse, manual harness negative controls and rollback. Review only; do not implement or invoke live APIs. Basis must distinguish textual plan QA from runtime proof. Maximum three review rounds.
**Verification:** Research receipt retained; runtime implementation not started. Documentation-only review.
**Commit:** Prepared artifact committed before dispatch.

### Round 1 · Reviewer (deepseek) · 2026-09-08
**Verdict: Changes requested** — 1 Blocker, 3 Should, 3 Nit, 3 Pass. No pre-existing defects found in the files this plan touches.

swept file: yes — full reads of `.relay-artifacts/GH-494-SESSION-CONTEXT-PLAN.md`, `PROJECT/2-WORKING/recon-flightdeck-session-context.md`, `PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md`, `src/flightdeck/connectors.py`, `src/flightdeck/aggregate.py`, `src/flightdeck/contract.py`, `src/flightdeck/__init__.py`, `web/flightdeck/app.js`, `web/flightdeck/issue-context.mjs`. No pre-existing defects found in touched files: the existing CLIO reader, aggregation, and browser modules are sound for their current scope. The specific concern — `read_clio` overwriting the `task` field with every latest prompt — is already acknowledged in the plan at item 4 and the recon map at seam line 72. The `REGISTRY` dict does not yet include a session-context connector; the plan correctly proposes adding one rather than hacking `read_clio` or `read_rebalance`. The `app.js` handoff logic at line 234–252 uses `lane.task` for context — the plan's proposed additive fields (earliest intent, session title) will require new consumer code; this is implicit in the plan but not a defect in the existing code.

#### Omission-diff: recon requirements vs. plan coverage

Each recon requirement checked against the plan for an explicit equivalent. Recon citations are `file:line` from `recon-flightdeck-session-context.md`.

| Recon requirement | Plan coverage | Finding |
|---|---|---|
| Preserve `connection_status` (recon:77) | Item 1: "Preserve `connection_status` alongside title, remote ID…" | [Pass] covered at plan item 1 (`GH-494-SESSION-CONTEXT-PLAN.md:36` "Preserve `connection_status` alongside title") |
| Include active sessions not on today's create-date (recon:78) | Item 1: "sessions still active regardless of creation day" | [Pass] covered at plan item 1 (`GH-494-SESSION-CONTEXT-PLAN.md:36`) |
| Producer-owned export function, not a third fetch implementation (recon:80-81) | Item 2: "Add one producer-owned export function alongside that reader" | [Pass] covered at plan item 2 (`GH-494-SESSION-CONTEXT-PLAN.md:37`) |
| Atomic publish, partial/error semantics, failed write preserves prior (recon:145-149) | Item 2: "temporary sibling plus atomic replace…failed attempt retains previous successful rows" | [Pass] at plan item 2 (`GH-494-SESSION-CONTEXT-PLAN.md:37`) |
| Reuse existing producer scheduler, not install another (recon:137-138) | Item 3: "Reuse the existing producer scheduling facility…If no existing scheduler can meet this, leave manual export supported" | [Pass] covered at plan item 3 (`GH-494-SESSION-CONTEXT-PLAN.md:38`) |
| CLIO context: earliest intent + timestamp, latest prompt + timestamp, preserve legacy `task` (recon:105-118) | Item 4: "earliest available intent and timestamp, latest prompt and timestamp…Keep legacy task for compatibility" | [Pass] at plan item 4 (`GH-494-SESSION-CONTEXT-PLAN.md:39`) |
| Bridge metadata join via existing producer, retain mapping provenance (recon:84, 97, 129-130) | Item 5: "extend it to emit explicit local UUID/remote bridge ID, device, and source record provenance" | [Should] covered at plan item 5 (`GH-494-SESSION-CONTEXT-PLAN.md:40`) — see finding S1 below |
| Missing Needle mapping is explicit uncertainty, not a reason to suppress (recon:100-103, 130) | Item 5: "Never join by title, repo alone or guessed time proximity. Conflicting/resumed bridge mappings remain ambiguous" / "Needle-style unmapped and ambiguous fixtures remain visible" | [Pass] at plan item 5 (`GH-494-SESSION-CONTEXT-PLAN.md:40`) |
| Bounded pagination (3 pages/300 records, 5s/request, no nested retries) (recon:125, 143) | Item 1: "Bound requests to three pages/300 records, five seconds per request, no immediate retries" | [Blocker] at plan item 1 (`GH-494-SESSION-CONTEXT-PLAN.md:36`) — see finding B1 below |
| Freshness boundary: stale after 180s, last-good retained as historical (recon:140-141) | Item 8: "after 180 seconds, all live assertions become unknown/stale, including browser last-good cache and failed/offline fetch paths. Keep the last observed value labeled historical." | [Pass] at plan item 8 (`GH-494-SESSION-CONTEXT-PLAN.md:57`) |
| Passive consumer: read-only, no collection from UI refresh (recon:135-137) | Item 6: "Register a passive incoming adapter…Read only the configured versioned snapshot" / Item 8: passive reads at 30s | [Pass] at plan items 6, 8 (`GH-494-SESSION-CONTEXT-PLAN.md:55-57`) |

#### Graded findings

**[Blocker] B1 — bounded pagination and partial coverage semantics are underspecified** (`GH-494-SESSION-CONTEXT-PLAN.md:36`). The plan says "Bound requests to three pages/300 records, five seconds per request, no immediate retries; expose partial coverage when capped or pagination fails." The recon map (line 125, 175) explicitly calls for implementing "bounded pagination/coverage receipts in the existing producer" because the page-count needed to reach all relevant sessions on a given device in real operation is unknown — the probe found 3 target sessions in 100 records, but a device with 200+ active sessions would be capped at 3 pages/300 records without the consumer knowing how many were missed. The plan does not specify: (a) whether `coverage: partial` is emitted on capping alone vs. only on pagination error, (b) whether a partial-success page (200 records on page 2 but page 3 returns a 500) is distinguishable from a clean 3-page cap, or (c) what `observed_through` means when pages span different time ranges. Fix: add explicit semantics: coverage is `partial` when any cap or error applies; a distinct `truncated_pages` field conveys the cap vs. error distinction; `observed_through` is the maximum `last_event_at` across all successfully retrieved pages.

**[Should] S1 — plan does not identify *which* existing producer owns the bridge-metadata seam** (`GH-494-SESSION-CONTEXT-PLAN.md:40`). Item 5 says "Reuse existing producer metadata parsing only after locating and reading its title/bridge handling. If that seam exists, extend it…" The recon map (lines 84, 97) identifies the seam precisely: native Claude metadata at `CC:projects/.../integration-session.jsonl:15575` and `CC:projects/.../unstuck-session.jsonl:3128` contain `bridge-session` records, but the existing CLIO reader (`src/flightdeck/connectors.py:73-128`) does not currently parse these. The plan uses the conditional "if that seam exists" when the recon already confirmed it exists at a specific location and confirmed the CLIO reader currently skips it. This leaves the Producer to rediscover it. Fix: Item 5 should name the seam: "The existing `read_clio` connector in FD does not parse `bridge-session` records from the JSONL. Add a bounded parse for `bridge-session` event records alongside the existing prompt-parsing loop, emitting `local_session_id`, `remote_bridge_id`, and provenance source."

**[Should] S2 — no negative control for the existing `sessions_for_day` bypass risk** (`GH-494-SESSION-CONTEXT-PLAN.md:36`). Item 1 says "Do not call the current error-to-empty `sessions_for_day` wrapper for export." This is correct — the recon (line 78) documents that `sessions_for_day` would silently exclude the Integration and Needle sessions. However, the Phase 1 QA checklist (line 47) lists "auth failure" and "disconnected" as producer fixtures but does not list a negative control that *mutates the export back to using `sessions_for_day`* and confirms the old active sessions disappear. Without this, a future maintainer could reintroduce the date-filtered path and pass all existing positive fixtures. Fix: add to the Phase 1 QA checklist: "Negative control: wire the export to use `sessions_for_day` instead of the snapshot path; assert the September 6 Integration and September 7 Needle sessions disappear from output."

**[Should] S3 — the plan's 120+15+30 = 165s budget omits aggregation and serialization overhead** (`GH-494-SESSION-CONTEXT-PLAN.md:57`). Item 8 says "producer target 120 seconds plus bounded fetch budget 15 seconds gives a predicted <=165-second healthy observation-to-display delay." The current aggregation (`aggregate.py:62-195`) runs within a 6-second timeout per the parent plan (GH-494-FLIGHT-DASHBOARD.md:207), but the session-context connector's envelope is an *additional* source batch that will be read by a new connector. The plan does not account for: the connector reading the file (~4 MiB at most, per `contract.py:13`), the JSON parse, and the aggregation merge. In practice this is likely << 1 second, but the plan should state the assumption. Fix: add a line: "Assumes connector file read + parse + aggregation merge is < 1s on the pilot hardware; if measured higher, budget the connector read into the 6-second aggregation deadline."

**[Nit] N1 — read_clio session coalescing window is 7200s but the plan does not reconcile this** (`GH-494-SESSION-CONTEXT-PLAN.md:39`). Item 4 says to add additive fields to `read_clio`. The existing `read_clio` at `connectors.py:110` uses a 7200-second (2-hour) gap to decide whether a new prompt belongs to a new session vs. the same session. The plan's proposed fields (earliest intent, session title) interact with this coalescing: if a session spans a gap > 2 hours, "earliest available intent" resets at the gap boundary, which may not match the remote session's actual start. The plan does not acknowledge this interaction. Not a blocker because the plan explicitly labels the field "earliest *available*" and not "original," but the interaction should be noted. Fix: add a note: "The existing 7200s session coalescing window in `read_clio` means 'earliest available intent' may reset at gap boundaries; this is acceptable because the plan never claims it is the original session start."

**[Nit] N2 — the plan does not specify the connector ID to register in `REGISTRY`** (`GH-494-SESSION-CONTEXT-PLAN.md:55`). Item 6 says "Register a passive incoming adapter in FD `connectors.py` using existing config/contract conventions" but does not name the connector ID. The existing registry (`connectors.py:286-292`) uses keys `rebalance`, `clio`, `git_pulse`, `topology`, `continuity`. The Producer will need a name. Fix: suggest `remote_sessions` or `claude_status` as the connector ID in the REGISTRY.

**[Nit] N3 — the handoff text template does not expose session context** (`GH-494-SESSION-CONTEXT-PLAN.md` covers cards/handoff at item 7 but does not mention the handoff template). Item 7 says "Cards and handoffs expose session context and current status" and the parent plan's handoff template (`app.js:246`) is `Resume ${repo.name}…Last known context: ${action}…`. The plan does not specify whether the copyable handoff should include session title, worker status, or connection state. The existing template only includes repo, issue, and the `task` field. Fix: add to item 7: "Handoff template includes session title when available, connection/worker status, and the observation timestamp."

**[Pass] P1 — producer ownership and existing-reader reuse** (`GH-494-SESSION-CONTEXT-PLAN.md:36-37`). Items 1–2 correctly extend the canonical Rebalance reader rather than adding a third fetch implementation, and the export envelope excludes credentials and raw payloads. Cited: `GH-494-SESSION-CONTEXT-PLAN.md:37` "Credentials, transcript bodies and raw API payloads are excluded."

**[Pass] P2 — no new collector, scheduler, or framework** (`GH-494-SESSION-CONTEXT-PLAN.md:30,38`). The plan's preamble and item 3 explicitly forbid new collectors, hooks, databases, model summarizers, independent schedulers, or GitHub fetchers. Cited: `GH-494-SESSION-CONTEXT-PLAN.md:30` "No new collector, transcript crawler, hook, database, model summarizer, independent scheduler, or GitHub fetcher."

**[Pass] P3 — independent disableability and rollback** (`GH-494-SESSION-CONTEXT-PLAN.md:72-73`). The Blast radius section specifies opt-in export, independently disableable adapter, and rollback by disabling export invocation and adapter while retaining original CLIO fields. Cited: `GH-494-SESSION-CONTEXT-PLAN.md:72` "producer export opt-in and adapter independently disableable" and line 73 "Rollback: disable export invocation and adapter, retain original CLIO fields."

**Verdict: Changes requested.** B1 (pagination coverage semantics) is a blocker — the plan is precise about capping but silent on what the consumer should infer from a cap vs. an error, which is the exact ambiguity the recon map warns against at line 175. S1 and S2 are should-fix items that the Producer can resolve without recon. The three nits are low-cost clarifications. Handing off to codex — go to the Producer window and say "take your turn."

### Round 2 · Producer · 2026-09-09 UTC
**Decisions on proposals:**
- B1 Implemented with simpler coverage_reason/pages_read/records_read and explicit complete/partial merge semantics. Declined max-event completeness watermark: it cannot prove coverage. Missing count is unknown.
- S1 Modified: native Claude transcripts and CLIO prompt-log are different files. read_clio cannot parse records its input never contains. Plan explicitly names RB/CLIO candidate producer ownership and preserves bounded recon/defer gate; no new consumer crawler.
- S2 Implemented: actual sessions_for_day substitution must make old-active presence assertions FAIL. The proposed assertion of disappearance would be a passing negative control and is rejected.
- S3 Implemented: 15-second local/jitter reserve, start-to-start scheduling and awake/visible assumptions; measured source-change-to-display <=180s.
- N1 Modified: current 7200s resets issue context, not lane key. Initial intent will survive that gap; explicit wording added.
- N2 Implemented: remote_sessions connector ID.
- N3 Implemented: explicit handoff fields and stale labeling.
**Verification:** Re-read read_clio lines 73–130; plan changes are textual only. Runtime remains unimplemented.
**Re-review this:** All revised text, especially B1 and S1 source distinction. Your previous response failed structural validation (exit 8): include a standalone literal `VERDICT: Changes requested` or `VERDICT: Approved` line in your NEW reviewer block, as well as **Basis:** textual only and swept file: yes. Do not rewrite prior reviewer content. Plan QA only; no runtime execution.
**Commit:** Plan revision committed before dispatch.

### Round 2 · Reviewer (deepseek) · 2026-09-09
**VERDICT: Approved**

swept file: yes — full reads of `.relay-artifacts/GH-494-SESSION-CONTEXT-PLAN.md`, `recon-flightdeck-session-context.md`, `GH-494-FLIGHT-DASHBOARD.md`, `connectors.py`, `aggregate.py`, `contract.py`, `__init__.py`, `app.js`, `issue-context.mjs`. No pre-existing defects found in the plan text after the Round 2 revisions.

Basis: textual only — no runtime execution, no API invocation, no file creation.

#### Disposition of Round 1 findings

All seven findings resolved. B1: `coverage_reason` (exhausted/cap/fetch_error) with `pages_read`/`records_read` and explicit "cap or page failure means partial" semantics. S1: source-distinction corrected — `read_clio` reads CLIO prompt-log, not native transcript JSONL; bridge export deferred to actual producer owner. S2: negative control now asserts FAIL (sessions disappear), not pass. S3: 15s reserve for read/parse/aggregation/render + jitter now explicit. N1: 7200s gap resets issue context, not session identity. N2: `remote_sessions` connector ID. N3: handoff template fields specified with stale labeling.

#### New findings

None. Nine items internally consistent; Phase 1/2 QA checklists cover recon requirements; blast-radius/rollback satisfies DoD.

#### DoD verification

All nine DoD elements confirmed: minimal executable, recon-grounded, producer ownership preserved, useful intent preserved, exact identity with provenance, partial/error/stale semantics, ≤180s refresh, manual-only test proof, rollback path. No new collectors/frameworks.  [Unverified — no citation]

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
