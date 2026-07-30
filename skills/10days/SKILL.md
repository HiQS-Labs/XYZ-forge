---
name: 10days
description: >
  Sweep GitHub issues opened or updated in an age window (default: last 10 days; the
  window is adjustable, e.g. an 11-14-day slice to avoid overlapping another sweep),
  verify each one is still valid, reproducible, and not already fixed (fan out
  subagents to check issue state, comments, and git/commit history for completion
  evidence), build a marathon plan from the survivors, run swarm-preflight on it, then
  cut a branch and execute the marathon end-to-end with no pause. This skill is a
  deliberate, operator-authorized exception to this repo's default "ask before cutting
  a branch / firing a marathon" rule (GUIDING-PRINCIPLES.md §8) — it exists specifically
  to run unattended. Trigger on "/10days", "run the 10 day sweep", or the operator's
  canned request: "look through recent GH issues within the last 10 days and check if
  they are still valid, reproducible, not completed already... add each one to a
  marathon file, run preflight, cut a new branch and execute on the marathon."
  Requires swarm-preflight.sh + marathon-plan.sh resolved from the harness root (bare repo
  root or a vendored `.xyz/` install — see Procedure Step 0), plus the swept repo's
  PROJECT/** + ROADMAP.md + gh (authenticated) + jq.
---

# /10days — recent-issue sweep → marathon → fire

Turn "what's landed in GitHub in the last N days that's still worth doing" into a fired
marathon, unattended. This is `marathon-triage`'s more automated sibling: where
`marathon-triage` stops at a plan and hands it to the operator, `/10days` carries the
plan through preflight, branch-cut, and execution in one run — because that is
literally what it was built for (a canned macOS text-replacement snippet that expects
one shot, no back-and-forth).

**Read this whole file before running anything.** The auto-fire behavior below is a
named exception to house convention, not an oversight — know why before you invoke it.

**Reviewed 2026-07-16** via `/consult --models agy` (static review, no execution;
transcript: `relay-system/2026-07-16/10days-review-222405/10days-review.agy.md`). That
review found five real problems, all fixed below before this skill was ever run live:
unsafe hand-rolled JSON in `find-doc.sh`, a `swarm-preflight.sh` multi-`--gh-issue`
bundling behavior the original Step 6 got wrong, no check for a concurrently-running
marathon before cutting a branch, no check for a behind-origin `main` (swarm-preflight
itself only warns on this, never blocks), and no containment story for the parallel
lane dispatch in Step 7. See each fix inline below.

## Guardrails (read first)

- **Sandbox off for `gh` and `git fetch`/`git push`** — every `gh` call and preflight
  run here fails under the Bash sandbox (TLS/keychain). Run with the sandbox disabled.
- **Auto-fire is intentional here, and only here.** `GUIDING-PRINCIPLES.md` §8 and the
  `marathon-triage` skill both say never auto-cut a branch or auto-fire a marathon —
  that default stands everywhere else in this repo. `/10days` was authorized by the
  operator (2026-07-16) to override the *pause*, not the *substance*: it still requires
  a clean working tree AND an idle coordination layer before cutting anything (Step 7),
  still runs every gate, still stops the run cold on a red gate or a git-safety
  violation, and still prints every command it runs. If any precondition in Step 7
  fails, stop and report — do not force through it.
- **Never mark an issue "already done" without evidence.** A hunch is not evidence. A
  merged commit/PR that references the issue number, or an existing capture doc parked
  in `PROJECT/3-COMPLETED`, is evidence.
- **Check for a concurrently-running marathon before touching the branch, not just the
  current branch name.** A dirty tree, a non-empty `.tick/locks/`, or a fresh untracked
  `PROJECT/2-WORKING/MARATHON-*` directory all mean something else is mid-flight —
  cutting a branch or firing on top of that state will collide with it. Step 7 checks
  all three, not just `git branch --show-current`.
- **Parallel lanes run in isolated worktrees, not on the shared tree.** Dispatching
  concurrent Agent calls directly against one working tree is a containment violation
  (GUIDING-PRINCIPLES.md §3/§4) — two lanes writing at once with no isolation can orphan
  each other's commits exactly like the documented GH-13/14/17 incidents. Step 7 uses
  the Agent tool's `isolation: "worktree"` for every parallel lane specifically to avoid
  this, without falling back to headless `marathon-drive.sh` (ruled out separately —
  it can't run a `claude` builder headlessly and the `codex` builder self-commits).
- **A lane only ever touches its contract's `artifacts` allowlist.** No lane edits
  ROADMAP.md execution detail (pointer/ledger only, GUIDING-PRINCIPLES.md §9) beyond the
  one queued-intake line this skill itself adds in Step 4.
- **Auto-drafted preflight contracts are a best-effort guess, not a verified fact —
  and the fix for a wrong guess has to land before firing, not in the after-the-fact
  report.** A wrong `artifacts` list makes `marathon-plan.sh`'s wave/collision map
  untrustworthy: two lanes it thinks are disjoint could actually touch the same file
  and race. Step 6.5 adds a cheap deterministic overlap check specifically to catch
  this before any wave runs concurrently, in addition to the Step 8 report flag.

## Preconditions — install once

Claude Code only scans `~/.claude/skills/`, not this repo's top-level `skills/`. Run this once,
**from a harness clone** (this is the one step that is genuinely clone-relative — there is no
`skills/` directory in a repo you are merely sweeping):

```bash
bash skills/10days/install.sh   # symlinks this clone's skills/10days into ~/.claude/skills/ (idempotent)
```

## Procedure

### 0. Resolve the harness root, and confirm which repo is being swept

`swarm-preflight.sh` and `marathon-plan.sh` may live at the repo root or, in a vendored install,
under `.xyz/`. Resolve once, using the same precedence as other self-locating skills in this repo
(env override → vendored `.xyz/` → current repo root):

```bash
HARNESS="${XYZ_HARNESS:-${XYZ_REPO_ROOT:-}}"
[ -n "$HARNESS" ] || HARNESS="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -x "$HARNESS/.xyz/utils/swarm-preflight.sh" ] && HARNESS="$HARNESS/.xyz"
```

Reference every harness script below as `$HARNESS/utils/…` — **not** bare `utils/…` paths, which
resolve to nothing (or to an unrelated `utils/` directory) in a vendored `.xyz/` install.

The two bundled scripts (Steps 1 and 2) ship beside this `SKILL.md`, so set `SKILL_DIR` to whatever
directory this file was loaded from — `~/.claude/skills/10days`, a clone's `skills/10days`, or a
vendored `.xyz/skills/10days` are all valid. Do **not** assume `skills/10days/` relative to the
swept repo; when sweeping a foreign repo that path does not exist:

```bash
SKILL_DIR=/absolute/path/to/this/skill/directory   # substitute the real one
```

**Also confirm the sweep target before spending anything.** Every step below is
working-directory-bound: `gh` resolves the repo from the cwd's git remote, `find-doc.sh` looks for
capture docs, and Step 7 cuts a branch. Standing in the wrong repo sweeps the wrong issues *and
succeeds*, which is the expensive failure. Print it once and check it:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner   # must be the repo you intend to sweep
git rev-parse --show-toplevel                         # and its checkout
```

Run every subsequent step from the swept repo's **root**, not a subdirectory — a contract whose
`gate` names a repo-relative program (e.g. `.venv/bin/python`) is currently checked against the
process cwd rather than the target root, so a ready lane reports NOT-READY from a subdirectory
(GH-343).

### 1. Pull the candidate window (deterministic — no judgment calls)

```bash
bash "$SKILL_DIR/scan-issues.sh" [MAX_DAYS] [MIN_DAYS]   # default: 10 0  (last 10 days)
```

`MAX_DAYS` is how far back the window opens; `MIN_DAYS` (default 0 = today) is how
close to today it closes. Use the two-argument form to carve out a slice that skips a
range another sweep already owns — e.g. `scan-issues.sh 14 11` covers issues 11-14
days old and deliberately excludes the last 10 days.

Emits one JSON object per OPEN issue updated in the window (`{number, title, createdAt,
updatedAt, url, labels}`), sorted by issue number. This is a plain `gh issue list`
wrapper — it makes no validity/completion judgment, so it is safe to re-run and diff.

### 2. Cheap local reconcile before spending any subagents

For every issue number from Step 1:

```bash
bash "$SKILL_DIR/find-doc.sh" <N>
```

- `bucket: "3-COMPLETED"` → strong already-done signal. Exclude immediately; note it on
  the "propose closing #<N>" list rather than spending a subagent on it.
- `bucket: "2-WORKING"` with `has_contract: true` → a real preflight verdict already
  exists or can be re-run cheaply; still route it through Step 3 (docs go stale —
  see the swarm-preflight fix-probe gotcha below), but it needs no new contract.
- `bucket: null` or `has_contract: false` → no shortcut; needs the full Step 3 check and,
  if it survives, a contract authored in Step 4.

**Gotcha to carry into Step 3:** `swarm-preflight.sh` fix-probes detect the *bug*, not
the *fix* (`grep_present` = bug still there, `grep_absent` = fix landed). Read a stale
doc's own probe definitions before trusting its verdict — don't assume "has a contract"
means "verdict is current."

### 3. Validity / reproducibility / completion fan-out (subagents)

For every issue that survives Step 2, spawn one subagent (Explore or general-purpose;
batch in groups of ~5-6 concurrent, not all at once) to answer, with receipts:

- `gh issue view <N> --json title,body,comments,state,labels,url` — read the actual ask.
- `git log --all --oneline -i --grep="#<N>\b" --grep="GH-<N>\b"` — any commit that
  references this issue number by either convention.
- `gh pr list --state merged --search "<N> in:body"` (and `--search "#<N>"`) — any
  merged PR that references it, even without a matching commit message.
- If a capture doc exists (from Step 2), read its own "Status" table for a prior
  completion note.

Return one structured verdict per issue:

```json
{"issue": N, "decision": "INCLUDE|EXCLUDE", "reason": "...",
 "evidence": ["commit abc123 fixes this", "..."],
 "already_done": false, "duplicate_of": null, "needs_contract": true}
```

`EXCLUDE` when: commit/PR evidence shows the work already landed; the issue is a
duplicate of another open issue; the issue isn't reproducible/actionable (vague report,
no repro steps, no clear acceptance criteria); or it's not a work item at all
(question, discussion, meta/process issue). `INCLUDE` only when none of those hold.

> **Runtime-aware reproducibility (`runtime:*`-labeled issues only).** If an issue carries a
> `runtime:bash` label, reproduce it under `XYZ_PYTHON=0` before ruling it not-reproducible or
> already-fixed: since the default flipped, a plain repro runs the Python twin, so a Bash-path bug
> won't surface and would be falsely `EXCLUDE`d as "already done." `runtime:python`/`runtime:parity`
> reproduce under the default path. These labels exist only in `xyz-3-agents-swarm`, so this is a
> silent no-op for any other repo the sweep runs against.

### 4. Ensure every INCLUDE has a contract-carrying capture doc in `2-WORKING`

For each `INCLUDE` verdict:

- **Doc already exists** (1-INBOX or 2-WORKING): move it to `2-WORKING` if it isn't
  there yet; add a `## Swarm Preflight Contract` block if `has_contract` was false.
- **No doc exists**: author `PROJECT/2-WORKING/GH-<N>-<slug>.md` using this repo's
  standard capture-doc frontmatter (`gh_issue`, `source`, `title`, `status`, `created`,
  `updated`, `owner`, `doc_type`, `complexity`/`risk`/`effort` with
  `ratings_provisional: true`, `goal`), plus a best-effort contract:

  ```
  ## Swarm Preflight Contract
  ```json
  {
    "target":      { "repo": ".", "ref": "main" },
    "gate":        "bash validate.sh",
    "fix_probes":  [ /* inferred from the issue body — grep for the bug it describes */ ],
    "artifacts":   [ /* files the issue names, or the subagent identified as the touch surface */ ],
    "remediation": { "source": "issue#<N>", "criteria": "<one-line acceptance criteria>" },
    "lanes":       { "agy_safe": [], "orchestrator_only": [ /* kernel/.tick paths, if any */ ] }
  }
  ```

  For a `runtime:bash`-labeled issue, set the gate to `"XYZ_PYTHON=0 bash validate.sh"` so the
  lane verifies against the Bash path the bug actually lives on, not the Python default (again, a
  no-op outside `xyz-3-agents-swarm`, where the label is absent).

  Mark it explicitly in the doc body: *"Contract auto-drafted by /10days from the issue
  text — artifacts/lanes not yet operator-verified."* This is the one place this skill
  guesses; the report in Step 8 must surface every auto-drafted contract by name.

- **Audit the guess like `marathon-triage` does**: do the declared `artifacts` paths
  actually exist (or, for a new file, does the issue actually call for creating one at
  that path)? Does the set plausibly match the issue's real subject, not a generic or
  copy-pasted guess? A contract that fails this sniff test is a placeholder — its
  collision map can't be trusted at all; drop that issue back to `needs_contract` and
  exclude it from this run rather than firing on an untrustworthy guess.

- Append one queued-intake pointer line for `GH-<N>` under ROADMAP.md's ledger (pointer
  only — no execution detail) so `$HARNESS/utils/marathon-plan.sh` picks it up in Step 5.

### 5. Build the marathon file

```bash
"$HARNESS/utils/marathon-plan.sh" --deep
```

`--deep` delegates to `$HARNESS/utils/swarm-preflight.sh --dry-run` per ready item for an
authoritative freshness verdict while ranking (slower, needs network — that's fine,
`gh`/network access is already required by this point). Writes
`PROJECT/2-WORKING/MARATHON-PLAN-<today>.md` — this is "the marathon file" the
operator's snippet refers to. Read its Held/Flagged section: anything held here drops
out of the fire list in Step 6, with the reason already stated by the planner.

**`marathon-plan.sh` ranks the ENTIRE ROADMAP ledger, not just this sweep's issues —
filter its waves down to this run's candidate set before treating anything as
fireable.** The generated waves will very likely include other ready ROADMAP items this
sweep never touched (a prior operator triage, a different marathon's queued work, an
old item that just became unblocked). Confirmed live on the first real run of this
skill: the generated plan's Wave 1 included issues already claimed by a separate,
concurrently-running marathon. Before Step 6: intersect the plan's wave assignments
with this run's own INCLUDE list from Step 3, drop everything else from consideration
(their wave slot, zone, and score are irrelevant to this run), and keep each surviving
issue's *relative* wave ordering the planner assigned (it already serialized same-zone
kernel items across separate waves correctly) — just don't fire the issues that aren't
yours.

### 6. Preflight the fire list — one issue per invocation

```bash
for N in <surviving issue numbers>; do
  "$HARNESS/utils/swarm-preflight.sh" --gh-issue "$N"
