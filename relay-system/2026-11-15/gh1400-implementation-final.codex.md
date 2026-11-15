# RELAY · GH1400 implementation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-15.
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
6. **Commit only the relay file** (`relay(gh1400-implementation-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Final review packet

Review this committed implementation against the NEW implementation slice in
`PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`; old PR1403 is preserved history.
Read entire changed production files `utils/py/jog_run.py`, `utils/py/releases_app.py`,
Jog instructions, recon/decision and `TESTS-RESULTS/2026-11-15+GH-1400/SUMMARY.md`, scripts,
required inventories, result records, logs and provenance. Review the actual diff against
7dd85cd3a55303818ce61cbcc5d89b246d4a6449. Source changed last at97aa938be; subsequent changes
are evidence/docs and primary-owned rating checkpoint. Plan QA Approved round1/3, retained.

Operational envelope: local operator-invoked bounded Jog wake, synthetic provider-free verification;
no scheduler activation, live LTVera, new API spend, merge or deployment. No new schema/queue/ledger,
framework or tests/registry. Deadline bounds dispatch and worker group; publication/cleanup clocks
remain separate. No correlated loss/power-loss/PID-reuse/context/external-effect exactly-once promise.
Grade commensurate scope, not an unrequested enterprise controller.

Questions:
1. Does actual CLI adoption/continuation and adjacent repeat satisfy the capability gain without
   a duplicate builder or writer? What prevents unchanged code being reported as delivered?
2. Are exact latest issue/execution/target binding, missing/invalid result holds and existing
   attempt accounting preserved? Check latest gate retry cannot fall back to older approval.
3. Are clone/branch/log preservation and stopped/unknown owner exclusions safe within this envelope?
4. Are deadline/cancel ownership and limitations honest? Are stopped/held outcomes visible?
5. Are manual receipts nonempty and complete, with discriminating red controls? They are synthetic
   worker/gate results, not real product approvals. Existing integration227/227 is separate.
6. Any shared valid-history regressions, unaddressed pre-existing defects, scope expansion or
   duplicate subsystem? No new suite/registry may be requested.
7. Rating75/60/50/45 with null override is primary-owned; original accepted-start retained. Is
   the rationale honest? Is whole umbrella coverage proven or must #1400 remain open?

Final classified full gate is pending by workflow order and must run on the final approved
revision. Do not call pending gate green. Review may approve source/evidence subject to that
required publication gate; no ready-PR claim precedes it. Do not run tests/gates or modify source;
only this relay file writable. Read-only bounded source/evidence probes allowed. Source-backed
findings require observed input/scope/falsifier. Maximum3 review rounds, no delegated children.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-15
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The composed wake demonstrates the intended controlled capability, but two existing gate-retry seams in the touched Jog owner still let older approval survive newer uncertainty. Address/disposition S1 and S2 before approval. Final full gate remains pending.

swept file: yes

Swept both complete production files, Jog instructions, owning project/recon/decision, plan review and dated evidence/scripts/inventories/results/provenance, including pre-existing behavior. Compared exact base 7dd85cd3a55303818ce61cbcc5d89b246d4a6449 to HEAD 0c4cd2aa54a97ba80c94bf415b766bd15362dbdd: 56 changed paths. Read-only Python Git-object decoding asserted object hashes; the retained original Jog blob matches that exact base. No Git command was invoked. Graph Verify discovery/coverage used primary project Users-noelsaw-Documents-GH-Repos-XYZ-forge, generation 2026-11-15T07:36:58Z, metadata_match/no recorded gaps for Jog/Releases/proc_group. That index belongs to another checkout; exact worktree source is authoritative. No children, suites, executable fixtures, live workers, provider calls, remote writes or source edits were performed this turn.

- [Should] **S1 — direct resume substitutes an older approval for an uncertain latest gate retry.** utils/py/jog_run.py:750–762 skips absent/invalid retry receipts; :793–813 then accepts the enclosing execution ID, selects the original publication and projects it. The new supervisor validates the exact newest retry first, but explicit resume bypasses that check. Both retained missing/invalid retry seeds selected “gh901-exec1 approved” while their recorded newest retry is “gh901-exec1-gateretry1”. A narrow jog_resume call with publication/Git/state-write functions replaced by spies returned0 and requested publishing the original, then parked/awaiting-landing PR901. No actual publication occurred. Fix the existing resume selection boundary to require the newest recorded retry's exact result and issue/execution identity before publication/projection; absence/invalidity must hold visibly. Preserve valid historical no-retry and valid newest-retry recovery; do not globally remove historical searching from callers that deliberately need it.
  Observed input: TESTS-RESULTS/2026-11-15+GH-1400/latest/results.json cases retry-missing and retry-invalid: issue901, original gh901-exec1 approved, newest retry gh901-exec1-gateretry1, whose JSON is absent or {}.
  Affected scope: explicit jog resume where the newest recorded retry is missing/invalid; not every historical receipt or arbitrary corruption.
  Falsifier: those same two seeds must hold without calling the publisher or claiming awaiting-landing from the old result. Valid no-retry history must still resume the original; a valid latest retry must select that retry. The read-only no-retry control returned “gh901-exec1 approved”.

  Probe command: “python3 -” with PYTHONDONTWRITEBYTECODE=1 and the following read-only core (exit0):
  ~~~python
  import sys,json,pathlib
  sys.path.insert(0,"utils/py")
  import jog_run as j
  prefix=pathlib.Path("/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-supervision-composition-2026-11-15-verify/temp/gh1400-manual/latest")
  for case in ("retry-missing","retry-invalid"):
      root=prefix/case/"primary"
      p=next(p for p in (root/".tick/jog").glob("*/state.json")
             if json.loads(p.read_text()).get("gh_number")==901)
      rec,result=j._jog_latest_receipt(str(root),p.parent.name)
      print(case,result["execution_id"],result["outcome"])
  ~~~
  Decisive reader output: “retry-missing ... selected= gh901-exec1 approved” and “retry-invalid ... selected= gh901-exec1 approved”. Separate resume-spy output for each: “rc: 0; effects: publish gh901-exec1; status parked; awaiting-landing (PR #901: https://example.invalid/pr/901)”. Its mutation boundaries were all mocked; source selection/load/projection logic was real.

- [Should] **S2 — gate-retry intent is not saved before dispatch.** utils/py/jog_run.py:1013–1039 builds the retry argv, invokes the worker at1025, then first appends/saves the retry after the call returns. Ordinary execution already saves its result path before dispatch at :677–680. A narrow dispatch spy observed retry gh901-exec1-gateretry1 with zero prior saves and an empty retry list; a controlled pre-return interruption left zero saves. Thus exact-latest recovery cannot discover this newer intent after an interruption. Fix the existing retry writer: append/save the exact retry execution ID, result path and in-progress status before invoking Marathon; update that same entry on return. Preserve attempt numbering/history. No new schema, queue or suite is needed.
  Observed input: the retained issue901 approved/unpublished original from latest/retry-missing, with gate_retries removed only in an in-memory copy. At the real retry function's dispatch boundary, argv requests gh901-exec1-gateretry1 but no retry has been saved. No worker was launched.
  Affected scope: interrupted jog retry-gate between launching the retry and its first post-return state save, where recovery would otherwise see the older terminal result. This is ordinary process interruption, not power-loss/correlated-loss certification.
  Falsifier: at dispatch the existing state writer must already have saved the exact retry identity/path. An interrupted retry lacking a valid matching result must hold through supervised recovery and explicit resume, while completed valid retries still publish normally. Actual killed-worker/restart qualification is [Unverified — needs clone run]; the spy establishes write ordering only.

  Source probe command: “nl -ba utils/py/jog_run.py | sed -n '1007,1058p'”, exit0. Decisive output: “1025 proc = subprocess.run(...)” precedes both “1032 jog_save_state(...)” and “1039 jog_save_state(...)”. Non-mutating boundary probe command: “python3 -”, exit0; invoked _jog_retry_gate_locked with the above in-memory ledger, mocking target/Git operations, directory creation and saves; subprocess.run returned the receipt head for the pre-head read, then printed the dispatch state and raised KeyboardInterrupt before launching anything. Decisive output: “dispatch execution_id gh901-exec1-gateretry1”, “saved_before_dispatch 0 gate_retry_entries_at_dispatch []”, “controlled pre-return interruption; no worker launched”, “saved_after_interruption 0”.

  Root cause: resume searches newest-loadable history, and retry intent is first recorded after dispatch; Fix sites: existing resume selection and retry dispatch writer; Why not upstream/downstream: the ledger gateway cannot infer an unrecorded retry, and a supervisor-only check cannot protect explicit resume or discover absent intent.

- [Pass] **Capability and reuse:** attempt2/main-first.log says “recovered GH-901 without a new builder or attempt” then “processing GH-902 (attempt 1)”; check.py checks starts exactly “901\n902\n”, unchanged histories on repeat and both attempt counts1. adjacent/results.json records the exact-base red predicate “recovered approved A must publish its receipt before continuation”; the original lacks committed_receipt. These distinguish the new composition from unchanged code. Existing resume/publication, lease, preflight and Marathon owners remain in use (jog_run.py:2573, :2808, :2839–2845); no duplicate execution owner was added.
- [Pass] **Preservation and bounded ownership:** dirty tracked target/dependent worktrees hold; ahead development is renamed without deletion and untracked-overwrite refusal is retained (jog_run.py:2505–2534). Unknown-owner refusal and live/stopped PID checks are present (:1531, :1541, :2541–2554). Deadline execution reuses proc_group.run_bounded, including its exception cleanup (proc_group.py:108–145). SUMMARY explicitly separates publication/cleanup clocks and excludes escaped children/PID reuse/correlated loss. Manual evidence establishes attempt retention; the existing integration log separately reports cap2/2 at jog-changed.log:58–60.
- [Pass] **Evidence integrity and limits:** read-only JSON/hash checks found matching provenance hashes for attempt1/attempt2/adjacent/latest, record counts12/12/4/3 and all recorded predicates true; both attempt inventories exactly match their nonempty unique required-ID sets. Citations: dated provenance.jsonl, both required.json and corresponding results.json. jog-changed.log ends “227 pass, 0 fail”; provenance pins that integration run to b1d80f84, before final hardening. Candidate97aa938's12+3 manual checks are separate. SUMMARY.md:3–4 leaves final QA/full gate pending. Synthetic approval/gate/PR results establish no independent product acceptance.
- [Unverified — no citation] **Rating and umbrella scope:** read-only exact-base/candidate SQLite comparison found all39 Jog rows unchanged; among500 roadmap rows only GH1400 changed (raw rating80→45, rating_effort80→45, updated_at). Other ratings, null override and status_label stayed unchanged. The implementation rationale calls trend unknown and distinguishes one assisted run from synthetic evidence (project “Rating rationale — implementation”). Whole-umbrella coverage is not established: honor the plan's “leave #1400 open unless whole-issue coverage is independently established.”

S1/S2 are pre-existing defects in the touched owner, surfaced by the sweep; they do not mean the new supervised latest-entry controls failed their retained seeds. No other blocking pre-existing defect was established in this bounded review. Final gate, real product acceptance and the unperformed actual retry-kill run remain outstanding.

Handing off to Producer — go to the producer window and say 'take your turn'.

### Producer · Round 2

- Implemented S1: explicit resume reads the newest recorded retry, validates issue/execution identity and holds without publication on absent, invalid or mismatched output. Historical search remains available to callers that intentionally request it. Valid no-retry resume still works.
- Implemented S2: the existing retry entry (exact ID/path, dispatched status) is saved before invoking Marathon; the same entry is updated afterward. No new schema or ledger. A local fixture process group was actually killed after the durable entry appeared, then direct resume and supervised wake both held without older publication or another A builder.
- Additional author-found preservation defect fixed: detached unique HEAD now holds before fetch/switch. Original failing evidence remains `detached-before/result.json` (false); replay passes in `review-fixes/results.json`.
- Source correction d1b372874; eight required unique correction checks pass in the full verify clone. Existing original adoption/restart and red controls remain. Review the full touched owners and all correction evidence, paraphrase the intended change before evaluating it. This is final QA round2/3, not a reset of the cap. Source and receipts are synthetic/provider-free as previously declared; full publication gate follows independent approval.
- Round1 driver exited3 after correctly returning the open token to Producer and finding no automated producer progress. The FAIL/findings are retained; this is the normal manual correction handoff, not an approval or bypass.

Handing off to Reviewer — inspect corrections and retained evidence, then give a source-backed disposition. Final full gate remains mandatory after approval.

### Reviewer · Round 2

VERDICT: PASS
Basis: Approve this bounded implementation slice and its retained synthetic evidence. S1 and S2 are resolved; the detached-HEAD correction preserves unique work. No additional blocking defect was established by the whole-file sweep. The required classified full gate on the final revision remains pending; this approval is not PR readiness, live-product acceptance or whole-umbrella completion.

swept file: yes

Intended change: one operator-invoked Jog wake adopts existing approved receipts and advances independently eligible pending work through the existing preflight/Marathon owners. The corrections make explicit resume respect the newest gate retry and persist that retry's identity before dispatch. Detached execution HEAD now holds in place. This remains a local bounded CLI composition, with explicit retries and separate publication/cleanup clocks.

Read both complete production owners, Jog instructions, project/recon/decision, plan QA and the dated scripts, inventories, records, logs and provenance, including pre-existing behavior. Compared exact base 7dd85cd3a55303818ce61cbcc5d89b246d4a6449 with HEAD ecfee23b93fe5d31ce7f76513c9a3d5cacc69bca through read-only Python Git-object decoding with SHA assertions: 75 changed paths. Both current production files byte-match source correction d1b3728745935f0e55a730e417421d93503d7183. No Git command, suite, executable fixture, worker, provider request, child agent or remote write was run by this reviewer. Scratch stayed under .relay-scratch/. Graph Verify discovery returned the four existing receipt/resume/retry symbols with no pagination remaining; coverage reports metadata_match/no recorded gap for Jog, Releases and proc_group at generation 2026-11-15T07:36:58Z. That graph is a different checkout and lacks current supervision symbols; trace access was unavailable. Exact worktree reads and the complete base comparison supplied the authoritative fallback.

- [Pass] **S1 resolved, including valid history.** `utils/py/jog_run.py:793` selects the newest recorded retry directly, validates its exact issue/execution, and returns a visible parked hold on missing/invalid/mismatched output before publication. The historical reader at :741 remains available. Retained `review-fixes/results.json` cases resume-missing/invalid/mismatch/original/valid-retry distinguish the refusal and success paths. A read-only resume boundary probe using the retained five seeds, removing publication cache flags only in memory and replacing all primary checks, writes, Git and publisher calls with spies, independently observed:
  ~~~text
  missing rc 1 effects ['status parked']
  invalid rc 1 effects ['status parked']
  mismatch rc 1 effects ['status parked']
  original rc 0 effects ['publish gh901-exec1', 'status parked']
  valid-retry rc 0 effects ['publish gh901-exec1-gateretry1', 'status parked']
  ~~~
  Command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`, exit0. Core call was `j.jog_resume(str(root),901)` with real receipt loading/identity/projection and mocked mutation boundaries; no publication occurred. This directly reverses Round1's older-approval selection without rejecting valid no-retry or latest-retry history.
- [Pass] **S2 resolved.** `utils/py/jog_run.py:1040` creates the exact suffixed retry ID/path and dispatched status; :1042 appends it; :1043 saves it before :1044 invokes Marathon. The same entry receives return status at :1048/:1054. Retained `review-fixes.py` waits for the local fixture worker's marker, reads the saved retry entry, then kills that process group; `review-fixes/results.json` case retry-intent-kill-resume records that entry, direct resume refusal and supervised hold with no additional A builder. Case retry-completion records successful publication. These author-run receipts resolve the earlier actual retry-kill evidence gap for this synthetic local envelope; they do not certify provider or power-loss behavior.
- [Pass] **Preservation correction and existing ownership.** `utils/py/jog_run.py:2526` checks attached HEAD before fetch/switch; `detached-before/result.json` retains pass=false and `review-fixes/results.json` detached-held requires exit2, unchanged unique HEAD and no B start. Existing dirty/worktree checks precede alignment (:2521), ahead development is renamed rather than deleted (:2537), and unknown/live/stopped owners block (:1547/:1558). Existing lease/publication/Marathon owners remain in use (:2828/:2859); no second execution owner, schema, queue, suite or registry appears in the exact diff.
- [Pass] **Capability, latest binding, budgets and clocks remain bounded.** `attempt2/main-first.log` records “recovered GH-901 without a new builder or attempt” followed by GH902 attempt1; check.py requires starts exactly 901 then902 and byte-unchanged histories on repeat. `adjacent/results.json` retains the exact-base missing-publication red control. `latest/wrong-target.log` records “result receipt names a different execution target”; recovery checks exact issue/execution and both target bindings at `utils/py/jog_run.py:2592`. Dispatch uses the existing bounded process-group owner (:2508; `utils/py/proc_group.py:124`/:139); `adjacent/results.json` records cancellation exit130 and worker_absent=true. Deadline/held reporting remains visible (:2779/:2956). SUMMARY and the implementation contract expressly separate publication/cleanup clocks and exclude escaped children, PID reuse, correlated loss and context/external-effect guarantees.
- [Pass] **Receipt integrity and verification limits.** A read-only Python JSON/hash/inventory check, command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`, exit0, printed “hash/inventory: attempt1 12 / 12”, “attempt2 12 / 12”, “adjacent 4 / 4”, “latest 3 / 3”, “detached-before 0 / 1”, and “review-fixes 8 / 8”. It required nonempty bytes, matching provenance SHA256, unique result IDs, exact required inventories where retained and true predicates, while requiring the detached red predicate to remain false. Sources: dated `provenance.jsonl`, corresponding results/required files and scripts. `jog-review-fixes.log` ends “gh280-jog-marathon-adapter: 227 pass, 0 fail”, with provenance at d1b372874; this is retained existing integration evidence, not a gate run in this turn. Synthetic approval/gate/PR receipts prove controlled composition only. The final classified full gate remains required after this approval.
- [Pass] **Rating and umbrella disposition.** Read-only SQLite deserialization of exact-base/current blobs found all39 Jog rows unchanged; among500 roadmap rows only GH1400 changed, in raw_text/updated_at/rating_effort. Output: “ratings: [75, 60, 50, 45, None] label: in-progress”. `releases.sql`'s GH1400 row carries the same rating/null override; the original lifecycle label is retained. The project section “Rating rationale — implementation” honestly calls trend unknown and distinguishes the single assisted run from synthetic controls. Its final acceptance step says “leave #1400 open unless whole-issue coverage is independently established.” No such umbrella proof is supplied by this review; keep it open.

S1/S2 were the pre-existing defects established in Round1 and are now addressed. No further unaddressed pre-existing blocking defect was identified in these touched files during this bounded sweep. No new suite or broader controller is requested.

Relay closed (Approved), no further turn needed. Producer/harness next performs the required final classified gate in the disposable full clone and reports its exact revision/result before any ready-PR claim.


### Attestation · relay-drive — 2026-11-15T16:29:28Z
task: RELAY-gh1400-implementation-final
reviewer: codex
status: Approved
reviewed-head: ecfee23b93fe5d31ce7f76513c9a3d5cacc69bca
added-range: 19924+7719
added-sha256: 6465ad9b7ed21d8bd6989ff4cef6cacefd8e51605877236c01774b2d0c62b9b3
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
