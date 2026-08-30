---
title: "Radar report 2026-08-28 — flow distribution, recurring targets, release recalibration"
status: active
created: 2026-08-28
updated: 2026-08-28
owner: orchestrator (Claude Code)
goal: record one windowed, cited read of where effort actually went, which defects recur, and where the plan has drifted — so the next run can reconcile against it
doc_type: report
---

# Radar — 2026-08-28

Window: **2026-08-07 → 2026-08-28** (21 days). Trunk: `origin/development`.
Tracking issue for the skill itself: GH-442.

## Degradation applied this run

| Row | Cost to the verdict |
|---|---|
| **History < ~2 windows** | Repo history is **2026-08-15 → 2026-08-28** (13 days, 822 commits). The prior 21-day window holds **0 commits**, so **there is no trend line**. Every recurrence span below is measured in days, and nothing can demonstrate recurrence across releases or months. |
| **Upstream issue numbers** | `related:` targets #308, #362, #375, #401, #418, #514, #544, #555, #559, #563, #564, #567 resolve to no issue in this tracker — they are upstream `xyz-3-agents-swarm` numbers. Recurrence crossing that boundary is invisible to `gh issue list` here, which structurally under-ranks T7. |
| **Effort ratings partly provisional** | `releases.db.roadmap_items.rating_effort` covers 79/80 rows, but #255 and #256 carry placeholder `1` and `PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md` sets `ratings_provisional: true`. **Treat all scores as ordinal only.** |

`gh`, `PROJECT/**`, and the releases ledger were all available. `RELEASES.md` is present but superseded — see Lens 3.

---

## Lens 1 — flow distribution

**Tally proven before bucketing.** Subjects written to file with `/usr/bin/git log --no-merges --pretty='%s'`; `wc -l` = **726**, cross-checked against `git rev-list --no-merges --count` = **726**. Bucket counts sum to 726. This check is not ceremonial: a shell wrapper in this environment truncates plain `git log` to 50 entries, which would have produced a confidently wrong distribution with no visible symptom.

### Mechanical read

| Bucket | Count | Share of RGT denominator |
|---|---|---|
| **Harness** (`relay*` `marathon*` `plan:` `capture:` `triage:` `wip:`) | 298 | *excluded from denominator* |
| **Run** (`fix` `chore` `docs` `refactor` `test` `ci` `hotfix` `cleanup`) | 317 | **74%** |
| **Grow** (`feat`) | 66 | **15%** |
| **Transform** (explicit `rgt: transform` only) | 0 | **0% (`rgt:` adoption: 0 of 104 PROJECT docs)** |
| **Unclassified** | 45 | **10%** |

RGT denominator = 428 (Run + Grow + Transform + Unclassified).

**Read the Transform figure precisely.** Zero docs carry an `rgt:` key, so `0%` means *nobody has declared anything* — not *no transformative work happened*. The number cannot become non-zero until the key is adopted. See "Operator dissent" below, and the tagging-gap issue filed alongside this report.

### Unclassified subjects, verbatim (45)

```
reconcile: promote GH-271, GH-272, GH-273, and GH-280 recon docs to 3-COMPLETED (PR #274)
reconcile: promote GH-280 doc to 3-COMPLETED and refresh views (PR #281)
evidence: the gate is green — F-025 closed, measurement hygiene recorded
release(0.7.4): dial in Linux-RC ahead of Cargo — #204, #205, #123 marathon lanes
release(0.7.3): SHIP Bulkhead (evidence receipted, #179 closed) + capture GH-223 gate-push double-apply into C
release(0.7.3): ship-with-evidence for all 13 completed Bulkhead members; regen views; kanban sync
queue(gh222): dial #222 (tracking-issue re-point) into 0.7.3 Bulkhead — intake doc, ROADMAP park, ledger sync
evidence: confirm the gate number on a clean tree, and say why it moved
evidence: PR body for round 2, with the gate status disclosed up front
evidence: correct two wrong attributions; F-031/F-032 and the false greens
evidence: diagnose all 9 gate failures — 4 are repo bugs, not host quirks
evidence: round 2 — MSYS2 follow-up for PR #29, sed bug promoted to the ledger
release(bulkhead): extend 0.7.3 with the Gen 3.5 soak cohort #180-#184 (#179)
release(0.7.3): cut Bulkhead — 7-member harness-reliability manifest, capture docs, preflighted marathon plan
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
Ballast 0.7.0: open the release block — exit criterion written first (NOT BUILT, red on arrival), manifest frozen
GH-5 PR#7 split: land the unit-test half, drop the reader quarantine (-> #14)
GH-1 PR#6 review fixes: un-mangle TESTS comments; init check above both case blocks, pinned; mutation control
launch: forward-port the artifact build's audit + build scripts onto main (Part 0 reconciliation)
GH-5: readAllEvents quarantines corrupt event files; add node:test unit runner for src/
GH-1: shared resolved-containment require_fixture + suite-wide clone-identity invariant gate
XYZ: initial public release
```

