# RELAY · GH-1537 Final QA: pre-push own-diff routing for development merges
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1537-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation in `githooks/pre-push` (diff against base `5964566ef`:
  `relay-system/2026-11-23/gh1537-final-qa-code.diff`), the plan `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md`,
  and the evidence `TESTS-RESULTS/2026-11-23+GH-1537/` (`README.md`, `red-green-table.log`, `provenance.jsonl`, `check.sh`,
  `replay.sh`, `replay/replay.log`, `focused-suites.log`). Plan QA history: `relay-system/2026-11-23/gh1537-plan-qa.md`.
- Reviewer: codex (gpt-6-astra, reasoning effort high)   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: #1537 (a)-(d) plus KS-12 of arc #1541 are met by the smallest change that works, with no duplicate
  subsystem, no new suite, and evidence that rejects an unchanged candidate.

Issue #1537 (operator-approved policy 2026-11-19): a push whose only new integration content is `development` merged into the branch
is classified by the branch's own diff through the existing `utils/ci-route.sh`; the final landing still gets a full gate. Checks
(a) docs branch + development merge routes docs, (b) code branch + development merge routes full, (c) a merge from another branch
falls back to full, (d) a stale base falls back. Correction comment on #1537: the real mechanism is the update-range diff
`git diff --no-renames --name-only "$remote_sha" "$local_sha"`, not `:91`. KS-12 (#1541): classify the FINAL TREE against the verified
integration parent so conflict-resolution and evil-merge edits count; use it only for `route=docs`; refuse it for pushes to
`development`/`main`; keep live `ls-remote` freshness, per-ref checks, rename/deletion handling and the ambiguous-history fallback.

Operational envelope: grade against the stated requirements, commensurate complexity, and this repo's own threat model. XYZ-forge
forbids new tests (AGENTS.md, GH-831): a new `test/` suite or `validate.sh` TESTS entry in the diff is a finding; verification is the
existing suites plus the manual check with its red control. This is a gate/hook surface: do not suggest deferring a finding.

Process disclosure you must weigh: plan QA ended at its 3-round cap (r1 FAIL, r2 FAIL, r3 FAIL, STATUS: Escalated). The r3 residual
(a stale tracking ref OLDER than the merged commit let an "ours" merge slip to docs) was accepted and fixed AFTER the cap and has had no
plan-level re-review. Treat that fix as unreviewed and attack it here.

Questions (cite `file:line`; for each behaviour-change request give `Observed input:`, `Affected scope:`, `Falsifier:`):
1. **Residual F6.** In `own_diff_base`, does a tracking ref older than the merged commit (tracking B, advertised D, merge `(R,D)->M`
   keeping B's source) now return rc 2 and force full? Is any ordering of the checks still able to return rc 1 for a push that
   contains an own merge without consulting the live tip? Try: no local integration tracking ref; a merge whose `rev-list ... ^tip`
   output is empty because the merge commit is reachable from the tip; octopus merges; a first-parent-development merge.
2. **Soundness of docs acceptance.** Can any code path reach a push as `route=docs` when the branch's final tree against the verified
   integration merge-base carries code, with the new code? Check renames/deletions (`--no-renames`), several refs in one push, a
   failing second diff (classifier status now gates every route: `_cls="$(classify_push 2>/dev/null)" || _cls=""`), and the multi-ref
   `_own_pairs`/`_base_pairs` alignment.
3. **No regression of untouched paths.** Compare the diff against base for the first-push path (extracted `probe_integration_tips`,
   same notes and returns?), linear pushes (no probe, no network), pushes to `development`/`main`, tier-2 routing, receipt reuse, and
   `set -u` under bash 3.2 (macOS `/bin/bash`; the evidence ran under it): any empty-array expansion?
4. **Evidence.** Does the evidence reject an unchanged candidate (observed rejection: the 8 rows red on base), assert the gate that
   actually ran, and cover (a)-(d) and each KS-12 red control? Is the PR #1526 replay honest about what is stubbed (README "Limits")?
   Is any claim in the README unsupported by `provenance.jsonl`?
5. **Scope.** Is the change extend-not-duplicate (one hook file; no new suite, registry entry or classifier)? Anything over-built for
   the envelope, or a requirement of #1537/KS-12 missing? Note the stated consequence: a rejected candidate or non-docs own diff now
   takes the full gate even where the update range alone read docs.
6. Is the plan document consistent with what was built (item 3 order, item 4 routing, Risks)?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**Block approval:** the specific plan-r3 stale-before-merge case is fixed, but another stale-tip shortcut remains. The retained focused-suite evidence also lacks its required provenance. This is a review of the implementation and supplied receipts, not a newly executed full gate.

- **[Should] F1 — an excluded merge can bypass live freshness verification.** `githooks/pre-push:223-224` subtracts the unverified tracking tip, then returns rc 1 on an empty merge set, before `:226-228` probes the live destination. This contradicts the freshness claim at `:205` and plan item 3 (`PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md:75-77`). A backward rewrite of development can therefore erase the candidate veto. Concrete graph: B has `src/example.js=0`; R descends from B and adds README; D descends from B and changes source to 1; M has parents `(R,D)`, retains source 0 and changes README. Development temporarily contains M, the tracking ref is M, then the destination rewinds development to D without a fetch. Push feature R→M. `R..M ^M` has no commits, so the helper returns 1 without checking that advertised D differs from tracking M. The caller uses R→M (README only); against verified D the final tree also changes source. This is the empty-exclusion variant explicitly requested in Setup question 1, not the ordinary merge-free follow-up.
  Observed input: `githooks/pre-push:223-224`, with `local_sha=M`, `remote_sha=R`, `dest=refs/heads/docs-pr`, `refs/remotes/origin/development=M`, advertised development D, and the concrete parents/tree values above. The existing classifier returns docs for README alone and full when `src/example.js` is included (probe below). The Git DAG/hook outcome is source-reasoned, **[Unverified — needs clone run]**, not an asserted executed push failure.
  Affected scope: a newly pushed merge reachable from an unverified local integration tip, when that tracking tip no longer represents the push destination. Genuinely merge-free update ranges need no additional network request.
  Falsifier: add this exact tracking-M/advertised-D shape to the existing disposable-clone manual check; with no reusable receipt it must select/invoke full, while the fresh normal docs merge still invokes docs and the demonstrated linear/docs follow-up cases keep their routes. If the current hook already does that, retain its nonempty push output and explain which condition prevents `:224` returning 1.
  Fix: do not treat exclusion by an unverified tip as proof that a newly pushed merge needs no freshness check. Preserve the no-new-merge fast path; validate the hint or retain the existing rc-2 veto for the concrete excluded-merge case. Reuse the helper/cache, revise the matching plan instruction at `:78-81`, and record the red/green control in the existing evidence procedure; no new suite or provenance subsystem is needed.

- **[Should] F2 — the evidence ledger does not support all claimed runs.** `TESTS-RESULTS/2026-11-23+GH-1537/provenance.jsonl:1-40` contains only 38 scenario rows and two replay rows: zero focused-suite records, and no scenario push exit statuses. `check.sh:173-174` never records those statuses, contrary to plan `:121-122`. `focused-suites.log:125`, `:128`, `:203`, `:213`, `:300`, and `:366` do record six successful suite exits, but do not identify the tested commit/hook or environment; consequently README `:19-21`'s candidate-commit, pinned-venv and identical-base-failure claims cannot be established from that log plus provenance. The 38 hook hashes do match the seeded candidate, so this is a specific attribution gap, not rejection of the routing table.
  Fix: retain provenance for the cited focused runs (actual command, tested SHA/hook identity, exit status, environment and log pointer), plus the required pre/post clone-identity evidence; recover the original records if available, otherwise rerun in a disposable full clone. Capture each manual push's status alongside route and gate invocation, without confusing the intentionally broken-object control's push failure with routing failure. Retain evidence for the earlier base/candidate environment-fault assertion or remove that unsupported assertion. Do not invent missing run metadata. These are evidence changes, not a requested runtime behavior change.

- **[Nit] F3 — align the explanatory contract.** `githooks/pre-push:121` still says “Every doubt keeps today's update range,” although `:301` and `:362-364` implement the deliberate full veto. Replace that sentence with the three-outcome distinction already documented at `:196-204`. Plan item 4 and its verification at `:96`/`:124` promise a line naming the merge-base; the actual message at hook `:367` names the concept but prints no base identifier. Either include the base information or narrow that prose promise. The substantive plan order/routing/Risks otherwise match `:214-243`, `:348-372` and the deliberate non-doc/stale full veto; F1 is a flaw shared by plan and implementation.

- **[Pass] The particular plan-r3 residual is addressed.** For tracking B / advertised D / merge `(R,D)->M`, M survives `^B`, so hook `:226-228` rejects before the ancestral-base shortcut at `:232`; `:301` and `:362-364` preserve the full veto. The executed producer control is defined at `check.sh:134-139` and retained at `provenance.jsonl:23-24` (base docs, candidate full, both gate invocations recorded). A missing local tracking ref with a successfully enumerated merge returns 2 at hook `:218-221`. Octopus non-first parents are each checked at `:236-240`; a development-first merge with an unintegrated feature second parent is conservatively rejected there. These last edge cases are source checks, not newly executed fixtures.

- **[Pass] Accepted own-diff classification retains the required boundaries.** Hook `:229-243` supplies the unique integration merge-base; `:305-306` appends one aligned pair to both arrays; `:355-357` classifies the chosen union and discards stdout on any failed diff. `:319` retains `--no-renames`, so deleted/renamed source paths remain visible; `:365-370` accepts only docs and overrides tier 2 otherwise. The partial-second-diff red control is at `check.sh:151-155` and `provenance.jsonl:31-32`. This closes the pre-existing status-masking defect identified in plan QA. This claim is about admitted candidates; F1 prevents claiming global soundness.

- **[Pass] Untouched behavior and scope remain bounded in the supplied diff.** `gh1537-final-qa-code.diff` changes one hook, extracts the existing push-URL/nonzero-status/absent-tip checks into `githooks/pre-push:146-194`, and preserves first-push base selection at `:269-292`. Ordinary merge-free pushes exit the helper before the probe; development/main destinations exit at `:210`. That destination exclusion preserves existing update-range policy; it does not newly force every docs-only integration push full. Tier-2 execution and exact-commit receipt reuse remain at `:337-345` and `:407-426`; the extra destination field leaves the receipt's `${_pair%%|*}` reader intact. The new whole-array expansions at `:355` require `_own_n>0`, which follows an appended pair, so no new empty-array expansion under `set -u` was found. No new classifier, registry entry or test suite appears in the supplied implementation diff. No additional substantiated pre-existing hook defect was found in the whole-file sweep.

- **[Pass] The retained routing comparison rejects the unchanged candidate, and the replay is qualified evidence.** `check.sh:177-183` requires candidate routes and actual gate markers to agree; eight base rows disagree with the same expected routes (`red-green-table.log`, final line). Probe below finds eight base mismatches, zero candidate mismatches, and candidate hook hash `9c5a332d52c0acda` matching every candidate receipt. The replay log `replay/replay.log:1-12` records the two own-diff paths, 33 update paths, and actual full/docs stub markers. `replay.sh:14-44` pins a local mirror, overlays current support files, stubs admission/gates and directly invokes the hook with historical ref input; it is not a live production push or proof of gate-body correctness. README `:10-12` and `:46-50` disclose the isolation/stubs; F2 covers its unsupported run-attribution claims. The ordinary controls (a)-(d) and the named evil-merge/partial-diff controls have rows; the F1 rewritten-tip variant is absent.

Read-only probe command (after `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"`), exit **0**:

```bash
python3 - <<'PYPROBE'
from pathlib import Path
import hashlib,json,subprocess
rows=[json.loads(x) for x in Path('TESTS-RESULTS/2026-11-23+GH-1537/provenance.jsonl').read_text().splitlines()]
assert len(rows)==40
print('hook',hashlib.sha256(Path('githooks/pre-push').read_bytes()).hexdigest()[:16])
print('candidate_hashes',sorted({r['hook_sha256'] for r in rows if r['variant']=='cand'}))
print('scenario_exits',sum('exit' in r for r in rows if 'scenario' in r))
print('suite_records',sum('scenario' not in r and 'replay' not in r for r in rows))
for v in ['base','cand']:
 print(v,'mismatches',sum(r['route']!=r['want'] for r in rows if 'scenario' in r and r['variant']==v))
for paths in ['README.md\n','README.md\nsrc/example.js\n']:
 p=subprocess.run(['/bin/bash','utils/ci-route.sh','push'],input=paths,text=True,capture_output=True)
 assert p.returncode==0 and p.stdout,(p.returncode,p.stderr)
 print(repr(paths),'exit',p.returncode,'/'.join(s for s in p.stdout.splitlines() if s.startswith(('route=','tier='))))
PYPROBE
```

Decisive output:

```text
hook 9c5a332d52c0acda
candidate_hashes ['9c5a332d52c0acda']
scenario_exits 0
suite_records 0
base mismatches 8
cand mismatches 0
'README.md\n' exit 0 route=docs/tier=1
'README.md\nsrc/example.js\n' exit 0 route=full/tier=3
```

Also ran `/bin/bash -n githooks/pre-push`: exit **0**, no diagnostics. Inspected the complete hook, plan, implementation diff and manual evidence scripts, plus the retained logs and relevant classifier paths. Graph tools were unavailable; no graph generation or coverage claim is made. No git command, executable fixture, test suite or full gate was run in this reviewer worktree. No later gate is assumed to run or pass. The only tracked edit is this relay file.

Handing off to Producer (claude-a): address F1-F3 and return the revised implementation and evidence for Round 2.

swept file: yes
VERDICT: FAIL
Basis: the exact prior F6 input is closed, but a stale tracking tip that contains the new merge still bypasses the live check and can select docs for the old-source resolution. Focused-run attribution and promised push statuses are also missing from provenance. Approval remains withheld pending the concrete correction and retained evidence.

### Producer · Round 1 · claude-a

Dispositions (hook `githooks/pre-push` `own_diff_base`; plan item 3; evidence dir `TESTS-RESULTS/2026-11-23+GH-1537/`; refreshed diff
`relay-system/2026-11-23/gh1537-final-qa-code.diff`; repair commit `477af7c68`, evidence `1d066fad8`):

- **F1 — Implemented.** `own_diff_base` now uses the plain `git rev-list --merges -n 1 remote..local` (no `^tip` exclusion) as the
  trigger, so a merge that the stale or rewound tracking tip already contains still reaches the live probe; stale or unverifiable
  returns rc 2 (whole-push full). Only after the tip is proven fresh is the `^tip` exclusion applied (empty => rc 1, all merges are
  integration history the verified tip holds). Linear and merge-free pushes still return rc 1 before any probe. Your exact
  tracking-M / advertised-D shape is the new control `rewound_tip_ours`: base docs, previous candidate (e46bb95ae) docs, repaired
  candidate full (`previous-candidate-vs-repaired.log` shows it is the only scenario that changed). The plan's item 3 bullets are reordered.
- **F2 — Implemented.** `check.sh` rows now carry `push_exit` (the `two_refs_partial_failure` push fails by construction, a deleted tree
  object cannot be packed, so only route and gate marker are judged; README says so). New `run-focused.sh` records one
  `suites-provenance.jsonl` row per existing suite (command, tested commit `477af7c68`, hook sha256, exit, python, mypy 1.14.1, bash,
  log pointer) plus clone identity (HEAD, origin URL, bare flag) before and after (`unchanged: yes`), run in a disposable full clone.
  The unsupported "identical base failure without the venv" sentence is removed from the README rather than back-filled. The PR #1526
  replay is rerun on the repaired hook (base full, candidate docs) and its two rows are back in `provenance.jsonl` (42 rows).
- **F3 — Implemented.** The header comment now states the three outcomes instead of "every doubt keeps today's update range", and the
  narrowing message prints the merge-base (`... merge-base (6c90ed1e2) ...` in the replay log).

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2 · codex

**Block approval on the remaining F2 evidence gap only.** F1's routing defect and F3's explanatory contract are closed. The repaired hook matches the retained candidate hash, with zero candidate routing mismatches and nine base red controls. No further substantiated runtime defect was found in the whole-hook sweep. This is source and retained-evidence review, not a newly executed gate.

- **[Should] F2 — attribution repaired; required clone-identity bracket still incomplete.** `TESTS-RESULTS/2026-11-23+GH-1537/suites-provenance.jsonl:1` through `:6` now attribute six successful suites to commit `477af7c6847c630fd45dc18cf1be4eb46dcec14a`, hook `4a14c3c2bd3acaf5`, and the reported Python/mypy/bash versions. All 40 scenario rows now include push status; the unsupported earlier environment-fault assertion is removed. However, `run-focused.sh:8-10` captures only HEAD, one origin fetch URL and the bare flag; `suites-provenance.jsonl:7` therefore cannot establish the pre/post local user identity or full remote mapping required by `AGENTS.md:297-298`. `WORKTREE-SAFETY.md:504-506` explicitly includes local user identity in the corruption check. The probe below confirms both records contain only `head`, `origin`, `bare`. This is missing evidence, **not an allegation that this clone actually drifted**. The purpose of the existing bracket is to distinguish a valid suite result from a fixture escaping into its host clone; matching HEAD alone cannot do that.
  Observed input: the exact before/after JSON objects quoted below, produced by `run-focused.sh:8-10` and retained at `suites-provenance.jsonl:7`.
  Affected scope: acceptance of these mutation-heavy focused-suite results under the repository's existing clone-identity rule; no hook behavior change is requested.
  Falsifier: contemporaneous pre/post records from this run showing unchanged local `user.email` (including an explicit unset result if applicable) and fetch/push remote mappings would close the gap without another run.
  Fix: recover those actual records if available. Otherwise retain a complete bracket with a disposable-clone run covering these suites; this can be folded into the already-planned full gate rather than duplicating unrelated work. Use the existing identity mechanism or complete this manual evidence script, not a new guard/runner subsystem. Do not back-fill historical values from the clone's current config. F2 remains open only for this residual; the hashes, commands, suite exits and manual-push status attribution are now supported.

- **[Pass] F1 closed by source and the retained discriminating control.** `githooks/pre-push:229-233` checks for any merge before the live probe and rejects a tracking/live mismatch before `:235` applies `^tip`. Thus tracking M / advertised D reaches rc 2 even though the tracking tip contains M. `check.sh:140-145` constructs precisely that local graph state; `provenance.jsonl:25-26` records base docs/docs-gate/exit 0 versus repaired full/full-gate/exit 0. `previous-candidate-vs-repaired.log:14` records the previous candidate's docs result for this same scenario. The older-tracking-B case remains covered at `provenance.jsonl:23-24`. With no local tip, a successfully enumerated merge is rejected at hook `:222-225`; after a verified fresh tip, an empty excluded set legitimately returns rc 1 at `:235-236`. Every octopus non-first parent is checked at `:244-248`, and a development-first merge whose feature second parent is not on the tip is rejected there. These last edge checks are source reasoning, not newly executed fixtures.

- **[Pass] F3 closed; the admitted route remains bounded.** The header at `githooks/pre-push:113-124` now distinguishes narrowing, non-applicability and rejection. Hook `:309` accumulates the base identifiers and `:376` prints them; `replay/replay.log:10` records `(6c90ed1e2)`. Plan item 3 at `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md:78-92` now places freshness before exclusion. Hook `:314-315` keeps one aligned pair per ref, `:328` preserves `--no-renames`, and `:366` discards partial classifier stdout on failure. The whole-push veto and docs-only acceptance remain at `:371-379`; the partial-diff evidence at `provenance.jsonl:33-34` correctly records nonzero push exits while demonstrating full-gate selection in the repaired candidate. An accepted own-diff candidate is classified against its final tree, so resolution edits, code removals and renamed source paths remain visible.

- **[Pass] Whole-hook sweep and scope.** Reviewed `githooks/pre-push:1-467`, the complete supplied diff, plan, manual evidence scripts and retained logs. The five new-side diff hunks match the seeded hook exactly (read-only Python comparison, exit 0). First-push base selection at `:270-301` retains the extracted probe's push-destination and status checks; ordinary merge-free pushes return before the network call at `:229-231`; development/main destinations are excluded at `:214`. Tier-2 execution at `:394-413` and exact-commit receipt reuse at `:416-436` remain unchanged. New whole-array expansion at `:364` requires a successfully appended own pair, so no new empty-array expansion under bash 3.2 `set -u` was found. No new classifier, suite registration or production subsystem appears in the supplied one-hook diff. No additional substantiated pre-existing defect was found. This does not certify the pending full gate.

- **[Pass] Routing and replay evidence are discriminating and appropriately qualified.** `check.sh:175-184` captures nonempty push output, the invoked stub gate and push status. The probe below confirms 20 scenarios per variant, nine base mismatches, zero candidate mismatches, and candidate receipts matching the seeded hook. Only `two_refs_partial_failure` has a nonzero push status (1 for both variants), consistent with README `:44`. The six log markers at `focused-suites.log:125`, `:128`, `:204`, `:214`, `:300`, `:366` agree with the suite receipts; F2 limits their clone-integrity attestation. Replay isolation remains explicit at `replay.sh:14-36` and README `:48-56`: historical commits, pinned local mirror, overlaid support files, stubbed admission/gates. The full/docs markers at `replay/replay.log:8` and `:12` demonstrate routing, not gate-body correctness or a new production push.

- **[Nit] F4 — refresh the plan's status count.** `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md:28` still reports 19 scenarios and eight red rows; the retained revised evidence and README now report 20 and nine. Update that status cell when recording the evidence repair. The substantive routing order, docs-only policy and full-veto tradeoff match the implementation.

Read-only evidence probe, exit **0** (no git, test suite or fixture executed):

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
from pathlib import Path
import hashlib,json
p=Path('TESTS-RESULTS/2026-11-23+GH-1537')
r=[json.loads(s) for s in (p/'provenance.jsonl').read_text().splitlines()]
s=[json.loads(x) for x in (p/'suites-provenance.jsonl').read_text().splitlines()]
h=hashlib.sha256(Path('githooks/pre-push').read_bytes()).hexdigest()[:16]
assert len(r)==42 and all(x['hook_sha256']==h for x in r if x['variant']=='cand')
print('hook',h,'rows',len(r))
for v in ('base','cand'):
 a=[x for x in r if 'scenario' in x and x['variant']==v]
 print(v,'scenarios',len(a),'mismatches',sum(x['want']!=x['route'] for x in a),'missing_push_exit',sum('push_exit' not in x for x in a))
assert len(s)==7 and all(x['exit']==0 and x['hook_sha256']==h for x in s[:-1])
print('focused_suite_exits',[x['exit'] for x in s[:-1]])
print('identity_before',s[-1]['clone_identity_before'])
print('identity_after',s[-1]['clone_identity_after'])
PYPROBE
/bin/bash -n githooks/pre-push
```

Decisive output (the bash syntax check also exits **0**, with no diagnostics):

```text
hook 4a14c3c2bd3acaf5 rows 42
base scenarios 20 mismatches 9 missing_push_exit 0
cand scenarios 20 mismatches 0 missing_push_exit 0
focused_suite_exits [0, 0, 0, 0, 0, 0]
identity_before {'head': '477af7c6847c630fd45dc18cf1be4eb46dcec14a', 'origin': 'https://github.com/HiQS-Labs/XYZ-forge.git', 'bare': 'false'}
identity_after {'head': '477af7c6847c630fd45dc18cf1be4eb46dcec14a', 'origin': 'https://github.com/HiQS-Labs/XYZ-forge.git', 'bare': 'false'}
```

Graph tools were unavailable; source fallback was used and no graph generation/coverage claim is made. No git command, executable fixture, test suite or full gate was run in this reviewer worktree, and no later gate is assumed to pass. Only this relay file was edited.

Handing off to Producer (claude-a): close the remaining F2 identity-evidence gap and refresh F4's status count; no further hook change is requested.

swept file: yes
VERDICT: FAIL
Basis: the runtime repair and its red control close F1, and the explanation closes F3. F2's required clone-identity evidence is still incomplete, so the earlier finding cannot yet be closed under the relay contract.

### Producer · Round 2 · claude-a

Dispositions (no hook change; evidence commit `5da8c1608`, suite rerun recorded in `suites-provenance.jsonl`):

- **F2 residual — Implemented by rerun, not back-fill.** `run-focused.sh` now brackets `HEAD`, `git config --get core.bare`, `git remote -v`
  (fetch and push mappings) and `git config --local --get user.email` (unset recorded as `<unset>`), before and after, in a disposable full
  clone of the task clone at `5da8c1608`. All six existing suites exit 0 (hook sha256 `4a14c3c2bd3acaf5`, python 3.12.13, mypy 1.14.1) and the
  bracket reports `unchanged: yes`. The earlier six rows (tested commit `477af7c68`) are replaced, not kept, so no row claims a bracket it lacks.
- **F4 — Implemented.** The plan's status cell now says 20 scenarios and 9 red rows.
- **Passes kept.** F1 and F3 closed in your Round 2; the hook is unchanged since `477af7c68`.

Handing off to Reviewer (codex) for Round 3 (the cap).

### Reviewer · Round 3 · codex

**Approve the implementation and retained focused evidence.** F2's remaining identity gap and F4's stale count are closed. F1 and F3 remain closed. This approval is final code QA, not a claim that the pending full gate on the final commit has run.

- **[Pass] F2 closed by the new, complete bracket.** `TESTS-RESULTS/2026-11-23+GH-1537/run-focused.sh:8-17` captures HEAD, configured bare state, effective bare state, full fetch/push remote mappings and local email before the suites; `:28-29` captures and compares them afterwards. `suites-provenance.jsonl:1-6` attributes all six successful runs to `5da8c1608c524c3897d480f549ea5f5a5ecd7ea5` and hook `4a14c3c2bd3acaf5`; `:7` contains equal before/after objects, including explicit `local_user_email: "<unset>"` and both origin mappings. The probe below checks equality, required fields, commit/hash attribution and agreement with the six exit markers in `focused-suites.log:125`, `:128`, `:204`, `:214`, `:300`, `:366`. This closes the specific missing-evidence finding; it does not imply a newly executed reviewer gate.

- **[Pass] F4 closed; F3 remains closed.** `PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md:28` now says “20 scenarios x base/candidate, 9 red rows on base”, matching the receipts. The three-outcome explanation at `githooks/pre-push:121-124`, printed base identifier at `:376`, and plan items 3–4 at `:73-104` remain consistent with the built routing. The plan explicitly leaves the full gate on the final commit outstanding.

- **[Pass] F1 remains closed and the runtime boundary is preserved.** `githooks/pre-push:229-236` discovers merges before consulting the live tip and only excludes verified integration history afterwards; the tracking-M/advertised-D control remains base docs versus candidate full at `provenance.jsonl:25-26`. The older-tracking-B control at `:23-24` remains full on the candidate. For a successfully enumerated merge with no local tracking tip, hook `:222-225` rejects; octopus non-first parents are each checked at `:244-248`. A development-first merge with a feature second parent not on the tip is rejected by that same check. These latter edges are source reasoning, not newly executed fixtures. Aligned per-ref pairs at `:314-315`, final-tree diff with `--no-renames` at `:328`, classifier-status handling at `:366`, and whole-push veto/docs-only acceptance at `:371-379` retain the required resolution-edit, rename/deletion and multi-ref boundaries.

- **[Pass] Whole-file sweep found no additional substantiated pre-existing defect.** Read all of `githooks/pre-push:1-467`, the complete supplied implementation diff, plan and manual evidence scripts. The five new-side diff hunks match the seeded hook exactly. First-push selection at `:270-301`, destination exclusion at `:214`, merge-free return before network at `:229-231`, tier-2 handling at `:394-413` and exact-commit full-receipt reuse at `:416-436` retain their previous scope. The new array expansion at `:364` requires an appended own pair; no new empty-array expansion under bash 3.2 `set -u` was found. The supplied diff extends one hook and reuses the classifier/live probe; it adds no production classifier, suite or registry entry.

- **[Pass] The retained evidence rejects the unchanged hook.** `provenance.jsonl:1-40` has 20 scenarios per variant, nine base route mismatches, zero candidate mismatches, matching actual stub-gate markers and recorded push exits. Candidate hashes match the seeded hook. The two replay records at `:41-42` and `replay/replay.log:1-12` retain base full versus candidate docs for PR #1526, with two own-diff paths versus 33 update paths. `README.md:8-22` and `:48-56`, together with `replay.sh:14-44`, disclose the fixture gates, isolated admission and historical/local-mirror replay. These establish routing behavior, not live production gate-body correctness. The intentionally broken-object push remains qualified at README `:44`.

Read-only probe command, exit **0** (the following syntax check also exits **0**, no diagnostics):

```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
from pathlib import Path
import hashlib,json,re
p=Path('TESTS-RESULTS/2026-11-23+GH-1537')
r=[json.loads(x) for x in (p/'provenance.jsonl').read_text().splitlines()]
s=[json.loads(x) for x in (p/'suites-provenance.jsonl').read_text().splitlines()]
h=hashlib.sha256(Path('githooks/pre-push').read_bytes()).hexdigest()[:16]
assert len(r)==42 and all(x['hook_sha256']==h for x in r if x['variant']=='cand')
print('hook',h,'rows',len(r))
for v in ('base','cand'):
 a=[x for x in r if 'scenario' in x and x['variant']==v]
 assert len(a)==20 and all('push_exit' in x for x in a)
 assert all(x['gate_ran']=={'docs':'docs-gate','full':'full-gate'}[x['route']] for x in a)
 print(v,'scenarios',len(a),'mismatches',sum(x['want']!=x['route'] for x in a))
assert len(s)==7 and all(x['exit']==0 and x['hook_sha256']==h for x in s[:-1])
b=s[-1]['clone_identity_before']; a=s[-1]['clone_identity_after']
assert b==a and s[-1]['unchanged']=='yes'
assert set(b)=={'head','core.bare','is_bare','remote_v','local_user_email'}
assert b['core.bare']==b['is_bare']=='false'
assert len(b['remote_v'])==2 and all(any(z.endswith('('+k+')') for z in b['remote_v']) for k in ('fetch','push'))
assert all(x['tested_commit']==b['head'] for x in s[:-1])
log=(p/'focused-suites.log').read_text()
assert re.findall(r'^rc=(\d+) (.+)$',log,re.M)==[('0',x['suite']) for x in s[:-1]]
print('suite_exits',[x['exit'] for x in s[:-1]],'log_matches',True)
print('identity',json.dumps(b,sort_keys=True))
print('identity_unchanged',b==a)
assert '20 scenarios x base/candidate, 9 red rows on base' in Path('PROJECT/2-WORKING/GH-1537-PREPUSH-OWN-DIFF-ROUTING.md').read_text()
print('plan_counts_match',True)
lines=Path('relay-system/2026-11-23/gh1537-final-qa-code.diff').read_text().splitlines()
hook=Path('githooks/pre-push').read_text().splitlines()
n=0;i=0
while i<len(lines):
 m=re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@',lines[i])
 if not m: i+=1;continue
 start=int(m[1])-1; count=int(m[2] or 1); i+=1; new=[]
 while i<len(lines) and not lines[i].startswith(('@@ ','diff --git ')):
  if lines[i].startswith((' ','+')):new.append(lines[i][1:])
  i+=1
 assert len(new)==count and hook[start:start+count]==new
 n+=1
print('diff_hunks_match',n)
PYPROBE
/bin/bash -n githooks/pre-push
```

Decisive output:

```text
hook 4a14c3c2bd3acaf5 rows 42
base scenarios 20 mismatches 9
cand scenarios 20 mismatches 0
suite_exits [0, 0, 0, 0, 0, 0] log_matches True
identity {"core.bare": "false", "head": "5da8c1608c524c3897d480f549ea5f5a5ecd7ea5", "is_bare": "false", "local_user_email": "<unset>", "remote_v": ["origin\thttps://github.com/HiQS-Labs/XYZ-forge.git (fetch)", "origin\thttps://github.com/HiQS-Labs/XYZ-forge.git (push)"]}
identity_unchanged True
plan_counts_match True
diff_hunks_match 5
```

Graph tools were unavailable; direct source fallback was used, with no graph generation or coverage claim. No git command, executable fixture, test suite or full gate was run in this reviewer worktree. No later gate is assumed to run or pass. Only this relay file was edited.

swept file: yes
VERDICT: PASS
Basis: all earlier findings are closed by the revised source and retained evidence, including the complete clone-identity bracket. The whole-hook sweep found no additional substantiated defect. Final-commit full-gate execution and delivery remain separate obligations; this verdict does not certify them.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-23T18:50:12Z
task: RELAY-gh1537-final-qa
reviewer: codex
status: Approved
reviewed-head: bd6b63a1ec9abb94b64dd9363a6c79b30dd5866d
added-range: 33647+7631
added-sha256: 3b7a6b7560e2aff24d5cdaa52a36784284f9bde328c3bb3fdb2f85d0a52e1274
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
