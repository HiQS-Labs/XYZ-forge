---
title: Concurrent swarms — make the driver-lock scope true, provable, and observable before selling parallelism
status: "Active (2-WORKING) — opened 2026-07-30. Phase 0 discovery COMPLETE (findings below, verified against `development` at `b93fd93`). Phase 0 overturns three of issue #354's five collision claims and promotes its single observability footnote to the plan's highest-severity finding. Phase 1 is next and is a correctness fix, not a feature."
created: 2026-07-30
updated: 2026-07-30
owner: noel
gh_issue: 354
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354
doc_type: bugfix
effort: 3
complexity: 4
risk: 3
phases: 5
branch: claude/pdda-compliance-plan-e4mua0
non_goals:
  - Shipping per-worktree concurrent swarms. This plan does NOT enable parallelism.
    Phases 1–3 make the current exclusion contract true and observable; Phase 4 only
    decides whether opt-in per-worktree parallelism is worth building, and needs its
    own issue + GO if the answer is yes.
  - Removing or weakening the GH-42 `ROOT@HEAD` guard. The guard stays until
    something proves containment, and Phase 0 found no such proof in the tree.
  - Reworking `TICK_REPO_ROOT` resolution. Phase 0 established `.tick/` is already
    per-worktree; the vendored-mismatch question is GH-272's and stays there.
  - Reviving the Bash twins as an authored surface. GH-308 froze them; this plan
    patches them only where a fix must land on both lanes to be real.
  - Any change to `xyz-vendor.sh`'s preserve list. `.relay-driver.lock` is already
    preserved (`relay-automation/xyz-vendor.sh:300`); Phase 1 changes where the lock
    lives in a linked worktree, not what vendoring keeps.
related:
  - "#354 — the originating analysis this plan reviews and corrects."
  - "#42 — the `ROOT@HEAD` concurrent-run hazard the driver lock exists to prevent.
    Phase 0 found the lock does not actually cover two of the three concurrency
    pairs, so #42's guarantee is narrower in a linked worktree than its own error
    message claims."
  - "#49 / GH-49b — the vendored-`.xyz/` and linked-worktree lock-path resolution
    that `marathon-drive` has and `relay-drive` never received."
  - "#308 — Bash-twin freeze + behavior audit. Every Phase 1/2 fix has to land on
    the Python twin (the default lane since GH-264) AND its frozen Bash sibling, or
    it silently does not run; this is the exact failure class #308 catalogued."
  - "#272 — `TICK_REPO_ROOT` vendored mismatch. Adjacent, deliberately NOT merged in:
    Phase 0 found `.tick/` is per-worktree today, so the namespacing #354 proposed
    is not needed for the worktree shape."
  - "#292 — `find-harness.sh` misses a vendored `.xyz/` from a linked worktree. Same
    root cause family: `-d .git` as a proxy for \"is a repo root\"."
  - "#11 — `--target-root` / registry cross-repo targeting, the separate-clones shape
    this plan's quick-win path leans on."
goal: >
  A single truthful sentence about concurrency, provable by a test, and visible in
  the monitors: state exactly which driver pairs exclude each other in a linked
  worktree, make all three pairs behave the way the lock's own error message already
  claims they do, and stop the fleet monitors reporting a LIVE worktree run as IDLE.
  Only then decide whether opt-in parallelism is worth building.
---

# GH-354 — Concurrent swarms: make the lock contract true before making it optional

