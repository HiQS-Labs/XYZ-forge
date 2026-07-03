---
**Task output:**
```
/Users/noelsaw/Documents/GH Repos/bottom-line-review/src/rebalance/ingest/index_ops.py
/Users/noelsaw/Documents/GH Repos/bottom-line-review/temp/bottom-line-review/src/rebalance/ingest/index_ops.py
```
---

### 1. Direct Answer
The integration plan is logically structured around the "observe-first" pattern, but contains **two Blocker-level design flaws**: (a) it records the repository version pin in a machine-local, uncommitted file (`registry.tsv`), breaking repository portability and reproducibility; and (b) it directly couples XYZ to Rebalance's SQLite database file for Seam #3, violating the mutual independence and data-only coupling invariants. Additionally, it introduces an **artificial scheduling block** in Phase 0.

---

### 2. Graded Findings

#### **[Blocker] Version Pin Portability & Registry Ambiguity (Phase 1, Seam #2)**
* **Issue:** The plan states that `registry.tsv` records the pinned version of the XYZ harness and that updates are PR-gated. However, as documented in [PDDA-INSTALL.md:131](file:///Users/noelsaw/Documents/rebalance-OS/utils/pdda/PDDA-INSTALL.md#L131), `registry.tsv` is machine-local (`~/.config/xyz/registry.tsv` or `~/.config/pdda/registry.tsv`) and is **never committed to git**. 
* **Impact:** A fresh checkout of the `rebalance-OS` repo on a different machine will have no record of the pinned commit, violating portability (Guiding Principle 10). Furthermore, the plan conflates `~/.config/xyz/registry.tsv` (owned by XYZ) and `~/.config/pdda/registry.tsv` (owned by PDDA), which are separate files with different columns and owners.
* **Remediation:** Phase 1 must record the pinned commit in a committed repository file (e.g., `.xyz-pin` or in `pyproject.toml`), which `rebalance doctor` and `xyz-sync check` can diff against the machine-local install registry.

#### **[Blocker] Direct SQLite Database Coupling (Phase 3, Seam #3)**
* **Issue:** The plan mechanism for Seam #3 relies on writing into a "net-new `roadmap_signals` table" in Rebalance's SQLite database, which the XYZ tick-lane consumer reads.
* **Impact:** To read this table, XYZ must query Rebalance's SQLite database file directly. This violates Invariant 1 (Mutual independence) and Invariant 2 (Data-only coupling). If the Rebalance database is locked during a sync operation, XYZ will block/fail; if the SQLite file path changes (resolved dynamically via `REBALANCE_DB`), XYZ breaks.
* **Remediation:** Rebalance should serialize its ranked actions to a static, local file (e.g., `.xyz/roadmap_signals.json` or a file in the Obsidian vault) that XYZ consumes, preserving the file-based trust boundary.

#### **[Should] Circular / Artificial Sequencing Block in Phase 0**
* **Issue:** The status block states that Phase 0 (Pre-scope spike) is sequenced *after* [GH-101-SIGNAL-QUALITY-CONTRACT.md](file:///Users/noelsaw/Documents/rebalance-OS/PROJECT/2-WORKING/GH-101-SIGNAL-QUALITY-CONTRACT.md) ships.
* **Impact:** Phase 0 is a 1–2 hour read-only discovery spike ("no code is written"). However, its checklist requires "confirming the GH-101 fields the collector will key off". Blocking Phase 0 on GH-101 creates a circular dependency: you cannot define the fields you need from GH-101 until discovery is done, but discovery is blocked on GH-101 shipping.
* **Remediation:** Run Phase 0 discovery immediately to feed requirements into GH-101. Only Phase 2 (Seam #1 collector) should be blocked on GH-101 shipping; Phase 1 (Seam #2 check subcommand) can proceed in parallel.

#### **[Should] Lack of Atomic Writes for `XYZ.json` (Phase 2, Seam #1)**
* **Issue:** The plan has XYZ emit `XYZ.json` and Rebalance's `xyz` collector read it.
* **Impact:** Since both processes run concurrently on the same machine, a non-atomic write of `XYZ.json` by XYZ will cause Rebalance's background sync crons (`com.rebalance-os.daily-sync` at [daily_sync.sh](file:///Users/noelsaw/Documents/rebalance-OS/scripts/daily_sync.sh)) to read partial or corrupt JSON, triggering false-positive "degraded" alerts.
* **Remediation:** Require XYZ to write `XYZ.json` atomically (write to a temporary file, then rename/mv) to ensure read isolation.

#### **[Nit] YAGNI: Defer Phase 4 (Outcome-Attribution Loop)**
* **Issue:** Phase 4 is a speculative correlation loop that is "log-don't-act" and does not affect ranking decisions in this plan.
* **Impact:** It adds schema and code overhead without immediate product value, violating the "least code that clears the bar" principle (Principle 6).
* **Remediation:** Remove Phase 4 and move its requirements to the "Open Questions" section to be addressed when the relevance fence is crossed.

#### **[Pass] Observability / Ingestion Seam Verification (Phase 2, Seam #1)**
* **Finding:** The plan correctly identifies [index_ops.py:95](file:///Users/noelsaw/Documents/rebalance-OS/src/rebalance/ingest/index_ops.py#L95) and the registrations at lines 1505–1513 as the extension point for the new collector. This adheres to Principle 3 (Extend by addition) and avoids parallel plumbing.

---

### 3. Recommendation
**Recommendation:** Move the commit pin to a committed repository file, run Phase 0 immediately to inform GH-101, and change Seam #3 to use a serialized file interface rather than direct SQLite DB coupling.
