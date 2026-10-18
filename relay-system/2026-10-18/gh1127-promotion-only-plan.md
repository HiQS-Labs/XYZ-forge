# RELAY · GH-1127 plan QA: promotion-only full suite, local ledger reconcile default
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1127-promotion-only-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1127-PROMOTION-ONLY-FULL-SUITE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` seeds into the isolated worktree (read it there; do NOT edit it).
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

**Plan QA request.** Read the canonical `PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` in full (not `.relay-artifacts`), then the cited sources: `.github/workflows/wave-reconcile.yml` (whole), `.github/workflows/ci.yml:98-260`, `utils/py/wave_reconcile.py:100-150,560-745,1280-1490,2130-2310`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:55-70,500-620,700-810`, `skills/2-daily/merge-cleanup/scripts/batch_record.py:170-200,255-316`, `test/gh549-work-events.sh:600-660`, `test/gh674-merge-cleanup-hosted-lookup.sh`, `test/ci-workflow.sh:100-115,236-300`, and issue context in `AGENTS.md:205-225,425-436`, `ROUTER.md:110-146`.

**Operational envelope:** single-maintainer repo. Decisions NOT under review: #1131 (local reconcile after each development merge; the full suite runs hosted once at development→main promotion; parallel is the standard qualifying form), the operator override on #1114/#1118, no new test files or cases (GH-831; per-case approval), no branch-protection changes by the agent, `ci.yml:203` mode stays the operator's call.

**Questions (cite file:line):**
1. With `pull_request` and `schedule` removed from wave-reconcile.yml, does a later `workflow_dispatch` on development with `--catch-up --gate --qualify` actually find **every** receipt-less landing since the last receipt (PRs via `unreconciled_prs`, direct pushes via `unreconciled_commits`) and qualify them in one integrated snapshot? Any pagination/limit, date cutover, or `--only-receipted` retry behavior in the publish step that would drop or fail landings when the pending set is large (e.g. 20+)?
2. merge-cleanup local default: does calling `run_local_wave_reconcile` immediately (no hosted lookup) lose anything the hosted-success path did — e.g. fast-forwarding onto a hosted reconcile commit, receipts the gate needs, `commit_and_push_phase5_writes` expectations? Is `check_hosted_reconciler_in_flight` (exit 8 while any hosted run is queued/in progress) the right behavior during a promotion dispatch, and does merge-cleanup surface exit 8 clearly?
3. Is keeping both calls in `run_post_merge_reconcile` behind `MERGE_CLEANUP_USE_HOSTED=1` sufficient for gh549's AST pin and gh674 without editing those tests? Would gh674 need the env set to keep exercising the hosted path (it calls `wait_for_hosted_reconcile` directly?).
4. batch_record sweep command change: any consumer or test that parses `sweep_inputs.command` beyond `batch_record.py:186`? Is "deferred to promotion dispatch" consistent with `record_verdict` (`clean|findings|deferred`)?
5. Receipt-meta check in `qualification_receipt_matches`: is "compare only keys present" safe for historical receipts and for the Small gate path? Any receipt producer other than `qualify_landings` writing those keys with different semantics?
6. Docs list: anything else that states per-merge hosted qualification or the 6-hourly catch-up as current behavior (e.g. hosted_lane_report.py messages, merge-cleanup SKILL.md elsewhere, WORKTREE-SAFETY.md, HOW-TO-USE.md)?
7. Anything in the plan that is a generalization without an observed input, or a required part of #1131/#1127 that is missing?

End with VERDICT and a `swept file: yes|no` line.
### Reviewer · Round 1

**VERDICT: FAIL**
**Basis:** The local-default change is sound in principle, but the unchanged tier-selected qualifier does not deliver the plan's promised full pre-promotion run. The promotion procedure also needs to bind evidence to the candidate rather than treating any green dispatch as sufficient. Review scope: the entire canonical `PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` (92 lines), including its pre-existing assumptions and acceptance table. The Setup's `.relay-artifacts/` copy is absent (`cat .relay-artifacts/GH-1127-PROMOTION-ONLY-FULL-SUITE.md`, exit 1, “No such file or directory”); used the canonical artifact explicitly requested by the Producer.

swept file: yes

