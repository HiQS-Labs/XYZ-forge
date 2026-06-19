# Relay — Marathon Dogfood plan review (Producer: Claude · Reviewer: Codex)

**STATUS: Approved** (Codex r2, 2026-06-18 — all 8 r1 findings RESOLVED, no new issues; 2 rounds)

**Artifact under review:** `PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md`
**Producer:** Claude Code (Opus 4.8) — authored the plan
**Reviewer:** Codex (codex-cli 0.139.0, `exec -s read-only`, sandbox-off, billed to ChatGPT sub)

---

## ▶ TAKE YOUR TURN

- **Reviewer (Codex):** Read the artifact. Critique it as an adversarial reviewer of an
  *experiment* plan. Emit findings as **[Blocker] / [Improvement] / [Nit]** then a one-line
  **Verdict: Approved** or **Verdict: Changes requested**. Do not edit files — return review text.
- **Producer (Claude):** Apply actionable findings to the artifact, append a Producer block noting
  what changed (and what was refuted, with reason), then request re-review.

---

## Round 1 · Producer · Claude

Plan submitted for review. It is a harness-experiment plan (Marathon headless relay vs. the
6,988-line WPCC scanner monolith), structured: frontmatter → status table → TOC → Phases 0–4 with
observable checklists + per-phase QA checklists → constraints → out-of-scope. Key claims to stress:
the one-variable-per-run design, the pre-registered Q1–Q6, the containment/sandbox guardrails, and
whether the phase checklists are genuinely *observable*. Codex, your turn.

---

## Round 1 · Reviewer · Codex (`exec -s read-only`, sandbox-off; 76,206 tokens)

**Verdict: Changes requested.** Findings (verbatim, condensed):

- **[Blocker]** Phase 2 doesn't isolate "reviewer only" — re-running a live builder+review loop with
  a different reviewer also changes builder stochasticity + starting tree; "same diff/brief" is
  incompatible with "re-run identical brief" unless the builder output is frozen / reset to a baseline.
- **[Blocker]** Q3 not answerable as measured — `git show`/tracked-path inspection can't prove absence
  of async/ignored-file side effects (worktree isolation open). Narrow Q3 or add a settle-window +
  dirty-tree/output sweep.
- **[Blocker]** Q4/Q5 not pre-registered as falsifiable — "actionable QA"/"rubber-stamp" need a rubric
  (TP/FP, did requested changes alter the diff/gate, seeded-defect catch, false-approval).
- **[Improvement]** Q1 misnamed — one run = feasibility at fixed caps, not a file-size ceiling.
- **[Improvement]** Several checklist items not observable: "no spawned external-model call" isn't shown
  by `git show`; "cost from `tick analyze`" overstates the analyzer (`src/analyze.js` defers
  drift/collision); Phase 3 transcript-fill needs manual git inspection.
- **[Improvement]** `AGY_MODEL` variants in Phase 2 break the one-variable rule — split out / forbid.
- **[Improvement]** Need an explicit invalidation/abort rule if brief/caps/scripts/baseline change
  between phases → restart from frozen baseline.
- **[Nit]** Synthesis should say upfront: unrun Phase 4 ⇒ Q6 inconclusive, doesn't weaken the verdict.

## Round 2 · Producer · Claude — changes applied

All 3 blockers + 4 improvements + the nit accepted (no refutations — the review was correct
throughout). Changes:
- **Q1** reworded to "feasibility at fixed caps"; stepped-cap sweep moved to Out of Scope.
- **Q3** narrowed to "tracked-allowlist scope" + a settle-window + dirty/untracked sweep as the
  honest extent; async/ignored-file effects explicitly declared out of measurable reach.
- **Q4/Q5** now backed by a pre-registered **Reviewer scoring rubric** (TP/FP, effect-on-outcome,
  binary seeded-defect catch, false-approval hard-fail).
- **Phase 2** rewritten: builder output is **frozen** (capture Phase-1 patch → reset to baseline →
  replay → both reviewers review the byte-identical patch); added a seeded-defect sub-run; removed
  the `AGY_MODEL`-variants bullet (→ Out of Scope).
- **Checklists** tightened to real evidence sources (external-call via transcript/tool-shadow not
  `git show`; cost via `claude --output-format json`; drift via manual git inspection).
- **Constraints** gained an explicit **invalidation rule**.
- **Phase 3** states the **Q6-inconclusive** caveat upfront.

Re-review requested.

---

## Round 2 · Reviewer · Codex — **Verdict: Approved** (67,592 tokens)

All eight r1 findings marked `RESOLVED` with line refs; "New issues introduced: none found."
- 1 Phase-2 reviewer isolation (freeze + replay) ✅ · 2 Q3 honest scope + sweep ✅ · 3 Q4/Q5 rubric ✅
- 4 Q1 feasibility-at-caps ✅ · 5 observable evidence sources ✅ · 6 AGY_MODEL deferred ✅
- 7 invalidation rule ✅ · 8 Q6-inconclusive stated upfront ✅

**Relay closed: Approved in 2 rounds.**
