# RELAY · GH-1476 Day 1 admission plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
6. **Manual relay: commit only the relay file** (`relay(gh1476-day1-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1476-RAW-TASK-PREPARATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-25
- Definition of Done: Review the Day 1 OL-10 section of the artifact against #1476 and #1609 scope: actual ready reaches worker; current human/dependency holds and stale acceptance or reviewed-source must not; refresh preserves queue identity, history and native budget. Before source or supplementary requirements, write 2–5 sentences each under What this proposes and How the existing system works, per this document, plus What it is not; distinguish missing boundaries. Then inspect source and retained replay logs for a source-backed assessment. Determine if a concrete implementation plan is actually specified, including a verifiable reviewed-source identity, authority, backward compatibility, offline behavior, applicable holds, and falsifiable checks. Identify what rejects an unchanged candidate and whether the named record is machine-verifiable. Grade within this repo's local-first developer CLI threat model and commensurate complexity; no extra scheduler, database, new tests, attempt reset, merge or production dispatch. Cite paths/lines and give concrete alternatives; unresolved requirements block approval. Limit writes to this relay thread.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: yes

**What this proposes.** Day 1 adds a current-preparation check to Jog → Preflight → Marathon. Reviewed ready work should reach the worker, while current holds or stale reviewed inputs should park before a native attempt. Recovery should use the same queue row, retain its execution history and spend only the remaining native allowance.

**How the existing system works.** Jog leases a pending row, appends an execution record and parks on a Preflight refusal. Preflight checks issue body/state, acceptance fidelity and contract probes. Conveyor records review and holds, Kickstart interprets issues during queue building, and Marathon/RTL owns the native cap.

**What it is not.** This is Day 1 setup and repair under #1476/#1609. Scope excludes a new scheduler, readiness database, suite, attempt reset, merge, and live dispatch.

VERDICT: FAIL
Basis: The whole canonical plan was read. Its Day 1 section is a problem statement and replay outline, with the record, authority, compatibility and dispatch checks explicitly deferred. Both held inputs reached the worker in retained evidence. The declared artifact seed is also absent, so this turn cannot attest to a seeded plan.

- **[Blocker] Restore the exact review input for the next round.** Observed input: `nl -ba .relay-artifacts/GH-1476-RAW-TASK-PREPARATION.md` → exit 1, “No such file or directory,” contrary to Setup. `ls -lab .relay-artifacts` → exit 0, only `gh182-claim-guards.md` as a file. `cmp PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1609-flywheel-day-1-2026-11-25/PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md"` → exit 0, no differences. I used that canonical copy for substantive review. Affected scope: attribution of Day 1 QA to the independently reviewed bytes. Falsifier: invoke the driver with the advertised artifact argument and show the seeded file is byte-identical to the exact revised plan before review.

- **[Blocker] Specify the reviewed-source record and what rejects an unchanged candidate.** Observed input: `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md:165–177,189–196` defers representation and verification despite requiring bound review at lines 142–145. The Conveyor marker at `skills/1-hourly/conveyor/SKILL.md:105–109` is a prose summary and a discoverability label. The source replay changes `src/feature.js` without supplying any review binding (`TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:197–204`). Affected scope: an explicitly preparation-managed lane, including the same queue candidate after its reviewed bytes change. Falsifier: a trusted, matching record reaches the worker once. Without changing the row, issue acceptance or contract, change a bound source file and require zero calls with a stale-review reason. Give the existing marker one versioned machine-readable payload, or reuse the existing relay attestation if it is available and verifiable at admission. Specify the exact qualified issue/capture, review and evaluated revision, bounded relevant source/contract paths and compared object IDs or digests, plus an existing trusted writer or independently verifiable review record bound to the exact reviewed head. A claimed SHA inside a comment and the ready label cannot establish that authority. Define missing, malformed, unauthorized and mismatched outcomes. Show which tree the digest describes and which tree the worker starts from. Preflight records evaluated-ref commit in `utils/py/swarm_preflight.py:394–395`; the invocation passes a ref name at :1265 and Marathon can switch to an existing lane branch at `utils/py/marathon_drive.py:3397–3405`. Use an existing stable handoff or a bounded comparison before reservation if these trees can differ, with a matching-input case that also allows unrelated changes.

- **[Blocker] Specify hold precedence and the compatibility/offline decision at the admission seam.** Observed input: `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:189–205` supplies the explicit owner hold and GH-902 dependency hold. `rg -n 'jog exit|^worker edge calls' TESTS-RESULTS/2026-11-25+GH-1476-day1/{ready-clean,held-clean,dependency,stale,source}.log` → exit 0. Each Jog exit was 0, and the sentinel was present in ready, both held and source; stale acceptance had zero (`held-clean.log:31–32`, `dependency.log:31–32`, `stale.log:8–12` in that directory). Preflight requests only body/state/close time and tolerates unknown fetches (`utils/py/swarm_preflight.py:707–746,1740–1744`); Kickstart checks authenticated operator decisions and conditions on open refs in `skills/1-hourly/kickstart/scripts/build_queue.py:153–201,298–317`. The plan leaves these inputs and outcomes to later QA (:179–193). Affected scope: managed preparations, explicit holds on direct/legacy candidates, and existing local/offline callers. Falsifier: give managed and legacy inputs independently observable outcomes for no receipt, lookup unavailable vs known absent, supported hold, wrong-author release and authorized release with dependency verified resolved. Keep the native explicit hold and structured dependency cases separate; the existing “unresolved dependency GH-902” fixture uses the same HELD marker as the human case and never proves dependency resolution. Specify a durable existing signal selecting managed enforcement so an unavailable lookup cannot downgrade a managed lane to legacy, keep legitimate direct/local flows on their existing policy, reuse the supported hold grammar and authorized owner rule, and keep any current independent hold blocking after another is released. Reuse the Jog refusal path at `utils/py/jog_run.py:652–659`; exit 4 instead projects completed at :648–651.

- **[Should] Make the retained controls measure the promised properties.** Observed input: `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:106,229,243` overwrites one sentinel file, then reports presence as exactly one call. Lines 233–234 compare native bytes immediately after refusal, while :241–242 report execution IDs/statuses and print native lines after refresh. That cannot prove exact counts or byte equality after refresh as requested at plan :197–205. Affected scope: the planned bounded clone replay, including false duplicate calls and rewritten history. Falsifier: simulate two sentinel invocations and alteration to one retained byte; the revised checks both fail, while a single call with an unchanged native prefix and preserved prior execution records passes. Use one append per sentinel call, snapshot and compare full old execution records and the native prefix through refresh, then assert exactly one appended native line. Name existing `jog retry` as the same-row recovery verb (`utils/py/releases_app.py:4954–4973`); distinguish Jog lease count at :5095–5098 from native reservation at `utils/py/marathon_drive.py:1292–1307,3483–3491`. Use the actual lane key for the exhausted-cap control and assert zero sentinel calls and identical native bytes. Name the pinned clone-local replay procedure and retire the retained script's author-machine setup path (`control.txt:12`) before treating it as a reusable command.

- **[Pass] Existing acceptance and refresh evidence is directionally sound.** The stale acceptance input parked with Preflight exit 5 before the sentinel (`TESTS-RESULTS/2026-11-25+GH-1476-day1/stale.log:8–12`). The budget replay records the same global ID at :12 and :44, retained refusal plus new execution at :45, and the seeded native line followed by another at :46–49 of `TESTS-RESULTS/2026-11-25+GH-1476-day1/refresh-budget.log`. This is a baseline acceptance-only correction with synthetic prior history. For OL-10, replay a true stale-review refresh on that same recovery path with an updated authorized record and the checks above.

- **[Nit] Bring the current status row up to date.** Plan :5 and :26 still describe earlier publication as pending, while :126–138 and [#1476](https://github.com/HiQS-Labs/XYZ-forge/issues/1476) record later OL-09 QA/publication. Preserve the history and identify the current Day 1 plan hold in the status row. [Day 1 scope](https://github.com/HiQS-Labs/XYZ-forge/issues/1609)

The graph was indexed for the main checkout, with no exact worktree index. Graph discovery and coverage informed the lookup; trace calls were unavailable under the approval policy, so material citations use the local source. No runtime fixtures or phase gate ran during this review. Handing off to Producer to seed the exact revised plan and resolve the admission and replay findings.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
