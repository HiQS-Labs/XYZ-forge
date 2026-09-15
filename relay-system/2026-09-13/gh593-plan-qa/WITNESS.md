## Summary

Closes #593. `whack-a-mole` files an umbrella for a recurring-defect cluster and is then stateless; "umbrella closed" was the only completion signal, and #591's chain (#421 → #425 → #546 → #584) showed that two closed fixes each exposed the next break. This PR makes `radar` the thing that measures whether a class actually stopped:

- **`skills/whack-a-mole/SKILL.md`** — the umbrella template carries a fixed-key `### Cluster signature` block (paths, error strings, member issues/commits, the six raw churn counts, run, window, weights) and owns the counting rules for any later re-score. A body without the block is a template violation. §7 report and the "already has an umbrella" edge case point at radar's row.
- **`skills/radar/SKILL.md`** — Lens 2 **signal 8, Umbrella re-score**: discover whack-a-mole-form `Umbrella:` issues, read or (for legacy umbrellas like #591) reconstruct the signature, take the cutoff from the fix PR the umbrella names, count only in-window member events strictly after it, score with the default weights, and append one row per umbrella to the recurring-targets issue under `## Umbrellas — re-scored`: `holding`, `class survived — recommend reopening` (closed but still ≥ 5), or `solved` (below 5 on two distinct-date runs after the fix — the only struck-through state). The three "no targets → write nothing" clauses now read "no targets and no umbrella observations". Boundaries table gains a `whack-a-mole` row.
- `CHANGELOG.md` entry; plan at `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md`; Codex plan QA thread at `relay-system/2026-09-13/gh593-plan-qa/` (4 rounds, last open item was reviewer-supplied fixture text, applied verbatim).

No scripts, no DB table, no third sink. Prose-only; rollback is one revert.

## Witness — radar signal 8 run by hand against this repo

Window `2026-08-23T00:00Z → 2026-09-13T23:59Z` (UTC). Every number below was produced by the command shown, not remembered.

### Discovery

```
gh issue list --state all --limit 200 --search 'Umbrella: in:title' --json number,title,state
```
**10 hits, 1 whack-a-mole-form:** #591 (`umbrella: the post-merge reconciler actually lands …`). Excluded as other tools' groupings: #224 (tracking umbrella), #497/#462/#417/#376 (`MARATHON umbrella:`), #467 (`Umbrella - Side Quest`), #257 (`[Umbrella]`), #419 (title mentions "umbrella issue"), #593 (this issue). **Finding fed back into the skill:** the first draft of signal 8 said "list `Umbrella:` issues"; the real search is case-insensitive substring, so the skill now says *begin with* `Umbrella:` and reports `N hits, M whack-a-mole-form`.

### Cutoff

```
gh pr list --state merged --limit 50 --search "591"
```
returned PR #281 (`feat(jog): recalibrate Jog …`, merged 2026-08-28) — a substring false match. The rule is "the PR the umbrella's Remediation Fix task names, or its closing comment cites": #591 names PR 1 (#546) and PR 2 (#584) as *not yet merged*. **No cutoff → full window counts.** (Verified at execution, not assumed.)

### #591 — legacy, reconstructed signature

#591 predates the template, so `filed at` is unavailable. Reconstructed from its Arc/Plan sections:

```
cluster:  post-merge-reconciler-lands
paths:    ["utils/py/wave_reconcile.py", "githooks/pre-push", ".github/workflows/wave-reconcile.yml", "TESTS-RESULTS/"]
errors:   ["No provenance.jsonl or error_log.jsonl entry matches PR", "exit 6", "--gate"]
issues:   ["#421", "#425", "#546", "#584"]
commits:  []
```

Members and in-window events (`gh issue view`, `gh api …/events`, `gh api …/comments`):

| Member | Signals (≥ 2 required) | In-window events |
|---|---|---|
| #421 | explicit link from #591 + path `wave_reconcile.py` in title | opened 2026-09-04T01:23Z; still open; 0 comments |
| #425 | explicit link + error `--gate` in title | opened 2026-09-04T01:51Z; still open; 0 comments |
| #546 | explicit link + path `.github/workflows/wave-reconcile.yml` + error `No provenance.jsonl` | opened 2026-09-10T04:06Z; 1 comment 2026-09-13T03:18Z |
| #584 | explicit link + path `wave_reconcile.py` + error `exit 6` | opened 2026-09-12T16:05Z; 1 comment 2026-09-13T03:18Z |
| `e30ceb86` `fix(GH-565): … check_provenance_receipts (--gate)` | path `wave_reconcile.py` + error `--gate` | committed 2026-09-10 |

`reopened` events on all four issues: **none**. `revert:` commits touching signature paths in window: **none**.

`fix:` commits touching signature paths in window (`git log origin/development --since … -- <paths>`): **9** (`e30ceb86 b348d9af ada4636c e99ea708 2526bf9b 7fb86363 7c4a44d2 61e01775 e2c429d9`). Only `e30ceb86` carries a second signal; the other eight touch a hot path and nothing else → **adjacency, not members**. **Finding fed back into the skill:** the first draft counted `repeat_fixes` by path-touch alone, which would have scored 8 repeat fixes (24 points) from unrelated work; membership now gates every count in both files.

Also witnessed: `git log | grep -E "421|425|546|584"` matched `c7421f24` and `e951e546` by **SHA substring** — neither closes a member. Recorded here so the next runner doesn't count them.

**Raw fields:** `reopens=0 repeat_fixes=0 reverts=0 size=5 comments=2 open_days=9`
(size = 4 issues + 1 member commit; open_days: oldest still-open member #421, `max(2026-09-04, window start)` → window end = 9 days.)
**Score** = 3·0 + 3·0 + 4·0 + 5 + floor(2/5) + floor(9/7) = **6**.

**Row as it would land on #293:**
```
- [ ] #591 — filed at legacy (no run), now 6 (2026-08-23 → 2026-09-13), fix merged not yet → holding
      cluster post-merge-reconciler-lands · baseline legacy — no signature (reconstructed) · quiet 0/2 (—, —) · class none
```
Holding, not survived: the umbrella is open and no fix has merged. The score being ≥ 5 is the point — the class is measurably alive, which is what #591's authors already believe.

### Red controls (pinned inputs; membership evidence real, event overlay labelled synthetic)

| Case | Inputs | Raw fields | Score | Rendered | Struck? |
|---|---|---|---|---|---|
| A. closed, still active | window 08-23→09-13, cutoff 2026-09-01T00:00Z; #546 opened 09-03, #584 opened 09-05, one `reopened` on #546 09-08, both closed by window end, 0 comments | `reopens=1 repeat_fixes=0 reverts=0 size=2 comments=0 open_days=0` | 3+2 = **5** | `class survived — recommend reopening` | no |
| A′. counterpart | A minus #584's opening event (no in-interval event → not counted) | `size=1` | 3+1 = **4** | `holding`, `quiet 1/2` | no |
| B. cutoff moved forward | A with cutoff 2026-09-10T00:00Z | all zero | **0** | `holding`, `quiet 1/2` | no |
| C. old fix, out-of-window churn | window 08-23→09-13, cutoff 2026-08-01; one member reopened 08-10, closed before window start, no in-window events | all zero | **0** | `holding` | no |
| C-neg. old interval restored | C scored with the *superseded* `[cutoff, window end]` rule | `reopens=1 size=1` | **4** | wrong — counts pre-window churn | — |
| D. nonzero comments and age | window 08-23T00Z→09-13T00Z, cutoff 08-29T00Z; retained member created 08-30, closed 09-07, reopened 09-08, open at end; second member 09-05→09-06; ten comments 09-09 | `reopens=1 repeat_fixes=0 reverts=0 size=2 comments=10 open_days=14` | 3+2+2+2 = **9** | umbrella closed → `class survived — recommend reopening`; umbrella open → `holding` (the fallback: fix merged, score ≥ 5, nothing to reopen), `quiet 0/2` | no |
| E. filing weights varied | A with `weights: reopen=1 repeat_fix=1 revert=1 member=1 comments=1/50 open_days=1/70` in the block | unchanged | **5** (defaults) | same as A, baseline `filed-custom (non-comparable)` | no |
| F. hand-mutated | A's row edited to `~~#…~~ → solved` | — | — | rejected by rule text: *"solved — the only state that is struck through, and only on quiet 2/2 and a fix merged PR"* — A has the merged-fix cutoff (2026-09-01) but scores 5, so it has `quiet 0/2`, not `2/2` | — |

### Observation table (same signature, default weights, verified cutoff, distinct UTC report dates)

| Run sequence | Streak | State |
|---|---|---|
| quiet (Sep 14) → quiet (Sep 21) | 2/2 | `solved`, struck |
| quiet (Sep 14) → active (Sep 18) → quiet (Sep 21) | reset at Sep 18, 1/2 | `holding` |
| quiet (Sep 14) → gh timeline unavailable (Sep 21) | reset, 0/2 | `holding`, evidence noted unavailable — never scored 0 |
| quiet (Sep 14) → quiet (Sep 14 `-run2`) | 1/2 | same-day rerun is not a second observation |

### Umbrella-only entry case

Inputs: zero ordinary targets; #591 tracked with the row above; evidence available; prior report `PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md`; run date 2026-09-13.

- Guardrails (`skills/radar/SKILL.md:37`): "No targets **and no umbrella observations** → write nothing" — one umbrella observation → proceed.
- Step 4 (`:313`): "When no targets and no umbrella observations were found …" — not the case → Structured Evidence section renders with the umbrella row.
- Step 5 (`:381`): "Skip entirely when there are no targets **and** no umbrella observations" — not the case → both sinks previewed: Sink A `PROJECT/1-INBOX/RADAR-REPORT-2026-09-13.md` with the signal-8 evidence above; Sink B #293 gains `## Umbrellas — re-scored` with the #591 row.
- **Negative control:** with the three clauses restored to their pre-PR wording ("No targets → write nothing", "no targets were found", "no targets."), the same inputs stop at Guardrails — the observation is never persisted. That is the failure this PR removes.

### Write audit

Writes the walkthrough would perform: (1) create `PROJECT/1-INBOX/RADAR-REPORT-2026-09-13.md`; (2) edit the body of #293. Nothing else. No `gh issue close`, `reopen`, or `edit` on #591; no third file.

### Template violation check (whack-a-mole)

Rendered body (tail of the issue as it would be filed — the §6 template's outer four-backtick fence is presentation only; this inner triple-backtick fence is part of the body, so the checklist above it still renders as tasks):

````markdown
## Evidence and confidence
- Churn score 6 (reopens 0, repeat fixes 0, reverts 0, size 5, comments 2, open 9d)
- What I could not verify: fix-merge state of PR 1/PR 2 beyond "not yet"
- Generated by whack-a-mole 20260913T000000Z

### Cluster signature — re-scored by radar on every run
```
cluster:  post-merge-reconciler-lands
run:      20260913T000000Z
window:   2026-08-23 → 2026-09-13
weights:  reopen=3 repeat_fix=3 revert=4 member=1 comments=1/5 open_days=1/7
paths:    ["utils/py/wave_reconcile.py", "githooks/pre-push", ".github/workflows/wave-reconcile.yml", "TESTS-RESULTS/"]
errors:   ["No provenance.jsonl or error_log.jsonl entry matches PR", "exit 6", "--gate"]
issues:   ["#421", "#425", "#546", "#584"]
commits:  ["e30ceb86"]
signals:  reopens=0 repeat_fixes=0 reverts=0 size=5 comments=2 open_days=9 score=6
```
````

Negative controls: (1) the same body with the inner fenced block deleted → §6 rule: *"A body without the fenced Cluster signature block, or with any key missing, is a template violation — do not file it."*; (2) the same body with only the `signals:` line deleted → same rule fires ("any key missing").

## Gates

- `utils/pdda/pdda.sh run` — 0 errors (27 pre-existing warnings, none on GH-593 docs).
- Pre-push gate — result recorded in the PR after push (the diff includes `releases.sql` from the intake, so the push routes to the tier-2 releases gate, not docs-only; `pdda.sh run` above is the docs gate recorded separately).

## Not in scope

Adding a real Cluster signature to #591 (whack-a-mole may not edit existing issues; an operator can). The two `MARATHON umbrella:` issues are not whack-a-mole output and are deliberately excluded from signal 8.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
