# 2026-10-02 PR fold final-tip gate

The macOS `ci-local.sh` full gate passed at `4ec641ba933479881a7a62e2d84b6f2b7bdddce0` against development `75b75181299d605b5458dbf4fd367680a05cbb53`. The command unset inherited `XYZ_HARNESS`, which had caused 12 fixture failures on both base and candidate in an earlier run.

The compressed log includes all suite output and the final `ci-local: all steps passed` summary. The separate full clone retained HEAD, Git configuration, origin, and a clean tree; only the timestamps differ in the identity files. This is local gate evidence, not hosted promotion qualification.
