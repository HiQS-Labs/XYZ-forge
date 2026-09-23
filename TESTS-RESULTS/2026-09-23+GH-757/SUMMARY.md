# GH-757 Phase 0 development-data probe

## Contents

- [Purpose and status](#purpose-and-status)
- [Method](#method)
- [Observed inventory](#observed-inventory)
- [Remaining gates](#remaining-gates)

## Purpose and status

This is a bounded **development-data feasibility probe**, not a model-quality campaign or a frozen final evaluation. The owning plan and substantive results live in [XYZ #757](https://github.com/HiQS-Labs/XYZ-forge/issues/757). No model calls or candidate scores were made. The probe took approximately 10 seconds for the final fetch/serialization run on 2026-09-23. The earlier first-eight-actions trial is excluded because it strongly favored early workflow actions.

## Method

- Public source: `nebius/SWE-rebench-openhands-trajectories`, pinned revision `35455389ab51bf5e2306bfd436ef72d0f98bf882`, train offsets 0–299. Dataset metadata and row count were verified by the upstream API; no embedded command was executed.
- Historical exclusion: all repositories and instance IDs in offsets 0–99 are excluded from the candidate development window 100–299. This is conservative; the historical scored campaign itself used fewer instances.
- Existing Needle serializer: `spike/coding_core/prepare_openhands.py`, SHA-256 `2c671c579552bc0071ce3c7616f506e7869e05243d36c68a389ac2e997c98492`. It emits pre-target q3 state and the six-label next recorded action. The source file is not copied here; the probe accepts its path as its argument.
- For each eligible resolved trajectory, select eight rows evenly by integer positions `(2*j+1)*n//16`, `j=0..7`, clamped to `n-1`. This position-only rule does not inspect labels. This is a development probe rule, **not yet the frozen final-test sampling manifest**.
- Reproduction from the XYZ root: `python3 TESTS-RESULTS/2026-09-23+GH-757/phase0-development-probe.py /path/to/Needle-fork/spike/coding_core/prepare_openhands.py`. The script writes `phase0-development-probe.json` in the current directory; the committed JSON is the retained aggregate. Its SHA-256 is `4c896f2e9f5590bac173d6dd262097663a9ac268e97dfdc3f648b36a3415b33e`.

## Observed inventory

Of 200 source trajectories in offsets 100–299, 46 overlapped an old repository or issue and 73 were unresolved. The remaining 81 resolved trajectories cover 74 repositories and 81 distinct issues, producing 3,940 eligible q3 rows. Eight evenly spread rows per trajectory yield 648 development rows: read 170, run_command 187, run_tests 89, git 15, search 81, edit 106. The maximum observed contribution is two trajectories per repository and one per issue.

All 81 eligible trajectories had an explicit `<issue_description>` in their first user message; none used full-user-text fallback. Ten first tasks and ten first observations hit the 2,000-character cap. The serializer audit recorded 363 control resets, 286 unmatched/empty tool results and one unlabelable call across eligible trajectories. These are audit counts, not proof that every sampled row is semantically correct. The serializer emits a row before setting the pending target call, but independent leakage/normalization review remains open. The committed JSON retains counts and sanitized example hashes, without source text.

The dataset card identifies CC BY 4.0 for the dataset and warns that repository-level licenses may also apply to redistribution. This campaign retains only aggregate counts and hashes here, not raw trajectories.

## Remaining gates

- [ ] Audit the `run_command` mapping, truncation consequences and representative q3 pre-action state without publishing source text.
- [ ] Inventory repository-disjoint unseen test groups and exclude every previously used campaign instance.
- [ ] Select exact candidate identities and synthetic-smoke latency/cost; cap the total calls.
- [ ] Freeze split, sample, baseline training, comparator, metrics, uncertainty, failure policy and budget in #757 before final-test access.
- [x] Human adjudication availability resolved: the operator reports no independent reviewer. Contract B remains unscored, with no advisory handoff.
