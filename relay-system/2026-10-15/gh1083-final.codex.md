# RELAY · GH1083 radar GitHub-first final QA and bounded dry run
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh1083-radar-github-first-final-qa-and-bounded-dry-run): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/3-weekly/radar/SKILL.md**, canonical task plan and retained verification packet.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: all four #1083 requirements met by a minimal skill-only payload, with truthful bounded manual dry-run evidence and post-merge deployment handoff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Producer · Final review and dry-run request

Read all of skills/3-weekly/radar/SKILL.md, the original requirements in TESTS-RESULTS/2026-10-15+GH-1083/issue-source.json and the task plan PROJECT/2-WORKING/GH-1083-RADAR-GITHUB-FIRST.md. Apply the updated instructions yourself to dry-run-input.md and live-facts.json in the same evidence folder. Write a compact A–H decision report in this relay, then compare manual-dry-run.md and provenance.jsonl against your application. Do not execute any full Radar inventory or write either report sink. The cases deliberately combine dated real GitHub facts and explicitly controlled overlays; don't treat overlays as live repo state.

Questions:
1. Is GitHub truly primary across state/kinship/recurrence/closure/reopens/milestones/landed claims, with every doc-derived work fact verified when accessible and stale docs reported as drift? Does the whole skill contain a contradictory doc-wins clause? A resolving link is not kinship, issue closure is not code landing and an open PR is not shipped.
2. Are explicit GitHub RGT declarations, quoted examples, conflicting declarations, adoption counts and doc fallback handled consistently without inferring Transform or dropping the five-bucket sum? Is the CI SOP exception restricted to adopted operating policy, preserving both draft-vs-adopted and newer-adopted-vs-stale-doc directions?
3. Are full/partial GitHub loss and PROJECT-only loss distinct, unknowns honest, and quiet/solved/retirement and sink confirmation boundaries preserved? Source evidence/read-only analysis is not an automatic repair, issue write or deployment.
4. Is the one-Markdown payload minimal and aligned with the approved plan/rating? No new scripts, tests, registry entries, runners or runtime edits. Instructions can be manually exercised but this is not proof of all future model responses.

Plan QA approved with mechanical attestation; existing Codex prerequisite 43/0 in a full helper clone, identity unchanged. Producer manual dry run has eight cases and textual red controls; format validation passes; classifier selects docs tier 1, no full runtime gate. Normal publication docs gate is pending until after final approval. Post-merge Skills Army refresh is explicitly tracked in plan; do not merge or deploy from this turn.

Operational envelope: local advisory skill, human report confirmation preserved. Apply commensurate complexity/ponytail; no speculative API scanner, parser framework or extra gate. Only this relay file writable; no self-commit, git mutations, validate.sh, test/*.sh, pytest, executable fixtures or external writes. Read-only narrow source probes are allowed under reviewer scratch rules. Report concrete findings with file:line evidence, swept file: yes/no, VERDICT: PASS|FAIL|PARKED and Basis. Every behavior-change Should/Blocker needs Observed input / Affected scope / Falsifier.

On approval set STATUS: Approved and NEXT: — and **done RELAY-GH1083-FINAL-20261015 --agent codex** using the env-pinned absolute tick. Never merely release on approval. Otherwise set NEXT: Producer and release to codex-producer. Harness owns the scoped commit. Cumulative cap 3 rounds.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
