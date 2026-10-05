# RELAY · GH-789 port plan QA (+#965)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-05.
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
6. **Commit only the relay file** (`relay(gh-789-port-plan-qa-965): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-789-MERGE-CLEANUP-AUTONOMOUS-PIPELINE.md` (the port plan).
  Source being ported: commit `08bb0655` (base `f1321d6d`), diff `git diff f1321d6d 08bb0655 -- skills/2-daily/merge-cleanup/`.
  Both commits are reachable in this clone only if fetched; the plan quotes the relevant facts. Issues:
  https://github.com/HiQS-Labs/XYZ-forge/issues/789 and https://github.com/HiQS-Labs/XYZ-forge/issues/965.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-05
- Definition of Done: the plan is grounded in today's `development` code paths, scopes the port correctly (phase one
  + #965, not GH-786), resolves the two named conflicts without dropping dev behaviour, keeps GH-831 (no new tests or
  capability rows), and its manual matrix + red controls would actually catch each behaviour failing.

**Operational envelope.** Single-operator local merge tool, core skill (full gate on push). Grade against the plan's
stated scope. Do not ask for new test suites, new capability rows, retries, telemetry or a generic Markdown parser.

**Paths to read in this clone:** the plan; `skills/2-daily/merge-cleanup/scripts/{merge_cleanup,ledger_merge,scan_clones,toposort_prs}.py`;
`skills/2-daily/merge-cleanup/SKILL.md` (capability table + Drive loop); `test/gh534_phase_c_tests.py` (`TestParityGuard`,
`parity_failures`); `AGENTS.md` "No new tests". Plus the port source, retrievable read-only with
`git fetch https://github.com/HiQS-Labs/XYZ-forge.git` — it is NOT on GitHub; read the saved patch at
`.relay-artifacts/gh789-code.patch` (seeded read-only by the driver; the unified diff `f1321d6d..08bb0655` for the four scripts and SKILL.md).

**Questions.**
1. Are the plan's claims about today's code right: `refresh_pr` / `fetch_open_prs` lack `isDraft`; the hold-label skip,
   GH-851 post-push head wait and `PUSH_GATE_TIMEOUT_S` exist where the conflict notes say; `inspect_primary_landing`
   treats a lone `REBASE_HEAD` as an active rebase (`scan_clones.py` ~line 1167)? Cite lines.
2. Does the conflict-resolution plan keep every behaviour `development` gained since `f1321d6d` (GH-851 head wait,
   GH-852 MERGED re-query, `--resume`, attempt records, soft edges)? Name anything the patch would silently revert.
3. Is leaving out the two new capability rows correct under the parity guard, and is anything else in the patch
   (e.g. `gh534_phase_c_tests.py` +3) needed to keep an existing suite truthful?
4. Would the manual matrix cases (a)–(g) and the two red controls fail if the behaviour were wrong? Anything missing
   for #965's acceptance (Phase 4 Draft column; drafts named in summary; run not stopped)?
5. Is the `merge-cleanup-deep` intake (`scan_clones --json`) safe with the REBASE_HEAD change?
6. Anything over- or under-built? Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: the bounded port is appropriate, but case (f) contradicts the source's exit contract, a repaired-head draft refusal still stops the queue, and the proposed matrix cannot falsify several promised behaviours.
swept file: yes

Read the entire plan, seeded patch, four current scripts and SKILL.md; read the parity guard and deep-scan intake. Review is source-level, not execution approval. Graph tier: Verify; nearest indexed project is the canonical XYZ-forge checkout, generation 2026-10-05T16:15:58Z, not this worktree. Discovery returned all 8 narrowed symbols (no further page); coverage reported no recorded gaps for the six requested source paths. Inbound trace calls were unavailable ("MCP tool call requires approval, but approval policy is never"), so current worktree source is the authority for call paths below. No git, suites or executable fixtures run.

