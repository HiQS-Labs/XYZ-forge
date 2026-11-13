# RELAY · GH-1452 final QA: merge-cleanup plan-ahead landing forecast
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1452-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (the IMPLEMENTATION, committed on this branch; base `6c0c76bb5`): review `git diff 6c0c76bb5..HEAD` limited to `skills/2-daily/merge-cleanup/scripts/ledger_merge.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/SKILL.md`, plus `CHANGELOG.md`, the working doc `PROJECT/2-WORKING/GH-1452-MERGE-CLEANUP-PLAN-AHEAD.md` and the evidence folder `TESTS-RESULTS/2026-11-13+GH-1452/` (README.md maps every scenario to its red control). You have no `git` in your sandbox if a command is refused: read the files at HEAD and use the Plan, Acceptance and Blast radius sections of the working doc as the diff map (the base text of each function is quoted there by `file:line`).
- Plan under review was Approved: `relay-system/2026-11-13/gh1452-plan-qa.md` (Codex, round 2). Settled findings S1-S3 and nits are not to be reopened without new evidence.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-13
- Operational envelope: a local, advisory conflict forecast printed by an operator CLI. Grade against the stated requirements and commensurate complexity, not multi-tenant or enterprise machinery. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new test file or registry entry in the diff is itself a finding, and you must not ask for one. Verification is the existing suite (`test/gh436-merge-cleanup.py`, 227 tests, OK) plus the retained manual scenarios. The final qualifying gate (`ci-local.sh`, route full) runs once after your approval; do not run it, `validate.sh`, `test/*.sh` or pytest.
- Definition of Done: GH-1452 is satisfied: a dry run over 3 or more `--prs` prints and stores the forecast; `unknown` withholds the recommendation; the forecast never supplies the GH-1158 decision or reason; `pin_selection` stays the single atomic writer; `set_landing_plan` is extended, not duplicated; SKILL.md states the planning-time contract; old pin files and old callers keep working; checks substantiate the claims.

## Questions for the Reviewer (answer each with `file:line`)

