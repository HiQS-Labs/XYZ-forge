# RELAY · GLM QA: hiqs-ai-resolve PR #51 (GH-49)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(hiqs-pr51-glm-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/pr51.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-hiqs-ai-resolve/e1cc774f-3230-482b-8148-e7d7414b4fa4/scratchpad/pr51.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-10-14
- Definition of Done: PR https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/51 (artifact = its full diff vs `main`)
  correctly implements issue #49 and its approved plan `docs/issue-49/plan.md`, with accurate docs and honest evidence.
  This is an additional independent review; Codex already approved plan and final diff.

### Operational envelope & non-goals
Documentation + skill-folder rename in a private single-maintainer repo (Lovable-synced `main`). No runtime code
change (the runtime classification fix is issue #50). No new tests. Grade against #49 and the plan, not unrequested
machinery. READ-ONLY: write only this relay file; do not edit the task clone.

### Read (absolute paths, read-only)
- Task clone at PR head ae7a29e: `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14`
  — `docs/issue-49/plan.md`, `docs/issue-49/durability-probe.md`, `skills/hiqs-research/SKILL.md`,
  `skills/hiqs-image/SKILL.md`, `skills/hiqs-chain/SKILL.md`, `CHANGELOG.md`, and the runtime source
  `consumer/chain.ts` lines 220-325 (to check the network section's claims).
- Prior reviews (for context, do not just repeat them): XYZ-forge `relay-system/2026-10-14/hiqs-gh49-plan-qa.md`
  and `relay-system/2026-10-14/hiqs-gh49-final-qa.md`.

### Questions
1. Is the rename complete and consistent? Any live reference to `resolve-research`/`resolve-image` left in
   `skills/` Markdown other than the two "formerly" notes? Do `name:` fields match folders?
2. Is the "Network requirement" section in `skills/hiqs-chain/SKILL.md` technically accurate against
   `consumer/chain.ts` (dispatched flag set before fetch; transport errors mapped to `contract_rejected`; HTTP-200
   shape rejections producing the same signature)? Is anything overstated or misleading?
3. Will an agent reading `hiqs-research` or `hiqs-image` actually find the network guidance (pointer wording,
   anchor `#network-requirement`)? Any wording that would mislead an agent into weakening admission checks?
4. Are any deliberate exclusions (historical docs, signed `image-manifest.json` evidence) wrong?
5. Anything missing, wrong, or over-engineered — including the CHANGELOG line and the durability-probe record?

Cite file:line for every finding. Set STATUS: Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
