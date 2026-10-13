# Approved gate dispositions — verification

Tested source9c77b309f36bab29d6e486d203b2f7218f86dc86 in a separate disposable full clone. Four existing focused checks passed; gh306 red control failed with both missing-exemption names and restored bytes passed. Clone identity remained intact. No new suite, test registry addition, gate machinery or runtime fix.

ci-workflow.sh.log:
Summary
  passed: 57
  failed: 0

gh306-red-missing-exemptions.log:
  PASS:   and the exempt helper in the same dir is NOT flagged
  PASS: a fully-registered-or-exempt dir yields an EMPTY drift report (control: the guard is not trigger-happy)
  gh306-registry-bidirectional: 9 pass, 1 fail

gh306-registry-bidirectional.sh.log:
  PASS:   and the exempt helper in the same dir is NOT flagged
  PASS: a fully-registered-or-exempt dir yields an EMPTY drift report (control: the guard is not trigger-happy)
  gh306-registry-bidirectional: 10 pass, 0 fail

gh35-test-tiers.sh.log:
  PASS:   with the same consequence message and override
  PASS: GH-45: an absolute-path invocation whose HERE is the worktree is still refused (exit 2)
  gh35-test-tiers: 72 pass, 0 fail

gh379-canary-uses-validate.sh.log:
  PASS: a quarantined run disqualifies itself as promotion evidence
  PASS: boundary-macos still pins --sequential (it is the promotion boundary, not the canary)
  gh379-canary-uses-validate: 36 pass, 0 fail

Selection preservation receipt records410→408, unchanged Small and byte-identical retained suite/runtime files. These are focused checks, not a full gate or development qualification. Full push gate and hosted exact-head check are still outstanding.