1. Is each Acceptance item in the working doc satisfied by the code and the retained evidence? For each item name the code site and the evidence line (`TESTS-RESULTS/2026-11-13+GH-1452/manual-check-run.log` `EVIDENCE` lines, README scenario map).
2. What prevents an unchanged, unfixed tree from being reported as delivered, and where is the observed rejection? Check that the red controls (S1 broken classifier, S10 naive read-modify-write, S13 base-commit `TypeError`, S7 control) are real and that the Preflight absence probes are only admission evidence.
3. Do the actual code paths match the plan: `landing_forecast` receives a prepared clone (no network, no import of the main script); `build_landing_forecast` owns the clone and the `pull/<N>/head` fetches and verifies each against the pin; `unknown` takes precedence over the direct/group rule; the fold stops at the first conflict; the recommendation text and `"conditional"` handling match SKILL.md?
4. Did a duplicate subsystem or writer slip in? Specifically: `ledger_repair_paths` is shared with the B1 resolver (behavior unchanged for `resolve_ledger_conflict`); `pin_selection` is still the only writer of the selection file; `set_landing_plan` is the only writer of `landing_plan`.
5. Is the GH-1158 contract intact? The refusal at the early checkpoint still exits 5 before any mutation, the forecast only annotates, `--landing-reason` is the operator's own, and an override is recorded rather than blocked.
6. Concurrency and failure handling in `pin_selection`: lock scope (temp-write and replace only), timeout reported as a failure to publish, behavior with `--scan-only`, `--prs-only`, no `--prs`, and inline `N@sha` pins. Any defect with a concrete failing input?
7. `forecast_comparison` base-drift check uses `git ls-remote` at the early checkpoint (before any fetch). Is a bounded read-only network call there acceptable under the GH-1158 "before any mutation" rule, and does a failed lookup correctly make no drift claim?
8. Is anything over-engineered for an advisory forecast? Name machinery to cut. Is the batch issue line (`Forecast (GH-1452)`) proportionate?
9. Are the PRS ratings still supported (pri 55, sev 40, appeal 50 neutral, effort 40), and does the CHANGELOG entry and doc status tell the truth about what was and was not verified (the real downstream queue and forks were not run, with reasons in the README)?
10. Pre-existing defects in the touched files are in scope: read `merge_cleanup.py` around `pin_selection`, `verify_selection`, the early checkpoint and `build_landing_forecast`, and `ledger_merge.py` around `resolve_ledger_conflict`; report any real defect you can demonstrate.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix. Every `[Blocker]` or `[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Include the literal line `swept file: yes` or `swept file: no`. Set a VERDICT (PASS, FAIL or PARKED) and Basis. Read-only probes only, output under `.relay-scratch/`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (codex)

**Block — one Should: the forecast can simulate a different order from the queue that lands.** This is an Easy correction within the existing ordering path; no new executor, gate or test suite is requested.

swept file: yes

gate run: no — this relay explicitly reserves the qualifying gate for the harness after approval.

Read all three implementation scripts and SKILL.md, the working doc, evidence driver/logs/provenance, and the GH-1452 CHANGELOG entry. The historical CHANGELOG was not audited as a separate product. Graph Verify discovery used `XYZ-forge`, whose root is another checkout and generation is `2026-09-01T15:54:30Z`; symbol lookup returned zero matches, `has_more: false`. Coverage for the three scripts was not current evidence for this worktree, so material claims below use direct source reads. No Git command, fixture, CLI workflow or suite was executed here. No additional demonstrated pre-existing code defect was found in the swept implementation; the pre-existing full-queue ordering path exposes the new integration defect below.

- [Should] **S1 — Use the actual selected landing sequence for the forecast and its comparison.** `merge_cleanup.py:2325` sorts only the selected PRs for the forecast; `:2150` similarly sorts only selected PRs at the early checkpoint. Phase 4 instead sorts **every** open PR (`:2336`) and then filters (`:2365`), and Phase 5 consumes that order (`:2464`). Soft collision edges through an unselected PR can therefore reorder selected members without any changed head/base or hard dependency. The stored forecast and the checkpoint agree with each other while disagreeing with the sequence that actually lands. Its cumulative conflict/conditional evidence can describe the wrong order, and `forecast_comparison` can report `match`, `stale: false`. Cheapest fix: reuse one ordering/eligibility calculation for the forecast, checkpoint comparison and Phase 4 consumer, preserving existing allowlist and hard-dependency deferrals. Re-evaluate comparison before landing when discovery changes the effective sequence; preserve the early GH-1158 refusal before mutations. Retain a bounded manual receipt using the input below and an unlisted-hard-prerequisite variant; no new test file or runner.
  Observed input: `--prs 1,2,3`; four open non-draft PRs, with files/creation timestamps `#1: [a.py], 2026-11-03`; `#2: [b.py], 2026-11-01`; `#3: [c.py], 2026-11-01`; unselected `#4: [a.py,c.py], 2026-11-02`; no explicit dependencies. Current selected-only sort yields `[1,2,3]`; full sort then allowlist yields `[2,3,1]`; all selected `_hard_deps` are empty.
  Affected scope: selected queues whose order or eligibility is affected by open PRs outside `--prs`, including soft collision chains; this does not authorize changing the sorter or merging unlisted PRs.
  Falsifier: with the exact input above, forecast order, comparison order and Phase 5 order must agree (or changed order must be visibly stale before landing); a queue containing only the three disjoint selected PRs must retain `[1,2,3]`. A selected member depending on an unlisted open prerequisite must remain deferred rather than being simulated as an unconditional landing.

  Read-only probe, exit **0**. The following is the ordering portion of the executed in-memory probe (no Git, fetch, file mutation or fixture):
  ```python
  import sys, copy
  sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts')
  from toposort_prs import toposort_prs
  prs = [
      {'number': 1, 'files': [{'path': 'a.py'}], 'createdAt': '2026-11-03'},
      {'number': 2, 'files': [{'path': 'b.py'}], 'createdAt': '2026-11-01'},
      {'number': 3, 'files': [{'path': 'c.py'}], 'createdAt': '2026-11-01'},
      {'number': 4, 'files': [{'path': 'a.py'}, {'path': 'c.py'}], 'createdAt': '2026-11-02'},
  ]
  selected = {1, 2, 3}
  forecast = toposort_prs(copy.deepcopy([p for p in prs if p['number'] in selected]))[0]
  phase4 = [p for p in toposort_prs(copy.deepcopy(prs))[0] if p['number'] in selected]
  print([p['number'] for p in forecast], [p['number'] for p in phase4])
  print({p['number']: p['_hard_deps'] for p in phase4})
  ```
  Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` with the code above. Decisive executed output: `forecast/early checkpoint order: [1, 2, 3]`, `Phase 4/5 selected order: [2, 3, 1]`, `hard dependencies: {2: [], 3: [], 1: []}`. The same invocation extracted only `forecast_comparison` with `ast.parse`, supplied an in-memory forecast in `[1,2,3]` order, matching pins `{n: str(n)*40 for n in selected}`, and a successful mocked `_net_git` lookup at base `'a'*40`. Called with the checkpoint order, the actual function returned `{'state': 'match', 'recommendation': 'direct', 'stale': False, 'stale_reasons': []}` (identity fields omitted here). This measures the comparison's actual inputs and output, not a full CLI execution.

- [Pass] **Q1 — Acceptance map, with the sequence caveat S1.** Paths below are relative to `skills/2-daily/merge-cleanup/scripts/`; evidence references are to `TESTS-RESULTS/2026-11-13+GH-1452/manual-check-run.log` unless stated otherwise. These are inspected retained author-run receipts, not reviewer reruns. Concrete action: retain these controls and refresh affected receipts after S1.
  1. Forecast print/store: `merge_cleanup.py:2324-2329`, `:2387-2392`, log **54**, per-PR table **11-24**. Covered for the fixture, but the general sequence claim needs S1.
  2. Group/disjoint and fewer-than-three: `ledger_merge.py:829-842`, log **24-27**, **52**; broken classifier rejection **25**.
  3. Clean-only fold/conditional: `ledger_merge.py:779-804`, log **24**, **32**; the ordering fed into it needs S1.
  4. Failed fetch/head mismatch/command failure: `merge_cleanup.py:586-594`, `ledger_merge.py:758-760`, `:829-832`; log **28-30**, complete control **26**. Fork topology itself was not run (README **63-64**).
  5. Atomic snapshot and old reader: `merge_cleanup.py:507-519`, `:538`; log **35**, **40**, **50-51**.
  6. Mode behavior: `merge_cleanup.py:2294`, `:2319`, `:2406`; log **55-56**. These receipts cover fixed-tree behavior; they do not show the requested per-mode base-tree reruns, so that portion remains unverified rather than inferred from helper absence.
  7. Refusal/override: `merge_cleanup.py:2167-2186`, `:2188-2205`; log **57**, **59**. The driver asserts equality of mutating calls (`manual-check-driver.py.txt:335-343`); log 57's `mutating_calls: true` means unchanged, not that a mutation occurred.
  8. Existing mutator compatibility/persistence: `batch_record.py:310-326`, `:190-220`, `merge_cleanup.py:2574-2580`; log **58-61** (S11/S12 read the stored record after CLI completion).
  9. Planning-time contract/capability: `SKILL.md:271-281`, **Drive loop step 1**, and the literal capability row `| landing-forecast | 4 | script | manual check, ... |`. This is directly readable delivery, not established by Preflight absence checks.
  10. Existing suites: `existing-suite-summary.txt:1-9` records **227 tests, OK, exit 0**; README **19-21** identifies the collector and omitted full log. Full final qualification is still pending, per README **65-66**.

- [Pass] **Q2 — Retained controls distinguish admission from implementation.** S1 intentionally replaces `_merge_tree` with an always-clean return and rejects `group` (`manual-check-driver.py.txt:138-142`, log **25**); note that the synthetic invalid tree also makes the fold incomplete, so this is a recommendation-sensitivity control, not an isolated path-parser proof. S10 deliberately attaches A's forecast to B's pins and observes mismatch (`driver:294-304`, log **51**); S13 actually calls the base mutator with the new keyword and observes `TypeError` (log **61**); S7 observes `direct` without a repair record and `group` with one (log **31**). Log **62** and the working doc's Preflight `grep_absent` checks prove missing code only. Four retained artifacts were nonempty and their declared SHA256 values matched when checked with `hashlib.sha256(Path(...).read_bytes())`, exit 0: driver, manual log, existing-suite summary, real-queue log (`provenance.jsonl:1-3`). Keep these distinctions; unchanged pre-fix code is rejected by S13 and cannot produce the delivered CLI forecast receipt in log **54**.

- [Pass] **Q3/Q4 — Simulation and existing owners are sound apart from S1's sequence input.** The caller owns the disposable clone, bounded network calls, base freeze, PR fetch/equality and cleanup (`merge_cleanup.py:558-603`); `landing_forecast` receives prepared objects and imports no main script (`ledger_merge.py:24-33`, `:732-743`). Unknown/pair failures precede the direct/group rule (`:824-842`); only clean fold steps synthesize parents and advance (`:788-804`); known conflicts stop and mark successors conditional. Resolver and forecast share `ledger_repair_paths` (`:528-533`, `:555`, `:746`) while exclusions remain explicit (`:551-554`, `:725-729`). Selection publication remains in `pin_selection` (`merge_cleanup.py:491-526`); `set_landing_plan` owns the landing-plan replacement (`batch_record.py:310-326`), and its existing save merge preserves that intent (`:190-220`). No duplicate subsystem/writer was found in these swept files. Keep these owners.

- [Pass] **Q5/Q6/Q7 — Authority and publication boundaries remain bounded.** Invalid decision/reason returns 5 at `merge_cleanup.py:2167-2186` before Phase 0, scans and batch creation; valid group records the operator reason (`:2204`) and override is annotation (`:660-663`), with receipts log **57-59**. Publication lock covers only temp-write/replace (`:513-516`); timeout/OSError returns failure to publish (`:517-519`), using `attempt_record.py:61-89`. No network/simulation runs under that lock. Inline pins are normalized (`merge_cleanup.py:454-458`), stale inline dry-run values warn while live heads are repinned (`:520-525`), execution verifies the inline/full live pin (`:543-555`), and comparison uses those verified heads (`:649-651`). Dedicated inline-pin and lock-timeout runtime cases are **[Unverified — needs clone run]**; they are not among the 13 retained cases. `ls-remote` at `:656-659` is bounded and read-only, so it respects “before any mutation”; a nonzero/empty lookup makes no base-drift claim. That does not prove current base freshness when lookup fails. Keep the current explicit contract; no extra network mechanism is needed.

- [Pass] **Q8/Q9 — Scope and qualification reporting are proportionate.** Three simulations, existing lock reuse and one optional metadata field are justified by the plan; no new gate/runner is present in these reviewed artifacts. The one-line batch annotation is sufficient (`batch_record.py:356-359`); no machinery needs cutting beyond converging the duplicated sequence selection in S1. Provisional PRS scores remain reasoned estimates: working doc **129-132** gives pri 55, sev 40, neutral appeal 50, effort 40 and expressly says parking was not demonstrated. The near-top status/frontmatter says final QA is pending; CHANGELOG **3-5** claims the focused suite/manual scenarios, not final qualification. README **58-66** discloses the downstream queue and forks not run, and pending final gate; **51-56** gives the substitute four-PR cost measurement. Preserve those limits and update completion wording only after correction and actual final evidence.

VERDICT: FAIL

Basis: Most acceptance behavior has concrete retained evidence and the advisory design preserves the existing writer and operator decision contracts. S1 is an observed integration defect in the feature's central sequence claim: advice and the recorded match can refer to an order different from the actual landing queue. Correct it through the existing ordering path and refresh affected manual receipts before approval. No tests or full gate were run in this reviewer worktree; the final harness gate remains outstanding.

Handing off to Producer (claude-a) — go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
