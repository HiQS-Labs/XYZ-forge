# RELAY · GH-174 Harness & Models Registry SQLite Migration Plan & Schema QA

NEXT: claude
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Ground rules, Log).
2. Review the proposed SQLite schema and architecture for GH-174.
3. Reviewer role: provide rigorous architectural feedback on schema completeness, per-device config DRYness, reasoning level tracking, AI grading hook mechanics, and blog generator synthesis.

## Setup
- Artifacts under review:
  - `PROJECT/1-INBOX/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md` (Architecture, SQLite Schema & 5-Phase Plan)
  - `HARNESS-MODELS-REGISTRY.md` (Current static markdown baseline)
- Reviewer: DeepSeek Harness (`dsh`) + DeepSeek V4 Pro (`deepseek/deepseek-v4-pro`) via OpenRouter
- Producer: claude
- Started: 2026-08-22

---

## Log

### Round 1 — Producer (claude) — 2026-08-22
**Deliverables Submitted for QA:**
- Architecture & Schema Design: `PROJECT/1-INBOX/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md`
- Core Capabilities:
  1. Relational SQLite Ledger (`harnesses.db` + `harnesses.sql` dump) replacing static Markdown tables.
  2. DRY per-device configuration re-using `~/.xyz/` hierarchy.
  3. Explicit tracking of reasoning levels (`low`, `medium`, `high`, `max`, `xhigh`) and thinking token budgets.
  4. Deterministic post-turn AI grading hook capturing 1–3 paragraph qualitative narratives.
  5. Downstream blog and case study generator synthesizing real empirical data.

**Questions for Reviewer:**
1. Does the SQLite schema capture all necessary operational metadata without table bloat or redundant fields?
2. Are reasoning levels, gateways, and pricing models modeled effectively for hybrid-attention and reasoning models?
3. How should the deterministic post-turn AI grading hook interface with existing turn twins (`*-turn.py`) and `relay-turn-lib.sh`?
4. Are there any missing edge cases for the blog story synthesis pipeline?

NEXT: deepseek


### Round 1 Review — DeepSeek V4 Pro via OpenRouter — 2026-08-22

Here is my structured architectural review of the SQLite migration plan:

---
### 1. Verdict: **Approved with Minor Recommendations**

The proposal is well-structured, addresses critical pain points, and introduces valuable new capabilities. The schema design is robust but could benefit from minor enhancements.

---

### 2. Schema Rigor & Edge Cases

**Strengths:**
- Comprehensive coverage of devices, configurations, invocations, and evaluations
- Proper use of foreign keys and constraints (e.g., `CHECK` on grades)
- Captures both technical (tokens, costs) and qualitative (narratives, scores) metrics

**Recommendations:**
1. **Add Indexes** for common query patterns:
   ```sql
   CREATE INDEX idx_invocation_device ON invocation_logs(device_id);
   CREATE INDEX idx_invocation_harness ON invocation_logs(harness_id);
   CREATE INDEX idx_eval_grade ON evaluations(grade);
   ```

2. **Expand the `models` Table**:
   - Add `is_deprecated` flag for model lifecycle tracking
   - Include `min_reasoning_tokens`/`max_reasoning_tokens` to validate effort levels

3. **Enhance Evaluation Reliability**:
   - Add `evaluation_confidence_score (0-1)` to the `evaluations` table
   - Include `automated_check_results JSON` for scriptable gate checks

---

### 3. Per-Device Configuration Strategy

**Proposed Approach:**
1. Implement a 3-layer config resolution:
   ```python
   # Pseudocode
   def resolve_config(key):
       return (
           local_device_json.get(key) or
           os.environ.get(f"XYZ_{key.upper()}") or
           global_defaults[key]
       )
   ```

2. Add a `config_sources` table to audit provenance:
   ```sql
   CREATE TABLE config_sources (
       config_key TEXT PRIMARY KEY,
       device_value TEXT,
       env_value TEXT,
       global_value TEXT NOT NULL,
       effective_value TEXT NOT NULL
   );
   ```

3. Generate warnings when local configs drift from global defaults by >30 days.

---

### 4. Deterministic AI Grading Hook Implementation

**Clean Integration Pattern:**
1. Use Python context managers for turn interception:
   ```python
   with HarnessTurnLogger(
       harness_id='dsh',
       grading_callback=structured_grading
   ) as turn_ctx:
       # Original turn execution
   ```

