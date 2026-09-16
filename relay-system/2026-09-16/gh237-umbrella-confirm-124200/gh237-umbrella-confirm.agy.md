### ANSWER
The churn scan classification is a complete hallucination; the cited commits, shims, files, and issue context do not exist or map to entirely unrelated changes in this repository.

### FINDINGS

**F1: DISAGREE** [Blocker] — The cited commits (`8029c866`, `36694572`, `0b37c36f`, `c9c3f21b`) do not exist in the repository's history. Furthermore, there is no `deepseek-turn.py` file, and issue GH-114 was actually about `marathon-yaml` updates, not `pty + idle-kill`.

**F2: DISAGREE** [Blocker] — (A) The progress oracle at [utils/py/turn_diagnostics.py:326](file:///Users/noelsaw/.gemini/antigravity-cli/scratch/xyz-audit/utils/py/turn_diagnostics.py#L326-L328) explicitly groups hung network calls alongside locks/prompts; it deliberately groups rather than conflates them. (B) There is no `commandcode` shim, and #241 and #285 are unrelated PR merges.

**F3: DISAGREE** [Blocker] — There is no `muse-turn` shim in the repository. The phase split is fabricated: issues like #237 (swarm setup), #241 (yaml docs), and #369 (`find-doc.sh` fix) are completely unrelated to headless turn timeouts.

**F4: DISAGREE** [Blocker] — Since the underlying family, per-symptom patches, and specific shims are hallucinated, the remediation plan targets phantom code.

**MISSED:**
The classifier suffered severe cross-contamination from another codebase. It invented shims (`commandcode`, `muse`), fictitious files (`deepseek-turn.py`), and hijacked real, unrelated PR/issue numbers from this repository to build a fabricated narrative. 

### RECOMMENDATION
Do not file the umbrella issue or execute the marathon; the entire classification is based on a hallucinated issue cluster.
