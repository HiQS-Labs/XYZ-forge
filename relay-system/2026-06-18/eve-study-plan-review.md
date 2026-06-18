# Relay — EVE-STUDY plan review (single round-trip)

- **Date:** 2026-06-18
- **Type:** Single-pass cross-model review (not a full Producer↔Reviewer relay thread)
- **Producer:** Claude Code (authored `PROJECT/2-WORKING/EVE-STUDY/PLAN.md`)
- **Reviewer:** Gemini CLI (`gemini --skip-trust -o text -p`, personal-login auth)
- **Artifact under review:** [PROJECT/2-WORKING/EVE-STUDY/PLAN.md](../../PROJECT/2-WORKING/EVE-STUDY/PLAN.md)
- **Disposition:** All recommendations accepted and folded into the plan (8 edits). See table below.

> Logged here per operator request (document the feedback in the relay-system transcripts folder
> instead of the CHANGELOG). This is a review record, not strict transcript format.

---

## Prompt sent to Gemini (paraphrased)

Single-pass review of a project plan governing a **clean-room** study of the Apache-2.0 "Eve" agent
framework — extract high-level PATTERNS (no code copying) and apply them to `xyz-3-agents-swarm` (core:
`tick`, a local append-only event-log CLI with `O_EXCL` claim locks; plus a `relay-automation` layer).
Asked for concise, concrete feedback (no rewrite) on four points:

1. Is the clean-room discipline sound/sufficient? Any gap that could leak Eve expression?
2. What is MISSING that would make the study more useful?
3. What should be CUT or simplified (over-engineering)?
4. Biggest risk to producing applied value, and one mitigation.

The full plan text was appended to the prompt. (Reviewing our own doc — no Eve source involved.)

---

## Gemini response (verbatim)

### Review: EVE-STUDY Plan

**1. Clean-Room Discipline**
*   **Soundness:** The plan is robust. The "paraphrase-on-ingest" and mandatory phase attestations are excellent controls.
*   **Leakage Gap:** **Structural Logic Leakage.** Even without copying text, following the exact control flow or "logic skeleton" of a complex Eve function can be seen as copying expression.
*   **Fix:** Add a rule: "If a pattern involves a specific algorithm, describe the *outcome* and *constraints*, then derive the logic independently without looking at the source."

**2. Missing Elements**
*   **Anti-Patterns:** The plan focuses on what to adopt. It should explicitly hunt for **"What Eve got wrong"** or "Where Eve is over-engineered for our needs" to avoid importing their technical debt.
*   **Failure Mode Analysis:** How does Eve handle partial state corruption or filesystem race conditions? This is critical for our `tick` (O_EXCL) model.
*   **Dependency Audit:** Briefly note Eve's core dependencies. If a pattern relies on a library we don't use, the pattern might be a "false win."

**3. What to Cut/Simplify**
*   **Decision Record Overload:** Don't mandate a full ADR (Phase 4) for *every* pattern. Only require them for "High Impact" changes to `tick` kernel or `relay-automation`. Use `LESSONS.md` for the rest.
*   **Provenance Granularity:** `00-PROVENANCE.md` is good, but don't let it become a burden. A list of "Files Reviewed" per theme is enough.

**4. Biggest Risk & Mitigation**
*   **Risk:** **"Abstract Drift."** Patterns become so high-level (e.g., "it uses files for state") they provide no actual engineering value.
*   **Mitigation:** In Phase 2, require a **"Mechanical Contrast"**: explicitly describe the *specific* delta between Eve's implementation and our current code. If you can't describe the change, the pattern isn't distilled enough.

---

## Disposition — what we did with each point

| # | Gemini recommendation | Action | Where in PLAN.md |
|---|---|---|---|
| 1 | Structural-logic-leakage rule (don't mirror the logic skeleton) | **Adopted** | §1 Forbidden list + per-phase gate + §5 final attestation |
| 2a | Hunt anti-patterns / "what Eve got wrong" | **Adopted** | Phase 2, step 5 (Anti-pattern check) + exit gate |
| 2b | Failure-mode analysis (partial corruption / FS races) | **Adopted** | Phase 2, step 3 (Failure modes) + exit gate |
| 2c | Dependency audit / "false win" flag | **Adopted** | Phase 2, step 6 (Dependency reality check) + exit gate |
| 3a | ADR only for high-impact changes; `LESSONS.md` for the rest | **Adopted** | Phase 4, step 2 + Phase 4 exit gate |
| 3b | Lighten provenance ("files reviewed" per theme is enough) | **Adopted** | §4 Method notes (provenance kept light) |
| 4 | "Mechanical Contrast" as the anti-drift gate | **Adopted** | Phase 2, step 7 (sharpens the prior "Contrast with us") |

**Net effect:** Phase 2's per-theme procedure went from 5 steps to 8 (added failure-modes, anti-pattern,
dependency, and a hard mechanical-contrast gate); the clean-room rule now names structural copying; Phase 4
no longer mandates an ADR per pattern. No restructuring — all changes surgical.
