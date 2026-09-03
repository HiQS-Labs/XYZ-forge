---
title: "Radar report 2026-09-02 — flow distribution, recurring targets, release recalibration (run 3)"
status: active
created: 2026-09-02
updated: 2026-09-02
owner: orchestrator (Claude Code)
goal: record one windowed, cited read of where effort actually went, which defects recur, and where the plan has drifted — reconciled against RADAR-REPORT-2026-09-01.md
doc_type: report
---

# Radar — 2026-09-02 (run 3)

Window: **2026-08-12 → 2026-09-02** (21 days). Trunk: `development` at `1b6058d7`.
Prior runs: [`RADAR-REPORT-2026-09-01.md`](RADAR-REPORT-2026-09-01.md) · [`RADAR-REPORT-2026-08-28.md`](RADAR-REPORT-2026-08-28.md)
Live checklist: issue #293. Tracking issue for the skill itself: GH-442.

## Why this run exists, and what it corrects in run 2

Run 2 measured local `development` at `bb0d5d6a` and reported a **blocker**: 57 unpushed commits
including local merges of PRs #356 and #364, which GitHub then showed as open and `CONFLICTING`.

**That blocker is resolved, and run 2's remedy was not the one taken.** Reconstructed from
`git reflog show development`:

| Reflog entry | Action |
|---|---|
| `development@{10}` | local merge commit `2a41968d` (PR #364) |
| `development@{9}` | local merge commit `bb0d5d6a` (PR #356) — **the state run 2 measured** |
| `development@{8}` | **`reset: moving to origin/development`** → `c3fae2d1` |
| `development@{7..0}` | eight successive `merge origin/development: Fast-forward` |

Both local merge commits were **discarded, not pushed**. `git merge-base --is-ancestor` confirms
neither `bb0d5d6a` nor `2a41968d` is an ancestor of current `development`. The work landed through
GitHub instead: PR #356 merged 2026-09-02T05:11Z, #364 at 05:23Z, #378 at 15:21Z.

**No work was lost.** Six representative GH-353 / GH-360 commits (`097de4fe`, `4fd6b164`,
`983009bd`, `f8a1ff28`, `ff5afd40`, `ec2a3248`) were each checked with
`git merge-base --is-ancestor` and are all present in `1b6058d7`. Local and origin are identical;
zero open pull requests.

Run 2's report is left unedited, as an immutable snapshot that was accurate when written.

**Machine of record for that run:** `noels-Mac-Studio.local` (this host). Run 2's prose called it a
"laptop"; it is a desktop, and no second machine was involved.

## Degradation applied this run

| Row | Cost to the verdict |
|---|---|
| **History < ~2 windows** | Repo history begins **2026-08-15**. The prior 21-day window (2026-07-22 → 2026-08-12) holds **0 commits**, proven by both `wc -l` and `git rev-list --count`. **Still no trend line** across windows; all trend statements below compare run 2 to run 3, four days apart, not window to window. |
| **`gh` false negative inside the sandbox** | Unchanged and re-confirmed: `gh auth status` reports an invalid token under the sandboxed shell and ✓ Logged in unsandboxed. All `gh` results here were gathered unsandboxed. |
| **Signal 6 still structurally unavailable** | **0 logs** under `relay-system/logs/`, `run-logs/`, `temp/logs/`. Second consecutive run with no operational corpus (run 1 read 83). No "is this class firing right now" claim is possible in either direction. |
| **Milestone join still impossible** | Unchanged. Five unshipped releases name `Cargo`, `Front-Door`, `Sundown`, `Plumbline`, `milestones`; GitHub has only `Bulkhead` (0 open / 8 closed) and `Ballast` (0 open / 5 closed). Claim status read from `blurb`/`exit` prose. |

`PROJECT/**`, `gh`, and the releases DB were available and healthy.

---

## Lens 1 — flow distribution

**Tally proven before bucketing.** `wc -l` = **998**, `git rev-list --no-merges --count` = **998**,
bucket counts sum to **998**. Prior window: 0 by both methods.

| Bucket | Count | Share of RGT denominator | Run 2 |
|---|---|---|---|
| **Harness** | 391 | *excluded* | 346 |
| **Run** | 467 | **76.9%** | 76.7% |
| **Grow** (`feat`) | 86 | **14.2%** | 14.4% |
| **Transform** (explicit `rgt:` only) | 0 | **0% (`rgt:` adoption: 0 of 138 PROJECT docs)** | 0% |
| **Unclassified** | 54 | **8.9%** | 8.9% |

RGT denominator = **607**.

**The mix has not moved.** Three runs, three near-identical distributions. 112 new commits since
run 2 changed the Run share by 0.2 points.

### `rgt:` adoption is now three runs old at zero

Zero of 138 PROJECT docs carry the key. Transform reads 0% because **nothing is declared**, not
because nothing transformative happened — and this window contains at least two candidates
(the GitHub Pages site, `d979ee28`; the cross-device AgentChorus bridge, `f3bf270d`). The
recommendation has been made in runs 1, 2, and 3 and actioned zero times.

### Unclassified: the same two de-facto types, now larger

| Prefix | Run 2 | Run 3 |
|---|---|---|
| `evidence:` | 10 | **14** |
| `release(x):` | 10 | **10** |
| no prefix at all | 12 | 12 |
| `reconcile:` | 2 | 2 |
| singletons (`site:`, `jog-state:`, `dogfood(x):`, `review(x):`, `queue(x):`, `repro.sh:`, `skills:`, `ship(x):`, `audit(x):`, `launch:`, `XYZ:`, `Ballast…`, `GH-1/5/15/23:`) | 14 | 16 |

`evidence:` **grew by four in one day** and is now the single largest unclassified family. These
are well-formed, consistently-used commit types that no parser recognises. **The convention is what
should change** — register `evidence` and `release` as recognised types in the commit SOP, or map
them to `docs:` / `chore:`.

### Adjusted read

Reclassifying the 54 by subject (~6 → Grow, ~48 → Run): **Run ~84.7% / Grow ~15.3% / Transform 0%
(undeclared)**. As in both prior runs, the adjusted read moves the mix *further* toward
maintenance, not less.

---

## Lens 2 — recurring-defect radar

### Signal yields

| Signal | State | Yield |
|---|---|---|
| **S1 `related:`** | available | **73 docs carry `related:`** (run 2: 58). Both block-array and filename-scalar shapes parsed. |
| **S2 shared seam** | available | Registration-and-guard commits dominate the delta; see T3. `validate.sh` excluded again as a false seam (it is the suite registry). |
| **S3 issue similarity** | available | **242 issues (100 open / 142 closed)**, up from 234. |
| **S4 false closes** | available; genuinely near-empty | 142 closed issues exist. Literal doc-only-close grep returns only policy/report text. **A real negative result.** |
| **S5 `reported_from:`** | available | **14 capture docs** (run 1: 7, run 2: 10). `rebalanceOS` **5** (was 2), `LTVera-Pandas` 4, `aegis-sleuth-slack-bot` 3, `ltvera` 2. **Grew by 4 docs in one day.** |
| **S6 operational evidence** | **structurally unavailable, second run running** | 0 logs. |

### Doc-corpus drift check

| Bucket | Run 1 | Run 2 | Run 3 | Δ (2→3) |
|---|---|---|---|---|
| `1-INBOX` | 22 | 26 | **29** | +3 |
| `2-WORKING` | 19 | 32 | **37** | +5 |
| `3-COMPLETED` | 55 | 64 | **72** | +8 |
| `4-MISC` | 0 | 0 | **0** | 0 |
| **Total `.md`** | 104 | 120 | **138** | +18 |

No lifecycle sweep — every bucket grew, none shrank. Citation deltas are attributable to genuine
intake. `3-COMPLETED` grew fastest this delta (+8), the first time completion has outpaced intake
across a Radar interval.

---

### Ranked targets

#### T1 · `RADAR-class-vendored-root-resolution` — score ≈ 9.0 · **↑ again, worst trajectory in the repo**

Scripts and generators resolve paths against the bare repo layout and break under a vendored
`.xyz/` install, or against a stale vendored copy.

| Run | Members | Consumer repos |
|---|---|---|
| 1 | 7 | 3 |
| 2 | 9 | 4 |
| **3** | **12** | **4** |

Closed since run 2: **#353**. Newly filed **today**: **#393**, **#394**, **#395** —

- **#393** — `find-harness.sh RELAY_HAS_DEEPSEEK gate checks for a "dsh" CLI the DeepSeek install does not provide`
- **#394** — `Vendored .xyz staleness silently breaks the "one-line profile" shortcut`
- **#395** — `Exporting XYZ_HARNESS before find-harness.sh --env silently collapses…`

Plus `852aafb5 fix(GH-346): --env never emitted RELAY_AGENT, so the documented one-liner could not run`.

Still open: **#215, #216, #253, #254, #255, #256, #393, #394, #395**.

**Run 1's acceptance condition was "no consumer repo files an eighth." Runs 2 and 3 have since
produced the eighth through the twelfth.** Every one has been fixed individually. **The shared
root-resolution helper still does not exist.** `reported_from:` docs grew 7 → 10 → 14 across the
three runs, and `rebalanceOS` alone went from 2 to 5.

Note the shift in shape: runs 1–2 were about *path arithmetic* (`ROOT="$(cd "$HERE/.." && pwd)"`);
#393–#395 are about *environment and staleness* — the harness resolving to the wrong install, a
stale vendored copy, or an exported variable defeating discovery. **The same class has widened from
"where is the root" to "which harness am I actually running."** A helper that fixes only the first
half will not retire #393–#395.

**Claimed by 0.9.0 `Cargo` (active).** The band is right; the method is not.

#### T2 · `RADAR-class-dark-telemetry` — score ≈ 5.5 (was 9.0) · **substantially retired, citable**

Instruments reporting a state they never measured. **This target moved more than any other, and
every retirement below cites a commit that names the seam.**

| Member | Run 2 | Run 3 | Citation |
|---|---|---|---|
| #370 mid-turn blindness | OPEN | **CLOSED** | worktree-progress telemetry landed |
| #377 telemetry completeness | (not yet a member) | **CLOSED** | `ad2f288d fix(GH-377): the telemetry completeness self-check never ran — grep -c double-print` |
| #365 test-suite recalibration | open as PR #378 | **CLOSED**, PR #378 merged | `bce674ba fix(GH-365): make worker telemetry real — export the surface, shard the writers, fix the skip-count double-print` |
| #327, #329, #330, #184, #180 | CLOSED | CLOSED | run 2 |
| #346 | OPEN | **OPEN** | — |
| #208 low-swap sampler is darwin-only | OPEN | **OPEN** | — |

**The class was also adopted as policy.** `AGENTS.md:100` now reads:

> **A check that cannot fail is not a check.** A passing assertion is evidence only once you have
> seen it fail.

and `67e3d937 docs: pin "a check that cannot fail is not a check" in AGENTS.md §6, and track the
2026-09-01 radar report` names the radar report as its source. Supporting evidence that the fixes
are real rather than cosmetic: `921b472d fix(gh379): address Codex review — both [Must]s were real,
and one of my fixes was vacuous too` — a self-caught vacuous assertion, which is this class
detecting itself.

**Two open members remain (#346, #208), and one structural gap:** the run-log corpus is still
absent for a second consecutive run. A repo whose defect class is *"the instrument is dark"* has
now gone two Radar runs with no instrument corpus. **UNCLAIMED** by any release band; nearest home
0.5.0 `Lantern` remains `draft` with exit criterion `NOT BUILT`.

#### T3 · `RADAR-class-guard-blind-matcher` — score ≈ 4.0 (was 6.4) · **last item now has citable progress**

Guards whose matcher is hand-written rather than derived from the authoritative source.

The one item outstanding at run 2 — *generalize the derive-from-source pattern into a reusable
helper* — has substantial named progress:

- `f1b59bd0 fix(GH-377): registry guards classify development's new suites — the audits firing on real drift`
- `dba7deba fix(test): register agent-chorus-bridge.sh in validate.sh and clean test literals`
- `91b294aa` / `4fb723bc` / `8189b983` — register `gh369`–`gh374` in `validate.sh`
- `39ba97c4 fix(gh384): the A3b fixture read as a credential literal to security-scan`
- `44eeb571 fix(gh384): the new A2 assertion piped into grep -q, which GH-139 bans`
- `05ec6a75 docs+fix: the guards read comments — reword the eval example, and say so in SOP`

**Not struck.** The pattern is being applied case by case and the guards are demonstrably catching
real drift, but no single reusable helper is cited. Score falls; the item stays open with its
progress recorded.

#### T4 · `RADAR-class-roadmap-ledger-drift` — score ≈ 4.0 · **two closes, core fix still unlanded**

Closed since run 2: **#360**, **#353**. Still open: **#69, #253, #269**.

**GH-269 (releases.db as sole roadmap truth) remains open and unlanded across all three runs** —
the longest-standing unactioned item on this board.

DB health is good and improving: `releases check` clean, **0 failures / 8 warnings**; generation
trio at **359**; receipt chain intact (**400 receipts**). Ledger hygiene work landed:
`e5447ac4 chore(releases): cancel the 0.7.4 Linux-RC, re-home its non-Linux work to 0.9.0` and
`ea983859 … promote 0.9.0 to active`.

**The 8 warnings have not moved and have aged.** The same eight migration refs are now **15 days
old against a 7-day threshold** (14 at run 2), and the same **24 `grandfather_entries`** remain
pending. Both block the strict flip.

#### T5 · `RADAR-marathon_drive.py` — score ≈ 4.5 · **unchanged, unactioned**

#290 and #291 both still open. Neither run-1 nor run-2 checklist item was actioned across two
intervals.

#### T6 · `RADAR-class-headless-turn-timeout` — score ≈ 2.0 · **unchanged, and still unmeasurable**

#237, #276, #285 all still open. No commit in the delta names any of them. Second consecutive run
with no log corpus, so the evidence base has not merely stalled — it does not exist. The single
checklist item remains the precondition for measuring this target at all. **UNCLAIMED.**

#### T7 · `RADAR-class-frozen-twin-dead-fix` — held at top-3 on mechanism

**10 FROZEN twins** under `relay-automation/`, unchanged from run 2. No commit widens
`test/gh308-frozen-twin-guard.sh` beyond its merge-base range scope. **Claimed by 0.8.0 `Sundown`**,
whose exit criterion still reads verbatim **"Exit: NOT WRITTEN."**

#### T8 · `RADAR-agy-auth-preflight` — **quiet, unexplained (second consecutive run)**

**#227 still open.** No commit or PR in the delta names #227 or the agy `whoami` seam. Per the
symptom-masking rule this is **not struck**, and the annotation now carries a second run's weight:
`quiet, unexplained across two runs — the #245 cross-call-site invariant may be masking #227 rather
than covering it.` One verification command settles it.

---

### New this window, not yet a target

Two pieces of genuinely new capability landed, neither of which is defect-shaped:

- **GitHub Pages site** — `d979ee28 feat: GitHub Pages site — static pages + ledger-driven roadmap and models pages`, plus `1b6058d7 docs(SOP): site maintenance section`.
- **Cross-device AgentChorus bridge over Cloudflare Tunnel** — `f3bf270d` (GH-384, PR #386 merged).

**One governance response is worth recording as a positive finding:**
`2415dfc4 docs: never open a network path into the operator's machine without asking` landed
alongside the tunnel work. A capability that opens an inbound network path arrived with its own
guardrail in the same window, rather than after an incident. Noted here so a later run can tell
whether that discipline held.

Both are **candidates for `rgt:` declaration** — see the measurement-hygiene item.

---

## Step 2b — open-PR collision check

**Zero open pull requests.** Every PR relevant to a target has merged: #356 (T1), #364 (T4),
#378 (T2), #386 (new capability).

**No open work claims any target.** All eight are available to schedule, and none carries a
duplicate-work risk. This is the cleanest collision picture across the three runs — run 2 found
three open PRs, all conflicting.

---

## Lens 3 — release recalibration

### The milestone join is still impossible

| Release | Status | `milestoneRef` | Exists on GitHub? |
|---|---|---|---|
| 0.9.0 | **active** | `Cargo` | ✗ |
| 0.6.0 | draft | `Front-Door` | ✗ |
| 0.8.0 | draft | `Sundown` | ✗ |
| 0.4.0 | draft | `Plumbline` | ✗ |
| 0.5.0 | draft | `milestones` | ✗ |

0.7.4 no longer appears — cancelled this window (`e5447ac4`), correctly, with its non-Linux work
re-homed to 0.9.0. That is good ledger discipline and is the one Lens 3 item that improved.

### Orphan share: 100 of 100 open issues (100%)

Third consecutive run at 100% (81/81 → 104/104 → 100/100). **This measures a missing binding, not
backlog drift** — with no live milestone for any unshipped release the figure is arithmetically
forced. Until milestones exist, no Radar run can answer whether a milestone's issue set has drifted
from its theme.

### Does the active arc's description still describe where effort goes?

**Yes on subject, and the gap from run 2 has widened on method.**

0.9.0 `Cargo` is about the harness travelling with its ledger into vendored `.xyz/` installs. That
is where the effort goes. But the arc is being delivered as **twelve individually-patched
resolution defects across four consumer repos**, three of them filed today, and the class has
widened from path arithmetic into environment and staleness. The plan is right. The absence of one
shared resolver is what keeps producing members.

### Claimed vs. unclaimed

| Target | Claim | Movement since run 2 |
|---|---|---|
| T1 vendored-root-resolution | **CLAIMED** — 0.9.0 `Cargo`, active | **worse** (9 → 12 members) |
| T2 dark-telemetry | **UNCLAIMED** — nearest 0.5.0 `Lantern`, draft, `NOT BUILT` | **much better** (3 closes + policy adoption) |
| T3 guard-blind-matcher | residue unclaimed | better (named progress) |
| T4 roadmap-ledger-drift | **CLAIMED** — GH-269, open | mixed (2 closes, core fix unlanded, warnings aged) |
| T5 marathon_drive.py | **UNCLAIMED** | unchanged |
| T6 headless-turn-timeout | **UNCLAIMED** | unchanged, still unmeasurable |
| T7 frozen-twin-dead-fix | **CLAIMED** — 0.8.0 `Sundown`, exit `NOT WRITTEN` | unchanged |
| T8 agy-auth-preflight | **UNCLAIMED**, quiet-unexplained ×2 | unchanged |

Four of eight remain unclaimed. Two more are claimed by draft releases whose exit criteria are
explicitly unwritten.

---

## Verdict

The repo **acts on Radar findings** — T2 is the proof, with three issues closed against named
commits and the class written into `AGENTS.md` as policy in four days. That is the fastest
finding-to-governance loop across the three runs.

The counter-observation is that the **structural** recommendations have moved zero times in three
runs: `rgt:` adoption, commit-type registration, milestone creation, GH-269, and above all the
shared root resolver. Defect-shaped findings get fixed quickly; convention-shaped and
architecture-shaped findings do not get picked up at all.

T1 is the cost of that. It is the only target getting **worse every run**, it is claimed by the
active release, and its twelfth member was filed the same day this report was written.

---

## Reconciliation notes for the next run

1. **Run 2's blocker resolved by discard, not push.** `bb0d5d6a` and `2a41968d` are dangling; do
   not look for them in `development`'s history.
2. **S6 has been unavailable for two consecutive runs.** If logs return, T2 and T6 both become
   measurable; record the count either way so the drift stays visible.
3. **T1's class has widened** from path arithmetic to environment/staleness resolution. Score it on
   the wider definition; a helper fixing only path arithmetic will not retire #393–#395.
4. **Never strike on symptom disappearance alone.** T8 is annotated *quiet, unexplained* for a
   second run. T3 and T7 remain causally linked to T1 and T2.
5. **`gh` lies inside the sandbox.** Re-run `gh auth status` unsandboxed before concluding the
   tooling is unavailable.
6. **`3-COMPLETED` outgrew intake for the first time** (+8 vs +3 in `1-INBOX`). Watch whether that
   holds — it is the first sign the 2-WORKING backlog may be draining.
