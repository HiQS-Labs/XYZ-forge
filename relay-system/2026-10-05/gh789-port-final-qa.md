# RELAY · GH-789 port final QA (+#965)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-05.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh-789-port-final-qa-965): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, plus the rest of this branch's diff against
  the development base `442ea913`: `ledger_merge.py`, `scan_clones.py`, `toposort_prs.py`, `skills/2-daily/merge-cleanup/SKILL.md`,
  the two fixture edits in `test/gh534_phase_b_tests.py` and `test/gh436-merge-cleanup.py`, the matrix and receipts in
  `TESTS-RESULTS/2026-10-05+GH-789/`, the plan `PROJECT/2-WORKING/GH-789-MERGE-CLEANUP-AUTONOMOUS-PIPELINE.md`, and the
  ledger rows (releases.sql). Approved plan QA: `relay-system/2026-10-05/gh789-port-plan-qa.md` (round 2).
  Issues: https://github.com/HiQS-Labs/XYZ-forge/issues/789, https://github.com/HiQS-Labs/XYZ-forge/issues/965.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-05
- Definition of Done: the code does what the approved plan says (drafts at every boundary incl. the F2 push-boundary skip,
  f1/f2 exit codes, Draft column, CHANGELOG union, stale REBASE_HEAD), keeps every behaviour development gained since
  f1321d6d, adds no test suite / registry entry / capability row (GH-831; the two fixture edits only keep existing suites
  truthful), and the receipts substantiate each claim, including the red controls.

**Operational envelope.** Single-operator local merge tool, core skill. Grade against the approved plan. Do not ask for
new suites, capability rows, retries or a Markdown parser.

**Questions.**
1. Does the code match the approved plan item by item? Cite `file:line` for any gap, especially `push_resolved_head` /
   `DRAFT_REFUSAL` and its caller, the draft summary line, and `prepare_primary_landing`.
2. Did the conflict resolution drop or weaken any development behaviour (GH-851 head wait, GH-852 MERGED re-query,
   resume/attempt records, PUSH_GATE_TIMEOUT_S, hold labels, soft edges)? Concrete input if so.
3. Are the two test-file edits limited to keeping existing suites truthful (fixture `isDraft`; one extra mocked refresh)?
   Is anything else in `test/` new?
4. Do the receipts in `provenance.jsonl` and the logs support the candidate (26/26), R0–R4 and the gh436 run? Over-claims?
5. The SKILL.md wording change at the Phase 1 safe-roots sentence (GH-970 parked nit) — accurate?
6. Ratings 75/70/50/50 (GH-789) and 60/50/50/85 (GH-965) — still right on this evidence?

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
Basis: The bounded implementation matches the approved plan on source inspection and preserves the named development behaviours. Two required evidence claims are not yet substantiated accurately: F2 continuation and red-control attribution. These are proof fixes, not requests to expand runtime scope.
swept file: yes

Swept all four scripts, SKILL.md, both edited fixture files, the entire manual matrix, the plan and receipt/log outcomes. Compared the four scripts, SKILL.md, both fixtures, phase-C source and validate.sh to development `442ea913` fetched read-only through GitHub. No additional pre-existing source defect requiring expansion of this port was identified; the explicitly excluded hold-label dependency gap remains #785. No git, suites, pytest or executable fixtures ran. Graph tier Verify: canonical project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-10-05T16:15:58Z`, six symbol results, no further page. Coverage has no recorded gaps for the scripts/fixtures/skill, but indexes the canonical checkout's older code; the candidate matrix/plan are missing there. Candidate source reads are authoritative. The graph trace call was unavailable under this runtime's approval policy, so caller inspection used source.

