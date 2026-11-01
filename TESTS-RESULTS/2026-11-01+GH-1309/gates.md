# GH-1309 gates (code at `190be352`; gate run at `d28cce4e`)

- **Route:** `git diff --name-only origin/development...HEAD | bash utils/ci-route.sh pull_request` →
  `route=fast`, `tier=2`, `tier2_subsystems=skills-army-hq`, `full_required=false`.
- **Where:** disposable full clone `XYZ-forge-gh1309-sa-migrate-legacy-2026-11-01-gate` at `d28cce4e`
  (identity and tracked tree unchanged before and after).
- `./validate.sh --subsystem skills-army-hq` → exit 0, `passed: 6 / 6`: `skills-army-hq.sh`,
  `gh620-skills-army-mini-sync.sh`, `gh589-xyz-mini-sync.sh`, `gh589-consult-no-tick.sh`,
  `gh589-skill-viewer.sh` and the clone-identity invariant. "tier 2 run: NOT promotion evidence (GH-35/GH-509)".
- `bash utils/pdda/pdda.sh run` → exit 0, no errors.
- Commits after `d28cce4e` change only the relay thread and the plan status table.
