# GH-646 writer qualification — aborted run record

Date: 2026-09-17

## Reviewed source boundary

- Focused reviewer-approved source commit: `54b478de17bdec88eedfcd2f4cb3be7fa8407f91`.
- Python relay-driver attestation commit: `ecb39a1049f55167facff796ae9cbc4efdea9cdf`.
- Attested review transcript: `relay-system/2026-09-17/gh646-writer-focused-replacement-qa.md` (SHA-256 `1b3ab8ebab7b52e606e63f3b2dea90f7d1058f59a6951a4c361bbd7a66634974`).
- Retained ignored reviewer-engine logs: Round 1 SHA-256 `8d4fdc19b338f08166e563b26f77b2fac7d70e9da503519b96b77b84ee9a7179`; Round 2 SHA-256 `fd2fd86959b05b65d137891094c89c82dd5f76903aaf5529e42787dfaaf3c04c`.

This record is a documentation commit after the approved source/attestation boundary. It is not
covered by that source approval and is not a qualification claim.

## Focused evidence

- `python3 test/gh646_status_label.py`: 41 passed.
- Deliberate `appearance`, `closure_identity`, and `wave_terminal` mutants each failed as expected.
- `bash test/gh646-status-label.sh`: 41 passed.
- The replacement review found and repaired wave reconciliation terminalizing a declined PR's linked
  issue when issue evidence was OPEN, missing, or invalid. Ordinary terminal closeout now requires
  confirmed CLOSED issue evidence unless the existing explicit `--force-promote` override is used.

## Attempted final gate — not qualified

A single full `PATH=/opt/homebrew/bin:$PATH bash ci-local.sh` attempt began in a separate disposable
full clone at attested commit `ecb39a10`. Its prerequisite and shellcheck stages failed because
`shellcheck` was absent at launch. Homebrew later installed `/opt/homebrew/bin/shellcheck`, but this
run remains failed and was not retroactively changed to a pass.

The still-running baseline gate was then stopped by TERM to its verified disposable-clone process
group before its `test/agent-chorus.sh` installer path could reach real Gemini skill links. This
was required by open [GH-678](https://github.com/HiQS-Labs/XYZ-forge/issues/678) and its unmerged
[PR #680](https://github.com/HiQS-Labs/XYZ-forge/pull/680), which protect managed app links. No
user link was edited or repointed. The aborted run produced no `.gate-evidence` success record.

## Remaining gates

1. Land or otherwise verify the GH-678 / PR #680 installer-safety repair, or use the already
   validated installer-target isolation: redirect all managed app skill-target variables to owned
   scratch while leaving `HOME` unchanged. This is normal disposable verification, not a live-link
   edit or a whole-home mutation.
2. From a new disposable full clone of the final source plus any required documentation commits,
   run `bash ci-local.sh` once with shellcheck available and preserve its actual result.
3. Inspect the exact final diff and source/receipt relationship. Only a green gate plus the
   already-attested review permits a normal PR that says `Refs #646`; no merge, live migration,
   connector enablement, label write, or deployment is included here.
