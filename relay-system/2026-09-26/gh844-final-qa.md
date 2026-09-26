# RELAY · GH-844 final QA — GH-833 evidence hygiene, and the first hosted Small run recorded
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
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
6. **Commit only the relay file** (`relay(gh844-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh844-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh844-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) #844's acceptance holds: V1b-v2 confines the PRS entry to the glossary section; the witness recipe
    exits non-zero on any unexpected result or unapplied mutation; the non-goal wording is corrected; and the
    recorded runs substantiate this, including the self-test and the "v1 passes the move" gap demonstration;
  - (b) the Small-run records in the GH-831, GH-836 and GH-833 plans match the hosted evidence: run 36276061201,
    its committed receipt, and its `validation.jsonl`. Nothing is overclaimed; in particular, D1 is presented
    as the operator's decision, not taken;
  - (c) the change is docs-only (tier 1), adds no suite, registry entry or code, and keeps the original r0/r1
    evidence unchanged;
  - (d) the #844 ledger row, rating `20/10/50/90` and capture doc follow the repo's lifecycle.

## Review packet

**What this is.** The follow-up to #840. It records the first hosted Small run (GH-831 Phase 3, GH-836 step 6)
and fixes #844 (CodeRabbit's post-merge findings on GH-833's evidence; umbrella #845). The artifact
`.relay-artifacts/gh844-final.diff` is `git diff 241bfcce HEAD`, without the binary `releases.db`. The branch
`fix/gh844-small-run-record` is checked out in this worktree, so read the files whole.

**Operational envelope.** A single-repo local developer harness, and a docs and evidence change. The operator has
ruled "no new tests". Grade against the stated requirements and commensurate complexity. Do not ask for new
suites or automation.

**Read:**
- the artifact;
- `PROJECT/2-WORKING/GH-844-PRS-EVIDENCE-HYGIENE.md`;
- the Status tables and the new Phase 3 results in `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md`, plus
  `GH-836-GATE-HOTSPOTS.md` (Status, D1) and `GH-833-PRS-DEFINITION.md` (Status, non-goals);
- the hosted evidence: `TESTS-RESULTS/2026-09-26+GH-591/wave-9fd2d88543f9f52e2e40b2cb8fc4771b08440ff6/`
  (`provenance.jsonl`, `validation.jsonl`) and `…/wave-b2c307b4e6be45f105b5d1030d75578d91572db2/provenance.jsonl`;
- `TESTS-RESULTS/2026-09-26+GH-833/`: `prs-definition-check-v2.py.txt`, `witness-script-v2.sh.txt`,
  `witnesses-v2.log`, `witnesses-v2-selftest.log` and `provenance.jsonl`, compared with the v1/r1 files.

You may run read-only probes: the checks against `$PWD` (copy `.txt` to a temporary name to execute), a Python
sum of `duration_ms` over the `validation.jsonl` suite events, and
`git diff --no-renames --name-only 241bfcce...HEAD | bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):
1. Does v2's glossary scoping hold for an entry moved outside it, a second entry inside it, and a missing heading?
   Does the recipe's aggregate catch each unexpected outcome?
2. Do the recorded durations and counts (15.7 min gate, 19.2 min job, 73 suites, 76/76, `gh436` 221 s, `gh549`
   159 s, about 12.0 min without `gh436`, and 57.2 and 59.9 min for the full runs) match the evidence?
3. Is anything overclaimed or missing?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
