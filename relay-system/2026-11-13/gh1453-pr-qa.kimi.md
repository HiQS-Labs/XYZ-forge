# RELAY · GH-1453 PR 1454 QA (Kimi)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1453-pr-qa.kimi): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: pull request 1454 as pushed, head `e93925f31`, against base `6c0c76bb5` (`development`). In this worktree: `git diff 6c0c76bb5 e93925f31 -- utils/py/jog_run.py skills/2-daily/jog/SKILL.md CHANGELOG.md LESSONS-LEARNED.md` (if git is unavailable to you, read the current files; they are at that head apart from this thread). Product code is one file: `utils/py/jog_run.py`, class `JogCheckpoint` and its two call sites in `jog_run_main`.
- Reviewer: kimi (`kimi-code/k3.1-pro`)   ·   Producer: claude
- Started: 2026-11-13
- You are a **fresh, independent second reviewer**. Codex reviewed the plan and the code earlier (`relay-system/2026-11-13/gh1453-plan-qa.md`, `gh1453-final-qa.md`, `gh1453-text-delta-qa.md`). Do not defer to those threads; read them only after forming your own view, to check whether anything they passed is wrong. Two parts of this PR have had **no** independent review and deserve the most attention: (a) commit `0e8ade643`, which switched three read-only ledger reads in `JogCheckpoint` from `sqlite3.connect(...mode=ro)` to `releases_app.connect(path, readonly=True)` after the gate refused new direct connect sites; (b) the final wording of the skill section "Checkpoint publication (`--checkpoint-root`)" and of the plan doc's "Text review after approval", which were corrected after Codex's last round.
- What the PR claims: a `jog run --checkpoint-root` wake starts from the primary's local state, and at publication reconciles a `development` that moved meanwhile (merge it, take the remote ledger, replay the wake's own `jog-lease` / `jog-<status>` writes read from `op_receipts`, run `utils/releases-merge-resolve.sh`, publish), stopping only with `jog: checkpoint held: <message>` and exit 2. Plan of record: `PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md`. Evidence: `TESTS-RESULTS/2026-11-13+GH-1453/` (`SUMMARY.md`, `candidate-A1-A14.log`, `base-red-controls.log`, `a6-skill-text.log`, driver `fixture-checks.py.txt`).
- Operational envelope: a local developer CLI, one operator per primary clone, other sessions pushing to the same `development`. Grade against the issue's acceptance and commensurate complexity, not enterprise or multi-tenant threat models. The repo forbids new tests, suites or gate machinery (AGENTS.md *No new tests*, GH-831); do not ask for one. You may run narrow read-only probes under `.relay-scratch/`; do not run `validate.sh`, `test/*.sh`, pytest or the fixture driver here, and mark anything that needs them `[Unverified — needs clone run]`.
- Definition of Done: the code does what the PR claims without a path that loses ledger rows, publishes a wrong ledger, or leaves the primary dirty or mid-merge; the skill text is true of the code.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading source or the earlier threads.
Read ONLY the plan doc's `## Plan`, `## Acceptance`, `## Risks`, `## Implementation notes`, `## Text review after approval`, `## Gate-driven change after approval`. Then write at the top of your block: **What this delivers**, **How the existing system works, per this document**, **What it's not**, **Input boundary**.

### Step B: source-backed validation
Read `utils/py/jog_run.py` `JogCheckpoint` in full and `jog_run_main`'s two checkpoint call sites; `utils/py/releases_app.py` `connect` (about line 432), `perform_write`, `jog_acquire_lease`, `jog_set_status`, `_rebuild`; `utils/releases-merge-resolve.sh`; the skill section; the evidence logs and driver. Answer each with `file:line`:

1. **The unreviewed gateway change.** `connect(path, readonly=True)` builds `file:<quoted abspath>?mode=ro`, sets `row_factory = sqlite3.Row`, runs `PRAGMA foreign_keys = ON`, and calls `refuse()` (a `SystemExit`) when the file is missing or the pragma does not take. For each of the three call sites (`_queue`, `_anchor`, `_replay`'s read of the extracted source DB): is behaviour unchanged from a plain read-only connect? Check tuple-unpacking of `sqlite3.Row`, the JSON round-trip of the `queue` snapshot, paths containing spaces or `#`/`?`, and whether a `SystemExit` from `connect` can now escape `_reconcile`'s `except` (which does not catch `SystemExit`) and leave a merge open. If it can, say exactly which call, and whether the recorded-ownership restore on rerun covers it.
2. **Correctness of the reconcile.** Trace `finish()` → `_reconcile()` → `_replay()` → `_push()`. Find any path that (a) publishes the wake's ledger over the remote's without replay, (b) replays the same receipts twice into one ledger, (c) drops a remote row, (d) commits with the primary dirty, (e) leaves `MERGE_HEAD` behind on a handled failure, or (f) lets the journal and `HEAD` disagree after a stop. Give the concrete sequence or say none found.
3. **The overlap rule.** `_replay` compares, for each queue row the wake wrote, the remote row's `(status, attempt_count, failure_reason)` with the values recorded at start. Name a remote change to one of the wake's rows that this comparison misses (for example a change to `position`, `lease_pid`, or a row deleted and re-added with the same three values) and say whether missing it can corrupt the published queue.
4. **Receipt identification.** The wake's writes are the `op_receipts` rows with `id` greater than the anchor row's `id`, in the source commit's database. Can a write made by another process in the same primary during the wake, or a `releases check` recovery, make this set wrong in a way the op whitelist (`lease`, `completed`, `parked`, `failed`, `pending`) does not catch?
5. **Merge ownership.** `finish()` restores an open merge only when `MERGE_HEAD` equals the journal's `merging` and `HEAD` equals the journal's `commit`. Can it abort a merge that is not this wake's, or refuse one that is?
6. **Evidence.** Does each of A1–A14 in `candidate-A1-A14.log` observe the behaviour it names, reading from the right place? Is any red control in `base-red-controls.log` red for an incidental reason? The existing suites were run before the last code changes: is that a real gap for this diff?
7. **Skill text.** Is every sentence of the "Checkpoint publication" section true of the code? In particular the definition of "competing writer" (three cases), the scope sentence about what the closed list does not override, and "At a stop" (start stop versus publication stop). Is any Jog-authored checkpoint stop missing from the list?
8. **Anything the earlier reviews passed that you think is wrong**, and anything over-built for this problem.

Write graded findings (`[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`), each behaviour-change request with `Observed input:`, `Affected scope:`, `Falsifier:`. Then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
