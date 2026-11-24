# RELAY · GH-1580 final QA (plain-gate rewrite, single round)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1580-final-qa-plain): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1580-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/d67c8fc2-b01d-447c-9384-355c25b46faa/scratchpad/gh1580-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: the plan's `## Acceptance` list in `PROJECT/2-WORKING/GH-1580-PREFLIGHT-MISREPORTS-GAPS.md` is satisfied by the committed change, the evidence under `TESTS-RESULTS/2026-11-23+GH-1580/` substantiates it, and the change causes no new false refusal and no regression. Nothing is deferred (preflight is a gate surface).

## Settled scope (do not re-litigate)

Operator decision 2026-11-24 on #1580 (https://github.com/HiQS-Labs/XYZ-forge/issues/1580#issuecomment-7122642807): the earlier shell parser (`_gate_tokens` / `gate_command_gap`, ~265 lines, four final-QA rounds of new shell shapes) was DELETED. Replacement: a plain-gate rule. A gate that is only plain commands joined by `&&` has every command checked by the existing per-program rules. Any other gate keeps the first-command check it has today and prints a non-blocking gap saying its later commands were not checked. **Accepted trade-off: a missing command inside a non-plain gate is a visible gap, not a refusal.** Therefore "complex gates are only warned about" and "a missing command in a non-plain gate is not refused" are NOT findings. The history is in `relay-system/2026-11-23/gh1580-final-qa*.md` (rounds on the removed parser; F1-F9 there are moot for the new code except as inputs that must not be falsely refused).

## What a finding is

A **new false refusal** (a gate the unchanged base `origin/development` reads READY that the new code reads NOT-READY, unless a command in a PLAIN gate is genuinely missing), a **missed check in a PLAIN gate** (a plain gate with a genuinely missing program/script that reads READY), a **regression** (probes, acceptance gaps, `path_present`, JSON/exit codes, marathon/jog consumers), a claim the evidence does not substantiate, or a new test suite/registry entry (GH-831: forbidden in this repo; a new `test/` file is a finding).

## Review brief

**Step 0 - paraphrase first.** Before reading source, write **What this changes** and **How the existing system works** (2-5 sentences each) from the plan doc alone; then review source-backed.

**Built (whole diff vs the merge-base 2ac998d13, seeded at `.relay-artifacts/gh1580-final.diff`):** `utils/py/swarm_preflight.py` only (plus one sentence in `relay-automation/CONTRACT.example.md`, the plan doc and evidence):
1. `eval_probes` matches grep probes with `re.M` (line anchors); `path_present` on a removed path reads `landed` (was `blocked`).
2. `gate_segments` + `_gate_segment_is_plain` + `_PLAIN_GATE_RE` + `_GATE_NOT_PLAIN` (about 25 code lines): plain = one line after strip, only `[\w./=:,@%+\s-]` and `&&`, every segment non-empty, no segment starting with an assignment/`env`/`cd`/a builtin or keyword in `_GATE_NOT_PLAIN`, no `bash`/`sh` segment using -c/-s/-o/--rcfile before its script. `evaluate_candidate` keeps the BASE gate block verbatim and loops it over `gate_segments(gate_cmd)[0]`; so `test/gh343-gate-program-target-root.sh` needs no edit (its exact-source mutation literal still matches).
3. One advisory list: `acceptance_gaps()` entries plus the non-plain gate gap, in `readiness.gaps` (JSON) and `  gap         :` lines (text). Never changes readiness or an exit code.

**Operational envelope.** Local developer CLI/harness code. Python authoritative; the Bash twin is FROZEN (GH-308); `githooks/` untouched. Challenge over-building.

**Read:** the seeded diff, then the real files: `utils/py/swarm_preflight.py` (`eval_probes`, `gate_segments`, `_gate_segment_is_plain`, the gate block in `evaluate_candidate`, `acceptance_gaps`, `normalize`, `report_candidate`), `git show origin/development:utils/py/swarm_preflight.py` is NOT available to you without git, so compare against the diff's removed lines; `test/gh343-gate-program-target-root.sh`, `test/gh557-unknown-blocks-manifest.sh`, the plan doc, and `TESTS-RESULTS/2026-11-23+GH-1580/{manual-check.md,controls.sh,provenance.jsonl,outputs/*}`. Measure with narrow read-only probes under `.relay-scratch/`; do not run suites (they ran in a disposable clone: `outputs/existing-suites.txt`). The full `validate.sh` gate is intentionally not run yet; it runs once at push via the pre-push hook (GH-1518): not a defect.

**Questions (cite file:line; for a finding give the exact input and observed output):**
1. Can any gate the base reads READY now read NOT-READY, other than a PLAIN gate with a genuinely missing command? Try plain-looking gates: options with arguments (`bash -o pipefail x.sh`), `sh` vs `bash`, `-n`/`-x`, `./prog` paths, `=` in arguments, a trailing `&&`, tabs, `&&&`, `test`/`true` segments, uppercase/unicode word characters.
2. Is any PLAIN gate with a genuinely missing program or script read READY (a missed check)?
3. Is the base per-program block really unchanged (messages byte-identical, structure preserved)? Does the `for … if not ready: break` loop keep behaviour for an empty/whitespace gate and for a first-segment failure?
4. `re.M` and `path_present`: any regression for marathon `acceptance_probes_unmet` or jog? Acceptance gaps still advisory (GH-557)? JSON `readiness.gaps` safe for consumers?
5. Does the evidence substantiate the claims: provenance hashes non-empty and matching; red (base) vs green (head) counts; the all-plain mutant failing the non-plain controls; the regression guard; the 129-contract replay (only GH-269 changes); the identity bracket? Are the controls able to fail (is the gap-line assertion real)?
6. Plan Acceptance 1-5 satisfied? Any finding that asks for a behaviour change needs `Observed input:`, `Affected scope:`, `Falsifier:`.

Include `swept file: yes|no`, a VERDICT (PASS/FAIL/PARKED) with Basis, and set STATUS Approved only if ready to ship.
## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
