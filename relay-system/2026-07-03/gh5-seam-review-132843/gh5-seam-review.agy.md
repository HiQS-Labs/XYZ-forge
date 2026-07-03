### 1. ANSWER
The contract-seam heuristic correctly integrates into `utils/marathon-plan.sh` without affecting wave sequencing, but it contains two algorithmic bugs in directory prefix/depth matching and a sorting bug in the CLI stdout reporter.

---

### 2. FINDINGS

#### 1. Heuristic correctness
* **Glob write-set (`src/schema/**`)**: `[Pass]` (cite [utils/marathon-plan.sh:383-385](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L383-L385)). `dirPrefixes` splits `"src/schema/**"` into `["src", "schema", "**"]`, pops the trailing glob segment, and computes cumulative prefixes, correctly yielding `["src", "src/schema"]`.
* **2-segment path (`bin/tick`)**: `[Pass]` (cite [utils/marathon-plan.sh:383-388](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L383-L388)). `dirPrefixes` returns `["bin"]`, which has no `"/"`, so `sharedSpine` correctly filters it out at line 398.
* **File at repo root (`README.md`)**: `[Pass]` (cite [utils/marathon-plan.sh:383-388](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L383-L388)). `dirPrefixes` returns `[]`, which has no prefixes and is correctly ignored.
* **Path with a trailing slash (`src/schema/`)**: `[Nit]` (cite [utils/marathon-plan.sh:384-385](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L384-L385)). If a write-set lists a directory with a trailing slash, `split("/").filter(Boolean)` yields `["src", "schema"]` and `parts.pop()` discards `schema` (treating it as a filename). This yields a false negative since `schema` is lost from the prefix tree.
* **Deeply nested shared dirs**: `[Should]` (cite [utils/marathon-plan.sh:398](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L398)). Comparing string lengths (`d.length > best.length`) as a proxy for depth is a bug. A shallower directory with a long name (e.g. `src/extremely-long-name`, length 24, depth 2) will override a deeper directory with a short name (e.g. `src/a/b/c`, length 9, depth 4), yielding the wrong "deepest" shared spine.

#### 2. False positives / negatives
* **Genuinely independent lanes (noise)**: `[Nit]` (cite [utils/marathon-plan.sh:685-687](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L685-L687)). The heuristic will flag unrelated files that share a subfolder (e.g. `src/components/Button.js` and `src/components/Input.js`). As this is advisory only, it is a reasonable trade-off, but may cause team noise.
* **Missing real coupling**: `[Nit]` (cite [utils/marathon-plan.sh:390-391](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L390-L391)). Real coupling between different folders (e.g. `src/producer/` and `src/consumer/`) will be missed by a folder-prefix heuristic.
* **Top-level restriction**: `[Pass]` (cite [utils/marathon-plan.sh:398](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L398)). Excluding top-level-only directories (checking `d.includes("/")`) is a reasonable proxy to prevent excessive noise under coarse directories like `src/`.
* **Same-wave limitation**: `[Pass]` (cite [utils/marathon-plan.sh:680-683](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L680-L683)). Evaluating only same-wave pairs is correct because serialized (cross-wave) lanes execute sequentially, eliminating concurrent execution conflicts.

#### 3. Advisory guarantee
* **Advisory guarantee**: `[Pass]` (cite [utils/marathon-plan.sh:679-702](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L679-L702)). The seam detection logic executes after wave packing and does not mutate `waves`, `deduped` states, or the computed exit code.

#### 4. Determinism
* **Deterministic comparison for `--check`**: `[Pass]` (cite [utils/marathon-plan.sh:889-894](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L889-L894)). `--check` performs a file comparison of the markdown output, which does not contain the CLI stdout `findings` report.
* **Stable tie-breaker**: `[Pass]` (cite [utils/marathon-plan.sh:398](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L398)). Ties are resolved by strict inequality (`>`), keeping the first encountered candidate, which is stable due to sequential loops.
* **CLI findings sorting**: `[Should]` (cite [utils/marathon-plan.sh:724](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L724)). The findings sort comparator `(order[a.severity] - order[b.severity]) || (a.type < b.type ? -1 : 1)` returns `1` when `a.type === b.type`, violating the strict weak ordering requirement of JavaScript's `sort()`. This leads to unstable, scrambled output order for findings of the same type and severity across different Node/V8 versions or array sizes.

#### 5. Only-proven-write-sets
* **Only-proven-write-sets**: `[Pass]` (cite [utils/marathon-plan.sh:684](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh#L684)). Zone-inferred lanes are correctly skipped via `if (!a.writeset.length || !b.writeset.length) continue`, ensuring keyword-inferred lanes (which default to `writeset: []`) cannot trigger phantom seams.

---

### 3. RECOMMENDATION
Merge with nits (fix the string length proxy in `sharedSpine` and the sort comparator bug in the CLI reporter).
