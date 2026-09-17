---
title: Isolate Agy model-validation probe
status: Active
created: 2026-09-17
updated: 2026-09-17
owner: noel
goal: Prevent relative model-probe writes in caller checkouts using existing temporary-directory ownership.
effort: 1
complexity: 2
risk: 3
phases: 1
gh_issue: 666
source: https://github.com/HiQS-Labs/XYZ-forge/issues/666
doc_type: bugfix
---

# GH-666 — Agy model probe

## Status

| What was just completed | What's next |
|---|---|
| Controlled caller-write reproduction; issue/intake/rating and recon | Independent plan QA, narrow implementation and verified PR |

## Quad Concepts

- A model-list probe inherits caller CWD → reuse the existing disposable-probe pattern.

## Diagnosis and scope

See recon-agy-model-probe.md. At base 74daa7d2, a relative-writing models stub
dirties a temporary Git caller while the actual validator returns True. Baseline
source is unchanged; no live CLI write or damage to operator files is claimed.
Protocol: debug-mantra, controlled temp caller; no instrumentation in shared RTL.
Hypotheses ranked: inherited CWD (observed), log capture protecting writes (falsified
by marker outside log), later RTL cleanup protecting caller (falsified by call order),
unset-model invocation (negative control specified). No new layer or dependency.

## Decision, limits and rating

Costly under shared-containment policy; focused code rollback is easy but a bad
preflight could damage work. Bet: stdlib temporary-directory ownership plus explicit
subprocess cwd removes inherited-relative writes while preserving model parsing.
Shield: controlled stub, fail closed on folder creation, existing shim tests,
disposable full-clone gates and independent QA. Tripwire: any changed caller or
model-selection/forwarding result stops delivery; rollback through reviewed revert.
No shared RTL, frozen Bash, process lifecycle, absolute-write sandbox, deployment,
GH-661 repair/merge, Daily or Flight Deck work. Cleanup failures must be reported,
not silently treated as clean success.

Persisted rating 90/85/50/85: potential caller corruption plus blocked review is
urgent/high severity; appeal neutral; one local probe is cheap to repair. Observed
recurrence is one reproduced defect, related historical auth-probe repair GH-426
is a different call. Search windows 2026-09-03..16 versus 2026-08-20..09-02 found
broader containment incidents GH-654/GH-658 and GH-285, not repeated measurements
of this validator. Search coverage is incomplete: trend unknown, no growing rate claim.
No operator override.

## Phase 1 — Surgical fix and PR

1. Independent Codex plan QA, cap three rounds → actual cited approval before code edits.
2. Add a registered stdlib regression suite against the real validator. Controlled
   relative-writing stub covers listed ID/display/full-line, unavailable, nonzero,
   timeout and launch failure. Assert nonempty invocation records, caller Git identity,
   HEAD/tree unchanged, explicit marker absent (including Git-ignored marker),
   pre-existing sentinel bytes unchanged and temporary CWD removed. Invocation
   records must prove the stub wrote the marker in its recorded cwd before exit.
   Unset model invokes nothing;
   creation failure returns False before invocation → baseline failures retained.
3. Use the existing disposable-probe-directory pattern with explicit cwd and
   cleanup on all returns, retaining timeout/errors/parsing/forwarding. Resolve the
   validator executable in caller CWD with shutil.which and make its result absolute
   before switching child cwd; test absolute, caller-relative and bare PATH forms
   including a relative PATH entry. This preserves validator resolution only;
   the existing auth probe's relative-executable limitation is not repaired here.
   No helper
   framework. Remove cwd via an in-memory ablation only → same preservation checks red.
4. Commit code/docs, run focused/shim/static and full gates in a separate full clone,
   pin logs/source/hash/exit and assert clone identity/tracked-tree unchanged → actual
   green results or explicit pre-existing base blockers. No silent skipping or bypass.
5. Final independent Codex QA (cap three), inspect scope, actual gated push and one PR
   into development → ready only on approval/passing checks; otherwise record hold.
   Merge is not authorized. Existing unrelated gate defects are not bundled.

### Phase 1 — QA checklist

- [ ] Registered preservation assertions fail on unchanged base and cwd ablation.
- [ ] Probe result/model forms and absent-model behavior preserved; completed-path cleanup verified.
- [ ] Creation/launch/timeout/nonzero/unavailable failures preserve caller and report refusal.
- [ ] Full source-pinned gate, static checks and final independent QA pass.
- [ ] PR base/head/scope verified; issue stays open awaiting merge.

Evidence destination: TESTS-RESULTS/2026-09-17+GH-666/ with committed provenance.jsonl.
