---
title: "SOP: CI churn recovery — entry gate, strategy checklist, exit gates"
status: Active — landed 2026-09-27 (#857); thresholds are tunable defaults
created: 2026-09-27
updated: 2026-09-27
owner: operator
goal: >
  A reusable playbook for the next CI churn episode: declare it on measurable triggers, open a
  time-boxed recovery window only after Day 0 prerequisites hold, work a phased strategy with
  scoped and declared exceptions, and close on measurable exit gates or a written hard-stop path.
doc_type: sop
context_tags: [ci, flaky-tests, gates, merge-queue, stabilization]
related:
  - "#802 — CI retrospective; operator decision (comment 5841529958)"
  - "#831 — no new tests; three gate tiers"
  - "#853 — suite-isolation umbrella (whack-a-mole cluster)"
  - "#854 — stabilization window; operator decisions D1–D6 (comment 5857449176)"
  - "#849 — merge-cleanup batch that exposed the ledger and sleep costs"
  - "#293 — radar board"
---

# Standard Operating Procedure (SOP): CI Churn Recovery

> **Scope & relationship to other docs**
> - **`AGENTS.md`** owns the rails this SOP works inside: *No new tests*, the bypass rule (GH-487),
>   the branch rules, the GH-784 QA receipt, and never deferring a test run to CI. This SOP grants
>   **no** standing exception to any of them. Each window's exceptions are dated operator decisions.
> - **`ROUTER.md`** owns the tier definitions and command rails. **`SOP.md` §4** owns branch
>   discipline and the merge predicates. **`PROJECT/PDDA.md`** owns the tracking doc and ledger.
> - **This file** owns one thing: how to recognise a churn episode, run a bounded recovery, and
>   prove it is over. Specific numbers below are **tunable defaults**, not measured facts, unless a
>   citation says otherwise.

---

## 1. Purpose and what "CI churn" means here

**CI churn** is when the team spends more time keeping the gate green and landing changes than on
the product. It is a system state, not one bad suite. The operator goal behind the 2026-09 episode
was "stop spending more time on CI than on the project" (#802, #853, #854).

Typical symptoms, usually several at once:

- The hosted qualifying lane (`wave-reconcile.yml` today) fails most runs, or fails on a clean trunk.
- The same failure class is fixed one suite at a time; each fix holds, and new members keep arriving.
- The test registry grows faster than the code it protects.
- Merges serialize behind long full-registry runs; ready PRs wait days.
- Many open PRs conflict on one shared or generated file, so each landing re-conflicts the rest.
- Tooling times out before the run it waits on can finish.
- Agents bypass the push gate informally to get work out.
- The flow mix tilts to Run (KTLO); Grow falls and releases slip.

---

## 2. Entry gate — declaring a churn recovery

### 2.1 Trigger criteria (proposed defaults — tune per episode)

Measure each from existing sources only: hosted run history, gate records, `validate.sh` `TESTS`,
issue search, radar/whack-a-mole output. **Do not add telemetry, guards or suites to measure
them** (AGENTS.md *No new tests* forbids new gate machinery).

| # | Trigger | Default threshold (tunable) | Source |
|---|---|---|---|
| E1 | Hosted qualifying-lane failure rate | ≥ 30% of the last 20 runs, or ≥ 5 consecutive failures | `gh run list --workflow wave-reconcile.yml` |
| E2 | Merge lead time | median ready→merged > 2 days, or ≥ 5 ready PRs waiting on serial qualification | PR list |
| E3 | Shared-file conflict load | ≥ 50% of open PRs touch one shared/generated file, or ≥ 2 PRs parked at the repair cap in one batch | open-PR file lists; merge-cleanup records |
| E4 | Registry growth | any net growth of `TESTS` while *No new tests* is in force; otherwise > 1 suite/day over 14 days | `validate.sh` at two SHAs |
| E5 | Repeat-fix cluster | one class with ≥ 5 repeat fixes in 14 days, or whack-a-mole churn score ≥ 40 | `/whack-a-mole`, radar |
| E6 | Red on clean trunk / rescues | ≥ 2 clean-trunk reds in 7 days, or ≥ 2 re-run-alone rescues across the last 5 full gates | issues, gate records |
| E7 | Timeout vs real duration | any tooling wait or job cap < 1.25 × the longest of the last 20 runs it covers | tool config vs run durations |
| E8 | Flow mix / release | Run share ≥ 80% in two consecutive radar runs, or the active release slips on CI work | radar report, `releases.sql` |

**Declare** when any two triggers fire, or any one fires for 7 consecutive days. E7 alone is a
Day 0 fix, not a window: fix the timeout and re-measure.

### 2.2 Who declares

- [ ] **Anyone may propose** (agent, radar run, whack-a-mole run, reviewer) by posting the trigger
      table with values and sources on a tracking issue.
- [ ] **Only the operator declares.** Declaring does not open the window; it starts Day 0.
- [ ] The proposal names which rails the window would bend (see §4.5). No bend is implied by
      declaring.

### 2.3 Day 0 prerequisites — all must hold before the window opens

- [ ] **Tracking issue opened** from the template in §7.1, labelled `ci`, `stability`, and a priority.
- [ ] **Owner named** (one person merges into the staging branch; one independent reviewer).
- [ ] **Baseline metrics captured** in the §7.2 table, with sources and timestamps.
- [ ] **Hard end date set** in the issue title or first line. Default: 7 days to target landing,
      10 days to hard stop.
- [ ] **Freeze scope decided** in writing (§4.1): what may not grow during the window.
- [ ] **Tooling timeouts checked against real durations.** For every wait or cap on the landing
      path, record `timeout / longest recent run`. Anything under 1.25 is raised first.
      Queued time counts if the clock starts at the call.
- [ ] **Gate host stable.** Unattended landings and full gates run on an always-on host, or under
      `caffeinate -i` with lid open and on AC. Record the host in every gate record.
- [ ] **Shared-file hotspots identified.** List files touched by ≥ 2 open PRs. Decide how branch PRs
      avoid them (e.g. no ledger rows until landing).
- [ ] **Trunk-pinned automation listed.** Which workflows and scripts only work on `development`?
      Those items go on the direct path, not the staging branch.
- [ ] **In-flight batch drained or parked** with recorded dispositions, so the window starts from a
      known trunk.
- [ ] **Stale-but-fixed issues closed** with a citing commit, after a red control at HEAD.
- [ ] **Operator decisions recorded** (§7.3) for every rail the window bends, each with a default,
      a fallback, and an adopt-if rule where the outcome is uncertain.

**Start condition:** every box above is ticked on the tracking issue. The staging branch is cut
from `development` at that point, not before.

---

## 3. Roles

| Role | Does | Does not |
|---|---|---|
| Operator | Declares; answers decisions; approves branch cut, deletion, extensions | Delegate decisions implicitly |
| Window owner (orchestrator) | Runs the daily cadence; merges into staging; posts status | Merge its own build lanes without review; self-attest QA |
| Builders (agy/codex lanes, humans) | One fix per PR with its evidence | Touch shared/generated files on branch PRs |
| Independent reviewer / QA | Per-PR receipt; combined landing QA (GH-784) | Accept test-only observation as review |

---

## 4. Strategy checklist (phased)

Work phases in order. Later phases may overlap once earlier ones are stable.

### 4.1 Phase A — Stop the bleeding

- [ ] Freeze the growth driver. Default: keep *No new tests* in force; add a scoped freeze for any
      other growing surface (new guards, lanes, workflows, ratchets) for the window.
- [ ] Find the **rule or incentive** producing the growth, not just the growth. Inventory the
      instructions (root docs, skills, brief generators, tool refusals) that push agents to add
      what is growing. #831 R4 is the model inventory.
- [ ] Rewrite those instructions in the same change as the freeze, landed through the normal
      issue-first PR **before the window opens** (a Day 0 prerequisite). A freeze without removing
      the instruction fights the agents every day. In 2026-09 this was #831 (`f832ef5a`, `b2c307b4`).
- [ ] Verify the freeze with a count at two SHAs, posted daily. Do not add a suite to enforce it.

### 4.2 Phase B — Triage and cluster

- [ ] Run `/whack-a-mole` over the churn window. Group repeat fixes by root cause, not by suite.
- [ ] One umbrella issue per class, with a cluster signature, member list, fix commits, and churn score.
- [ ] Rank classes by landing-queue cost (how many serial full runs a red costs), then by churn.
- [ ] First umbrella task: **reproduce and classify** each open member as suite assumption, product
      defect, or legitimate regression. If most are legitimate regressions, stop and re-scope.
- [ ] Fix the invariant, not the call sites. Prefer one edit to an existing helper over N suite edits.
- [ ] Disposition per class: fix in place (in-tier suite), turn off by unregister-and-exempt keeping
      the file (out-of-tier suite), or fix the product.

### 4.3 Phase C — Stabilise the pipeline plumbing first

- [ ] Get the hosted qualifying lane green on its own terms before trusting any other signal.
      A red lane makes every other metric unreadable.
- [ ] Raise every timeout found in Day 0 to ≥ 1.25 × the longest recent run. Prefer config
      (environment variable) over code during the window; land the code default on the direct path.
- [ ] Bound every network call on the landing path; after any merge-call failure, re-query state
      before declaring failure.
- [ ] Keep the gate host awake; treat any gate > 2× the awake band as invalid evidence and re-run.
- [ ] Check runner capacity: one gate at a time per host; no concurrent relay turns during full runs.
- [ ] Confirm each configured check actually runs for the event you rely on (a step in a job that
      never triggers is not a check).

### 4.4 Phase D — Unblock merge throughput

- [ ] Open **one** time-boxed staging branch (`staging/<topic>-<yyyy-mm>`) for the umbrella fixes only.
      Feature PRs stay on the normal path.
- [ ] Branch PRs write **no** shared/generated files (ledger rows, views, PDDA moves). Write them
      once, at landing, through their normal writer.
- [ ] Items that change landing machinery (merge-cleanup, reconcile, workflows) go **direct** to
      `development` through the normal gate by default. The staging branch cannot exercise them.
      The operator may move one onto the branch when nothing in the window depends on it landing
      early (2026-09: #851/#852, #854 comment 5858552134).
- [ ] Do not run trunk-pinned automation against the staging base. Merge by hand; dispatch CI
      with `gh workflow run <wf> --ref <branch>`.
- [ ] Batch same-seam fixes into one PR (SOP.md §4 Arc planning, item 2).
- [ ] Use `/express` only for true single-fix hotfixes that meet its own bounds; it is not a
      queue-jumping lane for window items.
- [ ] Measure: queue wait per fix (M1) and hosted Large runs spent (M2) vs the pre-window baseline.

### 4.5 Phase E — Controlled exceptions with guardrails

Every exception is a dated operator decision on the tracking issue. Each must be:

- [ ] **Scoped** to PRs whose base is the staging branch. Never `development`, never `main`, never
      promotion or teardown.
- [ ] **Declared** in each PR body: which gate was skipped, and a link to the evidence directory.
- [ ] **Compensated:** before its staging merge, the PR's edited suites, its area suites and its
      fails-before/passes-after receipt (Phase F) must pass. Only the **full-registry** run moves: it is
      paid locally, by the daily `ci-local.sh` run and by the landing PR's non-bypassed pre-push
      gate, both before `development` is touched. Nothing is deferred to hosted CI.
- [ ] **Revoked** at landing. Ad-hoc bypasses outside the window return to the GH-487 rule.
- [ ] **Absorbing:** informal bypasses already happening are routed through the window, not tolerated
      alongside it.

### 4.6 Phase F — Evidence per fix

- [ ] Red control on the pre-fix base, at the width or host where it fails.
- [ ] The fix.
- [ ] Edited suite green at that width, 5 of 5 runs (default).
- [ ] Lightweight independent QA receipt per PR: fails before, passes after (GH-784).
- [ ] Evidence under `TESTS-RESULTS/<date>+GH-<n>/` with committed `provenance.jsonl`.

### 4.7 Phase G — Daily cadence

- [ ] Sync `origin/development` into the branch. Ledger conflicts via `utils/releases-merge-resolve.sh`.
- [ ] Full registry (`bash ci-local.sh`) at the branch tip, disposable full clone, stable host.
- [ ] Red full run → stop merges until the red is attributed to one commit and fixed or reverted.
- [ ] Hosted dispatch on the branch (`gh workflow run ci.yml --ref <branch>`): `vendored-smoke` must
      be green (it runs on dispatch, `continue-on-error: false`). The Ubuntu canary is advisory.
      Nothing enforces this on the branch, so a red `vendored-smoke` stops merges like a red full run.
- [ ] One status comment: date, tip SHA, PRs merged, gate result + duration + host, run IDs, M1–M3.
- [ ] Stop/continue check: are exit gates trending toward met by the hard stop? If not, cut scope
      today, not on the last day.

### 4.8 Phase H — Landing

- [ ] Freeze the branch; final sync; full registry green at the frozen tip.
- [ ] One ledger commit through the writer for every fixed issue; `releases_app.py check` clean.
- [ ] Landing PR carries one `Closes #N` per fixed issue (merges into a non-default branch close
      nothing), the exception disclosures, every per-PR receipt, and one combined QA pass.
- [ ] Full pre-push gate, not bypassed. Merge with a **merge commit**, so each fix stays revertible.
- [ ] Green hosted reconcile on the full registry; then delete the branch with operator OK.
- [ ] Check every issue the window fixed is actually closed.

### 4.9 Phase I — Decisions log

- [ ] Every rail bend, default change, and deferral is a numbered decision (D1…Dn) in §7.3 form.
- [ ] Uncertain changes get an **adopt-if rule set before the data**, e.g. "adopt edited-suite
      routing for test-only edits only if M3 = 0 across every daily full run" (#854 D6).
- [ ] Record the outcome data on the tracking issue whichever way the rule goes.

### 4.10 Anti-patterns (learned 2026-09; evidence in Appendix A)

- Rules, skill text or tool refusals that demand a **new suite per change**.
- Assuming that turning suites off buys speed. Routing is the time lever; "off" buys less flake.
- Test edits auto-escalating to the largest tier while the fix list is mostly test fixes.
- **Tooling timeouts shorter than real runs**, including queue time.
- Many PRs editing one shared generated file, so every landing re-conflicts the rest.
- Unattended gates on a host that sleeps.
- Relying on a merge to close issues when the PR has no closing keyword.
- Running trunk-pinned automation against a non-trunk base.
- Informal gate bypasses outside any declared scope.
- Open-ended windows without a hard stop; extensions without a written decision.
- Striking a target because the symptom went quiet, with no commit naming the seam (#293 rule).
- Declaring "fixed" from one green control run of a nondeterministic process (AGENTS.md GH-567).

---

## 5. Exit gates

### 5.1 Close the window when all hold (defaults tunable)

- [ ] **X1 Hosted lane:** the first 3 PR-closed hosted runs after landing are green on the full
      registry; the class umbrella's longer streak (default 10) continues from there.
- [ ] **X2 Local gate:** 3 full-gate runs at normal width on `development` after landing, disposable
      clone, stable host, zero re-run-alone rescues.
- [ ] **X3 Attribution metric:** M3 recorded for every daily run; any adopt-if decision resolved.
- [ ] **X4 Umbrella:** every member closed with a citing commit or turn-off, or explicitly deferred
      with an owner and a trunk issue.
- [ ] **X5 Throughput:** median merge lead time back under the E2 threshold.
- [ ] **X6 Exceptions revoked:** no PR into `development`/`main` carries a skip; carve-outs marked
      ended on the tracking issue.
- [ ] **X7 Branch:** landed with a merge commit, green reconcile, deleted.
- [ ] **X8 Freeze:** lifted, kept, or converted to permanent policy by a recorded decision.
- [ ] **X9 Metrics:** baseline vs exit recorded in §7.2 on the tracking issue.
- [ ] **X10 Growth:** registry count at exit ≤ count at entry.

### 5.2 Hard-stop path (hard end reached, gates not met)

1. No merges into the staging branch after the hard stop. -> expect the tip SHA recorded.
2. Land only what was green in the last daily full run. -> expect one landing PR, merge commit.
3. Re-target every other item to `development` as its own issue on the normal path. -> expect an
   issue link per item.
4. Revoke all window exceptions the same day. -> expect a revocation line on the tracking issue.
5. Record which exit gates failed and why. -> expect the §7.2 exit column filled.
6. No extension without a new written operator decision naming a new hard stop. Silence is "no".

---

## 6. Post-window

- [ ] **Suite audit** (default: the day after the hard stop). Score every registered suite on:
      runtime; real regressions caught vs flakes; overlap with other suites; whether it asserts
      prose/wording rather than behaviour. Propose one of:
      - **keep** in the full registry;
      - **nightly** (only if a nightly lane already exists; do not add one without a decision);
      - **merge** into an overlapping suite;
      - **turn off**: unregister and exempt, file kept.
      Nothing changes without operator sign-off (#854 comment 5857449176).
- [ ] **Retro and lessons entry** in `LESSONS-LEARNED.md`: what happened, the lesson, how to apply.
- [ ] **Policy changes the retro produces** (AGENTS.md, ROUTER.md, skills) go through the normal
      issue-first PR after the window. A tool the window itself needs (2026-09: the #862 audit skill)
      is a window item and follows the per-PR rule on the branch.
- [ ] **Follow-up check** scheduled (default 14 days after landing): the class has no new member,
      the freeze held, and E1–E8 are all below threshold. Post the result on the umbrella.
- [ ] Update this SOP's defaults if the episode showed a threshold was wrong.

---

## 7. Artifacts and templates

### 7.1 Tracking issue — required fields

```md
# CI churn recovery: <topic> (<start> → hard stop <date>)
Triggers fired: E? E? (table with value, threshold, source, timestamp)
Owner: <name> · Reviewer/QA: <name> · Operator: <name>
Staging branch: staging/<topic>-<yyyy-mm> (not cut until Day 0 is done)
Freeze scope: <what may not grow>
Day 0 checklist: (§2.3, ticked with evidence)
Decisions: D1…Dn (§7.3)
Direct-path items: <machinery changes that go straight to development>
Branch items: <umbrella members, ordered by landing-queue cost>
Per-PR rule: <exact commands; declared skip; receipt location>
Daily status: one comment per day (§4.7)
Exit gates: X1–X10 (§5.1) · Hard-stop path: §5.2
Related: <umbrella(s)>, <batch issue>, <radar board>
```

### 7.2 Metrics table

| Metric | Baseline (Day 0) | Day 1 … Day N | Exit | Source |
|---|---|---|---|---|
| Hosted lane: failed / last 20; current green streak | | | | run history |
| Full-registry hosted duration (min, max) | | | | run history |
| Longest tooling wait / cap vs longest run (ratio) | | | | config + runs |
| Registry size (`TESTS` count) | | | | `validate.sh` at SHA |
| Open members per umbrella | | | | issue search |
| Ready PRs waiting; median lead time | | | | PR list |
| Open PRs touching the top shared file | | | | PR files |
| Re-run-alone rescues per full gate | | | | gate records |
| M1 queue wait per fix | | | | PR timestamps |
| M2 hosted Large runs spent | | | | run history |
| M3 full-run failures outside edited suites | | | | daily full runs |
| Run / Grow share (radar) | | | | radar report |

### 7.3 Decision log entry

```md
- [ ] **D<n> — <short name>.** Rail bent: <AGENTS.md line or none>. Scope: <branch/PR set>.
  - Default: <proposal>. If no: <fallback>.
  - Adopt-if (if the outcome is uncertain): <metric and threshold, set now>.
  - Operator answer: <APPROVED / DECLINED / DEFERRED to date>, <date>, <comment link>.
  - Revoked at: <landing / hard stop / never, with reason>.
```

---

## Appendix A — Lessons from the 2026-09 episode

Grades: **FACT** (observable in a committed artifact, issue or run), **PATTERN** (≥ 2 independent
sources or a recurrence), **HYPOTHESIS** (inferred; not yet tested). Times are PT.

| # | Lesson | Grade | Evidence |
|---|---|---|---|
| A1 | The `validate.sh` registry grew from 207 to 419 entries in 41 days (avg ~5.2/day; peak ~6.7/day in Aug 15–Sep 5). | FACT | `validate.sh` at `1f0a5bf1` vs `f832ef5a`; RADAR-REPORT-2026-09-26 CI table; #853 |
| A2 | Rules and skill text told agents to add a new test per change; `express.py` refused a hotfix without a registered `--suite`. | FACT | `PROJECT/3-COMPLETED/GH-831-THREE-TIER-GATE.md` R4; #831 body ("one `gh<N>-*.sh` per fixed issue", #815) |
| A3 | Those instructions were the main driver of registry growth. | PATTERN | A1 + A2 together; causation is inferred, not measured |
| A4 | A *No new tests* rule plus three routing tiers stopped the inflow: 0 test files added from the freeze through 2026-09-27 7:40 AM. | FACT (early) | `f832ef5a` (#832), `b2c307b4` (#834); radar addendum; freeze was ~1.5 days old |
| A5 | Turning suites off saved almost no time (8 suites, ~6 s). Routing is the time lever. | FACT | GH-831 doc R2 finding |
| A6 | Any `test/*` edit routes to Large, so tiering barely helps when the fix list is mostly test fixes: 32% of 146 merges were tier 1 as merged vs 42% without test edits. | FACT | `utils/ci-route.sh:361-378,478-479`; GH-831 doc R3; #854 |
| A7 | 50 of 54 `fix:`/`hotfix:` commits (Sep 12–26) touched `test/`. | FACT | #853; radar Lens 2 |
| A8 | Whack-a-mole: 22 issues, 10 fix commits on 7 days, 0 reopens, 0 reverts. Each fix held; the class kept producing members. Churn score 65. | FACT | #853 cluster signature; #293 |
| A9 | Suite count raises the odds that some host assumption breaks on a given run. | HYPOTHESIS | #853 root-cause section; reviewed with caution in #802 comment 5825412680 |
| A10 | The freeze stopped the inflow but not the stock of fragile suites. | PATTERN | radar exec summary; #293 standing observation |
| A11 | The hosted lane went from 80–85% weekly failure (and 59 straight failures Sep 11–18) to 25 consecutive green after plumbing fixes. | FACT | #684; `d3c220de` (#743); radar hosted-health table; #293 |
| A12 | Tooling timeouts shorter than real runs: merge-cleanup waited 1800 s against 52.8–65.9 min Large runs; the macOS promotion cap was 45 min against a 60–92 min suite. | PATTERN (two FACT instances) | `merge_cleanup.py:431,434-435,495-501`; #854 D5; #823 (via #854 cross-index) |
| A13 | Setting the wait by config (`MERGE_CLEANUP_HOSTED_WAIT_S=5400`) fixed it with no code change; the code default follows on the direct path. | FACT (decision) | #854 D5; comment 5857449176 |
| A14 | One shared generated file (`releases.db`/`.sql`) was touched by all 8 open PRs; each landing re-conflicted the rest; two PRs parked at the repair cap and needed operator approval for a third repair. | FACT | radar Step 2b; #849 comments 5852638878, 5857312850, 5857490014; earlier instances in #293 ledger-drift target |
| A15 | Ledger-free branch PRs with one ledger write at landing remove that conflict source. | FACT (design, accepted) / outcome untested | #854 review 5857379277; reply 5857409572 |
| A16 | Host sleep stretched a push gate to 8,967 s and produced re-run-alone rescues; under `caffeinate -i` full gates took 862–874 s. | PATTERN (self-reported) | #849 comment 5857312850; #854 review 5857379277; graded self-reported in reply 5857409572 (862 s may predate sleep) |
| A17 | Unbounded network calls and a merge call that "failed" after GitHub merged skipped post-merge steps. | FACT | #852 comments 5855239082, 5855372014; #849 comment 5857312850 (#810) |
| A18 | A PR with no closing keyword left its issue open; merges into a non-default branch close nothing. | FACT | #810 / #807; #854 Day 0 and landing sections |
| A19 | Trunk-pinned automation cannot serve a staging branch: merge-cleanup's reconcile exits 4 off `development`, `wave-reconcile.yml` qualifies `development` only, and `ci.yml`'s `push`/`pull_request` triggers cover `main`/`development` only. `ci.yml`'s `workflow_dispatch` does run `vendored-smoke` on the branch. | FACT | `merge_cleanup.py:545-559` → `wave_reconcile.py:2168-2173`; `ci.yml:98-103`, `:519-522`; run 36358027559 |
| A20 | A configured hosted step never ran on PRs (job not triggered on `pull_request`). | FACT | `ci.yml:398-400` vs `:248-250`; #854 |
| A21 | Informal bypasses (`--no-verify`, `XYZ_SKIP_PREPUSH=1`) appeared under queue pressure and were routed into the window. | FACT | #846, #827; #854 D1 |
| A22 | Per-PR fails-before/passes-after receipts were kept, not replaced by one combined QA, so a red landing can be attributed. | FACT (decision) | #854 D3; comment 5857449176 |
| A23 | Decide adopt-if rules before the data: edited-suite routing for test-only edits only if M3 = 0. | FACT (decision) | #854 D6; comment 5857449176 |
| A24 | A staging window saves ~7 serial Large waits for ~6 fixes. | HYPOTHESIS | #854 router section; M1/M2 test it |
| A25 | Churn crowded out Grow: Run 76.7% → 83.1% (adj. 86.3%), Grow 14.4% → 9.4%; weekly issues flat (75, 87, 70, 89); 0.9.0 shipped 6 days late; 0.6.0 expected to miss its date. | FACT (numbers) / PATTERN (cause) | RADAR-REPORT-2026-09-26 Lens 1 and 3; #293 |
| A26 | Operator decisions with defaults and fallbacks made a fast, bounded window possible without changing AGENTS.md. | FACT | #854 rev 2–3; comment 5857449176 |

**Outcome not yet known at writing (2026-09-27):** whether the window met its exit gates, the M1–M3
results, the D6 outcome, and the 2026-10-08 suite audit. Add them here after the retro.
