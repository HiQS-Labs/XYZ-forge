# Handoff — Marathon run for the KISS-woo-fast-search bug-fix batch

**To:** the plugin-repo maintainer (the one who built `tests/run.sh` + `tests/gate.php` + `tests/HUMAN-VERIFY.md`).
**From:** xyz-3-agents-swarm orchestration side.
**What you get:** `MARATHON.yaml` + `phases-briefs/` (4 briefs). Drop both at the plugin repo root next to `tests/`.

This run deliberately covers **only the four phases your no-DB gate can actually verify** (#68, #70, #71, #72).
#73 / #76 / #75-wiring / #69-values stay human-gated — they need production-scale data.

## Table of Contents

- [1. Run plan (lanes)](#1-run-plan-lanes)
- [2. How to run it (foreign repo = marathon ROOT)](#2-how-to-run-it-foreign-repo--marathon-root)
- [3. Two corrections to the buckets (do these, cheap)](#3-two-corrections-to-the-buckets-do-these-cheap)
- [4. What "success" looks like (don't be fooled by GATE: FAIL)](#4-what-success-looks-like-dont-be-fooled-by-gate-fail)
- [5. Transcripts — capture everything for fine-tuning](#5-transcripts--capture-everything-for-fine-tuning)
- [6. Post Run Independent Review (Codex — 2026-06-27)](#6-post-run-independent-review-codex--2026-06-27)
- [File manifest in this handoff](#file-manifest-in-this-handoff)

---

## 1. Run plan (lanes)

| Phase | Issue | Reviewer | Gate flips green? | Notes |
|-------|-------|----------|-------------------|-------|
| kwfs72 | #72 docs | agy | yes (phrase grep) | trivial, independent |
| kwfs71 | #71 packaging | agy | yes (file check) | trivial, independent |
| kwfs68 | #68 HPOS URL | codex | **partial** | gate proves the *helper*, not the call-site swap — see §3 |
| kwfs70 | #70 formatter | codex | yes (key-set equality) | depends_on kwfs68 (same file) |

Builder = `claude` (default). Reviewers split codex/agy on purpose — it dogfoods both review lanes while
keeping the two code-correctness phases on Codex (lane policy: agy is reviewer-first/builder-gated).

## 2. How to run it (foreign repo = marathon ROOT)

`marathon.sh` (the chainer) has **no `--target-root`** — cross-repo chaining is unfinished (GH-16/GH-29).
The clean workaround uses the env overrides marathon.sh already honors, with the **plugin repo as ROOT**:

```bash
cd <plugin-repo>            # KISS-woo-fast-search, on a branch off `development`
MARATHON_ROOT="$PWD" \
MARATHON_DRIVE="<xyz>/relay-automation/marathon-drive.sh" \
MARATHON_YAML_BIN="<xyz>/bin/marathon-yaml" \
TICK_BIN="<xyz>/bin/tick" \
bash "<xyz>/relay-automation/marathon.sh" --plan MARATHON.yaml --dry-run   # SMOKE FIRST
```

Then drop `--dry-run` for the real run. **Smoke with `--dry-run` first** — verify marathon-drive operates
cleanly with a foreign ROOT before committing a live run; this is the least-proven axis.

## 3. Two corrections to the buckets (do these, cheap)

1. **#68 gate blind spot.** Your `#68` check verifies `get_edit_url()` branching (already green) but not
   that `class-kiss-woo-search.php:960` *uses* it. Add a one-line grep assertion: fail if `post.php?post=`
   appears in `format_order_data_for_output()`. Without it, kwfs68 can be "approved" without the actual fix.
2. **#69 is uncovered.** It's neither gated nor in HUMAN-VERIFY. kwfs70 forces `payment`/`shipping` *keys*
   to exist, but the **values** (correct method titles) need a store. Add a `#69` entry to
   `tests/HUMAN-VERIFY.md` so it doesn't silently fall through.

Optional (only if you want true per-phase closed-loop): add a `tests/run.sh <issue>` filter so each phase
can gate on just its own invariant. Not required — see §4 for why the holistic gate is fine as-is.

## 4. What "success" looks like (don't be fooled by GATE: FAIL)

The gate is holistic and also checks **#75** (the `get_customer_orders_key` method), which is **not** in
this marathon — it's human-checkpoint work. So after a clean run the gate reads:

```
INVARIANTS: 4 passed, 1 failed   ·   GATE: FAIL      (the 1 failed = #75, expected)
```

That residual red is the **human-checkpoint tracker**, not a marathon failure. Judge marathon success by
the **`phase.approved` events** (4 of them) and `marathon.complete`, not by `GATE: PASS`. The marathon
cannot reach a fully-green gate alone, by design.

Per-phase note for the reviewer: each brief names the exact invariant + needle its phase must flip. The
holistic gate is **not** wired as `--pre-advance-cmd` (it would be red until all phases land and halt the
chain at phase 1). Per-phase verification = reviewer judgment guided by the brief; the gate is the final
regression fence + the "what's left for humans" dashboard.

## 5. Transcripts — capture everything for fine-tuning

This run is also a **training-data harvest**. Make sure none of it is thrown away:

- **Per-phase relay transcripts** land at `phases/<id>/RELAY.md` and `relay-system/<date>/marathon-<id>-*.md`
  (builder turns, reviewer turns, verdicts). These are the labeled build→review pairs we want.
- **Failure transcripts:** if a phase halts, marathon-drive leaves `phases/<id>/ESCALATION.md` — **keep it**.
  No-progress / cap-hit / containment halts are the highest-value negatives for fine-tuning; do not delete.
- **Gate deltas:** capture `bash tests/run.sh` output **before and after each phase** (red→green per issue)
  and save alongside the phase transcript. The (brief → diff → gate-flip) triple is the cleanest signal.
- **After the run**, copy the whole transcript set back to the xyz repo
  (`relay-system/<date>/kwfs-marathon-*/`) and note it in `CHANGELOG.md` so the corpus has one home.
  Note: `.distignore` (phase kwfs71) excludes `relay-system/`, `phases/`, and `.tick/` from the plugin
  **zip** — that does **not** delete them from the repo, so the transcripts survive for harvest. Good.
- Keep `.tick/events/` (phase.start / phase.approved / phase.escalated / marathon.complete) — the event
  log is the ground-truth timeline that stitches the transcripts together.

**Net:** every phase should leave a brief, a diff, a reviewer verdict, a before/after gate delta, and an
event trail. That's the unit we fine-tune on.

## 6. Post Run Independent Review (Codex — 2026-06-27)

**Verdict:** the task order is right-sized for `xyz-3-agents-swarm`; the over-engineering is mostly in the
operator ceremony, not in the phase sequencing.

**Why the order is correct**

- The run only includes fixes the plugin repo's no-DB gate can actually verify, which matches this repo's
  "verified beats plausible" posture.
- The two trivial, independent phases land first (`kwfs72`, `kwfs71`), then the shared-file dependency
  (`kwfs68` before `kwfs70`) follows. That is the minimum ordering needed to avoid cross-phase confusion.
- The harness itself is intentionally fail-fast and phase-ordered: `marathon.sh` advances on
  `phase.approved`, halts on the first failed phase, and emits `marathon.complete` only when the full chain
  closes. The handoff order matches the real orchestrator contract instead of inventing a second workflow.

**What feels overbuilt**

- Cross-repo operation still depends on env-variable indirection because `marathon.sh` lacks a first-class
  `--target-root`, even though `marathon-drive.sh` already supports it. That makes the maintainer carry
  harness internals that should be hidden behind one flag.
- Success is intentionally decoupled from `GATE: PASS`, which is operationally honest but cognitively
  expensive: the maintainer must interpret `phase.approved` events and the residual `#75` red correctly.
- The handoff also doubles as a transcript-harvest protocol. That is aligned with the repo's training-data
  goal, but it is more ceremony than a narrow "ship four bug fixes" run would need.

**Net call**

If the goal is **safe multi-agent dogfooding on a foreign repo plus reusable training data**, this is about
the right amount of process. If the goal were only **land four plugin fixes with the least operator work**,
the current handoff would be heavier than necessary.

---

### File manifest in this handoff
- `MARATHON.yaml`
- `phases-briefs/kwfs72-docs.md`
- `phases-briefs/kwfs71-packaging.md`
- `phases-briefs/kwfs68-hpos-url.md`
- `phases-briefs/kwfs70-formatter.md`
