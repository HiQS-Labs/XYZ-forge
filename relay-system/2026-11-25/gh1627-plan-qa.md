# RELAY · GH-1627 plan QA - gate selects prepared test venv
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Manual relay: commit only the relay file** (`relay(gh1627-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1627-GATE-VENV-AUTOSELECT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1627-GATE-VENV-AUTOSELECT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Definition of Done: the plan's "Requirements" 1-5 (issue #1627 Acceptance) are each met by the plan, each with a falsifiable check that rejects the unchanged base.

### Review packet (plan QA, round 1)

**Paraphrase first (GH-1414).** Before reading anything except the plan, write 2-5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not**. Distinguish excluded work, deferred work, unresolved choices. Record this initial paraphrase as the first part of your review block, then continue with the source-backed assessment (label it "source-backed").

**Operational envelope.** Local developer shell gate in a single repo (`validate.sh`, a bash script). Grade against the stated requirements, commensurate complexity, and the repo's own rules: AGENTS.md "No new tests" (GH-831: no new suites or registry entries; use existing suites or manual checks under `TESTS-RESULTS/`), the GH-732 environment-fault contract, and `utils/py` / `githooks` conventions. Do not ask for speculative machinery (path knobs, locks, journals, venv creation).

**Read:** `PROJECT/2-WORKING/GH-1627-GATE-VENV-AUTOSELECT.md` (the plan, `.relay-artifacts/` copy), `validate.sh` (the `GH-732 environment faults BEGIN/END` block and everything up to `--print-mode`), `githooks/pre-push`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`gate_toolchain_fault_reason`, `preflight_warnings`), `test/gh251-validate-pytest-skip.sh`, `README.md` (gate toolchain paragraph), `skills/2-daily/merge-cleanup/SKILL.md:269`, issues #1627 / #1437 / #1606 (as quoted in the plan).

**Questions (cite file:line):**
1. Is every claim in the plan's "Observed problem" table grounded in the actual paths? Is any entry wrong or missing?
2. Does the plan make a failing `python3` + healthy venv run on the venv, and ONLY then? Does the second `_xyz_python_probe python3` keep the failure output (fault line, remedy, exit 3) byte-identical to base when the venv is missing/failing? Is there any state (e.g. `_python_missing`, `_python_version`, PATH) that leaks differently from base?
3. Is it right that `githooks/pre-push` and `merge_cleanup.py` need no change? Trace every `python3` use before validate.sh in the hook (gate_receipt.py admit/check, docs route via pdda.sh, tier-2 route) and name any that would behave differently when PATH python3 is the toolchain-less 3.14. Does merge-cleanup's `validate.sh --print-mode` probe agree with the gate in all three cases?
4. Does the selection still hold for suites that re-exec `python3` or invoke `validate.sh` recursively (nested runs in the existing gh251 suite use a failing shim first on PATH)? Is the planned `HOME=` isolation of gh251's two failing-interpreter cases the right and minimal fix, and does anything else in `test/` break on a machine that has the venv?
5. What prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? Check the (a)-(f) table: does each row have a rejecting control on base, and is any row vacuous?
6. Is the plan surgical and DRY (one function, no copied module list, no second selector)? Flag any machinery that is unneeded, and any requirement left unmet. Does the plan respect "no change outside the repo" (no profile, no auto venv, no Homebrew edit)?
7. Surface-triggered: modified existing tests (Test-Honesty: does the gh251 edit keep its assertions real?); new wrapper layers (none intended).

Write your verdict (PASS / FAIL / PARKED, with `swept file: yes|no`) and set STATUS Approved only if the plan can be built as written.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**What this proposes**

The gate will reuse its existing Python probe to select the prepared home-directory venv only when PATH's Python fails and that venv passes. It will prepend the venv for this gate process and its children, announce the interpreter, preserve existing failure diagnostics otherwise, and isolate two existing gh251 failure cases from the user's venv.

**How the existing system works, per this document**

The document places the sole toolchain probe in validate.sh, before --print-mode. It says the hook delegates gate execution there, while merge-cleanup calls --print-mode and interprets its exit status; earlier hook receipt operations allegedly need only the standard library.

**What it's not**

Excluded: venv creation, system/profile changes, a path override, new suites, hook routing changes, and replacing healthy PATH Python. Deferred: ci-local.sh's independent Python invocations. No unresolved implementation choice is declared; the document says uncertainty is not material.

**Source-backed assessment**

swept file: yes

Scope/evidence: read the entire seeded plan, the existing GH-732 block and pre-print-mode control flow, hook routes, gh251, and the named merge-cleanup functions. Graph discovery used the nearest indexed project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-26T04:31:47Z`; this relay worktree is not indexed, and that other checkout's graph lacks `gate_toolchain_fault_reason`. Consequently all material citations below use this worktree's source. Coverage returned no recorded issues for the eight requested evidence paths in that other checkout, but known gaps in `test/`; local literal searches supplemented it. No exhaustive claim about every test's runtime is made. The whole-plan sweep found the existing inaccuracies below, not an additional implementation defect. No gate is configured in these Reviewer steps and none was run.

- **[Should] F1 — Correct the acceptance table's baseline claims before treating it as executable acceptance.**
  **Observed input:** Form 1 contradictions: `.relay-artifacts/GH-1627-GATE-VENV-AUTOSELECT.md:106` says the real push base exits 3, whereas `githooks/pre-push:453-472` captures the gate's 3, prints it, and exits **1**. Plan line 108 says unmodified base gh251 is green “only without the venv (recorded)”; `validate.sh:1035-1045` never reads the venv and `test/gh251-validate-pytest-skip.sh:60-85` already expects the PATH-shim refusal irrespective of HOME. The record cited by that parenthetical is not supplied.
  **Affected scope:** rows d/f and the distinction between the base suite and the changed selector with the unadjusted suite; no production behavior change requested.
  **Falsifier:** in disposable clones, base push must be nonzero with the inner gate's exit-3 diagnostic and no remote-ref advance; base gh251's negative cases must behave identically with the prepared venv present or absent. A changed selector plus the unadjusted gh251 should reject the newly available fallback; the HOME-isolated version should restore the negative cases. Results contradicting this trace should reopen the assessment.
  **Fix:** record push exit 1 separately from inner gate exit 3, correct row f to distinguish base from selector-changed/unadjusted-test behavior, and remove “recorded” until there is a linked receipt. Keep b1/b2/c/f explicitly labeled preservation/regression controls: they should not reject the unchanged base. The actual unchanged-candidate rejection comes from a, d and e(a), not from pretending every preservation row turns red on base.
  Narrow source probe (exit **0**, no gate/fixture execution):
  ```python
  # python3 -B - <<'PY' ... PY
  from pathlib import Path
  v = Path('validate.sh').read_text()
  h = Path('githooks/pre-push').read_text()
  b = v.split('# GH-732 environment faults BEGIN', 1)[1].split('# GH-732 environment faults END', 1)[0]
  assert b and h
  assert b.count('test-venv') == 1
  assert 'test-venv' in next(l for l in b.splitlines() if 'ENVIRONMENT FAULT: python3' in l)
  assert h.rstrip().endswith('exit 1')
  assert 'documentation gate, not validate.sh.' in h
  print('base probe: test-venv occurs only in diagnostic; HOME cannot enable fallback')
  print('hook: docs route bypasses validate.sh; final refusal exits 1')
  ```
  Decisive output: `base probe: test-venv occurs only in diagnostic; HOME cannot enable fallback` and `hook: docs route bypasses validate.sh; final refusal exits 1`.

- **[Should] F2 — Make the healthy-interpreter and push controls discriminating, and complete the preflight matrix.**
  **Observed input:** `.relay-artifacts/GH-1627-GATE-VENV-AUTOSELECT.md:105` permits the healthy PATH Python to be the same prepared venv, making an always-prepend substitution observationally indistinguishable by interpreter identity. Line 107 tests preflight only for a/b, despite requirement 4 at line 51 promising all three states. Line 106 leaves the pushed route and receipt state unspecified, while `githooks/pre-push:390-395` and `:421-440` can succeed without running validate.sh. The observed-problem claim “all gate work is inside validate.sh” at plan line 38 is therefore false.
  **Affected scope:** manual rows c/d/e and the plan's description of process-local PATH inheritance; retain the existing implementation scope.
  **Falsifier:** c uses a healthy interpreter path distinct from the fallback and observes that same interpreter in a downstream child, with no notice; e also returns `''` for that healthy-PATH case; d's transcript demonstrates the actual tier-2/full gate ran, with no bypass or receipt reuse, and a local remote read-back shows the candidate ref landed. An unchanged base must fail d at the toolchain probe before publication, not at accounting or unrelated checks.
  **Fix:** add those explicit preconditions/observables to c/d/e, including valid existing attempt accounting (`githooks/pre-push:90-99`, `validate.sh:1063-1068`). State that each validate.sh invocation selects independently: its PATH export reaches its children, not the parent hook. A normal push calls both --print-mode and the real gate (`githooks/pre-push:354-359`, `:445-453`), so “one notice” is per validate invocation, not necessarily once across the push. Document the docs-only and receipt-reuse exceptions; no hook rewrite is needed for the stated toolchain-less 3.14 case.

- **[Pass] Core selector is surgical and DRY.** Plan lines 58-70 preserve one module list/version floor, reset the version and missing-module state on each probe, and re-probe PATH after a rejected fallback. Against `validate.sh:1035-1045`, that preserves the fault text/state for stable missing/failing-venv cases and leaves healthy PATH untouched. Exporting PATH at plan line 64 supplies the selected executable to child workers and nested validate invocations; explicitly injected shims still take priority in gh251. Keeping HOME isolation local to the two calls at gh251 lines 60/78 preserves the assertions at 61-66/79-85, including refusal before pytest. Plan lines 72-73 and 98 require existing coverage/manual evidence only, with no new suite, external profile edits or automatic installation. No extra selector, knob, lock or wrapper is warranted.

- **[Pass] No hook or merge-cleanup code change is justified for a runnable Python 3.14 missing the four development modules.** Hook admission/check use gate_receipt (`githooks/pre-push:92-97`, `:426`), whose imports plus rtl's imports are standard-library (`utils/py/gate_receipt.py:13-24`, `utils/py/rtl.py:1-16`). Probe: `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$PWD/utils/py" /opt/homebrew/bin/python3 -B -c 'import sys, gate_receipt; print("gate_receipt import OK; Python", sys.version.split()[0])'` → exit **0**, `gate_receipt import OK; Python 3.14.7`. The classifier's Python uses sys/re (`utils/ci-route.sh:183-184`). Docs routing runs PDDA directly: its map/scanners/marathon checker use standard-library imports (`utils/pdda/pdda.sh:645-647`, `:1251`, `:1385`, `:1696`; `utils/py/pdda_gov_scan.py:58-59`, `utils/py/pdda_comment_refs.py:17-19`, `utils/pdda/check_marathon_qa.py:17-22`); missing pytest/yaml/requests/mypy alone does not alter those paths. This does not promise rescue for an absent or nonfunctional Python executable before hook admission. merge-cleanup's function calls the gate and returns empty on rc 0 or its fault lines otherwise (`merge_cleanup.py:1083-1097`); `preflight_warnings` consumes it at 1444-1448. Its decision should follow the selector without duplicating it.

- **[Unverified — needs clone run] Delivery evidence remains future work.** Rows a/d/e identify intended red controls, not observed rejections in this review. Real suite execution, push publication, byte-identical failed-fallback output and complete gh251/GH-732 regressions must be measured in disposable full clones with provenance as the plan requires at line 98. Local literal searches found no additional Python-fault assertion site beyond gh251; that is bounded source evidence, not proof that every suite passes with the venv. The related issues were assessed only as quoted in the plan, not independently fetched.

Handing off to Producer (claude-a) — correct the acceptance matrix and routing description, then return for plan QA. The selector design can remain as proposed.

VERDICT: FAIL
Basis: The implementation approach is proportionate, but the plan as written contains false baseline outcomes and leaves key acceptance cases able to miss the claimed behavior. F1/F2 require small plan corrections; no production redesign or new tests are requested.

### Producer · Round 1 · claude-a

Dispositions:
- **F1 [Should] — Implemented.** Plan "Observed problem" now records that the hook exits 1 on a gate failure with the inner gate status (3) in its message; the gh251 row states that base never reads the venv, so base gh251 is green with or without it, and the selector plus the *unadjusted* suite is what goes red on a venv machine. The unsupported "recorded" claim is removed. The matrix is split into rejecting controls (a, d, e(a)) and preservation controls (b1, b2, c, e(b/c), f).
- **F2 [Should] — Implemented.** c now uses a healthy PATH python at a path distinct from the venv and observes the interpreter in a child; e covers (a), (b1), (b2) and (c); d requires a code-path diff so the tier-2/full gate is reached, valid accounting, a transcript showing the gate ran (no receipt reuse, no bypass), and a `git ls-remote` read-back, with base expected to refuse at the toolchain fault (hook exit 1, inner 3). The false "all gate work is inside validate.sh" is corrected: docs route and receipt reuse skip validate.sh and are unchanged by this work; each validate.sh invocation selects independently, so notices are per invocation (two on a normal push), not per push.
- The two `[Pass]` findings and the `[Unverified — needs clone run]` item are accepted as stated; the latter is the build-phase evidence.

Handing off to Reviewer (codex) for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