- **[Should] F1 — F2's integration case does not exercise its promised independent landing.** `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py:373` says “independent lands”, but `conflict()` creates only PRs #1/#2 (`:327` and `:328`) and merges #1 before the reviewed run (`:329`). The case adds no PR, checks only #2 staying OPEN/no merge and rc 0 (`:394`–`:397`), and never measures the PR-head ref or retained B1 evidence. Thus a premature successful return at the push-boundary skip could pass this case. The existing unit case (`:240`) establishes no push for an OPEN draft, but does not establish queue continuation. **Fix:** extend this existing, unregistered matrix case with a later independent PR and an explicit hard dependent of #2; assert the independent actually merges, #2's remote head stays unchanged, the dependent is never attempted with a named block/exit 3, and the resolved B1 clone/record remains. Keep a draft-plus-independent variant at exit 0 if needed. Run it in the disposable full clone and witness a control that prematurely returns instead of continuing fail. No new suite, fixture, registry or capability row.
  Observed input: the current case's open queue contains only #2 after `self.conflict()`; AST probe below finds no additional `self.branch` call in that case.
  Affected scope: evidence for the already-approved repaired-head draft boundary (`merge_cleanup.py:1023`–`:1032`), not a new runtime policy.
  Falsifier: an existing recorded run where #2 becomes draft at that boundary and a later independent PR lands while a hard dependent stays unattempted, with unchanged #2 head and retained B1 evidence; that would satisfy this request without extending the matrix.

- **[Should] F2 — Correct the control receipts and supply their reproducible commands.** `provenance.jsonl:2` says R0 failed “24 of 26”, but `R0-unported.log:414` says “Ran 25 tests”; `:416` reports 14 failures and 22 errors (including subtests). R0/R1/R2/R3 all collect 25 and show older matrix line numbers, while every receipt names `d62d72e1`, whose candidate collects 26 (`G-candidate.log:6`). None of the six red-control rows has a command. The plan status (`PROJECT/2-WORKING/GH-789-MERGE-CLEANUP-AUTONOMOUS-PIPELINE.md:22`) claims seven red controls; only six receipts/logs exist. **Fix:** attribute each run to the actual matrix/source revision (or content hashes plus exact mutation), record the mutation and run commands as required at plan `:108`, and correct the counts. Preserve earlier evidence as earlier evidence; rerun only the strengthened F1 case and controls needed for changed assertions, in a disposable full clone. Retain the useful R4 disclosure that its first control stayed green and required a stronger assertion.
  Observed input: probe below reports R0/R1/R2/R3 as 25 collected, all six rows with `command present: False`, and six red-control receipts.
  Affected scope: provenance and plan status accuracy for these supplied runs; no runtime behaviour change.
  Falsifier: a seventh supplied receipt/log and reproducible commands/source identities that account for the 25-case versus 26-case runs; then the corresponding claim can stand.

- **[Pass] Draft and dependency source contracts.** `refresh_pr` requests `isDraft` (`merge_cleanup.py:188`); discovery does too (`toposort_prs.py:35`). Initial/post-poll skips are at `merge_cleanup.py:905` and `:928`, post-repair at `:1054`, final pre-merge at `:1088`. `push_resolved_head` checks refresh error/OPEN state, returns `DRAFT_REFUSAL` for an observed draft, and retains moved-head refusal (`:354`–`:367`); its caller retains B1 evidence and continues only for that reason (`:1023`–`:1032`). Drafts stay in the failure map for hard dependencies (`:880`) before being removed for final success accounting, with the named summary (`:1130`–`:1143`). The Draft column has actual yes/no cells (`toposort_prs.py:198`, `:217`); soft-cycle prevention is at `:135`–`:146`. These are source passes; F1 above limits the F2 runtime claim.

- **[Pass] CHANGELOG and marker safety boundaries.** `union_changelog` checks unchanged preamble/history and rejects ambiguous/fenced/HTML/duplicate-heading inputs before returning an exact-block union (`ledger_merge.py:419`–`:460`). `read_changelog_union` requires one merge base and reads binary UTF-8 (`:463`–`:474`); B1 classifies both CHANGELOG and ledger before its first write (`:500`–`:527`) and retains the downstream writer/check/commit path. `inspect_primary_landing` checks real operation directories through git-path resolution (`scan_clones.py:1165`–`:1212`) and requires affirmative readiness (`:1239`–`:1247`). `prepare_primary_landing` excludes dry/audit/teardown modes, compares the observed OID and re-inspects (`merge_cleanup.py:1151`–`:1163`). R4's decisive red is `R4-delete-without-oid.log:6` (“FAIL: test_rebase_head_moved_after_inspection_is_not_deleted”), against the real moved-ref assertion at matrix `:109`–`:125`.

