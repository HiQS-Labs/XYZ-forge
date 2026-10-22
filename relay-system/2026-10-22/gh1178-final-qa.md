# RELAY · GH-1178 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-22.
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
6. **Commit only the relay file** (`relay(gh1178-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff `git diff f243ccfbfb53a2c5d834436ab35cb2d46ab69459 HEAD
  -- utils/py/wave_reconcile.py` (helper `repoint_moved_doc_rows` beside `update_roadmap_entry`,
  `moved_docs` init before the landing loop, record after `validate_and_update_doc`, call before
  "Global roadmap cleanups"). Requirements: https://github.com/HiQS-Labs/XYZ-forge/issues/1178.
- Also read: plan `PROJECT/2-WORKING/GH-1178-WAVE-RECONCILE-SHARED-DOC-REPOINT.md` (Acceptance A1–A5,
  Implementation notes), approved plan QA `relay-system/2026-10-22/gh1178-plan-qa.md`, evidence
  `TESTS-RESULTS/2026-10-22+GH-1178/SUMMARY.md` and its logs (red control, green fixture incl. smoke,
  tier-2 route, gh421/gh454/gh168), `CHANGELOG.md` top entry, ledger row for GH-1178 (`rated 45/50/50/85`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-22
- Operational envelope: local post-merge reconciler CLI, one operator or CI job per repo. Grade against
  #1178's acceptance list and commensurate complexity; no multi-tenant/concurrency threat models. This
  repo forbids new test suites (GH-831): a new `test/` file or registry entry in the diff is a finding;
  do not ask for one.
- Definition of Done (final):
  1. Is each #1178 acceptance item satisfied, with evidence that substantiates it (A1 both rows + raw_text,
     A2 red control, A3 unmoved row untouched, A4 rerun quiet, A5 only `roadmap repoint` via `ledger_write`)?
  2. Does the code match the approved plan? Is the post-plan change (owner row skipped via
     `moved_docs[...][1]`, lazy `releases_app` import) correct — e.g. could skipping the owner row ever
     leave the owner dangling in a real apply (`update_roadmap_entry` :1550-1575 returning early, a
     foreign owner row, a ROADMAP.md-only repo)?
  3. Any duplicate writer or subsystem slipped in? Is the change surgical?
  4. Do the receipts match the committed candidate, and is the rating grounded?
  Cite `file:line` for every claim.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: Ship with conditions: no implementation defect found, but the required sibling-first execution is not exercised by the A1 receipt. Correct the manual evidence before final approval; no production-code change or new suite requested.
swept file: yes

- [Should] A1's “both issue orders” evidence runs the same order twice. TESTS-RESULTS/2026-10-22+GH-1178/probe.py.txt:91-92 reverses the closing clauses, but utils/py/wave_reconcile.py:1060 sorts them before the loop (:2375). Consequently SUMMARY.md:8 and :15 do not establish sibling-before-owner behavior. In the disposable full clone, exercise both actual orders (e.g. a second fixture whose shared doc is named after #422, so sorted #421 is the sibling), retain the base red control, and assert nonempty original and destination embedded paths in both rows' raw_text as well as doc_path. The present assertion (probe.py.txt:95) checks only absence of the old path in #422, not destination presence or #421 raw_text. Refresh logs, summary and provenance through the existing manual-check workflow.
  Observed input: the two closing-clause permutations at probe.py.txt:91, both with owner doc GH-421-fixture.md.
  Affected scope: A1 evidence and its “both orders / both raw_text” claims; no requested runtime behavior change.
  Falsifier: logged actual sibling-first traversal with both nonempty embedded destination paths and both doc_path values correct would close this finding.
  Probe command: PYTHONDONTWRITEBYTECODE=1 python3 - (stdin script parsed wave_reconcile.py with ast, selected only its regex assignments plus _strip_code_blocks/extract_linked_issues, compiled those pure definitions, and printed extract_linked_issues({'title':'fixture','body':body},'test/repo')[0] for the two bodies at probe.py.txt:91). Exit 0; decisive output: each produced [421, 422]. No fixture, git command, or suite executed.
- [Pass] Runtime matches the approved post-loop design: record source/destination after the move (utils/py/wave_reconcile.py:2409-2415), then repair exact source-path matches after all landings (:2476, :1525-1537). It reuses resolve_roadmap_identity and ledger_write → roadmap repoint; that verb replaces both fields (utils/py/releases_app.py:3799-3811). No parallel writer is present in the reviewed helper.
- [Pass] Owner exclusion and lazy import are sound in the reviewed successful apply path. The qualified owner is repointed before any later legacy early return (utils/py/wave_reconcile.py:1577-1579 versus :1595/:1616); missing/foreign/invalid identity (:1564-1566) supplies no eligible owner for this helper either (:1534-1535). Multiple qualified owners abort (:1562-1563) and errors roll back (:2515-2522). A ROADMAP-only repo returns no ledger rows (:1256-1258); placeholder rows return empty before the new import (:1262-1263, :1529-1531). Neither case introduces a newly dangling eligible owner. Dry-run exits before the writer CLI (:1278-1282).
- [Pass] Reviewed producer receipts substantiate the core regression, unmoved row and quiet rerun, subject to A1 above: TESTS-RESULTS/2026-10-22+GH-1178/red-control-f243ccfbf.log:1-9 reports the sibling dangling and exit=1; green-35d965825.log:1-9 reports both doc_path values moved, #500 retained and no rerun repoint, exit=0. The tier2-validate-auto-35d965825.log ends “passed: 19 / 19”; gh421-auto-wave-reconcile-35d965825.log ends “Ran 36 tests … OK”, gh454-reconciler-defects-35d965825.log “Ran 4 tests … OK”, gh168-wave-reconcile-scope-35d965825.log “7 pass, 0 fail”. These are retained receipts, not reviewer reruns.
- [Pass] Provenance integrity: command PYTHONDONTWRITEBYTECODE=1 python3 - (stdin script loaded every row of TESTS-RESULTS/2026-10-22+GH-1178/provenance.jsonl:1-9, asserted nonempty input, and compared each named artifact's SHA-256). Exit 0, output “Receipt hashes: 9/9 match”. All rows name candidate 35d965825404319f198a26c8682171504ea17b6b. Rating 45/50/50/85 matches releases.sql:890 and the recoverable pointer-integrity rationale at PROJECT/2-WORKING/GH-1178-WAVE-RECONCILE-SHARED-DOC-REPOINT.md:97-100; CHANGELOG.md:3-10 describes this scoped repair.
- [Pass] Swept the entire utils/py/wave_reconcile.py:1-2526, including pre-existing preflight, qualification, rollback, legacy handling and regeneration. No additional concrete pre-existing defect found in that sweep.
- [Unverified — needs clone run] Corrected A1 traversal/embedded-path checks must run in a disposable full clone. No validate.sh, test/*.sh, pytest, or executable fixture ran here. Exact committed-diff/receipt-to-current-HEAD equivalence remains for the harness: this reviewer obeyed the prohibition on git commands.

Evidence scope: Verify tier. Graph project XYZ-forge is the primary checkout, generation 2026-09-01T15:54:30Z, not this relay worktree. Graph search returned obsolete line ranges and coverage reported stale source metadata; material source conclusions use direct current-worktree reads instead. Only this relay file changed.

Handing off to Producer (claude-a) — correct the manual evidence in a disposable clone, then return for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
