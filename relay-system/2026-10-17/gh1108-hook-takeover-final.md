# RELAY · gh1108-hook-takeover-final
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh1108-hook-takeover-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: skills/2-daily/merge-cleanup/scripts/merge_cleanup.py (`run_jog_post_merge_land`), TESTS-RESULTS/2026-10-17+GH-1108/hook-no-bundle-skip-manual.{py,log}.txt, PROJECT/2-WORKING/GH-1108-JOG-LAND-RECEIPTS.md (Takeover section)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: the merge-cleanup post-merge Jog hook never fails a landing for a mapped row that has no committed receipt bundle in the merged tree; it still fails when a bundle exists and `jog land` refuses; bad `gh pr view` output is a named failure; nothing else in PR #1116 changed; no new suites (GH-831).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Context.** PR #1116 (GH-1108 delivery 1) was independently reviewed at 323602cd. One Blocker: `run_jog_post_merge_land` mapped every `pending|running|failed|parked` Jog row reachable from a PR's closing issues or any `gh<N>` token in its branch name and returned False when `jog land` refused — so a hand-built PR that closes an issue with a stale Jog row (GH-269, 310, 529, 533, 1075 exist today) stopped merge-cleanup after the remote merge, before `commit_and_push_phase5_writes`, and `--reconcile-pr` re-entered the same refusal. Operator decision: fix only this, land, stop delivery 2 (#1117), freeze Jog.

**Change under review (commit aa3ae393, one function):** after mapping, the hook runs `git ls-tree -r --name-only -z HEAD -- TESTS-RESULTS` in the primary and keeps only mapped issues that have a committed `TESTS-RESULTS/<date>+GH-<n>/jog/<exec>/receipt.json`; the others are logged `warn: … not a Jog delivery — row left as-is` and skipped. Rows with a bundle still go through `jog land`, and a refusal still returns False. `json.loads(gh pr view)` is wrapped: non-JSON/non-object → `log_err` + False (CodeRabbit item). Nothing else in the PR changed.

**Operational envelope.** Local merge-cleanup CLI run by one operator in the primary checkout after a PR merged on GitHub. Commensurate complexity: no new suites, no new config, no new subsystem. Evidence: `hook-no-bundle-skip-manual.py.txt` (6/6 green on aa3ae393; red at 323602cd: A1/A2 fail, D crashes) and the focused gh436/gh280 suites re-run in this clone (`takeover-focused-suites.log.txt`).

**Questions (answer each with file:line):**
1. Does the bundle regex over `ls-tree -z` output match exactly the layout `publish_jog_receipt` writes (`TESTS-RESULTS/<YYYY-MM-DD>+GH-<n>/jog/<execution-id>/receipt.json`) and nothing else? Any path shape that would be wrongly included or excluded (e.g. multiple executions, foreign `+GH-` dirs)?
2. Is the skip safe: can a row that *is* a Jog delivery ever lack a bundle in the merged tree at hook time (publication failed/parked, or the lane commit was squashed away by policy), and if so is "row left as-is + warn" the correct outcome versus failing?
3. Does the `mapped &= bundled` intersection preserve the original refusal path (bundle present + `jog land` rc≠0 → False) unchanged? Confirm against `jog_land` in `utils/py/jog_run.py`.
4. Is the `run_git(repo_path, [...])` argument order and return shape correct for `scan_clones.run_git`, and is a non-zero `ls-tree` handled as a named failure?
5. The `gh pr view` JSON guard: any remaining path in this function where malformed subprocess output raises instead of returning False?
6. Does the manual control actually exercise the real function (not a copy), and does its red run at 323602cd falsify the claim? Note it stubs `subprocess.run` and `_gh` by module attribute.
7. Anything in this one-function change that is over-built for the envelope, or a simpler equivalent?

Grade each finding [Blocker]/[Should]/[Nit]/[Unverified — no citation]; a [Blocker]/[Should] requesting a behaviour change must carry Observed input / Affected scope / Falsifier. Do not ask for new tests. End with STATUS: Approved if the Definition of Done holds.


### Reviewer · Round 1

**VERDICT: FAIL**

**Basis:** The no-bundle skip meets its purpose, but bad `gh pr view` output is not always a named failure. One Should remains. No source edits, Git commands, suites, or executable fixtures were run.

swept file: yes

Read all 1,789 lines of merge_cleanup.py, both manual evidence files, and the task document; checked publisher, committed-reader, landing and Git-helper source. No additional pre-existing defect was established beyond the malformed-object path below. Verify-tier graph discovery found no project for this worktree across both project-list pages. Nearest XYZ-forge generation is 2026-09-01T15:54:30Z; coverage reports untracked/changed/missing paths. Current local source supplies the evidence, not that stale graph.

