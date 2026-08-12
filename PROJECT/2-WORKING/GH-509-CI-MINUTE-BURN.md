---
gh_issue: 509
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509
title: "GH-509 — tier CI to stop per-push Actions minute burn"
status: Phase 1 shipped (PR #511) — replanned 2026-08-12 on the macOS-target reframe; Phases 2-5 authorised by the operator
created: 2026-08-11
updated: 2026-08-12
owner: noel
branch: feat/gh509-optimize-ci
doc_type: infrastructure
effort: 3
complexity: 3
risk: 3
phases: 5
ratings_provisional: false
roadmap_exempt: false
goal: >
  Spend CI minutes on the platform we ship to, make the developer's own Mac first-class evidence,
  and stop treating a Linux runner's opinion as breakage.
---

# GH-509 — tier CI to stop per-push Actions minute burn

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 (the docs/fast/full classifier for pull requests) shipped in PR #511. Replanned 2026-08-12 after the operator reframed the product: **XYZ is a local developer toolkit for Mac users.** That single fact deleted more of the previous plan than it added. | Phases 2-5 below, operator-directed. |

## The reframe that drives everything

**XYZ ships to macOS developers.** It is not a web service running on Linux boxes. Linux and Windows
support are on the roadmap and are not here yet; the Mac market is the target market today.

Everything below follows from that, and three things in the previous draft did not survive it.

### What the reframe deleted

**A cross-release blocker, gone.** The previous plan recorded a dependency — Meter could not claim
full-suite equivalence until Lantern discharged GH-358 Phase 2 — because `registry-lock-concurrency.sh`
is skipped as flaky. Its own skip comment says why:

> *flaky under CI load (16 concurrent tick writers → lock contention / lost row); **passes locally**,
> flaked 3 runs across PRs #257/#259*

It passes on the target platform. It fails on a contended shared Linux runner, a machine no user will
ever have. GH-358's 16-way concurrent-append flake is the same family and the same cause. **Neither is
a release blocker once we stop gating on Linux.** Confirmed by this repo's own runs on 2026-08-12:
local `validate.sh` is 190/190 *including* that suite.

**An equivalence contract, collapsed.** The previous plan spent a phase on making the hosted "full"
route provably identical to `validate.sh`, because the hosted route scrapes the Bash `TESTS` array and
therefore omits `test/test_python_layer.py` — 20 tests on the authoritative Python layer that have
**never run in CI**. On macOS the boundary job can simply invoke `RELAY_SELF_SUFFICIENCY_SKIP=1
./validate.sh` with **no skips at all**. There is no second list to keep honest, so there is nothing to
prove equivalent.

**An argument against local gates, withdrawn.** The previous plan argued local runs give false
confidence because local ≠ CI. That was only true while Linux was the reference. **The developer's Mac
*is* the shipping platform with the real toolchain**, which makes it the highest-fidelity test
available, not a lesser signal.

### What survived, with a better reason

On 2026-08-12 three suites passed locally and failed on Ubuntu because `codex`/`agy`/`aider` were not
installed (#520). Read as a Linux problem that is noise. Read correctly it is **"the test assumes the
operator's toolchain is already installed"** — just as true for a fresh Mac adopter, and exactly the
audience #380 describes: someone installing Claude Code specifically to run the swarm, with nothing
else on the machine yet.

Ubuntu was accidentally simulating an unconfigured Mac. We can do that deliberately, on a Mac, in
**~90 seconds** — that is how #520's control was recorded. We do not need a 12-minute Linux round trip
to learn it.

## Goals

1. Faster hosted CI, for cost and for timely review.
2. More strategic use of hosted CI.
3. Smarter use of CI generally — every trigger has a stated purpose.
4. Use local tests at gates and checkpoints.

Goal 4 was the contested one and the reframe settles it in its favour, with one caveat kept from the
previous draft: keep pre-push checks light for **ergonomic** reasons, because a 13-minute hook gets
`--no-verify`'d within a week. That is a statement about human behaviour, not about local fidelity.

## Measurement

Most recent 60 runs, 2026-08-11T05:00 → 2026-08-12T05:30 (~24.5 h). Single-job workflow, so per-run ≈
per-job billing:

| Event | Runs | Avg | Billed (ceil) | Share |
|---|---|---|---|---|
| `push` → `development` | 37 | 10.1 min | ~396 min | **72%** |
| `pull_request` | 23 | 6.1 min | ~155 min | 28% |

Phase 1 cut the PR average from ~16 min to 6.1 — it worked, and it worked on the 28%. **All 37 push
runs were on `development`, every one on the full route; zero pushes to `main`.** Caveat: one heavy
session-day, not a steady state, and the PR figure mixes routes and cancellations.

**Why this matters more after the reframe.** Hosted macOS runners bill at roughly **10× Linux**
(confirm against current pricing before relying on the figure). At today's volume, macOS-everywhere is
on the order of thousands of dollars a month. Routing is not a nice-to-have; it is the precondition
for having any honest hosted evidence at all.

And the boundary is cheap *because* it is rare: at ~12 minutes and 10×, one qualifying run costs well
under a dollar, a handful of times a month.

## Decision

### 1. Ubuntu is an advisory portability canary

It keeps running, at 1×, because Linux support is on the roadmap and this is the cheapest early
warning of portability drift we will get. It **never gates, never blocks, and its red is never
reported as breakage** — its failure means "portability drift", not "broken".

The alternative considered and rejected was deleting Linux CI entirely. A canary that cannot cry wolf
earns its minutes; one that cried wolf for five unread hours on 2026-08-12 is worse than none. Stripping
it to advisory is what makes the difference.

### 2. Hosted macOS runs at the promotion boundary only

| Trigger | Runner | Route |
|---|---|---|
| PR, docs/PDDA-only | ubuntu (advisory) | `docs` |
| PR, ordinary code | ubuntu (advisory) | `fast` |
| PR, critical surface | ubuntu (advisory) | `full` |
| push → `development` | ubuntu (advisory) | **classified from the pushed range**, docs/fast/full |
| push → `main` | **macOS** | full, no skips |
| `workflow_dispatch` at a chosen SHA | **macOS** | full, no skips |

**`workflow_dispatch` is the trigger that will actually get used.** Work lands on `development` and
`main` sees almost nothing, so a `main`-only macOS gate would always arrive after the promotion
decision rather than before it. The manual trigger is how a `development` commit gets qualified without
being merged first.

PRs get no macOS by default. Local covers them, and per-PR macOS would restore the original spend at
ten times the rate.

### 3. Route `development` pushes

Same classifier as pull requests, applied to the whole pushed range (`before..sha`). This is where the
72% is. An empty or unreadable range fails closed to full.

Accepted trade-off, stated plainly: an interaction between two separately fast-safe changes can go
undetected until a qualifying run. That is what §4 exists to bound.

### 4. Preserve per-SHA evidence when routing pushes

All `development` pushes currently share one concurrency group with `cancel-in-progress: true`. Once
routed, a 90-second `docs` run would **cancel a running `full`**, and "is this commit proven?" would
answer *no* for a commit that was never broken. Three of the last fourteen `development` runs are
already `cancelled`; today it is invisible because a cancelled full is replaced by another full.

The obvious fix — adding the route to the workflow-level `concurrency` key — **is not implementable**:
workflow-level concurrency is evaluated before any job runs and cannot read a job output. Job-level
`concurrency` *can* reference `needs.<job>.outputs.*`. So: a small non-cancelling classifier job, then
route-scoped job-level groups.

- `docs` supersedes only `docs` on the same branch; `fast` only `fast`;
- `full` supersedes only a newer `full` on the same branch — adjudicated toward cost, since a
  superseded commit can be re-qualified on demand via `workflow_dispatch`;
- **`docs` and `fast` must never cancel a running `full`**;
- `workflow_dispatch` stays in its own lane and is never cancelled by a push.

**Cost of this fix, stated because GH-509 warns about exactly it** (*"per-job rounding can increase
billed usage"*): splitting out the classifier bills two jobs per run instead of one, and a ~10-second
job still rounds to a minute. At ~60 runs/day that is roughly **+60 billed min/day** against the ~396
the routing removes. Net strongly positive — but it belongs in the measurement, not absorbed quietly.

### 5. Local Mac testing becomes first-class

Four changes, in value order:

1. **A durable per-commit record of local runs.** This is the unlock. If the Mac is the evidence, "I
   ran it and it was green" cannot live in a chat message — it must be a record keyed to the commit
   hash, refused from a dirty tree, so the promotion check has something to read.
2. **A fast local mode.** `utils/ci-route.sh` already exists and is tested 15/15, and has never been
   pointed at a local diff. Same classifier, working-tree changes, seconds.
3. **An unconfigured-Mac probe as a named mode.** The stripped-`PATH` check that caught all three of
   #520's failures in ~90 seconds currently exists only as a throwaway script. It simulates #380's
   new-adopter story and belongs in the tree.
4. **Tiering:** fast on every push, the probe before anything user-facing, full `validate.sh` at
   checkpoints.

**The honest limit:** a local record is self-reported. Keying it to the commit and refusing a dirty
tree covers most of it, but it proves *someone ran this*, not *someone ran this honestly*. That gap is
precisely what the rare hosted macOS run buys — a clean machine, and evidence not produced by the
person making the claim.

### 6. The promotion rule

> **No commit is promoted from `development` unless that exact commit has a green macOS full result —
> hosted, or locally recorded per §5.1.**

Ubuntu green proves nothing about what we ship and does not satisfy this.

### 7. The detector must be readable

Nothing can be a required check on this plan (`gh api .../branches/development/protection` →
`403: Upgrade to GitHub Pro or make this repository public`), and PR #511 merged with `tier1=FAILURE`
because nothing could stop it. So the operator surface reports structured status with **distance**:

```
development HEAD <sha>; last green macOS full <sha>, <distance> commits / <age>; status: exact | behind | red | none
```

`behind` is normal WIP information. `exact` is promotion-qualified. `red` and `none` are explicit *not
promotable*. A bare `MISMATCH` trains people to ignore the one signal this section protects — which is
how five hours of red went unread.

**Out of scope here, but worth naming:** required checks cost roughly $4/month (GitHub Pro) or making
the repo public. That buys something no amount of routing can.

## Phases

| # | Phase | Contents |
|---|---|---|
| 1 | PR classifier | **SHIPPED** (PR #511) |
| 2 | Ubuntu → advisory | non-blocking job, red reported as portability drift, not breakage |
| 3 | Route `development` pushes | classifier job + route-scoped job-level concurrency (§3, §4) |
| 4 | macOS boundary job | `main` + `workflow_dispatch`, `validate.sh` direct, no skips |
| 5 | Local evidence | recorded per-commit result, fast mode, unconfigured-Mac probe (§5) |

Phases 2-4 are independent. Phase 5 is the highest value and the only one that changes daily practice.

**Scope note.** This work is **operator-directed 2026-08-12** and is deliberately **not** admitted to a
frozen release manifest — it is repo infrastructure, and the frozen-manifest rule governs release
scope. If it should count toward Meter (0.6.0), that is a one-line re-scope for the operator to make
explicitly rather than something this document assumes.

## Acceptance

Phase 1 (shipped):

- [x] Superseded PR runs use branch-scoped concurrency cancellation.
- [x] Docs-only changes skip the runtime regression suite without skipping the required job.
- [x] Critical surfaces select a pre-merge full gate.
- [x] The fast-route whole-job budget is documented as under three minutes.
- [x] No daily full-suite burn is added.
- [x] Before/after minute sample recorded (60-run sample above).

Phases 2-5:

- [ ] A Ubuntu failure is reported as advisory and cannot mark a run as breakage.
- [ ] `development` pushes are routed; an empty/unreadable range fails closed to full.
- [ ] A `docs` or `fast` run cannot cancel a running `full`, proven by a witnessed control.
- [ ] A renamed regression test selects `full`, proven by a witnessed control (`git diff --name-only`
      cannot support this — the classifier needs `--no-renames` or status-aware input).
- [ ] The macOS boundary job invokes `validate.sh` directly with no skip list.
- [ ] A green hosted **macOS** full run exists for a chosen commit.
- [ ] A local full run writes a durable record keyed to the commit and refuses a dirty tree.
- [ ] The operator surface reports distance-based status.
- [ ] ~~Verify required-check behaviour~~ — **struck as unsatisfiable**: no branch protection exists on
      this plan. Replaced by the operator surface.

## Validation

| Check | Result |
|---|---|
| `bash test/ci-route.sh` | PASS — 15/15 *(does not yet cover rename or local-diff mode)* |
| `bash test/ci-workflow.sh` | PASS — 22/22 *(does not yet cover advisory/macOS/route-scoped concurrency)* |
| `RELAY_SELF_SUFFICIENCY_SKIP=1 ./validate.sh` | PASS locally — 190/190 including 20/20 Python **and** `registry-lock-concurrency.sh`, the suite Ubuntu CI skips |
| Hosted `full` | Never observed green on the new workflow. #511 merged with `tier1=FAILURE`; that red was `gh514`/`gh388` (#520, fixed at `6ae068b8`) and was unrelated to routing. |

## Provenance

Adjudicated 2026-08-12 across two models via agent2agent **#987467** (Claude Opus 5 / Codex, four
turns, closed). Codex contributed the promotion invariant, the direct-validator contract, the
reduced-route naming, and the correction that workflow-level concurrency cannot read a job output.
Claude contributed the three verified defects with reproductions, the cancellation defect, the
`pdda-repo-contract.sh` inversion, the per-job rounding cost, and the measurement. Each rejected one of
the other's proposals — a nightly full run (Claude's, withdrawn) and a workflow-level concurrency key
(Claude's, shown unimplementable).

The operator's macOS-target reframe then deleted the blocker, the equivalence phase, and the
anti-local-gate argument that both models had agreed on. Recorded because two models concurring is not
evidence when they share a false premise.
