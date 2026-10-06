# RELAY · GH-983 final workhorse continuation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh-983-final-workhorse-continuation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Final QA envelope and questions

Text-only instruction change, no new tests/gate/configuration. Read the complete skills/2-daily/workhorse/SKILL.md, preserved stop-hook.sh/install.sh, PROJECT/2-WORKING/GH-983-CODEX-CONTINUATION.md, and TESTS-RESULTS/2026-10-06+GH-983/{SUMMARY.md,cases.json,candidate-decisions.json,base-decisions.json,provenance.jsonl,pdda-gate.txt,releases-gate.txt,gate-identity.json}. Compare branch with base 8ec99b6066c997a00c40761c9efb9f9caaff8b8f. Read-only review, no suites/probes with mutations here.

1. Do same-turn subtask/status/auth/plan/handoff continuation and evidence-before-ticking cover the observed failure?
2. Does ending audit original outcome, user steering, acceptance and findings; keep required work active despite parking, checklist exhaustion or exit zero?
3. Are stop conditions, independent work, future deployment window and permission boundaries accurate?
4. Does the operational 1/1/1 active-work regression require inventory and service baseline without granting cancellation?
5. Are native Goals and configured trusted hooks distinguished from Claude skill hook frontmatter? No new unsupported enforcement is installed.
6. Are ten bounded decision fixtures, missing-evidence red control, raw validator incompatibility, base pass and warning dispositions truthfully reported without claiming causal or guaranteed behavior?
7. Is the diff minimal for the requested instruction correction, with no new test/gate machinery or unrelated source changes? Governance/evidence/relay receipts are required supporting scope. Merge and canonical deployment remain unfinished until authorized; do not grade their pending state as implemented.

## Setup
- Artifact under review: **skills/2-daily/workhorse/SKILL.md** — canonical committed file in this reviewer checkout; read it directly, do not edit. No seeded .relay-artifacts path is required.
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-06
- Definition of Done: All seven review questions satisfied by cited current source/evidence; no unresolved blocker or should finding. Review does not authorize merge, deployment, or runtime configuration.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The canonical instruction text and bounded evidence are coherent, but the declared seeded artifact is absent and the required base-to-branch scope/preservation comparison could not be established without git (prohibited this turn). This is a review-input gap, not an observed failure of the continuation instructions. Approval, merge and deployment remain unfinished.
swept file: yes

- [Blocker] Repair the review input before closing final QA. Setup declares `.relay-artifacts/SKILL.md`, but that file does not exist; `.relay-artifacts/` contains only `gh182-claim-guards.md`. Seed the correct workhorse artifact or explicitly correct the envelope to the canonical path, and furnish a read-only base-to-head comparison for `8ec99b6066c997a00c40761c9efb9f9caaff8b8f` including changed-path inventory and preserved hook/installer bytes. Do not change runtime behavior to address this finding.
  Observed input: declared path `.relay-artifacts/SKILL.md`; probe `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -c 'from pathlib import Path; p=Path(".relay-artifacts/SKILL.md"); print("declared_seed_exists=" + str(p.exists())); assert p.is_file(), "declared review artifact missing"'` exited 1: `declared_seed_exists=False`, `AssertionError: declared review artifact missing`.
  Affected scope: this final QA's artifact identity and question 7's base-relative scope/preservation evidence only.
  Falsifier: the declared seeded file exists and equals the candidate hash `f20c586bd0d16121fdaa5c431aa8fda41dbe220b295df2c91a3e8326c4112472`, or an explicitly corrected canonical target plus an inspectable base comparison supplies equivalent identity/scope proof; expect the existence/identity check to pass and no unrelated source/new gate changes.
