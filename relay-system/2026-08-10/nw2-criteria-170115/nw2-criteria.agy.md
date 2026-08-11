(1) ANSWER: Both drafts have flaws: #392 is generally sound but lacks verification, while #391 is dangerously scoped and contains false premises about the harness's capabilities and validation rules.

(2) FINDINGS:

**=== ISSUE #392 (Docs Only) ===**
- **Criterion 1:** [Nit] SATISFIABLE THE WRONG WAY. Adding "Recommended minimum: 16 GB" fulfills the text without actually stating a strict hardware *requirement*, technically passing while leaving ambiguity. 
- **Criterion 2:** [Pass]
- **Criterion 3:** [Pass]
- **Criterion 4:** [Pass]
- **Criterion 5:** [Pass] (The premise is true: `utils/marathon-plan-zones.default.json` enforces `maxPerWave: 1` for the kernel zone to serialize edits, preventing write conflicts).
- **Criterion 6:** [Pass]
- **Criterion 7:** [Pass]
- **Missing:** [Should] MISSING. There is no criteria defining how this docs-only change is evaluated for completion (e.g., relying on a `grep_present` fix_probe).

**=== ISSUE #391 (YAML Emitter) ===**
- **Criterion 1:** [Pass]
- **Criterion 2:** [Pass]
- **Criterion 3:** [Blocker] FALSE PREMISE. `bin/marathon-yaml` does NOT require the `brief` or `artifact` fields. It only throws an error if `id` or `reviewer` is missing (`bin/marathon-yaml:92-94`). 
- **Criterion 4:** [Pass]
- **Criterion 5:** [Blocker] FALSE PREMISE. Emitting `depends_on` everywhere does not "remove all parallelism" because there is no parallelism to remove. `README.md` explicitly states (lines 242-244): "Phases run **one at a time**... A phase without `depends_on` is not 'unordered' or 'parallel-safe'".
- **Criterion 6:** [Pass]
- **Criterion 7:** [Pass]
- **Criterion 8:** [Blocker] SCOPE LEAK. The scope explicitly says "the emitter only", but this criterion requires modifying `marathon-plan.sh` to update its "How to fire a lane" section.

**=== EXTRA QUESTIONS ===**
- **#391 Emitter Home:** A separate script is required. `marathon-plan.sh` runs *before* preflight packets are generated (via `swarm-preflight.sh`). You cannot emit a YAML file from a packet directory that does not exist yet. Additionally, the hand-rolled YAML parser in `bin/marathon-yaml` expects `- id:` as the very first key of a list item, meaning a standard YAML dumper library could easily output valid YAML that the validator rejects.
- **#391 Python Twin:** Targeting `utils/py/marathon_plan.py` only will actively break `test/marathon-plan.sh` Scenario T, which enforces byte-for-byte parity between the Bash and Python planners (`utils/marathon-plan.sh:11-14`). The lane must explicitly retire that parity test.
- **#392 Docs-only Phase:** A docs-only lane is technically possible (using a `grep_present` probe), but a direct PR is far more sensible. Using a marathon for a simple markdown edit adds orchestration overhead for zero benefit.
- **Counterexample to Inert Write-Set:** Your claim is FALSE. Modifying `marathon-plan.sh` or `marathon_plan.py` actively impacts a running marathon because `marathon.sh` uses `--pre-advance-cmd "bash validate.sh"` as its gate (`marathon.sh:102`). `validate.sh` runs `test/marathon-plan.sh` (`validate.sh:157`). If the edit breaks the planner tests (e.g., tripping the Bash/Python parity check), `validate.sh` exits non-zero, and the running marathon will immediately HALT the phase with exit code 5 (pre-advance gate failed).

(3) RECOMMENDATION: Re-scope #391 as a standalone script, correct the false premises regarding `depends_on` and required fields, and merge #392 manually via PR.
