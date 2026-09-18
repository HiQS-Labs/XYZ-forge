# RELAY · GH-684/GH-686 plan QA — hosted reconcile lane: alert, skip-and-report, gh53 fixture
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh684-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md` (the plan of record; sections Recon map, Requirements → plan mapping, Plan S1–S4, Acceptance checks, Risks) and `PROJECT/2-WORKING/GH-686-GH53-FIXTURE-FLAKE.md` (shares the PR; maps to S3).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-18
- Definition of Done: the plan is grounded in the actual code paths it names, satisfies R1–R4 with nothing missing, extends the existing subsystems and writers (no parallel machinery), and its acceptance checks can detect the actual failures (each new/changed behaviour has a red control). Approve when every question below is answered "yes" or the remaining findings are `[Nit]`.

### Operational envelope (grade against this, not an enterprise threat model)
A single-repo GitHub Actions job on `macos-latest` plus a ~2 000-line local Python reconciler and a Bash test fixture. One operator, one canonical repo. Machinery and tests must stay commensurate: no new workflow, no notification service, no retry/queue layer, no second ledger. Reviewer findings are advisory; requests for behaviour changes must carry `Observed input:` / `Affected scope:` / `Falsifier:` (Ground rule 7 in this harness).

### Read in full before answering
- the two plan docs above
- `.github/workflows/wave-reconcile.yml` (97 lines) — especially the reconcile step (`--pr "$PR_NUMBER" --catch-up --gate --qualify`) and the commit step that refuses undeclared in-tree files
- `utils/py/wave_reconcile.py`: `catch_up_prs` (~1181–1248), `validate_lessons_learned` (~926–949), `validate_and_update_doc` (~1002–1025), the main landing/issue loop (~1928–2075)
- `test/gh421-auto-wave-reconcile.sh` (the unittest harness with offline fixture and `WorkflowTests`)
- `test/gh53-releases-merge-resolve.sh` lines 53–100 (`mk_diverged`, `union_dump`) and `utils/releases-merge-resolve.sh` lines 70–120
- Issue text: `gh issue view 684`, `gh issue view 686`, and #591's design decision (full-suite qualification is intentional; the plan keeps `--qualify --gate` untouched)

### Questions (answer each; cite file:line)
1. **Grounding.** Does the recon map describe the code as it is? In particular: is it true that a catch-up-recovered landing is indistinguishable from an explicit `--pr` landing once merged into `landing_items`, and that `ship_manifest_items` runs before `validate_and_update_doc` can die? If the plan's line ranges or claims are wrong, say where.
2. **S2 placement.** The plan checks `validate_lessons_learned` *before* `ship_manifest_items` for catch-up-sourced landings only, warns, counts, and `continue`s; explicit landings keep `die(code=5)`. Is there any write earlier in the per-issue path (e.g. via `qualify_landings`, `check_provenance_receipts`, receipts under `TESTS-RESULTS/`) that a skipped item would still leave behind, so that "skip = no writes for that issue" is false? Is a skipped item guaranteed to be re-found by `catch_up_prs` on the next run (doc in `2-WORKING`, row not Completed)?
3. **S2 exit semantics.** The run exits 0 with `SKIPPED` lines and the commit step lands the other transitions. Is there a consumer (the `--gate`/`--qualify` receipt logic, `unreconciled_prs`, the idempotency test in gh421, `merge_cleanup.py`) for which "exit 0 but one item unreconciled" breaks an invariant? If so, name it and the input that breaks it.
4. **S1 design.** A final `if: always()` step runs a new stdlib tool `utils/py/hosted_lane_report.py` that reads a log `tee`d to `$RUNNER_TEMP` and opens/comments/closes exactly one issue labelled `hosted-reconcile-attention`. Is a separate small tool the right seam versus (a) inline `gh` in the YAML, or (b) a flag on `wave_reconcile.py`? Is `$RUNNER_TEMP` the right place given the commit step's undeclared-artifact refusal? Does `permissions: issues: write` on the job suffice for `gh issue create/comment/close` with `github.token`?
5. **S3 correctness.** Is "keep one `settings` row per key — for `generation` the higher value, then the later `updated_at`" the right dedupe for the fixture's union, and does it match what `releases-merge-resolve.sh` expects a human to do? Is there another settings key that can differ across sides in this fixture? Is forcing the second boundary (`sleep 1.1` between the sides' writes) an acceptable deterministic control, or should the fixture rewrite `updated_at` instead?
6. **Missing requirement.** Is anything in #684's ask (as amended by #591) or #686's ask not covered by S1–S4? Is anything in S1–S4 *not* asked for (scope creep)?
7. **Acceptance checks.** For each of the checks in "Acceptance checks (falsifiable)": would it actually go red if the corresponding change were reverted? Name any check that would stay green on the unfixed code.
8. **Commensurate complexity.** Is any part of S1–S4 more machinery than the requirement needs? Is the test footprint (two cases + pins in gh421, one new suite of ~7 cases for the report tool, a 10× loop for gh53) proportionate?

Output: graded bullets `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` per question, `file:line` for every disagreement with a specific claim, then a verdict. Set `STATUS: Approved` only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · Round 1

VERDICT: FAIL

Basis: The bounded design is appropriate, but S2 leaves skipped issues in the downstream planner's fatal ownership set, S1's producer/consumer skip strings disagree, and S1 observes the reconcile step rather than the complete publishing job. S4 also misses a necessary change to the existing workflow test extractor. Revise these seams before implementation.

swept file: yes

Read both complete plan docs, the complete workflow, reconciler, gh421 suite, gh53 suite and resolver; traced the relevant planner and merge-cleanup consumers. This includes pre-existing code, not just proposed changes. The existing gh421 extractor dependency described below is an additional pre-existing limitation exposed by S1; no other independently established pre-existing defect is asserted here. No git command, test suite, executable fixture, source edit, or artifact edit was performed. Narrow probes used only source parsing/compilation, selected pure functions, and SQLite `mode=ro`.

- **Q1 — [Pass] Grounding of the primary failure.** `utils/py/wave_reconcile.py:1930` builds explicit targets, `:1948` appends recovered targets, and `:1950` deduplicates without retaining origin. `:2033` ships manifest rows before `:2035` calls the doc updater, whose Lessons Learned failure is at `:1019`. The existing checker is reusable and pure (`:925`). The cited catch-up range is slightly overlong: the function ends at `:1235`. Extend the recon map to include the receipt writes and downstream planner ownership below.

- **Q2 — [Nit] Define skip as no issue lifecycle writes, not no writes whatsoever.** Qualification is invoked for the whole batch at `utils/py/wave_reconcile.py:1956`; it writes validation telemetry and per-landing provenance at `:578–600` before the issue loop. `check_provenance_receipts` (`:604`) reads evidence. Keep the qualification policy unchanged and explicitly allow its retained evidence for a skipped landing; narrow “before the first write” in `PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md:52` to “before that issue's lifecycle writes.” Put the skip inside the merged/closing-doc path, after the open-issue preservation branch at `wave_reconcile.py:2025`, so an open umbrella's missing Lessons Learned does not change merge-evidence behavior.

- **Q2 — [Pass] A retained receipt does not erase this skip's retry source.** `catch_up_prs` independently collects dialed-in members, nonterminal roadmap rows and active `GH-*.md` documents (`utils/py/wave_reconcile.py:1187–1199`), then adds attributable closing PRs at `:1232`. Receipt-based recovery at `:1200` is an additional source, not a filter on that drift. With the issue still closed and the same attributable closer, the skipped item is discovered again. Add a repeat-then-repair assertion to S4 to pin R4, including the already-qualified case.

- **Q3 — [Blocker] S2's `continue` does not prevent a later rollback for the same skipped issue.** `reconciled_issues.update(linked_issues)` runs at `utils/py/wave_reconcile.py:1999`, before the proposed skip. The unchanged set reaches `run_subprocesses` at `:2113–2117`; `handle_marathon_plan_result` treats any matching `already-closed`/held finding as fatal (`:1445–1457`). The planner produces exactly that finding for a CLOSED issue retained in In progress (`utils/py/_marathon_plan.py:866–870`). Cheapest fix: exclude intentionally skipped issues from the downstream reconciliation ownership set, preserving fatal handling for issues actually reconciled. Add a mixed-batch test that supplies a real-shaped planner exit-4 finding rather than the existing always-green planner stub (`test/gh421-auto-wave-reconcile.sh:112–120`).
  Observed input: Read-only ledger query `SELECT gh_number,section,doc_path FROM roadmap_items WHERE gh_number=505` returned `(505, 'In progress', 'PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md')`; the actual active GH-505 doc fails `validate_lessons_learned`. A pure-function probe passed `returncode=4`, `stdout={"check":"marathon-plan/already-closed","file":"PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md","message":"issue #505 is CLOSED but the ledger lists it under \"In progress\""}` and `reconciled_issues={421,505}` to the existing handler.
  Affected scope: Catch-up issues intentionally left active because their Lessons Learned check failed, when the downstream planner reports their retained closed-issue drift.
  Falsifier: The same planner finding with ownership `{421}` must warn and preserve the successful item; a finding for actually reconciled GH-421 must still fail. Probe command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` loading only `ReconcileError`, log/die and planner-result functions via `ast.parse`/`compile`, then `handle_marathon_plan_result(SimpleNamespace(returncode=4, stdout=json.dumps(finding), stderr=''), issues)` for those two sets. Exit 0 (exceptions caught); decisive output: `planner issues [421, 505] -> ReconcileError 6`, versus `planner issues [421] -> accepted`. Full mixed-batch execution: **[Unverified — needs clone run]**.

