# RELAY · GH-1527 Final QA: kickstart build_queue.py
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1527-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/kickstart/scripts/build_queue.py`, `skills/1-hourly/kickstart/SKILL.md`, `TESTS-RESULTS/2026-11-19+GH-1527/manual-check.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-19
- Definition of Done: the approved plan `PROJECT/2-WORKING/GH-1527-KICKSTART-BUILD-QUEUE.md`
  (Codex-approved in `relay-system/2026-11-19/gh1527-plan-qa.md`) and issue #1527's requirements.

Operational envelope: local, operator-invoked stdlib Python CLI that prints Markdown; read-only
except `--out`. Commensurate machinery only. XYZ-forge forbids new test suites (AGENTS.md, GH-831):
a new `test/` file or validate.sh entry in the diff is a finding; evidence is the manual check.
Diff: `git diff ad22311e8..HEAD`.

Questions (cite `file:line`):

1. Does `build_queue.py` implement the plan's PR rules 1–8 and issue rules 1–9 exactly, first match
   wins, in that order? Any rule missing, reordered or able to drop an item silently?
2. Does it reuse pr_minder for PR state, adding only author, links and raw `mergeable` from one
   gh call? Any second classifier?
3. Determinism: with the saved inputs and flags, can output vary (set ordering, wall clock,
   dict order)? The receipt records `cmp` exit 0 — is that claim consistent with the code?
4. You MAY run the script read-only against the committed saved inputs under `.relay-scratch/`
   (command is in manual-check.md; use `--out .relay-scratch/q.md`) and compare with
   `TESTS-RESULTS/2026-11-19+GH-1527/queue-replay-1.md`. Quote the command and result.
5. What prevents an unchanged, unfixed candidate from being reported delivered? Does the receipt's
   hand-queue diff explain every difference, and does the red control show the assertion rejecting
   a wrong output?
6. Does kickstart SKILL.md's new parent step 2 state the same closed ordering as the script
   docstring, and keep the parent's authority boundary (step 8)?
7. Anything over-built, or a new test/gate in the diff?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, and set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

- [Should] **S1 — make the live collection path honor the read-only envelope.** `build_queue.py:203–204` invokes pr_minder's full CLI. That CLI calls `conflict_files` before its JSON return (`skills/2-daily/pr-minder/scripts/pr_minder.py:530–542`); `conflict_files` performs two `git fetch` operations and `git merge-tree --write-tree` (`:164–172`). These write refs/FETCH_HEAD/objects in the target checkout even without `--out`. The queue does not consume conflict-file details. Reuse pr_minder's classification through a narrowly read-only collection option/path that skips these details, rather than duplicating its classifier; retain manual evidence that this branch does not invoke Git mutations. Merely revising the “Read-only: writes nothing but --out” promise (`build_queue.py:28`) would not satisfy this relay's operational envelope.
  Observed input: committed `inputs/pr_minder.json` row #1417 has `conflicting: true`, `rung: 3`, `held: null`, `unknown: false`, and non-null `plan.comment`; the same fetch predicate is true for #1391, #1460, #1467, #1471, #1497 and #1501. Read-only probe (exit 0): `python3 -c 'import json; from pathlib import Path; rows=json.loads(Path("TESTS-RESULTS/2026-11-19+GH-1527/inputs/pr_minder.json").read_text()); print([r["pr"] for r in rows if r["conflicting"] and r["plan"].get("comment") is not None])'` yields `[1391, 1417, 1460, 1467, 1471, 1497, 1501]`. This establishes concrete inputs to the source-backed write path; I did not execute those writes.
  Affected scope: live runs containing conflicting PRs with a planned comment; saved-input replay does not invoke this path.
  Falsifier: feed the saved #1417 classification/metadata through the live collector with subprocess calls recorded safely; expect unchanged queue routing and zero `fetch` / `merge-tree --write-tree` calls. A pre-existing option that already suppresses the calls on this invocation would invalidate the finding; the current argv contains only `--json --repo-root`.

- [Pass] **Ordered routing and reuse:** `build_queue.py:81–132` implements the PR/issue precedence and conservative fallback; `:149–174` emits A, B, C, D, E, F, G, H, final QA. PR state flags come from pr_minder, with author/link/raw mergeability enrichment at `:203–210`. Explicit overrides precede folding (`:112–117`); `:216–218` excludes operator-held issues from folded mentions. No additional classifier defect found during the whole-file sweep.

- [Pass] **Deterministic replay reproduced:** command `python3 skills/1-hourly/kickstart/scripts/build_queue.py --as-of 2026-11-19 --owner noelsaw1 --other-session 1400,1418 --needs-operator 1435,1427 --prs-json TESTS-RESULTS/2026-11-19+GH-1527/inputs/pr_minder.json --pr-meta-json TESTS-RESULTS/2026-11-19+GH-1527/inputs/pr_meta.json --issues-json TESTS-RESULTS/2026-11-19+GH-1527/inputs/issues.json --out .relay-scratch/q.md`, then `cmp .relay-scratch/q.md TESTS-RESULTS/2026-11-19+GH-1527/queue-replay-1.md`: exit 0, no output. Sorting and the pinned cutoff (`build_queue.py:79,111,176,197`) are consistent with this result; the supplied date prevents wall-clock dependence.

- [Pass] **Acceptance evidence rejects wrong routing:** `TESTS-RESULTS/2026-11-19+GH-1527/manual-check.md`, quoted receipt: `#1417 want=needs in_queue=True in_needs=True -> FAIL`, exit 1. Independently evaluated its section-membership predicate against the retained outputs: held #1417, non-owner #1460, both #1526 overrides and the clean #1526 control each produced assertion result 0; `routing/out-red-control.md` produced assertion result 1 (`in_queue=True in_needs=True`). The read-only Python inspection itself exited 0. All retained provenance artifact byte counts and SHA-256 values matched a direct file scan (exit 0, “receipt scan complete”). The hand-queue comparison table explains its listed differences by snapshot drift or explicit rules, including held #1024, #1517's narrowed sweep rule and operator-decision #1518. The original hand queue is local-only, so its completeness cannot be independently re-diffed here. This evidence supports routing/replay, not an unexecuted full gate.

- [Pass] **Parent integration and authority:** `skills/1-hourly/kickstart/SKILL.md:33–42` states the queue order and records the grant before dispatch; `:59–60` retains separate authorization for merges, deploys and installed-skill updates. The generated template explicitly says “Status: NOT YET GRANTED” (`build_queue.py:48`), so printing it does not grant authority. The implementation is a bounded stdlib CLI, with no scheduler or ledger writer (`build_queue.py:30–38,182–229`).

**Review limits:** Read the entire three seeded artifacts, approved plan and prior plan QA, plus pr_minder's collection/classification/JSON path. No additional pre-existing defect found in the seeded files beyond S1's inherited callee effect. No git command, gate, test suite, fixture, or live collector was executed. Consequently the actual base-to-head changed-file list and full-gate status are unverified here; no claim that a later gate will run or that the diff contains no new suite is made. Verify-tier graph discovery found pr_minder main/conflict_files with no pagination remaining, but the reference graph belongs to another checkout (generation 2026-11-18T19:39:07Z); coverage reports missing freshness for all three seeded artifacts. Exact local source reads govern this review. A clean graph coverage signal is not completeness proof.

swept file: yes
VERDICT: FAIL
Basis: Saved-input routing and replay meet the bounded plan, but the default live path violates the explicitly read-only operational envelope through pr_minder's conflict-detail Git writes. Resolve S1 before approval.

Handing off to Producer (claude-a) — disposition S1 and supply focused read-only collection evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
