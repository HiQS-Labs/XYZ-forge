---
gh_issue: 1580
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1580
title: "swarm_preflight misreports gaps: line anchors ignored, only a gate's first command checked, acceptance check misses real headings"
status: "In Progress (plan QA approved r3; building)"
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
| Recon, red replay on `origin/development` 81eefac61, and Codex plan QA (Approved in round 3; `relay-system/2026-11-23/gh1580-plan-qa.md`). | Build the three fixes in `utils/py/swarm_preflight.py`, green replay, existing suites, final QA, ready PR. |

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
3. **Acceptance.** `ACC_HEADING_RE` accepts a level 2-6 `Acceptance`, `Suggested Acceptance` or
   `Acceptance Criteria` heading (with a colon or qualifier), and no other wording. An issue whose criteria sit under "Done when", "To fix", "Ask" or
   "Findings" yields `unknown [cause: no-issue-section]`, and outside a frozen manifest the verdict stays
   ready (exit 0, GH-557 by design). The line says `unknown` but is not flagged as something to act on and
   does not name the heading the issue does have, so five real issues went through with their acceptance
   unverified.

Findings 4-6 of #1580 (relative `--project-doc` from a clone, system python 3.9 and PEP 604, conveyor asking
for a Status table PDDA forbids in `1-INBOX`) are separate follow-ups and stay out of this change.

## Recon map (base 81eefac61)

- Canonical implementation: `utils/py/swarm_preflight.py` (Python is authoritative; `utils/swarm-preflight.sh`
  is FROZEN by GH-308 and untouched).
- `eval_probes` has two in-repo consumers: preflight's own `inspect_repository` (`swarm_preflight.py:1551`,
  readiness) and `utils/py/marathon_drive.py:2681-2704` `acceptance_probes_unmet` (the GH-438 post-build
  re-check, which rejects every result except `landed`). Jog credits preflight exit 4 as completed
  (`jog_run.py:648-651`), so correcting a false STALE matters there too. Fixing
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
   (bash/sh script file, program path, PATH lookup, existing messages) to the program of each simple command,
   after skipping leading `NAME=value` assignments, `env` (with its assignments/options) and `!`.
   "Every command" means every statically resolvable simple command. Not proven, and skipped rather than
   guessed: shell builtins/keywords (`export`, `set`, `source`, `if`, …), a program word that needs expansion
   (`$VAR`, `${VAR:?}`, `$(…)`, backticks), and the inside of `bash -c '…'` (its argument is not a script path).
   No recursive shell parsing.
   **Working directory (QA F1, narrowed in r2).** The helper tracks one directory (starting at target_root) and
   moves it only for a `cd <literal-existing-dir>` that provably ran in the main shell: the literal is a plain word
   (no expansion, `~`, glob, `-`), the directory exists, the `cd` is not a pipeline stage or backgrounded (`|`,
   `&`), and it is not followed by `||`. Subshells `( … )` restore the directory when they close. A `cd` that was
   reached through `&&` is only certain inside that `&&` run: when the run ends at `;` or a newline the directory
   becomes indeterminate. Anything else (`true || cd x`, `cd x | cat`, `cd x || exit`, non-literal targets) makes the
   directory indeterminate. While it is indeterminate, relative script and program-path checks are skipped (PATH
   lookups still run); absolute operands are unaffected. Straight-line `cd src && bash -n ok.sh` is checked
   against `src/`.
   Downstream limit, recorded not fixed: a gate that starts with `NAME=value prog` now passes preflight, but
   marathon-drive's own pre-advance check still refuses it (`marathon_drive.py:2074-2075`); that module is out of
   scope, so preflight READY does not promise end-to-end readiness for that shape.
3. **Acceptance gap.** Reuse the existing acceptance report path. When the issue states no `## Acceptance`
   section (`cause: no-issue-section`), or the capture doc has none and its checklist is read from the whole
   document, record a gap: one `  gap         :` line in the text report and an `acceptance_gaps` list in
   `readiness` JSON. When the issue body carries a recognised alternative heading ("Done when", "To fix",
   "Ask", "Findings"), the gap names it so the fix is one step. Verdict and exit code do not change:
   GH-557 deliberately keeps this advisory outside a frozen manifest.

Final QA round 1 repairs (all four applied, none deferred; preflight is a gate surface):
- F1: a cd reached through `&&` is certain only inside that `&&` run, which now also ends at `||`, `|` and `&`
  (it ended only at `;`/newline), so `false && cd utils && true || bash -n validate.sh` checks the root file.
- F2: interpreter options end at the first operand; a `-c` after the script is the script's own argument
  (`bash absent.sh -c` is checked; `bash -c '…'` still skips). `-o x`, `-O x`, `--rcfile x` and `--` are read.
- F3: unquoted redirections (`>f`, `2>&1`, `&>f`, `<f`, `<<EOF`) are separate tokens, so
  `bash -n validate.sh>/dev/null` checks `validate.sh`; quoted `>` stays literal.
- F4 (same evaluator, found by the whole-file sweep): `path_present` detects an UNWANTED path
  (CONTRACT.example.md), so its absence now reads `landed`; it read `blocked`, which marathon's landed-only
  acceptance re-check can never accept. Parity limit recorded: `_marathon_plan._eval_probe`, `utils/marathon-plan.sh`
  and the frozen Bash twin keep the old `blocked` for a gone path (planner classification only); filed as a follow-up.

Final QA round 2 repairs (none deferred): F5 an assignment-prefixed `cd` (`FOO=1 cd src`) moves the tracked
directory like a bare `cd`; `pushd`/`popd`/`eval`/`source`/`command`/`builtin` make it unknown, and a `cd` under or after
control flow (`if`, `for`, `{ }`, …) is not tracked. F6 heredoc bodies (`<<EOF`, `<<-EOF`, quoted delimiters) are data and
are skipped up to their delimiter line (an unterminated heredoc falls back to the old first-word check). F7 `bash -s` (stdin
mode) takes no script operand, while a `-s`/`-c` after the script is the script's own argument. Same-class audit, fail-safe
skips instead of assertions: `[[ … && … ]]`, `(( … ))`, unquoted globs/braces, process substitution `<(…)`, shell functions
defined in the gate, and a backslash-newline continuation.

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

Existing suite kept truthful (QA F3): `test/gh343-gate-program-target-root.sh:91-104` builds its pre-fix
control by deleting an exact source branch of the inline gate block. Extracting that block into a helper moves
the span, so the suite's replacement literal is updated to the equivalent branch in the helper, and its
"could not construct the exact pre-GH-343 control branch" guard stays. This only keeps existing coverage
truthful; it adds no test.

Manual evidence (QA F2): `TESTS-RESULTS/2026-11-23+GH-1580/controls.sh` now records, per case, the expected
exit and expected lines next to the observed ones and prints MATCH/MISMATCH, runs the acceptance case in both
text and `--format json` (nonempty JSON, `readiness.acceptance_gaps`, the named alternative heading, unchanged
exit 0, the no-gap control, and the capture-doc whole-document case), keeps the lowercase `gap` line in its
output filter, and writes `provenance.jsonl` tying each run to its revision, command, exit code and output
hash. Red must show MISMATCH on the unchanged source; green must show MATCH everywhere.

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
