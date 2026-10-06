# RELAY · GH-983 final workhorse continuation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Producer
STATUS: Approved
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

### Reviewer · Round 2

VERDICT: PASS
Basis: The corrected canonical artifact and recorded base comparison resolve Round 1's review-input blocker. All seven questions are satisfied for this instruction-only review; no unresolved Blocker or Should remains. Approval is QA of the reviewed instructions/evidence, not final gate qualification, merge, deployment or runtime configuration authorization.
swept file: yes

- [Pass] Round 1 blocker resolved / question 7: Setup now names the existing canonical `skills/2-daily/workhorse/SKILL.md`. `TESTS-RESULTS/2026-10-06+GH-983/comparison.json` supplies base `8ec99b6066c997a00c40761c9efb9f9caaff8b8f`, reviewed head `138da2757289a14cd78d93d55d2a96f7b1ff1b47`, 21 changed paths, two exact skill hunks, and matching hook/installer base/head hashes; `provenance.jsonl` records its comparison receipt. The source diff replaces checklist/held-queue stopping with the requested completion contract and adjusts document closeout. The inventory contains instruction text and supporting governance, ledger, evidence and relay receipts; no new suite, gate, configuration or unrelated executable source is listed. Accept the furnished inventory as recorded comparison evidence, without claiming an independent git query. A non-mutating `python3 -` probe checked each current hunk span/count and reversed the supplied unified diff in memory; exit 0, decisive output: `reverse_diff_matches_base_provenance=True 635a87774765108297f3de01f3bbfad24e61d36cebfb6c257877ac4893663d2c`. Current canonical SHA256 is `f20c586bd0d16121fdaa5c431aa8fda41dbe220b295df2c91a3e8326c4112472`, matching candidate provenance. Preserve this scope.
- [Pass] Questions 1–2: `skills/2-daily/workhorse/SKILL.md:94–107` resumes authorized actions after subtasks, status, restored credentials and plans/handoffs, binds acceptance evidence to current target/revision, and audits original outcome, steering and unresolved findings. Lines 89–90 and 313–328 prevent parking, checked boxes, held queues and exit zero from discharging required work. Preserve these rules.
- [Pass] Questions 3–4: `skills/2-daily/workhorse/SKILL.md:108–121` requires inventory plus captured service baseline, keeps required quiescence unfinished at 1/1/1, grants no cancellation, finishes independent work before reporting an external blocker, preserves approvals/retry limits/windows, and reports runtime exhaustion truthfully. Rung 5's reconciliation-before-retry at lines 262–280 remains intact. Preserve these boundaries.
- [Pass] Question 5: `skills/2-daily/workhorse/SKILL.md:123–132` distinguishes instruction from runtime enforcement, explicitly requested Goals and configured/trusted Codex hooks from Claude frontmatter. The preserved hook's predicate is `l.lstrip().startswith("- [ ]")` (`stop-hook.sh:39`), so it checks syntax rather than acceptance. Official [Goals documentation](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex) supports idle, budget-bounded continuation and evidence-based completion; official [hooks documentation](https://learn.chatgpt.com/docs/hooks), sections “Where Codex looks for hooks,” “Review and trust hooks,” and “Stop,” supports separate configuration/trust and Stop continuation prompts. Explicit Goal authorization also follows this session's create_goal contract. No runtime hook activation or installation was performed or inferred. Preserve the distinction.
- [Pass] Question 6: `TESTS-RESULTS/2026-10-06+GH-983/SUMMARY.md:3–9`, `cases.json`, both decision outputs and `provenance.jsonl` disclose ten bounded states, both base and candidate passing, and complete/incomplete evidence controls; they claim no causal improvement or guaranteed multi-turn behavior. JSON inspection found ten unique matching IDs per output, only `control_complete` true, and raw event messages equal their corresponding decision JSON. Raw validator output says “Unexpected key(s) in SKILL.md frontmatter: hooks”; metadata projection says “Skill is valid!” PDDA output reports 0 errors/31 warnings and ledger output 0 failures/9 warnings; SUMMARY dispositions acknowledge the unrelated warnings. `gate-identity.json` has equal before/after identity. These are inspected receipts, not rerun gates or executed service operations. Preserve these limits.
- [Pass] Preservation/control probe (questions 5–7): command `python3 -c 'import hashlib,json,pathlib; p=pathlib.Path("TESTS-RESULTS/2026-10-06+GH-983"); c=json.loads((p/"comparison.json").read_text()); print("preserved_hashes_match="+str(all(hashlib.sha256(pathlib.Path(x["path"]).read_bytes()).hexdigest()==x["base_sha256"]==x["head_sha256"] for x in c["preserved"]))); print("completion_controls="+str({s:{d["id"]:d["complete"] for d in json.loads((p/(s+"-decisions.json")).read_text()) if d["id"].startswith("control_")} for s in ["base","candidate"]}))'` exited 0: `preserved_hashes_match=True`; `completion_controls={'base': {'control_complete': True, 'control_incomplete': False}, 'candidate': {'control_complete': True, 'control_incomplete': False}}`. This reads recorded controls, without rerunning their model invocation.
- [Pass] Pending work remains truthful at `PROJECT/2-WORKING/GH-983-CODEX-CONTINUATION.md:18,36–37,49`: reviewed PR, landing and canonical deployment are still unfinished and authorization-bound. Preserve their active state; this review does not discharge them.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, validator, executable fixture or mutation-heavy gate ran here. Earlier receipts attest the named candidate/gate revisions; the harness must qualify the final committed state after this turn. This limitation is expected by the QA envelope and is not an instruction defect.

Whole-file sweep: read all 376 current skill lines, all 51 stop-hook lines, all 58 installer lines, the complete task document and requested evidence, including the supplied full comparison. No additional actionable pre-existing defect was identified within this scope. Graph tools are unavailable in this turn's callable tool inventory, so current direct reads supplied evidence; no fresh graph generation or completeness claim is made. Editing this one relay file is Easy and reversible; earlier log blocks and artifact bytes are preserved. No git command was run and no source/artifact was edited.

Relay closed (Approved), no further review turn needed. Token returns to codex-author for harness commit and the pending final qualification/authorized next steps.


### Attestation · relay-drive — 2026-10-06T20:46:02Z
task: RELAY-gh983-final
reviewer: codex
status: Approved
reviewed-head: 5b6994aaa86df20c40aca015c75267c52cbe01db
added-range: 13470+6531
added-sha256: 328322753614f3323519386cbf65e852d2b7eaab87b6e9392c876ab3a3cd04ea
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
