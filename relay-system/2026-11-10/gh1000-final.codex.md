# RELAY · GH-1000 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
-->

NEXT: Reviewer
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
