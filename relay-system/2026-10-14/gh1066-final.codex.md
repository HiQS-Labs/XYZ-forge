# RELAY · GH1066 final QA: CI groups and cross-model strategy review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: —
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
6. **Commit only the relay file** (`relay(gh1066-final-qa-ci-groups-and-cross-model-strategy-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/merge-cleanup/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-14
- Definition of Done: approved GH1066 plan implemented as bounded caller-only guidance; manual evidence truthful; no new runtime or CI machinery.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Bounded final QA packet

Read the whole skills/2-daily/merge-cleanup/SKILL.md and PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md; plan QA relay-system/2026-10-14/gh1066-plan.codex.md; TESTS-RESULTS/2026-10-14+GH-1066/manual-review.md and provenance.jsonl; docs/CI-CHURN-RECOVERY-SOP.md as needed for policy. Production scope is only added CI-heavy group guidance and existing batch issue template field. No driver/runtime/CI/settings/new tests/gate runner changes. Core additions are candidate preparation/freeze, existing supported batch path with sequential fallback, and one bounded different-model-family adversarial strategy review for authorized batches3+ (not per subgroup).

Operational envelope: local developer orchestration prose; commensurate complexity. This is not a measured CI saving or executable enforcement. The initial prototype publication gate was interrupted when scope expanded, not passed. Existing codex-turn43/0 and manual7cases/2red policy variants have receipts; final full push gate runs once AFTER this approval in the separate full helper clone. Do not demand a full gate now or run tests in the relay worktree.

1. Does the implementation match the approved plan, including the whole-batch threshold, actual model identity, cap3 across resumes, per-PR QA preservation, neutral truthful missing-review/model-unknown handling and affected-plan invalidation?
2. Are CI qualification and final verification strategically placed without silently bypassing mandatory checks or changing Phase5 reconciliation, and without claiming unsupported automatic batching or duplicate final sweeps?
3. Are manual evidence/limitations and score65/25/50/85 truthful and proportionate? Any important contradiction in the whole changed skill? Does existing batch record carry required strategy/review fields without another tracking system?
4. Does any added wording introduce avoidable ceremony or stronger behavior than requested? Identify concrete input and cheapest correction; do not invent speculative infrastructure or new tests.

Only this relay thread writable. No git commands, validate/test/pytest/fixtures. Output graded findings with file:line citations, swept file: yes/no, literal VERDICT: PASS|FAIL|PARKED and Basis. Set STATUS: Approved and NEXT: — on supported approval. No self-commit; harness owns receipt. This is final round1/3; prior plan review is not a final approval.

### Reviewer · Round 1

Ship the bounded guidance; implementation QA approved, with final gate and publication still pending.

swept file: yes

Read all 580 lines of `skills/2-daily/merge-cleanup/SKILL.md`, the whole GH1066 working plan, plan relay, manual review and provenance; checked the retained focused-run/identity receipts and relevant recovery SOP policy. No additional substantive pre-existing defect found in the whole skill prose. No graph tools were exposed; this is document inspection, not a runtime audit. No Git command, suite or executable fixture was run here.

- [Pass] The implementation matches the approved bounded plan. `skills/2-daily/merge-cleanup/SKILL.md:230`–244 places preparation and candidate freeze before qualification, preserving final-head per-PR checks. Lines 245–263 apply one strategy review to the whole authorized three-plus-PR batch, even when subdivided; require different actual model families and both identities; preserve per-PR QA; cap cumulative rounds across resumes; reopen affected material changes; and hold missing/unknown review with neutral language. No extra strategy relay is imposed on ordinary one/two-PR queues. No correction needed.
- [Pass] Qualification remains policy-controlled. Skill lines 264–284 preserve tier/platform rules, supported landing paths, exact landed-scope evidence and ordinary sequential fallback without claiming one/two total runs. Lines 299–305 retain the per-merge durability/reconciliation sequence. Read lines 273–277 together with the existing regression sweep at lines 414–421: reuse qualifying evidence covering the merged range, still perform the interaction/conflict review and name its evidence; do not launch a duplicate broad suite. This preserves recovery SOP lines 183–202 and 216–224 rather than renewing historical exceptions. No correction needed.
- [Pass] The existing batch template carries strategy/revision/review fields at skill lines 438–439. The caller-owned ownership remains explicit at lines 385–408; an issue-service failure is a recording failure, distinct from a missing required strategy review. No new runtime, CI, settings or tracking mechanism is requested by this guidance. No correction needed.
- [Pass] Manual evidence is proportionate and candid. `TESTS-RESULTS/2026-10-14+GH-1066/manual-review.md:3`–20 explicitly distinguishes seven prose scenarios and two retained manual red variants from executable enforcement. Its retained source at lines 25–85 matches the nonempty production section. `provenance.jsonl:2` labels the interrupted prototype gate as non-passing; line 3 limits the focused evidence. The retained `codex-turn-focused.log:61` says `43 pass, 0 fail`, and the before/after identity JSON files contain identical recorded values. These receipts do not prove the final full gate or CI savings. No correction needed.
- [Pass] The rating rationale at `PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md:90`–93 is modest and disclaims incident growth and measured savings. Read-only probe `python3 -c 'import sqlite3; c=sqlite3.connect("file:releases.db?mode=ro",uri=True); print(c.execute("select rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr from roadmap_items where gh_number=1066").fetchall())'` returned `[(65, 25, 50, 85, None)]` (exit 0), supporting persistence only. Final gate/publication remain unchecked at plan lines 99–100. No correction needed.
- [Nit] Fix the artifact argument on future invocations. Command `nl -ba .relay-artifacts/SKILL.md` exited 1 with `No such file or directory`; the seed directory contains only `gh182-claim-guards.md`. The bounded packet explicitly names the canonical skill, which was reviewed instead. Approval binds to that file: command `shasum -a 256 skills/2-daily/merge-cleanup/SKILL.md`, exit 0, decisive output `8533cb63558432f7e925399ef9334c4c5142333bba64e8569d5e0b5525a5010d`. No unrelated seed is approved.

VERDICT: PASS
Basis: The reviewed prose implements the approved caller-only scope, preserves mandatory qualification and per-PR review, bounds strategy review and truthfully limits its evidence. No blocking finding. This approves implementation review, not publication, promotion, teardown, a live batch outcome or an unrun gate. The final classified full gate must still run at the final revision in the separate disposable full clone, as plan lines 83–86 require.

Relay closed (Approved), no further reviewer turn needed. Handing off to codex-producer for the final gate and authorized publication workflow; the harness owns the relay commit.


### Attestation · relay-drive — 2026-10-15T04:02:38Z
task: RELAY-GH1066-FINAL-20261014
reviewer: codex
status: Approved
reviewed-head: ee3e80349ab027037b7084292d56ec3ea83b7c10
added-range: 7910+4590
added-sha256: 842d3d34095f011e306fbd95dccbcb92a5ddc5e87331fd60deeba3c9e27fa19e

### Attestation · relay-drive — 2026-10-15T05:01:57Z
task: RELAY-GH1066-FINAL-R2-20261015
reviewer: codex
status: Approved
reviewed-head: c8ff62340af45193e1343506a51e0458f9cfddbb
added-range: 15159+5291
added-sha256: ee6a9c2932fcd1b36cf050ee86ed7f6131301d404126ccd30a78748ee8c49fc5
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


### Producer · Round 2

Continuation of the SAME final QA thread, cumulative2/3; original round1 and attestation preserved. Author published ready PR1068 then source/gate copies were externally retired. Caller owns this isolated clone and reserved canonical repair1/2 before any change. Current reviewed artifact is canonical skills/2-daily/merge-cleanup/SKILL.md, GH1066 plan and TESTS-RESULTS/2026-10-15+GH-1066-merge-receipt-correction/. The old external .relay-artifacts path was not present in round1; use canonical actual source and whole-file reads here. Source skill is unchanged byte-for-byte from original reviewedee3e8034, SHA2568533cb63558432f7e925399ef9334c4c5142333bba64e8569d5e0b5525a5010d.

Only integration/packaging corrections: existing receipt reader failed34ebdd83 due to narrative result/exit_code and later non-TESTS plan edits; typed historical alias accurately binds actual full409/409 at759b34e0 in989s, with rawtelemetry. This alias does not certify later metadata. A fresh normal classified publication gate will run AFTER this review; do not demand/run it in the relay or claim it passed now. Qualified destinationd71c57e7 adopted via canonicalB1 disjoint resolver, onlyGH1066 replayed; exact preservation proof retained. All incoming non-generation SQL rows preserved exactly, onlyGH1066 extra roadmap, whole incoming changelog unchanged. No policy/runtime/test/CI edit. No retroactive strategy-review/savings/installation claim. Current source guidance remains only a PR.

Review the whole current skill and plan, original finalQA, original full publication rawtelemetry/identity proof, and correction README/JSON/provenance/preservation proof. Verify truthful binding and limits; identify concrete integration loss or unsupported claim, not speculative machinery/test additions. Existing fullproof is historical and fresh normal publication/exacthead/hosted gates remain caller obligations. Only this thread writable. No Git commands, tests/validate/pytest, fixtures, network or repository imports; narrow file/hash/JSON read comparisons allowed, bytecode disabled. Append at absolute EOF exact ### Reviewer (codex) · Round 2, file:line citations, swept file yes/no, VERDICT PASS|FAIL|PARKED and Basis. PASS headerApproved/NEXT —, tick done RELAY-GH1066-FINAL-R2-20261015; no selfcommit. Harness owns attestation. Handing off to Reviewer.

### Reviewer (codex) · Round 2

Ship the unchanged guidance and bounded receipt correction; current-head publication qualification remains pending.

swept file: yes

Read the whole 580-line canonical skill, whole current GH1066 plan, plan/final QA turns, manual scenarios and retained publication/identity evidence, and every correction README/JSON/provenance file. No additional substantive pre-existing defect found in the skill prose. Graph tools were not exposed; this is document/evidence inspection, not a runtime audit. No Git command, network request, repository import, suite or executable fixture was run. Only this relay file was edited.

- [Pass] The approved caller-only behavior survives integration. `skills/2-daily/merge-cleanup/SKILL.md:230`–284 retains preparation/freeze, one whole-authorized-batch review for three-plus PRs, actual model-family identities, cumulative cap across resumes, affected-plan invalidation, per-PR QA and neutral missing-review holds. The fallback preserves Phase5's per-merge sequence at lines299–305; lines438–439 reuse the existing batch record. No added runtime or CI mechanism is specified. Command `shasum -a 256 skills/2-daily/merge-cleanup/SKILL.md TESTS-RESULTS/2026-10-14+GH-1066/validation.jsonl`, exit0, returned skill SHA256 `8533cb63558432f7e925399ef9334c4c5142333bba64e8569d5e0b5525a5010d`, identical to Round1. No correction required.
- [Pass] The typed alias binds historical evidence without certifying this revision. `TESTS-RESULTS/2026-10-15+GH-1066-merge-receipt-correction/provenance.jsonl:1` names full SHA759b34e0603626c81690af08bafa6edd38554c12, PR1068, typed result=pass/rc=0 and an explicit later-head limitation. The hash command above returned telemetry SHA256 `af296f7ad2b582612a446f62bffbe7c70d577dcba5ae6d3749ca34c083007803`, matching the alias. Raw `TESTS-RESULTS/2026-10-14+GH-1066/validation.jsonl:412` records run759b34e06-90490, passed409/failed0/total409 and no envelope drift; `qualified-publication.log:890` says “full gate GREEN in 989s” and lines895–897 show branch publication. Command `cmp TESTS-RESULTS/2026-10-14+GH-1066/qualified-identity-before.json TESTS-RESULTS/2026-10-14+GH-1066/qualified-identity-after.json`, exit0, produced no output: retained identity bytes agree. This supports the historical result only. No correction required.
- [Pass] The correction preserves the rejected attribution and states the remedy: `TESTS-RESULTS/2026-10-15+GH-1066-merge-receipt-correction/pr1068-initial-receipt-reader.json:3`–4 retains rejected head34ebdd83 and its missing-receipt error; `README.md:3` and `pr1068-verification-ground-truth.json:35`–38 say later plan metadata invalidates prior qualification and require fresh normal publication. Original interrupted/non-passing records remain labeled at `TESTS-RESULTS/2026-10-14+GH-1066/provenance.jsonl:2` and4. `manual-review.md:3`–20 limits seven scenarios/two red variants to manual prose sensitivity, without enforcement or savings claims. No correction required.
- [Pass] The supplied integration records are internally consistent and bounded. `TESTS-RESULTS/2026-10-15+GH-1066-merge-receipt-correction/pr1068-ledger-resolution.json:5`–18 reports keep=theirs, one GH1066 replay through the writer/rating/update, only ledger conflicts and the same merge ID as `pr1068-adoption-preservation.json:2`–23. That report's lines24–39 delimit the preservation claim, additive receipts and reminted GH1066 identity. These are retained producer receipts; independent reconstruction of incoming ancestry/whole-baseline preservation was not performed under the no-Git constraint. No contradictory input or concrete integration loss found in the packet; this does not attest ancestry or current remote state.
- [Nit] Refresh the plan's live status when recording the next gate. `PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md:19` says publication qualification is complete and line99 says the gate passes “at the final revision,” while correction `README.md:3` reopens qualification at the corrected head. Cheapest correction: identify759b34e as historical and list the fresh normal classified gate as next; replace pending status with the actual result afterward. The correction packet and this verdict already make that limit explicit, so this wording is non-blocking.
- [Unverified — needs clone run] Fresh corrected-head publication qualification, exact-head/hosted checks and live PR readiness remain caller obligations (`TESTS-RESULTS/2026-10-15+GH-1066-merge-receipt-correction/README.md:3`–7). No reviewer-worktree probe substitutes for them; no new test or machinery requested.

VERDICT: PASS
Basis: The whole skill retains the approved bounded behavior, and the typed alias agrees with retained historical raw evidence while explicitly declining qualification of subsequent changes. No observed blocking defect or integration loss. Approval covers implementation/packaging review only; it grants no merge, promotion, teardown, installation, measured savings or unrun gate claim.

Relay closed (Approved), no further reviewer turn needed. Handing off to codex-producer for the fresh normal classified publication gate and exact-head/hosted verification; the harness owns the file-scoped commit and attestation.