Issue [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
answers "can two swarms run in linked worktrees of one clone?" with *no, by design* and lists five
collisions plus one observability bug. This doc is the review of that answer.

The verdict changes. #354's conclusion — **use separate clones** — is right, and Phase 0 confirms it.
But it is right for a different reason than the issue gives, and #354's own footnote is the most
serious defect in the set. Specifically:

- The lock is **not** the hard blocker #354 describes. It blocks one of three concurrency pairs.
- Three of the five "what still collides if you bypassed the lock" items **do not collide** in a
  linked worktree, because `.tick/` is already per-worktree.
- The observability bug filed as "worth filing regardless" is **not one script**. It is three, and
  it means an operator cannot see the state that the whole exclusion argument depends on.

## Status

| What was just completed | What's next |
|---|---|
| **2026-07-30: Phase 0 discovery complete.** Reviewed the actual lock, lane-namespace, session-identity and monitor surfaces on `development` at `b93fd93` — including `relay-drive.sh` and `relay-turn-lib.sh`, which #354 flagged as unavailable and therefore reasoned about from `marathon-drive.sh`'s comments. Both are present and the comments are wrong. **Confirmed:** the marathon↔marathon exclusion, `MARATHON_LANE_NS` existing as the lane override, the `XYZ_SESSION_ID` → `PHASE_ID` fallback, and the monitor's false-IDLE. **Overturned:** (a) marathon↔relay and relay↔relay do **not** mutually exclude in a linked worktree — `relay-drive` never received GH-49b's worktree branch, on either runtime, so it takes a per-worktree lock while `marathon-drive` takes a shared one; (b) `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees, because `TICK_REPO_ROOT` defaults to each shim's own `ROOT`; (c) the `git worktree add/prune` exposure is the shared `worktrees/` admin registry and an add-vs-prune race, not `ROOT@HEAD` — `--detach … HEAD` resolves per-worktree. **Escalated:** the false-IDLE bug also exists in `utils/hq/marathon-live.sh` and `utils/hq/hourly-global-scan.sh`. Findings, with `file:line`, in [Phase 0](#phase-0--discovery-verify-354s-claims-against-the-code-complete). | Phase 1 — mirror GH-49b's worktree lock branch into `relay-drive` on **both** runtimes, with a regression test that fails pre-fix. This is a GH-42 containment fix and should not wait on the rest of the plan. |

## Table of contents

- [Phase 0 — Discovery: verify #354's claims against the code (COMPLETE)](#phase-0--discovery-verify-354s-claims-against-the-code-complete)
- [Phase 1 — Close the relay-drive worktree lock gap (correctness)](#phase-1--close-the-relay-drive-worktree-lock-gap-correctness)
- [Phase 2 — Make a live worktree run visible to the monitors](#phase-2--make-a-live-worktree-run-visible-to-the-monitors)
- [Phase 3 — Write the one true concurrency sentence, and test it](#phase-3--write-the-one-true-concurrency-sentence-and-test-it)
- [Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?](#phase-4--decision-gate-is-opt-in-per-worktree-parallelism-worth-building)

---

## Phase 0 — Discovery: verify #354's claims against the code (COMPLETE)

**What was investigated.** Every mechanism #354 names, read on `development` at `b93fd93`: the driver
lock in both drivers on both runtimes, the lane-attempt and session-identity namespacing, the
throwaway-worktree lifecycle in `relay-turn-lib.sh`, `.tick/` root resolution, and the fleet monitors.
#354 carries an explicit caveat that `relay-drive.sh` and `relay-turn-lib.sh` "aren't in this
project's files," so its lock-mirror and `rtl_worktree_begin` claims rest on `marathon-drive.sh`'s
comments. Both files are in the tree. Closing that caveat is what changes the plan.

### Finding 0.1 — CONFIRMED, and narrower than stated: the marathon lock is shared per clone

`relay-automation/marathon-drive.sh:197-208` and its Python twin
`utils/py/marathon_drive.py:293-313` resolve the lock in three branches: `.git` is a directory →
`ROOT/.git/relay-driver.lock`; `.git` is a *file* (linked worktree) → `git rev-parse
--git-common-dir` → `<common>/relay-driver.lock`; neither (vendored `.xyz/`) →
`ROOT/.relay-driver.lock`. Two linked worktrees of one clone therefore resolve the **same** lock and
the second marathon exits 1 with *"Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD
hazard)"* (`marathon-drive.sh:214-216`). #354 is exactly right here.

**What it changes:** nothing on its own — this is the one pair that works.

### Finding 0.2 — OVERTURNED, and the plan's headline: `relay-drive` never got the worktree branch

`relay-automation/relay-drive.sh:147-152` has **two** branches, not three:

```text
if [[ -d "$ROOT_DIR/.git" ]]; then  _lock="$ROOT_DIR/.git/relay-driver.lock"
else                                _lock="$ROOT_DIR/.relay-driver.lock"
```

In a linked worktree `.git` is a file, so `-d` is false and relay-drive falls to the **vendored**
branch — a per-worktree `.relay-driver.lock`. `utils/py/relay_drive.py:386-391` is identical, so the
gap is on the **default** runtime too (`XYZ_PYTHON-1`, `relay-drive.sh:9`), not just the frozen twin.

`marathon-drive.sh:194-196` asserts the opposite in a comment: *"Same lock NAME as relay-drive so a
marathon and a relay driver still mutually exclude in one clone."* The name matches. The **path** does
not. So in a linked worktree:

| Pair | Lock paths | Excludes? |
|---|---|---|
| marathon ↔ marathon | `<common>/relay-driver.lock` (both) | **yes** |
| marathon ↔ relay | `<common>/relay-driver.lock` vs `<wt>/.relay-driver.lock` | **no** |
| relay ↔ relay | `<wt1>/.relay-driver.lock` vs `<wt2>/.relay-driver.lock` | **no** |

Two of three pairs run concurrently while printing nothing. The marathon↔relay case is the worst:
both drivers operate on the **same working tree**, same HEAD, same `.tick/` — the GH-42 hazard with
no guard at all, reached without bypassing anything.

Second-order: the fallback lands `.relay-driver.lock` **inside the working tree**, and it is not in
`.gitignore` (checked — `.gitignore` covers `.tick/` and the GH-75 telemetry trio, not the lock). That
is the untracked-bookkeeping problem GH-49b's comment says the worktree branch exists to avoid
(`marathon-drive.sh:191-193`). `relay-drive` has no `--require-clean` of its own, so this does not
trip a documented gate today — call it a latent dirt source, not a live break, and let Phase 1's test
pin it rather than asserting a consequence this pass did not observe.

**What it changes:** #354's framing — *"the hard blocker (by design)"* — does not hold, so its
conclusion cannot rest on the lock. Phase 1 exists, and is a GH-42 correctness fix that should not
be sequenced behind the parallelism question at all.

### Finding 0.3 — OVERTURNED: `.tick/` is already per-worktree, so claims 1, 2 and 4 do not fire

#354 lists commingled tick task names, shared lane attempt counters
(`.tick/attempts/<_lane_key>`) and one cumulative `tick analyze` total as things that "still collide
if you bypassed the lock." In the linked-worktree shape they do not.

`marathon-drive.sh:74-76` / `marathon_drive.py:184-198` set `ROOT` to the harness clone dir — the
**worktree** path for a linked worktree — and `marathon_drive.py:805` (`relay-drive` and every turn
shim likewise, e.g. `relay-automation/claude-turn.sh:101-103`) exports `TICK_REPO_ROOT="$ROOT"`.
`bin/tick:19` honours that env var first. `.tick/` is gitignored (`.gitignore:1`), so it is never
checked out and each worktree materialises its own. Attempt counters
(`marathon-drive.sh:99`, `:130`) and `tick analyze` (`marathon-drive.sh:180`) both read
`${TICK_REPO_ROOT:-$ROOT}` and are therefore per-worktree.

Two swarms both driving a task named `MARATHON-P1-TURN` (`marathon-drive.sh:760`) in **separate**
`.tick` roots is harmless — the id is only a collision when the root is shared. That happens in a
different shape: two swarms in the *same* directory, or an operator pinning `TICK_REPO_ROOT` to a
common root (which the isolated-turn path deliberately does — `aider-turn.sh:268` keeps `.tick`
coordination state shared on purpose).

**What it changes:** deletes three of five collision items from the worktree shape and re-points them
at the shared-`TICK_REPO_ROOT` shape, where they are real. It also removes the need for the
`.tick`-namespacing work #354 proposed as "harder" step 2 — that work is not required for worktrees
and belongs to GH-272's question if it is required at all. Net: the plan gets smaller and more honest.

### Finding 0.4 — REFRAMED: the throwaway-worktree exposure is the admin registry, not `ROOT@HEAD`

`relay_turn_lib.sh`'s `rtl_worktree_begin` (`relay-automation/relay-turn-lib.sh:539-562`) does
`mktemp -d` then `git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD`; `rtl_worktree_end`
(`:714-715`) does `worktree remove --force` then `worktree prune`. Because `HEAD` is resolved through
`git -C "$RTL_ROOT"`, each linked worktree pins **its own** HEAD, and `mktemp -d` guarantees distinct
paths even on GH-236's relocated root (`<common>/rtl-worktrees`, `:552-556`) which *is* shared.

So the two throwaway trees do not collide by path or by commit. What they share is the
`<common>/worktrees/` admin registry that `add` and `prune` both mutate. One driver's `prune` will
not remove a peer's live tree (its directory exists), but `prune` concurrent with a mid-flight `add`
is a plausible narrow race on a partially-written entry. This pass did **not** reproduce it — stating
it as a hypothesis with a named test, not a finding, is the honest form and Phase 4 owns proving or
dismissing it.

**What it changes:** #354's *"That's the GH-42 hazard directly"* is too strong. The `ROOT@HEAD`
hazard needs a different argument than the throwaway trees, and Phase 0 found **no** written
reasoning for it anywhere — `marathon-drive.sh:215` asserts unsafety and cites GH-42; neither the
script nor the twin explains the mechanism. #354 already noticed this; it survives Phase 0 intact and
is the single biggest blocker to any future parallelism, which is why Phase 4 is a decision gate and
not an implementation phase.

### Finding 0.5 — CONFIRMED and ESCALATED: three monitors report a LIVE worktree run as IDLE

`relay-automation/marathon-ls.sh:44-50`:

```text
lock_path_for_repo() { if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' ...
                       else printf '%s/.relay-driver.lock' ... }
```

Same `-d .git` proxy. From a linked worktree it returns `<wt>/.relay-driver.lock`, which a marathon
never writes (Finding 0.1 puts it in the common dir), so the monitor sees no lock and derives
**IDLE** for a genuinely LIVE run.

#354 files this as one script. It is three:

- `relay-automation/marathon-ls.sh:44-50` — as described.
- `utils/hq/marathon-live.sh:94-95` — probes `$repo/.git/relay-driver.lock` then
  `$repo/.xyz/.relay-driver.lock` and returns non-zero otherwise; in a linked worktree `.git` is a
  file so the first path cannot exist. The cross-repo "is-it-really-driving" answer is **no** for
  every live worktree marathon in the fleet.
- `utils/hq/hourly-global-scan.sh:28` — same `.git/relay-driver.lock` assumption in the hourly
  global scan, so the rolling fleet snapshot inherits the same blind spot every hour.

**What it changes:** promotes this from a footnote to Phase 2, and it is load-bearing for the rest of
the plan. Every exclusion argument here is verified by *observing which lock is held*; if the
operator's three windows onto that state are all blind in exactly the shape under discussion, no
concurrency claim can be checked in the field. Note the asymmetry that makes this dangerous rather
than merely wrong: post-Phase-1, a live **relay** in a worktree *will* be seen (its lock is
per-worktree, which is what the monitors look for) while a live **marathon** will not — so the fleet
view is not uniformly pessimistic, it is selectively wrong.

### Phase 0 QA gate

- [x] `relay-drive.sh` and `relay-turn-lib.sh` read directly; #354's caveat closed and its
      comment-derived claims re-tested against code.
- [x] Every claim in #354 marked CONFIRMED / OVERTURNED / REFRAMED / ESCALATED with `file:line`.
- [x] Both runtimes checked for each finding (Bash + `utils/py/`), since a Bash-only reading of a
      Python-default lane is the GH-308 failure class.
- [x] Findings written back into this doc (PDDA discovery contract), not left in session context.
- [x] Unproven items (the add-vs-prune race; the `.relay-driver.lock` dirt consequence) labelled as
      hypotheses with owning phases, not reported as findings.

---

## Phase 1 — Close the relay-drive worktree lock gap (correctness)

Ship Finding 0.2's fix. Mirror `marathon-drive`'s three-branch resolution into `relay-drive` so the
lock name and the lock **path** agree, on both runtimes.

Scope — four files, one behavior:

- `relay-automation/relay-drive.sh:147-152` — add the `-f "$ROOT_DIR/.git"` → `--git-common-dir`
  branch, byte-consistent with `marathon-drive.sh:197-208` including the `.git/relay-driver.lock`
  label and the empty-`common-dir` fallback.
- `utils/py/relay_drive.py:386-391` — same, mirroring `utils/py/marathon_drive.py:293-313`.
- The Bash pair is GH-308-frozen. It gets the patch anyway: leaving `XYZ_PYTHON=0` with a silently
  weaker containment guard is the same "fake safety gate in the fallback" call already made at
  `marathon-drive.sh:685`. Note it in the GH-308 audit doc rather than inventing a new exemption.

Deliberately **not** in Phase 1: extracting the resolution into one shared helper. That is the right
end state and the wrong first move — a fifth copy is a fifth thing to drift, but a refactor across a
frozen twin and a live lane is a bigger blast radius than the bug. Re-raise it after Phase 3's test
pins the behavior from both sides.

### Phase 1 QA gate

- `test/driver-lock.sh` extended (or a sibling added and **registered in `validate.sh`'s explicit
  `TESTS=()` array** — GH-292 recorded that an unregistered test silently never runs) covering, in a
  real `git worktree add`ed fixture:
  - a live marathon lock in the common dir **refuses** a relay start in the worktree (exit 1) — this
    is the assertion that fails pre-fix;
  - a live relay in worktree W1 **refuses** a relay in W2 of the same clone;
  - both assertions run under `XYZ_PYTHON=1` **and** `XYZ_PYTHON=0`;
  - the vendored `.xyz/` (no `.git`) and plain-clone paths are **unchanged** — byte-identical lock
    path to pre-fix, so the fix cannot regress the two shapes that work today.
- The new test is observed **failing before** the fix and passing after, and that observation is
  recorded here (`gh319`/`gh312` precedent: a test not seen red is not evidence).
- `./validate.sh` green, with the run's pass/fail counts recorded here — not "green" as prose.
- `utils/pdda/pdda.sh run` clean.

---

## Phase 2 — Make a live worktree run visible to the monitors

Fix Finding 0.5 in all three monitors. Each needs the same `-f .git` → `--git-common-dir` probe added
ahead of its existing fallbacks, and each must keep working when `git` is absent or the path is not a
repo at all (these are read-only fleet monitors — degrade to the current answer, never error).

- `relay-automation/marathon-ls.sh:44-50` — `lock_path_for_repo` returns the common-dir path for a
  linked worktree. Its header comment (`:41-43`) documents only two shapes and must document three.
- `utils/hq/marathon-live.sh:94-95` — add the common-dir probe to the ordered candidate list.
- `utils/hq/hourly-global-scan.sh:28` — same, so the hourly snapshot stops inheriting the blind spot.

Sequenced **after** Phase 1 on purpose: post-Phase-1 both drivers write predictable per-shape paths,
so the monitors are taught one rule rather than being taught to model today's inconsistency.

### Phase 2 QA gate

- A fixture worktree with a marathon lock held in the common dir renders **LIVE** in
  `marathon-ls.sh`, and `marathon-live.sh` answers "really driving: yes" — both assertions failing
  pre-fix.
- Plain-clone and vendored-`.xyz/` repos render exactly as before (regression guard on the two
  working shapes).
- No monitor errors or exits non-zero on: a bare path that is not a git repo, a worktree whose common
  dir is gone, and `git` unavailable on `PATH`.
- `./validate.sh` green with counts recorded; `utils/pdda/pdda.sh run` clean.

---

## Phase 3 — Write the one true concurrency sentence, and test it

The reason this issue was asked at all is that no document says what the lock guarantees, and the one
place that tries — `marathon-drive.sh:194-196` — is wrong. Fix the docs *from the tests*, so the
sentence and the behavior cannot drift apart again.

- State the exclusion matrix (Finding 0.2's table, post-Phase-1: all three pairs exclude per clone)
  in `skills/relay-xyz/SKILL.md`, which is the vendored surface every `.xyz/` install reads — it
  currently describes the lock at `:109` without the worktree shape.
- Correct `marathon-drive.sh:194-196`'s comment and its Python counterpart so "same NAME" is no
  longer offered as the reason two drivers exclude; the reason is the resolved path.
- Record the recommended shape for actually running two swarms — **separate full clones**, per #354's
  quick win, which Phase 0 endorses — plus the cheap per-run hygiene that makes the event stream
  readable even across clones: distinct `--phase-id` / `--relay-task` (`marathon-drive.sh:655-656`),
  `MARATHON_LANE_NS` (`marathon-drive.sh:761` — the lane override already exists, confirming #354's
  quick win #2) and `XYZ_SESSION_ID`, whose fallback to `PHASE_ID`
  (`marathon-drive.sh:436`, `marathon_drive.py:366`) the code's own comment calls useless for telling
  one run from another.
- Correct the record on #354 itself: post a comment noting which claims Phase 0 overturned, so the
  issue thread does not remain the fleet's reference for a wrong collision list.

### Phase 3 QA gate

- The exclusion matrix appears in exactly **one** canonical place, with the others linking to it
  (PDDA Principle #4 — one canonical place per fact); no second copy of the matrix in a driver
  comment.
- Every row of the documented matrix is backed by a named assertion from Phase 1/2's tests, cited by
  test name in the doc.
- `relay-drive.sh`'s own header documents its lock shapes to the same standard as
  `marathon-drive.sh:190-196`.
- `utils/pdda/pdda.sh run` clean; `#354` updated.

---

## Phase 4 — Decision gate: is opt-in per-worktree parallelism worth building?

A gate, not an implementation phase. It ends in a written GO / NO-GO in this doc, and a NO-GO is a
perfectly good outcome — Phase 0 already shows the operator's real need is met by separate clones,
which cost a `git clone` and need no code.

GO requires all four, and each is a real risk of coming back negative:

1. **The `ROOT@HEAD` hazard is written down.** Finding 0.4: nothing in the tree explains the
   mechanism. Until someone can state what breaks, `XYZ_LOCK_SCOPE=worktree` would relax a guard
   whose purpose is unknown — the definition of a one-way door taken blind.
2. **The add-vs-prune race is resolved.** Reproduce it against a shared `<common>/rtl-worktrees` root
   (`relay-turn-lib.sh:552-556`) or dismiss it with reasoning. A hypothesis cannot gate a design and
   must not be quietly dropped either.
3. **Shared-ref collision has an answer.** Linked worktrees have separate HEAD and index but share
   refs; two drivers committing to the same branch is not a lock problem and the lock cannot fix it.
   If the answer is "each swarm owns a distinct branch," that is a contract to state and enforce, not
   an assumption.
4. **A real operator demand exists that separate clones do not meet.** Named, with the reason clones
   were insufficient. Absent that, NO-GO on cost alone.

On GO, the shape is #354's own: an opt-in `XYZ_LOCK_SCOPE=worktree` keeping the lock in `$ROOT`,
default off, mirrored across all four driver files, its own issue, and its own plan doc. Not this one
— by then this doc's job is done.

### Phase 4 QA gate

- A GO/NO-GO decision is written **into this doc** with its reasoning, and each of the four criteria
  is answered explicitly (an unanswered criterion is a NO-GO, not a deferral).
- On NO-GO: `#354` is closed with the separate-clones recommendation and a pointer to the Phase 3
  matrix; this doc moves to `PROJECT/3-COMPLETED/` and its `ROADMAP.md` pointer is updated.
- On GO: a new issue + `PROJECT/1-INBOX/GH-<n>-*.md` capture exists and is parked in `ROADMAP.md`
  per the issue-first SOP; no implementation begins under this doc.
- The `PROJECT/DO-NOT-BUILD.md` and `PROJECT/CONSTITUTION.md` reversibility stance is checked against
  the decision before it is recorded.

---

## Reversibility read

- **Phases 1–2 — Easy.** Both are additive branches in path-resolution functions; the plain-clone and
  vendored shapes keep byte-identical paths, and each phase's gate pins that. Revert is a one-commit
  `git revert`. The one live-state caveat: a driver started before the fix holds its lock at the old
  path, so a mid-flight upgrade can leave a stale lock at the pre-fix location — the GH-42 self-heal
  reclaims it only when the holder is dead, which is the correct behavior, and it is worth naming in
  Phase 3's docs rather than discovering in the field.
- **Phase 3 — Easy.** Docs and comments.
- **Phase 4 — one-way door, which is why it is a gate.** Relaxing lock scope changes the containment
  contract every consumer and every vendored `.xyz/` install inherits; `risk: 3` on this doc covers
  Phases 1–3, and a GO would carry its own higher rating in its own doc.
