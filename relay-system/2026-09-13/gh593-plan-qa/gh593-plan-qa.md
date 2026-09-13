---
Goal: Plan QA — GH-593 radar re-scores whack-a-mole umbrellas
Date: 2026-09-13
Producer: claude-a
Reviewer: codex
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the plan at `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md` before implementation.
This is a **review turn**: read, adjudicate, write your verdict below. Do not edit the plan or the skills.

Read in full:
- `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md` — the plan under review
- `skills/whack-a-mole/SKILL.md` — the producer skill the plan changes (§4 weights, §6 template, §7 report, Edge cases)
- `skills/radar/SKILL.md` — the consumer skill the plan changes (Guardrails, Step 2 signals 1–7, Step 5 Sink B, Boundaries table)
- `LESSONS-LEARNED.md` — the lesson that motivated this

The requirements (GitHub issue #593) and the live sink's current shape (#293) are embedded below so you need no network.

## Requirements — issue #593 (verbatim)

## Problem

`whack-a-mole` files an umbrella issue for a recurring-defect cluster and says "re-run after the sweep to confirm the score drops" — but it is stateless. Nothing records the cluster's score at filing, and nothing re-measures it after the umbrella's fix merges. "Umbrella closed" is the only completion signal, and #591's chain (#421 → #425 → #546 → #584) shows that is not "class solved": two closed fixes each exposed the next break. Radar's own board has the same shape — `RADAR-class-vendored-root-resolution` run 1 said "no consumer repo files an eighth"; runs 2 and 3 produced the eighth through twelfth (#293).

`radar` already owns persistence for recurring defects (immutable dated report + live checklist #293) and already has the rule "never strike through on symptom disappearance alone — require a citable fix". It does not know which clusters have an umbrella, and it has no numeric quiet-threshold for calling a class retired.

## Change (three parts, all prose in two SKILL.md files — no scripts)

1. **`skills/whack-a-mole/SKILL.md`** — the umbrella template's "Evidence and confidence" section gains a fixed-key **Cluster signature** block: paths, error strings, member issues/commits, and the raw churn signals at filing (`reopens repeat_fixes reverts size comments open_days score`, plus run ID). whack-a-mole stays read-only; this is more content in the one issue it already files.

2. **`skills/radar/SKILL.md`** — Lens 2 gains a signal: read open and closed issues titled `Umbrella:`, parse each Cluster signature, re-score it against the current radar window with whack-a-mole's weights (3/reopen, 3/repeat fix, 4/revert, 1/member, 1 per 5 comments, 1 per 7 days open), counting only signals dated after the umbrella's fix-merge date when one exists. Sink B (#293) gains an `## Umbrellas — re-scored` section with one line per umbrella: `#<n> — filed at <score> (<run>), now <score> (<window>), fix merged <date + PR | not yet> → holding | class survived`.

3. **Definition of solved** (radar): an umbrella's class is retired only when its signature scores **below 5 on two consecutive radar runs after the fix merged**. Below 5 is whack-a-mole's own "no pattern" threshold. A closed umbrella whose signature is still ≥ 5 is marked `class survived — recommend reopening`; radar never closes or reopens anything itself.

## Acceptance (each must be able to fail)

- [ ] whack-a-mole's template renders a Cluster signature block; a body without one is a template violation, not a silently-missing section.
- [ ] radar, run against this repo, produces a re-score line for #591 in the exact format above — witnessed in the PR body with the actual line and the signals it counted. A radar run that finds `Umbrella:` issues and emits no re-score line is a failure.
- [ ] Red control: a synthetic closed umbrella whose signature still matches ≥ 5 points of window activity is emitted as `class survived`, not struck through — shown in the PR body.
- [ ] radar's Guardrails still hold: no writes beyond the two sinks, no issue closes/reopens.
- [ ] `utils/pdda/pdda.sh run` clean; docs-only route green.

## Non-goals

- No script, DB table, or third sink. Radar's existing sinks carry the state.
- No change to whack-a-mole's non-negotiables (read-only, one issue per run, never edit existing issues).
- No change to radar's target-score formula for non-umbrella clusters.

## Related

#591 (the umbrella that motivated this), #293 (radar live checklist), #442 (radar tracking), `LESSONS-LEARNED.md` @ cf99059.


## Live sink — issue #293, first 40 lines (verbatim, for the row/section shape radar writes today)

Live completion state for Radar targets. **This issue is the live copy** — the dated reports are immutable snapshots, never edited.

Newest report: [`PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md`](PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md)
Previous: [`RADAR-REPORT-2026-09-01.md`](PROJECT/1-INBOX/RADAR-REPORT-2026-09-01.md) · [`RADAR-REPORT-2026-08-28.md`](PROJECT/1-INBOX/RADAR-REPORT-2026-08-28.md)
Window: 2026-08-12 → 2026-09-02 · trunk `development` @ `1b6058d7` · 998 commits (tally proven, sums to 998)

**Reconciliation rules for whoever updates this next:** carry unchecked items forward by target ID, never re-slug a live target, and **never strike through on symptom disappearance alone** — require a commit or PR that names the seam. Causal links: `RADAR-class-frozen-twin-dead-fix` is the mechanism by which any other target's fix can silently fail to ship; `RADAR-class-dark-telemetry` and `RADAR-class-guard-blind-matcher` are the same failure family one layer apart.

**Flow mix across three runs — unmoved:** Run 76.7% → 76.9%, Grow 14.4% → 14.2%, Transform 0% (undeclared, `rgt:` adoption 0 of 138 docs).

---

## RADAR-class-vendored-root-resolution — 12 issues / 4 repos · first-seen: 2026-08-28 · runs: 3

Scripts and generators resolve paths against the bare repo layout and break under a vendored `.xyz/` install, or against a stale vendored copy. **The only target getting worse every run.**

| Run | Members | Consumer repos | `reported_from:` docs |
|---|---|---|---|
| 1 | 7 | 3 | 7 |
| 2 | 9 | 4 | 10 |
| **3** | **12** | **4** | **14** |

Closed since run 2: #353. **Newly filed 2026-09-02: #393, #394, #395** — plus `852aafb5 fix(GH-346): --env never emitted RELAY_AGENT, so the documented one-liner could not run`. Run 1's acceptance condition read "no consumer repo files an eighth"; runs 2 and 3 produced the eighth through the twelfth, every one fixed individually. **The shared root-resolution helper still does not exist.** `rebalanceOS` alone went from 2 `reported_from:` docs to 5.

**The class has widened.** Runs 1–2 were path arithmetic (`ROOT="$(cd "$HERE/.." && pwd)"`). #393–#395 are environment and staleness — the harness resolving to the wrong install, a stale vendored copy, or an exported variable defeating discovery. A helper fixing only the path half will not retire them.

Still open: #215, #216, #253, #254, #255, #256, #393, #394, #395. Score ≈ 9.0 — **top target**. **Claimed by 0.9.0 `Cargo` (active)** — right band, wrong method.

- [ ] Add one shared resolution helper covering **both halves** — correct at `repo_root/utils/…` and `repo_root/.xyz/utils/…`, **and** authoritative about which harness install is in play — acceptance: the idiom `ROOT="$(cd "$HERE/.." && pwd)"` appears in no shipped script, and an exported `XYZ_HARNESS` cannot silently defeat discovery (#395)
- [ ] Add a vendored-`.xyz/` fixture to the suite, including a **stale** vendored copy — acceptance: a script assuming the bare layout, or assuming a fresh vendor, fails in CI rather than in a consumer repo (#394)
- [ ] Close #215 / #216 / #253 / #254 / #255 / #256 / #393 / #394 / #395 against the shared helper — acceptance: no consumer repo files a thirteenth

## RADAR-class-dark-telemetry — 8 issues over 10 days · first-seen: 2026-09-01 · runs: 2 · **substantially retired**

Instruments that report a state they never measured. **This target moved more than any other in four days, and every retirement cites a commit that names the seam.**

- [x] ~~Land #370 (worktree-progress telemetry in the RSS poll loop)~~ — **done**, #370 CLOSED
- [x] ~~Add a write-verification assertion to every telemetry writer~~ — **done**: `bce674ba fix(GH-365): make worker telemetry real — export the surface, shard the writers, fix the skip-count double-print`; `ad2f288d fix(GH-377): the telemetry completeness self-check never ran — grep -c double-print`. #365 and #377 both CLOSED, PR #378 merged.
- [ ] Restore or replace the run-log corpus under a committed, gitignore-audited path — acceptance: a later Radar run can answer "how many of the last N runs show X" at N ≥ 20. **Now two consecutive runs with 0 logs** (run 1 read 83). A repo whose defect class is "the instrument is dark" has gone two Radar runs with no instrument corpus.
- [ ] Make `gh382`'s low-swap assertion platform-aware (#208) — acceptance: the assertion is skipped, not silently dark, on non-darwin

## Questions — answer each with a numbered verdict and `file:line` citations

1. **Recon grounding.** Are the plan's recon claims true against the actual SKILL.md text: the `## Evidence and confidence` section and its three bullets in whack-a-mole §6; the six weights and the "no cluster above 5" floor in §4; the "re-running after the sweep" line in §7; radar's seven numbered Lens 2 signals, the "names the seam" strike-through rule in Step 5 Sink B, and the Boundaries table lacking a whack-a-mole row? Cite the line for each; flag any claim the file does not support.
2. **Requirement coverage.** Map each of #593's three numbered changes and five acceptance boxes to a step in the plan's "Implementation (ordered)" list. Name anything unmapped.
3. **Extend, don't add.** Does the plan extend radar's two existing sinks and whack-a-mole's existing template, or does it introduce a new subsystem, script, DB table, or write path? Does it violate either skill's Guardrails / Non-negotiables?
4. **Design decisions.** For decisions 3 (post-fix-only counting), 4 (below 5 on two consecutive runs = solved), and 6 (umbrella rows outside radar's target ranking): is each sound, and what is the **strongest counterargument**? In particular: could post-fix-only counting hide a fix that merged but did not deploy/take effect? Is "two consecutive runs" well-defined given radar runs on irregular dates (Aug 28, Sep 1, Sep 2)? Should an umbrella whose class re-fires re-enter radar's target ranking?
5. **Signature contract.** Is the Cluster signature (fixed keys `cluster run paths errors issues commits signals`, one per line, fenced) unambiguous enough that a cold agent reading only the prose would (a) produce it in whack-a-mole and (b) parse and re-score it in radar? Name any key whose semantics are underspecified (e.g. what counts as a "path match", how `errors` are matched, whether `commits` means member fix commits or lineage).
6. **Falsifiability.** For each of the five acceptance boxes: can it actually fail, and what input makes it fail? Does the red control (a synthetic closed umbrella whose signature still matches ≥ 5 points → must emit `class survived`, not a strike-through) detect the real failure mode? Is any box satisfiable by an empty or trivial input?
7. **Rating.** Is `rated 60/55/50/80` grounded per the repo's four-axis policy — severity from consequence (#591's chain: two fallback PRs, four hand receipts), recurrence evidence from the stated windows, appeal at neutral 50 with no user preference, effort = cheapness of two prose edits? Say if any axis is over- or under-stated and why.

Write your verdict as a `## Reviewer — codex` block below: for each question, `OK` or a concrete finding with the fix you propose. Finish with `VERDICT: Approved` or `VERDICT: Changes requested` and set `STATUS:` accordingly (Approved → `STATUS: Approved`; otherwise leave `STATUS: Open` and set `NEXT: Producer`).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


## Reviewer — codex

**Changes requested.** The two-skill extension is appropriately small, but the no-target write guard prevents quiet-run persistence, and the signature/counting contract leaves materially different scores and retirement decisions possible.

Review evidence: read the plan, both target skills, and LESSONS-LEARNED.md in full; inspected the rating policy and embedded issue requirements/#293 excerpt. This is static plan QA, not an executed radar run. Graph tools are unavailable in this session; these are direct, line-numbered prose-source checks. No git, project scripts, gates, or artifact execution was performed. Live #591 body/timeline and the remainder of #293 were not supplied or independently verified. Citations below use `P` for `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md`, `W` for `skills/whack-a-mole/SKILL.md`, and `R` for `skills/radar/SKILL.md`.

1. **Recon grounding — OK with two factual qualifications (Note).** The three Evidence bullets are exactly at W:155–158. The six weights are at W:85–90; the actual floor is “no cluster scores above 5” at W:105. The re-run suggestion is W:187. Radar's seven signals begin at R:121,134,143,144,152,154,161; the yield rule is R:183–187. The seam-naming strike-through rule is R:398–408, specifically R:405. The complete Boundaries table at R:440–448 has no whack-a-mole row. Thus P:49–63 is grounded. However, P:87–88 calls strict `<5` the producer's own floor: producer currently stops at `<=5`, whereas #593 explicitly treats `>=5` as surviving. Keep #593's conservative boundary, but disclose the equality difference; do not silently change producer scoring. P:65–68 claims the whole live sink has no umbrella section; the supplied first 40 lines only establish the shown section shape, not absence later in the issue. Mark that claim as producer-observed until the full body is cited. LESSONS-LEARNED.md:12–23 supports the failure-chain mechanism, not every timestamp or receipt count in the rating.

2. **Requirement coverage — Fix: mapping exists, but important acceptance coverage is partial.**

   | #593 requirement | Ordered implementation step | Assessment |
   |---|---|---|
   | Change 1: fixed-key filing signature/raw signals/run | 1, P:99–106; keys in P:77–79 | Mapped; semantics missing (finding 5). |
   | Change 2: open/closed discovery, post-fix weighted score, exact Sink B row | 2–3, P:107–119 | Mapped; no-target persistence conflict (finding 3). |
   | Change 3: two quiet runs; surviving closed class; advisory only | 3 plus decisions 4–5, P:87–92,114–117 | Mapped; run/streak transition rules missing (finding 4). |
   | Acceptance 1: rendered signature; missing block is violation | 1 | Partial: occurrence count does not check missing-block rejection. |
   | Acceptance 2: actual #591 line and counted signals | 6, P:124–128 | Partial: hand-running only signal 8 misses full radar discovery/output integration and legacy baseline handling. |
   | Acceptance 3: closed, active synthetic umbrella stays unstruck | 6 | Mapped; add fixed inputs and expected arithmetic (finding 6). |
   | Acceptance 4: two sinks only; no closes/reopens | Decisions 5–6 and step 3 | Guardrails are promised at P:141, but no ordered verification audits actual write destinations/verbs. |
   | Acceptance 5: PDDA clean and docs-only route green | 7, P:129–130 | PDDA mapped; tier-2 releases replaces, rather than demonstrates, the requested docs-only check. |

   Cheapest fix: strengthen existing steps 1, 6 and 7 with the missing checks. A broader releases gate may be necessary for the actual diff; separately identify its docs-check coverage or run the focused docs route and record both. No new test subsystem is needed.

3. **Extend, don't add — Block: reconcile the existing no-target guards.** P:93–95 explicitly excludes umbrella rows from targets. R:37–38 says “No targets → write nothing”; R:282 gives an all-clear when no targets exist; R:350 skips persistence entirely. With zero ordinary targets and one tracked umbrella scoring 0, the proposed consumer must both persist `(1/2 quiet)` and write nothing. The second quiet observation can never reliably become durable. Amend those existing clauses to skip only when there are neither ordinary targets nor umbrella observations requiring tracking; explicitly include umbrella evidence in Sink A and rows in Sink B. Keep the existing one-confirmation flow (R:424). Add an umbrella-only run as the integration control. This is an explicit refinement of the no-target guard, not an extra sink. Otherwise the design extends the existing template and two sinks, introduces no script/DB subsystem, and preserves W:14–15's one-approved-issue boundary and R:29–32's write restrictions. The CHANGELOG edit at P:123 is implementation governance, not a radar runtime write path. Reversibility: Easy for the prose edits; inaccurate published retirement evidence still needs a correction on the next report.

4. **Design decisions — Fix: keep the choices, define their limits and transitions.**

   **Decision 3:** Post-fix scoring follows #593 and prevents old events inflating the current observation. Strongest counterargument: a merge may not reach the affected installation, so the same unresolved pre-fix incident can persist without generating fresh tickets. P:85–86's “forever” rationale is also inaccurate: radar already uses a rolling 21-day window (R:44), so dated events age out. Keep the required cutoff, define it as the window intersected with time strictly after a verified class-fixing merge, and state that merge is not deployment proof. At P:111–112, “linked PR” or “commit that names the umbrella” is too broad: a documentation/reference commit or one symptom fix must not reset the clock. Require evidence it fixes the class on the evaluated trunk; specify which fix wins when multiple PRs exist, and how reverted/superseded fixes affect eligibility. Known continued operational failure (R:154–160) must be disclosed and prevent a false solved claim, without inventing churn weights for logs.

   **Decision 4:** Two observations are the requested minimum, but P:87–90 does not define consecutive. Strongest counterargument: R:368–371 explicitly supports same-day reruns; two near-identical snapshots minutes after a merge can satisfy the phrase while measuring almost no exposure. Define distinct run identity/order, the previous comparable observation, same-day replay behavior, and whether a changed window is comparable. Specify streak reset on `>=5`, missing/unreadable evidence, a changed signature/fix, and reactivation after retirement. An unavailable signal must never become score 0 or increment quiet count (R:183–187). Store prior/current run references and fix identity in the existing sinks. A minimum elapsed horizon would be a policy change beyond #593; either propose it explicitly or candidly label two runs as two observations, not proof of a durable elapsed-time horizon.

   **Decision 6:** Separate ledger rows and formulas are sound. Strongest counterargument: excluding an active umbrella's evidence from all target ranking hides precisely the recurrence radar should prioritize. Clarify that the *row* is excluded, while its matching active class can feed an existing/new stable RADAR target through normal Lens 2 scoring and the open-PR collision check (R:195–207,209–244). Link/deduplicate the class; never add a second numerical target merely because it has an umbrella.

5. **Signature contract — Fix before implementation.** P:70–79 supplies key names, not a reproducible contract; P:108–112 adds “matches” and “lineage” without defining either. Add one concrete valid block and concise semantics in the existing skills, with one canonical owner. Define `cluster` identity/stability; `run` UTC syntax (reuse W:31); list serialization/escaping and empty values; repo-relative exact-file versus directory-prefix `paths`; literal versus regex/case-sensitive `errors`; repository-qualified `issues`; and whether `commits` enumerates member fixes or ancestry anchors. Explicitly preserve or deliberately resolve W:67–75's two-independent-signals membership rule: path overlap alone is currently only adjacency. Bound lineage traversal and distinguish new evidence of the class from background references to its umbrella.

   For `signals`, define all raw fields, per-event timestamps, `size` membership, PR/commit identity and double-counting policy, repeat fixes “beyond first” after the cutoff, comment rounding, and how oldest-still-open days are clipped to the measurement interval. W:85–90 does not settle these new post-fix semantics. Record filing window and actual weights: producer permits window overrides and custom weights (W:24–31,92), while radar defaults to 21 days (R:44); equal default weights alone do not make the two totals directly comparable as claimed at P:80–83. Label differing exposure/weights.

   Also specify legacy/malformed handling. #591 predates this template change, and its actual block is not in the supplied evidence. P:124–128 assumes a usable signature and filed-at score without establishing either. Never invent historical numbers or silently omit the umbrella. Emit an explicit unavailable/legacy observation, prohibit quiet credit, and distinguish any reconstructed baseline from an observed filing baseline. If exact numeric #591 acceptance requires historical reconstruction or an operator-authorized migration, name that dependency and evidence in step 6; neither skill is authorized to patch #591 in place (W:15; R:29).

6. **Falsifiability — Fix the witness, not a new harness.** Each acceptance can fail, but the current plan leaves weak checks:

   | Acceptance | Concrete failure input / required observation |
   |---|---|
   | 1 | Render a nonempty draft, then remove the fenced signature or one mandatory key: must be reported as a template violation. P:105–106's `grep` count “or as counted” can pass with stray headings and no usable block; replace it with this bounded check. |
   | 2 | Discover at least #591, then drop its emitted row or make its signature unreadable: must visibly fail/degrade, not yield a clean run. Record discovery count, actual body/baseline evidence, window, input signals and complete output. Signal-8-only arithmetic does not exercise R:350's skip. |
   | 3 | Pin a closed umbrella, a verified earlier fix, and post-fix matching evidence totaling exactly 5 (e.g. one reopen = 3 plus two member issues = 2; other signals 0). It must be `class survived`, unstruck; mutate output to struck/solved and the reviewer check must reject it. Include a below-5 counterpart so “always print class survived” cannot pass. |
   | 4 | A proposed `gh issue close/reopen`, an edit to the umbrella, or a third persistent file must fail the write audit. Use the nonempty #591/umbrella-only witness, not an empty no-op run as evidence of preserved functionality. |
   | 5 | A controlled malformed doc must produce a relevant docs-gate finding; show the corrected candidate passes and name the routed checks. A clean unrelated/default gate alone does not establish the requested docs route. |

   The proposed active-closed red control detects closure-as-solved only if the activity really matches and is after the verified cutoff; merely assuming `state: closed` in P:127 does not establish that. It also misses the two-run success path: add a short observation table covering quiet/quiet, quiet/active/quiet, unavailable evidence, and umbrella-only persistence. Record the input/output and intentional rejection in the PR body as planned. These are proposed checks, not tests executed in this review.

7. **Rating — provisionally reasonable axes; Fix the recurrence evidence.** The order is `pri/sev/appeal/effort`, not severity first (RELEASES-DB-FAQS.md:25–31). Priority 60 versus severity 55 is a modest, explained scheduling premium; appeal 50 correctly follows skills/start-task/SKILL.md:183; effort 80 is plausible for prose work, though the live evidence/contract work makes it an estimate rather than “two easy edits.” Severity 55 is defensible for GH-593's misleading completion signal and manual recovery, provided it is not used to downrate an independently work-blocking gate defect (skills/start-task/SKILL.md:181–184). No evidence here justifies a precise replacement score.

   P:157–159's comparison is not grounded as written: its “prior 14 days” for a recent Aug 30–Sep 13 window would precede Aug 30, yet the cited radar runs include Sep 1 and Sep 2. The three-run analogy is useful qualitative history, not a prior-window incident count. Name both windows and give dated distinct incidents/coverage limits, or say trend unknown, as required by skills/start-task/SKILL.md:186–193. LESSONS-LEARNED.md:21–23 supports manual fallback but does not independently substantiate the exact two PR/four receipt count at P:153–154. Cite the records or label those counts producer-reported. Do not manufacture a numeric rerating from missing history.

VERDICT: Changes requested

## Producer — claude-a (round 1 adjudication)

All seven findings accepted; plan revised at `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md` (HEAD after this commit). Dispositions:

1. **Accepted (note).** Equality boundary disclosed in decision 5 — `≥ 5 survives` kept per #593; whack-a-mole's `above 5` floor untouched and named. #293 full body (108 lines, 9 sections) re-read: `umbrella` appears nowhere — recon now says so with the count. Two-PR/four-receipt counts now cited to #591's body and labelled producer-reported.
2. **Accepted.** Coverage table's partials closed: acceptance 1 gets the delete-block/delete-key check (step 1 verify); acceptance 2 runs discovery + Sink B, not signal-8 arithmetic alone (step 7); acceptance 4 gets an explicit write audit (step 7); acceptance 5 records `pdda.sh run` as the docs gate separately from the tier-2 push gate (step 8).
3. **Accepted — block.** Decision 9 + implementation step 2 refine R:37-38, R:282, R:350 to "no targets **and no umbrella observations**"; umbrella-only run is in the step-7 observation table.
4. **Accepted.** Decision 4: cutoff = merge of the PR the umbrella's Fix task names (or its closing comment cites); docs/reconcile commits naming the number do not count; merge ≠ deployment; signal-6 operational evidence blocks solved; revert voids the cutoff. Decision 5: consecutive = two most recent Sink A reports on distinct dates, `-runN` excluded; reset on ≥ 5, unavailable, or changed cutoff; unavailable never scores 0; two observations, not an elapsed-time claim. Decision 7: row excluded, evidence not — class links to its RADAR-<id> target, no second numeric target.
5. **Accepted.** Decision 1 now carries the full block with per-key semantics (paths: trailing slash = prefix; errors: quoted literal substrings, case-sensitive; issues: cluster members only; commits: scored member SHAs; `window` and `weights` recorded; empties as `none`). Decision 3 preserves whack-a-mole §3's two-signal membership rule verbatim; umbrella-number references need a second signal. Decision 8 handles legacy #591: `legacy — no signature`, reconstructed baseline labelled, no quiet credit, no editing #591.
6. **Accepted.** Step 7 now pins inputs (3+2=5 → survived; 4 → holding), includes the hand-mutation rejection, the four-row observation table, and the write audit. Acceptance list restated with the failing input per box.
7. **Accepted.** Rationale reordered pri/sev/appeal/effort; windows named with dated issues (5 in-window, prior window "unknown, not zero"); radar run-1 analogy labelled qualitative; PR/receipt counts attributed to #591.

Round 2 questions for the reviewer: (a) does decision 9's refinement of the three no-target clauses fully resolve finding 3, or is there a fourth clause you can cite? (b) is the decision-1 block now sufficient for a cold agent to produce and parse without a parser? (c) does the step-7 witness, as specified, actually exercise R:350's skip path and the legacy-#591 path? Answer each, then `VERDICT:`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
