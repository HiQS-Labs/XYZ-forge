---
name: start-task
description: >-
  Start one task or a batch of GitHub issues and carry it through fresh full clones,
  repo-governed intake, grounded recon, surgical DRY planning, Codex relay plan QA,
  execution, verification, final relay QA, and ready PRs. Use for /start-task,
  "start these issues", or requests to clone, register, execute, QA, and make a PR.
  Works across repos. For diagnosis alone use workhorse; for landing existing PRs
  and retiring clones use merge-cleanup.
---

# Start task

Own the lifecycle from the operator's request to reviewed, ready PRs. Reuse the
repository's existing execution, governance, and relay tools. Keep the canonical
plan resumable so another session can continue without reconstructing chat.

Invoking this workflow to execute work authorizes its ordinary steps through
issue creation, task branches, commits, pushes, Codex QA, and opening PRs. Preserve
explicit limits such as "plan only", "hold after QA", or a different reviewer.
Discovering this skill during discussion does not authorize external writes.
Ask only for missing scope, a consequential unresolved decision, or a real blocker;
do not repeat permission questions already answered. Merge, deployment, and clone
teardown are separate actions unless the operator explicitly includes them.

## Workflow

1. **Resolve the request and the target repo.** Read its startup instructions
   (`ROUTER.md` where present), `AGENTS.md`, `SOP.md`, guiding principles, active
   roadmap, and relevant project docs. Resolve issue numbers against the actual
   remote; use full repo/issue URLs across repos. Inspect existing issues, PRs,
   plans, and active work before creating anything. Reuse an existing issue and
   its canonical plan; never create duplicate intake for an already tracked ask.
   Follow the target repo's branch and governance contracts. Missing PDDA or
   RELEASES infrastructure is not permission to install it or invent a substitute.
   Record which local equivalent applies or that the repo has none.

2. **Group and order the work.** For multiple issues, keep a compact table in the
   canonical plan: issue URL, scope, dependencies, clone/branch, plan location,
   acceptance check, RELEASES rating/rationale pointer, current state, and PR URL
   when available. Group tightly
   related issues that change the same seam into one clone/branch/PR; separate
   independent work. Execute groups serially in dependency order unless parallel
   execution was explicitly requested. Track every issue even within a shared PR;
   map its requirements to the shared plan instead of copying the plan per issue.
   After recon and rating, order unblocked work by the existing RELEASES rank,
   subject to explicit user ordering; dependencies remain hard constraints.
   Do not silently omit failed, blocked, or deferred items.
   A dependency cycle needs a grouping/replan decision before dependent execution.
   If a prerequisite is still unmerged in a separate PR, finish that PR and mark
   its dependents blocked until it lands, then fetch and rebase their plans on the
   new base. A user-authorized stacked-PR workflow can override this; do not merge
   a prerequisite just to keep going. Continue other unblocked requested groups.

3. **Provision isolated work and register intake before implementation.** Create
   a clearly named fresh **full clone from the canonical remote**, verify origin
   and base SHA, and create the task branch under repo policy. In XYZ Forge this
   is one `feat/` or `fix/` branch off `origin/development`, with the per-clone git
   hooks installed and checked. Preserve the primary checkout and other sessions.
   An explicit resume should locate and verify the existing task clone, branch,
   PR and HEAD rather than duplicate them or overwrite their state.
   Create any missing issue first. Where PDDA applies, capture it in `1-INBOX`,
   park its roadmap entry immediately, then promote it through the documented
   lifecycle before execution. Read `PROJECT/PDDA.md` and the repo's RELEASES
   documentation for actual verbs and formats. Use the existing CLI to write
   the DB, dump, and generated views; never hand-edit them or add another write
   path. Check registration by reading back the issue, doc pointer, and ledger.
   The genuinely trivial intake exemption follows the repo's policy; it does not
   remove the requirement to rate the task. Apply the rating policy below after
   recon, persist/read back each tracked task's score before plan QA or execution,
   and keep each issue separately rated even when several share a PR.

4. **Ground the plan in initial recon.** Observe the current artifact or behavior
   and identify the existing implementation before proposing changes. For code,
   trace the relevant entry point through callers/callees to state writes and
   visible outputs; inspect tests, configuration knobs, and likely affected
   consumers. Prefer the repo's graph tools where available, falling back when
   coverage is insufficient. Trace enough to size the change; name untraced paths
   and uncertainty rather than claiming an exhaustive audit.
   Inspect recent same-class issues and recurrence evidence for severity/priority
   ratings; distinguish actual new incidents from duplicate reports.
   Record observations, file/symbol references, base SHA, relevant probes, and
   what the findings change in the canonical project plan. For documentation-only
   work, trace the instruction/consumer path; do not manufacture runtime recon.
   Honor explicit `/debug-mantra` and `/ponytail` tags by loading those skills
   (an installation may name the latter `ponytail-refined`). Use debug-mantra's
   plan pivot when available for acceptance criteria. If an explicitly requested
   skill cannot be located, report that dependency instead of claiming it ran.
   `workhorse` is available for deeper diagnosis/design; invoking this lifecycle
   does not require its entire consult ladder on every routine task.

