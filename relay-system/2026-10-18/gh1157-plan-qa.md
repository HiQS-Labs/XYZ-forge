# RELAY · GH-1157 plan QA: skills-army-hq hard rules first (prose-only SKILL.md)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh1157-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1157-SKILLS-ARMY-HARD-RULES.md` (the plan). Read with it:
  `skills/3-weekly/skills-army-hq/SKILL.md` (the file the plan changes, unchanged so far),
  `skills/3-weekly/skills-army-hq/scripts/intake.py` and `scripts/sync.py` (what the prose claims
  about them must be true), `utils/ci-route.sh` (gate routing claim), `AGENTS.md` → *No new tests*.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the plan's **Asks / acceptance criteria** section (items 1–7) is implementable
  as a prose-only, single-file change; every factual claim the new prose will make about the scripts
  is true of the code at this revision; the plan names the existing subsystem it extends, explicit
  non-goals, an Easy rollback, and a verification scope that adds no test (GH-831); the four-axis
  rating rationale is grounded.

## Review packet

**Goal.** Pre-implementation QA of the plan for GitHub issue #1157: put a "Hard rules (read first)"
block and a "Definition of done" at the top of the Skills Army HQ skill instructions so agents stop
hand-editing the deployment collection, stop forcing refusals through, run status first/last, resolve
the per-device root and canonical before acting, and apply renames/retirements per device.

**Operational envelope.** A documentation-only change to one `SKILL.md` in a local developer
toolkit. The deployment tool is two Python scripts run by hand or by an agent on a single Mac. Grade
against this envelope and the plan's stated non-goals; do not ask for enterprise fail-safes, new
scripts, hooks, device configuration, or tests (the repo forbids new tests — a request for one is a
finding against the request).

