---
issue: 1551
title: "kickstart(KS-07): enforce host-native background execution for long operations (>10 min)"
status: Complete
roadmap_id: rmi-01M7XEJR8KTN1FWEFYCJB2HFRE
parent_arc: 1541
milestone: KS-07
owner: antigravity
goal: "Require host-native background execution and completion notification for merge-cleanup --execute and full classified gates in skills/1-hourly/kickstart/SKILL.md without adding new runners."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1551 (KS-07) — Long Operations Cannot Run in the Foreground

## Status

| What was just completed | What's next |
|---|---|
| Instruction implementation complete: rule 6 (Long Operations, KS-07) in `skills/1-hourly/kickstart/SKILL.md` merged with development's KS-13 rule 5; >600s host check green on Claude Code (`sleep 660`, exit 0, native completion notification; `TESTS-RESULTS/2026-11-20+GH-1551/outputs/host-bg-600s-claude-code.md`). | PR #1572 is open: independent review of its final head, then land. U7 (real run-2 operation >10 min) stays uncredited until run 2. |

## Objective
Codify in `skills/1-hourly/kickstart/SKILL.md` that long operations (`merge-cleanup --execute` and full classified gates) MUST be launched via the host's native background execution and completion-notification mechanism, never in the foreground, without adding any new guard or runner wrapper.

## Grounded Recon
- `skills/1-hourly/kickstart/SKILL.md` specifies observer/child delegation and session recovery (sections 1 and 4) and launch authority defaults (KS-03), but does not explicitly forbid foreground execution of `merge-cleanup --execute` or full classified gates or state the U7/U8 qualification boundaries.
- Run-1 incident (#1539): a foreground `merge-cleanup --execute` crossed the 10-minute tool timeout and was killed mid-landing, stranding PR #1539.
- `PROJECT/PDDA.md:462-465` defines `CHANGELOG_WRITES` modes (`off` default, `landing` opt-in, legacy `branch`): PR branches under `off`/`landing` must NOT edit `CHANGELOG.md`.
- `utils/ci-route.sh` classifies edits limited to `skills/1-hourly/kickstart/SKILL.md`, `PROJECT/**`, `TESTS-RESULTS/**`, and `releases.db`/`releases.sql` as `route=docs`.

## Plan
1. Add a concise **Long Operations (Background-Only Execution, KS-07)** subsection to `skills/1-hourly/kickstart/SKILL.md` under Section 1 (Child execution contract):
   - `merge-cleanup --execute` and full classified gates (`./validate.sh` / full-route pre-push or disposable-clone gates) MUST launch through the host's native background execution mechanism and wait via native completion notification (no polling loops, no `sleep`, no custom wrapper/guard/runner).
   - Explicitly forbid foreground execution of those operations; a host lacking native background execution halts under Transition 3 (Shared Unsafe Stop) rather than falling back to foreground execution.
   - Record U7/U8 qualification boundaries honestly: controlled/disposable-clone checks verify the foreground-timeout kill vs host-native background-completion mechanism without manufacturing production incidents (U8), while full run-2 acceptance additionally requires at least one real run-2 >10-minute operation completing in the background with its result consumed exactly once (U7 — explicitly uncredited until run 2).
2. Honor the repository's configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off` / `landing`).
3. Retain paired red/green evidence under `TESTS-RESULTS/2026-11-20+GH-1551/` (no new test suite, GH-831):
   - **Controlled mechanism probe (`605s` > 10 min):** paired synthetic workload labeled explicitly as a controlled foreground-timeout vs host-native-background mechanism check (not a replay of the production landing entry point) — red foreground 600s timeout kill (incomplete marker) vs green host-native background completion at 605s (completed marker, exit 0, delivered via native completion notification), recording exact command, exit status, launch/completion timestamps, and U7/U8 scope limits.
     - **Superseded by what was executed:** the original plan expected one 605 s probe to show both the 600 s kill and a native completion. On Antigravity the 605 s probe showed only the red arm (kill at exactly 600 s) plus detached-OS survival at 605 s; native completion past 600 s was shown separately on Claude Code with a 660 s `run_in_background` command (`TESTS-RESULTS/2026-11-20+GH-1551/outputs/host-bg-600s-claude-code.md`). Read the green arm above as that split, not as a single 605 s native completion.
   - Source-only instruction walkthrough + `./utils/pdda/pdda.sh run` (0 errors) + `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` mandates host-native background launch + completion notification for `merge-cleanup --execute` and full gates, forbids foreground fallback (unsupported host -> Transition 3), introduces zero new wrappers/runners, and states U7/U8 honestly.
- Controlled >10-min paired mechanism check (labeled accurately, with U7 real-run acceptance explicitly deferred) recorded under `TESTS-RESULTS/2026-11-20+GH-1551/` with `provenance.jsonl`.
- `./utils/pdda/pdda.sh run` passes with 0 errors and `CHANGELOG_WRITES` policy is respected.

## Rating
- 2026-11-20: rated 40/35/50/70 (pri/sev/appeal/effort).
- Rationale: process hardening of the kickstart skill text; a missed foreground ban risks a killed landing, not data loss.
- Roadmap row `rmi-01M7XEJR8KTN1FWEFYCJB2HFRE` picked up via `releases_app.py roadmap pickup`.
