# RELAY · GH-823 final QA — promotion boundary cap
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-823-final-qa-promotion-boundary-cap): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (branch `fix/gh823-boundary-timeout`, base `origin/development` @ `9ab269c8`; commits `3f1f6d95` intake, `2b9a8425` fix):
  - `.github/workflows/ci.yml` — the `boundary-macos` job (lines ~150-165)
  - `test/ci-workflow.sh` — the GH-509 Phase 4 boundary block (lines ~236-305), new GH-823 assertion after the `timeout-minutes` presence check
  - `.github/workflows/wave-reconcile.yml` — read only; the `reconcile` job's cap (line 28) is the reference
  - `PROJECT/2-WORKING/GH-823-BOUNDARY-TIMEOUT.md` — plan, recon, rating
  - `CHANGELOG.md` — top entry
  - Review the diff with `git diff 9ab269c8..HEAD -- .github test CHANGELOG.md PROJECT/2-WORKING/GH-823-BOUNDARY-TIMEOUT.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/823 (found by #822)
- **Operational envelope:** one CI workflow value, its comment, and one assertion in the existing workflow-lock test for a
  single-maintainer, macOS-first developer toolkit. Grade against the requirements below and commensurate complexity. Do not
  ask for new frameworks, parsers, dispatch triggers, suite speed-ups (#808/#817/#819) or edits to dated historical baselines
  (`test/baselines/GH-509-*`); those are explicit non-goals.
- **Definition of Done:**
  1. `boundary-macos` `timeout-minutes` is 120, equal to `wave-reconcile.yml`'s `reconcile` job, which runs the same
     `./validate.sh --sequential` on the same `macos-latest` runner (measured 60–92 min per job over its last 28 runs).
  2. The stale "~13-15 min locally" comment is replaced by the measured figure and the reason for the value.
  3. `test/ci-workflow.sh` fails when the boundary cap is below the wave-reconcile cap, or when either cap is missing,
     and passes at 120. Red controls must be witnessed.
  4. No new subsystem, file or write path; the change extends the existing GH-509 workflow lock.
  5. The GH-823 plan doc and CHANGELOG state the change truthfully.
- **Producer's evidence (run in a disposable clone of `2b9a8425`, log committed with this thread's evidence later):**
  - `bash test/ci-workflow.sh` at 120 → 58 passed / 0 failed, including
    `PASS: the boundary cap (120m) fits the suite: >= wave-reconcile's 120m for the same sequential run`.
  - Red controls, each rc=1 with the GH-823 FAIL line: boundary 45; boundary 119; boundary `timeout-minutes` deleted
    (the GH-509 presence check also fails); `reconcile:` job renamed in `wave-reconcile.yml` (reports `'missing'`).
  - `bash test/gh460-pipe-buffer-sigpipe.sh` 12/0 (the pipe-pattern detector that scans test files).
  - `utils/pdda/pdda.sh run` 0 errors; `releases_app.py check` clean (0 failures).
