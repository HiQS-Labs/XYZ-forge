# RELAY · GH-1637 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-26.
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

### Reviewer · Round 2

swept file: yes

**What this proposes**
Factory lanes get four review rounds by default, with one two-advisor consult at the cap after a reviewer has completed a turn. Matching non-blocking verdicts would produce a distinct adjudication receipt and continue to the existing gates and ready PR. A real finding would allow one bounded repair ending on a reviewer turn, and safety or inconclusive results would hold.

**How the existing system works, per this document**
Marathon supplies a turn budget to relay-drive, which extends on qualifying progress and otherwise escalates at the cap. The existing terminal judge runs the configured gate, checks the done token, and records a reviewed candidate for Marathon's pre-advance checks.

**What it's not**
The acceptance criteria reserve landing for the operator and preserve the push and acceptance gates. The non-goals scope the change to the Python path and existing test infrastructure.

**Source-backed findings**

- [Blocker] Keep a failed adjudication gate from spending the relay before it can be retried. Observed input: the proposed NON-BLOCKING path writes the terminal header, runs `tick done`, then calls the judge (plan lines 43 and 70). With a configured driver gate of `exit 1`, the judge returns `gate-failed` before publishing a receipt (`utils/py/relay_drive.py:908-956,984-1009`). The existing refusal handler only exits and records the reason (`relay_drive.py:806-808,1360-1363`). Marathon explicitly refuses a terminal, done token without an attestation at startup (`utils/py/marathon_drive.py:2939-2979`). Affected scope: NON-BLOCKING pairs followed by gate, token, or receipt-publication failure. Falsifier: with both stub advisors NON-BLOCKING and a red driver gate, the same lane has a documented recovery path, the failure stays visible, and no ready PR or valid adjudication is emitted. Specify the order of the driver gate, checked handoff/claim/close, transcript and receipt publication, and the existing recovery path if publication fails after `done`. Preserve the judged snapshot and the final done check. Include a red driver gate and a refusal after token closure in the manual matrix. Round 1's failure-handling requirement remains open.

- [Blocker] Tie the advisors' checked-out content to the attested revision. Observed input: plan line 41 promises a pinned diff, but plan line 70 only sets `CONSULT_ROOT`. The reused runner takes tracked WIP via `stash create`, otherwise uses moving `HEAD`, and overlays untracked files (`utils/py/consult.py:604-607,730-752`). The existing receipt candidate check compares committed objects and cannot detect that overlay (`utils/py/relay_attest.py:473-486,489-518`). Affected scope: a target with a tracked working fix absent at the pinned SHA, or an untracked file covering a missing deliverable. Falsifier: given a tracked marker with value RED at the candidate and GREEN in the working tree, the advisor reads RED, and the receipt names the SHA containing RED. Add a pin to the existing consult isolation path that uses one captured SHA without taking WIP or copying untracked files for this invocation. Take the transcript baseline at the same boundary, build the adjudication block from the exact answers for that snapshot, and exercise a dirty or foreign target with stubs. The strict two-advisor parse addresses the other half of the earlier finding. Also reconcile the stale “same parse” description at plan line 62 with lines 41–42 and 70.

- [Should] Make the REAL result enforce a repair before any terminal review. Observed input: plan line 44 adds three turns if the reviewer is next, but an ordinary reviewer can finish on the first of those three by appending approval and closing the token (`utils/py/relay_drive.py:1023-1028,1082-1087,1345-1365`, `utils/py/marathon_drive.py:3164-3166`). Increasing the budget alone does not enforce its order. Affected scope: REAL with a pending reviewer handoff, including cap 9 after a normal builder-first alternating run. Falsifier: offer an immediate approving reviewer stub after REAL and observe that the driver first dispatches a builder, then judges the reviewer against the repaired SHA, with no second consult or progress extension beyond the stated repair budget. Use the same checked handoff to route the REAL finding to the builder before granting the repair pair, or explicitly prevent the first reviewer turn from closing early. Count review coverage with the existing nonempty review-block predicate (`relay_drive.py:146-157,1385-1394`) so a token-only handoff cannot arm the consult.

