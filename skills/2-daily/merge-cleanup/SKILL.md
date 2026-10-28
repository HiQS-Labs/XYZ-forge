---
name: merge-cleanup
description: Consolidate multiple Git worktrees and clones of a repository into a single clean checkout, safely merge associated PRs in topological dependency order, document landing batches of two or more PRs as a script-maintained GitHub issue (merge sequence, problems, ad-hoc fixes, regression sweep, post-deployment carry-overs — also echoed in chat), reconcile post-merge governance state (PDDA and RELEASES DB), and safely remove leftover worktrees/clones without data loss or interrupting active sessions. Strictly complies with WORKTREE-SAFETY.md.
---

# /merge-cleanup — Worktree Consolidation, PR Sequencing, and Safe Teardown

`merge-cleanup` consolidates multiple active Git worktrees and clones of a repository into a single clean primary checkout, determines optimal topological PR merge sequences, executes GitHub PR merges, triggers post-merge PDDA & RELEASES DB reconciliations (the RELEASES DB is the Product Release System, PRS; [definition](https://github.com/HiQS-Labs/XYZ-forge/blob/development/HOW-TO-USE.md#glossary--the-five-terms-youll-hit-first)), and safely tears down disposable worktrees/clones without data loss or active process disruption.

Strictly adheres to [`WORKTREE-SAFETY.md`](https://github.com/HiQS-Labs/XYZ-forge/blob/development/WORKTREE-SAFETY.md) and [`AGENTS.md`](https://github.com/HiQS-Labs/XYZ-forge/blob/development/AGENTS.md).

---

## Recite this — verbatim, as the first thing in your first response

> **Merge-Cleanup Discipline:**
> 1. **Verify primary landing readiness (Phase 0).** Confirm the primary on-disk checkout is clean, on the integration branch (`development`), and ready to fast-forward before any remote action.
> 2. **Inventory checkouts & protect active sessions (Phases 1–3).** Scan worktrees and task clones across safe roots; preserve any checkout with active file handles, driver locks, `.tick` claims, or recent edits (10m/60m recency ladder).
> 3. **Sequence PRs & pre-gate conflicts (Phases 4–5).** Fetch open PRs into a topological DAG to prevent file collisions; pre-simulate landings and resolve disjoint ledger/doc conflicts.
> 4. **Merge & reconcile governance (Phase 5).** Merge using the project policy in dependency order, fast-forward primary checkout (`git merge --ff-only`), and execute post-merge reconciliation (`wave_reconcile`, `releases_app check`, `pdda.sh`).
> 5. **Safe teardown & status confirmation (Phase 6).** Deregister worktrees via canonical git protocol, move clean disposable clones to Trash, prune dangling skill symlinks, and confirm all PRs are landed.
> 6. **Document and sweep qualifying batches (GH-944, GH-1064).** When the sequenced queue holds **two or more PRs**, the script opens the `merge-batch` GitHub issue **before the first merge** with the planned order, keeps its outcomes and sweep inputs current, and exits **4** (landed, QA pending) until a sweep verdict is recorded. You fill the caller sections (problems, ad-hoc fixes/pivots, findings), run the `/debug-mantra` regression sweep with the printed command (a Small suite in a throwaway clone, or the full sweep deferred to the pre-promotion dispatch, GH-1127), record the verdict with `--record-sweep <file>`, and transcribe each merged PR/issue's **post-deployment carry-over items** into the issue **and** the end-of-run chat summary, verbatim and unchecked.
>
> **Overall Goal:** All ready-to-merge PRs processed, qualifying batches documented and swept for regressions, and local disk clones and git worktree folders safely torn down when appropriate.

Then begin work.

---

## Conversational Triggers

When the operator speaks naturally:
- `"Run merge-cleanup on this repo"`: Reviews the primary on-disk checkout first (Phase 0), then audits the other checkouts, reports the sequence, and proceeds within the session's authorized PR and cleanup scope. Discovery does not add unrelated PRs to that scope; an explicit audit/dry-run request remains read-only.
- `"Scan all clones and worktrees"`: Runs Phase 1–3 discovery and outputs the status matrix of all worktrees and clones.
- `"Sequence and merge open PRs"`: Reports Phase 0 for the primary checkout first — a PR sequence is not actionable until the tree it lands in can receive it — then determines topological order of open PRs, detects file collisions, and executes policy-selected remote merges followed by wave reconciliation.
- `"Tear down clean task clones"`: Safely removes verified clean, non-active clones and worktrees.

---

## Project merge policy

Before any caller-owned doc parking or executing cleanup, read the target project's policy:

```bash
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$PRIMARY" --show-merge-policy
```

Use the installed script path when running outside Forge. `--primary` selects the policy root;
never read the policy from the harness source or `.xyz/`. This JSON-only mode performs no scan,
GitHub query, or mutation. A nonzero exit stops the run; do not interpret an empty report as disabled.

Maintainers opt in by committing `.merge-cleanup.json` at their project root:

```json
{"preserve_commit_history": true}
```

With preservation enabled, omitted `--strategy` selects `merge`; explicit `squash` or `rebase`
is refused. Merge commits preserve the PR's original commit IDs and ancestry as they exist at
landing; this does not recover commits already rewritten during development. Cleanup verifies
GitHub permits merge commits and refuses when unavailable or unknown, without changing repository
settings or falling back. GitHub branch rules can still refuse a merge.

Missing file/key or `false` keeps the legacy default (`squash`) and permits explicit
`--strategy merge|squash|rebase`. This does not infer conventions from GitHub's allowed methods;
maintainers retain their existing explicit strategy choice. Invalid/unreadable policy, unknown keys,
or a non-boolean value fails closed. No global preference overrides a project's opt-in.

Both cleanup skills use this one resolver. Vendoring alone never enables preservation; recommend
it to maintainers starting a new project and retain existing choices on updates. GitHub's settings
remain an independent control for humans and other tools. Forge opts in through its root file.
Historical squash provenance and all dirty/stash/session/teardown checks remain unchanged. To
change future behavior, review and commit the project setting; never rewrite old history.

The same file declares the repo's batch-sweep cadence (GH-1159) as an optional key:
`"qualification": {"full_suite": "promotion"|"per_batch"|"none", "sweep_command": "<command>"}`.
With `promotion`, Forge's classifier picks the gate and a full sweep is deferred to
`sweep_command`. With `per_batch`, `sweep_command` runs in a throwaway clone. With `none`, the
batch issue says the repo has no full suite. `sweep_command` is printed verbatim. Without the key,
the issue says no sweep command is declared and shows no Forge gate or workflow. An invalid value
fails closed, and `--show-merge-policy` prints the key. A merge-cleanup older than this key refuses
the file ("expected an object with only preserve_commit_history"): update the harness. The globally
deployed skill is a physical copy (Skills Army HQ), not a link to a checkout, so it does not follow
`git pull`; refresh it with `intake.py --apply update merge-cleanup` as soon as this key lands in a
repo it serves. Forge declares `promotion` with its `wave-reconcile.yml` dispatch (#1131).

## 7-Phase Ladder Logic

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Phase 0: Primary On-Disk Checkout (Can It Receive The Landing?)         │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 1: Discover & Inventory (Identify Checkouts & Roots)              │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 2: Active Process & Session Inspection (Zero Disruption)          │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 3: Git Safety & Worktree Verification (Data Loss Prevention)      │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 4: PR Matrix & Topological Sorting (Dependency-Ordered Landing)   │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 5: Safe Execution & Post-Merge Reconciliation (Governed Landing)  │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 6: Safe Teardown (Worktree & Clone Pruning via Git Protocol)      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Phase 0: Primary On-Disk Checkout — always first, never by discovery

**Targeted PR-ready retirement exception (GH-1059).** `--retire-published-pr N`
with explicit `--checkout /absolute/task/path` arguments is a separate closeout
mode, not a merge run. It does not scan other checkouts, merge PRs, fast-forward
the primary, write governance or prune skill links. Primary landing readiness is
therefore not required in this mode; its identity/origin and path protection are.
Native linked-worktree removal updates its parent's Git worktree metadata. All
ordinary modes retain Phase 0 unchanged. See the scoped contract below.

**Report the operator's own checkout before anything remote is fetched.** It is the tree every
PR lands in, the tree `git merge --ff-only` runs in, and the tree `wave_reconcile.py`,
`releases_app.py` and `pdda.sh` write to. A run that opens with a PR table has told the operator
about everyone else's work and nothing about their own.

- Inspect the primary **by identity**, not by discovery. It is listed because it is the primary —
  never because a `SAFE_ROOTS` walk reached it or its directory name matched `--prefix`. A primary
  outside those roots, or under a non-matching prefix, used to vanish from the audit entirely
  while Phase 5 went on merging into it.
- Report and gate on five facts: current branch vs the integration branch (`--integration-branch`,
  default `development`), working-tree cleanliness, an unfinished merge/rebase/cherry-pick, local
  commits on the integration branch that `origin` does not have, and positive ancestry proof that
  HEAD can fast-forward to `origin/<integration>`.
- **Readiness is affirmative.** Every fact must be positively established; a git query that *fails*
  is unknown state, never a pass. A checkout with no `origin/<integration>` at all is not ready,
  because the landing target cannot be resolved.
- The branch that is checked is the branch that is landed. `--integration-branch` threads through
  Phase 0 and the fast-forward alike.
- **Unpushed commits on the integration branch are a blocker, not a note.** A squash-merge landing
  skips them silently, which is how local work is lost. The caller may first park eligible
  documentation commits under the policy below, then re-establish readiness; the CLI never skips this gate.
- Not ready is a **refusal**, reported before the PR matrix and enforced before the first mutation.
  It covers zero-PR cleanup, teardown-only cleanup, and `--reconcile-pr`; none may silently defer
  the primary checkout to the operator after reporting success.
  A dry run still prints the sequence, labelled explicitly as not executable while blockers stand.
  `--allow-unready-primary` overrides the refusal deliberately and records the blockers.
- The verdict is **re-established against the live remote** immediately before the first merge, so
  a stale cached `origin/*` cannot certify a tree that has since diverged. A refresh that *fails*
  is itself a refusal — re-checking against the cache the fetch could not update would certify
  stale evidence as current.
- **Every PR's base must be the checked integration branch.** Phase 0 vouches for one branch only;
  a PR based elsewhere would land in a tree whose readiness was never established, so the run
  refuses rather than merging it.
- Uncommitted intake docs or captures in the primary are their own commit or a park — they do not
  ride along in whatever PR happens to be open.

```bash
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary . --scan-only   # Phase 0 + audit
```

Phase 0 runs in every mode of the orchestrator. The standalone helpers below
(`scan_clones.py`, `toposort_prs.py`) do **not** perform it — reach for `merge_cleanup.py` when
the answer will inform a landing.

### Committed documentation parking — caller-owned before executing Phase 0

For an executing merge-cleanup request, handle documentation-only unpushed commits before
invoking the strict CLI readiness gate. Audit/dry-run requests only report this option.
Parking preserves work for later review; it never qualifies it for integration or teardown.

1. Inspect the primary first and refresh `origin/<integration>` successfully. Enumerate the
   complete local-only commit range, not just its final net diff. Require a non-empty result
   and successful inspection of every changed path in every commit, including both rename
   sides and deleted blobs. Require documentation/session-transcript purpose; only `.md`,
   `.markdown`, `.txt`, and `.rst` ordinary, non-executable UTF-8 text files with no NUL bytes
   qualify. Inspect both old and new blobs where present; a text suffix alone is insufficient.
   Code/config/ledger files, binary data, symlinks/submodules, mixed or unknown history retain
   the existing preserve/handoff rules; a code edit followed by a revert never qualifies.
2. Preserve the exact tip under a unique local `temp-merge-cleanup-<date>-<short-sha>` branch
   and publish it to the same `origin` under that name. An existing name is reusable only at
   the identical SHA; otherwise choose a new unused name. Use a creation-only remote-ref
   lease for a new branch (expected remote ref absent), never force-replace an existing ref.
   Verify the origin branch SHA equals the saved tip. Publication failure blocks continuation
   without changing the source branch or working tree. Retain existing preserve refs/stashes.
3. Before continuing, save an unchecked item in session memory/checklist, durably backed by
   `<primary>/.tick/merge-cleanup/<owner>-<repo>/temp-docs.md` (append on resume). Include the
   source checkout/branch, exact tip and integration baseline, remote branch URL, commit/file
   summary, publication verification and pending disposition. This is a remote branch backup,
   not `git stash`; no PR is opened or merged for it automatically.
4. If the blocked integration branch itself carried these commits, only after verified
   publication and the durable record, apply existing working-tree/session/claim/worktree
   safeguards: preserve its local branch by renaming it and recreate a clean tracking
   integration branch from live origin with the sandbox guard. Never reset, discard files,
   clear another session's claims, or bypass readiness. Dirty/active/dependent state stays
   protected. Re-run Phase 0; proceed with the already-authorized PR sequence only when ready.
5. After the merge sequence, revisit every unchecked temp item, including resumed runs.
   Report branch links, commit/file summaries and overlap with current integration; record
   whether it is still pending or already covered. Offer keep, selectively recover via a
   reviewed PR, or discard for the operator to decide. Never auto-merge, auto-delete branches,
   mark disposal complete, or tear down source checkouts merely because the backup is pushed.
   Include the overview in the final chat and qualifying batch issue even on a stopped run.

### Phase 1: Discover & Inventory
- Always includes the primary checkout from Phase 0, then locates further candidate repositories under `SAFE_ROOTS` — `~/Documents/GH Repos`, `~/agent-workspaces`, `~/Documents/agent-workspaces`, `~/marathon-clones` (where `/jog`, marathon flows and older `/start-task` runs create task clones; task clones that follow the GH-970 location decision are siblings of the primary, found with `--root "$(dirname <primary>)"`). The list in `scan_clones.py` is the list in `WORKTREE-SAFETY.md` §16.1; a test pins the parity (GH-534 A.1).
- Evaluates component-aware containment (`_within(child, parent)`) and refuses `NEVER_DELETE` protected roots (`$HOME`, `~/Documents`, `~/Desktop`, `/`).
- Distinguishes **Linked Worktrees** (`.git` is a file with pointer `gitdir: ...`) from **Standalone Clones** (`.git` is a directory).
- Uses `git worktree list --porcelain` to determine parent-child relationships.

### Phase 2: Active Process & Session Inspection
- Checks driver locks: `.git/relay-driver.lock` (or vendored `.relay-driver.lock`) and validates holder PID liveness via `kill -0 <pid>`.
- Checks `.tick/` active claims through the **event log fold**, never `STATE.md` (a derived snapshot): `tick claims --json` with `TICK_REPO_ROOT` pinned to the coordination root (a linked worktree's is its parent clone's). Any claimed task → `ACTIVE_TICK_CLAIM` naming task and agent; a `.tick/locks/` entry of any shape counts; `tick` missing, failing, or an events directory that is missing/unreadable → `PRESERVE_UNVERIFIED_SESSION` naming why (GH-534 A.4, `decisions/2026-09-09-tick-claims-verb.md`).
- Checks live file handles via `lsof -F pcn +D <checkout>` from a CWD outside it. Three outcomes, because `lsof +D` exits 1 whether idle or held: a normal exit with code 0/1 **and** empty stderr is a complete enumeration (matches → `ACTIVE_PROCESS` naming PIDs and commands, none → verified idle); a signal-killed/timed-out/absent `lsof`, or **any** stderr line (`WARNING: can't opendir`), is incomplete → `PRESERVE_UNVERIFIED_SESSION` naming the warning.
- **Activity Window Ladder (10m + 60m Recency Detection):** Inspects non-ephemeral file modification timestamps (`mtime` ignoring `.git`, `node_modules`, `.venv`, `.DS_Store`, and `*.sqlite-wal`/`*.sqlite-shm`) to classify:
  - **`ACTIVE_WRITING`** ($\le 10$m): In-progress active editing.
  - **`RECENT_IDLE`** ($10\text{m} - 60\text{m}$): Paused session, recent edits.
  - **`DORMANT`** ($> 60$m): Zero file modifications in over an hour.
  - When open file handles are detected on a `DORMANT` checkout, `ACTIVE_PROCESS` is annotated with `(Dormant handle: 0 files modified in >60m)` to distinguish idle background handles from active editing.
- Honors explicit user exclusion patterns (e.g. `--exclude gh427`) for the checkout scan and teardown only. `--exclude` is never a PR filter: which PRs land is the `--prs` allowlist (GH-1226).

### Phase 3: Git Safety & Worktree Verification
- **Dirty status:** reads the complete NUL-safe `git status --porcelain -z --untracked-files=all` and names **every** file in the disposition. There is no regenerable-artifact allowance: `harnesses.db` carries invocation data, `*.db.bak` may be the last pre-rebuild copy (GH-534 A.3).
- **Stashes:** Asserts `git stash list` is empty (0 unpopped stashes).
- **Landed vs unlanded refs, by provenance (A.2):** after a verified `git fetch origin <integration-branch>`, every local ref tip — all `refs/heads/*`, detached `HEAD`, any local-only ref — must be either (1) reachable from `origin/<integration-branch>`, or (2) the exact `headRefOid` of a **MERGED** PR (base = integration branch, `gh pr list --state merged`, remote identity bound to the clone's `origin`) whose merge commit is reachable **and** whose landed content equals the branch's — per-path blob ids and modes from `git diff --raw --full-index`, so whitespace and binaries count. Anything else is `PRESERVE_UNPUSHED` naming the ref, the commit and the reason (no merged PR; content differs from PR #N; lookup unavailable). Squash merges no longer read as "unpushed forever"; a changed conflict resolution or a commit after the PR head still preserves. `git cherry` is never an authorization input.
- **Completion Confidence & Agent Follow-up (Medium Scan Ladder):**
  - **Medium Scan:** Inspects commit logs for QA attestations (`relay-drive: attest ... approved`, `status — final QA approved`, `LGTM`, `QA approved`), working tree cleanliness, and PDDA task checklists under `PROJECT/2-WORKING/`.
  - **Deep Scan Escalation:** If unlanded commits exist without QA attestation, marks confidence as `MEDIUM` and recommends a deeper scan. The deeper scan is [`/merge-cleanup-deep`](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/3-weekly/merge-cleanup-deep/SKILL.md) (GH-728): it consumes this skill's `scan_clones.py --json` audit, zips every preserved checkout to a dated backup, fans out ≤3 read-only sub-agents by branch family, and returns PR-WORTHY / SUPERSEDED / NEEDS-OWNER / ABANDON-CANDIDATE verdicts with the deciding evidence; disposable checkouts come back here for Phase 6 teardown. `/recon` or `/debug-mantra` remain the tools for a single clone's conflict.
  - **Agent Follow-up:** Identifies the owning agent (via `.tick` claim, author/co-author, or PID command name) and provides actionable follow-up guidance.
- **Canonical GitHub Issue Marker (`--marker`):**
  - Resolves linked canonical issue (via branch name, directory name, or commit log regex) and formats a structured status checkpoint comment to post to GitHub.
- **Worktree dependencies:** Verifies no other linked worktrees point to a clone before marking it disposable.
- **Every safety query fails closed (A.5):** a non-zero or unparseable `git status`, `stash list`, `worktree list`, `for-each-ref`, `fetch`, `tick claims` or `lsof` → `PRESERVE_UNVERIFIED_QUERY` / `PRESERVE_UNVERIFIED_SESSION` naming the query. No result is ever defaulted to "none".

### Phase 4: PR Matrix & Topological Sorting
- Runs only after Phase 0 has reported. The PR sequence is advice until the primary can receive it.
- Fetches open PRs via GitHub API (`gh pr list`). The discovery call is bounded in time and retried on transient network failures (GH-623): a FAILED discovery is an error, never an empty queue — after three transient retries it exits 2 before Phase 6, because rolling into teardown on a false "no PRs" would report success while the queue was silently skipped.
- Extracts explicit dependency references (`depends on #N`, `blocked by #N`, `after #N`) as **hard** edges.
- Analyzes touched file sets to detect unannotated file collisions and orders shared-file PRs chronologically as **soft** edges: they decide sequence only, never eligibility (GH-623).
- Builds a Directed Acyclic Graph (DAG) and computes topological merge order.
- **`--prs` allowlist (GH-1226).** The PRs a run may land are fixed when it starts, never discovered at merge time:
  - A merging `--execute` (anything but `--teardown-only`, `--scan-only`, `--prs-only` or `--reconcile-pr`) without `--prs N[,N...]` exits 2 before any mutation.
  - The dry run with `--prs` pins each listed PR's head SHA to `.tick/merge-cleanup/<slug>/selection-<integration>.json`. It refuses to pin (exit 2) if a listed PR is not open or is a draft. It also prints the same pins as `Pinned for --execute: --prs N@sha,...`.
  - An entry may carry its own pin as `N@sha` (7-40 hex; a prefix is enough). Such an entry needs no record, so the printed line can be passed to `--execute` from another checkout. A bare `N` needs the dry run's record.
  - `--execute` with the same `--prs` refuses (exit 2, before any mutation) if there is no pin, if it names a PR the dry run did not, or if a listed PR closed, went draft, or moved off its pinned head. `--prs` may narrow the pinned list (drop PRs that already landed on `--resume`), never widen it.
  - Every open PR is still sequenced so dependency edges stay visible. Unlisted PRs are logged `not in --prs; not sequenced` and never merged, and B1 repairs touch only listed PRs. A listed PR with a hard dependency on an unlisted one is deferred, and an executing run then exits 3. The same exit 3 applies when a pinned PR closes or merges between the startup check and Phase 4.
  - Stacked-PR base retargeting still covers unlisted PRs, because it protects them; it does not merge them.
  - After Phase 5 the script asserts merged ⊆ `--prs` (exit 2 otherwise). The batch issue renders the pinned list.
  - A dry run without `--prs` previews every open PR and pins nothing.

### Phase 5: required checks and pinned heads (GH-1226)
- Before each merge the script reads `gh pr checks <n> --required --json name,bucket`. `pass`/`skipping` proceed, and so does gh's "no required checks reported". Failing or cancelled checks mean the PR is not merged (exit 3).
- While required checks are pending, the script re-reads them every `MERGE_CLEANUP_CHECKS_POLL_S` (default 30 s) for up to `MERGE_CLEANUP_CHECKS_WAIT_S` (default 1800 s). Still pending after that defers the PR (exit 3), and so does an unreadable answer. It never merges on a guess. A dry run only reports the check state; it does not change its exit code.
- At final eligibility the live head must equal the dry-run pin. A B1 repair pushes a new head, so a repaired PR is always **deferred** in the run that repaired it. Wait for its checks, re-run the dry run to re-pin, then `--execute` again.

### CI-heavy repositories: plan merge groups before qualification (GH-1066)

Prefer a few coherent landing groups over repeatedly repairing, pushing and fully testing
one PR at a time. This is caller-owned planning, not a new driver mode or a gate bypass.
Use the existing batch issue for qualifying queues; smaller queues use the run summary.

#### Required Landing Decision Checkpoint (GH-1158)

For queues of 3 or more PRs, `--execute` strictly requires an explicit landing decision before any mutation occurs:
- `--landing-plan direct|group`: choose direct sequential landing or grouped candidate landing.
- `--landing-reason "<justification>"`: non-empty, non-whitespace explanation for the choice.

**Refusal (Exit 5):** If `--execute` is run on 3+ PRs without `--landing-plan` and `--landing-reason`, `merge_cleanup.py` halts immediately with **Exit 5** before modifying any git refs (no deletion of `REBASE_HEAD`), before fetching remote refs (`refs/FETCH_HEAD`), before posting `--marker` comments, and before creating batch records or issues.

**Behavior by Plan:**
- `--landing-plan direct`: Records the decision and reason in the local batch record and proceeds through sequential landing and reconciliation (Phase 5).
- `--landing-plan group`: Records the decision and reason in the local batch record and `merge-batch` issue, outputs the GH-1066 candidate execution checklist (freeze, sequential fold, adversarial preflight, single landing PR), and exits cleanly (**Exit 0**) without executing remote merges or checkout teardowns.
- `--resume`: Reuses a previously recorded landing decision without prompting if the batch record holds a plan for the identical PR set. If the queue membership changes or no plan was recorded, the checkpoint is re-enforced.
- **Small queues (<3 PRs):** Unaffected; proceed without requiring `--landing-plan`.

1. **Map the cost and constraints.** Read the repo's required checks, push hooks, hosted
   triggers and reconciliation policy. Identify which pushes actually start broad CI and
   which existing path supports batching (merge queue, staging or aggregate landing PR).
   Record the chosen path and intended full-run checkpoints before the first mutation.
2. **Group by dependency and interaction.** Keep hard dependencies in order; group related
   changes sharing runtime/contracts or repeated conflict sites. Shared ledger/CHANGELOG
   files alone do not prove semantic coupling. Separate unrelated work and risky migrations,
   security or containment changes that need independent rollback and qualification.
3. **Prepare before expensive runs.** Resolve the group's known conflicts and combined
   interactions in a disposable full clone, complete independent review, and run the existing
   focused checks as repairs are made. Publish complete reviewed checkpoints rather than
   each mechanical repair. Required per-PR checks still run on their actual final heads.
4. **Freeze the candidate.** Record member PRs and head SHAs, current integration base,
   combined candidate SHA, review receipts and rollback boundary. New members, code repairs
   or base changes invalidate affected evidence; refresh review/checks before landing.
5. **Adversarial sequence review for three or more PRs.** When the authorized batch
   contains three or more PRs, use one bounded [`relay-xyz`](../../1-hourly/relay-xyz/SKILL.md)
   review of the whole grouping, merge strategy and sequence before the first merge, even
   when the batch is divided into smaller groups. Choose an independent reviewer using a
   different actual model family from the plan author; a different CLI alone is not proof.
   Record both model identities, the frozen PR/head/base/candidate SHAs, proposed groups/order,
   required CI checkpoints and rollback boundaries in the existing batch record and relay.
   Ask the reviewer to challenge missing dependencies, semantic interactions, conflict sites,
   unsupported gate deferral, duplicate broad runs and recovery after a partial landing.
   Disposition supported findings before proceeding; advice cannot waive deterministic gates
   or operator authority. Use at most three cumulative review rounds per batch, including
   resumes; do not repeat this strategy review per PR or replace required per-PR QA.
   Material changes to membership, dependency/order, integration content or risk reopen the
   affected plan review; editorial record updates do not. Record unavailable review neutrally
   ("Independent review did not run.") or an unknown identity as "Reviewer model identity
   unverified." Hold the affected batch without assigning defect severity or opening a
   blocking issue. Do not claim cross-model
   approval without evidence. Ordinary one/two-PR queues need no extra strategy relay unless
   risk or repository policy calls for one.
6. **Qualify the complete group.** Where policy permits, reserve the first full gate for
   this frozen combined candidate, after preparation is complete. Keep the existing tier
   classification; grouping docs does not require a full gate. Run the repository's
   qualifying command on its required platform; a parallel publication run is not sequential
   promotion evidence. A failed required check stops landing; diagnose before retrying.
7. **Land through the supported path.** Preserve merge-history policy and PR/issue provenance.
   Never retarget PRs, create a staging branch, alter branch protection/workflows, cancel
   required runs or use a push bypass merely to meet a CI budget. Those changes require
   their own authorization. Historical time-boxed exceptions are not standing permission.
8. **Verify the landed result.** Reserve a second full run for the actual landed integration
   result when policy requires it or candidate evidence no longer qualifies that result.
   Reuse an existing qualifying hosted run only when its SHA/content scope covers the group;
   do not launch a duplicate final sweep. Complete required reconciliation and fresh teardown
   checks, and record actual run SHAs, results and any remaining verification.

**Fallback:** if no supported batch path exists, keep ordinary sequential merges and every
required per-merge reconciliation/check. The current Forge driver reconciles after each merge;
this guidance does not defer that sequence or add a batching flag. Group preparation can reduce
repair/push churn, but cannot promise one or two total CI runs under an unchanged per-PR policy.
Record that limit; use Forge's `docs/CI-CHURN-RECOVERY-SOP.md` for a separately authorized
recovery window when warranted. Never skip qualification or claim unmeasured savings.

### Phase 5: Safe Execution & Post-Merge Reconciliation
- **Refuses every executing cleanup when Phase 0 says the primary is not landing-ready**, unless the operator explicitly passes `--allow-unready-primary` to defer that cleanup. This gate applies before any Phase 5 or Phase 6 mutation, including zero-PR and `--teardown-only` runs; the skill never silently chooses to leave the primary dirty or otherwise unready.
- Carries existing authorization forward. Ask only for a missing scope decision, ambiguous resolution, or an action requiring additional permission under repo policy, after completing safe preparation; do not ask the operator to reselect already authorized work.
- **Every PR is re-fetched before every decision (E).** `gh pr view` is read fresh per PR; a `mergeable` of `UNKNOWN` is polled first — GitHub recomputes mergeability for every open PR after each landing on the base, so the next PR reads `UNKNOWN` for a few seconds — up to 6 × 15s (`MERGEABLE_POLL_ATTEMPTS` / `MERGEABLE_POLL_S`, GH-736), re-reading with the transient-retry wrapper; a read that fails mid-poll ends the poll and follows the same rules as the first read (transient → deferred, anything else → stop naming the error); still undecided after that stops the run, and so does any non-transient `gh` failure (a PR whose state is unknown is never merged). A TRANSIENT network failure (DNS, refused/timed-out connection, TLS, rate limit) is retried three times first (2s, 4s between calls, GH-623); one that survives the retries DEFERS that PR — named in the end-of-run summary — and the queue continues. A hold label (`hold`, `do not merge`, `blocked`, `wip`) skips the PR (#444). A PR whose base is not the checked integration branch stops the run.
- **Pre-merge ledger gate (E.6):** the landing is simulated in a disposable full clone — PR head, then `git merge --no-ff --no-commit origin/<integration-branch>` against the integration head fetched *now* (the three-way merge keeps `MERGE_HEAD`, which the ledger resolver's generation floor reads). On a clean merge: a three-way ledger classification (a clean textual merge can still be a semantic conflict), then `releases_app.py check` and `roadmap reconcile-state --dry-run`. Any non-zero exit or `FAIL:` line is **red** and the PR is not merged; `warn:` lines, per-row identity skips and `would move` lines are diagnostics, not red.
- **Ledger and additive changelog conflicts, disjoint changes only (B1):** a conflicted landing whose unmerged set (from `git diff --diff-filter=U` + `git ls-files -u`, required non-empty with a zero-exit extraction) is within `{releases.db, releases.sql, LEADERBOARD.md, RELEASES-PREVIEW.html, LEADERBOARD.html, CHANGELOG.md}` is classified three-way against the merge base, per table, per key. Only when the two sides' changes are mechanically disjoint — no same-key change on both sides, no reference to a row the other side deleted, no duplicate `gh_number`, nothing outside `roadmap_items` on the replayed side — is it resolved: the side with the higher generation is kept, the other side's roadmap changes are replayed **through the writer** (`roadmap add` / `update` / `rate` / `repoint`; receipts are regenerated, gids are re-minted), then `utils/releases-merge-resolve.sh` rebuilds the DB and views, `releases check` must be clean, `git ls-files -u` must be empty, the merge commit is validated in a **second** disposable clone, and it is pushed to the PR branch only if the remote head is still the SHA that was resolved. Then the PR is re-fetched and re-gated. `harnesses.*` conflicts, code conflicts, same-key edits, deletes, inexpressible tables, a resolver refusal (generation rewind), an extraction error → **handoff** (exit 3) naming the keys; the landing clone is kept for inspection. Never an SQL union.
- **Additive changelog boundary (GH-789):** B1 accepts complete dated sections prepended to unchanged preamble/history, proven against one merge base. Distinct same-date headings survive; exact identical new blocks deduplicate. Edited/deleted history, divergent same-heading additions, malformed sections, fenced/HTML additions and conflict markers hand off before writes. The repository still needs its existing RELEASES ledger and gates.
- **Drafts (GH-789):** live `isDraft` is checked before repair, after polling/repair refreshes, before a repaired-head push and immediately before merge. Drafts are skipped; hard dependents wait, independent PRs continue. Soft collision preferences cannot create dependency cycles; unresolved hard prerequisites block even under numerical fallback.
- **Orphan rebase marker (GH-789):** inspection stays read-only. Execute landing/reconcile may compare-and-delete a valid stale REBASE_HEAD only when all other readiness checks pass and no active rebase/sequencer/other operation exists, then re-inspects. Dry-run, scan-only, prs-only and teardown-only never prune.
- **One durable attempt record per PR, at the pinned coordinator (C):** before B1 runs, the script reserves a repair slot in `<primary>/.tick/merge-cleanup/<owner>-<repo>/pr-<N>.json` — `<primary>` is the explicit `--primary` path the run started with, never a disposable clone's CWD. Every writer (this script, and each caller repair rung via `attempt_record.py`) holds `fcntl.flock` on `<record>.lock` for the whole read → reserve → write; that lock is independent of the driver's mkdir lock, so a worker under a running driver still reserves. A lock timeout **stops** the attempt (never "skipped"). Only repairs count (`B1`, `ponytail`, `start-task`); `debug-mantra`/`recon` are notes. **Two repairs per PR, whatever the head**: at the ceiling the PR is **parked** with the record path, and B1 does not run. Any handoff or park prints `export MERGE_CLEANUP_RECORD=<record>` for the caller ladder below.
- **Only HARD dependencies block on a failed predecessor (C + GH-623):** Phase 4 orders; Phase 5 keeps a runtime map of predecessor outcomes and skips a PR whose declared dependency (`depends on #N`) was handed off, parked or deferred, naming it. File-collision edges are SOFT: a collision-adjacent PR is attempted anyway and its own landing simulation decides — a genuinely conflicting successor hands off on its own merits instead of never being tried (the incident's S3 cascade: one handoff removed most of the queue). Independent PRs still land. A run with any non-landed outcome (handoff / park / defer) exits 3 after the sequence; a stop (unknown state, gate red, merge/reconcile failure, unreadable record) exits 2 immediately. A batch run that landed PRs no recorded sweep verdict covers exits 4 after Phase 6 (GH-1064); 2 and 3 take precedence.
- **`--resume` continues a previous run (GH-623):** the live refresh stays first and authoritative. Only when a PR's landing actually conflicts — a repair would be needed — does the attempt record decide: at the ceiling with `--resume`, the PR is skipped as `previously parked` without re-running the B1 machinery (and without consuming a slot). A PR whose last recorded repair finished `resolved` and whose head now merges cleanly LANDS — a resume run completes a successful repair's work, never strands it. Without `--resume`, `reserve()` is the under-lock authority and the behavior is unchanged. Resume mode announces itself (`Resume mode: ...`) and the end-of-run summary breaks out parked-on-resume counts.
- Executes remote merges in topological sequence through `execute_pr_merge`, using the method selected by the project policy resolver (never a hardcoded direct `gh pr merge --squash`) — and a zero exit is not a landing: the PR is re-queried until it reads `MERGED` with a merge commit (#510 class), else the run fails. A non-zero or killed `gh pr merge` is re-queried once too, and a PR that reads `MERGED` with a merge commit continues to the post-merge sequence (GH-852). After a B1 push, the re-gate first waits (up to 6 × 15s) until GitHub reports the pushed head, because the old head's `CONFLICTING` is still showing (GH-851). `--reconcile-pr` refuses (exit 2) unless the PR reads `MERGED`, and looks up the hosted run by that PR's head and merge commit (GH-852).
- After each verified remote merge, performs one ordered durability sequence before looking at the next PR: **fast-forward primary → reconcile → emit `pr_merged` → commit all resulting primary-side ledger/governance writes → push `origin/<integration-branch>` → assert the primary is clean and `HEAD == origin/<integration-branch>`**. The emitter therefore runs only after both the landing fast-forward and any fast-forward performed by reconciliation; a failure at any step stops the run.
- Executes post-merge reconciliation, **gating** (a failure stops the run before emission, commit, push, the next PR, teardown, and symlink pruning; `--reconcile-pr` propagates the same exit):
  - **Default (GH-1127, #1131): reconcile locally** with `python3 utils/py/wave_reconcile.py --pr <PR_NUM>`. The hosted lane is dispatch-only (pre-promotion), so there is nothing to wait for after a merge. The local writer keeps its one safety query and refuses with exit 8 while a hosted run is queued or in progress (a promotion dispatch); land after it finishes.
  - **Opt-in hosted wait:** with `MERGE_CLEANUP_USE_HOSTED=1`, query the hosted `wave-reconcile.yml` runs (`gh run list --workflow wave-reconcile.yml`) and match the PR head or the merge commit. If the run is queued or in progress, poll until completion for at most `MERGE_CLEANUP_HOSTED_WAIT_S` seconds (default 5400, #854 D5: full-registry reconciles take 53–66 min); timing out while it remains active stops the landing rather than racing it locally.
  - On hosted success, fetch and fast-forward the primary onto `origin/<integration>`'s reconciliation commit.
  - An empty answer inside the first `MERGE_CLEANUP_HOSTED_GRACE_S` seconds (default 60) is "not listed yet", not "no workflow" — the run for a just-pushed head can lag `gh run list` by a few seconds, and reconciling locally in that gap would race the hosted writer. After the grace window, if no hosted run/workflow/`gh` exists, or the hosted run completed unsuccessfully, fall back to `python3 utils/py/wave_reconcile.py --pr <PR_NUM>`. Never invoke that local writer while the observed hosted run is queued or in progress (`--force-local-reconcile` remains a manual recovery tool only).
  - `python3 utils/py/releases_app.py check`
  - Verify with `bash utils/pdda/pdda.sh issue-doc-sync`.

### Phase 6: Safe Teardown
- **Linked Worktrees:** Always removed via `git worktree remove <path>` from parent clone, followed by `git worktree prune` and `git worktree repair`. **Zero `rm -rf` on linked worktrees!**
- **Fresh inspection first (A.5):** the Phase 1–3 table is display. Before any removal, **every** non-exempt checkout (all `PRESERVE_*` and `SAFE_REMOVE_*` alike; only `PRIMARY_CHECKOUT`, `PRESERVED_USER_EXCLUDE`, `PRESERVE_WIKI` are exempt) is re-inspected after a fresh fetch, and only that verdict is acted on. A `PRESERVE_UNPUSHED` clone whose PR landed in Phase 5 becomes eligible here; anything that became dirty, claimed, or grew a local ref since the scan is preserved. `teardown_checkout()` refuses a record that is not a fresh Phase 6 inspection.
- **Standalone Clones:** Only removed if verified 100% clean across Phase 2 & 3, and only by moving to Trash (`~/.Trash`). If Trash is unavailable the removal is **refused** — `rmtree` is not a removal path.
- **Backup Before Teardown (`--backup-first`):** When `--backup-first` is passed, candidate checkouts are backed up and verified via `backup_clones.py` before teardown. Standalone full clones are archived into `<backup-root>/<repo>/<timestamp>/zips/<clone>.zip` and verified with `testzip()` CRC and SHA256 before removal. Linked worktrees (external Git storage) cannot produce self-contained archives and are refused for backup; unverified or failed backup candidates are preserved from teardown, their names logged, and Phase 6 exits with code 2.
- **Symlink Cleanup:** Prunes dangling skill symlinks in `~/.claude/skills/` and `~/.gemini/**/skills/`.

---

## Drive loop — how an agent runs this skill end to end (GH-623)

`/merge-cleanup` is a driven workflow, not a one-shot report. Follow the loop; do not stop at the
first refusal, do not degrade the scope silently, and do not report completion over PRs that were
never attempted:

1. **Dry run first** (Phase 0 + audit + sequence), naming the PRs you mean to land:
   `python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$PRIMARY" --prefix <name> --prs 783,811`
   This pins their heads. Vet the sequence; anything else open is only listed, never landed.
2. **Fix the primary** so Phase 0 reports landing-ready (commit or park the dirty intake files per
   the Phase 0 rules). A dirty primary is a blocker to FIX, not a reason to silently switch to
   `--teardown-only` and still report completion (the incident's S1 false-Done). If a blocker
   cannot be resolved autonomously, finish every independent step first, then report the blockers
   and stop — address them or report them; never silently truncate the task.
3. **Execute:** add `--execute` to the same command (same `--prs`). If the sequenced queue holds **≥2 PRs**, the script opens the batch
   issue before the first merge — see [Batch issue protocol](#batch-issue-protocol-gh-944-gh-1064--script-owned-record-for-queues-of-two-or-more) —
   and you keep its caller sections current through the run.
4. **On exit 3** (handoff / park / defer): read the printed `export MERGE_CLEANUP_RECORD=...`
   paths, work the caller ladder below for handoffs, then **re-run with `--resume --execute`** to
   continue the queue. Repeat until exit 0 or a stop. Deferred PRs (network, pending required
   checks, or a head that moved off its pin after a B1 repair) are named in the summary; they are
   not PR failures — re-run once the network is healthy or the checks finish, re-running the dry run
   first to re-pin a moved head and dropping already-landed PRs from `--prs`.
5. **On exit 2**: diagnose before anything else; the diagnostic names the gate. A re-run is only
   valid once the cause is fixed.
6. **On exit 4** (landed, QA pending — GH-1064): for a Small gate, run the printed sweep command in a
   throwaway clone; for the full gate, the printed command is the pre-promotion dispatch (GH-1127) —
   record `verdict: deferred` naming it until its receipt exists. Then run the `/debug-mantra` cross-PR
   review over the recorded inputs, write the verdict file, and
   record it with `merge_cleanup.py --primary "$PRIMARY" --record-sweep <file>`. If it reports that
   planned PRs remain, continue with `--resume --execute`; a `--resume` run with nothing left to land
   still reports 4 until a verdict covers every landing.

### Continuation contract — do not hand back reversible steps (GH-985 pattern)

A merge-cleanup run fails the operator as surely by stopping to ask about a reversible step as by
skipping one. The same contract as `/workhorse` applies, specialised here:

- **What the request already authorizes.** "Run merge-cleanup", "merge the open PRs", "land these",
  or any request naming PRs authorizes the whole drive loop for that queue: dry run, fixing the
  primary, `--execute`, the batch issue, caller repair rungs within the two-repair budget,
  `--resume --execute` re-runs, reconciliation commits and pushes to the integration branch, and
  Phase 6 teardown of `SAFE_REMOVE_*` checkouts to Trash. An explicit audit, scan, or dry-run
  request stays read-only. Discovery never adds PRs outside the request.
- **Proceed without asking on reversible steps.** Do not pause to ask "should I execute?", "should I
  re-run with `--resume`?", "should I commit the intake doc?", "should I open the batch issue?", or
  "should I tear down the clean clones?". Each is in scope, gated by the script, and recoverable:
  merges land on a remote branch using the policy-selected method, ledger writes are reconciled and pushed, teardown
  goes to Trash, and the attempt record bounds repairs. After each step, take the next one in the
  same turn. A status question from the operator is answered briefly and the loop resumes.
- **Ask only at a real decision.** Stop and ask for exactly one of: a PR outside the requested
  queue; `--allow-unready-primary` or any other override flag; a `PRESERVE_*` checkout the operator
  might want removed; a semantic code conflict after the repair budget is exhausted (rung 5);
  a Costly or One-way-door action under `AGENTS.md` (force push, deleting a branch or clone that
  holds unlanded work, rewriting integration history); or a permission-classifier block that
  survives its one verbatim retry. Before asking, finish every independent authorized step — land
  the PRs that do not depend on the blocked one, reconcile them, tear down what is safe — and then
  ask once, naming the blocked PR or checkout, why it cannot proceed, and the decision needed.
- **Evidence before Done.** "Landed" means the PR reads `MERGED` with a merge commit and the primary
  equals `origin/<integration>` after reconciliation; "torn down" means the fresh Phase 6 verdict
  acted on it. A dry-run table, a planned sequence, or an attempted command is not a landing.
- **Continuation never widens authorization.** It grants no override flags, no force pushes, no
  deletion of preserved checkouts, and no PRs the operator did not name or imply.

**Done rule:** do not report Done unless Phase 5 ran to completion (exit 0; or exit 3 whose
handoffs and deferrals were worked and re-driven to exit 0), **or** the operator explicitly asked
for `--teardown-only` / `--scan-only` / `--prs-only`. For a qualifying batch, Done additionally
requires the regression sweep to have run and its verdict (or an explicit `deferred` verdict with
its reason) to be recorded with `--record-sweep`, which writes it to the batch record and issue;
exit 4 is the script saying that has not happened, so exit 4 is never Done. When the batch issue
could not be created or updated (see *Non-blocking*), the verdict still lands in the local batch
record; name the issue failure in the run summary.

**Permission-classifier blocks:** if a harness permission layer blocks the `--execute` launch,
retry the identical command once before escalating to the operator — a block that succeeds on a
verbatim retry was non-deterministic, and surrendering the run to it is how an operator ends up
hand-driving the loop four times (the incident's S2).

## Batch issue protocol (GH-944, GH-1064) — script-owned record, for queues of two or more

GH-1064 moved the record from caller prose into the script. The script owns the batch record, the
issue's marked block, the outcomes, the sweep **inputs** and the verdict **record**. It does not run
any test suite (GH-831): the caller still runs the sweep and writes the verdict.

- **Trigger & threshold.** An executing run whose Phase 4 sequence holds **two or more PRs**, after
  the `--prs` allowlist is applied, gets a batch. Single-PR runs are unchanged: no issue, no exit 4.
- **`--resume` continues the batch, whatever the queue size.** A resume first looks for an
  unfinished batch (planned PRs not yet landed-and-reconciled, or landings no verdict covers) for
  this repo and integration branch. A non-empty queue must overlap its planned PRs; an empty queue
  (everything already landed) matches on repo and branch alone. A found batch keeps its issue. With
  no match, a 2+ queue opens a new batch, even on `--resume`.
- **Created before the first merge.** The record lives at
  `<primary>/.tick/merge-cleanup/<owner>-<repo>/batch-<utc>-<pr>.json`. The issue is opened
  (`gh label create merge-batch --force`, then `gh issue create`) after sequencing and before the
  loop. Its marked block holds the planned order, with each PR's hard dependencies and soft-edge
  overlap files.
- **Every outcome, at the branch where it happens.**
  - The remote merge is recorded with its merge commit as soon as `gh pr merge` is verified, and the
    reconcile result separately.
  - Hold-label and draft skips get named statuses (a PR seen closed is recorded `closed`, which is
    terminal), as do blocked, deferred, parked and
    handed-off PRs.
  - Any hard stop is recorded against the PR in hand, with its error lines. PRs never reached stay
    `unattempted`.
  - The issue's marked block is rewritten on every return.
- **Sweep inputs (after the loop, over every landing in the batch, including earlier resumed runs):**
  - the merged range `<first landing>^1..<last landing>`;
  - files touched by two or more landed PRs (from the stored per-PR file lists);
  - repaired conflict sites from the attempt records;
  - the gate from `wave_reconcile.select_qualification_gate`, or the full gate when it cannot classify;
  - the command: for the Small gate, the exact `git clone --no-local … && bash <gate>` to run locally;
    for the full gate, the pre-promotion `gh workflow run wave-reconcile.yml` dispatch (GH-1127, #1131).
    A full sweep is never rerun locally: record `verdict: deferred` naming the promotion dispatch, or
    `clean` naming the hosted run that covered the batch tip.
- **Exit 4 = landed, QA pending.** After a normal Phase 6, a batch with landings that no recorded
  verdict covers ends with exit 4. Held or handed-off PRs elsewhere in the batch do not change
  that, and a new landing makes an earlier verdict partial again. Exit 2 and 3 take precedence.
- **Recording the verdict.** `merge_cleanup.py --primary <path> --record-sweep <file>` runs no scan,
  merge or teardown. The file's first line is `verdict: clean|findings|deferred`:
  - `clean` must name what ran;
  - `findings` needs at least one `- [ ]` item with its evidence;
  - `deferred` needs a reason.
  It covers the batch's current landings. Malformed or empty input exits 2 and stores nothing.
- **Issue ownership.** The script only ever replaces the text between
  `<!-- merge-batch:script:start -->` and `<!-- merge-batch:script:end -->`. If the body cannot be
  read, or the markers are gone, it does not edit and records why. Everything outside the markers is
  the caller's.
- **Caller-owned:** Strategy and sequence review (GH-1066), Problems, Ad-hoc fixes & pivots, Findings, the `/debug-mantra` sweep analysis
  (cross-PR interactions, repaired conflict sites as regression suspects, the Small suite run in a
  disposable full clone, never the primary, GH-564, or the full sweep deferred to the promotion
  dispatch per GH-1127), and the carry-overs below.
- **Non-blocking.** Issue create, read or edit failures are recorded in the batch record and
  printed as warnings; the landing proceeds. The record is the source of truth either way.
- **Post-deployment carry-overs (dual sink).** Scan each merged PR body and its closing-linked
  originating issue for post-deployment/verification checklist items; transcribe them
  **verbatim, attributed (`#PR` / `#issue`), unchecked** into the issue's carry-overs section, outside
  the markers, **and echo them at the end of the run's chat summary**, after the merge sequence, so
  the operator sees them in-band rather than only on GitHub. Transcribe only: merge-cleanup never
  executes production verification.
- **Lifecycle.** The issue stays open; the operator works the checklists. merge-cleanup never
  auto-closes it.

**Issue layout (created by the script):**

```markdown
Title: Merge batch <YYYY-MM-DD> — <owner-repo> — <PR list>
Labels: merge-batch
Integration branch: `<development>`

<!-- merge-batch:script:start -->
## Merge sequence      (planned order · depends on · file overlap · status · merge commit · reconcile)
## Sweep inputs        (range · shared files · repaired conflicts · gate · command)
## Sweep verdict       (QA pending | clean/findings/deferred covering #…)
<!-- merge-batch:script:end -->
## Strategy and sequence review
<!-- groups/order, PR/head/base/candidate SHAs, CI checkpoints, rollback; for 3+ PRs: author/reviewer model identities, relay receipt and finding dispositions (GH-1066) -->
## Problems
## Ad-hoc fixes & pivots
## Findings
## Regression sweep (debug-mantra)
- [ ] <!-- analysis with evidence -->
## Post-deployment carry-overs
- [ ] <!-- verbatim items, attributed to #PR / #issue -->
```

## Caller decision ladder (Phase C) — what the script hands off

The script owns the evidence and the cap; the caller owns the analysis. A standalone script run never claims to have run `/recon` or `/ponytail`. Every rung starts from the handoff line's `export MERGE_CLEANUP_RECORD=<abs path>`; a worker started without it, or with a relative or unreadable path, **stops** — it never derives a record root from its own CWD.

| Rung | Skill | Budget | Record verb |
|---|---|---|---|
| 1 | `/debug-mantra` — establish the conflict as ground truth from `conflict_files` in the record | none (note) | `note --kind diagnosis` |
| 2 | `/recon`, **read-only**, over the record's conflict files only — default 8 files, 15 minutes wall-clock, consumer tracing one level out counted inside the same budget; stop and record `budget_exceeded` when hit | none (note) | `note --kind recon` / `--kind budget_exceeded` |
| 3 | `/ponytail` — the smallest reviewed resolution; "independent hunks" is not proof of independent semantics, so a code resolution lands only with caller review and tests | **1 repair** | `reserve --rung ponytail --head <sha>` … `finish --index N --outcome …` |
| 4 | `/start-task`-style handoff for semantic overlap | **1 repair** | `reserve --rung start-task --head <sha>` |
| 5 | `/unstuck` — when `reserve` exits 3 (the record already shows two repairs) | — | `show` |

`reserve` exits 0 (go; prints `index=N`), 3 (budget exhausted — go to rung 5), 2 (stopped: no/invalid record, lock timeout). Bouncing between rungs, restarting, or re-cloning never resets the count, because the record lives at the coordinator. The record is untracked state under `.tick/`; delete it by hand when the PR is closed.

## Capability table (parity guard)

Each row names who does the work; `script` rows name the test that pins them, and `test/gh534_phase_c_tests.py::TestParityGuard` fails if a row, its owner, its test, or a listed CLI option disappears.

| Capability | Phase | Owner | Pinned by |
|---|---|---|---|
| session-evidence-driver-lock | 2 | script | TestA5FailClosed.test_each_failed_git_query_preserves_naming_it |
| session-evidence-tick-claims | 2 | script | TestA4TickClaims.test_iii_claim_is_read_from_the_fold_not_state_md |
| session-evidence-open-handles | 2 | script | TestA4OpenHandles.test_ix_held_descriptor_is_active_process_naming_the_pid |
| preservation-dirty-stash-unlanded | 3 | script | TestA2Provenance.test_ii_unlanded_branch_is_preserved_naming_ref_and_commit |
| preservation-fail-closed | 3 | script | TestA5FailClosed.test_each_failed_git_query_preserves_naming_it |
| landing-refetch-and-gate | 5 | script | TestE6Gate.test_gate_red_prevents_the_merge |
| ledger-resolution-disjoint | 5 | script | TestPhase5EndToEnd.test_same_key_update_on_both_sides_is_handoff_and_nothing_is_overwritten |
| ledger-handoff-and-record | 5 | script | TestCScript.test_two_clones_one_coordinator_third_repair_is_refused |
| coordinator-pinned-to-primary | 5 | script | TestCScript.test_omitted_primary_is_refused_and_no_record_root_is_minted |
| teardown-trash-only | 6 | script | TestCScript.test_teardown_refuses_without_trash |
| dependents-blocked | 5 | script | TestCScript.test_dependent_of_a_handed_off_pr_is_not_attempted_and_an_independent_pr_proceeds |
| soft-edge-nonblocking | 5 | script | TestGh623Resilience.test_soft_edge_predecessor_does_not_block_a_collision_dependent |
| network-retry-defer | 5 | script | TestGh623Resilience.test_transient_view_failure_defers_and_independents_land |
| resume-skips-parked | 5 | script | TestGh623Resilience.test_resume_skips_a_still_conflicting_exhausted_pr |
| reconciliation-gating | 5 | script | TestCScript.test_two_ledger_prs_emit_only_after_fast_forward_and_finish_durable |
| code-conflict-recon | 5 | caller | — |
| code-conflict-resolution | 5 | caller | — |
| teardown-fresh-inspection | 6 | script | TestA5FreshInspection.test_teardown_refuses_a_stale_scan_record |
| mergeable-unknown-poll | 5 | script | TestPhase5EndToEnd.test_unknown_mergeable_settles_and_the_pr_lands |
| prs-allowlist | 4 | script | TestPhase5EndToEnd.test_unlisted_pr_is_never_sequenced |
| batch-issue-threshold | 5 | script | TestGh623Resilience.test_resume_lands_a_pr_whose_last_repair_resolved |
| batch-issue-resume-append | 5 | script | TestGh623Resilience.test_resume_lands_a_pr_whose_last_repair_resolved |
| batch-sweep-record | 5 | script | manual check, `TESTS-RESULTS/2026-10-14+GH-1064/` |
| batch-regression-sweep | 5 | caller | — |
| post-deploy-carryover-dual-sink | 5 | caller | — |

CLI options this document describes and the guard asserts exist: `--primary`, `--root`, `--prefix`, `--exclude`, `--prs`, `--strategy`, `--show-merge-policy`, `--scan-only`, `--prs-only`, `--teardown-only`, `--reconcile-pr`, `--integration-branch`, `--allow-unready-primary`, `--execute`, `--backup-first`, `--resume`, `--record-sweep`, `--landing-plan`, `--landing-reason`.

## CLI Usage

### Automatic retirement after ready PR publication

Start-task's successful closeout authorizes retirement of its own task checkout and
disposable helpers before merge. Retain required code, plans and evidence in the PR
and resolve a current driver first; run from outside all retiring paths:

```bash
python3 /path/to/merge-cleanup/scripts/merge_cleanup.py --primary "$PRIMARY_REPO" \
  --retire-published-pr "$PR_NUMBER" --checkout "$TASK_CHECKOUT"
# Inspect the preview, then repeat this exact scope with --execute.
```

This mode accepts checkouts under `SAFE_ROOTS` or directly beside the primary (its parent
folder, start-task's GH-970 location), unless that parent is a `NEVER_DELETE` root (GH-1193).
Repeat `--checkout` only for explicit paths created by this workflow. Do not infer
the primary from the task clone: `--primary` must be an explicit absolute path;
empty/relative values refuse instead of inferring the current directory. Do not
combine this mode with scans, merge/reconcile,
override or backup flags. The driver requires matching canonical origins, a live
non-draft OPEN/MERGED same-repository PR targeting the integration branch, exact
fetched origin branch/head equality, and remote recovery proof for every local ref
and detached HEAD. Missing/deleted remote branches, stale heads, forks, failed API
or Git queries and malformed metadata preserve the checkout. Publication is not a
claim of merge, release promotion or issue completion.

Existing local-state/session/dependency checks run again immediately before the
existing teardown function. Preserve dirty/local-only evidence, stashes, unrelated
unpublished refs, active locks/claims/handles and dependent worktrees. Release only
the current workflow's completed activity; never stop peers or fabricate a safe
disposition. Report actual retirement or the exact preservation reason. Full clones
move to Trash; linked worktrees use native Git removal. Older drivers must be
updated or the checkout preserved, never replaced with a manual remover. Normal
merged-only history admission and its repair/landing policy are unchanged. Both native
worktree paths preserve ignored files, whose content is not proved recoverable by Git refs.

Run scripts directly from the skill directory or via python:

```bash
# 1. Full Dry-Run Inspection (Default); --prs pins the PRs you intend to land
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --prs 783,811

# 2. Audit Only (Scan Clones and Worktrees)
python3 skills/2-daily/merge-cleanup/scripts/scan_clones.py --prefix XYZ-forge

# 3. PR Topological Sequencing
python3 skills/2-daily/merge-cleanup/scripts/toposort_prs.py

# 4. Execute Full Sequence (Merges, Reconciliation, and Teardown) for the PRs pinned in step 1
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --prs 783,811 --execute

# 5. Teardown Only with Verified Backup (Safe aggressive deletion)
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --teardown-only --backup-first --execute

# 6. Land only PR 783 while other PRs (e.g. 427) stay open: anything not in --prs is never merged.
#    --exclude <pattern> keeps a checkout out of the scan/teardown; it does not filter PRs.
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --prs 783 --exclude gh427 --execute

# 7. Caller repair rung (Phase C): the handoff line printed the record path
export MERGE_CLEANUP_RECORD=/abs/primary/.tick/merge-cleanup/HiQS-Labs-XYZ-forge/pr-538.json
python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py note --kind diagnosis --text "same-key update on gh_number 100"
python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py reserve --rung ponytail --head <sha> --clone "$PWD"   # exit 3 → /unstuck
python3 skills/2-daily/merge-cleanup/scripts/attempt_record.py finish --index 0 --outcome resolved

# 8. Continue a previous run after repairs or a network outage (GH-623)
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --prs 811 --resume --execute

# 9. Execute with explicit direct landing plan for 3+ PR queues (GH-1066)
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --prs 783,811,812 --landing-plan direct --landing-reason "Independent fixes with disjoint file sets" --execute

# 10. Execute with group candidate landing plan (GH-1066 checklist, exits 0 without merging)
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary "$HOME/Documents/GH Repos/XYZ-forge" --prefix XYZ-forge --prs 783,811,812 --landing-plan group --landing-reason "Combine tightly coupled changes into staging branch" --execute
```

---

## Safety Guarantees

1. **Zero Data Loss:** Any dirty working tree, unpopped stash, or unlanded commit automatically stops deletion and marks the checkout `PRESERVE_*`, naming the files or refs. The primary checkout is inspected first and by identity, so it can never be skipped by a scan filter. Anything the scanner cannot prove is preserved, naming the failed query.
2. **No Silent Primary Deferral:** every executing run refuses before merge, teardown, or symlink mutation while the primary is unready; only the operator can defer primary cleanup with `--allow-unready-primary`.
3. **Zero Process Interference:** Clones with active driver locks, active tick claims (from the event fold), or open file handles are detected and preserved; an unverifiable session is preserved too.
4. **Canonical Worktree Protocol:** Linked worktrees are always cleanly deregistered from git metadata.
5. **Governed Landing:** Every PR is gated on the ledger against the current integration head before it merges, verified `MERGED` after, then fast-forwarded, reconciled, emitted, committed, pushed, and verified clean/equal to the remote integration head before the next PR is looked at; any failure stops the run.
6. **Bounded Repair:** every repair attempt on a PR — the script's B1 and each caller rung — is counted in one record at the pinned coordinator under one lock; the third is refused wherever it starts, and a dependent of a parked PR is never attempted.


### Jog post-merge completion (GH-1108, delivery 1)

When an origin-specific Jog primary pin exists, `--primary` must name that same checkout.
After successful merge/reconciliation and primary fast-forward, positively mapped issue/body
or branch references are intersected with existing Jog rows. The hook calls `jog land` in
that primary using committed execution bundles; it never reads a task clone's `.tick` cache.
A refusal stops advancement. Completion and `landing.json` ride the existing post-merge
commit/push step. Non-Jog PRs keep their existing behavior.

Until the separate automatic transition-push PR lands, a Jog run may leave owned primary
ledger changes/local supervisor commits. Inspect and publish those explicitly before invoking
merge-cleanup; Phase 0 still requires a clean, published, fast-forward-ready primary. Do not
use `--allow-unready-primary` to skip that checkpoint.
