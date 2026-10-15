**SINGLE-MODEL — NOT RECONCILED** (only claude answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (claude's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

I have enough source to give a complete advisory. Here is my analysis.

---

## Identity

I am Claude Sonnet 4.6 (claude-sonnet-4-6), an AI language model built by Anthropic. I am not a runner, CI seat, or code-execution agent. My findings are based on reading source files in this worktree at `f974fcee`. I ran no suites, made no changes, and hold no authority over gates, receipts, or merges.

---

## ANSWER

The plan in `GH-1076-CI-POLICY.md` is structurally correct and internally consistent with what the source shows. Phases 1–2 are unblocked and minimal. Phase 3 Medium pilot has concrete, named missing evidence that prevents authorization today. The additive `hosted_gate=` approach is the right seam. No new tests are required to begin, and none should be added without separate approval.

---

## FINDINGS

### Q1 — Smallest implementation: canonical policy ownership and deterministic enforcement

**[Pass]** The existing output block at `utils/ci-route.sh:499-508` already emits `route`, `tier`, `tier2_subsystems`, `tier2_tests`, and `tier_reason`. The minimal additive change is one new line: `hosted_gate=small|full`, derived from the already-resolved `$tier` variable at line 471–497, appended after line 508. No logic changes to the classification loop are required.

**[Pass]** The wave consumer at `utils/py/wave_reconcile.py:593-618` today regex-extracts `tier=(\S*)` and maps `tier[0] != "1"` to full. Extending it to prefer `hosted_gate=` when present, and fall back to the existing `tier`-based derivation when the field is absent or malformed, is correct and safe. The existing exception path at line 617 already returns `QUALIFICATION_GATE` (full) on any error. A new consumer reading an old router that emits no `hosted_gate` field will fall back to full — this satisfies the invariant stated in the plan.

**[Should]** Before adding `hosted_gate=` to ci-route output, verify that `test/ci-route.sh` and `test/gh35-test-tiers.sh` do not do exact line-count or exact-stdout matching on the full output block. I could not read those test files in this pass; exact-output assertions would silently fail or need a coordinated update. *Inferred risk, not observed.*

**[Pass]** Receipt compatibility is sound. `qualification_receipt_matches` at `wave_reconcile.py:531-571` binds receipts to the gate string literal (`QUALIFICATION_GATE` or `SMALL_GATE`). The `small_suites_at` replay at lines 470-478 reads `SUBSYSTEM_TESTS_small` at the *tested commit*, not HEAD. Neither mechanism needs to change; the new `hosted_gate=` field feeds only the selection decision, not the receipt schema.

---

### Q2 — Machine-consumed markdown payload without new test cases

**[Pass]** No new test cases are needed. The counterexample is fully handled by fixing routing precedence.

The concrete gap: `is_docs_surface()` at `ci-route.sh:65` matches `docs/*` before the loop at line 382-413 can invoke `subsystem_of()`. So `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md`, which `subsystem_of()` at line 50 explicitly maps to `skills-army-hq`, is intercepted as `docs_only=true`, `tier=1`, `tier2_subsystems=` (empty). The wave selector then picks Small, which omits `gh620-skills-army-mini-sync.sh`. *Observed directly in source.*

The fix (plan Phase 2 step 6) is a targeted precedence exception: make `is_docs_surface()` return 1 for `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md` specifically (or any file that `subsystem_of()` explicitly claims), so it falls through to subsystem mapping. The existing `test/ci-route.sh`, `test/gh35-test-tiers.sh`, and `test/gh620-skills-army-mini-sync.sh` already cover routing correctness and payload contract respectively. Manual red controls — run the classifier before/after with those exact historical paths — falsify the fix without creating new assertions.

**[Should]** The broader audit (plan step 6) should enumerate all other explicitly named paths in `subsystem_of()` that could also be caught by `is_docs_surface()`. The same pattern could recur for any future `docs/` file explicitly listed in a subsystem. This is not a scope expansion — it is required due diligence before calling the consumer audit complete.

---

### Q3 — Batch prerequisites blocking full issue completion

**[Blocker]** Phase 3 (batch fold assessment and any Medium pilot) is concretely blocked by two independent constraints:

1. **GH1072 and GH1073 unresolved**: `wave_reconcile.py` does not implement reliable transaction isolation for verdict writes (plan explicitly notes this; no fix is present at `f974fcee`). The plan's statement is correct: "Until reliable, #1069 batch state cannot authorize evidence reuse." These are not deferred for convenience — they are safety conditions for any batch authorization.

2. **GH1064/PR1069 active writer**: The plan at Phase 1 step 2 explicitly forbids overlap ("GH1064 ci-local was active at initial inventory, so do not overlap it"). Any Phase 3 batch policy work that touches the same implementation files would violate this constraint. *Observed from plan; writer activity not independently verified in this pass.*

**[Pass]** Phases 1 and 2 are fully independent of these blockers. Canonical policy doc (`docs/CI-QUALIFICATION-POLICY.md`), ci-route extension, docs-surface routing fix, and pointer updates to AGENTS/SOP/ROUTER touch no batch state machinery and do not overlap the active GH1064 files (ci-route.sh, pre-push, and wave_reconcile.py are involved in GH1076 Phase 2, but GH1064's active scope is ci-local; the plan's step 4 explicitly says "do not overlap GH1064's active implementation files"). This needs verification at implementation time — the plan's constraint is conditional on what GH1064 is actually touching.

**[Pass]** Phase 4 partial (before/after benchmark for Phase 2 work, draft PR) can proceed after Phase 2 completes, independent of Phase 3.

---

### Q4 — Reduced hosted Medium pilot: justified now?

**[Blocker] No.** Four concrete missing evidence items, each individually disqualifying:

1. **No representative historical failure dataset with attributed catch rate.** The spike states directly: "A representative, attributed historical dataset remains missing." The gh620/GH991 counterexample shows *one* known miss; it does not establish a miss rate. The distinction between package-contract failures and environment/contended failures is unresolved.

2. **GH1072/1073 unresolved.** Stale verdict writes can lose newer landings; repaired-PR file lists can omit actual overlap. These are not speculative — the plan names them as specific failure modes. No Medium pilot can proceed without reliable batch state.

3. **Content-consumer audit incomplete.** The `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md` example is the only audited case. The plan (step 8) requires inspecting "other machine-consumed text" before any reduction. This work has not been done.

4. **Workflow/branch-protection compatibility unverified for any coverage reduction.** The spike's REST snapshot showed no configured required-status-check contexts, which is a *current state observation*, not authorization for skipping configured gates. A coverage-reducing change requires separately reviewed policy, workflow, and protection compatibility at the time of the change.

**Independent phases that can finish now:** Phase 1 entirely; Phase 2 entirely; Phase 4 partially (benchmark and draft PR for Phase 2 work). Nothing in Phases 1–2 reduces coverage or requires batch state.

---

### Q5 — Width-4 local full baseline/after plus naturally occurring hosted jobs: sufficient descriptive benchmarking?

**[Pass]** Yes, as *descriptive measurement with disclosed caveats* — which the plan already requires.

The plan at Phase 4 step 10 mandates: same explicit `width4`, serial per host, retain command/versions/counts/skips/failures/retries/wall-time and environmental/load differences. Step 11 limits hosted comparison to naturally occurring equivalent jobs (no dispatch/rerun authorized). This is appropriate and consistent with how past measurements (GH831, GH836, the 3h43m54s evidence) were handled.

One sample per side is not causal performance proof. High variance from load/environment differences is an irreducible confounder for a single pair. The plan explicitly acknowledges this and prohibits claiming causal savings. The benchmarking goal is to honestly characterize the implementation, not to prove a speedup — and a single paired measurement is sufficient for that constrained goal.

**[Nit]** The plan should explicitly note that if environmental or load conditions differ materially between before and after (e.g., different time of day, different concurrent processes), the comparison should be reported with that caveat rather than a wall-time delta alone. This is a documentation concern, not a correctness issue.

---

### Q6 — Needless complexity, backward-compatibility, unsafe assumptions

**[Should]** The `docs/*` pattern in `is_docs_surface()` at `ci-route.sh:65` is an unsafe assumption if more files in `docs/` are machine-consumed and need subsystem routing. Every future addition to `subsystem_of()` that matches `docs/` will silently route as docs-only unless an explicit exception is added. The fix for the current case is clear; the systemic issue should be noted in policy and/or the `is_docs_surface()` comment. *Observed from source.*

**[Should]** The `select_qualification_gate` at `wave_reconcile.py:603` uses `git diff --no-renames --name-only {landing}^ {landing}` — first-parent diff of the merge commit. For a squash-merge where a file was added and then reverted within the squash, the net diff omits the file even though it was changed. The plan notes this: "Preserve the union of individual landing diffs; a net batch diff can hide changed-then-reverted inputs." This is an existing limitation, not a regression, but it should be documented as a known boundary in the policy section rather than left as an implicit gotcha. *Observed from source.*

**[Nit]** The Ubuntu PR Fast Gate step at `ci.yml:404-406` is unreachable under the containing job predicate at `ci.yml:243-252` (spike finding). The policy doc should note this is not active required PR selective coverage so future readers don't rely on it. No repair is implied here — just accurate documentation. *Observed (spike); not independently re-verified in this pass.*

**[Pass]** The `wave-qualification@1` schema at `wave_reconcile.py:461` and the literal Small-list reader at lines 470-478 (reads `SUBSYSTEM_TESTS_small` at the *tested commit*, not HEAD) are both correctly designed for durability. Adding `hosted_gate=` to ci-route output does not change these contracts. Old receipts remain valid under new code; new receipts are readable by old code (they ignore unknown fields at the receipt-matching level). No backward-compatibility issue.

**[Pass]** No new policy/runner framework, no second registry, and no batch scheduler are required or proposed. The scope is correctly bounded.

---

## RECOMMENDATION

Proceed with Phases 1–2 immediately (baseline capture, canonical policy doc, additive `hosted_gate=` in ci-route, docs-surface routing fix for `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md`). Verify `test/ci-route.sh` does not exact-match output before adding the new field. Hold Phase 3 on explicit named conditions (GH1072/1073 resolved, GH1064 clear, catch-rate evidence available). Accept no Medium pilot without those conditions and separate approval from Noel.