- **[Should] Q5 — finish validating the PR object (merge_cleanup.py:660–668).** The guard rejects non-JSON and non-objects but accepts a numeric branch field. Mapping then raises TypeError outside the guard. A whole-function AST probe with stubbed read-only dependencies reproduced this; it also observed `{}` returning True without a diagnostic. These are malformed-output controls, not claims that GitHub normally emits these shapes.
  **Observed input:** rc=0 stdout `{"number":7,"title":"x","body":"Closes #1075","headRefName":123}`, actionable queue `{1075}`. Output: `TypeError: expected string or bytes-like object, got 'int'`, rather than a named failure.
  **Affected scope:** unusable PR objects at this hook's `gh pr view --json number,title,body,headRefName` boundary.
  **Falsifier:** numeric branch and missing required identity should log `Cannot map PR #7 to Jog rows: …` and return False without raising; a valid string branch must preserve mapping, skip and refusal behavior.
  **Concrete fix:** validate requested PR identity and usable field types inside the existing JSON guard, raising ValueError there on malformed objects. Preserve ordinary nullable text semantics where appropriate. Reuse the manual evidence surface; no new suite.

  Exact repeat probe command (non-mutating, exit 0 because exceptions are printed):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 - <<'PY'
  from pathlib import Path
  import json,re,types
  s=Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py").read_text()
  start=s.index('    try:\n        pr = json.loads(current.stdout)')
  s=s[start:s.index('    if not mapped:\n',start)]
  env=dict(json=json,re=re,pr_num=7,queue={1075},linked_issues=lambda pr:[1075],log_err=print)
  exec("def probe():\n"+s+"    return mapped\n",env)
  for raw in ['not json','[]','{"number":7,"title":"x","body":"Closes #1075","headRefName":123}','{"number":7,"title":"x","body":"Closes #1075","headRefName":"fix/gh1075-x"}']:
      env["current"]=types.SimpleNamespace(stdout=raw)
      try: print(raw,"=>",env["probe"]())
      except Exception as e: print(raw,"=>",type(e).__name__+": "+str(e))
  PY
  ```
  Decisive output: non-JSON and `[]` log named errors and return False; numeric branch prints `TypeError: expected string or bytes-like object, got 'int'`; valid string branch prints `{1075}`. An initial source-span probe failed to compile (`return outside function`); the function wrapper above corrected that probe. The earlier whole-function AST observation agrees.

- **[Pass] Q1 — all publisher paths are included, though the matcher is broader.** `jog_run.py:979–997,1015` restricts execution IDs to `[A-Za-z0-9][A-Za-z0-9_.-]*` and writes the dated issue directory plus receipt.json. `merge_cleanup.py:681–682` accepts those paths with NUL boundaries and exact parent depth. Multiple executions collapse to one issue; unrelated issue directories are removed by intersection. An execution component containing a space also matches the hook, but the strict reader rejects it (`jog_run.py:1046,1084–1085`); it cannot gain approval. No change requested.
- **[Pass] Q2 — absent publication intentionally skips without completing a row.** `merge_cleanup.py:683–686` warns and leaves the row unchanged. Publication failure can leave a genuine execution without a bundle; ordinary squash preserving files retains it. The revised requirement explicitly permits the absent-bundle skip. Publisher commit/push steps are at `jog_run.py:1016–1037`; the operator choice is recorded in the Takeover section (`GH-1108-JOG-LAND-RECEIPTS.md:145–152`).
- **[Pass] Q3 — refusal remains gating.** `merge_cleanup.py:686,694–700` intersects, invokes land for surviving issues, and returns False on nonzero status. `jog_run.py:1152,1209–1211` verifies committed evidence and returns 2 on refusal; completion follows at 1213–1229. The hook introduces no weaker approval predicate.
- **[Pass] Q4 — helper call and error handling fit.** `scan_clones.py:87–110` accepts `(cwd, args, timeout=None)` and returns subprocess text output. The call at `merge_cleanup.py:677` uses that order; lines 678–680 name a nonzero tree-listing failure and return False.
- **[Pass] Q6 — manual control calls the real function.** `hook-no-bundle-skip-manual.py.txt:14–16,66–72` imports and calls `mc.run_jog_post_merge_land`. Rebinding mc.subprocess leaves scan_clones.run_git's separate subprocess binding intact. Lines 78–102 cover skip, refusal, success and non-JSON output. Recorded log lines 5–13 show six green checks; 14–21 show pre-fix A checks red and red_rc=1, a useful red control for the skip. The log does not contain the claimed D traceback, so that red crash is not independently evidenced by this log.
- **[Pass] Q7 — bounded mechanism.** `merge_cleanup.py:677–686` uses one existing helper, a set and the original landing loop. No additional subsystem or suite is needed; complete only the existing malformed-output guard.
- **[Unverified — needs clone run]** Retained manual/focused-suite results were inspected, not rerun in this worktree. Final qualifying execution remains the harness's responsibility.
- **[Unverified — no citation]** “Nothing else in PR #1116 changed” cannot be independently attested from the seeded files with Git forbidden. Producer/harness must verify the commit diff against 323602cd; no PR-wide unchanged claim is made here.

**Handoff:** Producer (claude-a) should disposition the single Should and repair only the existing malformed-output guard if accepted. STATUS remains Open.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