- **[Should] F1 — Split case (f)'s incompatible exit expectations.** Plan lines 81–82 combine a skipped draft, an independent landing and a blocked hard dependent with "exit 0"; patch lines 220–225 retain the hard dependent as a non-draft failed outcome, and lines 294–298 remove only the draft itself. Current `merge_cleanup.py:1088–1097` then returns 3. "Zero merge calls" also needs to mean zero calls **for the draft and its dependent**, since the independent must merge. Fix the plan to require (f1) draft + independent → exit 0, one independent merge, named draft summary; (f2) add hard dependent → independent still lands, dependent never attempted, exit 3 with named dependency. Do not weaken the non-landed-dependent contract merely to make this matrix green.
  Observed input: plan case (f), concretely queue #1 draft, #2 with `_hard_deps=[1]`, #3 independent; patch stores #2 as `"blocked by #1"` and only filters `"draft"`.
  Affected scope: verification expectations for drafts with and without blocked hard successors.
  Falsifier: disposable-clone runs of those two queues; f1 must return 0, f2 must return 3, and both must land #3 only.

- **[Should] F2 — Specify the skip at the repaired-head push boundary, not just refusal to push.** Plan lines 44–48 promise a live draft skip before repair/merge. Patch `.relay-artifacts/gh789-code.patch:186–187` adds a draft refusal to **merge_cleanup.push_resolved_head**, not `ledger_merge` as plan line 45 says. Its unchanged caller `merge_cleanup.py:1004–1008` stops with exit 2 on any false result; the later draft skip never runs. Cheapest fix: correct the owner in the plan and explicitly distinguish a positively observed draft refusal as a named skip, retain repair evidence, mark it as a hard predecessor that did not land, and continue independent PRs. Preserve fail-closed handling for unknown state, moved heads and other push failures.
  Observed input: the seeded guard's `live.get("isDraft")` branch returns `(False, "PR is draft or no longer open — not pushing repaired head")` (patch:186–187); the actual caller's `if not ok` returns 2 (current source:1005–1008). Concrete transition to measure: initially OPEN/non-draft at head A, B1 creates B, push-time refresh is OPEN/draft at A.
  Affected scope: a draft positively observed at the pre-push refresh after B1; not every false push result.
  Falsifier: clone-run fixture with that transition must make zero pushes/merges for this PR, name it in the draft summary and land an independent successor; a non-draft moved head or failed refresh must retain refusal. **[Unverified — needs clone run]** for runtime reproduction; this finding is the observed source path, not a claim that a fixture ran.

- **[Should] F3 — Make the manual evidence cover the actual acceptance predicates.** Plan `Verification:78–86` has no required assertion for the Phase 4 Draft column, the named summary or soft successors; the optional live table check cannot catch a missing column automatically. The initial-draft queue cannot catch removal of post-poll, post-B1 or pre-merge draft checks (patch:251–266, 274–284). Case (g) does not exercise the audit-mode exclusions or compare-and-delete refusal (patch:305–316). Extend the same unregistered manual evidence, not a new suite: assert Draft cells for true/false, exact skipped PR identities and per-PR mutation calls; cover each promised draft refresh boundary including F2; assert changelog output bytes/entries/history and duplicate retention/deduplication, plus the promised fenced/HTML rejection; cover scan/prs/teardown audit non-pruning, dirty-primary non-pruning, active rebase-apply/sequencer and a changed observed OID refusing deletion. Record red controls that remove the relevant draft/marker guards and make these cases fail; the two existing controls only exercise initial draft/additive support and a permissive changelog classifier. Require committed `provenance.jsonl`, command/exit/output receipts for candidate and controls. These are proof changes to the plan; no additional runtime mechanism requested.

- **[Nit] F4 — Correct the parity explanation and bound the missing source evidence.** Omitting both new rows is consistent with the explicit GH-831/no-capability-row scope. However, `test/gh534_phase_c_tests.py:585–596` checks named tests only while iterating **REQUIRED_CAPABILITIES**, not every table row. Neither new row is currently required (`:527–546`); merely adding them would be silently unchecked, not a missing-test failure. Correct plan line 65. The supplied patch contains no test-file diff, so the referenced old `gh534_phase_c_tests.py +3` is **[Unverified — needs source hunk]**. No extra imports/required rows are needed for the chosen omission; preserve today's required set rather than importing historical test changes without their hunk.

