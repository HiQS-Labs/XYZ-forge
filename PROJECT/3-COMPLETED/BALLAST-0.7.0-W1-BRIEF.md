---
title: "Ballast 0.7.0 — Wave 1 phase brief (#4 gate travels with clones · #10 require_fixture adoption)"
status: Complete
created: 2026-08-16
updated: 2026-08-24
owner: orchestrator (Claude Code)
doc_type: project
goal: >
  Drive Ballast's remaining wave — #4 and #10, now disjoint on validate.sh since #14/#15 landed
  outside the harness and were merged directly — as one marathon phase: build (agy), review
  (codex), adjudicate (orchestrator), merge on operator clearance.
roadmap_exempt: true
---

# Ballast 0.7.0 — Wave 1 phase brief (#4 gate travels with clones · #10 require_fixture adoption)

Subordinate planning artifact for the Ballast release (RELEASES.md 0.7.0 block owns scope; the
five member lanes each have their own capture doc and ROADMAP pointer — this brief is exempt from
a ledger line of its own for that reason).

## Status

| What was just completed | What's next |
|---|---|
| **Wave re-derived 2026-08-17**: #14 and #15 landed outside this harness (PR #21, PR #20 from an outside "Command Code/Qwen" lane), orchestrator-reviewed, merged, and post-merge-reconciled (ledger, negative controls, deferred-test waiver). Both dropped from the marathon fire list — preflight for both now reports STALE (exit 4). #4 and #10 are no longer forced into separate waves: nothing else touches `validate.sh` now, so they are disjoint and fit in one wave. Both dry-run READY. | Operator decides whether to fire this single reduced wave; on go, drive with marathon-drive (builder agy, reviewer codex, round-cap 5, require-clean) |

Release: Ballast (0.7.0), frozen manifest #14 #15 #4 #10 #3. **This wave, reduced: #4 and #10.**
#14 and #10 (GH-14, GH-15) are DONE — dropped, not fired; evidence: `test/baselines/GH-14-negative-control.md`,
`test/baselines/GH-15-parallel-contention-negative-control.md`, both issues closed with evidence,
`utils/swarm-preflight.sh --gh-issue {14,15}` both STALE (exit 4). Lane #3 is NOT FIRED — its
preflight verdict is STALE (the defect appears already landed on main; operator decision pending,
re-surfaced below).

**Why #4 and #10 can now share a wave**: the original serialization (#15 vs #10, both on
`validate.sh`) is moot now that #15 is merged. #4's edit targets are `README.md` and
`githooks/install.sh` — it never touched `validate.sh`. #10's edit targets are `ci-local.sh` and
`validate.sh`. These two lanes were never in conflict with EACH OTHER; the conflict was always
#10 vs #15/#14, both now resolved. Confirmed via `swarm-preflight.sh --gh-issue {4,10} --dry-run`
2026-08-17: both `ready`, no artifact overlap between the two lanes' actual edit targets.

Standing rules for every Ballast lane (from the release brief):

- Builder: **agy**. Reviewer: **codex**. The orchestrator adjudicates and merges; the operator
  decides whether to fire at all.
- The gate is `bash validate.sh`, run in a **disposable full clone at a durable location** — never
  in the primary clone, and never under `/tmp` (a clone under /tmp fails
  `gh388-run-log-durability`'s own-root durability classification; observed 2026-08-16).
- **Every fix ships a recorded negative control under `test/baselines/`** showing the check
  failing when the fix is reverted. A check never observed failing is not evidence.
- Acceptance criteria are the GitHub issue's, verbatim; deviations must be declared in the
  capture doc's `## Acceptance — deviations from the issue` section. Preflight re-fetches the
  issue and hard-fails on unexplained divergence.
- Before committing: `bash test/gh308-frozen-twin-guard.sh --check --staged`. No frozen-twin
  edits without an exception trailer; no new `.sh` under `utils/` or `relay-automation/`.
- A waiver names the failed criterion, the owner, the reason, and the follow-up issue. Silence
  is not a waiver.

## Lane #4 — the gate travels with the repo, not just with the clone

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/4 · Capture:
`PROJECT/2-WORKING/GH-4-GATE-TRAVELS-WITH-CLONES.md`.

Fix shape: surface an ungated clone in-band — a committed marker or first-run check that warns
when the hook wiring is absent, naming `bash githooks/install.sh` as the one-command fix — and
make the README quickstart state the install step is a correctness requirement, not optional
setup. The fix is LOCAL: hosted CI re-arm is #16, an explicit non-goal. A push cannot be locally
refused with no hook installed (git reads hooks from `.git/hooks`, which does not travel with a
clone) — the deliverable is that the ungated state stops being invisible; state the limit, don't
paper over it. If the design genuinely needs `validate.sh` or `ci-local.sh`, STOP and report:
that would collide with #10 and force re-serialization.

Artifacts: `README.md`, `githooks/install.sh`, `test/baselines/GH-4-negative-control.md` (new).

## Lane #10 — prevent-half of containment: require_fixture adoption

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/10 · Capture:
`PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md`. The manifest's designated cut if scope
slips (RELEASES.md); by far the largest member (~31 unaudited suites), with #1's clone-identity
bracket already covering the same ground *detectably* in the meantime.

Artifacts: `ci-local.sh`, `validate.sh`, `test/gh1-adoption-guard.sh` (new),
`test/baselines/GH-1-adoption-ledger.md` (new). Now the ONLY lane touching `validate.sh` in this
wave — no serialization needed against #4.

## Lane #3 — flagged, not fired

`improve-loop.sh --state-dir` default appears already landed on main
(`relay-automation/improve-loop.sh:75`, pinned by `test/gh430-state-dir-tracked-default.sh`).
Preflight confirms STALE (exit 4) again as of 2026-08-17. **Operator decision still pending**:
re-scope #3 to its provenance-policy half, swap it for another candidate, or close it as
already-landed. Surfaced again here per the standing rule (discovery is not admission; a flagged
member does not resolve itself).

## Exit criteria for this wave (per lane)

- #4: issue acceptance verbatim (4 criteria + 1 declared addition) + negative control recorded.
- #10: issue acceptance verbatim + negative control recorded (`test/baselines/GH-1-adoption-ledger.md`).
- Both: `bash validate.sh` green in the disposable clone; capture-doc Status tables updated;
  ROADMAP pointer lines updated to reflect progress (pointer-only).

## Lessons Learned (For Future Agents)
- Pre-0.7.0-era wave brief left active past its release; reconciled 2026-08-24 when PR #210's linkage surfaced it (its gh_issue frontmatter matches closed issue #1). Promote-on-closed-issue is correct here — the release shipped 2026-08-19.