- [Should] Define what qualifies an adjudicated delivery when the acceptance recheck is skipped. Observed input: plan lines 46, 48 and 73 add the unfixed case with a probe, but `utils/py/marathon_drive.py:2675-2704,2762-2775` treats absent or unevaluable contracts as unchecked and continues to the repo gate. The prior GH-438 run recorded both the unfixed fixture exiting 5 with `acceptance-probes-unmet` and the contract-less fixture exiting 0 (`TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:2831-2842`). Affected scope: adjudicated implementation lanes missing a usable fix probe. Falsifier: a no-op candidate on a probe-less brief with a green generic gate cannot be published as a completed fix unless the plan names the existing lane-specific check that proves the deliverable. State the eligibility or proof for that input and keep the with-probe red and green control. A read-only AST check of the exact `if unmet` guard exited 0 and printed `[False, False, True]` for `None`, `[]`, and one unfixed verdict respectively:
  ```sh
  python3 -c 'import ast,pathlib; t=ast.parse(pathlib.Path("utils/py/marathon_drive.py").read_text()); f=next(n for n in ast.walk(t) if isinstance(n,ast.FunctionDef) and n.name=="complete_phase_success"); g=next(n.test for n in f.body if isinstance(n,ast.If) and ast.unparse(n.test)=="unmet"); print([bool(eval(compile(ast.Expression(g),"<guard>","eval"),{"unmet":x})) for x in (None, [], [{"verdict":"unfixed"}])])'
  ```

- [Should] Preserve the existing merge eligibility for `Closed` and make the ready-PR boundary explicit. Observed input: plan line 72 refuses every status except Approved, while the existing Jog helper consumes loaded `Closed` records (`utils/py/jog_run.py:420-428,2113-2134`, `utils/py/relay_attest.py:28,440-441`). Affected scope: legacy and Marathon Jog merges with a valid `Closed` receipt, and the new adjudicated receipt. Falsifier: valid Approved and Closed fixtures follow their existing outcomes; an adjudicated candidate with a green gate and ready PR awaits operator landing without issuing a merge. Refuse the new status at the shared boundary and retain current eligibility for older statuses. Plan lines 45 and 71 now reach PR and phase QA text. Express requires Approved (`utils/py/express.py:204-205`), and a cited Codex approval receipt in PDDA must remain Approved or Closed (`utils/pdda/check_marathon_qa.py:294-307`). The gate receipt path instead accepts any load-valid status tied to the reservation and checked candidate (`utils/py/gate_receipt.py:145-175`), so explicitly preserve its push qualification and keep the adjudication out of approval-only receipt slots.

- [Should] Reconcile the evidence-repair decision and include the packaged README in delivery. Observed input: the issue owner's Notes say to count evidence repairs, while plan lines 15 and 53 reject that behavior. The issue fetch returned no superseding comment. Existing progress detection still excludes receipt-only changes (`utils/py/relay_drive.py:1409-1417`, see GH-976 note in plan line 59). Affected scope: receipt-only repairs with room to extend. Falsifier: a sourced operator disposition accepts immediate adjudication for that case, or a scoped receipt-only repair earns the requested extension while transcript-only churn does not. Resolve that disposition explicitly. Separately, step 3 edits `relay-automation/README.md`, packaged at `skills/1-hourly/relay-automation/make-pkg.sh:24`; `test/relay-pkg-freshness.sh:23-34` fails a changed packaged file against the old tarball. Regenerate the existing package with the README change.

- [Pass] The cap compatibility plan now scopes the two-turn cushion to opt-in and leaves the cap-1 Marathon fixture with no completed reviewer turn (plan lines 41 and 47, `test/gh115-round-cap.sh:143-173`). The three direct driver calls omit the proposed flag (`test/gh115-round-cap.sh:53,70,91`). The recorded baseline is 7 pass, 0 fail (`TESTS-RESULTS/2026-11-16+GH-1503/focused-gh115-round-cap.log:3-10`). Explicit contract caps are already optional and forwarded to Marathon (`utils/py/swarm_preflight.py:155-156,1236-1237`); update the published default in the marathon example (plan line 71).

- [Pass] The plan extends the existing driver, consult runner, attestation writer and Marathon gate (plan lines 69–73, `utils/py/relay_drive.py:849-860,1275-1280`, `utils/py/marathon_drive.py:2756-2788`). The new receipt status is distinct, and the plan now puts the driver-only check and advisor provenance on the existing attestation path (plan lines 43 and 69–70).

Whole seeded plan reviewed. The source sweep found existing behavior relevant to the new path in the acceptance skip, consult workspace creation, and post-gate refusal paths above. Graph coverage was checked on the nearest indexed checkout, generation 2026-11-26T04:31:47Z. The graph's trace calls were unavailable under the approval policy, and local source supplied the cited lines. [Unverified — needs clone run] Existing suites and proposed stub runs were not executed in this worktree. No phase gate was specified for this plan-review turn. Issue source: https://github.com/HiQS-Labs/XYZ-forge/issues/1637

