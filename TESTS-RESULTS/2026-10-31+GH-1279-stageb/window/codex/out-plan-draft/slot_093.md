# Plan draft: #1155 Release review 2026-10-18: open-PR merge sequence + Express/Radar hotfix QA → main promotion

> draft; preflight and independent plan QA outstanding

- Request: `gh-1155-0892430f5048` (tick `slot_093`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 0892430f5048343db273e982ea32650eca91fb09e21653747ba452f902529e37 (updated 2026-10-18T21:46:28Z)
- Dependencies: none

## Scope

_Source: issue#1155:L1 (Goal)_

Review today's combined development candidate for overall quality, cohesion and regressions across the open-PR merge sequence and the operator-authorized Express/Radar direct hotfix. A successful, evidence-backed review is the signal to proceed with development → main promotion under the current release gates. Merely finishing the review or closing this issue is not a passing result.

Requested by Noel on October 18, 2026 (America/Los_Angeles). This issue captures the review and promotion sequence; it does not start another concurrent merge writer.

_Source: codex-authored (codex-authored)_

Verify the current development and main heads, PR dispositions, holds, landing commits, and release evidence before defining the candidate and merge sequence.

_Source: codex-authored (codex-authored)_

Review the combined candidate and the Express/Radar hotfix against the recorded boundaries, then assess promotion readiness under the current release gates.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The review records the candidate, included and excluded work, evidence, findings, and an explicit verdict; completion alone is not treated as a passing result.

_Source: codex-authored (codex-authored)_

Promotion proceeds only if the evidence supports a passing review and the current release gates are satisfied.

## Open questions

_Source: codex-authored (codex-authored)_

What requirements and release gates appear beyond the truncated issue body?

_Source: codex-authored (codex-authored)_

What are the current PR, QA, hosted qualification, and promotion statuses, and which findings remain unresolved?

## Write set

- `validate.sh` (issue#1155:L19)
- `utils/py/express.py` (issue#1155:L38)

## Unresolved file names

- none

## Contract probes

- none
