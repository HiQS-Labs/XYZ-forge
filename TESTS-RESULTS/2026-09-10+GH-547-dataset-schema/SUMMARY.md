# GH-547 Phase 1 — external dataset schema probe

## Verdict

The bounded schema probe is complete. **TAWOS passes the structural screen for Task A, but needs a later sampled-data and label-quality check. NLBSE is useful only as four-class source-domain supervision and cannot support the planned project/time split from its published CSV. SWE-Gym exposes a valid chronological action schema, but its Hugging Face dataset metadata does not declare a license, so it cannot advance to training until data-use rights are resolved.**

No model was trained. The 514.46 MB NLBSE training archive, 637.55 MB TAWOS archive, 301.10 MB SWE-Gym OpenHands trajectory files, and 5.52 GB Moatless trajectory ZIP collection were not downloaded. The probe downloaded the 56.96 MB NLBSE test archive into a temporary directory and removed it after inspection.

## Results

| Source | Observed schema and scale | Task fit | Gate |
|---|---|---|---|
| NLBSE '23 | 142,320 test rows; `id`, `labels`, `title`, `body`, `author_association`; labels are bug 74,781, feature 52,797, question 8,490, documentation 6,252 | Limited Task A transfer source | **Conditional:** no repository or timestamp fields, only four of the eight HiQS purposes, and the linked archive has no separately declared data license in the source README. The code repository is AGPL-3.0. |
| TAWOS 1.1 | 13 relational tables; issues include text, type, resolution, creation/update timestamps and project IDs; separate component and chronological change-log tables | Strongest structural Task A candidate | **Conditional pass:** Apache-2.0 is declared by Figshare. A later bounded/full data sample must measure native type/component distributions and mapping noise; project-specific components cannot be treated as HiQS component labels. |
| SWE-Gym verifier train data | 2,163 rows; `messages`, `instance_id`, `exp_name`, `fail` | Verifier/patch-response data, not Task B trajectories | **Reject for next-action training:** bounded samples are short patch-generation conversations rather than chronological tool activity. |
| SWE-Gym OpenHands sampled trajectories | 6,055 rows; `instance_id`, `run_id`, `resolved`, chronological `messages`, declared `tools`, and `test_result`; sampled rows alternate assistant/tool events with explicit tool calls | Structurally valid Task B source | **Blocked on license:** the HF dataset metadata license field is empty. The SWE-Gym code repository is Apache-2.0, but that does not establish a license for this separately hosted dataset. |
| SWE-Gym Moatless sampled trajectories | 5.52 GB ZIP collection; dataset-server schema endpoint unavailable | Desired cross-scaffold Task B source | **Deferred:** no bounded row/schema endpoint and too large for this phase. |

## Implications for the planned seven steps

1. Do not use Gemini's `SWE-Gym/SWE-Gym-trajectories` identifier; it does not identify the datasets observed here.
2. NLBSE can provide weak transfer supervision for `bug_fix`, `feature_enhancement`, and `documentation`; `question` needs an explicit mapping decision. It cannot independently enforce repository/time-disjoint splits.
3. TAWOS is the next useful Task A data probe because its project and time keys support leakage control. Sample its native label distributions before defining any mapping.
4. Keep all HiQS component training labels HiQS-derived. TAWOS's many-to-many component relation is useful for representation experiments, not a direct taxonomy crosswalk.
5. OpenHands sampled trajectories prove the required Task B event shape exists. Resolve licensing before downloading or deriving training examples.
6. If licensing clears, define action labels from structured tool calls first; do not classify actions using substring searches over full message text.
7. Preserve independently adjudicated HiQS data as the final evaluation target; none of these public datasets replaces that holdout.

## Verification and limitations

The runner asserts nonempty NLBSE rows, SWE bounded samples, and TAWOS tables, plus exact pinned revisions for both SWE-Gym sources. Sample text and identifiers are represented only through field presence, lengths, roles, tool names, and SHA-256 digests. The initial run failed on an NLBSE field larger than Python's default CSV limit; commit `ad64975` records the explicit 16 MiB parser ceiling before the successful rerun. The first successful verifier sample exposed the dataset mismatch; commit `646cf78` records the protocol amendment and adds the real trajectory source rather than rewriting that result.

The probe does not establish label correctness, full-dataset distributions for TAWOS or SWE-Gym, training performance, publication rights for the unresolved datasets, or production suitability.
