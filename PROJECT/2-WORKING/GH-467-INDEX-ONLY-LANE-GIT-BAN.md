---
gh_issue: 467
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/467
title: "A builder is told \"Do NOT run git\", so a lane whose deliverable is an index change cannot perform its own work"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. The issue has NO ## Acceptance section (it is a scoping/analysis writeup, not a criteria list) — acceptance authored in a separate section below, deliberately scoped to the cheapest of the issue's three named options. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 3
risk: 3
effort: 2
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#438 — the issue this was split out of. Phase 1 (shipped #458) made a removal register as progress; Phase 2 (shipped #464) made an unmet acceptance probe escalate instead of falsely passing. Neither made the work possible — PROJECT/3-COMPLETED/GH-375-385-438-PREFLIGHT-TOKEN-DELTA.md:146-153 names this exact remainder and explicitly defers it."
  - "#401 — the observed instance. Its criterion 4 (untracking phases/p1/RELAY.md) is the index-only lane that could not be built by a marathon lane and was performed directly instead (commit 81b3127, PR #466)."
  - "#245 / #289 — the 'who owns the write' precedent the issue cites and explicitly declines to re-litigate here: GH-245 added a fast-refusal for a --target-root REVIEW turn that cannot report; GH-289 found the same guard's `((REVIEW_ONCE))` conjunct left BUILD turns uncovered. Same shape of question (who is allowed to act on behalf of the harness, and when does it refuse instead of guessing) as this issue's options 1 and 2."
  - "#13 / #14 / #42 — why the ban is load-bearing. #13/#14: a worktree-preserve branch was dead code, so a concurrent peer's ROOT HEAD move was treated as a self-commit and reset, discarding real work (root-caused and fixed 2026-06-29, PROJECT/3-COMPLETED/RELAY-CONTAINMENT-HARDENING.md:31). The in-ROOT backstop this issue's rationale draws on separately guards against a genuine self-commit by saving the discarded HEAD to `refs/relay-orphan/<sha>` (relay-turn-lib.sh:1047). #42 is the concurrent-ROOT-HEAD hazard the same lock/guard machinery defends against."
  - "#465 — the Litmus-vs-Nightwatch scope boundary (RELEASES.md:25-47) this issue's own framing uses to classify itself: 'the builder cannot perform the work it was dispatched to do' is a run-lifecycle/containment defect, not a false-verdict defect, so it is Nightwatch."
non_goals:
  - "Widening the builder's git allowlist in general, or relaxing rtl_enforce's commit-bypass guard (relay-turn-lib.sh:1026-1053, rtl.py) for any lane not explicitly marked. The guard's default behavior — a self-commit fails the turn — is unchanged for every lane this doc does not name."
  - "Choosing between the issue's option 1 (a declared index operation performed by the harness after the turn) and option 2 (a narrow allowlist verb enforced in rtl_enforce). Option 1 edits the driver (relay-automation/marathon-drive.sh, utils/py/marathon_drive.py — the code that renders the builder packet and commits on the lane's behalf); option 2 edits the turn kernel (relay-automation/relay-turn-lib.sh, utils/py/rtl.py — the code that runs rtl_enforce itself). Both are barred from being a marathon lane by this repo's own self-modification rule (a lane cannot edit the code gating its own run), and the issue itself declines to choose between them pending the GH-245/GH-289-style write-ownership decision. This doc does not make that decision."
  - "Making an index-only lane completable. This lane only makes the shape detectable and refusable at preflight time — a builder still cannot perform git-index-only work after this ships. That is the honest, cheaper half; the durable half (making it completable) is future work."
