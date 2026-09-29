# Chain of origin

Every managed file in this repository is published from [XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge)
by `utils/py/xyz_mini_sync.py`. The publication revision is recorded in `.xyz-forge-revision`
(source repo, commit, branch). A publication may run from any forge branch — including a feature
branch before its PR merges — and the recorded branch is the provenance; when the branch lands in
the forge's primary branch, a re-publication from it re-baselines the pin.

Two kinds of managed paths exist:

- **Byte-identical (managed):** the file here is byte-for-byte the forge source at the recorded
  revision. The sync tool replaces it on every publication. Everything listed in `MANIFEST.txt`
  is this kind unless named in the table below.
- **Adapted:** the file started from the forge source named below but carries mini-local changes.
  The sync tool never overwrites an adapted path and deletes it only if it is dropped from the
  tool's manifest; the forge source path remains the upstream of record.

| Path in XYZ-mini | Kind | Upstream in XYZ-forge | Notes |
|---|---|---|---|
| `skills/weekly-planner/` | adapted | `skills/3-weekly/weekly-planner` | mini-flat paths (`skills/3-weekly/…` → `skills/…`), `/relay-xyz` → `/relay`, GH-678 live-link guard in `install.sh`, OSError guard around temp-dir creation, None-safe `pr.get("title")` refs in `planner_core.py` (GH-889 QA) |
| `skills/daily-planner/` | adapted | `skills/2-daily/daily-planner` | mini-flat paths as above; `install.sh` locates `weekly-planner` in the flat layout; GH-678 live-link guard (GH-889 QA) |

Rules for a new adaptation:

1. Add the path to the forge tool's MANIFEST with mode `adapted`; the forge source must keep
   existing and stay tracked — it is the upstream of record.
2. Add a row to this table in the forge's `mini/ORIGIN.md` (this file). The sync tool refuses to
   publish an adapted path that this file does not document.
3. Park the upstream-sync debt (`PARKED/` in the forge) or file it, and either re-upstream the
   change to the forge or maintain the fork consciously.
