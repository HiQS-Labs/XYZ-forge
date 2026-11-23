# RELAY · GH-1498 CodeRabbit delta QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1498-coderabbit-delta-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/pr-minder/scripts/pr_minder.py** (review the diff `git diff 1ab49bc05..72bfb6348`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the post-approval delta `1ab49bc05..72bfb6348` correctly implements the accepted CodeRabbit findings on PR #1510, adds no regression to the approved behaviour, and the three declines are sound for the envelope.

## Context and questions

Codex approved the full change at `d03e81fcc` (`relay-system/2026-11-16/gh1498-final-qa.md`) and agy at `f8ecd37d7`. CodeRabbit then left 10 findings on PR #1510.

**Operational envelope:** a manual local CLI, one operator, one repo, about 12–50 PRs. The repo forbids new tests (GH-831). Review only `git diff 1ab49bc05..72bfb6348`, plus the code it touches.

**Accepted and implemented** (`skills/2-daily/pr-minder/scripts/pr_minder.py`):
1. Threshold validation (`--stale-days` must be 1–6, draft ≥ stale, drift ≥ 0).
2. `behind` is now also derived from measured drift when GitHub reports CLEAN.
3. The repair command uses `shlex.quote` for branch names.
4. Add-label is dropped when the refreshed labels already contain the label, so it is neither re-added nor owned.
5. A draft-status change aborts the write.
6. Receipt `head_after` OIDs are no longer trusted as maintenance syncs. The structural predicate alone decides, because an author push between update-branch and the re-read would otherwise be hidden.
7. Plan output now lists owned-label removals.

Evidence: A17 (with a bad candidate) and A18 in `TESTS-RESULTS/2026-11-16+GH-1498/manual-check.log`, 21/21 total. Smoke re-recorded at `2edec37f6`.

**Declined** (please challenge if wrong):
- **(a) Provenance for reviewer probes.** The probes ran inside the reviewer's throwaway worktree, and their command, exit status and output are quoted in the committed relay threads. They aren't PR evidence runs.
- **(b) A repo-scoped apply lock.** The plan and every prior review excluded locks for a manually invoked single-operator tool. The cost of a race is a duplicate comment, which a later pass PATCHes.
- **(c) Treat any truncated `commits(last:10)` as unknown.** That would make every PR with more than 10 commits unknown, which means no writes for exactly the long-running PRs this tool targets. Commits come in history order, and the missed case needs a committer date later than the 10 newest history commits (a forged or skewed clock).

Answer, citing `file:line`:
1. Is each accepted fix correct and complete? Any regression, for example the drift-derived `behind` now driving update-branch for PRs that a stale-but-clean status previously skipped?
2. Are the three declines sound? Grade a decline wrong only with an observed input that fails, per the falsifier rule.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (codex)

VERDICT: PASS
Basis: Ship within the stated manual, single-operator envelope. All seven accepted fixes are implemented coherently, and no observed failing input establishes that a declined change is required. This is implementation approval; final-head gate qualification remains the harness's work.
swept file: yes

Evidence boundary: read the whole current pr_minder.py, the exact source delta 1ab49bc05..72bfb6348, the relevant planner clock/query and merge-cleanup refresh seams, A17/A18 driver text and recorded results/provenance, and the prior final-QA relay. No additional pre-existing defect was established in this bounded sweep. Verify-tier discovery returned all 86 projects, none for this worktree; XYZ-forge generation 2026-09-01T15:54:30Z returned zero script symbols (has_more=false), with coverage missing/not-tracked for the three Python paths. Current source supplies the evidence; no freshness claim rests on that index. No Git executable, network call, full gate, suite, pytest, or executable fixture was run.

- [Pass] **Validation and measured behind status are correct for the accepted ladder.** pr_minder.py:455–457 rejects stale outside 1–6, draft below stale, and negative drift before repository I/O. The drift-derived predicate (:203–205) reaches the existing precedence and rung guards (:253–262,267–273,277–318): a CLEAN-but-behind PR now receives the intended update at rungs 1–2; fresh and retire rows do not, and rung 3 asks for a decision. Draft/fork/cap skips and conflict/failing precedence remain. This is the intentional repair of the prior CLEAN omission, not an unrestricted update policy. A17 specifically exercises the CLEAN input and rejects the state-only candidate (manual_check.py.txt:666–685).

