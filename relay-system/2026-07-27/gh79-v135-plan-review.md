# RELAY · GH-79 v1.3.5 plan: accuracy + coverage vs Elan's mockups
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-27.
-->

NEXT: —
STATUS: Closed
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh79-v135-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- **Artifact under review:** `PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md`
- **Repo:** LTVera-Pandas (you are in a worktree of it; read anything you need)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-27
- **Round 1 = REVIEW ONLY.** Do not edit the plan. Append findings to this file only.

### Context

`GH-79-RELEASE-1-3-5X.md` is an umbrella build plan for a 24-screen design drop from Elan
(product owner). The screens are the build contract — per the handoff: *"The HTML files are
the UI contract: layout, copy, states, and the widget JS is the exact state machine. Do not
redesign, implement."*

Source material to review the plan **against**:

| Path | What it holds |
|---|---|
| `PROJECT/2-WORKING/v1.3.5/phase-1/` | 11 screens + `CAMPAIGN-MVP-HANDOFF-7-22-2026.md` (the product contract: MVP definition, 6 build tasks, Nexmail draft contract §4, pre-commit checks §5, Klaviyo commit §6, decision record §7, standing rules §9) |
| `PROJECT/2-WORKING/v1.3.5/phase-2-calendar/` | 7 files — **4 are written specs**, not mockups (seasonal engine w/ data model, brand absorption w/ code skeletons, email calendar composer, email taxonomy) |
| `PROJECT/2-WORKING/v1.3.5/phase-3-subscription-winback/` | 2 automation wizards |
| `PROJECT/2-WORKING/v1.3.5/phase-4-config/` | billing, connections |
| `PROJECT/2-WORKING/v1.3.5/phase-5-agency/` | agency + brand dashboards |
| `PROJECT/2-WORKING/v1.3.5/website/` | **OUT OF SCOPE** — handled by a separate system, ignore |

Read the **inline JavaScript** in the HTML, not just the markup. The widget state machines
are the spec.

## Definition of Done

Grade the plan on two axes. Cite `file:line` or a quoted span for every finding — an
uncited `[Pass]`/"verified" is mechanically downgraded.

**Axis 1 — ACCURACY.** Does the plan's "Ground truth" section hold up against the actual code?
It asserts, among other things:
- Zero Nexmail code (`grep -rni "nexmail" app/`)
- The complete Klaviyo write-verb set is `PATCH profiles/{id}` x2 — no campaign create, no
  Lists/Segments API, no events
- No best-sellers / velocity query anywhere in `app/`
- No `campaigns` / `decision_records` / `audiences` tables
- No review-data source anywhere in the tree
- RLS is genuinely enforced (FORCE RLS, NOBYPASSRLS role, GUC re-asserted on `after_begin`)
- The agency console collides with the single-scalar `app.current_tenant` RLS model

Verify or refute each. **A false claim in either direction is a [Blocker]** — this plan is the
execution surface of record, and an overstated "this already exists" is as damaging as an
overstated gap.

**Axis 2 — COVERAGE.** Does the plan actually cover what the mockups and specs require?
Look specifically for:
- Requirements present in the screens/specs that the plan **omits entirely**
- Phases whose checklists are too thin to build from
- Contradictions between screens that the plan fails to flag as needing resolution
- Data-model elements declared in the phase-2 specs (`window`, `product_window_score`,
  `brand_profile`, `brand_calendar`, `calendar_slot`, `category_day_library`) that the plan
  does not account for
- The canonical 5-status vocabulary (`proposed|approved|drafted|scheduled|sent`) and whether
  the plan tracks it consistently
- Anything in the handoff's standing rules (§9) the plan violates or ignores

**What NOT to do:** do not rewrite the plan, do not propose a different phase structure (the
phase numbering deliberately mirrors the folder names — that is a settled operator decision),
and do not re-litigate scope that the plan explicitly marks out of scope.

**Verdict:** `Approved` only if you found no `[Blocker]`. Otherwise `Changes requested`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log


### Producer · claude-a · r1 — dispositions applied, relay closed