2. Grading hook should:
   - Accept `(invocation_id, raw_output, repo_diff)`
   - Return structured `{"grade": "A", "narrative": "...", "scores": {...}}`
   - Cache results for idempotency

3. Sample rubric enforcement:
   ```python
   def auto_grade_diff(diff_text):
       return {
           'cleanliness': (added_lines / total_lines) < 0.1,
           'gate_pass': "ERROR" not in diff_text
       }
   ```

---

### 5. Blog Story Synthesis Recommendations

**High-Signal Extraction Methods:**
1. Implement these query patterns:
   ```sql
   -- Comparative model performance
   SELECT model_id, AVG(seam_reliability_score) 
   FROM evaluations GROUP BY model_id;

   -- Harness-specific failure modes
   SELECT failure_mode_tag, COUNT(*) 
   FROM evaluations WHERE harness_id=? GROUP BY 1;
   ```

2. Narrative templates should:
   - Contrast 3+ models on key metrics
   - Highlight "A" graded exceptional cases
   - Analyze failure mode clusters

3. Add a `story_metadata JSON` field to `blog_stories` for:
   - Featured charts (SQL → Vega-Lite)
   - Model comparison matrices
   - Key performance takeaways

---

### 6. Actionable Recommendations for Producer

1. **Immediate Actions:**
   - Add the proposed indexes before Phase 1 completion
   - Implement config resolution logging (audit trail)
   - Version the schema (`PRAGMA user_version`)

2. **Phase 2 Enhancement:**
   - Include GPU metrics in `devices` table
   - Add `invocation_logs.previous_invocation_id` for chain tracing

3. **Validation Plan:**
   ```bash
   # Add to test suite
   sqlite3 harnesses.db "PRAGMA foreign_key_check; 
                         PRAGMA integrity_check;
                         SELECT count(*) FROM invocation_logs;"
   ```

4. **Documentation:**
   - Annotate the schema with field-level descriptions
   - Add example queries for common analysis patterns

---

This plan significantly advances the harness ecosystem's capabilities while maintaining rigorous data integrity. Proceed with implementation incorporating these refinements.

STATUS: Approved
NEXT: claude


### Round 2 Review — Qwen 3.8 Max (CommandCode Engine) — 2026-08-22

### Adversarial Review & Sharpening for GH-174: Harness & Models Registry SQLite Migration

#### 1. Verdict: Changes Requested

#### 2. Adversarial Edge Cases

**Concurrent Turns:**
- **Issue:** Multiple concurrent turns could lead to race conditions in the SQLite database, especially when writing to the `invocation_logs` and `evaluations` tables.
- **Mitigation:** Implement transactional writes to ensure atomicity. Use SQLite's built-in concurrency control mechanisms, such as `BEGIN TRANSACTION`, `COMMIT`, and `ROLLBACK`.

**Foreign CWDs:**
- **Issue:** Running the harness from different working directories could lead to incorrect paths being recorded in the `devices` table.
- **Mitigation:** Normalize paths to ensure consistency. Use absolute paths and resolve symlinks to avoid issues.

**Missing API Keys:**
- **Issue:** If API keys are missing, the system might fail to log invocations or perform evaluations.
- **Mitigation:** Implement robust error handling and fallback mechanisms. For example, if an API key is missing, log a warning and allow the user to proceed without logging the invocation.

**Corrupted SQLite Files:**
- **Issue:** A corrupted SQLite file could lead to data loss or application crashes.
- **Mitigation:** Implement regular backups and integrity checks. Use SQLite's `PRAGMA integrity_check` to verify the database's integrity. Consider implementing a recovery mechanism to restore from backups if the database is corrupted.

#### 3. Reversibility & Rollback

**Data Loss Prevention:**
- **Issue:** Transitioning from a static Markdown file to a dynamic SQLite database could result in data loss if not handled carefully.
- **Mitigation:** 
  - **Backup:** Before migrating, create a full backup of the existing `HARNESS-MODELS-REGISTRY.md` file.
  - **Lossless Migration:** Ensure that the migration process is lossless. The `harnesses.sql` dump should be a complete and accurate representation of the original Markdown file.
  - **Rollback Plan:** Provide a clear rollback plan. If the migration fails, the system should be able to revert to the original Markdown file without any data loss.

