# RELAY · GH-1010 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-1010-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1010-MERGE-HISTORY-POLICY.md
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-09
- Definition of Done: Grounded, minimal plan satisfying the GH-1010 requirements and current AGENTS verification policy.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Review packet

Read PROJECT/2-WORKING/GH-1010-MERGE-HISTORY-POLICY.md and its linked recon, then the referenced
merge_cleanup.py strategy/landing paths and both skill consumers. Plan review only; no code edits.
Local developer CLI, one project at a time. Require commensurate complexity; no new tests/suites
under current AGENTS, speculative frameworks, or unrelated pre-existing repairs.

1. Does the plan satisfy maintainer opt-in, original commit preservation, both cleanup consumers,
   and unchanged existing repo behavior without hosting mutations?
2. Are all entry points and refusal paths grounded; does the shared reporter avoid a second parser?
3. Are adoption semantics, historical squash handling, rollback and manual falsifiers sufficient?
4. Are ratings grounded with neutral appeal and no invented recurrence or overrides?

Append your review, set STATUS Approved on PASS or return findings. Tests are not authorized in
this worktree. Reviewer edits only this relay file; do not commit/push (the shim owns commits).

### Reviewer · Round 1

VERDICT: PASS
Basis: The plan is sufficiently grounded and bounded for implementation: one existing merge writer, one policy reader shared by both consumers, explicit adoption, backward-compatible default, and clone-isolated verification. This approves the plan, not runtime behavior.
swept file: yes

- [Pass] Opt-in and compatibility are explicit at `PROJECT/2-WORKING/GH-1010-MERGE-HISTORY-POLICY.md:44–63`: strict boolean, omitted versus explicit strategy, no hosting mutation/fallback, maintainer-selected adoption, and no automatic propagation to existing projects. Current seams are `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:150` (writer), `:854` (landing loop), and `:1182` (CLI default).
- [Pass] The shared read-only reporter and target-primary selection (`plan:50–51,95–96`) avoid a second parser. Historical squash stays valid and ancestry stays distinct from content (`plan:57–60`), matching the deep skill's Phase 3 evidence distinction. Disabling policy affects future merges only (`plan:67–71`).
- [Pass] Verification is commensurate with current AGENTS: existing focused suite, manual policy matrix, nonempty output, identity checks, enforcement-removal red control restored from a copy, committed provenance, bounded independent QA and disposable-clone gates (`plan:89–122`). No new test suite or gate machinery is proposed.
- [Pass] Ratings are neutral about appeal and recurrence (`plan:77–83`). Read-only command `rg -n 'GH-1010|rated 65/55/50/75' releases.sql` exited 0; decisive output at `releases.sql:837` contains ratings `65,55,50,75` and `rating_ovr=NULL`. The issue-search completeness claim remains the producer's bounded observation, not independent recurrence evidence.
- [Nit] Correct the recon's location for `land_prs`: it is `merge_cleanup.py:854`, not 1098 (1098 is its writer call). Also distinguish caller-owned documentation parking (cleanup SKILL, “Committed documentation parking — caller-owned before executing Phase 0”) from Python Phase 0 preparation. The proposed ordering is sound, but the prose currently blurs the two. Cheapest fix: citation/prose correction during implementation; no new mechanism.
- [Unverified — needs clone run] No suites, executable fixtures or live merges ran this turn. Implementation behavior and negative controls remain Phase 2 obligations. `gh issue view 1010 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1 with `error connecting to api.github.com`; review therefore uses the seeded requirements packet, not a independently refreshed issue body. Graph indexing was denied by tool approval policy; cited source was read directly.

The complete plan and linked recon were reviewed, along with the referenced merge strategy/landing paths, both consumer skills, deep agent template and adoption guidance. No other in-scope pre-existing plan defects found; unrelated consumer repairs are outside this plan review.

Relay closed (Approved), no further turn needed. Producer may proceed with implementation and the specified clone-run verification.


### Attestation · relay-drive — 2026-10-09T19:07:16Z
task: RELAY-gh1010-plan
reviewer: codex
status: Approved
reviewed-head: eb8a32455ef3ef20544dec962c1f78b782edd49e
added-range: 6270+3088
added-sha256: 4e846b5975c38f7303ba7c5936d97443a0dd6e7d7bae0e70b9e51f63a6e5b352
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
