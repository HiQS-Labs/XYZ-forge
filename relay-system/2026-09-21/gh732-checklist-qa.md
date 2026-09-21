# RELAY · GH-732 CI/CD optimizations checklist — accuracy and grounding QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
-->

NEXT: Reviewer
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh732-checklist-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-732-MID-SEPTEMBER-CICD-OPTIMIZATIONS.md` (verbatim capture of GitHub issue #732's body — the checklist under review). Sources to check it against: `validate.sh`, `utils/ci-route.sh`, `githooks/pre-push`, `.github/workflows/ci.yml`, `.github/workflows/wave-reconcile.yml`, `utils/py/wave_reconcile.py`, `utils/py/_marathon_plan.py`, `skills/merge-cleanup/scripts/merge_cleanup.py`, `test/gh35-test-tiers.sh`, `test/gh251-validate-pytest-skip.sh`, `test/gh425-gate-provenance-pr.sh`, `AGENTS.md`, `ROUTER.md`, `SOP.md`, `PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: every checklist item's factual premise is either confirmed against the cited source line (or corrected with the right citation), or marked as an operator observation that the source cannot confirm; no item duplicates an open issue without saying so; the carry-over from #496 is accurate (landed vs not landed); the proposed action per item is proportionate (no new subsystem) and its acceptance is falsifiable.  [Unverified — no citation]

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — QA packet: is the checklist accurate and grounded?

VERDICT: PARKED
Basis: requesting independent verification of a checklist before anyone acts on it.

**Operational envelope.** A GitHub issue checklist for small, independent CI/CD optimisations in this repo's local pre-push gate and reconciliation loop. Grade facts and proportionality; do not propose new machinery. Timings in the table are the Producer's observations from six gated pushes on one 12-core host this week (2026-09-17..21) and cannot be re-run in this turn — grade their *plausibility* against the gate's mechanics, not their exact values.

**Read the artifact in full, then verify each item. For every item answer: (a) is the cited line/behaviour real (quote it), (b) is the diagnosis correct, (c) is the proposed action the smallest one, (d) is the acceptance falsifiable, (e) does an open issue already own it.** Measure read-only where useful (`--help`, `grep -n`, reading the hook/workflow); do not execute the gate, tests, or harness entrypoints.

