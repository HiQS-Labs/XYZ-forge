# RELAY · GH-1127 final QA: promotion-only full suite, local reconcile default
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1127-promotion-only-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/wave_reconcile.py** — the read-only path that
  `relay-drive.sh --artifact-file utils/py/wave_reconcile.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Final QA request.** The approved plan is `PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md`; its plan relay `relay-system/2026-10-18/gh1127-promotion-only-plan.md` was Approved in r3. Review the committed diff `git diff 4fd5dca8..HEAD -- . ':!releases.db' ':!releases.sql' ':!relay-system' ':!TESTS-RESULTS'` against the canonical files, plus the evidence in `TESTS-RESULTS/2026-10-18+GH-1127/` (start at its `README.md`; `provenance.jsonl` hashes each artifact).

**Operational envelope:** unchanged from plan QA. Decisions #1131 and the #1114 override are not under review. No new test files or cases; no branch-protection changes; `ci.yml:203` stays the operator's call.

**Claims to verify (cite file:line):**
1. `promotion_gate` and `qualify_landings(promotion=...)` in `utils/py/wave_reconcile.py`:
   - Plain `--qualify` behavior is byte-for-byte equivalent: same early return when nothing is pending, and the tier selector is called only when something is pending.
   - `--promotion` always yields the full gate, and yields HEAD-as-commit when nothing is pending.
   - `tested` is now computed before `check_porcelain_cleanliness`; is that ordering change safe?
   - Parser refusals.
   - The `:2235` call site.
2. Receipt-metadata check in `qualification_receipt_matches`: present keys are compared, absent keys keep their legacy meaning.
3. `merge_cleanup.py`: `USE_HOSTED_ENV` default-off; dry-run wording; the `"local"` sentinel leads to `run_local_wave_reconcile`; nothing else in the hosted-success branch is lost when local.
4. `batch_record.py`:
   - The `deferred` flag and command.
   - The renderer label.
   - `rec.get('integration')` matches the record schema (`new()`).
5. `wave-reconcile.yml`: dispatch-only, and the args include `--promotion`. Is the dead PR branch harmless?
6. Docs (AGENTS.md Promotion, ROUTER.md, merge-cleanup SKILL.md, ci.yml and validate.sh comments): accurate, and consistent with the code.
7. Test adaptations:
   - `test/gh421-auto-wave-reconcile.sh` trigger assertion: same test, new contract; red against both the old workflow and the old test.
   - `test/gh534_phase_c_tests.py`: the class opts into `USE_HOSTED_ENV` because it pins the hosted path.
   - Are these adaptations, not new cases?
   - Does the default local path now lack suite coverage (only manual A2)? If so, say so plainly. Adding a case needs operator approval and is not requested here.
8. p4 evidence: re-authoring the clone's branch commits as the bot (tree-equal, recorded in the README) to obtain zero pending landings. Is that a sound way to establish the precondition, and is it disclosed adequately?
9. Pre-existing defects in the touched regions.

Changed paths route full; the pre-push full gate runs at push. End with VERDICT and a `swept file: yes|no` line.

### Reviewer · Round 1 — codex

**PARKED — named review input is missing.** Used the plan's A0–A6 as acceptance criteria; Setup still contains its DoD placeholder.

swept file: no

The named seeded artifact cannot be swept: `.relay-artifacts/wave_reconcile.py` does not exist. I read the full repository copy `utils/py/wave_reconcile.py` (1–2489), plus the related qualification, local reconciliation, batch renderer, workflow, documentation and test-adaptation regions. That source review is useful but cannot establish identity with the absent seed. No additional pre-existing defect was found in the reviewed regions; this is not an exhaustive review of the other 1,799-line merge-cleanup module.

- [Should] **F1 — restore the intended review input before sign-off.** Setup names `.relay-artifacts/wave_reconcile.py`, but the only seed is `gh182-claim-guards.md`. Re-seed the intended artifact through the harness and provide the scoped diff as a read-only artifact (the current turn explicitly forbids Git), or explicitly correct the review target to the repository copy and supply its revision/diff binding. Do not treat the unrelated seed as GH-1127 evidence. Probe command: `python3 -c 'from pathlib import Path; p=Path(".relay-artifacts/wave_reconcile.py"); print("seed_exists:", p.exists()); print("seeds:", sorted(x.name for x in p.parent.iterdir()))'`; exit **0**; decisive output: `seed_exists: False`, `seeds: ['gh182-claim-guards.md']`. This requests input repair, not a product behavior change.
- [Pass] **Promotion selection in the repository copy:** `utils/py/wave_reconcile.py:649–676` preserves no-pending/no-selector behavior, uses the full gate for promotion and substitutes HEAD metadata when empty. An AST-only probe of the actual `promotion_gate` function (no imports, subprocesses or fixtures), exit **0**, returned: empty ordinary → `count=0 gate=None calls=[]`; empty promotion → `count=1 gate=('validate.sh --parallel 4', None, 'promotion (#1127): full registry') calls=['head']`; pending ordinary → selector called; pending promotion → selector not called. The actual caller at `:2235–2263` admits empty promotion and keeps the `--only-receipted` retry out of the suite path. Parser restrictions are at `:2181–2188`. The ordinary path now reads HEAD even with no pending work, so “byte-for-byte equivalent” overstates the claim; the gate-selection behavior is preserved. Reading HEAD before cleanliness causes no write; later ancestry, clone identity and final HEAD/cleanliness checks (`:678–683`, `:721–744`) protect publication.
- [Pass] **Receipt metadata:** `utils/py/wave_reconcile.py:586–594` compares only present metadata keys and compares retries to rescued first-attempt failures. Historical omitted keys keep their prior semantics. Retained controls are `TESTS-RESULTS/2026-10-18+GH-1127/manual-controls.log.txt:7–12`; I did not rerun replay because it invokes Git.
- [Pass] **Local path and batch record:** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:721–757` makes hosted wait opt-in and routes the `local` sentinel to the existing child; `:759–779` retains the shared governance/Jog tail. The hosted-success fetch/fast-forward applies to hosted writes and is not needed before the local child; normal Phase-5 publication remains at `:782` onward. `batch_record.py:75` establishes `integration`; `:183–192` labels deferred/local sweeps; `:310–324` emits the dispatch command for full and preserves Small. Default-local execution evidence is the manual A2 control, not the hosted-path class.
- [Pass] **Workflow and promotion procedure:** `.github/workflows/wave-reconcile.yml:9–10` is dispatch-only, `:69` passes promotion; the retained PR branches are unreachable under these triggers and harmless. `AGENTS.md:440–457` binds the quiet window, run-id receipt, fetched development and final PR head. `ROUTER.md` GH-1127/GH-831 paragraphs distinguish promotion from ordinary qualification; merge-cleanup SKILL's lines 300–306 and 421–425 describe local reconciliation and deferred full sweeps. The unchanged sequential main witness remains `.github/workflows/ci.yml:152–153,203`.
- [Unverified — needs diff / clone run] **Test adaptation and final gate:** current `test/gh421-auto-wave-reconcile.sh:600–627` pins the new trigger contract; `test/gh534_phase_c_tests.py:256–261` opts the hosted-path class into the env flag. The retained `gh421-adaptation-controls.log.txt:1` reports both old/new red controls. These are consistent with adaptations; without the requested base diff I cannot independently attest there are no additional cases or changed paths. The default local branch lacks dedicated suite coverage in that opted-in class; A2 is manual evidence. No suite, pytest, executable fixture or Git command was run this turn. A6 remains the harness/push gate's responsibility.
- [Pass] **Retained p4 evidence is internally consistent:** `TESTS-RESULTS/2026-10-18+GH-1127/README.md:6` explicitly discloses re-authoring as bot and the tree-equality claim; `wave_reconcile.py:1417–1421` explains why that creates the zero-pending precondition. This is a reasonable synthetic precondition for the empty-landing route, not proof that naturally receipted history was exercised or that the original branch SHA was tested. Read-only Python hash/JSON inspection, exit **0**, found `evidence artifacts=19 hash_or_size_mismatches=[]`, `p4 starts=1 summaries=1 telemetry_hash_matches=True`. Telemetry reports commit `4030781b2423accd59782ca08b648e1912e2c3d3`, parallel width 4, tier 3, registered 406, summary passed/total 409, failed 0; the receipt records `first_attempt_failures=['gh75-dashboard.sh']`, retries 1. `p4-run.log.txt:2–3` records zero pending PRs/direct commits, and its final lines record the HEAD commit receipt. Tree equality, exit status and identity stability remain the Producer's retained assertions; I did not independently reconstruct history.
- [Nit] **Stale wording:** `merge_cleanup.py:715` still describes hosted-first as the function's default; `SKILL.md:339–341` says to run the printed sweep in a throwaway clone even when it is now a hosted dispatch. Update those descriptions when repairing the input; neither changes the reviewed routing.

Graph limitation: no project matches this isolated worktree. The nearest XYZ graph is generation `2026-09-01T15:54:30Z`; `check_index_coverage` reports wave source `metadata_changed` and merge-cleanup/batch files `not_tracked`. Claims above use direct current-source reads, not that stale graph.

**VERDICT: PARKED**
**Basis:** no observed product failure in the reviewed paths, but the required seeded artifact is absent and the requested committed-diff identity cannot be established under the no-Git turn contract. Restore/correct those review inputs before approval; no new tests or product changes requested.

Handing off to Producer (claude-a) — repair the review inputs, then go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