- **Q3 — [Pass] Partial backlog success need not weaken the other named consumers.** Qualification attests the tested snapshot, not doc completion (`utils/py/wave_reconcile.py:451–484`); its receipt can legitimately remain. Recovery still has the drift sources above. gh421's idempotency assertion concerns completed transitions and repeat ledger writes (`test/gh421-auto-wave-reconcile.sh:153–174`). Merge-cleanup accepts the triggering run's success (`skills/merge-cleanup/scripts/merge_cleanup.py:437–440`) and performs ledger/doc checks afterward (`:516–534`); preserving explicit-landing failure maintains that trigger's contract. No additional change to these consumers is justified by the observed input. The planner exception is the concrete incompatibility.

- **Q4 — [Should] S1 and S2 disagree on the skip wire format.** S1 parses `wave-reconcile: SKIPPED …`, while S2 emits `wave-reconcile: WARNING — SKIPPED …` (`PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md:71–72`; `log` supplies the prefix at `utils/py/wave_reconcile.py:36`). A successful run with this warning would be treated as skip-free and could close its attention issue. Choose one literal format and feed the actual S2-shaped output to the report-tool test.
  Observed input: `wave-reconcile: WARNING — SKIPPED GH-505: missing Lessons Learned` from S2's specified format.
  Affected scope: Successful catch-up runs with one or more skipped docs.
  Falsifier: That exact line with outcome success must open/comment the attention issue and never close it; a success log without skips may close it. Probe command: `python3 -c "print('wave-reconcile: WARNING — SKIPPED GH-505: missing Lessons Learned'.startswith('wave-reconcile: SKIPPED '))"`; equivalent expression executed in the read-only probe, exit 0, output `False`.

