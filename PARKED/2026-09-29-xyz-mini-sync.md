# XYZ-mini publication sync would delete the adapted planner skills

- **Found:** 2026-09-29, while publishing the review-code skill to HiQS-Labs/XYZ-mini by hand.
- **Finding:** `utils/py/xyz_mini_sync.py` cannot currently be run with `--apply` against
  XYZ-mini without destroying the planner publication. Mini's `MANIFEST.txt` lists
  `skills/weekly-planner/*` and `skills/daily-planner/*`, but the tool's embedded MANIFEST does
  not, and mini's copies are deliberate adaptations of the forge sources at `40f8a9b3`, not
  byte-identical copies: flat-layout paths (`skills/3-weekly/weekly-planner/` →
  `skills/weekly-planner/`), `/relay-xyz` → `/relay`, plus mini-only hardening (GH-678 live-link
  guard in both `install.sh` scripts, an OSError guard around temp-dir creation, None-safe
  `pr.get("title")` refs in `planner_core.py`). A `--apply` run therefore either deletes the
  planner files (they fall out of the tool's managed set, and deletions are driven by the
  previous MANIFEST.txt) or, if they are added as `managed` entries, silently overwrites the
  adaptations with forge bytes. `seed` mode does not protect them either — seed destinations are
  not recorded in MANIFEST.txt, so they still fall into the deletion set.
- **Why outside scope:** reconciling the planner text or adding a transformed-vendoring mode
  belongs to the GH-889 planner lane / the GH-589 publication owner. review-code was published
  to mini by hand this session instead (byte-identical to
  `skills/2-daily/review-code` at the sha pinned in mini's `.xyz-forge-revision`).
- **Next check/decision:** before the next `xyz_mini_sync.py --apply`, either reconcile the
  planner divergence in the forge and re-vendor, or extend the tool with a transformed-vendoring
  mode; then add `skills/2-daily/review-code` → `skills/review-code` to the tool MANIFEST so the
  hand publication is re-owned by the script.
