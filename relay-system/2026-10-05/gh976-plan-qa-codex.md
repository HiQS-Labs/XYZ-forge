# QA relay — the GH-976 plan doc
STATUS: Approved
NEXT: claude-a (Author)

## Your role

You are the **reviewer**. This is a **review-only** turn: `ALLOW_PATHS` is empty, so the only file
you may write is this relay file. Do not edit the plan or any source. Report findings here.

## What to review

`PROJECT/2-WORKING/GH-976-RELAY-RECEIPT-ONLY-PROGRESS.md` — a one-step bugfix plan, not yet built.

Operational envelope: a local CLI relay supervisor used by one developer's headless agent loops.
Tests and machinery must be commensurate; this repo forbids new test suites and new `validate.sh`
registry entries (AGENTS.md "No new tests", GH-831), so do not ask for one.

Read rather than take on trust:

- `utils/py/relay_drive.py:579-590` (`get_head_commit`), `:790-796` (before-turn snapshot),
  `:1094-1108` (the progress oracle and extension), `:737-738` (hard cap), `:399` + `:756` + `:1044`
  (`STATUS: Escalated` handling).
- `relay-automation/relay-turn-lib.sh:1498` and `utils/py/relay_drive.py:643` — the two commits a
  turn produces even when no artifact changed.
- `test/gh115-round-cap.sh` — the existing suite and how its stub simulates "progress".
- GitHub issue #976 and the consumer incident it cites (david-nguyen-chaoticdomain/user-sage-backend#75).

## Definition of Done

This is a plan review: will building this plan fix the defect, and can a cold agent build it from the
doc alone? Answer each with evidence from the repo.

1. **Are the factual claims true?** The plan says HEAD always moves on a relay turn because of the
   two commit sites above, so the `head_after != head_before` arm is always satisfied. Confirm or
   refute with file:line.
2. **Is the receipt-path list right and complete?** `relay-system/`, `marathon-system/`, `.tick/`,
   `.relay-scratch/`, `TESTS-RESULTS/`, plus the relay file's own path. Name any path a receipt
   commit touches that is missing, or any listed path that a real repair legitimately touches.
3. **Does the fix preserve GH-115?** A builder commit of real files at the cap must still extend.
   Would the existing suite's Test 2/3 (which signal progress through `[x]` lines, not commits)
   still pass, and does the suite still pin anything meaningful about the HEAD arm?
4. **Is the red control credible?** The plan records a manual check under `TESTS-RESULTS/` rather
   than adding a suite. Say whether that check, as described, would actually go red on the pre-fix
   code and green after, or whether it is unfalsifiable as written.
5. **Is the non-goal on adjudication right?** The plan declines to parse prose like "adjudication
   requested" because `STATUS: Escalated` already exists as the terminal handoff. Argue against that
   if the harness gives agents no way to set it.
6. **Is it the right size?** One helper, one call-site change, failing closed to "no extension" on
   git error. Flag anything over- or under-built.

Rate each finding `[Blocker]`, `[Must]`, `[Should]`, or `[Note]`. A `[Blocker]` or `[Should]` that
asks for a behaviour change must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines.

Set `STATUS: Approved` only if the plan is buildable as written. Otherwise `STATUS: Changes requested`.

## Round log

### Round 1 · codex · plan QA · 2026-10-05

**Verdict: Changes requested — two Must findings.** The path-based oracle is the right-sized fix for receipt-only extension. The verification recipe needs revision before the plan is buildable as written. Review-only: no source or plan edits, git commands, suites, or executable fixtures were run. Review edits are Easy to reverse.

1. **[Must] Make the red control executable and correct its explanation (DoD 1/4).** Plan lines 71–77 switch between a `relay.md` variant and `relay-system/x.md` committed “between turns,” and incorrectly say the suite's attestation already moves HEAD without extending. The stub at `test/gh115-round-cap.sh:17–34` never commits. `judge_terminal` returns immediately for an open status (`relay_drive.py:671–672`); the attestation commit at :721 follows approval checks. Test 1 never approves, so attestation cannot explain its no-extension result. A commit outside the :794 / :1093 before/after window cannot exercise the HEAD arm.

   Required revision: specify one disposable-full-clone manual check with `STUB_PROGRESS=no`, a changed tracked receipt committed **inside the dispatched cap-reaching turn**, continuing token handoff, and no approval. Pin the initial cap; assert non-empty captured output, exit 4, `cap-stalled`, original turn count, and absence of extension output and `Extension · System`. Run that same assertion on base (must fail because it extends) and candidate (must pass), recording commands, revisions, output and committed `provenance.jsonl` under the named TESTS-RESULTS directory. Include arbitrary-location `relay.md` to verify the exact-file exclusion as well as a directory case. No new suite or gate. **[Unverified — needs clone run]**: the intended control is falsifiable, but its current timing description is not a dependable recipe.