- **[Blocker] F1 — Dispatch does not guarantee a full run.** Plan lines 43–44, 50, 60 and 75 equate the existing catch-up with a full-registry promotion gate, while line 69 excludes qualifier behavior from scope. `wave_reconcile.py:629–637` returns Small for tier 1; `:647–651` returns without running anything when all discovered landings already have receipts; `:2235` also conditions qualification on nonempty landings. A docs-only promotion can therefore get a green dispatch without a full run. Change the plan to specify an explicit promotion qualification path that forces the full registry on the candidate, including the no-pending case, while preserving historical receipt replay and bounded publish retries. Reuse the existing qualification machinery; no new workflow/test suite is requested. Add manual acceptance/red controls and a durable provenance destination for docs-only and no-pending inputs.
  Observed input: one pending landing whose diff is `AGENTS.md` and classifier output is `tier=1`; the current selector returned Small in the non-mutating probe below.
  Affected scope: every pre-promotion dispatch, including docs-only backlogs and an already-receipted candidate.
  Falsifier: the same selector input returning `validate.sh --parallel 4` in promotion mode, and a disposable-clone run showing one complete full-registry telemetry record when the pending set is empty; legacy ordinary tier selection may remain Small.
  Probe command (exit **0**, no subprocess executed by the selector):
  ```sh
  python3 - <<'PYPROBE'
  import ast,re,subprocess
  from pathlib import Path
  from types import SimpleNamespace as S
  p=Path('utils/py/wave_reconcile.py')
  f=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='select_qualification_gate')
  ns=dict(re=re,subprocess=S(run=lambda a,**k:S(returncode=0,stdout='AGENTS.md\n' if a[0]=='git' else 'tier=1\n'),SubprocessError=subprocess.SubprocessError),QUALIFICATION_GATE='validate.sh --parallel 4',SMALL_GATE='validate.sh --sequential --subsystem small',small_suites_at=lambda *a:['existing-small-suite'])
  exec(compile(ast.Module(body=[f],type_ignores=[]),str(p),'exec'),ns)
  print(ns['select_qualification_gate']('.', [{'mergeCommit':{'oid':'a'*40}}], {}))
  PYPROBE
  ```
  Decisive output: `('validate.sh --sequential --subsystem small', ['existing-small-suite'], 'tier 1')`.

- **[Should] F2 — Replace “wait green” with candidate/evidence checks in the promotion procedure.** Plan line 62 omits the tested SHA and backlog/deferred check. The publish race branch deliberately lifts old receipts onto a newer development head (`hosted_lane_publish.py:203–228`); recompute drops newly discovered unreceipted landings without failing (`wave_reconcile.py:2247–2256`). Its message promises “its own run qualifies it,” but this plan removes both automatic triggers. This is a concrete path to a green job whose newest development landing was never tested. Document a quiet promotion window, inspect retained `tested_commit`, full-gate telemetry and pending/deferred output, and require redispatch if new product changes land before promotion. Account explicitly for generated reconciliation/receipt commits added after the tested snapshot, rather than equating workflow event SHA, tested SHA and published tip. Add the manual red control to Acceptance; branch-protection changes are unnecessary.
  Observed input: the existing rejected-push recovery branch at `hosted_lane_publish.py:203–228`, followed by an unreceipted catch-up item at `wave_reconcile.py:2253–2255`; the latter is deferred while the publisher can return 0.
  Affected scope: development advancing during dispatch, publication recovery, or the interval between green qualification and promotion.
  Falsifier: a quiet candidate covered by full telemetry and only declared generated publication changes can proceed; a newly landed source change absent from that snapshot must require another dispatch even if the previous job is green.

- **[Should] F3 — A2 contradicts the retained safety guard.** Acceptance line 83 requires the default path to “never `gh run list`”, but step 2 explicitly keeps `check_hosted_reconciler_in_flight`; its command is `gh run list` (`wave_reconcile.py:81–89`), invoked for live local runs at `:2192–2195`. Fix A2 to say “no hosted polling/grace lookup in merge-cleanup; retain the local writer's one safety query.” The monkeypatched wait control alone does not establish absence of all lookups. Keep exit-8 behavior; `merge_cleanup.py:614–618` already prints the code and tail of the refusal message.
  Observed input: a normal live local `wave_reconcile.py --pr N` with a GitHub origin and the retained workflow file.
  Affected scope: A2's acceptance wording and verification boundary, not removal of the single-writer guard.
  Falsifier: default merge-cleanup skips `wait_for_hosted_reconcile`, while its local child still makes the safety query and refuses an active run with exit 8.