5. **Write a surgical plan for anything beyond a simple change.** A simple change
   is obvious, local, reversible, and requires no design decision or uncertain
   behavior change; a small diff alone does not qualify. Features, multi-issue
   work, schema/shared-contract edits and uncertain fixes need a written plan.
   Use the existing project plan or create the repo-governed one. Include the
   observed problem, per-issue requirements, smallest affected surface, explicit
   non-goals, dependencies, risks/rollback, and one ordered implementation list
   with verification inline. Name the existing subsystem and canonical writer
   being extended. Keep changes surgical and DRY: reuse and extend the existing
   system, without similar subsystems, duplicate modules, parallel write paths,
   speculative abstractions, or unrelated refactors. Do not impose every SOLID
   principle as a checklist. If the existing design cannot carry a requirement,
   show the traced constraint and propose the smallest change to it; do not quietly
   build a second system. Acceptance checks must detect the actual failure, reject
   empty input where relevant, and specify a red control for new/changed gates.
   Scale the detail to the task and obey repo-specific arc planning when applicable.

6. **QA the plan before implementation.** For every non-simple change, load
   `relay-xyz` and use its locator, prerequisite checks, thread protocol and
   shipped harness to run a **Codex** plan review unless the user names another
   reviewer. Commit review inputs so isolated reviewers can see them. Ask specific
   questions: Are claims grounded in the actual paths? Is any requirement missing?
   Does the plan extend the existing subsystem and writer? Are blast radius,
   dependency ordering, rollback, and falsifiable checks sufficient? Are per-task
   ratings grounded, recurrence claims supported, appeal neutral unless the user
   set it, and user overrides preserved? Give the
   reviewer the requirements and source paths, not just a summary of your design.
   Keep reviewer writes limited to the relay thread. Adjudicate findings against
   evidence and repo principles, record every disposition, revise, and re-review
   until Approved within the relay's configured cap (default three review rounds
   for this workflow). Unresolved blockers, unavailable reviewers, containment
   failures or exhausted caps stop that group's implementation; record the exact
   failure and next action. Do not silently substitute a self-review or consult.
   A simple change may skip this stage with a brief reason; final QA still applies.

7. **Execute and verify the reviewed scope.** Use the current agent or the repo's
   established builder/jog/marathon workflow as appropriate. Multiple issues alone
   do not require a new marathon, queue, daemon, or parallel executor. Preserve
   existing role splits, active-marathon limits, driver locks and retry limits.
   Complete the ordered work and update per-issue state and recon findings in the
   plan as you go. Commit coherent checkpoints to the group's branch. Revisit
   plan QA if new evidence materially changes scope, architecture, or risk.
   Run the relevant deterministic checks against the final changes, including
   governance checks. For code/runtime work, run the repo-required gate. In XYZ
   Forge, mutation-heavy suites run in a **separate disposable full clone**, never
   a valued task clone or linked worktree. Verify its repository identity before
   and after the run; drift invalidates its evidence. Retain required provenance
   with the PR. Failed/skipped checks remain failed/skipped; fix within scope or
   mark the group blocked. Do not pass dependents on a failing prerequisite.

8. **Run final Codex relay QA and resolve findings.** Use `relay-xyz` on the
   committed implementation, plan, per-issue acceptance map, and test evidence.
   Ask whether each issue is satisfied, its persisted rating matches its latest
   evidence and user overrides, actual codepaths match the plan, a duplicate
   subsystem or writer slipped in, and checks substantiate the claims. A textual
   review does not replace deterministic tests. Keep author and reviewer roles
   separate, adjudicate each finding, apply surgical fixes and rerun affected checks
   and review within the same bounded loop. Require Approved and passing applicable
   gates for the final artifact revision. Changes after approval must receive
   appropriate fresh verification/review; do not reuse stale approval for a changed
   implementation. Treat a nonzero driver exit, empty output or missing verdict
   as a failed review, even if a transcript sounds positive. Preserve a resumable
   blocked state when review cannot complete, and continue independent groups.

9. **Open or update the ready PR and hand off.** Inspect the final diff for scope
   and accidental files, push through the repository's required gate, and open the
   PR against its active integration branch (`development` in XYZ Forge). Reuse
   an existing PR for the branch. Include the problem/result, issue mapping,
   relevant validation and relay evidence, dependencies and remaining limitations.
   Query the emitted PR to verify its base, head SHA, scope and readiness; verify
   hosted checks for that SHA when required by the repo. A configured workflow is
   not a completed run. A blocked group may have a clearly labelled draft when
   authorized, but cannot be reported ready. Keep issue/doc/ledger state truthful:
   "PR ready; awaiting merge" is not "shipped" or "completed" when governance
   requires landing first. Do not close issues or run post-merge reconciliation
   prematurely. Report each issue/group's PR or blocker, QA/gate result, and retained
   clone path. Hand off merging, reconciliation and safe teardown to `merge-cleanup`
   when requested; preserve the clone and its evidence until then.

## Task rating policy

