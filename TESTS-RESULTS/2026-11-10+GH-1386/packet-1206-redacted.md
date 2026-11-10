# Marathon preflight packet — gh-1206-packaging-drift

- Generated: 2026-11-10T05:31:14Z
- Mode: project-doc
- Sources: <local-root>/PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md 
- Target root: <local-root>/temp/b-jog-transition-gate-b7urqpag/repo (development @ bb7cff2b6)
- Suggested branch: `marathon/gh-1206-packaging-drift-2026-11-10` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- **Source issue state: unknown** — preflight could not determine it; this does not block the lane.
- Gate: `bash validate.sh --auto development`

- Artifacts: package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 65 LOC across 6 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/xyz-vendor.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `<local-root>/PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md` (its `## Acceptance` section, 8 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified against the source issue — could not fetch issue #1206 (gh missing, unauthenticated, or offline) — acceptance fidelity NOT verified. Treat this list as a summary, not a contract: if anything here is ambiguous, read the issue before building.*
- [ ] No stale predecessor package name remains in package/lock metadata.
- [ ] No `main` entry references a missing file.
- [ ] Metadata declares the same Node baseline as the README.
- [ ] The dry-run package contains only intentional assets and excludes evidence, runtime state, ledgers, and transcripts.
- [ ] The 14 kernel unit tests still pass, and any declared CLI works from the packed artifact.
- [ ] No npm publish, version bump, or release-tag change occurs.
- [ ] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only.
- [ ] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/xyz-vendor.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1206-packaging-drift RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh \
  --target-root <local-root>/temp/b-jog-transition-gate-b7urqpag/repo \
  --pre-advance-cmd 'bash validate.sh --auto development' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text
