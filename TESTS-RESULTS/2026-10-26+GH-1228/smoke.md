# GH-1228 verification and smoke (2026-10-26)

Docs-route change (`utils/ci-route.sh push`: `route=docs tier=1`, see [recon-grep.log](recon-grep.log)). No tests added (GH-831).

- **Docs gate:** `utils/pdda/pdda.sh run` exit 0, no errors, 41 warnings. None names a file this change touches ([pdda.log](pdda.log)).
- **Red control:** on base `1f5b0508` the three unscoped lines are present (express `:28`, `:173`; ci-suite-audit `:342`). On head the same patterns match nothing (grep exit 1), and each line now names XYZ-forge and defers to the host repo's policy ([recon-grep.log](recon-grep.log)).
- **Smoke, main path:** `relay-automation/xyz-vendor.sh` from this branch into an empty scratch git repo. The vendored `.xyz/skills` contains none of the unscoped patterns and both scoped files are present ([vendor-smoke.log](vendor-smoke.log)).
- **Smoke, adjacent path:** re-vendoring over the existing `.xyz/` (the update path) keeps the scoped text (express: 2 lines, ci-suite-audit: 1) ([vendor-smoke.log](vendor-smoke.log)).