- **[Pass] Current-code grounding and bounded scope.** `merge_cleanup.py:185–188` and `toposort_prs.py:30–36` omit isDraft; hold-label skip is at `merge_cleanup.py:894–897`; GH-851 pushed-head wait and head checks are at `:1010–1029`; PUSH_GATE_TIMEOUT_S is at `:89` and used at `:639`; a lone REBASE_HEAD is treated as a rebase at `scan_clones.py:1165–1189`. Preserve those dev behaviours by surgical porting, together with GH-852 MERGED re-query (`merge_cleanup.py:165–181`), bounded push (`:356`), retry clone cleanup (`:298–302`), resume/attempt records (`:933–998`), hosted reconciliation and post-merge durability (`:1073–1084`), and the current SKILL batch/backup prose. Replacing whole historical files would revert these; the saved patch is a delta, not authority to replace them. The patch also carries soft-cycle prevention and pending-hard-prerequisite protection (`patch:200–225, 414–444`): name these small supporting transforms in scope and include a dependency-order assertion; they are not GH-786 batch records.

- **[Pass] Deep intake does not traverse the changed readiness function.** `scan_clones.py:1311–1314` emits `scan_directories` checkout records; `scan_directories` calls `inspect_checkout` (`:1033–1092`), not `inspect_primary_landing`. The latter is the function the marker patch changes. Deep skill Phase 0 selects dispositions from that JSON. Thus the intake remains safe by call-path separation, not because the scanner's JSON "only adds fields" (plan:93–94). Keep inspection read-only. The pre-existing hold-label dependency gap is explicitly excluded as #785 (plan:70–71); no additional independent defect requiring expansion of this port was identified in the full-file sweep.

Static probe receipt (non-mutating; AST only, no module imports or fixtures): command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` with this body, exit **0**:
```python
import ast
from pathlib import Path
p = Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py")
s = p.read_text()
tree = ast.parse(s)
f = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "land_prs")
for n in ast.walk(f):
    if isinstance(n, ast.If) and n.lineno == 1005:
        print("push failure branch:", ast.get_source_segment(s, n.test),
              "returns:", [ast.literal_eval(x.value) for x in n.body if isinstance(x, ast.Return)])
t = ast.parse(Path("test/gh534_phase_c_tests.py").read_text())
a = next(n for n in t.body if isinstance(n, ast.Assign) and any(isinstance(x, ast.Name) and x.id == "REQUIRED_CAPABILITIES" for x in n.targets))
caps = ast.literal_eval(a.value)
for c in ("draft-skips-dependent", "changelog-additive-resolution"):
    print(c, "required by current parity guard:", c in caps)
patch = Path(".relay-artifacts/gh789-code.patch").read_text()
print("seeded patch has test-file diff:", "diff --git a/test/" in patch)
```
Decisive output:
```text
push failure branch: not ok returns: [2]
draft-skips-dependent required by current parity guard: False
changelog-additive-resolution required by current parity guard: False
seeded patch has test-file diff: False
```

Handing off to Producer (claude-a) — revise the plan and disposition F1–F4, then return for round 2. No approval of implementation or clone-run verification is implied.

### Producer · Round 1 · claude-a

- **F1 — Implemented.** Case (f) split into f1 (draft + independent → exit 0, one merge, draft named) and f2 (adds a hard dependent → independent lands, dependent never attempted, exit 3 naming the block). The non-landed-dependent contract is unchanged.
- **F2 — Implemented.** Plan now names the owner correctly (`merge_cleanup.push_resolved_head`, caller `merge_cleanup.py:1004–1008`) and requires a positively observed draft at the repaired-head push to be a named skip (zero push/merge, B1 evidence kept, non-landed hard predecessor, independents continue); every other push failure keeps `return 2`.
- **F3 — Implemented, by reuse.** The source's own 22 cases (TestGh789Drafts / TestGh789Changelog / TestGh789ChangelogMerge / five REBASE_HEAD cases at `08bb0655`) move into one unregistered evidence script under `TESTS-RESULTS/2026-10-05+GH-789/` importing the existing `LedgerFixture`; added a Phase 4 Draft-cell assertion; each draft boundary, changelog byte/history/dedupe/fenced case and marker mode is listed, with a red control per guard group and committed provenance. No registry entry.
- **F4 — Implemented.** Parity explanation corrected (guard checks named tests only for `REQUIRED_CAPABILITIES`); the source's phase_c hunk (import + two required rows) is explicitly not ported. Supporting soft-cycle / pending-hard-prerequisite transforms are now named in scope.
- Also corrected the deep-scan safety reason to call-path separation, per the Pass note.

Round 2: please re-review the revised plan.

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: F1–F4 are resolved in the revised plan. The bounded delta preserves today's landing contracts and now names falsifiable acceptance cases. This approves the plan, not implementation or runtime results.
swept file: yes

Swept the entire revised plan, seeded patch, four current scripts and SKILL.md; re-read the parity guard. Applied the SWE planning rubric. No additional pre-existing defect requiring expansion of this bounded port was identified; the already-excluded hold-label dependency gap remains #785.

Graph tier: Verify, project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-10-05T16:15:58Z`, canonical checkout rather than this worktree. Symbol query returned six results with no further page. Exact-path coverage reported no recorded gaps and metadata matches for the four scripts, SKILL.md and parity source; scope coverage excludes only `__pycache__`. The similarly named `XYZ-forge` index was stale (2026-09-01, paths not tracked), so its empty results were discarded. Worktree source reads are the authority. No git, executable fixtures or suites run.

