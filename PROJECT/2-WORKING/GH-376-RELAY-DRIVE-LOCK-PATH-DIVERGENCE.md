---
gh_issue: 376
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376
title: "GH-376 — relay-drive and marathon-drive take different locks from a linked worktree, so the mutual exclusion they both believe in does not exist"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch, batch 2. Issue has NO ## Acceptance section; criteria authored below in a separate section, not inside ## Acceptance. Verified against the tree at 2026-08-10: the divergence is real, and two things the issue does not say surfaced during verification — a shared resolver already exists (shipped by #448) and this fix is self-modifying (cannot be a marathon lane). Awaiting preflight is moot; this must ship as a direct PR."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#448 — CLOSED, shipped in PR #449 (merged `000aa6ce`). Built the ONE shared driver-lock resolver (`relay-automation/driver-lock-lib.sh` + `utils/py/rtl.py::driver_lock_path`) for every READ-ONLY consumer of the lock, and its own doc explicitly carves this issue out: 'relay-drive.sh/relay_drive.py are tracked separately by sibling issue #376 (the driver-side half of the same defect class).' #448 does not fix #376 — it changes what the cheapest correct fix for #376 now looks like, because a proven-correct resolver already exists to reuse instead of writing a third inline copy."
  - "#358 — a DIFFERENT lock entirely: an advisory mkdir lock on a per-repo `$XYZ_JSON.lock` guarding `utils/telemetry/append-xyz-completion.sh`'s read-modify-write of the completion-event log, not `relay-driver.lock`. Phase 1 (retain each appender's exit status, report terminal state) shipped in PR #489. Its instrumentation is single-process, single-repo, and carries no path-resolution logic — it changes nothing about #376. Both are 'a lock is wrong' findings in the same release, at unrelated call sites, with unrelated fixes."
  - "#354 — the parent analysis. This issue's own text calls itself 'the actionable defect its code review turned up,' and #354 itself has no ## Acceptance section and no Swarm Preflight Contract (named as such in the Nightwatch wave-1 CHANGELOG entry), so it is not itself preflightable."
  - "#149 — CLOSED. Same relay-driver.lock, a different failure: marathon-drive's own `--require-clean` self-tripping on its own lock directory, not a cross-driver path mismatch."
  - "#141 — CLOSED. Adjacent blind spot: containment cannot see a concurrent peer at all. #376 is sharper — the two drivers DO try to see each other through this lock; the mechanism is just broken in one topology (linked worktree)."
non_goals:
  - "The mode-aware lockout redesign the issue itself proposes as a 'broader shape worth considering' (a lock record naming the mode/phase, a compatibility matrix, mode-aware refusal messages). The issue says this 'may belong in the GH-354 plan rather than here.' Out of scope here; the single-mutex path-resolution bug is what this lane fixes."
  - "Changing lock ACQUISITION or reclaim semantics — stale-holder reclaim, the TOCTOU window noted at `marathon-drive.sh:226-227`, pid bookkeeping. This is a path-resolution fix only, mirroring #448's own non-goal on the identical code area."
  - "Editing `relay-automation/marathon-drive.sh` or `utils/py/marathon_drive.py`'s own lock resolution. Both are already correct (verified below) and #448 left the Bash side byte-unchanged for the same reason."
  - "Editing `utils/py/rtl.py::driver_lock_path` or `relay-automation/driver-lock-lib.sh` themselves. Both are the shared resolver #448 already shipped; this lane may call/import them but must not modify them — `rtl.py` is the turn kernel, and editing it would make this lane self-modifying in a second, worse way."
  - "Firing this as a marathon or relay lane. See Reversibility & blast radius — the write-set is the marathon driver's own per-turn-loop subprocess."
goal: >
  marathon-drive.sh:195-196 states, in-tree, that a marathon and a relay driver mutually exclude via
  one shared lock NAME. From a normal clone that is true. From a linked worktree — the exact topology
  swarm-preflight.sh's own recommended invocation creates via RELAY_WORKTREE_ISOLATION=1 — .git is a
  file, not a directory, and the two drivers' resolvers diverge: marathon-drive (and, since #448,
  utils/py/marathon_drive.py via the shared resolver) correctly follows .git to the git COMMON dir;
  relay-drive still guesses with the old 2-branch logic and lands on a lock local to whichever
  worktree it happens to run in. Two independently-launched top-level drivers can then each hold what
  they believe is THE lock while running against the same working tree, invisible to each other. Make
  relay-drive's Bash and Python resolution agree with marathon-drive's from a linked worktree, so the
  exclusion the comment already claims becomes true.
---