- [Pass] **Quoting, ownership, draft refresh and removal reporting are coherent.** Both branch arguments use shlex.quote (pr_minder.py:282–285). The removal list is computed from current labels plus successful ownership receipts (:90–100,237–245), consumed directly by apply (:342), and rendered by describe (:434–441). Refreshed existing labels filter add-label operations before intent/result writes (:380–389), so this pass does not acquire ownership of the other actor's addition. Both draft-status transitions abort before writes (:369–379), using the existing refresh field (merge_cleanup.py:505–506). The accepted once-per-bundle refresh window remains unchanged.

- [Pass] **Receipt OIDs no longer suppress an author push.** assess passes an empty sync-OID set into both author_activity and own-commit filtering (pr_minder.py:172–175,183,190–193). The structural maintenance predicate remains the existing two-parent/default-headline/GitHub-committer rule (planner_core.py:1283–1290). A captured head_after equal to a subsequent ordinary author commit therefore cannot erase that activity; the receipt continues to feed the separate update cap (:102–111).

  Independent bounded probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (inline imports the real script, disables subprocess.run, replaces holds/drift/refresh/GitHub operations with in-memory functions and receipts, constructs the cases above, and calls assess, plan_bundle, describe, apply_row and invalid-argument main paths). Exit **0**. Decisive output: `CLEAN age 1 rung 0 update False`; `CLEAN age 4 rung 1 update True`; `CLEAN age 8 rung 2 update True`; `CLEAN age 15 rung 3 update False`; `CLEAN age 31 rung 4 update False`; `draft/conflict/failure precedence preserved`; `refreshed existing label: add-label calls=0 ownership receipts=0`; `both draft flips: write calls=0; aborted=draft status changed`; `owned removal: plan and description contain pr-minder:stale`; `repair branch arguments are shell quoted`; `receipt head_after=author: rung=0 latest author commit retained`; `invalid threshold cases=4 all rc=2 before I/O`; `all bounded assertions passed; real subprocesses disabled`.

- [Pass] **The three declines are acceptable within the declared envelope.** (a) Reviewer probes are retained as command/status/decisive-output quotations in the relay, as in gh1498-final-qa.md's Round 3 block and this block; they are distinct from the producer's evidence runs, which have provenance.jsonl entries. This turn follows the operator's explicit scratch-and-quote protocol. (b) With serial invocation by one operator, no concrete overlapping-run failure was supplied or observed that requires a lock. Existing comments are found and PATCHed (pr_minder.py:327–330,345–350,424–427), and cap receipts remain (:102–111,304–305). This acceptance depends on serial invocation; it does not prove concurrent apply safe. (c) The bounded clock already reports unknown when a truncated connection contains no qualifying item (planner_core.py:1313–1319); making every truncated commit connection unknown would disable writes for ordinary longer histories despite a visible qualifying commit. No observed out-of-order-date input in this task demonstrates a necessary change. The decline is a proportional acceptance of the history-order/date assumption, not proof that commit dates must be monotonic or that only deliberate forgery can violate it. No blanket completeness guarantee is asserted.

- [Pass] **Exact delta and seed identity checked without Git execution.** Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (read-only stdlib query of the parent's loose/packed Git objects, resolves both named commits' script blobs, asserts the candidate blob equals the seeded file, then prints difflib.unified_diff). Exit **0**; decisive output: `Seed equals 72bfb6348 blob. Exact source delta:` followed by the seven accepted changes and no other script change. An initial loose-only query exited **1** because the base object was packed; the successful packed-object query supersedes that incomplete extraction. Nothing was written to object storage, refs or index.

- [Unverified — needs clone run] **Delivery qualification remains separate.** manual-check.log records 21 passed / 0 failed, A17's rejected candidate and A18's five true parts; provenance.jsonl:10–11 binds manual/smoke evidence to 2edec37f6. These are inspected recorded results, not a rerun here. A18 has no bad implementation candidate, as its driver explicitly records. The last retained gate receipt (:9) is f8ecd37d7, before this delta. The harness must run and retain its final-head gate before claiming delivery/merge readiness.

Relay closed (Approved), no further turn needed. The harness owns the relay-file commit and subsequent gate; the token is closed with done.


### Attestation · relay-drive — 2026-11-17T05:42:29Z
task: RELAY-gh1498-coderabbit-delta
reviewer: codex
status: Approved
reviewed-head: 5212965c25ce31952b0e1f6940c256510dd618bb
added-range: 8213+6733
added-sha256: 5b2245928b2c0b288481a74b2cee3004f38f37fd2c743e5cc4ecb3ef310ecfd8
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
