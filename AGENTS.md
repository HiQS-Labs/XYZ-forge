# AGENTS.md

XYZ Forge exists for cross-model reviews and agentic work on business information, including private code, within the task’s authorized scope and applicable data-protection requirements.

## Danger: commands agents must not run

- Never run `git reset --hard`, `git checkout -- <path>`, or a tree-wide `git stash` in a checkout
  whose state matters; they overwrite tracked work or hide shared worktree-family state.
- Never run `rm -rf`, `find ... -delete`, or equivalent recursive cleanup through an empty,
  unresolved, relative, root, home, workspace, or otherwise unproven target path.
- Never remove or move a linked worktree with `rm -rf` or `mv`, and never hand-delete
  `.git/worktrees/*`; use `git worktree remove` / `move` / `prune` / `repair`.
- Never run sandboxed `git switch --track` or `git branch -D` directly; wrap the complete command
  with `utils/git-sandbox-guard.sh --repo <root> -- <git command>`.
- Never delete or move a full-clone folder until its working tree, stashes, local refs, and registered
  worktrees prove that it contains no unique or depended-on state.
- Never run `validate.sh` or `test/*.sh` from a linked worktree or a full clone whose state matters;
  run mutation-heavy gates only in a separate disposable full clone.

Read [`WORKTREE-SAFETY.md`](WORKTREE-SAFETY.md) for the rationale, recovery paths, and safe patterns.

> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
> license. Coding models may choose commands through their own runtimes and safety controls, outside
> the intended harness workflow. XYZ Forge cannot guarantee model behavior or data integrity; maintain
> tested, independent backups and follow industry-standard backup and recovery practices.

Read `ROUTER.md` first for startup order and canonical files.

Read `GUIDING-PRINCIPLES.md` for the product north stars — its "The North Star" section (durable,
reversible, DRY; extend what exists rather than forking a parallel system) is canonical and governs
everything below. For semi-autonomous work, also read its "Adaptive work and continuous handoff"
section, which links to flywheel's operational rubrics and standing authorization ladder.

Read `PROJECT/PDDA.md` when the task touches project docs or `CHANGELOG.md`.
Its document contract is adopted here; [ROUTER’s role split](ROUTER.md#role-split) distinguishes
XYZ-owned policy from PDDA-layer scope.

Read `HARNESS-MODELS-REGISTRY.md` for evaluated agent harnesses, model compatibility grades, and CLI flags.

Read `TESTS-RESULTS/README.md` for committed test artifacts, telemetry receipts, and benchmark logs.
Read `SOP.md` → "Arc planning" before starting a large refactor — scheduling the follow-up arcs (review/dogfood/conformance lanes) at plan time is what keeps the arc linear.

## Standing authorization for AI agents

The operator authorizes sharing this repository's relevant source code (including private
code), diffs and task context with AI agents for implementation and independent review through
operator-configured accounts and destinations. This includes OpenAI/Codex, Anthropic/Claude,
GLM, Meta Muse, Agy's configured provider, and other operator-selected AI models/providers.
Authorization persists across sessions; do not request it again merely because the repository
is private, a new agent session is started, or another model within this scope is selected.
Ask only when the proposed destination, account or purpose falls outside this authorization.
Exclude credentials and unrelated private data. This permission does not override platform or
organization restrictions, authorize bypassing a denial, or change the builder-role defaults.

**Outer-loop and factory runs** follow [#1328](https://github.com/HiQS-Labs/XYZ-forge/issues/1328);
read its "Updated notes" first. Check a milestone against its three gates, repair routine and
reversible defects during the run without asking (at most three rounds per blocker, then file an
issue), and report a run with agent repairs as agent-assisted, never as unattended.

## Runtime default

Entry-point shims run their **Python** implementation by default (`XYZ_PYTHON` unset → Python). To
force the legacy Bash path for a single run, prefix it with `XYZ_PYTHON=0`; for a whole session,
`export XYZ_PYTHON=0`. The Bash body stays inline in every shim, so the opt-out is always available.

## What this file owns

This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
radius, planning shape, and proof.

Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
`ROUTER.md` and `PROJECT/PDDA.md`.

After development merges, merge-cleanup runs `python3 utils/py/wave_reconcile.py --pr <N>`
locally for docs, ledger and LEADERBOARD views. Task branches do not commit routine views.
It refuses while a hosted reconciler runs unless `--force-local-reconcile` is passed.
Hosted `wave-reconcile.yml` is dispatch-only, before promotion; see **Promotion**.
Use `pdda.sh issue-doc-sync` to detect drift.

Read SOP's **Opinionated SOPs** for binding maintainer branch/isolation defaults (optional
for downstream users). It pre-authorizes one `feat/`, `fix/`, `chore/` or `docs/` branch per
fresh task clone, an explicit carve-out from the interactive no-automatic-branch rule.

