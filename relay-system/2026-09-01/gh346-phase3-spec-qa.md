---
Goal: QA the GH-346 Phase 3 spec — preferred-model resolution, harnesses.db as a dispatch tier
Date: 2026-09-01
Reviewer: agy
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate a **specification**, not an implementation. Nothing in Phase 3 is built yet; the
question is whether this design is right *before* anyone writes it.

Read in full:
- `PROJECT/1-INBOX/GH-346-PHASE-3-SPEC.md` — the spec under review
- `PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md` — Phases 0-2, shipped and approved,
  including the CORRECTION section describing what went wrong the first time
- `relay-system/2026-08-31/gh346-phase0-2-qa.md` — the round-1/round-2 QA of Phases 0-2. The lessons
  the spec claims to obey come from here; check that claim.

Supporting code the spec depends on:
- `utils/py/device_config.py` — the existing 3-tier resolver the prefs file is modelled on
- `utils/py/model_alias.py` + `relay-automation/resolve-model-alias.sh` — the fallback discipline
  and the name normalizer the spec wants to reuse rather than reimplement
- `utils/py/harness_app.py` (`models`, `invocation_logs`) — what tier 3 would read
- `utils/py/marathon_drive.py` `route_agent` — the lane set the spec says to derive from
- `.gitattributes:36-37`, `utils/releases-merge-resolve.sh` — the merge-resolver asymmetry the
  reversibility argument turns on

**This is a REVIEW turn. Do not edit any file except this relay thread.** Cite `file:line`.

## The operator's requirement, verbatim

> "I want a preferences file that specifies a single model name that maps to my preferred harness,
> router, and model unless I provide the full harness → gateway → model path as a manual override.
> So if I say I want to do a `relay-xyz with Qwen 3.8 max` it knows to use DeepSeek harness →
> OpenRouter → Qwen 3.8 max. Or if I say `relay-xyz with GLM 5.3 max` it knows to use CommandCode →
> GLM 5.3 max."

Judge the spec against **that**, not against the issue's original proposals A/B/C.

## Questions

1. **Does the design actually satisfy the requirement?** Walk both named examples end to end
   through the four resolution tiers. Does `"qwen 3.8 max"` reach DeepSeek → OpenRouter →
   `qwen/qwen3.8-max`, and `"glm 5.3 max"` reach Command Code → `zai-org/glm-5.3`? Name any step
   where the spec is under-specified enough that two implementers would build different things.

2. **The reversibility argument is load-bearing — attack it.** The spec permits `harnesses.db` to
   feed dispatch *only* as a skippable tier 3, on the grounds that `releases.db` has
   `utils/releases-merge-resolve.sh` and `harnesses.db` has none, so a hard dependency would be a
   one-way door during a conflicted merge. Verify both halves (resolver exists / does not exist),
   and say whether the conclusion follows. Is "fallback tier, never a dependency" genuinely
   reversible, or is there a path where tier 3 silently becomes load-bearing anyway?

3. **Tier 3 reads `invocation_logs` — is that sound?** The spec proposes routing partly on "this
   model has actually run on this harness before." Does empirical history make a good routing
   source, or does it pin a one-off experiment as a default? Note the live data: `commandcode` has
   rows for four different models including a two-row `stealth/ox-alpha` experiment. Would this
   design route on that?

4. **Does it avoid becoming the eleventh allowlist?** Phases 0-2 found the shipped gateway set
   enumerated in TEN hand-maintained places; three were invisible to careful reading and surfaced
   only when an existing test failed. The spec says the resolver must derive the lane set from
   `route_agent`'s source. Is that sufficient, or does the preferences file itself become a new
   curated list that drifts — and if so, what makes it fail loudly?

5. **The fallback chain must never block a turn.** Four tiers, each skippable, floor = today's
   literal. Is there any combination — missing prefs file, malformed YAML, unmatched name, locked
   or corrupt DB, absent alias table — where a turn fails instead of degrading? A turn that cannot
   run because a *preference* is unreadable would be strictly worse than today.

6. **Phase 3c's proof is the one that closes a standing caveat.** QA on Phases 0-2 established that
   agy and codex record a *declared* default, not a dispatched one, and set a standing condition:
   the ROI checkpoint item "telemetry matches dispatch for all 8 gateways" must not be ticked while
   that holds. Does 3c's stated proof actually close it, or does it leave a gap?

7. **Scope and sequencing.** Is 3a/3b/3c the right split? Is anything here that should be its own
   issue, or missing and needed? Specifically: is `harnesses-merge-resolve.sh` a prerequisite that
   should be promoted out of a parenthetical, and is the cache (proposal A) correctly folded in
   rather than built separately?

8. **The four open questions at the end of the spec.** Answer them with a recommendation each,
   especially #1 (separate `model-prefs.yml` vs extending `device_config.json`) and #3 (does
   `effort` belong in a profile when not every gateway has one).

9. **Anything wrong, missing, over- or under-engineered.** Be concrete. If the design is sound, say
   so plainly rather than manufacturing findings — but if the operator would be better served by a
   simpler shape, say that instead.

Write your verdict below. Set `STATUS: Approved` if the spec is ready to implement, or leave it
`Open` with findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