- **[Should] F4 — Include the batch consumer guidance in the doc edits.** Step 3 changes the full sweep command to a hosted dispatch but leaves its renderer saying “Run it in a throwaway clone” (`batch_record.py:185–186`). Step 5 misses current skill instructions requiring the printed local sweep (`merge-cleanup/SKILL.md:22,416–421,435–437`). Update these texts to distinguish a pending full sweep deferred to promotion from a completed sweep, and explain recording `verdict: deferred` with its reason until evidence exists (`batch_record.py:317–334`). The CLI also displays the command (`merge_cleanup.py:1733`), so the plan's “Only batch_record.py:186 reads it” claim at line 55 is inaccurate. No machine parser dependency was identified in the bounded searches of merge-cleanup and the named test wrapper; do not label that a repository-wide exhaustive result.

- **[Pass] Q1, bounded source answer:** PR discovery uses `gh api --paginate --slurp` with `per_page=100`, compares merge dates to the workflow's introduction, and checks every returned merged PR against receipts (`wave_reconcile.py:1298–1345`). Direct recovery traverses first-parent history after `DIRECT_COMMIT_CUTOVER`, excluding PR merge SHAs, express receipts and bot-authored commits (`:1387–1419`); it is not literally every direct push. Qualification runs one selected gate for the pending union (`:693–707`), not N runs. Publisher `retry_argv` preserves all targets without a fixed list cap (`hosted_lane_publish.py:139–166`); an AST-only probe with targets 1–25 printed `25 receipt targets retained: True` and `retry flags: ['--only-receipted', '--skip-pull']`, exit 0 (`python3 -` extracting that function, calling `retry_argv('--catch-up --gate --qualify', [str(x) for x in range(1,26)], [])`). This is not a live 25-landing run. The important drop is the deliberate racer deferral in F2, not a 20-item pagination limit.

- **[Pass] Q2–3, source answer:** the local writer pulls upstream before reconciliation (`wave_reconcile.py:2197–2198`), and its changes flow into the existing commit/push durability step (`merge_cleanup.py:775–809`). The hosted in-flight refusal is appropriate for the proposed single-writer contract. Keeping both calls syntactically in `run_post_merge_reconcile` satisfies the named AST condition (`test/gh549-work-events.sh:649`); gh674 calls `wait_for_hosted_reconcile` directly (`test/gh674-merge-cleanup-hosted-lookup.sh:52–53,80–81,99–100`) and needs no opt-in env merely to keep those cases active. Preserve its helper semantics.

- **[Pass] Q5, source answer:** comparing metadata only when present preserves absent-key historical behavior. `qualification_summary` returns the same mode/width/failure metadata for both Small and full paths (`wave_reconcile.py:524,537,549`), and the retained receipt writer uses that metadata and its failure-list length (`:707,731–735`). No different producer of these qualification keys was found in the examined writer/reader path. Actual legacy and tampered receipt replay remains **[Unverified — needs clone run]** as planned; do not claim those controls passed here.

- **[Nit] Q6–7:** the reviewed HOW-TO-USE / WORKTREE-SAFETY text search found no additional cadence statements; `hosted_lane_report.py:104–107` says “next run,” which remains accurate but can be clarified as the next dispatch. Keep the historical ci.yml cost rationale unless explicitly updating it for the new procedural pre-promotion witness. The relay's Definition of Done is still a placeholder; this review used the canonical plan's Acceptance plus the Producer's seven questions.

**Evidence limits:** graph project `XYZ-forge` points to the main checkout, generation `2026-09-01T15:54:30Z`, not this worktree. Graph search returned no candidate symbols; coverage marked the relevant paths changed/not tracked/missing, so all material claims above use current local source fallback. No git command, suite, pytest or executable fixture was run. No live GitHub/branch-protection assertions are made. All whole-file-plan findings are above; clone-run and hosted-runtime verification remain outstanding. Reversibility is Costly for the qualification boundary; the existing trigger rollback is useful, but does not repair an unqualified promotion after the fact.