- **Q4 — [Should] Report job status through publication, not only reconcile-step outcome.** The proposed `--outcome <step outcome>` (`PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md:71`) misses a failed final commit/push. This is an explicitly supported failure path: `.github/workflows/wave-reconcile.yml:94–97` documents the rejected fast-forward push, and `test/gh421-auto-wave-reconcile.sh:509–510` already models it. Pass the job's status as evaluated in the final step (or the combined preceding step outcomes); a success report must require successful publication too. [GitHub's context reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#job-context) documents `job.status` for this purpose.
  Observed input: Existing rejected-push case: reconciliation succeeds, no skips, final `git('push', 'origin', 'HEAD:development')` raises; reconcile outcome remains success while the job fails.
  Affected scope: Publishing failures after a successful reconciliation, plus earlier job failures reaching the report step.
  Falsifier: Reconcile success + publish failure must create/comment an alert and never close one; both success + no skips may close. Pin the status expression in WorkflowTests and add the report case. Runtime execution: **[Unverified — needs clone run]**.

- **Q4 — [Pass] Small external helper, runner temp and permissions are appropriate.** This helper keeps issue-state handling testable without making the local reconciler a notification writer; inline YAML would mix that logic into the existing publication script. `$RUNNER_TEMP` avoids `.github/workflows/wave-reconcile.yml:75–85`'s repository artifact allowlist. `GH_TOKEN` already receives `github.token` at `:34`; `issues: write` is the appropriate permission for the ordinary same-repository issue operations ([GitHub token guide](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token)). Specify `2>&1` before `tee` because terminal errors use stderr (`wave_reconcile.py:40–41`), retain `pipefail`, and specify how the dedicated label is provisioned. These are implementation details within S1, not reasons to add a service/workflow.

- **Q5 — [Pass] S3 is correct for this fixture.** `mk_diverged` initializes once before branching and changes releases only (`test/gh53-releases-merge-resolve.sh:60–74`). Initial `enforcement` and `repo_slug` settings are inherited unchanged (`utils/py/releases_app.py:2141–2144`); the writer updates `generation` and its timestamp (`:1657–1668`). Keeping the higher numeric generation, then later timestamp, addresses the observed duplicate without relaxing the resolver. Keep the sole header consistent with the selected generation; the resolver rejects a header below either parent (`utils/releases-merge-resolve.sh:98–119`). `sleep 1.1` is proportionate here, although fixing the two timestamps is faster; choose one and assert distinct timestamps before testing the union. No general settings-conflict policy is needed for this fixture. Ten-run runtime result: **[Unverified — needs clone run]**.

