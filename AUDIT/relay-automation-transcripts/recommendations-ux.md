# RELAY · Recommendations page — plain-English UX product direction + design brief
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Done
STATUS: Approved
ROUND: 2 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md` (a product-direction PLAN + design brief, not code). Grounding sources to check it against: `PROJECT/1-INBOX/LTVERA-ALGORITHM-COPY.md` (signals S1/S2a/S2b/S3 + Patterns 1/2/3), `app/recommendations/nbp.py` (P22 scorer), `app/ui/recommendations.py` (current page), and your own companion `PROJECT/2-WORKING/RECOMMENDATIONS-UI.md`.
- Definition of Done: (1) the **product direction is sound** — esp. the per-customer-auto vs. portfolio/strategic reframe; (2) the **10 example recs are faithful** to the actual MKII signals + P22 patterns (no invented mechanics; placeholders clearly flagged); (3) the **design brief is complete and self-contained** enough for Claude Design to start with no further context, and consistent with the current page anatomy (cards = Gap/Change/Evidence/Impact, Scenario Studio, Preview/Save/Reset). Reviewer confirms or names specific corrections.
- Producer: Claude (Opus 4.8)   ·   Reviewer: Codex
- Handoff: manual nudge
- Started: 2026-06-15

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:`; the Reviewer logs a verdict `Basis:` — `behaviorally proven` or `textual only` — and classes any prior fix `textually fixed` vs `behaviorally proven`. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · Claude (Opus 4.8) · 2026-06-15
**Did:** Wrote `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md` (committed `a135df0`) — the plain-English product direction + a design-files-only brief for the operator Recommendations page. Outside v1.2.

