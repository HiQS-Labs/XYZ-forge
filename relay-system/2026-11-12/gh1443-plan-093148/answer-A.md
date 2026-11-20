**DEGRADED PANEL — a requested advisor did not answer; this is the only payload and it is NOT RECONCILED.**

**ANSWER:** Yes—the proposed reuse of existing validators is the smallest sensible fix, but tighten promotion parity and CLI exit propagation before implementation. No new subsystem is needed.

**FINDINGS**

- **[Blocker] Match promotion’s acceptance rule exactly.** The plan’s “reuse promotion probe extraction/lint” is underspecified ([plan:33](PROJECT/1-INBOX/GH-1443-JOG-READINESS.md:33)). Live promotion accepts **any valid legacy probe**, falling back to contract probes only when none survive ([jog_run.py:1719](utils/py/jog_run.py:1719)). Concrete input: one valid legacy probe plus a contract command `python3 -c ...`. Live promotion accepts the legacy probe; unconditional contract lint would falsely reject readiness. Extract/reuse the existing selection logic, including rejection when neither source supplies valid probes.

- **[Should] Make the process exit explicit.** Returning a numeric result from `_dry_run_preflight` alone cannot fix the CLI: the current caller prints its string and then returns normally ([jog_run.py:2322](utils/py/jog_run.py:2322)). Preserve diagnostic text alongside status, aggregate across selected items, and ensure the actual CLI exits nonzero. Missing helper and inbox identity mismatch must also count as unevaluated/nonzero ([jog_run.py:2210](utils/py/jog_run.py:2210)).

- **[Pass] Treat preflight exit 4 as nonzero readiness, explicitly labeled “already landed.”** Agree with [SPIKES.md:4](TESTS-RESULTS/2026-11-12+GH-1443/SPIKES.md:4): it means no new work is admissible for that item. Keep evaluating remaining selected items; do not drop or complete queue rows. Preserve live handling, which records completion for exit 4 ([jog_run.py:641](utils/py/jog_run.py:641)). This is a readiness refusal, not a provider escalation.

- **[Should] Keep checkpoint extraction narrowly static.** Validate option constraints and distinct roots ([jog_run.py:2333](utils/py/jog_run.py:2333)), clone/origin ([jog_run.py:2115](utils/py/jog_run.py:2115)), and publication cleanliness/development branch ([jog_run.py:2180](utils/py/jog_run.py:2180)). Do not move these checks earlier in **live** recovery: `begin()` intentionally resumes an unfinished journal before new-work admission ([jog_run.py:2143](utils/py/jog_run.py:2143)). Report remote freshness and recovery eligibility as unknown.

- **[Pass] Scope and preservation are sound.** Apply Marathon role validation only to target-aware, nonsimulated Marathon readiness; retain bare preview and simulation exemptions ([jog_run.py:2267](utils/py/jog_run.py:2267)). Existing preflight dry-run can fetch, create transient worktrees, and execute contract probes; describe the guarantee as **no Jog state writes**, not universally side-effect-free ([jog_run.py:2205](utils/py/jog_run.py:2205)). Capacity and environment remain unknown.

Static source review only; no tests, network, or provider calls performed.

**RECOMMENDATION:** Proceed after specifying exact promotion-selection reuse and observable CLI exit semantics; retain exit 4 as labeled nonzero readiness and leave live recovery untouched.