**Non-goals (already decided, out of scope here).** Script changes (receipt-stale detection, receipt
refresh — #1157 rung 4); Git Pulse Sync post-pull hook (rung 3); device config on any machine;
publisher policy (#961); status exit-code semantics (#958); downstream child publication; any device
repair.

**Questions — answer each with a grade and a citation:**

1. **Factual claims about the scripts.** The plan asserts: (a) `intake.py --apply update` copies and
   commits with no drift gate and app links expose the bytes immediately, so `sync.py`'s later drift
   refusal cannot roll a downgrade back; (b) there is no supported stale-receipt refresh — `catalog`
   only `setdefault`s and an identical `update` returns `Unchanged` before rewriting the receipt;
   (c) `sync.py --status` never compares a receipt digest with the deployed bytes; (d) a symlinked
   collection root is refused by `intake.py`. Are all four true at this revision? Cite `file:line`
   for each, or name the one that is false.
2. **Routing claim.** The plan says this `SKILL.md` is a docs surface, tier 1, because
   `utils/ci-route.sh`'s `is_docs_surface()` matches `*.md` before the subsystem mapping. True?
3. **Suites.** The plan says no suite pins this file's text (gh620 and `test_deploy_skills.py` assert
   existence only). Is there any suite, fixture or mini-sync check that this prose change would break?
4. **Contradictions.** Would any of the five rules or the Definition of done contradict an existing
   section of `SKILL.md` (notably "Immediate symlink read-through boundary", the GH-672 SOP, the
   drift-guard section, or the GH-1046 provenance prose)? Name the sentence pair if so.
5. **Over-reach.** Does any proposed rule overstate what the scripts enforce, or require an agent to
   manufacture a clean provenance report to finish a documentation-only task? (The plan deliberately
   says a stale receipt is a valid reported partial result.)
6. **DRY / smallest surface.** Is anything in the plan a parallel subsystem, duplicated prose, or
   avoidable scope? Is the fold-in of the existing line-45 sentence the right dedupe?
7. **Verification.** Is the stated verification (docs gate `pdda.sh run`, `releases check`, a
   read-only frontmatter parse with the tooling's own reader run with `python3 -B` from a scratch
   copy, and a red control that removes `name:`) sufficient and commensurate? Does it add a test?
8. **Rating.** Is `rated 60/55/50/90` grounded in the stated consequence and recurrence evidence,
   with appeal left neutral (no operator preference was given)?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Write graded findings with
`file:line` citations, declare `swept file: yes|no`, set a VERDICT and Basis, and set `STATUS: Approved`
if the plan passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL

Basis: The single-file instruction change is appropriate and the four core script claims are supported by source inspection. Two small documentation corrections remain: record verification with the required provenance, and correct an existing safety-relevant claim about unrelated changes. Reviewed the entire plan and entire target SKILL.md; the pre-existing defect is called out below. No suites or executable fixtures were run in this worktree.

- [Pass] **Q1 — script facts.** (a) Intake's add/update path has no canonical drift gate: `scripts/intake.py:787–808` stages/replaces payloads, `:845–851` transacts then attempts a commit; `:500–504` replaces the directory at the same path app links target. Sync's refusal is later and only gates reconciliation (`scripts/sync.py:218–239`, `:375–385`), with no rollback of intake. (b) Identical updates return before receipt replacement (`scripts/intake.py:797–808`); catalog only `setdefault`s (`:840–842`), and the parser offers no refresh verb (`:687–707`). (c) Status inventories current digests then reconciles links and reports recorded sources; it never compares those digests to receipt digests (`scripts/sync.py:364–386`, `scripts/intake.py:289–300`, `:384–395`). (d) Root and ancestor symlinks are refused by `scripts/intake.py:54–61`, invoked at `:713`; payload symlinks are separately refused at `:295`. All script citations here and below are relative to `skills/3-weekly/skills-army-hq/`.

- [Pass] **Q2 — routing.** `utils/ci-route.sh:63–65` matches `*.md`; `:382–383` excludes docs from subsystem classification. The targeted skill has no full-gate exception. The tier-1 claim in plan lines 88–91 is supported by source inspection.

- [Nit] **Q3 — narrow the existence-only claim.** No inspected assertion pins the instruction text, so no suite edit is indicated. However, plan lines 92–94 overcompress the coverage: `test/gh620-skills-army-mini-sync.sh:190–194` also compares the installed whole tree to the canonical tree and expects an identical update to return `Unchanged`; `test/test_deploy_skills.py:205` mutates the literal `name: skills-army-hq`. Say “no assertion pins the prose; existence, identity and copy-parity checks remain applicable.” These checks are compatible with the planned description/body edit provided the name stays intact. Runtime suite outcome is **[Unverified — needs clone run]**.

- [Should] **Q4 — correct the pre-existing unrelated-changes claim within the same SKILL.md.** `SKILL.md:29–30` says intake “refuses over unrelated changes.” In fact `scripts/intake.py:845–851` applies the transaction before `commit_skill` checks unrelated changes (`:466–471`); it then emits `WARN not committed` and returns 0 (`:855–858`). Payloads can already have changed and be readable through app links. Plan criterion 7 (`PROJECT/1-INBOX/GH-1157-SKILLS-ARMY-HARD-RULES.md:77–78`) would preserve this misleading statement. Permit a narrow correction to “applies the payload, then declines the automatic commit and warns if unrelated changes exist”; do not change the scripts.
  Observed input: the existing sentence “refuses over unrelated changes” (`SKILL.md:30`) against the explicit transact-before-commit call order (`scripts/intake.py:846–851`).
  Affected scope: the description of automatic commit behavior for add/update/remove in a Git-backed collection with unrelated uncommitted paths.
  Falsifier: an existing pre-transaction unrelated-change rejection on that command path would make the correction unnecessary; the inspected `main` path has none. A future disposable-clone check with unrelated dirt should show changed payload bytes plus `WARN not committed`, rather than an unchanged payload.

- [Pass] **Q4–Q6 — remaining fit, scope and DRY.** The elevated read-through warning agrees with `SKILL.md:190–194`; per-device root resolution agrees with `:145–149`, and rename/retirement acknowledgment extends `:85–89`. The distinction between local parity and upstream freshness agrees with `:180–183`. The proposed stale/source-unverified receipt outcome (plan lines 64–68) avoids manufacturing clean provenance. Folding the sentence at `SKILL.md:45–46` into rule (a) is the right dedupe. Plan lines 104–117 identify the existing owner, explicit non-goals and an Easy one-file rollback; no parallel subsystem is proposed. Apart from the unrelated-changes sentence above, no additional pre-existing defect requiring a change was identified in the target instruction file.

- [Should] **Q7 — specify the required durable verification evidence.** Plan lines 123–127 record the reader check and red control only “in this doc and the PR.” `AGENTS.md:112–114` requires committed `provenance.jsonl` for cited runs, and `:159–161` places manual checks under `TESTS-RESULTS/<date>+GH-<n>/` with that provenance. Amend the plan to record the positive parse, missing-name red control and cited gate results there, commit the provenance in the implementation PR, and link it from the plan/PR. This is an evidence artifact, not a new test or runner. Keep the runtime change restricted to the one SKILL.md; update the stated supporting-document scope accordingly.
  Observed input: plan lines 123–127 name only the doc/PR as the manual-check record and provide no provenance destination.
  Affected scope: verification runs cited as implementation evidence for GH-1157.
  Falsifier: an existing explicit plan instruction committing these runs' provenance under the required evidence directory would satisfy the requirement; none appears in the reviewed plan.

- [Pass] **Q7 — check design otherwise proportionate.** The reader validates nonempty name and description (`scripts/intake.py:126–130`); `package_info` delegates to it (`:134–138`). Parsing a scratch folder named `skills-army-hq`, then removing `name:` in another scratch copy, gives a meaningful positive/red pair without adding a test. Docs and ledger checks in plan lines 121–126 are commensurate. They are planned checks, not claimed passing runs in this review.

- [Pass] **Q8 — rating rationale.** Plan lines 159–169 explicitly ground 60/55 in recurring recoverable deployment disruption, leave appeal neutral at 50, and assign cheapness 90 to a prose-only change. The immediate-byte-exposure path supports the stated downgrade consequence (`scripts/intake.py:500–504`). The historical incident counts are attributed to issue evidence in the plan; they were not independently re-queried during this local review, so this is approval of the rationale's proportionality, not attestation of those live issue records.

Handing off to Producer (claude-a) — address the two Should findings and disposition the Nit, then return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
