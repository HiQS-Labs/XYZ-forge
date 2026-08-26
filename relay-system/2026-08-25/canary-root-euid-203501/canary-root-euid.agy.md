I have launched a search to locate the repository files and will inspect them as soon as the search completes.
I am waiting for the file search to complete.
I will wait for the search to complete.
### 1. Direct Answer

**Choose Option B (targeted skip when `EUID=0` at the assertion level).**

The failures in [`test/gh50-sandboxed-git-guard.sh`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/gh50-sandboxed-git-guard.sh#L55-L77) and [`test/security-scan.sh`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/security-scan.sh#L235-L260) are purely **test-fixture simulation artifacts**, not production guard defects. The tests use `chmod a-w` and `chmod 000` to mock filesystem unwritability/unreadability, but POSIX root (`EUID=0`) bypasses discretionary access control (DAC) permission bits via `CAP_DAC_OVERRIDE`. 

In production, root *can* write to `0444` files and read `0000` files without error or data corruption. Trying to make production guards "fail-closed" for root (Option A) would require inspecting mode bits via `stat` and rejecting operations that the kernel and Git would otherwise execute completely safely—breaking legitimate root execution in containerized environments. Option B accurately skips only the DAC-dependent negative assertions under `EUID=0` while preserving positive controls and full coverage on developer machines (macOS) and non-root runners.

---

### 2. Graded Findings

#### `[Blocker]` Option A introduces broken semantics and false rejections in production code
* **Reference:** [`utils/git-sandbox-guard.sh:66-79`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/utils/git-sandbox-guard.sh#L66-L79), [`relay-automation/hooks/security-scan.sh:168-187`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/relay-automation/hooks/security-scan.sh#L168-L187)
* **Rationale:** 
  * `git-sandbox-guard.sh` was written for GH-50 to protect against partial branch switches when Git index/worktree updates succeed but `.git/config` writes fail (e.g. in macOS seatbelt sandboxes or read-only volume mounts). Its probe (`: >> "$config"`) tests *actual kernel writability*. If root runs `git switch --track` on a `0444` config file, Git writes and updates the file successfully without half-applying. Refusing based on mode bits would falsely block safe operations under root (e.g., Docker container agents).
  * If a sandbox or mount *genuinely* denies root writes (`mount -o ro`, `EPERM`, `EROFS`), the existing probe `: >> "$config"` **already fails naturally** under root.
  * In `security-scan.sh`, `_grep_or_fail_loud` reports `[scan-error]` when `grep` exits `> 1` (I/O or permission error). For root, `grep` reads `0000` files cleanly. Modifying the production scanner to fabricate a scan-error for readable `0000` files would cause the scanner to abort scanning readable content where actual secrets might reside.

#### `[Should]` Option B must be scoped to specific assertions, not whole suite skips
* **Reference:** [`test/gh50-sandboxed-git-guard.sh:55-88`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/gh50-sandboxed-git-guard.sh#L55-L88), [`test/security-scan.sh:235-260`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/security-scan.sh#L235-L260), [`test/gh342-sentinel-debug-log-python.sh:237-250`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/gh342-sentinel-debug-log-python.sh#L237-L250)
* **Rationale:** 
  * In `test/gh50-sandboxed-git-guard.sh`, only the negative `chmod a-w` assertions (lines 62–77) should be skipped when `${EUID:-$(id -u)} -eq 0`. The writable control (lines 80–87) must still execute and pass.
  * In `test/security-scan.sh`, only the `chmod 000` fixture case (lines 251–256) should be skipped under root. The remaining 33 checks (including real-repo scan and all pattern rules) must continue to run.
  * This matches existing precedent in [`test/gh342-sentinel-debug-log-python.sh:237-250`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/gh342-sentinel-debug-log-python.sh#L237-L250), which explicitly does:
    ```python
    if os.geteuid() != 0:
        ...
    else:
        # Root defeats mode bits — say so rather than reporting a pass this run did not earn.
        print("  SKIP: 5b read-only-dir case (running as root; mode bits do not apply)")
    ```

#### `[Should]` Status quo permanently blinds the Linux portability canary
* **Reference:** [`.github/workflows/ci.yml:47-70, 210-237, 484-498`](file:///Users/noelsaw/.github/workflows/ci.yml#L47-L70)
* **Rationale:** Because the canary runs with `continue-on-error: true`, an existing red status hides all real Linux drift (such as GNU vs. BSD `sed`, unhandled exit codes, or missing dependencies). Restoring the canary to a clean green baseline ensures that any step failure flips `canary-ubuntu` to failure and emits `PORTABILITY-CANARY: drift` only on genuine regressions.

#### `[Nit]` Keep the "advisory, never breakage" posture in CI workflow
* **Reference:** [`.github/workflows/ci.yml:210-236`](file:///Users/noelsaw/.github/workflows/ci.yml#L210-L236), [`test/ci-workflow.sh:242-271`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/ci-workflow.sh#L242-L271)
* **Rationale:** macOS is the sole supported platform and promotion boundary ([`ci.yml:114`](file:///Users/noelsaw/.github/workflows/ci.yml#L114), GH-509). Furthermore, [`test/ci-workflow.sh:242`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/test/ci-workflow.sh#L242) explicitly asserts `continue-on-error: true` for the Ubuntu canary. Making the job a blocking gate would violate the contract and fail CI meta-assertions.

#### `[Pass]` Production guard implementations are correct as written
* **Reference:** [`utils/git-sandbox-guard.sh:66-79`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/utils/git-sandbox-guard.sh#L66-L79), [`relay-automation/hooks/security-scan.sh:176-187`](file:///Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/relay-automation/hooks/security-scan.sh#L176-L187)
* **Rationale:** Probing actual file append capability (`: >> "$config"`) and testing command exit codes (`grep` rc `> 1`) tests real operational capability rather than making fragile assumptions about DAC mode bits.

---

### 3. Recommendation

**Implement Option B by adding explicit `EUID == 0` guards to skip only the `chmod`-based negative assertions in `test/gh50-sandboxed-git-guard.sh` and `test/security-scan.sh`, leaving production guard scripts unchanged.**
