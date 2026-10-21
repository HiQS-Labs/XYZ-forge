# RELAY · GH-1174 ATE documentation final review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-20.
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
6. **Commit only the relay file** (`relay(gh1174-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1174-ATE-FUZZ-DOCS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1174-ATE-FUZZ-DOCS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-10-20
- Definition of Done: source-accurate documentation only, with all questions below answered.

## Review brief

Goal: independent final QA of GH-1174 manual docs hotfix, comparing origin/development..HEAD.
The user explicitly authorized correcting ATE/fuzzing docs, independent review, existing docs checks,
canonical ledger writers and normal-hook fast-forward publication to development WITHOUT a PR.
The express driver rejects SKILL.md; the manual exception is explicitly approved. No runtime,
packaging, tests, workflows, release-policy, skill deployment or production changes are in scope.

Read these changed files in FULL: skills/4-occasional/ate/SKILL.md,
PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md, PROJECT/2-WORKING/GH-1174-ATE-FUZZ-DOCS.md,
CHANGELOG.md (new entry), and releases.sql (new GH-1174 rows only).
Verify claims against utils/ate/install.sh, utils/ate/scripts/{run_variations,checkin,compile_issue}.py,
all three variation templates using harness_root, utils/ate/tier1-calibration.json, and
utils/py/{adaptive_ate,fuzz_engine,domain_oracles,gen4_campaign,repro_builder,repro_synth,self_healer}.py.
Read the unchanged defect-campaign skill to ensure its safeguards remain intact.

Questions:
1. Are runner exit codes, no-model exit-only classification, expects_edits and usage-exit limits accurate?
2. Is full-checkout execution accurate, including the missing proc_group dependency and all copied harness_root templates?
3. Are nine targets, no-synth/default-on synthesis, unused campaign tier2-cmd, replay OR predicate,
   exit-only synthesis fallback and targetless clustering accurately distinguished from semantic proof?
4. Are seeded plans versus outcomes, corpus feedback timing, output feedback versus coverage and
   twin exit/stderr parity versus semantics explained accurately?
5. Are calibration 50/24/9, historical 2026-09-04 status/reports, observational oracles/lsof skips,
   recorded host violations, batch budgets, exit0 findings and destructive-reset supervision accurate?
6. Does the documentation clearly reject the atomic-write/full-validation repair promises, preserve
   qualification requirements and keep code follow-ups separate? Does it avoid inventing approval authority?
7. Is the consolidation concise and reviewable? The map explicitly supersedes old module-header
   promises/grid comments, keeping executable files byte-identical and the publication gate docs-only.
   Flag any material remaining contradiction or lost useful guidance; do not demand behavior/test changes.

Operational envelope: repository documentation. No installs, campaigns, model benchmarks, runtime suites,
new tests, production/credential access or external writes. Read-only source inspection and narrow static
checks only; no test/*.sh/validate.sh/pytest in your worktree. Existing docs verification is performed by
producer in a separate disposable full clone. Do not claim those checks ran during your review.
Report file:line findings, swept file: yes/no, source revision and PASS/FAIL. Approve only if source
claims and scope pass; pre-existing code defects are known limitations, not a request to fix code.
Commensurate complexity: no new machinery or speculative requirements.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
