# RELAY · GH-1637 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-26.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1637-plan): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1637-REVIEW-CAP-CONSULT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1637-REVIEW-CAP-CONSULT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-26
- Definition of Done: the plan's `## Acceptance` list, graded against the operator decision recorded on issue #1637
  (4-round default; one Codex+agy consult at the cap; adjudicated findings continue to the real gate and a ready PR
  recorded as `consult-adjudicated`, distinct from `Approved`; a real finding gets one repair; hold only for
  safety/authority; push gate, red-then-green and operator merge kept).
- Review packet (GH-1414 paraphrase-first): BEFORE reading any source file, write 2-5 sentences each under
  **What this proposes** and **How the existing system works, per this document**, plus **What it's not** where a
  consequential expectation could be mistaken (ground exclusions in the plan's sections; label inference). THEN
  validate against source: `utils/py/relay_drive.py` (cap loop ~:1016-1436, `judge_terminal` ~:810-1000,
  `--consult-verify` ~:1238), `utils/py/relay_attest.py` (`TERMINAL`, `load`), `utils/py/marathon_drive.py`
  (`:2553`, `:3072`, relay-drive cmd ~:3519), `relay-automation/marathon.sh:587`, `utils/py/jog_run.py` (auto-merge ~:420),
  `relay-automation/consult.sh`, `test/gh115-round-cap.sh`. Label that part "source-backed".
- Operational envelope: grade against the stated requirements, commensurate complexity, and the repo's own threat
  model; a factory-run efficiency change, not an enterprise subsystem. The repo forbids new tests (AGENTS.md, GH-831):
  verification is existing suites plus a recorded manual check. Specific questions: (1) what stops an unchanged,
  unfixed driver from being reported as delivered, and where is the observed rejection? (2) can `Consult-Adjudicated`
  ever satisfy a consumer that requires `Approved` (express, jog auto-merge, gate_receipt, PDDA)? (3) is reusing
  `judge_terminal` with `actor = args.reviewer` sound, including the driver-run gate and token `done` check? (4) does
  `hard_cap = round_cap + 2` break any existing suite? (5) does the plan extend the existing driver rather than add a
  parallel subsystem? Round budget: up to 4 review rounds; classify findings [Blocker]/[Should]/[Nit].

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The proposed repair can end on the builder's turn, the terminal path lacks an authorized token close and distinct attestation provenance, and the plan does not carry the adjudication to the ready PR or prove that an unfixed candidate is refused.

swept file: yes

**What this proposes**
The factory would default to four review rounds, then use one Codex and agy consult to adjudicate unresolved findings. Two non-blocking answers would send the pinned candidate to the existing gates and ready-PR path under `Consult-Adjudicated`. A real finding would allow one repair cycle, and safety findings or unavailable verdicts would trigger a named hold.

**How the existing system works, per this document**
Jog and Preflight pass a turn budget through Marathon to relay-drive. The driver currently extends the budget on qualifying progress and escalates at the cap. The reviewer terminal path runs a configured gate, checks the token, and attests the candidate for Marathon.

**What it's not**
The acceptance criteria and non-goals reserve merge authority for the operator on adjudicated lanes and retain push and red-then-green checks. They scope implementation to the Python driver and existing verification facilities.

**Source-backed findings**

- [Blocker] Route a REAL finding to the builder, then review the repaired head. Observed input: the proposed default is 9 turns and Plan step 2 simply adds two turns. Marathon starts with the builder and alternates (`utils/py/marathon_drive.py:3130-3133,3149-3156,3164-3166`), and relay-drive dispatches the token actor (`utils/py/relay_drive.py:1019-1021,1082-1087`). At turn 9 the builder has handed off to the reviewer. Two more turns run reviewer then builder, leaving the repair unreviewed. Plan step 2 also adds two to both caps after progress extensions, so a consult at the initial hard ceiling of 11 can reach 13. Affected scope: REAL at odd caps and any adjudication reached after a progress extension. Falsifier: stub advisors return REAL at caps 9 and 2, the builder commits a repair, the next reviewer sees that exact SHA, and neither a second consult nor turns past the documented ceiling occur. Specify actor routing and a single budget for the enabled path at the configured cap, with the repair pair reserved.

- [Blocker] Give the driver an explicit adjudication path through the shared terminal checks. Observed input: Plan step 2 says to close the token, set `actor = args.reviewer`, and call the existing judge. After a normal handoff the token is open and reserved for the next actor (`utils/py/relay_drive.py:562-578`, `utils/py/marathon_drive.py:3149-3166`). `done` requires a current owner and `claim` refuses the wrong handoff identity (`src/scope.js:27-34,133-136`, `src/claim.js:43-54`). The current judge does not recognize the new word (`utils/py/relay_drive.py:556-557,849-864`); adding it to that predicate alone would also let an ordinary reviewer turn present it. The judge records `actor` as the reviewer and can refuse after the gate, token check, or publication (`:908-956,965,987-1009`). Affected scope: driver-authored adjudication and ordinary turns attempting to set the new status. Falsifier: the driver handles either open handoff without overriding a live claim, records the consult as the decision source, and only returns 0 with a readable attestation and a done token. Direct reviewer-authored adjudication and a nonzero driver gate both refuse. Define the checked token transition, a fresh transcript/HEAD snapshot at consult entry, the driver-only status origin, and refusal handling that leaves a truthful, recoverable state. Reuse the gate and receipt writer.

- [Should] Parse a complete two-advisor result and bind their input to the candidate. Observed input: the proposed “same parse” accepts any line containing `->` and scans a file for the first matching token (`utils/py/relay_drive.py:1289-1302`), while consult emits both successful paths and failed/partial paths and can retain a single survivor (`utils/py/consult.py:949-981,1036-1051`). Also, the same invocation sets `CONSULT_ROOT` to the harness (`relay_drive.py:1275-1278`), while the consult workspace is cut from stash/HEAD of that root (`consult.py:604-607,730-737`). This differs from the target checkout supported by `marathon_drive.py:3529-3530`. Affected scope: partial/malformed results and foreign-target or dirty-workspace runs. Falsifier: a surviving Codex NON-BLOCKING with agy missing, failed, or emitting conflicting tokens yields a named hold. Two successful responses about the pinned target revision yield adjudication even with a separate harness root. Specify exactly one valid verdict from each named successful advisor and pin the evidence/workspace to the same target revision the receipt attests.

- [Blocker] Carry adjudication through PR publication and enforce operator-only landing at the shared merge boundary. Observed input: Plan steps 3–4 only change the Marathon terminal reader and one Jog caller. `utils/py/marathon_drive.py:137-144,2735-2739` supplies generic PR notes to the closeout body (`relay-automation/marathon-closeout.sh:198`), while `marathon_drive.py:1751-1754,2794-2798` hard-codes reviewer approval in QA output. The loaded status also reaches the shared Jog merge helper from `jog_run.py:2180,2218`, where `:2113-2134` has no status check. Affected scope: adjudicated PR publication, QA reporting, and every automated Jog merge entry point consuming the expanded reader. Falsifier: ready PR text names the adjudication and links both retained answers, QA output reflects the actual decision source, and Jog refuses the new status before making a merge call through any entry point. Put the refusal in the shared helper and preserve existing approved/closed behavior where already admitted. Express explicitly requires Approved (`express.py:204-205`). PDDA's QA check still requires Approved or Closed (`utils/pdda/check_marathon_qa.py:299-306`). The archived lane path in `gate_receipt.py:145-175` accepts a valid terminal record covering the candidate, so widening its admission is real. Spell out that it can qualify the candidate for push while approval-only consumers refuse it.

- [Should] Add the unchanged/unfixed negative control to the manual check. Observed input: candidate identity checks compare the reviewed head and its allowable tail (`utils/py/relay_attest.py:463-518`), while Marathon skips the acceptance recheck when a contract or fix probe is absent (`utils/py/marathon_drive.py:2675-2678,2695-2704,2756-2775`). The existing recorded GH-438 run shows both cases: unfixed probe exits 5 with `acceptance-probes-unmet`, and a contract-less lane exits 0 (`TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:2831-2842`). Affected scope: factory implementation lanes whose adjudicated candidate may leave the requested work unfixed. Falsifier: on a GH-438-style still-unfixed candidate with two NON-BLOCKING stub answers, the existing acceptance check stops delivery before ready-PR publication, and a fixed candidate advances. Specify the existing lane-specific evidence required for a delivery claim when fix probes are absent and retain the red and green outputs with provenance.

- [Should] Reconcile the cap and template promises with the existing suite and the issue. Observed input: Plan lines 46–47 promise unchanged default-off behavior while step 2 unconditionally changes the hard cap. For cap 5 the current formula gives 10 and the proposal gives 7 (`utils/py/relay_drive.py:1016-1019`). The direct GH-115 cases use cap 2, where both formulas give 4, but its Marathon integration invokes cap 1 and pins `cap-stalled` (`test/gh115-round-cap.sh:53,70,91,152-173`, recorded baseline `TESTS-RESULTS/2026-11-16+GH-1503/focused-gh115-round-cap.log:3-10`). An unconditional Marathon opt-in changes that reason and sends this fixture toward advisor launch. The fetched [issue #1637](https://github.com/HiQS-Labs/XYZ-forge/issues/1637) also names contract templates and asks to count evidence repairs in Notes. The plan declares the latter rejected without a recorded disposition (lines 15,40,47,57). Affected scope: default-off direct callers, Marathon's existing cap fixture, and factory contracts generated with old defaults. Falsifier: cap-5 default-off behavior matches baseline, the existing fixture runs with deterministic local stubs and asserts the intended durable reason, and updated template defaults still preserve explicitly authored short caps. Scope the new ceiling to opt-in, name the fixture change and template disposition, and resolve the evidence-repair note against the stated decision.

- [Pass] The proposed architecture extends the existing driver, consult runner, attestation writer, and Marathon pre-advance gate (Plan steps 1–5, `utils/py/relay_drive.py:849-860,1275-1280`, `utils/py/marathon_drive.py:2756-2788`). The findings require completing those seams, with no separate review subsystem.

Whole seeded plan reviewed. The pre-existing acceptance skip and generic approval reporting above become material on this path. Graph coverage was checked against the nearest indexed checkout (generation 2026-11-26T04:31:47Z, head e22fd237); findings use source lines from this worktree. [Unverified — needs clone run] Runtime cases and existing suites were inspected as source or prior receipts during this plan turn. No phase gate was specified for the reviewer.

### Producer · Round 1 dispositions

1. [Blocker] REAL repair ends on builder turn / ceiling overrun — **Implemented**: grant is +2 when the builder is next, +3 when the reviewer is next, once; ceiling is cap+2 (+ that single grant); falsifier runs at caps 9 and 2 added to the manual check.
2. [Blocker] Token close and provenance — **Implemented**: driver closes the token with ordinary `tick` claim/release/done; `judge_terminal(adjudicated=True)` is the only producer of the new word and an ordinary turn writing it is reverted as forged; the record and trailer carry an `adjudication` field.
3. [Should] Complete two-advisor parse, target-repo root — **Implemented**: `CONSULT_ROOT` = target repo; both advisors must be `[ok]` with exactly one distinct token each, else `consult-inconclusive`.
4. [Blocker] PR text and merge boundary — **Implemented**: refusal moved to `_merge_reviewed_pr`; `lane_pr_notes` and the phase QA comment name `consult-adjudicated` and link both answers; success text derives from the attested status.
5. [Should] Unfixed-candidate control — **Implemented**: manual check includes an unfixed candidate with two NON-BLOCKING stubs reaching the existing `acceptance-probes-unmet`.
6. [Should] Default-off vs hard cap, gh115 Marathon fixture, issue notes — **Modified**: `round_cap + 2` only with `--consult-at-cap`; consult requires a completed reviewer turn so the cap-1 fixture still ends `cap-stalled`; TESTS-RESULTS-only repair note is `Disposition: Rejected (Out of Scope / Ponytail)` with reason in the plan; no code writes a contract `round_cap`.

Plan updated in `PROJECT/2-WORKING/GH-1637-REVIEW-CAP-CONSULT.md`. Handing off to Reviewer for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
