# RELAY · GH-1088 final QA — start-task orchestrator smoke check (step 7) before final relay QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
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
6. **Commit only the relay file** (`relay(gh1088-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed change on this branch versus `d48aa774`, mainly `skills/1-hourly/start-task/SKILL.md` (recite item 4 at L52, the step 7 smoke paragraph at ≈L252-264, step 8's evidence list at ≈L267-268), plus `CHANGELOG.md`.
- Plan (Approved in plan QA round 1): `PROJECT/2-WORKING/GH-1088-START-TASK-SMOKE-CHECK.md`; plan thread `relay-system/2026-10-15/gh1088-plan-qa.md`.
- Evidence: `TESTS-RESULTS/2026-10-15+GH-1088/` (`smoke-receipt.md`, `gh609.log`, `pdda-run.log`, `provenance.jsonl`).
- Requirements: GitHub issue #1088.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-15
- **Operational envelope:** an instruction-only edit to one skill file. Grade against #1088 and commensurate complexity. Do **not** ask for new suites, guards, runners or scripts (GH-831), or for enterprise process machinery.
- **Definition of Done — answer each with file:line evidence:**
  1. Does the edit satisfy each #1088 requirement: main path plus one adjacent path, a manual-check receipt with provenance, handed to the final reviewer, the docs-only variant, failure means fix before QA, and never counts as the independent review?
  2. Does the actual diff match the approved plan (placement, single file plus CHANGELOG and evidence; no other skills touched)? Did anything slip in beyond scope?
  3. Is the wording unambiguous to an agent following start-task in order, and does it avoid conflicting with step 6's no-self-review rule and step 7's existing gate and isolation rules?
  4. Do the checks substantiate the claims (gh609 33/0, PDDA no errors, docs route, smoke receipt)? Is there any new test file or registry entry (a finding under GH-831)?
  5. Does the persisted rating (55/45/50/85) still match the evidence?
  6. Any pre-existing defect in the touched steps that this edit makes wrong.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the bounded instruction change against the approved requirements. No blocker or should finding. Reversibility: Easy; remove the added instruction and evidence-list wording. Approval is independent artifact QA, not an attestation that the later harness/publication gate ran.
swept file: yes

- [Pass] **DoD 1 — requirement coverage.** Read the entire start-task skill, including pre-existing instructions (lines 1–409). `skills/1-hourly/start-task/SKILL.md:52,252–264` covers main plus adjacent operator paths, commands/output/verdict in a manual receipt with provenance, docs-only consumer reading or a reasoned skip, fixing/recording a blocker before QA, and the explicit “never replaces or counts as the independent review” boundary. Step 8 receives the receipt at `:266–268`. This matches the approved plan's Requirements; no extra mechanism is needed.
- [Pass] **DoD 2 — committed scope and plan.** Read-only object inspection, without invoking git: `python3 "$TMPDIR/read_objects.py"` exited 0; decisive output: `BASE d48aa774dc1e22fbab393a9324057b8acff47d4b HEAD e844c747370fa359923ed7ce13d5e1bce00fa299 CHANGED 11` and `All changed working files match committed objects.` The script decoded local loose/packed objects and compared recursive trees and working-file bytes. The skill diff has exactly recitation item 4, the step 7 paragraph, and the step 8 receipt addition; CHANGELOG adds only the GH-1088 entry (`CHANGELOG.md:3–11`). The other nine paths are the canonical plan, four evidence files, two relay threads, and the required ledger DB/dump. A second read-only SQL-diff probe exited 0: only generation metadata, the GH-1088 roadmap row, and its add/rate/repoint/update receipts/events changed. These are task-governance support, not another skill/runtime change. No new test file, runner, registry entry or unrelated skill appears in the complete 11-path list.
- [Pass] **DoD 3 and 6 — ordered instructions and existing boundaries.** Skill `:247–251` preserves full-clone isolation, identity checking and honest failed/skipped results; `:258` expressly applies that isolation to mutating smoke runs. The new work occurs before final QA (`:252,260–261`), and the receipt is evidence rather than self-review (`:262,266–268,276–283`), consistent with step 6 at `:211–214`. No pre-existing defect in the touched steps was found that this edit makes wrong. Historical CHANGELOG entries were not re-audited as independent runtime claims; the new entry matches the skill.
- [Pass] **DoD 4 — source/evidence and falsifiability.** `TESTS-RESULTS/2026-10-15+GH-1088/smoke-receipt.md:6–20` records the docs consumer walk; `:22–29` explicitly identifies installed-copy deployment as pending, not implemented here. `gh609.log:3,9,25,35` records the 31,359-byte skill, accepted start-task contract, a rejected mutated control, and 33 pass / 0 fail. `pdda-run.log:182` says “no errors, 47 warning(s)”; this is not a warning-free claim. `provenance.jsonl:1–3` is present in the committed object tree and references the retained receipt/logs. A narrow `python3 -` probe reading those files and JSON (no fixture execution) exited 0: `Step 8 nonempty; smoke receipt in final-review packet: True`, `skill bytes 31359`, and `provenance: 3 valid records; all referenced artifacts nonempty`. This is the positive counterpart to the approved plan relay's recorded baseline red control (“Step 8 nonempty; smoke receipt in final-review packet: False”, exit 1).
- [Pass] **DoD 4 — actual docs route.** Probe `printf '%s\n' <the complete 11 changed paths listed above> | bash utils/ci-route.sh pull_request` exited 0 with `docs_only=true`, `pdda_needed=true`, `full_required=false`, `route=docs`, `tier=1`, and empty `changed_tests`. This substantiates the docs gate choice in `PROJECT/2-WORKING/GH-1088-START-TASK-SMOKE-CHECK.md:98–103`; no full runtime gate is claimed for this turn.
- [Pass] **DoD 5 — persisted rating.** Read-only SQLite probe used `sqlite3.connect(Path('releases.db').resolve().as_uri()+'?mode=ro&immutable=1', uri=True)` and `select gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr,doc_path from roadmap_items where gh_number='1088'`; it returned `(1088, 55, 45, 50, 85, None, 'PROJECT/2-WORKING/GH-1088-START-TASK-SMOKE-CHECK.md')`. The same values appear in `releases.sql:863`; plan `:107–115` retains the rationale, neutral appeal and unknown trend. The small instruction diff supplies no reason to change those judgments.
- [Unverified — needs clone run] No suite, pytest, executable fixture or git command ran here. Gate results above describe committed producer receipts, whose provenance labels `42d9b092+uncommitted GH-1088 edit (committed next)`, not a fresh final-HEAD gate. The later harness/publication phase must retain its required final-revision evidence. Live issue re-fetch `gh issue view 1088 --repo HiQS-Labs/XYZ-forge --json body,title,url` failed with “error connecting to api.github.com”; requirements were checked against the committed canonical plan and approved plan-review record instead.

Evidence scope: Verify-tier direct source review of the current checkout. The nearest graph project is XYZ-forge at the primary clone, generation `2026-09-01T15:54:30Z`; coverage for the nine requested paths was stale/missing/not-tracked or excluded (CHANGELOG), so all material evidence used current files and read-only object inspection. No graph completeness claim.

relay closed (Approved), no further turn needed. Producer may proceed to the required final gate and publication steps.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
