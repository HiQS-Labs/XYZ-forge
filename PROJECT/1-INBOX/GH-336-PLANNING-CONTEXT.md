---
gh_issue: 336
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/336
title: "Planning context: phase metadata signals before deterministic marathon contracts"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-29
revised: 2026-07-30
doc_type: feedback
related: GH-334, GH-308, GH-284, GH-340, GH-348
effort: 3
complexity: 3
risk: 2
phases: 3
goal: >
  Improve marathon planning with evidence-backed release alignment, delivery-arc, issue-theme, and
  sub-module churn context, while preserving current execution safety and avoiding premature process
  overhead.
---

# GH-336 · planning context

> **Revision note (2026-07-29).** This doc has been through a four-round, three-model review in
> [relay-system/2026-07-29/gh336-planning-context-review.md](../../relay-system/2026-07-29/gh336-planning-context-review.md):
> **codex** r1 (2 Blockers / 4 Shoulds), **agy** r2–r3 (3 Shoulds, then Approved), **pi +
> qwen3.8-max-preview** r4 (5 Shoulds / 2 Nits, escalated at the round cap). Every judgement call is
> tie-broken against [GUIDING-PRINCIPLES.md](../../GUIDING-PRINCIPLES.md), cited inline as `(P<n>)`.
>
> **Second revision note (2026-07-30) — the base moved underneath the review.** All four rounds verified
> against `c6b98c2`; `development` advanced 6 commits while they ran, and two of those commits changed
> facts this plan depends on. Both are now corrected here:
> **(a)** `utils/release-lanes.sh` **exists** as of #330 — the round-1 Blocker was *premature*, not wrong,
> and Phase 1 now consumes the script instead of re-deriving release scope, which removes most of that
> signal's work. **(b)** `utils/py/_marathon_plan_node.js` was **deleted** by #340 in favor of a native
> Python engine, and #366 (GH-362) then retired marathon-plan's dual-maintenance exception entirely —
> `utils/marathon-plan.sh` is now the **12th frozen twin**, with Python authoritative. The
> "triple-maintained" argument is retired; the decision is unchanged and now rests on the simplest
> ground available.
>
> Round 4 was charged with finding what two models that had already agreed **both missed**, and it did.
> Two claims in the r3-Approved version were **factually wrong** and are corrected below: the kill-switch
> criterion asserted zero `gh` calls in `off` mode (the *base planner* calls `gh` regardless), and the
> churn threshold of "3 or more" was uncalibrated by an order of magnitude against this repo's measured
> commit volume. The architecture survived all four rounds unchanged; the defects were in the criteria
> that were supposed to *prove* the safety claims.

## Why now

The existing planner safely sequences individually valid issues, but it does not yet connect a run
to `RELEASES.md`/its GitHub milestone, summarize recently shipped direction, cluster related survivor
issues, or show evidence that one sub-module is receiving repeated local repairs. That can maximize
ticket throughput while obscuring release alignment and a likely refactor boundary.

`RELEASES.md` already carries `Milestone:` as the release → issue-set join key (GH-284 Phase 3), and
the `Quicksilver` block is populated. That is the one signal with real data on day one, and it needs
no new hygiene from the operator.

## Bet, tradeoff, and blast radius

**Bet:** an advisory, receipt-backed planning overlay will expose better grouping and refactor choices
before the harness needs new execution controls.

**Tradeoff:** Phase 1 accepts bounded inference and requires operators to review it; Phase 2 is
allowed only if the recorded evidence table below proves a small deterministic contract would prevent
a material planning mistake.

**Failure mode:** analysis silently changes scheduling or `/10days` auto-fire behavior. Phase 1 must
prove it cannot affect inclusion, scoring, waves, allowlists, preflight verdicts, or firing.

**Reversibility.** Made structural, not aspirational (P6, P8). Three layers, in increasing strength:

1. `off` is both the kill switch **and the default** — no sidecar written, no overlay `gh` call.
2. The overlay writes a **separate sidecar file** and never mutates the plan doc, so "the plan doc is
   byte-identical in every mode" is true *by construction*, not by test.
3. The Bash lane is never taught this feature, so `XYZ_PYTHON=0` remains a permanent second reference
   implementation of "feature off" — the parity oracle comes for free rather than being maintained.

A clean-room rewrite is a one-way-door decision and always requires an explicit operator GO.

