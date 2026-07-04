I will wait for the `find` command to finish search execution.
### GH-48 Design Review Consultation Response

Having analyzed the design document [GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) and cross-checked it in detail against the code in [utils/marathon-plan.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh) (specifically [zoneOf](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L350-L373) and the wave-packing loop [utils/marathon-plan.sh:L643-690](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L643-L690)), here is my honest and direct consultation feedback.

---

### 1. Direct Answers

#### **1. Does the zone-rules schema generalize the current kernel/shim semantics without losing existing behavior?**
**No, there are critical gaps and asymmetries** that will break existing behavior or fail to support foreign configs if built strictly as described:
* **The `orchestrator_only` Omission (Blocker):** Currently, in the proven contract branch ([utils/marathon-plan.sh:354-363](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L354-L363)), if any contract artifact falls under an `orchestrator_only` path (`contract.lanes.orchestrator_only`), it is reclassified as `"kernel"`. The design doc completely omits `orchestrator_only` handling in its Phase 1 code changes. To generalize this, the zone classification engine must check if an artifact touches an `orchestrator_only` path, and map that item to the zone matching that prefix rather than hardcoding `"kernel"`.
* **The Sorting Tie-Breaker (Blocker):** The design details wave-packing generalizations but misses updating the tie-breaker logic in `active.sort` ([utils/marathon-plan.sh:659-660](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L659-L660)):
  ```javascript
  const zr = { independent: 0, shim: 1, kernel: 2 };
  if (zr[a.zone] !== zr[b.zone]) return zr[a.zone] - zr[b.zone];
  ```
  If custom zones (like `rebalance-OS`'s `"signed-helper"`) are introduced, `zr[a.zone]` becomes `undefined`, causing the sorting comparison to yield `NaN` and break sorting determinism. The sorting comparator must be generalized to dynamically map zone names to their config penalties or list order.
* **Hardcoded Text & Collision Map Rendering (Should):** The generated document's text for `"## The one safety rule"` ([utils/marathon-plan.sh:802-804](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L802-L804)) is hardcoded to this repo's kernel filenames. Additionally, the collision-map loop ([utils/marathon-plan.sh:810-814](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L810-L814)) is hardcoded to `["kernel", "shim", "independent"]`. Although the design mentions iterating the configured zone list for the collision map, it doesn't specify how the parallel-safety text (e.g. `❌ serialize`) is determined—it must be derived from the zone's `maxPerWave` rather than a string check.
* **RegExp Case-Insensitivity (Nit):** The hardcoded `SHIM_RE` uses the case-insensitive flag `/i`. If the configuration constructs RegExp objects dynamically (`new RegExp(zone.pathRegex)`), case-insensitivity must be handled (e.g. by default or via a config flag) to prevent silent path mismatch errors if uppercase paths exist.

#### **2. Is deferring the foreign ledger/queue-format adapter (idea #3) the right call?**
**Yes, deferring it is the correct call.** The rebalance-OS dogfood project already uses a shared signed helper script and does not require parsing a foreign ledger. Standardizing on standard `swarm-preflight` contracts as the integration format (as recommended in `ROADMAP.md`) is simpler, less brittle, and avoids over-engineering an adapter layer for different repository formats.

#### **3. Any gap in the resolution-order precedence that would surprise an operator?**
* **The Missing/Malformed Config Silent Fallback (Should):** If the `--target-root` contains a malformed `.marathon-plan-zones.json`, the script must **fail fast with a clear error** rather than silently falling back to the default `xyz` config. Falling back silently is a major operational trap because the planning will look correct but silently run under the wrong repo's safety constraints.
* **The `--target-root` Path Resolution (Should):** When looking for `<target-root>/.marathon-plan-zones.json`, the script must resolve this relative to the resolved `--target-root` (or the default `ROOT`). If target-root resolution isn't explicit, it might look up the configuration relative to the runner script's parent directories, breaking cross-repo execution.

---

### 2. Graded Findings

* **[Blocker] `active.sort` Tie-Breaker:** The hardcoded `zr = { independent: 0, shim: 1, kernel: 2 }` mapping inside the sorting comparator will return `NaN` for custom zones and break determinism.
* **[Blocker] `orchestrator_only` Reclassification:** The design ignores how the proven-contract path evaluates `orchestrator_only` guardrails; this must be generalized to map to matched configuration zones rather than hardcoding `"kernel"`.
* **[Should] Fail-Fast on Configuration Errors:** The runner must explicitly exit non-zero and report invalid or missing paths when `--zones-config` or a target-root configuration file is specified but can't be parsed, avoiding silent fallback to `xyz` defaults.
* **[Should] Generic Collision Map & Safety Rule:** The collision map safety text (`❌ serialize`) and the "safety rule" header text must be dynamically generated from the config constraints (i.e. `maxPerWave`) rather than hardcoding xyz's file paths.
* **[Nit] RegExp Flags:** The dynamic instantiation of regexes should compile with `/i` (case-insensitive) to match `SHIM_RE`'s original behavior.

---

### 3. Recommendation

**Build with named fixes** (reconcile `active.sort` tie-breaking, generalize `orchestrator_only` mappings, and implement fail-fast config validation).
