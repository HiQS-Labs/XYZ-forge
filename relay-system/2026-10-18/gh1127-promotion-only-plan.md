# RELAY · GH-1127 plan QA: promotion-only full suite, local ledger reconcile default
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
