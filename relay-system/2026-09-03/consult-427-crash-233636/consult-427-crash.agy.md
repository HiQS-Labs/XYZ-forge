### 1. Disposition of PR #427

**ANSWER:** Split the PR to secure the immediate value, and rewrite the source scanner in Python.

**FINDINGS:**
- **[Blocker]** Intermittent signal deaths (SIGSEGV/SIGABRT) in Bash 3.2 are fundamentally incompatible with deterministic CI. While `utils/pdda/pdda.sh` successfully uses `done < <(...)` process substitutions for small doc sets (e.g., `utils/pdda/pdda.sh:1079` and `1147`), scaling this to per-line pipelines across the entire `src/` tree overwhelms macOS Bash IPC.
- **[Should]** Split the PR. Extract and land the artifact-check and ADR restorations (`decisions/2026-06-18-epoch-fencing.md`, etc.) immediately. This unblocks the pipeline and resolves the original GH-414 defect.
- **[Should]** Re-implement the source-comment scanner in Python (`utils/py/`) in a follow-up PR. Python is the authoritative Tier-A runtime for a reason: it scales effortlessly for tree-wide regex extractions and bypasses shell-based process limitations entirely. 

**RECOMMENDATION:** Land the artifact check and restored ADRs today; rebuild the source scanner in Python tomorrow.

---

### 2. Was the goal invalid?

**ANSWER:** The goal was over-broad in its polarity; source comments and shipped artifacts have fundamentally different strictness contracts.

**FINDINGS:**
- **[Pass]** The core intent (preventing documentation drift) is highly valid, but the implementation hit a category it didn't model: workspace state.
- **[Should]** Fail-closed on source comments is the wrong polarity. Source code contains hypotheses, examples, and references to local/generated state (like `src/project.js` citing `.tick/STATE.md`). The `git check-ignore` exemption is a clever band-aid, but it highlights the design tension: source code is a living workspace, not a rigid dependency graph.
- **[Should]** The line between "fine" and "over-broad" is the build boundary. The artifact check represents the shipped product and *must* fail-closed. The source scan evaluates developer context and should be warn-only hygiene.

**RECOMMENDATION:** Downgrade the source-comment scan to a WARN-only hygiene check, while keeping the artifact-check FAIL-CLOSED.

---

### 3. Amended acceptance criteria

**ANSWER:** Explicitly model pristine-clone determinism, generated state exemptions, and appropriate Tier-A tooling.

**FINDINGS:**
- **[Should]** The criteria must differentiate between artifact invariants and source hygiene to avoid the false-positive class encountered here.
- **[Should]** The criteria must mandate pristine-clone determinism without being masked by local dirty-tree state.

**RECOMMENDATION:**
Update the GH-414 Acceptance section to the following:
> - **Artifact scan (Fail-Closed):** A path-shaped reference in the built artifact citing a non-existent path FAILS the check.
> - **Source scan (Warn-Only):** A comment in a source file citing a non-existent tracked path WARNS.
> - **Generated state:** The source scan MUST NOT flag citations of runtime-generated or untracked state (e.g., paths matching `git check-ignore`).
> - **Determinism:** The check MUST be deterministic on a fresh, pristine clone, and MUST execute reliably across platforms without signal deaths (e.g., using Python for tree-wide scanning).
