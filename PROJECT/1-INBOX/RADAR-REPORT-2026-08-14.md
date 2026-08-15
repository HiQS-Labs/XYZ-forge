---
title: "Radar report — xyz-3-agents-swarm, 2026-07-25..2026-08-14 (run 3)"
status: 1-INBOX
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: report
roadmap_exempt: true
goal: >
  Windowed Run/Grow/Transform read, recurring-defect targets ranked by what one durable fix would
  retire, and release-plan drift. Analysis only — this document executes nothing.
---

# Radar — run 3

Window **2026-07-25 .. 2026-08-14** (21 days), trunk `development`. Prior window for the trend:
2026-07-04 .. 2026-07-25. Live checklist: [#444](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/444).
Prior runs: [run 1](RADAR-REPORT-2026-08-07.md) · [run 2](RADAR-REPORT-2026-08-07-run2.md).

## Lens 1 — flow distribution

Tally proven before use: `git log --no-merges` wrote **445** subject lines, the five buckets sum to
**445**, and `git rev-list --no-merges --count` independently returns **445**. Prior window: 629 /
629 / 629. (`/usr/bin/git` used throughout — the RTK proxy has silently truncated `git log` on this
machine before, and a partial read is indistinguishable from a real distribution.)

| Bucket | This window | Prior window |
|---|---|---|
| Harness (excluded from denominator) | 162 | 230 |
| **Run** | 220 — **77.7%** | 215 — 53.9% |
| **Grow** | 36 — **12.7%** | 28 — 7.0% |
| **Transform** | 0 — **0%** (`rgt:` adoption: **0 docs**) | 0 — 0% |
| **Unclassified** | 27 — **9.5%** | 156 — 39.1% |
| RGT denominator | 283 | 399 |

**Transform is 0% because nobody has declared anything.** No `PROJECT/**` doc carries an `rgt:` key,
so the figure cannot become non-zero until the key is adopted. It does not mean no transformative
work happened — `GH-308`'s Bash-twin port and `GH-340`'s native Python engine are both plausibly
Transform-shaped and both landed unclassified.

**Verdict: the mix did not improve — it became legible.** Unclassified fell 39.1% → 9.5%, and
essentially all of it resolved into Run rather than Grow. The honest reading is that the prior
window's 53.9% Run was an *undercount* produced by a bad measurement, and the underlying rate has
been near 80% the whole time. **Treat the trend line as weak**: comparing a 9.5%-unclassified window
against a 39.1%-unclassified one measures the convention as much as the work.

### Adjusted read

Mechanical: Run 77.7 · Grow 12.7 · Unclassified 9.5.
Adjusted (all 27 unclassified subjects hand-bucketed): **Run ~85% · Grow ~15% · Unclassified 0%.**
Six of the 27 are Grow-shaped (`Support grok-4.6 alias`, `fix(GH-426)+feat(0.3.0)`, `GH-340` engine,
`GH-308` port, `GH-284` Phases 2 and 4); the remaining 21 are Run. **Adjustment moves Run up, not
down** — the unclassified bucket was not hiding growth.

### Measurement defect, source-fixable

Two malformed families account for all 27:

- **issue-as-type — 15 commits.** `GH-308: Bash-twin behavior audit + port`, `GH-284 Phase 4: …`,
  `GH-354: review the concurrent-swarms analysis`. Correctly scoped work with the issue number
  standing where the type belongs. Any conventional-commit parser discards it.
- **undeclared custom types — 12 commits.** `release(…)`, `license(…)`, `review(…)`, `fuzz(…)`,
  `revert(…)`, plus bare `Create …` / `Support …` / `Revert "…"`.

This is a convention defect, not an inference miss. The fix is `fix(GH-308): …` and a declared set of
custom types — not a parser that compensates forever.

## Lens 2 — recurring-defect radar

### Signal yield (measured, not assumed)

| Signal | State | Yield |
|---|---|---|
| 1. `related:` kinship | available | 220 docs carry the key, **337 references extracted**; 12 issues drew ≥2 *kinship* citations. Raw citation counts are misleading — #419 draws 18 and #308 draws 15, almost entirely as infrastructure context, not kinship. |
| 2. shared seam (`fix:` in window) | available | 96 `fix:` commits. After discarding ledger files touched by everything (`validate.sh`, `CHANGELOG.md`, `ROADMAP.md`, `ROADMAP-DASHBOARD.md`), five real seams clear the ≥2-days-AND-≥2-issues recurrence bar. |
| 3. issue-text similarity | available | **the decisive signal this run** — one class carries 11 open issues. |
| 4. doc-only closes | available, genuinely non-empty | #18 remains the confirmed instance (closed doc-only in 2h, 2026-06-24; re-fired at day 34 and day 44). 262 closed issues exist, so this is a real result rather than an absent signal. |
| 5. `reported_from:` | available | 7 docs. Feeds target 4. |
| 6. operational evidence | **structurally unavailable** | tooling repo — no runtime log tail that would show a class firing right now. Costs every target the "and it fired in N of the last M runs" escalation. |

**Doc-corpus size this run** (for drift comparison against later runs): 1-INBOX 33 · 2-WORKING 62 ·
3-COMPLETED 216 · 4-MISC 40. No lifecycle sweep occurred between run 2 and run 3, so citation deltas
are attributable to defect activity.

---

### 1. RADAR-class-silent-wrong-source — **NEW** · 9 open issues over 25 days · UNCLAIMED

**Class-shaped.** A root, path, lane, or configuration key is resolved from the wrong place and
returns a plausible wrong answer instead of failing. The defect is never in the logic downstream —
it is that the wrong input arrived silently.

| Issue | Filed | Milestone | Shape |
|---|---|---|---|
| #272 | 2026-07-21 | — | tick release resolves the wrong `TICK_REPO_ROOT`; review content never lands |
| #310 | 2026-07-27 | — | reviewer cites artifact-relative offsets as `file:line` |
| #314 | 2026-07-28 | — | `ensure_gitignore` never un-ignores; a pre-existing rule HALTs the run |
| #329 | 2026-07-29 | — | `/10days` bare `utils/` paths silently empty the fire list in a vendored install |
| #365 | 2026-07-30 | — | vendored copies carry no license text |
| #395 | 2026-08-01 | — | hardcoded local path shipped to main |
| #440 | 2026-08-07 | — | `ensure_gitignore` misses `/.tick/` |
| #504 | 2026-08-11 | — | `--target-root` separation never tested |
| #548 | 2026-08-15 | — | `smallcode-turn.sh` hardcodes an absolute machine-specific path |

Plus **#380** and **#491** (both Meter) and **#549**, closed today.

**The kinship is authored, not inferred.** `GH-343-GATE-PROGRAM-TARGET-ROOT.md` writes of #344:
*"the same class in the /10days skill: a root resolved from the wrong place, silently."*
`GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md` writes: *"#344 — /10days find-doc.sh read the wrong
repo's PROJECT/ tree; same skill, same class of silent wrong-source."*

**It fired twice today**, in GH-549: `core.hooksPath=githooks` resolved to a directory that does not
exist on branches predating the hook, so git ran no hook and warned about nothing; and the first fix
resolved the stub's destination with `git rev-parse --git-path hooks`, which **obeys the very
setting being migrated** and so pointed at the in-tree hook it delegates to. Both are this class
exactly. Neither was caught by review; the second was caught only by an exit code in the test.

**What one durable fix would retire:** a shared, tested resolution layer with a single rule —
*a resolver that cannot determine its answer raises; it never returns a default.* Nine issues plus
the two Meter members currently each carry their own ad-hoc resolution.

**Score:** 11 distinct issues × blast radius 9 (home repo + 8 vendored copies) ÷ median effort 2
≈ **49**. Highest this run by a wide margin.

**UNCLAIMED.** Nine of eleven belong to no milestone.

---

### 2. RADAR-ensure-gitignore — 3 issues over 51 days · first-seen: 2026-08-07 · **runs: 3** · REGRESSED

#18 (closed **doc-only in 2 hours**, 2026-06-24) → #314 (day 34, reported from 2 repos) → #440 (day 44).

**Movement since run 2, and it took the shape run 2 warned against.** Run 2's checklist read: fix
`ensure_gitignore()` *"as one seam, not two append paths."* Commit `b3e1e0a4` (2026-08-11,
`fix(GH-440): gitignore /.tick/ alongside .xyz/`) is **three insertions adding a second append
path**. The current function:

```bash
ensure_gitignore() {
  local gitignore="$TARGET_REPO/.gitignore"
  if [ ! -f "$gitignore" ]; then : > "$gitignore"; fi
  if ! grep -Fqx '.xyz/'  "$gitignore" 2>/dev/null; then printf '%s\n' '.xyz/'  >> "$gitignore"; fi
  if ! grep -Fqx '/.tick/' "$gitignore" 2>/dev/null; then printf '%s\n' '/.tick/' >> "$gitignore"; fi
}
```

It still cannot un-ignore anything, so **#314's direction is entirely absent**. No regression test
landed. **#440 is still open** despite carrying a fix commit.

**Not struck through**, and deliberately: a partial patch that names one issue is not a fix that
names the seam. Striking here would reset the aging clock on a defect that is 51 days old and now has
a fix commit making it *look* addressed — the worst of both states.

**Score:** 3 issues × blast radius 8 ÷ effort 1 × **1.5** (doc-only close in the chain) ≈ **36**.

---

### 3. RADAR-class-guards-cant-fail — **PROMOTED from context to live target** · claiming band SHIPPED

Parked in runs 1-2 as *"claimed by Litmus 0.2.0 — tracked there, aged here."* **Litmus shipped
today.** The claim expired without the class being retired.

Litmus's own manifest block states the limit plainly: it froze at **six** named decision gates
because *"every gate"* was unshippable prose — `gate_inventory.py` reports **152 of 158 gates with
no declared control**, and retrofitting them was explicitly out of scope. So 0.2.0 retired six
instances of a class with roughly 152 remaining.

**The class re-fired twice this week, outside that denominator:**

- `test/gh544-pre-push-gate.sh` reported **35 pass / 0 fail** against a `marathon-closeout.sh` branch
  that was **dead code under `set -euo pipefail`** — a failing `var="$(cmd)"` exits before
  `_checks_rc=$?`, so the entire no-checks path was unreachable. The harness `eval`'d the block
  without `set -e`, i.e. under gentler options than production. Found by a cross-model review.
- The same suite reported **38 pass / 0 fail** against a hook **git never dispatched to** (GH-549).
  Every case invoked the hook directly, which is precisely what the defect was invisible to. Found by
  dogfooding, then pinned by a real `git push` harness.

Kinship citations corroborate the class independently: `GH-348` on #342 — *"same shape: GH-281's test
extracted helpers from the Bash file, so it asserted a lane nobody runs"*; `GH-351` — *"the dashboard
test regenerates the artifact it then validates"*; `GH-369` on #351 — *"same family: an assertion that
cannot distinguish the bug from the fix."*

**What one durable fix would retire:** not another release band. A rule with teeth — *a suite must
execute the production entrypoint under production shell options, or declare in the baseline why it
cannot.* Both this week's instances violate exactly that, and both were invisible to a green suite.

**Score:** 4 kinship-linked issues + 2 fresh instances × blast radius 152 undeclared gates ÷ effort 3
≈ **high, but the denominator is the problem, not the numerator.** Ranked third only because targets
1 and 2 are actionable this week and this one needs an operator scope decision first.

---

### 4. RADAR-class-foreign-repo-field-gaps — first-seen: 2026-08-07 · **runs: 3** · partial movement

Run 2 members: #312 · #438 · #439. **#312 and #438 are now CLOSED.** #439 remains open and remains
unmilestoned. Overlaps target 1 (#314, #329, #365, #440 are both foreign-repo *and* silent-wrong-source);
the two are causally linked — vendored installs are where wrong-source resolution is *observed*, not
where it is *caused*. **Stated under both targets** so neither is struck through on the other's fix.

**Downgraded but not closed**: 2 of 3 original members resolved with citable commits, so the pressure
is genuinely lower. Its remaining substance is now largely carried by target 1.

---

## Lens 3 — release recalibration

`RELEASES.md` is real (not a seed). Shipped today: **Litmus 0.2.0**, **Nightwatch 0.3.0**.
Unshipped: **Plumbline** (Draft, 2026-11-14), **Lantern** (Draft, milestone not created), **Meter**
(Draft, 2027-01-16, manifest frozen at six).

**Orphan share: 88 of 104 open issues (84.6%) belong to no milestone.** Milestone distribution:
Nightwatch 8 · Meter 6 · Litmus 2 · none 88. Real bands exist, so this number is meaningful rather
than an artifact of a young repo.

**It is getting worse, and it is tracked by an issue that is itself unmilestoned.** #334 filed this
as *"41 of 42 open issues have no milestone — GH-284 Phase 4 is shipped but inert until releases have
scope."* That ratio was 97.6% of a 42-issue backlog; it is now 84.6% of a 104-issue backlog. The
share improved; the absolute count of unplanned work more than doubled.

**Does the plan still describe where effort goes?** Partly. Meter's description is a precise match for
target 1's cost profile — *"a run accounts for what it spends and checks what it requires before
spending it"* — and it already holds two of the eleven (#380, #491). The other nine sit outside every
band.

**Claim status of each target:**

| Target | Claimed by |
|---|---|
| 1. RADAR-class-silent-wrong-source | **UNCLAIMED** (2 of 11 in Meter) |
| 2. RADAR-ensure-gitignore | **UNCLAIMED** |
| 3. RADAR-class-guards-cant-fail | claiming band (Litmus) **SHIPPED without retiring it** |
| 4. RADAR-class-foreign-repo-field-gaps | **UNCLAIMED** |

Advisory only: the plan says Plumbline/Lantern/Meter; the repo is doing silent-wrong-source defects
and maintenance.

## Degradation applied

| Row | Cost to the verdict |
|---|---|
| Operational evidence (signal 6) absent | No target can be escalated from "N issues over M days" to "and it is firing right now." Tooling repo; no runtime log tail exists to grep. |
| `rgt:` adoption is 0 docs | Transform is structurally 0% and cannot move until the key is adopted. Reported as `0% (rgt: adoption: 0 docs)` rather than as a finding about the work. |
| Prior window 39.1% unclassified | The trend line is weak. The Run 54%→78% jump measures the commit convention at least as much as the work. |

No other rows applied: `gh` authenticated, `PROJECT/**` present, `RELEASES.md` real, 262 closed
issues, history well over two windows.

## Checklist at generation time

A historical snapshot. The live copy is [#444](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/444).

### RADAR-class-silent-wrong-source — 9 open issues over 25 days · first-seen: 2026-08-14 · runs: 1

- [ ] Inventory every ad-hoc root/path resolution across `utils/py/`, `relay-automation/`, and `skills/**` — the cluster's members each carry their own
- [ ] Build one shared resolver with the rule *a resolver that cannot determine its answer raises; it never returns a default* — `utils/py/` + its Bash twin, per the frozen-twin contract
- [ ] Add the negative control the class demands: each resolver observed returning a REFUSAL, not just a correct answer
- [ ] Route the nine unmilestoned members to a band (operator decision — Meter's description is the closest fit)
- [ ] Close members with the commit SHA naming the seam, not the issue

### RADAR-ensure-gitignore — 3 issues over 51 days · first-seen: 2026-08-07 · runs: 3

- [ ] Rewrite `ensure_gitignore()` (`relay-automation/xyz-vendor.sh`) as ONE seam handling both directions — append missing ignores (`/.tick/`, #440, partially done in `b3e1e0a4`) AND un-ignore required tracked paths (`phases/`, `relay-system/`, #314, **not started**)
- [ ] Wire the #314 failure into preflight + `--dry-run` naming all three blocked paths (cf. #117); explicitly not `git add -f`
- [ ] Add the regression test asserting BOTH directions on a fresh vendor into a repo with a pre-existing conflicting ignore rule — absent after `b3e1e0a4`
- [ ] Re-vendor the 8 affected copies; acceptance: clean `git status` after a driven relay in each
- [ ] Close #314 and #440 with the commit SHA; annotate #18 with the recurrence chain

### RADAR-class-guards-cant-fail — first-seen: 2026-08-07 · runs: 3 · promoted to live target

- [ ] Adopt the rule the two fresh instances both violated: a suite must execute the production entrypoint under production shell options, or declare in its baseline why it cannot
- [ ] Decide the scope of the 152 undeclared gates `gate_inventory.py` reports — a follow-up band, a sampling policy, or an explicit accept (operator decision; Litmus deliberately did not answer this)
- [ ] Sweep the suites that `eval`/`sed`-extract production blocks for the `set -e` false-green shape found in `test/gh544-pre-push-gate.sh`

### RADAR-class-foreign-repo-field-gaps — first-seen: 2026-08-07 · runs: 3 · downgraded

- [ ] Assign #439 to a band or close it (#312 and #438 closed since run 2)
- [ ] Add a "foreign-repo shakedown" case: vendor into a scratch repo with a hostile `.gitignore` + a linked worktree, run one driven relay, assert clean status and single-branch landing
