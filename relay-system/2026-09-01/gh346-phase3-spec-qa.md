---
Goal: QA the GH-346 Phase 3 spec — preferred-model resolution, harnesses.db as a dispatch tier
Date: 2026-09-01
Reviewer: agy
NEXT: Author
STATUS: Open (with findings)
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

## QA Findings

1. **Does the design actually satisfy the requirement?**
   **No.** First, the operator requested Command Code as the gateway ("CommandCode → GLM 5.3 max"), but the spec's provided YAML profile explicitly wires `"glm 5.3 max"` to `gateway: openrouter` (`GH-346-PHASE-3-SPEC.md:68`), which routes to Command Code → OpenRouter → `zai-org/glm-5.3`. This directly contradicts the requirement. 
   Second, the name matching via `resolve-model-alias.sh` is fundamentally under-specified. The existing bash script parses a flat `alias: canonical` text format line-by-line via `sed`/`read` (`resolve-model-alias.sh:65-74`). It is entirely incapable of parsing the nested dictionary structure proposed in `model-prefs.yml`. Two implementers would either silently break the script, write an unspecified adapter, or fail entirely.

2. **The reversibility argument is load-bearing — attack it.**
   Both halves are factually true: `releases.db` has a resolver (`utils/releases-merge-resolve.sh`); `harnesses.db` has none (`ls utils/harnesses-merge-resolve.sh` fails). The conclusion that Tier 3 is reversible follows *only* if the fallback degrades gracefully and isn't leaned on. However, if Tier 3 becomes the primary routing mechanism users rely on, and the DB conflicts or corrupts, degrading to Tier 4 (shim literals) means turns will unexpectedly run with completely incorrect model defaults instead of failing loudly. This makes the system silently do the wrong thing, becoming a load-bearing one-way door operationally.

3. **Tier 3 reads `invocation_logs` — is that sound?**
   **No.** The `invocation_logs` data contains one-off experiments like `stealth/ox-alpha`. Using empirical history for routing means a single experimental run could permanently pin that model as the new default for that harness. This incorrectly turns history into policy and is inherently unsound for routing.

4. **Does it avoid becoming the eleventh allowlist?**
   **No.** The operator-owned `model-prefs.yml` simply becomes the eleventh hand-curated allowlist. Since the design explicitly states every tier falls through (Tier 2 to 3 to 4) without blocking, there is no mechanism for `model-prefs.yml` to fail loudly if a model ID changes or a harness is deprecated. It simply drifts silently.

5. **The fallback chain must never block a turn.**
   The spec completely ignores parser failures. While a missing file falls through safely, **malformed YAML** in `model-prefs.yml` will cause a Python or Bash parser to crash or throw an exception, instantly halting the resolver. This will completely block a turn because a preference is unreadable, making it strictly worse than today.

6. **Phase 3c's proof is the one that closes a standing caveat.**
   The caveat notes telemetry records a *declared* default, not a dispatched one. Phase 3c's proof ("telemetry model == dispatched model for all 8 gateways **with the var unset**") leaves a glaring gap. It misses the case where the variable *is* set (Tier 1 override). The proof must assert the match whether the var is set *or* unset.

7. **Scope and sequencing.**
   - Phase 3a is overloaded. The cache (Proposal A) is completely orthogonal and should not be folded into 3a.
   - The YAML parsing adapter/wrapper for `resolve-model-alias.sh` is entirely missing from the scope.
   - `harnesses-merge-resolve.sh` should be its own issue and promoted out of a parenthetical if Tier 3 were kept.

8. **The four open questions at the end of the spec.**
   1. **`model-prefs.yml` vs `device_config.json`:** Use `device_config.json`. It already manages defaults in the exact same seam. Do not introduce an 11th file.
   2. **`invocation_logs` for routing:** Unsound. Do not use experimental history for defaults.
   3. **`effort` in profile:** Effort is gateway-specific (`COMMANDCODE_REASONING_EFFORT`, `AGY_REASONING_EFFORT`). It does not belong in a generic profile unless properly namespaced per-gateway.
   4. **Deprecating 8 env vars:** Keep them as Tier 1 overrides (as the spec already intends). Deprecating them would break existing scripts without providing a cleaner override mechanism.

9. **Anything wrong, missing, over- or under-engineered.**
   - **Over-engineered:** Tier 3 (`harnesses.db`) adds unnecessary complexity and actively introduces bugs by routing on experiments. Drop Tier 3 entirely.
   - **Missing:** A strategy for parsing the nested YAML using the flat-file `resolve-model-alias.sh` script.
   - **Wrong:** The YAML example incorrectly routes GLM 5.3 to OpenRouter instead of Command Code.

**Verdict**: The spec needs to be rewritten. Drop Tier 3, move profile configuration into `device_config.json` instead of a new YAML file, use a Python-based resolver to cleanly parse it, and pass the profile alias to `resolve-model-alias.sh` strictly for string normalization, not file reading.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
