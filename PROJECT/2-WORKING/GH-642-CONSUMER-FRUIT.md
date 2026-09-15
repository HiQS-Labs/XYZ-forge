---
gh_issue: 642
source: https://github.com/HiQS-Labs/XYZ-forge/issues/642
title: "Low-hanging fruit from two foreign-repo marathons: make the consumer-repo SOP turnkey"
status: Active (2-WORKING — plan authored 2026-09-15, pending Codex plan review)
created: 2026-09-15
updated: 2026-09-15
owner: noelsaw1
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 4
rating: "pri/sev/appeal/effort 60/35/50/60 · calc 205"
goal: >
  Land the surgical tranche of #642 so a consumer-repo marathon stops tripping on layout and
  fix-round traps: vendor ignores go to .git/info/exclude (never the target .gitignore), the
  claude-turn bash twin honors CLAUDE_REASONING_EFFORT and both twins warn on Opus-class models
  with the Sonnet-sized default budget, --force on a spent token auto-suffixes a fresh relay-task
  id, isolated worktree turns see ROOT/node_modules, a new xyz-init-clone.sh produces the
  validated consumer-clone layout in one command, and both preflight twins warn loudly on a
  zero-item acceptance checklist.
---

# GH-642: Consumer-repo fruit — make the foreign-repo marathon SOP turnkey

## Status

| What was just completed | What's next |
|---|---|
| **INTAKE 2026-09-15** — #642 parked (`rmi-01M2KF9N7AE67J6AZHJQQ081M7`, rated 60/35/50/60), recon against `origin/development` @ `d5c18633` split the issue: 3 items already landed upstream (consumer remedy: `xyz-sync update`), 6 surgical items in this arc, 4 feature-sized deferrals with follow-up issues to be filed at deferral time. Plan authored; Codex plan review next. | Plan review (Codex, ≤3 rounds) → implement p1–p4 → full gate once (`ci-local.sh`) → final Codex QA → PR against `development`. |

## Field evidence

