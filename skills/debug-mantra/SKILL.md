---
name: debug-mantra
description: Four-mantra debugging discipline — reproduce, trace the fail path, falsify the hypothesis, cross-reference every breadcrumb. Recite the mantra block verbatim at the start of any debugging session, then apply the four steps in order before proposing any fix. Trigger on /debug-mantra and proactively whenever debugging starts — user reports a bug, says something is broken/throwing/failing, asks to debug/diagnose/investigate an issue, pastes a stack trace or error log, or asks an attribution question ('where is this coming from?', 'what posts/triggers/generates this?', 'why is X appearing?') where the answer is an unknown source to find, not just a crash to fix. Adapted from: https://github.com/thananon/9arm-skills
---

# Debug Mantra

Four-step discipline for any debug session. Recite verbatim, then apply in order.

## Recite this — verbatim, as the first thing in your first response

> **Mantra:**
> 1. **First is reproducibility.** Can the issue — or the artifact — be reproduced or observed reliably?
> 2. **Know the fail path.** Debugger first; then source trace + knob enumeration; then in-code instrumentation.
> 3. **Question your hypothesis.** What would disprove it?
> 4. **Every run is a breadcrumb.** Cross-reference all of them.

Then begin work.

---

## 1. Reproduce reliably

Establish ground truth before anything else — a runnable repro for a failure, a direct look at the real artifact for an attribution question.

**Reproduce = observe the primitive ground truth, not your impression of it.** For a crash that's a failing test; for an *attribution* question ("what posts this?", "where does X come from?") it's inspecting the actual artifact — the real message, record, or raw bytes — **before** theorising about its origin. A screenshot, a rendered view, or a remembered detail is an **observation to verify, not an axiom to build on**: name it as assumption-zero and check it first. The cheapest disproof is usually looking straight at the thing — one query against the real object beats a sweep of the code that *might* have produced it. Beware visual grouping and other rendering artifacts: what looks like "one consolidated thing" may be many separate ones (or vice versa) — confirm against the raw object before any hypothesis inherits the shape.

- **Reliable repro** → capture the exact steps, inputs, and environment as a runnable artifact: failing test, curl script, CLI invocation, replay harness.
- **Flaky repro** → the bug is not yet debuggable. Raise the rate first: loop the trigger, parallelise, add stress, narrow timing windows, inject sleeps. 50% flake is debuggable; 1% is not.
- **No repro at all** → stop. Say so explicitly. Ask the user for env access, captured artifacts (HAR, log dump, core), or permission to instrument. Do **not** proceed to hypothesise.

Target: a fast (1–5 s), deterministic pass/fail signal. Pin time, seed the RNG, freeze network, isolate filesystem.

## 2. Know the fail path

Once reproducible, find *where* the code breaks and *what stops it from breaking*. The differential narrows the search. Try in this order — escalate only when the prior tactic fails.

1. **Attach a debugger.** If the env supports it, attach and step to the failure site. One breakpoint beats ten logs. Do this **before** turning any knobs.
2. **Source trace + knob enumeration.** If no debugger (or it can't reach the bug), trace the code path end-to-end and list every knob that can influence the outcome:
   - config flags, env vars, feature toggles
   - branch conditions, input shape
   - timing, concurrency, build options
   Each knob is a candidate axis to flip in the differential. Flip one at a time.
3. **In-code instrumentation.** If outside knobs can't move the failure, go inside: `printf` / log statements at the suspected fail site, dump the relevant internal state. Tag every probe with a unique prefix (e.g. `[DBG-a4f2]`) so cleanup is a single grep. Let the trace show where reality diverges from your model.

## 3. Falsify the hypothesis

When a candidate root cause surfaces, scrutinise it **before** testing it.

- Does it actually explain the symptom end-to-end? Walk it through.
- What is the simplest **proof**? What is the cleanest **disproof**?
- Run the **disproof first**. If the hypothesis survives, it's real. If it dies, you saved yourself from chasing a phantom.
- Generate 3–5 ranked hypotheses, not one. Single-hypothesis thinking anchors on the first plausible idea.

## 4. Every run is a breadcrumb

Maintain a running **ledger** of every experiment in this session. Each entry: what changed, what happened, what it ruled in or out.

- When a new hypothesis surfaces, walk the ledger. Does it hold for **every** prior observation, not just the most recent?
- If any past run contradicts it, the hypothesis is wrong or incomplete — refine or discard.
- When in doubt, design the **single experiment** whose outcome makes it certain. Run that next, instead of churning on adjacent runs.
- Update the ledger after every run. It is your memory across the session.

---

## Operating rules

- Recite the mantra block **once** per debug session, in your first response. Do not re-recite mid-session.
- Recite **verbatim**. Never paraphrase or abridge the recital.
- If the user says "skip the mantra" → skip the recital but still apply the four steps silently.
- Apply the four steps **in order**:
  - Do not propose a fix before #1 is satisfied (reliable repro exists).
  - Do not start testing hypotheses before #2 has narrowed the fail path.
  - Do not commit to a hypothesis before #3 has tried to disprove it.
  - Do not declare a hypothesis correct until #4 confirms it against every prior breadcrumb.
- **Scale rigor to the bug.** The gate is on *evidence*, not ceremony: a trivially obvious defect — a typo, a stack trace pointing straight at the line — needs a confirming **observation**, not necessarily a runnable harness or a written ledger. The burden stays on a direct look, never on assumption.
- If you catch yourself proposing a fix without a reliable repro, stop and return to step 1.
- If you catch yourself building on an unverified observation ("it's obviously X", "that's clearly one Y") — especially one drawn from a screenshot, a rendered view, or memory — stop and inspect the raw artifact first. The impression is hypothesis-zero, not ground truth, and a single direct look at the real object usually settles it faster than any search of the code that might explain it.
- The mantra is a constraint **you** carry through the session — not advice to deliver back to the user.
