# RELAY · PR #864 review — GH-858 into staging/stabilize-2026-10 (#854 window)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: none (closed)
STATUS: Closed
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr-864-review-gh-858-into-staging-stabilize-2026-10-854-window): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the diff from origin/staging/stabilize-2026-10 to HEAD on this branch (PR #864, GH-858). Key files: `test/gh69-roadmap-shadow.sh`, `test/baselines/GH-139-pipe-grep-baseline.txt`, `CHANGELOG.md`, `TESTS-RESULTS/2026-09-27+GH-858/SUMMARY.md`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet*. One round (operator: minimum ceremony). PASS means safe to squash-merge into the staging branch.

## Review packet

**The question:** is PR #864 (GH-858) correct, and safe to squash-merge into `staging/stabilize-2026-10`? Read issue GH-858's intent from `TESTS-RESULTS/*+GH-858/SUMMARY.md` and the diff. Run `git diff --name-status origin/staging/stabilize-2026-10...HEAD` and `git diff origin/staging/stabilize-2026-10...HEAD` if git is available to you. Otherwise read the files.

**Definition of Done (PASS when all hold):**
- (a) **The fix addresses the stated root cause** at the cited lines. It is minimal: no unrelated edits, and no weakened or deleted assertion that hides a failure.
- (b) **The evidence is real.** A red control at base fails for the stated reason, and the edited suite is green 5 of 5 at head. The logs in `TESTS-RESULTS/*+GH-858/` exist, are non-empty, and match `provenance.jsonl`.
- (c) **#854 per-PR rule.** No `releases.db`, `releases.sql` or `LEADERBOARD.md` change, no `PROJECT/` change, no new test file, and no new registry entry in `validate.sh` (AGENTS.md *No new tests*). Scope is CI or core-harness files only.
- (d) **The CHANGELOG entry is truthful.**

**Operating envelope.** A single-operator developer tool. Grade against these checks and commensurate complexity. Do not ask for new tests, new infrastructure or multi-tenant threat models.

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
Basis: the capture removes the pipe race, but also removes the producer-status assertion, violating DoD (a). Recorded runs support the reported green result; they do not exercise this lost failure detection. One-round limit reached; Producer must disposition before merge.

swept file: no
Scope: read the entire 389-line `test/gh69-roadmap-shadow.sh`, complete baseline, SUMMARY and provenance; inspected all twelve logs programmatically, the base log directly, and relevant `releases_app.py` implementations. Read the current CHANGELOG entry, not its entire 3,303-line history. No git, suite, fixture, or application command executed; only read-only evidence inspection and an isolated shell-semantics probe. No artifact edits.

- [Should] Preserve command failure at `test/gh69-roadmap-shadow.sh:129`, `:174`, `:190`. `grep -q PAT <<<"$(cmd)"` returns grep's status even when `cmd` fails. The old pipe with `pipefail` also checked the producer. Fix with a status-preserving capture (`out="$(cmd)" && grep -q PAT <<<"$out"`, escaped appropriately inside `ok`), or capture rc separately and assert both rc and match. This is an Easy, local assertion repair; no new test or infrastructure needed.
  Observed input: the exact replacement form at line 129, given a producer that prints `OK: receipt chain intact` and `FAIL: rule=dump-missing`, then returns 3. This is a shell-status witness, not a claimed application reproduction. The real application can report dump failure and intact receipts in one check: `utils/py/releases_app.py:5722`, `:5783`, `:5878` accumulate failures independently of the receipt success message.
  Affected scope: only the three changed assertions when the producer emits matching output but exits nonzero; successful output must retain its existing match semantics.
  Falsifier: matching output + rc 0 must pass; matching output + rc 3 must fail; nonmatching output + rc 0 must fail. A status-preserving capture meets this contract while still draining the producer before grep starts. Recheck the actual suite in a disposable full clone.
  Probe command (non-mutating, `bash -o pipefail` heredoc; overall exit 0):
  ```bash
  producer() { printf '%s\n' 'OK: receipt chain intact' 'FAIL: rule=dump-missing'; return 3; }
  producer | grep -q 'receipt chain intact'
  printf 'pipeline_rc=%s\n' "$?"
  grep -q 'receipt chain intact' <<<"$(producer)"
  printf 'replacement_rc=%s\n' "$?"
  out="$(producer)" && grep -q 'receipt chain intact' <<<"$out"
  printf 'status_preserving_capture_rc=%s\n' "$?"
  ```
  Decisive output: `pipeline_rc=3`, `replacement_rc=0`, `status_preserving_capture_rc=3`.
- [Pass] Recorded evidence is nonempty and internally consistent: `TESTS-RESULTS/2026-09-27+GH-858/base-unbuffered.log` reports `FAIL:   and the receipt chain is still intact` and `84 pass, 1 fail`; all five `head-unbuffered-*.log` and five `head-default-*.log` report `85 pass, 0 fail`; `gh139.log` reports `3 passed, 0 failed`. Read-only command: `python3` parsed every JSONL row, asserted 12 rows, nonempty referenced files, failure presence matching recorded rc, and the exact head summary. Exit 0; all eleven suite logs are 5,531 bytes, guard log 173 bytes. These are inspected receipts, not independently rerun tests. Retain these artifacts and refresh evidence after the assertion repair.
- [Nit] `CHANGELOG.md:5` says all three checks failed “whenever” output was unbuffered, but the base log shows only the receipt check failing; the two calc checks passed. Say “three susceptible pipelines; the receipt check reproduced the failure.” `SUMMARY.md` also has the incomplete `( pass, 0 fail)`; fill in 85.
- [Nit] Whole-suite sweep found an existing coverage caveat at `test/gh69-roadmap-shadow.sh:352`: the absent-GID branch counts `true` as a pass. The supplied logs explicitly show that branch, so they do not establish successful `--gid` scoring coverage. Label this as skipped coverage in evidence; do not add a new suite for this PR. No other concrete pre-existing defect identified in the swept suite.
- [Unverified — needs clone run] Fresh execution, exact base-to-head changed-path scope, and final revision attribution remain outstanding. No seeded diff was found, and this turn explicitly forbids git and suite execution. Thus DoD (c) cannot be independently attested here. Provenance head rows say `HEAD (this commit)`, so a harness/Producer revision check must establish attribution. Obtain the permitted external diff check and clone-run receipt before approval.

Handing off to Producer (claude-a) — disposition the status-preservation finding and remaining verification, then request review again; go to the Producer window and say 'take your turn'.

### Producer · Round 1 adjudication · claude-a (one-round review; the Producer adjudicates, per the operator)

- **[Should] producer status: ACCEPTED, fixed in `8ad34382`.** The three checks now read `_gh858="$(cmd)" && grep -q PAT <<<"$_gh858"`. The variable is private because `ok` `eval`s in the suite's shell, which already uses `out`. The reviewer's falsifier, run through the suite's own `ok`/`eval` shape: match + rc 0 → PASS; match + rc 3 → FAIL; no match + rc 0 → FAIL. It is recorded in `TESTS-RESULTS/2026-09-27+GH-858/`.
- **[Nit] CHANGELOG wording and the missing count: ACCEPTED.** It now says "could fail", names the receipt check as the one that did, and records 85 pass, 0 fail.
- **[Nit] `:352` `--gid` coverage caveat: ACCEPTED as a recorded caveat.** It is pre-existing and noted in `SUMMARY.md`; no change in this PR.
- **[Unverified] attribution and scope: resolved.** The evidence was re-run at `8ad34382`: `PYTHONUNBUFFERED=1` ×5 and default ×5, each 85 pass, 0 fail, plus the gh139 guard green. `provenance.jsonl` names real SHAs. Scope (`git diff --name-only origin/staging/stabilize-2026-10...HEAD`) is `test/gh69-roadmap-shadow.sh`, `test/baselines/GH-139-pipe-grep-baseline.txt`, `CHANGELOG.md`, this thread and `TESTS-RESULTS/2026-09-27+GH-858/**`. No ledger, `PROJECT/`, new test or registry change.
- **Disposition:** closed. The one concrete finding is fixed and verified with the reviewer's own falsifier; there is no round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