## Operating principles

### 1. Lead with the line that survives skimming

Your first sentence gives the verdict, current state, or call. No setup first.

### 2. Make the bet explicit before acting

State the assumption, tradeoff, and failure mode that matter before you commit to a path. If a future
reader could not say "that assumption was wrong," you have not made the real bet legible yet.

### 3. Use one reversibility scale

Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
changes need a rollback path. One-way doors need explicit confirmation before proceeding.

This scale is how `GUIDING-PRINCIPLES.md` → "The North Star" gets applied per change; that section
owns the *why*, this one owns the read.

### 4. Size the blast radius before changing shared surfaces

Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
change, say what ripples, what might break, and who notices. A change you cannot size is not ready.

### 5. One plan, one ordered list

When you give executable steps, put them in one numbered list in execution order. Keep verification
inline (`-> expect ...`). Do not scatter action items across prose.

### 6. Verified beats plausible

Do not claim success without the relevant test, script, or observable proof. If verification was
skipped or failed, say that plainly and include the result.

Retain and commit `provenance.jsonl` with every run cited in an issue, PR, roadmap or decision
(GH-430); a transient local path is not proof.

**Witness a red control for every new or materially changed decision gate:** replay pre-fix
behavior, mutate its input or supply a controlled failure. Unchanged coverage needs no fresh
mutation. A check unable to fail is decorative. Use an existing suite or recorded manual check,
never a new suite (see *No new tests*). GH-377/GH-379 show why: an awk range ended at its own
first line, a duplicated `--` made a grep search for the wrong text, and retry telemetry never
exercised the failing path. Passing outputs alone established none of those claims.

**Reject empty evidence.** Failed substitutions and redirects can produce empty data that passes
every downstream assertion. Assert extraction succeeded and the artifact is nonempty first.