goal: >
  A builder dispatched to a marathon lane is told, verbatim: "Do NOT run git. Do NOT touch any other
  file — the harness commits for you." (relay-automation/marathon-drive.sh:1017/1023, mirrored in
  utils/py/marathon_drive.py:1757/1772). That instruction is correct for nearly every lane and is
  load-bearing — rtl_enforce's commit-bypass guard exists because agents committing mid-turn have
  corrupted peer state before (relay-turn-lib.sh:1032-1046, root-caused GH-13/#14). But a lane whose
  entire deliverable IS a git-index operation — `git rm --cached`, a mode change, a rename recorded
  without a content edit — has no sanctioned way to act: the builder is banned from the only command
  that could do the work. #438 Phase 2 made this fail honestly instead of falsely passing; it did not
  make it possible, and the one observed instance (GH-401 criterion 4) had to be performed directly by
  the orchestrator instead of a marathon lane (commit 81b3127, PR #466). Make the shape detectable and
  refusable at preflight time — so a marathon declines to dispatch a lane it structurally cannot
  complete instead of discovering that at escalation time — without touching the ban that protects
  every other lane.
---

# GH-467 · a builder banned from git cannot build an index-only lane

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch. Verified the exact packet text, the ban's rationale, and the observed workaround against source (all file:line below). The issue has no `## Acceptance` section — it is a three-option scoping writeup that explicitly declines to pick one — so acceptance criteria are authored here, deliberately scoped to only the cheapest of the three named options. | Preflight, then fire. The other two options stay open follow-on work, gated on the same write-ownership decision GH-245/GH-289 made for `--target-root` turns. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/467

## The defect

**The exact packet text.** The rendered builder instruction, verified live in both the frozen Bash
twin and its authoritative Python twin:

- `relay-automation/marathon-drive.sh:1017` (artifact lane): *"Edit ONLY these paths: ${REL_RELAY} and
  ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."*
- `relay-automation/marathon-drive.sh:1023` (relay-only lane): *"Edit ONLY ${REL_RELAY}. Do NOT run
  git. Do NOT touch any other file — the harness commits for you."*
- `utils/py/marathon_drive.py:1757` and `:1772` — byte-for-byte the same two lines in the authoritative
  Python twin (`relay-automation/marathon-drive.sh` : `utils/py/marathon_drive.py` is twin #10 of 12 in
  `test/gh308-frozen-twin-guard.sh:23` — Bash is frozen, Python is authoritative).

This is `BUILDER_SCOPE_LINE`, baked directly into the rendered relay file the builder reads
(`marathon-drive.sh:1028` `cat > "$RELAY_FILE"`), so there is no packet path that omits it.

**Why the ban exists, verified in the enforcement code itself.** `rtl_enforce` (`relay-automation/
relay-turn-lib.sh:1026`) is the commit-bypass guard: if `HEAD` moved during a turn, in the in-ROOT
(non-worktree) case it treats that as a forbidden self-commit, saves the discarded HEAD to
`refs/relay-orphan/<sha>` for recovery, resets to the pre-turn HEAD, and exits 6, failing the whole
turn (`relay-turn-lib.sh:1039-1051`). The comment at `:1040-1046` states the reasoning directly: *"the
agent ran in ROOT and may have committed off-lane changes... A concurrent PEER commit in this mode is
indistinguishable from a self-commit here."* The worktree-isolated branch just above it
(`:1032-1038`) documents the real incident that shaped this: *"a blind `reset --hard` here orphaned a
peer agent's commit on 2026-06-23 (recovered via reflog)"* — root-caused as GH-13/GH-14 dead code in
the worktree-preserve path, fixed 2026-06-29 per `PROJECT/3-COMPLETED/RELAY-CONTAINMENT-HARDENING.md:31`.
`GH-42` (`PROJECT/3-COMPLETED/GH-42-CONCURRENT-RELAY-ROOT-HEAD.md`) is the companion concurrent-ROOT-HEAD
hazard the same driver lock (`marathon-drive.sh:210-215`) defends against. So the ban is not
over-caution — it is the documented fix for a real, previously-observed corruption of a peer agent's
work, and it must not be loosened for the general case.

**What #438 already fixed, and what it explicitly left open.** `PROJECT/3-COMPLETED/
GH-375-385-438-PREFLIGHT-TOKEN-DELTA.md` records Phase 1 (shipped #458): a lane whose deliverable is a
*removal* now registers as progress (`:83-86`). Phase 2 (shipped #464): a lane whose `fix_probes` still
read `unfixed` after the build now escalates as `acceptance-probes-unmet` instead of reporting `STATUS:
Approved, gate passed` over an unchanged tree (`:96-164`). The same doc names this issue's remainder
verbatim at `:146-153`: *"The builder is told `Do NOT run git`, so a lane whose entire deliverable is
`git rm --cached`, `git update-index --chmod`, or `git mv` has no sanctioned way to act... A follow-on
needs either a per-lane opt-in that widens the builder's git scope, or a harness-executed post-build
index step the builder can request."* — i.e. this issue is that named follow-on, not new speculation.

**The observed instance, verified against the commit itself.** GH-401's own criterion 4 (`PROJECT/
3-COMPLETED/GH-401-DRY-RUN-MUTATES-REPO.md:82`) required untracking `phases/p1/RELAY.md`. `git log
--oneline -- phases/p1/RELAY.md` shows it was untracked by commit `81b3127`
(`feat(GH-390, GH-461): lift the gate-guard seam to module scope, and untrack phases/p1/RELAY.md`),
merged via PR #466 (`git log --grep=466` → `f540cd5 Merge pull request #466 from .../graft/gh390-gh461`).
The commit message itself states *"This is a graft onto current development, not a merge"* — i.e. a
direct, orchestrator-authored commit recovering work from an abandoned branch, not a marathon-driven
builder turn. `git ls-files phases/p1/RELAY.md` returns nothing today, confirming the file is in fact
untracked. This matches the issue's claim precisely: the index-only deliverable could not be
completed by a builder and was done directly instead.

**What is NOT currently wired to prevent mis-dispatch.** `swarm_preflight.py`'s `lane_plan()`
(`utils/py/swarm_preflight.py:199-234`) already classifies each artifact path as `orchestrator_owned`,
`codex_lane`, or `agy_lane` against a `lanes.orchestrator_only` / `lanes.agy_safe` contract field — the
same field named in the exemplar's and GH-401's own preflight contracts. But `lane_plan()` and
`orchestrator_owned` have **no caller outside `swarm_preflight.py` itself** (verified: `grep -rn
"lane_plan\|orchestrator_owned" utils/py/*.py relay-automation/*.sh` matches only inside
`swarm_preflight.py`). It is advisory report output today, not a dispatch gate — nothing currently
makes `swarm-preflight` refuse to mark a lane fireable because its deliverable is index-only. Option 3
in the issue ("preflight refuses to dispatch") describes new behavior, not an existing one.

## Acceptance

The issue has **no `## Acceptance` section**. It is a three-option scoping analysis
("What a fix has to respect") that explicitly declines to choose between its options: *"Not
choosing here — it needs the same 'who owns the write' decision that GH-245/GH-289 settled for build
turns against a target root."* Per the drafting brief, criteria are therefore authored below in a
separate, clearly-labelled section rather than placed inside `## Acceptance`.

## Authored acceptance criteria (the issue has none)

Scoped deliberately to the issue's own option 3 — *"declare such lanes orchestrator-only and have
preflight say so... the cheapest and is honest"* — because it is the only one of the three that does
not touch the driver (`marathon-drive.sh` / `marathon_drive.py`) or the turn kernel
(`relay-turn-lib.sh` / `rtl.py`), and so is the only one that can plausibly ship as a marathon lane
itself rather than a direct PR (see Reversibility & blast radius).

- [ ] A phase whose preflight contract marks its deliverable as an index-only change (a `git
  rm --cached`, mode-change, or rename-only edit, however the contract schema chooses to declare it)
  and is not also listed as `orchestrator_only` for that path is reported **BLOCKED** by
  `swarm-preflight`, with a diagnostic naming the reason — not silently marked fireable and then
  discovered un-completable at escalation time.
- [ ] The same lane, once correctly declared `orchestrator_only`, still preflights and dispatches
  exactly as an orchestrator-owned lane does today — this criterion adds a refusal for the
  *undeclared* case, not a new execution path for the declared one.
- [ ] `rtl_enforce`'s commit-bypass guard and the builder/reviewer "Do NOT run git" instruction are
  **byte-identical** for every lane not touched by this change — verified by a diff of
  `relay-automation/relay-turn-lib.sh`, `utils/py/rtl.py`, `relay-automation/marathon-drive.sh`, and
  `utils/py/marathon_drive.py` showing no lines changed in those four files.
- [ ] `#438` Phase 2's escalation behavior (`acceptance-probes-unmet`) is unchanged for any lane this
  criterion does not cover — a regression here would reintroduce the false-pass #438 fixed.
- [ ] A regression test drives an unscoped index-only lane through `swarm-preflight` and asserts
  `BLOCKED`, and a correctly-scoped one and asserts unchanged behavior — registered in `validate.sh`.
- [ ] The issue's options 1 and 2 are **not** implemented by this work and remain named as open
  follow-ons pending the write-ownership decision the issue itself defers.

## Acceptance — deviations from the issue

The issue names three candidate shapes and refuses to choose. This doc chooses one for itself
(option 3) rather than authoring criteria that could be satisfied by picking any of the three,
because "a decision was made and recorded" is a criterion this same repo has already learned not to
trust: `PROJECT/3-COMPLETED/GH-401-DRY-RUN-MUTATES-REPO.md:92` records that an earlier draft's
*"decided and the decision recorded"* wording was rejected in review because *"any decision satisfied
[it] including 'yes, no reason given.'"* The same trap applies here.

**Flagged explicitly, per the drafting brief:** any acceptance criterion that amounts to simply
widening the builder's git allowlist, or relaxing `rtl_enforce`, is under-specified and must not be
accepted without also specifying how it avoids reintroducing the GH-13/#14 self-commit hazard the ban
exists to prevent. Option 2 in the issue ("an explicit narrow allowlist verb... enforced in
`rtl_enforce`") reads as narrow but is literally an edit to the turn kernel that runs the
commit-bypass guard itself — the most protected file in this repo's own self-modification rule, not a
small carve-out. Option 1 ("a declared index operation... performed by the harness after the turn")
is safer in shape but edits the driver that renders the packet and performs the commit
(`marathon-drive.sh` / `marathon_drive.py`), which the self-modification rule also bars from being a
marathon lane. Neither is adopted here for that reason; both stay named as follow-ons.

## Litmus tests

- **The ban must still fire for a plain content-edit lane.** Run an ordinary artifact lane through the
  post-fix harness and confirm the rendered packet still reads "Do NOT run git" and that a builder
  self-commit still fails the turn (`rtl_enforce` exit 6). No test in `test/` currently asserts the
  "Do NOT run git" string's presence (`grep -rl "Do NOT run git" test/` matches nothing) — a real fix
  should add one, since nothing today would catch that string being silently dropped.
- **An undeclared index-only lane must BLOCK, not silently dispatch.** The negative control is GH-401
  criterion 4's own shape (untracking a file) run through `swarm-preflight` without the new
  declaration — it must read `BLOCKED`, not `ready`, before the fix, and `BLOCKED` with a named reason
  after.
- **A declared-and-scoped lane must be unaffected.** The existing `orchestrator_only` per-artifact
  routing in `lane_plan()` must keep working exactly as it does today for every contract that already
  uses it (e.g. GH-401's own `.mcp.json`-adjacent contracts) — this is a new refusal path added
  alongside the existing report, not a replacement for it.
- **A green `validate.sh` proves nothing about the ban's wording.** The suite does not read the
  rendered relay-file prose; only a grep-based regression test does.

## Reversibility & blast radius

**Small-to-Medium, and it must ship as its own marathon lane candidate, not a self-referential one.**
The authored criteria above touch only `utils/py/swarm_preflight.py` (adding a check inside the
existing `BLOCKED`/`AMBIGUOUS`/`ready` verdict machinery at `swarm_preflight.py:1393-1396`) plus a new
regression test. `swarm_preflight.py` is the authoritative half of frozen twin pair #11
(`utils/swarm-preflight.sh:utils/py/swarm_preflight.py`, `test/gh308-frozen-twin-guard.sh:24`) — if the
Bash twin needs no parity edit (the GH-401 Phase 2 precedent kept an equivalent decision Python-lane
only, `PROJECT/3-COMPLETED/GH-401-DRY-RUN-MUTATES-REPO.md:142`), no `Frozen-twin-exception:` trailer is
needed; if it does, one is required.

Critically, **this lane does NOT touch the running driver or the turn kernel**: `swarm-preflight` runs
once, before a marathon fires, to decide fireability — it is not re-sourced mid-turn the way
`relay-turn-lib.sh` is re-sourced by the reviewer turn after the builder edits it. That is what makes
option 3 (unlike options 1 and 2) buildable as an ordinary marathon lane at all, per this repo's own
rule: *"A lane whose write-set includes the running driver (`marathon-drive.sh`, `marathon_drive.py`)
or the turn kernel (`relay-turn-lib.sh`, `rtl.py`) cannot be a marathon lane — it would edit the code
gating its own run."* Options 1 and 2, if picked later, would need to ship as direct PRs for exactly
that reason.

**Failure direction if the new check is wrong:** it fails closed, not open — a bug would at worst
over-block a legitimate lane (denies dispatch, annoying but safe), never under-block one into a
silent false pass. That is the opposite failure direction from the one #438 fixed, which is the
correct direction to err in here.

**Undo:** revert the one commit; `lane_plan()`'s existing report behavior is unchanged either way.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "index_only" },
    { "type": "path_absent", "path": "test/gh467-index-only-lane-blocked.sh" }
  ],
  "artifacts":     ["utils/py/swarm_preflight.py", "test/gh467-index-only-lane-blocked.sh", "validate.sh"],
  "artifacts_new": ["test/gh467-index-only-lane-blocked.sh"],
  "remediation":   { "source": "issue #467", "criteria": "an undeclared index-only lane is reported BLOCKED by swarm-preflight instead of dispatched to a builder that cannot complete it — ranking summary only, NOT the definition of done (that is the authored acceptance block above)" },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```

**The `path_absent` probe is not decoration.** `swarm-preflight` refuses a contract whose
`artifacts_new` entry has no matching `path_absent` probe on the same path — verified on 2026-08-11,
when this contract was rejected outright with `CONTRACT ERROR: artifacts_new entry
'test/gh467-index-only-lane-blocked.sh' has no matching fix_probes entry of type path_absent on the
same path`, and the lane could not be preflighted at all. The rule is sound: an `artifacts_new` entry
declares a file the fix will CREATE, so its absence is precisely the bug-still-present evidence, and
a contract that names a new file without a probe for it can be satisfied by a builder that never
creates it.

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` reports the fix as still
required while the marker string the fix introduces — a concrete name for the new index-only
declaration/check, `index_only` — is still absent from `swarm_preflight.py`. Today no such marker
exists (verified: `grep -n "index_only" utils/py/swarm_preflight.py` matches nothing), which is
exactly the bug this lane exists to fix — an index-only lane has no way to declare itself and
`swarm-preflight` has no code path checking for one. Once the declaration and its BLOCKED-verdict
check are added under a name containing `index_only`, the probe flips to `landed` and the lane is no
longer fireable, which is the intended behavior. The exact identifier is a naming choice for
whoever builds this; the probe is written against the concept, not a pre-existing API.

## Provenance

Split out of #438 by the operator on 2026-08-10 "so the remainder does not get buried in a closed
issue's working doc" (issue body). The rationale for the git ban, the #438 Phase 1/2 history, the
GH-401 observed instance, and the RELEASES.md Litmus/Nightwatch scope boundary were all independently
re-verified against source for this capture doc on 2026-08-10, not taken on the issue's word — see
file:line citations throughout. `gh issue view` was unavailable in this environment (TLS verification
failure against api.github.com under the sandbox); the issue body was read from the provided capture
file instead, and every factual claim in it was cross-checked against the live tree and git history.
