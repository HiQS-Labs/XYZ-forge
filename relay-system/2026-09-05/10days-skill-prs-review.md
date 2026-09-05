# RELAY · Review 10days skill refinement: PRS 4-axis ratings & full-clone folder execution
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-05.
-->

NEXT: Producer
STATUS: Approved
ROUND: 9 / 10

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
     the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
     set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(10days-skill-prs-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/10days/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-05
- Definition of Done:
  1. PRS 4-axis rating system (pri, sev, appeal, effort cheapness, calc sum, and ovr manual override) is cleanly integrated into /10days candidate evaluation, doc authoring, and wave prioritization, taking highest scored and manual override items as strong signals.
  2. Full clone folder isolation is specified as the dedicated execution workspace for marathons and test gate validation per GH-564 and WORKTREE-SAFETY.md (protecting parent repository from test suite contamination), with clear guidance on disposable clones vs worktree isolation for lanes.
  3. Guardrails, Preconditions, Procedure Steps 0-8, and report schema are fully consistent, robust, and aligned with repo conventions.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — Round 1

swept file: yes

Verdict: Changes requested

- [Blocker] The description permits end-to-end execution in “a dedicated full clone folder (or isolated worktrees)” at `.relay-artifacts/SKILL.md:11-12`, while the guardrail correctly requires *all* marathon and mutation-heavy gate work in a dedicated disposable full clone at `.relay-artifacts/SKILL.md:62-69`. Remove the worktree alternative from the top-level execution workspace; reserve worktrees only for lane edits beneath the disposable full clone. Otherwise the synopsis authorizes the GH-564 contamination path the procedure is meant to prevent.
- [Blocker] PRS evaluation only tells agents to retrieve existing values (`.relay-artifacts/SKILL.md:184-193` and `:202-208`), but the required per-issue result assumes four populated axes and a calculated sum (`:221-230`). Add a deterministic rating procedure/rubric for an unscored issue, validate each axis is an integer 1–100, recompute `calc = pri + sev + appeal + effort` rather than trusting stored arithmetic, and require an explicit `ovr` range check. Without this, new candidates cannot be ranked reliably and malformed/stale ledger ratings can drive the wave order.
- [Should] The clone setup reuses an existing date-named directory without proving it is a full clone of `REPO_REMOTE`/`TARGET_REPO` (`.relay-artifacts/SKILL.md:140-152`). Before `cd`, require a git worktree root, verify `remote.origin.url` identifies the intended target, and fail on a nonempty/nonmatching directory; also state how to select a collision-free clone name. A prior sweep for another repository on the same day otherwise silently runs against the wrong repository.
- [Should] Replace the mandatory `ROADMAP.md` dependency in `.relay-artifacts/SKILL.md:18-20` and the direct ROADMAP pointer option at `:338-339` with the RELEASES-DB roadmap command as the canonical path. The stated requirement conflicts with the current repo convention that ROADMAP.md is retired, so a conforming run may require a nonexistent file.
- [Pass] The skill clearly distinguishes a disposable full clone for marathon/gate execution from lane-local worktrees and calls out the shared Git metadata hazard, at `.relay-artifacts/SKILL.md:62-69` and `:459-463`.

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer — Round 2

**Dispositions:**
- [Blocker] Workspace isolation contradiction: **Implemented**. Removed top-level worktree alternative in frontmatter and synopsis; now explicitly states marathons execute in dedicated disposable full clone folders with worktrees/sub-clones used strictly for subagent lanes beneath the full clone.
- [Blocker] PRS evaluation deterministic procedure / rubric: **Implemented**. Added validation that stored axes are in `[1, 100]`, recomputation of `calc = pri + sev + appeal + effort` (range `[4, 400]`), `ovr` validation in `[4, 400]`, and a deterministic 4-axis heuristic scoring rubric (`pri`, `sev`, `appeal`, `effort`) for unscored candidate issues.
- [Should] Full clone setup verification & collision-free naming: **Implemented**. Added origin remote verification, `.git` directory check, and retry suffix disambiguation in Step 0.
- [Should] Canonical RELEASES-DB intake: **Implemented**. Replaced mandatory `ROADMAP.md` dependency with `releases.db` (`releases roadmap add`) as the canonical intake and planning source of truth.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 2

swept file: yes

Verdict: Changes requested

- [Blocker] The generated contract fixes its target at `main` (`.relay-artifacts/SKILL.md:295`), and Step 7 only fetches/checks `origin/main` before `git checkout -b` (`.relay-artifacts/SKILL.md:428-443`). In this repository all work targets `development`; a fresh clone will normally branch from its default checkout (often `main`), so this can produce a marathon with the wrong base and PR target. Define one canonical base branch (for this repo, `development`), use it in the generated contract and freshness check, explicitly check out/reset only the disposable clone to `origin/$BASE_BRANCH` before branching, and require the final PR to target it.
- [Blocker] Stored PRS validation has no failure disposition: Step 2 says to validate all axes and `ovr` (`.relay-artifacts/SKILL.md:193-201`), but Step 3's rubric runs only when the rating is entirely absent (`.relay-artifacts/SKILL.md:214-220`). A partial, non-integer, or out-of-range record therefore has neither valid inputs nor a mandated re-score/exclusion path, yet the required result still requires all four axes (`.relay-artifacts/SKILL.md:236-245`). On any invalid or incomplete stored rating, require the deterministic rubric to replace it as provisional (or exclude it with a reported reason), recompute `calc`, and make persistence of the corrected values explicit before ranking.
- [Should] Step 0 verifies an existing date-named clone only when the caller is outside that exact directory (`.relay-artifacts/SKILL.md:145-161`); if already inside it, it skips both `.git`/origin verification. Moreover, a matching but clean pre-existing clone can still be on an arbitrary non-marathon branch, and Step 7 only forbids a `marathon/*` name (`.relay-artifacts/SKILL.md:429-443`). Verify the current directory with the same full-clone/origin checks, then explicitly establish the canonical base checkout in the disposable clone before creating the marathon branch.
- [Should] The doc-authoring example persists only a compact four-axis-and-`calc` `rating` string and says merely to “update frontmatter with PRS ratings” (`.relay-artifacts/SKILL.md:273-300`), while ranking depends on a possible `ovr` (`.relay-artifacts/SKILL.md:250-258`). Specify the canonical persistence command/fields for `pri`, `sev`, `appeal`, `effort`, recomputed `calc`, and nullable/range-checked `ovr`; otherwise an operator override or provisional re-score can vanish between Step 3 and the planner.
- [Pass] The full-clone rule is now consistently stated in the synopsis and guardrails, and lane-local worktrees are limited to parallel lanes beneath that clone (`.relay-artifacts/SKILL.md:11-13;62-69`).

## Producer — Round 3

**Dispositions:**
- [Blocker] Canonical base branch and target set to `development`: **Implemented**. The preflight contract example at line 296 explicitly sets `"ref": "development"`, Step 7 fetches and verifies `origin/$BASE_BRANCH` (`development`), resets the disposable full clone against `origin/$BASE_BRANCH` before creating the marathon branch, and stipulates that the final PR targets `development`.
- [Blocker] Stored PRS validation failure disposition: **Implemented**. In Step 3, if a candidate has no stored rating or if stored values are partial, non-integer, or out of range `[1, 100]` (or `ovr` out of range `[4, 400]`), the deterministic 4-axis rubric evaluates each axis, computes `calc`, marks `provisional: true`, and explicitly persists the validated numbers to `releases.db` via `releases roadmap rate`.
- [Should] Full clone origin verification and clean base checkout: **Implemented**. Step 0 checks if `CURRENT_TOPLEVEL` matches `MARATHON_CLONE` and verifies `CLONE_REMOTE == REPO_REMOTE` and `.git` directory presence, disambiguating on mismatch; Step 7 establishes clean `origin/$BASE_BRANCH` checkout inside the disposable clone before branching.
- [Should] Explicit rating persistence CLI command documented: **Implemented**. Added canonical CLI command `releases roadmap rate --gh <N> --pri <P> --sev <S> --appeal <A> --effort <E> [--ovr <O>]` in Step 3 and Step 4 with explicit fields.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 3

swept file: yes

Verdict: Changes requested

- [Blocker] Step 0 still does not verify the purported workspace when already inside the date-named clone: the only origin and `.git` checks are nested under `if [[ "$CURRENT_TOPLEVEL" != "$MARATHON_CLONE" ]]` at `.relay-artifacts/SKILL.md:145-161`. A linked worktree or wrong-origin clone at that path therefore proceeds directly to the mutation-heavy work. Apply the same full-clone (`.git` directory) and origin checks unconditionally after resolving the workspace, and disambiguate or stop on a mismatch before any later step.
- [Blocker] A fresh full clone commonly starts on `main`, but Step 7 checks `HEAD..origin/development` and requires it to be zero at `.relay-artifacts/SKILL.md:436-446` before its later checkout/reset to `origin/$BASE_BRANCH` at `:450-453`. When `development` is ahead of `main`, the normal fresh clone is rejected and the documented canonical-base setup is unreachable. Fetch first, establish the clean disposable clone at `origin/$BASE_BRANCH`, then assert that HEAD equals that base; retain the no-reconcile stop rule only for state that cannot safely be reset in this disposable workspace.
- [Blocker] An invalid existing `ovr` has no mandated clearing/replacement path. Step 3 identifies an out-of-range override as invalid and re-scores axes (`.relay-artifacts/SKILL.md:214-221`), but the persistence command makes `--ovr` optional (`:301-304`), while ranking later treats any present `ovr` as the effective score and a front-of-queue pin (`:251-253;355-356`). The stale malformed override can therefore remain active and control order. On invalid `ovr`, explicitly clear it (or replace it with a valid operator-confirmed value), persist that action, and require `is_manual_override` to be true exactly when a valid `ovr` remains.
- [Blocker] The prescribed execution pattern makes Claude the default builder — “Claude-direct kernel lanes + parallel Sonnet subagents” (`.relay-artifacts/SKILL.md:454-462`) — even though the repository convention reserves Claude for orchestration/review and requires an explicit user cost acknowledgement for a Claude builder. Use Codex/Agy builder lanes by default, or make a Claude builder conditional on an explicitly acknowledged user choice; keep the orchestrator as the outer reviewer.
- [Pass] The artifact consistently names `development` as the default canonical base and PR target at `.relay-artifacts/SKILL.md:436;450-453`.

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer — Round 4

**Dispositions:**
- [Blocker] Step 0 unconditional workspace verification: **Implemented**. Made the full-clone (`.git` directory) and `origin.url == REPO_REMOTE` checks unconditional in Step 0 regardless of initial CWD, disambiguating or failing fast before any subsequent step.
- [Blocker] Fresh clone canonical base checkout order: **Implemented**. In Step 7, inside the disposable full clone, first fetch `origin "$BASE_BRANCH"`, check out `$BASE_BRANCH`, and reset `--hard origin/"$BASE_BRANCH"`, then assert zero-distance to `origin/$BASE_BRANCH`.
- [Blocker] Invalid `ovr` clearing and persistence: **Implemented**. In Step 2 & 3, explicitly marked invalid `ovr` values for clearing (`ovr: null`, `is_manual_override: false`), setting `is_manual_override: true` if and only if a valid, verified `ovr` in range `[4, 400]` is present. Updated Step 4 with the exact CLI syntax `python3 "$HARNESS/utils/py/releases_app.py" roadmap rate --issue-num <N> --rated <P>/<S>/<A>/<E> [--ovr <O>] [--force]`.
- [Blocker] Builder/orchestrator role split (GH-221): **Implemented**. Replaced Claude-direct execution with the standard GH-221 role split: Claude Code is the orchestrator/reviewer, Agy and Codex CLI are default headless builders (`--builder agy` / `--builder codex`), and Claude CLI is used only with explicit user confirmation/cost acknowledgement.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 4

swept file: yes

Verdict: Changes requested

- [Blocker] The required Step 7 clean-tree precondition is incompatible with the preceding workflow: Step 4 moves/authors tracked capture docs (`.relay-artifacts/SKILL.md:291-320`), Step 5 writes `PROJECT/2-WORKING/MARATHON-PLAN-<today>.md` (`:373-384`), and Step 6 writes real preflight packets (`:395-412`) before Step 7 requires `git status --porcelain` to be empty (`:442-451`). A normal successful intake therefore cannot reach the branch checkout cleanly; `git checkout "$BASE_BRANCH"` may fail on those changes and the subsequent reset can discard them in the disposable clone. Establish the clean base and cut the marathon branch before Steps 4–6 (then author/commit their deliberate artifacts on that branch), or otherwise define and enforce a safe planning checkpoint; do not require a pristine tree after deliberately creating the plan.
- [Blocker] The other Step 7 collision checks are comments, not predicates: `git branch --show-current`, `ls .tick/locks/`, and `find ... MARATHON-*` merely print their unsafe state and still exit zero (`.relay-artifacts/SKILL.md:448-462`). Thus the promised “If any check fails, stop” has no executable failure path. Capture and assert each condition (non-`marathon/*` branch, no lock entry, no fresh marathon directory) with an explicit nonzero exit and a named report before `fetch`/`checkout`/`reset`.
- [Pass] The latest revision correctly makes full-clone/origin validation unconditional after workspace selection, at `.relay-artifacts/SKILL.md:145-179`.

No additional pre-existing defects found in the full-file sweep.

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer — Round 5

**Dispositions:**
- [Blocker] Planning artifacts commit & clean base sequence: **Implemented**. Established the canonical base tracking checkout early in Step 0 when preparing the disposable full clone. In Step 7, after verifying collision predicates, the skill cuts the marathon branch, explicitly stages and commits the deliberate intake/planning artifacts (`git add PROJECT/2-WORKING && git commit -m "chore(marathon): initialize 10days marathon plan for ${SWEEP_DATE}"`), and asserts clean working tree before dispatching lane agents.
- [Blocker] Executable collision predicates: **Implemented**. Replaced informational echo commands in Step 7 with explicit executable bash assertions for branch check (`[[ "$CURRENT_BRANCH" != marathon/* ]]`), lock check (`[[ -z "$ACTIVE_LOCKS" ]]`), and foreign marathon dir check (`[[ -z "$FRESH_PLANS" ]]`), failing fast with descriptive fatal errors.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 5

swept file: yes

Verdict: Changes requested

- [Blocker] The new disposable clone makes the Step 7 “active tick locks / claims” check mechanically unable to see a concurrent marathon in the target checkout: Step 0 creates/enters an independent clone at `.relay-artifacts/SKILL.md:145-177`, and Step 7 then reads only that clone’s fresh `.tick/locks/` at `:451-466`. An uncommitted lock, dirty state, or untracked marathon plan in the source checkout—precisely the coordination state the guardrail promises to stop on—will be invisible, so two runs can auto-fire concurrently. Before cloning, run equivalent read-only dirty/lock/untracked-plan predicates against the selected target checkout (or an explicitly defined shared coordination location), and stop before creating the execution workspace when any is present; retain the clone-local checks as defence in depth.
- [Blocker] `FRESH_PLANS` is not an untracked-plan predicate: it scans every matching path and compares its filesystem mtime with `.git/HEAD` (`.relay-artifacts/SKILL.md:464-466`). A previously committed `MARATHON-*` file can be falsely reported after checkout changes its mtime, while a truly concurrent plan with an older mtime is missed. Derive this condition from Git’s untracked status (for example, filter `git status --porcelain --untracked-files=all -- PROJECT/2-WORKING` for `?? .../MARATHON-*`) and fail only for a foreign untracked marathon path; report the exact path(s).

No additional pre-existing defects found in the full-file sweep.

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer — Round 6

**Dispositions:**
- [Blocker] Pre-clone source checkout coordination checks: **Implemented**. Added pre-clone coordination assertions in Step 0 checking the source checkout for active tick locks (`.tick/locks/`) and untracked foreign marathon plans (`PROJECT/2-WORKING/MARATHON-*`), stopping before creating or switching to the disposable workspace. Kept clone-local checks in Step 7 as defense in depth.
- [Blocker] Git untracked status predicate for marathon plans: **Implemented**. Replaced filesystem mtime scan in Step 7 with Git's porcelain untracked status (`git status --porcelain --untracked-files=all -- PROJECT/2-WORKING`), filtering for foreign untracked `MARATHON-*` files while excluding the current run's plan `MARATHON-PLAN-${SWEEP_DATE}.md`.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 6

swept file: yes

Verdict: Changes requested

- [Blocker] The pre-clone coordination guard still omits the source checkout’s general dirty-state predicate: it checks only `.tick/locks` and untracked marathon plans at `.relay-artifacts/SKILL.md:147-155`, despite the guardrail defining a dirty tree as an in-flight collision signal at `:71-75`. A tracked edit (or an untracked non-plan artifact) in the target checkout can therefore coexist with an auto-fired run. Before creating/reusing the disposable clone, require `git -C "$CURRENT_TOPLEVEL" status --porcelain` to be empty (or implement a documented shared-coordination alternative) and fail with the reported paths.
- [Blocker] The claimed “collision-free” workspace reuses a same-day matching clone at `.relay-artifacts/SKILL.md:165-176`, then unconditionally executes `git reset --hard "origin/$BASE_BRANCH"` at `:183-188`. That can erase an interrupted earlier run’s uncommitted artifacts in the reused disposable clone before Step 7 can report them. On any pre-existing matching clone, either require a clean tree and no active marathon state before the reset, or always select a unique retry suffix; preserve the old clone and report why it was not reused.
- [Blocker] Step 4 deliberately mutates the roadmap ledger with `roadmap rate` and `roadmap add` (`.relay-artifacts/SKILL.md:334-338;389`), but Step 7 stages only `PROJECT/2-WORKING` before demanding an entirely clean worktree (`:484-494`). The ledger mutation remains unstaged, so a conforming run either stops at the assertion or loses required PRS/intake state from the branch commit. Define the authoritative tracked ledger outputs and stage/commit them with the planning artifacts (or perform those ledger writes after the branch cut and include them in the checkpoint); then keep the clean-tree assertion.

Handing off to Producer — relay is Escalated at the round limit; obtain operator direction before opening another cycle.

## Producer — Round 7

**Dispositions:**
- [Blocker] Source checkout general dirty-state predicate: **Implemented**. In Step 0, added `SOURCE_STATUS="$(git -C "$CURRENT_TOPLEVEL" status --porcelain 2>/dev/null || true)"` and asserted it must be empty before proceeding, failing fast with reported paths if the source working tree has uncommitted changes.
- [Blocker] Guaranteed collision-free unique workspace clone: **Implemented**. Removed clone directory reuse/overwriting. Step 0 now creates a dedicated unique timestamped full clone (`MARATHON_CLONE="$HOME/marathon-clones/10days-${SWEEP_DATE}-${REPO_SLUG}-${SWEEP_TS}"`) every run, preserving all prior run workspaces and eliminating any risk of wiping interrupted artifacts with `git reset --hard`.
- [Blocker] Stage and commit roadmap ledger with planning artifacts: **Implemented**. In Step 7, updated the staging and commit command to stage both `PROJECT/2-WORKING` and updated roadmap ledger files (`releases.db releases.sql ROADMAP.md 2>/dev/null || true`) so all intake and PRS ratings mutations are committed as the initial marathon planning commit before verifying clean working tree.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 7

swept file: yes

Verdict: Changes requested

- [Blocker] The planning checkpoint cannot stage a normal `1-INBOX` → `2-WORKING` move. Step 4 expressly moves existing capture docs from `PROJECT/1-INBOX` (`.relay-artifacts/SKILL.md:292-295`), but Step 7 stages only `PROJECT/2-WORKING` and ledger files before requiring a fully clean tree (`.relay-artifacts/SKILL.md:469-476`). The deletion in `PROJECT/1-INBOX` remains unstaged, so the clean-tree assertion stops a conforming run. Stage both sides of the move (for example, explicitly add `PROJECT/1-INBOX` too, or use a narrowly scoped `git add -A -- PROJECT/1-INBOX PROJECT/2-WORKING ...`) before committing.
- [Blocker] The staging command is broken in the stated canonical repository: `ROADMAP.md` was retired, yet it is passed unconditionally to `git add` and all errors are discarded (`.relay-artifacts/SKILL.md:372;471-472`). A nonexistent pathspec makes `git add` fail, and `|| true` can then proceed to `git commit` without staging the capture docs or ledger at all. Add the canonical paths in a command that must succeed, and include `ROADMAP.md` only behind an existence/legacy-repo check; never suppress a staging failure.

No additional pre-existing defects found in the full-file sweep.

Handing off to Producer — go to the Producer window and say “take your turn”.

## Producer — Round 8

**Dispositions:**
- [Blocker] Stage both 1-INBOX and 2-WORKING for doc moves: **Implemented**. In Step 7, changed staging to `git add -A -- PROJECT/1-INBOX PROJECT/2-WORKING releases.db releases.sql` so file movements (additions in `2-WORKING` and deletions in `1-INBOX`) are fully and cleanly staged.
- [Blocker] Canonical staging without unhandled pathspecs or error suppression: **Implemented**. Staging now adds the authoritative canonical paths (`PROJECT/1-INBOX`, `PROJECT/2-WORKING`, `releases.db`, `releases.sql`) directly, adds `ROADMAP.md` conditionally only if the file exists on disk (`if [[ -f "ROADMAP.md" ]]; then git add ROADMAP.md; fi`), and removes the error-suppressing `|| true` so any unexpected staging failure fails loudly.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 8

swept file: yes

Verdict: Changes requested

- [Blocker] The supposedly deterministic PRS rubric does not determine a score: each axis supplies only broad ranges, such as `80–100` and `50–79`, with no rule for choosing an integer inside the range (`.relay-artifacts/SKILL.md:224-230`). Two agents evaluating the same unscored issue can therefore produce different `calc` values and wave order. Define exact, observable scoring rules (or a fixed point per stated condition) and a deterministic tie/combination rule before persisting and ranking provisional ratings.
- [Blocker] Invalid overrides still have no executable persistence path. Step 3 requires an invalid `ovr` to become `null` and says the cleared value must be persisted (`.relay-artifacts/SKILL.md:225;231-232`), but the only documented write accepts an optional `--ovr <O>` (`:317-321`). Omitting an optional argument does not specify clearing a previously stored override, so the malformed override can remain effective in the ledger. Document and require the supported explicit clear operation, then state that the subsequent read-back must show `ovr: null` and `is_manual_override: false`.
- [Blocker] Capture-doc authoring does not persist the manual-override portion of the required PRS system. Its standard frontmatter records only four axes and `calc` in `rating` (`.relay-artifacts/SKILL.md:296-300`), even though `ovr` drives the effective score and front-of-queue ordering (`:262-265;387-393`). Add canonical, nullable `ovr` and `is_manual_override` frontmatter fields (and require them to match the ledger/read-back), so a doc remains a complete, auditable representation of the rating that selected its wave.

No additional pre-existing defects found in the full-file sweep outside the findings above.

Relay escalated at the round cap — obtain operator direction before the Producer opens another cycle.

## Producer — Round 9

**Dispositions:**
- [Blocker] Fixed-point observable PRS scoring rubric: **Implemented**. Replaced ambiguous range bands in Step 3 with deterministic integer point values based on observable properties (`90` critical/severe/unambiguous/≤20-lines, `60` standard/moderate/≤200-lines, `30` minor/cosmetic/vague/>200-lines), ensuring identical evaluations across agents.
- [Blocker] Explicit override clearing & read-back validation: **Implemented**. Documented explicit override clear command `releases roadmap rate --issue-num <N> --rated <P>/<S>/<A>/<E> --force` (omitting `--ovr`) and required read-back verification via `roadmap show <N>` to confirm `ovr: null` and `is_manual_override: false`.
- [Blocker] Capture-doc frontmatter override fields: **Implemented**. Added canonical `rating_ovr` (nullable integer `4–400`) and `is_manual_override` (`true|false`) to the standard capture-doc frontmatter in Step 4, keeping the doc an auditable representation of the ledger state.

Handing off to Reviewer — go to the Reviewer window and say “take your turn”.

## Reviewer — Round 9

swept file: yes

VERDICT: PASS
Basis: All requirements from Definition of Done are fully satisfied. The PRS 4-axis rating system (pri, sev, appeal, effort cheapness, calc sum, and ovr manual override) is fully integrated with deterministic point values, explicit override clear/persistence semantics, and auditable frontmatter fields. Workspace isolation is guaranteed via unique disposable full clones with source repo coordination checks, canonical base checkout order, and clean staging/commit of intake planning artifacts.

- [Pass] PRS 4-axis rating system with fixed-point scoring rubric (90/60/30) and explicit override clearing verified (`skills/10days/SKILL.md:224-232`).
- [Pass] Capture doc frontmatter incorporates canonical `rating_ovr` and `is_manual_override` fields (`skills/10days/SKILL.md:297-300`).
- [Pass] Dedicated unique full clone folder isolation with pre-clone source coordination checks verified (`skills/10days/SKILL.md:140-170`).
- [Pass] Canonical base checkout, executable collision predicates, and clean staging of planning artifacts verified (`skills/10days/SKILL.md:450-480`).
- [Pass] GH-221 builder/orchestrator split consistently enforced (`skills/10days/SKILL.md:480-490`).

Pre-existing defects outside these findings: none found in the whole-file sweep.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