- **Q6 — [Pass] Local requirements map without scope creep; live issue coverage remains unverified.** R1–R4 and S1–S4 are present at `PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md:63–74`; GH-686's fixture-only scope is at `PROJECT/2-WORKING/GH-686-GH53-FIXTURE-FLAKE.md:34–38`. Keeping full qualification agrees with the checked-in #591 decision (`PROJECT/2-WORKING/GH-591-RECONCILER-LIFECYCLE.md:39–42`). Commands `gh issue view N --repo HiQS-Labs/XYZ-forge --json number,title,body,comments` for N=684,686,591 each failed to connect to `api.github.com` (exit 1); direct web opens also failed. **[Unverified — live issue text]**: Producer should confirm amendments against those issues; this review does not independently verify the historical run counts or current workflow enabled state.

- **Q7 — [Should] S4 must bound the existing workflow Python extraction before appending S1.** `WorkflowTests.publish` takes everything after `shell: python3 {0}\n        run: |\n` to EOF (`test/gh421-auto-wave-reconcile.sh:478`) and compiles it. Appending any final YAML step makes that text invalid Python. Extract just the publication step's `run` block, retaining all current allowlist and rejected-push assertions.
  Observed input: The current 97-line workflow plus the proposed final step shape `      - name: Report hosted lane\n        if: always()\n        run: python3 utils/py/hosted_lane_report.py\n`.
  Affected scope: gh421's existing publish tests once a step follows the Python publication block.
  Falsifier: Both the current workflow and the appended-step workflow must yield compilable publication Python; an undeclared artifact and rejected push must still be refused. Probe command: `python3 - <<'PY'`, reading the YAML and applying the exact `textwrap.dedent(source.split('shell: python3 {0}\n        run: |\n',1)[1])` followed only by `compile(..., 'workflow-publish', 'exec')` to base and appended-step strings. Exit 0 (syntax exceptions caught); decisive output: `gh421 extraction base -> compiles`; `gh421 extraction S1 appended step -> IndentationError unexpected indent line 1`. No workflow code or fixtures executed.

- **Q7 — [Nit] Distinguish regression controls from new-behavior proof.** Acceptance line `:78` correctly predicts removing S2 makes case (a) red; case (b) deliberately remains green on base. Neighbor suites at `:81` can also stay green on base and are preservation checks. YAML marker pins detect deletion, but do not detect the incorrect status/skip contract above. The report suite needs nonempty expected mutation calls, and “green/no issue → no calls” at `:74` should say **no mutating calls** because discovery still queries GitHub. Witness a deliberately omitted run URL going red; an assertion alone is not a red control. For gh53 (`:80`), undo only the dedupe while retaining forced distinct timestamps to guarantee the causal red, alongside the requested base-loop evidence. Full-suite green (`:82`) is aggregate regression evidence, not a substitute for those controls. Retain the red/green outputs with provenance.

- **Q7 — [Nit] Make hosted acceptance executable in the stated rollout order.** The status row says enable after merge (`PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md:29`), whereas `:83` expects this PR's close-triggered run. State whether the workflow will be enabled before that close event, or use an explicit post-enable dispatch as recovery proof followed by a later PR-close event. Since PR-close already runs `--catch-up` (`.github/workflows/wave-reconcile.yml:60`), its successful run should also report GH-505 if still defective; the next scheduled run proves retry, not necessarily the first success. Do not assert the schedule is the first success if a prior close-triggered run was green.

- **Q8 — [Pass] Complexity is commensurate.** One helper and one narrow skip branch reuse the existing workflow, checker, ledger writer and retry discovery (`PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md:71–74`; `wave_reconcile.py:925`, `:1079`, `:1181`). The proposed small report suite and gh53 repetition are reasonable. Add the few seam cases above within those suites; do not introduce a queue, notification service, second ledger, or blanket exception suppression. Reversibility: Easy for these plan edits; retain the existing qualification and rollback paths during implementation.

Disposition requested: address Q3's blocker and Q4/Q7's three Should findings, clarify the receipt boundary, then return the revised plans for round 2. Full implementation and hosted validation remain outstanding.

Handing off to Producer (claude-a) — revise the plans and disposition every finding, then take the next relay turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