- **Questions:**
  1. Is 120 justified by the cited evidence, and is tying the boundary cap to the wave-reconcile cap (`>=`) the right
     invariant? Is there a concrete case where it passes a cap that would still time out, or fails a cap that is fine?
  2. `test/ci-workflow.sh`: do the `reconcile_block` awk and the two `sed -nE` extractions select exactly the job-level
     `timeout-minutes` of each job? What happens with an indented step-level `timeout-minutes` inside either block, and
     is that failure mode acceptable (fail-closed) or a real defect?
  3. Does the assertion reject empty input (a missing file, a renamed job, a deleted line) rather than passing on it?
  4. Does anything else read or restate the boundary timeout (`ci-local.sh`, `utils/gate-status.sh`,
     `test/gh509-gate-evidence.sh`, `test/gh379-canary-uses-validate.sh`, `ROUTER.md`, `AGENTS.md`) and now disagree with it?
  5. Are the new `ci.yml` comment, the CHANGELOG entry and the plan doc accurate, with no claims beyond the evidence?
     (Note: no promotion has actually run since 2026-08-17; the timeout is predicted from wave-reconcile's runtimes.)
  6. Is anything over- or under-built for a one-value fix?
- Reply with graded findings citing `file:line`, a `swept file: yes|no` line, and a VERDICT. Set `STATUS: Approved` if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

Swept the complete CI workflow, workflow-lock test, reference reconciliation workflow and GH-823 plan; reviewed the CHANGELOG entry (not its unrelated historical archive). No additional pre-existing runtime defect identified in that sweep. No git commands or test suites were run.

- [Pass] The concrete workflow value is 120 (`.github/workflows/ci.yml:159`), matching `.github/workflows/wave-reconcile.yml:28`. The existing sequential invocation remains intact (`ci.yml:203`). The >= invariant is a reasonable conservative policy, not proof that every future run fits: both caps could drift downward together, and runtime could grow. No new mechanism is needed for this change.
- [Pass] The cited receipt durations support increasing the cap. Read-only command `python3` loaded each `TESTS-RESULTS/2026-09-25+GH-591/wave-*/validation.jsonl` and computed `(max(ts_ms)-min(ts_ms))/60000`; exit 0, output: `wave-6f956294... 84.4`, `wave-5ac6650d... 89.2`, `wave-0ae3452a... 67.7`. Each file's first row identifies sequential mode. The separate claim about all 28 hosted job runtimes was not independently queried.
- [Should] Scope both timeout extractions to the job-level key (`test/ci-workflow.sh:292-294`). Current `[[:space:]]*` matches step timeouts too. Two values fail closed, but a step timeout substitutes for a deleted job timeout and passes, violating DoD 3. Minimal fix: match exactly four leading spaces in this repository's workflow format; add disposable-clone controls with both job and step keys, and with only the step key, on both sides. The awk blocks also print the next job header before stopping, but no subsequent job fields, so this does not cause this failure.
  Observed input: current boundary block with `    timeout-minutes: 120` deleted and `        timeout-minutes: 120` inserted immediately after `      - name: Check out repo`; unchanged reconciliation block. The existing extraction/comparison returns 0 despite no job cap.
  Affected scope: job-cap extraction in the existing GH-823 lock, for either workflow when step-level timeout keys exist.
  Falsifier: unchanged 120/120 must pass; adding a valid step cap while keeping both job caps must pass; deleting either job cap while retaining a step cap must fail. No YAML parser or framework needed.
  Probe command (read-only in-memory input mutation, not suite/fixture execution):
  ```python
  # Invoked as PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY' ... PY
  from pathlib import Path
  import subprocess, shlex
  src = Path('test/ci-workflow.sh').read_text().splitlines()
  def block(path, job):
      return subprocess.run(['awk', '/^  '+job+':/{f=1} f{print} f && /^  [a-z]/ && !/^  '+job+':/{exit}'], input=Path(path).read_text(), text=True, capture_output=True, check=True).stdout
  b = block('.github/workflows/ci.yml', 'boundary-macos')
  r = block('.github/workflows/wave-reconcile.yml', 'reconcile')
  b = b.replace('    timeout-minutes: 120\n', '').replace('      - name: Check out repo\n', '      - name: Check out repo\n        timeout-minutes: 120\n')
  code = 'boundary_block='+shlex.quote(b)+'\nreconcile_block='+shlex.quote(r)+'\n'+'\n'.join(src[291:294])+' exit 0; else exit 1; fi'
  result = subprocess.run(['bash', '-c', code], capture_output=True, text=True)
  print(result.returncode, result.stderr)
  ```
  Probe driver exit 0; decisive predicate output `0` (unexpected pass). Same predicate probe also returned current=0, boundary45=1, missing-boundary=1, missing-reconcile=1, extra-step-cap=1. Thus ordinary empty inputs are rejected, but the missing-job/step-cap combination is not.
- [Nit] Correct the historical implication in `test/ci-workflow.sh:290`: “45 against a 60-92 min suite did” reads as an observed failed promotion, whereas the plan explicitly calls it latent. Use “would”. In the plan's Problem/Recon paragraphs and `CHANGELOG.md:7`, describe predicted timeout/cancellation rather than promising the final `MACOS-BOUNDARY: red` log line; no timed-out hosted boundary run is supplied as evidence that this step executes. Update the plan status table after implementation/QA so it no longer says implementation is next.
- [Pass] The named ancillary readers contain no competing boundary timeout value: the targeted `rg -n 'timeout|45|120|boundary' ci-local.sh utils/gate-status.sh test/gh509-gate-evidence.sh test/gh379-canary-uses-validate.sh` query (exit 0) locates trigger/status contracts, e.g. `utils/gate-status.sh:78` and `test/gh509-gate-evidence.sh:143`, rather than a cap dependency. ROUTER/AGENTS likewise prescribe qualification, not a numerical cap. Historical baseline values should remain unchanged.
- [Unverified — needs clone run] The producer reports 58/0 and red controls in Setup; this reviewer did not run those suites or the full gate. After the extraction fix, record the focused suite and the additional controls in a disposable full clone, then let the harness run its gate. No hosted promotion result is claimed.

VERDICT: FAIL
Basis: The 120-minute value is supported and the implementation is small, but the new lock does not enforce the stated missing-job-cap requirement when a step cap is present. Fix the two extraction patterns and witness the controls before approval.

Handing off to Producer (claude-a) — address the scoped extraction finding and documentation nits, record clone evidence, then return the relay for review.

### Producer · Round 2 · claude-a

Dispositions (fix commit `857ec01f`, evidence commit follows it on the branch):

- **[Should] job-level extraction — Implemented.** Both `sed -nE` patterns now match exactly `^    timeout-minutes:` (the four-space job key), at `test/ci-workflow.sh:294-295`, with the reason in the comment at `:288-292`. Your falsifier set was run in a disposable clone of `857ec01f` against real mutated workflow files (not an extracted predicate), see `TESTS-RESULTS/2026-09-25+GH-823/ci-workflow-controls.log`:
  - PASS expected and got: unchanged 120/120; an extra step-level `timeout-minutes: 120` inserted in both jobs with both job caps kept.
  - FAIL expected and got: boundary 45; boundary 119; boundary job cap deleted; **boundary job cap deleted with a step cap present (your observed input)**; reconcile job cap deleted with a step cap present; reconcile job renamed.
  - 9/9 matched expectation, 0 mismatches. Unmutated run: 58 passed / 0 failed.
- **[Nit] "did" → "would" — Implemented** (`test/ci-workflow.sh:290`).
- **[Nit] predicted, not observed — Implemented.** `CHANGELOG.md` now says the push "would time out before the suite finished and could never record a green boundary". The plan's Problem and Recon sections say the same, and state that whether the `if: always()` step prints `red` after a timeout has not been observed. The plan status table is updated.
- **[Pass] ancillary readers / 120 evidence** — no action.
- **[Unverified — needs clone run] — addressed.** Focused runs are committed with `provenance.jsonl` in `TESTS-RESULTS/2026-09-25+GH-823/` (the ci-workflow controls above; `test/gh460-pipe-buffer-sigpipe.sh` 12/0). The full gate runs once on the final approved commit through the push hook in a disposable clone.
- **Note (not changed):** the pre-existing GH-509 presence check at `test/ci-workflow.sh:282` still accepts any indentation. It is left alone because the GH-823 check now fails a missing job-level cap regardless, so that looseness can no longer hide one. Say if you see a case that disagrees.

Handing off to Reviewer (codex) for round 2: verify the extraction fix and the committed evidence.


### Reviewer · Round 2 · codex

swept file: yes

Swept the complete CI workflow, workflow-lock test, reference reconciliation workflow and GH-823 plan; reviewed the current CHANGELOG entry, not its unrelated historical archive. No additional pre-existing runtime defect identified. No git commands, suites or executable fixtures were run.

- [Pass] Round 1's extraction finding is resolved: both patterns now anchor the four-space job key at `test/ci-workflow.sh:294-295`; the numeric/nonempty comparison at `:296` rejects absent caps. Step keys cannot substitute for job keys, and additional step keys do not cause false failures. The older presence check is redundant but harmless for this requirement.
- [Pass] Independently probed the actual extraction/comparison statements using `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY' ... PY`: read the two workflow blocks through their awk expressions, assert both are nonempty, locate the source line beginning `boundary_cap=`, then run its two assignments and predicate via `subprocess.run(['bash', '-c', code])`, supplying only in-memory string variants and replacing the pass/fail body with exit 0/1. Driver exit 0. Decisive output:
  ```text
  current: rc=0 expected=0
  extra-step-both: rc=0 expected=0
  boundary45: rc=1 expected=1
  boundary119: rc=1 expected=1
  missing-boundary-plus-step: rc=1 expected=1
  missing-reconcile-plus-step: rc=1 expected=1
  empty-boundary: rc=1 expected=1
  empty-reconcile: rc=1 expected=1
  ```
  Source measured: `test/ci-workflow.sh:294-296`. This is a predicate probe, not a suite run.
- [Pass] Supplied clone receipts witness the requested controls: `TESTS-RESULTS/2026-09-25+GH-823/ci-workflow-controls.log:68` reports unchanged rc=0; `:135` reports extra-step-both rc=0; `:403` and `:470` report missing-job-plus-step rc=1 on the respective sides. Lower-cap, deleted-cap and renamed-job failures appear at `:202`, `:269`, `:336`, `:537`; restored rc=0 at `:604`. These are nine runs, including baseline and restored runs, rather than nine distinct mutations. `provenance.jsonl:1` binds the supplied evidence to source `857ec01f7c4e81f13c3b63d3b5b3604c02e622b6` and labels it focused-only. I inspected the receipts; I did not rerun the suites or independently establish their git provenance.
- [Pass] The cap remains 120 at `.github/workflows/ci.yml:159`, matching `.github/workflows/wave-reconcile.yml:28`. The measured-runtime rationale remains proportionate; >= is a conservative relative lock, not a guarantee against future runtime growth or both caps being lowered together. No extra subsystem is warranted.
- [Pass] Documentation nits are resolved: the test now says “would” (`test/ci-workflow.sh:290`); the plan explicitly says “Predicted from those runtimes; no boundary run has timed out yet” and leaves the post-timeout red line unobserved. `CHANGELOG.md:7` says “would time out”; the plan status table names round 2 and the pending final gate. No observed promotion success is claimed.
- [Unverified — needs clone run] Full-gate qualification on the final commit remains pending, as explicitly recorded in `TESTS-RESULTS/2026-09-25+GH-823/provenance.jsonl:1`. This approval closes artifact review only; it is not full-gate or hosted promotion evidence.

VERDICT: PASS
Basis: The scoped failure from round 1 is fixed, the independent predicate probe and supplied clone controls agree, and the documentation distinguishes predicted timeout from observed execution. No remaining blocking review finding.

Relay closed (Approved), no further turn needed. Producer (claude-a) resumes the already-planned final gate and PR workflow.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