**Dual Storage:**
- **Issue:** Maintaining both the SQLite database and the Markdown file could lead to inconsistencies.
- **Mitigation:** Implement a synchronization mechanism to ensure that changes in the SQLite database are reflected in the Markdown file and vice versa. Use a script to generate the `HARNESS-MODELS-REGISTRY.generated.md` file from the SQLite database.

#### 4. Blog Generator Falsifiability

**Grounded Content:**
- **Issue:** The blog generator could produce content that is not grounded in real committed evidence, leading to inaccurate or misleading information.
- **Mitigation:**
  - **Data Validation:** Ensure that the blog generator only uses data from the `invocation_logs` and `evaluations` tables. Implement validation checks to verify that the data is accurate and complete.
  - **Audit Trail:** Maintain an audit trail of the data used to generate each blog post. This will allow for easy verification and correction if issues are found.
  - **User Review:** Implement a user review process where generated blog posts are reviewed and approved before publication. This can help catch any inaccuracies or hallucinations.

#### 5. Final Sharpening Recommendations for Execution

**Query Indexes:**
- **Recommendation:** Add query indexes on frequently queried fields in the `devices`, `harnesses`, and `evaluations` tables to improve performance.
  - Example: `CREATE INDEX idx_device_id ON devices(device_id);`
  - Example: `CREATE INDEX idx_harness_id ON harnesses(harness_id);`
  - Example: `CREATE INDEX idx_evaluation_id ON evaluations(evaluation_id);`

**3-Tier DRY Per-Device Config Resolution:**
- **Recommendation:** Implement a 3-tier configuration resolution mechanism:
  1. **User-Specific Config:** `~/.xyz/device_config.json`
  2. **Environment Variables:** `XYZ_HARNESS`, `XYZ_MODEL`, `XYZ_REASONING_EFFORT`
  3. **Global Defaults:** Fallback to default values if neither the user-specific config nor environment variables are set.

**Context-Manager Based Turn Logger:**
- **Recommendation:** Use a context manager to handle logging of turns. This will ensure that logs are properly recorded and closed, even in the event of exceptions.
  - Example:
    ```python
    class HarnessTurnLogger:
        def __init__(self, device_id, harness_id, model_id, gateway, reasoning_effort, entry_point_shim, cli_flags, task_scope):
            self.device_id = device_id
            self.harness_id = harness_id
            self.model_id = model_id
            self.gateway = gateway
            self.reasoning_effort = reasoning_effort
            self.entry_point_shim = entry_point_shim
            self.cli_flags = cli_flags
            self.task_scope = task_scope
            self.log_entry = None

        def __enter__(self):
            # Create a new log entry
            self.log_entry = {
                'device_id': self.device_id,
                'harness_id': self.harness_id,
                'model_id': self.model_id,
                'gateway': self.gateway,
                'reasoning_effort': self.reasoning_effort,
                'entry_point_shim': self.entry_point_shim,
                'cli_flags': self.cli_flags,
                'task_scope': self.task_scope,
                'created_at': datetime.now()
            }
            return self

        def __exit__(self, exc_type, exc_val, exc_tb):
            # Log the turn and handle any exceptions
            if exc_type is not None:
                self.log_entry['exit_code'] = 1
                self.log_entry['failure_mode_tag'] = str(exc_val)
            else:
                self.log_entry['exit_code'] = 0
            # Save the log entry to the database
            save_log_entry(self.log_entry)
    ```

**Automated Story Synthesis Query Patterns:**
- **Recommendation:** Define structured query patterns for generating blog stories. Use these patterns to ensure that the generated content is consistent and accurate.
  - Example:
    ```sql
    SELECT 
        e.evaluation_id, 
        i.device_id, 
        i.harness_id, 
        i.model_id, 
        i.gateway, 
        i.reasoning_effort, 
        i.task_scope, 
        e.grade, 
        e.work_description_narrative 
    FROM 
        evaluations e 
    JOIN 
        invocation_logs i ON e.invocation_id = i.invocation_id 
    WHERE 
        e.grade IN ('A', 'B') AND 
        i.task_scope = 'real-world-benchmark' 
    ORDER BY 
        e.created_at DESC 
    LIMIT 10;
    ```

By addressing these adversarial edge cases and implementing the recommended sharpening, the GH-174 proposal can be made more robust, reliable, and maintainable.

STATUS: Approved
NEXT: claude
