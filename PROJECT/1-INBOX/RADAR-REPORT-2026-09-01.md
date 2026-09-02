---
title: "Radar report 2026-09-01 — flow distribution, recurring targets, release recalibration (run 2)"
status: active
created: 2026-09-01
updated: 2026-09-01
owner: orchestrator (Claude Code)
goal: record one windowed, cited read of where effort actually went, which defects recur, and where the plan has drifted — reconciled against RADAR-REPORT-2026-08-28.md
doc_type: report
---

# Radar — 2026-09-01 (run 2)

Window: **2026-08-11 → 2026-09-01** (21 days). Trunk: local `development`.
Prior run: [`RADAR-REPORT-2026-08-28.md`](RADAR-REPORT-2026-08-28.md) · Live checklist: issue #293.
Tracking issue for the skill itself: GH-442.

## Blocker found during analysis (not a Radar target — a state fact)

**Local `development` is 57 commits ahead of GitHub's `development` and 4 behind.**

- Local `development` = `bb0d5d6a`
- GitHub `repos/{owner}/{repo}/git/ref/heads/development` = `c5a385b9` (queried live, not from a stale remote ref; `.git/FETCH_HEAD` timestamped Sep 1 20:13)

The 57 unpushed commits include **two local merge commits for pull requests GitHub still lists as
open and `CONFLICTING`/`DIRTY`**:

| PR | Local merge | GitHub state |
|---|---|---|
| #356 — `feat(vendor): audit and prompt for target ROUTER.md ROADMAP.md frozen status (GH-353)` | `bb0d5d6a` | open, CONFLICTING, DIRTY |
| #364 — `fix(releases): scoped check --rebuild and accurate receipt-chain phrasing (GH-360)` | `2a41968d` | open, CONFLICTING, DIRTY |

Consequences, in order:

1. **Data-loss exposure.** All GH-353 (15 QA rounds) and GH-360 (5 QA rounds) work exists only on
   this machine.
2. **Collaborators see wrong state.** Anyone reading GitHub sees two conflicting open PRs whose
   work is in fact merged locally; a rebase or a duplicate fix is the natural next move for them.
3. **The divergence is two-sided.** 4 commits exist on origin that local does not have, so this is
   a diverged branch, not a fast-forward push.

Radar does not act. The operator's next move is to reconcile and push before any further work
lands on `development`.

## Degradation applied this run

| Row | Cost to the verdict |
|---|---|
| **History < ~2 windows** | Repo history begins **2026-08-15** (`XYZ: initial public release`). The prior 21-day window (2026-07-21 → 2026-08-11) holds **0 commits**, proven by both `wc -l` and `git rev-list --count`. **There is still no trend line.** All recurrence spans are measured in days. |
| **`gh` false negative inside the sandbox** | `gh auth status` reported *"The token in default is invalid"* under the sandboxed shell and **✓ Logged in** when re-run unsandboxed. Every `gh` result in this report was gathered unsandboxed. A run that trusted the first result would have silently lost Lens 2 signals 3–5, the open-PR check, Lens 3, and Sink B. |
| **Signal 6 corpus vanished** | The prior run read **83 logs** under `relay-system/logs/` + `run-logs/`. This run finds **0** — `relay-system/logs/*.log` does not glob and `run-logs/` does not exist. This is **corpus drift, not a clean sweep**: the instrument was removed, so "is this class firing right now" is unanswerable. It makes T6's outstanding instrumentation item *more* necessary, not less. |
| **Milestone join still impossible** | The releases DB names milestones `Cargo`, `Front-Door`, `Sundown`, `Plumbline`, `milestones`. GitHub has exactly two milestones, `Bulkhead` and `Ballast`, **both fully closed**. No unshipped release's `milestoneRef` resolves. Claim status below was read from each release's `blurb`/`exit` prose. |

`PROJECT/**` and the releases DB were available and healthy.

---

## Lens 1 — flow distribution

**Tally proven before bucketing.** Subjects written to a file with
`/usr/bin/git log --no-merges --since=2026-08-11 --until=2026-09-02 --pretty='%s' development`;
`wc -l` = **886**, cross-checked against `git rev-list --no-merges --count` = **886**. Bucket
counts sum to **886**. Prior window: `wc -l` = 0, `rev-list` = 0.

### Mechanical read

| Bucket | Count | Share of RGT denominator |
|---|---|---|
| **Harness** (`relay*` `marathon*` `plan:` `capture:` `triage:` `wip:`) | 346 | *excluded from denominator* |
| **Run** (`fix` `chore` `docs` `refactor` `test` `ci` `hotfix` `cleanup` `style` `build` `perf` `revert`) | 414 | **76.7%** |
| **Grow** (`feat`) | 78 | **14.4%** |
| **Transform** (explicit `rgt: transform` only) | 0 | **0% (`rgt:` adoption: 0 of 120 PROJECT docs)** |
| **Unclassified** | 48 | **8.9%** |