Handing off to Producer (claude-a) — address F1–F4 in the canonical plan, disposition each finding here, then request Round 2 review.

### Round 2 — Producer (claude-a) → Reviewer (codex)

Dispositions (canonical plan revised in place):
- **F1 [Blocker] — Implemented.** New step 0: `--promotion` (requires `--catch-up --gate --qualify`) forces `QUALIFICATION_GATE`, bypassing the tier selector, and when nothing is pending qualifies the tested HEAD via the existing direct-commit meta (`fetch_commit_metadata`, `:408-440`). The receipt is an ordinary `artifact_kind: commit` entry the existing matcher replays. The decision lives in a pure helper `promotion_gate(...)`, so it is checkable. Call site `:2235` becomes `landing_items or args.promotion`. Plain `--qualify` is unchanged. Dispatch args gain `--promotion`. Your probe input is red control p1; the empty-pending case is p2; parser refusals are p3.
- **F2 [Should] — Implemented.** The AGENTS.md promotion procedure is now four steps: quiet window, dispatch, a step-3 evidence check bound to `tested_commit` (gate string, `result=pass`, no `deferred` log line, `git log <tested>..origin/development` restricted to `BOT_AUTHOR_EMAIL` reconcile/receipt commits, otherwise redispatch), then the PR. The A5 manual control tests the step-3 check on bot-only vs non-bot commits.
- **F3 [Should] — Implemented.** A2 now says no hosted polling or grace lookup in merge-cleanup; the local writer keeps its one safety query and exit 8.
- **F4 [Should] — Implemented.** The renderer label distinguishes deferred-to-promotion (full) from run-locally (Small), with `verdict: deferred` guidance. Merge-cleanup `SKILL.md:22,416-421,435-437` and `hosted_lane_report.py:104-107` are added to the doc edits. The "only consumer" claim is replaced with the bounded statement.
- Q1/Q2-3/Q5 passes acknowledged. The Q6-7 Nit is folded in: the ci.yml cost rationale is kept as history.

Request: confirm F1–F4 closed against the revised text, or name the gap with Observed input / Affected scope / Falsifier. VERDICT + `swept file:` line.

### Reviewer · Round 2

**VERDICT: FAIL**
**Basis:** F3 and F4 are closed at plan level. F1 has a suitable design but an incomplete acceptance witness; F2 still leaves the interval between opening and merging the promotion PR outside its quiet window. Reviewed the entire canonical `PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` (113 lines), including unchanged sections. The Setup artifact remains absent; used the canonical plan requested by the Producer. No additional pre-existing plan defect was identified beyond the findings below.

swept file: yes

- **[Pass] F1 design addressed, execution pending.** Plan `:50-54` forces `QUALIFICATION_GATE`, substitutes tested-HEAD commit metadata for empty pending, enters qualification with no landing items, and preserves the receipt-only retry. The existing commit shape supports this (`wave_reconcile.py:447-451`); the publisher recognizes commit receipts and retains extra flags (`hosted_lane_publish.py:119-166`). This closes the design objection, not execution verification.

- **[Should] F1 acceptance follow-through — exercise the empty-pending caller.** Plan `:52,55-59,102` specifies p2 as “one commit meta,” but the existing early returns are in its caller (`wave_reconcile.py:650-653`) and the outer dispatch condition (`:2235`). A helper returning HEAD metadata cannot detect those defects. Add a manual disposable-full-clone acceptance run of the actual promotion route with zero pending landings, retaining one complete full-registry telemetry record and a matching HEAD commit receipt. Reuse the planned qualifying run where possible; no new suite or test case. Retain command, exit status, decisive output and provenance under the existing `TESTS-RESULTS/2026-10-18+GH-1127/` destination. This is **[Unverified — needs clone run]**, not a request to run it here.
  Observed input: empty `landing_items` and `pending` at `wave_reconcile.py:2235,650`; p2 asserts only a metadata value (`plan:57`).
  Affected scope: A0 verification of the new no-pending promotion route.
  Falsifier: actual no-pending promotion produces full-registry telemetry and a replayable commit receipt; restoring either old early-return predicate prevents that result and fails the manual assertion.

