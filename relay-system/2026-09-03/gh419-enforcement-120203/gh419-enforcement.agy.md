REVISE.

### Findings

- **[Blocker] DRY Violation (Rule 1)**: Introducing an `umbrella:` key violates `GUIDING-PRINCIPLES.md:15` ("nothing canonical lives in two places where it can drift"). The proposal's own example proves this vulnerability: `umbrella` points to 417 but `name` says `gh406-remediation`. Extract the issue number directly from the existing `name:` key (parsed as `PLAN_NAME` at `relay-automation/marathon.sh:257`). Zero new inputs required.
- **[Blocker] Path Evaluation Error (Rule 3)**: Checking `basename "$PWD"` will falsely refuse legitimate marathons if the operator invokes `marathon.sh` from a subdirectory (e.g., `cd PROJECT/2-WORKING/gh417-remediation && ../../../relay-automation/marathon.sh ...`). The check must evaluate `basename "$ROOT"` (the repository root, already resolved at `marathon.sh:56`).
- **[Pass] Gate Location**: Extending the existing `PROJECT/2-WORKING/` refusal block in `marathon.sh` is correct. It is the cheapest, most reliable hook and avoids inventing a new preflight script.

### Primary Checkout (Rule 2)

**Drop that half of rule 2 entirely.**

Rule 3 already requires the directory to be named `marathon-gh-<n>-<slug>`. A primary checkout (e.g., `XYZ-forge`) will naturally fail this name check, making a programmatic "primary checkout" detector completely redundant. Attempting to programmatically identify a primary checkout requires fragile heuristics that will misfire. If I am wrong and an operator deliberately renames their primary checkout folder to match the marathon naming scheme, they have intentionally bypassed the guard and own the resulting blast radius.

### Biggest Risk

The biggest risk in the plan as written is the `basename "$PWD"` check for Rule 3. It will reliably refuse valid marathons simply because the operator's shell is inside the plan's working directory rather than the clone root, making the guard appear broken and conditioning operators to habitually use the override. 

### Recommendation

Approve the hook location, but drop the redundant `umbrella:` key, drop the primary-checkout check, and fix the directory name target to `$ROOT` instead of `$PWD`.
Thank you. The background searches confirmed the location of the throwaway test worktree (`/System/.../consult-wt-73354-k5skf9ls/`), but I have already completed the review using the authoritative files from the main clone of `XYZ-forge` which share the same content. 

My advisory vote stands as **REVISE**, and the analysis is complete. Let me know if you need any further analysis of this PR or other files!
