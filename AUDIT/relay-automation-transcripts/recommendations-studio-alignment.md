# RELAY · Recommendations mockup — Scenario Studio alignment pass
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
- Artifact under review: `mockups/recommendations-page.html` — specifically the **Scenario Studio column** (`.studio-rail` → the action rail, header, presets, the two levers, the preview note). The recommendation cards + the impl-log control were already approved in prior relays — review the **Studio's alignment with the rest of the page**, not those.
- Definition of Done: **The Scenario Studio reads as part of the same page as the plain-English rec cards: (a) shared vocabulary/altitude — levers lead with plain-English names (technical alias kept as a secondary tag), not raw-algorithm jargon; (b) visible lever→card linkage — each lever names the cards it governs, and the preview note names the affected card; (c) honest gating — the Studio is marked an internal admin/support-view surface (it only renders in support view in the real app); (d) the two "commit" verbs are disambiguated — Studio "Save as live" (engine tuning) vs the per-card "Mark as implemented" (activation log); (e) NO misstatement of the engine — the cross-sell "affinity floor" (a 0–1 co-purchase score) and the "≥20-co-orders" deploy tier are RELATED BUT DISTINCT gates; the copy must say "works alongside", not equate them; (f) no WCAG AA regression.**
- Producer: Claude (Opus 4.8)   ·   Reviewer: Codex
- Handoff: manual nudge (this round driven headless via `codex exec` behind the relay shim)
- Scope: operator wants a SINGLE return-trip — **Draft → Codex Review → (iterate if needed)** (max ROUND 2). High-signal findings only; don't reopen the already-approved cards or impl-log control.
- Started: 2026-06-15

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(recommendations-studio-alignment): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:`; the Reviewer logs a verdict `Basis:` — `behaviorally proven` (rendered in a browser / probed) or `textual only` (read, not run). Opening the file and inspecting the Studio (render + contrast) is `behaviorally proven`; reading the HTML/CSS without rendering is `textual only`.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

## Context for the Reviewer (read before reviewing)

**The problem this pass fixes.** The redesigned rec cards speak deliberate **plain-English abstractions over the algorithm** (action headline + Why/How carets + Deploy/Monitor/Hold badges). The Scenario Studio column was still speaking **raw-algorithm jargon** ("affinity floor", "nudge fraction", "median reorder day") with no visible tie to the cards — two columns, two languages. This pass re-aligns the Studio to the page.

**What changed in the Studio (`.studio-rail`):**
1. **Plain-English lever names + technical alias.** "Cross-sell **confidence bar**" (alias: *affinity floor*); "**Restock reminder timing**" (alias: *replenishment nudge fraction*). Help text rewritten to plain English.
2. **Lever→card linkage.** Each lever now has an **"Affects:"** line naming the cards it governs (cross-sell + the Mushroom-Gummies→Capsules Hold; the day-38 replenishment card). The **preview note** now names the affected card ("…keeps Mushroom-Gummies → Capsules below the deploy bar (still Hold)").
3. **Admin/support-view gating.** The Studio header carries an **"Admin · support view"** tag + a subtitle saying most operators won't see this (matches the real app: the Studio only renders in support/impersonation view).
4. **Two "commit" verbs disambiguated.** A caption under the action rail: **"Save as live"** changes what the engine surfaces; it does **not** mark a rec implemented in Klaviyo — that's the per-card **"Mark as implemented"** log.

**The one accuracy line to check hard (DoD item e):** the cross-sell **affinity floor** (a 0–1 co-purchase *score* a pair must clear to qualify) and the **≥20-co-orders** *deploy tier* are **related but DISTINCT** gates in the engine (`nbp.py` / `LTVERA-ALGORITHM-COPY.md`). The new lever help says the bar **"works alongside the ≥20-co-orders deploy bar"** — deliberately NOT equating them. Verify the copy doesn't slip into claiming the floor *is* the ≥20 bar.

**Scrutiny points (Producer's asks):**
1. Vocabulary/altitude — do the levers now read like the rest of the page (plain-English first), or is jargon still leading?
2. Linkage — are the "Affects:" lines + preview-note card name a real, correct connection (right cards for each lever)?
3. Accuracy — is the "works alongside" framing of floor-vs-≥20 honest, or does any line still conflate the two gates?
4. Gating — is the "Admin · support view" treatment clear without over-burying the Studio?
5. Verb disambiguation — is the Save-as-live vs Mark-as-implemented caption clear and not redundant?
6. WCAG AA — re-sample the new small text: `.studio-admin-tag` (warn palette), `.lever-tech` (`--text-muted`), `.lever-affects` (`--text-muted`), `.studio-actions-foot` (`--text-muted`).

**Out of scope:** the approved rec cards + impl-log control; Reflex/backend; the lever *set* (only 2 levers shown — lightly mocked is fine).

---
## Log

### Round 1 · Producer · Claude · 2026-06-15 18:10 PDT
**Did:**
- Re-voiced both Studio levers to plain-English names with the technical term kept as a secondary `.lever-tech` alias; rewrote help text out of raw-algorithm jargon ([mockups/recommendations-page.html:880](mockups/recommendations-page.html#L880)).
- Added `.lever-affects` lines naming the cards each lever governs, and made the preview note name the affected card (Mushroom-Gummies→Capsules Hold).
- Tagged the Studio header **"Admin · support view"** + reworded the subtitle to match the real support-view-only gating.
- Added a `.studio-actions-foot` caption disambiguating **"Save as live"** (engine tuning) from the per-card **"Mark as implemented"** (activation log).
- Deliberately framed the confidence-bar lever as **"works alongside the ≥20-co-orders deploy bar"** — NOT equating the 0–1 affinity floor with the ≥20-co-orders deploy tier (they're distinct gates).
**Review this:** the 6 scrutiny points — especially (3) the floor-vs-≥20 accuracy line and (2) whether the lever→card linkage names the right cards.
**Verification:** structural — new classes present (`.studio-admin-tag`, `.lever-tech`, `.lever-affects`, `.studio-actions-foot`), `<div>` balance OK; not rendered in a browser this turn — Reviewer asked to open it for a `behaviorally proven` basis + contrast re-sample.
**Open questions:**
- Is "Cross-sell confidence bar" the right plain-English name, or does it collide too much with the Deploy/Monitor/Hold "confidence" badge language (i.e. should it be "Cross-sell strength bar" to avoid implying it's the same thing as the badge)?
**Commit:** 79b7e1c

### Round 1 · Reviewer · Codex · 2026-06-15 18:36 PDT
**Verdict:** Approved
**Basis:** behaviorally proven — rendered `mockups/recommendations-page.html` in headless Chromium, inspected the Studio text/layout in-browser, re-sampled the small-text contrast from the rendered token values, and cross-checked the engine wording against `app/recommendations/nbp.py:77-83,107`, `app/api/routes/recommendations.py:189-197`, and `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:83-85,121,131-133`.
**Answers:**
- On the naming question: keep **"Cross-sell confidence bar."** The badge language stays local to rec status (`Deploy / Monitor / Hold`), while the lever help immediately frames this as a pair-strength filter, so I don't see a misleading collision in the rendered Studio (`mockups/recommendations-page.html:413-415`, `mockups/recommendations-page.html:882-883`).
**Findings & proposals:**
- [Pass] Vocabulary/altitude is aligned with the page. Both levers now lead with plain-English labels and demote the raw engine term to a secondary mono alias, which matches the rec-card voice instead of reintroducing jargon (`mockups/recommendations-page.html:882`, `mockups/recommendations-page.html:902`).
- [Pass] Lever-to-card linkage is visible and correct. The cross-sell lever points to the live Gummies→Tinctures card and the low-evidence Mushroom-Gummies→Capsules Hold card, and the restock lever points to the day-38 replenishment card the product brief describes (`mockups/recommendations-page.html:405`, `mockups/recommendations-page.html:646`, `mockups/recommendations-page.html:800`, `mockups/recommendations-page.html:895`, `mockups/recommendations-page.html:915`, `mockups/recommendations-page.html:922`; `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:83-85`, `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:131-133`).
- [Pass] The accuracy line is honest. The Studio says the affinity-floor lever **"works alongside"** the `≥20` deploy bar rather than equating them, which matches the engine split between `affinity_score` and the separate `co_order_count` evidence gate (`mockups/recommendations-page.html:883`; `app/recommendations/nbp.py:77-83`, `app/recommendations/nbp.py:107`; `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:84`, `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:121`).
- [Pass] Gating and verb disambiguation are clear without burying the Studio. The header/subtitle make the support-view restriction explicit, and the action-foot copy cleanly separates engine tuning from the per-card activation log (`mockups/recommendations-page.html:850`, `mockups/recommendations-page.html:855-856`; `app/api/routes/recommendations.py:189-197`; `app/ui/recommendations.py:221-233`).
- [Pass] No WCAG AA regression found in the sampled small text. In the browser probe, `.studio-admin-tag` rendered at roughly `13.07:1` on its warn chip, and the muted Studio helper text (`.lever-tech`, `.lever-affects`, `.studio-actions-foot`) stayed between roughly `12.66:1` and `16.97:1` on their surfaces.
**Commit:** none (operator requested no git; harness commits)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
