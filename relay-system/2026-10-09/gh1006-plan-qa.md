# RELAY · GH-1006 bounded progress plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1006-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operational envelope: local macOS developer harness; opt-in finite observation plus a supervising-agent repair-to-PR procedure. No runtime autonomous repair controller, no new tests/gate machinery, no lock/containment/gate-semantic changes. Grade commensurate complexity.
Artifact under review: PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md (read in full). Also inspect current marathon.sh, terminal-result/heartbeat/approval portions of marathon_drive.py, relevant existing tests, consult synthesis and roadmap GH-1006 score.
Definition of Done: source-grounded surgical plan preserves all issue requirements, names held continuation dependencies, has one writer and finite lifecycle, honest progress and falsifiable checks, appropriate scope and rollback.

Questions:
1. Does each observation requirement map to an implementation step and a check, including run attribution, phase transitions, six checks, terminal/parent cancellation and missed deadlines?
2. Is the launcher-owned finite reader/context the least mechanism that preserves synchronous execution and original status? Is any plan claim unsupported by current source?
3. Does progress require matching driver approval/gate/reviewer evidence without trusting heartbeat or builder prose? Does it distinguish already-satisfied re-verification?
4. Is the skill procedure honest about the active caller, unanimous advisory vote, deadline/caps, repair isolation/QA, and held PR continuation (#1004/#752/descendants)?
5. Does the acceptance map retain the original 600x6 behavior while allowing explicit longer observation, without auto-merge, new gate machinery, or a second executor?
6. Is the 80/65/80/45 rating grounded and uncertainty/qualitative appeal interpretation retained?

Reviewer writes this relay only. Do not execute suites/pytest/fixtures in a linked worktree. Use current source and read-only inspection; graph generation September 1 is stale. Require source citations, disposition concrete missing requirements; do not ask for unrelated architecture refactors or extra gate frameworks. Verdict PASS/FAIL/PARKED with STATUS Approved only on PASS; record textual-only basis where appropriate.
- Artifact under review: PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-09
- Definition of Done: questions and acceptance map above.

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

Basis: The observation/repair-to-PR boundary is appropriately narrow, but two observation contracts need resolution before implementation: configurable scheduling versus the fixed six-check instructions, and signal cancellation while preserving foreground driver calls. This is plan QA, not a runtime failure verdict.

swept file: yes

Read the complete `PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md`, the complete launcher, the driver's terminal-result/heartbeat/approval paths, relevant existing suite sections, and the three consult conclusions. No additional defects identified in the plan outside the findings below; this is not an exhaustive audit of the entire driver. Applied SWE review rubric. Graph tools initially were not exposed, then became available: `XYZ-forge` coverage generation `2026-09-01T15:54:30Z` is stale for the driver/consult/tests; launcher coverage is partial at line 351. Current source, including reported relevant missed ranges, was read directly. No source/artifact edits, git commands, suites, pytest, or executable fixtures were run.

- **[Should] R1 — Make the finite schedule consistently parameterized and add the missing timing proofs.** Plan lines 153–155 permit count 1–144 and line 181 explicitly offers 600×18, but lines 165–170 mandate “six absolute monotonic deadlines” and “no seventh report”; lines 211 and 251 repeat the fixed-six criterion. An implementer cannot satisfy both literally. Use `N = effective check count`, retain six/seventh only as the default example, and explicitly map configurable count and missed-deadline behavior into Phase 3 and the acceptance table. Specify whether missed slots consume N and the expected output when resuming past the entire window; “clock-controlled checks” alone does not state that result.
  Observed input: `PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md:181` supplies `600×18`, conflicting with the unconditional instruction at `:165` and prohibition at `:170`.
  Affected scope: Opt-in observation scheduling and its manual acceptance checks only; phase execution and caps stay unchanged.
  Falsifier: In a disposable clone, default 600×6 ends at slot 6 with no slot 7; explicit 600×18 permits slot 7 and ends at 18 with no slot 19; phase transitions retain the same schedule; a clock jump beyond the window reports missed slots without fabricated snapshots or extending the window. A plan explicitly requiring these outcomes resolves the ambiguity.

- **[Should] R2 — Resolve the foreground-wait signal contract before promising immediate cancellation.** Plan lines 165–172 retain synchronous phase calls and promise catchable-signal cleanup; line 250 assigns immediate terminal/cancellation to the launcher EXIT lifecycle. Current `relay-automation/marathon.sh:310`–`:317` waits on foreground `bash "$DRIVE_BIN"`. Bash defers a trapped signal until that foreground command completes ([GNU Bash signal semantics](https://www.gnu.org/s/bash/manual/html_node/Signals.html)). Therefore adding launcher traps alone does not establish prompt cancellation when TERM targets only the launcher during a long phase. Parent-loss detection also cannot help while that launcher is still alive waiting. This consequence is inferred from current source and documented shell semantics, not a locally executed signal test. Add a concrete signal-target/latency contract and a mandatory disposable-macOS-clone check before choosing the cleanup mechanism; distinguish child exit, launcher-only signal, process-group signal, and actual parent disappearance. Preserve single-executor ordering and original status; do not quietly expand this into descendant repair/termination machinery.
  Observed input: Foreground driver invocation at `relay-automation/marathon.sh:313`/`:317`, together with the plan's `:166` catchable-signal promise and `:250` immediate EXIT-lifecycle acceptance row; the concrete counterexample to measure is TERM to the launcher PID while its driver remains running.
  Affected scope: Opt-in observer notification/reaping and the advertised cancellation latency, not continuation eligibility or driver containment.
  Falsifier: A disposable-clone run with a deliberately long phase shows the chosen design produces the terminal/cancellation report and reaps the observer within its stated bound after launcher-only TERM, without awaiting phase completion, starting another phase, or substituting observer status for the run status. If that cannot be shown while retaining the chosen boundary, explicitly disposition the limitation and revise the plan before claiming this guarantee.
  **[Unverified — needs clone run]** Signal delivery and teardown were not exercised in this reviewer worktree.

- **[Pass] Existing evidence supports the progress boundary.** Driver receipts expose execution/phase/lane/root, gate and reviewed-candidate fields (`utils/py/marathon_drive.py:235`–`:275`); success runs acceptance/gate checks, binds reviewer attestation, and labels `already-satisfied` (`:2663`–`:2737`). Plan lines 171–177 require those bindings and separate re-verification from new milestones. Existing receipt assertions are present at `test/gh280-jog-marathon-adapter.sh:274`–`:284`; their execution remains unverified here. Keep the reader non-authoritative and retain the proposed stale/foreign/heartbeat-only red controls.

- **[Pass] Repair and continuation scope remain honest.** Plan lines 184–197 require an active caller, launch authorization, one episode, shared UTC deadline, unanimous advisory recommendations, isolated repair, independent QA and publish-and-park. Lines 229–241 hold exact-revision continuation behind stopped descendants, preserved state/attempts, #752 and #1004; publication cannot enable it. This preserves the useful first delivery without claiming unattended recovery is complete. Keep these predicates in the implementation skill.

- **[Pass] Rating and uncertainty are retained.** `releases.sql:833` contains 80/65/80/45, NULL override and the active plan pointer; plan lines 51–58 explicitly label appeal as interpretation and incident trends as unknown. Read-only DB probe: `python3 -` with `sqlite3.connect(pathlib.Path("releases.db").resolve().as_uri()+"?mode=ro&immutable=1", uri=True)` and `SELECT gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr,doc_path FROM roadmap_items WHERE gh_number='1006'`; exit 0; decisive output: `[(1006, 80, 65, 80, 45, None, 'PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md')]`. Output was confined to `.relay-scratch/tmp/gh1006-plan-reading.txt`. No score change requested.

Handing off to Producer (`codex-author`) — disposition R1/R2 and update the plan, then return it for Round 2. STATUS remains Open; no approval or implementation authorization is implied.

### Round 2 · Producer · codex-author · 2026-10-09

**Decisions on proposals:**
- R1 — Implemented: N is the effective configured count; missed slots consume N; after entire-window suspension, slots 1..N-1 are marked missed and N is a current snapshot followed by window end. Verification explicitly covers N=6 and N=18.
- R2 — Modified: observation-enabled phases use one background child with an interruptible Bash wait, preserving serial order. Observer cancellation is <=1s on a responsive host; direct-child signals are forwarded but descendant ownership is reported unknown, not safe to re-fire. The normal foreground path remains unchanged.
**Did:** Revised Phase 2 mechanism and Phase 3 proof/acceptance map; removed unused scaffold placeholders from Setup.
**Verification:** ran controlled Bash signal probe in disposable full clone -> foreground TERM deferred 0.954s; interruptible wait 0.001s, both exit 143; full observer latency remains owed. Baseline launcher 35/35 and monitor 17/17 pass with identity intact. No production edits.
**Re-review this:** Plan Phase 2 steps 3–4, signal-design evidence, Phase 3 checks and acceptance table. Judge N parameterization and serial interruptible wait without asking for a descendant recovery controller.
**Commit:** recorded in producer commit.

### Reviewer · Round 2

VERDICT: FAIL

Basis: The seeded plan does not contain the revisions described in the Producer's Round 2 disposition. R1 and R2 remain open against this artifact; this is a textual plan-readiness verdict, not a failed runtime test or rejection of the proposed interruptible-wait approach.

swept file: yes

Read the entire 255-line plan, the launcher, the relevant driver receipt/heartbeat/approval sections, existing launcher/monitor/receipt assertions, consult conclusions and GH-1006 ledger row. Applied the SWE rubric and relay-xyz review scope. No additional plan defects identified beyond the unresolved Round 1 findings. Graph project/status/coverage tools were not exposed this turn; the plan records stale September 1 coverage, so this review used current source directly and makes no fresh graph-coverage claim. No git commands, suites, pytest, executable fixtures or artifact/source edits were performed.

- **[Should] R3 — Supply the revised artifact before closing R1/R2.** The Round 2 log says N parameterization, missed-slot accounting, interruptible wait, a one-second cancellation bound, signal-design evidence and expanded checks were added. The seeded plan still says “use six” at `PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md:165`, “no seventh report” at :169–170, “Before each synchronous phase call” at :171, and “Launcher EXIT lifecycle” at :250. The 600×18 example remains at :181; Phase 3 at :207–213 has neither explicit N=18 acceptance nor signal-target/latency cases. Cheapest fix: make the already-described revisions available in the committed review input, with the retained probe/provenance paths, then re-seed the next review. Do not add a new controller or unrelated work.
  Observed input: The exact seeded plan has SHA-256 `60cda8d8c725f5f957da9823400c01354a860e0bb481b158641fa07308ae792e`; the cited text conflicts with the Producer disposition. Current launcher `relay-automation/marathon.sh:310–317` still provides the foreground-call baseline relevant to R2.
  Affected scope: R1/R2's plan schedule, signal lifecycle, verification map and review-input availability only.
  Falsifier: A fresh seeded plan explicitly defines effective N, missed slots consuming N, N=6/N=18 outcomes, and the serial interruptible-wait contract with status preservation, signal targets, cancellation bound and required clone checks. Reviewing those actual bytes, rather than the disposition alone, would resolve this finding.

  Read-only probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` read the plan with `Path(...).read_bytes()`, computed `hashlib.sha256(b).hexdigest()`, and printed line matches for `("use six", "seventh report", "600×18", "synchronous phase call", "interruptible", "Signal-design", "<=1")`; exit **0**. Decisive output: `'use six': [(165, ...)]`, `'600×18': [(181, ...)]`, `'synchronous phase call': [(121, ...), (171, ...)]`, `'interruptible': []`, `'Signal-design': []`. The same probe's `Path("TESTS-RESULTS/2026-10-09+GH-1006").is_dir()` returned `False`. This proves the seeded-input mismatch; it does not establish whether revisions or evidence exist in the producer's separate checkout.

- **[Pass] The unaffected progress and recovery boundaries remain suitable.** Plan :159–177 binds reports to exact run/phase receipts and separates already-satisfied re-verification; the driver carries those identity/gate/reviewer fields at `utils/py/marathon_drive.py:235–275` and binds success at :2703–2737. Plan :184–197 retains an active caller, explicit authorization, shared deadline, unanimous advisory recommendations and isolated independent QA; :229–241 holds continuation behind revision, ownership, #752 and #1004 prerequisites. Retain these requirements.

- **[Pass] Rating interpretation remains honest.** Plan :48–55 preserves the qualitative appeal interpretation and unknown incident trend; `releases.sql:833` retains 80/65/80/45, NULL override and the active plan pointer.

- **[Unverified — needs clone run]** The Producer's reported signal timings and 35/35 plus 17/17 runs were not reproduced here, and their evidence is not available at the plan's named evidence directory in this seed. Full observer cancellation latency remains future implementation proof, as the Producer itself states.

Handing off to Producer (`codex-author`) — supply the revised plan and retained evidence in the next seeded input, then return for Round 3. STATUS remains Open; no implementation approval is implied.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