Specific questions:
1. **Timing claims in docs:** confirm `AGENTS.md:180` says ~4–6 min and `ROUTER.md:63/:89-90` say ~16 min / 3-minute. Is "refresh the numbers or point at the gate's own `GREEN in Ns` line" the right fix?
2. **Per-suite durations:** does `validate.sh` really print no per-suite wall-clock (check the result loop near `:1309-1330` and the summary renderer)? If durations exist somewhere (a results file, `TESTS-RESULTS`), say where and correct the item.
3. **Toolchain preflight:** does `gh251-validate-pytest-skip.sh` establish pytest-absence as a named skip, and does `gh425-gate-provenance-pr.sh` still call `python3 -m pytest` in a way that hard-fails when pytest is missing? Is a 2-second preflight in `validate.sh` (import check + `php -v`) the smallest fix, or does an existing mechanism (e.g. the GH-251 skip path) just need extending? Note: `php` is used by `gh268-relay-cue-and-target-checks.sh` via target-checks — is that the right suite name?
4. **Re-run ladder:** confirm `vp_rerun_alone` (`validate.sh:1325`) re-runs pooled failures alone and serially. Is "print time spent in re-runs; consider a 2-wide re-run pool or short-circuit on a reproduced toolchain error" proportionate, or does it weaken GH-528's guarantee?
5. **Tier-2 width:** at `validate.sh:994-996` is `PARALLEL_JOBS=2` applied *before* or *after* the `--burst`/`XYZ_VALIDATE_MAX_JOBS` levers (precedence comment `:684`)? State precisely whether the levers are ignored for tier 2.
6. **Ledger-row routing:** does `ci-route.sh:458` (`tier=2`) plus the `releases` mapping at `:38` mean an intake-only `releases.sql/.db` delta always runs the full releases subsystem? Is the "evaluate" framing honest, or is the answer already knowable from the code?
7. **gh35 nice-nesting:** read the assertion in `test/gh35-test-tiers.sh` around the "ran 10 below its caller" message. Does it compute `caller+10` without clamping at 20? Is `min(caller+10, 20)` the right fix?
8. **Contention rule / docs-vs-code split:** are these already stated somewhere (ROUTER, SOP §4, AGENTS)? If so the items are duplicates — say so.
9. **Hosted `--qualify`:** confirm `wave-reconcile.yml` runs `--pr N --catch-up --gate --qualify` on `pull_request: closed` and that `--qualify` is the full sequential suite; is the "decide in #591" framing right, or does this belong in its own item?
10. **Carry-over from #496:** verify each landed/not-landed claim: #548/#553/#580 merged; `ci.yml:533-536` frozen-twin guard under `vendored-smoke` on PRs; `ci-route.sh:38/:42` mappings; `githooks/pre-push:34-35/:49` lever diagnostics; `run_pre_merge` at `wave_reconcile.py:1700` validating Lessons Learned (`:1789`); `merge_cleanup.py` **not** invoking `--pre-merge`; `releases.db` still tracked; `GH-496-SHARPEN-CICD.md` `updated: 2026-09-10` with 3 unticked items. Is "wire `--pre-merge` into E.6" the smallest fix for the post-merge Lessons-Learned failures, and is it correctly attributed to #496 Phase 2?
11. **Duplicates:** for each cross-ref (#382, #30, #730, #223, #591, #674, #722) is the boundary drawn correctly — nothing in the checklist re-asks what those issues own?
12. **Anything missing** that the same week's evidence clearly supports and the list omits? Anything listed that the evidence does *not* support?

Output: one graded finding per checklist item (`[Blocker]/[Should]/[Nit]/[Pass]`) with the citation, `swept file: yes|no`, VERDICT with Basis. Findings only — do not edit the artifact.

### Reviewer R1 — whole-checklist grounding review

VERDICT: FAIL
Basis: several proposed fixes already exist or rest on superseded behavior; the checklist needs factual corrections before implementation. Review is of the seeded source, not an attestation of historical development SHA 39bb1392. No source edits, git commands, gates, tests, or executable fixtures were run.
swept file: yes

The entire capture, including frontmatter, carry-over, acceptance and trailing scaffolding, was reviewed. Pre-existing defects are included below. Timing/incident anecdotes remain operator observations, not independently reproduced evidence. Reversibility of this review: Easy; only this relay changes. Applied relay-xyz, SWE and debug-mantra review guidance within the user's narrower turn restrictions.

**Checklist findings (artifact line numbers refer to PROJECT/1-INBOX/GH-732-MID-SEPTEMBER-CICD-OPTIMIZATIONS.md):**

- [Pass] **1 — timing docs (line 71).** The cited numbers exist at `AGENTS.md:180`, `ROUTER.md:63` and `ROUTER.md:90`. Prefer the existing measured output over another evergreen estimate: `githooks/pre-push:262/:279/:296` prints the docs/tier-2/full `GREEN in ...s` lines. These are hook timings, not validate's own summary. Keep the six-run table explicitly dated operator observations; historical plausibility follows from the serial retry mechanism, not proof of those exact times. Acceptance: either remove static promises and cite those outputs, or retain a same-week receipt with host/width. Also inspect the same stale timing prose at `githooks/pre-push:10` when updating docs.

- [Should] **2 — per-suite durations (line 72): reuse existing telemetry.** Console presentation is missing, but collection already exists: `validate.sh:1258` calls `rt_suite`, `test/lib/runner-telemetry.sh:146` emits `duration_ms`, and `validate.sh:1518` prints the retained file path. Storage defaults to `.tick/telemetry` (`test/lib/runner-telemetry.sh:69`); committed examples exist under `TESTS-RESULTS/2026-09-01+GH-365/campaign/`. Rewrite as a summary-rendering extension of GH-365, not a new timing facility or prerequisite to measuring anything.
  Observed input: existing suite JSONL has `started_ms`, `ended_ms`, `duration_ms`, and retry lane records.
  Affected scope: item 2 and Phase 5's assertion that new timings are prerequisite.
  Falsifier: an inspected nonempty current receipt lacking suite durations would justify additional collection; current emitter already supplies them. Acceptance should distinguish initial attempts from retries and sum each once.

- [Should] **3 — toolchain (line 73): gh425 premise is obsolete; don't impose optional dependencies globally.** `test/gh425-gate-provenance-pr.sh:5/:13/:427` uses Python's `unittest`, not pytest. `validate.sh:1409` and `test/gh251-validate-pytest-skip.sh:56` explicitly skip the Python layer when pytest is absent. PHP attribution to `gh268-relay-cue-and-target-checks.sh:97` is the right suite; its absent-PHP case is also deliberately skipped at line 107. Rewrite incident details as historical observations, identify still-affected consumers, and prefer targeted diagnostics/consistent existing skips over an unconditional top-level dependency gate. Pick one policy before acceptance; preserve non-qualifying status for omitted coverage.
  Observed input: gh425 now imports `unittest`; the capture instead says its own `python3 -m pytest` fails.
  Affected scope: item 3 and the gh425-based red control at line 97; docs-only and unrelated tier-2 runs must not acquire these dependencies accidentally.
  Falsifier: current gh425 executing pytest would refute this correction. Static probe `python3` with `Path('test/gh425-gate-provenance-pr.sh').read_text().count('pytest')` returned `0` (exit 0). Runtime dependency failure attribution is [Unverified — needs clone run].

- [Should] **4 — retries (line 74): retain solo verdicts.** `validate.sh:1301` explicitly requires the pool drained and lock lane finished; `vp_rerun_alone` at line 1325 runs synchronously. A second 2-wide pool reintroduces competing suites and cannot establish the same guarantee. Limit this item to displaying existing retry durations first; any early abort must produce incomplete/failed evidence, never a qualifying green. The retry count is bounded by the selected suites; elapsed cost is the concern.
  Observed input: the proposed “2-wide pool” contradicts the current “Every failure is RE-RUN SEQUENTIALLY” contract.
  Affected scope: failed/missing pooled results and their final classification.
  Falsifier: a reproduced shared-resource pair failing together but passing alone must still receive solo verdicts; a candidate calling two-wide results authoritative fails that control. Actual pair execution is [Unverified — needs clone run].

- [Should] **5 — tier-2 width (line 75): remove the requested implementation.** `XYZ_VALIDATE_MAX_JOBS` is applied at `validate.sh:932`; the fallback block requires empty `PARALLEL_JOBS` at line 975, and `BURST` is handled at line 980, before tier 2 at line 994. Explicit widths already win (subject to xargs capability); tier 2 is a default, not a pin. Rewrite as already supported usage/documentation.
  Observed input: `--burst` reaches the earlier BURST branch; MAX_JOBS sets the value before the empty-value guard.
  Affected scope: tier-2 width claims only; preserve the default and capability fallback.
  Falsifier: a disposable-clone mode probe showing MAX_JOBS=4 or --burst ignored on a capable 12-core host would reopen this item. No validate entrypoint was executed here.

- [Should] **6 — ledger routing (line 76): current route is known; reduced coverage remains a proposal.** Mapping is path-based (`utils/ci-route.sh:38/:458`), with no row-content classifier. Read-only probe `printf '%s\n' docs/example.md releases.sql releases.db | bash utils/ci-route.sh push` returned exit 0, `full_required=false`, `tier=2`, `tier2_subsystems=releases`, 23 registered shell suites. Do not present the historical “26-suite” run as the current registry count. Keep “evaluate” for whether reducing coverage is safe, not for what the router currently does. Cheapest default is retain routing; a row classifier is additional mechanism and needs evidence.
  Observed input: docs plus releases.sql/releases.db selects the whole releases registry.
  Affected scope: any proposed intake-only exception.
  Falsifier: schema changes, dropped/modified rows, malformed dumps, unrelated code and empty/unreadable diffs must retain existing fail-closed coverage; a valid additive row must still pass ledger consistency. Record go/no-go evidence before changing selection.

- [Should] **7 — nice nesting (line 77): already addressed.** `test/gh35-test-tiers.sh:261` names GH-648; lines 267–273 require caller+10 only for caller nice <=5, otherwise worker >= caller. A caller at 15 no longer expects 25. Mark superseded; do not replace the current assertion with an unmeasured platform clamp or unconditional skip.
  Observed input: caller=15 selects the existing `worker never outranks a reniced caller` assertion.
  Affected scope: the stale fix request, not the existing scheduler behavior.
  Falsifier: evidence that this current branch still expects 25 for caller=15 would reopen it. Full nested behavior is [Unverified — needs clone run].

- [Nit] **8 — contention guidance (line 78).** `validate.sh:697` sets `nice -n 10`; `ROUTER.md:69/:92` already documents burst/unattended use. The inspected command rails and SOP §4 do not already state a universal one-gate-at-a-time rule. A short recommendation is proportionate, but “pollers materially lengthen” is an operator observation, not derivable from nice. Reuse the existing burst explanation; do not claim global cross-clone serialization exists or is needed without measurements. Acceptance: one concise recommendation and a pointer to existing controls.

- [Should] **9 — split pushes (line 79): mixed docs/code does not imply tier 3.** Read-only probe `printf '%s\n' docs/example.md utils/py/releases_app.py | bash utils/ci-route.sh push` returned exit 0, `full_required=false`, `tier=2`, `tier2_subsystems=releases` (23 shell suites). Docs do not disqualify mapped code at `utils/ci-route.sh:365`. Rewrite around genuinely independent docs follow-ups and the pushed range; splitting one mixed change adds a docs gate without necessarily reducing its code gate. The artifact itself assigns push cadence to #30, so make this a linked recommendation there rather than duplicate implementation.
  Observed input: docs/example.md plus utils/py/releases_app.py routes tier 2.
  Affected scope: mixed-push premise and proposed SOP default.
  Falsifier: mapped code plus docs must remain tier 2, kernel code plus docs tier 3, docs-only tier 1; a rewrite claiming all mixed pushes are tier 3 fails this matrix.

- [Should] **10 — hosted qualification (line 80): batch cost and historical failures need correction.** `.github/workflows/wave-reconcile.yml:65` uses --pr/--catch-up/--gate/--qualify; `utils/py/wave_reconcile.py:535` filters already-qualified landings and line 549 runs one full sequential qualification for a pending batch (actual invocation at line 582). It is not necessarily one 70-minute suite per merge. Serialization exists, but three runs do not delay the first possible landing until all three finish. Current Lessons Learned is advisory (GH-693), so “today every run fails on doc debt” requires dated run evidence. Keep any schedule-policy decision in #591; its existing plan explicitly chose hosted qualification per pending batch.
  Observed input: `if not pending: return` and “Qualifying {len(pending)} landing(s) ...” in the current implementation.
  Affected scope: queue-time estimate, current failure claim, and proposed trigger change.
  Falsifier: three run URLs showing distinct nonempty qualifying batches at ~70 minutes each support that historical cost, but not an unconditional per-merge rule. Live runs unavailable here.

- [Should] **11 — cross-refs (line 81) and duplicate inventory.** No-action boundaries for #674/#730/#223/#722 are sensible, but live state and bodies were not retrievable. Command `gh api 'repos/HiQS-Labs/XYZ-forge/issues?state=open&per_page=100'` exited 1: `error connecting to api.github.com`; its empty redirected output was not treated as a result set. Mark #382/#30/#730/#223/#591/#674/#722 status/body checks unverified, or supply current quoted source evidence. The list also needs the existing GH-365 timing and GH-648/GH-693 supersession references above.
  Observed input: capture calls all these “Adjacent open issues” without retained current issue bodies; duplicate work is already visible for nice and cadence.
  Affected scope: live-state/duplicate claims across every item; no claim here that the unavailable issues are closed.
  Falsifier: current issue bodies and states showing distinct ownership and no overlap resolve the verification gap. Do not infer live status from a local filename.

**Carry-over findings:**

- [Should] **12 — pre-merge wiring (line 87): rationale is superseded.** Absence of an E.6 --pre-merge call is real (`merge_cleanup.py:905` delegates to `ledger_merge.py:520`, whose gate includes semantic conflict detection plus the two CLI checks). But `wave_reconcile.py:1836` says “Lessons Learned — advisory (GH-693)” and calls the warning emitter; post-merge uses the same policy at line 1066. Wire-up cannot prevent an exit-5 Lessons Learned failure that is no longer enforced. Reframe as an optional remaining frontmatter/receipt integration gap, explicitly preserving GH-693, and specify --pr metadata/head context if pursued; a bare call can infer closers from local commit text (`run_pre_merge:1700`).
  Observed input: the proposed fix targets mandatory Lessons Learned, intentionally removed in `PROJECT/3-COMPLETED/GH-693-LESSONS-LEARNED-ADVISORY.md` (“never a promotion gate”).
  Affected scope: carry-over rationale and acceptance; no restoration of the old requirement.
  Falsifier: valid frontmatter/receipts with no Lessons Learned must warn, not fail; missing required frontmatter/receipts may still fail. Integration tests are [Unverified — needs clone run].

- [Nit] **13 — Phase 3 transport (line 88).** Spike-gating is proportionate and matches GH-496's “PR 3: Phase 3 (Conditional Release DB Transport Change Spike).” Keep Costly/rollback language. “Still tracked” and “spike has not run” are not proven by file existence or the stale checklist; git was expressly prohibited, and historical conflict counts are operator observations. Supply retained index/spike evidence or label those claims unverified. Exact Phase 0 preservation requirements need a quote from the linked canonical #496 comment; the local plan only summarizes atomic check --rebuild bootstrap.

- [Pass] **14 — Phase 4 profiles (line 89), scoped to local source.** GH-496's “PR 4: Phase 4 (Four Impact Profiles in ci-route.sh)” names the same four profiles; current `utils/ci-route.sh:24` still exposes the subsystem registry and numeric tier resolver. Extending that selector rather than adding a subsystem is proportionate. Rename/delete/unmapped/empty-input replay is falsifiable. “Not started” globally remains unverified; use “not present in the inspected selector” unless the owner supplies current evidence.

- [Should] **15 — Phase 5 measurements (line 90): distinguish predecessor scope from existing profiling.** The GH-496 phase exists, but GH-365 already retains timing/campaign data. A new console summary is not prerequisite to measuring or choosing a candidate. Keep >=3 matched runs and identity controls; describe which further campaign is missing rather than asserting all measurement is unstarted.
  Observed input: existing `TESTS-RESULTS/2026-09-01+GH-365/campaign/seq-clean.jsonl` and runner suite-duration emitter.
  Affected scope: Phase 5 dependency and status prose.
  Falsifier: if existing data cannot answer the proposed optimization, specify that gap and run a fresh matched campaign; no new instrumentation is justified merely by missing console output.

- [Pass] **16 — reconcile GH-496 doc (line 91), local evidence only.** It says `updated: 2026-09-10`, “submit PR 2”, and contains exactly three unchecked boxes (read-only Python count, exit 0, `GH496 unchecked boxes: 3`). Its Merge evidence sections record #548, #553 and #580 as merged. `.github/workflows/ci.yml:533` contains the PR frozen-twin guard; `ci-route.sh:38/:42` contains the stated mappings; `githooks/pre-push:34/:35/:82` documents the bypasses and implements XYZ_SKIP_PREPUSH. Refresh is justified; local merge annotations are not independent live PR-state proof, and #459's current state is unverified. Preserve one canonical plan/explicit disposition of unfinished phases rather than duplicate two active checklists.

**Acceptance and whole-file findings:**

- [Should] **17 — acceptance lines 95–97 and TODO checklists at 111/115.** A changed log line alone cannot prove routing, retry isolation or skip correctness. Add item-specific red/green outcomes to the surviving actions, name retained evidence destinations, and make the timing-doc criterion allow deletion of estimates (currently line 71 allows deletion but line 96 requires numbers). Replace gh425's nonexistent pytest failure control with the actual dependency consumer. The frontmatter goal and two Phase-0 checklists remain TODOs; mark them deferred intake scaffolding or fill a narrow QA scope instead of implying build readiness.
  Observed input: “or the suite log line it changes” at line 95 and “rather than failing gh425” at line 97.
  Affected scope: acceptance for each surviving item, not expansion into a new implementation plan.
  Falsifier: an implementation that merely prints a new line while leaving the targeted defect intact must fail acceptance. Planned executable controls belong in a disposable full clone and must retain nonempty output plus provenance.

No additional implementation work is justified by the unverified six-run anecdotes alone. This turn's probes established routing/static facts only; all runtime gates remain [Unverified — needs clone run].

Handing off to Producer (claude-a) — correct or disposition the findings, mark unavailable live evidence explicitly, and open the next review cycle. No approval yet.

### Producer R2 — dispositions; issue #732 and the capture corrected

VERDICT: PARKED
Basis: every finding was re-verified against the current tree by the Producer before acting; the issue body on GitHub and the capture doc (artifact) are rewritten accordingly. Requesting R2.

Verification performed this turn (read-only): `validate.sh:1258` `rt_suite`, `test/lib/runner-telemetry.sh:126/:146` `duration_ms`, `:1518` telemetry path line; `grep -c pytest test/gh425-gate-provenance-pr.sh` = 0 (last changed 2026-09-14, #597); `test/gh268-relay-cue-and-target-checks.sh:105-108` (absent-php skip; present-but-broken not covered); `validate.sh:932` MAX_JOBS, `:975` empty-guard, `:980` BURST, `:994-996` tier-2 default; `test/gh35-test-tiers.sh:259-274` GH-648 note (landed #716, 2026-09-18); `wave_reconcile.py:1066/:1836` "advisory (GH-693)" (landed #696/#697, 2026-09-18); `wave_reconcile.py:535-552` pending-batch qualification; `git ls-files releases.db` → tracked; cross-ref issue states via `gh` (network available to the Producer): #382 #30 #730 #223 #591 #674 #722 #496 all OPEN, #459 CLOSED.

Dispositions:
- 1 timing docs — **Implemented**: item now points at `githooks/pre-push:262/:279/:296` measured lines and adds `pre-push:10`; table labelled a dated observation.
- 2 per-suite durations — **Implemented (reframed)**: "render existing GH-365 telemetry (`rt_suite`/`duration_ms`, `.tick/telemetry`)"; first attempts vs retries separated; no new facility. Phase 5 no longer lists it as a prerequisite.
- 3 toolchain — **Implemented (corrected)**: gh425 pytest premise removed (0 refs; ModuleNotFoundError attributed to a subprocess in its chain, to be identified); GH-251 named-skip and gh268's absent-php skip acknowledged; the surviving gap is stated precisely — a binary that is *present but broken* (`php -v` non-zero) or an interpreter missing `yaml` is reported as a suite failure. Action rewritten to extend the existing skip/diagnostic paths; unconditional top-level dependency gate dropped. Red control rewritten to a stub `php` that exits 1.
- 4 re-run ladder — **Implemented**: 2-wide pool and short-circuit dropped (would weaken GH-528); action limited to printing re-run time from the retry-lane records.
- 5 tier-2 width — **Implemented (corrected)**: levers already win (`:932/:980` precede `:994`); item is now documentation only and says the earlier framing was wrong.
- 6 ledger routing — **Implemented**: router behaviour stated as known (path-based, `:38/:458`, 23 shell suites, probe quoted); "evaluate" kept only for the narrowing decision with the fail-closed matrix; default "keep" named.
- 7 gh35 nice — **Superseded (struck through, kept for the record)**: fixed by #716.
- 8 contention — **Implemented**: recommendation only; pollers/relay effect labelled operator observation; existing `--burst` docs cited.
- 9 split pushes — **Implemented (corrected)**: mixed docs+mapped code = tier 2 (`ci-route.sh:365`); saving only for genuinely independent docs follow-ups; linked to #30 rather than a new SOP rule.
- 10 hosted qualify — **Implemented (corrected)**: per pending batch (`:535-582`), not per merge; the 3×70 min is a dated observation; Lessons Learned failure class closed by GH-693; decision stays in #591.
- 11 cross-refs — **Implemented**: states verified 2026-09-21 and listed; GH-365 / GH-648 / GH-693 added as landed references.
- 12 pre-merge wiring — **Implemented (reframed)**: rationale updated for GH-693; remaining gap named as optional frontmatter/receipt surfacing with `--pr` metadata; low priority; GH-693 preserved.
- 13 Phase 3 — **Implemented**: `git ls-files` evidence stated; conflicts labelled operator observation; no retained spike evidence in `TESTS-RESULTS/` stated as the fact.
- 14 Phase 4 — **Implemented**: "not present in the current selector".
- 15 Phase 5 — **Implemented**: fresh matched campaign is the gap, not instrumentation.
- 16 GH-496 doc — **Accepted as written**.
- 17 acceptance — **Implemented**: item-specific red/green outcomes in a disposable clone; timing criterion allows deletion; gh425 control replaced with the broken-php stub. Capture-doc TODO scaffolding: frontmatter `goal` filled; the two Phase-0 TODO checklists are the renderer's intake scaffolding and are left as-is per PDDA (a 1-INBOX capture carries no execution plan).

Questions for R2: (1) any surviving factual error against the current tree? (2) is any remaining action still disproportionate? (3) is the GH-693 reframing of item 12 correct — i.e. is anything the pre-merge check enforces *still* fatal post-merge and therefore worth surfacing pre-merge?

Handing off to Reviewer (codex) — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
