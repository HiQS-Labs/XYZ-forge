---
issue: 249
source: https://github.com/HiQS-Labs/XYZ-forge/issues/249
title: "CI: ubuntu portability canary permanently red — EUID=0 defeats chmod-based assertions in gh50-sandboxed-git-guard + security-scan"
created: 2026-08-25
type: bug
status: 2-WORKING
complexity: 2
risk: 2
effort: 2
phases: 1
---

# GH-249 · ubuntu canary: EUID=0 defeats chmod-based assertions

## Why

The `portability canary (ubuntu — advisory, never breakage)` job is red on `development` itself,
not just on PRs — verified on run 32923564904 (job 98041796632) and PR #247's run (job
98041592682), with byte-identical failing suites on both. Because the job is
`continue-on-error: true`, the workflow still reports success, so genuine Linux drift is invisible.

The job's own rationale block already pre-committed to a consequence for this exact state
(`.github/workflows/ci.yml:230-232`): if drift ships named-and-unresolved across two consecutive
promotions, the job "should be deleted rather than kept as decoration." The canary is currently in
the state its author said to delete it over.

Root cause: GitHub's ubuntu runner executes as root (EUID=0), so `chmod`-based negative assertions
cannot hold — root writes a `0444` file and reads a `0000` file regardless of mode bits.

- `test/gh50-sandboxed-git-guard.sh` — 3 pass, 8 fail (read-only git config never triggers refusal)
- `test/security-scan.sh` — 33 pass, 2 fail (`chmod 000` fixture is read cleanly, no `[scan-error]`)

## Key Concepts

- Cross-model consult (2026-08-25, `relay-system/2026-08-25/canary-root-euid-203501/`): Codex and
  agy independently graded "make the guards fail-closed under root" a **Blocker**. The production
  guards are correct as written — they probe actual capability (`: >> "$config"`, `grep` rc > 1)
  rather than inspecting mode bits. Refusing on mode bits would falsely block root-run containers.
- Fix the TESTS, not the guards: add `EUID=0` skips to only the chmod-dependent assertions.
- Follow the existing in-repo precedent at `test/gh342-sentinel-debug-log-python.sh:249` — a named
  SKIP that states why, rather than a silent pass.
- Keep the job advisory: `test/ci-workflow.sh:242` asserts the ubuntu job declares
  `continue-on-error: true`; promoting it to a gate would break that meta-test and contradict GH-509.

## Non-goals

- Changing `utils/git-sandbox-guard.sh` or `relay-automation/hooks/security-scan.sh`.
- Promoting the canary to a required gate.

## Related

- `test/gh50-sandboxed-git-guard.sh` · `test/security-scan.sh` · `test/gh342-sentinel-debug-log-python.sh:249`
- `.github/workflows/ci.yml:210-236` · `test/ci-workflow.sh:242` · GH-509 · #249

## Phase 0 checklist

- [ ] `EUID=0` skips on the chmod-dependent assertions in both suites (writable-control cases stay live)
- [ ] Also resolve the three unrelated FAILs in the same job, or the canary stays red:
      `agy` not on PATH (marathon-drive), worktree-isolation case 2, concurrent-lock race
- [ ] Witness a green hosted canary run before claiming the signal is restored

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "grep_absent", "path": "test/gh50-sandboxed-git-guard.sh", "pattern": "EUID" },
                     { "type": "grep_absent", "path": "test/security-scan.sh", "pattern": "running as root" } ],
  "artifacts":     [ "test/gh50-sandboxed-git-guard.sh", "test/security-scan.sh" ],
  "artifacts_new": [],
  "remediation":   { "source": "self#plan", "criteria": "chmod-dependent assertions emit a named SKIP under EUID=0 (gh342 precedent); writable-control cases still run; production guards unchanged; hosted Ubuntu canary green" },
  "lanes":         { "agy_safe": [ "test/gh50-sandboxed-git-guard.sh", "test/security-scan.sh" ], "orchestrator_only": [ "relay-automation/", ".tick/", "utils/git-sandbox-guard.sh", "relay-automation/hooks/security-scan.sh" ] }
}
```