## Architecture decision: Python-only, standalone module

**Decided:** the overlay ships as a new `utils/py/planning_context.py`, called only from
`utils/py/marathon_plan.py`. It does **not** touch `utils/marathon-plan.sh` or its embedded JS engine.

Why this is the only defensible seam (P7 *least code that clears the bar*, P6 *durable not band-aid*):

- Python is authoritative for Tier-A entry points (GH-308, [AGENTS.md](../../AGENTS.md)), and the
  operator's standing rule is Python-only wherever possible.
- **`utils/marathon-plan.sh` is a frozen twin (GH-362), and Python is authoritative.** It used to be
  GH-308's one dual-maintained exception; GH-340 deleted the copied Node renderer and made the Python
  lane native, so the exception outlived its reason and marathon-plan became the **12th frozen twin**.
  Editing it now requires a `Frozen-twin-exception:` trailer naming the file.
- A standalone module needs neither engine changed: it writes a sidecar beside an already-rendered plan.
  No trailer, no second implementation, nothing to keep in step.

> **Note on the reasoning, not the decision.** This rationale has now been rewritten three times as the
> ground moved — first "the render path is triple-maintained" (true until GH-340 deleted the copy), then
> "dual-maintained with no drift guard" (true until GH-362 retired the exception), now simply
> "Python is authoritative and the Bash twin is frozen." **The decision has survived every one of those
> changes unchanged**, because it never actually depended on the policy: an additive sidecar avoids the
> render path under any maintenance regime. If the policy shifts a fourth time, re-check this paragraph
> — not the decision.

**Consequence to accept explicitly:** under `XYZ_PYTHON=0` the overlay is simply absent. That is the
intended behavior, not a gap.

## Table of contents

