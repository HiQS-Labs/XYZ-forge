# RELAY · GH-833 plan review — define PRS, the Product Release System
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
6. **Commit only the relay file** (`relay(gh833-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh833-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh833-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) each recon claim R1–R6 matches the cited files and lines;
  - (b) the plan covers every item of #833's scope and acceptance, or names why one is out;
  - (c) there is one canonical definition, and every other placement points to it without restating it;
  - (d) every touched file is docs to `utils/ci-route.sh`, so the landing is tier 1 and takes the hosted Small
    run; nothing touches `relay-automation/*` or `skills/*/relay-xyz/*`;
  - (e) the witnesses V1–V5 are falsifiable, their red controls fire, and nothing adds a suite, a registry
    entry or gate machinery;
  - (f) the rating `55/20/50/85` and its rationale are grounded, and appeal is neutral (the operator set none).

## Review packet

**What this is.** The plan for #833 (`https://github.com/HiQS-Labs/XYZ-forge/issues/833`): define PRS, the
Product Release System (the RELEASES ledger), once, and spell it out where the canonical docs and six skills
introduce the ledger. The artifact is `.relay-artifacts/gh833-plan.md`, a copy of
`PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md` at `fd511c52`. Read #833's text with `gh issue view 833` if you can;
otherwise, the plan's scope follows the issue's steps 1–3, non-goals and acceptance.

**Operational envelope.** A single-repo local developer harness. This is a docs-only wording change. The operator
has ruled "no new tests" (AGENTS.md). The merge must also be docs-only to the tier router, because it is the
first landing meant to qualify through the hosted Small run (#831 Phase 3). Grade against the stated
requirements and commensurate complexity. Do not ask for new suites, lint rules, glossary machinery or code.

**Read:**
- the artifact;
- the placements it cites: `HOW-TO-USE.md` 5-10 and 67-80, `ROUTER.md` 1-12 and 110-125, `AGENTS.md` 154-178,
  `PROJECT/PDDA.md` 590-602 and 944-950, `SOP.md` 58-64, `ARCHITECTURE.md` 76-82 and 402-408,
  `RELEASES-DB-FAQS.md` 1-8, `README.md` 36-40 and 140-147;
- the skills: `skills/2-daily/releases/SKILL.md` 1-10, `skills/1-hourly/start-task/SKILL.md` 236-244,
  `skills/2-daily/merge-cleanup/SKILL.md` 1-10, `skills/2-daily/start-marathon/SKILL.md` 236-241,
  `skills/3-weekly/10days/SKILL.md` 1-25, `skills/3-weekly/end-of-week/SKILL.md` 28-34;
- `utils/ci-route.sh` 54-72 (`is_docs_surface`) and 305-350 (`full_required`);
- `utils/py/wave_reconcile.py` 589-614 (`select_qualification_gate`).

You may run read-only probes, such as `git grep -nw PRS` or piping a path list through
`bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):

1. **Placements.** Is each R2/R3 placement the right one? In particular:
   - `AGENTS.md` 173 rather than 157;
   - `ARCHITECTURE.md` 406 rather than the catalog row at 80;
   - `README.md` 145 rather than 38;
   - start-task's rating policy rather than its recite block;
   - editing `10days`'s frontmatter description and `end-of-week`'s recite block, where PRS first appears.
2. **`PROJECT/PDDA.md`.** It is the PDDA contract that other repos adopt. Is the proposed wording right for
   them, and is the roadmap-ledger contract at 948 the right place?
3. **The glossary.** Is `HOW-TO-USE.md`'s glossary the right single home for the definition, rather than
   `RELEASES-DB-FAQS.md`? Is the proposed entry accurate about what the ledger holds and how it is written?
4. **Tier 1.** Can any touched path, including the ledger dump and this relay thread, route as non-docs?
   Is the "only landing in its reconcile" condition correct?
5. **Witnesses.** Does V1 catch a PRS used before its definition, and an edit that is missing? Do V1's and V2's
   red controls fire? Is V3's suite list complete?
6. **Scope.** Anything missing from #833, over-built or out of scope?
7. **Rating.** Is `55/20/50/85` grounded in the rationale?

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