Rate **every task**, using the existing XYZ RELEASES vocabulary and writer. The
canonical schema is four integer axes, **1–100**: `pri/sev/appeal/effort`, stored as
`rated N/N/N/N`. It is not a three-level scale. "Impact" describes the consequences
and reach used to assess severity and priority; do not invent an impact column or
another scoring subsystem. The fourth field is required by the existing schema.

| Axis | Assessment policy |
|---|---|
| Severity (`sev`) | Judge observed or credibly supported potential consequences, including data/work lost, affected users and recovery difficulty. Crashes, data corruption/loss, and work-blocking defects belong in the high band (80–100); do not average away a serious consequence because reports are rare. Within that band, distinguish a recoverable crash from irreversible corruption. Raise the assessment for a recurring same-class defect or rising incident rate; do not infer a shared root cause merely from similar labels. |
| Priority (`pri`) | Weight urgency strongly toward severity, consequence/reach, recurrence and blocked work, then incorporate the user's stated urgency, deadlines and ordering. Explain departures from severity-led ordering. Keep observed severity honest even when the user schedules something else first. This is LLM assessment of the existing priority axis, not a new ranking formula. |
| Appeal (`appeal`) | Use **50 (neutral)** unless the user explicitly supplies a score or desirability preference. Preserve a prior explicit user value on resume; if translating a qualitative preference into a number, label that interpretation. Do not infer appeal from bug severity, frequency, developer enthusiasm or apparent popularity. |
| Effort/cheapness (`effort`) | Retain an evidence-supported existing value or estimate delivery ease from recon. Higher means cheaper/easier, not more work: 100 is a quick win and 1 a multi-week architectural rewrite. Never copy a PDDA effort value into this axis. |

For recurrence, inspect a stated recent window (default: last 14 days versus the
preceding 14 days) in the target repo's issues, reopenings, relevant comments and
available incident/test evidence. Count distinct incidents where possible; one
incident cross-posted repeatedly is not growing velocity. Record the windows,
counts or concrete examples, links, and limits of coverage. Missing history means
**unknown trend**, not zero incidents and not a reason to downgrade a known crash
or corruption. A repeated bug class is a signal to assess, not a made-up numeric
multiplier. Reassess when new evidence or user input materially changes the task.

Keep a short dated rationale with each task's canonical plan/issue: the four
scores, consequence/impact, recurrence evidence, uncertainty and user overrides.
A displayed copy is a read-back of the DB, never a competing editable ranking.
A simple task exempt from tracked intake still gets its rating and rationale in
the task report. Repos without RELEASES use their existing task record; do not
install the ledger merely to score work.

In XYZ Forge, read `RELEASES-DB-FAQS.md` → "Roadmap Rating Vocabulary & Grammar"
and the current CLI help before writing. After parking an unrated issue, use
`python3 utils/py/releases_app.py roadmap rate --issue-num N --rated P/S/A/E`
(substitute actual values); `--dry-run` previews it. Read the existing rating and
its provenance first. Re-scoring uses `--force` only deliberately with a recorded
reason, never as an automatic response to an "already rated" refusal. Preserve
explicit user appeal/priority choices and any existing operator `ovr`; when
re-scoring, pass the retained `--ovr` explicitly because omitting it replaces it
with no override. New rank overrides are the user's choice, not an LLM shortcut.
The existing rank is the four-axis sum unless operator `ovr` replaces it; do not
change that algorithm or distort cheapness/appeal to manufacture urgency.
Regenerate the repo's required views and read back the rating and rationale.
Use one addressable issue row per tracked task; do not hide a batch behind one
aggregate score. A legacy grouped row requires deliberate per-issue intake
reconciliation through existing CLI verbs before it can satisfy that requirement.

The legacy `cx/risk/eff` ranking vocabulary must not coexist with `rated` on a
ledger row. RELEASES owns task ranking; retain separately required PDDA planning
metadata (such as phases or change risk) without treating it as another ranking
system. A legacy-vocabulary refusal calls for the repo's supported conversion,
not raw SQL, guessed field mappings, or silently deleting governance metadata.

## Global installation

Maintain this skill in the XYZ Forge repository's `skills/start-task/` directory.
When installation is requested, symlink app discovery entries to that directory
in the **maintained primary clone**, never to a temporary review/task checkout.
Resolve the location on the current machine; do not embed an operator-specific path.

| Consumer | Global skill entry |
|---|---|
| Codex | `~/.codex/skills/start-task`; shared discovery also uses `~/.agents/skills/start-task` |
| Claude Code | `~/.claude/skills/start-task` |
| Agy | `~/.gemini/antigravity/skills/start-task`; also `~/.gemini/antigravity-cli/skills/start-task` when that CLI installation is present |
| ZCode | `~/.zcode/skills/start-task` |

Verify the current app installation supports its path. Preserve any existing
nonmatching directory or symlink; do not force-overwrite it. An already correct
link is a no-op. Read `SKILL.md` through each link and verify its resolved target
and content against the maintained source. Report filesystem deployment separately
from whether a running app has refreshed discovery. Install only when requested;
using start-task for ordinary work does not deploy skills or change app settings.
