# RELAY · GH-1108 one-writer first PR plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1108-one-writer-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1108-JOG-LAND-RECEIPTS.md`; read operator design frame issue1108 comment6231071222 and current source cited in recon.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Review delivery1 only: primary-only Jog writes, disposable execution, committed portable bundles, mechanical stripped merge proof, and merge-cleanup post-merge hook. Delivery2 immediate push/retry is explicitly deferred to separate revertible PR by operator. Validate no new DB writer, DRY reuse, missing requirements, compatibility, ratings, bounded manual verification and rollback. Grade against local operator tool requirements and commensurate complexity, not unrequested enterprise scope. Proposed binding and receipt-publication defaults are explicit; assess correctness. Reviewer writes only this relay and runs no suites in worktree.

## Terminal token protocol (takes precedence over handoff prose)

Claim the token first as instructed by the shim. If APPROVED, finish with `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1108-jog-land-receipts-2026-10-17" "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1108-jog-land-receipts-2026-10-17/bin/tick" done RELAY-gh1108-one-writer-plan --agent codex`. Do not release the token to Producer when approving: terminal approval requires a done event by the current reviewer owner. The previous superseded relay content passed but its token was released instead of done, yielding close-mismatch. If requesting changes, release to codex-producer normally. Never run git; the shim commits your relay.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes
VERDICT: FAIL
Basis: Delivery 1 has a workable one-writer/portable-evidence design, but its deferred publisher leaves the existing merge-cleanup entry gate unsatisfied. Specify the interim operational checkpoint before implementation. This is plan QA, not implementation or runtime attestation.

- [Should] **Make delivery 1's pre-merge primary publication checkpoint explicit.** The plan at `PROJECT/1-INBOX/GH-1108-JOG-LAND-RECEIPTS.md:64` relies on the *post*-merge commit/push, while acceptance step 4 (`:93`) starts after reconciliation/ff. Existing `jog_commit_supervisor_state` commits intake/lease locally without pushing (`utils/py/jog_run.py:244–289`), and the terminal projection writes again (`:1754–1757`). Merge-cleanup checks readiness *before* Phase 5 (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1526–1573`): dirty paths and local-only integration commits both refuse (`scan_clones.py:1233–1240,1296–1307`). Its post-merge publisher cannot clear a prerequisite that prevents reaching it. Fix: retain the authorized delivery-2 deferral, but document an explicit operator checkpoint to inspect and commit only owned Jog ledger/view changes and normally push existing supervisor commits before merge-cleanup, with refusal/preservation on divergence or unrelated changes. Include an end-to-end delivery-1 acceptance control from run completion through clean, published primary to the post-merge hook; do not weaken Phase 0 or introduce automatic NFF repair in this PR.
  Observed input: the retained primary-run sequence is local supervisor commit → terminal `jog_set_status` → merge-cleanup. Static source input `dirty != []` appends “uncommitted path(s)”; `unpushed_on_integration > 0` appends “local commit(s) ... are not on origin”. Command `sed -n '244,295p' utils/py/jog_run.py; sed -n '1174,1318p' skills/2-daily/merge-cleanup/scripts/scan_clones.py; sed -n '1520,1585p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` exited 0 and showed those predicates and the pre-Phase-5 refusal. No runtime reproduction is claimed.
  Affected scope: delivery-1 primary-supervised runs producing owned local ledger mutations/commits before a normal merge-cleanup invocation; historical receipt-only imports into an already clean primary are not evidence for this path.
  Falsifier: in a disposable full clone, finish a delivery-1 run, then run normal merge-cleanup readiness without a manual checkpoint or delivery-2 publisher. If primary is clean, has zero unpublished integration commits and is ff-ready, this concern is unnecessary. Otherwise record the refusal, apply the documented owned-state checkpoint, and require readiness to pass. Record commands/results/provenance in the planned GH-1108 evidence directory.

- [Pass] **Scope, reuse and receipt exception are explicit.** The plan says “No immediate transition-push or NFF replay path is added in this PR” (`:64`), keeps canonical `perform_write`/Marathon/B1/post-merge publication (`:71–76,84`), and limits the necessary receipt-publication exception to “this execution's exact bundle paths” (`:73`). B1's current five-path set is at `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:35–39`; its CHANGELOG exception is at `:496`. No second DB writer or suite is proposed. Preserve these boundaries while resolving the checkpoint.
- [Pass] **Verification and rollback are proportionate at plan time.** `:86` rates the cross-surface change Costly and provides code rollback while preserving evidence; `:91–94` names negative controls, historical cases, existing suites in a disposable full clone, and committed provenance. Revised ratings at `:99` distinguish the broader design from the symptom fix. These are acceptance promises, not witnessed implementation passes.
- [Unverified — needs clone run] No suites, executable fixtures, Git commands, or functional landing probes were run in this worktree. The historical bundle imports, stripped merge implementation, gate validation and read-only command behavior still require the planned clone controls. Existing base evidence was inspected as prior evidence only. Graph project `XYZ-forge` generation `2026-09-01T15:54:30Z` is stale; coverage marked current Python paths changed and merge-cleanup paths untracked, so material findings use current source reads. The whole 99-line plan was swept; no additional pre-existing plan defects were identified beyond the checkpoint above.