### Source-fixable measurement defect

**35 of the 45 unclassified commits fall into two known malformed-prefix families.** Both are correctly-typed work that a strict conventional-commit parser silently discards. The convention is what should change — compensating for this in the parser forever is the wrong fix.

- **Component-as-type** (~25): `evidence:` ×8, `release(x):` ×10, `reconcile:` ×2, `queue(x):` ×1, plus `skills:`, `repro.sh:`, `audit(tooling)`, `ship(GH-32)`, `launch:`.
- **Missing colon / bare issue-ID as type** (~10): `Ballast 0.7.0:`, `Ballast preflight round 1:`, `Ballast capture docs:`, `Ballast:`, `GH-23:`, `GH-15:`, `GH-5:`, `GH-5 PR#7 split:`, `GH-1:`, `GH-1 PR#6 review fixes:`.

### Adjusted read

Reclassifying the 45 by reading their subjects (3 → Harness, ~6 → Grow, ~36 → Run):

| Bucket | Adjusted share |
|---|---|
| Run | **~83%** |
| Grow | **~17%** |
| Transform | **0% (undeclared)** |

**The adjusted read flatters nobody** — it moves the mix *further* toward maintenance than the mechanical read did. Both are reported; the mechanical one is the measurement, the adjusted one is the honest interpretation.

### Operator dissent — recorded, not silently adopted

The operator states that the **RELEASES DB system + dashboard** and the **initial Jog system** are transformative work delivered in this window. Radar's guardrail is that **Transform is declared, never inferred** — no commit prefix and no operator statement retroactively promotes work in the measurement, because auto-promotion is exactly what inflates the one number this exercise exists to keep honest.

So the figure above stands as measured, **and** the operator's assertion is recorded here as the primary evidence that the measurement instrument is missing a signal rather than the work being absent. The remedy is forward-looking: adopt `rgt:` on the governing docs (`GH-105`/`GH-269` for the ledger and dashboard, `GH-280` for Jog) and the next run reports a non-zero Transform share on a declared basis. Filed as a separate issue alongside this report.

---

## Lens 2 — recurring-defect radar

### Signal yields