RGT denominator = **540**.

**Read the Transform figure precisely.** Zero docs carry an `rgt:` key — unchanged from run 1, and
the remedy the prior report recommended (adopt `rgt:` on GH-105/GH-269/GH-280) **has not been
adopted**. `0%` still means *nobody has declared anything*, not *no transformative work happened*.
The figure cannot move until the key is adopted. This is now a **two-run-old open recommendation**.

### Unclassified subjects, verbatim (48)

```
jog-state: intake + lease for GH-314 (execution gh314-exec3) — supervisor-owned ledger, doc, and view writes committed before dispatch (GH-292 F1)
dogfood(gh222): executor + vendored run receipts, findings record (issue #310)
review(gh290): orchestrator fixups — pipe idiom, T2.17 wording-agnostic, gate registration
reconcile: promote GH-271, GH-272, GH-273, and GH-280 recon docs to 3-COMPLETED (PR #274)
reconcile: promote GH-280 doc to 3-COMPLETED and refresh views (PR #281)
evidence: the gate is green — F-025 closed, measurement hygiene recorded
release(0.7.4): dial in Linux-RC ahead of Cargo — #204, #205, #123 marathon lanes
release(0.7.3): SHIP Bulkhead (evidence receipted, #179 closed) + capture GH-223 gate-push double-apply into Cargo
release(0.7.3): ship-with-evidence for all 13 completed Bulkhead members; regen views; kanban sync
queue(gh222): dial #222 (tracking-issue re-point) into 0.7.3 Bulkhead — intake doc, ROADMAP park, ledger sync + regen; sweep gate-run eval rows
evidence: confirm the gate number on a clean tree, and say why it moved
evidence: PR body for round 2, with the gate status disclosed up front
evidence: correct two wrong attributions; F-031/F-032 and the false greens
evidence: diagnose all 9 gate failures — 4 are repo bugs, not host quirks
evidence: round 2 — MSYS2 follow-up for PR #29, sed bug promoted to the ledger
release(bulkhead): extend 0.7.3 with the Gen 3.5 soak cohort #180-#184 (#179)
release(0.7.3): cut Bulkhead — 7-member harness-reliability manifest, capture docs, preflighted marathon plan (#179)
release(daybreak): ship 0.7.2 — manifest items #82-#87 shipped with evidence, GH #77/#82-87 closed
Fix broken bash syntax in commandcode-turn.sh and gh460-pipe-buffer-sigpipe.sh
Add Agent2Agent - Codex Sol incident
evidence: post-push gate triage, sed-severity finding, and PR-BODY disclosure
repro.sh: guard the mktemp path before cd — the repo's own GH-177 gate caught it
evidence: three marathon runs complete, findings F-015..F-026, packaged deliverables
evidence: phase 4-5 — agy fix verified live, run 1 complete, findings F-015..F-023
evidence: Linux bring-up phases 0-3 (env, command map, baseline suite, findings F-001..F-014)
release(0.9.0): cut Cargo — vendor the RELEASES DB + timeline generator into .xyz (GH-105)
skills: install relay-xyz and consult for Codex and Gemini/Antigravity too
merge + fix(GH-10): refresh onto development a350b2d; adopt gh90 suite the guard caught
release(0.7.2): cut Daybreak and hand the marathon from GH-10 to GH-77
ship(GH-32): release 0.7.1 Bulwark + reconcile both ledgers against GitHub
release(0.7.1): cut Bulwark — the RELEASES ledger survives a git merge
audit(tooling): portable, non-destructive repro scripts
GH-23: address Agy code review — negative control + scope.js double-fold fix
release(ballast): mark Ballast 0.7.0 Shipped after verified release-gate run
Add timed Agent2Agent invitations
Clarify timed Agent2Agent doorbell watches
Ballast 0.7.0: land #4 and #3, cut #10, write the release's exit criterion
GH-15: finalize ten-run stranger verification (10/10 clean) + re-derive Ballast wave 1
Ballast: post-merge reconciliation for #14 and #15 (PR #21, PR #20)
Ballast preflight round 1: contracts made valid + acceptance normalization
Ballast capture docs: five 2-WORKING docs with bug-polarity swarm contracts; ROADMAP pointer lines
Ballast 0.7.0: open the release block — exit criterion written first (NOT BUILT, red on arrival), manifest frozen on creation, non-goals stated
GH-5 PR#7 split: land the unit-test half, drop the reader quarantine (-> #14)
GH-1 PR#6 review fixes: un-mangle TESTS comments; init check above both case blocks, pinned; mutation control recorded
launch: forward-port the artifact build's audit + build scripts onto main (Part 0 reconciliation)
GH-5: readAllEvents quarantines corrupt event files; add node:test unit runner for src/
GH-1: shared resolved-containment require_fixture + suite-wide clone-identity invariant gate
XYZ: initial public release
```

### Source-fixable measurement defect — unchanged from run 1, and now provably static

