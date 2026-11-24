---
gh_issue: 1580
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1580
title: "swarm_preflight misreports gaps: line anchors ignored, only a gate's first command checked, acceptance check misses real headings"
status: "In Progress (gate extension withdrawn, remaining fixes in qualification)"
created: 2026-11-23
updated: 2026-11-24
owner: Claude (start-task sub-agent)
doc_type: bugfix
goal: "Correct grep probe anchors, removed-path probes and missing acceptance reporting."
effort: 1
complexity: 2
risk: 2
phases: 1
---

# GH-1580 — swarm_preflight misreports gaps

## Status

| What was just completed | What's next |
|---|---|
| The single allow-list repair addressed F1 and F2. Final QA reproduced a new false refusal for `NAME+=value` in a later command. The operator's fallback restores the exact development first-command check. | Qualify and publish the probe and acceptance fixes. Leave the second-command gap open on the issue. |

## Observed problem

Source: BinoidCBD/LTVera-Pandas#1205 (software-factory test, 2026-11-20): preflight reports wrong answers
silently. Three defects, all present on `origin/development`:

1. **Probe anchors.** `eval_probes` calls `re.search(pattern, text)` with no `re.M`, so `^`/`$` anchor to the
   file, not the line. A line-anchored `grep_present` reads as already-landed (preflight STALE, exit 4). A
   `^`-anchored `grep_absent` reads `unfixed` forever, so a real fix never flips it and a lane rebuilds
   without end.
2. **Gate existence.** The gate check inspects only the first word of the gate. LTVera #1140's gate, with
   `bash -n …` moved in front of `uv lock --check`, turned NOT-READY into READY with `uv` still missing.
3. **Acceptance.** `ACC_HEADING_RE` accepts a level 2-6 `Acceptance`, `Suggested Acceptance` or
   `Acceptance Criteria` heading (with a colon or qualifier), and no other wording. An issue whose criteria sit
   under "Done when", "To fix", "Ask" or "Findings" yields `unknown [cause: no-issue-section]`, and outside a
   frozen manifest the verdict stays ready (exit 0, GH-557 by design). The line says `unknown` but flags
   nothing to act on and names no heading.

Findings 4-6 of #1580 (relative `--project-doc` from a clone, system python 3.9 and PEP 604, conveyor asking
for a Status table PDDA forbids in `1-INBOX`) are separate follow-ups and stay out of this change.

## Recon map

- Canonical implementation: `utils/py/swarm_preflight.py` (Python is authoritative; `utils/swarm-preflight.sh`
  is FROZEN by GH-308 and untouched).
- `eval_probes` has two in-repo consumers: preflight's own `inspect_repository` (readiness) and
  `utils/py/marathon_drive.py` `acceptance_probes_unmet` (the GH-438 post-build re-check, which rejects every
  result except `landed`). Jog credits preflight exit 4 as completed, so a false STALE matters there too.
- The gate check is inline in `evaluate_candidate`; its verdict is the preflight exit code 5 (NOT-READY) read by
  `jog_run.py`, `_marathon_plan.py`, `marathon-drive`, conveyor and 10days through the CLI. flywheel and kickstart
  compose those owners. `test/gh343-gate-program-target-root.sh` builds its pre-fix control by deleting an exact
  source branch of that block, so the block keeps its base text.
- Acceptance check: `check_acceptance_fidelity`, report lines, JSON `readiness` built by `normalize`.
- No active contract uses a line-anchored probe pattern (the one `^  push:` uses the unknown key `kind`).
- Prior art: GH-400/GH-557 (acceptance fidelity, `unknown` stays advisory outside a frozen manifest, pinned by
  `test/gh557-unknown-blocks-manifest.sh` case 2), GH-343/GH-308 (gate program resolution), GH-438 (re-check).

## Plan

Extend the existing evaluator and report path. No new module, suite, flag or exit code.

1. **Anchors.** `re.search(pattern, text, re.M)` in both grep branches of `eval_probes`; one sentence in
   `relay-automation/CONTRACT.example.md`. Inline `(?m)` stays valid; `\A`/`\Z` anchor the whole file.
2. **Gate scope withdrawn.** This release restores the existing first-command gate check.
   The allow-list review reproduced a false refusal for `true && PYTHONPATH+=:src python3 -V`.
   The operator directed shipping the remaining fixes after that failure. The missing later
   `uv` case remains open (see the issue and final relay).
3. **Gaps.** Use the existing acceptance evaluation to surface missing issue or capture
   acceptance sections in text and JSON. Keep the non-manifest gap advisory (GH-557).
4. **Removed path.** An absent path under a `path_present` probe has landed. Planner
   parity is tracked separately by the existing #1583.

## Acceptance

- [ ] Line-anchored grep probes match individual lines and ignore comment/echo mentions at unmatched positions.
- [ ] A removed unwanted path reads as landed.
- [ ] Missing acceptance sections appear as advisory text and JSON gaps, naming alternative issue headings when present.
- [ ] The first-command gate check matches development byte for byte, with legacy cases verified through the CLI.
- [ ] Retained red and green controls and independent review cover this reduced scope.

## Acceptance — deviations from the issue

- [deferred] Extend preflight to check later commands. The single authorized final review showed another false refusal after the allow-list repair. This PR leaves #1580 open for that gap and the other follow-ups.
- [added] Treat a removed unwanted path as landed, from earlier final QA F4. The fixture in the existing controls verifies both path states.

## Rating rationale (2026-11-23)

pri 70 / sev 65 / appeal 50 / effort 75. Severity: preflight is a gate surface and returns a wrong verdict
silently (an endless rebuild loop, a READY on an unrunnable gate, unverified acceptance); no data is lost and
a human can recover. Priority: severity-led, plus the operator's instruction that preflight findings are never
deferred. Appeal: neutral 50, no stated preference. Effort: one file, local edits. Recurrence: window
2026-10-26..2026-11-23 shows ~11 preflight-titled issues of mixed classes; the same class (preflight reporting
a wrong readiness) is #1426 and this one, so the trend is unknown rather than rising.

## Red/green evidence

`TESTS-RESULTS/2026-11-23+GH-1580/` (`controls.sh`, `outputs/*.txt`, `provenance.jsonl`, `manual-check.md`).

## Merge evidence

- PR #1593 merged 2026-11-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
