---
title: "Radar report 2026-09-21 — flow distribution, recurring targets, release recalibration (run 4)"
status: complete
created: 2026-09-21
updated: 2026-09-21
owner: radar
goal: "Run-4 read of the last 21 days on development: RGT mix, recurring/regressing defect classes, release alignment; reconcile the live board #293"
doc_type: report
---

# Radar report — 2026-09-21 (run 4)

Window: **2026-08-31 → 2026-09-21** (21 days). Trunk: `origin/development` at `bd8c6950`.
Prior window for trend: 2026-08-10 → 2026-08-31. Prior reports: `RADAR-REPORT-2026-08-28.md` (run 1),
`-09-01.md` (run 2), `-09-02.md` (run 3). Live board: #293. Tally file proven: 734 subjects = 734 bucketed
= `git rev-list --no-merges --count` 734 (prior window 805 = 805 = 805).

## Executive summary (SDLC process coach)

Over the last three weeks the team landed the things that were hurting most: the post-merge reconciler
is now *wired* and runs on every PR close (#599/#600), the headless turn-timeout family got a real
root-cause umbrella and a nine-lane delivery (#648 → #687), the Skills Army collection moved to one
Pulse-carried copy per device (#672/#675/#680), `ROADMAP.md` and its dashboard were retired in favour of
the ledger (#432/#567), and the merge lane grew a read-only deep triage (#731) and hotfix closeout
receipts (#733). Quality follow-through was fast where the defect was concrete — GH-693, GH-721,
GH-710/#716 and GH-678 each closed within a day of being observed.

At the same time the mix has slipped the wrong way: Run is **82.4%** of non-harness commits (76.9% at run 3),
Grow **11.5%** (14.2%), Transform still **0% on a declared basis** (`rgt:` adoption 0 of 321 docs). The
single biggest drag is a **regression-shaped** class: the hosted reconcile lane has failed **30 of its last
40 runs**, and five separate fixes in nine days (each from a different PR, each exposing the next break)
have not made it land reliably — today it opened #735 on a new failure class. Right behind it, the
pre-push gate went red on a *clean* trunk six different ways in five days (toolchain, `__pycache__`,
vendored layout, roadmap coverage, HOME writes, nice nesting). Both classes tax every push and every merge,
and both train operators to reach for bypasses. A short stabilisation pass on those two seams — not more
features on top of them — is what will give the Grow share room to come back.

**Recommended next step:** treat the hosted reconcile lane as the release-blocking seam it is: land the two
open items now filed under #591 (#740 the fast-forward push race when a merge lands during a run; #741 the lane
report naming a unit test's expected error instead of the real failure), and hold new merges until `gh run watch` returns green
twice in a row — completion condition: 10 consecutive green scheduled/PR-closed runs.
**Second:** finish the "gate red on clean trunk" class as one item on #732 — named environment faults for
present-but-broken tools, #730's `__pycache__` and #667's roadmap-coverage — completion: a fresh clone of
`development` passes the full gate with no re-runs on the documented PATH. **Third:** adopt `rgt:` on the
five governing docs named on #293 so the next run can measure Transform at all.

## Lens 1 — flow distribution

| Bucket | Count | Share of RGT denominator | Prior window | Run 3 |
|---|---|---|---|---|
| **Harness** (`relay*` `marathon*` `plan:` `capture:` `triage:` `wip:`) | 177 | *excluded* | 308 | — |
| **Run** | 459 | **82.4%** | 75.7% | 76.9% |
| **Grow** (`feat`) | 64 | **11.5%** | 14.7% | 14.2% |
| **Transform** (explicit `rgt:` only) | 0 | **0% (`rgt:` adoption: 0 of 321 PROJECT docs)** | 0% | 0% |
| **Unclassified** | 34 | 6.1% | 9.7% | 8.9% |

RGT denominator = **557** (prior 497; run 3 607). Doc corpus per bucket: 1-INBOX 53 · 2-WORKING 102 ·
3-COMPLETED 164 · 4-MISC 2 (321; run 3 counted 138 — a lifecycle sweep and heavy intake moved the
instrument, so citation deltas below are not compared run-over-run).

**Unclassified, verbatim (34):** `evidence(GH-…)` ×7, `jog-state:` ×6, `skill(debug-mantra)` ×3,
`GH-712: …`, `GH-642: …`, `GH-534: …`, `GH-518: …`, `pages:`, `mini(GH-677):`, `skills(GH-660):`,
`merge-cleanup:`, `draft(GH-605):`, `telemetry(gh-405):`, `site:`, `docs+fix:`, `Flightdeck HTML dashboard…`,
`Timbre and adjust consult skill…`, `Reconcile Other Apps & Tools PR 466`, `Add Other Apps & Tools…`,
`Reconcile homepage copy PR 464`, `Clarify homepage quality proposition…`.
Two source-fixable families: **component-as-type** (`evidence`, `jog-state`, `skill`, `telemetry`, `site`,
`pages`, `mini`, `skills`, `draft`, `merge-cleanup` — 22 commits) and **missing type** (`GH-NNN: …` — 4).
`jog-state:` is new this window and is machine-written by the Jog supervisor → belongs in the Harness family.

**Adjusted read** (jog-state → Harness; `evidence`/`skill`/`telemetry`/`site`/`draft`/`docs+fix`/reconcile → Run;
`pages`/`mini`/`skills(660)`/`GH-642`/`GH-518`/Flightdeck/Other-Apps/homepage/Timbre → Grow):
Harness 183 · denominator 551 · **Run ~86.8% · Grow ~13.2% · Transform 0% (undeclared)**.
Mechanical and adjusted reads agree on direction: Run up ~5–6 points on run 3, Grow down ~1–3.

## Lens 2 — recurring defects & regressions

Signal yields: (1) `related:` — 127 docs carry it, references extracted (top: GH-406 ×9, #174 ×7, #177 ×6);
all context, no new kinship cluster. (2) shared seam — 143 `fix:`/`hotfix:` commits, 323 files, **71 seams
pass the ≥2-days ∧ ≥2-PRs discriminator**. (3) issue-text similarity — 400 most-recent issues (162 open).
(4) doc-only closes — available, 2 candidates in 3-COMPLETED, neither in-window. (5) `reported_from:` — 11
docs. (6) operational evidence — **now available**: hosted `wave-reconcile.yml` run history (40 runs);
no local run-log corpus (`temp/logs` 0, third consecutive run). (7) bounceback — computed from (2).
(8) umbrellas — 12 hits, **2 whack-a-mole-form** (#648, #591), both legacy (no `### Cluster signature` block).

### Ranked targets

**1. `RADAR-class-hosted-reconcile-lane` — NEW · 9 issues · 5 fix PRs over 9 days · Recent Regression**
Cluster: #421 #454 #492 #674 #707 #711 #735 + umbrella #591 (open); GH-546/#599, #600, GH-684/686
(`43cf4452`), GH-693 (`989f5549`), GH-721/#725, GH-656/657/#733 (closed). Seam:
`utils/py/wave_reconcile.py` (10 PRs / 9 days), `.github/workflows/wave-reconcile.yml` (4 PRs),
`test/gh421-auto-wave-reconcile.sh` (6 PRs). Operational evidence: **30 failure / 7 success / 2 cancelled**
in the last 40 hosted runs; failure classes seen in order — hosted test setup (#600), exit-5 doc-debt gate
(GH-693), 1-INBOX publish guard (GH-721), `agent-chorus-bridge` red only on the runner, plain
fast-forward push rejected when a merge landed mid-run (#733 during #731's run 35623940059, 2026-09-21),
and the same rejection again on 2026-09-21 (#733 during #731's run 35623940059) — which the lane report
(#735) *misattributed* to `invalid merged_at timestamp`: that line is a gh421 unit test's expected output inside
the qualification log (followed by `ok`); the reconcile step was green and the job failed on the push step.
Filed from this run: **#740** (push race) and **#741** (report attribution). Why it recurs: the lane is one ~70-min sequential job whose last step is a
plain `git push HEAD:development`; every guard added in front of it (frontmatter, Lessons Learned, publish
allowlist, artifact allowlist) is a new way to fail after 70 minutes of green tests, and the fallback is a
manual local `wave_reconcile.py` — which is what #674 races. One durable fix: make the final push
rebase-and-retry (or refuse merges while a run is in flight) and move the cheap declarative guards to the
*front* of the job. Score ≈ 9 × 2 ÷ 1 × 1.3 ≈ **23**. **UNCLAIMED** by any band (Cargo has no milestone).

**2. `RADAR-class-gate-red-on-clean-trunk` — NEW · 7 members · 5 PRs over 5 days · Recent Regression**
Cluster: #667 (roadmap-coverage red on `origin/development`), #730 (`agent-chorus.sh` red from a leftover
`__pycache__`), #715 (11 vendored-`.xyz` suites red), toolchain present-but-broken `php` / interpreter
without `pytest`/`yaml` (#732 item 3, observed 2026-09-17 on clean `1e21b7cc`), and closed: #708
(`gh267-express-skill.sh` red from `.xyz/`), GH-710/#716 (nice nesting + `gh_number` NULL), GH-678/#680
(gate stole real-HOME symlinks). Seam: the 09-18 wave alone touched `test/gh379-canary-uses-validate.sh`,
`gh365-*`, `gh35-test-tiers.sh`, `ci-workflow.sh`, `gh267-express-skill.sh`, `gh496-phase2-*` (7 PRs / 2 days).
Why it recurs: the gate assumes a clean host and a bare layout; every environment difference (PATH order,
clone leftovers, vendored layout, another lane's uncommitted intake) surfaces as a red *suite* rather than a
named *environment fault*, so each is fixed suite-by-suite. Single durable fix: the existing skip/diagnostic
paths (`validate.sh:1409`, `gh251`, `gh268:107`) report present-but-broken tools and clone-state faults by
name, with a red control. Score ≈ 7 × 2 ÷ 2 × 1.3 ≈ **9**. **Claimed by #732** (checklist).

**3. `RADAR-class-vendored-skill-drift` — NEW · 6 issues · 4 PRs · 2026-09-12 → 09-21 · Chronic**
Cluster: #585, #676 (open); GH-660, #672, #675, #678 (closed); plus two live drifts found this run:
Pulse `radar/install.sh` predates GH-678, and `marathon-triage` is DRIFTED (pre-landing publish, disclosed).
Seam: `Deployed Skills/*` vs `skills/*`, `test/test_deploy_skills.py` (5 PRs / 2 days). Why it recurs: two
copies, two writers (skill authors and the hourly Pulse writer), and the drift gate compares `SKILL.md`
only. Durable fix: extend `skill_drift_check.py` to the whole folder digest and run it in CI on `skills/**`
changes. Score ≈ 6 × 2 ÷ 3 ≈ **4**.

**Observation, not a target — three conflict magnets.** `validate.sh` was edited by **47 of the 143** window
fix commits (suite registration = one shared array), `skills/relay-automation/relay-pkg.tar.gz` was
regenerated **13** times, and the binary `releases.db` conflicted on 3 of 4 PRs landed 2026-09-17 — and twice more on #734 today
while this report was being written (each landing on `development` re-conflicts every open ledger-touching PR). All three
are "generated or registry state committed in one file". Folded into #732 as a measurement item; the
registry half is the same derive-from-source pattern `RADAR-class-guard-blind-matcher` has asked for since
run 1.

### Carried targets (from #293)

| Target | Run-4 state | Evidence |
|---|---|---|
| `RADAR-class-vendored-root-resolution` | **worse again** — 14 members (12 at run 3): #708, #715 added; #393 closed 09-03; 8 still open (#215 #216 #253–#256 #394 #395); the `ROOT="$(cd "$HERE/.." && pwd)"` idiom is in **102** shipped files | runs: 4 |
| `RADAR-class-dark-telemetry` | partial — #346, #208 open; **signal 6 restored one instrument** (hosted run history), local log corpus still 0 | runs: 3 |
| `RADAR-class-guard-blind-matcher` | one more case-by-case derive (`383b4fd6` gh415 entrypoints from the AGENTS.md inventory); still no single helper | runs: 4 |
| `RADAR-class-roadmap-ledger-drift` | **item 1 retired**: GH-269 landed via #432 `593fdf7b` (2026-09-04); `ROADMAP.md`/`ROADMAP-DASHBOARD.md` gone from trunk (#567). Item 2 aged: same 3 migration refs now **34 days** old, 24 grandfather entries pending. New member: #711 (gid re-mint) + binary conflicts | runs: 4 |
| `RADAR-marathon_drive.py` | #290 #291 open, untouched — **unactioned across three intervals** | runs: 4 |
| `RADAR-class-headless-turn-timeout` | CLAIMED by #648; fix merged **#687 `1e434d58` 2026-09-18**; #242 #397 closed 09-18; **wave-1 members #237 #241 #276 #285 #480 #521 still OPEN with zero post-cutoff activity** — the delivery did not close its ledger. Candidate 13th member: #720 (review-once misgrades a real block as a stall — same oracle overclaim) | runs: 4 |
| `RADAR-class-frozen-twin-dead-fix` | 10 FROZEN twins unchanged; no guard widening cited | runs: 4 |
| `RADAR-agy-auth-preflight` | #227 open, no commit names it — **quiet, unexplained ×3** | runs: 4 |

### Open-PR collision check (Step 2b)

4 open PRs. #734 (GH-732 intake, **CONFLICTING** since #733 landed) — overlaps target 2 by issue number;
intake only, no fix; *blocked/stale work: refresh before merge, does not cover the target*. #726 (GH-724
marathon-triage, MERGEABLE) and #723 (GH-646, draft, CONFLICTING) — no target overlap. #729 (GH-720 intake,
MERGEABLE) — adjacent to `headless-turn-timeout`; intake only. **No open PR addresses targets 1 or 3 —
no work underway.**

### Umbrellas — re-scored (signal 8)

- #648 — filed at 25 (`20260916T190147Z`, legacy prose, no signature block → **reconstructed**), fix merged
  2026-09-18 #687; post-cutoff 09-18T19:05Z → 09-21: reopens 0, repeat_fixes 0, reverts 0, size 0, comments 0,
  open_days 3 → **score 0**; but `filed at legacy` earns no quiet credit → **holding · quiet 0/2** ·
  class `RADAR-class-headless-turn-timeout`. Six wave-1 members remain open: close them citing #687 lanes or
  say why not.
- #591 — filed 2026-09-13 (hand-written, no signature → **reconstructed** from body: paths
  `wave_reconcile.py` / `wave-reconcile.yml` / `githooks/pre-push`, issues #421 #454 #546 #565), fix merged
  2026-09-13 #600; post-cutoff: repeat_fixes **2** (`989f5549`, `a3125bfe` after `43cf4452`), reverts 0,
  reopens 0, size 6, comments 1, open_days 8 → **score ≈ 13** and signal 6 shows the class firing now
  (30/40 red, #735 today) → **holding — class alive** · class `RADAR-class-hosted-reconcile-lane`.

## Lens 3 — release recalibration

`releases check`: clean, 0 failures, 9 warnings; generation **968**; 13 releases. Active: **0.9.0 Cargo**
(30 items, **2 days past its 2026-09-19 target**, `release-overdue`). Drafts: 0.6.0 Front-Door (target
09-26, 9 items), 0.8.0 Sundown, 0.4.0 Plumbline, 0.5.0 Lantern. Milestones now exist for **Bulkhead and
Ballast only** (both shipped) — the join is impossible for every unshipped release, so the orphan share
(**162/162 open issues, 100%**) still measures a missing binding, not backlog drift (fourth consecutive run).
Plan vs execution: Cargo's `Description:` is the vendored/consumer-repo band; the window's effort went to
the reconciler lane, the gate, and skills deployment — targets 1–3 are **UNCLAIMED** by any band. The plan
says "Cargo ships consumer-repo readiness by 09-19"; the repo is doing "make the lane that lands PRs land".
Advisory: either bind a `Cargo` milestone and move its date, or ship it on the landed scope.

## Degradation

Applied rows: **no local run-log corpus** (signal 6 partially restored via hosted run history);
**legacy umbrellas** (no signature blocks — both re-scores are reconstructed baselines, no quiet credit);
**milestone join unavailable** for unshipped releases. Cost: turn-timeout recurrence is measurable only via
git/gh, not runtime; orphan share is arithmetically forced.

## Checklist as generated (historical copy — live copy is #293)

New this run: `RADAR-class-hosted-reconcile-lane` (4 items: #740 the final push must survive a concurrent
landing; #741 the lane report must name the failing step's real error; declarative guards to the front of the
job; close #421 as landed-by-#599 or say what is left),
`RADAR-class-gate-red-on-clean-trunk` (→ #732 B.1/B.2), `RADAR-class-vendored-skill-drift` (whole-folder
digest in `skill_drift_check.py`; re-vendor `radar/install.sh`). Carried: `RADAR-class-roadmap-ledger-drift`
item 1 struck citing `593fdf7b` (#432); new item for the ledger binary as a conflict magnet (#711, #732 C.1,
#496 Phase 3). `RADAR-class-headless-turn-timeout`: new item — close the six open wave-1 members against
#687's lanes or reopen the umbrella's claim. All other items carried unchecked; `runs:` incremented; hygiene
items carried (rgt: 0/321; `jog-state:` added to the Harness family request; milestones: 2 created for
shipped releases, none for Cargo).
