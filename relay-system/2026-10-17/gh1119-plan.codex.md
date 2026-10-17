# RELAY · GH1119 worth-it plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1119-worth-it-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **plan-review.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-17

### Artifact — plan-review.md
````
Review PROJECT/2-WORKING/GH-1119-WORTH-IT.md and the exact upstream source in the read-only review packet below. Operational envelope: documentation-only import of one separately licensed skill, not a planner rewrite or deployment. Require commensurate complexity and no new tests/cases/gates. Questions: (1) Does the plan preserve upstream Continue/Pivot/Park/Stop and remaining-value, alternative, cost, maintenance/risk, one bounded proof, stop/revisit behavior? (2) Does approval-aware results capture avoid duplicates/nagging and false closure? (3) Is skills/3-weekly/worth-it with NOTICE/LICENSE and manual update path surgical and compatible with existing taxonomy and weekly-planner? (4) Are source provenance, verification limits and separate licensing adequately grounded? Flag only concrete omissions or failures; cite file:line. Do not edit implementation. Approve when sufficient, otherwise report Blocker/Should with observed input, scope and falsifier. Review cap 3, no resets.
---
name: worth-it
description: >-
  Judge whether a planned feature or refactor is worth building — whether the payoff justifies the cost and actually moves a needle that matters. Judges benefit against cost across the constituencies a change can serve (end-user UX, human operator experience, codebase maintainability/durability, contributor velocity, business/strategic obligation), discounts benefit that is asserted but unmeasured, nets a gain on one front against the cost it adds on another, and weighs the whole thing against the do-nothing baseline, the timing window, and the next-best use of the same effort. Also reassess in-flight work on `/worth-it continue`, "should we keep going," or "is this still worth pursuing": ignore sunk effort and recommend Continue, Pivot, Park or Stop against the next-best experiment. Trigger when the user asks "is this worth doing/building," "is it worth it," "is this worthwhile," "does this move the needle," "what's the payoff/ROI," "should we even bother," is weighing whether a feature or refactor earns its place, or hands over a plan doc whose open question is its *value* rather than its engineering or its risk. Assumes the frame is already right (that is take-a-step-back); it leans on blast-radius and iron-triangle to price the cost and reversibility of a candidate path, then weighs that cost against the benefit it scores — the term those skills leave unscored. Skip routine analysis when the change is obviously worth it and cheap (an explicit continuation request still gets the five-line checkpoint), or when the open question is HOW to build it well (swe) rather than WHETHER to build it at all.
---

# Worth It

Price the benefit before you spend the effort. Most plans get sized for cost and reviewed for craft, then built on an *assumed* payoff nobody scored.

A value lens for a **feature or refactor under consideration** — a "should we build this" doc, a backlog item, a refactor someone is itching to start. The sibling skills price the cost (blast-radius), the traded corner (iron-triangle), and the engineering discipline (swe); none of them score the *benefit*. This one does, and it answers exactly one question: **is the payoff worth the cost — and is the payoff even real?** It is not a yes-machine. A clean "not worth it" or "not yet, measure first" is the point as often as a green light.

## The core read

> **Worth ~ (Impact x Reach x Confidence) / Cost — netted across fronts, against the do-nothing baseline.**

Not a calculator — a discipline: the symbols order the reasoning, they don't resolve to a number. Don't total made-up values; this is ordinal judgement (bigger / smaller, surer / shakier), not arithmetic. Each term is a question the plan usually leaves implicit:

- **Impact** — how far does the needle actually move? Not "it helps," but the size of the move.
- **Reach** — for how many, how often? A small win hit a hundred times a day beats a big win nobody reaches.
- **Confidence** — is the payoff *measured*, or asserted? An unmeasured benefit is weighted well under one, never at face value.
- **Cost** — the build effort *plus* the carrying cost it adds forever. Every feature is a permanent liability.
- **Netted across fronts** — a gain on one constituency is not free if it taxes another. Net them; don't OR them.
- **Do-nothing baseline** — what the status quo costs if you ship nothing. Some refactors are worth it only because decay is the alternative; some features solve a non-problem the baseline already handles.
- **Timing** — is there a window? A deadline, an expiring opportunity, or a do-nothing cost that compounds the longer you wait can flip a marginal call. Urgency raises the cost of *waiting*, it does not inflate the benefit — keep them separate.