- [Phase 0 — correct the record (prerequisite)](#phase-0--correct-the-record-prerequisite)
- [Phase 1 — advisory planning context](#phase-1--advisory-planning-context)
- [Phase 2 — minimal deterministic contracts](#phase-2--minimal-deterministic-contracts)
- [Phase 2 promotion evidence](#phase-2-promotion-evidence)
- [Non-goals](#non-goals)
- [Open questions for the operator](#open-questions-for-the-operator)

## Phase 0 — correct the record (prerequisite)

Small, doc-only, and blocking — the original draft rested on a source that does not exist
(Codex Blocker 1). No code.

- [x] ~~Delete the claim that this proposal consumes an existing `utils/release-lanes.sh seed|rollup`
      foundation.~~ **Reversed 2026-07-30 — the claim was premature, not false.** It was correct that no
      such file existed when this doc was written and when round 1 reviewed it. #330 (GH-284 Phase 4)
      then landed `utils/release-lanes.sh` on `development` with exactly those `seed`/`rollup` verbs.
      Verified here: `bash test/gh284-p4-release-lanes.sh` → **38 pass / 0 fail**, and
      `utils/release-lanes.sh rollup --milestone Quicksilver` runs live, reporting `2/2 landed on
      origin/main` with per-issue evidence. **The claim is restored, and Phase 1 now consumes the
      script rather than re-deriving release scope** — see the release-alignment signal below.
- ~~Delete the `Release: 0.1.0` EXAMPLE block from `RELEASES.md`.~~ **Removed from scope.** The
      original justification — that release selection "would otherwise have to special-case" it — was
      wrong: the stated selection rule already skips any block whose `Milestone:` is empty, and that
      block's is empty. Nothing here needs it gone. It is expired hygiene (its own `Description` says
      to delete it "once real entries exist below," and `Quicksilver` now exists), but it is unrelated
      to GH-336 and belongs in a separate trivial doc fix. **GH-336 stays read-only against
      `RELEASES.md`.**
- [ ] Resolve the dangling `related: GH-334` reference: either land a `PROJECT/**` pointer doc and a
      `ROADMAP.md` line for it, or drop the cross-reference. It currently has neither, so a cold
      agent cannot read it (P9 — *if reality and the docs disagree, the docs are the bug*).

### Acceptance criteria

- Every `utils/release-lanes.sh` reference in this doc points at the real script and its real verbs
  (`seed`, `rollup`) — no reference claims it is absent.
- `utils/pdda/pdda.sh run` is green, including link checks (no dangling `GH-334` pointer).

## Phase 1 — advisory planning context

A read-only synthesis written to a **sidecar file** —
`PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.context.md` — beside the generated plan doc, which is
**never modified**. Every claim carries its source and the analysis window; every synthesis is labelled
inference, not fact (the *Attested* pillar).

**Why a sidecar and not a section appended to the plan doc.** The round-4 pass found that
`marathon_plan.py --check` re-renders the plan with the *default* mode and `cmp`s the result against the
committed doc ([marathon_plan.py:378-391](../../utils/py/marathon_plan.py#L378)). A plan written under
`auto`/`on` and later checked under default `off` would therefore report **drift that is not real**.
A sidecar removes that interaction entirely and buys two more things: "the plan doc is byte-identical
in every mode" becomes true *by construction* rather than by test, and the removal seam sharpens to one
deletable artifact. (The hazard is currently latent — `validate.sh` does not yet wire `--check` — but
designing around a trap that is already documented is cheaper than remembering it later.)

**Row format (pinned, so two builders cannot diverge).** The sidecar body is one Markdown table per
signal, each with exactly these columns:

| Claim | Kind | Source | Window |
|---|---|---|---|
| the statement | `fact` or `inference` | a `file:line`, `gh` query, or commit/PR ref | the analysis window |

`Kind` is what makes the *Attested* pillar checkable rather than stylistic: a synthesis that forgets to
label itself `inference` fails the receipts test below.

### Activation — three modes, default `off`

`utils/py/marathon_plan.py --planning-context=off|auto|on` (default **`off`**):

| Mode | Behavior |
|---|---|
| `off` | **Default.** Hard kill switch. No sidecar is written at all. **Zero overlay `gh` calls** (see the precise wording below — the *base planner* has its own, unrelated `gh` path). |
| `auto` | Opt-in. Activates only when preconditions hold; otherwise writes no sidecar, exactly as `off`. |
| `on` | Forced. If **any** precondition fails — no release resolves, several resolve without `--release`, or `gh` is unreachable — still generates the plan, exits 0, and prints the specific reason to stderr instead of passing through silently (P8 — *honest*). |

**Why `off` and not `auto` is the default.** The first draft of this revision defaulted to `auto`; the
round-2 QA pass rejected that on P1 grounds and was right. `auto` still has to *ask* whether a release
resolves and whether `gh` is reachable, so it puts an outward reach on **every ordinary planning run** —
precisely what P1 forbids (*a coordination primitive that reaches out is a coordination primitive that
can fail or leak*). Defaulting `off` means the reach happens only when an operator asks for it. It also
makes the reversibility claim trivially true rather than argued: the default path never had the feature
on.

**Day-one usability is unaffected.** `off` → `auto` is one flag on one command, and `/10days` may pass
`--planning-context=auto` explicitly for its **report** step (it already depends on `gh` for the sweep
itself, so this adds no new reach) — but only after its fire list is frozen.

**The `/10days` hook is a documentation change, not a code path.** `/10days` is a prose skill, not an
executable, so there is nothing to "dry-run." Making it surface the sidecar means one instruction in
`skills/10days/SKILL.md` placed after its Step 6 (fire list frozen) and before its Step 8 (report). That
file is therefore part of the removal seam and part of the no-parser grep scope — see both below. This
replaces a round-3 criterion that assumed a `/10days` binary existed.

**Preconditions for `auto` to activate:** exactly one selectable release resolves *and* `gh` is
reachable. This is the operator's "feature-not-activated → pass-through" gate, and it is what keeps
Phase 1 useful without contracts: with no release hygiene the overlay is simply absent rather than a
screen of `unresolved` (Codex Should, Q1).

**Release selection.** Read `RELEASES.md` blocks; skip any block whose `Milestone:` is empty. Exactly
one remaining block → select it. Several → require `--release <codename>`; without it, pass through.
None → pass through.

**`gh` failure is never load-bearing.** P1 is explicit that *a coordination primitive that reaches out
is a coordination primitive that can fail or leak*. On any `gh` failure, timeout, or offline state the
overlay writes no sidecar, the plan still generates, and the exit code is unchanged. It never fails a
run. The overlay's `gh` calls are read-only, bounded to a fixed budget, and **never** issued on any path
that decides what fires.

**Correction — the overlay is *not* the only `gh` reach in this program, and the earlier draft said so
wrongly.** The base planner already shells out to `gh` in its ordinary render path (`gh auth status`,
then `gh issue view <n>` per issue), suppressed only by a forced-off flag or a stub state file. That
behavior was first found in the old copied Node renderer; GH-340 deleted that file and ported the engine
natively, and it still holds — see `_gh_state()` and the `GH_MODE` resolution in
[utils/py/_marathon_plan.py](../../utils/py/_marathon_plan.py). Two consequences, both load-bearing:

- Every claim in this doc about `gh` calls is scoped to **overlay** calls (`gh issue list --milestone`).
  "`off` makes zero `gh` calls" was false as written and is now stated correctly above.
- Any test asserting "no `gh` call" must run under the existing hermetic seam (`QP_GH_STATE_FILE` /
  `QUEUE_PLAN_GH_STATE_FILE`, the same one [test/marathon-plan.sh](../../test/marathon-plan.sh) already
  uses), or the base planner trips the assertion before the overlay is ever reached.

### The three signals

- **Release alignment** — **delegated to `utils/release-lanes.sh`, not re-implemented.** `seed
  --milestone <title>` gives the in-scope open issues (JSON-lines, same six keys and sort as
  `skills/10days/scan-issues.sh`); `rollup --milestone <title>` gives per-issue
  `landed`/`mentioned`/`absent` against the derived trunk plus an `N/M landed` headline. The overlay
  selects the release from `RELEASES.md`, calls those two verbs, and formats the result. It issues **no
  `gh` query of its own** — which is why this signal makes no new outward reach beyond what
  `release-lanes.sh` already does, and why its `exit 3` (unresolvable milestone) / `exit 4` (empty
  milestone) map cleanly onto pass-through. Membership stays *asked of GitHub*, never inferred.
- **Delivery arc** — merged PR and commit receipts in the window, plus a clearly labelled inference
  about the direction they represent.
- **Churn signals** — sub-modules whose recent activity is **unusual for that sub-module**, with the
  ratio, the baseline it was measured against, linked issues/PRs, and a bounded recommendation.

**Issue themes: deferred out of Phase 1.** Both review rounds independently graded it the weakest of
the original four — no taxonomy exists, creating one is a standing non-goal, and clustering without one
is low-confidence by construction. Shipping it would trade against the *Relevant* pillar (*volume is
not value*) and against the very "worthwhile" bar this phase is being held to. It is not being
redesigned here; it is simply out of scope until a real run shows the other three signals left a
grouping decision unanswered.

**Churn rules — relative to a trailing baseline, not an absolute count.**

The operator's original instinct was a flat "3 or more," and it was reasonable in the abstract. Real
measurement killed it. Over the trailing 14 days this repo shows **538 commits**, with `utils/py/` at
**40** distinct commits and `relay-automation/` at **59**. Any absolute ladder topping out near 8 puts
the primary code directories permanently at "consider bounded refactor" — a signal that fires every run
forever, which is how an operator learns to ignore a signal. Worse, `utils/py/`'s current churn *is* the
GH-308 Bash phase-out under the `Quicksilver` milestone, so an absolute rule would flag precisely the
directed, release-aligned work the release-alignment signal already reports — double-reporting known
work as if it were a discovery.

- **Recurrence unit:** directory at depth 2 (`utils/py/`, `relay-automation/`), counted in **distinct
  commits**.
- **Signal condition:** the window's commit count for that directory divided by its **trailing 90-day
  median for an equal-length window** — the ratio, not the count, is the signal. Ladder:
  `watch` (≥2×), `investigate` (≥3×), `consider bounded refactor` (≥5×). A directory churning hard but
  *normally for itself* stays silent.
- **Minimum floor:** at least 3 distinct commits in the window regardless of ratio, so a directory going
  from 0 to 1 commit cannot register as an infinite spike.
- **Baseline is printed with every signal**, so the operator can see what "unusual" was measured against
  rather than trusting a bare verdict (the *Attested* pillar).
- **Issue/PR linkage — parse rule pinned.** A commit counts as linked when a `#<n>` or `GH-<n>` reference
  appears anywhere in its **full message body**, not the subject alone. The round-4 pass showed the rung
  swings on this: subject-only gives 6 linked commits for `utils/py/` where whole-message gives 40+. At
  least one linked commit is required, else the signal is dropped as noise.
- **Excluded paths** (documentation and ledger churn is not code churn): `relay-system/**`, `PROJECT/**`,
  `ROADMAP.md`, `CHANGELOG.md`, root `*.md`, `.tick/**`.
- **Release-aware suppression:** when a directory's linked issues all sit in the selected release's
  milestone, the signal is labelled `directed work — already in release scope` rather than presented as
  a discovery. This is the double-reporting fix, and it only works because release alignment is computed
  first — an ordering dependency the build must honor.

**Analysis window:** fixed **14 days**, overridable with `--context-window <days>`, and always printed
alongside every claim (the *Fresh* pillar). 14 rather than 10 so a signal is not lost at the boundary
of a `/10days` sweep.

Churn signals are evidence, not diagnoses. A possible larger refactor or rewrite is a human decision
prompt only; it must never create or fire a lane automatically.

### Acceptance criteria

Each one names a runnable check (P10, Appendix H4). Fixtures live in `test/gh336-planning-context.sh`
plus `test/fixtures/gh336/`.

**Every fixture runs under the hermetic `gh` seam** (`QP_GH_STATE_FILE` / `QUEUE_PLAN_GH_STATE_FILE`, as
[test/marathon-plan.sh](../../test/marathon-plan.sh) already does). This is a precondition, not a detail:
without it the base planner's own `gh auth status` / `gh issue view` calls fire first and contaminate
every assertion below.

- [ ] **Plan doc is untouched in every mode.** For `off` / `auto` / `on` over the same fixture ROADMAP,
      `MARATHON-PLAN-<date>.md` is **byte-identical** — guaranteed by construction now that the overlay
      writes a sidecar, and pinned by test so a future refactor cannot quietly reintroduce an append.
- [ ] **Execution invariance (the load-bearing one).** Across the same three modes, the candidate set,
      ordering, waves, artifacts/collision map, preflight verdicts, and fire list are byte-identical.
      Asserted by golden files across `marathon_plan.py` *and* `swarm_preflight.py`.
- [ ] **Kill switch is byte-exact, it is the default, and it makes no overlay `gh` call.** Both
      `--planning-context=off` and the no-flag invocation reproduce today's plan doc byte-for-byte
      (golden captured before the change lands) and write **no sidecar file**. The `gh` assertion is
      scoped to the overlay's own query: a stub that fails loudly **only** on
      `gh issue list --milestone`, with the base planner's `gh` path neutralized by the hermetic seam
      above. (The previous wording — "neither issues a single `gh` call" — was false against the real
      base planner; round-4 finding 1.)
- [ ] **`--check` reports no false drift.** A plan generated under `auto`/`on` and then checked under
      the default mode reports **in sync**. This is the criterion the sidecar design exists to make
      trivially passable; it is pinned anyway because the guarantee is the point, not the mechanism.
- [ ] **Neither planner engine is touched.** `bash test/gh308-frozen-twin-guard.sh --check --staged`
      passes with no `Frozen-twin-exception:` trailer, and `git diff` touches neither
      `utils/marathon-plan.sh` nor `utils/py/_marathon_plan.py`.
- [ ] **`/10days` ordering is verified by reading the skill, not by running a binary.** Assert that
      `skills/10days/SKILL.md` places the sidecar instruction after its fire-list-frozen step and
      before its report step, and that no step preceding the fire list references the overlay. (Replaces
      a criterion that assumed a `/10days` executable existed — there is none; round-4 finding 2.)
- [ ] **Degrades, never fails.** With `gh` forced to fail *and* separately with a non-`gh` precondition
      failure (no release resolves; several resolve without `--release`): `auto` writes no sidecar
      silently, `on` writes none and prints the specific reason to stderr, both exit 0, and the plan doc
      is byte-identical to `off` in all four cases.
- [ ] **Receipts are structurally required.** Every sidecar row carries a non-empty `Claim`, `Kind`,
      `Source`, and `Window`, and `Kind` is exactly `fact` or `inference`. Fixtures with a missing source,
      a missing window, and an unlabelled synthesis each fail.
- [ ] **Churn is relative, floored, and suppressible.** Fixtures pin all four behaviors: a directory
      churning at its own normal rate emits nothing; a genuine spike emits with its ratio and baseline;
      a 0→1 directory is floored out; and a directory whose linked issues sit in the selected milestone
      is labelled `directed work` rather than reported as a discovery. Linkage parsing is asserted on a
      commit whose `#<n>` appears in the body but not the subject.
- [ ] **Messy-data fixture.** `RELEASES.md` with no `Milestone:` yields no sidecar — not a wall of
      `unresolved`.
- [ ] **No new persistence.** A scoped check asserts the diff adds no `tick` verb, no cache directory,
      and no file written outside `MARATHON-PLAN-<date>.context.md`. (Replaces the original unbounded
      "no event-log verbs, new service, persistent cache, or blocking gate" assertion, which no test
      could fail — Codex Should, Q3.)
- [ ] `./validate.sh` and `utils/pdda/pdda.sh run` are green. **Verification only** — these gates
      cannot substitute for the behavioral assertions above.

## Phase 2 — minimal deterministic contracts

**Start condition:** the [Phase 2 promotion evidence](#phase-2-promotion-evidence) table below holds
**three or more** dated rows, *and* an operator records an explicit GO. No rows, no Phase 2. Do not
start it merely because a richer schema is possible.

If earned, implement only the smallest stable contract those rows demonstrate:

- optional release/milestone selection input and a compact, versioned planning-context shape;
- GitHub-milestone verification for release-aware selection, while existing per-issue Swarm Preflight
  contracts remain the sole execution authority;
- deterministic malformed/missing-context findings **only** for an explicitly requested release-aware
  run — ordinary marathon planning and `/10days` remain valid without them;
- a dedicated architecture/refactor capture doc and explicit operator GO before a churn signal may
  become a large-refactor or clean-room-rewrite candidate.

### Reversibility contract (carried forward from Phase 1)

Phase 2 inherits `--planning-context=off` unchanged, and adds nothing that can outlive it.

**Removal seam — corrected and complete.** The round-4 pass found the earlier three-file list
understated the real surface; "nothing else references it" was wrong twice over. To remove the feature:

1. delete `utils/py/planning_context.py`;
2. delete `test/gh336-planning-context.sh` and `test/fixtures/gh336/`;
3. revert three things in `marathon_plan.py` — the post-render call site, the **three new flags**
   (`--planning-context`, `--release`, `--context-window`) in an arg parser that currently `die()`s on
   any unknown argument, and the usage text;
4. remove the sidecar instruction from `skills/10days/SKILL.md`;
5. delete any stale `MARATHON-PLAN-*.context.md` sidecars (generated artifacts, safe to remove).

**Call-site note for the builder.** The hook is real and already proven: `_inject_review_lanes`
([marathon_plan.py:195](../../utils/py/marathon_plan.py#L195), called post-render before the
check/write branch) does exactly this kind of post-render mutation today. `planning_context.py` attaches
at that same point. Unlike `_inject_review_lanes` — which *inserts* before the `## How to fire a lane`
anchor — the sidecar writer touches the plan doc not at all, so there is no ordering interaction between
the two.

The stickiness vectors Codex named are closed as follows:

| Vector | Closure |
|---|---|
| `/10days` unattended auto-fire | Context computed only after the fire list is frozen; asserted by test. |
| Consumers depend on the versioned shape | The shape is emitted into a sidecar artifact only. Enforced, not asserted: a CI check greps `utils/`, `relay-automation/` **and `skills/`** for any parser of `*.context.md` and fails if one appears. `skills/` is in scope because the `/10days` hook lives there — the earlier two-directory scope let the one file that *does* reference the feature escape the grep. Adding a reader is a new issue, not a Phase 2 sub-task. |
| Milestone-validation failure read as a gate | Findings are advisory and cannot change an exit code. |
| Vendored `.xyz/` drift | Module is Python-only under `utils/py/`; a vendored copy inherits `off` semantics with no `gh` reach. |
| CI/docs drift into requiring it | No CI step may make the overlay mandatory; the `off` golden test is itself the guard. |

### Acceptance criteria

- [ ] **Off-parity still holds.** The Phase 1 `off` byte-identical golden test passes unchanged after
      Phase 2 lands.
- [ ] **Removal is provable.** A test (or documented dry-run) shows that executing all five removal-seam
      steps above leaves `./validate.sh` green — including the `marathon_plan.py` arg-parser revert, since
      a leftover flag on a parser that `die()`s on unknown arguments is itself a regression.
- [ ] **No downstream parser exists.** A CI check greps `utils/`, `relay-automation/`, and `skills/` for
      any reader of `*.context.md` and fails if one is found. This is what makes the "no consumer depends
      on the shape" claim a mechanism rather than prose (round-2 QA finding), with `skills/` added after
      round 4 found the `/10days` hook escaping the original scope.
- [ ] **Scoped validation.** Contract validation runs only for the opt-in release-aware invocation;
      an ordinary-plan fixture produces byte-identical output with and without Phase 2 present.
- [ ] **Malformed input is specified.** A fixture pins the exact result for a missing or malformed
      selected milestone: an advisory finding, exit code unchanged.
- [ ] **Milestones stay the sole join key.** A fixture asserts no second membership source is read;
      GitHub milestones remain the release → issue-set join.
- [ ] **Execution authority unchanged.** An allowlist/collision/preflight regression fixture shows
      issue-level contracts and gates continue to govern execution byte-identically.
- [ ] **Refactor recommendations cannot fire.** A test asserts `/10days`' fire list never contains a
      churn or refactor recommendation, and that a refactor capture doc records alternatives,
      rollback/migration strategy, and the operator decision before any GO.
- [ ] `./validate.sh` and `utils/pdda/pdda.sh run` are green (verification only).

## Phase 2 promotion evidence

The auditable record that replaces the unverifiable "three real planning runs" phrasing. A row is
added **only** when a Phase 1 signal changed a real decision. This table is the doc-as-runtime-state
surface (P9); it is not a cache or a service, so it does not breach the non-goals.

| # | Date | Plan doc / run | Signal that fired | Decision it changed | Operator |
|---|------|----------------|-------------------|---------------------|----------|
| _(empty — Phase 2 is not startable)_ | | | | | |

## Non-goals

- No automatic selection, creation, or firing of refactor or rewrite work.
- No mandatory taxonomy for every issue.
- No duplicate release ledger, hand-maintained membership list, broad event-kernel change, or service.
- No Phase 2 implementation without the evidence rows above and explicit operator promotion.
- **No change to either planner engine** — `utils/marathon-plan.sh`'s embedded JS or
  `utils/py/_marathon_plan.py`.
- **No re-implementation of release→issue-set resolution.** `utils/release-lanes.sh` owns it.
- No `gh` call on any code path that decides what fires.

## Open questions for the operator

**Answered by the operator (2026-07-29):** churn threshold (3+), release-absent gating (pass-through),
Python-only lane.

**Resolved by the round-2 QA pass, with `GUIDING-PRINCIPLES.md` as the tie-breaker** — recorded here so
the reasoning is not lost:

- *Default mode* → **`off`**. `auto` would put an outward `gh` reach on every ordinary planning run,
  which P1 forbids. Opt-in costs one flag and makes reversibility true by construction.
- *Issue themes* → **deferred out of Phase 1.** Both reviewers independently graded it weakest; the
  *Relevant* pillar (*volume is not value*) settles it.

**Resolved on 2026-07-29 by checking the premise rather than deciding the question:**

- *Phase 0 ledger scope* → **out of scope.** The item rested on a false claim (that release selection
  would have to special-case the `Release: 0.1.0` EXAMPLE block); the stated rule already skips any
  block with an empty `Milestone:`, which that block has. GH-336 stays read-only against `RELEASES.md`.
  Deleting the expired placeholder is real but unrelated hygiene — a separate trivial doc fix, exempt
  from issue-first under P11.

**Still open:** none. Phase 0 is doc-correction only; Phase 1 is ready to build once an operator
schedules it.

## Found during review, deliberately out of scope

Recorded so they are not lost, and so nobody mistakes them for GH-336 work:

- **`marathon-plan.sh:54` claims `--check` is "a drift guard in `validate.sh`" — `validate.sh` does not
  wire it.** `validate.sh` runs `test/marathon-plan.sh` but never invokes `--check`, so the documented
  guard does not exist. A doc-vs-reality disagreement (P9), pre-existing, and a separate hygiene fix.
  It is why the sidecar's false-drift hazard is *latent* rather than active today.
- **`relay-drive.sh:353-356` rejects a bold-backticked artifact path in a relay Setup line.** The
  extractor strips `**` but leaves the backticks, so a valid path fails preflight as "not found in
  worktree." Hit live while scaffolding this very review. Harness papercut, unrelated to GH-336.
- **The expired `Release: 0.1.0` EXAMPLE block in `RELEASES.md`** — see Phase 0's struck item.
