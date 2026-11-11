# RELAY · GH-1000 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1000-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1000-EVIDENCE-LINKED-CONSOLIDATION.md`, `TESTS-RESULTS/2026-11-10+GH-1000/` and `CHANGELOG.md` (the full branch diff is `git diff 68367d668...HEAD`)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-10
- Definition of Done: see "Final QA brief" below.

### Final QA brief

**Goal.** Final QA of the completed documentation slice for umbrella issue #1000, against the plan Approved in `relay-system/2026-11-10/gh1000-plan.codex.md` (reviewed head `712ee432d`). The issue asks to inventory overlapping Storyline / Kanban / dashboard efforts with a disposition each, reconstruct one real failed-or-resumed task from one entry point using existing IDs, select one primary interface, and define a small implementation sequence. It withholds authorization for migration, deletion, deployment and merging, and forbids a new board, knowledge graph, event bus or task-state store.

**Operational envelope.** Documentation-only PR in a single-operator local developer toolkit. Grade against the plan and the issue's stated requirements with commensurate complexity. Do not request new tests, suites, gates or tools (AGENTS.md "No new tests", GH-831). `walk.py.txt` is a recorded manual-check receipt, not a tool: nothing invokes it and it is not in any registry. If you judge that it is nonetheless new test or gate machinery, say so as a finding.

**Read.** The plan doc in full (Phases 1–4 are new since plan QA); the receipt directory; the CHANGELOG entry; and the sources the claims cite. You may re-run the walk read-only as a probe (`python3 TESTS-RESULTS/2026-11-10+GH-1000/walk.py.txt 1254`, and `1064`) with `PYTHONDONTWRITEBYTECODE=1`; it only reads committed files and `git log`.

**Questions.**
1. Does each claim in Phase 2 follow from `walk-gh1254.txt` and the cited committed records? Check in particular the Conflict cell for `gh1254-exec2-gateretry1`, the two unjoined transcripts, the attestation cell of the approved attempt, and the statement that all ten work events carry no execution ID. Is anything labelled [M] that is really a summary or a guess?
2. Does the walk satisfy plan steps 2–3: seven cells per attempt, no attempt complete on a trailer alone, gate cells bound by SHA, ambiguous transcript matches left unknown, and both controls (GH-1064 zero attempts; machine-local attestation MISSING) genuinely able to fail? Is the retained first-run output an honest red witness?
3. Phase 1: is every "Shipped" claim backed by a merged PR or a file path that exists, and is any disposition stated as a decision rather than a recommendation? Spot-check at least rows 2, 4, 5 and 7 against the code.
4. Phase 3: are the per-interface answers accurate to the cited code (`web/flightdeck/issue-context.mjs`, `src/flightdeck/aggregate.py`, `web/flightdeck/app.js`, `utils/py/board_sync.py`, `utils/py/work_connectors/github_board.py`)? Is the Flightdeck recommendation supported, or does the evidence equally support another choice?
5. Phase 4: do drafts A–E stay within "add only missing references" and avoid a second reader, writer, store, scheduler or status vocabulary? Is draft A's proposal to commit failed receipts stated with its real risk? Are the acceptance criteria falsifiable and do they cover the umbrella's section 4 checks (repeated ingestion, stale or conflicting state never done, telemetry failure never approval)?
6. Is the Acceptance map truthful about what is done versus still owed, and does anything in the diff (doc, CHANGELOG, receipt) overclaim? Does the persisted rating `45/35/50/55` still match the evidence?
7. Scope: any accidental file, new test or registry entry, absolute local path, or transcript/secret content in the diff?

Flag anything wrong, missing, overclaimed or over/under-engineered with file:line. Set STATUS to Approved if the slice can be published as a PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The documentation slice is proportionate and the retained GH-1254 conclusions are mostly supported. Correct the completeness claim in the manual receipt and the Paperclip inheritance claim before publication. These need bounded documentation/manual-check corrections, not new tests or runtime work.
swept file: yes

- [Should] **R1 — “Every cell resolved” counts only three cells.** `TESTS-RESULTS/2026-11-10+GH-1000/walk.py.txt:130` increments completeness from transcript, gate and attestation only; invocation is printed but never participates, and attestation at lines 120–122 checks existence without reading its candidate binding. This does not implement plan step 2's seven-cell/bound-review condition. The current zero-complete conclusion is conservative for this corpus, but the receipt's advertised completeness criterion remains false. Correct the recorded manual procedure/tally (or explicitly restrict its claim to the three cells it actually checks), and preserve the historical first-run output unchanged. Do not turn this receipt into a maintained tool or suite.
  Observed input: `walk-gh1254-first-run-red.txt` reports the approved attempt's invocation MISSING yet ends “1 with every cell resolved.” The corrected command retains the same `complete += len(cells) == 3` predicate. The actual approved input still has invocation MISSING (`walk-gh1254.txt`, section `gh1254-exec2-gateretry2`). Inspection command: `nl -ba TESTS-RESULTS/2026-11-10+GH-1000/walk.py.txt | tail -12`, exit 0, decisive output `130 complete += len(cells) == 3`.
  Affected scope: Only this recorded manual walk's completeness and attestation-resolution assertions, including its use as follow-on B acceptance evidence; no production gate change requested.
  Falsifier: A record with transcript, gate and a candidate-bound attestation but no invocation must remain incomplete; a repo-relative existing attestation for a different reviewed head must remain unresolved. GH-1064 must remain UNKNOWN and the current GH-1254 corpus must remain PARTIAL. This can be a recorded manual check under the existing receipt convention.

