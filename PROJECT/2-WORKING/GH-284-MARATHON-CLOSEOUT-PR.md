---
gh_issue: 284
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284
title: "marathon: closeout PR, run-log back to the lane issue, and release-driven marathon selection"
status: "Phase 1 SHIPPED 2026-07-28 (PR #316, merged 243a310). Phases 2-6 scoped only, not contracted — Phase 6 (feedback loop) added 2026-07-28 with GH-315 as its first specimen."
created: 2026-07-23
updated: 2026-07-28
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 6
ratings_provisional: true
non_goals:
  - Auto-merging the closeout PR (explicit non-goal in the issue itself — open only, never merge/force-push/branch-create beyond what's already there).
  - Re-adding "linked marathons/issues" or a release-tag cache as FIELDS inside RELEASES.md. That exact design was already tried and deliberately rolled back as "too much data to keep current" (PROJECT/PDDA.md, RELEASES.md check rationale). The many-to-one linkage belongs in GitHub, where it maintains itself.
  - Putting lessons-learned INTO RELEASES.md. Its contract says lessons belong in CHANGELOG.md at ship time. This doc is the second home, for cross-repo portability only.
  - Auto-FILING new GitHub issues per marathon run (see Phase 2 rationale — it would poison the /10days scan input).
  - Making any of Phases 2-6 a blocker on Phase 1 shipping.
goal: >
  Close the loop between a marathon run and its durable record: (down) RELEASES.md defines what a
  release needs, which resolves to an issue set that drives marathon selection; (up) each marathon
  run reports back to the issues it touched, and to the release, with a machine-checkable statement
  of whether the work actually landed on trunk.
---

# GH-284 · marathon closeout PR → run-log → release-driven selection

## Status
| What was just completed | What's next |
|---|---|
| **Phase 1 SHIPPED 2026-07-28 — merged to `development` via PR #316** (`243a310`). `marathon-closeout.sh` gained `--open-only` (clean-tree safe, duplicate-PR safe); `marathon.sh` gained `--closeout-pr` with closeout failure non-fatal to the marathon's exit code. Built by codex, approved by agy, `test/marathon-closeout.sh` 25/0, `test/marathon.sh` 33/0, `validate.sh` exit 0. **Verified by direct inspection of the deliverable, not the runner's summary line** — which matters, because the first fire of this very lane reported success while building nothing (#315). **Phase 6 scoped 2026-07-28** with #315 as its first specimen. | Phases 2-6 remain scoped-only and need their own contracts at promotion. Recommended order: **Phase 2 next** (run-log) — it is the sensor Phase 6 depends on, and it carries the `landed on trunk` + `driver still running` fields that would have caught all three observation defects found while shipping Phase 1. |

## Why this doc grew (read before scoping)

#284 was a small, well-specified, ready-to-fire feature (2/2/2). It has been widened into a 6-phase
program. That is a real scope-creep risk, so the mitigation is structural: **Phase 1 keeps its
original contract, byte-for-byte, and ships on its own.** Everything added here is downstream of it
and separately promotable. If Phases 2-6 stall, Phase 1 still delivered (it did — merged in PR #316).

The reason to keep them in one doc rather than a sibling issue: they are the same dataflow. A
closeout PR, a run-log comment, and a release rollup are three surfaces on one loop. Splitting them
across issues is how you end up with two half-overlapping mechanisms — which is exactly what
already happened once, when #281's closeout gap was split out to #284 and then sat unfired.

## The loop (this is the whole design in one picture)

```
  RELEASES.md  ──(1) release defines scope──▶  issue set (GitHub milestone)
       ▲                                              │
       │                                              │ (2) marathon selection
  (4) rollup: % of release landed                     ▼
       │                                        MARATHON.yaml lanes
       │                                              │
       └──(3) run-log: did it land on trunk? ◀────────┘
```

Down-direction (1→2) is *planning*: what does this release need, and what marathon does that imply.
Up-direction (3→4) is *recording*: what actually happened, and did it really land.

Today only the middle exists. Both ends are manual, which is why they drift.

## Evidence this is worth building (from the 2026-07-27 /10days sweep)

Four of ~22 issues in a single 10-day window had the work and the record out of sync:

| Issue | Drift |
|---|---|
| **#303** | 9 commits stranded on a branch, **no PR ever opened**, `qwen-reliability-loop.sh` absent from `development`, ~70 commits behind. Issue comments read as *finished*. It was nearly closed on narrative alone. |
| **#274** | Shipped via PR #277; issue left open, doc stale in `2-WORKING`, no CHANGELOG entry. |
| **#292** | Shipped via PR #309; issue left open, no CHANGELOG entry. |
| **#294** | Shipped via PR #309; issue left open, no CHANGELOG entry. |

The cost is not tidiness. Reconstructing that state took a five-subagent fan-out, and #303 was one
careless close away from losing validated work permanently. **The runner knew every one of those
facts at the time and discarded them.**

### Why existing telemetry does not already solve this

`XYZ.json` (GH-75) already records completion telemetry, and four scripts already emit it —
`marathon-drive.sh`, `marathon.sh`, `relay-drive.sh`, `relay-turn-lib.sh`. So the emit points exist
and the marginal cost of another sink is low.

But `XYZ.json` is **gitignored** (`.gitignore:14`). It is machine-local and invisible by
construction — GH-312 (2026-07-27) had to actively stop `xyz-sync update` from deleting it, since
nothing under a gitignored path is recoverable from git. It is an excellent local signal and a
useless institutional one. That asymmetry is the entire argument for a GitHub-side record.

---

## Phase 1 — the closeout PR (SHIPPED 2026-07-28, PR #316)

> Original 2026-07-23 scope. Nothing below this heading was modified on 2026-07-27.

Well-specified by the issue itself: exact seam, step-by-step plan, acceptance criteria, and explicit
non-goals (no merge, no force-push, no branch creation). Confirmed unimplemented — no matching
commits/PRs, no capture doc, no test file existed before this one.

### Touch surface (confirmed by reading both files in full)

- `relay-automation/marathon-closeout.sh` (155 lines): currently always runs
  add → commit → push → PR-create → checks → merge → switch → pull as one atomic sequence. Add an
  `--open-only` (or `--no-merge`) flag that stops after `gh pr create` (skips `gh pr checks`,
  `gh pr view --json mergeable`, `gh pr merge`, `git switch`, `git pull`). Guard `git commit` against a
  clean tree (`git diff --cached --quiet` check before committing) so a no-op run doesn't hard-fail.
  Query for an existing open PR on `HEAD_BRANCH` before `gh pr create` to avoid a duplicate-PR failure.
- `relay-automation/marathon.sh` (234 lines): success tail is lines ~224-234, right after the phase
  loop, before `TICK_BIN log marathon.complete`. Add a `--closeout-pr` flag, wired in there, that
  builds deterministic PR notes from `PLAN_NAME`/phase count/tick events and invokes
  `marathon-closeout.sh --open-only`. A PR-creation failure should be logged but must NOT propagate to
  the marathon's own exit code (the marathon itself already succeeded).
- **Correction 2026-07-23 (swarm-preflight AMBIGUOUS catch):** `test/marathon-closeout.sh` already
  exists — a GH-273 Phase 3 regression test for the CURRENT closeout behavior (hermetic, PATH-shadowed
  git/gh stubs). It is unrelated to this issue's new flag but the filename collides with what would
  have been a "new" test file. Extend the EXISTING file with new cases (success / no-merge /
  notes-content / duplicate-PR / PR-creation-failure for `--open-only`/`--closeout-pr`), reusing its
  existing PATH-shadowed git/gh stub pattern — do not create a second file.
- `--help` text in both scripts needs updating for the new flag.

### Swarm Preflight Contract

> This is the ONLY contract block in this doc, deliberately. Phases 2-5 get their own contracts when
> promoted; a second block here would change what `swarm-preflight --gh-issue 284` resolves.

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-closeout.sh", "pattern": "--open-only" }
  ],
  "artifacts": [ "relay-automation/marathon-closeout.sh", "relay-automation/marathon.sh", "test/marathon-closeout.sh" ],
  "remediation": {
    "source": "issue#284",
    "criteria": "marathon-closeout.sh gains --open-only (stops after gh pr create, clean-tree-safe, duplicate-PR-safe); marathon.sh gains --closeout-pr wired into its success tail, PR-creation failure non-fatal to the marathon's own exit code; the EXISTING test/marathon-closeout.sh (GH-273 Phase 3 regression test) gets new cases covering success/no-merge/notes/duplicate/failure paths for the new flags, reusing its existing PATH-shadowed git/gh stub pattern; --help text updated in both scripts."
  },
  "lanes": { "agy_safe": [ "relay-automation/marathon-closeout.sh", "relay-automation/marathon.sh", "test/marathon-closeout.sh" ], "orchestrator_only": [] }
}
```

---

## Phase 2 — run-log back to the lane's own issue

**Comment on existing issues. Do not file new ones.**

Filing an issue per run would land those issues in `skills/10days/scan-issues.sh`'s output — it
pulls *open issues updated in the window* — so auto-generated run-logs would pollute the candidate
set of every future `/10days` and `marathon-triage` sweep. That actively degrades the tool meant to
find real work, and adds unclosed issues to a repo that just needed 9 closed in one pass.

The marathon already knows each lane's issue number (it is in `MARATHON.yaml`'s parent capture docs),
so the record can land exactly where a triager will see it.

### The field that earns the whole feature

```
landed on trunk: yes/no    ← git merge-base --is-ancestor <lane-head> origin/<trunk>
```

That single boolean is what #303 was missing. Everything else is garnish. Alongside it:

- branch name
- PR link, **or an explicit `NO PR OPENED`** (silence must not read as success)
- per-phase gate result (green/red)
- plan name + run timestamp

### Design constraints

- **Idempotent**: update a marker comment (e.g. an HTML-comment sentinel) rather than appending a new
  comment every retry. A re-fired marathon must not produce N comments.
- **Flag-gated** (`--log-github`), default off. Writing to GitHub is an outward-facing side effect
  from an automated runner.
- **Degrade, never hang**: `gh` fails under the Bash sandbox in this environment. Missing/unauthenticated
  `gh` must fall back to `XYZ.json`-only and log a line, never block the run or change its exit code
  (same rule Phase 1 already applies to PR-creation failure).
- **Never closes an issue.** Reporting only. Closing stays a human judgment — this sweep found three
  issues that *looked* done and correctly stayed open (#299 gated on operator browser review, #272 on
  the operator's own stated Bash-runtime replay, #303 stranded).

---

## Phase 3 — release tagging: the join key

**The follow-up phase requested on 2026-07-27.** To drive marathons from RELEASES.md, a release must
resolve to a *set* of issues. Today `RELEASES.md`'s `GH_URL` holds **one** link (Quicksilver → GH 308),
which cannot express a release's scope.

### Do NOT solve this inside RELEASES.md

`PROJECT/PDDA.md` records that the current light ledger **replaced an earlier design** with
"status enum, linked marathons/issues, a GitHub release-tag cache" that was "too much data to keep
current for an initial release," and that fields "grow only as a real need shows up."

Re-adding a hand-maintained issue list would walk straight back into the failure that design already
had. Put the many-to-one linkage in **GitHub**, where it maintains itself as issues are opened and
closed, and let RELEASES.md keep pointing at it with (at most) one field.

### Recommended: a GitHub **milestone** per release

- Membership is naturally exclusive — an issue belongs to one release. Matches the semantics.
- GitHub maintains open/closed rollup for free, which Phase 4 reads instead of computing.
- `gh issue list --milestone "Quicksilver" --state open --json number,title,labels` is exactly the
  query marathon selection needs — no new cache, no new file format.
- Closing a milestone is a real "release shipped" signal that can cross-check `Status: Shipped`.

RELEASES.md gains **one** field, `Milestone:`. (Zero-field alternative: repoint `GH_URL` at the
milestone URL instead of a single issue — cheaper, but it silently changes that field's meaning for
existing blocks, so it needs a migration note.)

Label (`release:quicksilver`) is the alternative if an issue must belong to several releases at once.
It buys flexibility and costs the free rollup. **See Open decisions — this is yours to call.**

---

## Phase 4 — release-driven marathon selection (closing the loop)

Turn "what does Quicksilver need?" into a marathon candidate list, reusing machinery that exists:

- `utils/pdda/pdda.sh releases-current` **already** parses RELEASES.md and prints in-progress
  entries. It is the natural front half.
- `skills/10days/` already does window-scan → verify → contract → plan → preflight. Release-driven
  selection is the **same pipeline with a different seed set**: swap "issues updated in the last N
  days" for "open issues in milestone X."
- `utils/marathon-plan.sh` already ranks and waves.

So Phase 4 is mostly a new seed source, not a new pipeline. Keep the `/10days` guardrails that
proved their worth: never mark done without evidence, re-verify defects in live source, and run the
Step 6.5 artifact-overlap diff before trusting any wave's concurrency.

Rollup direction: report `landed on trunk` counts per milestone, so "Quicksilver is 6/9 landed" is
computed from git ancestry, not from anyone's memory.

---

## Phase 6 — semi-automatic feedback → issue loop

The loop closing on itself: Phase 2's run-log is the **sensor**, a filed issue is the **actuator**.
Scoped 2026-07-27 with a real specimen already in hand (#315).

### The gap is a filter, not a reporter

Most of the machinery exists: `/file-xyz-bug` is the write end (PDDA capture + issue + ROADMAP
pointer), Sentinel (#281, shipped, inert-by-default) is the sensor, `XYZ.json` is the raw signal,
`/10days` is the verify-and-close end. What is missing is the decision of **when a signal deserves an
issue**. Without that, this becomes issue spam — which would actively damage `/10days`, whose
`scan-issues.sh` seeds from *open issues updated in the window*.

### Four pieces, in value order

1. **A stable signature.** Hash the failure *shape* — exit code + failing phase + gate name + first
   stderr line. Not timestamps, not session ids, not PIDs. Everything downstream depends on two
   occurrences of one bug producing one signature.
2. **Dedupe before filing.** `gh issue list --search "<signature>" --state all` → comment and bump a
   count on a hit, never file a second issue. This is the single most important guard.
3. **A breaker, not a hair trigger.** File only on N consecutive occurrences or a *novel* signature.
   Reuse GH-303's deterministic `loop-stop.sh` breaker rather than inventing one. One flaky gate must
   never open an issue.
4. **Propose, don't file** — this is what makes it *semi*-automatic. Draft the capture locally,
   notify, let the operator confirm. If autonomous filing is later wanted, label `auto-filed` +
   `needs-triage` so `/10days` treats it as a distinct bucket rather than ordinary intake.

### Specimen #1 — GH-315 (the bug that motivated this phase)

`marathon-drive` reported `lane_already_satisfied, reviewer approved, gate passed` and exited **0**
while building nothing, because `--relay-task` defaults to `MARATHON-<PHASE_ID>-TURN` with a constant
`PHASE_ID=p1`, matching a `done` token from an unrelated run.

What makes it the right specimen: **three independent signals agreed it succeeded** — exit 0,
"reviewer approved", and a genuinely green `validate.sh` (green *because* the tree was untouched).
A loop that only watches exit codes would have recorded a success. So Phase 6 must key on the
**deliverable**, not the runner's self-report:

> An approved lane whose declared `artifacts` show **zero diff** against the phase's base commit is a
> false success, regardless of exit code, gate colour, or reviewer verdict.

That check is cheap, deterministic, and would have caught #315 on the first fire.

### The failure class this phase actually targets

All three defects this work surfaced share one shape — **a broken observation layer, where the failure
is invisible and the obvious next action is destructive**:

| # | Defect | Destructive next action it invites |
|---|---|---|
| 1 | `lane_already_satisfied` reported as success (#315) | trusting an unbuilt lane; merging nothing |
| 2 | Sandboxed observer cannot see processes → live run reads as "finished" | firing a second driver against a live one (GH-183/187 race) |
| 3 | Driver lock read as "stale" while its PID was alive | clearing a live run's lock |

None is unit-testable; all three live at the seam between a runner and its observer. Concrete
consequences for the design:

- `landed on trunk` needs the sibling **`driver still running`**, derived from the lock PID — never
  from a process-name grep (which also fails outright, since the executing lane is the Python twin
  `marathon_drive.py`, not `marathon-drive.sh`).
- **`lane_already_satisfied` must not share an exit code with `lane built and approved`.**
- Any tooling offering "clear stale lock" must verify the recorded PID first.

### Constraints

- `gh` fails under the Bash sandbox here — degrade to local-only, never block a run or alter its exit code.
- **Never auto-close.** This sweep found three issues that looked done and correctly stayed open
  (#299, #272, #303).
- Auto-filed issues inherit the current release **milestone** (decision 1), so they surface in the
  same rollup as planned work rather than as a separate stream.

### Phase 6 checklist

- [ ] Define the signature function and prove two runs of one bug collide to one signature
- [ ] Zero-diff-deliverable check against the phase base commit (the #315 catch)
- [ ] Dedupe query against existing open+closed issues before any write
- [ ] Breaker: N-consecutive or novel-only, reusing `loop-stop.sh`
- [ ] Propose-then-confirm path; `--auto-file` opt-in with `auto-filed`+`needs-triage` labels
- [ ] Degradation test: `gh` absent/unauthenticated → local-only, run exit code unchanged

### QA checklist — Phase 6

- [ ] A deliberately re-run identical failure files **one** issue, not two — demonstrated, not assumed
- [ ] A single transient failure files **nothing**
- [ ] A false success (approved + green gate + zero artifact diff) **is** reported — replay #315
- [ ] No auto-close path exists anywhere in the implementation
- [ ] `/10days`'s candidate set is unpolluted: auto-filed issues are distinguishable by label

---

## Phase 5 — lessons rollup and cross-repo portability

The explicit ask: findings from Phases 2-4 must come back **here**, so rolling this out to other
repos can apply them.

- Each phase appends to a **Lessons learned** section in this doc (created empty below).
- Ship-time lessons ALSO go to `CHANGELOG.md`, per the RELEASES.md contract. They do **not** go into
  RELEASES.md.
- Portability checklist for a target repo — every one of these is a real constraint already hit here:
  - Does it have `gh` authenticated, and does it degrade cleanly when it doesn't?
  - Does it have a trunk name other than `development`? (Do not hardcode.)
  - Does it use milestones already for something else?
  - Does it have PDDA rails at all, or is RELEASES.md absent? Phases 3-4 must no-op cleanly.
  - Vendored `.xyz/` copies: a new runtime artifact must join the GH-312 preserve list in
    `materialize_vendor()`, or `xyz-sync update` deletes it.

### Lessons learned

*(empty — populated as Phases 1-4 land. Do not delete this heading; Phase 5 is the reason it exists.)*

---

## Decisions (operator, 2026-07-27) — SETTLED

1. **Release join key = GitHub MILESTONE.** Not a label. Phase 3 and 4 are scoped to milestones:
   `gh issue list --milestone <name>` is the selection query, and GitHub's own open/closed rollup is
   the progress signal rather than anything recomputed. RELEASES.md gains one `Milestone:` field and
   keeps its existing `GH_URL` semantics unchanged.
2. **Phase 1 fires now, standalone.** Fired 2026-07-27 — see the Status table.
3. **Rollout scope = THIS REPO ONLY for now.** Phase 5's cross-repo work is deferred, not cancelled.
   The portability checklist stays in this doc as the capture point, but no vendored/foreign repo is
   a target until this repo has run the loop for real. Practical consequence: Phases 2-4 may assume
   this repo's rails exist (PDDA, RELEASES.md, `development` trunk) **but must still not hardcode the
   trunk name**, because that is the single cheapest thing to get right early and the most annoying
   to retrofit.

### Still open

- **Trunk name derivation** for the `landed on trunk` check. `development` here; derive it (e.g. from
  the upstream ref) rather than literal, per decision 3.

## Housekeeping found while scoping

- `RELEASES.md:19` — Quicksilver's `Target Date: August 1, 2026` is not `YYYY-MM-DD`, so
  `pdda.sh releases` emits a live warning. Trivial fix, unrelated to the phases above.
