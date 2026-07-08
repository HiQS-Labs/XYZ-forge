### 1. ANSWER
Several key Git commands and behaviors documented in [WORKTREE-SAFETY.md](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/WORKTREE-SAFETY.md) are technically inaccurate. Specifically, `git branch -D` on a branch active in another worktree is strictly blocked by Git, stashes are stored globally rather than worktree-locally, and `git gc` is worktree-aware. Furthermore, the document has a gap regarding the selective `.git` corruption (GH-177) failure mode, and misses key footguns like untracked files preventing worktree removals and submodule movement constraints.

---

### 2. GRADED FINDINGS

#### **[Should] Technical Accuracy: Branch Deletion Prevention**
*   **Location:** [WORKTREE-SAFETY.md:L212-216](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/WORKTREE-SAFETY.md#L212-216)
*   **Issue:** The guide claims `git branch -D <branch>` force-deletes a branch checked out in another worktree, leaving that worktree in detached `HEAD`.
*   **Correction:** Git explicitly blocks branch deletion (including force-deletion with `-D`) if the branch is active in any linked worktree. It will fail with: `error: cannot delete branch '<branch>' used by worktree at '<path>'` (exit code 1).
*   **Proposed Edit:**
    ```diff
    -git branch -D feature-branch  # force-deletes, leaves worktree in detached HEAD
    -
    -**Why it's dangerous:** Force-deleting the branch leaves the worktree in a detached HEAD state.
    +# Force-deleting still fails if active in another worktree:
    +git branch -D feature-branch  # Fails with error: cannot delete branch...
    +
    +**Why it's dangerous:** Attempting to force-delete the branch will result in a hard command failure. 
    +To delete, you must first switch that worktree to a different ref or detach its HEAD.
    ```

#### **[Should] Technical Accuracy: Global Stash Scope**
*   **Location:** [WORKTREE-SAFETY.md:L228-243](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/WORKTREE-SAFETY.md#L228-243)
*   **Issue:** The guide states that stashes are stored worktree-locally under `.git/worktrees/<name>/refs/stash`.
*   **Correction:** Stashes are stored globally in `.git/refs/stash` and are shared across all worktrees. The real danger is that running `git stash pop` in the wrong worktree applies changes to the wrong files/branch and consumes the global stash.
*   **Proposed Edit:**
    ```diff
    -git stash pop  # NOPE, stashes are per-worktree!
    -**Why it's dangerous:** Stashes are stored in the worktree's own refs (`.git/worktrees/<name>/refs/stash`), not in the shared refs. Popping in the wrong worktree gets you a different stash or nothing.
    -**Correct mental model:** Stashes are worktree-local. Use `git stash list` in each worktree to see what's actually there.
    +git stash pop  # Danger: applies the shared stash to the current worktree!
    +**Why it's dangerous:** Stashes are shared globally in `.git/refs/stash`. Popping a stash in the wrong worktree will consume it and apply changes to the incorrect working directory, causing confusion or conflicts.
    +**Correct mental model:** Stashes are global. Use unique stash messages to keep track of which worktree they belong to.
    ```

#### **[Should] Technical Accuracy: Git GC Worktree Awareness**
*   **Location:** [WORKTREE-SAFETY.md:L149-153](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/WORKTREE-SAFETY.md#L149-153)
*   **Issue:** The guide claims `git gc` only considers refs from the worktree it's run in, posing a risk of deleting objects needed by other worktrees.
*   **Correction:** Modern Git is worktree-aware. `git gc` and `git prune` scan refs and logs of all registered worktrees under `.git/worktrees/` before pruning unreachable objects.
*   **Proposed Edit:**
    ```diff
    - - git gc only considers refs from the worktree it's run in, but objects might be reachable from another worktree's refs
    + - Modern Git is worktree-aware; git gc scans refs across all registered worktrees. The risk occurs if a worktree directory is deleted manually without pruning, leading Git to lose track of reachable objects in the unregistered tree.
    ```

#### **[Should] Gap Analysis: Addressing Selective `.git` Corruption (GH-177)**
*   **Issue:** The guide does not provide any check or resolution steps for selective `.git` folder gutting.
*   **Proposed Addition (add as Section 11):**
    ```markdown
    ## 11. Selective `.git` Corruption & Skeleton Loss (The GH-177 Scenario)
    
    **Scenario:** Core `.git` files (`HEAD`, `objects/`, `refs/`, `index`) are deleted or corrupted, but configuration and metadata (`config`, `hooks/`, `worktrees/`) survive.
    
    **Prevention & Diagnostic Checklist:**
    1. Verify that `.git/HEAD`, `.git/objects/`, `.git/refs/`, and `.git/config` all exist before executing repository tasks.
    2. Never exclude `objects/` or `refs/` from backups while keeping other metadata folders.
    
    **Recovery Steps:**
    1. **Reinitialize Skeleton:** Run `git init`. This is safe to run on an existing repository and restores the missing skeleton (like `HEAD`) without overwriting your `config` or `hooks/`.
    2. **Repopulate History:** Run `git fetch origin` to download remote refs and repopulate `.git/objects/`.
    3. **Re-link Worktrees:** Run `git worktree prune` to clear metadata stubs that lost valid directory mappings.
    ```

#### **[Should] Missing Footguns: Untracked Files and Submodule Limitations**
*   **Proposed Addition (add as Section 12):**
    ```markdown
    ## 12. Removing and Moving Complex Worktrees
    
    *   **Untracked Files:** `git worktree remove` will fail if there are any untracked or modified files in the worktree. Scripts must use `git worktree remove --force` if they intend to discard changes.
    *   **Submodules:** `git worktree move` does not support moving worktrees containing submodules because the relative links to the main `.git/modules` directory will break.
    ```

#### **[Nit] Technical Accuracy: `git worktree move` Version Support**
*   **Location:** [WORKTREE-SAFETY.md:L106](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/WORKTREE-SAFETY.md#L106)
*   **Issue:** The guide notes that Git 2.34+ is required for `git worktree move`.
*   **Correction:** `git worktree move` was introduced in Git 2.17.0. However, Git 2.30.0 introduced `git worktree repair` which is critical for restoring broken paths.
*   **Proposed Edit:**
    ```diff
    -# Git 2.34+ supports moving
    +# Git 2.17+ supports moving. Git 2.30+ supports 'git worktree repair' to restore broken path connections.
    ```

---

### 3. RECOMMENDATION
Update [WORKTREE-SAFETY.md](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/WORKTREE-SAFETY.md) to correct false claims regarding branch deletion, stash isolation, and GC reachability, and add dedicated sections for selective `.git` directory recovery (GH-177) and removal/movement blockers.