[#621](https://github.com/HiQS-Labs/XYZ-forge/issues/621) — two foreign-repo marathons on
`jpollock/local-addon-nexus-ai` (gh-52, gh-60); the run-2 report (comment of 2026-09-15) is the
incidence source for every item. Consumer side: umbrella
[local-addon-nexus-ai#60](https://github.com/jpollock/local-addon-nexus-ai/issues/60), PRs #61–#64.

## Recon findings (task clone @ origin/development d5c18633)

Already satisfied at HEAD — the Nexus `.xyz` vendor predates them (source 033a48ee, 2026-08-26);
consumer remedy is `xyz-sync update`, not new work:

| #642 item | State at HEAD | Evidence |
|---|---|---|
| Ship `releases_app.py` in `--with-releases` overlay | **Already landed** | `relay-automation/xyz-vendor.sh:344` `RELEASES_OVERLAY` includes `utils/py/releases_app.py` |
| Claude effort support | **Already landed (Python twin)** | `utils/py/claude_cli.py:19` `effort_flags` reads `CLAUDE_REASONING_EFFORT` (low/medium/high/xhigh/max) |
| Acceptance-inlining loss protection | **Already hardened** | `utils/py/swarm_preflight.py:779` — GH-399 fails rather than warns on a lossy inline |

## Scope — the surgical tranche (this arc)

1. **Vendor ignores → `.git/info/exclude`** (`relay-automation/xyz-vendor.sh:296-303`). Today the
   vendor appends `.xyz/` + `/.tick/` to the target's `.gitignore` ("direction 1" append) — that
   dirtied a consumer worktree and hard-stopped the next `--require-clean` fire until manually
   reverted (run-2 incident). Change the destination to `git -C "$TARGET_REPO" rev-parse
   --git-path info/exclude` (worktree-safe; honored by `git check-ignore`), creating the dir as
   needed. The direction-2 refusal (never un-ignore paths marathons must commit) is unchanged, as
   is the pre-mutation check ordering.
2. **claude-turn parity + budget warning** (`relay-automation/claude-turn.sh`, `utils/py/claude-turn.py`).
   The bash twin gains `CLAUDE_REASONING_EFFORT` (same validation set as `claude_cli.effort_flags`:
   low/medium/high/xhigh/max, appended as `--effort <v>`); both twins emit a **non-fatal stderr
   warning** when `CLAUDE_MODEL` matches `claude-opus*` and `CLAUDE_MAX_BUDGET` is unset or the
   0.50 default (field evidence: a bare Opus smoke call is ~$0.68 of cache-write; the default cap
   hard-stops mid-turn).
3. **`--force` auto-suffix on a spent token** (`relay-automation/marathon-drive.sh`,
   `utils/py/marathon_drive.py`). When the relay task was auto-derived (no explicit
   `--relay-task`), `--force` is set, and `tick info` reports the default token done/not-claimable,
   derive `MARATHON-<PHASE>-TURN-R<k>` (lowest free k ≥ 2) and announce it on stderr. An explicit
   `--relay-task` is never rewritten.
4. **Worktree build deps** (`relay-automation/relay-turn-lib.sh`, `utils/py/rtl.py` — wherever
   `rtl_worktree_begin` lives per runtime). After worktree creation, symlink `$RTL_ROOT/node_modules`
   into the worktree when the root has one and the worktree lacks it; teardown needs no special
   handling (disposable tree). No behavior change when absent.
5. **`relay-automation/xyz-init-clone.sh`** — thin wrapper over existing pieces:
   `xyz-init-clone.sh <repo-url> [--umbrella N] [--slug s] [--dir D] [--with-releases]` →
   deterministic clone name (`marathon-gh-<umbrella>-<slug>`, slug ≤3 lowercase words, default
   `~/marathon-clones/<name>`), `git clone`, self-vendor (`xyz-vendor.sh --with-releases`),
   githooks install when the target ships `githooks/install.sh`, printed next steps (bootstrap
   hint + drive invocation shape). Reuses item 1, so no `.gitignore` revert step exists.
6. **Preflight zero-criteria warning** (`relay-automation/swarm-preflight.sh`,
   `utils/py/swarm_preflight.py`): when the acceptance section yields zero `- [ ]` items, emit the
   existing fallback text **plus a stderr warning** naming the doc and the fix; exit codes unchanged.

## Non-goals (deferred — follow-up issues to be filed and parked)

- **Gate-red auto-recycle** (`marathon-drive --fix-rounds N`): touches escalation semantics and
  token lifecycle of both driver twins; feature-sized arc of its own.
- **Operator-block preservation across relay re-renders / `--handback`**: render-semantics change
  in both drivers; interacts with the GH-505 attestation model.
- **Preflight `--scaffold`**: new intake subcommand; deserves its own contract discussion.
- **Dual-home contracts** (issue-body contract fallback): changes the `--gh-issue` resolution
  contract documented in `MACHINE-CONTRACTS.md`.

Also dispositioned: `find-harness.sh` vendored-diff warning polish (minor; fold into any future
find-harness touch), ledger-absent-in-stale-vendors (consumer remedy is re-vendor; documented in
#621).

## Implementation order (verification inline)

1. **p1 — vendor excludes + claude-turn parity/warning** (items 1–2). Verify:
   `bash test/xyz-vendor.sh` updated and green; new focused suite cases for exclude destination,
   `.gitignore` untouched, effort env validation, Opus-budget warning.
2. **p2 — drive token auto-suffix + worktree deps** (items 3–4). Verify: focused suite cases with
   a stub `tick` (spent token → `-R2` announced; explicit id untouched) and a tmp repo with
   `node_modules` (symlink present in worktree, absent-behavior unchanged).
3. **p3 — `xyz-init-clone.sh`** (item 5). Verify: e2e against a local bare fixture repo — clone
   name derivation, vendor ran, excludes present, hooks installed when present, `--help`.
4. **p4 — preflight zero-criteria warning** (item 6). Verify: both twins emit the stderr warning
   on a checklist-less doc; existing preflight suites stay green.
5. **Gate** — `./validate.sh --auto` during development; **`bash ci-local.sh` exactly once on the
   final commit** (the qualifying run; cite that SHA in the PR).

## Bounded test scope

One new focused suite, `test/gh642-consumer-fruit.sh`, covering the six items above with tmp-dir
fixtures (bare repo, stub tick, stub claude binary). **Test non-scope:** no new test framework, no
live CLI/network calls, no fuzzing, no hosted-CI simulation. Existing suites that pin touched
behavior (`test/xyz-vendor.sh`, timeout-parity, preflight suites) must stay green unmodified
except where item 1 changes pinned `.gitignore` assertions — those assertions move to the exclude
destination in the same commit.

## Risks / rollback

- Item 1 changes documented vendor behavior; consumers relying on `.gitignore` semantics lose
  nothing (exclude is honored by `git check-ignore` and by the driver's own probe). Rollback:
  revert one hunk.
- Item 3 changes which token id a forced re-fire claims. Guarded: only when the id was
  auto-derived and the token is spent; explicit ids win. Rollback: revert one hunk.
- Items are independent; any can land or revert alone. All additive; no schema/DB format changes
  beyond the roadmap row this doc already wrote.
