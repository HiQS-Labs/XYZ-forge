# RELAY · GH-1317 frozen pilot plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-01.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh-1317-frozen-pilot-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Read PROJECT/1-INBOX/GH-1317-CODEX-REPAIR-PILOT.md and TESTS-RESULTS/2026-11-01+GH-1317/pilot/CONTRACT.md plus manual-check.py.txt and utils/py/harness.py.
- Reviewer: codex   ·   Producer: supervisor
- Started: 2026-11-01
- Review only, no implementation. Local supervised CLI pilot; no enterprise requirements or new framework. Are source claims accurate, eight approved cases meaningful, fake external boundaries faithful, budgets/ownership adequate and the surgical plan sufficient? Flag concrete blockers with file:line. Do not run cases/tests in this worktree. No paid providers or production reads. Grade against these narrow requirements; do not expand scope.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The surgical adapter plan is supported by source, but the frozen evaluation protocol needs two corrections before actor execution. This is plan review only; no CLI cases or suites ran here.
swept file: yes

- [Pass] Source claims match `utils/py/harness.py:214–218` (strictly `> 3600`), `:243–249` (configured targets bypass the idle shortcut and prompt is reread), `:1016–1028` (init records prompt hash), and `:1443–1446` (reserve, dispatch, settle). A shared due predicate plus an unbilled prompt-mismatch result fits the existing owner and settlement path. Whole-file sweep found no additional production defect requiring expansion of this narrow repair; the protocol defects below are in the seeded manual artifact.

- [Should] Prepare the synthetic local ledger explicitly before v3 init. `manual-check.py.txt:18–25` supplies fake GitHub responses, but `:38–45` goes directly to `--from-prs` with no ledger fixture setup. `harness.py:819–821` copies the supplied repository's actual `releases.db`, and `:860–888` chooses its ranked queue rows and capture docs; fake `issue view` accepts any number. Thus the promised synthetic IDs/frozen local fixture are not established by this protocol. Specify the exact disposable-clone ledger preparation through existing supported mechanisms, hash it, assert the seeded issue/request identity, and reject unexpected fake-gh arguments/IDs. No production source change is needed for this finding.
  Observed input: the v3 tuples at `manual-check.py.txt:37`, the `--from-prs --codex-authoring --limit 1` argv at `:44`, and the only three supplied pilot artifacts (CONTRACT.md, frozen.sha256, manual-check.py.txt); no fixture ledger or preparation command is supplied.
  Affected scope: only v3 setup/cases 5 and 7 in this local pilot.
  Falsifier: show a frozen setup command/fixture that replaces the disposable clone's ledger with the owned synthetic queue before this script runs; the resulting backlog must contain only the specified synthetic request, with no production capture-doc selection.

- [Should] Make the no-call oracle reject unavailable tool execution. `manual-check.py.txt:67–68` ignores tick exit, tick completion, receipts and tool_runs. After settlement, `_run_tool` can fail because sandbox-exec is unavailable (`harness.py:1364–1366`); the persisted decision/event/reservation still satisfy these predicates. Require successful completed idle execution, a completed receipt and verified nonempty output for these cases, and classify infrastructure failure as unavailable. Also retain before/after budget observations promised by the contract rather than only a single reservation's actual_cost.
  Observed input: narrow non-mutating AST-expression probe, command `python3 -B - <<'PY'` parsing manual-check.py.txt, selecting the `ok` expressions at lines 67/68 and evaluating with `n=0, called=False, nocharge=True, dec={'status':'prompt-mismatch'}, tool='idle', tick_rc=1, tick_status='failed', receipts=[], tool_runs=[]`. Exit 0; decisive output: `line 67: failed tick / empty tool_runs => ok=True` and `line 68: failed tick / empty tool_runs => ok=True`. This evaluates only the acceptance expressions; no fixture, CLI or product code was executed.
  Affected scope: not-due and mutated-v2/v3 no-call acceptance, cases 1, 4 and 5.
  Falsifier: the same failed/empty-tool state must produce unavailable/fail; an otherwise identical completed idle tick with valid receipt/output and unchanged spent/remaining must pass.

- [Unverified — needs clone run] Real sandbox execution, seven CLI cases, evaluator-controlled bypass mutation and positive controls remain unexecuted. The contract's two attempts, zero provider spend and absolute stop are explicit (`CONTRACT.md`, “absolute stop 22:37:47Z”); this review does not extend them. If the remaining window cannot cover corrections plus independent evaluation, retain an unavailable/budget-exhausted result.

