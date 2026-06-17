# RELAY · Recommendations mockup — "mark as implemented" capture control
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, the Context block, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: `PROJECT/2-WORKING/mockups/recommendations-page.html` — specifically the **new "mark as implemented" capture control** added to each *live* recommendation card (the `.rec-impl` block + its CSS). The rest of the mockup was already approved in a prior relay (`relay-system/2026-06-15/recommendations-page.md`) — review the new control, not the whole page again.
- Definition of Done: **A clearly-marked FUTURE (not-yet-wired) operator self-report control on each live rec card that (a) reads honestly as "coming soon / self-reported, not verified against Klaviyo" and does NOT imply a working backend today; (b) communicates the captured data model — an `implemented_at` timestamp + actor — and its purpose (a before/after lift-measurement anchor for P26); (c) attaches to the portfolio/strategic rec unit (§2), not per-customer; (d) preserves the just-won WCAG AA contrast and keyboard/a11y bar; (e) does not muddy the page's live-vs-future honesty story even though it sits inside a "live" card.**
- Producer: Claude (Opus 4.8)   ·   Reviewer: Codex
- Handoff: manual nudge
- Scope: operator wants a SINGLE review cycle — **You Draft → Codex Review → You Iterate** (max ROUND 2). Keep findings high-signal; don't reopen the already-approved base mockup.
- Started: 2026-06-15

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(recommendations-impl-log): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:`; the Reviewer logs a verdict `Basis:` — `behaviorally proven` (rendered in a browser / probed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. For this mockup, opening the file and inspecting the new control (render + contrast sampling) is `behaviorally proven`; reading the HTML/CSS without rendering is `textual only`.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

## Context for the Reviewer (read before reviewing)

**What changed.** A new **"Mark as implemented in Klaviyo"** control was added to the expanded body of each of the **5 live** recommendation cards (not the future cards). It is a deliberate FUTURE capability captured into the mockup — there is no backend behind it yet.

**Why it exists (product rationale, agreed with the operator):**
- The product's unit of action is **portfolio/strategic** (§2 of `RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md`): the operator's one real action is wiring a pattern/pair into their existing Klaviyo flow. This control records *that* event — it is NOT per-customer.
- It fills a **named measurement gap**: the spec admits it can't honestly promise lift until P26 measures it (the Black Crow confound, SWE-internal §2.3). A captured `implemented_at` timestamp + actor is the **before/after anchor** a lift read needs — you can't attribute revenue movement to a change without knowing when it went live.
- It has **precedent**: the Scenario Studio already audits Save/Reset with actor + before/after payload (see the FAQ copy in `app/ui/recommendations.py`), so "actor + timestamp + note" logging is an existing pattern applied to a new event — not net-new backend invention.

**How it's rendered (the honesty stance to vet):**
- Each `.rec-impl` block: a disabled checkbox "Mark as implemented in Klaviyo", a **"Coming soon"** pill, a one-line hint naming the `implemented_at` + actor capture and stating "**Self-reported — not verified against Klaviyo**", inside a dashed/striped (future) container.
- Card **#1** (Gummies→Tinctures) shows the **implemented** example state: a captured log line `✓ Implemented · self-reported · Jun 15 2026, 2:31 pm · noel@neochro.me`. The other 4 live cards show the unchecked state.
- The checkbox is `disabled` on purpose (no live behavior) — it signals "not actionable yet" alongside the "Coming soon" pill.

**Specific things to scrutinize (Producer's review asks):**
1. **Honesty / does-it-imply-a-live-backend** — is a FUTURE control sitting *inside a LIVE card* confusing, or does the dashed + "Coming soon" + disabled treatment scope the "future" clearly to just this row? Is the `is-future` whole-card pattern vs. this in-card future-row pattern a coherent visual language?
2. **Self-reported framing** — is "self-reported · not verified against Klaviyo" prominent enough that no one reads the log as verified activation truth?
3. **WCAG AA** — re-sample contrast on the new elements: `.rec-impl-toggle` label, the **disabled** checkbox, `.impl-soon` pill (`--text-muted` on `--bg-sunken`), `.rec-impl-log` (accent-on-soft on accent-soft), `.rec-impl-hint` (`--text-muted`). The prior relay just brought the page to AA — don't regress it.
4. **a11y of the control** — the disabled checkbox has an `aria-label`; is the implemented-state log conveyed to AT acceptably (it's plain text, not tied to the checkbox state)? Suggest the lightest fix if not.
5. **Data-model legibility** — does the hint communicate enough of the eventual model (`implemented_at` + actor + note) for this to "translate into the plan" later, without over-speccing a backend in a mockup?
6. **Placement** — is below the two carets the right spot, or should it sit elsewhere in the card?

**Out of scope:** the already-approved base mockup (live/future split, badges, carets, Scenario Studio); Reflex/backend implementation; the direction-doc capture (the operator will fold the vetted design into `RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md` §6 *after* this relay approves — intentionally deferred so the doc reflects the reviewed version).

---
## Log

### Round 1 · Producer · Claude · 2026-06-15 14:40 PDT
**Did:**
- Added a `.rec-impl` "Mark as implemented in Klaviyo" control to the expanded body of all **5 live** rec cards in `recommendations-page.html` (not the future cards): disabled checkbox + "Coming soon" pill + an `implemented_at`/actor hint that states "self-reported — not verified against Klaviyo", in a dashed/striped future container.
- Card #1 demonstrates the **implemented** state with a captured log line (`✓ Implemented · self-reported · Jun 15 2026, 2:31 pm · noel@neochro.me`); the other 4 show the unchecked state.
- Added scoped CSS (`.rec-impl*`) reusing existing tokens (`--accent-soft`/`--accent-on-soft` for the captured log, `--text-muted` for hints/pill, dashed `--line-strong`); no new tokens, no new JS (control is intentionally inert).
**Review this:** the 6 scrutiny points in "Context for the Reviewer" — especially (1) whether a future control inside a live card muddies the live-vs-future honesty story, (2) the self-reported framing, and (3) no WCAG AA regression on the new elements.
**Verification:** structural — confirmed 5 `.rec-impl` rows (1 implemented example, 4 unchecked), all inside live cards, future cards untouched; `<div>`/`<details>` tag balance OK (the lone `<details` "mismatch" is a literal in a CSS comment, not a tag). Did NOT render in a browser this turn — Reviewer asked to open it for a `behaviorally proven` basis + contrast re-sample.
**Open questions:**
- Is the in-card future-row treatment (dashed + "Coming soon" + disabled) honest enough, or would you rather the capture control live in a single page-level "Coming soon" affordance instead of per-card?
- Is showing one card in the implemented state (with a fake timestamp/actor) helpful, or does a populated example over-imply the feature is live?
**Commit:** 3d9c249

### Round 1 · Reviewer · Codex · 2026-06-15 15:10 PDT
**Verdict:** Changes requested.
**Basis:** textual only — inspected `recommendations-page.html` and computed token-pair contrast from the declared OKLCH values; I did not render the mockup in a browser, so final visual hierarchy and UA disabled-checkbox styling are not behaviorally proven.
**Findings & proposals:**
- [Should] The populated example on the first live card still over-signals "this already happened" inside the "Live now" section. The strongest local string is the log row `Implemented · self-reported · Jun 15 2026, 2:31 pm · noel@neochro.me`, while the "Coming soon" caveat sits beside the label and the "not verified" caveat is pushed into the hint below (`PROJECT/2-WORKING/mockups/recommendations-page.html:411-418`). Proposed fix: relabel the populated row as specimen data, e.g. `Example future log:`, `Would capture:`, or `Sample self-report:`, so no reader can mistake it for a real recorded activation.
- [Pass] The future-row pattern itself is coherent. Reusing the same dashed/striped treatment and muted "Coming soon" pill as the `.is-future` whole-card language scopes the futurity to this sub-row rather than muddying the whole live card (`PROJECT/2-WORKING/mockups/recommendations-page.html:199-249`, `PROJECT/2-WORKING/mockups/recommendations-page.html:411-418`, `PROJECT/2-WORKING/mockups/recommendations-page.html:457-599`).
- [Pass] The new text contrast looks safely AA from the declared tokens: label `--text` on `--bg-elev` ≈ 17.29:1, hint/pill `--text-muted` on `--bg-sunken` ≈ 5.90:1, log `--accent-on-soft` on `--accent-soft` ≈ 10.04:1 (`PROJECT/2-WORKING/mockups/recommendations-page.html:19-32`, `PROJECT/2-WORKING/mockups/recommendations-page.html:223-249`). The disabled checkbox itself is inactive, so its UA-disabled rendering is not the release-risk here.
- [Pass] Placement below the two carets keeps the control attached to the portfolio-level recommendation unit, not per-customer execution, and the hint communicates the `implemented_at` + actor measurement purpose without pretending there is backend behavior today (`PROJECT/2-WORKING/mockups/recommendations-page.html:394-419`, `PROJECT/2-WORKING/mockups/recommendations-page.html:457-599`).
**Answers:**
- The in-card future-row treatment is the right direction; I would not move this to a single page-level affordance.
- Showing one implemented example is useful for the data model, but only after it is visibly marked as example/sample future output.
**Commit:** none (harness commits)

### Round 2 · Producer · Claude · 2026-06-15 15:25 PDT
**Decisions on proposals:** (verified the finding against the rendered card #1 before editing)
- [Should] Populated example over-signals a real recorded activation — **Implemented** → relabeled card #1's log row with an "Example log" specimen marker (`.impl-sample`, warn-toned mono pill) so it reads unmistakably as illustrative future output, not a real event: now `[Example log] ✓ Implemented · self-reported · Jun 15 2026, 2:31 pm · noel@neochro.me` ([recommendations-page.html:419](PROJECT/2-WORKING/mockups/recommendations-page.html#L419)). Kept the checked-state demo (Codex's Pass + Answer endorsed showing one implemented example, *once marked as sample*). · Proof: `.impl-sample` uses the warn palette (`--warn-text` on `--warn-soft`) = the divergence-badge tones, already AA; no other contrast touched.
**Did:** added the `.impl-sample` style; no other changes — narrowest edit closing the one Should.
**Verification:** structural — single edit to card #1's log row + one new CSS rule; the 4 unchecked live cards and all future cards untouched.
**Re-review this:** confirm the card #1 row now reads as a sample/specimen (not a real activation) and the "Example log" pill is legible. Per the agreed single-cycle scope (Draft → Review → Iterate) this is the final Producer turn; a final Codex approve is optional.
**Commit:** 7f0cf78

### Round 2 · Reviewer · Codex · 2026-06-15 17:39 PDT
**Verdict:** Approved.
**Basis:** textual only — inspected the revised HTML/CSS; I did not render the mockup in a browser. The Round 1 Should is textually fixed, not behaviorally proven.
**Findings & proposals:**
- [Pass] The card #1 populated row now reads as specimen output rather than a real recorded activation. The inline `Example log` marker sits inside the captured row itself, so the strongest local cue is now "illustrative future data" before the timestamp/actor payload reads (`PROJECT/2-WORKING/mockups/recommendations-page.html:246-253`, `PROJECT/2-WORKING/mockups/recommendations-page.html:425`).
- [Pass] The existing hint still carries the two honesty constraints the DoD needed: this captures `implemented_at` + actor for before/after lift measurement, and it is "Self-reported — not verified against Klaviyo" (`PROJECT/2-WORKING/mockups/recommendations-page.html:426`).
**Answers:**
- Yes: the card #1 row now reads as a sample/specimen, not a real activation.
- Textually, the `Example log` pill is legible: it is a dedicated warn-toned mono badge with its own border and spacing, separate from the captured log payload (`PROJECT/2-WORKING/mockups/recommendations-page.html:248-253`).
**Commit:** none (harness commits)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
