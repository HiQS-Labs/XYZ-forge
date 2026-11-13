# RELAY · GH-1452 plan QA: merge-cleanup plan-ahead landing forecast
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1452-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (the PLAN, pre-implementation): `PROJECT/1-INBOX/GH-1452-MERGE-CLEANUP-PLAN-AHEAD.md`, whose `## Idea` section is the issue body for HiQS-Labs/XYZ-forge#1452 (Observed, Diagnosis, Plan, Blast radius, Acceptance, Verification, Non-goals, Risk, PRS proposal, Preflight Contract). No production code exists yet.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-13
- Operational envelope: a local, advisory conflict forecast printed by an operator CLI (`skills/2-daily/merge-cleanup`). Grade against the stated requirements and commensurate complexity; do NOT demand multi-tenant or enterprise machinery. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a request for a new test file or registry entry is itself a finding. Verification is existing suites plus retained manual checks under `TESTS-RESULTS/`.
- Source paths to validate against (read-only): `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (early checkpoint ~`:2000-2050`, `pin_selection` `:491`, `verify_selection` `:513`, dry-run decision block ~`:2229-2240`, B1 loop ~`:1500-1650`), `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (`pre_merge_ledger_gate` `:658`, `B1_EXCLUDED` ~`:543`, `LEDGER_VIEWS` `:37`), `skills/2-daily/merge-cleanup/scripts/attempt_record.py` (`MAX_REPAIRS` `:31`), `skills/2-daily/merge-cleanup/scripts/batch_record.py` (`set_landing_plan` `:310`), `skills/2-daily/merge-cleanup/scripts/toposort_prs.py`, `skills/2-daily/merge-cleanup/SKILL.md` (GH-1066 / GH-1158 sections, capability table).
- Prior review: a single-model (Codex) consult on the draft issue found 5 blockers, all dispositioned and folded into the plan before this review (issue comment 6861008436): early checkpoint is the authoritative decision point; the `forecast` flag value was dropped so the GH-1158 explicit decision stays unchanged; exact repair counts became a churn-risk band; the merge-tree continuation rule stops the cumulative fold at the first conflict; `pin_selection` stays the single atomic writer. agy did not answer (quota). Do not re-litigate those unless you have new evidence; challenge what remains.
- Definition of Done (for this plan review): the plan is grounded in the cited paths, extends the existing subsystem and writer, has falsifiable acceptance checks with real red controls, bounded blast radius and rollback, grounded PRS ratings with neutral appeal, and no unneeded machinery.

## Review instructions (Reviewer: read this before anything else)

**Step A — paraphrase first (GH-1414).** Before opening any source file or the dispositions above, read ONLY the `## Idea` section of the plan document and write, in your review block, 2-5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not** where a consequential expectation could be mistaken. Ground exclusions in the plan's own sections; distinguish excluded work, deferred work, unresolved choices and later authorization; label inference instead of inventing non-goals. State the input boundary ("read only the Idea section").

**Step B — source-backed validation.** Then read the cited source paths and answer, with `file:line` citations (label this part "source-backed"):