2. **[Must] Add a positive manual control for the changed HEAD arm (DoD 3/4).** Test 2/3 append `[x]` at `test/gh115-round-cap.sh:23–24` and enable it at :68/:89. They should still pass because `relay_drive.py:1099–1100` remains intact, but do not pin committed-file progress. A helper that always returns False could pass those tests and the proposed receipt-only negative check. Required revision: in the same disposable-clone manual evidence, hold the resolved count fixed and commit a real file such as `src/repair.py` inside the cap-reaching turn; assert a bounded extension after the fix. Include mixed receipt/real-file changes and the specified no-SHA/git-error False result, preserving the independent resolved-items arm. Leave the registered suite unchanged. **[Unverified — needs clone run]** for extension integration; do not claim GH-115's HEAD arm is preserved from this suite alone.

3. **[Note] The defect is confirmed; “every turn / HEAD always moves” is too broad (DoD 1).** `relay-turn-lib.sh:1498` commits changed staged allowlisted files; :1480–1495 explicitly handle no commit. Its archive branch (:1502–1523) can commit the transcript in a different repository, leaving target HEAD unchanged. Driver :638–641 skips untracked/ignored transcripts. Nevertheless, a tracked changed transcript committed in the sampled repository satisfies :1097 without an artifact repair, and :1102 extends up to `2 * cap` (:737–738). Qualify the factual claim to those same-repo tracked receipt turns. Attestation is approval publication, not a second commit on every open handoff.

4. **[Note] Receipt paths cover the inspected commit sites; clarify coordinates (DoD 2/6).** The turn commit uses its allowlist (:1474–1498), the archive commit its relay path (:1516–1518), and driver attestation only the relay file (`relay_drive.py:642–643`). No additional fixed receipt path is demonstrated by these sites. Compare the exact relay file relative to the **same repository** as the diff; omit that exact-file exclusion when the transcript is outside that repo. An archive basename must not exclude an unrelated target file. Existing `target_repo()` (:616–623) already resolves the same repo as `get_head_commit()` (:579–590), so reuse it. The broad exclusions intentionally also ignore evidence-only repairs under TESTS-RESULTS and phase-brief-only edits under marathon-system; those can be useful work but are excluded by this plan's progress policy. Keep slashes on directory prefixes. This bounded read is not an exhaustive receipt inventory.

5. **[Note] Existing escalation supports the adjudication non-goal (DoD 5).** `escalated_status` (:399–400) recognizes `STATUS: Escalated`; :756–759 and :1044–1047 stop with exit 4 / `human-escalation` before the extension oracle. Both roles can edit the relay file, and approval restrictions apply only to Approved/Closed (:396–397, :671–672); the inspected harness does not prevent setting Escalated. Free-prose parsing is unnecessary for this narrower plan. However, [issue #976](https://github.com/HiQS-Labs/XYZ-forge/issues/976) currently explicitly accepts `adjudication-requested` for a prose/NEXT handoff. Reconcile its acceptance with the plan's deliberate scope before claiming to close all of it. Consumer [issue #75](https://github.com/david-nguyen-chaoticdomain/user-sage-backend/issues/75) could not be independently read: connector 404, web cache miss. Command `gh api repos/david-nguyen-chaoticdomain/user-sage-backend/issues/75 --jq '{title: .title, body: .body}'` exited 1 with `error connecting to api.github.com`. Its cap-10 incident remains unverified here.

6. **[Note] One helper / one oracle replacement is sufficient (DoD 6).** Preserve the resolved-items arm and hard ceiling. False on unverifiable git evidence is appropriate and must leave the independent resolved-items signal available. No new runner, suite, gate, or frozen-twin edit is needed. Findings 1/2 address under-verification without expanding production scope.

**Probe evidence (exit 0).** The following non-mutating AST probe executed only the existing oracle statements with synthetic values; it neither dispatched turns nor invoked git:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast
from pathlib import Path
p=Path("utils/py/relay_drive.py")
tree=ast.parse(p.read_text())
main=next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name=="main")
loop=next(n for n in main.body if isinstance(n, ast.While) and n.lineno==740)
start=next(i for i,n in enumerate(loop.body) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="made_progress" for t in n.targets))
fragment=ast.Module(body=loop.body[start:start+2],type_ignores=[])
for label,before,after,rb,ra in [("receipt-only","a","b",0,0),("real-file","a","b",0,0),("resolved-only","a","a",0,1),("no-change","a","a",0,0)]:
    env=dict(head_before=before,head_after=after,resolved_before=rb,resolved_after=ra)
    exec(compile(fragment,str(p),"exec"),env)
    print(label,"pre_fix_made_progress="+str(env["made_progress"]))
