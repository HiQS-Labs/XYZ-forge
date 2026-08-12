# AGENTS.md

Read `WORKTREE-SAFETY.md` for important Git Worktree Dangerous actions to avoid.

Read `ROUTER.md` first for startup order and canonical files.

Read `GUIDING-PRINCIPLES.md` for the product north stars.

Read `PROJECT/PDDA.md` when the task touches project docs, `ROADMAP.md`, or `CHANGELOG.md`.

## Runtime default

Entry-point shims run their **Python** implementation by default (`XYZ_PYTHON` unset → Python). To
force the legacy Bash path for a single run, prefix it with `XYZ_PYTHON=0`; for a whole session,
`export XYZ_PYTHON=0`. The Bash body stays inline in every shim, so the opt-out is always available.

## What this file owns

This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
radius, planning shape, and proof.

Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
`ROUTER.md` and `PROJECT/PDDA.md`.

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

### 4. Size the blast radius before changing shared surfaces

Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
change, say what ripples, what might break, and who notices. A change you cannot size is not ready.

### 5. One plan, one ordered list

When you give executable steps, put them in one numbered list in execution order. Keep verification
inline (`-> expect ...`). Do not scatter action items across prose.

### 6. Verified beats plausible

Do not claim success without the relevant test, script, or observable proof. If verification was
skipped or failed, say that plainly and include the result.

### 7. Record only consequential bets

If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
`PROJECT/PDDA.md`. Below that threshold, skip the ritual.

### 8. Stay quiet on trivial work

Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
local change.

## Repo-specific rails

- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
  containment, skill-first relay work, durable fixes, and verified done.
