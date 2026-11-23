# Plan draft: #1252 Software Factory: evaluate existing OSS candidates (umbrella)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1252-474090aa2cc3` (tick `slot_032`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 55/30/65/70
- Capture doc: PROJECT/1-INBOX/GH-1252-FACTORY-OSS-CANDIDATES.md (sha256 9b4f109d8fe6e8ade5f05f64e85f9f4268dee8e901b6969b250247875151509e)
- Issue sha256: 474090aa2cc39b1d8b7635523d216094dd9c0361583af45d7b41fcfdad185af1 (updated 2026-10-29T16:20:54Z)
- Dependencies: none

## Scope

_Source: issue#1252:L1 (Outcome)_

Pick which existing open-source projects, if any, the Software Factory (#1175) should reuse, and in which role. This saves building parts that already exist, and stops us adopting something that conflicts with how XYZ decides who owns what.

This issue covers evaluation only. It doesn't authorize adopting, vendoring, installing or running any candidate.

_Source: issue#1252:L7 (Goals)_

1. **Keep the loop turning end to end.** Intake → pick → execute → review → merge → close, continuously, across restarts, one issue at a time per factory.
2. **Clear the known bottlenecks first.** The Phase 0 spike (#1225, findings on #1175) showed that landing stalls first, then intake becomes the bottleneck. A candidate is worth more if it helps landing or intake, and less if it only speeds up execution.
3. **Get ready for more than one repo.** XYZ Forge is the first factory. Other repos with a vendored `.xyz/` come later, under the same control plane.
4. **Make remote execution optional, not a rewrite.** Execution stays on the local Mac until Phase R's entry criteria hold (#1175). After that, moving hosts should be a deployment change.

_Source: PROJECT/1-INBOX/GH-1252-FACTORY-OSS-CANDIDATES.md:L26 (frontmatter goal)_

For each factory layer (intake, execution, review, landing, remote host), record whether to reuse an existing open-source project, borrow its ideas, or build it in XYZ. Base each call on candidate evaluations against fixed requirements, and record the operator's decision.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `MACHINE-CONTRACTS.md` (issue#1252:L16)

## Unresolved file names

- `codex-turn.sh` (issue#1252:L23; 2 tracked files share this name)
- `agy-turn.sh` (issue#1252:L23; 2 tracked files share this name)

## Contract probes

- none