**Flaky suites:** fix in place if in a tier (`utils/ci-route.sh`, `SUBSYSTEM_TESTS_small`);
otherwise remove from `validate.sh` TESTS and add to gh306 EXEMPT, retaining the file
(#802, comment 5841529958; #853).

**Never expose the operator's machine to the network without explicit permission each time.**
Tests or feature work do not authorize a tunnel, port-forward or remote bridge. Read SOP §3b
for the incident and teardown requirement.

**Establish blocker necessity.** If a failure's user consequence is unclear, or two investigation
attempts produce no new evidence, use `skills/1-hourly/sanity-check/SKILL.md` to decide whether
to fix, simplify, defer via PRS or dismiss before investing further.

**Apply proportionate rigor** under GUIDING-PRINCIPLES' North Star. Name each blocking control's
concrete benefit and weigh operator time, maintenance and recovery cost. Prefer the simplest
adequate control; recommend simplifying one whose burden exceeds its value. Honor and record
explicit scoped operator tradeoffs while keeping review/test/delivery evidence truthful. Do not
recreate a rejected restriction under another name or bypass unrelated controls.

### 7. Record only consequential bets

If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
`PROJECT/PDDA.md`. Below that threshold, skip the ritual.

### 8. Stay quiet on trivial work

Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
local change.

## Repo-specific rails

- **No new tests (GH-831, operator decision 2026-09-25).** No new `test/` suite,
  `validate.sh` TESTS entry, gate/guard/lane/runner/telemetry-stage machinery, or test to
  enforce this rule. Verify through existing coverage or manual checks retained under
  `TESTS-RESULTS/<date>+GH-<n>/` with `provenance.jsonl`. Edit an existing suite only to keep
  it truthful when pinned behavior changes. Witness red controls there or manually.
  A new test file is a review finding. The Small/Medium/Large transition is #831;
  #815/#816/#817/#819 are superseded and must not be implemented.

- **Prove the harness with real long-horizon marathon work.** Short tasks can land but do not
  establish coordination, isolation, lock, multi-round handoff, escalation or resume robustness.
  Keep exactly one long-horizon marathon in flight, explicitly named in the RELEASES ledger's
  **Immediate next-up** (`python3 utils/py/releases_app.py roadmap list`). Choosing its successor
  is a decision, not a default. Prefer needed work decomposable into many identical transforms,
  with per-item machine-checkable outcomes and enough blast radius to stress the harness
  (GH-10's 73 suites is the archetype). Choosing a comparably valuable non-marathon-shaped item
  instead needs a reason in the ledger. Never invent work or a harmless synthetic load to keep
  busy: if no needed marathon fits, stay idle or do smaller work. Report failures and lessons;
  a clean run teaching nothing is weaker evidence than one exposing a defect.
- **The RELEASES DB has two subsystems behind one CLI:** release planning and the roadmap
  (`roadmap_items`), both owned by `utils/py/releases_app.py`. This is the Product Release System
  ([PRS](HOW-TO-USE.md#glossary--the-five-terms-youll-hit-first)). Create roadmap rows at work
  pickup/selection via the CLI; read with `roadmap list`. `ROADMAP.md` is retired; `roadmap sync`
  is for legacy repos and no-ops here, since mirroring Markdown could delete parked rows.
  Never hand-edit `releases.db` or `releases.sql`. Before changing or merging them, read
  [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); resolve dump conflicts through
  `utils/releases-merge-resolve.sh`.
- **Local push gates and hosted CI both apply (GH-544, #16).** This repo has been public since
  2026-08-15; `.github/workflows/ci.yml` covers pushes/PRs on `main` and `development`.
  Commits are ungated; `githooks/pre-push` gates pushes. Install and check once per clone with
  `bash githooks/install.sh` and `bash githooks/install.sh --check`. The dispatch stub covers
  every branch/worktree even where `githooks/` is absent; hooks do not travel to another clone.
  `validate.sh` defaults to parallel, cores/2 capped at 4 (GH-35); `--burst` restores full width.
  `ci-local.sh` stays sequential, writes qualifying evidence, and does not call `validate.sh`.
  Development merges reconcile locally through `wave_reconcile.py --pr N`. The dispatch-only
  `wave-reconcile.yml --promotion` runs the full registry (`validate.sh --parallel 4`) on the
  development tip before promotion, qualifying landings together (GH-1127/#1131/#1134).
  Read ROUTER for tiers/retired suites; its selector applies to non-promotion `--qualify` only.
  Bypasses (`git push --no-verify`, `XYZ_SKIP_PREPUSH=1`) announce themselves: use deliberately,
  not reflexively. Operator-requested WIP draft publication may bypass only with current focused
  evidence and skipped-gate disclosure in the PR, leaving merge readiness outstanding (GH-487).
  A bypass authorizes no merge, promotion or teardown. A configured workflow is not a result:
  query the actual hosted run and cite its commit SHA. See **Promotion** below.
- **Never restore committed tree state to undo an experiment in a shared clone (GH-527).**
  `git reset --hard`, `git checkout -- <path>` and tree-wide `git stash` can overwrite or hide
  peer work; stash may time out before pop. Copy your file first and restore that copy instead.
  Untracked files surviving does not protect tracked changes. The
  `relay-automation/hooks/gh527-destructive-git-guard.sh` snapshot to `.tick/orphan-backups/`
  is a recovery net, not permission to use destructive commands.
- **Preflight sandboxed branch mutations (GH-50).** A sandbox may let `git switch --track` rewrite
  the index and working tree, then deny the `.git/config` lock and leave HEAD on the old branch.
  Before a harness runs a tracking switch or destructive branch mutation such as `git branch -D`,
  wrap the complete command with `utils/git-sandbox-guard.sh --repo <root> -- <git command>` so it
  refuses before mutation when the config cannot be written. Never truncate git stderr for branch
  operations: the decisive `could not lock config file` line can otherwise disappear behind an
  unrelated upstream hint.
- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
  containment, skill-first relay work, durable fixes, and verified done.
- `PROJECT/PDDA.md` owns doc lifecycle, roadmap pointer-ledger rules, and `CHANGELOG.md`
  governance.
- Before approving a PDDA distribution change, follow the repo-owned
  [PDDA sync review policy](PROJECT/PDDA-SYNC-POLICY.md); a green suite after fixups does not by
  itself establish that deleted local behaviour was safe to remove.
- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
- **Scratch belongs in `temp/` (gitignored), never the repo root.** Probes, captured output,
  temporary scripts and unfinished notes go there or outside the repo. Untracked root scratch
  survives branch/worktree changes and can be swept into unrelated commits (observed with 20
  files in marathon closeout). Deliberately promote durable material to `PROJECT/1-INBOX/`,
  `test/baselines/` or CHANGELOG; do not leave it for later agents to classify.
- **Park incidental findings in root `PARKED/`.** When an agent notices a real item outside the
  current task, record a short, sourced observation there under `PARKED/README.md` without expanding
  the active work. Triage may promote it through issue-first `PROJECT/1-INBOX` and the RELEASES
  roadmap. This folder is an intentional exception to the scratch-file rule above; it is durable
  intake, not a place for probes or half-written notes. Never park a blocker to the current task.
- **Frozen Bash twins (GH-308).** Python in `utils/py/` owns the twelve Tier-A entry points:
  `agy-turn`, `aider-turn`, `claude-turn`, `codex-turn`, `pi-turn`, `poll`, `relay-loop`,
  `relay-drive`, `consult`, `marathon-drive`, `marathon-plan`, `swarm-preflight`.
  Their `.sh` bodies are historical `XYZ_PYTHON=0` fallbacks: fix behavior in Python.
  `marathon-plan` became the twelfth frozen twin when GH-340 removed its copied-node-engine
  implementation (GH-362). `relay-turn-lib.sh` remains an unfrozen shared Bash dependency.
  Before committing run `bash test/gh308-frozen-twin-guard.sh --check --staged`; hosted CI runs
  the guard with `--base <PR base> --allow-exceptions` on every PR.

  A fallback safety defect can justify an exception, with a per-file commit trailer:
  `Frozen-twin-exception: relay-automation/marathon-drive.sh — <reason>`.
  Every edited twin in the range must be named by a trailer in that range; comma-separated
  paths may share a reason. No trailer, no edit. Non-twin paths and new pathless trailers fail.
  A commit introducing a path's `FROZEN` banner may establish the freeze without a trailer;
  later edits still need one. Historical pre-GH-321 pathless trailers are tolerated only in
  those establishing commits, not new changes (GH-321/GH-362).

  **No new Bash (GH-551).** New executables belong in `utils/py/` as Python. A new `.sh` under
  `utils/` or `relay-automation/` needs `New-bash-exception: <path> — <reason>` per file.
  Tests, git hooks and existing shims are outside that new-file guard.
- **Builder/orchestrator role split (GH-221).** Claude Code terminal/VS Code agents orchestrate
  and review; they never default to building or drive themselves as a headless build lane.
  Agy CLI and Codex CLI are the subscription-billed default builders (GH-212).
  `--builder claude` remains supported only as an explicit, usage-acknowledged user choice
  (flag or local settings), whether authenticated by subscription or API. If neither default
  builder is available, stop and ask; do not silently substitute headless Claude.

  The orchestrator must inspect every emitted artifact before continuing automation: the PR
  targets `development`, its diff matches the logical scope (e.g. <500 lines for a targeted bug),
  and a gate ran on the final commit. Failure of any predicate halts the loop.
  **Independent QA is separate (GH-784):** test results or author review cannot satisfy it.
  Mechanically invoke peer/Codex QA via `relay-xyz` / start-task Step 8 and retain receipts in
  `relay-system/<YYYY-MM-DD>/<label>.codex.md` before signing off PR creation or promotion.
- **HQ (multi-repo command center)** — for cross-repo tasking (resolve a project → land intake on its
  own PDDA rails → prepare dispatch), drive `utils/hq/hq.sh` via the `/hq` skill rather than hand-editing
  another repo's docs. Full command surface (`status`/`resolve`/`next`/`park`/`promote`/`queue`/`fire`),
  install, and the resolution ladder and agent-facing invocation flow + guardrails are in [skills/2-daily/hq/SKILL.md](skills/2-daily/hq/SKILL.md). Write paths preview by default; `fire` never drives the harness.
- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
  broader than they look. Treat them as at least Costly until proven otherwise.
- **Contain modifying subagents with `isolation: "worktree"` (GH-177/GH-233).** Claude Code
  Agent/Workflow subagents that edit this repo need that flag; read-only audits do not.
  Harness-driven Codex/Agy lanes use `rtl_worktree_begin`. Commit review inputs first:
  untracked artifacts are invisible to a new worktree; `--require-clean` may self-trip on the
  driver's lock directory. Worktrees isolate working files only: config, refs, objects, hooks
  and all other shared `.git` state remain exposed, including destructive git operations.
  Never run `validate.sh`/`test/*.sh` under a sandboxed Bash call; the GH-177 hook enforces it.
  Rerun unsandboxed, never defer to CI. `test/mktemp-trap-guard.sh` outlaws the wipe idiom.

- **Run mutation-heavy suites only in a separate disposable FULL CLONE (GH-564).** Never run
  `validate.sh` or `test/*.sh` in a valued clone or linked worktree. Read
  [WORKTREE-SAFETY.md](WORKTREE-SAFETY.md#12-run-the-full-gate-only-in-a-disposable-full-clone)
  before running gates. A linked worktree shares `.git/config`, refs, remotes, objects and
  hooks with its parent. Escaped fixtures have set `core.bare=true`, repointed origin and
  rewritten development, even from worktrees deliberately created for isolation. Full clones
  contain that Git blast radius but may themselves be corrupted, including mid-push-hook.

  Before trusting a run, fetch or push from a tested clone, compare pre/post `HEAD`,
  `git config --get core.bare`, `git remote -v` and `git config --local --get user.email`.
  Until #564's invariant gate lands, treat every tested clone as suspect. Unexpected identity
  drift invalidates the result: re-clone and compare candidate/base at the same width before
  blaming the diff. Intact identity means investigate the diff or normal flakiness. A serial
  pass cannot disprove a parallel fixture escape; one green run is not nondeterminism proof.

  **Validate paths at every dangerous use boundary (GH-567), not just creation.** Empty
  `git -C` uses CWD and empty `cd` is a no-op; empty cleanup operands can target root/CWD.
  These suites may intentionally lack `set -e`. Each receiving function must prove a path
  nonempty, resolved beneath its sandbox root, and of the expected type. A lexical prefix
  permits `..` traversal; harden before copying. `require_fixture` in
  `test/gh544-pre-push-gate.sh` is the containment pattern; the recorded 31 other suites lack
  it. Strict mode or a non-null check alone is not containment.

  **Audit invocation variants and inspect repeatable write artifacts (GH-195).** A detector
  matching only `bash <driver>.sh` misses direct Python execution. That blind spot let
  `test/gh115-round-cap.sh` commit a live transcript on every run in four separate clones.
  Ask what an audit does not match. Trace the actual write using repeatable artifacts (such
  as timestamp-correlated `.tick/attempts/<phase>`) before speculative process hunts.
  Evidence: [GH-195](PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md).

- **Local macOS is the gate; hosted Ubuntu is advisory (GH-509).** XYZ ships for macOS;
  Linux/Windows support is future work. Never defer local verification to CI's wrong-platform
  canary. Operator-retired suites stay out of both runners; retained manual files are in
  gh306 EXEMPT (GH-854). `canary-ubuntu` is `continue-on-error: true`: red means portability
  drift, not a broken macOS commit. For a Linux-specific claim it is authoritative.
  A green local run is self-reported and cannot qualify promotion. Development landings are
  qualified together by pre-promotion hosted `wave-reconcile.yml` on the tip; after pushing
  main, hosted `boundary-macos` witnesses it (GH-1127/#1131).
- **Promotion (development → main), GH-1127.** Evidence must belong to the commit that is merged:
  1. **Quiet window** from the dispatch until the promotion PR is merged: no PR merges or direct pushes
     to `development`. (The local writer's exit 8 only refuses *reconciliation* while a hosted run is
     active, not the merge, so the operator holds the window.)
  2. `gh workflow run wave-reconcile.yml --ref development`; take the run id from
     `gh run list --workflow wave-reconcile.yml --limit 1`; `gh run watch <id>` until it succeeds.
  3. `git fetch origin development`. Pick the receipt whose `run_url` ends in `/<id>` (not merely the
     newest). Require `gate == "validate.sh --parallel 4"`, `result == "pass"`, no `deferred` line in
     `gh run view <id> --log`, `git merge-base --is-ancestor <tested_commit> origin/development`, and
     every commit in `<tested_commit>..origin/development` authored by the bot
     (`wave_reconcile.BOT_AUTHOR_EMAIL`) with paths accepted by `hosted_lane_publish.declared_paths`.
     Any failure: redispatch.
  4. Open the development → main PR. Immediately before merging, fetch and repeat step 3 against the
     PR head (`gh pr view <n> --json headRefOid`); anything changed → redispatch.
  5. After the merge, `boundary-macos` witnesses main (full registry, `--sequential`, unchanged).
- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
  override (`--force`) or a replan note — never a quiet slide off the plan.
- **Do not create branches automatically in interactive work** unless the user requests it.
  The maintainer fresh-clone policy in SOP §4 pre-authorizes one task branch. A requested
  marathon/relay lane also cuts its own `marathon/gh-<n>-*` branch and PRs to `development`.
  This rule never licenses marathon commits directly onto development (GH-561); the driver
  guards `development` itself, not just `origin/HEAD`.
- **`development` is the standing WIP branch for ALL work**, including relay/marathon lanes:
  branch from it and PR back to it, not main (GH-216/#217). Promote development to main
  periodically when shippable; do not leave main indefinitely behind. Watch for development
  becoming stale and re-cut from main if necessary. The previous branch was 295 commits
  behind main and was preserved as `development-archived-2026-07-04`, not deleted.
- **Do not assume GitHub branch rename preserves an open PR.** The branch-rename API
  deletes/recreates the ref, closing its PR as `head_ref_deleted` (PR #193, 2026-07-10).
  Rename before opening a PR, or expect to open a new PR and pointer-comment the old one.
- **Aider Configuration (AIDER.md / GH-77)**: When using Aider as a headless runner against OpenRouter, do not hardcode the API key or attempt to use a secrets manager. The `OPENROUTER_API_KEY` is securely stored at `~/secrets/openrouter/openrouter.txt` and is exported dynamically by `~/.zshrc`.
- **Aider edit-format compat for OpenRouter models (GH-118)**: many OpenRouter-proxied models
  (confirmed: GLM-5.2, Nemotron Ultra 3) default to Aider's `whole` edit format and fail to emit
  parseable edits, stalling the turn. Fix is `AIDER_FLAGS=--edit-format diff` (existing passthrough
  in `aider-turn.sh`) — see `relay-automation/README.md`'s "Known OpenRouter edit-format quirks"
  section before adding a new OpenRouter model to a driven lane.
- **Resolving an OpenRouter model name before setting `AIDER_MODEL` (GH-120)**: don't probe
  `aider --list-models` or curl `openrouter.ai/api/v1/models` by hand — run
  `relay-automation/resolve-model-alias.sh "<colloquial name>"` first (local alias table, no live
  query) or use the `/open-router` skill. Only fall back to the live catalog on a miss. **Do not
  append the resolved slug to `relay-automation/openrouter-model-aliases.yml` — it is a generated
  file (GH-450)** rendered from the vendored HiQS-Labs/Model-catalog copy, and a hand-added line
  fails `test/gh450-model-catalog-pin.sh`. Add the row upstream in Model-catalog, then land a sync
  PR here (`utils/py/model_catalog.py pin` / `render` / `check`); the exact two-PR recipe is in
  `relay-automation/README.md` → "Adding a new model alias".

## Conflict order

1. The current user request
2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
   `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
3. This file
4. Skill defaults