- **[Pass] F1 and F2 closed.** Plan lines 99–100 split draft-only success from blocked-hard-dependent exit 3, with per-PR merge expectations and named summaries. Lines 45–49 correctly name `merge_cleanup.push_resolved_head` and require a positively observed pre-push draft to skip while retaining B1 evidence and continuing independents; other push refusals stay exit 2. This explicitly fixes the seeded patch's combined refusal at patch lines 186–187 and current caller's stop at `merge_cleanup.py:1004–1008`. Implement the specified distinction rather than copying that historical branch unchanged.
- **[Pass] F3 closed as a proof contract.** Plan lines 95–111 require draft transitions at polling, gate and repaired-push boundaries, hard/soft dependency outcomes, true/false Draft cells, byte/history/deduplication checks, audit/dirty/active-operation non-pruning and compare-and-delete refusal. Candidate and deliberately broken controls must emit committed receipts (lines 108–112). These expected outcomes can reject missing guards; no claim is made that the matrix has run.
- **[Pass] F4 and dev preservation closed.** Plan lines 70–77 preserve the current required capabilities and omit historical additions while keeping GH-851, GH-852, bounded push, resume/attempt records, hosted reconcile and durability. Current `parity_failures` iterates `REQUIRED_CAPABILITIES` (`test/gh534_phase_c_tests.py:585–596`); omission creates no required missing test. Supporting pending-hard-prerequisite and soft-cycle transforms are explicitly scoped at plan lines 53–55, matching patch lines 200–225 and 414–444.
- **[Pass] Read-only deep intake and containment.** Plan lines 120–122 correctly identify `scan_directories → inspect_checkout`, separate from `inspect_primary_landing`; current scanner JSON dispatch is at `scan_clones.py:1311–1314`. Plan lines 61–65 and 105–107 constrain marker deletion to ready execute landing/reconcile and require the observed OID; scan/prs/teardown and dry runs remain non-pruning.
- **[Nit] Historical test evidence remains unavailable in this envelope.** Plan lines 89–93 and 73–74 describe 22 old cases and a phase-C import/required-row hunk, but the seeded patch contains only SKILL.md and four scripts. **[Unverified — needs source hunk]** for that historical count/content. During implementation, read the source hunks before transplanting; if unavailable, implement the explicitly listed manual checks using existing helpers and record that provenance honestly. This does not change scope or authorize a registered suite.
- **[Unverified — needs clone run]** The completed manual matrix, red-control failures, existing suite and full gate. Plan lines 87–112 already require these in a disposable full clone with identity checks and committed provenance. They remain prerequisites to implementation approval.

Relay closed (Approved), no further review turn needed. Producer (claude-a) may implement the approved plan and collect the required clone-run evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
