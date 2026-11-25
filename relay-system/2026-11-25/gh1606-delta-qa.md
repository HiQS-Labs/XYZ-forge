# RELAY · GH-1606 delta QA — a nonzero probe exit with no fault line must not defer (PR #1614 review)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh1606-delta-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1606-delta.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-XYZ-forge/e3f96cf1-a102-4b6b-8e5b-e513c6a2ffc3/scratchpad/GH-1606-delta.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: the post-approval change is correct and minimal, is consistent with the approved plan and `SKILL.md`, regresses none of the previously approved behaviour, and its retained controls would have rejected the unfixed code.

### Context (read this first)
- Codex plan QA (APPROVED round 3) and Codex final QA (APPROVED round 2, reviewed head `15792a167`) covered the code through `11ac019c7` / published head `99433678e`. PR #1614 was then opened. CodeRabbit's PR review raised ONE valid inline finding, which is the only reason this delta exists:
  > `gate_toolchain_fault_reason` returns the output tail when `validate.sh --print-mode` exits nonzero WITHOUT an `ENVIRONMENT FAULT` line, so the execute path defers a PR for a reason that names no fault (e.g. a clone whose own `validate.sh` rejects `--print-mode`). It conflicts with the helper's docstring and with the rule that a probe which cannot answer is skipped.
- The change under review is the delta from `99433678e` to the current HEAD, supplied as the artifact above (`skills/`, `TESTS-RESULTS/`, `PROJECT/`): the helper now returns `""` when no fault line is present; the plan, summary and provenance are updated; the driver gained `AC-1-nofault-red/green` and an end-to-end scenario `S8` (a `validate.sh` that answers `--print-mode` with a usage error and exit 2); the provenance was regenerated on the new commit and no longer contains an expanded home-directory path.
- Note: you earlier accepted the "empty nonzero fallback" at final QA round 2 (your probe asserted `reason(3)=='validate.sh --print-mode exited 3: '`). The fix reverses that on purpose. Say whether you now agree with the reversal and why, citing the plan's own rule and `skills/2-daily/merge-cleanup/SKILL.md:269`.

### Operational envelope and non-goals
- Same as before: local operator CLI tooling; grade against stated requirements and commensurate complexity. XYZ-forge forbids new tests (GH-831): a new `test/` suite or `validate.sh` entry is a finding; `run_controls.py` is a manual driver under `TESTS-RESULTS/`. No change to hook routing, the 2-repair budget, accounting, or the push path.
- Not yet run by design: the repository qualification gate on the new commit and hosted CI for the new head. Do not assume them and do not demand them here.

### Questions (answer each; cite `file:line`)
1. Is `return " | ".join(faults)` (`merge_cleanup.py` `gate_toolchain_fault_reason`) correct for every output shape: mixed php+python rc 3, php-only rc 0, python-only rc 3, stderr-only rc 3, rc 3 with no fault line, rc 2 with empty output, spawn error and timeout, and absent `validate.sh`? Say what you tried.
2. Is the reversal consistent with the approved plan, the helper docstring, `SKILL.md`, and the dry-run `preflight_warnings` entry (which also calls the helper)? Is there any remaining place that still describes or depends on the old tail fallback (grep the whole tree, not just the diff)?
3. Does the S8 scenario actually reach the code under test, and would the PRE-FIX commit fail it? Is `AC-3-S8-prefix-red` non-vacuous (can it pass on empty or absent output)? Are `AC-1-nofault-red/green` falsifiable?
4. Is anything in the delta outside the one finding's scope? Is the provenance free of absolute home-directory text, and is it internally consistent with `SUMMARY.md` and the plan (counts, commit ids)?
5. Does this change create any new way for a genuinely blocked gate to slip through un-deferred (a missed toolchain fault)? Where does the pre-push hook still enforce it, and is that enforcement unchanged?
6. Anything unverified or overstated in `SUMMARY.md` or the plan's new *Decisions after the PR review* section? Label each gap accepted-and-recorded or a finding.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

Ship the delta; no required changes.

swept file: yes