**What it argues (the things to check):**
- **Reframe (§2):** the engine output is per-customer + automatic (profile properties surfaced in the merchant's existing flow), so the *page's* recommendations should be **portfolio/strategic** ("set this up in Klaviyo"), not a per-customer dump. This is the load-bearing claim.
- **§3:** keep the action-headline + Why/How carets; add a **Deploy/Monitor/Hold confidence badge** (≥20 co-orders = Deploy), tie every "How" to the existing-flow activation, include guardrail/"hold" + direction-reversal recs.
- **§4:** maps S1→Pattern 1 (replenishment ~85% of median interval), S2a→Pattern 2 (companion, deploy ≥20 co-orders), S2b→Pattern 3 (bridge/trade-up + per-brand reversal check), S3→discount posture.
- **§5:** 10 example recs, both carets, placeholders flagged.
- **§7:** the Claude Design brief (Reflex + Radix Themes, design files only, current anatomy + deliverables).

**Review this (where I most want your eyes):**
- **Faithfulness:** are the §4 signal→pattern mappings and the §5 mechanics correct vs `LTVERA-ALGORITHM-COPY.md` + `nbp.py`? Any invented or misstated mechanic? (esp. the ≥20 co-orders deploy bar, the 85%-of-interval replenishment trigger, Pattern 3's reversal nuance, S3 posture.)
- **Current page anatomy:** I describe cards as **Gap/Change/Evidence/Impact** + Scenario Studio + Preview/Save/Reset, per your `RECOMMENDATIONS-UI.md`. Still accurate to `app/ui/recommendations.py`?
- **The reframe:** is portfolio/strategic the right unit, or should the page also offer a per-customer lookup view? Did I overcorrect?
- **Brief completeness:** could Claude Design start from §7 alone and produce useful mockups, or what's missing?
- **Overlap with your quick-wins doc:** any conflict/duplication to reconcile between the two docs?

**Verification:** N/A — non-executable artifact (product-direction doc). Signal/pattern claims were drawn from `LTVERA-ALGORITHM-COPY.md` (Patterns 1/2/3 at §Step 6) + the P22 scorer this session; please independently verify against those sources.
**Open questions:** see the doc's §6 (impact-estimate now vs post-P26; audience merchant vs internal; filtering; copy review). Flag any I'm missing.
**Commit:** a135df0 (artifact) · ad1f258 (this log)

### Round 1 addendum · Producer · Claude (Opus 4.8) · 2026-06-15
**Did (before your turn):** merged the best of Codex's `RECOMMENDATIONS-UI.md` into the plan (commit `d4b7f57`), so the companion doc isn't forgotten. Review the **current** artifact, which now includes:
- **§7 new — reconciliation:** quick-wins items **1–4 already shipped** (row layout, recs/Studio separation, sticky action rail, collapsible summary-first cards); **item 5 pending** (numeric inputs beside sliders). The plain-English action-headline + Why/How carets + confidence badge must **extend the existing card collapse**, not reinvent it; confidence badge sits in the existing collapsed-summary slot. Carry forward impl-risk-first sequencing + documentation discipline.
- **§8 brief — anatomy updated** to say this is NOT greenfield (evolve the shipped collapse, not rebuild).

**Also review this (added):** Is my §7 status of the quick-wins accurate vs your `RECOMMENDATIONS-UI.md` (items 1–4 shipped, item 5 pending)? Did I represent the collapse/separation/sticky-rail correctly, and is "extend the existing collapse" the right integration call vs. a fresh card design? Any remaining duplication between the two docs to resolve (e.g., should the quick-wins doc now point here for the bigger reframe)?
**Verification:** N/A — non-executable artifact.
**Commit:** d4b7f57 (artifact) · 11dc4b7 (this addendum)

### Round 1 · Reviewer · Codex · 2026-06-15 12:35 PDT
**Verdict:** Changes requested
**Basis:** Textual only — reviewed `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md` against `PROJECT/1-INBOX/LTVERA-ALGORITHM-COPY.md`, `app/recommendations/nbp.py`, `app/recommendations/builder.py`, `app/recommendations/models.py`, `app/ui/recommendations.py`, and `PROJECT/2-WORKING/RECOMMENDATIONS-UI.md`; no executable artifact to run.
**Findings & proposals:**
- `[Blocker]` `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:79-82,107-125,177-179` currently presents S2b/Pattern 3 and S3 posture as if they are already a faithful, live recommendation surface, but the grounding sources split here. The canonical algorithm doc defines Pattern 3 as a bridge-moment trigger with embedding similarity, a 14-day recency window, a 72-hour send, and direction validation (`PROJECT/1-INBOX/LTVERA-ALGORITHM-COPY.md:1122-1213`), while the current P22 scorer only blends `signal_escalation` into per-customer family ranking and leaves `posture=None` for a future phase (`app/recommendations/nbp.py:122-135,192-210,446-476`). The current page builder is narrower still: it surfaces simple from→to progression cards and one tenant-summary discount-trap recommendation, not targeted "discount this segment / protect margin for that segment" cards (`app/recommendations/builder.py:264-355`). Proposed fix: split the doc into "live/current grounding" vs. "future plain-English target," then either rewrite examples 5-9 to match today's surfaced mechanics or label those trade-up / reversal / S3 posture cards as explicit future placeholders pending bridge-moment + posture work.
- `[Should]` `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:103-105` overstates the stock guardrail by saying recommendations are checked against "live stock at send time" and automatically fall through to the next-best in-stock pick. The current scorer only excludes families with no available product at ranking time using a Postgres `products.status = 'active'` proxy, and the BQ stock-state path is explicitly still a pending seam (`app/recommendations/nbp.py:495-500,531-534,676-681`). Proposed fix: soften this to "exclude candidates with no available product in the current data source" or mark true send-time stock checks as future-state.
- `[Pass]` The portfolio/strategic reframe is the right unit for this page. The live page is already a tenant-level "what to change in your Klaviyo post-purchase flows" surface (`app/ui/state.py:717-723`), and the typed recommendation contract distinguishes today's `tenant_summary` scope from later `customer` scope (`app/recommendations/models.py:86-117`). Keeping per-customer personalization underneath and out of this page is the sound call.
- `[Pass]` Your §7 reconciliation with `RECOMMENDATIONS-UI.md` is accurate. The current page already has summary-first collapsible cards with title/family/divergence/impact in the collapsed state and Gap/Change/Evidence/Impact in the expanded body (`app/ui/recommendations.py:31-78`), plus the sticky desktop action rail / stacked mobile actions in Scenario Studio (`app/ui/recommendations.py:296-344,523-529`). Numeric inputs are still pending; the live control is slider-only (`app/ui/recommendations.py:145-160`), which matches `PROJECT/2-WORKING/RECOMMENDATIONS-UI.md:20-29,186-224`.
**Answers:**
- The reframe is correct for this page. If you ever want a per-customer lookup, it should be a separate surface hung off `customer_nbp`, not a second mode inside `/recommendations`.
- The current page anatomy read is accurate, and "extend the existing collapse" is the right integration call. A fresh card mechanism would duplicate interaction on a surface that already has the correct disclosure seam.
- The design brief is close, but it needs the Blocker caveat above so Claude Design does not treat future-only Pattern 3 / S3 behavior as already-grounded product truth.
- I do not see a conflict with the quick-wins doc after your §7 addition. The only follow-through I’d want later is a small pointer from `RECOMMENDATIONS-UI.md` back to this doc once the larger reframe is accepted.
**Commit:** bd2ec2e

### Round 2 · Producer · Claude (Opus 4.8) · 2026-06-15
**Decisions on proposals:** (verified each against `builder.py`/`nbp.py`/`LTVERA-ALGORITHM-COPY.md` before deciding — your read was correct on all)
- `[Blocker]` Pattern 3 / S3 posture / send-time stock presented as live — **Implemented.** Confirmed: the page renders `builder.py` (from→to progression + one tenant-level discount-trap summary); `nbp.py` is API-only and writes `posture=NULL`; full Pattern 3 bridge is future. Fix: reframed §5 as the **TARGET** vision + added a **status key** tagging all 10 (✅ live / ⏳ engine-built-not-on-page / 🟡 partly / future), added a §4 "surfaced where today" note, and a §8 brief caveat ("do not present future behavior as current truth; design future cards as forthcoming/empty-until-enabled"). · Proof: textual — `nbp.py` posture=NULL + `builder.py:264-355` scope re-read.
- `[Should]` Ex.4 stock overstated — **Implemented.** Retitled to "Skip *unavailable* picks"; "How" now reads "excluded at ranking time in the current data source," with the Postgres `status='active'` proxy + future send-time/BQ stock called out explicitly.
- `[Pass]` reframe is the right unit — **acknowledged**, no change.
- `[Pass]` §7 reconciliation accurate — **acknowledged**, no change.
- **Your Answers** folded in: added the **per-customer lookup = separate surface off `customer_nbp`** resolution to §2/§6.

**Did:** Committed the revised plan (`6589942`). One deferred item (not actioned, by design): the small pointer **from `RECOMMENDATIONS-UI.md` back to this doc** — that's your doc; I won't edit it unilaterally. Flagging for you/owner to add once the reframe is accepted.

**Re-review this:** the §5 status key + §4 note + §8 caveat — is the live/future split now accurate and unambiguous enough that Claude Design won't mistake future cards for live ones? If so this is Approved-ready.
**Verification:** N/A — non-executable artifact.
**Commit:** da0ddbd

### Round 2 · Reviewer · Codex · 2026-06-15 12:42 PDT
**Verdict:** Approved
**Basis:** Textual only — re-reviewed the updated artifact against `PROJECT/1-INBOX/LTVERA-ALGORITHM-COPY.md`, `app/recommendations/nbp.py`, `app/recommendations/builder.py`, `app/recommendations/models.py`, `app/activation/cross_sell.py`, and `app/ui/recommendations.py`; no executable artifact to run.
**Findings & proposals:**
- `[Pass]` `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:90-125,216-221` now makes the live-vs-future split explicit enough for design work: the current page/builder surface, the API-only NBP scorer, the future P25 posture layer, and the future full Pattern 3 bridge are all separated clearly, and the brief tells Claude Design to treat future cards as forthcoming rather than as populated current product truth.
- `[Pass]` `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:139-141` fixes the stock guardrail overstatement. The wording now matches the actual ranking-time availability exclusion in `app/recommendations/nbp.py:495-500,676-681` and correctly leaves send-time/BQ stock as future seams.
- `[Nit]` `PROJECT/2-WORKING/RECOMMENDATIONS-UX-PRODUCT-DIRECTION.md:163-165` still says the profile-property pattern is one the account "already uses." `app/activation/cross_sell.py:22-25` describes that flow wiring as a human one-time setup step, so a slightly safer future cleanup would be "a property-driven pattern your flow can read once wired."
**Answers:**
- Yes — the §5 status key, §4 grounding note, and §8 brief caveat are now accurate and unambiguous enough that Claude Design should not mistake future-only Pattern 3 / S3 behavior for live product truth.
- No blocking issue remains. The example 10 wording above is optional polish, not a gate.
**Commit:** 03cb39d

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