- `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
  governance.
- Before approving a PDDA dependency sync, follow the repo-owned
  [PDDA sync review policy](PROJECT/PDDA-SYNC-POLICY.md); a green suite after fixups does not by
  itself establish that deleted local behaviour was safe to remove.
- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
- **Scratch and temporary files go in `temp/`, never the repo root.** `/temp/` is already gitignored
  (`.gitignore:13`). Probes, reproduction scripts, one-off analysis, captured command output,
  half-written notes — anything you would not put in a commit — belongs there or outside the repo
  entirely. **Do not create `scratch-*.md`, `notes-*.md`, `*.tmp` or similar at the repo root.**

  This is a housekeeping rule with a real failure mode behind it, which is why it is a rail and not a
  preference. Root-level scratch is *untracked*, so it survives branch switches, rebases and
  worktree teardown; it accumulates silently across sessions until nobody can say which agent or
  which lane produced it, or whether it is safe to delete. It also puts unreviewed prose one
  `git add -A` away from a commit — and `marathon-closeout.sh` has already swept 20 unrelated files
  into a lane's PR once (2026-08-10), which is exactly this hazard firing.

  A file that turns out to be worth keeping gets *promoted* deliberately — into `PROJECT/1-INBOX/`
  as a capture doc, into `test/baselines/` as recorded evidence, or into the CHANGELOG — rather than
  being left at the root in the hope that someone later works out what it was.
- **Frozen Bash twins (GH-308).** Python in `utils/py/` is authoritative for the eleven Tier-A
  entry points (`agy-turn`, `aider-turn`, `claude-turn`, `codex-turn`, `pi-turn`, `poll`,
  `relay-loop`, `relay-drive`, `consult`, `marathon-drive`, and `swarm-preflight`). Their `.sh`
  files are historical `XYZ_PYTHON=0` fallbacks: put behavior fixes in the named Python twin, not
  the Bash body. Before committing, run `bash test/gh308-frozen-twin-guard.sh --check --staged`; the
  `Frozen Bash twin guard (GH-308)` step in `.github/workflows/ci.yml` runs the same guard with
  `--base <PR base> --allow-exceptions` on every PR to reject a committed twin edit. **Escape
  hatch:** a safety defect in a fallback can warrant an edit anyway — GH-319 left a silently-fake
  pre-advance gate in `marathon-drive.sh` under `XYZ_PYTHON=0`. Such a commit must carry a trailer
  that **names the twin it covers**, with an em-dash before the reason:

  ```
  Frozen-twin-exception: relay-automation/marathon-drive.sh — silently-fake pre-advance gate (GH-319)
  ```

  **Per file, not per PR (GH-321).** Every frozen twin changed in the range must be named by some
  trailer in that range; one exception no longer excuses a different, undeclared edit riding along
  on the same branch — the common case on a multi-lane marathon PR. A trailer naming a path that is
  not a frozen twin fails loudly rather than silently covering nothing, and the bare
  `Frozen-twin-exception: <reason>` form (no path) no longer covers anything. Comma-separate to cover
  several twins with one reason. No trailer, no edit.

  **`utils/marathon-plan.sh` is no longer the exception (GH-362).** It was, while its Python "port"
  shelled out to a copied node engine with documented gaps; GH-340 deleted that copy and made the
  Python lane native, so the exception outlived its reason and marathon-plan is now the **12th frozen
  twin**. `relay-turn-lib.sh` remains a shared Bash runtime dependency rather than a twin, and is the
  only non-frozen file left in the Tier-A surface.

  **Two edits the guard permits without a trailer, both narrow (GH-362).** A commit that *introduces*
  a path's `FROZEN` banner establishes the freeze for that path and is not a violation of it — a range
  reaching back before the freeze (a release merge, a bisect, an old fork base) contains exactly that
  commit. The exemption covers the establishing edit only; anything touching the path *after* it in
  the same range still needs a trailer. Relatedly, the pre-GH-321 pathless trailer is tolerated **only**
  inside such a commit, because it is permanently in git history and cannot be rewritten — a new
  pathless trailer is still rejected everywhere.
- **Builder/orchestrator role split (GH-221)** — **Claude Code (terminal and VS Code agents) is the
  orchestrator and reviewer, never a default builder.** It plans, dispatches marathon/relay lanes, and
  reviews/verifies their output; it does not drive itself headlessly as a build lane. **Agy CLI and
  Codex CLI are the builders** — the two cost-blind (subscription-billed) headless build lanes
  `marathon.sh`/`marathon-drive.sh` default to (GH-212). **Claude CLI (billed via the Anthropic API) is
  NOT a builder by default** — `--builder claude` stays fully supported, but only as an explicit,
  cost-acknowledged choice the *user* makes locally (their own `--builder claude` flag or a local
  settings override), never something a session reaches for on its own reasoning that it's "just
  another supported builder option." If a task calls for a headless build lane and neither agy nor
  codex is available, stop and ask — don't default to spawning a headless Claude CLI turn.
- **HQ (multi-repo command center)** — for cross-repo tasking (resolve a project → land intake on its
  own PDDA rails → prepare dispatch), drive `utils/hq/hq.sh` via the `/hq` skill rather than hand-editing
  another repo's docs. Full command surface (`status`/`resolve`/`next`/`park`/`promote`/`queue`/`fire`),
  install, and the resolution ladder are in [README.md → HQ — multi-repo command center](README.md#hq--multi-repo-command-center); agent-facing invocation flow + guardrails live in [skills/hq/SKILL.md](skills/hq/SKILL.md). Write paths preview by default; `fire` never drives the harness.
- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
  broader than they look. Treat them as at least Costly until proven otherwise.
- **Contain tree-touching subagents with `isolation: "worktree"` (GH-177/GH-233).** A Claude Code
  session spawning Agent/Workflow subagents that will *modify files* in this repo should pass
  `isolation: "worktree"` so a runaway destructive command shreds a disposable checkout, not the main
  tree (this repo has been wiped twice — see
  `PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md`). Know what it does NOT protect: worktrees
  share `.git` objects/refs, so destructive *git* operations (`update-ref`, `branch -D`, resets,
  force-push) still hit the real repo — a worktree-isolated agent once reset ROOT HEAD via
  `rtl_enforce`'s commit-bypass guard. Harness-driven codex/agy lanes are covered by
  `rtl_worktree_begin` instead and don't need the flag. Known frictions: `--require-clean` self-trips
  on the driver's own lock dir inside a linked worktree, and untracked artifacts are invisible to a
  worktree checkout — commit review inputs first. Read-only subagents (Explore, audits) don't need
  isolation. Related guards: never execute `validate.sh`/`test/*.sh` under a sandboxed Bash call
  (enforced by `relay-automation/hooks/gh177-sandbox-test-guard.sh` — CI is the exercise path), and
  `test/mktemp-trap-guard.sh` statically outlaws the wipe idiom repo-wide.
- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
  override (`--force`) or a replan note — never a quiet slide off the plan.
- **Do not create new git branches** automatically. Only create a new branch if explicitly requested by the user.
- **`development` is the standing WIP branch — ALL work targets it, including marathon/relay-fired lanes (cut fresh from `main` 2026-07-17, [GH-216](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/216); policy widened 2026-07-17 to cover marathon lanes too, first applied to [PR #217](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/217)).** The prior `development` had drifted 295 commits behind `main` with no open PRs — retired to `development-archived-2026-07-04` rather than deleted outright. Both manual/exploratory work AND marathon-fired lanes (`marathon/gh-<n>-*` branches, GH-212 convention) now branch off `development` and PR back into it — `--plan`/`marathon.sh` still cuts its own short-lived per-lane branch, just off `development` instead of `main`. Periodically merge `development` → `main` once it's in a shippable state; don't let `main` sit behind `development` indefinitely. Watch for `development` drifting stale again the same way the old one did; re-cut from `main` if it does.
- **Anti-pattern: renaming a branch with an open PR via GitHub's branch-rename API
  (`POST /repos/{owner}/{repo}/branches/{branch}/rename`, or `gh api ... branches/<old>/rename`).**
  It does **not** rename in place — it deletes the old ref and recreates a new one, which GitHub
  treats as `head_ref_deleted` and **auto-closes the open PR** pointed at that branch (found
  2026-07-10 renaming a branch backing PR #193; recovered by opening a new PR from the renamed
  branch and pointer-commenting the closed one). If a branch needs a new name and has an open PR:
  either rename it *before* opening the PR, or accept that renaming after will require re-opening a
  fresh PR — don't assume the PR follows the rename.
- **Aider Configuration (AIDER.md / GH-77)**: When using Aider as a headless runner against OpenRouter, do not hardcode the API key or attempt to use a secrets manager. The `OPENROUTER_API_KEY` is securely stored at `/Users/noelsaw/secrets/openrouter/openrouter.txt` and is exported dynamically by `~/.zshrc`.
- **Aider edit-format compat for OpenRouter models (GH-118)**: many OpenRouter-proxied models
  (confirmed: GLM-5.2, Nemotron Ultra 3) default to Aider's `whole` edit format and fail to emit
  parseable edits, stalling the turn. Fix is `AIDER_FLAGS=--edit-format diff` (existing passthrough
  in `aider-turn.sh`) — see `relay-automation/README.md`'s "Known OpenRouter edit-format quirks"
  section before adding a new OpenRouter model to a driven lane.
- **Resolving an OpenRouter model name before setting `AIDER_MODEL` (GH-120)**: don't probe
  `aider --list-models` or curl `openrouter.ai/api/v1/models` by hand — run
  `relay-automation/resolve-model-alias.sh "<colloquial name>"` first (local alias table, no live
  query) or use the `/open-router` skill. Only fall back to the live catalog on a miss, and add the
  resolved slug back to `relay-automation/openrouter-model-aliases.yml` so the next lookup is instant.

## Conflict order

1. The current user request
2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
   `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
3. This file
4. Skill defaults