s=Path("test/gh115-round-cap.sh").read_text()
stub=s.split("cat >\"$STUB\" <<'STUB_EOF'",1)[1].split("\nSTUB_EOF",1)[0]
print("existing_Test_2_3_stub_commits="+str("git " in stub))
print("existing_Test_2_3_stub_increments_resolved="+str('echo "- [x] task $count"' in stub))
PY
```

Decisive output:

```text
receipt-only pre_fix_made_progress=True
real-file pre_fix_made_progress=True
resolved-only pre_fix_made_progress=True
no-change pre_fix_made_progress=False
existing_Test_2_3_stub_commits=False
existing_Test_2_3_stub_increments_resolved=True
```

**Evidence limits.** Verify-tier intent. Paginated graph inventory had no index for this task worktree. Nearest Forge index was ready, generation `2026-09-01T15:54:30Z`; searches for `get_head_commit` returned no nodes. Coverage reported metadata_changed for all three source/suite paths and missing for the plan, so material claims use direct current source reads. TESTS-RESULTS scope had a deliberately excluded compressed log; no exhaustive claim relies on it. No graph completeness or passing gate is asserted.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Round 1 · claude-a · Author response · 2026-10-05

Driver note: round 1 exited 3 (classified as stall) although a full review block was appended; treating
the content as the review and re-driving. Pre-fix red witnessed on the current code with a standalone
`$TMPDIR` script: receipt-only commits inside the turn produced `bounded extension granted` twice and
`cap-progressing-extended` at cap 4, exit 4.

1. **[Must] red control** — Accepted. Plan §Implementation step 2 rewritten: one standalone script,
   commits inside the dispatched turn, no approval, cap pinned at 2, run on base and candidate, with
   the exact-file (B) and directory (A) cases and the listed assertions; evidence under
   `TESTS-RESULTS/2026-10-05+GH-976/` with `provenance.jsonl`. The wrong attestation explanation is removed.
2. **[Must] positive control** — Accepted. Cases C (real file), D (mixed) and E (no-SHA) added to the
   same script; registered suite unchanged.
3. **[Note] claim too broad** — Accepted; §Observed problem now qualifies it to same-repo tracked
   receipt turns and names the no-commit and archive-repo paths.
4. **[Note] coordinates** — Accepted; §Requirement now reuses `target_repo()` and compares the relay
   file relative to that repo, omitting the exact-file exclusion when the transcript is elsewhere.
5. **[Note] issue acceptance** — Accepted; issue #976 edited to withdraw the `adjudication-requested`
   item and point at `STATUS: Escalated`. The consumer incident is quoted in the issue body for the
   reviewer since the API is unreachable from the worktree.
6. **[Note]** — No change.

STATUS set back to Open for round 2.


### Round 2 · codex · plan QA · 2026-10-05

**Verdict: Approved — the revised plan is buildable as written.** Both Round 1 Must findings are resolved. The specified helper and oracle replacement fix same-repository receipt-only extension while preserving real-file and resolved-item progress. Approval is of the plan, not of an implementation or passing gate. Review edits are Easy to reverse. Production blast radius is the Python relay driver's cap-extension decision for all consumers; a wrong filter would withhold or grant an extra turn, bounded by the unchanged hard ceiling. The plan provides a direct oracle rollback.

1. **[Note] DoD 1 — defect confirmed, qualified claim sufficient.** `relay_drive.py:794` samples HEAD before dispatch and :1093 samples it after. The current :1097–1098 accepts any nonempty unequal pair, so a same-repo transcript-only commit at `relay-turn-lib.sh:1498` satisfies it. :1102–1107 grants the extension, bounded by :737–738. The plan now names the no-commit (:1480–1495) and separate archive (:1502–1523) cases. Its remaining sentence “Every relay turn commits its own transcript” is still literally too broad, but the adjacent qualification makes the operative requirement unambiguous; it is not a build blocker. Driver :643 is an approval-attestation commit, not a second commit on every open turn (`judge_terminal`, :671–672).

2. **[Note] DoD 2 — receipt filter and coordinates are adequate for this bounded scope.** The inspected turn commit selects staged allowlisted paths (:1474–1498), the archive commit selects the relay path (:1516–1518), and attestation selects the relay file (`relay_drive.py:642–643`). No additional fixed receipt path is demonstrated by these sites. The exact relay-file exclusion covers an arbitrary location; using `target_repo()` (:616–623) keeps it in the same coordinates as `get_head_commit()` (:579–590), and omitting it for an external transcript avoids an unrelated basename exclusion. Directory prefixes retain trailing slashes. Real evidence repairs under `TESTS-RESULTS/` and brief edits under `marathon-system/` are intentionally excluded by the written progress policy; a mixed commit containing a real source change still qualifies. This is not an exhaustive inventory of every possible consumer receipt.

3. **[Note] DoD 3 — GH-115 preservation now has an appropriate proof recipe.** Tests 2/3 append resolved lines (`test/gh115-round-cap.sh:23–24`, enabled :68/:89), so retaining :1099–1100 should preserve them. They cannot prove committed-file progress. Revised cases C/D hold that count fixed and commit a real file inside the dispatched turn, so an always-False helper would fail those controls. Keep the suite unchanged. Positive runs should reach the existing hard ceiling (cap 4 for initial cap 2), exit 4 with `cap-progressing-extended`, and contain the extension output/block; this follows the already-specified bounded behavior, not a new requirement.

4. **[Note] DoD 4 — red control is now credible and falsifiable.** Revised step 2 pins a disposable full clone, base/candidate revisions, initial cap 2, commits inside dispatch, continued token handoffs, no approval, and fixed resolved count. Receipt-only A/B should fail their candidate expectation on base: the old oracle grants extensions instead of stopping after two turns with `cap-stalled`. Nonempty output, exit/reason, turn count, and extension text/block checks avoid a vacuous pass. C/D prevent a false negative oracle from masquerading as a fix. E covers missing SHA; an invalid SHA/diff-error helper call can settle the separately specified git-error branch without new machinery. **[Unverified — needs clone run]**: no manual fixture or suite was executed here. The author's pre-fix run is reported evidence until its commands/output and `provenance.jsonl` are retained as specified; it is not my observed integration result.

5. **[Note] DoD 5 — adjudication non-goal is justified and issue scope reconciled.** `escalated_status` (:399–400) accepts `Escalated`; :756–759 and :1044–1047 exit 4 with `human-escalation` before the extension decision. Both roles may edit the relay file; the approval-role restriction covers Approved/Closed (:396–397, :671–674), not Escalated. GitHub connector `github_fetch_issue(repository_full_name="HiQS-Labs/XYZ-forge", issue_number=976)` succeeded: the current [issue #976](https://github.com/HiQS-Labs/XYZ-forge/issues/976) body explicitly withdraws the earlier prose/NEXT acceptance in favor of this marker. The same fetch for [consumer #75](https://github.com/david-nguyen-chaoticdomain/user-sage-backend/issues/75) returned API 404; web opens of both URLs returned cache misses. The consumer incident is therefore available here only through #976's quoted report, not independently verified.

6. **[Note] DoD 6 — right-sized.** One nested helper, existing repository resolver, one oracle replacement, no new dependency/runner/suite/gate, and no frozen Bash edit. Returning False on missing SHA or diff failure must still allow the independent resolved-count arm. The revised manual controls supply the missing proof without expanding production scope. A cold builder has the filter, repository-coordinate rule, call site, failure policy, controls, evidence destination, and rollback needed to implement this plan.

**Non-mutating probe (exit 0).** Only the current oracle's AST statements were executed with synthetic values; no git command, fixture, dispatch, pytest or suite was invoked:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
import ast
from pathlib import Path
p=Path("utils/py/relay_drive.py")
tree=ast.parse(p.read_text())
main=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=="main")
loop=next(n for n in main.body if isinstance(n,ast.While) and n.lineno==740)
i=next(i for i,n in enumerate(loop.body) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="made_progress" for t in n.targets))
fragment=ast.Module(body=loop.body[i:i+2],type_ignores=[])
for label,b,a,rb,ra in [("receipt-only","a","b",0,0),("real-file","a","b",0,0),("no-SHA","","",0,0),("resolved-only","","",0,1)]:
    env=dict(head_before=b,head_after=a,resolved_before=rb,resolved_after=ra)
    exec(compile(fragment,str(p),"exec"),env)
    print(label,"base_made_progress="+str(env["made_progress"]))
PYPROBE
```

Decisive output:

```text
receipt-only base_made_progress=True
real-file base_made_progress=True
no-SHA base_made_progress=False
resolved-only base_made_progress=True
```

**Evidence limits.** Verify tier. `list_projects(limit=100)` returned all 77 projects with no current task index. Nearest Forge index `XYZ-forge` was ready; coverage generation `2026-09-01T15:54:30Z`. Narrow graph search for the exact two helper names in `utils/py/relay_drive.py` returned no nodes. Coverage for the three cited code/suite paths reported `metadata_changed`; the plan was `missing`. Current direct source reads therefore supply the material evidence. No exhaustive or graph-completeness claim is made. Only this relay file was edited; no git commands or prohibited gates were run. Implementation verification remains for the disposable clone and harness gate.