- **[Pass] Development preservation and fixture scope.** The `442ea913` comparison retains GH-851's bounded pushed-head wait (`merge_cleanup.py:1034`–`:1053`), GH-852 MERGED re-query (`:165`–`:181`), clone retry cleanup (`:298`–`:302`), push-gate timeout (`:89`, `:648`), resume/attempt reservation (`:957`–`:1017`), hold-label skip (`:909`–`:912`), hosted reconciliation and durable landing (`:1113`–`:1124`). The only semantic fixture edits are `isDraft` in the stub (`test/gh534_phase_b_tests.py:78`) and one final mocked refresh (`test/gh436-merge-cleanup.py:557`–`:558`); no added test method in either. Capability rows (`SKILL.md:298`–`:323`), phase-C source and validate.sh are unchanged against the base. A whole-branch changed-path inventory was not available in this no-git envelope, so “nothing else anywhere in test/ is new” remains unverified beyond these supplied paths.

- **[Pass] Supplied green outcomes, with attribution limits.** `G-candidate.log:6`–`:8` reports 26 tests/OK and `:499` says “RESULT: ALL PASS (26 cases)”; `suite-gh436.log:2046`–`:2048` reports 180 tests/OK. The R1/R1b/R2/R3 logs name the intended failing assertions (`R1-no-premerge-draft.log:5`, `R1b-no-post-poll-draft.log:6`, `R2-no-push-boundary-skip.log:5`, `R3-changelog-accepts-history-edit.log:5`). This validates the reported log outcomes, not independent reproduction or the incorrect attribution in F2. **[Unverified — needs clone run]** strengthened F1 evidence and the full harness gate; neither ran here.

- **[Nit] GH-970 wording: location guidance is accurate, chronology is too strong.** `SKILL.md:106`'s sibling scan advice matches the operator decision in [#970](https://github.com/HiQS-Labs/XYZ-forge/issues/970), whose location formula names a sibling of the primary. But #970 is still open and this branch's `start-task` step 3 (`skills/1-hourly/start-task/SKILL.md:78`) only says “a clearly named fresh full clone”; the SOP already shows siblings (`SOP.md:216`) before #970. Prefer “task clones following the GH-970 location decision are siblings…” over “since GH-970 /start-task clones are…”. This needs no scanner change.

- **[Pass] Ratings remain reasonable.** The ledger has `75/70/50/50` for #789 (`releases.sql:730`) and `60/50/50/85` for #965 (`:805`), matching the plan's recurrence/recoverable-stop/neutral-appeal/port-effort rationale. These evidence corrections do not warrant changing those ratings.

Non-mutating AST/log probe for F1/F2, exit **0**; command:
```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
import ast, json, re
from pathlib import Path
root=Path("TESTS-RESULTS/2026-10-05+GH-789")
tree=ast.parse((root/"manual_matrix.py").read_text())
cls=next(n for n in tree.body if isinstance(n,ast.ClassDef) and n.name=="ChangelogMergeCases")
for name in ("conflict","test_draft_at_repaired_push_is_skipped_and_independent_lands"):
 f=next(n for n in cls.body if isinstance(n,ast.FunctionDef) and n.name==name)
 calls=[ast.unparse(n) for n in ast.walk(f) if isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute) and n.func.attr=="branch"]
 print(name, "branch calls:",calls)
rows=[json.loads(l) for l in (root/"provenance.jsonl").read_text().splitlines()]
for r in rows:
 if r["kind"]=="red_control":
  log=(root/r["log"]).read_text()
  print(r["id"],r["sha"],"command present:","command" in r,"collected:",re.findall(r"Ran (\d+) tests",log))
print("red control receipts:",sum(r["kind"]=="red_control" for r in rows))
PY
```
Decisive output:
```text
conflict branch calls: ["self.branch('feat/a', 1, lambda r: edit(r, ChangelogUnitCases.a, 200))", "self.branch('feat/b', 2, lambda r: edit(r, ChangelogUnitCases.b, 201))"]
test_draft_at_repaired_push_is_skipped_and_independent_lands branch calls: []
R0 d62d72e1 command present: False collected: ['25']
R1 d62d72e1 command present: False collected: ['25']
R1b d62d72e1 command present: False collected: ['26']
R2 d62d72e1 command present: False collected: ['25']
R3 d62d72e1 command present: False collected: ['25']
R4 d62d72e1 command present: False collected: ['26']
red control receipts: 6
```

Handing off to Producer (claude-a) — disposition F1/F2, collect the focused clone evidence, and return for round 2. Go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
