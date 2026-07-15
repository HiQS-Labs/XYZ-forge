### 1. Answer

1. **Correctness**: No fatal execution bugs found. 
   - **Set -e & Failure Capture**: The pattern `marathon_log="$(...)" || marathon_rc=$?` ([utils/hq/rollup.sh:117](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L117)) is correct and safe under `set -euo pipefail`. Because it is part of an OR list (`||`), a non-zero exit from the command substitution will not abort the script and instead correctly captures both the logs and the exit code.
   - **AWK Demotion & Frontmatter Stripping**: The awk logic ([utils/hq/rollup.sh:123-130](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L123-L130)) handles edge cases perfectly:
     - The first `---` blocks are correctly identified via `NR==1` ([utils/hq/rollup.sh:124](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L124)) to strip only the frontmatter. Any subsequent `---` in the markdown body (e.g., horizontal rules) are preserved.
     - Code block boundaries are tracked via `infence` ([utils/hq/rollup.sh:127](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L127)), preventing demotion of `#` comments inside script blocks.
     - Only lines matching `/^#+ /` ([utils/hq/rollup.sh:128](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L128)) are demoted, which correctly avoids changing blockquotes or comments.

2. **Test Coverage**: There is a test gap in [test/hq-rollup.sh](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/test/hq-rollup.sh). It tests Case A (populated roadmap) and Case B (empty roadmap), but never asserts Case C—the failure path of `marathon-scan.sh` (where it exits non-zero and prints the `_marathon scan failed..._` error banner).

3. **Design**: Verbatim-appending is the correct decision here. A marathon preflight readiness scan outputs critical, deterministic verdicts (e.g. `ready`, `blocked-not-promoted`, `stale-already-landed`). Passing these through an LLM synthesis pass introduces high risks of hallucination, omission, or paraphrasing a warning into a false success.

4. **Merge Readiness**: **Mergeable**. However, I recommend executing a minor follow-up to address the test gap, clean up temp files via `trap`, and avoid a static path collision in `/tmp`.

---

### 2. Graded Findings

* **[Should]** [test/hq-rollup.sh](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/test/hq-rollup.sh): Add a Case C to the rollup test script that stubs a failing run of `marathon-scan.sh` (e.g. exit code 2) and asserts that the final rollup report contains the appropriate failure banner: `_marathon scan failed (exit 2)..._` ([utils/hq/rollup.sh:132](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L132)).
* **[Should]** [utils/hq/rollup.sh:115-134](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L115-L134): Add an exit `trap` to ensure that `MARATHON_TMP` is successfully deleted if `rollup.sh` crashes or is interrupted before reaching `rm -f` at line 134.
* **[Nit]** [utils/hq/rollup.sh:18](file:///Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/utils/hq/rollup.sh#L18): Change the static `/tmp/hq-raw-rollup.txt` path to a random `mktemp` path. If multiple instances of `rollup.sh` run concurrently on the same machine, they will collide on this static name.

---

### 3. Recommendation

Merge the PR as-is to resolve GH-192, and immediately address the temp file safety and test coverage gaps in a minor follow-up commit.

consult: [FAIL] agy transcript cited the real repo root (/Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm) instead of the isolation worktree. This is a known agy isolation breach (grounding escaped $WT). Failing the turn to prevent a silent breach.