- [Pass] Q1/Q2 — I agree with reversing my earlier acceptance of the empty nonzero fallback. A usage error is not evidence of a blocking toolchain fault. The plan's skip-on-unanswerable rule (PROJECT/2-WORKING/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md:84-86), skills/2-daily/merge-cleanup/SKILL.md:269, and the helper contract (skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1072-1097) agree. The same helper controls the advisory warning (:1443-1448) and pre-reserve deferral (:2176-2183). Narrow AST-extracted helper probe, with subprocess mocked (no gate or fixture executed), returned: mixed rc3 → both fault lines joined; php-only rc0 → ''; python-only rc3 → python line; stderr-only rc3 → python line; no-fault rc3 → ''; empty rc2 → ''; OSError → ''; TimeoutExpired → ''; absent validate.sh → '' without calling subprocess. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` with ast.parse/compile extracting only gate_toolchain_fault_reason, Path.is_file patched true/false and subprocess.run patched with CompletedProcess or the named exceptions. Exit 0; decisive output: `mixed 'ENVIRONMENT FAULT: php advisory | ENVIRONMENT FAULT: python3 missing modules'`, `no-fault ''`, `empty ''`, `absent ''; subprocess not called`. No fix needed.
- [Pass] Q2 — Whole-tree `rg -n --hidden -g '!.git' -g '!.relay-artifacts/**' 'validate.sh --print-mode exited|output tail|nonzero.*fault line|first.*ENVIRONMENT FAULT' .` exited 0. Remaining fallback descriptions are explicitly historical: relay-system/2026-11-25/gh1606-final-qa.md:153,186 and the accepted PR-review finding at PROJECT/2-WORKING/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md:249. No remaining live fallback dependency found. Preserve historical turns; no fix needed.
- [Pass] Q3 — S8 installs the usage branch before cutting PR branches (TESTS-RESULTS/2026-11-25+GH-1606/run_controls.py:33-39,65-87,184-186); _drive passes GH1606_TOOLCHAIN=usage into main (:121-125). The landing-clone helper then runs before reserve (merge_cleanup.py:2176-2183). Old fallback returns nonempty usage text, so the pre-fix code defers. Candidate S8 requires rc4, MERGED, exactly one attempt and push, and a nonempty published origin head equal to the recorded repair (run_controls.py:304-308,342-344); the prefix-red requires rc3, the positive defer message and a present zero/absent attempt value (:346-350). An AST-only evaluation of these predicates on {} and a driver-error result exited 0: `S8 predicates reject empty and driver-error results`. The nofault checks require subprocess rc0 plus an explicitly parsed False/True flag (:291-298), so missing output cannot satisfy either. Retained red/green and S8 results are provenance.jsonl:6-7,15-16. End-to-end replay was not rerun here (requires disposable clone); accepted-and-recorded, supported by those producer receipts. No fix needed.
- [Pass] Q4 — Scope is the helper's one return change plus explanation, two manual controls and S8, and regenerated receipts. No hook, routing, accounting or budget change appears in .relay-artifacts/GH-1606-delta.diff. JSON parsing and assertions over the retained provenance exited 0: `provenance 23 rows; all passed; no /Users/`. SUMMARY.md:5,27 and provenance.jsonl:19-22 agree on candidate 06671b514 and 227/8/6 suite counts. Older commit identifiers describe historical fixes; the phase-B base receipt remains explicitly historical (:23). No fix needed.
- [Pass] Q5 — Actual Python faults still print ENVIRONMENT FAULT and exit 3 (validate.sh:1042-1045), so the delta retains their early deferral. A nonzero result with no recognized diagnostic can now spend a repair slot and reach the hook: that is the intended bounded loss of foresight, not permission to publish a blocked gate. push_resolved_head still verifies wiring and performs an ordinary hooked push (merge_cleanup.py:1190-1203); tier2 invokes the real gate (githooks/pre-push:354-360), and full routing refuses a nonzero actual gate (:453-463). These paths are unchanged. No fix needed.
- [Pass] Q6 / sweep — Read the complete affected Python module, manual driver, plan, summary and provenance, including surrounding pre-existing behavior; no additional pre-existing defect established. The new PR-body/template and CodeRabbit walkthrough claims (plan:250-251) are external producer reports, not independently verified here; accepted-and-recorded as administrative claims, not runtime proof. The 23-row receipt set is internally consistent, but does not independently prove checkout identity or rerun the suites. SUMMARY.md:35-43 records conservative-route, phase-B and final-gate limitations. Qualification gate and hosted CI on the new head remain unverified by design; this approval neither supplies them nor assumes a later relay gate. No fix needed.

VERDICT: PASS
Basis: The smallest runtime correction restores the documented advisory-probe contract, preserves recognized blocking faults and the hook boundary, and has discriminating retained red/green controls. Narrow independent probes passed; disposable-clone and external results are assessed as retained producer evidence with the stated limits.

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-25T21:07:31Z
task: RELAY-gh1606-delta-qa-r1
reviewer: codex
status: Approved
reviewed-head: 5fdf53b103d7bdf23e96b7e9e12896eb66b017c5
added-range: 12100+5351
added-sha256: 9808314c65dce89738941a312656bcd59793be9ec5a2c7eac1544af989d2c877
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
