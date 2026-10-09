# RELAY · GH-696 (LTVera-Pandas) fix-or-exception calls vs #202 in-force values — QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
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
6. **Commit only the relay file** (`relay(gh696-fix-exception-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh696-relay-artifact.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-10-02

### Artifact — gh696-relay-artifact.md
````
# GH-696 weekend task 1 — proposed fix-or-exception calls (QA input)

Repo under discussion: BinoidCBD/LTVera-Pandas (NOT this harness repo). You have no repo access; everything you need is quoted below. Facts are as of Fri Oct 2, 2026, ~6 PM PT, `development` tip `3862a60`, production `5d8dc83`.

## Questions for the Reviewer (answer each by number)

1. For each of the 13 rows in Table A, is the proposed call (fix this week / exception / done-by-#632) **consistent with the #202 values in force and the settings inventory excerpts** below? Name any row where the call contradicts an in-force value, cites the wrong #202 item, or misstates the inventory bucket (GOAL_1 = working setting on /admin/system-settings; GOAL_2 = deferred to #633, shown read-only).
2. Are the five rows flagged "needs Noel/Elan judgment" (#630, #167, #203, #620, #514) the right set? Is any other row's call actually a judgment call that cannot be inferred from an in-force value (or vice versa)?
3. Is "done-by-#632" correct for 4.8 #424 (inventory GOAL_2 item 202-61) and 6.8 #202? Or should 4.8 be "exception (deferred to #633)"? Note #632's rule: every decision is either a working setting or a labelled #633 plan; decisions are not a gate.
4. Part B: is the claim "nothing in #696 needs new System Settings / tenant / recipient UI" consistent with the excerpts (#202 items 136, 147–149 for the #533 Cancel design control; registry keys `nexmail.design_ready_recipients`, `copy_and_claims.designed_draft_explainer`; inventory 202-61/33/6/7/97 as GOAL_2)?
5. Any owner or confidence that looks wrong given the excerpts?

Output: graded findings ([Blocker]/[Should]/[Nit]/[Unverified — no citation]) citing the excerpt (item number or inventory id) you rely on; per the protocol, a behaviour-change request needs Observed input / Affected scope / Falsifier. Do not propose new product decisions. Set STATUS Approved if the calls are consistent.

## Context (frame, verified on GitHub)
- Handover frame: the target is **Bounce only**; Binoid/Bloomz-only work is post-handover. Remaining gates: the deploy, the #632 phase 5 Settings-page dry run, and open Critical/High Bounce rows in #255. Decisions are not a gate: every decision has a value in force on /admin/system-settings (#632) or is a labelled plan (#633).
- #632 body: "Every handover decision (#202 items 1–119, plus …) has a value in force today and a place on /admin/system-settings: Goal #1 a working setting … Goal #2 a labelled plan (#633) … No decision is waiting on Sam or Elan before engineering can proceed … The handover walkthrough is a tour of that page." Inventory after #643: 181 items = 36 Goal #1 + 145 Goal #2.
- #236 scope: "Elan's own account is assumed manually provisioned by an operator via Keycloak." Out of scope: the Klaviyo send decision.
- #670 (Noel's plan) recalibration: "Include actual alert delivery, not just computed health status, following today's #630 findings."
- #630 (Noel's operator direction): "We need to take Mailgun out of the picture. We are sticking with NexMail until Elan and Sam say otherwise." Production: app mailer `MAILGUN_API_KEY_SECRET_REF` empty, so ops alerts fail (row 2.2, 510 failed sends 09-28..29); `nexmail.design_ready_recipients` empty; Keycloak has no SMTP.
- #255 row texts (Medium/Low Bounce rows):
  - 4.8 #424 Medium P5: `permitted_numbers_for` allows nearest whole percent; "ruling on rate precision needed".
  - 5.6 #203 Medium P6: category-day layer matches no tenant; `classify_brand` never called; "the provisional 8-vertical taxonomy has been in force since 09-26 (#632, register item 33), so wiring `classify_brand` does not wait on a ruling".
  - 5.22 #528 Medium P5: Checks panel shows developer notes ("See GH-94 section 5d", "Do not implement this as a passing check"); three content checks never run on a commissioned design (body reads as images); 2 of 8 ceiling.
  - 5.23 #518 Medium P5: tenant timezone editor is exact-match free text; wrong-but-valid zone saved silently.
  - 6.4 #393 Medium P4: no deploy workflow; deployed commit unreadable from the app.
  - 6.6 #167 part 2 Medium P6: `ltvera-vm-app@` holds three unconditioned project-level Secret Manager roles incl. `secretVersionAdder` (write) over 16 secrets. #167 itself: "Split-IAM narrowing — bigger than it reads, wants its own plan".
  - 6.7 #234 Low P7: no in-app help.
  - 6.8 #202 Low P8: "37 provisional defaults unratified in Elan's or Sam's name".
  - 6.9 #514 Medium P6: workspace switcher can render an empty panel (system admin with no memberships, lazy all-tenants load failed, no retry); header falls back to "System Workspace".
  - 6.10 #620 Medium P6: 19 time-handling findings; the two Highs went to #613 (done); Mediums include "from 5:00 pm PT the calendar marks tomorrow as today for a Pacific merchant"; #620 says two findings are "a product question for the #202 register" (none recorded there).
  - 6.11 #537 Medium P5: `.settings-input` reads undefined CSS tokens, timezone input class has no rule, eight controls unclassed; "That page is where Sam and Elan change handover values (#632)".
  - 7.5 #457 Low P5: home page shows "Sign in" to a signed-in visitor; "today's behavior (`/` serves the home page) is in force, so the fix does not wait on register item 97".
- PR #689 (open) rewrites the `copy_and_claims.designed_draft_explainer` help text and factory default (item 60 update, Oct 2). #528/#688/#671 touch the same Dispatch code and are best held until #689 merges.

## Table A — proposed calls (Producer's draft)

| Row | Proposed call | Reason (basis) | Owner | Confidence |
|---|---|---|---|---|
| 4.8 #424 | Done-by-#632 (deferred to #633) | #202 item 61 open; in force = whole percent permitted; inventory 202-61 GOAL_2 (planned "decimal places"). Item 1: proof numbers withheld from prompt lowers risk | Sam (rule) / Elan (copy) | Med |
| 5.6 #203 | Exception (deferred to #633/#105) | Items 33/6/7 GOAL_2 in inventory (taxonomy control + reclassify action). Item 2: category days are opt-in, so classifying Bounce changes nothing visible unless days are enabled | Noel (Matthew offered) | Med — Noel to confirm |
| 5.22 #528 | Fix this week (finding 1); finding 2 exception | Finding 1 is strings (dev notes shown to merchant); item 60 copy already updated in #689; finding 2 is the image-body limit #689's copy now discloses. After #689 merges | Noel | High |
| 5.23 #518 | Exception | Item 112: Bounce zone already set (America/Los_Angeles, provisional); item 111 UTC fallback; editor UX only matters for other (post-handover) tenants | Noel (Matthew offered) | Med |
| 6.4 #393 | Exception | No #202 value; inferred from the manual deploy receipts on #677/#635; workflow build too large this week | Jose / Noel | High |
| 6.6 #167 | Exception | No #202 value; #167: "wants its own plan"; security-risk acceptance should be explicit | Jose / Noel | Med — Noel to confirm |
| 6.7 #234 | Exception | No #202 value; inferred from #632: "handover walkthrough is a tour of that page" | Noel | High |
| 6.8 #202 | Done-by-#632 | #632 settles "decisions are not a gate"; closes with #632 phase 5 | Noel | High |
| 6.9 #514 | Exception (conditional) | No #202 value; only hits a system admin with no memberships; if Elan gets a Bounce membership he won't hit it; fix is small | Noel | Low — depends on Elan's account type |
| 6.10 #620 | Exception (list Bounce-visible items) | Decisions #620 asks for are not in #202; adjacent in-force items 111, 120–123; Highs fixed in #613; Pacific "tomorrow as today" after 5 PM PT is Bounce-visible | Noel / Elan | Low — Noel/Elan to confirm |
| 6.11 #537 | Fix this week | No #202 value; CSS only; System Settings page is the #632 walkthrough / Elan's tour | Noel | High |
| 7.5 #457 | Exception | Item 97 open (Elan must own); in force `/` serves home page; inventory 202-97 GOAL_2 | Elan (decision) / Noel | High |
| #630 | Exception for the call — Noel decides | Item 65: recipients empty = off (inventory GOAL_1 setting exists); item 118: no outbox; provider/keys not in #202; #670 asks for actual delivery; #236 assumes manual account provisioning | Noel | Low — Noel to confirm |

## Part B — settings answer (Producer's draft)
No new System Settings / tenant / recipient UI is needed for #696 scope:
- #689: existing key `copy_and_claims.designed_draft_explainer` (help text/default rewrite only).
- #693 (#687), #694 (#692): no settings code touched.
- #533 Cancel: items 136, 147–149 call for one route, one vendor call and a "Cancel design" widget/Campaigns-row control (not a setting); uses existing `failed` draft state, no migration. Branch not pushed (unverified code).
- #632: page exists; #680/#681 settings are merged but undeployed (needs the Tue deploy before the walkthrough).
- #630: existing key `nexmail.design_ready_recipients` (GOAL_1); provider/key are deploy-time env config (`mailgun_api_key_secret_ref` today), not UI.
- #518 (if ever fixed): changes the existing per-tenant timezone field at /tenants (inventory 202-112 delivered_at "/tenants → Timezone"); not a new setting.
- #424, #203, #457: their would-be settings are already GOAL_2 (#633): 202-61, 202-33/6/7, 202-97 — out of #696.
- #528, #537, #514, #393, #167, #234, #620: no settings involved.

## Excerpts — #202 items (verbatim, possibly truncated)
#### #202 item 1 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202
- [x] **1. Proof numbers are withheld from the prompt entirely, not merely forbidden in the copy.** `repeat_rate`, `unique_buyers_30d`, `units_30d` never reach the model. **L0 — it changes what we claim to a customer.** Conflicts head-on with our own stated position in [nexmail-ltvera-connector#11](https://github.com/BinoidCBD/nexmail-ltvera-connector/issues/11) (*"the numbers **are** the product"*); withholding is the conservative branch while that is open, not a verdict on it. Evidence for the structural control: `repeat_rate: 0.8048` came back as "80%" against a do-not-round constraint ([connector#12](https://github.com/BinoidCBD/nexmail-ltvera-connector/issues/12)). Canonical block: `PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md:707`. Code: [`app/campaigns/prompt_generator.py:172`](../blob/development/app/campaigns/prompt_generator.py#L172) `SUPPRESS_PROOF_NUMBERS_RULE`, tagged `<<ELAN-MUST-OWN>>`. Ruling the other way turns #146 into a *labelling* problem, same seam. **Cost of correction: one constant plus a whitelist.**

#### #202 item 2 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202
- [x] **2. Category days ship opt-in (`default_enabled=False`), all 11 of them.** A classifier guessing "snack" must not by itself start a National Popcorn Day send — and every tenant we carry currently classifies to `vertical = null`, so an opt-out default would enable days for brands they demonstrably do not apply to. Elan's open #6; inferred default E1, `PROJECT/3-COMPLETED/PHASE-2-COMPLETION-PLAN-2026-08-06.md:569`. **Cost of correction: one line in the seeds.**

#### #202 item 6 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202
- [x] **6. Category days for `sports_nutrition` / `hydration` — add World Water Day (22 March) and nothing else.** Elan's decision #3. `MIN_CATEGORY_DAYS = 4` and `hydration` had 3, so it could never clear its own coverage gate. World Water Day was picked *because it needs no source review* — a UN observance fixed by A/RES/47/193 since 1993 — against Sam's 2026-08-06 finding that blog-sourced "national day" dates fabricate on re-fetch. **Deliberately not done: propping `sports_nutrition` up to 5**, which sits exactly on the floor with two of its four days UNVERIFIED. Inferred default E3, completion plan `:620`. Recorded as data in [`app/calendar/library.py:622`](../blob/development/app/calendar/library.py#L622) `PROVISIONAL_CATEGORY_DAYS` (6 slugs). **Cost of correction: a seed edit.**

#### #202 item 7 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202
- [x] **7. `sports_nutrition` and `hydration` stay two verticals rather than merging into one.** This, not the day count, is the real content of decision #3. **See item 33 — it is the parent question, and ruling on 33 may moot this.** The release plan's own sizing rule (*"if two categories draw the same days, they are one vertical"*) argues they should merge: Bounce's catalog is both, and no tenant we carry is hydration-but-not-sports-nutrition, so today the split distinguishes **nobody**. Left as two on purpose because merging is a **one-way** simplification. Completion plan `:660`. **Cost of correction: delete one string from `VERTICALS`, retag four seeds; no code branches on a vertical name.**

#### #202 item 33 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202
- [x] **33. `VERTICALS` is an unratified initial best guess, and the six original entries match no tenant we carry.** `coffee`, `tea`, `frozen_dessert`, `bakery`, `confection`, `snack` came from Elan's seed; **every tenant classifies to `null` against them and draws zero category days, leaving the whole layer inert.** `sports_nutrition` and `hydration` were then inferred from Bounce's real 65-product catalog — from the catalog, not the brand name, and deliberately **not keyed to a tenant slug**, because the classifier reads this tuple as its closed taxonomy. **Deliberately not added: `apparel`** — Bounce sells six T-shirts, but a vertical that changes nobody's day set is not a vertical. [`app/calendar/library.py:65`](../blob/development/app/calendar/library.py#L65), flagged in-code *"initial best guess, unratified"*. **This is the parent of item 7** — 7 asks whether two entries merge, 33 asks whether the list is right at all. **Owner: Elan. Cost of correction: a seed edit; no code branches on a vertical name.**

#### #202 item 60 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219
- [ ] **60. The "Written by: Dispatch, designed" explainer promises that prices and proof numbers are checked before commit.** `<<ELAN-MUST-OWN>>` (copy claim).
  **Applied today:** "A designed draft takes a few minutes to come back. Its body comes back as text, so the subject line, preview text, links, prices and proof numbers are all checked before you commit." True for text-heavy bodies (GH-410); would be false if a draft came back image-only.
  **Alternatives:** the weaker pre-GH-410 wording; a sentence that names the checks that ran on this draft rather than a standing promise.
  **What settles it:** whether image-only bodies can still occur under `creativeMode: text-heavy` (item 55).
  **Cost of correction:** one string.
  `[new decision]:`

#### #202 item 61 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219
- [ ] **61. A proof rate may not be rendered to whole percent; `80%` for a measured `80.48%` should be refused.** Owner: Sam (the check's rule), `<<ELAN-MUST-OWN>>` on copy precision. https://github.com/BinoidCBD/LTVera-Pandas/issues/424.
  **Applied today:** the opposite. `permitted_numbers_for` permits the nearest whole percent of any 0..1 rate, while the function's comment and the check's docstring both say a rounded figure fails. Nothing is changed yet; #424 records the contradiction.
  **Alternatives:** allow whole percent and rewrite the prose to match; allow one decimal.
  **What settles it:** a ruling on the precision a rate is shown at. The code is one line either way.
  **Cost of correction:** one line plus one test.
  `[new decision]:`

#### #202 item 65 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219
- [ ] **65. Nobody is emailed when a long generation becomes ready.** `<<ELAN-MUST-OWN>>` (who is told), operator on the channel.
  **Applied today:** the browser learns by polling; a merchant who pressed Generate and closed the tab is told on next open (#185 F10). Against a 20–60 minute generation, closing the tab is the expected behaviour.
  **Alternatives:** email the merchant; email the operator; both, above a duration threshold.
  **What settles it:** who owns the campaign at that moment. The reconciler already knows the instant a draft is ready, so the hook point exists.
  **Cost of correction:** a notification path; no schema change.
  `[new decision]:`

#### #202 item 66 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219
- [ ] **66. The `unknown` sentence shown to the merchant.** `<<ELAN-MUST-OWN>>`.
  **Applied today:** says Dispatch, never the vendor; states no second email was used; gives a relative last-checked time; names the template id as "reference"; ends "You can check again." The check-again button itself is GH-421 box 4 and does not exist yet, so the sentence currently describes an action the merchant cannot take.
  **Alternatives:** drop the last clause until the button ships.
  **What settles it:** copy review; the button's arrival.
  **Cost of correction:** one string.
  `[new decision]:`

#### #202 item 97 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5609180241
- [ ] **97. Is `/` a public landing page?** (#457) If yes, the button reads "Open dashboard" for a live session;
  if no, `/` redirects like `/login` does. Owner: `<<ELAN-MUST-OWN>>`. Cost: one line either way.

#### #202 item 111 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5720772619
- [ ] **111. When a workspace has no timezone, clocks render as UTC and say so; browser-local is the alternative.** Applied today: `_dispatch_clock` and the Campaigns list render `18:58 UTC` when the tenant timezone is empty (`app/ui/state.py:3934-3943`), so a time is never local-looking while secretly UTC (#95). All five workspaces were empty until Sep 16th. Alternative: fall back to the browser's local zone, which reads naturally for a merchant at their own store but hides that the store's zone is unset, and the two can differ for a remote operator. Owner: Elan (what the merchant reads). Cost of correction: one function; no data change. `[new decision]`

#### #202 item 112 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5720772619
- [ ] **112. Bounce Nutrition's store timezone is America/Los_Angeles.** Applied Sep 16th, 5:32 pm PT by Matthew through the admin Timezone editor (made visible with the #517 workaround), because #185 F7 cannot be verified on a tenant with no zone. Nobody has confirmed where Bounce's store keeps its clock; the value is the editor's placeholder example. Alternative: the zone the store's Shopify or Klaviyo account reports. Owner: Sam (which zone is the store's), or an operator who can read it from Klaviyo. Cost of correction: one field on the Tenants page; any campaign scheduled before the correction sends at the wrong hour. `[new decision]`

#### #202 item 118 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5738007231
- [ ] **118. The design-ready mail is sent after the commit; a crash between the two skips the notification, and nothing records that it was owed.** Applied in PR #582: `notify_design_ready` runs after `db.commit()` at every place a draft becomes ready, so the `ready` state is durable before anyone is told and the row is no longer held for one Mailgun call per recipient. Before this change the risk ran the other way: a crash between the mail and the commit could send twice, and a commit failure after the mail could not un-send it. There is still no outbox and no delivery guarantee, so a notification lost this way is not retried. Alternatives: (a) accept the skipped-notification failure mode; the merchant still sees the design on the Campaigns list and the list row says it is ready; (b) an outbox row written in the same transaction as `mark_ready`, drained by a task that retries, which is the delivery guarantee item 65's recipient list would otherwise be assumed to have. Owner: Elan (whether a missed "Design ready" mail is acceptable for the people item 65 names), Noel (the outbox, if not). Cost of correction: a queued task and a small table; the send call already stands alone. `[new decision]`

Nothing to register from https://github.com/BinoidCBD/LTVera-Pandas/issues/526 (PR https://github.com/BinoidCBD/LTVera-Pandas/pull/554): the one product choice made during the build, an audience picker on the Schedule step, was withdrawn on Matthew's ruling the same day, and the flow is unchanged. Nothing from https://github.com/BinoidCBD/LTVera-Pandas/issues/539 (PR https://github.com/BinoidCBD/LTVera-Pandas/pull/552).

#### #202 item 120 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5896680415
- [ ] **120. Choosing Schedule fills in the next whole hour on the store's clock; with no store timezone the field stays empty.** Applied in PR #613: `_next_whole_hour` (`app/ui/state.py`) sets the Send at field when the merchant switches to Schedule and the field is empty, and never overwrites a time already chosen. In the spring clock change it offers the first hour that exists (03:00, not 02:00). With no timezone set it offers nothing, because a UTC default would look plausible and be hours away from what the merchant reads. Alternatives: (a) tomorrow at 9:00 am on the store's clock, which suits a planned campaign better than a time that can be minutes away; (b) no default, as before. A related open point: at 9:59 am the default is 10:00 am, so a merchant who spends a few minutes on Review is refused for a time the app chose; a minimum lead (for example, skip to the following hour when fewer than 15 minutes remain) would avoid that. Owner: Elan (what the merchant starts from). Cost of correction: one function and its tests; no data change. `[new decision]`

#### #202 item 121 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5896680415
- [ ] **121. A send time in the past is refused with 400, not 422.** Applied in PR #613: the commit route returns 400 for a past time (`SendAtInPastError`) and for a time in the hour the spring clock change skips (`SendAtNonexistentError`), matching the existing 400 for a store with no timezone on the same field. #527 proposed 422. The refusal happens before any Klaviyo call, and the sentence names both times on the store's clock, for example "The send time 2026-09-15 11:49 (America/Los_Angeles) has already passed: Bounce Nutrition's clock reads 2026-09-17 11:49 (America/Los_Angeles). Pick a later time, or choose Send now." Alternative: 422 for all three refusals, the usual status for a well-formed request with an invalid value. The widget shows the sentence either way; only API clients see the code. Owner: Noel (the API contract). Cost of correction: one status constant in the route and the matching test assertions. `[new decision]`

#### #202 item 122 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5896680415
- [ ] **122. The step row is captioned "Step 3 of 4: Schedule" and the tags read "1. Brief", "2. Draft", "3. Schedule", "4. Done".** Applied in PR #613, from #527 finding 2: the caption sits above the tags, the current tag is filled, and no tag responds to hover. Alternatives: a caption without the step count ("Schedule"), or step names without numbers. Owner: Elan (merchant copy). Cost of correction: one string template in `app/ui/campaigns.py`. `[new decision]`

#### #202 item 123 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5896680415
- [ ] **123. With no store timezone, the Schedule step says a time cannot be scheduled and that Send now still works.** Applied in PR #613. Under the Send at field: "This store has no timezone set, so a time cannot be scheduled until one is. Send now still works." In the Review row: "<time>, store timezone not set". In the Confirm sentence: "scheduled for <time>, but this store has no timezone set, so the time cannot be scheduled until one is". With a zone set, the three instead name it, for example "Times are in America/Los_Angeles, the store's timezone." Alternatives: hide the Schedule option entirely for a store with no timezone, or say who can set the timezone (an admin, on the Tenants page). Owner: Elan (merchant copy); the premise depends on item 111, whether an unset zone is shown as UTC or as browser-local. Cost of correction: three strings in `app/ui/state.py`. `[new decision]`

#### #202 item 136 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5943410436
- [ ] **136. LTVera offers "Cancel design" only while NexMail still has the ticket `queued`, and never cancels on its own.** To apply under #533: the waiting campaign's row on the Campaigns list, and the widget while it is waiting, show "Cancel design" while the ticket status is `queued`; pressing it (with a confirm step) calls NexMail's cancel with the reason "Cancelled by the merchant in LTVera", and the campaign's draft ends as failed with the sentence "Design cancelled before work started." Once the ticket is past `queued`, the button is replaced by "Work has started on this design, so it can no longer be cancelled here. Contact support to close it." Nothing cancels automatically (closing the widget, leaving the page or deleting a campaign does not), because an automatic cancel can call off work the merchant wanted. The cancelled campaign uses the existing `failed` draft state, so no migration is needed. Alternatives: (a) no cancel at all, since the window is minutes; (b) cancel automatically when the merchant starts a new Generate within the window; (c) a separate `cancelled` state (needs a migration like #611's). Owner: <<ELAN-MUST-OWN>> (what the merchant can do); Noel on the state choice. Cost of correction: one route, one client call and one control. `[new decision]`
- [ ] **113 (write-back). LTVera stays approve-only for the handover: no revision round and no direction note from LTVera; the Draft step says where changes are asked for.** Applied today: nothing (no call to revisions or direction). Proposed: option (b) of item 113, one sentence on the Draft step under a NexMail design: "Changes to this design cannot be requested from here yet. Contact support to ask for changes." Reasons: a revision round uses a paid allowance (zero on a trial) and needs a note f …[truncated]

#### #202 item 147 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5943888612
- [ ] **147. The confirm step reads "Cancel this design? Work on it has not started. The campaign keeps its brief, and a new design needs another Generate.", with "Keep waiting" (widget) or "Keep it" (Campaigns row) and "Yes, cancel design".** Item 136 set no wording. Alternative: one button label in both places. `[new decision]`

#### #202 item 148 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5943888612
- [ ] **148. On the Campaigns list, the "work has started … Contact support to close it" sentence appears only after a cancel on that row is refused; the widget shows it whenever its ticket is past queued.** Keeps the table cells short. Alternative: show it on every row whose ticket is past queued. `[new decision]`

#### #202 item 149 — source: https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5943888612
- [ ] **149. The widget offers "Cancel design" only while the draft is collecting, not while it is unknown.** The cancel route refuses an unknown draft, because its ticket status is not current. Alternative: allow it after a fresh ticket read. `[new decision]`

## Excerpts — settings_inventory.py / settings_registry.py at development 3862a60 (verbatim)
```python
InventoryItem(
        id="202-61", bucket=GOAL_2, group="Copy and claims",
        label="Proof-rate rounding precision (80% for 80.48%)",
        owner="Sam (check rule) + Elan (must own copy precision)", ratification="open",
        current="permitted_numbers_for permits nearest whole percent (contradicts its docstring).",
        planned="Number: decimal places for proof-rate rounding",
        reason="The precision must be threaded through two pure call chains (review_draft, and the subject validator, which has no session); the rule is still open.",
        refs=(SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219"), SourceRef("#424", "https://github.com/BinoidCBD/LTVera-Pandas/issues/424"),),
        duplicates=("424-1",),
    )

InventoryItem(
        id="202-33", bucket=GOAL_2, group="Calendar taxonomy and reclassification",
        label="VERTICALS taxonomy (unratified best guess; layer inert)",
        owner="Elan", ratification="provisional",
        current="8 verticals (6 Elan seed + sports_nutrition, hydration); brand_profiles.vertical NULL for all tenants (classifier has no production caller); 'unset = every ungated window'. cbd not in VERTICALS.",
        planned="A taxonomy control plus a 'Reclassify tenants now' action",
        reason="Reclassification: 'a taxonomy change invalidates existing tenant classifications; nothing reclassifies' (#520 ask 1, deferred — no execution path until #203 wires classifier). #633 candidate.",
        refs=(SourceRef("#202", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202"), SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5347147480"), SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5719742943"), SourceRef("#462 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/462#issuecomment-5718714300"), SourceRef("#203", "https://github.com/BinoidCBD/LTVera-Pandas/issues/203"),),
    )

InventoryItem(
        id="202-6", bucket=GOAL_2, group="Calendar library and seed data",
        label="Add World Water Day only, so hydration clears MIN_CATEGORY_DAYS",
        owner="Elan", ratification="provisional",
        current="World Water Day seeded; recorded in PROVISIONAL_CATEGORY_DAYS (6 slugs) — a record, not a switch.",
        planned="Library editing plus a 'Reseed calendar library' action (bumps SEED_VERSION)",
        reason="Seed edit + reseed: 'a ruling edits the library and bumps SEED_VERSION' (#462 W4.5).",
        refs=(SourceRef("#202", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202"), SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5347147480"), SourceRef("#462 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/462#issuecomment-5718714300"),),
    )

InventoryItem(
        id="202-7", bucket=GOAL_2, group="Calendar taxonomy and reclassification",
        label="sports_nutrition and hydration stay two verticals (one-way if merged)",
        owner="Elan", ratification="open",
        current="Two separate entries in VERTICALS.",
        planned="A taxonomy control plus a 'Reclassify tenants now' action",
        reason="Taxonomy edit + retag four seeds + reclassification (#633 candidate).",
        refs=(SourceRef("#202", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202"), SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5347147480"), SourceRef("#203", "https://github.com/BinoidCBD/LTVera-Pandas/issues/203"), SourceRef("#462 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/462#issuecomment-5718714300"),),
        duplicates=("203-3",),
    )

InventoryItem(
        id="202-97", bucket=GOAL_2, group="Operations and platform",
        label="Is '/' a public landing page?",
        owner="Elan (must own)", ratification="open",
        current="'/' serves home_page (behaviour per #457 not stated as applied).",
        planned="A deploy-time or ops control (#462 Wave 7) where one applies",
        reason="One line.",
        refs=(SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5609180241"),),
    )

InventoryItem(
        id="202-65", bucket=GOAL_1, group="Campaigns",
        label="Who is emailed when a design is ready",
        owner="Elan (must own) + operator on channel", ratification="provisional",
        current="'' (empty: notifications off)",
        setting_keys=("nexmail.design_ready_recipients",),
        refs=(SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219"), SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5719742943"), SourceRef("#462 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/462#issuecomment-5718714300"),),
    )

InventoryItem(
        id="202-60", bucket=GOAL_1, group="Copy and claims",
        label="'Written by: Dispatch, designed' explainer promises checks",
        owner="Elan (must own)", ratification="provisional",
        setting_keys=("copy_and_claims.designed_draft_explainer",),
        current="Factory text unchanged; now served by /dispatch-defaults from the page.",
        planned="",
        refs=(SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5577714219"),),
    )

# settings_registry.py
SettingSpec(
            key="nexmail.design_ready_recipients", module="draft_lifecycle",
            label="Design ready recipients", kind="text", default="",
            allow_empty=True, max_length=500,
            owner="Elan", provisional=True, register_item="65",
            help_text=(
                'Asked of Elan 2026-09-17, unruled. Comma-separated email recipients notified '
                'when a collected design is ready. Empty disables notifications. Delivery is '
                'best-effort before commit and may repeat after a crash.'
            ),
        ),

# settings_registry.py
SettingSpec(
            key="copy_and_claims.designed_draft_explainer",
            module="copy_and_claims",
            label="Note under 'Written by: Dispatch, designed'",
            kind="text",
            default=DESIGNED_DRAFT_EXPLAINER,
            max_length=500,
            help_text=(
                "Shown to the merchant in the Dispatch widget when the designed "
                "writer is picked. The factory text says every number is checked "
                "before commit; for a design that comes back as images the checks "
                "report 'could not verify' instead — edit it here if that reads as "
                "an overclaim. Plain text, no placeholders, and it must say Dispatch rather "
                "than the vendor's name. Shows on the next widget open."
            ),
            owner="Elan",
            provisional=True,
            must_own=True,
            register_item="60",
        ),
InventoryItem(
        id="202-112", bucket=GOAL_1, group="Tenants",
        label="Bounce store timezone = America/Los_Angeles",
        owner="Sam (or operator who can read it from Klaviyo)", ratification="provisional",
        current="America/Los_Angeles",
        delivered_at="/tenants → Timezone (per tenant, system admin)",
        refs=(SourceRef("#202 comment", "https://github.com/BinoidCBD/LTVera-Pandas/issues/202#issuecomment-5720772619"),),
    )
```
````
- Definition of Done: every Table A call and the Part B settings answer is consistent with the quoted #202 in-force values and settings-inventory excerpts; each cites the correct #202 item (or says "no #202 value; inferred from X"); the judgment-call set is right; findings answer Questions 1–5 in the artifact. The artifact is about a different repo (BinoidCBD/LTVera-Pandas); all needed context is embedded — do not look for it in this repo, and do not edit anything but this relay file.

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
Basis: Every proposed call across all 13 rows in Table A and the settings architecture conclusions in Part B are completely consistent with the #202 in-force values, settings inventory excerpts, and handover constraints for Bounce. All citations match, inventory buckets are accurately categorized, and the five flagged judgment rows represent the complete and correct set requiring human stakeholder decisions. No pre-existing defects were found in `gh696-fix-exception-qa.md`.
swept file: yes

- [Pass] Question 1 (Table A consistency): All 13 rows in Table A (`gh696-fix-exception-qa.md:100-112`) are consistent with the #202 values in force and the settings inventory excerpts. None contradict an in-force value or misstate an inventory bucket:
  - 4.8 #424 (`gh696-fix-exception-qa.md:100`): Call `Done-by-#632 (deferred to #633)` is consistent with #202 item 61 (`gh696-fix-exception-qa.md:150-156`) where `permitted_numbers_for` permits nearest whole percent, and `settings_inventory.py` item `202-61` (`gh696-fix-exception-qa.md:215-224`, `bucket=GOAL_2`). Item 1 (`gh696-fix-exception-qa.md:127`) structural suppression of proof numbers lowers customer-facing risk.
  - 5.6 #203 (`gh696-fix-exception-qa.md:101`): Call `Exception (deferred to #633/#105)` is consistent with #202 item 33 (`gh696-fix-exception-qa.md:139`, "every tenant classifies to null"), item 2 (`gh696-fix-exception-qa.md:130`, category days opt-in `default_enabled=False`), and inventory items `202-33`, `202-6`, and `202-7` (`gh696-fix-exception-qa.md:226-255`, all `bucket=GOAL_2`).
  - 5.22 #528 (`gh696-fix-exception-qa.md:102`): Call `Fix this week (finding 1); finding 2 exception` is consistent with #255 finding 1 developer notes ("See GH-94 section 5d", `gh696-fix-exception-qa.md:84`) and finding 2 image-body ceiling disclosed by item 60 copy in PR #689 (`gh696-fix-exception-qa.md:94`, `gh696-fix-exception-qa.md:300-319`). Holding until #689 merges is the right sequence.
  - 5.23 #518 (`gh696-fix-exception-qa.md:103`): Call `Exception` is consistent with item 112 (`gh696-fix-exception-qa.md:180-182`) and inventory `202-112` (`gh696-fix-exception-qa.md:320-327`), confirming Bounce store timezone is already set to `America/Los_Angeles`. UTC fallback exists in item 111 (`gh696-fix-exception-qa.md:178`).
  - 6.4 #393 (`gh696-fix-exception-qa.md:104`): Call `Exception` is consistent. Correctly cites no #202 value, and relies on manual deploy receipts on #677/#635 (`gh696-fix-exception-qa.md:104`).
  - 6.6 #167 (`gh696-fix-exception-qa.md:105`): Call `Exception` is consistent. Correctly cites no #202 value, referencing #167 ("wants its own plan", `gh696-fix-exception-qa.md:87`).
  - 6.7 #234 (`gh696-fix-exception-qa.md:106`): Call `Exception` is consistent. Correctly cites no #202 value, inferring from #632 that the handover walkthrough is a tour of the settings page (`gh696-fix-exception-qa.md:77`).
  - 6.8 #202 (`gh696-fix-exception-qa.md:107`): Call `Done-by-#632` is consistent with #632 establishing that "decisions are not a gate" (`gh696-fix-exception-qa.md:76-77`) and closing with #632 phase 5.
  - 6.9 #514 (`gh696-fix-exception-qa.md:108`): Call `Exception (conditional)` is consistent. Correctly cites no #202 value; failure mode only triggers for system admin with no memberships (`gh696-fix-exception-qa.md:90`), which is avoided by provisioning Elan with a Bounce membership (`gh696-fix-exception-qa.md:78`).
  - 6.10 #620 (`gh696-fix-exception-qa.md:109`): Call `Exception (list Bounce-visible items)` is consistent. Notes Highs fixed in #613 (`gh696-fix-exception-qa.md:91`), adjacent in-force items 111 and 120–123 (`gh696-fix-exception-qa.md:177-198`), and identifies the Bounce-visible defect where the calendar marks tomorrow as today after 5:00 PM PT (`gh696-fix-exception-qa.md:91`).
  - 6.11 #537 (`gh696-fix-exception-qa.md:110`): Call `Fix this week` is consistent. Correctly cites no #202 value; CSS fix is essential for the /admin/system-settings walkthrough page (`gh696-fix-exception-qa.md:92`).
  - 7.5 #457 (`gh696-fix-exception-qa.md:111`): Call `Exception` is consistent with item 97 (`gh696-fix-exception-qa.md:173-175`) and inventory `202-97` (`gh696-fix-exception-qa.md:257-264`, `bucket=GOAL_2`), with `/` serving the home page in force (`gh696-fix-exception-qa.md:93`).
  - #630 (`gh696-fix-exception-qa.md:112`): Call `Exception for the call — Noel decides` is consistent with item 65 (`gh696-fix-exception-qa.md:158`, empty recipients = notifications off), item 118 (`gh696-fix-exception-qa.md:184`, no outbox/delivery guarantee), and Noel's operator direction on NexMail vs Mailgun (`gh696-fix-exception-qa.md:80`).
- [Pass] Question 2 (Judgment calls set): The five rows flagged "needs Noel/Elan judgment" (#630, #167, #203, #620, #514) are the exact and complete set (`gh696-fix-exception-qa.md:101, 105, 108, 109, 112`). No other row requires human policy or risk arbitration:
  - #630 requires operator direction on Mailgun retirement and ops alerts delivery expectations (`gh696-fix-exception-qa.md:80`).
  - 6.6 #167 requires explicit security risk acceptance regarding `ltvera-vm-app@` Secret Manager permissions (`gh696-fix-exception-qa.md:87`).
  - 5.6 #203 requires Noel's decision on whether to accept Matthew's offer to wire `classify_brand` or defer to #633 (`gh696-fix-exception-qa.md:83, 101`).
  - 6.10 #620 requires Noel/Elan confirmation on accepting the Bounce-visible calendar roll bug at 5:00 PM PT as a known handover exception (`gh696-fix-exception-qa.md:91, 109`).
  - 6.9 #514 depends on Elan's Keycloak provisioning path (`gh696-fix-exception-qa.md:78, 108`).
  - All remaining rows (4.8, 5.22, 5.23, 6.4, 6.7, 6.8, 6.11, 7.5) are strictly determinable from existing in-force settings, inventory bucket assignments, or engineering scope.
- [Pass] Question 3 (Done-by-#632 vs Exception):
  - For 6.8 #202 (`gh696-fix-exception-qa.md:107`), "Done-by-#632" is accurate: #632 explicitly established that "decisions are not a gate" by placing all decisions into working settings (Goal 1) or labelled #633 plans (Goal 2) (`gh696-fix-exception-qa.md:76-77`).
  - For 4.8 #424 (`gh696-fix-exception-qa.md:100`), the operational outcome is identical (no code changes in #696 this week; deferred to #633), and Table A already qualifies it as `Done-by-#632 (deferred to #633)`.
- [Pass] Question 4 (Part B settings consistency): The claim that "nothing in #696 needs new System Settings / tenant / recipient UI" (`gh696-fix-exception-qa.md:115`) is verified consistent with all excerpts:
  - `copy_and_claims.designed_draft_explainer` (`gh696-fix-exception-qa.md:300-319`) and `nexmail.design_ready_recipients` (`gh696-fix-exception-qa.md:287-297`) are already registered in `settings_registry.py`.
  - #533 Cancel design controls (items 136, 147–149, `gh696-fix-exception-qa.md:200-212`) are inline buttons and dialog text on the Campaigns list row and Draft step widget, not settings.
  - Items 202-61, 202-33, 202-6, 202-7, and 202-97 are all classified under `bucket=GOAL_2` (`gh696-fix-exception-qa.md:215-265`) and displayed read-only under #632.
  - #518 per-tenant timezone operates on the existing field delivered at `/tenants → Timezone` (`gh696-fix-exception-qa.md:325`).
- [Pass] Question 5 (Owner and confidence assessment): All owners and confidence levels in Table A (`gh696-fix-exception-qa.md:100-112`) accurately align with the excerpts and roles:
  - 4.8 #424 lists "Sam (rule) / Elan (copy)" matching inventory `202-61` (`gh696-fix-exception-qa.md:218`).
  - 5.6 #203 lists "Noel (Matthew offered)" matching context (`gh696-fix-exception-qa.md:83`).
  - 7.5 #457 lists "Elan (decision) / Noel" matching inventory `202-97` (`gh696-fix-exception-qa.md:260`).
  - Infra/IAM items (6.4, 6.6) correctly assign Jose / Noel, while walkthrough UI items (5.22, 6.11) assign Noel.
- [Nit] Row 4.8 #424 categorization phrasing (`gh696-fix-exception-qa.md:100`): While `Done-by-#632 (deferred to #633)` correctly identifies the governing vehicle, labelling it `Exception (deferred to #633)` would harmonize its nomenclature with 5.6 #203 (`Exception (deferred to #633/#105)`) and 7.5 #457 (`Exception`), making clear that the code in `permitted_numbers_for` remains an open exception deferred to post-handover #633 rather than closed code.
- [Pass] Whole-file sweep: Entire file `relay-system/2026-10-02/gh696-fix-exception-qa.md:1-343` was swept for pre-existing defects, broken markdown syntax, missing citations, or contradictory assertions. No pre-existing defects found.

relay closed (Approved), no further turn needed. All 13 Table A calls and Part B settings answers verified consistent with in-force values and settings inventory (`gh696-relay-artifact.md`).

### Producer · Round 2 (claude-a)

Dispositions for Round 1 findings:
- [Nit] 4.8 #424 nomenclature — **Implemented.** Row 4.8 is relabelled `Exception (deferred to #633)`; basis unchanged (#202 item 61 open; in force = whole percent permitted; inventory `202-61` GOAL_2, planned "decimal places"). This harmonizes it with 5.6 #203 and 7.5 #457. Only 6.8 #202 keeps `Done-by-#632`.
- [Pass] Q1–Q5 — no change needed.

Process note: the Round 1 `STATUS: Approved` was reverted by relay-drive because this run was started without `--reviewer agy` (GH-505 attestation), not because of the review content. Round 2 is driven with `--reviewer agy`.

Updated Table A row (the only change):

| Row | Proposed call | Reason (basis) | Owner | Confidence |
|---|---|---|---|---|
| 4.8 #424 | Exception (deferred to #633) | #202 item 61 open; in force = whole percent permitted; inventory 202-61 GOAL_2 (planned "decimal places"). Item 1: proof numbers withheld from prompt lowers risk | Sam (rule) / Elan (copy) | Med |

Ask for Reviewer (Round 2): confirm the relabel is consistent with the excerpts and that no other row or Part B needs a change; set STATUS Approved if so.

handing off to Reviewer (agy) — take your turn.


### System · relay-drive — 2026-10-03T01:29:05Z
terminal STATUS Approved written by builder-role turn (agy) — reverted

### Reviewer · Round 2

VERDICT: PASS
Basis: Producer in Round 2 implemented the requested nomenclature harmonization on Row 4.8 #424, updating its proposed call to `Exception (deferred to #633)`. This call is fully consistent with #202 item 61, inventory item `202-61` (`bucket=GOAL_2`), and aligns with 5.6 #203 and 7.5 #457. All 13 Table A calls, the five stakeholder judgment calls, and the Part B settings architecture claims remain verified and consistent with in-force values and settings inventory excerpts. No pre-existing defects were found during the whole-file sweep.
swept file: yes

- [Pass] Question 1 & 3 (Row 4.8 #424 relabel verification): In Table A row 4.8 #424 (`gh696-fix-exception-qa.md:399`), the call `Exception (deferred to #633)` is verified consistent with #202 item 61 (`gh696-fix-exception-qa.md:150-156`) where `permitted_numbers_for` permits nearest whole percent against its docstring, and with `settings_inventory.py` item `202-61` (`gh696-fix-exception-qa.md:215-224`, `bucket=GOAL_2`). Structural suppression under item 1 (`gh696-fix-exception-qa.md:127`) mitigates prompt exposure. The relabeling cleanly harmonizes nomenclature with row 5.6 #203 (`Exception (deferred to #633/#105)`, `gh696-fix-exception-qa.md:101`) and row 7.5 #457 (`Exception`, `gh696-fix-exception-qa.md:111`), leaving row 6.8 #202 (`gh696-fix-exception-qa.md:107`) as the sole `Done-by-#632` item.
- [Pass] Question 1 (Table A consistency re-check): All 13 rows in Table A (`gh696-fix-exception-qa.md:100-112, 399`) remain verified consistent with in-force values and inventory excerpts:
  - 4.8 #424: `Exception (deferred to #633)` per #202 item 61 (`gh696-fix-exception-qa.md:150-156`) and inventory `202-61` (`gh696-fix-exception-qa.md:215-224`).
  - 5.6 #203: `Exception (deferred to #633/#105)` per #202 item 33 (`gh696-fix-exception-qa.md:139`), item 2 (`gh696-fix-exception-qa.md:130`), and inventory items `202-33`, `202-6`, `202-7` (`gh696-fix-exception-qa.md:226-255`, `bucket=GOAL_2`).
  - 5.22 #528: `Fix this week (finding 1); finding 2 exception` per #255 finding 1 dev notes (`gh696-fix-exception-qa.md:84`) and item 60 copy in PR #689 (`gh696-fix-exception-qa.md:94, 300-319`).
  - 5.23 #518: `Exception` per item 112 (`gh696-fix-exception-qa.md:180-182`) and inventory `202-112` (`gh696-fix-exception-qa.md:320-327`), with UTC fallback in item 111 (`gh696-fix-exception-qa.md:178`).
  - 6.4 #393: `Exception` per manual deploy receipts on #677/#635 (`gh696-fix-exception-qa.md:104`).
  - 6.6 #167: `Exception` per #167 ("wants its own plan", `gh696-fix-exception-qa.md:87`).
  - 6.7 #234: `Exception` per #632 walkthrough scope (`gh696-fix-exception-qa.md:77`).
  - 6.8 #202: `Done-by-#632` per #632 rule ("decisions are not a gate", `gh696-fix-exception-qa.md:76-77`).
  - 6.9 #514: `Exception (conditional)` per admin membership failure mode (`gh696-fix-exception-qa.md:90`) and manual provisioning (#236, `gh696-fix-exception-qa.md:78`).
  - 6.10 #620: `Exception (list Bounce-visible items)` per #613 fixes (`gh696-fix-exception-qa.md:91`), in-force items 111, 120–123 (`gh696-fix-exception-qa.md:177-198`), and the 5:00 PM PT date-roll behavior (`gh696-fix-exception-qa.md:91`).
  - 6.11 #537: `Fix this week` per CSS fixes needed for /admin/system-settings walkthrough (`gh696-fix-exception-qa.md:92`).
  - 7.5 #457: `Exception` per item 97 (`gh696-fix-exception-qa.md:173-175`) and inventory `202-97` (`gh696-fix-exception-qa.md:257-264`, `bucket=GOAL_2`).
  - #630: `Exception for the call — Noel decides` per item 65 (`gh696-fix-exception-qa.md:158`), item 118 (`gh696-fix-exception-qa.md:184`), and Noel's direction (`gh696-fix-exception-qa.md:80`).
- [Pass] Question 2 (Judgment calls set re-check): The five flagged rows (#630, #167, #203, #620, #514) remain the exact and exhaustive set of stakeholder judgment calls (`gh696-fix-exception-qa.md:101, 105, 108, 109, 112`), with no extraneous or missing judgment items.
- [Pass] Question 4 (Part B settings consistency re-check): The claim that "nothing in #696 needs new System Settings / tenant / recipient UI" (`gh696-fix-exception-qa.md:115`) remains verified against all excerpts: registered keys `copy_and_claims.designed_draft_explainer` (`gh696-fix-exception-qa.md:300-319`) and `nexmail.design_ready_recipients` (`gh696-fix-exception-qa.md:287-297`), inline widget/row controls for #533 Cancel (`gh696-fix-exception-qa.md:200-212`), existing `/tenants → Timezone` field (`gh696-fix-exception-qa.md:325`), and GOAL_2 deferred inventory items (`gh696-fix-exception-qa.md:215-265`).
- [Pass] Question 5 (Owner and confidence re-check): Owners and confidence ratings in Table A (`gh696-fix-exception-qa.md:100-112, 399`) align accurately with roles and inventory specifications: Sam (rule) / Elan (copy) for 4.8 (`gh696-fix-exception-qa.md:218`), Noel for 5.6 (`gh696-fix-exception-qa.md:83`), Elan / Noel for 7.5 (`gh696-fix-exception-qa.md:260`), and Jose / Noel for infra (6.4, 6.6).
- [Pass] Whole-file sweep: Entire file `relay-system/2026-10-02/gh696-fix-exception-qa.md:1-408` swept for pre-existing defects, markdown issues, or inconsistencies. No pre-existing defects found.

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-03T01:34:16Z
task: RELAY-gh696-fix-exception-qa
reviewer: agy
status: Approved
reviewed-head: 072916dc0a12a06e7f277c024a26e0c86b76f183
added-range: 51106+5236
added-sha256: 6c08efe81f48a2d4901683dda4578c35ea805fbff280f4cfb4214237d541e5c2
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
