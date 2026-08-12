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

**agy pushed back on the justification, and was right to.** The previous draft claimed that stripping
the canary to advisory *prevents* it being ignored. That is backwards: a non-blocking job is if
anything **more** likely to be ignored, because nothing forces anyone to look. "Advisory" describes
what its red means; it supplies no reason for anyone to read it.

So the mechanism is named instead of assumed: **the canary's status is a line in the promotion output
(§7), and a promotion with unresolved drift must name it.** That is the only reliable way to get
something read — attach it to a moment when a human is already looking and already deciding. A
continuously-emitted advisory nobody is obliged to consult is exactly the five unread hours of
2026-08-12, repeated more cheaply.

The alternative considered and rejected was deleting Linux CI entirely. That stays on the table: if a
promotion ever ships with drift named and unresolved twice running, the canary has proven it is not
being actioned, and it should be deleted rather than kept as decoration.

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

### 4. Concurrency stays exactly as it is — DELETED, and this is the fourth thing the reframe should have killed

The previous draft spent a section here, and a phase, on route-scoped job-level concurrency: a
non-cancelling classifier job so that a 90-second `docs` push could not cancel a running `full` on
`development`. It cost **+60 billed min/day** in per-job rounding, and it was written to protect
per-commit evidence.

**agy killed it on review, correctly.** `development` pushes run on **Ubuntu**, and §1 just made Ubuntu
advisory. Protecting the per-commit evidence of a signal that never gates anything, at extra cost, is
ceremony by this document's own definition. The cancellation defect was real *when it was found* — the
plan then still treated `development` full runs as meaningful. The reframe removed the meaning and the
fix outlived its reason.

The one thing that does need protection is already protected: `workflow_dispatch` and `push` are
distinct `github.event_name` values and the existing group keys on it, so **a push cannot cancel a
macOS boundary run today.** Verified against the current `concurrency:` block.

So: keep the existing workflow-level group, let pushes cancel pushes, and **delete the classifier-job
split along with its +60 min/day.** Routing `development` pushes (§3) gets simpler *and* cheaper than
the previous draft claimed.

*Kept as a hazard note rather than a design:* if `development` runs are ever promoted back to gating,
this defect returns, and the workflow-level `concurrency` key cannot fix it — that key is evaluated
before any job runs and cannot read a job output. Only job-level `concurrency` can reference
`needs.<job>.outputs.*`.

### 5. Local Mac testing becomes first-class

**`ci-local.sh` already existed** — a full local mirror of the hosted job with a `--fast` mode — and
was found mid-implementation rather than planned for. It carried the reframe's error in miniature: it
mirrored the hosted job's skip list, so it **skipped `registry-lock-concurrency.sh`**, a suite the
workflow's own comment says *"passes locally"*. Local was discarding real macOS signal to stay faithful
to a contended Linux runner, and `test/ci-workflow.sh` actively pinned it that way.

**Inverted `2026-08-12`.** `ci-local.sh` now runs a **superset** of the hosted job; the only surviving
skip is `acorn-extract.sh`, which is duplicate work rather than dropped coverage. The pinning assertion
was inverted with it — local skipping that suite is now a **failure**, witnessed red. Its closing
notice was re-pointed too: the useful caveat is no longer "this is not a green ubuntu run" but "this is
**self-reported** and does not qualify a promotion".

What remains, in value order:

1. **A durable per-commit record of local runs.** This is the unlock. If the Mac is the evidence, "I
   ran it and it was green" cannot live in a chat message — it must be a record keyed to the commit
   hash, refused from a dirty tree, so the promotion check has something to read.
2. **An unconfigured-Mac probe as a named mode.** The stripped-`PATH` check that caught all three of
   #520's failures in ~90 seconds currently exists only as a throwaway script. It simulates #380's
   new-adopter story and belongs in the tree.
3. **Tiering:** `ci-local.sh --fast` on every push, the probe before anything user-facing, full
   `validate.sh` at checkpoints.

**The honest limit:** a local record is self-reported. Keying it to the commit and refusing a dirty
tree covers most of it, but it proves *someone ran this*, not *someone ran this honestly*. That gap is
precisely what the rare hosted macOS run buys — a clean machine, and evidence not produced by the
person making the claim.

### 6. The promotion rule

> **No commit is promoted from `development` unless that exact commit has a green *hosted* macOS full
> result** — `push` to `main` or `workflow_dispatch`.

Ubuntu green proves nothing about what we ship and does not satisfy this. **Neither does a local
record** — and the previous draft's "hosted, *or* locally recorded" was circular, caught by agy on
review: if a self-reported record satisfies the boundary, the boundary is optional and buys exactly
nothing. The whole reason the rare 10× run exists is that it supplies a clean machine and evidence not
produced by the person making the claim.

Local records (§5.1) remain first-class for everything short of promotion — day-to-day work, PRs, and
`development` — which is where they carry their weight.

### 7. The detector must be readable

