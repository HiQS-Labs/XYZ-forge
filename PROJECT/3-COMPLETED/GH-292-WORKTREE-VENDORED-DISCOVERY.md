---
title: find-harness.sh misses a vendored .xyz/ when run from a linked git worktree
status: "Active (2-WORKING) — promoted 2026-07-26 after confirming the defect is still unfixed at development and that its three sibling issues are already fixed. Preflight contract below is LIVE and safe to fire."
created: 2026-07-26
updated: 2026-07-26
owner: noel
gh_issue: 292
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/292
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Redesigning the harness resolution order. Add ONE probe for the main working
    tree; leave env → .xyz/ → current repo → script-relative otherwise intact.
  - Making the centralized-harness fallback an error. Falling back stays the
    default; only the silence and the wrong message are defects.
  - Anything about the driver lock itself (GH-42's ROOT@HEAD hazard is correct).
related:
  - "#272, #296, #304 — the other vendored-.xyz path-resolution defects. ALL THREE
    ARE FIXED IN development as of 2026-07-26 (#296/#272 via PR #297 merged
    2026-07-24; #304 via PR #306 merged 2026-07-26). #292 is the only one of the
    family still genuinely open, which is why it is scoped alone rather than as a
    four-issue marathon."
goal: >
  A relay driven from a linked git worktree of a vendored repo resolves that repo's
  own .xyz/ harness and its per-repo driver lock, exactly as it does from the main
  checkout. When the harness genuinely cannot be reached, the readiness output says
  something true and actionable instead of "no local .xyz/ in this repo".
---

# GH-292 — find-harness.sh misses a vendored `.xyz/` from a linked worktree

## Status
| What was just completed | What's next |
|---|---|
| **2026-07-26: captured, verified still-unfixed, and promoted to 2-WORKING with a live preflight contract.** Confirmed against `development` at `8d89616`: `skills/relay-xyz/find-harness.sh` contains no `--git-common-dir` handling and no worktree awareness, so the `grep_absent` probe returns `unfixed` — the fix is genuinely still required. Scoped as a **single lane, deliberately not a four-issue marathon**: its three siblings are already fixed in `development` (#296 and, transitively, #272 via [PR #297](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/297) merged 2026-07-24; #304 via [PR #306](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/306) merged 2026-07-26), and #272's own contract is recorded as SUPERSEDED / "do not fire". Bundling all four would have produced three no-op lanes and one actively wrong one. Also identified the reason the family stayed invisible: only #304 has a regression test, and `validate.sh` registers tests via an explicit `TESTS=()` array rather than globbing, so an unregistered test silently never runs. | Fire the contract below via `utils/swarm-preflight.sh --gh-issue 292`, then hand the emitted packet to `relay-automation/marathon-drive.sh`. Separately: verify-and-close #272 / #296 / #304, none of which need a build lane. |

## Symptom

`.xyz/` is gitignored, so it is materialised only in a repo's **main checkout**. Driving a relay
from a **linked worktree** of that same repo, `find-harness.sh` fails to find it, silently falls
back to the centralized harness, and takes that clone's single global driver lock — the exact
contention the repo vendored to avoid.

The failure then presents as someone else's problem:

```
relay-drive: another driver is active in this repo (pid 68529, lock: .git/relay-driver.lock).
```

The vendored harness's own lock was free the whole time. The natural diagnosis is "wait for that
marathon", not "my harness resolution is wrong", so the time is lost chasing the wrong cause.

The readiness output actively misleads, telling the operator to vendor a repo that already is:

```
!   concurrency: no local .xyz/ in this repo — relays here use the CENTRALIZED harness...
```

## Root cause

The resolution order probes for `.xyz/` relative to the current working directory / worktree root.
A linked worktree's root is not the main checkout's root, and gitignored files are not materialised
there. Confirmed still unfixed at `development` — `skills/relay-xyz/find-harness.sh` contains no
`--git-common-dir` handling and no worktree awareness of any kind.

## Reproduction

```bash
cd /path/to/vendored-repo && skills/relay-xyz/find-harness.sh --check   # resolves .xyz/   ✅
git worktree add .wt/feature
cd .wt/feature && skills/relay-xyz/find-harness.sh --check              # "no local .xyz/" ❌
```

**Frequency:** every time. Worktrees are the normal way to run isolated feature work, and
`--target-root` runs are especially likely to be launched from one, so this is not an edge case.

## Fix (as proposed on the issue, unchanged)

Resolve the **main** working tree before probing for `.xyz/`:

```bash
main_root="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")"
```

`--git-common-dir` points at the shared `.git` of the main checkout; its parent is the main working
tree. Probe `"$main_root/.xyz"` **after** the CWD probe fails, so existing behaviour is unchanged
wherever it already works. Guard for bare/absent repos, and keep `--path-format=absolute` because
older git returns a relative path.

Two follow-ons belong in the same change, because without them the bug stays invisible:

1. **Correct the readiness message.** When the repo is vendored but the copy is not reachable from
   here, say so — "vendored .xyz found in the main checkout at `<path>`".
2. **Warn on silent fallback.** Falling back is a fine default; doing it silently for a repo that
   explicitly opted into isolation is not.

## Scope note — why this is a single lane

Its three sibling issues are already fixed in `development`. #272's own capture doc records its
swarm-preflight contract as **SUPERSEDED — "do not fire"**, and #296's doc explains that firing it
would edit the correct-all-along backstop logic while leaving the real defect unremarked. Bundling
this issue with them would produce three no-op lanes and one actively wrong one. #272/#296/#304
need verification-and-close, not build lanes — tracked separately from this capture.

## Test gap this closes

`validate.sh` registers tests through an explicit `TESTS=()` array rather than globbing `test/`, so
the new regression test must be **registered there** or it will silently never run. Of the four
issues in this family only #304 has a regression test today, which is precisely how three fixed
defects sat open and unverified.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "skills/relay-xyz/find-harness.sh", "pattern": "git-common-dir" },
    { "type": "path_absent", "path": "test/gh292-worktree-vendored-discovery.sh" }
  ],
  "artifacts":   [
    "skills/relay-xyz/find-harness.sh",
    "test/gh292-worktree-vendored-discovery.sh",
    "validate.sh"
  ],
  "artifacts_new": [ "test/gh292-worktree-vendored-discovery.sh" ],
  "remediation": {
    "source":   "self#fix-as-proposed-on-the-issue-unchanged",
    "criteria": "find-harness.sh probes the main working tree via --path-format=absolute --git-common-dir after the CWD probe fails; readiness names the main-checkout .xyz path instead of claiming none exists; silent centralized fallback for a vendored repo emits a warning; test/gh292-worktree-vendored-discovery.sh asserts resolution + lock selection from a linked worktree AND from the main checkout (control), and is registered in validate.sh's TESTS array."
  },
  "lanes":       {
    "agy_safe":          [ "test/gh292-worktree-vendored-discovery.sh" ],
    "orchestrator_only": [ "bin/", ".tick/" ]
  }
}
```

## Phase 0 — Fix & lock it in

### Checklist
- [ ] Reproduce from a linked worktree of a vendored repo (the repro above)
- [ ] Add the main-working-tree probe after the CWD probe; leave the rest of the order intact
- [ ] Guard bare/absent repos and older git's relative `--git-common-dir`
- [ ] Correct the readiness message; warn on silent centralized fallback for a vendored repo
- [ ] Register the new test in `validate.sh`'s `TESTS=()` array — it will not run otherwise

### QA checklist — Phase 0
- [ ] The regression test fails before the fix and passes after (verify with `git stash`)
- [ ] Control case: resolution from the **main** checkout is byte-identical to today
- [ ] A repo with no `.xyz/` still falls back to the centralized harness, unchanged
- [ ] `bash validate.sh` green, including the new test actually executing
