# RELAY · Landing 2 GH-549 attested QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(landing2-gh549-qa-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/landing2-gh549-qa-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/landing2-gh549-qa-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: Independently review the GH-549 fixture batch-boundary fix and its red/green evidence against the production 500-event limit. Check idempotence, overshoot and lock negative controls. Report cited PASS/FAIL findings; final full ci-local rerun pending.

## Review-token instruction
Do not call tick release or tick done. The Codex turn shim owns the token transition. Review the embedded packet and full source; do not run mutation-heavy suites in the relay worktree. Prior Agy review in landing2-gh549-qa.md said PASS but was not attested because its turn handed the token to Producer.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1
VERDICT: PASS
Basis: Approve the fixture batch-boundary correction and its focused recorded evidence; final landing/promotion qualification remains pending.
swept file: yes

- [Pass] Read the entire seeded packet and swept `test/gh549-work-events.sh:1` through `:1511`, including pre-existing fixture setup and all controls; no actionable pre-existing defect found in this sweep. Graph evidence was provisional: no indexed project matches this worktree; nearest XYZ-forge generation 2026-09-01 returned no connector symbols, and coverage freshness was not_tracked/missing. Findings therefore use current local source and retained logs.
- [Pass] Production reads one ordered batch of at most 500 events (`utils/py/work_connectors/__init__.py:128`, `:136`, `:467`). The existing helper defaults to the pristine maximum (`test/gh549-work-events.sh:159`, `:160`); section 14 emits an event after that snapshot (`:455`), so section 15's seed (`:474`) leaves real work pending. First replay then second no-op still measures cursor idempotence; --reset still deletes the cursor and replays from zero (`:499`; production `:460`). Recorded evidence: `TESTS-RESULTS/2026-09-30+GH-854/gh549-green.log:50` reports replay, `:51` idempotence, and `:52` reset. No fix requested.
- [Pass] Overshoot remains falsifiable: the positive stub reports batch max + 5 (`test/gh549-work-events.sh:524`), production refuses beyond the dispatched bound (`utils/py/work_connectors/__init__.py:295`), and the negative copy removes that guard (`test/gh549-work-events.sh:577`). Seeding MAXID - 1 (`:589`) leaves the latest event pending; the unguarded cursor must become MAXID + 5 (`:594`). Recorded refusal at `TESTS-RESULTS/2026-09-30+GH-854/gh549-green.log:55`; negative result at `:60`: "without the guard the overshoot IS stored (508 > 503)". Old failure at `gh549-red.log:64` was cursor 505 versus expected 508, consistent with first-batch max 500. No fix requested.
- [Pass] Lock check now isolates serialization from batch draining: protected and unprotected runs seed the same MAXID - 1 (`test/gh549-work-events.sh:821`, `:823`, `:858`). The stub logs starts and forces two-party overlap in the negative run (`:782`, `:792`), which removes flock (`:847`). Recorded protected ONE child and newest cursor 503 at `TESTS-RESULTS/2026-09-30+GH-854/gh549-green.log:78` and `:79`, versus unprotected BOTH children at `:80`. Separate monotonic-persistence assertion remains intact (`test/gh549-work-events.sh:875`). No fix requested.
- [Pass] The seeded packet's diff only changes existing-suite cursor setup in sections 15/15c/19, reusing seed_cursor_tail without changing production limits, guards, locks or assertions. Reversibility: Easy; fixture-only scope. Probe `bash -n test/gh549-work-events.sh` exited 0, no output. Read-only log/provenance probe (Python pathlib reads, regex counts of `^  ok  -` and `^  FAIL-`, JSON parsing) exited 0: "gh549-red.log ok= 122 fail= 3"; "gh549-green.log ok= 125 fail= 0"; "focused recorded exits: 1 0". These inspect retained evidence rather than executing the suite.
- [Unverified — needs clone run] Final clean-environment full ci-local run against the committed tip remains outstanding. `TESTS-RESULTS/2026-09-30+GH-854/provenance.jsonl:3` explicitly qualifies green as "candidate diff uncommitted at observation"; `SUMMARY.md` says the final rerun remains outstanding. No mutation-heavy suite, executable fixture, pytest or git command was run in this turn. Producer/harness must obtain final qualification before landing/promotion.

Relay closed (Approved), no further turn needed. Producer claude-a owns the pending final full-clone gate; approval covers this focused review only. User-directed tick done supersedes the embedded shim-owned transition instruction; harness owns the relay-file commit.


### Attestation · relay-drive — 2026-09-30T08:50:36Z
task: RELAY-landing2-gh549-qa-codex
reviewer: codex
status: Approved
reviewed-head: 981e990884a14ba851a6833f9bb97678d4875229
added-range: 5897+3847
added-sha256: c18c8a53b9684cb4830e01e0c39a461e4ad79b482de4c33e8580435ebab1cc5f
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
