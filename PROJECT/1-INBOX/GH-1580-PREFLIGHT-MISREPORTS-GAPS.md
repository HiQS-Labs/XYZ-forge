---
gh_issue: 1580
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1580
title: "swarm_preflight misreports gaps: line anchors ignored, only a gate's first command checked, acceptance check misses real headings"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-11-23
updated: 2026-11-23
owner: Claude (start-task sub-agent)
doc_type: bugfix
goal: "swarm_preflight reports probe, gate and acceptance gaps correctly instead of silently reading wrong."
effort: 1
complexity: 2
risk: 2
phases: 1
---

# GH-1580 — swarm_preflight misreports gaps

## Status

| What was just completed | What's next |
|---|---|
| Recon of #1580, its source (BinoidCBD/LTVera-Pandas#1205) and every preflight caller; red replay recorded against `origin/development` 81eefac61. | Codex plan QA, accepted-start, build the three fixes in `utils/py/swarm_preflight.py`, green replay, final QA, ready PR. |

## Observed problem

Source: BinoidCBD/LTVera-Pandas#1205 (software-factory test, 2026-11-20). Its purpose was to see whether
preflight can compute the gaps between an issue and pickup without a human. Three defects make it
report wrong answers. All three are still present on `origin/development` (81eefac61).

1. **Probe anchors.** `eval_probes` (`utils/py/swarm_preflight.py:250-292`) calls `re.search(pattern, text)`
   with no `re.M`, so `^`/`$` anchor to the file, not the line. A line-anchored `grep_present` reads as
   already-landed (preflight STALE, exit 4). A `^`-anchored `grep_absent` reads `unfixed` forever, so a real
   fix never flips it and a lane rebuilds without end.
2. **Gate existence.** The check at `swarm_preflight.py:1785-1814` inspects `gate_cmd.split()[0]` only. LTVera
   #1140's gate, with `bash -n …` moved in front of `uv lock --check`, turned NOT-READY into READY with `uv`
   still missing.
3. **Acceptance.** `extract_acceptance_criteria` reads only a `## Acceptance` heading. An issue whose criteria
   sit under "Done when", "To fix", "Ask" or "Findings" yields `unknown [cause: no-issue-section]`, and
   outside a frozen manifest the verdict stays ready (exit 0, GH-557 by design). Nothing says what to do
   about it, so five real issues went through with their acceptance unverified.

Findings 4-6 of #1580 (relative `--project-doc` from a clone, system python 3.9 and PEP 604, conveyor asking
for a Status table PDDA forbids in `1-INBOX`) are separate follow-ups and stay out of this change.

## Recon map (base 81eefac61)

- Canonical implementation: `utils/py/swarm_preflight.py` (Python is authoritative; `utils/swarm-preflight.sh`
  is FROZEN by GH-308 and untouched).
- `eval_probes` has two in-repo consumers: preflight's own `evaluate_candidate` (readiness) and
  `utils/py/marathon_drive.py:2681` `acceptance_probes_unmet` (the GH-438 post-build re-check). Fixing
  anchors in `eval_probes` therefore fixes both with one edit, and keeps them agreeing.
- Gate check is inline in `evaluate_candidate` (`:1785-1814`); consumers of its verdict are the preflight
  exit code 5 (NOT-READY) read by `jog_run.py` `_dry_run_preflight` / live executor,
  `_marathon_plan.py:1321`, `marathon-drive`, conveyor and 10days through the CLI. A new NOT-READY can
  only come from a gate that names a program or script that genuinely does not resolve.
- Acceptance check: `check_acceptance_fidelity` (`:928`), report lines (`:1941-1958`), JSON readiness
  (`:396-416`, built by `normalize`), packet provenance line (`:2028`).
- Contracts in the repo with line-anchored probe patterns: none active (one `^  push:` in a 2-WORKING doc
  that uses the unknown key `kind`, so it already evaluates `blocked`).
- Gate strings in the repo's own contracts (survey of `"gate":` values): single commands, `&&` chains of
  `bash test/...`/`python3 -m pytest`, and placeholders. The new per-command check is replayed on every
  chain form during the build.
