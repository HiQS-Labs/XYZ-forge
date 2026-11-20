---
issue: 1551
title: "kickstart(KS-07): enforce host-native background execution for long operations (>10 min)"
status: active
roadmap_id: rmi-01M7W39TSPD8DMM0575S9FDM8Z
parent_arc: 1541
milestone: KS-07
created: 2026-11-20
---

# GH-1551 (KS-07) — Long Operations Cannot Run in the Foreground

## Objective
Codify in `skills/1-hourly/kickstart/SKILL.md` that long operations (`merge-cleanup --execute` and full classified gates) MUST be launched via the host's native background execution and completion-notification mechanism, never in the foreground, without adding any new guard or runner wrapper.

## Grounded Recon
- `skills/1-hourly/kickstart/SKILL.md` currently specifies observer/child delegation and session recovery (sections 1 and 4) and launch authority defaults (KS-03), but does not explicitly forbid running `merge-cleanup --execute` or full classified gates in the foreground or specify the host-native background + completion-notification rule and U7/U8 qualification boundaries.
- Run-1 incident (#1539): a foreground `merge-cleanup --execute` crossed the 10-minute tool timeout and was killed mid-landing, stranding PR #1539.
- `utils/ci-route.sh` classifies edits limited to `skills/1-hourly/kickstart/SKILL.md`, `PROJECT/**`, `TESTS-RESULTS/**`, `CHANGELOG.md`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. Add a concise, explicit **Long Operations (Background-Only Execution, KS-07)** subsection to `skills/1-hourly/kickstart/SKILL.md` under Section 1 (Child execution contract):
   - `merge-cleanup --execute` and full classified gates (`./validate.sh` / full-route pre-push or disposable-clone gates) MUST launch through the host's native background execution mechanism and wait via native completion notification (no polling loops, no `sleep`, no custom wrapper/guard/runner).
   - Explicitly forbid foreground execution of those operations and record that a host lacking native background execution stops under Transition 3 (Shared Unsafe Stop) rather than falling back to foreground execution.
   - Record U7/U8 qualification boundaries honestly: synthetic/disposable-clone checks verify the foreground-timeout kill vs background-completion rule without manufacturing production incidents (U8), while full run-2 acceptance additionally requires at least one real run-2 >10-minute operation completing in the background with its result consumed exactly once (U7 — remains uncredited until run 2).
2. Update `CHANGELOG.md` with a concise GH-1551 (KS-07) entry.
3. Retain paired red/green evidence under `TESTS-RESULTS/2026-11-20+GH-1551/` (no new test suite, GH-831):
   - Real >10-min (`605s`) paired probe: red foreground 600s timeout kill (incomplete marker, reproduces #1539) vs green host-native background completion at 605s (completed marker, exit 0, delivered via native completion notification).
   - Source-only instruction walkthrough + `utils/pdda/pdda.sh run` + `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` mandates host-native background launch + completion notification for `merge-cleanup --execute` and full gates, forbids foreground fallback (unsupported host -> Transition 3), introduces zero new wrappers/runners, and states U7/U8 honestly.
- Paired >10-min red/green probe recorded under `TESTS-RESULTS/2026-11-20+GH-1551/` with `provenance.jsonl`.
- `./utils/pdda/pdda.sh run` passes with 0 errors.