- **[Should] F2 remains open — hold and verify the candidate through the promotion merge.** Plan `:77` ends the quiet window at step 4, but step 4 (`:80`) only opens the PR. Development can advance before that PR merges. Also, `:79` compares a local `origin/development` without a fetch and selects the “newest” receipt without associating it with the successful dispatch. Extend the quiet window through the actual promotion merge; fetch development before the final check, require `tested_commit` to be its ancestor, select the receipt by the dispatch run URL/ID, and recheck the PR head before merging. Existing receipts contain `run_url` (`wave_reconcile.py:738-740`). Keep the generated-commit allowance, checking those commits contain generated reconciliation/receipt changes rather than relying on bot email alone. Correct the exit-8 claim: it refuses reconciliation after a landing, not the merge itself (`merge_cleanup.py:713-716,727-729,749,609-610`). Extend A5 with post-PR-opening advance and stale-local-ref controls. This needs procedural wording and manual evidence, not branch protection or new gates.
  Observed input: proposed `plan:77-80` releases the quiet window when opening the PR and checks only an unfetched tracking ref; the existing reconciliation path explicitly runs after the merge (`merge_cleanup.py:713-716`).
  Affected scope: evidence selection and development changes between dispatch, PR creation and promotion merge.
  Falsifier: a fetched quiet candidate with evidence from the named dispatch and only inspected generated publication changes proceeds; a source commit after PR creation, or present remotely but absent from the tracking ref, requires redispatch before promotion.

- **[Pass] F3 closed:** A2 distinguishes skipped merge-cleanup polling from the child’s retained safety query (`plan:63,104`); exit-8 reporting remains in `merge_cleanup.py:614-618`.
- **[Pass] F4 closed:** labels, deferred-verdict guidance, bounded consumer statement and additional skill/report edits are explicit (`plan:64-68,81-82,105`).
- **[Nit]** Setup Definition of Done remains a placeholder; this turn grades the canonical Acceptance and Producer’s F1–F4 request.

**Evidence limits:** Graph project `XYZ-forge` points to the main checkout, generation `2026-09-01T15:54:30Z`; symbol search returned no matches, and coverage reported changed/not-tracked/missing freshness for the examined paths. Used current local source fallback. Read-only command `nl -ba PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md | sed -n '45,150p'` exited 0; decisive output: `77: Quiet window: no merges to development until step 4` and `80: Open the development → main PR from that tip`. Command `nl -ba skills/2-daily/merge-cleanup/scripts/merge_cleanup.py | sed -n '600,620p;700,815p'` exited 0; decisive output at `715-716`: the Phase-5 fast-forward “has just moved to the merge.” No git command, validator, test suite, pytest, executable fixture or live GitHub mutation was run. Runtime proof remains outstanding.

Root cause: promotion proof can become disconnected from the eventual merge candidate; Fix site: promotion procedure and A0/A5 acceptance; Why not upstream/downstream: the operator chose a procedural boundary, so preserve it and require an observable witness there.

Handing off to Producer (claude-a) — complete F1’s clone-run acceptance specification and tighten F2’s candidate window/evidence selection, disposition these findings, then request Round 3 review.

### Round 3 — Producer (claude-a) → Reviewer (codex)

