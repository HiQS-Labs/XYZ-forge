---
title: "GH-613: Claude review follow-ups"
status: Complete
created: 2026-09-14
updated: 2026-09-15
owner: operator
gh_issue: 613
source: https://github.com/HiQS-Labs/XYZ-forge/issues/613
doc_type: bugfix
effort: 2
complexity: 2
risk: 3
phases: 2
reversibility: Easy
goal: Close the accepted native Claude routing, isolation, result, cleanup and effort gaps.
---

# GH-613 — Claude review follow-ups

## Status

| What was just completed | What's next |
|---|---|
| Implemented, reviewed; full gate 376/376; [PR #614](https://github.com/HiQS-Labs/XYZ-forge/pull/614) open | Operator review and merge decision |

## Table of contents
- [Recon map](#recon-map)
- [Phase 0 — Boundary spike](#phase-0--boundary-spike)
- [Phase 1 — Implement and verify](#phase-1--implement-and-verify)

## Recon map

Base ec0823abb084c62f494df4cd31432625f17a5c60. Reuses this session's full-file
inspection and Opus review; no intervening source change. Graph generation
2026-09-01 is stale/missing these additions; exact source is the evidence.

| Seam | Current path and state | Planned boundary |
|---|---|---|
| Runtime routing | claude-turn.sh / consult.sh:9-22 select Python or fall through | Refuse explicit subscription before any legacy dispatch |
| Auth route | claude_cli.preflight:19-49 probes actual cwd/env | Optional native settings flags shared with consult request |
| Relay success | claude-turn.py:184-193 conditionally reads JSON | Validate all successful process results; stderr sidecar |
| Consult read tools | consult.py:554-573 launches in snapshot with unrestricted read tools | Native --restricted and --strict-mcp-config in preflight AND request |
| Process ownership | consult.py:240-305 and 724-725 use proc_group.kill_existing | Exercise existing termination, no new runner |
| Effort | claude-turn.py:170-177 omits flag, :284 records high | Shared optional effort flag builder for both dispatches; honest cli-default telemetry |

Existing writers remain: claude_cli interprets auth/results; RTL owns claims,
worktree cleanup and commits; consult aggregates answers; proc_group owns child
termination. Full vendor copies utils; legacy tarball cannot supply Python adapters.
No new credential store, API bridge, runtime, coordination layer or dependency.

Blast: only Claude paths plus compatibility stubs and public Claude docs. Explicit
subscription users on old runtime now get a refusal, and old non-JSON relay stubs
must emit the real success shape. Codex/Agy defaults remain unchanged. Easy undo:
revert this PR; no migration. CLI restricted mode is a native tool boundary, not an
OS sandbox: trusted managed configuration and native CLI behavior remain external.

Rating read-back: 80/75/50/65 (pri/sev/appeal/cheapness). Unexpected routing and
out-of-checkout reads are material potential consequences, with no observed loss.
Neutral appeal; bounded changes. Review of Claude-related issues over Aug31–Sep13
versus Aug17–30 found related #608 effort work and this #610 review, not enough to
establish distinct incident velocity; trend unknown. No operator override.

## Phase 0 — Boundary spike

- [x] Native CLI 2.1.270 accepts --restricted for auth status and preserves the
  Claude.ai / firstParty / Max route. Only whitelisted account fields inspected.
- [x] Native restricted Read returns a random in-directory marker and denies a
  random outside-directory marker; non-empty positive result is required.
  Evidence: TESTS-RESULTS/2026-09-14+GH-613/boundary-spike.jsonl.
- [x] Findings written back: use identical restriction flags for preflight/request;
  user/project/local settings are ignored by restricted mode. Unsupported CLI
  versions must fail before inference. No substring-based confinement.

### QA gate
- [x] Happy read and denied read observed; no real private file accessed.
- [x] Commit reproducible boundary probe and full secret-free provenance, including a authorized-extra-directory negative control.
- [x] Plan independently approved before production edits.

## Phase 1 — Implement and verify

1. Add a subscription-only refusal at the two shell routing boundaries. This is
   an explicitly authorized narrow exception to frozen fallback policy; do not
   extend or refactor legacy runtime bodies. Test XYZ_PYTHON=0/empty/missing Python
   with a dispatch marker, and unchanged inherit fallback.
2. Extend claude_cli.preflight with optional settings flags; consult passes
   --restricted/--strict-mcp-config identically to auth and inference. Test argv
   parity, unsupported restriction refusal, and native read denial. Restriction
   overrides user/project/local settings; document this change including inherit.
3. Make relay JSON success validation unconditional. Keep nonzero/error paths
   through RTL enforcement; retain stderr in a sidecar. Fix old test stubs/logs
   to represent actual Claude results; do not relax strict parsing for tests.
4. Add shared optional effort flags, used by relay and consult; accept only native
   low/medium/high/xhigh/max, reject invalid settings before claim or inference.
   Omitted effort leaves CLI default untouched and telemetry records cli-default.
5. Expand registered GH610 fixtures with inherit error, relay/consult effort,
   nonzero stderr pointer, and wall/idle timeout scenarios. A fake CLI forks a
   TERM-resistant child and records its PID/PGID; assert both are gone, answer is
   failed, and consult worktree cleanup holds. Relay fixtures separately assert error/token handoff; no relay process-group or idle guarantee is claimed. Red controls remove new flags/guard
   and strict validation; existing runner guarantees get killed-descendant checks.
6. On consult Git worktree removal failure, preserve the linked worktree and report an actionable error (exit 5); never manually delete the directory. Add a forced Git-removal failure fixture with recovery via Git. This small shared cleanup correction affects all consult advisors.
7. Update public setup/skills/registry references and CHANGELOG; refresh the legacy
   packaged README if required. Record evidence/provenance and review verdicts.
8. Run focused suites then full pre-push gate in a separate disposable full clone,
   final relay QA, and open a PR against development. No merge or deployment.

### QA gate / acceptance
- [x] S1 explicit subscription never reaches legacy inference (witnessed red).
- [x] S2 malformed/error/empty result fails in both auth modes with clean handoff.
- [x] S3 actual restricted tools deny outside reads; auth/request flags agree.
- [x] S4 wall/idle descendants gone; nonzero diagnostics survive; worktree removed.
- [x] S5 effort reaches both commands and omitted effort telemetry is truthful.
- [x] Public docs, independent source QA and full gate complete; [PR #614](https://github.com/HiQS-Labs/XYZ-forge/pull/614). Latest delta receipt limitation recorded below.

Debugging follows debug-mantra: reproduce, trace, falsify, retain each breadcrumb.
Retries capped at three review rounds; deterministic failures require a diagnosis.
Optional nits: sidecar N1 and effort docs N6 included; no speculative idle detection
rewrite, billing guarantee, or global MCP policy change. Programmatic consult
instructions should identify Claude as read-only; no new script execution capability.

Boundary evidence correction: default CLI permissions also denied the first outside
probe; no baseline data leak is claimed. The recorded control deliberately grants an
extra fixture directory and returns its random marker; the production restriction
flags omit that grant and deny it. `boundary_probe.py` reproduces both.

Final QA: first implementation relay Approved with full-gate qualification still pending.
Post-review corrections root stderr in the resolved coordination checkout (existing
target-root regression witnessed red then green), clarify programmatic Claude's
read-only seat, and extend timeout fixtures through the entire consult CLI. The first
full gate was superseded with known failures; it is not passing evidence.

Independent final correction review: Approved on 2cbfc53a (production/test tree
identical to 83995bf3). Live native Opus subscription consult passed with high effort
requested through the shipped adapter, no execution wrapper. Full gate remains pending.

## Lessons Learned (For Future Agents)

- Strict parsing requires real success envelopes in old CLI stubs; never special-case
  fixtures or discard the result stream.
- Diagnostic logs follow the selected JSON transcript path. Create parent-owned sidecars before the containment snapshot so custom in-tree diagnostics survive without becoming artifact commits.
- An outside-read denial alone is weak evidence; use random markers and a deliberately
  authorized extra-directory control. Do not infer a prior data leak from a review concern.

Final full-gate correction: the 83995bf3 gate passed 371/376. Four failures exposed a mismatched committed ledger pair; regenerated both files through `releases check --rebuild`. The archive containment failure exposed stderr resolving independently of custom `CLAUDE_LOG`; diagnostics now use the selected JSON path plus `.stderr`, retaining its archive/custom location. Isolated archive, ledger and subscription regressions pass; full corrected gate follows. Earlier tick-root stderr review is superseded by this sidecar correction.

The custom in-tree transcript regression then exposed the new stderr sidecar as an off-lane edit. Prepare that parent-owned file before the existing dirty-state snapshot; setup failures still traverse normal turn enforcement. Extended the existing Claude suite to require retained diagnostic content and exclude it from the artifact commit (37 checks pass); archive mode also passes 16 checks.

Final delta source review: Codex returned PASS after reading the complete changed adapter and compatibility suite. The driver refused the receipt because the reviewer inserted one blank line above its own block; the review is preserved in gh613-sidecar.md, but this latest delta has no accepted driver attestation. Prior full implementation and correction attestations remain preserved. No new blocking source finding; latest focused logs and fingerprints are published.

Final publication: PR #614 targets development. Full guarded pre-push passed 376/376 (21 Python-layer tests) in 819 seconds on ddd19bee; qualification clone HEAD stayed identical and clean, and origin contains that exact commit. Later commits contain review/evidence/docs only, verified against that runtime/test tree. This is PR readiness evidence, not promotion qualification. Nothing merged or deployed. GH-613 remains active pending merge.