| Signal | State | Yield |
|---|---|---|
| **S1 `related:` frontmatter** | **available** | 88 `GH-*.md` docs, **45 carry `related:`, 104 references extracted** — no parser failure. Filename-scalar shape (b) is **structurally unavailable** here: the resolver was built and matched 0 edges; the only scalar forms are prose tag lists (`PROJECT/2-WORKING/GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md`, `PROJECT/3-COMPLETED/GH-1-SUITE-CONTAINMENT-GATE.md`). 8 references unresolvable. **Kinship vs. infrastructure split, after reading every citing string: 26 kinship (25%) / 78 infrastructure (75%).** Citation count alone would have produced four fake clusters around #174/#177/#224. |
| **S2 shared seam** | **available** | 104 deduped `fix:`/`GH-` commits. `validate.sh` (20 issues / 9 days) **excluded as a false seam** — 10 of 12 sampled commits are `1 0 validate.sh`, one-line suite *registrations*, not fixes (`86f6d07c`, `de31c66b`, `9a313564`). `test/agent2agent.sh` (3 issues, 1 day) and `test/gh35-test-tiers.sh` (2 issues, 1 day) excluded as **concentrated authoring**. |
| **S3 issue similarity** | **available** | 193 issues (81 open / 112 closed); 40 pairs ≥0.34 Jaccard. 29 of 40 are the GH-77 Daybreak wave series (#79–#87) — planned parallel work, discarded. Residue: `#227↔#221` (0.43), `#135↔#130` (0.43), both on the agy auth preflight verb. |
| **S4 false closes** | **available; literal form genuinely near-empty** | Only 2 repo-wide hits, both policy text (`PROJECT/PDDA.md:244`, `PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md:135`) — neither a real doc-only close. **The stronger variant fired hard:** `fa372590` (2026-08-26) records "GH-256 WAS DEAD CODE. The fix went into `relay-automation/marathon-drive.sh`, whose own line 2 reads 'FROZEN (GH-308): Python is authoritative'… Normal runs never reached it. It shipped in `74bb8d1c` and only the QA caught it." A no-effective-code-change resolution earns the 1.5× multiplier the same way a doc-only close does. |
| **S5 `reported_from:`** | **available** | 7 capture docs, **3 distinct external consumer repos**: `LTVera-Pandas` (#215, #216, #222), `rebalanceOS` (#255, #256), `aegis-sleuth-slack-bot` (#221, #254). All in `PROJECT/1-INBOX/`; 6 still open. |
| **S6 operational evidence** | **available but evidentially thin** | 83 logs under `relay-system/logs/` + `run-logs/`. **A false positive is recorded here deliberately:** `"degraded"` appears in 33 of 83 logs, but reading the hits shows they are echoed *source lines* of `skills/standup/collect.sh` inside agent turn transcripts (`lens3_status="degraded"`), **not runtime degradation events** — the 33/83 figure is meaningless and is not counted. Only 5 marathon run-logs exist across 2 days, so "how many of the last N runs" is unanswerable at useful N. `exit 7` in 2 logs; wall/timeout cap in 2; idle-kill in 0. |

### Doc-corpus size per bucket (record for the next run's drift check)

`PROJECT/1-INBOX` 22 · `PROJECT/2-WORKING` 19 · `PROJECT/3-COMPLETED` 55 · `PROJECT/4-MISC` 0 · **total 104 (`.md`), 88 matching `GH-*.md`**.

A lifecycle sweep that relocates docs between these buckets changes S1 citation counts with no defect having changed. Compare these figures before attributing any citation delta in a later run.

---

### Ranked targets

#### T1 · `RADAR-class-guard-blind-matcher` — score ≈ 15.0 (7 issues × 5 lanes ÷ 3.5 × 1.5)

**Class-shaped.** Guards whose matcher is a hand-written pattern or enumeration instead of being derived from the authoritative source — so they stay green while a new shape walks past.

| Member | Where | Evidence |
|---|---|---|
| #52 (closed) | `releases check` | "nothing runs `releases check` on the repo's real artifacts" |
| #137 (closed) | `validate.sh` registry | "synthetic suites gh129/gh130/gh131 are unregistered — nothing runs them" |
| #195 (closed) | `test/marathon-root-audit.sh` | `PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md:48` — "reopened via a shape the original fix" missed |
| #273 (closed) | same file | title reads "(GH-195 class)" — the #195 close did not hold |
| #256 (open) | `utils/py/marathon_drive.py` | no preflight checks artifact reachability; phase burns full round cap |
| #221 / #375 | agy preflight | "whoami falsely exits 0 on a TTY error — a false PASS" (`PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md`) |
| GH-77 | `skills/standup/collect.sh` | `test/gh77-standup-triage.sh:382` — "only the jq preflight honoured it, so a caller checking `$?` was told" success |

Span **2026-08-16 → 2026-08-26** (~10 days = 77% of all repo history), ≥6 originating PRs, **5 unrelated files** — class-shaped, not a seam.

**Why it recurs:** each guard hardcodes its own copy of a set that lives somewhere else.

**New instance, same day as this report:** PR **#281** merged an 893-line suite, `test/gh280-jog-marathon-adapter.sh` (139 assertions), that is **absent from `validate.sh`'s `TESTS` array** — and `.github/workflows/ci.yml:460` re-derives its own suite list by parsing that same array. The suite runs in no gate. The existing registry guard `test/gh35-test-tiers.sh` pins that every *registered* suite exists, but not that every suite *file* is registered — one-directional by construction, which is precisely this class. This is a textual repeat of #137.

**What one durable fix retires:** `fa372590` already proved the pattern on one instance — "the test DERIVES the expected set from `route_agent` rather than hardcoding it — adding a route without a guard root now fails here instead of in a 29-minute marathon." Generalizing derive-from-source, plus a meta-test that fails when an authoritative set gains a member its guard lacks, **retires all 7 and closes the #195 → #273 reopen loop.**

#### T2 · `RADAR-class-vendored-root-resolution` — score ≈ 6.0 (7 × 4 ÷ 7.0 × 1.5)

**Class-shaped, cross-repo.** Scripts resolve the repo root one level too shallow, or hardcode `utils/…` argv, and break under a vendored `.xyz/` install.

Members: **#215, #216, #222** (`LTVera-Pandas`), **#255, #256** (`rebalanceOS`), **#221, #254** (`aegis-sleuth-slack-bot`). Docs: `PROJECT/1-INBOX/GH-{215,216,222,255,256,221,254}-*.md`.

**Blast radius 4 repos.** Per the S5 rule these are **one target, not seven**. The idiom is quoted verbatim in GH-215: `ROOT="$(cd "$HERE/.." && pwd)"` — "correct only if the script lives at `repo_root/utils/…`; vendored one level deeper, `ROOT` resolves to `repo_root/.xyz`."

**Why it recurs:** every script re-derives root privately, and no suite fixture exercises the vendored layout.

**What one durable fix retires:** a shared root-resolution helper plus a vendored-`.xyz/` fixture in the suite retires all 7 and stops the next consumer repo filing an eighth. 6 of 7 still open.

#### T3 · `RADAR-class-roadmap-ledger-drift` — score ≈ 4.3 (10 × 3 ÷ 7.0)

**Class-shaped.** #163, #168, #202, #232, #228, #250, #253, #257, #272, #69. Seams: `utils/py/wave_reconcile.py`, `utils/py/releases_app.py`, and derived artifacts `RELEASES-PREVIEW.html` / `LEADERBOARD.html` / `releases.sql`. 8–9 issues across 5 distinct days, 2026-08-20 → 08-26 — **passes the recurrence discriminator.**

Root cause is in #69's own title: "ROADMAP.md … already is [a ledger] — with a regex for a schema"; #228 is that regex silently dropping issue URLs on an org rename. Two independent corroborations: `PROJECT/3-COMPLETED/GH-168-WAVE-RECONCILE-SCOPE.md:29` records "the class recurred same-day (`f8ea40a1` '(recurrence)')", and `PROJECT/1-INBOX/GH-269-RELEASES-DB-SWITCHOVER.md:24` notes agents "keep hand-editing it (two incidents this week)".

**GH-269 (DB as sole roadmap truth) is already the durable fix and is queued** — `releases.db.jog_queue` position 2. No multiplier: no false close found here.

#### T4 · `RADAR-marathon_drive.py` — score ≈ 3.5 (7 × 3 ÷ 6.0)

**Seam-shaped, one file.** `utils/py/marathon_drive.py`: #514 (`54aec132`, 08-18), #129/#130/#131 (`d92236cb`, 08-21), #135–#140 (`9c07f0cc`, 08-21), #115 (`0f4aa372`, 08-23), #217 (`793588d0`, 08-24), #255/#256 (`9e99c85c` + `fa372590`, 08-26). **5 distinct days, 6 distinct PRs/branches — passes the discriminator.**

Central dispatcher for every marathon lane. Overlaps T1 and T2 by membership; listed separately because the *file* is the concentration point regardless of class. #290 and #291 (both open) extend this into the Jog supervisor — see the PR #281 note under T1.

#### T5 · `RADAR-agy-auth-preflight` — score ≈ 3.3 (5 × 3 ÷ 6.75 × 1.5) — **already retired; one loose end**

**Seam-shaped, one function.** The agy auth probe verb at `utils/py/agy-turn.py:142`, `:259`, `utils/py/consult.py:299`. #130 → #135 → #221 → #245, span 2026-08-22 → 2026-08-26. Fixes: `d92236cb` (08-21), `68534a30` (08-24, "probes `agy models`, not the removed `whoami`"), `c2786452` (08-25, "pin the agy probe verb with a cross-call-site invariant").

#245's body is the cleanest self-diagnosis in the repo — it tabulates all three prior fixes and states "Nothing prevents the fourth recurrence." Ranked low only because the durable fix (#245/#247 cross-call-site invariant) **has already landed**.

**Loose end: #227 is still OPEN and is the same defect as the closed #221** (0.43 similarity, created 2026-08-25, one day after #221 closed). Verify the invariant covers it and close, or it will read as a live fourth recurrence.

#### T6 · `RADAR-class-headless-turn-timeout` — score ≈ 2.0 (4 × 3 ÷ 6.0)

**Class-shaped.** Turn caps that kill productive work or fail to kill dead work: #114 (closed, pty/idle-kill attribution), #237 (open, "consult.sh agy lane hangs idle in throwaway worktree, 2/2, idle-killed before 300s cap"), #276 (open, "300s cap kills progressing codex advisors"), #285 (open, "reports exit 7 at the timeout cap but never kills the child"). Span 08-24 → 08-27; 3 of 4 open.

**Evidence is weak and is flagged rather than inflated** — S6 found `exit 7` in only 2 of 83 logs.

#### T7 · `RADAR-class-frozen-twin-dead-fix` — formula score ≈ 1.2, **promoted on mechanism**

**Class-shaped.** 11 FROZEN Bash twins under `relay-automation/` (`agy-turn.sh`, `codex-turn.sh`, `claude-turn.sh`, `aider-turn.sh`, `pi-turn.sh`, `poll.sh`, `relay-loop.sh`, `relay-drive.sh`, `marathon-drive.sh`, `consult.sh`, `relay-turn-lib.sh`) plus `utils/swarm-preflight.sh`, `utils/marathon-plan.sh`. **An edit to a twin reports success and changes nothing.**

Documented recurrence: `fa372590` catching `74bb8d1c`. The existing guard `test/gh308-frozen-twin-guard.sh` is **range-scoped** (`GH308_FROZEN_TWIN_BASE=<merge-base>`, and `freeze_commit_for()` at line 158 deliberately narrows the predicate), which is why it did not catch `74bb8d1c`.

**Judgment call: treat as top-3 on mechanism despite the formula.** It scores 1.2 only because its governing issues (#308, #362, #418) live in the upstream tracker and are invisible to this repo's `gh issue list` — the same structural blindness noted in the degradation table. It is the delivery mechanism by which T1 and T2 fixes silently fail to ship.

### Clusters dropped as uncited or non-recurring

- **Telemetry ingest** around `utils/py/repro_builder.py` — #180/#181 cite each other as "same ingest seam", but both closed 2026-08-23 in one pass. **Concentrated authoring; fails the discriminator.**
- **Containment/scratch family** — #1, #2, #10, #91, #113, #182, #184. Seven kinship edges, the densest subgraph in S1, but every member is closed and in `3-COMPLETED`, with no in-window recurrence and no open successor. **Nothing left for a durable fix to retire.**

---

## Lens 2b — open-PR collision check

**Zero open PRs** (`gh pr list --state open --limit 100` → `[]`). No collision surface; every target below classifies as **"no work underway"**.

**The one thing that changes the operator's next step:** PR **#281** is no longer blocked open work — **it merged** at 2026-08-28T15:33:25Z (merge commit `144f75c2`, base `development`, confirmed an ancestor of `origin/development`). A 6-blocker review was posted at 15:07:59Z against `86f97eac`, ~25 minutes earlier. The findings were **converted to follow-ups rather than fixed pre-merge**: #290 and #291, both open.

**Verified at `origin/development` `9451b504` — all six blockers landed unchanged**, at identical line numbers:

| Blocker | State on trunk |
|---|---|
| Auto-merge gates on `outcome == "approved"` alone, while `jog land` runs 7 checks + ancestry | `utils/py/jog_run.py:259` — unchanged |
| `retry-gate` / `run_marathon_phase` export `RELAY_DRIVER_LOCKED=1` without holding the lock | exports at `:409`, `:565`; `JogSupervisorLock` only at `:814`, `:1259` |
| 893-line suite unregistered | absent from `validate.sh` — see T1 |
| `result_path` never persisted before dispatch | assigned at `:403`; last save at `:368` |
| Landing marker written before `jog_set_status` | unchanged at `:747-758` |
| Driver exit 4 ("issue already closed") → `escalated` → `failed`, halting the queue | no `issue-closed` handling in `jog_run.py` |

Sharpest consequence: opt-in `--auto-merge` combined with a cross-repo `--target-root` can merge an unrelated PR in the harness repo and report `completed`, because the PR number is derived by `gh pr list --head <branch>` in the *target* repo while the merge runs with `cwd=root`.

**Two operational cautions.** PR **#286** (`fix(pdda): restore ledger coverage for GH-105/GH-107 — development is gate-red and blocking every push`) was **closed unmerged**; #288 landed the fix by a different route. And the local checkout used for part of this session was 96 commits behind `origin/development` with uncommitted modifications to `harnesses.db`, `harnesses.sql`, `RELEASES.md`, `ROADMAP.md`, `LEADERBOARD.*` — triage run off a stale local tree reads a different repo than CI does.

---

## Lens 3 — release recalibration

**Plan of record used: `releases.db` via `utils/py/releases_app.py`, not `RELEASES.md`.** `RELEASES.md` exists (42.1K, not a seed) but is superseded: no 0.7.4 block at all, its 0.6.0 codename is `Meter` where the DB says `Front-Door`, and its `GH_URL:` fields point at a different org (`Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm`) than `origin` (`HiQS-Labs/XYZ-forge`). Its own header (`RELEASES.md:9-22`, GH-381) declares the file optional and explicitly not something to keep topped up — **that staleness is a valid state, not a finding, and this report does not edit it.**

### The milestone join is impossible for every unshipped row

`HiQS-Labs/XYZ-forge` has exactly **two milestones** — `Ballast` (#1) and `Bulkhead` (#2) — and **both hold 0 open issues**. Both belong to already-shipped releases (0.7.0 Ballast shipped 2026-08-18; 0.7.3 Bulkhead shipped 2026-08-25). None of the six unshipped rows' `Milestone:` values exist as milestones: `Linux MVP RC` (0.7.4), `Cargo`, `Front-Door`, `Sundown`, `Plumbline`, and 0.5.0's field holds prose rather than a title. **Findings below fall back to `Description:` prose plus the DB manifest, as the rule requires.**

### Orphan share: 81 of 81 open issues (100%) carry no milestone

Per the rule, **this is not backlog drift** — with no milestones to belong to, the number measures a **missing binding**. The actionable finding is: **create `Linux MVP RC` and bind 0.7.4's rows**, so the next run can join. The two milestones that do exist are spent.

### The active arc's Description no longer describes where effort goes

0.7.4 Linux-RC says "portability blockers cleared, hosted Ubuntu CI attestation on branch Linux-MVP-RC"; its exit criterion is a green hosted Ubuntu CI run plus #224's checklist. Against 822 commits on `origin/development` in-window (293 machine/harness excluded → 529 human):

- **17 human commits (3.2%)** match linux/ubuntu/portability/bsd/gnu/sc2144.
- **194 (36.7%)** match jog/marathon/relay/releases/ledger/roadmap machinery.
- The five most recent merged PRs — #288, #287, #284, #283, #281 — are all ledger/jog/marathon. None are Linux.
- One commit states it outright: `docs(marathon): housekeeping marathon (GH-182 + GH-197), no Linux-RC work` (2026-08-25).

**The plan says Linux RC; the repo is doing harness orchestration and the releases ledger.** Advisory only.

### The milestone's issue set has drifted from its stated theme

Visible in the DB manifest since the GitHub join is unavailable. Of 0.7.4's 12 manifest items, 5 shipped and 7 are `dialed_in`. **Only #123** (Linux portability canary) **and #249** (ubuntu canary red, EUID=0) are Linux/CI. The other four open items are harness concerns wearing a Linux-RC label: **#251** (pytest merely absent misreported as FAILED), **#255** (`XYZ_ARCHIVE_ROOT` omitted from a refusal message), **#256** (no preflight for phase artifact paths), **#275** (write-ops logging).

Separately: **#204 is CLOSED on GitHub but still carried as `dialed_in`** in the manifest.

### Claimed vs. unclaimed targets

| Target | Status |
|---|---|
| T1 `class-guard-blind-matcher` | **UNCLAIMED** — no planned band covers it |
| T2 `class-vendored-root-resolution` | **UNCLAIMED** — #255/#256 sit in 0.7.4 as Linux-RC items, but the *class* (4 repos, 7 issues) is unplanned |
| T3 `class-roadmap-ledger-drift` | **claimed by GH-269** (`jog_queue` position 2) |
| T4 `marathon_drive.py` | **partially claimed** — #290/#291 open, opened post-merge |
| T5 `agy-auth-preflight` | **claimed and largely retired**; #227 loose end |
| T6 `class-headless-turn-timeout` | **UNCLAIMED** — 3 of 4 open |
| T7 `class-frozen-twin-dead-fix` | **UNCLAIMED** — governing issues live upstream |

Five of seven targets are unclaimed by any planned band.

---

## Checklist at generation time

*Historical snapshot. The live copy is the `radar`-labelled tracking issue; reconcile there, not here.*

### RADAR-class-guard-blind-matcher — 7 issues over 10 days · first-seen: 2026-08-28 · runs: 1

- [ ] Register `test/gh280-jog-marathon-adapter.sh` in `validate.sh`'s `TESTS` array — acceptance: `sed -n '/^TESTS=(/,/^)/p' validate.sh` names it, and CI executes its 139 assertions
- [ ] Make `test/gh35-test-tiers.sh` bidirectional: fail when a `test/*.sh` file exists that `TESTS` does not name — acceptance: adding an unregistered suite turns the guard red
- [ ] Generalize the derive-from-source pattern proved in `fa372590` into a reusable helper — acceptance: at least `test/marathon-root-audit.sh` and the agy preflight guard derive their expected set rather than hardcoding it
- [ ] Close #195 / #273 together with the commit SHA — acceptance: the reopen loop is cited as closed by a derived matcher, not a widened pattern

### RADAR-class-vendored-root-resolution — 7 issues across 4 repos · first-seen: 2026-08-28 · runs: 1

- [ ] Add one shared root-resolution helper that resolves correctly at both `repo_root/utils/…` and `repo_root/.xyz/utils/…` — acceptance: the GH-215 idiom `ROOT="$(cd "$HERE/.." && pwd)"` appears in no shipped script
- [ ] Add a vendored-`.xyz/` fixture to the suite — acceptance: a script that assumes the bare layout fails in CI, not in a consumer repo
- [ ] Close #215 / #216 / #222 / #255 / #256 / #221 / #254 against the shared helper — acceptance: no consumer repo files an eighth

### RADAR-class-roadmap-ledger-drift — 10 issues over 6 days · first-seen: 2026-08-28 · runs: 1

- [ ] Land GH-269 (releases.db as sole roadmap truth) — already at `jog_queue` position 2; acceptance: `ROADMAP.md` is generated, never hand-edited, and the regex-as-schema in #69 is retired

### RADAR-marathon_drive.py — 7 issues over 5 days · first-seen: 2026-08-28 · runs: 1

- [ ] Confirm #291 enumerates all six merged #281 blockers (auto-merge verification, supervisor lock, `result_path` persistence, landing-marker ordering, exit-4 mapping, suite registration) — acceptance: each has a named acceptance condition or its own issue
- [ ] Decide `--auto-merge` policy at head — acceptance: either a refusal guard lands, or the cross-repo case is verified safe with a test

### RADAR-agy-auth-preflight — 4 issues over 4 days · first-seen: 2026-08-28 · runs: 1 · largely retired

- [ ] Verify the #245/#247 cross-call-site invariant covers #227 and close it — acceptance: #227 closed citing the invariant, or reopened as a genuine fourth recurrence

### RADAR-class-headless-turn-timeout — 4 issues over 3 days · first-seen: 2026-08-28 · runs: 1 · weak evidence

- [ ] Instrument turn termination so idle-kill, wall-cap, and child-orphan are distinguishable in the run log — acceptance: a later radar run can answer "how many of the last N runs" at useful N

### RADAR-class-frozen-twin-dead-fix — first-seen: 2026-08-28 · runs: 1 · promoted on mechanism

- [ ] Widen `test/gh308-frozen-twin-guard.sh` beyond its merge-base range scope — acceptance: an edit to any FROZEN twin fails the guard regardless of base, replaying `74bb8d1c` as a red

---

## Reconciliation notes for the next run

1. **No trend line exists yet.** The next run (on or after ~2026-09-18) will be the first with a genuine prior window. Until then, do not read any delta as a trend.
2. **Record the doc-corpus figures above** before attributing S1 citation changes to defect activity — a PDDA lifecycle sweep moves counts without any defect moving.
3. **Never strike a target on symptom disappearance alone.** T1 and T7 are causally linked: T7 is the mechanism by which a T1 fix can silently fail to ship. If T1 goes quiet without a commit naming its seam, annotate it *quiet, unexplained — possible symptom masking by RADAR-class-frozen-twin-dead-fix* rather than striking it.
4. **`rgt:` adoption is the measurement fix for Transform.** If the tagging issue lands, the next run reports a declared Transform share; if it does not, `0%` will continue to mean "undeclared" and should keep being printed that way.