## The five constituencies

A change usually moves a needle for one or more of these. Name *which* — "it's better" without a constituency is unscored. The list aims to be exhaustive about *who* benefits; a change that serves none of them is itself the finding.

1. **End-user UX** — the person using the product feels it: faster, clearer, fewer steps, less pain.
2. **Operator experience** — the human running the system: diagnosis, recovery, day-to-day toil, on-call load.
3. **Maintainability & durability** — the codebase itself: less surface to break, longer useful life, fewer ways to rot.
4. **Contributor velocity** — the next developer: how fast and safely the *next* change lands. Distinct from #3 — clean code the team can't move through fast still fails this.
5. **Business / strategic** — the organization: revenue protected or won, a contractual or regulatory obligation met, a competitive window held, a concrete risk avoided. The benefit here often *is* the do-nothing cost — the deal lost, the fine, the churn — rather than anything a user touches.

The two fronts an operator usually names first are #1 and #3. The skill's job is to also surface #2, #4, and #5, and to **net a forward move on one against a backward move on another**: a UX win that adds a subsystem to maintain is a UX gain *and* a maintainability tax — score both, then decide if the net clears.

## The four tests

Each test is a lens on the change. A plan passes a test by answering it with a *fact*, not a hope. When the fact is missing, don't invent one — mark the field **Unknown** and let the uncertainty carry into the verdict: a Costly or One-way change with Unknown impact, reach, or confidence is **Not yet, measure first** by default, while an Easy, reversible one can still be tried on a thin read.

### 1. Needle — which front moves, and by how much?

- [ ] The moved constituency is named — one of the five above (UX / operator / maintainability / contributor / business), not left as a generic "better."
- [ ] The *size* of the move is stated, not just its direction — "cuts checkout from 5 taps to 2," not "improves checkout."
- [ ] Any front the change moves **backward** is named in the same breath — the new dependency, the added subsystem, the surface that now needs tending.
- [ ] The two fronts are **netted**, not OR'd: a gain on one that is cancelled by a cost on another is a wash, and the plan says so.

### 2. Reach — for whom, how often?

- [ ] The population is sized — "every API request," "the 15% of users who open settings," "the 4 people who run the deploy."
- [ ] The frequency is named — once ever, every release, every incident, every page load. Magnitude without frequency overstates a rare win.
- [ ] A benefit that reaches almost no one is flagged even when its per-event impact is large.
- [ ] **Small population, high frequency still clears.** Reach is population *times* frequency — a daily-friction win for the 3 people who touch that code every day can outrank a one-time win for thousands. Don't kill an operator or contributor refactor just because few people see it; weigh how often they hit it.

### 3. Confidence — measured or asserted?