**38 of the 48 unclassified commits fall into two malformed-prefix families**, both correctly-typed
work that a strict conventional-commit parser silently discards.

- **Component-as-type / unregistered type** (~28): `evidence:` ×10, `release(x):` ×10,
  `reconcile:` ×2, plus `queue(x):`, `dogfood(x):`, `review(x):`, `jog-state:`, `skills:`,
  `repro.sh:`, `audit(tooling):`, `ship(GH-32):`, `launch:`, `XYZ:`.
- **Bare issue-ID or component as type, colon present but type absent** (~10):
  `Ballast 0.7.0:`, `Ballast preflight round 1:`, `Ballast capture docs:`, `Ballast:`, `GH-23:`,
  `GH-15:`, `GH-5:`, `GH-5 PR#7 split:`, `GH-1:`, `GH-1 PR#6 review fixes:`.

Two of these are **not sloppiness but de-facto conventions**: `evidence:` (10) and `release(x):`
(10) are used consistently and well-formed — the repo has two commit types that no parser knows
about. **The convention is what should change**, in one of two directions: register `evidence` and
`release` as recognised types in the repo's commit-message SOP, or map them to `docs:`/`chore:`.
Compensating for this inside every consuming parser forever is the wrong fix.

**This finding is byte-identical to run 1's.** Every one of the 45 unclassified subjects from the
prior window reappears here (the window overlaps), plus 3 new ones — and **not one commit in the
4-day delta adopted a registered prefix for `evidence:` or `release(x):`**. The recommendation was
made and not acted on.

### Adjusted read

Reclassifying the 48 by reading their subjects (~6 → Grow: `skills:`, `launch:`, `GH-5:`, `GH-1:`,
`Add Agent2Agent…`, `Add timed Agent2Agent…`; the remaining ~42 → Run):

| Bucket | Mechanical | Adjusted |
|---|---|---|
| Run | 76.7% | **~84.4%** |
| Grow | 14.4% | **~15.6%** |
| Transform | 0% (undeclared) | **0% (undeclared)** |

**The adjusted read flatters nobody** — as in run 1 it moves the mix *further* toward maintenance.
Both are reported; the mechanical figure is the measurement, the adjusted one is the honest
interpretation.

### Verdict

Roughly **five sixths of chosen work is maintenance**, and 346 of 886 commits (39%) are the harness
running itself. Compared with run 1 (Run ~83% adjusted), the mix has **not moved** — it has drifted
one point *further* toward Run over four days.

---

## Lens 2 — recurring-defect radar

### Signal yields

