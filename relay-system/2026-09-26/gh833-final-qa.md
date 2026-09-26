# RELAY · GH-833 final QA — define PRS, the Product Release System
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
6. **Commit only the relay file** (`relay(gh833-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh833-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh833-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) #833's acceptance holds: the glossary and `ROUTER.md` define PRS and name the trinity; each canonical doc
    spells PRS out on first use; no bare PRS precedes its definition; PDDA reports 0 errors;
  - (b) the implementation matches the approved plan (`relay-system/2026-09-26/gh833-plan-review.md`, attested
    at `dbce9916`), and the plan's Results section records every deviation truthfully;
  - (c) there is one definition, every other placement points to it without restating it, and every link and
    anchor resolves (the absolute URLs resolve once this merges);
  - (d) the wording is accurate about the ledger and the three skills' behaviour is unchanged: no instruction,
    route or command is altered;
  - (e) every touched path is docs to `utils/ci-route.sh` (tier 1), and nothing adds a suite, a registry entry,
    code or gate machinery;
  - (f) the evidence in `TESTS-RESULTS/2026-09-26+GH-833/` substantiates the Results table, and the rating
    `55/20/50/85` still fits.

## Review packet

**What this is.** Final QA for #833 (`https://github.com/HiQS-Labs/XYZ-forge/issues/833`). The artifact
`.relay-artifacts/gh833-final.diff` is `git diff af4fef27 cd777ca7`, without the binary `releases.db` and the
approved plan-review thread. The branch `feat/gh833-prs-docs` is checked out in this worktree at `cd777ca7`, so
read the files whole.

**Operational envelope.** A single-repo local developer harness. This is a docs-only wording change, and its merge is
meant to be the first landing the hosted reconcile qualifies with the Small gate (#831 Phase 3). The operator has
ruled "no new tests". Grade against the stated requirements and commensurate complexity. Do not ask for new suites,
lint rules or code.

**Read:**
- the artifact;
- the plan, `PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md`, especially Plan, Verification and Results;
- the edited files whole around each change: `HOW-TO-USE.md` (5-12, 67-95), `ROUTER.md` (1-8), `AGENTS.md`
  (170-178), `SOP.md` (58-66), `ARCHITECTURE.md` (402-410), `RELEASES-DB-FAQS.md` (1-10), `README.md` (140-148),
  `PROJECT/PDDA.md` (944-950), and the six skills;
- the evidence: `witnesses.log`, `witness-script.sh.txt`, `prs-order-check.sh.txt`, `prs-definition-check.py.txt`,
  `red-controls-base.log`, `v2-v4.log`, `v3-reader-suites.log` and `provenance.jsonl`.

You may run read-only probes: the two check scripts on `$PWD`, `git grep`, and
`git diff --no-renames --name-only af4fef27...HEAD | bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):

1. **Acceptance.** Does each item of #833's acceptance hold in the files, not only in the checks?
2. **Accuracy.** Is the glossary entry true to the ledger (`AGENTS.md` 173-178, `RELEASES-DB-FAQS.md`,
   `utils/py/releases_app.py`)? Does any placement misdescribe what it names?
3. **Behaviour.** Does any skill edit change an instruction, a recited contract (`end-of-week`'s recite block), a
   frontmatter field's meaning (`10days` description), or the start-task rating policy?
4. **Links.** Do the relative links and the GitHub anchor resolve? Is `#glossary--the-five-terms-youll-hit-first`
   GitHub's slug for the new heading?
5. **Tier.** Does the full committed diff, including the ledger dump, the relay threads and the evidence, route
   to tier 1?
6. **Evidence.** Do the logs and provenance substantiate every row of Results? Is anything overclaimed?

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