VERDICT: FAIL
Basis: The plan still allows a gate refusal to leave a terminal spent token without an attestation, and the consult workspace is not bound to the candidate SHA. The repair and delivery checks also need to cover the early approval and unchecked-acceptance cases above.

### Producer · Round 2 dispositions

1. [Blocker] Gate refusal spends the token — **Implemented**: order is driver gate, then token close (callback inside `judge_terminal`), then publication; a red gate or refused close restores STATUS and leaves the token open; publication failure after `done` is the existing spent-token recovery. Red-gate and refusal cases added to the manual matrix.
2. [Blocker] Consult workspace not bound to the candidate SHA — **Implemented**: `CONSULT_PIN_SHA` in the existing `consult.py` isolation path (base = that SHA, no stash, no untracked copy); the "same parse" wording is corrected; dirty-tree pin check added to the matrix.
3. [Should] REAL must force a repair first — **Implemented**: token routed to the builder, then +2 turns; coverage counted with the existing `review_blocks_added` predicate.
4. [Should] Probe-less acceptance — **Modified**: no new eligibility rule; a probe-less lane keeps today's reviewer+gate assurance; consult prompt says an undelivered brief is REAL and an empty diff is a hold; recorded as an accepted risk identical to the `Approved` path.
5. [Should] `Closed` and ready-PR boundary — **Implemented**: `_merge_reviewed_pr` refuses exactly `Consult-Adjudicated`; `Closed`/`Approved` unchanged; `gate_receipt.py` push qualification unchanged and stated.
6. [Should] Evidence-repair disposition and README package — **Modified**: `Disposition: Rejected (Out of Scope / Ponytail)`, sourced to the operator's brief ("decide them with the leanest change") because the issue note says "consider"; the packaged tarball is regenerated with `make-pkg.sh`.

Handing off to Reviewer for round 3.

### Reviewer · Round 3

swept file: yes

**What this proposes**
Factory phases would default to four review rounds and call Codex and agy once when qualifying review reaches the cap. Two NON-BLOCKING answers would attest the candidate as Consult-Adjudicated and continue to delivery gates, a REAL finding would route one builder/reviewer pair, and a safety or inconclusive outcome would hold.

**How the existing system works, per this document**
Marathon hands a turn cap to relay-drive, which can extend for progress and otherwise escalates at the cap. The terminal judge runs the configured approval gate, verifies the token and writes the reviewed candidate receipt.

**What the plan preserves**
The operator retains landing authority, the push gate and acceptance probe remain, and the change applies to the Python path. Existing suites and a recorded manual matrix supply implementation evidence.

**Source-backed findings**

- [Should] Keep `Closed` eligible at the shared Jog boundary. Observed input: seeded plan line 45 refuses exactly `Consult-Adjudicated`, but line 72 rejects every status other than `Approved`. A valid `Closed` record currently passes the status check in `utils/py/relay_attest.py:28,440–444` and can reach the exact-candidate merge in `utils/py/jog_run.py:2113–2134,2180–2183,2218–2222`. Affected scope: valid legacy `Closed` receipts and the new adjudicated receipt. Falsifier: valid Approved and Closed inputs reach the same candidate checks as today, while Consult-Adjudicated returns before any merge call. Make step 4 match Acceptance and include all three statuses in the manual control. Round 2's finding remains open in the seeded artifact.

- [Should] Make the strict parser and snapshot the single implementation contract. Observed input: plan lines 41–42 require one final verdict per successful advisor; line 62 still specifies “the same parse.” The reused parser takes any `->` row and any first matching token (`utils/py/relay_drive.py:1289–1302`), while consult emits named successful and unsuccessful rows (`utils/py/consult.py:949–981`). Affected scope: duplicate identical verdicts, tokens in quoted rebuttals, and paths supplied by a failed or unrelated advisor. Falsifier: a duplicate final verdict, a token only in quoted text, or a missing [ok] for either named advisor produces `consult-inconclusive`; one exact final verdict from each succeeds. Align lines 42, 62 and 70. Keep the new no-stash/no-untracked rule and explicitly pass the consult-entry SHA and transcript preimage into the judge. Its `pre` inputs drive the append-only comparison and reviewed SHA (`relay_drive.py:872–891,968–972,1088–1102`); the latest ordinary turn's preimage describes a different boundary.