1. Are the Observed claims and every file:line citation in the plan grounded in the current tree (base `6c0c76bb5`)? Quote any that are wrong.
2. Is any requirement missing from Plan, Acceptance or Non-goals?
3. Does the plan extend the existing subsystem and writer (`toposort_prs`, `ledger_merge`, `attempt_record`, `batch_record`, the `pin_selection` writer) rather than add a parallel one? Is the single new function placed correctly?
4. What prevents an unchanged, unfixed tree from being reported as delivered, and where is the observed rejection? Does EACH Acceptance item name a real red control, and do the probes in the Preflight Contract hold on the unfixed tree?
5. Are blast radius, ordering, rollback and the manual verification cases sufficient and proportionate? Is the one-clone `git merge-tree` design (frozen base, `pull/<N>/head` fetches verified against pins, cumulative fold stopping at first conflict, `unknown` never `clean`) sound and commensurate for an advisory forecast?
6. Is writing the forecast inside `pin_selection` as one atomic snapshot safe, given the dry-run ordering and the existing lock helper? What exactly is serialized?
7. Are the PRS ratings (pri 55, sev 40, appeal 50, effort 40) grounded, and is appeal neutral?
8. Is anything over-engineered for an advisory CLI forecast? Name unneeded machinery to cut.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix. Every `[Blocker]` or `[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Include the literal line `swept file: yes` or `swept file: no`. Set a VERDICT (PASS, FAIL or PARKED) and Basis. Read-only probes only (no `validate.sh`, no `test/*.sh`, no pytest).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Input boundary for Step A: read only the plan's Idea/issue-body sections, before opening source; the scaffold's subsequent Why and Phase 0 headings were present in the same output.

**What this proposes**

Compute an advisory conflict forecast when a queue of at least three PRs is selected during a dry run. Simulate individual, pairwise and ordered cumulative merges in one disposable clone, classify paths and repair risk, then publish the forecast together with the selected pins and print a recommended explicit landing command.

**How the existing system works, per this document**

The document says the dry run writes head pins before ordering and prints generic direct/group guidance. Execution separately orders the pinned selection and requires an explicit decision and reason before mutation; B1 can repair selected ledger paths, but changed heads defer landing and each PR has two repair attempts.

**What it's not**

The Non-goals exclude a group executor, repair automation, new flags and exact repair/reconcile predictions. A forecast does not authorize execution: the operator still supplies the existing direct/group decision and reason. Reconcile-induced conflicts remain a stated blind spot; the recommendation is advice.

**Source-backed — Block pending the three Should corrections below.**

swept file: yes

Swept the entire capture, including frontmatter and the remaining scaffold. Findings below include pre-existing plan contradictions, not just its latest edits. This is plan QA, not implementation sign-off. Graph lookup used project `XYZ-forge`, generation `2026-09-01T15:54:30Z`; it points to a different checkout, returned no matching symbols, and coverage reported these five script paths as `freshness: not_tracked`. Therefore all material source claims below use this worktree's directly read source. No Git commands were run; the asserted base/HEAD/origin equivalence at plan line 75 was not independently established.

- [Should] **S1 — Make the annotation's writer and write-set achievable.** Plan lines 70 and 82 promise recording match/override in `batch_record.set_landing_plan` while reusing that function unchanged. Its entire implementation (`skills/2-daily/merge-cleanup/scripts/batch_record.py:310-319`) accepts only decision/reason/PRs and replaces the landing-plan dictionary with four fields. It has no forecast parameter; adding fields before calling it loses them. Cheapest fix: explicitly extend this existing mutator with optional forecast-comparison metadata, preserving old callers, and include `batch_record.py` in Blast radius, the truthful write-set and the Preflight artifacts. Alternatively specify a concrete existing-writer representation in the reason, if prose-only recording is sufficient; do not introduce another writer. Retain manual match/override/stale cases against persisted records, including a later save/resume.
  Observed input: plan line 70 requires match/override metadata; the current call `set_landing_plan({}, 'direct', 'operator override', [1,2,3])` produces only `decided_at`, `decision`, `prs`, `reason`.
  Affected scope: recording forecast comparisons for either direct or group decisions in the existing batch record.
  Falsifier: show an unchanged supported mutator invocation that durably records the specified comparison (with its forecast identity/staleness), then survives save/resume; expected result is the comparison remains recoverable without bypassing the owning mutator.
  Probe (in-memory only, no module import or real save), exit 0:
  ```python
  import ast
  from pathlib import Path
  source = Path('skills/2-daily/merge-cleanup/scripts/batch_record.py').read_text()
  f = next(n for n in ast.parse(source).body
           if isinstance(n, ast.FunctionDef) and n.name == 'set_landing_plan')
  ns = {'Dict': dict, 'Any': object, 'List': list,
        '_now': lambda: 'NOW', 'save': lambda rec: None}
  exec(compile(ast.Module(body=[f], type_ignores=[]), 'batch_record.py', 'exec'), ns)
  rec = {}
  ns['set_landing_plan'](rec, 'direct', 'operator override', [1,2,3])
  print(sorted(rec['landing_plan']))
  print([a.arg for a in f.args.args])
  ```
  Decisive output: `['decided_at', 'decision', 'prs', 'reason']`; parameters `['rec', 'decision', 'reason', 'prs']`. Executed within `python3 - <<'PY'` with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`.

- [Should] **S2 — Remove the unsupported lower bound on CI waits.** Plan line 67 says “one per PR plus one per conflicting PR.” The source waits only when checks are pending (`merge_cleanup.py:1660-1669`), accepts no-required-checks (`:554-555`), and defers repaired heads *before* waiting (`:1651-1656`). A head repair may cause a new CI run, but this is not a guaranteed additional CLI wait; the script can be rerun after checks are green. Cheapest fix: report an explicitly assumed head/check-cycle estimate, or omit this number and report repair deferrals/conflict counts. Do not change the executor or infer downstream CI triggers. Add a retained manual case with already-green/no-required checks to keep the wording honest.
  Observed input: `checks == 'ok'` for three disjoint pinned PRs at `merge_cleanup.py:1660`; the pending-only branch is skipped, so zero pending-check waits is compatible with the existing code, versus the plan's minimum of three.
  Affected scope: the forecast's numeric CI-cost wording for every queue, including prequalified heads and repositories with no required checks.
  Falsifier: demonstrate that the stated metric denotes actual mandatory waits and that three already-green/no-required-check PRs necessarily incur at least three such waits; otherwise expected wording must allow zero waits and label estimates/assumptions.

- [Should] **S3 — Close the failed-simulation recommendation hole.** Plan line 65 correctly returns `unknown` for command failure, but line 68 groups only members that *conflict* on code/unknown paths, three conflicting members, or a repeat repair conflict. A failed fetch has no conflict paths, so all three predicates may be false and “otherwise direct” applies. This contradicts Acceptance line 98 (“no recommendation of direct may rest on it”). Cheapest fix: explicitly give any unknown simulation/head/base result precedence over the direct recommendation, using group with an uncertainty reason or withholding advice; distinguish command failure from an unknown conflict *path*. Include the chosen outcome in the existing manual failure case.
  Observed input: the plan's own failed-fetch case (lines 65 and 98), with one unknown PR, empty detected conflict paths, zero detected conflicting members and zero prior repairs; line 68's literal rule falls through to direct.
  Affected scope: incomplete/error forecasts, including unavailable pairwise or cumulative results; conditional results after a known conflict should be named separately rather than silently treated as clean.
  Falsifier: a three-PR queue with one exhausted fetch failure and two clean PRs must not print an evidence-backed direct recommendation; a complete disjoint queue must still recommend direct.

- [Pass] **Existing ownership and checkpoint facts are grounded.** `merge_cleanup.py:491-510` is the selection writer, `:522` reads `prs`, `:2000-2050` is the early decision refusal, `:2174` pins before `:2182` orders, and `:2237-2240` prints generic guidance. `attempt_record.py:31` caps repairs at two; `merge_cleanup.py:1515-1534` gates the cap on a still-conflicting landing, and `:1651-1656` defers a changed head. `ledger_merge.py:37-39` owns the views/exclusions, `:543-553` applies exclusions and the shared policy. The placement beside the existing pre-merge gate is reasonable for advisory path classification. Keep these owners; the new helper should receive the existing orchestration/network callbacks or have the caller perform fetches, rather than import the main script back into `ledger_merge` (`merge_cleanup.py:56` already imports `ledger_merge`).

- [Pass] **One coherent snapshot is sufficient, with a precise lock scope.** Plan line 69's compute-first/one-replace approach is sound if pins, sequence, base and forecast all come from the same invocation's immutable inputs. `attempt_record.RecordLock` (`attempt_record.py:61-89`) locks `<record>.lock`; using the selection path serializes only publication to that selection file. It does not serialize network discovery, simulation, per-PR repair records, execution, or an operator reading the command. That is adequate for the stated advisory envelope: readers see a complete old or new snapshot, and execution still verifies heads. Keep the lock around temp-write/replace, avoid holding its default five-second timeout across simulation, and handle timeout explicitly. The old-reader compatibility follows from `verify_selection` reading only `prs` (`merge_cleanup.py:522`).

- [Pass] **The simulation design and rollback are proportionate at plan level.** The plan's “freeze one base SHA,” fetched-head equality, bounded calls, no checkout, ancestry-preserving clean fold and “conditional: not simulated after #N” (lines 65-66) avoid treating conflicted tree output as a resolved landing. Pairwise work is quadratic but reasonable for the observed six-PR queue, and the representative large-repo measurement at line 107 can expose unacceptable cost without a new benchmark system. `ledger_merge.py:547-573` shows why “potentially B1-eligible” must remain an advisory path category rather than proof that semantic repair succeeds. The Easy code rollback and explicit warning that it cannot undo later authorized landings (line 118) are appropriate. No new module, flag, registry or automated repair mechanism is justified; none needs to be added beyond the specified extension. Actual merge-tree and timing behavior: [Unverified — needs clone run].

- [Pass] **Preflight absence probes hold on this unfixed tree, but are admission evidence only.** Command: `python3 - <<'PY'` with `from pathlib import Path; r=Path('skills/2-daily/merge-cleanup'); print('def landing_forecast' not in (r/'scripts/ledger_merge.py').read_text()); print('landing-forecast' not in (r/'SKILL.md').read_text())`, exit 0, decisive output `True`, `True` (same membership checks were executed in the combined in-memory probe above). The scripts' Python text scan also printed `merge-tree script hits: []`. These absences establish missing implementation, not an observed behavioral rejection or a completed delivery. Acceptance lines 95-103 and retained manual outcomes must establish delivered behavior; a stub helper/capability row cannot qualify the change. No CLI, fixture, existing suite or full gate was run here.

- [Nit] **Tighten acceptance receipts and a few citations.** Line 96's “each edit releases.sql and CHANGELOG.md” must specify genuinely conflicting differing edits (same affected content), since shared paths alone do not establish conflicts (`SKILL.md:275-278`). Several red controls are failure-input checks rather than witnessed red results; require the retained checks to actually reject deliberately wrong output (not merely run those inputs). In particular retain checks for override/staleness as well as refusal, and let existing unchanged regression coverage stand without a new mutation. The actual repaired-head condition is `merge_cleanup.py:1651`, and the real per-PR merge simulation begins at `:1503` in `prepare_landing_clone`, not at the semantic `pre_merge_ledger_gate` (`ledger_merge.py:658-687`). Correct those references; other quoted source locations inspected are grounded. The downstream incident remains reporter evidence, not independently verified here. Frontmatter goal/Phase 0 TODOs are unstarted-capture scaffold, not implementation proof.

- [Unverified — no citation] **PRS appeal is neutral and the other scores are defensible estimates.** Plan lines 122-125 explicitly ground pri 55 in a lost planning cycle, sev 40 in wasted time without data loss, appeal 50 in “neutral default,” and effort 40 in simulation plus concurrent snapshot handling. Preserve those as provisional judgments. The “likely parked PR” severity rationale should be qualified by line 46's admission that parking was never demonstrated; that claim must not become measured impact.

VERDICT: FAIL

Basis: The core advisory design extends the right subsystem and preserves explicit operator authority, but its recording write-set, CI wait claim and failure-to-recommendation mapping need the bounded corrections S1-S3 before implementation. No new test machinery is requested. The plan's proposed runtime/manual controls remain [Unverified — needs clone run]; they were not executed in this reviewer worktree.

Handing off to Producer (claude-a) — go to the Producer window and say 'take your turn'.

### Producer · Round 1 (claude-a)

Plan revised in `PROJECT/1-INBOX/GH-1452-MERGE-CLEANUP-PLAN-AHEAD.md` (new section "Plan QA revisions"; plan lines edited in place). Every finding was checked against the tree before it was accepted.

- **S1 — Implemented.** `batch_record.set_landing_plan` (`batch_record.py:310-319`) keeps only decision, reason, PRs and time, as you showed. The plan now extends that existing mutator with one optional forecast-comparison argument (forecast identity, match, override, stale), leaving old callers unchanged. `batch_record.py` is added to the Blast radius table, the truthful write-set (now four files) and the Preflight artifacts, and a new Acceptance item requires the comparison to survive a save and reload with a witnessed red control.
- **S2 — Implemented.** The CI-wait lower bound is removed. The forecast now reports how many PRs a B1 repair would defer in the run that repairs them (`merge_cleanup.py:1651`) and gives no CI-wait count, since waits happen only while required checks are pending (`:1660-1669`).
- **S3 — Implemented.** Any `unknown` result (failed fetch or merge command, missing object, head or base mismatch, timeout) now takes precedence and withholds the recommendation ("none: forecast incomplete, #N unknown"). A PR that is "conditional" after an earlier conflict is a known conflict and is named separately. The failed-fetch Acceptance item now requires that a three-PR queue with one failed fetch and two clean PRs does not recommend `direct`, while a complete disjoint queue still does.
- **[Pass] callback shape — Implemented.** `landing_forecast` receives a prepared clone, the base SHA and verified heads from `merge_cleanup.py`, so `ledger_merge` never imports the main script back.
- **[Pass] lock scope — Implemented.** The plan now says the `RecordLock` is held only around the temp-write and replace, never across fetch or simulation, and a lock timeout is reported as a failure to publish.
- **[Nit] — Implemented.** The repaired-head condition is cited at `:1651`; the per-PR merge simulation is cited at `prepare_landing_clone` (`:1503`); the conflict fixture requires different edits to the same lines; every red control must show the deliberately wrong output being rejected; the severity rationale no longer treats parking as measured (it says possible and hand-estimated). The base-equality claim at plan line 75 now names its command (`git diff --quiet origin/development -- skills/2-daily/merge-cleanup`, exit 0 in the primary checkout).
- **[Unverified] PRS — Modified.** Scores kept as provisional judgments; only the severity wording changed, as above.

swept file: n/a (Producer)

Handing off to Reviewer (codex) for round 2. Re-check S1-S3 and the nits only, plus anything these edits newly broke; do not reopen settled points.

### Reviewer · Round 2

Input boundary for Step A: the plan's Idea/issue-body sections (Observed through Preflight Contract), read before opening source this turn. `## Idea` itself is an empty heading; its sibling headings hold the issue body. The full capture was subsequently swept, including revisions and scaffold. Earlier relay history was necessarily read to establish this turn and its scope.

**What this proposes**

Provide a planning-time advisory forecast for a selected queue of at least three PRs. A disposable clone supplies individual, pairwise and ordered cumulative merge evidence; one snapshot publishes that evidence with its pins, sequence and base. Incomplete evidence withholds advice, and execution records how the explicit operator decision compares with the forecast.

**How the existing system works, per this document**

The dry run currently pins heads before ordering and prints generic direct/group guidance. Execution independently verifies pins and requires an explicit decision and reason at an early checkpoint. B1 has a bounded repair path and defers a repaired head; the current batch-record mutator records only decision, reason, PRs and time.

**What it's not**

The Non-goals exclude a group executor, automatic repairs, exact repair/reconcile predictions and new flags. Recommendation does not authorize execution. Reconcile-induced conflicts remain an acknowledged blind spot, and actual runtime verification is later work in a disposable full clone.

**Source-backed — approve the plan for implementation.**

swept file: yes

Swept all 185 lines of the capture, not merely its revision summary. No additional blocking defect was found in that artifact; settled Round 1 findings remain settled except for the corrections checked below. This is plan approval only. Graph discovery used `XYZ-forge`; its root is another checkout, generation `2026-09-01T15:54:30Z`, symbol lookup returned zero matches with no further page, and coverage reports all five candidate scripts `freshness: not_tracked`. Material source checks therefore use this worktree's source. No Git command was run, so the reported base/origin equality remains author evidence.

- [Pass] **S1 resolved without a second writer.** Plan step 6 explicitly extends `set_landing_plan` with an optional comparison argument; Blast radius, truthful write-set and Preflight artifacts now include `batch_record.py`. Acceptance requires old-call compatibility and persistence after reload. The present mutator owns replacement and sets `_landing_plan_touched` (`skills/2-daily/merge-cleanup/scripts/batch_record.py:310-319`); the existing save path preserves that intent under its lock (`:186-220`). This is the appropriate extension point. Concrete action: implement the optional metadata there and retain the planned old-caller, override, stale and reload receipts.

- [Pass] **S2 resolved with a conditional, defensible metric.** Plan step 3 now says it “gives no CI-wait count” and describes deferral in the run that repairs a head. This matches the pin-mismatch deferral before the pending-only wait (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1651-1669`). The severity rationale explicitly says parking was estimated and never demonstrated (plan PRS proposal). Keep the count conditional on a repair occurring, as written; do not turn text conflicts into a promise that B1 can repair them.

- [Pass] **S3 resolved by explicit precedence.** Plan step 4 says “any `unknown` result ... takes precedence and withholds the recommendation”; the failed-fetch Acceptance item requires no `direct` recommendation for one unknown plus two clean members, and preserves `direct` for complete disjoint input. Step 2 still stops the cumulative fold at its first conflict. These statements close the empty-path fall-through identified last round. Implement that precedence before evaluating the ordinary direct/group rule; conditional later members must stay labelled as not simulated.

- [Pass] **The bounded design and publication contract remain coherent.** Plan steps 1 and 5 put network preparation in the caller, avoid a circular import, and hold `RecordLock` only for publication, reporting lock timeout. The helper locks `<record>.lock`, not simulation or the queue (`skills/2-daily/merge-cleanup/scripts/attempt_record.py:61-89`). `pin_selection` remains the sole selection writer (`merge_cleanup.py:491-510`); the old reader accesses only `prs` (`:522`). Serialization therefore covers publishing one complete selection snapshot, while execution still verifies its own pins. The specified frozen base, verified fetched heads and clean-only ancestry-preserving fold remain proportionate for advisory output; no extra module, gate or executor is needed. Preserve the existing semantic handoff boundary (`ledger_merge.py:543-573`), since “potentially B1-eligible” is not proof of resolvability.

- [Pass] **The revised evidence requirements distinguish admission from delivery.** The capture's revision section requires that retained checks show deliberately wrong output being rejected, not just that an input ran (plan line 171). The Acceptance section has ten items, now including persisted comparison metadata, conflicting edits to the same lines, unknown-result precedence and mode/concurrency/refusal controls. Existing unchanged suites need no new mutation. The Preflight absence checks remain admission probes; neither a helper name nor a capability row proves delivered behavior. Keep the planned manual receipts and `provenance.jsonl`; do not add tests or runners. The Easy rollback and explicit limit that reverting cannot undo a later operator-authorized landing remain adequate (Risk and rollback).

  Narrow in-memory probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` using `ast.parse` to extract only the current `set_landing_plan`, executing it with `save=lambda rec: None`, and checking source membership with `Path.read_text`. Exit 0; decisive output:
  ```text
  legacy keys: ['decided_at', 'decision', 'prs', 'reason']
  forecast helper absent: True
  capability absent: True
  capture lines: 185 acceptance items: 10
  ```
  The executable probe body performed `r={}; ns['set_landing_plan'](r,'direct','override',[1,2,3])` and printed `sorted(r['landing_plan'])`; absence expressions were `'def landing_forecast' not in ledger_source` and `'landing-forecast' not in skill_source`. No module import, save, CLI, fixture or suite was executed. The earlier source-display command exited 1 after requesting lines past the end of `ledger_merge.py`; its missing range was subsequently read with a length-bounded display, exit 0. That display error is not behavioral evidence.

- [Unverified — no citation] **PRS remains provisional and neutral.** The PRS proposal explicitly assigns appeal 50 as “neutral default”; pri 55 is justified by a lost planning cycle, sev 40 by wasted time without demonstrated data loss or parking, and effort 40 by simulation/snapshot/error-handling work. Those are reasonable planning judgments, not measured runtime impact. Keep that qualification.

Actual merge-tree behavior, concurrent publication, refusal invariants, save/reload and suite outcomes: [Unverified — needs clone run]. No implementation is present; none of those future results is being certified here.

VERDICT: PASS

Basis: S1-S3 and the requested citation/evidence nits are addressed in the plan, with existing ownership preserved and no new blocking contradiction found. The plan is ready for implementation; completion still requires its retained manual checks and existing gates in a disposable full clone.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-13T18:17:05Z
task: RELAY-gh1452-plan-qa
reviewer: codex
status: Approved
reviewed-head: 0695451b19dc2dce7fd6f66ce550a7124c3166f8
added-range: 26161+7752
added-sha256: 7752d8e0481eb2bb8995117be4a4020daf96e5fa1a765bf8fe1dbbb2726580e5
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
