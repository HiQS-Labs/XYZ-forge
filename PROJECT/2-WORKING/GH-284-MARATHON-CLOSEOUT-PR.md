---
gh_issue: 284
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284
title: "marathon: closeout PR, run-log back to the lane issue, and release-driven marathon selection"
status: "Phase 1 contract authored 2026-07-23 and STILL READY to fire standalone. Phases 2-5 added 2026-07-27 (run-log + RELEASES.md driver + cross-repo lessons rollup) — scoped only, not contracted."
created: 2026-07-23
updated: 2026-07-27
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 5
ratings_provisional: true
non_goals:
  - Auto-merging the closeout PR (explicit non-goal in the issue itself — open only, never merge/force-push/branch-create beyond what's already there).
  - Re-adding "linked marathons/issues" or a release-tag cache as FIELDS inside RELEASES.md. That exact design was already tried and deliberately rolled back as "too much data to keep current" (PROJECT/PDDA.md, RELEASES.md check rationale). The many-to-one linkage belongs in GitHub, where it maintains itself.
  - Putting lessons-learned INTO RELEASES.md. Its contract says lessons belong in CHANGELOG.md at ship time. This doc is the second home, for cross-repo portability only.
  - Auto-FILING new GitHub issues per marathon run (see Phase 2 rationale — it would poison the /10days scan input).
  - Making any of Phases 2-5 a blocker on Phase 1 shipping.
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
| **Phase 1 unchanged and still independently fireable** — contract below is untouched and `swarm-preflight --gh-issue 284` still returns ready. **Phases 2-5 scoped 2026-07-27** after the `/10days` sweep produced hard evidence that the marathon↔record gap is a recurring, measurable failure (four cases in one 22-issue window — see Evidence). Phase 3-4 design deliberately keeps the release↔issue linkage OUT of RELEASES.md, because that design was already tried here and rolled back. | **Fire Phase 1 now — do not wait on the rest.** Phases 2-5 need one operator decision first (milestone vs. label as the release join key, see Open decisions) and their own contracts at promotion time. |

## Why this doc grew (read before scoping)

#284 was a small, well-specified, ready-to-fire feature (2/2/2). It has been widened into a 5-phase
program. That is a real scope-creep risk, so the mitigation is structural: **Phase 1 keeps its
original contract, byte-for-byte, and ships on its own.** Everything added here is downstream of it
and separately promotable. If Phases 2-5 stall, Phase 1 still delivered.

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

## Phase 1 — the closeout PR (UNCHANGED, ready to fire)

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

## Open decisions (operator)

1. **Milestone vs. label as the release join key** (Phase 3). Recommendation: milestone. Changes
   Phase 3 and 4 implementation, so it is worth settling before either is contracted.
2. **Does Phase 1 fire now, independently?** Recommendation: yes. It is ready today and nothing in
   Phases 2-5 changes its contract.
3. **Trunk name** for the `landed on trunk` check — `development` here, but it must be derived, not
   hardcoded, if this ships to other repos.

## Housekeeping found while scoping

- `RELEASES.md:19` — Quicksilver's `Target Date: August 1, 2026` is not `YYYY-MM-DD`, so
  `pdda.sh releases` emits a live warning. Trivial fix, unrelated to the phases above.