- [Should] Include both token and publication refusals in the manual matrix. Observed input: seeded plan line 43 specifies recovery for a refused close and a publication failure after `done`, but line 48 exercises only a red driver gate among those failures. `judge_terminal` has distinct token and publication refusals (`utils/py/relay_drive.py:954–956,984–1006`), and Marathon startup deliberately refuses a spent token without a valid attestation (`utils/py/marathon_drive.py:2939–2979`). Affected scope: a green driver gate followed by close refusal or receipt-write failure. Falsifier: inject a refused close and observe restored Open status, no driver-owned claim left behind, and no attestation; then allow `done` and inject a receipt-write failure, observe no ready PR, and use `marathon.sh --retry <phase-id>` to dispatch on a fresh token (`relay-automation/marathon.sh:375–382,608–620`). The gate-before-close order fixes Round 2's ordering defect. Add these separate controls to verify the recovery promised by line 43 and the Round 2 disposition.

- [Should] Resolve the evidence-repair request against the operator's actual wording. Observed input: issue #1637 says “count evidence repairs”; the preceding bullet is the one that says “consider” and refers to the ceiling. Seeded plan line 53 uses “consider” to justify declining evidence repairs, and `utils/py/relay_drive.py:1409–1417` still excludes receipt-only commits from the existing progress check. Affected scope: a TESTS-RESULTS-only repair with spare extension budget. Falsifier: cite the operator message that explicitly delegates this tradeoff, or demonstrate the requested extension on an evidence-only repair with a transcript-only negative control. Correct the rationale and make the disposition match its source. [Issue #1637](https://github.com/HiQS-Labs/XYZ-forge/issues/1637)

- [Should] Carry the decision label through the existing optional Marathon closeout. Observed input: plan lines 19–20 and 45 require the ready PR to distinguish adjudication from reviewer approval and link both answers. Step 3 only changes the lane PR. The separate `marathon.sh --closeout-pr` path counts all zero-exit phases as “Phases approved” and passes that text to its PR publisher (`relay-automation/marathon.sh:383–384,662–675,682–696`). Affected scope: a successful multi-phase invocation with `--closeout-pr` and at least one adjudicated phase. Falsifier: a mixed Approved/adjudicated closeout labels the adjudicated phase and carries its existing answer links while retaining the completion count. Reuse phase result evidence for that summary.

- [Pass] The plan now routes REAL to the builder before the reviewer and keeps consult eligibility tied to actual review text (seeded plan lines 41, 44 and 48). The current driver dispatches from the token actor and has a nonempty-review predicate (`utils/py/relay_drive.py:1082–1087,1385–1394`), so this fits the existing dispatch loop. The default-off ceiling is explicit at plan line 47. The cap-1 integration fixture only hands off and still expects `cap-stalled` (`test/gh115-round-cap.sh:143–173`).

- [Pass] The revised plan names the residual probe-less risk and keeps the delivery recheck where the lane supplies a fix probe (seeded plan line 46, `utils/py/marathon_drive.py:2675–2704,2756–2775`). The existing GH-438 receipt shows unfixed exit 5, fixed exit 0, and contract-less exit 0 (`TESTS-RESULTS/2026-09-01+GH-365/qualifying-run.log:2831–2842`). The planned stub-advisor cases still need their own red and green receipt. The package rebuild is specified in step 3 (line 71).

Read-only artifact probe (exit 0) printed `Closed conflict: plan lines 45,72`, `parser conflict: plan lines 41,62`, `post-done failure missing from matrix: plan lines 43,48`, and `matrix names neither refused close nor post-done publication failure`. The decisive checks were:
```sh
python3 - <<'PYCODE'
from pathlib import Path
lines = Path(".relay-artifacts/GH-1637-REVIEW-CAP-CONSULT.md").read_text().splitlines()
items = {
    "Closed conflict": (45, "refusing exactly this status", 72, 'status is not `Approved`'),
    "parser conflict": (41, "exactly one", 62, "the same parse"),
    "post-done failure missing from matrix": (43, "publication failure after `done`", 48, "a red driver gate"),
}
for name, (a, x, b, y) in items.items():
    assert x in lines[a-1] and y in lines[b-1], name
    print(f"{name}: plan lines {a},{b}")
assert "publication failure" not in lines[47] and "refused close" not in lines[47]
print("matrix names neither refused close nor post-done publication failure")
PYCODE
```

