# RELAY · GH1436 and GH1437 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1436-and-gh1437-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1436-CONTRACT-ENVIRONMENT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1436-CONTRACT-ENVIRONMENT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Final QA scope

Review the complete implementation diff against origin/development, requirements in both PROJECT/2-WORKING/GH-1436-CONTRACT-ENVIRONMENT.md and GH-1437-GATE-PYTHON-ENVIRONMENT.md, plan receipt gh1436-plan.codex.md, and committed evidence TESTS-RESULTS/2026-11-12+GH-1436-1437/. The reviewed source is bf38b326 plus evidence/docs; required full push gate is pending and must pass before PR-ready publication. Do not interpret focused success as full qualification.

1. Does contract_shape_error reject bounded malformed shapes before all planner consumers, while preserving optional-null markers and partial intake? Check both registered and unregistered paths and the changed extraction tuple callers.
2. Does the needs-contract finding retain wave_reconcile's owned/unrelated semantics? Compare manual matrix and existing suite evidence.
3. Does HQ validate the final selected request before external/file writes with no probe execution?
4. Does validate.sh refuse unsupported Python or missing any module before suites with a distinct code and exact remedy, preserving healthy and PHP behavior?
5. Are evidence claims reproducible and diff scope commensurate? No new registered tests/gates, no interpreter installation or speculative schema framework.

Only edit this relay. Do not run suites in the review worktree. Report observed input, affected scope and falsifier for behavioral findings. A complete code review is requested; retained manual evidence is available, full gate remains the author's publication obligation.

## Log

### Reviewer · Round 1

swept file: no

- [Should] HQ filing-time validation can skip a supplied malformed contract. At utils/hq/hq.sh:328, the heading expression uses `.*` with `re.S`, so it consumes subsequent headings and prose containing “preflight contract”; the block search then sees an empty body and never calls the validator. Use the same line-bounded first-heading/section extraction semantics as `swarm_preflight.extract_contract`, or at minimum prevent the heading matcher from crossing newlines. Preserve partial intake and do not execute probes.
  Observed input: `## Preflight Contract\n```json\n{"target":"bad"}\n```\n\n## Acceptance\n- Reject malformed preflight contract before filing.\n` (literal `\n` here denotes a newline).
  Affected scope: HQ requests containing a contract followed by later prose mentioning “preflight contract”; the first contract is malformed but the current validation branch silently skips it before the issue/capture writer.
  Falsifier: With that exact request, the extracted first JSON must reach `contract_shape_error` and refuse with `target must be an object` before writes. The same request with `{"artifacts":["README.md"]}` must remain accepted as partial intake.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` using the exact two `re.search` patterns from hq.sh against the request above, followed by the line-based heading search from extract_contract. Exit 0; decisive output: `HQ matched section body: ''`, `HQ validation invoked: False`, `extract_contract heading: ## Preflight Contract`, `first contract JSON: {"target":"bad"}`. This was a pure in-memory parsing probe; no HQ writer, fixture, git command, or suite was executed.
- [Pass] Planner shape rejection is ordered before zone/probe consumers: utils/py/_marathon_plan.py:484 returns `(None if error else contract), error`; :1138 extracts before `_zone_of`; :1171-1178 holds malformed rows using `needs-contract` and continues. The helper at utils/py/swarm_preflight.py:54-92 preserves optional-null `lanes`/`artifacts_new` while rejecting non-object target and malformed path arrays.
- [Pass] The environment branch exits 3 before suite dispatch and prints the interpreter, version, missing modules and explicit PATH remedy (validate.sh:1033-1043). Committed focused evidence is explicitly bounded: TESTS-RESULTS/2026-11-12+GH-1436-1437/SUMMARY.md says “No claims of full-gate or hosted success yet”; provenance.jsonl records eight focused suite commands at bf38b326.
- [Unverified — needs clone run] No suites or executable evidence scripts were run here. Full push qualification remains outstanding and must pass before PR-ready publication.

**VERDICT: FAIL**

**Basis:** The observed HQ parsing bypass fails the filing-time rejection requirement. Reviewed the complete seeded artifact, both requirements, plan receipt, relevant implementation paths and retained evidence; the complete source-file sweep is unfinished, so no claim of an exhaustive pre-existing-defect audit is made. Finish that sweep on the next review after this concrete defect is repaired.

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer · Round 2

Implemented the observed HQ parsing finding: heading matching now excludes newlines and uses horizontal whitespace. The exact later-Acceptance prose input produced a malformed issue/capture write on bf38b326 (retained red) and now refuses before writes on f78c531c; matching partial intake remains accepted. Existing hq-park passes 23 assertions. Evidence and revised manual_hq.py are retained under the existing TESTS-RESULTS folder. Removed only generated LEADERBOARD intake churn per task-branch policy; no production change beyond the one-line heading fix.

Please finish the whole-diff sweep and recheck this concrete repair; source scope and full-gate obligation are unchanged.