# GH-376 · relay-drive resolves a different lock than marathon-drive from a linked worktree

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch. The issue has no `## Acceptance` section; criteria are authored below in a clearly separate section. Every locking claim in the issue was re-verified against the current tree and holds. Verification also surfaced two things the issue does not say: (1) `#448` already shipped a proven-correct shared resolver this fix should reuse rather than duplicate a third time, and (2) `relay-drive.sh` is not an inert helper — it is the literal per-phase-turn subprocess `marathon-drive.sh`/`marathon_drive.py` exec, by its own comment ("relay-drive.sh IS the loop"), which makes this fix self-modifying. | Direct PR against `development`. Not preflightable as a marathon lane — see Reversibility & blast radius. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376

## The defect

**The divergence, verified byte-for-byte against the issue's own claims, tree at 2026-08-10:**

`relay-automation/marathon-drive.sh:189-208` — three branches (comment at 190-196 asserts the
exclusion):

```
189  if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
197    if [[ -d "$ROOT/.git" ]]; then
198      _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
199    elif [[ -f "$ROOT/.git" ]]; then
200      _git_common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
201-205  [common-dir branch]
206    else
207      _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
208    fi
```

`relay-automation/relay-drive.sh:142-151` — **two** branches, no `-f` case, exactly as the issue
describes:

```
142  if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
147    if [[ -d "$ROOT_DIR/.git" ]]; then
148      _lock="$ROOT_DIR/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
149    else
150      _lock="$ROOT_DIR/.relay-driver.lock";     _lock_label=".relay-driver.lock"
151    fi
```

`utils/py/relay_drive.py:385-391` carries the identical 2-branch shape (no `isfile`/common-dir case)
— confirmed, matching the issue's claim about the default Python runtime.

`utils/swarm-preflight.sh:821` confirmed: `RELAY_WORKTREE_ISOLATION=1` is present in the invocation
`swarm-preflight` recommends, so the linked-worktree topology is not exotic — it is what preflight
itself creates.

**Not in the issue — finding 1: a shared resolver already exists and one driver already uses it.**
`utils/py/rtl.py:477-499` defines `driver_lock_path(root)`, a 3-branch resolver (dir / file+
`git-common-dir` / absent) whose own docstring (line 478-481) claims it matches "the DRIVER's own
write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh)".
`utils/py/marathon_drive.py:20` imports it (`from rtl import driver_lock_path`) and calls it at
`:611` — so the Python marathon driver already resolves correctly via the shared function. But
`utils/py/relay_drive.py` does **not** import it; it still constructs the path inline (385-391). So
`rtl.py`'s own comment is currently false about half of what it claims to describe — a second wrong
comment in this area, not just `marathon-drive.sh:195-196`. This resolver was built by `#448`
(closed, PR #449) specifically for read-only lock *consumers* (`marathon-ls.sh`,
`utils/hq/marathon-live.sh`, `skills/relay-xyz/find-harness.sh`); `#448`'s own doc explicitly excludes
`relay-drive.sh`/`relay_drive.py` as this issue's scope. A Bash twin of the same resolver,
`relay-automation/driver-lock-lib.sh:20-35` (`driver_lock_path_for_repo`), is sourced only by
`marathon-ls.sh` — not by `marathon-drive.sh` (which keeps its own inline copy, left byte-unchanged
by #448 since it was already correct) and not by `relay-drive.sh`.

**Not in the issue — finding 2: this write-set is the marathon driver's own turn loop.**
`relay-automation/marathon-drive.sh:27-28`: "calls relay-drive.sh unmodified, runs the pre-advance
gate, emits phase events, and saves the transcript. Does NOT reimplement any loop logic —
relay-drive.sh IS the loop." `marathon-drive.sh:82` and `utils/py/marathon_drive.py:474` both default
to invoking exactly `relay-automation/relay-drive.sh` as that subprocess. The buggy 2-branch lock
code only actually *executes* when `relay-drive` is launched standalone, not nested inside a running
marathon: `marathon_drive.py:649` (and `marathon-drive.sh:245`) sets `RELAY_DRIVER_LOCKED=1` in the
environment after acquiring its own (correct) lock, and both `relay-drive.sh:142` and
`relay_drive.py:385` skip their own lock-acquisition block entirely when that variable is already
`1`. So the actual collision the issue describes is between two *independently launched, top-level*
drivers — one via `marathon-drive`, one via a standalone `relay-drive` invocation (e.g. `/relay-xyz`)
— from two linked worktrees of the same repo. But `relay-drive.sh`'s *other* code still runs, fresh,
as a subprocess on every single phase turn a marathon takes. See Reversibility & blast radius.

Both target files are GH-308 frozen twins: `relay-automation/relay-drive.sh` : `utils/py/relay_drive.py`
is `TWINS` entry #8 in `test/gh308-frozen-twin-guard.sh:21`. Both open with `# FROZEN (GH-308): Python
is authoritative — do not make behavior changes here` (`relay-drive.sh:2`), and both currently default
to Python at runtime: `${XYZ_PYTHON-1}` (`relay-drive.sh:9`) evaluates to `1` when the variable is
unset, so the in-file comment "Default (unset/0) runs... Bash" (`relay-drive.sh:7-8`) is itself stale
relative to the repo-wide Python-default flip — a third stale comment nearby, noted for completeness,
not part of this issue's scope to fix.

## Acceptance

*Issue #376 contains no `## Acceptance` section — verified against the fetched issue body. There is
no verbatim block to copy. Criteria are authored in the section immediately below, kept clearly
separate from this heading per the drafting brief's instruction never to put authored criteria inside
`## Acceptance` itself.*

## Acceptance criteria — authored (the issue has none)

- [ ] From a **real** linked worktree (`.git` is a file — created with `git worktree add`, not
      simulated), `relay-drive.sh`'s standalone lock-acquisition path (i.e. `RELAY_DRIVER_LOCKED`
      unset, the same condition already gating that code block at `relay-drive.sh:142`) resolves to
      the identical absolute lock path that `marathon-drive.sh`'s own resolution
      (`marathon-drive.sh:189-208`) would compute for the same repo.
