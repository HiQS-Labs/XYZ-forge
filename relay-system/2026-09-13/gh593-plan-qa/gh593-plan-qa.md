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