| Signal | State | Yield |
|---|---|---|
| **S1 `related:` frontmatter** | **available** | **58 docs carry `related:`, 68 references extracted** — no parser failure. Both shapes parsed: the `#N` block form and the filename-scalar form resolved via the target doc's `gh_issue:` key (**1 edge resolved this way**: `PROJECT/2-WORKING/GH-351-MANIFEST-UNSHIP.md → #349` via `GH-349-RELEASES-ROADMAP-VENDORED.md`). Top-cited: #174 (7), #177 (6), #224 (5), #113 (4). As in run 1, **citation count conflates kinship with infrastructure context** — #174/#177/#224 are ATE/Gen-3.5 umbrella references, not defect kinship, and form no cluster. |
| **S2 shared seam** | **available** | **154 `fix:`/`hotfix:` commits** in the window. Generated artifacts excluded from seam ranking (`releases.db`, `releases.sql`, `*.html`, `CHANGELOG.md`, `ROADMAP*.md`, `PROJECT/**`) — they change on every release commit and are co-change noise. `validate.sh` (36 issues / 31 commits / 11 days) **excluded again as a false seam**: it is the suite registry, so nearly every fix touches it to register a test. **Concentrated authoring excluded from targets**: `skills/standup/` (327 commits, **1 day**, 1 issue), `test/gh353-vendored-router-audit.sh` + `utils/py/router_audit.py` (13 commits each, 1 day, 1 issue), `test/gh77-standup-triage.sh` (10 commits, 1 day). These are components being *written*, not defects recurring. |
| **S3 issue similarity** | **available** | 234 issues (**104 open / 130 closed**). Residue after discarding planned parallel waves: the vendored-path family (below) and the telemetry family (below), both promoted to targets on stronger evidence than title similarity. |
| **S4 false closes** | **available; literal form genuinely near-empty** | 130 closed issues exist, so the signal is structurally available. Literal doc-only-close grep returns 4 repo-wide hits, **all policy or report text** (`PROJECT/PDDA.md`, `PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md`, this report's predecessor, `GH-346-PHASE-3-SPEC.md`) — **a real negative result, not an absent signal**. The stronger variant fired again: `fix(GH-255,GH-256): codex QA — the fix was in a file that never runs` (2026-08-26) is a second documented instance of the T7 mechanism. |
| **S5 `reported_from:`** | **available** | **10 capture docs** (was 7), **4 distinct external consumer repos**: `LTVera-Pandas` ×4 (#215, #216, #222, +1), `aegis-sleuth-slack-bot` ×3 (#221, #254, +1), `rebalanceOS` ×2 (#255, #256), `ltvera` ×1. **Grew by 3 docs and 1 repo in 4 days.** |
| **S6 operational evidence** | **structurally unavailable this run** | **0 logs.** `relay-system/logs/*.log` does not glob; `run-logs/` does not exist; `temp/logs/` absent. The prior run read 83. **This is corpus drift — the instrument was removed, not the failures.** No "is this firing right now" claim can be made this run, in either direction. |

### Doc-corpus size per bucket — drift check against run 1

| Bucket | Run 1 (2026-08-28) | Run 2 (2026-09-01) | Δ |
|---|---|---|---|
| `PROJECT/1-INBOX` | 22 | **26** | +4 |
| `PROJECT/2-WORKING` | 19 | **32** | **+13** |
| `PROJECT/3-COMPLETED` | 55 | **64** | +9 |
| `PROJECT/4-MISC` | 0 | **0** | 0 |
| **Total `.md`** | 104 | **120** | +16 |
| **`GH-*.md`** | 88 | **106** | +18 |

No lifecycle sweep occurred — every bucket grew and none shrank, so this is **genuine intake, not
relocation**. S1's citation counts (45→58 carriers, 104→68 references) may therefore be compared
directly. The reference count *fell* while carriers rose because this run counts only frontmatter
`related:` blocks; run 1's 104 included prose-body references. **Treat the two reference counts as
measured differently, not as a decline in kinship.**

Note `2-WORKING` grew 68% in four days (19 → 32). Work is being opened faster than it is completed.

---

### Ranked targets

Scores are **ordinal only** — effort ratings in `releases.db` remain partly provisional
(`ratings_provisional: true` on `PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md`).

#### T1 · `RADAR-class-vendored-root-resolution` — score ≈ 7.7 (9 × 4 ÷ 7.0 × 1.5) · **↑ from run 1's #2**

Scripts and generators resolve the repo root against the bare layout and break under a vendored
`.xyz/` install. **This target got worse, not better.**

Run 1 members: #215, #216, #222, #254, #255, #256, #221 (7 issues, 3 repos).
Run 2 members: those **plus #349, #358** (9 issues, **4 repos**).

The run-1 checklist item read: *"Close #215/#216/#222/#255/#256/#221/#254 against the shared
helper — acceptance: no consumer repo files an eighth."* **An eighth and a ninth were filed:**

- **#349** (2026-08-31, closed via PR #350) — `releases ledger: roadmap layer never generalised to a vendored install`
- **#358** (2026-09-01, closed via PR #359) — `wave_reconcile.py resolves all five harness tools repo-root-relative`

Both were fixed **individually**. The shared root-resolution helper was never added. #358 is the
same defect as #215, in the same file (`wave_reconcile.py`), re-reported and re-fixed **eight days
later** — the clearest recurrence in the repo.

Still open: **#215, #216, #253, #254, #255, #256, #353**. Also in-family: #360.

Span: 2026-08-24 → 2026-09-01 (**9 days**), 4 consumer repos, ≥6 distinct PRs. Recurrence
discriminator: **passes** on both axes.

**Claim status: CLAIMED by release 0.9.0 `Cargo` (status `active`)** — whose blurb is literally
*"the harness travels with its ledger… ship inside every vendored `.xyz/` payload"* and whose exit
criterion is *"A repo vendored with `xyz-vendor.sh` can, with zero extra downloads, run
`releases init/add` and `export_timeline.py --preview` from `.xyz/` against its own root."*
This is a **change from run 1**, where the target was unclaimed. The band exists; what is missing
is the durable fix inside it.

A single durable fix — one shared root resolver, plus a vendored-`.xyz/` CI fixture — would retire
nine issues across four repos and stop the tenth being filed.

#### T2 · `RADAR-class-dark-telemetry` — score ≈ 9.0 (8 × 3 ÷ 4.0 × 1.5) · **NEW this run**

*Kin to [T3] `RADAR-class-guard-blind-matcher`; recorded separately because the seam and the fix differ.*

Instruments that report a state they never measured: the writer silently no-ops, writes to the
wrong place, or a reader turns a write failure into a wrong verdict.

Members (8, all cited):

| Issue | Date | State | Evidence |
|---|---|---|---|
| **#346** | 2026-08-31 | OPEN | `fix(GH-346): three gateways wrote NO telemetry at all — QA round 1 fixes` (`e3031586`) — and a companion commit titled `telemetry honesty` (`86fa1906`) |
| #327 | 2026-08-30 | CLOSED | telemetry sidecar writes **into the coordinated repository** (`cd698e79`) |
| #329 | 2026-08-30 | CLOSED | uncaught sqlite error makes a **committed turn read as a failure** (`2999e294`) |
| #330 | 2026-08-30 | CLOSED | `SKILL.md` documents a STALE-LOCK reclaim **the code deliberately does not do** (`495e737f`) |
| #208 | 2026-08-24 | OPEN | `gh382` asserts the low-swap warning on every platform, **but the sampler is darwin-only** |
| #184 | 2026-08-23 | CLOSED | committed scratch artifact `.relay-scratch/probe_telemetry.json` **makes every real run look dirty** |
| #180 | 2026-08-23 | CLOSED | `repro_builder` crashes on timeout telemetry records (`exit_code: null` → TypeError) |
| #370 | 2026-09-01 | OPEN | **Mid-turn blindness**: no worktree-progress telemetry in the RSS poll loop |

Span: 2026-08-23 → 2026-09-01 (**10 days**), ≥5 distinct PRs (#331–#335, #346 lane). Recurrence
discriminator: **passes**.

The 1.5× multiplier is earned by **#330** — a resolution that reconciled documentation to code
rather than fixing behaviour — and by **#346**, where three gateways wrote nothing at all and the
system reported success throughout.

**And S6's disappearance is this target's own symptom.** The 83-log corpus that run 1 read is gone.
A repo whose recurring defect class is *"the instrument is dark"* just lost its instrument corpus.
That is not a coincidence worth ignoring, and it is why #370 matters more than its age suggests.

**Claim status: UNCLAIMED.** No unshipped release band names telemetry integrity. `0.5.0 Lantern`
(*"When the harness fails, the information needed to act already exists inside it — make it say
so"*) is the natural home — but it is `draft`, its exit criterion is marked **NOT BUILT**, and it
sits behind 0.9.0 and 0.6.0.

#### T3 · `RADAR-class-guard-blind-matcher` — score ≈ 6.4 (was 15.0) · **partially retired, citable**

Guards whose matcher is hand-written instead of derived from the authoritative source, so they stay
green while a new shape walks past. Members: #52, #137, #195, #273, #256, #221, GH-77.

**Two checklist items retired against named commits — struck, not assumed:**

1. ✅ *Register `test/gh280-jog-marathon-adapter.sh` in `validate.sh`'s `TESTS` array* —
   **verified present**: `sed -n '/^TESTS=(/,/^)/p' validate.sh` names
   `"gh280-jog-marathon-adapter.sh"`.
2. ✅ *Make `test/gh35-test-tiers.sh` bidirectional* — **PR #308 merged 2026-08-29**,
   `chore(hygiene): bidirectional registry guard + ATE negative control`. `validate.sh`'s own
   comment now reads *"pins the registry contract (every registered suite exists AND is in
   TESTS)"*.
4. ✅ *Close #195 / #273* — both **CLOSED** (#195 on 2026-08-24, #273 on 2026-08-28).

**One item remains open**: generalize the derive-from-source pattern into a reusable helper.
Partial progress is citable — `5b6a734b feat(GH-346): wire the generated-registry view into the
gate` — but no shared helper exists.

Score falls because three quarters of the cluster's checklist retired with named commits. **The
class itself is not retired** — see T2, which is the same failure mode one layer down.

#### T4 · `RADAR-class-roadmap-ledger-drift` — score ≈ 4.3 (unchanged)

`ROADMAP.md` is a ledger with a regex for a schema (#69). Run-1 members: #163, #168, #202, #232,
#228, #250, #253, #257, #272, #69. **New in-family this run: #351 (closed, `manifest unship` —
the retraction verb the ledger never had), #360 (open, `releases check` calls a git-induced chain
fork a "forged audit trail"), #362 (closed, marathon-plan parses only bold ledger bullets).**

Still open: **#69, #253, #269, #360**.

**Claimed** — GH-269 (releases.db as sole roadmap truth) remains the durable fix and remains
**open and unlanded**, unchanged across both runs.

The DB itself is healthy: `releases check` reports **clean, 0 failures, 8 warnings**; generation
trio consistent at **350**; receipt chain intact (**391 receipts**, 37 merge forks tolerated).
The 8 warnings are all `mig-ref-stale` — eight migrations **14 days old against a 7-day
threshold** — plus 24 `grandfather_entries` pending disposition, both of which block the strict
flip.

#### T5 · `RADAR-marathon_drive.py` — score ≈ 4.5 (was 3.5) · **↑**

Central marathon dispatcher. This window: **18 distinct issues / 10 fix commits / 6 distinct days**
on `utils/py/marathon_drive.py` alone. Recurrence discriminator: **passes**.

Its fix history is the repo's other classes converging on one file:

```
2026-08-31 fix(GH-346): three gateways wrote NO telemetry at all          → T2
2026-08-26 fix(GH-255,GH-256): codex QA — the fix was in a file that never runs → T7
2026-08-26 fix(GH-255): order the blocked-before-dispatch remedies by what is actually blocked
2026-08-24 fix(harness): GH-217 — scrub MARATHON_ALLOW_PLAN_OUTSIDE_WORKING at the gate boundary
2026-08-23 fix(marathon-drive): let a productive relay extend past a stalled round cap (#115) → T6
```

#290 and #291 both remain **open**; neither run-1 checklist item was actioned.

#### T6 · `RADAR-class-headless-turn-timeout` — score ≈ 2.0 · **evidence got worse**

Turn caps that kill productive work or fail to kill dead work: #114 (closed), **#237, #276, #285
all still open**. No commit in the delta names any of them.

Run 1 rated the evidence thin (`exit 7` in 2 of 83 logs). **This run cannot rate it at all** — the
log corpus is gone (S6). The single checklist item — *instrument turn termination so idle-kill,
wall-cap and child-orphan are distinguishable* — is now the **precondition for measuring this
target at all**, not merely a refinement.

**Claim status: UNCLAIMED.**

#### T7 · `RADAR-class-frozen-twin-dead-fix` — formula score ≈ 1.2, **held at top-3 on mechanism**

An edit to any FROZEN Bash twin under `relay-automation/` reports success and changes nothing.
**10 twins remain frozen** (run 1 counted 11–12 — one retired).

**Second documented instance found this run**: `fix(GH-255,GH-256): codex QA — the fix was in a
file that never runs` (2026-08-26), alongside run 1's `fa372590` catching `74bb8d1c`. Two
independent occurrences, eight days apart, from different issues — the discriminator now
**passes**, where run 1 had to promote it on mechanism alone.

Checklist item — *widen `test/gh308-frozen-twin-guard.sh` beyond its merge-base range scope* —
**not actioned**. The guard exists (34.1K, registered in `TESTS`) but no commit in the delta widens
its base scope.

**Claim status: CLAIMED by release 0.8.0 `Sundown`** (*"Retire the twelve frozen Bash twins"*) —
but Sundown is `draft` and its exit criterion reads verbatim **"Exit: NOT WRITTEN."**

#### T8 · `RADAR-agy-auth-preflight` — **quiet, unexplained**

Agy auth probe verb (#130 → #135 → #221 → #245). #245 closed 2026-08-26; **#227 remains open** and
is the run-1 loose end.

**No commit or PR in the 4-day delta names #227 or the agy `whoami` seam.** Per the
symptom-masking rule, this target is **not struck**. Annotated:
**`quiet, unexplained — the #245 cross-call-site invariant may be masking #227 rather than covering it.`**
Verifying that the invariant actually covers #227 is one command's work and settles it either way.

---

### Clusters examined and dropped

| Candidate | Why dropped |
|---|---|
| `validate.sh` (36 issues / 31 commits / 11 days) | **False seam.** It is the suite registry; nearly every fix touches it to register a test. Same exclusion as run 1. |
| `skills/standup/` (327 commits, 1 day) | **Concentrated authoring.** One day, one issue — a skill being written. |
| `test/gh353-vendored-router-audit.sh` + `utils/py/router_audit.py` (13 commits each, 1 day) | **Concentrated authoring** — 15 Codex QA rounds on GH-353 in a single day. Counted as T1 *membership*, not as an independent seam. |
| `test/gh77-standup-triage.sh`, `test/gh257-roadmap-ledger-fixes.sh` | Concentrated authoring, 1 day each. |
| #174 / #177 / #224 citation hubs | **Infrastructure context, not kinship** — ATE/Gen-3.5 umbrella references. Same finding as run 1. |
| `LEADERBOARD.md`, `RELEASES-PREVIEW.html`, `releases.db/.sql`, `CHANGELOG.md`, `ROADMAP-DASHBOARD.md` | **Generated artifacts.** Regenerated on every release commit; co-change noise. |

---

## Step 2b — open-PR collision check

Three open PRs on GitHub. **All three are `CONFLICTING` / `DIRTY`.**

| PR | Target overlap | Match evidence | State | Recommendation |
|---|---|---|---|---|
| **#356** `feat(vendor): audit and prompt for target ROUTER.md ROADMAP.md frozen status (GH-353)` | **T1** vendored-root-resolution | GH-353 is a named T1 member; PR head `feat/gh353-vendored-router-roadmap-audit` | open + CONFLICTING **but already merged locally at `bb0d5d6a`** | **Push the local merge and close the PR.** Until then GitHub shows a conflicting PR for work that is done. Do **not** schedule a duplicate. |
| **#364** `fix(releases): scoped check --rebuild and accurate receipt-chain phrasing (GH-360)` | **T4** roadmap-ledger-drift | GH-360 is a named T4 in-family issue | open + CONFLICTING **but already merged locally at `2a41968d`** | **Push the local merge and close the PR.** Same duplicate-work risk. |
| **#378** `GH-365: test-suite recalibration — shared envelope, retained telemetry, contention…` | **T2** dark-telemetry (partial), **T3** guard-blind-matcher (partial) | Title names *retained telemetry*; #377 (`Finish #365: baseline + real-push tier latency receipts`) is open behind it | open, ready, **CONFLICTING/DIRTY**, updated 2026-09-02 | **Collision risk, not progress.** Do not treat T2 as covered. Rebase it onto a pushed `development` and re-check; #377 says it is not finished. |

**No open PR claims T5, T6, T7, or T8.** Those four are available to schedule.

---

## Lens 3 — release recalibration

Read from `releases check` and `python3 utils/timeline/export_timeline.py --json`.
DB generation trio consistent at **350**; receipt chain intact (391 receipts).
`releases roadmap sync --dry-run` correctly reports **releases-mode** (the DB is canonical).

### The milestone join is impossible for every unshipped row

| Release | Status | `milestoneRef` | Exists on GitHub? |
|---|---|---|---|
| 0.9.0 | **active** | `Cargo` | ✗ |
| 0.6.0 | draft | `Front-Door` | ✗ |
| 0.8.0 | draft | `Sundown` | ✗ |
| 0.4.0 | draft | `Plumbline` | ✗ |
| 0.5.0 | draft | `milestones` | ✗ |

GitHub has two milestones — `Bulkhead` (0 open / 8 closed) and `Ballast` (0 open / 5 closed) —
**both fully closed**. Claim status above was read from each release's `blurb`/`exit` prose, and
this report says so rather than implying a join happened.

### Orphan share: 104 of 104 open issues (100%) carry no milestone

**This measures a missing binding, not backlog drift** — identical in kind to run 1 (81 of 81) and
worse in absolute terms. With no live milestone for any unshipped release, 100% orphan is
arithmetically forced. The actionable finding is *create the milestones and bind them*, so the next
run can join. Until then, no run of Radar can answer "has this milestone's issue set drifted from
its theme."

### Does the active arc's description still describe where effort goes?

**Yes — better than at run 1, and that is the good news in this report.**

0.9.0 `Cargo`'s blurb is about shipping the RELEASES DB and timeline generator inside every
vendored `.xyz/` payload. The window's largest non-harness effort — GH-353 (15 QA rounds), GH-349,
GH-358, GH-350, GH-359 — is exactly that work. The plan and the repo agree.

**The gap is the shape of the work, not its subject.** The arc is being delivered as a sequence of
individually-fixed vendored-path defects rather than the one shared resolver that would stop the
next one. Nine issues, four consumer repos, and no helper.

### Claimed vs. unclaimed targets

| Target | Claim |
|---|---|
| T1 vendored-root-resolution | **CLAIMED** — 0.9.0 `Cargo`, active |
| T2 dark-telemetry | **UNCLAIMED** — nearest band 0.5.0 `Lantern`, draft, exit **NOT BUILT** |
| T3 guard-blind-matcher | partially retired; residue unclaimed |
| T4 roadmap-ledger-drift | **CLAIMED** — GH-269, open |
| T5 marathon_drive.py | **UNCLAIMED** |
| T6 headless-turn-timeout | **UNCLAIMED** |
| T7 frozen-twin-dead-fix | **CLAIMED** — 0.8.0 `Sundown`, draft, exit **NOT WRITTEN** |
| T8 agy-auth-preflight | **UNCLAIMED**, quiet-unexplained |

**Four of eight targets are unclaimed, and the second-highest-scoring target (T2) is one of them.**
Two more are claimed by draft releases whose exit criteria are explicitly unwritten — a claim that
cannot yet be executed against.

Advisory only. The plan says *vendor the ledger*; the repo is doing that, and also carrying four
unowned recurring defect classes it has not scheduled.

---

## Checklist as at generation time

*(historical snapshot — the live copy is issue #293)*

### RADAR-class-vendored-root-resolution — 9 issues / 4 repos over 9 days · first-seen: 2026-08-28 · runs: 2

- [ ] Add one shared root-resolution helper correct at both `repo_root/utils/…` and `repo_root/.xyz/utils/…` — acceptance: the idiom `ROOT="$(cd "$HERE/.." && pwd)"` appears in no shipped script
- [ ] Add a vendored-`.xyz/` fixture to the suite — acceptance: a script assuming the bare layout fails in CI, not in a consumer repo
- [ ] Close #215 / #216 / #253 / #254 / #255 / #256 against the shared helper — acceptance: no consumer repo files a tenth (an eighth and ninth, #349 and #358, were filed since run 1)

### RADAR-class-dark-telemetry — 8 issues over 10 days · first-seen: 2026-09-01 · runs: 1 · NEW

- [ ] Add a write-verification assertion to every telemetry writer — acceptance: a gateway that writes zero rows fails its own turn instead of reporting success (replays GH-346's "three gateways wrote NO telemetry at all")
- [ ] Restore or replace the run-log corpus under a committed, gitignore-audited path — acceptance: a later Radar run can answer "how many of the last N runs show X" at N ≥ 20
- [ ] Land #370 (worktree-progress telemetry in the RSS poll loop) — acceptance: mid-turn progress is observable without attaching to the process
- [ ] Make `gh382`'s low-swap assertion platform-aware (#208) — acceptance: the assertion is skipped, not silently dark, on non-darwin

### RADAR-class-guard-blind-matcher — 7 issues over 10 days · first-seen: 2026-08-28 · runs: 2

- ~~Register `test/gh280-jog-marathon-adapter.sh` in `validate.sh`'s `TESTS` array~~ — **done**, verified present in `TESTS`
- ~~Make `test/gh35-test-tiers.sh` bidirectional~~ — **done**, PR #308 merged 2026-08-29
- [ ] Generalize the derive-from-source pattern into a reusable helper — acceptance: at least `test/marathon-root-audit.sh` and the agy preflight guard derive their expected set rather than hardcoding it (partial: `5b6a734b`)
- ~~Close #195 / #273~~ — **done**, both closed

### RADAR-class-roadmap-ledger-drift — 13 issues over 10 days · first-seen: 2026-08-28 · runs: 2

- [ ] Land GH-269 (releases.db as sole roadmap truth) — acceptance: `ROADMAP.md` is generated, never hand-edited, and #69's regex-as-schema is retired. **Unchanged across two runs.**
- [ ] Disposition the 8 stale migration refs (14 days vs. a 7-day threshold) and the 24 pending `grandfather_entries` — acceptance: `releases check` reports 0 warnings and the strict flip is unblocked

### RADAR-marathon_drive.py — 18 issues over 6 days · first-seen: 2026-08-28 · runs: 2

- [ ] Confirm #291 enumerates all six merged #281 blockers — acceptance: each has a named acceptance condition or its own issue
- [ ] Decide `--auto-merge` policy at head — acceptance: either a refusal guard lands, or the cross-repo case is verified safe with a test

### RADAR-class-headless-turn-timeout — 4 issues over 3 days · first-seen: 2026-08-28 · runs: 2 · evidence now unmeasurable

- [ ] Instrument turn termination so idle-kill, wall-cap, and child-orphan are distinguishable in the run log — acceptance: a later radar run can answer "how many of the last N runs" at useful N. **Now a precondition for measuring this target at all — the 83-log corpus run 1 read no longer exists.**

### RADAR-class-frozen-twin-dead-fix — 2 documented instances over 8 days · first-seen: 2026-08-28 · runs: 2 · discriminator now passes

- [ ] Widen `test/gh308-frozen-twin-guard.sh` beyond its merge-base range scope — acceptance: an edit to any of the 10 FROZEN twins fails the guard regardless of base, replaying `74bb8d1c` as a red
- [ ] Write 0.8.0 `Sundown`'s exit criterion — acceptance: the release block no longer reads "Exit: NOT WRITTEN", per the Litmus/Nightwatch gate-first ordering the repo already uses

### RADAR-agy-auth-preflight — 4 issues over 4 days · first-seen: 2026-08-28 · runs: 2 · quiet, unexplained

- [ ] Verify the #245 cross-call-site invariant covers #227, then close or reopen it — acceptance: #227 closed citing the invariant, or reopened as a genuine fourth recurrence. **Not struck: no commit in the delta names the seam; possible symptom masking by the #245 invariant.**

### Measurement hygiene — carried from run 1, unactioned

- [ ] Adopt `rgt:` on the governing docs (GH-105 / GH-269 for ledger + dashboard, GH-280 for Jog) — acceptance: the next Radar run reports a non-zero Transform share on a declared basis. **Two runs old.**
- [ ] Register `evidence:` and `release(scope):` as recognised commit types in the commit SOP, or map them to `docs:`/`chore:` — acceptance: the Unclassified share falls below 5% without any parser change. **20 of 48 unclassified commits are these two well-formed families.**
- [ ] Create GitHub milestones matching the DB's `milestoneRef` values (`Cargo`, `Front-Door`, `Sundown`, `Plumbline`, `Lantern`) and bind open issues — acceptance: the next Radar run can perform the milestone join and report a meaningful orphan share.

---

## Reconciliation notes for the next run

1. **Doc-corpus grew without a lifecycle sweep** (104 → 120 `.md`, 88 → 106 `GH-*.md`). Citation
   deltas in run 3 may be attributed to defect activity — but re-check for a sweep first.
2. **S1 reference counts are measured differently between runs 1 and 2** (104 prose-inclusive vs.
   68 frontmatter-only). Do not read the fall as declining kinship.
3. **S6's corpus disappeared between runs.** If it returns, T6 and T2 both become measurable again;
   note the log count in run 3 so the drift is visible in both directions.
4. **Never strike a target on symptom disappearance alone.** T3 and T7 are causally linked, as are
   T2 and T3. T8 is currently annotated *quiet, unexplained* for exactly this reason.
5. **`gh` lies inside the sandbox.** Re-run `gh auth status` unsandboxed before concluding the
   tooling is unavailable.
