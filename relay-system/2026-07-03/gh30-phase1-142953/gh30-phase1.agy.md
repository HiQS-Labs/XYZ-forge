# Review: GH-30 Phase 1 — transcript-root resolver (PR #105)

### (1) Direct Answer
The resolver is functional and passes the existing test suite, but it contains a **[Blocker] path traversal vulnerability** where certain target roots (e.g., those resolving to `..` or `.`) produce directory-traversal slugs that escape the namespaced `relay-system` container. It also contains a minor remote parsing bug (collapsing to directory basenames when remote URLs have trailing slashes) and minor double-slash formatting issues.

---

### (2) Graded Findings

#### 1. Regression Safety
* **Finding**: **[Nit]** Potential double-slash output if `target_root` has a trailing slash.
* **Citation**: [`relay-automation/relay-turn-lib.sh:72`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L72)
* **Details**: If `target_root` has a trailing slash (e.g., `/foo/bar/` or `/`), `printf '%s/relay-system'` prints `/foo/bar//relay-system` or `//relay-system`. Under POSIX, paths starting with a double slash can have implementation-defined semantics.
* **Fix**: Strip any trailing slash from `target_root`:
  ```bash
  local tr="${target_root%/}"
  [[ -z "$tr" ]] && tr="/"
  ```

#### 2. Fail-Loud, Never Silent-Fallback
* **Finding**: **[Pass]** No silent fallback on invalid `XYZ_ARCHIVE_ROOT`.
* **Citation**: [`relay-automation/relay-turn-lib.sh:76-89`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L76-L89)
* **Details**: The absolute path check, existence check, and git repo validation correctly print warning/error messages to `stderr` (`>&2`) and return exit code `1` immediately without printing anything to `stdout`.

#### 2b. `set -u` / `set -e` Safety
* **Finding**: **[Pass]** Safe variable expansion and split variable declarations.
* **Citation**: [`relay-automation/relay-turn-lib.sh:71`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L71), [`98`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L98), [`103`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L103)
* **Details**: Safe parameter expansion `${XYZ_ARCHIVE_ROOT:-}` prevents unbound variable errors under `set -u`. In `rtl_repo_slug`, local variables are declared first (`local target_root="$1" url slug`) and assigned separately, which ensures that exit codes of subshells (like `git` or `basename`) are not masked by the `local` keyword under `set -e`.

#### 3. Slug Correctness & Injection Safety
* **Finding**: **[Blocker]** Path traversal via `..` or `.` directory basenames.
* **Citation**: [`relay-automation/relay-turn-lib.sh:103-104`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L103-L104)
* **Details**: If `target_root` basename resolves to `..` or `.` (e.g. `/foo/bar/..` or `/foo/bar/.`) and there is no origin remote, the `tr` sanitize step preserves dots since `.` is in `A-Za-z0-9._-`. 
  - A slug of `..` outputs `$XYZ_ARCHIVE_ROOT/relay-system/..` (resolving to `$XYZ_ARCHIVE_ROOT`), allowing transcript writers to escape the `relay-system/` base containment.
  - A slug of `.` collapses the namespace to `$XYZ_ARCHIVE_ROOT/relay-system`, causing namespace collisions for any repositories that default to `.`.
* **Fix**: Force-rewrite the slug to a safe name (e.g. `repo`) if it evaluates to `.` or `..`.

* **Finding**: **[Should]** Remote URL parsing fails on trailing slashes.
* **Citation**: [`relay-automation/relay-turn-lib.sh:101`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L101)
* **Details**: If the origin remote URL has a trailing slash (e.g., `https://github.com/org/foo/`), `slug="${url##*/}"` evaluates to the empty string, falling back to local directory basename.
* **Fix**: Strip trailing slashes before parsing:
  ```bash
  url="${url%/}"
  ```

* **Finding**: **[Nit]** Hyphen-prefixed slugs can trigger flag options.
* **Citation**: [`relay-automation/relay-turn-lib.sh:104`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L104)
* **Details**: A slug starting with a hyphen (e.g. `-myrepo`) is allowed. If a caller later does `git -C <slug>` or `cd <slug>` without `--` guards, it can be interpreted as a command flag.
* **Fix**: Strip leading hyphens or replace them with underscores.

#### 4. Determinism
* **Finding**: **[Pass]** Deterministic output for absolute paths.
* **Citation**: [`relay-automation/relay-turn-lib.sh:98`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh#L98)
* **Details**: The resolver uses `git -C` which handles absolute targets cleanly and is independent of the caller's CWD. Relative target paths (e.g. `.`) will inherently resolve relative to the caller's CWD, which is expected behavior. No random or time-dependent state is used.

#### 5. Test Coverage Gaps
* **Finding**: **[Should]** Missing critical validation test cases.
* **Citation**: [`test/archive-root.sh`](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/archive-root.sh)
* **Details**: The test script misses checking:
  - Trailing slash targets (`/foo/bar/` and `/`)
  - Target paths resolving to `.` and `..` (the blocker path-traversal cases)
  - Target paths with space characters (e.g., `/foo/my repo`)
  - SCP-style remote URLs (`git@github.com:org/foo.git`)
  - Trailing slash remote URLs (`https://github.com/org/foo/`)

---

### (3) Recommendation
**RECOMMENDATION:** Changes required (address the Blocker path-traversal vulnerability and add missing test coverage before merging).