Whole seeded plan reviewed. Existing behaviors exposed by the proposed path are cited above. Graph coverage was checked on the nearest indexed checkout (generation 2026-11-26T04:31:47Z, head e22fd237); trace was unavailable under the approval policy. Local source supplied exact lines, including the partial Marathon shell coverage. [Unverified — needs clone run] This is a plan review; existing suites and planned stub-advisor scenarios were not executed, and no reviewer phase gate was specified.

VERDICT: FAIL
Basis: The seeded implementation steps still conflict with the acceptance criteria on Closed receipts and verdict parsing. The recovery matrix and operator disposition remain incomplete, and the optional Marathon closeout would still report adjudicated phases as reviewer-approved.

Handing off to Producer to reconcile the seeded plan and its verification matrix.

### Producer · Round 3 dispositions

1. [Should] `Closed` eligibility / step 4 wording — **Implemented**: step 4 now matches Acceptance (refuse exactly `Consult-Adjudicated`); the Approved/Closed/Adjudicated triple is in the manual matrix.
2. [Should] Strict parser and snapshot as one contract — **Implemented**: stale "same parse" line replaced; the consult-entry SHA and its transcript preimage are the `pre` snapshot given to `judge_terminal`.
3. [Should] Token-refusal and post-`done` publication failure in the matrix — **Implemented**: both added as separate controls, with `marathon.sh --retry` recovery.
4. [Should] Evidence-repair disposition source — **Modified**: rationale corrected (issue says "count evidence repairs"; the operator's task brief delegates the decision to the leanest change, quoted in the plan); disposition stays `Rejected (Out of Scope / Ponytail)` because consult-at-cap removes the stall without a second progress rule.
5. [Should] `--closeout-pr` label — **Implemented**: the multi-phase closeout summary reads phase result evidence to label adjudicated phases and keeps the count.

Handing off to Reviewer for round 4 (the cap).

### Reviewer · Round 4

swept file: yes

**What this proposes**
Factory relays would default to a nine-turn budget and consult Codex and agy once if actual review has occurred and the lane exhausts its eligible extensions. Two non-blocking verdicts would send a pinned candidate through the existing gates under a distinct attested status. An actionable finding would send the builder and reviewer through one repair pair, while safety findings and incomplete answers would hold.

**How the existing system works, per this document**
Marathon passes a turn budget to relay-drive, which extends the budget for qualifying progress and otherwise escalates at the cap. The terminal judge runs the configured reviewer gate, checks the token and publishes the reviewed candidate receipt for Marathon.

**What the plan preserves**
The acceptance criteria retain the operator's landing authority, the push gate and the acceptance recheck. The non-goals leave the legacy Bash behavior in place.

**Source-backed findings**

- [Should] Specify the default-gate ordering and recovery. Observed input: plan lines 43 and 70 promise a driver gate before token close, but the reused judge runs a gate only when `MARATHON_REVIEWER_GATE_CMD` is nonempty (`utils/py/relay_drive.py:908–911,954–956`). Marathon leaves it unset for the default gate and for explicit full suites (`utils/py/marathon_drive.py:559–589,3066–3068,3538–3541`). For those inputs the real gate currently runs in Marathon's pre-advance path (`:2756–2788`). Affected scope: two NON-BLOCKING answers on a normal factory lane with the default gate, or an explicitly configured harness-only gate. Falsifier: a red default gate emits no ready PR and leaves exactly the documented token, transcript, attestation and retry state. Say which gate runs before `done` when a focused gate is armed and what happens when only the real pre-advance gate is present. Exercise the latter red case as well as the focused case already in the matrix. Allow the existing pre-advance recovery if that is the chosen order.

  Read-only selector probe, exit 0. Decisive output: `default='' explicit_full='' explicit_focused='python3 utils/py/marathon_drive.py'`. This evaluated the selector only.
  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
  import ast, os, re, shlex
  from pathlib import Path
  tree = ast.parse(Path("utils/py/marathon_drive.py").read_text())
  gate = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "reviewer_runnable_gate")
  pattern = next(n for n in tree.body if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "_FULL_SUITE_RE" for t in n.targets))
  scope = dict(os=os, re=re, shlex=shlex)
  exec(compile(ast.Module(body=[pattern, gate], type_ignores=[]), "<gate selector>", "exec"), scope)
  select = scope["reviewer_runnable_gate"]
  implicit = select("bash validate.sh", False, ".", "")
  explicit = select("bash validate.sh", True, ".", "")
  focused = select("python3 utils/py/marathon_drive.py", True, ".", "")
  print(f"default={implicit!r} explicit_full={explicit!r} explicit_focused={focused!r}")
  assert implicit == explicit == "" and focused == "python3 utils/py/marathon_drive.py"
  PY
  ```

- [Should] Exclude harness transcripts from the empty-deliverable check. Observed input: plan lines 41–42 and 46 rely on an empty merge-base diff to hold a no-op. On a freshly rendered same-repository lane, Marathon itself stages and commits `RELAY.md` before dispatch (`utils/py/marathon_drive.py:3438–3452`). A candidate whose only change from the integration merge-base is that tracked file has a nonempty raw diff even if no builder changed the deliverable. The existing candidate comparison already distinguishes harness transcripts from other changes (`utils/py/relay_attest.py:489–515`). Affected scope: transcript-only candidates, particularly lanes without a fix probe. Falsifier: a candidate whose only changed path is the phase's `RELAY.md` holds before the consult can confer adjudication, while a candidate containing an actual deliverable change reaches the advisors. Define the empty check over the deliverable diff, reusing the harness-owned path exclusions where they fit. Keep the transcript separately in the prompt. Add a transcript-only control to complement the still-unfixed-with-probe control.

- [Should] Supply the closeout with evidence on its normal entry point and retain the answer links. Observed input: plan lines 45 and 71 rely on phase result evidence, but `--closeout-pr` and progress observation are separate flags (`relay-automation/marathon.sh:392–408`), and only the progress branch supplies `--result-file` (`:624–633`). Marathon arms that writer only when the path is supplied (`utils/py/marathon_drive.py:1270–1275`). The result currently exposes `relay_status` and `attest_path` (`:287–323`), while consult returns local answer paths (`utils/py/consult.py:701–709,953–958,1105`) and the existing Marathon archive stages only the copied relay transcript (`utils/py/marathon_drive.py:2290–2314`). Affected scope: regular Python `--closeout-pr` with progress disabled, and PR or issue readers opening advisor links from another checkout. Falsifier: a mixed Approved/adjudicated `--closeout-pr` run with progress disabled preserves the completed count, identifies the adjudicated phase from that run's validated result, and both answer links resolve from the published PR without access to its authoring checkout. Name the result handoff for closeout-only calls and the published archive location for the exact two answers. Keep the existing result schema and attestation writer where they fit. The Round 3 closeout finding remains open.

- [Pass] Plan lines 45 and 72 now agree on the exact Jog exclusion and line 48 exercises all three statuses. The shared helper reaches the merge only after candidate checks (`utils/py/jog_run.py:2113–2134`). Express still requires Approved, PDDA's approval slot still accepts Approved or Closed, and push qualification uses a load-valid receipt bound to the candidate (`utils/py/express.py:204–205`, `utils/pdda/check_marathon_qa.py:294–307`, `utils/py/gate_receipt.py:145–175`).

- [Pass] Plan lines 41–43, 48, 62 and 70 align the strict two-advisor parser, the consult-entry preimage and SHA, and the separate refused-close and post-`done` publication controls. The judge uses the supplied preimage for its append-only comparison and reviewed SHA (`utils/py/relay_drive.py:872–891,965–972`), and the consult runner has a single isolation creation point (`utils/py/consult.py:730–752`). Line 53 records the evidence-repair tradeoff and its stated source.

- [Pass] The plan keeps explicit short caps, scopes the new ceiling to opt-in callers, routes REAL to the builder before the reviewer, and preserves the fix-probe red control (lines 44, 46–48 and 54). The cap-1 GH-115 fixture has only a token handoff (`test/gh115-round-cap.sh:143–173`). Marathon still rejects an unmet fix probe before its gate or PR path (`utils/py/marathon_drive.py:2756–2775,2858–2865`).

Whole seeded plan reviewed. The pre-existing gate selector, transcript render commit and optional receipt writer account for the findings above. Graph coverage was checked on the nearest indexed checkout (generation 2026-11-26T04:31:47Z, head e22fd237). Trace was unavailable under the approval policy and the cited lines came from local source, including the partial Marathon shell ranges. [Unverified — needs clone run] No reviewer phase gate was specified, and the existing suites and proposed stub runs were not executed in this worktree.

Round cap reached. Handing off to Producer for disposition of the escalated plan.

VERDICT: FAIL
Basis: The plan leaves the default red-gate recovery unspecified, a transcript-only candidate defeats its raw empty-diff safeguard, and ordinary closeout has no configured handoff for the result and answer links.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