- [Pass] Questions 1–2: `skills/2-daily/workhorse/SKILL.md:94–107` resumes subtask/status/restored-auth/plan/handoff work, ties evidence to acceptance and revision, and audits original outcome, steering and unresolved findings. Lines 89–90 and 313–328 retain required work despite parking, checklist exhaustion, held queues and exit zero. Preserve these clauses.
- [Pass] Questions 3–4: `skills/2-daily/workhorse/SKILL.md:108–121` requires active-work inventory and service baseline, rejects required quiescence at 1/1/1, denies implied cancellation, finishes independent work before a concrete external blocker, honors windows/permissions/retry limits, and reports runtime exhaustion as unfinished. Preserve these boundaries.
- [Pass] Question 5's instruction/enforcement distinction is explicit at `skills/2-daily/workhorse/SKILL.md:123–132`: “this skill does not install a Codex runtime gate,” Goals require an explicit request, and configured hooks require trust. The retained Claude hook reads only open checkbox syntax (`skills/2-daily/workhorse/stop-hook.sh`, quoted predicate `l.lstrip().startswith("- [ ]")`); it cannot attest acceptance. This is textual review, not firsthand activation or verification of Codex runtime hooks.
- [Pass] Question 6: `TESTS-RESULTS/2026-10-06+GH-983/SUMMARY.md:3–9` truthfully reports both base and candidate passing ten bounded decisions, missing-evidence control, raw validator incompatibility and projection pass, 31 PDDA and 9 ledger warnings, intact clone identity, and no causal/reliability guarantee. `cases.json` supplies concrete states; both decision outputs reject all completion except `control_complete`, including `control_incomplete`. A read-only `python3 -` JSON/hash probe (exit 0) found `cases=10`, `candidate_provenance_hash_matches=True`, both raw event messages equal their respective decision JSON, and `identity_bracket_equal=True`. The canonical skill SHA256 equals the candidate provenance hash above. `raw-validate.txt` says “Unexpected key(s) in SKILL.md frontmatter: hooks”; projection output says “Skill is valid!” These are inspected recorded results, not rerun gates or an executed operational regression.
- [Pass] Pending state is truthful at `PROJECT/2-WORKING/GH-983-CODEX-CONTINUATION.md:18,36–37,49`: PR review, merge and canonical deployment remain unfinished and subject to authorization. The review does not authorize them.
- [Unverified — needs clone run] No validation suite, executable fixture, pytest, validator or gate was executed here. Recorded receipts name earlier candidate/gate revisions in `provenance.jsonl`; the harness must qualify the final committed state after this turn. Base-relative minimality and hook/installer byte preservation remain unverified pending the comparison requested above.

Whole-file sweep: read all 376 lines of the canonical SKILL.md, all 51 hook lines, all 58 installer lines, the full task document and the complete requested evidence files. No additional actionable pre-existing defect was identified within this instruction-only scope. The missing declared seed prevents claiming a sweep of that artifact. Graph Verify-tier lookup found no indexed project for this worktree; nearest XYZ-forge is another checkout, generation `2026-09-01T15:54:30Z`; coverage reports skill files not_tracked and new evidence missing. Current direct source supplied the evidence; no graph completeness claim is made. No git command or source/artifact edit was performed.

Handing off to Producer (codex-author) — repair the review-input gap and supply the base comparison, then go to the Producer window and say 'take your turn'.

### Producer · Round 2

Disposition: Implemented (review input only). Corrected Setup to the canonical skills/2-daily/workhorse/SKILL.md path already read by Round 1; no absent seeded artifact is claimed. Added TESTS-RESULTS/2026-10-06+GH-983/comparison.json with base/head identity, complete changed-path inventory, exact skill diff and matching base/current hook+installer hashes. Only instruction source changed; no new test or gate file. The canonical skill hash remains f20c586bd0d16121fdaa5c431aa8fda41dbe220b295df2c91a3e8326c4112472. All Round 1 Pass clauses are preserved. Qualify final committed state through pre-push after approval. Please re-review the repaired input and question 7; read full current artifact/comparison and retain no-guarantee validation limits. Handing off to Reviewer (codex).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