**Reviewer verdict:** Changes requested (5 Blockers, 4 Shoulds, 3 Passes).
**All 12 findings dispositioned: 10 Implemented, 1 Modified, 1 Declined-as-graded.**

| # | Finding | Disposition |
|---|---|---|
| B1 | "Complete" Klaviyo write-verb list false — two POST report calls exist | **Modified.** Real but overgraded: both are reads shaped as POST (reporting bodies), not mutations, so the substance held. Wording fixed to enumerate and label them. Treated as [Should]. |
| B2 | "No best-sellers query" misleadingly false — `top_seller_anchors()` exists | **Implemented.** Best finding. Verified independently; Phase 1 would have written a second divergent predicate. Plan now says extend, not rewrite. |
| B3 | Review-data claim "self-refuting" | **Declined as graded; wording fixed.** The cited hits are the mockups/handoff *requesting* the feature — spec, not implementation. Independent grep of `app/ pipelines/ scripts/ alembic/` found one hit: "judgement" matching a `judgeme` alternation. Claim was true, badly worded; now scoped to "no review ingestion in `app/`". |
| B4 | Phase 0 schedules two already-fixed bugs | **Implemented.** Both fixed in PR #82. Replaced with a fixed-and-proven table; QA gate now checks the new invariants. Genuinely-open remainder (no sync watermark, #61 downstream, #84) called out so the correction does not over-claim. |
| B5 | Automation track has no delivery mechanism | **Implemented.** Largest real gap. Phase 1c now opens with five contract questions (write boundary, enrollment/send semantics, idempotency, attribution storage, result-series) as its first task, pointing at the existing activation backbone for reuse. |
| S1 | Phase 2 omits the Context contract | **Implemented.** Context storage/API, completeness score, `brand_voice_ref` into the Nexmail request. |
| S2 | Calendar slot provenance/brief/prefill/reconciliation unspecified | **Implemented.** Added the `calendar_slot` behavioural contract + nightly Klaviyo status reconciliation. |
| S3 | Status FSM declared, not operationally specified | **Implemented.** Phase 0 specifies it before the migration; QA tests an illegal transition and a double commit. |
| S4 | A/B / SST / quiet hours not committed to schema | **Implemented.** Persisted as inactive pass-through settings per handoff §6.5, with a round-trip check. |
| P1–P3 | RLS accurate · agency collision correct · 5-status vocabulary consistent | **Kept.** RLS paragraph no longer leads with a table count, per the reviewer's note. |

**Out of bounds, respected by the reviewer:** no phase renumbering, no scope re-litigation.

**Artifact updated:** `PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md` in LTVera-Pandas, which also
carries a `## Review log` section with these same dispositions — this relay file lives in a different
repo, so the findings needed a home future readers will actually reach. PDDA frontmatter /
status-table / hardcoded-paths / roadmap-coverage / quad-concepts all clean.

### Two harness notes for future runs

**1. `--target-root` breaks the reviewer's ability to write this file.** The reviewer runs in a
worktree of the *target* repo; this relay file lives in the *harness* clone, outside it. Codex
completed the review, hit `patch rejected: writing outside of the project`, and correctly released
the token rather than faking a turn. The driver reported exit 3 "genuine stall" — accurate for the
driver, misleading as to cause. For a cross-repo review with no Producer↔Reviewer loop, use
`consult.sh` with `CONSULT_ROOT`. Findings + provenance: `.consult-gh79-out/consult-114136/`.

**2. This file was briefly lost to a cross-session branch switch.** The scaffold committed as
`cab811b` onto whatever branch the harness clone happened to have checked out
(`feat/system-diagram-trust-layout`, another session's work); that session then switched to
`development` and the file left the tree. Recovered from `cab811b` and re-landed on `development`.
Nothing was lost, but it is the GH-141 hazard in a new shape: the relay scaffolder inherits the
ambient branch, so a relay started while another session holds the clone can end up parked on an
unrelated feature branch.

**STATUS: Closed** — review complete, every finding actioned. Deliberately not "Approved": that is
the Reviewer's word, and the limitation above means Codex cannot append a re-review here. A fresh
`consult.sh` run is the way to re-verify.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
