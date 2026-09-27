# RELAY · GH-851/852 final QA — merge-cleanup landing resilience (implementation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-851-852-final-qa-merge-cleanup-landing-resilience-implementation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff from base 030ab5ba to HEAD on branch fix/gh851-852-merge-cleanup-network. Files: `skills/2-daily/merge-cleanup/SKILL.md`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`, `test/gh436-merge-cleanup.py`, `test/gh534_phase_a_tests.py`, `test/gh534_phase_b_tests.py`, `CHANGELOG.md`, `TESTS-RESULTS/2026-09-27+GH-851/SUMMARY.md`, `PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet* below (a)–(f). **One round only** (operator, 2026-09-27: minimum ceremony; #854 staging route). A FAIL is adjudicated by the Producer and the operator, not re-reviewed.

## Review packet

**What this is.** This is the final QA on the implementation of #851 and #852, one PR. It is #854's first
direct-path item, and it carries #854 decision D5, the 5400 s hosted-wait default. The plan is
`PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`. Its plan QA (`relay-system/2026-09-27/gh851-852-plan-review.md`)
ran two Codex rounds, then closed by operator-directed adjudication, with every finding accepted into the plan.
Branch `fix/gh851-852-merge-cleanup-network`, based on `030ab5ba`. Review the diff `030ab5ba..HEAD`. **Route:** the operator moved this PR to #854's `staging/stabilize-2026-10` branch. It gets no local full gate (a D2 bypass), and the staging landing gate re-runs it. This review is its D3 per-PR QA receipt.

**Definition of Done: Approved when all of these hold.**
- (a) Each of F1–F5 is implemented as the plan's *Plan* section states, at the lines it names. Nothing is missing, and nothing is added that the plan does not call for.
- (b) The existing subsystem is extended: GH-623 `_net_git` / `_retry_call` / `TRANSIENT_RE`, and GH-736's poll budget. There is no new module, helper family, writer, suite, test case or registry entry (AGENTS.md *No new tests*, GH-831). A new test file or registry entry in the diff is a finding.
- (c) The test edits are exactly the plan's C3 and D1 list: signature-only `**kw` on three `flaky` stubs; `gh436` `_run_main` injecting a MERGED PR, plus the `pr_head` / `merged_head` asserts in the ready-primary test; and `gh534_phase_b` PR 7 made MERGED. The Producer also added `reconcile.assert_called_once()` there, to prove that rc 2 comes from the reconcile and not the new refusal. Judge whether that is within "edit what the test injects" or is scope creep.
- (d) The evidence substantiates the claims. `TESTS-RESULTS/2026-09-27+GH-851/`: `witness.py.txt`, run unchanged at base and at head; `witness/*.jsonl` and logs; `SUMMARY.md`; `provenance.jsonl`; and `focused/`, holding gh436 (180 OK), gh674 (6 OK), gh645 (8 OK) and the Phase-B red control (FAIL `0 != 2`, then restored). Check that each witness would fail if its fix were reverted, and that no log is empty.
- (e) Safety holds. F2 returns True only on GitHub's `MERGED` with a merge-commit oid. F3 fails closed, with zero reconcile calls on OPEN or a read error, and never starts the local writer while the run on H is active. F4 cannot land a head other than the pushed one. The `GIT_HTTP_LOW_SPEED_*` defaults never override an operator's value.
- (f) The docs are truthful: the `SKILL.md` Phase 5 sentence and default, the `emit_pr_merged` docstring, and `CHANGELOG.md`. The ratings in the plan (#851 `55/35/50/85`, #852 `60/45/50/65`) still match the evidence.

**Read these yourself.** `git diff 030ab5ba..HEAD -- skills/ test/`; `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`
(`TRANSIENT_RE`, `execute_pr_merge`, `validate_head_in_second_clone`, `push_resolved_head`, `run_post_merge_reconcile`,
`commit_and_push_phase5_writes`, the post-B1 re-gate in `land_prs`, and `main`'s top and `--reconcile-pr`);
`scan_clones.py` (`classify_local_refs`, `main`); and the plan's *Plan* section.

**Specific questions.**
1. F4: when the refresh inside the head-wait loop returns an error, the code falls through to `_await_mergeable`, which returns the error, and the existing "after resolution the PR reads …" stop fires. Is that the right handling, or should a transient error there defer, as at the other pre-decision sites?
2. F3: `refresh_pr_with_retry` is read before `run_post_merge_reconcile`, and `dry_run` still short-circuits inside it. Is a dry-run `--reconcile-pr` now doing a network read it did not do before, and does that matter?
3. F1: `commit_and_push_phase5_writes` bounds its push at 3600 s. Is there any other caller of `run_git(... "push" ...)` or of `"fetch"` against a remote in these two scripts that is still unbounded? Cite it.

**Operating envelope.** A single-operator developer tool, run from one machine against one GitHub repo. Grade against the
stated requirements and commensurate complexity: surgical changes to one existing script pair. Do not grade against
multi-tenant or adversarial threat models, and do not ask for new infrastructure or new tests.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