done
```

**Run it once per issue, never bundled** (`--gh-issue N --gh-issue M` in one call is a
different feature — `merge-contracts.mjs` folds every listed issue into *one* packet, so
a single invalid contract fails the *entire* bundle and stops filtering per-issue; that
is not what this step needs). No `--dry-run` — this run is going to fire, so let it
write the real packet, one per issue. Read the verdict per exit code: `0` ready · `3`
contract missing/invalid · `4` stale/already landed (drop it, propose closing the GH
issue — the fix shipped without this run knowing) · `5` not marathon-ready · `6`
blocked/missing-target · `7` ambiguous. Only exit-0 issues carry into Step 6.5. Every
non-zero drop gets one line in the Step 8 report with its exit code and reason — never
silently disappear an issue from the count.

### 6.5. Cross-issue artifact-overlap check — before any wave runs concurrently

`marathon-plan.sh` already groups exit-0 issues into waves by disjoint `artifacts`
sets. That grouping is only as trustworthy as the contracts feeding it, and Step 4 can
include auto-drafted ones. Before accepting a wave's concurrency as safe:

- Diff every pair of lanes slotted into the same wave: do their `artifacts` lists
  literally intersect (a bug in the planner or the contract) or does either lane's
  underlying issue body/title mention a file path that appears in the other lane's
  `artifacts`? Either signal is enough.
- Any lane pair with a hit — **serialize them**: move one to the next wave regardless
  of what the planner computed. This costs wall-clock time, not correctness; the
  planner's wave grouping is an optimization, not a safety guarantee, once an
  auto-drafted contract is in the mix.
- Log every serialization decision so Step 8 can report it — a silently-reordered wave
  is still a surprise the operator should see.

### 7. Cut the branch and execute — no pause (see Guardrails)

**Preconditions — stop the whole run if any fails:**

```bash
git status --porcelain                                  # must be empty
git branch --show-current                                # not already on a marathon/* branch
ls .tick/locks/ 2>/dev/null                               # must be empty — a claim means something is live
find PROJECT/2-WORKING -maxdepth 1 -iname 'MARATHON-*' -newer .git/HEAD 2>/dev/null   # unexpected fresh marathon dir → stop, don't assume it's yours
git fetch origin main --quiet && git rev-list --count HEAD..origin/main   # must be 0 — swarm-preflight only WARNS on behind, never blocks; this skill has to check itself
```

If the fetch/behind check is nonzero, do **not** rebase or pull automatically — stop and
report it; the operator decides how to reconcile. If any other check fails, stop and
report which one, and do not touch the branch.

Then:

1. Branch: use the packet's own `suggested_branch` (single-issue run) or
   `marathon/10days-<today>` (multi-issue bundle). `git checkout -b <branch>`.
2. Execute per the proven **Marathon execution pattern**: Claude-direct kernel lanes +
   parallel Sonnet subagents for independent lanes — **not** headless
   `marathon-drive.sh` (it can't run a `claude` builder headlessly, and the `codex`
   builder is known to self-commit mid-turn). Walk the MARATHON-PLAN doc's waves in
   order, respecting any Step 6.5 serialization:
   - Within a wave, dispatch one Agent tool call **per lane, each with
     `isolation: "worktree"`** — this is the containment substitute for
     `marathon-drive.sh`'s worktree isolation, so concurrent lanes cannot write over
     each other on a shared tree. Respect the wave's zone caps (kernel ≤ 1 per wave).
   - Each lane agent writes only inside its contract's `artifacts` allowlist.
   - After all of a wave's lane agents return, before merging any lane's worktree
     commit(s), verify that lane's worktree base against the marathon branch's start
     commit: `git merge-base --is-ancestor <marathon-branch-start-sha> <lane-worktree-HEAD>`.
     **Confirmed live 2026-07-17 (GH-225): `isolation:"worktree"` lanes can silently
     branch from a stale historical commit instead of the marathon branch** — do not
     assume the ancestry check will pass. If it passes, fast-forward/merge as normal. If
     it fails, the worktree is based on a stale/unrelated point — **cherry-pick the
     lane's specific new commit(s) onto the marathon branch instead; never `git merge`
     the isolation branch wholesale** in that case, or it silently reintroduces every
     already-superseded file state between the stale base and the marathon branch tip.
     Merge/cherry-pick each lane **one at a time** (not concurrently) so the branch ref
     never has two writers racing it.
   - Once a lane's commit(s) are merged, remove its worktree: `git worktree remove
     <path>` (fall back to `git worktree remove --force <path>` if it still reports
     uncommitted/stray state). Do this for every lane in the wave, right alongside the
     gate check below — left as-is, a run with several parallel lanes accumulates
     orphaned worktree directories under the repo's git metadata across sessions. A
     removal failure does not stop the run: record the lane, path, and error for the
     Step 8 report and continue.
   - After a wave's merges land, run its gate (the contract's `gate`, default
     `bash validate.sh`) **before starting the next wave.** A red gate stops the run —
     do not advance to the next wave, do not force-merge, report it in Step 8 and leave
     the branch as-is for the operator to inspect.
3. Commit per lane/wave with a message referencing the GH issue number(s) it closes.

### 8. Report

One final summary, always — even (especially) on a partial or stopped run:

- Window scanned (N days, issue count).
- Excluded, with reason, grouped by bucket (already-done / duplicate / not
  reproducible / not-a-work-item / held-by-preflight / held-by-planner).
- Included and fired, with their issue numbers and final commit(s).
- Every **auto-drafted contract**, named individually, flagged for operator review.
- Every **Step 6.5 serialization** — which lane pairs were pulled out of a concurrent
  wave and why, so a wave that ran slower than expected isn't a mystery.
- Every gate result per wave (green/red) and, if red, exactly where the run stopped.
- Every **worktree-cleanup failure** — lane, worktree path, and the `git worktree
  remove` error — if any lane's worktree failed to remove after its merge. Never
  silently ignore a leftover worktree; if none failed, say so explicitly (all
  worktrees removed cleanly).
- Branch name, and whether it's ready for a PR or still mid-marathon.

Never mask a stopped run as a finished one — an honest partial report is the point of
this whole skill (GUIDING-PRINCIPLES.md §8: the operator decides, but only if they know
what actually happened).

## Bundled deterministic scripts

- [`scan-issues.sh`](scan-issues.sh) — Step 1, the GH window pull. No judgment calls.
- [`find-doc.sh`](find-doc.sh) — Step 2, the capture-doc lookup for one issue number. No
  judgment calls.

Both exist so the mechanical parts of this sweep run byte-identical every time instead
of being re-typed as ad hoc `gh`/`ls`/`grep` one-liners each invocation.