- [ ] `utils/py/relay_drive.py`'s equivalent standalone lock-acquisition path resolves to the
      identical path `utils/py/marathon_drive.py` already resolves via `driver_lock_path`
      (`marathon_drive.py:611`) for the same repo.
- [ ] `relay-drive.sh` and `relay_drive.py` agree with **each other**, byte-for-byte, on all three
      branches (`.git` dir / `.git` file / no `.git`) — not just each independently agreeing with the
      marathon side.
- [ ] A test demonstrates this against a real `git worktree add` fixture, not asserted in prose, and
      includes a negative control per #419: the OLD 2-branch logic (shown verbatim in The defect,
      above) replayed against the identical fixture is shown to diverge from marathon-drive's path,
      before the fixed logic is shown to agree — mirroring the shape `test/gh448-driver-lock-resolver.sh`
      already established for the sibling defect.
- [ ] `relay-automation/marathon-drive.sh` and `utils/py/marathon_drive.py`'s own lock resolution are
      unchanged (both already correct, per The defect above).
- [ ] `utils/py/rtl.py` and `relay-automation/driver-lock-lib.sh` are unchanged in behavior — the fix
      may import/call `driver_lock_path` / `driver_lock_path_for_repo` but must not modify either.
- [ ] `relay-drive.sh` carries a `Frozen-twin-exception:` trailer naming the file if it is edited (per
      GH-308; `utils/py/relay_drive.py` is the authoritative side).
- [ ] Ships as a direct PR against `development`. Never dispatched as a marathon or relay lane — see
      Reversibility & blast radius for why.
- [ ] The mode-aware lockout redesign the issue floats as a "broader shape worth considering" is
      explicitly out of scope for this change (see non_goals).

There is no `## Acceptance — deviations from the issue` section: there is no verbatim block to
deviate from, so that heading is omitted rather than left empty.

## Litmus tests

- **A real `git worktree add` fixture is the only evidence that counts.** GH-448's own test makes
  this argument for the sibling defect; the same reasoning applies here — a path-string assertion
  with no real linked worktree cannot exercise git's actual `--git-common-dir` behavior.
- **Negative control per #419**: replaying the pre-fix 2-branch logic against the same fixture must
  be shown, in the test itself, to land somewhere the marathon-side lock is *not* — before the fixed
  logic is shown to agree. A fix that skips this is not evidence, the same standard #358 and #448
  were both held to.
- **Bash/Python parity, not just each twin's individual correctness against marathon-drive.** The two
  `relay-drive` implementations must agree with each other, not merely each happen to agree with the
  marathon side independently — GH-448's own parity test (Section A) is the direct precedent.
- **A green `validate.sh` proves nothing here.** Nothing in the existing suite stands up two
  concurrent top-level drivers from two linked worktrees of the same repo; a passing suite is
  consistent with the defect being completely untouched.