Dispositions (canonical plan revised; final round):
- **F1 acceptance — Implemented.** New p4 in step 0 / A0: a real zero-pending promotion route (`--catch-up --gate --qualify --promotion`, no push) in a disposable full clone of the branch tip, identity bracketed. Development's tip already has receipts for every landing, so the route is naturally the empty case. It retains one full-registry telemetry file plus the HEAD `artifact_kind: commit` receipt, replayed True. The red control shows the two old predicates (`:650`, `:2235`) would launch nothing for the same inputs.
- **F2 — Implemented.** Procedure step 1: the quiet window now runs from dispatch until the promotion PR is **merged**, and the exit-8 claim is corrected (it refuses reconciliation, not the merge). Step 2: select the run id. Step 3: fetch first; pick the receipt by `run_url` = dispatch id; require ancestry of `tested_commit`; each later commit must be bot-authored **and** pass `hosted_lane_publish.declared_paths` (the publisher's own allowlist, `hosted_lane_publish.py:49-86`); no `deferred` log line. Step 4: re-run step 3 against the PR head immediately before merging. A5 now has controls (i)–(iv): a source commit after the tested commit, a non-allowlisted bot commit, a stale tracking ref, and selection by recency.

Request: confirm F1/F2 closed, or name any remaining gap with Observed input / Affected scope / Falsifier. VERDICT + `swept file:` line.

### Reviewer · Round 3

**VERDICT: PASS**
**Basis:** Approve the plan for implementation. F1's remaining acceptance gap and F2's candidate-window gap are closed in the revised specification. This is plan approval, not runtime qualification or merge readiness. Reviewed the entire canonical `PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` (120 lines), including the unchanged sections; no additional blocking pre-existing plan defect was identified. The Setup artifact remains absent, so this turn follows the Producer's explicit canonical-path instruction as in rounds 1–2.

swept file: yes

- **[Pass] F1 closed at plan level.** `plan:50-59,109` specifies the full-gate override, both entry/early-return changes, and p4's actual zero-pending promotion route in a disposable full clone. Its required outputs are full-registry telemetry plus the tested-HEAD commit receipt replaying True, with command, exit status and decisive output retained under the stated evidence destination. This now exercises the caller rather than accepting only a helper value. The two current predicates remain observable at `utils/py/wave_reconcile.py:650-651,2235`; implementation must replace them as planned. Establish the stated zero-pending precondition during execution rather than treating the sentence about today's development receipts as measured live evidence.
- **[Pass] F2 closed at plan level.** `plan:78-86` holds the quiet window until the promotion merge, fetches before checking, selects evidence by dispatch id, requires ancestry, restricts later commits by bot author and the existing publisher allowlist, and repeats the check against the PR head immediately before merge. `plan:114` supplies the source-advance, non-allowlisted bot, stale-ref and wrong-receipt controls. The named reusable allowlist actually rejects unexpected paths (`utils/py/hosted_lane_publish.py:80-86`), and the receipt producer writes the dispatch run id into `run_url` (`utils/py/wave_reconcile.py:738-740`). The exit-8 explanation now correctly describes refusal of reconciliation (`plan:78`). This remains the operator's chosen procedural boundary.
- **[Pass] F3/F4 remain addressed.** `plan:64` distinguishes merge-cleanup polling from the local writer's retained safety query; `plan:65-70,88-89` includes deferred full-sweep wording, the renderer/CLI consumers, and the skill/report documentation edits. No additional behavior or gate machinery is requested.
- **[Unverified — needs clone run]** A0–A6 execution remains outstanding (`plan:109-115`), including the actual empty-pending full run, receipt replay/tampering, existing covering suites, doc hygiene, and promotion procedure controls. Retain committed provenance for evidence cited by the implementation. No implementation result, live pending count, hosted run, or branch-protection state is attested by this review.
- **[Nit]** Setup still contains the literal Definition of Done placeholder. As in prior rounds, this verdict grades the canonical Acceptance table and the Producer's F1/F2 closure request.

**Evidence ledger and limits:** Read commands `cat PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` and `nl -ba ... | sed -n '55,103p'` exited 0. Decisive spans: line 58 requires the “actual route”; line 78 says “until the promotion PR is merged”; lines 80 and 86 require fetching and the final PR-head recheck. Direct source reads of the cited qualifier, caller, receipt writer and publisher allowlist exited 0. `cat .relay-artifacts/GH-1127-PROMOTION-ONLY-FULL-SUITE.md` reported “No such file or directory” (within a combined read whose final command exited 0). Verify-tier graph lookup used project `XYZ-forge`, rooted in the main checkout; symbol lookup returned zero matches, and coverage generation `2026-09-01T15:54:30Z` reported the plan missing, qualifier metadata changed and publisher untracked. Current local source supplied the evidence; graph results do not establish worktree freshness. No git command, validator, test suite, pytest, executable fixture, or live GitHub operation was run.

Root cause: promotion qualification can otherwise skip the full registry or become disconnected from the eventual candidate; Fix site: the existing qualifier plus the candidate-bound promotion procedure; Why not upstream/downstream: reuse the existing dispatch/receipt machinery and preserve the operator's procedural enforcement decision.

Relay closed (Approved), no further turn needed. Producer (claude-a) may implement the approved plan and obtain the specified execution evidence and final independent QA.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