- [Should] **R2 — Frozen Paperclip does not automatically inherit the evidence display.** The working doc's Phase 1 row 7 says it “costs nothing to keep and cannot drift,” and line 372 says “It inherits whatever Flightdeck gains.” Paperclip shares the snapshot and status helper, but has an independent renderer (`addons/paperclip-dashboard/app.js:86–98`) which selects a fixed set of fields and renders no attempt/evidence links. Draft C changes Flightdeck's view only. Qualify the recommendation: keeping Paperclip frozen preserves its present display; it may receive new snapshot fields without displaying them. No Paperclip implementation is required in this slice.
  Observed input: Paperclip `renderDetail` selects Observation, Progress, Data and Coverage at `app.js:92`, then builds its own handoff at `:97`; its live reader fetches `/flightdeck.json` at `:106`. Read-only Python inspection of the two app sources exited 0 and printed `addons/paperclip-dashboard/app.js own renderDetail True imports other app False`.
  Affected scope: Inventory row 7, the Phase 3 optional-skin recommendation and any implication that draft C updates both interfaces automatically.
  Falsifier: A shared evidence-detail renderer used by both apps, or code generically rendering new attempt/link fields, would justify automatic inheritance. The current fixed-field renderer does neither.

- [Nit] **R3 — Narrow the changelog's shared-reader statement.** `CHANGELOG.md:5` says the three systems “already share one reader,” while the working doc's Phase 1 separates the Forge ledger/views from Rebalance history and its Phase 0 explicitly excludes the raw board connector and release cards from `load_work_evidence`. Say the Forge work projections share the reader and Rebalance consumes ledger/history separately; the present sentence overstates consolidation.

- [Pass] **The retained reconstruction exposes the important gaps.** `walk-gh1254.txt` records six attempts, ten work events carrying zero execution IDs, two unjoined transcripts, a same-SHA red/green conflict, and missing approved attestation; `walk-gh1064-control.txt` ends “UNKNOWN - zero attempts discovered.” Independent JSON-only probe (`python3`, `json.loads` of the approved bundle's result and gate receipt, print identities/SHA/exit and whether any filename contains `attest`) exited 0: `gh1254-exec2-gateretry2 approved`, both SHAs `fc7896aae3349e89d0e929aa1ca299f2fa678f2d`, gate exit `0`, `attestation bundled False`. The first-run red witness is honestly described as an erroneous cell resolution, not a successful full reconstruction. The prose should continue treating the unjoined retries as guesses.
- [Pass] **Reuse and scope are sound apart from R2–R3.** Board refusal is explicit at `utils/py/work_connectors/github_board.py:126–133`; End of Week prescribes the raw connector at `skills/3-weekly/end-of-week/SKILL.md:210`; `web/flightdeck/issue-context.mjs:23–40` handles unavailable, stale and conflicting evidence; `src/flightdeck/aggregate.py:40–43` always returns `needs-qa`. These support the inventory spot checks and the Flightdeck recommendation without establishing a uniquely mandatory interface. Draft A acknowledges the approved-only publication boundary implemented at `utils/py/jog_run.py:1083–1084`; draft C explicitly covers repeat loads, conflict/staleness and telemetry failure. The acceptance map at working-doc lines 464–473 leaves implementation and interface demonstration owed. The SQL row `rmi-01M74K4FNE7GBY2S1W3F24NF5K` stores `45/35/50/55`, consistent with the bounded documentation effort. No additional pre-existing defect found in the task document/receipt sweep; runtime sources were spot-checked, not exhaustively audited.
- [Unverified — needs clone run] No validate/test/pytest or executable fixtures ran. No git commands, including the walk's internal git calls, were run in this turn. Full branch changed-file containment, committed provenance, deterministic PDDA/RELEASES gates and final committed-state verification remain the harness's responsibility. Sibling-repo merge/live-state claims were not independently refreshed; local shipped paths and the supplied approved-plan record were examined. `walk.py.txt` is an unregistered manual-check receipt in this review, not new production test/gate machinery.

Handing off to Producer (claude-a) — go to the Producer window and say 'take your turn'; address R1–R2 and disposition R3, then return for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