Handing off to Producer (supervisor) — correct the frozen protocol, disposition both findings, and request the next review turn. Do not start actor repair on this FAIL.

### Producer · Round 2

Both findings verified and Implemented in manual-check.v2.py.txt. Synthetic ledger  [Unverified — no citation]
is initialized/parked through existing CLI into an owned root, substituted only in
the disposable clone, hashed and v3 request identity checked. Fake gh refuses
unexpected issue IDs. All cases now require completed tick/receipt and hash-verified  [Unverified — no citation]
nonempty tool output; no-call cases compare aggregate spending before/after.
Verification: v1 base observed 3 fault cases fail and 4 positive controls pass, but
its acceptance is superseded. v2 base run pending; no actor edit. Freeze revised
contract/helper hashes; preserve v1. Review the v2 artifact in place of v1, no scope
expansion or runtime tests in the relay worktree.

### Reviewer · Round 2

VERDICT: FAIL
Basis: The revised no-call oracle addresses the earlier false-pass path, but synthetic ledger preparation cannot reach initialization as written. No CLI cases, fixtures or suites ran here; this is specification review only.
swept file: yes

- [Blocker] Initialize the owned ledger root as an independent disposable Git repository before using the releases writer. `manual-check.v2.py.txt:37–43` creates only `ledger/` and `.pdda-mode`, then invokes releases init. `releases_app.py:2185–2186` constructs/acquires WriterLock; `:337–342` requires that exact root to resolve a Git common directory. Explicit `--root` does not waive this requirement. Thus the protocol stops before any of its seven cases. Add the owned fixture repository initialization to the frozen preparation (performed by the evaluator in the disposable environment); retain the existing writer and synthetic identity checks. Do not repair production source for this fixture issue.
  Observed input: v2 lines 37–43, a fresh `out/ledger` containing `.pdda-mode` and no `.git`. Narrow non-mutating source-function probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -B - <<'PY'` parsed `utils/py/releases_app.py`, compiled only `git_common_dir` and `state_dir` with `os` and a raising `refuse`, created that directory shape under TMPDIR and called `state_dir`. Exit 0 (refusal caught); decisive output: `rule=not-a-git-repo: cannot resolve the git common-dir for the lock/journal (GH-448); a git checkout is required`. No Git command, writer, fixture executable or product case was executed.
  Affected scope: only v2 synthetic ledger preparation, which currently precedes all cases.
  Falsifier: an owned fixture root with its own valid Git common directory must resolve its lock there, and releases init plus roadmap add must succeed in a disposable clone run; a plain directory must remain refused.

- [Pass] The former failed-tick false-pass expression is removed: v2 `:87` requires zero tick exit, completed tick and receipt, and hash-verified nonempty output; `:88–89` conjoin it with the no-call predicates. Aggregate spending is compared at `:68`, `:75` and `:79`. Synthetic request identity is checked at `:58–60`, and unexpected issue IDs are refused at `:22–23`. These are source-level observations, not runtime acceptance. Whole-file sweep of harness.py, the capture, contract and both protocol versions found no additional production defect requiring expansion of this narrow repair.

- [Unverified — needs clone run] Revised base/candidate cases, real sandbox availability, and independently controlled bypass mutation remain unexecuted. After the fixture correction, re-freeze CONTRACT.md and manual-check.v2.py.txt before actor changes: the current frozen.sha256 still names v1, while CONTRACT.md Revision 2 explicitly requires re-freezing v2. Approval must not extend the existing absolute stop or two-attempt ceiling; exhausted time remains unavailable/budget-exhausted.

Handing off to Producer (supervisor) — correct the owned ledger setup, disposition this finding, and request Round 3 review. Do not start actor repair on this FAIL.

### Producer · Round 3

Implemented the verified fixture-only blocker in manual-check.v3.py.txt: an explicit
/usr/bin/git init -q creates the owned ledger Git root before releases init/add.
Verification: real v3 base CLI run completed, reproduced non-due and both prompt
mutation failures, and passed all four positive controls; all ticks had completed
receipts and verified nonempty output. Retained baseline-v3/ contains raw sanitized
commands, call records, DB-derived state and results. No actor edits yet. The new
frozen.v3.sha256 binds current contract and v3 protocol. Review those as the final
plan input; earlier protocol versions are preserved history, not current acceptance.
No time or attempt extension. Final review round 3 of 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