Handing off to Producer (codex-producer) — document the bounded delivery-1 checkpoint and its acceptance control, then open round 2 for review.

### Producer · Round 1 disposition

Disposition: Implemented. The delivery1 boundary now names a manual operator checkpoint before merge-cleanup: inspect only owned ledger/view files and local supervisor commits, refuse unrelated state/divergence, commit explicit paths, normal push, and prove clean/published ff readiness. A rejected push preserves state and stops; automatic NFF recovery remains exclusively delivery2. Acceptance now requires witnessing pre-checkpoint Phase-0 refusal and post-checkpoint readiness in a disposable clone, through the mapped post-merge hook. No source code changed.

Handing off to Reviewer for round 2; check this focused correction and approve only if the delivery1 plan is sufficient. When approving, use the terminal token protocol above (done, no release).

### Reviewer · Round 2

swept file: yes
VERDICT: PASS
Basis: Delivery 1 is sufficiently specified for implementation. Round 1's publication prerequisite is addressed without pulling delivery 2 into this PR or weakening merge-cleanup readiness. This approves the plan only; no implementation, merge, or runtime success is attested.

- [Pass] **Round 1 checkpoint is resolved.** `PROJECT/1-INBOX/GH-1108-JOG-LAND-RECEIPTS.md:66` now requires inspecting status/diff/index and local supervisor commits, refusing unrelated state/divergence, explicitly committing owned paths, normal push, and clean/published ff readiness. It states: “A rejected push preserves local state and stops for operator reconciliation.” Acceptance at `:93` requires witnessing normal Phase-0 refusal before the checkpoint and readiness afterward, through the post-merge hook. Current source still refuses dirty paths and unpublished integration commits (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:1233–1240,1296–1307`), and blocks before Phase 5 (`merge_cleanup.py:1557–1573`). Thus the checkpoint supplies the missing operational step rather than relying on a post-merge action to satisfy a pre-merge predicate. Read-only command `sed -n '1220,1315p' skills/2-daily/merge-cleanup/scripts/scan_clones.py` exited 0; decisive output: `res["is_clean"] = not dirty` and `res["unpushed_on_integration"] = int(ahead.stdout.strip())`, with both non-ready cases appending blockers. This is static evidence, not a witnessed end-to-end run.
- [Pass] **Whole-plan scope remains coherent and bounded.** The complete 99-line artifact was swept, including unchanged sections; no additional pre-existing plan defects were identified. Explicit primary binding and read-only behavior are specified at `:70`; separate-full-clone execution, primary writer reuse and held-lock separation at `:71`; portable receipt publication and its exact-path exception at `:72–73`; cache-independent landing and mapped post-merge integration at `:74–75`. Six-path stripping and merge-history preservation are specified at `:58`, with fail-closed equality/conflict controls at `:92`. Existing B1 policy remains authoritative (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:35–39,496`). These are design requirements to verify during implementation, not claims that the current source implements them.
- [Pass] **Deferral, verification and rollback remain explicit.** `:64–66,80,95` reserve immediate transition publication and fresh-intent retry for independently reviewed delivery 2. `:86` rates the change Costly and preserves committed evidence on rollback; `:91–94` specify negative controls, historic receipt checks, existing covering suites in a disposable full clone and committed provenance under `TESTS-RESULTS/2026-10-17+GH-1108/`. `:99` records revised ratings without claiming independently reproduced identical failure traces. No new suite, writer or scheduler is proposed (`:76,86,94`).
- [Unverified — needs clone run] No Git commands, suites, pytest or executable fixtures were run here. Primary/clone refusal, unchanged clone ledger bytes, portable historical imports, stripped merge recomputation, readiness controls and final gate results remain implementation acceptance work. The operator design comment was read using `gh api repos/HiQS-Labs/XYZ-forge/issues/comments/6231071222 --jq .body` (exit 0); it requires “one DB writer, the primary.” The relay Setup supplies the authorized two-delivery boundary. Graph lookup returned both Jog symbols without pagination; coverage generation `2026-09-01T15:54:30Z` is stale (plan missing, Jog metadata changed, merge-cleanup paths untracked), so review evidence uses current source reads rather than graph freshness claims.

Relay closed (Approved), no further turn needed. Producer may proceed with delivery-1 implementation and its specified clone controls; final implementation QA remains required.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
