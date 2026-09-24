# RELAY · GH-736 merge-cleanup exclude-PR and UNKNOWN poll QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh736-merge-cleanup-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (branch `fix/gh736-merge-cleanup-exclude-unknown-poll`, commit `09003de9`; see `git show 09003de9`):
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` — constants `MERGEABLE_POLL_ATTEMPTS` / `MERGEABLE_POLL_S`; the poll before the `UNKNOWN` stop in `land_prs`; the poll + `refresh_pr_with_retry` after a B1 re-fetch; the `--exclude <PR#>` filter in `main()` before `toposort_prs`
  - `test/gh534_phase_b_tests.py` — countdown `force_mergeable` in the gh stub `view()`; `test_unknown_mergeable_stops_before_any_merge`, `test_unknown_mergeable_settles_and_the_pr_lands`, `test_exclude_pr_number_drops_it_from_the_queue`
  - `skills/2-daily/merge-cleanup/SKILL.md` — Phase 1 exclusion bullet, Phase 5 re-fetch bullet, two new capability-table rows
  - `PROJECT/2-WORKING/GH-736-MERGE-CLEANUP-EXCLUDE-PR-AND-UNKNOWN-POLL.md` — capture doc (problem, change, acceptance)
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/736 (items 1 and 2 only; item 3, stacked PRs closed by `--delete-branch`, is out of scope)
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-24
- Operational envelope: a local operator CLI that merges a handful of PRs per run. Keep findings commensurate — no distributed locks, no new subsystems.
- Definition of Done:
  1. **Safety is unchanged:** a PR whose mergeability never settles is still never merged; the run still stops (exit 2) after the bounded poll. No path merges a PR that read `UNKNOWN`.
  2. **The poll is bounded and correct:** at most `MERGEABLE_POLL_ATTEMPTS` sleeps of `MERGEABLE_POLL_S`; a refresh error ends the poll and falls through to the existing handling rather than being retried blindly or masked; `info` is replaced with the fresh read so later decisions (base branch, hold labels, head SHA) use current data.
  3. **`--exclude` semantics:** only bare integers are treated as PR numbers; non-numeric patterns keep their checkout-only meaning; an excluded PR is never sequenced, merged, or made a dependency blocker for others; each exclusion is logged.
  4. **Tests prove it:** the three tests fail on the unfixed script (author ran the negative control: all three red on `development`'s file) and pass on this branch; the shared `run_main` helper is not changed in a way that breaks other suites (the GH-623 resilience tests install their own `_sleep` stub).
  5. **Docs match code:** SKILL.md's Phase 1/Phase 5 text and the two capability rows describe exactly what the code does; `TestParityGuard` stays green.
- Questions for the Reviewer (answer each, citing `file:line`):
  1. In `land_prs`, after the poll ends with an error (`again.get("error")`), what does the code do next — is that the right outcome, or can an errored refresh leave a stale `info` that is then acted on?
  2. Does the post-B1 poll correctly keep the stop condition `info.get("error") or info.get("mergeable") != "MERGEABLE"` (note: `CONFLICTING` must still stop there)?
  3. Where does `--exclude` filtering sit relative to hard-dependency edges? If PR 2 declares `depends on #1` and `--exclude 1` is passed, what happens to PR 2 — is that acceptable, and is it documented?
  4. Could any numeric `--exclude` value that was meant as a checkout pattern (e.g. `--exclude 427` intended for clone `…-gh427`) now also drop PR 427 unexpectedly? Is that the documented intent (SKILL.md example 6)?
  5. Pre-existing code in the same functions you read: any defect you find is in scope — name it, or state that you found none.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