- **Check the fix against the comment, not just the code.** `marathon-drive.sh:195-196` ("Same lock
  NAME as relay-drive so a marathon and a relay driver still mutually exclude in one clone") is
  currently false from a linked worktree. After a real fix, a reviewer should be able to construct
  the worktree, run both drivers, and find the comment now true — not merely find that the diff
  "looks right."

## Reversibility & blast radius

**Major, atypically for a change the issue itself calls "small and symmetrical" — because of what
this write-set touches, not what it changes.** `relay-automation/relay-drive.sh` and
`utils/py/relay_drive.py` are not an inert path-resolution helper: `marathon-drive.sh:27-28` states
outright that it "calls relay-drive.sh unmodified... Does NOT reimplement any loop logic —
relay-drive.sh IS the loop," and both `marathon-drive.sh:82` and `utils/py/marathon_drive.py:474`
invoke exactly this file as the per-phase-turn subprocess by default. A marathon builder turn that
edited it would have the very **next** phase-turn subprocess exec — a fresh process launch from disk,
not a sourced-and-cached kernel function — run the changed script. That is at least as sharp a
self-modification hazard as the `relay-turn-lib.sh`/`rtl.py` case the drafting brief calls out by
name, even though `relay-drive.sh` is not itself on that named list. **This must ship as a direct PR
against `development`; it cannot be fired as a marathon lane or a relay lane.**

Both target files are GH-308 frozen twins (`test/gh308-frozen-twin-guard.sh:21`, TWINS entry #8);
Python (`relay_drive.py`) is authoritative, and any behavior-changing edit to the Bash side
(`relay-drive.sh`) needs a `Frozen-twin-exception:` trailer naming the file.

**What breaks if this goes wrong:** getting the resolved path wrong in a *new* way could make two
separate drivers silently agree on a lock path neither correctly protects — worse than today's status
quo, where at least the marathon side resolves correctly. Getting it right changes only path
resolution, not acquisition, reclaim, or release semantics (mirroring #448's own explicit non-goal on
this exact code area), so the change is narrow by construction.

**How hard to undo:** trivial. Revert the one commit. The lock itself is a transient `mkdir`
directory, never committed to git, and self-heals via the existing stale-holder reclaim logic
(`relay-drive.sh:152-164` / `relay_drive.py:394+`) regardless of which path-resolution version is
live.

## Swarm Preflight Contract

**Not fireable as a marathon lane** — recorded here in the exemplar's shape for completeness and
because it documents what a direct-PR reviewer should check, not because `swarm-preflight` should
ever dispatch it.

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "relay-automation/relay-drive.sh", "pattern": "git-common-dir" },
    { "type": "grep_absent", "path": "utils/py/relay_drive.py", "pattern": "driver_lock_path" }
  ],
  "artifacts":     ["relay-automation/relay-drive.sh", "utils/py/relay_drive.py", "test/gh376-relay-drive-lock-parity.sh"],
  "artifacts_new": ["test/gh376-relay-drive-lock-parity.sh"],
  "remediation":   { "source": "issue #376", "criteria": "make relay-drive's Bash and Python lock-path resolution agree with marathon-drive's from a linked worktree — ranking summary only, NOT the definition of done (that is the verbatim Acceptance criteria section above). NEVER dispatch this as a marathon or relay lane: relay-drive.sh is the marathon driver's own per-turn-loop subprocess (marathon-drive.sh:27-28), so this write-set is self-modifying in substance. Ship as a direct PR." },
  "lanes": { "agy_safe": [], "orchestrator_only": ["relay-automation/relay-drive.sh", "utils/py/relay_drive.py"] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): both are `grep_absent`, so each reports
`landed` only once its marker string *appears*. `git-common-dir` is 0 matches in
`relay-automation/relay-drive.sh` today (confirmed) — chosen because `marathon-drive.sh`'s own
(already-correct, frozen) Bash side resolves the worktree branch inline with exactly that git flag
rather than sourcing `driver-lock-lib.sh`, and `#448` left that inline-vs-shared choice alone for the
Bash frozen twin; the parallel, precedent-consistent fix for `relay-drive.sh` is the same inline
3-branch copy, not a new sourcing dependency. `driver_lock_path` is 0 matches in
`utils/py/relay_drive.py` today (confirmed) — chosen because `utils/py/marathon_drive.py` already
imports that exact shared function (`marathon_drive.py:20`) rather than duplicating the branches in
Python, and the parallel, precedent-consistent fix for `relay_drive.py` is to do the same. If an
implementation takes a different concrete shape than either precedent, these two specific probes may
need updating before firing — the acceptance criteria above are the actual definition of done, not
these markers.

## Provenance

Surfaced by the `#354` code review (`5660aae`, "3 of 5 collision claims overturned"), which did not
carry its own issue; filed as `#376`. Captured 2026-08-10 as part of Nightwatch batch 2. Every
locking claim in the issue body was independently re-verified against `development` at the current
tree before this doc was written; none were found stale. Two additional findings not present in the
issue — the already-shipped `#448` shared resolver, and the self-modification hazard in the write-set
— were found during that verification and are recorded above.