Nothing can be a required check on this plan (`gh api .../branches/development/protection` →
`403: Upgrade to GitHub Pro or make this repository public`), and PR #511 merged with `tier1=FAILURE`
because nothing could stop it. So the operator surface reports structured status with **distance**:

```
development HEAD <sha>; last green macOS full <sha>, <distance> commits / <age>; status: exact | behind | red | none
portability canary (ubuntu): green | drift since <sha> (<n> runs)
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
| 2 | Ubuntu → advisory | **SHIPPED** `bc2e1d1d` — `canary-ubuntu`, `continue-on-error: true`, `if: always()` verdict step; contract test 26→30 with both assertions witnessed red |
| 3 | Route `development` pushes | classifier applied to `before..sha`; **existing concurrency untouched** (§3, §4) |
| 4 | macOS boundary job | **SHIPPED** — `boundary-macos` on `macos-latest`, `main` + `workflow_dispatch`, `./validate.sh` direct, no skip list, 45-min bound, prints its resolved SHA. Four assertions, four witnessed controls |
| 5 | Local evidence | recorded per-commit result, fast mode, unconfigured-Mac probe (§5) |

Phases 2-4 are independent. Phase 5 is the highest value and the only one that changes daily practice.

Phase 3 is **smaller and cheaper than the previous draft**: agy's review deleted the classifier-job
split and the route-scoped concurrency it existed to enable, taking the +60 billed min/day with it.

**Scope note.** Operator-directed 2026-08-12, and **admitted to Meter (0.6.0)** the same day by explicit
operator decision — recorded in `RELEASES.md` as a dated re-scope from five entries to six, not as a
list that quietly grew. It is a real thematic fit: what a run costs, and what it checks before spending.

## Acceptance

Phase 1 (shipped):

- [x] Superseded PR runs use branch-scoped concurrency cancellation.
- [x] Docs-only changes skip the runtime regression suite without skipping the required job.
- [x] Critical surfaces select a pre-merge full gate.
- [x] The fast-route whole-job budget is documented as under three minutes.
- [x] No daily full-suite burn is added.
- [x] Before/after minute sample recorded (60-run sample above).

Phases 2-5:

- [x] A Ubuntu failure is reported as advisory and cannot mark a run as breakage. *(Declared and
      asserted at `bc2e1d1d`; the **runtime** half is still open — it needs a witnessed hosted run,
      since a grep cannot prove GitHub's `continue-on-error` semantics.)*
- [x] The local runner stops imitating Linux: `ci-local.sh` runs a superset of the hosted job, and the
      assertion that pinned them together is inverted and witnessed red.
- [ ] Unresolved portability drift appears in the promotion output — the mechanism that makes the
      advisory canary *read* rather than merely non-blocking.
- [ ] `development` pushes are routed; an empty/unreadable range fails closed to full.
- [ ] A renamed regression test selects `full`, proven by a witnessed control (`git diff --name-only`
      cannot support this — the classifier needs `--no-renames` or status-aware input).
- [x] The macOS boundary job invokes `validate.sh` directly with no skip list. *(Declared and asserted; `test/baselines/GH-509-phase4-negative-control.md`. This also closes **D1** — the 20-test authoritative Python layer now runs at the boundary, having never run in CI before.)*
- [ ] A `push` cannot cancel a running `workflow_dispatch` boundary run. *(Believed already true —
      `github.event_name` is in the existing concurrency key. Needs a witnessed control, not an
      assertion.)*
- [ ] A green hosted **macOS** full run exists for a chosen commit.
- [ ] A local full run writes a durable record keyed to the commit and refuses a dirty tree.
- [ ] The operator surface reports distance-based status, including the canary line.
- [ ] ~~A `docs`/`fast` run cannot cancel a running `full`~~ — **struck 2026-08-12 on agy's review.**
      `development` runs on advisory Ubuntu; preserving per-commit evidence for a signal that never
      gates is ceremony. Returns only if `development` runs are ever promoted back to gating.
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

A third model reviewed the replan — **agy**, via the shipped relay harness
(`relay-system/2026-08-12/gh509-ci-strategy-macos-review.md`, `--review-once`, verdict *Changes
requested*). It was asked to find the fourth thing the reframe should have deleted and did:

- **[Blocker]** the promotion rule was **circular** — "hosted, *or* locally recorded" let self-reported
  evidence satisfy the boundary whose entire purpose is independent evidence. Accepted; §6 now requires
  a hosted run.
- **[Should]** the route-scoped concurrency design was **ceremony** — it protected per-commit evidence
  for `development`, which the same document had just made advisory. Accepted; §4 and the +60 min/day
  classifier split are deleted, and the plan got cheaper as a result.
- **[Should]** the advisory-canary justification was **sociologically backwards** — non-blocking jobs
  are *more* ignorable, not less. Accepted with a modification: rather than delete the canary (the
  operator had already chosen to keep it), its status is now attached to the promotion output, which is
  the only moment a human is reliably reading.
- **[Pass]** the macOS boundary trigger, cited.

Worth noting which model caught what: the two that co-authored the plan both missed the ceremony in
their own design, and the one that had not seen it built found it first.