- Prior art: GH-400/GH-557 (acceptance fidelity, unknown stays advisory outside a frozen manifest, pinned
  by `test/gh557-unknown-blocks-manifest.sh` case 2), GH-343/GH-308 (gate program resolution),
  GH-438 (re-check). Existing-fix candidates reported by `prior_art_recon` (#1426, #1257, #396) are
  different subjects; none changes anchors, chained gates or the acceptance gap.

## Plan

Extend the existing evaluator and report path. No new module, suite, flag or exit code.

1. **Anchors.** One helper in `swarm_preflight.py` used by both `grep_present` and `grep_absent`:
   `re.search(pattern, text, re.M)`. Authors write `^`/`$` to mean line anchors; the LTVera contracts already
   work around it with inline `(?m)`, which stays valid. Add one sentence to
   `relay-automation/CONTRACT.example.md` saying probe anchors match per line.
2. **Gate.** Replace the inline first-token block with a helper that splits the gate on shell control
   operators (`&&`, `||`, `;`, `|`, newline; quotes respected) and applies the *existing* per-program rules
   (bash/sh script file, program path under target_root, PATH lookup, existing messages) to the program of
   each command, after skipping leading `NAME=value` assignments, `env` (with its assignments/options) and `!`.
   Shell builtins/keywords (`cd`, `export`, `set`, `source`, `if`, …) are skipped. A program word that
   needs shell expansion (`$VAR`, `$(…)`, backticks) cannot be resolved at preflight time and is skipped.
   `bash -c '…'` is not treated as a script path.
3. **Acceptance gap.** Reuse the existing acceptance report path. When the issue states no `## Acceptance`
   section (`cause: no-issue-section`), or the capture doc has none and its checklist is read from the whole
   document, record a gap: one `  gap         :` line in the text report and an `acceptance_gaps` list in
   `readiness` JSON. When the issue body carries a recognised alternative heading ("Done when", "To fix",
   "Ask", "Findings"), the gap names it so the fix is one step. Verdict and exit code do not change:
   GH-557 deliberately keeps this advisory outside a frozen manifest.

Non-goals: new exit codes or blocking on the gap (GH-557 control stays exit 0); accepting synonym headings
as criteria (it would change which lanes block, a decision for its own issue); a shell parser; the Bash twin;
`githooks/`; findings 4-6; the marathon-drive pre-advance gate, which keeps its own first-token check.

Risks and rollback: the gate change can only add NOT-READY for a gate that names an unresolvable program or
script; the helper is replayed over every in-repo gate shape. The anchor change makes `$` and `^` per-line
for every probe in every consumer. Rollback is a revert of one commit.

Preflight bet check:
- Outcome: preflight's verdict is true for the three cases, so the factory stops needing a human to find them.
- Smallest bet: three local edits in one file plus one doc sentence; not built: parser, blocking gap, synonym matching.
- Alternative rejected: rejecting anchors loudly. Authors meant line anchors, and rejection would break
  contracts that already work around it with `(?m)`.
- Containment: revert one commit.

Test scope (GH-831): no new suite, no registry entry. Verification = existing preflight coverage
(`test/swarm-preflight.sh`, `gh308-swarm-gate-path`, `gh343-gate-program-target-root`, `gh400-acceptance-fidelity`,
`gh557-unknown-blocks-manifest`, `gh438-acceptance-recheck`, `gh291-contract-goldens`,
`gh280-jog-marathon-adapter`, `test_python_layer.py`) plus a recorded red/green manual check under
`TESTS-RESULTS/2026-11-23+GH-1580/`.

## Acceptance

- [ ] A `^`/`$`-anchored `grep_present` or `grep_absent` probe matches per line: a mid-file line reads as present, and a comment or `echo` mention does not satisfy `^alembic check`.
- [ ] Every command in a gate is existence-checked: `bash -n … && uv lock --check` with `uv` absent is NOT-READY (exit 5) naming `uv`, and a gate with only resolvable programs (cd, env-prefix, pipe) is still READY.
- [ ] An issue with no `## Acceptance` section is reported as a gap in the text report and in `readiness.acceptance_gaps`, naming any "Done when"/"To fix"/"Ask"/"Findings" heading it has, with verdict and exit code unchanged.
- [ ] Red on `origin/development` and green on the changed head are recorded under `TESTS-RESULTS/2026-11-23+GH-1580/` with `provenance.jsonl`, and no new test suite is added.
- [ ] The existing preflight suites and every preflight caller (marathon, jog, conveyor, flywheel, kickstart) are verified unaffected.

## Acceptance — deviations from the issue

- [added] A `^`/`$`-anchored `grep_present` or `grep_absent` probe matches per line: a mid-file line reads as present, and a comment or `echo` mention does not satisfy `^alembic check`. — reason: #1580 has no acceptance checklist; these restate its three defects and R2 as machine-checkable criteria.
- [added] Every command in a gate is existence-checked: `bash -n … && uv lock --check` with `uv` absent is NOT-READY (exit 5) naming `uv`, and a gate with only resolvable programs (cd, env-prefix, pipe) is still READY. — reason: #1580 has no acceptance checklist; these restate its three defects and R2 as machine-checkable criteria.
- [added] An issue with no `## Acceptance` section is reported as a gap in the text report and in `readiness.acceptance_gaps`, naming any "Done when"/"To fix"/"Ask"/"Findings" heading it has, with verdict and exit code unchanged. — reason: #1580 has no acceptance checklist; these restate its three defects and R2 as machine-checkable criteria.
- [added] Red on `origin/development` and green on the changed head are recorded under `TESTS-RESULTS/2026-11-23+GH-1580/` with `provenance.jsonl`, and no new test suite is added. — reason: #1580 has no acceptance checklist; these restate its three defects and R2 as machine-checkable criteria.
- [added] The existing preflight suites and every preflight caller (marathon, jog, conveyor, flywheel, kickstart) are verified unaffected. — reason: #1580 has no acceptance checklist; these restate its three defects and R2 as machine-checkable criteria.

## Rating rationale (2026-11-23)

pri 70 / sev 65 / appeal 50 / effort 75. Severity: preflight is a gate surface and returns a wrong verdict
silently (an endless rebuild loop, a READY on an unrunnable gate, unverified acceptance); no data is lost and
a human can recover. Priority: severity-led, plus the operator's instruction that preflight findings are never
deferred. Appeal: neutral 50, no stated preference. Effort: one file and one doc sentence, local edits.
Recurrence: window 2026-10-26..2026-11-23 shows ~11 preflight-titled issues of mixed classes; the same
class (preflight reporting a wrong readiness) is #1426 and this one, so the trend is unknown rather than
rising. The three defects were hit repeatedly within the single #1205 run.

## Red/green evidence

`TESTS-RESULTS/2026-11-23+GH-1580/` (script `controls.sh`, outputs `red.txt`, `green.txt`, `provenance.jsonl`).