### Reviewer · Round 2

swept file: no

- [Pass] Round 1 HQ finding is repaired: utils/hq/hq.sh:328 now bounds the heading with `[^\n]*` and horizontal whitespace. Pure in-memory replay of the two current `re.search` patterns on the exact Round 1 request produced `HQ {"target": "bad"} -> target must be an object`; the corresponding partial request produced `HQ {"artifacts": ["README.md"]} -> None` (exit 0). The validation still precedes issue/capture writes and imports only the shape helper (utils/hq/hq.sh:323-342). Retained f78c531c provenance separately records HQ no-write green and 23 existing-suite assertions; these were read, not rerun here.
- [Should] Accepted optional-null artifacts crash the next preflight consumer. `contract_shape_error` explicitly accepts `artifacts_new: null` (utils/py/swarm_preflight.py:74-75), and extract_contract also permits it (:163), but merge_contracts calls `list(None)` for the first contract (:219) and iterates None for later bundle contracts (:238). Main calls merge_contracts even for a single project doc (:1316). Normalize this optional marker to an empty list at both merge reads, preserving nonempty subset behavior. Extend the retained manual evidence through this existing consumer; manual_matrix.py:31-40 currently checks only planner and extract_contract for optional-null, so it misses the crash. This is a pre-existing defect in the touched source, covered by this relay's whole-file rule and optional-null review question.
  Observed input: `{"target":{"repo":".","ref":"development"},"gate":"true","fix_probes":[{"type":"path_absent","path":"missing"}],"artifacts":["README.md"],"artifacts_new":null}` passed as the sole member of merge_contracts, or as the second member after the same contract with artifacts_new absent.
  Affected scope: shape-valid execution contracts with explicit JSON null for artifacts_new, at either the first or a later bundle position; no broadening to other fields or execution authorization is requested.
  Falsifier: the exact input must merge without exception and yield artifacts_new `[]` in both positions. Absent and empty-list markers must continue yielding `[]`; valid nonempty subset markers must survive merging unchanged.
  Probe command (pure functions; no CLI, git, suites, fixtures, or probe execution):
  ```sh
  PYTHONDONTWRITEBYTECODE=1 python3 - <<'PYPROBE'
  import sys, copy
  sys.path.insert(0, 'utils/py')
  from swarm_preflight import contract_shape_error, merge_contracts
  c = {'target': {'repo': '.', 'ref': 'development'}, 'gate': 'true',
       'fix_probes': [{'type': 'path_absent', 'path': 'missing'}],
       'artifacts': ['README.md']}
  print('shape_error:', contract_shape_error(dict(c, artifacts_new=None)))
  for label, cs in [('absent', [c]), ('empty', [dict(c, artifacts_new=[])]),
                    ('first-null', [dict(c, artifacts_new=None)]),
                    ('later-null', [c, dict(c, artifacts_new=None)])]:
      try:
          print(label, '->', merge_contracts(copy.deepcopy(cs))['artifacts_new'])
      except Exception as e:
          print(label, '->', type(e).__name__ + ':', str(e))
  PYPROBE
  ```
  Equivalent in-memory probes executed here: initial single-case probe exited 1 with `shape_error: None` and `merge failure: TypeError: 'NoneType' object is not iterable`; follow-up with caught exceptions exited 0 and printed `absent -> []`, `empty -> []`, and both `first-null`/`later-null -> TypeError: 'NoneType' object is not iterable`.
- [Unverified — needs clone run] No suites or executable evidence scripts ran here. Full push gate remains pending before PR-ready publication. No git commands were used, so the requested complete origin/development diff comparison was not independently obtained. Read the complete seeded artifact, both requirements, plan receipt, retained receipts/scripts, HQ source, planner validation/discovery/packing/rendering paths, and preflight extraction/merge/execution paths. Whole-source sweep is not claimed complete: portions of the large gate registry and source output were truncated; this declaration must not be interpreted as exhaustive source approval.

**VERDICT: FAIL**

**Basis:** The earlier HQ defect is addressed, but a concrete downstream crash remains for an explicitly accepted optional-null marker. Correct both merge positions and retain discriminating manual evidence. Source-review and full-gate limitations above remain explicit; no approval or publication qualification is granted.

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer · Round 3

Implemented the concrete optional-null merge finding in both reads with `or []`; absent/empty/nonempty subset behavior remains unchanged. First/later null red controls at f78c531c and five green consumer controls at ebbe5877 are retained alongside a fresh passing swarm-preflight run. This is the final review round under the cap; assess residual concrete blockers without speculative broadening.

The exact complete implementation diff is now committed as TESTS-RESULTS/2026-11-12+GH-1436-1437/implementation.diff so the review can compare changes without invoking git. Read that complete file, then inspect affected paths with bounded ranges to avoid truncated registry output. Existing suite/full-gate results are distinct: focused is green; normal full pre-push qualification must still pass before PR-ready publication. No new production scope besides the two merge reads.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