- [ ] The payoff is tagged **measured** (there is a number), **proxied** (a reasonable stand-in exists), or **asserted** (someone believes it).
- [ ] An *asserted* benefit on a **Costly or One-way door** build is the headline finding — the verdict becomes **Not yet, measure first**, and the cheapest measurement is named. (On an Easy, reversible build, just try it — measuring would cost more than the build.)
- [ ] **Mandatory work skips the measure-first gate.** When the driver is compliance, security, a contract, or competitive table-stakes (constituency #5), the benefit *is* the penalty avoided — the fine, the breach, the lost deal — not a number to capture. Verdict: **Worth it — required**, not *measure first*. Scope can still be questioned; the *whether* cannot.
- [ ] Predicted and observed are kept separate — "this will cut load 40%" is a hypothesis to test, never evidence the build is worth it. (Borrows swe's Proof discipline: don't launder a projection as a result.)

### 4. Price — at what cost, instead of what?

- [ ] Build cost is sized (defer the detailed sizing to **blast-radius**; this test only requires the plan *carry* a number).
- [ ] **Carrying cost** is named — the permanent maintenance, the new failure modes, the thing on-call now has to know. Build cost is one-time; carrying cost is forever.
- [ ] **Reversibility** is read on the shared scale — **Easy / Costly / One-way door** (defer the read to **blast-radius**; if it hasn't run, gut-check it: can you undo this in an afternoon, a sprint, or never?) — because it sets how far an *asserted* benefit is allowed to ride: an Easy build can be tried on a hunch, a One-way door cannot.
- [ ] The **counterfactual** is stated — what the same effort would buy if spent on the next item instead. Worth is relative, not absolute.
- [ ] The **do-nothing cost** is stated — what the status quo actually costs over the next N months. If it is lower than the build, the honest verdict is *not worth it*.

## The cheaper-version lever

The most valuable output is rarely yes/no — it is **"the full thing isn't worth it, but the 20% that delivers 80% of the needle is."** Before any verdict, ask whether a smaller version captures most of the Impact x Reach at a fraction of the Cost. Scope is the release valve here exactly as it is in iron-triangle: the cheap slice that moves the needle usually beats the complete build that moves it slightly further for ten times the carrying cost.

## Continuation mode — is the next increment still worth it?

Use `/worth-it continue: <current experiment and evidence>` or a request to reassess ongoing work. Keep the initial-investment evaluation above for new proposals; here reuse its four tests, constituencies and cheaper-version lever on **remaining** benefit, effort, carrying cost and risk. Ignore time, money and polish already spent: they buy no preference. Count future integration, cleanup and safe-exit costs where real. `worth-it` owns the allocation call; this is one checkpoint, not another scoring framework or review loop.

1. **Ground the premise.** Reuse current findings and decisions. Borrow `sanity-check`'s goal/dependency/consequence read and `ponytail`'s smallest valid approach, preserving requirements and safety. Resolve helpers by installed frontmatter `name` before invoking: the sibling source folder `ponytail-refined` declares `name: ponytail`, so do not assume `/ponytail-refined` is callable. Read available helpers; if absent, disclose that and apply the relevant reasoning directly. Do not launch their repair, issue-filing or review workflows from this checkpoint.
2. **Price the next increment against the best alternative.** Name the user outcome, current baseline, strongest competing experiment (or doing nothing), remaining payoff, effort, maintenance/risk and Easy / Costly / One-way door reversibility. Separate observed, proxied and projected benefits; cite dated sources, revision/environment and sample limits where available. Keep skipped coverage, first-attempt failures and retry-rescued passes visible: final green is not clean first-pass equivalence. Overlapping gains are not additive; local percentages are not comparable end-to-end savings. Unknowns stay unknown.
3. **Choose once.** **Continue** when the next increment beats the alternative on supported remaining value; **Pivot** when a smaller slice or different approach serves the goal better; **Park** when potentially useful work is blocked or outranked, with a concrete revisit trigger; **Stop** when evidence no longer justifies further effort. Mandatory obligations survive an unattractive implementation: pivot the mechanism, do not silently drop the requirement. Uncertainty alone never earns Continue.
4. **Buy information only when it could change the call.** Propose at most one bounded proof step, only if its expected decision value warrants its cost versus the alternative. Reuse baseline-spec's metric, correctness oracle, baseline and fixed budget; use existing checks or manual evidence, without generating a harness or adding tests absent explicit approval. State the time/cost cap, success threshold and failure/early-stop criteria before running anything; never extend the cap to rescue a result. Otherwise say `Proof: None` with the reason. A recommendation authorizes no execution, publication or weakening of required coverage.

### Soft durable-results guard (both modes)

When meaningful findings or decisions could get lost, need comparison across alternatives, or are likely to be debated again, **first look for an existing relevant leaderboard/results issue** in current context and the target project's issues, including closed results where relevant. Reuse it rather than duplicate it. If lookup is unavailable, disclose that; absence of access is not evidence that no issue exists. Suggest creating one only after checking for prior results.

**Ask the operator before creating or posting**, unless that exact action and destination are already authorized. Suggest the existing destination or a new results issue if absent; keep any approval question inside the existing output (in `Exit` for continuation). Never publish automatically or let a helper's broader filing authority bypass this guard. Approved capture retains the decision, dated source evidence, limitations, alternatives, closed versus open work, and the new evidence that would justify reopening; verify the write before claiming capture. After a decline, respect it for this scope and do not ask again unless the operator reopens capture. Pending or declined capture does not block useful work, but do not claim full loop closure while durable capture remains pending or was declined. New facts can still justify reassessment; unchanged facts do not justify endless review.

**Counter-example:** A trivial, reversible typo correction with no reusable finding earns no results search or capture prompt. Keep the existing cheap initial-investment verdict brief.

### Continuation output — exactly five short lines

Use these instead of the initial-investment scorecard. Fit uncertainty, helper unavailability and capture status into the relevant line; do not append another report.

```text
Call: Continue / Pivot / Park / Stop — decisive remaining-value reason.
Evidence: Observed versus projected payoff; dated source and material limits/retries.
Tradeoff: Next increment's benefit/cost/risk and reversibility versus best alternative; overlap.
Proof: One warranted step with baseline, metric/oracle, budget and success/stop criteria; or None — why.
Exit: Stop/pivot condition; Park revisit trigger; capture status or one approval question if warranted.
```

## How this differs from the sibling skills

- **worth-it** — "Is the payoff worth the cost, and is the payoff real?" Scores the *benefit* the others leave unscored, against cost.
- **take-a-step-back** — "Is this the *right problem* at all?" Challenges the frame *before* there is a benefit to price. If the frame is wrong, worth-it is scoring the wrong thing — hand back to it.
- **iron-triangle** — "Which of speed / cost / quality am I trading?" Prices a path already chosen on three axes. worth-it asks whether to walk the path at all.
- **blast-radius** — "How big and how reversible is this path?" Sizes the cost. worth-it *consumes* that as the denominator and weighs benefit against it.
- **swe** — "Is the *plan* engineered well?" Judges the build's discipline (minimal / diagnosable / blast / proof). worth-it judges whether the build should exist. Complementary: swe grades the *how*, worth-it grades the *whether*.
- **baseline-spec** — when worth-it returns **Not yet, measure first**, this is the handoff: it turns the asserted benefit into a metric, oracle, and baseline so the value question can be answered with a number next time.

Reach for worth-it the moment the open question is *value* — should this be built — rather than risk, craft, or framing.

**Used standalone?** When those siblings aren't installed or haven't run yet, estimate cost, carrying cost, and reversibility directly from the plan and label the read *rough*. worth-it still works alone — it just leans on its own gut-check instead of their output.

## Output format

Lead with the verdict in one line; the load-bearing reason rides with it. Then the scorecard, then the lever and the next move. **Skip the scorecard entirely when the call is obvious** — a cheap, reversible change that moves a front forward with no real downside earns a one- or two-line "Worth it" and nothing more. The full scorecard is for the ambiguous, costly, irreversible, or politically loaded calls; forcing it on an easy one is the regression, not the diligence.

**Verdict:** **Worth it** · **Marginal** · **Not worth it** · **Not yet, measure first** — [one sentence: the reason that carries the call].

**Scorecard:**

| Test | Read |
| --- | --- |
| Needle | [front(s) moved + size; any front moved backward] |
| Reach | [population x frequency] |
| Confidence | [measured / proxied / asserted] |
| Price | [build cost + carrying cost + what the effort displaces] |
| Do-nothing | [what the status quo costs over the next N months — the counterweight the build must beat] |
| Reversibility | [Easy / Costly / One-way door — defers to blast-radius, or gut-check: undo in an afternoon / a sprint / never] |

Keep every scorecard cell to one or two sentences — a cell that swells into a paragraph or a bulleted list breaks the table and buries the read.

**Cheaper version:** [the 20% slice that captures most of the needle, or "none — it's all-or-nothing because ___"].

**Do next:** [the single move — usually "ship the cheap slice," "measure X before committing," or "build it, the net is clearly positive"].

Verdict guide: **Worth it** (net benefit clearly clears cost; both fronts non-negative or the backward one is named and accepted) · **Marginal** (not worth it *as written*, but worth a cheaper slice, or worth it only if a named assumption holds — say which; never read it as "barely worth building as-is") · **Not worth it** (do-nothing cost is lower, reach is near-zero, or the carrying cost outlives the win) · **Not yet, measure first** (the benefit is asserted on a Costly or One-way build — the value can't be judged until it's measured; an Easy build just gets tried instead).

## Principles

**Score the benefit, not just the cost.** The whole reason this skill exists is that the suite already prices cost five ways and never scores payoff. Refuse to let "it'll be better" pass as a benefit.

**Carrying cost is forever; build cost is once.** The permanent maintenance, the new failure mode, the thing on-call must now know — these outlast the build and often outweigh it. Price the liability, not just the labor.

**Net the fronts; don't OR them.** A UX win that taxes maintainability has to clear *both* — or name which front it sacrifices and why that's acceptable. A change that moves one needle forward and another backward by the same amount is a wash dressed as progress.

**The do-nothing baseline is a real option.** The status quo has a cost; sometimes it's lower than the fix. "Solving a non-problem" is the most common way a plausible plan is not worth it.

**Don't manufacture doubt.** A change that is clearly worth it and cheap gets "ship it" in two lines. The lens prices value honestly in both directions — it is not a bias toward caution any more than toward building.

## Example — a feature whose payoff is assumed

Input (abridged):

> **Build an in-app notification center.** A bell icon with unread counts, full history, and per-type preferences, so users stop missing important updates. Roughly three weeks. It'll meaningfully improve the UX.

Output:

> **Verdict:** **Marginal** — a full notification subsystem is a permanent carrying cost for a needle that the existing email already moves; the cheap slice captures most of it.
>
> **Scorecard:**
>
> | Test | Read |
> | --- | --- |
> | Needle | UX forward (users miss fewer updates) — but maintainability **backward**: a new subsystem (storage, real-time, preferences) to own and page on, forever. |
> | Reach | Unknown — no data on how many users miss updates today, or whether they'd check a bell over the email they already get. |
> | Confidence | **Asserted.** "Meaningfully improve the UX" has no number behind it; the email channel already covers the stated problem. |
> | Price | ~3 weeks build + indefinite carrying cost; displaces the billing-bug backlog. |
> | Do-nothing | Users keep getting the existing emails — modest ongoing cost, not zero. The build must beat *that*, not zero. |
> | Reversibility | Costly — once support flows and user habits depend on the bell, ripping it out is its own project. |
>
> **Cheaper version:** A single "what's new since you left" panel on login surfaces the 2-3 missed items at ~2 days, no new subsystem, no real-time, no preferences.
>
> **Do next:** Ship the login panel and instrument it — if click-through proves users want more, *then* the full center has a measured benefit to justify it. Until then the three-week build is buying an asserted gain.

## Counter-example — clearly worth it, no analysis needed

Input (abridged): "Adding request IDs and structured logging to the API before the next release — about a day's work."

Output:

> **Verdict:** **Worth it** — two needles forward (operator and durability), nothing moved backward, cost of a day. Ship it; no scorecard needed.
>
> A change this cheap with two fronts forward and zero traded is the calibration floor — the kind worth-it should green-light in one line. Walking the full scorecard here would be the regression, not the diligence: the skill prices value to *find* the hard calls, not to ceremony the easy ones.

## What success looks like

The operator sees, before spending the effort, whether the payoff is real and big enough — the subsystem whose benefit was never measured, the refactor that only halts decay, the feature whose cheap 20% would have done the job. The best outcome is not a verdict at all but a *reframe of the build*: smaller, measured, and worth it — instead of large, assumed, and shipped on faith.
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

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
Basis: Approve the documentation-only import plan against the four questions in the embedded review request (the scaffold's Definition of Done remains a placeholder). This approves implementation preparation, not implementation correctness or publication readiness.
swept file: yes

- [Pass] Whole-file sweep covered all 43 lines of `PROJECT/2-WORKING/GH-1119-WORTH-IT.md` and the entire embedded upstream skill, including initial mode, continuation mode, results guard and examples. No additional pre-existing defect requiring correction was found in those artifacts.
- [Pass] Behavior preservation is explicit at plan lines 36–37: “keep initial and continuation modes together” and “Preserve the upstream behavior and callable name”; the walkthrough acceptance names all four calls, sunk-cost exclusion, strongest alternative, maintenance/risk, bounded proof/oracle/cap, stop and Park trigger. The supplied source's continuation steps 2–4 and “exactly five short lines” supply the concrete import contract; no planner rewrite or new decision framework is needed.
- [Pass] Capture acceptance is adequate at plan line 37: meaningful-results lookup, exact authorization, decline/no nag, duplicates and pending-capture truthfulness. The supplied source explicitly says “including closed results where relevant,” “absence of access is not evidence that no issue exists,” and “verify the write before claiming capture.” It also forbids helpers bypassing approval and permits useful work while capture is pending/declined. Preserve these spans verbatim.
- [Pass] Scope fits existing taxonomy: `skills/README.md:10` defines weekly cadence reviews; plan lines 25, 29 and 36–39 add one bundle/index row and leave weekly-planner unchanged. Its existing frontmatter describes team planning/shared daily engine; a standalone value checkpoint has a distinct responsibility. No deployment, scheduler, new tests or gates are proposed.
- [Pass] Provenance and verification are appropriately bounded as a plan: lines 20 and 27 pin the revision, acknowledge the open PR and separate license; line 36 requires NOTICE/LICENSE and recorded deviations; lines 38 and 43 explicitly limit author walkthroughs rather than claiming live-agent compliance.
- [Nit] Make the promised manual update recipe easy to find in the eventual NOTICE: source repository/path/full revision, fetch/compare at a new explicit revision, review upstream changes and license, then update recorded deviations and provenance. Plan line 20 already promises this recipe; this is placement guidance, not a request for tooling or another workstream.
- [Unverified — needs implementation QA] Exact upstream LICENSE/README bytes and current PR state were not independently verified this turn. `web.open` of the pinned raw LICENSE and README URLs returned “Failed to fetch … Cache miss” for each. The supplied skill text supports the behavior review; the import must still inspect and retain the actual pinned license and attribution as planned. No legal compatibility conclusion is asserted.
- [Unverified — needs clone run] No gate, executable fixture or live model evaluation ran. The plan correctly leaves checks and final diff/evidence QA outstanding (lines 38–43).
- Evidence limits: graph project `XYZ-forge` resolves to the main checkout, generation `2026-09-01T15:54:30Z`, not this relay checkout. Coverage reported missing/not-tracked/changed freshness for the four requested plan/taxonomy/index/planner paths. Used direct local source reads instead. Decisive read: `nl -ba PROJECT/2-WORKING/GH-1119-WORTH-IT.md`, exit 0, nonempty lines 1–43; taxonomy/index reads also exit 0. No runtime or exhaustive repository-discovery claim relies on that stale graph.

Relay closed (Approved), no further review turn needed. Producer may proceed with the bounded import and final QA described in the plan.

### Producer · Round 2 protocol correction

Round 1 reviewer verdict PASS is retained above, but the driver refused attestation (exit 4, close-mismatch) because the reviewer released to author and then attempted done without ownership. No implementation has begun. Same task, same three-round cap; no reset. Reconfirm the plan and append your own Round 2 verdict. On approval claim the existing token, then use `done RELAY-gh1119-plan --agent codex` while still owning it; do NOT release it first. Set Approved only as the Reviewer. The harness owns commits. The acceptance criteria are the four explicit questions in the embedded review request and the plan's Ordered plan and acceptance section. Source/license bytes remain implementation verification, not a new plan blocker.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
